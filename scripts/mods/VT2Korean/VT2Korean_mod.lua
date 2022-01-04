local mod = VT2KoreanMod

-- HUGE Is this okay? We will see...
local korean_translation_table = dofile("scripts/mods/VT2Korean/korean_translation_table")

local korean_state = true

local original_fonts = Fonts
-- Probably .notdef glyph fixed
local custom_font_path = "fonts/mods/VT2Korean/KoPubWorld Batang_Pro Medium_subset"
local custom_fonts = {
  arial = {custom_font_path, 14, "arial"},
  arial_masked = {custom_font_path, 14, "arial", Gui.Masked},
  arial_write_mask = {custom_font_path, 14, "arial", Gui.WriteMask},
  hell_shark_arial = {custom_font_path, 14, "arial"},
  hell_shark_arial_masked = {custom_font_path, 14, "arial", Gui.Masked},
  hell_shark_arial_write_mask = {custom_font_path, 14, "arial", Gui.WriteMask},
  hell_shark = {custom_font_path, 20, "gw_body"},
  hell_shark_masked = {custom_font_path, 20, "gw_body", Gui.Masked},
  hell_shark_write_mask = {custom_font_path, 20, "gw_body", Gui.WriteMask},
  hell_shark_header = {custom_font_path, 20, "gw_head"},
  hell_shark_header_masked = {custom_font_path, 20, "gw_head", Gui.Masked},
  hell_shark_header_write_mask = {custom_font_path, 20, "gw_head", Gui.WriteMask},
  chat_output_font = {
    custom_font_path, 14, "arial", Gui.MultiColor + Gui.ForceSuperSampling + Gui.FormatDirectives
  },
  chat_output_font_masked = {
    custom_font_path, 14, "arial",
    Gui.MultiColor + Gui.ForceSuperSampling + Gui.FormatDirectives + Gui.Masked
  }
}

--- From UIManager.reload_ingame_ui
local function reload_sources()
  DeadlockStack.pause()

  if Managers.ui then
    Managers.ui:reload_ingame_ui(true)
    collectgarbage()
    DeadlockStack.unpause()
    return
  end

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

local function load_custom_font()
  Fonts = custom_fonts
  -- For Korean Chat compatible
  Fonts.kobatang_arial = original_fonts.arial
  Fonts.kobatang_chat_output_font = original_fonts.chat_output_font
end

local function unload_custom_font()
  Fonts = original_fonts
  -- For Korean Chat compatible
  Fonts.kobatang_arial = original_fonts.arial
  Fonts.kobatang_chat_output_font = original_fonts.chat_output_font
end

mod.on_init = function()
  load_custom_store_texture()
  load_custom_font()
  reload_sources()
end

mod.on_unload = function()
  unload_custom_font()
end

mod.on_reload = function()
  unload_custom_font()
end

mod.on_game_state_changed = function(status, state)
end

mod.update = function()
end

mod:hook(LocalizationManager, "_base_lookup", function(func, self, text_id)
  local text = korean_state and korean_translation_table[text_id]

  if text then
    return text
  end

  return func(self, text_id)
end)

local text_id_table = {}

-- Moded only
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

-- I don't know why, but these isn't localized... maybe widget.style.localize ?
-- {"title_text_victory", "title_text_defeat", "summary_title"} -- Return to keep

-- Weave widget text size should be not reduced
local scenegraph_id_blacklist = {
  "forge_level_title", "panel_level_title_1", "panel_level_value_1", "panel_level_title_2",
  "panel_level_value_2", "panel_level_title_3", "panel_level_value_3", "panel_power_title_1",
  "panel_power_value_1", "panel_power_title_2", "panel_power_value_2", "panel_power_title_3",
  "panel_power_value_3", "viewport_title_1", "viewport_title_2", "viewport_title_3",
  "viewport_sub_title_1", "viewport_sub_title_2", "viewport_sub_title_3", "loadout_power_title",
  "viewport_title", "viewport_sub_title", "panel_level_title", "panel_level_value",
  "panel_power_title", "panel_power_value"
}

-- Some text is not localized so
mod:hook(UIWidgets, "create_simple_text",
         function(func, text, scenegraph_id, size, color, text_style, optional_font_style, ...)
  local reduce_font_size = 25

  if not table.contains(scenegraph_id_blacklist, scenegraph_id) then
    if scenegraph_id == "loadout_power_text" then
      reduce_font_size = 8
    end
    if scenegraph_id == "essence_text" then
      reduce_font_size = 5
    end

    local text_offset = (text_style and text_style.offset) or {0, 0, 2}
    local text_color = (text_style and text_style.text_color) or color or {255, 255, 255, 255}

    if not text_style then
      text_style = {
        vertical_alignment = "center",
        localize = true,
        horizontal_alignment = "center",
        word_wrap = true,
        font_size = size - reduce_font_size,
        font_type = optional_font_style or "hell_shark",
        text_color = text_color,
        offset = text_offset
      }
    else
      text_style.localize = true
      text_style.font_size = text_style.font_size - reduce_font_size
    end
  end

  return func(text, scenegraph_id, size, color, text_style, optional_font_style, ...)
end)

return
