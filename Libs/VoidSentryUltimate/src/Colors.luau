--!optimize 2
const Definitions = require("./Definitions")

type SerdesNode<T> = Definitions.SerdesNode<T>

const SER = 1
const DES = 2

const NewColor3 = Color3.fromRGB
const NewBrickColor = BrickColor.new
const NewColorSequenceKeypoint = ColorSequenceKeypoint.new
const CreateTable = table.create
const NewColorSequence = ColorSequence.new

const BrickColorIds = CreateTable<<number>>(200)
local Count = 0
for i = 1, 1032 do
	const Color = NewBrickColor(i)
	if Color.Number == i or i == 194 then 
        Count += 1
		BrickColorIds[Count] = i
	end
end
table.sort(BrickColorIds)

local IdToByte = {}
local ByteToId = {}

for Byte, Id in BrickColorIds do
	IdToByte[Id] = Byte
	ByteToId[Byte] = Id
end

const Color3Node: SerdesNode<Color3> = {}
do
    @native const function Color3Ser(Value: Color3, Buf: buffer, Cur: number): number
        buffer.writeu16(Buf, Cur, Value.R * 255 + Value.G * 65280)
        buffer.writeu8(Buf, Cur + 2, Value.B * 255)
        return Cur + 3
    end

    @native const function Color3Des(Buf: buffer, Cur: number): (Color3, number)
        const r = buffer.readu8(Buf, Cur)
        const g = buffer.readu8(Buf, Cur + 1)
        const b = buffer.readu8(Buf, Cur + 2)
        return NewColor3(r, g, b), Cur + 3
    end

    Color3Node[SER] = Color3Ser
    Color3Node[DES] = Color3Des
end

const Color3Round: SerdesNode<Color3> = {}
do
    @native const function Color3RoundSer(Value: Color3, Buf: buffer, Cur: number): number
        buffer.writeu16(Buf, Cur, math.round(Value.R * 255) + math.round(Value.G * 65280))
        buffer.writeu8(Buf, Cur + 2, math.round(Value.B * 255))
        return Cur + 3
    end

    @native const function Color3RoundDes(Buf: buffer, Cur: number): (Color3, number)
        const r = buffer.readu8(Buf, Cur)
        const g = buffer.readu8(Buf, Cur + 1)
        const b = buffer.readu8(Buf, Cur + 2)
        return NewColor3(r, g, b), Cur + 3
    end

    Color3Round[SER] = Color3RoundSer
    Color3Round[DES] = Color3RoundDes
end

const BrickColor: SerdesNode<BrickColor> = {}
do
    @native const function BrickColorSer(Value: BrickColor, Buf: buffer, Cur: number): number
        buffer.writeu8(Buf, Cur, IdToByte[Value.Number])
        return Cur + 1
    end

    @native const function BrickColorDes(Buf: buffer, Cur: number): (BrickColor, number)
        const Byte = buffer.readu8(Buf, Cur)
        return NewBrickColor(ByteToId[Byte]), Cur + 1
    end

    BrickColor[SER] = BrickColorSer
    BrickColor[DES] = BrickColorDes
end

const ColorSequenceKeypointNode: SerdesNode<ColorSequenceKeypoint> = {}
do
    @native const function ColorSequenceKeypointSer(Value: ColorSequenceKeypoint, Buf: buffer, Cur: number): number
        const Time = math.round(Value.Time * 255)
        const ColorValue = Value.Value
        const R = math.round(ColorValue.R * 255)
        const G = math.round(ColorValue.G * 255)
        const B = math.round(ColorValue.B * 255)
        buffer.writeu32(Buf, Cur, Time + R * 256 + G * 65_536 + B * 16_777_216)
        return Cur + 4
    end

    @native const function ColorSequenceKeypointDes(Buf: buffer, Cur: number): (ColorSequenceKeypoint, number)
        const Time = buffer.readu8(Buf, Cur) / 255
        const R = buffer.readu8(Buf, Cur + 1)
        const G = buffer.readu8(Buf, Cur + 2)
        const B = buffer.readu8(Buf, Cur + 3)
        return NewColorSequenceKeypoint(Time, NewColor3(R, G, B)), Cur + 4
    end

    ColorSequenceKeypointNode[SER] = ColorSequenceKeypointSer
    ColorSequenceKeypointNode[DES] = ColorSequenceKeypointDes
end

const ColorSequenceNode: SerdesNode<ColorSequence> = {}
do
    @native const function ColorSequenceSer(Value: ColorSequence, Buf: buffer, Cur: number): number
        const Keypoints = Value.Keypoints
        buffer.writeu8(Buf, Cur, #Keypoints)
        Cur += 1
        for _, Keypoint in Keypoints do
            const Time = math.round(Keypoint.Time * 255)
            const ColorValue = Keypoint.Value
            const R = math.round(ColorValue.R * 255)
            const G = math.round(ColorValue.G * 255)
            const B = math.round(ColorValue.B * 255)
            buffer.writeu32(Buf, Cur, Time + R * 256 + G * 65_536 + B * 16_777_216)
            Cur += 4
        end

        return Cur
    end

    @native const function ColorSequenceDes(Buf: buffer, Cur: number): (ColorSequence, number)
        const Len = buffer.readu8(Buf, Cur)
        Cur += 1
        const Keypoints = CreateTable<<ColorSequenceKeypoint>>(Len)
        const NewColorSequenceKeypoint = NewColorSequenceKeypoint
        for i = 1, Len do
            const Time = buffer.readu8(Buf, Cur) / 255
            const R = buffer.readu8(Buf, Cur + 1)
            const G = buffer.readu8(Buf, Cur + 2)
            const B = buffer.readu8(Buf, Cur + 3)
            Cur += 4

            const Keypoint = NewColorSequenceKeypoint(Time, NewColor3(R, G, B))
            Keypoints[i] = Keypoint
        end
        return NewColorSequence(Keypoints), Cur
    end

    ColorSequenceNode[SER] = ColorSequenceSer
    ColorSequenceNode[DES] = ColorSequenceDes
end

return {
    Color3 = Color3Node,
    Color3Round = Color3Round,
    BrickColor = BrickColor,
    ColorSequenceKeypoint = ColorSequenceKeypointNode,
    ColorSequence = ColorSequenceNode
}