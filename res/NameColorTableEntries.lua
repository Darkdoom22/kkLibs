--  if (param_1->NameColorTableIdx < 0x17) {
--     param_1->XiActor->NameColor = (&gNameColorTable)[param_1->NameColorTableIdx];
--     return;
--  }
--todo figure out the rest of these sometime
return {
    ["Players"] = 0,
    ["PartyMembers"] = 1,
    ["Npc"] = 4,
    ["Unclaimed"] = 5,
    ["Claimed"] = 6,
    ["Gm1"] = 13,
    ["Gm2"] = 14,
    ["Gm3"] = 15,
    ["Sgm"] = 16,
} --0x17/23 total