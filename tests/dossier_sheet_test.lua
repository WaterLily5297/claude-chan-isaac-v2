-- MAP dossier cards bind their portrait PNG by its resources-root path after
-- loading the ANM2, so the image shows whichever way the engine resolves the
-- ANM2 Spritesheet Path. Every one of the 22 cards is rendered once.
local root = arg[1]
local modules = {}
local C = {Player = setmetatable({}, {__index = function() return -1 end})}
function include(name)
    if name == "scripts.constants" then return C end
    if not modules[name] then modules[name] = dofile(root .. "/" .. name:gsub("%.", "/") .. ".lua") end
    return modules[name]
end

local callbacks = {}
ModCallbacks = {MC_POST_GAME_STARTED = 1, MC_PRE_GAME_EXIT = 2, MC_POST_RENDER = 3}
ButtonAction = {ACTION_MAP = 11}
Vector = setmetatable({Zero = {}}, {__call = function(_, x, y) return {X = x, Y = y} end})
Input = {IsActionPressed = function(action) return action == ButtonAction.ACTION_MAP end}

local log = {}
function Sprite()
    local s = {calls = {}}
    log[#log + 1] = s
    local function record(name) return function(_, ...) s.calls[#s.calls + 1] = {name, ...} end end
    s.Load = record("Load")
    s.ReplaceSpritesheet = record("ReplaceSpritesheet")
    s.LoadGraphics = record("LoadGraphics")
    s.Play = record("Play")
    s.Render = record("Render")
    return s
end

local current
Isaac = {
    GetPlayerTypeByName = function() return -1 end,
    GetScreenWidth = function() return 480 end,
    GetScreenHeight = function() return 270 end,
    GetPlayer = function() return current end,
    RenderText = function() end,
}
function Game()
    return {
        GetNumPlayers = function() return 1 end,
        GetHUD = function() return {IsVisible = function() return true end} end,
        GetRoom = function() return {IsClear = function() return true end} end,
    }
end

local Dossiers = include("scripts.characters.dossiers")
local Roster = include("scripts.characters.model_roster")
local found
Roster.Find = function() return found end
Dossiers:Init({AddCallback = function(_, id, fn) callbacks[id] = fn end})
callbacks[ModCallbacks.MC_POST_GAME_STARTED]()

local defs = {}
for i, def in ipairs(Dossiers.originals) do def.id = 1000 + i; defs[#defs + 1] = {def, nil} end
for _, def in ipairs(Roster.definitions) do defs[#defs + 1] = {def, def} end
assert(#defs == 22, "all 22 dossier cards are rendered")

for _, pair in ipairs(defs) do
    local def = pair[1]
    found = pair[2]
    current = {ControllerIndex = 0, GetPlayerType = function() return def.id end}
    local before = #log
    callbacks[ModCallbacks.MC_POST_RENDER]()
    assert(#log == before + 1, def.key .. ": one sprite is built on first open")
    local calls = log[#log].calls
    local png = "gfx/ui/dossiers/" .. def.key .. ".png"
    assert(calls[1][1] == "Load" and calls[1][2] == "gfx/ui/dossiers/" .. def.key .. ".anm2", def.key .. ": loads its ANM2")
    assert(calls[2][1] == "ReplaceSpritesheet" and calls[2][2] == 0 and calls[2][3] == png, def.key .. ": binds " .. png)
    assert(calls[3][1] == "LoadGraphics", def.key .. ": reloads graphics after binding")
    assert(calls[4][1] == "Play" and calls[#calls][1] == "Render", def.key .. ": plays and renders")
    assert(io.open(root .. "/resources/" .. png, "rb"), def.key .. ": bound PNG exists under resources/")
    callbacks[ModCallbacks.MC_POST_RENDER]()
    assert(#log == before + 1, def.key .. ": the sprite is cached for later frames")
end
print("PASS dossier_sheet: 22 cards bind their portrait by resources-root path")
