--[[-------------------------------------------------------
 Management
]]---------------------------------------------------------

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    for i, v in pairs(Config.Locations) do
        if v.BlipHandle then
            RemoveBlip(v.BlipHandle)
        end
        if v.NPC then
            DeleteEntity(v.NPC)
            DeletePed(v.NPC)
            SetEntityAsNoLongerNeeded(v.NPC)
        end
    end
end)

--[[-------------------------------------------------------
 Prompts
]]---------------------------------------------------------

Prompts       = GetRandomIntInRange(0, 0xffffff)
PromptsList   = {}


CreateLocationNPCPrompts = function()

    for index, tprompt in pairs (Config.PromptsKeys) do

		if tprompt.type == "npc" then
			local str = tprompt.label
			local keyPress = Config.Keys[tprompt.key]
		
			local dPrompt = PromptRegisterBegin()
			PromptSetControlAction(dPrompt, keyPress)
			str = CreateVarString(10, 'LITERAL_STRING', str)
			PromptSetText(dPrompt, str)
			PromptSetEnabled(dPrompt, 1)
			PromptSetVisible(dPrompt, 1)
			PromptSetStandardMode(dPrompt, 1)
			PromptSetHoldMode(dPrompt, 1000)
			PromptSetGroup(dPrompt, Prompts)
			Citizen.InvokeNative(0xC5F428EE08FA7F2C, dPrompt, true)
			PromptRegisterEnd(dPrompt)
		
			table.insert(PromptsList, {prompt = dPrompt, type = index})
		end
    end

end

ActionPrompts       = GetRandomIntInRange(0, 0xffffff)
ActionPromptsList   = {}

CreateLocationActionPrompts = function()

    for index, tprompt in pairs (Config.PromptsKeys) do

		if tprompt.type == "action" then
			local str = tprompt.label
			local keyPress = Config.Keys[tprompt.key]
		
			local dPrompt = PromptRegisterBegin()
			PromptSetControlAction(dPrompt, keyPress)
			str = CreateVarString(10, 'LITERAL_STRING', str)
			PromptSetText(dPrompt, str)
			PromptSetEnabled(dPrompt, 1)
			PromptSetVisible(dPrompt, 0)
			PromptSetStandardMode(dPrompt, 1)
			PromptSetHoldMode(dPrompt, 1000)
			PromptSetGroup(dPrompt, ActionPrompts)
			Citizen.InvokeNative(0xC5F428EE08FA7F2C, dPrompt, true)
			PromptRegisterEnd(dPrompt)
		
			table.insert(ActionPromptsList, {prompt = dPrompt, type = index, stage = tprompt.stage})
		end
    end

end

--[[-------------------------------------------------------
 Locations Management
]]---------------------------------------------------------

function AddBlip(Store)
    if Config.Locations[Store].BlipData then
        Config.Locations[Store].BlipHandle = N_0x554d9d53f696d002(1664425300, Config.Locations[Store].Coords.x, Config.Locations[Store].Coords.y, Config.Locations[Store].Coords.z)

        SetBlipSprite(Config.Locations[Store].BlipHandle, Config.Locations[Store].BlipData.Sprite, 1)
        SetBlipScale(Config.Locations[Store].BlipHandle, 0.2)
        Citizen.InvokeNative(0x9CB1A1623062F402, Config.Locations[Store].BlipHandle, Config.Locations[Store].BlipData.Name)

		Citizen.InvokeNative(0x662D364ABF16DE2F, Config.Locations[Store].BlipHandle, 0xF91DD38D)
    end
end


function SpawnNPC(Store)
    local v = Config.Locations[Store]

	LoadModel(v.NPCModel)

	local npc = CreatePed(v.NPCModel, v.Coords.x, v.Coords.y, v.Coords.z, v.Coords.h, false, true, true, true)

	Citizen.InvokeNative(0x283978A15512B2FE, npc, true) -- SetRandomOutfitVariation

	SetEntityCanBeDamaged(npc, false)
	SetEntityInvincible(npc, true)
	Wait(1000)
	FreezeEntityPosition(npc, true) -- NPC can't escape
	SetBlockingOfNonTemporaryEvents(npc, true) -- NPC can't be scared

	Config.Locations[Store].NPC = npc

end

--[[-------------------------------------------------------
 General
]]---------------------------------------------------------

function LoadModel(model)
    local model = joaat(model)

    if IsModelValid(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            RequestModel(model)
            Citizen.Wait(100)
        end
    else
        print(model .. " is not valid") -- Concatenations
    end
end
