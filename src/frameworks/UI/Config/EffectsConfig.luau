------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const OriginalSizes = require("../Data/OriginalSizes")
const Types = require("../Types")
const EffectsConfig = {}

------------------------------------------------------------
-- TWEEN INFO MAP
------------------------------------------------------------
const TweenInfos = {
	HoverEffect = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	HoverOutEffect = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	ClickEffect = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	ClickOutEffect = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	RotateEffect = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
	OpenFrameEffect = TweenInfo.new(0.45, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	CloseFrameEffect = TweenInfo.new(0.45, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	OpenEffectOnAncestorOpenEffect = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

EffectsConfig.Bobbing = {
	Period = 4,
	OffsetY = 6,
	RotationAmplitude = 10,
}

function EffectsConfig.BobbingSegmentInfo(): TweenInfo
	return TweenInfo.new(EffectsConfig.Bobbing.Period / 4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
end

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
	const CachedSize = OriginalSizes[UIObject]
	return {
		Info = TweenInfos.HoverOutEffect,
		Goal = {
			Size = if CachedSize then CachedSize else UIObject.Size,
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
	const CachedSize = OriginalSizes[UIObject]
	return {
		Info = TweenInfos.ClickOutEffect,
		Goal = {
			Size = if CachedSize then CachedSize else UIObject.Size,
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

function EffectsConfig.CloseFrameEffect(_UIObject: GuiObject): Types.EffectConfigReturnNode
	return {
		Info = TweenInfos.CloseFrameEffect,
		Goal = {
			Size = UDim2.fromScale(0, 0),
		},
	}
end

function EffectsConfig.OpenEffectOnAncestorOpenEffect(TargetSize: UDim2): Types.EffectConfigReturnNode
	return {
		Info = TweenInfos.OpenEffectOnAncestorOpenEffect,
		Goal = {
			Size = TargetSize,
		},
	}
end

return EffectsConfig
