-- Cannon ball
-- There are two types of canonn balls: normal and bomb

local physics = require('physics')
local sounds = require('libs.sounds')

local _M = {}

local newPuff = require('classes.puff').newPuff

function _M.newBall(params)
	local ball = display.newImageRect(params.g, 'images/ammo/' .. params.type .. '.png', 48, 48)
	ball.x, ball.y = params.x, params.y
	-- While the ball rests near the cannon, it's static
	physics.addBody(ball, 'static', {density = 2, friction = 0.5, bounce = 0.5, radius = ball.width / 2})
	ball.isBullet = true -- More accurate collision detection
	ball.angularDamping = 3 -- Prevent the ball from rolling for too long
	ball.type = params.type

	function ball:launch(dir, force)
		dir = math.rad(dir) -- We need the direction angle in radians for calculations below
		ball.bodyType = 'dynamic' -- Change to dynamic so it can move
		ball:applyLinearImpulse(force * math.cos(dir), force * math.sin(dir), ball.x, ball.y)
		ball.isLaunched = true
	end

	function ball:explode()
		sounds.play('explosion')
		local radius = 192 -- Explosion radius, all objects touching this area will be affected by the explosion
		local area = display.newCircle(params.g, self.x, self.y, radius)
		area.isVisible = false
		physics.addBody(area, 'dynamic', {isSensor = true, radius = radius})

		-- The trick is to create a large circle, grab all collisions and destroy it
		local affected = {} -- Keep affected bodies here
		function area:collision(event)
			if event.phase == 'began' then
				if not affected[event.other] then
					affected[event.other] = true
					local x, y = event.other.x - self.x, event.other.y - self.y
					local dir = math.atan2(y, x) * 180 / math.pi
					local force = (radius - math.sqrt(x ^ 2 + y ^ 2)) * 4 -- Reduce the force with the distance from the explosion
					-- If an object touches the explosion, the force will be at least this big
					if force < 20 then
						force = 20
					end
					event.other:applyLinearImpulse(force * math.cos(dir), force * math.sin(dir), event.other.x, event.other.y)
				end
			end
		end
		area:addEventListener('collision')
		timer.performWithDelay(1, function()
			area:removeSelf()
		end)

		self:removeSelf()
	end

	function ball:destroy()
		-- The ball can either be destroyed as a normal one or as bomb with an explosions
		newPuff({g = params.g, x = self.x, y = self.y, isExplosion = self.type == 'bomb'})
		if self.type == 'bomb' then
			self:explode()
		else
			sounds.play('ball_destroy')
			self:removeSelf()
		end
	end

	return ball
end

return _M
