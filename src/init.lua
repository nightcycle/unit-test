--!strict
export type TestResult = boolean
export type SectionResult = {[string]: boolean}
export type LedgerResult = {[string]: SectionResult}
export type Test = () -> boolean
export type TestSection = {[string]: Test}
export type TestLedger = {[string]: TestSection}

function runTest(test: Test): TestResult
	local result: boolean?
	local success, msg = pcall(function()
		result = test()
	end)
	if not success then
		task.spawn(function()
			error(msg)
		end)
	end
	if result == nil then result = false end
	assert(result ~= nil)
	return result
end

function runSection(section: TestSection): SectionResult
	local result: SectionResult = {}

	for k, test: Test in pairs(section) do
		local testResult = runTest(test)
		if not testResult then
			warn("FAIL", k)
		end
		result[k] = testResult
	end

	return result
end

function runLedger(module: ModuleScript): LedgerResult
	local ledger: TestLedger = require(module) :: any
	local result: LedgerResult = {}

	for k, section: TestSection in pairs(ledger) do
		result[k] = runSection(section)
	end

	return result
end

function getIfLedger(inst: Instance): boolean
	return inst:IsA("ModuleScript") and not (string.find(inst.Name, ".test") == nil)
end

return function(moduleScript: ModuleScript?): boolean
	-- assemble list of ledger modules
	print("Assembling tests")
	local ledgers: {[number]: ModuleScript} = {}
	if moduleScript then
		table.insert(ledgers, moduleScript)
	else
		for i, inst in ipairs(game:GetDescendants()) do
			if getIfLedger(inst) then
				assert(inst:IsA("ModuleScript"))
				table.insert(ledgers, inst)
			end
		end
	end

	-- run all ledgers
	print("Running tests")
	local isSuccess = true
	local results = {}
	for i, module in ipairs(ledgers) do
		local ledgerResult = runLedger(module)
		if not ledgerResult then
			isSuccess = false
		end
		results[module.Name] = ledgerResult		
	end
	return isSuccess, results
end