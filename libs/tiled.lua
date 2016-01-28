-- Tiled maps loading library
-- This library has basic, but sufficent support of Tiled lua format.
-- Adjust it according to your usage of Tiled, for example extra layer properties.

local physics = require('physics')
local bit = require('plugin.bit')

local eachframe = require('libs.eachframe')
local relayout = require('libs.relayout')

local FlippedHorizontallyFlag   = 0x80000000
local FlippedVerticallyFlag     = 0x40000000
local FlippedGiagonallyFlag     = 0x20000000
local ClearFlag                 = 0x1FFFFFFF

-- Break full path string into path and filename
local function extractPath(p)
    local c
    for i = p:len(), 1, -1 do
        c = p:sub(i, i)
        if c == '/' then
            return p:sub(1, i - 1), p:sub(i + 1)
        end
    end
end

-- Keep a value in boundaries
local function clamp(value, low, high)
    if value < low then value = low
    elseif high and value > high then value = high end
    return value
end

local function load(self, params)
    local _W, _H = relayout._W, relayout._H

    self.map = require(params.filename) -- Actual Tiled data
    package.loaded[params.filename] = nil -- Remove from memory in case it's updated during runtime
    self.specs = params.specs or {}

    self:prepareTilesets()

    self.snapshot = display.newSnapshot(params.g, _W, _H) -- All tiles go into this snapshot
    self.snapshot.x, self.snapshot.y = 0, 0
    self.group = self.snapshot.group
    self.snapshot.anchorX, self.snapshot.anchorY = 0, 0
    self.group.x, self.group.y = -self.snapshot.width / 2, -self.snapshot.height / 2

    local super = self
    function self.snapshot:relayout()
        self.width, self.height = relayout._W, relayout._H
        super.camera.high = {x = super.map.tilewidth * super.map.width - relayout._W, y = super.map.tilewidth * super.map.height - relayout._H}
        super:moveCamera(super.camera.x, super.camera.y)
    end
    relayout.add(self.snapshot)

    self.layers = {} -- Each Tiled layer has it's own group and they are stored here

    self.physicsGroup = display.newGroup() -- A separate group for physics objects
    params.g:insert(self.physicsGroup)
    self.physicsGroup.x, self.physicsGroup.y = self.snapshot.x, self.snapshot.y

    -- A set of properties for the camera
    self.camera = {
        x = 0, y = 0,
        xIncrement = 0, yIncrement = 0,
        low = {x = 0, y = 0},
        high = {x = self.map.tilewidth * self.map.width - _W, y = self.map.tilewidth * self.map.height - _H}
    }

    -- Tiled provides a background color
    local color = self.map.backgroundcolor
    self.map.backgroundcolor = {color[1] / 255, color[2] / 255, color[3] / 255}

    eachframe.add(self)
    function self.snapshot:finalize()
        eachframe.remove(super)
        relayout.remove(self)
    end
    self.snapshot:addEventListener('finalize')
end

-- Load all spritesheers into memory
local function prepareTilesets(self)
    self.tilesets = {}
    self.tileProperties = {}
    local map = self.map
    for i = 1, #map.tilesets do
        local t = map.tilesets[i]
        if t.image then
            local dir, filename = extractPath(t.image:sub(4))
            local spritesheet = graphics.newImageSheet(dir .. filename, {
                width = t.tilewidth,
                height = t.tileheight,
                sheetContentWidth = t.imagewidth,
                sheetContentHeight = t.imageheight,
                numFrames = (t.imagewidth / t.tilewidth) * (t.imageheight / t.tileheight)})
            table.insert(self.tilesets, spritesheet)
        end

        if t.tiles then
            self.tileProperties[t.name] = {}
            for j = 1, #t.tiles do
                local p = t.tiles[j]
                if p.properties then
                    self.tileProperties[t.name][p.id + 1] = p.properties
                else
                    self.tileProperties[t.name][p.id + 1] = {image = p.image:sub(4, p.image:len()), width = p.width, height = p.height}
                end
            end
        end
    end
end

local function getSpriteSheetByGid(self, gid)
    local map_tilesets = self.map.tilesets
    for i = #map_tilesets, 1, -1 do
        if map_tilesets[i].firstgid <= gid then
            return map_tilesets[i].name, self.tilesets[i], gid - map_tilesets[i].firstgid + 1
        end
    end
end

local function newTile(self, params)
    local map = self.map
    local gid = params.gid
    local flip = {}
    if gid > 1000 or gid < -1000 then
        flip.x = bit.band(gid, FlippedHorizontallyFlag) ~= 0
        flip.y = bit.band(gid, FlippedVerticallyFlag) ~= 0
        flip.xy = bit.band(gid, FlippedGiagonallyFlag) ~= 0
        gid = bit.band(gid, ClearFlag)
    end
    local sheetName, sheet, frameIndex = self:getSpriteSheetByGid(gid)
    local properties = self.tileProperties[sheetName] and self.tileProperties[sheetName][frameIndex] or {}
    local tile
    if sheet then
        tile = display.newImage(params.g, sheet, frameIndex)
        tile.x, tile.y = (params.x + 0.5) * map.tilewidth, (params.y + 0.5) * map.tileheight
    else
        tile = display.newImageRect(params.g, properties.image, properties.width, properties.height)
        tile.x, tile.y = params.x * map.tilewidth + properties.width / 2, (params.y + 1) * map.tileheight - properties.height / 2
    end
    if params.tint then
        tile:setFillColor(unpack(params.tint))
    end
    tile.flip = flip

    if flip.xy then
        if flip.x == flip.y then
            print('tiled: unsupported rotation x,y:', params.x, params.y, flip.x, flip.y)
        end
        if flip.x then
            tile.rotation = 90
        elseif flip.y then
            tile.rotation = -90
        end
    else
        if flip.x then
            tile.xScale = -1
        end
        if flip.y then
            tile.yScale = -1
        end
    end
    return tile
end

-- Objects are rectangles and other polygons from Tiled
local function newObject(self, params)
    if params.shape == 'rectangle' then
        local rect = display.newRect(params.g, params.x, params.y, params.width, params.height)
        rect.anchorX, rect.anchorY = 0, 0
        rect.isVisible = false
        physics.addBody(rect, 'static', {density = 1, friction = 0.5, bounce = 0})
    elseif params.shape == 'polygon' then
        local vertices = {}
        for i = 1, #params.polygon do
            table.insert(vertices, params.polygon[i].x)
            table.insert(vertices, params.polygon[i].y)
        end
        local polygon = display.newPolygon(params.g, params.x, params.y, vertices)
        polygon.anchorX, polygon.anchorY = 0, 1
        polygon.isVisible = false
        physics.addBody(polygon, 'static', {density = 1, friction = 0.5, bounce = 0})
    end
end

-- Iterate each Tiled layer and create all tiles and objects
local function draw(self)
    local map = self.map
    local w, h = map.width, map.height
    for i = 1, #map.layers do
        local l = map.layers[i]
        if l.type == 'tilelayer' then
            local groupLayer = display.newGroup()
            self.group:insert(groupLayer)
            table.insert(self.layers, groupLayer)
            if l.properties.ratio then
                groupLayer.ratio = tonumber(l.properties.ratio)
            end
            if l.properties.speed then
                groupLayer.speed = tonumber(l.properties.speed)
                groupLayer.xOffset = 0
            end
            if l.properties.yFactor then
                groupLayer.yFactor = tonumber(l.properties.yFactor)
            end
            local tint
            if l.properties.tintR and l.properties.tintG and l.properties.tintB then
                tint = {tonumber(l.properties.tintR), tonumber(l.properties.tintG), tonumber(l.properties.tintB)}
            end
            local d = l.data
            local gid
            for y = 0, h - 1 do
                for x = 0, w - 1 do
                    gid = d[x + y * w + 1]
                    if gid > 0 then
                        self:newTile{
                            gid = gid,
                            g = groupLayer,
                            x = x, y = y,
                            tint = tint
                        }
                    end
                end
            end
        elseif l.type == 'objectgroup' then
            for j = 1, #l.objects do
                local o = l.objects[j]
                self:newObject{g = self.physicsGroup,
                    shape = o.shape,
                    x = o.x, y = o.y,
                    width = o.width, height = o.height,
                    polygon = o.polygon
                }
            end
        end
    end
end

local function moveCamera(self, x, y)
    self.camera.x = clamp(x, self.camera.low.x, self.camera.high.x)
    self.camera.y = clamp(y, self.camera.low.y, self.camera.high.y)
end

local function moveCameraSmoothly(self, params)
    self.smoothMovementTransition = transition.to(self.camera, {
        x = clamp(params.x, self.camera.low.x, self.camera.high.x),
        y = clamp(params.y, self.camera.low.y, self.camera.high.y),
        time = params.time or 1000,
        delay = params.delay or 0,
        transition = easing.inOutExpo
    })
end

local function snapCameraTo(self, object)
    self.camera.snappedObject = object
    if self.smoothMovementTransition then
        transition.cancel(self.smoothMovementTransition)
        self.smoothMovementTransition = nil
    end
end

local function eachFrame(self)
    -- Modify camera position
    local _W, _H, _CX, _CY = relayout._W, relayout._H, relayout._CX, relayout._CY
    local step = 30
    local damping = 0.98
    if self.camera.xIncrement ~= 0 or self.camera.yIncrement ~= 0 then
        self.camera.xIncrement = self.camera.xIncrement * damping
        if math.abs(self.camera.xIncrement) < 0.02 then
            self.camera.xIncrement = 0
        end
        self.camera.yIncrement = self.camera.yIncrement * damping
        if math.abs(self.camera.yIncrement) < 0.02 then
            self.camera.yIncrement = 0
        end
        self:moveCamera(self.camera.x + self.camera.xIncrement * step, self.camera.y + self.camera.yIncrement * step)
    elseif self.camera.snappedObject then
        if self.camera.snappedObject.x then
            local w, h = _W * 0.33 / 2, _H * 0.33 / 2 -- Object tracking window
            local oX, oY = self.camera.snappedObject.x, self.camera.snappedObject.y
            local x, y = self.camera.x + _CX, self.camera.y + _CY
            x = clamp(x, oX - w, oX + w)
            y = clamp(y, oY - h, oY + h)
            self:moveCamera(x - _CX, y - _CY)
        else
            self.camera.snappedObject = nil
        end
    end

    -- Adjust layers positions according to the camera
    self.group.x, self.group.y = -self.camera.x - _CX, -self.camera.y - _CY
    self.physicsGroup.x, self.physicsGroup.y = -self.camera.x, -self.camera.y
    for i = 1, #self.layers do
        local l = self.layers[i]
        if l.ratio then
            l.x = self.camera.x - self.camera.x * l.ratio
            if l.speed then
                for j = 1, l.numChildren do
                    local object = l[j]
                    local speed = l.speed
                    if l.yFactor then
                        speed = speed / (l.yFactor * object.y / self.map.tileheight)
                    end
                    object.x = object.x + speed
                    if object.x > self.map.width * self.map.tilewidth + object.width then
                        object.x = object.x - self.map.width * self.map.tilewidth - 2 * object.width
                    elseif object.x < -object.width then
                        object.x = object.x + self.map.width * self.map.tilewidth + object.width
                    end
                end
            end
        end
    end

    self.snapshot:invalidate()
end

local function mapXYToPixels(self, x, y)
	return x * self.map.tilewidth, y * self.map.tileheight
end

local _M = {}

function _M.newTiledMap(params)
    local tiledMap = {
        load = load,
        prepareTilesets = prepareTilesets,
        getSpriteSheetByGid = getSpriteSheetByGid,
        newTile = newTile,
        newObject = newObject,
        draw = draw,
        moveCamera = moveCamera,
        moveCameraSmoothly = moveCameraSmoothly,
        snapCameraTo = snapCameraTo,
        eachFrame = eachFrame,
        mapXYToPixels = mapXYToPixels
    }
    tiledMap:load(params)
    return tiledMap
end

return _M
