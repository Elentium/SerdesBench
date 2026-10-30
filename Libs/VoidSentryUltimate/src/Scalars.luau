--!optimize 2
const SER = 1
const DES = 2

const Definitions = require("./Definitions")
const Shared = require("./Shared")

const FloatConverter = Shared.FloatConverter
const F16Scale = Shared.F16Scale
const F24Scale = Shared.F24Scale

type SerdesNode<T> = Definitions.SerdesNode<T>

const F16: SerdesNode<number> = {}
do
    @native const function F16Ser(Value: number, Buf: buffer, Cur: number): number
        const FloatConverter = FloatConverter
        buffer.writef32(FloatConverter, 0, Value)
        const Bits = buffer.readu32(FloatConverter, 0)

        const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
        const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000

        buffer.writeu16(Buf, Cur, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        return Cur + 2
    end

    @native const function F16Deser(Buf: buffer, Cur: number): (number, number)
        const Packed = buffer.readu16(Buf, Cur)
        return bit32.bor(bit32.band(Packed, 0x3FF), 0x400) * F16Scale[bit32.rshift(Packed, 10) + 1], Cur + 2
    end

    F16[SER] = F16Ser
    F16[DES] = F16Deser
end

const F24: SerdesNode<number> = {}
do
    @native const function F24Ser(Value: number, Buf: buffer, Cur: number): number
        const FloatConverter = FloatConverter
        buffer.writef32(FloatConverter, 0, Value)
        buffer.writeu16(Buf, Cur, buffer.readu16(FloatConverter, 1))
        buffer.writeu8(Buf, Cur + 2, buffer.readu8(FloatConverter, 3))
        return Cur + 3
    end

    @native const function F24Deser(Buf: buffer, Cur: number): (number, number)
        const Packed = buffer.readu16(Buf, Cur) + buffer.readu8(Buf, Cur + 2) * 65536
        return bit32.bor(bit32.band(Packed, 0x7FFF), 0x8000) * F24Scale[bit32.rshift(Packed, 15) + 1], Cur + 3
    end

    F24[SER] = F24Ser
    F24[DES] = F24Deser
end

const F32: SerdesNode<number> = {}

do
	@native const function F32Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writef32(Buf, Cur, Value)
		return Cur + 4
	end

	@native const function F32Des(Buf: buffer, Cur: number): (number, number)
		const Value = buffer.readf32(Buf, Cur)
		return Value, Cur + 4
	end

	F32[SER] = F32Ser
	F32[DES] = F32Des
end

const F64: SerdesNode<number> = {}

do
	const function F64Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writef64(Buf, Cur, Value)
		return Cur + 8
	end

	const function F64Des(Buf: buffer, Cur: number): (number, number)
		const Value = buffer.readf64(Buf, Cur)
		return Value, Cur + 8
	end

	F64[SER] = F64Ser
	F64[DES] = F64Des
end

return {
    F16 = F16,
    F24 = F24,
    F32 = F32,
    F64 = F64,
    Number = F32
}