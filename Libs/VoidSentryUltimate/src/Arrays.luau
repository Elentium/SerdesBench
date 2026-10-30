--!optimize 2
const Definitions = require("./Definitions")

type SerdesNode<T> = Definitions.SerdesNode<T>
type Ser<T> = Definitions.Ser<T>
type Des<T> = Definitions.Des<T>

const CreateTable = table.create

const SER = 1
const DES = 2

@native const function Array<T>(Node: SerdesNode<T>): SerdesNode<{ T }>
    const ArrayNode: SerdesNode<{ T }> = {}

    const Ser = Node[SER] :: Ser<T>
    const Des = Node[DES] :: Des<T>

    @native const function ArraySer(Array: { T }, Buf: buffer, Cur: number): number
        const Len = #Array
        buffer.writeu16(Buf, Cur, Len)
        Cur += 2
        const Ser = Ser
        for _, Value in Array do
            Cur = Ser(Value, Buf, Cur)
        end
        return Cur
    end

    @native const function ArrayDes(Buf: buffer, Cur: number): ({ T }, number)
        const Len = buffer.readu16(Buf, Cur)
        const Array = CreateTable<<T>>(Len)
        Cur += 2
        const Des = Des
        for i = 1, Len do
            Array[i], Cur = Des(Buf, Cur)
        end
        return Array, Cur
    end

    ArrayNode[SER] = ArraySer
    ArrayNode[DES] = ArrayDes

    return ArrayNode
end

@native const function Array8<T>(Node: SerdesNode<T>): SerdesNode<{ T }>
    const Array8Node: SerdesNode<{ T }> = {}

    const Ser = Node[SER] :: Ser<T>
    const Des = Node[DES] :: Des<T>

    @native const function Array8Ser(Array: { T }, Buf: buffer, Cur: number): number
        const Len = #Array
        buffer.writeu8(Buf, Cur, Len)
        Cur += 1
        const Ser = Ser
        for _, Value in Array do
            Cur = Ser(Value, Buf, Cur)
        end
        return Cur
    end

    @native const function Array8Des(Buf: buffer, Cur: number): ({ T }, number)
        const Len = buffer.readu8(Buf, Cur)
        const Array = CreateTable<<T>>(Len)
        Cur += 1
        const Des = Des
        for i = 1, Len do
            Array[i], Cur = Des(Buf, Cur)
        end
        return Array, Cur
    end

    Array8Node[SER] = Array8Ser
    Array8Node[DES] = Array8Des

    return Array8Node
end

@native const function Array24<T>(Node: SerdesNode<T>): SerdesNode<{ T }>
    const Array24Node: SerdesNode<{ T }> = {}

    const Ser = Node[SER] :: Ser<T>
    const Des = Node[DES] :: Des<T>

    @native const function Array24Ser(Array: { T }, Buf: buffer, Cur: number): number
        const Len = #Array
        buffer.writeu16(Buf, Cur, Len)
        buffer.writeu8(Buf, Cur + 2, bit32.rshift(Len, 16))
        Cur += 3
        const Ser = Ser
        for _, Value in Array do
            Cur = Ser(Value, Buf, Cur)
        end
        return Cur
    end

    @native const function Array24Des(Buf: buffer, Cur: number): ({ T }, number)
        const Len = buffer.readu16(Buf, Cur) + buffer.readu8(Buf, Cur + 2) * 65536
        const Array = CreateTable<<T>>(Len)
        Cur += 3
        const Des = Des
        for i = 1, Len do
            Array[i], Cur = Des(Buf, Cur)
        end
        return Array, Cur
    end

    Array24Node[SER] = Array24Ser
    Array24Node[DES] = Array24Des

    return Array24Node
end

@native const function Array32<T>(Node: SerdesNode<T>): SerdesNode<{ T }>
    const Array32Node: SerdesNode<{ T }> = {}

    const Ser = Node[SER] :: Ser<T>
    const Des = Node[DES] :: Des<T>

    @native const function Array32Ser(Array: { T }, Buf: buffer, Cur: number): number
        const Len = #Array
        buffer.writeu32(Buf, Cur, Len)
        Cur += 4
        const Ser = Ser
        for _, Value in Array do
            Cur = Ser(Value, Buf, Cur)
        end
        return Cur
    end

    @native const function Array32Des(Buf: buffer, Cur: number): ({ T }, number)
        const Len = buffer.readu32(Buf, Cur)
        const Array = CreateTable<<T>>(Len)
        Cur += 4
        const Des = Des
        for i = 1, Len do
            Array[i], Cur = Des(Buf, Cur)
        end
        return Array, Cur
    end

    Array32Node[SER] = Array32Ser
    Array32Node[DES] = Array32Des

    return Array32Node
end

@native const function ArrayFixed<T>(Node: SerdesNode<T>, Length: number): SerdesNode<{ T }>
    const ArrayFixedNode: SerdesNode<{ T }> = {}

    const Ser = Node[SER] :: Ser<T>
    const Des = Node[DES] :: Des<T>

    @native const function ArrayFixedSer(Array: { T }, Buf: buffer, Cur: number): number
        const Ser = Ser
        for _, Value in Array do
            Cur = Ser(Value, Buf, Cur)
        end
        return Cur
    end

    @native const function ArrayFixedDes(Buf: buffer, Cur: number): ({ T }, number)
        const Length = Length
        const Array = CreateTable<<T>>(Length)
        const Des = Des
        for i = 1, Length do
            Array[i], Cur = Des(Buf, Cur)
        end
        return Array, Cur
    end

    ArrayFixedNode[SER] = ArrayFixedSer
    ArrayFixedNode[DES] = ArrayFixedDes

    return ArrayFixedNode
end

return {
    Array = Array,
    Array8 = Array8,
    Array24 = Array24,
    Array32 = Array32,
    ArrayFixed = ArrayFixed
}