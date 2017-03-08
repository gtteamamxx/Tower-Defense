#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <cstrike>
#include <hamsandwich>
#include <amxmisc>
#include <fun>
#include <td>

#define MAX_BLOOD_DISTANCE	64
#define LOADUP_TIME		0.75
#define SHUTDOWN_TIME	1.7
#define SHAKE_FORCE		-5.0

new const GUNSHOT_DECALS[] = {41, 42, 43, 44, 45}

new bool:has_minigun[33], Float:m249, bool:atk2[33], bool:atk1[33],
bool:delay[33], clipp[33],clipstart[33],g_fwid,bool:delayhud[33],bool:beackup[33],bool:frstCLIP[33],g_MaxPlayers,g_guns_eventids_bitsum,bool:haswhpnnmg[33],
Float:g_lastShot[33], Float:g_nextSound[33], g_plAction[33],bool:g_fix_punchangle[33],
bool:canfire[33],oneround,g_normal_trace[33],Float:DMGMG,bool:user_bot[33],
bool:is_alive[33],bool:is_connected[33]

new g_blood
new g_bloodspray

const OFFSET_CSTEAMS = 114

const OFFSET_LINUX = 5

new P_MODEL[] = "models/wpnmod/m134/p_minigun.mdl"
new V_MODEL[] = "models/wpnmod/m134/v_minigun.mdl"
new W_MODEL[] = "models/wpnmod/m134/w_minigun.mdl"

new m_SOUND[][] = {"wpnmod/minigun/hw_shoot1.wav", "wpnmod/minigun/hw_spin.wav", "wpnmod/minigun/hw_spinup.wav", "wpnmod/minigun/hw_spindown.wav"}
new g_noammo_sounds[][] = {"weapons/dryfire_rifle.wav"}

new const g_guns_events[][] = {"events/m249.sc"}

#define is_user_valid_connected(%1) (1 <= %1 <= g_MaxPlayers && is_connected[%1])

enum {
	anim_idle,
	anim_idle2,
	anim_gentleidle,
	anim_stillidle,
	anim_draw,
	anim_holster,
	anim_spinup,
	anim_spindown,
	anim_spinidle,
	anim_spinfire,
	anim_spinidledown
}

enum {
	act_none,
	act_load_up,
	act_run
}

new iItem;

public plugin_precache() {
	precache_model(P_MODEL)
	precache_model(V_MODEL)
	precache_model(W_MODEL)
	precache_sound(m_SOUND[0])
	precache_sound(m_SOUND[1])
	precache_sound(m_SOUND[2])
	precache_sound(m_SOUND[3])
	
	g_blood = precache_model("sprites/blood.spr")
	g_bloodspray = precache_model("sprites/bloodspray.spr")
	g_fwid = register_forward(FM_PrecacheEvent, "fwPrecacheEvent", 1)
}


new bought[33] = 0
public plugin_init() {
	new id = register_plugin("TD Shop: Minigun", "1.65", "CLLlAgOB edited by GT Team")
	
	m249 = 		0.2
	DMGMG =		1.5
	
	register_event("CurWeapon","event_curweapon","be", "1=1")
	register_event("DeathMsg","unminigun","a")
	
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect")
	register_forward(FM_CmdStart, "fwd_CmdStart")
	register_forward(FM_EmitSound,"fwd_emitsound")
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_PlayerPostThink, "fwPlayerPostThink", 1)
	register_forward(FM_StartFrame, "fwd_StartFrame")
	register_forward(FM_UpdateClientData, "UpdateClientData_Post", 1)
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "player_TakeDamage")
	
	register_clcmd("drop","dropcmd")
	
	g_MaxPlayers = global_get(glb_maxClients)
	
	register_logevent("event_start", 2, "1=Round_Start")
	register_event("TextMsg", "fwEvGameWillRestartIn", "a", "2=#Game_will_restart_in")
	register_event("HLTV", "event_start_freezetime", "a", "1=0", "2=0")
	unregister_forward(FM_PrecacheEvent, g_fwid, 1)
	
	iItem = td_shop_register_item("Minigun", "You get minigun!", 650, 1, id)
}
public plugin_natives() {
	
	/* Set ammunition for minigun */
	register_native("set_cp", "_set_cp", 1)
}
public _set_cp(id) {
	clipstart[id] += 500
	if(frstCLIP[id] == false) {
		clipp[id] += 500

		new ent = get_weapon_ent(id,_, "weapon_m249")
		cs_set_weapon_ammo(ent, clipp[id])
	}
}
	
public td_shop_item_selected(id, itemid)
{
	if(iItem == itemid)
	{
		give_weapon(id, 0, 1)
	}

}
public client_putinserver(id)
{
	clipstart[id] = 500
	bought[id] = 0
	is_connected[id] = true
}
public fw_ClientDisconnect(id)
{
	if(is_user_alive(id))
	{
		new iEnt = find_ent_by_owner(0, "minigun", id)
		if(iEnt)
			remove_entity(iEnt)
	}
	is_connected[id] = false
	is_alive[id] = false
	clipstart[id] = 500
}
public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !fm_cs_get_user_team(id))
		return;
	is_alive[id] = true
}
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	is_alive[victim] = false
}
public unminigun(){
	new id = read_data(2) 
	if(has_minigun[id] && !is_alive[id]) {
		new Float:Aim[3],Float:origin[3]
		VelocityByAim(id, 64, Aim)
		entity_get_vector(id,EV_VEC_origin,origin)
		
		origin[0] += Aim[0]
		origin[1] += Aim[1]
		
		new minigun = create_entity("info_target")
		entity_set_string(minigun,EV_SZ_classname,"minigun")
		entity_set_model(minigun,W_MODEL)	
		
		entity_set_size(minigun,Float:{-2.0,-2.0,-2.0},Float:{5.0,5.0,5.0})
		entity_set_int(minigun,EV_INT_solid,1)
		
		entity_set_int(minigun,EV_INT_movetype,6)
		entity_set_int(minigun, EV_INT_iuser1, clipp[id])
		entity_set_vector(minigun,EV_VEC_origin,origin)
		has_minigun[id] = false
		remowegun(id)
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public player_TakeDamage(victim, inflictor, attacker, Float:damage, damagetype) {
	if(damagetype & DMG_BULLET && haswhpnnmg[attacker] && has_minigun[attacker] == true  && attacker!=victim)
		{
		damage = damage*DMGMG
		SetHamParamFloat(4, damage)
		return HAM_IGNORED
		} 
	return HAM_IGNORED
}



public dropcmd(id) {
	if(has_minigun[id] && haswhpnnmg[id] && is_alive[id]) {
		new Float:Aim[3],Float:origin[3]
		VelocityByAim(id, 64, Aim)
		entity_get_vector(id,EV_VEC_origin,origin)
		
		origin[0] += Aim[0]
		origin[1] += Aim[1]
		
		new minigun = create_entity("info_target")
		entity_set_string(minigun,EV_SZ_classname,"minigun")
		entity_set_model(minigun,W_MODEL)	
		set_pev(minigun, pev_owner, id)
		entity_set_size(minigun,Float:{-2.0,-2.0,-2.0},Float:{5.0,5.0,5.0})
		entity_set_int(minigun,EV_INT_solid,1)
		
		entity_set_int(minigun,EV_INT_movetype,6)
		entity_set_int(minigun, EV_INT_iuser1, clipp[id])
		entity_set_vector(minigun,EV_VEC_origin,origin)
		has_minigun[id] = false
		canfire[id] = false
		remowegun(id)
		g_plAction[id] = false
		return PLUGIN_HANDLED
	} 
	return PLUGIN_CONTINUE
}

public pfn_touch(ptr, ptd) {
	if(is_valid_ent(ptr)) {
		new classname[32]
		entity_get_string(ptr,EV_SZ_classname,classname,31)
		
		if(equal(classname, "minigun")) {
			if(is_valid_ent(ptd)) {
				new id = ptd
				if(id > 0 && id < 33) {
					if(!has_minigun[id] && is_alive[id]) {
						if(id == pev(ptr, pev_owner))
						{
							give_weapon(id,entity_get_int(ptr, EV_INT_iuser1), 0)
							canfire[id] = true
							remove_entity(ptr)
						}
						else {
							client_print(id, print_center, "To nie jest Twoj minigun!")
						}
					}
				}
			}
		}
	}
}

public remove_miniguns() {
	new nextitem  = find_ent_by_class(0,"minigun")
	while(nextitem) {
		remove_entity(nextitem)
		nextitem = find_ent_by_class(0,"minigun")
	}
	return PLUGIN_CONTINUE
}
public event_start_freezetime(){
	remove_miniguns()
	static iPlayers[32], iPlayersNum, i 
	get_players(iPlayers, iPlayersNum, "a")
		
	if(oneround){
		for (i = 0; i <= iPlayersNum; ++i){
			if(has_minigun[iPlayers[i]]){
				has_minigun[iPlayers[i]] = false 
				remowegun(iPlayers[i])
			}
		}
	} else { 
		for (i = 0; i <= iPlayersNum; ++i){
			g_plAction[iPlayers[i]] = false
			canfire[iPlayers[i]] = false
			frstCLIP[iPlayers[i]] = true	
			}
	}
}

public remowegun(id) { 
	new wpnList[32] 
	new number
	get_user_weapons(id,wpnList,number) 
	for (new i = 0;i < number ;i++) { 
		if (wpnList[i] == CSW_M249) {
			fm_strip_user_gun(id, wpnList[i])
		}
	}
} 

public event_start(){
	static iPlayers[32], iPlayersNum, i 
	get_players(iPlayers, iPlayersNum, "a") 
	for (i = 0; i <= iPlayersNum; ++i)
		canfire[iPlayers[i]] = true
}



public fwEvGameWillRestartIn() { 
	static iPlayers[32], iPlayersNum, i 
	get_players(iPlayers, iPlayersNum, "a") 
	for (i = 0; i <= iPlayersNum; ++i) 
		has_minigun[iPlayers[i]] = false
}
public client_connect(id){
	canfire[id]= false
	has_minigun[id] = false
	g_normal_trace[id] = 0
	if(is_user_bot(id)) user_bot[id] = true 
	else user_bot[id] = false 
}
public fwd_emitsound(id, channel, sample[], Float:volume, Float:attn, flag, pitch)
{	
	if (!is_user_valid_connected(id) || !has_minigun[id])
		return FMRES_IGNORED;
	else if((equal(sample, g_noammo_sounds[0])) && has_minigun[id] && haswhpnnmg[id]) 
		{
		return FMRES_SUPERCEDE
		}	
	return FMRES_IGNORED
}
public give_weapon(id, ammo, frst){
	has_minigun[id] = true
	give_item(id,"weapon_m249")
	canfire[id] = true
	clipp[id] = ammo
	if(frst) frstCLIP[id] = true
	else beackup[id] = true
	
}
public native_playanim(player,anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}


 public fwd_CmdStart(id, uc_handle, seed)
{
	if(!is_alive[id] || !canfire[id] || !has_minigun[id]) return FMRES_HANDLED
	
	if(haswhpnnmg[id])
	{
		static buttons
		buttons = get_uc(uc_handle, UC_Buttons)		
		if(buttons & IN_ATTACK)
		{
			atk1[id] = true
			atk2[id] = false

			
		}
		else if(buttons & IN_ATTACK2)
		{
			atk2[id] = true
			atk1[id] = false
		}
		
		if(atk1[id] && !atk2[id] && (g_plAction[id] == act_none || g_plAction[id] == act_load_up) && clipp[id]>0){
			buttons &= ~IN_ATTACK
			buttons &= ~IN_ATTACK2
			set_uc(uc_handle, UC_Buttons, buttons)
			fire_mode(id,0)
		} else if(atk2[id] || atk1[id] && clipp[id]==0){
			fire_mode(id,1)
		}
			
	}
	return FMRES_IGNORED	
}
fire_mode(id, type) {
	static Float:gtime
	gtime = get_gametime()
	g_lastShot[id] = gtime
	
	if(g_nextSound[id] <= gtime && canfire[id]) {
		switch(g_plAction[id]) {
			case act_none: {
				native_playanim(id, anim_spinup)
				emit_sound(id, CHAN_WEAPON, m_SOUND[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
				g_nextSound[id] = gtime + LOADUP_TIME
				g_plAction[id] = act_load_up
			}
			case act_load_up: {
				g_nextSound[id] = gtime
				g_plAction[id] = act_run
			}
		}
	}
	
	if(g_plAction[id] == act_run) {
		if(type == 0 && clipp[id]>0 && atk1[id]){
			emit_sound(id, CHAN_WEAPON, m_SOUND[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
			testbulet(id)
			if(!delay[id]) {
				native_playanim(id, anim_spinfire)
				ammo_hud(id)
				set_task(0.2,"delayanim",id)
				delay[id] = true
			}
		} 
		else { 
			if(!delay[id]) {
				ammo_hud(id)
				emit_sound(id, CHAN_WEAPON, m_SOUND[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
				native_playanim(id, anim_spinidle)
				set_task(0.2,"delayanim",id)
				delay[id] = true
			}
		}
	}
	atk1[id] = false
	atk2[id] = false
}

public delayanim(id){
	delay[id] = false
}
public event_curweapon(id){
	if(!is_alive[id] || !is_connected[id] || user_bot[id]) 
		return;	

	new clip, ammo, weapon = get_user_weapon(id, clip, ammo)
	clip = clipp[id]
	if((has_minigun[id]) && (weapon == CSW_M249))
	{
		if(g_plAction[id] != act_run && frstCLIP[id])
		{
			new ent = get_weapon_ent(id,weapon)
			if(clipp[id] < clipstart[id]) clipp[id] = clipstart[id]
			cs_set_weapon_ammo(ent, clipp[id])
			frstCLIP[id] = false
		}

		if(g_plAction[id] != act_run && beackup[id])
		{
			new ent = get_weapon_ent(id,weapon)
			cs_set_weapon_ammo(ent, clipp[id])
			beackup[id] = false
		}

		if(clipp[id] == 0)
		{
			new ent = get_weapon_ent(id,weapon)
			cs_set_weapon_ammo(ent, clipp[id])
		}
		if(g_plAction[id] == act_run)
		{
			clipp[id] = clip-1
			clip = clipp[id]
			new ent = get_weapon_ent(id,weapon)
			cs_set_weapon_ammo(ent, clipp[id])
		}
	
		message_begin(MSG_ONE, get_user_msgid("CurWeapon"), {0,0,0}, id) 
		write_byte(1) 
		write_byte(CSW_KNIFE) 
		write_byte(0) 
		message_end()

		if(!haswhpnnmg[id])
		{
			entity_set_string(id,EV_SZ_viewmodel,V_MODEL)
			entity_set_string(id,EV_SZ_weaponmodel,P_MODEL)
			haswhpnnmg[id] = true
		}

		new Ent = get_weapon_ent(id,weapon)	
		new Float:N_Speed
		
		if(Ent)
		{
			N_Speed = m249
			new Float:Delay = get_pdata_float( Ent, 46, 4) * N_Speed	
			if (Delay > 0.0)
			{
				set_pdata_float( Ent, 46, Delay, 4)
			}
		}
		ammo_hud(id)

		if(atk1[id])
		{
			fire_mode(id, 0)
		}
		if(atk2[id])
		{
			fire_mode(id, 1)
		}

	} 
	if(weapon != CSW_M249) haswhpnnmg[id] = false
	if((has_minigun[id]) && (!haswhpnnmg[id])) g_plAction[id] = act_none
	bought[id] = 0
	return;
 }	
 
public fwd_StartFrame() {
	static Float:gtime, id
	
	gtime = get_gametime()
	
	for(id = 0; id <= g_MaxPlayers; id++) {
		if(g_plAction[id] != act_none) {
			
			if(!(pev(id, pev_button) & IN_ATTACK) && !(pev(id, pev_button) & IN_ATTACK2) && g_lastShot[id] + 0.2 < gtime) {
				native_playanim(id, anim_spinidledown)
				emit_sound(id, CHAN_WEAPON, m_SOUND[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
				g_nextSound[id] = gtime + SHUTDOWN_TIME
				g_plAction[id] = act_none
			}
		}
	}
}
 public native_gi_get_gunshot_decal()
{
	return GUNSHOT_DECALS[random_num(0, sizeof(GUNSHOT_DECALS) - 1)]
}
public testbulet(id){
	new aimOrigin[3], target, body
	get_user_origin(id, aimOrigin, 3)
	get_user_aiming(id, target, body)
	
	if(target > 0 && target <= g_MaxPlayers)
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		
		velocity_by_aim(id, MAX_BLOOD_DISTANCE, fVel)
		
		fStart[0] = float(aimOrigin[0])
		fStart[1] = float(aimOrigin[1])
		fStart[2] = float(aimOrigin[2])
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
				
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short(g_bloodspray)
		write_short(g_blood)
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
		
		
	} else {
		new decal = native_gi_get_gunshot_decal()
		
		if(target)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(decal)
			write_short(target)
			message_end()
		} else {
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(decal)
			message_end()
		}
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(aimOrigin[0])
		write_coord(aimOrigin[1])
		write_coord(aimOrigin[2])
		write_short(id)
		write_byte(decal)
		message_end()
	}
}
public UpdateClientData_Post( id, sendweapons, cd_handle ){
	if ( !is_alive[id] ) return FMRES_IGNORED;
	if(haswhpnnmg[id] && has_minigun[id]) set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001 );      
	return FMRES_HANDLED;
}
public fwPrecacheEvent(type, const name[]) {
	for (new i = 0; i < sizeof g_guns_events; ++i) {
		if (equal(g_guns_events[i], name)) {
			g_guns_eventids_bitsum |= (1<<get_orig_retval())
			return FMRES_HANDLED
		}
	}

	return FMRES_IGNORED
}
public fwPlaybackEvent(flags, invoker, eventid) {
	if (!(g_guns_eventids_bitsum & (1<<eventid)) || !(1 <= invoker <= g_MaxPlayers)|| !haswhpnnmg[invoker] || !has_minigun[invoker])
		return FMRES_IGNORED

	g_fix_punchangle[invoker] = true

	return FMRES_HANDLED
}
public fwPlayerPostThink(id) {
	if (g_fix_punchangle[id]) {
		g_fix_punchangle[id] = false
		set_pev(id, pev_punchangle, Float:{0.0, 0.0, 0.0})
		return FMRES_HANDLED
	}

	return FMRES_IGNORED
}
public fwTraceLine(const Float:start[3], const Float:dest[3], ignore_monsters, id, ptr) {
	if (!(1 <= id <= g_MaxPlayers))
		return FMRES_IGNORED

	if (!g_normal_trace[id]) {
		g_normal_trace[id] = ptr
		return FMRES_HANDLED
	}
	if (ptr == g_normal_trace[id] || ignore_monsters != DONT_IGNORE_MONSTERS || !haswhpnnmg[id] || !has_minigun[id] || !is_alive[id])
		return FMRES_IGNORED

	fix_recoil_trace(id, start, ptr)

	return FMRES_SUPERCEDE
}
public ammo_hud(id) {
	if(!delayhud[id]) {
		delayhud[id] = true
		set_hudmessage(200, 100, 0, 1.0 , 1.0, 0, 0.1, 0.1,0.1)
		show_hudmessage(id,"Amunicja: %i",clipp[id])
		set_task(0.2,"delayhutmsg",id)
	}
}

public delayhutmsg(id){
	delayhud[id]= false
}

stock get_weapon_ent(id,wpnid=0,wpnName[]="")
{
	static newName[24];

	if(wpnid) get_weaponname(wpnid,newName,23);

	else formatex(newName,23,"%s",wpnName);

	if(!equal(newName,"weapon_",7))
		format(newName,23,"weapon_%s",newName);

	return fm_find_ent_by_owner(get_maxplayers(),newName,id);
} 

fix_recoil_trace(id, const Float:start[], ptr) {
	static Float:dest[3]
	pev(id, pev_v_angle, dest)
	engfunc(EngFunc_MakeVectors, dest)
	global_get(glb_v_forward, dest)
	xs_vec_mul_scalar(dest, 9999.0, dest)
	xs_vec_add(start, dest, dest)
	engfunc(EngFunc_TraceLine, start, dest, DONT_IGNORE_MONSTERS, id, ptr)
}
stock fm_cs_get_user_team(id)
{
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}
