--[[
            fs_taxi - Taxi service for FiveM Servers
              Copyright (C) 2018  FiveM-Scripts

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program in the file "LICENSE".  If not, see <http://www.gnu.org/licenses/>.
]]

--- Configuration
-- Set the language for all clients
i18n.setLang("en")

--- Variables
taxiBlip = nil
taxiVeh = nil
taxiPed = nil 
HornToInform = false
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
						if GetDistanceBetweenCoords(Px, Py, Pz, x, y, z, true) <= 18.0 then
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
		PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
		Wait(2500)

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

		SetEntityAsMissionEntity(taxiVeh, true, true)
		SetVehicleEngineOn(taxiVeh, true)		
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

RegisterCommand('taxi', function()
	if not IsPedInAnyVehicle(PlayerPedId(), false) then
		SpawnTaxi()
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		if not IsPedInAnyVehicle(PlayerPedId(), false) then
			PopulateTaxiIndex()
			if IsControlJustPressed(0, 168) then
				SpawnTaxi()
			end	
		end

		if data then
			if DoesEntityExist(data.vehicle) then
				if not HornToInform then
					if GetIsVehicleEngineRunning(taxiVeh) then
						SetHornEnabled(taxiVeh, true)
						StartVehicleHorn(taxiVeh, 2000, GetHashKey("HELDDOWN"), false)
					end
					HornToInform = true
				end
			end

			if IsControlJustPressed(0, 38) then
				for k,v in pairs(data) do
					print(k,v)
				end

				local TaxiDriver = GetPedInVehicleSeat(data.vehicle, -1)
				--SetBlockingOfNonTemporaryEvents(data.driver, true)

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

				if IsDestinationSet then
					-- drive horse drive!
				end
			else
				questionDest = false
			end
		end

		if IsEntityDead(taxiVeh) then
			if DoesBlipExist(taxiBlip) then
				RemoveBlip(taxiBlip)
			end

			DeleteEntity(taxiPed)
			DeleteEntity(taxiVeh)
			HornToInform = false
			data = {}			
		end

		if IsPlayerDead(PlayerId()) then			
			if DoesEntityExist(taxiVeh) then
				RemoveBlip(taxiBlip)				
			end

			DeleteEntity(taxiPed)
			DeleteEntity(taxiVeh)

			HornToInform = false
			data = {}
		end


	end
end)