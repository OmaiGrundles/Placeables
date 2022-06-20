--TODO LIST
--   Change graphic for button on top left
--   Add shortcut button using graphic mentioned above

local mod_gui = require("mod-gui")

--globals and their initial states
--playerData = {}
--itemValidCache = {}
--ignoreEventFlag = false

local function CreatePlayerData(playerIndex)
	local playerData = global.playerData
	--Initialize data stored about the player
	if playerData[playerIndex] == nil then
		playerData[playerIndex] = {
			placeablesVisibleState = false,
			placeablesCollapsedState = false,
			buttonData = {},
			lastRows = 0,
			lastCollapsedState = false,
			lastColumns = 0,
			buttonCache = {},
			settingColumns = 7,
			settingQuickbarMode = false,
			itemLocaleCache = {}
		}
	end
	--Create the settingColumns and settingQuickbarMode fields if updating from older version
	if playerData[playerIndex].settingColumns == nil then
		local player = game.get_player(playerIndex)
		--Record the amount of columns the player had displayed previously
		playerData[playerIndex].settingColumns = player.gui.screen.framePlaceablesOuter.framePlaceablesInner.framePlaceablesTable.column_count
		--Record if quickbar mode was previously on
		if player.gui.screen.framePlaceablesOuter.placeablesTitleFlow.buttonPlaceablesModeSwitch.sprite == "spriteOrangeCircle" then
			playerData[playerIndex].settingQuickbarMode = true
		else
			playerData[playerIndex].settingQuickbarMode = false
		end
	end
end

local function CreateTitleFlow(player, outerFrame)
	local titleFlow = outerFrame.placeablesTitleFlow
	local settingPowerMode = player.mod_settings["placeablesSettingPowerUser"].value
	--This function mostly exists to deal with players loading saves with older versions of the mod
	titleFlow.clear()
	titleFlow.add{type = "label", name = "placeablesLabel", caption = "Placeables", style = "frame_title", visible = not settingPowerMode}.drag_target = outerFrame
	titleFlow.add{type = "empty-widget", name = "placeablesTitleDragLeft", style = "draggableWidget", visible = not settingPowerMode}.drag_target = outerFrame
	titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesThin",
	 sprite = "spriteContract", tooltip = {"placeablesTooltips.reduce"} }
	titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesWide",
	 sprite = "utility/expand", tooltip = {"placeablesTooltips.expand"} }
	titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesCollapse",
	 sprite = "utility/collapse", tooltip = {"placeablesTooltips.collapse"} }
	titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesModeSwitch",
	 sprite = "spriteCircle", tooltip = {"placeablesTooltips.modeSwitch"} }
	titleFlow.add{type = "empty-widget", name = "placeablesTitleDragRight", style = "draggableWidget", visible = settingPowerMode}.drag_target = outerFrame
	titleFlow.add{type = "label", name = "placeablesLabelRight", style = "frame_title", caption = "   ", visible = settingPowerMode}.drag_target = outerFrame
	if global.playerData[player.index].settingQuickbarMode == true then
		titleFlow.buttonPlaceablesModeSwitch.sprite = "spriteOrangeCircle"
	end
end

local function DestroyModButton(player)
	local gui = player.gui.top
	local flow = gui.mod_gui_button_flow or (gui.mod_gui_top_frame and gui.mod_gui_top_frame.mod_gui_inner_frame)
	if flow and flow.buttonPlaceablesVisible then
		flow.buttonPlaceablesVisible.destroy()
		-- Remove empty frame if we're the only thing there, remove the parent frame if we just removed the only child
		if #flow.children_names == 0 then
		  local parent = flow.parent
		  flow.destroy()
		  if parent and #parent.children_names == 0 then
			parent.destroy()
		  end
		end
	end
end

local function CreateModButton(playerIndex)
	local player = game.get_player(playerIndex)
	DestroyModButton(player)
	if player.mod_settings["placeablesSettingHideButton"].value then
		return
	end
	mod_gui.get_button_flow(player).add{
		type = "button",
		name = "buttonPlaceablesVisible",
		caption = "P", 
		style = mod_gui.button_style,
		tooltip = {"placeablesTooltips.topButton"}
	}
end

local function CreateGUI(player)
	playerData = global.playerData[player.index]
	--Make button on top-left of screen
	CreateModButton(player.index)

	--Create the main panel GUI elements
	if player.gui.screen.framePlaceablesOuter == nil then
		--Outermost layer
		player.gui.screen.add{type = "frame", name ="framePlaceablesOuter", style = "quick_bar_window_frame", direction = "vertical"}
		local outerFrame = player.gui.screen.framePlaceablesOuter
		--Have to declare the position of the frame afterwards for some reason...
		outerFrame.location = {x = 30, y = 200}
		outerFrame.visible = playerData.placeablesVisibleState
		--Titlebar Flow
		outerFrame.add{type = "flow", name = "placeablesTitleFlow", direction = "horizontal"}.drag_target = outerFrame
		CreateTitleFlow(player, outerFrame)

		--Middle layer, after the horizontal flow, borders the buttons
		outerFrame.add{type = "frame", name = "framePlaceablesInner", style = "quick_bar_inner_panel"}

		--Table that holds all the buttons for each unique placeable item
		outerFrame.framePlaceablesInner.add{type = "table", name = "framePlaceablesTable", column_count = playerData.settingColumns, style = "quick_bar_slot_table"}
	end
	--If the player updated from version 0.9.25 or older, we need to remake the title flow
	if player.gui.screen.framePlaceablesOuter.placeablesTitleFlow.placeablesTitleDragLeft == nil then
		CreateTitleFlow(player, player.gui.screen.framePlaceablesOuter)
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
	local playerData = global.playerData[player.index]
	local buttonData = playerData.buttonData
	local buttonIndex = 1
	local buttonCache = playerData.buttonCache
	local itemLocaleCache = playerData.itemLocaleCache

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
	local buttonRows = math.floor((buttonIndex - 1) / playerData.settingColumns + 0.999)

	--Delete excess buttons
	if buttonCache[buttonIndex] ~= nil then
		for i = buttonIndex, #buttonCache do
			buttonCache[i].destroy()
			buttonCache[i] = nil
		end
	end

	--Move the frame when on 'quickbar mode'
	if playerData.settingQuickbarMode then
		QuickbarMode(player, buttonRows)
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
		--Item is valid if its something like concrete or red wire, also modules count now
		if prototype.place_as_tile_result ~= nil or prototype.wire_count == 1 or prototype.type == "module" then
			return true
		else
			return false
		end
	end
end

local function CheckInventory(player, inventory, buttonData, handSlot)
	local itemValidCache = global.itemValidCache
	local playerStack = nil
	local itemsInserted = false
	if handSlot ~= -1 then
		global.ignoreEventFlag = true

		--Put a duplicate of the held stack back into the inventory temporarily so that contents will be in proper order
		local pStack = player.cursor_stack
		local name = pStack.name
		if itemValidCache[name] then
			if not pStack.is_item_with_entity_data and not pStack.is_item_with_inventory then
				local count = inventory.insert(pStack)
				if count ~= 0 then
					itemsInserted = true
					playerStack = {name = name, count = count}
				end
			end
		end
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
		--Remove the duplicated items from the inventory
		if itemsInserted then
			inventory.remove(playerStack)
		end
	end
end

local function UpdateGUI(playerIndex)
	local player = game.get_player(playerIndex)
	local playerData = global.playerData[player.index]
	local inventory = player.get_main_inventory()
	local buttonTable = player.gui.screen.framePlaceablesOuter.framePlaceablesInner.framePlaceablesTable

	--Updating to new mod version: Delete all the buttons if buttonCache is empty
	if playerData.buttonCache[1] == nil then buttonTable.clear() end

	--Delete the old list of buttons
	playerData.buttonData = {}
	--Sorts the inventory if the player has autosort on, solves an edge case
	if player.auto_sort_main_inventory then inventory.sort_and_merge() end

	--Create list of buttons to be made by looping through the player's inventory
	local handSlot = -1
	if player.hand_location ~= nil then handSlot = player.hand_location.slot end
	CheckInventory(player, inventory, playerData.buttonData, handSlot)

	--Recreate all the item buttons
	CreateItemButtons(player, buttonTable)
end

local function CallUpdateWhenNotFlagged(event)
	if global.ignoreEventFlag == false then
		UpdateGUI(event.player_index)
	else
		global.ignoreEventFlag = false
	end
end
script.on_event(defines.events.on_player_main_inventory_changed, CallUpdateWhenNotFlagged)

local function PlayerRemovedEntity(event)
	local itemValidCache = global.itemValidCache
	local player = game.get_player(event.player_index)
	local buttonData = global.playerData[player.index].buttonData
	local itemName = event.item_stack.name
	local itemCount = event.item_stack.count
	local guiTable = player.gui.screen.framePlaceablesOuter.framePlaceablesInner.framePlaceablesTable

	if itemValidCache[itemName] then
		if buttonData[itemName] ~= nil then
			local button = guiTable["buttonPlaceables"..buttonData[itemName].buttonIndex]
			buttonData[itemName].count = buttonData[itemName].count + itemCount
			button.number = buttonData[itemName].count
			--Skip the next UpdateGUI function call since we updated the changed button here
			global.ignoreEventFlag = true
		else
			--This item is valid but a button for it doesnt exist. Force update the GUI
			UpdateGUI(event.player_index)
		end
	else
		if itemValidCache[itemName] == false then
			--Skip the next UpdateGUI function call because the item mined isnt supposed to be displayed on the button list anyway
			global.ignoreEventFlag = true
		else
			--This item hasnt been validated yet. Validate the item.
			itemValidCache[itemName] = IsPlaceableItem(game.item_prototypes[itemName])
			if itemValidCache[itemName] then
				--This item is valid but a button for it doesnt exist. Force update the GUI
				UpdateGUI(event.player_index)
			end
		end
	end
end
script.on_event(defines.events.on_player_mined_item, PlayerRemovedEntity)

local function PlayerPlacedEntity(event)
	local player = game.get_player(event.player_index)
	local buttonData = global.playerData[player.index].buttonData
	local guiTable = player.gui.screen.framePlaceablesOuter.framePlaceablesInner.framePlaceablesTable

	local entityName = event.created_entity.name
	--If the item is a ghost, skip everything
	if entityName ~= "entity-ghost" and entityName ~= "tile-ghost" then
		local item = event.item
		--If the player placed a blueprint or the like, this should be nil and nothing should happen
		if item ~= nil then
			local name = item.name

			--Attempt to catch a crash that I belive is caused by placing things that get into
			--your cursor by non-standard means
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
end
script.on_event(defines.events.on_built_entity, PlayerPlacedEntity)

local function PlayerPlacedTile(event)
	local player = game.get_player(event.player_index)
	local buttonData = global.playerData[player.index].buttonData
	local guiTable = player.gui.screen.framePlaceablesOuter.framePlaceablesInner.framePlaceablesTable

	local item = event.item
	--There is a couple cases where item might not be given. In these cases we will just end the function
	if item == nil then
		--Not even sure we need to call this as the inventory might not even change but just in case
		UpdateGUI(event.player_index)
		return
	end

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
	--If the element clicked isnt part of this mod, do nothing
	if event.element.get_mod() == "Placeables" then
		local player = game.get_player(event.player_index)
		local playerData = global.playerData[player.index]

		--Check to see if there is a number attached to the element, if so that is one of the dynamically generated buttons
		local buttonNumber = tonumber(string.match(event.element.name, "%d+"))
		if buttonNumber ~= nil then
			local inventory = player.get_main_inventory()
			local itemName = string.sub(event.element.sprite, 6)

			local cursorItemName = nil
			if player.cursor_stack.valid_for_read then cursorItemName = player.cursor_stack.name end
			player.clear_cursor()

			--If player selected the item that was already in cursor, then do nothing else, which leaves cursor empty
			if cursorItemName ~= itemName then
				local itemStack, itemIndex = inventory.find_item_stack(itemName)
				if itemStack ~= nil then
					local pickupResult = player.cursor_stack.transfer_stack(itemStack)
					if pickupResult then
						player.hand_location = {inventory = inventory.index, slot = itemIndex}
					else
						log("Unable to reserve inventory slot for cursor stack")
					end
				end
			end
		end

		--Player clicked the top-left button that isnt part of the placeables window
		if event.element.name == "buttonPlaceablesVisible" then
			--Inverse the visibility of the main panel
			playerData.placeablesVisibleState = not playerData.placeablesVisibleState
			player.gui.screen.framePlaceablesOuter.visible = playerData.placeablesVisibleState
		end

		--Player clicked the button with the downwards chevron
		if event.element.name == "buttonPlaceablesCollapse" then
			local innerFrame = player.gui.screen.framePlaceablesOuter.framePlaceablesInner
			playerData.placeablesCollapsedState = not playerData.placeablesCollapsedState
			innerFrame.visible = not playerData.placeablesCollapsedState
		end

		--Player clicked the button with the circle on the right
		if event.element.name == "buttonPlaceablesModeSwitch" then
			playerData.settingQuickbarMode = not playerData.settingQuickbarMode
			if playerData.settingQuickbarMode == true then
				player.gui.screen.framePlaceablesOuter.placeablesTitleFlow.buttonPlaceablesModeSwitch.sprite = "spriteOrangeCircle"
			else
				player.gui.screen.framePlaceablesOuter.placeablesTitleFlow.buttonPlaceablesModeSwitch.sprite = "spriteCircle"
			end
		end

		--These buttons increase/decrease the number of columns of buttons
		if event.element.name == "buttonPlaceablesWide" then
			if event.shift then
				playerData.settingColumns = playerData.settingColumns + 2
			else
				playerData.settingColumns = playerData.settingColumns + 1
			end
		end
		if event.element.name == "buttonPlaceablesThin" then
			if event.shift then
				playerData.settingColumns = 4
			else
				playerData.settingColumns = playerData.settingColumns - 1
			end
		end

		--If column count changes, we need to destroy the table of buttons and rebuild
		if playerData.lastColumns ~= playerData.settingColumns then
			local innerFrame = player.gui.screen.framePlaceablesOuter.framePlaceablesInner
			innerFrame.framePlaceablesTable.destroy()
			playerData.buttonCache = {}

			--Partially hides the word 'Placeables' and removes the leftmost button when the column amount is 4
			local titleFlow = player.gui.screen.framePlaceablesOuter.placeablesTitleFlow
			if playerData.settingColumns == 4 then
				titleFlow.buttonPlaceablesThin.visible = false
				titleFlow.placeablesLabel.caption = "Placeab.."
			else
				titleFlow.buttonPlaceablesThin.visible = true
				titleFlow.placeablesLabel.caption = "Placeables"
			end
			--Recreate the holder for the buttons that will be re-added later
			innerFrame.add{type = "table", name = "framePlaceablesTable", column_count = playerData.settingColumns, style = "quick_bar_slot_table"}
		end
		--Record the amount of columns displayed for future calculations
		playerData.lastColumns = playerData.settingColumns

		UpdateGUI(event.player_index)
	end
end
script.on_event(defines.events.on_gui_click, PressButton)

local function InitializeMod()
	--Loop through every player and create the GUI/data for that player
	global.playerData = {}
	global.itemValidCache = {}
	global.ignoreEventFlag = false
	for key, value in pairs(game.players) do
		CreatePlayerData(game.players[key].index)
		CreateGUI(game.players[key])
		--Delete/create the button cache
		global.playerData[game.players[key].index].buttonCache = {}
		--Delete/create the locale cache, which stores the text for the button tooltips
		global.playerData[game.players[key].index].itemLocaleCache = {}
		--Fully create/update all the buttons as long as its not a brand new game
		local inventory = game.players[key].get_main_inventory()
		if inventory ~= nil then
			UpdateGUI(game.players[key].index)
		end
	end
end
script.on_init(InitializeMod)
script.on_event(defines.events.on_player_created, InitializeMod)
script.on_configuration_changed(InitializeMod)

local function SettingsChanged(event)
	local settingName = event.setting
	--Player changed the setting to hide/unhide the top left button
	if settingName == "placeablesSettingHideButton" then
		CreateModButton(event.player_index)
	end
	--Player toggled "Power User" mode, also known as the mode that makes the window buttons render on left side
	if settingName == "placeablesSettingPowerUser" then
		local player = game.get_player(event.player_index)
		local powerUser = player.mod_settings["placeablesSettingPowerUser"].value
		local titleFlow = player.gui.screen.framePlaceablesOuter.placeablesTitleFlow
		titleFlow.placeablesLabel.visible = not powerUser
		titleFlow.placeablesTitleDragLeft.visible = not powerUser
		titleFlow.placeablesTitleDragRight.visible = powerUser
		titleFlow.placeablesLabelRight.visible = powerUser
	end
end
script.on_event(defines.events.on_runtime_mod_setting_changed, SettingsChanged)

local function ToggleVisibility(event)
	--This is when a player presses Ctrl-Shift-P by default
	local player = game.get_player(event.player_index)
	local playerData = global.playerData[event.player_index]
	playerData.placeablesVisibleState = not playerData.placeablesVisibleState
	player.gui.screen.framePlaceablesOuter.visible = playerData.placeablesVisibleState
end
script.on_event("placeablesToggleVisibilty", ToggleVisibility)

local function ToggleCollapse(event)
	--This is when a player presses Ctrl-P by default
	local playerData = global.playerData[event.player_index]
	local innerFrame = game.get_player(event.player_index).gui.screen.framePlaceablesOuter.framePlaceablesInner
	playerData.placeablesCollapsedState = not playerData.placeablesCollapsedState
	innerFrame.visible = not playerData.placeablesCollapsedState
	UpdateGUI(event.player_index)
end
script.on_event("placeablesToggleCollapse", ToggleCollapse)