--[[
    Written By: Uwu/Darkdoom 12/8/2022
    Description: Convert packets into human friendly formats and handle packet manipulation
    Notes: This is a work in progress, lot to do
]]

--package.loaded["ffi"] = nil
local ffi = require("ffi")
local reflect = require("libs.reflect")

ffi.cdef[[
    struct RecvMenuCalc         //incoming 0x032
    {
        uint32_t Header;
        uint32_t NpcId;         //_CliEventUniqueNo_NpcId = pEVar1->field4_0x4;
        uint16_t NpcIndex;      //_CliEventIndex_NpcIndex = pEVar1->field5_0x8;
        uint16_t ZoneId;        //_CliEventNum_ZoneId = pEVar1->field6_0xa;
        uint16_t MenuId;        //_CliEventParam_MenuId = pEVar1->field7_0xc;
        uint16_t CliEventMode;  //__CliEventMode = param_3->field8_0xe | 0x2000; not sure what this is used for
        uint16_t SubZoneId;     /*if ((subZoneId < 1000) || (0x513 < subZoneId)) {
                                    subZoneId = pktSubZoneId;
                                    if (zoneId == pktSubZoneId) goto LAB_100ad3dd;
                                }
                                zoneId = subZoneId + 1000*/
        uint16_t unk;           //set from each flavor of menu interaction packets, only used in one place (possibly related to menu ui)
    }; 
    struct RecvCharNpc//incoming 0x00E
    {
        uint32_t Header;
        uint32_t NpcId;
        uint16_t NpcIndex;
        uint8_t UpdateMask; 
        uint8_t EncodedRotation;
        float X;
        float Z;
        float Y;
        uint32_t RunCount;
        uint16_t Unk1;
        uint8_t HpPercent;
        uint8_t Status;
        uint32_t Unk2;
        uint32_t Unk3;
        uint32_t Unk4;
        uint32_t ClaimId;
        uint16_t Unk5;
        uint16_t Model;
        char Name[18];
    };
]]

local Packets = {

}

--probably a better way to get the base type for the reflection lib to work
Packets.strDefs = {
    incoming = {
        [0x0E] = {type=ffi.typeof("struct RecvCharNpc"), name="RecvCharNpc"},
        [0x32] = {type=ffi.typeof("struct RecvMenuCalc"), name="RecvMenuCalc"},
    },
    outgoing = {

    },
}

Packets.defs = {
    incoming = { 
        [0x0E] = ffi.typeof("struct RecvCharNpc*"),
        [0x32] = ffi.typeof("struct RecvMenuCalc*"),
    },
    outgoing = {

    },
}

local MetaTable = {
    __index = Packets,
}

local function ToBits(num)
    local t = {}
    while num > 0 do
        rest = math.fmod(num,2)
        t[#t+1] = rest
        num = (num-rest) / 2
    end
    --pad with 0s if not 8 bit aligned from start
    if(#t % 8 ~= 0)then
        local pad = 8 - (#t % 8)
        for i = 1, pad do
            t[#t+1] = 0
        end
    end
    return t
end

function Packets:ReflectFormatPacketStr(dir, id, cDataPacket)
    local str = string.format("Packet: %s\n", self.strDefs[dir][id] and self.strDefs[dir][id].name or tostring(id))
    if(dir and id and cDataPacket)then
        for reflection in reflect.typeof(self.strDefs[dir][id].type):members() do
            local name = reflection.name
            local ctype = reflection.type
            local value = cDataPacket[name]
            if(type(value) == 'cdata')then
                value = ffi.string(value)
            end
            if(type(value) == 'number')then
                local bits = ToBits(value)
                local bitStr = ")"
                for i = 1, #bits do
                    if(i % 8 == 0 and i < #bits)then
                        bitStr = string.format("%s%s ", bitStr, bits[i])
                    else
                        bitStr = string.format("%s%s", bitStr, bits[i])
                    end
                end
                bitStr = string.format("(%s", string.reverse(bitStr))
                str = string.format("%s[%s]: %s %s\n", str, name, value, bitStr)
            else
                str = string.format("%s[%s]: %s\n", str, name, value)
            end
        end
    end
    return str
end

function Packets:Unpack(dir, id, data)
    if(dir and id and data and self.defs[dir][id])then
        local cBuff = ffi.new("uint8_t[?]", #data, data)
        local pCBuff = ffi.cast("uint8_t*", cBuff)
        local packet = ffi.cast(self.defs[dir][id], pCBuff)
        return packet
    end
end

return Packets