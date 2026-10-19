-- ============================================================
-- UNIVERSAL TRACKER v6.2 (FINAL — ready to run)
-- ============================================================

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local RepStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TextChatService = game:GetService("TextChatService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

-- ФИКС 1: CoreGui в pcall
local okCore, CoreGui = pcall(function() return game:GetService("CoreGui") end)
CoreGui = okCore and CoreGui or nil

-- ==================== UI ====================
local sg = Instance.new("ScreenGui")
sg.Name = "UniversalTrackerV62"
sg.ResetOnSpawn = false
sg.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 440, 0, 600)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Active = true
MainFrame.Parent = sg

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "  Tracker v6.2 (Final)"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==================== ФИЛЬТРЫ ====================
local FilterFrame = Instance.new("Frame")
FilterFrame.Size = UDim2.new(1, -10, 0, 65)
FilterFrame.Position = UDim2.new(0, 5, 0, 35)
FilterFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
FilterFrame.Parent = MainFrame

local filters = {
    {name = "NET", value = true}, {name = "Stats", value = true},
    {name = "Inv", value = true}, {name = "Workspace", value = true},
    {name = "Storage", value = true}, {name = "GUI", value = true},
    {name = "Attr", value = true}, {name = "Char", value = true},
    {name = "Chat", value = true}, {name = "Const", value = true},
    {name = "Pass", value = true}, {name = "Anim", value = false},
}

for i, f in ipairs(filters) do
    local row = math.floor((i-1) / 6)
    local col = (i-1) % 6
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 67, 0, 25)
    btn.Position = UDim2.new(0, 3 + col * 70, 0, 5 + row * 28)
    btn.BackgroundColor3 = f.value and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 0, 0)
    btn.Text = f.name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 9
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = FilterFrame
    
    btn.MouseButton1Click:Connect(function()
        f.value = not f.value
        btn.BackgroundColor3 = f.value and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 0, 0)
        for _, label in ipairs(Scroll:GetChildren()) do
            if label:IsA("TextLabel") and label:GetAttribute("Category") == f.name then
                label.Visible = f.value
            end
        end
    end)
end

-- ==================== КНОПКИ ====================
local BtnRow = Instance.new("Frame")
BtnRow.Size = UDim2.new(1, -10, 0, 60)
BtnRow.Position = UDim2.new(0, 5, 0, 105)
BtnRow.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
BtnRow.Parent = MainFrame

local function makeBtn(parent, x, y, w, text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w, 0, 26)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = parent
    return btn
end

local ClearBtn = makeBtn(BtnRow, 2, 2, 100, "CLEAR", Color3.fromRGB(150, 50, 50))
local SaveBtn = makeBtn(BtnRow, 105, 2, 100, "SAVE LOGS", Color3.fromRGB(50, 100, 150))
local ScanClosuresBtn = makeBtn(BtnRow, 208, 2, 105, "SCAN CLOSURES", Color3.fromRGB(150, 50, 150))
local ScanOwnersBtn = makeBtn(BtnRow, 316, 2, 105, "SCAN OWNERS", Color3.fromRGB(50, 150, 100))
local DumpBCBtn = makeBtn(BtnRow, 2, 31, 155, "DUMP BYTECODE", Color3.fromRGB(150, 100, 50))
local ScanScriptsBtn = makeBtn(BtnRow, 160, 31, 155, "RUNNING SCRIPTS", Color3.fromRGB(50, 130, 130))

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 1, -170)
Scroll.Position = UDim2.new(0, 5, 0, 168)
Scroll.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Scroll.ScrollBarThickness = 4
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Parent = Scroll
Layout.Padding = UDim.new(0, 1)

-- ==================== СЕРИАЛИЗАТОР ====================
local function serialize(v, depth, seen)
    depth = depth or 0
    seen = seen or {}
    if depth > 3 then return "..." end
    if v == nil then return "nil" end
    
    local t = type(v)
    if t == "boolean" or t == "number" then return tostring(v) end
    if t == "string" then
        if #v > 80 then return '"'..v:sub(1,80)..'..."' end
        return '"'..v..'"'
    end
    if typeof(v) == "Instance" then return "[I:"..v.Name.."]" end
    if typeof(v) == "Vector3" then return string.format("V3(%.0f,%.0f,%.0f)",v.X,v.Y,v.Z) end
    if typeof(v) == "CFrame" then return "CFrame" end
    if typeof(v) == "Color3" then return "Color3" end
    if typeof(v) == "EnumItem" then return v.Name end
    
    if t == "table" or typeof(v) == "table" then
        if seen[v] then return "<cycle>" end
        seen[v] = true
        local hasStringKeys = false
        for k in pairs(v) do
            if type(k) ~= "number" then hasStringKeys = true; break end
        end
        local parts = {}
        local isArray = not hasStringKeys and #v > 0
        if isArray then
            for i = 1, math.min(#v, 10) do
                table.insert(parts, serialize(v[i], depth+1, seen))
            end
            if #v > 10 then table.insert(parts, "..."..(#v-10)) end
        else
            local count = 0
            for k, val in pairs(v) do
                if count >= 10 then table.insert(parts, "..."); break end
                table.insert(parts, tostring(k).."="..serialize(val, depth+1, seen))
                count = count + 1
            end
        end
        return "{"..table.concat(parts,",").."}"
    end
    return tostring(v)
end

-- ==================== ЛОГИКА ====================
local logs = {}
local maxLogs = 250
local labelQueue = {}

local function getFilterValue(name)
    for _, f in ipairs(filters) do
        if f.name == name then return f.value end
    end
    return true
end

local function addLog(category, text, color)
    local time = os.date("%H:%M:%S")
    local fullText = "["..time.."][ "..category.." ] "..text
    table.insert(logs, fullText)
    if #logs > maxLogs then table.remove(logs, 1) end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = fullText
    label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Code
    label.TextSize = 10
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label:SetAttribute("Category", category)
    label.Visible = getFilterValue(category)
    label.Parent = Scroll
    
    table.insert(labelQueue, label)
    if #labelQueue > maxLogs then
        local old = table.remove(labelQueue, 1)
        pcall(function() old:Destroy() end)
    end
end

-- ==================== THROTTLE ====================
local throttleBuffer = {}
local throttleEnd = 1.0

local function flushEntry(key)
    local entry = throttleBuffer[key]
    if not entry then return end
    throttleBuffer[key] = nil
    
    local summary = ""
    if entry.count > 1 then
        summary = "("..entry.count.."x/1s)"
        local uniq = {}
        for s, c in pairs(entry.sigs) do
            table.insert(uniq, s.." ["..c.."x]")
        end
        summary = summary.."\n  └ "..table.concat(uniq, "\n  └ ")
    else
        for s, _ in pairs(entry.sigs) do summary = s end
    end
    
    local arrow = (entry.direction == "IN") and "⬇" or ((entry.method == "FireServer") and "⬆" or "?")
    local color = (entry.direction == "IN") and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 200, 100)
    addLog("NET", arrow.." "..entry.name.." "..summary, color)
end

local function logNet(name, method, args, direction)
    local key = name.."_"..method.."_"..direction
    local now = time()
    local sig = ""
    for _, v in ipairs(args) do sig = sig .. serialize(v) .. " " end
    if sig == "" then sig = "(no args)" end
    
    local entry = throttleBuffer[key]
    if entry and now - entry.first < throttleEnd then
        entry.count = entry.count + 1
        entry.sigs[sig] = (entry.sigs[sig] or 0) + 1
        return
    end
    if entry then flushEntry(key) end
    
    local newEntry = {first = now, count = 1, sigs = {[sig]=1}, name = name, method = method, direction = direction}
    throttleBuffer[key] = newEntry
    task.delay(throttleEnd + 0.2, function()
        if throttleBuffer[key] == newEntry then flushEntry(key) end
    end)
end

-- ==================== 1. СЕТЬ ====================
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if typeof(self) == "Instance" then
        if method == "UserOwnsGamePassAsync" and self == MarketplaceService then
            addLog("Pass", "🔑 UserOwnsGamePassAsync("..tostring(args[1])..", "..tostring(args[2])..")", Color3.fromRGB(255, 200, 100))
        elseif method == "PlayerOwnsAsset" and self == MarketplaceService then
            addLog("Pass", "🔑 PlayerOwnsAsset("..tostring(args[1])..", "..tostring(args[2])..")", Color3.fromRGB(255, 200, 100))
        elseif method == "FireServer" then
            logNet(self.Name, method, args, "OUT")
        elseif method == "InvokeServer" then
            local argsStr = ""
            for _, v in ipairs(args) do argsStr = argsStr .. serialize(v) .. " " end
            local result = oldNamecall(self, ...)
            addLog("NET", "🔄 "..self.Name.." "..argsStr.." => "..serialize(result), Color3.fromRGB(255, 150, 200))
            return result
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- ==================== 2. ONCLIENTEVENT ====================
local hookedRemotes = {}
local ourHandlers = {}

local function hookRemote(remote)
    if hookedRemotes[remote] then return end
    hookedRemotes[remote] = true
    if remote:IsA("RemoteEvent") then
        local handler = function(...) logNet(remote.Name, "OnClientEvent", {...}, "IN") end
        ourHandlers[handler] = true
        remote.OnClientEvent:Connect(handler)
    end
end

for _, obj in ipairs(RepStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") then pcall(hookRemote, obj) end
end

-- ==================== 3. LEADERSTATS ====================
local function monitorLeaderstats()
    local leaderstats = Player:WaitForChild("leaderstats", 10)
    if not leaderstats then
        for _, v in ipairs(Player:GetChildren()) do
            if v:IsA("Folder") or v:IsA("Model") then
                for _, stat in ipairs(v:GetChildren()) do
                    if stat:IsA("IntValue") or stat:IsA("NumberValue") or stat:IsA("StringValue") then
                        addLog("Stats", "📊 "..v.Name.."."..stat.Name.." = "..tostring(stat.Value), Color3.fromRGB(100, 255, 100))
                        stat:GetPropertyChangedSignal("Value"):Connect(function()
                            addLog("Stats", "💰 "..v.Name.."."..stat.Name.." → "..tostring(stat.Value), Color3.fromRGB(0, 255, 100))
                        end)
                    end
                end
            end
        end
        return
    end
    for _, stat in ipairs(leaderstats:GetChildren()) do
        addLog("Stats", "📊 "..stat.Name.." = "..tostring(stat.Value), Color3.fromRGB(100, 255, 100))
        stat:GetPropertyChangedSignal("Value"):Connect(function()
            addLog("Stats", "💰 "..stat.Name.." → "..tostring(stat.Value), Color3.fromRGB(0, 255, 100))
        end)
    end
end
task.spawn(monitorLeaderstats)

-- ==================== 4. BACKPACK ====================
task.spawn(function()
    local backpack = Player:WaitForChild("Backpack", 10)
    if not backpack then return end
    backpack.ChildAdded:Connect(function(tool)
        addLog("Inv", "📦 + "..tool.Name.." ("..tool.ClassName..")", Color3.fromRGB(100, 255, 200))
    end)
    backpack.ChildRemoved:Connect(function(tool)
        addLog("Inv", "📦 - "..tool.Name, Color3.fromRGB(255, 150, 150))
    end)
end)

-- ==================== 5. CHARACTER ====================
task.defer(function()
    local teamName = Player.Team and Player.Team.Name or "nil"
    addLog("Char", "👥 Team (initial): "..teamName, Color3.fromRGB(200, 200, 255))
    addLog("Char", "📷 CameraMode (initial): "..tostring(Player.CameraMode), Color3.fromRGB(200, 200, 255))
end)

Player:GetPropertyChangedSignal("Team"):Connect(function()
    addLog("Char", "👥 Team: "..(Player.Team and Player.Team.Name or "nil"), Color3.fromRGB(200, 200, 255))
end)
Player:GetPropertyChangedSignal("CameraMode"):Connect(function()
    addLog("Char", "📷 CameraMode: "..tostring(Player.CameraMode), Color3.fromRGB(200, 200, 255))
end)

local function monitorCharacter(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    local conns = {}
    local lastWS, lastJP, lastMH = hum.WalkSpeed, hum.JumpPower, hum.MaxHealth
    
    table.insert(conns, hum.HealthChanged:Connect(function(hp)
        addLog("Char", "❤ Health: "..math.floor(hp), Color3.fromRGB(255, 100, 100))
    end))
    table.insert(conns, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if math.abs(hum.WalkSpeed - lastWS) < 0.5 then return end
        lastWS = hum.WalkSpeed
        addLog("Char", "🏃 WalkSpeed: "..hum.WalkSpeed, Color3.fromRGB(255, 200, 100))
    end))
    table.insert(conns, hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if math.abs(hum.JumpPower - lastJP) < 0.5 then return end
        lastJP = hum.JumpPower
        addLog("Char", "🦘 JumpPower: "..hum.JumpPower, Color3.fromRGB(255, 200, 100))
    end))
    table.insert(conns, hum:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        if math.abs(hum.MaxHealth - lastMH) < 1 then return end
        lastMH = hum.MaxHealth
        addLog("Char", "💪 MaxHealth: "..hum.MaxHealth, Color3.fromRGB(255, 200, 100))
    end))
    
    local animator = hum:WaitForChild("Animator", 5)
    if animator then
        table.insert(conns, animator.AnimationPlayed:Connect(function(track)
            local animName = "Unknown"
            pcall(function() animName = track.Animation.Name end)
            addLog("Anim", "🎬 "..animName, Color3.fromRGB(200, 255, 150))
        end))
    end
    
    local ancestryConn
    ancestryConn = char.AncestryChanged:Connect(function()
        if not char:IsDescendantOf(game) then
            for _, c in ipairs(conns) do pcall(c.Disconnect, c) end
            pcall(ancestryConn.Disconnect, ancestryConn)
        end
    end)
end

if Player.Character then monitorCharacter(Player.Character) end
Player.CharacterAdded:Connect(monitorCharacter)

-- ==================== 6. WORKSPACE ====================
Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") or obj:IsA("Part") then
        if Player.Character and obj:IsDescendantOf(Player.Character) then return end
        local lowerName = obj.Name:lower()
        if obj:IsA("Model") or lowerName:find("car") or lowerName:find("npc") or lowerName:find("box") or lowerName:find("item") then
            addLog("Workspace", "+ "..obj.Name.." ("..obj.ClassName..")", Color3.fromRGB(100, 255, 100))
        end
    end
end)
Workspace.DescendantRemoving:Connect(function(obj)
    if obj:IsA("Model") then
        addLog("Workspace", "- "..obj.Name, Color3.fromRGB(255, 100, 100))
    end
end)

-- ==================== 7. STORAGE ====================
RepStorage.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        addLog("Storage", "+ REMOTE: "..obj:GetFullName(), Color3.fromRGB(255, 200, 100))
        pcall(hookRemote, obj)
    elseif obj:IsA("ModuleScript") then
        addLog("Storage", "+ MODULE: "..obj.Name, Color3.fromRGB(150, 200, 255))
    end
end)

-- ==================== 8. GUI ====================
PlayerGui.ChildAdded:Connect(function(obj)
    addLog("GUI", "+ "..obj.Name.." ("..obj.ClassName..")", Color3.fromRGB(200, 150, 255))
    task.spawn(function()
        task.wait(1)
        if obj:IsA("ScreenGui") then
            for _, child in ipairs(obj:GetDescendants()) do
                if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Text ~= "" then
                    addLog("GUI", "  └ "..child.Name.." = "..tostring(child.Text), Color3.fromRGB(180, 180, 220))
                end
            end
        end
    end)
end)

-- ==================== 9. ATTRIBUTES ====================
local monitoredAttrs = {}
local function monitorAttributes(obj, prefix)
    if monitoredAttrs[obj] then return end
    monitoredAttrs[obj] = true
    obj.AttributeChanged:Connect(function(attr)
        addLog("Attr", prefix.."."..attr.." = "..tostring(obj:GetAttribute(attr)), Color3.fromRGB(255, 255, 100))
    end)
end

monitorAttributes(Player, "Player")
for _, obj in ipairs(RepStorage:GetDescendants()) do
    if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("Configuration") then
        monitorAttributes(obj, obj.Name)
    end
end

-- ==================== 10. CHAT ====================
pcall(function()
    TextChatService.MessageReceived:Connect(function(msg)
        local sender = msg.TextSource and msg.TextSource.Name or "?"
        addLog("Chat", sender..": "..msg.Text, Color3.fromRGB(200, 200, 200))
    end)
end)

-- ==================== 11. LOADED MODULES ====================
task.delay(10, function()
    pcall(function()
        if getloadedmodules then
            local mods = getloadedmodules()
            local filtered = {}
            for _, mod in ipairs(mods) do
                if mod:IsDescendantOf(game) then table.insert(filtered, mod) end
            end
            addLog("Storage", "📚 Загружено модулей: "..#filtered, Color3.fromRGB(150, 255, 255))
        end
    end)
end)

-- ==================== 12. SCAN CLOSURES ====================
local function scanClosures()
    if not getconnections then
        addLog("Const", "❌ getconnections не поддерживается", Color3.fromRGB(255, 100, 100))
        return
    end
    addLog("Const", "🔍 Сканирую closures...", Color3.fromRGB(255, 200, 255))
    local found = 0
    for _, obj in ipairs(RepStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            pcall(function()
                -- ФИКС 4: ipairs вместо pairs
                for _, conn in ipairs(getconnections(obj.OnClientEvent)) do
                    if conn.Function and not ourHandlers[conn.Function] then
                        local info = debug.getinfo(conn.Function)
                        if info and info.name ~= "" then
                            local consts = {}
                            pcall(function()
                                for _, c in pairs(debug.getconstants(conn.Function)) do
                                    if (type(c) == "string" and #c < 200) or type(c) == "number" then
                                        table.insert(consts, tostring(c))
                                    end
                                end
                            end)
                            if #consts > 0 then
                                addLog("Const", "🔍 "..obj.Name.." → "..info.name.."\n   Const: "..table.concat(consts, ", "), Color3.fromRGB(255, 100, 255))
                                found = found + 1
                            end
                        end
                    end
                end
            end)
        end
    end
    addLog("Const", "✅ Найдено "..found.." обработчиков с константами", Color3.fromRGB(255, 200, 255))
end

-- ==================== 13. SCAN OWNERS ====================
local function scanOwners()
    addLog("Workspace", "🔍 Сканирую NetworkOwner (только не-anchored)...", Color3.fromRGB(50, 255, 150))
    local ownByMe, ownByOther, serverOwned = 0, 0, 0
    local interesting = {}
    local i = 0
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            i = i + 1
            if i % 500 == 0 then task.wait() end
            local ok, owner = pcall(function() return obj:GetNetworkOwner() end)
            if ok then
                if owner == Player then
                    ownByMe = ownByMe + 1
                    -- ФИКС 3: лимит 50
                    if #interesting < 50 then
                        local parent = obj.Parent
                        if parent and (parent:IsA("Model") or parent.Name ~= obj.Name) then
                            table.insert(interesting, parent.Name.."."..obj.Name)
                        end
                    end
                elseif owner then
                    ownByOther = ownByOther + 1
                else
                    serverOwned = serverOwned + 1
                end
            end
        end
    end
    
    addLog("Workspace", "⚙ Твой: "..ownByMe.." | Чужих: "..ownByOther.." | Серверных: "..serverOwned, Color3.fromRGB(50, 255, 150))
    for k, name in ipairs(interesting) do
        if k > 30 then break end
        addLog("Workspace", "  ⚙ owned by you: "..name, Color3.fromRGB(150, 255, 200))
    end
end

-- ==================== 14. DUMP BYTECODE ====================
local function dumpBytecode()
    if not getscriptbytecode then
        addLog("Const", "❌ getscriptbytecode не поддерживается", Color3.fromRGB(255, 100, 100))
        return
    end
    addLog("Const", "📦 Дамп байткода...", Color3.fromRGB(255, 200, 100))
    local count = 0
    -- ФИКС 2: fallback на Character
    local backpack = Player:FindFirstChild("Backpack") or (Player.Character and Player.Character:FindFirstChildOfClass("Backpack"))
    local locations = {PlayerGui, Player.PlayerScripts, RepStorage, ReplicatedFirst, Workspace, backpack}
    
    for _, loc in ipairs(locations) do
        if loc then
            for _, obj in ipairs(loc:GetDescendants()) do
                if obj:IsA("LocalScript") then
                    pcall(function()
                        local bc = getscriptbytecode(obj)
                        if bc and #bc > 0 then
                            local safeName = obj.Name:gsub("[^%w_]", "_")
                            local filename = "bc_"..safeName.."_"..count..".bin"
                            writefile(filename, bc)
                            addLog("Const", "💾 "..obj:GetFullName().." → "..filename.." ("..#bc.." bytes)", Color3.fromRGB(255, 200, 100))
                            count = count + 1
                        end
                    end)
                elseif obj:IsA("ModuleScript") then
                    pcall(function()
                        if obj.RunContext == Enum.RunContext.Client then
                            local bc = getscriptbytecode(obj)
                            if bc and #bc > 0 then
                                local safeName = obj.Name:gsub("[^%w_]", "_")
                                local filename = "bc_mod_"..safeName.."_"..count..".bin"
                                writefile(filename, bc)
                                addLog("Const", "💾 "..obj:GetFullName().." → "..filename, Color3.fromRGB(255, 200, 100))
                                count = count + 1
                            end
                        end
                    end)
                end
            end
        end
    end
    addLog("Const", "✅ Сохранено: "..count.." байткодов", Color3.fromRGB(255, 200, 100))
end

-- ==================== 15. RUNNING SCRIPTS ====================
local function scanRunningScripts()
    pcall(function()
        if getrunningscripts then
            local scripts = getrunningscripts()
            local filtered = {}
            for _, s in ipairs(scripts) do
                if s:IsDescendantOf(game) and not (CoreGui and s:IsDescendantOf(CoreGui)) then
                    table.insert(filtered, s)
                end
            end
            addLog("Storage", "🏃 Запущено скриптов: "..#filtered, Color3.fromRGB(100, 255, 150))
            for _, s in ipairs(filtered) do
                pcall(function() addLog("Storage", "  └ "..s:GetFullName(), Color3.fromRGB(150, 200, 150)) end)
            end
        end
    end)
end

-- ==================== КНОПКИ ====================
ClearBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    logs = {}
    labelQueue = {}
end)

SaveBtn.MouseButton1Click:Connect(function()
    local keys = {}
    for key in pairs(throttleBuffer) do table.insert(keys, key) end
    for _, key in ipairs(keys) do flushEntry(key) end
    if #logs == 0 then
        game:GetService("StarterGui"):SetCore("SendNotification", {Title="Ошибка", Text="Нечего сохранять", Duration=3})
        return
    end
    local filename = "TrackerV62_"..os.date("%Y-%m-%d_%H-%M-%S")..".txt"
    pcall(function()
        writefile(filename, table.concat(logs, "\n"))
        game:GetService("StarterGui"):SetCore("SendNotification", {Title="Сохранено", Text=filename, Duration=5})
    end)
end)

ScanClosuresBtn.MouseButton1Click:Connect(scanClosures)
ScanOwnersBtn.MouseButton1Click:Connect(scanOwners)
DumpBCBtn.MouseButton1Click:Connect(dumpBytecode)
ScanScriptsBtn.MouseButton1Click:Connect(scanRunningScripts)

addLog("System", "Tracker v6.2 FINAL запущен.", Color3.fromRGB(0, 255, 100))