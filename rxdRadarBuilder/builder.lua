local ESX = nil
local allRadarsInServer = {}
local radarSelect = {}
local infoRadar = {
    name = nil,
    vitesse = nil,
    taillezone = nil,
    coords = {}
}

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


local function menuRadarBuilder()
    local menuP = RageUI.CreateMenu("Créer un Radar", Config.subTitle)
    local menuS = RageUI.CreateSubMenu(menuP, "Gestion des Radars", Config.subTitle)
    local menuModif = RageUI.CreateSubMenu(menuS, "Gestion des Radars", Config.subTitle)
    RageUI.Visible(menuP, not RageUI.Visible(menuP))

    while menuP do
        Citizen.Wait(0)

        RageUI.IsVisible(menuP, true, true, true, function()

            RageUI.Separator("~b~Créer un Radar")

            RageUI.ButtonWithStyle("Nom de votre radar ?", nil, {RightLabel = infoRadar.name}, true, function(_, _, s)
                if s then
                    local nameR = rxdRadarBuilderKeyboard("Nom de votre radar ?", "", 20)
                    if nameR == nil then
                        ESX.ShowNotification("Vous avez laissé le nom vide.")
                    else
                        infoRadar.name = nameR
                        ESX.ShowNotification("Vous avez choisi le nom " ..nameR.. " pour votre radar.")
                    end
                end
            end)

            RageUI.ButtonWithStyle("Coordonnées ?", nil, {RightLabel = "→"}, true, function(_, _, s)
                if s then
                    infoRadar.coords.x = GetEntityCoords(GetPlayerPed(-1)).x
                    infoRadar.coords.y = GetEntityCoords(GetPlayerPed(-1)).y
                    infoRadar.coords.z = GetEntityCoords(GetPlayerPed(-1)).z
                    infoRadar.coords.h = GetEntityHeading(GetPlayerPed(-1))
                    ESX.ShowNotification("Vous avez choisi les coordonnées de votre radar.")
                end
            end)

            RageUI.ButtonWithStyle("Limititation de vitesse ?", nil, {RightLabel = infoRadar.vitesse}, true, function(_, _, s)
                if s then
                    local vitesseR = rxdRadarBuilderKeyboard("Limititation de vitesse ?", "", 20)
                    if tonumber(vitesseR) then
                        infoRadar.vitesse = vitesseR
                        ESX.ShowNotification("Vous avez saisi " ..vitesseR.. " km/h pour ce radar.")
                    else
                        ESX.ShowNotification("Vous n'avez pas mis de nombres.")
                    end
                end
            end)

            RageUI.ButtonWithStyle("Taille de la zone de flash ?", nil, {RightLabel = infoRadar.taillezone}, true, function(_, _, s)
                if s then
                    local taillezoneR = rxdRadarBuilderKeyboard("Taille de la zone de flash ?", "", 20)
                    if tonumber(taillezoneR) then
                        infoRadar.taillezone = taillezoneR
                        ESX.ShowNotification("Vous avez choisi une zone de " ..taillezoneR.. " mètres.")
                    else
                        ESX.ShowNotification("Vous n'avez pas mis de nombres.")
                    end
                end
            end)
            
            
            RageUI.ButtonWithStyle("~g~Créer le radar", nil, {RightLabel = "→→→"}, true, function(_, _, s)
                if s then
                    if infoRadar.name == nil then
                        ESX.ShowNotification("Vous avez laissé le nom vide.")
                    elseif infoRadar.coords == nil then
                        ESX.ShowNotification("Vous avez laissé les coordonnées vide.")
                    elseif infoRadar.vitesse == nil then
                        ESX.ShowNotification("Vous n'avez pas saisi de vitesse.")
                    elseif infoRadar.taillezone == nil then
                        ESX.ShowNotification("Vous n'avez pas indiqué de périmètre")
                    else
                        TriggerServerEvent("rxdRadarBuilder:createRadars", infoRadar)
                        infoRadar = {
                            name = nil,
                            vitesse = nil,
                            taillezone = nil,
                            coords = nil
                        }
                    end
                end
            end)

            RageUI.ButtonWithStyle("~r~Annuler", nil, {RightLabel = "→→→"}, true, function(_, _, s)
                if s then
                    RageUI.CloseAll()
                end
            end)


            RageUI.Line()

            RageUI.ButtonWithStyle("~o~Gestion des Radars", nil, {}, true, function(_, _, s)
                if s then
                    getAllRadars()
                end
            end, menuS)

        end)

        RageUI.IsVisible(menuS, true, true, true, function()

            RageUI.Separator("~b~Gestion des Radars")

            for k,v in pairs(allRadarsInServer) do
                RageUI.ButtonWithStyle("Radar : "..tostring(v.name), "Limit : "..v.limitRadar.."\nDistance : "..v.distanceRadar, {}, true, function(_, _, s)
                    if s then
                        radarSelect = v
                    end
                end, menuModif)
            end

        end)

        RageUI.IsVisible(menuModif, true, true, true, function()
            
            RageUI.Separator("Nom du radar : ~o~"..radarSelect.name)

            RageUI.ButtonWithStyle("Limititation de vitesse ?", nil, {RightLabel = "→→"}, true, function(_, _, s)
                if s then
                    local vitesseR = rxdRadarBuilderKeyboard("Limititation de vitesse ?", "", 20)
                    if tonumber(vitesseR) then
                        TriggerServerEvent("rxdRadarBuilder:editSpeedLimitRadar", radarSelect.id, vitesseR)
                        getAllRadars()
                    else
                        ESX.ShowNotification("Vous n'avez pas mis de nombres.")
                    end
                end
            end)

            RageUI.ButtonWithStyle("Taille de la zone de flash ?", nil, {RightLabel = "→→"}, true, function(_, _, s)
                if s then
                    local taillezoneR = rxdRadarBuilderKeyboard("Taille de la zone de flash ?", "", 20)
                    if tonumber(taillezoneR) then
                        TriggerServerEvent("rxdRadarBuilder:editDistanceRadar", radarSelect.id, taillezoneR)
                        getAllRadars()
                    else
                        ESX.ShowNotification("Vous n'avez pas mis de nombres.")
                    end
                end
            end)
            
            RageUI.ButtonWithStyle("~r~Supprimer le radar", nil, {RightLabel = "→→→"}, true, function(_, _, s)
                if s then
                    TriggerServerEvent("rxdRadarBuilder:deleteRadars", radarSelect.id)
                    RageUI.CloseAll()
                end
            end)
        end)

        if not RageUI.Visible(menuP) and not RageUI.Visible(menuS) and not RageUI.Visible(menuModif) then
            menuP = RMenu:DeleteType("menuP", true)
        end
    end
end

function getAllRadars()
    ESX.TriggerServerCallback('rxdRadarBuilder:getAllRadars', function(result)
        allRadarsInServer = result
    end)
end

RegisterCommand("radarbuilder", function()
    ESX.TriggerServerCallback('rxdRadarBuilder:getPlayerGroup', function(result)
        if result == "admin" or result == "superadmin" or result == "fondateur" then
            menuRadarBuilder()
        else
            ESX.ShowNotification("Vous n'avez pas les droits pour utiliser cette commande.")
        end
    end)
end)