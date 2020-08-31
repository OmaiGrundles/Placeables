data:extend({
    {
        type = "bool-setting",
        name = "placeablesSettingQuickbarMode",
        setting_type = "runtime-per-user",
        default_value = false,
        order = "c"
    },
    {
        type = "bool-setting",
        name = "placeablesSettingHideButton",
        setting_type = "runtime-per-user",
        default_value = false,
        order = "a"
    },
    {
        type = "int-setting",
        name = "placeablesSettingColumns",
        setting_type = "runtime-per-user",
        minimum_value = 4,
        maximum_value = 50,
        default_value = 5,
        order = "b"
    }
})