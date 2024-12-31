-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
cRP = {}
Tunnel.bindInterface("trinity_atm",cRP)
vSERVER = Tunnel.getInterface("trinity_atm")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('toggleClosedPhone')
AddEventHandler('toggleClosedPhone', function()
	exports["lb-phone"]:ToggleOpen(false, false)
end)


RegisterNetEvent('togglePhoneDisabled')
AddEventHandler('togglePhoneDisabled', function(disabled)
	exports["lb-phone"]:ToggleDisabled(disabled)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- ROUBO DE ATMS
---------------------------------------------------------------

local atms = {
    `prop_fleeca_atm`,
    `prop_atm_03`,
    `prop_atm_02`,
    `prop_atm_01`
}

local inProgress = false
local canLoot = false

function startRobbery()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local closestATM = nil
    local closestDistance = 3.0

	if not inProgress then
		if not IsPedInAnyVehicle(playerPed, false) then

			for _, atmModel in ipairs(atms) do
				local atm = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, closestDistance, atmModel, false, false, false)
				
				if atm ~= 0 then
					closestATM = atm
					rotation = GetEntityRotation(atm)
					closestATMCoords = GetEntityCoords(atm)
					break
				end
			end

			if closestATM then
				inProgress = true
				local success, remainingTime, timerPull = vSERVER.checkRobberyATM(closestATMCoords)
				
				if success then
					playAnimPlantC4()
					Citizen.Wait(4000)
					vSERVER.asyncExplosion(closestATMCoords)
					canLoot = true
					
					--Progress loot

					Citizen.CreateThread(function()
						while canLoot do
							Citizen.Wait(1)
					
							local playerPos = GetEntityCoords(playerPed)
							local distance = #(playerPos - closestATMCoords)
							

							if distance < 1.5 then
								
								DrawText3D(closestATMCoords.x, closestATMCoords.y, closestATMCoords.z + 1.0, "Pressione [G] para saquear o dinheiro")
					
								if IsControlJustPressed(0, 47) then
									if not IsPedInAnyVehicle(playerPed, false) then
										playAnimProgressLoot(timerPull)
										vSERVER.paymentRobbery(closestATMCoords)
										canLoot = false
										inProgress = false
									else
										TriggerEvent("Notify","negado","Saia do veículo para saquear o dinheiro.",3000)
									end
								end
							elseif distance >= 35 then
								canLoot = false
								inProgress = false
								TriggerEvent("Notify","negado","<b>Roubo cancelado.</b><br><small>Você foi muito longe.</small><br>",6000)
							elseif GetEntityHealth(playerPed) <= 101 then
								canLoot = false
								inProgress = false
								TriggerEvent("Notify","negado","<b>Roubo cancelado.</b><br><small>Você morreu.</small><br>",6000)
							end
						end
					end)

				else
					inProgress = false
					if remainingTime == nil then return end
					if remainingTime <= 60 then
						TriggerEvent("Notify", "aviso","Sistema indisponivel no momento. <br><small>Tente novamente daqui a <b>" .. remainingTime .. " segundos.</b></small>",5000)
						return
					end
					TriggerEvent("Notify", "aviso","Sistema indisponivel no momento. <br><small>Tente novamente daqui a <b>" .. parseInt(remainingTime/60) .. " minuto(s).</b></small>",5000)
				end
			else
				TriggerEvent("Notify", "negado", "Nenhum ATM próximo encontrado para roubo.",3000)
			end

		else
			TriggerEvent("Notify","negado","Não é possivel iniciar o roubo dentro de um veículo.",3000)
		end
	else
		TriggerEvent("Notify","important","Ação indisponivel.",3000)
	end
end

function playAnimPlantC4()
	TriggerEvent('snt/animations/play', { dict = "anim@heists@ornate_bank@thermal_charge", anim = "thermal_charge", walk = false, loop = false})
	TriggerEvent('snt/animations/setBlocked',true)
	TriggerEvent('player:disabledInventory', true)
	exports["lb-phone"]:ToggleOpen(false, false) 							
	exports["lb-phone"]:ToggleDisabled(true)
	TriggerEvent('Progress',6, 'Armando a C4.')
	LocalPlayer["state"]["Acao"] = true
	FreezeEntityPosition(PlayerPedId(),true)
	Citizen.Wait(6000)

	FreezeEntityPosition(PlayerPedId(),false)
	LocalPlayer["state"]["Acao"] = false
	TriggerEvent('snt/animations/setBlocked',false)
	TriggerEvent('player:disabledInventory', false)
	exports["lb-phone"]:ToggleDisabled(false)
	TriggerEvent('snt/animations/stop')
	TriggerEvent("Notify", "aviso", "Afaste-se!", 3000)
end

function playAnimProgressLoot(timerPull)
	TriggerEvent('snt/animations/play', { dict = "anim@heists@ornate_bank@grab_cash", anim = "grab", walk = false, loop = false})
	TriggerEvent('snt/animations/setBlocked',true)
	TriggerEvent('player:disabledInventory',true)
	exports["lb-phone"]:ToggleOpen(false, false) 							
	exports["lb-phone"]:ToggleDisabled(true)
	FreezeEntityPosition(PlayerPedId(),true)
	LocalPlayer["state"]["Acao"] = true
	TriggerEvent('Progress',timerPull, 'Coletando.')

	Citizen.Wait(timerPull * 1000)
	LocalPlayer["state"]["Acao"] = false
	FreezeEntityPosition(PlayerPedId(),false)
	TriggerEvent('snt/animations/setBlocked',false)
	TriggerEvent('player:disabledInventory',false)
	exports["lb-phone"]:ToggleDisabled(false)
	TriggerEvent('snt/animations/stop')
end

RegisterNetEvent("client:CreateC4Explosion")
AddEventHandler("client:CreateC4Explosion", function(x, y, z)
    local explosionType = 2
    local damageScale = 1.0
    local isAudible = true  
    local isInvisible = false
    local cameraShake = 0.5 

    AddExplosion(x, y, z, explosionType, damageScale, isAudible, isInvisible, cameraShake)
end)

RegisterNetEvent("trinity:robberyAtms")
AddEventHandler("trinity:robberyAtms", function()
	startRobbery()
end)

-----------------------------------------------------------------------------------------------------------------------------------------
--DRAW TEXT
-----------------------------------------------------------------------------------------------------------------------------------------
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())

    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)

    end
end