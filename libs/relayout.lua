-- Relayout
-- This library helps position elements on the screen during the resize event
local _M = {}

-- Short names for screen width/height and it's center coordinates
-- They get updated on resize event
_M._W, _M._H = display.actualContentWidth, display.actualContentHeight
_M._CX, _M._CY = _M._W / 2, _M._H / 2

-- Perform actual relayout for each listener object or function
local function relayout()
    for i = #_M.relayoutListeners, 1, -1 do
        local l = _M.relayoutListeners[i]
        if type(l) == 'function' then -- Listener is a simple function
            l()
        elseif type(l) == 'table' then -- Listener is a display object
            if not l.x then -- Remove removeSelf()'ed objects from the list
                table.remove(_M.relayoutListeners, i)
            else
                if type(l.relayout) == 'function' then -- Object has object:relayout() function
                    l:relayout()
                else -- If not, perform automatic repositioning
                    local r = l._relayout
                    if r.anchor then -- Which screen corner is the object positioned closer to
                        l.x, l.y = r.anchor.x * _M._W + r.anchor.offset.x, r.anchor.y * _M._H + r.anchor.offset.y
                    end
                    if r.width then -- Full screen width
                        l.width = _M._W
                    end
                    if r.height then -- Full screen height
                        l.height = _M._H
                    end
                end
            end
        end
    end
end

-- Add a listener to the internal list
-- Listener can be a function, an object with a :relayout() method or just a display object
-- If it's an ordinary display object, calculate data for it's automatic repositioning
function _M.add(listener)
    if not _M.relayoutListeners then
        _M.relayoutListeners = {}
        Runtime:addEventListener('resize', relayout)
    end
    table.insert(_M.relayoutListeners, listener)
    if type(listener) == 'table' and not listener.relayout then
        -- Data for automatic repositioning
        listener._relayout = {}
        if listener.width == _M._W then -- Full screen width
            listener._relayout.width = true
        end
        if listener.height == _M._H then -- Full screen height
            listener._relayout.height = true
        end
        local anchor = {}
        for anchorX = 0, 1, 0.5 do -- Iterate through all screen corners and edges and find the closest one
            for anchorY = 0, 1, 0.5 do
                local distance = math.sqrt((anchorX * _M._W - listener.x) ^ 2 + (anchorY * _M._H - listener.y) ^ 2)
                if not anchor.distance or anchor.distance > distance then
                    anchor.x, anchor.y, anchor.distance = anchorX, anchorY, distance
                    anchor.offsetX, anchor.offsetY = listener.x - anchorX * _M._W, listener.y - anchorY * _M._H
                end
            end
        end
        if anchor.distance < math.max(_M._W * 0.33, _M._H * 0.33) then
            listener._relayout.anchor = { -- Add found anchor to the repositioning data
                x = anchor.x, y = anchor.y,
                offset = {
                    x = anchor.offsetX, y = anchor.offsetY
                }
            }
        end
    end
    return listener
end

-- Remove the given listener from the internal list
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

-- Always listen for the resize event to update variables
Runtime:addEventListener('resize', function()
    _M._W, _M._H = display.actualContentWidth, display.actualContentHeight
    _M._CX, _M._CY = _M._W / 2, _M._H / 2 -- display.contentCenterX/Y don't work here, because they are not display.actualContentCenterX/Y
    -- Move the content area of Corona SDK app to be always at the top left corner
    -- You may want to not desire this for your app
    local stage = display.getCurrentStage()
    stage.x, stage.y = display.screenOriginX, display.screenOriginY
end)

return _M
