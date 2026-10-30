-- This file contains functions for inlining schemas with 0-16 fields
--!optimize 2
const CreateBuffer = buffer.create
const CopyBuffer = buffer.copy
const WriteU8 = buffer.writeu8
const ReadU8 = buffer.readu8
const Pcall = pcall
const XPcall = xpcall

local WriteBuffer = buffer.create(0) -- will be set on load

const InlineSchema: { [number]: ({ [string]: any }) -> { [string]: any }, SetWriteBuffer: (buffer) -> () } = {} :: any

function InlineSchema.SetWriteBuffer(Buf: buffer)
    WriteBuffer = Buf
end

@native const function Zero(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const Object: { [string]: any } = {}
    @native const function Serialize(_: { [string]: any }): buffer
        const Buf = CreateBuffer(0)
        CopyBuffer(Buf, 0, WriteBuffer, 0, 0)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(_: { [string]: any }, Offset: number): buffer
        return CreateBuffer(Offset)
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(_: { [string]: any }, _: buffer, Offset: number?): number
        return Offset or 0
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        return {}, 0
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        return {}, Offset
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        return {}, (Offset or 0) + 1
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        return CreateBuffer(NewOffset or 0)
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function One(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        return s1(Data[k1], Buf, Offset or 0)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        return {
            [k1] = v1
        }, c1
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        return {
            [k1] = v1
        }, c1
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            local function ErrorFormatter(Err: string)
                return `Failed to Serialize Field '{k1}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
            end
            Success, Cur = XPcall(s1, ErrorFormatter, Data[k1], WriteBuffer, Cur)
            if not Success then
                return nil, Cur :: any
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Two(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        return s2(Data[k2], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        return {
            [k1] = v1,
            [k2] = v2
        }, c2
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        return {
            [k1] = v1,
            [k2] = v2
        }, c2
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Three(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        return s3(Data[k3], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        return {
            [k1] = v1,
            [k2] = v2,
            [k3] = v3
        }, c3
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        return {
            [k1] = v1,
            [k2] = v2,
            [k3] = v3
        }, c3
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Four(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        return s4(Data[k4], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        return {
            [k1] = v1,
            [k2] = v2,
            [k3] = v3,
            [k4] = v4
        }, c4
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        return {
            [k1] = v1,
            [k2] = v2,
            [k3] = v3,
            [k4] = v4
        }, c4
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Five(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        return s5(Data[k5], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        return {
            [k1] = v1,
            [k2] = v2,
            [k3] = v3,
            [k4] = v4,
            [k5] = v5
        }, c5
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        return {
            [k1] = v1,
            [k2] = v2,
            [k3] = v3,
            [k4] = v4,
            [k5] = v5
        }, c5
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Six(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const k6 = Keys[6]
    const s6 = Writes[6]
    const d6 = Reads[6]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        Cur = s5(Data[k5], Buf, Cur)
        return s6(Data[k6], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        return {
            [k1] = v1,
            [k2] = v2,
            [k3] = v3,
            [k4] = v4,
            [k5] = v5,
            [k6] = v6
        }, c6
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        return {
            [k1] = v1,
            [k2] = v2,
            [k3] = v3,
            [k4] = v4,
            [k5] = v5,
            [k6] = v6
        }, c6
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 6)
            Cur += 1
            Cur = s6(Data[k6], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 6)
            Offset += 1
            Offset = s6(Data[k6], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            elseif Index == 6 then
                Result[k6], Cur = d6(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Seven(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const k6 = Keys[6]
    const s6 = Writes[6]
    const d6 = Reads[6]

    const k7 = Keys[7]
    const s7 = Writes[7]
    const d7 = Reads[7]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        Cur = s5(Data[k5], Buf, Cur)
        Cur = s6(Data[k6], Buf, Cur)
        return s7(Data[k7], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7
        }, c7
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7
        }, c7
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 6)
            Cur += 1
            Cur = s6(Data[k6], WriteBuffer, Cur)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 7)
            Cur += 1
            Cur = s7(Data[k7], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 6)
            Offset += 1
            Offset = s6(Data[k6], Buf, Offset)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 7)
            Offset += 1
            Offset = s7(Data[k7], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            elseif Index == 6 then
                Result[k6], Cur = d6(Buf, Cur)
            elseif Index == 7 then
                Result[k7], Cur = d7(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Eight(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const k6 = Keys[6]
    const s6 = Writes[6]
    const d6 = Reads[6]

    const k7 = Keys[7]
    const s7 = Writes[7]
    const d7 = Reads[7]

    const k8 = Keys[8]
    const s8 = Writes[8]
    const d8 = Reads[8]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        Cur = s5(Data[k5], Buf, Cur)
        Cur = s6(Data[k6], Buf, Cur)
        Cur = s7(Data[k7], Buf, Cur)
        return s8(Data[k8], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8
        }, c8
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8
        }, c8
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 6)
            Cur += 1
            Cur = s6(Data[k6], WriteBuffer, Cur)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 7)
            Cur += 1
            Cur = s7(Data[k7], WriteBuffer, Cur)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 8)
            Cur += 1
            Cur = s8(Data[k8], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 6)
            Offset += 1
            Offset = s6(Data[k6], Buf, Offset)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 7)
            Offset += 1
            Offset = s7(Data[k7], Buf, Offset)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 8)
            Offset += 1
            Offset = s8(Data[k8], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            elseif Index == 6 then
                Result[k6], Cur = d6(Buf, Cur)
            elseif Index == 7 then
                Result[k7], Cur = d7(Buf, Cur)
            elseif Index == 8 then
                Result[k8], Cur = d8(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Nine(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const k6 = Keys[6]
    const s6 = Writes[6]
    const d6 = Reads[6]

    const k7 = Keys[7]
    const s7 = Writes[7]
    const d7 = Reads[7]

    const k8 = Keys[8]
    const s8 = Writes[8]
    const d8 = Reads[8]

    const k9 = Keys[9]
    const s9 = Writes[9]
    const d9 = Reads[9]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        Cur = s5(Data[k5], Buf, Cur)
        Cur = s6(Data[k6], Buf, Cur)
        Cur = s7(Data[k7], Buf, Cur)
        Cur = s8(Data[k8], Buf, Cur)
        return s9(Data[k9], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9
        }, c9
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9
        }, c9
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 6)
            Cur += 1
            Cur = s6(Data[k6], WriteBuffer, Cur)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 7)
            Cur += 1
            Cur = s7(Data[k7], WriteBuffer, Cur)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 8)
            Cur += 1
            Cur = s8(Data[k8], WriteBuffer, Cur)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 9)
            Cur += 1
            Cur = s9(Data[k9], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 6)
            Offset += 1
            Offset = s6(Data[k6], Buf, Offset)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 7)
            Offset += 1
            Offset = s7(Data[k7], Buf, Offset)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 8)
            Offset += 1
            Offset = s8(Data[k8], Buf, Offset)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 9)
            Offset += 1
            Offset = s9(Data[k9], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            elseif Index == 6 then
                Result[k6], Cur = d6(Buf, Cur)
            elseif Index == 7 then
                Result[k7], Cur = d7(Buf, Cur)
            elseif Index == 8 then
                Result[k8], Cur = d8(Buf, Cur)
            elseif Index == 9 then
                Result[k9], Cur = d9(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Ten(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const k6 = Keys[6]
    const s6 = Writes[6]
    const d6 = Reads[6]

    const k7 = Keys[7]
    const s7 = Writes[7]
    const d7 = Reads[7]

    const k8 = Keys[8]
    const s8 = Writes[8]
    const d8 = Reads[8]

    const k9 = Keys[9]
    const s9 = Writes[9]
    const d9 = Reads[9]

    const k10 = Keys[10]
    const s10 = Writes[10]
    const d10 = Reads[10]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        Cur = s5(Data[k5], Buf, Cur)
        Cur = s6(Data[k6], Buf, Cur)
        Cur = s7(Data[k7], Buf, Cur)
        Cur = s8(Data[k8], Buf, Cur)
        Cur = s9(Data[k9], Buf, Cur)
        return s10(Data[k10], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10
        }, c10
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10
        }, c10
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 6)
            Cur += 1
            Cur = s6(Data[k6], WriteBuffer, Cur)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 7)
            Cur += 1
            Cur = s7(Data[k7], WriteBuffer, Cur)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 8)
            Cur += 1
            Cur = s8(Data[k8], WriteBuffer, Cur)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 9)
            Cur += 1
            Cur = s9(Data[k9], WriteBuffer, Cur)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 10)
            Cur += 1
            Cur = s10(Data[k10], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 6)
            Offset += 1
            Offset = s6(Data[k6], Buf, Offset)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 7)
            Offset += 1
            Offset = s7(Data[k7], Buf, Offset)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 8)
            Offset += 1
            Offset = s8(Data[k8], Buf, Offset)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 9)
            Offset += 1
            Offset = s9(Data[k9], Buf, Offset)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 10)
            Offset += 1
            Offset = s10(Data[k10], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            elseif Index == 6 then
                Result[k6], Cur = d6(Buf, Cur)
            elseif Index == 7 then
                Result[k7], Cur = d7(Buf, Cur)
            elseif Index == 8 then
                Result[k8], Cur = d8(Buf, Cur)
            elseif Index == 9 then
                Result[k9], Cur = d9(Buf, Cur)
            elseif Index == 10 then
                Result[k10], Cur = d10(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Eleven(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const k6 = Keys[6]
    const s6 = Writes[6]
    const d6 = Reads[6]

    const k7 = Keys[7]
    const s7 = Writes[7]
    const d7 = Reads[7]

    const k8 = Keys[8]
    const s8 = Writes[8]
    const d8 = Reads[8]

    const k9 = Keys[9]
    const s9 = Writes[9]
    const d9 = Reads[9]

    const k10 = Keys[10]
    const s10 = Writes[10]
    const d10 = Reads[10]

    const k11 = Keys[11]
    const s11 = Writes[11]
    const d11 = Reads[11]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        Cur = s5(Data[k5], Buf, Cur)
        Cur = s6(Data[k6], Buf, Cur)
        Cur = s7(Data[k7], Buf, Cur)
        Cur = s8(Data[k8], Buf, Cur)
        Cur = s9(Data[k9], Buf, Cur)
        Cur = s10(Data[k10], Buf, Cur)
        return s11(Data[k11], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11
        }, c11
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11
        }, c11
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 6)
            Cur += 1
            Cur = s6(Data[k6], WriteBuffer, Cur)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 7)
            Cur += 1
            Cur = s7(Data[k7], WriteBuffer, Cur)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 8)
            Cur += 1
            Cur = s8(Data[k8], WriteBuffer, Cur)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 9)
            Cur += 1
            Cur = s9(Data[k9], WriteBuffer, Cur)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 10)
            Cur += 1
            Cur = s10(Data[k10], WriteBuffer, Cur)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 11)
            Cur += 1
            Cur = s11(Data[k11], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 6)
            Offset += 1
            Offset = s6(Data[k6], Buf, Offset)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 7)
            Offset += 1
            Offset = s7(Data[k7], Buf, Offset)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 8)
            Offset += 1
            Offset = s8(Data[k8], Buf, Offset)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 9)
            Offset += 1
            Offset = s9(Data[k9], Buf, Offset)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 10)
            Offset += 1
            Offset = s10(Data[k10], Buf, Offset)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 11)
            Offset += 1
            Offset = s11(Data[k11], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            elseif Index == 6 then
                Result[k6], Cur = d6(Buf, Cur)
            elseif Index == 7 then
                Result[k7], Cur = d7(Buf, Cur)
            elseif Index == 8 then
                Result[k8], Cur = d8(Buf, Cur)
            elseif Index == 9 then
                Result[k9], Cur = d9(Buf, Cur)
            elseif Index == 10 then
                Result[k10], Cur = d10(Buf, Cur)
            elseif Index == 11 then
                Result[k11], Cur = d11(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Twelve(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const k6 = Keys[6]
    const s6 = Writes[6]
    const d6 = Reads[6]

    const k7 = Keys[7]
    const s7 = Writes[7]
    const d7 = Reads[7]

    const k8 = Keys[8]
    const s8 = Writes[8]
    const d8 = Reads[8]

    const k9 = Keys[9]
    const s9 = Writes[9]
    const d9 = Reads[9]

    const k10 = Keys[10]
    const s10 = Writes[10]
    const d10 = Reads[10]

    const k11 = Keys[11]
    const s11 = Writes[11]
    const d11 = Reads[11]

    const k12 = Keys[12]
    const s12 = Writes[12]
    const d12 = Reads[12]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        Cur = s5(Data[k5], Buf, Cur)
        Cur = s6(Data[k6], Buf, Cur)
        Cur = s7(Data[k7], Buf, Cur)
        Cur = s8(Data[k8], Buf, Cur)
        Cur = s9(Data[k9], Buf, Cur)
        Cur = s10(Data[k10], Buf, Cur)
        Cur = s11(Data[k11], Buf, Cur)
        return s12(Data[k12], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        const v12, c12 = d12(Buf, c11)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11, [k12] = v12
        }, c12
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        const v12, c12 = d12(Buf, c11)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11, [k12] = v12
        }, c12
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 6)
            Cur += 1
            Cur = s6(Data[k6], WriteBuffer, Cur)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 7)
            Cur += 1
            Cur = s7(Data[k7], WriteBuffer, Cur)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 8)
            Cur += 1
            Cur = s8(Data[k8], WriteBuffer, Cur)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 9)
            Cur += 1
            Cur = s9(Data[k9], WriteBuffer, Cur)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 10)
            Cur += 1
            Cur = s10(Data[k10], WriteBuffer, Cur)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 11)
            Cur += 1
            Cur = s11(Data[k11], WriteBuffer, Cur)
        end
        if Data[k12] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 12)
            Cur += 1
            Cur = s12(Data[k12], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 6)
            Offset += 1
            Offset = s6(Data[k6], Buf, Offset)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 7)
            Offset += 1
            Offset = s7(Data[k7], Buf, Offset)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 8)
            Offset += 1
            Offset = s8(Data[k8], Buf, Offset)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 9)
            Offset += 1
            Offset = s9(Data[k9], Buf, Offset)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 10)
            Offset += 1
            Offset = s10(Data[k10], Buf, Offset)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 11)
            Offset += 1
            Offset = s11(Data[k11], Buf, Offset)
        end
        if Data[k12] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 12)
            Offset += 1
            Offset = s12(Data[k12], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            elseif Index == 6 then
                Result[k6], Cur = d6(Buf, Cur)
            elseif Index == 7 then
                Result[k7], Cur = d7(Buf, Cur)
            elseif Index == 8 then
                Result[k8], Cur = d8(Buf, Cur)
            elseif Index == 9 then
                Result[k9], Cur = d9(Buf, Cur)
            elseif Index == 10 then
                Result[k10], Cur = d10(Buf, Cur)
            elseif Index == 11 then
                Result[k11], Cur = d11(Buf, Cur)
            elseif Index == 12 then
                Result[k12], Cur = d12(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Thirteen(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const k6 = Keys[6]
    const s6 = Writes[6]
    const d6 = Reads[6]

    const k7 = Keys[7]
    const s7 = Writes[7]
    const d7 = Reads[7]

    const k8 = Keys[8]
    const s8 = Writes[8]
    const d8 = Reads[8]

    const k9 = Keys[9]
    const s9 = Writes[9]
    const d9 = Reads[9]

    const k10 = Keys[10]
    const s10 = Writes[10]
    const d10 = Reads[10]

    const k11 = Keys[11]
    const s11 = Writes[11]
    const d11 = Reads[11]

    const k12 = Keys[12]
    const s12 = Writes[12]
    const d12 = Reads[12]

    const k13 = Keys[13]
    const s13 = Writes[13]
    const d13 = Reads[13]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        Cur = s5(Data[k5], Buf, Cur)
        Cur = s6(Data[k6], Buf, Cur)
        Cur = s7(Data[k7], Buf, Cur)
        Cur = s8(Data[k8], Buf, Cur)
        Cur = s9(Data[k9], Buf, Cur)
        Cur = s10(Data[k10], Buf, Cur)
        Cur = s11(Data[k11], Buf, Cur)
        Cur = s12(Data[k12], Buf, Cur)
        return s13(Data[k13], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        const v12, c12 = d12(Buf, c11)
        const v13, c13 = d13(Buf, c12)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11, [k12] = v12,
            [k13] = v13
        }, c13
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        const v12, c12 = d12(Buf, c11)
        const v13, c13 = d13(Buf, c12)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11, [k12] = v12,
            [k13] = v13
        }, c13
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 6)
            Cur += 1
            Cur = s6(Data[k6], WriteBuffer, Cur)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 7)
            Cur += 1
            Cur = s7(Data[k7], WriteBuffer, Cur)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 8)
            Cur += 1
            Cur = s8(Data[k8], WriteBuffer, Cur)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 9)
            Cur += 1
            Cur = s9(Data[k9], WriteBuffer, Cur)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 10)
            Cur += 1
            Cur = s10(Data[k10], WriteBuffer, Cur)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 11)
            Cur += 1
            Cur = s11(Data[k11], WriteBuffer, Cur)
        end
        if Data[k12] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 12)
            Cur += 1
            Cur = s12(Data[k12], WriteBuffer, Cur)
        end
        if Data[k13] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 13)
            Cur += 1
            Cur = s13(Data[k13], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 6)
            Offset += 1
            Offset = s6(Data[k6], Buf, Offset)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 7)
            Offset += 1
            Offset = s7(Data[k7], Buf, Offset)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 8)
            Offset += 1
            Offset = s8(Data[k8], Buf, Offset)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 9)
            Offset += 1
            Offset = s9(Data[k9], Buf, Offset)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 10)
            Offset += 1
            Offset = s10(Data[k10], Buf, Offset)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 11)
            Offset += 1
            Offset = s11(Data[k11], Buf, Offset)
        end
        if Data[k12] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 12)
            Offset += 1
            Offset = s12(Data[k12], Buf, Offset)
        end
        if Data[k13] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 13)
            Offset += 1
            Offset = s13(Data[k13], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            elseif Index == 6 then
                Result[k6], Cur = d6(Buf, Cur)
            elseif Index == 7 then
                Result[k7], Cur = d7(Buf, Cur)
            elseif Index == 8 then
                Result[k8], Cur = d8(Buf, Cur)
            elseif Index == 9 then
                Result[k9], Cur = d9(Buf, Cur)
            elseif Index == 10 then
                Result[k10], Cur = d10(Buf, Cur)
            elseif Index == 11 then
                Result[k11], Cur = d11(Buf, Cur)
            elseif Index == 12 then
                Result[k12], Cur = d12(Buf, Cur)
            elseif Index == 13 then
                Result[k13], Cur = d13(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Fourteen(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const k6 = Keys[6]
    const s6 = Writes[6]
    const d6 = Reads[6]

    const k7 = Keys[7]
    const s7 = Writes[7]
    const d7 = Reads[7]

    const k8 = Keys[8]
    const s8 = Writes[8]
    const d8 = Reads[8]

    const k9 = Keys[9]
    const s9 = Writes[9]
    const d9 = Reads[9]

    const k10 = Keys[10]
    const s10 = Writes[10]
    const d10 = Reads[10]

    const k11 = Keys[11]
    const s11 = Writes[11]
    const d11 = Reads[11]

    const k12 = Keys[12]
    const s12 = Writes[12]
    const d12 = Reads[12]

    const k13 = Keys[13]
    const s13 = Writes[13]
    const d13 = Reads[13]

    const k14 = Keys[14]
    const s14 = Writes[14]
    const d14 = Reads[14]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        Cur = s14(Data[k14], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        Cur = s14(Data[k14], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        Cur = s5(Data[k5], Buf, Cur)
        Cur = s6(Data[k6], Buf, Cur)
        Cur = s7(Data[k7], Buf, Cur)
        Cur = s8(Data[k8], Buf, Cur)
        Cur = s9(Data[k9], Buf, Cur)
        Cur = s10(Data[k10], Buf, Cur)
        Cur = s11(Data[k11], Buf, Cur)
        Cur = s12(Data[k12], Buf, Cur)
        Cur = s13(Data[k13], Buf, Cur)
        return s14(Data[k14], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        const v12, c12 = d12(Buf, c11)
        const v13, c13 = d13(Buf, c12)
        const v14, c14 = d14(Buf, c13)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11, [k12] = v12,
            [k13] = v13, [k14] = v14
        }, c14
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        const v12, c12 = d12(Buf, c11)
        const v13, c13 = d13(Buf, c12)
        const v14, c14 = d14(Buf, c13)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11, [k12] = v12,
            [k13] = v13, [k14] = v14
        }, c14
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 6)
            Cur += 1
            Cur = s6(Data[k6], WriteBuffer, Cur)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 7)
            Cur += 1
            Cur = s7(Data[k7], WriteBuffer, Cur)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 8)
            Cur += 1
            Cur = s8(Data[k8], WriteBuffer, Cur)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 9)
            Cur += 1
            Cur = s9(Data[k9], WriteBuffer, Cur)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 10)
            Cur += 1
            Cur = s10(Data[k10], WriteBuffer, Cur)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 11)
            Cur += 1
            Cur = s11(Data[k11], WriteBuffer, Cur)
        end
        if Data[k12] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 12)
            Cur += 1
            Cur = s12(Data[k12], WriteBuffer, Cur)
        end
        if Data[k13] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 13)
            Cur += 1
            Cur = s13(Data[k13], WriteBuffer, Cur)
        end
        if Data[k14] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 14)
            Cur += 1
            Cur = s14(Data[k14], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 6)
            Offset += 1
            Offset = s6(Data[k6], Buf, Offset)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 7)
            Offset += 1
            Offset = s7(Data[k7], Buf, Offset)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 8)
            Offset += 1
            Offset = s8(Data[k8], Buf, Offset)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 9)
            Offset += 1
            Offset = s9(Data[k9], Buf, Offset)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 10)
            Offset += 1
            Offset = s10(Data[k10], Buf, Offset)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 11)
            Offset += 1
            Offset = s11(Data[k11], Buf, Offset)
        end
        if Data[k12] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 12)
            Offset += 1
            Offset = s12(Data[k12], Buf, Offset)
        end
        if Data[k13] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 13)
            Offset += 1
            Offset = s13(Data[k13], Buf, Offset)
        end
        if Data[k14] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 14)
            Offset += 1
            Offset = s14(Data[k14], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            elseif Index == 6 then
                Result[k6], Cur = d6(Buf, Cur)
            elseif Index == 7 then
                Result[k7], Cur = d7(Buf, Cur)
            elseif Index == 8 then
                Result[k8], Cur = d8(Buf, Cur)
            elseif Index == 9 then
                Result[k9], Cur = d9(Buf, Cur)
            elseif Index == 10 then
                Result[k10], Cur = d10(Buf, Cur)
            elseif Index == 11 then
                Result[k11], Cur = d11(Buf, Cur)
            elseif Index == 12 then
                Result[k12], Cur = d12(Buf, Cur)
            elseif Index == 13 then
                Result[k13], Cur = d13(Buf, Cur)
            elseif Index == 14 then
                Result[k14], Cur = d14(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        Cur = s14(Data[k14], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Fifteen(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const k6 = Keys[6]
    const s6 = Writes[6]
    const d6 = Reads[6]

    const k7 = Keys[7]
    const s7 = Writes[7]
    const d7 = Reads[7]

    const k8 = Keys[8]
    const s8 = Writes[8]
    const d8 = Reads[8]

    const k9 = Keys[9]
    const s9 = Writes[9]
    const d9 = Reads[9]

    const k10 = Keys[10]
    const s10 = Writes[10]
    const d10 = Reads[10]

    const k11 = Keys[11]
    const s11 = Writes[11]
    const d11 = Reads[11]

    const k12 = Keys[12]
    const s12 = Writes[12]
    const d12 = Reads[12]

    const k13 = Keys[13]
    const s13 = Writes[13]
    const d13 = Reads[13]

    const k14 = Keys[14]
    const s14 = Writes[14]
    const d14 = Reads[14]

    const k15 = Keys[15]
    const s15 = Writes[15]
    const d15 = Reads[15]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        Cur = s14(Data[k14], WriteBuffer, Cur)
        Cur = s15(Data[k15], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        Cur = s14(Data[k14], WriteBuffer, Cur)
        Cur = s15(Data[k15], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        Cur = s5(Data[k5], Buf, Cur)
        Cur = s6(Data[k6], Buf, Cur)
        Cur = s7(Data[k7], Buf, Cur)
        Cur = s8(Data[k8], Buf, Cur)
        Cur = s9(Data[k9], Buf, Cur)
        Cur = s10(Data[k10], Buf, Cur)
        Cur = s11(Data[k11], Buf, Cur)
        Cur = s12(Data[k12], Buf, Cur)
        Cur = s13(Data[k13], Buf, Cur)
        Cur = s14(Data[k14], Buf, Cur)
        return s15(Data[k15], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        const v12, c12 = d12(Buf, c11)
        const v13, c13 = d13(Buf, c12)
        const v14, c14 = d14(Buf, c13)
        const v15, c15 = d15(Buf, c14)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11, [k12] = v12,
            [k13] = v13, [k14] = v14, [k15] = v15
        }, c15
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        const v12, c12 = d12(Buf, c11)
        const v13, c13 = d13(Buf, c12)
        const v14, c14 = d14(Buf, c13)
        const v15, c15 = d15(Buf, c14)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11, [k12] = v12,
            [k13] = v13, [k14] = v14, [k15] = v15
        }, c15
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 6)
            Cur += 1
            Cur = s6(Data[k6], WriteBuffer, Cur)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 7)
            Cur += 1
            Cur = s7(Data[k7], WriteBuffer, Cur)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 8)
            Cur += 1
            Cur = s8(Data[k8], WriteBuffer, Cur)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 9)
            Cur += 1
            Cur = s9(Data[k9], WriteBuffer, Cur)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 10)
            Cur += 1
            Cur = s10(Data[k10], WriteBuffer, Cur)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 11)
            Cur += 1
            Cur = s11(Data[k11], WriteBuffer, Cur)
        end
        if Data[k12] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 12)
            Cur += 1
            Cur = s12(Data[k12], WriteBuffer, Cur)
        end
        if Data[k13] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 13)
            Cur += 1
            Cur = s13(Data[k13], WriteBuffer, Cur)
        end
        if Data[k14] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 14)
            Cur += 1
            Cur = s14(Data[k14], WriteBuffer, Cur)
        end
        if Data[k15] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 15)
            Cur += 1
            Cur = s15(Data[k15], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 6)
            Offset += 1
            Offset = s6(Data[k6], Buf, Offset)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 7)
            Offset += 1
            Offset = s7(Data[k7], Buf, Offset)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 8)
            Offset += 1
            Offset = s8(Data[k8], Buf, Offset)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 9)
            Offset += 1
            Offset = s9(Data[k9], Buf, Offset)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 10)
            Offset += 1
            Offset = s10(Data[k10], Buf, Offset)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 11)
            Offset += 1
            Offset = s11(Data[k11], Buf, Offset)
        end
        if Data[k12] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 12)
            Offset += 1
            Offset = s12(Data[k12], Buf, Offset)
        end
        if Data[k13] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 13)
            Offset += 1
            Offset = s13(Data[k13], Buf, Offset)
        end
        if Data[k14] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 14)
            Offset += 1
            Offset = s14(Data[k14], Buf, Offset)
        end
        if Data[k15] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 15)
            Offset += 1
            Offset = s15(Data[k15], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            elseif Index == 6 then
                Result[k6], Cur = d6(Buf, Cur)
            elseif Index == 7 then
                Result[k7], Cur = d7(Buf, Cur)
            elseif Index == 8 then
                Result[k8], Cur = d8(Buf, Cur)
            elseif Index == 9 then
                Result[k9], Cur = d9(Buf, Cur)
            elseif Index == 10 then
                Result[k10], Cur = d10(Buf, Cur)
            elseif Index == 11 then
                Result[k11], Cur = d11(Buf, Cur)
            elseif Index == 12 then
                Result[k12], Cur = d12(Buf, Cur)
            elseif Index == 13 then
                Result[k13], Cur = d13(Buf, Cur)
            elseif Index == 14 then
                Result[k14], Cur = d14(Buf, Cur)
            elseif Index == 15 then
                Result[k15], Cur = d15(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        Cur = s14(Data[k14], WriteBuffer, Cur)
        Cur = s15(Data[k15], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

@native const function Sixteen(Schema: { [string]: any }): { [string]: any }
    const Keys = Schema.Keys
    const Writes = Schema.Writes
    const Reads = Schema.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const k4 = Keys[4]
    const s4 = Writes[4]
    const d4 = Reads[4]

    const k5 = Keys[5]
    const s5 = Writes[5]
    const d5 = Reads[5]

    const k6 = Keys[6]
    const s6 = Writes[6]
    const d6 = Reads[6]

    const k7 = Keys[7]
    const s7 = Writes[7]
    const d7 = Reads[7]

    const k8 = Keys[8]
    const s8 = Writes[8]
    const d8 = Reads[8]

    const k9 = Keys[9]
    const s9 = Writes[9]
    const d9 = Reads[9]

    const k10 = Keys[10]
    const s10 = Writes[10]
    const d10 = Reads[10]

    const k11 = Keys[11]
    const s11 = Writes[11]
    const d11 = Reads[11]

    const k12 = Keys[12]
    const s12 = Writes[12]
    const d12 = Reads[12]

    const k13 = Keys[13]
    const s13 = Writes[13]
    const d13 = Reads[13]

    const k14 = Keys[14]
    const s14 = Writes[14]
    const d14 = Reads[14]

    const k15 = Keys[15]
    const s15 = Writes[15]
    const d15 = Reads[15]

    const k16 = Keys[16]
    const s16 = Writes[16]
    const d16 = Reads[16]

    const Object: { [string]: any } = {}
    @native const function Serialize(Data: { [string]: any }): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        Cur = s14(Data[k14], WriteBuffer, Cur)
        Cur = s15(Data[k15], WriteBuffer, Cur)
        Cur = s16(Data[k16], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur)
        CopyBuffer(Buf, 0, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Serialize = Serialize

    @native const function SerializeWithOffset(Data: { [string]: any }, Offset: number): buffer
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        Cur = s14(Data[k14], WriteBuffer, Cur)
        Cur = s15(Data[k15], WriteBuffer, Cur)
        Cur = s16(Data[k16], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Offset)
        CopyBuffer(Buf, Offset, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.SerializeWithOffset = SerializeWithOffset

    @native const function Push(Data: { [string]: any }, Buf: buffer, Offset: number?): number
        local Cur = Offset or 0
        Cur = s1(Data[k1], Buf, Cur)
        Cur = s2(Data[k2], Buf, Cur)
        Cur = s3(Data[k3], Buf, Cur)
        Cur = s4(Data[k4], Buf, Cur)
        Cur = s5(Data[k5], Buf, Cur)
        Cur = s6(Data[k6], Buf, Cur)
        Cur = s7(Data[k7], Buf, Cur)
        Cur = s8(Data[k8], Buf, Cur)
        Cur = s9(Data[k9], Buf, Cur)
        Cur = s10(Data[k10], Buf, Cur)
        Cur = s11(Data[k11], Buf, Cur)
        Cur = s12(Data[k12], Buf, Cur)
        Cur = s13(Data[k13], Buf, Cur)
        Cur = s14(Data[k14], Buf, Cur)
        Cur = s15(Data[k15], Buf, Cur)
        return s16(Data[k16], Buf, Cur)
    end
    Object.Push = Push

    @native const function Deserialize(Buf: buffer): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, 0)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        const v12, c12 = d12(Buf, c11)
        const v13, c13 = d13(Buf, c12)
        const v14, c14 = d14(Buf, c13)
        const v15, c15 = d15(Buf, c14)
        const v16, c16 = d16(Buf, c15)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11, [k12] = v12,
            [k13] = v13, [k14] = v14, [k15] = v15, [k16] = v16
        }, c16
    end
    Object.Deserialize = Deserialize

    @native const function DeserializeWithOffset(Buf: buffer, Offset: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Offset)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        const v10, c10 = d10(Buf, c9)
        const v11, c11 = d11(Buf, c10)
        const v12, c12 = d12(Buf, c11)
        const v13, c13 = d13(Buf, c12)
        const v14, c14 = d14(Buf, c13)
        const v15, c15 = d15(Buf, c14)
        const v16, c16 = d16(Buf, c15)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4,
            [k5] = v5, [k6] = v6, [k7] = v7, [k8] = v8,
            [k9] = v9, [k10] = v10, [k11] = v11, [k12] = v12,
            [k13] = v13, [k14] = v14, [k15] = v15, [k16] = v16
        }, c16
    end
    Object.DeserializeWithOffset = DeserializeWithOffset

    @native const function DeltaSerialize(Data: { [string]: any }, Offset: number?): buffer
        local Cur = 0
        const Start = 0
        Cur += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 1)
            Cur += 1
            Cur = s1(Data[k1], WriteBuffer, Cur)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 2)
            Cur += 1
            Cur = s2(Data[k2], WriteBuffer, Cur)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 3)
            Cur += 1
            Cur = s3(Data[k3], WriteBuffer, Cur)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 4)
            Cur += 1
            Cur = s4(Data[k4], WriteBuffer, Cur)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 5)
            Cur += 1
            Cur = s5(Data[k5], WriteBuffer, Cur)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 6)
            Cur += 1
            Cur = s6(Data[k6], WriteBuffer, Cur)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 7)
            Cur += 1
            Cur = s7(Data[k7], WriteBuffer, Cur)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 8)
            Cur += 1
            Cur = s8(Data[k8], WriteBuffer, Cur)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 9)
            Cur += 1
            Cur = s9(Data[k9], WriteBuffer, Cur)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 10)
            Cur += 1
            Cur = s10(Data[k10], WriteBuffer, Cur)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 11)
            Cur += 1
            Cur = s11(Data[k11], WriteBuffer, Cur)
        end
        if Data[k12] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 12)
            Cur += 1
            Cur = s12(Data[k12], WriteBuffer, Cur)
        end
        if Data[k13] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 13)
            Cur += 1
            Cur = s13(Data[k13], WriteBuffer, Cur)
        end
        if Data[k14] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 14)
            Cur += 1
            Cur = s14(Data[k14], WriteBuffer, Cur)
        end
        if Data[k15] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 15)
            Cur += 1
            Cur = s15(Data[k15], WriteBuffer, Cur)
        end
        if Data[k16] ~= nil then
            Len += 1
            WriteU8(WriteBuffer, Cur, 16)
            Cur += 1
            Cur = s16(Data[k16], WriteBuffer, Cur)
        end
        WriteU8(WriteBuffer, Start, Len)
        const Prefix = Offset or 0
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.DeltaSerialize = DeltaSerialize

    @native const function DeltaPush(Buf: buffer, Data: { [string]: any }, Offset: number): number
        const Start = Offset
        Offset += 1
        local Len = 0
        if Data[k1] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 1)
            Offset += 1
            Offset = s1(Data[k1], Buf, Offset)
        end
        if Data[k2] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 2)
            Offset += 1
            Offset = s2(Data[k2], Buf, Offset)
        end
        if Data[k3] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 3)
            Offset += 1
            Offset = s3(Data[k3], Buf, Offset)
        end
        if Data[k4] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 4)
            Offset += 1
            Offset = s4(Data[k4], Buf, Offset)
        end
        if Data[k5] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 5)
            Offset += 1
            Offset = s5(Data[k5], Buf, Offset)
        end
        if Data[k6] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 6)
            Offset += 1
            Offset = s6(Data[k6], Buf, Offset)
        end
        if Data[k7] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 7)
            Offset += 1
            Offset = s7(Data[k7], Buf, Offset)
        end
        if Data[k8] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 8)
            Offset += 1
            Offset = s8(Data[k8], Buf, Offset)
        end
        if Data[k9] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 9)
            Offset += 1
            Offset = s9(Data[k9], Buf, Offset)
        end
        if Data[k10] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 10)
            Offset += 1
            Offset = s10(Data[k10], Buf, Offset)
        end
        if Data[k11] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 11)
            Offset += 1
            Offset = s11(Data[k11], Buf, Offset)
        end
        if Data[k12] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 12)
            Offset += 1
            Offset = s12(Data[k12], Buf, Offset)
        end
        if Data[k13] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 13)
            Offset += 1
            Offset = s13(Data[k13], Buf, Offset)
        end
        if Data[k14] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 14)
            Offset += 1
            Offset = s14(Data[k14], Buf, Offset)
        end
        if Data[k15] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 15)
            Offset += 1
            Offset = s15(Data[k15], Buf, Offset)
        end
        if Data[k16] ~= nil then
            Len += 1
            WriteU8(Buf, Offset, 16)
            Offset += 1
            Offset = s16(Data[k16], Buf, Offset)
        end
        WriteU8(Buf, Start, Len)
        return Offset
    end
    Object.DeltaPush = DeltaPush

    @native const function DeltaDeserialize(Buf: buffer, Offset: number?): ({ [string]: any }, number)
        local Cur = Offset or 0
        const Len = ReadU8(Buf, Cur)
        Cur += 1
        const Result = {}
        for _ = 1, Len do
            const Index = ReadU8(Buf, Cur)
            Cur += 1
            if Index == 1 then
                Result[k1], Cur = d1(Buf, Cur)
            elseif Index == 2 then
                Result[k2], Cur = d2(Buf, Cur)
            elseif Index == 3 then
                Result[k3], Cur = d3(Buf, Cur)
            elseif Index == 4 then
                Result[k4], Cur = d4(Buf, Cur)
            elseif Index == 5 then
                Result[k5], Cur = d5(Buf, Cur)
            elseif Index == 6 then
                Result[k6], Cur = d6(Buf, Cur)
            elseif Index == 7 then
                Result[k7], Cur = d7(Buf, Cur)
            elseif Index == 8 then
                Result[k8], Cur = d8(Buf, Cur)
            elseif Index == 9 then
                Result[k9], Cur = d9(Buf, Cur)
            elseif Index == 10 then
                Result[k10], Cur = d10(Buf, Cur)
            elseif Index == 11 then
                Result[k11], Cur = d11(Buf, Cur)
            elseif Index == 12 then
                Result[k12], Cur = d12(Buf, Cur)
            elseif Index == 13 then
                Result[k13], Cur = d13(Buf, Cur)
            elseif Index == 14 then
                Result[k14], Cur = d14(Buf, Cur)
            elseif Index == 15 then
                Result[k15], Cur = d15(Buf, Cur)
            elseif Index == 16 then
                Result[k16], Cur = d16(Buf, Cur)
            end
        end
        return Result, Cur
    end
    Object.DeltaDeserialize = DeltaDeserialize

    @native const function Migrate(OtherSchema: { [string]: any }, OldBuf: buffer, OldOffset: number?, NewOffset: number?): buffer
        const Data = OtherSchema.DeserializeWithOffset(OldBuf, OldOffset or 0)
        const Prefix = NewOffset or 0
        local Cur = s1(Data[k1], WriteBuffer, 0)
        Cur = s2(Data[k2], WriteBuffer, Cur)
        Cur = s3(Data[k3], WriteBuffer, Cur)
        Cur = s4(Data[k4], WriteBuffer, Cur)
        Cur = s5(Data[k5], WriteBuffer, Cur)
        Cur = s6(Data[k6], WriteBuffer, Cur)
        Cur = s7(Data[k7], WriteBuffer, Cur)
        Cur = s8(Data[k8], WriteBuffer, Cur)
        Cur = s9(Data[k9], WriteBuffer, Cur)
        Cur = s10(Data[k10], WriteBuffer, Cur)
        Cur = s11(Data[k11], WriteBuffer, Cur)
        Cur = s12(Data[k12], WriteBuffer, Cur)
        Cur = s13(Data[k13], WriteBuffer, Cur)
        Cur = s14(Data[k14], WriteBuffer, Cur)
        Cur = s15(Data[k15], WriteBuffer, Cur)
        Cur = s16(Data[k16], WriteBuffer, Cur)
        const Buf = CreateBuffer(Cur + Prefix)
        CopyBuffer(Buf, Prefix, WriteBuffer, 0, Cur)
        return Buf
    end
    Object.Migrate = Migrate

    @native const function SerializeSafe(Data: { [string]: any }, Offset: number?): (buffer?, string?)
        Offset = Offset or 0
        local Success, Result = Pcall(SerializeWithOffset, Data, Offset)
        if not Success then
            local Cur = 0
            for Index, Key in Keys do
                local function ErrorFormatter(Err: string)
                    return `Failed to Serialize Field '{Key}' at cursor {Cur}, Type: {debug.info(3, "n"):gsub("Ser", "")} Error message: {Err}`
                end
                Success, Cur = XPcall(Writes[Index], ErrorFormatter, Data[Key], WriteBuffer, Cur)
                if not Success then
                    return nil, Cur :: any
                end
            end
            return nil, "Unknown Serialization error"
        end

        return Result, nil
    end
    Object.SerializeSafe = SerializeSafe

    Object.Keys = Keys
    Object.Writes = Writes
    Object.Reads = Reads
    return Object
end

InlineSchema[0] = Zero
InlineSchema[1] = One
InlineSchema[2] = Two
InlineSchema[3] = Three
InlineSchema[4] = Four
InlineSchema[5] = Five
InlineSchema[6] = Six
InlineSchema[7] = Seven
InlineSchema[8] = Eight
InlineSchema[9] = Nine
InlineSchema[10] = Ten
InlineSchema[11] = Eleven
InlineSchema[12] = Twelve
InlineSchema[13] = Thirteen
InlineSchema[14] = Fourteen
InlineSchema[15] = Fifteen
InlineSchema[16] = Sixteen

return InlineSchema
