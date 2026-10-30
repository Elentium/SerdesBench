--!native
--[[
	Multi-library serdes benchmark — arrays & maps only.
	Sera is excluded (no array/map support).
]]

local BenchTypes = require("./Types")
local Benchmark = require("./BenchHelper")

local Libs = script.Parent.Parent.Libs
local VoidSentryUltimate = require(Libs.VoidSentryUltimate)
local VoidSentry2 = require(Libs.VoidSentry2)
local BlazeSentry = require(Libs.BlazeSentry)
local Z = require(Libs.Z)
local Squash = require(Libs.Squash)

local VSTypes = VoidSentryUltimate.Types
local VS2Types = VoidSentry2.types
local VS2Static = VoidSentry2.static
local BSTypes = BlazeSentry.types
local BSStatic = BlazeSentry.static

local DefaultIterations = 5_000
local Results: BenchTypes.Results = {}
local CurrentSection: BenchTypes.Section? = nil

local Separator = ("_"):rep(50)
local SmallSeparator = "________________________"
local MedSeparator = "______________________________________"

local LIBS = {
	"VoidSentryUltimate",
	"VoidSentry2",
	"BlazeSentry",
	"Z",
	"Squash",
}

local function Test(Lib: string, TestName: string, Func: () -> (), Iterations: number)
	if not CurrentSection then
		return
	end
	task.wait()
	local Result = Benchmark(Func, Iterations)

	table.insert(CurrentSection.Nodes, {
		Name = TestName,
		Lib = Lib,
		Result = Result,
	})

	task.wait()
end

local function Section(Name: string)
	CurrentSection = {
		SectionName = Name,
		Nodes = {},
	}
	table.insert(Results, CurrentSection)
end

local function Fmt(N: number): string
	return string.format("%.2f", N)
end

local function PrintResults(Iterations: number)
	print(Separator)
	print("* SERDES ARRAY/MAP BENCH RESULTS (NO SERA)")
	print(`* ITERATIONS: {Iterations}`)
	for _, SectionData in Results do
		print(`** {SectionData.SectionName}:`)
		for _, Entry in SectionData.Nodes do
			print(SmallSeparator)
			print(`*** [{Entry.Lib}] {Entry.Name}:`)
			print(`**** Total: {Fmt(Entry.Result.Total)}ms`)
			print(`**** Avg: {Fmt(Entry.Result.Avg)}μs`)
			print(`**** Min: {Fmt(Entry.Result.Min)}μs`)
			print(`**** Max: {Fmt(Entry.Result.Max)}μs`)
			print(`**** Med: {Fmt(Entry.Result.Med)}μs`)
			print(SmallSeparator)
		end
		print(MedSeparator)
	end
	print(Separator)
end

local function ScoreLibs(
	Filter: ((Entry: BenchTypes.BenchmarkEntry, SectionName: string) -> boolean)?
): { BenchTypes.LibScore }
	local Sums: { [string]: number } = {}
	local Counts: { [string]: number } = {}

	for _, Lib in LIBS do
		Sums[Lib] = 0
		Counts[Lib] = 0
	end

	for _, SectionData in Results do
		for _, Entry in SectionData.Nodes do
			if Filter and not Filter(Entry, SectionData.SectionName) then
				continue
			end
			Sums[Entry.Lib] += Entry.Result.Med
			Counts[Entry.Lib] += 1
		end
	end

	local Scores: { BenchTypes.LibScore } = {}
	for _, Lib in LIBS do
		local Count = Counts[Lib]
		if Count > 0 then
			table.insert(Scores, {
				Lib = Lib,
				AvgMed = Sums[Lib] / Count,
				Count = Count,
			})
		end
	end

	table.sort(Scores, function(A, B)
		return A.AvgMed < B.AvgMed
	end)

	return Scores
end

local function PrintTop(Title: string, Scores: { BenchTypes.LibScore }, Limit: number?)
	local Cap = Limit or 5
	print(MedSeparator)
	print(`* {Title}`)
	local Shown = 0
	for Rank, Score in Scores do
		if Shown >= Cap then
			break
		end
		Shown += 1
		print(`** #{Rank} {Score.Lib} — {Fmt(Score.AvgMed)}μs med avg ({Score.Count} tests)`)
	end
	if Shown == 0 then
		print("** (no results)")
	end
end

local function PrintRankings()
	print(Separator)
	print("* RANKINGS (lower median μs is faster)")
	PrintTop("TOP 5 OVERALL (all tests)", ScoreLibs(nil), 5)
	PrintTop(
		"TOP 5 OVERALL — RoundTrip only",
		ScoreLibs(function(Entry)
			return string.find(Entry.Name, "RoundTrip", 1, true) ~= nil
		end),
		5
	)
	PrintTop(
		"TOP 5 OVERALL — Serialize only",
		ScoreLibs(function(Entry)
			return string.find(Entry.Name, "Serialize", 1, true) ~= nil
		end),
		5
	)
	PrintTop(
		"TOP 5 OVERALL — Deserialize only",
		ScoreLibs(function(Entry)
			return string.find(Entry.Name, "Deserialize", 1, true) ~= nil
		end),
		5
	)

	for _, SectionData in Results do
		local SectionName = SectionData.SectionName
		PrintTop(
			`TOP 5 — {SectionName}`,
			ScoreLibs(function(_, Name)
				return Name == SectionName
			end),
			5
		)
		PrintTop(
			`TOP 5 — {SectionName} (RoundTrip)`,
			ScoreLibs(function(Entry, Name)
				return Name == SectionName and string.find(Entry.Name, "RoundTrip", 1, true) ~= nil
			end),
			5
		)
	end
	print(Separator)
end

------------------------------------------------------------
-- Value builders
------------------------------------------------------------

local function MakeU8Array(Count: number): { number }
	local Arr: { number } = table.create(Count)
	for i = 1, Count do
		Arr[i] = i % 256
	end
	return Arr
end

local function MakeU8Map(Count: number): { [number]: number }
	local Map: { [number]: number } = {}
	for i = 1, Count do
		Map[i] = i % 256
	end
	return Map
end

------------------------------------------------------------
-- Bench runners
------------------------------------------------------------

local function BenchVS(Name: string, Schema: any, Value: any, Iter: number)
	local Serialize = VoidSentryUltimate.Serialize
	local Deserialize = VoidSentryUltimate.Deserialize

	Test("VoidSentryUltimate", `{Name} Serialize`, function()
		Serialize(Schema, Value)
	end, Iter)

	local Buf = Serialize(Schema, Value)
	Test("VoidSentryUltimate", `{Name} Deserialize`, function()
		Deserialize(Schema, Buf)
	end, Iter)

	Test("VoidSentryUltimate", `{Name} RoundTrip`, function()
		Deserialize(Schema, Serialize(Schema, Value))
	end, Iter)
end

local function BenchVS2(Name: string, Schema: any, Value: any, Iter: number)
	local Serialize = VS2Static.serialize
	local Deserialize = VS2Static.deserialize

	Test("VoidSentry2", `{Name} Serialize`, function()
		Serialize(Schema, Value)
	end, Iter)

	local Buf = Serialize(Schema, Value)
	Test("VoidSentry2", `{Name} Deserialize`, function()
		Deserialize(Schema, Buf)
	end, Iter)

	Test("VoidSentry2", `{Name} RoundTrip`, function()
		Deserialize(Schema, Serialize(Schema, Value))
	end, Iter)
end

local function BenchBS(Name: string, Schema: any, Value: any, Iter: number)
	local Serialize = BSStatic.serialize
	local Deserialize = BSStatic.deserialize

	Test("BlazeSentry", `{Name} Serialize`, function()
		Serialize(Schema, Value)
	end, Iter)

	local Buf = Serialize(Schema, Value)
	Test("BlazeSentry", `{Name} Deserialize`, function()
		Deserialize(Schema, Buf)
	end, Iter)

	Test("BlazeSentry", `{Name} RoundTrip`, function()
		Deserialize(Schema, Serialize(Schema, Value))
	end, Iter)
end

local function BenchZ(Name: string, Schema: any, Value: any, Iter: number)
	local Serialize = Z.ser
	local Deserialize = Z.des

	Test("Z", `{Name} Serialize`, function()
		Serialize(Schema, Value)
	end, Iter)

	local Buf = Serialize(Schema, Value)
	Test("Z", `{Name} Deserialize`, function()
		Deserialize(Schema, Buf)
	end, Iter)

	Test("Z", `{Name} RoundTrip`, function()
		Deserialize(Schema, Serialize(Schema, Value))
	end, Iter)
end

local function BenchSquash(Name: string, Serdes: any, Value: any, Iter: number)
	local Ser = Serdes.ser
	local Des = Serdes.des
	local Cursor = Squash.cursor
	local ToBuffer = Squash.tobuffer
	local FromBuffer = Squash.frombuffer

	Test("Squash", `{Name} Serialize`, function()
		local C = Cursor()
		Ser(C, Value)
		ToBuffer(C)
	end, Iter)

	local SetupCursor = Cursor()
	Ser(SetupCursor, Value)
	local Buf = ToBuffer(SetupCursor)

	Test("Squash", `{Name} Deserialize`, function()
		Des(FromBuffer(Buf))
	end, Iter)

	Test("Squash", `{Name} RoundTrip`, function()
		local C = Cursor()
		Ser(C, Value)
		Des(FromBuffer(ToBuffer(C)))
	end, Iter)
end

local function BenchArrayAll(Name: string, Value: { number }, Iter: number)
	BenchVS2(Name, VS2Types.array(VS2Types.uint8), Value, Iter)
	BenchBS(Name, BSTypes.array(BSTypes.uint8), Value, Iter)
	-- u16 length prefix to align with VS Array / VS2 array
	BenchZ(Name, Z.schema16({ Z.u8 }), Value, Iter)
	BenchVS(Name, VSTypes.Array(VSTypes.U8), Value, Iter)
	BenchSquash(Name, Squash.array(Squash.u8()), Value, Iter)
end

local function BenchMapAll(Name: string, Value: { [number]: number }, Iter: number)
	BenchVS2(Name, VS2Types.map(VS2Types.uint8, VS2Types.uint8), Value, Iter)
	BenchBS(Name, BSTypes.map(BSTypes.uint8, BSTypes.uint8), Value, Iter)
	BenchZ(Name, Z.schema16({ [Z.u8] = Z.u8 }), Value, Iter)
	BenchVS(Name, VSTypes.Map(VSTypes.U8, VSTypes.U8), Value, Iter)
	BenchSquash(Name, Squash.map(Squash.u8(), Squash.u8()), Value, Iter)
end

local function ComparatorNoSera(Log: boolean?, LogFullResults: boolean?, Iterations: number?): BenchTypes.Results
	table.clear(Results)
	local Iter = Iterations or DefaultIterations

	------------------------------------------------------------
	-- Array Types
	------------------------------------------------------------
	Section("Array Types")
	BenchArrayAll("Array (1 elem)", MakeU8Array(1), Iter)
	task.wait()
	BenchArrayAll("Array (10 elem)", MakeU8Array(10), Iter)
	task.wait()
	BenchArrayAll("Array (100 elem)", MakeU8Array(100), Iter)
	task.wait()

	------------------------------------------------------------
	-- Map Types
	------------------------------------------------------------
	Section("Map Types")
	BenchMapAll("Map (1 elem)", MakeU8Map(1), Iter)
	task.wait()
	BenchMapAll("Map (10 elem)", MakeU8Map(10), Iter)
	task.wait()
	BenchMapAll("Map (100 elem)", MakeU8Map(100), Iter)

	if Log then
		if LogFullResults then
			PrintResults(Iter)
		end
		PrintRankings()
	end

	return table.clone(Results)
end

return ComparatorNoSera
