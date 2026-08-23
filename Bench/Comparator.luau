--!native
--[[
	Multi-library serdes benchmark.
	Covers: Number / Other primitives, Vectors & CFrames, Structs.
	Skips arrays/maps (Sera has no support).
]]

local BenchTypes = require("./Types")
local Benchmark = require("./BenchHelper")

local Libs = script.Parent.Parent.Libs
local Sera = require(Libs.Sera)
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

local DefaultIterations = 10_000
local Results: BenchTypes.Results = {}
local CurrentSection: BenchTypes.Section? = nil

local Separator = ("_"):rep(50)
local SmallSeparator = "________________________"
local MedSeparator = "______________________________________"

local LIBS = {
	"Sera",
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
	print("* SERDES MULTI-LIB BENCH RESULTS")
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
	local Cap = Limit or 6
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
	PrintTop("TOP 6 OVERALL (all tests)", ScoreLibs(nil), 6)
	PrintTop(
		"TOP 6 OVERALL — RoundTrip only",
		ScoreLibs(function(Entry)
			return string.find(Entry.Name, "RoundTrip", 1, true) ~= nil
		end),
		6
	)
	PrintTop(
		"TOP 6 OVERALL — Serialize only",
		ScoreLibs(function(Entry)
			return string.find(Entry.Name, "Serialize", 1, true) ~= nil
		end),
		6
	)
	PrintTop(
		"TOP 6 OVERALL — Deserialize only",
		ScoreLibs(function(Entry)
			return string.find(Entry.Name, "Deserialize", 1, true) ~= nil
		end),
		6
	)

	for _, SectionData in Results do
		local SectionName = SectionData.SectionName
		PrintTop(
			`TOP 6 — {SectionName}`,
			ScoreLibs(function(_, Name)
				return Name == SectionName
			end),
			6
		)
		PrintTop(
			`TOP 6 — {SectionName} (RoundTrip)`,
			ScoreLibs(function(Entry, Name)
				return Name == SectionName and string.find(Entry.Name, "RoundTrip", 1, true) ~= nil
			end),
			6
		)
	end
	print(Separator)
end

------------------------------------------------------------
-- Shared helpers
------------------------------------------------------------

local function MakeFieldName(Index: number): string
	return `f{string.format("%03d", Index)}`
end

local function MakeU8StructValue(Count: number): { [string]: number }
	local Tbl: { [string]: number } = {}
	for i = 1, Count do
		Tbl[MakeFieldName(i)] = i % 256
	end
	return Tbl
end

------------------------------------------------------------
-- Schema builders
------------------------------------------------------------

local function MakeSeraU8Schema(Count: number): any
	local Params: { [string]: any } = {}
	for i = 1, Count do
		Params[MakeFieldName(i)] = Sera.Uint8
	end
	return Sera.Schema(Params)
end

local function MakeVSU8Struct(Count: number): any
	local Tbl: { [string]: any } = {}
	for i = 1, Count do
		Tbl[MakeFieldName(i)] = VSTypes.U8
	end
	return VSTypes.Struct(Tbl)
end

local function MakeVS2U8Struct(Count: number): any
	local Tbl: { [string]: any } = {}
	for i = 1, Count do
		Tbl[MakeFieldName(i)] = VS2Types.uint8
	end
	return VS2Types.struct(Tbl)
end

local function MakeBSU8Struct(Count: number): any
	local Tbl: { [string]: any } = {}
	for i = 1, Count do
		Tbl[MakeFieldName(i)] = BSTypes.uint8
	end
	return BSTypes.struct(Tbl)
end

local function MakeZU8Schema(Count: number): any
	local Tbl: { [string]: any } = {}
	for i = 1, Count do
		Tbl[MakeFieldName(i)] = Z.u8
	end
	return Z.schema(Tbl)
end

local function MakeSquashU8Record(Count: number): any
	local Tbl: { [string]: any } = {}
	for i = 1, Count do
		Tbl[MakeFieldName(i)] = Squash.u8()
	end
	return Squash.record(Tbl)
end

------------------------------------------------------------
-- Bench runners per library style
------------------------------------------------------------

local function BenchSera(Name: string, Schema: any, Value: { [string]: any }, Iter: number)
	local Serialize = Sera.Serialize
	local Deserialize = Sera.Deserialize

	Test("Sera", `{Name} Serialize`, function()
		Serialize(Schema, Value)
	end, Iter)

	local Buf = Serialize(Schema, Value)
	Test("Sera", `{Name} Deserialize`, function()
		Deserialize(Schema, Buf)
	end, Iter)

	Test("Sera", `{Name} RoundTrip`, function()
		Deserialize(Schema, Serialize(Schema, Value))
	end, Iter)
end

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

-- Sera only serializes via Schema — wrap primitives in a single field.
-- Z accepts ZTypes in ser/des directly; Squash serdes are used as-is (record only for structs).
local function BenchPrimitiveAll(
	Name: string,
	SeraType: any,
	VSSchema: any,
	VS2Schema: any,
	BSSchema: any,
	ZType: any,
	SquashSerdes: any,
	Value: any,
	Iter: number
)
	BenchSera(Name, Sera.Schema({ v = SeraType }), { v = Value }, Iter)
	BenchVS(Name, VSSchema, Value, Iter)
	BenchVS2(Name, VS2Schema, Value, Iter)
	BenchBS(Name, BSSchema, Value, Iter)
	BenchZ(Name, ZType, Value, Iter)
	BenchSquash(Name, SquashSerdes, Value, Iter)
end

local function Comparator(Log: boolean?, LogFullResults: boolean?, Iterations: number?): BenchTypes.Results
	table.clear(Results)
	local Iter = Iterations or DefaultIterations

	local TestVector = Vector3.new(1, 2, 3)
	local TestCFrame = CFrame.new(1, 2, 3) * CFrame.Angles(0.5, 1, 0.25)

	------------------------------------------------------------
	-- Number Types
	------------------------------------------------------------
	Section("Number Types")
	BenchPrimitiveAll("U8", Sera.Uint8, VSTypes.U8, VS2Types.uint8, BSTypes.uint8, Z.u8, Squash.u8(), 42, Iter)
	task.wait()
	BenchPrimitiveAll("I8", Sera.Int8, VSTypes.I8, VS2Types.int8, BSTypes.int8, Z.i8, Squash.i8(), -42, Iter)
	task.wait()
	BenchPrimitiveAll("U16", Sera.Uint16, VSTypes.U16, VS2Types.uint16, BSTypes.uint16, Z.u16, Squash.u16(), 42, Iter)
	task.wait()
	BenchPrimitiveAll("I16", Sera.Int16, VSTypes.I16, VS2Types.int16, BSTypes.int16, Z.i16, Squash.i16(), -42, Iter)
	task.wait()
	BenchPrimitiveAll("U32", Sera.Uint32, VSTypes.U32, VS2Types.uint32, BSTypes.uint32, Z.u32, Squash.u32(), 42, Iter)
	task.wait()
	BenchPrimitiveAll("I32", Sera.Int32, VSTypes.I32, VS2Types.int32, BSTypes.int32, Z.i32, Squash.i32(), -42, Iter)
	task.wait()
	BenchPrimitiveAll(
		"F32",
		Sera.Float32,
		VSTypes.F32,
		VS2Types.float32,
		BSTypes.float32,
		Z.f32,
		Squash.f32(),
		3.14,
		Iter
	)
	task.wait()
	BenchPrimitiveAll(
		"F64",
		Sera.Float64,
		VSTypes.F64,
		VS2Types.float64,
		BSTypes.float64,
		Z.f64,
		Squash.f64(),
		3.14,
		Iter
	)
	task.wait()

	------------------------------------------------------------
	-- Other Primitives
	------------------------------------------------------------
	Section("Other Primitives")
	BenchPrimitiveAll(
		"Bool",
		Sera.Boolean,
		VSTypes.Bool,
		VS2Types.boolean,
		BSTypes.boolean,
		Z.bool,
		Squash.boolean(),
		true,
		Iter
	)
	task.wait()
	BenchPrimitiveAll(
		"String8 (1 char)",
		Sera.String8,
		VSTypes.String8,
		VS2Types.string255,
		BSTypes.string255,
		Z.str8,
		Squash.string(),
		"a",
		Iter
	)
	task.wait()
	BenchPrimitiveAll(
		"String8 (10 chars)",
		Sera.String8,
		VSTypes.String8,
		VS2Types.string255,
		BSTypes.string255,
		Z.str8,
		Squash.string(),
		"aaaaaaaaaa",
		Iter
	)
	task.wait()
	BenchPrimitiveAll(
		"String8 (100 chars)",
		Sera.String8,
		VSTypes.String8,
		VS2Types.string255,
		BSTypes.string255,
		Z.str8,
		Squash.string(),
		string.rep("a", 100),
		Iter
	)
	task.wait()
	BenchPrimitiveAll(
		"String16 (100 chars)",
		Sera.String16,
		VSTypes.String,
		VS2Types.string,
		BSTypes.string,
		Z.str16,
		Squash.string(),
		string.rep("a", 100),
		Iter
	)
	task.wait()

	------------------------------------------------------------
	-- Vector Types
	------------------------------------------------------------
	Section("Vector Types")
	do
		local Name = "Vector3"
		BenchSera(Name, Sera.Schema({ v = Sera.Vector3 }), { v = TestVector }, Iter)
		BenchVS(Name, VSTypes.Vector, TestVector, Iter)
		BenchVS2(Name, VS2Types.vector3, TestVector, Iter)
		BenchBS(Name, BSTypes.vector3, TestVector, Iter)
		BenchZ(Name, Z.Vector3, TestVector, Iter)
		BenchSquash(Name, Squash.Vector3(Squash.f32()), TestVector, Iter)
	end
	task.wait()

	------------------------------------------------------------
	-- CFrame Types (full + lossy/compressed where available)
	------------------------------------------------------------
	Section("CFrame Types")
	do
		local Name = "CFrame"
		BenchSera(Name, Sera.Schema({ v = Sera.CFrame }), { v = TestCFrame }, Iter)
		BenchVS(Name, VSTypes.CFrame, TestCFrame, Iter)
		BenchVS2(Name, VS2Types.cframe, TestCFrame, Iter)
		BenchBS(Name, BSTypes.cframe, TestCFrame, Iter)
		BenchZ(Name, Z.CFrame, TestCFrame, Iter)
		BenchSquash(Name, Squash.CFrame(Squash.f32()), TestCFrame, Iter)
	end
	task.wait()

	do
		-- Lossy / quaternion / axis-angle compressed variants (~28B class)
		local Name = "LossyCFrame"
		BenchSera(Name, Sera.Schema({ v = Sera.LossyCFrame }), { v = TestCFrame }, Iter)
		BenchVS(Name, VSTypes.QCFrame, TestCFrame, Iter)
		BenchVS2(Name, VS2Types.qcframe, TestCFrame, Iter)
		BenchBS(Name, BSTypes.qcframe, TestCFrame, Iter)
		BenchZ(Name, Z.CFrame28, TestCFrame, Iter)
		BenchSquash(Name, Squash.CFrame(Squash.f32()), TestCFrame, Iter)
	end
	task.wait()

	------------------------------------------------------------
	-- Struct Types
	------------------------------------------------------------
	Section("Struct Types")
	do
		local Value1 = MakeU8StructValue(1)
		local Name = "Struct (1 field)"
		BenchSera(Name, MakeSeraU8Schema(1), Value1, Iter)
		BenchVS(Name, MakeVSU8Struct(1), Value1, Iter)
		BenchVS2(Name, MakeVS2U8Struct(1), Value1, Iter)
		BenchBS(Name, MakeBSU8Struct(1), Value1, Iter)
		BenchZ(Name, MakeZU8Schema(1), Value1, Iter)
		BenchSquash(Name, MakeSquashU8Record(1), Value1, Iter)
	end
	task.wait()
	do
		local Value10 = MakeU8StructValue(10)
		local Name = "Struct (10 fields)"
		BenchSera(Name, MakeSeraU8Schema(10), Value10, Iter)
		BenchVS(Name, MakeVSU8Struct(10), Value10, Iter)
		BenchVS2(Name, MakeVS2U8Struct(10), Value10, Iter)
		BenchBS(Name, MakeBSU8Struct(10), Value10, Iter)
		BenchZ(Name, MakeZU8Schema(10), Value10, Iter)
		BenchSquash(Name, MakeSquashU8Record(10), Value10, Iter)
	end
	task.wait()
	do
		local Value100 = MakeU8StructValue(100)
		local Name = "Struct (100 fields)"
		BenchSera(Name, MakeSeraU8Schema(100), Value100, Iter)
		BenchVS(Name, MakeVSU8Struct(100), Value100, Iter)
		BenchVS2(Name, MakeVS2U8Struct(100), Value100, Iter)
		BenchBS(Name, MakeBSU8Struct(100), Value100, Iter)
		BenchZ(Name, MakeZU8Schema(100), Value100, Iter)
		BenchSquash(Name, MakeSquashU8Record(100), Value100, Iter)
	end

	if Log then
		if LogFullResults then
			PrintResults(Iter)
		end
		PrintRankings()
	end

	return table.clone(Results)
end

return Comparator
