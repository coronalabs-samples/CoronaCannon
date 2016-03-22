-- Databox
-- This library automatically loads and saves it's storage into databox.json inside Documents directory.
-- And it uses iCloud KVS storage on iOS and tvOS.
-- It uses metatables to do it's job.
-- Require the library and call it with a table of default values. Only 1 level deep table is supported.
-- supported values are strings, numbers and booleans.
-- It will create and populate the file on the first run. If file already exists, it will load it's content into the data table.
-- Accessing data is simple like databox.someKey
-- Saving data is automatic on key change, you only need to set a value like databox.someKey = 'someValue'
-- If you update default values, all new values will be added into the existing file.

local json = require('json')
local iCloud

local data = {}
local defaultData = {}

local path = system.pathForFile('databox.json', system.DocumentsDirectory)
local isiOS = system.getInfo('platformName') == 'iPhone OS'
local istvOS = system.getInfo('platformName') == 'tvOS'
local isOSX = system.getInfo('platformName') == 'Mac OS X'

if isiOS or istvOS or isOSX then
    iCloud = require('plugin.iCloud')
end

-- Copy tables by value
-- Nested tables are not supported, because iCloud
local function shallowcopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(k) == 'string' then
            if type(v) == 'number' or type(v) == 'string' or type(v) == 'boolean' then
                copy[k] = v
            else
                print('databox: Values of type "' .. type(v) .. '" are not supported.')
            end
        end
    end
    return copy
end

-- When saving, upload to iCloud and save to disk
local function saveData()
    if iCloud then
        iCloud.set('databox', data)
    end
    if not istvOS then
        local file = io.open(path, 'w')
        if file then
            file:write(json.encode(data))
            io.close(file)
        end
    end
end

-- When loading, try iCloud first and only then attempt reading from disk
-- If no file or no iCloud data - load defaults
local function loadData()
    local iCloudData
    if iCloud then
        iCloudData = iCloud.get('databox')
    end
    if iCloudData then
        data = iCloudData
    else
        if istvOS then
            data = shallowcopy(defaultData)
            saveData()
        else
            local file = io.open(path, 'r')
            if file then
                data = json.decode(file:read('*a'))
                io.close(file)
            else
                data = shallowcopy(defaultData)
                saveData()
            end
        end
    end
end

-- If you update your app and set new defaults, check if an old file has all the keys
local function patchIfNewDefaultData()
    local isPatched = false
    for k, v in pairs(defaultData) do
        if data[k] == nil then
            data[k] = v
            isPatched = true
        end
    end
    if isPatched then
        saveData()
    end
end

-- Metatables action!
local mt = {
    __index = function(t, k) -- On indexing, just return a field from the data table
        return data[k]
    end,
    __newindex = function(t, k, value) -- On setting an index, save the data table automatically
        data[k] = value
        saveData()
    end,
    __call = function(t, value) -- On calling, initiate with defaults
        if type(value) == 'table' then
            defaultData = shallowcopy(value)
        end
        loadData()
        patchIfNewDefaultData()
    end
}

local _M = {}
setmetatable(_M, mt)
return _M
