#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <td>
#include <stripweapons>
#include <nvault_util>
#include <engine>
#include <colorchat>

#define PLUGIN "Tower Defense: Gun mod"
#define VERSION "1.0"
#define AUTHOR "GT Team"

#define PISTOL_WEAPONS_BIT  	(1<<CSW_GLOCK18|1<<CSW_USP|1<<CSW_DEAGLE|1<<CSW_P228|1<<CSW_FIVESEVEN|1<<CSW_ELITE)
#define SHOTGUN_WEAPONS_BIT   	(1<<CSW_M3|1<<CSW_XM1014)
#define SUBMACHINE_WEAPONS_BIT  (1<<CSW_TMP|1<<CSW_MAC10|1<<CSW_MP5NAVY|1<<CSW_UMP45|1<<CSW_P90)
#define RIFLE_WEAPONS_BIT    	(1<<CSW_FAMAS|1<<CSW_GALIL|1<<CSW_AK47|1<<CSW_M4A1|1<<CSW_SG552|1<<CSW_AUG)
#define SNIPERS_WEAPONS_BIT 	(1<<CSW_SCOUT|1<<CSW_AWP|1<<CSW_G3SG1|1<<CSW_SG550)
#define MACHINE_WEAPONS_BIT    	(1<<CSW_M249)
#define ALL_WEAPONS_BIT 		(PISTOL_WEAPONS_BIT|SHOTGUN_WEAPONS_BIT|SUBMACHINE_WEAPONS_BIT|RIFLE_WEAPONS_BIT|SNIPERS_WEAPONS_BIT|MACHINE_WEAPONS_BIT)

#define TASK_SHOW_INFO	999321
#define PLAYER_WEAPON_CHANGE_LIMIT 1

#define CONFIG_FILE "addons/amxmodx/configs/Tower Defense/td_gunmod.cfg"

#pragma semicolon 1

#define MAX_LEVEL 24 // All default weapons
#define MAX_WEAPONS_PER_LEVEL 3


new const g_MaxBpAmmo[CSW_P90 +1] = {-2, 52, 0, 90, 1, 32, 0, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30,
120, 200, 32, 90, 120, 90, 2, 35, 90, 90, 0, 100};

new g_ExpTable[] = {0, 86, 144, 360, 571, 820, 1100, 1506, 2411, 3600, 5035, 
    7192, 9500, 12350, 16001, 22000, 25000, 31412, 35915, 46103, 55000, 65000, 999999};

enum eCONFIG
{
	CFG_KILL_XP,
	CFG_DAMAGE_RATIO,
	CFG_DAMAGE_XP
}

new g_ConfigValues[_:eCONFIG];

new bool:g_isGameAvailable;

new g_LevelWeapons[MAX_LEVEL][MAX_WEAPONS_PER_LEVEL][33];
new g_PlayerLevel[33];
new g_PlayerSelectedWeapons[33][2][33]; //[0] secondary (pistols) ; [1] primary
new g_PlayerChangeWeaponLimit[33];
new g_PlayerTakedDamage[33];
new g_PlayerExp[33];

new g_LevelsNum;
new g_LevelWeaponsNum[MAX_LEVEL];

new g_HudStatusText;

public fillConfigValuesWithNullValues()
{
	for(new i; i < _:eCONFIG; i++)
		g_ConfigValues[i] = -1;
}

public plugin_end()
{
	SavePlayersConfig();
}

new g_SoundLevelUp[64 + 8];

public plugin_precache()
{
    fillConfigValuesWithNullValues();

    g_LevelsNum = loadWeaponLevels();

    g_isGameAvailable = g_LevelsNum > 0;

    new nVaultFile;

    if(g_isGameAvailable && (nVaultFile = nvault_open("TowerDefenseGunMod")) == INVALID_HANDLE)
            log_to_file("TDGUNMOD.txt", "DEBUG: Users config file data/vault/TowerDefenseGunMod.vault is not exist. This message can be showed when you run first time Tower Defense GunMod on your server.");

    nvault_close(nVaultFile);

    if(!g_isGameAvailable)
    {
        set_fail_state("Plugin has some problems [g_LevelsNum = %d]. Check and fix it please.", g_LevelsNum);
        return;
    }

    formatex(g_SoundLevelUp, charsmax(g_SoundLevelUp), "sound/%s", g_SoundLevelUp);
    if(file_exists(g_SoundLevelUp))
    {
        replace(g_SoundLevelUp, charsmax(g_SoundLevelUp), "sound/", "");
        precache_sound(g_SoundLevelUp);
    }
    else 
    {
        log_to_file("TDGUNMOD.txt", "DEBUG: Sound of levelup '%s' is not exist", g_SoundLevelUp);
    }
}

public plugin_natives()
{
	register_native("td_gunmod_get_player_level", "_getPlayerLeveL", 1);
	register_native("td_gunmod_get_player_exp", "_getUserExp", 1);
	register_native("td_gunmod_get_level_exp", "_getLevelExp", 1);
	register_native("td_gunmod_get_max_level", "_getMaxLevel", 1);
	register_native("td_gumod_set_player_exp", "_setUserExp", 1);
	register_native("td_gumod_add_player_exp", "_addUserExp", 1);
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /guns", "cmdWeaponMenu");
	register_clcmd("say /gunmod", "cmdWeaponMenu");
	register_clcmd("say /bron", "cmdWeaponMenu");
	register_clcmd("say /bronie", "cmdWeaponMenu");
	register_clcmd("say /w", "cmdWeaponMenu");
	register_clcmd("say /weap", "cmdWeaponMenu");
	register_clcmd("say /weapons", "cmdWeaponMenu");
	register_clcmd("say /weapon", "cmdWeaponMenu");
	register_clcmd("guns", "cmdWeaponMenu");

	register_clcmd("buy", "cmdOpenBuyMenu");
	register_clcmd("buyequip", "cmdOpenBuyMenu");
	
	RegisterHam(Ham_Spawn, "player", "playerSpawned", 1);
	register_event("CurWeapon", "eventCurWeapon", "be", "1=1");
	g_HudStatusText = get_user_msgid("StatusText");

	RegisterHam(Ham_Touch, "weaponbox", "HamTouchPre", 0);
	RegisterHam(Ham_Touch, "armoury_entity", "HamTouchPre", 0);
	BlockBuy();

	if(g_isGameAvailable)
	{
		removeMapBuyZoneEntities();
		set_task(2.5, "DisplayHud", TASK_SHOW_INFO, _, _, "b");
	}
}

public _setUserExp(id, exp)
	g_PlayerExp[id] = exp;

public _addUserExp(id ,exp)
	g_PlayerExp[id] += exp;
	
public removeMapBuyZoneEntities()
{
	new iEnt = find_ent_by_class(-1, "func_buyzone");

	while(is_valid_ent(iEnt))
	{
		remove_entity(iEnt);
		iEnt = find_ent_by_class(iEnt, "func_buyzone");
	}
}

public HamTouchPre(weapon, id)
{
	if(!is_valid_ent(weapon) || !is_user_alive(id))
		return HAM_IGNORED;
	
	if(entity_get_edict(weapon, EV_ENT_owner) == id)
		return HAM_IGNORED;
		
	return HAM_SUPERCEDE;
}

public DisplayHud(iTask)
{
	for(new id = 1; id < 33; id++)
	{
        if(!is_user_alive(id))
            continue;
            
        static iPlayerLevel, iPlayerExp, iExpToLevel;
        iPlayerLevel = g_PlayerLevel[id];
        iPlayerExp = g_PlayerExp[id];
        iExpToLevel = g_ExpTable[iPlayerLevel];
        
        if(iPlayerLevel == g_LevelsNum && iPlayerExp > iExpToLevel)
            iPlayerExp = iExpToLevel;
            
        static szText[128]	;
        formatex(szText, charsmax(szText),  "Gun level: %d / %d | Exp: %d / %d", iPlayerLevel, g_LevelsNum, iPlayerExp, iExpToLevel);	
        message_begin(MSG_ONE, g_HudStatusText, _, id);
        write_byte(0);
        write_string(szText);
        message_end();
	}
}

public td_on_game_end()
{
    SavePlayersConfig();

    remove_task(TASK_SHOW_INFO);
}	 

public eventCurWeapon(id)
{
	if(!is_user_alive(id))
		return;
	
	new weaponID= read_data(2);
	if(weaponID==CSW_C4 || weaponID==CSW_KNIFE || weaponID==CSW_HEGRENADE || weaponID==CSW_SMOKEGRENADE || weaponID==CSW_FLASHBANG)
		return;
	
	if(cs_get_user_bpammo(id, weaponID) != g_MaxBpAmmo[weaponID])
		cs_set_user_bpammo(id, weaponID, g_MaxBpAmmo[weaponID]);
	
	return;
}

public _getUserExp(id)
	return g_PlayerExp[id];
public _getMaxLevel()
	return g_LevelsNum;
public _getPlayerLeveL(id)
	return g_PlayerLevel[id];
public _getLevelExp(level)
	return g_ExpTable[level];

public td_on_monster_killed(ent, player)
{
    if(!g_isGameAvailable || !is_user_connected(player))
        return;

    g_PlayerExp[player] += g_ConfigValues[CFG_KILL_XP];

    checkIfUserEarnedNewLevel(player);
}

public td_on_damage_taken_to_monster(monsterEntity, playerId, Float:fDamage)
{
	if(!g_isGameAvailable || !is_user_alive(playerId))
		return;

	g_PlayerTakedDamage[playerId] += floatround(fDamage);
		
	if(g_PlayerTakedDamage[playerId] >= g_ConfigValues[CFG_DAMAGE_RATIO])
	{
		g_PlayerTakedDamage[playerId] -= g_ConfigValues[CFG_DAMAGE_RATIO];
		g_PlayerExp[playerId] += g_ConfigValues[CFG_DAMAGE_XP];

		checkIfUserEarnedNewLevel(playerId);
	}
}

public playerSpawned(id)
{
	if(!strlen(g_PlayerSelectedWeapons[id][0]) && !strlen(g_PlayerSelectedWeapons[id][1]))
		showWeaponMenu(id);

	set_task(0.5, "givePlayerWeapons", id + 516);
}

public td_on_wave_end(iEndedWave)
{
	if(g_isGameAvailable)
		resetLimitOfChangingWeaponsForPlayers();

	SavePlayersConfig();
}

public resetLimitOfChangingWeaponsForPlayers()
{
    for(new i = 1; i < 33; i++)
		g_PlayerChangeWeaponLimit[i] = PLAYER_WEAPON_CHANGE_LIMIT;
}
	
stock saveUserConfig(id, file = 0)
{
    if(file == INVALID_HANDLE)
    {
        set_fail_state("saveUserConfig, nVualt INVALID HANDLE %d %d", id, file);
        return;
    }

    if(g_PlayerExp[id] == 0)
        return; 
        
    new szKey[48];
    new szData[128];

    get_user_name(id, szKey, 32);

    formatex(szKey, charsmax(szKey), "%s-gunmod#", szKey);
    formatex(szData, charsmax(szData), "%d|%s|%s", g_PlayerExp[id], g_PlayerSelectedWeapons[id][0], g_PlayerSelectedWeapons[id][1]);

    nvault_set(file, szKey, szData);
}

public loadUserConfig(id)
{
	if(!g_isGameAvailable)
		return;
		
	new iFile;
	if((iFile = nvault_open("TowerDefenseGunMod")) == INVALID_HANDLE)
	{
		set_fail_state("loadUserLevel, nvualt INVALID HANDLE %d %d", id, iFile);
		return;
	}
	
	new szKey[48];
	new szData[128];

	get_user_name(id, szKey, 32);

	formatex(szKey, charsmax(szKey), "%s-gunmod#", szKey);

	if(nvault_get(iFile, szKey, szData, charsmax(szData)))
	{	
		new szTempInfo[3][33];
		explode(szData, '|', szTempInfo, 3, 32);
	
		g_PlayerExp[id] = str_to_num(szTempInfo[0]);
		copy(g_PlayerSelectedWeapons[id][0], 32, szTempInfo[1]);
		copy(g_PlayerSelectedWeapons[id][1], 32, szTempInfo[2]);
	}
	else
	{
		new weapons[MAX_WEAPONS_PER_LEVEL][33], num, weaponId;
		getLevelWeapons(1, weapons, num, ALL_WEAPONS_BIT, false);
		
		for(new i = 0 ; i < num ; i++)
		{
			if(!strlen(weapons[i]))
				continue;
			
			weaponId = get_weaponid(weapons[i]);

			if((1 << weaponId) & PISTOL_WEAPONS_BIT)
				copy(g_PlayerSelectedWeapons[id][0], 32, weapons[i]);
			else
				copy(g_PlayerSelectedWeapons[id][1], 32, weapons[i]);
		}
	}

	nvault_close(iFile);
	
	g_PlayerLevel[id] = getLevelByExp(g_PlayerExp[id]);
	g_PlayerChangeWeaponLimit[id] = PLAYER_WEAPON_CHANGE_LIMIT;

}

public BlockBuy()
{
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

public BlockWeapon(id) 
{
	client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Buy_This", 0);
	return PLUGIN_HANDLED;
}

public resetUserStats(id)
{
	g_PlayerLevel[id] = 1;
	g_PlayerExp[id] = 0;
	g_PlayerChangeWeaponLimit[id] = PLAYER_WEAPON_CHANGE_LIMIT;
	g_PlayerTakedDamage[id] = 0;
	
	for(new i; i < 2; i++)
		g_PlayerSelectedWeapons[id][i] = "";
}

public cmdWeaponMenu(id)
	showWeaponMenu(id);
	
public client_disconnected(id)
	resetUserStats(id);
	
public client_putinserver(id)
	loadUserConfig(id);

public SavePlayersConfig()
{
	new iFile = nvault_open("TowerDefenseGunMod");
	for(new i = 1 ; i < get_maxplayers(); i++)
		if(is_user_connected(i)) 
			saveUserConfig(i, iFile);
		
	nvault_close(iFile);
}

public cmdOpenBuyMenu(id) 
{
	if(!is_user_alive(id))	
		return PLUGIN_CONTINUE;
	
	static iMsgBuyMenu;
	
	if(!iMsgBuyMenu)	
		iMsgBuyMenu = get_user_msgid("BuyClose");
	
	message_begin(MSG_ONE, iMsgBuyMenu, _, id);
	message_end();
	
	showWeaponMenu(id);
	
	return PLUGIN_HANDLED;
}

	
public showWeaponMenu(id)
{
	if(!g_isGameAvailable)
		return;
	
	static szTitle[64];
	new iPlayerLevel = g_PlayerLevel[id];
	
	formatex(szTitle, 63, "Your level:\r %d^n\wExp:\r %d\w /\r %d", iPlayerLevel, g_PlayerExp[id], g_ExpTable[iPlayerLevel]);
	
	new menu = menu_create(szTitle, "showWeaponMenuH");
	new cb = menu_makecallback("showWeaponMenuCb");
	
	new loadedWeaponsType = getWeaponsLoaded();
	
	if(loadedWeaponsType & 1<<1)
		menu_additem(menu, "Pistols", "0");
	if(loadedWeaponsType & 1<<2)
		menu_additem(menu, "Shotguns", "1");
	if(loadedWeaponsType & 1<<3)
		menu_additem(menu, "SMGs", "2");
	if(loadedWeaponsType & 1<<4)
		menu_additem(menu, "Rifles", "3");
	if(loadedWeaponsType & 1<<5)
		menu_additem(menu, "Snipers", "4");
	if(loadedWeaponsType & 1<<6)
	{
		new iWeapLvl = getLevelOfWeapon("weapon_m249");
		
		if(iWeapLvl > iPlayerLevel)
			formatex(szTitle, 63, "M249\w [\y Unlock at\r %d\y level\w ]", iWeapLvl);
		else
			formatex(szTitle, 63, "M249\w [\r %d\y level\w ]", iWeapLvl);
		
		if(strcmp("weapon_m249", g_PlayerSelectedWeapons[id][1], true) == 0)
			add(szTitle, 63, " \w[\y SELECTED\w ]");
			
		menu_additem(menu, szTitle, "5", .callback = cb);
	}
	
	menu_display(id, menu);
}

public showWeaponMenuCb(id, menu, item)
{
	if(!is_user_alive(id))
		return ITEM_DISABLED;
	
	new ac, in[3], nm[3], iPlayerLevel;
	menu_item_getinfo(menu, item, ac, in, 2, nm, 2, iPlayerLevel);
	
	item = str_to_num(in);
	iPlayerLevel = g_PlayerLevel[id];
	
	if(item == 5 && iPlayerLevel < getLevelOfWeapon("weapon_m249")) //m249
		return ITEM_DISABLED;
	else if(item == 5 && strcmp("weapon_m249", g_PlayerSelectedWeapons[id][1]) == 0)
		return ITEM_DISABLED;
		
	return ITEM_ENABLED;
}

public showWeaponMenuH(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	
	new ac, in[3], nm[3], cb;
	menu_item_getinfo(menu, item, ac, in, 2, nm, 2, cb);
	
	item = str_to_num(in);
	
	if(item == 5 && !is_user_alive(id))
		return;
	
	switch(item)
	{
		case 0: showWeaponTypeMenu(id, PISTOL_WEAPONS_BIT);
		case 1: showWeaponTypeMenu(id, SHOTGUN_WEAPONS_BIT);
		case 2: showWeaponTypeMenu(id, SUBMACHINE_WEAPONS_BIT);
		case 3: showWeaponTypeMenu(id, RIFLE_WEAPONS_BIT);
		case 4: showWeaponTypeMenu(id, SNIPERS_WEAPONS_BIT);
		case 5:
		{
			if(g_PlayerChangeWeaponLimit[id] == 0)
				client_print(id, print_center, "You reached wave change weapon limit!");
			else
			{
				g_PlayerChangeWeaponLimit[id]--;
				givePlayerWeapon(id, "weapon_m249");
				g_PlayerSelectedWeapons[id][1] = "weapon_m249";
			}
		}
	}
	
	if(item == 5)
		showWeaponMenu(id);
}


public showWeaponTypeMenu(id, weaponType)
{
	static szTitle[64], szWeapons[33][33], szWeaponName[35];
	new iPlayerLevel = g_PlayerLevel[id], iWeaponLevel, len;
	
	formatex(szTitle, 63, "Your level:\r %d^n\wExp:\r %d\w /\r %d", iPlayerLevel, g_PlayerExp[id], g_ExpTable[iPlayerLevel]);
	
	new menu = menu_create(szTitle, "showWeaponTypeMenuH");
	new cb = menu_makecallback("showWeaponTypeMenuCb");
	
	getLevelWeapons(g_LevelsNum, szWeapons, len, weaponType);
	
	for(new i = 0 ; i < len; i++)
	{
		iWeaponLevel = getLevelOfWeapon(szWeapons[i]);
		getWeaponName(szWeapons[i], szWeaponName, 32);
				
		if(iWeaponLevel > iPlayerLevel)
			formatex(szTitle, 63, "%s\w [\y Unlock at\r %d\y level\w ]", szWeaponName, iWeaponLevel);
		else 
			formatex(szTitle, 63, "%s\w [\r %d\y level\w ]", szWeaponName, iWeaponLevel);
		
		
		for(new j = 0; j < 2; j++)
		{
			if(strcmp(szWeapons[i], g_PlayerSelectedWeapons[id][j], true) == 0)
			{
				add(szTitle, 63, " [\y SELECTED\w ]");
				break;
			}
		}
		
		format(szWeaponName, 34, "%d %s", i, szWeapons[i]);
		menu_additem(menu, szTitle, szWeaponName, _, cb);
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Back");
	menu_display(id, menu);
}

public showWeaponTypeMenuCb(id, menu, item)
{
	if(!is_user_alive(id))
		return ITEM_DISABLED;

	static ac, info[35], nm[3], cb, weapon[33];
	menu_item_getinfo(menu, item, ac, info, 32, nm, 2, cb);
	parse(info, nm, 2, weapon, 32);
	
	if(item == str_to_num(nm) && g_PlayerLevel[id] < getLevelOfWeapon(weapon))
		return ITEM_DISABLED;
	
	for(new i = 0; i < 2; i++)
		if(strcmp(weapon, g_PlayerSelectedWeapons[id][i], true) == 0)
			return ITEM_DISABLED;

	return ITEM_ENABLED;
}
	
public showWeaponTypeMenuH(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		showWeaponMenu(id);
		return;
	}
	else if(!is_user_alive(id))
	{
		menu_destroy(menu);
		return;
	}
	
	static ac, info[35], nm[3], cb, weapon[33];
	menu_item_getinfo(menu, item, ac, info, 32, nm, 2, cb);
	parse(info, nm, 2, weapon, 32);
	
	new bitWeapon = (1 << get_weaponid(weapon));
	
	if(g_PlayerChangeWeaponLimit[id] == 0)
		client_print(id, print_center, "You reached wave change weapon limit!");
	else
	{
		
		g_PlayerChangeWeaponLimit[id]--;
		givePlayerWeapon(id, weapon);
		
		if(bitWeapon & PISTOL_WEAPONS_BIT)
			g_PlayerSelectedWeapons[id][0] = weapon;
		else
			g_PlayerSelectedWeapons[id][1] = weapon;
	}
	
	showWeaponTypeMenu(id, bitWeapon & PISTOL_WEAPONS_BIT ? PISTOL_WEAPONS_BIT : 
		bitWeapon & SHOTGUN_WEAPONS_BIT ? SHOTGUN_WEAPONS_BIT : bitWeapon & SUBMACHINE_WEAPONS_BIT ?
		SUBMACHINE_WEAPONS_BIT : bitWeapon & RIFLE_WEAPONS_BIT ? RIFLE_WEAPONS_BIT :
		bitWeapon & SNIPERS_WEAPONS_BIT ? SNIPERS_WEAPONS_BIT : bitWeapon & MACHINE_WEAPONS_BIT ? MACHINE_WEAPONS_BIT :
		PISTOL_WEAPONS_BIT);
}

public getWeaponsLoaded()
{
	new sum = (1>>1), weaponId;
	
	for(new i = 0 ; i < MAX_LEVEL; i++)
	{
		for(new j = 0 ; j < MAX_WEAPONS_PER_LEVEL; j++)
		{
			if(!strlen(g_LevelWeapons[i][j]))
				continue;
			
			weaponId = get_weaponid(g_LevelWeapons[i][j]);

			if(~(sum & 1<<1) && ((1 << weaponId) & PISTOL_WEAPONS_BIT))
				sum |= 1<<1;
			else if(~(sum & 1<<2) && ((1 << weaponId) & SHOTGUN_WEAPONS_BIT))
				sum |= 1<<2;
			else if(~(sum & 1<<3) && ((1 << weaponId) & SUBMACHINE_WEAPONS_BIT))
				sum |= 1<<3;
			else if(~(sum & 1<<4) && ((1 << weaponId) & RIFLE_WEAPONS_BIT))
				sum |= 1<<4;
			else if(~(sum & 1<<5) && ((1 << weaponId) & SNIPERS_WEAPONS_BIT))
				sum |= 1<<5;
			else if(~(sum & 1<<6) && ((1 << weaponId) & MACHINE_WEAPONS_BIT))
				sum |= 1<<6;
		}
	}
	
	return sum;
}
public loadWeaponLevels()
{
    if(!file_exists(CONFIG_FILE))
    {
        log_to_file("TDGUNMOD.txt", "[TD: GUNMOD] Config file: %s does not exists. Plugin work stopped.", CONFIG_FILE);
        return 0;
    }

    log_to_file("TDGUNMOD.txt", "Starting reading config file.");

    new szLine[4][64], line_len, bool:isLoadingLevels, iLoadedLevel, iWeaponIndex, bool:isDifferentLevel;

    for(new i = 0; read_file(CONFIG_FILE, i, szLine[0], 63, line_len); i++)
    {
        if(line_len == 0)
            continue;
            
        trim(szLine[0]);
        
        if(!strlen(szLine[0]) || szLine[0][0] == ';')
            continue;
        
        szLine[1] = "";
        szLine[2] = "";
        szLine[3] = "";
        
        parse(szLine[0], szLine[1], 63, szLine[2], 63, szLine[3], 63);
                
        if(isLoadingLevels)
        {
            if(equali("[LEVEL_", szLine[0], 7))
            {
                if(iLoadedLevel != 0 && iWeaponIndex == 0)
                {
                    log_to_file("TDGUNMOD.txt", "[TD GUNMOD] Error durning loading levels. %s %d", szLine[0], iLoadedLevel);
                    return 0;
                }
                
                replace(szLine[0], 63, "[LEVEL_", "");
                replace(szLine[0], 63, "]", "");
                
                isDifferentLevel = iLoadedLevel + 1 != str_to_num(szLine[0]);
                iLoadedLevel = str_to_num(szLine[0]);
                
                if(isDifferentLevel)
                {
                    log_to_file("TDGUNMOD.txt", "[TD GUNMOD] Error durning loading levels. Loaded %d!", iLoadedLevel);
                    return 0;
                }
                    
                iWeaponIndex = 0;
                
                log_to_file("TDGUNMOD.txt", "[TD GUNMOD] Loading Level: %d", iLoadedLevel);
                continue;
            }
            if(iLoadedLevel != 0)
            {
                if(checkIfWeaponIsRegistered(szLine[0]))
                {
                    log_to_file("TDGUNMOD.txt", "[TD GUNMOD] Error durning loading weapon. '%s' [level: %d] is alerady in some level!", szLine[0], iLoadedLevel);
                    return 0;
                }
                else if(checkIfWeaponIsBad(szLine[0]))
                {
                    log_to_file("TDGUNMOD.txt", "[TD GUNMOD] Error durning loading weapon. '%s' [level: %d] is a bad weapon name!", szLine[0], iLoadedLevel);
                    return 0;
                }
                if(iWeaponIndex > MAX_WEAPONS_PER_LEVEL)
                {
                    log_to_file("TDGUNMOD.txt", "[TD GUNMOD] Error during loading weapon. iWeaponIndex[%d] is more than MAX_WEAPONS_PER_LEVEL[%d]", iWeaponIndex, MAX_WEAPONS_PER_LEVEL);
                    return 0;
                }

                copy(g_LevelWeapons[iLoadedLevel][iWeaponIndex], 32, szLine[0]);
                
                log_to_file("TDGUNMOD.txt", "[TD GUNMOD] Loaded weapon: %s", szLine[0]);
                
                iWeaponIndex++;
                g_LevelWeaponsNum[iLoadedLevel]++;
            }
        }
        else if(equali(szLine[0], "[LEVELS]"))
        {
            log_to_file("TDGUNMOD.txt", "Starting loading levels");
            
            isLoadingLevels = true;
            continue;
        }
        else
        {
            line_len = str_to_num(szLine[3]);
            
            if(equali(szLine[1], "KILL_XP"))
                g_ConfigValues[CFG_KILL_XP] = line_len;
            else if(equali(szLine[1], "DAMAGE_RATIO"))
                g_ConfigValues[CFG_DAMAGE_RATIO] = line_len;
            else if(equali(szLine[1], "DAMAGE_XP"))
                g_ConfigValues[CFG_DAMAGE_XP] = line_len;
            else if(equali(szLine[1], "LEVELUP_SOUND"))
            {
                remove_quotes(szLine[3]);
                copy(g_SoundLevelUp, 63, szLine[3]);
            }

            log_to_file("TDGUNMOD.txt", "%s = %s", szLine[1], szLine[3]);
        }
    }

    for(new i = 0; i < _:eCONFIG; i++)
    {
        if(g_ConfigValues[i] == -1)
        {
            log_to_file("TDGUNMOD.txt", "Some value has been not loaded properly. Check it and fix please. [%d = -1]", i);
            
            return 0;
        }
    }

    return iLoadedLevel;
}
	

public checkIfUserEarnedNewLevel(id)
{
	new level = getLevelByExp(g_PlayerExp[id]);
	
	if(level > g_PlayerLevel[id])
	{
		g_PlayerLevel[id] = level;
		

		new szName[33];
		get_user_name(id, szName, 32);
		ColorChat(0, GREEN, "^x01 Defender^x04 %s^x01 has just earned new weapon level [%d]!", szName, level);
		ColorChat(id, GREEN, "^x01 You has just earned new weapon level: %d!", level);
		client_cmd(id, "spk %s", g_SoundLevelUp);
		
		ColorChat(id, GREEN, "%s^x01 Also, you has just unlocked:");
		
		new weapons[MAX_WEAPONS_PER_LEVEL][33], len;
		
		getLevelWeapons(level, weapons, len, _, false);
		
		for(new i = 0; i < len; i++)
		{
			if(!strlen(weapons[i]))
				return;
		
			getWeaponName(weapons[i], szName, 32);
			
			ColorChat(id, GREEN, "^x01 %d. %s", i+1, szName);
		}
		
		showWeaponMenu(id);
	}
}

stock getWeaponName(wweapon[], weaponName[], len)
{
	new weapon[33];
	copy(weapon, 32, wweapon);
	
	replace(weapon, 32, "weapon_", "");
	new name[33];
	
	if(equali(weapon, "glock18")) name = "Glock 18";
	else if(equali(weapon, "usp")) name = "Usp";
	else if(equali(weapon, "p228")) name = "P228";
	else if(equali(weapon, "deagle")) name = "Deagle";
	else if(equali(weapon, "fiveseven")) name = "Fiveseven";
	else if(equali(weapon, "elite")) name = "Elite";
	else if(equali(weapon, "m3")) name = "M3";
	else if(equali(weapon, "xm1014")) name = "XM1014";
	else if(equali(weapon, "mac10")) name = "Mac 10";
	else if(equali(weapon, "tmp")) name = "Tmp";
	else if(equali(weapon, "mp5navy")) name = "Mp5";
	else if(equali(weapon, "ump45")) name = "Ump 45";
	else if(equali(weapon, "p90")) name = "P90";
	else if(equali(weapon, "famas")) name = "Famas";
	else if(equali(weapon, "aug")) name = "AUG";
	else if(equali(weapon, "galil")) name = "Galil";
	else if(equali(weapon, "scout")) name = "Scout";
	else if(equali(weapon, "awp")) name = "AWP";
	else if(equali(weapon, "m4a1")) name = "M4A1";
	else if(equali(weapon, "ak47")) name = "Ak-47";
	else if(equali(weapon, "sg550")) name = "SG 550";
	else if(equali(weapon, "sg552")) name = "SG 552";
	else if(equali(weapon, "g3sg1")) name = "G3SG1";
	else if(equali(weapon, "m249")) name = "M249";
	else name = "bad";
	
	copy(weaponName, len, name);
}

stock checkIfUserCanHoldWeapon(id, const weapon[])
{
	new level = g_PlayerLevel[id];
	
	for(new i = 0; i < level; i++)
		for(new j = 0; j < MAX_WEAPONS_PER_LEVEL; j++)
			if(equali(weapon, g_LevelWeapons[i][j]))
				return true;
	
	return false;
}

stock getLevelWeapons(iLevel, weapons[][33], &len, weapType = ALL_WEAPONS_BIT, bool:weaponsToLevel = true)
{	
	new weaponId;

	for(new i = weaponsToLevel == false ? iLevel : 1; i <= iLevel; i+=weaponsToLevel==false?100:1)
	{
		for(new j = 0; j < MAX_WEAPONS_PER_LEVEL; j++)
		{
			if(!strlen(g_LevelWeapons[i][j]))
				continue;
			weaponId = get_weaponid(g_LevelWeapons[i][j]);
			
			if((1<<weaponId) & weapType)
				copy(weapons[len++], 32, g_LevelWeapons[i][j]);
		}
	}
}

stock getLevelOfWeapon(const weapon[])
{
	for(new i = 0; i < MAX_LEVEL; i++)
		for(new j = 0; j < MAX_WEAPONS_PER_LEVEL; j++)
			if(equali(g_LevelWeapons[i][j], weapon))
				return i;
	return -1;
}

stock bool:checkIfWeaponIsBad(weapon[])
{
	new weaponName[33];
	getWeaponName(weapon, weaponName, 32);
	
	return strcmp(weaponName, "bad", true) == 0;
}

stock bool:checkIfWeaponIsRegistered(const weapon[])
{
	for(new i = 0; i < MAX_LEVEL; i++)
		for(new j = 0; j < MAX_WEAPONS_PER_LEVEL; j++)
			if(equali(g_LevelWeapons[i][j], weapon))
				return true;
	return false;
}

stock getLevelByExp(exp)
{
	new level = 1;
	while(exp >= g_ExpTable[level])
		level++;
	return level;
}

public givePlayerWeapons(id)
{
	id-=516;
	
	if(!is_user_alive(id))
		return;
		
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
	
	givePlayerWeapon(id, g_PlayerSelectedWeapons[id][0]);
	givePlayerWeapon(id, g_PlayerSelectedWeapons[id][1]);
}

stock explode(const string[],const character,output[][],const maxs,const maxlen)
{
	new iDo = 0,
	len = strlen(string),
	oLen = 0;

	do { 
		oLen += (1+copyc(output[iDo++],maxlen,string[oLen],character)) ;
	}
	while(oLen < len && iDo < maxs);
}

stock givePlayerWeapon(id, const weaponName[])
{
	if(!strlen(weaponName))
		return;
		
	new weaponId = get_weaponid(weaponName);
	
	new weapons[32], num;
	get_user_weapons(id, weapons, num);
	
	for(new i = 0; i < num; i++)
		if(weapons[i] == weaponId)
			return;
	
	if((1<<weaponId) & PISTOL_WEAPONS_BIT)
		ham_strip_user_weapon(id, get_weaponid(g_PlayerSelectedWeapons[id][0]), Secondary);
	else
		ham_strip_user_weapon(id, get_weaponid(g_PlayerSelectedWeapons[id][1]), Primary);
		
	give_item(id, weaponName);
	cs_set_user_bpammo(id, weaponId, g_MaxBpAmmo[weaponId]);
}  