
local FORCE = 180

local conf = {
    imageOff = "images/ship debris 1.png",
    imageOn = "images/ship debris 1.png",
    imageOrigin = {450, 450},
    imageScale = {0.06, 0.06},
    activationOrigin = {0, 0},
    shapeCoords = { 7,7, 7,-7, -7,-7, -7,7},
    mass = 20,
    name = "player",
    onFunction = function (self, body, activeX, activeY, activeAngle)
        local fx, fy = FORCE*math.cos(activeAngle), FORCE*math.sin(activeAngle)
        body:applyForce(fx, fy, activeX, activeY)
    end,
}

return conf