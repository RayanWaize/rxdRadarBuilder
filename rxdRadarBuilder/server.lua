local ESX = nil

if not Config.newEsx then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
else
    ESX = exports["es_extended"]:getSharedObject()
end

local function convertirTemps(millisecondes)
    local secondes = math.floor(millisecondes / 1000)
    local minutes = math.floor(secondes / 60)
    local heures = math.floor(minutes / 60)

    heures = heures % 24
    minutes = minutes % 60
    secondes = secondes % 60

    return heures, minutes, secondes
end

ESX.RegisterUsableItem(Config.itemWaze, function(source)
    local heures, minutes, secondes = convertirTemps(Config.timeWaze)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    TriggerClientEvent("rxdRadarBuilder:getAllRadarInMap", _src)
    TriggerClientEvent('esx:showAdvancedNotification', _src, 'Waze', 'Action', "Vous avez sortie votre waze, il est actif pendant:".."\n~g~Heures: "..heures.."~s~\n~o~Minutes: "..minutes.."~s~\n~y~Secondes: "..secondes, "CHAR_LESTER", 1)
    xPlayer.removeInventoryItem(Config.itemWaze, 1)
end)

RegisterServerEvent("rxdRadarBuilder:createRadars")
AddEventHandler("rxdRadarBuilder:createRadars", function(infoB)
    local _src = source
    MySQL.Async.execute('INSERT INTO radarbuilder (name, coords, vitesse, taillezone) VALUES (@name, @coords, @vitesse, @taillezone)', {
        ['@name'] = infoB.name,
        ['@coords'] = json.encode(infoB.coords),
        ['@vitesse'] = infoB.vitesse,
        ['@taillezone'] = infoB.taillezone
    })
    TriggerClientEvent('esx:showNotification', _src, "Vous avez créé un radar.")
end)


RegisterServerEvent("rxdRadarBuilder:deleteRadars")
AddEventHandler("rxdRadarBuilder:deleteRadars", function(id)
    local _src = source
    MySQL.Async.execute('DELETE FROM radarbuilder WHERE id = @id', {
        ['@id'] = id
    })
    TriggerClientEvent('esx:showNotification', _src, "Vous avez supprimé un radar.")
end)

RegisterServerEvent("rxdRadarBuilder:editSpeedLimitRadar")
AddEventHandler("rxdRadarBuilder:editSpeedLimitRadar", function(id, newV)
    local _src = source
    MySQL.Async.execute('UPDATE radarbuilder SET vitesse = @vitesse WHERE id = @id', {
        ['@id'] = id,
        ['@vitesse'] = newV
    })
    TriggerClientEvent('esx:showNotification', _src, "Vous modifier la viteese du radar.")
end)

RegisterServerEvent("rxdRadarBuilder:editDistanceRadar")
AddEventHandler("rxdRadarBuilder:editDistanceRadar", function(id, newD)
    local _src = source
    MySQL.Async.execute('UPDATE radarbuilder SET taillezone = @taillezone WHERE id = @id', {
        ['@id'] = id,
        ['@taillezone'] = newD
    })
    TriggerClientEvent('esx:showNotification', _src, "Vous modifier la distance du radar.")
end)

ESX.RegisterServerCallback('rxdRadarBuilder:getAllRadars', function(source, cb)
	local allRadars = {}
	MySQL.Async.fetchAll("SELECT * FROM radarbuilder", {}, function(data)
        for _,v in pairs(data) do
			table.insert(allRadars, {
                id = v.id,
				name = v.name,
				posRadar = v.coords,
				limitRadar = v.vitesse,
                distanceRadar = v.taillezone
			})
        end
        cb(allRadars)
    end)
end)

ESX.RegisterServerCallback('rxdRadarBuilder:getPlayerGroup', function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local group = xPlayer.getGroup()
    cb(group)
end)

RegisterServerEvent("rxdRadarBuilder:paidRadar")
AddEventHandler("rxdRadarBuilder:paidRadar", function(speedCar)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local getBank = xPlayer.getAccount("bank").money
    if getBank >= Config.bilingAmount then
        xPlayer.removeAccountMoney('bank', Config.bilingAmount)
        TriggerClientEvent('esx:showNotification', _src, "Radar - ~r~Flash~s~ ~o~["..speedCar.." km/h]~s~ | ~r~-"..Config.bilingAmount)
    else
        TriggerClientEvent('rxdRadarBuilder:sendBiling', _src, speedCar)
    end
end)