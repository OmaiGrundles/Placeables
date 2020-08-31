local data_util = require("__flib__.data_util")

-- data:extend{
--   {
--     type = "shortcut",
--     name = "rb-toggle-gui",
--     action = "lua",
--     icon = data_util.build_sprite(nil, {0,0}, "__RecipeBook__/graphics/shortcut.png", 32, 2),
--     small_icon = data_util.build_sprite(nil, {0,32}, "__RecipeBook__/graphics/shortcut.png", 24, 2),
--     disabled_icon = data_util.build_sprite(nil, {48,0}, "__RecipeBook__/graphics/shortcut.png", 32, 2),
--     disabled_small_icon = data_util.build_sprite(nil, {36,32}, "__RecipeBook__/graphics/shortcut.png", 24, 2),
--     toggleable = true,
--     associated_control_input = "rb-toggle-gui"
--   }
-- }

data:extend({
    {
        type = "sprite",
        name = "spriteContract",
        filename = "__Placeables__/graphics/contract.png",
        priority = "extra-high-no-scale",
        size = 16,
        scale = 1,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "spriteCircle",
        filename = "__Placeables__/graphics/whiteCircle.png",
        priority = "extra-high-no-scale",
        size = 32,
        scale = 1,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "spriteOrangeCircle",
        filename = "__Placeables__/graphics/orangeCircle.png",
        priority = "extra-high-no-scale",
        size = 32,
        scale = 1,
        flags = {"gui-icon"}
    }
})

data:extend({
    {
        type = "custom-input",
        name = "placeablesToggleVisibilty",
        key_sequence = "CONTROL + SHIFT + P",
        consuming = "none"
    },
    {
        type = "custom-input",
        name = "placeablesToggleCollapse",
        key_sequence = "CONTROL + P",
        consuming = "none"
    }
})

data.raw["gui-style"].default["draggableWidget"] = {
    type = "empty_widget_style",
    --parent = "draggable_space_header",
    horizontally_stretchable = "on",
    natural_height = 24,
    minimal_width = 0
}
data.raw["gui-style"].default["highlightedButton"] = {
    type = "button_style",
    parent = "frame_action_button",
    default_graphical_set = 
    {
        base = {position = {51, 17}, corner_size = 8},
        shadow = {position = {440, 24}, corner_size = 8, draw_type = "outer"}
    }
}