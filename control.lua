--TODO LIST
--   Change graphic for button on top left
--   Add shortcut button using graphic mentioned above
--   Fix unresponsive buttons when items are being changed rapidly/increase performance in general
--   Add thumbnail

require("mod-gui")

global.playerData = {}

local function CreatePlayerData(playerIndex)
	playerData = global.playerData
	--Initialize data stored about the player
	if playerData[playerIndex] == nil then
		playerData[playerIndex] = { 
			placeablesVisibleState = false, 
			placeablesCollapsedState = false,
			buttonData = {},
			lastRows = 0,
			lastCollapsedState = false
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

local function InitializeMod()
	--Loop through every player and create the GUI/data for that player
	for key, value in pairs(game.players) do
		CreatePlayerData(game.players[key].index)
		CreateGUI(game.players[key])
	end
end
script.on_init(InitializeMod)
script.on_event(defines.events.on_player_created, InitializeMod)

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

	--Finally, move the frame to the calculated position
	frameLocation = {x = newLocation.x, y = newLocation.y}
	player.gui.screen.framePlaceablesOuter.location = frameLocation
end

local function CreateItemButtons(player, table)
	local settingColumns = player.mod_settings["placeablesSettingColumns"].value
	local settingQuickbarMode = player.mod_settings["placeablesSettingQuickbarMode"].value
	--Create all the buttons for selecting placeable items
	local buttonCount = 0
	local buttonData = global.playerData[player.index].buttonData
	for key, value in pairs(buttonData) do
		table.add{type="sprite-button", sprite = "item/"..key, name = "buttonPlaceables"..buttonData[key].index, 
			number = buttonData[key].count, style = "slot_button", tooltip = 
			{"", "[font=default-bold][color=255,230,192]", game.item_prototypes[key].localised_name, "[/color][/font]"} }
		buttonCount = buttonCount + 1
	end
	local buttonRows = math.floor(buttonCount / settingColumns + 0.999)
	
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

local function AddToButtonList(player, item, index)
	local buttonData = global.playerData[player.index].buttonData
	for key, value in pairs(buttonData) do
		--Search for the existance of the item already in the button list
		if item.name == key then
			buttonData[key].count = buttonData[key].count + item.count
			return
		end
	end
	--If list entry doesnt exist, create it
	buttonData[item.name] = {index = index, count = item.count}
end

local function CheckStack(player, inventory, index)
	--Check to see if we are looking at the 'hand' slot, and add the current held stack to the button list
	if player.hand_location ~= nil then
		if index == player.hand_location.slot then
			local prototype = player.cursor_stack.prototype
			if prototype.place_result ~= nil then
				--Don't add robots to the list
				if prototype.place_result.type ~= "construction-robot" and prototype.place_result.type ~= "logistic-robot" then
					AddToButtonList(player, player.cursor_stack, index)
				end
			end
			if prototype.place_as_tile_result ~= nil or prototype.wire_count == 1 then 	
				AddToButtonList(player, player.cursor_stack, index)
			end
		end
	end
	--If item is placeable, add to the button list
	if inventory[index].valid_for_read then
		local prototype = inventory[index].prototype
		if prototype.place_result ~= nil then
			--Don't add robots to the list
			if prototype.place_result.type ~= "construction-robot" and prototype.place_result.type ~= "logistic-robot" then
				AddToButtonList(player, inventory[index], index)
			end
		end
		if prototype.place_as_tile_result ~= nil or prototype.wire_count == 1 then 	
			AddToButtonList(player, inventory[index], index)
		end
	end
end


local function UpdateGUI(event)
	local player = game.get_player(event.player_index)
	local settingColumns = player.mod_settings["placeablesSettingColumns"].value
	local settingHideButton = player.mod_settings["placeablesSettingHideButton"].value
	local inventory = player.get_main_inventory()
	local innerFrame = player.gui.screen.framePlaceablesOuter.framePlaceablesInner
	local titleFlow = player.gui.screen.framePlaceablesOuter.placeablesTitleFlow

	--delete all the item buttons, recreate the table, this allows the column count setting to be changed during game
	if innerFrame.framePlaceablesTable ~= nil then innerFrame.framePlaceablesTable.destroy() end
	innerFrame.add{type = "table", name = "framePlaceablesTable", column_count = settingColumns, style = "quick_bar_slot_table"}

	--Delete the old list of buttons
	global.playerData[player.index].buttonData = {}
	--Sorts the inventory if the player has autosort on, solves an edge case
	if player.auto_sort_main_inventory then inventory.sort_and_merge() end

	--Create list of buttons to be made
	for i = 1, #inventory do
		CheckStack(player, inventory, i)
	end

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
	global.playerData[player.index].lastFrameLocation = player.gui.screen.framePlaceablesOuter.location
end
script.on_event(defines.events.on_player_main_inventory_changed, UpdateGUI)
script.on_event(defines.events.on_built_entity, UpdateGUI)
script.on_event(defines.events.on_player_mined_item, UpdateGUI)
script.on_event(defines.events.on_player_built_tile, UpdateGUI)
script.on_event(defines.events.on_player_mined_tile, UpdateGUI)


local function PressButton(event)
	local playerData = global.playerData
	if event.element.get_mod() == "Placeables" then
		local player = game.get_player(event.player_index)
		--Check to see if there is a number attached to the element, if so that is one of the dynamically generated buttons
		local index = tonumber(string.match(event.element.name, "%d+"))
		if index ~= nil then
			local itemInCursor = nil
			local inventory = player.get_main_inventory()
			if player.cursor_stack.valid_for_read then itemInCursor = player.cursor_stack.name end
			player.clean_cursor()
			--If player selected the item that was already in cursor, then do nothing else, which leaves cursor empty
			if itemInCursor ~= inventory[index].name then
				player.cursor_stack.transfer_stack(inventory[index])
				player.hand_location = {inventory = defines.inventory.character_main, slot = index}
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

		UpdateGUI(event)
	end
end
script.on_event(defines.events.on_gui_click, PressButton)

local function ToggleVisibility(event)
	local playerData = global.playerData[event.player_index]
	playerData.placeablesVisibleState = not playerData.placeablesVisibleState
	UpdateGUI(event)
end
script.on_event("placeablesToggleVisibilty", ToggleVisibility)

local function ToggleCollapse(event)
	local playerData = global.playerData[event.player_index]
	playerData.placeablesCollapsedState = not playerData.placeablesCollapsedState
	UpdateGUI(event)
end
script.on_event("placeablesToggleCollapse", ToggleCollapse)