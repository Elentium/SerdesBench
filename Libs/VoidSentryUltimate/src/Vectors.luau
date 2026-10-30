--!optimize 2
const SER = 1
const DES = 2

const Definitions = require("./Definitions")
const Shared = require("./Shared")

const FloatConverter = Shared.FloatConverter
const F16Scale = Shared.F16Scale
const F24Scale = Shared.F24Scale

const Vector2New = Vector2.new

type SerdesNode<T> = Definitions.SerdesNode<T>

const Vector: SerdesNode<Vector3> = {}
do
    @native const function VectorSer(Value: Vector3, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.X)
        buffer.writef32(Buf, Cur + 4, Value.Y)
        buffer.writef32(Buf, Cur + 8, Value.Z)
        return Cur + 12
    end

    @native const function VectorDes(Buf: buffer, Cur: number): (Vector3, number)
        const x = buffer.readf32(Buf, Cur)
        const y = buffer.readf32(Buf, Cur + 4)
        const z = buffer.readf32(Buf, Cur + 8)
        return Vector3.new(x, y, z), Cur + 12
    end

    Vector[SER] = VectorSer
    Vector[DES] = VectorDes
end

const VectorF24: SerdesNode<Vector3> = {}
do
    @native const function VectorF24Ser(Value: Vector3, Buf: buffer, Cur: number): number
        const FloatConverter = FloatConverter
        buffer.writef32(Buf, Cur + 5, Value.Z)
        buffer.writef32(Buf, Cur + 2, Value.Y)
        buffer.writef32(FloatConverter, 0, Value.X)
        buffer.writeu16(Buf, Cur, buffer.readu16(FloatConverter, 1))
        buffer.writeu8(Buf, Cur + 2, buffer.readu8(FloatConverter, 3))
        return Cur + 9
    end

    @native const function VectorF24Des(Buf: buffer, Cur: number): (Vector3, number)
        const Scale = F24Scale
        const Px = bit32.band(buffer.readu32(Buf, Cur), 0xFFFFFF)
        const x = bit32.bor(bit32.band(Px, 0x7FFF), 0x8000) * Scale[bit32.rshift(Px, 15) + 1]
        const Py = bit32.rshift(buffer.readu32(Buf, Cur + 2), 8)
        const y = bit32.bor(bit32.band(Py, 0x7FFF), 0x8000) * Scale[bit32.rshift(Py, 15) + 1]
        const Pz = bit32.rshift(buffer.readu32(Buf, Cur + 5), 8)
        const z = bit32.bor(bit32.band(Pz, 0x7FFF), 0x8000) * Scale[bit32.rshift(Pz, 15) + 1]

        return Vector3.new(x, y, z), Cur + 9
    end

    VectorF24[SER] = VectorF24Ser
    VectorF24[DES] = VectorF24Des
end

const VectorF16: SerdesNode<Vector3> = {}
do
    @native const function VectorF16Ser(Value: Vector3, Buf: buffer, Cur: number): number
        const FloatConverter = FloatConverter

        do
            buffer.writef32(FloatConverter, 0, Value.X)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, Value.Y)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 2, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, Value.Z)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 4, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end

        return Cur + 6
    end

    @native const function VectorF16Des(Buf: buffer, Cur: number): (Vector3, number)
        const Scale = F16Scale
        const Px = buffer.readu16(Buf, Cur)
        const x = bit32.bor(bit32.band(Px, 0x3FF), 0x400) * Scale[bit32.rshift(Px, 10) + 1]
        const Py = buffer.readu16(Buf, Cur + 2)
        const y = bit32.bor(bit32.band(Py, 0x3FF), 0x400) * Scale[bit32.rshift(Py, 10) + 1]
        const Pz = buffer.readu16(Buf, Cur + 4)
        const z = bit32.bor(bit32.band(Pz, 0x3FF), 0x400) * Scale[bit32.rshift(Pz, 10) + 1]

        return Vector3.new(x, y, z), Cur + 6
    end

    VectorF16[SER] = VectorF16Ser
    VectorF16[DES] = VectorF16Des
end

const VectorU16: SerdesNode<Vector3> = {}
do
    @native const function VectorU16Ser(Value: Vector3, Buf: buffer, Cur: number): number
        buffer.writeu16(Buf, Cur, Value.X)
        buffer.writeu16(Buf, Cur + 2, Value.Y)
        buffer.writeu16(Buf, Cur + 4, Value.Z)
        return Cur + 6
    end

    @native const function VectorU16Des(Buf: buffer, Cur: number): (Vector3, number)
        const x = buffer.readu16(Buf, Cur)
        const y = buffer.readu16(Buf, Cur + 2)
        const z = buffer.readu16(Buf, Cur + 4)
        return Vector3.new(x, y, z), Cur + 6
    end

    VectorU16[SER] = VectorU16Ser
    VectorU16[DES] = VectorU16Des
end

const VectorI16: SerdesNode<Vector3> = {}
do
    @native const function VectorI16Ser(Value: Vector3, Buf: buffer, Cur: number): number
        buffer.writei16(Buf, Cur, Value.X)
        buffer.writei16(Buf, Cur + 2, Value.Y)
        buffer.writei16(Buf, Cur + 4, Value.Z)
        return Cur + 6
    end

    @native const function VectorI16Des(Buf: buffer, Cur: number): (Vector3, number)
        const x = buffer.readi16(Buf, Cur)
        const y = buffer.readi16(Buf, Cur + 2)
        const z = buffer.readi16(Buf, Cur + 4)
        return Vector3.new(x, y, z), Cur + 6
    end

    VectorI16[SER] = VectorI16Ser
    VectorI16[DES] = VectorI16Des
end

const VectorU8: SerdesNode<Vector3> = {}
do
    @native const function VectorU8Ser(Value: Vector3, Buf: buffer, Cur: number): number
        buffer.writeu8(Buf, Cur, Value.X)
        buffer.writeu8(Buf, Cur + 1, Value.Y)
        buffer.writeu8(Buf, Cur + 2, Value.Z)
        return Cur + 3
    end

    @native const function VectorU8Des(Buf: buffer, Cur: number): (Vector3, number)
        const x = buffer.readu8(Buf, Cur)
        const y = buffer.readu8(Buf, Cur + 1)
        const z = buffer.readu8(Buf, Cur + 2)
        return Vector3.new(x, y, z), Cur + 3
    end

    VectorU8[SER] = VectorU8Ser
    VectorU8[DES] = VectorU8Des
end

const VectorI8: SerdesNode<Vector3> = {}
do
    @native const function VectorI8Ser(Value: Vector3, Buf: buffer, Cur: number): number
        buffer.writei8(Buf, Cur, Value.X)
        buffer.writei8(Buf, Cur + 1, Value.Y)
        buffer.writei8(Buf, Cur + 2, Value.Z)
        return Cur + 3
    end

    @native const function VectorI8Des(Buf: buffer, Cur: number): (Vector3, number)
        const x = buffer.readi8(Buf, Cur)
        const y = buffer.readi8(Buf, Cur + 1)
        const z = buffer.readi8(Buf, Cur + 2)
        return Vector3.new(x, y, z), Cur + 3
    end

    VectorI8[SER] = VectorI8Ser
    VectorI8[DES] = VectorI8Des
end

const VectorU24: SerdesNode<Vector3> = {}
do
    @native const function VectorU24Ser(Value: Vector3, Buf: buffer, Cur: number): number
        buffer.writeu32(Buf, Cur, Value.X)
        buffer.writeu32(Buf, Cur + 3, Value.Y)
        const z = Value.Z
        buffer.writeu16(Buf, Cur + 6, z)
        buffer.writeu8(Buf, Cur + 8, bit32.rshift(z, 16))
        return Cur + 9
    end

    @native const function VectorU24Des(Buf: buffer, Cur: number): (Vector3, number)
        const x = bit32.band(buffer.readu32(Buf, Cur), 0xFFFFFF)
        const y = bit32.band(buffer.readu32(Buf, Cur + 3), 0xFFFFFF)
        const z = bit32.rshift(buffer.readu32(Buf, Cur + 5), 8)
        return Vector3.new(x, y, z), Cur + 9
    end

    VectorU24[SER] = VectorU24Ser
    VectorU24[DES] = VectorU24Des
end

const VectorI24: SerdesNode<Vector3> = {}
do
    @native const function VectorI24Ser(Value: Vector3, Buf: buffer, Cur: number): number
        buffer.writeu32(Buf, Cur, Value.X)
        buffer.writeu32(Buf, Cur + 3, Value.Y)
        const z = Value.Z
        buffer.writeu16(Buf, Cur + 6, z)
        buffer.writeu8(Buf, Cur + 8, bit32.rshift(z, 16))
        return Cur + 9
    end

    @native const function VectorI24Des(Buf: buffer, Cur: number): (Vector3, number)
        const x = buffer.readu16(Buf, Cur) + buffer.readi8(Buf, Cur + 2) * 65536
        const y = buffer.readi32(Buf, Cur + 2) // 256
        const z = buffer.readi32(Buf, Cur + 5) // 256
        return Vector3.new(x, y, z), Cur + 9
    end

    VectorI24[SER] = VectorI24Ser
    VectorI24[DES] = VectorI24Des
end

const Vector2Node: SerdesNode<Vector2> = {}
do
    @native const function Vector2Ser(Value: Vector2, Buf: buffer, Cur: number): number
        buffer.writef32(Buf, Cur, Value.X)
        buffer.writef32(Buf, Cur + 4, Value.Y)
        return Cur + 8
    end

    @native const function Vector2Des(Buf: buffer, Cur: number): (Vector2, number)
        const x = buffer.readf32(Buf, Cur)
        const y = buffer.readf32(Buf, Cur + 4)
        return Vector2New(x, y), Cur + 8
    end

    Vector2Node[SER] = Vector2Ser
    Vector2Node[DES] = Vector2Des
end

const Vector2F24: SerdesNode<Vector2> = {}
do
    @native const function Vector2F24Ser(Value: Vector2, Buf: buffer, Cur: number): number
        const FloatConverter = FloatConverter
        buffer.writef32(Buf, Cur + 2, Value.Y)
        buffer.writef32(FloatConverter, 0, Value.X)
        buffer.writeu16(Buf, Cur, buffer.readu16(FloatConverter, 1))
        buffer.writeu8(Buf, Cur + 2, buffer.readu8(FloatConverter, 3))
        return Cur + 6
    end

    @native const function Vector2F24Des(Buf: buffer, Cur: number): (Vector2, number)
        const Scale = F24Scale
        const Px = bit32.band(buffer.readu32(Buf, Cur), 0xFFFFFF)
        const x = bit32.bor(bit32.band(Px, 0x7FFF), 0x8000) * Scale[bit32.rshift(Px, 15) + 1]
        const Py = bit32.rshift(buffer.readu32(Buf, Cur + 2), 8)
        const y = bit32.bor(bit32.band(Py, 0x7FFF), 0x8000) * Scale[bit32.rshift(Py, 15) + 1]

        return Vector2New(x, y), Cur + 6
    end

    Vector2F24[SER] = Vector2F24Ser
    Vector2F24[DES] = Vector2F24Des
end

const Vector2F16: SerdesNode<Vector2> = {}
do
    @native const function Vector2F16Ser(Value: Vector2, Buf: buffer, Cur: number): number
        const FloatConverter = FloatConverter
        do
            buffer.writef32(FloatConverter, 0, Value.X)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, Value.Y)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 2, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end

        return Cur + 4
    end

    @native const function Vector2F16Des(Buf: buffer, Cur: number): (Vector2, number)
        const Scale = F16Scale
        const Px = buffer.readu16(Buf, Cur)
        const x = bit32.bor(bit32.band(Px, 0x3FF), 0x400) * Scale[bit32.rshift(Px, 10) + 1]
        const Py = buffer.readu16(Buf, Cur + 2)
        const y = bit32.bor(bit32.band(Py, 0x3FF), 0x400) * Scale[bit32.rshift(Py, 10) + 1]

        return Vector2New(x, y), Cur + 4
    end

    Vector2F16[SER] = Vector2F16Ser
    Vector2F16[DES] = Vector2F16Des
end

const Vector2U16: SerdesNode<Vector2> = {}
do
    @native const function Vector2U16Ser(Value: Vector2, Buf: buffer, Cur: number): number
        buffer.writeu16(Buf, Cur, Value.X)
        buffer.writeu16(Buf, Cur + 2, Value.Y)
        return Cur + 4
    end

    @native const function Vector2U16Des(Buf: buffer, Cur: number): (Vector2, number)
        const x = buffer.readu16(Buf, Cur)
        const y = buffer.readu16(Buf, Cur + 2)
        return Vector2New(x, y), Cur + 4
    end

    Vector2U16[SER] = Vector2U16Ser
    Vector2U16[DES] = Vector2U16Des
end

const Vector2I16: SerdesNode<Vector2> = {}
do
    @native const function Vector2I16Ser(Value: Vector2, Buf: buffer, Cur: number): number
        buffer.writei16(Buf, Cur, Value.X)
        buffer.writei16(Buf, Cur + 2, Value.Y)
        return Cur + 4
    end

    @native const function Vector2I16Des(Buf: buffer, Cur: number): (Vector2, number)
        const x = buffer.readi16(Buf, Cur)
        const y = buffer.readi16(Buf, Cur + 2)
        return Vector2New(x, y), Cur + 4
    end

    Vector2I16[SER] = Vector2I16Ser
    Vector2I16[DES] = Vector2I16Des
end

const Vector2U8: SerdesNode<Vector2> = {}
do
    @native const function Vector2U8Ser(Value: Vector2, Buf: buffer, Cur: number): number
        buffer.writeu8(Buf, Cur, Value.X)
        buffer.writeu8(Buf, Cur + 1, Value.Y)
        return Cur + 2
    end

    @native const function Vector2U8Des(Buf: buffer, Cur: number): (Vector2, number)
        const x = buffer.readu8(Buf, Cur)
        const y = buffer.readu8(Buf, Cur + 1)
        return Vector2New(x, y), Cur + 2
    end

    Vector2U8[SER] = Vector2U8Ser
    Vector2U8[DES] = Vector2U8Des
end

const Vector2I8: SerdesNode<Vector2> = {}
do
    @native const function Vector2I8Ser(Value: Vector2, Buf: buffer, Cur: number): number
        buffer.writei8(Buf, Cur, Value.X)
        buffer.writei8(Buf, Cur + 1, Value.Y)
        return Cur + 2
    end

    @native const function Vector2I8Des(Buf: buffer, Cur: number): (Vector2, number)
        const x = buffer.readi8(Buf, Cur)
        const y = buffer.readi8(Buf, Cur + 1)
        return Vector2New(x, y), Cur + 2
    end

    Vector2I8[SER] = Vector2I8Ser
    Vector2I8[DES] = Vector2I8Des
end

const Vector2U24: SerdesNode<Vector2> = {}
do
    @native const function Vector2U24Ser(Value: Vector2, Buf: buffer, Cur: number): number
        buffer.writeu32(Buf, Cur, Value.X)
        const y = Value.Y
        buffer.writeu16(Buf, Cur + 3, y)
        buffer.writeu8(Buf, Cur + 5, bit32.rshift(y, 16))
        return Cur + 6
    end

    @native const function Vector2U24Des(Buf: buffer, Cur: number): (Vector2, number)
        const x = bit32.band(buffer.readu32(Buf, Cur), 0xFFFFFF)
        const y = bit32.rshift(buffer.readu32(Buf, Cur + 2), 8)
        return Vector2New(x, y), Cur + 6
    end

    Vector2U24[SER] = Vector2U24Ser
    Vector2U24[DES] = Vector2U24Des
end

const Vector2I24: SerdesNode<Vector2> = {}
do
    @native const function Vector2I24Ser(Value: Vector2, Buf: buffer, Cur: number): number
        buffer.writeu32(Buf, Cur, Value.X)
        const y = Value.Y
        buffer.writeu16(Buf, Cur + 3, y)
        buffer.writeu8(Buf, Cur + 5, bit32.rshift(y, 16))
        return Cur + 6
    end

    @native const function Vector2I24Des(Buf: buffer, Cur: number): (Vector2, number)
        const x = buffer.readu16(Buf, Cur) + buffer.readi8(Buf, Cur + 2) * 65536
        const y = buffer.readi32(Buf, Cur + 2) // 256
        return Vector2New(x, y), Cur + 6
    end

    Vector2I24[SER] = Vector2I24Ser
    Vector2I24[DES] = Vector2I24Des
end

return {
    Vector = Vector,
    VectorF24 = VectorF24,
    VectorF16 = VectorF16,
    VectorU24 = VectorU24,
    VectorI24 = VectorI24,
    VectorU16 = VectorU16,
    VectorI16 = VectorI16,
    VectorU8 = VectorU8,
    VectorI8 = VectorI8,

    Vector2 = Vector2Node,
    Vector2F16 = Vector2F16,
    Vector2F24 = Vector2F24,
    Vector2I24 = Vector2I24,
    Vector2I16 = Vector2I16,
    Vector2I8 = Vector2I8,
    Vector2U24 = Vector2U24,
    Vector2U16 = Vector2U16,
    Vector2U8 = Vector2U8
}