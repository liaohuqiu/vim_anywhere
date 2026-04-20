local registry = require('command_registry')

local function translator(input, seg, env)
  local command = registry.find(input)
  if not command then
    return
  end
  local candidate = Candidate('command', seg.start, seg._end, command.label, input)
  yield(candidate)
end

return translator
