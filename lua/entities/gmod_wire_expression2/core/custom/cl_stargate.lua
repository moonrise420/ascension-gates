if (E2Helper == nil) then return end

if EGP and EGP.ValidFonts then
    local insertid

    for k, v in pairs(EGP.ValidFonts) do
        if v:StartWith("WireEGP_") then
            insertid = k
            break
        end
    end

    -- insert to table with correct order client-side
    if insertid then
        table.insert(EGP.ValidFonts, insertid, "AGP Glyphs SG1")
        table.insert(EGP.ValidFonts, insertid + 1, "AGP Glyphs Concept") -- AGP: Earth's point of origin at '#' (CAP's concept font; AGP Glyphs SG1 has only the Abydos one)
        table.insert(EGP.ValidFonts, insertid + 2, "AGP Glyphs Universe")
        table.insert(EGP.ValidFonts, insertid + 3, "AGP Glyphs Atlantis")
        table.insert(EGP.ValidFonts, insertid + 4, "AGP Ancient")
        table.insert(EGP.ValidFonts, insertid + 5, "AGP Segment")
    end
end

E2Helper.Descriptions["stargateActive"] = "Returns 1 if linked stargate is active."
E2Helper.Descriptions["stargateAddress"] = "Returns the linked stargates address."
E2Helper.Descriptions["stargateAddressList"] = "Returns a table of all addresses the linked gate can see."
E2Helper.Descriptions["stargateAsgardTeleport"] = "Teleport things using Asgard Teleport.\nSyntax: from, to, all (if all = 0 - only players).\nExample: stargateAsgardTeleport(vec(0,0,0),vec(10,10,10),0)"
E2Helper.Descriptions["stargateAsuranBeam"] = "Return 1 if linked stargate has asuran gate weapon active."
E2Helper.Descriptions["stargateAtlantisTPAddressList"] = "Returns a table of all addresses the linked Atlantis Transporter can see."
E2Helper.Descriptions["stargateAtlantisTPGetGroup"] = "Returns the group of the linked Atlantis Transporter."
E2Helper.Descriptions["stargateAtlantisTPGetLocal"] = "Returns 1 if linked Atlantis Transporter is local."
E2Helper.Descriptions["stargateAtlantisTPGetName"] = "Returns the name of the linked Atlantis Transporter."
E2Helper.Descriptions["stargateAtlantisTPGetPrivate"] = "Returns 1 if linked Atlantis Transporter is private."
E2Helper.Descriptions["stargateAtlantisTPSetGroup"] = "Sets the group of the linked Atlantis Transporter."
E2Helper.Descriptions["stargateAtlantisTPSetLocal"] = "Sets the Local state of the linked Atlantis Transporter."
E2Helper.Descriptions["stargateAtlantisTPSetName"] = "Sets the name of the linked Atlantis Transporter."
E2Helper.Descriptions["stargateAtlantisTPSetPrivate"] = "Sets the Private state of the linked Atlantis Transporter."
E2Helper.Descriptions["stargateAtlantisTPTeleport"] = "Activates the linked Atlantis Transporter to teleport to the specified Atlantis Transporter"
E2Helper.Descriptions["stargateBlocked"] = "Returns 1 if the linked stargate is blocked."
E2Helper.Descriptions["stargateClose"] = "Closes linked stargate or aborts dialling."
E2Helper.Descriptions["stargateDHDPressButton"] = "Press button on DHD (not stargate!)."
E2Helper.Descriptions["stargateDial"] = "Dial gate.\nSyntax: address, mode.\nModes: 0 - slow, 1 - fast, 2 - nox."
E2Helper.Descriptions["stargateGalaxy"] = "Returns 1 if the linked stargate is a Galaxy type."
E2Helper.Descriptions["stargateGetDistanceFromAddress"] = "Returns the distance of the gate with the given address."
E2Helper.Descriptions["stargateGetEnergyFromAddress"] = "Returns how much power it will take to dial the given address."
E2Helper.Descriptions["stargateGetRingAngle"] = "Returns the number angle of the linked stargate."
E2Helper.Descriptions["stargateGroup"] = "Returns the group the linked stargate is in."
E2Helper.Descriptions["stargateInbound"] = "Returns 1 if the linked gate has an incoming wormhole."
E2Helper.Descriptions["stargateIrisActive"] = "Returns 1 if the linked stargates iris is active."
E2Helper.Descriptions["stargateIrisToggle"] = "Toggles the linked iris."
E2Helper.Descriptions["stargateLocal"] = "Returns 1 if the linked stargate is local."
E2Helper.Descriptions["stargateName"] = "Returns the name of the linked stargate."
E2Helper.Descriptions["stargateOpen"] = "Returns 1 if the linked stargate is open."
E2Helper.Descriptions["stargateOverload"] = "Return 1 if stargate has overload by overloader\nReturn 2 if gate will explode in 30 seconds."
E2Helper.Descriptions["stargateOverloadPerc"] = "Return stargate overload percent.\nGate will explode in 30 seconds after get 100 percent."
E2Helper.Descriptions["stargatePrivate"] = "Returns 1 if the linked stargate is private."
E2Helper.Descriptions["stargateRandomAddress"] = "Generate new random address and/or name.\nModes:\n0 - Generate new address and name.\n1 - Generate only new address.\n2 - Generate only new name."
E2Helper.Descriptions["stargateRingAddress"] = "Returns the address of the linked ring platform."
E2Helper.Descriptions["stargateRingDial"] = "Dials the linked ring platform to the given address."
E2Helper.Descriptions["stargateRingDialClosest"] = "Dials the linked ring platform to the closest ring platform."
E2Helper.Descriptions["stargateRingSetAddress"] = "Sets the address of the linked ring platform."
E2Helper.Descriptions["stargateSetAddress"] = "Sets the address of the linked stargate."
E2Helper.Descriptions["stargateSetBlock"] = "Sets the blocked state of the linked stargate."
E2Helper.Descriptions["stargateSetGalaxy"] = "Sets the linked stargate to the Galaxy system."
E2Helper.Descriptions["stargateSetGroup"] = "Sets the group of the linked stargate."
E2Helper.Descriptions["stargateSetLocal"] = "Sets the local state of the linked stargate."
E2Helper.Descriptions["stargateSetName"] = "Sets the name of the linked stargate."
E2Helper.Descriptions["stargateSetPrivate"] = "Sets the private state of the linked stargate."
E2Helper.Descriptions["stargateSystemType"] = "Return stargate system.\n1 - Group System, 0 - Galaxy System."
E2Helper.Descriptions["stargateTransferEnergy"] = "Transfer energy between two connected stargates.\nUse negative value to retrieve energy.\nReturns transferred amount of energy if successful."
E2Helper.Descriptions["stargateTransferResource"] = "Transfer resource between two connected stargates.\nUse negative value to retrieve resource.\nCan transfer only to dialled gate (not from).\nReturns transferred amount of resource if successful."
E2Helper.Descriptions["stargateTransmit"] = "Transmits a message through the stargate"
E2Helper.Descriptions["stargateUnstable"] = "Returns 1 if the linked stargate is unstable"
-- our own: generic wire port access and the player-aware jamming check
E2Helper.Descriptions["stargateGetWire"] = "Returns the number value of a wire output of the linked CAP entity (-1 if not found).\nExample: SG:stargateGetWire(\"Active\")"
E2Helper.Descriptions["stargateGetWireString"] = "Returns the string value of a wire output of the linked CAP entity."
E2Helper.Descriptions["stargateGetWireVector"] = "Returns the vector value of a wire output of the linked CAP entity."
E2Helper.Descriptions["stargateGetWireEntity"] = "Returns the entity value of a wire output of the linked CAP entity."
E2Helper.Descriptions["stargateGetWireInput"] = "Returns the number value of a wire input of the linked CAP entity (-1 if not set)."
E2Helper.Descriptions["stargateGetWireStringInput"] = "Returns the string value of a wire input of the linked CAP entity."
E2Helper.Descriptions["stargateGetWireVectorInput"] = "Returns the vector value of a wire input of the linked CAP entity."
E2Helper.Descriptions["stargateGetWireEntityInput"] = "Returns the entity value of a wire input of the linked CAP entity."
E2Helper.Descriptions["stargateSetWire"] = "Sets a wire input of the linked CAP entity (number, string, vector or entity), as if it was wired.\nExample: SG:stargateSetWire(\"Dial String\",\"ABCDEF#\")"
E2Helper.Descriptions["stargateIsInJamming"] = "Returns 1 if the position is inside an active jamming device.\nWith a player as second argument, jammers with immunity owned by that player are ignored (-1 if the player is not valid)."
