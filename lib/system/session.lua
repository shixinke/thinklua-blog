local session = require 'resty.session'

local _M = {
    _VERSION = '0.01'
}

function _M.get_session(is_set)
    local sess;
    if is_set then
        sess = session.start({secret = config.security.session.secret})
    else
        sess = session.open({secret = config.security.session.secret})
    end
    return sess
end

-- 设置session的封闭(依赖于lua-resty-session)
function _M.set(key, value)
    local sess = session.start({secret = config.security.session.secret})
    if sess.data[key] then
        if type(value) == 'table' then
            for k, v in pairs(value) do
                sess.data[key][k] = v
            end
        else
            sess.data[key] = value
        end
    else
        sess.data[key] = value
    end
    return sess:save()
end

-- 获取session信息
function _M.get(key)
    local sess = session.open({secret = config.security.session.secret})
    local data = sess.data or {}
    if key then
        return data[key]
    end
    return data
end

return _M