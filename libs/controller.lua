local eachframe = require('libs.eachframe')

local _M = {}

_M.axes = {
    x = {type = 'motion', name = 'x'},
    y = {type = 'motion', name = 'y'},
    hatX = {type = 'motion', name = 'x'},
    hatY = {type = 'motion', name = 'y'},
    leftX = {type = 'motion', name = 'x'},
    leftY = {type = 'motion', name = 'y'},
    z = {type = 'rotation', name = 'x'},
    rotationZ = {type = 'rotation', name = 'y'},
    rightX = {type = 'rotation', name = 'x'},
    rightY = {type = 'rotation', name = 'y'}
}

_M.keys = {
    left = {type = 'motion', name = 'x', dir = -1},
    right = {type = 'motion', name = 'x', dir = 1},
    up = {type = 'motion', name = 'y', dir = -1},
    down = {type = 'motion', name = 'y', dir = 1},
    button1 = {type = 'action'},
    space = {type = 'action'},
    enter = {type = 'action'},
    numPadEnter = {type = 'action'},
    escape = {type = 'pause'},
    button2 = {type = 'pause'},
    button9 = {type = 'pause'},
    menu = {type = 'pause'}, -- Apple TV, menu button to show pause screen
    buttonA = {type = 'action'}, -- Switch map movement/cannon control on Apple TV remote by pressing the touchpad
    buttonX = {type = 'action'} -- Apple TV, play/pause button to fire the cannnon
}

-- Navigate to on-screen buttons
function _M.selectNextVisualButton(axis, dir)
    local self = _M
    local x, y, a = self.activeVisualButton.x, self.activeVisualButton.y, self.activeVisualButton[axis]
    -- All buttons are sorted and one is choosed by looking at their coordinates and movement from the controller
    local sort = {}
    for i = 1, #self.visualButtons do
        local b = self.visualButtons[i]
        if b.isVisible and ((dir == 1 and b[axis] > a) or (dir == -1 and b[axis] < a)) then
            local distance = math.sqrt((b.x - x) ^ 2 + (b.y - y) ^ 2)
            local axisDistance = math.abs(b[axis] - a)
            table.insert(sort, {button = b, distance = distance, axisDistance = axisDistance, index = i})
        end
    end
    if #sort > 0 then
        table.sort(sort, function(e1, e2)
            return e1.axisDistance < e2.axisDistance
        end)
        local axisDistance = sort[1].axisDistance
        for i = #sort, 1, -1 do
            local b = sort[i]
            if b.axisDistance > axisDistance then
                table.remove(sort, i)
            end
        end
        table.sort(sort, function(e1, e2)
            return e1.distance < e2.distance
        end)
        self.selectVisualButton(sort[1].index)
    end
end

-- Motion is the left stick / D-pad
function _M.processMotion(name, value)
    local self = _M
    if #self.visualButtons > 0 then
        if math.abs(value) == 1 then
            self.selectNextVisualButton(name, value)
        end
    end
    if self.onMotion then
        self.onMotion(name, value)
    end
end

-- Rotation is the right stick
function _M.processRotation(name, value)
    local self = _M
    if self.onRotation then
        self.onRotation(name, value)
    end
end

-- Apply a visual effect for the selected on-screen button
function _M.setSelectionEffect(button, isSelected)
    local self = _M
    if not button then
        return
    end
    if isSelected then
        self.activeVisualButton.xScale, self.activeVisualButton.yScale = 1, 1
        self.activeVisualButtonTransition = transition.to(self.activeVisualButton, {time = 1000, xScale = 1.05, yScale = 1.05, iterations = 0, transition = easing.continuousLoop})
        local edge = 1.2
        if self.activeVisualButton.isRound then
            self.activeVisualButtonOutline = display.newCircle(self.activeVisualButton.x, self.activeVisualButton.y, self.activeVisualButton.width / 2 * edge)
        else
            self.activeVisualButtonOutline = display.newRoundedRect(self.activeVisualButton.x, self.activeVisualButton.y, self.activeVisualButton.width * edge, self.activeVisualButton.height * edge, 10)
        end
        self.activeVisualButtonOutline:setFillColor(0.5, 1, 0.5, 0.2)
        local super = self
        function self.activeVisualButtonOutline:eachFrame()
            self.x, self.y = super.activeVisualButton.x, super.activeVisualButton.y
        end
        eachframe.add(self.activeVisualButtonOutline)
        function self.activeVisualButtonOutline:finalize()
            eachframe.remove(self)
        end
        self.activeVisualButtonOutline:addEventListener('finalize')
        for i = 1, self.activeVisualButton.parent.numChildren do
            if self.activeVisualButton.parent[i] == self.activeVisualButton then
                self.activeVisualButton.parent:insert(i, self.activeVisualButtonOutline)
                break
            end
        end
    else
        if self.activeVisualButtonTransition then
            transition.cancel(self.activeVisualButtonTransition)
            self.activeVisualButtonTransition = nil
        end
        display.remove(self.activeVisualButtonOutline)
        self.activeVisualButton.xScale, self.activeVisualButton.yScale = 1, 1
    end
end

function _M.selectVisualButton(index)
    local self = _M
    self:deselectVisualButton()
    if type(index) == 'table' then
        index = table.indexOf(self.visualButtons, index)
    end
    self.activeVisualButton = self.visualButtons[index]
    self.setSelectionEffect(self.activeVisualButton, true)
end

function _M.deselectVisualButton()
    local self = _M
    self.setSelectionEffect(self.activeVisualButton, false)
    self.activeVisualButton = nil
end

-- Return true if there is an active controller
function _M.isActive()
    local self = _M
    return self.activeDevice ~= nil
end

-- If some controller sends some data, make it active and select an on-screen button
function _M.checkActiveDevice(device)
    local self = _M
    if device and not self.activeDevice and (
            device.type == 'keyboard' or -- Allow only these devices to be used with the game
            device.type == 'joystick' or
            device.type == 'gamepad' or
            device.type == 'directionalPad'
        ) then
        self.activeDevice = device
        if #self.visualButtons > 0 and not self.activeVisualButton then
            for i = 1, #self.visualButtons do
                if self.visualButtons[i].isVisible then
                    self.selectVisualButton(i)
                    break
                end
            end
        end
    end
end

function _M.getInputDevices()
    local self = _M
    self.devices = system.getInputDevices()
end

-- Check if the currently active controller is disconnected
function _M:inputDeviceStatus(event)
    if event.device and event.device == self.activeDevice and event.device.connectionState == 'disconnected' then
        self.activeDevice = nil
        self.deselectVisualButton()
    end
end

-- Sticks and D-pad
function _M:axis(event)
    local a = self.axes[event.axis.type]
    self.checkActiveDevice(event.device)
    if event.device == self.activeDevice then
        if a then
            if a.type == 'motion' then
                self.processMotion(a.name, event.normalizedValue)
            else
                self.processRotation(a.name, event.normalizedValue)
            end
        end
    end
end

-- Controller buttons and keyboard buttons
function _M:key(event)
    if event.device and not self.activeDevice then
        self.activeDevice = event.device
    end
    local k = self.keys[event.keyName]
    if event.phase == 'down' and (not event.device or event.device == self.activeDevice) then
        if k then
            if k.type == 'action' and self.activeVisualButton then
                local x, y = self.activeVisualButton.parent:localToContent(self.activeVisualButton.x, self.activeVisualButton.y)
                local e = {name = 'touch', target = self.activeVisualButton, phase = 'began', x = x, y = y, xStart = x, yStart = y}
                self.activeVisualButton:dispatchEvent(e)
                e.phase = 'ended'
                self.activeVisualButton:dispatchEvent(e)
            elseif k.type == 'motion' then
                if #self.visualButtons > 0 and not self.activeVisualButton then
                    for i = 1, #self.visualButtons do
                        if self.visualButtons[i].isVisible then
                            self.selectVisualButton(i)
                            break
                        end
                    end
                end
                self.processMotion(k.name, k.dir)
            end
        end
        if self.onKey then
            self.onKey(event.keyName, k and k.type)
        end
    end
end

-- Tell the library what on-screen buttons are currently available for navigation with a controller
function _M.setVisualButtons(buttons)
    local self = _M
    self.deselectVisualButton()
    self.visualButtons = buttons or {}
    if #self.visualButtons > 0 and self.isActive() then
        for i = 1, #self.visualButtons do
            if self.visualButtons[i].isVisible then
                self.selectVisualButton(i)
                break
            end
        end
    end
end

function _M.activate()
    local self = _M
    Runtime:addEventListener('inputDeviceStatus', self)
    Runtime:addEventListener('axis', self)
    Runtime:addEventListener('key', self)

    local delay = 1
    if system.getInfo('platformName') == 'tvOS' then
        delay = 500 -- Need to wait a little on tvOS for some reason
        self.keys.left = nil -- Disable swipe events on Apple TV remote
        self.keys.right = nil
        self.keys.up = nil
        self.keys.down = nil
    end
    timer.performWithDelay(delay, function()
        self.getInputDevices()
    end)
end

_M.activate()

return _M
