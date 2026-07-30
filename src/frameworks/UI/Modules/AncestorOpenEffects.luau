------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
const RunService = game:GetService("RunService")

------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const EffectsConfig = require("../Config/EffectsConfig")
const OriginalSizes = require("../Data/OriginalSizes")
const UIEffects = require("./UIEffects")
const AncestorOpenEffects = {}

------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------
const TagName = "UI_OpenEffectOnAncestorOpen"
const StaggerFrames = 2

------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------
const FramePlaybackGenerations: { [GuiObject]: number } = {}

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
const function GetPlaybackGeneration(Frame: GuiObject): number
	return FramePlaybackGenerations[Frame] or 0
end

const function CacheOriginalSize(GuiObject: GuiObject): UDim2
	if not OriginalSizes[GuiObject] then
		OriginalSizes[GuiObject] = GuiObject.Size
	end
	return OriginalSizes[GuiObject]
end

const function CompareBySnapshot(
	Left: { AbsolutePosition: Vector2, Order: number },
	Right: { AbsolutePosition: Vector2, Order: number }
): boolean
	if Left.AbsolutePosition.Y ~= Right.AbsolutePosition.Y then
		return Left.AbsolutePosition.Y < Right.AbsolutePosition.Y
	end

	if Left.AbsolutePosition.X ~= Right.AbsolutePosition.X then
		return Left.AbsolutePosition.X < Right.AbsolutePosition.X
	end

	return Left.Order < Right.Order
end

const function GetPriority(GuiObject: GuiObject): number?
	const Priority = GuiObject:GetAttribute("Priority")
	if typeof(Priority) == "number" then
		return Priority
	end
	return nil
end

const function GetTaggedDescendantSnapshots(
	Frame: GuiObject
): { { Object: GuiObject, AbsolutePosition: Vector2, Order: number } }
	local Snapshots: { { Object: GuiObject, AbsolutePosition: Vector2, Order: number } } = {}
	local Order = 0

	for _, Instance: Instance in Frame:QueryDescendants(`.{TagName}`) do
		if Instance:IsA("GuiObject") then
			Order += 1
			table.insert(Snapshots, {
				Object = Instance,
				AbsolutePosition = Instance.AbsolutePosition,
				Order = Order,
			})
		end
	end

	return Snapshots
end

const function GetSortedTaggedDescendants(Frame: GuiObject): { GuiObject }
	const Snapshots = GetTaggedDescendantSnapshots(Frame)

	local WithPriority: { { Object: GuiObject, Priority: number, AbsolutePosition: Vector2, Order: number } } = {}
	local WithoutPriority: { { Object: GuiObject, AbsolutePosition: Vector2, Order: number } } = {}

	for _, Snapshot in Snapshots do
		const Priority = GetPriority(Snapshot.Object)
		if Priority then
			table.insert(WithPriority, {
				Object = Snapshot.Object,
				Priority = Priority,
				AbsolutePosition = Snapshot.AbsolutePosition,
				Order = Snapshot.Order,
			})
		else
			table.insert(WithoutPriority, Snapshot)
		end
	end

	table.sort(WithPriority, function(Left, Right): boolean
		if Left.Priority ~= Right.Priority then
			return Left.Priority < Right.Priority
		end
		return CompareBySnapshot(Left, Right)
	end)

	table.sort(WithoutPriority, CompareBySnapshot)

	local TotalCount = #WithPriority + #WithoutPriority
	local SortedDescendants: { GuiObject } = {}
	local Used: { [GuiObject]: boolean } = {}
	local WithoutPriorityIndex = 1

	for Slot = 1, TotalCount do
		local Placed = false

		for _, Entry in WithPriority do
			if not Used[Entry.Object] and Entry.Priority == Slot then
				table.insert(SortedDescendants, Entry.Object)
				Used[Entry.Object] = true
				Placed = true
				break
			end
		end

		if not Placed and WithoutPriorityIndex <= #WithoutPriority then
			const Descendant = WithoutPriority[WithoutPriorityIndex].Object
			table.insert(SortedDescendants, Descendant)
			Used[Descendant] = true
			WithoutPriorityIndex += 1
		end
	end

	for _, Entry in WithPriority do
		if not Used[Entry.Object] then
			table.insert(SortedDescendants, Entry.Object)
		end
	end

	while WithoutPriorityIndex <= #WithoutPriority do
		table.insert(SortedDescendants, WithoutPriority[WithoutPriorityIndex].Object)
		WithoutPriorityIndex += 1
	end

	return SortedDescendants
end

function AncestorOpenEffects.PrepareForFrameOpen(Frame: GuiObject): { GuiObject }
	const TaggedDescendants = GetSortedTaggedDescendants(Frame)

	for _, Descendant: GuiObject in TaggedDescendants do
		if not Descendant.Visible then
			continue
		end

		CacheOriginalSize(Descendant)
		Descendant.Size = UDim2.fromScale(0, 0)
	end

	return TaggedDescendants
end

const function WaitFrames(FrameCount: number): ()
	for _ = 1, FrameCount do
		RunService.Heartbeat:Wait()
	end
end

function AncestorOpenEffects.ResetForFrameClose(Frame: GuiObject): ()
	FramePlaybackGenerations[Frame] = GetPlaybackGeneration(Frame) + 1

	for _, Descendant: GuiObject in GetSortedTaggedDescendants(Frame) do
		UIEffects.CancelOpenEffectOnAncestorOpen(Descendant)

		const CachedSize = OriginalSizes[Descendant]
		if CachedSize then
			Descendant.Size = CachedSize
		else
			Descendant.Size = UDim2.fromScale(0, 0)
		end
	end
end

function AncestorOpenEffects.GetFrameOpenHalfDelay(TargetSize: UDim2): number
	const EffectConfig = EffectsConfig.OpenFrameEffect(TargetSize)
	return EffectConfig.Info.Time / 2
end

function AncestorOpenEffects.PlayStaggered(Frame: GuiObject, TaggedDescendants: { GuiObject }, StartDelay: number?): ()
	const PlaybackGeneration = GetPlaybackGeneration(Frame)

	task.spawn(function()
		if StartDelay and StartDelay > 0 then
			task.wait(StartDelay)
			if GetPlaybackGeneration(Frame) ~= PlaybackGeneration then
				return
			end
		end

		for Index, Descendant: GuiObject in TaggedDescendants do
			if GetPlaybackGeneration(Frame) ~= PlaybackGeneration then
				return
			end

			if Index > 1 then
				WaitFrames(StaggerFrames)
				if GetPlaybackGeneration(Frame) ~= PlaybackGeneration then
					return
				end
			end

			if not Descendant.Parent or not Descendant.Visible then
				continue
			end

			const TargetSize = OriginalSizes[Descendant]
			if TargetSize then
				UIEffects.ApplyOpenEffectOnAncestorOpen(Descendant, TargetSize)
			end
		end
	end)
end

return AncestorOpenEffects
