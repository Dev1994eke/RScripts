-- // SHADOWDEV MADE THIS AWESOME SCRIPT
-- // RUNNABLE SCRIPT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

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
Output.Text = ""
Output.PlaceholderText = "Generated code will appear here..."
Output.TextSize = 13
Output.Font = Enum.Font.Code
Output.TextXAlignment = Enum.TextXAlignment.Left
Output.TextYAlignment = Enum.TextYAlignment.Top
Output.MultiLine = false
Output.ClearTextOnFocus = false
Output.TextEditable = true
Output.Parent = Main

local OutputCorner = Instance.new("UICorner")
OutputCorner.CornerRadius = UDim.new(0, 6)
OutputCorner.Parent = Output

local function CleanName(Name)
	Name = tostring(Name)
	return Name:gsub("[^%w_]", "_")
end

local function Quote(String)
	String = tostring(String)
	return string.format("%q", String)
end

local function GetPath(Object)
	local Parts = {}
	local Current = Object

	while Current and Current ~= game do
		table.insert(Parts, 1, Quote(Current.Name))
		Current = Current.Parent
	end

	if Current ~= game then
		return nil
	end

	return "game" .. string.rep(":FindFirstChild", 0) .. "[" ..
		table.concat(Parts, "][")
end



local function SerializeValue(Value)
	local ValueType = typeof(Value)

	if ValueType == "string" then
		return Quote(Value)

	elseif ValueType == "number" then
		if Value ~= Value then
			return "0/0"
		end

		if Value == math.huge then
			return "math.huge"
		end

		if Value == -math.huge then
			return "-math.huge"
		end

		return tostring(Value)

	elseif ValueType == "boolean" then
		return tostring(Value)

	elseif ValueType == "BrickColor" then
		return "BrickColor.new(" .. Quote(Value.Name) .. ")"

	elseif ValueType == "Color3" then
		return string.format(
			"Color3.new(%s,%s,%s)",
			Value.R,
			Value.G,
			Value.B
		)

	elseif ValueType == "Vector2" then
		return string.format(
			"Vector2.new(%s,%s)",
			Value.X,
			Value.Y
		)

	elseif ValueType == "Vector3" then
		return string.format(
			"Vector3.new(%s,%s,%s)",
			Value.X,
			Value.Y,
			Value.Z
		)

	elseif ValueType == "UDim" then
		return string.format(
			"UDim.new(%s,%s)",
			Value.Scale,
			Value.Offset
		)

	elseif ValueType == "UDim2" then
		return string.format(
			"UDim2.new(%s,%s,%s,%s)",
			Value.X.Scale,
			Value.X.Offset,
			Value.Y.Scale,
			Value.Y.Offset
		)

	elseif ValueType == "CFrame" then
		local Components = {Value:GetComponents()}

		for i, v in ipairs(Components) do
			Components[i] = tostring(v)
		end

		return "CFrame.new(" .. table.concat(Components, ",") .. ")"

	elseif ValueType == "EnumItem" then
		return tostring(Value)

	elseif ValueType == "Ray" then
		return string.format(
			"Ray.new(%s,%s)",
			SerializeValue(Value.Origin),
			SerializeValue(Value.Direction)
		)

	elseif ValueType == "ColorSequence" then
		local Keypoints = {}

		for _, Keypoint in ipairs(Value.Keypoints) do
			table.insert(
				Keypoints,
				string.format(
					"ColorSequenceKeypoint.new(%s,%s)",
					Keypoint.Time,
					SerializeValue(Keypoint.Value)
				)
			)
		end

		return "ColorSequence.new({" .. table.concat(Keypoints, ",") .. "})"

	elseif ValueType == "NumberSequence" then
		local Keypoints = {}

		for _, Keypoint in ipairs(Value.Keypoints) do
			table.insert(
				Keypoints,
				string.format(
					"NumberSequenceKeypoint.new(%s,%s,%s)",
					Keypoint.Time,
					Keypoint.Value,
					Keypoint.Envelope
				)
			)
		end

		return "NumberSequence.new({" .. table.concat(Keypoints, ",") .. "})"

	elseif ValueType == "NumberRange" then
		return string.format(
			"NumberRange.new(%s,%s)",
			Value.Min,
			Value.Max
		)

	elseif ValueType == "PhysicalProperties" then
		return string.format(
			"PhysicalProperties.new(%s,%s,%s,%s,%s)",
			Value.Density,
			Value.Friction,
			Value.Elasticity,
			Value.FrictionWeight,
			Value.ElasticityWeight
		)
	end

	return nil
end

local function AddProperty(Code, Object, Property, Variable)
	local Success, Value = pcall(function()
		return Object[Property]
	end)

	if not Success then
		return
	end

	local Serialized = SerializeValue(Value)

	if Serialized then
		table.insert(
			Code,
			Variable .. "." .. Property .. "=" .. Serialized
		)
	end
end

local Properties = {
	"Name",
	"Archivable",
	"Transparency",
	"Reflectance",
	"CanCollide",
	"CanTouch",
	"CanQuery",
	"Anchored",
	"Massless",
	"Size",
	"Position",
	"Orientation",
	"CFrame",
	"Color",
	"BrickColor",
	"Material",
	"CastShadow",
	"Visible",
	"Active",
	"Selectable",
	"Text",
	"TextColor3",
	"TextSize",
	"TextScaled",
	"TextWrapped",
	"TextXAlignment",
	"TextYAlignment",
	"Font",
	"BackgroundColor3",
	"BackgroundTransparency",
	"BorderColor3",
	"BorderSizePixel",
	"Image",
	"ImageColor3",
	"ImageTransparency",
	"Enabled",
	"Volume",
	"PlaybackSpeed",
	"Looped",
	"SoundId",
	"AnimationId",
	"Value",
	"Brightness",
	"Range",
	"Shadows",
	"ZIndex",
	"LayoutOrder",
	"ScrollBarThickness",
	"CanvasSize",
	"CanvasPosition",
	"PlaceholderText",
	"PlaceholderColor3",
	"MaxTextLength",
	"AutomaticSize",
	"TextTransparency",
	"TextStrokeColor3",
	"TextStrokeTransparency",
}

local function GenerateObject(Code, Object, ParentExpression, Variables, State)
	if Object == workspace then
		return 0
	end

	if Object == ReplicatedStorage then
		return 0
	end

	local ClassName = Object.ClassName

	Variables.Count += 1
	local VariableName = "v" .. tostring(Variables.Count)

	Variables[Object] = VariableName
	State.Processed += 1
	if State.Processed % 100 == 0 then
		task.wait()
	end

	table.insert(
		Code,
		"local " ..
			VariableName ..
			"=Instance.new(" ..
			Quote(ClassName) ..
			")"
	)

	local NameSuccess = pcall(function()
		Object.Name = Object.Name
	end)

	if NameSuccess then
		table.insert(
			Code,
			VariableName ..
				".Name=" ..
				Quote(Object.Name)
		)
	end

	for _, Property in ipairs(Properties) do
		if Property ~= "Name" then
			AddProperty(
				Code,
				Object,
				Property,
				VariableName
			)
		end
	end

	local AttributeSuccess, Attributes = pcall(function()
		return Object:GetAttributes()
	end)

	if AttributeSuccess then
		for Name, Value in pairs(Attributes) do
			local Serialized = SerializeValue(Value)

			if Serialized then
				table.insert(
					Code,
					VariableName ..
						":SetAttribute(" ..
						Quote(Name) ..
						"," ..
						Serialized ..
						")"
				)
			end
		end
	end

	table.insert(
		Code,
		VariableName ..
			".Parent=" ..
			ParentExpression
	)

	local Count = 1

	for _, Child in ipairs(Object:GetChildren()) do
		local Before = #Code

		GenerateObject(
			Code,
			Child,
			VariableName,
			Variables,
			State
		)

		if #Code > Before then
			Count += 1
		end
	end

	return Count
end

local function GenerateCode()
	local Code = {}
	local Variables = {Count = 0}
	local State = {Processed = 0}

	local Total = 0

	for _, Object in ipairs(workspace:GetChildren()) do
		local Before = #Code

		GenerateObject(
			Code,
			Object,
			"workspace",
			Variables,
			State
		)

		if #Code > Before then
			Total += 1
		end
	end

	for _, Object in ipairs(ReplicatedStorage:GetChildren()) do
		local Before = #Code

		GenerateObject(
			Code,
			Object,
			"game:GetService(" ..
				Quote("ReplicatedStorage") ..
				")",
			Variables,
			State
		)

		if #Code > Before then
			Total += 1
		end
	end

	return table.concat(Code, "\n"), Total
end

GenerateButton.MouseButton1Click:Connect(function()
	GenerateButton.Active = false
	GenerateButton.AutoButtonColor = false

	Status.Text = "Generating..."

	task.wait()

	local Success, Code, Count = pcall(GenerateCode)

	if Success then

		Output.Text = Code

		Status.Text =
			"Generated " ..
			tostring(Count) ..
			" objects | Single line"
	else
		Output.Text =
			"-- Generation error: " ..
			tostring(Code)

		Status.Text = "Generation failed"
	end

	GenerateButton.Active = true
	GenerateButton.AutoButtonColor = true
end)

local UserInputService = game:GetService("UserInputService")

local Dragging = false
local DragStart
local StartPosition

Title.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then

		Dragging = true
		DragStart = Input.Position
		StartPosition = Main.Position

		Input.Changed:Connect(function()
			if Input.UserInputState == Enum.UserInputState.End then
				Dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(Input)
	if not Dragging then
		return
	end

	if Input.UserInputType ~= Enum.UserInputType.MouseMovement
		and Input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local Delta = Input.Position - DragStart

	Main.Position = UDim2.new(
		StartPosition.X.Scale,
		StartPosition.X.Offset + Delta.X,
		StartPosition.Y.Scale,
		StartPosition.Y.Offset + Delta.Y
	)
end)
