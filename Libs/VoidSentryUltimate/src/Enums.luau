--!optimize 2
const Definitions = require("./Definitions")

type SerdesNode<T> = Definitions.SerdesNode<T>
type GetEnumItem<T> = Definitions.GetEnumItem<T>

const SER = 1
const DES = 2

const EnumMap = Enum:GetEnums()
const NodeCache = {}
const ReverseMap = {} :: { [Enum]: number }

for i, Enum in EnumMap do
    ReverseMap[Enum] = i
end

@native const function EnumNode<T>(EnumType: T & Enum): SerdesNode<GetEnumItem<T>>
    const Cached = NodeCache[EnumType]
    if Cached then
        return Cached
    end

    const Node: SerdesNode<GetEnumItem<T>> = {}

    const IdToItem = EnumType:GetEnumItems()
    const ItemToId: { [EnumItem]: number } = {}
    const EnumCount = #IdToItem

    for Id, Item in IdToItem do
        ItemToId[Item] = Id
    end
    
    @native const function Enum16Ser(Value: EnumItem & GetEnumItem<T>, Buf: buffer, Cur: number): number
        buffer.writeu16(Buf, Cur, ItemToId[Value])
        return Cur + 2
    end

    @native const function Enum16Des(Buf: buffer, Cur: number): (GetEnumItem<T>, number)
        const Value = buffer.readu16(Buf, Cur)
        return IdToItem[Value], Cur + 2
    end

    @native const function Enum8Ser(Value: EnumItem & GetEnumItem<T>, Buf: buffer, Cur: number): number
        buffer.writeu8(Buf, Cur, ItemToId[Value])
        return Cur + 1
    end

    @native const function Enum8Des(Buf: buffer, Cur: number): (GetEnumItem<T>, number)
        const Value = buffer.readu8(Buf, Cur)
        return IdToItem[Value], Cur + 1
    end

    const Use16 = EnumCount > 255
    Node[SER] = if Use16 then Enum16Ser else Enum8Ser
    Node[DES] = if Use16 then Enum16Des else Enum8Des

    NodeCache[EnumType] = Node
    return Node
end

@native const function Enum8<T>(EnumType: T & Enum): SerdesNode<GetEnumItem<T>>
    const Node: SerdesNode<GetEnumItem<T>> = {}
    
    @native const function Enum8Ser(Value: EnumItem & GetEnumItem<T>, Buf: buffer, Cur: number): number
        buffer.writeu8(Buf, Cur, Value.Value)
        return Cur + 1
    end

    @native const function Enum8Des(Buf: buffer, Cur: number): (GetEnumItem<T>, number)
        const Value = buffer.readu8(Buf, Cur)
        return EnumType:FromValue(Value), Cur + 1
    end

    Node[SER] = Enum8Ser
    Node[DES] = Enum8Des
    return Node
end

const EnumObj: SerdesNode<Enum> = {}

do
    @native const function EnumObjSer(Value: Enum, Buf: buffer, Cur: number): number
        buffer.writeu16(Buf, Cur, ReverseMap[Value])
        return Cur + 2
    end

    @native const function EnumObjDes(Buf: buffer, Cur: number): (Enum, number)
        const Value = EnumMap[buffer.readu16(Buf, Cur)]
        return Value, Cur + 2
    end

    EnumObj[SER] = EnumObjSer
    EnumObj[DES] = EnumObjDes
end

return {
    Enum = EnumNode,
    Enum8 = Enum8,
    EnumObj = EnumObj
}