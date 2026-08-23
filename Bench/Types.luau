export type BenchmarkResult = {
	-- in milliseconds
	Total: number,
	-- in microseconds
	Min: number,
	Max: number,
	Avg: number,
	Med: number,
}

export type BenchmarkEntry = {
	Name: string,
	Lib: string,
	Result: BenchmarkResult,
}

export type Section = {
	SectionName: string,
	Nodes: { BenchmarkEntry },
}

export type Results = { Section }

export type LibScore = {
	Lib: string,
	AvgMed: number,
	Count: number,
}

return nil
