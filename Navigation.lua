--[[
    Written By: Uwu/Darkdoom 12/7/2022
    Description: This is a wrapper around a wrapper for Xenonsmurf's FFXINAV.dll navmesh library to facilitate movement around the game world.
    Notes: there is some confusing inconsistent vector3 keying going on right now, the mesh dll swaps z and y naming but mine doesn't, will fix
]]

--TODO: Nav functions need to go inside a class and regiser that, globally registering them is just temporary

require("libs.Tables")
require("libs.Vector3")
local ZoneNames = require("res.ZoneNames")
--TODO: add lib / addon path functions to api
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*[/\\])") or "./"
end

--TODO: need a file system class too
function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
 end

local Navigation = {
    CurrentZoneId = 0,
    LastZoneId = 0,
    MeshLoaded = false,
    CurrentPath = T{},
    BestWaypoint = Vec3{},
    CurrentGoal = Vec3{},
    NumWaypointsLeftBeforeUpdatingPath = 3,
}

local MetaTable = {
    __index = Navigation,
}

function Nav()
    local self = setmetatable({}, MetaTable)
    return self
end

function Navigation:TryLoadMesh()
    if(GetNavDllBaseAddress() == 0)then
        print("FFXINAV.dll not loaded\n")
        return false
    end
    local curZoneId = GetZoneId()
    local zoneName = ZoneNames[curZoneId]
    if(curZoneId and zoneName and curZoneId ~= 0 and curZoneId ~= self.CurrentZoneId)then
        self.LastZoneId = self.CurrentZoneId
        self.CurrentZoneId = curZoneId
        self.CurrentPath = T{}
        self.BestWaypoint = Vec3{}
        local path = script_path().."Dumped NavMeshes/"..zoneName..".nav"
        if(file_exists(path))then
            local success = LoadMesh(path)
            if(success > 0)then
                print("Mesh loaded for zone "..zoneName.."\n")
                self.CurrentPath = T{}
                self.BestWaypoint = Vec3{}
                return true
            end
            print("Failed to load mesh for zone "..zoneName.."\n")
            return false
        end
    end
end

--nav dll expects y and z flipped
function Navigation:FindPath(dest)
    local localActor = GetLocalActor()
    if(localActor and self.CurrentPath and self.CurrentPath:Length() == 0)then 
        local ourPos = {x = localActor.X, y = localActor.Z, z = localActor.Y}
        local waypoints = T(FindPath(ourPos, dest))
       -- print("Found "..waypoints:Length().." waypoints\n")
        self.CurrentPath = waypoints
        self.CurrentGoal = dest
        return waypoints:Length()
    end
end

function Navigation:MoveToBestWaypoint()
    local localActor = GetLocalActor()
    if(localActor and self.CurrentPath and self.CurrentPath:Length() > 0)then
        local ourPos = Vec3{localActor.X, localActor.Y, localActor.Z}
        local nextWp = self.CurrentPath:First()
        if(nextWp)then
            --print("Best waypoint found\n")
            local dist = ourPos:Distance(nextWp)
            --print("Distance to waypoint: "..dist.."\n")
            --print("wp: "..nextWp.x..", "..nextWp.z..", "..nextWp.y.."\n")
            if(dist > 2.5)then
                self.BestWaypoint = Vec3{nextWp.x, nextWp.y, nextWp.z}
                --print(string.format("Moving to waypoint: %s, %s, %s\n", nextWp.x, nextWp.z, nextWp.y))
                GameManager:GetMovementManager():MoveTo(nextWp.x, nextWp.y, nextWp.z)--todo standardize capitalization
            else
                --print("Waypoint reached\n")
                self.CurrentPath:Remove(nextWp)
            end
        else
            print("No best waypoint found\n")
        end
    end
end

--NOTE: only call this method from addon["Present"]
function Navigation:DrawWaypointsWS()
    local count = 0
    for wp in self.CurrentPath:It() do
        DrawOutlinedTextWS(string.format("Waypoint: %s", count), 50, 200, 50, wp.x, wp.y, wp.z)
        count = count + 1
    end 
end