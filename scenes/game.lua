-- Game Scene
-- All actual gameplay happens here.
-- This scene loads and shows many various little pieces from the rest of the project and combines them together.

local composer = require('composer') -- Scene management
local physics = require('physics') -- Box2D physics
local widget = require('widget') -- Buttons
local controller = require('libs.controller') -- Gamepad support
local databox = require('libs.databox') -- Persistant storage, track level completion and settings
local sounds = require('libs.sounds') -- Music and sounds manager
local tiled = require('libs.tiled') -- Tiled map loader

physics.start()
physics.setGravity(0, 20) -- Default gravity is too boring

-- Short names for these crucial, but long variables
local _W, _H = display.actualContentWidth, display.actualContentHeight
local _CX, _CY = display.contentCenterX, display.contentCenterY

local scene = composer.newScene()

-- LEVEL EDITOR
-- Uncomment to enable level editing features
--require('classes.level_editor').enableLevelEditor(scene)

local newCannon = require('classes.cannon').newCannon -- The ultimate weapon
local newBug = require('classes.bug').newBug -- Enemies to kill, debug powers
local newBlock = require('classes.block').newBlock -- Buildig blocks for the levels
local newSidebar = require('classes.sidebar').newSidebar -- Settings and pause sidebar
local newEndLevelPopup = require('classes.end_level_popup').newEndLevelPopup -- Win/Lose dialog windows

function scene:create(event)
	local group = self.view
	self.levelId = event.params
	self.level = require('levels.' .. self.levelId)
	local background = display.newRect(group, _CX, _CY, _W,  _H)
	background.fill = {
	    type = 'gradient',
	    color1 = {0.2, 0.45, 0.8},
	    color2 = {0.7, 0.8, 1}
	}

	-- The central element - Tiled map
	self.map = tiled.newTiledMap({g = group, filename = 'maps.' .. self.level.map})
	self.map.camera.low.y = -self.map.map.height * self.map.map.tileheight -- Make the camera see above and just to the bottom of the level
	self.map.camera.high.y = self.map.camera.high.y
	self.map:moveCamera(self.map.camera.high.x, 0) -- Move camera to the end of the level
	self.map:draw()

	-- Bugs, blocks and balls are inserted into self.map.physicsGroup
	self.bugs = {}
	for i = 1, #self.level.bugs do
		local b = self.level.bugs[i]
		table.insert(self.bugs, newBug({g = self.map.physicsGroup, x = b.x, y = b.y}))
	end

	self.blocks = {}
	for i = 1, #self.level.blocks do
		local b = self.level.blocks[i]
		table.insert(self.blocks, newBlock({
			g = self.map.physicsGroup,
			x = b.x, y = b.y,
			rotation = b.rotation,
			material = b.material,
			name = b.name}))
	end

	-- Handle touch events, wait a little for camera to slide
	self:createTouchRect({delay = 2000})
	self.map.physicsGroup:toFront() -- Put cannon in front of the touchRect
	self.cannon = newCannon({map = self.map, level = self.level})
	self.map:moveCameraSmoothly({x = self.cannon.x - _CX, y = 0, time = 1000, delay = 1000}) -- Slide it back to the cannon

	-- Preload End Level Popup and Sidebar
	self.endLevelPopup = newEndLevelPopup({g = group, levelId = self.levelId})
	local sidebar = newSidebar({g = group, levelId = self.levelId, onHide = function()
		self:setIsPaused(false)
		controller.setVisualButtons()
	end})

	local levelLabel = display.newText({
		parent = group,
		text = 'Level: ' .. self.levelId,
		x = _W - 16, y = 16,
		font = native.systemFontBold,
		fontSize = 32
	})
	levelLabel.anchorX, levelLabel.anchorY = 1, 0

	local pauseButton = widget.newButton({
		defaultFile = 'images/buttons/pause.png',
		overFile = 'images/buttons/pause-over.png',
		width = 96, height = 105,
		x = 16, y = 16,
		onRelease = function()
			sounds.play('tap')
			sidebar:show()
			self:setIsPaused(true)
		end
	})
	pauseButton.anchorX, pauseButton.anchorY = 0, 0
	group:insert(pauseButton)

	sidebar:toFront()

	controller.setVisualButtons()
	-- Map movement on gamepad left stick
	controller.onMotion = function(name, value)
		if not self.isPaused then
			self.map:snapCameraTo()
			if name == 'x' then
				self.map.camera.xIncrement = value
			elseif name == 'y' then
				self.map.camera.yIncrement = value
			end
		end
	end
	-- Cannon control on gamepad right stick
	controller.onRotation = function(name, value)
		if not self.isPaused then
			if self.cannon.ball and not self.cannon.ball.isLaunched then
				self.map:snapCameraTo(self.cannon)
			end
			if name == 'x' then
				self.cannon.radiusIncrement = value
			elseif name == 'y' then
				self.cannon.rotationIncrement = value
			end
		end
	end
	-- Other gamepad and keyboard buttons
	controller.onKey = function(keyName, keyType)
		if not self.isPaused then
			if keyType == 'action' then
				cannonControllerRadius = 0
				self.cannon:engageForce()
			elseif keyType == 'pause' then
				pauseButton._view._onRelease()
			elseif keyType == 'switch' then
				-- switch for tvOS
				controller.onMotion, controller.onRotation = controller.onRotation, controller.onMotion
			end
		end
	end

	-- Only check once in a while for level end
	self.endLevelCheckTimer = timer.performWithDelay(2000, function()
		self:endLevelCheck()
	end, 0)

	sounds.playStream('game_music')
end

-- Count bugs and see if all are debugged
function scene:getBugsCount()
	for i = #self.bugs, 1, -1 do
		if not self.bugs[i].isAlive then
			table.remove(self.bugs, i)
		end
	end
	return #self.bugs
end

function scene:setIsPaused(isPaused)
	self.isPaused = isPaused
	self.cannon.isPaused = self.isPaused -- Pause adding trajectory points
	if self.isPaused then
		physics.pause()
	else
		physics.start()
	end
end

-- Check if the player won or lost
function scene:endLevelCheck()
	if not self.isPaused then
		if self:getBugsCount() == 0 then
			sounds.play('win')
			self:setIsPaused(true)
			self.endLevelPopup:show({isWin = true})
			timer.cancel(self.endLevelCheckTimer)
			self.endLevelCheckTimer = nil
			databox['level' .. self.levelId] = true -- Save level completion
		elseif self.cannon:getAmmoCount() == 0 then
			sounds.play('lose')
			self:setIsPaused(true)
			self.endLevelPopup:show({isWin = false})
			timer.cancel(self.endLevelCheckTimer)
			self.endLevelCheckTimer = nil
		end
	end
end

-- Touch to pan the map
function scene:createTouchRect(params)
	local group = self.view
	local map = self.map
	local delay = params.delay or 1
	local touchRect = display.newRect(group, _CX, _CY, _W, _H)
	touchRect.isVisible = false

	local super = self
	function touchRect:touch(event)
		if event.phase == 'began' then
			display.getCurrentStage():setFocus(self, event.id)
			self.isFocused = true
			self.xStart, self.yStart = map.camera.x, map.camera.y
		elseif self.isFocused then
			if event.phase == 'moved' then
				map:snapCameraTo()
				map:moveCamera(self.xStart - event.x + event.xStart, self.yStart - event.y + event.yStart)
			else
				display.getCurrentStage():setFocus(self, nil)
				self.isFocused = false
			end
		end
		return true
	end
	touchRect:addEventListener('touch')

	timer.performWithDelay(delay, function()
		touchRect.isHitTestable = true
	end)
end

-- Clean up
function scene:destroy()
	controller.onMotion = nil
	controller.onRotation = nil
	controller.onKey = nil
	if self.endLevelCheckTimer then
		timer.cancel(self.endLevelCheckTimer)
	end
	physics.stop()
end

scene:addEventListener('create')
scene:addEventListener('destroy')

return scene
