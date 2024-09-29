---@class PSI
local PSI = select(2, ...)

PSI.PlaterOptions = {
    "General Settings", "Colors", "Target", "Cast Bar", "Scripting", "Modding", "Personal Bar",
    "Buff Settings", "Buff Tracking", "Buff Special", "Ghost Auras", "Enemy NPC", "Enemy Player",
    "Friendly NPC", "Friendly Player", "NPC Colors and Names", "Cast Colors and Names",
    "Spell List", "Spell Feedback", "Auto", "Advanced", "Combo Points"
}

PSI.PlaterOptionToDBEntry = {
    ["General Settings"] = {},
    ["Colors"] = {
        "tank",
        "tank_threat_colors",
        "tap_denied_colors",
        "color_override",
        "color_override_colors",
        "aggro_modifies",
        "aggro_can_check_notank",
        "dps",
        "show_aggro_flash",
        "show_aggro_glow",
    },
    ["Target"] = {},
    ["Cast Bar"] = {},
    ["Scripting"] = {
        "script_data",
        "script_auto_imported",
        "cvar_default_cache",
    },
    ["Modding"] = {
        "hook_data",
        "hook_auto_imported",
    },
    ["Personal Bar"] = {},
    ["Buff Settings"] = {},
    ["Buff Tracking"] = {
        "aura_tracker",
    },
    ["Buff Special"] = {
        "extra_icon_auras",
        "extra_icon_auras_mine",
    },
    ["Ghost Auras"] = {
        "ghost_auras",
    },
    ["Enemy NPC"] = {},
    ["Enemy Player"] = {},
    ["Friendly NPC"] = {},
    ["Friendly Player"] = {},
    ["NPC Colors and Names"] = {
        "npc_colors",
        "npcs_renamed",
        "npc_cache",
    },
    ["Cast Colors and Names"] = {
        "cast_colors",
        "cast_color_settings",
        "cast_audiocues",
        "cast_audiocue_cooldown",
        "cast_audiocues_channel",
        "npc_cache",
    },
    ["Spell List"] = {},
    ["Spell Feedback"] = {
        "spell_animation_list",
    },
    ["Auto"] = {},
    ["Advanced"] = {},
    ["Combo Points"] = {},
}
