-- End Level Popup
-- A simple popup window with three buttons - menu, restart and next.

local composer = require('composer')
local widget = require('widget')
local sounds = require('libs.sounds')

local _M = {}

local _W, _H = display.actualContentWidth, display.actualContentHeight
local _CX, _CY = display.contentCenterX, display.contentCenterY

local newShade = require('classes.shade').newShade

function _M.newEndLevelPopup(params)
	local popup = display.newGroup()
	params.g:insert(popup)

	local background = display.newImageRect(popup, 'images/end_level.png', 480, 480)
	popup.x, popup.y = _CX, -background.height

	local label = display.newText({
		parent = popup,
		text = '',
		x = 0, y = -80,
		font = native.systemFontBold,
		fontSize = 64
	})

	local menuButton = widget.newButton({
		defaultFile = 'images/buttons/menu.png',
		overFile = 'images/buttons/menu-over.png',
		width = 96, height = 105,
		x = -120, y = 80,
		onRelease = function()
			sounds.play('tap')
			composer.gotoScene('scenes.menu', {time = 500, effect = 'slideRight'})
		end
	})
	popup:insert(menuButton)

	local restartButton = widget.newButton({
		defaultFile = 'images/buttons/restart.png',
		overFile = 'images/buttons/restart-over.png',
		width = 96, height = 105,
		x = 0, y = menuButton.y,
		onRelease = function()
			sounds.play('tap')
			composer.gotoScene('scenes.reload_game', {params = params.levelId})
		end
	})
	popup:insert(restartButton)

	-- Don't display the next button if it was the last level
	if params.levelId < composer.getVariable('levelCount') then
		local nextButton = widget.newButton({
			defaultFile = 'images/buttons/resume.png',
			overFile = 'images/buttons/resume-over.png',
			width = 96, height = 105,
			x = -menuButton.x, y = menuButton.y,
			onRelease = function()
				sounds.play('tap')
				composer.gotoScene('scenes.reload_game', {params = params.levelId + 1})
			end
		})
		popup:insert(nextButton)
	end

	local superParams = params
	function popup:show(params)
		-- Shade dims the background and makes it impossible to touch
		self.shade = newShade(superParams.g)
		self:toFront()

		if params.isWin then
			label.text = 'YOU WON!'
		else
			label.text = 'YOU LOST!'
		end

		transition.to(self, {time = 250, y = _CY, transition = easing.outExpo})
	end

	return popup
end

return _M
