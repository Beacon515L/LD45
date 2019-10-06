local debugHitboxKey = 'm'
local debugEnabled = false

IterableMap = require("IterableMap")
util = require("util")

local drawSystem = require("draw")
local gameSystem = require("game")

local world
local player = {
    guy = nil,
    ship = nil,
    setKeybind = false, 
    needKeybind = false,
    crawlSpeed = 5,
    girderAddDist = 60,
}

local junkList = {}
local junkIndex = 0

local SPAWN_SIZE = 12000

--------------------------------------------------
-- Draw
--------------------------------------------------

function love.draw()
    drawSystem.draw(world, player, junkList, debugEnabled)
end

--------------------------------------------------
-- Input
--------------------------------------------------

function love.mousemoved(x, y, dx, dy, istouch )
    --ps:moveTo(x,y)
end

function love.mousereleased(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isRepeat)
    if key == debugHitboxKey and not isRepeat then
        debugEnabled = not debugEnabled
    end

    if player.ship and player.needKeybind then
        if not isRepeat then
            if key == 'space' then
                player.setKeybind = not player.setKeybind
            elseif player.setKeybind then
                for i = 1, #player.ship.components do
                    local comp = player.ship.components[i]
                    if comp.def.text and not comp.activeKey then
                        comp.activeKey = key
                    end
                end
                player.setKeybind = false
                player.needKeybind = false
            end
        end
    end
    
    gameSystem.KeypressInput(player.ship, key, isRepeat)
end

local function MouseHitFunc(fixture)
    local fixtureData = fixture:getUserData()
    if fixtureData.junkIndex and not fixtureData.noSelect then
        -- Todo: point intersection
        if gameSystem.TestJunkClick(junkList[fixtureData.junkIndex]) then
            return false
        end
    end

    return true
end

function love.mousepressed(x, y, button, istouch, presses)
    local cx, cy = drawSystem.GetCameraTopLeft()
    local mx, my = x + cx, y + cy
    -- clicking on junk
    --world:queryBoundingBox(mx - 2, my - 2, mx + 2, my + 2, MouseHitFunc)
end

--------------------------------------------------
-- Colisions
--------------------------------------------------

local function beginContact(a, b, coll)
    gameSystem.beginContact(a, b, col1)
end

local function endContact(a, b, coll)
    gameSystem.endContact(a, b, col1)
end

local function preSolve(a, b, coll)

end

local function postSolve(a, b, coll,  normalimpulse, tangentimpulse)

end

--------------------------------------------------
-- Update
--------------------------------------------------

function love.update(dt)
    gameSystem.UpdateInput(player.ship)
    gameSystem.UpdateActivation(player, junkList)

    local cx, cy = drawSystem.GetCameraTopLeft()
    local mx, my = love.mouse.getX() + cx, love.mouse.getY() + cy
    gameSystem.UpdateMovePlayerGuy(player, mx, my)

    if dt < 0.4 then
        world:update(dt)
    end
    gameSystem.ProcessCollisions(player, junkList)
end

--------------------------------------------------
-- Loading
--------------------------------------------------

local function SetupWorld()
    world = love.physics.newWorld(0, 0, true) -- Last argument is whether sleep is allowed.
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    for i = 1, 2000 do
        junkIndex = junkIndex + 1
        junkList[junkIndex] = gameSystem.MakeRandomJunk(world, junkIndex, 0, 0, SPAWN_SIZE, 1000)
    end
end

function love.load()
    math.randomseed(os.clock())
    drawSystem.load()

    SetupWorld()

    junkIndex = junkIndex + 1
    player.guy = gameSystem.SetupPlayer(world, junkList, junkIndex)
end
