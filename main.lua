-- Corona Cannon
-- A complete remake of Ghosts vs. Monsters sample game for Corona SDK.
-- Most of the graphics made by kenney.nl
-- Created by Sergey Lerg for Corona Labs.

display.setStatusBar(display.HiddenStatusBar)
system.activate('multitouch')
display.setDefault('isAnchorClamped', false) -- Needed for scenes/reload_game.lua animation

local composer = require('composer')
composer.recycleOnSceneChange = true -- Automatically remove scenes from memory
composer.setVariable('levelCount', 10) -- Set how many levels there are under levels/ directory

-- Add support for controllers so the game is playable on Android TV and Apple TV
require('libs.controller') -- Activate by requiring

-- This library automatically loads and saves it's storage into databox.json inside Documents directory
local databox = require('libs.databox')
databox({
	isSoundOn = true,
	isMusicOn = true
})

-- This library manages sound files and music files playback
-- Inside it there is a list of all used audio files
local sounds = require('libs.sounds')
sounds.isSoundOn = databox.isSoundOn
sounds.isMusicOn = databox.isMusicOn

-- Show menu scene
composer.gotoScene('scenes.menu')

-- Fix
easing.continuousLoop = function(t, tMax, start, delta)
	local interval = t / tMax
	if interval < 0.5 then
		return start + delta * interval * 2
	else
		return start + delta * (1 - interval) * 2
	end
end
