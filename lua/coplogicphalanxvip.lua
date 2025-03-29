-- Assault actually ends if Winters dies. Death added in chartweak
-- hopefuly completely fixes it
local ds_bw_orig_phalanxVip_death_clbk = CopLogicPhalanxVip.death_clbk
function CopLogicPhalanxVip.death_clbk(data, damage_info)
	managers.groupai:state():unregister_phalanx_vip()
	managers.groupai:state():set_assault_endless(false)
	
	return ds_bw_orig_phalanxVip_death_clbk(self, data, damage_info)
end