local MarkerDraw = {}
local markerdraw_mt = { __index = MarkerDraw }

local DrawMarker = DrawMarker
local vector3 = vector3

function MarkerDraw.new(coords, options)
    options = options or {}
    local self = setmetatable({}, markerdraw_mt)

    self.type = options.type
    self.coords = coords
    self.direction = options.direction or vector3(0.0, 0.0, 0.0)
    self.rotation = options.rotation or vector3(0.0, 0.0, 0.0)
    self.scale = options.scale or vector3(1.0, 1.0, 1.0)
    self.color = options.color or { r = 255, g = 255, b = 255, a = 255 }
    self.bobUpAndDown = options.bobUpAndDown == true
    self.bobPeriod = options.bobPeriod or 1500
    self.bobHeight = options.bobHeight or 0.25
    self.faceCamera = options.faceCamera == true
    self.rotate = options.rotate == true
    self.textureDict = options.textureDict
    self.textureName = options.textureName
    self.drawOnEnts = options.drawOnEnts == true

    return self
end

function MarkerDraw:draw(extraZ)
    local z = self.coords.z
    if extraZ then z = z + extraZ end

    DrawMarker(
        self.type,
        self.coords.x, self.coords.y, z,
        self.direction.x, self.direction.y, self.direction.z,
        self.rotation.x, self.rotation.y, self.rotation.z,
        self.scale.x, self.scale.y, self.scale.z,
        self.color.r, self.color.g, self.color.b, self.color.a,
        false, self.faceCamera, 2, self.rotate, -- bobUpAndDown false, handled manually
        self.textureDict, self.textureName, self.drawOnEnts
    )
end

return MarkerDraw
