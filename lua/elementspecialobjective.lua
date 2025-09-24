local dsbw_orig_nav_link_delay = ElementSpecialObjective.nav_link_delay
function ElementSpecialObjective:nav_link_delay()
	if DS_BW and DS_BW.DS_difficultycheck then
		return 0.25
	else
		return dsbw_orig_nav_link_delay(self)
	end
end