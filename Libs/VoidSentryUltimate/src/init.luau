--!optimize 2
--[[
    VoidSentryUltimate 
    [ V1.2.0 ]
    [ by IAMNOTULTRA3 a.k.a Elentium, Elite ]
    [ Apache-2.0 License ]

    Wally: "elentium/voidsentryultimate@1.2.0"
    Pesde: pesde add elentium/voidsentryultimate
    Npm(rbxts): npm install @elentium/voidsentryultimate
    Docs: https://Elentium.github.io/VoidSentryUltimate
]]

--- Schematized SerDes library for Roblox.
---
--- @class VoidSentryUltimate
---------------------------------------------------------
-- CONSTANTS
---------------------------------------------------------
const SER = 1 -- index of Ser function
const DES = 2 -- index of Des function
const BIG_BUFFER_SIZE = 1_000_000 -- size of big scratch buffer (this also means the max serialize bytes)
const INSTANCE_ATTRIBUTE_NAME = "_VSID" -- attribute that is assigned to each instance and stores unique id
const INSTANCE_SERIALIZATION_ENABLED = true -- if true, assigns attribute `INSTANCE_ATTRIBUTE_NAME` to every instance and fills the map, if false, skips this work

---------------------------------------------------------
-- SERVICES
---------------------------------------------------------
const RunService = game:GetService("RunService")

---------------------------------------------------------
-- MODULE
---------------------------------------------------------
const VoidSentryUltimate = {}
const Types = {}
VoidSentryUltimate.Types = Types

---------------------------------------------------------
-- REQUIRES
---------------------------------------------------------
const Arrays = require("@self/Arrays")
const Booleans = require("@self/Booleans")
const Buffers = require("@self/Buffers")
const CFrames = require("@self/CFrames")
const Colors = require("@self/Colors")
const Definitions = require("@self/Definitions")
const Enums = require("@self/Enums")
const InstanceMaps = require("@self/InstanceMaps")
const Instances = require("@self/Instances")
const Integers = require("@self/Integers")
const Maps = require("@self/Maps")
const Scalars = require("@self/Scalars")
const Special = require("@self/Special")
const Strings = require("@self/Strings")
const Structs = require("@self/Structs")
const Udims = require("@self/Udims")
const Vectors = require("@self/Vectors")
const RobloxExtra = require("@self/RobloxExtra")
const InlineSchema = require("@self/InlineSchema")

---------------------------------------------------------
-- VARIABLES
---------------------------------------------------------
const CreateBuffer = buffer.create
const CopyBuffer = buffer.copy
const XPcall = xpcall
const CreateTable = table.create
const Pcall = pcall
const TaskSpawn = task.spawn
const CoroutineRunning = coroutine.running
const CoroutineYield = coroutine.yield
const TaskDelay = task.delay
const SortTable = table.sort

const IdMap = InstanceMaps.IdMap
const InstanceMap = InstanceMaps.ReverseMap

local WriteBuffer = CreateBuffer(BIG_BUFFER_SIZE)
const SetWBuf = InlineSchema.SetWriteBuffer

---------------------------------------------------------
-- TYPES
---------------------------------------------------------
export type Instances = Definitions.Instances
export type Ser<T> = Definitions.Ser<T>
export type Des<T> = Definitions.Des<T>
export type SerdesNode<T> = Definitions.SerdesNode<T>
export type Schema<T> = Definitions.Schema<T>
export type Lib = Definitions.Lib
export type GetTypeFromTypeNodes<T> = Definitions.GetTypeFromTypeNodes<T>
export type GetTypeFromTypeNode<T> = Definitions.GetTypeFromTypeNode<T>
export type Optional<T> = Definitions.Optional<T>

---------------------------------------------------------
-- API
---------------------------------------------------------

--- Serializes a value according to a schema and returns an exactly sized buffer.
---
--- Values are not validated. The caller must provide data that matches the
--- schema and the selected node's range.
--- @tag Core
--- @param Node SerdesNode<T> -- Schema that defines the wire representation.
--- @param Data T -- Value to serialize.
--- @return buffer
@native function VoidSentryUltimate.Serialize<T>(Node: SerdesNode<any> & T, Data: GetTypeFromTypeNode<T>): buffer
	const Ser = Node[SER] :: Ser<GetTypeFromTypeNode<T>>
    const WriteBuffer = WriteBuffer
	const Cur = Ser(Data, WriteBuffer, 0)
	const Buf = CreateBuffer(Cur)
	CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
	return Buf
end

--- Serializes a value into a new buffer after a zero-filled prefix.
---
--- The returned buffer has `Offset` bytes before the payload. Use this when a
--- caller will fill a packet header separately.
--- @tag Core
--- @param Node SerdesNode<T> -- Schema that defines the wire representation.
--- @param Data T -- Value to serialize.
--- @param Offset number -- Number of bytes reserved before the payload.
--- @return buffer
@native function VoidSentryUltimate.SerializeWithOffset<T>(Node: SerdesNode<any> & T, Data: GetTypeFromTypeNode<T>, Offset: number): buffer
	const Ser = Node[SER] :: Ser<GetTypeFromTypeNode<T>>
    const WriteBuffer = WriteBuffer
	const Cur = Ser(Data, WriteBuffer, 0)
	const Buf = CreateBuffer(Cur + Offset)
	CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
	return Buf
end

const SerializeUnsafe = VoidSentryUltimate.SerializeWithOffset

--- Serializes a value according to a schema and returns an exactly sized buffer. If error, it safely returns nil and detailed error message
---
--- @tag Core
--- @param Node SerdesNode<T> -- Schema that defines the wire representation.
--- @param Data T -- Value to serialize.
--- @param Offset number? -- Optional number of bytes reserved before the payload
--- @return buffer
@native function VoidSentryUltimate.SerializeSafe<T>(Node: SerdesNode<any> & T, Data: GetTypeFromTypeNode<T>, Offset: number?): (buffer?, string?)
    Offset = Offset or 0
    const Success, Result = XPcall(SerializeUnsafe :: (SerdesNode<any>, any, number?) -> buffer, function(Err: string)
        return `Failed to Serialize Type: {debug.info(3, "n"):gsub("Ser", "")}, Error: {Err}`
    end, Node, Data, Offset)
    if not Success then
        return nil, Result :: any
    end

    return Result, nil
end

--- Deserializes a buffer from byte zero using the supplied schema.
---
--- The schema must match the schema and node choices used by the writer.
--- @tag Core
--- @param Schema SerdesNode<T> -- Schema that defines the wire representation.
--- @param Buffer buffer -- Buffer containing the encoded value.
--- @return T, number (cursor)
@native function VoidSentryUltimate.Deserialize<T>(Schema: SerdesNode<T>, Buffer: buffer): (T, number)
	const Des = Schema[DES] :: Des<T>
	return Des(Buffer, 0)
end

--- Writes a serialized value directly into an existing buffer.
---
--- The destination must already be large enough. `Offset` defaults to zero.
--- Returns the byte offset after the written payload.
--- @tag Core
--- @param Node SerdesNode<T> -- Schema that defines the wire representation.
--- @param Data T -- Value to serialize.
--- @param Buffer buffer -- Existing destination buffer.
--- @param Offset number? -- Byte offset at which writing begins. Defaults to 0.
--- @return number (cursor)
@native function VoidSentryUltimate.Push<T>(Node: SerdesNode<any> & T, Data: GetTypeFromTypeNode<T>, Buffer: buffer, Offset: number?): number
    const Ser = Node[SER] :: Ser<GetTypeFromTypeNode<T>>
    return Ser(Data, Buffer, Offset or 0)
end

--- Deserializes a value beginning at a byte offset in a buffer.
--- @tag Core
--- @param Schema SerdesNode<T> -- Schema that defines the wire representation.
--- @param Buffer buffer -- Buffer containing the encoded value.
--- @param Offset number -- Byte offset at which reading begins.
--- @return T, number (cursor)
@native function VoidSentryUltimate.DeserializeWithOffset<T>(Schema: SerdesNode<T>, Buffer: buffer, Offset: number): (T, number)
	const Des = Schema[DES] :: Des<T>
	return Des(Buffer, Offset)
end

--- Migrates the old serialized buffer based on the new provided SerdesNode.
---
--- Mainly designed for Struct types (but might sometimes work with other types).
--- @tag Core
--- @param Old SerdesNode<T> -- Old SerdesNode which was used to serialize the old buffer.
--- @param New SerdesNode<T> -- New SerdesNode which will be used to re-serialize the old buffer.
--- @param OldBuf buffer -- Buffer previously serialized with `Old`.
--- @param OldOffset number? -- Optional offset if old buffer was serialized with offset.
--- @param NewOffset number? -- Optional offset for the new buffer.
--- @return buffer
@native function VoidSentryUltimate.Migrate<T>(Old: SerdesNode<T>, New: SerdesNode<T>, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
    const OldDes = Old[DES] :: Des<T>
    const NewSer = New[SER] :: Ser<T>

    const Data = OldDes(OldBuf, OldOffset or 0)

    const WriteBuffer = WriteBuffer
    const Prefix = NewOffset or 0
    const Cur = NewSer(Data, WriteBuffer, 0)

    const Buf = CreateBuffer(Cur + Prefix)
    CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
    return Buf
end

--- Creates a schema object from a map of field names to type nodes.
---
--- Field names are collected and sorted lexicographically. The returned object
--- exposes full-struct and delta helpers. Maximum 255 fields.
--- @within VoidSentryUltimate
--- @tag Core
--- @param Tbl T -- Map of field name to `SerdesNode`.
--- @return Schema
@native function VoidSentryUltimate.Schema<T>(Tbl: { [string]: SerdesNode<any> } & T): Schema<GetTypeFromTypeNodes<T>>
    const Object = {}

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
    const KeyIndex: { [string]: number } = {}

    for i, Key in Keys do
        const Node = Tbl[Key]
        const Ser, Des = Node[SER] :: Ser<any>, Node[DES] :: Des<any>
        Writes[i] = Ser
        Reads[i] = Des
        KeyIndex[Key] = i
    end

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads

    const InlineNode = InlineSchema[Idx]
    if InlineNode then
        return InlineNode(Object)
    end

    @native function Object.Serialize(Data: { [string]: any } & GetTypeFromTypeNodes<T>): buffer
        local Cur = 0
        const Writes = Writes
        const Keys = Keys
        const WriteBuffer = WriteBuffer
        for i, Key in Keys do
            Cur = Writes[i](Data[Key], WriteBuffer, Cur)
        end
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end

    @native const function SerializeWithOffset(Data: { [string]: any } & GetTypeFromTypeNodes<T>, Offset: number): buffer
        local Cur = 0
        const Writes = Writes
        const Keys = Keys
        const WriteBuffer = WriteBuffer
        for i, Key in Keys do
            Cur = Writes[i](Data[Key], WriteBuffer, Cur)
        end
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end

    Object.SerializeWithOffset = SerializeWithOffset

    @native function Object.Push(Data: { [string]: any } & GetTypeFromTypeNodes<T>, Buffer: buffer, Offset: number?): number
        local Cur = Offset or 0
        const Keys = Keys
        const Writes = Writes
        for i, Key in Keys do
            Cur = Writes[i](Data[Key], Buffer, Cur)
        end
        return Cur
    end

    @native function Object.Deserialize(Buffer: buffer): (GetTypeFromTypeNodes<T>, number)
        local Cur = 0
        const Result = {}
        const Keys = Keys
        const Reads = Reads
        for i, Key in Keys do
            Result[Key], Cur = Reads[i](Buffer, Cur)
        end
        return Result :: GetTypeFromTypeNodes<T>, Cur
    end

    @native function Object.DeserializeWithOffset(Buffer: buffer, Offset: number): (GetTypeFromTypeNodes<T>, number)
        const Result = {}
        const Keys = Keys
        const Reads = Reads
        for i, Key in Keys do
            Result[Key], Offset = Reads[i](Buffer, Offset)
        end
        return Result :: GetTypeFromTypeNodes<T>, Offset
    end

    @native function Object.DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        const WriteBuffer = WriteBuffer
        const KeyIndex = KeyIndex
        const Writes = Writes
        for Key, Value in Data do
            Len += 1
            const Index = KeyIndex[Key]
            buffer.writeu8(WriteBuffer, Cur, Index)
            Cur += 1
            Cur = Writes[Index](Value, WriteBuffer, Cur)
        end
        buffer.writeu8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end

    @native function Object.DeltaPush(Buffer: buffer, Data: Optional<GetTypeFromTypeNodes<T>>, Offset: number): number
        const Cur = Offset
        Offset += 1
        local Len = 0
        const KeyIndex = KeyIndex
        const Writes = Writes
        for Key, Value in Data :: { [string]: any } do
            Len += 1
            const Index = KeyIndex[Key]
            buffer.writeu8(Buffer, Offset, Index)
            Offset += 1
            Offset = Writes[Index](Value, Buffer, Offset)
        end
        buffer.writeu8(Buffer, Cur, Len)
        return Offset
    end

    @native function Object.DeltaDeserialize(Buffer: buffer, Offset: number?): (Optional<GetTypeFromTypeNodes<T>>, number)
        local Cur = Offset or 0
        const Len = buffer.readu8(Buffer, Cur)
        Cur += 1
        const Result = {}
        const Keys = Keys
        const Reads = Reads
        for i = 1, Len do
            const Index = buffer.readu8(Buffer, Cur)
            Cur += 1
            Result[Keys[Index]], Cur = Reads[Index](Buffer, Cur)
        end
        return Result :: Optional<GetTypeFromTypeNodes<T>>, Cur
    end

    @native function Object.Migrate(OtherSchema: Schema<T & { [string]: SerdesNode<any> }>, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)

        const WriteBuffer = WriteBuffer
        const Prefix = NewOffset or 0
        local Cur = 0
        const Writes = Writes
        const Keys = Keys
        for i, Key in Keys do
            Cur = Writes[i](Data[Key], WriteBuffer, Cur)
        end

        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end

    @native function Object.SerializeSafe(Data: { [string]: any } & GetTypeFromTypeNodes<T>, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            const Writes = Writes
            const Keys = Keys
            const WriteBuffer = WriteBuffer
            for i, Key in Keys do
                const function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                const Write = Writes[i]
                Success, Cur = XPcall(Write, ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end

            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end

    return Object :: Schema<GetTypeFromTypeNodes<T>>
end

--- Builds one schema by merging field maps, `Struct` nodes, and other `Schema` objects.
---
--- Field names are sorted lexicographically. Duplicate keys error. Delta structs are rejected.
--- Maximum 255 fields. Results with 16 or fewer fields use the same inlined writers as `Schema`.
--- @tag Core
--- @param ... SerdesNode | {[string]: SerdesNode} | Schema -- Pieces to merge, in any order.
--- @return Schema
@native function VoidSentryUltimate.InheritedSchema(...: SerdesNode<any> | { [string]: SerdesNode<any> } | Schema<{[string]: any}>): Schema<{[string]: any}>
    const Object = {}
    const Keys = {}
    const TempData: { [string]: { Ser: Ser<any>, Des: Des<any> } } = {}
    local KeysCount = 0
    const KeyIndex = {}

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
    if KeysCount > 255 then
        error("Schema cannot have more than 255 fields, provided fields: " .. KeysCount)
    end
    const Writes = CreateTable<<Ser<any>>>(KeysCount)
    const Reads = CreateTable<<Des<any>>>(KeysCount)
    for i, Key in Keys do
        const Data = TempData[Key]
        Writes[i] = Data.Ser
        Reads[i] = Data.Des :: Des<any>
        KeyIndex[Key] = i
    end
    
    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads

    const InlineNode = InlineSchema[KeysCount]
    if InlineNode then
        return InlineNode(Object)
    end

    @native function Object.Serialize(Data: { [string]: any }): buffer
        local Cur = 0
        const Writes = Writes
        const Keys = Keys
        const WriteBuffer = WriteBuffer
        for i, Key in Keys do
            Cur = Writes[i](Data[Key], WriteBuffer, Cur)
        end
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end

    @native function Object.SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = 0
        const Writes = Writes
        const Keys = Keys
        const WriteBuffer = WriteBuffer
        for i, Key in Keys do
            Cur = Writes[i](Data[Key], WriteBuffer, Cur)
        end
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end

    const SerializeUnsafe = Object.SerializeWithOffset

    @native function Object.Push(Data: { [string]: any }, Buffer: buffer, Offset: number?): number
        local Cur = Offset or 0
        const Keys = Keys
        const Writes = Writes
        for i, Key in Keys do
            Cur = Writes[i](Data[Key], Buffer, Cur)
        end
        return Cur
    end

    @native function Object.Deserialize(Buffer: buffer): ({ [string]: any }, number)
        local Cur = 0
        const Result = {}
        const Keys = Keys
        const Reads = Reads

        for i, Key in Keys do
            Result[Key], Cur = Reads[i](Buffer, Cur)
        end
        return Result, Cur
    end

    @native function Object.DeserializeWithOffset(Buffer: buffer, Offset: number): ({ [string]: any }, number)
        const Result = {}
        const Keys = Keys
        const Reads = Reads
        for i, Key in Keys do
            Result[Key], Offset = Reads[i](Buffer, Offset)
        end
        return Result, Offset
    end

    @native function Object.DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        const WriteBuffer = WriteBuffer
        const KeyIndex = KeyIndex
        const Writes = Writes
        for Key, Value in Data do
            Len += 1
            const Index = KeyIndex[Key]
            buffer.writeu8(WriteBuffer, Cur, Index)
            Cur += 1
            Cur = Writes[Index](Value, WriteBuffer, Cur)
        end
        buffer.writeu8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end

    @native function Object.DeltaPush(Buffer: buffer, Data: { [string]: any }, Offset: number): number
        const Cur = Offset
        Offset += 1
        local Len = 0
        const KeyIndex = KeyIndex
        const Writes = Writes
        for Key, Value in Data do
            Len += 1
            const Index = KeyIndex[Key]
            buffer.writeu8(Buffer, Offset, Index)
            Offset += 1
            Offset = Writes[Index](Value, Buffer, Offset)
        end
        buffer.writeu8(Buffer, Cur, Len)
        return Offset
    end

    @native function Object.DeltaDeserialize(Buffer: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = buffer.readu8(Buffer, Cur)
        Cur += 1
        const Result = {}
        const Keys = Keys
        const Reads = Reads
        for i = 1, Len do
            const Index = buffer.readu8(Buffer, Cur)
            Cur += 1
            Result[Keys[Index]], Cur = Reads[Index](Buffer, Cur)
        end
        return Result, Cur
    end

    @native function Object.Migrate(OtherSchema: Schema<{ [string]: any }>, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)

        const WriteBuffer = WriteBuffer
        const Prefix = NewOffset or 0
        local Cur = 0
        const Writes = Writes
        const Keys = Keys
        for i, Key in Keys do
            Cur = Writes[i](Data[Key], WriteBuffer, Cur)
        end

        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end

    @native function Object.SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeUnsafe, Data, Offset)
        if not Success then
            local Cur = 0
            const Writes = Writes
            const Keys = Keys
            const WriteBuffer = WriteBuffer
            for i, Key in Keys do
                const function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                const Write = Writes[i]
                Success, Cur = XPcall(Write, ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end

            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end

    return Object 
end

--- Replaces the reusable serialization scratch buffer with a new capacity.
---
--- The default capacity is 1,000,000 bytes. Set a different size before
--- serialization when your payload limit differs.
--- @tag Core
--- @param NewSize number -- New scratch-buffer size in bytes.
function VoidSentryUltimate.SetWriteBufferSize(NewSize: number): ()
    WriteBuffer = CreateBuffer(NewSize)
    SetWBuf(WriteBuffer)
end

--- Returns the current scratch buffer.
--- @tag Core
--- @return buffer
function VoidSentryUltimate.GetWriteBuffer(): buffer
    return WriteBuffer
end

---------------------------------------------------------
-- INIT
---------------------------------------------------------

if INSTANCE_SERIALIZATION_ENABLED then
    if RunService:IsClient() then
        const function RetryGetAttribute(Co: thread, Descendant: Instance): ()
            TaskSpawn(Co, Descendant.GetAttribute, Descendant, INSTANCE_ATTRIBUTE_NAME)
        end
        
        const function DeferFetch(Descendant: Instance): number?
            const Co = CoroutineRunning()
            TaskDelay(0, RetryGetAttribute, Co, Descendant)
            return CoroutineYield()
        end
        
        const function OnInstance(Descendant: Instance): ()
            local Success: boolean, Id: number? = Pcall(Descendant.GetAttribute :: (Instance, string) -> number?, Descendant, INSTANCE_ATTRIBUTE_NAME)
            if not Success then
                return
            end
            if not Id then
                Id = DeferFetch(Descendant)
                if not Id then
                    return
                end
            end
            IdMap[Id :: number] = Descendant
            InstanceMap[Descendant] = Id
        end

        const function OnRemoving(Descendant: Instance): ()
            const Id = InstanceMap[Descendant]
            if Id then
                IdMap[Id] = nil
            end
            InstanceMap[Descendant] = nil
        end

        for _, Descendant in game:GetDescendants() do
            TaskSpawn(OnInstance, Descendant)
        end
        game.DescendantAdded:Connect(OnInstance)
        game.DescendantRemoving:Connect(OnRemoving)
    else
        const FreeIds: { number } = {}
        local FreeIdsCount = 0
        local Total = 0

        const function OnInstance(Descendant: Instance): ()
            if FreeIdsCount ~= 0 then
                const Count = FreeIdsCount
                const Id = FreeIds[Count]
                FreeIds[Count] = nil
                FreeIdsCount = Count - 1

                const Success = Pcall(Descendant.SetAttribute, Descendant, INSTANCE_ATTRIBUTE_NAME, Id)
                if Success then
                    IdMap[Id] = Descendant
                    InstanceMap[Descendant] = Id
                end
            else
                const NewTotal = Total + 1
                const Success = Pcall(Descendant.SetAttribute, Descendant, INSTANCE_ATTRIBUTE_NAME, NewTotal)
        
                if Success then
                    Total = NewTotal
                    IdMap[Total] = Descendant
                    InstanceMap[Descendant] = NewTotal
                end
            end
        end

        const function OnRemoving(Descendant: Instance): ()
            const Id = InstanceMap[Descendant]
            if Id then
                IdMap[Id] = nil
                table.insert(FreeIds, Id)
                FreeIdsCount += 1
            end
            InstanceMap[Descendant] = nil
        end

        for _, Descendant in game:GetDescendants() do
            TaskSpawn(OnInstance, Descendant)
        end
        game.DescendantAdded:Connect(OnInstance)
        game.DescendantRemoving:Connect(OnRemoving)
    end
end

const List = { Integers, Scalars, Strings, Arrays, Maps, Structs, Booleans, CFrames, Vectors, Udims, Buffers, Special, Enums, Instances, RobloxExtra, Colors }

for _, Container in List do
    for Name, Node in Container do
        Types[Name] = Node
    end
end

SetWBuf(WriteBuffer)

const Freeze = table.freeze
Freeze(VoidSentryUltimate)
Freeze(Types)

return VoidSentryUltimate :: Lib