--[[
    Boolean UI  v2.0.0
    Immediate-mode inspired, client-sided UI library for Roblox.

    Multiple draggable / resizable / collapsible windows, tree nodes, collapsing headers,
    rows, grids, buttons, checkboxes, radio grids, sliders, number inputs, text inputs,
    combos, color editors, keybinds, progress bars, separators, tooltips, 3D preview
    viewports and toast notifications.

    local Boolean = loadstring(game:HttpGet("<raw url>"))()
    local Win = Boolean:Window({ Title = "Editor", Size = Vector2.new(360, 420) })
    local Node = Win:Tree("Player", true)
    Node:Slider("Speed", { Min = 16, Max = 100, Default = 16 }, function(v) end)
]]

local Boolean = {}
Boolean.Version = "2.0.0"
Boolean.Flags = {}
Boolean.Windows = {}
Boolean.ToggleKey = Enum.KeyCode.RightShift
Boolean.Visible = true

Boolean.Style = {
    Font = Enum.Font.RobotoMono,
    TextSize = 13,
    FrameHeight = 20,
    TitleHeight = 22,
    Spacing = 4,
    Indent = 18,
    Padding = 8,
    Rounding = 0,        -- set to 2-4 for softer corners
    WindowRounding = 0,
    ScrollbarSize = 6,
}

Boolean.Accents = {
    Blue   = Color3.fromRGB(66, 150, 250),
    Purple = Color3.fromRGB(150, 105, 255),
    Red    = Color3.fromRGB(235, 72, 88),
    Green  = Color3.fromRGB(62, 200, 122),
    Orange = Color3.fromRGB(255, 152, 52),
    Pink   = Color3.fromRGB(255, 98, 172),
    Teal   = Color3.fromRGB(40, 200, 200),
    Mono   = Color3.fromRGB(165, 165, 175),
}
Boolean.Accent = Boolean.Accents.Blue

--// Services
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService      = game:GetService("TextService")
local RunService       = game:GetService("RunService")
local GuiService       = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------------------------------------------
-- Theme
----------------------------------------------------------------------------------------------------

local function buildTheme(accent)
    accent = accent or Boolean.Accent
    local bg = Color3.fromRGB(17, 17, 18)
    local black = Color3.new(0, 0, 0)
    local white = Color3.new(1, 1, 1)
    return {
        Accent        = accent,
        WindowBg      = bg,
        TitleBg       = Color3.fromRGB(10, 10, 10),
        TitleBgActive = Color3.fromRGB(10, 10, 10):Lerp(accent, 0.16),
        PopupBg       = Color3.fromRGB(21, 21, 23),
        Border        = Color3.fromRGB(56, 56, 64),
        Text          = Color3.fromRGB(232, 232, 232),
        TextDim       = Color3.fromRGB(128, 128, 134),
        FrameBg       = bg:Lerp(accent, 0.20),
        FrameBgHover  = bg:Lerp(accent, 0.34),
        FrameBgActive = bg:Lerp(accent, 0.48),
        Button        = bg:Lerp(accent, 0.36),
        ButtonHover   = bg:Lerp(accent, 0.62),
        ButtonActive  = accent,
        Header        = bg:Lerp(accent, 0.30),
        HeaderHover   = bg:Lerp(accent, 0.48),
        HeaderActive  = bg:Lerp(accent, 0.70),
        Check         = accent,
        Grab          = accent:Lerp(black, 0.08),
        GrabActive    = accent:Lerp(white, 0.2),
        Separator     = Color3.fromRGB(56, 56, 64),
        ResizeGrip    = bg:Lerp(accent, 0.42),
        ResizeHover   = bg:Lerp(accent, 0.75),
        Scrollbar     = Color3.fromRGB(78, 78, 84),
        Viewport      = Color3.fromRGB(38, 38, 40),
    }
end

----------------------------------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------------------------------

local function create(className, props, children)
    local inst = Instance.new(className)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, child in ipairs(children or {}) do child.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

local function tween(obj, t, props, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function rounding(parent, r)
    r = r or Boolean.Style.Rounding
    if r and r > 0 then
        create("UICorner", { CornerRadius = UDim.new(0, r), Parent = parent })
    end
end

local function stroke(color, transparency)
    return create("UIStroke", {
        Color = color,
        Thickness = 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function pad(t, r, b, l)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
        PaddingLeft = UDim.new(0, l or r or t or 0),
    })
end

local function list(spacing, horizontal)
    return create("UIListLayout", {
        Padding = UDim.new(0, spacing or Boolean.Style.Spacing),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        VerticalAlignment = horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top,
    })
end

local function textWidth(str)
    local S = Boolean.Style
    return TextService:GetTextSize(tostring(str), S.TextSize, S.Font, Vector2.new(10000, 100)).X
end

local function label(parent, text, color, props)
    local S = Boolean.Style
    local l = create("TextLabel", {
        BackgroundTransparency = 1,
        Font = S.Font,
        TextSize = S.TextSize,
        TextColor3 = color,
        Text = tostring(text),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.fromScale(1, 1),
        Parent = parent,
    })
    for k, v in pairs(props or {}) do l[k] = v end
    return l
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

-- Screen position in the same space as AbsolutePosition (ScreenGui uses IgnoreGuiInset)
local function screenPos(input)
    if input and input.UserInputType == Enum.UserInputType.Touch then
        local inset = GuiService:GetGuiInset()
        return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
    end
    return UserInputService:GetMouseLocation()
end

local function inside(obj, pos)
    if not obj or not obj.Parent then return false end
    local a, s = obj.AbsolutePosition, obj.AbsoluteSize
    return pos.X >= a.X and pos.X <= a.X + s.X and pos.Y >= a.Y and pos.Y <= a.Y + s.Y
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local args, n = { ... }, select("#", ...)
    task.spawn(function()
        local ok, err = pcall(fn, unpack(args, 1, n))
        if not ok then warn("[Boolean] " .. tostring(err)) end
    end)
end

-- Pixel triangle (points down at Rotation 0). Rotate the holder to point other ways.
local function triangle(parent, size, color)
    local holder = create("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    local rows = math.ceil(size / 2)
    local top = math.floor((size - rows) / 2)
    local parts = {}
    for i = 0, rows - 1 do
        table.insert(parts, create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, top + i),
            Size = UDim2.fromOffset(size - i * 2, 1),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Parent = holder,
        }))
    end
    return holder, parts
end

local function colorParts(parts, color, t)
    for _, p in ipairs(parts) do
        if t then tween(p, t, { BackgroundColor3 = color }) else p.BackgroundColor3 = color end
    end
end

-- Hover / press color feedback
local function feedback(obj, trigger, normal, hover, active, prop)
    prop = prop or "BackgroundColor3"
    local hovering = false
    trigger.MouseEnter:Connect(function()
        hovering = true
        tween(obj, 0.12, { [prop] = hover })
    end)
    trigger.MouseLeave:Connect(function()
        hovering = false
        tween(obj, 0.18, { [prop] = normal })
    end)
    trigger.MouseButton1Down:Connect(function()
        tween(obj, 0.06, { [prop] = active })
    end)
    trigger.MouseButton1Up:Connect(function()
        tween(obj, 0.15, { [prop] = hovering and hover or normal })
    end)
end

local function fmtNumber(v, decimals)
    return string.format("%." .. tostring(decimals or 0) .. "f", v)
end

local function toHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function fromHex(str)
    local hex = string.gsub(tostring(str), "[^%x]", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(string.sub(hex, 1, 2), 16)
    local g = tonumber(string.sub(hex, 3, 4), 16)
    local b = tonumber(string.sub(hex, 5, 6), 16)
    if r and g and b then return Color3.fromRGB(r, g, b) end
    return nil
end

----------------------------------------------------------------------------------------------------
-- Shared state (ScreenGui, overlay, popups, tooltip, toasts)
----------------------------------------------------------------------------------------------------

local State = {
    Gui = nil,
    Overlay = nil,
    Z = 10,
    Conns = {},
    Popup = nil,
    Focused = nil,
    TooltipToken = 0,
}

local function track(conn)
    table.insert(State.Conns, conn)
    return conn
end

local function closePopup()
    local p = State.Popup
    if not p then return end
    State.Popup = nil
    if p.OnClose then p.OnClose() end
end

local function openPopup(frame, owner, follow, onClose)
    closePopup()
    State.Popup = { Frame = frame, Owner = owner, Follow = follow, OnClose = onClose }
    if follow then follow() end
end

local function getGui(parent)
    if State.Gui and State.Gui.Parent then return State.Gui end
    local T = buildTheme()
    local S = Boolean.Style

    local gui = create("ScreenGui", {
        Name = "Boolean",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    gui.Parent = parent or LocalPlayer:WaitForChild("PlayerGui")
    State.Gui = gui

    State.Overlay = create("Frame", {
        Name = "Overlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 1000000,
        Parent = gui,
    })

    State.Tooltip = create("TextLabel", {
        Name = "Tooltip",
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = T.PopupBg,
        BorderSizePixel = 0,
        Font = S.Font,
        TextSize = S.TextSize,
        TextColor3 = T.Text,
        Text = "",
        Visible = false,
        ZIndex = 50,
        Parent = State.Overlay,
    }, { pad(4, 7, 4, 7), stroke(T.Border) })

    State.Toasts = create("Frame", {
        Name = "Toasts",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -14, 1, -14),
        Size = UDim2.new(0, 280, 1, -28),
        BackgroundTransparency = 1,
        ZIndex = 40,
        Parent = State.Overlay,
    }, {
        create("UIListLayout", {
            Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    track(UserInputService.InputBegan:Connect(function(input, processed)
        if isPress(input) then
            local pos = screenPos(input)
            local p = State.Popup
            if p and not inside(p.Frame, pos) and not inside(p.Owner, pos) then
                closePopup()
            end
            local top, z = nil, -1
            for _, w in ipairs(Boolean.Windows) do
                if w.Root.Visible and inside(w.Root, pos) and w.Root.ZIndex > z then
                    top, z = w, w.Root.ZIndex
                end
            end
            if top and top ~= State.Focused then top:Focus() end
        end
        if not processed and input.UserInputType == Enum.UserInputType.Keyboard
            and Boolean.ToggleKey and input.KeyCode == Boolean.ToggleKey then
            Boolean:Toggle()
        end
    end))

    track(RunService.RenderStepped:Connect(function()
        if State.Popup and State.Popup.Follow then State.Popup.Follow() end
        if State.Tooltip.Visible then
            local m = UserInputService:GetMouseLocation()
            State.Tooltip.Position = UDim2.fromOffset(m.X + 14, m.Y + 12)
        end
    end))

    return gui
end

local function attachTooltip(obj, text)
    if not text then return end
    obj.MouseEnter:Connect(function()
        State.TooltipToken = State.TooltipToken + 1
        local token = State.TooltipToken
        task.delay(0.35, function()
            if State.TooltipToken == token and State.Tooltip then
                State.Tooltip.Text = text
                State.Tooltip.Visible = true
            end
        end)
    end)
    obj.MouseLeave:Connect(function()
        State.TooltipToken = State.TooltipToken + 1
        if State.Tooltip then State.Tooltip.Visible = false end
    end)
end

----------------------------------------------------------------------------------------------------
-- Container (shared by windows, trees, headers, rows, grids)
----------------------------------------------------------------------------------------------------

local Container = {}
Container.__index = Container

local Window = setmetatable({}, { __index = Container })
Window.__index = Window

local function newContainer(window, items, mode)
    return setmetatable({
        Window = window,
        Theme = window.Theme,
        Items = items,
        Order = 0,
        Mode = mode or "List",
    }, Container)
end

function Container:_order()
    self.Order = self.Order + 1
    return self.Order
end

function Container:_flag(opts, el)
    if opts and opts.Flag then Boolean.Flags[opts.Flag] = el end
    return el
end

-- Frame width for "widget + label" elements
function Container:_fw(opts, hasLabel)
    if opts.Width then return UDim.new(0, opts.Width) end
    if self.Mode == "Row" then return UDim.new(0, opts.DefaultWidth or 110) end
    if not hasLabel then return UDim.new(1, 0) end
    return UDim.new(opts.Ratio or 0.62, 0)
end

-- Builds the root frame and right-side label used by most widgets
function Container:_widget(text, opts)
    local T, S = self.Theme, Boolean.Style
    local H = S.FrameHeight
    local hasLabel = text ~= nil and text ~= ""
    local fw = self:_fw(opts, hasLabel)
    local labelW = hasLabel and (textWidth(text) + 6) or 0

    local root = create("Frame", {
        Name = hasLabel and text or "Widget",
        Size = (self.Mode == "Row") and UDim2.fromOffset(fw.Offset + labelW, H) or UDim2.new(1, 0, 0, H),
        BackgroundTransparency = 1,
        LayoutOrder = self:_order(),
        Parent = self.Items,
    })
    if hasLabel then
        label(root, text, T.Text, {
            Name = "Label",
            Position = UDim2.new(fw.Scale, fw.Offset + 6, 0, 0),
            Size = UDim2.new(1 - fw.Scale, -(fw.Offset + 6), 1, 0),
        })
    end
    attachTooltip(root, opts.Tooltip)
    return root, fw
end

-- Press-and-drag binding, connections owned by the window
function Container:_drag(obj, onMove, onRelease)
    local dragging = false
    obj.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true
            onMove(screenPos(input), true)
        end
    end)
    self.Window:_track(UserInputService.InputChanged:Connect(function(input)
        if dragging and isMove(input) then onMove(screenPos(input), false) end
    end))
    self.Window:_track(UserInputService.InputEnded:Connect(function(input)
        if dragging and isPress(input) then
            dragging = false
            if onRelease then onRelease() end
        end
    end))
end

----------------------------------------------------------------------------------------------------
-- Layout containers
----------------------------------------------------------------------------------------------------

function Container:_collapsible(text, opts, filled)
    opts = opts or {}
    local T, S = self.Theme, Boolean.Style
    local H = S.FrameHeight
    local open = opts.Open and true or false

    local node = create("Frame", {
        Name = text,
        Size = UDim2.new(1, 0, 0, H),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        LayoutOrder = self:_order(),
        Parent = self.Items,
    })
    local header = create("TextButton", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, H),
        BackgroundColor3 = T.Header,
        BackgroundTransparency = filled and 0 or 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = node,
    })
    rounding(header)

    local arrow, arrowParts = triangle(header, 9, T.Text)
    arrow.AnchorPoint = Vector2.new(0, 0.5)
    arrow.Position = UDim2.new(0, 4, 0.5, 0)
    arrow.Rotation = open and 0 or -90

    label(header, text, T.Text, {
        Position = UDim2.fromOffset(19, 0),
        Size = UDim2.new(1, -19, 1, 0),
    })
    attachTooltip(header, opts.Tooltip)

    local indent = filled and 0 or S.Indent
    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(indent, H + S.Spacing),
        Size = UDim2.new(1, -indent, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = node,
    }, { list() })

    local c = newContainer(self.Window, content, "List")
    c.Open = open

    local animId = 0
    local animating = false
    local function target()
        if c.Open then return H + S.Spacing + content.AbsoluteSize.Y end
        return H
    end

    local function set(state, instant)
        c.Open = state and true or false
        if instant then
            node.Size = UDim2.new(1, 0, 0, target())
            arrow.Rotation = c.Open and 0 or -90
            return
        end
        animId = animId + 1
        local id = animId
        animating = true
        tween(arrow, 0.22, { Rotation = c.Open and 0 or -90 })
        local tw = tween(node, 0.28, { Size = UDim2.new(1, 0, 0, target()) })
        tw.Completed:Connect(function()
            if id == animId then
                animating = false
                node.Size = UDim2.new(1, 0, 0, target())
            end
        end)
        safeCall(opts.Callback, c.Open)
    end

    content:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if not animating then node.Size = UDim2.new(1, 0, 0, target()) end
    end)

    -- hover / press visuals
    local hovering = false
    header.MouseEnter:Connect(function()
        hovering = true
        if filled then
            tween(header, 0.12, { BackgroundColor3 = T.HeaderHover })
        else
            tween(header, 0.12, { BackgroundTransparency = 0, BackgroundColor3 = T.Header })
        end
    end)
    header.MouseLeave:Connect(function()
        hovering = false
        if filled then
            tween(header, 0.18, { BackgroundColor3 = T.Header })
        else
            tween(header, 0.18, { BackgroundTransparency = 1 })
        end
    end)
    header.MouseButton1Down:Connect(function()
        tween(header, 0.06, { BackgroundColor3 = T.HeaderActive, BackgroundTransparency = 0 })
    end)
    header.MouseButton1Up:Connect(function()
        tween(header, 0.15, { BackgroundColor3 = (hovering and filled) and T.HeaderHover or T.Header })
    end)
    header.MouseButton1Click:Connect(function() set(not c.Open) end)

    function c:SetOpen(state) set(state) end
    function c:SetText(newText) header:FindFirstChildOfClass("TextLabel").Text = newText end

    set(open, true)
    return c
end

-- Tree node: arrow + label, indented children
function Container:Tree(text, open, opts)
    opts = opts or {}
    if type(open) == "table" then opts = open else opts.Open = open end
    return self:_collapsible(text, opts, false)
end

-- Collapsing header: filled bar, no indent
function Container:Header(text, open, opts)
    opts = opts or {}
    if type(open) == "table" then opts = open else opts.Open = open end
    return self:_collapsible(text, opts, true)
end

-- Horizontal row: Row():Button(...) Row():Checkbox(...) side by side
function Container:Row(spacing)
    local frame = create("Frame", {
        Name = "Row",
        Size = UDim2.new(1, 0, 0, Boolean.Style.FrameHeight),
        BackgroundTransparency = 1,
        LayoutOrder = self:_order(),
        Parent = self.Items,
    }, { list(spacing or 6, true) })
    return newContainer(self.Window, frame, "Row")
end

-- Grid with N equal columns
function Container:Grid(columns, opts)
    opts = opts or {}
    columns = columns or 3
    local S = Boolean.Style
    local frame = create("Frame", {
        Name = "Grid",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self:_order(),
        Parent = self.Items,
    }, {
        create("UIGridLayout", {
            CellSize = UDim2.new(1 / columns, -(opts.Gap or 8), 0, opts.CellHeight or S.FrameHeight),
            CellPadding = UDim2.fromOffset(opts.Gap or 8, S.Spacing),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    return newContainer(self.Window, frame, "Grid")
end

-- Indented block
function Container:Indent(amount)
    local frame = create("Frame", {
        Name = "Indent",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self:_order(),
        Parent = self.Items,
    }, { list(), pad(0, 0, 0, amount or Boolean.Style.Indent) })
    return newContainer(self.Window, frame, "List")
end

function Container:Spacing(px)
    create("Frame", {
        Name = "Spacing",
        Size = UDim2.new(1, 0, 0, px or 6),
        BackgroundTransparency = 1,
        LayoutOrder = self:_order(),
        Parent = self.Items,
    })
end

function Container:Separator(text)
    local T, S = self.Theme, Boolean.Style
    local frame = create("Frame", {
        Name = "Separator",
        Size = UDim2.new(1, 0, 0, text and S.FrameHeight or 7),
        BackgroundTransparency = 1,
        LayoutOrder = self:_order(),
        Parent = self.Items,
    })
    local x = 0
    if text then
        local w = textWidth(text)
        label(frame, text, T.TextDim, { Size = UDim2.new(0, w, 1, 0) })
        x = w + 8
    end
    create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, x, 0.5, 0),
        Size = UDim2.new(1, -x, 0, 1),
        BackgroundColor3 = T.Separator,
        BorderSizePixel = 0,
        Parent = frame,
    })
end

----------------------------------------------------------------------------------------------------
-- Text
----------------------------------------------------------------------------------------------------

function Container:Text(text, opts)
    opts = opts or {}
    local T, S = self.Theme, Boolean.Style
    local color = opts.Color or (opts.Dim and T.TextDim or T.Text)
    local l
    if self.Mode == "Row" then
        l = label(self.Items, text, color, {
            Size = UDim2.fromOffset(textWidth(text), S.FrameHeight),
            TextTruncate = Enum.TextTruncate.None,
            LayoutOrder = self:_order(),
        })
    else
        l = label(self.Items, text, color, {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            LayoutOrder = self:_order(),
        })
        create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), Parent = l })
    end
    attachTooltip(l, opts.Tooltip)
    return {
        Set = function(_, newText)
            l.Text = tostring(newText)
            if self.Mode == "Row" then l.Size = UDim2.fromOffset(textWidth(newText), S.FrameHeight) end
        end,
        SetColor = function(_, c) tween(l, 0.15, { TextColor3 = c }) end,
    }
end

----------------------------------------------------------------------------------------------------
-- Button
----------------------------------------------------------------------------------------------------

function Container:Button(text, callback, opts)
    opts = opts or {}
    local T, S = self.Theme, Boolean.Style
    local H = S.FrameHeight
    local size
    if opts.FullWidth then
        size = UDim2.new(1, 0, 0, H)
    else
        size = UDim2.fromOffset(opts.Width or (textWidth(text) + 14), H)
    end

    local btn = create("TextButton", {
        Name = text,
        Size = size,
        BackgroundColor3 = opts.Selected and T.ButtonHover or T.Button,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = S.Font,
        TextSize = S.TextSize,
        TextColor3 = T.Text,
        Text = text,
        ClipsDescendants = true,
        LayoutOrder = self:_order(),
        Parent = self.Items,
    })
    rounding(btn)
    attachTooltip(btn, opts.Tooltip)

    local el = { Selected = opts.Selected or false }
    local function normal() return el.Selected and T.ButtonHover or T.Button end

    local hovering = false
    btn.MouseEnter:Connect(function()
        hovering = true
        tween(btn, 0.12, { BackgroundColor3 = el.Selected and T.ButtonActive or T.ButtonHover })
    end)
    btn.MouseLeave:Connect(function()
        hovering = false
        tween(btn, 0.18, { BackgroundColor3 = normal() })
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, 0.05, { BackgroundColor3 = T.ButtonActive })
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, 0.2, { BackgroundColor3 = hovering and T.ButtonHover or normal() })
    end)
    btn.MouseButton1Click:Connect(function()
        safeCall(callback)
    end)

    function el:SetText(newText)
        btn.Text = newText
        if not opts.FullWidth and not opts.Width then
            tween(btn, 0.15, { Size = UDim2.fromOffset(textWidth(newText) + 14, H) })
        end
    end
    function el:SetSelected(v)
        self.Selected = v and true or false
        tween(btn, 0.15, { BackgroundColor3 = normal() })
    end
    function el:Fire() safeCall(callback) end
    el.Instance = btn
    return self:_flag(opts, el)
end

----------------------------------------------------------------------------------------------------
-- Checkbox
----------------------------------------------------------------------------------------------------

function Container:Checkbox(text, default, callback, opts)
    opts = opts or {}
    local T, S = self.Theme, Boolean.Style
    local H = S.FrameHeight
    local k = H / 20

    local root = create("TextButton", {
        Name = text,
        Size = (self.Mode == "Row") and UDim2.fromOffset(H + 6 + textWidth(text), H) or UDim2.new(1, 0, 0, H),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = self:_order(),
        Parent = self.Items,
    })
    local box = create("Frame", {
        Size = UDim2.fromOffset(H, H),
        BackgroundColor3 = T.FrameBg,
        BorderSizePixel = 0,
        Parent = root,
    })
    rounding(box)

    local mark = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = box,
    })
    local markScale = create("UIScale", { Scale = 0, Parent = mark })
    create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(7 * k, 11.5 * k),
        Size = UDim2.fromOffset(6 * k, 2 * k),
        Rotation = 45,
        BackgroundColor3 = T.Check,
        BorderSizePixel = 0,
        Parent = mark,
    })
    create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(11.6 * k, 9.4 * k),
        Size = UDim2.fromOffset(11 * k, 2 * k),
        Rotation = -48,
        BackgroundColor3 = T.Check,
        BorderSizePixel = 0,
        Parent = mark,
    })

    label(root, text, T.Text, {
        Position = UDim2.fromOffset(H + 6, 0),
        Size = UDim2.new(1, -(H + 6), 1, 0),
    })
    attachTooltip(root, opts.Tooltip)
    feedback(box, root, T.FrameBg, T.FrameBgHover, T.FrameBgActive)

    local el = { Value = false }
    function el:Set(v, silent)
        v = v and true or false
        local changed = v ~= self.Value
        self.Value = v
        if v then
            tween(markScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
        else
            tween(markScale, 0.15, { Scale = 0 })
        end
        if changed and not silent then safeCall(callback, v) end
    end
    function el:Get() return self.Value end
    el.Instance = root

    root.MouseButton1Click:Connect(function()
        if opts._click then opts._click() else el:Set(not el.Value) end
    end)

    el:Set(default, true)
    return self:_flag(opts, el)
end

-- Exclusive checkbox grid (like attachment pickers)
function Container:Radio(options, default, callback, opts)
    opts = opts or {}
    local grid = self:Grid(opts.Columns or 3)
    local el = { Value = default, Boxes = {} }
    if el.Value == nil then el.Value = options[1] end

    function el:Set(option, silent)
        local changed = option ~= self.Value
        self.Value = option
        for key, box in pairs(self.Boxes) do box:Set(key == option, true) end
        if changed and not silent then safeCall(callback, option) end
    end
    function el:Get() return self.Value end

    for _, option in ipairs(options) do
        el.Boxes[option] = grid:Checkbox(tostring(option), option == el.Value, nil, {
            _click = function() el:Set(option) end,
        })
    end
    return self:_flag(opts, el)
end

----------------------------------------------------------------------------------------------------
-- Slider
----------------------------------------------------------------------------------------------------

function Container:Slider(text, opts, callback)
    opts = opts or {}
    local T, S = self.Theme, Boolean.Style
    local min, max = opts.Min or 0, opts.Max or 100
    local decimals = opts.Decimals or 0
    local GW = 10

    local root, fw = self:_widget(text, opts)
    local bar = create("TextButton", {
        Name = "Bar",
        Size = UDim2.new(fw.Scale, fw.Offset, 1, 0),
        BackgroundColor3 = T.FrameBg,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = root,
    })
    rounding(bar)
    local grab = create("Frame", {
        Name = "Grab",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.new(0, GW, 1, -4),
        BackgroundColor3 = T.Grab,
        BorderSizePixel = 0,
        Parent = bar,
    })
    rounding(grab)
    local valueText = label(bar, "", T.Text, {
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 2,
    })

    local el = { Value = nil }
    local function display(v)
        if opts.Format then return string.format(opts.Format, v) end
        return fmtNumber(v, decimals) .. (opts.Suffix or "")
    end

    function el:Set(v, silent, instant)
        v = math.clamp(tonumber(v) or min, min, max)
        if opts.Step then
            v = math.clamp(math.floor((v - min) / opts.Step + 0.5) * opts.Step + min, min, max)
        end
        local m = 10 ^ decimals
        v = math.floor(v * m + 0.5) / m
        local changed = v ~= self.Value
        self.Value = v
        local p = (max == min) and 0 or (v - min) / (max - min)
        local pos = UDim2.new(p, 2 - p * (GW + 4), 0.5, 0)
        if instant then grab.Position = pos else tween(grab, 0.09, { Position = pos }) end
        valueText.Text = display(v)
        if changed and not silent then safeCall(callback, v) end
    end
    function el:Get() return self.Value end

    -- Ctrl+Click to type a value
    local function beginEdit()
        local box = create("TextBox", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = T.FrameBgActive,
            BorderSizePixel = 0,
            Font = S.Font,
            TextSize = S.TextSize,
            TextColor3 = T.Text,
            Text = tostring(el.Value),
            ClearTextOnFocus = false,
            ZIndex = 3,
            Parent = bar,
        })
        box:CaptureFocus()
        box.FocusLost:Connect(function()
            local n = tonumber((string.gsub(box.Text, "[^%d%.%-]", "")))
            if n then el:Set(n) end
            box:Destroy()
        end)
    end

    local editing = false
    self:_drag(bar, function(pos, first)
        if first and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
            editing = true
            beginEdit()
            return
        end
        if editing then return end
        local w = bar.AbsoluteSize.X - GW - 4
        local p = math.clamp((pos.X - bar.AbsolutePosition.X - 2 - GW / 2) / math.max(w, 1), 0, 1)
        el:Set(min + (max - min) * p)
        if first then tween(grab, 0.1, { BackgroundColor3 = T.GrabActive }) end
    end, function()
        editing = false
        tween(grab, 0.2, { BackgroundColor3 = T.Grab })
    end)
    bar.MouseEnter:Connect(function() tween(bar, 0.12, { BackgroundColor3 = T.FrameBgHover }) end)
    bar.MouseLeave:Connect(function() tween(bar, 0.18, { BackgroundColor3 = T.FrameBg }) end)

    el.Instance = root
    el:Set(opts.Default or min, true, true)
    return self:_flag(opts, el)
end

----------------------------------------------------------------------------------------------------
-- Number input  [ 1.00 ][-][+] Label
----------------------------------------------------------------------------------------------------

function Container:InputNumber(text, opts, callback)
    opts = opts or {}
    local T, S = self.Theme, Boolean.Style
    local H = S.FrameHeight
    local step = opts.Step or 1
    local decimals = opts.Decimals
    if decimals == nil then decimals = (step % 1 ~= 0) and 2 or 0 end
    opts.DefaultWidth = opts.DefaultWidth or 120

    local root, fw = self:_widget(text, opts)
    local box = create("TextBox", {
        Size = UDim2.new(fw.Scale, fw.Offset - 2 * (H + 2), 1, 0),
        BackgroundColor3 = T.FrameBg,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = S.Font,
        TextSize = S.TextSize,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "",
        Parent = root,
    }, { pad(0, 6, 0, 6) })
    rounding(box)

    local function stepButton(symbol, x)
        local b = create("TextButton", {
            Position = UDim2.new(fw.Scale, fw.Offset + x, 0, 0),
            Size = UDim2.fromOffset(H, H),
            BackgroundColor3 = T.Button,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = S.Font,
            TextSize = S.TextSize,
            TextColor3 = T.Text,
            Text = symbol,
            Parent = root,
        })
        rounding(b)
        feedback(b, b, T.Button, T.ButtonHover, T.ButtonActive)
        return b
    end
    local minus = stepButton("-", -(2 * H + 2))
    local plus = stepButton("+", -H)

    local el = { Value = nil }
    function el:Set(v, silent)
        v = tonumber(v) or 0
        if opts.Min then v = math.max(v, opts.Min) end
        if opts.Max then v = math.min(v, opts.Max) end
        local m = 10 ^ decimals
        v = math.floor(v * m + 0.5) / m
        local changed = v ~= self.Value
        self.Value = v
        box.Text = fmtNumber(v, decimals)
        if changed and not silent then safeCall(callback, v) end
    end
    function el:Get() return self.Value end

    -- hold to repeat
    local function holdRepeat(btn, dir)
        local holding = 0
        btn.MouseButton1Down:Connect(function()
            holding = holding + 1
            local id = holding
            el:Set(el.Value + step * dir)
            task.delay(0.4, function()
                while holding == id do
                    el:Set(el.Value + step * dir)
                    task.wait(0.05)
                end
            end)
        end)
        local function stop() holding = holding + 1 end
        btn.MouseButton1Up:Connect(stop)
        btn.MouseLeave:Connect(stop)
    end
    holdRepeat(minus, -1)
    holdRepeat(plus, 1)

    box.Focused:Connect(function() tween(box, 0.12, { BackgroundColor3 = T.FrameBgActive }) end)
    box.FocusLost:Connect(function()
        tween(box, 0.18, { BackgroundColor3 = T.FrameBg })
        local n = tonumber((string.gsub(box.Text, "[^%d%.%-]", "")))
        if n then el:Set(n) else box.Text = fmtNumber(el.Value, decimals) end
    end)

    el.Instance = root
    el:Set(opts.Default or 0, true)
    return self:_flag(opts, el)
end

----------------------------------------------------------------------------------------------------
-- Text input
----------------------------------------------------------------------------------------------------

function Container:Input(text, opts, callback)
    opts = opts or {}
    local T, S = self.Theme, Boolean.Style
    opts.DefaultWidth = opts.DefaultWidth or 140

    local root, fw = self:_widget(text, opts)
    local box = create("TextBox", {
        Size = UDim2.new(fw.Scale, fw.Offset, 1, 0),
        BackgroundColor3 = T.FrameBg,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = S.Font,
        TextSize = S.TextSize,
        TextColor3 = T.Text,
        PlaceholderText = opts.Placeholder or "",
        PlaceholderColor3 = T.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = opts.Default or "",
        Parent = root,
    }, { pad(0, 6, 0, 6) })
    rounding(box)
    local focusStroke = stroke(T.Accent, 1)
    focusStroke.Parent = box

    local el = { Value = box.Text }
    box.MouseEnter:Connect(function()
        if not box:IsFocused() then tween(box, 0.12, { BackgroundColor3 = T.FrameBgHover }) end
    end)
    box.MouseLeave:Connect(function()
        if not box:IsFocused() then tween(box, 0.18, { BackgroundColor3 = T.FrameBg }) end
    end)
    box.Focused:Connect(function()
        tween(box, 0.12, { BackgroundColor3 = T.FrameBgActive })
        tween(focusStroke, 0.15, { Transparency = 0.2 })
    end)
    box.FocusLost:Connect(function(enter)
        tween(box, 0.18, { BackgroundColor3 = T.FrameBg })
        tween(focusStroke, 0.2, { Transparency = 1 })
        local value = box.Text
        if opts.Numeric then
            value = string.gsub(value, "[^%d%.%-]", "")
            box.Text = value
        end
        el.Value = value
        safeCall(callback, value, enter)
        if opts.ClearOnSubmit and enter then box.Text = "" end
    end)

    function el:Set(v, silent)
        box.Text = tostring(v)
        self.Value = box.Text
        if not silent then safeCall(callback, self.Value, false) end
    end
    function el:Get() return self.Value end
    el.Instance = root
    return self:_flag(opts, el)
end

----------------------------------------------------------------------------------------------------
-- Combo (dropdown)
----------------------------------------------------------------------------------------------------

function Container:Combo(text, options, default, callback, opts)
    opts = opts or {}
    local T, S = self.Theme, Boolean.Style
    local H = S.FrameHeight
    local multi = opts.Multi
    opts.DefaultWidth = opts.DefaultWidth or 140

    local root, fw = self:_widget(text, opts)
    local field = create("TextButton", {
        Size = UDim2.new(fw.Scale, fw.Offset, 1, 0),
        BackgroundColor3 = T.FrameBg,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = root,
    })
    rounding(field)
    local shown = label(field, "", T.Text, {
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -(H + 10), 1, 0),
    })
    local arrowBox = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(H, H),
        BackgroundColor3 = T.Button,
        BorderSizePixel = 0,
        Parent = field,
    })
    rounding(arrowBox)
    local arrow = triangle(arrowBox, 7, T.Text)
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.Position = UDim2.fromScale(0.5, 0.5)

    local el = { Options = options or {}, Open = false }
    if multi then
        el.Value = type(default) == "table" and default or {}
    else
        el.Value = default
    end

    local function isSelected(o)
        if multi then return table.find(el.Value, o) ~= nil end
        return el.Value == o
    end
    local function refreshText()
        if multi then
            shown.Text = (#el.Value > 0) and table.concat(el.Value, ", ") or (opts.Placeholder or "None")
        else
            shown.Text = (el.Value ~= nil) and tostring(el.Value) or (opts.Placeholder or "None")
        end
        shown.TextColor3 = ((multi and #el.Value == 0) or (not multi and el.Value == nil)) and T.TextDim or T.Text
    end

    local popup
    local function buildPopup()
        local count = math.min(#el.Options, opts.MaxItems or 8)
        local height = math.max(count, 1) * H + 2
        popup = create("ScrollingFrame", {
            Name = "ComboPopup",
            Size = UDim2.fromOffset(field.AbsoluteSize.X, 0),
            BackgroundColor3 = T.PopupBg,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = T.Scrollbar,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ClipsDescendants = true,
            ZIndex = 10,
            Parent = State.Overlay,
        }, { stroke(T.Border), list(0), pad(1) })
        rounding(popup)

        for i, o in ipairs(el.Options) do
            local sel = isSelected(o)
            local item = create("TextButton", {
                Size = UDim2.new(1, 0, 0, H),
                BackgroundColor3 = sel and T.Header or T.HeaderHover,
                BackgroundTransparency = sel and 0 or 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = i,
                ZIndex = 11,
                Parent = popup,
            })
            label(item, tostring(o), T.Text, {
                Position = UDim2.fromOffset(6, 0),
                Size = UDim2.new(1, -12, 1, 0),
                ZIndex = 12,
            })
            item.MouseEnter:Connect(function()
                tween(item, 0.1, { BackgroundTransparency = 0, BackgroundColor3 = T.HeaderHover })
            end)
            item.MouseLeave:Connect(function()
                local s = isSelected(o)
                tween(item, 0.15, { BackgroundTransparency = s and 0 or 1, BackgroundColor3 = T.Header })
            end)
            item.MouseButton1Click:Connect(function()
                if multi then
                    local idx = table.find(el.Value, o)
                    if idx then table.remove(el.Value, idx) else table.insert(el.Value, o) end
                    refreshText()
                    safeCall(callback, el.Value)
                else
                    el.Value = o
                    refreshText()
                    closePopup()
                    safeCall(callback, o)
                end
            end)
        end

        tween(popup, 0.2, { Size = UDim2.fromOffset(field.AbsoluteSize.X, height) })
    end

    local function setOpen(state)
        if state then
            el.Open = true
            buildPopup()
            tween(arrow, 0.2, { Rotation = 180 })
            tween(arrowBox, 0.15, { BackgroundColor3 = T.ButtonHover })
            local myPopup = popup
            openPopup(myPopup, field, function()
                local a = field.AbsolutePosition
                myPopup.Position = UDim2.fromOffset(a.X, a.Y + H + 1)
            end, function()
                el.Open = false
                tween(arrow, 0.2, { Rotation = 0 })
                tween(arrowBox, 0.15, { BackgroundColor3 = T.Button })
                local tw = tween(myPopup, 0.15, { Size = UDim2.fromOffset(myPopup.AbsoluteSize.X, 0) })
                tw.Completed:Connect(function() myPopup:Destroy() end)
            end)
        else
            closePopup()
        end
    end

    field.MouseButton1Click:Connect(function() setOpen(not el.Open) end)
    field.MouseEnter:Connect(function() tween(field, 0.12, { BackgroundColor3 = T.FrameBgHover }) end)
    field.MouseLeave:Connect(function() tween(field, 0.18, { BackgroundColor3 = T.FrameBg }) end)

    function el:Set(v, silent)
        if multi then self.Value = type(v) == "table" and v or { v } else self.Value = v end
        refreshText()
        if not silent then safeCall(callback, self.Value) end
    end
    function el:Get() return self.Value end
    function el:Refresh(newOptions, keep)
        self.Options = newOptions or {}
        if not keep then self.Value = multi and {} or nil end
        if self.Open then closePopup() end
        refreshText()
    end

    el.Instance = root
    refreshText()
    return self:_flag(opts, el)
end

----------------------------------------------------------------------------------------------------
-- Color editor  [■][#RRGGBB] Label   (click the swatch for the picker)
----------------------------------------------------------------------------------------------------

function Container:ColorEdit(text, default, callback, opts)
    opts = opts or {}
    local T, S = self.Theme, Boolean.Style
    local H = S.FrameHeight
    opts.DefaultWidth = opts.DefaultWidth or 130

    local root, fw = self:_widget(text, opts)
    local color = default or Color3.new(1, 1, 1)
    local h, s, v = color:ToHSV()

    local swatch = create("TextButton", {
        Size = UDim2.fromOffset(H, H),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = root,
    }, { stroke(T.Border) })
    rounding(swatch)
    local hexBox = create("TextBox", {
        Position = UDim2.fromOffset(H + 4, 0),
        Size = UDim2.new(fw.Scale, fw.Offset - H - 4, 1, 0),
        BackgroundColor3 = T.FrameBg,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = S.Font,
        TextSize = S.TextSize,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = toHex(color),
        Parent = root,
    }, { pad(0, 6, 0, 6) })
    rounding(hexBox)

    local el = { Value = color, Open = false }
    local refs = {}

    local function apply(silent)
        local c = Color3.fromHSV(h, s, v)
        el.Value = c
        swatch.BackgroundColor3 = c
        hexBox.Text = toHex(c)
        if refs.sv then
            refs.sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            refs.svCursor.Position = UDim2.fromScale(s, 1 - v)
            refs.hueCursor.Position = UDim2.fromScale(0.5, h)
            refs.preview.BackgroundColor3 = c
            refs.rgb.Text = string.format("R %d  G %d  B %d",
                math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
        end
        if not silent then safeCall(callback, c) end
    end

    local function buildPopup()
        local PW, PH = 204, 186
        local popup = create("Frame", {
            Name = "ColorPopup",
            Size = UDim2.fromOffset(PW, 0),
            BackgroundColor3 = T.PopupBg,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 10,
            Parent = State.Overlay,
        }, { stroke(T.Border) })
        rounding(popup)

        local sv = create("Frame", {
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.fromOffset(160, 140),
            BackgroundColor3 = Color3.fromHSV(h, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 11,
            Parent = popup,
        })
        create("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 12,
            Parent = sv,
        }, {
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
            BorderSizePixel = 0,
            ZIndex = 13,
            Parent = sv,
        }, {
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
            Size = UDim2.fromOffset(8, 8),
            BackgroundTransparency = 1,
            ZIndex = 14,
            Parent = sv,
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5 }),
        })

        local keys = {}
        for i = 0, 6 do
            table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
        end
        local hue = create("Frame", {
            Position = UDim2.fromOffset(176, 8),
            Size = UDim2.fromOffset(20, 140),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 11,
            Parent = popup,
        }, { create("UIGradient", { Rotation = 90, Color = ColorSequence.new(keys) }) })
        local hueCursor = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 4, 0, 3),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 12,
            Parent = hue,
        }, { create("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.5 }) })

        local preview = create("Frame", {
            Position = UDim2.fromOffset(8, 156),
            Size = UDim2.fromOffset(H, H),
            BackgroundColor3 = el.Value,
            BorderSizePixel = 0,
            ZIndex = 11,
            Parent = popup,
        }, { stroke(T.Border) })
        local rgb = label(popup, "", T.TextDim, {
            Position = UDim2.fromOffset(H + 14, 156),
            Size = UDim2.new(1, -(H + 22), 0, H),
            ZIndex = 11,
        })

        refs = { sv = sv, svCursor = svCursor, hueCursor = hueCursor, preview = preview, rgb = rgb }

        self:_drag(sv, function(pos)
            if not sv.Parent then return end
            s = math.clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
            v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
            apply()
        end)
        self:_drag(hue, function(pos)
            if not hue.Parent then return end
            h = math.clamp((pos.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
            apply()
        end)

        apply(true)
        tween(popup, 0.2, { Size = UDim2.fromOffset(PW, PH) })
        return popup
    end

    swatch.MouseButton1Click:Connect(function()
        if el.Open then closePopup() return end
        el.Open = true
        local popup = buildPopup()
        openPopup(popup, swatch, function()
            local a = swatch.AbsolutePosition
            popup.Position = UDim2.fromOffset(a.X, a.Y + H + 2)
        end, function()
            el.Open = false
            refs = {}
            local tw = tween(popup, 0.15, { Size = UDim2.fromOffset(popup.AbsoluteSize.X, 0) })
            tw.Completed:Connect(function() popup:Destroy() end)
        end)
    end)

    hexBox.FocusLost:Connect(function()
        local c = fromHex(hexBox.Text)
        if c then
            h, s, v = c:ToHSV()
            apply()
        else
            hexBox.Text = toHex(el.Value)
        end
    end)

    function el:Set(c, silent)
        h, s, v = c:ToHSV()
        apply(silent)
    end
    function el:Get() return self.Value end
    el.Instance = root
    return self:_flag(opts, el)
end

----------------------------------------------------------------------------------------------------
-- Keybind
----------------------------------------------------------------------------------------------------

function Container:Keybind(text, default, callback, opts)
    opts = opts or {}
    local T, S = self.Theme, Boolean.Style
    opts.DefaultWidth = opts.DefaultWidth or 100

    local root, fw = self:_widget(text, opts)
    local field = create("TextButton", {
        Size = UDim2.new(fw.Scale, fw.Offset, 1, 0),
        BackgroundColor3 = T.FrameBg,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = S.Font,
        TextSize = S.TextSize,
        TextColor3 = T.Text,
        Text = "",
        Parent = root,
    })
    rounding(field)
    feedback(field, field, T.FrameBg, T.FrameBgHover, T.FrameBgActive)

    local el = { Value = default, Listening = false }
    local function show()
        field.Text = el.Value and el.Value.Name or "None"
        field.TextColor3 = el.Value and T.Text or T.TextDim
    end
    function el:Set(key)
        self.Value = key
        show()
        safeCall(opts.Changed, key)
    end
    function el:Get() return self.Value end

    field.MouseButton1Click:Connect(function()
        el.Listening = true
        field.Text = "..."
        tween(field, 0.15, { TextColor3 = T.Accent })
    end)

    self.Window:_track(UserInputService.InputBegan:Connect(function(input, processed)
        if el.Listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                el.Listening = false
                if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                    el:Set(nil)
                else
                    el:Set(input.KeyCode)
                end
            end
            return
        end
        if processed then return end
        if el.Value and input.KeyCode == el.Value then safeCall(callback, el.Value) end
    end))

    el.Instance = root
    show()
    return self:_flag(opts, el)
end

----------------------------------------------------------------------------------------------------
-- Progress bar
----------------------------------------------------------------------------------------------------

function Container:Progress(fraction, opts)
    opts = opts or {}
    local T = self.Theme
    local root, fw = self:_widget(opts.Label, opts)
    local bar = create("Frame", {
        Size = UDim2.new(fw.Scale, fw.Offset, 1, 0),
        BackgroundColor3 = T.FrameBg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = root,
    })
    rounding(bar)
    local fill = create("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = T.Grab,
        BorderSizePixel = 0,
        Parent = bar,
    })
    rounding(fill)
    local overlay = label(bar, "", T.Text, { TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2 })

    local el = { Value = 0 }
    function el:Set(f, text)
        f = math.clamp(tonumber(f) or 0, 0, 1)
        self.Value = f
        tween(fill, 0.3, { Size = UDim2.fromScale(f, 1) })
        overlay.Text = text or (tostring(math.floor(f * 100 + 0.5)) .. "%")
    end
    function el:Get() return self.Value end
    el:Set(fraction or 0, opts.Text)
    return el
end

----------------------------------------------------------------------------------------------------
-- 3D preview viewport
----------------------------------------------------------------------------------------------------

function Container:Viewport(opts)
    opts = opts or {}
    local T, S = self.Theme, Boolean.Style
    local frame = create("Frame", {
        Name = "Viewport",
        Size = UDim2.new(1, 0, 0, opts.Height or 200),
        BackgroundColor3 = opts.Background or T.Viewport,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = self:_order(),
        Parent = self.Items,
    })
    rounding(frame)

    local vpf = create("ViewportFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Ambient = Color3.fromRGB(150, 150, 150),
        LightColor = Color3.fromRGB(255, 255, 255),
        LightDirection = Vector3.new(-1, -1, -1),
        Parent = frame,
    })
    local world = create("WorldModel", { Parent = vpf })
    local camera = create("Camera", { FieldOfView = 40, Parent = vpf })
    vpf.CurrentCamera = camera

    if opts.Crosshair ~= false then
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(0, 1, 1, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.88,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = frame,
        })
        create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.88,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = frame,
        })
    end

    local title = label(frame, opts.Title or "PREVIEW", T.TextDim, {
        Position = UDim2.fromOffset(0, 16),
        Size = UDim2.new(1, 0, 0, 20),
        TextSize = S.TextSize + 4,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 3,
    })
    local subtitle = label(frame, opts.Subtitle or "", T.TextDim, {
        Position = UDim2.fromOffset(0, 38),
        Size = UDim2.new(1, 0, 0, 30),
        TextSize = S.TextSize - 2,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        ZIndex = 3,
    })

    local el = { Model = nil, Yaw = opts.Yaw or 35, Pitch = opts.Pitch or 12, Distance = 10, Spin = opts.Spin or 0 }
    local center = Vector3.new()

    local function updateCamera()
        local rot = CFrame.Angles(0, math.rad(el.Yaw), 0) * CFrame.Angles(math.rad(-el.Pitch), 0, 0)
        camera.CFrame = CFrame.new(center) * rot * CFrame.new(0, 0, el.Distance)
    end

    function el:SetModel(model, keepAngle)
        if self.Model then self.Model:Destroy() self.Model = nil end
        if not model then return end
        local clone
        local ok = pcall(function()
            local old = model.Archivable
            model.Archivable = true
            clone = model:Clone()
            model.Archivable = old
        end)
        if not ok or not clone then return end
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BaseScript") then d:Destroy() end
        end
        clone.Parent = world
        self.Model = clone
        local cf, size
        if clone:IsA("Model") then
            cf, size = clone:GetBoundingBox()
        elseif clone:IsA("BasePart") then
            cf, size = clone.CFrame, clone.Size
        else
            cf, size = CFrame.new(), Vector3.new(4, 4, 4)
        end
        center = cf.Position
        local radius = size.Magnitude / 2
        self.Distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * (opts.Zoom or 1.1)
        if not keepAngle then
            self.Yaw, self.Pitch = opts.Yaw or 35, opts.Pitch or 12
        end
        updateCamera()
        return clone
    end
    function el:SetTitle(t) title.Text = t end
    function el:SetSubtitle(t) subtitle.Text = t end
    function el:SetAngle(yaw, pitch) self.Yaw, self.Pitch = yaw or self.Yaw, pitch or self.Pitch updateCamera() end
    el.WorldModel = world
    el.Camera = camera

    -- drag to orbit, scroll to zoom
    local input = create("TextButton", {
        Name = "Input",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 4,
        Parent = frame,
    })
    local last
    self:_drag(input, function(pos, first)
        if first then last = pos return end
        local d = pos - last
        last = pos
        el.Yaw = el.Yaw - d.X * 0.5
        el.Pitch = math.clamp(el.Pitch + d.Y * 0.4, -80, 80)
        updateCamera()
    end)
    input.InputChanged:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseWheel then
            el.Distance = math.max(1, el.Distance * (1 - io.Position.Z * 0.1))
            updateCamera()
        end
    end)
    if el.Spin ~= 0 then
        self.Window:_track(RunService.RenderStepped:Connect(function(dt)
            if el.Model and frame.Parent then
                el.Yaw = el.Yaw + el.Spin * dt
                updateCamera()
            end
        end))
    end

    if opts.Model then el:SetModel(opts.Model) end
    updateCamera()
    return el
end

----------------------------------------------------------------------------------------------------
-- Window
----------------------------------------------------------------------------------------------------

function Boolean:Window(cfg)
    cfg = cfg or {}
    local S = Boolean.Style
    local gui = getGui(cfg.Parent)
    local T = buildTheme(cfg.Accent)
    local TH = S.TitleHeight

    local size = cfg.Size or Vector2.new(340, 380)
    if typeof(size) == "UDim2" then size = Vector2.new(size.X.Offset, size.Y.Offset) end
    local index = #Boolean.Windows

    local win = setmetatable({
        Theme = T,
        Size = size,
        MinSize = cfg.MinSize or Vector2.new(200, 120),
        Collapsed = cfg.Collapsed or false,
        Visible = true,
        Conns = {},
        Order = 0,
        Mode = "List",
        AnimId = 0,
    }, Window)
    win.Window = win

    State.Z = State.Z + 10
    local root = create("Frame", {
        Name = cfg.Title or "Window",
        Position = cfg.Position or UDim2.fromOffset(80 + index * 36, 80 + index * 36),
        Size = UDim2.fromOffset(size.X, TH),
        BackgroundColor3 = T.WindowBg,
        BackgroundTransparency = cfg.Transparency or 0.04,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = State.Z,
        Parent = gui,
    }, { stroke(T.Border) })
    rounding(root, S.WindowRounding)
    local scale = create("UIScale", { Scale = 1, Parent = root })
    win.Root, win.Scale = root, scale

    -- Title bar ---------------------------------------------------------------------------------
    local titleBar = create("TextButton", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, TH),
        BackgroundColor3 = T.TitleBg,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 3,
        Parent = root,
    })
    win.TitleBar = titleBar

    local collapseBtn = create("TextButton", {
        Size = UDim2.new(0, 22, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 4,
        Parent = titleBar,
    })
    local arrow = triangle(collapseBtn, 9, T.Text)
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.Position = UDim2.fromScale(0.5, 0.5)
    arrow.Rotation = win.Collapsed and -90 or 0
    win.Arrow = arrow

    win.TitleLabel = label(titleBar, cfg.Title or "Window", T.Text, {
        Position = UDim2.fromOffset(24, 0),
        Size = UDim2.new(1, -50, 1, 0),
        ZIndex = 4,
    })

    local closeBtn
    if cfg.Closable ~= false then
        closeBtn = create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -3, 0.5, 0),
            Size = UDim2.fromOffset(TH - 4, TH - 4),
            BackgroundColor3 = T.ButtonHover,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 4,
            Parent = titleBar,
        })
        rounding(closeBtn)
        for _, rot in ipairs({ 45, -45 }) do
            create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(11, 2),
                Rotation = rot,
                BackgroundColor3 = T.Text,
                BorderSizePixel = 0,
                ZIndex = 5,
                Parent = closeBtn,
            })
        end
        closeBtn.MouseEnter:Connect(function() tween(closeBtn, 0.12, { BackgroundTransparency = 0 }) end)
        closeBtn.MouseLeave:Connect(function() tween(closeBtn, 0.18, { BackgroundTransparency = 1 }) end)
        closeBtn.MouseButton1Click:Connect(function()
            win:SetVisible(false)
            safeCall(cfg.OnClose)
        end)
    end

    -- Content -----------------------------------------------------------------------------------
    local content = create("ScrollingFrame", {
        Name = "Content",
        Position = UDim2.fromOffset(0, TH),
        Size = UDim2.new(1, 0, 1, -TH),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = S.ScrollbarSize,
        ScrollBarImageColor3 = T.Scrollbar,
        VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 1,
        Parent = root,
    }, { list(), pad(S.Padding) })
    win.Items = content
    win.Content = content

    -- Resize grip -------------------------------------------------------------------------------
    if cfg.Resizable ~= false then
        local grip = create("TextButton", {
            Name = "ResizeGrip",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 6,
            Parent = root,
        })
        local parts = {}
        for i = 1, 12 do
            table.insert(parts, create("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -1, 0, i),
                Size = UDim2.fromOffset(i, 1),
                BackgroundColor3 = T.ResizeGrip,
                BorderSizePixel = 0,
                ZIndex = 6,
                Parent = grip,
            }))
        end
        grip.MouseEnter:Connect(function() colorParts(parts, T.ResizeHover, 0.12) end)
        grip.MouseLeave:Connect(function() colorParts(parts, T.ResizeGrip, 0.18) end)

        local resizing, startPos, startSize = false, nil, nil
        grip.InputBegan:Connect(function(input)
            if isPress(input) and not win.Collapsed then
                resizing = true
                startPos = screenPos(input)
                startSize = win.Size
                colorParts(parts, T.Accent)
            end
        end)
        win:_track(UserInputService.InputChanged:Connect(function(input)
            if resizing and isMove(input) then
                local d = screenPos(input) - startPos
                win.Size = Vector2.new(
                    math.max(win.MinSize.X, startSize.X + d.X),
                    math.max(win.MinSize.Y, startSize.Y + d.Y)
                )
                root.Size = UDim2.fromOffset(win.Size.X, win.Size.Y)
            end
        end))
        win:_track(UserInputService.InputEnded:Connect(function(input)
            if resizing and isPress(input) then
                resizing = false
                colorParts(parts, T.ResizeGrip, 0.2)
            end
        end))
    end

    -- Dragging + double-click collapse ----------------------------------------------------------
    local dragging, dragStart, startPos = false, nil, nil
    local lastClick = 0
    titleBar.InputBegan:Connect(function(input)
        if not isPress(input) then return end
        local pos = screenPos(input)
        if inside(collapseBtn, pos) or (closeBtn and inside(closeBtn, pos)) then return end
        if os.clock() - lastClick < 0.3 then
            win:SetCollapsed(not win.Collapsed)
            lastClick = 0
            return
        end
        lastClick = os.clock()
        dragging = true
        dragStart = pos
        startPos = root.Position
        closePopup()
    end)
    win:_track(UserInputService.InputChanged:Connect(function(input)
        if dragging and isMove(input) then
            local d = screenPos(input) - dragStart
            root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    win:_track(UserInputService.InputEnded:Connect(function(input)
        if isPress(input) then dragging = false end
    end))

    collapseBtn.MouseButton1Click:Connect(function()
        win:SetCollapsed(not win.Collapsed)
    end)

    table.insert(Boolean.Windows, win)
    win:Focus()
    if cfg.Visible == false then
        win.Visible = false
        root.Visible = false
    else
        win:_animateIn()
    end
    return win
end

function Window:_track(conn)
    table.insert(self.Conns, conn)
    return conn
end

function Window:_targetHeight()
    if self.Collapsed then return Boolean.Style.TitleHeight end
    return self.Size.Y
end

function Window:_animateIn()
    self.AnimId = self.AnimId + 1
    local r = self.Root
    r.Visible = true
    r.Size = UDim2.fromOffset(self.Size.X, Boolean.Style.TitleHeight)
    self.Scale.Scale = 0.96
    tween(self.Scale, 0.3, { Scale = 1 })
    tween(r, 0.38, { Size = UDim2.fromOffset(self.Size.X, self:_targetHeight()) })
end

function Window:_animateOut()
    self.AnimId = self.AnimId + 1
    local id = self.AnimId
    local r = self.Root
    tween(self.Scale, 0.2, { Scale = 0.96 })
    tween(r, 0.2, { Size = UDim2.fromOffset(self.Size.X, Boolean.Style.TitleHeight) })
    task.delay(0.2, function()
        if self.AnimId == id then r.Visible = false end
    end)
end

function Window:Focus()
    State.Z = State.Z + 10
    self.Root.ZIndex = State.Z
    State.Focused = self
    for _, w in ipairs(Boolean.Windows) do
        tween(w.TitleBar, 0.15, { BackgroundColor3 = (w == self) and w.Theme.TitleBgActive or w.Theme.TitleBg })
    end
end

function Window:SetCollapsed(state)
    self.Collapsed = state and true or false
    tween(self.Arrow, 0.22, { Rotation = self.Collapsed and -90 or 0 })
    tween(self.Root, 0.3, { Size = UDim2.fromOffset(self.Size.X, self:_targetHeight()) })
end

function Window:SetVisible(state)
    state = state and true or false
    if state == self.Visible then return end
    self.Visible = state
    if not Boolean.Visible then return end
    if state then
        self:_animateIn()
        self:Focus()
    else
        closePopup()
        self:_animateOut()
    end
end

function Window:ToggleVisible()
    self:SetVisible(not self.Visible)
end

function Window:SetTitle(text)
    self.TitleLabel.Text = text
end

function Window:SetSize(size)
    if typeof(size) == "UDim2" then size = Vector2.new(size.X.Offset, size.Y.Offset) end
    self.Size = size
    tween(self.Root, 0.3, { Size = UDim2.fromOffset(size.X, self:_targetHeight()) })
end

function Window:Destroy()
    for _, c in ipairs(self.Conns) do pcall(function() c:Disconnect() end) end
    self.Conns = {}
    local idx = table.find(Boolean.Windows, self)
    if idx then table.remove(Boolean.Windows, idx) end
    closePopup()
    self:_animateOut()
    task.delay(0.25, function() self.Root:Destroy() end)
end

----------------------------------------------------------------------------------------------------
-- Library-level
----------------------------------------------------------------------------------------------------

function Boolean:Toggle(state)
    if state == nil then state = not self.Visible end
    self.Visible = state
    closePopup()
    for _, w in ipairs(self.Windows) do
        if w.Visible then
            if state then w:_animateIn() else w:_animateOut() end
        end
    end
end

function Boolean:SetToggleKey(key)
    self.ToggleKey = key
end

function Boolean:SetAccent(color)
    -- applies to windows created after this call
    self.Accent = color
end

function Boolean:Notify(cfg)
    if type(cfg) == "string" then cfg = { Title = cfg } end
    cfg = cfg or {}
    getGui()
    local T, S = buildTheme(cfg.Accent), Boolean.Style
    local duration = cfg.Duration or 4

    local wrap = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 40,
        Parent = State.Toasts,
    })
    local card = create("Frame", {
        Position = UDim2.fromOffset(300, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.PopupBg,
        BorderSizePixel = 0,
        ZIndex = 41,
        Parent = wrap,
    }, { stroke(T.Border), list(0) })
    rounding(card, S.WindowRounding)

    local titleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, S.TitleHeight),
        BackgroundColor3 = T.TitleBgActive,
        BorderSizePixel = 0,
        LayoutOrder = 1,
        ZIndex = 42,
        Parent = card,
    })
    label(titleBar, cfg.Title or "Notification", T.Text, {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -16, 1, 0),
        ZIndex = 43,
    })
    local body = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        ZIndex = 42,
        Parent = card,
    }, { pad(6, 8, 8, 8) })
    label(body, cfg.Content or "", T.TextDim, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        ZIndex = 43,
    })
    local progressHolder = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        ZIndex = 42,
        Parent = card,
    })
    local progress = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        ZIndex = 44,
        Parent = progressHolder,
    })

    tween(card, 0.4, { Position = UDim2.fromOffset(0, 0) })
    tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
    task.delay(duration, function()
        tween(card, 0.3, { Position = UDim2.fromOffset(300, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.wait(0.32)
        wrap:Destroy()
    end)
end

----------------------------------------------------------------------------------------------------
-- v1 compatibility (CreateWindow / CreateTab / CreateButton ... still work)
----------------------------------------------------------------------------------------------------

local function decimalsOf(n)
    local s = tostring(n or 1)
    local dot = string.find(s, "%.")
    return dot and (#s - dot) or 0
end

function Boolean:CreateWindow(cfg)
    cfg = cfg or {}
    return self:Window({
        Title = cfg.Title or cfg.Name,
        Size = cfg.Size or Vector2.new(420, 440),
        Position = cfg.Position,
        Accent = cfg.Accent,
        Closable = cfg.Closable,
        OnClose = cfg.OnClose,
    })
end

function Window:CreateTab(name)
    local first = not self._hasTab
    self._hasTab = true
    return self:Header(name, first)
end

function Window:Notify(cfg) Boolean:Notify(cfg) end
function Window:SetToggleKey(key) Boolean:SetToggleKey(key) end
function Window:Toggle(state) Boolean:Toggle(state) end
function Window:Minimize(state)
    if state == nil then state = not self.Collapsed end
    self:SetCollapsed(state)
end

function Container:CreateSection(name)
    self:Separator(name)
end

function Container:CreateButton(cfg)
    cfg = cfg or {}
    return self:Button(cfg.Name or "Button", cfg.Callback, { Tooltip = cfg.Description or cfg.Tooltip, Flag = cfg.Flag })
end

function Container:CreateToggle(cfg)
    cfg = cfg or {}
    return self:Checkbox(cfg.Name or "Toggle", cfg.Default, cfg.Callback, { Tooltip = cfg.Description or cfg.Tooltip, Flag = cfg.Flag })
end

function Container:CreateSlider(cfg)
    cfg = cfg or {}
    return self:Slider(cfg.Name or "Slider", {
        Min = cfg.Min, Max = cfg.Max, Default = cfg.Default,
        Step = cfg.Increment, Decimals = decimalsOf(cfg.Increment),
        Suffix = cfg.Suffix, Tooltip = cfg.Description or cfg.Tooltip, Flag = cfg.Flag,
    }, cfg.Callback)
end

function Container:CreateDropdown(cfg)
    cfg = cfg or {}
    return self:Combo(cfg.Name or "Dropdown", cfg.Options or {}, cfg.Default, cfg.Callback, {
        Multi = cfg.Multi, Tooltip = cfg.Description or cfg.Tooltip, Flag = cfg.Flag,
    })
end

function Container:CreateInput(cfg)
    cfg = cfg or {}
    return self:Input(cfg.Name or "Input", {
        Placeholder = cfg.Placeholder, Default = cfg.Default,
        ClearOnSubmit = cfg.ClearOnFocusLost, Numeric = cfg.NumbersOnly,
        Tooltip = cfg.Description or cfg.Tooltip, Flag = cfg.Flag,
    }, cfg.Callback)
end

function Container:CreateKeybind(cfg)
    cfg = cfg or {}
    return self:Keybind(cfg.Name or "Keybind", cfg.Default, cfg.Callback, {
        Changed = cfg.Changed, Tooltip = cfg.Description or cfg.Tooltip, Flag = cfg.Flag,
    })
end

function Container:CreateColorPicker(cfg)
    cfg = cfg or {}
    return self:ColorEdit(cfg.Name or "Color", cfg.Default, cfg.Callback, {
        Tooltip = cfg.Description or cfg.Tooltip, Flag = cfg.Flag,
    })
end

function Container:CreateLabel(text)
    return self:Text(text or "", { Dim = true })
end

function Container:CreateParagraph(cfg)
    cfg = cfg or {}
    local t = self:Text(cfg.Title or "")
    local c = self:Text(cfg.Content or "", { Dim = true })
    return {
        Set = function(_, n)
            if n.Title then t:Set(n.Title) end
            if n.Content then c:Set(n.Content) end
        end,
    }
end

function Boolean:Destroy()
    for i = #self.Windows, 1, -1 do self.Windows[i]:Destroy() end
    for _, c in ipairs(State.Conns) do pcall(function() c:Disconnect() end) end
    State.Conns = {}
    if State.Gui then
        local g = State.Gui
        State.Gui = nil
        task.delay(0.3, function() g:Destroy() end)
    end
end

return Boolean
