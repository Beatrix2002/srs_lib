local SpriteDraw = {}
local spritedraw_mt = { __index = SpriteDraw }

local HasStreamedTextureDictLoaded = HasStreamedTextureDictLoaded
local RequestStreamedTextureDict = RequestStreamedTextureDict
local SetDrawOrigin = SetDrawOrigin
local DrawSprite = DrawSprite
local ClearDrawOrigin = ClearDrawOrigin

function SpriteDraw.new(coords, options)
    options = options or {}
    local self = setmetatable({}, spritedraw_mt)

    self.textureDict = options.textureDict
    self.textureName = options.textureName
    self.coords = coords
    self.bobUpAndDown = options.bobUpAndDown == true
    self.bobPeriod = options.bobPeriod or 1500
    self.bobHeight = options.bobHeight or 0.25

    self.width = options.width or 1.0
    self.height = options.height or 1.0
    self.rotation = options.rotation or 0.0
    self.color = options.color or { r = 255, g = 255, b = 255, a = 255 }
    self.zOffset = options.zOffset or 0.0
    self.useRaycast = options.useRaycast == true
    self.raycastVisible = true

    return self
end

function SpriteDraw:draw(extraZ)
    if self.useRaycast and not self.raycastVisible then return end
    local z = self.coords.z + self.zOffset
    if extraZ then z = z + extraZ end

    SetDrawOrigin(self.coords.x, self.coords.y, z, 0)
    DrawSprite(
        self.textureDict, self.textureName,
        0.0, 0.0,
        self.width, self.height,
        self.rotation,
        self.color.r, self.color.g, self.color.b, self.color.a
    )
    ClearDrawOrigin()
end

return SpriteDraw
