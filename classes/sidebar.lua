-- Sidebar
-- This is a narrow vertical bar, that appears on the left side of the screen and provides the player five buttons:
-- resume, restart, menu, music and sounds.

local composer = require('composer')
local widget = require('widget')
local databox = require('libs.databox')
local sounds = require('libs.sounds')

local _M = {}

local _W, _H = display.actualContentWidth, display.actualContentHeight
local _CX, _CY = display.contentCenterX, display.contentCenterY

local newShade = require('classes.shade').newShade

function _M.newSidebar(params)
	local sidebar = display.newGroup()
	params.g:insert(sidebar)

	local background = display.newImageRect(sidebar, 'images/sidebar.png', 160, 640)
	sidebar.x, sidebar.y = -background.width, _CY

	local spacing = background.height / 6 + 12
	local start = -background.height / 2 + spacing / 2 + 24

	local resumeButton = widget.newButton({
		defaultFile = 'images/buttons/resume.png',
		overFile = 'images/buttons/resume-over.png',
		width = 96, height = 105,
		x = 0, y = start,
		onRelease = function()
			sounds.play('tap')
			sidebar:hide()
		end
	})
	sidebar:insert(resumeButton)

	if params.levelId then
		local restartButton = widget.newButton({
			defaultFile = 'images/buttons/restart.png',
			overFile = 'images/buttons/restart-over.png',
			width = 96, height = 105,
			x = 0, y = start + spacing,
			onRelease = function()
				sounds.play('tap')
				composer.gotoScene('scenes.reload_game', {params = params.levelId})
			end
		})
		sidebar:insert(restartButton)

		local menuButton = widget.newButton({
			defaultFile = 'images/buttons/menu.png',
			overFile = 'images/buttons/menu-over.png',
			width = 96, height = 105,
			x = 0, y = start + spacing * 2,
			onRelease = function()
				sounds.play('tap')
				composer.gotoScene('scenes.menu', {time = 500, effect = 'slideRight'})
			end
		})
		sidebar:insert(menuButton)
	end

	local soundsButtons = {}
	local musicButtons = {}

	-- When changing music on sounds, we need to show/hide corresponding buttons and save the value into the databox
	local function updateDataboxAndVisibility()
		databox.isSoundOn = sounds.isSoundOn
		databox.isMusicOn = sounds.isMusicOn
		soundsButtons.on.isVisible = false
		soundsButtons.off.isVisible = false
		musicButtons.on.isVisible = false
		musicButtons.off.isVisible = false
		if databox.isSoundOn then
			soundsButtons.on.isVisible = true
		else
			soundsButtons.off.isVisible = true
		end
		if databox.isMusicOn then
			musicButtons.on.isVisible = true
		else
			musicButtons.off.isVisible = true
		end
	end

	musicButtons.on = widget.newButton({
		defaultFile = 'images/buttons/music_on.png',
		overFile = 'images/buttons/music_on-over.png',
		width = 96, height = 105,
		x = 0, y = start + spacing * 3,
		onRelease = function()
			sounds.play('tap')
			sounds.isMusicOn = false
			updateDataboxAndVisibility()
			sounds.stop()
		end
	})
	sidebar:insert(musicButtons.on)

	musicButtons.off = widget.newButton({
		defaultFile = 'images/buttons/music_off.png',
		overFile = 'images/buttons/music_off-over.png',
		width = 96, height = 105,
		x = 0, y = musicButtons.on.y,
		onRelease = function()
			sounds.play('tap')
			sounds.isMusicOn = true
			updateDataboxAndVisibility()
			if params.levelId then
				sounds.playStream('game_music')
			else
				sounds.playStream('menu_music')
			end
		end
	})
	sidebar:insert(musicButtons.off)

	soundsButtons.on = widget.newButton({
		defaultFile = 'images/buttons/sounds_on.png',
		overFile = 'images/buttons/sounds_on-over.png',
		width = 96, height = 105,
		x = 0, y = start + spacing * 4,
		onRelease = function()
			sounds.play('tap')
			sounds.isSoundOn = false
			updateDataboxAndVisibility()
		end
	})
	sidebar:insert(soundsButtons.on)

	soundsButtons.off = widget.newButton({
		defaultFile = 'images/buttons/sounds_off.png',
		overFile = 'images/buttons/sounds_off-over.png',
		width = 96, height = 105,
		x = 0, y = soundsButtons.on.y,
		onRelease = function()
			sounds.play('tap')
			sounds.isSoundOn = true
			updateDataboxAndVisibility()
		end
	})
	sidebar:insert(soundsButtons.off)

	updateDataboxAndVisibility()

	function sidebar:show()
		self.shade = newShade(params.g)
		self:toFront()
		transition.to(self, {time = 250, x = background.width / 2, transition = easing.outExpo})
	end

	function sidebar:hide()
		self.shade:hide()
		transition.to(self, {time = 250, x = -background.width, transition = easing.outExpo, onComplete = params.onHide})
	end

	return sidebar
end

return _M
