--!optimize 2
const Definitions = require("./Definitions")
const InlineStruct = require("./InlineStruct")

type SerdesNode<T> = Definitions.SerdesNode<T>
type Optional<T> = Definitions.Optional<T>
type GetTypeFromTypeNodes<T> = Definitions.GetTypeFromTypeNodes<T>
type Ser<T> = Definitions.Ser<T>
type Des<T> = Definitions.Des<T>
type Schema<T> = Definitions.Schema<T>

const SER = 1
const DES = 2

const CreateTable = table.create
const SortTable = table.sort

@native const function Struct<T>(Tbl: T & { [string]: SerdesNode<any> }): SerdesNode<GetTypeFromTypeNodes<T>>
    const StructNode: SerdesNode<GetTypeFromTypeNodes<T>> = {}

    const Keys = {}
    local Idx = 0
    for Key in Tbl :: { [string]: SerdesNode<any> } do
        Idx += 1
        Keys[Idx] = Key
    end
    SortTable(Keys)

    const Writes = CreateTable<<Ser<any>>>(Idx)
    const Reads = CreateTable<<Des<any>>>(Idx)

    for i, Key in Keys do
        const Node = Tbl[Key]
        Writes[i] = Node[SER] :: Ser<any>
        Reads[i] = Node[DES] :: Des<any>
    end

    const Node: { [any]: any } = StructNode
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads

    const InlineNode = InlineStruct[Idx]
    if InlineNode then
        return InlineNode(Node)
    end

    @native const function StructSer(Value: GetTypeFromTypeNodes<T> & { [string]: any }, Buf: buffer, Cur: number): number
        const Writes = Writes
        for i, Key in Keys do
            Cur = Writes[i](Value[Key], Buf, Cur)
        end
        return Cur
    end

    @native const function StructDes(Buf: buffer, Cur: number): (GetTypeFromTypeNodes<T>, number)
        const Result = {}
        const Reads = Reads
        for i, Key in Keys do
            Result[Key], Cur = Reads[i](Buf, Cur)
        end
        return Result :: any, Cur
    end

    StructNode[SER] = StructSer
    StructNode[DES] = StructDes

    return StructNode
end

@native const function DeltaStruct<T>(Tbl: T & { [string]: SerdesNode<any> }): SerdesNode<Optional<GetTypeFromTypeNodes<T>> & { [string]: nil }>
    const DeltaStructNode: SerdesNode<Optional<GetTypeFromTypeNodes<T>> & { [string]: nil }> = {}

    const Keys = {}
    local Idx = 0
    for Key in Tbl :: { [string]: SerdesNode<any> } do
        Idx += 1
        Keys[Idx] = Key
    end

    if Idx > 255 then
        error("Schema cannot have more than 255 fields, provided fields: " .. Idx)
    end
    SortTable(Keys)

    const Writes = CreateTable<<Ser<any>>>(Idx)
    const Reads = CreateTable<<Des<any>>>(Idx)
    const Lookup: { [string]: number } = {}

    for i, Key in Keys do
        const Node = Tbl[Key]
        Writes[i] = Node[SER] :: Ser<any>
        Reads[i] = Node[DES] :: Des<any>
        Lookup[Key] = i
    end

    @native const function DeltaStructSer(Value: Optional<GetTypeFromTypeNodes<T>> & { [string]: nil }, Buf: buffer, Cur: number): number
        const Start = Cur
        Cur += 1
        local Len = 0
        const Lookup = Lookup
        const Writes = Writes
        for Key, Field in Value :: { [string]: any } do
            const Id = Lookup[Key]
            Len += 1
            buffer.writeu8(Buf, Cur, Id)
            Cur = Writes[Id](Field, Buf, Cur + 1)
        end
        buffer.writeu8(Buf, Start, Len)
        return Cur
    end

    @native const function DeltaStructDes(Buf: buffer, Cur: number): (Optional<GetTypeFromTypeNodes<T>> & { [string]: nil }, number)
        const Result = {}
        const Len = buffer.readu8(Buf, Cur)
        const Keys = Keys
        const Reads = Reads
        Cur += 1
        for _ = 1, Len do
            const Id = buffer.readu8(Buf, Cur)
            Cur += 1
            const Key = Keys[Id]
            const Read = Reads[Id]

            Result[Key], Cur = Read(Buf, Cur)
        end
        return Result :: any, Cur
    end

    DeltaStructNode[SER] = DeltaStructSer
    DeltaStructNode[DES] = DeltaStructDes;
    DeltaStructNode.Delta = true

    return DeltaStructNode
end

@native const function DeltaStruct16<T>(Tbl: T & { [string]: SerdesNode<any> }): SerdesNode<Optional<GetTypeFromTypeNodes<T>> & { [string]: nil }>
    const DeltaStruct16Node: SerdesNode<Optional<GetTypeFromTypeNodes<T>> & { [string]: nil }> = {}

    const Keys = {}
    local Idx = 0
    for Key in Tbl :: { [string]: SerdesNode<any> } do
        Idx += 1
        Keys[Idx] = Key
    end
    SortTable(Keys)

    const Writes = CreateTable<<Ser<any>>>(Idx)
    const Reads = CreateTable<<Des<any>>>(Idx)
    const Lookup: { [string]: number } = {}

    for i, Key in Keys do
        const Node = Tbl[Key]
        Writes[i] = Node[SER] :: Ser<any>
        Reads[i] = Node[DES] :: Des<any>
        Lookup[Key] = i
    end

    if Idx > 65535 then
        error("Schema cannot have more than 65535 fields, provided fields: " .. Idx)
    end

    @native const function DeltaStruct16Ser(Value: Optional<GetTypeFromTypeNodes<T>> & { [string]: nil }, Buf: buffer, Cur: number): number
        const Start = Cur
        Cur += 2
        local Len = 0
        const Lookup = Lookup
        const Writes = Writes
        for Key, Field in Value :: { [string]: any } do
            const Id = Lookup[Key]
            Len += 1
            buffer.writeu16(Buf, Cur, Id)
            Cur += 2
            Cur = Writes[Id](Field, Buf, Cur)
        end
        buffer.writeu16(Buf, Start, Len)
    
        return Cur
    end

    @native const function DeltaStruct16Des(Buf: buffer, Cur: number): (Optional<GetTypeFromTypeNodes<T>> & { [string]: nil }, number)
        const Result = {}
        const Len = buffer.readu16(Buf, Cur)
        Cur += 2
        const Keys = Keys
        const Reads = Reads
        for _ = 1, Len do
            const Id = buffer.readu16(Buf, Cur)
            Cur += 2
            const Key = Keys[Id]
            const Read = Reads[Id]

            Result[Key], Cur = Read(Buf, Cur)
        end
        return Result :: any, Cur
    end

    DeltaStruct16Node[SER] = DeltaStruct16Ser
    DeltaStruct16Node[DES] = DeltaStruct16Des;
    DeltaStruct16Node.Delta = true

    return DeltaStruct16Node
end

@native const function InheritedStruct(...: SerdesNode<{[string]: any}> | Schema<{[string]: any}> | { [string]: SerdesNode<{[string]: any}> })
    const StructNode: SerdesNode<{ [string]: any }> = {}
    const Keys = {}
    const TempData: { [string]: { Ser: Ser<any>, Des: Des<any> } } = {}
    local KeysCount = 0
    
    for i, Node: { [any]: any } in { ... } do
        if type(Node) ~= "table" then
            error(`Invalid argument #{i}, table expected, got {typeof(Node)}`)
        end

        const IsSerdesNode = type(Node[SER]) == "function" or type(Node.Serialize) == "function"
        if IsSerdesNode then
            if Node.Delta then
                error(`Invalid argument #{i}, delta structs are not supported`)
            end
            const NodeKeys = Node.Keys
            const NodeWrites = Node.Writes
            const NodeReads = Node.Reads
            if not NodeKeys or not NodeWrites or not NodeReads then
                error(`Invalid argument #{i}, Passed Node is not a fitting SerdesNode, the node must be a Struct or a Schema`)
            end
            for i, Key in NodeKeys do
                if TempData[Key] then
                    error(`'{Key}' key collision detected`)
                end
                KeysCount += 1
                Keys[KeysCount] = Key
                TempData[Key] = {
                    Ser = NodeWrites[i],
                    Des = NodeReads[i]
                }
            end
            continue
        end

        for Key, SerdesNode in Node do
            if TempData[Key] then
                error(`'{Key}' key collision detected`)
            end

            KeysCount += 1
            Keys[KeysCount] = Key
            TempData[Key] = { Ser = SerdesNode[SER], Des = SerdesNode[DES] }
        end
    end
    SortTable(Keys)
    const Writes = CreateTable<<Ser<any>>>(KeysCount)
    const Reads = CreateTable<<Des<any>>>(KeysCount)
    for i, Key in Keys do
        const Data = TempData[Key]
        Writes[i] = Data.Ser
        Reads[i] = Data.Des
    end
    StructNode.Keys = Keys
    StructNode.Writes = Writes
    StructNode.Reads = Reads

    const InlineNode = InlineStruct[KeysCount]
    if InlineNode then
        return InlineNode(StructNode :: any)
    end

    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        const Writes = Writes
        for i, Key in Keys do
            Cur = Writes[i](Value[Key], Buf, Cur)
        end
        return Cur
    end

    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const Result = {}
        const Reads = Reads
        for i, Key in Keys do
            Result[Key], Cur = Reads[i](Buf, Cur)
        end
        return Result :: any, Cur
    end

    StructNode[SER] = StructSer
    StructNode[DES] = StructDes

    return StructNode
end

return {
    Struct = Struct,
    DeltaStruct = DeltaStruct,
    DeltaStruct16 = DeltaStruct16,
    InheritedStruct = InheritedStruct
}