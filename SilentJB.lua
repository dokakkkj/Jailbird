--[[
    SexHUB - Silent Aim + Highlight ESP + TPWalk
    Script integrado à Biblioteca Obsidian
    Com FOV fixo no centro da tela
    ESP simplificado: sem distância e sem cores de texto
    TPWalk sem predefinições
]]

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- ========================== CONFIGURAÇÕES DO SILENT AIM ==========================
local ConfigSA = {
    TargetPart = "Head",
    MaxFOV = 300,
    TeamCheck = true,
    VisibleCheck = false,
    MaxDistance = 700,
    DrawFOV = true,
    Enabled = false,
}

-- ========================== CONFIGURAÇÕES DO ESP (SIMPLIFICADO) ==========================
local ConfigESP = {
    -- Cores do Highlight
    FillColor = Color3.fromRGB(175, 25, 255),
    DepthMode = "AlwaysOnTop",
    FillTransparency = 0.5,
    OutlineColor = Color3.fromRGB(255, 255, 255),
    OutlineTransparency = 0,
    
    -- Opções de visibilidade
    ShowName = true,
    ShowHealth = true,
    ShowESP = true,
    TeamCheckESP = true,
    
    -- Configurações do nome (fixo, sem opção de cor)
    NameSize = 9,
    FontName = Enum.Font.GothamBold,
    NameColor = Color3.fromRGB(255, 255, 255),
}

-- ========================== CONFIGURAÇÕES DO TPWALK ==========================
local ConfigTP = {
    Enabled = false,
    Speed = 1.0,
    MinSpeed = 0.1,
    MaxSpeed = 25,
    Keybind = Enum.KeyCode.Q,
}

-- ========================== VARIÁVEIS GLOBAIS ==========================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

-- ========================== VARIÁVEIS DO ESP ==========================
local Storage = Instance.new("Folder")
Storage.Name = "ESP_Storage"
Storage.Parent = CoreGui
local espData = {}
local lp = LocalPlayer

-- ========================== VARIÁVEIS DO TPWALK ==========================
local tpwalking = false
local tpConnection = nil

-- ========================== FUNÇÕES DO ESP (SIMPLIFICADO) ==========================
local function ShouldShowESP(player)
    if player == lp then return false end
    if not ConfigESP.ShowESP then return false end
    if ConfigESP.TeamCheckESP and lp.Team and player.Team and lp.Team == player.Team then
        return false
    end
    return true
end

local function CreateESP(player)
    if not ShouldShowESP(player) then
        if espData[player] then
            RemoveESP(player)
        end
        return
    end
    
    local oldESP = Storage:FindFirstChild(player.Name)
    if oldESP then oldESP:Destroy() end
    
    if espData[player] then
        if espData[player].Highlight then espData[player].Highlight:Destroy() end
        if espData[player].Billboard then espData[player].Billboard:Destroy() end
        if espData[player].CharConnection then espData[player].CharConnection:Disconnect() end
        espData[player] = nil
    end
    
    -- Criar Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = player.Name
    highlight.FillColor = ConfigESP.FillColor
    highlight.DepthMode = ConfigESP.DepthMode
    highlight.FillTransparency = ConfigESP.FillTransparency
    highlight.OutlineColor = ConfigESP.OutlineColor
    highlight.OutlineTransparency = ConfigESP.OutlineTransparency
    highlight.Parent = Storage
    if player.Character then highlight.Adornee = player.Character end
    
    -- Criar Billboard (apenas nome e vida)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = player.Name .. "_Billboard"
    billboard.Size = UDim2.new(0, 120, 0, 25)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = Storage
    if player.Character then billboard.Adornee = player.Character end
    
    local labels = {}
    
    -- Nome (cor fixa branca)
    if ConfigESP.ShowName then
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, -6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = ConfigESP.NameSize
        nameLabel.Font = ConfigESP.FontName
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Parent = billboard
        labels.Name = nameLabel
    end
    
    -- Vida (sem opção de cores, apenas texto branco)
    if ConfigESP.ShowHealth then
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
        healthLabel.Position = UDim2.new(0, 0, 0.5, -6)
        healthLabel.BackgroundTransparency = 1
        healthLabel.Text = "[100%]"
        healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        healthLabel.TextSize = 9
        healthLabel.Font = Enum.Font.Gotham
        healthLabel.TextStrokeTransparency = 0.3
        healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        healthLabel.Parent = billboard
        labels.Health = healthLabel
    end
    
    -- Função para atualizar vida (apenas texto, sem cores)
    local function UpdateHealth()
        if not ConfigESP.ShowHealth then return end
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") and labels.Health then
            local humanoid = char.Humanoid
            local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
            labels.Health.Text = "[" .. healthPercent .. "%]"
        end
    end
    
    -- Conexão para quando o personagem spawnar
    local charConn = player.CharacterAdded:Connect(function(char)
        if not ShouldShowESP(player) then
            RemoveESP(player)
            return
        end
        highlight.Adornee = char
        billboard.Adornee = char
        task.wait(0.5)
        UpdateHealth()
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.HealthChanged:Connect(UpdateHealth)
        end
    end)
    
    if player.Character then
        task.wait(0.5)
        UpdateHealth()
        if player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.HealthChanged:Connect(UpdateHealth)
        end
    end
    
    espData[player] = {
        Highlight = highlight,
        Billboard = billboard,
        Labels = labels,
        CharConnection = charConn,
    }
end

local function RemoveESP(player)
    if espData[player] then
        if espData[player].Highlight then espData[player].Highlight:Destroy() end
        if espData[player].Billboard then espData[player].Billboard:Destroy() end
        if espData[player].CharConnection then espData[player].CharConnection:Disconnect() end
        espData[player] = nil
    end
    local oldESP = Storage:FindFirstChild(player.Name)
    if oldESP then oldESP:Destroy() end
    local oldBillboard = Storage:FindFirstChild(player.Name .. "_Billboard")
    if oldBillboard then oldBillboard:Destroy() end
end

-- Eventos de jogadores para ESP
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ShouldShowESP(player) then
            CreateESP(player)
        else
            RemoveESP(player)
        end
    end)
    task.wait(0.5)
    if ShouldShowESP(player) then
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

task.spawn(function()
    while task.wait(2) do
        for _, player in ipairs(Players:GetPlayers()) do
            if ShouldShowESP(player) then
                if not espData[player] then
                    CreateESP(player)
                end
            else
                if espData[player] then
                    RemoveESP(player)
                end
            end
        end
    end
end)

-- ========================== SILENT AIM ==========================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 100
FOVCircle.Radius = ConfigSA.MaxFOV
FOVCircle.Color = Color3.fromRGB(255, 0, 100)
FOVCircle.Transparency = 0.75
FOVCircle.Visible = ConfigSA.DrawFOV
FOVCircle.Filled = false

local function UpdateFOVPosition()
    local viewportSize = Camera.ViewportSize
    FOVCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
end

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateFOVPosition)

RunService.RenderStepped:Connect(function()
    UpdateFOVPosition()
    FOVCircle.Visible = ConfigSA.DrawFOV and ConfigSA.Enabled
end)

local function GetClosestTarget()
    if not ConfigSA.Enabled then return nil end
    
    local viewportSize = Camera.ViewportSize
    local centerPos = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local closest, shortest = nil, ConfigSA.MaxFOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        if ConfigSA.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local char = player.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        
        local targetPart = char:FindFirstChild(ConfigSA.TargetPart) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end
        
        local distance = (Camera.CFrame.Position - targetPart.Position).Magnitude
        if distance > ConfigSA.MaxDistance then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end
        
        if ConfigSA.VisibleCheck then
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
            local ray = Workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * distance, rayParams)
            if ray and ray.Instance:IsDescendantOf(char) == false then
                continue
            end
        end
        
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude
        if dist < shortest then
            shortest = dist
            closest = targetPart
        end
    end
    return closest
end

local OldBulletRayCast = nil
local OldKnifeRayCast = nil

local function Redirect(origin, direction, distance, ignoreList, isKnife)
    local target = GetClosestTarget()
    if target then
        local newDirection = (target.Position - origin).Unit
        if isKnife then
            return OldKnifeRayCast(origin, newDirection, distance, ignoreList)
        else
            return OldBulletRayCast(origin, newDirection, distance, ignoreList)
        end
    end
    if isKnife then
        return OldKnifeRayCast(origin, direction, distance, ignoreList)
    else
        return OldBulletRayCast(origin, direction, distance, ignoreList)
    end
end

local function ForceHook()
    for _, v in ipairs(getgc(true)) do
        if typeof(v) == "table" and rawget(v, "BulletRayCast") and rawget(v, "KnifeRayCast") then
            if not OldBulletRayCast then
                OldBulletRayCast = v.BulletRayCast
                OldKnifeRayCast = v.KnifeRayCast
                v.BulletRayCast = function(a, b, c, d)
                    return Redirect(a, b, c, d, false)
                end
                v.KnifeRayCast = function(a, b, c, d)
                    return Redirect(a, b, c, d, true)
                end
                return true
            end
        end
    end
    return false
end

task.spawn(function()
    local tries = 0
    while tries < 25 and not OldBulletRayCast do
        if ForceHook() then
            print("Silent Aim: Hook aplicado com sucesso!")
            break
        end
        tries += 1
        task.wait(0.6)
    end
    if not OldBulletRayCast then
        warn("Silent Aim: Não foi possível aplicar o hook.")
    end
end)

-- ========================== FUNÇÕES DO TPWALK ==========================
local function StartTPWalk()
    if tpwalking then return end
    
    local chr = LocalPlayer.Character
    local hum = chr and chr:FindFirstChildOfClass("Humanoid")
    if not chr or not hum then return end
    
    tpwalking = true
    ConfigTP.Enabled = true
    
    tpConnection = RunService.Heartbeat:Connect(function(delta)
        if not tpwalking then
            tpConnection:Disconnect()
            tpConnection = nil
            return
        end
        
        local chr = LocalPlayer.Character
        local hum = chr and chr:FindFirstChildOfClass("Humanoid")
        if not chr or not hum or hum.Health <= 0 then
            tpwalking = false
            ConfigTP.Enabled = false
            if tpConnection then
                tpConnection:Disconnect()
                tpConnection = nil
            end
            return
        end
        
        if hum.MoveDirection.Magnitude > 0 then
            chr:TranslateBy(hum.MoveDirection * ConfigTP.Speed * delta * 10)
        end
    end)
end

local function StopTPWalk()
    tpwalking = false
    ConfigTP.Enabled = false
    if tpConnection then
        tpConnection:Disconnect()
        tpConnection = nil
    end
end

local function ToggleTPWalk()
    if tpwalking then
        StopTPWalk()
    else
        StartTPWalk()
    end
end

-- Reset ao respawnar
LocalPlayer.CharacterAdded:Connect(function()
    if tpwalking then
        StopTPWalk()
    end
end)

-- Keybind do TPWalk
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == ConfigTP.Keybind then
        ToggleTPWalk()
    end
end)

-- ========================== CRIAÇÃO DA INTERFACE OBSIDIAN ==========================
local Window = Library:CreateWindow({
    Title = "SexHUB",
    Footer = "By Doka",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- ========================== GUIAS ==========================
local Tabs = {
    ["Silent-Aim"] = Window:AddTab("Silent-Aim", "crosshair"), -- Nome alterado
    ESP = Window:AddTab("ESP", "eye"),
    TPWalk = Window:AddTab("TPWalk", "zap"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- ========================== ABA SILENT-AIM ==========================
local MainGroup = Tabs["Silent-Aim"]:AddLeftGroupbox("Configurações do Silent Aim")

MainGroup:AddToggle("SilentAimToggle", {
    Text = "Ativar Silent Aim",
    Default = false,
    Tooltip = "Liga ou desliga o Silent Aim.",
    Callback = function(Value)
        ConfigSA.Enabled = Value
        print("[Silent Aim] Estado:", Value)
    end,
})

MainGroup:AddDropdown("TargetPartDropdown", {
    Text = "Parte do Corpo",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
    Default = "Head",
    Tooltip = "Parte do corpo que será mirada.",
    Callback = function(Value)
        ConfigSA.TargetPart = Value
    end,
})

MainGroup:AddSlider("FOVSlider", {
    Text = "Campo de Visão (FOV)",
    Default = 300,
    Min = 50,
    Max = 800,
    Rounding = 0,
    Suffix = "px",
    Tooltip = "Raio do círculo de mira (fixo no centro da tela).",
    Callback = function(Value)
        ConfigSA.MaxFOV = Value
        FOVCircle.Radius = Value
    end,
})

MainGroup:AddSlider("DistanceSlider", {
    Text = "Distância Máxima",
    Default = 700,
    Min = 100,
    Max = 2000,
    Rounding = 0,
    Suffix = "estuds",
    Tooltip = "Distância máxima para considerar um alvo.",
    Callback = function(Value)
        ConfigSA.MaxDistance = Value
    end,
})

MainGroup:AddToggle("TeamCheckToggle", {
    Text = "Verificar Time (Silent Aim)",
    Default = true,
    Tooltip = "Se ativado, não mirará em membros do seu time.",
    Callback = function(Value)
        ConfigSA.TeamCheck = Value
    end,
})

MainGroup:AddToggle("VisibleCheckToggle", {
    Text = "Verificar Visibilidade (Wallcheck)",
    Default = false,
    Tooltip = "Se ativado, só mirará em alvos visíveis.",
    Callback = function(Value)
        ConfigSA.VisibleCheck = Value
    end,
})

MainGroup:AddToggle("DrawFOVToggle", {
    Text = "Desenhar Círculo FOV",
    Default = true,
    Tooltip = "Mostra ou esconde o círculo de FOV no centro da tela.",
    Callback = function(Value)
        ConfigSA.DrawFOV = Value
        FOVCircle.Visible = Value and ConfigSA.Enabled
    end,
})

MainGroup:AddDivider()
MainGroup:AddLabel("Cor do Círculo FOV"):AddColorPicker("FOVColorPicker", {
    Default = Color3.fromRGB(255, 0, 100),
    Title = "Selecione a Cor do FOV",
    Callback = function(Value)
        FOVCircle.Color = Value
    end,
})

-- ========================== ABA ESP (SIMPLIFICADO) ==========================
local ESPGroup = Tabs.ESP:AddLeftGroupbox("Configurações do ESP")

-- Toggle geral
ESPGroup:AddToggle("ESPToggle", {
    Text = "Ativar ESP",
    Default = true,
    Tooltip = "Liga ou desliga todo o ESP.",
    Callback = function(Value)
        ConfigESP.ShowESP = Value
        if not Value then
            for player, _ in pairs(espData) do
                RemoveESP(player)
            end
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= lp then
                    CreateESP(player)
                end
            end
        end
    end,
})

-- Ocultar time
ESPGroup:AddToggle("TeamCheckESP", {
    Text = "Ocultar Jogadores do Time",
    Default = true,
    Tooltip = "Remove completamente o ESP dos jogadores do seu time.",
    Callback = function(Value)
        ConfigESP.TeamCheckESP = Value
        for player, _ in pairs(espData) do
            if ShouldShowESP(player) then
                CreateESP(player)
            else
                RemoveESP(player)
            end
        end
    end,
})

-- Informações
ESPGroup:AddDivider()
ESPGroup:AddLabel("Informações")

ESPGroup:AddToggle("ShowNameToggle", {
    Text = "Mostrar Nome",
    Default = true,
    Tooltip = "Mostra o nome do jogador acima do personagem.",
    Callback = function(Value)
        ConfigESP.ShowName = Value
        for player, data in pairs(espData) do
            if data.Labels and data.Labels.Name then
                data.Labels.Name.Visible = Value
            end
        end
    end,
})

ESPGroup:AddToggle("ShowHealthToggle", {
    Text = "Mostrar Vida",
    Default = true,
    Tooltip = "Mostra a porcentagem de vida do jogador.",
    Callback = function(Value)
        ConfigESP.ShowHealth = Value
        for player, data in pairs(espData) do
            if data.Labels and data.Labels.Health then
                data.Labels.Health.Visible = Value
            end
        end
    end,
})

-- Cores do Highlight
ESPGroup:AddDivider()
ESPGroup:AddLabel("Cores do Highlight")

ESPGroup:AddLabel("Cor de Preenchimento"):AddColorPicker("FillColorPicker", {
    Default = Color3.fromRGB(175, 25, 255),
    Title = "Cor do Highlight",
    Callback = function(Value)
        ConfigESP.FillColor = Value
        for player, data in pairs(espData) do
            if data.Highlight then
                data.Highlight.FillColor = Value
            end
        end
    end,
})

ESPGroup:AddLabel("Cor do Contorno"):AddColorPicker("OutlineColorPicker", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Cor do Contorno",
    Callback = function(Value)
        ConfigESP.OutlineColor = Value
        for player, data in pairs(espData) do
            if data.Highlight then
                data.Highlight.OutlineColor = Value
            end
        end
    end,
})

ESPGroup:AddSlider("OutlineTransparencySlider", {
    Text = "Transparência do Contorno",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Tooltip = "Transparência do contorno do highlight. 0 = opaco, 1 = invisível.",
    Callback = function(Value)
        ConfigESP.OutlineTransparency = Value
        for player, data in pairs(espData) do
            if data.Highlight then
                data.Highlight.OutlineTransparency = Value
            end
        end
    end,
})

ESPGroup:AddSlider("FillTransparencySlider", {
    Text = "Transparência do Preenchimento",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Tooltip = "Transparência do preenchimento do highlight.",
    Callback = function(Value)
        ConfigESP.FillTransparency = Value
        for player, data in pairs(espData) do
            if data.Highlight then
                data.Highlight.FillTransparency = Value
            end
        end
    end,
})

-- ========================== ABA TPWALK (SEM PREDEFINIÇÕES) ==========================
local TPGroup = Tabs.TPWalk:AddLeftGroupbox("Configurações do TPWalk")

-- Toggle principal
TPGroup:AddToggle("TPWalkToggle", {
    Text = "Ativar TPWalk",
    Default = false,
    Tooltip = "Liga ou desliga o TPWalk. Você também pode usar a tecla de atalho.",
    Callback = function(Value)
        if Value then
            StartTPWalk()
        else
            StopTPWalk()
        end
        ConfigTP.Enabled = Value
    end,
})

-- Slider de velocidade
TPGroup:AddSlider("SpeedSlider", {
    Text = "Velocidade",
    Default = 1.0,
    Min = 0.1,
    Max = 25,
    Rounding = 2,
    Suffix = "x",
    Tooltip = "Velocidade do TPWalk. Valores mais altos = mais rápido.",
    Callback = function(Value)
        ConfigTP.Speed = Value
        print("[TPWalk] Velocidade:", Value)
    end,
})

-- Keybind
TPGroup:AddDivider()
TPGroup:AddLabel("Tecla de Atalho"):AddKeyPicker("TPKeybind", {
    Default = "Q",
    Mode = "Toggle",
    Text = "Tecla para ativar/desativar TPWalk",
    NoUI = false,
    Callback = function(Value)
        if Value then
            ToggleTPWalk()
            Options.TPWalkToggle:SetValue(tpwalking)
        end
    end,
    ChangedCallback = function(NewKey, NewModifiers)
        if type(NewKey) == "string" then
            for _, enum in pairs(Enum.KeyCode:GetEnumItems()) do
                if enum.Name == NewKey then
                    ConfigTP.Keybind = enum
                    break
                end
            end
        elseif typeof(NewKey) == "EnumItem" then
            ConfigTP.Keybind = NewKey
        end
        print("[TPWalk] Keybind alterado para:", tostring(ConfigTP.Keybind))
    end,
})

-- Status atual
TPGroup:AddDivider()
local StatusLabel = TPGroup:AddLabel("Status: Desativado")

task.spawn(function()
    while task.wait(0.5) do
        if tpwalking then
            StatusLabel:SetText("Status: Ativado (Velocidade: " .. string.format("%.2f", ConfigTP.Speed) .. "x)")
        else
            StatusLabel:SetText("Status: Desativado")
        end
    end
end)

-- ========================== CONFIGURAÇÕES DA UI ==========================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Abrir Menu de Teclas",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Cursor Personalizado",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddButton("Descarregar Script", function()
    for player, _ in pairs(espData) do
        RemoveESP(player)
    end
    Storage:Destroy()
    StopTPWalk()
    Library:Unload()
end)

-- Sistemas de tema e salvamento
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()

ThemeManager:SetFolder("SexHUB")
SaveManager:SetFolder("SexHUB")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

MenuGroup:AddLabel("Tecla do Menu"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Tecla para abrir/fechar o menu",
})
Library.ToggleKeybind = Options.MenuKeybind

SaveManager:LoadAutoloadConfig()

print("SexHUB carregado! Abas: Silent-Aim, ESP e TPWalk")
print("ESP simplificado: sem distância e sem cores de texto")
print("TPWalk: Pressione " .. tostring(ConfigTP.Keybind) .. " para ativar/desativar")
