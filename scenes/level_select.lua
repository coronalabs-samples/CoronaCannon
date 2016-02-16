-- Level Selection Scene
-- Displays a button for each level. There is a space for extra buttons, add your own levels!

local composer = require('composer')
local widget = require('widget')
local controller = require('libs.controller')
local databox = require('libs.databox')
local relayout = require('libs.relayout')
local sounds = require('libs.sounds')

local scene = composer.newScene()

function scene:create()
	local _W, _H, _CX, _CY = relayout._W, relayout._H, relayout._CX, relayout._CY

	local group = self.view

	local background = display.newRect(group, _CX, _CY, _W, _H)
	background.fill = {
	    type = 'gradient',
	    color1 = {0.8, 0.45, 0.2},
	    color2 = {1, 0.8, 0.7}
	}
	relayout.add(background)

	local visualButtons = {}

	local buttonsGroup = display.newGroup()
	buttonsGroup.x, buttonsGroup.y = _CX, 0
	group:insert(buttonsGroup)
	relayout.add(buttonsGroup)

	local function onLevelButtonRelease(event)
		sounds.play('tap')
		composer.gotoScene('scenes.reload_game', {params = event.target.id})
	end

	-- Button positioning is grid based, x,y are grid points
	local x, y = -2, 0
	local spacing = 180
	for i = 1, composer.getVariable('levelCount') do
		local button = widget.newButton({
			id = i,
			label = i,
			labelColor = {default = {1}, over = {0.5}},
			font = native.systemFontBold,
			fontSize = 100,
			labelYOffset = -10,
			defaultFile = 'images/buttons/level.png',
			overFile = 'images/buttons/level-over.png',
			width = 160, height = 175,
			x = x * spacing, y = 32 + y * spacing + 87,
			onRelease = onLevelButtonRelease
		})
		buttonsGroup:insert(button)
		table.insert(visualButtons, button)

		-- Check if this level was completed
		if databox['level' .. i] then
			local check = display.newImageRect('images/check.png', 48, 48)
			check.anchorX, check.anchorY = 1, 1
			check.x, check.y = button.width - 3, button.height - 18
			button:insert(check) -- Insert after positioning, because if inserted before, button.width/height will be different
		end

		x = x + 1
		if x == 3 then
			x = -2
			y = y + 1
		end
	end
	controller.setVisualButtons(visualButtons)

	self.gotoPreviousScene = 'scenes.menu' -- Allow going back on back button press
end

scene:addEventListener('create')

return scene
