export type Instances = {
    -- Add more instances for autocomplete (optionally)
    Part: Part,
    BasePart: BasePart,
    MeshPart: MeshPart,
    Texture: Texture,
    Model: Model,
    SpawnLocation: SpawnLocation,
}

export type function GetTypeFromTypeNode(Node: type)
    const T = Node:readproperty(types.singleton("_T"))
    if not T then
        error("_T field not found in Node")
    end

    return GetProperTypeFromUnion(T)
end

export type function GetInstanceType(ClassName: type, Instances: type, InstanceType: type, DefinedTbl: type)
    const Inst = Instances:readproperty(ClassName) or InstanceType
    local TableFilled = false
    const Tbl = types.newtable()
    const PropsBlacklist: { [string]: true } = {
        PrimaryPart = true,
        Parent = true,
        Value = true,
        Part0 = true,
        Part1 = true,
        Attachment0 = true,
        Attachment1 = true,
        Occupant = true,
        Adornee = true,
        PlayerToHideFrom = true,
        CurrentCamera = true,
        EndEffector = true,
        SoundGroup = true,
    }
    for Key, Value: any in DefinedTbl:properties() do
        if Key.tag ~= "singleton" or type(Key:value()) ~= "string" then
            error(`Invalid field key, string singleton expected, got {if Key.tag == "singleton" then type(Key:value()) else Key.tag}`)
        end

        Value = Value.read or Value.write :: type
        if PropsBlacklist[Key:value() :: string] then
            continue
        end

        if GetTypeFromTypeNode(Value :: type):issubtypeof(InstanceType) then
            Tbl:setproperty(Key, GetTypeFromTypeNode(Value))
            TableFilled = true
            continue
        end
    end
    return if TableFilled then types.intersectionof(Inst, Tbl) else Inst
end

export type function Optional(Type: type)
    if Type.tag ~= "table" then
        error(`Argument #1 must be a table, got {Type.tag}`)
    end

    const Tbl = types.newtable()
    for Key, Value in Type:properties() do
        const Val = Value.read or Value.write :: type
        Tbl:setproperty(Key, types.optional(Val))
    end
    Tbl:setindexer(types.string, types.any)

    return Tbl
end

export type function GetEnumItem(Enum: type)
    if Enum.tag ~= "extern" then
		error(`Expected input tag to be extern, but got {Enum.tag}`, 0)
	end
	
	for _, Value in Enum:properties() do
		const Type = Value.read or Value.write :: type
		if Type.tag == "extern" then
			return Type
		end
	end

	error("Provided input type does not contain extern properties")
end

export type Ser<T> = (T, buffer, number) -> number
export type Des<T> = (buffer, number) -> (T, number)
export type SerdesNode<T> = {
	-- [1] = Ser
	-- [2] = Des
	[number | string]: any,
	_T: T | any,
}

export type function GetProperTypeFromUnion(Union: type): type
    if Union.tag ~= "union" then
        return Union
    end

    const Components = Union:components()
    const First = Components[1]
    if First.tag == "any" then
        return Components[2]
    end

    return First
end

export type function GetTypeFromTypeNodes(Struct: type)
    if Struct.tag ~= "table" then
        error(`Argument #1 must be a table, got {Struct.tag}`)
    end

    const Tbl = types.newtable()
    for Key, Value in Struct:properties() do
        const Node = Value.read or Value.write :: type

        Tbl:setproperty(Key, GetTypeFromTypeNode(Node))
    end
    -- Tbl:setindexer(types.string, types.any)

    return Tbl
end

-- TODO: improve code quality of this messy function & add validations
export type function Inherit(Fn: type): type
    const Params = Fn:parameters().head :: { type }
	const MergeResult = types.newtable()
	const _T = types.singleton("_T")
	for i = 1, #Params do
		const Node = Params[i]
        if Node:readproperty(_T) then
            const Prop = GetProperTypeFromUnion(Node:readproperty(_T) :: type)
            for Key, Value in Prop:properties() do
                MergeResult:setproperty(Key, Value.read or Value.write :: type)
            end
        else
            for Key, Value in Node:properties() do
                MergeResult:setproperty(Key, GetTypeFromTypeNode(Value.read or Value.write :: type))
            end
        end
	end
	
	return MergeResult
end

export type Schema<T> = {
    read Serialize: (Data: T) -> buffer,
    read SerializeWithOffset: (Data: T, Offset: number) -> buffer,
    read Deserialize: (Buffer: buffer) -> (T, number),
    read DeserializeWithOffset: (Buffer: buffer, Offset: number) -> (T, number),
    read Push: (Data: T, Buffer: buffer, Offset: number?) -> number,
    read DeltaSerialize: (Data: Optional<T>, Offset: number?) -> buffer,
    read DeltaDeserialize: (Buffer: buffer, Offset: number?) -> (Optional<T>, number),
    read DeltaPush: (Buffer: buffer, Data: Optional<T>, Offset: number) -> number,
    read Migrate: (OtherSchema: any, OldBuf: buffer, OldOffset: number?, NewOffset: number?) -> buffer,
    read SerializeSafe: (Data: T, Offset: number?) -> (buffer?, string?),

    _T: any | T,
}

export type Lib = {
    read Serialize: <T>(Node: SerdesNode<any> & T, Data: GetTypeFromTypeNode<T>) -> buffer,
    read SerializeWithOffset: <T>(Node: SerdesNode<any> & T, Data: GetTypeFromTypeNode<T>, Offset: number) -> buffer,
    read Deserialize: <T>(Node: SerdesNode<T>, Buffer: buffer) -> (GetProperTypeFromUnion<T>, number),
    read DeserializeWithOffset: <T>(Node: SerdesNode<T>, Buffer: buffer, Offset: number) -> (GetProperTypeFromUnion<T>, number),
    read Push: <T>(Node: SerdesNode<any> & T, Data: GetTypeFromTypeNode<T>, Buffer: buffer, Offset: number?) -> number,
    read SetWriteBufferSize: (NewSize: number) -> (),
    read Schema: <T>(Tbl: T & { [string]: SerdesNode<any> }) -> Schema<GetTypeFromTypeNodes<T>>,
    read Migrate: (Old: SerdesNode<any>, New: SerdesNode<any>, OldBuf: buffer, OldOffset: number?, NewOffset: number?) -> buffer,
    read SerializeSafe: <T>(Node: SerdesNode<any> & T, Data: GetTypeFromTypeNode<T>, Offset: number?) -> (buffer?, string?),
    read InheritedSchema: <T...>(T...) -> Schema<Inherit<(T...) -> ()>>,
    read GetWriteBuffer: () -> buffer,

    read Types: {
        -- number types
        read U8: SerdesNode<number>,
        read I8: SerdesNode<number>,
        read U16: SerdesNode<number>,
        read I16: SerdesNode<number>,
        read F16: SerdesNode<number>,
        read U24: SerdesNode<number>,
        read I24: SerdesNode<number>,
        read F24: SerdesNode<number>,
        read U32: SerdesNode<number>,
        read I32: SerdesNode<number>,
        read F32: SerdesNode<number>,
        read U40: SerdesNode<number>,
        read I40: SerdesNode<number>,
        read U48: SerdesNode<number>,
        read I48: SerdesNode<number>,
        read F64: SerdesNode<number>,
        read Number: SerdesNode<number>,
        read Int: SerdesNode<number>,
        read UInt: SerdesNode<number>,
        
        -- other primitives
        read Bool: SerdesNode<boolean>,
        read BoolPacked: SerdesNode<{ boolean }>,
        read String: SerdesNode<string>,
        read String8: SerdesNode<string>,
        read String24: SerdesNode<string>,
        read String32: SerdesNode<string>,
        read StringFixed: (Length: number) -> SerdesNode<string>,
        read Buffer: SerdesNode<buffer>,
        read Buffer8: SerdesNode<buffer>,
        read Buffer24: SerdesNode<buffer>,
        read Buffer32: SerdesNode<buffer>,
        read BufferFixed: (Length: number) -> SerdesNode<buffer>,
        read Vector: SerdesNode<Vector3>,
        read VectorF16: SerdesNode<Vector3>,
        read VectorF24: SerdesNode<Vector3>,
        read VectorU8: SerdesNode<Vector3>,
        read VectorI8: SerdesNode<Vector3>,
        read VectorU16: SerdesNode<Vector3>,
        read VectorI16: SerdesNode<Vector3>,
        read VectorU24: SerdesNode<Vector3>,
        read VectorI24: SerdesNode<Vector3>,

        -- collection types
        read Array: <T>(Node: SerdesNode<any> & T) -> SerdesNode<{ GetTypeFromTypeNode<T> }>,
        read Array8: <T>(Node: SerdesNode<any> & T) -> SerdesNode<{ GetTypeFromTypeNode<T> }>,
        read Array24: <T>(Node: SerdesNode<any> & T) -> SerdesNode<{ GetTypeFromTypeNode<T> }>,
        read Array32: <T>(Node: SerdesNode<any> & T) -> SerdesNode<{ GetTypeFromTypeNode<T> }>,
        read ArrayFixed: <T>(Node: SerdesNode<any> & T, Length: number) -> SerdesNode<{ GetTypeFromTypeNode<T> }>,
        read Struct: <T>(Tbl: T & { [string]: SerdesNode<any> }) -> SerdesNode<GetTypeFromTypeNodes<T>>,
        read DeltaStruct: <T>(Tbl: T & { [string]: SerdesNode<any> }) -> SerdesNode<Optional<GetTypeFromTypeNodes<T>>>,
        read DeltaStruct16: <T>(Tbl: T & { [string]: SerdesNode<any> }) -> SerdesNode<Optional<GetTypeFromTypeNodes<T>>>,
        read Map: <K, V>(KeyNode: SerdesNode<any> & K, ValueNode: SerdesNode<any> & V) -> SerdesNode<{ [GetTypeFromTypeNode<K>]: GetTypeFromTypeNode<V> }>,
        read Map8: <K, V>(KeyNode: SerdesNode<any> & K, ValueNode: SerdesNode<any> & V) -> SerdesNode<{ [GetTypeFromTypeNode<K>]: GetTypeFromTypeNode<V> }>,
        read Map24: <K, V>(KeyNode: SerdesNode<any> & K, ValueNode: SerdesNode<any> & V) -> SerdesNode<{ [GetTypeFromTypeNode<K>]: GetTypeFromTypeNode<V> }>,        
        read Map32: <K, V>(KeyNode: SerdesNode<any> & K, ValueNode: SerdesNode<any> & V) -> SerdesNode<{ [GetTypeFromTypeNode<K>]: GetTypeFromTypeNode<V> }>,
        read MapFixed: <K, V>(KeyNode: SerdesNode<any> & K, ValueNode: SerdesNode<any> & V, Length: number) -> SerdesNode<{ [GetTypeFromTypeNode<K>]: GetTypeFromTypeNode<V> }>,
        read Optional: <T>(Node: SerdesNode<T>) -> SerdesNode<T?>,
        read InheritedStruct: <T...>(T...) -> SerdesNode<Inherit<(T...) -> ()>>,

        -- roblox types
        read Instance: SerdesNode<Instance>,
        read Instance24: SerdesNode<Instance>,
        read SerInstance: <T, K>(ClassName: T | keyof<Instances> | "", Schema: K & { [string]: any }) -> SerdesNode<GetInstanceType<T, Instances, Instance, K>>,
        read CFrame: SerdesNode<CFrame>,
        read QCFrame: SerdesNode<CFrame>,
        read CFrameF16: SerdesNode<CFrame>,
        read CFrameF24: SerdesNode<CFrame>,
        read QCFrameF16: SerdesNode<CFrame>,
        read QCFrameF24: SerdesNode<CFrame>,
        read CFrameQuant: SerdesNode<CFrame>,
        read CFrameQuant8: SerdesNode<CFrame>,
        read CFrameQuantF16: SerdesNode<CFrame>,
        read CFrameQuant8F16: SerdesNode<CFrame>,
        read Color3: SerdesNode<Color3>,
        read BrickColor: SerdesNode<BrickColor>,
        read Color3Round: SerdesNode<Color3>,
        read Enum: <T>(EnumType: T & Enum) -> SerdesNode<GetEnumItem<T>>,
        read Enum8: <T>(EnumType: T & Enum) -> SerdesNode<GetEnumItem<T>>,
        read EnumObj: SerdesNode<Enum>,
        read Vector2: SerdesNode<Vector2>,
        read Vector2F16: SerdesNode<Vector2>,
        read Vector2F24: SerdesNode<Vector2>,
        read Vector2U8: SerdesNode<Vector2>,
        read Vector2I8: SerdesNode<Vector2>,
        read Vector2U16: SerdesNode<Vector2>,
        read Vector2I16: SerdesNode<Vector2>,
        read Vector2U24: SerdesNode<Vector2>,
        read Vector2I24: SerdesNode<Vector2>,
        read UDim2: SerdesNode<UDim2>,
        read UDim2Scale: SerdesNode<UDim2>,
        read UDim2Offset: SerdesNode<UDim2>,
        read UDim2OffsetI16: SerdesNode<UDim2>,
        read UDim2ScaleF24: SerdesNode<UDim2>,
        read UDim2Quant: (ScaleMin: number, ScaleMax: number) -> SerdesNode<UDim2>,
        read Axes: SerdesNode<Axes>,
        read Faces: SerdesNode<Faces>,
        read DateTime: SerdesNode<DateTime>,
        read DateTimeF32: SerdesNode<DateTime>,
        read DateTimeInt: SerdesNode<DateTime>,
        read FloatCurveKey: SerdesNode<FloatCurveKey>,
        read PhysicalProperties: SerdesNode<PhysicalProperties>,
        read RaycastResult: SerdesNode<RaycastResult>,
        read RaycastResult8: SerdesNode<RaycastResult>,
        read NumberSequenceKeypoint: SerdesNode<NumberSequenceKeypoint>,
        read NumberSequence: SerdesNode<NumberSequence>,
        read NumberRange: SerdesNode<NumberRange>,
        read NumberRangeF32: SerdesNode<NumberRange>,
        read Font: SerdesNode<Font>,
        read Ray: SerdesNode<Ray>,
        read TweenInfo: SerdesNode<TweenInfo>,
        read ColorSequenceKeypoint: SerdesNode<ColorSequenceKeypoint>,
        read ColorSequence: SerdesNode<ColorSequence>,
    },
}


return nil