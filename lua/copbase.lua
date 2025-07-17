-- swap weapons for single unit when it spawns in. this allows for randomization for every unit individualy.
-- note: g36 deals 375 damage on light and heavy zeal units. i tried, it sucks outside of dodge builds. dont do it again.
Hooks:PreHook(CopBase, "post_init", "DS_BW_CopBase_post_init", function(self)
	local weapon_mapping = {}
	if Network:is_server() and DS_BW and DS_BW.DS_difficultycheck then
		weapon_mapping = {
			
			------ AMERICA ------
			-- SWATS
			[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy"):key()] = {"m4","ak47_ass"}, 
			[("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat"):key()] = {"r870","m249","m4"},
			-- MEDIC
			[("units/payday2/characters/ene_medic_m4/ene_medic_m4"):key()] = {"g36"},
			[("units/payday2/characters/ene_medic_r870/ene_medic_r870"):key()] = {"benelli"},
			-- DOZERS
			[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer/ene_zeal_bulldozer"):key()] = {"m249","mini"},
			[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_2/ene_zeal_bulldozer_2"):key()] = {"mini"},
			[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_3/ene_zeal_bulldozer_3"):key()] = {"m249","r870"},
			[("units/pd2_dlc_drm/characters/ene_bulldozer_minigun/ene_bulldozer_minigun"):key()] = {"sko12_conc","mini"},
			[("units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic"):key()] = {"m249","sko12_conc"},
			
			
			------ RUSSIA ------
			-- SWATS
			-- heavy
			[("units/pd2_dlc_mad/characters/ene_akan_fbi_heavy_g36/ene_akan_fbi_heavy_g36"):key()] = {"mini","g36"},
			[("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass"):key()] = {"ak47_ass"},
			-- light
			[("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg"):key()] = {"r870","ak47_ass"},
			-- MEDIC
			[("units/pd2_dlc_mad/characters/ene_akan_medic_ak47_ass/ene_akan_medic_ak47_ass"):key()] = {"g36"},
			[("units/pd2_dlc_mad/characters/ene_akan_medic_r870/ene_akan_medic_r870"):key()] = {"benelli"},
			-- DOZERS
			[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_saiga/ene_akan_fbi_tank_saiga"):key()] = {"rpk_lmg","mini"},
			[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_r870/ene_akan_fbi_tank_r870"):key()] = {"mini"},
			[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_rpk_lmg/ene_akan_fbi_tank_rpk_lmg"):key()] = {"r870","rpk_lmg"},
			[("units/pd2_dlc_drm/characters/ene_bulldozer_minigun_classic/ene_bulldozer_minigun_classic"):key()] = {"sko12_conc","mini"},
			
			
			------ ZOMBIE ------
			-- SWATS
			[("units/pd2_dlc_hvh/characters/ene_swat_heavy_hvh_1/ene_swat_heavy_hvh_1"):key()] = {"mini","svdsil_snp"},
			[("units/pd2_dlc_hvh/characters/ene_swat_hvh_1/ene_swat_hvh_1"):key()] = {"g36","mini"},
			-- MEDIC
			[("units/pd2_dlc_hvh/characters/ene_medic_hvh_m4/ene_medic_hvh_m4"):key()] = {"g36"},
			[("units/pd2_dlc_hvh/characters/ene_medic_hvh_r870/ene_medic_hvh_r870"):key()] = {"benelli"},
			-- DOZERS
			[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_1/ene_bulldozer_hvh_1"):key()] = {"m249","mini"},
			[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_2/ene_bulldozer_hvh_2"):key()] = {"mini"},
			[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_3/ene_bulldozer_hvh_3"):key()] = {"r870","m249"},
			
			
			------ MURKYWATER ------
			-- SWATS
			[("units/pd2_dlc_bph/characters/ene_murkywater_heavy/ene_murkywater_heavy"):key()] = {"m4","ak47_ass"},
			[("units/pd2_dlc_bph/characters/ene_murkywater_light/ene_murkywater_light"):key()] = {"m249","r870","m4"},
			-- MEDIC
			[("units/pd2_dlc_bph/characters/ene_murkywater_medic/ene_murkywater_medic"):key()] = {"g36"},
			[("units/pd2_dlc_bph/characters/ene_murkywater_medic_r870/ene_murkywater_medic_r870"):key()] = {"benelli"},
			-- DOZERS
			[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_2/ene_murkywater_bulldozer_2"):key()] = {"m249","mini"},
			[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_3/ene_murkywater_bulldozer_3"):key()] = {"mini"},
			[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_4/ene_murkywater_bulldozer_4"):key()] = {"r870","m249"},
			[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_1/ene_murkywater_bulldozer_1"):key()] = {"sko12_conc","mini"},
			[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_medic/ene_murkywater_bulldozer_medic"):key()] = {"m249","sko12_conc"},
			
			
			------ FEDERALES ------
			-- SWATS
			[("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale/ene_swat_heavy_policia_federale"):key()] = {"m4","ak47_ass"},
			[("units/pd2_dlc_bex/characters/ene_swat_policia_federale/ene_swat_policia_federale"):key()] = {"r870","ak47_ass","rpk_lmg"},
			-- MEDIC
			[("units/pd2_dlc_bex/characters/ene_swat_medic_policia_federale/ene_swat_medic_policia_federale"):key()] = {"g36"},
			[("units/pd2_dlc_bex/characters/ene_swat_medic_policia_federale_r870/ene_swat_medic_policia_federale_r870"):key()] = {"benelli"},
			-- DOZERS
			[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_saiga/ene_swat_dozer_policia_federale_saiga"):key()] = {"rpk_lmg","mini"},
			[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_r870/ene_swat_dozer_policia_federale_r870"):key()] = {"mini"},
			[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_m249/ene_swat_dozer_policia_federale_m249"):key()] = {"r870","rpk_lmg"},
			[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_minigun/ene_swat_dozer_policia_federale_minigun"):key()] = {"sko12_conc","mini"},
			[("units/pd2_dlc_bex/characters/ene_swat_dozer_medic_policia_federale/ene_swat_dozer_medic_policia_federale"):key()] = {"rpk_lmg","sko12_conc"},
			
			[("units/pd2_dlc_help/characters/ene_zeal_bulldozer_halloween/ene_zeal_bulldozer_halloween"):key()] = {"mini"}
		}
	end
	
	local weapon_swap = weapon_mapping[self._unit:name():key()]
	if weapon_swap then
		self._default_weapon_id = type(weapon_swap) == "table" and table.random(weapon_swap) or weapon_swap
	end
end)