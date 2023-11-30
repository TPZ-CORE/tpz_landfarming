local TPZ         = {}
local TPZInv      = exports.tpz_inventory:getInventoryAPI()

local PlayersList = {}

TriggerEvent("getTPZCore", function(cb) TPZ = cb end)

-- Requesting real time hours with os.date
RegisterServerEvent('tpz_landfarming:requestCurrentHour')
AddEventHandler('tpz_landfarming:requestCurrentHour', function()
    local _source = source
    local hour    = os.date("%H")
    TriggerClientEvent("tpz_landfarming:updateCurrentHour", _source, hour)
end)


RegisterServerEvent('tpz_landfarming:onCharacterSelect')
AddEventHandler('tpz_landfarming:onCharacterSelect', function()
  local _source        = source
  local xPlayer        = TPZ.GetPlayer(source)

  local charidentifier = xPlayer.getCharacterIdentifier()

  -- If there are no players registered in the player list or there are players into the list but not the connected player.
  if (next(PlayersList) == nil or #PlayersList <= 0) or (#PlayerList > 0 and PlayersList[charidentifier] == nil) then

    local LocationsList = {}

    -- Registering the locations for farm lands.
    for _index, location in pairs (Config.Locations) do
      LocationsList[_index]          = {}
      LocationsList[_index].name     = _index
      LocationsList[_index].finished = false
    end

    Wait(1000)

    -- Registering the first player into the list
    PlayersList[charidentifier]                = {}
    PlayersList[charidentifier].source         = _source
    PlayersList[charidentifier].charidentifier = charidentifier
    PlayersList[charidentifier].locations      = LocationsList

    local data = {source = _source, char = charidentifier, locations = LocationsList }

    TriggerClientEvent("tpz_landfarming:updatePlayerListLocations", _source, data )

  else -- If there are players available in the list.

    -- We are checking if the player who connected has already been into the list to load all the actions and data.
    if PlayersList[charidentifier] then

      -- We are updating the player source with the new one.
      PlayersList[charidentifier].source = _source

      local data = {source = _source, char = charidentifier, locations = PlayersList[charidentifier].locations }

      TriggerClientEvent("tpz_landfarming:updatePlayerListLocations", _source, data )

    end

  end

end)


RegisterServerEvent('tpz_landfarming:setFarmingLocationAsFinished')
AddEventHandler('tpz_landfarming:setFarmingLocationAsFinished', function(currLocation)
  local _source        = source
  local xPlayer        = TPZ.GetPlayer(source)

  local charidentifier = xPlayer.getCharacterIdentifier()
  local finished       = false

  local config         = Config.Locations[currLocation]

  for _index, location in pairs (PlayersList[charidentifier].locations) do

    if location.name == currLocation then
      location.finished = true
      finished = true
    end

  end

  while not finished do
    Wait(250)
  end

  -- After we set the location as finished, we update the list.
  local data = {source = _source, char = PlayersList[charidentifier].charidentifier, locations = PlayersList[charidentifier].locations }
  TriggerClientEvent("tpz_landfarming:updatePlayerListLocations", _source, data )

  -- Giving random money rewards (if available)
  local randomMoney = math.random(config.RewardAmount.min, config.RewardAmount.max)
  local gaveItems   = false

  xPlayer.addAccount(config.RewardCurrencyType, randomMoney)

  -- Giving item rewards (if available).
  if config.ItemRewards then

    local givenItemsList  = {}

    local rewardItems     = math.random(config.MaxRewardItems.min, config.MaxRewardItems.max)
    local randomItemsList = config.ItemRewardsList

    local randomChance = math.random(1, 99)

    for i, item in pairs(randomItemsList) do

      if item.chance >= randomChance then
        table.insert(givenItemsList, item)
      end

    end

    Wait(500)

    if next(givenItemsList) == nil then
      return
    end

    for i = 1, rewardItems do
      local randomItem = givenItemsList[math.random(#givenItemsList)] 

      local randomQuantity = tonumber(math.random(randomItem.min, randomItem.max))
  
      local canCarryItem = TPZInv.canCarryItem(_source, randomItem.item, tonumber(randomQuantity))

      Wait(250)
  
      if canCarryItem then
        gaveItems = true

        TPZInv.addItem(_source, randomItem.item, tonumber(randomQuantity))

      end

    end

  end

  if gaveItems then
    SendNotification(_source, string.format(Locales['SUCCESSFULLY_RECEIVED_MONEY_AND_ITEMS'], randomMoney), "success")
  else
    SendNotification(_source, string.format(Locales['SUCCESSFULLY_RECEIVED_ONLY_MONEY'], randomMoney) "success")
  end

end)