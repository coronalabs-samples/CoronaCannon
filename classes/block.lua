-- Block elements
-- Physics objects from which constructed all the levels

local physics = require('physics')
local sounds = require('libs.sounds')

local _M = {}

local newPuff = require('classes.puff').newPuff

local specs = {
	circle = {w = 35, h = 35},
	rectangle1 = {w = 35, h = 35},
	rectangle2 = {w = 70, h = 35},
	rectangle3 = {w = 35, h = 70},
	rectangle4 = {w = 110, h = 35},
	rectangle5 = {w = 35, h = 110},
	rectangle6 = {w = 70, h = 70},
	rectangle7 = {w = 110, h = 70},
	rectangle8 = {w = 70, h = 110}
}

function _M.newBlock(params)
	local block = display.newImageRect(params.g, 'images/blocks/' .. params.material .. '/' .. params.name .. '.png', specs[params.name].w, specs[params.name].h)
	block.x, block.y = params.x, params.y
	block.rotation = params.rotation
	-- This is an impact force threshold, the object will stay alive if force is below this value
	local forceThreshold = 75
	local bodyParams = {density = 2, friction = 0.5, bounce = 0.5}
	if params.name == 'circle' then
		bodyParams.radius = block.width / 2
	end
	-- Increase density and strength for stone blocks
	if params.material == 'stone' then
		bodyParams.density = 4
		forceThreshold = 150
	end
	physics.addBody(block, 'dynamic', bodyParams)
	block.angularDamping = 3 -- Prevent from rolling for too long
	block.isAlive = true

	function block:destroy()
		sounds.play('poof')
		self.isAlive = false
		newPuff({g = params.g, x = self.x, y = self.y})
		timer.performWithDelay(1, function()
			self:removeSelf()
		end)
	end

	function block:postCollision(event)
		if self.isAlive then
			-- Small impact detection just to play a sound
			if event.force > 20 then
				local vx, vy = event.other:getLinearVelocity()
				if vx + vy > 4 then
					sounds.play('impact')
				end
			end
			if event.force >= forceThreshold then
				self:destroy()
			end
		end
	end
	block:addEventListener('postCollision')

	return block
end

return _M
