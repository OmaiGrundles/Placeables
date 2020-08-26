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
			buttonData = {}
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
		titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesCollapse", sprite = "utility/collapse"}
		titleFlow.add{type = "sprite-button", style = "frame_action_button", name = "buttonPlaceablesClose", sprite = "utility/close_white"}

		--Middle layer, after the horizontal flow, borders the buttons
		outerFrame.add{type = "frame", name = "framePlaceablesInner", style = "quick_bar_inner_panel"}
		--Innermost layer, will contain all the buttons for selecting items
		outerFrame.framePlaceablesInner.add{type="table", name = "framePlaceablesTable", column_count = 10, style = "quick_bar_slot_table"}
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

function CreateItemButtons(player, table)
	--Create all the buttons for selecting placeable items
	buttonData = global.playerData[player.index].buttonData
	for key, value in pairs(buttonData) do
		table.add{type="sprite-button", sprite = "item/"..key, name = "buttonPlaceables"..buttonData[key].index, number = buttonData[key].count, style = "slot_button"}
	end
end

function AddToButtonList(player, item, index)
	buttonData = global.playerData[player.index].buttonData
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
	local inventory = player.get_main_inventory()
	local table = player.gui.screen.framePlaceablesOuter.framePlaceablesInner.framePlaceablesTable
	
	--delete all the item buttons
	table.clear()
	--Delete the old data about the player's inventory
	global.playerData[player.index].buttonData = {}
	--Sorts the inventory if the player has autosort on, solves an edge case
	if player.auto_sort_main_inventory then inventory.sort_and_merge() end

	for i = 1, #inventory do
		--Adds the current item to the list of buttons to be made, if applicable
		CheckStack(player, inventory, i)
	end

	CreateItemButtons(player, table)

	player.gui.screen.framePlaceablesOuter.framePlaceablesInner.visible = not global.playerData[player.index].placeablesCollapsedState
	player.gui.screen.framePlaceablesOuter.visible = global.playerData[player.index].placeablesVisibleState
end
script.on_event(defines.events.on_player_main_inventory_changed, UpdateGUI)
script.on_event(defines.events.on_built_entity, UpdateGUI)
script.on_event(defines.events.on_player_mined_item, UpdateGUI)
script.on_event(defines.events.on_player_built_tile, UpdateGUI)
script.on_event(defines.events.on_player_mined_tile, UpdateGUI)


function PressButton(event)
	playerData = global.playerData
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
		if event.element.name == "buttonPlaceablesClose" then
			playerData[player.index].placeablesVisibleState = false 
		end
		if event.element.name == "buttonPlaceablesCollapse" then 
			playerData[player.index].placeablesCollapsedState = not playerData[player.index].placeablesCollapsedState
		end
		UpdateGUI(event)
	end
end
script.on_event(defines.events.on_gui_click, PressButton)