-- swap weapons for single unit when it spawns in. this allows for randomization for every unit individualy.
Hooks:PreHook(CopBase, "post_init", "DS_BW_CopBase_post_init", function(self)
	local weapon_mapping = {}
	if Network:is_server() and DS_BW and DS_BW.DS_difficultycheck then
		weapon_mapping = {
			
			------ AMERICA ------
			-- SWATS
			[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy"):key()] = {
				[0] = {
					r870 = 0.15,
					s552 = 0.7,
					ak47_ass = 0.85,
					m4 = 1,
				},
				[2] = {
					r870 = 0.2,
					s552 = 0.6,
					ak47_ass = 0.8,
					m4 = 1,
				},
				[3] = {
					r870 = 0.2,
					ak47_ass = 0.6,
					m4 = 1,
				},
				[4] = {
					m249 = 0.35,
					g36 = 1,
				},
				[5] = {
					m249 = 0.15,
					g36 = 1,
				},
			},
			[("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat"):key()] = {
				[0] = {
					saiga = 0.1,
					s552 = 0.2,
					m249 = 0.5,
					mp5_tactical = 1,
				},
				[2] = {
					saiga = 0.15,
					s552 = 0.35,
					m249 = 0.7,
					mp5_tactical = 1,
				},
				[3] = {
					saiga = 0.2,
					m249 = 0.6,
					mp5_tactical = 1,
				},
				[4] = {
					ak47_ass = 0.4,
					m249 = 1,
				},
				[5] = {
					ak47_ass = 0.6,
					m249 = 1,
				}
			},
			-- MEDIC
			[("units/payday2/characters/ene_medic_m4/ene_medic_m4"):key()] = {
				[0] = {
					g36 = 1,
				}
			},
			[("units/payday2/characters/ene_medic_r870/ene_medic_r870"):key()] = {
				[0] = {
					benelli = 1,
				}
			},
			-- DOZERS
			[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer/ene_zeal_bulldozer"):key()] = {
				[0] = {
					m249 = 0.5,
					mini = 1,
				}
			},
			[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_2/ene_zeal_bulldozer_2"):key()] = {
				[0] = {
					mini = 1,
				}
			},
			[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_3/ene_zeal_bulldozer_3"):key()] = {
				[0] = {
					m249 = 0.5,
					r870 = 1,
				}
			},
			[("units/pd2_dlc_drm/characters/ene_bulldozer_minigun/ene_bulldozer_minigun"):key()] = {
				[0] = {
					sko12_conc = 0.5,
					mini = 1,
				}
			},
			[("units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic"):key()] = {
				[0] = {
					m249 = 0.5,
					sko12_conc = 1,
				}
			},
			-- "HRT" Squad
			[("units/payday2/characters/ene_fbi_1/ene_fbi_1"):key()] = {
				[0] = {
					m4 = 0.5,
					s552 = 1,
				}
			},
			[("units/payday2/characters/ene_fbi_2/ene_fbi_2"):key()] = {
				[0] = {
					m4 = 0.5,
					s552 = 1,
				}
			},
			
			
			------ RUSSIA ------
			-- SWATS
			-- heavy squad - low hp unit, that has DS damage
			[("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass"):key()] = {
				[0] = {
					r870 = 0.15,
					ak47_ass = 1,
				},
				[2] = {
					r870 = 0.2,
					ak47_ass = 1,
				},
				[3] = {
					r870 = 0.2,
					g36 = 0.2,
					ak47_ass = 1,
				},
				[4] = {
					ak47_ass = 0.6,
					g36 = 1,
				},
				[5] = {
					ak47_ass = 0.4,
					g36 = 1,
				}
			},
			-- light squad - high hp unit
			[("units/pd2_dlc_mad/characters/ene_akan_fbi_heavy_g36/ene_akan_fbi_heavy_g36"):key()] = {
				[0] = {
					mini = 0.25,
					g36 = 1,
				},
				[2] = {
					mini = 0.35,
					g36 = 1,
				},
				[3] = {
					mini = 0.5,
					g36 = 1,
				},
				[4] = {
					mini =  0.5,
					g36 = 1,
				},
				[5] = {
					mini =  0.5,
					g36 = 1,
				},
			},
			-- HRT unit
			[("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg"):key()] = {
				[0] = {
					r870 = 1,
					ak47_ass = 1,
					g36 = 1,
				}
			},
			-- MEDIC
			[("units/pd2_dlc_mad/characters/ene_akan_medic_ak47_ass/ene_akan_medic_ak47_ass"):key()] = {
				[0] = {
					g36 = 1,
				}
			},
			[("units/pd2_dlc_mad/characters/ene_akan_medic_r870/ene_akan_medic_r870"):key()] = {
				[0] = {
					benelli = 1,
				}
			},
			-- DOZERS
			[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_saiga/ene_akan_fbi_tank_saiga"):key()] = {
				[0] = {
					rpk_lmg = 0.5,
					mini = 1,
				}
			},
			[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_r870/ene_akan_fbi_tank_r870"):key()] = {
				[0] = {
					mini = 1,
				}
			},
			[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_rpk_lmg/ene_akan_fbi_tank_rpk_lmg"):key()] = {
				[0] = {
					r870 = 0.5,
					rpk_lmg = 1,
				}
			},
			[("units/pd2_dlc_drm/characters/ene_bulldozer_minigun_classic/ene_bulldozer_minigun_classic"):key()] = {
				[0] = {
					sko12_conc = 0.5,
					mini = 1,
				}
			},
			-- "HRT" Squad
			[("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg"):key()] = {
				[0] = {
					ak47_ass = 0.5,
					g36 = 1,
				}
			},
			
			
			------ ZOMBIE ------
			-- SWATS
			[("units/pd2_dlc_hvh/characters/ene_swat_heavy_hvh_1/ene_swat_heavy_hvh_1"):key()] = {
				[0] = {
					g36 = 0.33,
					mini = 0.666, -- spoopy
					svdsil_snp = 1,
				},
				[3] = {
					g36 = 0.5,
					mini = 1,
				},
				[4] = {
					g36 = 0.75,
					mini = 1,
				},
				[5] = {
					g36 = 0.75,
					mini = 1,
				}
			},
			[("units/pd2_dlc_hvh/characters/ene_swat_hvh_1/ene_swat_hvh_1"):key()] = {
				[0] = {
					g36 = 0.5,
					mini = 1,
				}
			},
			-- MEDIC
			[("units/pd2_dlc_hvh/characters/ene_medic_hvh_m4/ene_medic_hvh_m4"):key()] = {
				[0] = {
					g36 = 1,
				}
			},
			[("units/pd2_dlc_hvh/characters/ene_medic_hvh_r870/ene_medic_hvh_r870"):key()] = {
				[0] = {
					benelli = 1,
				}
			},
			-- DOZERS
			[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_1/ene_bulldozer_hvh_1"):key()] = {
				[0] = {
					m249 = 0.5,
					mini = 1,
				}
			},
			[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_2/ene_bulldozer_hvh_2"):key()] = {
				[0] = {
					mini = 1,
				}
			},
			[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_3/ene_bulldozer_hvh_3"):key()] = {
				[0] = {
					r870 = 0.5,
					m249 = 1,
				}
			},
			-- "HRT" Squad
			[("units/pd2_dlc_hvh/characters/ene_fbi_hvh_1/ene_fbi_hvh_1"):key()] = {
				[0] = {
					g36 = 1,
				}
			},
			[("units/pd2_dlc_hvh/characters/ene_fbi_hvh_2/ene_fbi_hvh_2"):key()] = {
				[0] = {
					g36 = 1,
				}
			},
			
			------ MURKYWATER ------
			-- SWATS
			[("units/pd2_dlc_bph/characters/ene_murkywater_heavy/ene_murkywater_heavy"):key()] = {
				[0] = {
					r870 = 0.15,
					scar_murky = 0.7,
					m4 = 0.85,
					ak47_ass = 1,
				},
				[2] = {
					r870 = 0.2,
					scar_murky = 0.6,
					m4 = 0.8,
					ak47_ass = 1,
				},
				[3] = {
					r870 = 0.2,
					m4 = 0.6,
					ak47_ass = 1,
				},
				[4] = {
					rpk_lmg = 0.35,
					g36 = 1,
				},
				[5] = {
					rpk_lmg = 0.15,
					g36 = 1,
				},
			},
			[("units/pd2_dlc_bph/characters/ene_murkywater_light/ene_murkywater_light"):key()] = {
				[0] = {
					saiga = 0.1,
					scar_murky = 0.2,
					rpk_lmg = 0.5,
					ump = 0.75,
					akmsu_smg = 1,
				},
				[2] = {
					saiga = 0.15,
					scar_murky = 0.35,
					rpk_lmg = 0.7,
					ump = 0.85,
					akmsu_smg = 1,
				},
				[3] = {
					saiga = 0.2,
					rpk_lmg = 0.6,
					ump = 0.8,
					akmsu_smg = 1,
				},
				[4] = {
					m4 = 0.4,
					rpk_lmg = 1,
				},
				[5] = {
					m4 = 0.6,
					rpk_lmg = 1,
				}
			},
			-- MEDIC
			[("units/pd2_dlc_bph/characters/ene_murkywater_medic/ene_murkywater_medic"):key()] = {
				[0] = {
					g36 = 1,
				}
			},
			[("units/pd2_dlc_bph/characters/ene_murkywater_medic_r870/ene_murkywater_medic_r870"):key()] = {
				[0] = {
					benelli = 1,
				}
			},
			-- DOZERS
			[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_2/ene_murkywater_bulldozer_2"):key()] = {
				[0] = {
					m249 = 0.5,
					mini = 1,
				}
			},
			[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_3/ene_murkywater_bulldozer_3"):key()] = {
				[0] = {
					mini = 1,
				}
			},
			[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_4/ene_murkywater_bulldozer_4"):key()] = {
				[0] = {
					r870 = 0.5,
					m249 = 1,
				}
			},
			[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_1/ene_murkywater_bulldozer_1"):key()] = {
				[0] = {
					sko12_conc = 0.5,
					mini = 1,
				}
			},
			[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_medic/ene_murkywater_bulldozer_medic"):key()] = {
				[0] = {
					m249 = 0.5,
					sko12_conc = 1,
				}
			},
			
			
			------ FEDERALES ------
			-- SWATS
			[("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale/ene_swat_heavy_policia_federale"):key()] = {
				[0] = {
					r870 = 0.15,
					sg417 = 0.7,
					m4 = 0.85,
					ak47_ass = 1,
				},
				[2] = {
					r870 = 0.2,
					sg417 = 0.6,
					m4 = 0.8,
					ak47_ass = 1,
				},
				[3] = {
					r870 = 0.2,
					m4 = 0.6,
					ak47_ass = 1,
				},
				[4] = {
					m249 = 0.35,
					g36 = 1,
				},
				[5] = {
					m249 = 0.15,
					g36 = 1,
				}
			},
			[("units/pd2_dlc_bex/characters/ene_swat_policia_federale/ene_swat_policia_federale"):key()] = {
				[0] = {
					saiga = 0.1,
					scar_murky = 0.15,
					sg417 = 0.2,
					m249 = 0.35,
					rpk_lmg = 0.5,
					mac11 = 0.75,
					asval_smg = 1,
				},
				[2] = {
					saiga = 0.15,
					scar_murky = 0.25,
					sg417 = 0.35,
					m249 = 0.525,
					rpk_lmg = 0.7,
					mac11 = 0.85,
					asval_smg = 1,
				},
				[3] = {
					saiga = 0.2,
					m249 = 0.4,
					rpk_lmg = 0.6,
					mac11 = 0.8,
					asval_smg = 1,
				},
				[4] = {
					m4 = 0.4,
					rpk_lmg = 1,
				},
				[5] = {
					m4 = 0.6,
					rpk_lmg = 1,
				}
			},
			-- MEDIC
			[("units/pd2_dlc_bex/characters/ene_swat_medic_policia_federale/ene_swat_medic_policia_federale"):key()] = {
				[0] = {
					g36 = 1,
				}
			},
			[("units/pd2_dlc_bex/characters/ene_swat_medic_policia_federale_r870/ene_swat_medic_policia_federale_r870"):key()] = {
				[0] = {
					benelli = 1,
				}
			},
			-- DOZERS
			[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_saiga/ene_swat_dozer_policia_federale_saiga"):key()] = {
				[0] = {
					rpk_lmg = 0.5,
					mini = 1,
				}
			},
			[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_r870/ene_swat_dozer_policia_federale_r870"):key()] = {
				[0] = {
					mini = 1,
				}
			},
			[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_m249/ene_swat_dozer_policia_federale_m249"):key()] = {
				[0] = {
					r870 = 0.5,
					rpk_lmg = 1,
				}
			},
			[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_minigun/ene_swat_dozer_policia_federale_minigun"):key()] = {
				[0] = {
					sko12_conc = 0.5,
					mini = 1,
				}
			},
			[("units/pd2_dlc_bex/characters/ene_swat_dozer_medic_policia_federale/ene_swat_dozer_medic_policia_federale"):key()] = {
				[0] = {
					rpk_lmg = 0.5,
					sko12_conc = 1,
				}
			},
			-- "HRT" Squad
			[("units/pd2_dlc_bex/characters/ene_policia_01/ene_policia_01"):key()] = {
				[0] = {
					m4 = 0.5,
					scar_murky = 1,
				}
			},
			[("units/pd2_dlc_bex/characters/ene_policia_02/ene_policia_02"):key()] = {
				[0] = {
					m4 = 0.5,
					scar_murky = 1,
				}
			},
			
			[("units/pd2_dlc_help/characters/ene_zeal_bulldozer_halloween/ene_zeal_bulldozer_halloween"):key()] = {
				[0] = {
					mini = 1,
				}
			}
		}
	end
	
	local weapon_swap = weapon_mapping[self._unit:name():key()]
	if weapon_swap then
		local roll = math.random()
		local weapon_tree_level = 0
		if DS_BW._low_spawns_manager and DS_BW._low_spawns_manager.level >= 1 then
			if weapon_swap[DS_BW._low_spawns_manager.level] then
				weapon_tree_level = DS_BW._low_spawns_manager.level
			end
		end
		for wpn, chance in pairs(weapon_swap[weapon_tree_level]) do
			if roll < chance then
				self._default_weapon_id = tostring(wpn)
			end
		end
	end
end)