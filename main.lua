-- Corona Cannon
-- A complete remake of Ghosts vs. Monsters sample game for Corona SDK.
-- Most of the graphics made by kenney.nl
-- Please use Corona daily build 2016.2818 or later.
-- Created by Sergey Lerg for Corona Labs.
-- License - MIT.

display.setStatusBar(display.HiddenStatusBar)
system.activate('multitouch')
if system.getInfo('build') >= '2015.2741' then -- Allow the game to be opened using an old Corona version
	display.setDefault('isAnchorClamped', false) -- Needed for scenes/reload_game.lua animation
end

local platform = system.getInfo('platformName')
if platform == 'tvOS' then
	system.setIdleTimer(false)
end

-- Hide navigation bar on Android
if platform == 'Android' then
	native.setProperty('androidSystemUiVisibility', 'immersiveSticky')
end

-- Exit and enter fullscreen mode
-- CMD+CTRL+F on OS X
-- F11 or ALT+ENTER on Windows
if platform == 'Mac OS X' or platform == 'Win' then
	Runtime:addEventListener('key', function(event)
		if event.phase == 'down' and (
				(platform == 'Mac OS X' and event.keyName == 'f' and event.isCommandDown and event.isCtrlDown) or
					(platform == 'Win' and (event.keyName == 'f11' or (event.keyName == 'enter' and event.isAltDown)))
			) then
			if native.getProperty('windowMode') == 'fullscreen' then
				native.setProperty('windowMode', 'normal')
			else
				native.setProperty('windowMode', 'fullscreen')
			end
		end
	end)
end

local composer = require('composer')
composer.recycleOnSceneChange = true -- Automatically remove scenes from memory
composer.setVariable('levelCount', 10) -- Set how many levels there are under levels/ directory

-- Add support for back button on Android and Window Phone
-- When it's pressed, check if current scene has a special field gotoPreviousScene
-- If it's a function - call it, if it's a string - go back to the specified scene
if platform == 'Android' or platform == 'WinPhone' then
	Runtime:addEventListener('key', function(event)
		if event.phase == 'down' and event.keyName == 'back' then
			local scene = composer.getScene(composer.getSceneName('current'))
            if scene then
				if type(scene.gotoPreviousScene) == 'function' then
                	scene:gotoPreviousScene()
                	return true
				elseif type(scene.gotoPreviousScene) == 'string' then
					composer.gotoScene(scene.gotoPreviousScene, {time = 500, effect = 'slideRight'})
					return true
				end
            end
		end
	end)
end
-- Please note that above Runtime events use anonymous listeners. While it's fine for these cases,
-- it is not possible to remove the event listener if needed. For instanse, an accelerometer event listener must be removed at some point
-- to reduce battery consumption.
-- The above cases are fine to use anonymous listeners because we don't need to remove them ever.

-- Add support for controllers so the game is playable on Android TV, Apple TV and with a MFi controller
require('libs.controller') -- Activate by requiring

-- This library automatically loads and saves it's storage into databox.json inside Documents directory
-- And it uses iCloud KVS storage on iOS and tvOS
local databox = require('libs.databox')
databox({
	isSoundOn = true,
	isMusicOn = true,
	isHelpShown = false,
	overscanValue = 0
})

-- This library manages sound files and music files playback
-- Inside it there is a list of all used audio files
local sounds = require('libs.sounds')
sounds.isSoundOn = databox.isSoundOn
sounds.isMusicOn = databox.isMusicOn

-- This library helps position elements on the screen during the resize event
require('libs.relayout')

-- This library deals with the overscan issue that is present on many TVs
local overscan = require('libs.overscan')
overscan.compensate(databox.overscanValue)

-- Show menu scene
composer.gotoScene('scenes.menu')
