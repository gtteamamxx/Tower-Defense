#include <amxmodx>
#include <amxmisc>
#include <td>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "TD: Shop | Golden ammo for SNIPERS"
#define VERSION "1.0"
#define AUTHOR "tomcionek15 & grs4"

new iItem;

new g_PlayerAmmo[33];
new m_spriteTexture

public plugin_init() 
{
	new id = register_plugin(PLUGIN, VERSION, AUTHOR)
	
	iItem = td_shop_register_item("Golden ammo for SNIPERS", "You have 150 golden ammo for SNIPERS. You take with it 1.5x more damage", 200, 0, id)

	RegisterHam(Ham_TraceAttack, "info_target", "TraceAttack")
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttackW", 1)
}
public client_disconnected(id)
	g_PlayerAmmo[id] = 0
public td_shop_item_selected(id, itemid) {
	if(iItem == itemid) {
		set_task(0.3, "info", id)
		g_PlayerAmmo[id] += 150
	}
}
public info(id) {
	if(is_user_connected(id)) {
		if(!g_PlayerAmmo[id])
			client_print(id, print_chat, "[GOLDEN AMMO] Ready to shot!");

		if(g_PlayerAmmo[id])
			client_print(id, print_chat, "[GOLDEN AMMO] Now you have %d golden ammo only for SNIPERS (NOT AWP)!", g_PlayerAmmo[id]);

	}
}

public plugin_precache() 
	m_spriteTexture = precache_model( "sprites/lgtning.spr" )

public TraceAttackW(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageTaype)
{
	if( !is_user_alive(iAttacker) || !g_PlayerAmmo[iAttacker])
		return HAM_IGNORED;
	
	static weapon 
	weapon = get_user_weapon(iAttacker);
	
	if(weapon != CSW_SG550 && weapon != CSW_SCOUT  && weapon != CSW_G3SG1)
		return HAM_IGNORED;
	
	client_print(iAttacker, print_center, "Golden Ammo for SNIPERS: %d", g_PlayerAmmo[iAttacker])
	
	return HAM_IGNORED
}
public TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageTaype)
{
	if( !is_user_alive(iAttacker) || !g_PlayerAmmo[iAttacker])
		return HAM_IGNORED;
	
	static weapon 
	weapon = get_user_weapon(iAttacker);
	
	if(weapon != CSW_SG550 && weapon != CSW_SCOUT  && weapon != CSW_G3SG1)
		return HAM_IGNORED;
	if(iEnt == 0) 
		return HAM_IGNORED
	
	g_PlayerAmmo[iAttacker] --;

	new Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMENTPOINT)
	write_short(iAttacker | 0x1000)
	write_coord_f(flEnd[0]) 
	write_coord_f(flEnd[1]) 
	write_coord_f(flEnd[2]) 
	write_short(m_spriteTexture)
	write_byte(0) // framerate
	write_byte(0) // framerate
	write_byte(1) // life
	write_byte(10)  // width
	write_byte(0)   // noise
	write_byte(random_num(230,255))   // r, g, b
	write_byte(random_num(215, 255))   // r, g, b
	write_byte(0)   // r, g, b
	write_byte(128)	// brightness
	write_byte(10)		// speed
	message_end()
	
	client_print(iAttacker, print_center, "Golden Ammo for SNIPERS: %d", g_PlayerAmmo[iAttacker])
	if(td_is_monster(iEnt)) 
		SetHamParamFloat(3, flDamage*1.5);
	
	return HAM_HANDLED;
}
