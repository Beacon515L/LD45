
local FORCE = 1400

local conf = {
    imageOff = "images/ion engine 1.png",
    imageOn = "images/ion engine on 1.png",
    imageDmg = {"images/ionenginebreak1.png","images/ionenginebreak2.png"},
    imageOrigin = {700, 637},
    imageScale = {0.05, 0.05},
    activationOrigin = {-12.1, 0},
    shapeCoords = {-12.1, -7.35, -9.8, -16.4, 22.5, 0, -9.8, 16.4, -12.1, 7.35},
    walkRadius = 30,
    maxHealth = 240,
    density = 2,
    humanName = "an ion engine",
    getOccurrence = function (dist)
        return util.InterpolateOccurrenceDensity(dist, 0.6, 0.5, 0.2, 0.1)
    end,
    text =
    {
        pos = {5.5, 5},
        rotation = math.pi/2,
        scale = {1, 1},
        color = {0.8,0.1,0.1,1},
    },
    holdActivate = true,
    onFunction = function (comp, body, activeX, activeY, activeAngle, junkList, player, dt)
        local fx, fy = FORCE*math.cos(activeAngle), FORCE*math.sin(activeAngle)
        body:applyForce(fx, fy, activeX, activeY)
        audioSystem.playSound("ion", comp.index)
    end,
}

return conf