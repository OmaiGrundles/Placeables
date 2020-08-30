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
    }
  })

data.raw["gui-style"].default["draggableWidget"] = {
    type = "empty_widget_style",
    --parent = "draggable_space_header",
    horizontally_stretchable = "on",
    natural_height = 24,
    minimal_width = 0
}