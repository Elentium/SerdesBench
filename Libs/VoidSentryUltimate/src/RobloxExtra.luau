--!optimize 2
const Definitions = require("./Definitions")
const InstanceMaps = require("./InstanceMaps")

const IdMap = InstanceMaps.IdMap
const ReverseMap = InstanceMaps.ReverseMap

type SerdesNode<T> = Definitions.SerdesNode<T>

const SER = 1
const DES = 2

const NewAxes = Axes.new :: (...Enum.Axis | boolean) -> Axes
const NewFaces = Faces.new :: (...Enum.NormalId | boolean) -> Faces
const FloatDateTime = DateTime.fromUnixTimestampMillis
const NewFloatCurveKey = FloatCurveKey.new
const NewPhysicalProperties = PhysicalProperties.new
const IntDateTime = DateTime.fromUnixTimestamp
const NewNumberSequenceKeypoint = NumberSequenceKeypoint.new
const NewNumberSequence = NumberSequence.new
const NewNumberRange = NumberRange.new
const NewFont = Font.new
const NewRay = Ray.new
const NewTweenInfo = TweenInfo.new
const CreateTable = table.create

const EnumAxis = Enum.Axis
const EnumNormalId = Enum.NormalId
const AxisX = EnumAxis.X
const AxisY = EnumAxis.Y
const AxisZ = EnumAxis.Z
const FrontId = EnumNormalId.Front
const TopId = EnumNormalId.Top
const RightId = EnumNormalId.Right
const BackId = EnumNormalId.Back
const LeftId = EnumNormalId.Left
const BottomId = EnumNormalId.Bottom
const EnumMaterial = Enum.Material

const EnumInterpolationMode = Enum.KeyInterpolationMode
const Cubic = EnumInterpolationMode.Cubic

const FontStyle = Enum.FontStyle
const Italic = FontStyle.Italic
const Normal = FontStyle.Normal

const EasingStyle = Enum.EasingStyle
const EasingDirection = Enum.EasingDirection

@native const function EnumLookup(EnumType: Enum): ({ EnumItem }, { [EnumItem]: number })
    const IdToItem = EnumType:GetEnumItems()
    const ItemToId: { [EnumItem]: number } = {}
    for Id, Item in IdToItem do
        ItemToId[Item] = Id
    end
    return IdToItem, ItemToId
end

const MaterialIdToItem, MaterialItemToId = EnumLookup(EnumMaterial)
const InterpolationIdToItem, InterpolationItemToId = EnumLookup(EnumInterpolationMode)
const EasingStyleIdToItem, EasingStyleItemToId = EnumLookup(EasingStyle)
const EasingDirectionIdToItem, EasingDirectionItemToId = EnumLookup(EasingDirection)

-- the helpers get inlined so there is no overhead
const Oct16Scale = 32767
const Oct8Scale = 127

@native const function EncodeOctahedral(x: number, y: number, z: number): (number, number)
    const Sum = math.abs(x) + math.abs(y) + math.abs(z)
    if Sum == 0 then
        return 0, 0
    end
    const Inv = 1 / Sum
    local rx, ry = x * Inv, y * Inv
    if z < 0 then
        rx, ry = (1 - math.abs(ry)) * (if rx >= 0 then 1 else -1), (1 - math.abs(rx)) * (if ry >= 0 then 1 else -1)
    end
    return rx, ry
end

@native const function DecodeOctahedral(x: number, y: number): (number, number, number)
    local z = 1 - math.abs(x) - math.abs(y)
    if z < 0 then
        x, y = (1 - math.abs(y)) * (if x >= 0 then 1 else -1), (1 - math.abs(x)) * (if y >= 0 then 1 else -1)
    end
    const Inv = 1 / math.sqrt(x * x + y * y + z * z)
    return x * Inv, y * Inv, z * Inv
end

@native const function WriteOct16(x: number, y: number, z: number, Buf: buffer, Cur: number): number
    const ox, oy = EncodeOctahedral(x, y, z)
    buffer.writei16(Buf, Cur, math.round(ox * Oct16Scale))
    buffer.writei16(Buf, Cur + 2, math.round(oy * Oct16Scale))
    return Cur + 4
end

@native const function ReadOct16(Buf: buffer, Cur: number): (number, number, number)
    return DecodeOctahedral(buffer.readi16(Buf, Cur) / Oct16Scale, buffer.readi16(Buf, Cur + 2) / Oct16Scale)
end

@native const function WriteOct8(x: number, y: number, z: number, Buf: buffer, Cur: number): number
    const ox, oy = EncodeOctahedral(x, y, z)
    buffer.writei8(Buf, Cur, math.round(ox * Oct8Scale))
    buffer.writei8(Buf, Cur + 1, math.round(oy * Oct8Scale))
    return Cur + 2
end

@native const function ReadOct8(Buf: buffer, Cur: number): (number, number, number)
    return DecodeOctahedral(buffer.readi8(Buf, Cur) / Oct8Scale, buffer.readi8(Buf, Cur + 1) / Oct8Scale)
end

@native const function EncodeVec(Value: Vector3, Buf: buffer, Cur: number): number
    buffer.writef32(Buf, Cur, Value.X)
    buffer.writef32(Buf, Cur + 4, Value.Y)
    buffer.writef32(Buf, Cur + 8, Value.Z)
    return Cur + 12
end

@native const function DecodeVec(Buf: buffer, Cur: number): (Vector3, number)
    return Vector3.new(
        buffer.readf32(Buf, Cur),
        buffer.readf32(Buf, Cur + 4),
        buffer.readf32(Buf, Cur + 8)
    ), Cur + 12
end

@native const function UIntSer(Value: number, Buf: buffer, Cur: number): number
    if Value < 0 then
        error("Unsigned Integer type cannot Serialize negative value")
    elseif Value < 0x80 then
        buffer.writeu8(Buf, Cur, Value)
        return Cur + 1
    elseif Value < 0x4000 then
        buffer.writeu16(Buf, Cur, bit32.bor(bit32.band(Value, 0x7F), bit32.band(bit32.lshift(Value, 1), 0x7F00), 0x80))
        return Cur + 2
    elseif Value < 0x200000 then
        buffer.writeu16(Buf, Cur, bit32.bor(bit32.band(Value, 0x7F), bit32.band(bit32.lshift(Value, 1), 0x7F00), 0x8080))
        buffer.writeu8(Buf, Cur + 2, bit32.rshift(Value, 14))
        return Cur + 3
    elseif Value < 0x10000000 then
        buffer.writeu32(Buf, Cur, bit32.bor(
            bit32.band(Value, 0x7F),
            bit32.band(bit32.lshift(Value, 1), 0x7F00),
            bit32.band(bit32.lshift(Value, 2), 0x7F0000),
            bit32.lshift(bit32.rshift(Value, 21), 24),
            0x808080
        ))
        return Cur + 4
    end

    buffer.writeu32(Buf, Cur, bit32.bor(
        bit32.band(Value, 0x7F),
        bit32.band(bit32.lshift(Value, 1), 0x7F00),
        bit32.band(bit32.lshift(Value, 2), 0x7F0000),
        bit32.band(bit32.lshift(Value, 3), 0x7F000000),
        0x80808080
    ))

    const Hi = Value // 0x10000000
    if Hi < 0x80 then
        buffer.writeu8(Buf, Cur + 4, Hi)
        return Cur + 5
    elseif Hi < 0x4000 then
        buffer.writeu16(Buf, Cur + 4, bit32.bor(bit32.band(Hi, 0x7F), bit32.band(bit32.lshift(Hi, 1), 0x7F00), 0x80))
        return Cur + 6
    elseif Hi < 0x200000 then
        buffer.writeu16(Buf, Cur + 4, bit32.bor(bit32.band(Hi, 0x7F), bit32.band(bit32.lshift(Hi, 1), 0x7F00), 0x8080))
        buffer.writeu8(Buf, Cur + 6, bit32.rshift(Hi, 14))
        return Cur + 7
    end

    buffer.writeu32(Buf, Cur + 4, bit32.bor(
        bit32.band(Hi, 0x7F),
        bit32.band(bit32.lshift(Hi, 1), 0x7F00),
        bit32.band(bit32.lshift(Hi, 2), 0x7F0000),
        bit32.lshift(bit32.rshift(Hi, 21), 24),
        0x808080
    ))
    return Cur + 8
end

@native const function UIntDes(Buf: buffer, Cur: number): (number, number)
    local Byte = buffer.readu8(Buf, Cur)
    if Byte < 0x80 then
        return Byte, Cur + 1
    end
    local Value = Byte

    Byte = buffer.readu8(Buf, Cur + 1)
    Value += Byte * 0x80
    if Byte < 0x80 then
        return Value - 0x80, Cur + 2
    end

    Byte = buffer.readu8(Buf, Cur + 2)
    Value += Byte * 0x4000
    if Byte < 0x80 then
        return Value - 0x4080, Cur + 3
    end

    Byte = buffer.readu8(Buf, Cur + 3)
    Value += Byte * 0x200000
    if Byte < 0x80 then
        return Value - 0x204080, Cur + 4
    end

    Byte = buffer.readu8(Buf, Cur + 4)
    Value += Byte * 0x10000000
    if Byte < 0x80 then
        return Value - 0x10204080, Cur + 5
    end

    Byte = buffer.readu8(Buf, Cur + 5)
    Value += Byte * 0x800000000
    if Byte < 0x80 then
        return Value - 0x810204080, Cur + 6
    end

    Byte = buffer.readu8(Buf, Cur + 6)
    Value += Byte * 0x40000000000
    if Byte < 0x80 then
        return Value - 0x40810204080, Cur + 7
    end

    return Value - 0x2040810204080 + buffer.readu8(Buf, Cur + 7) * 0x2000000000000, Cur + 8
end

const AxesNode: SerdesNode<Axes> = {}
do
    @native const function AxesSer(Value: Axes, Buf: buffer, Cur: number): number
        local Byte = 0
        if Value.X then
            Byte += 1
        end
        if Value.Y then
            Byte += 2
        end
        if Value.Z then
            Byte += 4
        end
        buffer.writeu8(Buf, Cur, Byte)
        return Cur + 1
    end

    @native const function AxesDes(Buf: buffer, Cur: number): (Axes, number)
        const Byte = buffer.readu8(Buf, Cur)
        const x = bit32.btest(Byte, 1)
        const y = bit32.btest(Byte, 2)
        const z = bit32.btest(Byte, 4)

        return NewAxes(
            x and AxisX,
            y and AxisY,
            z and AxisZ
        ), Cur + 1
    end

    AxesNode[SER] = AxesSer
    AxesNode[DES] = AxesDes
end

const FacesNode: SerdesNode<Faces> = {}
do
    @native const function FacesSer(Value: Faces, Buf: buffer, Cur: number): number
        local Byte = 0
        if Value.Front then
            Byte += 1
        end
        if Value.Top then
            Byte += 2
        end
        if Value.Right then
            Byte += 4
        end
        if Value.Back then
            Byte += 8
        end
        if Value.Left then
            Byte += 16
        end
        if Value.Bottom then
            Byte += 32
        end
        buffer.writeu8(Buf, Cur, Byte)
        return Cur + 1
    end

    @native const function FacesDes(Buf: buffer, Cur: number): (Faces, number)
        const Byte = buffer.readu8(Buf, Cur)
        const Front = bit32.btest(Byte, 1)
        const Top = bit32.btest(Byte, 2)
        const Right = bit32.btest(Byte, 4)
        const Back = bit32.btest(Byte, 8)
        const Left = bit32.btest(Byte, 16)
        const Bottom = bit32.btest(Byte, 32)

        return NewFaces(
            Front and FrontId,
            Top and TopId,
            Right and RightId,
            Back and BackId,
            Left and LeftId,
            Bottom and BottomId
        ), Cur + 1
    end

    FacesNode[SER] = FacesSer
    FacesNode[DES] = FacesDes
end

const DateTimeNode: SerdesNode<DateTime> = {}
do
    @native const function DateTimeSer(Value: DateTime, Buf: buffer, Cur: number): number
        buffer.writef64(Buf, Cur, Value.UnixTimestampMillis)
        return Cur + 8
    end

    @native const function DateTimeDes(Buf: buffer, Cur: number): (DateTime, number)
        const Timestamp = buffer.readf64(Buf, Cur)
        return FloatDateTime(Timestamp), Cur + 8
    end

    DateTimeNode[SER] = DateTimeSer
    DateTimeNode[DES] = DateTimeDes
end

const DateTimeF32: SerdesNode<DateTime> = {}
do
    @native const function DateTimeF32Ser(Value: DateTime, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.UnixTimestampMillis)
        return Cur + 4
    end

    @native const function DateTimeF32Des(Buf: buffer, Cur: number): (DateTime, number)
        const Timestamp = buffer.readf32(Buf, Cur)
        return FloatDateTime(Timestamp), Cur + 4
    end

    DateTimeF32[SER] = DateTimeF32Ser
    DateTimeF32[DES] = DateTimeF32Des
end

const DateTimeInt: SerdesNode<DateTime> = {}
do
    @native const function DateTimeIntSer(Value: DateTime, Buf: buffer, Cur: number): number
        const Timestamp = Value.UnixTimestamp
        buffer.writeu32(Buf, Cur, Timestamp)
        buffer.writeu8(Buf, Cur + 4, Timestamp // 0x100000000)
        return Cur + 5
    end

    @native const function DateTimeIntDes(Buf: buffer, Cur: number): (DateTime, number)
        const Low = buffer.readu32(Buf, Cur)
        const High = buffer.readu8(Buf, Cur + 4)
	    const Timestamp = Low + High * 0x100000000
        return IntDateTime(Timestamp), Cur + 5
    end

    DateTimeInt[SER] = DateTimeIntSer
    DateTimeInt[DES] = DateTimeIntDes
end

const FloatCurveKeyNode: SerdesNode<FloatCurveKey> = {}
do
    @native const function FloatCurveKeySer(Value: FloatCurveKey, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.Time)
        buffer.writef32(Buf, Cur + 4, Value.Value)
        const InterpolationMode = Value.Interpolation
        buffer.writeu8(Buf, Cur + 8, InterpolationItemToId[InterpolationMode])
        if InterpolationMode == Cubic then
            buffer.writef32(Buf, Cur + 9, Value.LeftTangent)
            buffer.writef32(Buf, Cur + 13, Value.RightTangent)
            Cur += 8
        end
        return Cur + 9
    end

    @native const function FloatCurveKeyDes(Buf: buffer, Cur: number): (FloatCurveKey, number)
        const Time = buffer.readf32(Buf, Cur)
        const Value = buffer.readf32(Buf, Cur + 4)
        const InterpolationMode = buffer.readu8(Buf, Cur + 8)
        const ModeEnum = InterpolationIdToItem[InterpolationMode] :: Enum.KeyInterpolationMode
        const Result = NewFloatCurveKey(Time, Value, ModeEnum)
        if ModeEnum == Cubic then
            Result.LeftTangent = buffer.readf32(Buf, Cur + 9)
            Result.RightTangent = buffer.readf32(Buf, Cur + 13)
            Cur += 8
        end
        return Result, Cur + 9
    end

    FloatCurveKeyNode[SER] = FloatCurveKeySer
    FloatCurveKeyNode[DES] = FloatCurveKeyDes
end

const PhysicalPropertiesNode: SerdesNode<PhysicalProperties> = {}
do
    @native const function PhysicalPropertiesSer(Value: PhysicalProperties, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.Density)
        buffer.writef32(Buf, Cur + 4, Value.Friction)
        buffer.writef32(Buf, Cur + 8, Value.Elasticity)
        buffer.writef32(Buf, Cur + 12, Value.FrictionWeight)
        buffer.writef32(Buf, Cur + 16, Value.ElasticityWeight)
        return Cur + 20
    end

    @native const function PhysicalPropertiesDes(Buf: buffer, Cur: number): (PhysicalProperties, number)
        const Density = buffer.readf32(Buf, Cur)
        const Friction = buffer.readf32(Buf, Cur + 4)
        const Elasticity = buffer.readf32(Buf, Cur + 8)
        const FrictionWeight = buffer.readf32(Buf, Cur + 12)
        const ElasticityWeight = buffer.readf32(Buf, Cur + 16)
        return NewPhysicalProperties(Density, Friction, Elasticity, FrictionWeight, ElasticityWeight), Cur + 20
    end

    PhysicalPropertiesNode[SER] = PhysicalPropertiesSer
    PhysicalPropertiesNode[DES] = PhysicalPropertiesDes
end

const RaycastResultNode: SerdesNode<RaycastResult> = {}
do
    @native const function RaycastResultSer(Value: RaycastResult, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.Distance)
        buffer.writeu8(Buf, Cur + 4, MaterialItemToId[Value.Material])
        buffer.writeu16(Buf, Cur + 5, ReverseMap[Value.Instance])
        Cur = EncodeVec(Value.Position, Buf, Cur + 7)
        const Normal = Value.Normal
        return WriteOct16(Normal.X, Normal.Y, Normal.Z, Buf, Cur)
    end

    @native const function RaycastResultDes(Buf: buffer, Cur: number): (RaycastResult, number)
        const Distance = buffer.readf32(Buf, Cur)
        const Material = MaterialIdToItem[buffer.readu8(Buf, Cur + 4)]
        const Inst = IdMap[buffer.readu16(Buf, Cur + 5)]
        const Position, Next = DecodeVec(Buf, Cur + 7)
        const nx, ny, nz = ReadOct16(Buf, Next)

        return {
            Position = Position,
            Distance = Distance,
            Material = Material :: Enum.Material,
            Instance = Inst :: BasePart,
            Normal = Vector3.new(nx, ny, nz)
        }, Next + 4
    end

    RaycastResultNode[SER] = RaycastResultSer
    RaycastResultNode[DES] = RaycastResultDes
end

const RaycastResult8: SerdesNode<RaycastResult> = {}
do
    @native const function RaycastResult8Ser(Value: RaycastResult, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.Distance)
        buffer.writeu8(Buf, Cur + 4, MaterialItemToId[Value.Material])
        buffer.writeu16(Buf, Cur + 5, ReverseMap[Value.Instance])
        Cur = EncodeVec(Value.Position, Buf, Cur + 7)
        const Normal = Value.Normal
        return WriteOct8(Normal.X, Normal.Y, Normal.Z, Buf, Cur)
    end

    @native const function RaycastResult8Des(Buf: buffer, Cur: number): (RaycastResult, number)
        const Distance = buffer.readf32(Buf, Cur)
        const Material = MaterialIdToItem[buffer.readu8(Buf, Cur + 4)]
        const Inst = IdMap[buffer.readu16(Buf, Cur + 5)]
        const Position, Next = DecodeVec(Buf, Cur + 7)
        const nx, ny, nz = ReadOct8(Buf, Next)

        return {
            Position = Position,
            Distance = Distance,
            Material = Material :: Enum.Material,
            Instance = Inst :: BasePart,
            Normal = Vector3.new(nx, ny, nz)
        }, Next + 2
    end

    RaycastResult8[SER] = RaycastResult8Ser
    RaycastResult8[DES] = RaycastResult8Des
end

const NumberSequenceKeypointNode: SerdesNode<NumberSequenceKeypoint> = {}
do
    @native const function NumberSequenceKeypointSer(Value: NumberSequenceKeypoint, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.Time)
        buffer.writef32(Buf, Cur + 4, Value.Value)
        buffer.writef32(Buf, Cur + 8, Value.Envelope)
        return Cur + 12
    end

    @native const function NumberSequenceKeypointDes(Buf: buffer, Cur: number): (NumberSequenceKeypoint, number)
        return NewNumberSequenceKeypoint(
            buffer.readf32(Buf, Cur),
            buffer.readf32(Buf, Cur + 4),
            buffer.readf32(Buf, Cur + 8)
        ), Cur + 12
    end

    NumberSequenceKeypointNode[SER] = NumberSequenceKeypointSer
    NumberSequenceKeypointNode[DES] = NumberSequenceKeypointDes
end

const NumberSequenceNode: SerdesNode<NumberSequence> = {}
do
    @native const function NumberSequenceSer(Value: NumberSequence, Buf: buffer, Cur: number): number
        const Keypoints = Value.Keypoints
        const Len = #Keypoints
        buffer.writeu8(Buf, Cur, Len)
        Cur += 1
        for _, Keypoint in Keypoints do
            buffer.writef32(Buf, Cur, Keypoint.Time)
            buffer.writef32(Buf, Cur + 4, Keypoint.Value)
            buffer.writef32(Buf, Cur + 8, Keypoint.Envelope)
            Cur += 12
        end
        return Cur
    end

    @native const function NumberSequenceDes(Buf: buffer, Cur: number): (NumberSequence, number)
        const Len = buffer.readu8(Buf, Cur)
        const Keypoints = CreateTable<<NumberSequenceKeypoint>>(Len)
        Cur += 1

        for i = 1, Len do
            Keypoints[i] = NewNumberSequenceKeypoint(
                buffer.readf32(Buf, Cur),
                buffer.readf32(Buf, Cur + 4),
                buffer.readf32(Buf, Cur + 8)
            )
            Cur += 12
        end

        return NewNumberSequence(Keypoints), Cur
    end

    NumberSequenceNode[SER] = NumberSequenceSer
    NumberSequenceNode[DES] = NumberSequenceDes
end

const NumberRangeNode: SerdesNode<NumberRange> = {}
do
    @native const function NumberRangeSer(Value: NumberRange, Buf: buffer, Cur: number): number
        buffer.writef64(Buf, Cur, Value.Min)
        buffer.writef64(Buf, Cur + 8, Value.Max)
        return Cur + 16
    end

    @native const function NumberRangeDes(Buf: buffer, Cur: number): (NumberRange, number)
        const Min = buffer.readf64(Buf, Cur)
        const Max = buffer.readf64(Buf, Cur + 8)
        return NewNumberRange(Min, Max), Cur + 16
    end

    NumberRangeNode[SER] = NumberRangeSer
    NumberRangeNode[DES] = NumberRangeDes
end

const NumberRangeF32: SerdesNode<NumberRange> = {}
do
    @native const function NumberRangeF32Ser(Value: NumberRange, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.Min)
        buffer.writef32(Buf, Cur + 4, Value.Max)
        return Cur + 8
    end

    @native const function NumberRangeF32Des(Buf: buffer, Cur: number): (NumberRange, number)
        const Min = buffer.readf32(Buf, Cur)
        const Max = buffer.readf32(Buf, Cur + 4)
        return NewNumberRange(Min, Max), Cur + 8
    end

    NumberRangeF32[SER] = NumberRangeF32Ser
    NumberRangeF32[DES] = NumberRangeF32Des
end

const FontNode: SerdesNode<Font> = {}
do
    const Weights = Enum.FontWeight:GetEnumItems()

	table.sort(Weights, function(a: EnumItem, b: EnumItem)
		return a.Value < b.Value
	end)

	const IdToWeight = CreateTable(#Weights) :: { Enum.FontWeight }
	const WeightToId = {}

	for i, v in Weights do
		IdToWeight[i] = v
		WeightToId[v] = i
	end

    const IdToFamily = {
        "rbxasset://fonts/families/AccanthisADFStd.json",
        "rbxasset://fonts/families/AmaticSC.json",
        "rbxasset://fonts/families/Arimo.json",
        "rbxasset://fonts/families/Balthazar.json",
        "rbxasset://fonts/families/Bangers.json",
        "rbxasset://fonts/families/BuilderExtended.json",
        "rbxasset://fonts/families/BuilderMono.json",
        "rbxasset://fonts/families/BuilderSans.json",
        "rbxasset://fonts/families/ComicNeueAngular.json",
        "rbxasset://fonts/families/Creepster.json",
        "rbxasset://fonts/families/DenkOne.json",
        "rbxasset://fonts/families/Fondamento.json",
        "rbxasset://fonts/families/FredokaOne.json",
        "rbxasset://fonts/families/GothamSSm.json",
        "rbxasset://fonts/families/GrenzeGotisch.json",
        "rbxasset://fonts/families/Guru.json",
        "rbxasset://fonts/families/HighwayGothic.json",
        "rbxasset://fonts/families/Inconsolata.json",
        "rbxasset://fonts/families/IndieFlower.json",
        "rbxasset://fonts/families/JosefinSans.json",
        "rbxasset://fonts/families/Jura.json",
        "rbxasset://fonts/families/Kalam.json",
        "rbxasset://fonts/families/LegacyArial.json",
        "rbxasset://fonts/families/LuckiestGuy.json",
        "rbxasset://fonts/families/Merriweather.json",
        "rbxasset://fonts/families/Michroma.json",
        "rbxasset://fonts/families/Montserrat.json",
        "rbxasset://fonts/families/Nunito.json",
        "rbxasset://fonts/families/Oswald.json",
        "rbxasset://fonts/families/PatrickHand.json",
        "rbxasset://fonts/families/PermanentMarker.json",
        "rbxasset://fonts/families/PressStart2P.json",
        "rbxasset://fonts/families/Roboto.json",
        "rbxasset://fonts/families/RobotoCondensed.json",
        "rbxasset://fonts/families/RobotoMono.json",
        "rbxasset://fonts/families/RomanAntique.json",
        "rbxasset://fonts/families/Sarpanch.json",
        "rbxasset://fonts/families/SourceSansPro.json",
        "rbxasset://fonts/families/SpecialElite.json",
        "rbxasset://fonts/families/TitilliumWeb.json",
        "rbxasset://fonts/families/Ubuntu.json",
        "rbxasset://fonts/families/Zekton.json",
    }
    const FamilyToId = {}

    for i, Family in IdToFamily do
        FamilyToId[Family] = i
    end

    @native const function FontSer(Value: Font, Buf: buffer, Cur: number): number
        local Byte = if Value.Style == Italic then 1 else 0
        Byte += bit32.lshift(WeightToId[Value.Weight], 1)
        buffer.writeu8(Buf, Cur, Byte)
        const Family = Value.Family
        const Builtin = FamilyToId[Family]
        if Builtin then
            buffer.writeu8(Buf, Cur + 1, Builtin)
            return Cur + 2
        end

        const Digits = string.match(Family, "%d+")
        if not Digits then
            error("Font family is not a built-in or rbxassetid")
        end
        buffer.writeu8(Buf, Cur + 1, 0)
        return UIntSer(tonumber(Digits) :: number, Buf, Cur + 2)
    end

    @native const function FontDes(Buf: buffer, Cur: number): (Font, number)
        const Byte = buffer.readu8(Buf, Cur)
        const Tag = buffer.readu8(Buf, Cur + 1)
        const Weight = IdToWeight[Byte // 2]
        const Style = if Byte % 2 == 1 then Italic else Normal
        if Tag ~= 0 then
            const Family = IdToFamily[Tag]
            return NewFont(Family, Weight, Style), Cur + 2
        end
        const Id, Next = UIntDes(Buf, Cur + 2)
        return NewFont("rbxassetid://" .. Id, Weight, Style), Next
    end

    FontNode[SER] = FontSer
    FontNode[DES] = FontDes
end

const RayNode: SerdesNode<Ray> = {}
do
    @native const function RaySer(Value: Ray, Buf: buffer, Cur: number): number
        const Origin = Value.Origin
        const Direction = Value.Direction
        buffer.writef32(Buf, Cur, Origin.X)
        buffer.writef32(Buf, Cur + 4, Origin.Y)
        buffer.writef32(Buf, Cur + 8, Origin.Z)
        buffer.writef32(Buf, Cur + 12, Direction.Magnitude)
        return WriteOct16(Direction.X, Direction.Y, Direction.Z, Buf, Cur + 16)
    end

    @native const function RayDes(Buf: buffer, Cur: number): (Ray, number)
        const ox = buffer.readf32(Buf, Cur)
        const oy = buffer.readf32(Buf, Cur + 4)
        const oz = buffer.readf32(Buf, Cur + 8)
        const Magnitude = buffer.readf32(Buf, Cur + 12)
        const dx, dy, dz = ReadOct16(Buf, Cur + 16)
        return NewRay(
            Vector3.new(ox, oy, oz),
            Vector3.new(dx * Magnitude, dy * Magnitude, dz * Magnitude)
        ), Cur + 20
    end

    RayNode[SER] = RaySer
    RayNode[DES] = RayDes
end

const TweenInfoNode: SerdesNode<TweenInfo> = {}
do
    @native const function TweenInfoSer(Value: TweenInfo, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.Time)
        buffer.writef32(Buf, Cur + 4, Value.DelayTime)
        buffer.writei16(Buf, Cur + 8, Value.RepeatCount)
        local Byte = if Value.Reverses then 128 else 0
        Byte = bit32.bor(Byte, bit32.lshift(EasingStyleItemToId[Value.EasingStyle], 2), EasingDirectionItemToId[Value.EasingDirection])
        buffer.writeu8(Buf, Cur + 10, Byte)
        return Cur + 11
    end

    @native const function TweenInfoDes(Buf: buffer, Cur: number): (TweenInfo, number)
        const Time = buffer.readf32(Buf, Cur)
        const DelayTime = buffer.readf32(Buf, Cur + 4)
        const RepeatCount = buffer.readi16(Buf, Cur + 8)
        const Byte = buffer.readu8(Buf, Cur + 10)
        const Reverses = bit32.btest(Byte, 0x80)
        const Style = EasingStyleIdToItem[bit32.rshift(bit32.band(Byte, 0b00111100), 2)]
        const Direction = EasingDirectionIdToItem[bit32.band(Byte, 0b00000011)]
        return NewTweenInfo(Time, Style :: Enum.EasingStyle, Direction :: Enum.EasingDirection, RepeatCount, Reverses, DelayTime), Cur + 11
    end

    TweenInfoNode[SER] = TweenInfoSer
    TweenInfoNode[DES] = TweenInfoDes
end


return {
    Axes = AxesNode,
    Faces = FacesNode,
    DateTime = DateTimeNode,
    DateTimeF32 = DateTimeF32,
    DateTimeInt = DateTimeInt,
    FloatCurveKey = FloatCurveKeyNode,
    PhysicalProperties = PhysicalPropertiesNode,
    RaycastResult = RaycastResultNode,
    RaycastResult8 = RaycastResult8,
    NumberSequenceKeypoint = NumberSequenceKeypointNode,
    NumberSequence = NumberSequenceNode,
    NumberRange = NumberRangeNode,
    NumberRangeF32 = NumberRangeF32,
    Font = FontNode,
    Ray = RayNode,
    TweenInfo = TweenInfoNode
}
