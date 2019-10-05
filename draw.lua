local cameraX, cameraY = 0, 0
local smoothCameraFactor = 0.25

local starfield = require("starfield")
local util = require("util")

local shipPart 

local function intersection (x1, y1, x2, y2, x3, y3, x4, y4)
  local d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
  local a = x1 * y2 - y1 * x2
  local b = x3 * y4 - y3 * x4
  local x = (a * (x3 - x4) - (x1 - x2) * b) / d
  local y = (a * (y3 - y4) - (y1 - y2) * b) / d
  return x, y
end

local function getAngles(self, sourceX, sourceY)
    local angles = {}
    
    for i = 1, #self / 2 do
        angles[#angles + 1] = math.atan2(sourceY - self[2 * i], sourceX - self[(2 * i) - 1])
    end
    
    return angles
end

local function distance (x1, y1, x2, y2)
      local dx = x1 - x2
  local dy = y1 - y2
  return math.sqrt ( dx * dx + dy * dy )    
end

local function paintShadows (bodyList, lightSource, minDistance)
    
    --check for polygon light sources, or circular bodies
    
    --bodies
    for i = 1, #bodyList do
        fixtures = bodyList[i]:getFixtures()
        
        --fixtures
        for j = 1, #fixtures do
            
            local shadowPoints = {}
            
            local shape = fixtures[j]:getShape()
            
            --points for fixture
            local points = {shape:getPoints()}
            local _points = {junkList[i]:getWorldPoints(points[1], points[2], points[3], points[4], points[5], points[6], points[7], points[8])}
            
            for i = 1, #_points / 2 do
                if distance(_points[2 * i - 1], _points[2 * i], lightSource.x, lightSource.y) < minDistance then
                    goto continue
                end
            end
            
            local angles = getAngles(_points, lightSource.x, lightSource.y)
            local compAngles = {}
            
            for i = 1, #angles do
                compAngles[i] = angles[i]
            end
            
            table.sort(angles)
            
            minAngle = angles[1]
            maxAngle = angles[#angles]
            
            local maxAngleNo = 0
            local minAngleNo = 0
            
            for i = 1, #angles do
                if compAngles[i] == minAngle then
                    minAngleNo = i
                end
                
                if compAngles[i] == maxAngle then
                    maxAngleNo = i
                end
                
            end

            edgePoints = {}
            edgePoints[1] = _points[(2 * minAngleNo) - 1]
            edgePoints[2] = _points[2 * minAngleNo]
            edgePoints[3] = _points[(2 * maxAngleNo) - 1]
            edgePoints[4] = _points[2 * maxAngleNo]
            
            shadowPoints[1] = edgePoints[3]
            shadowPoints[2] = edgePoints[4]
            shadowPoints[3] = edgePoints[1]
            shadowPoints[4] = edgePoints[2]

            --draw lines tracing from shape edges
            for i = 1, 2 do
                --project line to edge of screen
                --top or bottom?
                local angle = math.atan2(lightSource.y - edgePoints[2 * i], lightSource.x - edgePoints[(2 * i) - 1])
                
                if angle > 0 and angle < math.pi then
                    --top
                    intersectX, intersectY = intersection(lightSource.x, lightSource.y, edgePoints[(2 * i) - 1], edgePoints[2 * i], 0, 0, winWidth, 0)
                
                elseif angle < 0 and angle > - math.pi then
                    --bottom
                    intersectX, intersectY = intersection(lightSource.x, lightSource.y, edgePoints[(2 * i) - 1], edgePoints[2 * i], 0, winHeight, winWidth, winHeight)
                    
                else
                    --direct horizontal, skip this step and move to left or right
                    if angle == 0 then
                        --right
                        intersectX, intersectY = intersection(lightSource.x, lightSource.y, edgePoints[(2 * i) - 1], edgePoints[2 * i], winWidth, 0, winWidth, winHeight)
                    else
                        --left
                        intersectX, intersectY = intersection(lightSource.x, lightSource.y, edgePoints[(2 * i) - 1], edgePoints[2 * i], 0, 0, 0, winHeight)
                        
                    end     
                end
                     
                if intersectX < 0 then
                    --left
                    intersectX, intersectY = intersection(lightSource.x, lightSource.y, edgePoints[(2 * i) - 1], edgePoints[2 * i], 0, 0, 0, winHeight)
                        
                elseif intersectX > winWidth then
                    --right
                    intersectX, intersectY = intersection(lightSource.x, lightSource.y, edgePoints[(2 * i) - 1], edgePoints[2 * i], winWidth, 0, winWidth, winHeight)
                    
                end
                                
                shadowPoints[3 + (2 * i)] = intersectX
                shadowPoints[4 + (2 * i)] = intersectY
            end    
            
            --draw the shadow shape  
            love.graphics.polygon("fill", shadowPoints)
        end
        
        ::continue::
    end
end

local function DrawShipVectors(ship)
    for i = 1, #ship.components do
        local comp = ship.components[i]
        local ox, oy = ship.body:getWorldPoint(comp.xOff, comp.yOff)
        local vx, vy = comp.def.activationOrigin[1], comp.def.activationOrigin[2]
        local angle = ship.body:getAngle() + comp.angle
        vx, vy = util.RotateVector(vx, vy, ship.body:getAngle() + comp.angle)
        local dx, dy = ox + vx, oy + vy
        love.graphics.line(dx, dy, dx + 20*math.cos(angle), dy + 20*math.sin(angle))
        love.graphics.circle("line", dx, dy, 10)
    end
end

local function DrawDebug(world, player)
    love.graphics.setColor(1,0,0,1)
    local bodies = world:getBodies()
    for i = 1, #bodies do
        local fixtures = bodies[i]:getFixtures()
        for j = 1, #fixtures do
            local shape = fixtures[j]:getShape()
            local shapeType = shape:getType()
            if shapeType == "polygon" then
                local points = {bodies[i]:getWorldPoints(shape:getPoints())}
                love.graphics.polygon("line", points)
            elseif shapeType == "circle" then
                local x, y = bodies[i]:getWorldPoint(shape:getPoint())
                love.graphics.circle("line", x, y, shape:getRadius())
            end
        end
    end

    DrawShipVectors(player)

    love.graphics.setColor(1, 1, 1, 1)
end

local function DrawShip(ship)
    for i = 1, #ship.components do
        local comp = ship.components[i]
        local dx, dy = ship.body:getWorldPoint(comp.xOff, comp.yOff)

        local image = (comp.activated and comp.def.imageOn) or comp.def.imageOff

        love.graphics.draw(image, dx, dy, ship.body:getAngle() + comp.angle, 
            comp.def.imageScale[1], comp.def.imageScale[2], comp.def.imageOrigin[1], comp.def.imageOrigin[2])

        if comp.def.text ~= nil and comp.isPlayer then
            local textDef = comp.def.text
            local keyName = comp.activeKey or "??"

            love.graphics.setColor(unpack(comp.def.text.color))
            love.graphics.print(string.upper(keyName), dx, dy, ship.body:getAngle() + comp.angle + textDef.rotation, textDef.scale[1], textDef.scale[2], textDef.pos[1], textDef.pos[2])
            love.graphics.setColor(1,1,1,1)
        end
    end

    if debugEnabled then
        love.graphics.draw(shipPart, ship.body:getX(), ship.body:getY(), ship.body:getAngle(), 0.02, 0.02, 400, 300)
    end
end

local function UpdateCameraPos(player)
    local px, py = player.body:getWorldCenter()
    cameraX = (1 - smoothCameraFactor)*cameraX + smoothCameraFactor*px
    cameraY = (1 - smoothCameraFactor)*cameraY + smoothCameraFactor*py

    return cameraX, cameraY
end

local externalFunc = {}

function externalFunc.draw(world, player, junkList, debugEnabled, needKeybind, setKeybind) 
    local winWidth  = love.graphics:getWidth()
    local winHeight = love.graphics:getHeight()

    love.graphics.push()

    local cx, cy = UpdateCameraPos(player)
    local stars = starfield.locations(cx, cy)
    love.graphics.points(stars)

    love.graphics.translate(winWidth/2 - cx, winHeight/2 - cy)
    -- Worldspace
    for _, junk in pairs(junkList) do
        DrawShip(junk)
    end

    DrawShip(player)

    if debugEnabled then
        DrawDebug(world, player)
    end

    love.graphics.pop()
    -- UI space

    if needKeybind and not setKeybind then
        love.graphics.print("Press space to set unbound component keys", 10, 10, 0, 2, 2)
    elseif setKeybind then
        love.graphics.print("Press any key to set a keybind", 10, 10, 0, 2, 2)
    end
end

local function LoadComponentResources()
    local compConfig, compConfigList = unpack(require("components"))
    for name, def in pairs(compConfig) do
        def.imageOff = love.graphics.newImage(def.imageOff)
        def.imageOn = love.graphics.newImage(def.imageOn)
    end
end

function externalFunc.load()
    shipPart = love.graphics.newImage('images/ship.png')
    LoadComponentResources()
end

return externalFunc
