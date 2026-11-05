-- Reconcile live ownership immediately before serialization. The registry is
-- transient, belongs to one Risk instance, and is never part of Risk.state.
local SaveSync = {}

function SaveSync.Register(risk, name, fn)
    assert(type(name) == "string" and type(fn) == "function", "invalid save synchronizer")
    local hooks = risk._saveSync
    if not hooks then hooks = {order={}, callbacks={}}; risk._saveSync = hooks end
    if not hooks.callbacks[name] then hooks.order[#hooks.order + 1] = name end
    hooks.callbacks[name] = fn
end

function SaveSync.Run(risk)
    local hooks = risk._saveSync
    if not hooks then return end
    -- A failed synchronizer must prevent encoding/writing a mixed snapshot.
    -- Callbacks only reconcile ownership: never advance timers or grant rewards.
    for _,name in ipairs(hooks.order) do hooks.callbacks[name]() end
end

return SaveSync
