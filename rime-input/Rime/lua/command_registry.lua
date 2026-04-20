local command_registry = {}

local commands = {
  { ids = { '/huma', '/zhmn' }, label = '打开 Tiger 官网', url = 'https://tiger-code.com' },
  { ids = { '/baidu', '/bddu', '/fuxl' }, label = '打开百度', url = 'https://www.baidu.com' },
  { ids = { '/biying', '/bing', '/biyk', '/htxk' }, label = '打开 Bing', url = 'https://cn.bing.com' },
  { ids = { '/guge', '/google', '/hgzz' }, label = '打开 Google', url = 'https://www.google.com' },
  { ids = { '/wangpan', '/whpj', '/mbia' }, label = '打开虎码网盘', url = 'http://huma.ysepan.com' },
  { ids = { '/genda', '/gfda', '/piua', '/muyi', '/emon' }, label = '打开跟打器', url = 'https://typer.owenyang.top' },
  { ids = { '/zitong', '/zits', '/whib' }, label = '打开字统', url = 'https://zi.tools' },
  { ids = { '/yedian', '/yedm', '/dnih' }, label = '打开 Yedict', url = 'http://www.yedict.com' },
}

local by_id = {}
for _, command in ipairs(commands) do
  for _, id in ipairs(command.ids) do
    by_id[id] = command
  end
end

function command_registry.find(input)
  return by_id[input]
end

return command_registry
