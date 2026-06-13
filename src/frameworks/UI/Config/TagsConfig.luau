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
	const FrameToToggleObj: ObjectValue? = UIObject:FindFirstChild("FrameToToggle")
	if not FrameToToggleObj or not FrameToToggleObj.Value then
		return
	end

	const FrameToToggle: Frame = FrameToToggleObj.Value
	UIObject.MouseButton1Click:Connect(function()
		const Division = UIObject:GetAttribute("Division")
		FrameToggler.ToggleFrame(
			FrameToToggle,
			if typeof(Division) == "string" then Division else nil
		)
	end)
end

function TagsConfig.UI_RotatingEffect(UIObject: GuiObject)
	UIEffects.ApplyRotateEffect(UIObject)
end

return TagsConfig