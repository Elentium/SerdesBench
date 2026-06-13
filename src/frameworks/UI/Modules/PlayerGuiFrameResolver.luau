--!strict
------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
const Players = game:GetService("Players")
const StarterGui = game:GetService("StarterGui")

------------------------------------------------------------
-- MODULE
------------------------------------------------------------
const PlayerGuiFrameResolver = {}

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
local function FindByRelativePath(Root: Instance, RelativePath: string): Instance?
	local Current: Instance = Root
	for _, Segment in string.split(RelativePath, ".") do
		const Child = Current:FindFirstChild(Segment)
		if not Child then
			return nil
		end
		Current = Child
	end
	return Current
end

function PlayerGuiFrameResolver.ResolveFrame(Reference: Instance): GuiObject?
	if not Reference:IsA("GuiObject") then
		return nil
	end

	const PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	if Reference:IsDescendantOf(PlayerGui) then
		return Reference
	end

	const FullName = Reference:GetFullName()
	const StarterGuiFullName = StarterGui:GetFullName()
	if string.sub(FullName, 1, #StarterGuiFullName) ~= StarterGuiFullName then
		return nil
	end

	const RelativePath = string.sub(FullName, #StarterGuiFullName + 2)
	const Resolved = FindByRelativePath(PlayerGui, RelativePath)
	if Resolved and Resolved:IsA("GuiObject") then
		return Resolved :: GuiObject
	end

	return nil
end

return PlayerGuiFrameResolver
