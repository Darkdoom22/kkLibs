--[[
    Written By: Uwu/Darkdoom 12/5/2022
    Description: This is a simple vector3 class that can be used to represent a 3d point in space and operate on it.
    Notes: follows memory layout for position order(x,z,y).
]]

local Vector3 = {
    x = 0,
    z = 0,
    y = 0
}

local MetaTable = {
    __index = Vector3,
    __class = "Vector3",
    __tostring = function(self)
        return string.format("Vector3: %.2f, %.2f, %.2f", self.x, self.z, self.y)
    end,
    __metatable = "Vector3 is a protected metatable",
    __add = function(self, other)
        return Vec3(self.x + other.x, self.z + other.z, self.y + other.y)
    end,
    __sub = function(self, other)
        return Vec3(self.x - other.x, self.z - other.z, self.y - other.y)
    end,
    __mul = function(self, other)
        return Vec3(self.x * other.x, self.z * other.z, self.y * other.y)
    end,
    __div = function(self, other)
        return Vec3(self.x / other.x, self.z / other.z, self.y / other.y)
    end,
    __eq = function(self, other)
        return self.x == other.x and self.z == other.z and self.y == other.y
    end,
    __lt = function(self, other)
        return self.x < other.x and self.z < other.z and self.y < other.y
    end,
    __le = function(self, other)
        return self.x <= other.x and self.z <= other.z and self.y <= other.y
    end,
    __unm = function(self)
        return Vec3(-self.x, -self.z, -self.y)
    end,
    __len = function(self)
        return math.sqrt(self.x * self.x + self.z * self.z + self.y * self.y)
    end,
    __concat = function(self, other)
        return string.format("v1:%s v2:%s", tostring(self), tostring(other))
    end
}

function Vec3(...)
    local arg = {...}
    local self = setmetatable({}, MetaTable)
    self.x = 0
    self.y = 0
    self.z = 0
    if(type(arg[1]) == "number")then
        self.x = arg[1]
        self.z = arg[2]
        self.y = arg[3]
    elseif(type(arg[1]) == "table")then
        self.x = arg[1][1]
        self.z = arg[1][2]
        self.y = arg[1][3]
    end
    return self
end

function Vector3:New(x, z, y)
    local self = setmetatable({}, MetaTable)
    self.x = x
    self.z = z
    self.y = y
    return self
end

function Vector3:CalculateFacingAngle(other)
   local deg = (math.atan2(other.y - self.y, other.x - self.x) * 180 / math.pi) * -1;
   return math.rad(deg)
end

function Vector3:Distance(other)
    return math.sqrt((self.x - other.x) * (self.x - other.x) + (self.z - other.z) * (self.z - other.z) + (self.y - other.y) * (self.y - other.y))
end

function Vector3:Dot(other)
    return self.x * other.x + self.z * other.z + self.y * other.y
end

function Vector3:Cross(other)
    return Vec3(self.y * other.z - self.z * other.y, self.z * other.x - self.x * other.z, self.x * other.y - self.y * other.x)
end

function Vector3:Normalize()
    local len = math.sqrt(self.x * self.x + self.z * self.z + self.y * self.y)
    self.x = self.x / len
    self.z = self.z / len
    self.y = self.y / len
end

function Vector3:Normalized()
    local len = math.sqrt(self.x * self.x + self.z * self.z + self.y * self.y)
    return Vec3(self.x / len, self.z / len, self.y / len)
end

function Vector3:Angle(other)
    return math.acos(self:Dot(other) / (self:Length() * other:Length()))
end

function Vector3:Project(other)
    return other:Normalized() * self:Dot(other:Normalized())
end

function Vector3:ProjectOnPlane(other)
    return self - self:Project(other)
end

function Vector3:Reflect(other)
    return self - other * 2 * self:Dot(other)
end

function Vector3:RotateAround(axis, angle)
    local sin = math.sin(angle)
    local cos = math.cos(angle)
    local t = 1 - cos
    local x = self.x
    local y = self.y
    local z = self.z
    local x2 = axis.x * axis.x
    local y2 = axis.y * axis.y
    local z2 = axis.z * axis.z
    local xy = axis.x * axis.y
    local xz = axis.x * axis.z
    local yz = axis.y * axis.z
    local xs = axis.x * sin
    local ys = axis.y * sin
    local zs = axis.z * sin
    self.x = (t * x2 + cos) * x + (t * xy - zs) * y + (t * xz + ys) * z
    self.y = (t * xy + zs) * x + (t * y2 + cos) * y + (t * yz - xs) * z
    self.z = (t * xz - ys) * x + (t * yz + xs) * y + (t * z2 + cos) * z
end

return Vector3

