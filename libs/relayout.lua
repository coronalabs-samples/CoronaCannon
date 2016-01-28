local _M = {}

_M._W, _M._H = display.actualContentWidth, display.actualContentHeight
_M._CX, _M._CY = _M._W / 2, _M._H / 2

local _ = {_W = _M._W, _H = _M._H, _CX = _M._CX, _CY = _M._CY}

local function relayout()
    for i = #_M.relayoutListeners, 1, -1 do
        local l = _M.relayoutListeners[i]
        if type(l) == 'function' then
            l()
        elseif type(l) == 'table' then
            if not l.x then
                table.remove(_M.relayoutListeners, i)
            else
                if type(l.relayout) == 'function' then
                    l:relayout()
                else
                    local r = l._relayout
                    if r.anchor then
                        l.x, l.y = r.anchor.x * _M._W + r.anchor.offset.x, r.anchor.y * _M._H + r.anchor.offset.y
                    end
                    if r.width then
                        l.width = _M._W
                    end
                    if r.height then
                        l.height = _M._H
                    end
                end
            end
        end
    end
end

function _M.add(listener)
    if not _M.relayoutListeners then
        _M.relayoutListeners = {}
        Runtime:addEventListener('resize', relayout)
    end
    table.insert(_M.relayoutListeners, listener)
    if type(listener) == 'table' and not listener.relayout then
        listener._relayout = {}
        if listener.width == _M._W then
            listener._relayout.width = true
        end
        if listener.height == _M._H then
            listener._relayout.height = true
        end
        local anchor = {}
        for anchorX = 0, 1, 0.5 do
            for anchorY = 0, 1, 0.5 do
                local distance = math.sqrt((anchorX * _M._W - listener.x) ^ 2 + (anchorY * _M._H - listener.y) ^ 2)
                if not anchor.distance or anchor.distance > distance then
                    anchor.x, anchor.y, anchor.distance = anchorX, anchorY, distance
                    anchor.offsetX, anchor.offsetY = listener.x - anchorX * _M._W, listener.y - anchorY * _M._H
                end
            end
        end
        if anchor.distance < math.max(_M._W * 0.33, _M._H * 0.33) then
            listener._relayout.anchor = {
                x = anchor.x, y = anchor.y,
                offset = {
                    x = anchor.offsetX, y = anchor.offsetY
                }
            }
        end
    end
    return listener
end

function _M.remove(listener)
    if not listener or not _M.relayoutListeners then return end
    local ind = table.indexOf(_M.relayoutListeners, listener)
    if ind then
        table.remove(_M.relayoutListeners, ind)
        if #_M.relayoutListeners == 0 then
            _M.removeAll()
        end
    end
end

function _M.removeAll()
    Runtime:removeEventListener('resize', relayout)
    _M.relayoutListeners = nil
end

Runtime:addEventListener('resize', function()
    _M._W, _M._H = display.actualContentWidth, display.actualContentHeight
    _M._CX, _M._CY = _M._W / 2, _M._H / 2
    local stage = display.getCurrentStage()
    stage.x, stage.y = display.screenOriginX, display.screenOriginY
end)

return _M
