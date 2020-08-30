require("mod-gui")

global.playerData = {}

function CreatePlayerData(playerIndex)
	playerData = global.playerData
	--Initialize data stored about the player
	if playerData[playerIndex] == nil then
		playerData[playerIndex] = { 
			placeablesVisibleState = false, 
			placeablesFrameLocation = {x = 0, y = 200}, 
			placeablesCollapsedState = false,
			buttonData = {},
			lastRows = 0,
			lastCollapsedState = false
		}
	end
end

function CreateGUI(player)
	
	playerData = global.playerData
	--Make button on top-left of screen
	if mod_gui.get_button_flow(player).buttonPlaceablesVisible == nil then
		mod_gui.get_button_flow(player).add{type = "button", name = "buttonPlaceablesVisible", caption = "P", style = mod_gui.button_style}
	end

	--Create the main panel GUI elements
	if player.gui.screen.framePlaceablesOuter == nil then
		--Outermost layer
		player.gui.screen.add{type = "frame", name ="framePlaceablesOuter", style = "quick_bar_window_frame", direction = "vertical"}
		local outerFrame = player.gui.screen.framePlaceablesOuter
		--Have to declare the position of the frame afterwards for some reason...
		outerFrame.location = playerData[player.index].placeablesFrameLocation
		outerFrame.visible = playerData[player.index].placeablesVisibleState
		--Titlebar Flow
		outerFrame.add{type = "flow", name = "placeablesTitleFlow", direction = "horizontal"}
		local titleFlow = outerFrame.placeablesTitleFlow
		titleFlow.add{type = "label", name = "placeablesLabel", caption = "Placeables", style = "frame_title"}.drag_target = outerFrame
		titleFlow.add{type = "empty-widget", style = "draggableWidget"}.drag_target = outerFrame
		titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesThin", sprite = "spriteContract"}
		titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesWide", sprite = "utility/expand"}
		titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesCollapse", sprite = "utility/collapse"}
		titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesClose", sprite = "utility/close_white"}

		--Middle layer, after the horizontal flow, borders the buttons
		outerFrame.add{type = "frame", name = "framePlaceablesInner", style = "quick_bar_inner_panel"}
	end
end

function InitializeMod()
	--Loop through every player and create the GUI/data for that player
	for key, value in pairs(game.players) do
		CreatePlayerData(game.players[key].index)
		CreateGUI(game.players[key])
	end
end
script.on_init(InitializeMod)
script.on_event(defines.events.on_player_created, InitializeMod)

function QuickbarMode(player, rows)
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
	newLocation.y = newLocation.y + ((playerData.lastRows - rows) * buttonHeight) * gameScale
	
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

function CreateItemButtons(player, table)
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
	if settingQuickbarMode then QuickbarMode(player, buttonRows) end

	--Note the amount of rows of buttons used, and if the frame is collapsed
	global.playerData[player.index].lastRows = buttonRows
	global.playerData[player.index].lastCollapsedState = global.playerData[player.index].placeablesCollapsedState
end

function AddToButtonList(player, item, index)
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

function CheckStack(player, inventory, index)
	--Check to see if we are looking at the 'hand' slot, and add the current held stack to the button list
	if player.hand_location ~= nil then
		if index == player.hand_location.slot then
			if player.cursor_stack.prototype.place_result ~= nil or player.cursor_stack.prototype.place_as_tile_result ~= nil then
				AddToButtonList(player, player.cursor_stack, index)
				return
			end
		end
	end
	--If item is placeable, add to the button list
	if inventory[index].valid_for_read then 
		if inventory[index].prototype.place_result ~= nil or inventory[index].prototype.place_as_tile_result ~= nil then
			AddToButtonList(player, inventory[index], index)
		end
	end
end


function UpdateGUI(event)
	local player = game.get_player(event.player_index)
	local settingColumns = player.mod_settings["placeablesSettingColumns"].value
	local settingQuickbarMode = player.mod_settings["placeablesSettingQuickbarMode"].value
	local inventory = player.get_main_inventory()
	local innerFrame = player.gui.screen.framePlaceablesOuter.framePlaceablesInner
	
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

	if settingColumns == 4 then
		player.gui.screen.framePlaceablesOuter.placeablesTitleFlow.buttonPlaceablesThin.visible = false
		player.gui.screen.framePlaceablesOuter.placeablesTitleFlow.placeablesLabel.caption = "Placeab.."
	else
		player.gui.screen.framePlaceablesOuter.placeablesTitleFlow.buttonPlaceablesThin.visible = true
		player.gui.screen.framePlaceablesOuter.placeablesTitleFlow.placeablesLabel.caption = "Placeables"
	end


	innerFrame.visible = not global.playerData[player.index].placeablesCollapsedState
	--player.gui.screen.framePlaceablesOuter.placeablesTitleFlow.visible = not settingQuickbarMode
	player.gui.screen.framePlaceablesOuter.visible = global.playerData[player.index].placeablesVisibleState

	--store the current location of the frame
	global.playerData[player.index].lastFrameLocation = player.gui.screen.framePlaceablesOuter.location
end
script.on_event(defines.events.on_player_main_inventory_changed, UpdateGUI)
script.on_event(defines.events.on_built_entity, UpdateGUI)
script.on_event(defines.events.on_player_mined_item, UpdateGUI)
script.on_event(defines.events.on_player_built_tile, UpdateGUI)
script.on_event(defines.events.on_player_mined_tile, UpdateGUI)


function PressButton(event)
	local playerData = global.playerData
	if event.element.get_mod() == "Placeables" then
		local player = game.get_player(event.player_index)
		local settingColumns = player.mod_settings["placeablesSettingColumns"].value
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
		if event.element.name == "buttonPlaceablesClose" then
			if event.shift then
				--Toggle Quickbar Mode if you hold shift and hit the X
				player.mod_settings["placeablesSettingQuickbarMode"].value = not player.mod_settings["placeablesSettingQuickbarMode"].value
			else
				playerData[player.index].placeablesVisibleState = false
			end
		end
		if event.element.name == "buttonPlaceablesCollapse" then 
			playerData[player.index].placeablesCollapsedState = not playerData[player.index].placeablesCollapsedState
		end
		--These buttons increase/decrease the number of columns of buttons
		local settingColumns = player.mod_settings["placeablesSettingColumns"]
		if event.element.name == "buttonPlaceablesWide" then
			settingColumns = {value = settingColumns.value + 1}
			player.mod_settings["placeablesSettingColumns"] = settingColumns
		end
		if event.element.name == "buttonPlaceablesThin" then
			settingColumns = {value = settingColumns.value - 1}
			player.mod_settings["placeablesSettingColumns"] = settingColumns
		end

		UpdateGUI(event)
	end
end
script.on_event(defines.events.on_gui_click, PressButton)