-- ============================================================================
-- HotkeyBuilder.txt - Plasmii Hotkey & Combo Macro Builder Plugin
-- Styled 100% natively to match the Plasmii UI Suite
-- Font: RobotoMono / RobotoCondensed | Topbar: RGB(29, 29, 29) | Body: RGB(18, 18, 18)
-- ============================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

-- ============================================================================
-- Section 1: Cleanup & Hot-Reload Isolation
-- ============================================================================
local genv = (typeof(getgenv) == "function" and getgenv()) or nil
if genv and genv.__HotkeyBuilderCleanup then
    pcall(genv.__HotkeyBuilderCleanup)
    genv.__HotkeyBuilderCleanup = nil
end

local Janitor = {}
local function Own(x)
    table.insert(Janitor, x)
    return x
end

-- ============================================================================
-- Section 2: Macro State & Persistence
-- ============================================================================
local CONFIG_FILE = "hotkey_macros.json"

local State = {
    Enabled = true,
    UIVisible = false,
    SelectedMacroIndex = 1,
    ListeningForTrigger = false,
    Macros = {
        {
            Name = "Weapon Swap Combo",
            Enabled = true,
            Trigger = "R",
            Steps = {
                { Type = "Key", Value = "One" },
                { Type = "Wait", Value = 0.1 },
                { Type = "Click", Value = "Left" },
                { Type = "Key", Value = "Two" },
                { Type = "Wait", Value = 0.1 },
                { Type = "Click", Value = "Left" },
                { Type = "Key", Value = "Three" },
            }
        }
    }
}

local function LoadMacros()
    pcall(function()
        if typeof(readfile) == "function" and typeof(isfile) == "function" then
            if isfile(CONFIG_FILE) then
                local raw = readfile(CONFIG_FILE)
                local data = HttpService:JSONDecode(raw)
                if type(data) == "table" and type(data.Macros) == "table" and #data.Macros > 0 then
                    State.Macros = data.Macros
                    if data.Enabled ~= nil then State.Enabled = data.Enabled end
                end
            end
        end
    end)
end

local function SaveMacros()
    pcall(function()
        if typeof(writefile) == "function" then
            local data = {
                Enabled = State.Enabled,
                Macros = State.Macros
            }
            writefile(CONFIG_FILE, HttpService:JSONEncode(data))
        end
    end)
end

LoadMacros()

-- ============================================================================
-- Section 3: Input Simulation Engine (VirtualInputManager + Fallbacks)
-- ============================================================================
local KeyNameToKeyCode = {
    ["0"] = Enum.KeyCode.Zero, ["1"] = Enum.KeyCode.One, ["2"] = Enum.KeyCode.Two,
    ["3"] = Enum.KeyCode.Three, ["4"] = Enum.KeyCode.Four, ["5"] = Enum.KeyCode.Five,
    ["6"] = Enum.KeyCode.Six, ["7"] = Enum.KeyCode.Seven, ["8"] = Enum.KeyCode.Eight,
    ["9"] = Enum.KeyCode.Nine,
    ["A"] = Enum.KeyCode.A, ["B"] = Enum.KeyCode.B, ["C"] = Enum.KeyCode.C,
    ["D"] = Enum.KeyCode.D, ["E"] = Enum.KeyCode.E, ["F"] = Enum.KeyCode.F,
    ["G"] = Enum.KeyCode.G, ["H"] = Enum.KeyCode.H, ["I"] = Enum.KeyCode.I,
    ["J"] = Enum.KeyCode.J, ["K"] = Enum.KeyCode.K, ["L"] = Enum.KeyCode.L,
    ["M"] = Enum.KeyCode.M, ["N"] = Enum.KeyCode.N, ["O"] = Enum.KeyCode.O,
    ["P"] = Enum.KeyCode.P, ["Q"] = Enum.KeyCode.Q, ["R"] = Enum.KeyCode.R,
    ["S"] = Enum.KeyCode.S, ["T"] = Enum.KeyCode.T, ["U"] = Enum.KeyCode.U,
    ["V"] = Enum.KeyCode.V, ["W"] = Enum.KeyCode.W, ["X"] = Enum.KeyCode.X,
    ["Y"] = Enum.KeyCode.Y, ["Z"] = Enum.KeyCode.Z,
    ["SPACE"] = Enum.KeyCode.Space, ["LSHIFT"] = Enum.KeyCode.LeftShift,
    ["RSHIFT"] = Enum.KeyCode.RightShift, ["LCTRL"] = Enum.KeyCode.LeftControl,
    ["RCTRL"] = Enum.KeyCode.RightControl, ["TAB"] = Enum.KeyCode.Tab,
    ["RETURN"] = Enum.KeyCode.Return, ["ENTER"] = Enum.KeyCode.Return,
    ["BACKQUOTE"] = Enum.KeyCode.Backquote, ["TILDE"] = Enum.KeyCode.Backquote,
}

local function ResolveKeyCode(str)
    if not str or str == "" then return nil end
    local upper = string.upper(tostring(str))
    if KeyNameToKeyCode[upper] then
        return KeyNameToKeyCode[upper]
    end
    for _, enumItem in ipairs(Enum.KeyCode:GetEnumItems()) do
        if string.upper(enumItem.Name) == upper then
            return enumItem
        end
    end
    return nil
end

local HeldKeys = {}

local function SimulateKeyPress(keyCode)
    if not keyCode then return end
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        elseif typeof(keypress) == "function" and typeof(keyrelease) == "function" then
            keypress(keyCode.Value)
            task.wait(0.02)
            keyrelease(keyCode.Value)
        end
    end)
end

local function SimulateKeyDown(keyCode)
    if not keyCode then return end
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        elseif typeof(keypress) == "function" then
            keypress(keyCode.Value)
        end
    end)
end

local function SimulateKeyUp(keyCode)
    if not keyCode then return end
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        elseif typeof(keyrelease) == "function" then
            keyrelease(keyCode.Value)
        end
    end)
end

local HeldMouseButtons = {}

local function ReleaseAllHeldKeys()
    for kc in pairs(HeldKeys) do
        SimulateKeyUp(kc)
        HeldKeys[kc] = nil
    end
end

local function SimulateMouseClick(buttonType)
    pcall(function()
        local mousePos = UserInputService:GetMouseLocation()
        local isLeft = (buttonType ~= "Right")
        if VirtualInputManager then
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, isLeft and 0 or 1, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, isLeft and 0 or 1, false, game, 0)
        elseif isLeft and typeof(mouse1click) == "function" then
            mouse1click()
        elseif not isLeft and typeof(mouse2click) == "function" then
            mouse2click()
        end
    end)
end

local function SimulateMouseDown(buttonType)
    pcall(function()
        local mousePos = UserInputService:GetMouseLocation()
        local isLeft = (buttonType ~= "Right")
        if VirtualInputManager then
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, isLeft and 0 or 1, true, game, 0)
        elseif isLeft and typeof(mouse1press) == "function" then
            mouse1press()
        elseif not isLeft and typeof(mouse2press) == "function" then
            mouse2press()
        end
    end)
end

local function SimulateMouseUp(buttonType)
    pcall(function()
        local mousePos = UserInputService:GetMouseLocation()
        local isLeft = (buttonType ~= "Right")
        if VirtualInputManager then
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, isLeft and 0 or 1, false, game, 0)
        elseif isLeft and typeof(mouse1release) == "function" then
            mouse1release()
        elseif not isLeft and typeof(mouse2release) == "function" then
            mouse2release()
        end
    end)
end

local function ReleaseAllHeldMouseButtons()
    for btn in pairs(HeldMouseButtons) do
        SimulateMouseUp(btn)
        HeldMouseButtons[btn] = nil
    end
end

local RunningMacros = {}

local function ExecuteMacro(macro)
    if not macro or not macro.Enabled or #macro.Steps == 0 then return end
    if RunningMacros[macro] then return end
    RunningMacros[macro] = true

    task.spawn(function()
        for _, step in ipairs(macro.Steps) do
            if not State.Enabled then break end
            if step.Type == "Key" then
                local kc = ResolveKeyCode(step.Value)
                if kc then SimulateKeyPress(kc) end
            elseif step.Type == "KeyDown" then
                local kc = ResolveKeyCode(step.Value)
                if kc then
                    HeldKeys[kc] = true
                    SimulateKeyDown(kc)
                end
            elseif step.Type == "KeyUp" then
                local kc = ResolveKeyCode(step.Value)
                if kc then
                    HeldKeys[kc] = nil
                    SimulateKeyUp(kc)
                end
            elseif step.Type == "Wait" then
                local dur = tonumber(step.Value) or 0.1
                task.wait(math.clamp(dur, 0.001, 10))
            elseif step.Type == "Click" then
                SimulateMouseClick(step.Value)
            elseif step.Type == "MouseDown" then
                HeldMouseButtons[step.Value] = true
                SimulateMouseDown(step.Value)
            elseif step.Type == "MouseUp" then
                HeldMouseButtons[step.Value] = nil
                SimulateMouseUp(step.Value)
            end
        end
        RunningMacros[macro] = nil
    end)
end

Own(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not State.Enabled then return end
    if UserInputService:GetFocusedTextBox() then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        for _, macro in ipairs(State.Macros) do
            if macro.Enabled and macro.Trigger then
                local triggerKey = ResolveKeyCode(macro.Trigger)
                if triggerKey and input.KeyCode == triggerKey then
                    ExecuteMacro(macro)
                end
            end
        end
    end
end))

-- ============================================================================
-- Section 4: 100% Plasmii-Native GUI Styling
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Plasmii_HotkeyBuilder"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 150

local parentTarget = (typeof(gethui) == "function" and gethui()) or CoreGui
ScreenGui.Parent = parentTarget
Own(ScreenGui)

-- Native Plasmii Window: RGB(18, 18, 18), UICorner: 8
local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, 360, 0, 520)
Window.Position = UDim2.new(0.5, -180, 0.5, -260)
Window.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Window.BorderSizePixel = 0
Window.ClipsDescendants = true
Window.Visible = false
Window.Parent = ScreenGui

local WindowCorner = Instance.new("UICorner")
WindowCorner.CornerRadius = UDim.new(0, 8)
WindowCorner.Parent = Window

-- Native Plasmii Topbar: RGB(29, 29, 29), Height: 30
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 30)
Topbar.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Topbar.BorderSizePixel = 0
Topbar.Parent = Window

local TopbarCorner = Instance.new("UICorner")
TopbarCorner.CornerRadius = UDim.new(0, 8)
TopbarCorner.Parent = Topbar

local TopbarBottomCover = Instance.new("Frame")
TopbarBottomCover.Size = UDim2.new(1, 0, 0, 8)
TopbarBottomCover.Position = UDim2.new(0, 0, 1, -8)
TopbarBottomCover.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
TopbarBottomCover.BorderSizePixel = 0
TopbarBottomCover.Parent = Topbar

-- Native Plasmii Title: Centered, Font: RobotoMono, Size: 18, Color: White
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.RobotoMono
Title.TextSize = 16
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.Text = "Hotkey Builder"
Title.Parent = Topbar

-- Native Plasmii Exit Button: Font: RobotoCondensed, Size: 18, Color: Red (255, 0, 0)
local Exit = Instance.new("TextButton")
Exit.Name = "Exit"
Exit.Size = UDim2.new(0, 30, 0, 30)
Exit.Position = UDim2.new(1, -30, 0, 0)
Exit.BackgroundTransparency = 1
Exit.Font = Enum.Font.RobotoCondensed
Exit.TextSize = 18
Exit.TextColor3 = Color3.fromRGB(255, 0, 0)
Exit.Text = "X"
Exit.Parent = Topbar

-- Dragging Logic
local isDragging = false
local dragStart, startPos
Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = Window.Position
    end
end)

Own(UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

Own(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end))

-- Native Plasmii Container: ScrollingFrame, Size: {1, 0}, {1, -30}, Pos: {0, 0}, {0, 30}
local Container = Instance.new("ScrollingFrame")
Container.Name = "Container"
Container.Size = UDim2.new(1, 0, 1, -30)
Container.Position = UDim2.new(0, 0, 0, 30)
Container.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Container.BorderSizePixel = 0
Container.ScrollBarThickness = 4
Container.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.Parent = Window

local ContainerLayout = Instance.new("UIListLayout")
ContainerLayout.Padding = UDim.new(0, 6)
ContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContainerLayout.Parent = Container

local ContainerPadding = Instance.new("UIPadding")
ContainerPadding.PaddingTop = UDim.new(0, 8)
ContainerPadding.PaddingBottom = UDim.new(0, 8)
ContainerPadding.PaddingLeft = UDim.new(0, 10)
ContainerPadding.PaddingRight = UDim.new(0, 10)
ContainerPadding.Parent = Container

-- Helper function to create native Plasmii row containers:
-- BackgroundColor: RGB(48, 48, 48), Transparency: 0.95, UICorner: 8
local function CreatePlasmiiRow(height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, height or 30)
    row.BackgroundColor3 = Color3.fromRGB(48, 48, 48)
    row.BackgroundTransparency = 0.95
    row.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = row

    return row
end

-- Helper function to create native Plasmii button/input controls:
-- BackgroundColor: RGB(255, 255, 255), Transparency: 0.95, UICorner: 8, Font: RobotoMono, Size: 16
local function CreatePlasmiiButton(text, widthScale, xPosScale)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(widthScale or 0.35, 0, 1, 0)
    btn.Position = UDim2.new(xPosScale or 0.65, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.95
    btn.Font = Enum.Font.RobotoMono
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextXAlignment = Enum.TextXAlignment.Center
    btn.Text = text or ""

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    return btn
end

local function CreatePlasmiiLabel(text, widthScale)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(widthScale or 0.65, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.RobotoMono
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.Text = text or ""
    return lbl
end

-- ============================================================================
-- Section 5: Constructing the Controls
-- ============================================================================

-- 1. Macro Switcher Row
local MacroRow = CreatePlasmiiRow(30)
MacroRow.Name = "Row_MacroSelect"
MacroRow.LayoutOrder = 1
MacroRow.Parent = Container

local MacroLabel = CreatePlasmiiLabel("Select Macro", 0.5)
MacroLabel.Parent = MacroRow

local MacroPrevBtn = CreatePlasmiiButton("<", 0.12, 0.52)
MacroPrevBtn.Parent = MacroRow

local MacroIndexDisplay = Instance.new("TextLabel")
MacroIndexDisplay.Size = UDim2.new(0.22, 0, 1, 0)
MacroIndexDisplay.Position = UDim2.new(0.65, 0, 0, 0)
MacroIndexDisplay.BackgroundTransparency = 1
MacroIndexDisplay.Font = Enum.Font.RobotoMono
MacroIndexDisplay.TextSize = 13
MacroIndexDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
MacroIndexDisplay.TextXAlignment = Enum.TextXAlignment.Center
MacroIndexDisplay.Text = "1 / 1"
MacroIndexDisplay.Parent = MacroRow

local MacroNextBtn = CreatePlasmiiButton(">", 0.12, 0.88)
MacroNextBtn.Parent = MacroRow

-- 2. Macro Name Input Row
local NameRow = CreatePlasmiiRow(30)
NameRow.Name = "Row_MacroName"
NameRow.LayoutOrder = 2
NameRow.Parent = Container

local NameLabel = CreatePlasmiiLabel("Macro Name", 0.4)
NameLabel.Parent = NameRow

local NameInput = Instance.new("TextBox")
NameInput.Size = UDim2.new(0.58, 0, 1, 0)
NameInput.Position = UDim2.new(0.42, 0, 0, 0)
NameInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
NameInput.BackgroundTransparency = 0.95
NameInput.Font = Enum.Font.RobotoMono
NameInput.TextSize = 13
NameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
NameInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
NameInput.PlaceholderText = "input"
NameInput.Text = ""
NameInput.ClearTextOnFocus = false
NameInput.Parent = NameRow

local NameInputCorner = Instance.new("UICorner")
NameInputCorner.CornerRadius = UDim.new(0, 8)
NameInputCorner.Parent = NameInput

-- 3. Trigger Key Row
local TriggerRow = CreatePlasmiiRow(30)
TriggerRow.Name = "Row_Trigger"
TriggerRow.LayoutOrder = 3
TriggerRow.Parent = Container

local TriggerLabel = CreatePlasmiiLabel("Trigger Key", 0.5)
TriggerLabel.Parent = TriggerRow

local TriggerBtn = CreatePlasmiiButton("[ R ]", 0.48, 0.52)
TriggerBtn.Parent = TriggerRow

-- 4. Status Toggle Row
local StatusRow = CreatePlasmiiRow(30)
StatusRow.Name = "Row_Status"
StatusRow.LayoutOrder = 4
StatusRow.Parent = Container

local StatusLabel = CreatePlasmiiLabel("Macro Status", 0.5)
StatusLabel.Parent = StatusRow

local StatusBtn = CreatePlasmiiButton("Enabled", 0.48, 0.52)
StatusBtn.Parent = StatusRow

-- Divider: Add Actions Header
local ActionHeaderRow = CreatePlasmiiRow(24)
ActionHeaderRow.Name = "Row_ActionHeader"
ActionHeaderRow.LayoutOrder = 5
ActionHeaderRow.BackgroundTransparency = 1
ActionHeaderRow.Parent = Container

local ActionHeaderLabel = Instance.new("TextLabel")
ActionHeaderLabel.Size = UDim2.new(1, 0, 1, 0)
ActionHeaderLabel.BackgroundTransparency = 1
ActionHeaderLabel.Font = Enum.Font.RobotoMono
ActionHeaderLabel.TextSize = 13
ActionHeaderLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
ActionHeaderLabel.TextXAlignment = Enum.TextXAlignment.Center
ActionHeaderLabel.Text = "-- Add Action Steps --"
ActionHeaderLabel.Parent = ActionHeaderRow

-- 5. Add Key Press Row
local AddKeyRow = CreatePlasmiiRow(30)
AddKeyRow.Name = "Row_AddKey"
AddKeyRow.LayoutOrder = 6
AddKeyRow.Parent = Container

local AddKeyLabel = CreatePlasmiiLabel("Key Action", 0.22)
AddKeyLabel.Parent = AddKeyRow

local AddKeyInput = Instance.new("TextBox")
AddKeyInput.Size = UDim2.new(0.20, 0, 1, 0)
AddKeyInput.Position = UDim2.new(0.24, 0, 0, 0)
AddKeyInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AddKeyInput.BackgroundTransparency = 0.95
AddKeyInput.Font = Enum.Font.RobotoMono
AddKeyInput.TextSize = 13
AddKeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
AddKeyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
AddKeyInput.PlaceholderText = "1"
AddKeyInput.Text = "1"
AddKeyInput.ClearTextOnFocus = false
AddKeyInput.Parent = AddKeyRow

local AddKeyInputCorner = Instance.new("UICorner")
AddKeyInputCorner.CornerRadius = UDim.new(0, 8)
AddKeyInputCorner.Parent = AddKeyInput

local AddTapBtn = CreatePlasmiiButton("+Tap", 0.16, 0.46)
AddTapBtn.Parent = AddKeyRow

local AddDownBtn = CreatePlasmiiButton("+Down", 0.17, 0.64)
AddDownBtn.Parent = AddKeyRow

local AddUpBtn = CreatePlasmiiButton("+Up", 0.16, 0.83)
AddUpBtn.Parent = AddKeyRow

-- 6. Add Wait Delay Row
local AddWaitRow = CreatePlasmiiRow(30)
AddWaitRow.Name = "Row_AddWait"
AddWaitRow.LayoutOrder = 7
AddWaitRow.Parent = Container

local AddWaitLabel = CreatePlasmiiLabel("Delay (sec)", 0.4)
AddWaitLabel.Parent = AddWaitRow

local AddWaitInput = Instance.new("TextBox")
AddWaitInput.Size = UDim2.new(0.28, 0, 1, 0)
AddWaitInput.Position = UDim2.new(0.42, 0, 0, 0)
AddWaitInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AddWaitInput.BackgroundTransparency = 0.95
AddWaitInput.Font = Enum.Font.RobotoMono
AddWaitInput.TextSize = 13
AddWaitInput.TextColor3 = Color3.fromRGB(255, 255, 255)
AddWaitInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
AddWaitInput.PlaceholderText = "0.1"
AddWaitInput.Text = "0.1"
AddWaitInput.ClearTextOnFocus = false
AddWaitInput.Parent = AddWaitRow

local AddWaitInputCorner = Instance.new("UICorner")
AddWaitInputCorner.CornerRadius = UDim.new(0, 8)
AddWaitInputCorner.Parent = AddWaitInput

local AddWaitBtn = CreatePlasmiiButton("+ Add", 0.28, 0.72)
AddWaitBtn.Parent = AddWaitRow

-- 7. Add Mouse Left Row
local AddMouseLRow = CreatePlasmiiRow(30)
AddMouseLRow.Name = "Row_AddMouseL"
AddMouseLRow.LayoutOrder = 8
AddMouseLRow.Parent = Container

local AddMouseLLabel = CreatePlasmiiLabel("Mouse Left", 0.28)
AddMouseLLabel.Parent = AddMouseLRow

local AddLClickBtn = CreatePlasmiiButton("+Click", 0.22, 0.30)
AddLClickBtn.Parent = AddMouseLRow

local AddLDownBtn = CreatePlasmiiButton("+Down", 0.22, 0.54)
AddLDownBtn.Parent = AddMouseLRow

local AddLUpBtn = CreatePlasmiiButton("+Up", 0.20, 0.78)
AddLUpBtn.Parent = AddMouseLRow

-- 8. Add Mouse Right Row
local AddMouseRRow = CreatePlasmiiRow(30)
AddMouseRRow.Name = "Row_AddMouseR"
AddMouseRRow.LayoutOrder = 9
AddMouseRRow.Parent = Container

local AddMouseRLabel = CreatePlasmiiLabel("Mouse Right", 0.28)
AddMouseRLabel.Parent = AddMouseRRow

local AddRClickBtn = CreatePlasmiiButton("+Click", 0.22, 0.30)
AddRClickBtn.Parent = AddMouseRRow

local AddRDownBtn = CreatePlasmiiButton("+Down", 0.22, 0.54)
AddRDownBtn.Parent = AddMouseRRow

local AddRUpBtn = CreatePlasmiiButton("+Up", 0.20, 0.78)
AddRUpBtn.Parent = AddMouseRRow

-- Divider: Sequence Header
local SeqHeaderRow = CreatePlasmiiRow(24)
SeqHeaderRow.Name = "Row_SeqHeader"
SeqHeaderRow.LayoutOrder = 9
SeqHeaderRow.BackgroundTransparency = 1
SeqHeaderRow.Parent = Container

local SeqHeaderLabel = Instance.new("TextLabel")
SeqHeaderLabel.Size = UDim2.new(1, 0, 1, 0)
SeqHeaderLabel.BackgroundTransparency = 1
SeqHeaderLabel.Font = Enum.Font.RobotoMono
SeqHeaderLabel.TextSize = 13
SeqHeaderLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
SeqHeaderLabel.TextXAlignment = Enum.TextXAlignment.Center
SeqHeaderLabel.Text = "-- Action Sequence --"
SeqHeaderLabel.Parent = SeqHeaderRow

-- Container for dynamic sequence rows
local StepsContainer = Instance.new("Frame")
StepsContainer.Name = "StepsContainer"
StepsContainer.Size = UDim2.new(1, 0, 0, 0)
StepsContainer.AutomaticSize = Enum.AutomaticSize.Y
StepsContainer.BackgroundTransparency = 1
StepsContainer.LayoutOrder = 10
StepsContainer.Parent = Container

local StepsLayout = Instance.new("UIListLayout")
StepsLayout.Padding = UDim.new(0, 4)
StepsLayout.SortOrder = Enum.SortOrder.LayoutOrder
StepsLayout.Parent = StepsContainer

-- Divider: Action Footer
local FooterRow1 = CreatePlasmiiRow(30)
FooterRow1.Name = "Row_Footer1"
FooterRow1.LayoutOrder = 20
FooterRow1.BackgroundTransparency = 1
FooterRow1.Parent = Container

local TestBtn = CreatePlasmiiButton("Test Run", 0.48, 0)
TestBtn.Parent = FooterRow1

local ClearStepsBtn = CreatePlasmiiButton("Clear Steps", 0.48, 0.52)
ClearStepsBtn.Parent = FooterRow1

local FooterRow2 = CreatePlasmiiRow(30)
FooterRow2.Name = "Row_Footer2"
FooterRow2.LayoutOrder = 21
FooterRow2.BackgroundTransparency = 1
FooterRow2.Parent = Container

local NewMacroBtn = CreatePlasmiiButton("+ New Macro", 0.48, 0)
NewMacroBtn.Parent = FooterRow2

local DeleteMacroBtn = CreatePlasmiiButton("Delete Macro", 0.48, 0.52)
DeleteMacroBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
DeleteMacroBtn.Parent = FooterRow2

-- ============================================================================
-- Section 6: UI Controller & Reactive Rendering
-- ============================================================================
local RenderUI

local function GetCurrentMacro()
    return State.Macros[State.SelectedMacroIndex]
end

RenderUI = function()
    local current = GetCurrentMacro()
    if not current then return end

    -- Update Top Row Values
    MacroIndexDisplay.Text = string.format("%d / %d", State.SelectedMacroIndex, #State.Macros)
    NameInput.Text = current.Name or ""
    TriggerBtn.Text = State.ListeningForTrigger and "press key..." or string.format("[ %s ]", current.Trigger or "None")
    StatusBtn.Text = current.Enabled and "Enabled" or "Disabled"
    StatusBtn.TextColor3 = current.Enabled and Color3.fromRGB(90, 240, 130) or Color3.fromRGB(160, 160, 160)

    -- Clear & Rebuild Dynamic Steps
    for _, child in ipairs(StepsContainer:GetChildren()) do
        if child:IsA("GuiObject") and child.Name:find("StepRow_") then
            child:Destroy()
        end
    end

    for i, step in ipairs(current.Steps) do
        local row = CreatePlasmiiRow(28)
        row.Name = "StepRow_" .. i
        row.LayoutOrder = i
        row.Parent = StepsContainer

        local descText = ""
        if step.Type == "Key" then
            descText = string.format("%d. Tap [%s]", i, tostring(step.Value))
        elseif step.Type == "KeyDown" then
            descText = string.format("%d. Key Down [%s]", i, tostring(step.Value))
        elseif step.Type == "KeyUp" then
            descText = string.format("%d. Key Up [%s]", i, tostring(step.Value))
        elseif step.Type == "Wait" then
            descText = string.format("%d. Wait [%s s]", i, tostring(step.Value))
        elseif step.Type == "Click" then
            descText = string.format("%d. %s Click", i, tostring(step.Value))
        elseif step.Type == "MouseDown" then
            descText = string.format("%d. %s Mouse Down", i, tostring(step.Value))
        elseif step.Type == "MouseUp" then
            descText = string.format("%d. %s Mouse Up", i, tostring(step.Value))
        end

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, -34, 1, 0)
        descLbl.Position = UDim2.new(0, 8, 0, 0)
        descLbl.BackgroundTransparency = 1
        descLbl.Font = Enum.Font.RobotoMono
        descLbl.TextSize = 13
        descLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Text = descText
        descLbl.Parent = row

        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, 24, 0, 24)
        delBtn.Position = UDim2.new(1, -26, 0.5, -12)
        delBtn.BackgroundTransparency = 1
        delBtn.Font = Enum.Font.RobotoCondensed
        delBtn.TextSize = 16
        delBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
        delBtn.Text = "X"
        delBtn.Parent = row

        delBtn.Activated:Connect(function()
            table.remove(current.Steps, i)
            SaveMacros()
            RenderUI()
        end)
    end
end

-- Hook Events
MacroPrevBtn.Activated:Connect(function()
    if State.SelectedMacroIndex > 1 then
        State.SelectedMacroIndex = State.SelectedMacroIndex - 1
        RenderUI()
    end
end)

MacroNextBtn.Activated:Connect(function()
    if State.SelectedMacroIndex < #State.Macros then
        State.SelectedMacroIndex = State.SelectedMacroIndex + 1
        RenderUI()
    end
end)

NameInput.FocusLost:Connect(function()
    local current = GetCurrentMacro()
    if current and NameInput.Text ~= "" then
        current.Name = NameInput.Text
        SaveMacros()
        RenderUI()
    end
end)

TriggerBtn.Activated:Connect(function()
    State.ListeningForTrigger = true
    TriggerBtn.Text = "press key..."
end)

Own(UserInputService.InputBegan:Connect(function(input)
    if State.ListeningForTrigger and input.UserInputType == Enum.UserInputType.Keyboard then
        local current = GetCurrentMacro()
        if current then
            current.Trigger = input.KeyCode.Name
            State.ListeningForTrigger = false
            SaveMacros()
            RenderUI()
        end
    end
end))

StatusBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    if current then
        current.Enabled = not current.Enabled
        SaveMacros()
        RenderUI()
    end
end)

AddTapBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    local val = AddKeyInput.Text
    if current and val and val ~= "" then
        table.insert(current.Steps, { Type = "Key", Value = val })
        SaveMacros()
        RenderUI()
    end
end)

AddDownBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    local val = AddKeyInput.Text
    if current and val and val ~= "" then
        table.insert(current.Steps, { Type = "KeyDown", Value = val })
        SaveMacros()
        RenderUI()
    end
end)

AddUpBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    local val = AddKeyInput.Text
    if current and val and val ~= "" then
        table.insert(current.Steps, { Type = "KeyUp", Value = val })
        SaveMacros()
        RenderUI()
    end
end)

AddWaitBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    local val = tonumber(AddWaitInput.Text) or 0.1
    if current then
        table.insert(current.Steps, { Type = "Wait", Value = val })
        SaveMacros()
        RenderUI()
    end
end)

AddLClickBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    if current then
        table.insert(current.Steps, { Type = "Click", Value = "Left" })
        SaveMacros()
        RenderUI()
    end
end)

AddLDownBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    if current then
        table.insert(current.Steps, { Type = "MouseDown", Value = "Left" })
        SaveMacros()
        RenderUI()
    end
end)

AddLUpBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    if current then
        table.insert(current.Steps, { Type = "MouseUp", Value = "Left" })
        SaveMacros()
        RenderUI()
    end
end)

AddRClickBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    if current then
        table.insert(current.Steps, { Type = "Click", Value = "Right" })
        SaveMacros()
        RenderUI()
    end
end)

AddRDownBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    if current then
        table.insert(current.Steps, { Type = "MouseDown", Value = "Right" })
        SaveMacros()
        RenderUI()
    end
end)

AddRUpBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    if current then
        table.insert(current.Steps, { Type = "MouseUp", Value = "Right" })
        SaveMacros()
        RenderUI()
    end
end)

TestBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    if current then
        ExecuteMacro(current)
    end
end)

ClearStepsBtn.Activated:Connect(function()
    local current = GetCurrentMacro()
    if current then
        table.clear(current.Steps)
        SaveMacros()
        RenderUI()
    end
end)

NewMacroBtn.Activated:Connect(function()
    local newIndex = #State.Macros + 1
    table.insert(State.Macros, {
        Name = "Macro " .. newIndex,
        Enabled = true,
        Trigger = "None",
        Steps = {}
    })
    State.SelectedMacroIndex = newIndex
    SaveMacros()
    RenderUI()
end)

DeleteMacroBtn.Activated:Connect(function()
    if #State.Macros <= 1 then
        local current = GetCurrentMacro()
        if current then
            table.clear(current.Steps)
            SaveMacros()
            RenderUI()
        end
        return
    end
    table.remove(State.Macros, State.SelectedMacroIndex)
    State.SelectedMacroIndex = math.clamp(State.SelectedMacroIndex, 1, #State.Macros)
    SaveMacros()
    RenderUI()
end)

local function SetUIVisible(visible)
    State.UIVisible = visible
    Window.Visible = visible
    if visible then
        RenderUI()
    else
        State.ListeningForTrigger = false
    end
end

Exit.Activated:Connect(function()
    SetUIVisible(false)
end)

-- Initial Render
RenderUI()

-- ============================================================================
-- Section 7: Plasmii Command System Integration
-- ============================================================================
local function RegisterPlasmiiCommands()
    local plasmii = getgenv().Plasmii or _G.Plasmii or shared.Plasmii or rawget(_G, "Plasmii")
    if not (plasmii and plasmii.CmdSys and plasmii.CmdSys.AddCmd) then
        return false
    end

    local AddCmd = plasmii.CmdSys.AddCmd

    AddCmd("hotkeys", "Opens the Hotkey & Combo Macro Builder GUI.", "hotkeys", function()
        SetUIVisible(not State.UIVisible)
    end, true)

    AddCmd("macro", "Controls the Hotkey Macro system.", "macro [on/off/gui]", function(arg)
        if arg then
            local lower = string.lower(arg)
            if lower == "on" or lower == "true" or lower == "enable" then
                State.Enabled = true
                print("[HotkeyBuilder]: Macro system ENABLED")
            elseif lower == "off" or lower == "false" or lower == "disable" then
                State.Enabled = false
                print("[HotkeyBuilder]: Macro system DISABLED")
            elseif lower == "gui" or lower == "ui" then
                SetUIVisible(not State.UIVisible)
            else
                SetUIVisible(not State.UIVisible)
            end
        else
            SetUIVisible(not State.UIVisible)
        end
    end, true)

    print("[HotkeyBuilder]: Successfully registered Plasmii commands (;hotkeys, ;macro)!")
    return true
end

if not RegisterPlasmiiCommands() then
    task.spawn(function()
        for _ = 1, 30 do
            task.wait(1)
            if RegisterPlasmiiCommands() then break end
        end
    end)
end

-- ============================================================================
-- Section 8: Export & Teardown
-- ============================================================================
local function Cleanup()
    ReleaseAllHeldKeys()
    ReleaseAllHeldMouseButtons()
    for i = #Janitor, 1, -1 do
        local x = Janitor[i]
        if typeof(x) == "RBXScriptConnection" then
            x:Disconnect()
        elseif typeof(x) == "Instance" then
            pcall(x.Destroy, x)
        end
        Janitor[i] = nil
    end
    print("[HotkeyBuilder]: Cleaned up successfully.")
end

if genv then
    genv.__HotkeyBuilderCleanup = Cleanup
    genv.HotkeyBuilder = {
        Open = function() SetUIVisible(true) end,
        Close = function() SetUIVisible(false) end,
        Toggle = function() SetUIVisible(not State.UIVisible) end,
        Execute = ExecuteMacro,
        State = State,
        Cleanup = Cleanup,
    }
end

print("[HotkeyBuilder]: Initialized Plasmii-Native UI! Type ';hotkeys' to open.")

return {
    Open = function() SetUIVisible(true) end,
    Close = function() SetUIVisible(false) end,
    Toggle = function() SetUIVisible(not State.UIVisible) end,
    Execute = ExecuteMacro,
    State = State,
    Cleanup = Cleanup,
}
