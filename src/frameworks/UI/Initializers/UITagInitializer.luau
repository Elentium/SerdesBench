------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
const CollectionService = game:GetService("CollectionService")

------------------------------------------------------------
-- MODULES
------------------------------------------------------------
const TagsConfig = require("../Config/TagsConfig")
const Types = require("../Types")
const UITagInitializer = {}

------------------------------------------------------------
-- TYPES
------------------------------------------------------------
type TagHandler = Types.TagHandler

------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------
local Initialized = false

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
function UITagInitializer.Init(): ()
	if Initialized then
		return
	end
	Initialized = true
	for Tag: string, Handler: TagHandler in TagsConfig do
		for _, TaggedInstance: Instance in CollectionService:GetTagged(Tag) do
			task.spawn(Handler, TaggedInstance)
		end

		CollectionService:GetInstanceAddedSignal(Tag):Connect(Handler)
	end
end

return UITagInitializer
