--[[
    ██████╗  ██████╗  ██████╗ ██╗     ███████╗ █████╗ ███╗   ██╗
    ██╔══██╗██╔═══██╗██╔═══██╗██║     ██╔════╝██╔══██╗████╗  ██║
    ██████╔╝██║   ██║██║   ██║██║     █████╗  ███████║██╔██╗ ██║
    ██╔══██╗██║   ██║██║   ██║██║     ██╔══╝  ██╔══██║██║╚██╗██║
    ██████╔╝╚██████╔╝╚██████╔╝███████╗███████╗██║  ██║██║ ╚████║
    ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝

    Boolean UI Library  •  v1.0.0
    A clean, modern, client-sided UI library for Roblox (LocalScript / ModuleScript).

    Elements:
        Window  : CreateTab, Notify, Toggle, SetToggleKey, Minimize, SelectTab, Destroy
        Tab     : CreateSection, CreateButton, CreateToggle, CreateSlider, CreateDropdown,
                  CreateInput, CreateKeybind, CreateColorPicker, CreateLabel, CreateParagraph

    Themes: Midnight (default), Ocean, Rose, Emerald, Amber, Light
]]

local Boolean = {}
Boolean.Version = "1.0.0"

--// Services
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService      = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

--// Fonts
local FONT        = Enum.Font.Gotham
local FONT_MEDIUM = Enum.Font.GothamMedium
local FONT_BOLD   = Enum.Font.GothamBold

--// Themes
Boolean.Themes = {
    Midnight = {
        Background   = Color3.fromRGB(15, 16, 21),
        Sidebar      = Color3.fromRGB(20, 21, 28),
        Element      = Color3.fromRGB(25, 26, 35),
        ElementHover = Color3.fromRGB(32, 34, 45),
        Stroke       = Color3.fromRGB(40, 42, 56),
        Text         = Color3.fromRGB(236, 238, 246),
        SubText      = Color3.fromRGB(135, 140, 162),
        Accent       = Color3.fromRGB(112, 96, 255),
        Off          = Color3.fromRGB(46, 48, 64),
    },
    Ocean = {
        Background   = Color3.fromRGB(12, 18, 26),
        Sidebar      = Color3.fromRGB(16, 23, 33),
        Element      = Color3.fromRGB(21, 30, 43),
        ElementHover = Color3.fromRGB(27, 38, 54),
        Stroke       = Color3.fromRGB(35, 50, 70),
        Text         = Color3.fromRGB(232, 242, 252),
        SubText      = Color3.fromRGB(125, 148, 175),
        Accent       = Color3.fromRGB(0, 170, 255),
        Off          = Color3.fromRGB(40, 55, 76),
    },
    Rose = {
        Background   = Color3.fromRGB(20, 14, 18),
        Sidebar      = Color3.fromRGB(26, 18, 23),
        Element      = Color3.fromRGB(33, 23, 30),
        ElementHover = Color3.fromRGB(42, 29, 38),
        Stroke       = Color3.fromRGB(58, 40, 52),
        Text         = Color3.fromRGB(250, 236, 243),
        SubText      = Color3.fromRGB(170, 135, 155),
        Accent       = Color3.fromRGB(255, 88, 138),
        Off          = Color3.fromRGB(60, 42, 54),
    },
    Emerald = {
        Background   = Color3.fromRGB(12, 19, 16),
        Sidebar      = Color3.fromRGB(16, 25, 21),
        Element      = Color3.fromRGB(21, 32, 27),
        ElementHover = Color3.fromRGB(27, 41, 35),
        Stroke       = Color3.fromRGB(36, 54, 46),
        Text         = Color3.fromRGB(232, 248, 240),
        SubText      = Color3.fromRGB(125, 165, 145),
        Accent       = Color3.fromRGB(40, 205, 130),
        Off          = Color3.fromRGB(40, 58, 50),
    },
    Amber = {
        Background   = Color3.fromRGB(19, 16, 12),
        Sidebar      = Color3.fromRGB(25, 21, 16),
        Element      = Color3.fromRGB(32, 27, 20),
        ElementHover = Color3.fromRGB(41, 35, 26),
        Stroke       = Color3.fromRGB(56, 48, 36),
        Text         = Color3.fromRGB(250, 244, 232),
        SubText      = Color3.fromRGB(170, 155, 125),
        Accent       = Color3.fromRGB(255, 170, 40),
        Off          = Color3.fromRGB(58, 50, 38),
    },
    Light = {
        Background   = Color3.fromRGB(244, 245, 250),
        Sidebar      = Color3.fromRGB(234, 236, 243),
        Element      = Color3.fromRGB(255, 255, 255),
        ElementHover = Color3.fromRGB(246, 247, 252),
        Stroke       = Color3.fromRGB(218, 221, 232),
        Text         = Color3.fromRGB(28, 30, 40),
        SubText      = Color3.fromRGB(110, 115, 135),
        Accent       = Color3.fromRGB(100, 84, 245),
        Off          = Color3.fromRGB(205, 208, 222),
    },
}

----------------------------------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------------------------------

local function create(className, props, children)
    local inst = Instance.new(className)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if parent then inst.Parent = parent end
    return inst
end

local function tween(obj, duration, props, style, direction)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(duration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function corner(radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

local function round()
    return create("UICorner", { CornerRadius = UDim.new(1, 0) })
end

local function stroke(color, thickness, transparency)
    return create("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function padding(top, right, bottom, left)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        PaddingLeft = UDim.new(0, left or right or top or 0),
    })
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local args = { ... }
    local n = select("#", ...)
    task.spawn(function()
        local ok, err = pcall(fn, unpack(args, 1, n))
        if not ok then
            warn("[Boolean] Callback error: " .. tostring(err))
        end
    end)
end

local function textWidth(str, size, font)
    return TextService:GetTextSize(str, size, font, Vector2.new(10000, 100)).X
end

local function ripple(parent, color)
    local mouse = UserInputService:GetMouseLocation()
    local pos = parent.AbsolutePosition
    local circle = create("Frame", {
        Name = "Ripple",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(mouse.X - pos.X, mouse.Y - pos.Y),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.75,
        ZIndex = 5,
        Parent = parent,
    }, { round() })
    local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.2
    tween(circle, 0.55, { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 })
    task.delay(0.6, function() circle:Destroy() end)
end

local function decimalsOf(n)
    local s = tostring(n)
    local dot = string.find(s, "%.")
    if not dot then return 0 end
    return #s - dot
end

----------------------------------------------------------------------------------------------------
-- Classes
----------------------------------------------------------------------------------------------------

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

function Window:_track(connection)
    table.insert(self.Connections, connection)
    return connection
end

-- Smooth dragging for any handle -> target
function Window:_makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)
    self:_track(UserInputService.InputEnded:Connect(function(input)
        if isPress(input) then dragging = false end
    end))
    self:_track(UserInputService.InputChanged:Connect(function(input)
        if dragging and isMove(input) then
            local delta = input.Position - dragStart
            tween(target, 0.14, {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                ),
            })
        end
    end))
end

-- Generic press-and-drag used by sliders and color pickers
function Window:_bindDrag(guiObject, onMove, onRelease)
    local dragging = false
    guiObject.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true
            onMove(input.Position)
        end
    end)
    self:_track(UserInputService.InputChanged:Connect(function(input)
        if dragging and isMove(input) then onMove(input.Position) end
    end))
    self:_track(UserInputService.InputEnded:Connect(function(input)
        if dragging and isPress(input) then
            dragging = false
            if onRelease then onRelease() end
        end
    end))
end

----------------------------------------------------------------------------------------------------
-- Window
----------------------------------------------------------------------------------------------------

function Boolean:CreateWindow(config)
    config = config or {}

    local base = Boolean.Themes[config.Theme or "Midnight"] or Boolean.Themes.Midnight
    local T = {}
    for k, v in pairs(base) do T[k] = v end
    if config.Accent then T.Accent = config.Accent end

    local self = setmetatable({
        Theme = T,
        Tabs = {},
        Flags = {},
        Connections = {},
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        Visible = true,
        Minimized = false,
        Size = config.Size or UDim2.fromOffset(600, 410),
        SidebarWidth = 170,
    }, Window)
    Boolean.Flags = self.Flags

    -- ScreenGui
    local gui = create("ScreenGui", {
        Name = "Boolean",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    gui.Parent = config.Parent or LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = gui

    -- Holder (for shadow + scaling)
    local holder = create("Frame", {
        Name = "Holder",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = self.Size,
        BackgroundTransparency = 1,
        Parent = gui,
    })
    local scale = create("UIScale", { Scale = 0.9, Parent = holder })
    self.Holder, self.Scale = holder, scale

    create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 60, 1, 60),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.45,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0,
        Parent = holder,
    })

    local main = create("Frame", {
        Name = "Main",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = T.Background,
        ClipsDescendants = true,
        Parent = holder,
    }, { corner(10), stroke(T.Stroke, 1) })
    self.Main = main

    -- Sidebar --------------------------------------------------------------------------------
    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, self.SidebarWidth, 1, 0),
        BackgroundColor3 = T.Sidebar,
        Parent = main,
    }, { corner(10) })
    -- square off the right edge of the sidebar
    create("Frame", {
        Name = "Filler",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 12, 1, 0),
        BackgroundColor3 = T.Sidebar,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    create("Frame", {
        Name = "Divider",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = T.Stroke,
        BorderSizePixel = 0,
        Parent = sidebar,
    })

    -- Logo: a little "true" switch, because Boolean.
    local logo = create("Frame", {
        Name = "Logo",
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })
    local logoSwitch = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 16, 0.5, 0),
        Size = UDim2.fromOffset(30, 17),
        BackgroundColor3 = T.Accent,
        Parent = logo,
    }, { round() })
    create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -3, 0.5, 0),
        Size = UDim2.fromOffset(11, 11),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = logoSwitch,
    }, { round() })
    create("TextLabel", {
        Position = UDim2.fromOffset(54, 13),
        Size = UDim2.new(1, -62, 0, 18),
        BackgroundTransparency = 1,
        Font = FONT_BOLD,
        Text = config.Title or "Boolean",
        TextColor3 = T.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = logo,
    })
    create("TextLabel", {
        Position = UDim2.fromOffset(54, 31),
        Size = UDim2.new(1, -62, 0, 14),
        BackgroundTransparency = 1,
        Font = FONT,
        Text = config.Subtitle or ("v" .. Boolean.Version),
        TextColor3 = T.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = logo,
    })
    create("Frame", {
        Position = UDim2.new(0, 14, 0, 58),
        Size = UDim2.new(1, -28, 0, 1),
        BackgroundColor3 = T.Stroke,
        BorderSizePixel = 0,
        Parent = sidebar,
    })

    local tabList = create("ScrollingFrame", {
        Name = "TabList",
        Position = UDim2.fromOffset(0, 66),
        Size = UDim2.new(1, -1, 1, -66 - 58),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = sidebar,
    }, {
        create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
        padding(4, 10, 4, 10),
    })
    self.TabList = tabList

    -- Player card
    local profile = create("Frame", {
        Name = "Profile",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 10, 1, -10),
        Size = UDim2.new(1, -21, 0, 44),
        BackgroundColor3 = T.Element,
        Parent = sidebar,
    }, { corner(8), stroke(T.Stroke, 1) })
    local avatar = create("ImageLabel", {
        Position = UDim2.fromOffset(7, 7),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = T.Off,
        Image = "",
        Parent = profile,
    }, { round() })
    create("TextLabel", {
        Position = UDim2.fromOffset(44, 7),
        Size = UDim2.new(1, -50, 0, 15),
        BackgroundTransparency = 1,
        Font = FONT_MEDIUM,
        Text = LocalPlayer.DisplayName,
        TextColor3 = T.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = profile,
    })
    create("TextLabel", {
        Position = UDim2.fromOffset(44, 22),
        Size = UDim2.new(1, -50, 0, 14),
        BackgroundTransparency = 1,
        Font = FONT,
        Text = "@" .. LocalPlayer.Name,
        TextColor3 = T.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = profile,
    })
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
        if ok and avatar.Parent then avatar.Image = img end
    end)

    -- Topbar ---------------------------------------------------------------------------------
    local topbar = create("Frame", {
        Name = "Topbar",
        Position = UDim2.fromOffset(self.SidebarWidth, 0),
        Size = UDim2.new(1, -self.SidebarWidth, 0, 48),
        BackgroundTransparency = 1,
        Parent = main,
    })
    self.TabTitle = create("TextLabel", {
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(1, -110, 1, 0),
        BackgroundTransparency = 1,
        Font = FONT_BOLD,
        Text = "",
        TextColor3 = T.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar,
    })
    create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = T.Stroke,
        BorderSizePixel = 0,
        Parent = topbar,
    })

    local function topButton(order, build)
        local btn = create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10 - (order * 34), 0.5, 0),
            Size = UDim2.fromOffset(30, 30),
            BackgroundColor3 = T.Element,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Parent = topbar,
        }, { corner(6) })
        build(btn)
        btn.MouseEnter:Connect(function() tween(btn, 0.2, { BackgroundTransparency = 0 }) end)
        btn.MouseLeave:Connect(function() tween(btn, 0.2, { BackgroundTransparency = 1 }) end)
        return btn
    end

    local closeBtn = topButton(0, function(btn)
        for _, rot in ipairs({ 45, -45 }) do
            create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(13, 2),
                Rotation = rot,
                BackgroundColor3 = T.SubText,
                BorderSizePixel = 0,
                Parent = btn,
            }, { round() })
        end
    end)
    local minBtn = topButton(1, function(btn)
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(12, 2),
            BackgroundColor3 = T.SubText,
            BorderSizePixel = 0,
            Parent = btn,
        }, { round() })
    end)
    closeBtn.MouseButton1Click:Connect(function()
        safeCall(config.OnClose)
        self:Destroy()
    end)
    minBtn.MouseButton1Click:Connect(function() self:Minimize() end)

    -- Content area
    self.Content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(self.SidebarWidth, 48),
        Size = UDim2.new(1, -self.SidebarWidth, 1, -48),
        BackgroundTransparency = 1,
        Parent = main,
    })

    self:_makeDraggable(topbar, holder)
    self:_makeDraggable(logo, holder)

    -- Notifications
    self.NotifyHolder = create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.new(0, 290, 1, -36),
        BackgroundTransparency = 1,
        Parent = gui,
    }, {
        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    -- Toggle key
    self:_track(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if self.ToggleKey and input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end))

    -- Mobile toggle button
    local wantsMobileButton = config.MobileButton
    if wantsMobileButton == nil then
        wantsMobileButton = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    end
    if wantsMobileButton then
        local mobile = create("TextButton", {
            Name = "MobileToggle",
            Position = UDim2.new(0, 20, 0.5, -24),
            Size = UDim2.fromOffset(48, 48),
            BackgroundColor3 = T.Sidebar,
            AutoButtonColor = false,
            Font = FONT_BOLD,
            Text = "B",
            TextColor3 = T.Accent,
            TextSize = 20,
            Parent = gui,
        }, { round(), stroke(T.Accent, 1.5, 0.3) })
        self:_makeDraggable(mobile, mobile)
        local pressPos
        mobile.InputBegan:Connect(function(input)
            if isPress(input) then pressPos = input.Position end
        end)
        mobile.InputEnded:Connect(function(input)
            if isPress(input) and pressPos and (input.Position - pressPos).Magnitude < 8 then
                self:Toggle()
            end
        end)
    end

    -- Open animation
    main.BackgroundTransparency = 1
    tween(scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
    tween(main, 0.3, { BackgroundTransparency = 0 })

    return self
end

function Window:Toggle(state)
    if state == nil then state = not self.Visible end
    self.Visible = state
    if state then
        self.Holder.Visible = true
        self.Scale.Scale = 0.94
        tween(self.Scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
    else
        tween(self.Scale, 0.18, { Scale = 0.94 })
        task.delay(0.15, function()
            if not self.Visible and self.Holder then self.Holder.Visible = false end
        end)
    end
end

function Window:SetToggleKey(key)
    self.ToggleKey = key
end

function Window:Minimize(state)
    if state == nil then state = not self.Minimized end
    self.Minimized = state
    local s = self.Size
    tween(self.Holder, 0.35, {
        Size = state and UDim2.new(s.X.Scale, s.X.Offset, 0, 58) or s,
    })
end

function Window:Destroy()
    for _, c in ipairs(self.Connections) do
        pcall(function() c:Disconnect() end)
    end
    self.Connections = {}
    if self.Gui then
        local gui = self.Gui
        self.Gui = nil
        tween(self.Scale, 0.2, { Scale = 0.9 })
        tween(self.Main, 0.2, { BackgroundTransparency = 1 })
        task.delay(0.2, function() gui:Destroy() end)
    end
end

function Window:Notify(cfg)
    cfg = cfg or {}
    local T = self.Theme
    local duration = cfg.Duration or 4

    local wrap = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = self.NotifyHolder,
    })
    local card = create("Frame", {
        Position = UDim2.fromOffset(320, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.Sidebar,
        ClipsDescendants = true,
        Parent = wrap,
    }, { corner(8), stroke(T.Stroke, 1) })
    create("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Parent = card,
    })
    local body = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = card,
    }, {
        padding(12, 14, 15, 18),
        create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    create("TextLabel", {
        LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = FONT_BOLD,
        Text = cfg.Title or "Notification",
        TextColor3 = T.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = body,
    })
    create("TextLabel", {
        LayoutOrder = 2,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = FONT,
        Text = cfg.Content or "",
        TextColor3 = T.SubText,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = body,
    })
    local bar = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Parent = card,
    })

    tween(card, 0.45, { Position = UDim2.fromOffset(0, 0) })
    tween(bar, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        tween(card, 0.35, { Position = UDim2.fromOffset(320, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.wait(0.36)
        wrap:Destroy()
    end)
end

----------------------------------------------------------------------------------------------------
-- Tabs
----------------------------------------------------------------------------------------------------

function Window:CreateTab(name, icon)
    local T = self.Theme
    local tab = setmetatable({ Window = self, Name = name or "Tab", Order = 0 }, Tab)

    local btn = create("TextButton", {
        Name = tab.Name,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = T.Element,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = #self.Tabs + 1,
        Parent = self.TabList,
    }, { corner(7) })
    local indicator = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(3, 0),
        BackgroundColor3 = T.Accent,
        Parent = btn,
    }, { round() })

    local textX = 14
    local iconImg
    if icon then
        iconImg = create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = T.SubText,
            Parent = btn,
        })
        textX = 36
    end
    local label = create("TextLabel", {
        Position = UDim2.fromOffset(textX, 0),
        Size = UDim2.new(1, -textX - 8, 1, 0),
        BackgroundTransparency = 1,
        Font = FONT_MEDIUM,
        Text = tab.Name,
        TextColor3 = T.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = btn,
    })

    local page = create("ScrollingFrame", {
        Name = tab.Name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Stroke,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Content,
    }, {
        create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }),
        padding(14, 16, 14, 16),
    })

    tab.Button, tab.Page, tab.Indicator, tab.Label, tab.Icon = btn, page, indicator, label, iconImg

    btn.MouseEnter:Connect(function()
        if self.CurrentTab ~= tab then tween(label, 0.2, { TextColor3 = T.Text }) end
    end)
    btn.MouseLeave:Connect(function()
        if self.CurrentTab ~= tab then tween(label, 0.2, { TextColor3 = T.SubText }) end
    end)
    btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then self:SelectTab(tab) end
    return tab
end

function Window:SelectTab(tab)
    if self.CurrentTab == tab then return end
    local T = self.Theme
    for _, t in ipairs(self.Tabs) do
        local on = (t == tab)
        tween(t.Button, 0.25, { BackgroundTransparency = on and 0 or 1 })
        tween(t.Indicator, 0.25, { Size = UDim2.fromOffset(3, on and 16 or 0) })
        tween(t.Label, 0.25, { TextColor3 = on and T.Text or T.SubText })
        if t.Icon then tween(t.Icon, 0.25, { ImageColor3 = on and T.Accent or T.SubText }) end
        t.Page.Visible = on
    end
    self.CurrentTab = tab
    self.TabTitle.Text = tab.Name
    tab.Page.Position = UDim2.fromOffset(0, 10)
    tween(tab.Page, 0.3, { Position = UDim2.fromOffset(0, 0) })
end

----------------------------------------------------------------------------------------------------
-- Element base
----------------------------------------------------------------------------------------------------

function Tab:_nextOrder()
    self.Order = self.Order + 1
    return self.Order
end

-- Builds a standard element card with a title (+ optional description).
-- opts.right  = pixels reserved on the right for a control
-- opts.extra  = extra height below the title area
-- Returns frame, topHeight
function Tab:_element(cfg, opts)
    opts = opts or {}
    local T = self.Window.Theme
    local hasDesc = cfg.Description ~= nil and cfg.Description ~= ""
    local top = hasDesc and 52 or 40
    local right = opts.right or 0

    local frame = create("Frame", {
        Name = cfg.Name or "Element",
        Size = UDim2.new(1, 0, 0, top + (opts.extra or 0)),
        BackgroundColor3 = T.Element,
        ClipsDescendants = opts.clip or false,
        LayoutOrder = self:_nextOrder(),
        Parent = self.Page,
    }, { corner(7), stroke(T.Stroke, 1) })

    create("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(14, hasDesc and 10 or 0),
        Size = UDim2.new(1, -(28 + right), 0, hasDesc and 16 or top),
        BackgroundTransparency = 1,
        Font = FONT_MEDIUM,
        Text = cfg.Name or "Element",
        TextColor3 = T.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame,
    })
    if hasDesc then
        create("TextLabel", {
            Name = "Description",
            Position = UDim2.fromOffset(14, 28),
            Size = UDim2.new(1, -(28 + right), 0, 14),
            BackgroundTransparency = 1,
            Font = FONT,
            Text = cfg.Description,
            TextColor3 = T.SubText,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = frame,
        })
    end
    return frame, top
end

function Tab:_hover(frame, trigger)
    local T = self.Window.Theme
    trigger = trigger or frame
    trigger.MouseEnter:Connect(function() tween(frame, 0.2, { BackgroundColor3 = T.ElementHover }) end)
    trigger.MouseLeave:Connect(function() tween(frame, 0.2, { BackgroundColor3 = T.Element }) end)
end

function Tab:_flag(cfg, element)
    if cfg.Flag then self.Window.Flags[cfg.Flag] = element end
    return element
end

----------------------------------------------------------------------------------------------------
-- Section
----------------------------------------------------------------------------------------------------

function Tab:CreateSection(name)
    local T = self.Window.Theme
    local first = self.Order == 0
    local label = create("TextLabel", {
        Name = "Section",
        Size = UDim2.new(1, 0, 0, first and 18 or 28),
        BackgroundTransparency = 1,
        Font = FONT_BOLD,
        Text = string.upper(name or "Section"),
        TextColor3 = T.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom,
        LayoutOrder = self:_nextOrder(),
        Parent = self.Page,
    }, { padding(0, 0, 2, 2) })
    return {
        Set = function(_, text) label.Text = string.upper(text) end,
    }
end

----------------------------------------------------------------------------------------------------
-- Button
----------------------------------------------------------------------------------------------------

function Tab:CreateButton(cfg)
    cfg = cfg or {}
    local T = self.Window.Theme
    local frame, top = self:_element(cfg, { right = 24, clip = true })

    -- small arrow made from two bars
    local arrow = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0, top / 2),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        Parent = frame,
    })
    for i, rot in ipairs({ 45, -45 }) do
        create("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -2, 0.5, i == 1 and -3 or 3),
            Size = UDim2.fromOffset(8, 2),
            Rotation = rot,
            BackgroundColor3 = T.SubText,
            BorderSizePixel = 0,
            Parent = arrow,
        }, { round() })
    end

    local hit = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 6,
        Parent = frame,
    })
    self:_hover(frame, hit)

    hit.MouseButton1Click:Connect(function()
        ripple(frame, T.Accent)
        arrow.Position = UDim2.new(1, -10, 0, top / 2)
        tween(arrow, 0.35, { Position = UDim2.new(1, -14, 0, top / 2) })
        safeCall(cfg.Callback)
    end)

    return self:_flag(cfg, {
        SetText = function(_, text) frame.Title.Text = text end,
        Fire = function() safeCall(cfg.Callback) end,
    })
end

----------------------------------------------------------------------------------------------------
-- Toggle
----------------------------------------------------------------------------------------------------

function Tab:CreateToggle(cfg)
    cfg = cfg or {}
    local T = self.Window.Theme
    local frame, top = self:_element(cfg, { right = 46 })
    local element = { Value = false }

    local switch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0, top / 2),
        Size = UDim2.fromOffset(40, 22),
        BackgroundColor3 = T.Off,
        Parent = frame,
    }, { round() })
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Color3.fromRGB(235, 235, 240),
        Parent = switch,
    }, { round() })

    local hit = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    self:_hover(frame, hit)

    function element:Set(value, silent)
        value = value and true or false
        self.Value = value
        tween(switch, 0.25, { BackgroundColor3 = value and T.Accent or T.Off })
        tween(knob, 0.3, {
            Position = value and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            BackgroundColor3 = value and Color3.new(1, 1, 1) or Color3.fromRGB(235, 235, 240),
        }, Enum.EasingStyle.Back)
        if not silent then safeCall(cfg.Callback, value) end
    end

    function element:Get() return self.Value end

    hit.MouseButton1Click:Connect(function()
        -- squish feedback
        tween(knob, 0.1, { Size = UDim2.fromOffset(20, 16) })
        task.delay(0.1, function() tween(knob, 0.2, { Size = UDim2.fromOffset(16, 16) }) end)
        element:Set(not element.Value)
    end)

    element:Set(cfg.Default or false, not cfg.CallOnDefault)
    return self:_flag(cfg, element)
end

----------------------------------------------------------------------------------------------------
-- Slider
----------------------------------------------------------------------------------------------------

function Tab:CreateSlider(cfg)
    cfg = cfg or {}
    local T = self.Window.Theme
    local min = cfg.Min or 0
    local max = cfg.Max or 100
    local inc = cfg.Increment or 1
    local suffix = cfg.Suffix or ""
    local decimals = decimalsOf(inc)

    local frame, top = self:_element(cfg, { right = 70, extra = 16 })
    local element = { Value = min }

    local valueBox = create("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0, top / 2 + (cfg.Description and 0 or 1)),
        Size = UDim2.fromOffset(62, 22),
        BackgroundColor3 = T.Background,
        Font = FONT_MEDIUM,
        Text = "",
        TextColor3 = T.Text,
        TextSize = 12,
        ClearTextOnFocus = false,
        Parent = frame,
    }, { corner(5), stroke(T.Stroke, 1) })

    local bar = create("Frame", {
        Position = UDim2.new(0, 14, 0, top),
        Size = UDim2.new(1, -28, 0, 6),
        BackgroundColor3 = T.Off,
        Parent = frame,
    }, { round() })
    local fill = create("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = T.Accent,
        Parent = bar,
    }, { round() })
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 2,
        Parent = bar,
    }, { round(), stroke(T.Accent, 2) })
    -- larger invisible hitbox for easier grabbing
    local hitbox = create("TextButton", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 3,
        Parent = bar,
    })

    local function format(v)
        if decimals > 0 then
            return string.format("%." .. decimals .. "f", v) .. suffix
        end
        return tostring(math.floor(v + 0.5)) .. suffix
    end

    function element:Set(value, silent)
        value = tonumber(value) or min
        value = math.clamp(value, min, max)
        value = math.floor((value - min) / inc + 0.5) * inc + min
        value = math.clamp(value, min, max)
        if decimals > 0 then
            value = tonumber(string.format("%." .. decimals .. "f", value))
        end
        local changed = value ~= self.Value
        self.Value = value
        local pct = (max == min) and 0 or (value - min) / (max - min)
        tween(fill, 0.15, { Size = UDim2.fromScale(pct, 1) })
        tween(knob, 0.15, { Position = UDim2.fromScale(pct, 0.5) })
        valueBox.Text = format(value)
        if changed and not silent then safeCall(cfg.Callback, value) end
    end

    function element:Get() return self.Value end

    self.Window:_bindDrag(hitbox, function(pos)
        local pct = math.clamp((pos.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        element:Set(min + (max - min) * pct)
        tween(knob, 0.15, { Size = UDim2.fromOffset(17, 17) })
    end, function()
        tween(knob, 0.2, { Size = UDim2.fromOffset(14, 14) })
    end)

    valueBox.Focused:Connect(function()
        valueBox.Text = tostring(element.Value)
    end)
    valueBox.FocusLost:Connect(function()
        local n = tonumber((string.gsub(valueBox.Text, "[^%d%.%-]", "")))
        if n then element:Set(n) else valueBox.Text = format(element.Value) end
        valueBox.Text = format(element.Value)
    end)

    self:_hover(frame)
    element.Value = nil
    element:Set(cfg.Default or min, not cfg.CallOnDefault)
    return self:_flag(cfg, element)
end

----------------------------------------------------------------------------------------------------
-- Dropdown
----------------------------------------------------------------------------------------------------

function Tab:CreateDropdown(cfg)
    cfg = cfg or {}
    local T = self.Window.Theme
    local multi = cfg.Multi or false
    local options = cfg.Options or {}
    local maxVisible = cfg.MaxVisible or 5
    local ITEM_H, GAP = 28, 4

    local frame, top = self:_element(cfg, { right = 160, clip = true })
    local element = { Value = multi and {} or nil, Options = options, Open = false }

    local selectedLabel = create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -38, 0, top / 2),
        Size = UDim2.fromOffset(130, 16),
        BackgroundTransparency = 1,
        Font = FONT,
        Text = "None",
        TextColor3 = T.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame,
    })
    local plusHolder = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0, top / 2),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        Parent = frame,
    })
    for _, rot in ipairs({ 0, 90 }) do
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(11, 2),
            Rotation = rot,
            BackgroundColor3 = T.SubText,
            BorderSizePixel = 0,
            Parent = plusHolder,
        }, { round() })
    end

    local header = create("TextButton", {
        Size = UDim2.new(1, 0, 0, top),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    self:_hover(frame, header)

    local list = create("ScrollingFrame", {
        Position = UDim2.fromOffset(8, top),
        Size = UDim2.new(1, -16, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Stroke,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = frame,
    }, {
        create("UIListLayout", { Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    local function isSelected(opt)
        if multi then
            return table.find(element.Value, opt) ~= nil
        end
        return element.Value == opt
    end

    local function listHeight()
        local n = math.min(#element.Options, maxVisible)
        if n == 0 then return 0 end
        return n * ITEM_H + (n - 1) * GAP
    end

    local function updateLabel()
        if multi then
            selectedLabel.Text = (#element.Value > 0) and table.concat(element.Value, ", ") or "None"
        else
            selectedLabel.Text = element.Value ~= nil and tostring(element.Value) or "None"
        end
    end

    local buildOptions

    local function setOpen(state)
        element.Open = state
        local h = listHeight()
        list.Size = UDim2.new(1, -16, 0, h)
        tween(frame, 0.3, { Size = UDim2.new(1, 0, 0, state and (top + h + 8) or top) })
        tween(plusHolder, 0.3, { Rotation = state and 45 or 0 })
    end

    buildOptions = function()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for i, opt in ipairs(element.Options) do
            local sel = isSelected(opt)
            local item = create("TextButton", {
                Size = UDim2.new(1, -4, 0, ITEM_H),
                BackgroundColor3 = sel and T.ElementHover or T.Background,
                AutoButtonColor = false,
                Font = sel and FONT_MEDIUM or FONT,
                Text = tostring(opt),
                TextColor3 = sel and T.Accent or T.SubText,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = i,
                Parent = list,
            }, { corner(5), padding(0, 10, 0, 10) })
            item.MouseEnter:Connect(function()
                if not isSelected(opt) then tween(item, 0.15, { TextColor3 = T.Text }) end
            end)
            item.MouseLeave:Connect(function()
                if not isSelected(opt) then tween(item, 0.15, { TextColor3 = T.SubText }) end
            end)
            item.MouseButton1Click:Connect(function()
                if multi then
                    local idx = table.find(element.Value, opt)
                    if idx then table.remove(element.Value, idx) else table.insert(element.Value, opt) end
                    buildOptions()
                    updateLabel()
                    safeCall(cfg.Callback, element.Value)
                else
                    element.Value = opt
                    buildOptions()
                    updateLabel()
                    setOpen(false)
                    safeCall(cfg.Callback, opt)
                end
            end)
        end
    end

    header.MouseButton1Click:Connect(function() setOpen(not element.Open) end)

    function element:Set(value, silent)
        if multi then
            self.Value = type(value) == "table" and value or { value }
        else
            self.Value = value
        end
        buildOptions()
        updateLabel()
        if not silent then safeCall(cfg.Callback, self.Value) end
    end

    function element:Get() return self.Value end

    function element:Refresh(newOptions, keepSelection)
        self.Options = newOptions or {}
        if not keepSelection then
            self.Value = multi and {} or nil
        end
        buildOptions()
        updateLabel()
        if self.Open then setOpen(true) end
    end

    if cfg.Default ~= nil then
        element:Set(cfg.Default, true)
    else
        buildOptions()
        updateLabel()
    end
    return self:_flag(cfg, element)
end

----------------------------------------------------------------------------------------------------
-- Input (TextBox)
----------------------------------------------------------------------------------------------------

function Tab:CreateInput(cfg)
    cfg = cfg or {}
    local T = self.Window.Theme
    local frame, top = self:_element(cfg, { right = 160 })
    local element = { Value = cfg.Default or "" }

    local box = create("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0, top / 2),
        Size = UDim2.fromOffset(150, 26),
        BackgroundColor3 = T.Background,
        ClearTextOnFocus = false,
        Font = FONT,
        PlaceholderText = cfg.Placeholder or "Type here...",
        PlaceholderColor3 = T.SubText,
        Text = element.Value,
        TextColor3 = T.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame,
    }, { corner(5), padding(0, 8, 0, 8) })
    local boxStroke = stroke(T.Stroke, 1)
    boxStroke.Parent = box

    self:_hover(frame)

    box.Focused:Connect(function() tween(boxStroke, 0.2, { Color = T.Accent }) end)
    box.FocusLost:Connect(function(enter)
        tween(boxStroke, 0.2, { Color = T.Stroke })
        local text = box.Text
        if cfg.NumbersOnly then
            text = string.gsub(text, "[^%d%.%-]", "")
            box.Text = text
        end
        element.Value = text
        safeCall(cfg.Callback, text, enter)
        if cfg.ClearOnFocusLost then box.Text = "" end
    end)

    function element:Set(text, silent)
        box.Text = tostring(text)
        self.Value = box.Text
        if not silent then safeCall(cfg.Callback, self.Value, false) end
    end
    function element:Get() return self.Value end

    return self:_flag(cfg, element)
end

----------------------------------------------------------------------------------------------------
-- Keybind
----------------------------------------------------------------------------------------------------

function Tab:CreateKeybind(cfg)
    cfg = cfg or {}
    local T = self.Window.Theme
    local frame, top = self:_element(cfg, { right = 90 })
    local element = { Value = cfg.Default, Listening = false }

    local btn = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0, top / 2),
        Size = UDim2.fromOffset(60, 26),
        BackgroundColor3 = T.Background,
        AutoButtonColor = false,
        Font = FONT_MEDIUM,
        Text = "None",
        TextColor3 = T.Text,
        TextSize = 12,
        Parent = frame,
    }, { corner(5) })
    local btnStroke = stroke(T.Stroke, 1)
    btnStroke.Parent = btn

    self:_hover(frame)

    local function refresh(text)
        local w = math.max(48, textWidth(text, 12, FONT_MEDIUM) + 22)
        btn.Text = text
        tween(btn, 0.2, { Size = UDim2.fromOffset(w, 26) })
    end

    function element:Set(key)
        self.Value = key
        refresh(key and key.Name or "None")
        safeCall(cfg.Changed, key)
    end
    function element:Get() return self.Value end

    btn.MouseButton1Click:Connect(function()
        element.Listening = true
        refresh("...")
        tween(btnStroke, 0.2, { Color = T.Accent })
    end)

    self.Window:_track(UserInputService.InputBegan:Connect(function(input, processed)
        if element.Listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                element.Listening = false
                tween(btnStroke, 0.2, { Color = T.Stroke })
                if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                    element:Set(nil)
                else
                    element:Set(input.KeyCode)
                end
            end
            return
        end
        if processed then return end
        if element.Value and input.KeyCode == element.Value then
            safeCall(cfg.Callback, element.Value)
        end
    end))

    refresh(element.Value and element.Value.Name or "None")
    return self:_flag(cfg, element)
end

----------------------------------------------------------------------------------------------------
-- Color Picker
----------------------------------------------------------------------------------------------------

function Tab:CreateColorPicker(cfg)
    cfg = cfg or {}
    local T = self.Window.Theme
    local frame, top = self:_element(cfg, { right = 50, clip = true })
    local element = { Value = cfg.Default or Color3.fromRGB(255, 255, 255), Open = false }
    local h, s, v = element.Value:ToHSV()

    local PICK_H = 120
    local openHeight = top + PICK_H + 8 + 26 + 12

    local swatch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0, top / 2),
        Size = UDim2.fromOffset(34, 20),
        BackgroundColor3 = element.Value,
        Parent = frame,
    }, { corner(5), stroke(T.Stroke, 1) })

    local header = create("TextButton", {
        Size = UDim2.new(1, 0, 0, top),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    self:_hover(frame, header)

    -- Saturation / Value box
    local svBox = create("Frame", {
        Position = UDim2.fromOffset(14, top),
        Size = UDim2.new(1, -28 - 26, 0, PICK_H),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        Parent = frame,
    }, { corner(6) })
    create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = svBox,
    }, {
        corner(6),
        create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }),
    })
    create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        Parent = svBox,
    }, {
        corner(6),
        create("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        }),
    })
    local svCursor = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = svBox,
    }, { round(), stroke(Color3.new(1, 1, 1), 2) })

    -- Hue bar
    local hueKeys = {}
    for i = 0, 6 do
        table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
    end
    local hueBar = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, top),
        Size = UDim2.fromOffset(16, PICK_H),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = frame,
    }, {
        corner(6),
        create("UIGradient", { Rotation = 90, Color = ColorSequence.new(hueKeys) }),
    })
    local hueCursor = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0),
        Size = UDim2.new(1, 4, 0, 4),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 3,
        Parent = hueBar,
    }, { round(), stroke(Color3.fromRGB(30, 30, 30), 1, 0.4) })

    -- Hex input
    local hexBox = create("TextBox", {
        Position = UDim2.fromOffset(14, top + PICK_H + 8),
        Size = UDim2.new(1, -28, 0, 26),
        BackgroundColor3 = T.Background,
        ClearTextOnFocus = false,
        Font = FONT_MEDIUM,
        Text = "",
        TextColor3 = T.Text,
        TextSize = 12,
        Parent = frame,
    }, { corner(5), stroke(T.Stroke, 1) })

    local function toHex(c)
        return string.format("#%02X%02X%02X",
            math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
    end

    local function apply(silent)
        local color = Color3.fromHSV(h, s, v)
        element.Value = color
        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(0.5, h)
        swatch.BackgroundColor3 = color
        hexBox.Text = toHex(color)
        if not silent then safeCall(cfg.Callback, color) end
    end

    self.Window:_bindDrag(svBox, function(pos)
        s = math.clamp((pos.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
        v = 1 - math.clamp((pos.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
        apply()
    end)
    self.Window:_bindDrag(hueBar, function(pos)
        h = math.clamp((pos.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
        apply()
    end)

    hexBox.FocusLost:Connect(function()
        local hex = string.gsub(hexBox.Text, "[^%x]", "")
        if #hex == 6 then
            local r = tonumber(string.sub(hex, 1, 2), 16)
            local g = tonumber(string.sub(hex, 3, 4), 16)
            local b = tonumber(string.sub(hex, 5, 6), 16)
            if r and g and b then
                h, s, v = Color3.fromRGB(r, g, b):ToHSV()
                apply()
                return
            end
        end
        hexBox.Text = toHex(element.Value)
    end)

    header.MouseButton1Click:Connect(function()
        element.Open = not element.Open
        tween(frame, 0.3, { Size = UDim2.new(1, 0, 0, element.Open and openHeight or top) })
    end)

    function element:Set(color, silent)
        h, s, v = color:ToHSV()
        apply(silent)
    end
    function element:Get() return self.Value end

    apply(true)
    return self:_flag(cfg, element)
end

----------------------------------------------------------------------------------------------------
-- Label & Paragraph
----------------------------------------------------------------------------------------------------

function Tab:CreateLabel(text)
    local T = self.Window.Theme
    local frame = create("Frame", {
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = T.Element,
        BackgroundTransparency = 0.4,
        LayoutOrder = self:_nextOrder(),
        Parent = self.Page,
    }, { corner(7) })
    local label = create("TextLabel", {
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -28, 1, 0),
        BackgroundTransparency = 1,
        Font = FONT,
        Text = text or "Label",
        TextColor3 = T.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame,
    })
    return {
        Set = function(_, newText) label.Text = newText end,
    }
end

function Tab:CreateParagraph(cfg)
    cfg = cfg or {}
    local T = self.Window.Theme
    local frame = create("Frame", {
        Name = "Paragraph",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.Element,
        LayoutOrder = self:_nextOrder(),
        Parent = self.Page,
    }, {
        corner(7),
        stroke(T.Stroke, 1),
        padding(11, 14, 12, 14),
        create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    local title = create("TextLabel", {
        LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = FONT_BOLD,
        Text = cfg.Title or "Paragraph",
        TextColor3 = T.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })
    local content = create("TextLabel", {
        LayoutOrder = 2,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = FONT,
        Text = cfg.Content or "",
        TextColor3 = T.SubText,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })
    return {
        Set = function(_, newCfg)
            if newCfg.Title then title.Text = newCfg.Title end
            if newCfg.Content then content.Text = newCfg.Content end
        end,
    }
end

return Boolean
