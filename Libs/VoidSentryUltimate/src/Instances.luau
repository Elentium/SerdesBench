--!optimize 2
const Definitions = require("./Definitions")

type SerdesNode<T> = Definitions.SerdesNode<T>
type Instances = Definitions.Instances
type GetInstanceType<T0, T1, T2, T3> = Definitions.GetInstanceType<T0, T1, T2, T3>
type Ser<T> = Definitions.Ser<T>
type Des<T> = Definitions.Des<T>

const SER = 1
const DES = 2

const InstanceMaps = require("./InstanceMaps")
const IdMap: { [number]: Instance } = InstanceMaps.IdMap
const InstanceMap: { [Instance]: number } = InstanceMaps.ReverseMap

const CreateTable = table.create
const NewInstance = Instance.new
const SortTable = table.sort
const Pcall = pcall

const InstanceNode: SerdesNode<Instance> = {}
do
    @native const function InstanceSer(Value: Instance, Buf: buffer, Cur: number): number
        const Id = InstanceMap[Value]
        if Id then
            buffer.writeu16(Buf, Cur, Id)
            return Cur + 2
        end

        error(`Instance {Value:GetFullName()} not found in InstanceMap, make sure INSTANCE_SERIALIZATION_ENABLED is set to true`)
    end

    @native const function InstanceDes(Buf: buffer, Cur: number): (Instance, number)
        const Id = buffer.readu16(Buf, Cur)
        const Value = IdMap[Id]
        if not Value then -- lowk wanted to remove this check for another micro perf gain but this error could be useful for debugging
            error(`Instance not found by id {Id}, make sure INSTANCE_SERIALIZATION_ENABLED is set to true and the Instance is reachable by this context.`)
        end

        return Value, Cur + 2
    end

    InstanceNode[SER] = InstanceSer
    InstanceNode[DES] = InstanceDes
    InstanceNode.IsInstanceNode = true
end

const Instance24: SerdesNode<Instance> = {}
do
    @native const function Instance24Ser(Value: Instance, Buf: buffer, Cur: number): number
        const Id = InstanceMap[Value]
        if Id then
            buffer.writeu16(Buf, Cur, Id)
            buffer.writeu8(Buf, Cur + 2, bit32.rshift(Id, 16))
            return Cur + 3
        end

        error(`Instance {Value:GetFullName()} not found in InstanceMap, make sure INSTANCE_SERIALIZATION_ENABLED is set to true`)
    end

    @native const function Instance24Des(Buf: buffer, Cur: number): (Instance, number)
        const Id = buffer.readu16(Buf, Cur) + buffer.readu8(Buf, Cur + 2) * 65536
        const Value = IdMap[Id]
        if not Value then
            error(`Instance not found by id {Id}, make sure INSTANCE_SERIALIZATION_ENABLED is set to true and the Instance is reachable by this context.`)
        end

        return Value, Cur + 3
    end

    Instance24[SER] = Instance24Ser
    Instance24[DES] = Instance24Des
    Instance24.IsInstanceNode = true
end

@native const function SerInstance<T, K>(ClassName: T | keyof<Instances> | "", Schema: K & { [string]: SerdesNode<any> }): SerdesNode<GetInstanceType<T, Instances, Instance, K>>
    const SerInstanceNode: SerdesNode<GetInstanceType<T, Instances, Instance, K>> = {}
    const Keys = {}
    local Idx = 0
    for Key in Schema :: { [string]: any } do
        Idx += 1
        Keys[Idx] = Key
    end
    SortTable(Keys)

    const Writes = CreateTable<<Ser<any>>>(Idx)
    const Reads = CreateTable<<Des<any>>>(Idx)
    const InstanceProps: { [string]: true } = {}

    local Success, TestInst: any = Pcall(Instance.new, ClassName, nil)
    if not Success then
        error(`Invalid classname {ClassName}, it cannot be instantiated`)
    end

    for i, Key in Keys do
        const Node = Schema[Key]
        Writes[i] = Node[SER] :: Ser<any>
        Reads[i] = Node[DES] :: Des<any>

        Success = Pcall(function()
            const _ = TestInst[Key]
        end)

        if not Success and Node.IsInstanceNode then
            InstanceProps[Key] = true
        end
    end

    @native const function SerInstanceSer(Value: Instance, Buf: buffer, Cur: number): number
        const Keys = Keys
        const Writes = Writes
        for i, Key in Keys do
            Cur = Writes[i]((Value :: any)[Key], Buf, Cur)
        end
    
        return Cur
    end

    @native const function SerInstanceDes(Buf: buffer, Cur: number): (GetInstanceType<T, Instances, Instance, K>, number)
        const Inst = NewInstance(ClassName) :: any
        const Keys = Keys
        const Reads = Reads
        local Child
        for i, Key in Keys do
            if InstanceProps[Key] then
                Child, Cur = Reads[i](Buf, Cur)
                Child.Name = Key
                Child.Parent = Inst
                continue
            end

            Inst[Key], Cur = Reads[i](Buf, Cur)
        end

        return Inst, Cur
    end

    SerInstanceNode[SER] = SerInstanceSer
    SerInstanceNode[DES] = SerInstanceDes
    SerInstanceNode.IsInstanceNode = true
    return SerInstanceNode
end

return {
    Instance = InstanceNode,
    Instance24 = Instance24,
    SerInstance = SerInstance
}