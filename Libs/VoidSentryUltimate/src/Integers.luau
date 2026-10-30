--!optimize 2
const Definitions = require("./Definitions")

type SerdesNode<T> = Definitions.SerdesNode<T>

const SER = 1
const DES = 2

const I8: SerdesNode<number> = {}

do
	@native const function I8Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writei8(Buf, Cur, Value)
		return Cur + 1
	end

	@native const function I8Des(Buf: buffer, Cur: number): (number, number)
		const Value = buffer.readi8(Buf, Cur)
		return Value, Cur + 1
	end

	I8[SER] = I8Ser
	I8[DES] = I8Des
end

const U8: SerdesNode<number> = {}

do
	@native const function U8Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writeu8(Buf, Cur, Value)
		return Cur + 1
	end

	@native const function U8Des(Buf: buffer, Cur: number): (number, number)
		const Value = buffer.readu8(Buf, Cur)
		return Value, Cur + 1
	end

	U8[SER] = U8Ser
	U8[DES] = U8Des
end

const U16: SerdesNode<number> = {}

do
	@native const function U16Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writeu16(Buf, Cur, Value)
		return Cur + 2
	end

	@native const function U16Des(Buf: buffer, Cur: number): (number, number)
		const Value = buffer.readu16(Buf, Cur)
		return Value, Cur + 2
	end

	U16[SER] = U16Ser
	U16[DES] = U16Des
end

const I16: SerdesNode<number> = {}

do
	@native const function I16Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writei16(Buf, Cur, Value)
		return Cur + 2
	end

	@native const function I16Des(Buf: buffer, Cur: number): (number, number)
		const Value = buffer.readi16(Buf, Cur)
		return Value, Cur + 2
	end

	I16[SER] = I16Ser
	I16[DES] = I16Des
end

const U24: SerdesNode<number> = {}
do
    @native const function U24Ser(Value: number, Buf: buffer, Cur: number): number
        buffer.writeu16(Buf, Cur, Value)
        buffer.writeu8(Buf, Cur + 2, bit32.rshift(Value, 16))
        return Cur + 3
    end

    @native const function U24Deser(Buf: buffer, Cur: number): (number, number)
        return buffer.readu16(Buf, Cur) + buffer.readu8(Buf, Cur + 2) * 65536, Cur + 3
    end

    U24[SER] = U24Ser
    U24[DES] = U24Deser
end

const I24: SerdesNode<number> = {}
do
    @native const function I24Ser(Value: number, Buf: buffer, Cur: number): number
        -- exactly the same as U24
        buffer.writeu16(Buf, Cur, Value)
        buffer.writeu8(Buf, Cur + 2, bit32.rshift(Value, 16))
        return Cur + 3
    end

    @native const function I24Deser(Buf: buffer, Cur: number): (number, number)
        return buffer.readu16(Buf, Cur) + buffer.readi8(Buf, Cur + 2) * 65536, Cur + 3
    end

    I24[SER] = I24Ser
    I24[DES] = I24Deser
end

const U32: SerdesNode<number> = {}

do
	@native const function U32Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writeu32(Buf, Cur, Value)
		return Cur + 4
	end

	@native const function U32Des(Buf: buffer, Cur: number): (number, number)
		const Value = buffer.readu32(Buf, Cur)
		return Value, Cur + 4
	end

	U32[SER] = U32Ser
	U32[DES] = U32Des
end

const I32: SerdesNode<number> = {}

do
	@native const function I32Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writei32(Buf, Cur, Value)
		return Cur + 4
	end

	@native const function I32Des(Buf: buffer, Cur: number): (number, number)
		const Value = buffer.readi32(Buf, Cur)
		return Value, Cur + 4
	end

	I32[SER] = I32Ser
	I32[DES] = I32Des
end

const I40: SerdesNode<number> = {}

do
	@native const function I40Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writeu32(Buf, Cur, Value)
        buffer.writeu8(Buf, Cur + 4, Value // 0x100000000)
		return Cur + 5
	end

	@native const function I40Des(Buf: buffer, Cur: number): (number, number)
		return buffer.readu32(Buf, Cur) + buffer.readi8(Buf, Cur + 4) * 0x100000000, Cur + 5
	end

	I40[SER] = I40Ser
	I40[DES] = I40Des
end

const U40: SerdesNode<number> = {}

do
	@native const function U40Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writeu32(Buf, Cur, Value)
        buffer.writeu8(Buf, Cur + 4, Value // 0x100000000)
		return Cur + 5
	end

	@native const function U40Des(Buf: buffer, Cur: number): (number, number)
		const Low = buffer.readu32(Buf, Cur)
        const High = buffer.readu8(Buf, Cur + 4)
	    const Value = Low + High * 0x100000000
		return Value, Cur + 5
	end

	U40[SER] = U40Ser
	U40[DES] = U40Des
end

const I48: SerdesNode<number> = {}

do
	@native const function I48Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writeu32(Buf, Cur, Value)
        buffer.writeu16(Buf, Cur + 4, Value // 0x100000000)
		return Cur + 6
	end

	@native const function I48Des(Buf: buffer, Cur: number): (number, number)
		return buffer.readu32(Buf, Cur) + buffer.readi16(Buf, Cur + 4) * 0x100000000, Cur + 6
	end

    I48[SER] = I48Ser
	I48[DES] = I48Des
end

const U48: SerdesNode<number> = {}

do
	@native const function U48Ser(Value: number, Buf: buffer, Cur: number): number
		buffer.writeu32(Buf, Cur, Value)
        buffer.writeu16(Buf, Cur + 4, Value // 0x100000000)
		return Cur + 6
	end

	@native const function U48Des(Buf: buffer, Cur: number): (number, number)
		const Low = buffer.readu32(Buf, Cur)
        const High = buffer.readu16(Buf, Cur + 4)
	    const Value = Low + High * 0x100000000
		return Value, Cur + 6
	end

    U48[SER] = U48Ser
	U48[DES] = U48Des
end

const UInt: SerdesNode<number> = {}
do
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

    UInt[SER] = UIntSer
    UInt[DES] = UIntDes
end

const Int: SerdesNode<number> = {}
do
    @native const function IntSer(Value: number, Buf: buffer, Cur: number): number
        Value = if Value < 0 then -2 * Value - 1 else 2 * Value

        if Value < 0x80 then
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

    @native const function IntDes(Buf: buffer, Cur: number): (number, number)
        local Byte = buffer.readu8(Buf, Cur)
        local Value = Byte
        local Next = Cur + 1

        repeat
            if Byte < 0x80 then
                break
            end

            Byte = buffer.readu8(Buf, Cur + 1)
            Value += Byte * 0x80
            if Byte < 0x80 then
                Value -= 0x80
                Next = Cur + 2
                break
            end

            Byte = buffer.readu8(Buf, Cur + 2)
            Value += Byte * 0x4000
            if Byte < 0x80 then
                Value -= 0x4080
                Next = Cur + 3
                break
            end

            Byte = buffer.readu8(Buf, Cur + 3)
            Value += Byte * 0x200000
            if Byte < 0x80 then
                Value -= 0x204080
                Next = Cur + 4
                break
            end

            Byte = buffer.readu8(Buf, Cur + 4)
            Value += Byte * 0x10000000
            if Byte < 0x80 then
                Value -= 0x10204080
                Next = Cur + 5
                break
            end

            Byte = buffer.readu8(Buf, Cur + 5)
            Value += Byte * 0x800000000
            if Byte < 0x80 then
                Value -= 0x810204080
                Next = Cur + 6
                break
            end

            Byte = buffer.readu8(Buf, Cur + 6)
            Value += Byte * 0x40000000000
            if Byte < 0x80 then
                Value -= 0x40810204080
                Next = Cur + 7
                break
            end

            Value = Value - 0x2040810204080 + buffer.readu8(Buf, Cur + 7) * 0x2000000000000
            Next = Cur + 8
        until true

        return if not bit32.btest(Value, 1) then Value * 0.5 else (Value + 1) * -0.5, Next
    end

    Int[SER] = IntSer
    Int[DES] = IntDes
end

return {
    I8 = I8,
    U8 = U8,
    I16 = I16,
    U16 = U16,
    U24 = U24,
    I24 = I24,
    I32 = I32,
    U32 = U32,
    I40 = I40,
    U40 = U40,
    I48 = I48,
    U48 = U48,
    Int = Int,
    UInt = UInt
}