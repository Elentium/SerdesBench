--!strict
------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const OpenFrames = require("../Data/OpenFrames")
const Types = require("../Types")
const UIEffects = require("./UIEffects")
const FrameToggler = {}

------------------------------------------------------------
-- TYPES
------------------------------------------------------------
type Node = Types.OpenFrameNode

------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------
const FrameVisibilityHandlers: { [boolean]: (Node: Node, Frame: Frame) -> () } = {
	[true] = function(Node: Node, Frame: Frame)
		const Tween = UIEffects.ApplyFrameCloseEffect(Frame)
		Tween.Completed:Once(function()
			Node.Debounce = false
			Frame.Visible = false
			Frame.Size = Node.OriginalSize
		end)
	end,
	[false] = function(Node: Node, Frame: Frame)
		Frame.Visible = true
		Frame.Size = UDim2.fromScale(0, 0)
		const Tween = UIEffects.ApplyFrameOpenEffect(Frame, Node.OriginalSize)
		Tween.Completed:Once(function()
			Node.Debounce = false
		end)
	end
}

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
function FrameToggler.ToggleFrame(Frame: Frame): ()
	local Node: Node = OpenFrames[Frame]
	if not Node then
		Node = {
			OriginalSize = Frame.Size,
			Debounce = false,
		}
		OpenFrames[Frame] = Node
	elseif Node.Debounce then
		return
	end
	Node.Debounce = true
	FrameVisibilityHandlers[Frame.Visible](Node, Frame)
end

return FrameToggler
