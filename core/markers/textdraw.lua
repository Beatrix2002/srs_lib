local TextDraw = {}
local textdraw_mt = {__index = TextDraw}

local SetDrawOrigin = SetDrawOrigin
local SetTextFont = SetTextFont
local SetTextProportional = SetTextProportional
local SetTextScale = SetTextScale
local SetTextColour = SetTextColour
local SetTextDropshadow = SetTextDropshadow
local SetTextEdge = SetTextEdge
local SetTextOutline = SetTextOutline
local SetTextCentre = SetTextCentre
local SetTextRightJustify = SetTextRightJustify
local SetTextWrap = SetTextWrap
local BeginTextCommandDisplayText = BeginTextCommandDisplayText
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local EndTextCommandDisplayText = EndTextCommandDisplayText
local ClearDrawOrigin = ClearDrawOrigin
local vector3 = vector3

function TextDraw.new(text, coords, options)
    options = options or {}
    local self = setmetatable({}, textdraw_mt)

    self.text = text
    self.coords = coords
    self.bobUpAndDown = options.bobUpAndDown == true
    self.bobPeriod = options.bobPeriod or 1500
    self.bobHeight = options.bobHeight or 0.25

    self.zOffset = options.zOffset or 1.2
    self.font = options.font
    self.scale = options.scale or 0.35
    self.proportional = options.proportional ~= false
    self.color = options.color or { r = 255, g = 255, b = 255, a = 215 }
    self.shadow = options.shadow -- { distance, r, g, b, a }
    self.edge = options.edge -- { index, r, g, b, a }
    self.outline = options.outline ~= false
    self.centre = options.centre ~= false
    self.right = options.right or false
    self.wrap = options.wrap -- { min, max }
    self.offset = options.offset and vector3(options.offset.x, options.offset.y, options.offset.z) or vector3(0.0, 0.0, 0.0)
    self.offset = vector3(
        self.offset.x + 0.0,
        self.offset.y + 0.0,
        self.offset.z
    )
    self.useRaycast = options.useRaycast == true
    self.raycastVisible = true

    return self
end

    
function TextDraw:draw(extraZ)
    if self.useRaycast and not self.raycastVisible then return end
    local z = self.coords.z + self.zOffset
    if extraZ then z = z + extraZ end

    SetDrawOrigin(self.coords.x, self.coords.y, z, 0)
    if self.font then SetTextFont(self.font) end
    if self.proportional then SetTextProportional(1) end
    SetTextScale(0.0, self.scale)
    SetTextColour(self.color.r, self.color.g, self.color.b, self.color.a)

    if self.shadow then
        SetTextDropshadow(self.shadow.distance, self.shadow.r, self.shadow.g, self.shadow.b, self.shadow.a)
    end
    
    if self.edge then
        SetTextEdge(self.edge.index, self.edge.r, self.edge.g, self.edge.b, self.edge.a)
    end
    
    if self.outline then SetTextOutline() end
    if self.centre then SetTextCentre(true) end
    if self.right then SetTextRightJustify(true) end
    if self.wrap then SetTextWrap(self.wrap.min, self.wrap.max) end

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(self.text)
    EndTextCommandDisplayText(self.offset.x, self.offset.y)
    ClearDrawOrigin()
end

return TextDraw