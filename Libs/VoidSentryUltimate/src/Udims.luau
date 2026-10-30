--!optimize 2
const Definitions = require("./Definitions")
const Shared = require("./Shared")

const FloatConverter = Shared.FloatConverter
const F24Scale = Shared.F24Scale

type SerdesNode<T> = Definitions.SerdesNode<T>

const SER = 1
const DES = 2

const NewUDim2 = UDim2.new
const FromUDim2Scale = UDim2.fromScale
const FromUDim2Offset = UDim2.fromOffset

const UDim2Node: SerdesNode<UDim2> = {}
do
    @native const function UDim2Ser(Value: UDim2, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.X.Scale)
        buffer.writef32(Buf, Cur + 4, Value.X.Offset)
        buffer.writef32(Buf, Cur + 8, Value.Y.Scale)
        buffer.writef32(Buf, Cur + 12, Value.Y.Offset)
        return Cur + 16
    end

    @native const function UDim2Des(Buf: buffer, Cur: number): (UDim2, number)
        const xScale = buffer.readf32(Buf, Cur)
        const xOffset = buffer.readf32(Buf, Cur + 4)
        const yScale = buffer.readf32(Buf, Cur + 8)
        const yOffset = buffer.readf32(Buf, Cur + 12)
        return NewUDim2(xScale, xOffset, yScale, yOffset), Cur + 16
    end

    UDim2Node[SER] = UDim2Ser
    UDim2Node[DES] = UDim2Des
end

const UDim2Scale: SerdesNode<UDim2> = {}
do
    @native const function UDim2ScaleSer(Value: UDim2, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.X.Scale)
        buffer.writef32(Buf, Cur + 4, Value.Y.Scale)
        return Cur + 8
    end

    @native const function UDim2ScaleDes(Buf: buffer, Cur: number): (UDim2, number)
        const xScale = buffer.readf32(Buf, Cur)
        const yScale = buffer.readf32(Buf, Cur + 4)
        return FromUDim2Scale(xScale, yScale), Cur + 8
    end

    UDim2Scale[SER] = UDim2ScaleSer
    UDim2Scale[DES] = UDim2ScaleDes
end

const UDim2Offset: SerdesNode<UDim2> = {}
do
    @native const function UDim2OffsetSer(Value: UDim2, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.X.Offset)
        buffer.writef32(Buf, Cur + 4, Value.Y.Offset)
        return Cur + 8
    end

    @native const function UDim2OffsetDes(Buf: buffer, Cur: number): (UDim2, number)
        const xOffset = buffer.readf32(Buf, Cur)
        const yOffset = buffer.readf32(Buf, Cur + 4)
        return FromUDim2Offset(xOffset, yOffset), Cur + 8
    end

    UDim2Offset[SER] = UDim2OffsetSer
    UDim2Offset[DES] = UDim2OffsetDes
end

const UDim2OffsetI16: SerdesNode<UDim2> = {}
do
    @native const function UDim2OffsetI16Ser(Value: UDim2, Buf: buffer, Cur: number): number
        buffer.writei16(Buf, Cur, Value.X.Offset)
        buffer.writei16(Buf, Cur + 2, Value.Y.Offset)
        return Cur + 4
    end

    @native const function UDim2OffsetI16Des(Buf: buffer, Cur: number): (UDim2, number)
        const xOffset = buffer.readi16(Buf, Cur)
        const yOffset = buffer.readi16(Buf, Cur + 2)
        return FromUDim2Offset(xOffset, yOffset), Cur + 4
    end

    UDim2OffsetI16[SER] = UDim2OffsetI16Ser
    UDim2OffsetI16[DES] = UDim2OffsetI16Des
end

const UDim2ScaleF24: SerdesNode<UDim2> = {}
do
    @native const function UDim2ScaleF24Ser(Value: UDim2, Buf: buffer, Cur: number): number
        const FloatConverter = FloatConverter
        buffer.writef32(Buf, Cur + 2, Value.Y.Scale)
        buffer.writef32(FloatConverter, 0, Value.X.Scale)
        buffer.writeu16(Buf, Cur, buffer.readu16(FloatConverter, 1))
        buffer.writeu8(Buf, Cur + 2, buffer.readu8(FloatConverter, 3))
        return Cur + 6
    end

    @native const function UDim2ScaleF24Des(Buf: buffer, Cur: number): (UDim2, number)
        const Scale = F24Scale
        const PxScale = bit32.band(buffer.readu32(Buf, Cur), 0xFFFFFF)
        const xScale = bit32.bor(bit32.band(PxScale, 0x7FFF), 0x8000) * Scale[bit32.rshift(PxScale, 15) + 1]
        const PyScale = bit32.rshift(buffer.readu32(Buf, Cur + 2), 8)
        const yScale = bit32.bor(bit32.band(PyScale, 0x7FFF), 0x8000) * Scale[bit32.rshift(PyScale, 15) + 1]
        return FromUDim2Scale(xScale, yScale), Cur + 6
    end

    UDim2ScaleF24[SER] = UDim2ScaleF24Ser
    UDim2ScaleF24[DES] = UDim2ScaleF24Des
end

@native const function UDim2Quant(MinScale: number, MaxScale: number)
    const UDim2QuantNode: SerdesNode<UDim2> = {}
    const QuantizedScaleRange = MaxScale - MinScale
    const QuantizedScale = QuantizedScaleRange / 65535
    const InvQuantizedScale = 65535 / QuantizedScaleRange

    @native const function UDim2QuantSer(Value: UDim2, Buf: buffer, Cur: number): number
        const X, Y = Value.X, Value.Y
        const MinScale = MinScale
        const InvQuantizedScale = InvQuantizedScale
        buffer.writeu16(Buf, Cur, math.round((X.Scale - MinScale) * InvQuantizedScale))
        buffer.writeu16(Buf, Cur + 2, math.round((Y.Scale - MinScale) * InvQuantizedScale))
        return Cur + 4
    end

    @native const function UDim2QuantDes(Buf: buffer, Cur: number): (UDim2, number)
        const MinScale = MinScale
        const QuantizedScale = QuantizedScale
        const X = MinScale + buffer.readu16(Buf, Cur) * QuantizedScale
        const Y = MinScale + buffer.readu16(Buf, Cur + 2) * QuantizedScale
        return FromUDim2Scale(X, Y), Cur + 4
    end

    UDim2QuantNode[SER] = UDim2QuantSer
    UDim2QuantNode[DES] = UDim2QuantDes
    return UDim2QuantNode
end

return {
    UDim2 = UDim2Node,
    UDim2Offset = UDim2Offset,
    UDim2Scale = UDim2Scale,
    UDim2OffsetI16 = UDim2OffsetI16,
    UDim2ScaleF24 = UDim2ScaleF24,
    UDim2Quant = UDim2Quant
}