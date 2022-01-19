-- Set farmSize=3, and storageFarmSize=9 to use this script.

local database = require("database")
local gps = require("gps")
local posUtil = require("posUtil")
local scanner = require("scanner")
local action = require("action")
local config = require("config")

local args = {...}

--[[ 
    The script aims to transfer stats from a parent crop type to the crop type 
    desired but have low stats.
    
    [P, _, X],
    [_, T, _],
    [X, _, P],
    where P represents parent crop, T represents target crop. X represents a non-farmland
    block. 
    
    According to IC2 breeding rule, The offspring of 2 plants have 45% chance to be either
    the parent plants, and 10% chance to be a new type of crop.
 ]]

  local targetCrop;
 -- The min stats requirement for target crop to be put into storage farm.
 local targetCropMinStats = 46;
 -- Current stats of target crop in the breeding cell.
 local targetCropCurrentStats = 0;
 
 local TARGETCROP_SLOT = 5;

local function isWeed(crop)
    return crop.name == "weed" or 
        crop.name == "Grass" or
        crop.gr > 21 or 
        (crop.name == "venomilia" and crop.gr > 7);
end

 local function checkChildren(slot, crop)
    if crop.name == "air" then
        action.placeCropStick(2);
        return;
    end

    if (not config.assumeNoBareStick) and crop.name == "crop" then
        action.placeCropStick();
        return;
    end

    if not crop.isCrop then
        return;
    end

    if isWeed(crop) then
        action.deweed();
        action.placeCropStick();
        return;
    end

    if crop.name == targetCrop then
        -- Populate breeding cells with high stats crop as priority.
        if targetCropCurrentStats <= targetCropMinStats and calculateStats(crop) > targetCropCurrentStats then
            action.transplant(posUtil.farmToGlobal(slot), posUtil.farmToGlobal(TARGETCROP_SLOT));
            targetCropCurrentStats = calculateStats(crop);
            return;
        end
        
        if calculateStats(crop) >= targetCropMinStats then
            action.transplant(posUtil.farmToGlobal(slot), posUtil.storageToGlobal(database.nextStorageSlot()));
            action.placeCropStick(2);
            return;
        end
    end
    
    action.deweed();
    action.placeCropStick();
 end

 function calculateStats(crop)
    return crop.gr + crop.ga - crop.re;
 end

 local function posEquals(p1, p2)
    return (p1[1] == p2[1]) and (p1[2] == p2[2]);
 end

 local function spreadOnce()
    for slot=1, config.farmArea, 1 do
        local farmPos = posUtil.farmToGlobal(slot);    
        gps.go(farmPos);
        local crop = scanner.scan();

        if slot % 2 == 0 then
            checkChildren(slot, crop);
        end
                
        if action.needCharge() then
            action.charge()
        end

        if #database.getStorage() >= 81 then
            return true;
        end
    end
    return false
end

local function init()
    gps.save();

    gps.go(posUtil.farmToGlobal(TARGETCROP_SLOT));
    targetCrop = scanner.scan().name;
    print(string.format('Target crop recognized: %s.', targetCrop));

    action.restockAll();
    gps.resume();
end

local function main()
    init()
    while not spreadOnce() do
        gps.go({0, 0})
        action.restockAll()
    end
    gps.go({0,0})
    if #args == 1 and args[1] == "docleanup" then
        action.destroyAll()
        gps.go({0,0})
    end
    gps.turnTo(1)
    print("Done.\nThe Farm is filled up.")
end

main()
