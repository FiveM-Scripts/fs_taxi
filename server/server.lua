RegisterServerEvent('fs_taxi:payCab')
AddEventHandler('fs_taxi:payCab', function(price)
	local Source = tonumber(source)	
	TriggerEvent('es:getPlayerFromId', Source, function(user)
		if not price then
			price = 40
		end

		if user.getMoney() >= tonumber(price) then
			user.removeMoney(tonumber(price))
			TriggerClientEvent('CashMeOutside', Source, true)
		else
			TriggerClientEvent('CashMeOutside', Source, false)
		end
	end)
end)