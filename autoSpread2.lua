local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require("config")

local workingCrop;

local function isWeed(crop)
    return crop.name == "weed" or
        crop.name == "Grass" or
        crop.gr > config.autoSpread2MaxGrows or
        (crop.name == "venomilia" and crop.gr > 7);
end

local function checkOffspring(slot, crop)
    if crop.name == "air" then
        action.placeCropStick(2, true)
        return
    end
    if (not config.assumeNoBareStick) and crop.name == "crop" then
        action.placeCropStick(1, true)
        return
    end
    if not crop.isCrop then
        return
    end
    if isWeed(crop) or crop.name ~= workingCrop then
        action.deweed()
        action.placeCropStick(1, true)
        return
    end

    if crop.stats >= config.autoSpread2TargetCropStatsThreshold then
        action.transplant(posUtil.farmToGlobal(slot), posUtil.storageToGlobal(database.nextStorageSlot()));
        database.addToStorage(crop);
        action.placeCropStick(2, true);
    else
        action.deweed()
        action.placeCropStick(1, true)
    end
end

local function checkParent(slot, crop)
    if crop.isCrop and isWeed(crop) then
        action.deweed();
        database.updateFarm(slot, { name = 'crop' });
    end
end

local function spreadOnce()
    for slot = 1, config.farmArea, 1 do
        gps.go(posUtil.farmToGlobal(slot))
        local crop = scanner.scan()

        if (slot % 2 == 0) then
            checkOffspring(slot, crop);
            if #database.getStorage() >= config.storageFarmArea then
                return true;
            end
        else
            checkParent(slot, crop);
        end

        if action.needCharge() then
            action.charge()
        end
    end
    return false
end

local function init()
    database.scanFarm()
    database.scanStorage()
    workingCrop = database.getFarm()[1].name
    action.restockAll()
end

local function main()
    init()
    while not spreadOnce() do
        gps.go({ 0, 0 })
        action.restockAll()
    end
    gps.go({ 0, 0 })
    action.destroyAll()
    gps.go({ 0, 0 })
    if config.takeCareOfDrops then
        action.dumpInventory()
    end
    gps.turnTo(1)
    print("Done.\nThe Farm is filled up.")
end

main()
