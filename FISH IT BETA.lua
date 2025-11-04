--[[

    WindUI Example - RyDev Fishing Hub
    
]]

local WindUI

do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)
    
    if ok then
        WindUI = result
    else 
        WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end
end

-- */ Import Fishing Script Variables and Functions /* --
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Waypoints Coordinates
local islandCoords = {
	["01"] = { name = "Weather Machine", position = Vector3.new(-1471, -3, 1929) },
	["02"] = { name = "Esoteric Depths", position = Vector3.new(3157, -1303, 1439) },
	["03"] = { name = "Tropical Grove", position = Vector3.new(-2038, 3, 3650) },
	["04"] = { name = "Stingray Shores", position = Vector3.new(-32, 4, 2773) },
	["05"] = { name = "Kohana Volcano", position = Vector3.new(-519, 24, 189) },
	["06"] = { name = "Coral Reefs", position = Vector3.new(-3095, 1, 2177) },
	["07"] = { name = "Crater Island", position = Vector3.new(968, 1, 4854) },
	["08"] = { name = "Kohana", position = Vector3.new(-658, 3, 719) },
	["09"] = { name = "Winter Fest", position = Vector3.new(1611, 4, 3280) },
	["10"] = { name = "Isoteric Island", position = Vector3.new(1987, 4, 1400) },
	["11"] = { name = "Treasure Hall", position = Vector3.new(-3600, -267, -1558) },
	["12"] = { name = "Lost Shore", position = Vector3.new(-3663, 38, -989 ) },
	["13"] = { name = "Sishypus Statue", position = Vector3.new(-3792, -135, -986) }
}

-- Path dasar ke remote sleitnick_net
local netPath = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

-- ====== Remote Events & Functions ======
local EquipToolRE = netPath:WaitForChild("RE/EquipToolFromHotbar")
local ChargeRodRF = netPath:WaitForChild("RF/ChargeFishingRod")
local RequestMinigameRF = netPath:WaitForChild("RF/RequestFishingMinigameStarted")
local FishingCompletedRE = netPath:WaitForChild("RE/FishingCompleted")
local SellAllItemsRF = netPath:FindFirstChild("RF/SellAllItems")
local ActivateEnchantingAltarRE = netPath:WaitForChild("RE/ActivateEnchantingAltar")

-- ====== Animation Paths ======
local AnimationsFolder = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations")
local RodIdleName = "FishingRodReelIdle"
local RodReelName = "EasyFishReelStart"
local RodShakeName = "CastFromFullChargePosition1Hand"

local RodIdle, RodReel, RodShake
local animLoadSuccess = true
pcall(function() RodIdle = AnimationsFolder:WaitForChild(RodIdleName, 5) end)
pcall(function() RodReel = AnimationsFolder:WaitForChild(RodReelName, 5) end)
pcall(function() RodShake = AnimationsFolder:WaitForChild(RodShakeName, 5) end)

if not RodIdle or not RodReel or not RodShake then
    warn("!!! PERINGATAN: Animasi tidak ditemukan! Periksa path/nama. Animasi mungkin tidak akan diputar. !!!")
    animLoadSuccess = false
end

-- ====== Player & Character Variables ======
local Player = Players.LocalPlayer
local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

-- ====== Animation Loading ======
local RodShakeAnim, RodIdleAnim, RodReelAnim
if animLoadSuccess then
    local success1, anim1 = pcall(function() return animator:LoadAnimation(RodShake) end)
    if success1 then RodShakeAnim = anim1 else warn("Gagal memuat animasi RodShake!") end

    local success2, anim2 = pcall(function() return animator:LoadAnimation(RodIdle) end)
    if success2 then RodIdleAnim = anim2 else warn("Gagal memuat animasi RodIdle!") end

    local success3, anim3 = pcall(function() return animator:LoadAnimation(RodReel) end)
    if success3 then RodReelAnim = anim3 else warn("Gagal memuat animasi RodReel!") end
else
    warn("Memuat animasi dihentikan karena path awal tidak valid.")
end

-- ====== Configuration Values & State ======
local state = {
    AutoFavourite = false,
    AutoSell = false
}

local FishingState = {
	autoFish = false,
	perfectCast = true,
	delayInitialized = false
}

local AntiAFKState = {
	active = false
}

-- Auto Click Variables
local AutoClickState = {
    enabled = false,
    clickDelay = 0.1,
    lastValidDelay = 0.1,
    MIN_DELAY = 0.0002,
    SLOW_DOWN_DELAY = 5,
    HOVER_DELAY = 4,
    isHovering = false
}

-- Delay Bypass per pancing
local RodDelays = {
    ["Ares Rod"] = {bypass = 1.45},
    ["Angler Rod"] = {bypass = 1.45},
    ["Ghostfinn Rod"] = {bypass = 1.45},
    ["Astral Rod"] = {bypass = 1.45},
    ["Chrome Rod"] = {bypass = 2},
    ["Steampunk Rod"] = {bypass = 2.3},
    ["Lucky Rod"] = {bypass = 3.6},
    ["Midnight Rod"] = {bypass = 3.4},
    ["Demascus Rod"] = {bypass = 3.8},
    ["Grass Rod"] = {bypass = 3.9},
    ["Luck Rod"] = {bypass = 4.1},
    ["Carbon Rod"] = {bypass = 3.8},
    ["Lava Rod"] = {bypass = 4.1},
    ["Starter Rod"] = {bypass = 4.2},
}

-- Nilai Delay yang Digunakan
local BypassDelay = 4.2 -- Default delay starter rod bypass
local additionalWait = 0 -- No additional wait for maximum speed
local speedFactor = 1 -- Kecepatan normal

local lastSellTime = 0
local AUTO_SELL_THRESHOLD = 10
local AUTO_SELL_DELAY = 30

local allowedTiers = {
    ["Secret"] = true,
    ["Mythic"] = true,
    ["Legendary"] = true
}

-- */ Fishing Functions /* --
local function simulateClick()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
    wait(0.00001)
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
end

local function startAutoClick()
    task.spawn(function()
        while AutoClickState.enabled do
            local currentDelay = AutoClickState.isHovering and AutoClickState.HOVER_DELAY or AutoClickState.clickDelay
            simulateClick()
            wait(currentDelay)
        end
    end)
end

local function stopAutoClick()
    AutoClickState.enabled = false
end

local function getValidRodName()
    local player = Players.LocalPlayer
    local backpackDisplay = player.PlayerGui:FindFirstChild("Backpack", true) and player.PlayerGui.Backpack:FindFirstChild("Display", true)
    if not backpackDisplay then return nil end

    for _, tile in ipairs(backpackDisplay:GetChildren()) do
        local success, itemNamePath = pcall(function()
            return tile.Inner.Tags.ItemName
        end)
        if success and itemNamePath and itemNamePath:IsA("TextLabel") then
            local name = itemNamePath.Text
            if RodDelays[name] then
                return name
            end
        end
    end
    return nil
end

-- PERBAIKAN: Fix speed anjlok dari 4 ke 1
local function updateDelayBasedOnRod(showNotify)
    if FishingState.delayInitialized then 
        -- PERBAIKAN: Jangan reset kalau sudah initialized, kecuali rod berubah
        local currentRod = getValidRodName()
        if currentRod and RodDelays[currentRod] and RodDelays[currentRod].bypass == BypassDelay then
            return -- Rod sama, delay sama, skip update
        end
    end
    
    local rodName = getValidRodName()
    local newBypass = 4.2 -- Default
    
    if rodName and RodDelays[rodName] then
        newBypass = RodDelays[rodName].bypass
        print(string.format("Rod Detected: %s | Bypass Delay: %.2fs", rodName, newBypass))
    else
        print("Warning: Rod Detection Failed. Using Default Starter Rod bypass delay.")
    end
    
    -- PERBAIKAN: Pastikan delay tidak reset ke 1
    if newBypass ~= BypassDelay then
        BypassDelay = newBypass
        if showNotify then
            WindUI:Notify({
                Title = "Rod Detection",
                Content = string.format("Rod: %s | Delay: %.2fs", rodName or "Unknown", BypassDelay),
                Icon = "fishing-rod"
            })
        end
    end
    
    FishingState.delayInitialized = true
end

local function AdjustBypassDelay(delta)
    BypassDelay = math.max(0, BypassDelay + delta)
    print("Bypass Delay manually set to: " .. BypassDelay)
end

local function setupRodWatcher()
    local player = Players.LocalPlayer
    local backpackDisplay = player.PlayerGui:FindFirstChild("Backpack", true) and player.PlayerGui.Backpack:FindFirstChild("Display", true)
    if backpackDisplay then
        local function checkRodChange()
            task.wait(0.5)
            if not FishingState.delayInitialized then
                updateDelayBasedOnRod(true)
            end
        end
        backpackDisplay.ChildAdded:Connect(checkRodChange)
        backpackDisplay.ChildRemoved:Connect(checkRodChange)
    else
        warn("Backpack Display not found, rod watcher disabled.")
    end
end

local function startAutoSell()
    task.spawn(function()
        while state.AutoSell do
            pcall(function()
                if not game:GetService("CoreGui"):FindFirstChild("Replion") then task.wait(5); return end
                local Replion = require(game:GetService("CoreGui").Replion)
                if not Replion then return end

                local DataReplion = Replion.Client:WaitReplion("Data", 10)
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                if type(items) ~= "table" then return end

                local unfavoritedCount = 0
                for _, item in ipairs(items) do
                    if not item.Favorited then
                        unfavoritedCount = unfavoritedCount + (item.Count or 1)
                    end
                end

                print("Auto Sell Debug: Unfavorited items count: " .. unfavoritedCount .. " | Threshold: " .. AUTO_SELL_THRESHOLD .. " | Time since last sell: " .. (os.time() - lastSellTime) .. " | Delay: " .. AUTO_SELL_DELAY)

                if unfavoritedCount >= AUTO_SELL_THRESHOLD and os.time() - lastSellTime >= AUTO_SELL_DELAY then
                    print("Auto Sell: Triggering sell...")
                    sellAllFishes()
                    lastSellTime = os.time()
                end
            end)
            task.wait(10)
        end
    end)
end

local function startAutoFavourite()
    task.spawn(function()
        while state.AutoFavourite do
            pcall(function()
                 if not game:GetService("CoreGui"):FindFirstChild("Replion") then task.wait(5); return end
                 if not game:GetService("ReplicatedStorage"):FindFirstChild("ItemUtility") then task.wait(5); return end

                 local Replion = require(game:GetService("CoreGui").Replion)
                 local ItemUtility = require(game:GetService("ReplicatedStorage").ItemUtility)
                 if not Replion or not ItemUtility then return end

                 local DataReplion = Replion.Client:WaitReplion("Data", 10)
                 local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                 if type(items) ~= "table" then return end

                 for _, item in ipairs(items) do
                     local base = ItemUtility:GetItemData(item.Id)
                     if base and base.Data and allowedTiers[base.Data.Tier] and not item.Favorited then
                         item.Favorited = true
                         print("Auto Favorited: " .. (base.Name or item.Id))
                     end
                 end
            end)
            task.wait(5)
        end
    end)
end

function StartAutoFish()
    if FishingState.autoFish then return end

    FishingState.autoFish = true
    FishingState.delayInitialized = false
    updateDelayBasedOnRod(true)
    task.spawn(function()
        while FishingState.autoFish do
            pcall(function()
                print("🎣 Starting new fishing cycle...")

                -- 1. Equip (skip if already holding tool)
                if not LocalPlayer.Character:FindFirstChildOfClass("Tool") then
                    EquipToolRE:FireServer(1)
                    task.wait(0.2)
                end

                -- 2. Charge
                ChargeRodRF:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.5)

                -- 3. Cast
                local timestamp = workspace:GetServerTimeNow()
                ChargeRodRF:InvokeServer(timestamp)
                print("  -> Casting rod...")

                -- 4. Send Minigame Result
                local x, y
                local baseX, baseY = 0.0, 1.0
                if FishingState.perfectCast then
                    x = baseX + (math.random(-500, 500) / 10000000)
                    y = baseY + (math.random(-500, 500) / 10000000)
                else
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                end
                RequestMinigameRF:InvokeServer(x, y)
                print("  -> Minigame result sent.")

                -- 5. Wait for Catch Time
                local effectiveBypass = BypassDelay / speedFactor + (math.random(-50, 50)/1000)
                print(string.format("  -> Waiting %.2fs for bite (based on Bypass: %.2fs)...", effectiveBypass, BypassDelay))
                task.wait(effectiveBypass)

                -- 6. Tunggu Jeda Tambahan Singkat
                task.wait(additionalWait)

                -- 7. Send Catch Confirmation and Immediate Recast berbarengan
                FishingCompletedRE:FireServer()
                print("✅ Fish Caught!")

                -- Immediate recast berbarengan tanpa delay
                task.spawn(function()
                    if not LocalPlayer.Character:FindFirstChildOfClass("Tool") then
                        EquipToolRE:FireServer(1)
                        task.wait(0.1) -- Reduced delay
                    end
                    ChargeRodRF:InvokeServer(workspace:GetServerTimeNow())
                    task.wait(0.3) -- Reduced delay
                    local timestamp = workspace:GetServerTimeNow()
                    ChargeRodRF:InvokeServer(timestamp)
                    print("  -> Immediate Casting rod...")
                    local x, y
                    local baseX, baseY = 0.0, 1.0
                    if FishingState.perfectCast then
                        x = baseX + (math.random(-500, 500) / 10000000)
                        y = baseY + (math.random(-500, 500) / 10000000)
                    else
                        x = math.random(-1000, 1000) / 1000
                        y = math.random(0, 1000) / 1000
                    end
                    RequestMinigameRF:InvokeServer(x, y)
                    print("  -> Minigame result sent.")
                    local effectiveBypass = BypassDelay / speedFactor + (math.random(-50, 50)/1000)
                    print(string.format("  -> Waiting %.2fs for bite (based on Bypass: %.2fs)...", effectiveBypass, BypassDelay))
                    task.wait(effectiveBypass)
                    FishingCompletedRE:FireServer()
                    print("✅ Immediate Fish Caught!")
                end)

            end)
            task.wait(0.1) -- Reduced delay for faster cycles
        end
        print("🛑 Auto Fish Stopped.")
        StopAutoFish()
    end)
end

function StopAutoFish()
    FishingState.autoFish = false
    FishingState.delayInitialized = false
    if RodIdleAnim then RodIdleAnim:Stop() end
    if RodShakeAnim then RodShakeAnim:Stop() end
    if RodReelAnim then RodReelAnim:Stop() end
end

function sellAllFishes()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		print("Error: Character HRP not found for selling.")
		return
	end

	task.spawn(function()
		print("💸 Selling all fish...")
		task.wait(1)
		local success, result = pcall(function()
			return SellAllItemsRF:InvokeServer()
		end)

		if success then
			print("✅ All non-favorited fish sold successfully!")
		else
			print("❌ Sell Failed: " .. tostring(result))
		end
	end)
end

function autoEnchantRod()
    local ENCHANT_POSITION = Vector3.new(3231, -1303, 1402)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        print("Error: Failed to get character HRP for enchanting.")
        return
    end

    print("Info: Please manually place Enchant Stone into slot 5 before we begin...")
    task.wait(3)

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local backpackDisplay = PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    local children = backpackDisplay:GetChildren()
    local slot5 = nil
    for _, child in ipairs(children) do
        if child:FindFirstChild("Order") and child.Order.Value == 5 then
            slot5 = child
            break
        end
    end
    if not slot5 and #children >= 5 then slot5 = children[5] end

    local itemName = slot5 and slot5:FindFirstChild("Inner") and slot5.Inner:FindFirstChild("Tags") and slot5.Inner.Tags:FindFirstChild("ItemName")

    if not itemName or not itemName.Text or not string.lower(itemName.Text):find("enchant") then
        print("Error: Slot 5 does not contain an Enchant Stone.")
        return
    end

    print("Info: Enchanting in progress, please wait...")

    local originalPosition = hrp.CFrame
    task.wait(1)
    hrp.CFrame = CFrame.new(ENCHANT_POSITION + Vector3.new(0, 5, 0))
    task.wait(1.2)

    pcall(function()
        EquipToolRE:FireServer(5)
        task.wait(0.5)
        ActivateEnchantingAltarRE:FireServer()
        task.wait(7)
        print("Success: Successfully Enchanted!")
    end)

    task.wait(0.9)
    hrp.CFrame = originalPosition * CFrame.new(0, 3, 0)
end

local function AutoReconnect()
    while task.wait(5) do
        if not Players.LocalPlayer or not Players.LocalPlayer:IsDescendantOf(game) then
            print("Detected disconnect, attempting to reconnect...")
            TeleportService:Teleport(game.PlaceId)
        end
    end
end

local function BoostFPS()
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end

    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e10

    settings().Rendering.QualityLevel = "Level01"
    print("FPS Boost applied.")
end

-- */ Teleport Functions /* --
local function GetPlayerList()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    return playerList
end

-- PERBAIKAN: Fix auto teleport saat GUI load
local function TeleportToPlayer(playerName)
    -- PERBAIKAN: Validasi input dan pastikan bukan auto-trigger
    if not playerName or playerName == "" or playerName == "Select Player" then
        print("❌ Invalid player name")
        return
    end
    
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer then
        print("❌ Player not found: " .. playerName)
        return
    end
    
    -- PERBAIKAN: Tambah validasi character
    local targetChar = targetPlayer.Character
    local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP then
        print("❌ Target player HRP not found.")
        return
    end
    
    local localChar = LocalPlayer.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then
        print("❌ Local player HRP not found.")
        return
    end
    
    localHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
    print("🚀 Teleported to: " .. playerName)
end

local function TeleportToWaypoint(waypointKey)
    local waypoint = islandCoords[waypointKey]
    if not waypoint then
        print("❌ Waypoint not found: " .. waypointKey)
        return
    end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        print("❌ HumanoidRootPart not found.")
        return
    end
    hrp.CFrame = CFrame.new(waypoint.position + Vector3.new(0, 5, 0))
    print("🚀 Teleported to: " .. waypoint.name)
end

-- */ Anti-AFK Functions /* --
local function StartAntiAFK()
    if AntiAFKState.active then return end
    AntiAFKState.active = true
    task.spawn(function()
        while AntiAFKState.active do
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local humanoid = char and char:FindFirstChild("Humanoid")
                if hrp and humanoid then
                    local originalPos = hrp.Position
                    local originalCFrame = hrp.CFrame

                    local moveDirection = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit * 0.5
                    hrp.CFrame = hrp.CFrame * CFrame.new(moveDirection)
                    task.wait(0.2)

                    if math.random(1, 5) == 1 then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        task.wait(0.5)
                    end

                    hrp.CFrame = CFrame.new(originalPos) * (originalCFrame - originalCFrame.Position)
                    task.wait(0.2)
                end
            end)
            task.wait(math.random(45, 75))
        end
    end)
    print("🛡️ Advanced Anti-AFK activated.")
end

local function StopAntiAFK()
    AntiAFKState.active = false
    print("🛡️ Anti-AFK deactivated.")
end

-- */  Window  /* --
local Window = WindUI:CreateWindow({
    Title = "RyDev Fishing Hub  |  WindUI",
    Author = "by RyDev • Modified by Ry",
    Folder = "RyDevfishing",
    NewElements = true,
    
    HideSearchBar = false,
    
    OpenButton = {
        Title = "Open RyDev Fishing Hub",
        CornerRadius = UDim.new(1,0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"), 
            Color3.fromHex("#e7ff2f")
        )
    }
})

-- */  Tags  /* --
do
    Window:Tag({
        Title = "v" .. WindUI.Version,
        Icon = "github",
        Color = Color3.fromHex("#6b31ff")
    })
end

-- */  Theme  /* --
do
    WindUI:AddTheme({
        Name = "RyDevFishing",
        
        Accent = Color3.fromHex("#3b82f6"), 
        Dialog = Color3.fromHex("#1a1a1a"), 
        Outline = Color3.fromHex("#3b82f6"),
        Text = Color3.fromHex("#f8fafc"),  
        Placeholder = Color3.fromHex("#94a3b8"),
        Button = Color3.fromHex("#334155"), 
        Icon = Color3.fromHex("#60a5fa"), 
        
        WindowBackground = Color3.fromHex("#0f172a"),
        
        TopbarButtonIcon = Color3.fromHex("#60a5fa"),
        TopbarTitle = Color3.fromHex("#f8fafc"),
        TopbarAuthor = Color3.fromHex("#94a3b8"),
        TopbarIcon = Color3.fromHex("#3b82f6"),
        
        TabBackground = Color3.fromHex("#1e293b"),    
        TabTitle = Color3.fromHex("#f8fafc"),
        TabIcon = Color3.fromHex("#60a5fa"),
        
        ElementBackground = Color3.fromHex("#1e293b"),
        ElementTitle = Color3.fromHex("#f8fafc"),
        ElementDesc = Color3.fromHex("#cbd5e1"),
        ElementIcon = Color3.fromHex("#60a5fa"),
    })
    
    WindUI:SetTheme("RyDevFishing")
end

-- */ Other Functions /* --
local function parseJSON(luau_table, indent, level, visited)
    indent = indent or 2
    level = level or 0
    visited = visited or {}
    
    local currentIndent = string.rep(" ", level * indent)
    local nextIndent = string.rep(" ", (level + 1) * indent)
    
    if luau_table == nil then
        return "null"
    end
    
    local dataType = type(luau_table)
    
    if dataType == "table" then
        if visited[luau_table] then
            return "\"[Circular Reference]\""
        end
        
        visited[luau_table] = true
        
        local isArray = true
        local maxIndex = 0
        
        for k, _ in pairs(luau_table) do
            if type(k) == "number" and k > maxIndex then
                maxIndex = k
            end
            if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
                isArray = false
                break
            end
        end
        
        local count = 0
        for _ in pairs(luau_table) do
            count = count + 1
        end
        if count ~= maxIndex and isArray then
            isArray = false
        end
        
        if count == 0 then
            return "{}"
        end
        
        if isArray then
            if count == 0 then
                return "[]"
            end
            
            local result = "[\n"
            
            for i = 1, maxIndex do
                result = result .. nextIndent .. parseJSON(luau_table[i], indent, level + 1, visited)
                if i < maxIndex then
                    result = result .. ","
                end
                result = result .. "\n"
            end
            
            result = result .. currentIndent .. "]"
            return result
        else
            local result = "{\n"
            local first = true
            
            local keys = {}
            for k in pairs(luau_table) do
                table.insert(keys, k)
            end
            table.sort(keys, function(a, b)
                if type(a) == type(b) then
                    return tostring(a) < tostring(b)
                else
                    return type(a) < type(b)
                end
            end)
            
            for _, k in ipairs(keys) do
                local v = luau_table[k]
                if not first then
                    result = result .. ",\n"
                else
                    first = false
                end
                
                if type(k) == "string" then
                    result = result .. nextIndent .. "\"" .. k .. "\": "
                else
                    result = result .. nextIndent .. "\"" .. tostring(k) .. "\": "
                end
                
                result = result .. parseJSON(v, indent, level + 1, visited)
            end
            
            result = result .. "\n" .. currentIndent .. "}"
            return result
        end
    elseif dataType == "string" then
        local escaped = luau_table:gsub("\\", "\\\\")
        escaped = escaped:gsub("\"", "\\\"")
        escaped = escaped:gsub("\n", "\\n")
        escaped = escaped:gsub("\r", "\\r")
        escaped = escaped:gsub("\t", "\\t")
        
        return "\"" .. escaped .. "\""
    elseif dataType == "number" then
        return tostring(luau_table)
    elseif dataType == "boolean" then
        return luau_table and "true" or "false"
    elseif dataType == "function" then
        return "\"function\""
    else
        return "\"" .. dataType .. "\""
    end
end

local function tableToClipboard(luau_table, indent)
    indent = indent or 4
    local jsonString = parseJSON(luau_table, indent)
    setclipboard(jsonString)
    return jsonString
end

-- */  Auto Fishing Tab  /* --
do
    local AutoFishingTab = Window:Tab({
        Title = "Auto Fishing",
        Icon = "fish",
    })
    
    local AutoFishingSection = AutoFishingTab:Section({
        Title = "Auto Fishing Settings",
    })
    
    -- Status Indicator
    local statusText = "Status: " .. (FishingState.autoFish and "Aktif" or "Nonaktif")
    local statusColor = FishingState.autoFish and Color3.fromHex("#30ff6a") or Color3.fromHex("#ff3040")
    
    AutoFishingSection:Section({
        Title = statusText,
        TextColor = statusColor,
        TextSize = 18,
        FontWeight = Enum.FontWeight.SemiBold,
    })
    
    AutoFishingSection:Space()
    
    -- Main Toggle Button
    AutoFishingSection:Button({
        Title = FishingState.autoFish and "Stop Auto Fishing" or "Start Auto Fishing",
        Desc = "Mulai atau hentikan auto fishing otomatis",
        Color = FishingState.autoFish and Color3.fromHex("#ff3040") or Color3.fromHex("#30ff6a"),
        Icon = FishingState.autoFish and "stop-circle" or "play-circle",
        Callback = function()
            if FishingState.autoFish then
                StopAutoFish()
                WindUI:Notify({
                    Title = "Auto Fishing",
                    Content = "Auto Fishing Dihentikan!",
                    Icon = "stop-circle"
                })
            else
                StartAutoFish()
                WindUI:Notify({
                    Title = "Auto Fishing",
                    Content = "Auto Fishing Dimulai!",
                    Icon = "play-circle"
                })
            end
        end
    })
    
    AutoFishingSection:Space()
    
    -- Perfect Cast Toggle
    AutoFishingSection:Toggle({
        Title = "Perfect Cast",
        Desc = "Aktifkan cast sempurna untuk hasil maksimal",
        Default = FishingState.perfectCast,
        Callback = function(value)
            FishingState.perfectCast = value
            if value then
                WindUI:Notify({
                    Title = "Perfect Cast",
                    Content = "Perfect Cast Diaktifkan!",
                    Icon = "target"
                })
            else
                WindUI:Notify({
                    Title = "Perfect Cast",
                    Content = "Perfect Cast Dinonaktifkan!",
                    Icon = "circle"
                })
            end
        end
    })
    
    AutoFishingSection:Space()
    
    -- Bypass Delay Controls
    AutoFishingSection:Section({
        Title = "Bypass Delay Settings",
        TextSize = 16,
        FontWeight = Enum.FontWeight.SemiBold,
    })
    
    AutoFishingSection:Section({
        Title = string.format("Current Bypass Delay: %.2fs", BypassDelay),
        TextSize = 14,
        TextTransparency = 0.5,
    })
    
    AutoFishingSection:Button({
        Title = "- 0.1s",
        Desc = "Kurangi bypass delay",
        Color = Color3.fromHex("#ff6b35"),
        Callback = function()
            AdjustBypassDelay(-0.1)
            WindUI:Notify({
                Title = "Bypass Delay",
                Content = string.format("Bypass Delay: %.2fs", BypassDelay),
                Icon = "minus"
            })
        end
    })
    
    AutoFishingSection:Button({
        Title = "+ 0.1s",
        Desc = "Tambah bypass delay",
        Color = Color3.fromHex("#4CAF50"),
        Callback = function()
            AdjustBypassDelay(0.1)
            WindUI:Notify({
                Title = "Bypass Delay",
                Content = string.format("Bypass Delay: %.2fs", BypassDelay),
                Icon = "plus"
            })
        end
    })
    
    AutoFishingSection:Space()
    
    -- Additional Wait Input
    AutoFishingSection:Input({
        Title = "Additional Wait",
        Desc = "Waktu tambahan setelah bite (detik)",
        Value = tostring(additionalWait),
        Callback = function(value)
            local number = tonumber(value)
            if number and number >= 0 then
                additionalWait = number
                WindUI:Notify({
                    Title = "Additional Wait",
                    Content = string.format("Set to: %.2fs", additionalWait),
                    Icon = "clock"
                })
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Invalid input!",
                    Icon = "alert-triangle"
                })
            end
        end
    })
end

-- */  Auto Features Tab  /* --
do
    local AutoFeaturesTab = Window:Tab({
        Title = "Auto Features",
        Icon = "zap",
    })
    
    local AutoSellSection = AutoFeaturesTab:Section({
        Title = "Auto Sell Settings",
    })
    
    -- Auto Sell Toggle
    AutoSellSection:Toggle({
        Title = "Auto Sell",
        Desc = "Otomatis jual ikan non-favorit",
        Default = state.AutoSell,
        Callback = function(value)
            state.AutoSell = value
            if value then
                startAutoSell()
                WindUI:Notify({
                    Title = "Auto Sell",
                    Content = "Auto Sell Diaktifkan!",
                    Icon = "shopping-cart"
                })
            else
                WindUI:Notify({
                    Title = "Auto Sell",
                    Content = "Auto Sell Dinonaktifkan!",
                    Icon = "shopping-cart"
                })
            end
        end
    })
    
    AutoSellSection:Space()
    
    -- Auto Favourite Toggle
    AutoSellSection:Toggle({
        Title = "Auto Favourite",
        Desc = "Otomatis favoritkan item tier tinggi",
        Default = state.AutoFavourite,
        Callback = function(value)
            state.AutoFavourite = value
            if value then
                startAutoFavourite()
                WindUI:Notify({
                    Title = "Auto Favourite",
                    Content = "Auto Favourite Diaktifkan!",
                    Icon = "star"
                })
            else
                WindUI:Notify({
                    Title = "Auto Favourite",
                    Content = "Auto Favourite Dinonaktifkan!",
                    Icon = "star"
                })
            end
        end
    })
    
    AutoSellSection:Space()
    
    -- Manual Actions
    AutoSellSection:Button({
        Title = "Sell All Fish",
        Desc = "Jual semua ikan non-favorit",
        Color = Color3.fromHex("#FF9800"),
        Icon = "dollar-sign",
        Callback = function()
            sellAllFishes()
            WindUI:Notify({
                Title = "Sell All",
                Content = "Menjual semua ikan...",
                Icon = "dollar-sign"
            })
        end
    })
    
    AutoSellSection:Button({
        Title = "Auto Enchant Rod",
        Desc = "Otomatis enchant fishing rod",
        Color = Color3.fromHex("#9C27B0"),
        Icon = "wand",
        Callback = function()
            autoEnchantRod()
            WindUI:Notify({
                Title = "Auto Enchant",
                Content = "Memulai proses enchant...",
                Icon = "wand"
            })
        end
    })
end

-- */  Teleport Tab  /* --
do
    local TeleportTab = Window:Tab({
        Title = "Teleport",
        Icon = "map-pin",
    })
    
    local WaypointsSection = TeleportTab:Section({
        Title = "Waypoints",
    })
    
    -- Waypoints Grid
    local waypointKeys = {}
    for key in pairs(islandCoords) do
        table.insert(waypointKeys, key)
    end
    table.sort(waypointKeys)
    
    for _, key in ipairs(waypointKeys) do
        local waypoint = islandCoords[key]
        WaypointsSection:Button({
            Title = key .. ": " .. waypoint.name,
            Desc = "Teleport ke " .. waypoint.name,
            Color = Color3.fromHex("#2196F3"),
            Callback = function()
                TeleportToWaypoint(key)
                WindUI:Notify({
                    Title = "Teleport",
                    Content = "Teleport ke: " .. waypoint.name,
                    Icon = "map-pin"
                })
            end
        })
    end
    
    TeleportTab:Space({ Columns = 2 })
    
    local PlayerTeleportSection = TeleportTab:Section({
        Title = "Player Teleport",
    })
    
    -- Variable untuk menyimpan dropdown element
    local playerDropdownElement = nil
    
    -- Function untuk update player list - FIX REAL-TIME
    local function updatePlayerDropdown()
        local newPlayerList = GetPlayerList()
        local newDropdownValues = {}
        
        for _, playerName in ipairs(newPlayerList) do
            table.insert(newDropdownValues, {
                Title = playerName,
                Icon = "user"
            })
        end
        
        -- Update dropdown dengan values baru
        if playerDropdownElement then
            playerDropdownElement:SetValues(newDropdownValues)
            -- JANGAN otomatis set value ke player pertama
        end
        
        return #newPlayerList
    end
    
    -- Player List Dropdown
    local playerList = GetPlayerList()
    local playerDropdownValues = {}
    for _, playerName in ipairs(playerList) do
        table.insert(playerDropdownValues, {
            Title = playerName,
            Icon = "user"
        })
    end
    
    -- PERBAIKAN: Gunakan placeholder default, bukan player pertama
    local defaultDropdownValue = {Title = "Pilih Player", Icon = "user"}
    
    if #playerDropdownValues > 0 then
        playerDropdownElement = PlayerTeleportSection:Dropdown({
            Title = "Select Player",
            Desc = "Pilih player untuk teleport",
            Values = playerDropdownValues,
            Value = defaultDropdownValue, -- GUNAKAN PLACEHOLDER, BUKAN PLAYER PERTAMA
            Callback = function(option)
                -- PERBAIKAN: Validasi untuk cegah auto-teleport
                if option.Title ~= "Pilih Player" and option.Title ~= "" then
                    TeleportToPlayer(option.Title)
                    WindUI:Notify({
                        Title = "Teleport",
                        Content = "Teleport ke: " .. option.Title,
                        Icon = "user"
                    })
                end
            end
        })
    else
        playerDropdownElement = PlayerTeleportSection:Dropdown({
            Title = "Select Player",
            Desc = "Pilih player untuk teleport",
            Values = {defaultDropdownValue},
            Value = defaultDropdownValue,
            Callback = function(option)
                -- Do nothing if no players
            end
        })
    end
    
    -- PERBAIKAN: Refresh Player List yang benar-benar REAL-TIME
    PlayerTeleportSection:Button({
        Title = "Refresh Player List",
        Desc = "Refresh daftar player secara real-time",
        Color = Color3.fromHex("#4CAF50"),
        Icon = "refresh-cw",
        Callback = function()
            local playerCount = updatePlayerDropdown()
            WindUI:Notify({
                Title = "Player List", 
                Content = playerCount > 0 and ("Player list refreshed! " .. playerCount .. " players found") or "No other players found",
                Icon = "refresh-cw"
            })
        end
    })
    
    -- REAL-TIME AUTO REFRESH SYSTEM
    local function setupRealTimePlayerTracker()
        -- Auto refresh setiap 5 detik
        task.spawn(function()
            while task.wait(5) do
                if playerDropdownElement then
                    updatePlayerDropdown()
                end
            end
        end)
        
        -- Player join event
        Players.PlayerAdded:Connect(function(player)
            if player ~= LocalPlayer then
                task.wait(2) -- Tunggu player fully loaded
                if playerDropdownElement then
                    updatePlayerDropdown()
                end
            end
        end)
        
        -- Player leave event  
        Players.PlayerRemoving:Connect(function(player)
            if player ~= LocalPlayer then
                if playerDropdownElement then
                    updatePlayerDropdown()
                end
            end
        end)
    end
    
    -- Start real-time tracker
    setupRealTimePlayerTracker()
end

-- */  Utilities Tab  /* --
do
    local UtilitiesTab = Window:Tab({
        Title = "Utilities",
        Icon = "settings",
    })
    
    local AFKSection = UtilitiesTab:Section({
        Title = "Anti-AFK",
    })
    
    -- Anti-AFK Toggle
    AFKSection:Toggle({
        Title = "Anti-AFK",
        Desc = "Mencegah AFK detection",
        Default = AntiAFKState.active,
        Callback = function(value)
            AntiAFKState.active = value
            if value then
                StartAntiAFK()
                WindUI:Notify({
                    Title = "Anti-AFK",
                    Content = "Anti-AFK Diaktifkan!",
                    Icon = "shield"
                })
            else
                StopAntiAFK()
                WindUI:Notify({
                    Title = "Anti-AFK",
                    Content = "Anti-AFK Dinonaktifkan!",
                    Icon = "shield"
                })
            end
        end
    })
    
    UtilitiesTab:Space({ Columns = 2 })
    
    local ClickerSection = UtilitiesTab:Section({
        Title = "Auto Clicker",
    })
    
    -- Auto Click Toggle
    ClickerSection:Toggle({
        Title = "Auto Click",
        Desc = "Otomatis klik mouse",
        Default = AutoClickState.enabled,
        Callback = function(value)
            AutoClickState.enabled = value
            if value then
                startAutoClick()
                WindUI:Notify({
                    Title = "Auto Click",
                    Content = "Auto Click Diaktifkan!",
                    Icon = "mouse-pointer"
                })
            else
                stopAutoClick()
                WindUI:Notify({
                    Title = "Auto Click",
                    Content = "Auto Click Dinonaktifkan!",
                    Icon = "mouse-pointer"
                })
            end
        end
    })
    
    -- Click Delay Input
    ClickerSection:Input({
        Title = "Click Delay",
        Desc = string.format("Delay antara klik (min %.4f)", AutoClickState.MIN_DELAY),
        Value = string.format("%.4f", AutoClickState.clickDelay),
        Callback = function(value)
            local number = tonumber(value)
            if number and number >= AutoClickState.MIN_DELAY then
                AutoClickState.clickDelay = number
                AutoClickState.lastValidDelay = number
                WindUI:Notify({
                    Title = "Click Delay",
                    Content = string.format("Set to: %.4fs", AutoClickState.clickDelay),
                    Icon = "clock"
                })
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = string.format("Minimum delay is %.4f", AutoClickState.MIN_DELAY),
                    Icon = "alert-triangle"
                })
            end
        end
    })
    
    UtilitiesTab:Space({ Columns = 2 })
    
    local PerformanceSection = UtilitiesTab:Section({
        Title = "Performance",
    })
    
    -- FPS Boost Button
    PerformanceSection:Button({
        Title = "Boost FPS",
        Desc = "Optimasi performa game",
        Color = Color3.fromHex("#FF5722"),
        Icon = "zap",
        Callback = function()
            BoostFPS()
            WindUI:Notify({
                Title = "FPS Boost",
                Content = "FPS boost applied!",
                Icon = "zap"
            })
        end
    })
    
    -- Auto Reconnect Toggle
    PerformanceSection:Toggle({
        Title = "Auto Reconnect",
        Desc = "Otomatis reconnect jika disconnect",
        Default = true,
        Callback = function(value)
            if value then
                task.spawn(AutoReconnect)
                WindUI:Notify({
                    Title = "Auto Reconnect",
                    Content = "Auto Reconnect Diaktifkan!",
                    Icon = "wifi"
                })
            else
                WindUI:Notify({
                    Title = "Auto Reconnect",
                    Content = "Auto Reconnect Dinonaktifkan!",
                    Icon = "wifi-off"
                })
            end
        end
    })
end

-- */  About Tab  /* --
do
    local AboutTab = Window:Tab({
        Title = "About",
        Icon = "info",
    })
    
    local AboutSection = AboutTab:Section({
        Title = "RyDev Fishing Hub",
    })
    
    AboutSection:Section({
        Title = [[RyDev Fishing Hub adalah script auto fishing lengkap dengan berbagai fitur:
• Auto Fishing dengan bypass delay
• Perfect Cast mode
• Auto Sell & Auto Favourite
• Teleport Waypoints & Player
• Anti-AFK System
• Auto Clicker
• FPS Boost]],
        TextSize = 16,
        TextTransparency = .35,
        FontWeight = Enum.FontWeight.Medium,
    })
    
    AboutTab:Space({ Columns = 4 })
    
    AboutTab:Button({
        Title = "Setup Rod Watcher",
        Color = Color3.fromHex("#a2ff30"),
        Justify = "Center",
        Icon = "eye",
        Callback = function()
            setupRodWatcher()
            WindUI:Notify({
                Title = "Rod Watcher",
                Content = "Rod detection activated!",
                Icon = "eye"
            })
        end
    })
    
    AboutTab:Space({ Columns = 1 })
    
    AboutTab:Button({
        Title = "Export Config JSON",
        Color = Color3.fromHex("#30a2ff"),
        Justify = "Center",
        Icon = "copy",
        Callback = function()
            local config = {
                FishingState = FishingState,
                AutoClickState = AutoClickState,
                BypassDelay = BypassDelay,
                additionalWait = additionalWait
            }
            tableToClipboard(config)
            WindUI:Notify({
                Title = "Config JSON",
                Content = "Copied to Clipboard!"
            })
        end
    })
    
    AboutTab:Space({ Columns = 1 })
    
    AboutTab:Button({
        Title = "Destroy Window",
        Color = Color3.fromHex("#ff4830"),
        Justify = "Center",
        Icon = "shredder",
        Callback = function()
            Window:Destroy()
            WindUI:Notify({
                Title = "Window Destroyed",
                Content = "RyDev Fishing Hub closed!",
                Icon = "shredder"
            })
        end
    })
end

-- */ Initialize Systems /* --
do
    -- Setup rod detection
    setupRodWatcher()
    
    -- Apply FPS boost
    BoostFPS()
    
    -- Start auto reconnect
    task.spawn(AutoReconnect)
    
    print("--- RyDev Fishing Hub dengan WindUI Aktif ---")
    WindUI:Notify({
        Title = "RyDev Fishing Hub",
        Content = "Successfully loaded!",
        Icon = "check"
    })
end
