--!optimize 2
const SER = 1
const DES = 2

const Definitions = require("./Definitions")
const Shared = require("./Shared")

const FloatConverter = Shared.FloatConverter
const F16Scale = Shared.F16Scale
const F24Scale = Shared.F24Scale

const NewCFrame = CFrame.new
const CreateTable = table.create
const NewCFrameFromOrientation = CFrame.fromOrientation

const Pi = math.pi
const DoublePi = Pi * 2
const HalfPi = Pi / 2

type SerdesNode<T> = Definitions.SerdesNode<T>

const CFrameNode: SerdesNode<CFrame> = {}
do
    @native const function CFrameSer(Value: CFrame, Buf: buffer, Cur: number): number
        const 
        x, y, z, 
        R0, R01, R02, 
        R10, R11, R12, 
        R20, R21, R22 
        = Value:GetComponents()

        buffer.writef32(Buf, Cur, x)
        buffer.writef32(Buf, Cur + 4, y)
        buffer.writef32(Buf, Cur + 8, z)
        buffer.writef32(Buf, Cur + 12, R0)
        buffer.writef32(Buf, Cur + 16, R01)
        buffer.writef32(Buf, Cur + 20, R02)
        buffer.writef32(Buf, Cur + 24, R10)
        buffer.writef32(Buf, Cur + 28, R11)
        buffer.writef32(Buf, Cur + 32, R12)
        buffer.writef32(Buf, Cur + 36, R20)
        buffer.writef32(Buf, Cur + 40, R21)
        buffer.writef32(Buf, Cur + 44, R22)
    
        return Cur + 48
    end
    
    @native const function CFrameDes(Buf: buffer, Cur: number): (CFrame, number)

        const x = buffer.readf32(Buf, Cur)
        const y = buffer.readf32(Buf, Cur + 4)
        const z = buffer.readf32(Buf, Cur + 8)
        const R0 = buffer.readf32(Buf, Cur + 12)
        const R01 = buffer.readf32(Buf, Cur + 16)
        const R02 = buffer.readf32(Buf, Cur + 20)
        const R10 = buffer.readf32(Buf, Cur + 24)
        const R11 = buffer.readf32(Buf, Cur + 28)
        const R12 = buffer.readf32(Buf, Cur + 32)
        const R20 = buffer.readf32(Buf, Cur + 36)
        const R21 = buffer.readf32(Buf, Cur + 40)
        const R22 = buffer.readf32(Buf, Cur + 44)

        return NewCFrame(x, y, z, R0, R01, R02, R10, R11, R12, R20, R21, R22), Cur + 48
    end

    CFrameNode[SER] = CFrameSer
    CFrameNode[DES] = CFrameDes
end

const Quant8Angle = CreateTable(256, 0)
for i = 0, 255 do
    Quant8Angle[i + 1] = (i / 255) * DoublePi - Pi
end

const CFrameQuant8: SerdesNode<CFrame> = {}
do
    @native const function CFrameQuant8Ser(Value: CFrame, Buf: buffer, Cur: number): number
        const Pos = Value.Position

        buffer.writef32(Buf, Cur, Pos.X)
        buffer.writef32(Buf, Cur + 4, Pos.Y)
        buffer.writef32(Buf, Cur + 8, Pos.Z)

        const rx, ry, rz = Value:ToOrientation()

        const normalYaw = math.min((ry + Pi) / DoublePi, 1)
        const normalPitch = math.min((rx + HalfPi) / Pi, 1)
        const normalRoll = math.min((rz + Pi) / DoublePi, 1)

        buffer.writeu8(Buf, Cur + 12, math.round(normalYaw * 255))
        buffer.writeu8(Buf, Cur + 13, math.round(normalPitch * 255))
        buffer.writeu8(Buf, Cur + 14, math.round(normalRoll * 255))

        return Cur + 15
    end

    @native const function CFrameQuant8Des(Buf: buffer, Cur: number): (CFrame, number)
        const x = buffer.readf32(Buf, Cur)
        const y = buffer.readf32(Buf, Cur + 4)
        const z = buffer.readf32(Buf, Cur + 8)

        const Angles = Quant8Angle
        const ry = Angles[buffer.readu8(Buf, Cur + 12) + 1]
        const rx = Angles[buffer.readu8(Buf, Cur + 13) + 1] * 0.5
        const rz = Angles[buffer.readu8(Buf, Cur + 14) + 1]

        return NewCFrameFromOrientation(rx, ry, rz) + Vector3.new(x, y, z), Cur + 15
    end

    CFrameQuant8[SER] = CFrameQuant8Ser
    CFrameQuant8[DES] = CFrameQuant8Des
end

const CFrameQuant8F16: SerdesNode<CFrame> = {}
do
    @native const function CFrameQuant8F16Ser(Value: CFrame, Buf: buffer, Cur: number): number
        const Pos = Value.Position

        const FloatConverter = FloatConverter

        do
            buffer.writef32(FloatConverter, 0, Pos.X)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, Pos.Y)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 2, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, Pos.Z)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 4, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end

        const rx, ry, rz = Value:ToOrientation()

        const normalYaw = math.min((ry + Pi) / DoublePi, 1)
        const normalPitch = math.min((rx + HalfPi) / Pi, 1)
        const normalRoll = math.min((rz + Pi) / DoublePi, 1)

        buffer.writeu8(Buf, Cur + 6, math.round(normalYaw * 255))
        buffer.writeu8(Buf, Cur + 7, math.round(normalPitch * 255))
        buffer.writeu8(Buf, Cur + 8, math.round(normalRoll * 255))

        return Cur + 9
    end

    @native const function CFrameQuant8F16Des(Buf: buffer, Cur: number): (CFrame, number)
        const Scale = F16Scale
        const Px = buffer.readu16(Buf, Cur)
        const x = bit32.bor(bit32.band(Px, 0x3FF), 0x400) * Scale[bit32.rshift(Px, 10) + 1]
        const Py = buffer.readu16(Buf, Cur + 2)
        const y = bit32.bor(bit32.band(Py, 0x3FF), 0x400) * Scale[bit32.rshift(Py, 10) + 1]
        const Pz = buffer.readu16(Buf, Cur + 4)
        const z = bit32.bor(bit32.band(Pz, 0x3FF), 0x400) * Scale[bit32.rshift(Pz, 10) + 1]

        const Angles = Quant8Angle
        const ry = Angles[buffer.readu8(Buf, Cur + 6) + 1]
        const rx = Angles[buffer.readu8(Buf, Cur + 7) + 1] * 0.5
        const rz = Angles[buffer.readu8(Buf, Cur + 8) + 1]

        return NewCFrameFromOrientation(rx, ry, rz) + Vector3.new(x, y, z), Cur + 9
    end

    CFrameQuant8F16[SER] = CFrameQuant8F16Ser
    CFrameQuant8F16[DES] = CFrameQuant8F16Des
end

const CFrameQuant: SerdesNode<CFrame> = {}
do
    @native const function CFrameQuantSer(Value: CFrame, Buf: buffer, Cur: number): number
        const Pos = Value.Position

        buffer.writef32(Buf, Cur, Pos.X)
        buffer.writef32(Buf, Cur + 4, Pos.Y)
        buffer.writef32(Buf, Cur + 8, Pos.Z)

        const rx, ry, rz = Value:ToOrientation()

        const normalYaw = math.min((ry + Pi) / DoublePi, 1)
        const normalPitch = math.min((rx + HalfPi) / Pi, 1)
        const normalRoll = math.min((rz + Pi) / DoublePi, 1)

        buffer.writeu16(Buf, Cur + 12, math.round(normalYaw * 65535))
        buffer.writeu16(Buf, Cur + 14, math.round(normalPitch * 65535))
        buffer.writeu16(Buf, Cur + 16, math.round(normalRoll * 65535))

        return Cur + 18
    end

    @native const function CFrameQuantDes(Buf: buffer, Cur: number): (CFrame, number)
        const x = buffer.readf32(Buf, Cur)
        const y = buffer.readf32(Buf, Cur + 4)
        const z = buffer.readf32(Buf, Cur + 8)
        const Yaw = buffer.readu16(Buf, Cur + 12)
        const Pitch = buffer.readu16(Buf, Cur + 14)
        const Roll = buffer.readu16(Buf, Cur + 16)

        const ry = (Yaw / 65535) * DoublePi - Pi
        const rx = (Pitch / 65535) * Pi - HalfPi
        const rz = (Roll / 65535) * DoublePi - Pi

        return NewCFrameFromOrientation(rx, ry, rz) + Vector3.new(x, y, z), Cur + 18
    end

    CFrameQuant[SER] = CFrameQuantSer
    CFrameQuant[DES] = CFrameQuantDes
end

const CFrameQuantF16: SerdesNode<CFrame> = {}
do
    @native const function CFrameQuantF16Ser(Value: CFrame, Buf: buffer, Cur: number): number
        const Pos = Value.Position

        const FloatConverter = FloatConverter

        do
            buffer.writef32(FloatConverter, 0, Pos.X)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, Pos.Y)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 2, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, Pos.Z)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 4, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end

        const rx, ry, rz = Value:ToOrientation()

        const normalYaw = math.min((ry + Pi) / DoublePi, 1)
        const normalPitch = math.min((rx + HalfPi) / Pi, 1)
        const normalRoll = math.min((rz + Pi) / DoublePi, 1)

        buffer.writeu16(Buf, Cur + 6, math.round(normalYaw * 65535))
        buffer.writeu16(Buf, Cur + 8, math.round(normalPitch * 65535))
        buffer.writeu16(Buf, Cur + 10, math.round(normalRoll * 65535))

        return Cur + 12
    end

    @native const function CFrameQuantF16Des(Buf: buffer, Cur: number): (CFrame, number)
        const Scale = F16Scale
        const Px = buffer.readu16(Buf, Cur)
        const x = bit32.bor(bit32.band(Px, 0x3FF), 0x400) * Scale[bit32.rshift(Px, 10) + 1]
        const Py = buffer.readu16(Buf, Cur + 2)
        const y = bit32.bor(bit32.band(Py, 0x3FF), 0x400) * Scale[bit32.rshift(Py, 10) + 1]
        const Pz = buffer.readu16(Buf, Cur + 4)
        const z = bit32.bor(bit32.band(Pz, 0x3FF), 0x400) * Scale[bit32.rshift(Pz, 10) + 1]
        const Yaw = buffer.readu16(Buf, Cur + 6)
        const Pitch = buffer.readu16(Buf, Cur + 8)
        const Roll = buffer.readu16(Buf, Cur + 10)

        const ry = (Yaw / 65535) * DoublePi - Pi
        const rx = (Pitch / 65535) * Pi - HalfPi
        const rz = (Roll / 65535) * DoublePi - Pi

        return NewCFrameFromOrientation(rx, ry, rz) + Vector3.new(x, y, z), Cur + 12
    end

    CFrameQuantF16[SER] = CFrameQuantF16Ser
    CFrameQuantF16[DES] = CFrameQuantF16Des
end

const QCFrame: SerdesNode<CFrame> = {}
do
    @native const function QCFrameSer(Value: CFrame, Buf: buffer, Cur: number): number
        const
        x, y, z,
        R00, R01, R02,
        R10, R11, R12,
        R20, R21, R22
        = Value:GetComponents()

        local qx, qy, qz, qw
        const Trace = R00 + R11 + R22
        if Trace > 0 then
            const S = math.sqrt(Trace + 1) * 2
            qx, qy, qz, qw = (R21 - R12) / S, (R02 - R20) / S, (R10 - R01) / S, S * 0.25
        elseif R00 > R11 and R00 > R22 then
            const S = math.sqrt(1 + R00 - R11 - R22) * 2
            qx, qy, qz, qw = S * 0.25, (R01 + R10) / S, (R02 + R20) / S, (R21 - R12) / S
        elseif R11 > R22 then
            const S = math.sqrt(1 + R11 - R00 - R22) * 2
            qx, qy, qz, qw = (R01 + R10) / S, S * 0.25, (R12 + R21) / S, (R02 - R20) / S
        else
            const S = math.sqrt(1 + R22 - R00 - R11) * 2
            qx, qy, qz, qw = (R02 + R20) / S, (R12 + R21) / S, S * 0.25, (R10 - R01) / S
        end

        buffer.writef32(Buf, Cur, x)
        buffer.writef32(Buf, Cur + 4, y)
        buffer.writef32(Buf, Cur + 8, z)
        buffer.writef32(Buf, Cur + 12, qx)
        buffer.writef32(Buf, Cur + 16, qy)
        buffer.writef32(Buf, Cur + 20, qz)
        buffer.writef32(Buf, Cur + 24, qw)

        return Cur + 28
    end

    @native const function QCFrameDes(Buf: buffer, Cur: number): (CFrame, number)
        const x = buffer.readf32(Buf, Cur)
        const y = buffer.readf32(Buf, Cur + 4)
        const z = buffer.readf32(Buf, Cur + 8)
        const qx = buffer.readf32(Buf, Cur + 12)
        const qy = buffer.readf32(Buf, Cur + 16)
        const qz = buffer.readf32(Buf, Cur + 20)
        const qw = buffer.readf32(Buf, Cur + 24)

        return NewCFrame(x, y, z, qx, qy, qz, qw), Cur + 28
    end

    QCFrame[SER] = QCFrameSer
    QCFrame[DES] = QCFrameDes
end

const CFrameF24: SerdesNode<CFrame> = {}
do
    @native const function CFrameF24Ser(Value: CFrame, Buf: buffer, Cur: number): number
        const
        x, y, z,
        R00, R01, R02,
        R10, R11, R12,
        R20, R21, R22
        = Value:GetComponents()

        const FloatConverter = FloatConverter

        buffer.writef32(Buf, Cur + 32, R22)
        buffer.writef32(Buf, Cur + 29, R21)
        buffer.writef32(Buf, Cur + 26, R20)
        buffer.writef32(Buf, Cur + 23, R12)
        buffer.writef32(Buf, Cur + 20, R11)
        buffer.writef32(Buf, Cur + 17, R10)
        buffer.writef32(Buf, Cur + 14, R02)
        buffer.writef32(Buf, Cur + 11, R01)
        buffer.writef32(Buf, Cur + 8, R00)
        buffer.writef32(Buf, Cur + 5, z)
        buffer.writef32(Buf, Cur + 2, y)
        buffer.writef32(FloatConverter, 0, x)
        buffer.writeu16(Buf, Cur, buffer.readu16(FloatConverter, 1))
        buffer.writeu8(Buf, Cur + 2, buffer.readu8(FloatConverter, 3))

        return Cur + 36
    end

    @native const function CFrameF24Des(Buf: buffer, Cur: number): (CFrame, number)
        const Scale = F24Scale
        const Px = bit32.band(buffer.readu32(Buf, Cur), 0xFFFFFF)
        const x = bit32.bor(bit32.band(Px, 0x7FFF), 0x8000) * Scale[bit32.rshift(Px, 15) + 1]
        const Py = bit32.rshift(buffer.readu32(Buf, Cur + 2), 8)
        const y = bit32.bor(bit32.band(Py, 0x7FFF), 0x8000) * Scale[bit32.rshift(Py, 15) + 1]
        const Pz = bit32.rshift(buffer.readu32(Buf, Cur + 5), 8)
        const z = bit32.bor(bit32.band(Pz, 0x7FFF), 0x8000) * Scale[bit32.rshift(Pz, 15) + 1]
        const PR00 = bit32.rshift(buffer.readu32(Buf, Cur + 8), 8)
        const R00 = bit32.bor(bit32.band(PR00, 0x7FFF), 0x8000) * Scale[bit32.rshift(PR00, 15) + 1]
        const PR01 = bit32.rshift(buffer.readu32(Buf, Cur + 11), 8)
        const R01 = bit32.bor(bit32.band(PR01, 0x7FFF), 0x8000) * Scale[bit32.rshift(PR01, 15) + 1]
        const PR02 = bit32.rshift(buffer.readu32(Buf, Cur + 14), 8)
        const R02 = bit32.bor(bit32.band(PR02, 0x7FFF), 0x8000) * Scale[bit32.rshift(PR02, 15) + 1]
        const PR10 = bit32.rshift(buffer.readu32(Buf, Cur + 17), 8)
        const R10 = bit32.bor(bit32.band(PR10, 0x7FFF), 0x8000) * Scale[bit32.rshift(PR10, 15) + 1]
        const PR11 = bit32.rshift(buffer.readu32(Buf, Cur + 20), 8)
        const R11 = bit32.bor(bit32.band(PR11, 0x7FFF), 0x8000) * Scale[bit32.rshift(PR11, 15) + 1]
        const PR12 = bit32.rshift(buffer.readu32(Buf, Cur + 23), 8)
        const R12 = bit32.bor(bit32.band(PR12, 0x7FFF), 0x8000) * Scale[bit32.rshift(PR12, 15) + 1]
        const PR20 = bit32.rshift(buffer.readu32(Buf, Cur + 26), 8)
        const R20 = bit32.bor(bit32.band(PR20, 0x7FFF), 0x8000) * Scale[bit32.rshift(PR20, 15) + 1]
        const PR21 = bit32.rshift(buffer.readu32(Buf, Cur + 29), 8)
        const R21 = bit32.bor(bit32.band(PR21, 0x7FFF), 0x8000) * Scale[bit32.rshift(PR21, 15) + 1]
        const PR22 = bit32.rshift(buffer.readu32(Buf, Cur + 32), 8)
        const R22 = bit32.bor(bit32.band(PR22, 0x7FFF), 0x8000) * Scale[bit32.rshift(PR22, 15) + 1]

        return NewCFrame(x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22), Cur + 36
    end

    CFrameF24[SER] = CFrameF24Ser
    CFrameF24[DES] = CFrameF24Des
end

const CFrameF16: SerdesNode<CFrame> = {}
do
    @native const function CFrameF16Ser(Value: CFrame, Buf: buffer, Cur: number): number
        const
        x, y, z,
        R00, R01, R02,
        R10, R11, R12,
        R20, R21, R22
        = Value:GetComponents()

        const FloatConverter = FloatConverter

        do
            buffer.writef32(FloatConverter, 0, x)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, y)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 2, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, z)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 4, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, R00)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 6, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, R01)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 8, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, R02)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 10, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, R10)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 12, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, R11)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 14, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, R12)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 16, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, R20)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 18, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, R21)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 20, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, R22)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 22, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end

        return Cur + 24
    end

    @native const function CFrameF16Des(Buf: buffer, Cur: number): (CFrame, number)
        const Scale = F16Scale
        const Px = buffer.readu16(Buf, Cur)
        const x = bit32.bor(bit32.band(Px, 0x3FF), 0x400) * Scale[bit32.rshift(Px, 10) + 1]
        const Py = buffer.readu16(Buf, Cur + 2)
        const y = bit32.bor(bit32.band(Py, 0x3FF), 0x400) * Scale[bit32.rshift(Py, 10) + 1]
        const Pz = buffer.readu16(Buf, Cur + 4)
        const z = bit32.bor(bit32.band(Pz, 0x3FF), 0x400) * Scale[bit32.rshift(Pz, 10) + 1]
        const PR00 = buffer.readu16(Buf, Cur + 6)
        const R00 = bit32.bor(bit32.band(PR00, 0x3FF), 0x400) * Scale[bit32.rshift(PR00, 10) + 1]
        const PR01 = buffer.readu16(Buf, Cur + 8)
        const R01 = bit32.bor(bit32.band(PR01, 0x3FF), 0x400) * Scale[bit32.rshift(PR01, 10) + 1]
        const PR02 = buffer.readu16(Buf, Cur + 10)
        const R02 = bit32.bor(bit32.band(PR02, 0x3FF), 0x400) * Scale[bit32.rshift(PR02, 10) + 1]
        const PR10 = buffer.readu16(Buf, Cur + 12)
        const R10 = bit32.bor(bit32.band(PR10, 0x3FF), 0x400) * Scale[bit32.rshift(PR10, 10) + 1]
        const PR11 = buffer.readu16(Buf, Cur + 14)
        const R11 = bit32.bor(bit32.band(PR11, 0x3FF), 0x400) * Scale[bit32.rshift(PR11, 10) + 1]
        const PR12 = buffer.readu16(Buf, Cur + 16)
        const R12 = bit32.bor(bit32.band(PR12, 0x3FF), 0x400) * Scale[bit32.rshift(PR12, 10) + 1]
        const PR20 = buffer.readu16(Buf, Cur + 18)
        const R20 = bit32.bor(bit32.band(PR20, 0x3FF), 0x400) * Scale[bit32.rshift(PR20, 10) + 1]
        const PR21 = buffer.readu16(Buf, Cur + 20)
        const R21 = bit32.bor(bit32.band(PR21, 0x3FF), 0x400) * Scale[bit32.rshift(PR21, 10) + 1]
        const PR22 = buffer.readu16(Buf, Cur + 22)
        const R22 = bit32.bor(bit32.band(PR22, 0x3FF), 0x400) * Scale[bit32.rshift(PR22, 10) + 1]

        return NewCFrame(x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22), Cur + 24
    end

    CFrameF16[SER] = CFrameF16Ser
    CFrameF16[DES] = CFrameF16Des
end

const QCFrameF24: SerdesNode<CFrame> = {}
do
    @native const function QCFrameF24Ser(Value: CFrame, Buf: buffer, Cur: number): number
        const
        x, y, z,
        R00, R01, R02,
        R10, R11, R12,
        R20, R21, R22
        = Value:GetComponents()

        local qx: number, qy: number, qz: number, qw: number
        const Trace = R00 + R11 + R22
        if Trace > 0 then
            const S = math.sqrt(Trace + 1) * 2
            qx, qy, qz, qw = (R21 - R12) / S, (R02 - R20) / S, (R10 - R01) / S, S * 0.25
        elseif R00 > R11 and R00 > R22 then
            const S = math.sqrt(1 + R00 - R11 - R22) * 2
            qx, qy, qz, qw = S * 0.25, (R01 + R10) / S, (R02 + R20) / S, (R21 - R12) / S
        elseif R11 > R22 then
            const S = math.sqrt(1 + R11 - R00 - R22) * 2
            qx, qy, qz, qw = (R01 + R10) / S, S * 0.25, (R12 + R21) / S, (R02 - R20) / S
        else
            const S = math.sqrt(1 + R22 - R00 - R11) * 2
            qx, qy, qz, qw = (R02 + R20) / S, (R12 + R21) / S, S * 0.25, (R10 - R01) / S
        end

        const FloatConverter = FloatConverter

        buffer.writef32(Buf, Cur + 17, qw)
        buffer.writef32(Buf, Cur + 14, qz)
        buffer.writef32(Buf, Cur + 11, qy)
        buffer.writef32(Buf, Cur + 8, qx)
        buffer.writef32(Buf, Cur + 5, z)
        buffer.writef32(Buf, Cur + 2, y)
        buffer.writef32(FloatConverter, 0, x)
        buffer.writeu16(Buf, Cur, buffer.readu16(FloatConverter, 1))
        buffer.writeu8(Buf, Cur + 2, buffer.readu8(FloatConverter, 3))

        return Cur + 21
    end

    @native const function QCFrameF24Des(Buf: buffer, Cur: number): (CFrame, number)
        const Scale = F24Scale
        const Px = bit32.band(buffer.readu32(Buf, Cur), 0xFFFFFF)
        const x = bit32.bor(bit32.band(Px, 0x7FFF), 0x8000) * Scale[bit32.rshift(Px, 15) + 1]
        const Py = bit32.rshift(buffer.readu32(Buf, Cur + 2), 8)
        const y = bit32.bor(bit32.band(Py, 0x7FFF), 0x8000) * Scale[bit32.rshift(Py, 15) + 1]
        const Pz = bit32.rshift(buffer.readu32(Buf, Cur + 5), 8)
        const z = bit32.bor(bit32.band(Pz, 0x7FFF), 0x8000) * Scale[bit32.rshift(Pz, 15) + 1]
        const Pqx = bit32.rshift(buffer.readu32(Buf, Cur + 8), 8)
        const qx = bit32.bor(bit32.band(Pqx, 0x7FFF), 0x8000) * Scale[bit32.rshift(Pqx, 15) + 1]
        const Pqy = bit32.rshift(buffer.readu32(Buf, Cur + 11), 8)
        const qy = bit32.bor(bit32.band(Pqy, 0x7FFF), 0x8000) * Scale[bit32.rshift(Pqy, 15) + 1]
        const Pqz = bit32.rshift(buffer.readu32(Buf, Cur + 14), 8)
        const qz = bit32.bor(bit32.band(Pqz, 0x7FFF), 0x8000) * Scale[bit32.rshift(Pqz, 15) + 1]
        const Pqw = bit32.rshift(buffer.readu32(Buf, Cur + 17), 8)
        const qw = bit32.bor(bit32.band(Pqw, 0x7FFF), 0x8000) * Scale[bit32.rshift(Pqw, 15) + 1]

        return NewCFrame(x, y, z, qx, qy, qz, qw), Cur + 21
    end

    QCFrameF24[SER] = QCFrameF24Ser
    QCFrameF24[DES] = QCFrameF24Des
end

const QCFrameF16: SerdesNode<CFrame> = {}
do
    @native const function QCFrameF16Ser(Value: CFrame, Buf: buffer, Cur: number): number
        const
        x, y, z,
        R00, R01, R02,
        R10, R11, R12,
        R20, R21, R22
        = Value:GetComponents()

        local qx: number, qy: number, qz: number, qw: number
        const Trace = R00 + R11 + R22
        if Trace > 0 then
            const S = math.sqrt(Trace + 1) * 2
            qx, qy, qz, qw = (R21 - R12) / S, (R02 - R20) / S, (R10 - R01) / S, S * 0.25
        elseif R00 > R11 and R00 > R22 then
            const S = math.sqrt(1 + R00 - R11 - R22) * 2
            qx, qy, qz, qw = S * 0.25, (R01 + R10) / S, (R02 + R20) / S, (R21 - R12) / S
        elseif R11 > R22 then
            const S = math.sqrt(1 + R11 - R00 - R22) * 2
            qx, qy, qz, qw = (R01 + R10) / S, S * 0.25, (R12 + R21) / S, (R02 - R20) / S
        else
            const S = math.sqrt(1 + R22 - R00 - R11) * 2
            qx, qy, qz, qw = (R02 + R20) / S, (R12 + R21) / S, S * 0.25, (R10 - R01) / S
        end

        const FloatConverter = FloatConverter

        do
            buffer.writef32(FloatConverter, 0, x)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, y)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 2, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, z)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 4, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, qx)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 6, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, qy)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 8, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, qz)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 10, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end
        do
            buffer.writef32(FloatConverter, 0, qw)
            const Bits = buffer.readu32(FloatConverter, 0)
            const Sign = bit32.band(bit32.rshift(Bits, 16), 0x8000)
            const Abs = bit32.band(Bits, 0x7FFFFFFF) + 0x1000
            buffer.writeu16(Buf, Cur + 12, if Abs >= 0x47800000 then Sign + 0x7BFF elseif Abs < 0x38800000 then Sign else Sign + bit32.rshift(Abs, 13) - 0x1C000)
        end

        return Cur + 14
    end

    @native const function QCFrameF16Des(Buf: buffer, Cur: number): (CFrame, number)
        const Scale = F16Scale
        const Px = buffer.readu16(Buf, Cur)
        const x = bit32.bor(bit32.band(Px, 0x3FF), 0x400) * Scale[bit32.rshift(Px, 10) + 1]
        const Py = buffer.readu16(Buf, Cur + 2)
        const y = bit32.bor(bit32.band(Py, 0x3FF), 0x400) * Scale[bit32.rshift(Py, 10) + 1]
        const Pz = buffer.readu16(Buf, Cur + 4)
        const z = bit32.bor(bit32.band(Pz, 0x3FF), 0x400) * Scale[bit32.rshift(Pz, 10) + 1]
        const Pqx = buffer.readu16(Buf, Cur + 6)
        const qx = bit32.bor(bit32.band(Pqx, 0x3FF), 0x400) * Scale[bit32.rshift(Pqx, 10) + 1]
        const Pqy = buffer.readu16(Buf, Cur + 8)
        const qy = bit32.bor(bit32.band(Pqy, 0x3FF), 0x400) * Scale[bit32.rshift(Pqy, 10) + 1]
        const Pqz = buffer.readu16(Buf, Cur + 10)
        const qz = bit32.bor(bit32.band(Pqz, 0x3FF), 0x400) * Scale[bit32.rshift(Pqz, 10) + 1]
        const Pqw = buffer.readu16(Buf, Cur + 12)
        const qw = bit32.bor(bit32.band(Pqw, 0x3FF), 0x400) * Scale[bit32.rshift(Pqw, 10) + 1]

        return NewCFrame(x, y, z, qx, qy, qz, qw), Cur + 14
    end

    QCFrameF16[SER] = QCFrameF16Ser
    QCFrameF16[DES] = QCFrameF16Des
end

return {
    CFrame = CFrameNode,
    QCFrame = QCFrame,
    CFrameF24 = CFrameF24,
    CFrameF16 = CFrameF16,
    QCFrameF24 = QCFrameF24,
    QCFrameF16 = QCFrameF16,
    CFrameQuant = CFrameQuant,
    CFrameQuant8 = CFrameQuant8,
    CFrameQuantF16 = CFrameQuantF16,
    CFrameQuant8F16 = CFrameQuant8F16
}