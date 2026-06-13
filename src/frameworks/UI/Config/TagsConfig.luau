------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const FrameToggler = require("../Modules/FrameToggler")
const UIEffects = require("../Modules/UIEffects")
const TagsConfig = {}

------------------------------------------------------------
-- TAGS MAP ([TagName]: Handler(Instance) -> ())
------------------------------------------------------------
function TagsConfig.UI_AnimatedButton(UIObject: GuiButton)
	UIObject.MouseEnter:Connect(function()
		UIEffects.ApplyHoverEffect(UIObject)
	end)
	UIObject.MouseLeave:Connect(function()
		UIEffects.ApplyHoverOutEffect(UIObject)
	end)
	UIObject.MouseButton1Down:Connect(function()
		UIEffects.ApplyClickEffect(UIObject)
	end)
	UIObject.MouseButton1Up:Connect(function()
		UIEffects.ApplyClickOutEffect(UIObject)
	end)
end

function TagsConfig.UI_HoverEffect(UIObject: GuiObject)
	UIObject.MouseEnter:Connect(function()
		UIEffects.ApplyHoverEffect(UIObject)
	end)

	UIObject.MouseLeave:Connect(function()
		UIEffects.ApplyHoverOutEffect(UIObject)
	end)
end

function TagsConfig.UI_FrameTogglerButton(UIObject: GuiButton)
	const FrameToOpenObj: ObjectValue? = UIObject:FindFirstChild("FrameToOpen")
	if not FrameToOpenObj or not FrameToOpenObj.Value then
		return
	end

	const FrameToOpen: Frame = FrameToOpenObj.Value
	UIObject.MouseButton1Click:Connect(function()
		FrameToggler.ToggleFrame(FrameToOpen)
	end)
end

function TagsConfig.UI_RotatingEffect(UIObject: GuiObject)
	UIEffects.ApplyRotateEffect(UIObject)
end

return TagsConfig