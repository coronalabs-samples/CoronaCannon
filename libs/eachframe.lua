-- EachFrame library
-- This is a handy manager for the enterFrame runtime event.
-- Listeners can be both functions and objects.
-- The point of this module is to have only one runtime listener to call all other listeners.
-- This leads to less runtime errors.
-- Don't forget to remove the listeners when they are not needed anymore. Use Corona's finalize event.

local _M = {}

local function enterFrame()
    for i = 1, #_M.enterFrameListeners do
        if type(_M.enterFrameListeners[i]) == 'function' then
            _M.enterFrameListeners[i]()
        elseif type(_M.enterFrameListeners[i]) == 'table' and type(_M.enterFrameListeners[i].eachFrame) == 'function' then
            _M.enterFrameListeners[i]:eachFrame()
        end
    end
end

function _M.add(listener)
    if not _M.enterFrameListeners then
        _M.enterFrameListeners = {}
        Runtime:addEventListener('enterFrame', enterFrame)
    end
    table.insert(_M.enterFrameListeners, listener)
    return listener
end

function _M.remove(listener)
    if not listener or not _M.enterFrameListeners then return end
    local ind = table.indexOf(_M.enterFrameListeners, listener)
    if ind then
        table.remove(_M.enterFrameListeners, ind)
        if #_M.enterFrameListeners == 0 then
            _M.removeAll()
        end
    end
end

function _M.removeAll()
    Runtime:removeEventListener('enterFrame', enterFrame)
    _M.enterFrameListeners = nil
end

return _M
