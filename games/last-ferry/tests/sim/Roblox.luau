--!nonstrict
--[[
	A headless Roblox for tests: enough of the engine to run the game's real
	server and client scripts together on a virtual clock.

	- Instances are mocks held to tests/sim/reflection.json (generated from the
	  Roblox API dump): unknown members, wrong value types and writes to read-only
	  properties raise the same way they would in Roblox, and deprecated members
	  are recorded.
	- task.*, signals (deferred, like Roblox's default), TweenService,
	  RemoteEvents (server and per-player client contexts), DataStores, badges
	  and players are simulated.
	- Nothing renders and there is no physics. Tweens jump to their goal when
	  they finish. This checks logic, wiring and API use, not looks or feel.

	Usage:
		local sim = Sim.new({ root = "." })
		sim:startServer()
		local player = sim:addPlayer("Alice", 101)
		sim:runUntil(function() return done end, 1800)
		assert(#sim.errors == 0)
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Enum = roblox.Enum

-- Lune's CFrame.lookAt faces the opposite way to Roblox's (right and look vectors
-- flipped), so the simulator gives game code a CFrame table with Roblox's lookAt.
local function lookAt(at, target, up)
	local look = (target - at).Unit
	local right = look:Cross(up or roblox.Vector3.yAxis)
	if right.Magnitude < 1e-6 then
		right = look:Cross(roblox.Vector3.zAxis)
	end
	right = right.Unit
	return roblox.CFrame.fromMatrix(at, right, right:Cross(look).Unit, -look)
end
local CFrameApi = setmetatable({ lookAt = lookAt }, { __index = roblox.CFrame })

local Sim = {}
Sim.__index = Sim

local TWEENABLE = {
	number = true,
	boolean = true,
	CFrame = true,
	Color3 = true,
	UDim = true,
	UDim2 = true,
	Vector2 = true,
	Vector3 = true,
	Rect = true,
}

local function typeOf(value: any): string
	local mt = getmetatable(value)
	if type(mt) == "table" and rawget(mt, "__type") then
		return rawget(mt, "__type")
	end
	return typeof(value)
end

local function split(path: string): { string }
	local parts = {}
	for part in string.gmatch(path, "[^/]+") do
		table.insert(parts, part)
	end
	return parts
end

function Sim.new(options: { root: string?, screen: Vector2?, safeArea: Vector2?, preferredInput: EnumItem? }?)
	local opts = options or {}
	local root = opts.root or "."
	local reflection = serde.decode("json", fs.readFile(`{root}/tests/sim/reflection.json`)).classes

	-- Lune's fs calls yield to Lune's own scheduler, which would stall a simulated thread,
	-- so every script and module is read up front, here on Lune's main thread.
	local sources: { [string]: string } = {}
	local function preload(directory: string)
		for _, entry in fs.readDir(`{root}/{directory}`) do
			local path = `{directory}/{entry}`
			if fs.isDir(`{root}/{path}`) then
				preload(path)
			elseif string.sub(entry, -5) == ".luau" then
				sources[path] = fs.readFile(`{root}/{path}`)
			end
		end
	end
	preload("ServerScriptService")
	preload("ReplicatedStorage")

	local sim = setmetatable({
		now = 0,
		frames = 0,
		errors = {},
		warnings = {},
		output = {},
		deprecated = {},
		screen = opts.screen or roblox.Vector2.new(1280, 720),
		safeArea = opts.safeArea or opts.screen or roblox.Vector2.new(1280, 684),
		preferredInput = opts.preferredInput or Enum.PreferredInput.KeyboardAndMouse,
		stores = {},
		badges = {},
		coreCalls = {},
	}, Sim)

	--------------------------------------------------------------------------
	-- Scheduler

	local threadContext = setmetatable({}, { __mode = "k" })
	local deadContexts = {}
	local deferred = {}
	local sleepers = {}
	local sequence = 0

	local function currentContext(): string
		return threadContext[coroutine.running()] or "test"
	end

	local function resume(thread: thread, ...)
		if coroutine.status(thread) ~= "suspended" then
			return
		end
		if deadContexts[threadContext[thread] or ""] then
			return
		end
		local ok, err = coroutine.resume(thread, ...)
		if not ok then
			table.insert(sim.errors, `[{threadContext[thread] or "?"}] {debug.traceback(thread, tostring(err))}`)
		end
	end

	local function newThread(context: string, fn: any): thread
		local thread = if type(fn) == "thread" then fn else coroutine.create(fn)
		if threadContext[thread] == nil then
			threadContext[thread] = context
		end
		return thread
	end

	local function defer(context: string, fn: any, ...)
		local thread = newThread(context, fn)
		table.insert(deferred, { thread = thread, args = table.pack(...) })
		return thread
	end

	local function sleep(context: string, seconds: number, fn: any, ...)
		local thread = newThread(context, fn)
		sequence += 1
		table.insert(
			sleepers,
			{ time = sim.now + math.max(seconds, 0), seq = sequence, thread = thread, args = table.pack(...) }
		)
		return thread
	end

	local function drain()
		local guard = 0
		while #deferred > 0 do
			guard += 1
			if guard > 200000 then
				error("sim: the deferred queue never empties (an event loop feeding itself?)")
			end
			local item = table.remove(deferred, 1)
			resume(item.thread, table.unpack(item.args, 1, item.args.n))
		end
	end

	local function assertInSim(what: string)
		if threadContext[coroutine.running()] == nil then
			error(`sim: {what} called from the test thread; run it inside the simulation`, 3)
		end
	end

	local taskApi = {
		spawn = function(fn, ...)
			local thread = newThread(currentContext(), fn)
			resume(thread, ...)
			return thread
		end,
		defer = function(fn, ...)
			return defer(currentContext(), fn, ...)
		end,
		delay = function(seconds, fn, ...)
			return sleep(currentContext(), seconds or 0, fn, ...)
		end,
		wait = function(seconds)
			assertInSim("task.wait")
			local thread = coroutine.running()
			local started = sim.now
			sequence += 1
			table.insert(
				sleepers,
				{ time = sim.now + math.max(seconds or 0, 0), seq = sequence, thread = thread, args = table.pack() }
			)
			coroutine.yield()
			return sim.now - started
		end,
		cancel = function(thread)
			for i = #sleepers, 1, -1 do
				if sleepers[i].thread == thread then
					table.remove(sleepers, i)
				end
			end
		end,
	}

	--------------------------------------------------------------------------
	-- Signals

	local ConnectionMT = { __type = "RBXScriptConnection" }
	ConnectionMT.__index = ConnectionMT
	function ConnectionMT.Disconnect(self)
		self.Connected = false
		local list = self.signal.connections
		local index = table.find(list, self)
		if index then
			table.remove(list, index)
		end
	end

	local SignalMT = { __type = "RBXScriptSignal" }
	SignalMT.__index = SignalMT

	local function newSignal(name: string)
		return setmetatable({ name = name, connections = {} }, SignalMT)
	end

	function SignalMT.Connect(self, fn)
		if type(fn) ~= "function" then
			error("Attempt to connect failed: Passed value is not a function", 2)
		end
		local connection =
			setmetatable({ Connected = true, fn = fn, context = currentContext(), signal = self }, ConnectionMT)
		table.insert(self.connections, connection)
		return connection
	end

	function SignalMT.Once(self, fn)
		local connection
		connection = self:Connect(function(...)
			connection:Disconnect()
			fn(...)
		end)
		return connection
	end

	function SignalMT.Wait(self)
		assertInSim(`{self.name}:Wait`)
		local thread = coroutine.running()
		self:Once(function(...)
			resume(thread, ...)
		end)
		return coroutine.yield()
	end

	-- Deferred, like Roblox's default SignalBehavior: handlers run at the next resumption point.
	local function fire(signal, filter: ((context: string) -> boolean)?, ...)
		for _, connection in table.clone(signal.connections) do
			if connection.Connected and (filter == nil or filter(connection.context)) then
				defer(connection.context, connection.fn, ...)
			end
		end
	end

	--------------------------------------------------------------------------
	-- Reflection

	local memberCache = {}
	local function member(className: string, key: string)
		local cache = memberCache[className]
		if cache == nil then
			cache = {}
			memberCache[className] = cache
		end
		local hit = cache[key]
		if hit ~= nil then
			return hit or nil
		end
		local name = className
		while name and reflection[name] do
			local class = reflection[name]
			if class.properties[key] then
				hit = { kind = "property", info = class.properties[key], class = name }
				break
			elseif class.events[key] then
				hit = { kind = "event", info = class.events[key], class = name }
				break
			elseif class.functions[key] then
				hit = { kind = "function", info = class.functions[key], class = name }
				break
			end
			name = class.superclass
		end
		cache[key] = hit or false
		return hit
	end

	local function isA(className: string, target: string): boolean
		local name = className
		while name and reflection[name] do
			if name == target then
				return true
			end
			name = reflection[name].superclass
		end
		return false
	end

	--------------------------------------------------------------------------
	-- Instances

	local state = setmetatable({}, { __mode = "k" })
	local welds = setmetatable({}, { __mode = "k" }) -- part -> { [part] = true }, from WeldConstraints
	local InstanceMT = { __type = "Instance" }
	local computed = {} -- [className][property] = function(instance, st) -> value
	local methods = {} -- [className][name] = function(instance, ...)

	local function isInstance(value: any): boolean
		return type(value) == "table" and state[value] ~= nil
	end

	local function fullName(instance): string
		local names = {}
		local current = instance
		while current and state[current] do
			local st = state[current]
			if st.className == "DataModel" then
				break
			end
			table.insert(names, 1, st.props.Name)
			current = st.parent
		end
		return table.concat(names, ".")
	end

	local function note(list, message: string)
		if not table.find(list, message) then
			table.insert(list, message)
		end
	end

	local function resolve(map, className: string, key: string)
		local name = className
		while name and reflection[name] do
			local byClass = map[name]
			if byClass and byClass[key] then
				return byClass[key]
			end
			name = reflection[name].superclass
		end
		return nil
	end

	local function eventFor(instance, st, key: string)
		local signal = st.signals[key]
		if signal == nil then
			signal = newSignal(`{fullName(instance)}.{key}`)
			st.signals[key] = signal
		end
		return signal
	end

	local function checkValue(className: string, key: string, info, value: any, level: number)
		local category, typeName = info.category, info.type
		local actual = typeOf(value)
		local ok
		if category == "Primitive" then
			if typeName == "bool" then
				ok = actual == "boolean"
			elseif typeName == "string" then
				ok = actual == "string"
			else
				ok = actual == "number" and value == value
			end
		elseif category == "DataType" then
			ok = actual == typeName or ((typeName == "Content" or typeName == "ContentId") and actual == "string")
		elseif category == "Enum" then
			ok = actual == "EnumItem" and Enum[typeName][value.Name] == value
		elseif category == "Class" then
			ok = value == nil or (isInstance(value) and isA(state[value].className, typeName))
		else
			ok = true
		end
		if not ok then
			error(`Unable to assign property {key} of {className}. {typeName} expected, got {actual}`, level)
		end
	end

	-- Roblox's real default values, read from Lune's reflection database through a sample
	-- instance of each class. Falls back to the table below when Lune can't make the class.
	local samples = {}
	local function realDefault(className: string, key: string): (boolean, any)
		local sample = samples[className]
		if sample == nil then
			local ok, instance = pcall(roblox.Instance.new, className)
			sample = if ok then instance else false
			samples[className] = sample
		end
		if sample then
			local ok, value = pcall(function()
				return sample[key]
			end)
			if ok and value ~= nil then
				return true, value
			end
		end
		return false, nil
	end

	local function defaultFor(instance, st, key: string, info)
		local found, real = realDefault(st.className, key)
		if found and pcall(checkValue, st.className, key, info, real, 1) then
			return real
		end
		local overrides = {
			Visible = true,
			Interactable = true,
			Enabled = true,
			Archivable = true,
			AutoButtonColor = true,
			Selectable = st.className == "TextButton",
			TextSize = 14,
			MaxVisibleGraphemes = -1,
			LineHeight = 1,
		}
		if overrides[key] ~= nil then
			return overrides[key]
		end
		local category, typeName = info.category, info.type
		if category == "Primitive" then
			if typeName == "bool" then
				return false
			elseif typeName == "string" then
				return ""
			end
			return 0
		elseif category == "Enum" then
			local items = Enum[typeName]:GetEnumItems()
			table.sort(items, function(x, y)
				return x.Value < y.Value
			end)
			return items[1]
		elseif category == "DataType" then
			local constructors = {
				Vector3 = function()
					return roblox.Vector3.zero
				end,
				Vector2 = function()
					return roblox.Vector2.zero
				end,
				CFrame = function()
					return roblox.CFrame.new()
				end,
				Color3 = function()
					return roblox.Color3.new(1, 1, 1)
				end,
				UDim2 = function()
					return roblox.UDim2.new()
				end,
				UDim = function()
					return roblox.UDim.new()
				end,
				Font = function()
					return roblox.Font.fromEnum(Enum.Font.Legacy)
				end,
			}
			local make = constructors[typeName]
			return if make then make() else nil
		end
		return nil
	end

	local function changed(instance, st, key: string, value: any)
		if isA(st.className, "ValueBase") then
			if key == "Value" and st.signals.Changed then
				fire(st.signals.Changed, nil, value)
			end
		elseif st.signals.Changed then
			fire(st.signals.Changed, nil, key)
		end
		local propertySignal = st.propertySignals[key]
		if propertySignal then
			fire(propertySignal, nil)
		end
	end

	local function setParent(instance, st, parent)
		if st.destroyed then
			error(`The Parent property of {st.props.Name} is locked, current parent: NULL`, 3)
		end
		if parent ~= nil and not isInstance(parent) then
			error(`Unable to assign property Parent. Instance expected, got {typeOf(parent)}`, 3)
		end
		local cursor = parent
		while cursor do
			if cursor == instance then
				error(
					`Attempt to set parent of {fullName(instance)} to {fullName(parent)} would result in circular reference`,
					3
				)
			end
			cursor = state[cursor].parent
		end
		local old = st.parent
		if old == parent then
			return
		end
		if old then
			local siblings = state[old].children
			local index = table.find(siblings, instance)
			if index then
				table.remove(siblings, index)
			end
			if state[old].signals.ChildRemoved then
				fire(state[old].signals.ChildRemoved, nil, instance)
			end
		end
		st.parent = parent
		if parent then
			table.insert(state[parent].children, instance)
			if state[parent].signals.ChildAdded then
				fire(state[parent].signals.ChildAdded, nil, instance)
			end
			local ancestor = parent
			while ancestor do
				if state[ancestor].signals.DescendantAdded then
					fire(state[ancestor].signals.DescendantAdded, nil, instance)
				end
				ancestor = state[ancestor].parent
			end
		end
		changed(instance, st, "Parent", parent)
	end

	local function findChild(st, name: string)
		for _, child in st.children do
			if state[child].props.Name == name then
				return child
			end
		end
		return nil
	end

	InstanceMT.__index = function(instance, key)
		local st = state[instance]
		if key == "Parent" then
			return st.parent
		elseif key == "Name" then
			return st.props.Name
		elseif key == "ClassName" then
			return st.className
		end
		local found = member(st.className, key)
		if found then
			if found.info.deprecated then
				note(sim.deprecated, `{found.class}.{key}`)
			end
			if found.kind == "property" then
				local compute = resolve(computed, st.className, key)
				if compute then
					return compute(instance, st)
				end
				local value = st.props[key]
				if value == nil then
					value = defaultFor(instance, st, key, found.info)
				end
				return value
			elseif found.kind == "event" then
				return eventFor(instance, st, key)
			end
			local method = resolve(methods, st.className, key)
			if method == nil then
				error(`sim: {st.className}:{key}() isn't simulated (add it to tests/sim/Roblox.luau)`, 2)
			end
			return method
		end
		local child = findChild(st, key)
		if child then
			return child
		end
		error(`{key} is not a valid member of {st.className} "{fullName(instance)}"`, 2)
	end

	InstanceMT.__newindex = function(instance, key, value)
		local st = state[instance]
		if key == "Parent" then
			setParent(instance, st, value)
			return
		end
		local found = member(st.className, key)
		if found == nil or found.kind ~= "property" then
			error(`{key} is not a valid member of {st.className} "{fullName(instance)}"`, 2)
		end
		if found.info.readOnly then
			error(`Unable to assign property {key}. Property is read only`, 2)
		end
		if found.info.deprecated then
			note(sim.deprecated, `{found.class}.{key}`)
		end
		checkValue(st.className, key, found.info, value, 3)
		if key == "Position" and isA(st.className, "BasePart") then
			local cframe = st.props.CFrame or roblox.CFrame.new()
			key, value = "CFrame", cframe.Rotation + value
		end
		local old = st.props[key]
		st.props[key] = value
		if old ~= value then
			changed(instance, st, key, value)
		end
		if st.className == "WeldConstraint" and (key == "Part0" or key == "Part1") then
			local part0, part1 = st.props.Part0, st.props.Part1
			if part0 and part1 then
				welds[part0] = welds[part0] or {}
				welds[part1] = welds[part1] or {}
				welds[part0][part1] = true
				welds[part1][part0] = true
			end
		elseif key == "CFrame" and old ~= nil and old ~= value and welds[instance] then
			-- Moving a part moves the whole welded assembly with it.
			local delta = value * old:Inverse()
			local visited = { [instance] = true }
			local queue = { instance }
			while #queue > 0 do
				local part = table.remove(queue)
				for other in welds[part] or {} do
					if not visited[other] then
						visited[other] = true
						local otherState = state[other]
						otherState.props.CFrame = delta * (otherState.props.CFrame or roblox.CFrame.new())
						changed(other, otherState, "CFrame", otherState.props.CFrame)
						table.insert(queue, other)
					end
				end
			end
		end
	end

	InstanceMT.__tostring = function(instance)
		return state[instance].props.Name
	end

	local function newInstance(className: string)
		if reflection[className] == nil then
			error(`sim: class {className} isn't in tests/sim/reflection.json (add it to gen_reflection.py)`, 2)
		end
		local instance = setmetatable({}, InstanceMT)
		state[instance] = {
			className = className,
			props = { Name = className },
			children = {},
			parent = nil,
			signals = {},
			propertySignals = {},
			attributes = {},
			attributeSignals = {},
			destroyed = false,
		}
		return instance
	end

	local InstanceApi = {
		new = function(className: string, parent: any?)
			local class = reflection[className]
			if class == nil then
				error(`Unable to create an Instance of type "{className}"`, 2)
			elseif not class.creatable then
				error(`Unable to create an Instance of type "{className}" (not creatable)`, 2)
			end
			local instance = newInstance(className)
			if parent ~= nil then
				instance.Parent = parent
			end
			return instance
		end,
	}

	local function descendants(instance, into)
		for _, child in state[instance].children do
			table.insert(into, child)
			descendants(child, into)
		end
		return into
	end

	methods.Object = {
		IsA = function(self, className)
			return isA(state[self].className, className)
		end,
		GetPropertyChangedSignal = function(self, property)
			local st = state[self]
			local found = member(st.className, property)
			if found == nil or found.kind ~= "property" then
				error(`{property} is not a valid property name.`, 2)
			end
			local signal = st.propertySignals[property]
			if signal == nil then
				signal = newSignal(`{fullName(self)}.{property} changed`)
				st.propertySignals[property] = signal
			end
			return signal
		end,
	}

	methods.Instance = {
		FindFirstChild = function(self, name, recursive)
			local st = state[self]
			local child = findChild(st, name)
			if child or not recursive then
				return child
			end
			for _, candidate in descendants(self, {}) do
				if state[candidate].props.Name == name then
					return candidate
				end
			end
			return nil
		end,
		FindFirstChildOfClass = function(self, className)
			for _, child in state[self].children do
				if state[child].className == className then
					return child
				end
			end
			return nil
		end,
		FindFirstChildWhichIsA = function(self, className)
			for _, child in state[self].children do
				if isA(state[child].className, className) then
					return child
				end
			end
			return nil
		end,
		WaitForChild = function(self, name, timeout)
			local child = findChild(state[self], name)
			if child then
				return child
			end
			assertInSim("WaitForChild")
			local started = sim.now
			local warned = false
			while true do
				child = findChild(state[self], name)
				if child then
					return child
				end
				if timeout and sim.now - started >= timeout then
					return nil
				end
				if not warned and sim.now - started > 5 then
					warned = true
					note(sim.warnings, `Infinite yield possible on '{fullName(self)}:WaitForChild("{name}")'`)
				end
				taskApi.wait(0)
			end
		end,
		GetChildren = function(self)
			return table.clone(state[self].children)
		end,
		GetDescendants = function(self)
			return descendants(self, {})
		end,
		Destroy = function(self)
			local st = state[self]
			if st.destroyed then
				return
			end
			for _, child in table.clone(st.children) do
				child:Destroy()
			end
			if st.signals.Destroying then
				fire(st.signals.Destroying, nil)
			end
			setParent(self, st, nil)
			st.destroyed = true
		end,
		ClearAllChildren = function(self)
			for _, child in table.clone(state[self].children) do
				child:Destroy()
			end
		end,
		IsDescendantOf = function(self, ancestor)
			local cursor = state[self].parent
			while cursor do
				if cursor == ancestor then
					return true
				end
				cursor = state[cursor].parent
			end
			return false
		end,
		GetFullName = function(self)
			return fullName(self)
		end,
		SetAttribute = function(self, name, value)
			local st = state[self]
			st.attributes[name] = value
			if st.attributeSignals[name] then
				fire(st.attributeSignals[name], nil)
			end
		end,
		GetAttribute = function(self, name)
			return state[self].attributes[name]
		end,
		GetAttributeChangedSignal = function(self, name)
			local st = state[self]
			local signal = st.attributeSignals[name]
			if signal == nil then
				signal = newSignal(`{fullName(self)} attribute {name}`)
				st.attributeSignals[name] = signal
			end
			return signal
		end,
	}

	--------------------------------------------------------------------------
	-- The data model and its services

	local game = newInstance("DataModel")
	state[game].props.Name = "Game"
	local services = {}

	local function service(className: string)
		local existing = services[className]
		if existing then
			return existing
		end
		local class = reflection[className]
		if class == nil or not class.service then
			error(`'{className}' is not a valid Service name`, 3)
		end
		local instance = newInstance(className)
		state[instance].props.Name = className
		services[className] = instance
		instance.Parent = game
		return instance
	end

	methods.ServiceProvider = {
		GetService = function(_self, className)
			return service(className)
		end,
		FindService = function(_self, className)
			return services[className]
		end,
	}
	methods.DataModel = {
		IsLoaded = function()
			return true
		end,
	}

	local workspace = service("Workspace")
	local terrain = newInstance("Terrain")
	state[terrain].props.Name = "Terrain"
	terrain.Parent = workspace
	local camera = newInstance("Camera")
	state[camera].props.Name = "Camera"
	camera.Parent = workspace
	for _, name in { "Players", "Lighting", "ReplicatedStorage", "ServerScriptService", "StarterGui", "RunService" } do
		service(name)
	end

	computed.Workspace = {
		Terrain = function()
			return terrain
		end,
		CurrentCamera = function()
			return camera
		end,
	}
	methods.Workspace = {
		GetServerTimeNow = function()
			return sim.now
		end,
	}
	computed.BasePart = {
		Position = function(_instance, st)
			return (st.props.CFrame or roblox.CFrame.new()).Position
		end,
	}
	computed.LayerCollector = {
		AbsoluteSize = function(_instance, st)
			local insets = st.props.ScreenInsets
			if insets == nil or insets == Enum.ScreenInsets.None then
				return sim.screen
			end
			return sim.safeArea
		end,
	}
	computed.Camera = {
		ViewportSize = function()
			return sim.screen
		end,
	}

	methods.PVInstance = {
		GetPivot = function(self)
			local st = state[self]
			if isA(st.className, "BasePart") then
				return self.CFrame
			end
			local primary = st.props.PrimaryPart
			if primary then
				return primary.CFrame
			end
			return st.props.WorldPivot or roblox.CFrame.new()
		end,
		PivotTo = function(self, target)
			if typeOf(target) ~= "CFrame" then
				error("PivotTo expects a CFrame", 2)
			end
			local delta = target * self:GetPivot():Inverse()
			if isA(state[self].className, "BasePart") then
				self.CFrame = target
				return
			end
			for _, descendant in descendants(self, {}) do
				if isA(state[descendant].className, "BasePart") then
					descendant.CFrame = delta * descendant.CFrame
				end
			end
		end,
	}

	methods.Terrain = {
		FillBlock = function(_self, cframe, size, material)
			assert(typeOf(cframe) == "CFrame" and typeOf(size) == "Vector3", "FillBlock(CFrame, Vector3, Material)")
			assert(typeOf(material) == "EnumItem" and Enum.Material[material.Name] == material, "FillBlock material")
		end,
	}

	-- Players and client contexts ----------------------------------------------
	local players = service("Players")
	local clientPlayer = {} -- context -> Player
	local users = {}

	local UserMT = { __type = "User" }
	UserMT.__index = UserMT

	computed.Players = {
		LocalPlayer = function()
			return clientPlayer[currentContext()]
		end,
	}
	computed.Player = {
		User = function(instance)
			return users[instance]
		end,
	}
	methods.Players = {
		GetPlayers = function()
			local list = {}
			for _, child in state[players].children do
				if state[child].className == "Player" then
					table.insert(list, child)
				end
			end
			return list
		end,
		GetPlayerByUserId = function(_self, id)
			for _, child in state[players].children do
				if state[child].props.UserId == id then
					return child
				end
			end
			return nil
		end,
	}

	-- Run service and input --------------------------------------------------------
	local runService = service("RunService")
	local renderSteps = {}
	methods.RunService = {
		IsServer = function()
			return currentContext() == "server"
		end,
		IsClient = function()
			return clientPlayer[currentContext()] ~= nil
		end,
		IsStudio = function()
			return false
		end,
		IsRunning = function()
			return true
		end,
		BindToRenderStep = function(_self, name, priority, fn)
			if clientPlayer[currentContext()] == nil then
				error("BindToRenderStep can only be used on the client", 2)
			end
			assert(
				type(name) == "string" and type(priority) == "number" and type(fn) == "function",
				"BindToRenderStep args"
			)
			table.insert(renderSteps, { name = name, priority = priority, fn = fn, context = currentContext() })
			table.sort(renderSteps, function(a, b)
				return a.priority < b.priority
			end)
		end,
		UnbindFromRenderStep = function(_self, name)
			for i = #renderSteps, 1, -1 do
				if renderSteps[i].name == name and renderSteps[i].context == currentContext() then
					table.remove(renderSteps, i)
				end
			end
		end,
	}

	local input = service("UserInputService")
	computed.UserInputService = {
		PreferredInput = function()
			return sim.preferredInput
		end,
		TouchEnabled = function()
			return sim.preferredInput == Enum.PreferredInput.Touch
		end,
		KeyboardEnabled = function()
			return sim.preferredInput == Enum.PreferredInput.KeyboardAndMouse
		end,
	}
	methods.UserInputService = {
		GetFocusedTextBox = function()
			return nil
		end,
		IsKeyDown = function(_self, key)
			assert(typeOf(key) == "EnumItem" and Enum.KeyCode[key.Name] == key, "IsKeyDown expects a KeyCode")
			return false
		end,
	}
	service("GuiService")
	methods.StarterGui = {
		SetCoreGuiEnabled = function(_self, kind, enabled)
			assert(typeOf(kind) == "EnumItem" and Enum.CoreGuiType[kind.Name] == kind, "SetCoreGuiEnabled type")
			assert(type(enabled) == "boolean", "SetCoreGuiEnabled enabled")
			table.insert(sim.coreCalls, `SetCoreGuiEnabled {kind.Name} {enabled}`)
		end,
		SetCore = function(_self, name, value)
			table.insert(sim.coreCalls, `SetCore {name} {tostring(value)}`)
		end,
		GetCore = function()
			return nil
		end,
	}

	-- Remotes -------------------------------------------------------------------------
	local function copyArgument(value: any, depth: number, seen)
		local kind = type(value)
		if kind == "function" or kind == "thread" then
			error(`sim: a {kind} can't be sent through a RemoteEvent`, depth)
		elseif kind ~= "table" or isInstance(value) or getmetatable(value) ~= nil then
			return value
		end
		if seen[value] then
			error("sim: a table with a cycle can't be sent through a RemoteEvent", depth)
		end
		seen[value] = true
		local count, hasString, hasNumber = 0, false, false
		for key in value do
			count += 1
			if type(key) == "string" then
				hasString = true
			elseif type(key) == "number" then
				hasNumber = true
			else
				error(`sim: remote table keys must be strings or array indices, got {typeOf(key)}`, depth)
			end
		end
		if hasString and hasNumber then
			error("sim: a table mixing array and string keys loses data in a RemoteEvent", depth)
		end
		if hasNumber and count ~= #value then
			error("sim: an array with holes loses data in a RemoteEvent", depth)
		end
		local copy = {}
		for key, child in value do
			copy[key] = copyArgument(child, depth + 1, seen)
		end
		seen[value] = nil
		return copy
	end

	local function copyArguments(...)
		local packed = table.pack(...)
		for i = 1, packed.n do
			packed[i] = copyArgument(packed[i], 4, {})
		end
		return packed
	end

	methods.RemoteEvent = {
		FireServer = function(self, ...)
			local player = clientPlayer[currentContext()]
			if player == nil then
				error("FireServer can only be called from the client", 2)
			end
			local args = copyArguments(...)
			fire(eventFor(self, state[self], "OnServerEvent"), function(context)
				return context == "server"
			end, player, table.unpack(args, 1, args.n))
		end,
		FireAllClients = function(self, ...)
			if currentContext() ~= "server" then
				error("FireAllClients can only be called from the server", 2)
			end
			local args = copyArguments(...)
			fire(eventFor(self, state[self], "OnClientEvent"), function(context)
				return clientPlayer[context] ~= nil
			end, table.unpack(args, 1, args.n))
		end,
		FireClient = function(self, player, ...)
			if currentContext() ~= "server" then
				error("FireClient can only be called from the server", 2)
			end
			if not (isInstance(player) and state[player].className == "Player") then
				error("FireClient: player argument must be a Player", 2)
			end
			local args = copyArguments(...)
			fire(eventFor(self, state[self], "OnClientEvent"), function(context)
				return clientPlayer[context] == player
			end, table.unpack(args, 1, args.n))
		end,
	}

	-- Tweens ------------------------------------------------------------------------------
	local TweenInfoMT = { __type = "TweenInfo" }
	TweenInfoMT.__index = TweenInfoMT
	local TweenInfoApi = {
		new = function(time, style, direction, repeatCount, reverses, delayTime)
			local function enumOrNil(value, enum, label)
				if value ~= nil then
					assert(typeOf(value) == "EnumItem" and enum[value.Name] == value, `TweenInfo {label}`)
				end
			end
			enumOrNil(style, Enum.EasingStyle, "EasingStyle")
			enumOrNil(direction, Enum.EasingDirection, "EasingDirection")
			assert(time == nil or type(time) == "number", "TweenInfo time")
			return setmetatable({
				Time = time or 1,
				EasingStyle = style or Enum.EasingStyle.Quad,
				EasingDirection = direction or Enum.EasingDirection.Out,
				RepeatCount = repeatCount or 0,
				Reverses = reverses or false,
				DelayTime = delayTime or 0,
			}, TweenInfoMT)
		end,
	}

	local tweens = setmetatable({}, { __mode = "k" })
	methods.TweenService = {
		Create = function(_self, target, info, goals)
			if not isInstance(target) then
				error("TweenService:Create expects an Instance", 2)
			end
			if typeOf(info) ~= "TweenInfo" then
				error("TweenService:Create expects a TweenInfo", 2)
			end
			local className = state[target].className
			for key, value in goals do
				local found = member(className, key)
				if found == nil or found.kind ~= "property" or found.info.readOnly then
					error(`TweenService:Create no property named '{key}' for object '{fullName(target)}'`, 2)
				end
				checkValue(className, key, found.info, value, 3)
				if not TWEENABLE[typeOf(value)] then
					error(`TweenService:Create property named '{key}' cannot be tweened ({typeOf(value)})`, 2)
				end
			end
			local tween = newInstance("Tween")
			tweens[tween] = { target = target, info = info, goals = table.clone(goals), token = 0 }
			state[tween].props.PlaybackState = Enum.PlaybackState.Begin
			return tween
		end,
	}
	methods.TweenBase = {
		Play = function(self)
			local tween = tweens[self]
			tween.token += 1
			local token = tween.token
			state[self].props.PlaybackState = Enum.PlaybackState.Playing
			local duration = tween.info.Time + tween.info.DelayTime
			sleep("engine", duration, function()
				if tween.token ~= token then
					return
				end
				for key, value in tween.goals do
					tween.target[key] = value
				end
				state[self].props.PlaybackState = Enum.PlaybackState.Completed
				fire(eventFor(self, state[self], "Completed"), nil, Enum.PlaybackState.Completed)
			end)
		end,
		Cancel = function(self)
			local tween = tweens[self]
			if state[self].props.PlaybackState == Enum.PlaybackState.Playing then
				tween.token += 1
				state[self].props.PlaybackState = Enum.PlaybackState.Cancelled
				fire(eventFor(self, state[self], "Completed"), nil, Enum.PlaybackState.Cancelled)
			end
		end,
		Pause = function(self)
			tweens[self].token += 1
			state[self].props.PlaybackState = Enum.PlaybackState.Paused
		end,
	}

	-- Data stores and badges ---------------------------------------------------------------
	local function storable(value: any, depth: number)
		local kind = type(value)
		if kind == "table" then
			for key, child in value do
				if type(key) ~= "string" and type(key) ~= "number" then
					error("sim: DataStore keys must be strings or numbers", depth)
				end
				storable(child, depth + 1)
			end
		elseif kind ~= "string" and kind ~= "number" and kind ~= "boolean" then
			error(`sim: a {typeOf(value)} can't be saved in a DataStore`, depth)
		end
	end

	methods.DataStoreService = {
		GetDataStore = function(_self, name)
			assert(type(name) == "string", "GetDataStore name")
			local instance = newInstance("DataStore")
			state[instance].props.Name = name
			sim.stores[name] = sim.stores[name] or {}
			state[instance].storeName = name
			return instance
		end,
	}
	methods.GlobalDataStore = {
		GetAsync = function(self, key)
			assert(type(key) == "string", "GetAsync key")
			taskApi.wait(0.05)
			local value = sim.stores[state[self].storeName][key]
			return if value == nil then nil else serde.decode("json", serde.encode("json", value))
		end,
		UpdateAsync = function(self, key, transform)
			assert(type(key) == "string" and type(transform) == "function", "UpdateAsync(key, fn)")
			taskApi.wait(0.05)
			local store = sim.stores[state[self].storeName]
			local old = store[key]
			local copy = if old == nil then nil else serde.decode("json", serde.encode("json", old))
			local new = transform(copy, nil)
			if new ~= nil then
				storable(new, 2)
				store[key] = serde.decode("json", serde.encode("json", new))
			end
			return new
		end,
	}
	methods.BadgeService = {
		AwardBadgeAsync = function(_self, user, badgeId)
			assert(typeOf(user) == "User" or type(user) == "number", "AwardBadgeAsync user")
			assert(type(badgeId) == "number", "AwardBadgeAsync badgeId")
			taskApi.wait(0.05)
			table.insert(sim.badges, { user = user, badge = badgeId })
			return true
		end,
	}

	--------------------------------------------------------------------------
	-- Scripts and modules

	local RandomMT = { __type = "Random" }
	RandomMT.__index = RandomMT
	function RandomMT.NextNumber(_self, low, high)
		low, high = low or 0, high or 1
		return low + math.random() * (high - low)
	end
	function RandomMT.NextInteger(_self, low, high)
		return math.random(low, high)
	end
	local RandomApi = {
		new = function()
			return setmetatable({}, RandomMT)
		end,
	}

	local function output(kind: string, ...)
		local parts = {}
		for i = 1, select("#", ...) do
			table.insert(parts, tostring(select(i, ...)))
		end
		local line = table.concat(parts, " ")
		table.insert(sim.output, `[{currentContext()}] {kind}: {line}`)
		if kind == "warn" then
			table.insert(sim.warnings, line)
		end
	end

	local baseGlobals = {
		game = game,
		workspace = workspace,
		Instance = InstanceApi,
		Enum = Enum,
		typeof = typeOf,
		task = taskApi,
		print = function(...)
			output("print", ...)
		end,
		warn = function(...)
			output("warn", ...)
		end,
		os = {
			clock = function()
				return sim.now
			end,
			time = function()
				return math.floor(sim.now)
			end,
			date = os.date,
		},
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = CFrameApi,
		Color3 = roblox.Color3,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Font = roblox.Font,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		TweenInfo = TweenInfoApi,
		Random = RandomApi,
		assert = assert,
		error = error,
		pcall = pcall,
		xpcall = xpcall,
		type = type,
		tostring = tostring,
		tonumber = tonumber,
		select = select,
		next = next,
		pairs = pairs,
		ipairs = ipairs,
		rawget = rawget,
		rawset = rawset,
		rawequal = rawequal,
		rawlen = rawlen,
		setmetatable = setmetatable,
		getmetatable = getmetatable,
		math = math,
		string = string,
		table = table,
		coroutine = coroutine,
		utf8 = utf8,
		bit32 = bit32,
		buffer = buffer,
		debug = debug,
	}

	local moduleCaches = {}

	local function dataModelPath(from: string, request: string): string
		local base, rest
		if string.sub(request, 1, 2) == "./" then
			base, rest = split(from), string.sub(request, 3)
			table.remove(base)
		elseif string.sub(request, 1, 3) == "../" then
			base, rest = split(from), string.sub(request, 4)
			table.remove(base)
			table.remove(base)
		elseif string.sub(request, 1, 6) == "@game/" then
			base, rest = {}, string.sub(request, 7)
		elseif string.sub(request, 1, 6) == "@self/" then
			base, rest = split(from), string.sub(request, 7)
		else
			error(`sim: unsupported require path "{request}" in {from}`, 3)
		end
		for _, part in split(rest) do
			if part == ".." then
				table.remove(base)
			elseif part ~= "." then
				table.insert(base, part)
			end
		end
		return table.concat(base, "/")
	end

	local requireModule

	local function environment(context: string, path: string)
		return setmetatable({
			require = function(request)
				return requireModule(context, path, request)
			end,
			script = { Name = split(path)[#split(path)] },
		}, { __index = baseGlobals })
	end

	requireModule = function(context: string, from: string, request: string)
		local path = dataModelPath(from, request)
		local cache = moduleCaches[context]
		local entry = cache[path]
		if entry then
			if entry.loading then
				error(`sim: require cycle through {path}`, 2)
			end
			return entry.value
		end
		local source = sources[`{path}.luau`]
		if source == nil then
			error(`sim: no module at {path} (require("{request}") in {from})`, 2)
		end
		entry = { loading = true }
		cache[path] = entry
		local chunk = luau.load(source, {
			debugName = path,
			environment = environment(context, path),
			injectGlobals = false,
		})
		local value = chunk()
		if value == nil then
			error(`Module code did not return exactly one value: {path}`, 2)
		end
		entry.loading = false
		entry.value = value
		return value
	end

	local function runScript(context: string, path: string, file: string)
		moduleCaches[context] = moduleCaches[context] or {}
		local source = sources[file]
		assert(source, `sim: no script at {file}`)
		local chunk = luau.load(source, {
			debugName = path,
			environment = environment(context, path),
			injectGlobals = false,
		})
		local thread = newThread(context, chunk)
		resume(thread)
		drain()
	end

	--------------------------------------------------------------------------
	-- Test API

	function sim:startServer()
		runScript("server", "ServerScriptService/Server", "ServerScriptService/Server.server.luau")
	end

	function sim:addPlayer(name: string, userId: number, displayName: string?)
		local player = newInstance("Player")
		local st = state[player]
		st.props.Name = name
		st.props.DisplayName = displayName or name
		st.props.UserId = userId
		users[player] = setmetatable({ Id = userId }, UserMT)
		local gui = newInstance("PlayerGui")
		state[gui].props.Name = "PlayerGui"
		gui.Parent = player
		local context = `client:{userId}`
		clientPlayer[context] = player
		player.Parent = players
		fire(eventFor(players, state[players], "PlayerAdded"), nil, player)
		drain()
		runScript(context, "ReplicatedStorage/Client", "ReplicatedStorage/Client.client.luau")
		return player
	end

	function sim:removePlayer(player)
		fire(eventFor(players, state[players], "PlayerRemoving"), nil, player)
		drain()
		deadContexts[`client:{state[player].props.UserId}`] = true
		for context, candidate in clientPlayer do
			if candidate == player then
				clientPlayer[context] = nil
			end
		end
		player.Parent = nil
		drain()
	end

	function sim:step(dt: number)
		sim.now += dt
		sim.frames += 1
		for _, step in table.clone(renderSteps) do
			if not deadContexts[step.context] then
				local thread = newThread(step.context, step.fn)
				resume(thread, dt)
			end
		end
		local renderStepped = state[runService].signals.RenderStepped
		if renderStepped then
			fire(renderStepped, function(context)
				return clientPlayer[context] ~= nil
			end, dt)
		end
		drain()
		local due = {}
		for i = #sleepers, 1, -1 do
			if sleepers[i].time <= sim.now then
				table.insert(due, table.remove(sleepers, i))
			end
		end
		table.sort(due, function(a, b)
			return if a.time == b.time then a.seq < b.seq else a.time < b.time
		end)
		for _, sleeper in due do
			resume(sleeper.thread, table.unpack(sleeper.args, 1, sleeper.args.n))
			drain()
		end
		local heartbeat = state[runService].signals.Heartbeat
		if heartbeat then
			fire(heartbeat, nil, dt)
		end
		drain()
	end

	-- Steps frames until `predicate` returns true or `limit` virtual seconds pass.
	function sim:runUntil(predicate: () -> boolean, limit: number, dt: number?, onFrame: (() -> ())?): boolean
		local stop = sim.now + limit
		while sim.now < stop do
			sim:step(dt or 1 / 30)
			if onFrame then
				onFrame()
				drain()
			end
			if predicate() then
				return true
			end
		end
		return false
	end

	function sim:run(seconds: number, dt: number?, onFrame: (() -> ())?)
		sim:runUntil(function()
			return false
		end, seconds, dt, onFrame)
	end

	-- Visible on screen: this object, every GuiObject above it, and its ScreenGui.
	function sim:shown(object): boolean
		local cursor = object
		while cursor and state[cursor] do
			local st = state[cursor]
			if isA(st.className, "GuiObject") and cursor.Visible == false then
				return false
			elseif isA(st.className, "LayerCollector") then
				return cursor.Enabled ~= false
			end
			cursor = st.parent
		end
		return false
	end

	-- A player tapping or clicking a button: only works if it's on screen and interactable.
	function sim:click(button)
		assert(isA(state[button].className, "GuiButton"), `{fullName(button)} isn't a button`)
		assert(sim:shown(button), `clicked {fullName(button)} while it's hidden`)
		assert(button.Interactable, `clicked {fullName(button)} while it's disabled`)
		fire(eventFor(button, state[button], "Activated"), nil, nil, 1)
		drain()
	end

	-- A key (or gamepad button) press reaching the game, not eaten by the UI.
	function sim:pressKey(keyCode: EnumItem)
		local inputType = if string.sub(keyCode.Name, 1, 6) == "Button"
			then Enum.UserInputType.Gamepad1
			else Enum.UserInputType.Keyboard
		local inputObject = {
			KeyCode = keyCode,
			UserInputType = inputType,
			UserInputState = Enum.UserInputState.Begin,
			Position = roblox.Vector3.zero,
			Delta = roblox.Vector3.zero,
		}
		fire(eventFor(input, state[input], "InputBegan"), function(context)
			return clientPlayer[context] ~= nil
		end, inputObject, false)
		drain()
	end

	function sim:className(instance): string
		return state[instance].className
	end

	sim.game = game
	sim.workspace = workspace
	sim.drain = function(_self)
		drain()
	end

	return sim
end

return Sim
