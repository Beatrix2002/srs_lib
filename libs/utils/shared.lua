local Utils = {}

local counter = 0

Utils.GenId = function(prefix)
    counter += 1
    return ('srs_%s_%s'):format(prefix or 'id', counter)
end

return Utils
