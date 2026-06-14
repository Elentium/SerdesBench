------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
const CollectionService = game:GetService("CollectionService")
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
local FramePlaybackGenerations: { [GuiObject]: number } = {}

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
local function GetPlaybackGeneration(Frame: GuiObject): number
	return FramePlaybackGenerations[Frame] or 0
end

local function CacheOriginalSize(GuiObject: GuiObject): UDim2
	if not OriginalSizes[GuiObject] then
		OriginalSizes[GuiObject] = GuiObject.Size
	end
	return OriginalSizes[GuiObject]
end

local function CompareByAbsolutePosition(Left: GuiObject, Right: GuiObject): boolean
	local LeftPosition = Left.AbsolutePosition
	local RightPosition = Right.AbsolutePosition

	if LeftPosition.Y ~= RightPosition.Y then
		return LeftPosition.Y < RightPosition.Y
	end

	return LeftPosition.X < RightPosition.X
end

local function GetPriority(GuiObject: GuiObject): number?
	const Priority = GuiObject:GetAttribute("Priority")
	if typeof(Priority) == "number" then
		return Priority
	end
	return nil
end

local function GetSortedTaggedDescendants(Frame: GuiObject): { GuiObject }
	local TaggedDescendants: { GuiObject } = {}

	for _, Instance: Instance in CollectionService:GetTagged(TagName) do
		if Instance:IsA("GuiObject") and Instance:IsDescendantOf(Frame) then
			table.insert(TaggedDescendants, Instance)
		end
	end

	local WithPriority: { { Object: GuiObject, Priority: number } } = {}
	local WithoutPriority: { GuiObject } = {}

	for _, Descendant: GuiObject in TaggedDescendants do
		const Priority = GetPriority(Descendant)
		if Priority then
			table.insert(WithPriority, { Object = Descendant, Priority = Priority })
		else
			table.insert(WithoutPriority, Descendant)
		end
	end

	table.sort(WithPriority, function(Left, Right): boolean
		if Left.Priority ~= Right.Priority then
			return Left.Priority < Right.Priority
		end
		return CompareByAbsolutePosition(Left.Object, Right.Object)
	end)

	table.sort(WithoutPriority, CompareByAbsolutePosition)

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
			const Descendant = WithoutPriority[WithoutPriorityIndex]
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
		table.insert(SortedDescendants, WithoutPriority[WithoutPriorityIndex])
		WithoutPriorityIndex += 1
	end

	return SortedDescendants
end

function AncestorOpenEffects.PrepareForFrameOpen(Frame: GuiObject): { GuiObject }
	const TaggedDescendants = GetSortedTaggedDescendants(Frame)

	for _, Descendant: GuiObject in TaggedDescendants do
		CacheOriginalSize(Descendant)
		Descendant.Size = UDim2.fromScale(0, 0)
		Descendant.Visible = true
	end

	return TaggedDescendants
end

local function WaitFrames(FrameCount: number): ()
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

function AncestorOpenEffects.PlayStaggered(
	Frame: GuiObject,
	TaggedDescendants: { GuiObject },
	StartDelay: number?
): ()
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

			if not Descendant.Parent then
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
