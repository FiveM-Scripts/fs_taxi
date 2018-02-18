--- Configuration
-- Set the language for all clients
i18n.setLang("en")

--- Variables
taxiBlip = nil
taxiVeh = nil
taxiPed = nil 
data = {}

function DisplayHelpMsg(text)
	BeginTextCommandDisplayHelp("STRING")
	AddTextComponentScaleform(text)
	EndTextCommandDisplayHelp(0, 0, 1, -1)
end

function DisplayNotify(title, text)
	SetNotificationTextEntry("STRING");
	AddTextComponentString(text);
	SetNotificationMessage("CHAR_TAXI", "CHAR_TAXI", true, 1, "Downtown Cab & Co", title, text);
	DrawNotification(true, false)	
end

function PopulateTaxiIndex()
	local handle, vehicle = FindFirstVehicle()
	local finished = false
	
	repeat
		if DoesEntityExist(vehicle) then
			if IsVehicleDriveable(vehicle) then
				if GetEntityModel(vehicle) == GetHashKey("taxi") then
					local x, y, z = table.unpack(GetEntityCoords(vehicle))
					local Px, Py, Pz = table.unpack(GetEntityCoords(PlayerPedId(), true))
					local driver = GetPedInVehicleSeat(vehicle, -1)
					if driver then
						if GetDistanceBetweenCoords(Px, Py, Pz, x, y, z, true) < 8.0 then
						TaxiInfoTimer = GetGameTimer()							
							if GetGameTimer() < TaxiInfoTimer + 15000 then
								DisplayHelpMsg(i18n.translate("info_message"))
							end							
							data = {["vehicle"] = vehicle, ["driver"] = driver}
						else
							data = {} 
						end
					end
				end
			end
		else 
			vehicle = nil
		end

	finished, vehicle = FindNextVehicle(handle)
	until not finished
		EndFindVehicle(handle)
		return data		
	end

local function SpawnTaxi()
	local taxiModel = GetHashKey("taxi")
	local driverModel = GetHashKey("a_m_y_stlat_01")

	local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
	local _, vector = GetNthClosestVehicleNode(x, y, z, math.random(5, 10), 0, 0, 0)
	local sX, sY, sZ = table.unpack(vector)	

	if not DoesEntityExist(taxiVeh) then
		DisplayNotify(i18n.translate("taxi_contact"), i18n.translate("taxi_dispatch"))
		Wait(2000)

		RequestModel(taxiModel)
		RequestModel(driverModel)
		
		while not HasModelLoaded(taxiModel) do
			Wait(0)
		end

		while not HasModelLoaded(driverModel) do
			Wait(0)
		end
		
		taxiVeh = CreateVehicle(taxiModel, sX, sY, sZ, 0, true, false)
		taxiPed = CreatePedInsideVehicle(taxiVeh, 26, driverModel, -1, true, false)

		SetAmbientVoiceName(taxiPed, "A_M_M_EASTSA_02_LATINO_FULL_01")

		if not DoesBlipExist(taxiBlip) then
			taxiBlip = AddBlipForEntity(taxiVeh)
			SetBlipSprite(taxiBlip, 198)
			SetBlipFlashes(taxiBlip, true)
			SetBlipFlashTimer(taxiBlip, 8000)
		end

		SetModelAsNoLongerNeeded(taxiModel)
		SetModelAsNoLongerNeeded(driverModel)
	else
		DisplayNotify(i18n.translate("taxi_contact"), i18n.translate("drivers_busy"))
	end	
end

AddEventHandler("playerSpawned", function()
	Wait(15000)
	DisplayNotify(false, i18n.translate("welcome_message"))
end)

AddEventHandler("OnPlayerDied", function()
	data = {}

	if DoesEntityExist(taxiVeh) then
		SetEntityAsNoLongerNeeded(taxiVeh)
		SetEntityAsNoLongerNeeded(taxiPed)

		RemoveBlip(taxiBlip)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		if not IsPedInAnyVehicle(PlayerPedId(), false) then
			PopulateTaxiIndex()
		end

		if IsControlJustPressed(0, 168) then
			SpawnTaxi()
		end

		if data then
			if IsControlJustPressed(0, 38) then
				local TaxiDriver = GetPedInVehicleSeat(data.vehicle, -1)
				SetBlockingOfNonTemporaryEvents(data.driver, true)

				if not IsPedInVehicle(PlayerPedId(), data.vehicle, false) then
					TaskEnterVehicle(PlayerPedId(), data.vehicle, -1, 1, 1.0, 1, 0)
					TaxiInfoTimer = GetGameTimer()
					taxiService = true
				end
			end
		end

		if taxiService then
			if IsPedInVehicle(PlayerPedId(), data.vehicle, true) then
				if not questionDest then
					PlayAmbientSpeech1(data.driver, "TAXID_WHERE_TO", "SPEECH_PARAMS_FORCE_NORMAL")
					questionDest = true
				end
			else
				questionDest = false
			end
		end

		if not DoesEntityExist(taxiVeh) or IsEntityDead(taxiVeh) then
			if DoesBlipExist(taxiBlip) then
				RemoveBlip(taxiBlip)
			end

			if DoesEntityExist(taxiPed) then
				SetEntityAsNoLongerNeeded(taxiPed)
				taxiPed = nil
			end
			taxiVeh = nil
		end

	end
end)