--!strict
------------------------------------------------------------
-- MODULES
------------------------------------------------------------
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
local function GetOrCreateNode(Frame: Frame, Division: string): Node
	local ExistingNode = OpenFrames[Frame]
	if ExistingNode then
		ExistingNode.Division = Division
		return ExistingNode
	end

	local Node: Node = {
		OriginalSize = Frame.Size,
		Division = Division,
	}
	OpenFrames[Frame] = Node
	return Node
end

local function ReleaseGlobalDebounce(): ()
	GlobalDebounce = false
end

local function ClearDivisionFrame(Division: string, Frame: Frame): ()
	if OpenDivisions[Division] == Frame then
		OpenDivisions[Division] = nil
	end
end

local function AnimateFrameClose(Frame: Frame, Node: Node, OnComplete: () -> ()): ()
	const Tween = UIEffects.ApplyFrameCloseEffect(Frame)
	Tween.Completed:Once(function()
		Frame.Visible = false
		Frame.Size = Node.OriginalSize
		ClearDivisionFrame(Node.Division, Frame)
		OnComplete()
	end)
end

local function AnimateFrameOpen(Frame: Frame, Node: Node, OnComplete: () -> ()): ()
	Frame.Visible = true
	Frame.Size = UDim2.fromScale(0, 0)
	const Tween = UIEffects.ApplyFrameOpenEffect(Frame, Node.OriginalSize)
	Tween.Completed:Once(function()
		OpenDivisions[Node.Division] = Frame
		OnComplete()
	end)
end

function FrameToggler.ToggleFrame(Frame: Frame, Division: string?): ()
	if GlobalDebounce then
		return
	end

	const ResolvedDivision = Division or DefaultDivision
	const Node = GetOrCreateNode(Frame, ResolvedDivision)

	if Frame.Visible then
		GlobalDebounce = true
		AnimateFrameClose(Frame, Node, ReleaseGlobalDebounce)
		return
	end

	const OpenFrameInDivision = OpenDivisions[ResolvedDivision]
	if OpenFrameInDivision and OpenFrameInDivision ~= Frame then
		if OpenFrameInDivision.Visible then
			GlobalDebounce = true
			const OpenNode = GetOrCreateNode(OpenFrameInDivision, ResolvedDivision)
			AnimateFrameClose(OpenFrameInDivision, OpenNode, function()
				AnimateFrameOpen(Frame, Node, ReleaseGlobalDebounce)
			end)
			return
		end
		OpenDivisions[ResolvedDivision] = nil
	end

	GlobalDebounce = true
	AnimateFrameOpen(Frame, Node, ReleaseGlobalDebounce)
end

return FrameToggler
