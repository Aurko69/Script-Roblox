-- Aurkos Universal Gui (অর্কো স্ক্রিপ্ট) - Standalone Xeno Luau GUI (With Copy Player Dress Button)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local Teams = game:GetService("Teams")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
local FPDH = Workspace.FallenPartsDestroyHeight

local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
if not playerGui then
	warn("[Aurkos] PlayerGui not found")
	return
end

local existingGui = playerGui:FindFirstChild("AurkosUniversalGui")
if existingGui then
	existingGui:Destroy()
end

-- Color Palette for Theme & ESP Pickers
local ColorChoices = {
	{ name = "Purple", color = Color3.fromRGB(138, 98, 224) },
	{ name = "Red", color = Color3.fromRGB(235, 64, 82) },
	{ name = "Green", color = Color3.fromRGB(52, 211, 120) },
	{ name = "Blue", color = Color3.fromRGB(66, 145, 255) },
	{ name = "Cyan", color = Color3.fromRGB(45, 212, 218) },
	{ name = "Amber", color = Color3.fromRGB(245, 175, 50) },
	{ name = "Pink", color = Color3.fromRGB(240, 95, 175) },
	{ name = "White", color = Color3.fromRGB(245, 245, 252) },
}

-- State & Values
local States = {
	Fly = false,
	Noclip = false,
	InfiniteJump = false,
	VehicleFly = false,
	ESP = false,
	NameESP = false,
	BoxESP = false,
	HighlightESP = false,
	HealthESP = false,
	Fullbright = false,
	AntiAFK = false,
	ClickTP = false,
	AntiVoid = false,
	InstantRespawn = false,
	WalkSpeedEnabled = false,
	JumpPowerEnabled = false,
	GravityEnabled = false,
	Spectating = false,
	AutoAntiFling = true,
	FlingLoop = false,
	FlingAll = false,
	AutoFlingNew = false,
	WhiteListEnabled = false,
	BlackListEnabled = false,
	GuiVisible = true,
}

local Values = {
	WalkSpeed = 16,
	JumpPower = 50,
	Gravity = Workspace.Gravity,
	FlySpeed = 60,
	FlyKey = Enum.KeyCode.F,
	ListeningFlyKey = false,
	GuiToggleKey = Enum.KeyCode.K,
	ListeningGuiKey = false,
	VehicleFlySpeed = 60,
	VehicleBoost = 1,
	TimeOfDay = Lighting.ClockTime,
	FOV = Camera and Camera.FieldOfView or 70,
}

local ThemeColors = {
	PresetName = "Purple",
	MainBg = Color3.fromRGB(20, 17, 29),
	PanelBg = Color3.fromRGB(26, 22, 38),
	ItemBg = Color3.fromRGB(34, 29, 48),
	Accent = Color3.fromRGB(138, 98, 224),
	Border = Color3.fromRGB(70, 56, 102),
	Text = Color3.fromRGB(246, 244, 255),
}

local ESPColors = {
	NameColor = Color3.fromRGB(255, 255, 255),
	HealthColor = Color3.fromRGB(0, 255, 0),
	BoxColor = Color3.fromRGB(255, 70, 120),
	HighlightFill = Color3.fromRGB(145, 95, 255),
	HighlightOutline = Color3.fromRGB(255, 255, 255),
}

local WhiteListTeams = {}
local BlackListTeams = {}
local SelectedPlayerName = nil
local SearchQuery = ""
local OldPos = nil
local Character, Humanoid, HumanoidRootPart = nil, nil, nil
local CharacterParts = {}
local FlyBodyGyro, FlyBodyVelocity = nil, nil
local VehicleFlyBodyGyro, VehicleFlyBodyVelocity = nil, nil
local FlingActive = false
local BoxESPDrawings = {}

-- Dynamic UI Registries for Live Theme Updates
local ThemeRegistry = {
	mainFrames = {},
	panelFrames = {},
	itemFrames = {},
	accentFrames = {},
	strokes = {},
	textLabels = {},
	activeTabGetter = nil,
}

local function registerMainFrame(f)
	table.insert(ThemeRegistry.mainFrames, f)
end

local function registerPanelFrame(f)
	table.insert(ThemeRegistry.panelFrames, f)
end

local function registerItemFrame(f)
	table.insert(ThemeRegistry.itemFrames, f)
end

local function registerAccentFrame(f)
	table.insert(ThemeRegistry.accentFrames, f)
end

local function registerStroke(s)
	table.insert(ThemeRegistry.strokes, s)
end

local function registerText(t)
	table.insert(ThemeRegistry.textLabels, t)
end

local function applyTheme()
	for _, f in ipairs(ThemeRegistry.mainFrames) do
		if f and f.Parent then
			f.BackgroundColor3 = ThemeColors.MainBg
		end
	end
	for _, f in ipairs(ThemeRegistry.panelFrames) do
		if f and f.Parent then
			f.BackgroundColor3 = ThemeColors.PanelBg
		end
	end
	for _, f in ipairs(ThemeRegistry.itemFrames) do
		if f and f.Parent then
			f.BackgroundColor3 = ThemeColors.ItemBg
		end
	end
	for _, f in ipairs(ThemeRegistry.accentFrames) do
		if f and f.Parent then
			f.BackgroundColor3 = ThemeColors.Accent
		end
	end
	for _, s in ipairs(ThemeRegistry.strokes) do
		if s and s.Parent then
			s.Color = ThemeColors.Border
		end
	end
	for _, t in ipairs(ThemeRegistry.textLabels) do
		if t and t.Parent and (t:IsA("TextLabel") or t:IsA("TextButton") or t:IsA("TextBox")) then
			t.TextColor3 = ThemeColors.Text
		end
	end
	if ThemeRegistry.activeTabGetter then
		ThemeRegistry.activeTabGetter()
	end
end

local function applyThemePreset(choice)
	ThemeColors.PresetName = choice.name
	ThemeColors.Accent = choice.color
	ThemeColors.Border = choice.color:Lerp(Color3.fromRGB(35, 30, 50), 0.45)
	ThemeColors.MainBg = Color3.fromRGB(16, 15, 22):Lerp(choice.color, 0.06)
	ThemeColors.PanelBg = Color3.fromRGB(24, 22, 32):Lerp(choice.color, 0.08)
	ThemeColors.ItemBg = Color3.fromRGB(32, 29, 44):Lerp(choice.color, 0.10)
	applyTheme()
end

-- Drawing API Check (for 2D Box ESP if executor supports it)
local HasDrawing = false
local DrawingLib = nil
pcall(function()
	local env = (getgenv and getgenv()) or _G
	local d = env.Drawing or Drawing
	if d and d.new then
		local test = d.new("Line")
		if test then
			test:Remove()
			DrawingLib = d
			HasDrawing = true
		end
	end
end)

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "AurkosESPFolder"
ESPFolder.Parent = playerGui

-- Character Helpers
local function CacheCharacterParts(char)
	CharacterParts = {}
	if not char then
		return
	end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(CharacterParts, part)
		end
	end
end

local function RefreshCharacter()
	Character = LocalPlayer.Character
	if Character then
		Humanoid = Character:FindFirstChildOfClass("Humanoid")
		HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
		CacheCharacterParts(Character)
		if Humanoid then
			Humanoid.Died:Connect(function()
				if States.InstantRespawn then
					task.wait(0.1)
					LocalPlayer:LoadCharacter()
				end
			end)
			if States.WalkSpeedEnabled then
				Humanoid.WalkSpeed = Values.WalkSpeed
			end
			if States.JumpPowerEnabled then
				Humanoid.UseJumpPower = true
				Humanoid.JumpPower = Values.JumpPower
			end
		end
	else
		Humanoid = nil
		HumanoidRootPart = nil
		CharacterParts = {}
	end
end

RefreshCharacter()

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.1)
	RefreshCharacter()
end)

LocalPlayer.CharacterRemoving:Connect(function()
	Character = nil
	Humanoid = nil
	HumanoidRootPart = nil
	CharacterParts = {}
end)

local function GetSelectedPlayer()
	if not SelectedPlayerName then
		return nil
	end
	local plr = Players:FindFirstChild(SelectedPlayerName)
	if plr and plr ~= LocalPlayer then
		return plr
	end
	return nil
end

local function GetTargetParts(plr)
	if not plr or not plr.Character then
		return nil, nil
	end
	return plr.Character:FindFirstChildOfClass("Humanoid"), plr.Character:FindFirstChild("HumanoidRootPart")
end

-- Copy Selected Player Dress / Appearance
local function CopyPlayerDress()
	local target = GetSelectedPlayer()
	if not target or not target.Character or not Character or not Humanoid then
		return
	end
	pcall(function()
		local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
		local desc = nil
		if targetHum then
			pcall(function()
				desc = targetHum:GetAppliedDescription()
			end)
		end
		if not desc then
			pcall(function()
				desc = Players:GetHumanoidDescriptionFromUserId(target.UserId)
			end)
		end

		if desc then
			pcall(function()
				Humanoid:ApplyDescription(desc)
			end)
		end

		for _, item in ipairs(Character:GetChildren()) do
			if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("Accessory") or item:IsA("BodyColors") then
				pcall(function()
					item:Destroy()
				end)
			end
		end

		for _, item in ipairs(target.Character:GetChildren()) do
			if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("Accessory") or item:IsA("BodyColors") then
				pcall(function()
					local cloned = item:Clone()
					cloned.Parent = Character
				end)
			end
		end

		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end
		CacheCharacterParts(Character)
	end)
end

-- Spectate & Teleport Actions
local SpectateToggleCtrl = nil

local function StopSpectate()
	States.Spectating = false
	if SpectateToggleCtrl then
		SpectateToggleCtrl.setState(false, false)
	end
	Camera = Workspace.CurrentCamera
	if Camera and Humanoid then
		Camera.CameraType = Enum.CameraType.Custom
		Camera.CameraSubject = Humanoid
	end
end

local function SetSpectate(enabled)
	if not enabled then
		StopSpectate()
		return
	end
	local target = GetSelectedPlayer()
	local targetHum = GetTargetParts(target)
	Camera = Workspace.CurrentCamera
	if target and targetHum and Camera then
		States.Spectating = true
		Camera.CameraType = Enum.CameraType.Custom
		Camera.CameraSubject = targetHum
	else
		StopSpectate()
	end
end

local function TeleportToSelected()
	local target = GetSelectedPlayer()
	local _, targetHrp = GetTargetParts(target)
	if targetHrp and HumanoidRootPart then
		HumanoidRootPart.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 4)
	end
end

-- Quick Actions & Character Exploits
local function DoInstantRespawn()
	if not Character then
		return
	end
	if HumanoidRootPart then
		OldPos = HumanoidRootPart.CFrame
	end
	if Humanoid then
		Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
	end
	LocalPlayer:LoadCharacter()
	task.spawn(function()
		local newChar = LocalPlayer.CharacterAdded:Wait()
		local newHrp = newChar:WaitForChild("HumanoidRootPart", 5)
		if newHrp and OldPos then
			task.wait(0.2)
			newHrp.CFrame = OldPos
		end
	end)
end

local function DoFEInvisible()
	if not Character or not HumanoidRootPart then
		return
	end
	pcall(function()
		local clone = Character:Clone()
		clone.Parent = Workspace
		Character:MoveTo(Vector3.new(0, 100000, 0))
		task.wait(0.1)
		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 1
			end
		end
	end)
end

-- Fly & Vehicle Fly
local FlyToggleCtrl = nil

local function StopFlyPhysics()
	if FlyBodyGyro then
		FlyBodyGyro:Destroy()
		FlyBodyGyro = nil
	end
	if FlyBodyVelocity then
		FlyBodyVelocity:Destroy()
		FlyBodyVelocity = nil
	end
	if Humanoid then
		Humanoid.PlatformStand = false
	end
end

local function EnsureFlyPhysics()
	if not HumanoidRootPart then
		return
	end
	if Humanoid then
		Humanoid.PlatformStand = true
	end
	if not FlyBodyGyro or FlyBodyGyro.Parent ~= HumanoidRootPart then
		if FlyBodyGyro then
			FlyBodyGyro:Destroy()
		end
		FlyBodyGyro = Instance.new("BodyGyro")
		FlyBodyGyro.P = 9e4
		FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		FlyBodyGyro.CFrame = HumanoidRootPart.CFrame
		FlyBodyGyro.Parent = HumanoidRootPart
	end
	if not FlyBodyVelocity or FlyBodyVelocity.Parent ~= HumanoidRootPart then
		if FlyBodyVelocity then
			FlyBodyVelocity:Destroy()
		end
		FlyBodyVelocity = Instance.new("BodyVelocity")
		FlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		FlyBodyVelocity.Velocity = Vector3.zero
		FlyBodyVelocity.Parent = HumanoidRootPart
	end
end

local function SetFly(enabled)
	States.Fly = enabled
	if FlyToggleCtrl and FlyToggleCtrl.getState() ~= enabled then
		FlyToggleCtrl.setState(enabled, false)
	end
	if not enabled then
		StopFlyPhysics()
	end
end

local function GetVehicle()
	if not Humanoid or not Humanoid.SeatPart then
		return nil
	end
	local seat = Humanoid.SeatPart
	return seat:FindFirstAncestorWhichIsA("Model") or seat
end

local function ApplyVehicleBoost(multiplier)
	local vehicle = GetVehicle()
	if not vehicle then
		return
	end
	for _, desc in ipairs(vehicle:GetDescendants()) do
		if desc:IsA("VehicleSeat") then
			desc.MaxSpeed = 25 * multiplier
			desc.Torque = 1 * multiplier
		end
	end
end

local function StopVehicleFlyPhysics()
	if VehicleFlyBodyGyro then
		VehicleFlyBodyGyro:Destroy()
		VehicleFlyBodyGyro = nil
	end
	if VehicleFlyBodyVelocity then
		VehicleFlyBodyVelocity:Destroy()
		VehicleFlyBodyVelocity = nil
	end
end

-- Fling Helper
local function FlingPlayer(targetPlr)
	local _, targetHrp = GetTargetParts(targetPlr)
	if not targetHrp or not HumanoidRootPart then
		return
	end
	pcall(function()
		local oldCF = HumanoidRootPart.CFrame
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = Vector3.new(9e5, 9e5, 9e5)
		bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		bv.Parent = HumanoidRootPart

		local bav = Instance.new("BodyAngularVelocity")
		bav.AngularVelocity = Vector3.new(9e5, 9e5, 9e5)
		bav.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		bav.Parent = HumanoidRootPart

		for _ = 1, 20 do
			if not targetHrp or not targetHrp.Parent or not HumanoidRootPart then
				break
			end
			HumanoidRootPart.CFrame = targetHrp.CFrame
			task.wait(0.015)
		end

		bv:Destroy()
		bav:Destroy()
		if HumanoidRootPart then
			HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
			HumanoidRootPart.CFrame = oldCF
		end
	end)
end

local function StartFlingLoop()
	if FlingActive then
		return
	end
	FlingActive = true
	task.spawn(function()
		while FlingActive and (States.FlingLoop or States.FlingAll) do
			if States.FlingAll then
				for _, plr in ipairs(Players:GetPlayers()) do
					if not FlingActive or not States.FlingAll then
						break
					end
					if plr ~= LocalPlayer then
						FlingPlayer(plr)
						task.wait(0.1)
					end
				end
			elseif States.FlingLoop then
				local target = GetSelectedPlayer()
				if target then
					FlingPlayer(target)
				end
			end
			task.wait(0.25)
		end
		FlingActive = false
	end)
end

-- ESP System
local function IsPlayerESPVisible(plr)
	if plr == LocalPlayer then
		return false
	end
	local teamName = plr.Team and plr.Team.Name or "None"
	if States.WhiteListEnabled and not WhiteListTeams[teamName] then
		return false
	end
	if States.BlackListEnabled and BlackListTeams[teamName] then
		return false
	end
	return true
end

local function CreateBoxESP(plr)
	if not HasDrawing or not DrawingLib then
		return nil
	end
	local lines = nil
	pcall(function()
		lines = {
			Top = DrawingLib.new("Line"),
			Bottom = DrawingLib.new("Line"),
			Left = DrawingLib.new("Line"),
			Right = DrawingLib.new("Line"),
			HpBg = DrawingLib.new("Line"),
			HpFg = DrawingLib.new("Line"),
		}
		for _, ln in pairs(lines) do
			ln.Visible = false
			ln.Thickness = 1.5
			ln.Transparency = 1
		end
		lines.HpBg.Color = Color3.fromRGB(25, 25, 25)
		lines.HpBg.Thickness = 3
		lines.HpFg.Thickness = 2
	end)
	return lines
end

local function HideBoxLines(lines)
	if not lines then
		return
	end
	for _, ln in pairs(lines) do
		pcall(function()
			ln.Visible = false
		end)
	end
end

local function CleanupBoxESP(plr)
	local lines = BoxESPDrawings[plr]
	if lines then
		for _, ln in pairs(lines) do
			pcall(function()
				ln:Remove()
			end)
		end
		BoxESPDrawings[plr] = nil
	end
end

local function SyncBoxESPPool()
	if not HasDrawing then
		return
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and not BoxESPDrawings[plr] then
			BoxESPDrawings[plr] = CreateBoxESP(plr)
		end
	end
end

local function UpdateBoxESP()
	Camera = Workspace.CurrentCamera
	if not HasDrawing or not Camera then
		return
	end
	if not States.ESP or not States.BoxESP then
		for _, lines in pairs(BoxESPDrawings) do
			HideBoxLines(lines)
		end
		return
	end
	SyncBoxESPPool()
	for plr, lines in pairs(BoxESPDrawings) do
		local hum, hrp = GetTargetParts(plr)
		if not (hum and hrp and hum.Health > 0 and IsPlayerESPVisible(plr)) then
			HideBoxLines(lines)
			continue
		end
		local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
		if not onScreen then
			HideBoxLines(lines)
			continue
		end
		local dist = math.max((Camera.CFrame.Position - hrp.Position).Magnitude, 1)
		local scale = 1000 / dist
		local w = math.clamp(scale * 1.8, 10, 280)
		local h = math.clamp(scale * 2.8, 16, 420)
		local x = pos.X - w / 2
		local y = pos.Y - h / 2

		pcall(function()
			lines.Top.From = Vector2.new(x, y)
			lines.Top.To = Vector2.new(x + w, y)
			lines.Top.Color = ESPColors.BoxColor
			lines.Top.Visible = true

			lines.Bottom.From = Vector2.new(x, y + h)
			lines.Bottom.To = Vector2.new(x + w, y + h)
			lines.Bottom.Color = ESPColors.BoxColor
			lines.Bottom.Visible = true

			lines.Left.From = Vector2.new(x, y)
			lines.Left.To = Vector2.new(x, y + h)
			lines.Left.Color = ESPColors.BoxColor
			lines.Left.Visible = true

			lines.Right.From = Vector2.new(x + w, y)
			lines.Right.To = Vector2.new(x + w, y + h)
			lines.Right.Color = ESPColors.BoxColor
			lines.Right.Visible = true

			if States.HealthESP then
				local hpRatio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
				local barX = x - 6
				lines.HpBg.From = Vector2.new(barX, y)
				lines.HpBg.To = Vector2.new(barX, y + h)
				lines.HpBg.Visible = true

				lines.HpFg.From = Vector2.new(barX, y + h)
				lines.HpFg.To = Vector2.new(barX, y + h - (h * hpRatio))
				lines.HpFg.Color = ESPColors.HealthColor
				lines.HpFg.Visible = true
			else
				lines.HpBg.Visible = false
				lines.HpFg.Visible = false
			end
		end)
	end
end

local function UpdateESP()
	ESPFolder:ClearAllChildren()
	if not States.ESP then
		UpdateBoxESP()
		return
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if not IsPlayerESPVisible(plr) then
			continue
		end
		local char = plr.Character
		local head = char and char:FindFirstChild("Head")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (char and head and hum and hum.Health > 0) then
			continue
		end

		if States.HighlightESP then
			local hl = Instance.new("Highlight")
			hl.Name = plr.Name .. "_HL"
			hl.Adornee = char
			hl.FillColor = ESPColors.HighlightFill
			hl.OutlineColor = ESPColors.HighlightOutline
			hl.FillTransparency = 0.5
			hl.OutlineTransparency = 0
			hl.Parent = ESPFolder
		end

		if States.NameESP or States.HealthESP then
			local bbg = Instance.new("BillboardGui")
			bbg.Name = plr.Name .. "_ESP"
			bbg.Adornee = head
			bbg.Size = UDim2.new(0, 210, 0, 46)
			bbg.StudsOffset = Vector3.new(0, 2.5, 0)
			bbg.AlwaysOnTop = true

			local list = Instance.new("UIListLayout")
			list.HorizontalAlignment = Enum.HorizontalAlignment.Center
			list.SortOrder = Enum.SortOrder.LayoutOrder
			list.Parent = bbg

			if States.NameESP then
				local nameLbl = Instance.new("TextLabel")
				nameLbl.Size = UDim2.new(1, 0, 0, 20)
				nameLbl.BackgroundTransparency = 1
				nameLbl.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
				nameLbl.TextColor3 = ESPColors.NameColor
				nameLbl.TextSize = 13
				nameLbl.Font = Enum.Font.GothamBold
				nameLbl.TextStrokeTransparency = 0.4
				nameLbl.LayoutOrder = 1
				nameLbl.Parent = bbg
			end

			if States.HealthESP and not States.BoxESP then
				local hpLbl = Instance.new("TextLabel")
				hpLbl.Size = UDim2.new(1, 0, 0, 16)
				hpLbl.BackgroundTransparency = 1
				hpLbl.Text = string.format("HP: %d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth))
				hpLbl.TextColor3 = ESPColors.HealthColor
				hpLbl.TextSize = 12
				hpLbl.Font = Enum.Font.GothamMedium
				hpLbl.TextStrokeTransparency = 0.4
				hpLbl.LayoutOrder = 2
				hpLbl.Parent = bbg
			end

			bbg.Parent = ESPFolder
		end
	end
	UpdateBoxESP()
end

-- GUI Construction (Aurkos Universal Gui)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AurkosUniversalGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 720, 0, 440)
mainFrame.Position = UDim2.new(0.5, -360, 0.5, -220)
mainFrame.BackgroundColor3 = ThemeColors.MainBg
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
registerMainFrame(mainFrame)

local function SetGuiVisible(visible)
	States.GuiVisible = visible
	if mainFrame and mainFrame.Parent then
		mainFrame.Visible = visible
	end
end

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = ThemeColors.Border
mainStroke.Thickness = 1.2
mainStroke.Parent = mainFrame
registerStroke(mainStroke)

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 54)
header.BackgroundColor3 = ThemeColors.PanelBg
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)
registerPanelFrame(header)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0.75, 0, 0, 26)
titleLbl.Position = UDim2.new(0, 18, 0, 6)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "Aurkos Universal Gui"
titleLbl.TextColor3 = ThemeColors.Text
titleLbl.TextSize = 19
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = header
registerText(titleLbl)

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(0.75, 0, 0, 16)
subLbl.Position = UDim2.new(0, 18, 0, 30)
subLbl.BackgroundTransparency = 1
subLbl.Text = "অর্কো স্ক্রিপ্ট • Full Multi-Tab Panel"
subLbl.TextColor3 = Color3.fromRGB(160, 150, 190)
subLbl.TextSize = 11
subLbl.Font = Enum.Font.Gotham
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Parent = header

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -74, 0.5, -15)
minBtn.BackgroundColor3 = ThemeColors.ItemBg
minBtn.Text = "-"
minBtn.TextColor3 = ThemeColors.Text
minBtn.TextSize = 18
minBtn.Font = Enum.Font.GothamBold
minBtn.Parent = header
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)
registerItemFrame(minBtn)
registerText(minBtn)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0.5, -15)
closeBtn.BackgroundColor3 = Color3.fromRGB(160, 38, 58)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 235, 240)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- Left Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 180, 1, -54)
sidebar.Position = UDim2.new(0, 0, 0, 54)
sidebar.BackgroundColor3 = ThemeColors.MainBg
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
registerMainFrame(sidebar)

local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.new(1, -16, 1, -72)
tabHolder.Position = UDim2.new(0, 8, 0, 10)
tabHolder.BackgroundTransparency = 1
tabHolder.Parent = sidebar

local tabListLayout = Instance.new("UIListLayout")
tabListLayout.Padding = UDim.new(0, 5)
tabListLayout.Parent = tabHolder

-- Profile Footer
local profileCard = Instance.new("Frame")
profileCard.Size = UDim2.new(1, -16, 0, 48)
profileCard.Position = UDim2.new(0, 8, 1, -56)
profileCard.BackgroundColor3 = ThemeColors.ItemBg
profileCard.Parent = sidebar
Instance.new("UICorner", profileCard).CornerRadius = UDim.new(0, 10)
registerItemFrame(profileCard)

local avatarImg = Instance.new("ImageLabel")
avatarImg.Size = UDim2.new(0, 34, 0, 34)
avatarImg.Position = UDim2.new(0, 7, 0.5, -17)
avatarImg.BackgroundColor3 = ThemeColors.PanelBg
avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
avatarImg.Parent = profileCard
Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

local profileName = Instance.new("TextLabel")
profileName.Size = UDim2.new(1, -50, 1, 0)
profileName.Position = UDim2.new(0, 46, 0, 0)
profileName.BackgroundTransparency = 1
profileName.Text = LocalPlayer.DisplayName
profileName.TextColor3 = ThemeColors.Text
profileName.TextSize = 13
profileName.Font = Enum.Font.GothamMedium
profileName.TextXAlignment = Enum.TextXAlignment.Left
profileName.TextTruncate = Enum.TextTruncate.AtEnd
profileName.Parent = profileCard
registerText(profileName)

-- Content Area
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -190, 1, -64)
contentArea.Position = UDim2.new(0, 185, 0, 59)
contentArea.BackgroundColor3 = ThemeColors.PanelBg
contentArea.Parent = mainFrame
Instance.new("UICorner", contentArea).CornerRadius = UDim.new(0, 12)
registerPanelFrame(contentArea)

local pages = {}
local tabButtons = {}
local currentTabName = "Player"

local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, -16, 1, -16)
	page.Position = UDim2.new(0, 8, 0, 8)
	page.BackgroundTransparency = 1
	page.ScrollBarThickness = 4
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = contentArea

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 7)
	layout.Parent = page

	pages[name] = page
	return page
end

local function refreshTabStyles()
	for tabName, btn in pairs(tabButtons) do
		local active = (tabName == currentTabName)
		btn.BackgroundColor3 = active and ThemeColors.Accent or ThemeColors.MainBg
		btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(165, 158, 188)
	end
end

ThemeRegistry.activeTabGetter = refreshTabStyles

local function switchTab(name)
	currentTabName = name
	for tabName, page in pairs(pages) do
		page.Visible = (tabName == name)
	end
	refreshTabStyles()
end

local tabNames = { "Main", "Movement", "Visuals", "Combat", "Player", "World", "Server" }
for _, tabName in ipairs(tabNames) do
	createPage(tabName)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = ThemeColors.MainBg
	btn.Text = "◈  " .. tabName
	btn.TextColor3 = Color3.fromRGB(165, 158, 188)
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamMedium
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = tabHolder
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 10)

	btn.MouseButton1Click:Connect(function()
		switchTab(tabName)
	end)
	tabButtons[tabName] = btn
end

-- Component Builders
local function addSection(parent, title)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 22)
	lbl.BackgroundTransparency = 1
	lbl.Text = title
	lbl.TextColor3 = Color3.fromRGB(185, 175, 215)
	lbl.TextSize = 12
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent
end

local function addInfoLabel(parent, initialText)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 26)
	lbl.BackgroundColor3 = ThemeColors.ItemBg
	lbl.Text = "  " .. initialText
	lbl.TextColor3 = ThemeColors.Text
	lbl.TextSize = 12
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
	registerItemFrame(lbl)
	registerText(lbl)
	return lbl
end

local function addButton(parent, labelText, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = ThemeColors.ItemBg
	btn.Text = labelText
	btn.TextColor3 = ThemeColors.Text
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamMedium
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)
	registerItemFrame(btn)
	registerText(btn)

	local stroke = Instance.new("UIStroke")
	stroke.Color = ThemeColors.Border
	stroke.Thickness = 1
	stroke.Parent = btn
	registerStroke(stroke)

	if callback then
		btn.MouseButton1Click:Connect(function()
			callback(btn)
		end)
	end
	return btn
end

local function addToggle(parent, labelText, initialState, callback)
	local active = initialState or false
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = active and ThemeColors.Accent or ThemeColors.ItemBg
	btn.Text = labelText .. (active and "  [ON]" or "  [OFF]")
	btn.TextColor3 = ThemeColors.Text
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamMedium
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)
	registerText(btn)

	local function setVisual(stateVal)
		active = stateVal
		btn.BackgroundColor3 = active and ThemeColors.Accent or ThemeColors.ItemBg
		btn.Text = labelText .. (active and "  [ON]" or "  [OFF]")
	end

	btn.MouseButton1Click:Connect(function()
		setVisual(not active)
		if callback then
			callback(active)
		end
	end)

	return {
		button = btn,
		setState = function(stateVal, fireCb)
			setVisual(stateVal)
			if fireCb and callback then
				callback(active)
			end
		end,
		getState = function()
			return active
		end,
	}
end

-- Color Selector Row (Click to Cycle Through Red, Green, Purple, Blue, Cyan, Amber, Pink, White)
local function addColorCycleButton(parent, labelPrefix, initialColor, onColorPicked)
	local idx = 1
	for i, choice in ipairs(ColorChoices) do
		if math.abs(choice.color.R - initialColor.R) < 0.05
			and math.abs(choice.color.G - initialColor.G) < 0.05
			and math.abs(choice.color.B - initialColor.B) < 0.05 then
			idx = i
			break
		end
	end

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3 = ThemeColors.ItemBg
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)
	registerItemFrame(row)

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.new(0, 22, 0, 22)
	swatch.Position = UDim2.new(0, 8, 0.5, -11)
	swatch.BackgroundColor3 = ColorChoices[idx].color
	swatch.Parent = row
	Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 6)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -38, 1, 0)
	btn.Position = UDim2.new(0, 36, 0, 0)
	btn.BackgroundTransparency = 1
	btn.Text = labelPrefix .. ": " .. ColorChoices[idx].name .. "  (Click to Change)"
	btn.TextColor3 = ThemeColors.Text
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamMedium
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = row
	registerText(btn)

	btn.MouseButton1Click:Connect(function()
		idx = (idx % #ColorChoices) + 1
		local picked = ColorChoices[idx]
		swatch.BackgroundColor3 = picked.color
		btn.Text = labelPrefix .. ": " .. picked.name .. "  (Click to Change)"
		if onColorPicked then
			onColorPicked(picked)
		end
	end)

	return {
		row = row,
		swatch = swatch,
		button = btn,
		setChoiceByName = function(name)
			for i, choice in ipairs(ColorChoices) do
				if choice.name == name then
					idx = i
					swatch.BackgroundColor3 = choice.color
					btn.Text = labelPrefix .. ": " .. choice.name .. "  (Click to Change)"
					return
				end
			end
		end,
	}
end

-- Left-to-Right Drag Slider (Temporarily disables mainFrame drag while sliding)
local function addDragSlider(parent, title, minVal, maxVal, defaultVal, suffix, onChanged)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 54)
	container.BackgroundColor3 = ThemeColors.ItemBg
	container.Active = true
	container.Parent = parent
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 9)
	registerItemFrame(container)

	local topRow = Instance.new("TextLabel")
	topRow.Size = UDim2.new(1, -20, 0, 22)
	topRow.Position = UDim2.new(0, 10, 0, 4)
	topRow.BackgroundTransparency = 1
	topRow.TextXAlignment = Enum.TextXAlignment.Left
	topRow.TextColor3 = ThemeColors.Text
	topRow.TextSize = 12
	topRow.Font = Enum.Font.GothamMedium
	topRow.Parent = container
	registerText(topRow)

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -20, 0, 10)
	track.Position = UDim2.new(0, 10, 0, 33)
	track.BackgroundColor3 = Color3.fromRGB(54, 46, 76)
	track.Active = true
	track.Parent = container
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = ThemeColors.Accent
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	registerAccentFrame(fill)

	local knob = Instance.new("TextButton")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(246, 244, 255)
	knob.Text = ""
	knob.AutoButtonColor = false
	knob.Parent = track
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local dragging = false
	local savedDraggable = true
	local currentVal = math.clamp(defaultVal or minVal, minVal, maxVal)

	local function applyRatio(ratio)
		ratio = math.clamp(ratio, 0, 1)
		local raw = minVal + (maxVal - minVal) * ratio
		local rounded = math.floor(raw * 10 + 0.5) / 10
		currentVal = rounded
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		topRow.Text = string.format("%s: %.1f%s", title, currentVal, suffix or "")
		if onChanged then
			onChanged(currentVal)
		end
	end

	local initRatio = (currentVal - minVal) / math.max(maxVal - minVal, 0.0001)
	applyRatio(initRatio)

	local function updateFromInput(inputPos)
		local absPos = track.AbsolutePosition.X
		local absSize = math.max(track.AbsoluteSize.X, 1)
		applyRatio((inputPos.X - absPos) / absSize)
	end

	local function beginDrag(inputPos)
		if dragging then
			return
		end
		dragging = true
		savedDraggable = mainFrame.Draggable
		mainFrame.Draggable = false
		updateFromInput(inputPos)
	end

	local function endDrag()
		if not dragging then
			return
		end
		dragging = false
		mainFrame.Draggable = savedDraggable
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input.Position)
		end
	end)

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input.Position)
		end
	end)

	knob.MouseButton1Down:Connect(function()
		local mPos = UserInputService:GetMouseLocation()
		beginDrag(Vector3.new(mPos.X, mPos.Y, 0))
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			endDrag()
		end
	end)
end

-- 1. MAIN TAB (Includes GUI Hide/Show Keybind + GUI Theme Colors)
local mainPage = pages.Main
addSection(mainPage, "Local Player Stats")
local ageLbl = addInfoLabel(mainPage, "Account Age: Loading...")
local hpLbl = addInfoLabel(mainPage, "Health: Loading...")
local posLbl = addInfoLabel(mainPage, "Position: Loading...")

addSection(mainPage, "GUI Visibility & Keybind")
addButton(mainPage, "Hide / Show GUI", function()
	SetGuiVisible(not States.GuiVisible)
end)
local guiKeyBtn = addButton(mainPage, "GUI Keybind: [" .. Values.GuiToggleKey.Name .. "] (Click to Set)", function(btn)
	Values.ListeningGuiKey = true
	btn.Text = "Press any key to Hide/Show GUI..."
end)

addSection(mainPage, "GUI Theme Colors")
local themePresetCtrl = addColorCycleButton(mainPage, "Theme Preset", ThemeColors.Accent, function(choice)
	applyThemePreset(choice)
end)
addColorCycleButton(mainPage, "Accent Color", ThemeColors.Accent, function(choice)
	ThemeColors.Accent = choice.color
	applyTheme()
end)
addColorCycleButton(mainPage, "Background Color", ThemeColors.MainBg, function(choice)
	ThemeColors.MainBg = Color3.fromRGB(16, 15, 22):Lerp(choice.color, 0.14)
	applyTheme()
end)
addColorCycleButton(mainPage, "Panel Color", ThemeColors.PanelBg, function(choice)
	ThemeColors.PanelBg = Color3.fromRGB(24, 22, 32):Lerp(choice.color, 0.16)
	applyTheme()
end)
addColorCycleButton(mainPage, "Button / Card Color", ThemeColors.ItemBg, function(choice)
	ThemeColors.ItemBg = Color3.fromRGB(32, 29, 44):Lerp(choice.color, 0.18)
	applyTheme()
end)
addColorCycleButton(mainPage, "Border Color", ThemeColors.Border, function(choice)
	ThemeColors.Border = choice.color
	applyTheme()
end)
addColorCycleButton(mainPage, "Text Color", ThemeColors.Text, function(choice)
	ThemeColors.Text = choice.color
	applyTheme()
end)
addButton(mainPage, "Quick Cycle Theme (Red / Green / Purple / Blue)", function()
	local idx = 1
	for i, c in ipairs(ColorChoices) do
		if c.name == ThemeColors.PresetName then
			idx = i
			break
		end
	end
	local nextChoice = ColorChoices[(idx % #ColorChoices) + 1]
	themePresetCtrl.setChoiceByName(nextChoice.name)
	applyThemePreset(nextChoice)
end)

addSection(mainPage, "Quick Actions")
addButton(mainPage, "Reset Character", function()
	if Humanoid then
		Humanoid.Health = 0
	end
end)
addButton(mainPage, "Instant Respawn", DoInstantRespawn)
addToggle(mainPage, "Instant Respawn On Death", false, function(val)
	States.InstantRespawn = val
end)
addToggle(mainPage, "Anti-AFK", false, function(val)
	States.AntiAFK = val
end)
addToggle(mainPage, "Anti-Void", false, function(val)
	States.AntiVoid = val
end)

-- 2. MOVEMENT TAB
local movePage = pages.Movement
addSection(movePage, "Walk & Jump")
addToggle(movePage, "Enable WalkSpeed", false, function(val)
	States.WalkSpeedEnabled = val
	if Humanoid then
		Humanoid.WalkSpeed = val and Values.WalkSpeed or 16
	end
end)
addDragSlider(movePage, "WalkSpeed", 16, 350, 16, " studs/s", function(val)
	Values.WalkSpeed = val
	if States.WalkSpeedEnabled and Humanoid then
		Humanoid.WalkSpeed = val
	end
end)
addToggle(movePage, "Enable JumpPower", false, function(val)
	States.JumpPowerEnabled = val
	if Humanoid then
		Humanoid.UseJumpPower = true
		Humanoid.JumpPower = val and Values.JumpPower or 50
	end
end)
addDragSlider(movePage, "JumpPower", 50, 500, 50, "", function(val)
	Values.JumpPower = val
	if States.JumpPowerEnabled and Humanoid then
		Humanoid.UseJumpPower = true
		Humanoid.JumpPower = val
	end
end)
addToggle(movePage, "Infinite Jump", false, function(val)
	States.InfiniteJump = val
end)
addToggle(movePage, "Noclip", false, function(val)
	States.Noclip = val
end)

addSection(movePage, "Flight & Keybind")
FlyToggleCtrl = addToggle(movePage, "Fly", false, function(val)
	SetFly(val)
end)

local flyKeyBtn = addButton(movePage, "Fly Keybind: [" .. Values.FlyKey.Name .. "] (Click to Set)", function(btn)
	Values.ListeningFlyKey = true
	btn.Text = "Press any key for Fly..."
end)

addDragSlider(movePage, "Fly Speed", 10, 300, Values.FlySpeed, "", function(val)
	Values.FlySpeed = val
end)

addSection(movePage, "Vehicle & Teleport")
addToggle(movePage, "Vehicle Fly", false, function(val)
	States.VehicleFly = val
	if not val then
		StopVehicleFlyPhysics()
	end
end)
addDragSlider(movePage, "Vehicle Fly Speed", 10, 300, Values.VehicleFlySpeed, "", function(val)
	Values.VehicleFlySpeed = val
end)
addDragSlider(movePage, "Vehicle Speed Multiplier", 1, 20, Values.VehicleBoost, "x", function(val)
	Values.VehicleBoost = val
	ApplyVehicleBoost(val)
end)
addToggle(movePage, "Click TP (Ctrl + Click)", false, function(val)
	States.ClickTP = val
end)

-- 3. VISUALS TAB (ESP + ESP Colors + Team Filters)
local visPage = pages.Visuals
addSection(visPage, "ESP Master")
addToggle(visPage, "Master ESP", false, function(val)
	States.ESP = val
	UpdateESP()
end)
addToggle(visPage, "Name ESP", false, function(val)
	States.NameESP = val
	UpdateESP()
end)
addToggle(visPage, "Box ESP (2D)", false, function(val)
	States.BoxESP = val
	UpdateESP()
end)
addToggle(visPage, "Highlight ESP", false, function(val)
	States.HighlightESP = val
	UpdateESP()
end)
addToggle(visPage, "Health ESP", false, function(val)
	States.HealthESP = val
	UpdateESP()
end)

addSection(visPage, "ESP Colors")
addColorCycleButton(visPage, "Box ESP Color", ESPColors.BoxColor, function(choice)
	ESPColors.BoxColor = choice.color
	UpdateBoxESP()
end)
addColorCycleButton(visPage, "Name ESP Color", ESPColors.NameColor, function(choice)
	ESPColors.NameColor = choice.color
	UpdateESP()
end)
addColorCycleButton(visPage, "Health ESP Color", ESPColors.HealthColor, function(choice)
	ESPColors.HealthColor = choice.color
	UpdateESP()
end)
addColorCycleButton(visPage, "Highlight Fill Color", ESPColors.HighlightFill, function(choice)
	ESPColors.HighlightFill = choice.color
	UpdateESP()
end)
addColorCycleButton(visPage, "Highlight Outline Color", ESPColors.HighlightOutline, function(choice)
	ESPColors.HighlightOutline = choice.color
	UpdateESP()
end)

addSection(visPage, "Team Filters")
addToggle(visPage, "Enable Team Whitelist", false, function(val)
	States.WhiteListEnabled = val
	UpdateESP()
end)
addToggle(visPage, "Enable Team Blacklist", false, function(val)
	States.BlackListEnabled = val
	UpdateESP()
end)

local teamHolder = Instance.new("Frame")
teamHolder.Size = UDim2.new(1, 0, 0, 86)
teamHolder.BackgroundColor3 = ThemeColors.ItemBg
teamHolder.Parent = visPage
Instance.new("UICorner", teamHolder).CornerRadius = UDim.new(0, 9)
registerItemFrame(teamHolder)

local teamScroll = Instance.new("ScrollingFrame")
teamScroll.Size = UDim2.new(1, -12, 1, -10)
teamScroll.Position = UDim2.new(0, 6, 0, 5)
teamScroll.BackgroundTransparency = 1
teamScroll.ScrollBarThickness = 3
teamScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
teamScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
teamScroll.Parent = teamHolder

local teamLayout = Instance.new("UIListLayout")
teamLayout.Padding = UDim.new(0, 4)
teamLayout.Parent = teamScroll

local function refreshTeamList()
	for _, c in ipairs(teamScroll:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	local teams = Teams:GetTeams()
	if #teams == 0 then
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 24)
		lbl.BackgroundTransparency = 1
		lbl.Text = "No Teams in Server"
		lbl.TextColor3 = Color3.fromRGB(165, 156, 190)
		lbl.TextSize = 12
		lbl.Font = Enum.Font.Gotham
		lbl.Parent = teamScroll
		return
	end
	for _, tm in ipairs(teams) do
		local tName = tm.Name
		local tBtn = Instance.new("TextButton")
		tBtn.Size = UDim2.new(1, 0, 0, 26)
		local wl = WhiteListTeams[tName] == true
		local bl = BlackListTeams[tName] == true
		tBtn.BackgroundColor3 = wl and Color3.fromRGB(45, 95, 75) or (bl and Color3.fromRGB(95, 42, 58) or ThemeColors.PanelBg)
		tBtn.Text = string.format("%s  [WL:%s | BL:%s]", tName, wl and "ON" or "OFF", bl and "ON" or "OFF")
		tBtn.TextColor3 = ThemeColors.Text
		tBtn.TextSize = 11
		tBtn.Font = Enum.Font.GothamMedium
		tBtn.Parent = teamScroll
		Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)

		tBtn.MouseButton1Click:Connect(function()
			if not WhiteListTeams[tName] and not BlackListTeams[tName] then
				WhiteListTeams[tName] = true
			elseif WhiteListTeams[tName] then
				WhiteListTeams[tName] = nil
				BlackListTeams[tName] = true
			else
				BlackListTeams[tName] = nil
			end
			refreshTeamList()
			UpdateESP()
		end)
	end
end
refreshTeamList()

-- 4. COMBAT TAB
local combatPage = pages.Combat
addSection(combatPage, "Target Elimination")
addButton(combatPage, "Fling Selected Target", function()
	local target = GetSelectedPlayer()
	if target then
		FlingPlayer(target)
	end
end)
addToggle(combatPage, "Fling Loop Selected", false, function(val)
	States.FlingLoop = val
	if val then
		StartFlingLoop()
	end
end)
addToggle(combatPage, "Fling All Players", false, function(val)
	States.FlingAll = val
	if val then
		StartFlingLoop()
	end
end)
addToggle(combatPage, "Auto Fling New Players", false, function(val)
	States.AutoFlingNew = val
end)

addSection(combatPage, "Combat Protection & Exploits")
addToggle(combatPage, "Auto Anti-Fling Protection", true, function(val)
	States.AutoAntiFling = val
end)
addButton(combatPage, "FE Invisible (Exploit)", DoFEInvisible)

-- 5. PLAYER TAB
local playerPage = pages.Player
addSection(playerPage, "Select Player to Teleport / Spectate")

local ddHeader = Instance.new("TextButton")
ddHeader.Size = UDim2.new(1, 0, 0, 36)
ddHeader.BackgroundColor3 = ThemeColors.ItemBg
ddHeader.Text = "Select Player to Teleport   |   None  ▾"
ddHeader.TextColor3 = ThemeColors.Text
ddHeader.TextSize = 13
ddHeader.Font = Enum.Font.GothamMedium
ddHeader.TextXAlignment = Enum.TextXAlignment.Left
ddHeader.Parent = playerPage
Instance.new("UICorner", ddHeader).CornerRadius = UDim.new(0, 9)
Instance.new("UIPadding", ddHeader).PaddingLeft = UDim.new(0, 12)
registerItemFrame(ddHeader)
registerText(ddHeader)

local listBox = Instance.new("Frame")
listBox.Size = UDim2.new(1, 0, 0, 134)
listBox.BackgroundColor3 = ThemeColors.ItemBg
listBox.Visible = true
listBox.Parent = playerPage
Instance.new("UICorner", listBox).CornerRadius = UDim.new(0, 10)
registerItemFrame(listBox)

local searchInput = Instance.new("TextBox")
searchInput.Size = UDim2.new(1, -16, 0, 26)
searchInput.Position = UDim2.new(0, 8, 0, 7)
searchInput.BackgroundColor3 = ThemeColors.PanelBg
searchInput.PlaceholderText = "Search player..."
searchInput.Text = ""
searchInput.TextColor3 = ThemeColors.Text
searchInput.PlaceholderColor3 = Color3.fromRGB(148, 138, 178)
searchInput.TextSize = 12
searchInput.Font = Enum.Font.Gotham
searchInput.Parent = listBox
Instance.new("UICorner", searchInput).CornerRadius = UDim.new(0, 7)
registerPanelFrame(searchInput)
registerText(searchInput)

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Size = UDim2.new(1, -16, 1, -40)
playersScroll.Position = UDim2.new(0, 8, 0, 37)
playersScroll.BackgroundTransparency = 1
playersScroll.ScrollBarThickness = 3
playersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playersScroll.Parent = listBox

local playersLayout = Instance.new("UIListLayout")
playersLayout.Padding = UDim.new(0, 4)
playersLayout.Parent = playersScroll

addSection(playerPage, "Player Dossier")
local dossierAgeLbl = addInfoLabel(playerPage, "Age: N/A")
local dossierHpLbl = addInfoLabel(playerPage, "Health: N/A")
local dossierTeamLbl = addInfoLabel(playerPage, "Team: N/A")
local dossierDistLbl = addInfoLabel(playerPage, "Distance: N/A")

local function updateDossier()
	local target = GetSelectedPlayer()
	if not target then
		dossierAgeLbl.Text = "  Age: N/A"
		dossierHpLbl.Text = "  Health: N/A"
		dossierTeamLbl.Text = "  Team: N/A"
		dossierDistLbl.Text = "  Distance: N/A"
		return
	end
	pcall(function()
		dossierAgeLbl.Text = "  Age: " .. tostring(target.AccountAge) .. " days"
		dossierTeamLbl.Text = "  Team: " .. (target.Team and target.Team.Name or "None")
		local hum, hrp = GetTargetParts(target)
		if hum then
			dossierHpLbl.Text = string.format("  Health: %d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth))
		else
			dossierHpLbl.Text = "  Health: Dead / None"
		end
		if hrp and HumanoidRootPart then
			local dist = (hrp.Position - HumanoidRootPart.Position).Magnitude
			dossierDistLbl.Text = string.format("  Distance: %.1f studs", dist)
		else
			dossierDistLbl.Text = "  Distance: N/A"
		end
	end)
end

local function refreshPlayerList()
	for _, child in ipairs(playersScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local q = string.lower(SearchQuery or "")
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local dMatch = string.find(string.lower(plr.DisplayName), q, 1, true)
			local nMatch = string.find(string.lower(plr.Name), q, 1, true)
			if q == "" or dMatch or nMatch then
				local pBtn = Instance.new("TextButton")
				pBtn.Size = UDim2.new(1, 0, 0, 28)
				local isSel = (SelectedPlayerName == plr.Name)
				pBtn.BackgroundColor3 = isSel and ThemeColors.Accent or ThemeColors.PanelBg
				pBtn.Text = (isSel and "● " or "○ ") .. plr.DisplayName .. " (@" .. plr.Name .. ")"
				pBtn.TextColor3 = ThemeColors.Text
				pBtn.TextSize = 12
				pBtn.Font = Enum.Font.GothamMedium
				pBtn.TextXAlignment = Enum.TextXAlignment.Left
				pBtn.Parent = playersScroll
				Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 7)
				Instance.new("UIPadding", pBtn).PaddingLeft = UDim.new(0, 8)

				pBtn.MouseButton1Click:Connect(function()
					SelectedPlayerName = plr.Name
					ddHeader.Text = "Select Player to Teleport   |   " .. plr.Name .. "  ▾"
					if States.Spectating then
						SetSpectate(true)
					end
					updateDossier()
					refreshPlayerList()
				end)
			end
		end
	end
end

ddHeader.MouseButton1Click:Connect(function()
	listBox.Visible = not listBox.Visible
end)

searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	SearchQuery = searchInput.Text
	refreshPlayerList()
end)

refreshPlayerList()

addButton(playerPage, "Teleport to Player", TeleportToSelected)
SpectateToggleCtrl = addToggle(playerPage, "Spectate Player", false, function(val)
	SetSpectate(val)
end)
addButton(playerPage, "Copy Player Dress", CopyPlayerDress)

-- 6. WORLD TAB
local worldPage = pages.World
addSection(worldPage, "Lighting & Sky")
addToggle(worldPage, "Fullbright", false, function(val)
	States.Fullbright = val
	if val then
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 1e10
		Lighting.GlobalShadows = false
	else
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)
		Lighting.Brightness = 1
		Lighting.ClockTime = Values.TimeOfDay
		Lighting.FogEnd = 10000
		Lighting.GlobalShadows = true
	end
end)

addDragSlider(worldPage, "Time of Day (Day / Night)", 0, 24, Values.TimeOfDay, "h", function(val)
	Values.TimeOfDay = val
	if not States.Fullbright then
		Lighting.ClockTime = val
	end
end)

addDragSlider(worldPage, "Field of View (FOV)", 50, 120, Values.FOV, "°", function(val)
	Values.FOV = val
	Camera = Workspace.CurrentCamera
	if Camera then
		Camera.FieldOfView = val
	end
end)

addSection(worldPage, "Physics")
addToggle(worldPage, "Custom Gravity", false, function(val)
	States.GravityEnabled = val
	Workspace.Gravity = val and Values.Gravity or 196.2
end)
addDragSlider(worldPage, "Gravity Force", 0, 350, Values.Gravity, "", function(val)
	Values.Gravity = val
	if States.GravityEnabled then
		Workspace.Gravity = val
	end
end)

-- 7. SERVER TAB
local serverPage = pages.Server
addSection(serverPage, "Server Information")
local jobIdLbl = addInfoLabel(serverPage, "Job ID: " .. tostring(game.JobId))
local placeIdLbl = addInfoLabel(serverPage, "Place ID: " .. tostring(game.PlaceId))
local pingLbl = addInfoLabel(serverPage, "Ping: Calculating...")
local fpsLbl = addInfoLabel(serverPage, "FPS: Calculating...")

addSection(serverPage, "Server Connection")
addButton(serverPage, "Rejoin Server", function()
	if #Players:GetPlayers() <= 1 then
		LocalPlayer:Kick("\nRejoining...")
		task.wait()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	else
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end
end)

addButton(serverPage, "Server Hop", function()
	pcall(function()
		local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
		local raw = game:HttpGet(url)
		local body = HttpService:JSONDecode(raw)
		if body and body.data then
			for _, srv in ipairs(body.data) do
				if type(srv) == "table" and srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
					break
				end
			end
		end
	end)
end)

addButton(serverPage, "Copy Server Job ID", function()
	if setclipboard then
		setclipboard(tostring(game.JobId))
	end
end)

-- Input & Keybind Listeners
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if Values.ListeningGuiKey then
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
			Values.GuiToggleKey = input.KeyCode
			Values.ListeningGuiKey = false
			if guiKeyBtn and guiKeyBtn.Parent then
				guiKeyBtn.Text = "GUI Keybind: [" .. Values.GuiToggleKey.Name .. "] (Click to Set)"
			end
		end
		return
	end

	if Values.ListeningFlyKey then
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
			Values.FlyKey = input.KeyCode
			Values.ListeningFlyKey = false
			if flyKeyBtn and flyKeyBtn.Parent then
				flyKeyBtn.Text = "Fly Keybind: [" .. Values.FlyKey.Name .. "] (Click to Set)"
			end
		end
		return
	end

	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Values.GuiToggleKey then
		SetGuiVisible(not States.GuiVisible)
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Values.FlyKey then
		SetFly(not States.Fly)
	end

	if States.ClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 and HumanoidRootPart then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			local mouse = LocalPlayer:GetMouse()
			if mouse and mouse.Hit then
				HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
			end
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if States.InfiniteJump and Humanoid then
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- Header Controls
minBtn.MouseButton1Click:Connect(function()
	local collapsed = (mainFrame.Size.Y.Offset <= 64)
	mainFrame.Size = collapsed and UDim2.new(0, 720, 0, 440) or UDim2.new(0, 720, 0, 54)
	sidebar.Visible = collapsed
	contentArea.Visible = collapsed
end)

closeBtn.MouseButton1Click:Connect(function()
	SetFly(false)
	StopVehicleFlyPhysics()
	StopSpectate()
	FlingActive = false
	ESPFolder:Destroy()
	for plr in pairs(BoxESPDrawings) do
		CleanupBoxESP(plr)
	end
	screenGui:Destroy()
end)

-- Runtime Loops
local frameCounter = 0
local fpsAccumulator = 0
local currentFPS = 60

RunService.RenderStepped:Connect(function(dt)
	Camera = Workspace.CurrentCamera
	frameCounter += 1
	fpsAccumulator += dt
	if fpsAccumulator >= 0.5 then
		currentFPS = math.floor((frameCounter / fpsAccumulator) + 0.5)
		frameCounter = 0
		fpsAccumulator = 0
	end

	if Camera then
		Camera.FieldOfView = Values.FOV
	end

	if States.Spectating then
		local target = GetSelectedPlayer()
		local targetHum = GetTargetParts(target)
		if target and targetHum and Camera then
			Camera.CameraSubject = targetHum
		else
			StopSpectate()
		end
	end

	if States.WalkSpeedEnabled and Humanoid then
		Humanoid.WalkSpeed = Values.WalkSpeed
	end

	if States.JumpPowerEnabled and Humanoid then
		Humanoid.UseJumpPower = true
		Humanoid.JumpPower = Values.JumpPower
	end

	if States.Fly and HumanoidRootPart and Camera then
		EnsureFlyPhysics()
		local dir = Vector3.zero
		local cf = Camera.CFrame
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			dir += cf.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			dir -= cf.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			dir += cf.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			dir -= cf.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			dir += Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			dir -= Vector3.new(0, 1, 0)
		end
		FlyBodyVelocity.Velocity = (dir.Magnitude > 0) and (dir.Unit * Values.FlySpeed) or Vector3.zero
		FlyBodyGyro.CFrame = CFrame.lookAt(HumanoidRootPart.Position, HumanoidRootPart.Position + cf.LookVector)
	else
		StopFlyPhysics()
	end

	if States.VehicleFly and Camera then
		local veh = GetVehicle()
		local part = veh and (veh.PrimaryPart or veh:FindFirstChildWhichIsA("BasePart"))
		if part then
			if not VehicleFlyBodyGyro or VehicleFlyBodyGyro.Parent ~= part then
				StopVehicleFlyPhysics()
				VehicleFlyBodyGyro = Instance.new("BodyGyro")
				VehicleFlyBodyGyro.P = 9e4
				VehicleFlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
				VehicleFlyBodyGyro.CFrame = part.CFrame
				VehicleFlyBodyGyro.Parent = part

				VehicleFlyBodyVelocity = Instance.new("BodyVelocity")
				VehicleFlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
				VehicleFlyBodyVelocity.Velocity = Vector3.zero
				VehicleFlyBodyVelocity.Parent = part
			end
			local dir = Vector3.zero
			local cf = Camera.CFrame
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				dir += cf.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				dir -= cf.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				dir += cf.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				dir -= cf.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				dir += Vector3.new(0, 1, 0)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				dir -= Vector3.new(0, 1, 0)
			end
			VehicleFlyBodyVelocity.Velocity = (dir.Magnitude > 0) and (dir.Unit * Values.VehicleFlySpeed) or Vector3.zero
			VehicleFlyBodyGyro.CFrame = cf
		else
			StopVehicleFlyPhysics()
		end
	end

	if States.AutoAntiFling and HumanoidRootPart then
		if HumanoidRootPart.AssemblyLinearVelocity.Magnitude > 250 then
			HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
		end
	end

	if States.AntiVoid and HumanoidRootPart then
		if HumanoidRootPart.Position.Y < (FPDH + 20) then
			HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position.X, FPDH + 50, HumanoidRootPart.Position.Z)
		end
	end

	if States.ESP and States.BoxESP then
		UpdateBoxESP()
	end
end)

RunService.Stepped:Connect(function()
	if States.Noclip or States.Fly then
		for _, part in ipairs(CharacterParts) do
			if part and part.Parent and part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end)

-- Anti-AFK Loop
task.spawn(function()
	while task.wait(60) do
		if States.AntiAFK then
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.zero)
			end)
		end
	end
end)

-- Periodic Stats, Dossier & Server Info Refresh
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			ageLbl.Text = "  Account Age: " .. tostring(LocalPlayer.AccountAge) .. " days"
			if Humanoid then
				hpLbl.Text = string.format("  Health: %d / %d", math.floor(Humanoid.Health), math.floor(Humanoid.MaxHealth))
			end
			if HumanoidRootPart then
				local p = HumanoidRootPart.Position
				posLbl.Text = string.format("  Position: X: %.1f, Y: %.1f, Z: %.1f", p.X, p.Y, p.Z)
			end
			updateDossier()

			jobIdLbl.Text = "  Job ID: " .. tostring(game.JobId)
			placeIdLbl.Text = "  Place ID: " .. tostring(game.PlaceId)
			fpsLbl.Text = "  FPS: " .. tostring(currentFPS)

			local pingItem = Stats and Stats.Network and Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem["Data Ping"]
			if pingItem then
				pingLbl.Text = string.format("  Ping: %d ms", math.floor(pingItem:GetValue() + 0.5))
			end

			if States.AutoFlingNew then
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= LocalPlayer then
						FlingPlayer(plr)
						task.wait(0.1)
					end
				end
			end
		end)
	end
end)

Players.PlayerAdded:Connect(function(plr)
	task.delay(1, function()
		refreshPlayerList()
		if States.ESP then
			UpdateESP()
		end
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	task.delay(0.2, function()
		if SelectedPlayerName == plr.Name then
			SelectedPlayerName = nil
			ddHeader.Text = "Select Player to Teleport   |   None  ▾"
			StopSpectate()
			updateDossier()
		end
		CleanupBoxESP(plr)
		refreshPlayerList()
		if States.ESP then
			UpdateESP()
		end
	end)
end)

Teams.ChildAdded:Connect(refreshTeamList)
Teams.ChildRemoved:Connect(refreshTeamList)

switchTab("Player")