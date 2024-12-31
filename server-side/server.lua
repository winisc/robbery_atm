
-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPC = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
cRP = {}
Tunnel.bindInterface("trinity_atm",cRP)
vCLIENT = Tunnel.getInterface("trinity_atm")
-----------------------------------------------------------------------------------------------------------------------------------------
-- ROBBERYAVAILABLE
-----------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEBHOOK
-----------------------------------------------------------------------------------------------------------------------------------------
local webhookstartatm = "https://discord.com/api/webhooks/1310703123458949132/HxIh3Zq7faTT1UhOWkgsO_lKC7kStsGIxzNe4OHi05qDkPIBTxg_JqxGvytaT9XxEH12"
local webhookpagamentoatm = "https://discord.com/api/webhooks/1310703123458949132/HxIh3Zq7faTT1UhOWkgsO_lKC7kStsGIxzNe4OHi05qDkPIBTxg_JqxGvytaT9XxEH12"

function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local atmCooldowns = {}
local robberysConfig = {
	["cooldown"] = 420,
	["timer"] = 20,
	["cops"] = 2,
	["needItem"] = "c4",
	["paymentItem"] = "dollarsroll",
	['paymentValue'] = {20000,25000}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKROBBERY
-----------------------------------------------------------------------------------------------------------------------------------------
function cRP.checkRobberyATM(closestATMCoords)
    local source = source
	local user_id = vRP.getUserId(source)
    local currentTime = os.time()
	local policeResult,totalP = vRP.numPermission("Police")

    -- if robberysConfig['cops'] > total  then
    -- 	TriggerClientEvent("Notify", source, "important", "Sem policiais suficientes.", 5000)
    -- 	return false
    -- end

    if atmCooldowns[closestATMCoords] then
        local elapsedTime = currentTime - atmCooldowns[closestATMCoords]
        if elapsedTime < robberysConfig["cooldown"] then

            local remainingTime = robberysConfig["cooldown"] - elapsedTime
            return false, remainingTime
        else
            atmCooldowns[closestATMCoords] = nil
        end
    end

    atmCooldowns[closestATMCoords] = currentTime

    Citizen.CreateThread(function()
        Citizen.Wait(robberysConfig["cooldown"] * 1000)
        atmCooldowns[closestATMCoords] = nil
    end)

	vRP.tryGetInventoryItem(user_id,robberysConfig['needItem'] ,1,false)
    SendWebhookMessage(webhookstartatm,"```prolog\n[ID]: "..user_id.."\n[INICIOU A ACAO]: ATM".."\n[LOC]: "..closestATMCoords[1]..",".. closestATMCoords[2]..","..closestATMCoords[3]..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")

    if totalP > 0 then
        for k, v in pairs(policeResult) do
            async(function()
                TriggerClientEvent("NotifyPush", v, { code = 31, title = "Roubo a Caixa Eletrônico <b>(ATM)</b>", x = closestATMCoords[1], y = closestATMCoords[2], z = closestATMCoords[3], time = "Recebido às " .. os.date("%H:%M"), blipColor = 35 })
                vRPC.playSound(v, "Beep_Green", "DLC_HEIST_HACKING_SNAKE_SOUNDS")
            end)
        end
    end

    return true, 0, robberysConfig['timer'] 
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENTROBBERY
-----------------------------------------------------------------------------------------------------------------------------------------
function cRP.paymentRobbery(coords)
	local source = source
	local user_id = vRP.getUserId(source)
    local policeResult,totalP = vRP.numPermission("Police")
	if user_id then
		TriggerEvent("Wanted",source,user_id,200)

		local value = math.random(robberysConfig["paymentValue"][1],robberysConfig["paymentValue"][2])

        if totalP == 0 then
            value = 13000
        end

		vRP.generateItem(user_id,robberysConfig["paymentItem"],parseInt(value),true)

        SendWebhookMessage(webhookpagamentoatm,"```prolog\n[ID]: "..user_id.."\n[RECEBEU]: "..value.."\n[FINALIZOU A ACAO]: ATM ".."\n[LOC]: "..coords.x..",".. coords.y..","..coords.z..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
		TriggerClientEvent("sounds:source",source,"cash",0.03)
	end
end

function cRP.asyncExplosion(coords)
    local explosionRadius = 35.0

    for _, playerId in ipairs(GetPlayers()) do
        local playerPed = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(playerPed)

        local distance = #(coords - playerCoords)

        if distance <= explosionRadius then
            TriggerClientEvent("client:CreateC4Explosion", playerId, coords.x, coords.y, coords.z + 1)
            TriggerClientEvent("sounds:source", playerId, 'alarm', 0.1)
        end
    end
end

