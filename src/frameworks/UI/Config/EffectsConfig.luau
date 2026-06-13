------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const OriginalSizes = require("../Data/OriginalSizes")
const Types = require("../Types")
const EffectsConfig = {}

------------------------------------------------------------
-- TWEEN INFO MAP
------------------------------------------------------------
const TweenInfos = {}
TweenInfos.HoverEffect = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
TweenInfos.HoverOutEffect = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
TweenInfos.ClickEffect = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
TweenInfos.ClickOutEffect = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
TweenInfos.RotateEffect = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
TweenInfos.OpenFrameEffect = TweenInfo.new(0.45, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
TweenInfos.CloseFrameEffect = TweenInfo.new(0.45, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

------------------------------------------------------------
-- EFFECTS MAP ([EffectName]: function(Instance) -> EffectConfigReturnNode)
------------------------------------------------------------
function EffectsConfig.HoverEffect(UIObject: GuiObject): Types.EffectConfigReturnNode
	const ScaleFactor = 1.1
	if not OriginalSizes[UIObject] then
		OriginalSizes[UIObject] = UIObject.Size
	end
	return {
		Info = TweenInfos.HoverEffect,
		Goal = {
			Size = UDim2.fromScale(
				OriginalSizes[UIObject].X.Scale * ScaleFactor,
				OriginalSizes[UIObject].Y.Scale * ScaleFactor
			),
		},
	}
end

function EffectsConfig.HoverOutEffect(UIObject: GuiObject): Types.EffectConfigReturnNode
	return {
		Info = TweenInfos.HoverOutEffect,
		Goal = {
			Size = OriginalSizes[UIObject],
		},
	}
end

function EffectsConfig.ClickEffect(UIObject: GuiObject): Types.EffectConfigReturnNode
	const ScaleFactor = 0.9
	if not OriginalSizes[UIObject] then
		OriginalSizes[UIObject] = UIObject.Size
	end
	return {
		Info = TweenInfos.ClickEffect,
		Goal = {
			Size = UDim2.fromScale(
				OriginalSizes[UIObject].X.Scale * ScaleFactor,
				OriginalSizes[UIObject].Y.Scale * ScaleFactor
			),
		},
	}
end

function EffectsConfig.ClickOutEffect(UIObject: GuiObject): Types.EffectConfigReturnNode
	return {
		Info = TweenInfos.ClickOutEffect,
		Goal = {
			Size = OriginalSizes[UIObject],
		},
	}
end

function EffectsConfig.RotateEffect(UIObject: GuiObject): Types.EffectConfigReturnNode
	return {
		Info = TweenInfos.RotateEffect,
		Goal = {
			Rotation = UIObject.Rotation + 360,
		},
	}
end

function EffectsConfig.OpenFrameEffect(TargetSize: UDim2): Types.EffectConfigReturnNode
	return {
		Info = TweenInfos.OpenFrameEffect,
		Goal = {
			Size = TargetSize,
		},
	}
end

function EffectsConfig.CloseFrameEffect(UIObject: GuiObject): Types.EffectConfigReturnNode
	return {
		Info = TweenInfos.CloseFrameEffect,
		Goal = {
			Size = UDim2.fromScale(0, 0),
		},
	}
end

return EffectsConfig
