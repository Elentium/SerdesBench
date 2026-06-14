------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const AncestorOpenEffects = require("./AncestorOpenEffects")
const OpenDivisions = require("../Data/OpenDivisions")
const OpenFrames = require("../Data/OpenFrames")
const Types = require("../Types")
const UIEffects = require("./UIEffects")
const FrameToggler = {}

------------------------------------------------------------
-- TYPES
------------------------------------------------------------
type Node = Types.OpenFrameNode

------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------
const DefaultDivision = "Default"

------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------
local GlobalDebounce = false

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
local function GetOrCreateNode(GuiObject: GuiObject, Division: string): Node
	local ExistingNode = OpenFrames[GuiObject]
	if ExistingNode then
		ExistingNode.Division = Division
		return ExistingNode
	end

	local Node: Node = {
		OriginalSize = GuiObject.Size,
		Division = Division,
	}
	OpenFrames[GuiObject] = Node
	return Node
end

local function ReleaseGlobalDebounce(): ()
	GlobalDebounce = false
end

local function ClearDivisionFrame(Division: string, GuiObject: GuiObject): ()
	if OpenDivisions[Division] == GuiObject then
		OpenDivisions[Division] = nil
	end
end

local function WhenAllComplete(Count: number, OnComplete: () -> ()): () -> ()
	local Remaining = Count
	return function()
		Remaining -= 1
		if Remaining <= 0 then
			OnComplete()
		end
	end
end

local function AnimateFrameClose(GuiObject: GuiObject, Node: Node, OnComplete: () -> ()): ()
	AncestorOpenEffects.ResetForFrameClose(GuiObject)

	const Tween = UIEffects.ApplyFrameCloseEffect(GuiObject)
	Tween.Completed:Once(function()
		GuiObject.Visible = false
		ClearDivisionFrame(Node.Division, GuiObject)
		OnComplete()
	end)
end

local function AnimateFrameOpen(GuiObject: GuiObject, Node: Node, OnComplete: () -> ()): ()
	GuiObject.Size = Node.OriginalSize
	const TaggedDescendants = AncestorOpenEffects.PrepareForFrameOpen(GuiObject)

	GuiObject.Size = UDim2.fromScale(0, 0)
	GuiObject.Visible = true
	const Tween = UIEffects.ApplyFrameOpenEffect(GuiObject, Node.OriginalSize)
	const DescendantStartDelay = AncestorOpenEffects.GetFrameOpenHalfDelay(Node.OriginalSize)
	AncestorOpenEffects.PlayStaggered(GuiObject, TaggedDescendants, DescendantStartDelay)

	Tween.Completed:Once(function()
		OpenDivisions[Node.Division] = GuiObject
		OnComplete()
	end)
end

function FrameToggler.CloseFrame(GuiObject: GuiObject, Division: string?): ()
	if GlobalDebounce or not GuiObject.Visible then
		return
	end

	const ResolvedDivision = Division or DefaultDivision
	const Node = GetOrCreateNode(GuiObject, ResolvedDivision)

	GlobalDebounce = true
	AnimateFrameClose(GuiObject, Node, ReleaseGlobalDebounce)
end

function FrameToggler.OpenFrame(GuiObject: GuiObject, Division: string?): ()
	if GlobalDebounce or GuiObject.Visible then
		return
	end

	const ResolvedDivision = Division or DefaultDivision
	const Node = GetOrCreateNode(GuiObject, ResolvedDivision)

	const OpenFrameInDivision = OpenDivisions[ResolvedDivision]
	if OpenFrameInDivision and OpenFrameInDivision ~= GuiObject then
		if OpenFrameInDivision.Visible then
			GlobalDebounce = true
			OpenDivisions[ResolvedDivision] = GuiObject
			const OpenNode = GetOrCreateNode(OpenFrameInDivision, ResolvedDivision)
			const OnSwitchComplete = WhenAllComplete(2, ReleaseGlobalDebounce)
			AnimateFrameClose(OpenFrameInDivision, OpenNode, OnSwitchComplete)
			AnimateFrameOpen(GuiObject, Node, OnSwitchComplete)
			return
		end
		OpenDivisions[ResolvedDivision] = nil
	end

	GlobalDebounce = true
	AnimateFrameOpen(GuiObject, Node, ReleaseGlobalDebounce)
end

function FrameToggler.ToggleFrame(GuiObject: GuiObject, Division: string?): ()
	if GuiObject.Visible then
		FrameToggler.CloseFrame(GuiObject, Division)
	else
		FrameToggler.OpenFrame(GuiObject, Division)
	end
end

return FrameToggler
