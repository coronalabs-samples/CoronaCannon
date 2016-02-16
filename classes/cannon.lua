-- Cannon
-- It consists of a tower and actual cannon. Cannon can rotate and shoot the cannon balls

local eachframe = require('libs.eachframe')
local relayout = require('libs.relayout')
local sounds = require('libs.sounds')

local _M = {}

local newBall = require('classes.ball').newBall
local newPuff = require('classes.puff').newPuff

function _M.newCannon(params)
	local map = params.map
	local level = params.level
	-- Tower and cannon images are aligned to the level's grid, hence the mapX and mapY
	local tower = display.newImageRect(map.group, 'images/tower.png', 192, 256)
	tower.anchorY = 1
	tower.x, tower.y = map:mapXYToPixels(level.cannon.mapX + 0.5, level.cannon.mapY + 1)
	map.snapshot:invalidate()

	local cannon = display.newImageRect(map.physicsGroup, 'images/cannon.png', 128, 64)
	cannon.anchorX = 0.25
	cannon.x, cannon.y = map:mapXYToPixels(level.cannon.mapX + 0.5, level.cannon.mapY - 3)

	-- Cannon force is set by a player by moving the finger away from the cannon
	cannon.force = 0
	cannon.forceRadius = 0
	-- Increments are for gamepad control
	cannon.radiusIncrement = 0
	cannon.rotationIncrement = 0
	-- Minimum and maximum radius of the force circle indicator
	local radiusMin, radiusMax = 64, 200

	-- Indicates force value
	local forceArea = display.newCircle(map.physicsGroup, cannon.x, cannon.y, radiusMax)
	forceArea.strokeWidth = 4
	forceArea:setFillColor(1, 0.5, 0.2, 0.2)
	forceArea:setStrokeColor(1, 0.5, 0.2)
	forceArea.isVisible = false

	-- touchArea is larger than cannon image so player does not need to be very accurate with the fingers
	local touchArea = display.newCircle(map.physicsGroup, cannon.x, cannon.y, 128)
	touchArea.isVisible = false
	touchArea.isHitTestable = true
	touchArea:addEventListener('touch', cannon)

	local trajectoryPoints = {} -- White dots along the flying path of a ball
	local balls = {} -- Container for the ammo

	function cannon:getAmmoCount()
		return #balls + (self.ball and 1 or 0)
	end

	-- Create and stack all available cannon balls near the tower
	function cannon:prepareAmmo()
		local mapX, mapY = level.cannon.mapX - 1, level.cannon.mapY
		for i = #level.ammo, 1, -1 do
			local x, y = map:mapXYToPixels(mapX + 0.5, mapY + 0.5)
			local ball = newBall({g = self.parent, type = level.ammo[i], x = x, y = y})
			table.insert(balls, ball)
			mapX = mapX - 1
			if (#level.ammo - i + 1) % 3 == 0 then
				mapX, mapY = level.cannon.mapX - 1, mapY - 1
			end
		end
	end

	-- Move next available cannon ball into the cannon
	function cannon:load()
		if #balls > 0 then
			self.ball = table.remove(balls, #balls)
			transition.to(self.ball, {time = 500, x = self.x, y = self.y, transition = easing.outExpo})
		end
	end

	-- Launch loaded cannon ball
	function cannon:fire()
		if self.ball and not self.ball.isLaunched then
			self.ball:launch(self.rotation, self.force)
			self:removeTrajectoryPoints()
			self.launchTime = system.getTimer() -- This time value is needed for the trajectory points
			self.lastTrajectoryPointTime = self.launchTime
			newPuff({g = self.parent, x = self.x, y = self.y, isExplosion = true}) -- Display an explosion visual effect
			map:snapCameraTo(self.ball)
			sounds.play('cannon')
		end
	end

	function cannon:setForce(radius, rotation)
		self.rotation = rotation % 360
		if radius > radiusMin then
			if radius > radiusMax then
				radius = radiusMax
			end
			self.force = radius
		else
			self.force = 0
		end
		-- Only show the force indication if there is a loaded cannon ball
		if self.ball and not self.ball.isLaunched then
			forceArea.isVisible = true
			forceArea.xScale = 2 * radius / forceArea.width
			forceArea.yScale = forceArea.xScale
		end
		return math.min(radius, radiusMax), self.rotation
	end

	function cannon:engageForce()
		forceArea.isVisible = false
		self.forceRadius = 0
		if self.force > 0 then
			self:fire()
		end
	end

	function cannon:touch(event)
		if event.phase == 'began' then
			display.getCurrentStage():setFocus(self, event.id)
			self.isFocused = true
			sounds.play('cannon_touch')
		elseif self.isFocused then
			if event.phase == 'moved' then
				local x, y = self.parent:contentToLocal(event.x, event.y)
				x, y = x - self.x, y - self.y
				local rotation = math.atan2(y, x) * 180 / math.pi + 180
				local radius = math.sqrt(x ^ 2 + y ^ 2)
				self:setForce(radius, rotation)
			else
				display.getCurrentStage():setFocus(self, nil)
				self.isFocused = false
				self:engageForce()
			end
		end
		return true
	end
	cannon:addEventListener('touch')

	-- Add white trajectory points each time interval
	function cannon:addTrajectoryPoint()
		local now = system.getTimer()
		-- Draw them for no longer than the first value and each second value millisecods
		if now - self.launchTime < 1000 and now - self.lastTrajectoryPointTime > 85 then
			self.lastTrajectoryPointTime = now
			local point = display.newCircle(self.parent, self.ball.x, self.ball.y, 2)
			table.insert(trajectoryPoints, point)
		end
	end

	-- Clean the trajectory before drawing another one
	function cannon:removeTrajectoryPoints()
		for i = #trajectoryPoints, 1, -1 do
			table.remove(trajectoryPoints, i):removeSelf()
		end
	end

	-- echFrame() is like enterFrame(), but managed by a library
	-- Track a launched ball until it stops and load another one
	function cannon:eachFrame()
		local step = 2
	    local damping = 0.99
		if self.ball then
			if self.ball.isLaunched then
				local vx, vy = self.ball:getLinearVelocity()
				if vx ^ 2 + vy ^ 2 < 4 or
					self.ball.x < 0 or
						self.ball.x > map.map.tilewidth * map.map.width or
							self.ball.y > map.map.tilewidth * map.map.height then
					self.ball:destroy()
					self.ball = nil
					self:load()
					map:moveCameraSmoothly({x = self.x - relayout._CX, y = self.y - relayout._CY, time = 1000, delay = 500})
				elseif not self.isPaused then
					self:addTrajectoryPoint()
				end
			elseif self.radiusIncrement ~= 0 or self.rotationIncrement ~= 0 then
		        self.radiusIncrement = self.radiusIncrement * damping
		        if math.abs(self.radiusIncrement) < 0.02 then
		            self.radiusIncrement = 0
		        end
				self.rotationIncrement = self.rotationIncrement * damping
		        if math.abs(self.rotationIncrement) < 0.02 then
		            self.rotationIncrement = 0
		        end
				self.forceRadius = self.forceRadius + self.radiusIncrement * step
				self.forceRadius = self:setForce(math.max(math.abs(self.forceRadius), 1), self.rotation + self.rotationIncrement * step)
		    end
		end
	end
	eachframe.add(cannon)

	-- finalize() is called by Corona when display object is destroyed
	function cannon:finalize()
		eachframe.remove(self)
	end
	cannon:addEventListener('finalize')

	cannon:prepareAmmo()
	cannon:load()

	return cannon
end

return _M
