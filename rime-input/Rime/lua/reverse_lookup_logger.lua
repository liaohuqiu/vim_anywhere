local kNoop = 2

local function escape_json(value)
  return (value:gsub('[%z\1-\31\\"]', {
    ['\\'] = '\\\\',
    ['"'] = '\\"',
    ['\b'] = '\\b',
    ['\f'] = '\\f',
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['\t'] = '\\t',
  }):gsub('[%z\1-\31]', function(ch)
    return string.format('\\u%04x', ch:byte())
  end))
end

local function iso8601_now()
  local tz = os.date('%z')
  if tz and #tz == 5 then
    tz = tz:sub(1, 3) .. ':' .. tz:sub(4, 5)
  else
    tz = ''
  end
  return os.date('%Y-%m-%dT%H:%M:%S') .. tz
end

local function append_log(path, record)
  local file = io.open(path, 'a')
  if not file then
    log.error('reverse lookup logger: failed to open log file ' .. path)
    return
  end
  file:write(record)
  file:close()
end

local function contains_cjk(text)
  if not text or text == '' then
    return false
  end
  for _, codepoint in utf8.codes(text) do
    if (codepoint >= 0x3400 and codepoint <= 0x9FFF) or
       (codepoint >= 0xF900 and codepoint <= 0xFAFF) or
       (codepoint >= 0x20000 and codepoint <= 0x2EBEF) then
      return true
    end
  end
  return false
end

local function is_ascii_text(text)
  return text and text ~= '' and not text:find('[^\x00-\x7F]')
end

local function write_event(env, fields)
  local items = {}
  for _, key in ipairs({ 'ts', 'schema', 'event_type', 'query', 'commit_text' }) do
    local value = fields[key]
    if value ~= nil and value ~= '' then
      items[#items + 1] = string.format('"%s":"%s"', escape_json(key), escape_json(value))
    end
  end
  if fields.ascii_mode ~= nil then
    items[#items + 1] = string.format('"ascii_mode":%s', fields.ascii_mode and 'true' or 'false')
  end
  append_log(env.log_path, '{' .. table.concat(items, ',') .. '}\n')
end

local function reset_pending(env)
  env.pending_reverse_lookup = nil
  env.pending_ascii_input = nil
end

local function update_pending(ctx, env)
  if env.engine.schema.schema_id ~= 'tiger' then
    reset_pending(env)
    return
  end
  local input = ctx.input or ''
  local query = input:match("^`([a-z]+)'?$")
  if query then
    env.pending_reverse_lookup = query
    env.pending_ascii_input = nil
    return
  end
  if ctx:get_option('ascii_mode') and input ~= '' then
    env.pending_ascii_input = input
    env.pending_reverse_lookup = nil
    return
  end
  if input ~= '' then
    env.pending_reverse_lookup = nil
    env.pending_ascii_input = nil
    return
  end
  reset_pending(env)
end

local function log_commit(ctx, env)
  if env.engine.schema.schema_id ~= 'tiger' then
    reset_pending(env)
    return
  end
  local commit_text = ctx:get_commit_text()
  if not commit_text or commit_text == '' then
    return
  end
  local query = env.pending_reverse_lookup
  if query and query ~= '' then
    if commit_text ~= '`' .. query and contains_cjk(commit_text) then
      write_event(env, {
        ts = iso8601_now(),
        schema = env.engine.schema.schema_id,
        event_type = 'reverse_lookup_commit',
        query = query,
        commit_text = commit_text,
      })
    end
    reset_pending(env)
    return
  end
  if env.pending_ascii_input and is_ascii_text(commit_text) then
    write_event(env, {
      ts = iso8601_now(),
      schema = env.engine.schema.schema_id,
      event_type = 'ascii_english_commit',
      commit_text = commit_text,
      ascii_mode = true,
    })
    reset_pending(env)
    return
  end
  if contains_cjk(commit_text) then
    write_event(env, {
      ts = iso8601_now(),
      schema = env.engine.schema.schema_id,
      event_type = 'tiger_commit',
      commit_text = commit_text,
    })
  end
  reset_pending(env)
end

local function init(env)
  env.log_path = rime_api.get_user_data_dir() .. '/reverse_lookup.log'
  env.update_connection = env.engine.context.update_notifier:connect(function(ctx)
    update_pending(ctx, env)
  end)
  env.commit_connection = env.engine.context.commit_notifier:connect(function(ctx)
    log_commit(ctx, env)
  end)
end

local function func(key, env)
  return kNoop
end

local function fini(env)
  if env.update_connection then
    env.update_connection:disconnect()
  end
  if env.commit_connection then
    env.commit_connection:disconnect()
  end
end

return {
  init = init,
  func = func,
  fini = fini,
}
