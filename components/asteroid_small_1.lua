local conf = {
    imageOff = "images/asteroid_r1.png",
    imageOn = "images/asteroid_r1.png",
    imageOrigin = {120, 111},
    imageScale = {1, 1},
    activationOrigin = {0, 0},
    shapeCoords = {-20, -108, 54, -98, 114, -26, 107, 73, 32, 110, -112, 64, -117, -1, -85, -57},
    walkRadius = 35,
    maxHealth = 400,
    scaleMax = 0.6,
    scaleMin = 0.15,
    density = 1,
    noAttach = true,
    noSelect = true,
    getOccurrence = function (dist)
        return util.InterpolateOccurrenceDensity(dist, 0.5, 1, 1.1, 1.2)
    end,
}

return conf