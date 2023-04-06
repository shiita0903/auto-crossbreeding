local component = require("component")
local geolyzer = component.geolyzer
local sides = require("sides")

local function scan()
    local rawResult = geolyzer.analyze(sides.down)
    if rawResult.name == "minecraft:air" or rawResult.name == "GalacticraftCore:tile.brightAir" then
        return { isCrop = false, name = "air" }
    elseif rawResult.name == "IC2:blockCrop" then
        if rawResult["crop:name"] == nil then
            return { isCrop = false, name = "crop" }
        elseif rawResult["crop:name"] == "weed" then
            return { isCrop = true, name = "weed" }
        else
            local gr = rawResult["crop:growth"]
            local ga = rawResult["crop:gain"]
            local re = rawResult["crop:resistance"]
            return {
                isCrop = true,
                name = rawResult["crop:name"],
                gr = gr,
                ga = ga,
                re = re,
                stats = gr + ga - re,
                tier = rawResult["crop:tier"]
            }
        end
    else
        return { isCrop = false, name = rawResult.name }
    end
end

return {
    scan = scan
}
