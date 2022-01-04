--[[
MIT License

Copyright (c) 2018 Vermintide Mod Framework

All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]] --
-- ####################################################################################################################
-- ##### VMF Hooks #############################################################################################
-- ####################################################################################################################
local HOOK_TYPES = {hook = 1, hook_safe = 2, hook_origin = 3}

local HOOK_TYPE_NORMAL = 1
local HOOK_TYPE_SAFE = 2
local HOOK_TYPE_ORIGIN = 3

local _delayed = {}
local _delaying_enabled = true

local auto_table_meta = {
  __index = function(t, k)
    t[k] = {}
    return t[k]
  end
}

local _registry = setmetatable({}, auto_table_meta)
_registry.uids = {}

local _hooks = {
  setmetatable({}, auto_table_meta), -- normal
  setmetatable({}, auto_table_meta), -- safe
  {} -- origin
}

local _origs = {}

local function get_return_values(...)
  local num = select('#', ...)
  return num, {...}
end

local function can_rehook(hook_data, obj, hook_type)
  if hook_data.obj == obj and hook_data.hook_type == hook_type then
    return true
  end
end

-- Search global table for an object that matches to get a readable string.
local function print_obj(obj)
  for k, v in pairs(_G) do
    if v == obj then
      return k
    end
  end
  return obj
end

-- This will tell us if we already have the given function in our registry.
local function is_orig_hooked(obj, method)
  if _origs[obj] and _origs[obj][method] then
    return true
  end
  return false
end

-- Since we replace the original function, we need to keep its reference around.
-- This will grab the cached reference if we hooked it before, otherwise return the function.
local function get_orig_function(obj, method)
  if is_orig_hooked(obj, method) then
    return _origs[obj][method]
  else
    return obj[method]
  end
end

-- Return an object from the global table. Second return value is if it was successful.
local function get_object_reference(obj)
  if type(obj) == "table" then
    return obj, true
  elseif type(obj) == "string" then
    local obj_table = rawget(_G, obj)
    if obj_table then
      return obj_table, true
    end
  end
  return obj, false
end

local function get_hook_chain(orig, unique_id)
  local hook_registry = _hooks
  local hooks = hook_registry[HOOK_TYPE_NORMAL][unique_id]
  if hooks and #hooks > 0 then
    return hooks[#hooks]
  end
  -- We can't simply return orig here, or it would cause origins to depend on load order.
  return function(...)
    if hook_registry[HOOK_TYPE_ORIGIN][unique_id] then
      return hook_registry[HOOK_TYPE_ORIGIN][unique_id](...)
    else
      return orig(...)
    end
  end
end

-- Returns a table containing hook data inside of it.
local function create_hook_data(obj, orig, handler, hook_type)
  return {active = true, hook_type = hook_type, handler = handler, orig = orig, obj = obj}
end

local function create_specialized_hook(mod, unique_id, hook_type)
  local func
  local hook_data = _registry[mod][unique_id]
  local orig = hook_data.orig

  -- Determine the previous function in the hook stack
  local previous_hook = get_hook_chain(orig, unique_id)

  if hook_type == HOOK_TYPE_NORMAL then
    func = function(...)
      if hook_data.active then
        return hook_data.handler(previous_hook, ...)
      else
        return previous_hook(...)
      end
    end
    -- Make sure hook_origin directly calls the original function if inactive.
  elseif hook_type == HOOK_TYPE_ORIGIN then
    func = function(...)
      if hook_data.active then
        return hook_data.handler(...)
      else
        return orig(...)
      end
    end
  elseif hook_type == HOOK_TYPE_SAFE then
    func = function(...)
      if hook_data.active then
        mod:safe_call_nr("(safe_hook)", hook_data.handler, ...)
      end
    end
  end
  return func
end

local function create_internal_hook(orig, obj, method)
  local fn -- Needs to be over two line to be usable within the closure.
  fn = function(...)
    local hook_chain = get_hook_chain(orig, fn)
    local num_values, values = get_return_values(hook_chain(...))

    local safe_hooks = _hooks[HOOK_TYPE_SAFE][fn]
    if safe_hooks and #safe_hooks > 0 then
      for i = 1, #safe_hooks do
        safe_hooks[i](...)
      end
    end
    ---@diagnostic disable-next-line: deprecated
    return unpack(values, 1, num_values)
  end

  if not _origs[obj] then
    _origs[obj] = {}
  end
  _origs[obj][method] = orig
  obj[method] = fn
  return fn
end

local function create_hook(mod, orig, obj, method, handler, func_name, hook_type)
  local unique_id

  if not is_orig_hooked(obj, method) then
    unique_id = create_internal_hook(orig, obj, method)
    _registry.uids[unique_id] = orig
  else
    unique_id = obj[method]
  end
  mod:info("(%s): Hooking '%s' from [%s] (Origin: %s)", func_name, method, print_obj(obj), orig)

  -- Check to make sure this mod hasn't hooked it before
  local hook_data = _registry[mod][unique_id]
  if not hook_data then
    _registry[mod][unique_id] = create_hook_data(obj, orig, handler, hook_type)

    local hook_registry = _hooks[hook_type]
    if hook_type == HOOK_TYPE_ORIGIN then
      if hook_registry[unique_id] then
        mod:error("(%s): Attempting to hook origin of already hooked function %s", func_name, method)
      else
        hook_registry[unique_id] = create_specialized_hook(mod, unique_id, hook_type)
      end
    else
      table.insert(hook_registry[unique_id], create_specialized_hook(mod, unique_id, hook_type))
    end
  else
    -- If hook_data already exists and it's the same hook_type, we can safely change the hook handler.
    -- This should (in practice) only be used for debugging by modders who uses DoFile.
    -- Revisit purpose when lua files are in plain text.
    if can_rehook(hook_data, obj, hook_type) then
      mod:warning("(%s): Attempting to rehook active hook [%s].", func_name, method)
      hook_data.handler = handler
    else
      -- If we can't rehook but rehooking is enabled, send a warning that something went wrong
      mod:warning("(%s): Attempting to rehook active hook [%s] with different obj or hook_type.",
                  func_name, method)
    end
  end

end

local function generic_hook(mod, obj, method, handler, func_name)
  if mod:check_wrong_argument_type(func_name, "obj", obj, "string", "table") or
      mod:check_wrong_argument_type(func_name, "method", method, "string", "function") or
      mod:check_wrong_argument_type(func_name, "handler", handler, "function", "nil") then
    return
  end

  if not handler then
    obj, method, handler = _G, obj, method
    if not method then
      mod:error("(%s): trying to create hook without giving a method name.", func_name)
      return
    end
  end

  local hook_type = HOOK_TYPES[func_name]

  local obj, success = get_object_reference(obj)
  if obj and not success then
    if _delaying_enabled and type(obj) == "string" then
      -- Call this func at a later time, using upvalues.
      mod:info("(%s): [%s.%s] needs to be delayed.", func_name, obj, method)
      table.insert(_delayed, function()
        generic_hook(mod, obj, method, handler, func_name)
      end)
      return
    else
      mod:error("(%s): trying to hook object that doesn't exist: %s", func_name, obj)
      return
    end
  end

  if not obj[method] then
    mod:error("(%s): trying to hook function or method that doesn't exist: [%s.%s]", func_name,
              print_obj(obj), method)
    return
  end

  local orig = get_orig_function(obj, method)
  if type(orig) ~= "function" then
    mod:error("(%s): trying to hook %s (a %s), not a function.", func_name, method, type(orig))
    return
  end

  if _registry.uids[orig] then
    orig = _registry.uids[orig]
  end

  return create_hook(mod, orig, obj, method, handler, func_name, hook_type)
end

VT2Korean.hook_safe = function(self, obj, method, handler)
  return generic_hook(self, obj, method, handler, "hook_safe")
end

VT2Korean.hook = function(self, obj, method, handler)
  return generic_hook(self, obj, method, handler, "hook")
end

VT2Korean.hook_origin = function(self, obj, method, handler)
  return generic_hook(self, obj, method, handler, "hook_origin")
end

VT2Korean.unload_hooks = function()
  for key, value in pairs(_origs) do
    if type(value) == "function" then
      _G[key] = value
    elseif type(value) == "table" then
      for method, orig in pairs(value) do
        key[method] = orig
      end
    end
  end
end

VT2Korean.apply_delayed_hooks = function(self, status, state)
  if status == "enter" and state == "StateIngame" then
    _delaying_enabled = false
  end

  if #_delayed > 0 then
    self:info("Attempt to hook %s delayed hooks", #_delayed)
    for i = #_delayed, 1, -1 do
      _delayed[i]()
      table.remove(_delayed, i)
    end
  end
end

return
