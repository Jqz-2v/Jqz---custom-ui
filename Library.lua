local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local CoreGui = game:GetService('CoreGui')
local Teams = game:GetService('Teams')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)

local ScreenGui = Instance.new('ScreenGui')
ProtectGui(ScreenGui)
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}

getgenv().Toggles = Toggles
getgenv().Options = Options

local Jqz = {
    Registry = {};
    RegistryMap = {};
    HudRegistry = {};
    BorderMap = setmetatable({}, { __mode = 'k' });

    FontColor = Color3.fromRGB(238, 230, 255);
    DimColor = Color3.fromRGB(150, 125, 195);
    MainColor = Color3.fromRGB(44, 19, 80);
    BackgroundColor = Color3.fromRGB(0, 0, 0);
    AccentColor = Color3.fromRGB(168, 88, 255);
    OutlineColor = Color3.fromRGB(78, 33, 138);
    RiskColor = Color3.fromRGB(255, 70, 70);

    Black = Color3.new(0, 0, 0);
    White = Color3.new(1, 1, 1);
    Font = Enum.Font.GothamMedium;

    OpenedFrames = {};
    DependencyBoxes = {};
    Signals = {};
    ScreenGui = ScreenGui;
}

local RainbowStep, Hue = 0, 0
table.insert(Jqz.Signals, RunService.RenderStepped:Connect(function(dt)
    RainbowStep += dt
    if RainbowStep >= 1/60 then
        RainbowStep = 0
        Hue += 1/400
        if Hue > 1 then Hue = 0 end
        Jqz.CurrentRainbowHue = Hue
        Jqz.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end))

local function GetPlayersString()
    local t = Players:GetPlayers()
    for i = 1, #t do t[i] = t[i].Name end
    table.sort(t, function(a, b) return a < b end)
    return t
end

local function GetTeamsString()
    local t = Teams:GetTeams()
    for i = 1, #t do t[i] = t[i].Name end
    table.sort(t, function(a, b) return a < b end)
    return t
end

function Jqz:SafeCallback(f, ...)
    if not f then return end
    if not Jqz.NotifyOnError then return f(...) end
    local ok, err = pcall(f, ...)
    if not ok then
        local _, i = err:find(':%d+: ')
        Jqz:Notify(i and err:sub(i + 1) or err, 3)
    end
end

function Jqz:AttemptSave()
    if Jqz.SaveManager then Jqz.SaveManager:Save() end
end

function Jqz:Create(Class, Properties)
    local inst = type(Class) == 'string' and Instance.new(Class) or Class
    for k, v in next, Properties do inst[k] = v end
    return inst
end

function Jqz:SyncStroke(Inst)
    local s = Jqz.BorderMap[Inst]
    if s then s.Color = Inst.BorderColor3 end
end

function Jqz:Corner(Inst, Radius, NoStroke)
    Jqz:Create('UICorner', { CornerRadius = UDim.new(0, Radius or 4); Parent = Inst })
    if NoStroke then
        Inst.BorderSizePixel = 0
        return
    end
    local Stroke = Jqz:Create('UIStroke', {
        Name = 'BorderStroke';
        Color = Inst.BorderColor3;
        Thickness = 1;
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        BorderStrokePosition = Enum.BorderStrokePosition.Inner;
        Parent = Inst;
    })
    Inst.BorderSizePixel = 0
    Jqz.BorderMap[Inst] = Stroke
    local P = Inst.Parent
    if P and P:IsA('Frame') and Inst.Size == UDim2.new(1, 0, 1, 0) and P.BackgroundColor3 == Color3.new(0, 0, 0) and P.BackgroundTransparency == 0 then
        P.BackgroundTransparency = 1
        P.BorderSizePixel = 0
        Jqz.BorderMap[P] = Stroke
    end
end

function Jqz:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1
    local s = Jqz:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        Transparency = 0.55;
        LineJoinMode = Enum.LineJoinMode.Round;
        Parent = Inst;
    })
    Jqz:AddToRegistry(s, { Color = 'Black' })
    return s
end

function Jqz:CreateLabel(Properties, IsHud)
    local inst = Jqz:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Jqz.Font;
        TextColor3 = Jqz.FontColor;
        TextSize = 13;
        TextStrokeTransparency = 0;
    })
    Jqz:ApplyTextStroke(inst)
    Jqz:AddToRegistry(inst, { TextColor3 = 'FontColor' }, IsHud)
    return Jqz:Create(inst, Properties)
end

function Jqz:MakeDraggable(Frame, Cutoff)
    Frame.Active = true
    Frame.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local off = Vector2.new(Mouse.X - Frame.AbsolutePosition.X, Mouse.Y - Frame.AbsolutePosition.Y)
        if off.Y > (Cutoff or 40) then return end
        while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            Frame.Position = UDim2.new(
                0, Mouse.X - off.X + Frame.Size.X.Offset * Frame.AnchorPoint.X,
                0, Mouse.Y - off.Y + Frame.Size.Y.Offset * Frame.AnchorPoint.Y
            )
            RunService.RenderStepped:Wait()
        end
    end)
end

function Jqz:AddToolTip(Text, HoverInst)
    local X, Y = Jqz:GetTextBounds(Text, Jqz.Font, 13)
    local Tip = Jqz:Create('Frame', {
        BackgroundColor3 = Jqz.MainColor;
        BorderColor3 = Jqz.OutlineColor;
        Size = UDim2.fromOffset(X + 10, Y + 6);
        ZIndex = 100;
        Parent = Jqz.ScreenGui;
        Visible = false;
    })
    Jqz:Corner(Tip, 5)
    local Lbl = Jqz:CreateLabel({
        Position = UDim2.fromOffset(5, 3);
        Size = UDim2.fromOffset(X, Y);
        TextSize = 13;
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 101;
        Parent = Tip;
    })
    Jqz:AddToRegistry(Tip, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })
    local Hovering = false
    HoverInst.MouseEnter:Connect(function()
        if Jqz:MouseIsOverOpenedFrame() then return end
        Hovering = true
        Tip.Visible = true
        while Hovering do
            RunService.Heartbeat:Wait()
            Tip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)
    HoverInst.MouseLeave:Connect(function()
        Hovering = false
        Tip.Visible = false
    end)
end

function Jqz:OnHighlight(HoverInst, Target, On, Off)
    HoverInst.MouseEnter:Connect(function()
        local Reg = Jqz.RegistryMap[Target]
        for k, v in next, On do
            Target[k] = Jqz[v] or v
            if Reg and Reg.Properties[k] then Reg.Properties[k] = v end
        end
        Jqz:SyncStroke(Target)
    end)
    HoverInst.MouseLeave:Connect(function()
        local Reg = Jqz.RegistryMap[Target]
        for k, v in next, Off do
            Target[k] = Jqz[v] or v
            if Reg and Reg.Properties[k] then Reg.Properties[k] = v end
        end
        Jqz:SyncStroke(Target)
    end)
end

function Jqz:MouseIsOverOpenedFrame()
    for Frame in next, Jqz.OpenedFrames do
        local p, s = Frame.AbsolutePosition, Frame.AbsoluteSize
        if Mouse.X >= p.X and Mouse.X <= p.X + s.X
        and Mouse.Y >= p.Y and Mouse.Y <= p.Y + s.Y then
            return true
        end
    end
end

function Jqz:IsMouseOverFrame(Frame)
    local p, s = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= p.X and Mouse.X <= p.X + s.X
       and Mouse.Y >= p.Y and Mouse.Y <= p.Y + s.Y
end

function Jqz:UpdateDependencyBoxes()
    for _, db in next, Jqz.DependencyBoxes do db:Update() end
end

function Jqz:MapValue(v, minA, maxA, minB, maxB)
    return (1 - (v - minA)/(maxA - minA)) * minB + ((v - minA)/(maxA - minA)) * maxB
end

function Jqz:GetTextBounds(Text, Font, Size, Res)
    local b = TextService:GetTextSize(Text, Size, Font, Res or Vector2.new(1920, 1080))
    return b.X, b.Y
end

function Jqz:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end

Jqz.AccentColorDark = Jqz:GetDarkerColor(Jqz.AccentColor)

function Jqz:AddToRegistry(Instance, Properties, IsHud)
    local data = { Instance = Instance; Properties = Properties; Idx = #Jqz.Registry + 1 }
    table.insert(Jqz.Registry, data)
    Jqz.RegistryMap[Instance] = data
    if IsHud then table.insert(Jqz.HudRegistry, data) end
end

function Jqz:RemoveFromRegistry(Instance)
    local data = Jqz.RegistryMap[Instance]
    if not data then return end
    for i = #Jqz.Registry, 1, -1 do
        if Jqz.Registry[i] == data then table.remove(Jqz.Registry, i) end
    end
    for i = #Jqz.HudRegistry, 1, -1 do
        if Jqz.HudRegistry[i] == data then table.remove(Jqz.HudRegistry, i) end
    end
    Jqz.RegistryMap[Instance] = nil
end

function Jqz:UpdateColorsUsingRegistry()
    for _, obj in next, Jqz.Registry do
        for prop, idx in next, obj.Properties do
            if type(idx) == 'string' then
                obj.Instance[prop] = Jqz[idx]
            elseif type(idx) == 'function' then
                obj.Instance[prop] = idx()
            end
            if prop == 'BorderColor3' then Jqz:SyncStroke(obj.Instance) end
        end
    end
end

function Jqz:GiveSignal(s)
    table.insert(Jqz.Signals, s)
end

function Jqz:Unload()
    for i = #Jqz.Signals, 1, -1 do
        table.remove(Jqz.Signals, i):Disconnect()
    end
    if Jqz.OnUnload then Jqz.OnUnload() end
    ScreenGui:Destroy()
end

function Jqz:OnUnload(cb)
    Jqz.OnUnload = cb
end

Jqz:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(inst)
    if Jqz.RegistryMap[inst] then Jqz:RemoveFromRegistry(inst) end
end))

local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel
        assert(Info.Default, 'AddColorPicker: missing Default')

        local CP = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color';
            Callback = Info.Callback or function() end;
        }

        function CP:SetHSV(c)
            CP.Hue, CP.Sat, CP.Vib = Color3.toHSV(c)
        end
        CP:SetHSV(CP.Value)

        local Swatch = Jqz:Create('Frame', {
            BackgroundColor3 = CP.Value;
            BorderColor3 = Jqz:GetDarkerColor(CP.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        })
        Jqz:Corner(Swatch, 4)

        local SwatchChecker = Jqz:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = Swatch;
        })
        Jqz:Create('UICorner', { CornerRadius = UDim.new(0, 3); Parent = SwatchChecker })

        local PopupOuter = Jqz:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderSizePixel = 0;
            Position = UDim2.fromOffset(Swatch.AbsolutePosition.X, Swatch.AbsolutePosition.Y + 18);
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui;
        })
        Swatch:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PopupOuter.Position = UDim2.fromOffset(Swatch.AbsolutePosition.X, Swatch.AbsolutePosition.Y + 18)
        end)

        local PopupInner = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.BackgroundColor;
            BorderColor3 = Jqz.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PopupOuter;
        })
        Jqz:Corner(PopupInner, 6)

        local TopBar = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 5, 0, 1);
            Size = UDim2.new(1, -10, 0, 2);
            ZIndex = 17;
            Parent = PopupInner;
        })
        Jqz:Corner(TopBar, 1, true)

        local SatVibOuter = Jqz:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderSizePixel = 0;
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PopupInner;
        })
        local SatVibInner = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.BackgroundColor;
            BorderColor3 = Jqz.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibOuter;
        })
        Jqz:Corner(SatVibInner, 5)
        local SatVibMap = Jqz:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibInner;
        })
        Jqz:Corner(SatVibMap, 5, true)
        local CursorOuter = Jqz:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        })
        Jqz:Create('ImageLabel', {
            Size = UDim2.new(0, 4, 0, 4);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueOuter = Jqz:Create('Frame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PopupInner;
        })
        local HueInner = Jqz:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueOuter;
        })
        Jqz:Corner(HueInner, 5, true)
        local HueCursor = Jqz:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 18;
            Parent = HueInner;
        })
        Jqz:Corner(HueCursor, 1, true)
        local seq = {}
        for h = 0, 1, 0.1 do
            table.insert(seq, ColorSequenceKeypoint.new(h, Color3.fromHSV(h, 1, 1)))
        end
        Jqz:Create('UIGradient', { Color = ColorSequence.new(seq); Rotation = 90; Parent = HueInner })

        local function MakeBox(Pos, Size, Text, Placeholder)
            local O = Jqz:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderSizePixel = 0;
                Position = Pos;
                Size = Size;
                ZIndex = 18;
                Parent = PopupInner;
            })
            local I = Jqz:Create('Frame', {
                BackgroundColor3 = Jqz.MainColor;
                BorderColor3 = Jqz.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 18;
                Parent = O;
            })
            Jqz:Corner(I, 4)
            local T = Jqz:Create('TextBox', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 6, 0, 0);
                Size = UDim2.new(1, -6, 1, 0);
                Font = Jqz.Font;
                PlaceholderColor3 = Color3.fromRGB(165, 140, 205);
                PlaceholderText = Placeholder;
                Text = Text;
                TextColor3 = Jqz.FontColor;
                TextSize = 13;
                TextStrokeTransparency = 0;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 20;
                Parent = I;
            })
            Jqz:ApplyTextStroke(T)
            Jqz:AddToRegistry(I, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })
            Jqz:AddToRegistry(T, { TextColor3 = 'FontColor' })
            return T
        end

        local HexBox = MakeBox(UDim2.fromOffset(4, 228), UDim2.new(0.5, -6, 0, 20), '#FFFFFF', 'Hex')
        local RgbBox = MakeBox(UDim2.new(0.5, 2, 0, 228), UDim2.new(0.5, -6, 0, 20), '255, 255, 255', 'R, G, B')

        local TAlphaOuter, TAlphaInner, TAlphaCursor
        if Info.Transparency then
            TAlphaOuter = Jqz:Create('Frame', {
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PopupInner;
            })
            TAlphaInner = Jqz:Create('Frame', {
                BackgroundColor3 = CP.Value;
                BorderColor3 = Jqz.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TAlphaOuter;
            })
            Jqz:Corner(TAlphaInner, 4)
            Jqz:AddToRegistry(TAlphaInner, { BorderColor3 = 'OutlineColor' })
            local TAlphaImage = Jqz:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TAlphaInner;
            })
            Jqz:Create('UICorner', { CornerRadius = UDim.new(0, 4); Parent = TAlphaImage })
            TAlphaCursor = Jqz:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 2, 1, 0);
                ZIndex = 21;
                Parent = TAlphaInner;
            })
            Jqz:Corner(TAlphaCursor, 1, true)
        end

        Jqz:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(6, 6);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 13;
            Text = CP.Title;
            ZIndex = 16;
            Parent = PopupInner;
        })

        local Ctx = {}
        do
            Ctx.Container = Jqz:Create('Frame', { BackgroundColor3 = Color3.new(0, 0, 0); BorderSizePixel = 0; ZIndex = 14; Visible = false; Parent = ScreenGui })
            Ctx.Inner = Jqz:Create('Frame', {
                BackgroundColor3 = Jqz.BackgroundColor; BorderColor3 = Jqz.OutlineColor;
                BorderMode = Enum.BorderMode.Inset; Size = UDim2.fromScale(1, 1); ZIndex = 15; Parent = Ctx.Container;
            })
            Jqz:Corner(Ctx.Inner, 5)
            Jqz:Create('UIListLayout', { Name = 'Layout'; FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Parent = Ctx.Inner })
            Jqz:Create('UIPadding', { Name = 'Padding'; PaddingLeft = UDim.new(0, 5); PaddingTop = UDim.new(0, 2); Parent = Ctx.Inner })

            local function CtxPos()
                Ctx.Container.Position = UDim2.fromOffset(
                    Swatch.AbsolutePosition.X + Swatch.AbsoluteSize.X + 4,
                    Swatch.AbsolutePosition.Y + 1
                )
            end
            local function CtxSize()
                local w = 60
                for _, l in next, Ctx.Inner:GetChildren() do
                    if l:IsA('TextLabel') then w = math.max(w, l.TextBounds.X) end
                end
                Ctx.Container.Size = UDim2.fromOffset(w + 10, Ctx.Inner.Layout.AbsoluteContentSize.Y + 6)
            end
            Swatch:GetPropertyChangedSignal('AbsolutePosition'):Connect(CtxPos)
            Ctx.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(CtxSize)
            task.spawn(CtxPos); task.spawn(CtxSize)
            Jqz:AddToRegistry(Ctx.Inner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })

            function Ctx:Show() self.Container.Visible = true end
            function Ctx:Hide() self.Container.Visible = false end
            function Ctx:AddOption(Label, Fn)
                if type(Fn) ~= 'function' then Fn = function() end end
                local Btn = Jqz:CreateLabel({
                    Active = false; Size = UDim2.new(1, 0, 0, 16); TextSize = 12;
                    Text = Label; ZIndex = 16; Parent = self.Inner; TextXAlignment = Enum.TextXAlignment.Left;
                })
                Jqz:OnHighlight(Btn, Btn, { TextColor3 = 'AccentColor' }, { TextColor3 = 'FontColor' })
                Btn.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then Fn() end
                end)
            end
            Ctx:AddOption('Copy color',  function() Jqz.ColorClipboard = CP.Value; Jqz:Notify('Copied!', 2) end)
            Ctx:AddOption('Paste color', function()
                if not Jqz.ColorClipboard then return Jqz:Notify('Nothing copied!', 2) end
                CP:SetValueRGB(Jqz.ColorClipboard)
            end)
            Ctx:AddOption('Copy HEX', function() pcall(setclipboard, CP.Value:ToHex()); Jqz:Notify('HEX copied!', 2) end)
            Ctx:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(CP.Value.R*255), math.floor(CP.Value.G*255), math.floor(CP.Value.B*255) }, ', '))
                Jqz:Notify('RGB copied!', 2)
            end)
        end

        Jqz:AddToRegistry(PopupInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })
        Jqz:AddToRegistry(TopBar,     { BackgroundColor3 = 'AccentColor' })
        Jqz:AddToRegistry(SatVibInner,{ BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })

        HexBox.FocusLost:Connect(function(enter)
            if enter then
                local ok, c = pcall(Color3.fromHex, HexBox.Text)
                if ok then CP.Hue, CP.Sat, CP.Vib = Color3.toHSV(c) end
            end
            CP:Display()
        end)
        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r then CP.Hue, CP.Sat, CP.Vib = Color3.toHSV(Color3.fromRGB(r, g, b)) end
            end
            CP:Display()
        end)

        function CP:Display()
            CP.Value = Color3.fromHSV(CP.Hue, CP.Sat, CP.Vib)
            SatVibMap.BackgroundColor3 = Color3.fromHSV(CP.Hue, 1, 1)
            Jqz:Create(Swatch, {
                BackgroundColor3 = CP.Value;
                BackgroundTransparency = CP.Transparency;
                BorderColor3 = Jqz:GetDarkerColor(CP.Value);
            })
            Jqz:SyncStroke(Swatch)
            if TAlphaInner then
                TAlphaInner.BackgroundColor3 = CP.Value
                TAlphaCursor.Position = UDim2.new(1 - CP.Transparency, 0, 0, 0)
            end
            CursorOuter.Position = UDim2.new(CP.Sat, 0, 1 - CP.Vib, 0)
            HueCursor.Position = UDim2.new(0, 0, CP.Hue, 0)
            HexBox.Text = '#' .. CP.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(CP.Value.R*255), math.floor(CP.Value.G*255), math.floor(CP.Value.B*255) }, ', ')
            Jqz:SafeCallback(CP.Callback, CP.Value)
            Jqz:SafeCallback(CP.Changed,  CP.Value)
        end

        function CP:OnChanged(fn) CP.Changed = fn; fn(CP.Value) end
        function CP:Show()
            for f in next, Jqz.OpenedFrames do
                if f.Name == 'Color' then f.Visible = false; Jqz.OpenedFrames[f] = nil end
            end
            PopupOuter.Visible = true; Jqz.OpenedFrames[PopupOuter] = true
        end
        function CP:Hide() PopupOuter.Visible = false; Jqz.OpenedFrames[PopupOuter] = nil end
        function CP:SetValue(hsv, alpha)
            CP.Transparency = alpha or 0
            CP:SetHSV(Color3.fromHSV(hsv[1], hsv[2], hsv[3]))
            CP:Display()
        end
        function CP:SetValueRGB(c, alpha)
            CP.Transparency = alpha or 0
            CP:SetHSV(c)
            CP:Display()
        end

        SatVibMap.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local mnX, mxX = SatVibMap.AbsolutePosition.X, SatVibMap.AbsolutePosition.X + SatVibMap.AbsoluteSize.X
                local mnY, mxY = SatVibMap.AbsolutePosition.Y, SatVibMap.AbsolutePosition.Y + SatVibMap.AbsoluteSize.Y
                CP.Sat = (math.clamp(Mouse.X, mnX, mxX) - mnX) / (mxX - mnX)
                CP.Vib = 1 - ((math.clamp(Mouse.Y, mnY, mxY) - mnY) / (mxY - mnY))
                CP:Display(); RunService.RenderStepped:Wait()
            end
            Jqz:AttemptSave()
        end)
        HueInner.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local mnY, mxY = HueInner.AbsolutePosition.Y, HueInner.AbsolutePosition.Y + HueInner.AbsoluteSize.Y
                CP.Hue = (math.clamp(Mouse.Y, mnY, mxY) - mnY) / (mxY - mnY)
                CP:Display(); RunService.RenderStepped:Wait()
            end
            Jqz:AttemptSave()
        end)
        if TAlphaInner then
            TAlphaInner.InputBegan:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local mnX, mxX = TAlphaInner.AbsolutePosition.X, TAlphaInner.AbsolutePosition.X + TAlphaInner.AbsoluteSize.X
                    CP.Transparency = 1 - ((math.clamp(Mouse.X, mnX, mxX) - mnX) / (mxX - mnX))
                    CP:Display(); RunService.RenderStepped:Wait()
                end
                Jqz:AttemptSave()
            end)
        end
        Swatch.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 and not Jqz:MouseIsOverOpenedFrame() then
                if PopupOuter.Visible then CP:Hide() else Ctx:Hide(); CP:Show() end
            elseif i.UserInputType == Enum.UserInputType.MouseButton2 and not Jqz:MouseIsOverOpenedFrame() then
                Ctx:Show(); CP:Hide()
            end
        end)
        Jqz:GiveSignal(InputService.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                local p, s = PopupOuter.AbsolutePosition, PopupOuter.AbsoluteSize
                if Mouse.X < p.X or Mouse.X > p.X+s.X or Mouse.Y < p.Y-21 or Mouse.Y > p.Y+s.Y then CP:Hide() end
                if not Jqz:IsMouseOverFrame(Ctx.Container) then Ctx:Hide() end
            end
            if i.UserInputType == Enum.UserInputType.MouseButton2 and Ctx.Container.Visible then
                if not Jqz:IsMouseOverFrame(Ctx.Container) and not Jqz:IsMouseOverFrame(Swatch) then Ctx:Hide() end
            end
        end))

        CP:Display()
        CP.DisplayFrame = Swatch
        Options[Idx] = CP
        return self
    end

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self
        local ToggleLabel = self.TextLabel
        assert(Info.Default, 'AddKeyPicker: missing Default')

        local KP = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';
            Callback = Info.Callback or function() end;
            ChangedCallback = Info.ChangedCallback or function() end;
            SyncToggleState = Info.SyncToggleState or false;
        }
        if KP.SyncToggleState then Info.Modes = { 'Toggle' }; Info.Mode = 'Toggle' end

        local PickOuter = Jqz:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0); BorderSizePixel = 0;
            Size = UDim2.new(0, 28, 0, 15); ZIndex = 6; Parent = ToggleLabel;
        })
        local PickInner = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.MainColor; BorderColor3 = Jqz.OutlineColor;
            BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 1, 0); ZIndex = 7; Parent = PickOuter;
        })
        Jqz:Corner(PickInner, 4)
        Jqz:AddToRegistry(PickInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })
        local DisplayLabel = Jqz:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0); TextSize = 12; Text = Info.Default;
            TextWrapped = true; ZIndex = 8; Parent = PickInner;
        })

        local ModeOuter = Jqz:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0); BorderSizePixel = 0;
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 64, 0, 50);
            Visible = false; ZIndex = 14; Parent = ScreenGui;
        })
        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1)
        end)
        local ModeInner = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.BackgroundColor; BorderColor3 = Jqz.OutlineColor;
            BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 1, 0); ZIndex = 15; Parent = ModeOuter;
        })
        Jqz:Corner(ModeInner, 5)
        Jqz:AddToRegistry(ModeInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })
        Jqz:Create('UIListLayout', { FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Parent = ModeInner })
        Jqz:Create('UIPadding', { PaddingTop = UDim.new(0, 2); Parent = ModeInner })

        local ContainerLabel = Jqz:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left; Size = UDim2.new(1, 0, 0, 18);
            TextSize = 12; Visible = false; ZIndex = 110; Parent = Jqz.KeybindContainer;
        }, true)

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' }
        local ModeButtons = {}
        for _, Mode in next, Modes do
            local MB = {}
            local Lbl = Jqz:CreateLabel({
                Active = false; Size = UDim2.new(1, 0, 0, 15); TextSize = 12;
                Text = Mode; ZIndex = 16; Parent = ModeInner;
            })
            function MB:Select()
                for _, b in next, ModeButtons do b:Deselect() end
                KP.Mode = Mode
                Lbl.TextColor3 = Jqz.AccentColor
                Jqz.RegistryMap[Lbl].Properties.TextColor3 = 'AccentColor'
                ModeOuter.Visible = false
            end
            function MB:Deselect()
                KP.Mode = nil
                Lbl.TextColor3 = Jqz.FontColor
                Jqz.RegistryMap[Lbl].Properties.TextColor3 = 'FontColor'
            end
            Lbl.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then MB:Select(); Jqz:AttemptSave() end
            end)
            if Mode == KP.Mode then MB:Select() end
            ModeButtons[Mode] = MB
        end

        function KP:Update()
            if Info.NoUI then return end
            local State = KP:GetState()
            ContainerLabel.Text = string.format('[%s] %s (%s)', KP.Value, Info.Text, KP.Mode)
            ContainerLabel.Visible = true
            ContainerLabel.TextColor3 = State and Jqz.AccentColor or Jqz.FontColor
            Jqz.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor'
            local Y, X = 0, 0
            for _, l in next, Jqz.KeybindContainer:GetChildren() do
                if l:IsA('TextLabel') and l.Visible then
                    Y += 18
                    if l.TextBounds.X > X then X = l.TextBounds.X end
                end
            end
            Jqz.KeybindFrame.Size = UDim2.new(0, math.max(X + 10, 210), 0, Y + 23)
        end
        function KP:GetState()
            if KP.Mode == 'Always' then return true
            elseif KP.Mode == 'Hold' then
                if KP.Value == 'None' then return false end
                if KP.Value == 'MB1' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
                if KP.Value == 'MB2' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
                return InputService:IsKeyDown(Enum.KeyCode[KP.Value])
            else return KP.Toggled end
        end
        function KP:SetValue(data)
            DisplayLabel.Text = data[1]; KP.Value = data[1]
            ModeButtons[data[2]]:Select(); KP:Update()
        end
        function KP:OnClick(fn)    KP.Clicked  = fn end
        function KP:OnChanged(fn)  KP.Changed  = fn; fn(KP.Value) end
        if ParentObj.Addons then table.insert(ParentObj.Addons, KP) end
        function KP:DoClick()
            if ParentObj.Type == 'Toggle' and KP.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end
            Jqz:SafeCallback(KP.Callback, KP.Toggled)
            Jqz:SafeCallback(KP.Clicked,  KP.Toggled)
        end

        local Picking = false
        PickOuter.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 and not Jqz:MouseIsOverOpenedFrame() then
                Picking = true; DisplayLabel.Text = ''
                local Break, Dots = false, ''
                task.spawn(function()
                    while not Break do
                        Dots = Dots == '...' and '' or Dots .. '.'
                        DisplayLabel.Text = Dots; wait(0.4)
                    end
                end)
                wait(0.2)
                local ev
                ev = InputService.InputBegan:Connect(function(i2)
                    local Key
                    if i2.UserInputType == Enum.UserInputType.Keyboard then Key = i2.KeyCode.Name
                    elseif i2.UserInputType == Enum.UserInputType.MouseButton1 then Key = 'MB1'
                    elseif i2.UserInputType == Enum.UserInputType.MouseButton2 then Key = 'MB2' end
                    Break = true; Picking = false
                    DisplayLabel.Text = Key; KP.Value = Key
                    Jqz:SafeCallback(KP.ChangedCallback, i2.KeyCode or i2.UserInputType)
                    Jqz:SafeCallback(KP.Changed,         i2.KeyCode or i2.UserInputType)
                    Jqz:AttemptSave(); ev:Disconnect()
                end)
            elseif i.UserInputType == Enum.UserInputType.MouseButton2 and not Jqz:MouseIsOverOpenedFrame() then
                ModeOuter.Visible = true
            end
        end)
        Jqz:GiveSignal(InputService.InputBegan:Connect(function(i)
            if not Picking then
                if KP.Mode == 'Toggle' then
                    local Key = KP.Value
                    if (Key == 'MB1' and i.UserInputType == Enum.UserInputType.MouseButton1)
                    or (Key == 'MB2' and i.UserInputType == Enum.UserInputType.MouseButton2) then
                        KP.Toggled = not KP.Toggled; KP:DoClick()
                    elseif i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == Key then
                        KP.Toggled = not KP.Toggled; KP:DoClick()
                    end
                end
                KP:Update()
            end
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                local p, s = ModeOuter.AbsolutePosition, ModeOuter.AbsoluteSize
                if Mouse.X < p.X or Mouse.X > p.X+s.X or Mouse.Y < p.Y-21 or Mouse.Y > p.Y+s.Y then
                    ModeOuter.Visible = false
                end
            end
        end))
        Jqz:GiveSignal(InputService.InputEnded:Connect(function() if not Picking then KP:Update() end end))

        KP:Update()
        Options[Idx] = KP
        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...) return Funcs[Key](...) end
end

local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddBlank(sz)
        Jqz:Create('Frame', { BackgroundTransparency = 1; Size = UDim2.new(1, 0, 0, sz); ZIndex = 1; Parent = self.Container })
    end

    function Funcs:AddLabel(Text, Wrap)
        local GB = self
        local Lbl = Jqz:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15); TextSize = 13; Text = Text;
            TextWrapped = Wrap or false; TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5; Parent = GB.Container;
        })
        if Wrap then
            local Y = select(2, Jqz:GetTextBounds(Text, Jqz.Font, 13, Vector2.new(Lbl.AbsoluteSize.X, math.huge)))
            Lbl.Size = UDim2.new(1, -4, 0, Y)
        else
            Jqz:Create('UIListLayout', {
                Padding = UDim.new(0, 4); FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right; SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Lbl;
            })
        end
        local Label = { TextLabel = Lbl; Container = GB.Container }
        function Label:SetText(t)
            Lbl.Text = t
            if Wrap then
                local Y = select(2, Jqz:GetTextBounds(t, Jqz.Font, 13, Vector2.new(Lbl.AbsoluteSize.X, math.huge)))
                Lbl.Size = UDim2.new(1, -4, 0, Y)
            end
            GB:Resize()
        end
        if not Wrap then setmetatable(Label, BaseAddons) end
        GB:AddBlank(5); GB:Resize()
        return Label
    end

    function Funcs:AddButton(...)
        local Btn = {}
        local GB = self
        local function ParseArgs(_, obj, ...)
            local p = select(1, ...)
            if type(p) == 'table' then
                obj.Text = p.Text; obj.Func = p.Func
                obj.DoubleClick = p.DoubleClick; obj.Tooltip = p.Tooltip
            else
                obj.Text = select(1, ...); obj.Func = select(2, ...)
            end
            assert(type(obj.Func) == 'function', 'AddButton: Func missing')
        end
        ParseArgs('', Btn, ...)

        local function MakeBtn(obj)
            local Outer = Jqz:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0); BorderColor3 = Jqz.OutlineColor;
                Size = UDim2.new(1, -4, 0, 21); ZIndex = 5;
            })
            local Inner = Jqz:Create('Frame', {
                BackgroundColor3 = Jqz.MainColor; BorderColor3 = Jqz.OutlineColor;
                BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 1, 0); ZIndex = 6; Parent = Outer;
            })
            Jqz:Corner(Inner, 5)
            local Lbl = Jqz:CreateLabel({ Size = UDim2.new(1, 0, 1, 0); TextSize = 13; Text = obj.Text; ZIndex = 6; Parent = Inner })
            Jqz:AddToRegistry(Outer, { BorderColor3 = 'OutlineColor' })
            Jqz:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })
            Jqz:OnHighlight(Outer, Outer, { BorderColor3 = 'AccentColor' }, { BorderColor3 = 'OutlineColor' })
            return Outer, Inner, Lbl
        end

        local function Wire(obj)
            local function ok(i)
                return not Jqz:MouseIsOverOpenedFrame() and i.UserInputType == Enum.UserInputType.MouseButton1
            end
            obj.Outer.InputBegan:Connect(function(i)
                if not ok(i) or obj.Locked then return end
                if obj.DoubleClick then
                    Jqz:RemoveFromRegistry(obj.Label)
                    Jqz:AddToRegistry(obj.Label, { TextColor3 = 'AccentColor' })
                    obj.Label.TextColor3 = Jqz.AccentColor
                    obj.Label.Text = 'Confirm?'
                    obj.Locked = true
                    local be = Instance.new('BindableEvent')
                    local con = obj.Outer.InputBegan:Once(function(i2)
                        be:Fire(ok(i2))
                    end)
                    task.delay(0.5, function() con:Disconnect(); be:Fire(false) end)
                    local clicked = be.Event:Wait()
                    Jqz:RemoveFromRegistry(obj.Label)
                    Jqz:AddToRegistry(obj.Label, { TextColor3 = 'FontColor' })
                    obj.Label.TextColor3 = Jqz.FontColor
                    obj.Label.Text = obj.Text
                    task.defer(rawset, obj, 'Locked', false)
                    if clicked then Jqz:SafeCallback(obj.Func) end
                    return
                end
                Jqz:SafeCallback(obj.Func)
            end)
        end

        Btn.Outer, Btn.Inner, Btn.Label = MakeBtn(Btn)
        Btn.Outer.Parent = GB.Container
        Wire(Btn)

        function Btn:AddTooltip(t) if type(t) == 'string' then Jqz:AddToolTip(t, self.Outer) end; return self end
        function Btn:AddButton(...)
            local Sub = {}
            ParseArgs('', Sub, ...)
            self.Outer.Size = UDim2.new(0.5, -3, 0, 21)
            Sub.Outer, Sub.Inner, Sub.Label = MakeBtn(Sub)
            Sub.Outer.Position = UDim2.new(1, 5, 0, 0)
            Sub.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X, self.Outer.AbsoluteSize.Y)
            Sub.Outer.Parent = self.Outer
            function Sub:AddTooltip(t) if type(t) == 'string' then Jqz:AddToolTip(t, self.Outer) end; return self end
            if type(Sub.Tooltip) == 'string' then Sub:AddTooltip(Sub.Tooltip) end
            Wire(Sub); return Sub
        end
        if type(Btn.Tooltip) == 'string' then Btn:AddTooltip(Btn.Tooltip) end
        GB:AddBlank(5); GB:Resize()
        return Btn
    end

    function Funcs:AddDivider()
        self:AddBlank(2)
        local O = Jqz:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0); BorderColor3 = Jqz.OutlineColor;
            Size = UDim2.new(1, -4, 0, 4); ZIndex = 5; Parent = self.Container;
        })
        local I = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.MainColor; BorderColor3 = Jqz.OutlineColor;
            BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 1, 0); ZIndex = 6; Parent = O;
        })
        Jqz:Corner(I, 2)
        Jqz:AddToRegistry(O, { BorderColor3 = 'OutlineColor' })
        Jqz:AddToRegistry(I, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })
        self:AddBlank(9); self:Resize()
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: missing Text')
        local GB = self
        local TB = { Value = Info.Default or ''; Numeric = Info.Numeric; Finished = Info.Finished; Type = 'Input'; Callback = Info.Callback or function() end }
        Jqz:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15); TextSize = 13; Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 5; Parent = GB.Container;
        })
        GB:AddBlank(1)
        local Outer = Jqz:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0); BorderColor3 = Jqz.OutlineColor;
            Size = UDim2.new(1, -4, 0, 21); ZIndex = 5; Parent = GB.Container;
        })
        local Inner = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.MainColor; BorderColor3 = Jqz.OutlineColor;
            BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 1, 0); ZIndex = 6; Parent = Outer;
        })
        Jqz:Corner(Inner, 5)
        Jqz:AddToRegistry(Outer, { BorderColor3 = 'OutlineColor' })
        Jqz:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })
        Jqz:OnHighlight(Outer, Outer, { BorderColor3 = 'AccentColor' }, { BorderColor3 = 'OutlineColor' })
        if type(Info.Tooltip) == 'string' then Jqz:AddToolTip(Info.Tooltip, Outer) end
        local Clip = Jqz:Create('Frame', {
            BackgroundTransparency = 1; ClipsDescendants = true;
            Position = UDim2.new(0, 6, 0, 0); Size = UDim2.new(1, -8, 1, 0); ZIndex = 7; Parent = Inner;
        })
        local Box = Jqz:Create('TextBox', {
            BackgroundTransparency = 1; Position = UDim2.fromOffset(0, 0); Size = UDim2.fromScale(5, 1);
            Font = Jqz.Font; PlaceholderColor3 = Color3.fromRGB(165, 140, 205);
            PlaceholderText = Info.Placeholder or ''; Text = Info.Default or '';
            TextColor3 = Jqz.FontColor; TextSize = 13; TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 7; Parent = Clip;
        })
        Jqz:ApplyTextStroke(Box)

        function TB:SetValue(t)
            if Info.MaxLength and #t > Info.MaxLength then t = t:sub(1, Info.MaxLength) end
            if TB.Numeric and not tonumber(t) and #t > 0 then t = TB.Value end
            TB.Value = t; Box.Text = t
            Jqz:SafeCallback(TB.Callback, TB.Value)
            Jqz:SafeCallback(TB.Changed,  TB.Value)
        end
        if TB.Finished then
            Box.FocusLost:Connect(function(enter) if enter then TB:SetValue(Box.Text); Jqz:AttemptSave() end end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function() TB:SetValue(Box.Text); Jqz:AttemptSave() end)
        end

        local function UpdateScroll()
            local PAD = 2; local rev = Clip.AbsoluteSize.X
            if not Box:IsFocused() or Box.TextBounds.X <= rev - 2*PAD then
                Box.Position = UDim2.new(0, PAD, 0, 0)
            else
                local cur = Box.CursorPosition
                if cur ~= -1 then
                    local w = TextService:GetTextSize(Box.Text:sub(1, cur-1), Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X
                    local cp = Box.Position.X.Offset + w
                    if cp < PAD then Box.Position = UDim2.fromOffset(PAD-w, 0)
                    elseif cp > rev-PAD-1 then Box.Position = UDim2.fromOffset(rev-w-PAD-1, 0) end
                end
            end
        end
        task.spawn(UpdateScroll)
        Box:GetPropertyChangedSignal('Text'):Connect(UpdateScroll)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(UpdateScroll)
        Box.FocusLost:Connect(UpdateScroll); Box.Focused:Connect(UpdateScroll)
        Jqz:AddToRegistry(Box, { TextColor3 = 'FontColor' })

        function TB:OnChanged(fn) TB.Changed = fn; fn(TB.Value) end
        GB:AddBlank(5); GB:Resize()
        Options[Idx] = TB
        return TB
    end

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddToggle: missing Text')
        local GB = self
        local Tog = {
            Value = Info.Default or false; Type = 'Toggle';
            Callback = Info.Callback or function() end;
            Addons = {}; Risky = Info.Risky;
        }

        local TOuter = Jqz:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0); BorderColor3 = Jqz.OutlineColor;
            Size = UDim2.new(0, 14, 0, 14); ZIndex = 5; Parent = GB.Container;
        })
        Jqz:AddToRegistry(TOuter, { BorderColor3 = 'OutlineColor' })
        local TInner = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.MainColor; BorderColor3 = Jqz.OutlineColor;
            BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 1, 0); ZIndex = 6; Parent = TOuter;
        })
        Jqz:Corner(TInner, 4)
        Jqz:AddToRegistry(TInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })

        local TLabel = Jqz:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0); Position = UDim2.new(1, 7, 0, 0);
            TextSize = 13; Text = Info.Text; TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6; Parent = TInner;
        })
        Jqz:Create('UIListLayout', {
            Padding = UDim.new(0, 4); FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right; SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = TLabel;
        })

        local TRegion = Jqz:Create('Frame', {
            BackgroundTransparency = 1; Size = UDim2.new(0, 170, 1, 0); ZIndex = 8; Parent = TOuter;
        })
        Jqz:OnHighlight(TRegion, TOuter, { BorderColor3 = 'AccentColor' }, { BorderColor3 = 'OutlineColor' })
        if type(Info.Tooltip) == 'string' then Jqz:AddToolTip(Info.Tooltip, TRegion) end

        function Tog:UpdateColors() Tog:Display() end
        function Tog:Display()
            TInner.BackgroundColor3 = Tog.Value and Jqz.AccentColor or Jqz.MainColor
            Jqz.RegistryMap[TInner].Properties.BackgroundColor3 = Tog.Value and 'AccentColor' or 'MainColor'
        end
        function Tog:OnChanged(fn) Tog.Changed = fn; fn(Tog.Value) end
        function Tog:SetValue(b)
            b = not not b; Tog.Value = b; Tog:Display()
            for _, a in next, Tog.Addons do
                if a.Type == 'KeyPicker' and a.SyncToggleState then a.Toggled = b; a:Update() end
            end
            Jqz:SafeCallback(Tog.Callback, Tog.Value)
            Jqz:SafeCallback(Tog.Changed,  Tog.Value)
            Jqz:UpdateDependencyBoxes()
        end
        TRegion.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 and not Jqz:MouseIsOverOpenedFrame() then
                Tog:SetValue(not Tog.Value); Jqz:AttemptSave()
            end
        end)
        if Tog.Risky then
            Jqz:RemoveFromRegistry(TLabel)
            TLabel.TextColor3 = Jqz.RiskColor
            Jqz:AddToRegistry(TLabel, { TextColor3 = 'RiskColor' })
        end

        Tog:Display()
        GB:AddBlank(Info.BlankSize or 7)
        GB:Resize()
        Tog.TextLabel = TLabel; Tog.Container = GB.Container
        setmetatable(Tog, BaseAddons)
        Toggles[Idx] = Tog
        Jqz:UpdateDependencyBoxes()
        return Tog
    end

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default,  'AddSlider: missing Default')
        assert(Info.Text,     'AddSlider: missing Text')
        assert(Info.Min,      'AddSlider: missing Min')
        assert(Info.Max,      'AddSlider: missing Max')
        assert(Info.Rounding, 'AddSlider: missing Rounding')
        local GB = self
        local Sl = {
            Value = Info.Default; Min = Info.Min; Max = Info.Max;
            Rounding = Info.Rounding; MaxSize = 232; Type = 'Slider';
            Callback = Info.Callback or function() end;
        }

        if not Info.Compact then
            Jqz:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10); TextSize = 13; Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left; TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5; Parent = GB.Container;
            })
            GB:AddBlank(3)
        end

        local SOuter = Jqz:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0); BorderColor3 = Jqz.OutlineColor;
            Size = UDim2.new(1, -4, 0, 14); ZIndex = 5; Parent = GB.Container;
        })
        Jqz:AddToRegistry(SOuter, { BorderColor3 = 'OutlineColor' })
        local SInner = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.MainColor; BorderColor3 = Jqz.OutlineColor;
            BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 1, 0); ZIndex = 6; Parent = SOuter;
        })
        Jqz:Corner(SInner, 5)
        Jqz:AddToRegistry(SInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })

        local Fill = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.AccentColor; BorderColor3 = Jqz.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0); ZIndex = 7; Parent = SInner;
        })
        Jqz:Corner(Fill, 5, true)
        Jqz:AddToRegistry(Fill, { BackgroundColor3 = 'AccentColor' })

        local SLabel = Jqz:CreateLabel({ Size = UDim2.new(1, 0, 1, 0); TextSize = 13; Text = '0'; ZIndex = 9; Parent = SInner })
        Jqz:OnHighlight(SOuter, SOuter, { BorderColor3 = 'AccentColor' }, { BorderColor3 = 'OutlineColor' })
        if type(Info.Tooltip) == 'string' then Jqz:AddToolTip(Info.Tooltip, SOuter) end

        function Sl:UpdateColors()
            Fill.BackgroundColor3 = Jqz.AccentColor
        end
        function Sl:Display()
            local sfx = Info.Suffix or ''
            if Info.Compact then SLabel.Text = Info.Text .. ': ' .. Sl.Value .. sfx
            elseif Info.HideMax then SLabel.Text = Sl.Value .. sfx
            else SLabel.Text = Sl.Value .. sfx .. '/' .. Sl.Max .. sfx end
            local X = math.ceil(Jqz:MapValue(Sl.Value, Sl.Min, Sl.Max, 0, Sl.MaxSize))
            Fill.Size = UDim2.new(0, X, 1, 0)
            Fill.Visible = X > 0
        end
        function Sl:OnChanged(fn) Sl.Changed = fn; fn(Sl.Value) end
        local function Round(v)
            if Sl.Rounding == 0 then return math.floor(v) end
            return tonumber(string.format('%.' .. Sl.Rounding .. 'f', v))
        end
        function Sl:GetValueFromX(x) return Round(Jqz:MapValue(x, 0, Sl.MaxSize, Sl.Min, Sl.Max)) end
        function Sl:SetValue(v)
            local n = tonumber(v); if not n then return end
            n = math.clamp(n, Sl.Min, Sl.Max); Sl.Value = n; Sl:Display()
            Jqz:SafeCallback(Sl.Callback, Sl.Value)
            Jqz:SafeCallback(Sl.Changed,  Sl.Value)
        end

        SInner.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 or Jqz:MouseIsOverOpenedFrame() then return end
            local mX = Mouse.X; local gX = Fill.Size.X.Offset
            local df = mX - (Fill.AbsolutePosition.X + gX)
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local nX = math.clamp(gX + (Mouse.X - mX) + df, 0, Sl.MaxSize)
                local nVal = Sl:GetValueFromX(nX)
                local old = Sl.Value; Sl.Value = nVal; Sl:Display()
                if nVal ~= old then
                    Jqz:SafeCallback(Sl.Callback, Sl.Value)
                    Jqz:SafeCallback(Sl.Changed,  Sl.Value)
                end
                RunService.RenderStepped:Wait()
            end
            Jqz:AttemptSave()
        end)

        Sl:Display()
        GB:AddBlank(Info.BlankSize or 6); GB:Resize()
        Options[Idx] = Sl
        return Sl
    end

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then Info.Values = GetPlayersString(); Info.AllowNull = true
        elseif Info.SpecialType == 'Team' then Info.Values = GetTeamsString(); Info.AllowNull = true end
        assert(Info.Values, 'AddDropdown: missing Values')
        assert(Info.AllowNull or Info.Default, 'AddDropdown: missing Default')
        if not Info.Text then Info.Compact = true end

        local GB = self
        local DD = {
            Values = Info.Values; Value = Info.Multi and {}; Multi = Info.Multi; Type = 'Dropdown'; SpecialType = Info.SpecialType;
            Callback = Info.Callback or function() end;
        }

        if not Info.Compact then
            Jqz:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10); TextSize = 13; Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left; TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5; Parent = GB.Container;
            })
            GB:AddBlank(3)
        end

        local DOuter = Jqz:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0); BorderColor3 = Jqz.OutlineColor;
            Size = UDim2.new(1, -4, 0, 21); ZIndex = 5; Parent = GB.Container;
        })
        Jqz:AddToRegistry(DOuter, { BorderColor3 = 'OutlineColor' })
        local DInner = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.MainColor; BorderColor3 = Jqz.OutlineColor;
            BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 1, 0); ZIndex = 6; Parent = DOuter;
        })
        Jqz:Corner(DInner, 5)
        Jqz:AddToRegistry(DInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })
        local Arrow = Jqz:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5); BackgroundTransparency = 1;
            Position = UDim2.new(1, -17, 0.5, 0); Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798'; ZIndex = 8; Parent = DInner;
        })
        local ItemLbl = Jqz:CreateLabel({
            Position = UDim2.new(0, 6, 0, 0); Size = UDim2.new(1, -24, 1, 0);
            TextSize = 13; Text = '--'; TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true; ZIndex = 7; Parent = DInner;
        })
        Jqz:OnHighlight(DOuter, DOuter, { BorderColor3 = 'AccentColor' }, { BorderColor3 = 'OutlineColor' })
        if type(Info.Tooltip) == 'string' then Jqz:AddToolTip(Info.Tooltip, DOuter) end

        local MAX = 8
        local ListOuter = Jqz:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0); BorderSizePixel = 0;
            ZIndex = 20; Visible = false; Parent = ScreenGui;
        })
        local function RPos() ListOuter.Position = UDim2.fromOffset(DOuter.AbsolutePosition.X, DOuter.AbsolutePosition.Y + DOuter.Size.Y.Offset + 3) end
        local function RSze(Y) ListOuter.Size = UDim2.fromOffset(DOuter.AbsoluteSize.X, Y or (MAX*20+2)) end
        RPos(); RSze()
        DOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RPos)

        local ListInner = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.MainColor; BorderColor3 = Jqz.OutlineColor;
            BorderMode = Enum.BorderMode.Inset; ClipsDescendants = true;
            Size = UDim2.new(1, 0, 1, 0); ZIndex = 21; Parent = ListOuter;
        })
        Jqz:Corner(ListInner, 5)
        Jqz:AddToRegistry(ListInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })

        local Scroll = Jqz:Create('ScrollingFrame', {
            BackgroundTransparency = 1; BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0); Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21; Parent = ListInner;
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            ScrollBarThickness = 3; ScrollBarImageColor3 = Jqz.AccentColor;
        })
        Jqz:AddToRegistry(Scroll, { ScrollBarImageColor3 = 'AccentColor' })
        Jqz:Create('UIListLayout', { Padding = UDim.new(0, 0); FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Parent = Scroll })

        function DD:Display()
            local s = ''
            if Info.Multi then
                for _, v in next, DD.Values do if DD.Value[v] then s ..= v .. ', ' end end
                s = s:sub(1, #s-2)
            else s = DD.Value or '' end
            ItemLbl.Text = s == '' and '--' or s
        end
        function DD:GetActiveValues()
            if Info.Multi then local t = {} for v in next, DD.Value do table.insert(t, v) end return t
            else return DD.Value and 1 or 0 end
        end
        function DD:BuildList()
            for _, el in next, Scroll:GetChildren() do
                if not el:IsA('UIListLayout') then el:Destroy() end
            end
            local Btns, Count = {}, 0
            for _, Val in next, DD.Values do
                local T = {}; Count += 1
                local B = Jqz:Create('Frame', {
                    BackgroundColor3 = Jqz.MainColor; BorderColor3 = Jqz.MainColor;
                    BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23; Active = true; Parent = Scroll;
                })
                Jqz:Corner(B, 4)
                Jqz:AddToRegistry(B, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'MainColor' })
                local BL = Jqz:CreateLabel({
                    Active = false; Size = UDim2.new(1, -6, 1, 0); Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 13; Text = Val; TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 25; Parent = B;
                })
                Jqz:OnHighlight(B, B, { BorderColor3 = 'AccentColor', ZIndex = 24 }, { BorderColor3 = 'MainColor', ZIndex = 23 })
                local Sel = Info.Multi and DD.Value[Val] or DD.Value == Val
                function T:UpdateBtn()
                    Sel = Info.Multi and DD.Value[Val] or DD.Value == Val
                    BL.TextColor3 = Sel and Jqz.AccentColor or Jqz.FontColor
                    Jqz.RegistryMap[BL].Properties.TextColor3 = Sel and 'AccentColor' or 'FontColor'
                end
                BL.InputBegan:Connect(function(i)
                    if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    local Try = not Sel
                    if DD:GetActiveValues() == 1 and not Try and not Info.AllowNull then return end
                    if Info.Multi then
                        Sel = Try
                        if Try then DD.Value[Val] = true else DD.Value[Val] = nil end
                    else
                        Sel = Try; DD.Value = Try and Val or nil
                        for _, ob in next, Btns do ob:UpdateBtn() end
                    end
                    T:UpdateBtn(); DD:Display()
                    Jqz:SafeCallback(DD.Callback, DD.Value)
                    Jqz:SafeCallback(DD.Changed,  DD.Value)
                    Jqz:AttemptSave()
                end)
                T:UpdateBtn(); DD:Display()
                Btns[B] = T
            end
            Scroll.CanvasSize = UDim2.fromOffset(0, Count*20+1)
            RSze(math.clamp(Count*20, 0, MAX*20)+1)
        end
        function DD:SetValues(v) if v then DD.Values = v end; DD:BuildList() end
        function DD:Open()  ListOuter.Visible = true;  Jqz.OpenedFrames[ListOuter] = true;  Arrow.Rotation = 180 end
        function DD:Close() ListOuter.Visible = false; Jqz.OpenedFrames[ListOuter] = nil;   Arrow.Rotation = 0   end
        function DD:OnChanged(fn) DD.Changed = fn; fn(DD.Value) end
        function DD:SetValue(v)
            if DD.Multi then
                local t = {}
                for val in next, v do if table.find(DD.Values, val) then t[val] = true end end
                DD.Value = t
            else
                DD.Value = (not v) and nil or (table.find(DD.Values, v) and v or DD.Value)
            end
            DD:BuildList()
            Jqz:SafeCallback(DD.Callback, DD.Value)
            Jqz:SafeCallback(DD.Changed,  DD.Value)
        end

        DOuter.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 and not Jqz:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then DD:Close() else DD:Open() end
            end
        end)
        InputService.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                local p, s = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize
                if Mouse.X < p.X or Mouse.X > p.X+s.X or Mouse.Y < p.Y-21 or Mouse.Y > p.Y+s.Y then DD:Close() end
            end
        end)

        DD:BuildList(); DD:Display()

        local Defaults = {}
        if type(Info.Default) == 'string' then
            local i = table.find(DD.Values, Info.Default); if i then table.insert(Defaults, i) end
        elseif type(Info.Default) == 'table' then
            for _, v in next, Info.Default do local i = table.find(DD.Values, v); if i then table.insert(Defaults, i) end end
        elseif type(Info.Default) == 'number' and DD.Values[Info.Default] then
            table.insert(Defaults, Info.Default)
        end
        if next(Defaults) then
            for _, idx in ipairs(Defaults) do
                if Info.Multi then DD.Value[DD.Values[idx]] = true
                else DD.Value = DD.Values[idx]; break end
            end
            DD:BuildList(); DD:Display()
        end

        GB:AddBlank(Info.BlankSize or 5); GB:Resize()
        Options[Idx] = DD
        return DD
    end

    function Funcs:AddDependencyBox()
        local GB = self
        local Depbox = { Dependencies = {} }
        local Holder = Jqz:Create('Frame', {
            BackgroundTransparency = 1; Size = UDim2.new(1, 0, 0, 0); Visible = false; Parent = GB.Container;
        })
        local Frame = Jqz:Create('Frame', {
            BackgroundTransparency = 1; Size = UDim2.new(1, 0, 1, 0); Visible = true; Parent = Holder;
        })
        local Layout = Jqz:Create('UIListLayout', { FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Parent = Frame })

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y); GB:Resize()
        end
        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() Depbox:Resize() end)
        Holder:GetPropertyChangedSignal('Visible'):Connect(function() Depbox:Resize() end)
        function Depbox:Update()
            for _, d in next, Depbox.Dependencies do
                if d[1].Type == 'Toggle' and d[1].Value ~= d[2] then
                    Holder.Visible = false; Depbox:Resize(); return
                end
            end
            Holder.Visible = true; Depbox:Resize()
        end
        function Depbox:SetupDependencies(deps)
            for _, d in next, deps do
                assert(type(d) == 'table' and d[1] and d[2] ~= nil)
            end
            Depbox.Dependencies = deps; Depbox:Update()
        end
        Depbox.Container = Frame
        setmetatable(Depbox, BaseGroupbox)
        table.insert(Jqz.DependencyBoxes, Depbox)
        return Depbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, Key, ...) return Funcs[Key](...) end
end

do
    Jqz.NotificationArea = Jqz:Create('Frame', {
        BackgroundTransparency = 1; Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200); ZIndex = 100; Parent = ScreenGui;
    })
    Jqz:Create('UIListLayout', {
        Padding = UDim.new(0, 5); FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder; Parent = Jqz.NotificationArea;
    })

    local WOuter = Jqz:Create('Frame', {
        BackgroundColor3 = Color3.new(0, 0, 0); BorderSizePixel = 0; Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20); ZIndex = 200; Visible = false; Parent = ScreenGui;
    })
    Jqz:Corner(WOuter, 6, true)
    local WInner = Jqz:Create('Frame', {
        BackgroundColor3 = Jqz.BackgroundColor; BorderColor3 = Jqz.OutlineColor;
        BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 1, 0); ZIndex = 201; Parent = WOuter;
    })
    Jqz:Corner(WInner, 6)
    Jqz:AddToRegistry(WInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })
    local WLabel = Jqz:CreateLabel({
        Position = UDim2.new(0, 8, 0, 0); Size = UDim2.new(1, -8, 1, 0);
        TextSize = 13; TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 203; Parent = WInner;
    })
    Jqz.Watermark = WOuter
    Jqz.WatermarkText = WLabel
    Jqz:MakeDraggable(WOuter)

    local KOuter = Jqz:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5); BackgroundColor3 = Color3.new(0, 0, 0); BorderSizePixel = 0;
        Position = UDim2.new(0, 10, 0.5, 0); Size = UDim2.new(0, 210, 0, 20);
        Visible = false; ZIndex = 100; Parent = ScreenGui;
    })
    Jqz:Corner(KOuter, 6, true)
    local KInner = Jqz:Create('Frame', {
        BackgroundColor3 = Jqz.BackgroundColor; BorderColor3 = Jqz.OutlineColor;
        BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 1, 0); ZIndex = 101; Parent = KOuter;
    })
    Jqz:Corner(KInner, 6)
    Jqz:AddToRegistry(KInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' }, true)
    local KBar = Jqz:Create('Frame', {
        BackgroundColor3 = Jqz.AccentColor; BorderSizePixel = 0;
        Position = UDim2.new(0, 5, 0, 1); Size = UDim2.new(1, -10, 0, 2); ZIndex = 102; Parent = KInner;
    })
    Jqz:Corner(KBar, 1, true)
    Jqz:AddToRegistry(KBar, { BackgroundColor3 = 'AccentColor' }, true)
    Jqz:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20); Position = UDim2.fromOffset(6, 3);
        TextXAlignment = Enum.TextXAlignment.Left; Text = 'Keybinds';
        ZIndex = 104; Parent = KInner;
    })
    local KContainer = Jqz:Create('Frame', {
        BackgroundTransparency = 1; Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20); ZIndex = 1; Parent = KInner;
    })
    Jqz:Create('UIListLayout', { FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Parent = KContainer })
    Jqz:Create('UIPadding', { PaddingLeft = UDim.new(0, 6); Parent = KContainer })
    Jqz.KeybindFrame = KOuter
    Jqz.KeybindContainer = KContainer
    Jqz:MakeDraggable(KOuter)
end

function Jqz:SetWatermarkVisibility(b) Jqz.Watermark.Visible = b end
function Jqz:SetWatermark(Text)
    local X, Y = Jqz:GetTextBounds(Text, Jqz.Font, 13)
    Jqz.Watermark.Size = UDim2.new(0, X + 16, 0, (Y * 1.5) + 3)
    Jqz:SetWatermarkVisibility(true)
    Jqz.WatermarkText.Text = Text
end

function Jqz:Notify(Text, Time)
    local X, Y = Jqz:GetTextBounds(Text, Jqz.Font, 13)
    Y += 8
    local NOuter = Jqz:Create('Frame', {
        BackgroundColor3 = Color3.new(0, 0, 0); BorderSizePixel = 0; Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, Y); ClipsDescendants = true; ZIndex = 100; Parent = Jqz.NotificationArea;
    })
    Jqz:Corner(NOuter, 6, true)
    local NInner = Jqz:Create('Frame', {
        BackgroundColor3 = Jqz.BackgroundColor; BorderColor3 = Jqz.OutlineColor;
        BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 1, 0); ZIndex = 101; Parent = NOuter;
    })
    Jqz:Corner(NInner, 6)
    Jqz:AddToRegistry(NInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' }, true)
    Jqz:CreateLabel({
        Position = UDim2.new(0, 12, 0, 0); Size = UDim2.new(1, -12, 1, 0);
        Text = Text; TextXAlignment = Enum.TextXAlignment.Left; TextSize = 13; ZIndex = 103; Parent = NInner;
    })
    local NBar = Jqz:Create('Frame', {
        BackgroundColor3 = Jqz.AccentColor; BorderSizePixel = 0;
        Position = UDim2.new(0, 5, 0, 5); Size = UDim2.new(0, 2, 1, -10); ZIndex = 104; Parent = NOuter;
    })
    Jqz:Corner(NBar, 1, true)
    Jqz:AddToRegistry(NBar, { BackgroundColor3 = 'AccentColor' }, true)
    pcall(NOuter.TweenSize, NOuter, UDim2.new(0, X + 26, 0, Y), 'Out', 'Quad', 0.3, true)
    task.spawn(function()
        wait(Time or 5)
        pcall(NOuter.TweenSize, NOuter, UDim2.new(0, 0, 0, Y), 'Out', 'Quad', 0.3, true)
        wait(0.3)
        NOuter:Destroy()
    end)
end

function Jqz:CreateWindow(Config)
    if type(Config) ~= 'table' then Config = { Title = tostring(Config) } end
    Config.Title = type(Config.Title) == 'string' and Config.Title or 'Jqz'
    Config.TabPadding = type(Config.TabPadding) == 'number' and Config.TabPadding or 6
    Config.MenuFadeTime = type(Config.MenuFadeTime) == 'number' and Config.MenuFadeTime or 0.2
    Config.AnchorPoint = Config.AnchorPoint or Vector2.zero
    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 600) end
    if Config.Center then Config.AnchorPoint = Vector2.new(0.5, 0.5); Config.Position = UDim2.fromScale(0.5, 0.5) end

    local Window = { Tabs = {} }

    local Outer = Jqz:Create('Frame', {
        AnchorPoint = Config.AnchorPoint; BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0; Position = Config.Position; Size = Config.Size;
        Visible = false; ZIndex = 1; Parent = ScreenGui;
    })
    Jqz:MakeDraggable(Outer, 25)

    local Inner = Jqz:Create('Frame', {
        BackgroundColor3 = Jqz.BackgroundColor; BorderColor3 = Jqz.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0); ZIndex = 1; Parent = Outer;
    })
    Jqz:Corner(Inner, 9)
    Jqz.BorderMap[Inner].Thickness = 3
    Jqz:AddToRegistry(Inner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })

    local TitleLabel = Jqz:CreateLabel({
        Position = UDim2.new(0, 14, 0, 6); Size = UDim2.new(1, -28, 0, 22);
        Text = Config.Title; TextXAlignment = Enum.TextXAlignment.Left; TextSize = 14; ZIndex = 3; Parent = Inner;
    })
    TitleLabel.TextColor3 = Jqz.AccentColor
    Jqz.RegistryMap[TitleLabel].Properties.TextColor3 = 'AccentColor'

    local TitleLine = Jqz:Create('Frame', {
        BackgroundColor3 = Jqz.OutlineColor; BorderSizePixel = 0;
        Position = UDim2.new(0, 8, 0, 33); Size = UDim2.new(1, -16, 0, 1); ZIndex = 3; Parent = Inner;
    })
    Jqz:AddToRegistry(TitleLine, { BackgroundColor3 = 'OutlineColor' })

    local TabArea = Jqz:Create('Frame', {
        BackgroundTransparency = 1; Position = UDim2.new(0, 8, 0, 42);
        Size = UDim2.new(1, -16, 0, 25); ZIndex = 1; Parent = Inner;
    })
    local TabLayout = Jqz:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding); FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder; Parent = TabArea;
    })
    local TabDivider = Jqz:Create('Frame', {
        BackgroundColor3 = Jqz.OutlineColor; BorderSizePixel = 0;
        Position = UDim2.new(0, 8, 0, 66); Size = UDim2.new(1, -16, 0, 1); ZIndex = 2; Parent = Inner;
    })
    Jqz:AddToRegistry(TabDivider, { BackgroundColor3 = 'OutlineColor' })
    local TabContainer = Jqz:Create('Frame', {
        BackgroundTransparency = 1; BorderSizePixel = 0;
        Position = UDim2.new(0, 8, 0, 74); Size = UDim2.new(1, -16, 1, -82);
        ZIndex = 2; Parent = Inner;
    })

    function Window:SetWindowTitle(t) TitleLabel.Text = t end

    function Window:AddTab(Name)
        local Tab = { Groupboxes = {}; Tabboxes = {} }

        local BtnW = Jqz:GetTextBounds(Name, Jqz.Font, 13)
        local TabBtn = Jqz:Create('Frame', {
            BackgroundTransparency = 1; BorderSizePixel = 0;
            Size = UDim2.new(0, BtnW + 22, 1, 0); ZIndex = 3; Parent = TabArea;
        })
        local TabLbl = Jqz:CreateLabel({
            Size = UDim2.new(1, 0, 1, -2); Text = Name; TextSize = 13; ZIndex = 4; Parent = TabBtn;
        })
        local TabLine = Jqz:Create('Frame', {
            BackgroundColor3 = Jqz.AccentColor; BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, -2); Size = UDim2.new(1, 0, 0, 2);
            Visible = false; ZIndex = 5; Parent = TabBtn;
        })
        Jqz:AddToRegistry(TabLine, { BackgroundColor3 = 'AccentColor' })

        local TabFrame = Jqz:Create('Frame', {
            Name = 'TabFrame'; BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0); Visible = false; ZIndex = 2; Parent = TabContainer;
        })

        local function MakeSide(xPos, xSize)
            local s = Jqz:Create('ScrollingFrame', {
                BackgroundTransparency = 1; BorderSizePixel = 0;
                Position = xPos; Size = xSize;
                CanvasSize = UDim2.new(0, 0, 0, 0); BottomImage = ''; TopImage = '';
                ScrollBarThickness = 0; ZIndex = 2; Parent = TabFrame;
            })
            Jqz:Create('UIListLayout', {
                Padding = UDim.new(0, 8); FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder; HorizontalAlignment = Enum.HorizontalAlignment.Center;
                Parent = s;
            })
            s:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                s.CanvasSize = UDim2.fromOffset(0, s.UIListLayout.AbsoluteContentSize.Y)
            end)
            return s
        end
        local LeftSide = MakeSide(UDim2.new(0, 7, 0, 7), UDim2.new(0.5, -11, 1, -14))
        local RightSide = MakeSide(UDim2.new(0.5, 5, 0, 7), UDim2.new(0.5, -11, 1, -14))

        function Tab:ShowTab()
            for _, t in next, Window.Tabs do t:HideTab() end
            TabLine.Visible = true
            TabLbl.TextColor3 = Jqz.FontColor
            Jqz.RegistryMap[TabLbl].Properties.TextColor3 = 'FontColor'
            TabFrame.Visible = true
        end
        function Tab:HideTab()
            TabLine.Visible = false
            TabLbl.TextColor3 = Jqz.DimColor
            Jqz.RegistryMap[TabLbl].Properties.TextColor3 = 'DimColor'
            TabFrame.Visible = false
        end
        function Tab:SetLayoutOrder(n) TabBtn.LayoutOrder = n; TabLayout:ApplyLayout() end

        function Tab:AddGroupbox(Info)
            local GB = {}
            local Side = Info.Side == 1 and LeftSide or RightSide

            local BOuter = Jqz:Create('Frame', {
                BackgroundColor3 = Jqz.BackgroundColor; BorderColor3 = Jqz.OutlineColor;
                BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 0, 509);
                ZIndex = 2; Parent = Side;
            })
            Jqz:Corner(BOuter, 7)
            Jqz:AddToRegistry(BOuter, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })
            local BInner = Jqz:Create('Frame', {
                BackgroundTransparency = 1; BorderSizePixel = 0;
                Size = UDim2.new(1, -2, 1, -2); Position = UDim2.new(0, 1, 0, 1); ZIndex = 4; Parent = BOuter;
            })
            local BBar = Jqz:Create('Frame', {
                BackgroundColor3 = Jqz.AccentColor; BorderSizePixel = 0;
                Position = UDim2.new(0, 6, 0, 1); Size = UDim2.new(1, -12, 0, 2); ZIndex = 5; Parent = BInner;
            })
            Jqz:Corner(BBar, 1, true)
            Jqz:AddToRegistry(BBar, { BackgroundColor3 = 'AccentColor' })
            Jqz:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18); Position = UDim2.new(0, 6, 0, 3);
                TextSize = 13; Text = Info.Name; TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5; Parent = BInner;
            })
            local Container = Jqz:Create('Frame', {
                BackgroundTransparency = 1; Position = UDim2.new(0, 5, 0, 22);
                Size = UDim2.new(1, -5, 1, -22); ZIndex = 1; Parent = BInner;
            })
            Jqz:Create('UIListLayout', { FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Parent = Container })

            function GB:Resize()
                local sz = 0
                for _, el in next, GB.Container:GetChildren() do
                    if not el:IsA('UIListLayout') and el.Visible then sz += el.Size.Y.Offset end
                end
                BOuter.Size = UDim2.new(1, 0, 0, 22 + sz + 4)
            end
            GB.Container = Container
            setmetatable(GB, BaseGroupbox)
            GB:AddBlank(3); GB:Resize()
            Tab.Groupboxes[Info.Name] = GB
            return GB
        end

        function Tab:AddLeftGroupbox(n) return Tab:AddGroupbox({ Side = 1; Name = n }) end
        function Tab:AddRightGroupbox(n) return Tab:AddGroupbox({ Side = 2; Name = n }) end

        function Tab:AddTabbox(Info)
            local Tabbox = { Tabs = {} }
            local Side = Info.Side == 1 and LeftSide or RightSide

            local BOuter = Jqz:Create('Frame', {
                BackgroundColor3 = Jqz.BackgroundColor; BorderColor3 = Jqz.OutlineColor;
                BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2; Parent = Side;
            })
            Jqz:Corner(BOuter, 7)
            Jqz:AddToRegistry(BOuter, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })
            local BInner = Jqz:Create('Frame', {
                BackgroundTransparency = 1; BorderSizePixel = 0;
                Size = UDim2.new(1, -2, 1, -2); Position = UDim2.new(0, 1, 0, 1); ZIndex = 4; Parent = BOuter;
            })
            local BBar = Jqz:Create('Frame', {
                BackgroundColor3 = Jqz.AccentColor; BorderSizePixel = 0;
                Position = UDim2.new(0, 6, 0, 1); Size = UDim2.new(1, -12, 0, 2); ZIndex = 10; Parent = BInner;
            })
            Jqz:Corner(BBar, 1, true)
            Jqz:AddToRegistry(BBar, { BackgroundColor3 = 'AccentColor' })
            local TabboxBtns = Jqz:Create('Frame', {
                BackgroundTransparency = 1; Position = UDim2.new(0, 3, 0, 4);
                Size = UDim2.new(1, -6, 0, 18); ZIndex = 5; Parent = BInner;
            })
            Jqz:Create('UIListLayout', { FillDirection = Enum.FillDirection.Horizontal; HorizontalAlignment = Enum.HorizontalAlignment.Left; SortOrder = Enum.SortOrder.LayoutOrder; Parent = TabboxBtns })

            function Tabbox:AddTab(Name)
                local IT = {}
                local Btn = Jqz:Create('Frame', {
                    BackgroundTransparency = 1; BorderSizePixel = 0;
                    Size = UDim2.new(0.5, 0, 1, 0); ZIndex = 6; Parent = TabboxBtns;
                })
                local BtnLbl = Jqz:CreateLabel({
                    Size = UDim2.new(1, 0, 1, -2); TextSize = 13; Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center; ZIndex = 7; Parent = Btn;
                })
                local Block = Jqz:Create('Frame', {
                    BackgroundColor3 = Jqz.AccentColor; BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, -2); Size = UDim2.new(1, 0, 0, 2);
                    Visible = false; ZIndex = 9; Parent = Btn;
                })
                Jqz:AddToRegistry(Block, { BackgroundColor3 = 'AccentColor' })
                local Container = Jqz:Create('Frame', {
                    BackgroundTransparency = 1; Position = UDim2.new(0, 5, 0, 24);
                    Size = UDim2.new(1, -5, 1, -24); ZIndex = 1; Visible = false; Parent = BInner;
                })
                Jqz:Create('UIListLayout', { FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Parent = Container })

                function IT:Show()
                    for _, t in next, Tabbox.Tabs do t:Hide() end
                    Container.Visible = true; Block.Visible = true
                    BtnLbl.TextColor3 = Jqz.FontColor
                    Jqz.RegistryMap[BtnLbl].Properties.TextColor3 = 'FontColor'
                    IT:Resize()
                end
                function IT:Hide()
                    Container.Visible = false; Block.Visible = false
                    BtnLbl.TextColor3 = Jqz.DimColor
                    Jqz.RegistryMap[BtnLbl].Properties.TextColor3 = 'DimColor'
                end
                function IT:Resize()
                    local c = 0
                    for _ in next, Tabbox.Tabs do c += 1 end
                    for _, b in next, TabboxBtns:GetChildren() do
                        if not b:IsA('UIListLayout') then b.Size = UDim2.new(1/c, 0, 1, 0) end
                    end
                    if not Container.Visible then return end
                    local sz = 0
                    for _, el in next, IT.Container:GetChildren() do
                        if not el:IsA('UIListLayout') and el.Visible then sz += el.Size.Y.Offset end
                    end
                    BOuter.Size = UDim2.new(1, 0, 0, 24 + sz + 4)
                end
                Btn.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 and not Jqz:MouseIsOverOpenedFrame() then
                        IT:Show(); IT:Resize()
                    end
                end)
                IT.Container = Container
                Tabbox.Tabs[Name] = IT
                setmetatable(IT, BaseGroupbox)
                IT:AddBlank(3); IT:Resize()
                if #TabboxBtns:GetChildren() == 2 then IT:Show() else IT:Hide() end
                return IT
            end

            Tab.Tabboxes[Info.Name or ''] = Tabbox
            return Tabbox
        end

        function Tab:AddLeftTabbox(n) return Tab:AddTabbox({ Name = n; Side = 1 }) end
        function Tab:AddRightTabbox(n) return Tab:AddTabbox({ Name = n; Side = 2 }) end

        TabBtn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then Tab:ShowTab() end
        end)
        Tab:HideTab()
        local IsFirstTab = next(Window.Tabs) == nil
        Window.Tabs[Name] = Tab
        if IsFirstTab then Tab:ShowTab() end
        return Tab
    end

    local Modal = Jqz:Create('TextButton', {
        BackgroundTransparency = 1; Size = UDim2.new(0, 0, 0, 0);
        Visible = true; Text = ''; Modal = false; Parent = ScreenGui;
    })
    local Cache, Toggled, Fading = {}, false, false

    function Jqz:Toggle()
        if Fading then return end
        local ft = Config.MenuFadeTime
        Fading = true; Toggled = not Toggled
        Modal.Modal = Toggled

        if Toggled then
            Outer.Visible = true
            task.spawn(function()
                local prevIcon = InputService.MouseIconEnabled
                local Cur = Drawing.new('Triangle')
                Cur.Thickness = 1; Cur.Filled = true; Cur.Visible = true
                local CurO = Drawing.new('Triangle')
                CurO.Thickness = 1; CurO.Filled = false; CurO.Color = Color3.new(0, 0, 0); CurO.Visible = true
                while Toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false
                    local mp = InputService:GetMouseLocation()
                    Cur.Color = Jqz.AccentColor
                    Cur.PointA = Vector2.new(mp.X,    mp.Y)
                    Cur.PointB = Vector2.new(mp.X+16, mp.Y+6)
                    Cur.PointC = Vector2.new(mp.X+6,  mp.Y+16)
                    CurO.PointA = Cur.PointA; CurO.PointB = Cur.PointB; CurO.PointC = Cur.PointC
                    RunService.RenderStepped:Wait()
                end
                InputService.MouseIconEnabled = prevIcon
                Cur:Remove(); CurO:Remove()
            end)
        end

        for _, d in next, Outer:GetDescendants() do
            local props = {}
            if d:IsA('ImageLabel') then
                table.insert(props, 'ImageTransparency'); table.insert(props, 'BackgroundTransparency')
            elseif d:IsA('TextLabel') or d:IsA('TextBox') then
                table.insert(props, 'TextTransparency')
            elseif d:IsA('Frame') or d:IsA('ScrollingFrame') then
                table.insert(props, 'BackgroundTransparency')
            elseif d:IsA('UIStroke') then
                table.insert(props, 'Transparency')
            end
            local c = Cache[d]
            if not c then c = {}; Cache[d] = c end
            for _, p in next, props do
                if not c[p] then c[p] = d[p] end
                if c[p] == 1 then continue end
                TweenService:Create(d, TweenInfo.new(ft, Enum.EasingStyle.Linear), { [p] = Toggled and c[p] or 1 }):Play()
            end
        end

        task.wait(ft)
        Outer.Visible = Toggled
        Fading = false
    end

    Jqz:GiveSignal(InputService.InputBegan:Connect(function(i, proc)
        if type(Jqz.ToggleKeybind) == 'table' and Jqz.ToggleKeybind.Type == 'KeyPicker' then
            if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == Jqz.ToggleKeybind.Value then
                task.spawn(Jqz.Toggle)
            end
        elseif i.KeyCode == Enum.KeyCode.RightControl
            or (i.KeyCode == Enum.KeyCode.RightShift and not proc) then
            task.spawn(Jqz.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Jqz.Toggle) end
    Window.Holder = Outer
    return Window
end

local function RefreshPlayers()
    local list = GetPlayersString()
    for _, v in next, Options do
        if v.Type == 'Dropdown' and v.SpecialType == 'Player' then v:SetValues(list) end
    end
end
Players.PlayerAdded:Connect(RefreshPlayers)
Players.PlayerRemoving:Connect(RefreshPlayers)

getgenv().Jqz = Jqz
return Jqz
