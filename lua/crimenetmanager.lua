if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

-- highlight lobby host's name using dsbw default color if name is set to dsbw's lobby name
local DS_BW_orig_criment_job_gui = CrimeNetGui._create_job_gui
function CrimeNetGui:_create_job_gui(data, type, fixed_x, fixed_y, fixed_location)
	local result = DS_BW_orig_criment_job_gui(self, data, type, fixed_x, fixed_y, fixed_location)
	
	if result.side_panel:child("host_name"):text() == "DS, but Worse" then
		result.side_panel:child("host_name"):set_color(DS_BW.color)
	end
	
	return result
	
end