local Types = require("./Types")

@native
local function Benchmark(Func: () -> (), Iterations: number): Types.BenchmarkResult
	local OverheadStart = os.clock()
	for _ = 1, Iterations do
	end
	local Overhead = os.clock() - OverheadStart

	-- warm up
	for _ = 1, 50 do
		Func()
	end

	local Result: Types.BenchmarkResult = {
		Min = 0,
		Max = 0,
		Avg = 0,
		Med = 0,
		Total = 0,
	}
	local Sum = 0
	local Entries = table.create(10) :: { number }
	for i = 1, 10 do
		local Start = os.clock()
		for _ = 1, Iterations do
			Func()
		end
		local End = os.clock() - Start - Overhead
		local PerOp = (End * 1_000_000) / Iterations
		Sum += PerOp
		Entries[i] = PerOp
		Result.Total += End * 1_000
	end
	table.sort(Entries, function(a0: number, a1: number): boolean
		return a0 < a1
	end)

	Result.Min = Entries[1]
	Result.Max = Entries[10]
	Result.Med = (Entries[5] + Entries[6]) / 2
	Result.Avg = Sum / 10

	return Result
end

return Benchmark
