------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const OpenHitboxes = require("../Data/OpenHitboxes")
const FrameToggler = require("../Modules/FrameToggler")
const PlayerGuiFrameResolver = require("../Modules/PlayerGuiFrameResolver")
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

	const FrameToToggle = PlayerGuiFrameResolver.ResolveFrame(FrameToToggleObj.Value)
	if not FrameToToggle then
		return
	end
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

function TagsConfig.UI_FrameHitbox(Object: BasePart)
	const FrameToToggleObj: ObjectValue? = Object:FindFirstChild("FrameToToggle")
		or Object:FindFirstChild("FrameToOpen")
	if not FrameToToggleObj or not FrameToToggleObj.Value then
		return
	end

	const FrameToToggle = PlayerGuiFrameResolver.ResolveFrame(FrameToToggleObj.Value)
	if not FrameToToggle then
		return
	end

	const Division = Object:GetAttribute("Division")
	OpenHitboxes[Object] = {
		GuiObject = FrameToToggle,
		Division = if typeof(Division) == "string" then Division else "Default",
	}
end

return TagsConfig :: { [string]: (Instance) -> () }
