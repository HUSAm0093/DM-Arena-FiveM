local lobbies = {}
local playerLobbies = {}

local weaponList = {
    {name = "Пистолет Mk II", hash = "WEAPON_PISTOL_MK2"},
    {name = "Боевой пистолет Mk II", hash = "WEAPON_COMBATPISTOL_MK2"},
    {name = "AP Пистолет Mk II", hash = "WEAPON_APPISTOL_MK2"},
    {name = "ПП Mk II", hash = "WEAPON_SMG_MK2"},
    {name = "Штурмовая винтовка Mk II", hash = "WEAPON_ASSAULTRIFLE_MK2"},
    {name = "Карабин Mk II", hash = "WEAPON_CARBINERIFLE_MK2"},
    {name = "Продвинутая винтовка Mk II", hash = "WEAPON_ADVANCEDRIFLE_MK2"},
    {name = "Пулемет Mk II", hash = "WEAPON_MG_MK2"},
    {name = "Боевой пулемет Mk II", hash = "WEAPON_COMBATMG_MK2"},
    {name = "Дробовик Mk II", hash = "WEAPON_PUMPSHOTGUN_MK2"},
    {name = "Снайперская винтовка Mk II", hash = "WEAPON_SNIPERRIFLE_MK2"},
    {name = "Тяжелый снайпер Mk II", hash = "WEAPON_HEAVYSNIPER_MK2"}
}

local function generateLobbyId()
    local id = ""
    for i = 1, 6 do
        id = id .. string.char(math.random(65, 90))
    end
    return id
end

local function getWeaponName(hash)
    for _, weapon in ipairs(weaponList) do
        if weapon.hash == hash then
            return weapon.name
        end
    end
    return "Неизвестно"
end

local function getLobbyArray()
    local lobbyArray = {}
    for lobbyId, lobby in pairs(lobbies) do
        local playersWithNames = {}
        for _, playerId in ipairs(lobby.players) do
            for _, id in ipairs(GetPlayers()) do
                if GetPlayerIdentifier(id, 0) == playerId then
                    table.insert(playersWithNames, GetPlayerName(id))
                end
            end
        end
        lobby.playersNames = playersWithNames
        table.insert(lobbyArray, lobby)
    end
    return lobbyArray
end

local function removePlayerFromLobbies(playerId)
    for lobbyId, lobby in pairs(lobbies) do
        for i, player in ipairs(lobby.players) do
            if player == playerId then
                table.remove(lobby.players, i)
                table.remove(lobby.playersNames, i)
                if lobby.leader == playerId and #lobby.players > 0 then
                    lobby.leader = lobby.players[1]
                end
                break
            end
        end
        if #lobby.players == 0 then
            lobbies[lobbyId] = nil
        end
    end
    TriggerClientEvent("dmArena:updateLobbies", -1, getLobbyArray(), weaponList)
end

RegisterNetEvent("dmArena:getLobbies")
AddEventHandler("dmArena:getLobbies", function()
    local src = source
    TriggerClientEvent("dmArena:updateLobbies", src, getLobbyArray(), weaponList)
end)

RegisterNetEvent("dmArena:createLobby")
AddEventHandler("dmArena:createLobby", function(weapon, duration)
    local src = source
    local playerId = GetPlayerIdentifier(src, 0)
    
    removePlayerFromLobbies(playerId)
    
    local lobbyId = generateLobbyId()
    lobbies[lobbyId] = {
        id = lobbyId,
        weapon = weapon,
        weaponName = getWeaponName(weapon),
        duration = tonumber(duration),
        players = {playerId},
        playersNames = {GetPlayerName(src)},
        leader = playerId,
        started = false
    }
    
    playerLobbies[playerId] = lobbyId
    TriggerClientEvent("dmArena:joinedLobby", src, lobbies[lobbyId], true)
    TriggerClientEvent("dmArena:updateLobbies", -1, getLobbyArray(), weaponList)
end)

RegisterNetEvent("dmArena:joinLobby")
AddEventHandler("dmArena:joinLobby", function(lobbyId)
    local src = source
    local playerId = GetPlayerIdentifier(src, 0)
    
    if not lobbies[lobbyId] then
        TriggerClientEvent("chat:addMessage", src, {args = {"DM Арена", "Лобби не найдено!"}})
        return
    end
    
    if lobbies[lobbyId].started then
        TriggerClientEvent("chat:addMessage", src, {args = {"DM Арена", "Игра уже началась!"}})
        return
    end
    
    if #lobbies[lobbyId].players >= 10 then -- Изменено с 2 на 10
        TriggerClientEvent("chat:addMessage", src, {args = {"DM Арена", "Лобби заполнено!"}})
        return
    end
    
    removePlayerFromLobbies(playerId)
    table.insert(lobbies[lobbyId].players, playerId)
    table.insert(lobbies[lobbyId].playersNames, GetPlayerName(src))
    playerLobbies[playerId] = lobbyId
    
    for _, player in ipairs(lobbies[lobbyId].players) do
        for _, id in ipairs(GetPlayers()) do
            if GetPlayerIdentifier(id, 0) == player then
                TriggerClientEvent("dmArena:joinedLobby", id, lobbies[lobbyId], player == lobbies[lobbyId].leader)
            end
        end
    end
    TriggerClientEvent("dmArena:updateLobbies", -1, getLobbyArray(), weaponList)
end)

RegisterNetEvent("dmArena:startGame")
AddEventHandler("dmArena:startGame", function(lobbyId)
    local src = source
    local playerId = GetPlayerIdentifier(src, 0)
    
    if not lobbies[lobbyId] then
        TriggerClientEvent("chat:addMessage", src, {args = {"DM Арена", "Лобби не существует!"}})
        return
    end
    
    if lobbies[lobbyId].leader ~= playerId then
        TriggerClientEvent("chat:addMessage", src, {args = {"DM Арена", "Только лидер может начать игру!"}})
        return
    end
    
    if #lobbies[lobbyId].players < 2 then
        TriggerClientEvent("chat:addMessage", src, {args = {"DM Арена", "Нужно минимум 2 игрока!"}})
        return
    end
    
    lobbies[lobbyId].started = true
    for _, player in ipairs(lobbies[lobbyId].players) do
        for _, id in ipairs(GetPlayers()) do
            if GetPlayerIdentifier(id, 0) == player then
                TriggerClientEvent("dmArena:startGameCountdown", id, lobbies[lobbyId])
            end
        end
    end
end)

RegisterNetEvent("dmArena:playerDied")
AddEventHandler("dmArena:playerDied", function(lobbyId)
    local src = source
    if not lobbies[lobbyId] then return end
    
    Citizen.SetTimeout(5000, function()
        TriggerClientEvent("dmArena:respawnPlayer", src, lobbies[lobbyId].weapon)
    end)
end)

RegisterNetEvent("dmArena:endGame")
AddEventHandler("dmArena:endGame", function(lobbyId)
    if lobbies[lobbyId] then
        for _, player in ipairs(lobbies[lobbyId].players) do
            for _, id in ipairs(GetPlayers()) do
                if GetPlayerIdentifier(id, 0) == player then
                    TriggerClientEvent("dmArena:endGameClient", id)
                end
            end
        end
        lobbies[lobbyId] = nil
        TriggerClientEvent("dmArena:updateLobbies", -1, getLobbyArray(), weaponList)
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    local playerId = GetPlayerIdentifier(src, 0)
    removePlayerFromLobbies(playerId)
end)