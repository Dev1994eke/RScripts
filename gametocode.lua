--[[
    Optimized Game Copier
    - Safer property serialization
    - Preserves hierarchy
    - Handles unsupported properties without stopping
    - Avoids unnecessary work
    - Uses chunked yielding for large hierarchies
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GameCopier"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(650, 450)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.fromOffset(10, 5)
Title.BackgroundTransparency = 1
Title.Text = "Game Copier"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local GenerateButton = Instance.new("TextButton")
GenerateButton.Size = UDim2.fromOffset(150, 40)
GenerateButton.Position = UDim2.fromOffset(10, 50)
GenerateButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
GenerateButton.Text = "Generate"
GenerateButton.TextColor3 = Color3.new(1, 1, 1)
GenerateButton.TextSize = 16
GenerateButton.Font = Enum.Font.GothamBold
GenerateButton.Parent = Main

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 6)
ButtonCorner.Parent = GenerateButton

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -180, 0, 40)
Status.Position = UDim2.fromOffset(170, 50)
Status.BackgroundTransparency = 1
Status.Text = "Ready"
Status.TextColor3 = Color3.fromRGB(180, 180, 180)
Status.TextSize = 14
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

local Output = Instance.new("TextBox")
Output.Size = UDim2.new(1, -20, 1, -105)
Output.Position = UDim2.fromOffset(10, 95)
Output.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Output.TextColor3 = Color3.fromRGB(220, 220, 220)
Output.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
Output.PlaceholderText = "Generated code will appear here..."
Output.Text = ""
Output.TextSize = 13
Output.Font = Enum.Font.Code
Output.TextXAlignment = Enum.TextXAlignment.Left
Output.TextYAlignment = Enum.TextYAlignment.Top
Output.MultiLine = true
Output.ClearTextOnFocus = false
Output.TextEditable = true
Output.Parent = Main

local OutputCorner = Instance.new("UICorner")
OutputCorner.CornerRadius = UDim.new(0, 6)
OutputCorner.Parent = Output

--// Serializer

local function Quote(value)
	return string.format("%q", tostring(value))
end

local function Number(value)
	if value ~= value then
		return "0/0"
	elseif value == math.huge then
		return "math.huge"
	elseif value == -math.huge then
		return "-math.huge"
	end

	return string.format("%.17g", value)
end

local function Serialize(value)
	local valueType = typeof(value)

	if valueType == "string" then
		return Quote(value)

	elseif valueType == "number" then
		return Number(value)

	elseif valueType == "boolean" then
		return tostring(value)

	elseif valueType == "BrickColor" then
		return "BrickColor.new(" .. Quote(value.Name) .. ")"

	elseif valueType == "Color3" then
		return string.format(
			"Color3.new(%s,%s,%s)",
			Number(value.R),
			Number(value.G),
			Number(value.B)
		)

	elseif valueType == "Vector2" then
		return string.format(
			"Vector2.new(%s,%s)",
			Number(value.X),
			Number(value.Y)
		)

	elseif valueType == "Vector3" then
		return string.format(
			"Vector3.new(%s,%s,%s)",
			Number(value.X),
			Number(value.Y),
			Number(value.Z)
		)

	elseif valueType == "UDim" then
		return string.format(
			"UDim.new(%s,%d)",
			Number(value.Scale),
			value.Offset
		)

	elseif valueType == "UDim2" then
		return string.format(
			"UDim2.new(%s,%d,%s,%d)",
			Number(value.X.Scale),
			value.X.Offset,
			Number(value.Y.Scale),
			value.Y.Offset
		)

	elseif valueType == "CFrame" then
		local components = {value:GetComponents()}

		for i = 1, #components do
			components[i] = Number(components[i])
		end

		return "CFrame.new(" .. table.concat(components, ",") .. ")"

	elseif valueType == "EnumItem" then
		return tostring(value)

	elseif valueType == "Ray" then
		return string.format(
			"Ray.new(%s,%s)",
			Serialize(value.Origin),
			Serialize(value.Direction)
		)

	elseif valueType == "NumberRange" then
		return string.format(
			"NumberRange.new(%s,%s)",
			Number(value.Min),
			Number(value.Max)
		)

	elseif valueType == "ColorSequence" then
		local points = {}

		for _, point in ipairs(value.Keypoints) do
			points[#points + 1] = string.format(
				"ColorSequenceKeypoint.new(%s,%s)",
				Number(point.Time),
				Serialize(point.Value)
			)
		end

		return "ColorSequence.new({" .. table.concat(points, ",") .. "})"

	elseif valueType == "NumberSequence" then
		local points = {}

		for _, point in ipairs(value.Keypoints) do
			points[#points + 1] = string.format(
				"NumberSequenceKeypoint.new(%s,%s,%s)",
				Number(point.Time),
				Number(point.Value),
				Number(point.Envelope)
			)
		end

		return "NumberSequence.new({" .. table.concat(points, ",") .. "})"

	elseif valueType == "PhysicalProperties" then
		return string.format(
			"PhysicalProperties.new(%s,%s,%s,%s,%s)",
			Number(value.Density),
			Number(value.Friction),
			Number(value.Elasticity),
			Number(value.FrictionWeight),
			Number(value.ElasticityWeight)
		)
	end

	return nil
end

--// Properties that are commonly useful and serializable.
--// The serializer safely ignores properties that don't exist.
local Properties = {
	"Archivable",

	-- BasePart
	"Anchored",
	"CanCollide",
	"CanTouch",
	"CanQuery",
	"Massless",
	"CastShadow",
	"Reflectance",
	"Transparency",
	"Size",
	"Position",
	"Orientation",
	"CFrame",
	"Color",
	"BrickColor",
	"Material",

	-- GUI
	"Visible",
	"Active",
	"Selectable",
	"BackgroundColor3",
	"BackgroundTransparency",
	"BorderColor3",
	"BorderSizePixel",
	"ZIndex",
	"LayoutOrder",
	"AutomaticSize",

	-- Text
	"Text",
	"TextColor3",
	"TextSize",
	"TextScaled",
	"TextWrapped",
	"TextXAlignment",
	"TextYAlignment",
	"Font",
	"TextTransparency",
	"TextStrokeColor3",
	"TextStrokeTransparency",
	"PlaceholderText",
	"PlaceholderColor3",
	"MaxTextLength",

	-- Image
	"Image",
	"ImageColor3",
	"ImageTransparency",

	-- Scrolling
	"ScrollBarThickness",
	"CanvasSize",
	"CanvasPosition",

	-- Sound
	"Volume",
	"PlaybackSpeed",
	"Looped",
	"SoundId",

	-- Animation
	"AnimationId",

	-- Lighting / effects
	"Brightness",
	"Range",
	"Shadows",

	-- Generic
	"Enabled",
	"Value",
}

--// Cache whether a property can be read.
-- This avoids repeatedly doing expensive work for properties
-- that aren't supported by a class.
local PropertyCache = {}

local function ReadProperty(object, property)
	local className = object.ClassName

	local classCache = PropertyCache[className]

	if not classCache then
		classCache = {}
		PropertyCache[className] = classCache
	end

	if classCache[property] == false then
		return nil
	end

	local success, value = pcall(function()
		return object[property]
	end)

	if not success then
		classCache[property] = false
		return nil
	end

	classCache[property] = true

	return value
end

local function AddProperty(code, object, property, variable)
	local value = ReadProperty(object, property)

	if value == nil then
		return
	end

	local serialized = Serialize(value)

	if serialized then
		code[#code + 1] =
			variable ..
			"." ..
			property ..
			"=" ..
			serialized
	end
end

local function AddAttributes(code, object, variable)
	local success, attributes = pcall(function()
		return object:GetAttributes()
	end)

	if not success then
		return
	end

	for name, value in pairs(attributes) do
		local serialized = Serialize(value)

		if serialized then
			code[#code + 1] =
				variable ..
				":SetAttribute(" ..
				Quote(name) ..
				"," ..
				serialized ..
				")"
		end
	end
end

--// Object generation

local function GenerateObject(code, object, parentExpression, state)
	state.count += 1

	-- Yield occasionally so huge maps don't freeze the client.
	if state.count % state.yieldEvery == 0 then
		task.wait()
	end

	local variable = "v" .. state.count

	code[#code + 1] =
		"local " ..
		variable ..
		"=Instance.new(" ..
		Quote(object.ClassName) ..
		")"

	code[#code + 1] =
		variable ..
		".Name=" ..
		Quote(object.Name)

	for _, property in ipairs(Properties) do
		AddProperty(code, object, property, variable)
	end

	AddAttributes(code, object, variable)

	code[#code + 1] =
		variable ..
		".Parent=" ..
		parentExpression

	for _, child in ipairs(object:GetChildren()) do
		GenerateObject(
			code,
			child,
			variable,
			state
		)
	end
end

local function GenerateCode()
	local code = {}

	local state = {
		count = 0,
		yieldEvery = 250,
	}

	-- Workspace
	for _, object in ipairs(workspace:GetChildren()) do
		GenerateObject(
			code,
			object,
			"workspace",
			state
		)
	end

	-- ReplicatedStorage
	local replicatedStorageExpression =
		'game:GetService("ReplicatedStorage")'

	for _, object in ipairs(ReplicatedStorage:GetChildren()) do
		GenerateObject(
			code,
			object,
			replicatedStorageExpression,
			state
		)
	end

	return table.concat(code, "\n"), state.count
end

--// Generate button

local Generating = false

GenerateButton.MouseButton1Click:Connect(function()
	if Generating then
		return
	end

	Generating = true

	GenerateButton.Active = false
	GenerateButton.AutoButtonColor = false
	GenerateButton.Text = "Generating..."
	Status.Text = "Generating..."
	Output.Text = ""

	task.wait()

	local success, result, count = pcall(GenerateCode)

	if success then
		Output.Text = result

		Status.Text =
			"Generated " ..
			tostring(count) ..
			" objects"
	else
		Output.Text =
			"-- Generation error:\n-- " ..
			tostring(result)

		Status.Text = "Generation failed"
	end

	GenerateButton.Text = "Generate"
	GenerateButton.Active = true
	GenerateButton.AutoButtonColor = true

	Generating = false
end)

--// Dragging

local dragging = false
local dragStart
local startPosition

Title.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	dragging = true
	dragStart = input.Position
	startPosition = Main.Position

	local connection

	connection = input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			dragging = false

			if connection then
				connection:Disconnect()
			end
		end
	end)
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = input.Position - dragStart

	Main.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end)
