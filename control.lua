require("mod-gui")
toggleState = false

function CheckStack(player, index, lastIndex, table)
	inventory = player.get_main_inventory()
	--Does a inventory stack even exist at this index?
	if not inventory[index].valid_for_read then return false end
	--Is the player holding the same stack as the indexed stack?
	if player.cursor_stack.valid_for_read then
		if player.cursor_stack.name == inventory[index].name then return false end
	end
	--Is the stack even placeable?
	if inventory[index].prototype.place_result == nil then return false end
	--Is the stack the same as the last stack in the index?
	if index - 1 ~= 0 then 
		if inventory[index-1].valid_for_read then
			if inventory[lastIndex].name == inventory[index].name then
				--Add the current count stack to the last button made
				table["buttonPlaceables"..lastIndex]["number"] = inventory[index].count + table["buttonPlaceables"..lastIndex]["number"]
				return false
			end
		end
	end
	--If none of the above triggers, all is good! Make the button!
	return true
end


function CreateRefreshGUI(event)

	local player = game.get_player(event.player_index)
	local inventory = player.get_main_inventory()
	
	--Make button on top-left of screen
	if mod_gui.get_button_flow(player).buttonPlaceablesToggle == nil then
		mod_gui.get_button_flow(player).add{type = "button", name = "buttonPlaceablesToggle", caption = "P", style = mod_gui.button_style}
	end

	--Create the Placeables GUI elements
	if player.gui.screen.framePlaceablesOuter == nil then
		player.gui.screen.add{type="frame", name ="framePlaceablesOuter", caption="Placeables", style = "quick_bar_window_frame"}
		player.gui.screen.framePlaceablesOuter.add{type = "frame", name = "framePlaceablesInner", style = "quick_bar_inner_panel"}
		player.gui.screen.framePlaceablesOuter.framePlaceablesInner.add{type="table", name = "framePlaceablesTable", column_count = 10, style = "quick_bar_slot_table"}
	end

	table = player.gui.screen.framePlaceablesOuter.framePlaceablesInner.framePlaceablesTable
	table.clear()
	
	inventory.sort_and_merge() --Forces the inventory to sort before generating the buttons, solves a small issue
	lastIndex = 1 --the index of the last valid button made, or 1
	for i = 1, #inventory do
		--If the current stack of the inventory is a unique placeable item, add a button for it
		if CheckStack(player, i, lastIndex, table) then
			table.add{type="sprite-button", sprite = "item/"..inventory[i].name, name = "buttonPlaceables"..i, number = inventory[i].count, style = "slot_button"}
			lastIndex = i
		end
	end

	player.gui.screen.framePlaceablesOuter.visible = toggleState

end
script.on_event(defines.events.on_player_main_inventory_changed, CreateRefreshGUI)


function PressButton(event)
	if event.element.get_mod() == "Placeables" then
		local player = game.get_player(event.player_index)
		--Check to see if there is a number attached to the element, if so that is one of the dynamically generated buttons
		index = tonumber(string.match(event.element.name, "%d+"))
		if index ~= nil then 
			player.clean_cursor()
			inventory = player.get_main_inventory()
			player.cursor_stack.transfer_stack(inventory[index])
			player.hand_location = {inventory = defines.inventory.character_main, slot = index}
		end
		--Toggle button check
		if event.element.name == "buttonPlaceablesToggle" then 
			toggleState = not toggleState
			player.gui.screen.framePlaceablesOuter.visible = toggleState
		end
	end
end
script.on_event(defines.events.on_gui_click, PressButton)