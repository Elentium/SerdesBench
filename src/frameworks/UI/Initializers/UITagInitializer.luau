------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
const CollectionService = game:GetService("CollectionService")

------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const TagsConfig = require("../Config/TagsConfig")
const UITagInitializer = {}

------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------
local Initialized = false

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
function UITagInitializer.Init()
	if Initialized then
		return
	end
	Initialized = true
	for Tag: string, Handler: (UIObject: GuiObject) -> () in TagsConfig do
		for _, UIObject: GuiObject in CollectionService:GetTagged(Tag) do
			task.spawn(Handler, UIObject)
		end

		CollectionService:GetInstanceAddedSignal(Tag):Connect(Handler)
	end
end

return UITagInitializer
