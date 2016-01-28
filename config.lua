local normalW, normalH = 640, 960

if not display then return end -- This is needed for dekstop app

-- This calculation extends the standard letterbox scaling
-- Using this point x = 0, y = 0 is always in the top left corner of the screen on all devices
-- And x = display.contentWidth, y = display.contentHeight is always in the bottom right corner
local w, h = display.pixelWidth, display.pixelHeight
local scale = math.max(normalW / w, normalH / h)
w, h = w * scale, h * scale

application = {
    content = {
		width = w,
        height = h,
        scale = 'letterbox',
        fps = 60,
        imageSuffix = {
			['@2x'] = 1.1,
            --['@4x'] = 2.1
		}
    }
}
