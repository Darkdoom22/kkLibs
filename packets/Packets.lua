--[[
    Written By: Uwu/Darkdoom 12/8/2022
    Description: Convert packets into human friendly formats and handle packet manipulation
    Notes: This is a work in progress, lot to do
]]

package.loaded["ffi"] = nil
local ffi = require("ffi")
local reflect = require("libs.reflect")

ffi.cdef[[
    struct pktHeader    //handling headers entirely on the c side, this version of luajit doesn't have bitfield support - leaving as reference
    {
        uint16_t id : 9;
        uint16_t len : 7;
        uint16_t seq : 16;
    };

    struct SendCharPos          //outgoing 0x015
    {
        uint32_t Header;
        float X;
        float Z;
        float Y;
        uint16_t pad;
        uint16_t RunCount;
        uint8_t EncodedRotation;
        uint8_t Flags;
        uint16_t TargetIndex;
        uint32_t Timestamp;
        uint32_t junk; //this and pad are never set in XiAtelBuff::SendCharPos
    };

    /*Outgoing*/
    struct ActionPacket         //outgoing 0x01A
    {
        uint32_t Header;
        uint32_t TargetId;
        uint16_t TargetIndex;
        uint16_t Category;
        uint16_t Parameter;
        uint16_t Unk1;
        float XOffset; //for geo bubble positioning system
        float ZOffset;
        float YOffset;
    };

    typedef struct EquipSetEntry EquipSetEntry;

    struct EquipSetEntry        //not a packet, but used in EquipSet
    {
        uint8_t InventoryIndex;
        uint8_t EquipmentSlot;
        uint8_t Bag;
        uint8_t Pad;
    };

    struct EquipSet             //outgoing 0x051
    {
        uint32_t Header;
        uint8_t EquipCount;
        uint8_t pad;
        uint8_t pad2;
        uint8_t pad3;
        EquipSetEntry Entries[16];
    };

    struct SendPendingTag               //outgoing 0x05b, two handlers: SendPendingTag, SendEventEnd
    {
        uint32_t Header;
        uint32_t ActorId;               //puVar1->NpcId = _CliEventUniqueNo_NpcId;
        uint16_t OptionIndex;           //*(undefined4 *)&puVar1->OptionIndex = _CliEventIndex;
        uint16_t CancelEvent;           //*(undefined4 *)&pkt->OptionIndex = 0x40000000; this implies that OptionIndex is actually just treated as 4 bytes, this set only happens when gMenuCancelEvent is set in SendEventEnd.
        uint16_t ActorIndex;            //pkt->NpcIndex = _CliEventIndex_NpcIndex;
        uint16_t ContinueInteraction;   //*(undefined2 *)&puVar1->AutomatedMessage = 1; true if from SendPendingTag, false if from SendEventEnd
        uint16_t ZoneId;                //puVar1->ZoneId = _CliEventNum_ZoneId;
        uint16_t MenuId;                //puVar1->MenuId = _CliEventParam_MenuId;
    };

    struct SendPendingXzyTag            //outgoing 0x05c, used to warp in menus (going through staging point doors, zeruhn mines door, homepoints, etc)
    {
        uint32_t Header;
        float X;
        float Z;
        float Y;
        uint32_t ActorId;
        uint32_t OptionIndex;          //menuWarpRqst->MenuOptionIndex = _CliEventIndex
        uint16_t ZoneId;               //menuWarpRqst->Zone = _CliEventNum_ZoneId;
        uint16_t ActorIndex;
        uint8_t ContinueInteraction;   //menuWarpRqst->ContinueInteraction = '\x01'; always true
        uint8_t EncodedRotation;       //lVar2 = enDirCliToNet(param4); menuWarpRqst->Rotation = (char)lVar2;  
    };

    /*Incoming*/       

    struct RecvCharNpc          //incoming 0x00E
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

    struct RecvBattleCalc2          //incoming 0x028
    {
        uint32_t Header;
        uint8_t Length;
        uint32_t ActorId;
        uint8_t PackedData[?];      //param1 is either action id or the second half of a 4cc combined with the next 2 bytes
    } __attribute__((packed));      //variable length packet, if not using __attribute__((packed)) then the compiler will pad the struct to 4 byte alignment

    struct RecvBattleMessage        //incoming 0x029
    {
        uint32_t Header;
        uint32_t ActorId;
        uint32_t TargetId;
        uint16_t CommandMessWork;   //_CommandMessWork = localActionmsg->Param1;
        uint16_t CommandMessWork2;  //DAT_10474a9c = localActionmsg->Param2;
        uint16_t ActorIndex;        //_MESCASNAMEINDEX = localActionmsg->ActorIndex;
        uint16_t TargetIndex;       //_MESTARNAMEINDEX = localActionmsg->TargetIndex;
        uint16_t Message;
        uint16_t Unk1;
    };

    struct RecvMessageTalkNumWork       //incoming 0x2A -- more commonly known as "Resting Message"
    {
        uint32_t Header;
        uint32_t ActorId;
        uint32_t Param1;                //get copied to gMenu34Params, interpretation is based on message id                        
        uint32_t Param2;
        uint32_t Param3;
        uint16_t ServerEventIndex;      //_ServerEventIndex = uVar2; uVar2 set from pkt->0x18 depending on the results of some id/index checks based on 0x1d and 0x1e fields
        uint16_t MessageId;
        uint8_t  MesNumTypeTableIndex;  //local_154 = (&MesNumTypeTbl)[param_3->field11_0x1c];
        uint8_t Unk1;
        uint8_t Unk2;                   //these are used, but I'm not sure what they effect
    };

    struct RecvBattleMessage2            //incoming 0x2D
    {
        uint32_t Header;
        uint32_t ActorId;
        uint32_t TargetId;
        uint16_t ActorIndex;
        uint16_t TargetIndex;
        uint32_t Param1;
        uint32_t Param2;
        uint16_t Message;
        uint8_t Unk;                    //used instead of the message for EventMessDecodePut in some cases, unsure purpose
    };

    struct RecvEventCalc        //incoming 0x032
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

                                //incoming 0x033 - RecvEventCalcStr
                                
    struct RecvEventCalcNum     //incoming 0x034 - RecvEventCalcNum
    {
        uint32_t Header;
        uint32_t NpcId;         //_CliEventUniqueNo_NpcId = pkt->field4_0x4;
        uint8_t MenuParams[32]; //Menu34Params = memcpy(Menu34Params, pkt->field5_0x8, 0x20);~psuedo
        uint16_t NpcIndex;      //_CliEventIndex_NpcIndex = pkt->field34_0x28;
        uint16_t ZoneId;        //_CliEventNum_ZoneId = pkt->field35_0x2a;
        uint16_t MenuId;        //_CliEventParam_MenuId = pkt->field36_0x2c;
        uint16_t CliEventMode;  //__CliEventMode = param_3->field37_0x2e & 0xff | (ushort)(byte)((uint)param_3->field37_0x2e >> 8) << 8 | 0x2000;
        uint16_t SubZoneId;     //same as 32, these get passed to InitEvent() along with the current SubZoneId in memory and the other zone Id in the packet and the menu id
        uint16_t unk;           //same as 32
    };                  
    
    struct RecvMessageTalkNum           //incoming 0x036
    {
        uint32_t Header;
        uint32_t ActorId;               //if (pEVar1->Id != *(uint *)(param_3 + 4)) 
        uint16_t ServerEventIndex;      //serverEventIndex = *(ushort *)(param_3 + 8);
        uint16_t Message;           
        uint8_t  MesNumTypeTableIndex;  //  if (param_3->field7_0xc < 8) { local_4c = (&MesNumTypeTbl)[param_3->field7_0xc]; } else { local_4c = 0; }
    };

    struct RecvCliStatus                //incoming 0x061
    {
        uint32_t Header;
        uint32_t MaxHealth;
        uint32_t MaxMp;
        uint8_t MainJob;
        uint8_t MainJobLevel;
        uint8_t SubJob;
        uint8_t SubJobLevel;
        uint16_t CurrentExp;
        uint16_t NextLevelExp;
        uint16_t BaseStr;
        uint16_t BaseDex;
        uint16_t BaseVit;
        uint16_t BaseAgi;
        uint16_t BaseInt;
        uint16_t BaseMnd;
        uint16_t BaseChr;
        int16_t AddStr;
        int16_t AddDex;
        int16_t AddVit;
        int16_t AddAgi;
        int16_t AddInt;
        int16_t AddMnd;
        int16_t AddChr;
        uint16_t Attack;
        uint16_t Defense;
        int16_t FireResistance;
        int16_t WindResistance;
        int16_t LightningResistance;
        int16_t LightResistance;
        int16_t IceResistance;
        int16_t EarthResistance;
        int16_t WaterResistance;
        int16_t DarkResistance;
        uint16_t Title;
        uint16_t NationRank;
        uint16_t RankPoints;
        uint16_t CurrentHomePoint;
        uint32_t Unks;
        uint8_t Nation;
        uint8_t Unk2;
        uint8_t SuLevel;
        uint8_t Unk3;
        uint8_t MaxItemLevel;
        uint8_t ItemLevelOver99;
        uint8_t MainHandItemLevel;
        uint8_t Unk5;
        uint32_t UnityId:5;
        uint32_t UnityRank:5;
        uint32_t UnityPoints:17;
        uint32_t Unk6:5;
        uint32_t pad;
        uint32_t pad2;
        uint8_t unk7;                   //see if we can clear up some of these unknowns
        uint8_t MasterLevel;
        uint8_t MasterBreaker;
        uint32_t CurrentExemplarPoints;
        uint32_t NextLevelExemplarPoints;
    };

    struct RecvSetUpdate                //Incoming 0x063, leaving dealing with variation up to addons for now
    {
        uint32_t Header;
        uint16_t Type;
        uint8_t Data[150];
    };
]]

local Packets = {

}

--probably a better way to get the base type for the reflection lib to work
Packets.strDefs = {
    incoming = {
        [0x0E] = {type=ffi.typeof("struct RecvCharNpc"), name="RecvCharNpc"},
        [0x28] = {type=ffi.typeof("struct RecvBattleCalc2"), name="RecvBattleCalc2"},
        [0x29] = {type=ffi.typeof("struct RecvBattleMessage"), name="RecvBattleMessage"},
        [0X2A] = {type=ffi.typeof("struct RecvMessageTalkNumWork"), name="RecvMessageTalkNumWork"},
        [0x2D] = {type=ffi.typeof("struct RecvBattleMessage2"), name="RecvBattleMessage2"},
        [0x32] = {type=ffi.typeof("struct RecvEventCalc"), name="RecvEventCalc"},
        [0x34] = {type=ffi.typeof("struct RecvEventCalcNum"), name="RecvEventCalcNum"},
        [0x36] = {type=ffi.typeof("struct RecvMessageTalkNum"), name="RecvMessageTalkNum"},
        [0x61] = {type=ffi.typeof("struct RecvCliStatus"), name="RecvCliStatus"},
        [0x63] = {type=ffi.typeof("struct RecvSetUpdate"), name="RecvSetUpdate"},
    },
    outgoing = {
        [0x15] = {type=ffi.typeof("struct SendCharPos"), name="SendCharPos"},
        [0x1A] = {type=ffi.typeof("struct ActionPacket"), name="ActionPacket"},
        [0x51] = {type=ffi.typeof("struct EquipSet"), name="EquipSet"},
        [0x5B] = {type=ffi.typeof("struct SendPendingTag"), name="SendPendingTag"},
        [0x5C] = {type=ffi.typeof("struct SendPendingXzyTag"), name="SendPendingXzyTag"},
    },
}

Packets.defs = {
    incoming = { 
        [0x0E] = ffi.typeof("struct RecvCharNpc*"),
        [0x28] = ffi.typeof("struct RecvBattleCalc2*"),
        [0x29] = ffi.typeof("struct RecvBattleMessage*"),
        [0X2A] = ffi.typeof("struct RecvMessageTalkNumWork*"),
        [0x2D] = ffi.typeof("struct RecvBattleMessage2*"),
        [0x32] = ffi.typeof("struct RecvEventCalc*"),
        [0x34] = ffi.typeof("struct RecvEventCalcNum*"),
        [0x36] = ffi.typeof("struct RecvMessageTalkNum*"),
        [0x61] = ffi.typeof("struct RecvCliStatus*"),
        [0x63] = ffi.typeof("struct RecvSetUpdate*"),
    },
    outgoing = {
        [0x15] = ffi.typeof("struct SendCharPos*"),
        [0x1A] = ffi.typeof("struct ActionPacket*"),
        [0x51] = ffi.typeof("struct EquipSet*"),
        [0x5B] = ffi.typeof("struct SendPendingTag*"),
        [0x5C] = ffi.typeof("struct SendPendingXzyTag*"),
    },
}

local MetaTable = {
    __index = Packets,
    __class = "Packets",
    __metatable = "Locked metatable: Packets",
}

local function ToBits(num) --todo: this has a bug with floats, need to fix
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

function Packets:RequestBuffer(dir, id)
    if(dir and id and self.strDefs[dir] and self.strDefs[dir][id])then
        local new = ffi.new(self.strDefs[dir][id].type)
        local pNew = ffi.cast(self.defs[dir][id], new)
        ffi.gc(pNew, ffi.free)
        --pNew["Header"] = id todo: add header here
        return pNew
    end
end

function Packets:QueueOutgoing(id, data)
    if(id and data and self.strDefs['outgoing'][id])then
        local size = ffi.sizeof(self.strDefs['outgoing'][id].type)
        local packetManager = GameManager:GetPacketManager()
        if(packetManager)then
            return packetManager:QueueOutgoing(id, size, tonumber(ffi.cast("uintptr_t", data))) --TODO: super hacky way to integrate this existing ffi stuff into sol, works but there's probably a better way
        end
    end
end

function Packets:Unpack(dir, id, data)
    if(dir and id and data and self.defs[dir] and self.defs[dir][id])then
        local cBuff = ffi.new("uint8_t[?]", #data, data)
        ffi.gc(cBuff, ffi.free)
        local pCBuff = cBuff and ffi.cast("uint8_t*", cBuff)
        ffi.gc(pCBuff, ffi.free)
        local asPacket = ffi.cast(self.defs[dir][id], pCBuff)
        ffi.gc(asPacket, ffi.free)
        return asPacket
    end
end


--0x028 stuff
--copilot wrote the bit functions for me <3 might be a little jank 
local function unpackBits(data, offset, length)
    local byteOffset = math.floor(offset / 8)
    local bitOffset = offset % 8
    local byteLength = math.ceil((offset + length) / 8) - byteOffset
    local bitLength = length + bitOffset
    local value = 0
    for i = 0, byteLength - 1 do
        value = bit.lshift(value, 8)
        value = bit.bor(value, data[byteOffset + i])
    end
    value = bit.rshift(value, bitOffset)
    value = bit.band(value, bit.lshift(1, bitLength) - 1)
    return value
end

local function unpackBitsBE(data, offset, length)
    local byteOffset = math.floor(offset / 8)
    local bitOffset = offset % 8
    local byteLength = math.ceil((offset + length) / 8) - byteOffset
    local bitLength = length + bitOffset
    local value = 0
    for i = 0, byteLength - 1 do
        value = bit.lshift(value, 8)
        value = bit.bor(value, data[byteOffset + byteLength - i - 1])
    end
    value = bit.rshift(value, bitOffset)
    value = bit.band(value, bit.lshift(1, bitLength) - 1)
    return value
end

local function unpackBitsBetweenBE(data, firstBit, lastBit)
    local offset = firstBit
    local length = lastBit - firstBit + 1
    return unpackBitsBE(data, offset, length)
end

local function unpackBitsBetween(data, firstBit, lastBit)
    local offset = firstBit
    local length = lastBit - firstBit + 1
    return unpackBits(data, offset, length)
end

--incomplete but this packet is a pita, might be worth seeing if we can just call CXiSchStatus::Unpack() and pass that back to lua
function Packets:UnpackActionPacket(cPacket)
    if(not cPacket)then return nil end

    local packet = {}
    packet["Header"] = cPacket["Header"]
    packet["Length"] = cPacket["Length"]
    packet["ActorId"] = cPacket["ActorId"]

    --start packed data
    packet["TargetCount"] = unpackBits(cPacket["PackedData"], 0, 8)
    packet["Category"] = unpackBits(cPacket["PackedData"], 10, 2)
    packet["Param"] = unpackBitsBE(cPacket["PackedData"], 14, 16)
    packet["Param2"] = unpackBitsBE(cPacket["PackedData"], 30, 16)
    packet["Recast"] = unpackBitsBE(cPacket["PackedData"], 46, 32)

    --only handling part of first action for now, debating how to move forward with this packet before i work out all of it
    packet["Actions"] = {}
    packet["Actions"][1] = {
        ["TargetId"] = unpackBitsBetweenBE(cPacket["PackedData"], 78, 102),
        ["TargetCount"] = unpackBitsBetweenBE(cPacket["PackedData"], 110, 111),
        ["Animation"] = unpackBitsBetweenBE(cPacket["PackedData"], 118, 129) / 2,
        ["Param"] = unpackBitsBetweenBE(cPacket["PackedData"], 140 , 153) / 2,
    }

    return packet
end

setmetatable(Packets, MetaTable)
return Packets