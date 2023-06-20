local ESX = nil
local allRadars = {}
local lastPlate = nil

if not Config.newEsx then
    Citizen.CreateThread(function()
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    
        while ESX == nil do Citizen.Wait(100) end
    
        while ESX.GetPlayerData().job == nil do
            Citizen.Wait(10)
        end
    
        ESX.PlayerData = ESX.GetPlayerData()
    end)
else
    ESX = exports["es_extended"]:getSharedObject()
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

local function getAllRadar()
    ESX.TriggerServerCallback('rxdRadarBuilder:getAllRadars', function(result)
        allRadars = result
        SpawnRadarObject(result)
    end)
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	getAllRadar()
end)

RegisterNetEvent('rxdRadarBuilder:getAllRadarInMap')
AddEventHandler('rxdRadarBuilder:getAllRadarInMap', function()
    ESX.TriggerServerCallback('rxdRadarBuilder:getAllRadars', function(result)
        for k,v in pairs(result) do
            local pos = vector3(json.decode(v.posRadar).x, json.decode(v.posRadar).y, json.decode(v.posRadar).z)
            local blipRadar = AddBlipForCoord(pos)
            SetBlipSprite(blipRadar, 744)
            SetBlipScale(blipRadar, 0.8)
            SetBlipColour(blipRadar, 1)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Radar - "..v.name)
            EndTextCommandSetBlipName(blipRadar)
            Wait(Config.timeWaze)
            RemoveBlip(blipRadar)
        end
    end)
end)

local function rxdRadarBuilderKeyboard(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    blockinput = true
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Wait(0)
    end 
        
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end

local function getIfLimit(speedCar, radarLimit, plateCar, vehicle)
    local vehicleClass = GetVehicleClass(vehicle)
    if vehicleClass == 18 and GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
        return
    end
    for k,v in pairs(Config.vehicleEmergency) do
        if IsVehicleModel(vehicle, GetHashKey(v)) then
            return
        end
    end
    for k,v in pairs(Config.jobWhiteList) do
        if ESX.PlayerData.job and ESX.PlayerData.job.name == v then
            return
        end
    end
    for k,v in pairs(Config.playerWhiteList) do
        if string.lower(ESX.PlayerData.identifier) == string.lower(v) then
            return
        end
    end
	if speedCar >= radarLimit then
		if plateCar == lastPlate then
			return
		end
		ESX.ShowNotification("Vous avez atteint ~r~la limite de vitesse~s~ vous avez donc reçu une amende de : "..Config.bilingAmount..Config.moneySymbol)
		lastPlate = plateCar
        if Config.facture then
            TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(PlayerId()), Config.Society, "Radar - ~r~Flash~s~ ~o~["..speedCar.." km/h]", Config.bilingAmount)
        else
            TriggerServerEvent('rxdRadarBuilder:paidRadar', speedCar)
        end
        Citizen.SetTimeout(30000, function()
            lastPlate = nil
        end)
	end
end

CreateThread(function()
    while true do
        local Timer = 500
        local playerPed = PlayerPedId()
        local plyPos = GetEntityCoords(playerPed)
        for k,v in pairs(allRadars) do
            local pos = vector3(json.decode(v.posRadar).x, json.decode(v.posRadar).y, json.decode(v.posRadar).z)
            local dist = #(plyPos-pos)
            if dist <= v.distanceRadar then
                Timer = 0
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                if IsPedSittingInAnyVehicle(playerPed) and GetPedInVehicleSeat(vehicle, -1) == playerPed then
                    local speed = GetEntitySpeed(vehicle) * 3.6
                    local plate = GetVehicleNumberPlateText(vehicle) or ""
                    getIfLimit(math.ceil(speed), v.limitRadar, plate, vehicle)
                end
            end
        end
        Wait(Timer)
    end
end)

function SpawnRadarObject(allRadarsR)
    for k,v in pairs(allRadarsR) do
        local radarHeading = json.decode(v.posRadar).h

        local x, y, z = json.decode(v.posRadar).x, json.decode(v.posRadar).y, json.decode(v.posRadar).z

        RequestModel("prop_cctv_pole_01a")
        while not HasModelLoaded("prop_cctv_pole_01a") do
            Wait(1)
        end

        spawnedObject = CreateObject(GetHashKey("prop_cctv_pole_01a"), x+1, y, z - 7, false, true, true)
        SetEntityHeading(spawnedObject, radarHeading-90.0)
        SetEntityInvincible(spawnedObject, true)
        SetEntityAsMissionEntity(spawnedObject, true, true)
        FreezeEntityPosition(spawnedObject, true)
    end
end


RegisterNetEvent('rxdRadarBuilder:sendBiling')
AddEventHandler('rxdRadarBuilder:sendBiling', function(speedCar)
	TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(PlayerId()), Config.Society, "Radar - ~r~Flash~s~ ~o~["..speedCar.." km/h]", Config.bilingAmount)
end)


RegisterCommand("testradar", function()
    getAllRadar()
end)