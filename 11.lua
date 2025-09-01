-- Gui to Lua
-- Version: 3.2

-- Instances:

local Spawner = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local T = Instance.new("TextLabel")
local UICorner = Instance.new("UICorner")
local NFR = Instance.new("TextButton")
local UICorner_2 = Instance.new("UICorner")
local MFR = Instance.new("TextButton")
local UICorner_3 = Instance.new("UICorner")
local MFR_2 = Instance.new("TextButton")
local UICorner_4 = Instance.new("UICorner")
local NameBox = Instance.new("TextBox")
local UICorner_5 = Instance.new("UICorner")
local Spawn = Instance.new("TextButton")
local UICorner_6 = Instance.new("UICorner")
local petType = "NFR"

local function duplicatePet(petName)
    local Loads = require(game.ReplicatedStorage.Fsys).load
    local ClientData = Loads("ClientData")
    local InventoryDB = Loads("InventoryDB")
    local Inventory = ClientData.get("inventory")

    local function generate_prop()
        return {
            flyable = true,
            rideable = true,
            neon = petType == "NFR" or petType == "MFR",
            mega_neon = petType == "MFR",
            age = 1
        }
    end

    local function cloneTable(original)
        local copy = {}
        for key, value in pairs(original) do
            if type(value) == "table" then
                copy[key] = cloneTable(value)
            else
                copy[key] = value
            end
        end
        return copy
    end

    for category_name, category_table in pairs(InventoryDB) do
        for id, item in pairs(category_table) do
            if category_name == "pets" and item.name == petName then
                local fake_uuid = game.HttpService:GenerateGUID()
                local n_item = cloneTable(item)

                n_item["unique"] = "uuid_" .. fake_uuid
                n_item["category"] = "pets"
                n_item["properties"] = generate_prop()
                n_item["newness_order"] = math.random(1, 900000)

                if not Inventory[category_name] then
                    Inventory[category_name] = {}
                end

                Inventory[category_name][fake_uuid] = n_item
                return
            end
        end
    end
end

--Properties:

Spawner.Name = "Spawner"
Spawner.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
Spawner.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Main.Name = "Main"
Main.Parent = Spawner
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
Main.BorderColor3 = Color3.fromRGB(0, 0, 0)
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.5, 0, 0.507051289, 0)
Main.Size = UDim2.new(0, 446, 0, 260)

T.Name = "T"
T.Parent = Main
T.AnchorPoint = Vector2.new(0.5, 0.5)
T.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
T.BackgroundTransparency = 1.000
T.BorderColor3 = Color3.fromRGB(0, 0, 0)
T.BorderSizePixel = 0
T.Position = UDim2.new(0.5, 0, 0.0884615406, 0)
T.Size = UDim2.new(0, 406, 0, 46)
T.Font = Enum.Font.GothamBold
T.Text = "Pet Spawner"
T.TextColor3 = Color3.fromRGB(255, 255, 255)
T.TextScaled = true
T.TextSize = 14.000
T.TextWrapped = true

UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = Main

NFR.Name = "NFR"
NFR.Parent = Main
NFR.AnchorPoint = Vector2.new(0.5, 0.5)
NFR.BackgroundColor3 = Color3.fromRGB(6, 6, 6)
NFR.BorderColor3 = Color3.fromRGB(0, 0, 0)
NFR.BorderSizePixel = 0
NFR.Position = UDim2.new(0.498878926, 0, 0.353846163, 0)
NFR.Size = UDim2.new(0, 89, 0, 50)
NFR.Font = Enum.Font.GothamBold
NFR.Text = "NFR"
NFR.TextColor3 = Color3.fromRGB(25, 255, 21)
NFR.TextScaled = true
NFR.TextSize = 14.000
NFR.TextWrapped = true
NFR.MouseButton1Click:Connect(function()
    NFR.TextColor3 = Color3.fromRGB(25, 255, 21)
    petType = "NFR"
    MFR_2.TextColor3 = Color3.fromRGB(255, 255, 255)
    MFR.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

UICorner_2.CornerRadius = UDim.new(0, 6)
UICorner_2.Parent = NFR

MFR.Name = "MFR"
MFR.Parent = Main
MFR.AnchorPoint = Vector2.new(0.5, 0.5)
MFR.BackgroundColor3 = Color3.fromRGB(6, 6, 6)
MFR.BorderColor3 = Color3.fromRGB(0, 0, 0)
MFR.BorderSizePixel = 0
MFR.Position = UDim2.new(0.797085226, 0, 0.353846163, 0)
MFR.Size = UDim2.new(0, 89, 0, 50)
MFR.Font = Enum.Font.GothamBold
MFR.Text = "MFR"
MFR.TextColor3 = Color3.fromRGB(255, 255, 255)
MFR.TextScaled = true
MFR.TextSize = 14.000
MFR.TextWrapped = true
MFR.MouseButton1Click:Connect(function()
    MFR.TextColor3 = Color3.fromRGB(25, 255, 21)
    petType = "MFR"
    MFR_2.TextColor3 = Color3.fromRGB(255, 255, 255)
    NFR.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

UICorner_3.CornerRadius = UDim.new(0, 6)
UICorner_3.Parent = MFR

MFR_2.Name = "MFR"
MFR_2.Parent = Main
MFR_2.AnchorPoint = Vector2.new(0.5, 0.5)
MFR_2.BackgroundColor3 = Color3.fromRGB(6, 6, 6)
MFR_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
MFR_2.BorderSizePixel = 0
MFR_2.Position = UDim2.new(0.202914804, 0, 0.353846163, 0)
MFR_2.Size = UDim2.new(0, 89, 0, 50)
MFR_2.Font = Enum.Font.GothamBold
MFR_2.Text = "FR"
MFR_2.TextColor3 = Color3.fromRGB(255, 255, 255)
MFR_2.TextScaled = true
MFR_2.TextSize = 14.000
MFR_2.TextWrapped = true
MFR_2.MouseButton1Click:Connect(function()
    MFR_2.TextColor3 = Color3.fromRGB(25, 255, 21)
    petType = "FR"
    NFR.TextColor3 = Color3.fromRGB(255, 255, 255)
    MFR.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

UICorner_4.CornerRadius = UDim.new(0, 6)
UICorner_4.Parent = MFR_2

NameBox.Name = "NameBox"
NameBox.Parent = Main
NameBox.AnchorPoint = Vector2.new(0.5, 0.5)
NameBox.BackgroundColor3 = Color3.fromRGB(6, 6, 6)
NameBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
NameBox.BorderSizePixel = 0
NameBox.Position = UDim2.new(0.5, 0, 0.601923048, 0)
NameBox.Size = UDim2.new(0, 354, 0, 45)
NameBox.Font = Enum.Font.GothamBold
NameBox.PlaceholderText = "Enter Pet Name Here"
NameBox.Text = ""
NameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
NameBox.TextScaled = true
NameBox.TextSize = 14.000
NameBox.TextWrapped = true

UICorner_5.CornerRadius = UDim.new(0, 6)
UICorner_5.Parent = NameBox

Spawn.Name = "Spawn"
Spawn.Parent = Main
Spawn.AnchorPoint = Vector2.new(0.5, 0.5)
Spawn.BackgroundColor3 = Color3.fromRGB(6, 6, 6)
Spawn.BorderColor3 = Color3.fromRGB(0, 0, 0)
Spawn.BorderSizePixel = 0
Spawn.Position = UDim2.new(0.497757852, 0, 0.824999988, 0)
Spawn.Size = UDim2.new(0, 176, 0, 41)
Spawn.Font = Enum.Font.GothamBold
Spawn.Text = "Spawn"
Spawn.TextColor3 = Color3.fromRGB(255, 255, 255)
Spawn.TextScaled = true
Spawn.TextSize = 14.000
Spawn.TextWrapped = true

UICorner_6.CornerRadius = UDim.new(0, 6)
UICorner_6.Parent = Spawn

Spawn.MouseButton1Click:Connect(function()
    duplicatePet(NameBox.Text)
end)

local UIS = game:GetService('UserInputService')
local frame = Main
local dragToggle = nil
local dragSpeed = 0.25
local dragStart = nil
local startPos = nil

local function updateInput(input)
	local delta = input.Position - dragStart
	local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	game:GetService('TweenService'):Create(frame, TweenInfo.new(dragSpeed), {Position = position}):Play()
end

frame.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then 
		dragToggle = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragToggle = false
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		if dragToggle then
			updateInput(input)
		end
	end
end)
