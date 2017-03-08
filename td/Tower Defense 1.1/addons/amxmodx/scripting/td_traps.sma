/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <td>
#include <fakemeta_util>
#include <hamsandwich>

#define PLUGIN "TD Traps"
#define VERSION "1.0"
#define AUTHOR "GT Team"

#define MAX_TRACKS 35

#define TRAP_DAMAGE 1500
#define TRAP_SLOWMO 0.50
#define TRAP_SLOWMO_DURATION 6.0

enum {
	NONE = 0,
	HURTING = 1,
	SLOWING = 2
}

new g_szTrapModel[] = "models/TD/trap.mdl"

new Float:g_fTracksOrigin[MAX_TRACKS][3]
new g_iTracksTraps[MAX_TRACKS]
new g_iTrackNum

new bool: g_bStatus = true

new g_iPlayerTrapEnt[33]
new bool:g_bPlayerIsChoosing[33]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /trap", "trapMenu")
	register_clcmd("say /traps", "trapMenu")
	
	register_touch("trap", "monster", "asd");

	loadTracks(MAX_TRACKS)
}


public asd(trap, monster) {	
	switch(entity_get_edict(trap, EV_ENT_euser2)) {
		case HURTING: {
			if(!td_is_special_monster(monster)) {
				fm_set_rendering(monster, kRenderFxGlowShell, 255, 50, 0, _, 16)
			}
			if(entity_get_float(monster, EV_FL_health) - TRAP_DAMAGE <= 0.0) {
				td_kill_monster(monster, entity_get_edict(trap, EV_ENT_owner))
				goto set
			}
			
			ExecuteHam(Ham_TakeDamage, monster, entity_get_edict(trap, EV_ENT_owner), entity_get_edict(trap, EV_ENT_owner), TRAP_DAMAGE, DMG_CLUB)
			
			if(! td_is_special_monster(monster)) {
				set_task(0.3, "endRendering", 1552+monster)
			}
		} 
		case SLOWING: { 

			new szSpeed[5]
			num_to_str(td_get_monster_speed(monster), szSpeed, 4)
			td_set_monster_speed(monster, floatround((td_get_monster_speed(monster)*TRAP_SLOWMO)))
			fm_set_rendering(monster, kRenderFxGlowShell, 0, 50, 200, _, 16)
			set_task(TRAP_SLOWMO_DURATION, "endSlowmotion", 1992+monster, szSpeed, 4)
		}
		default: return
	}
	set:
	g_iPlayerTrapEnt[entity_get_edict(trap, EV_ENT_owner)] = 0
	g_iTracksTraps[entity_get_edict(trap, EV_ENT_euser1)] = 0
	remove_entity(trap)
	
}
public endRendering(monster) {
	monster-=1552
	fm_set_rendering(monster, kRenderFxGlowShell, 0, 0, 0, _ , 0)
}
public endSlowmotion(szData[5], monster) { 
	monster-=1992
	new bef_speed = str_to_num(szData)
	if(td_is_monster(monster)) {
		fm_set_rendering(monster, kRenderFxGlowShell, td_is_special_monster(monster)?255:0, td_is_special_monster(monster)==2?255:0, 0, _, td_is_special_monster(monster)?17:0)
		
		new act_speed = td_get_monster_speed(monster)
		
		new speed = bef_speed - act_speed
		td_set_monster_speed(monster, td_get_monster_speed(monster)+speed)
	}
}
	
public trapMenu(id) {
	if(!is_user_alive(id) || !g_bStatus) {
		return
	}
	
	if(td_get_user_info(id, PLAYER_GOLD) < 25)
	{
		client_print_color(id, 0, "^4You dont have 25 gold!");
		return
	}
	new menu = menu_create("Select type of trap:", "trapMenuH")
	
	menu_additem(menu, "Hurting [1500 DMG] [25 GOLD]")
	
	menu_display(id, menu)
	
}

public trapMenuH(id, menu, item) {
	
	if(item == MENU_EXIT) {
		menu_destroy(menu)
		return
	}
	
	trapMenuType(id, item+1)
}

public trapMenuType(id, type) {
	if(!is_user_alive(id)) {
		return
	}
	new num
	for(new i = 1; i < g_iTrackNum; i ++) {
		if(g_iTracksTraps[i]) {
			num++
		}
	}
	if(num == g_iTrackNum) {
		client_print(id, print_center, "Map reached limit [%d]!", num)
		client_print_color(id, 0, "Map reached limit [%d]!", num)
		return
	}
	if(g_iPlayerTrapEnt[id]) {
		client_print(id, print_center, "You alerady have a trap !")
		client_print_color(id, 0, "^4You alerady have a trap !")
		return
	}
	g_bPlayerIsChoosing[id] = true
	new menu = menu_create("Select place of trap^nby aiming on corner of track", "trapMenuTypeH")
	new index[3]
	num_to_str(type, index, 2)
	menu_additem(menu, "Place it here", index)
	menu_additem(menu, "Back")
	
	menu_display(id, menu)
}

public trapMenuTypeH(id, menu, item) {
	
	if(item == 1 || item == MENU_EXIT) {
		g_bPlayerIsChoosing[id] = false
		if(is_valid_ent(g_iPlayerTrapEnt[id])) {
			remove_entity(g_iPlayerTrapEnt[id])	
		}
		g_iPlayerTrapEnt[id] = 0
		trapMenu(id)
		return
	}
	new acces, index[3], type, cb
	menu_item_getinfo(menu, 0, acces, index, 2, _, _, cb)
	type = str_to_num(index)
	
	if(type == NONE) {
		return
	}
	if(!g_iPlayerTrapEnt[id]) {
		client_print(id, print_center, "You have to select proper corner of track!")
		client_print_color(id, 0, "^4You have to select proper corner of track!")
		trapMenuType(id, type)
		return
		
	}
	g_bPlayerIsChoosing[id] = false
	
	if(type == HURTING)
	{
		td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD)-25)
	}
	entity_set_edict(g_iPlayerTrapEnt[id], EV_ENT_euser2, type);
	entity_set_int(g_iPlayerTrapEnt[id], EV_INT_solid, SOLID_TRIGGER)
	fm_set_rendering(g_iPlayerTrapEnt[id], kRenderFxGlowShell, (type==HURTING?255:0), 50, (type==SLOWING?200:0), _, 16)
	g_iTracksTraps[entity_get_edict(g_iPlayerTrapEnt[id], EV_ENT_euser1)] = g_iPlayerTrapEnt[id]
}

public client_disconnected(id) 
{
	ResetUserInfo(id)
}
public ResetUserInfo(id)
{
	g_bPlayerIsChoosing[id] = false
	if(is_valid_ent(g_iPlayerTrapEnt[id]))
		remove_entity(g_iPlayerTrapEnt[id])

	g_iPlayerTrapEnt[id] = 0
}
public td_reset_game(imode, Float:fTime) {
	for(new i = 1 ;i < 33; i++ ) {
		if(is_user_connected(i)) {
			ResetUserInfo(i);
		}
	}
}
public td_reset_player_info(id) {
	ResetUserInfo(id)
}
public plugin_precache() {
	precache_model(g_szTrapModel)
}

public client_PostThink(id) {
	if(!is_user_alive(id) || !g_bStatus || !g_bPlayerIsChoosing[id]) {
		return
	}

	new bool:bCreated = false
	if(!bCreated && !g_iPlayerTrapEnt[id]) 
	{
		new iTrackIndex = getClosestTrack(id, 0), iEnt
		if(iTrackIndex != -1) {
			if(entity_get_edict(g_iPlayerTrapEnt[id], EV_ENT_euser1) != iTrackIndex && !g_iTracksTraps[iTrackIndex]) {
				if(is_valid_ent(g_iPlayerTrapEnt[id])) {
					remove_entity(g_iPlayerTrapEnt[id])
					g_iPlayerTrapEnt[id] = 0
				}
				g_iPlayerTrapEnt[id] = iEnt = create_entity("info_target")
				bCreated = true
				entity_set_string(iEnt, EV_SZ_classname, "trap")
				entity_set_model(iEnt, g_szTrapModel)
				entity_set_edict(iEnt, EV_ENT_owner, id)
				entity_set_int(iEnt, EV_INT_solid,SOLID_TRIGGER)
				entity_set_edict(iEnt, EV_ENT_euser1, iTrackIndex)
				entity_set_size(iEnt, Float:{-40.0, -40.0, -40.0}, Float:{40.0, 40.0, 100.0})
				entity_set_origin(iEnt, g_fTracksOrigin[iTrackIndex])

				
			}
		}
	}
	if(!bCreated) {
		if(g_iPlayerTrapEnt[id]) {
			new Float:fUserOrigin[3]
			entity_get_vector(id, EV_VEC_origin, fUserOrigin)
			
			if(get_distance_f(fUserOrigin, g_fTracksOrigin[entity_get_edict(g_iPlayerTrapEnt[id], EV_ENT_euser1)]) > 250.0) {
				remove_entity(g_iPlayerTrapEnt[id])
				g_iPlayerTrapEnt[id] = 0
			}
		}
		
		new iTrackIndex = getClosestTrack(id, 1)
		if(iTrackIndex == -1) {
			return
		}
		if(g_iTracksTraps[iTrackIndex]) {
			return
		}
		if(is_valid_ent(g_iPlayerTrapEnt[id])) {
			if(entity_get_edict(g_iPlayerTrapEnt[id], EV_ENT_euser1) == iTrackIndex) {
				return
			}
		}
		
		if(g_iPlayerTrapEnt[id]) {
			entity_set_origin(g_iPlayerTrapEnt[id], g_fTracksOrigin[iTrackIndex])
			entity_set_edict(g_iPlayerTrapEnt[id], EV_ENT_euser1, iTrackIndex)
			entity_set_int(g_iPlayerTrapEnt[id], EV_INT_solid,SOLID_TRIGGER)
		} else {
			new iEnt
			g_iPlayerTrapEnt[id] = iEnt = create_entity("info_target")
			entity_set_string(iEnt, EV_SZ_classname, "trap")
			entity_set_model(iEnt, g_szTrapModel)
			entity_set_int(iEnt, EV_INT_solid,SOLID_TRIGGER)
			entity_set_edict(iEnt, EV_ENT_owner, id)
			entity_set_edict(iEnt, EV_ENT_euser1, iTrackIndex)
			entity_set_size(iEnt, Float:{-40.0, -40.0, -40.0}, Float:{40.0, 40.0, 100.0})
			entity_set_origin(iEnt, g_fTracksOrigin[iTrackIndex])

		}
	}
}

public getClosestTrack(id, mode) {	
	new iEntList[9], iNum, szFormat[16]
	static iOrigin[3], Float:fOrigin[3], Float:fOrigin2[3]
	if(!mode) {
		iNum = find_sphere_class(id, "info_target", 230.0, iEntList, 9)
		} else if(mode) {
		get_user_origin(id, iOrigin, 3)
		IVecFVec(iOrigin, fOrigin)
		entity_get_vector(id, EV_VEC_origin, fOrigin2)
		iNum = find_sphere_class(0, "info_target", 100.0, iEntList, 9, fOrigin)
	}
	for( new i; i < iNum ; i++ ) {
		if(is_valid_ent(iEntList[i])) 
		{			
			if(iEntList[i] == g_iPlayerTrapEnt[i]) {
				continue
			}
			
			entity_get_string(iEntList[i], EV_SZ_classname, szFormat, charsmax(szFormat))
			if(containi(szFormat, "monster") != -1) {
				continue
			}
			
			entity_get_string(iEntList[i], EV_SZ_targetname, szFormat, charsmax(szFormat))
			if(containi(szFormat, "track") != -1) {
				if(mode) {
					
					if(get_distance_f(fOrigin, fOrigin2) >= 750.0) {
						continue
					}
				}
				replace_string(szFormat, charsmax(szFormat), "track", "")
				trim(szFormat)
				return str_to_num(szFormat)
			}
		}
	}
	
	return -1
}
public client_PreThink(id) {
}

public loadTracks(iTracksNum) {
	new iEnt, szFormat[16]
	
	iEnt = find_ent_by_tname(-1, "track1")
	new num
	if( ! is_valid_ent ( iEnt ) )  {
		g_bStatus = false
		return PLUGIN_CONTINUE
	}
	for ( new i ; i < iTracksNum; i++ ) {
		formatex(szFormat, charsmax(szFormat), "track%d", i)
		
		iEnt = find_ent_by_tname(-1, szFormat)
		
		if( is_valid_ent(iEnt) ) {
			num++
			static Float:fVector[3]
			entity_get_vector(iEnt, EV_VEC_origin, fVector)
			fVector[2]-=5.0
			g_fTracksOrigin[i] = fVector
		}
	}
	g_iTrackNum = num
	return PLUGIN_CONTINUE
}

public bool:isTrap(iEnt) {
	for(new i ; i < g_iTrackNum ; i ++ ) {
		if(g_iTracksTraps[i] == iEnt) {
			return true
		}
	}
	return false
}