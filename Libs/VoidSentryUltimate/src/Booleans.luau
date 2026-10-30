--!optimize 2
const Definitions = require("./Definitions")

type SerdesNode<T> = Definitions.SerdesNode<T>

const SER = 1
const DES = 2

const Bool: SerdesNode<boolean> = {}
do
    @native const function BoolSer(Value: boolean, Buf: buffer, Cur: number): number
        buffer.writeu8(Buf, Cur, Value and 1 or 0)
        return Cur + 1
    end

    @native const function BoolDes(Buf: buffer, Cur: number): (boolean, number)
        const Value = buffer.readu8(Buf, Cur)
        return Value == 1, Cur + 1
    end

    Bool[SER] = BoolSer
    Bool[DES] = BoolDes
end

const BoolPacked: SerdesNode<{ boolean }> = {}
do
    @native const function BoolPackedSer(Value: { boolean }, Buf: buffer, Cur: number): number
        local Write = 0
        if Value[1] then
			Write += 1
		end
		if Value[2] then
			Write += 2
		end
		if Value[3] then
			Write += 4
		end
		if Value[4] then
			Write += 8
		end
		if Value[5] then
			Write += 16
		end
		if Value[6] then
			Write += 32
		end
		if Value[7] then
			Write += 64
		end
		if Value[8] then
			Write += 128
		end

        buffer.writeu8(Buf, Cur, Write)
        return Cur + 1
    end

    @native const function BoolPackedDes(Buf: buffer, Cur: number): ({ boolean }, number)
        const Byte = buffer.readu8(Buf, Cur)
        return { 
			bit32.btest(Byte, 1),
			bit32.btest(Byte, 2),
			bit32.btest(Byte, 4),
			bit32.btest(Byte, 8),
			bit32.btest(Byte, 16),
			bit32.btest(Byte, 32),
			bit32.btest(Byte, 64),
			bit32.btest(Byte, 128), 
        }, Cur + 1
    end

    BoolPacked[SER] = BoolPackedSer
    BoolPacked[DES] = BoolPackedDes
end

return {
    Bool = Bool,
    BoolPacked = BoolPacked
}