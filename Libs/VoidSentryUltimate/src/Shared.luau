const CreateTable = table.create
const CreateBuffer = buffer.create

const F16Scale = CreateTable(64, 0)
for i = 0, 63 do
    const e = i % 32
    const s = if e == 0 then 0 else math.ldexp(1, e - 25)
    F16Scale[i + 1] = if i >= 32 and e ~= 0 then -s else s
end

const F24Scale = CreateTable(512, 0)
for i = 0, 511 do
    const e = i % 256
    const s = if e == 0 then 0 else math.ldexp(1, e - 142)
    F24Scale[i + 1] = if i >= 256 and e ~= 0 then -s else s
end

const FloatConverter = CreateBuffer(4)

return {
    F16Scale = F16Scale,
    F24Scale = F24Scale,
    FloatConverter = FloatConverter
}