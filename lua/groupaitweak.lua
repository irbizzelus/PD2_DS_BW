if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

local function string_startswith(String, Start)
	return string.sub(String,1,string.len(Start))==Start
end

-- holdout check
local level = Global.level_data and Global.level_data.level_id
if level and string_startswith(level, "skm_") then
	return
end

local access_type_walk_only = {
	walk = true
}

local access_type_all = {
	acrobatic = true,
	walk = true
}

-- units themselves
Hooks:PostHook(GroupAITweakData, "_init_unit_categories", "DS_BW_tweak_initunitcategories", function(self, difficulty_index)
	if difficulty_index == 8 then
		DS_BW.DS_difficultycheck = true
		DS_BW.update_surrender_tweak_data()

		self.unit_categories.Blue_swat = {
			unit_types = {
				america = {
					Idstring("units/payday2/characters/ene_swat_1/ene_swat_1"),
					Idstring("units/payday2/characters/ene_swat_heavy_1/ene_swat_heavy_1")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_swat_ak47_ass/ene_akan_cs_swat_ak47_ass"),
					Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_heavy_ak47_ass/ene_akan_cs_heavy_ak47_ass")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_swat_hvh_1/ene_swat_hvh_1")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_light_fbi/ene_murkywater_light_fbi"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_heavy_g36/ene_murkywater_heavy_g36")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale_g36/ene_swat_heavy_policia_federale_g36"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale/ene_swat_heavy_policia_federale")
				}
			},
			access = access_type_all
		}
		
		self.unit_categories.Green_swat = {
			unit_types = {
				america = {
					Idstring("units/payday2/characters/ene_fbi_swat_1/ene_fbi_swat_1"),
					Idstring("units/payday2/characters/ene_fbi_swat_2/ene_fbi_swat_2"),
					Idstring("units/payday2/characters/ene_fbi_heavy_1/ene_fbi_heavy_1"),
					Idstring("units/payday2/characters/ene_fbi_heavy_r870/ene_fbi_heavy_r870")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_swat_ak47_ass/ene_akan_fbi_swat_ak47_ass"),
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_swat_r870/ene_akan_fbi_swat_r870"),
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_heavy_r870/ene_akan_fbi_heavy_r870")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_fbi_swat_hvh_1/ene_fbi_swat_hvh_1"),
					Idstring("units/pd2_dlc_hvh/characters/ene_fbi_swat_hvh_2/ene_fbi_swat_hvh_2"),
					Idstring("units/pd2_dlc_hvh/characters/ene_fbi_heavy_hvh_1/ene_fbi_heavy_hvh_1"),
					Idstring("units/pd2_dlc_hvh/characters/ene_fbi_heavy_hvh_r870/ene_fbi_heavy_hvh_r870")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_light_fbi/ene_murkywater_light_fbi"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_heavy_shotgun/ene_murkywater_heavy_shotgun"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_light_fbi_r870/ene_murkywater_light_fbi_r870"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_heavy_g36/ene_murkywater_heavy_g36")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_policia_federale_fbi/ene_swat_policia_federale_fbi"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_policia_federale_fbi_r870/ene_swat_policia_federale_fbi_r870"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale_fbi/ene_swat_heavy_policia_federale_fbi"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale_fbi_r870/ene_swat_heavy_policia_federale_fbi_r870")
				}
			},
			access = access_type_all
		}
		
		self.unit_categories.Grey_swat = {
			unit_types = {
				america = {
					Idstring("units/payday2/characters/ene_city_swat_1/ene_city_swat_1"),
					Idstring("units/payday2/characters/ene_city_swat_3/ene_city_swat_3"),
					Idstring("units/payday2/characters/ene_city_swat_2/ene_city_swat_2"),
					Idstring("units/payday2/characters/ene_city_swat_r870/ene_city_swat_r870"),
					Idstring("units/payday2/characters/ene_city_heavy_g36/ene_city_heavy_g36"),
					Idstring("units/payday2/characters/ene_city_heavy_r870/ene_city_heavy_r870")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_swat_dw_ak47_ass/ene_akan_fbi_swat_dw_ak47_ass"),
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_heavy_r870/ene_akan_fbi_heavy_r870"),
					Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_asval_smg/ene_akan_cs_cop_asval_smg"),
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_swat_dw_r870/ene_akan_fbi_swat_dw_r870")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_fbi_swat_hvh_1/ene_fbi_swat_hvh_1"),
					Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_3/ene_cop_hvh_3"),
					Idstring("units/pd2_dlc_hvh/characters/ene_fbi_swat_hvh_2/ene_fbi_swat_hvh_2"),
					Idstring("units/pd2_dlc_hvh/characters/ene_fbi_heavy_hvh_1/ene_fbi_heavy_hvh_1"),
					Idstring("units/pd2_dlc_hvh/characters/ene_fbi_heavy_hvh_r870/ene_fbi_heavy_hvh_r870")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_light_city/ene_murkywater_light_city"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_light_city_r870/ene_murkywater_light_city_r870"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_heavy_g36/ene_murkywater_heavy_g36"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_heavy_shotgun/ene_murkywater_heavy_shotgun")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_policia_federale_city/ene_swat_policia_federale_city"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_policia_federale/ene_swat_policia_federale"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_policia_federale_city_r870/ene_swat_policia_federale_city_r870"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale_fbi_g36/ene_swat_heavy_policia_federale_fbi_g36"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale_fbi_r870/ene_swat_heavy_policia_federale_fbi_r870")
				}
			},
			access = access_type_all
		}
		
		-- Blue shields
		-- self.unit_categories.CS_shield
		
		self.unit_categories.Green_shield = {
			special_type = "shield",
			unit_types = {
				america = {
					Idstring("units/payday2/characters/ene_shield_1/ene_shield_1")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_shield_sr2_smg/ene_akan_fbi_shield_sr2_smg")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_shield_hvh_1/ene_shield_hvh_1")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_shield/ene_murkywater_shield")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_shield_policia_federale_mp9/ene_swat_shield_policia_federale_mp9")
				}
			},
			access = access_type_walk_only
		}
		
		self.unit_categories.Grey_shield = {
			special_type = "shield",
			unit_types = {
				america = {
					Idstring("units/payday2/characters/ene_city_shield/ene_city_shield")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_shield_dw_sr2_smg/ene_akan_fbi_shield_dw_sr2_smg")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_shield_hvh_1/ene_shield_hvh_1")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_shield/ene_murkywater_shield")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_shield_policia_federale_mp9/ene_swat_shield_policia_federale_mp9")
				}
			},
			access = access_type_walk_only
		}
		
		self.unit_categories.Default_tazer = {
			special_type = "taser",
			unit_types = {
				america = {
					Idstring("units/payday2/characters/ene_tazer_1/ene_tazer_1")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_tazer_ak47_ass/ene_akan_cs_tazer_ak47_ass")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_tazer_hvh_1/ene_tazer_hvh_1")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_tazer/ene_murkywater_tazer")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_tazer_policia_federale/ene_swat_tazer_policia_federale")
				}
			},
			access = access_type_all
		}
		
		self.unit_categories.Default_spooc = {
			special_type = "spooc",
			unit_types = {
				america = {
					Idstring("units/payday2/characters/ene_spook_1/ene_spook_1")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_spooc_asval_smg/ene_akan_fbi_spooc_asval_smg")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_spook_hvh_1/ene_spook_hvh_1")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_cloaker/ene_murkywater_cloaker")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_cloaker_policia_federale/ene_swat_cloaker_policia_federale")
				}
			},
			access = access_type_all
		}

		self.unit_categories.Blue_green_tank = {
			special_type = "tank",
			unit_types = {
				america = {
					Idstring("units/payday2/characters/ene_bulldozer_1/ene_bulldozer_1"),
					Idstring("units/payday2/characters/ene_bulldozer_2/ene_bulldozer_2")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_r870/ene_akan_fbi_tank_r870"),
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_saiga/ene_akan_fbi_tank_saiga")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_1/ene_bulldozer_hvh_1"),
					Idstring("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_2/ene_bulldozer_hvh_2")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_2/ene_murkywater_bulldozer_2"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_4/ene_murkywater_bulldozer_4")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_r870/ene_swat_dozer_policia_federale_r870"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_saiga/ene_swat_dozer_policia_federale_saiga")
				}
			},
			access = access_type_all
		}
		
		self.unit_categories.Grey_tank = {
			special_type = "tank",
			unit_types = {
				america = {
					Idstring("units/pd2_dlc_drm/characters/ene_bulldozer_minigun_classic/ene_bulldozer_minigun_classic"),
					Idstring("units/payday2/characters/ene_bulldozer_3/ene_bulldozer_3")
				},
				russia = {
					Idstring("units/pd2_dlc_drm/characters/ene_bulldozer_minigun_classic/ene_bulldozer_minigun_classic"),
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_rpk_lmg/ene_akan_fbi_tank_rpk_lmg")
				},
				zombie = {
					Idstring("units/pd2_dlc_drm/characters/ene_bulldozer_minigun_classic/ene_bulldozer_minigun_classic"),
					Idstring("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_3/ene_bulldozer_hvh_3")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_1/ene_murkywater_bulldozer_1"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_3/ene_murkywater_bulldozer_3")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_minigun/ene_swat_dozer_policia_federale_minigun"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_m249/ene_swat_dozer_policia_federale_m249")
				}
			},
			access = access_type_all
		}
		
		-- HRT/FBI/cop units. will be spawned rarely to allow for easy to get jokers sometimes, since they use an easy preset
		self.unit_categories.FBI_HRT_mix = {
			unit_types = {
				america = {
					Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1"),
					Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_1/ene_fbi_hvh_1"),
					Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_2/ene_fbi_hvh_2")
				},
				murkywater = {
					Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2"),
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_policia_01/ene_policia_01"),
					Idstring("units/pd2_dlc_bex/characters/ene_policia_02/ene_policia_02")
				}
			},
			access = access_type_all
		}
		
		-- light ZEAL SWAT
		self.unit_categories.SupportCQB = {
			unit_types = {
				america = {
					Idstring("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_heavy_g36/ene_akan_fbi_heavy_g36")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_swat_hvh_1/ene_swat_hvh_1")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_light/ene_murkywater_light")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_policia_federale/ene_swat_policia_federale")
				}
			},
			access = access_type_walk_only
		}

		-- heavy ZEAL SWAT
		self.unit_categories.RifleMen = {
			unit_types = {
				america = {
					Idstring("units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_swat_heavy_hvh_1/ene_swat_heavy_hvh_1")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_heavy/ene_murkywater_heavy")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale/ene_swat_heavy_policia_federale")
				}
			},
			access = access_type_all
		}

		-- Change dozer types
		self.unit_categories.FBI_tank = {
			special_type = "tank",
			unit_types = {
				america = {
					Idstring("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer/ene_zeal_bulldozer"),
					Idstring("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_2/ene_zeal_bulldozer_2"),
					Idstring("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_3/ene_zeal_bulldozer_3"),
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_r870/ene_akan_fbi_tank_r870"),
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_saiga/ene_akan_fbi_tank_saiga"),
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_rpk_lmg/ene_akan_fbi_tank_rpk_lmg")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_1/ene_bulldozer_hvh_1"),
					Idstring("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_2/ene_bulldozer_hvh_2"),
					Idstring("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_3/ene_bulldozer_hvh_3")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_2/ene_murkywater_bulldozer_2"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_3/ene_murkywater_bulldozer_3"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_4/ene_murkywater_bulldozer_4")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_r870/ene_swat_dozer_policia_federale_r870"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_saiga/ene_swat_dozer_policia_federale_saiga"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_m249/ene_swat_dozer_policia_federale_m249")
				}
			},
			access = access_type_all
		}
		
		self.unit_categories.FBI_tank_annoying = {
			special_type = "tank",
			unit_types = {
				america = {
					Idstring("units/pd2_dlc_drm/characters/ene_bulldozer_minigun/ene_bulldozer_minigun"),
					Idstring("units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic")
				},
				russia = {
					Idstring("units/pd2_dlc_drm/characters/ene_bulldozer_minigun_classic/ene_bulldozer_minigun_classic"),
					Idstring("units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic")
				},
				zombie = {
					Idstring("units/pd2_dlc_drm/characters/ene_bulldozer_minigun_classic/ene_bulldozer_minigun_classic"),
					Idstring("units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_1/ene_murkywater_bulldozer_1"),
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_medic/ene_murkywater_bulldozer_medic")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_minigun/ene_swat_dozer_policia_federale_minigun"),
					Idstring("units/pd2_dlc_bex/characters/ene_swat_dozer_medic_policia_federale/ene_swat_dozer_medic_policia_federale")
				}
			},
			access = access_type_all
		}
		
		-- 50% chance that marshal shields may have black variants spawning along with default green. this roll hapens once, at the begining of each game. purely visual
		if math.random() <= 0.5 then
			self.unit_categories.marshal_marksman.unit_types.america = {
				Idstring("units/pd2_dlc_usm1/characters/ene_male_marshal_marksman_1/ene_male_marshal_marksman_1"),
				Idstring("units/pd2_dlc_usm1/characters/ene_male_marshal_marksman_2/ene_male_marshal_marksman_2")
			}
			self.unit_categories.marshal_shield.unit_types.america = {
				Idstring("units/pd2_dlc_usm2/characters/ene_male_marshal_shield_1/ene_male_marshal_shield_1"),
				Idstring("units/pd2_dlc_usm2/characters/ene_male_marshal_shield_2/ene_male_marshal_shield_2")
			}
		end
		
		self.special_unit_spawn_limits = {
			shield = 7,
			medic = 4,
			taser = 5,
			tank = 3,
			spooc = 4
		}
	
	else
		DS_BW.DS_difficultycheck = false
	end
end)

-- SPAWNGROUPS
Hooks:PostHook(GroupAITweakData, "_init_enemy_spawn_groups", "DS_BW_spawngroupstweak", function(self, difficulty_index)
	if difficulty_index == 8 then
		-- Change spawn groups to our own
		self.enemy_spawn_groups = {}
		
		-- Tactics
		self._tactics = {
			Phalanx_minion = {
				"smoke_grenade",
				"charge",
				"provide_coverfire",
				"provide_support",
				"shield",
				"deathguard"
			},
			Phalanx_vip = {
				"smoke_grenade",
				"charge",
				"provide_coverfire",
				"provide_support",
				"shield",
				"deathguard"
			},
			CS_cop = {
				"provide_coverfire",
				"provide_support",
				"ranged_fire"
			},
			CS_cop_stealth = {
				"flank",
				"provide_coverfire",
				"provide_support"
			},
			CS_swat_rifle = {
				"smoke_grenade",
				"charge",
				"provide_coverfire",
				"provide_support",
				"ranged_fire",
				"deathguard"
			},
			CS_swat_shotgun = {
				"smoke_grenade",
				"charge",
				"provide_coverfire",
				"provide_support",
				"shield_cover"
			},
			CS_swat_heavy = {
				"smoke_grenade",
				"charge",
				"flash_grenade",
				"provide_coverfire",
				"provide_support"
			},
			CS_shield = {
				"charge",
				"provide_coverfire",
				"provide_support",
				"shield",
				"deathguard"
			},
			CS_swat_rifle_flank = {
				"flank",
				"flash_grenade",
				"smoke_grenade",
				"charge",
				"provide_coverfire",
				"provide_support"
			},
			CS_swat_shotgun_flank = {
				"flank",
				"flash_grenade",
				"smoke_grenade",
				"charge",
				"provide_coverfire",
				"provide_support"
			},
			CS_swat_heavy_flank = {
				"flank",
				"flash_grenade",
				"smoke_grenade",
				"charge",
				"provide_coverfire",
				"provide_support",
				"shield_cover"
			},
			CS_shield_flank = {
				"flank",
				"charge",
				"flash_grenade",
				"provide_coverfire",
				"provide_support",
				"shield"
			},
			CS_tazer = {
				"flank",
				"charge",
				"flash_grenade",
				"shield_cover",
				"murder"
			},
			CS_sniper = {
				"ranged_fire",
				"provide_coverfire",
				"provide_support"
			},
			FBI_suit = {
				"flank",
				"ranged_fire",
				"flash_grenade"
			},
			FBI_suit_stealth = {
				"provide_coverfire",
				"provide_support",
				"flash_grenade",
				"flank"
			},
			FBI_swat_rifle = {
				"smoke_grenade",
				"flash_grenade",
				"provide_coverfire",
				"charge",
				"provide_support",
				"ranged_fire"
			},
			FBI_swat_shotgun = {
				"smoke_grenade",
				"flash_grenade",
				"charge",
				"provide_coverfire",
				"provide_support"
			},
			FBI_heavy = {
				"smoke_grenade",
				"flash_grenade",
				"charge",
				"provide_coverfire",
				"provide_support",
				"shield_cover",
				"deathguard"
			},
			FBI_shield = {
				"smoke_grenade",
				"charge",
				"provide_coverfire",
				"provide_support",
				"shield",
				"deathguard"
			},
			FBI_swat_rifle_flank = {
				"flank",
				"smoke_grenade",
				"flash_grenade",
				"charge",
				"provide_coverfire",
				"provide_support"
			},
			FBI_swat_shotgun_flank = {
				"flank",
				"smoke_grenade",
				"flash_grenade",
				"charge",
				"provide_coverfire",
				"provide_support"
			},
			FBI_heavy_flank = {
				"flank",
				"smoke_grenade",
				"flash_grenade",
				"charge",
				"provide_coverfire",
				"provide_support",
				"shield_cover"
			},
			FBI_shield_flank = {
				"flank",
				"smoke_grenade",
				"flash_grenade",
				"charge",
				"provide_coverfire",
				"provide_support",
				"shield"
			},
			FBI_tank = {
				"charge",
				"deathguard",
				"shield_cover",
				"smoke_grenade"
			},
			spooc = {
				"charge",
				"shield_cover",
				"smoke_grenade",
				"flash_grenade"
			},
			marshal_marksman = {
				"ranged_fire",
				"flank"
			},
			-- tactics for snowman specifically
			tank_rush = {
				"charge",
				"murder"
			},
		}
		
		-- lol
		self.enemy_spawn_groups.piggydozer = {
			amount = {
				1,
				1
			},
			spawn = {
				{
					freq = 1,
					amount_min = 1,
					rank = 1,
					unit = "piggydozer",
					tactics = self._tactics.tank_rush
				}
			},
			spawn_point_chk_ref = table.list_to_set({
				"tac_bull_rush"
			})
		}
		
		-- IMPORTANT NOTE: certain squads had their custom names replaced for vanilla squad names
		-- because some heists use scripted spawns for certain squads at certain points, at certain areas
		-- most noticable examples: brooklyn bank - top floor office area, and whole 2nd floor on tihuana breakfast.
		-- these areas only use scripted spawns, that search for a squad with a specific name
		-- and never spawn cops through standard spawn logic (at least i think thats whats happening).
		-- this was the reason why only cloakers spawned in these areas in DW+ - because their squad name was never updated
		
		self.enemy_spawn_groups.Squad_Blue_Swat = {
			amount = {4, 5},
			spawn = {
				{
					unit = "Blue_swat",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.CS_swat_rifle_flank,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Green_Swat = {
			amount = {4, 5},
			spawn = {
				{
					unit = "Green_swat",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Grey_Swat = {
			amount = {4, 5},
			spawn = {
				{
					unit = "Grey_swat",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Blue_Shield = {
			amount = {2, 4},
			spawn = {
				{
					unit = "CS_shield",
					freq = 1,
					amount_min = 2,
					amount_max = 3,
					tactics = self._tactics.CS_shield,
					rank = 1
				},
				{
					unit = "Blue_swat",
					freq = 1,
					amount_min = 2,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Green_Shield = {
			amount = {2, 4},
			spawn = {
				{
					unit = "Green_shield",
					freq = 1,
					amount_min = 2,
					amount_max = 3,
					tactics = self._tactics.CS_shield,
					rank = 1
				},
				{
					unit = "Green_swat",
					freq = 1,
					amount_min = 2,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Grey_Shield = {
			amount = {2, 4},
			spawn = {
				{
					unit = "Grey_shield",
					freq = 1,
					amount_min = 2,
					amount_max = 3,
					tactics = self._tactics.CS_shield,
					rank = 1
				},
				{
					unit = "Grey_swat",
					freq = 1,
					amount_min = 2,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Blue_Green_Tazer = {
			amount = {1, 3},
			spawn = {
				{
					unit = "Default_tazer",
					freq = 1,
					amount_min = 2,
					amount_max = 3,
					tactics = self._tactics.CS_tazer,
					rank = 1
				},
				{
					unit = "Blue_swat",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.CS_swat_rifle_flank,
					rank = 1
				},
				{
					unit = "Green_swat",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Blue_Green_spooc = {
			amount = {2, 4},
			spawn = {
				{
					unit = "Default_spooc",
					freq = 1,
					amount_max = 1,
					tactics = self._tactics.spooc,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Blue_Green_Tank = {
			amount = {1, 2},
			spawn = {
				{
					unit = "Blue_green_tank",
					freq = 1,
					amount_min = 1,
					amount_max = 1,
					tactics = self._tactics.FBI_tank,
					rank = 1
				},
				{
					unit = "Blue_swat",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.CS_swat_rifle_flank,
					rank = 1
				},
				{
					unit = "Green_swat",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Grey_Tank = {
			amount = {1, 2},
			spawn = {
				{
					unit = "Grey_tank",
					freq = 1,
					amount_min = 1,
					amount_max = 1,
					tactics = self._tactics.FBI_tank,
					rank = 1
				},
				{
					unit = "Grey_swat",
					freq = 1,
					amount_min = 2,
					amount_max = 4,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.FBI_HRT_mix = {
			amount = {1, 2},
			spawn = {
				{
					unit = "FBI_HRT_mix",
					freq = 1,
					amount_min = 2,
					amount_max = 3,
					tactics = self._tactics.CS_swat_rifle_flank,
					rank = 1
				}
			}
		}
		
		-- Squad_Heavy_1
		self.enemy_spawn_groups.tac_swat_rifle_flank = {
			amount = {5, 6},
			spawn = {
				{
					unit = "RifleMen",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Heavy_2 = {
			amount = {5, 6},
			spawn = {
				{
					unit = "RifleMen",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Heavy_3 = {
			amount = {5, 6},
			spawn = {
				{
					unit = "RifleMen",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Light_1 = {
			amount = {5, 6},
			spawn = {
				{
					unit = "SupportCQB",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.CS_swat_rifle_flank,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Light_2 = {
			amount = {5, 6},
			spawn = {
				{
					unit = "SupportCQB",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.CS_swat_rifle_flank,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Light_3 = {
			amount = {5, 6},
			spawn = {
				{
					unit = "SupportCQB",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.CS_swat_rifle_flank,
					rank = 1
				}
			}
		}
		
		-- Squad_Medic
		self.enemy_spawn_groups.tac_tazer_flanking = {
			amount = {2, 2},
			spawn = {
				{
					unit = "medic_M4",
					freq = 1,
					amount_min = 1,
					amount_max = 1,
					tactics = self._tactics.CS_swat_rifle_flank,
					rank = 1
				},
				{
					unit = "RifleMen",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				},
				{
					unit = "medic_R870",
					freq = 0.5,
					amount_min = 0,
					amount_max = 1,
					tactics = self._tactics.CS_swat_rifle_flank,
					rank = 1
				},
			}
		}
		
		-- Squad_Shield
		self.enemy_spawn_groups.tac_shield_wall = {
			amount = {2, 4},
			spawn = {
				{
					unit = "FBI_shield",
					freq = 1,
					amount_min = 1,
					amount_max = 1,
					tactics = self._tactics.CS_shield,
					rank = 1
				},
				{
					unit = "RifleMen",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		-- Squad_Tazer
		self.enemy_spawn_groups.tac_tazer_charge = {
			amount = {1, 3},
			spawn = {
				{
					unit = "CS_tazer",
					freq = 1,
					amount_min = 2,
					amount_max = 2,
					tactics = self._tactics.CS_tazer,
					rank = 1
				},
				{
					unit = "SupportCQB",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.CS_swat_rifle_flank,
					rank = 1
				}
			}
		}
		
		-- Squad_Tank
		self.enemy_spawn_groups.tac_bull_rush = {
			amount = {1, 2},
			spawn = {
				{
					unit = "FBI_tank",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_tank,
					rank = 1
				},
				{
					unit = "RifleMen",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_swat_rifle,
					rank = 1
				}
			}
		}
		
		self.enemy_spawn_groups.Squad_Tank_Annoying = {
			amount = {1, 2},
			spawn = {
				{
					unit = "FBI_tank_annoying",
					freq = 1,
					amount_min = 1,
					amount_max = 1,
					tactics = self._tactics.FBI_tank,
					rank = 1
				},
				{
					unit = "SupportCQB",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.CS_swat_rifle_flank,
					rank = 1
				},
			}
		}
		
		-- this squad is almost never used ever since they gutted the reinforce phase
		self.enemy_spawn_groups.FBI_defence_squad = {
			amount = {2, 4},
			spawn = {
				{
					unit = "SupportCQB",
					freq = 1,
					amount_min = 1,
					amount_max = 2,
					tactics = self._tactics.FBI_suit,
					rank = 1
				}
			}
		}

		self.enemy_spawn_groups.single_spooc = {
			amount = {2, 4},
			spawn = {
				{
					unit = "spooc",
					freq = 1,
					amount_max = 1,
					tactics = self._tactics.spooc,
					rank = 1
				}
			}
		}
		self.enemy_spawn_groups.FBI_spoocs = self.enemy_spawn_groups.single_spooc

		-- Winters
		self.enemy_spawn_groups.Phalanx = {
			amount = {
				self.phalanx.minions.amount + 1,
				self.phalanx.minions.amount + 1
			},
			spawn = {
				{
					amount_min = 1,
					freq = 1,
					amount_max = 1,
					rank = 2,
					unit = "Phalanx_vip",
					tactics = self._tactics.Phalanx_vip
				},
				{
					freq = 1,
					amount_min = 1,
					rank = 1,
					unit = "Phalanx_minion",
					tactics = self._tactics.Phalanx_minion
				}
			}
		}
		
		-- snowman, prob will be removed later, ovkl kept him for now
		self.enemy_spawn_groups.snowman_boss = {
			amount = {
				1,
				1
			},
			spawn = {
				{
					freq = 1,
					amount_min = 1,
					rank = 1,
					unit = "snowman_boss",
					tactics = self._tactics.tank_rush
				}
			},
			spawn_point_chk_ref = table.list_to_set({
				"tac_bull_rush"
			})
		}
		
	end
end)

-- TASK DATA
-- Defines which group actually spawns when. It also defines assault delays etc.
Hooks:PostHook(GroupAITweakData, "_init_task_data", "DS_BW_taskdata_override", function(self, difficulty_index, difficulty)
	if difficulty_index == 8 then
		
		self.smoke_and_flash_grenade_timeout = {
			6,
			12
		}
		self.flash_grenade.timer = 1
		
		self.besiege.assault.build_duration = 5
		
		-- assault duration, smaller values are only used for first 2 waves
		if Global and Global.level_data and Global.level_data.level_id == "nmh" then
			-- no mercy shorter first waves
			self.besiege.assault.sustain_duration_min = {
				60,
				60,
				280
			}
			self.besiege.assault.sustain_duration_max = {
				80,
				80,
				300
			}
		else
			self.besiege.assault.sustain_duration_min = {
				90,
				90,
				265
			}
			self.besiege.assault.sustain_duration_max = {
				110,
				110,
				275
			}
		end
		
		-- duration mul depends on player count
		self.besiege.assault.sustain_duration_balance_mul = {
			1,
			1,
			1,
			1
		}
		
		-- self explanatory
		if Global and Global.level_data and Global.level_data.level_id == "nmh" then
			self.besiege.assault.delay = {
				5,
				20,
				55
			}
		else
			self.besiege.assault.delay = {
				5,
				20,
				35
			}
		end
		
		-- if we have hostages increase delay by a few seconds
		if Global and Global.level_data and Global.level_data.level_id == "nmh" then
			-- no mercy shorter delay for first few waves
			self.besiege.assault.hostage_hesitation_delay = {
				1,
				1,
				15
			}
		else
			self.besiege.assault.hostage_hesitation_delay = {
				10,
				15,
				25
			}
		end
		
		-- Max cop amount on the map at the same time, depends on diff
		self.besiege.assault.force = {
			40,
			44,
			50
		}
		-- adjusments for it based on the map
		if Global and Global.level_data then
		
			local level_balance_data = {
				-- boil point
				mad = 1.24,
				-- rats day 3
				alex_3 = 1.24,
				-- goat sim day 1
				peta = 1.29,
				-- mcshay lost in transit
				trai = 1.14,
				-- birth of sky
				pbr2 = 1.14,
				-- bomb:forest
				crojob3 = 1.14,
				crojob3_night = 1.14,
				-- golden grin
				kenaz = 1.1,
				-- stealing xmas
				moon = 1.1,
				-- mountain master
				pent = 0.85,
			}
			
			local lvl_id = Global.level_data.level_id
			if level_balance_data[lvl_id] then
				local mul = level_balance_data[lvl_id]
				self.besiege.assault.force = {
					math.floor(self.besiege.assault.force[1] * mul),
					math.floor(self.besiege.assault.force[2] * mul),
					math.floor(self.besiege.assault.force[3] * mul)
				}
			end
			
		end
		
		-- multiplier for cop amounts on the map, depends on player count
		self.besiege.assault.force_balance_mul = {
			1,
			1,
			1,
			1
		}
		
		-- Total max cop spawns per each assault
		if Global and Global.level_data and Global.level_data.level_id == "nmh" then
			self.besiege.assault.force_pool = {
				60,
				400,
				400
			}
		else
			self.besiege.assault.force_pool = {
				60,
				250,
				250
			}
		end
		
		-- for thing above - player count mul
		self.besiege.assault.force_pool_balance_mul = {
			1,
			1,
			1,
			1
		}

		-- Add cloaker specific group
		self.besiege.cloaker.groups = {
			single_spooc = {
				1,
				1,
				1
			}
		}
		
		self:init_taskdata_spawnRates()
		
		-- Why tf is it this way?
		self.street = deep_clone(self.besiege)
		self.safehouse = deep_clone(self.besiege)
	
	end
	
	-- ingame check
	if NoobJoin or BLT.Mods:GetModByName("Newbies go back to overkill") then
		DS_BW:yoink_ngbto()
	end
end)

function GroupAITweakData:_init_enemy_spawn_groups_level(tweak_data, difficulty_index)
	local lvl_tweak_data = tweak_data.levels[Global.game_settings and Global.game_settings.level_id or Global.level_data and Global.level_data.level_id]

	if Global.level_data and Global.level_data.level_id == "deep" then
		-- ignore unit type overrides specifically for crude awakening, since only change here is to the marshal's uniform colour -- this is a leftover from dw+, that i dont think i need to remove
		-- rest of the function is base game code, let's hope it wont break with new updates :)
	elseif lvl_tweak_data and lvl_tweak_data.ai_unit_group_overrides then
		local unit_types = nil

		for unit_type, faction_type_data in pairs(lvl_tweak_data.ai_unit_group_overrides) do
			unit_types = self.unit_categories[unit_type] and self.unit_categories[unit_type].unit_types

			if unit_types then
				for faction_type, override in pairs(faction_type_data) do
					if unit_types[faction_type] then
						unit_types[faction_type] = override
					end
				end
			end
		end
	end

	-- commented out values are base game values, for reference. rip tweaking shield amounts for the train heist, but tbh, after flashlight range buff they are ridiculously annoying
	if lvl_tweak_data and not lvl_tweak_data.ai_marshal_spawns_disabled then
		self.enemy_spawn_groups.marshal_squad = {
			spawn_cooldown = 15, -- 60
			max_nr_simultaneous_groups = 1,
			initial_spawn_delay = 40, -- 90
			amount = {
				1,
				2 -- 2
			},
			spawn = {
				{
					respawn_cooldown = 40, -- 30
					amount_min = 1,
					amount_max = 1, -- nil
					rank = 2,
					freq = 1,
					unit = "marshal_shield",
					tactics = self._tactics.marshal_shield
				},
				{
					respawn_cooldown = 20, -- 30
					amount_min = 1, -- 1
					amount_max = 2, -- nil
					rank = 1,
					freq = 1,
					unit = "marshal_marksman",
					tactics = self._tactics.marshal_marksman
				}
			},
			spawn_point_chk_ref = table.list_to_set({
				"tac_shield_wall",
				"tac_shield_wall_ranged",
				"tac_shield_wall_charge"
			})
		}
	end
end

-- IMPORTANT NOTE: certain squads had their custom names replaced for vanilla squad names
-- because some heists use scripted spawns for certain squads at certain points, at certain areas
-- most noticable examples: brooklyn bank - top floor office area, and whole 2nd floor on tihuana breakfast.
-- these areas only use scripted spawns, that search for a squad with a specific name
-- and never spawn cops through standard spawn logic (at least i think thats whats happening).
-- this was the reason why only cloakers spawned in these areas in DW+ - because their squad name was never updated
function GroupAITweakData:init_taskdata_spawnRates()
	self.besiege.assault.groups = {
		-- first wave units
		Squad_Blue_Swat = {
			0.12,
			0,
			0
		},
		Squad_Green_Swat = {
			0.12,
			0,
			0
		},
		Squad_Blue_Shield = {
			0.1,
			0,
			0
		},
		Squad_Green_Shield = {
			0.1,
			0,
			0
		},
		Squad_Blue_Green_Tazer = {
			0.15,
			0,
			0
		},
		Squad_Blue_Green_spooc = {
			0.15,
			0,
			0
		},
		Squad_Blue_Green_Tank = {
			0.15,
			0,
			0
		},
		Squad_Grey_Swat = {
			0,
			0.12,
			0
		},
		Squad_Grey_Shield = {
			0,
			0.1,
			0
		},
		Squad_Grey_Tank = {
			0,
			0.075,
			0
		},
		-- zeal
		Squad_Light_1 = {
			0,
			0.01,
			0.015
		},
		Squad_Light_2 = {
			0,
			0.01,
			0.015
		},
		Squad_Light_3 = {
			0,
			0.01,
			0.015
		},
		FBI_HRT_mix = {
			0.2,
			0.05,
			0.025
		},
		tac_swat_rifle_flank = { -- Squad_Heavy_1
			0,
			0.01,
			0.047
		},
		Squad_Heavy_2 = {
			0,
			0,
			0.047
		},
		Squad_Heavy_3 = {
			0,
			0,
			0.047
		},
		tac_tazer_flanking = { -- Squad_Medic
			0,
			0.15,
			0.2
		},
		tac_shield_wall = { -- Squad_Shield
			0,
			0.05,
			0.25
		},
		tac_tazer_charge = { -- Squad_Tazer
			0,
			0.15,
			0.25
		},
		tac_bull_rush = { -- Squad_Tank
			0,
			0.05,
			0.08
		},
		Squad_Tank_Annoying = {
			0,
			0,
			0.07
		},
		FBI_spoocs = {
			0,
			0.04,
			0.08
		},
		single_spooc = {
			0,
			0.04,
			0.08
		},
		Phalanx = {
			0,
			0,
			0
		},
		marshal_squad = {
			0,
			0,
			0
		},
		snowman_boss = {
			0,
			0,
			0
		},
		piggydozer = {
			0,
			0,
			0
		}
	}

	self.besiege.reenforce.groups = {
		FBI_defence_squad = {
			1,
			1,
			1
		}
	}

	self.besiege.recon.groups = {
		FBI_defence_squad = {
			1,
			1,
			1
		},
		single_spooc = {
			0,
			0,
			0
		},
		Phalanx = {
			0,
			0,
			0
		},
		marshal_squad = {
			0,
			0,
			0
		},
		snowman_boss = {
			0,
			0,
			0
		},
		piggydozer = {
			0,
			0,
			0
		}
	}
	
	self.phalanx.check_spawn_intervall = 75
	self.phalanx.chance_increase_intervall = 75
	self.phalanx.spawn_chance = {
		decrease = 0.4,
		start = 0.4,
		respawn_delay = 750,
		increase = 0.04,
		max = 1
	}
	
	DS_BW.base_groupaitweak_values = {
		assault_force = deep_clone(self.besiege.assault.force)
	}
	if self.special_unit_spawn_limits then
		DS_BW.base_groupaitweak_values.special_limits = deep_clone(self.special_unit_spawn_limits)
	end
end