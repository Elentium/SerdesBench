--!optimize 2
const SER = 1
const DES = 2

const Definitions = require("./Definitions")

type SerdesNode<T> = Definitions.SerdesNode<T>

const String: SerdesNode<string> = {}

do
	@native const function StringSer(Value: string, Buf: buffer, Cur: number): number
        const Len = #Value
        buffer.writeu16(Buf, Cur, Len)
        Cur += 2
		buffer.writestring(Buf, Cur, Value)
        return Cur + Len
	end

	@native const function StringDes(Buf: buffer, Cur: number): (string, number)
		const Len = buffer.readu16(Buf, Cur)
        Cur += 2
        const Value = buffer.readstring(Buf, Cur, Len)
		return Value, Cur + Len
	end

	String[SER] = StringSer
	String[DES] = StringDes
end

const String8: SerdesNode<string> = {}

do
	@native const function String8Ser(Value: string, Buf: buffer, Cur: number): number
        const Len = #Value
        buffer.writeu8(Buf, Cur, Len)
        Cur += 1
		buffer.writestring(Buf, Cur, Value)
        return Cur + Len
	end

	@native const function String8Des(Buf: buffer, Cur: number): (string, number)
		const Len = buffer.readu8(Buf, Cur)
        Cur += 1
        const Value = buffer.readstring(Buf, Cur, Len)
		return Value, Cur + Len
	end

	String8[SER] = String8Ser
	String8[DES] = String8Des
end

const String24: SerdesNode<string> = {}

do
	@native const function String24Ser(Value: string, Buf: buffer, Cur: number): number
        const Len = #Value
        buffer.writeu16(Buf, Cur, Len)
        buffer.writeu8(Buf, Cur + 2, bit32.rshift(Len, 16))
        Cur += 3
		buffer.writestring(Buf, Cur, Value)
        return Cur + Len
	end

	@native const function String24Des(Buf: buffer, Cur: number): (string, number)
		const Len = buffer.readu16(Buf, Cur) + buffer.readu8(Buf, Cur + 2) * 65536
        Cur += 3
        const Value = buffer.readstring(Buf, Cur, Len)
		return Value, Cur + Len
	end

	String24[SER] = String24Ser
	String24[DES] = String24Des
end

const String32: SerdesNode<string> = {}

do
	@native const function String32Ser(Value: string, Buf: buffer, Cur: number): number
        const Len = #Value
        buffer.writeu32(Buf, Cur, Len)
        Cur += 4
		buffer.writestring(Buf, Cur, Value)
        return Cur + Len
	end

	@native const function String32Des(Buf: buffer, Cur: number): (string, number)
		const Len = buffer.readu32(Buf, Cur)
        Cur += 4
        const Value = buffer.readstring(Buf, Cur, Len)
		return Value, Cur + Len
	end

	String32[SER] = String32Ser
	String32[DES] = String32Des
end

const function StringFixed(Length: number): SerdesNode<string>
    const StringFixedNode: SerdesNode<string> = {}

    @native const function StringFixedSer(Value: string, Buf: buffer, Cur: number): number
		buffer.writestring(Buf, Cur, Value)
		return Cur + Length
    end

	@native const function StringFixedDes(Buf: buffer, Cur: number): (string, number)
        const Length = Length
        const Value = buffer.readstring(Buf, Cur, Length)
		return Value, Cur + Length
	end

	StringFixedNode[SER] = StringFixedSer
	StringFixedNode[DES] = StringFixedDes

    return StringFixedNode
end

return {
    String = String,
    String8 = String8,
    String24 = String24,
    String32 = String32,
    StringFixed = StringFixed
}