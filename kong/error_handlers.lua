local kong = kong
local find = string.find
local fmt  = string.format
local utils = require "kong.tools.utils"
local request_id = require "kong.tracing.request_id"


local CONTENT_TYPE    = "Content-Type"
local ACCEPT          = "Accept"
local TYPE_GRPC       = "application/grpc"


local BODIES = {
  [400] = "Bad request",
  [404] = "Not found",
  [405] = "Method not allowed",
  [408] = "Request timeout",
  [411] = "Length required",
  [412] = "Precondition failed",
  [413] = "Payload too large",
  [414] = "URI too long",
  [417] = "Expectation failed",
  [425] = "Too Early",
  [426] = "Upgrade required",
  [428] = "Precondition required",
  [429] = "Too many requests",
  [494] = "Request header or cookie too large",
  [500] = "An unexpected error occurred",
  [502] = "An invalid response was received from the upstream server",
  [503] = "The upstream server is currently unavailable",
  [504] = "The upstream server is timing out",
  [580] = "An unexpected error occurred",
  [581] = "An unexpected error occurred",
  [582] = "An invalid response was received from the upstream server",
  [583] = "The upstream server is currently unavailable",
  [584] = "Gateway Timeout",
  [585] = "HTTP Version Not Supported",
  [586] = "Variant Also Negotiates",
  [587] = "Insufficient Storage",
  [588] = "Loop Detected",
  default = "The upstream server responded with %d"
}

local function interp(s, tab)
    return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

local function read_file(path)
    local f = io.open(path, "r") -- r read mode and b binary mode
    if not f then return nil end
    local content = f:read("*a") -- *a or *all reads the whole file
    f:close()
    return content
end

local get_body
do
  local DEFAULT_FMT = "The upstream server responded with %d"

  get_body = function(ctx)
    local status = kong.response.get_status()
    local accept_header = kong.request.get_header(ACCEPT)
    if accept_header == nil then
      accept_header = kong.request.get_header(CONTENT_TYPE)
      if accept_header == nil then
        accept_header = kong.configuration.error_default_type
      end
    end

    local mime_type = utils.get_response_type(accept_header)

    if status >= 500 and status < 510 then
      status = status + 80
    end
    
    local message = BODIES[status] or fmt(DEFAULT_FMT, status)

    -- Hack to output CSS in error page
    local path = ngx.var.request_uri
    if path == "/g-in/4xx.css" then
      local resource_4xx = "/usr/local/share/lua/5.1/kong/templates/4xx.css"
      message = read_file(resource_4xx)
      status = 200
      mime_type = "text/css; charset=utf-8"
    end


    if accept_header == "*/*" or string.find(accept_header, "html") then
      accept_header = "text/html"
      local accept_lang = kong.request.get_header("Accept-Language")
      local template_4xx = ""
      
      if accept_lang and string.find(accept_lang, 'zh')
      then
          template_4xx = "/usr/local/share/lua/5.1/kong/templates/kong_error_4xx-zh.html"
      else
          template_4xx = "/usr/local/share/lua/5.1/kong/templates/kong_error_4xx-en.html"
      end
      local template_5xx = "/usr/local/share/lua/5.1/kong/templates/kong_error_5xx.html"
      local template_error = (status < 500) and template_4xx or template_5xx
      local tmpl = read_file(template_error)
      local headers = ngx.req.get_headers()
      local status_text = ctx.MESSAGE or BODIES["s" .. status] or fmt(BODIES.default, status)
      local request = ngx.var.request_method .. " " .. ngx.var.request_uri .. " " .. ngx.var.server_protocol

      local user_agent = headers['user-agent']
      if user_agent == nil then
        user_agent = "unknown"
      elseif type(user_agent) == 'table' then
        user_agent = table.concat(user_agent, ", ")
      end

      local tmpl_res = interp(tmpl, {
        status_text = status_text, status = status, remote_addr =  ngx.var.remote_addr,
        host = headers["host"], http_referer = headers['referer'] or '(none)',
        hostname = kong.node.get_hostname(), date_local = ngx.http_time(ngx.req.start_time()),
        request = request, user_agent = user_agent
      })
      message = tmpl_res or fmt(BODIES.default, status)
    end

    return message, status, accept_header, mime_type
  end
end


return function(ctx)
  local message, status, accept_header, mime_type = get_body(ctx)

  local headers
  if find(accept_header, TYPE_GRPC, nil, true) == 1 then
    message = { message = message }

  else
    message = fmt(utils.get_error_template(mime_type), message, rid)
    headers = { [CONTENT_TYPE] = mime_type }

  end

  -- Reset relevant context values
  ctx.buffered_proxying = nil
  ctx.response_body = nil

  if ctx then
    ctx.delay_response = nil
    ctx.delayed_response = nil
    ctx.delayed_response_callback = nil
  end

  return kong.response.exit(status, message, headers)
end
