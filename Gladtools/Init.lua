local ADDON_NAME, GT = ...

GT = GT or {}
_G.GladTools = GT

GT.ADDON_NAME = ADDON_NAME
GT.modules = GT.modules or {}
GT.moduleOrder = GT.moduleOrder or {}

function GT:Print(message)
    print("|cff33ff99Gladtools|r " .. tostring(message))
end

function GT:RegisterModule(name, module)
    if not name or type(module) ~= "table" then
        return
    end
    if self.modules[name] then
        return
    end

    module.name = name
    self.modules[name] = module
    self.moduleOrder[#self.moduleOrder + 1] = module
end

function GT:IterateModules(callbackName, ...)
    for _, module in ipairs(self.moduleOrder) do
        local callback = module[callbackName]
        if type(callback) == "function" then
            local ok, err = pcall(callback, module, ...)
            if not ok then
                self:Print(string.format("Module %s failed in %s: %s", module.name or "?", callbackName, tostring(err)))
            end
        end
    end
end
