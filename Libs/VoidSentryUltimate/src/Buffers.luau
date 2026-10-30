--!optimize 2
const Definitions = require("./Definitions")

type SerdesNode<T> = Definitions.SerdesNode<T>

const SER = 1
const DES = 2

const CopyBuffer = buffer.copy
const BufferLen = buffer.len
const CreateBuffer = buffer.create

const Buffer: SerdesNode<buffer> = {}
do
    @native const function BufferSer(Value: buffer, Buf: buffer, Cur: number): number
        const Len = BufferLen(Value)
        buffer.writeu16(Buf, Cur, Len)
        Cur += 2
        CopyBuffer(Buf, Cur, Value, 0, Len)
        return Cur + Len
    end

    @native const function BufferDes(Buf: buffer, Cur: number): (buffer, number)
        const Length = buffer.readu16(Buf, Cur)
        Cur += 2
        const Value = CreateBuffer(Length)
        CopyBuffer(Value, 0, Buf, Cur, Length)
        return Value, Cur + Length
    end

    Buffer[SER] = BufferSer
    Buffer[DES] = BufferDes
end

const Buffer8: SerdesNode<buffer> = {}
do
    @native const function Buffer8Ser(Value: buffer, Buf: buffer, Cur: number): number
        const Len = BufferLen(Value)
        buffer.writeu8(Buf, Cur, Len)
        Cur += 1
        CopyBuffer(Buf, Cur, Value, 0, Len)
        return Cur + Len
    end

    @native const function Buffer8Des(Buf: buffer, Cur: number): (buffer, number)
        const Length = buffer.readu8(Buf, Cur)
        Cur += 1
        const Value = CreateBuffer(Length)
        CopyBuffer(Value, 0, Buf, Cur, Length)
        return Value, Cur + Length
    end

    Buffer8[SER] = Buffer8Ser
    Buffer8[DES] = Buffer8Des
end

const Buffer32: SerdesNode<buffer> = {}
do
    @native const function Buffer32Ser(Value: buffer, Buf: buffer, Cur: number): number
        const Len = BufferLen(Value)
        buffer.writeu32(Buf, Cur, Len)
        Cur += 4
        CopyBuffer(Buf, Cur, Value, 0, Len)
        return Cur + Len
    end

    @native const function Buffer32Des(Buf: buffer, Cur: number): (buffer, number)
        const Length = buffer.readu32(Buf, Cur)
        Cur += 4
        const Value = CreateBuffer(Length)
        CopyBuffer(Value, 0, Buf, Cur, Length)
        return Value, Cur + Length
    end

    Buffer32[SER] = Buffer32Ser
    Buffer32[DES] = Buffer32Des
end

const Buffer24: SerdesNode<buffer> = {}
do
    @native const function Buffer24Ser(Value: buffer, Buf: buffer, Cur: number): number
        const Len = BufferLen(Value)
        buffer.writeu16(Buf, Cur, Len)
        buffer.writeu8(Buf, Cur + 2, bit32.rshift(Len, 16))
        Cur += 3
        CopyBuffer(Buf, Cur, Value, 0, Len)
        return Cur + Len
    end

    @native const function Buffer24Des(Buf: buffer, Cur: number): (buffer, number)
        const Length = buffer.readu16(Buf, Cur) + buffer.readu8(Buf, Cur + 2) * 65536
        const Value = CreateBuffer(Length)
        Cur += 3
        CopyBuffer(Value, 0, Buf, Cur, Length)
        return Value, Cur + Length
    end

    Buffer24[SER] = Buffer24Ser
    Buffer24[DES] = Buffer24Des
end

@native const function BufferFixed(Length: number): SerdesNode<buffer>
    const BufferFixedNode: SerdesNode<buffer> = {}

    @native const function BufferFixedSer(Value: buffer, Buf: buffer, Cur: number): number
        CopyBuffer(Buf, Cur, Value, 0, Length)
        Cur +=Length
        return Cur
    end

    @native const function BufferFixedDes(Buf: buffer, Cur: number): (buffer, number)
        const Value = CreateBuffer(Length)
        CopyBuffer(Value, 0, Buf, Cur, Length)
        return Value, Cur + Length
    end

    BufferFixedNode[SER] = BufferFixedSer
    BufferFixedNode[DES] = BufferFixedDes

    return BufferFixedNode
end

return {
    Buffer = Buffer,
    Buffer8 = Buffer8,
    Buffer24 = Buffer24,
    Buffer32 = Buffer32,
    BufferFixed = BufferFixed
}