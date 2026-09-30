--!strict
-- A tiny test harness for Lune. Specs call `test`, then `run.luau` prints a summary.
-- `lune run tests/run.luau some words` runs only the tests whose suite and name contain
-- those words.

local process = require("@lune/process")

local TestLib = {}

local passed = 0
local skipped = 0
local failures: { string } = {}
local currentSuite = ""
local only = string.lower(table.concat(process.args, " "))

function TestLib.suite(name: string)
	currentSuite = name
end

function TestLib.test(name: string, fn: () -> ())
	if only ~= "" and not string.find(string.lower(`{currentSuite} › {name}`), only, 1, true) then
		skipped += 1
		return
	end
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		table.insert(failures, `{currentSuite} › {name}\n    {err}`)
	end
end

function TestLib.expect(condition: any, message: string?)
	if not condition then
		error(message or "expectation failed", 2)
	end
end

function TestLib.equal(actual: any, expected: any, message: string?)
	if actual ~= expected then
		error(`{message or "values differ"}: expected {tostring(expected)}, got {tostring(actual)}`, 2)
	end
end

function TestLib.summary(): boolean
	for _, failure in failures do
		print(`FAIL {failure}`)
	end
	print(`{passed} passed, {#failures} failed` .. if skipped > 0 then `, {skipped} skipped` else "")
	return #failures == 0
end

return TestLib
