local printApi = srs.lib.print

local Prints = {}

Prints.Info = function(...)
    return printApi.info(...)
end

Prints.Warn = function(...)
    return printApi.warn(...)
end

Prints.Error = function(...)
    return printApi.error(...)
end

Prints.Debug = function(...)
    return printApi.debug(...)
end

return Prints
