local inMenu = false
local inLobby = false
local isLeader = false
local currentLobby = nil
local npc = nil
local blip = nil
local nearNPC = false
local inDMArena = false

local spawnPoints = {
    {x = 5000.44, y = -4553.37, z = 187.40, h = 88.64},
    {x = 4833.02, y = -4553.65, z = 187.40, h = 278.30},
    {x = 4898.25, y = -4553.18, z = 187.38, h = 268.10},
    {x = 4992.62, y = -4587.88, z = 184.27, h = 2.25},
    {x = 4897.55, y = -4555.46, z = 184.28, h = 83.43},
    {x = 4852.62, y = -4528.29, z = 184.27, h = 61.15},
    {x = 4837.36, y = -4502.27, z = 184.27, h = 20.27}
}

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

Citizen.CreateThread(function()
    local npcModel = GetHashKey("s_m_y_armymech_01")
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Citizen.Wait(1)
    end
    
    npc = CreatePed(4, npcModel, 2020.37, 4226.55, 138.39, 182.89, false, true)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    
    blip = AddBlipForCoord(2020.37, 4226.55, 139.39)
    SetBlipSprite(blip, 269)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("DM Арена")
    EndTextCommandSetBlipName(blip)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if npc then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local npcCoords = GetEntityCoords(npc)
            local distance = #(playerCoords - npcCoords)
            
            if distance < 3.0 then
                nearNPC = true
                DisplayHelpText("Нажмите ~INPUT_CONTEXT~ чтобы открыть меню DM Арены")
                Draw3DText(npcCoords.x, npcCoords.y, npcCoords.z + 1.0, "Нажмите E для меню DM Арены", 255, 255, 255, 255)
            else
                nearNPC = false
                if inMenu then
                    SetNuiFocus(false, false)
                    inMenu = false
                    SendNUIMessage({type = "close"})
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if nearNPC and IsControlJustReleased(0, 38) and not inMenu then -- E
            TriggerServerEvent("dmArena:getLobbies")
            SetNuiFocus(true, true)
            inMenu = true
            SendNUIMessage({type = "open"})
        end
    end
end)

function DisplayHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

function Draw3DText(x, y, z, text, r, g, b, a)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(r, g, b, a)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

RegisterNUICallback("createLobby", function(data, cb)
    TriggerServerEvent("dmArena:createLobby", data.weapon, data.duration)
    cb("ok")
end)

RegisterNUICallback("joinLobby", function(data, cb)
    TriggerServerEvent("dmArena:joinLobby", data.lobbyId)
    cb("ok")
end)

RegisterNUICallback("startGame", function(data, cb)
    TriggerServerEvent("dmArena:startGame", data.lobbyId)
    cb("ok")
end)

RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    inMenu = false
    SendNUIMessage({type = "close"})
    cb("ok")
end)

RegisterNetEvent("dmArena:updateLobbies")
AddEventHandler("dmArena:updateLobbies", function(lobbies, weapons)
    SendNUIMessage({
        type = "updateLobbies",
        lobbies = lobbies,
        weaponList = weapons
    })
end)

RegisterNetEvent("dmArena:joinedLobby")
AddEventHandler("dmArena:joinedLobby", function(lobby, leader)
    currentLobby = lobby
    inLobby = true
    isLeader = leader
    SendNUIMessage({
        type = "joinedLobby",
        lobby = lobby,
        isLeader = leader
    })
end)

RegisterNetEvent("dmArena:startGameCountdown")
AddEventHandler("dmArena:startGameCountdown", function(lobby)
    currentLobby = lobby
    SendNUIMessage({type = "close"})
    SetNuiFocus(false, false)
    inMenu = false
    
    for i = 5, 1, -1 do
        TriggerEvent("chat:addMessage", {args = {"DM Арена", "Игра начнется через " .. i .. " секунд!"}})
        Citizen.Wait(1000)
    end
    
    local spawnPoint = spawnPoints[math.random(#spawnPoints)]
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, spawnPoint.x, spawnPoint.y, spawnPoint.z)
    SetEntityHeading(playerPed, spawnPoint.h)
    RemoveAllPedWeapons(playerPed, true)
    GiveWeaponToPed(playerPed, GetHashKey(lobby.weapon), 999, false, true)
    SetPedArmour(playerPed, 100)
    SetEntityHealth(playerPed, 100)
    
    inDMArena = true
    TriggerEvent("dmArena:startGameTimer", lobby.duration)
end)

RegisterNetEvent("dmArena:respawnPlayer")
AddEventHandler("dmArena:respawnPlayer", function(weaponHash)
    local spawnPoint = spawnPoints[math.random(#spawnPoints)]
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, spawnPoint.x, spawnPoint.y, spawnPoint.z)
    SetEntityHeading(playerPed, spawnPoint.h)
    RemoveAllPedWeapons(playerPed, true)
    GiveWeaponToPed(playerPed, GetHashKey(weaponHash), 999, false, true)
    SetPedArmour(playerPed, 100)
    SetEntityHealth(playerPed, 100)
end)

RegisterNetEvent("dmArena:startGameTimer")
AddEventHandler("dmArena:startGameTimer", function(duration)
    local timeLeft = duration * 60
    while timeLeft > 0 and inLobby do
        Citizen.Wait(1000)
        timeLeft = timeLeft - 1
        if timeLeft % 60 == 0 then
            TriggerEvent("chat:addMessage", {args = {"DM Арена", "Осталось: " .. math.floor(timeLeft/60) .. " мин"}})
        end
    end
    if inLobby then
        TriggerServerEvent("dmArena:endGame", currentLobby.id)
    end
end)

RegisterNetEvent("dmArena:endGameClient")
AddEventHandler("dmArena:endGameClient", function()
    TriggerEvent("chat:addMessage", {args = {"DM Арена", "Игра окончена!"}})
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, 2020.37, 4226.55, 138.39)
    SetEntityHeading(playerPed, 182.89)
    RemoveAllPedWeapons(playerPed, true)
    currentLobby = nil
    inLobby = false
    isLeader = false
    inDMArena = false
end)

-- Поток для обработки смерти в DM Arena
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if inLobby and currentLobby then
            local playerPed = PlayerPedId()
            local health = GetEntityHealth(playerPed)
            
            if IsPedDeadOrDying(playerPed, 1) or health <= 0 then
                TriggerServerEvent("dmArena:playerDied", currentLobby.id)
                Citizen.Wait(5000)
            end
        end
    end
end)

-- Килл-лист: отслеживание убийств
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if inDMArena then
            local playerPed = PlayerPedId()
            local victim, killer, isDead, weaponHash = Citizen.InvokeNative(0xB36B0C7152EAC995, playerPed, Citizen.PointerValueInt(), Citizen.PointerValueInt(), Citizen.PointerValueInt(), Citizen.PointerValueInt()) -- CEventNetworkEntityDamage
            
            if isDead == 1 and killer ~= 0 and victim ~= 0 then
                local killerPed = GetPlayerPed(GetPlayerFromServerId(killer))
                local victimPed = GetPlayerPed(GetPlayerFromServerId(victim))
                
                if killerPed == playerPed then
                    local victimName = GetPlayerName(GetPlayerFromServerId(victim))
                    local weaponName = "неизвестным оружием"
                    for _, weapon in pairs(weaponList) do
                        if GetHashKey(weapon.hash) == weaponHash then
                            weaponName = weapon.name
                            break
                        end
                    end
                    TriggerEvent("chat:addMessage", {args = {"DM Арена", "Вы убили " .. victimName .. " с помощью " .. weaponName .. "!"}})
                elseif victimPed == playerPed then
                    local killerName = GetPlayerName(GetPlayerFromServerId(killer))
                    local weaponName = "неизвестным оружием"
                    for _, weapon in pairs(weaponList) do
                        if GetHashKey(weapon.hash) == weaponHash then
                            weaponName = weapon.name
                            break
                        end
                    end
                    TriggerEvent("chat:addMessage", {args = {"DM Арена", killerName .. " убил вас с помощью " .. weaponName .. "!"}})
                end
            end
        end
    end
end)

-- Экспортируемая функция для проверки состояния DM Arena
function IsInDMArena()
    return inDMArena
end