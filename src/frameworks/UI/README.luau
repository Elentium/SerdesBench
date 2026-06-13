--[[
	UI Framework
	============

	Tag-driven client UI framework for Roblox Studio. Assign CollectionService tags to
	GuiObjects in PlayerGui and the framework wires up effects and behaviors automatically.
	No per-instance scripts required for the built-in features.

	Architecture
	------------

	Frameworks/UI/
	├── init.luau                          Public entry; exposes API and runs Init()
	├── Types.luau                         Shared type definitions
	├── README.luau                        This file
	├── Config/
	│   ├── TagsConfig.luau                Tag name → handler(Instance)
	│   └── EffectsConfig.luau             Effect name → TweenInfo + goal properties
	├── Modules/
	│   ├── UIEffects.luau                 Applies tweens from EffectsConfig
	│   └── FrameToggler.luau              Open/close frame animations + debounce
	├── Data/                              Runtime state (do not edit at rest)
	│   ├── OriginalSizes.luau             Cached original Size per GuiObject
	│   ├── HoverTweens.luau               Active hover tweens (click-out reuse)
	│   └── OpenFrames.luau                Per-frame toggle state
	└── Initializers/
	    ├── UITagInitializer.luau          Scans PlayerGui and binds tag handlers
	    └── FrameworkInitializer.client.luau  Client bootstrap (require parent)


	How tags work
	-------------

	UITagInitializer scans all descendants of LocalPlayer.PlayerGui that match each
	tag in TagsConfig, then connects DescendantAdded so newly created UI is handled too.

	Tag names in Studio must exactly match keys in TagsConfig (e.g. `UI_AnimatedButton`).
	Each handler receives the tagged Instance and should connect input events or start
	effects. Handlers run inside task.spawn; keep them lightweight.


	Built-in tags
	-------------

	UI_AnimatedButton
		Full button feedback: hover in/out, click press/release.
		Instance type: GuiButton

	UI_HoverEffect
		Hover scale only (no click animation).
		Instance type: GuiObject

	UI_FrameTogglerButton
		Opens/closes a target Frame on click.
		Instance type: GuiButton
		Setup:
			- Add an ObjectValue child named `FrameToOpen`
			- Set its Value to the Frame you want to toggle
		The Frame should start Visible = false (or true); toggling animates Size
		between scale (0, 0) and its layout size.

	UI_RotatingEffect
		Continuous 360° rotation loop.
		Instance type: GuiObject


	Built-in effects
	----------------

	Defined in EffectsConfig; applied by UIEffects.

	| Effect            | Behavior                                      |
	|-------------------|-----------------------------------------------|
	| HoverEffect       | Scale to 1.1× original (scale components)     |
	| HoverOutEffect    | Restore cached original Size                  |
	| ClickEffect       | Scale to 0.9× original                        |
	| ClickOutEffect    | Restore size; reuses active hover tween if any|
	| RotateEffect      | Linear infinite rotation (+360°)              |
	| OpenFrameEffect   | Tween Size to current layout size             |
	| CloseFrameEffect  | Tween Size to UDim2.fromScale(0, 0)           |

	Tween timings and easing live in EffectsConfig (`TweenInfos` table). Adjust
	duration, EasingStyle, and EasingDirection there.


	Programmatic API
	----------------

	require the framework module:

		local UI = require(path.to.UI)

	UI.Effects  — UIEffects module (ApplyHoverEffect, ApplyClickEffect, etc.)
	UI.Tags     — TagsConfig table (tag handlers; rarely needed at runtime)

	Effects return the playing Tween:

		local tween = UI.Effects.ApplyHoverEffect(someImageLabel)


	Modifying existing behavior
	---------------------------

	Change tween feel
		Edit `TweenInfos` in Config/EffectsConfig.luau (duration, easing, repeat).

	Change hover/click scale
		Edit `ScaleFactor` in EffectsConfig.HoverEffect / ClickEffect.

	Change frame open/close speed
		Edit TweenInfos.OpenFrameEffect / CloseFrameEffect.

	Change which events a tag listens to
		Edit the matching function in Config/TagsConfig.luau.


	Adding a new effect
	-------------------

	1. Types.luau — no change needed unless you introduce new config shapes.

	2. Config/EffectsConfig.luau
	   - Add a TweenInfo entry to TweenInfos.
	   - Add a function that returns { Info = ..., Goal = { ... } }.
	     Use OriginalSizes[UIObject] when tweening Size so hover/click stacks stay consistent.

	3. Modules/UIEffects.luau
	   - Add ApplyYourEffect(UIObject) that reads EffectsConfig, creates a Tween, plays it, returns it.

	4. Wire it up from a tag handler (TagsConfig) or call UI.Effects.ApplyYourEffect from game code.


	Adding a new tag
	----------------

	1. Config/TagsConfig.luau
	   - Add a function whose name is the exact CollectionService tag string:

			function TagsConfig.UI_MyNewTag(UIObject: GuiObject)
				-- connect events or call UIEffects
			end

	2. Studio → Tag Editor → create tag `UI_MyNewTag`.

	3. Assign the tag to instances in PlayerGui. No initializer changes needed;
	   UITagInitializer iterates all keys in TagsConfig automatically.


	Adding frame-toggle behavior without a button
	---------------------------------------------

	Require FrameToggler directly or expose a thin wrapper:

		local FrameToggler = require(path.to.Modules.FrameToggler)
		FrameToggler.ToggleFrame(myFrame)

	First call caches OriginalSize and manages debounce so rapid clicks do not overlap tweens.


	Runtime data (Data/)
	--------------------

	These modules are empty tables at load time; the framework fills them at runtime.

	OriginalSizes  — first-seen Size per GuiObject for scale effects
	HoverTweens    — active hover tween per object (click-out can replay it)
	OpenFrames     — { OriginalSize, Debounce } per toggled Frame

	Do not pre-populate these files. Clear state is handled in memory only.


	Types (Types.luau)
	------------------

	EffectConfigReturnNode
		{ Info: TweenInfo, Goal: { [string]: any } }

	OpenFrameNode
		{ OriginalSize: UDim2, Debounce: boolean }


	Notes and limitations
	---------------------

	- Client-only: uses LocalPlayer.PlayerGui and runs from a LocalScript bootstrap.
	- Hover/click scaling uses Scale components (UDim2.fromScale). Offset-based sizes
	  are cached but tween goals use scale math.
	- Tag handlers run once per instance when tagged; avoid duplicate connections if
	  you retag at runtime without cloning.
	- UI_FrameTogglerButton silently no-ops if `FrameToOpen` ObjectValue is missing or empty.


	Checklist: new interactive UI element
	-------------------------------------

	[ ] Create/configure GuiObject in PlayerGui
	[ ] Add CollectionService tag(s) from TagsConfig
	[ ] For frame toggles: add FrameToOpen ObjectValue → target Frame
	[ ] Play-test hover, click, and frame animations
	[ ] Tune EffectConfig if the motion feels wrong
]]

error("Cannot require a README module")
