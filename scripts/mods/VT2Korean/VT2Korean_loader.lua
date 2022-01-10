local vt2_korean_object = {}

vt2_korean_object.init = function()
  dofile("scripts/mods/VT2Korean/core/VT2Korean")
  dofile("scripts/mods/VT2Korean/core/hooks")

  VT2KoreanMod = VT2Korean:new()

  dofile("scripts/mods/VT2Korean/VT2Korean_mod")
  VT2KoreanMod.on_init()
end

vt2_korean_object.update = function(dt)
  VT2KoreanMod:core_update()
end

vt2_korean_object.on_unload = function()
  VT2KoreanMod.unload_hooks()
  VT2KoreanMod.on_unload()
end

vt2_korean_object.on_reload = function()
  VT2KoreanMod.on_reload()
end

vt2_korean_object.on_game_state_changed = function(status, state)
  VT2KoreanMod:apply_delayed_hooks(status, state)
end

return vt2_korean_object
