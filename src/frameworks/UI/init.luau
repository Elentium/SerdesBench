------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
const RunService = game:GetService("RunService")
if not RunService:IsClient() then
    error("UI framework can only be required on the client")
end

------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const UI = {}
const TagsConfig = require("@self/Config/TagsConfig")
const UITagInitializer = require("@self/Initializers/UITagInitializer")
const UIEffects = require("@self/Modules/UIEffects")
const FrameToggler = require("@self/Modules/FrameToggler")
const OpenHitboxHandler = require("@self/Initializers/OpenHitboxHandler")

------------------------------------------------------------
-- INIT
------------------------------------------------------------
UI.Effects = UIEffects
UI.Tags = TagsConfig
UI.FrameToggler = FrameToggler

UITagInitializer.Init()
OpenHitboxHandler.Init()

return UI
