-- Roblox Discord Bridge Client
-- Paste script ini ke dalam ServerScriptService atau tempat yang sesuai di Roblox Studio

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ========== KONFIGURASI ==========
local API_URL = "http://localhost:3000"  -- Ganti dengan URL server kamu (atau IP publik jika deploy)
local SHARED_SECRET = "dev-secret"  -- Harus sama dengan yang di .env server
local POLL_INTERVAL = 1  -- Poll setiap 1 detik untuk pesan baru dari Discord

-- ========== UI SETUP ==========
local function createDiscordUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- ScreenGui untuk UI Discord
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DiscordBridgeUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 500)
	mainFrame.Position = UDim2.new(0, 50, 0, 50)
	mainFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)  -- Discord dark gray
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	-- Corner untuk rounded edges
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame
	
	-- Title Bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame
	
	local titleText = Instance.new("TextLabel")
	titleText.Name = "TitleText"
	titleText.Size = UDim2.new(1, -20, 1, 0)
	titleText.Position = UDim2.new(0, 10, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "💬 Discord Bridge"
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.TextSize = 16
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar
	
	-- Scroll Frame untuk messages
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "MessagesFrame"
	scrollFrame.Size = UDim2.new(1, -20, 1, -100)
	scrollFrame.Position = UDim2.new(0, 10, 0, 50)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.Parent = mainFrame
	
	local messagesList = Instance.new("UIListLayout")
	messagesList.Padding = UDim.new(0, 5)
	messagesList.SortOrder = Enum.SortOrder.LayoutOrder
	messagesList.Parent = scrollFrame
	
	-- Input Frame
	local inputFrame = Instance.new("Frame")
	inputFrame.Name = "InputFrame"
	inputFrame.Size = UDim2.new(1, -20, 0, 40)
	inputFrame.Position = UDim2.new(0, 10, 1, -50)
	inputFrame.BackgroundColor3 = Color3.fromRGB(40, 43, 48)
	inputFrame.BorderSizePixel = 0
	inputFrame.Parent = mainFrame
	
	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 6)
	inputCorner.Parent = inputFrame
	
	local textBox = Instance.new("TextBox")
	textBox.Name = "MessageInput"
	textBox.Size = UDim2.new(1, -80, 1, -10)
	textBox.Position = UDim2.new(0, 10, 0, 5)
	textBox.BackgroundTransparency = 1
	textBox.Text = ""
	textBox.PlaceholderText = "Ketik pesan..."
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	textBox.TextSize = 14
	textBox.Font = Enum.Font.Gotham
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.ClearTextOnFocus = false
	textBox.Parent = inputFrame
	
	local sendButton = Instance.new("TextButton")
	sendButton.Name = "SendButton"
	sendButton.Size = UDim2.new(0, 60, 1, -10)
	sendButton.Position = UDim2.new(1, -70, 0, 5)
	sendButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)  -- Discord blurple
	sendButton.BorderSizePixel = 0
	sendButton.Text = "Kirim"
	sendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	sendButton.TextSize = 14
	sendButton.Font = Enum.Font.GothamBold
	sendButton.Parent = inputFrame
	
	local sendCorner = Instance.new("UICorner")
	sendCorner.CornerRadius = UDim.new(0, 6)
	sendCorner.Parent = sendButton
	
	return screenGui, scrollFrame, textBox, sendButton
end

-- ========== FUNGSI UTILITAS ==========
local function addMessageToUI(scrollFrame, source, name, text)
	local messageFrame = Instance.new("Frame")
	messageFrame.Name = "Message"
	messageFrame.Size = UDim2.new(1, 0, 0, 0)
	messageFrame.BackgroundTransparency = 1
	messageFrame.Parent = scrollFrame
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = (source == "discord" and "🔵 " or "🟢 ") .. name
	nameLabel.TextColor3 = source == "discord" and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(67, 181, 129)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = messageFrame
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.new(1, 0, 0, 0)
	textLabel.Position = UDim2.new(0, 0, 0, 22)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
	textLabel.TextSize = 14
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.TextWrapped = true
	textLabel.Parent = messageFrame
	
	-- Auto-resize berdasarkan text
	textLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
		textLabel.Size = UDim2.new(1, 0, 0, textLabel.TextBounds.Y)
		messageFrame.Size = UDim2.new(1, 0, 0, textLabel.TextBounds.Y + 22)
	end)
	
	-- Scroll ke bawah
	wait(0.1)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, messagesList.AbsoluteContentSize.Y)
	scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.AbsoluteCanvasSize.Y)
end

-- ========== API FUNCTIONS ==========
local function sendMessageToDiscord(name, text)
	local success, result = pcall(function()
		local response = HttpService:PostAsync(
			API_URL .. "/roblox/send",
			HttpService:JSONEncode({
				name = name,
				text = text
			}),
			Enum.HttpContentType.ApplicationJson,
			false,
			{
				["x-shared-secret"] = SHARED_SECRET
			}
		)
		return HttpService:JSONDecode(response)
	end)
	
	if not success then
		warn("Error mengirim pesan:", result)
		return false
	end
	
	return result.ok == true
end

local lastMessageId = 0

local function pollDiscordMessages(scrollFrame)
	local success, result = pcall(function()
		local url = API_URL .. "/roblox/poll?since=" .. tostring(lastMessageId)
		local response = HttpService:GetAsync(
			url,
			false,
			{
				["x-shared-secret"] = SHARED_SECRET
			}
		)
		return HttpService:JSONDecode(response)
	end)
	
	if not success then
		warn("Error polling messages:", result)
		return
	end
	
	if result.ok and result.messages then
		for _, msg in ipairs(result.messages) do
			addMessageToUI(scrollFrame, msg.source, msg.name, msg.text)
			if msg.id > lastMessageId then
				lastMessageId = msg.id
			end
		end
		
		if result.nextSince then
			lastMessageId = result.nextSince
		end
	end
end

-- ========== MAIN ==========
local screenGui, scrollFrame, textBox, sendButton = createDiscordUI()

-- Send button click
sendButton.MouseButton1Click:Connect(function()
	local text = textBox.Text
	if text and text:match("%S") then  -- Check if not empty/whitespace
		local playerName = Players.LocalPlayer.Name
		if sendMessageToDiscord(playerName, text) then
			textBox.Text = ""
		else
			warn("Gagal mengirim pesan")
		end
	end
end)

-- Enter key to send
textBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		sendButton.MouseButton1Click:Fire()
	end
end)

-- Start polling loop
spawn(function()
	while true do
		pollDiscordMessages(scrollFrame)
		wait(POLL_INTERVAL)
	end
end)

print("Discord Bridge Client loaded!")
