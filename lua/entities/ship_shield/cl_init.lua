include("shared.lua");
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
language.Add("ship_shield",SGLanguage.GetMessage("ship_shield"));
end
if (StarGate==nil or StarGate.Trace==nil) then return end
-- Register shield SENT to the trace class (AGP 2026-11-08: as "ship_shield", like the server; registered as "shield"
-- it replaced the bubble's client rule and was never traced itself, so beams were drawn through a raised ship shield)
StarGate.Trace:Add("ship_shield",
	function(e,values,trace,in_box)
		local depleted = e:GetNetworkedBool("depleted",false);
		local containment = e:GetNWBool("containment",false);
		if(not depleted) then
			if((containment and in_box) or (not containment and not in_box)) then
				return true;
			end
		end
	end
);
function ENT:Draw() end -- Do not draw the shield
-- AGP 2026-11-12: admin setting "ship shields always visible" (agp_ship_shield_visible): a raised shield without its
-- bubble effect (the setting was switched on later, the effect ran out) gets it back
function ENT:Think()
	if (GetGlobalBool("AGPShipShieldVisible", false) and not IsValid(self.ShieldBubble) and not self:GetNWBool("depleted", false) and (self.AGPBubbleAt or 0) < CurTime()) then
		self.AGPBubbleAt = CurTime() + 1;
		local fx = EffectData();
		fx:SetOrigin(self:GetPos());
		fx:SetEntity(self);
		fx:SetMagnitude(0);
		util.Effect("ship_shield_engage", fx, true, true);
	end
end
--################# Retrieves the shield color @aVoN
function ENT:GetShieldColor()
	local v = self.Entity:GetNWVector("shield_color",Vector(1,1,1));
	return Color(v.x,v.y,v.z);
end


