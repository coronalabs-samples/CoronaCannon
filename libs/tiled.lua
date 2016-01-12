-- Tiled maps loading library

local physics = require('physics')
local bit = require('plugin.bit')

local _W, _H = display.actualContentWidth, display.actualContentHeight
local _CX, _CY = display.contentCenterX, display.contentCenterY

local FlippedHorizontallyFlag   = 0x80000000
local FlippedVerticallyFlag     = 0x40000000
local FlippedGiagonallyFlag     = 0x20000000
local ClearFlag                 = 0x1FFFFFFF

local function extractPath(p)
    local c
    for i = p:len(), 1, -1 do
        c = p:sub(i, i)
        if c == '/' then
            return p:sub(1, i - 1), p:sub(i + 1)
        end
    end
end

local function clamp(value, low, high)
    if value < low then value = low
    elseif high and value > high then value = high end
    return value
end

local function load(self, params)
    self.map = require(params.filename)
    package.loaded[params.filename] = nil
    self.specs = params.specs or {}

    self:prepareTilesets()
    self.collisionHandlers = params.collisionHandlers

    self.snapshot = display.newSnapshot(params.g, _W, _H)
    self.snapshot.x, self.snapshot.y = 0, 0
    self.group = self.snapshot.group
    self.snapshot.anchorX, self.snapshot.anchorY = 0, 0
    self.group.x, self.group.y = -self.snapshot.width / 2, -self.snapshot.height / 2

    self.physicsGroup = display.newGroup()
    params.g:insert(self.physicsGroup)
    self.physicsGroup.x, self.physicsGroup.y = self.snapshot.x, self.snapshot.y

    self.camera = {x = 0, y = 0, low = {x = 0, y = 0}, high = {x = self.map.tilewidth * self.map.width - _W, y = self.map.tilewidth * self.map.height - _H}}

    local color = self.map.backgroundcolor
    self.map.backgroundcolor = {color[1] / 255, color[2] / 255, color[3] / 255}
end

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
    else
        tile = display.newImageRect(params.g, properties.image, properties.width, properties.height)
    end
    tile.x, tile.y = (params.x + 0.5) * map.tilewidth, (params.y + 0.5) * map.tileheight
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

    if properties.material then
        local rect = display.newRect(tile.x, tile.y, tile.width, tile.height)
        rect.isVisible = false
        self.physicsGroup:insert(rect)

        rect.rotation = tile.rotation
        if tile.yScale == -1 then
            rect.rotation = rect.rotation + 180
        end

        local body = {}
        local shape = self.specs.shapes[properties.shape]
        for i = 1, #shape do
            local element = {shape = shape[i], density = 1, bounce = 0, friction = 0}
            table.insert(body, element)
        end
        physics.addBody(rect, 'static', unpack(body))
        if properties.material == 'none' then
            rect.isSensor = true
        end

        if properties.effect then
            rect.effect = properties.effect
            if self.collisionHandlers[properties.effect] then
                rect:addEventListener('collision', self.collisionHandlers[properties.effect])
            end
        end
    end
    return tile
end

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

local function draw(self)
    local map = self.map
    local w, h = map.width, map.height
    for i = 1, #map.layers do
        local l = map.layers[i]
        if l.type == 'tilelayer' then
            local d = l.data
            local gid
            for y = 0, h - 1 do
                for x = 0, w - 1 do
                    gid = d[x + y * w + 1]
                    if gid > 0 then
                        self:newTile{
                            gid = gid,
                            g = self.group,
                            x = x, y = y}
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
    self.snapshot:invalidate()
end

local function moveCamera(self, x, y)
    self.camera.x = clamp(x, self.camera.low.x, self.camera.high.x)
    self.camera.y = clamp(y, self.camera.low.y, self.camera.high.y)
    local toX, toY = -self.camera.x - _CX, -self.camera.y - _CY
    if self.group.x ~= toX or self.group.y ~= toY then
        self.group.x, self.group.y = toX, toY
        self.physicsGroup.x, self.physicsGroup.y = self.group.x + _CX, self.group.y + _CY
        self.snapshot:invalidate()
    end
end

local function moveCameraSmoothly(self, params)
    local mt = {}
    function mt.__index(t, k)
        if k == 'x' then
            return t._x
        elseif k == 'y' then
            return t._y
        end
    end
    function mt.__newindex(t, k, value)
        if k == 'x' then
            t._x = value
        elseif k == 'y' then
            t._y = value
        end
        if self.snapshot.invalidate then
            self:moveCamera(t._x, t._y)
        end
    end

    local t = {_x = self.camera.x, _y = self.camera.y}
    setmetatable(t, mt)
    transition.to(t, {x = params.x, y = params.y, time = params.time or 1000, delay = params.delay or 0, transition = easing.inOutExpo})
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
        mapXYToPixels = mapXYToPixels
    }
    tiledMap:load(params)
    return tiledMap
end

return _M
