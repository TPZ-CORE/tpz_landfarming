Config = {}

Config.Keys = { ['G'] = 0x760A9C6F, ['E'] = 0xCEFD9220, ['BACKSPACE'] = 0x156F7119, ["SPACEBAR"] = 0xD9D0E1C0 }

Config.DevMode     = true
Config.Debug       = false

Config.TPZLeveling = false

Config.RenderNPCDistance = 40.0

Config.PromptsKeys = {

    -- Prompts close to the NPC.
    ['START']           = {type = "npc",    label = "Start Working",                   key = 'SPACEBAR'},
    ['FINISHED']        = {type = "npc",    label = "Collect Rewards",                 key = 'BACKSPACE'},

    -- Action prompts
    ['PLACE_PLANT']     = {type = "action", label = "Plant Seed",      stage = 1,      key = 'G'},
    ['THROW_WATER']     = {type = "action", label = "Throw Water",     stage = 2,      key = 'E'},
}

-- @AllowOnlyOnce, by enabling, when the player reaches the actions limit, it will not allow this player to do more actions until the next server restart.
Config.AllowOnlyOnce             = true

Config.ActionsDistance           = 1.1

Config.Locations = {

    ['Guarma1'] = {
        Coords = { x = 1385.398, y = -6955.21, z = 60.288, h = 338.04101562 },

        DistanceOpenStore = 1.5,

        BlipData = {
            Allowed = true,
            Name    = "Farmers Sugarcanes Land - Working Area",
            Sprite  = 669307703,
        },

        NPCModel = "a_m_m_emrfarmhand_01",

        Hours = {
            Allowed = true,

            Starting = 17, -- real time hours (restart hours by default)
            Stopping = 20, -- real time hours (restart hours by default)
        },

        DisplayActionMarkers = true,

        Actions = {

            { Coords = { x = 1390.318, y = -6953.87, z = 61.642, h = 231.3891448974  }, experience = 15 }, 
            { Coords = { x = 1392.870, y = -6950.89, z = 61.998, h = 236.6383361816  }, experience = 15 },
            { Coords = { x = 1395.794, y = -6946.53, z = 62.195, h = 250.3905181884  }, experience = 15 },
            { Coords = { x = 1398.495, y = -6949.51, z = 62.354, h = 240.9570922851  }, experience = 15 },
            { Coords = { x = 1395.956, y = -6952.67, z = 62.071, h = 231.5433502197  }, experience = 15 },
            { Coords = { x = 1393.066, y = -6956.57, z = 61.745, h = 236.1106567382  }, experience = 15 },
            { Coords = { x = 1397.948, y = -6957.41, z = 62.299, h = 233.021209716   }, experience = 15 },
            { Coords = { x = 1400.756, y = -6953.58, z = 62.724, h = 247.7532348632  }, experience = 15 },
            { Coords = { x = 1405.126, y = -6949.16, z = 63.190, h = 248.2471313476  }, experience = 15 },
            { Coords = { x = 1391.341, y = -6948.25, z = 61.855, h = 233.0876770019  }, experience = 15 },
        },

        RewardCurrencyType  = 1,
        RewardAmount        = {min = 300, max = 600},

        ItemRewards         = true,

        MaxRewardItems      = {min = 1, max = 2}, -- How many random items should it give? Default is 2, but keep in mind, if all chances are low, there is a chance to not getting any loot, you have to play around with chances.

        ItemRewardsList = {

            { item = "farming_wheat_seed",         label = "Wheat Seed",            chance = 100,  min = 3, max = 6},
            { item = "farming_fertilizer",         label = "Fertilizer",            chance = 50,   min = 1, max = 1},
            { item = "farming_plant_trimmer",      label = "Plant Trimmer Seed",    chance = 30,   min = 1, max = 1},
        },

    },
    

}

-----------------------------------------------------------
--[[ Notification Functions  ]]--
-----------------------------------------------------------

-- @param source is always null when called from client.
-- @param messageType returns "success" or "error" depends when and where the message is sent.
function SendNotification(source, message, messageType)

    if not source then
        TriggerEvent('tpz_core:sendRightTipNotification', message, 3000)
    else
        TriggerClientEvent('tpz_core:sendRightTipNotification', source, message, 3000)
    end
  
end