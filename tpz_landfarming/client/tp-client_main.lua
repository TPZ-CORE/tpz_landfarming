local CurrentHour         = nil

local PlayerListLocations = {}

local ClientData = { loaded = false, job = nil, jobGrade = 0, currentLocation = nil, started = false, performingAction = false}

-----------------------------------------------------------
--[[ Base Events  ]]--
-----------------------------------------------------------

RegisterNetEvent("tpz_core:getPlayerJob")
AddEventHandler("tpz_core:getPlayerJob", function(data)
    ClientData.job      = data.job
    ClientData.jobGrade = data.jobGrade
end)

RegisterNetEvent('tpz_core:isPlayerReady')
AddEventHandler("tpz_core:isPlayerReady", function()

    if Config.DevMode then 
        return 
    end

    CreateLocationActionPrompts()
    CreateLocationNPCPrompts()

    TriggerEvent("tpz_core:ExecuteServerCallBack", "tpz_core:getPlayerData", function(data) 
        
        ClientData.job, ClientData.jobGrade = data.job, data.jobGrade

        ClientData.loaded = true
    end)

    TriggerServerEvent('tpz_landfarming:requestCurrentHour')
    TriggerServerEvent("tpz_landfarming:onCharacterSelect")
end)


if Config.DevMode then
    Citizen.CreateThread(function ()

        CreateLocationActionPrompts()
        CreateLocationNPCPrompts()

        TriggerEvent("tpz_core:ExecuteServerCallBack", "tpz_core:getPlayerData", function(data) 
        
            ClientData.job, ClientData.jobGrade = data.job, data.jobGrade
    
            ClientData.loaded = true
        end)
    
        TriggerServerEvent('tpz_landfarming:requestCurrentHour')
        TriggerServerEvent("tpz_landfarming:onCharacterSelect")

    end)

end


-----------------------------------------------------------
--[[ General Events  ]]--
-----------------------------------------------------------

RegisterNetEvent("tpz_landfarming:updateCurrentHour")
AddEventHandler("tpz_landfarming:updateCurrentHour", function(hour)
    CurrentHour = tonumber(hour)
end)

RegisterNetEvent("tpz_landfarming:updatePlayerListLocations")
AddEventHandler("tpz_landfarming:updatePlayerListLocations", function(data)
    PlayerListLocations = data

    ClientData.loaded   = true
end)

-----------------------------------------------------------
--[[ Functions  ]]--
-----------------------------------------------------------


function anim(dict,name, time, flag)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
	TaskPlayAnim(PlayerPedId(), dict, name, 1.0, 1.0, time, flag, 0, true, 0, false, 0, false)  
end

function PlantingAnimation()
    ClearPedTasks(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), true)
    local coords = GetEntityCoords(PlayerPedId())
    anim("amb_work@world_human_farmer_rake@male_a@idle_a","idle_a", -1, 1)
    Citizen.Wait(700)
    local rake = CreateObject("p_rake02x", coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(rake, PlayerPedId(), GetEntityBoneIndexByName(PlayerPedId(), "PH_R_Hand"), 0.0, 0.0, 0.19, 0.0, 0.0, 0.0, false, false, true, false, 0, true, false, false)
    Citizen.Wait(15000)
    DeleteEntity(rake)
    ClearPedTasks(PlayerPedId())
    anim("amb_work@world_human_feed_chickens@female_a@base","base", -1, 1)
    Citizen.Wait(700)
    local bag = CreateObject("p_feedbag01bx", coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(bag, PlayerPedId(), GetEntityBoneIndexByName(PlayerPedId(), "PH_L_Hand"), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, true, false, 0, true, false, false)
    Citizen.Wait(10000)
    DeleteEntity(bag)
    ClearPedTasks(PlayerPedId())
	FreezeEntityPosition(PlayerPedId(), false)

end

-- animation for watering plants
function WaterAnimation()

	FreezeEntityPosition(PlayerPedId(), true)
	ClearPedTasks(PlayerPedId())

    TaskStartScenarioInPlace(PlayerPedId(), joaat("WORLD_PLAYER_CHORES_BUCKET_POUR_HIGH"), 7000, true, false, false, false)
    Wait(6000)

	Citizen.Wait(50)
	FreezeEntityPosition(PlayerPedId(), false)
    Citizen.InvokeNative(0xFCCC886EDE3C63EC,PlayerPedId(),false,true)
end

-----------------------------------------------------------
--[[ Threads  ]]--
-----------------------------------------------------------

Citizen.CreateThread(function ()
    while true do
        Wait(60000)
        TriggerServerEvent('tpz_landfarming:requestCurrentHour')
    end
end)


Citizen.CreateThread(function()

    while true do
        Citizen.Wait(0)

        local sleep        = true

        local player       = PlayerPedId()
        local isPlayerDead = IsEntityDead(player)


        if ClientData.loaded and not isPlayerDead and ClientData.started and ClientData.currentLocation and not ClientData.performingAction then
            local coords = GetEntityCoords(player)

            local config = Config.Locations[ClientData.currentLocation]


            for locId, locationConfig in pairs(config.Actions) do

                local coordsDist = vector3(coords.x, coords.y, coords.z)
                local coordsLoc = vector3(locationConfig.Coords.x, locationConfig.Coords.y, locationConfig.Coords.z)
                local distance = #(coordsDist - coordsLoc)

                if locationConfig.stage == nil then locationConfig.stage = 1 locationConfig.finished = false end

                if config.DisplayActionMarkers then
                    if (distance <= 20.0 and not locationConfig.finished) then
                        sleep = false
        
                        Citizen.InvokeNative(0x2A32FAA57B937173, 0x94FDAE17, locationConfig.Coords.x, locationConfig.Coords.y, locationConfig.Coords.z - 1.2, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 0.7, 100, 1, 1, 120, false, true, 2, false, false, false, false)
                    end
                end
    

                if distance <= Config.ActionsDistance and not locationConfig.finished then
                    sleep = false

                    local label = CreateVarString(10, 'LITERAL_STRING', Locales['PROMPT_FOOTER'])
                    PromptSetActiveGroupThisFrame(ActionPrompts, label)

                    for i, prompt in pairs (ActionPromptsList) do

                        PromptSetVisible(prompt.prompt, 0)

                        if locationConfig.stage == prompt.stage then
                            PromptSetVisible(prompt.prompt, 1)
                        end

                        if PromptHasHoldModeCompleted(prompt.prompt) then

                            ClientData.performingAction = true

                            if prompt.type == "PLACE_PLANT" then

                                PlantingAnimation()

                                locationConfig.stage = locationConfig.stage + 1

                                TriggerEvent("tp_metabolism:updateStress", "remove", 0.5, false, 0)

                            elseif prompt.type == "THROW_WATER" then

                                WaterAnimation()

                                locationConfig.stage    = locationConfig.stage + 1
                                locationConfig.finished = true

                                config.CurrentActions = config.CurrentActions + 1

                                if Config.TPZLeveling then
                                    exports.tpz_leveling:addLevelExperience(nil, "farming", locationConfig.experience)
                                end

                                TriggerEvent("tp_metabolism:updateStress", "remove", 0.5, false, 0)
                            end

                            ClientData.performingAction = false

                            Wait(1000)
                        end

                    end
                end

            end

        end

        if sleep then
            Citizen.Wait(1000)
        end

    end
    
end)

Citizen.CreateThread(function()

    while true do
        Citizen.Wait(0)

        local sleep        = true
        local player       = PlayerPedId()
        local isPlayerDead = IsEntityDead(player)

        if ClientData.loaded and not isPlayerDead then
            local coords = GetEntityCoords(player)
            
            for locId, locationConfig in pairs(Config.Locations) do

                local coordsDist = vector3(coords.x, coords.y, coords.z)
                local coordsLoc = vector3(locationConfig.Coords.x, locationConfig.Coords.y, locationConfig.Coords.z)
                local distance = #(coordsDist - coordsLoc)

                if locationConfig.Hours.Allowed then

                    if CurrentHour > locationConfig.Hours.Stopping or CurrentHour < locationConfig.Hours.Starting then

                        if Config.Locations[locId].BlipHandle then
                            RemoveBlip(Config.Locations[locId].BlipHandle)
                            Config.Locations[locId].BlipHandle = nil
                        end

                        if Config.Locations[locId].NPC then
                            DeleteEntity(Config.Locations[locId].NPC)
                            DeletePed(Config.Locations[locId].NPC)
                            SetEntityAsNoLongerNeeded(Config.Locations[locId].NPC)
                            Config.Locations[locId].NPC = nil
                        end

                    elseif CurrentHour >= locationConfig.Hours.Starting then

                        if not Config.Locations[locId].BlipHandle and locationConfig.BlipData.Allowed then
                            AddBlip(locId)
                        end

                        if Config.Locations[locId].NPC and distance > Config.RenderNPCDistance then
                            DeleteEntity(Config.Locations[locId].NPC)
                            DeletePed(Config.Locations[locId].NPC)
                            SetEntityAsNoLongerNeeded(Config.Locations[locId].NPC)
                            Config.Locations[locId].NPC = nil
                        end
                        
                        if not Config.Locations[locId].NPC and distance <= Config.RenderNPCDistance then
                            SpawnNPC(locId)
                        end
    
                        if not Config.Locations[locId].CurrentActions then
                            Config.Locations[locId].CurrentActions = 0
                        end
    
                    
                        if (distance <= locationConfig.DistanceOpenStore) then -- check distance
                            sleep = false
    
                            local displayFooterLabel = Locales['PROMPT_FOOTER']
    
                            local totalActions       = #locationConfig.Actions
                            if ClientData.started then
                                displayFooterLabel = Locales['PROMPT_FOOTER'] .. " | " .. Locales['PROMPT_FOOTER_SECOND'] .. Config.Locations[locId].CurrentActions .. " / " .. totalActions
                            end
    
                            local label = CreateVarString(10, 'LITERAL_STRING', displayFooterLabel)
                            PromptSetActiveGroupThisFrame(Prompts, label)
    
                            local isFinished = false
    
                            for index, locations in pairs (PlayerListLocations.locations) do
                                
                                if locations.name == locId and locations.finished then
                                    isFinished = true
                                end
                            end
        
                            for i, prompt in pairs (PromptsList) do
    
                                if not ClientData.started and not isFinished then
                                    PromptSetVisible(prompt.prompt, 0)
    
                                    if prompt.type == "START" then
                                        PromptSetVisible(prompt.prompt, 1)
    
                                        if Config.Locations[locId].CurrentActions ~= totalActions then
                                            PromptSetEnabled(prompt.prompt, 1)
                                        end
                                    end
    
                                else
                                    PromptSetVisible(prompt.prompt, 0)
                                    PromptSetEnabled(prompt.prompt, 0)
    
                                    if prompt.type == "FINISHED" then
                                        PromptSetVisible(prompt.prompt, 1)
    
                                        if Config.Locations[locId].CurrentActions == totalActions and not isFinished then
                                            PromptSetEnabled(prompt.prompt, 1)
                                        end
                                    end
                                end
    
                                if PromptHasHoldModeCompleted(prompt.prompt) then
    
                                    if prompt.type == "START" then
                                        ClientData.currentLocation = locId
                                        ClientData.started = true
    
                                    elseif prompt.type == 'FINISHED' then
                                        ClientData.currentLocation = nil
                                        ClientData.started = false
    
                                        TriggerServerEvent('tpz_landfarming:setFarmingLocationAsFinished', locId)
                                    end
    
                                    Wait(1500)
                                end
        
                            end
                        end

                    end

                end

            end


        end

        if sleep then
            Citizen.Wait(1000)
        end

    end

end)
