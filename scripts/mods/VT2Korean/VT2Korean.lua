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

  for _, pkg in ipairs(package.load_order) do
    if string.find(pkg, "^scripts/ui") then
      require(pkg)
    end
  end

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

local function on_init()
  load_custom_store_texture()
  table.insert(Managers.localizer._localizers, 1, Localizer("localization/mods/korean"))
  reload_ingame_ui()
  for _, font in pairs(Fonts) do
    font[1] = custom_font_path
  end
end

local function on_unload()
  table.remove(Managers.localizer._localizers, 1)
  Fonts = original_fonts
end

local function on_reload()
  on_unload()
end

local vt2_korean_object = {}

vt2_korean_object.init = function()
  on_init()
end

vt2_korean_object.update = function(dt)
end

vt2_korean_object.on_unload = function()
  on_unload()
end

vt2_korean_object.on_reload = function()
  on_reload()
end

vt2_korean_object.on_game_state_changed = function(status, state)
end

return vt2_korean_object
