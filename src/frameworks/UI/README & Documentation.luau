--[[
-- ████████╗███████╗███╗   ███╗██████╗ ██╗      █████╗ ████████╗███████╗
-- ╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██║     ██╔══██╗╚══██╔══╝██╔════╝
--    ██║   █████╗  ██╔████╔██║██████╔╝██║     ███████║   ██║   █████╗
--    ██║   ██╔══╝  ██║╚██╔╝██║██╔═══╝ ██║     ██╔══██║   ██║   ██╔══╝
--    ██║   ███████╗██║ ╚═╝ ██║██║     ███████╗██║  ██║   ██║   ███████╗
--    ╚═╝   ╚══════╝╚═╝     ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝

-- ██╗      █████╗ ██████╗ ███████╗
-- ██║     ██╔══██╗██╔══██╗██╔════╝
-- ██║     ███████║██████╔╝███████╗
-- ██║     ██╔══██║██╔══██╗╚════██║
-- ███████╗██║  ██║██████╔╝███████║
-- ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
-- ================================================================================
-- MEGA STUDS UI PACK - README & DOCUMENTATION

-- Thank you for purchasing from Template Labs! We truly appreciate your support.
-- If you encounter any issues or inquiries, don't hesitate to contact our support team in our Discord server: https://discord.gg/UPNCEh8MBS

-- By using our templates you agree to our Terms of Service: https://payhip.com/labstemplate/terms-of-service
-- ================================================================================
-- !! WHITELIST SYSTEM (IMPORTANT) !!

-- In order to use any Template Labs product, you must complete our whitelist verification process, this'll only take a few minutes.
-- This system is required for all users and helps protect our products against unauthorized redistribution, leaking, reselling, and illegal access.

-- HOW TO VERIFY YOUR LICENSE:

-- 1. Join our official Discord server: https://discord.gg/UPNCEh8MBS
-- 2. Open a ticket in the #tickets channel.
-- 3. Create a "Whitelist" ticket.
-- 4. Provide the required information listed.

-- IMPORTANT NOTES:

-- • Products will NOT function until your license has been verified.
-- • Attempting to bypass the whitelist system may result in your access being permanently revoked without warning.
-- • Unauthorized copies, leaked versions, or redistributed assets are automatically denied access to our systems.

-- Once your verification has been approved, your Roblox account will be successfully whitelisted and your product will function normally.(Including in groups/communities)

-- VERIFIED CUSTOMERS ALSO RECEIVES:

-- • Access to product updates
-- • Bug fixes & improvements
-- • Customer support & setup assistance
-- • Access to exclusive support channels
-- • Future announcements regarding the product

-- Template Labs reserves the right to take legal action against unauthorized redistribution, reselling, leaking, or misuse of our products, including but not limited to DMCA takedowns.
-- ================================================================================
-- SOCIALS & STORES

-- Discord Server: https://discord.gg/UPNCEh8MBS
-- Official Store(Payhip): https://payhip.com/labstemplate
-- BuiltByBit Store: https://builtbybit.com/store/template-labs.455/
-- X / Twitter Page: https://x.com/TemplateLabsRBX

-- ================================================================================
-- ================================================================================
-- © Template Labs. All Rights Reserved.

-- !! DOCUMENTATION !!
UI Framework
============

Tag-driven client UI framework for Roblox Studio. Assign CollectionService tags to
instances and the framework wires up effects and behaviors automatically.
No per-instance scripts required for the built-in features.


Architecture
------------

Frameworks/UI/
├── init.luau                          Public entry; exposes API and runs Init()
├── Types.luau                         Shared type definitions
├── Config/
│   ├── TagsConfig.luau                Tag name → handler(Instance)
│   ├── EffectsConfig.luau             Effect name → TweenInfo + goal properties
│   ├── EffectsSoundConfig.luau        Hover and click sound asset IDs
│   └── OpenHitboxConfig.luau          Proximity query interval and box size
├── Modules/
│   ├── UIEffects.luau                 Applies tweens from EffectsConfig
│   ├── FrameToggler.luau              Open/close GuiObject animations + debounce
│   ├── AncestorOpenEffects.luau     Staggered open effects for tagged descendants
│   └── PlayerGuiFrameResolver.luau  Maps StarterGui refs to PlayerGui clones
├── Data/                              Runtime state (do not edit at rest)
│   ├── OriginalSizes.luau             Cached original Size per GuiObject
│   ├── OriginalBobbingStates.luau     Cached Position + Rotation for bobbing
│   ├── BobbingConnections.luau          Active bobbing tween runner per GuiObject
│   ├── AncestorOpenTweens.luau          Active ancestor-open tweens per GuiObject
│   ├── HoverTweens.luau               Active hover tweens (click-out reuse)
│   ├── OpenFrames.luau                Per-GuiObject toggle state
│   ├── OpenDivisions.luau             Currently open GuiObject per division
│   └── OpenHitboxes.luau              Hitbox Part → GuiObject + division mapping
└── Initializers/
	├── UITagInitializer.luau          Binds CollectionService tag handlers
	└── OpenHitboxHandler.luau         Proximity queries → FrameToggler.OpenFrame
	└── FrameworkInitializer.client.luau        Client bootstrap (initializes the framework)


Bootstrap order (init.luau)
---------------------------

1. UITagInitializer.Init()   — registers tag handlers and existing tagged instances
2. OpenHitboxHandler.Init()  — starts heartbeat proximity queries

Tags must initialize before hitbox queries so OpenHitboxes is populated.


How tags work
-------------

UITagInitializer iterates TagsConfig, scans CollectionService:GetTagged for each
tag, and connects GetInstanceAddedSignal for new instances.

Tag names in Studio must exactly match keys in TagsConfig (e.g. `UI_AnimatedButton`).
Already-tagged instances are handled via task.spawn; newly added instances invoke
the handler directly.

Most UI tags target GuiObjects in PlayerGui. `UI_FrameHitbox` targets BaseParts
anywhere in the DataModel (typically workspace).


PlayerGui frame resolution
--------------------------

UI_FrameTogglerButton and UI_FrameHitbox resolve ObjectValue targets through
PlayerGuiFrameResolver before wiring FrameToggler.

- Reference already under PlayerGui → used as-is
- Reference under StarterGui → GetFullName() path is mapped onto PlayerGui
	(e.g. StarterGui.HUD.ShopFrame → PlayerGui.HUD.ShopFrame)
- Any other source → resolution fails; the tag handler no-ops

Point ObjectValues at StarterGui templates or the live PlayerGui instance.


Built-in tags
-------------

UI_AnimatedButton
	Full button feedback: hover in/out, click press/release.
	Instance type: GuiButton

UI_HoverEffect
	Hover scale only (no click animation).
	Instance type: GuiObject

UI_FrameTogglerButton
	Opens/closes a target GuiObject on click via FrameToggler.ToggleFrame.
	Only one GuiObject per division may be open; opening another in the same
	division closes the current one first (close and open animate in parallel).
	Instance type: GuiButton
	Setup:
		- Add an ObjectValue child named `FrameToToggle`
		- Set its Value to the GuiObject you want to toggle (StarterGui or PlayerGui)
		- Optional: set a `Division` attribute (string) on the button
	Divisions:
		- Omit `Division` or leave it unset → uses `"Default"`
		- Buttons in the same division share one open slot (e.g. button1 + button2)
		- A custom division is independent (e.g. `"Shop"` only conflicts with other `"Shop"` buttons)
	Global debounce: while any open/close tween is playing, further open/close/toggle
	calls are ignored.
	The GuiObject should start Visible = false (or true); toggling animates Size
	between scale (0, 0) and its cached layout size.

UI_FrameHitbox
	Opens a target GuiObject when the local player's character overlaps the hitbox Part.
	Uses the same division rules as UI_FrameTogglerButton. Only opens GuiObjects that
	are not already visible (calls FrameToggler.OpenFrame).
	Instance type: BasePart (in workspace or elsewhere)
	Setup:
		- Tag the Part with `UI_FrameHitbox`
		- Add an ObjectValue child named `FrameToToggle` (or `FrameToOpen`)
		- Set its Value to the GuiObject you want to open (StarterGui or PlayerGui)
		- Optional: set a `Division` attribute (string) on the Part
	Query behavior (OpenHitboxHandler):
		- Runs on the client heartbeat at QueryIntermission intervals
		- Casts a box around the character's PrimaryPart using QuerySize
		- Any overlapping registered hitbox Part triggers OpenFrame for its GuiObject
	Tune query interval and box size in Config/OpenHitboxConfig.luau.

UI_RotatingEffect
	Continuous 360° rotation loop.
	Instance type: GuiObject

UI_BobbingEffect
	Continuous bobbing via chained TweenService segments (Linear, next segment starts on Completed):
		1. rises and rotates right
		2. falls to rest with neutral rotation
		3. rises and rotates left
		4. falls to rest, then repeats
	Instance type: GuiObject

UI_OpenEffectOnAncestorOpen
	Marks a GuiObject to play a staggered open animation when an ancestor frame opens
	via FrameToggler. Place on descendants inside a toggled frame; no extra setup.
	Instance type: GuiObject
	Behavior when the parent frame opens:
		- Collapsed to Size (0, 0) when the frame begins opening; playback starts
		  halfway through the ancestor frame open tween, then staggers from there
		- Sorted by AbsolutePosition (top-to-bottom, then left-to-right)
		- Optional `Priority` attribute (number): plays at that slot (1 = first),
		  bypassing position sort for that element; unprioritized items fill remaining slots
		- Each plays OpenEffectOnAncestorOpenEffect with a frame stagger between starts
		- Does not affect FrameToggler global debounce or division logic
		- On frame close: pending playback is cancelled, active tweens are stopped,
		  and each descendant's Size is restored to its cached layout size
	Tag handler is a no-op marker; animation is driven by FrameToggler.OpenFrame.


Built-in effects
----------------

Defined in EffectsConfig; applied by UIEffects.

| Effect            | Behavior                                      |
|-------------------|-----------------------------------------------|
| HoverEffect       | Scale to 1.1× original (scale components)     |
| HoverOutEffect    | Restore cached original Size                  |
| ClickEffect       | Scale to 0.9× original                        |
| ClickOutEffect    | Restore size; reuses active hover tween if any|
| RotateEffect                      | Linear infinite rotation (+360°)              |
| OpenFrameEffect                   | Tween Size to target layout size              |
| CloseFrameEffect                  | Tween Size to UDim2.fromScale(0, 0)           |
| OpenEffectOnAncestorOpenEffect    | Quint open tween (0.25s) to target Size       |
| BobbingEffect                     | Chained TweenService segments on Position and Rotation |

Hover and click sounds play from Config/EffectsSoundConfig.luau when ApplyHoverEffect
and ApplyClickEffect run. Per-instance `HoverSoundId` / `ClickSoundId` attributes
(string) override the config. Set an ID to rbxassetid:// URL, or nil /
rbxassetid://0 to disable.

Tween timings and easing live in EffectsConfig (`TweenInfos` table). Adjust
duration, EasingStyle, and EasingDirection there.


Programmatic API
----------------

UI.Effects       — UIEffects (ApplyHoverEffect, ApplyClickEffect,
                     ApplyOpenEffectOnAncestorOpen, ApplyBobbingEffect, etc.)
UI.Tags          — TagsConfig tag handlers
UI.FrameToggler  — OpenFrame, CloseFrame, ToggleFrame

Effects return the playing Tween:

	local Tween = UI.Effects.ApplyHoverEffect(someImageLabel)

Frame toggling:

	UI.FrameToggler.OpenFrame(myGuiObject)           -- open if closed; no-op if already open
	UI.FrameToggler.OpenFrame(myGuiObject, "Shop")   -- open in a custom division
	UI.FrameToggler.CloseFrame(myGuiObject)          -- close if open; no-op if already closed
	UI.FrameToggler.ToggleFrame(myGuiObject)         -- open or close based on Visible state

OpenFrame closes any other open GuiObject in the same division before opening.
Close and open tweens during a division switch play at the same time.
All three methods share the same global debounce and division tracking.


GuiObject toggler (FrameToggler)
--------------------------------

OpenFrame and CloseFrame contain the core logic. ToggleFrame delegates to them.

OpenFrame(GuiObject, Division?)
	- No-op if global debounce is active or GuiObject.Visible is true
	- Closes any other visible GuiObject in the same division, then opens target
	- Division switch: close and open animations run in parallel
	- Descendants tagged UI_OpenEffectOnAncestorOpen play staggered open effects
	  starting halfway through the frame open tween (independent of global debounce)

CloseFrame(GuiObject, Division?)
	- No-op if global debounce is active or GuiObject.Visible is false
	- Resets UI_OpenEffectOnAncestorOpen descendants before the close tween plays
	- Plays close animation and clears division tracking

ToggleFrame(GuiObject, Division?)
	- Calls CloseFrame when visible, OpenFrame when hidden

Division defaults to `"Default"` when omitted. First call caches OriginalSize per GuiObject.


Modifying existing behavior
---------------------------

Change tween feel
	Edit `TweenInfos` in Config/EffectsConfig.luau (duration, easing, repeat).

Change hover/click scale
	Edit `ScaleFactor` in EffectsConfig.HoverEffect / ClickEffect.

Change hover/click sounds
	Edit Hover / Click in Config/EffectsSoundConfig.luau.

Change frame open/close speed
	Edit TweenInfos.OpenFrameEffect / CloseFrameEffect in EffectsConfig.

Change ancestor-open child effect timing or easing
	Edit TweenInfos.OpenEffectOnAncestorOpenEffect in EffectsConfig (duration 0.25s,
	Quint). Stagger between children is frame-based (StaggerFrames in
	Modules/AncestorOpenEffects.luau, default 2 heartbeat frames).

Change bobbing intensity or speed
	Edit EffectsConfig.Bobbing (Period, OffsetY, RotationAmplitude) and
	EffectsConfig.BobbingSegmentInfo easing/duration.

Change hitbox query rate or detection box
	Edit QueryIntermission / QuerySize in Config/OpenHitboxConfig.luau.

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

3. Assign the tag to instances. No initializer changes needed unless the tag needs
	ongoing polling — UITagInitializer picks up new TagsConfig keys automatically.


Adding frame-toggle behavior without a button
---------------------------------------------

Use UI.FrameToggler from game code (see Programmatic API above).
For proximity-based opening, tag a Part with UI_FrameHitbox instead.


Runtime data (Data/)
--------------------

These modules are empty tables at load time; the framework fills them at runtime.

OriginalSizes         — first-seen Size per GuiObject for scale effects
OriginalBobbingStates — cached Position + Rotation per bobbing GuiObject
BobbingConnections  — active bobbing tween runner per GuiObject
AncestorOpenTweens  — active open-on-ancestor tween per GuiObject
HoverTweens           — active hover tween per object (click-out can replay it)
OpenFrames      — { OriginalSize, Division } per toggled GuiObject
OpenDivisions   — division name → currently open GuiObject (or unset)
OpenHitboxes    — hitbox Part → { GuiObject, Division }

Do not pre-populate these files. Clear state is handled in memory only.


Types (Types.luau)
------------------

EffectConfigReturnNode
	{ Info: TweenInfo, Goal: { [string]: any } }

OpenFrameNode
	{ OriginalSize: UDim2, Division: string }

OpenHitboxNode
	{ GuiObject: GuiObject, Division: string }


Notes and limitations
---------------------

- Client-only: init.luau errors if required on the server.
- Hover/click scaling uses Scale components (UDim2.fromScale). Offset-based sizes
	are cached but tween goals use scale math; offset-only GuiObjects may animate poorly.
- Open/close animations collapse Size to UDim2.fromScale(0, 0); layout size is cached
	on first toggle. Hidden GuiObjects stored at size (0, 0) in Studio will not open visibly.
- Tag handlers run once per instance when tagged; avoid duplicate connections if
	you retag at runtime without cloning.
- UI_FrameTogglerButton and UI_FrameHitbox silently no-op if the ObjectValue is missing,
	empty, or PlayerGuiFrameResolver cannot map the reference.
- `Division` attribute must be a string when set; non-string values fall back to `"Default"`.
- Hitbox queries only open GuiObjects; they do not close them when the player leaves.
- PlayerGuiFrameResolver only maps StarterGui paths; ReplicatedStorage references are not supported.
- Hitbox registration yields on PlayerGui via WaitForChild; ensure PlayerGui exists before
	or when tags are applied.


Checklist: new interactive UI element
-------------------------------------

[ ] Create/configure GuiObject in StarterGui or PlayerGui
[ ] Add CollectionService tag(s) from TagsConfig
[ ] For frame toggles: add FrameToToggle ObjectValue → target GuiObject
[ ] Tag child elements with UI_OpenEffectOnAncestorOpen for staggered reveal on open
[ ] Set `Priority` attribute (number) on children that must open in a specific order
[ ] Set `Division` attribute when multiple toggle groups should stay independent
[ ] For proximity frames: tag a BasePart with UI_FrameHitbox and link FrameToToggle
[ ] Tune OpenHitboxConfig query size/interval if detection feels off
[ ] Play-test hover, click, frame, and hitbox animations
[ ] Tune EffectsConfig if the motion feels wrong
]]

error("Cannot require a README module")
