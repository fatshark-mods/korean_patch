local mod = VT2KoreanMod

local korean_translation_table = dofile("scripts/mods/VT2Korean/translation_table")

local korean_state = true

-- If Korean Patch is approved, Korean chat mod will be useless
local original_fonts = table.clone(Fonts)
local custom_font_path = "fonts/mods/VT2Korean/SourceHanSerifKR-Medium-subset"

--- From UIManager.reload_ingame_ui
local function reload_ingame_ui()
  DeadlockStack.pause()

  for pkg in pairs(package.loaded) do
    if string.find(pkg, "^scripts/ui") then
      package.loaded[pkg] = nil
    end
  end

  require("scripts/ui/views/ingame_ui")

  collectgarbage()
  DeadlockStack.unpause()
end

-- Bless is not done yet
local dlc_names = {
  "woods", "woods_upgrade", "cog", "cog_upgrade", "grass", "holly", "lake", "lake_upgrade"
}

-- Korean store texture! Thanks AmYumi.
local function load_custom_store_texture()
  for _, dlc in ipairs(dlc_names) do
    local dlc_index = table.find_by_key(StoreDlcSettings, "dlc_name", dlc)
    local dlc_settings = StoreDlcSettings[dlc_index]

    if dlc_settings then
      dlc_settings.store_banner_texture_paths = "textures/mods/dlc_store_banner_" .. dlc
      local layout_index = table.find_by_key(dlc_settings.layout, "id", "dlc_logo")
      local item = dlc_settings.layout[layout_index]

      if item then
        local str_start, str_end = string.find(dlc, "upgrade")

        if str_start and dlc ~= "lake_upgrade" then
          item.settings.texture_path = "textures/mods/dlc_store_logo_" ..
                                           string.sub(dlc, 1, str_end - 8)
        else
          item.settings.texture_path = "textures/mods/dlc_store_logo_" .. dlc
        end
      end
    end
  end
end

mod.on_init = function()
  load_custom_store_texture()
  for _, font in pairs(Fonts) do
    font[1] = custom_font_path
  end
  reload_ingame_ui()
end

mod.on_unload = function()
  Fonts = original_fonts
end

mod.on_reload = function()
  mod.on_unload()
end

mod:hook(LocalizationManager, "_base_lookup", function(func, self, text_id)
  local text = korean_state and korean_translation_table[text_id]

  if text then
    return text
  end

  return func(self, text_id)
end)

local text_id_table = {}

-- Modded only
if script_data["eac-untrusted"] then
  -- For scraping text_ids
  mod:hook("Localize", function(func, text_id)
    if not table.contains(text_id_table, text_id) then
      local concat_str = sprintf("[VT2Korean] text_id = %s", text_id)
      print(concat_str)
      table.insert(text_id_table, text_id)
    end
    return func(text_id)
  end)
end

-- Weave widget text size should not be reduced
local weave_widget_blacklist = {
  "forge_level_title", "panel_level_title_1", "panel_level_value_1", "panel_level_title_2",
  "panel_level_value_2", "panel_level_title_3", "panel_level_value_3", "panel_power_title_1",
  "panel_power_value_1", "panel_power_title_2", "panel_power_value_2", "panel_power_title_3",
  "panel_power_value_3", "viewport_title_1", "viewport_title_2", "viewport_title_3",
  "viewport_sub_title_1", "viewport_sub_title_2", "viewport_sub_title_3", "loadout_power_title",
  "viewport_title", "viewport_sub_title", "panel_level_title", "panel_level_value",
  "panel_power_title", "panel_power_value"
}

-- Some text isn't localized, like scoreboard and Return to keep
mod:hook(UIWidgets, "create_simple_text",
         function(func, text, scenegraph_id, size, color, text_style, optional_font_style, ...)
  local font_size_offset = 25

  if not table.contains(weave_widget_blacklist, scenegraph_id) then
    if scenegraph_id == "loadout_power_text" then
      font_size_offset = 8
    end
    if scenegraph_id == "essence_text" then
      font_size_offset = 5
    end
    if scenegraph_id == "text_area" then
      font_size_offset = 35
    end

    local text_offset = (text_style and text_style.offset) or {0, 0, 2}
    local text_color = (text_style and text_style.text_color) or color or {255, 255, 255, 255}

    if not text_style then
      text_style = {
        vertical_alignment = "center",
        localize = true,
        horizontal_alignment = "center",
        word_wrap = true,
        font_size = size - font_size_offset,
        font_type = optional_font_style or "hell_shark",
        text_color = text_color,
        offset = text_offset
      }
    else
      text_style.localize = true
      text_style.font_size = text_style.font_size - font_size_offset
    end
  end

  return func(text, scenegraph_id, size, color, text_style, optional_font_style, ...)
end)

return
