#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <td>

#define ID_BURN (taskid - 1000)
#define DAMAGE 12.5

#define type pev_iuser1

new g_ModelV[] = "models/TD/v_burngrenade.mdl"
new g_ModelP[] = "models/TD/p_burngrenade.mdl"
new g_ModelW[] = "models/TD/w_burngrenade.mdl"

new g_SoundsGrenadeFire[] = "weapons/hegrenade-1.wav"
new g_SoundsBuyAmmo[] = "items/9mmclip1.wav"

new g_SpriteFireSource[] = "sprites/flame.spr"
new g_SpriteTrailSource[] = "sprites/laserbeam.spr"
new g_SpriteRingSource[] = "sprites/shockwave.spr"

new g_SpriteFlame
new g_SpriteSmoke
new g_SpriteTrail
new g_SpriteExplode

new g_duration, Float:g_radius

new const szName[] = "Granat podpalajacy"
new const szDesc[]  = "Granat podpalajacy, czas trwania: 10 sekund"
new iPrice = 30;
new iOnePerMap = 0;

new iItem;

public plugin_precache(){
	engfunc(EngFunc_PrecacheSound, g_SoundsGrenadeFire)
	engfunc(EngFunc_PrecacheSound, g_SoundsBuyAmmo)

	g_SpriteFlame = engfunc(EngFunc_PrecacheModel, g_SpriteFireSource)
	g_SpriteTrail = engfunc(EngFunc_PrecacheModel, g_SpriteTrailSource)
	g_SpriteExplode = engfunc(EngFunc_PrecacheModel, g_SpriteRingSource)
	
	engfunc(EngFunc_PrecacheModel, g_ModelV)
	engfunc(EngFunc_PrecacheModel, g_ModelP)
	engfunc(EngFunc_PrecacheModel, g_ModelW)
}

public plugin_init(){
	new id = register_plugin("TD: SHOP| Napaln Nade", "1.0", "MeRcyLeZZ & edited by GT Team for TD")
	
	iItem = td_shop_register_item(szName, szDesc, iPrice, iOnePerMap, id)

	register_forward(FM_SetModel, "fw_SetModel")
	
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Touch, "info_target", "fw_TouchMonster")
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "fw_Item_Deploy_Post", 1)
}

public plugin_cfg()
	set_task(0.5, "loadConfig")


public loadConfig(){
	/* czas trwania oparzeñ */
	g_duration = 10

	/* zasiêg */
	g_radius = 305.0
}

public fw_SetModel(entity, const model[]){
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime == 0.0)
		return FMRES_IGNORED;
	
	if (!equal(model[7], "w_he", 4))
		return FMRES_IGNORED;
	
	static owner, napalm_weaponent
	owner = pev(entity, pev_owner)
	napalm_weaponent = fm_get_user_current_weapon_ent(owner)
	
	if (pev(napalm_weaponent, pev_flTimeStepSound) != 681856)
		return FMRES_IGNORED;
	fm_set_rendering(entity, kRenderFxGlowShell, 255, 50, 0, kRenderNormal, 16)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) 
	write_short(entity) 
	write_short(g_SpriteTrail) 
	write_byte(10) 
	write_byte(10) 
	write_byte(255) 
	write_byte(50) 
	write_byte(0) 
	write_byte(200)
	message_end()
	
	static napalm_ammo
	napalm_ammo = pev(napalm_weaponent, pev_flSwimTime)
	set_pev(napalm_weaponent, pev_flSwimTime, --napalm_ammo)
	set_pev(entity, type, 1)
	if (napalm_ammo < 1)
		set_pev(napalm_weaponent, pev_flTimeStepSound, 0)
	set_pev(entity, pev_flTimeStepSound, 681856)
	
	engfunc(EngFunc_SetModel, entity, g_ModelW)
	return FMRES_SUPERCEDE;
}

public fw_ThinkGrenade(entity){
	if (!pev_valid(entity)) 
		return HAM_IGNORED;
	if(pev(entity, type) != 1)
		return HAM_IGNORED
		
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	
	if (dmgtime > get_gametime())
		return HAM_IGNORED;
	
	if (pev(entity, pev_flTimeStepSound) != 681856)
		return HAM_IGNORED;

	napalm_explode(entity)

	engfunc(EngFunc_RemoveEntity, entity)
	return HAM_SUPERCEDE;
}

public fw_TouchMonster(self, other){
	if (!td_is_monster(other))
		return;
	
	if (!task_exists(self+1000) || task_exists(other+1000))
		return;
	
	static params[2]
	params[0] = g_duration * 2 
	params[1] = self	

	set_task(0.1, "burning_flame", other+1000, params, sizeof params)
}

public fw_Item_Deploy_Post(entity){
	if (pev(entity, pev_flTimeStepSound) != 681856)
		return;
	
	static weaponid
	weaponid = fm_get_weapon_ent_id(entity)
	
	if (weaponid != CSW_HEGRENADE)
		return;
	
	static owner
	owner = fm_get_weapon_ent_owner(entity)
	
	set_pev(owner, pev_viewmodel2, g_ModelV)
	set_pev(owner, pev_weaponmodel2, g_ModelP)
}

public td_shop_item_selected(id, itemid)
{
	if(iItem == itemid)
	{
		static napalm_weaponent
		napalm_weaponent = fm_get_napalm_entity(id)
	
		if (napalm_weaponent != 0){
			static napalm_ammo
			napalm_ammo = pev(napalm_weaponent, pev_flSwimTime)
		
			set_pev(napalm_weaponent, pev_flSwimTime, ++napalm_ammo)
			
			set_pdata_int(id, 388, get_pdata_int(id, 388) + 1, 5)
			
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoPickup"), _, id)
			write_byte(12)
			write_byte(1) 
			message_end()
			set_pev(napalm_weaponent, type, 1)
			engfunc(EngFunc_EmitSound, id, CHAN_ITEM, g_SoundsBuyAmmo, 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_pev(napalm_weaponent, pev_flTimeStepSound, 681856)
			
		}
		else {
			fm_give_item(id, "weapon_hegrenade")
			napalm_weaponent = fm_get_napalm_entity(id)
			set_pev(napalm_weaponent, type, 1)
			set_pev(napalm_weaponent, pev_flTimeStepSound, 681856)
			set_pev(napalm_weaponent, pev_flSwimTime, 1)
		}
	}
}

napalm_explode(ent){
	static attacker;
	attacker = pev(ent, pev_owner)
	
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	create_blast2(originF)
	
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, g_SoundsGrenadeFire, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	static victim
	victim = 0
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, g_radius)) != 0){
		if (!td_is_monster(victim))
			continue;
		
		static params[2]
		params[0] = g_duration * 5 
		params[1] = attacker
		
		set_task(0.1, "burning_flame", victim+1000, params, sizeof params)
	}
}

public burning_flame(args[2], taskid){
	if (!td_is_monster(ID_BURN) || pev(ID_BURN, pev_health) <= 0)
		return;
	
	static Float:originF[3]
	pev(ID_BURN, pev_origin, originF)
	
	if (args[0] < 1){
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_SMOKE)
		engfunc(EngFunc_WriteCoord, originF[0])
		engfunc(EngFunc_WriteCoord, originF[1])
		engfunc(EngFunc_WriteCoord, originF[2]-50.0)
		write_short(g_SpriteSmoke)
		write_byte(random_num(15, 20))
		write_byte(random_num(10, 20))
		message_end()
		
		return
	}
	
	new Float:iDamage = DAMAGE
	if(pev(ID_BURN, pev_health) - 5.0 < 0)
		iDamage = float(pev(ID_BURN, pev_health))

	ExecuteHamB(Ham_TakeDamage, ID_BURN, args[1], args[1], iDamage, DMG_BURN, 1);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, originF[0]+random_float(-5.0, 5.0))
	engfunc(EngFunc_WriteCoord, originF[1]+random_float(-5.0, 5.0))
	engfunc(EngFunc_WriteCoord, originF[2]+random_float(-10.0, 10.0))
	write_short(g_SpriteFlame)
	write_byte(random_num(5, 10))
	write_byte(200)
	message_end()
	
	args[0] -= 1;

	set_task(0.2, "burning_flame", taskid, args, sizeof args)
}

create_blast2(const Float:originF[3]){
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_SpriteExplode) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(100) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_SpriteExplode) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(50) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_SpriteExplode) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16){
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

stock fm_give_item(id, const item[]){
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item));
	if (!pev_valid(ent)) return;
	
	static Float:originF[3]
	pev(id, pev_origin, originF);
	set_pev(ent, pev_origin, originF);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);
	
	static save
	save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, id);
	if (pev(ent, pev_solid) != save)
		return;
	
	engfunc(EngFunc_RemoveEntity, ent);
}

stock fm_find_ent_by_owner(entity, const classname[], owner){
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) {}
	return entity;
}

stock fm_get_napalm_entity(id)
	return fm_find_ent_by_owner(-1, "weapon_hegrenade", id);

stock fm_get_user_current_weapon_ent(id)
	return get_pdata_cbase(id, 373, 5);

stock fm_get_weapon_ent_id(ent)
	return get_pdata_int(ent, 43, 4);

stock fm_get_weapon_ent_owner(ent)
	return get_pdata_cbase(ent, 41, 4);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
