-- Databox
-- This library automatically loads and saves it's storage into databox.json inside Documents directory.
-- It uses metatables to do it's job.
-- Require the library and call it with a table of default values. Only 1 level deep table is supported.
-- supported values are strings, numbers and booleans.
-- It will create and populate the file on the first run. If file already exists, it will load it's content into the data table.
-- Accessing data is simple like databox.someKey
-- Saving data is automatic on key change, you only need to set a value like databox.someKey = 'someValue'
-- If you update default values, all new values will be added into the existing file.

local json = require('json')

local data = {}
local defaultData = {}

local path = system.pathForFile('databox.json', system.DocumentsDirectory)

local function deepcopy(t)
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

local function saveData()
    local file = io.open(path, 'w')
    if file then
        file:write(json.encode(data))
        io.close(file)
    end
end

local function loadData()
    local file = io.open(path, 'r')
    if file then
        data = json.decode(file:read('*a'))
        io.close(file)
    else
        data = deepcopy(defaultData)
        saveData()
    end
end

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

local mt = {
    __index = function(t, k)
        return data[k]
    end,
    __newindex = function(t, k, value)
        data[k] = value
        saveData()
    end,
    __call = function(t, value)
        if type(value) == 'table' then
            defaultData = deepcopy(value)
        end
        loadData()
        patchIfNewDefaultData()
    end
}

local _M = {}
setmetatable(_M, mt)
return _M
