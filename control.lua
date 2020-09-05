--TODO LIST
--   Change graphic for button on top left
--   Add shortcut button using graphic mentioned above
--	 Remove copper wire from the list of placeables
--   Maybe add an option for left-hand buttons?

require("mod-gui")

global.playerData = {}
local itemLocaleCache = {}
local itemValidCache = {}
local ignoreEventFlag = false

local function CreatePlayerData(playerIndex)
	playerData = global.playerData
	--Initialize data stored about the player
	if playerData[playerIndex] == nil then
		playerData[playerIndex] = { 
			placeablesVisibleState = false, 
			placeablesCollapsedState = false,
			buttonData = {},
			lastRows = 0,
			lastCollapsedState = false,
			lastColumns = 0,
			buttonCache = {}
		}
	end
end

local function CreateGUI(player)
	
	playerData = global.playerData
	--Make button on top-left of screen
	if mod_gui.get_button_flow(player).buttonPlaceablesVisible == nil then
		mod_gui.get_button_flow(player).add{type = "button", name = "buttonPlaceablesVisible", caption = "P", 
			style = mod_gui.button_style, tooltip = {"placeablesTooltips.topButton"} }
	end

	--Create the main panel GUI elements
	if player.gui.screen.framePlaceablesOuter == nil then
		--Outermost layer
		player.gui.screen.add{type = "frame", name ="framePlaceablesOuter", style = "quick_bar_window_frame", direction = "vertical"}
		local outerFrame = player.gui.screen.framePlaceablesOuter
		--Have to declare the position of the frame afterwards for some reason...
		outerFrame.location = {x = 30, y = 200}
		outerFrame.visible = playerData[player.index].placeablesVisibleState
		--Titlebar Flow
		outerFrame.add{type = "flow", name = "placeablesTitleFlow", direction = "horizontal"}
		local titleFlow = outerFrame.placeablesTitleFlow
		titleFlow.add{type = "label", name = "placeablesLabel", caption = "Placeables", style = "frame_title"}.drag_target = outerFrame
		titleFlow.add{type = "empty-widget", style = "draggableWidget"}.drag_target = outerFrame
		titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesThin", 
			sprite = "spriteContract", tooltip = {"placeablesTooltips.reduce"} }
		titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesWide", 
			sprite = "utility/expand", tooltip = {"placeablesTooltips.expand"} }
		titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesCollapse", 
			sprite = "utility/collapse", tooltip = {"placeablesTooltips.collapse"} }
		titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesModeSwitch", 
			sprite = "spriteCircle", tooltip = {"placeablesTooltips.modeSwitch"} }

		--Middle layer, after the horizontal flow, borders the buttons
		outerFrame.add{type = "frame", name = "framePlaceablesInner", style = "quick_bar_inner_panel"}
	end
end

local function QuickbarMode(player, rows)
	--The goal of Quickbar Mode is to keep the bottom of the frame locked in place, instead of the top, when the frame's size changes
	local playerData = global.playerData[player.index]
	local frameLocation = player.gui.screen.framePlaceablesOuter.location
	local newLocation = {x = frameLocation.x, y = frameLocation.y}
	local lastRows = playerData.lastRows
	local gameResolution = player.display_resolution
	local gameScale = player.display_scale
	local buttonHeight = 40
	local frameHeight = 48

	--Prevent dragging the window offscreen to the left
	if newLocation.x <= 0 then newLocation.x = 0 end
	
	--if lastRows was 7 and rows is 8 then Y needs to be reduced by buttonHeight
	if playerData.placeablesCollapsedState == false then
		newLocation.y = newLocation.y + ((playerData.lastRows - rows) * buttonHeight) * gameScale
	end
	
	--If the player has just clicked the collapse button, stuff needs doing ugh
	if playerData.placeablesCollapsedState ~= playerData.lastCollapsedState then 
		if playerData.placeablesCollapsedState == false then
			--Frame is to be uncollapsed
			newLocation.y = newLocation.y - ((buttonHeight * rows) + 4) * gameScale
		else
			--This will snap the frame to the bottom when its collapsed
			newLocation.y = newLocation.y + ((buttonHeight * rows) + 4) * gameScale
		end 
	end

	--Prevent dragging the frame below the screen
	if playerData.placeablesCollapsedState == false then 
		if newLocation.y >= gameResolution.height - ((buttonHeight * rows) + frameHeight) * gameScale then
			newLocation.y = gameResolution.height - ((buttonHeight * rows) + frameHeight) * gameScale
		end
	else 
		if newLocation.y >= gameResolution.height - (frameHeight - 4) * gameScale then
			newLocation.y = gameResolution.height - (frameHeight - 4) * gameScale
		end
	end

	--Prevent the frame from going above the screen
	if newLocation.y < 0 then newLocation.y = 0 end

	--Finally, move the frame to the calculated position
	frameLocation = {x = newLocation.x, y = newLocation.y}
	player.gui.screen.framePlaceablesOuter.location = frameLocation
end

local function CreateItemButtons(player, guiTable)
	local settingColumns = player.mod_settings["placeablesSettingColumns"].value
	local settingQuickbarMode = player.mod_settings["placeablesSettingQuickbarMode"].value
	local buttonData = global.playerData[player.index].buttonData
	local buttonIndex = 1
	local buttonCache = global.playerData[player.index].buttonCache
	
	--Create all the buttons for selecting placeable items
	for key, value in pairs(buttonData) do
		--Store the localized item name in a cache
		if itemLocaleCache[key] == nil then 
			itemLocaleCache[key] = {"", "[font=default-bold][color=255,230,192]", game.item_prototypes[key].localised_name, "[/color][/font]"}
		end
		--Create and cache button if one doesnt exist
		if buttonCache[buttonIndex] == nil then
			buttonCache[buttonIndex] = guiTable.add{ type="sprite-button", sprite = "item/"..key, name = "buttonPlaceables"..buttonIndex, 
			 number = value.count, style = "slot_button", tooltip = itemLocaleCache[key]}
			--Record what button this item is shown on
			value.buttonIndex = buttonIndex
		else
			--..Or modify the existing button to display new info
			button = buttonCache[buttonIndex]
			if button.number ~= value.count then button.number = value.count end
			if button.sprite ~= "item/"..key then
				button.sprite = "item/"..key
				button.tooltip = itemLocaleCache[key]
			end
			--Record what button this item is shown on
			value.buttonIndex = buttonIndex
		end
		buttonIndex = buttonIndex + 1
	end
	local buttonRows = math.floor((buttonIndex - 1) / settingColumns + 0.999)
	
	--Delete excess buttons
	if buttonCache[buttonIndex] ~= nil then 
		for i = buttonIndex, #buttonCache do
			buttonCache[i].destroy()
			buttonCache[i] = nil
		end
	end

	--Move the frame when on 'quickbar mode'
	if settingQuickbarMode then 
		QuickbarMode(player, buttonRows)
		player.gui.screen.framePlaceablesOuter.placeablesTitleFlow.buttonPlaceablesModeSwitch.sprite = "spriteOrangeCircle"
	else
		player.gui.screen.framePlaceablesOuter.placeablesTitleFlow.buttonPlaceablesModeSwitch.sprite = "spriteCircle"
	end

	--Note the amount of rows of buttons used, and if the frame is collapsed
	global.playerData[player.index].lastRows = buttonRows
	global.playerData[player.index].lastCollapsedState = global.playerData[player.index].placeablesCollapsedState
end

local function IsPlaceableItem(prototype)
	local placeResult = prototype.place_result
	if placeResult ~= nil then
		--Don't add robots to the list
		if placeResult.type ~= "construction-robot" and placeResult.type ~= "logistic-robot" then
			return true
		end
	else
		--Item is valid if its something like concrete or red wire
		if prototype.place_as_tile_result ~= nil or prototype.wire_count == 1 then
			return true
		else
			return false
		end
	end
end

local function CheckInventory(player, inventory, buttonData, handSlot)
	if handSlot ~= -1 then
		ignoreEventFlag = true
		--Put the held stack back into the inventory temporarily so that contents will be in proper order
		player.clean_cursor()
	end
	local contents = inventory.get_contents()
	for key, value in pairs(contents) do
		if itemValidCache[key] then
			buttonData[key] = {count = value}
		else
			if itemValidCache[key] == nil then
				--Determine if item is placeable and cache the result
				itemValidCache[key] = IsPlaceableItem(game.item_prototypes[key])
				if itemValidCache[key] then
					buttonData[key] = {count = value}
				end
			end
		end
	end
	if handSlot ~= -1 then
		player.cursor_stack.transfer_stack(inventory[handSlot])
		player.hand_location = {inventory = inventory.index, slot = handSlot}
	end
end

local function UpdateGUI(playerIndex)
	local player = game.get_player(playerIndex)
	local playerData = global.playerData[player.index]
	local settingColumns = player.mod_settings["placeablesSettingColumns"].value
	local settingHideButton = player.mod_settings["placeablesSettingHideButton"].value
	local inventory = player.get_main_inventory()
	local innerFrame = player.gui.screen.framePlaceablesOuter.framePlaceablesInner
	local titleFlow = player.gui.screen.framePlaceablesOuter.placeablesTitleFlow

	--If column count changes, we need to destroy the table and rebuild
	if playerData.lastColumns ~= settingColumns and innerFrame.framePlaceablesTable ~= nil then
		innerFrame.framePlaceablesTable.destroy()
		playerData.buttonCache = {}
	end
	playerData.lastColumns = settingColumns

	--Create the table that holds all the buttons if needed
	if innerFrame.framePlaceablesTable == nil then
		innerFrame.add{type = "table", name = "framePlaceablesTable", column_count = settingColumns, style = "quick_bar_slot_table"}
	end
	
	--Updating to new mod version: Delete all the buttons if buttonCache is empty
	if playerData.buttonCache[1] == nil then innerFrame.framePlaceablesTable.clear() end

	--Delete the old list of buttons
	playerData.buttonData = {}
	--Sorts the inventory if the player has autosort on, solves an edge case
	if player.auto_sort_main_inventory then inventory.sort_and_merge() end

	--Create list of buttons to be made by looping through the player's inventory
	local handSlot = -1
	if player.hand_location ~= nil then handSlot = player.hand_location.slot end
	CheckInventory(player, inventory, playerData.buttonData, handSlot)

	--Recreate all the item buttons
	CreateItemButtons(player, innerFrame.framePlaceablesTable)

	--Partially hides the word 'Placeables' and removes the leftmost button when the column amount is 4 
	if settingColumns == 4 then
		titleFlow.buttonPlaceablesThin.visible = false
		titleFlow.placeablesLabel.caption = "Placeab.."
	else
		titleFlow.buttonPlaceablesThin.visible = true
		titleFlow.placeablesLabel.caption = "Placeables"
	end
	--Changes the visibility of the top-left button depending on settings
	mod_gui.get_button_flow(player).buttonPlaceablesVisible.visible = not settingHideButton

	innerFrame.visible = not global.playerData[player.index].placeablesCollapsedState
	player.gui.screen.framePlaceablesOuter.visible = global.playerData[player.index].placeablesVisibleState

	--store the current location of the frame
	playerData.lastFrameLocation = player.gui.screen.framePlaceablesOuter.location
end

local function CallUpdateWhenNotFlagged(event)
	if ignoreEventFlag == false then
		UpdateGUI(event.player_index)
	else 
		ignoreEventFlag = false
	end
end
script.on_event(defines.events.on_player_main_inventory_changed, CallUpdateWhenNotFlagged)
script.on_event(defines.events.on_player_mined_item, CallUpdateWhenNotFlagged)
script.on_event(defines.events.on_player_mined_tile, CallUpdateWhenNotFlagged)

local function PlayerPlacedEntity(event)
	local player = game.get_player(event.player_index)
	local buttonData = global.playerData[player.index].buttonData
	local guiTable = player.gui.screen.framePlaceablesOuter.framePlaceablesInner.framePlaceablesTable

	local item = event.item
	--If the player placed a blueprint or the like, this should be nil and nothing should happen
	if item ~= nil then
		local name = item.name

		--Attempt to catch a crash that I belive is caused by placing ghosts
		if buttonData[name] == nil then return end
		if buttonData[name].buttonIndex == nil then return end

		local button = guiTable["buttonPlaceables"..buttonData[name].buttonIndex]
		--Reduce the number on the button by 1
		buttonData[name].count = buttonData[name].count - 1
		button.number = buttonData[name].count
		--If number becomes zero, hide button
		if button.number == 0 then
			UpdateGUI(event.player_index)
		end
	end
end
script.on_event(defines.events.on_built_entity, PlayerPlacedEntity)

local function PlayerPlacedTile(event)
	local player = game.get_player(event.player_index)
	local buttonData = global.playerData[player.index].buttonData
	local guiTable = player.gui.screen.framePlaceablesOuter.framePlaceablesInner.framePlaceablesTable

	local item = event.item
	local subtractAmount = 0
	--Count number of tiles that were placed
	for key, value in pairs(event.tiles) do
		subtractAmount = subtractAmount + 1
	end

	local name = item.name
	--If the player runs out of a tile while placing over another tile, buttonData[name] becomes
	-- nil because player_mined_tile fired right before this, so if that happens we just skip
	-- all the following
	if buttonData[name] ~= nil then
		local button = guiTable["buttonPlaceables"..buttonData[name].buttonIndex]
		--Reduce the number on the button by 1
		buttonData[name].count = buttonData[name].count - subtractAmount
		button.number = buttonData[name].count
		--If number becomes zero, hide button
		if button.number == 0 then
			UpdateGUI(event.player_index)
		end
	end
end
script.on_event(defines.events.on_player_built_tile, PlayerPlacedTile)

local function PressButton(event)
	local playerData = global.playerData
	if event.element.get_mod() == "Placeables" then
		local player = game.get_player(event.player_index)
		--Check to see if there is a number attached to the element, if so that is one of the dynamically generated buttons
		local buttonNumber = tonumber(string.match(event.element.name, "%d+"))
		if buttonNumber ~= nil then
			local inventory = player.get_main_inventory()
			local itemName = string.sub(event.element.sprite, 6)

			local cursorItemName = nil
			if player.cursor_stack.valid_for_read then cursorItemName = player.cursor_stack.name end
			player.clean_cursor()

			--If player selected the item that was already in cursor, then do nothing else, which leaves cursor empty
			if cursorItemName ~= itemName then
				local itemStack, itemIndex = inventory.find_item_stack(itemName)
				if itemStack ~= nil then
					player.cursor_stack.transfer_stack(itemStack)
					player.hand_location = {inventory = inventory.index, slot = itemIndex}
				end
			end
		end
		--Visible button check
		if event.element.name == "buttonPlaceablesVisible" then
			--Inverse the visibility of the main panel
			playerData[player.index].placeablesVisibleState = not playerData[player.index].placeablesVisibleState
		end
		
		if event.element.name == "buttonPlaceablesModeSwitch" then
			if not event.shift then
				--Toggle Quickbar Mode
				player.mod_settings["placeablesSettingQuickbarMode"] = {value = not player.mod_settings["placeablesSettingQuickbarMode"].value}
			else
				--Hidden sortcut to close the frame when holding shift
				--playerData[player.index].placeablesVisibleState = false
			end
		end
		if event.element.name == "buttonPlaceablesCollapse" then 
			playerData[player.index].placeablesCollapsedState = not playerData[player.index].placeablesCollapsedState
		end

		--These buttons increase/decrease the number of columns of buttons
		local settingColumns = player.mod_settings["placeablesSettingColumns"]
		if event.element.name == "buttonPlaceablesWide" then
			if event.shift then 
				settingColumns = {value = settingColumns.value + 2}
			else 
				settingColumns = {value = settingColumns.value + 1}
			end
			player.mod_settings["placeablesSettingColumns"] = settingColumns
		end
		if event.element.name == "buttonPlaceablesThin" then
			if event.shift then
				settingColumns = {value = 4}
			else 
				settingColumns = {value = settingColumns.value - 1}
			end
			player.mod_settings["placeablesSettingColumns"] = settingColumns
		end

		UpdateGUI(event.player_index)
	end
end
script.on_event(defines.events.on_gui_click, PressButton)

local function InitializeMod()
	--Loop through every player and create the GUI/data for that player
	for key, value in pairs(game.players) do
		CreatePlayerData(game.players[key].index)
		CreateGUI(game.players[key])
		--Delete/create the button cache
		playerData[game.players[key].index].buttonCache = {}
		--Fully create/update all the buttons
		UpdateGUI(game.players[key].index)
	end
end
script.on_init(InitializeMod)
script.on_event(defines.events.on_player_created, InitializeMod)
script.on_configuration_changed(InitializeMod)

local function ToggleVisibility(event)
	local playerData = global.playerData[event.player_index]
	playerData.placeablesVisibleState = not playerData.placeablesVisibleState
	UpdateGUI(event.player_index)
end
script.on_event("placeablesToggleVisibilty", ToggleVisibility)

local function ToggleCollapse(event)
	local playerData = global.playerData[event.player_index]
	playerData.placeablesCollapsedState = not playerData.placeablesCollapsedState
	UpdateGUI(event.player_index)
end
script.on_event("placeablesToggleCollapse", ToggleCollapse)