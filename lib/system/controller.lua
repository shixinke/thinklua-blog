local _M = {
    _VERSION = '0.01'
}

local ngx_req = ngx.req
local view = require 'system.view'
local header = ngx.header
local ok = ngx.HTTP_OK
local session = require 'system.session'

function json(code, message, data)
    local tab = {}
    if type(code) == 'table' then
        tab = code
    else
        tab.code = code or 0
        tab.message = message or ''
        tab.data = data or {}
    end
    return cjson.encode(tab)
end

function _M.init_view(self)
    self.view = view.new(self)
end

function _M.assign(self, name, value)
    self.view:assign(name, value)
end

function _M.get(self, name)
    local data = func.merge(self.params, ngx_req.get_uri_args())
    if name then
        if data and data[name] then
            return data[name]
        end
    else
        return data
    end
end

function _M.post(self, name)
    ngx_req.read_body()
    local data = ngx_req.get_post_args()
    if name then
        if data and data[name] then
            return data[name]
        end
    else
        return data
    end
end

local function get_method()
    return string.lower(ngx_req.get_method())
end

function _M.is_get()
    local method = get_method()
    if method == 'get' then
        return true
    else
        return false
    end
end

function _M.is_post()
    local method = get_method()
    if method == 'post' then
        return true
    else
        return false
    end
end

function _M.display(self, tpl, data)
    if data then
        self:assign(data)
    end
    if not tpl then
        local view_suffix = (config.views.file_suffix and config.views.file_suffix ~= '') and config.views.file_suffix or '.html'
        if self.layer then
            tpl = self.layer..'/'..self.controller..'/'..self.action..view_suffix
        else
            tpl = self.controller..'/'..self.action..view_suffix
        end
    end
    self.view:display(tpl, data)
end

function _M.json(code, message, data)
    header.header = 'content-type:application/json;charset='..config.pages.charset
    ngx.say(json(code, message, data))
    ngx.exit(ok)
end

function _M.jsonp(code, message, data, callback)
    header.header = 'content-type:application/json;charset='..config.pages.charset
    local callback = type(code) == 'table' and message or callback
    local msg = callback..'('..json(code, message, data)..')'
    ngx.say(msg)
    ngx.exit(ok)
end

function _M.check_login(self)
    local user_info = self.login_info()
    if not user_info then
        self.json(5006, '用户未登录')
    else
        self.json(200, '用户已登录', user_info)
    end
end

function _M.login_info()
    local user_info = session:get('login_user')
    if not user_info or type(user_info) ~= 'table' or  not user_info['uid'] or user_info['uid'] < 1 then
        return nil
    else
        return user_info
    end
end

return _M