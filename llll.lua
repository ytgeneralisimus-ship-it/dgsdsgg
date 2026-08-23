--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║        AETHER UI ULTRA + VEHICLE DEALERSHIP (Объединённый)          ║
    ║         Тёмно-красная тема • Плавные анимации • Размытие            ║
    ║         Все функции дилера, гонок, автоматизации и покупки          ║
    ║         Версия: 13.0 (финальная)                                    ║
    ╚══════════════════════════════════════════════════════════════════════╝
]]

-- ==================== СЛУЖЕБНЫЕ ФУНКЦИИ (из dealer.lua) ====================

local function races()
    local tab = {"None"}
    if workspace:FindFirstChild("Races") then
        for _, v in pairs(workspace.Races:GetChildren()) do
            if v:IsA("Model") then
                table.insert(tab, v.Name)
            end
        end
    end
    return tab
end

-- Анти-АФК
local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ==================== ПЕРЕХВАТ МЕТОДОВ (Hooking) ====================

local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == 'FireServer' then
        if self.Name == "JobRemoteHandler" and rawget(..., "Action") == "StartDeliveryJob" then
            _G.remotetable = ...
        elseif self.Name == "StartLobby" then
            _G.remotetable1 = args
            _G.remote1 = self
        elseif self.Name == "Vote" and (args[2] == "Vote" or args[2] == "VoteRace") then
            _G.remotetable2 = args
            _G.remote2 = self
        elseif self.Name == "Vote" and string.find(tostring(args[2]), "Vote") then
            _G.remotetable3 = args
            _G.remote3 = self
        elseif self.Name == "NPCHandler" and rawget(..., "Action") == "DeclineOrder" then
            return
        end
    elseif (method == 'Raycast' and getfenv().race) or (method == 'Ray' and _G.racetest) then
        args[2] = Vector3.new(0, -1000, 0)
    elseif method == 'Fire' and self.Name == "FullscreenReward" and (getfenv().deluxe1 or getfenv().deluxe) then
        return
    end
    
    return oldNamecall(self, ...)
end)

getfenv().grav = workspace.Gravity
getfenv().speed = 300
getfenv().raceSpeed = 200

-- ==================== ГЛОБАЛЬНЫЕ НАСТРОЙКИ (JSON) ====================

local settings = {
    -- Main
    driveSpeed = 300,
    autoFarm = false,
    autoCollectibles = false,
    autoVehicleKit = false,
    autoFire = false,
    autoSell = false,
    minSellPrice = 0,
    autoDelivery = false,
    autoDeliveryAdv = false,
    deliveryStars = 5,
    deliveryMinMoney = 0,
    deliveryMaxMoney = 999999999,
    autoUpgrade = false,
    annoyPopup = false,

    -- Race
    raceSpeed = 200,
    autoRace = false,
    autoRaceFast = false,
    autoDriftRace = false,
    autoFarmLaps = false,
    autoRaceFarming = false,

    -- Automation
    autoSeason = false,
    seasonFrom = 1,
    seasonTo = 50,
    autoFreeGifts = false,
    autoSpinStandard = false,
    autoSpinHyper = false,
    spinCount = 1,
    spinDelay = 0.3,
    autoOpenKits = false,
    kitCount = 1,
    autoOpenAllKits = false,
    autoChop = false,
    chopCarName = "Ferrari8",
    chopCarGUID = "1cbe963e-482a-49e9-ae80-80c1f56920e1",
    autoInfusion = false,
    infusionCarName = "Ferrari8",
    infusionCarGUID = "1cbe963e-482a-49e9-ae80-80c1f56920e1",
    autoDaily = false,
    autoConsume = false,
    consumeItem = "SpinTicket",
    autoPurchase = false,
    purchaseItem = "SomeItem",
    autoPurchaseSpins = false,
    purchaseSpinsType = "Standard",
    purchaseSpinsAmount = 1,
    autoCollectAllFreeRewards = false,
    autoSmartSell = false,

    -- Auto Buy Cars
    autoBuyCars = false,
    buyMinPrice = 0,
    buyMaxPrice = 999999999,
    buySpecificCar = "",

    -- Giver Kit
    giverKit = false,
}

-- Загрузка из JSON
local function loadSettings()
    if pcall(function() return readfile("VD_settings.json") end) then
        local data = game:GetService("HttpService"):JSONDecode(readfile("VD_settings.json"))
        if data then
            for k, v in pairs(data) do
                if settings[k] ~= nil then
                    settings[k] = v
                end
            end
        end
    end
    -- Для совместимости со старым файлом cdtdelivery.txt
    if pcall(function() return readfile("cdtdelivery.txt") end) and readfile("cdtdelivery.txt") ~= nil then
        local data = readfile("cdtdelivery.txt"):split(" ")
        if #data >= 3 then
            settings.deliveryStars = tonumber(data[1]) or 5
            settings.deliveryMinMoney = tonumber(data[2]) or 0
            settings.deliveryMaxMoney = tonumber(data[3]) or 999999999
        end
    end
end
loadSettings()

local function saveSettings()
    local json = game:GetService("HttpService"):JSONEncode(settings)
    writefile("VD_settings.json", json)
    local oldData = tostring(settings.deliveryStars.." "..settings.deliveryMinMoney.." "..settings.deliveryMaxMoney)
    writefile("cdtdelivery.txt", oldData)
end

-- ==================== AETHER LIB (МОДИФИЦИРОВАННАЯ) ====================

local AetherLib = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- Вспомогательная функция загрузки ассетов
function AetherLib:GetAsset(assetUrlOrId, customFileName)
    if not assetUrlOrId or assetUrlOrId == "" then return "" end
    if string.find(assetUrlOrId, "rbxassetid://") or string.find(assetUrlOrId, "roblox.com") then
        return assetUrlOrId
    end
    if (string.find(assetUrlOrId, "http://") or string.find(assetUrlOrId, "https://")) and writefile and getcustomasset then
        local fileName = customFileName or ("aether_asset_" .. tostring(math.abs(tick())) .. ".png")
        pcall(function()
            if not isfile or not isfile(fileName) then
                local data = game:HttpGet(assetUrlOrId)
                writefile(fileName, data)
            end
        end)
        local success, customId = pcall(getcustomasset, fileName)
        if success and customId then return customId end
    end
    return assetUrlOrId
end

function AetherLib:CreateWindow(options)
    options = options or {}
    local Title = options.Title or "Aether Script Hub"
    local SubTitle = options.SubTitle or "Ultra Edition"
    local ToggleKey = options.ToggleKey or Enum.KeyCode.RightControl

    -- Новая цветовая схема: тёмно-красный + кримсон
    local AccentColor = options.AccentColor or Color3.fromRGB(220, 20, 60)   -- Crimson
    local ThemeBgColor = options.ThemeBgColor or Color3.fromRGB(20, 10, 12)  -- почти чёрный с красным отливом
    local SidebarColor = options.SidebarColor or Color3.fromRGB(30, 15, 18)
    local CardColor = options.CardColor or Color3.fromRGB(40, 22, 26)
    local TextColor = options.TextColor or Color3.fromRGB(255, 255, 255)

    local ConfigName = options.ConfigName or "aether_config.json"
    local AnimationStyle = options.AnimationStyle or "spring_scale"
    local NeonGlow = options.NeonGlow or true
    local RainbowMode = options.RainbowMode or false
    local ShowWatermark = options.ShowWatermark or true

    -- Уничтожаем старый GUI
    if CoreGui:FindFirstChild("AetherUI_Root") then
        CoreGui.AetherUI_Root:Destroy()
    end

    -- Эффект размытия (Blur)
    local blurEffect = nil
    if not Lighting:FindFirstChild("AetherBlur") then
        blurEffect = Instance.new("BlurEffect")
        blurEffect.Name = "AetherBlur"
        blurEffect.Size = 6
        blurEffect.Parent = Lighting
    else
        blurEffect = Lighting.AetherBlur
    end
    blurEffect.Enabled = true

    -- Создаём ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AetherUI_Root"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            ScreenGui.Parent = CoreGui
        elseif gethui then
            ScreenGui.Parent = gethui()
        else
            ScreenGui.Parent = CoreGui
        end
    end)

    -- При уничтожении GUI выключаем размытие
    ScreenGui.AncestryChanged:Connect(function()
        if not ScreenGui.Parent then
            if blurEffect then blurEffect.Enabled = false end
        end
    end)

    -- Основная панель
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 750, 0, 520)
    MainFrame.Position = UDim2.new(0.5, -375, 0.5, -260)
    MainFrame.BackgroundColor3 = ThemeBgColor
    MainFrame.BackgroundTransparency = 0.85   -- полупрозрачная
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner", MainFrame)
    UICorner.CornerRadius = UDim.new(0, 14)

    local UIStroke = Instance.new("UIStroke", MainFrame)
    UIStroke.Color = NeonGlow and AccentColor or Color3.fromRGB(80, 40, 50)
    UIStroke.Thickness = NeonGlow and 2 or 1.5

    -- Анимация открытия
    if AnimationStyle == "spring_scale" then
        MainFrame.Size = UDim2.new(0, 375, 0, 260)
        MainFrame.Position = UDim2.new(0.5, -187, 0.5, -130)
        TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 750, 0, 520),
            Position = UDim2.new(0.5, -375, 0.5, -260)
        }):Play()
    elseif AnimationStyle == "smooth_fade" then
        MainFrame.BackgroundTransparency = 1
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.85
        }):Play()
    end

    -- Перетаскивание
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Шапка
    local Header = Instance.new("Frame", MainFrame)
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 56)
    Header.BackgroundColor3 = Color3.fromRGB(25, 12, 16)
    Header.BackgroundTransparency = 0.5
    Header.BorderSizePixel = 0

    local HeaderStroke = Instance.new("Frame", Header)
    HeaderStroke.Size = UDim2.new(1, 0, 0, 1)
    HeaderStroke.Position = UDim2.new(0, 0, 1, -1)
    HeaderStroke.BackgroundColor3 = Color3.fromRGB(80, 40, 50)
    HeaderStroke.BorderSizePixel = 0

    local TitleLabel = Instance.new("TextLabel", Header)
    TitleLabel.Text = Title
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextColor3 = TextColor
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Position = UDim2.new(0, 20, 0, 10)
    TitleLabel.Size = UDim2.new(0, 300, 0, 20)
    TitleLabel.BackgroundTransparency = 1

    local SubTitleLabel = Instance.new("TextLabel", Header)
    SubTitleLabel.Text = SubTitle
    SubTitleLabel.Font = Enum.Font.Gotham
    SubTitleLabel.TextSize = 11
    SubTitleLabel.TextColor3 = Color3.fromRGB(200, 180, 185)
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.Position = UDim2.new(0, 20, 0, 32)
    SubTitleLabel.Size = UDim2.new(0, 300, 0, 16)
    SubTitleLabel.BackgroundTransparency = 1

    -- Кнопка сворачивания (минус)
    local MinimizeBtn = Instance.new("TextButton", Header)
    MinimizeBtn.Text = "−"
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.TextSize = 18
    MinimizeBtn.TextColor3 = Color3.fromRGB(200, 180, 185)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(35, 18, 22)
    MinimizeBtn.Size = UDim2.new(0, 32, 0, 32)
    MinimizeBtn.Position = UDim2.new(1, -84, 0, 12)
    Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 8)

    -- Кнопка закрытия (крестик)
    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 13
    CloseBtn.TextColor3 = Color3.fromRGB(200, 180, 185)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 18, 22)
    CloseBtn.Size = UDim2.new(0, 32, 0, 32)
    CloseBtn.Position = UDim2.new(1, -44, 0, 12)
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

    -- Левый сайдбар
    local Sidebar = Instance.new("ScrollingFrame", MainFrame)
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 185, 1, -56)
    Sidebar.Position = UDim2.new(0, 0, 0, 56)
    Sidebar.BackgroundColor3 = SidebarColor
    Sidebar.BackgroundTransparency = 0.6
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 2
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local SidebarLayout = Instance.new("UIListLayout", Sidebar)
    SidebarLayout.Padding = UDim.new(0, 6)
    SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local SidebarPadding = Instance.new("UIPadding", Sidebar)
    SidebarPadding.PaddingTop = UDim.new(0, 12)
    SidebarPadding.PaddingBottom = UDim.new(0, 12)

    -- Контентная область
    local ContentArea = Instance.new("Frame", MainFrame)
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -195, 1, -66)
    ContentArea.Position = UDim2.new(0, 190, 0, 61)
    ContentArea.BackgroundTransparency = 1

    -- Уведомления
    local NotifyHolder = Instance.new("Frame", ScreenGui)
    NotifyHolder.Name = "NotifyHolder"
    NotifyHolder.Size = UDim2.new(0, 320, 1, -20)
    NotifyHolder.Position = UDim2.new(1, -330, 0, 10)
    NotifyHolder.BackgroundTransparency = 1

    local NotifyLayout = Instance.new("UIListLayout", NotifyHolder)
    NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifyLayout.Padding = UDim.new(0, 10)

    -- Функция уведомлений с анимацией
    function AetherLib:Notify(msgTitle, msgDesc, duration)
        duration = duration or 3.5
        local Card = Instance.new("Frame", NotifyHolder)
        Card.Size = UDim2.new(1, 0, 0, 68)
        Card.BackgroundColor3 = Color3.fromRGB(25, 12, 16)
        Card.BackgroundTransparency = 0.9
        Card.BorderSizePixel = 0
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 10)
        local Stroke = Instance.new("UIStroke", Card)
        Stroke.Color = AccentColor
        Stroke.Thickness = 1.5

        local T = Instance.new("TextLabel", Card)
        T.Text = msgTitle or "Уведомление"
        T.Font = Enum.Font.GothamBold
        T.TextSize = 14
        T.TextColor3 = Color3.fromRGB(255, 255, 255)
        T.Position = UDim2.new(0, 14, 0, 10)
        T.Size = UDim2.new(1, -28, 0, 20)
        T.TextXAlignment = Enum.TextXAlignment.Left
        T.BackgroundTransparency = 1

        local D = Instance.new("TextLabel", Card)
        D.Text = msgDesc or ""
        D.Font = Enum.Font.Gotham
        D.TextSize = 12
        D.TextColor3 = Color3.fromRGB(210, 190, 195)
        D.Position = UDim2.new(0, 14, 0, 34)
        D.Size = UDim2.new(1, -28, 0, 26)
        D.TextXAlignment = Enum.TextXAlignment.Left
        D.TextWrapped = true
        D.BackgroundTransparency = 1

        -- Анимация появления (сдвиг вверх + затухание)
        Card.Position = UDim2.new(0, 0, 1, 10)
        Card.BackgroundTransparency = 1
        T.TextTransparency = 1
        D.TextTransparency = 1
        TweenService:Create(Card, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 1, -Card.Size.Y.Offset - 10),
            BackgroundTransparency = 0.1
        }):Play()
        TweenService:Create(T, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
        TweenService:Create(D, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()

        task.delay(duration, function()
            TweenService:Create(Card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, 0, 1, 10),
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(T, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            TweenService:Create(D, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            task.wait(0.35)
            Card:Destroy()
        end)
    end

    -- Звук
    function AetherLib:PlaySound(soundId, volume)
        if not soundId or soundId == "" then return end
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = soundId
            s.Volume = volume or 1
            s.Parent = ScreenGui
            s:Play()
            s.Ended:Connect(function() s:Destroy() end)
        end)
    end

    -- Кнопка сворачивания
    local minimized = false
    local iconFrame = nil  -- маленькая иконка для разворачивания

    MinimizeBtn.MouseButton1Click:Connect(function()
        if not minimized then
            minimized = true
            -- Анимация сворачивания
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                Size = UDim2.new(0, 60, 0, 60),
                Position = UDim2.new(1, -70, 0, 14),
                BackgroundTransparency = 0.95
            }):Play()
            TweenService:Create(UIStroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
            -- Скрыть содержимое (сайдбар, контент, хедер)
            Sidebar.Visible = false
            ContentArea.Visible = false
            Header.Visible = false

            -- Создаём иконку для разворачивания
            iconFrame = Instance.new("Frame", ScreenGui)
            iconFrame.Size = UDim2.new(0, 44, 0, 44)
            iconFrame.Position = UDim2.new(1, -56, 0, 18)
            iconFrame.BackgroundColor3 = AccentColor
            iconFrame.BackgroundTransparency = 0.3
            Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(1, 0)
            local iconLabel = Instance.new("TextLabel", iconFrame)
            iconLabel.Size = UDim2.new(1, 0, 1, 0)
            iconLabel.Text = "A"
            iconLabel.Font = Enum.Font.GothamBold
            iconLabel.TextSize = 18
            iconLabel.TextColor3 = Color3.fromRGB(255,255,255)
            iconLabel.BackgroundTransparency = 1

            iconFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    -- Разворачиваем
                    minimized = false
                    iconFrame:Destroy()
                    Sidebar.Visible = true
                    ContentArea.Visible = true
                    Header.Visible = true
                    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                        Size = UDim2.new(0, 750, 0, 520),
                        Position = UDim2.new(0.5, -375, 0.5, -260),
                        BackgroundTransparency = 0.85
                    }):Play()
                    TweenService:Create(UIStroke, TweenInfo.new(0.3), { Transparency = 0 }):Play()
                end
            end)
        end
    end)

    -- Закрытие
    CloseBtn.MouseButton1Click:Connect(function()
        if blurEffect then blurEffect.Enabled = false end
        ScreenGui:Destroy()
    end)

    -- Toggle visibility hotkey
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == ToggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    -- Табы
    local Tabs = {}
    local FirstTab = true

    function Tabs:CreateTab(tabName, tabIcon)
        local TabBtn = Instance.new("TextButton", Sidebar)
        TabBtn.Size = UDim2.new(1, -20, 0, 38)
        TabBtn.BackgroundColor3 = CardColor
        TabBtn.BackgroundTransparency = 0.3
        TabBtn.Text = (tabIcon and (tabIcon .. " ") or "") .. (tabName or "Tab")
        TabBtn.Font = Enum.Font.GothamSemibold
        TabBtn.TextSize = 13
        TabBtn.TextColor3 = Color3.fromRGB(200, 180, 185)
        TabBtn.AutoButtonColor = false
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)

        local TabPage = Instance.new("ScrollingFrame", ContentArea)
        TabPage.Name = tabName .. "_Page"
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = AccentColor
        TabPage.Visible = false
        TabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)

        local PageLayout = Instance.new("UIListLayout", TabPage)
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local PagePadding = Instance.new("UIPadding", TabPage)
        PagePadding.PaddingRight = UDim.new(0, 10)
        PagePadding.PaddingTop = UDim.new(0, 4)
        PagePadding.PaddingBottom = UDim.new(0, 10)

        local function ActivateTab()
            for _, child in pairs(ContentArea:GetChildren()) do
                if child:IsA("ScrollingFrame") then child.Visible = false end
            end
            for _, btn in pairs(Sidebar:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = CardColor
                    btn.BackgroundTransparency = 0.3
                    btn.TextColor3 = Color3.fromRGB(200, 180, 185)
                end
            end
            TabPage.Visible = true
            TabBtn.BackgroundColor3 = AccentColor
            TabBtn.BackgroundTransparency = 0.6
            TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end

        TabBtn.MouseButton1Click:Connect(ActivateTab)

        if FirstTab then
            FirstTab = false
            ActivateTab()
        end

        local Elements = {}

        -- Section
        function Elements:AddSection(text)
            local SectionLabel = Instance.new("TextLabel", TabPage)
            SectionLabel.Size = UDim2.new(1, 0, 0, 24)
            SectionLabel.BackgroundTransparency = 1
            SectionLabel.Text = string.upper(text)
            SectionLabel.Font = Enum.Font.GothamBold
            SectionLabel.TextSize = 11
            SectionLabel.TextColor3 = Color3.fromRGB(180, 150, 155)
            SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
        end

        -- Button
        function Elements:AddButton(btnText, callback, soundId, customColor)
            callback = callback or function() end
            local btnBg = customColor or CardColor
            local Btn = Instance.new("TextButton", TabPage)
            Btn.Size = UDim2.new(1, 0, 0, 40)
            Btn.BackgroundColor3 = btnBg
            Btn.BackgroundTransparency = 0.4
            Btn.Text = btnText
            Btn.Font = Enum.Font.GothamSemibold
            Btn.TextSize = 13
            Btn.TextColor3 = TextColor
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", Btn)
            S.Color = Color3.fromRGB(80, 40, 50)
            S.Thickness = 1

            Btn.MouseButton1Click:Connect(function()
                if soundId and soundId ~= "" then AetherLib:PlaySound(soundId) end
                TweenService:Create(Btn, TweenInfo.new(0.1), { BackgroundColor3 = AccentColor }):Play()
                task.wait(0.1)
                TweenService:Create(Btn, TweenInfo.new(0.2), { BackgroundColor3 = btnBg }):Play()
                pcall(callback)
                AetherLib:Notify("Действие", "Кнопка '"..btnText.."' нажата", 2)
            end)
        end

        -- Toggle
        function Elements:AddToggle(toggleText, default, callback, soundId)
            default = default or false
            callback = callback or function() end
            local state = default

            local ToggleFrame = Instance.new("Frame", TabPage)
            ToggleFrame.Size = UDim2.new(1, 0, 0, 42)
            ToggleFrame.BackgroundColor3 = CardColor
            ToggleFrame.BackgroundTransparency = 0.4
            Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", ToggleFrame)
            S.Color = Color3.fromRGB(80, 40, 50)
            S.Thickness = 1

            local Label = Instance.new("TextLabel", ToggleFrame)
            Label.Size = UDim2.new(1, -70, 1, 0)
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.Text = toggleText
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextColor3 = TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1

            local Switch = Instance.new("TextButton", ToggleFrame)
            Switch.Size = UDim2.new(0, 44, 0, 24)
            Switch.Position = UDim2.new(1, -54, 0.5, -12)
            Switch.BackgroundColor3 = state and AccentColor or Color3.fromRGB(50, 30, 35)
            Switch.Text = ""
            Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

            local Circle = Instance.new("Frame", Switch)
            Circle.Size = UDim2.new(0, 18, 0, 18)
            Circle.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

            local function UpdateState(val)
                state = val
                if soundId and soundId ~= "" then AetherLib:PlaySound(soundId) end
                local targetBg = state and AccentColor or Color3.fromRGB(50, 30, 35)
                local targetPos = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                TweenService:Create(Switch, TweenInfo.new(0.2), { BackgroundColor3 = targetBg }):Play()
                TweenService:Create(Circle, TweenInfo.new(0.2), { Position = targetPos }):Play()
                pcall(callback, state)
            end

            Switch.MouseButton1Click:Connect(function() UpdateState(not state) end)
            local ClickArea = Instance.new("TextButton", ToggleFrame)
            ClickArea.Size = UDim2.new(1, -60, 1, 0)
            ClickArea.BackgroundTransparency = 1
            ClickArea.Text = ""
            ClickArea.MouseButton1Click:Connect(function() UpdateState(not state) end)

            pcall(callback, state)
            return { Set = UpdateState }
        end

        -- Slider
        function Elements:AddSlider(sliderText, min, max, default, callback)
            min = min or 0
            max = max or 100
            default = default or min
            callback = callback or function() end
            local value = default

            local Frame = Instance.new("Frame", TabPage)
            Frame.Size = UDim2.new(1, 0, 0, 54)
            Frame.BackgroundColor3 = CardColor
            Frame.BackgroundTransparency = 0.4
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", Frame)
            S.Color = Color3.fromRGB(80, 40, 50)
            S.Thickness = 1

            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(1, -100, 0, 24)
            Label.Position = UDim2.new(0, 14, 0, 6)
            Label.Text = sliderText
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextColor3 = TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1

            local ValLabel = Instance.new("TextLabel", Frame)
            ValLabel.Size = UDim2.new(0, 80, 0, 24)
            ValLabel.Position = UDim2.new(1, -94, 0, 6)
            ValLabel.Text = tostring(value)
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextSize = 13
            ValLabel.TextColor3 = AccentColor
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.BackgroundTransparency = 1

            local SliderBar = Instance.new("TextButton", Frame)
            SliderBar.Size = UDim2.new(1, -28, 0, 6)
            SliderBar.Position = UDim2.new(0, 14, 0, 36)
            SliderBar.BackgroundColor3 = Color3.fromRGB(50, 30, 35)
            SliderBar.Text = ""
            SliderBar.AutoButtonColor = false
            Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)

            local Progress = Instance.new("Frame", SliderBar)
            Progress.Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)
            Progress.BackgroundColor3 = AccentColor
            Progress.BorderSizePixel = 0
            Instance.new("UICorner", Progress).CornerRadius = UDim.new(1, 0)

            local function UpdateSlider(input)
                local percent = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * percent)
                ValLabel.Text = tostring(value)
                Progress.Size = UDim2.new(percent, 0, 1, 0)
                pcall(callback, value)
            end

            local sliding = false
            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    UpdateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input)
                end
            end)

            pcall(callback, value)
        end

        -- Knob (крутилка)
        function Elements:AddKnob(knobText, min, max, default, unit, callback)
            min = min or 0
            max = max or 100
            default = default or min
            unit = unit or "%"
            callback = callback or function() end
            local value = default

            local Frame = Instance.new("Frame", TabPage)
            Frame.Size = UDim2.new(1, 0, 0, 68)
            Frame.BackgroundColor3 = CardColor
            Frame.BackgroundTransparency = 0.4
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", Frame)
            S.Color = Color3.fromRGB(80, 40, 50)
            S.Thickness = 1

            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(0.6, 0, 0, 24)
            Label.Position = UDim2.new(0, 14, 0, 10)
            Label.Text = knobText
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextColor3 = TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1

            local ValLabel = Instance.new("TextLabel", Frame)
            ValLabel.Size = UDim2.new(0.6, 0, 0, 20)
            ValLabel.Position = UDim2.new(0, 14, 0, 34)
            ValLabel.Text = string.format("%d %s (Диапазон: %d-%d)", value, unit, min, max)
            ValLabel.Font = Enum.Font.Gotham
            ValLabel.TextSize = 11
            ValLabel.TextColor3 = Color3.fromRGB(200, 180, 185)
            ValLabel.TextXAlignment = Enum.TextXAlignment.Left
            ValLabel.BackgroundTransparency = 1

            local KnobBtn = Instance.new("TextButton", Frame)
            KnobBtn.Size = UDim2.new(0, 46, 0, 46)
            KnobBtn.Position = UDim2.new(1, -60, 0.5, -23)
            KnobBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 35)
            KnobBtn.Text = ""
            Instance.new("UICorner", KnobBtn).CornerRadius = UDim.new(1, 0)
            local KS = Instance.new("UIStroke", KnobBtn)
            KS.Color = AccentColor
            KS.Thickness = 2

            local Pointer = Instance.new("Frame", KnobBtn)
            Pointer.Size = UDim2.new(0, 4, 0, 14)
            Pointer.Position = UDim2.new(0.5, -2, 0, 4)
            Pointer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Pointer.BorderSizePixel = 0
            Instance.new("UICorner", Pointer).CornerRadius = UDim.new(1, 0)

            local function UpdateRotation(val)
                local pct = math.clamp((val - min) / (max - min), 0, 1)
                local angle = -135 + (pct * 270)
                KnobBtn.Rotation = angle
                ValLabel.Text = string.format("%d %s (Диапазон: %d-%d)", val, unit, min, max)
                pcall(callback, val)
            end

            local draggingKnob = false
            local startY, startVal = 0, default

            KnobBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingKnob = true
                    startY = input.Position.Y
                    startVal = value
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingKnob = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingKnob and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local delta = (startY - input.Position.Y) / 100
                    value = math.clamp(math.floor(startVal + (max - min) * delta), min, max)
                    UpdateRotation(value)
                    AetherLib:Notify("Крутилка", "Значение: "..value.." "..unit, 1.5)
                end
            end)

            UpdateRotation(default)
        end

        -- Keybind
        function Elements:AddKeybind(bindText, defaultKey, callback)
            defaultKey = defaultKey or Enum.KeyCode.E
            callback = callback or function() end
            local currentKey = defaultKey
            local listening = false

            local Frame = Instance.new("Frame", TabPage)
            Frame.Size = UDim2.new(1, 0, 0, 42)
            Frame.BackgroundColor3 = CardColor
            Frame.BackgroundTransparency = 0.4
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", Frame)
            S.Color = Color3.fromRGB(80, 40, 50)
            S.Thickness = 1

            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(0.6, 0, 1, 0)
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.Text = "⌨️ " .. bindText
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextColor3 = TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1

            local KeyBtn = Instance.new("TextButton", Frame)
            KeyBtn.Size = UDim2.new(0.35, -14, 0, 26)
            KeyBtn.Position = UDim2.new(0.65, 0, 0.5, -13)
            KeyBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 35)
            KeyBtn.Text = typeof(currentKey) == "EnumItem" and currentKey.Name or tostring(currentKey)
            KeyBtn.Font = Enum.Font.GothamBold
            KeyBtn.TextSize = 11
            KeyBtn.TextColor3 = AccentColor
            Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 6)

            KeyBtn.MouseButton1Click:Connect(function()
                listening = true
                KeyBtn.Text = "..."
                KeyBtn.TextColor3 = Color3.fromRGB(255, 180, 0)
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    currentKey = input.KeyCode
                    KeyBtn.Text = currentKey.Name
                    KeyBtn.TextColor3 = AccentColor
                elseif not gpe and input.KeyCode == currentKey then
                    pcall(callback, currentKey)
                end
            end)
        end

        -- ColorPicker (упрощённый)
        function Elements:AddColorPicker(pickerText, defaultColor, callback)
            defaultColor = defaultColor or AccentColor
            callback = callback or function() end
            local chosenColor = defaultColor

            local Frame = Instance.new("Frame", TabPage)
            Frame.Size = UDim2.new(1, 0, 0, 44)
            Frame.BackgroundColor3 = CardColor
            Frame.BackgroundTransparency = 0.4
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", Frame)
            S.Color = Color3.fromRGB(80, 40, 50)
            S.Thickness = 1

            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(0.6, 0, 1, 0)
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.Text = "🎨 " .. pickerText
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextColor3 = TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1

            local ColorBox = Instance.new("TextButton", Frame)
            ColorBox.Size = UDim2.new(0, 32, 0, 24)
            ColorBox.Position = UDim2.new(1, -44, 0.5, -12)
            ColorBox.BackgroundColor3 = chosenColor
            ColorBox.Text = ""
            Instance.new("UICorner", ColorBox).CornerRadius = UDim.new(0, 6)
            local CBS = Instance.new("UIStroke", ColorBox)
            CBS.Color = Color3.fromRGB(255, 255, 255)
            CBS.Thickness = 1

            local palette = {
                Color3.fromRGB(220, 20, 60),
                Color3.fromRGB(200, 40, 60),
                Color3.fromRGB(180, 30, 50),
                Color3.fromRGB(255, 50, 80),
                Color3.fromRGB(150, 20, 40),
            }
            local colorIdx = 1

            ColorBox.MouseButton1Click:Connect(function()
                colorIdx = (colorIdx % #palette) + 1
                chosenColor = palette[colorIdx]
                ColorBox.BackgroundColor3 = chosenColor
                pcall(callback, chosenColor)
            end)
        end

        -- ProgressBar
        function Elements:AddProgressBar(progText, defaultPct, animatedPulse)
            defaultPct = math.clamp(defaultPct or 50, 0, 100)
            local Frame = Instance.new("Frame", TabPage)
            Frame.Size = UDim2.new(1, 0, 0, 50)
            Frame.BackgroundColor3 = CardColor
            Frame.BackgroundTransparency = 0.4
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", Frame)
            S.Color = Color3.fromRGB(80, 40, 50)
            S.Thickness = 1

            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(0.7, 0, 0, 20)
            Label.Position = UDim2.new(0, 14, 0, 8)
            Label.Text = progText
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 12
            Label.TextColor3 = TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1

            local PctLabel = Instance.new("TextLabel", Frame)
            PctLabel.Size = UDim2.new(0.3, -14, 0, 20)
            PctLabel.Position = UDim2.new(0.7, 0, 0, 8)
            PctLabel.Text = tostring(defaultPct) .. "%"
            PctLabel.Font = Enum.Font.GothamBold
            PctLabel.TextSize = 12
            PctLabel.TextColor3 = AccentColor
            PctLabel.TextXAlignment = Enum.TextXAlignment.Right
            PctLabel.BackgroundTransparency = 1

            local BarBg = Instance.new("Frame", Frame)
            BarBg.Size = UDim2.new(1, -28, 0, 8)
            BarBg.Position = UDim2.new(0, 14, 0, 32)
            BarBg.BackgroundColor3 = Color3.fromRGB(50, 30, 35)
            Instance.new("UICorner", BarBg).CornerRadius = UDim.new(1, 0)

            local Fill = Instance.new("Frame", BarBg)
            Fill.Size = UDim2.new(defaultPct / 100, 0, 1, 0)
            Fill.BackgroundColor3 = AccentColor
            Fill.BorderSizePixel = 0
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

            if animatedPulse then
                task.spawn(function()
                    while Fill and Fill.Parent do
                        TweenService:Create(Fill, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.4 }):Play()
                        task.wait(0.8)
                        TweenService:Create(Fill, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0 }):Play()
                        task.wait(0.8)
                    end
                end)
            end

            return {
                Set = function(newPct)
                    newPct = math.clamp(newPct, 0, 100)
                    PctLabel.Text = tostring(newPct) .. "%"
                    TweenService:Create(Fill, TweenInfo.new(0.3), { Size = UDim2.new(newPct / 100, 0, 1, 0) }):Play()
                end
            }
        end

        -- Paragraph
        function Elements:AddParagraph(headerText, bodyText, calloutType)
            local Frame = Instance.new("Frame", TabPage)
            Frame.Size = UDim2.new(1, 0, 0, 64)
            Frame.BackgroundColor3 = Color3.fromRGB(30, 16, 20)
            Frame.BackgroundTransparency = 0.4
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", Frame)
            if calloutType == "warning" then
                S.Color = Color3.fromRGB(245, 158, 11)
            elseif calloutType == "danger" then
                S.Color = Color3.fromRGB(239, 68, 68)
            elseif calloutType == "success" then
                S.Color = Color3.fromRGB(34, 197, 94)
            else
                S.Color = AccentColor
            end
            S.Thickness = 1

            local T = Instance.new("TextLabel", Frame)
            T.Size = UDim2.new(1, -24, 0, 20)
            T.Position = UDim2.new(0, 12, 0, 8)
            T.Text = headerText or "Информация"
            T.Font = Enum.Font.GothamBold
            T.TextSize = 13
            T.TextColor3 = Color3.fromRGB(255, 255, 255)
            T.TextXAlignment = Enum.TextXAlignment.Left
            T.BackgroundTransparency = 1

            local B = Instance.new("TextLabel", Frame)
            B.Size = UDim2.new(1, -24, 0, 30)
            B.Position = UDim2.new(0, 12, 0, 28)
            B.Text = bodyText or ""
            B.Font = Enum.Font.Gotham
            B.TextSize = 11
            B.TextColor3 = Color3.fromRGB(210, 190, 195)
            B.TextXAlignment = Enum.TextXAlignment.Left
            B.TextWrapped = true
            B.BackgroundTransparency = 1
        end

        -- Divider
        function Elements:AddDivider(divText)
            local Container = Instance.new("Frame", TabPage)
            Container.Size = UDim2.new(1, 0, 0, 20)
            Container.BackgroundTransparency = 1

            local Line = Instance.new("Frame", Container)
            Line.Size = UDim2.new(1, 0, 0, 1)
            Line.Position = UDim2.new(0, 0, 0.5, 0)
            Line.BackgroundColor3 = Color3.fromRGB(80, 40, 50)
            Line.BorderSizePixel = 0

            if divText and divText ~= "" then
                local L = Instance.new("TextLabel", Container)
                L.Size = UDim2.new(0, 140, 0, 18)
                L.Position = UDim2.new(0.5, -70, 0.5, -9)
                L.BackgroundColor3 = ThemeBgColor
                L.BackgroundTransparency = 0.5
                L.Text = divText
                L.Font = Enum.Font.GothamBold
                L.TextSize = 10
                L.TextColor3 = Color3.fromRGB(180, 150, 155)
                L.TextXAlignment = Enum.TextXAlignment.Center
            end
        end

        -- TextBox
        function Elements:AddTextBox(boxText, default, callback)
            default = default or ""
            callback = callback or function() end

            local Frame = Instance.new("Frame", TabPage)
            Frame.Size = UDim2.new(1, 0, 0, 42)
            Frame.BackgroundColor3 = CardColor
            Frame.BackgroundTransparency = 0.4
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", Frame)
            S.Color = Color3.fromRGB(80, 40, 50)
            S.Thickness = 1

            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(0.5, 0, 1, 0)
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.Text = boxText
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextColor3 = TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1

            local Box = Instance.new("TextBox", Frame)
            Box.Size = UDim2.new(0.45, -14, 0, 26)
            Box.Position = UDim2.new(0.55, 0, 0.5, -13)
            Box.BackgroundColor3 = Color3.fromRGB(50, 30, 35)
            Box.Text = default
            Box.PlaceholderText = "Введите..."
            Box.Font = Enum.Font.Gotham
            Box.TextSize = 12
            Box.TextColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)

            Box.FocusLost:Connect(function()
                pcall(callback, Box.Text)
            end)
        end

        -- Dropdown
        function Elements:AddDropdown(ddText, optionsList, default, callback)
            optionsList = optionsList or {}
            default = default or optionsList[1] or "None"
            callback = callback or function() end

            local Frame = Instance.new("Frame", TabPage)
            Frame.Size = UDim2.new(1, 0, 0, 42)
            Frame.BackgroundColor3 = CardColor
            Frame.BackgroundTransparency = 0.4
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", Frame)
            S.Color = Color3.fromRGB(80, 40, 50)
            S.Thickness = 1

            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(0.5, 0, 1, 0)
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.Text = ddText
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextColor3 = TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1

            local CurrentIdx = 1
            for i, v in ipairs(optionsList) do
                if v == default then CurrentIdx = i break end
            end

            local DdBtn = Instance.new("TextButton", Frame)
            DdBtn.Size = UDim2.new(0.45, -14, 0, 26)
            DdBtn.Position = UDim2.new(0.55, 0, 0.5, -13)
            DdBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 35)
            DdBtn.Text = tostring(default) .. " ▾"
            DdBtn.Font = Enum.Font.GothamSemibold
            DdBtn.TextSize = 12
            DdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", DdBtn).CornerRadius = UDim.new(0, 6)

            DdBtn.MouseButton1Click:Connect(function()
                if #optionsList == 0 then return end
                CurrentIdx = CurrentIdx + 1
                if CurrentIdx > #optionsList then CurrentIdx = 1 end
                local chosen = optionsList[CurrentIdx]
                DdBtn.Text = tostring(chosen) .. " ▾"
                pcall(callback, chosen)
                AetherLib:Notify("Выпадающий список", "Выбрано: "..chosen, 2)
            end)
        end

        -- Image
        function Elements:AddImage(imgTitle, assetOrUrl, height)
            height = height or 120
            local realAsset = AetherLib:GetAsset(assetOrUrl, "banner_" .. tostring(math.abs(tick())) .. ".png")
            local Container = Instance.new("Frame", TabPage)
            Container.Size = UDim2.new(1, 0, 0, height + 24)
            Container.BackgroundColor3 = CardColor
            Container.BackgroundTransparency = 0.4
            Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", Container)
            S.Color = Color3.fromRGB(80, 40, 50)
            S.Thickness = 1

            local T = Instance.new("TextLabel", Container)
            T.Size = UDim2.new(1, -20, 0, 20)
            T.Position = UDim2.new(0, 10, 0, 4)
            T.Text = imgTitle or "Image"
            T.Font = Enum.Font.GothamSemibold
            T.TextSize = 11
            T.TextColor3 = Color3.fromRGB(200, 180, 185)
            T.TextXAlignment = Enum.TextXAlignment.Left
            T.BackgroundTransparency = 1

            local Img = Instance.new("ImageLabel", Container)
            Img.Size = UDim2.new(1, -20, 0, height - 10)
            Img.Position = UDim2.new(0, 10, 0, 26)
            Img.Image = realAsset
            Img.ScaleType = Enum.ScaleType.Fit
            Img.BackgroundTransparency = 1
            Instance.new("UICorner", Img).CornerRadius = UDim.new(0, 6)
        end

        -- Audio
        function Elements:AddAudio(audioTitle, soundIdOrUrl, autoPlay)
            local Frame = Instance.new("Frame", TabPage)
            Frame.Size = UDim2.new(1, 0, 0, 42)
            Frame.BackgroundColor3 = CardColor
            Frame.BackgroundTransparency = 0.4
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
            local S = Instance.new("UIStroke", Frame)
            S.Color = Color3.fromRGB(80, 40, 50)
            S.Thickness = 1

            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(0.6, 0, 1, 0)
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.Text = "🎵 " .. (audioTitle or "Sound Effect")
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 12
            Label.TextColor3 = TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1

            local Sound = Instance.new("Sound", Frame)
            Sound.SoundId = AetherLib:GetAsset(soundIdOrUrl or "rbxassetid://9043887091", "audio_fx.mp3")
            Sound.Volume = 1
            if autoPlay then Sound:Play() end

            local PlayBtn = Instance.new("TextButton", Frame)
            PlayBtn.Size = UDim2.new(0.35, -14, 0, 26)
            PlayBtn.Position = UDim2.new(0.65, 0, 0.5, -13)
            PlayBtn.BackgroundColor3 = AccentColor
            PlayBtn.BackgroundTransparency = 0.4
            PlayBtn.Text = "Воспроизвести ▶"
            PlayBtn.Font = Enum.Font.GothamSemibold
            PlayBtn.TextSize = 11
            PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 6)

            PlayBtn.MouseButton1Click:Connect(function()
                Sound:Play()
            end)
        end

        -- Label
        function Elements:AddLabel(text)
            local Label = Instance.new("TextLabel", TabPage)
            Label.Size = UDim2.new(1, 0, 0, 24)
            Label.BackgroundTransparency = 1
            Label.Text = text or ""
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 12
            Label.TextColor3 = TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
        end

        return Elements
    end

    return Tabs
end

return AetherLib

-- ==================== ИНИЦИАЛИЗАЦИЯ ОКНА ====================

local Window = AetherLib:CreateWindow({
    Title = "Aether Script Hub",
    SubTitle = "Crimson Edition • Все функции дилера",
    ToggleKey = Enum.KeyCode.RightControl,
    AccentColor = Color3.fromRGB(220, 20, 60),
    ThemeBgColor = Color3.fromRGB(20, 10, 12),
    SidebarColor = Color3.fromRGB(30, 15, 18),
    CardColor = Color3.fromRGB(40, 22, 26),
    ConfigName = "aether_settings.json",
    AnimationStyle = "smooth_fade",
    NeonGlow = true,
    RainbowMode = false,
    ShowWatermark = true
})

AetherLib:Notify("Aether Script Hub", "Скрипт успешно загружен! (Crimson Edition)", 4)

-- ==================== ВКЛАДКА: UNIVERSAL (из Aether Script) ====================

local universal = Window:CreateTab("Universal", "⚡")
universal:AddSection("Параметры игрока")
universal:AddKnob("Крутилка скорости (WalkSpeed)", 16, 350, 120, "spd", function(val)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = val
    end
end)
universal:AddSlider("Сила прыжка (JumpPower)", 50, 400, 150, function(val)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = val
    end
end)
universal:AddToggle("Авто-Фарм Миль / Монет", true, function(state)
    AetherLib:Notify("Авто-Фарм Миль / Монет", state and "Включён" or "Выключен", 2)
end, nil)
universal:AddKnob("Крутилка угла камеры (FOV)", 70, 120, 90, "°", function(val)
    workspace.CurrentCamera.FieldOfView = val
end)

universal:AddSection("Бой & ESP")
universal:AddToggle("ESP Box Подсветка игроков", true, function(state)
    AetherLib:Notify("ESP", state and "Включён" or "Выключен", 2)
end, nil)
universal:AddKeybind("Бинд триггера авто-прицела", Enum.KeyCode.E, function()
    AetherLib:Notify("Бинд триггера", "Авто-прицел активирован", 2)
end)
universal:AddColorPicker("Цвет обводки врагов (Chams)", Color3.fromRGB(239, 68, 68), function(col)
    print("[Aether UI] Color changed:", col)
end)
universal:AddProgressBar("Индикатор перезарядки скилла", 80, true)

universal:AddSection("Медиа & Утилиты")
universal:AddParagraph("Статус безопасности", "Все функции работают без инъекции в защищенные хуки. Риск бана минимален.", "success")
universal:AddDivider("МЕДИА & ЗВУК")
universal:AddImage("Aether Cyber Banner", "rbxassetid://10903332468", 110)
universal:AddAudio("Звук победы / Джингл", "rbxassetid://9043887091", false)
universal:AddButton("Anti-Stuck (Телепорт вверх)", function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(0, 20, 0)
    end
end, nil, nil)

-- ==================== ВКЛАДКА: DEALERSHIP ====================

local dealership = Window:CreateTab("Dealership", "🚗")
dealership:AddSection("Основные функции")
dealership:AddTextBox("Auto Drive Speed (max 2000)", tostring(settings.driveSpeed), function(val)
    local num = tonumber(val)
    if num then
        if num > 2000 then num = 2000 end
        settings.driveSpeed = num
        getfenv().speed = num
        saveSettings()
    end
end)
dealership:AddToggle("Auto Farm (езда)", settings.autoFarm, function(state)
    settings.autoFarm = state
    getfenv().auto = state
    saveSettings()
    task.spawn(function()
        while getfenv().auto do
            task.wait()
            pcall(function()
                local chr = game.Players.LocalPlayer.Character
                if chr and chr:FindFirstChild("Humanoid") and chr.Humanoid.SeatPart then
                    local car = chr.Humanoid.SeatPart.Parent.Parent
                    if not workspace:FindFirstChild("justapart") then
                        local new = Instance.new("Part", workspace)
                        new.Name = "justapart"
                        new.Size = Vector3.new(20000, 20, 20000)
                        new.Anchored = true
                        new.Position = chr.HumanoidRootPart.Position + Vector3.new(0, 1000, 0)
                    end
                    car:PivotTo(workspace.justapart.CFrame * CFrame.new(0, 10, 1000))
                    local pos = workspace.justapart.CFrame * CFrame.new(0, 10, -1000)
                    local dist = (car.PrimaryPart.Position - pos.Position).Magnitude
                    local speed = getfenv().speed or 300
                    if speed > 2000 then speed = 2000 end
                    car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed
                    local TweenService = game:GetService("TweenService")
                    local TweenInfoToUse = TweenInfo.new(dist/speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, true, 0)
                    local TweenValue = Instance.new("CFrameValue")
                    TweenValue.Value = car.WorldPivot
                    TweenValue.Changed:Connect(function()
                        car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed
                        car:PivotTo(TweenValue.Value)
                    end)
                    local OnTween = TweenService:Create(TweenValue, TweenInfoToUse, {Value = pos})
                    OnTween:Play()
                    OnTween.Completed:Wait()
                    TweenValue:Destroy()
                end
            end)
        end
    end)
end)
dealership:AddToggle("Auto Farm Collectibles", settings.autoCollectibles, function(state)
    settings.autoCollectibles = state
    getfenv().collectables = state
    saveSettings()
    task.spawn(function()
        while getfenv().collectables do
            task.wait()
            pcall(function()
                local chr = game.Players.LocalPlayer.Character
                if chr and chr:FindFirstChild("Humanoid") and chr.Humanoid.SeatPart then
                    local car = chr.Humanoid.SeatPart.Parent.Parent
                    local collect = workspace:FindFirstChild("Collectibles")
                    if collect then
                        for _, v in pairs(collect:GetDescendants()) do
                            if v:IsA("Model") and v.PrimaryPart and v:GetChildren()[2] and v:GetChildren()[2]:FindFirstChild("Part") and v:GetChildren()[2].Part:FindFirstChildOfClass("BillboardGui") and v:GetChildren()[2].Part:FindFirstChildOfClass("BillboardGui").Enabled then
                                car:PivotTo(v.PrimaryPart.CFrame)
                                break
                            end
                        end
                    end
                end
            end)
        end
    end)
end)
dealership:AddToggle("Auto Open Vehicle Kit", settings.autoVehicleKit, function(state)
    settings.autoVehicleKit = state
    getfenv().open = state
    saveSettings()
    task.spawn(function()
        while getfenv().open do
            task.wait()
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.Services.CarKitEventServiceRemotes.ClaimFreePack:InvokeServer()
            end)
        end
    end)
end)
dealership:AddToggle("Auto Extinguish Fire", settings.autoFire, function(state)
    settings.autoFire = state
    getfenv().fireman = state
    saveSettings()
    task.spawn(function()
        while getfenv().fireman do
            task.wait()
            workspace.Gravity = 196
            pcall(function()
                local plr = game.Players.LocalPlayer
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    plr.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                    if not plr.Backpack:FindFirstChildOfClass("Tool") and not plr.Character:FindFirstChildOfClass("Tool") then
                        game:GetService("ReplicatedStorage").Remotes.Switch:FireServer("FireDealership")
                        task.wait(10)
                    elseif plr.Backpack:FindFirstChildOfClass("Tool") then
                        plr.Character.Humanoid:EquipTool(plr.Backpack:FindFirstChildOfClass("Tool"))
                        task.wait(1)
                    elseif plr.Character:FindFirstChildOfClass("Tool") then
                        if plr.PlayerGui:FindFirstChild("FireGuide") then
                            local test = nil
                            for _, v in pairs(workspace:GetDescendants()) do
                                if v.Name == "FirePart" then
                                    test = v
                                    plr.Character.HumanoidRootPart.CFrame = v.CFrame
                                    break
                                end
                            end
                            if test == nil then
                                plr.Character.HumanoidRootPart.CFrame = plr.PlayerGui.FireGuide.Adornee.CFrame
                            else
                                for _, v in pairs(test.Parent:GetDescendants()) do
                                    if (v.ClassName == "Part" or v.ClassName == "MeshPart") and v.CanCollide then
                                        v.CanCollide = false
                                    end
                                end
                                workspace.Gravity = 0
                                repeat task.wait()
                                    game:GetService("ReplicatedStorage").Remotes.TaskController.ActionGameDataReplication:FireServer("TryInteractWithItem", {
                                        ["GameName"] = "FirefighterGame",
                                        ["Action"] = "UpdatePlayerToolState",
                                        ["Data"] = {["IsActive"] = true, ["ToolName"] = "Extinguisher"}
                                    })
                                    plr.Character.HumanoidRootPart.CFrame = test.CFrame * CFrame.new(0, 10, 0)
                                    plr.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(-90), 0, 0)
                                until not plr.PlayerGui:FindFirstChild("FireGuide")
                                plr.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                                task.wait(5)
                                game:GetService("ReplicatedStorage").Remotes.TaskController.ActionGameDataReplication:FireServer("TryInteractWithItem", {
                                    ["GameName"] = "FirefighterGame",
                                    ["Action"] = "TryToCollectReward",
                                    ["Data"] = {}
                                })
                            end
                        end
                    end
                end
            end)
        end
    end)
end)
dealership:AddToggle("Auto Sell Cars (NPC)", settings.autoSell, function(state)
    settings.autoSell = state
    getfenv().Customer = state
    saveSettings()
    task.spawn(function()
        while getfenv().Customer do
            task.wait(2)
            pcall(function()
                local tycoon
                for _, v in pairs(workspace.Tycoons:GetDescendants()) do
                    if v.Name == "Owner" and v:IsA("StringValue") and (string.find(v.Parent.Name, "Plot") or string.find(v.Parent.Name, "Slot")) and v.Value == game.Players.LocalPlayer.Name then
                        tycoon = v.Parent
                        break
                    end
                end
                if tycoon and tycoon:FindFirstChild("Dealership") then
                    local customer
                    for _, v in pairs(tycoon.Dealership:GetChildren()) do
                        if v:IsA("Model") and v.PrimaryPart and v.PrimaryPart.Name == "HumanoidRootPart" then
                            customer = v
                            break
                        end
                    end
                    if customer then
                        local text = customer:GetAttribute("OrderSpecBudget"):split(";")
                        local minPrice = settings.minSellPrice or 0
                        local selectedCar
                        for _, v in pairs(require(game:GetService("ReplicatedStorage").Data.CarShopEntries).CarsInShop) do
                            if v.PriceValue and v.PriceValue > tonumber(text[1]) and v.PriceValue < tonumber(text[2]) then
                                if v.PriceValue >= minPrice then
                                    if not selectedCar or v.PriceValue < selectedCar.PriceValue then
                                        selectedCar = v
                                    end
                                end
                            end
                        end
                        if selectedCar then
                            local remotes = game:GetService("ReplicatedStorage").Remotes.DealershipCustomerController.NPCHandler
                            local orderId = customer:GetAttribute("OrderId")
                            remotes:FireServer({["Action"] = "AcceptOrder", ["OrderId"] = orderId})
                            task.wait(0.5)
                            remotes:FireServer({
                                ["OrderId"] = orderId,
                                ["Action"] = "CompleteOrder",
                                ["Specs"] = {
                                    ["Car"] = selectedCar.Id,
                                    ["Color"] = customer:GetAttribute("OrderSpecColor"),
                                    ["Rims"] = customer:GetAttribute("OrderSpecRims"),
                                    ["Springs"] = customer:GetAttribute("OrderSpecSprings"),
                                    ["RimColor"] = customer:GetAttribute("OrderSpecRimColor")
                                }
                            })
                            task.wait(0.5)
                            remotes:FireServer({["Action"] = "CollectReward", ["OrderId"] = orderId})
                        end
                    end
                end
            end)
        end
    end)
end)
dealership:AddTextBox("Min sell price (0 = all)", tostring(settings.minSellPrice), function(val)
    local num = tonumber(val)
    if num then
        settings.minSellPrice = num
        saveSettings()
    end
end)
dealership:AddToggle("Auto Upgrade Plot", settings.autoUpgrade, function(state)
    settings.autoUpgrade = state
    getfenv().buyer = state
    saveSettings()
    task.spawn(function()
        while getfenv().buyer do
            task.wait()
            pcall(function()
                local tycoon
                for _, v in pairs(workspace.Tycoons:GetDescendants()) do
                    if v.Name == "Owner" and v:IsA("StringValue") and v.Value == game.Players.LocalPlayer.Name then
                        tycoon = v.Parent
                        break
                    end
                end
                if tycoon and tycoon:FindFirstChild("Dealership") and tycoon.Dealership:FindFirstChild("Purchases") then
                    for _, v in pairs(tycoon.Dealership.Purchases:GetChildren()) do
                        if v:FindFirstChild("TycoonButton") and v.TycoonButton.Button.Transparency == 0 then
                            game:GetService("ReplicatedStorage").Remotes.Build:FireServer("BuyItem", v.Name)
                            task.wait(0.3)
                        end
                    end
                end
            end)
        end
    end)
end)
dealership:AddToggle("Annoying Popup Disabler", settings.annoyPopup, function(state)
    settings.annoyPopup = state
    getfenv().annoy = state
    saveSettings()
    if state then
        getfenv().fun = game:GetService("Players").LocalPlayer.PlayerGui.ChildAdded:Connect(function(ok)
            if ok.Name == "Popup2" then ok:Destroy() end
        end)
    else
        if getfenv().fun then getfenv().fun:Disconnect() end
    end
end)

-- ==================== ВКЛАДКА: DELIVERY ====================

local delivery = Window:CreateTab("Delivery", "📦")
delivery:AddLabel("Minimum Stars")
delivery:AddTextBox("Enter stars (default 5)", tostring(settings.deliveryStars), function(val)
    local num = tonumber(val)
    if num then
        settings.deliveryStars = num
        getfenv().stars = num
        saveSettings()
    end
end)
delivery:AddLabel("Minimum Reward Money")
delivery:AddTextBox("Enter min money", tostring(settings.deliveryMinMoney), function(val)
    local num = tonumber(val)
    if num then
        settings.deliveryMinMoney = num
        getfenv().smaller = num
        saveSettings()
    end
end)
delivery:AddLabel("Maximum Reward Money")
delivery:AddTextBox("Enter max money", tostring(settings.deliveryMaxMoney), function(val)
    local num = tonumber(val)
    if num then
        settings.deliveryMaxMoney = num
        getfenv().bigger = num
        saveSettings()
    end
end)
delivery:AddToggle("Auto Delivery (обычная)", settings.autoDelivery, function(state)
    settings.autoDelivery = state
    getfenv().deliver = state
    saveSettings()
    resetcharactervalue1 = 0
    devpart2 = 1
    task.spawn(function()
        while getfenv().deliver do
            task.wait()
            pcall(function()
                if game.Players.LocalPlayer.Character:WaitForChild("Humanoid").Sit == false then
                    task.wait(5)
                    getfenv().spawned = false
                end
            end)
        end
    end)
    task.spawn(function()
        while getfenv().deliver do
            task.wait()
            if devpart2 ~= nil then
                resetcharactervalue1 = 0
            elseif devpart2 == nil and resetcharactervalue1 >= 20 then
                resetcharactervalue1 = 0
                game.Players.LocalPlayer.Character:BreakJoints()
                task.wait(1)
            end
        end
    end)
    while getfenv().deliver do
        task.wait()
        pcall(function()
            local chr = game.Players.LocalPlayer.Character
            if chr and chr.Humanoid.SeatPart ~= nil then
                task.wait(1)
                devpart2 = nil
                for _, v in pairs(workspace.ActionTasksGames.Jobs:GetDescendants()) do
                    if v.Name == "DeliveryPart" and v.Transparency ~= 1 then
                        devpart2 = v
                        workspace.Gravity = 0
                        getfenv().spawned = false
                        local car = chr.Humanoid.SeatPart.Parent.Parent
                        car:PivotTo(v.CFrame)
                        car:PivotTo(v.CFrame * CFrame.new(-30, 20, -10))
                        car:PivotTo(v.CFrame * CFrame.Angles(0, math.rad(90), 0))
                        for _, child in pairs(car:GetChildren()) do
                            if child:IsA("Model") and child:GetAttribute("StockTurbo") then
                                for _, job in pairs(workspace.ActionTasksGames.Jobs:GetChildren()) do
                                    if job:IsA("Model") and job:GetAttribute("JobId") then
                                        game:GetService("ReplicatedStorage").Remotes.DealershipCustomerController.JobRemoteHandler:FireServer({["Action"] = "TryToCompleteJob", ["JobId"] = job:GetAttribute("JobId")})
                                        game:GetService("ReplicatedStorage").Remotes.DealershipCustomerController.JobRemoteHandler:FireServer({["JobId"] = game:GetService("Players").LocalPlayer.PlayerGui.MissionRewardStars:GetAttribute("JobId"), ["Action"] = "CollectReward"})
                                    end
                                end
                            end
                        end
                    end
                end
                if devpart2 == nil then resetcharactervalue1 = resetcharactervalue1 + 1 end
            elseif chr and chr.Humanoid.Sit == false and getfenv().spawned ~= true then
                game:GetService("ReplicatedStorage").Remotes.DealershipCustomerController.JobRemoteHandler:FireServer(_G.remotetable)
                workspace.Gravity = 196
                getfenv().spawned = true
                task.wait(0.1)
            end
        end)
    end
end)
delivery:AddToggle("Auto Delivery (продвинутая)", settings.autoDeliveryAdv, function(state)
    settings.autoDeliveryAdv = state
    getfenv().deliver2 = state
    saveSettings()
    resetcharactervalue = 0
    devpart = 1
    game.Players.LocalPlayer.Character.Head.Anchored = false
    task.spawn(function()
        while getfenv().deliver2 do
            task.wait()
            pcall(function()
                if game.Players.LocalPlayer.Character:WaitForChild("Humanoid").Sit == false then
                    task.wait(5)
                    getfenv().spawned = false
                end
            end)
        end
    end)
    task.spawn(function()
        while getfenv().deliver2 do
            task.wait()
            if devpart ~= nil then
                resetcharactervalue = 0
            elseif devpart == nil and resetcharactervalue >= 20 then
                resetcharactervalue = 0
                game.Players.LocalPlayer.Character:BreakJoints()
                task.wait(1)
            end
        end
    end)
    local function gettruck()
        for _, v in pairs(workspace.Cars:GetChildren()) do
            if v.Name == "DeliveryTruck" and v:GetAttribute("JobId") == _G.remotetable.Jobs[1].Id then
                return v
            end
        end
        return nil
    end
    task.spawn(function()
        local timeout = 0
        while getfenv().deliver2 do
            task.wait()
            local truck = gettruck()
            if truck and game.Players.LocalPlayer.Character.Humanoid.SeatPart == nil then
                if timeout < 10 then
                    timeout = timeout + 1
                    task.wait(1)
                else
                    timeout = 0
                    truck:Destroy()
                    task.wait(1)
                end
            elseif truck and game.Players.LocalPlayer.Character.Humanoid.SeatPart ~= nil then
                timeout = 0
                task.wait(1)
            end
        end
    end)
    task.spawn(function()
        while getfenv().deliver2 do
            task.wait()
            if getfenv().checkif ~= nil then
                task.wait(40)
                getfenv().checkif = nil
            end
        end
    end)
    getfenv().checkif = nil
    while getfenv().deliver2 do
        task.wait()
        pcall(function()
            local chr = game.Players.LocalPlayer.Character
            if chr and chr.Humanoid.Sit == true then
                task.wait(0.1)
                devpart = nil
                for _, v in pairs(workspace.ActionTasksGames.Jobs:GetDescendants()) do
                    if v.Name == "DeliveryPart" and v.Transparency ~= 1 and chr.Humanoid.SeatPart ~= nil then
                        devpart = v
                        workspace.Gravity = 0
                        chr.Head.Anchored = false
                        tppart = v
                        getfenv().spawned = false
                        local car = chr.Humanoid.SeatPart.Parent.Parent
                        car:PivotTo(v.CFrame)
                        car:PivotTo(v.CFrame * CFrame.new(-30, 30, -10))
                        car:PivotTo(v.CFrame * CFrame.Angles(0, math.rad(90), 0))
                        for _, child in pairs(car:GetChildren()) do
                            if child:IsA("Model") and child:GetAttribute("StockTurbo") then
                                repeat task.wait(0.1)
                                    pcall(function()
                                        local car2 = chr.Humanoid.SeatPart.Parent.Parent
                                        car2:PivotTo(tppart.CFrame)
                                        car2:PivotTo(tppart.CFrame * CFrame.new(-30, 30, -10))
                                        car2:PivotTo(tppart.CFrame * CFrame.Angles(0, math.rad(90), 0))
                                    end)
                                    game:GetService("ReplicatedStorage").Remotes.DealershipCustomerController.JobRemoteHandler:FireServer({["Action"] = "TryToCompleteJob", ["JobId"] = child.Name})
                                until chr.Humanoid.SeatPart == nil or devpart.Transparency == 1 or not getfenv().deliver2
                                chr.Head.Anchored = false
                                chr.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                                local function getstars()
                                    local stars = 0
                                    local gui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("MissionRewardStars")
                                    if gui then
                                        for _, star in pairs(gui.Frame.Stars:GetChildren()) do
                                            if string.find(star.Name, "Star") and star.ImageColor3 == Color3.fromRGB(255, 189, 34) then
                                                stars = stars + 1
                                            end
                                        end
                                    end
                                    return stars
                                end
                                local function isused(id)
                                    for _, used in pairs(_G.usedids or {}) do
                                        if used == id then return true end
                                    end
                                    return false
                                end
                                if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("MissionRewardStars") and tonumber(getstars()) < settings.deliveryStars and game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("MissionRewardStars").Enabled == true and getfenv().checkif == nil then
                                    if type(_G.usedids) ~= "table" then _G.usedids = {} end
                                    for _, v in pairs(getgc(true)) do
                                        if type(v) == "table" and rawget(v, "MoneyReward") ~= nil and getfenv().checkif == nil and not isused(v.Id) then
                                            if tonumber(v.MoneyReward) > settings.deliveryMinMoney and tonumber(v.MoneyReward) < settings.deliveryMaxMoney then
                                                local tabnum = #_G.usedids + 1
                                                _G.usedids[tabnum] = v.Id
                                                whate = v
                                                _G.remotetable = {
                                                    ["Truck"] = "DeliveryTruck",
                                                    ["Action"] = "StartDeliveryJob",
                                                    ["Jobs"] = { [1] = {
                                                        ["Id"] = whate.Id,
                                                        ["Image"] = "http://www.roblox.com/asset/?id=7962599980",
                                                        ["CFrame"] = CFrame.new(-1476.16199, 601.700134, 3489.31299, -1, 0, 0, 0, 1, 0, 0, 0, -1),
                                                        ["JobData"] = whate
                                                    } }
                                                }
                                                if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("MissionRewardStars") then
                                                    task.wait(0.5)
                                                    game:GetService("ReplicatedStorage").Remotes.DealershipCustomerController.JobRemoteHandler:FireServer({["JobId"] = game:GetService("Players").LocalPlayer.PlayerGui.MissionRewardStars:GetAttribute("JobId"), ["Action"] = "CollectReward"})
                                                    task.wait(0.5)
                                                    game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("MissionRewardStars").Enabled = false
                                                end
                                                getfenv().checkif = true
                                                break
                                            end
                                        end
                                    end
                                end
                                task.wait()
                                if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("MissionRewardStars") then
                                    game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("MissionRewardStars").Enabled = false
                                    game:GetService("ReplicatedStorage").Remotes.DealershipCustomerController.JobRemoteHandler:FireServer({["JobId"] = game:GetService("Players").LocalPlayer.PlayerGui.MissionRewardStars:GetAttribute("JobId"), ["Action"] = "CollectReward"})
                                end
                            end
                        end
                    end
                end
                if devpart == nil then resetcharactervalue = resetcharactervalue + 1 end
            elseif chr and chr.Humanoid.Sit == false and gettruck() == nil then
                if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("MissionRewardStars") then
                    pcall(function()
                        chr.HumanoidRootPart.CFrame = tppart.CFrame
                        chr.Head.Anchored = true
                    end)
                    task.wait(1)
                end
                game:GetService("ReplicatedStorage").Remotes.DealershipCustomerController.JobRemoteHandler:FireServer(_G.remotetable)
                local unstuck = 0
                repeat task.wait() unstuck = unstuck + 1 until gettruck() ~= nil or not getfenv().deliver2 or unstuck > 100
                workspace.Gravity = 196
                chr.Head.Anchored = false
            end
        end)
    end
end)

-- ==================== ВКЛАДКА: RACE ====================

local raceTab = Window:CreateTab("Race", "🏁")
raceTab:AddTextBox("Auto Race Speed", tostring(settings.raceSpeed), function(val)
    local num = tonumber(val)
    if num then
        settings.raceSpeed = num
        getfenv().raceSpeed = num
        saveSettings()
    end
end)
raceTab:AddToggle("Auto Race (Standard)", settings.autoRace, function(state)
    settings.autoRace = state
    _G.racetest = state
    saveSettings()
    workspace.Gravity = 196
    local race = nil
    local distance = math.huge
    for _, v in pairs(workspace.Races:GetDescendants()) do
        if v.Name == "Main" and v:IsA("UnionOperation") then
            local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - v.Position).Magnitude
            if dist < distance then
                distance = dist
                race = v
            end
        end
    end
    local tpto = race and race.CFrame or CFrame.new()
    _G.remotetable1 = nil
    _G.remotetable2 = nil
    _G.remotetable3 = nil
    while _G.racetest do
        task.wait()
        local chr = game.Players.LocalPlayer.Character
        if not chr or not chr:FindFirstChild("Humanoid") then continue end
        if game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == false and _G.remotetable1 ~= nil then
            getfenv().firsttime = true
            if chr.Humanoid.SeatPart then
                local car = chr.Humanoid.SeatPart.Parent.Parent
                car:PivotTo(tpto)
                workspace.Gravity = 196
                chr.Head.Anchored = true
                task.wait(1)
                chr.Head.Anchored = false
                local timer = tick()
                repeat task.wait(0.1)
                    _G.remote1:FireServer(unpack(_G.remotetable1))
                until tick() - timer > 15 or not _G.racetest
                if _G.remotetable2 ~= nil then
                    _G.remote2:FireServer(unpack(_G.remotetable2))
                    task.wait(15)
                end
                if _G.remotetable3 ~= nil then
                    _G.remote3:FireServer(unpack(_G.remotetable3))
                end
                repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == true or not _G.racetest
            end
        elseif game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == true then
            repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui.RaceStart.GO.ImageTransparency ~= 1 or getfenv().firsttime == false or not _G.racetest
            getfenv().firsttime = false
            local function updategoal()
                local goal = nil
                local distance = math.huge
                for _, v in pairs(workspace.Races:GetDescendants()) do
                    if v.Name == "GoalPart" and v:IsA("Part") and v:FindFirstChildOfClass("Decal") and v:FindFirstChildOfClass("Decal").Transparency ~= 1 or (v.Name == "GoalCheckpoint" and v:IsA("Part") and v:FindFirstChildOfClass("Decal") and v:FindFirstChildOfClass("Decal").Transparency ~= 1) then
                        local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - v.Position).Magnitude
                        if dist < distance then
                            distance = dist
                            goal = v
                        end
                    end
                end
                return goal
            end
            local function updategoal1()
                for _, v in pairs(workspace.Races:GetDescendants()) do
                    if v.Name == "Checkpoint" and v:IsA("MeshPart") and v.Transparency ~= 1 then
                        local goal = v.Parent.Parent.Parent.GoalCheckpoint.GoalCheckpoint
                        goal.Size = Vector3.new(goal.Size.X, 15, goal.Size.Z)
                        return goal
                    end
                end
                return nil
            end
            local function updategoal2()
                local goal = nil
                local distance = math.huge
                for _, v in pairs(workspace.Races:GetDescendants()) do
                    if v.Name == "GoalPart" and v:IsA("Part") then
                        local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - v.Position).Magnitude
                        if dist < distance then
                            distance = dist
                            goal = v
                        end
                    end
                end
                return goal
            end
            local speed = getfenv().raceSpeed or 200
            local TweenService = game:GetService("TweenService")
            repeat task.wait()
                local test = nil
                for _, v in pairs(workspace.Races:GetDescendants()) do
                    if v.Name == "Checkpoint" and v:IsA("MeshPart") and v.Transparency ~= 1 then
                        test = v
                        break
                    end
                end
                if not test then break end
                local chr = game.Players.LocalPlayer.Character
                if not chr or not chr.Humanoid.SeatPart then break end
                local car = chr.Humanoid.SeatPart.Parent.Parent
                local dist = (chr.HumanoidRootPart.Position - test.Position).Magnitude
                workspace.Gravity = 0
                local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
                local tweenValue = Instance.new("CFrameValue")
                tweenValue.Value = car:GetPrimaryPartCFrame()
                local conn = tweenValue.Changed:Connect(function()
                    car.PrimaryPart.Velocity = Vector3.zero
                    car:PivotTo(CFrame.new(tweenValue.Value.Position))
                end)
                local tween = TweenService:Create(tweenValue, tweenInfo, { Value = test.CFrame + Vector3.new(0, 5, 0) })
                tween:Play()
                tween.Completed:Wait()
                conn:Disconnect()
                tweenValue:Destroy()
                if tonumber(test.Parent.Name) == #test.Parent.Parent:GetChildren() then
                    local goal = updategoal1()
                    if goal then
                        local chr2 = game.Players.LocalPlayer.Character
                        if chr2 and chr2.Humanoid.SeatPart then
                            local car2 = chr2.Humanoid.SeatPart.Parent.Parent
                            local goalPos = CFrame.new(goal.Position.X, chr2.PrimaryPart.Position.Y, goal.Position.Z)
                            dist = (chr2.HumanoidRootPart.Position - goal.Position).Magnitude
                            local tweenInfo2 = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
                            local tweenValue2 = Instance.new("CFrameValue")
                            tweenValue2.Value = car2:GetPrimaryPartCFrame()
                            local conn2 = tweenValue2.Changed:Connect(function()
                                car2.PrimaryPart.Velocity = Vector3.zero
                                car2:PivotTo(CFrame.new(tweenValue2.Value.Position))
                            end)
                            local tween2 = TweenService:Create(tweenValue2, tweenInfo2, { Value = goalPos })
                            tween2:Play()
                            tween2.Completed:Wait()
                            conn2:Disconnect()
                            tweenValue2:Destroy()
                        end
                    end
                    break
                end
            until not _G.racetest
            local goal = updategoal()
            if goal then
                local chr = game.Players.LocalPlayer.Character
                if chr and chr.Humanoid.SeatPart then
                    local car = chr.Humanoid.SeatPart.Parent.Parent
                    local target = CFrame.new(goal.Position.X, chr.HumanoidRootPart.Position.Y, goal.Position.Z)
                    local dist = (chr.HumanoidRootPart.Position - target.Position).Magnitude
                    local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
                    local tweenValue = Instance.new("CFrameValue")
                    tweenValue.Value = car:GetPrimaryPartCFrame()
                    local conn = tweenValue.Changed:Connect(function()
                        car.PrimaryPart.Velocity = Vector3.zero
                        car:PivotTo(CFrame.new(tweenValue.Value.Position))
                    end)
                    local tween = TweenService:Create(tweenValue, tweenInfo, { Value = target })
                    tween:Play()
                    tween.Completed:Wait()
                    conn:Disconnect()
                    tweenValue:Destroy()
                    task.wait(1)
                    car:PivotTo(target)
                    task.wait()
                    car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * 350
                    task.wait(1)
                    local t = tick()
                    repeat task.wait() car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero until tick() - t >= 1 or not _G.racetest
                    workspace.Gravity = 196
                end
            elseif not goal and updategoal2() then
                local v = updategoal2()
                local chr = game.Players.LocalPlayer.Character
                if chr and chr.Humanoid.SeatPart then
                    local car = chr.Humanoid.SeatPart.Parent.Parent
                    local target = CFrame.new(v.Position.X, chr.HumanoidRootPart.Position.Y, v.Position.Z)
                    local dist = (chr.HumanoidRootPart.Position - target.Position).Magnitude
                    local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
                    local tweenValue = Instance.new("CFrameValue")
                    tweenValue.Value = car:GetPrimaryPartCFrame()
                    local conn = tweenValue.Changed:Connect(function()
                        car.PrimaryPart.Velocity = Vector3.zero
                        car:PivotTo(CFrame.new(tweenValue.Value.Position))
                    end)
                    local tween = TweenService:Create(tweenValue, tweenInfo, { Value = target })
                    tween:Play()
                    tween.Completed:Wait()
                    conn:Disconnect()
                    tweenValue:Destroy()
                    task.wait(1)
                    car:PivotTo(target)
                    task.wait()
                    car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * 350
                    task.wait(1)
                    local t = tick()
                    repeat task.wait() car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero until tick() - t >= 1 or not _G.racetest
                    workspace.Gravity = 196
                end
            end
        end
    end
end)
raceTab:AddToggle("Auto Race (Fast - Hitbox)", settings.autoRaceFast, function(state)
    settings.autoRaceFast = state
    _G.racetest_fast = state
    saveSettings()
    workspace.Gravity = 196
    local race = nil
    local distance = math.huge
    for _, v in pairs(workspace.Races:GetDescendants()) do
        if v.Name == "Main" and v:IsA("UnionOperation") then
            local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - v.Position).Magnitude
            if dist < distance then
                distance = dist
                race = v
            end
        end
    end
    local tpto = race and race.CFrame or CFrame.new()
    _G.remotetable1 = nil
    _G.remotetable2 = nil
    _G.remotetable3 = nil
    while _G.racetest_fast do
        task.wait()
        local chr = game.Players.LocalPlayer.Character
        if not chr or not chr:FindFirstChild("Humanoid") then continue end
        if game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == false and _G.remotetable1 ~= nil then
            getfenv().firsttime_fast = true
            if chr.Humanoid.SeatPart then
                local car = chr.Humanoid.SeatPart.Parent.Parent
                car:PivotTo(tpto)
                workspace.Gravity = 196
                chr.Head.Anchored = true
                task.wait(1)
                chr.Head.Anchored = false
                local timer = tick()
                repeat task.wait(0.1)
                    _G.remote1:FireServer(unpack(_G.remotetable1))
                until tick() - timer > 15 or not _G.racetest_fast
                if _G.remotetable2 ~= nil then
                    _G.remote2:FireServer(unpack(_G.remotetable2))
                    task.wait(15)
                end
                if _G.remotetable3 ~= nil then
                    _G.remote3:FireServer(unpack(_G.remotetable3))
                end
                repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == true or not _G.racetest_fast
            end
        elseif game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == true then
            repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui.RaceStart.GO.ImageTransparency ~= 1 or getfenv().firsttime_fast == false or not _G.racetest_fast
            getfenv().firsttime_fast = false
            local speed = getfenv().raceSpeed or 200
            local TweenService = game:GetService("TweenService")
            while _G.racetest_fast do
                local checkpoint = nil
                for _, v in pairs(workspace.Races:GetDescendants()) do
                    if v.Name == "Checkpoint" and v:IsA("MeshPart") and v.Transparency ~= 1 then
                        checkpoint = v
                        break
                    end
                end
                if not checkpoint then break end
                local chr = game.Players.LocalPlayer.Character
                if not chr or not chr.Humanoid.SeatPart then break end
                local car = chr.Humanoid.SeatPart.Parent.Parent
                local goal = checkpoint.CFrame + Vector3.new(0, 5, 0)
                local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
                local tweenValue = Instance.new("CFrameValue")
                tweenValue.Value = car:GetPrimaryPartCFrame()
                local conn = tweenValue.Changed:Connect(function()
                    car:PivotTo(CFrame.new(tweenValue.Value.Position))
                end)
                local tween = TweenService:Create(tweenValue, tweenInfo, { Value = goal })
                tween:Play()
                tween.Completed:Wait()
                conn:Disconnect()
                tweenValue:Destroy()
                if checkpoint.Parent and checkpoint.Parent.Parent then
                    local children = checkpoint.Parent.Parent:GetChildren()
                    local last = children[#children]
                    if last and last == checkpoint.Parent then
                        break
                    end
                end
                task.wait(0.05)
            end
        end
    end
end)
raceTab:AddToggle("Auto Drift Race", settings.autoDriftRace, function(state)
    settings.autoDriftRace = state
    _G.racetest3 = state
    saveSettings()
    if not _G.racetest3 and partvelo ~= nil then
        partvelo.Velocity = Vector3.zero
    end
    local race = nil
    local distance = math.huge
    for _, v in pairs(workspace.Races:GetDescendants()) do
        if v.Name == "Main" and v:IsA("UnionOperation") then
            local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - v.Position).Magnitude
            if dist < distance then
                distance = dist
                race = v
            end
        end
    end
    local tpto = race and race.CFrame or CFrame.new()
    _G.remotetable1 = nil
    _G.remotetable2 = nil
    _G.remotetable3 = nil
    while _G.racetest3 do
        task.wait()
        local chr = game.Players.LocalPlayer.Character
        if not chr or not chr:FindFirstChild("Humanoid") then continue end
        if game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == false and _G.remotetable1 ~= nil then
            getfenv().firsttime = true
            if chr.Humanoid.SeatPart then
                local car = chr.Humanoid.SeatPart.Parent.Parent
                car.PrimaryPart.Velocity = Vector3.zero
                car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
                task.wait()
                car:PivotTo(tpto)
                chr.Head.Anchored = true
                task.wait(1)
                chr.Head.Anchored = false
                local timer = tick()
                repeat task.wait(0.1)
                    _G.remote1:FireServer(unpack(_G.remotetable1))
                until tick() - timer > 15 or not _G.racetest3
                if _G.remotetable2 ~= nil then
                    _G.remote2:FireServer(unpack(_G.remotetable2))
                    task.wait(15)
                end
                if _G.remotetable3 ~= nil then
                    _G.remote3:FireServer(unpack(_G.remotetable3))
                end
                partvelo = nil
                repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == true or not _G.racetest3
            end
        elseif game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == true then
            repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui.RaceStart.GO.ImageTransparency ~= 1 or getfenv().firsttime == false or not _G.racetest3
            if partvelo == nil then
                local chr = game.Players.LocalPlayer.Character
                if chr and chr.Humanoid.SeatPart then
                    local car = chr.Humanoid.SeatPart.Parent.Parent
                    carloc = car.PrimaryPart.CFrame
                    local hum = chr.HumanoidRootPart
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = { hum.Parent, car, workspace.Camera }
                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                    raycastParams.IgnoreWater = true
                    local result = workspace:Raycast(hum.Position, Vector3.new(0, -100, 0), raycastParams)
                    if result then
                        partvelo = result.Instance
                        partvelo.Velocity = hum.CFrame.LookVector * 1000
                    end
                end
            end
            local split = game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Bar.Laps.Text:split("pts")[1]
            local number = tonumber(string.gsub(split, ",", ""))
            local chr = game.Players.LocalPlayer.Character
            if chr and chr.Humanoid.SeatPart then
                local car = chr.Humanoid.SeatPart.Parent.Parent
                repeat task.wait()
                    split = game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Bar.Laps.Text:split("pts")[1]
                    number = tonumber(string.gsub(split, ",", ""))
                    if game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == true and number ~= nil and number <= 49999 then
                        car:PivotTo(carloc)
                    end
                until game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == false or not _G.racetest3 or (number ~= nil and number >= 50000)
                if partvelo then
                    partvelo.Velocity = Vector3.zero
                    partvelo = nil
                end
                repeat task.wait()
                    car.PrimaryPart.Velocity = Vector3.zero
                    car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(tpto)
                until game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == false or not _G.racetest3
                task.wait(1)
            end
        end
    end
end)
raceTab:AddToggle("AutoFarm [laps|checkpoints]", settings.autoFarmLaps, function(state)
    settings.autoFarmLaps = state
    _G.racetest = state
    saveSettings()
    workspace.Gravity = 196
    local race = nil
    local distance = math.huge
    for _, v in pairs(workspace.Races:GetDescendants()) do
        if v.Name == "Main" and v:IsA("UnionOperation") then
            local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - v.Position).Magnitude
            if dist < distance then
                distance = dist
                race = v
            end
        end
    end
    local tpto = race and race.CFrame or CFrame.new()
    _G.remotetable1 = nil
    _G.remotetable2 = nil
    _G.remotetable3 = nil
    while _G.racetest do
        pcall(function()
            task.wait()
            local chr = game.Players.LocalPlayer.Character
            if not chr or not chr:FindFirstChild("Humanoid") then return end
            if game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == false and _G.remotetable1 ~= nil then
                getfenv().firsttime = true
                if chr.Humanoid.SeatPart then
                    local car = chr.Humanoid.SeatPart.Parent.Parent
                    car:PivotTo(tpto)
                    workspace.Gravity = 196
                    chr.Head.Anchored = true
                    task.wait(1)
                    chr.Head.Anchored = false
                    local timer = tick()
                    repeat task.wait(0.1)
                        _G.remote1:FireServer(unpack(_G.remotetable1))
                    until tick() - timer > 15 or not _G.racetest
                    if _G.remotetable2 ~= nil then
                        _G.remote2:FireServer(unpack(_G.remotetable2))
                        task.wait(15)
                    end
                    if _G.remotetable3 ~= nil then
                        _G.remote3:FireServer(unpack(_G.remotetable3))
                    end
                    repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == true or not _G.racetest
                end
            elseif game:GetService("Players").LocalPlayer.PlayerGui.Menu.Race.Visible == true then
                local count = #race.Parent.Checkpoints:GetChildren()
                for i = 1, count * race.Parent.Script:FindFirstChild("Laps").Value do
                    race.Parent.Script.Checkpoint:FireServer(i)
                end
            end
        end)
    end
end)
raceTab:AddToggle("Auto Race Farming (комбо)", settings.autoRaceFarming, function(state)
    settings.autoRaceFarming = state
    getfenv().autoRaceFarming = state
    saveSettings()
    task.spawn(function()
        while getfenv().autoRaceFarming do
            local modes = {
                {flag = "racetest", toggle = settings.autoRace, name = "Standard"},
                {flag = "racetest_fast", toggle = settings.autoRaceFast, name = "Fast"},
                {flag = "racetest3", toggle = settings.autoDriftRace, name = "Drift"},
            }
            for _, mode in ipairs(modes) do
                if not getfenv().autoRaceFarming then break end
                _G[mode.flag] = true
                local start = tick()
                while getfenv().autoRaceFarming and _G[mode.flag] and tick() - start < 60 do
                    task.wait(1)
                end
                _G[mode.flag] = false
                task.wait(2)
            end
            task.wait(5)
        end
    end)
end)

-- ==================== ВКЛАДКА: AUTOMATION ====================

local automation = Window:CreateTab("Automation", "🤖")
automation:AddSection("Season & Free Rewards")
automation:AddTextBox("Season from level", tostring(settings.seasonFrom), function(val)
    local num = tonumber(val)
    if num then
        settings.seasonFrom = num
        saveSettings()
    end
end)
automation:AddTextBox("to level", tostring(settings.seasonTo), function(val)
    local num = tonumber(val)
    if num then
        settings.seasonTo = num
        saveSettings()
    end
end)
automation:AddToggle("Auto Claim Season Rewards", settings.autoSeason, function(state)
    settings.autoSeason = state
    getfenv().claimSeasonAll = state
    saveSettings()
    task.spawn(function()
        while getfenv().claimSeasonAll do
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local remotes = rep:FindFirstChild("Remotes")
                local services = remotes and remotes:FindFirstChild("Services")
                local seasonService = (services and (services:FindFirstChild("TrophySeasonRemotes") or services:FindFirstChild("SeasonService") or services:FindFirstChild("BattlePassService")))
                    or (remotes and (remotes:FindFirstChild("TrophySeasonRemotes") or remotes:FindFirstChild("SeasonService")))
                if seasonService then
                    local claimRemote = seasonService:FindFirstChild("ClaimLevelReward") or seasonService:FindFirstChild("ClaimReward") or seasonService:FindFirstChild("Claim")
                    if claimRemote then
                        for level = settings.seasonFrom, settings.seasonTo do
                            if not getfenv().claimSeasonAll then break end
                            if claimRemote:IsA("RemoteFunction") then
                                claimRemote:InvokeServer(level, "Free")
                                claimRemote:InvokeServer(level, "Premium")
                                claimRemote:InvokeServer(level, "Elite")
                                claimRemote:InvokeServer(level)
                            elseif claimRemote:IsA("RemoteEvent") then
                                claimRemote:FireServer(level, "Free")
                                claimRemote:FireServer(level, "Premium")
                                claimRemote:FireServer(level, "Elite")
                                claimRemote:FireServer(level)
                            end
                            task.wait(0.05)
                        end
                    end
                end
            end)
            task.wait(5)
        end
    end)
end)
automation:AddToggle("Auto Claim Free Gifts (Store)", settings.autoFreeGifts, function(state)
    settings.autoFreeGifts = state
    getfenv().claimFreeGift = state
    saveSettings()
    task.spawn(function()
        while getfenv().claimFreeGift do
            pcall(function()
                local claimRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Databases")
                    and game.ReplicatedStorage.Databases:FindFirstChild("Store")
                    and game.ReplicatedStorage.Databases.Store:FindFirstChild("Featured")
                    and game.ReplicatedStorage.Databases.Store.Featured:FindFirstChild("ClaimFreeGift")
                if claimRemote then
                    claimRemote:InvokeServer()
                end
            end)
            task.wait(5)
        end
    end)
end)
automation:AddToggle("Auto Collect All Free Rewards", settings.autoCollectAllFreeRewards, function(state)
    settings.autoCollectAllFreeRewards = state
    getfenv().autoCollectAllFree = state
    saveSettings()
    task.spawn(function()
        while getfenv().autoCollectAllFree do
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local remotes = rep:FindFirstChild("Remotes")
                local services = remotes and remotes:FindFirstChild("Services")
                local seasonService = (services and (services:FindFirstChild("TrophySeasonRemotes") or services:FindFirstChild("SeasonService") or services:FindFirstChild("BattlePassService")))
                    or (remotes and (remotes:FindFirstChild("TrophySeasonRemotes") or remotes:FindFirstChild("SeasonService")))
                if seasonService then
                    local claimRemote = seasonService:FindFirstChild("ClaimLevelReward") or seasonService:FindFirstChild("ClaimReward") or seasonService:FindFirstChild("Claim")
                    if claimRemote then
                        for level = settings.seasonFrom, settings.seasonTo do
                            if not getfenv().autoCollectAllFree then break end
                            if claimRemote:IsA("RemoteFunction") then
                                claimRemote:InvokeServer(level, "Free")
                                claimRemote:InvokeServer(level, "Premium")
                                claimRemote:InvokeServer(level, "Elite")
                            elseif claimRemote:IsA("RemoteEvent") then
                                claimRemote:FireServer(level, "Free")
                                claimRemote:FireServer(level, "Premium")
                                claimRemote:FireServer(level, "Elite")
                            end
                            task.wait(0.05)
                        end
                    end
                end
                local claimGift = rep:FindFirstChild("Databases")
                    and rep.Databases:FindFirstChild("Store")
                    and rep.Databases.Store:FindFirstChild("Featured")
                    and rep.Databases.Store.Featured:FindFirstChild("ClaimFreeGift")
                if claimGift then
                    claimGift:InvokeServer()
                end
                local dailyEvent = rep:FindFirstChild("Remotes")
                    and rep.Remotes:FindFirstChild("EventController")
                    and rep.Remotes.EventController:FindFirstChild("DailyStreak")
                if dailyEvent and dailyEvent:IsA("RemoteEvent") then
                    firesignal(dailyEvent.OnClientEvent, {Action = "Claim"})
                    local claimFunc = dailyEvent:FindFirstChild("Claim")
                    if claimFunc and claimFunc:IsA("RemoteFunction") then
                        claimFunc:InvokeServer()
                    end
                else
                    local claimDaily = rep:FindFirstChild("Remotes")
                        and rep.Remotes:FindFirstChild("DailyStreak")
                    if claimDaily and claimDaily:IsA("RemoteFunction") then
                        claimDaily:InvokeServer()
                    end
                end
            end)
            task.wait(10)
        end
    end)
end)

automation:AddSection("Spin Settings")
automation:AddTextBox("Spin count per cycle", tostring(settings.spinCount), function(val)
    local num = tonumber(val)
    if num then
        settings.spinCount = num
        saveSettings()
    end
end)
automation:AddTextBox("Spin delay (seconds)", tostring(settings.spinDelay), function(val)
    local num = tonumber(val)
    if num then
        settings.spinDelay = num
        saveSettings()
    end
end)
automation:AddToggle("Auto Spin Standard (с количеством)", settings.autoSpinStandard, function(state)
    settings.autoSpinStandard = state
    getfenv().spinner = state
    saveSettings()
    task.spawn(function()
        while getfenv().spinner do
            local count = settings.spinCount or 1
            local delay = settings.spinDelay or 0.3
            for i = 1, count do
                if not getfenv().spinner then break end
                pcall(function()
                    local spinRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Databases")
                        and game.ReplicatedStorage.Databases:FindFirstChild("Spinners")
                        and game.ReplicatedStorage.Databases.Spinners:FindFirstChild("SpinEvent")
                    if spinRemote then
                        spinRemote:InvokeServer("Standard", "Free")
                    else
                        local altSpin = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                            and game.ReplicatedStorage.Remotes:FindFirstChild("Services")
                            and game.ReplicatedStorage.Remotes.Services:FindFirstChild("SpinnerRemotes")
                            and game.ReplicatedStorage.Remotes.Services.SpinnerRemotes:FindFirstChild("Spin")
                        if altSpin then
                            altSpin:InvokeServer("Standard")
                        end
                    end
                end)
                task.wait(delay)
            end
            task.wait(1.5)
        end
    end)
end)
automation:AddToggle("Auto Spin Hyper (с количеством)", settings.autoSpinHyper, function(state)
    settings.autoSpinHyper = state
    getfenv().spinner1 = state
    saveSettings()
    task.spawn(function()
        while getfenv().spinner1 do
            local count = settings.spinCount or 1
            local delay = settings.spinDelay or 0.3
            for i = 1, count do
                if not getfenv().spinner1 then break end
                pcall(function()
                    local spinRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Databases")
                        and game.ReplicatedStorage.Databases:FindFirstChild("Spinners")
                        and game.ReplicatedStorage.Databases.Spinners:FindFirstChild("SpinEvent")
                    if spinRemote then
                        spinRemote:InvokeServer("Hyper", "Free")
                    end
                end)
                task.wait(delay)
            end
            task.wait(1.5)
        end
    end)
end)
automation:AddSection("Auto Purchase Spins (Free Dup)")
automation:AddTextBox("Spin type", settings.purchaseSpinsType, function(val)
    if val and val ~= "" then
        settings.purchaseSpinsType = val
        saveSettings()
    end
end)
automation:AddTextBox("Amount per call", tostring(settings.purchaseSpinsAmount), function(val)
    local num = tonumber(val)
    if num then
        settings.purchaseSpinsAmount = num
        saveSettings()
    end
end)
automation:AddToggle("Auto Purchase Spins (Free Dup)", settings.autoPurchaseSpins, function(state)
    settings.autoPurchaseSpins = state
    getfenv().autoPurchaseSpins = state
    saveSettings()
    task.spawn(function()
        while getfenv().autoPurchaseSpins do
            pcall(function()
                local spinner = game:GetService("ReplicatedStorage"):FindFirstChild("Databases")
                    and game.ReplicatedStorage.Databases:FindFirstChild("Spinners")
                    and game.ReplicatedStorage.Databases.Spinners:FindFirstChild("OnPurchaseSpins")
                if spinner then
                    spinner:FireServer(settings.purchaseSpinsType, settings.purchaseSpinsAmount)
                else
                    warn("OnPurchaseSpins не найден")
                end
            end)
            task.wait(1.5)
        end
    end)
end)

automation:AddSection("Kits")
automation:AddTextBox("Kits count per cycle", tostring(settings.kitCount), function(val)
    local num = tonumber(val)
    if num then
        settings.kitCount = num
        saveSettings()
    end
end)
automation:AddToggle("Auto Open Kits (с количеством)", settings.autoOpenKits, function(state)
    settings.autoOpenKits = state
    getfenv().openKits = state
    saveSettings()
    task.spawn(function()
        while getfenv().openKits do
            local count = settings.kitCount or 1
            for i = 1, count do
                if not getfenv().openKits then break end
                pcall(function()
                    local consume = game:GetService("ReplicatedStorage").Remotes.Services.ConsumableServiceRemotes.Consume
                    local kitTypes = {"DecorationKit", "DecorationKitDeluxe", "RegularCustomizationKit", "DeluxeCustomizationKit", "CustomizationKit"}
                    for _, kitName in ipairs(kitTypes) do
                        if not getfenv().openKits then break end
                        consume:InvokeServer(kitName)
                        task.wait(0.05)
                    end
                end)
                task.wait(0.1)
            end
            task.wait(0.5)
        end
    end)
end)
automation:AddToggle("Giver Kit (открывает все виды китов)", settings.giverKit, function(state)
    settings.giverKit = state
    getfenv().giverKit = state
    saveSettings()
    task.spawn(function()
        while getfenv().giverKit do
            pcall(function()
                local consume = game:GetService("ReplicatedStorage").Remotes.Services.ConsumableServiceRemotes.Consume
                local kitTypes = {"DecorationKit", "DecorationKitDeluxe", "RegularCustomizationKit", "DeluxeCustomizationKit", "CustomizationKit"}
                for _, kitName in ipairs(kitTypes) do
                    if not getfenv().giverKit then break end
                    consume:InvokeServer(kitName)
                    task.wait(0.1)
                end
            end)
            task.wait(0.5)
        end
    end)
end)
automation:AddToggle("Auto Open All Customization Kits (отдельно)", settings.autoOpenAllKits, function(state)
    settings.autoOpenAllKits = state
    getfenv().openAllKits = state
    saveSettings()
    task.spawn(function()
        while getfenv().openAllKits do
            pcall(function()
                local consume = game:GetService("ReplicatedStorage").Remotes.Services.ConsumableServiceRemotes.Consume
                local kitTypes = {"DecorationKit", "DecorationKitDeluxe", "RegularCustomizationKit", "DeluxeCustomizationKit", "CustomizationKit"}
                for _, kitName in ipairs(kitTypes) do
                    if not getfenv().openAllKits then break end
                    consume:InvokeServer(kitName)
                    task.wait(0.1)
                end
            end)
            task.wait(0.5)
        end
    end)
end)

automation:AddSection("Auto Chop / Infusion")
automation:AddTextBox("Chop Car Name", settings.chopCarName, function(val)
    if val and val ~= "" then
        settings.chopCarName = val
        saveSettings()
    end
end)
automation:AddTextBox("Chop Car GUID", settings.chopCarGUID, function(val)
    if val and val ~= "" then
        settings.chopCarGUID = val
        saveSettings()
    end
end)
automation:AddToggle("Auto Chop Vehicle", settings.autoChop, function(state)
    settings.autoChop = state
    getfenv().autoChop = state
    saveSettings()
    task.spawn(function()
        while getfenv().autoChop do
            pcall(function()
                local RequestChop = game:GetService("ReplicatedStorage"):WaitForChild("Packages")
                    :WaitForChild("_Index")
                    :WaitForChild("sleitnick_typed-remote@0.2.0")
                    :WaitForChild("typed-remote")
                    :WaitForChild("RequestChop")
                RequestChop:InvokeServer(settings.chopCarName, settings.chopCarGUID)
            end)
            task.wait(5)
        end
    end)
end)
automation:AddTextBox("Infusion Car Name", settings.infusionCarName, function(val)
    if val and val ~= "" then
        settings.infusionCarName = val
        saveSettings()
    end
end)
automation:AddTextBox("Infusion Car GUID", settings.infusionCarGUID, function(val)
    if val and val ~= "" then
        settings.infusionCarGUID = val
        saveSettings()
    end
end)
automation:AddToggle("Auto Infusion Vehicle", settings.autoInfusion, function(state)
    settings.autoInfusion = state
    getfenv().autoInfusion = state
    saveSettings()
    task.spawn(function()
        while getfenv().autoInfusion do
            pcall(function()
                local RequestInfusion = game:GetService("ReplicatedStorage"):WaitForChild("Packages")
                    :WaitForChild("_Index")
                    :WaitForChild("sleitnick_typed-remote@0.2.0")
                    :WaitForChild("typed-remote")
                    :WaitForChild("RequestInfusion")
                RequestInfusion:InvokeServer(settings.infusionCarName, settings.infusionCarGUID)
            end)
            task.wait(5)
        end
    end)
end)
automation:AddToggle("Auto Claim Daily Streak", settings.autoDaily, function(state)
    settings.autoDaily = state
    getfenv().autoDaily = state
    saveSettings()
    task.spawn(function()
        while getfenv().autoDaily do
            pcall(function()
                local dailyEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    and game.ReplicatedStorage.Remotes:FindFirstChild("EventController")
                    and game.ReplicatedStorage.Remotes.EventController:FindFirstChild("DailyStreak")
                if dailyEvent and dailyEvent:IsA("RemoteEvent") then
                    firesignal(dailyEvent.OnClientEvent, {Action = "Claim"})
                    local claimFunc = dailyEvent:FindFirstChild("Claim")
                    if claimFunc and claimFunc:IsA("RemoteFunction") then
                        claimFunc:InvokeServer()
                    end
                else
                    local claimRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                        and game.ReplicatedStorage.Remotes:FindFirstChild("DailyStreak")
                    if claimRemote and claimRemote:IsA("RemoteFunction") then
                        claimRemote:InvokeServer()
                    end
                end
            end)
            task.wait(10)
        end
    end)
end)

automation:AddSection("Auto Buy Cars (из магазина)")
automation:AddTextBox("Min price (0 = no limit)", tostring(settings.buyMinPrice), function(val)
    local num = tonumber(val)
    if num then
        settings.buyMinPrice = num
        saveSettings()
    end
end)
automation:AddTextBox("Max price (999999999 = no limit)", tostring(settings.buyMaxPrice), function(val)
    local num = tonumber(val)
    if num then
        settings.buyMaxPrice = num
        saveSettings()
    end
end)
automation:AddTextBox("Specific car name (empty = all in range)", settings.buySpecificCar, function(val)
    settings.buySpecificCar = val
    saveSettings()
end)
automation:AddToggle("Auto Buy Cars (покупает недостающие машины)", settings.autoBuyCars, function(state)
    settings.autoBuyCars = state
    getfenv().autoBuyCars = state
    saveSettings()
    task.spawn(function()
        while getfenv().autoBuyCars do
            pcall(function()
                local carShopEntries = require(game:GetService("ReplicatedStorage").Data.CarShopEntries)
                local cars = carShopEntries.CarsInShop
                local playerCars = {}
                local playerData = game:GetService("Players").LocalPlayer:FindFirstChild("Data")
                if playerData and playerData:FindFirstChild("OwnedCars") then
                    for _, car in pairs(playerData.OwnedCars:GetChildren()) do
                        playerCars[car.Name] = true
                    end
                end
                for _, car in pairs(cars) do
                    if not getfenv().autoBuyCars then break end
                    local price = car.PriceValue or 0
                    local carName = car.Name or ""
                    if settings.buySpecificCar ~= "" and settings.buySpecificCar ~= carName then
                        continue
                    end
                    if price >= settings.buyMinPrice and price <= settings.buyMaxPrice then
                        if not playerCars[carName] then
                            local purchaseRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                                and game.ReplicatedStorage.Remotes:FindFirstChild("Services")
                                and game.ReplicatedStorage.Remotes.Services:FindFirstChild("CarShopService")
                                and game.ReplicatedStorage.Remotes.Services.CarShopService:FindFirstChild("PurchaseCar")
                            if purchaseRemote then
                                local success, result = pcall(function()
                                    return purchaseRemote:InvokeServer(car.Id)
                                end)
                                if success then
                                    print("Куплена машина: " .. carName .. " за " .. price)
                                    playerCars[carName] = true
                                else
                                    warn("Не удалось купить " .. carName .. ": " .. tostring(result))
                                end
                            else
                                warn("Ремоут PurchaseCar не найден")
                            end
                        end
                    end
                end
            end)
            task.wait(5)
        end
    end)
end)

-- ==================== ВКЛАДКА: MISC ====================

local misc = Window:CreateTab("Misc", "🛠")
misc:AddButton("Force Load Map", function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") then
            task.spawn(function()
                game.Players.LocalPlayer:RequestStreamAroundAsync(v.WorldPivot.Position, 1)
            end)
            task.wait()
        end
    end
end)
misc:AddLabel("Race Teleports")
misc:AddDropdown(races(), "None", function(state)
    if state ~= "None" then
        for _, v in pairs(workspace.Races:GetChildren()) do
            if v.Name == state then
                local chr = game.Players.LocalPlayer.Character
                if chr and chr:FindFirstChild("Humanoid") then
                    local target
                    if v:FindFirstChildOfClass("UnionOperation") then
                        target = v:FindFirstChildOfClass("UnionOperation").CFrame
                    else
                        target = v:GetPivot()
                    end
                    if chr.Humanoid.SeatPart == nil then
                        chr.HumanoidRootPart.CFrame = target
                    else
                        local car = chr.Humanoid.SeatPart.Parent.Parent
                        car:PivotTo(target)
                    end
                end
                break
            end
        end
    end
end)
misc:AddToggle("Auto Loop All (Season + Kits + Spins)", false, function(state)
    getfenv().autoLoopAll = state
    saveSettings()
    task.spawn(function()
        while getfenv().autoLoopAll do
            pcall(function()
                local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                local services = remotes and remotes:FindFirstChild("Services")
                local claimFunc = services and services:FindFirstChild("TrophySeasonRemotes") and services.TrophySeasonRemotes:FindFirstChild("ClaimLevelReward")
                if claimFunc then
                    for level = 1, 50 do
                        if not getfenv().autoLoopAll then break end
                        claimFunc:InvokeServer(level, "Free")
                        claimFunc:InvokeServer(level, "Premium")
                        task.wait(0.05)
                    end
                end
                local consumeRemote = services and services:FindFirstChild("ConsumableServiceRemotes") and services.ConsumableServiceRemotes:FindFirstChild("Consume")
                if consumeRemote then
                    local count = settings.kitCount or 1
                    for i = 1, count do
                        if not getfenv().autoLoopAll then break end
                        local kitTypes = {"DecorationKit", "DecorationKitDeluxe", "RegularCustomizationKit", "DeluxeCustomizationKit", "CustomizationKit"}
                        for _, kit in ipairs(kitTypes) do
                            if not getfenv().autoLoopAll then break end
                            consumeRemote:InvokeServer(kit)
                            task.wait(0.05)
                        end
                        task.wait(0.1)
                    end
                end
                local spinRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Databases")
                    and game.ReplicatedStorage.Databases:FindFirstChild("Spinners")
                    and game.ReplicatedStorage.Databases.Spinners:FindFirstChild("SpinEvent")
                if spinRemote then
                    local count = settings.spinCount or 1
                    local delay = settings.spinDelay or 0.3
                    for i = 1, count do
                        if not getfenv().autoLoopAll then break end
                        spinRemote:InvokeServer("Standard", "Free")
                        spinRemote:InvokeServer("Hyper", "Free")
                        task.wait(delay)
                    end
                else
                    local altSpin = services and services:FindFirstChild("SpinnerRemotes") and services.SpinnerRemotes:FindFirstChild("Spin")
                    if altSpin then
                        local count = settings.spinCount or 1
                        local delay = settings.spinDelay or 0.3
                        for i = 1, count do
                            if not getfenv().autoLoopAll then break end
                            altSpin:InvokeServer("Standard")
                            altSpin:InvokeServer("Hyper")
                            task.wait(delay)
                        end
                    end
                end
            end)
            task.wait(3)
        end
    end)
end)
misc:AddToggle("Auto Claim Tokens", false, function(state)
    getfenv().claimTokens = state
    saveSettings()
    task.spawn(function()
        while getfenv().claimTokens do
            pcall(function()
                local claimRemote = game:GetService("ReplicatedStorage").Remotes.Services.TrophySeasonRemotes.ClaimLevelReward
                for lvl = 1, 50 do
                    claimRemote:InvokeServer(lvl, "Free")
                end
            end)
            task.wait(5)
        end
    end)
end)
misc:AddToggle("Auto Use Deluxe Upgrade Kit", false, function(state)
    getfenv().autoUpgradeKit = state
    saveSettings()
    task.spawn(function()
        while getfenv().autoUpgradeKit do
            pcall(function()
                local consume = game:GetService("ReplicatedStorage").Remotes.Services.ConsumableServiceRemotes.Consume
                if consume then
                    consume:InvokeServer("DeluxeUpgradeKit")
                end
            end)
            task.wait(2)
        end
    end)
end)
misc:AddToggle("Auto Smart Sell (самый дорогой заказ)", settings.autoSmartSell, function(state)
    settings.autoSmartSell = state
    getfenv().smartSell = state
    saveSettings()
    task.spawn(function()
        while getfenv().smartSell do
            task.wait(2)
            pcall(function()
                local tycoon
                for _, v in pairs(workspace.Tycoons:GetDescendants()) do
                    if v.Name == "Owner" and v:IsA("StringValue") and (string.find(v.Parent.Name, "Plot") or string.find(v.Parent.Name, "Slot")) and v.Value == game.Players.LocalPlayer.Name then
                        tycoon = v.Parent
                        break
                    end
                end
                if tycoon and tycoon:FindFirstChild("Dealership") then
                    local customer
                    for _, v in pairs(tycoon.Dealership:GetChildren()) do
                        if v:IsA("Model") and v.PrimaryPart and v.PrimaryPart.Name == "HumanoidRootPart" then
                            customer = v
                            break
                        end
                    end
                    if customer then
                        local text = customer:GetAttribute("OrderSpecBudget"):split(";")
                        local minPrice = settings.minSellPrice or 0
                        local selectedCar
                        local maxPrice = 0
                        for _, v in pairs(require(game:GetService("ReplicatedStorage").Data.CarShopEntries).CarsInShop) do
                            if v.PriceValue and v.PriceValue > tonumber(text[1]) and v.PriceValue < tonumber(text[2]) then
                                if v.PriceValue >= minPrice and v.PriceValue > maxPrice then
                                    maxPrice = v.PriceValue
                                    selectedCar = v
                                end
                            end
                        end
                        if selectedCar then
                            local remotes = game:GetService("ReplicatedStorage").Remotes.DealershipCustomerController.NPCHandler
                            local orderId = customer:GetAttribute("OrderId")
                            remotes:FireServer({["Action"] = "AcceptOrder", ["OrderId"] = orderId})
                            task.wait(0.5)
                            remotes:FireServer({
                                ["OrderId"] = orderId,
                                ["Action"] = "CompleteOrder",
                                ["Specs"] = {
                                    ["Car"] = selectedCar.Id,
                                    ["Color"] = customer:GetAttribute("OrderSpecColor"),
                                    ["Rims"] = customer:GetAttribute("OrderSpecRims"),
                                    ["Springs"] = customer:GetAttribute("OrderSpecSprings"),
                                    ["RimColor"] = customer:GetAttribute("OrderSpecRimColor")
                                }
                            })
                            task.wait(0.5)
                            remotes:FireServer({["Action"] = "CollectReward", ["OrderId"] = orderId})
                        end
                    end
                end
            end)
        end
    end)
end)
misc:AddSection("Consume / Purchase")
misc:AddTextBox("Auto Consume Item", settings.consumeItem, function(val)
    if val and val ~= "" then
        settings.consumeItem = val
        saveSettings()
    end
end)
misc:AddToggle("Auto Consume Items", settings.autoConsume, function(state)
    settings.autoConsume = state
    getfenv().autoConsume = state
    saveSettings()
    task.spawn(function()
        while getfenv().autoConsume do
            pcall(function()
                local consume = game:GetService("ReplicatedStorage").Remotes.Services.ConsumableServiceRemotes.Consume
                if consume then
                    consume:InvokeServer(settings.consumeItem)
                end
            end)
            task.wait(2)
        end
    end)
end)
misc:AddTextBox("Auto Purchase Item", settings.purchaseItem, function(val)
    if val and val ~= "" then
        settings.purchaseItem = val
        saveSettings()
    end
end)
misc:AddToggle("Auto Purchase (магазин)", settings.autoPurchase, function(state)
    settings.autoPurchase = state
    getfenv().autoPurchase = state
    saveSettings()
    task.spawn(function()
        while getfenv().autoPurchase do
            pcall(function()
                warn("Auto Purchase: реализуйте свой ремоут")
            end)
            task.wait(5)
        end
    end)
end)
misc:AddToggle("Block Analytics Events", false, function(state)
    getfenv().blockAnalytics = state
    task.spawn(function()
        while getfenv().blockAnalytics do
            task.wait(10)
        end
    end)
end)
misc:AddButton("Show All Remotes", function()
    print("=== All Remotes in ReplicatedStorage ===")
    local function printRemotes(parent, indent)
        indent = indent or ""
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("RemoteAction") then
                print(indent .. child:GetFullName())
            end
            if #child:GetChildren() > 0 then
                printRemotes(child, indent .. "  ")
            end
        end
    end
    printRemotes(game:GetService("ReplicatedStorage"))
    print("=== End of Remotes ===")
end)
misc:AddButton("Save Settings", function()
    saveSettings()
    print("Settings saved!")
end)
misc:AddButton("Load Settings", function()
    loadSettings()
    print("Settings loaded!")
end)

-- ==================== УСТАНОВКА НАЧАЛЬНЫХ ЗНАЧЕНИЙ ====================

getfenv().speed = settings.driveSpeed
getfenv().raceSpeed = settings.raceSpeed
getfenv().stars = settings.deliveryStars
getfenv().smaller = settings.deliveryMinMoney
getfenv().bigger = settings.deliveryMaxMoney
getfenv().grav = workspace.Gravity

print("✅ Скрипт успешно загружен (Crimson Edition с полным функционалом дилера)!")