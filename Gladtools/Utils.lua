local _, GT = ...

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = deepCopy(child)
    end
    return copy
end

local function mergeDefaults(target, defaults)
    for key, defaultValue in pairs(defaults) do
        if type(defaultValue) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = deepCopy(defaultValue)
            else
                mergeDefaults(target[key], defaultValue)
            end
        elseif target[key] == nil then
            target[key] = defaultValue
        end
    end
end

local function mergeOverwrite(target, source)
    for key, sourceValue in pairs(source) do
        if type(sourceValue) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            mergeOverwrite(target[key], sourceValue)
        else
            target[key] = sourceValue
        end
    end
end

local function tablesEqual(a, b)
    if type(a) ~= type(b) then
        return false
    end

    if type(a) ~= "table" then
        return a == b
    end

    for key, value in pairs(a) do
        if not tablesEqual(value, b[key]) then
            return false
        end
    end

    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end

    return true
end

local function normalizePath(path)
    if type(path) ~= "table" then
        return nil
    end
    return path
end

function GT:DeepCopy(value)
    return deepCopy(value)
end

function GT:MergeDefaults(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then
        return
    end
    mergeDefaults(target, defaults)
end

function GT:MergeOverwrite(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return
    end
    mergeOverwrite(target, source)
end

function GT:TablesEqual(a, b)
    return tablesEqual(a, b)
end

function GT:GetByPath(root, path)
    local resolvedPath = normalizePath(path)
    if not resolvedPath then
        return nil
    end

    local node = root
    for index = 1, #resolvedPath do
        if type(node) ~= "table" then
            return nil
        end
        node = node[resolvedPath[index]]
        if node == nil then
            return nil
        end
    end

    return node
end

function GT:SetByPath(root, path, value)
    local resolvedPath = normalizePath(path)
    if not resolvedPath or #resolvedPath == 0 then
        return false
    end

    local node = root
    for index = 1, #resolvedPath - 1 do
        local key = resolvedPath[index]
        if type(node[key]) ~= "table" then
            node[key] = {}
        end
        node = node[key]
    end

    node[resolvedPath[#resolvedPath]] = value
    return true
end

function GT:Trim(text)
    if type(text) ~= "string" then
        return ""
    end
    return (text:gsub("^%s*(.-)%s*$", "%1"))
end

function GT:FormatRemaining(seconds)
    if not seconds or seconds <= 0 then
        return ""
    end

    if seconds >= 60 then
        return string.format("%dm", math.ceil(seconds / 60))
    end

    if seconds >= 10 then
        return tostring(math.ceil(seconds))
    end

    return string.format("%.1f", seconds)
end

function GT:GetClassColor(classFile)
    if not classFile then
        return 1, 1, 1
    end

    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then
        return color.r, color.g, color.b
    end

    return 1, 1, 1
end

function GT:CreateBasicCheckbox(parent, labelText, x, y, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, y)
    checkbox:SetScript("OnClick", function(button)
        if onClick then
            onClick(button:GetChecked() and true or false)
        end
    end)

    checkbox.Text:SetText(labelText)
    checkbox.Text:SetWidth(380)
    checkbox.Text:SetJustifyH("LEFT")
    return checkbox
end
