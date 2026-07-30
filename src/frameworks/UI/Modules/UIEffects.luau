------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
const SoundService = game:GetService("SoundService")
const TweenService = game:GetService("TweenService")

------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const AncestorOpenTweens = require("../Data/AncestorOpenTweens")
const EffectsConfig = require("../Config/EffectsConfig")
const EffectsSoundConfig = require("../Config/EffectsSoundConfig")
const BobbingConnections = require("../Data/BobbingConnections")
const HoverTweens = require("../Data/HoverTweens")
const OriginalBobbingStates = require("../Data/OriginalBobbingStates")
const UIEffects = {}

------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------
const CachedSounds: { [string]: Sound } = {}

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
const function PlayEffectSound(SoundId: string?): ()
	if SoundId == nil or SoundId == "rbxassetid://0" then
		return
	end

	if not CachedSounds[SoundId] then
		const NewSound = Instance.new("Sound")
		NewSound.SoundId = SoundId
		NewSound.Parent = SoundService
		CachedSounds[SoundId] = NewSound
	end

	const Sound = CachedSounds[SoundId]
	Sound.TimePosition = 0
	Sound:Play()
end

const function GetHoverSoundId(UIObject: GuiObject): string?
	const SoundId = UIObject:GetAttribute("HoverSoundId")
	if typeof(SoundId) == "string" then
		return SoundId
	end
	return EffectsSoundConfig.Hover
end

const function GetClickSoundId(UIObject: GuiObject): string?
	const SoundId = UIObject:GetAttribute("ClickSoundId")
	if typeof(SoundId) == "string" then
		return SoundId
	end
	return EffectsSoundConfig.Click
end

function UIEffects.ApplyHoverEffect(UIObject: GuiObject): Tween
	PlayEffectSound(GetHoverSoundId(UIObject))
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
	PlayEffectSound(GetClickSoundId(UIObject))
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

function UIEffects.ApplyFrameOpenEffect(UIObject: GuiObject, TargetSize: UDim2): Tween
	const EffectConfig = EffectsConfig.OpenFrameEffect(TargetSize)
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

function UIEffects.ApplyOpenEffectOnAncestorOpen(UIObject: GuiObject, TargetSize: UDim2): Tween
	const ExistingTween = AncestorOpenTweens[UIObject]
	if ExistingTween then
		ExistingTween:Cancel()
	end

	const EffectConfig = EffectsConfig.OpenEffectOnAncestorOpenEffect(TargetSize)
	const Tween = TweenService:Create(UIObject, EffectConfig.Info, EffectConfig.Goal)
	AncestorOpenTweens[UIObject] = Tween
	Tween:Play()

	Tween.Completed:Once(function()
		if AncestorOpenTweens[UIObject] == Tween then
			AncestorOpenTweens[UIObject] = nil
		end
	end)

	return Tween
end

function UIEffects.CancelOpenEffectOnAncestorOpen(UIObject: GuiObject): ()
	const ActiveTween = AncestorOpenTweens[UIObject]
	if ActiveTween then
		ActiveTween:Cancel()
		AncestorOpenTweens[UIObject] = nil
	end
end

const function GetBobbingUpPosition(OriginalPosition: UDim2, OffsetY: number): UDim2
	return UDim2.new(
		OriginalPosition.X.Scale,
		OriginalPosition.X.Offset,
		OriginalPosition.Y.Scale,
		OriginalPosition.Y.Offset - OffsetY
	)
end

function UIEffects.ApplyBobbingEffect(UIObject: GuiObject): ()
	if BobbingConnections[UIObject] then
		return
	end

	if not OriginalBobbingStates[UIObject] then
		OriginalBobbingStates[UIObject] = {
			Position = UIObject.Position,
			Rotation = UIObject.Rotation,
		}
	end

	const BobbingConfig = EffectsConfig.Bobbing
	const OriginalState = OriginalBobbingStates[UIObject]
	const UpPosition = GetBobbingUpPosition(OriginalState.Position, BobbingConfig.OffsetY)
	const SegmentInfo = EffectsConfig.BobbingSegmentInfo()
	local ActiveTween: Tween? = nil
	local Cancelled = false

	const function StopBobbing(): ()
		if Cancelled then
			return
		end

		Cancelled = true

		if ActiveTween then
			ActiveTween:Cancel()
			ActiveTween = nil
		end

		UIObject.Position = OriginalState.Position
		UIObject.Rotation = OriginalState.Rotation
		BobbingConnections[UIObject] = nil
	end

	const function PlaySegment(GoalPosition: UDim2, GoalRotation: number, OnComplete: () -> ()): ()
		if Cancelled then
			return
		end

		const Tween = TweenService:Create(UIObject, SegmentInfo, {
			Position = GoalPosition,
			Rotation = GoalRotation,
		})
		ActiveTween = Tween
		Tween:Play()

		Tween.Completed:Once(function(PlaybackState: Enum.PlaybackState)
			if Cancelled or PlaybackState ~= Enum.PlaybackState.Completed then
				if ActiveTween == Tween then
					ActiveTween = nil
				end
				return
			end

			OnComplete()

			if ActiveTween == Tween then
				ActiveTween = nil
			end
		end)
	end

	const function RunCycle(): ()
		if Cancelled then
			return
		end

		PlaySegment(UpPosition, OriginalState.Rotation + BobbingConfig.RotationAmplitude, function()
			PlaySegment(OriginalState.Position, OriginalState.Rotation, function()
				PlaySegment(UpPosition, OriginalState.Rotation - BobbingConfig.RotationAmplitude, function()
					PlaySegment(OriginalState.Position, OriginalState.Rotation, RunCycle)
				end)
			end)
		end)
	end

	BobbingConnections[UIObject] = {
		Cancel = StopBobbing,
	}

	RunCycle()

	UIObject.Destroying:Once(StopBobbing)
end

return UIEffects
