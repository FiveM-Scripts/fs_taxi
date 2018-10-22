PerformHttpRequest("https://raw.githubusercontent.com/FiveM-Scripts/fs_taxi/master/__resource.lua", function(errorCode, result, headers)
    local version = GetResourceMetadata(GetCurrentResourceName(), 'resource_version', 0)

    if string.find(tostring(result), version) == nil then
        print("\n\r[fs_taxi] The version on this server is not up to date. Please update now.\n\r")
    end
end, "GET", "", "")

RegisterServerEvent('fs_taxi:payCab')
AddEventHandler('fs_taxi:payCab', function(meters)
	local src = source
	
	local totalPrice = meters / 40.0
	local price = math.floor(totalPrice)
	
	if optional.use_essentialmode then
		TriggerEvent('es:getPlayerFromId', src, function(user)
			if user.getMoney() >= tonumber(price) then
				user.removeMoney(tonumber(price))
				TriggerClientEvent('fs_taxi:payment-status', src, true)
			else
				TriggerClientEvent('fs_taxi:payment-status', src, false)
			end
		end)
	elseif optional.use_venomous then
		TriggerEvent('vf_base:FindPlayer', src, function(user)
			if user.cash >= tonumber(price) then
				TriggerEvent('vf_base:ClearCash', src, tonumber(price))
				TriggerClientEvent('fs_taxi:payment-status', src, true)				
			else
				TriggerClientEvent('fs_taxi:payment-status', src, false)
			end
		end)
	else
		TriggerClientEvent('fs_taxi:payment-status', src, true)	
	end
end)