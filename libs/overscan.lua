-- This library deals with the overscan issue that is present on many TVs.
-- It's doing so by scaling down composer.stage and drawing a black border around it so nothing else is visible.
local composer = require('composer')
local relayout = require('libs.relayout')

local _M = {}

_M.value = 0 -- Level of compensation: 0, 1, 2, 3.

local function getVericies(h, v)
    -- Polygon shape verticies, looks like a hollow rectangle, but a polygon can't have holes in it,
    -- so it's a twisted thick line instead.
    local _W, _H = relayout._W, relayout._H
    local verticies = {
        0,0, _W,0, _W,_H, 0,_H,
        0,v, h,v, h,_H-v, _W-h,_H-v, _W-h,v-0.001, 0,v-0.001 -- Change coordinate slightly so it doesn't intersect itself
    }
    return verticies
end

function _M.compensate(value)
    local self = _M
    local _W, _H, _CX, _CY = relayout._W, relayout._H, relayout._CX, relayout._CY
    self.value = value
    local percentage = self.value * 0.025

    if self.overlay then
        self.overlay:removeSelf()
        self.overlay = nil
    end
    if self.value > 0 then
        -- Create an black frame around app's content
        self.overlay = display.newPolygon(_CX, _CY, getVericies(percentage * _W, percentage * _H))
        self.overlay:setFillColor(0)
    end

    -- Shrink app's content to be visible on a TV with an overscan issue
    local stage = composer.stage
    stage.xScale = 1 - percentage * 2
    stage.yScale = stage.xScale
    stage.x, stage.y = percentage * _W, percentage * _H
end

return _M
