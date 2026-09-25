--!strict
--[[
    ⚡ Fulgor ⚡
    Latin: "Fulgor" = 閃光・輝き・稲妻
    Original UI Library for Roblox
    
    Version: 1.1.8
    License: MIT
    
    Changelog v1.1.8:
      - Reverted to reliable GetMouseLocation + RenderStepped
      - Added exponential moving average smoothing to reduce stutter
    
    使い方:
    local Fulgor = loadstring(game:HttpGet("https://raw.githubusercontent.com/Bye-Bye-pass/Fulgor/main/Fulgor.luau"))()
    local Window = Fulgor:CreateWindow({ Title = "My Script" })
    local Tab = Window:CreateTab("Main")
    Tab:CreateSection("General"):CreateButton("Click", function()
        Fulgor:Notify({ Title = "⚡", Content = "Hello!" })
    end)
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--============================================================
-- Signal
--============================================================
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
    table.insert(self._handlers, fn)
    return {
        Disconnect = function()
            for i, h in ipairs(self._handlers) do
                if h == fn then table.remove(self._handlers, i) break end
            end
        end
    }
end

function Signal:Fire(...)
    for _, fn in ipairs(self._handlers) do
        task.spawn(fn, ...)
    end
end

--============================================================
-- Theme
--============================================================
local Themes = {
    Volt = {
        Background      = Color3.fromRGB(12, 12, 15),
        BackgroundAlt   = Color3.fromRGB(18, 18, 22),
        Surface         = Color3.fromRGB(24, 24, 28),
        SurfaceAlt      = Color3.fromRGB(30, 30, 35),
        SurfaceHover    = Color3.fromRGB(40, 40, 46),
        Primary         = Color3.fromRGB(245, 195, 30),
        PrimaryHover    = Color3.fromRGB(255, 215, 70),
        PrimaryDeep     = Color3.fromRGB(180, 130, 15),
        Glow            = Color3.fromRGB(255, 210, 60),
        Accent          = Color3.fromRGB(255, 235, 140),
        Text            = Color3.fromRGB(240, 240, 235),
        TextDim         = Color3.fromRGB(140, 140, 148),
        Border          = Color3.fromRGB(42, 42, 48),
        BorderLight     = Color3.fromRGB(60, 60, 68),
        Success         = Color3.fromRGB(76, 200, 120),
        Error           = Color3.fromRGB(230, 80, 90),
        Warning         = Color3.fromRGB(245, 195, 30),
    },
    Electric = {
        Background      = Color3.fromRGB(11, 14, 24),
        BackgroundAlt   = Color3.fromRGB(16, 20, 34),
        Surface         = Color3.fromRGB(24, 30, 48),
        SurfaceAlt      = Color3.fromRGB(30, 36, 58),
        SurfaceHover    = Color3.fromRGB(40, 48, 72),
        Primary         = Color3.fromRGB(88, 140, 255),
        PrimaryHover    = Color3.fromRGB(120, 165, 255),
        PrimaryDeep     = Color3.fromRGB(40, 80, 180),
        Glow            = Color3.fromRGB(100, 160, 255),
        Accent          = Color3.fromRGB(255, 220, 90),
        Text            = Color3.fromRGB(240, 244, 255),
        TextDim         = Color3.fromRGB(140, 150, 180),
        Border          = Color3.fromRGB(45, 55, 85),
        BorderLight     = Color3.fromRGB(65, 75, 110),
        Success         = Color3.fromRGB(76, 200, 120),
        Error           = Color3.fromRGB(230, 80, 90),
        Warning         = Color3.fromRGB(255, 210, 90),
    },
    Storm = {
        Background      = Color3.fromRGB(13, 10, 22),
        BackgroundAlt   = Color3.fromRGB(20, 16, 34),
        Surface         = Color3.fromRGB(28, 22, 46),
        SurfaceAlt      = Color3.fromRGB(35, 28, 56),
        SurfaceHover    = Color3.fromRGB(46, 38, 70),
        Primary         = Color3.fromRGB(170, 100, 240),
        PrimaryHover    = Color3.fromRGB(195, 140, 255),
        PrimaryDeep     = Color3.fromRGB(90, 45, 150),
        Glow            = Color3.fromRGB(190, 130, 255),
        Accent          = Color3.fromRGB(255, 220, 90),
        Text            = Color3.fromRGB(245, 240, 255),
        TextDim         = Color3.fromRGB(150, 140, 180),
        Border          = Color3.fromRGB(50, 42, 82),
        BorderLight     = Color3.fromRGB(75, 62, 115),
        Success         = Color3.fromRGB(76, 200, 120),
        Error           = Color3.fromRGB(230, 80, 90),
        Warning         = Color3.fromRGB(255, 210, 90),
    },
}

local Theme = {
    Current = Themes.Volt,
    Changed = Signal.new(),
}

function Theme.Get(key) return Theme.Current[key] end

function Theme.Set(name)
    Theme.Current = Themes[name] or Themes.Volt
    Theme.Changed:Fire(Theme.Current)
end

--============================================================
-- Utils
--============================================================
local Utils = {}

function Utils.Create(className, props, children)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

function Utils.Corner(radius)
    return Utils.Create("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

function Utils.Stroke(color, thickness)
    return Utils.Create("UIStroke", {
        Color = color or Theme.Get("Border"),
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

function Utils.Padding(px)
    return Utils.Create("UIPadding", {
        PaddingTop = UDim.new(0, px),
        PaddingBottom = UDim.new(0, px),
        PaddingLeft = UDim.new(0, px),
        PaddingRight = UDim.new(0, px),
    })
end

function Utils.Tween(inst, props, time, style, dir)
    local info = TweenInfo.new(
        time or 0.15,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(inst, info, props)
    tween:Play()
    return tween
end

local function grayKeypoint(time, factor)
    local c = math.clamp(factor or 1, 0, 1)
    return ColorSequenceKeypoint.new(time, Color3.new(c, c, c))
end

function Utils.ShadeV(parent, topFactor, bottomFactor)
    local grad = Instance.new("UIGradient")
    grad.Name = "FulgorShadeV"
    grad.Color = ColorSequence.new({
        grayKeypoint(0, topFactor or 1.0),
        grayKeypoint(1, bottomFactor or 0.75),
    })
    grad.Rotation = 90
    grad.Parent = parent
    return grad
end

function Utils.ColorGradientH(parent, colorA, colorB)
    local grad = Instance.new("UIGradient")
    grad.Name = "FulgorColorH"
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colorA),
        ColorSequenceKeypoint.new(1, colorB),
    })
    grad.Rotation = 0
    grad.Parent = parent
    return grad
end

--============================================================
-- Component 基底
--============================================================
local Component = {}
Component.__index = Component

function Component.new()
    local self = setmetatable({}, Component)
    self._connections = {}
    self._themeBindings = {}
    return self
end

function Component:Track(connection)
    table.insert(self._connections, connection)
    return connection
end

function Component:BindTheme(inst, property, tokenKey)
    table.insert(self._themeBindings, { inst = inst, prop = property, key = tokenKey })
    inst[property] = Theme.Get(tokenKey)
end

function Component:Destroy()
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    if self.Instance then self.Instance:Destroy() end
end

--============================================================
-- Window
--============================================================
local Window = setmetatable({}, { __index = Component })
Window.__index = Window

function Window.new(config)
    local self = Component.new()
    setmetatable(self, Window)

    config = config or {}
    local title = config.Title or "Fulgor"
    local size = config.Size or UDim2.fromOffset(620, 440)

    local screenGui = Utils.Create("ScreenGui", {
        Name = "Fulgor_" .. tostring(math.random(1, 1e6)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
    })
    self.ScreenGui = screenGui

    --=========================
    -- メイン
    --=========================
    local main = Utils.Create("Frame", {
        Name = "Main",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        AnchorPoint = Vector2.new(0, 0),
        Parent = screenGui,
    }, {
        Utils.Corner(12),
    })
    self:BindTheme(main, "BackgroundColor3", "Background")
    Utils.ShadeV(main, 1.0, 0.7)

    local glowStroke = Utils.Create("UIStroke", {
        Thickness = 1,
        Transparency = 0.55,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = main,
    })
    self:BindTheme(glowStroke, "Color", "Primary")

    --=========================
    -- ヘッダー
    --=========================
    local header = Utils.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = main,
    }, {
        Utils.Corner(12),
    })
    self:BindTheme(header, "BackgroundColor3", "Surface")

    local headerCornerFix = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = header,
    })
    self:BindTheme(headerCornerFix, "BackgroundColor3", "Surface")
    Utils.ShadeV(headerCornerFix, 1.0, 1.0)

    local headerGrad = Instance.new("UIGradient")
    headerGrad.Name = "HeaderGrad"
    headerGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Get("PrimaryDeep")),
        ColorSequenceKeypoint.new(0.45, Theme.Get("Surface")),
        ColorSequenceKeypoint.new(1, Theme.Get("Surface")),
    })
    headerGrad.Rotation = 0
    headerGrad.Parent = header

    local topLine = Utils.Create("Frame", {
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Parent = header,
    }, {
        Utils.Corner(1),
    })

    local accentLine = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Parent = header,
    })
    local accentGrad = Instance.new("UIGradient")
    accentGrad.Name = "AccentGrad"
    accentGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Get("Primary")),
        ColorSequenceKeypoint.new(0.5, Theme.Get("Primary")),
        ColorSequenceKeypoint.new(1, Theme.Get("Primary")),
    })
    accentGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    accentGrad.Rotation = 0
    accentGrad.Parent = accentLine

    local logo = Utils.Create("TextLabel", {
        Text = "⚡",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.fromOffset(14, 9),
        Parent = header,
    })
    self:BindTheme(logo, "TextColor3", "Primary")

    local titleLabel = Utils.Create("TextLabel", {
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.fromOffset(42, 0),
        Parent = header,
    })
    self:BindTheme(titleLabel, "TextColor3", "Text")

    local versionLabel = Utils.Create("TextLabel", {
        Text = "FULGOR",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(70, 24),
        Position = UDim2.new(1, -106, 0.5, -12),
        Parent = header,
    })
    self:BindTheme(versionLabel, "TextColor3", "Primary")

    local closeBtn = Utils.Create("TextButton", {
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -36, 0.5, -14),
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Parent = header,
    }, {
        Utils.Corner(6),
    })
    self:BindTheme(closeBtn, "TextColor3", "TextDim")

    self:Track(closeBtn.MouseEnter:Connect(function()
        Utils.Tween(closeBtn, {
            BackgroundColor3 = Theme.Get("Error"),
            TextColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0,
        })
    end))
    self:Track(closeBtn.MouseLeave:Connect(function()
        Utils.Tween(closeBtn, {
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            TextColor3 = Theme.Get("TextDim"),
            BackgroundTransparency = 0.5,
        })
    end))
    self:Track(closeBtn.Activated:Connect(function()
        Utils.Tween(main, { BackgroundTransparency = 1 }, 0.2)
        task.wait(0.2)
        main.Visible = false
        main.BackgroundTransparency = 0
    end))

    local sidebar = Utils.Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 140, 1, -50),
        Position = UDim2.fromOffset(10, 48),
        BackgroundTransparency = 1,
        Parent = main,
    }, {
        Utils.Create("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    self.Sidebar = sidebar

    local content = Utils.Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -170, 1, -60),
        Position = UDim2.fromOffset(160, 52),
        BackgroundTransparency = 1,
        Parent = main,
    })
    self.Content = content

    local footer = Utils.Create("TextLabel", {
        Text = "⚡ Fulgor  •  v1.1.8",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 1, -22),
        Parent = main,
    })
    self:BindTheme(footer, "TextColor3", "TextDim")

    self.Instance = main
    self.Tabs = {}
    self.ActiveTab = nil

    self:_setupDrag(main, header)

    self:Track(Theme.Changed:Connect(function()
        for _, binding in ipairs(self._themeBindings) do
            binding.inst[binding.prop] = Theme.Get(binding.key)
        end
        headerGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Get("PrimaryDeep")),
            ColorSequenceKeypoint.new(0.45, Theme.Get("Surface")),
            ColorSequenceKeypoint.new(1, Theme.Get("Surface")),
        })
        accentGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Get("Primary")),
            ColorSequenceKeypoint.new(0.5, Theme.Get("Primary")),
            ColorSequenceKeypoint.new(1, Theme.Get("Primary")),
        })
    end))

    return self
end

--============================================================
-- Smooth Drag (GetMouseLocation + RenderStepped + smoothing)
--============================================================
function Window:_setupDrag(main, handle)
    local dragging = false
    local dragStartMouse = Vector2.new(0, 0)
    local dragStartPos = UDim2.new(0, 0, 0, 0)
    local smoothX, smoothY = 0, 0

    self:Track(handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = true
        dragStartMouse = UserInputService:GetMouseLocation()
        dragStartPos = main.Position
        smoothX, smoothY = 0, 0
    end))

    self:Track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    self:Track(RunService.RenderStepped:Connect(function()
        if not dragging then return end
        local mouse = UserInputService:GetMouseLocation()
        local targetX = mouse.X - dragStartMouse.X
        local targetY = mouse.Y - dragStartMouse.Y

        -- 指数移動平均でスムージング（0.7 = 滑らかさ重視）
        smoothX = smoothX + (targetX - smoothX) * 0.7
        smoothY = smoothY + (targetY - smoothY) * 0.7

        main.Position = UDim2.new(
            dragStartPos.X.Scale, dragStartPos.X.Offset + smoothX,
            dragStartPos.Y.Scale, dragStartPos.Y.Offset + smoothY
        )
    end))
end

--============================================================
-- CreateTab / CreateSection
--============================================================
function Window:CreateTab(name)
    local tab = {}

    local btn = Utils.Create("TextButton", {
        Text = "  " .. name,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 32),
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Get("Surface"),
        TextColor3 = Theme.Get("TextDim"),
        Parent = self.Sidebar,
    }, {
        Utils.Corner(6),
    })

    local tabGrad = Instance.new("UIGradient")
    tabGrad.Name = "TabGrad"
    tabGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.85, 0.85, 0.85)),
    })
    tabGrad.Rotation = 90
    tabGrad.Parent = btn

    local function setInactive()
        Utils.Tween(btn, {
            BackgroundColor3 = Theme.Get("Surface"),
            TextColor3 = Theme.Get("TextDim"),
        })
        tabGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0.85, 0.85, 0.85)),
        })
    end

    local function setActive()
        Utils.Tween(btn, {
            BackgroundColor3 = Theme.Get("Primary"),
            TextColor3 = Theme.Get("Background"),
        })
        tabGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0.8, 0.8, 0.8)),
        })
    end

    local container = Utils.Create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Get("Primary"),
        ScrollBarImageTransparency = 0.3,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Content,
    }, {
        Utils.Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local function activate()
        for _, t in ipairs(self.Tabs) do
            t.Container.Visible = false
            t.SetInactive()
        end
        container.Visible = true
        setActive()
        self.ActiveTab = tab
    end

    self:Track(btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Utils.Tween(btn, { BackgroundColor3 = Theme.Get("SurfaceHover") })
        end
    end))
    self:Track(btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Utils.Tween(btn, { BackgroundColor3 = Theme.Get("Surface") })
        end
    end))
    self:Track(btn.Activated:Connect(activate))

    tab.Button = btn
    tab.Container = container
    tab.Name = name
    tab.SetInactive = setInactive
    tab.SetActive = setActive

    function tab:CreateSection(sectionName)
        local section = {}
        local frame = Utils.Create("Frame", {
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = container,
        }, {
            Utils.Create("UIListLayout", {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })

        local headerRow = Utils.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Parent = frame,
        })

        local bullet = Utils.Create("Frame", {
            Size = UDim2.fromOffset(3, 14),
            Position = UDim2.fromOffset(0, 4),
            BackgroundColor3 = Theme.Get("Primary"),
            BorderSizePixel = 0,
            Parent = headerRow,
        }, {
            Utils.Corner(2),
        })

        local headerLabel = Utils.Create("TextLabel", {
            Text = sectionName:upper(),
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.fromOffset(10, 0),
            Parent = headerRow,
        })
        headerLabel.TextColor3 = Theme.Get("Primary")

        local body = Utils.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = frame,
        }, {
            Utils.Create("UIListLayout", {
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })

        section.Instance = frame
        section.Body = body
        attachSectionMethods(section)
        return section
    end

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then activate() end

    return tab
end

--============================================================
-- Components
--============================================================
local Components = {}

function Components.Button(section, text, callback)
    local btn = Utils.Create("TextButton", {
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        Size = UDim2.new(1, 0, 0, 36),
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Get("Surface"),
        TextColor3 = Theme.Get("Text"),
        Parent = section.Body,
    }, {
        Utils.Corner(6),
        Utils.Stroke(),
    })
    Utils.ShadeV(btn, 1.0, 0.85)

    btn.MouseEnter:Connect(function()
        Utils.Tween(btn, {
            BackgroundColor3 = Theme.Get("Primary"),
            TextColor3 = Theme.Get("Background"),
        })
    end)
    btn.MouseLeave:Connect(function()
        Utils.Tween(btn, {
            BackgroundColor3 = Theme.Get("Surface"),
            TextColor3 = Theme.Get("Text"),
        })
    end)
    btn.Activated:Connect(function()
        if callback then task.spawn(callback) end
    end)
    return btn
end

function Components.Toggle(section, text, default, callback)
    local state = default or false

    local frame = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Parent = section.Body,
    })

    local label = Utils.Create("TextLabel", {
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 1, 0),
        Parent = frame,
    })
    label.TextColor3 = Theme.Get("Text")

    local toggle = Utils.Create("TextButton", {
        Text = "",
        Size = UDim2.fromOffset(46, 24),
        Position = UDim2.new(1, -46, 0.5, -12),
        AutoButtonColor = false,
        BackgroundColor3 = state and Theme.Get("Primary") or Theme.Get("Surface"),
        Parent = frame,
    }, {
        Utils.Corner(12),
        Utils.Stroke(),
    })
    Utils.ShadeV(toggle, 1.0, 0.85)

    local knob = Utils.Create("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.fromOffset(3, 3),
        BackgroundColor3 = state and Theme.Get("Background") or Color3.fromRGB(210, 210, 210),
        Parent = toggle,
    }, {
        Utils.Corner(9),
    })
    Utils.ShadeV(knob, 1.0, 0.85)

    local function update()
        Utils.Tween(toggle, {
            BackgroundColor3 = state and Theme.Get("Primary") or Theme.Get("Surface"),
        })
        Utils.Tween(knob, {
            Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = state and Theme.Get("Background") or Color3.fromRGB(210, 210, 210),
        })
    end

    toggle.Activated:Connect(function()
        state = not state
        update()
        if callback then task.spawn(callback, state) end
    end)

    return {
        Instance = frame,
        Set = function(v) state = v; update() end,
        Get = function() return state end,
    }
end

function Components.Slider(section, text, min, max, default, callback)
    min = min or 0
    max = max or 100
    local value = default or min

    local frame = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = section.Body,
    })

    local label = Utils.Create("TextLabel", {
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.7, 0, 0, 20),
        Parent = frame,
    })
    label.TextColor3 = Theme.Get("Text")

    local valueLabel = Utils.Create("TextLabel", {
        Text = tostring(value),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.3, 0, 0, 20),
        Position = UDim2.new(0.7, 0, 0, 0),
        Parent = frame,
    })
    valueLabel.TextColor3 = Theme.Get("Primary")

    local bar = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.fromOffset(0, 30),
        BackgroundColor3 = Theme.Get("Surface"),
        Parent = frame,
    }, {
        Utils.Corner(4),
    })
    Utils.ShadeV(bar, 0.8, 1.0)

    local fill = Utils.Create("Frame", {
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Get("Primary"),
        Parent = bar,
    }, {
        Utils.Corner(4),
    })
    Utils.ColorGradientH(fill, Theme.Get("Primary"), Theme.Get("PrimaryHover"))

    local dragging = false

    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        valueLabel.Text = tostring(value)
        if callback then task.spawn(callback, value) end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {
        Instance = frame,
        Set = function(v)
            value = math.clamp(v, min, max)
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            valueLabel.Text = tostring(value)
        end,
        Get = function() return value end,
    }
end

function Components.Textbox(section, placeholder, callback)
    local box = Utils.Create("TextBox", {
        Text = "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Theme.Get("TextDim"),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Get("Surface"),
        TextColor3 = Theme.Get("Text"),
        Parent = section.Body,
    }, {
        Utils.Corner(6),
        Utils.Stroke(),
        Utils.Padding(10),
    })

    box.Focused:Connect(function()
        Utils.Tween(box, { BackgroundColor3 = Theme.Get("SurfaceHover") })
    end)
    box.FocusLost:Connect(function(enterPressed)
        Utils.Tween(box, { BackgroundColor3 = Theme.Get("Surface") })
        if callback then task.spawn(callback, box.Text, enterPressed) end
    end)
    return box
end

function Components.Dropdown(section, text, options, callback)
    local selected = options[1]
    local expanded = false

    local frame = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Parent = section.Body,
    })

    local header = Utils.Create("TextButton", {
        Text = text .. ": " .. tostring(selected),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Get("Surface"),
        TextColor3 = Theme.Get("Text"),
        AutoButtonColor = false,
        Parent = frame,
    }, {
        Utils.Corner(6),
        Utils.Stroke(),
        Utils.Padding(10),
    })

    local list = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = Theme.Get("Surface"),
        Visible = false,
        ZIndex = 5,
        Parent = frame,
    }, {
        Utils.Corner(6),
        Utils.Stroke(),
        Utils.Create("UIListLayout", {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        Utils.Padding(4),
    })
    list.AutomaticSize = Enum.AutomaticSize.Y

    for i, opt in ipairs(options) do
        local item = Utils.Create("TextButton", {
            Text = "  " .. tostring(opt),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = Theme.Get("Surface"),
            TextColor3 = Theme.Get("Text"),
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 6,
            Parent = list,
        }, {
            Utils.Corner(4),
        })

        item.MouseEnter:Connect(function()
            Utils.Tween(item, {
                BackgroundColor3 = Theme.Get("Primary"),
                TextColor3 = Theme.Get("Background"),
            })
        end)
        item.MouseLeave:Connect(function()
            Utils.Tween(item, {
                BackgroundColor3 = Theme.Get("Surface"),
                TextColor3 = Theme.Get("Text"),
            })
        end)
        item.Activated:Connect(function()
            selected = opt
            header.Text = text .. ": " .. tostring(selected)
            expanded = false
            list.Visible = false
            if callback then task.spawn(callback, selected) end
        end)
    end

    header.Activated:Connect(function()
        expanded = not expanded
        list.Visible = expanded
    end)

    return {
        Instance = frame,
        Set = function(v)
            selected = v
            header.Text = text .. ": " .. tostring(v)
        end,
        Get = function() return selected end,
    }
end

function Components.Label(section, text)
    local label = Utils.Create("TextLabel", {
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = section.Body,
    })
    label.TextColor3 = Theme.Get("Text")
    return label
end

function Components.Keybind(section, text, default, callback)
    local key = default or Enum.KeyCode.Unknown
    local listening = false

    local frame = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Parent = section.Body,
    })

    local label = Utils.Create("TextLabel", {
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -90, 1, 0),
        Parent = frame,
    })
    label.TextColor3 = Theme.Get("Text")

    local btn = Utils.Create("TextButton", {
        Text = key == Enum.KeyCode.Unknown and "None" or key.Name,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Size = UDim2.fromOffset(80, 26),
        Position = UDim2.new(1, -80, 0.5, -13),
        BackgroundColor3 = Theme.Get("Surface"),
        TextColor3 = Theme.Get("Text"),
        AutoButtonColor = false,
        Parent = frame,
    }, {
        Utils.Corner(6),
        Utils.Stroke(),
    })

    btn.Activated:Connect(function()
        listening = true
        btn.Text = "..."
        btn.TextColor3 = Theme.Get("Primary")
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not listening then return end
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            key = input.KeyCode
            btn.Text = key.Name
            btn.TextColor3 = Theme.Get("Text")
            listening = false
            if callback then task.spawn(callback, key) end
        end
    end)

    return {
        Instance = frame,
        Get = function() return key end,
    }
end

--============================================================
-- Section にメソッド付与
--============================================================
function attachSectionMethods(section)
    section.CreateButton   = function(_, text, cb) return Components.Button(section, text, cb) end
    section.CreateToggle   = function(_, text, def, cb) return Components.Toggle(section, text, def, cb) end
    section.CreateSlider   = function(_, text, min, max, def, cb) return Components.Slider(section, text, min, max, def, cb) end
    section.CreateTextbox  = function(_, ph, cb) return Components.Textbox(section, ph, cb) end
    section.CreateDropdown = function(_, text, opts, cb) return Components.Dropdown(section, text, opts, cb) end
    section.CreateLabel    = function(_, text) return Components.Label(section, text) end
    section.CreateKeybind  = function(_, text, def, cb) return Components.Keybind(section, text, def, cb) end
end

--============================================================
-- 公開API
--============================================================
local Fulgor = {}
Fulgor.__index = Fulgor
Fulgor.Name = "Fulgor"
Fulgor.Icon = "⚡"
Fulgor.Version = "1.1.8"
Fulgor.Themes = Themes

function Fulgor:CreateWindow(config)
    config = config or {}
    config.Title = config.Title or "Fulgor"
    if config.Theme then Theme.Set(config.Theme) end
    return Window.new(config)
end

function Fulgor:SetTheme(name) Theme.Set(name) end
function Fulgor:GetTheme() return Theme.Current end

function Fulgor:GetThemeList()
    local list = {}
    for k in pairs(Themes) do table.insert(list, k) end
    return list
end

-- 通知
local _notifCount = 0

function Fulgor:Notify(config)
    config = config or {}
    local title = config.Title or "⚡ Fulgor"
    local content = config.Content or ""
    local duration = config.Duration or 4

    local parent = LocalPlayer:WaitForChild("PlayerGui")
    local index = _notifCount
    _notifCount = _notifCount + 1

    local notif = Utils.Create("Frame", {
        Size = UDim2.fromOffset(300, 72),
        Position = UDim2.new(1, -320, 0, 20 + index * 82),
        BackgroundColor3 = Theme.Get("Surface"),
        Parent = parent,
    }, {
        Utils.Corner(8),
        Utils.Stroke(),
    })
    Utils.ShadeV(notif, 1.0, 0.85)

    local accent = Utils.Create("Frame", {
        Size = UDim2.new(0, 4, 1, -16),
        Position = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Theme.Get("Primary"),
        BorderSizePixel = 0,
        Parent = notif,
    }, {
        Utils.Corner(2),
    })
    Utils.ShadeV(accent, 1.0, 0.6)

    local titleLabel = Utils.Create("TextLabel", {
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 20),
        Position = UDim2.fromOffset(22, 8),
        Parent = notif,
    })
    titleLabel.TextColor3 = Theme.Get("Primary")

    local contentLabel = Utils.Create("TextLabel", {
        Text = content,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 30),
        Position = UDim2.fromOffset(22, 32),
        Parent = notif,
    })
    contentLabel.TextColor3 = Theme.Get("Text")

    task.delay(duration, function()
        Utils.Tween(notif, { BackgroundTransparency = 1 }, 0.3)
        Utils.Tween(accent, { BackgroundTransparency = 1 }, 0.3)
        Utils.Tween(titleLabel, { TextTransparency = 1 }, 0.3)
        Utils.Tween(contentLabel, { TextTransparency = 1 }, 0.3)
        task.wait(0.35)
        notif:Destroy()
        _notifCount = math.max(0, _notifCount - 1)
    end)
end

return Fulgor
