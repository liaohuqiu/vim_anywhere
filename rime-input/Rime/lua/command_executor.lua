local registry = require('command_registry')

local kRejected = 0
local kAccepted = 1
local kNoop = 2

local function generic_open(dest)
  if os.execute('start "" ' .. dest) then
    return true
  elseif os.execute('open ' .. dest) then
    return true
  elseif os.execute('xdg-open ' .. dest) then
    return true
  end
  return false
end

local function get_command_candidate_by_index(context, index)
  local composition = context.composition
  if composition:empty() then
    return nil
  end
  local segment = composition:back()
  if not segment or not segment.menu or index < 0 or index >= segment.menu:candidate_count() then
    return nil
  end
  local candidate = segment:get_candidate_at(index)
  if candidate and candidate.type == 'command' then
    return candidate
  end
  return nil
end

local function get_selected_command_candidate(context)
  if not context:has_menu() then
    return nil
  end
  local candidate = context:get_selected_candidate()
  if candidate and candidate.type == 'command' then
    return candidate
  end
  return nil
end

local function execute_command(candidate, context)
  local command = registry.find(candidate.comment)
  if not command then
    return kRejected
  end
  generic_open(command.url)
  context:clear()
  return kAccepted
end

local function processor(key, env)
  local context = env.engine.context
  local input = context.input or ''
  if not registry.find(input) or not context:has_menu() then
    return kNoop
  end

  local repr = key:repr()
  if repr == 'space' or repr == 'Return' or repr == 'KP_Enter' then
    local candidate = get_selected_command_candidate(context)
    if candidate then
      return execute_command(candidate, context)
    end
    return kNoop
  end

  local index = nil
  if repr == '1' then
    index = 0
  elseif repr:match('^[2-9]$') then
    index = tonumber(repr) - 1
  elseif repr == '0' then
    index = 9
  end
  if index == nil then
    return kNoop
  end

  local candidate = get_command_candidate_by_index(context, index)
  if candidate then
    return execute_command(candidate, context)
  end
  return kNoop
end

return processor
