local vt2_korean_object = {}

vt2_korean_object.init = function()
  VT2Korean = {}
  dofile("scripts/mods/VT2Korean/VT2Korean")
  VT2Korean.on_init()
end

vt2_korean_object.update = function(dt)
end

vt2_korean_object.on_unload = function()
  VT2Korean.on_unload()
end

vt2_korean_object.on_reload = function()
  VT2Korean.on_reload()
end

vt2_korean_object.on_game_state_changed = function(status, state)
end

return vt2_korean_object
