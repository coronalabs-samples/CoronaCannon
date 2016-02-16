-- Game Scene
-- All actual gameplay happens here.
-- This scene loads and shows many various little pieces from the rest of the project and combines them together.

local composer = require('composer') -- Scene management
local physics = require('physics') -- Box2D physics
local widget = require('widget') -- Buttons
local controller = require('libs.controller') -- Gamepad support
local databox = require('libs.databox') -- Persistant storage, track level completion and settings
local eachframe = require('libs.eachframe') -- enterFrame manager
local relayout = require('libs.relayout') -- Repositions elements on screen on window resize
local sounds = require('libs.sounds') -- Music and sounds manager
local tiled = require('libs.tiled') -- Tiled map loader

physics.start()
physics.setGravity(0, 20) -- Default gravity is too boring

local scene = composer.newScene()

-- LEVEL EDITOR
-- Uncomment to enable level editing features
--require('classes.level_editor').enableLevelEditor(scene)

local newCannon = require('classes.cannon').newCannon -- The ultimate weapon
local newBug = require('classes.bug').newBug -- Enemies to kill, debug powers
local newBlock = require('classes.block').newBlock -- Building blocks for the levels
local newSidebar = require('classes.sidebar').newSidebar -- Settings and pause sidebar
local newEndLevelPopup = require('classes.end_level_popup').newEndLevelPopup -- Win/Lose dialog windows

function scene:create(event)
	local _W, _H, _CX, _CY = relayout._W, relayout._H, relayout._CX, relayout._CY

	local group = self.view
	self.levelId = event.params
	self.level = require('levels.' .. self.levelId)
	local background = display.newRect(group, _CX, _CY, _W,  _H)
	background.fill = {
	    type = 'gradient',
	    color1 = {0.2, 0.45, 0.8},
	    color2 = {0.7, 0.8, 1}
	}
	relayout.add(background)

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
			name = b.name
		}))
	end

	-- Handle touch events, wait a little for camera to slide
	self:createTouchRect({delay = 2000})
	self.map.physicsGroup:toFront() -- Put cannon in front of the touchRect
	self.cannon = newCannon({map = self.map, level = self.level})
	self.map:moveCameraSmoothly({x = self.cannon.x - _CX, y = 0, time = 1000, delay = 1000}) -- Slide it back to the cannon

	-- Preload End Level Popup and Sidebar
	self.endLevelPopup = newEndLevelPopup({g = group, levelId = self.levelId})
	self.sidebar = newSidebar({g = group, levelId = self.levelId, onHide = function()
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
	relayout.add(levelLabel)

	local pauseButton = widget.newButton({
		defaultFile = 'images/buttons/pause.png',
		overFile = 'images/buttons/pause-over.png',
		width = 96, height = 105,
		x = 16, y = 16,
		onRelease = function()
			sounds.play('tap')
			self.sidebar:show()
			self:setIsPaused(true)
		end
	})
	pauseButton.anchorX, pauseButton.anchorY = 0, 0
	group:insert(pauseButton)
	relayout.add(pauseButton)

	self.sidebar:toFront()

	controller.setVisualButtons() -- No on-screen buttons, that can be navigated to with a controller

	local function switchMotionAndRotation()
		-- Switch for tvOS, because it has only one touchpad (axis)
		controller.onMotion, controller.onRotation = controller.onRotation, controller.onMotion
	end

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
			if math.abs(value) >= 0.08 or math.abs(value) < 0.02 then
				if name == 'x' then
					self.cannon.radiusIncrement = -value -- Invert x axis to resemble a slingshot
				elseif name == 'y' then
					self.cannon.rotationIncrement = value
				end
			end
		end
	end
	-- Other gamepad and keyboard buttons
	controller.onKey = function(keyName, keyType)
		if not self.isPaused then
			if keyType == 'action' then
				if keyName == 'buttonA' and system.getInfo('platformName') == 'tvOS' then
					switchMotionAndRotation()
				else
					self.cannon:engageForce()
				end
			elseif keyType == 'pause' then
				pauseButton._view._onRelease()
			end
		end
	end

	-- On tvOS default to cannon control with the remote
	if system.getInfo('platformName') == 'tvOS' then
		switchMotionAndRotation()
	end
end

function scene:show(event)
	if event.phase == 'did' then
		eachframe.add(self) -- Each frame self:eachFrame() is called

		-- Only check once in a while for level end
		self.endLevelCheckTimer = timer.performWithDelay(2000, function()
			self:endLevelCheck()
		end, 0)

		-- Show help image once
		if not databox.isHelpShown then
			timer.performWithDelay(2500, function()
				self.sidebar:show()
				self:setIsPaused(true)
			end)
		end

		sounds.playStream('game_music')
	end
end

-- Check for bugs and blocks being dead or outside the borders
function scene:eachFrame()
	local tables = {self.bugs, self.blocks}
	for i = 1, #tables do
		local t = tables[i]
		for j = #t, 1, -1 do
			local b = t[j]
			if b.isAlive then
				if b.x < 0 or b.x > self.map.map.tilewidth * self.map.map.width or b.y > self.map.map.tilewidth * self.map.map.height then
					b:destroy()
				end
			else
				table.remove(t, j)
			end
		end
	end
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
		if #self.bugs == 0 then
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
	local _W, _H, _CX, _CY = relayout._W, relayout._H, relayout._CX, relayout._CY

	local group = self.view
	local map = self.map
	local delay = params.delay or 1
	local touchRect = display.newRect(group, _CX, _CY, _W, _H)
	touchRect.isVisible = false
	relayout.add(touchRect)

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

-- Device's back button action
function scene:gotoPreviousScene()
	native.showAlert('Corona Cannon', 'Are you sure you want to exit this level?', {'Yes', 'Cancel'}, function(event)
		if event.action == 'clicked' and event.index == 1 then
			composer.gotoScene('scenes.menu', {time = 500, effect = 'slideRight'})
		end
	end)
end

-- Clean up
function scene:hide(event)
	if event.phase == 'will' then
		eachframe.remove(self)
		controller.onMotion = nil
		controller.onRotation = nil
		controller.onKey = nil
		if self.endLevelCheckTimer then
			timer.cancel(self.endLevelCheckTimer)
		end
	elseif event.phase == 'did' then
		physics.stop()
	end
end

scene:addEventListener('create')
scene:addEventListener('show')
scene:addEventListener('hide')

return scene
