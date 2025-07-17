--[[
  ____      _    _
 / ___|   _| | _| |_   _ ___
| |  | | | | |/ / | | | / __|
| |__| |_| |   <| | |_| \__ \
 \____\__, |_|\_\_|\__,_|___/
      |___/

  ____        _             _                          _
 / ___| _ __ (_)_ __  _ __ (_)_ __   __ _    ___ _   _| |__   ___
 \___ \| '_ \| | '_ \| '_ \| | '_ \ / _` |  / __| | | | '_ \ / _ \
  ___) | |_) | | | | | | | | | | | | (_| | | (__| |_| | |_) |  __/
 |____/| .__/|_|_| |_|_| |_|_|_| |_|\__, |  \___|\__,_|_.__/ \___|
       |_|                          |___/

This project was created by **IAmCyklus** as a complete Lua rewrite of the original
CubeASCII project by **Tucna**:
https://github.com/tucna/Programming_Projects/blob/main/C%2B%2B/CubeASCII.cpp

Made primarily for **fun and learning** purposes in Lua (tested in Psych Engine,
but might work in other interpreters).

Please note:
- I am still learning Lua. this code is not perfect, but it's a personal project.
- The cube’s shape and camera are delicate; **modifying the code may break it**.
  Only edit if you know what you're doing.
**License:**

This project is licensed under the Apache License 2.0. You're free to use, modify, and distribute it — but please don’t misrepresent the original work or remove attribution.

IMPORTANT:
Make sure you are running the game in a terminal in order to see this script in action!
]]


-- Modifiable values v v
local WIDTH, HEIGHT = 80, 40
local CUBE_SIZE = 12
local CAMERA_DISTANCE = 3
local FOV = 90
local SHADES = ".:-=+*#%@" -- 98% of this doesn't work because i'm stupid
local PI = 3.14159265359 -- don't touch this!

local angleX, angleY = 0, 0

local cube_vertices = {
    {-1, -1, -1},
    {1, -1, -1},
    {1, 1, -1},
    {-1, 1, -1},
    {-1, -1, 1},
    {1, -1, 1},
    {1, 1, 1},
    {-1, 1, 1}
}

local cube_edges = {
    {1, 2},
    {2, 3},
    {3, 4},
    {4, 1},
    {5, 6},
    {6, 7},
    {7, 8},
    {8, 5},
    {1, 5},
    {2, 6},
    {3, 7},
    {4, 8}
}
-- DO NOT TOUCH THE CODE BELOW HERE!
local aspect = WIDTH / HEIGHT
local fovScale = 1 / math.tan(FOV * 0.5 * PI / 180)

local cos, sin, floor, max, min = math.cos, math.sin, math.floor, math.max, math.min

local function rotateX(p, a)
    local c, s = cos(a), sin(a)
    local y = p[2] * c - p[3] * s
    local z = p[2] * s + p[3] * c
    p[2], p[3] = y, z
end

local function rotateY(p, a)
    local c, s = cos(a), sin(a)
    local x = p[1] * c + p[3] * s
    local z = -p[1] * s + p[3] * c
    p[1], p[3] = x, z
end

local function project(p)
    local z = p[3] + CAMERA_DISTANCE
    local scale = fovScale / z * CUBE_SIZE
    local x2d = floor(WIDTH / 2 + p[1] * scale * aspect)
    local y2d = floor(HEIGHT / 2 - p[2] * scale)
    return {x = x2d, y = y2d, depth = z}
end

local function drawLine(screen, p1, p2)
    local avgDepth = (p1.depth + p2.depth) * 0.5
    local shadeIdx = floor((avgDepth - CAMERA_DISTANCE) * 2) + 1
    if shadeIdx < 1 then
        shadeIdx = 1
    end
    if shadeIdx > #SHADES then
        shadeIdx = #SHADES
    end
    local c = SHADES:sub(shadeIdx, shadeIdx)

    local dx = math.abs(p2.x - p1.x)
    local dy = -math.abs(p2.y - p1.y)
    local sx = p1.x < p2.x and 1 or -1
    local sy = p1.y < p2.y and 1 or -1
    local err = dx + dy
    local x, y = p1.x, p1.y

    while true do
        if x >= 1 and x <= WIDTH and y >= 1 and y <= HEIGHT then
            if screen[y][x] == " " or SHADES:find(c) > SHADES:find(screen[y][x]) then
                screen[y][x] = c
            end
        end
        if x == p2.x and y == p2.y then
            break
        end
        local e2 = 2 * err
        if e2 >= dy then
            err = err + dy
            x = x + sx
        end
        if e2 <= dx then
            err = err + dx
            y = y + sy
        end
    end
end

local frameTimer = 0
local frameDelay = 0.03 -- ~33 fps limit

local deltaAngleX = 0.03 * 60 * frameDelay
local deltaAngleY = 0.02 * 60 * frameDelay

function onUpdate(elapsed)
    frameTimer = frameTimer + elapsed
    if frameTimer < frameDelay then
        return
    end
    frameTimer = 0

    angleX = angleX + deltaAngleX
    angleY = angleY + deltaAngleY

    local screen = {}
    for y = 1, HEIGHT do
        screen[y] = {}
        for x = 1, WIDTH do
            screen[y][x] = " "
        end
    end

    local projected = {}
    for i = 1, #cube_vertices do
        local v = cube_vertices[i]
        local p = {v[1], v[2], v[3]}
        rotateX(p, angleX)
        rotateY(p, angleY)
        projected[i] = project(p)
    end

    for _, edge in ipairs(cube_edges) do
        drawLine(screen, projected[edge[1]], projected[edge[2]])
    end

    io.write("\27[H")

    for y = 1, HEIGHT do
        io.write(table.concat(screen[y]), "\n")
    end
    io.flush()
end

function onDestroy()
if package.config:sub(1,1) == "\\" then
    os.execute("cls")   -- Windows
else
    os.execute("clear") -- Unix
end
end

