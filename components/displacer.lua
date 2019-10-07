local POWER = 3.5

local conf = {
    imageOff = "images/displacer.png",
    imageOn = "images/displaceron.png",
    imageDmg = {"images/displacerbreak1.png","images/displacerbreak2.png"},
    imageOrigin = {500, 550},
    imageScale = {0.2, 0.2},
    activationOrigin = {0, 0},
    shapeCoords = {-60,-20, 60,-20, 60,10, 25,30, -25,30, -60,10},
    walkRadius = 40,
    maxHealth = 400,
    density = 1,
    humanName = "a phase engine",
    getOccurence = function (dist)
        if dist < 25000 then
            return 0
        elseif dist < 55000 then
            return 0.5
        else
            return 0.2
        end
    end,
    text =
    {
        pos = {-5, 5},
        rotation = 0,
        scale = {1, 1},
        color = {0.8,0.1,0.1,1},
    },
    toggleActivate = true,
    onFunction = function (comp, body, activeX, activeY, activeAngle, junkList, player, dt)
        util.AddPhaseRadius(player.guy, activeX, activeY, 400, dt*POWER)
        if player.ship then
            util.AddPhaseRadius(player.ship, activeX, activeY, 400, dt*POWER)
        end
    end,
}

return conf