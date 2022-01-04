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
---@class VT2Korean
VT2Korean = class(VT2Korean)

VT2Korean.init = function(self)
  self._print_cache = {}
end

VT2Korean.core_update = function(self)
  self:_print_cached_message()
end

VT2Korean._print_cached_message = function(self)
  local print_cache = self._print_cache
  local num_delayed_prints = #print_cache

  if num_delayed_prints > 0 and Managers.chat then
    for i = 1, num_delayed_prints, 1 do
      Managers.chat:add_local_system_message(1, print_cache[i], true)
    end

    table.clear(print_cache)
  end
end

VT2Korean.echo = function(self, str, ...)
  local concat_str = sprintf(tostring(str), ...)

  if Managers.chat then
    Managers.chat:add_local_system_message(1, concat_str, true)
  else
    self._print_cache[#self._print_cache + 1] = concat_str
  end
end

VT2Korean.error = function(self, str, ...)
  local concat_str = sprintf("[VT2Korean][ERROR] " .. str, ...)
  print(concat_str)
end

VT2Korean.info = function(self, str, ...)
  local concat_str = sprintf("[VT2Korean][INFO] " .. str, ...)
  print(concat_str)
end

VT2Korean.warning = function(self, str, ...)
  local concat_str = sprintf("[VT2Korean][WARNING] " .. str, ...)
  print(concat_str)
end

-- ####################################################################################################################
-- ##### VMF Exception control ########################################################################################
-- ####################################################################################################################

VT2Korean._show_error = function(self, error_prefix_data, error_message)
  local error_prefix
  if type(error_prefix_data) == "table" then
    error_prefix = string.format(error_prefix_data[1], error_prefix_data[2], error_prefix_data[3],
                                 error_prefix_data[4])
  else
    error_prefix = error_prefix_data
  end

  self:error("%s: %s", error_prefix, error_message)
end

VT2Korean.check_wrong_argument_type = function(self, function_name, argument_name, argument, ...)
  local allowed_types = {...}
  local argument_type = type(argument)

  for _, allowed_type in ipairs(allowed_types) do
    if allowed_type == argument_type then
      return false
    end
  end

  self:error("(%s): argument '%s' should have the '%s' type, not '%s'", function_name,
             argument_name, table.concat(allowed_types, "/"), argument_type)
  return true
end

local function pack_pcall(status, ...)
  return status, {n = select('#', ...), ...}
end

local function print_error_callstack(error_message)
  if type(error_message) == "table" and error_message.error then
    error_message = error_message.error
  end
  print("Error: " .. tostring(error_message) .. "\n" .. Script.callstack())
  return error_message
end

-- Safe Call
VT2Korean.safe_call = function(self, error_prefix_data, func, ...)
  local success, return_values = pack_pcall(xpcall(func, print_error_callstack, ...))
  if not success then
    self:_show_error(error_prefix_data, return_values[1])
    return success
  end
  ---@diagnostic disable-next-line: deprecated
  return success, unpack(return_values, 1, return_values.n)
end

-- Safe Call [No return values]
VT2Korean.safe_call_nr = function(self, error_prefix_data, func, ...)
  local success, error_message = xpcall(func, print_error_callstack, ...)
  if not success then
    self:_show_error(error_prefix_data, error_message)
  end
  return success
end

-- Safe Call [No return values and error callstack]
VT2Korean.safe_call_nrc = function(self, error_prefix_data, func, ...)
  local success, error_message = pcall(func, ...)
  if not success then
    self:_show_error(error_prefix_data, error_message)
  end
  return success
end

return
