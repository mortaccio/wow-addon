local _, GT = ...

local DRTracker = {}
GT.DRTracker = DRTracker
GT:RegisterModule("DRTracker", DRTracker)

function DRTracker:Init()
    -- TODO: Implement DR category tracking (stun, fear, silence, incap, root, disorient) per unit GUID.
    self.enabled = false
end
