--!optimize 2
const Definitions = require("./Definitions")

type SerdesNode<T> = Definitions.SerdesNode<T>
type Ser<T> = Definitions.Ser<T>
type Des<T> = Definitions.Des<T>

const SER = 1
const DES = 2

@native
const function Map<K, V>(KeyNode: SerdesNode<K>, ValueNode: SerdesNode<V>): SerdesNode<{ [K]: V }>
	const MapNode: SerdesNode<{ [K]: V }> = {}

	const KeySer = KeyNode[SER] :: Ser<K>
	const KeyDes = KeyNode[DES] :: Des<K>

	const ValueSer = ValueNode[SER] :: Ser<V>
	const ValueDes = ValueNode[DES] :: Des<V>

	@native
	const function MapSer(Map: { [K]: V }, Buf: buffer, Cur: number): number
		const Start = Cur
		local Len = 0
		Cur += 2
		const KeySer = KeySer
		const ValueSer = ValueSer
		for Key, Value in Map do
			Len += 1
			Cur = KeySer(Key, Buf, Cur)
			Cur = ValueSer(Value, Buf, Cur)
		end
		buffer.writeu16(Buf, Start, Len)

		return Cur
	end

	@native
	const function MapDes(Buf: buffer, Cur: number): ({ [K]: V }, number)
		const Len = buffer.readu16(Buf, Cur)
		const Map = {}
		Cur += 2
		const KeyDes = KeyDes
		const ValueDes = ValueDes
		local Key, Val
		for _ = 1, Len do
			Key, Cur = KeyDes(Buf, Cur)
			Val, Cur = ValueDes(Buf, Cur)
			Map[Key] = Val
		end
		return Map, Cur
	end

	MapNode[SER] = MapSer
	MapNode[DES] = MapDes

	return MapNode
end

@native
const function Map8<K, V>(KeyNode: SerdesNode<K>, ValueNode: SerdesNode<V>): SerdesNode<{ [K]: V }>
	const Map8Node: SerdesNode<{ [K]: V }> = {}

	const KeySer = KeyNode[SER] :: Ser<K>
	const KeyDes = KeyNode[DES] :: Des<K>

	const ValueSer = ValueNode[SER] :: Ser<V>
	const ValueDes = ValueNode[DES] :: Des<V>

	@native
	const function Map8Ser(Map: { [K]: V }, Buf: buffer, Cur: number): number
		const Start = Cur
		local Len = 0
		Cur += 1
		const KeySer = KeySer
		const ValueSer = ValueSer
		for Key, Value in Map do
			Len += 1
			Cur = KeySer(Key, Buf, Cur)
			Cur = ValueSer(Value, Buf, Cur)
		end
		buffer.writeu8(Buf, Start, Len)

		return Cur
	end

	@native
	const function Map8Des(Buf: buffer, Cur: number): ({ [K]: V }, number)
		const Len = buffer.readu8(Buf, Cur)
		const Map = {}
		Cur += 1
		const KeyDes = KeyDes
		const ValueDes = ValueDes
		local Key, Val
		for _ = 1, Len do
			Key, Cur = KeyDes(Buf, Cur)
			Val, Cur = ValueDes(Buf, Cur)
			Map[Key] = Val
		end
		return Map, Cur
	end

	Map8Node[SER] = Map8Ser
	Map8Node[DES] = Map8Des

	return Map8Node
end

@native
const function Map24<K, V>(KeyNode: SerdesNode<K>, ValueNode: SerdesNode<V>): SerdesNode<{ [K]: V }>
	const Map24Node: SerdesNode<{ [K]: V }> = {}

	const KeySer = KeyNode[SER] :: Ser<K>
	const KeyDes = KeyNode[DES] :: Des<K>

	const ValueSer = ValueNode[SER] :: Ser<V>
	const ValueDes = ValueNode[DES] :: Des<V>

	@native
	const function Map24Ser(Map: { [K]: V }, Buf: buffer, Cur: number): number
		const Start = Cur
		local Len = 0
		Cur += 3
		const KeySer = KeySer
		const ValueSer = ValueSer
		for Key, Value in Map do
			Len += 1
			Cur = KeySer(Key, Buf, Cur)
			Cur = ValueSer(Value, Buf, Cur)
		end
		buffer.writeu16(Buf, Start, Len)
		buffer.writeu8(Buf, Start + 2, bit32.rshift(Len, 16))

		return Cur
	end

	@native
	const function Map24Des(Buf: buffer, Cur: number): ({ [K]: V }, number)
		const Len = buffer.readu16(Buf, Cur) + buffer.readu8(Buf, Cur + 2) * 65536
		const Map = {}
		Cur += 3
		const KeyDes = KeyDes
		const ValueDes = ValueDes
		local Key, Val
		for _ = 1, Len do
			Key, Cur = KeyDes(Buf, Cur)
			Val, Cur = ValueDes(Buf, Cur)
			Map[Key] = Val
		end
		return Map, Cur
	end

	Map24Node[SER] = Map24Ser
	Map24Node[DES] = Map24Des

	return Map24Node
end

@native
const function Map32<K, V>(KeyNode: SerdesNode<K>, ValueNode: SerdesNode<V>): SerdesNode<{ [K]: V }>
	const Map32Node: SerdesNode<{ [K]: V }> = {}

	const KeySer = KeyNode[SER] :: Ser<K>
	const KeyDes = KeyNode[DES] :: Des<K>

	const ValueSer = ValueNode[SER] :: Ser<V>
	const ValueDes = ValueNode[DES] :: Des<V>

	@native
	const function Map32Ser(Map: { [K]: V }, Buf: buffer, Cur: number): number
		const Start = Cur
		local Len = 0
		Cur += 4
		const KeySer = KeySer
		const ValueSer = ValueSer
		for Key, Value in Map do
			Len += 1
			Cur = KeySer(Key, Buf, Cur)
			Cur = ValueSer(Value, Buf, Cur)
		end
		buffer.writeu32(Buf, Start, Len)

		return Cur
	end

	@native
	const function Map32Des(Buf: buffer, Cur: number): ({ [K]: V }, number)
		const Len = buffer.readu32(Buf, Cur)
		const Map = {}
		Cur += 4
		const KeyDes = KeyDes
		const ValueDes = ValueDes
		local Key, Val
		for _ = 1, Len do
			Key, Cur = KeyDes(Buf, Cur)
			Val, Cur = ValueDes(Buf, Cur)
			Map[Key] = Val
		end
		return Map, Cur
	end

	Map32Node[SER] = Map32Ser
	Map32Node[DES] = Map32Des

	return Map32Node
end

@native
const function MapFixed<K, V>(KeyNode: SerdesNode<K>, ValueNode: SerdesNode<V>, Length: number): SerdesNode<{ [K]: V }>
	const MapFixedNode: SerdesNode<{ [K]: V }> = {}

	const KeySer = KeyNode[SER] :: Ser<K>
	const KeyDes = KeyNode[DES] :: Des<K>

	const ValueSer = ValueNode[SER] :: Ser<V>
	const ValueDes = ValueNode[DES] :: Des<V>

	@native
	const function MapFixedSer(Map: { [K]: V }, Buf: buffer, Cur: number): number
		const KeySer = KeySer
		const ValueSer = ValueSer
		for Key, Value in Map do
			Cur = KeySer(Key, Buf, Cur)
			Cur = ValueSer(Value, Buf, Cur)
		end

		return Cur
	end

	@native
	const function MapFixedDes(Buf: buffer, Cur: number): ({ [K]: V }, number)
		const Map = {}
		const KeyDes = KeyDes
		const ValueDes = ValueDes
		local Key, Val
		for _ = 1, Length do
			Key, Cur = KeyDes(Buf, Cur)
			Val, Cur = ValueDes(Buf, Cur)
			Map[Key] = Val
		end
		return Map, Cur
	end

	MapFixedNode[SER] = MapFixedSer
	MapFixedNode[DES] = MapFixedDes

	return MapFixedNode
end

return {
	Map = Map,
	Map8 = Map8,
	Map24 = Map24,
	Map32 = Map32,
	MapFixed = MapFixed,
}
