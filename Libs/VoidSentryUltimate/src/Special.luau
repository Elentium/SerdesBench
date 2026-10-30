--!optimize 2
const Definitions = require("./Definitions")

type SerdesNode<T> = Definitions.SerdesNode<T>
type Ser<T> = Definitions.Ser<T>
type Des<T> = Definitions.Des<T>

const SER = 1
const DES = 2

@native const function Optional<T>(Node: SerdesNode<T>): SerdesNode<T?>
    const OptionalNode: SerdesNode<T?> = {}

    @native const function OptionalSer(Value: T?, Buf: buffer, Cur: number): number
        const Exists = Value ~= nil
        buffer.writeu8(Buf, Cur, Exists and 1 or 0)
        Cur += 1
        if Exists then
            const Ser = Node[SER] :: Ser<T>
            Cur = Ser(Value :: T, Buf, Cur)
        end
    
        return Cur
    end

    @native const function OptionalDes(Buf: buffer, Cur: number): (T?, number)
        const Exists = buffer.readu8(Buf, Cur)
        Cur += 1
        if Exists == 1 then
            const Des = Node[DES] :: Des<T>
            local Result
            Result, Cur = Des(Buf, Cur)
            return Result, Cur
        end

        return nil, Cur
    end

    OptionalNode[SER] = OptionalSer
    OptionalNode[DES] = OptionalDes

    return OptionalNode
end

return {
    Optional = Optional
}