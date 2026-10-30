-- This file contains functions for inlining structs with 0-16 fields
--!optimize 2
const Definitions = require("./Definitions")
type Ser<T> = Definitions.Ser<T>
type Des<T> = Definitions.Des<T>
type SerdesNode<T> = Definitions.SerdesNode<T>

const SER = 1
const DES = 2

const InlineStruct: { [number]: ({ [string]: any }) -> SerdesNode<{ [string]: any }> } = {}

@native const function Zero(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

    const Node: { [any]: any } = {}
    @native const function StructSer(_: { [string]: any }, _: buffer, Cur: number): number
        return Cur
    end
    @native const function StructDes(_: buffer, Cur: number): ({ [string]: any }, number)
        return {}, Cur
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function One(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads
    const Key: string = Keys[1]
    const Ser: Ser<any> = Writes[1]
    const Des: Des<any> = Reads[1]

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = Ser(Value[Key], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const Value, Next = Des(Buf, Cur)
        return { [Key] = Value }, Next
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Two(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys: { string } = Struct.Keys
    const Writes: { Ser<any> } = Struct.Writes
    const Reads: { Des<any> } = Struct.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur =  s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
        const v2, c2 = d2(Buf, c1)
        return {
            [k1] = v1,
            [k2] = v2
        }, c2
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Three(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

    const k1 = Keys[1]
    const s1 = Writes[1]
    const d1 = Reads[1]

    const k2 = Keys[2]
    const s2 = Writes[2]
    const d2 = Reads[2]

    const k3 = Keys[3]
    const s3 = Writes[3]
    const d3 = Reads[3]

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        return {
            [k1] = v1,
            [k2] = v2,
            [k3] = v3
        }, c3
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Four(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
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

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Five(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4, [k5] = v5
        }, c5
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Six(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        Cur = s6(Value[k6], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        return {
            [k1] = v1, [k2] = v2, [k3] = v3, [k4] = v4, [k5] = v5, [k6] = v6
        }, c6
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Seven(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        Cur = s6(Value[k6], Buf, Cur)
        Cur = s7(Value[k7], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        return {
            [k1]=v1, [k2]=v2, [k3]=v3, [k4]=v4, [k5]=v5, [k6]=v6, [k7]=v7
        }, c7
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Eight(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        Cur = s6(Value[k6], Buf, Cur)
        Cur = s7(Value[k7], Buf, Cur)
        Cur = s8(Value[k8], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        return {
            [k1]=v1, [k2]=v2, [k3]=v3, [k4]=v4, [k5]=v5, [k6]=v6, [k7]=v7, [k8]=v8
        }, c8
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Nine(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        Cur = s6(Value[k6], Buf, Cur)
        Cur = s7(Value[k7], Buf, Cur)
        Cur = s8(Value[k8], Buf, Cur)
        Cur = s9(Value[k9], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
        const v2, c2 = d2(Buf, c1)
        const v3, c3 = d3(Buf, c2)
        const v4, c4 = d4(Buf, c3)
        const v5, c5 = d5(Buf, c4)
        const v6, c6 = d6(Buf, c5)
        const v7, c7 = d7(Buf, c6)
        const v8, c8 = d8(Buf, c7)
        const v9, c9 = d9(Buf, c8)
        return {
            [k1]=v1, [k2]=v2, [k3]=v3, [k4]=v4, [k5]=v5, [k6]=v6, [k7]=v7, [k8]=v8, [k9]=v9
        }, c9
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Ten(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        Cur = s6(Value[k6], Buf, Cur)
        Cur = s7(Value[k7], Buf, Cur)
        Cur = s8(Value[k8], Buf, Cur)
        Cur = s9(Value[k9], Buf, Cur)
        Cur = s10(Value[k10], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
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
            [k1]=v1, [k2]=v2, [k3]=v3, [k4]=v4, [k5]=v5, [k6]=v6, [k7]=v7, [k8]=v8, [k9]=v9, [k10]=v10
        }, c10
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Eleven(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        Cur = s6(Value[k6], Buf, Cur)
        Cur = s7(Value[k7], Buf, Cur)
        Cur = s8(Value[k8], Buf, Cur)
        Cur = s9(Value[k9], Buf, Cur)
        Cur = s10(Value[k10], Buf, Cur)
        Cur = s11(Value[k11], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
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
            [k1]=v1, [k2]=v2, [k3]=v3, [k4]=v4, [k5]=v5, [k6]=v6, [k7]=v7, [k8]=v8, [k9]=v9, [k10]=v10, [k11]=v11
        }, c11
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Twelve(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        Cur = s6(Value[k6], Buf, Cur)
        Cur = s7(Value[k7], Buf, Cur)
        Cur = s8(Value[k8], Buf, Cur)
        Cur = s9(Value[k9], Buf, Cur)
        Cur = s10(Value[k10], Buf, Cur)
        Cur = s11(Value[k11], Buf, Cur)
        Cur = s12(Value[k12], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
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
            [k1]=v1, [k2]=v2, [k3]=v3, [k4]=v4, [k5]=v5, [k6]=v6, [k7]=v7, [k8]=v8, [k9]=v9, [k10]=v10, [k11]=v11, [k12]=v12
        }, c12
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Thirteen(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        Cur = s6(Value[k6], Buf, Cur)
        Cur = s7(Value[k7], Buf, Cur)
        Cur = s8(Value[k8], Buf, Cur)
        Cur = s9(Value[k9], Buf, Cur)
        Cur = s10(Value[k10], Buf, Cur)
        Cur = s11(Value[k11], Buf, Cur)
        Cur = s12(Value[k12], Buf, Cur)
        Cur = s13(Value[k13], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
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
            [k1]=v1, [k2]=v2, [k3]=v3, [k4]=v4, [k5]=v5, [k6]=v6, [k7]=v7,
            [k8]=v8, [k9]=v9, [k10]=v10, [k11]=v11, [k12]=v12, [k13]=v13
        }, c13
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Fourteen(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        Cur = s6(Value[k6], Buf, Cur)
        Cur = s7(Value[k7], Buf, Cur)
        Cur = s8(Value[k8], Buf, Cur)
        Cur = s9(Value[k9], Buf, Cur)
        Cur = s10(Value[k10], Buf, Cur)
        Cur = s11(Value[k11], Buf, Cur)
        Cur = s12(Value[k12], Buf, Cur)
        Cur = s13(Value[k13], Buf, Cur)
        Cur = s14(Value[k14], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
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
            [k1]=v1, [k2]=v2, [k3]=v3, [k4]=v4, [k5]=v5, [k6]=v6, [k7]=v7,
            [k8]=v8, [k9]=v9, [k10]=v10, [k11]=v11, [k12]=v12, [k13]=v13, [k14]=v14
        }, c14
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Fifteen(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        Cur = s6(Value[k6], Buf, Cur)
        Cur = s7(Value[k7], Buf, Cur)
        Cur = s8(Value[k8], Buf, Cur)
        Cur = s9(Value[k9], Buf, Cur)
        Cur = s10(Value[k10], Buf, Cur)
        Cur = s11(Value[k11], Buf, Cur)
        Cur = s12(Value[k12], Buf, Cur)
        Cur = s13(Value[k13], Buf, Cur)
        Cur = s14(Value[k14], Buf, Cur)
        Cur = s15(Value[k15], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
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
            [k1]=v1, [k2]=v2, [k3]=v3, [k4]=v4, [k5]=v5, [k6]=v6, [k7]=v7,
            [k8]=v8, [k9]=v9, [k10]=v10, [k11]=v11, [k12]=v12, [k13]=v13, [k14]=v14, [k15]=v15
        }, c15
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

@native const function Sixteen(Struct: { [string]: any }): SerdesNode<{ [string]: any }>
    const Keys = Struct.Keys
    const Writes = Struct.Writes
    const Reads = Struct.Reads

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

    const Node: { [any]: any } = {}
    @native const function StructSer(Value: { [string]: any }, Buf: buffer, Cur: number): number
        Cur = s1(Value[k1], Buf, Cur)
        Cur = s2(Value[k2], Buf, Cur)
        Cur = s3(Value[k3], Buf, Cur)
        Cur = s4(Value[k4], Buf, Cur)
        Cur = s5(Value[k5], Buf, Cur)
        Cur = s6(Value[k6], Buf, Cur)
        Cur = s7(Value[k7], Buf, Cur)
        Cur = s8(Value[k8], Buf, Cur)
        Cur = s9(Value[k9], Buf, Cur)
        Cur = s10(Value[k10], Buf, Cur)
        Cur = s11(Value[k11], Buf, Cur)
        Cur = s12(Value[k12], Buf, Cur)
        Cur = s13(Value[k13], Buf, Cur)
        Cur = s14(Value[k14], Buf, Cur)
        Cur = s15(Value[k15], Buf, Cur)
        Cur = s16(Value[k16], Buf, Cur)
        return Cur
    end
    @native const function StructDes(Buf: buffer, Cur: number): ({ [string]: any }, number)
        const v1, c1 = d1(Buf, Cur)
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
            [k1]=v1, [k2]=v2, [k3]=v3, [k4]=v4, [k5]=v5, [k6]=v6, [k7]=v7,
            [k8]=v8, [k9]=v9, [k10]=v10, [k11]=v11, [k12]=v12, [k13]=v13, [k14]=v14,
            [k15]=v15, [k16]=v16
        }, c16
    end

    Node[SER] = StructSer
    Node[DES] = StructDes
    Node.Keys = Keys
    Node.Writes = Writes
    Node.Reads = Reads
    return Node
end

InlineStruct[0]  = Zero
InlineStruct[1]  = One
InlineStruct[2]  = Two
InlineStruct[3]  = Three
InlineStruct[4]  = Four
InlineStruct[5]  = Five
InlineStruct[6]  = Six
InlineStruct[7]  = Seven
InlineStruct[8]  = Eight
InlineStruct[9]  = Nine
InlineStruct[10] = Ten
InlineStruct[11] = Eleven
InlineStruct[12] = Twelve
InlineStruct[13] = Thirteen
InlineStruct[14] = Fourteen
InlineStruct[15] = Fifteen
InlineStruct[16] = Sixteen

return InlineStruct