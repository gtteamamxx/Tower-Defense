/* Jest to plugin w g³ównej mierze stworozny po to by móc dodaæ do menu w³asne bronie oraz
	zmieniæ ich ceny nie u¿yhwaj¹c modu³u Orpheu.
	
   Podziêkowania dla nie-RGB u¿ytkowników amxx.pl [z wyj¹tkiem Gwyna]
*/
#include <amxmodx>
#include <td>
#include <cstrike>
#include <fakemeta_util>
#include <fun>
#include <colorchat>
#include <engine>
#include <hamsandwich>

#define PLUGIN "Tower Defense: Guns"
#define VERSION "1.0"
#define AUTHOR "GT Team"

#define TASK_BUY_GUN	6242


/* ======================================== */

new gszPrefix[33];

new const giMaxAmmo[31] = {0,52,0,90,1,32,1,100,90,1,120,100,100,90,90,90,100,120,30,120,200,32,90,120,90,2,35,90,90,0,100};

/* ======================================== */

#define m_rgpPlayerItems_Slot1        368
#define m_rgpPlayerItems_Slot2        369 
#define XTRA_OFS_PLAYER                5 

/* ======================================== */

#define cs_get_user_hasprim(%1) ( get_pdata_cbase(%1,m_rgpPlayerItems_Slot1,XTRA_OFS_PLAYER) > 0 )
#define cs_get_user_hassec(%1) ( get_pdata_cbase(%1,m_rgpPlayerItems_Slot2,XTRA_OFS_PLAYER) > 0 )

/* ======================================== */

// Nazwy scriptingowe broni g³ównych
new const gszPrimaryWeapons[][] = {
	"weapon_scout",
	"weapon_xm1014",
	"weapon_mac10",
	"weapon_aug",
	"weapon_ump45",
	"weapon_sg550",
	"weapon_galil",
	"weapon_famas",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_p90"
}
// -||- broni podrzêdnych

new const gszSecondaryWeapons[][] = {
	"weapon_p228",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_usp",
	"weapon_glock18",
	"weapon_deagle"
}

/* Jeœli nie chceszm mieæ danej broni w mneu to usuñ wszystkie jej pozycje przed plugin_init. */

/* ======================================== */

enum e_GunsType {
	GUNS_PISTOLS,
	GUNS_SHOTGUNS,
	GUNS_SMG,
	GUNS_RIFLES,
	GUNS_SNIPERS
}
enum e_PistolsType {
	PISTOL_GLOCK,
	PISTOL_USP,
	PISTOL_P228,
	PISTOL_DEAGLE,
	PISTOL_ELITE,
	PISTOL_FIVESEVEN
}
enum e_ShotgunType {
	SHOTGUN_M3,
	SHOTGUN_XM1014
}
enum e_SmgType {
	SMG_TMP,
	SMG_MAC,
	SMG_MP5,
	SMG_UMP,
	SMG_P90
}
enum e_RifleType {
	RIFLE_FAMAS,
	RIFLE_GALIL,
	RIFLE_AK47,
	RIFLE_M4A1,
	RIFLE_SG552,
	RIFLE_AUG
}
enum e_SniperType {
	SNIPER_SCOUT,
	SNIPER_AWP
}

/* ======================================== */

new gszGunsType[e_GunsType][] = {
	"Pistolety",
	"Shotguny",
	"SMG",
	"Karabiny",
	"Snajperki"
}
/* Pistols */
new gszPistolsNames[e_PistolsType][] = {
	"Glock 18",
	"USP",
	"P228",
	"Deagle",
	"Elite",
	"Fiveseven"
}
new gszPistolsIndex[e_PistolsType][] = {
	"weapon_glock18",
	"weapon_usp",
	"weapon_p228",
	"weapon_deagle",
	"weapon_elite",
	"weapon_fiveseven"
}

new giPistolsPrice[e_PistolsType]  = {
	250,
	400,
	750,
	1000,
	1250,
	800
}
/* ======================================== */

/* Shotgun */

/* ======================================== */

new gszShotgunNames[e_ShotgunType][] = {
	"M3",
	"XM1014"
}
new gszShotgunIndex[e_ShotgunType][] = {
	"weapon_m3",
	"weapon_xm1014"
}

new giShotgunPrice[e_ShotgunType]  = {
	4500,
	5500
}

/* ======================================== */

/* SMG */

/* ======================================== */

new gszSmgNames[e_SmgType][] = {
	"TMP",
	"Uzi",
	"MP5",
	"Ump 45",
	"P90"
}
new gszSmgIndex[e_SmgType][] = {
	"weapon_tmp",
	"weapon_mac10",
	"weapon_mp5navy",
	"weapon_ump45",
	"weapon_p90"
}

new giSmgPrice[e_SmgType]  = {
	1500,
	1600,
	2000,
	2350,
	2750
}

/* ======================================== */

/* Rifle */

/* ======================================== */

new gszRifleNames[e_RifleType][] = {
	"Famas",
	"Galil",
	"AK47",
	"M4A1",
	"Krieg",
	"AUG"
}
new gszRifleIndex[e_RifleType][] = {
	"weapon_famas",
	"weapon_galil",
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_sg552",
	"weapon_aug"
}

new giRiflePrice[e_RifleType]  = {
	3000,
	3500,
	4500,
	4500,
	5000,
	5000
}

/* ======================================== */

/* Snipers */

/* ======================================== */

new gszSniperNames[e_SniperType][] = {
	"Scout",
	"AWP"
}
new gszSniperIndex[e_SniperType][] = {
	"weapon_scout",
	"weapon_awp"
}

new giSniperPrice[e_SniperType]  = {
	3000,
	10000
}

/* ======================================== */

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /guns", "cmdmenuGuns")
	register_clcmd("say /bronie", "cmdmenuGuns")
	register_clcmd("say /gun", "cmdmenuGuns")
	register_clcmd("say /buy", "cmdmenuGuns")
	register_clcmd("say /bron", "cmdmenuGuns")
	
	register_clcmd("buy", "cmdmenuGuns")
	register_clcmd("buyequip", "cmdmenuGuns")
	
	register_clcmd("buyammo1", "cmdBuyAmmo2")
	register_clcmd("buyammo2", "cmdBuyAmmo1")
	
	BlockBuy()
	
	register_clcmd("client_buy_open","cmdOpenBuyMenu")
	
	td_get_prefix(gszPrefix, 32)
	
	register_forward(FM_ClientUserInfoChanged, "fwClientUserInfoChanged", 1)
}

/* Pokaz wiadomosc */
public block(id){

	client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Buy_This",0);

	return PLUGIN_HANDLED;

}
/* zablolkuj komendy kupywania broni */
public BlockBuy(){
	register_clcmd("cl_setautobuy","BlockWeapon");
	register_clcmd("cl_autobuy","BlockWeapon");
	register_clcmd("cl_setrebuy","BlockWeapon");
	register_clcmd("cl_rebuy","BlockWeapon");
	register_clcmd("p228","BlockWeapon");
	register_clcmd("228compact","BlockWeapon");
	register_clcmd("shield","BlockWeapon");
	register_clcmd("scout","BlockWeapon");
	register_clcmd("hegren","BlockWeapon");               
	register_clcmd("xm1014","BlockWeapon");
	register_clcmd("autoshotgun","BlockWeapon");                   
	register_clcmd("mac10","BlockWeapon");                
	register_clcmd("aug","BlockWeapon");
	register_clcmd("bullpup","BlockWeapon");
	register_clcmd("sgren","BlockWeapon");   
	register_clcmd("elites","BlockWeapon");     
	register_clcmd("fn57","BlockWeapon");
	register_clcmd("fiveseven","BlockWeapon");  
	register_clcmd("ump45","BlockWeapon");                
	register_clcmd("sg550","BlockWeapon");
	register_clcmd("krieg550","BlockWeapon");   
	register_clcmd("galil","BlockWeapon");
	register_clcmd("defender","BlockWeapon");  
	register_clcmd("famas","BlockWeapon");
	register_clcmd("clarion","BlockWeapon");   
	register_clcmd("usp","BlockWeapon");
	register_clcmd("km45","BlockWeapon");       
	register_clcmd("glock","BlockWeapon");
	register_clcmd("9x19mm","BlockWeapon");     
	register_clcmd("awp","BlockWeapon");
	register_clcmd("magnum","BlockWeapon");     
	register_clcmd("mp5","BlockWeapon");
	register_clcmd("smg","BlockWeapon");       
	register_clcmd("m249","BlockWeapon");                 
	register_clcmd("m3","BlockWeapon");
	register_clcmd("12gauge","BlockWeapon");   
	register_clcmd("m4a1","BlockWeapon");                 
	register_clcmd("tmp","BlockWeapon");
	register_clcmd("mp","BlockWeapon");         
	register_clcmd("g3sg1","BlockWeapon");
	register_clcmd("d3au1","BlockWeapon");    
	register_clcmd("flash","BlockWeapon");                
	register_clcmd("deagle","BlockWeapon");
	register_clcmd("nighthawk","BlockWeapon"); 
	register_clcmd("sg552","BlockWeapon");
	register_clcmd("krieg552","BlockWeapon");   
	register_clcmd("ak47","BlockWeapon");
	register_clcmd("cv47","BlockWeapon");                        
	register_clcmd("p90","BlockWeapon");
	register_clcmd("c90","BlockWeapon");
	register_clcmd("vest","BlockWeapon");
	register_clcmd("vesthelm","BlockWeapon");
	register_clcmd("nvgs","BlockWeapon");
}

public BlockWeapon(id) {
	client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Buy_This",0);
	return PLUGIN_HANDLED;
}

// PODZIEKOWANIA DLA BLACK_PERFUM Z AMXX>pl
/* Zablokuj menu motd a pokaz menu normalne */
public cmdOpenBuyMenu(id) {
	if(!is_user_alive(id))	
		return PLUGIN_CONTINUE
	
	static iMsgBuyMenu
	
	if(!iMsgBuyMenu)	
		iMsgBuyMenu = get_user_msgid("BuyClose")
	
	message_begin(MSG_ONE, iMsgBuyMenu, _, id)
	message_end()
	
	cmdmenuGuns(id)
	
	return PLUGIN_HANDLED
}

/* ======================================== */
/* Amunicja do broni podrzêdnej */
public cmdBuyAmmo1(id) {
	if(!userHasSecondary(id))
		return PLUGIN_HANDLED_MAIN
	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED_MAIN
	
	new entlist[1]
	if(!find_sphere_class(id, "func_buyzone", 4.0, entlist, 1)) 
		return PLUGIN_HANDLED_MAIN
	
	
	set_user_ammo(id,get_pdata_cbase(id,369,5),50)
	
	return PLUGIN_HANDLED_MAIN
}

/* ======================================== */
/* Amunicja do broni pierwszorzêdnej */
public cmdBuyAmmo2(id) {
	if(!userHasPrimary(id))
		return PLUGIN_HANDLED_MAIN
	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED_MAIN
	
	new entlist[1]
	if(!find_sphere_class(id, "func_buyzone", 4.0, entlist, 1)) 
		return PLUGIN_HANDLED_MAIN

	set_user_ammo(id,get_pdata_cbase(id,368,5), 120)
	
	return PLUGIN_HANDLED_MAIN
}


// PODZIEKOWANIA DLA BLACK_PERFUM Z AMXX>pl
public set_user_ammo(id, iWeaponIndex,iPrice) {
	
	if(!is_valid_ent(iWeaponIndex))	
		return
	
	new iAmmoType = get_pdata_int(iWeaponIndex,49,4)
	new iWeaponID = get_pdata_int(iWeaponIndex,43,4)
	new iAmmo = get_pdata_int(id,376 + iAmmoType,5)
	new iMoney = get_pdata_int(id,115,5)
	
	if(iWeaponID == CSW_KNIFE)
		return 
	if(iMoney < iPrice || iMoney == 0) {
		fm_set_user_money(id, iMoney, 1)
		return
	}
	if(iAmmo >= giMaxAmmo[iWeaponID])
		return

	iAmmo = iAmmo + 12 > giMaxAmmo[iWeaponID] ? giMaxAmmo[iWeaponID] : iAmmo+12
	
	set_pdata_int(id,376 + iAmmoType, iAmmo,5)
	
	fm_set_user_money(id,iMoney - iPrice)
	
	set_pdata_int(id,351,0,5)
	
	client_cmd(id, "spk weapons/reload1")
}

/* ======================================== */

public cmdmenuGuns(id) {
	if(!is_user_alive(id)) {
		ColorChat(id, GREEN, "%s^x01 Nie mozesz kupic broni, gdy nie zyjesz!", gszPrefix)
		return PLUGIN_CONTINUE
	}
	new szTitle[64], szItem[33]
	
	formatex(szTitle, charsmax(szTitle), "\wMasz \r$%d\w^nWybierz typ broni:", cs_get_user_money(id))
	
	new menu = menu_create(szTitle, "cmdmenuGunsH")
	
	for(new i ; i <_: e_GunsType ; i++) {
		formatex(szItem, charsmax(szItem), gszGunsType[e_GunsType:i])
		menu_additem(menu, szItem)
	}
	menu_additem(menu, "Amunicja")
	menu_display(id, menu)
	return PLUGIN_HANDLED_MAIN
}
public cmdmenuGunsH(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id)) {
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	
	new e_GunsType: iOption = e_GunsType:item
	
	if(iOption == GUNS_PISTOLS) {
		menuPistols(id)
		} else  if(iOption == GUNS_SHOTGUNS) {
		menuShotguns(id)
		} else if(iOption == GUNS_SMG) {
		menuSmg(id)
		} else if(iOption == GUNS_RIFLES) {
		menuRifles(id)
		} else if(iOption == GUNS_SNIPERS) {
		menuSnipers(id)
		} else if(iOption == GUNS_SNIPERS+e_GunsType:1) {
		menuAmmo(id)
	}
	return PLUGIN_CONTINUE
}

/* ======================================== */

public menuAmmo(id)
{	
	new menu = menu_create("Jaka amunicje chcesz kupic?", "menuAmmoH")
	new cb = menu_makecallback("menuAmmoCb");
	
	menu_additem(menu, "$300         \yDo pistoletow", _, _, cb)
	menu_additem(menu, "$500         \yDo karabinow", _, _, cb)
	menu_additem(menu, "$800         \yDo wszystkiego", _, _, cb)
	menu_display(id, menu)
}
public menuAmmoCb(id,menu,item)
{
	new iMoney = cs_get_user_money(id)
	if((item == 0 && iMoney < 300) || (item == 1 && iMoney < 500) || (item == 2 && iMoney < 800) || (item == 0 && !userHasSecondary(id)) || (item == 1 && !userHasPrimary(id)) || ((item == 2 && !userHasSecondary(id)) || (item == 2 && !userHasPrimary(id))))
		return ITEM_DISABLED
	return ITEM_ENABLED
}

public menuAmmoH(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id))
	{
		menu_destroy(menu)
		if(is_user_alive(id))
			cmdmenuGuns(id)
		return
	}
	
	if(item == 0) {
		fm_set_user_money(id, cs_get_user_money(id) - 300)
		
		for(new i = 0; i < sizeof gszSecondaryWeapons; i++) {	
			new weapon = get_weaponid(gszSecondaryWeapons[i])
			
			if(user_has_weapon(id, weapon)) {
				cs_set_user_bpammo(id, weapon, giMaxAmmo[weapon])
				break;
			}
		}
	}
	if(item == 1) {
		fm_set_user_money(id, cs_get_user_money(id) - 500)
		
		for(new i = 0; i < sizeof gszPrimaryWeapons; i++) {	
			new weapon = get_weaponid(gszPrimaryWeapons[i])
			
			if(user_has_weapon(id, weapon)) {
				cs_set_user_bpammo(id, weapon, giMaxAmmo[weapon])
				break;
			}
		}
	}
	if(item == 2) {
		fm_set_user_money(id, cs_get_user_money(id) - 800)
		new weapon
		for(new i = 0; i < sizeof gszSecondaryWeapons; i++) {	
			weapon = get_weaponid(gszSecondaryWeapons[i])
			
			if(user_has_weapon(id, weapon)) {
				cs_set_user_bpammo(id, weapon, giMaxAmmo[weapon])
				break;
			}
		}
		for(new i = 0; i < sizeof gszPrimaryWeapons; i++) {	
			weapon = get_weaponid(gszPrimaryWeapons[i])
			
			if(user_has_weapon(id, weapon)) {
				cs_set_user_bpammo(id, weapon, giMaxAmmo[weapon])
				break;
			}
		}
	}
	menuAmmo(id)
	client_cmd(id, "spk weapons/reload1")
}

/* ======================================== */

public menuPistols(id) {
	new szTitle[64], szItem[33]
	
	formatex(szTitle, charsmax(szTitle), "\wMasz \r$%d\w^nWybierz pistolet:", cs_get_user_money(id))
	
	new menu = menu_create(szTitle, "menuPistolsH")
	new cb = menu_makecallback("menuPistolsCb");
	
	for(new i ; i < _:e_PistolsType; i++) {
		formatex(szItem, charsmax(szItem),"$%-10.3d %-2s",  giPistolsPrice[ e_PistolsType:i], gszPistolsNames[e_PistolsType:i])
		menu_additem(menu, szItem, _, _, cb)
	}
	menu_display(id, menu)
}

public menuPistolsCb(id, menu, item) {
	
	if( cs_get_user_money(id) < giPistolsPrice[ e_PistolsType:item]) {
		return ITEM_DISABLED
	}
	return ITEM_ENABLED
}

public menuPistolsH(id, menu, item) {
	if(item == MENU_EXIT || !is_user_alive(id)) {
		menu_destroy(menu)
		if(is_user_alive(id))
			cmdmenuGuns(id)
		
		return  PLUGIN_CONTINUE;	
	}
	
	if(userHasSecondary(id)) {
		cmdDropWeapons(id, 0)
		
	}
	
	new szData[3]
	szData[0] = _:GUNS_PISTOLS
	szData[1] =  item
	
	set_task(0.1, "cmdBuyWeaponPost", id + TASK_BUY_GUN, szData, 2)
	
	return PLUGIN_CONTINUE ;
}

/* ======================================== */

// =============SHOTGUNS

/* ======================================== */

public menuShotguns(id) {
	new szTitle[64], szItem[33]
	
	formatex(szTitle, charsmax(szTitle), "\wMasz \r$%d\w^nWybierz shotgun:", cs_get_user_money(id))
	
	new menu = menu_create(szTitle, "menuShotgunsH")
	new cb = menu_makecallback("menuShotgunsCb");
	
	for(new i ; i < _:e_ShotgunType; i++) {
		formatex(szItem, charsmax(szItem),"$%-10.3d %-2s",  giShotgunPrice[ e_ShotgunType:i], gszShotgunNames[e_ShotgunType:i])
		menu_additem(menu, szItem, _, _, cb)
	}
	menu_display(id, menu)
}

public menuShotgunsCb(id, menu, item) {
	
	if( cs_get_user_money(id) < giShotgunPrice[ e_ShotgunType:item]) {
		return ITEM_DISABLED
	}
	return ITEM_ENABLED
}

public menuShotgunsH(id, menu, item) {
	if(item == MENU_EXIT || !is_user_alive(id)) {
		menu_destroy(menu)
		
		if(is_user_alive(id))
			cmdmenuGuns(id)
		return  PLUGIN_CONTINUE;	
	}
	
	if(userHasPrimary(id)) {
		cmdDropWeapons(id, 1)
	}
	
	new szData[3]
	szData[0] = _:GUNS_SHOTGUNS
	szData[1] =  item
	
	set_task(0.1, "cmdBuyWeaponPost", id + TASK_BUY_GUN, szData, 2)
	return PLUGIN_CONTINUE ;
}

/* ======================================== */

// ===========SMG

/* ======================================== */

public menuSmg(id) {
	new szTitle[64], szItem[33]
	
	formatex(szTitle, charsmax(szTitle), "\wMasz \r$%d\w^nWybierz SMG:", cs_get_user_money(id))
	
	new menu = menu_create(szTitle, "menuSmgH")
	new cb = menu_makecallback("menuSmgCb");
	
	for(new i ; i < _:e_SmgType; i++) {
		formatex(szItem, charsmax(szItem),"$%-10.3d %-2s",  giSmgPrice[ e_SmgType:i], gszSmgNames[e_SmgType:i])
		menu_additem(menu, szItem, _, _, cb)
	}
	menu_display(id, menu)
}

public menuSmgCb(id, menu, item) {
	
	if( cs_get_user_money(id) < giSmgPrice[ e_SmgType:item]) {
		return ITEM_DISABLED
	}
	return ITEM_ENABLED
}

public menuSmgH(id, menu, item) {
	if(item == MENU_EXIT || !is_user_alive(id)) {
		menu_destroy(menu)
		if(is_user_alive(id))
			cmdmenuGuns(id)
		
		return  PLUGIN_CONTINUE;	
	}
	
	if(userHasPrimary(id)) {
		cmdDropWeapons(id, 1)
	}
	
	new szData[3]
	szData[0] = _:GUNS_SMG
	szData[1] =  item
	
	set_task(0.1, "cmdBuyWeaponPost", id + TASK_BUY_GUN, szData, 2)
	
	return PLUGIN_CONTINUE ;
}

/* ======================================== */

// =============RIFLE

/* ======================================== */

public menuRifles(id) {
	new szTitle[64], szItem[33]
	
	formatex(szTitle, charsmax(szTitle), "\wMasz \r$%d\w^nWybierz karabin:", cs_get_user_money(id))
	
	new menu = menu_create(szTitle, "menuRiflesH")
	new cb = menu_makecallback("menuRiflesCb");
	
	for(new i ; i < _:e_RifleType; i++) {
		formatex(szItem, charsmax(szItem),"$%-10.3d %-2s",  giRiflePrice[ e_RifleType:i], gszRifleNames[e_RifleType:i])
		menu_additem(menu, szItem, _, _, cb)
	}
	menu_display(id, menu)
}

public menuRiflesCb(id, menu, item) {
	
	if( cs_get_user_money(id) < giRiflePrice[ e_RifleType:item]) {
		return ITEM_DISABLED
	}
	return ITEM_ENABLED
}

public menuRiflesH(id, menu, item) {
	if(item == MENU_EXIT || !is_user_alive(id)) {
		menu_destroy(menu)
		if(is_user_alive(id))
			cmdmenuGuns(id)
		
		return  PLUGIN_CONTINUE;	
	}
	
	if(userHasPrimary(id)) {
		cmdDropWeapons(id, 1)
	}
	
	new szData[3]
	szData[0] = _:GUNS_RIFLES
	szData[1] =  item
	
	set_task(0.1, "cmdBuyWeaponPost", id + TASK_BUY_GUN, szData, 2)
	
	return PLUGIN_CONTINUE ;
}

/* ======================================== */

// ========SNIPER

/* ======================================== */

public menuSnipers(id) {
	new szTitle[64], szItem[33]
	
	formatex(szTitle, charsmax(szTitle), "\wMasz \r$%d\w^nWybierz snajperke:", cs_get_user_money(id))
	
	new menu = menu_create(szTitle, "menuSnipersH")
	new cb = menu_makecallback("menuSnipersCb");
	
	for(new i ; i < _:e_SniperType; i++) {
		formatex(szItem, charsmax(szItem),"$%-10.3d %-2s",  giSniperPrice[ e_SniperType:i], gszSniperNames[e_SniperType:i])
		menu_additem(menu, szItem, _, _, cb)
	}
	menu_display(id, menu)
}

public menuSnipersCb(id, menu, item) {
	
	if( cs_get_user_money(id) < giSniperPrice[ e_SniperType:item]) {
		return ITEM_DISABLED
	}
	return ITEM_ENABLED
}

public menuSnipersH(id, menu, item) {
	if(item == MENU_EXIT || !is_user_alive(id)) {
		menu_destroy(menu)
		if(is_user_alive(id))
			cmdmenuGuns(id)
		
		return  PLUGIN_CONTINUE;	
	}
	
	if(userHasPrimary(id)) {	
		cmdDropWeapons(id, 1)
	}
	
	
	new szData[3]
	szData[0] = _:GUNS_SNIPERS
	szData[1] =  item
	
	set_task(0.1, "cmdBuyWeaponPost", id + TASK_BUY_GUN, szData, 2)
	
	return PLUGIN_CONTINUE ;
}

/* ======================================== */

public cmdBuyWeaponPost(szData[], id) {
	id  -= TASK_BUY_GUN
	remove_task(id+TASK_BUY_GUN)
	
	cmdBuyWeapon(id, e_GunsType:szData[0], szData[1])
	
	new e_GunsType: iOption = e_GunsType:szData[0]
	
	if(iOption == GUNS_PISTOLS)
		menuPistols(id)
	else  if(iOption == GUNS_SHOTGUNS)
		menuShotguns(id)
	else if(iOption == GUNS_SMG)
		menuSmg(id)
	else if(iOption == GUNS_RIFLES)
		menuRifles(id)
	else if(iOption == GUNS_SNIPERS)
		menuSnipers(id)

}

/* ======================================== */

cmdSwitchWeapon(id, e_GunsType:iWeaponType, iWeaponIndex) {
	if(iWeaponType == GUNS_PISTOLS)
		client_cmd(id, gszPistolsIndex[e_PistolsType:iWeaponIndex])
	if(iWeaponType == GUNS_SHOTGUNS)
		client_cmd(id, gszShotgunIndex[e_ShotgunType:iWeaponIndex])
	if(iWeaponType == GUNS_SMG)
		client_cmd(id, gszSmgIndex[e_SmgType:iWeaponIndex])
	if(iWeaponType == GUNS_RIFLES)
		client_cmd(id, gszRifleIndex[e_RifleType:iWeaponIndex])
	if(iWeaponType == GUNS_SNIPERS)
		client_cmd(id, gszSniperIndex[e_SniperType:iWeaponIndex])
	
}

/* ======================================== */

cmdBuyWeapon(id, e_GunsType:iWeaponType, iWeaponIndex) 
{
	if(iWeaponType == GUNS_PISTOLS) {
		new e_PistolsType:iWeapon = e_PistolsType:iWeaponIndex
		
		ColorChat(id, GREEN, "%s^x01 Kupiles^x04 '%s'^x01 za ^x03$%d^x01 !", gszPrefix, gszPistolsNames[iWeapon], giPistolsPrice[iWeapon])
		
		fm_give_item(id, gszPistolsIndex[iWeapon])
		
		fm_set_user_money(id, cs_get_user_money(id) - giPistolsPrice[iWeapon])
		
	} 
	else if(iWeaponType == GUNS_SHOTGUNS) {
		new e_ShotgunType:iWeapon = e_ShotgunType:iWeaponIndex
		
		ColorChat(id, GREEN, "%s^x01 Kupiles^x04 '%s'^x01 za ^x03$%d^x01 !", gszPrefix, gszShotgunNames[iWeapon], giShotgunPrice[iWeapon])
		
		fm_give_item(id, gszShotgunIndex[iWeapon])
		
		fm_set_user_money(id, cs_get_user_money(id) - giShotgunPrice[iWeapon])
	}
	else if(iWeaponType == GUNS_SMG){
		new e_SmgType:iWeapon = e_SmgType:iWeaponIndex
		
		ColorChat(id, GREEN, "%s^x01 Kupiles^x04 '%s'^x01 za ^x03$%d^x01 !", gszPrefix, gszSmgNames[iWeapon], giSmgPrice[iWeapon])
		
		fm_give_item(id, gszSmgIndex[iWeapon])
		
		fm_set_user_money(id, cs_get_user_money(id) - giSmgPrice[iWeapon])
	}
	else if(iWeaponType == GUNS_RIFLES){
		new e_RifleType:iWeapon = e_RifleType:iWeaponIndex
		
		ColorChat(id, GREEN, "%s^x01 Kupiles^x04 '%s'^x01 za ^x03$%d^x01 !", gszPrefix, gszRifleNames[iWeapon], giRiflePrice[iWeapon])
		
		fm_give_item(id, gszRifleIndex[iWeapon])
		
		fm_set_user_money(id, cs_get_user_money(id) - giRiflePrice[iWeapon])
	}
	else if(iWeaponType == GUNS_SNIPERS) {
		new e_SniperType:iWeapon = e_SniperType:iWeaponIndex
		
		ColorChat(id, GREEN, "%s^x01 Kupiles^x04 '%s'^x01 za ^x03$%d^x01 !", gszPrefix, gszSniperNames[iWeapon], giSniperPrice[iWeapon])
		
		fm_give_item(id, gszSniperIndex[iWeapon])
		
		fm_set_user_money(id, cs_get_user_money(id) - giSniperPrice[iWeapon])
	}
	cmdSwitchWeapon(id, iWeaponType,iWeaponIndex)
	
	set_task(0.1, "cmdGiveAmmo", id + TASK_BUY_GUN)
}

/* ======================================== */

cmdDropWeapons(id, iPrimary = 1) 
{
	if(iPrimary == 1) {
		for(new i = 0; i < sizeof gszPrimaryWeapons; i++) {
			client_cmd(id, "drop %s", gszPrimaryWeapons[i])
		}
	} else if(iPrimary == 0) {
		for(new j = 0; j < sizeof gszSecondaryWeapons; j++) {
			client_cmd(id, "drop %s", gszSecondaryWeapons[j])
		}
	}
}

/* ======================================== */

public cmdGiveAmmo(id) {
	id-=TASK_BUY_GUN
	new iWeapon = get_user_weapon(id)
	
	if(iWeapon != 29)
		cs_set_user_bpammo(id,iWeapon, giMaxAmmo[iWeapon])
}

/* ======================================== */

userHasSecondary(id)
	return cs_get_user_hassec(id)

userHasPrimary(id)
	return cs_get_user_hasprim(id)

/* ======================================== */

fm_set_user_money( id, Money, effect = 1)
{
	static s_msgMoney
	if(!s_msgMoney) 
		s_msgMoney = get_user_msgid("Money")
	
	set_pdata_int( id, 115, Money )
	
	emessage_begin( MSG_ONE, s_msgMoney, _, id )
	ewrite_long( Money )
	ewrite_byte(effect )
	emessage_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
