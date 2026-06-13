--!strict
------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
const TweenService = game:GetService("TweenService")

------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const EffectsConfig = require("../Config/EffectsConfig")
const HoverTweens = require("../Data/HoverTweens")
const UIEffects = {}

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
function UIEffects.ApplyHoverEffect(UIObject: GuiObject): Tween
	const EffectConfig = EffectsConfig.HoverEffect(UIObject)
	const Tween = TweenService:Create(UIObject, EffectConfig.Info, EffectConfig.Goal)
	Tween:Play()
	HoverTweens[UIObject] = Tween
	return Tween
end

function UIEffects.ApplyHoverOutEffect(UIObject: GuiObject): Tween
	const EffectConfig = EffectsConfig.HoverOutEffect(UIObject)
	const Tween = TweenService:Create(UIObject, EffectConfig.Info, EffectConfig.Goal)
	Tween:Play()
	HoverTweens[UIObject] = Tween
	return Tween
end

function UIEffects.ApplyClickEffect(UIObject: GuiObject): Tween
	const EffectConfig = EffectsConfig.ClickEffect(UIObject)
	const Tween = TweenService:Create(UIObject, EffectConfig.Info, EffectConfig.Goal)
	Tween:Play()
	return Tween
end

function UIEffects.ApplyClickOutEffect(UIObject: GuiObject): Tween
	if HoverTweens[UIObject] then
		const Tween = HoverTweens[UIObject]
		Tween:Play()
		return Tween
	end
	const EffectConfig = EffectsConfig.ClickOutEffect(UIObject)
	const Tween = TweenService:Create(UIObject, EffectConfig.Info, EffectConfig.Goal)
	Tween:Play()
	return Tween
end

function UIEffects.ApplyRotateEffect(UIObject: GuiObject): Tween
	const EffectConfig = EffectsConfig.RotateEffect(UIObject)
	const Tween = TweenService:Create(UIObject, EffectConfig.Info, EffectConfig.Goal)
	Tween:Play()
	return Tween
end

function UIEffects.ApplyFrameOpenEffect(UIObject: GuiObject): Tween
	const EffectConfig = EffectsConfig.OpenFrameEffect(UIObject)
	const Tween = TweenService:Create(UIObject, EffectConfig.Info, EffectConfig.Goal)
	Tween:Play()
	return Tween
end

function UIEffects.ApplyFrameCloseEffect(UIObject: GuiObject): Tween
	const EffectConfig = EffectsConfig.CloseFrameEffect(UIObject)
	const Tween = TweenService:Create(UIObject, EffectConfig.Info, EffectConfig.Goal)
	Tween:Play()
	return Tween
end

return UIEffects
