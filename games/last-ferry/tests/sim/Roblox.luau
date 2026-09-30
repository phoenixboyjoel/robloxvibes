--!nonstrict
--[[
	A headless Roblox for tests: enough of the engine to run the game's real
	server and client scripts together on a virtual clock.

	- Instances are mocks held to tests/sim/reflection.json (generated from the
	  Roblox API dump): unknown members, wrong value types and writes to read-only
	  properties raise the same way they would in Roblox, and deprecated members
	  are recorded.
	- task.*, signals (deferred, as the place is set), TweenService,
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

-- Roblox's top bar row keeps its left end for its own buttons: the Roblox button (16 to
-- 60 px from the device safe area's left edge) and the unibar with the menu and chat (68
-- to 164).
local TOP_BAR_BUTTONS = 164

function Sim.new(
	options: {
		root: string?,
		screen: Vector2?,
		safeArea: Vector2?,
		-- The part of Roblox's top bar row left for the game (GuiService.TopbarInset), in
		-- pixels from the device safe area's left edge and the screen's top. By default,
		-- right of Roblox's buttons to the safe area's right edge.
		topbarInset: any?,
		preferredInput: EnumItem?,
		tenFoot: boolean?,
	}?
)
	local opts = options or {}
	local root = opts.root or "."
	local reflection = serde.decode("json", fs.readFile(`{root}/tests/sim/reflection.json`)).classes
	-- Each character's width in the fonts the game uses, as a share of the text size, from
	-- Roblox's own font files (made by gen_fonts.py).
	local fontWidths = serde.decode("json", fs.readFile(`{root}/tests/sim/fonts.json`))

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
		-- Below Roblox's 58 px top bar, where ScreenGuis with CoreUISafeInsets go.
		safeArea = opts.safeArea or opts.screen or roblox.Vector2.new(1280, 662),
		topbarInset = opts.topbarInset,
		preferredInput = opts.preferredInput or Enum.PreferredInput.KeyboardAndMouse,
		-- A console on a TV: GuiService:IsTenFootInterface(), a Large ViewportDisplaySize, and
		-- Roblox's chat never shows.
		tenFoot = opts.tenFoot == true,
		-- When the fonts finish loading, in seconds of game time (at once by default). Roblox
		-- loads each font the first time it's needed; until then, text measures as a
		-- stand-in font's does.
		fontsLoadAt = opts.fontsLoadAt or 0,
		fontsLoaded = (opts.fontsLoadAt or 0) <= 0,
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

	-- Deferred, as the place sets Workspace.SignalBehavior (Roblox's Default still means
	-- Immediate): handlers run at the next resumption point.
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

	local isACache = {}
	local function isA(className: string, target: string): boolean
		local byClass = isACache[className]
		if byClass == nil then
			byClass = {}
			isACache[className] = byClass
		end
		local hit = byClass[target]
		if hit ~= nil then
			return hit
		end
		local name = className
		hit = false
		while name and reflection[name] do
			if name == target then
				hit = true
				break
			end
			name = reflection[name].superclass
		end
		byClass[target] = hit
		return hit
	end

	--------------------------------------------------------------------------
	-- Instances

	local state = setmetatable({}, { __mode = "k" })
	local welds = setmetatable({}, { __mode = "k" }) -- part -> { [part] = true }, from WeldConstraints
	local joints = setmetatable({}, { __mode = "k" }) -- Part0 -> { [joint] = true }, from Motor6Ds and Welds
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

	-- Once the simulator is set up (`sealed`), its method and computed-property tables no
	-- longer change, so lookups up the class chain are cached.
	local sealed = false
	local resolveCache = setmetatable({}, { __mode = "k" })
	local function resolve(map, className: string, key: string)
		local cache
		if sealed then
			local byMap = resolveCache[map]
			if byMap == nil then
				byMap = {}
				resolveCache[map] = byMap
			end
			cache = byMap[className]
			if cache == nil then
				cache = {}
				byMap[className] = cache
			end
			local hit = cache[key]
			if hit ~= nil then
				return hit or nil
			end
		end
		local found = nil
		local name = className
		while name and reflection[name] do
			local byClass = map[name]
			if byClass and byClass[key] then
				found = byClass[key]
				break
			end
			name = reflection[name].superclass
		end
		if cache then
			cache[key] = found or false
		end
		return found
	end

	local ancestryListeners = 0 -- AncestryChanged signals made so far; none, and it's never fired
	local function eventFor(instance, st, key: string)
		if key == "AncestryChanged" and st.signals[key] == nil then
			ancestryListeners += 1
		end
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

	local function computeDefault(st, key: string, info)
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
			CharacterAutoLoads = true,
			RespawnTime = 5,
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

	-- A property's default depends only on the class, and every value type is immutable,
	-- so each is worked out once.
	local defaults = {}
	local NO_DEFAULT = newproxy()
	local function defaultFor(_instance, st, key: string, info)
		local byClass = defaults[st.className]
		if byClass == nil then
			byClass = {}
			defaults[st.className] = byClass
		end
		local value = byClass[key]
		if value == nil then
			value = computeDefault(st, key, info)
			byClass[key] = if value == nil then NO_DEFAULT else value
		end
		return if value == NO_DEFAULT then nil else value
	end

	-- Whether an instance is in the game's tree (under the DataModel).
	local function inGame(instance): boolean
		local cursor = instance
		while cursor do
			local st = state[cursor]
			if st.className == "DataModel" then
				return true
			end
			cursor = st.parent
		end
		return false
	end

	-- CollectionService tags: tag -> { [instance] = true }. As in Roblox, the added and
	-- removed signals only fire for instances in the game's tree: when a tag is added to or
	-- removed from one, or a tagged instance enters or leaves the tree.
	local tagged = {}
	local tagSignals = {}
	local function tagSignal(tag: string, kind: string)
		local key = `{kind}:{tag}`
		local signal = tagSignals[key]
		if signal == nil then
			signal = newSignal(`CollectionService {kind} {tag}`)
			tagSignals[key] = signal
		end
		return signal
	end
	local function addTag(instance, tag: string)
		assert(type(tag) == "string", "AddTag expects a string")
		tagged[tag] = tagged[tag] or {}
		if not tagged[tag][instance] then
			tagged[tag][instance] = true
			if inGame(instance) then
				fire(tagSignal(tag, "added"), nil, instance)
			end
		end
	end
	local function removeTag(instance, tag: string)
		if tagged[tag] and tagged[tag][instance] then
			tagged[tag][instance] = nil
			if inGame(instance) then
				fire(tagSignal(tag, "removed"), nil, instance)
			end
		end
	end
	local function untagAll(instance)
		for tag, members in tagged do
			if members[instance] then
				removeTag(instance, tag)
			end
		end
	end
	-- `root` and everything under it entered (kind "added") or left ("removed") the tree.
	local function retagTree(root, kind: string)
		local function visit(instance)
			for tag, members in tagged do
				if members[instance] then
					fire(tagSignal(tag, kind), nil, instance)
				end
			end
			for _, child in state[instance].children do
				visit(child)
			end
		end
		visit(root)
	end

	-- Tests can count who writes a property: sim:countWrites(instance, key).
	local writeCounts = setmetatable({}, { __mode = "k" })

	-- GUI changes, so a laid-out position or size (see layoutOf) is kept only until
	-- something it depends on changes. Each GUI object has a stamp for its own last change
	-- (`guiOwn`: its properties, its UIScale, UIPadding or UIListLayout, or which children
	-- it has) and for the last change anywhere inside it (`guiInside`).
	local guiStamp = 0
	local isGuiCache = {}
	local function isGui(className: string): boolean
		local hit = isGuiCache[className]
		if hit == nil then
			hit = isA(className, "GuiBase2d") or isA(className, "UIComponent")
			isGuiCache[className] = hit
		end
		return hit
	end
	local function touchGui(instance)
		guiStamp += 1
		local st = state[instance]
		local node = instance
		-- A UI component changes how its parent lays out.
		if isA(st.className, "UIComponent") and st.parent then
			node = st.parent
		end
		state[node].guiOwn = guiStamp
		while node do
			local nst = state[node]
			nst.guiInside = guiStamp
			node = nst.parent
		end
	end

	local function changed(instance, st, key: string, value: any)
		local counts = writeCounts[instance]
		if counts and counts[key] then
			local context = currentContext()
			counts[key][context] = (counts[key][context] or 0) + 1
		end
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
		local wasInGame = old ~= nil and inGame(old)
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
		if isGui(st.className) then
			touchGui(instance)
			for _, holder in { old, parent } do
				if holder and isGui(state[holder].className) then
					touchGui(holder) -- its children changed
				end
			end
		end
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
		local isInGame = parent ~= nil and inGame(parent)
		if isInGame ~= wasInGame then
			retagTree(instance, if isInGame then "added" else "removed")
		end
		-- AncestryChanged(child, parent) fires on the instance and everything under it.
		if ancestryListeners > 0 then
			local function tell(node)
				local signal = state[node].signals.AncestryChanged
				if signal then
					fire(signal, nil, instance, parent)
				end
				for _, child in state[node].children do
					tell(child)
				end
			end
			tell(instance)
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

	-- Assemblies: moving a part moves every part welded to it (WeldConstraint), and poses
	-- every part jointed below it (Motor6D, Weld): Part1 = Part0 * C0 * Transform * C1:Inverse().
	local propagate

	local function placePart(part, cframe)
		local partState = state[part]
		local old = partState.props.CFrame or roblox.CFrame.new()
		partState.props.CFrame = cframe
		if old ~= cframe then
			changed(part, partState, "CFrame", cframe)
		end
		return old
	end

	local function solveJoint(joint, visited)
		local p = state[joint].props
		local part0, part1 = p.Part0, p.Part1
		if p.Enabled == false or part0 == nil or part1 == nil or visited[part1] then
			return
		end
		local transform = if state[joint].className == "Motor6D"
			then p.Transform or roblox.CFrame.new()
			else roblox.CFrame.new()
		local c1 = p.C1 or roblox.CFrame.new()
		local target = (state[part0].props.CFrame or roblox.CFrame.new())
			* (p.C0 or roblox.CFrame.new())
			* transform
			* c1:Inverse()
		visited[part1] = true
		local old = placePart(part1, target)
		propagate(part1, old, visited)
	end

	propagate = function(part, old, visited)
		local now = state[part].props.CFrame or roblox.CFrame.new()
		if welds[part] and old ~= now then
			local delta = now * old:Inverse()
			for other in welds[part] do
				if not visited[other] then
					visited[other] = true
					local otherOld = placePart(other, delta * (state[other].props.CFrame or roblox.CFrame.new()))
					propagate(other, otherOld, visited)
				end
			end
		end
		for joint in joints[part] or {} do
			solveJoint(joint, visited)
		end
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
		if key == "Position" and (isA(st.className, "BasePart") or st.className == "Attachment") then
			-- Position is the translation part of CFrame, for parts and attachments alike.
			local cframe = st.props.CFrame or roblox.CFrame.new()
			key, value = "CFrame", cframe.Rotation + value
		end
		local old = st.props[key]
		st.props[key] = value
		if old ~= value then
			if isGui(st.className) then
				touchGui(instance)
			end
			changed(instance, st, key, value)
		end
		if key == "IgnoreGuiInset" and st.className == "ScreenGui" then
			-- As in Roblox: true moves a ScreenGui from the safe area below the top bar to the
			-- device's safe area, top bar and all; false moves it back.
			local insets = instance.ScreenInsets
			if value and insets == Enum.ScreenInsets.CoreUISafeInsets then
				instance.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
			elseif not value and insets == Enum.ScreenInsets.DeviceSafeInsets then
				instance.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
			end
		end
		if st.className == "WeldConstraint" and (key == "Part0" or key == "Part1") then
			local part0, part1 = st.props.Part0, st.props.Part1
			if part0 and part1 then
				welds[part0] = welds[part0] or {}
				welds[part1] = welds[part1] or {}
				welds[part0][part1] = true
				welds[part1][part0] = true
			end
		elseif
			isA(st.className, "JointInstance")
			and (
				key == "Part0"
				or key == "Part1"
				or key == "C0"
				or key == "C1"
				or key == "Transform"
				or key == "Enabled"
			)
		then
			if key == "Part0" then
				if old and joints[old] then
					joints[old][instance] = nil
				end
				if value then
					joints[value] = joints[value] or {}
					joints[value][instance] = true
				end
			end
			solveJoint(instance, {})
		elseif key == "CFrame" and isA(st.className, "BasePart") then
			-- Moving a part moves its welded assembly and poses the parts jointed below it.
			if old ~= nil and old ~= value or joints[instance] then
				propagate(instance, old or value, { [instance] = true })
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

	-- What an attribute can hold (Roblox's Properties window docs list the same types).
	local ATTRIBUTE_TYPES = {
		string = true,
		boolean = true,
		number = true,
		UDim = true,
		UDim2 = true,
		BrickColor = true,
		Color3 = true,
		Vector2 = true,
		Vector3 = true,
		CFrame = true,
		NumberSequence = true,
		ColorSequence = true,
		NumberRange = true,
		Rect = true,
		Font = true,
	}

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
				if not warned and timeout == nil and sim.now - started > 5 then
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
			local part0 = isA(st.className, "JointInstance") and st.props.Part0
			if part0 and joints[part0] then
				joints[part0][self] = nil
			end
			untagAll(self)
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
			if type(name) ~= "string" or #name == 0 or #name > 100 or string.find(name, "[^%w_%.%-/]") then
				error(
					`Attribute name "{name}" is invalid: use letters, digits, periods, hyphens, slashes and underscores, up to 100`,
					2
				)
			elseif string.sub(name, 1, 3) == "RBX" then
				error(`Attribute name "{name}" is reserved: names starting with RBX are Roblox's`, 2)
			elseif value ~= nil and not ATTRIBUTE_TYPES[typeOf(value)] then
				error(`{typeOf(value)} is not a supported attribute type ("{name}" on {fullName(self)})`, 2)
			end
			local st = state[self]
			local old = st.attributes[name]
			st.attributes[name] = value
			-- As in Roblox, only a change fires: setting the same value again does nothing.
			if old ~= value and st.attributeSignals[name] then
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
		AddTag = function(self, tag)
			addTag(self, tag)
		end,
		RemoveTag = function(self, tag)
			removeTag(self, tag)
		end,
		HasTag = function(self, tag)
			return tagged[tag] ~= nil and tagged[tag][self] == true
		end,
		GetTags = function(self)
			local list = {}
			for tag, members in tagged do
				if members[self] then
					table.insert(list, tag)
				end
			end
			return list
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

	-- Service properties the Rojo project file sets, as a built place would have them.
	-- Properties scripts can't see at all (Lighting.Technology) are skipped; `rojo build`
	-- checks those names.
	local projectPath = `{root}/default.project.json`
	if fs.isFile(projectPath) then
		local project = serde.decode("json", fs.readFile(projectPath))
		-- Signals here always run deferred. A place left on Default runs them immediately
		-- (for now), which changes the order things happen in, so the place must say Deferred.
		local workspaceProperties = project.tree and project.tree.Workspace and project.tree.Workspace["$properties"]
		if workspaceProperties == nil or workspaceProperties.SignalBehavior ~= "Deferred" then
			error(
				'sim: set Workspace.SignalBehavior to "Deferred" in default.project.json; the simulator only runs signals deferred',
				2
			)
		end
		-- Roblox's controls bind jump through ContextActionService unless the place opts into
		-- the Input Action System, which isn't simulated.
		if workspaceProperties.PlayerScriptsUseInputActionSystem ~= "Disabled" then
			error(
				'sim: set Workspace.PlayerScriptsUseInputActionSystem to "Disabled"; Roblox\'s controls are simulated on ContextActionService',
				2
			)
		end
		for serviceName, entry in project.tree or {} do
			if type(entry) == "table" and entry["$properties"] and reflection[serviceName] then
				local instance = service(serviceName)
				for key, raw in entry["$properties"] do
					local found = member(serviceName, key)
					if found == nil or found.kind ~= "property" then
						continue
					end
					local info = found.info
					local value = raw
					if info.category == "Enum" then
						value = Enum[info.type][raw]
					elseif info.type == "Color3" then
						value = roblox.Color3.new(raw[1], raw[2], raw[3])
					elseif info.type == "Vector3" then
						value = roblox.Vector3.new(raw[1], raw[2], raw[3])
					end
					checkValue(serviceName, key, info, value, 2)
					state[instance].props[key] = value
				end
			end
		end
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
	local function attachmentWorld(st)
		local local_ = st.props.CFrame or roblox.CFrame.new()
		local parent = st.parent
		if parent and isA(state[parent].className, "BasePart") then
			return (state[parent].props.CFrame or roblox.CFrame.new()) * local_
		end
		return local_
	end
	computed.Attachment = {
		Position = function(_instance, st)
			return (st.props.CFrame or roblox.CFrame.new()).Position
		end,
		WorldCFrame = function(_instance, st)
			return attachmentWorld(st)
		end,
		WorldPosition = function(_instance, st)
			return attachmentWorld(st).Position
		end,
	}
	-- Roblox's screen coordinates, as its docs define them. The camera renders the whole
	-- screen. The device safe area leaves out any notch (sideInset, each side, in
	-- landscape); Roblox's top bar is the top of it (topInset). GUI coordinates
	-- (AbsolutePosition, InputObject.Position, WorldToScreenPoint) start at the bottom-left
	-- corner of the top bar; viewport coordinates (WorldToViewportPoint, ViewportSize)
	-- start at its top-left. A ScreenGui covers the safe area below the top bar by default
	-- (CoreUISafeInsets), the whole screen with None, the device safe area with
	-- DeviceSafeInsets, and the top bar row's free part with TopbarSafeInsets.
	local function topInset(): number
		return sim.screen.Y - sim.safeArea.Y
	end
	local function sideInset(): number
		return (sim.screen.X - sim.safeArea.X) / 2
	end
	-- The top bar row's free part, GuiService.TopbarInset: from the device safe area's
	-- left edge and the screen's top edge.
	local function topbarInset()
		if sim.topbarInset == nil then
			local left = math.min(TOP_BAR_BUTTONS, sim.safeArea.X)
			sim.topbarInset = roblox.Rect.new(left, 0, sim.safeArea.X, topInset())
		end
		return sim.topbarInset
	end
	computed.GuiService = {
		TopbarInset = function()
			return topbarInset()
		end,
		-- A TV, a phone or tablet, or a computer's screen.
		ViewportDisplaySize = function()
			return if sim.tenFoot
				then Enum.DisplaySize.Large
				elseif sim.preferredInput == Enum.PreferredInput.Touch then Enum.DisplaySize.Small
				else Enum.DisplaySize.Medium
		end,
	}
	-- Where a ScreenGui's area is, in GUI coordinates, and how big it is.
	local function screenArea(instance, st)
		local insets = if st.className == "ScreenGui" then instance.ScreenInsets else Enum.ScreenInsets.None
		if insets == Enum.ScreenInsets.CoreUISafeInsets then
			return roblox.Vector2.zero, sim.safeArea
		elseif insets == Enum.ScreenInsets.DeviceSafeInsets then
			return roblox.Vector2.new(0, -topInset()), roblox.Vector2.new(sim.safeArea.X, sim.screen.Y)
		elseif insets == Enum.ScreenInsets.TopbarSafeInsets then
			local inset = topbarInset()
			return roblox.Vector2.new(inset.Min.X, inset.Min.Y - topInset()),
				roblox.Vector2.new(inset.Width, inset.Height)
		end
		return roblox.Vector2.new(-sideInset(), -topInset()), sim.screen
	end
	computed.LayerCollector = {
		AbsoluteSize = function(instance, st)
			local _, size = screenArea(instance, st)
			return size
		end,
		AbsolutePosition = function(instance, st)
			local position = screenArea(instance, st)
			return position
		end,
	}
	-- The character widths for a Font: its family's (Gotham is drawn as Montserrat, as
	-- Roblox draws it) at the nearest weight that ships with Roblox, or nil for a font
	-- that isn't in fonts.json.
	local faces = {}
	local function faceWidths(font): { [string]: number }?
		if font == nil then
			return nil
		end
		local key = `{font.Family}|{font.Weight.Value}`
		local found = faces[key]
		if found == nil then
			local family = string.match(font.Family, "families/(.-)%.json$")
			if family == "GothamSSm" or family == "Gotham" then
				family = "Montserrat"
			end
			local weights = family and fontWidths[family]
			local gap = math.huge
			found = false
			for weight, widths in weights or {} do
				local off = math.abs(tonumber(weight) - font.Weight.Value)
				if off < gap then
					found, gap = widths, off
				end
			end
			faces[key] = found
		end
		return found or nil
	end

	local ENTITIES = { lt = "<", gt = ">", amp = "&", quot = '"', apos = "'" }

	-- How much room text takes, as Roblox lays it out: each character as wide as it is in
	-- its font (no kerning), a line for each line break, and, wrapped at `maxWidth` if
	-- given, breaking lines between words and breaking a word wider than a line across
	-- lines. While the fonts are loading, and for a font it doesn't know, every character
	-- is about half the text size wide (a fifth less while loading, as a stand-in font's).
	local function measureText(st, maxWidth: number?)
		local text = st.props.Text or ""
		if st.props.RichText then
			text = string.gsub(string.gsub(text, "<[^>]*>", ""), "&(%a+);", ENTITIES)
		end
		if text == "" then
			return roblox.Vector2.zero
		end
		local size = st.props.TextSize or 14
		local widths = if sim.fontsLoaded then faceWidths(st.props.FontFace) else nil
		local rough = if sim.fontsLoaded then 0.52 else 0.42
		local function width(character: string): number
			if widths then
				return (widths[character] or widths["?"]) * size
			end
			return (if character == " " then rough * 0.55 else rough) * size
		end
		local limit = if maxWidth and maxWidth > 0 then maxWidth else math.huge
		local space = width(" ")
		local lines, widest = 0, 0
		for line in string.gmatch(text .. "\n", "(.-)\n") do
			lines += 1
			local current = 0
			local function breakLine()
				widest = math.max(widest, current)
				lines += 1
				current = 0
			end
			for word in string.gmatch(line, "%S+") do
				local wordWidth = 0
				for _, code in utf8.codes(word) do
					wordWidth += width(utf8.char(code))
				end
				if current > 0 and current + space + wordWidth <= limit then
					current += space + wordWidth
				else
					if current > 0 then
						breakLine()
					end
					if wordWidth <= limit then
						current = wordWidth
					else
						for _, code in utf8.codes(word) do
							local characterWidth = width(utf8.char(code))
							if current > 0 and current + characterWidth > limit then
								breakLine()
							end
							current += characterWidth
						end
					end
				end
			end
			widest = math.max(widest, current)
		end
		return roblox.Vector2.new(math.ceil(widest), lines * size)
	end

	-- The fonts have loaded: all text is laid out again with them.
	local function loadFonts()
		sim.fontsLoaded = true
		for instance, st in state do
			if isA(st.className, "TextLabel") or isA(st.className, "TextButton") or isA(st.className, "TextBox") then
				touchGui(instance)
			end
		end
	end

	-- GUI layout, for GuiObject.AbsolutePosition and AbsoluteSize, roughly as Roblox lays
	-- out:
	-- - Size and Position as a share of the parent's size plus pixels, and AnchorPoint;
	-- - the parent's UIPadding (its pixels);
	-- - UIScale, which scales an object and everything in it about its anchor point;
	-- - UIListLayout, which lines the visible children up in LayoutOrder, with its Padding
	--   and alignments, ignoring their Position and AnchorPoint;
	-- - AutomaticSize, which grows an object to fit its text or its visible children
	--   (their pixel sizes and positions; shares of a size still being worked out count
	--   as nothing).
	-- Rotation is ignored, as it is by AbsolutePosition. Each object's layout is kept until
	-- something it depends on changes (see touchGui).
	local layoutCache = setmetatable({}, { __mode = "k" })
	local listCache = setmetatable({}, { __mode = "k" })

	local function childOfClass(st, className: string)
		for _, child in st.children do
			if state[child].className == className then
				return child
			end
		end
		return nil
	end

	local function isText(className: string): boolean
		return isA(className, "TextLabel") or isA(className, "TextButton")
	end

	-- An object's UIPadding in pixels, before scaling: left, top, right, bottom.
	local function paddingOf(st): (number, number, number, number)
		local padding = childOfClass(st, "UIPadding")
		if padding == nil then
			return 0, 0, 0, 0
		end
		return padding.PaddingLeft.Offset,
			padding.PaddingTop.Offset,
			padding.PaddingRight.Offset,
			padding.PaddingBottom.Offset
	end

	local layoutOf
	local contentExtent

	-- How big an object is before any scaling, in a box `room` across (in the same units),
	-- and the UIScale on it.
	local function sizeOf(instance, room): (any, number)
		local st = state[instance]
		local declared = instance.Size
		local width = declared.X.Scale * room.X + declared.X.Offset
		local height = declared.Y.Scale * room.Y + declared.Y.Offset
		local automatic = instance.AutomaticSize
		if automatic ~= Enum.AutomaticSize.None then
			local growX = automatic ~= Enum.AutomaticSize.Y
			local growY = automatic ~= Enum.AutomaticSize.X
			local extent = contentExtent(instance, if growX then nil else width)
			if growX then
				width = math.max(width, extent.X)
			end
			if growY then
				height = math.max(height, extent.Y)
			end
		end
		local uiScale = childOfClass(st, "UIScale")
		return roblox.Vector2.new(width, height), if uiScale then uiScale.Scale else 1
	end

	-- How much room an object's content takes before any scaling: its text (wrapped at
	-- `width` less padding, if its width is set) or its visible children (end to end, if
	-- a UIListLayout lines them up), plus its UIPadding.
	contentExtent = function(instance, width: number?)
		local st = state[instance]
		local left, top, right, bottom = paddingOf(st)
		local inner = if width then math.max(0, width - left - right) else nil
		local extentX, extentY = 0, 0
		if isText(st.className) then
			local text = measureText(st, if inner and instance.TextWrapped then inner else nil)
			extentX, extentY = text.X, text.Y
		end
		local list = childOfClass(st, "UIListLayout")
		local vertical = list ~= nil and list.FillDirection == Enum.FillDirection.Vertical
		local room = roblox.Vector2.new(inner or 0, 0)
		local along, across, count = 0, 0, 0
		for _, child in st.children do
			if isA(state[child].className, "GuiObject") and child.Visible then
				local size, own = sizeOf(child, room)
				size *= own
				if list then
					count += 1
					along += if vertical then size.Y else size.X
					across = math.max(across, if vertical then size.X else size.Y)
				else
					local at, anchor = child.Position, child.AnchorPoint
					extentX = math.max(extentX, at.X.Offset + (1 - anchor.X) * size.X)
					extentY = math.max(extentY, at.Y.Offset + (1 - anchor.Y) * size.Y)
				end
			end
		end
		if list and count > 0 then
			along += list.Padding.Offset * (count - 1)
			extentX = math.max(extentX, if vertical then across else along)
			extentY = math.max(extentY, if vertical then along else across)
		end
		return roblox.Vector2.new(extentX + left + right, extentY + top + bottom)
	end

	-- The box an object's children go in, in pixels (inside any UIPadding), and the scale
	-- their sizes are drawn at.
	local function contentBox(instance)
		local st = state[instance]
		if isA(st.className, "LayerCollector") then
			return instance.AbsolutePosition, instance.AbsoluteSize, 1
		elseif isA(st.className, "GuiObject") then
			local box = layoutOf(instance)
			local left, top, right, bottom = paddingOf(st)
			local scale = box.scale
			return box.position + roblox.Vector2.new(left, top) * scale,
				box.size - roblox.Vector2.new(left + right, top + bottom) * scale,
				scale
		end
		return roblox.Vector2.zero, roblox.Vector2.zero, 1
	end

	-- Where the UIListLayout in `parent` puts each of its visible children, in pixels.
	local function listSlots(parent, origin, room, scale)
		local cached = listCache[parent]
		if
			cached
			and cached.inside == (state[parent].guiInside or 0)
			and cached.origin == origin
			and cached.room == room
		then
			return cached.slots
		end
		local pst = state[parent]
		local list = childOfClass(pst, "UIListLayout")
		local vertical = list.FillDirection == Enum.FillDirection.Vertical
		local horizontal, verticalAlign = list.HorizontalAlignment, list.VerticalAlignment
		local items = {}
		for index, child in pst.children do
			if isA(state[child].className, "GuiObject") and child.Visible then
				table.insert(items, { child = child, index = index, order = child.LayoutOrder })
			end
		end
		table.sort(items, function(a, b)
			if a.order ~= b.order then
				return a.order < b.order
			end
			return a.index < b.index
		end)
		local units = if scale > 0 then room / scale else roblox.Vector2.zero
		local gap = list.Padding.Scale * (if vertical then room.Y else room.X) + list.Padding.Offset * scale
		local total = 0
		for i, item in items do
			local size, own = sizeOf(item.child, units)
			item.size = size * scale * own
			total += (if vertical then item.size.Y else item.size.X) + (if i > 1 then gap else 0)
		end
		local function offset(align, space: number): number
			if align == Enum.HorizontalAlignment.Center or align == Enum.VerticalAlignment.Center then
				return space / 2
			elseif align == Enum.HorizontalAlignment.Right or align == Enum.VerticalAlignment.Bottom then
				return space
			end
			return 0
		end
		local slots = {}
		local cursor = if vertical
			then origin.Y + offset(verticalAlign, room.Y - total)
			else origin.X + offset(horizontal, room.X - total)
		for _, item in items do
			local size = item.size
			if vertical then
				slots[item.child] = roblox.Vector2.new(origin.X + offset(horizontal, room.X - size.X), cursor)
				cursor += size.Y + gap
			else
				slots[item.child] = roblox.Vector2.new(cursor, origin.Y + offset(verticalAlign, room.Y - size.Y))
				cursor += size.X + gap
			end
		end
		listCache[parent] = { inside = state[parent].guiInside or 0, origin = origin, room = room, slots = slots }
		return slots
	end

	-- Whether a laid-out entry still holds: nothing it depends on has changed since. It
	-- depends on the object's own properties (everything inside it too, if it grows to fit
	-- them), its siblings if a UIListLayout lines them up, and on where its parent is.
	local function fresh(instance, entry): boolean
		local st = state[instance]
		local stamp = if entry.whole then st.guiInside else st.guiOwn
		if (stamp or 0) ~= entry.stamp or st.parent ~= entry.parent then
			return false
		end
		local parent = st.parent
		if parent == nil then
			return true
		end
		local pst = state[parent]
		if entry.siblings and entry.siblings ~= (pst.guiInside or 0) then
			return false
		end
		if isA(pst.className, "GuiObject") then
			local parentEntry = layoutCache[parent]
			return parentEntry ~= nil and parentEntry == entry.parentEntry and fresh(parent, parentEntry)
		end
		return entry.parentStamp == (pst.guiOwn or 0)
	end

	layoutOf = function(instance)
		local cached = layoutCache[instance]
		if cached and fresh(instance, cached) then
			return cached
		end
		local st = state[instance]
		local parent = st.parent
		local origin, room, scale = roblox.Vector2.zero, roblox.Vector2.zero, 1
		if parent then
			origin, room, scale = contentBox(parent)
		end
		local size, own = sizeOf(instance, if scale > 0 then room / scale else roblox.Vector2.zero)
		local pixels = size * scale * own
		local position
		if parent and childOfClass(state[parent], "UIListLayout") then
			position = listSlots(parent, origin, room, scale)[instance] or origin
		else
			local at, anchor = instance.Position, instance.AnchorPoint
			position = origin
				+ roblox.Vector2.new(
					at.X.Scale * room.X + at.X.Offset * scale - anchor.X * pixels.X,
					at.Y.Scale * room.Y + at.Y.Offset * scale - anchor.Y * pixels.Y
				)
		end
		local whole = instance.AutomaticSize ~= Enum.AutomaticSize.None
		local pst = if parent then state[parent] else nil
		local result = {
			position = position,
			size = pixels,
			scale = scale * own,
			whole = whole,
			stamp = (if whole then st.guiInside else st.guiOwn) or 0,
			parent = parent,
			parentEntry = if parent then layoutCache[parent] else nil,
			parentStamp = if pst then pst.guiOwn or 0 else 0,
			siblings = if pst and childOfClass(pst, "UIListLayout") then pst.guiInside or 0 else nil,
		}
		layoutCache[instance] = result
		return result
	end

	computed.GuiObject = {
		AbsolutePosition = function(instance)
			return layoutOf(instance).position
		end,
		AbsoluteSize = function(instance)
			return layoutOf(instance).size
		end,
	}

	-- An object's text as laid out, wrapped at its width less its padding if it wraps, and
	-- the room it has for it.
	local function textLayout(instance, st)
		local box = layoutOf(instance)
		local left, top, right, bottom = paddingOf(st)
		local width = box.size.X / box.scale - left - right
		local height = box.size.Y / box.scale - top - bottom
		return measureText(st, if st.props.TextWrapped then width else nil), width, height
	end
	-- Wrapped text never measures taller than its object: as in Roblox, lines that don't fit
	-- aren't drawn (and TextFits says so).
	local function textBounds(instance, st)
		local bounds, _, height = textLayout(instance, st)
		if st.props.TextWrapped and bounds.Y > height then
			local size = st.props.TextSize or 14
			return roblox.Vector2.new(bounds.X, math.max(0, math.floor(height / size)) * size)
		end
		return bounds
	end
	local function textFits(instance, st)
		local bounds, width, height = textLayout(instance, st)
		return bounds.X <= width + 0.5 and bounds.Y <= height + 0.5
	end
	for _, className in { "TextLabel", "TextButton", "TextBox" } do
		computed[className] = { TextBounds = textBounds, TextFits = textFits }
	end

	computed.Camera = {
		-- The device safe area (not the whole screen the camera renders).
		ViewportSize = function()
			return roblox.Vector2.new(sim.safeArea.X, sim.screen.Y)
		end,
	}
	-- Where a point in the world is drawn, for a camera with a vertical FieldOfView over
	-- the whole screen: x and y in viewport coordinates, less `inset` from the top, and the
	-- depth in front of the camera (negative behind it).
	local function project(camera, point, inset: number)
		local relative = camera.CFrame:PointToObjectSpace(point)
		local depth = -relative.Z
		local screen = sim.screen
		local tanHalf = math.tan(math.rad(camera.FieldOfView) / 2)
		local scale = if math.abs(depth) > 1e-6 then depth else 1e-6
		local x = (relative.X / (scale * tanHalf * screen.X / screen.Y) + 1) / 2 * screen.X - sideInset()
		local y = (1 - relative.Y / (scale * tanHalf)) / 2 * screen.Y
		local onScreen = depth > 0 and x >= 0 and x <= sim.safeArea.X and y >= 0 and y <= screen.Y
		return roblox.Vector3.new(x, y - inset, depth), onScreen
	end
	methods.Camera = {
		WorldToViewportPoint = function(self, point)
			return project(self, point, 0)
		end,
		-- In GUI coordinates, from the bottom-left of the top bar, for placing GUI.
		WorldToScreenPoint = function(self, point)
			return project(self, point, topInset())
		end,
	}

	-- A part's pivot sits at its PivotOffset from its CFrame; a model's is its PrimaryPart's
	-- pivot, or its WorldPivot.
	methods.PVInstance = {
		GetPivot = function(self)
			local st = state[self]
			if isA(st.className, "BasePart") then
				return self.CFrame * self.PivotOffset
			end
			local primary = st.props.PrimaryPart
			if primary then
				return primary:GetPivot()
			end
			return st.props.WorldPivot or roblox.CFrame.new()
		end,
		PivotTo = function(self, target)
			if typeOf(target) ~= "CFrame" then
				error("PivotTo expects a CFrame", 2)
			end
			if isA(state[self].className, "BasePart") then
				local offset = state[self].props.PivotOffset
				self.CFrame = if offset then target * offset:Inverse() else target
				return
			end
			local delta = target * self:GetPivot():Inverse()
			-- Every target comes from where the parts are now, before any of them moves:
			-- moving one part also moves the parts welded or jointed to it.
			local moves = {}
			for _, descendant in descendants(self, {}) do
				if isA(state[descendant].className, "BasePart") then
					table.insert(moves, { descendant, delta * descendant.CFrame })
				end
			end
			for _, move in moves do
				move[1].CFrame = move[2]
			end
		end,
	}

	-- Terrain isn't voxelized; fills are recorded (for tools/preview) and otherwise ignored.
	sim.terrainFills = {}
	methods.Terrain = {
		FillBlock = function(_self, cframe, size, material)
			assert(typeOf(cframe) == "CFrame" and typeOf(size) == "Vector3", "FillBlock(CFrame, Vector3, Material)")
			assert(typeOf(material) == "EnumItem" and Enum.Material[material.Name] == material, "FillBlock material")
			table.insert(sim.terrainFills, {
				cframe = { cframe:GetComponents() },
				size = { size.X, size.Y, size.Z },
				material = material.Name,
			})
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

	-- Characters ------------------------------------------------------------------------
	-- A blocky R15 built to Roblox's default rig (Studio's content/avatar/characterR15.rbxm):
	-- the same part sizes, joints and accessory attachments, as block Parts. The platform
	-- would dress each player in their own avatar; here the colours come from the user id.
	local R15_PARTS = {
		-- name, size, offset from the root, colour slot
		{ "HumanoidRootPart", { 2, 2, 1 }, { 0, 0, 0 }, "root" },
		{ "LowerTorso", { 2, 0.4, 1 }, { 0, -0.15, 0 }, "pants" },
		{ "UpperTorso", { 2, 1.6, 1 }, { 0, 0.85, 0 }, "shirt" },
		{ "Head", { 2, 1, 1 }, { 0, 2.15, 0 }, "skin" },
		{ "LeftUpperArm", { 1, 1.1687, 1 }, { -1.5, 1.0187, 0 }, "shirt" },
		{ "RightUpperArm", { 1, 1.1687, 1 }, { 1.5, 1.0187, 0 }, "shirt" },
		{ "LeftLowerArm", { 1, 1.0519, 1 }, { -1.5, 0.4259, 0 }, "skin" },
		{ "RightLowerArm", { 1, 1.0519, 1 }, { 1.5, 0.4259, 0 }, "skin" },
		{ "LeftHand", { 1, 0.3, 1 }, { -1.5, -0.2, 0 }, "skin" },
		{ "RightHand", { 1, 0.3, 1 }, { 1.5, -0.2, 0 }, "skin" },
		{ "LeftUpperLeg", { 1, 1.2166, 1 }, { -0.5, -0.7708, 0 }, "pants" },
		{ "RightUpperLeg", { 1, 1.2166, 1 }, { 0.5, -0.7708, 0 }, "pants" },
		{ "LeftLowerLeg", { 1, 1.1931, 1 }, { -0.5, -1.5509, 0 }, "pants" },
		{ "RightLowerLeg", { 1, 1.1931, 1 }, { 0.5, -1.5509, 0 }, "pants" },
		{ "LeftFoot", { 1, 0.3, 1 }, { -0.5, -2.2, 0 }, "shoes" },
		{ "RightFoot", { 1, 0.3, 1 }, { 0.5, -2.2, 0 }, "shoes" },
	}
	local R15_JOINTS = {
		-- name, Part0, Part1 (the joint's parent), C0 position, C1 position; all unrotated
		{ "Root", "HumanoidRootPart", "LowerTorso", { 0, -0.35, 0 }, { 0, -0.2, 0 } },
		{ "Waist", "LowerTorso", "UpperTorso", { 0, 0.2, 0 }, { 0, -0.8, 0 } },
		{ "Neck", "UpperTorso", "Head", { 0, 0.8, 0 }, { 0, -0.5, 0 } },
		{ "LeftShoulder", "UpperTorso", "LeftUpperArm", { -1, 0.563, 0 }, { 0.5, 0.3943, 0 } },
		{ "RightShoulder", "UpperTorso", "RightUpperArm", { 1, 0.563, 0 }, { -0.5, 0.3943, 0 } },
		{ "LeftElbow", "LeftUpperArm", "LeftLowerArm", { 0, -0.3341, 0 }, { 0, 0.2587, 0 } },
		{ "RightElbow", "RightUpperArm", "RightLowerArm", { 0, -0.3341, 0 }, { 0, 0.2587, 0 } },
		{ "LeftWrist", "LeftLowerArm", "LeftHand", { 0, -0.5009, 0 }, { 0, 0.125, 0 } },
		{ "RightWrist", "RightLowerArm", "RightHand", { 0, -0.5009, 0 }, { 0, 0.125, 0 } },
		{ "LeftHip", "LowerTorso", "LeftUpperLeg", { -0.5, -0.2, 0 }, { 0, 0.4208, 0 } },
		{ "RightHip", "LowerTorso", "RightUpperLeg", { 0.5, -0.2, 0 }, { 0, 0.4208, 0 } },
		{ "LeftKnee", "LeftUpperLeg", "LeftLowerLeg", { 0, -0.4011, 0 }, { 0, 0.379, 0 } },
		{ "RightKnee", "RightUpperLeg", "RightLowerLeg", { 0, -0.4011, 0 }, { 0, 0.379, 0 } },
		{ "LeftAnkle", "LeftLowerLeg", "LeftFoot", { 0, -0.5472, 0 }, { 0, 0.1019, 0 } },
		{ "RightAnkle", "RightLowerLeg", "RightFoot", { 0, -0.5472, 0 }, { 0, 0.1019, 0 } },
	}
	local R15_ATTACHMENTS = {
		HumanoidRootPart = { RootAttachment = { 0, 0, 0 } },
		Head = {
			HairAttachment = { 0, 0.6, 0 },
			HatAttachment = { 0, 0.6, 0 },
			FaceFrontAttachment = { 0, 0, -0.6 },
			FaceCenterAttachment = { 0, 0, 0 },
		},
		UpperTorso = {
			NeckAttachment = { 0, 0.8, 0 },
			BodyFrontAttachment = { 0, -0.2, -0.5 },
			BodyBackAttachment = { 0, -0.2, 0.5 },
			LeftCollarAttachment = { -1, 0.8, 0 },
			RightCollarAttachment = { 1, 0.8, 0 },
		},
		LowerTorso = {
			WaistCenterAttachment = { 0, -0.2, 0 },
			WaistFrontAttachment = { 0, -0.2, -0.5 },
			WaistBackAttachment = { 0, -0.2, 0.5 },
		},
		LeftUpperArm = { LeftShoulderAttachment = { 0, 0.5843, 0 } },
		RightUpperArm = { RightShoulderAttachment = { 0, 0.5843, 0 } },
		LeftHand = { LeftGripAttachment = { 0, -0.15, 0 } },
		RightHand = { RightGripAttachment = { 0, -0.15, 0 } },
		LeftFoot = { LeftFootAttachment = { 0, -0.15, 0 } },
		RightFoot = { RightFootAttachment = { 0, -0.15, 0 } },
	}
	local OUTFITS = {
		{ skin = { 234, 184, 146 }, shirt = { 13, 105, 172 }, pants = { 27, 42, 53 }, shoes = { 27, 42, 53 } },
		{ skin = { 124, 92, 70 }, shirt = { 196, 40, 28 }, pants = { 99, 95, 98 }, shoes = { 17, 17, 17 } },
		{ skin = { 245, 205, 48 }, shirt = { 40, 127, 71 }, pants = { 13, 105, 172 }, shoes = { 27, 42, 53 } },
		{ skin = { 204, 142, 105 }, shirt = { 107, 50, 124 }, pants = { 27, 42, 53 }, shoes = { 242, 243, 243 } },
	}
	local ROOT_HEIGHT = 2.35 -- ground to the root's centre: HipHeight 1.35 + half the root's height

	local function buildCharacter(player)
		local userId = state[player].props.UserId or 0
		local outfit = OUTFITS[userId % #OUTFITS + 1]
		local model = newInstance("Model")
		state[model].props.Name = state[player].props.Name
		local parts = {}
		for _, spec in R15_PARTS do
			local part = newInstance("Part")
			local p = state[part].props
			p.Name = spec[1]
			p.Size = roblox.Vector3.new(spec[2][1], spec[2][2], spec[2][3])
			p.CFrame = roblox.CFrame.new(spec[3][1], spec[3][2] + ROOT_HEIGHT, spec[3][3])
			p.Material = Enum.Material.Plastic
			p.CanCollide = spec[1] == "HumanoidRootPart"
			p.Transparency = if spec[4] == "root" then 1 else 0
			local rgb = outfit[spec[4]] or { 163, 162, 165 }
			p.Color = roblox.Color3.fromRGB(rgb[1], rgb[2], rgb[3])
			parts[spec[1]] = part
			part.Parent = model
		end
		local mesh = newInstance("SpecialMesh")
		state[mesh].props.Name = "Mesh"
		mesh.MeshType = Enum.MeshType.Head
		mesh.Scale = roblox.Vector3.new(1.25, 1.25, 1.25)
		mesh.Parent = parts.Head
		local face = newInstance("Decal")
		state[face].props.Name = "face"
		face.Texture = "rbxasset://textures/face.png"
		face.Parent = parts.Head
		for partName, list in R15_ATTACHMENTS do
			for attachmentName, at in list do
				local attachment = newInstance("Attachment")
				state[attachment].props.Name = attachmentName
				attachment.Position = roblox.Vector3.new(at[1], at[2], at[3])
				attachment.Parent = parts[partName]
			end
		end
		for _, spec in R15_JOINTS do
			local joint = newInstance("Motor6D")
			state[joint].props.Name = spec[1]
			joint.C0 = roblox.CFrame.new(spec[4][1], spec[4][2], spec[4][3])
			joint.C1 = roblox.CFrame.new(spec[5][1], spec[5][2], spec[5][3])
			joint.Part0 = parts[spec[2]]
			joint.Part1 = parts[spec[3]]
			joint.Parent = parts[spec[3]]
		end
		local humanoid = newInstance("Humanoid")
		humanoid.RigType = Enum.HumanoidRigType.R15
		humanoid.HipHeight = 1.35
		humanoid.Parent = model
		model.PrimaryPart = parts.HumanoidRootPart
		return model
	end

	-- Where a character appears: on top of an enabled, neutral SpawnLocation, facing the way
	-- it faces, spread out a little so two players don't land on each other.
	local spawnCount = 0
	local function spawnFrame()
		spawnCount += 1
		for _, candidate in descendants(workspace, {}) do
			local cst = state[candidate]
			if cst.className == "SpawnLocation" and candidate.Enabled and candidate.Neutral then
				local frame = candidate.CFrame
				local look = frame.LookVector
				local yaw = math.atan2(-look.X, -look.Z)
				local slot = (spawnCount - 1) % 3 -- centre, then left, then right
				local spread = roblox.Vector3.new(if slot == 0 then 0 elseif slot == 1 then -2.5 else 2.5, 0, 0)
				local top = frame.Position + roblox.Vector3.new(0, candidate.Size.Y / 2 + ROOT_HEIGHT, 0)
				return roblox.CFrame.new(top) * roblox.CFrame.Angles(0, yaw, 0) * roblox.CFrame.new(spread)
			end
		end
		-- No spawn: Studio drops the character near the origin, high up.
		return roblox.CFrame.new(0, 100, 0)
	end

	local function removeCharacter(player)
		local old = state[player].props.Character
		if old then
			fire(eventFor(player, state[player], "CharacterRemoving"), nil, old)
			drain()
			old:Destroy()
			state[player].props.Character = nil
		end
	end

	-- Roblox's order: Character is set, CharacterAdded fires (deferred), the model is parented
	-- to the workspace and moved to a spawn. Handlers run after all of that.
	local function loadCharacter(player)
		removeCharacter(player)
		local character = buildCharacter(player)
		state[player].props.Character = character
		fire(eventFor(player, state[player], "CharacterAdded"), nil, character)
		changed(player, state[player], "Character", character)
		character.Parent = workspace
		character:PivotTo(spawnFrame())
		drain()
		return character
	end
	sim.loadCharacter = function(_self, player)
		return loadCharacter(player)
	end

	methods.Player = {
		LoadCharacterAsync = function(self)
			if currentContext() ~= "server" then
				error("LoadCharacterAsync can only be called by the backend server", 2)
			end
			loadCharacter(self)
		end,
	}

	computed.Humanoid = {
		RootPart = function(instance, st)
			local model = st.parent
			return model and findChild(state[model], "HumanoidRootPart") or nil
		end,
		FloorMaterial = function()
			return Enum.Material.Plastic -- no physics: everyone is standing on something
		end,
		MoveDirection = function()
			return roblox.Vector3.zero
		end,
	}

	local function findAttachment(model, name: string)
		for _, descendant in descendants(model, {}) do
			local dst = state[descendant]
			if dst.className == "Attachment" and dst.props.Name == name then
				local parent = dst.parent
				-- Only the body's own attachments, not another accessory's.
				if parent and isA(state[parent].className, "BasePart") and state[parent].parent == model then
					return descendant
				end
			end
		end
		return nil
	end

	methods.Humanoid = {
		-- Welds the accessory's Handle to the body part with the matching attachment, so the
		-- two attachments meet. (Roblox's weld has Part0 = Handle; the simulator's joints pose
		-- Part1 from Part0, so here Part0 is the body part. The result is the same.)
		AddAccessory = function(self, accessory)
			local model = state[self].parent
			assert(model, "AddAccessory: the Humanoid has no character")
			assert(
				isInstance(accessory) and isA(state[accessory].className, "Accoutrement"),
				"AddAccessory expects an Accessory"
			)
			local handle = findChild(state[accessory], "Handle")
			accessory.Parent = model
			if handle == nil then
				return
			end
			for _, child in state[handle].children do
				if state[child].className == "Attachment" then
					local target = findAttachment(model, state[child].props.Name)
					if target then
						local weld = newInstance("Weld")
						state[weld].props.Name = "AccessoryWeld"
						weld.C0 = state[target].props.CFrame or roblox.CFrame.new()
						weld.C1 = state[child].props.CFrame or roblox.CFrame.new()
						weld.Part1 = handle
						weld.Part0 = state[target].parent
						weld.Parent = handle
						return
					end
				end
			end
		end,
		GetAccessories = function(self)
			local model = state[self].parent
			local list = {}
			if model then
				for _, child in state[model].children do
					if isA(state[child].className, "Accoutrement") then
						table.insert(list, child)
					end
				end
			end
			return list
		end,
		GetState = function()
			return Enum.HumanoidStateType.Running
		end,
		ChangeState = function() end,
		SetStateEnabled = function(_self, stateType, enabled)
			assert(typeOf(stateType) == "EnumItem" and type(enabled) == "boolean", "SetStateEnabled(state, enabled)")
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

	-- ContextActionService: bindings are per client. sim:pressKey offers each key press to
	-- them in priority order (see dispatchAction).
	service("ContextActionService")
	local actionBindings = {}
	local bindingSequence = 0

	local function bindAction(name, fn, touchButton, priority, ...)
		local context = currentContext()
		if clientPlayer[context] == nil then
			error("ContextActionService actions can only be bound on the client", 3)
		end
		assert(type(name) == "string" and type(fn) == "function", "BindAction(name, function, ...)")
		assert(type(touchButton) == "boolean", "BindAction: createTouchButton must be a boolean")
		assert(type(priority) == "number", "BindActionAtPriority: priority must be a number")
		local inputs = table.pack(...)
		assert(inputs.n > 0, "BindAction needs at least one input")
		for i = 1, inputs.n do
			local item = inputs[i]
			assert(
				typeOf(item) == "EnumItem"
					and (
						Enum.KeyCode[item.Name] == item
						or Enum.UserInputType[item.Name] == item
						or Enum.PlayerActions[item.Name] == item
					),
				`BindAction: input {i} must be a KeyCode, UserInputType or PlayerActions`
			)
		end
		for i = #actionBindings, 1, -1 do
			if actionBindings[i].context == context and actionBindings[i].name == name then
				table.remove(actionBindings, i)
			end
		end
		bindingSequence += 1
		table.insert(actionBindings, {
			name = name,
			fn = fn,
			priority = priority,
			inputs = { table.unpack(inputs, 1, inputs.n) },
			context = context,
			seq = bindingSequence,
		})
	end

	methods.ContextActionService = {
		BindAction = function(_self, name, fn, touchButton, ...)
			bindAction(name, fn, touchButton, Enum.ContextActionPriority.Default.Value, ...)
		end,
		BindActionAtPriority = function(_self, name, fn, touchButton, priority, ...)
			bindAction(name, fn, touchButton, priority, ...)
		end,
		UnbindAction = function(_self, name)
			local context = currentContext()
			for i = #actionBindings, 1, -1 do
				if actionBindings[i].context == context and actionBindings[i].name == name then
					table.remove(actionBindings, i)
				end
			end
		end,
		GetButton = function()
			return nil
		end,
		SetTitle = function() end,
		SetImage = function() end,
		SetPosition = function() end,
		SetDescription = function() end,
	}

	-- Runs `fn` in a client's context right now and returns its first result (nil if it yields).
	local function callIn(context: string, fn, ...)
		local thread = coroutine.create(fn)
		threadContext[thread] = context
		local results = table.pack(coroutine.resume(thread, ...))
		if not results[1] then
			table.insert(sim.errors, `[{context}] {debug.traceback(thread, tostring(results[2]))}`)
			return nil
		end
		return results[2]
	end

	-- Offers an input to one client's bound actions. Returns true if an action sank it.
	local function dispatchAction(context: string, inputObject): boolean
		local matching = {}
		for _, binding in actionBindings do
			if binding.context == context then
				for _, item in binding.inputs do
					if item == inputObject.KeyCode or item == inputObject.UserInputType then
						table.insert(matching, binding)
						break
					end
				end
			end
		end
		table.sort(matching, function(a, b)
			if a.priority ~= b.priority then
				return a.priority > b.priority
			end
			return a.seq > b.seq
		end)
		for _, binding in matching do
			local result = callIn(context, binding.fn, binding.name, inputObject.UserInputState, inputObject)
			drain()
			if result ~= Enum.ContextActionResult.Pass then
				return true
			end
		end
		return false
	end
	service("GuiService")
	methods.GuiService = {
		IsTenFootInterface = function()
			return sim.tenFoot
		end,
		-- The top bar's inset (top left) and the bottom-right inset.
		GetGuiInset = function()
			return roblox.Vector2.new(0, topInset()), roblox.Vector2.zero
		end,
	}

	-- The box round every part in a model, turned the way its PrimaryPart is (or its
	-- WorldPivot), as Roblox's GetBoundingBox: returns its centre and size.
	methods.Model = {
		GetBoundingBox = function(self)
			local st = state[self]
			local primary = st.props.PrimaryPart
			local turn = (if primary then primary.CFrame else (st.props.WorldPivot or roblox.CFrame.new())).Rotation
			local low, high
			for _, part in descendants(self, {}) do
				if isA(state[part].className, "BasePart") then
					local frame, half = part.CFrame, part.Size / 2
					for _, x in { -1, 1 } do
						for _, y in { -1, 1 } do
							for _, z in { -1, 1 } do
								local corner = turn:PointToObjectSpace(
									frame:PointToWorldSpace(roblox.Vector3.new(half.X * x, half.Y * y, half.Z * z))
								)
								low = if low then low:Min(corner) else corner
								high = if high then high:Max(corner) else corner
							end
						end
					end
				end
			end
			if low == nil then
				return roblox.CFrame.new(), roblox.Vector3.zero
			end
			return roblox.CFrame.new(turn:PointToWorldSpace((low + high) / 2)) * turn, high - low
		end,
	}

	methods.StarterGui = {
		SetCoreGuiEnabled = function(_self, kind, enabled)
			assert(typeOf(kind) == "EnumItem" and Enum.CoreGuiType[kind.Name] == kind, "SetCoreGuiEnabled type")
			assert(type(enabled) == "boolean", "SetCoreGuiEnabled enabled")
			table.insert(sim.coreCalls, `[{currentContext()}] SetCoreGuiEnabled {kind.Name} {enabled}`)
		end,
		SetCore = function(_self, name, value)
			table.insert(sim.coreCalls, `[{currentContext()}] SetCore {name} {tostring(value)}`)
		end,
		GetCore = function()
			return nil
		end,
	}

	-- TextChatService comes with Roblox's defaults: the chat configurations and the
	-- RBXGeneral and RBXSystem channels (CreateDefaultTextChannels).
	local textChat = service("TextChatService")
	for _, className in { "ChatWindowConfiguration", "BubbleChatConfiguration" } do
		local configuration = newInstance(className)
		configuration.Parent = textChat
	end
	local channels = newInstance("Folder")
	state[channels].props.Name = "TextChannels"
	channels.Parent = textChat
	for _, name in { "RBXGeneral", "RBXSystem" } do
		local channel = newInstance("TextChannel")
		state[channel].props.Name = name
		channel.Parent = channels
	end

	-- Chat bubbles and system messages: recorded per client, for tests and previews.
	sim.bubbles = {}
	sim.systemMessages = {}
	methods.TextChannel = {
		DisplaySystemMessage = function(self, text)
			local player = clientPlayer[currentContext()]
			if player == nil then
				error("DisplaySystemMessage can only be called from the client", 2)
			end
			assert(type(text) == "string", "DisplaySystemMessage expects a string")
			table.insert(sim.systemMessages, { time = sim.now, player = player, channel = self.Name, text = text })
			return nil
		end,
	}
	methods.TextChatService = {
		DisplayBubble = function(_self, partOrCharacter, message)
			local player = clientPlayer[currentContext()]
			if player == nil then
				error("DisplayBubble can only be called from the client", 2)
			end
			assert(isInstance(partOrCharacter), "DisplayBubble expects a part or character")
			assert(type(message) == "string", "DisplayBubble expects a string message")
			table.insert(sim.bubbles, { time = sim.now, player = player, adornee = partOrCharacter, message = message })
		end,
	}

	-- Sounds: nothing is heard, but every Play is recorded (sim.sounds) with the context
	-- that played it, so tests can check what a player would hear and from where.
	sim.sounds = {}
	methods.Sound = {
		Play = function(self)
			local st = state[self]
			st.playing = true
			st.props.TimePosition = 0
			table.insert(sim.sounds, {
				time = sim.now,
				context = currentContext(),
				name = st.props.Name,
				id = st.props.SoundId,
				sound = self,
			})
		end,
		Stop = function(self)
			local st = state[self]
			st.playing = false
			st.props.TimePosition = 0
		end,
		Pause = function(self)
			state[self].playing = false
		end,
		Resume = function(self)
			state[self].playing = true
		end,
	}
	computed.Sound = {
		IsPlaying = function(_instance, st)
			return st.playing == true
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

	service("CollectionService")
	methods.CollectionService = {
		GetTagged = function(_self, tag)
			local list = {}
			for instance in tagged[tag] or {} do
				if inGame(instance) then
					table.insert(list, instance)
				end
			end
			return list
		end,
		GetInstanceAddedSignal = function(_self, tag)
			return tagSignal(tag, "added")
		end,
		GetInstanceRemovedSignal = function(_self, tag)
			return tagSignal(tag, "removed")
		end,
		AddTag = function(_self, instance, tag)
			addTag(instance, tag)
		end,
		RemoveTag = function(_self, instance, tag)
			removeTag(instance, tag)
		end,
		HasTag = function(_self, instance, tag)
			return tagged[tag] ~= nil and tagged[tag][instance] == true
		end,
	}

	-- Robert Penner's easings, which Roblox's EasingStyles follow. "In" is defined per
	-- style; "Out" mirrors it and "InOut" joins the two.
	local EASE_IN = {
		Linear = function(t)
			return t
		end,
		Sine = function(t)
			return 1 - math.cos(t * math.pi / 2)
		end,
		Quad = function(t)
			return t * t
		end,
		Cubic = function(t)
			return t * t * t
		end,
		Quart = function(t)
			return t ^ 4
		end,
		Quint = function(t)
			return t ^ 5
		end,
		Exponential = function(t)
			return if t == 0 then 0 else 2 ^ (10 * t - 10)
		end,
		Circular = function(t)
			return 1 - math.sqrt(1 - t * t)
		end,
		Back = function(t)
			return 2.70158 * t ^ 3 - 1.70158 * t * t
		end,
		-- Bounce is defined by its Out: a ball dropped onto the end value, bouncing lower
		-- each time. In mirrors it.
		Bounce = function(t)
			local u = 1 - t
			local out
			if u < 1 / 2.75 then
				out = 7.5625 * u * u
			elseif u < 2 / 2.75 then
				u -= 1.5 / 2.75
				out = 7.5625 * u * u + 0.75
			elseif u < 2.5 / 2.75 then
				u -= 2.25 / 2.75
				out = 7.5625 * u * u + 0.9375
			else
				u -= 2.625 / 2.75
				out = 7.5625 * u * u + 0.984375
			end
			return 1 - out
		end,
	}
	local function ease(t: number, style, direction): number
		local easeIn = EASE_IN[style.Name]
		if easeIn == nil then
			error(`sim: EasingStyle.{style.Name} isn't simulated (add it to EASE_IN)`, 3)
		end
		if direction == Enum.EasingDirection.In then
			return easeIn(t)
		elseif direction == Enum.EasingDirection.Out then
			return 1 - easeIn(1 - t)
		end
		return if t < 0.5 then easeIn(2 * t) / 2 else 1 - easeIn(2 * (1 - t)) / 2
	end

	local tweens = setmetatable({}, { __mode = "k" })
	methods.TweenService = {
		GetValue = function(_self, alpha, style, direction)
			assert(type(alpha) == "number", "GetValue alpha")
			assert(typeOf(style) == "EnumItem" and Enum.EasingStyle[style.Name] == style, "GetValue EasingStyle")
			assert(
				typeOf(direction) == "EnumItem" and Enum.EasingDirection[direction.Name] == direction,
				"GetValue EasingDirection"
			)
			return ease(math.clamp(alpha, 0, 1), style, direction)
		end,
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
	methods.ContentProvider = {
		-- Every asset is there from the start, except fonts, which load at sim.fontsLoadAt.
		PreloadAsync = function(_self, contents, callback)
			assert(type(contents) == "table", "PreloadAsync takes a list of instances or content ids")
			while not sim.fontsLoaded do
				taskApi.wait(0.1)
			end
			if callback then
				for _, content in contents do
					callback(if type(content) == "string" then content else "", Enum.AssetFetchStatus.Success)
				end
			end
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

	-- Runs `fn(env)` on a player's client, as their client scripts would, for testing the
	-- simulator itself. `env` holds the globals a client script sees.
	function sim:runAsClient(player, fn)
		local context = `client:{state[player].props.UserId}`
		assert(clientPlayer[context] == player, "runAsClient: that player isn't connected")
		local thread = newThread(context, fn)
		resume(thread, baseGlobals)
		drain()
	end

	local function runSnippet(context: string, path: string, source: string)
		moduleCaches[context] = moduleCaches[context] or {}
		local chunk = luau.load(source, {
			debugName = path,
			environment = environment(context, path),
			injectGlobals = false,
		})
		local results
		local thread = newThread(context, function()
			results = table.pack(chunk())
		end)
		resume(thread)
		drain()
		if results == nil then
			return nil
		end
		return table.unpack(results, 1, results.n)
	end

	-- Runs a snippet of Luau as a server script, for testing the simulator itself.
	-- Returns whatever the snippet returns.
	function sim:execute(source: string)
		return runSnippet("server", "ServerScriptService/Snippet", source)
	end

	-- Runs a snippet of Luau on a player's client, next to their client script (so
	-- `require("./Controllers/CameraController")` is the module their client is running).
	-- Returns whatever the snippet returns.
	function sim:executeClient(player, source: string)
		local context = `client:{state[player].props.UserId}`
		assert(clientPlayer[context] == player, "executeClient: that player isn't connected")
		return runSnippet(context, "ReplicatedStorage/Snippet", source)
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
		if players.CharacterAutoLoads then
			loadCharacter(player)
		end
		return player
	end

	function sim:removePlayer(player)
		fire(eventFor(players, state[players], "PlayerRemoving"), nil, player)
		drain()
		removeCharacter(player)
		deadContexts[`client:{state[player].props.UserId}`] = true
		for context, candidate in clientPlayer do
			if candidate == player then
				clientPlayer[context] = nil
			end
		end
		player.Parent = nil
		drain()
	end

	-- Roblox's default camera, roughly, for one player (sim.cameraFollows): with CameraType
	-- Custom it keeps the camera's direction and puts it on the subject point the way
	-- BaseCamera:GetSubjectPosition does (1.5 studs above the root, plus Humanoid.CameraOffset),
	-- half a stud behind it in first person (LockFirstPerson) or sim.cameraZoom behind it
	-- otherwise. In first person it hides the character from its own camera
	-- (LocalTransparencyModifier), as the TransparencyController does. Tests don't use it;
	-- tools/preview does, so the pictures show what the player would see.
	local function emulateCamera(player)
		local character = state[player].props.Character
		if character == nil or camera.CameraType ~= Enum.CameraType.Custom then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = humanoid and humanoid.RootPart
		if root == nil then
			return
		end
		local lift = 1.5
		if humanoid.RigType == Enum.HumanoidRigType.R15 then
			lift = 1.5 + (root.Size.Y - 2) / 2
		end
		local subject = root.Position
			+ root.CFrame:VectorToWorldSpace(roblox.Vector3.new(0, lift, 0) + humanoid.CameraOffset)
		local firstPerson = player.CameraMode == Enum.CameraMode.LockFirstPerson
		local rotation = camera.CFrame.Rotation
		local zoom = if firstPerson then 0.5 else (sim.cameraZoom or 12.5)
		camera.CFrame = roblox.CFrame.new(subject - rotation.LookVector * zoom) * rotation
		camera.Focus = roblox.CFrame.new(subject)
		for _, descendant in descendants(character, {}) do
			local className = state[descendant].className
			if isA(className, "BasePart") or className == "Decal" then
				descendant.LocalTransparencyModifier = if firstPerson then 1 else 0
			end
		end
	end

	function sim:step(dt: number)
		sim.now += dt
		sim.frames += 1
		if not sim.fontsLoaded and sim.now >= sim.fontsLoadAt then
			loadFonts()
		end
		if sim.cameraFollows then
			emulateCamera(sim.cameraFollows)
		end
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
		-- Then, as in Roblox's frame: PreSimulation (where custom animation sets
		-- Motor6D.Transform), the scheduler, and Heartbeat after physics.
		local preSimulation = state[runService].signals.PreSimulation
		if preSimulation then
			fire(preSimulation, nil, dt)
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

	-- A key (or gamepad button) press and release reaching the game, not eaten by the UI.
	-- It goes to every player's client, or only `player`'s. As in Roblox, actions bound with
	-- ContextActionService see it first, highest priority first (the latest binding first on
	-- a tie); an action that doesn't return Pass sinks it, and UserInputService then reports
	-- it as processed.
	function sim:pressKey(keyCode: EnumItem, player: any?)
		local inputType = if string.sub(keyCode.Name, 1, 6) == "Button"
			then Enum.UserInputType.Gamepad1
			else Enum.UserInputType.Keyboard
		for context, owner in table.clone(clientPlayer) do
			if (player == nil or owner == player) and not deadContexts[context] then
				for _, phase in { Enum.UserInputState.Begin, Enum.UserInputState.End } do
					local inputObject = {
						KeyCode = keyCode,
						UserInputType = inputType,
						UserInputState = phase,
						Position = roblox.Vector3.zero,
						Delta = roblox.Vector3.zero,
					}
					local sunk = dispatchAction(context, inputObject)
					local event = if phase == Enum.UserInputState.Begin then "InputBegan" else "InputEnded"
					fire(eventFor(input, state[input], event), function(candidate)
						return candidate == context
					end, inputObject, sunk)
					drain()
				end
			end
		end
	end

	-- A player holding the prompt's key (for its HoldDuration) within reach of it, as the
	-- engine requires: the prompt must be enabled and the player's character close enough.
	function sim:triggerPrompt(player, prompt)
		local st = state[prompt]
		assert(st and st.className == "ProximityPrompt", "triggerPrompt expects a ProximityPrompt")
		assert(prompt.Enabled, `{fullName(prompt)} is disabled`)
		local parent = st.parent
		assert(parent, "the prompt isn't in the world")
		local position
		if isA(state[parent].className, "BasePart") then
			position = parent.Position
		elseif state[parent].className == "Attachment" then
			position = parent.WorldPosition
		else
			error(`sim: a ProximityPrompt under a {state[parent].className} never shows`)
		end
		local character = state[player].props.Character
		assert(character, `{state[player].props.Name} has no character to reach the prompt with`)
		local root = findChild(state[character], "HumanoidRootPart")
		local distance = (root.Position - position).Magnitude
		assert(
			distance <= prompt.MaxActivationDistance,
			`{state[player].props.Name} is {math.floor(distance * 10) / 10} studs from {fullName(prompt)} (reach {prompt.MaxActivationDistance})`
		)
		local function serverAndOwner(context)
			return context == "server" or clientPlayer[context] == player
		end
		if prompt.HoldDuration > 0 then
			fire(eventFor(prompt, st, "PromptButtonHoldBegan"), serverAndOwner, player)
			sim:run(prompt.HoldDuration)
			assert(prompt.Enabled, `{fullName(prompt)} was disabled during the hold`)
		end
		fire(eventFor(prompt, st, "Triggered"), serverAndOwner, player)
		fire(eventFor(prompt, st, "TriggerEnded"), serverAndOwner, player)
		drain()
	end

	-- Moves a player's character as if they had walked there: standing at `feet`, facing
	-- `toward` (a point) if given.
	function sim:moveCharacter(player, feet, toward)
		local character = state[player].props.Character
		assert(character, `{state[player].props.Name} has no character`)
		local root = feet + roblox.Vector3.new(0, ROOT_HEIGHT, 0)
		local frame = if toward
			then lookAt(root, roblox.Vector3.new(toward.X, root.Y, toward.Z))
			else roblox.CFrame.new(root) * character:GetPivot().Rotation
		character:PivotTo(frame)
		drain()
	end

	-- Whether a player's client last left a piece of Roblox's own UI on
	-- (StarterGui:SetCoreGuiEnabled, `kind` an Enum.CoreGuiType name). Everything starts on.
	function sim:coreGuiEnabled(player, kind: string): boolean
		local context = `client:{state[player].props.UserId}`
		local on = true
		for _, call in sim.coreCalls do
			local who, name, value = string.match(call, "^%[(.-)%] SetCoreGuiEnabled (%a+) (%a+)$")
			if who == context and name == kind then
				on = value == "true"
			end
		end
		return on
	end

	-- Roblox's own top bar buttons take a different amount of room (its chat pill opening,
	-- say): the free part of the top bar row changes, and ScreenGuis in it resize.
	function sim:setTopbarInset(rect)
		sim.topbarInset = rect
		for instance, st in state do
			if st.className == "ScreenGui" and instance.ScreenInsets == Enum.ScreenInsets.TopbarSafeInsets then
				touchGui(instance)
				local signal = st.propertySignals.AbsoluteSize
				if signal then
					fire(signal, nil)
				end
			end
		end
		drain()
	end

	-- Counts writes of `key` on `instance` from now on, by context ("server",
	-- "client:<UserId>", "engine" for tweens, "test"), in the table it returns.
	function sim:countWrites(instance, key: string)
		local counts = {}
		writeCounts[instance] = writeCounts[instance] or {}
		writeCounts[instance][key] = counts
		return counts
	end

	function sim:className(instance): string
		return state[instance].className
	end

	sim.game = game
	sim.workspace = workspace
	-- Roblox's CFrame.lookAt (Lune's faces the other way), for tests and tools.
	sim.lookAt = lookAt
	sim.drain = function(_self)
		drain()
	end

	sealed = true
	return sim
end

return Sim
