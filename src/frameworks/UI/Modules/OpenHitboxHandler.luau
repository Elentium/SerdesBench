------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const OpenHitboxConfig = require("../Config/OpenHitboxConfig")
const OpenHitboxes = require("../Data/OpenHitboxes")
const FrameToggler = require("./FrameToggler")
const OpenHitboxHandler = {}

------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------
const Player = Players.LocalPlayer

const Intermission = OpenHitboxConfig.QueryIntermission
const HitboxSize = OpenHitboxConfig.QuerySize

local LastQueryTime = 0

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
function OpenHitboxHandler.Init(): ()
    RunService.Heartbeat:Connect(function(Delta: number): ()
        LastQueryTime += Delta
    
        const Character = Player.Character
        const PrimaryPart = Character and Character.PrimaryPart
    
        if LastQueryTime < Intermission or not Character or not PrimaryPart then
            return
        end
    
        LastQueryTime = 0
        const CF = PrimaryPart.CFrame
        
        const Query = workspace:GetPartBoundsInBox(CF, HitboxSize)
        for _, Part: BasePart in Query do
            const HitboxNode = OpenHitboxes[Part]
            if HitboxNode then
                FrameToggler.OpenFrame(HitboxNode.GuiObject, HitboxNode.Division)
            end
        end
    end)
end

return OpenHitboxHandler