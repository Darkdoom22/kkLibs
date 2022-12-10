--[[
    Written By: Uwu/Darkdoom 12/8/2022
    Description: Convert packets into human friendly formats and handle packet manipulation
    Notes: This is a work in progress, lot to do
]]

package.loaded["ffi"] = nil
local ffi = require("ffi")
local reflect = require("libs.reflect")

ffi.cdef[[
    void free(void* ptr);
    void* malloc(size_t size);
    struct pktHeader
    {
        uint16_t id : 9;
        uint16_t len : 7;
        uint16_t seq : 16;
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
]]

local Packets = {

}

--probably a better way to get the base type for the reflection lib to work
Packets.strDefs = {
    incoming = {
        [0x0E] = {type=ffi.typeof("struct RecvCharNpc"), name="RecvCharNpc"},
        [0x29] = {type=ffi.typeof("struct RecvBattleMessage"), name="RecvBattleMessage"},
        [0X2A] = {type=ffi.typeof("struct RecvMessageTalkNumWork"), name="RecvMessageTalkNumWork"},
        [0x32] = {type=ffi.typeof("struct RecvEventCalc"), name="RecvEventCalc"},
        [0x34] = {type=ffi.typeof("struct RecvEventCalcNum"), name="RecvEventCalcNum"},
        [0x36] = {type=ffi.typeof("struct RecvMessageTalkNum"), name="RecvMessageTalkNum"},
    },
    outgoing = {
        [0x15] = {type=ffi.typeof("struct SendCharPos"), name="SendCharPos"},
        [0x1A] = {type=ffi.typeof("struct ActionPacket"), name="ActionPacket"},
        [0x5B] = {type=ffi.typeof("struct SendPendingTag"), name="SendPendingTag"},
        [0x5C] = {type=ffi.typeof("struct SendPendingXzyTag"), name="SendPendingXzyTag"},
    },
}

Packets.defs = {
    incoming = { 
        [0x0E] = ffi.typeof("struct RecvCharNpc*"),
        [0x29] = ffi.typeof("struct RecvBattleMessage*"),
        [0X2A] = ffi.typeof("struct RecvMessageTalkNumWork*"),
        [0x32] = ffi.typeof("struct RecvEventCalc*"),
        [0x34] = ffi.typeof("struct RecvEventCalcNum*"),
        [0x36] = ffi.typeof("struct RecvMessageTalkNum*"),
    },
    outgoing = {
        [0x15] = ffi.typeof("struct SendCharPos*"),
        [0x1A] = ffi.typeof("struct ActionPacket*"),
        [0x5B] = ffi.typeof("struct SendPendingTag*"),
        [0x5C] = ffi.typeof("struct SendPendingXzyTag*"),
    },
}

local MetaTable = {
    __index = Packets,
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
        return pNew
    end
end

function Packets:QueueOutgoing(id, data)
    if(id and data and self.strDefs['outgoing'][id])then
        local size = ffi.sizeof(self.strDefs['outgoing'][id].type)
        local packetManager = GameManager:GetPacketManager()
        if(packetManager)then
            packetManager:QueueOutgoing(id, size, data)
        end
    end
end

function Packets:Unpack(dir, id, data)
    if(dir and id and data and self.defs[dir] and self.defs[dir][id])then
        local cBuff = ffi.new("uint8_t[?]", #data, data)
        local pCBuff = cBuff and ffi.cast("uint8_t*", cBuff)
        return pCBuff and ffi.cast(self.defs[dir][id], pCBuff)
    end
end

return Packets