-- Corona Cannon
-- A complete remake of Ghosts vs. Monsters sample game for Corona SDK.
-- Created by Sergey Lerg for Corona Labs.

display.setStatusBar(display.HiddenStatusBar)
system.activate('multitouch')
display.setDefault('isAnchorClamped', false) -- Needed for scenes/reload_game.lua animation

local composer = require('composer')
composer.recycleOnSceneChange = true -- Automatically remove scenes from memory
composer.setVariable('levelCount', 10) -- Set how many levels there are under levels/ directory

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
