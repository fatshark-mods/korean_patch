local vt2korean

local vt2_korean_object = {}

vt2_korean_object.init = function()
  dofile("scripts/mods/VT2Korean/core/VT2Korean")
  dofile("scripts/mods/VT2Korean/core/hooks")

  vt2korean = VT2Korean:new()
  VT2KoreanMod = vt2korean

  dofile("scripts/mods/VT2Korean/VT2Korean_mod")
  vt2korean.on_init()
end

vt2_korean_object.update = function(dt)
  vt2korean:core_update()
  vt2korean.update()
end

vt2_korean_object.on_unload = function()
  vt2korean.unload_hooks()
  vt2korean.on_unload()
end

vt2_korean_object.on_reload = function()
  vt2korean.on_reload()
end

vt2_korean_object.on_game_state_changed = function(status, state)
  vt2korean:apply_delayed_hooks(status, state)
  vt2korean.on_game_state_changed(status, state)
end

return vt2_korean_object
