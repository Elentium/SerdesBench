------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const AncestorOpenEffects = require("./AncestorOpenEffects")
const OpenDivisions = require("../Data/OpenDivisions")
const OpenFrames = require("../Data/OpenFrames")
const Types = require("../Types")
const PlayerGuiFrameResolver = require("./PlayerGuiFrameResolver")
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
const HideFrameChildName = "HideFrame"

------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------
local GlobalDebounce = false

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
const function GetOrCreateNode(GuiObject: GuiObject, Division: string): Node
	const ExistingNode = OpenFrames[GuiObject]
	if ExistingNode then
		ExistingNode.Division = Division
		return ExistingNode
	end

	const Node: Node = {
		OriginalSize = GuiObject.Size,
		Division = Division,
	}
	OpenFrames[GuiObject] = Node
	return Node
end

const function ReleaseGlobalDebounce(): ()
	GlobalDebounce = false
end

const function ClearDivisionFrame(Division: string, GuiObject: GuiObject): ()
	if OpenDivisions[Division] == GuiObject then
		OpenDivisions[Division] = nil
	end
end

const function ApplyHideFrameChildren(GuiObject: GuiObject, Visible: boolean): ()
	for _, Child in GuiObject:GetChildren() do
		if Child.Name == HideFrameChildName and Child:IsA("ObjectValue") then
			const Value = Child.Value
			if Value and Value:IsA("GuiObject") then
				const Resolved = PlayerGuiFrameResolver.ResolveFrame(Value)
				if Resolved then
					Resolved.Visible = Visible
				end
			end
		end
	end
end

const function WhenAllComplete(Count: number, OnComplete: () -> ()): () -> ()
	local Remaining = Count
	return function()
		Remaining -= 1
		if Remaining <= 0 then
			OnComplete()
		end
	end
end

const function AnimateFrameClose(GuiObject: GuiObject, Node: Node, OnComplete: () -> ()): ()
	ApplyHideFrameChildren(GuiObject, true)
	AncestorOpenEffects.ResetForFrameClose(GuiObject)

	const Tween = UIEffects.ApplyFrameCloseEffect(GuiObject)
	Tween.Completed:Once(function()
		GuiObject.Visible = false
		ClearDivisionFrame(Node.Division, GuiObject)
		OnComplete()
	end)
end

const function AnimateFrameOpen(GuiObject: GuiObject, Node: Node, OnComplete: () -> ()): ()
	GuiObject.Size = Node.OriginalSize
	const TaggedDescendants = AncestorOpenEffects.PrepareForFrameOpen(GuiObject)

	GuiObject.Size = UDim2.fromScale(0, 0)
	GuiObject.Visible = true
	ApplyHideFrameChildren(GuiObject, false)
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
