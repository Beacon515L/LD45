local ps
local world
local player
local junkList = {}

local compConfig, compConfigList = unpack(require("components"))

local debugHitboxKey = 'm'
local debugEnabled = false

local setKeybind = false
local needKeybind = false

local drawSystem = require("draw")

local function GetRandomComponent()
    local num = math.random(1, #compConfigList)
    return compConfigList[num].name
end

local function RotateVector(x, y, angle)
	return x*math.cos(angle) - y*math.sin(angle), x*math.sin(angle) + y*math.cos(angle)
end

local function UpdatePlayerComponentAttributes()
    needKeybind = false
    for i = 1, #player.components do
        local comp = player.components[i]
        if comp.def.text and not comp.activeKey then
            needKeybind = true
            break
        end
    end

    if not needKeybind then
        setKeybind = false
    end
end

local function SetupComponent(body, compDefName, params)
    params = params or {}
    local comp = {}
    comp.def = compConfig[compDefName]

    comp.xOff = params.xOff or 0
    comp.yOff = params.yOff or 0
    comp.angle = params.angle or 0

    local xOff, yOff, angle = comp.xOff, comp.yOff, comp.angle
    if comp.def.circleShapeRadius then
        comp.shape = love.physics.newCircleShape(xOff, yOff, comp.def.circleShapeRadius)
    else
        local coords = comp.def.shapeCoords
        local modCoords = {}
        for i = 1, #coords, 2 do
            local cx, cy = RotateVector(coords[i], coords[i + 1], angle)
            cx, cy = cx + xOff, cy + yOff
            modCoords[#modCoords + 1] = cx
            modCoords[#modCoords + 1] = cy
        end
        comp.shape = love.physics.newPolygonShape(unpack(modCoords))
    end
    comp.fixture = love.physics.newFixture(body, comp.shape, comp.def.density)

    comp.activeKey = params.activeKey
    comp.isPlayer  = params.isPlayer
    local fixtureData = params.fixtureData or {}
    fixtureData.noAttach = comp.def.noAttach
    comp.fixture:setUserData(fixtureData)

    return comp
end

local function UpdateInput(ship)
    for i = 1, #ship.components do
        local comp = ship.components[i]
        if comp.def.holdActivate then
            if comp.activeKey and love.keyboard.isDown(comp.activeKey) then
                local ox, oy = ship.body:getWorldPoint(comp.xOff, comp.yOff)
                local vx, vy = comp.def.activationOrigin[1], comp.def.activationOrigin[2]
                local angle = ship.body:getAngle() + comp.angle
                vx, vy = RotateVector(vx, vy, ship.body:getAngle() + comp.angle)
                comp.def:onFunction(ship.body, ox + vx, oy + vy, angle)
                comp.activated = true
            else
                comp.activated = false
            end
        end
    end
end


function love.draw()
    drawSystem.draw(player, junkList, debugEnabled, needKeybind, setKeybind)
end


function love.mousemoved(x, y, dx, dy, istouch )
    --ps:moveTo(x,y)
end

function love.mousereleased(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isRepeat)
    if key == debugHitboxKey and not isRepeat then
        debugEnabled = not debugEnabled
    end

    if not isRepeat then
        if key == 'space' then
            setKeybind = not setKeybind
        elseif setKeybind then
            for i = 1, #player.components do
                local comp = player.components[i]
                if comp.def.text and not comp.activeKey then
                    comp.activeKey = key
                end
            end
            setKeybind = false
            needKeybind = false
        end
    end
end

local function LoadComponentResources()
    for name, def in pairs(compConfig) do
        def.imageOff = love.graphics.newImage(def.imageOff)
        def.imageOn = love.graphics.newImage(def.imageOn)
    end
end

--------------------------------------------------
-- Colisions
--------------------------------------------------

local collisionToAdd

local function beginContact(a, b, coll)
    local aData, bData = a:getUserData() or {}, b:getUserData() or {}
    if aData.noAttach or bData.noAttach then
        return
    end
    if aData.isPlayer == bData.isPlayer then
        return
    end
    playerFixture = (aData.isPlayer and a) or b
    otherFixture  = (bData.isPlayer and a) or b

    collisionToAdd = collisionToAdd or {}
    collisionToAdd[#collisionToAdd + 1] = {playerFixture, otherFixture}
end

local function endContact(a, b, coll)

end

local function preSolve(a, b, coll)

end

local function postSolve(a, b, coll,  normalimpulse, tangentimpulse)

end

--------------------------------------------------
-- Update
--------------------------------------------------

local function DoMerge(playerFixture, otherFixture)
    if otherFixture:isDestroyed() then
        return
    end

    local otherData = otherFixture:getUserData()
    if not otherData.junkIndex then
        return
    end
    local junk = junkList[otherData.junkIndex]

    local junkBody = junk.body
    local playerBody = playerFixture:getBody()

    for i = 1, #junk.components do
        local comp = junk.components[i]
        local xOff, yOff = playerBody:getLocalPoint(junkBody:getWorldPoint(comp.xOff, comp.yOff))

        local angle = junkBody:getAngle() - playerBody:getAngle() + comp.angle

        player.components[#player.components + 1] = SetupComponent(playerBody, otherData.compDefName, {
                isPlayer = true,
                fixtureData = {isPlayer = true, compDefName = compDefName},
                xOff = xOff,
                yOff = yOff,
                angle = angle,
            }
        )
    end
    
    otherFixture:getBody():destroy()
    junkList[otherData.junkIndex] = nil

    UpdatePlayerComponentAttributes()
end

local function ProcessCollisions()
    for i = 1, #collisionToAdd do
        local playerFixture, otherFixture = collisionToAdd[i][1], collisionToAdd[i][2]
        DoMerge(playerFixture, otherFixture)
    end
    collisionToAdd = false
end

function love.update(dt)
    UpdateInput(player)
    world:update(0.033)
    if collisionToAdd then
        ProcessCollisions()
    end
end

--------------------------------------------------
-- Loading
--------------------------------------------------

local function MakeJunk(index)
    local junk = love.physics.newBody(world, math.random()*1000 - 500, math.random()*1000 - 500, "dynamic")

    local compDefName = GetRandomComponent()
    local comp = SetupComponent(junk, compDefName, {fixtureData = {junkIndex = index, compDefName = compDefName}})
    junk:setAngle(math.random()*2*math.pi)
    junk:setLinearVelocity(math.random()*4, math.random()*4)
    junk:setAngularVelocity(math.random()*2*math.pi)
    junkList[#junkList + 1] = {
        body = junk,
        components = {comp}
    }
end

local function SetupWorld()
    world = love.physics.newWorld(0, 0, true) -- Last argument is whether sleep is allowed.
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    for i = 1, 20 do
        MakeJunk(i)
    end
end

local function SetupPlayer()
    local body = love.physics.newBody(world, 0, 0, "dynamic")
    body:setAngularVelocity(0.8)

    local components = {}
    components[1] = SetupComponent(body, "booster", {isPlayer = true, fixtureData = {isPlayer = true, compDefName = compDefName}})

    return {
        body = body,
        components = components,
    }
end

function love.load()
    math.randomseed(os.clock())
    drawSystem.load()

    LoadComponentResources()

    SetupWorld()
    player = SetupPlayer()
    UpdatePlayerComponentAttributes()
end
