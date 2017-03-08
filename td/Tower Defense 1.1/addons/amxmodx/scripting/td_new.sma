#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta_util>
#include <cstrike>
#include <hamsandwich>
#include <fun>
#include <td_const>
#include <colorchat>
// test
#pragma dynamic 32768 

#define PLUGIN "TD: New"
#define VERSION "0.5"
#define AUTHOR "GT Team"

#define DEBUG

#define MAX_WAVE 50
#define MAX_LEVEL 8
#define MAX_CLASS 14
#define MAX_MONSTERS 40
#define MAX_SHOP_ITEMS 30

#define EV_INT_monster_type		EV_INT_iuser1
#define EV_INT_monster_track		EV_INT_iuser2
#define EV_INT_monster_maxhealth	EV_INT_iuser3
#define EV_INT_monster_speed		EV_INT_iuser4
#define EV_ENT_monster_healthbar	EV_ENT_euser1
#define EV_ENT_monster_headshot		EV_ENT_euser2

//native td_show_turrets_menu(index)

/* =================== */

new gszWaveConfigDir[] 	= "addons/amxmodx/configs/Tower Defense";
new gszCvarConfigFile[] = "addons/amxmodx/configs/td_cvars.cfg";
new gszModelsConfigFile[] = "addons/amxmodx/configs/td_models.ini";
new gszSoundConfigFile[] = "addons/amxmodx/configs/td_sounds.cfg";
new gszShopConfigFile[] = "addons/amxmodx/configs/td_shop.cfg";
new gszClassConfigFile[] = "addons/amxmodx/configs/td_player_class.cfg";

/* =================== */

new gszPrefix[]	= "[TD]"

/* =================== */

new gszLogFile[] = "Tower Defense.log"
new gszLangFile[] = "TowerDefense.txt"	// zmieniaj1c ten plik, zmien te? nazwe w td_turrets

/* =================== */

new MAX_MAP_TURRETS

/* =================== */

enum groups ( <<= 1 )
{
    GROUP_NONE,
    GROUP_TERRORISTS = 1,
    GROUP_CT
}

new const giLevelFrags[MAX_LEVEL] = {
	8,
	14,
	27,
	39, 
	45, 
	60, 
	75,
	9999
}

new const giMaxAmmo[31] = {0,52,0,90,1,32,1,100,90,1,120,100,100,90,90,90,100,120,30,120,200,32,90,120,90,2,35,90,90,0,100};

/* Tower Defense: Shop */

new giShopItemsName[MAX_SHOP_ITEMS+1][33];
new giShopItemsDesc[MAX_SHOP_ITEMS+1][128];
new giShopItemsPrice[MAX_SHOP_ITEMS+1];

new giShopOnePerMap[MAX_SHOP_ITEMS+1];
new giShopPlayerBuy[33][MAX_SHOP_ITEMS+1];

new giShopItemsNum;
new gszPrefixShop[] = "[TD: SHOP]";

/* =================== */

new gStatusText;

/* =================== */

enum e_Forwards {
	FORWARD_STARTWAVE,
	FORWARD_ENDWAVE,
	FORWARD_MONSTER_KILLED,
	FORWARD_RESET_GAME,
	FORWARD_ITEM_SELECTED,
	FORWARD_RESET_PLAYER_INFO,
	FORWARD_TAKE_DAMAGE,
	FORWARD_COUNTDOWN_STARTED,
	FORWARD_CLASS_SELECTED,
	FORWARD_CLASS_DISABLED
}
enum e_Models {
	MODEL_NORMAL,
	MODEL_FAST,
	MODEL_STRENGHT,
	MODEL_BOSS,
	MODEL_BONUS,
	MODEL_TOWER,
}
enum e_Cvar {
	CVAR_BASE_HEALTH,
	CVAR_TIME_TO_WAVE,
	CVAR_MONSTER_DAMAGE,
	CVAR_BOSS_DAMAGE,
	CVAR_KILL_GOLD,
	CVAR_KILL_MONEY,
	CVAR_KILL_BONUS_GOLD,
	CVAR_KILL_BOSS_GOLD,
	CVAR_KILL_BONUS_FRAGS,
	CVAR_KILL_BOSS_FRAGS,
	CVAR_KILL_BP_AMMO,
	CVAR_BLOCK_CMD_KILL,
	CVAR_KILL_MONSTER_FX,
	CVAR_ONE_PLAYER_MODE,
	CVAR_WAVE_GOLD,
	CVAR_WAVE_MONEY,
	CVAR_COUNTDOWN_MODE,
	CVAR_RESPAWN_PLAYER_CMD,
	CVAR_SEND_MONSTER_TIME,
	CVAR_SWAP_MONEY,
	CVAR_SWAP_MONEY_MONEY,
	CVAR_SWAP_MONEY_GOLD,
	CVAR_DAMAGE_RATIO,
	CVAR_DAMAGE_GOLD,
	CVAR_DAMAGE_MONEY,
	CVAR_SHOW_LEFT_DAMAGE,
	CVAR_PLAYER_JOIN_EXTRA,
	CVAR_PLAYER_JOIN_EXTRA_MIN_WAVE,
	CVAR_PLAYER_JOIN_EXTRA_GOLD,
	CVAR_PLAYER_JOIN_EXTRA_MONEY,
	CVAR_BLOCK_HE,
	CVAR_BLOCK_FB,
	CVAR_BLOCK_SG
}
enum e_CvarValue {
	BASE_HEALTH,
	TIME_TO_WAVE,
	MONSTER_DAMAGE,
	BOSS_DAMAGE,
	KILL_GOLD,
	KILL_MONEY,
	KILL_BONUS_GOLD,
	KILL_BOSS_GOLD,
	KILL_BONUS_FRAGS,
	KILL_BOSS_FRAGS,
	KILL_BP_AMMO,
	BLOCK_CMD_KILL,
	KILL_MONSTER_FX,
	ONE_PLAYER_MODE,
	WAVE_GOLD,
	WAVE_MONEY,
	COUNTDOWN_MODE,
	RESPAWN_PLAYER_CMD,
	Float:SEND_MONSTER_TIME,
	SWAP_MONEY,
	SWAP_MONEY_MONEY,
	SWAP_MONEY_GOLD,
	DAMAGE_RATIO,
	DAMAGE_GOLD,
	DAMAGE_MONEY,
	SHOW_LEFT_DAMAGE,
	PLAYER_JOIN_EXTRA,
	PLAYER_JOIN_EXTRA_MIN_WAVE,
	PLAYER_JOIN_EXTRA_GOLD,
	PLAYER_JOIN_EXTRA_MONEY,
	BLOCK_HE,
	BLOCK_FB,
	BLOCK_SG
}

enum  {
	TASK_COUNTDOWN = 334,
	TASK_COUNTDOWN_FUNCTION = 711,
	TASK_SEND_MONSTER = 404,
	TASK_PLAYER_SPAWN = 437,
	TASK_MONSTER_DEATH = 487,
	TASK_PLAYER_HUD = 521,
	TASK_START_WAVE = 555,
	TASK_DAMAGE_EFFECT = 594,
	TASK_KILL_MONSTER = 644,
	TASK_GAME_FALSE = 790,
	TASK_PRE_SEND_MONSTER = 818
}

enum e_Sync {
	SYNC_WAVE_INFO,
	SYNC_DAMAGE,
	SYNC_END_GAME,
}

enum e_Sound {
	SOUND_START_WAVE,
	SOUND_COIN,
	SOUND_ACTIVATED,
	SOUND_COUNTDOWN,
	SOUND_MONSTER_DIE_1,
	SOUND_MONSTER_DIE_2,
	SOUND_MONSTER_DIE_3,
	SOUND_MONSTER_DIE_4,
	SOUND_MONSTER_HIT_1,
	SOUND_MONSTER_HIT_2,
	SOUND_MONSTER_HIT_3,
	SOUND_MONSTER_HIT_4,
	SOUND_MONSTER_1,
	SOUND_MONSTER_2,
	SOUND_MONSTER_3,
	SOUND_MONSTER_4,
	SOUND_MONSTER_GROWL_1,
	SOUND_MONSTER_GROWL_2,
	SOUND_MONSTER_GROWL_3,
	SOUND_MONSTER_GROWL_4,
	SOUND_BOSS_DIE,
	SOUND_BONUS_DIE,
	SOUND_PLAYER_LEVELUP,
	SOUND_PLAYER_USE_LIGHTING,
	SOUND_CLEAR_WAVE
}

enum _:eHudSize {
	HUD_SMALL,
	HUD_NORMAL, 
	HUD_BIG
}

new gszRoundName[e_RoundType][33];

new gszSkills[MAX_LEVEL-1][64] = {
	"Zadajesz 6 obrazen wiecej.",
	"Jestes 10% szybszy.",
	"Otrzymujesz za kazde zabicie 1-no zloto wiecej",
	"Dostajesz o $150 wiecej za zabicie potwora",
	"Jestes 25% szybszy",
	"Zadajesz 16 obrazen wiecej",
	"Mozesz atakowac piorunem potwora co 30s klawiszem 'X'"
}

new gForward[e_Forwards]
new gWaveInfo[MAX_WAVE][e_WaveInfo]

new gCvarInfo[e_Cvar]
new gCvarValue[e_CvarValue]

new g_VipModel[33];
new gModels[4][e_Models][33]
new gSounds[e_Sound][128]

new gSyncInfo[e_Sync]
new gPlayerInfo[33][e_Player]

new bool:gGame = true;
new bool:gOnePlayerMode = false;
new bool:gWaveIsStarted = false
new bool:gGameIsStarted = false
new bool:gCanWalk = false
new bool:gTurretsAvailable = false
new bool:gModelTurret = false
new bool:gPlayersAreReady = false
//new bool:gCountdownStarted = false

//new bool:gGameIsPaused = false


new Float:gfStartOrigin[3];
new Float:gfEndOrigin[3];
new Float:gfTowerOrigin[3]

new Float:gfPlayerHudPosition[33][2]
new Float:gfPlayerHealthbarScale[33];
new Float:gfPlayerLightingTime[33];
new Float:gfPlayerAmmobarScale[33]

new giPlayerHudSize[33]
new giPlayerHudColor[33][3]
new giPlayerHealthbar[33];
new giPlayerAlarmValue[33];
new giPlayerSwapMoneyMsg[33];
new giPlayerSwapAutobuy[33];
new giPlayerDamage[33]

/* Players class */
new giPlayerClass[33];
new giPlayerChangedClass[33];

new gszClassName[MAX_CLASS][33];
new gszClassDescription[MAX_CLASS][128]
new giClassNum

new giWaveNum;
new giWave;

new giMaxPlayers; 
new giBaseHealth;

new giMonsterAlive;
new giSendsMonster;

new giSpriteBloodDrop
new giSpriteBloodSpray;
new giSpriteExplode
new giSpriteSpawn[] = "sprites/TD/spawn.spr"
new giSpriteLighting

/* from Tower Defense: Turrets */

//native Float:td_set_ammobar_scale(index, Float:fScale)
//native td_set_alarm_value(index, iValue);

/* **** */

public plugin_natives()
{
	/*register_native("td_is_special_wave", "is_special_wave", 1)
	register_native("td_is_special_monster", "is_special_monster", 1)
	register_native("td_is_healthbar", "td_is_healthbar", 1)
	register_native("td_is_monster", "td_is_monster", 1)
	
	register_native("td_get_wave", "_td_get_wave", 1)
	register_native("td_set_wave", "_td_set_wave", 1)
	register_native("td_get_wavenum", "_td_get_wavenum", 1)
	
	register_native("td_get_wave_info", "_td_get_wave_info", 1)
	register_native("td_set_wave_info", "_td_set_wave_info", 1)
	
	register_native("td_get_max_level", "_td_get_max_level", 1)
	register_native("td_get_max_monsters", "_td_get_max_monsters", 1)
	register_native("td_get_max_wave", "_td_get_max_wave", 1)
	
	register_native("td_get_monster_type", "_td_get_monster_type", 1)
	register_native("td_get_monster_health", "_td_get_monster_health", 1)
	register_native("td_get_monster_healthbar", "_td_get_monster_healthbar", 1)
	
	register_native("td_remove_tower", "_td_remove_tower", 1)
	register_native("td_remove_monsters", "_td_remove_monsters", 1)
		
	register_native("td_get_start_origin", "_td_get_start_origin")
	register_native("td_get_end_origin", "_td_get_end_origin")
	
	register_native("td_get_round_name", "_td_get_round_name", 1)
	register_native("td_kill_monster", "MonsterKilled", 1)
	
	
	
	
	

	register_native("td_get_prefix", "_td_get_prefix", 1);
	
	register_native("td_set_tower_health", "_td_set_tower_health", 1);
	register_native("td_get_tower_health", "_td_get_tower_health", 1);
	register_native("td_get_max_tower_health", "_td_get_max_tower_health", 1);
	
	register_native("td_get_end_status", "_td_get_end_status", 1);
	
	register_native("td_get_monster_speed", "_get_monster_speed", 1)
	register_native("td_set_monster_speed", "_set_monster_speed", 1)
	//register_native("td_get_vip_model", "_get_vip_model", 1);*/
	
	//register_native("td_shop_register_item", "_td_shop_register_item", 1);
	//register_native("td_register_class", "_td_register_class", 1);
	//register_native("td_get_max_map_turrets", "_td_get_max_map_turrets", 1)
	
	
	register_native("td_get_game_status", "_td_get_game_status", 1)
	register_native("td_set_game_status", "_td_set_game_status", 1)
	
	register_native("td_get_user_info", "_td_get_user_info", 1)
	register_native("td_set_user_info", "_td_set_user_info", 1)
	
}

public plugin_precache() {
	
#if defined DEBUG

	log_to_file(gszLogFile, "		DEBUG MODE ON")
	log_to_file(gszLogFile, "DEBUG: Chechking a validating configuration files...")

#endif
	
	/* Load models */
	LoadModels();

	/* Load sounds */
	LoadSound();
	
	/* Checking a shop config file */
	CheckShopConfig();

	/* Checking a player class file */

	//Blood
	giSpriteBloodDrop = precache_model("sprites/blood.spr")
	giSpriteBloodSpray = precache_model("sprites/bloodspray.spr")
	
	//Lighting
	giSpriteLighting = precache_model("sprites/lgtning.spr")
	
	//Explode
	giSpriteExplode = precache_model("sprites/TD/zerogxplode.spr")
	
	
	precache_model(giSpriteSpawn);
	
	//Sounds
	for(new i; i < _:e_Sound ; i++) {
		precache_sound(gSounds[e_Sound:i]);
	}

	
	//Potwory
	new szModelDir[] = "models/TD"
	new szModel[64]
	
	for(new i ; i < _:e_Models ; i++) {
		for(new j ; j < 4; j++) {

			//if(i == _:MODEL_PLAYER_CT || i == _:MODEL_PLAYER_TT) {
			//	formatex(szModel, charsmax(szModel),"models/player/%s/%s.mdl", gModels[j][e_Models:i], gModels[j][e_Models:i])
			//	log_amx(szModel)
			//}
			//else
			formatex(szModel, charsmax(szModel),"%s/%s.mdl", szModelDir, gModels[j][e_Models:i])

			precache_model(szModel);
		}
	}
	log_amx("asd")
}
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(gszLangFile)
	
	gForward[FORWARD_STARTWAVE] 		= CreateMultiForward("td_startwave", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	gForward[FORWARD_ENDWAVE] 		= CreateMultiForward("td_endwave", ET_CONTINUE, FP_CELL)
	gForward[FORWARD_MONSTER_KILLED] 	= CreateMultiForward("td_monster_killed", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	gForward[FORWARD_RESET_GAME] 		= CreateMultiForward("td_reset_game", ET_CONTINUE, FP_CELL, FP_FLOAT)
	gForward[FORWARD_ITEM_SELECTED]		= CreateMultiForward("td_shop_item_selected", ET_CONTINUE, FP_CELL, FP_CELL);
	gForward[FORWARD_CLASS_SELECTED]	= CreateMultiForward("td_class_selected", ET_CONTINUE, FP_CELL, FP_CELL);
	gForward[FORWARD_CLASS_DISABLED]	= CreateMultiForward("td_class_disabled", ET_CONTINUE, FP_CELL, FP_CELL);
	gForward[FORWARD_RESET_PLAYER_INFO] 	= CreateMultiForward("td_reset_player_info", ET_CONTINUE, FP_CELL);
	gForward[FORWARD_TAKE_DAMAGE]		= CreateMultiForward("td_take_damage", ET_CONTINUE, FP_CELL, FP_CELL,  FP_CELL, FP_FLOAT, FP_ARRAY);
	gForward[FORWARD_COUNTDOWN_STARTED]  = CreateMultiForward("td_countdown_started", ET_CONTINUE, FP_CELL)
	log_amx("asd 1")
	register_event("HLTV", "HLTV", "a", "1=0", "2=0")
	register_event("Money", "eventMoney","be")
	register_event("CurWeapon","eventCurWeapon","be") 

	register_logevent("LogEventNewRound", 2, "1=Round_Start")
	
	/* Monster */
	
	RegisterHam(Ham_TakeDamage, "info_target", "TakeDamage")// przed zadaniem obr.
	RegisterHam(Ham_TakeDamage, "info_target", "TakeDamagePost", 1)// po zadaniu
	RegisterHam(Ham_Killed, "info_target", "MonsterKilled")
	RegisterHam(Ham_Touch, "info_target", "touchMonsterTrack", 1)
	
	register_forward(FM_AddToFullPack, "fwAddToFullPack", 1)
	
	/* Player */
	
	RegisterHam(Ham_AddPlayerItem, "player", "C4Remove")
	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "PlayerSpeed", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamagePlayer")
	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1) //po odrodzeniu

	register_think("monster", "thinkMonsterThink")
	
	register_forward(FM_ClientKill, "PlayerCmdKill")
	register_forward(FM_Sys_Error, "CrashLog")

	register_clcmd("say /respawn", "cmdPlayerRespawn")
	register_clcmd("say /odrodz", "cmdPlayerRespawn")
	
	register_clcmd("say /start", "cmdOnePlayerMode");
	register_clcmd("say /skill", "cmdmenuPlayerSkill");
	register_clcmd("say /info", "cmdInfoRound")
	register_clcmd("say /menu",  "cmdmenuPlayer");
	
	register_clcmd("say /class",  "cmdmenuPlayerClass");
	register_clcmd("say /klasa",  "cmdmenuPlayerClass");

	register_clcmd("say /sklep", "cmdmenuPlayerShop")
	register_clcmd("say /shop", "cmdmenuPlayerShop")
	
	register_clcmd("say /ustawienia", "menuPlayerOptions")
	register_clcmd("say /config", "menuPlayerOptions")
	register_clcmd("say /settings", "menuPlayerOptions")
	register_clcmd("say /options", "menuPlayerOptions")
	
	register_clcmd("say /swap", "cmdSwapMoney")
	register_clcmd("say /wymien", "cmdSwapMoney")
	register_clcmd("say /zamien", "cmdSwapMoney")
	
	register_clcmd("radio2",     "cmdUseLighting")
	register_clcmd("jointeam", "PlayerJoinTeam")
	
	register_message(get_user_msgid("SayText"), "SayText")
	log_amx("asd 2")
	gStatusText = get_user_msgid("StatusText");
	
	gSyncInfo[SYNC_WAVE_INFO] = CreateHudSyncObj();
	gSyncInfo[SYNC_DAMAGE] = CreateHudSyncObj();
	gSyncInfo[SYNC_END_GAME] = CreateHudSyncObj();
	
	/* LOADING CONFIGURATION */
	
	giMaxPlayers = get_maxplayers();
	
	new gszMapName[33];
	get_mapname(gszMapName, 32);
	
	formatex(gszRoundName[ROUND_NONE], 32,		"%L", LANG_SERVER, "ROUND_NONE")
	formatex(gszRoundName[ROUND_NORMAL], 32,	"%L", LANG_SERVER, "ROUND_NORMAL")
	formatex(gszRoundName[ROUND_FAST], 32,		"%L", LANG_SERVER, "ROUND_FAST")
	formatex(gszRoundName[ROUND_STRENGHT], 32, 	"%L", LANG_SERVER, "ROUND_STRENGHT")
	formatex(gszRoundName[ROUND_BONUS], 32, 	"%L", LANG_SERVER, "ROUND_BONUS")
	formatex(gszRoundName[ROUND_BOSS], 32, 		"%L", LANG_SERVER, "ROUND_BOSS")
	
	formatex(gszClassName[0], 32, "Brak")
	formatex(gszClassDescription[0], 127, "Brak")
	log_amx("asd 3")
	LoadCvars()
	LoadWave(gszMapName)
	CheckMap();
	log_amx("asd 4")
	CheckGamePossibility()	
	set_task(2.0, "PlayerHud", TASK_PLAYER_HUD, _, _, "b");
	log_amx("asd 5")

}
		
/* Loads cvars */
public LoadCvars()
{
		
	// This is set in a configuration file

	/*gCvarInfo[CVAR_BASE_HEALTH] 	= create_cvar("td_base_health", 	"80", _, _, true, 1.0, false, _);
	gCvarInfo[CVAR_TIME_TO_WAVE] 	= create_cvar("td_time_to_wave", 	"12", _, _, true, 1.0, true, 180.0)
	gCvarInfo[CVAR_MONSTER_DAMAGE] 	= create_cvar("td_damage", 		"4", _, _, true, 1.0, false, _);
	gCvarInfo[CVAR_BOSS_DAMAGE] 	= create_cvar("td_boss_damage", 	"8", _, _, true, 1.0, false, _);
	
	// =====
	
	gCvarInfo[CVAR_KILL_GOLD] 	= create_cvar("td_kill_gold", 		"3", _, _, true, 0.0, false, _);
	gCvarInfo[CVAR_KILL_BONUS_GOLD]	= create_cvar("td_kill_bonus_gold", 	"10", _, _,true, 0.0, false, _);
	gCvarInfo[CVAR_KILL_BOSS_GOLD] 	= create_cvar("td_kill_boss_gold", 	"6", _, _, true, 0.0, false, _);

	gCvarInfo[CVAR_KILL_BONUS_FRAGS]= create_cvar("td_kill_bonus_frags", 	"25", _, _,true, 0.0, false, _);
	gCvarInfo[CVAR_KILL_BOSS_FRAGS] = create_cvar("td_kill_boss_frags", 	"20", _, _, true, 0.0, false, _);

	gCvarInfo[CVAR_KILL_MONEY] 	= create_cvar("td_kill_money", 	"650", _,_,true, 0.0, true, 16000.0);
	gCvarInfo[CVAR_KILL_BP_AMMO] 	= create_cvar("td_kill_bp_ammo", 	"15", _, _,true, 0.0, false, _);
	gCvarInfo[CVAR_WAVE_GOLD] 	= create_cvar("td_wave_gold", 		"5", _, _, true, 0.0, false, _);
	gCvarInfo[CVAR_WAVE_MONEY] 	= create_cvar("td_wave_money", 	"1000",_,_,true, 0.0, true, 16000.0);
	gCvarInfo[CVAR_SWAP_MONEY] 	= create_cvar("td_swap_money", 	"1", _, _, true, 0.0, true, 1.0);
	gCvarInfo[CVAR_SWAP_MONEY_MONEY]= create_cvar("td_swap_money_money",  "10000",_,_,true, 0.0, true,16000.0);
	gCvarInfo[CVAR_SWAP_MONEY_GOLD] = create_cvar("td_swap_money_gold", 	"10",  _,_,true, 0.0, false, _)
	gCvarInfo[CVAR_BLOCK_CMD_KILL] 	= create_cvar("td_block_cmd_kill", 	"1", _, _, true, 0.0, true, 1.0);
	gCvarInfo[CVAR_RESPAWN_PLAYER_CMD] = create_cvar("td_respawn_player_cmd","1", _,_,true, 0.0, true, 1.0);
	gCvarInfo[CVAR_ONE_PLAYER_MODE]	= create_cvar("td_one_player_mode", 	"1", _, _, true, 0.0, true, 1.0);
	gCvarInfo[CVAR_KILL_MONSTER_FX] = create_cvar("td_kill_monster_fx", 	"1", _, _, true, 0.0, true, 1.0);
	gCvarInfo[CVAR_SEND_MONSTER_TIME] = create_cvar("td_send_monster_time", "1.5",_,_,true, 0.1, true, 10.0);
	gCvarInfo[CVAR_COUNTDOWN_MODE] 	= create_cvar("td_countdown_mode", 	"2", _, _, true, 0.0, true, 2.0); // 0=off 1=hud 2=timer
	gCvarInfo[CVAR_DAMAGE_RATIO]	= create_cvar("td_damage_ratio", 	"400", _,_,true, 0.0, false, _); 
	gCvarInfo[CVAR_DAMAGE_GOLD] 	= create_cvar("td_damage_gold", 	"1", _, _, true, 0.0, false, _); 
	gCvarInfo[CVAR_DAMAGE_MONEY] 	= create_cvar("td_damage_money", 	"65", _, _, true, 0.0, false, _); 
	gCvarInfo[CVAR_SHOW_LEFT_DAMAGE]= create_cvar("td_show_left_damage", 	"1", _, _, true, 0.0, true, 1.0); 
	gCvarInfo[CVAR_PLAYER_JOIN_EXTRA_MONEY]= create_cvar("td_player_join_extra_money","800", _, _, true, 0.0, false, _); 
	gCvarInfo[CVAR_PLAYER_JOIN_EXTRA_GOLD]= create_cvar("td_player_join_extra_gold", "6", _, _, true, 0.0, false, _); 
	gCvarInfo[CVAR_PLAYER_JOIN_EXTRA]= create_cvar("td_player_join_extra","1", _, _, true, 0.0, true, 1.0); 
	gCvarInfo[CVAR_PLAYER_JOIN_EXTRA_MIN_WAVE]= create_cvar("td_player_join_extra_min_wave", 	"3", _, _, true, 0.0, false, _); 
	gCvarInfo[CVAR_BLOCK_HE] 	= create_cvar("td_block_he", 		"0", _, _, true, 0.0, true, 1.0); 
	gCvarInfo[CVAR_BLOCK_FB] 	= create_cvar("td_block_fb", 		"1", _, _, true, 0.0, true, 1.0); 
	gCvarInfo[CVAR_BLOCK_SG] 	= create_cvar("td_block_sg", 		"1", _, _, true, 0.0, true, 1.0); 
	//gCvarInfo[CVAR_CUSTOM_PLAYER_MODELS] = create_cvar("td_custom_player_models", "1")

	LoadCvar()
	
	for(new i; i < _:e_Cvar;i++) {
		if(i == _:CVAR_SEND_MONSTER_TIME )
			bind_pcvar_float(gCvarInfo[e_Cvar:i], Float:gCvarValue[e_CvarValue:i])
		else
			bind_pcvar_num(gCvarInfo[e_Cvar:i], gCvarValue[e_CvarValue:i])
	}*/
	
		
}

/* Writes a error logs to file */
public CrashLog(const szError[]) {
	log_to_file("towerdefense_crash.log", szError)  
}

/* Swap money*/
public cmdSwapMoney(id) {
	new iMoney = cs_get_user_money(id)
	
	if(!gCvarValue[SWAP_MONEY]) {
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "CMD_SWAP_MONfEY_DISABLE");
		return;
	}
	if(iMoney < gCvarValue[SWAP_MONEY_MONEY]) {
		
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "CMD_SWAP_MONEY_NOT_ENOUGHT", gCvarValue[SWAP_MONEY_MONEY])
		giPlayerSwapMoneyMsg[id] = 0
		
		return;
	}
	if(giPlayerSwapMoneyMsg[id]) {
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix,id, "CMD_SWAP_MONEY", gCvarValue[SWAP_MONEY_MONEY], gCvarValue[SWAP_MONEY_GOLD])
	
		iMoney -= gCvarValue[SWAP_MONEY_MONEY]
		
		fm_set_user_money(id, iMoney)
		gPlayerInfo[id][PLAYER_GOLD] += gCvarValue[SWAP_MONEY_GOLD]
		client_cmd(id, "spk sound/%s", gSounds[SOUND_COIN]);
		giPlayerSwapMoneyMsg[id] = 0;
	}
	log_amx("asd 51")
}

/* Delete C4 */
public C4Remove(id, iWeapon) {
	if(iWeapon == CSW_C4) {
		entity_set_int(id, EV_INT_body, 0)
		cs_set_user_plant(id, 0, 0)
		SetHamReturnInteger( false )
		return HAM_SUPERCEDE
	}
	log_amx("asd 3")
	return HAM_IGNORED
}

/* Respawns player */
public cmdPlayerRespawn(id) {
	if(is_user_alive(id)) {
		ColorChat(id, GREEN, "%s^x03 %L", gszPrefix, id, "CMD_RESPAWN_NOT_ALIVE");
		return;
	}
	else if(gCvarValue[RESPAWN_PLAYER_CMD] == 0) {
		ColorChat(id, GREEN, "%s^x03 %L", gszPrefix, id, "CMD_RESPAWN_DISABLE");
		return;
	}
	else if(get_user_team(id) == 0 || get_user_team(id) == 3) {
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "CMD_RESPAWN_NO_TEAM");
		return;
	}	
	else if(!is_user_alive(id) && is_user_connected(id)) {
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "CMD_RESPAWN");
		ExecuteHamB(Ham_CS_RoundRespawn, id)
	}
	log_amx("asd 22")
}

/* Shows info about acutally wave */
public cmdInfoRound(id, force) {
	if(is_user_connected(id) && gGame && (MAX_WAVE >= giWave >= 1) && gWaveIsStarted  || force) {
		
		static szTemp[64],szText[128], szMonsters[33];
		
		new iMonsterNum = is_special_wave(giWave)?gWaveInfo[giWave][WAVE_MONSTER_NUM]+1:gWaveInfo[giWave][WAVE_MONSTER_NUM]
		
		if(iMonsterNum >= 5) {
			formatex(szMonsters, charsmax(szMonsters), "%L", id, "INFO_ROUND_MONSTERS_1")
		} else if(iMonsterNum > 1) {
			formatex(szMonsters, charsmax(szMonsters), "%L", id, "INFO_ROUND_MONSTERS_2")
		} else if(iMonsterNum == 1) {
			formatex(szMonsters, charsmax(szMonsters), "%L", id, "INFO_ROUND_MONSTERS_3")
		} else if(iMonsterNum <= 0) {
			formatex(szMonsters, charsmax(szMonsters), "%L", id, "INFO_ROUND_MONSTERS_ERROR")
		}

		new e_RoundType:RoundType = gWaveInfo[giWave][WAVE_ROUND_TYPE]
		
		formatex(szText, 127, "%L: %d | %L [ %d %s ]", id, "WAVE", giWave, id, 
		(RoundType==ROUND_NONE?"ROUND_NONE":RoundType==ROUND_NORMAL?"ROUND_NORMAL":RoundType==ROUND_FAST?"ROUND_FAST":RoundType==ROUND_STRENGHT?"ROUND_STRENGHT":RoundType==ROUND_BONUS?"ROUND_BONUS":RoundType==ROUND_BOSS?"ROUND_BOSS":"ROUND_NONE"),
		iMonsterNum, szMonsters);
		
		if((!is_special_wave(giWave) && iMonsterNum) || (is_special_wave(giWave) && (iMonsterNum-1) > 0)) {	
			formatex(szTemp, charsmax(szTemp), "^nHP: %d^nSPEED: %d", gWaveInfo[giWave][WAVE_MONSTER_HEALTH], gWaveInfo[giWave][WAVE_MONSTER_SPEED])
			add(szText, 127, szTemp);
		}
		if(gWaveInfo[giWave][WAVE_ROUND_TYPE] == ROUND_BOSS) {
			formatex(szTemp, charsmax(szTemp), "^n^nBOSS :^nHP: %d^nSPEED: %d", gWaveInfo[giWave][WAVE_SPECIAL_HEALTH], gWaveInfo[giWave][WAVE_SPECIAL_SPEED])
			add(szText, 127, szTemp)
		}
		else if(gWaveInfo[giWave][WAVE_ROUND_TYPE] == ROUND_BONUS) {
			formatex(szTemp, charsmax(szTemp), "^n^nBONUS:^nHP: %d^nSPEED: %d", gWaveInfo[giWave][WAVE_SPECIAL_HEALTH], gWaveInfo[giWave][WAVE_SPECIAL_SPEED])
			add(szText, 127, szTemp)
		}
		
		set_hudmessage(255, 255, 255, 0.50, 0.65, 2, 9.0, 9.0, 0.05, 3.0, -1)
		ShowSyncHudMsg(id, gSyncInfo[SYNC_WAVE_INFO], szText)
	}
}

/* Blocks switching team */
public PlayerJoinTeam(id){
	if(!is_user_connected(id) || !get_user_team(id) || get_user_team(id) == 3)
		return PLUGIN_CONTINUE
	return PLUGIN_HANDLED_MAIN
}

public plugin_cfg() {
	
	server_cmd("mp_buytime 9999")
	server_cmd("sv_maxspeed 9999")
	server_cmd("mp_timelimit 9999")
	log_amx("asd 51232")
}

/* Blocks restricted weapons(Grenades) */
public eventCurWeapon(id) 
{
	new weapon = read_data(2)
	
	if((weapon == CSW_HEGRENADE && gCvarValue[BLOCK_HE]) || (weapon == CSW_FLASHBANG && gCvarValue[BLOCK_FB]) || (weapon == CSW_SMOKEGRENADE && gCvarValue[BLOCK_SG])) 
	{
		client_print(id, print_center, "Grenade %s is restricted!", weapon==CSW_HEGRENADE?"HE":weapon==CSW_FLASHBANG?"FB":weapon==CSW_SMOKEGRENADE?"SG":"")
		engclient_cmd(id, "weapon_knife")	
	}
}  

public _get_monster_speed(ent, defaultspeed)
	return ( defaultspeed   ?   (entity_get_int(ent, EV_INT_monster_type)==_:ROUND_BOSS?gWaveInfo[giWave][WAVE_SPECIAL_SPEED] : entity_get_int(ent, EV_INT_monster_type)==_:ROUND_BONUS? gWaveInfo[giWave][WAVE_SPECIAL_SPEED] : gWaveInfo[giWave][WAVE_MONSTER_SPEED])    :   entity_get_int(ent, EV_INT_monster_speed)) 

public _set_monster_speed(ent, speed, defaultspeed, now) {
	if(defaultspeed) {
		switch(e_RoundType:entity_get_int(ent, EV_INT_monster_type)) {
			case ROUND_BOSS, ROUND_BONUS: entity_set_int(ent, EV_INT_monster_speed, gWaveInfo[giWave][WAVE_SPECIAL_SPEED])
			default: entity_set_int(ent, EV_INT_monster_speed, gWaveInfo[giWave][WAVE_MONSTER_SPEED])
		}
	} else {
		entity_set_int(ent, EV_INT_monster_speed, speed)
	}
	
	if(entity_get_int(ent, EV_INT_monster_type) == _:ROUND_NONE)
		return
		
	if(now) {
		new iTrack = entity_get_int(ent, EV_INT_monster_track), szFormat[33], Float:Velocity[3]
		formatex(szFormat, charsmax(szFormat), "track%d",iTrack)
		new iTarget = find_ent_by_tname(0, szFormat)
		
		if(!is_valid_ent(iTarget))
			iTarget = find_ent_by_tname(0, "end")
		
		entity_set_aim(ent, iTarget, Float:{0.0, 0.0, 0.0}, 0);
		
		velocity_by_aim(ent, entity_get_int(ent, EV_INT_monster_speed) < 0 ? 1 : entity_get_int(ent, EV_INT_monster_speed), Velocity)
		entity_set_vector(ent, EV_VEC_velocity, Velocity)
		
		new Float:fSpeed = float(entity_get_int(ent, EV_INT_monster_speed))
		fSpeed /= 240.0		
		entity_set_float(ent, EV_FL_framerate, fSpeed)
	}
		
}

/* Sterring monsters track to move */
public touchMonsterTrack(iMonster, track) {
	
	if(!td_is_monster(iMonster) || !is_valid_ent(track))
		return HAM_IGNORED
		
	new szClass[16], szFormat[33], iTrack;
	entity_get_string(track, EV_SZ_targetname, szClass, 15)
	iTrack = entity_get_int(iMonster, EV_INT_monster_track)
	
	formatex(szFormat, charsmax(szFormat), "track%d_wall", iTrack)
	
	if(equali(szFormat, szClass)) {
		new Float:Velocity[3]
		formatex(szFormat, charsmax(szFormat), "track%d",iTrack+1)
		new iTarget = find_ent_by_tname(0, szFormat)

		if(!is_valid_ent(iTarget))
			iTarget = find_ent_by_tname(0, "end")
			
		entity_set_aim(iMonster, iTarget, Float:{0.0, 0.0, 0.0}, 0);	

		velocity_by_aim(iMonster, entity_get_int(iMonster, EV_INT_monster_speed), Velocity)
		entity_set_vector(iMonster, EV_VEC_velocity, Velocity)
		entity_set_int(iMonster, EV_INT_monster_track, iTrack+1);
	}
	else if(equali(szClass, "end_wall"))  {
		//jesli doszly do konac

		giMonsterAlive--
		entity_set_int(iMonster, EV_INT_monster_track, 1);
		
		
		new Float:fDamage;
		
		new iTower = find_ent_by_class(0, "tower");
				
		if(!is_valid_ent(iTower)) {
			remove_entity(iMonster)
			return HAM_IGNORED
		}
		
		fDamage = float( gCvarValue[MONSTER_DAMAGE])
	
		if(e_RoundType:entity_get_int(iMonster, EV_INT_monster_type)== ROUND_BOSS)
			fDamage = float(gCvarValue[BOSS_DAMAGE])			

		giBaseHealth -= floatround(fDamage)
		
		_td_update_tower_origin(0, fDamage, 1)
		
		if(giBaseHealth <= 0) {
			giBaseHealth = 0;
			EndGame(PLAYERS_LOSE);
		}

		if(giMonsterAlive <= 0 && (giSendsMonster >= ( (is_special_wave(giWave)) ? (gWaveInfo[giWave][WAVE_MONSTER_NUM]+1) : (gWaveInfo[giWave][WAVE_MONSTER_NUM]) ))) {
			client_cmd(0, "spk sound/%s", gSounds[SOUND_CLEAR_WAVE]);
			set_task(3.0, "StartWave", TASK_START_WAVE) // nowy wave
		}
	
		if(is_valid_ent(iMonster)) {

			if(is_valid_ent(entity_get_edict(iMonster, EV_ENT_monster_healthbar)))
				remove_entity(entity_get_edict(iMonster, EV_ENT_monster_healthbar))
			
			
			entity_set_int(iMonster, EV_INT_monster_type, 0)
			entity_set_int(iMonster, EV_INT_monster_track, 0)
			entity_set_int(iMonster, EV_INT_monster_maxhealth, 0)
			entity_set_int(iMonster, EV_INT_monster_speed, 0)
			entity_set_edict(iMonster, EV_ENT_monster_healthbar, 0)

			remove_entity(iMonster)
		}
	}
	return HAM_IGNORED
}

public HLTV() {
	log_amx("asd 11111")
	gCanWalk = false
	
}

public LogEventNewRound() {
	gCanWalk = true
}

new isJoined[33];

/* Resets all player informations */
public ResetPlayerInformation(id) {
	log_amx("asd 2312")
	if(0 < id <= giMaxPlayers) {
		new iRet;
		ExecuteForward(gForward[FORWARD_RESET_PLAYER_INFO], iRet, id)
			
		if(iRet)
			return iRet;

		isJoined[id] = 0;
		
		giPlayerClass[id] = 0
		giPlayerChangedClass[id] = 0

		gfPlayerHudPosition[id] = Float:{0.1, 0.0}
		giPlayerHudColor[id] = {0, 255, 255}
		gfPlayerHealthbarScale[id] = 0.3
		
		gfPlayerAmmobarScale[id] = 0.30
		giPlayerAlarmValue[id] = 50
		
		gfPlayerLightingTime[id] = 0.0
		
		giPlayerHudSize[id] = HUD_NORMAL
		giPlayerHealthbar[id] = 0
		giPlayerSwapMoneyMsg[id]  =0
		giPlayerSwapAutobuy[id] = 0
		giPlayerDamage[id] = 0

		//td_set_ammobar_scale(id, gfPlayerAmmobarScale[id])
		//td_set_alarm_value(id, giPlayerAlarmValue[id]);
		
		for(new i ; i < _:e_Player ; i++)
			gPlayerInfo[id][e_Player:i] = 0
		for(new i = 1; i <= giShopItemsNum; i++) 
			giShopPlayerBuy[id][i] = 0;

	}
	
	return PLUGIN_CONTINUE
}


public client_connect(id) {
	log_amx("asd 33333")
	ResetPlayerInformation(id)
	
}

public client_disconnected(id) {
	if(get_playersnum() == 1) {
		ResetGame(0, 0.0)
	}

	ResetPlayerInformation(id)
}

public client_putinserver(id){
	log_amx("asd 33434")
	if(!is_user_connected(id) || !gGame )
		return PLUGIN_CONTINUE

	isJoined[id] = 1;
	
	set_task(5.0, "PlayerRespawn", id + TASK_PLAYER_SPAWN )
	
	return PLUGIN_CONTINUE
}

public PlayerRespawn(id) {
	id -= TASK_PLAYER_SPAWN

	if(isJoined[id] && get_user_team(id) == 1 || get_user_team(id) == 2) {
		if(gCvarValue[PLAYER_JOIN_EXTRA]) {
		        if(giWave >= gCvarValue[PLAYER_JOIN_EXTRA_MIN_WAVE] )  {
				new iGold = gCvarValue[PLAYER_JOIN_EXTRA_GOLD] * giWave
				
				ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "MSG_PLAYER_JOIN_WELCOME", giWave)
				if(gCvarValue[PLAYER_JOIN_EXTRA_GOLD]) {
					ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "MSG_PLAYER_JOIN_GOLD", iGold)	          
					gPlayerInfo[id][PLAYER_GOLD] += iGold
				}
				if(gCvarValue[PLAYER_JOIN_EXTRA_MONEY]) {
					new iMoney = (cs_get_user_money(id) * gCvarValue[PLAYER_JOIN_EXTRA_MONEY]) > 16000?16000:(cs_get_user_money(id) * gCvarValue[PLAYER_JOIN_EXTRA_MONEY])
					ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "MSG_PLAYER_JOIN_MONEY", iMoney)
					cs_set_user_money(id, iMoney)
				}
			}
	        }	

	        isJoined[id] = 0
	}
	if(!is_user_connected(id) || is_user_alive(id))
		return PLUGIN_CONTINUE	
    
                
	if(get_user_team(id) == 1 || get_user_team(id) == 2) {
		ExecuteHamB(Ham_CS_RoundRespawn, id)
	        
		remove_task(id+TASK_PLAYER_SPAWN)
		return PLUGIN_CONTINUE
	}
	set_task(5.0, "PlayerRespawn", id + TASK_PLAYER_SPAWN )
	return PLUGIN_CONTINUE
}

public cmdUseLighting(id) {
	if(!is_user_alive(id) || gPlayerInfo[id][PLAYER_LEVEL] < 7)
		return PLUGIN_CONTINUE
		
	if(gfPlayerLightingTime[id]+30 > get_gametime()) {
		client_print(id, print_center, "%L", id, "CMD_USE_LIGHTING_WAIT", floatround(gfPlayerLightingTime[id]+30-get_gametime()))
		return PLUGIN_CONTINUE
	}
	
	new Float:fAimedOrigin[3]
	new iOrigin[3]
	
	get_user_origin(id, iOrigin, 3)
	IVecFVec(iOrigin, fAimedOrigin)
	
	new iEntList[1]
	find_sphere_class(0, "monster", 80.0, iEntList, 1, fAimedOrigin)
	
	if(!is_valid_ent(iEntList[0]) || entity_get_int(iEntList[0], EV_INT_monster_type) == _:ROUND_NONE) {
		client_print(id, print_center, "%L", id, "CMD_USE_LIGHTING_NO_TARGET")
		return PLUGIN_CONTINUE
	}
	gfPlayerLightingTime[id] = get_gametime()
	
	emit_sound(id, CHAN_AUTO, gSounds[SOUND_PLAYER_USE_LIGHTING], 1.0, ATTN_NORM, 0, PITCH_NORM); 
	ExecuteHamB(Ham_TakeDamage, iEntList[0], id, id, 1000.0, DMG_BLAST)
	
	Create_Lighting(id, iEntList[0], 0, 1, 10, 20, 20, 255, 255, 255, 255, 3)
	
	return PLUGIN_CONTINUE
}

public PlayerCmdKill(id) { // jezeli ktos uzyl komendy "kill
	if(!is_user_alive(id) &&gCvarValue[BLOCK_CMD_KILL])
		return FMRES_IGNORED
		
	client_print(id, print_console, "%L", id, "CMD_PLAYER_KILL")
	ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "CMD_PLAYER_KILL")

	gPlayerInfo[id][PLAYER_GOLD] -= 2 
	client_cmd(id, "spk sound/%s", gSounds[SOUND_COIN]);
	if(gPlayerInfo[id][PLAYER_GOLD] < 0) 
		gPlayerInfo[id][PLAYER_GOLD] = 0 
	
	return FMRES_SUPERCEDE //przerwij
}

/* Players cannot damages others player */
public TakeDamagePlayer(this, idinflictor, attacker, Float:damage, damagebits) { 	
	if(is_user_alive(attacker) && is_user_alive(this))
		return HAM_SUPERCEDE
	return HAM_IGNORED;
}

public TakeDamagePost(ent, idinflictor, attacker, Float:damage, damagetype) {
	if(is_user_connected(attacker) && !(damagetype & DMG_DROWN) && !(damagetype & DMG_BURN) && is_valid_ent(ent)) {
		set_hudmessage(0, 255, 0, 0.55, -1.0, 0, 6.0, 1.0, 0.0, 0.4)
		ShowSyncHudMsg(attacker, gSyncInfo[SYNC_DAMAGE], "%d^n%s", floatround(damage), bool:entity_get_edict(ent, EV_ENT_monster_headshot)?"HS":"")	
	}
}
/* This event is sterring an damages */
public TakeDamage(ent, idinflictor, attacker, Float:damage, damagetype) {
	
	if(!is_valid_ent(ent) || !is_user_alive(attacker?attacker:idinflictor?idinflictor:0))
		return HAM_IGNORED
	
	if(td_is_monster(ent))  { //jezli to potwor
		
		/* Dodatkowe obrazenia dla broni */
		
		if(damagetype & DMG_BULLET) {
			if(gPlayerInfo[attacker][PLAYER_EXTRA_DAMAGE])
				damage += float(gPlayerInfo[attacker][PLAYER_EXTRA_DAMAGE])
			new iWeapon = get_user_weapon(attacker)
			
			new iRet
			new szData[2]
			szData[0] = floatround(damage)
			
			ExecuteForward(gForward[FORWARD_TAKE_DAMAGE], iRet, attacker, ent, iWeapon, damage, PrepareArray(szData, 1, 1))
			damage = float(szData[0])
			
			if(iRet)
				return iRet;
		}
		
		if(is_valid_ent(entity_get_edict(ent, EV_ENT_monster_healthbar)))
			entity_set_float( entity_get_edict(ent, EV_ENT_monster_healthbar) , EV_FL_frame , 0.0 + ( (entity_get_float(ent, EV_FL_health)-floatround(damage)) * 100.0 ) / entity_get_int(ent, EV_INT_monster_maxhealth));
		
		if(!(damagetype & DMG_BLAST) && !(damagetype & DMG_DROWN) && !(damagetype & DMG_BURN)) {
			
			if(gCvarValue[SHOW_LEFT_DAMAGE]) {
				client_print(attacker, print_center, "HP: %d", (floatround(entity_get_float(ent, EV_FL_health)-damage)) < 0 ? 0 : (floatround(entity_get_float(ent, EV_FL_health)-damage)));
			}
			if(gCvarValue[DAMAGE_GOLD] || gCvarValue[DAMAGE_MONEY]) {
				giPlayerDamage[attacker] += floatround(damage)

				if(giPlayerDamage[attacker] >= gCvarValue[DAMAGE_RATIO]) {
					giPlayerDamage[attacker] = 0
					gPlayerInfo[attacker][PLAYER_GOLD]+= gCvarValue[DAMAGE_GOLD]

					cs_set_user_money(attacker, (cs_get_user_money(attacker)+gCvarValue[DAMAGE_MONEY]) > 16000 ? 16000 : (cs_get_user_money(attacker)+gCvarValue[DAMAGE_MONEY]))
					
					if(gCvarValue[DAMAGE_GOLD])
						client_cmd(attacker, "spk sound/%s", gSounds[SOUND_COIN]);
				}
			}
		}
		set_task(0.1, "TakeDamageEffects", ent + TASK_DAMAGE_EFFECT)
	}
	
	SetHamParamFloat(4, damage)
	
	return HAM_IGNORED
}

/* Shows effect and emits sound */
public TakeDamageEffects(iEnt) {
	iEnt -= TASK_DAMAGE_EFFECT

	if(is_valid_ent(iEnt)) {
		switch(random_num(1, 8)) {
			case 1, 2: emit_sound(iEnt, CHAN_ITEM, gSounds[SOUND_MONSTER_HIT_1], 1.0, ATTN_NORM, 0, PITCH_NORM);
			case 3, 4: emit_sound(iEnt, CHAN_ITEM, gSounds[SOUND_MONSTER_HIT_2], 1.0, ATTN_NORM, 0, PITCH_NORM);
			case 5, 6: emit_sound(iEnt, CHAN_ITEM, gSounds[SOUND_MONSTER_HIT_3], 1.0, ATTN_NORM, 0, PITCH_NORM);
			case 7, 8: emit_sound(iEnt, CHAN_ITEM, gSounds[SOUND_MONSTER_HIT_4], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		
		if(random_num(1, 1) == 1) {

			new iOrigin[3], Float:fOrigin[3]
			entity_get_vector(iEnt, EV_VEC_origin, fOrigin)
			
			FVecIVec(fOrigin, iOrigin)
			
			iOrigin[0] += random_num(-10, 10)
			iOrigin[1] += random_num(-10, 10)
			iOrigin[2] += random_num(-10, 30)
			
			fx_blood(iOrigin, 15) // krew	
		}
	}
	remove_task(iEnt + TASK_DAMAGE_EFFECT)
}

/* Kill the monster and set a death animation*/
public MonsterKilled(iEnt, id) //zabicie potwora
{
	if(!td_is_monster(iEnt))
		return HAM_IGNORED

	new bool:bHeadShot = bool:entity_get_edict(iEnt, EV_ENT_monster_headshot)
	new iDeadSeq;
	
	switch(bHeadShot) {
		case true: iDeadSeq = lookup_sequence(iEnt, "head") 
		case false: switch(random_num(1, 3)) {
				case 1:iDeadSeq = lookup_sequence(iEnt, "death1")
				case 2:iDeadSeq = lookup_sequence(iEnt, "death2")
				case 3:iDeadSeq = lookup_sequence(iEnt, "death3")
			}
	}
	if(!iDeadSeq)
		iDeadSeq = lookup_sequence(iEnt, "death1");
	
	new iRet;
	new e_RoundType:iMonsterType = e_RoundType:entity_get_int(iEnt, EV_INT_monster_type)
	ExecuteForward(gForward[FORWARD_MONSTER_KILLED], iRet, iEnt, id, iMonsterType)

	if(iRet)
		return iRet
		
	giMonsterAlive--
	
	if(is_valid_ent(entity_get_edict(iEnt, EV_ENT_monster_healthbar)))
		remove_entity(entity_get_edict(iEnt, EV_ENT_monster_healthbar))
	
	if(is_user_connected(id)) {
		if(iMonsterType == ROUND_BONUS ) {
			new szNick[33];
			get_user_name(id, szNick, 32);
			ColorChat(0, GREEN, "%s^x01 %L", gszPrefix,id, "GAME_PLAYER_KILL_BONUS", szNick);
		} else if(iMonsterType == ROUND_BOSS) {
			new szNick[33];
			get_user_name(id, szNick, 32);
			ColorChat(0, GREEN, "%s^x01 %L", gszPrefix, id, "GAME_PLAYER_KILL_BOSS", szNick);
		}
	}
					
	new szData[4];
	szData[0] = id,
	szData[1] = iEnt
	szData[2] = iMonsterType
	
	set_task(0.25, "postKillMonster", id  + TASK_KILL_MONSTER, szData, 3)
	
	if(is_user_connected(id)) {
		new gold
		if(iMonsterType == ROUND_BOSS)
			gold = gCvarValue[KILL_BOSS_GOLD]
		else  if(iMonsterType == ROUND_BONUS)
			gold = gCvarValue[KILL_BONUS_GOLD]
		else 
			gold = gCvarValue[KILL_GOLD]
			
		if(gPlayerInfo[id][PLAYER_EXTRA_GOLD] > 0)
			gold += gPlayerInfo[id][PLAYER_EXTRA_GOLD]
			
		set_hudmessage(255, 255, 255, 0.60, 0.6, 2, 6.0, 1.0, 0.0, 0.4)
		ShowSyncHudMsg(id, gSyncInfo[SYNC_DAMAGE], "+%L^n+%d %L^n%s", id, "KILL", gold, id, "GOLD", bHeadShot?"HS":"")
	}

	if(giMonsterAlive <= 0 && (giSendsMonster >= (is_special_wave(giWave)?gWaveInfo[giWave][WAVE_MONSTER_NUM]+1:gWaveInfo[giWave][WAVE_MONSTER_NUM]))) {
		client_cmd(0, "spk sound/%s", gSounds[SOUND_CLEAR_WAVE]);
		set_task(3.0, "StartWave", 9123)
		//return HAM_IGNORED
	}

	entity_set_int(iEnt, EV_INT_monster_type, 0)
	entity_set_int(iEnt, EV_INT_monster_track, 0)
	entity_set_int(iEnt, EV_INT_monster_maxhealth, 0)
	entity_set_int(iEnt, EV_INT_monster_speed, 0)
	entity_set_edict(iEnt, EV_ENT_monster_healthbar, 0)
	
	entity_set_float(iEnt, EV_FL_nextthink, 0.0);
	entity_set_vector(iEnt, EV_VEC_velocity, Float:{0.0, 0.0, 0.0})
	entity_set_int(iEnt, EV_INT_solid, SOLID_NOT)
	
	entity_set_int(iEnt, EV_INT_sequence, iDeadSeq); 
	entity_set_float(iEnt, EV_FL_animtime, get_gametime()+0.1); 
	entity_set_float(iEnt, EV_FL_framerate,  1.0); 
	entity_set_float(iEnt, EV_FL_frame, 3.0); 	
	
	if(gCvarValue[KILL_MONSTER_FX]) {
		new iOrigin[3]
		new Float:fOrigin[3]
		
		entity_get_vector(iEnt, EV_VEC_origin, fOrigin);
		
		FVecIVec(fOrigin, iOrigin)
		
		iOrigin[2]-=35
		
		msg_implosion(0, iOrigin, 100, 50, 5);
	}
	set_task(5.0, "DeleteMonsterPost", iEnt + TASK_MONSTER_DEATH);
	return HAM_SUPERCEDE
}	

/* Completly remove a monster */
public DeleteMonsterPost(iEnt) {
	iEnt -= TASK_MONSTER_DEATH

	if(is_valid_ent(iEnt))
		remove_entity(iEnt);

	remove_task(iEnt+TASK_MONSTER_DEATH)
}

public postKillMonster(szData[], iTask) {
	KillMonster(szData[0], e_RoundType:szData[2]);

	new iEnt = szData[1]
	if(!is_valid_ent(iEnt))
		return PLUGIN_CONTINUE
		
	if(!is_special_monster(iEnt)) {	
		switch(random_num(1, 4)) {
			case 1: emit_sound(iEnt, CHAN_ITEM, gSounds[SOUND_MONSTER_DIE_1], 1.0, ATTN_NORM, 0, PITCH_NORM);
			case 2: emit_sound(iEnt, CHAN_ITEM, gSounds[SOUND_MONSTER_DIE_2], 1.0, ATTN_NORM, 0, PITCH_NORM);
			case 3: emit_sound(iEnt, CHAN_ITEM, gSounds[SOUND_MONSTER_DIE_3], 1.0, ATTN_NORM, 0, PITCH_NORM);
			case 4: emit_sound(iEnt, CHAN_ITEM, gSounds[SOUND_MONSTER_DIE_4], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	} else {
		switch( e_RoundType:szData[2]) {
			case ROUND_BONUS: emit_sound(iEnt, CHAN_ITEM, gSounds[SOUND_BONUS_DIE], 1.0, ATTN_NORM, 0, PITCH_NORM);
			case ROUND_BOSS: emit_sound(iEnt, CHAN_ITEM, gSounds[SOUND_BOSS_DIE], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	remove_task(iTask)
	return PLUGIN_CONTINUE	
}

/* Choose class menu */
public cmdmenuPlayerClass(id) {
	if(!is_user_connected(id))
		return;

	new szTitle[164];
	formatex(szTitle, charsmax(szTitle), "\yClass:\w %s^n\yDescription:\w %s^n\rSelect class to see details", gszClassName[giPlayerClass[id]], gszClassDescription[giPlayerClass[id]]);

	new iMenu = menu_create(szTitle, "cmdmenuPlayerClass_H");
	new iCb = menu_makecallback("cmdmenuPlayerClass_Cb");

	for(new i = 1 ; i <= giClassNum ; i++) {
		menu_additem(iMenu, gszClassName[i], _, _, iCb)	
	}

	menu_display(id, iMenu)
}

public cmdmenuPlayerClass_Cb(id, menu, item) {
	if(item+1 == giPlayerClass[id])
		return ITEM_DISABLED;
	return ITEM_ENABLED;
}

public cmdmenuPlayerClass_H(id, menu, item) {
	menu_destroy(menu)
	if(item == MENU_EXIT)  {
		return;
	}
	item++
	new szDescription[164];
	new szOption[33];
	
	formatex(szDescription, charsmax(szDescription), "\yYour class:\w %s^n^n\rClass:\w %s^n\rDescription:\w %s^n\yChoose a action:", gszClassName[giPlayerClass[id]], gszClassName[item], gszClassDescription[item]);
	formatex(szOption, charsmax(szOption), "Change class");
	
	new iMenu = menu_create(szDescription, "cmdmenuPlayerClass_Choose")
	
	new szClassIndex[5];
	num_to_str(item, szClassIndex, 4);
	
	menu_additem(iMenu, szOption, szClassIndex);
	menu_display(id, iMenu)
}

public cmdmenuPlayerClass_Choose(id, menu, item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu);
		cmdmenuPlayerClass(id)
		return;
	}	
	
	new szData[5], szOptionName[4];
	new iClaasIndex, callback;
	
	menu_item_getinfo(menu, 0, iClaasIndex, szData, 4, szOptionName, 3, callback);
	iClaasIndex = str_to_num(szData);
	
	setPlayerClass(id, iClaasIndex, !gWaveIsStarted ? true : false);
	
}

public setPlayerClass(id, iClassIndex, bool:iForce) {
	if(iForce) {
		disablePlayerClassForward(id, giPlayerClass[id])
		giPlayerClass[id] = iClassIndex;
		new iRet;
		ExecuteForward(gForward[FORWARD_CLASS_SELECTED], iRet, id, iClassIndex);
		
		if(iRet)
			return iRet;
	}
	else
		giPlayerChangedClass[id] = iClassIndex;

	ColorChat(id, GREEN, "^x04%s^x01 Changed class:", gszPrefix)
	ColorChat(id, GREEN, "^x04%s^x01 Class name:^x04 %s", gszPrefix, gszClassName[iClassIndex])
	ColorChat(id, GREEN, "^x04%s^x01 Class description:^x04 %s", gszPrefix, gszClassDescription[iClassIndex])
	
	if(!iForce)
		ColorChat(id, GREEN, "^x04%s^x01 You class will be changed in next countdown", gszPrefix);

	return PLUGIN_CONTINUE;
}

public disablePlayerClassForward(id, iClassIndex) {
	new iRet;
	ExecuteForward(gForward[FORWARD_CLASS_DISABLED], iRet, id, iClassIndex);
	if(iRet)
		return iRet
	return PLUGIN_CONTINUE;
}

public KillMonster(iPlayer, e_RoundType:iType) {
	if(!is_user_connected(iPlayer)) {
		return PLUGIN_CONTINUE;
	}

	/* Golds for kill */
	if(iType == ROUND_BOSS)
		gPlayerInfo[iPlayer][PLAYER_GOLD] += gCvarValue[KILL_BOSS_GOLD]
	else  if(iType == ROUND_BONUS)
		gPlayerInfo[iPlayer][PLAYER_GOLD] += gCvarValue[KILL_BONUS_GOLD]
	else 
		gPlayerInfo[iPlayer][PLAYER_GOLD] += gCvarValue[KILL_GOLD]
	
	if(gPlayerInfo[iPlayer][PLAYER_EXTRA_GOLD] > 0)
		gPlayerInfo[iPlayer][PLAYER_GOLD] += gPlayerInfo[iPlayer][PLAYER_EXTRA_GOLD]
	
	/* Frags */

	set_user_frags(iPlayer, get_user_frags(iPlayer) + (iType == ROUND_BOSS ? gCvarValue[KILL_BOSS_FRAGS] : iType == ROUND_BONUS ? gCvarValue[KILL_BONUS_FRAGS]: 1 ))
	gPlayerInfo[iPlayer][PLAYER_FRAGS] += iType == ROUND_BOSS ? gCvarValue[KILL_BOSS_FRAGS] : iType == ROUND_BONUS ? gCvarValue[KILL_BONUS_FRAGS] : 1
	
	CheckPlayerLevel(iPlayer)

	/* Money  */
	fm_set_user_money(iPlayer, cs_get_user_money(iPlayer) + gPlayerInfo[iPlayer][PLAYER_EXTRA_MONEY] + gCvarValue[KILL_MONEY])
	
	if(cs_get_user_money(iPlayer) > 16000)
		fm_set_user_money(iPlayer, 16000, 0)

	client_cmd(iPlayer, "spk sound/%s", gSounds[SOUND_COIN]);
	
	/* Refreshing frags*/
	RefreshFrag(iPlayer)

	/* Ammo [if is other than knife] */
	if(get_user_weapon(iPlayer) != 29)
		GivePlayerAmmo(iPlayer,gCvarValue[KILL_BP_AMMO]) // prawy BP
		
	return PLUGIN_CONTINUE;
}

public CheckPlayerLevel(iPlayer) {
	if(!is_user_connected(iPlayer))
		return PLUGIN_CONTINUE

	while(gPlayerInfo[iPlayer][PLAYER_FRAGS] >= giLevelFrags[gPlayerInfo[iPlayer][PLAYER_LEVEL]])
	{
		gPlayerInfo[iPlayer][PLAYER_LEVEL]++
		gPlayerInfo[iPlayer][PLAYER_FRAGS] = 0
		
		ColorChat(iPlayer, GREEN, "%s^x01 %L", gszPrefix, iPlayer, "PLAYER_LEVEL_UP", gPlayerInfo[iPlayer][PLAYER_LEVEL])
		ColorChat(iPlayer, GREEN, "%s^x01 %L", gszPrefix, iPlayer, "PLAYER_SKILL_UP")
		
		client_cmd(iPlayer, "spk sound/%s", gSounds[SOUND_PLAYER_LEVELUP])
		
		switch(gPlayerInfo[iPlayer][PLAYER_LEVEL]) {
			case 1: {
				gPlayerInfo[iPlayer][PLAYER_EXTRA_DAMAGE] += 6;
			}
			case 2: {
				gPlayerInfo[iPlayer][PLAYER_EXTRA_SPEED] += 25
			}
			case 3: {
				gPlayerInfo[iPlayer][PLAYER_EXTRA_GOLD] += 1
			}
			case 4: {
				gPlayerInfo[iPlayer][PLAYER_EXTRA_MONEY] += 150
			}
			case 5: {
				gPlayerInfo[iPlayer][PLAYER_EXTRA_SPEED] += 50
			}
			case 6: {
				gPlayerInfo[iPlayer][PLAYER_EXTRA_DAMAGE] += 15;
			}		
		}
	}
	return PLUGIN_CONTINUE
}

public PlayerSpeed(id) {
	if(!is_user_alive(id))
			return HAM_IGNORED
	
	if(gCanWalk)
		fm_set_user_maxspeed(id, (250.0 + gPlayerInfo[id][PLAYER_EXTRA_SPEED]))
		
	return HAM_IGNORED
}

public eventMoney(id) {
	if(is_user_alive(id)) {
		if(!gCvarValue[SWAP_MONEY])
			return
			
		new iCvarValue = gCvarValue[SWAP_MONEY_MONEY]

		new iMoney = cs_get_user_money(id)
		
		if(iMoney >= iCvarValue && !giPlayerSwapMoneyMsg[id]) {
			
			if(giPlayerSwapAutobuy[id]) {
				giPlayerSwapMoneyMsg[id] = 1;
				ColorChat(id, GREEN, "%s^x03 %L", gszPrefix, id, "PLAYER_AUTO_SWAP")
				cmdSwapMoney(id)
				return
			}
			ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "PLAYER_SWAP_MONEY_1", iCvarValue)
			ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "PLAYER_SWAP_MONEY_2", gCvarValue[SWAP_MONEY_GOLD])
			giPlayerSwapMoneyMsg[id] = 1;	
			
		} else if( iMoney < iCvarValue) {
			giPlayerSwapMoneyMsg[id] = 0
		}
	}
}

public fwAddToFullPack(es_handle, e, ENT, HOST, hostflags, player, set) {
	if(player || !is_user_connected(HOST) || !is_valid_ent(ENT) || !entity_get_float(ENT, EV_FL_health))
		return FMRES_IGNORED
	
	static Float:fOrigin[ 3 ]
	static iHealthbar 
	
	iHealthbar  = entity_get_edict(ENT, EV_ENT_monster_healthbar)
	
	if(is_valid_ent(iHealthbar)) {	
		
		entity_get_vector(ENT, EV_VEC_origin, fOrigin)
		
		fOrigin[ 2 ] += 45.0;		
		
		entity_set_vector(iHealthbar, EV_VEC_origin, fOrigin)
		entity_set_model(iHealthbar, gszEntityBar[giPlayerHealthbar[HOST]]);
		entity_set_float(iHealthbar, EV_FL_scale, gfPlayerHealthbarScale[HOST])
		
		iHealthbar = 0
	}
	return FMRES_IGNORED;
}

public cmdmenuPlayerShop(id) {
	
	static szFormat[128]

	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_SHOP_TITLE", gPlayerInfo[id][PLAYER_GOLD])
	
	new iMenu = menu_create(szFormat, "cmdMenuPlayerShopH")
	new iCb = menu_makecallback("cmdMenuPlayerShopCb")
	
	for(new i = 1; i <= giShopItemsNum; i++) {
		
		if(giShopPlayerBuy[id][i] )
			formatex(szFormat, charsmax(szFormat), "%L",id, "MENU_SHOP_ITEM_BOUGHT",  giShopItemsName[i])
		else {
			if(giShopItemsPrice[i] > 0) 
				formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_SHOP_ITEM", giShopItemsName[i], giShopItemsPrice[i])
			else
				formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_SHOP_ITEM_FREE", giShopItemsName[i])
		}
			
		menu_additem(iMenu, szFormat, _, _, iCb)
	}
	menu_display(id, iMenu)
}

public cmdMenuPlayerShopCb(id, menu, item) {
	for(new i = 1; i <= giShopItemsNum;i++) {
		if((item == i-1 && gPlayerInfo[id][PLAYER_GOLD] < giShopItemsPrice[i]) || (item == i-1 && giShopPlayerBuy[id][i] == 1))
			return ITEM_DISABLED
	}
	return ITEM_ENABLED
}

public cmdMenuPlayerShopH(id, menu, item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	
	item++;
	new szKey[5];
	static szBuyOption[16],
	szTitle[256],
	szNo[16];
	
	num_to_str(item, szKey, 4);
	
	formatex(szBuyOption, charsmax(szBuyOption), "%L", id, "BUY_2");
	formatex(szNo, charsmax(szNo), "%L", id, "NO")
	
	formatex(szTitle, charsmax(szTitle), "\w%L ^n\w%L ^n\w%L ^n\w%L: \y%L ^n\r%L",  
	id, "MENU_SHOP_NAME", giShopItemsName[item], 
	id, "MENU_SHOP_DESC", giShopItemsDesc[item],
	id, "MENU_SHOP_PRICE", giShopItemsPrice[item], 
	id, "MENU_SHOP_ONE_ROUND", 
	id,  giShopOnePerMap[item] ?  "YES": "NO",
	id, "BUY_1")	
	
	new iMenu = menu_create(szTitle, "cmdMenuPlayerShop2H")
	menu_additem(iMenu, szBuyOption, szKey)
	menu_additem(iMenu,szNo )	
	menu_display(id, iMenu)
	return PLUGIN_CONTINUE
}

public cmdMenuPlayerShop2H(id, menu, item) {
	if(item == MENU_EXIT || item == 1) {
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	if(item == 0) {
		
		new szItem[6], access, callback, iName[4];
		menu_item_getinfo(menu, item, access, szItem,5, iName, 4, callback);
		
		cmdBuyItem(id, str_to_num(szItem))
	}
	return PLUGIN_CONTINUE
}

public cmdBuyItem(id, iItemIndex) {
	new iRet;
	ExecuteForward(gForward[FORWARD_ITEM_SELECTED], iRet, id, iItemIndex);
	
	if(iRet)
		return iRet;
		
	ColorChat(id, GREEN, "%s^x01 %L", gszPrefixShop, id, "PLAYER_BUY_ITEM_NAME", giShopItemsName[iItemIndex])
	ColorChat(id, GREEN, "%s^x01 %L", gszPrefixShop, id, "PLAYER_BUY_ITEM_DESC", giShopItemsDesc[iItemIndex])
	ColorChat(id, GREEN, "%s^x01 %L", gszPrefixShop, id, "PLAYER_BUY_ITEM_PRICE", giShopItemsPrice[iItemIndex])
	
	if(giShopOnePerMap[iItemIndex]) {
		giShopPlayerBuy[id][iItemIndex] = 1;
	}
	
	gPlayerInfo[id][PLAYER_GOLD] -= giShopItemsPrice[iItemIndex]
	
	client_cmd(id, "spk sound/%s", gSounds[SOUND_COIN]);
	return PLUGIN_CONTINUE
}

new bool:gimenuOption[33];

public cmdmenuPlayer(id) {
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE
	
	static szFormat[33];
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_PLAYER_TITLE")
	
	new iMenu = menu_create(szFormat, "cmdmenuPlayerH");
	new iCb = menu_makecallback("cmdmenuPlayerCb");
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_PLAYER_TURRETS");
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_PLAYER_SKILLS");
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_PLAYER_SHOP");
	menu_additem(iMenu, szFormat)
	
	if(is_plugin_loaded("td_givegold.amxx", true) != -1) {
		formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_PLAYER_GIVE_GOLD")
		menu_additem(iMenu, szFormat)
	}
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_PLAYER_PLAYER_OPTIONS");
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "EXIT")
	menu_setprop(iMenu, MPROP_EXITNAME, szFormat);
	menu_display(id, iMenu);
	return PLUGIN_CONTINUE;
}
public cmdmenuPlayerCb(id, menu, item) {
	if(item == 0 && !gTurretsAvailable)
		return ITEM_DISABLED;
	return ITEM_ENABLED
}

public cmdmenuPlayerH(id, menu, item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	
	switch(item) {
		case 0: {
			//td_show_turrets_menu(id)
		}
		case 1: {
			cmdmenuPlayerSkill(id)
		}
		case 2: {
			client_cmd(id, "say /sklep")
			
		}
		case 3: {
			if(is_plugin_loaded("td_givegold.amxx", true) != -1) {
				client_cmd(id, "say /daj")
			}
			else {
				menuPlayerOptions(id);
			}
		}
		case 4: {
			if(is_plugin_loaded("td_givegold.amxx", true) != -1){
				menuPlayerOptions(id)
			}
		}
	}
	
	return PLUGIN_CONTINUE
}

public cmdmenuPlayerSkill(id) {
	static szFormat[128]
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_SKILLS_TITLE")
	
	new iMenu = menu_create(szFormat, "cmdmenuPlayerSkillH")
	new iCb = menu_makecallback("cmdmenuPlayerSkillCb");
	
	for(new i ; i < MAX_LEVEL-1 ; i++) {
		formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_SKILLS_ITEM", gszSkills[i], i+1, giLevelFrags[i]) 
		menu_additem(iMenu, szFormat, _, _, iCb);
	}
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "BACK")
	menu_setprop(iMenu, MPROP_EXITNAME, szFormat);
	
	menu_display(id, iMenu);
}

public cmdmenuPlayerSkillCb(id, menu, item) {
	for(new i ; i < MAX_LEVEL-1 ; i++ ) {
		if(item == i && gPlayerInfo[id][PLAYER_LEVEL] < i+1) {
			return ITEM_DISABLED;
		}
	}
	
	return ITEM_ENABLED;
}

public cmdmenuPlayerSkillH(id, menu, item) {
	if(item == MENU_EXIT) {
		cmdmenuPlayer(id)
		return PLUGIN_CONTINUE
	}
	
	cmdmenuPlayerSkill(id)
	return PLUGIN_CONTINUE;
}
public menuPlayerOptions(id) {	
	static  szFormat[64]
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_OPTIONS_TITLE")
	
	new iMenu = menu_create(szFormat, "menuPlayerOptionsH");
	new iCb = menu_makecallback("menuPlayerOptionsCb")
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_OPTIONS_HUD");
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_OPTIONS_HEALTHBARS");
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_OPTIONS_TURRETS");
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "%L \y%L", id, "MENU_OPTIONS_SWAP", id, giPlayerSwapAutobuy[id] ? "ENABLED_1":"DISABLED_1");	
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "BACK")
	menu_setprop(iMenu, MPROP_EXITNAME, szFormat);
	
	menu_display(id, iMenu);
}
public menuPlayerOptionsCb(id, meun, item) {
	if(item == 3 &&! gCvarValue[SWAP_MONEY])
		return ITEM_DISABLED
	return ITEM_ENABLED
}
public menuPlayerOptionsH(id, menu, item) {
	if(item == MENU_EXIT) {
		cmdmenuPlayer(id)
		return PLUGIN_CONTINUE
	}
	
	switch(item) {
		case 0: {
			menuPlayerOptionsHud(id);
		} case 1: {
			menuPlayerOptionsBar(id)
		} case 2: {
			menuPlayerOptionTurrets(id);
		} case 3: {
			giPlayerSwapAutobuy[id] = !giPlayerSwapAutobuy[id]
			if(cs_get_user_money(id) >gCvarValue[SWAP_MONEY_MONEY] && gCvarValue[SWAP_MONEY])
				cmdSwapMoney(id)
				
			ColorChat(id, GREEN, "%s^x03 %L^x01 %L", gszPrefix,id,  giPlayerSwapAutobuy[id] ? "ENABLED_2":"DISABLED_2", id, "MENU_OPTIONS_SWAP_CHANGE");
			menuPlayerOptions(id)
		}
	}
	
	return PLUGIN_CONTINUE
}

public menuPlayerOptionTurrets(id) {
	static szFormat[33];

	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_TURRETS_TTILE")
	
	new iMenu = menu_create(szFormat, "menuPlayerOptionTurretsH")
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_TURRETS_SCALE")
	menu_additem(iMenu, szFormat)
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_TURRETS_ALARM_VALUE")
	menu_additem(iMenu, szFormat)
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "BACK")
	menu_setprop(iMenu, MPROP_EXITNAME,szFormat);
	
	menu_display(id, iMenu);
}

public menuPlayerOptionTurretsH(id, menu, item) {
	if(item == MENU_EXIT) {
		menuPlayerOptions(id)
		return PLUGIN_CONTINUE
	}
	

	switch(item) {
		case 0:{
			menuPlayerOpScaleAmmoBar(id)
		}
		case 1:  {
			menuPlayerOpAlarm(id)
		}
	}
	return PLUGIN_CONTINUE
}


public menuPlayerOpScaleAmmoBar(id) {
	if(!is_user_connected(id)) 
		return PLUGIN_CONTINUE
	
	static szFormat[33];
	
	formatex(szFormat, charsmax(szFormat), "%L %L \w0.05",  id, gimenuOption[id] ? "ADD":"SUBSTRACT", id, "EVERY")
	new iMenu = menu_create(szFormat, "menuPlayerOpScaleAmmoBarH");
	
	formatex(szFormat, charsmax(szFormat), "%L: \r%0.2f", id, "MENU_AMMOBAR_SCALE", gfPlayerAmmobarScale[id]);
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, gimenuOption[id] ? "SUBSTRACT":"ADD")
	menu_additem(iMenu, szFormat)
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "BACK")
	
	menu_setprop(iMenu, MPROP_EXITNAME, szFormat);
	menu_display(id, iMenu);
	
	return PLUGIN_CONTINUE;
}

public menuPlayerOpScaleAmmoBarH(id, menu, item) {
	if(item == MENU_EXIT) {
		menuPlayerOptionTurrets(id)
		return PLUGIN_CONTINUE
	}
	
	switch(item) {
		case 0: {
			if(gimenuOption[id]) {
				gfPlayerAmmobarScale[id] += 0.05
			} else {
				gfPlayerAmmobarScale[id] -= 0.05
			}
			
			if(gfPlayerAmmobarScale[id] < 0.1) {
				gfPlayerAmmobarScale[id] = 0.1
			} else if(gfPlayerAmmobarScale[id] > 1.0) {
				gfPlayerAmmobarScale[id] = 1.0
			}
		}
		case 1: {
			gimenuOption[id] = !gimenuOption[id]
		}
	}
	
	//td_set_ammobar_scale(id, gfPlayerAmmobarScale[id]);
	
	menuPlayerOpScaleAmmoBar(id)
	return PLUGIN_CONTINUE
}

public menuPlayerOpAlarm(id) {
	static szTitle[64], szBack[16];
	
	formatex(szTitle, charsmax(szTitle), "%L", id, "MENU_TURRETS_ALARM_TITLE", giPlayerAlarmValue[id]);
	formatex(szBack, charsmax(szBack), "%L", id, "BACK")
	
	new iMenu = menu_create(szTitle, "menuPlayerOpAlarmH")
	new iCb = menu_makecallback("menuPlayerOpAlarmCb");
	
	menu_additem(iMenu, "10", _, _, iCb)
	menu_additem(iMenu, "25", _, _, iCb)
	menu_additem(iMenu, "50", _, _, iCb)
	menu_additem(iMenu, "75", _, _, iCb)
	menu_additem(iMenu, "100", _, _, iCb)
	menu_additem(iMenu, "150", _, _, iCb)
	
	menu_setprop(iMenu, MPROP_EXITNAME, szBack);
	menu_display(id, iMenu);
}

public menuPlayerOpAlarmCb(id, menu, item) {
	if(item == 0 && giPlayerAlarmValue[id] == 10)
		return ITEM_DISABLED;
	if(item == 1 && giPlayerAlarmValue[id] == 25)
		return ITEM_DISABLED;
	if(item == 2 && giPlayerAlarmValue[id] == 50)
		return ITEM_DISABLED;
	if(item == 3 && giPlayerAlarmValue[id] == 75)
		return ITEM_DISABLED;
	if(item == 4 && giPlayerAlarmValue[id] == 100)
		return ITEM_DISABLED;
	if(item == 5 && giPlayerAlarmValue[id] == 150)
		return ITEM_DISABLED;
		
	return ITEM_ENABLED
}

public menuPlayerOpAlarmH(id, menu, item) {
	if(item == MENU_EXIT) {
		menuPlayerOptionTurrets(id)
		return PLUGIN_CONTINUE
	}
	item++;
	
	switch(item) {
		case 1: {
			giPlayerAlarmValue[id] = 10
		}
		case 2: {
			giPlayerAlarmValue[id] = 25
		}
		case 3: {
			giPlayerAlarmValue[id] = 50
		}
		case 4: {
			giPlayerAlarmValue[id] = 75
		}
		case 5: {
			giPlayerAlarmValue[id] = 100
		}
		case 6: {
			giPlayerAlarmValue[id] = 150
		}
	}
	
	ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "MENU_TURRETS_ALARM_MSG", giPlayerAlarmValue[id]);
	//td_set_alarm_value(id, giPlayerAlarmValue[id])
	menuPlayerOpAlarm(id);
	return PLUGIN_CONTINUE
}

public menuPlayerOptionsBar(id) {
	static szFormat[33];
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_HEALTHBAR_TITLE");
	new iMenu = menu_create(szFormat, "menuPlayerOptionsBarH")
	
	formatex(szFormat, charsmax(szFormat),  "%L", id, "MENU_HEALTHBAR_STYLE_ITEM")
	menu_additem(iMenu, szFormat)
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_HEALTHBAR_SCALE_ITEM")
	menu_additem(iMenu, szFormat)
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "BACK")
	menu_setprop(iMenu, MPROP_EXITNAME, szFormat);
	
	menu_display(id, iMenu);
}

public menuPlayerOptionsBarH(id, menu, item) {
	if(item == MENU_EXIT) {
		menuPlayerOptions(id)
		return PLUGIN_CONTINUE
	}
	switch(item) {
		case 0: menuPlayerOpStyleBar(id)
		case 1:  menuPlayerOpScaleBar(id)
	}
	return PLUGIN_CONTINUE
}

public menuPlayerOpScaleBar(id) {

	if(!is_user_connected(id)) 
		return PLUGIN_CONTINUE
	
	static szFormat[33];
	
	formatex(szFormat, charsmax(szFormat), "%L\w %L 0.05", id, gimenuOption[id]? "ADD":"SUBSTRACT", id, "EVERY")
	new iMenu = menu_create(szFormat, "menuPlayerOpScaleBarH");
	
	formatex(szFormat, charsmax(szFormat), "%L: \r%0.2f",id, "MENU_HEALTHBAR_SCALE",  gfPlayerHealthbarScale[id]);
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, gimenuOption[id]?"SUBSTRACT":"ADD")
	menu_additem(iMenu, szFormat)
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "BACK")
	menu_setprop(iMenu, MPROP_EXITNAME, szFormat);
	
	menu_display(id, iMenu);
	return PLUGIN_CONTINUE;
}

public menuPlayerOpScaleBarH(id, menu, item) {
	if(item == MENU_EXIT)  {
		menuPlayerOptionsBar(id)
		return PLUGIN_CONTINUE
	}
	
	switch(item) {
		case 0:  {
			if(gimenuOption[id]) {
				gfPlayerHealthbarScale[id] += 0.05
			} else {
				gfPlayerHealthbarScale[id] -= 0.05
			}
			
			if(gfPlayerHealthbarScale[id] < 0.1) {
				gfPlayerHealthbarScale[id] = 0.1
			} else if(gfPlayerHealthbarScale[id] > 1.0) {
				gfPlayerHealthbarScale[id] = 1.0
			}
		}
		case 1: {
			gimenuOption[id] = !gimenuOption[id]
		}
	}
	
	menuPlayerOpScaleBar(id)
	return PLUGIN_CONTINUE
}

public menuPlayerOpStyleBar(id) {
	static szFormat[33];
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_HEALTHBAR_STYLES_TITLE")
	new iMenu = menu_create(szFormat, "menuPlayerOpStyleBarH")
	new iCb = menu_makecallback("menuPlayerOpStyleBarCb");
	
	for(new i; i < 3 ; i++) {
		formatex(szFormat, charsmax(szFormat), "%L %d", id, "HEALTHBAR", i+1)
		menu_additem(iMenu, szFormat, _, _, iCb)
	}
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "BACK")
	menu_setprop(iMenu, MPROP_EXITNAME, szFormat);
	
	menu_display(id, iMenu);
}

public menuPlayerOpStyleBarCb(id, menu, item) {
	if(item == giPlayerHealthbar[id])
		return ITEM_DISABLED
	return ITEM_ENABLED
}

public menuPlayerOpStyleBarH(id, menu, item) {
	if(item == MENU_EXIT) {
		menuPlayerOptions(id)
		return PLUGIN_CONTINUE
	}
	
	ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "MENU_HEALTHBAR_STYLES_CHANGE", item +1);
	
	giPlayerHealthbar[id] = item;
	menuPlayerOpStyleBar(id)
	
	return PLUGIN_CONTINUE
}

public menuPlayerOptionsHud(id) {
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE
	
	static szFormat[33];
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "MENU_OPTION_HUD_TITLE");

	new iMenu = menu_create(szFormat, "menuPlayerOptionsHudH");
	new iCb = menu_makecallback("menuPlayerOptionsHudCb");
	
	formatex(szFormat, charsmax(szFormat), "%L \rX: %0.2f \yY: %0.2f", id, "MENU_OPTION_HUD_POSITION", gfPlayerHudPosition[id][0], gfPlayerHudPosition[id][1]);
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "%L R: %d G: %d B: %d", id, "MENU_OPTION_HUD_COLOR", giPlayerHudColor[id][0], giPlayerHudColor[id][1], giPlayerHudColor[id][2]);
	menu_additem(iMenu, szFormat,  _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "%L %L", id, "MENU_OPTION_HUD_SIZE", id, giPlayerHudSize[id] == HUD_SMALL ? "HUD_SMALL" : giPlayerHudSize[id] == HUD_NORMAL ? "HUD_NORMAL" : "HUD_BIG");	
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "BACK")
	menu_setprop(iMenu, MPROP_EXITNAME, szFormat);
	
	menu_display(id, iMenu);
	return PLUGIN_CONTINUE;
}

public menuPlayerOptionsHudCb(id, menu, item) {
	if(giPlayerHudSize[id] == HUD_SMALL) {
		if(item == 0 || item == 1)
			return ITEM_DISABLED
	}	
	return ITEM_ENABLED
}

public menuPlayerOptionsHudH(id, menu, item) {
	if(item == MENU_EXIT) {
		menuPlayerOptions(id)
		return PLUGIN_CONTINUE
	}
	
	switch(item) {
		case 0:menuPlayerOpHudPos(id)
		case 1:menuPlayerOpHudColor(id)
		case 2:menuPlayerOpHudSize(id)
	}
	
	return PLUGIN_CONTINUE
}
public menuPlayerOpHudSize(id) {
	static szFormat[33]
	
	formatex(szFormat, charsmax(szFormat), "%L %L", id, "MENU_OPTION_HUD_SIZE_TITLE", id, giPlayerHudSize[id] == HUD_SMALL ? "HUD_SMALL" : giPlayerHudSize[id] == HUD_NORMAL ? "HUD_NORMAL" : "HUD_BIG");
	
	new iMenu = menu_create(szFormat, "menuPlayerOpHudSizeH")
	new iCb = menu_makecallback("menuPlayerOpHudSizeCb");
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "HUD_SMALL")
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "HUD_NORMAL")
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "HUD_BIG")
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "BACK")
	menu_setprop(iMenu, MPROP_EXITNAME, szFormat);
	menu_display(id, iMenu);
}

public menuPlayerOpHudSizeCb(id, menu, item) {
	if(item == giPlayerHudSize[id])
		return ITEM_DISABLED
		
	return ITEM_ENABLED
}

public menuPlayerOpHudSizeH(id, menu, item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu)
		menuPlayerOptionsHud(id)
		return PLUGIN_CONTINUE
	}
	
	if(item == HUD_SMALL) {
		giPlayerHudSize[id] = HUD_SMALL
		menuPlayerOpHudSize(id)
	}
	else if(item == HUD_NORMAL) {
		giPlayerHudSize[id] = HUD_NORMAL
		menuPlayerOpHudSize(id)
	}
	else if(item == HUD_BIG) {
		giPlayerHudSize[id] =HUD_BIG
		menuPlayerOpHudSize(id)
	}
	
	if(item != HUD_SMALL) {
		message_begin(MSG_ONE, gStatusText, _, id);
		write_byte(0);
		write_string("");
		message_end();
	}
	
	ColorChat(id, GREEN, "%s^x01 %L %L", gszPrefix, id, "MENU_HUD_SIZE_CHANGE", id, giPlayerHudSize[id] == HUD_SMALL ? "HUD_SMALL" : giPlayerHudSize[id] == HUD_NORMAL ? "HUD_NORMAL" : "HUD_BIG");
	
	return PLUGIN_CONTINUE
}

public menuPlayerOpHudPos(id) {
	static szFormat[33];
	
	formatex(szFormat, charsmax(szFormat), "%L\w %L 0.04 :",id,  gimenuOption[id]?"ADD":"SUBSTRACT", id, "EVERY");
	
	new iMenu = menu_create(szFormat, "menuPlayerOpHudPosH")
	
	formatex(szFormat, charsmax(szFormat), "X: %0.2f", gfPlayerHudPosition[id][0]);
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "Y: %0.2f", gfPlayerHudPosition[id][1]);
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, gimenuOption[id]?"SUBSTRACT":"ADD");
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, "BACK")
	menu_setprop(iMenu, MPROP_EXITNAME, szFormat);
	
	menu_display(id, iMenu);
}

public menuPlayerOpHudPosH(id, menu, item)
{
	if(item == MENU_EXIT) {
		menuPlayerOptionsHud(id)
		return PLUGIN_CONTINUE
	}
	
	switch(item) {
		case 0: {
			if(gimenuOption[id]) {
				gfPlayerHudPosition[id][0] += 0.04
			} else {
				gfPlayerHudPosition[id][0] -= 0.04
			}
			
			if(gfPlayerHudPosition[id][0] < 0.0) {
				gfPlayerHudPosition[id][0] = 0.00
			} else if(gfPlayerHudPosition[id][0] > 1.0) {
				gfPlayerHudPosition[id][0] = 1.00
			}
		}
		case 1: {
			
			if(gimenuOption[id]) {
				gfPlayerHudPosition[id][1] += 0.04
			} else {
				gfPlayerHudPosition[id][1] -= 0.04
			}
			
			if(gfPlayerHudPosition[id][1] < 0.0) {
				gfPlayerHudPosition[id][1] = 0.00
			} else if(gfPlayerHudPosition[id][1] > 1.0) {
				gfPlayerHudPosition[id][1] = 1.00
			}
			
		}
		case 2: {
			gimenuOption[id] = !gimenuOption[id]
		}
	}
	
	menuPlayerOpHudPos(id)
	return PLUGIN_CONTINUE
}

public menuPlayerOpHudColor(id) {
	static szFormat[33]
	
	formatex(szFormat, charsmax(szFormat), "%L\w %L 10: ", id, gimenuOption[id]?"ADD":"SUBSTRACT", id, "EVERY");
	
	new iMenu = menu_create(szFormat, "menuPlayerOpHudColorH")
	
	formatex(szFormat, charsmax(szFormat), "%L %d", id, "MENU_HUD_COLOR_RED", giPlayerHudColor[id][0]);
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "%L %d", id, "MENU_HUD_COLOR_GREEN", giPlayerHudColor[id][1]);
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "%L %d", id, "MENU_HUD_COLOR_BLUE", giPlayerHudColor[id][2]);
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "%L", id, gimenuOption[id]?"SUBSTRACT":"ADD");
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat),  "%L", id, "BACK")
	menu_setprop(iMenu, MPROP_EXITNAME, szFormat);
	
	menu_display(id, iMenu);
}

public menuPlayerOpHudColorH(id, menu, item)
{
	if(item == MENU_EXIT) {
		menuPlayerOptionsHud(id)
		return PLUGIN_CONTINUE
	}
	
	switch(item) {
		case 0: {
			if(gimenuOption[id]) {
				giPlayerHudColor[id][0] += 10
			} else {
				giPlayerHudColor[id][0] -= 10
			}
			
			if(giPlayerHudColor[id][0] == 260)
				giPlayerHudColor[id][0] = 255
			else if(giPlayerHudColor[id][0] == 245)
				giPlayerHudColor[id][0] = 250
				
			if(giPlayerHudColor[id][0] < 0) {
				giPlayerHudColor[id][0] = 0
			} else if(giPlayerHudColor[id][0] > 255) {
				giPlayerHudColor[id][0] = 255
			}
		}
		case 1: {
			
			if(gimenuOption[id]) {
				giPlayerHudColor[id][1] += 10
			} else {
				giPlayerHudColor[id][1] -= 10
			}
			
			if(giPlayerHudColor[id][1] == 260)
				giPlayerHudColor[id][1] = 255
			else if(giPlayerHudColor[id][1] == 245)
				giPlayerHudColor[id][1] = 250
				
			if(giPlayerHudColor[id][1] < 0) {
				giPlayerHudColor[id][1] = 0
			} else if(giPlayerHudColor[id][1] > 255) {
				giPlayerHudColor[id][1] = 255
			}
		}
		case 2: {
			
			if(gimenuOption[id]) {
				giPlayerHudColor[id][2] += 10
			} else {
				giPlayerHudColor[id][2] -= 10
			}
			
			if(giPlayerHudColor[id][2] == 260)
				giPlayerHudColor[id][2] = 255
			else if(giPlayerHudColor[id][2] == 245)
				giPlayerHudColor[id][2] = 250
				
			if(giPlayerHudColor[id][2] < 0) {
				giPlayerHudColor[id][2] = 0
			} else if(giPlayerHudColor[id][2] > 255) {
				giPlayerHudColor[id][2] = 255
			}
		}
		case 3: {
			gimenuOption[id] = !gimenuOption[id]
		}
	}
	
	menuPlayerOpHudColor(id)
	return PLUGIN_CONTINUE
}

public PlayerSpawn(id){
	if(!is_user_alive(id) || !gGame || is_user_hltv(id))
		return HAM_IGNORED
	
	/* setting custom models if function enabled */

	/*if(gCvarValue[CUSTOM_PLAYER_MODELS]) {
		if(get_user_team(id) == 1) {
			switch(random_num(1, 4)) {
				case 1: cs_set_user_model(id, gModels[0][MODEL_PLAYER_TT])
				case 2:	cs_set_user_model(id, gModels[1][MODEL_PLAYER_TT])
				case 3:	cs_set_user_model(id, gModels[2][MODEL_PLAYER_TT])
				case 4:	cs_set_user_model(id, gModels[3][MODEL_PLAYER_TT])
			}
		} else if(get_user_team(id) == 2) {
			switch(random_num(1, 4)) {
				case 1:	cs_set_user_model(id, gModels[0][MODEL_PLAYER_CT])
				case 2:	cs_set_user_model(id, gModels[1][MODEL_PLAYER_CT])
				case 3:	cs_set_user_model(id, gModels[2][MODEL_PLAYER_CT])
				case 4:	cs_set_user_model(id, gModels[3][MODEL_PLAYER_CT])
			}
		}
	}*/
	
	if(0 < get_playersnum() <= 2 && !gOnePlayerMode && gCvarValue[ONE_PLAYER_MODE]){
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "GAME_WELCOME_MSG_1")
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "GAME_WELCOME_MSG_2")
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "GAME_WELCOME_MSG_3")
	}
	new iPlayersNum;
	for(new i = 1; i<= giMaxPlayers;i++) {
		if(!is_user_alive(i) || !is_user_connected(i) || is_user_hltv(i))
			continue
		iPlayersNum++
	}
	
	if(iPlayersNum >= 2 && !gOnePlayerMode && !gWaveIsStarted && !gGameIsStarted) {
		client_cmd(0, "spk sound/%s", gSounds[SOUND_CLEAR_WAVE]);
		gPlayersAreReady = true
		gGameIsStarted = true
		ColorChat(0, GREEN, "%s^x01 %L", gszPrefix, id, "GAME_START")
		set_task(30.0, "StartWave", TASK_START_WAVE)
	}

	if(get_playersnum() > 1 && gGameIsStarted) {
		ColorChat(0, GREEN, "%s^x01 %L", gszPrefix, id, "GAME_FRIEND_JOIN")
		gOnePlayerMode = false;
	}
	ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "HELP_MSG_1");
	
	return HAM_IGNORED
}

public PlayerHud(iTask) {	
	for(new id = 1 ; id <= giMaxPlayers ; id++) {
		if(is_user_alive(id) && is_user_connected(id)) {	
			
			new e_RoundType:RoundType = gWaveInfo[giWave][WAVE_ROUND_TYPE], str[32]
			
			formatex(str, charsmax(str), "%L", id, (RoundType==ROUND_NONE?"ROUND_NONE":RoundType==ROUND_NORMAL?"ROUND_NORMAL":RoundType==ROUND_FAST?"ROUND_FAST":RoundType==ROUND_STRENGHT?"ROUND_STRENGHT":RoundType==ROUND_BONUS?"ROUND_BONUS":RoundType==ROUND_BOSS?"ROUND_BOSS":"ROUND_NONE"))
			
			if(giPlayerHudSize[id] == HUD_BIG) {
				set_dhudmessage(giPlayerHudColor[id][0], giPlayerHudColor[id][1], giPlayerHudColor[id][2], gfPlayerHudPosition[id][0], gfPlayerHudPosition[id][1], 0, 6.0, 2.02, 0.0, 0.1)
				show_dhudmessage(id, "[%L: %d / %d | %s] [%L: %d]^n[%L: %d (%d) / %d] [%L: %d / %d]^n[%L: %d] [%L: %d / %d]",
				id, "WAVE", giWave, giWaveNum, str,id, "GOLD",  gPlayerInfo[id][PLAYER_GOLD],id, "MONSTERS",  giMonsterAlive, giSendsMonster, (is_special_wave(giWave)?gWaveInfo[giWave][WAVE_MONSTER_NUM]+1:gWaveInfo[giWave][WAVE_MONSTER_NUM]), id, "TOWER", giBaseHealth, gCvarValue[BASE_HEALTH],
				id, "LEVEL", gPlayerInfo[id][PLAYER_LEVEL], id, "FRAGS", gPlayerInfo[id][PLAYER_FRAGS], 
				gPlayerInfo[id][PLAYER_LEVEL]==(MAX_LEVEL-1)?gPlayerInfo[id][PLAYER_FRAGS]:giLevelFrags[gPlayerInfo[id][PLAYER_LEVEL]])
			} else if(giPlayerHudSize[id] == HUD_NORMAL ) {
				set_hudmessage(giPlayerHudColor[id][0], giPlayerHudColor[id][1], giPlayerHudColor[id][2], gfPlayerHudPosition[id][0], gfPlayerHudPosition[id][1], 0, 6.0, 2.02, 0.0, 0.1, 2)
				show_hudmessage(id, "[%L: %d / %d | %s] [%L: %d]^n[%L: %d (%d) / %d] [%L: %d / %d]^n[%L: %d] [%L: %d / %d]",
				id, "WAVE", giWave, giWaveNum, str,id, "GOLD",  gPlayerInfo[id][PLAYER_GOLD],id, "MONSTERS",  giMonsterAlive, giSendsMonster, (is_special_wave(giWave)?gWaveInfo[giWave][WAVE_MONSTER_NUM]+1:gWaveInfo[giWave][WAVE_MONSTER_NUM]), id, "TOWER", giBaseHealth, gCvarValue[BASE_HEALTH],
				id, "LEVEL", gPlayerInfo[id][PLAYER_LEVEL], id, "FRAGS", gPlayerInfo[id][PLAYER_FRAGS], 
				gPlayerInfo[id][PLAYER_LEVEL]==(MAX_LEVEL-1)?gPlayerInfo[id][PLAYER_FRAGS]:giLevelFrags[gPlayerInfo[id][PLAYER_LEVEL]])
			} else if ( giPlayerHudSize[id] == HUD_SMALL ) {
				
				static szText[64]	
				
				formatex(szText, charsmax(szText),  "%L: %d|%L: %d/%d|%L: %d|LVL: %d|%L: %d/%d", id, "GOLD", gPlayerInfo[id][PLAYER_GOLD], id, "MONSTERS", giMonsterAlive,
				(is_special_wave(giWave) ? gWaveInfo[giWave][WAVE_MONSTER_NUM] + 1 : gWaveInfo[giWave][WAVE_MONSTER_NUM]), id, "TOWER", giBaseHealth, 
				 gPlayerInfo[id][PLAYER_LEVEL], id, "FRAGS", gPlayerInfo[id][PLAYER_FRAGS], 
				(gPlayerInfo[id][PLAYER_LEVEL]==(MAX_LEVEL-1)?gPlayerInfo[id][PLAYER_FRAGS]:giLevelFrags[gPlayerInfo[id][PLAYER_LEVEL]]))
				
				message_begin(MSG_ONE, gStatusText, _, id);
				write_byte(0);
				write_string(szText);
				message_end();
			}
		}
	}
	
}
public cmdOnePlayerMode(id) {
	if(!is_user_alive(id)) {
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "CMD_OPM_NOT_ALIVE")
		return PLUGIN_CONTINUE
	} else if(get_playersnum() > 2 || !gGame) {
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "CMD_OPM_NOT_ALONE")
		return PLUGIN_CONTINUE
	} else if(gOnePlayerMode || gPlayersAreReady) {
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "CMD_OPM_ACTIVED")
		return PLUGIN_CONTINUE
	} else if(!gCvarValue[ONE_PLAYER_MODE]) {
		ColorChat(id, GREEN, "%s^x01 %L", gszPrefix, id, "CMD_OPM_DISABLED");
		return PLUGIN_CONTINUE;
	}
	
	client_cmd(id, "spk sound/%s", gSounds[SOUND_ACTIVATED])
	ColorChat(0, GREEN, "%s^x01 %L", gszPrefix, id, "CMD_OPM_STARTED")
	
	gOnePlayerMode = true;
	
	set_task(30.0, "StartWave", TASK_START_WAVE)
	return PLUGIN_CONTINUE
}

new gszData[6]
public StartWave() {
	if(!gGame)
		return PLUGIN_CONTINUE
	
	remove_task(TASK_START_WAVE)
	RemoveMonsters()
	
	if(giWave >= giWaveNum) {
		giSendsMonster = 0;
		giMonsterAlive = 0;
		EndGame(PLAYERS_WIN);
		return PLUGIN_CONTINUE
	}
	
	if(giWave != 0) {
		for(new i = 1 ; i <=  giMaxPlayers ; i ++) {
			if(is_user_alive(i) && is_user_connected(i)) {
				gPlayerInfo[i][PLAYER_GOLD] += gCvarValue[WAVE_GOLD] 
				fm_set_user_money(i, cs_get_user_money(i)+gCvarValue[WAVE_MONEY])
				client_cmd(i, "spk sound/%s", gSounds[SOUND_COIN]);
				if(cs_get_user_money(i) > 16000)
					fm_set_user_money(i, 16000, 0)
				ColorChat(i, GREEN, "%s^x01 %L", gszPrefix,  i, "GAME_NEXT_WAVE", gCvarValue[WAVE_GOLD] , gCvarValue[WAVE_MONEY], giWave)
			}
		}
	}
			
	gGameIsStarted = true
	giMonsterAlive = 0;
	giSendsMonster = 0;
	gWaveIsStarted = false
	giWave++;
	
	gszData[0] = gWaveInfo[giWave][WAVE_ROUND_TYPE]
	gszData[1] = is_special_wave(giWave)?gWaveInfo[giWave][WAVE_MONSTER_NUM]+1:gWaveInfo[giWave][WAVE_MONSTER_NUM]
	gszData[2] = gWaveInfo[giWave][WAVE_MONSTER_HEALTH]
	gszData[3] = gWaveInfo[giWave][WAVE_MONSTER_SPEED]
	gszData[4] = gWaveInfo[giWave][WAVE_SPECIAL_HEALTH]
	gszData[5] = gWaveInfo[giWave][WAVE_SPECIAL_SPEED]
	
	for(new i = 1; i <=  giMaxPlayers; i++ ) {
		if(is_user_connected(i)) {
			cmdInfoRound(i, 1)
			
			if(giPlayerChangedClass[i]) {
				disablePlayerClassForward(i, giPlayerClass[i])
				giPlayerClass[i] = giPlayerChangedClass[i];
				
				new iRet;
				ExecuteForward(gForward[FORWARD_CLASS_SELECTED], iRet, i, giPlayerChangedClass[i]);
				if(iRet)
					return iRet;
				giPlayerChangedClass[i] = 0;
			}
		}
	}

	if(giWave != 1) {
		new iRet;
		ExecuteForward(gForward[FORWARD_ENDWAVE], iRet, giWave-1)
		if(iRet)
		        return iRet
        }
	
	new iRet;
	ExecuteForward(gForward[FORWARD_COUNTDOWN_STARTED], iRet, giWave)
	
	if(iRet)
                return iRet
                
	new szTime[6];
	new iTime = gCvarValue[TIME_TO_WAVE]
	num_to_str(iTime, szTime, 5);
	
	
	gameCountdown(szTime, TASK_COUNTDOWN);
	set_task(float(iTime)+2.0, "PreSendMonsters", TASK_PRE_SEND_MONSTER, gszData, 6)
	
	return PLUGIN_CONTINUE
}



public gameCountdown(szData[], iTask) {
	new iSecond = str_to_num(szData);
	
	iSecond --;
	
	if(random_num(1, 6) == 1) {
		static iStart;
		
		if(!iStart)
			iStart = find_ent_by_tname(0, "start")

		switch(random_num(1, 4)) {
			case 1: emit_sound(iStart, CHAN_AUTO, gSounds[SOUND_MONSTER_GROWL_1], 1.0, ATTN_NORM, 0, PITCH_NORM); 
			case 2: emit_sound(iStart, CHAN_AUTO, gSounds[SOUND_MONSTER_GROWL_2], 1.0, ATTN_NORM, 0, PITCH_NORM); 
			case 3: emit_sound(iStart, CHAN_AUTO, gSounds[SOUND_MONSTER_GROWL_3], 1.0, ATTN_NORM, 0, PITCH_NORM); 
			case 4: emit_sound(iStart, CHAN_AUTO, gSounds[SOUND_MONSTER_GROWL_4], 1.0, ATTN_NORM, 0, PITCH_NORM); 
		}
	}

	if(iSecond ) {
		if(iSecond > 5 && (gCvarValue[TIME_TO_WAVE] - iSecond) % 3 == 1)
			client_cmd(0, "spk sound/%s", gSounds[SOUND_COUNTDOWN]);
		if(iSecond <= 5)
			client_cmd(0, "spk sound/%s", gSounds[SOUND_COUNTDOWN]);
	} 

	for(new i = 1 ; i <=  giMaxPlayers; i++ ) {
		if(is_user_connected(i) && iSecond  >= 0) {
			static szText[33];
			formatex(szText, 32, "%L %d", i, "GAME_WAVE_COMING", giWave, iSecond);
			if(iSecond == 0)
				formatex(szText, 32, "START!!!")
			
			set_hudmessage(255, 255, 0, 0.06, 0.63, 1, 1.0, 1.1, 0.2, 0.2, 3)
			show_hudmessage(i, szText)

			if(giPlayerChangedClass[i]) {
				disablePlayerClassForward(i, giPlayerClass[i])
				giPlayerClass[i] = giPlayerChangedClass[i];
				giPlayerChangedClass[i] = 0;
			}
		}
	}
		
	if(iSecond <= 0) {
		remove_task(iTask) 
		return PLUGIN_HANDLED;
	}
	num_to_str(iSecond, szData, 5);
	set_task(1.0, "gameCountdown", iTask, szData, 5) 
	
	return PLUGIN_CONTINUE;
}

public PreSendMonsters(szData[], iTask)
{
	new iRet;
	ExecuteForward(gForward[FORWARD_STARTWAVE], iRet, giWave, e_RoundType:szData[0], szData[1])
	if(iRet)
		return iRet
		
	gWaveIsStarted = true
	
	client_cmd(0, "spk sound/%s", gSounds[SOUND_START_WAVE]);
	
	switch(szData[0]) {
		case ROUND_NORMAL:	SendMonsters(ROUND_NORMAL, szData[1], szData[2])
		case ROUND_FAST:	SendMonsters(ROUND_FAST, szData[1], szData[2])
		case ROUND_STRENGHT:	SendMonsters(ROUND_STRENGHT, szData[1], szData[2])
		case ROUND_BOSS: {
			if(szData[1]-1)
				SendMonsters(ROUND_NORMAL, szData[1], szData[2])	
			else if(szData[1]-1 <= 0)
				SendMonsters(ROUND_BOSS,  -1, szData[4])
		}
		case ROUND_BONUS: {
			if(szData[1]-1)
				SendMonsters(ROUND_NORMAL, szData[1], szData[2])
			else if(szData[1]-1 <= 0)
				SendMonsters(ROUND_BONUS, -1, szData[4])
		}
	}
	
	remove_task(iTask)
	return PLUGIN_CONTINUE
}

public SendMonsters(e_RoundType:Type, num, health) {
	if(gGame == true) {
		num -- ;
		if(num < 1 && num >= (-2)) {
			
			if(Type != ROUND_BONUS && e_RoundType:gszData[0] == ROUND_BONUS) {
				SendMonsters(ROUND_BONUS, -1, gszData[4])
				
				return PLUGIN_CONTINUE
			}
			if(Type != ROUND_BOSS && e_RoundType:gszData[0] == ROUND_BOSS) {
				SendMonsters(ROUND_BOSS, -1, gszData[4])
				
				return PLUGIN_CONTINUE
			}
		}

		/* --------- */
		
		new iEnt = create_entity("info_target");
		
		entity_set_string(iEnt, EV_SZ_classname, "monster");
		static szModel[64];
			
		/* --------- */

		switch(Type)
		{
			case ROUND_NORMAL:	formatex(szModel, charsmax(szModel), "models/TD/%s.mdl", gModels[random(4)][MODEL_NORMAL])
			case ROUND_FAST:		formatex(szModel, charsmax(szModel), "models/TD/%s.mdl", gModels[random(4)][MODEL_FAST])
			case ROUND_STRENGHT:	formatex(szModel, charsmax(szModel), "models/TD/%s.mdl", gModels[random(4)][MODEL_STRENGHT])
			case ROUND_BONUS:	formatex(szModel, charsmax(szModel), "models/TD/%s.mdl", gModels[random(4)][MODEL_BONUS])
			case ROUND_BOSS:		formatex(szModel, charsmax(szModel), "models/TD/%s.mdl", gModels[random(4)][MODEL_BOSS])
		}

		/* --------- */
		
		//dllfunc(DLLFunc_Spawn, iEnt)
		entity_set_model(iEnt, szModel);	
		entity_set_float(iEnt, EV_FL_health, float(health));
		entity_set_float(iEnt, EV_FL_takedamage, DAMAGE_YES);
		entity_set_size(iEnt, Float:{-20.0, -20.0, -30.0}, Float:{20.0, 20.0, 56.0}); // org -20(-20..)			
		entity_set_vector(iEnt, EV_VEC_origin, gfStartOrigin);
		
		entity_set_vector(iEnt, EV_VEC_angles, Float:{0.0, 0.0, 0.0});
		entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX);
		entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_FLY) 
		
		/* --------- */
		
		entity_set_int(iEnt, EV_INT_sequence, 4) // oodpowiada za animacje
		entity_set_float(iEnt, EV_FL_animtime, 2.0)
		set_pev(iEnt, pev_groupinfo, GROUP_CT)
		
		/* Szybkosc animacji wzgledem speeda */

		static Float:szSpeed;
		
		if(Type != ROUND_BOSS && Type != ROUND_BONUS)
			szSpeed = float(gszData[3])
		else if(Type == ROUND_BOSS || Type == ROUND_BONUS) {
			szSpeed = float(gszData[5])
			set_glow(iEnt, 255, Type==ROUND_BONUS?255:0, 0, 17)
		}
		
		/* --------- */
		
		entity_set_int(iEnt, EV_INT_monster_speed, floatround(szSpeed))
		szSpeed /= 240.0
		
		entity_set_float(iEnt, EV_FL_framerate, szSpeed)
		
		/* Healthbar */

		new iHealtbar = create_entity("env_sprite")
		
		entity_set_string(iHealtbar, EV_SZ_classname, "monster_healthbar");
		entity_set_vector(iHealtbar, EV_VEC_origin, gfStartOrigin)
		entity_set_model(iHealtbar, gszEntityBar[0]);
		entity_set_int(iHealtbar, EV_INT_solid, SOLID_NOT);
		entity_set_int(iHealtbar, EV_INT_movetype, MOVETYPE_FLY) 
		
		entity_set_edict(iEnt, EV_ENT_monster_healthbar, iHealtbar)
		entity_set_int(iEnt, EV_INT_monster_maxhealth, health)
		entity_set_float(iHealtbar, EV_FL_scale, 0.30);
		entity_set_float(iHealtbar , EV_FL_frame , 99.0 );
			
		/* --------- */

		giMonsterAlive ++;
		giSendsMonster ++;
		
		/* --------- */
		
		entity_set_int(iEnt, EV_INT_monster_track, 1)
		entity_set_int(iEnt, EV_INT_monster_type, Type)
		
		new Float:ffOrigin3[3]
		entity_get_vector(iEnt, EV_VEC_origin, ffOrigin3)
		
		/* --------- */

		new Float:Velocity[3]
		new iTarget = find_ent_by_tname(-1, "track1")
		
		if(!is_valid_ent(iTarget)) 
			iTarget = find_ent_by_tname(-1, "end")
		
		/* --------- */
		
		entity_set_aim(iEnt, iTarget, Float:{0.0, 0.0, 0.0}, 0);	
			
		velocity_by_aim(iEnt, entity_get_int(iEnt, EV_INT_monster_speed), Velocity)
		entity_set_vector(iEnt, EV_VEC_velocity, Velocity)
		/* --------- */
		
		//if(Type == ROUND_BOSS || Type == ROUND_BONUS)
		//	entity_set_float(iEnt, EV_FL_nextthink, get_gametime()+0.01)


		entity_set_float(iEnt, EV_FL_nextthink, get_gametime()+0.01)

		/* --------- */
		
		remove_task((num+TASK_SEND_MONSTER+1))

		if(num >= 1 && Type != ROUND_BONUS && Type != ROUND_BOSS) {
			new szData[4]
			szData[0] = Type
			szData[1] = num
			szData[2] = health

			set_task(gCvarValue[SEND_MONSTER_TIME], "SendMonstersPost", (num+TASK_SEND_MONSTER), szData, 3) // 1.0 - czas wyslania nastepnego potwora
		}
	}
	return PLUGIN_CONTINUE
}
public SendMonstersPost(szData[])// sendmonsters 2
	if(gGame)
		SendMonsters(e_RoundType:szData[0], szData[1], szData[2])
		
public thinkMonsterThink(iEnt) {
	if(!is_valid_ent(iEnt))
		return FMRES_IGNORED	
	if(giMonsterAlive == 1 || giSendsMonster == 1)
		goto iNextThink
	
	new iEntList[4]//, szTrack[16]
	new num = find_sphere_class(iEnt, "monster", 50.0, iEntList, 3)

	for(new i; i < num ; i++) {
		if(iEntList[i] == iEnt)
			continue
		set_pev(iEntList[i], pev_groupinfo, GROUP_TERRORISTS)
	}
	
	iNextThink:
	set_pev(iEnt, pev_groupinfo, GROUP_CT)
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime()+0.01);
	
	return FMRES_IGNORED
	
	/*
		if(!is_valid_ent(iEnt))
		return FMRES_IGNORED	
	
	if(giMonsterAlive == 1 || giSendsMonster == 1)
		goto iNextThink

	static iEntList[3], szTrack[16]
	
	if(find_sphere_class(iEnt, "monster", 80.0, iEntList, 2) <= 1)
		goto iNextThink;
	
	new ciEnt = (iEntList[1] == iEnt && iEntList[0] != iEnt)  ?  iEntList[0]  :  iEntList[1]
	
	if(ciEnt == iEnt)
		goto iNextThink
	
	
	
	if(entity_get_int(iEnt, EV_INT_solid) == SOLID_NOT) {
		formatex(szTrack, charsmax(szTrack), "track%d_wall", entity_get_int(iEnt, EV_INT_monster_track))
		
		new giEnt = find_ent_by_tname(-1, szTrack)
		
		if(!is_valid_ent(giEnt))
			giEnt = find_ent_by_tname(-1, "end_wall")
		
		static Float:fOrigin[2][3]
		
		entity_get_vector(iEnt, EV_VEC_origin, fOrigin[0])
		fm_get_brush_entity_origin(giEnt, fOrigin[1])
		
		if(get_distance_f(fOrigin[0], fOrigin[1]) <= 80.0)
			touchMonsterTrack(iEnt, giEnt)
	}
	
	
	if(ciEnt != iEnt && ciEnt > 0) {
		entity_set_int(iEnt, EV_INT_solid, SOLID_NOT)
		entity_set_float(iEnt, EV_FL_nextthink, get_gametime()+0.01);
		return FMRES_IGNORED
	}
	
	iNextThink:
	
	entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX)
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime()+0.01);
	return FMRES_IGNORED
	*/
}
	
public RemoveMonsters() {
	new iEnt = find_ent_by_class(0, "monster");
	while(is_valid_ent(iEnt)) {

		entity_set_int(iEnt, EV_INT_monster_type, 0)
		entity_set_int(iEnt, EV_INT_monster_track, 0)
		entity_set_int(iEnt, EV_INT_monster_maxhealth, 0)
		entity_set_int(iEnt, EV_INT_monster_speed, 0)
		entity_set_edict(iEnt, EV_ENT_monster_healthbar, 0)
		remove_entity(iEnt)
		iEnt = find_ent_by_class(0, "monster");
	}
	iEnt = find_ent_by_class(0, "monster_healthbar")
	while(is_valid_ent(iEnt)) {
		remove_entity(iEnt)
		iEnt = find_ent_by_class(0, "monster_healthbar")
	}
}

public EndGame(e_EndType: iType) {
	
	giMonsterAlive = 0;
	giSendsMonster = 0;
	gWaveIsStarted = false;
	gGame = false;
	
	RemoveMonsters();
	
	new iFrag, iPlayer, szNick[33];
	new szMapName[33]
	
	for(new i = 1; i <= giMaxPlayers; i++) {
		if(is_user_connected(i) && ( 1<= i <= 32 )) {
			if(iFrag < get_user_frags(i)) {
				iFrag = get_user_frags(i)
				iPlayer = i;
			}
		}
	}
	if(iPlayer == 0 && iFrag == 0)
	{
		iPlayer = 1
		iFrag == get_user_frags(1) ? get_user_frags(1) : 0
	}

	get_cvar_string("amx_nextmap", szMapName, charsmax(szMapName));
	get_user_name(iPlayer, szNick, charsmax(szNick));	
	
	new message[32]
	if(iType == PLAYERS_LOSE) 
	{
		if(gModelTurret)
		{
			set_task(0.1, "Explode")
			set_task(0.5, "Explode")
			set_task(1.0, "Explode")
			set_task(2.0, "Explode")
			set_task(2.5, "Explode")
			set_task(3.0, "Explode")
			set_task(4.0, "Explode")
			set_task(4.4, "Explode")
			set_task(4.8, "Explode")
			set_task(5.0, "Explode")
			set_task(6.6, "Explode")
			set_task(6.7, "RemoveTower")
		}
		
		set_hudmessage(255, 255, 0, 0.25, 0.65, 0, 6.0, 10.0, 0.0, 0.4, -1)
		formatex(message, charsmax(message), "GAME_END_PLAYERS_LOSE")
	} else if(iType == PLAYERS_WIN) {
		set_hudmessage(255, 255, 0, 0.25, 0.65, 0, 6.0, 10.0, 0.0, 0.4, -1)
		formatex(message, charsmax(message), "GAME_END_PLAYERS_WIN")
	}
	
	for(new i = 1; i < MAX_PLAYERS; i++) {
		if(!is_user_connected(i) || is_user_hltv(i))
			continue
		ShowSyncHudMsg(i, gSyncInfo[SYNC_END_GAME], "%L", i, message, szNick, iFrag)
	}
		
	endGameChangeMap("15", 500);
	set_task(15.0, "ChangeMap", _, szMapName, 32);
}

public endGameChangeMap(szData[], iTask) {
	new iSecond = str_to_num(szData);
	static szText[64];
	static szMapName[32];
	
	get_cvar_string("amx_nextmap", szMapName, charsmax(szMapName));
	
	iSecond --;

	if(iSecond <= 0) {
		remove_task(iTask) 
		return PLUGIN_HANDLED;
	}
	
	for(new i ; i <=  giMaxPlayers; i++ ) {
		if(is_user_connected(i) && iSecond  > 0) {
			formatex(szText, charsmax(szText), "%L %d", i, "GAME_CHANGE_MAP_MSG", szMapName, iSecond)
			
			set_hudmessage(255, 255, 0, 0.06, 0.79, 0, 1.1, 1.1, 0.0, 0.4, -1)
			show_hudmessage(i, szText)
		}
	}
	
	num_to_str(iSecond, szData, 5);	
	
	set_task(1.0, "endGameChangeMap", iTask, szData, 5);
	return PLUGIN_CONTINUE;
}


public RemoveTower() {
	/* Usuwa g3�wn1 wie?e z serwera je?li istnieje */
	
	new iTower = find_ent_by_class(0, "tower")
	if(is_valid_ent(iTower))
		remove_entity(iTower)
}
public CheckGamePossibility(){
#if defined DEBUG
	log_to_file(gszLogFile, "DEBUG: Checking a game status...")
#endif
	if(gGame == false)
	{
		new szNextMap[33];
		
		get_cvar_string("amx_nextmap", szNextMap, 32);
		
		set_task(1.0, "gameFalseChangeMap", TASK_GAME_FALSE, szNextMap, 32,"a", 50)
		
#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Game is not possibility, becouse of bad map or bad configuration...")
#endif
	}
#if defined DEBUG
	log_to_file(gszLogFile, "DEBUG: Checking a game status completed...")
	
	log_to_file(gszLogFile, "DEBUG: Checking all configuration files completed...")
#endif
}

public CheckShopConfig() {
#if defined DEBUG
	log_to_file(gszLogFile, "DEBUG: Checking a configuration file of shop...")
#endif
	if(!file_exists(gszShopConfigFile)) {
#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Shop configuration file not found, creating new...")
#endif	

		write_file(gszShopConfigFile, ";**** FILE CREATED AUTOMATICLY ****", 0);
		write_file(gszShopConfigFile, ";If you add a new item to shop, text will be created automaticly, example:", 1);
		write_file(gszShopConfigFile, ";[NAME_OF_PLUGIN] // without .amxx", 2);
		write_file(gszShopConfigFile, ";NAME = ^"name of item^" // must be in quotes(max 63 characters)", 3);
		write_file(gszShopConfigFile, ";DESCRIPTION = ^"desc of item^" // must be in quotes (max 127 characters)", 4);
		write_file(gszShopConfigFile, ";PRICE = 35 // only a numbers! (max 9999999, min 0 -> free)", 5);
		write_file(gszShopConfigFile, ";ONE_PER_MAP = true (or yes, no, false) // others characters will not be load", 6);
		write_file(gszShopConfigFile, ";If is a problem, DEBUG mode in td_new will find it!", 7);

#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Shop configuration file created succesfully")
#endif
	}

#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Checking shop configuration file completed...")
#endif

}

public CheckClassConfig() {
#if defined DEBUG
	log_to_file(gszLogFile, "DEBUG: Checking a configuration file od player class...")
#endif
	if(!file_exists(gszClassConfigFile)) {
#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Player class configuration file not found, creating new...")
#endif	

		write_file(gszClassConfigFile, ";**** FILE CREATED AUTOMATICLY ****", 0);
		write_file(gszClassConfigFile, ";If you add a new class to plugin, text will be created automaticly, example:", 1);
		write_file(gszClassConfigFile, ";[NAME_OF_PLUGIN] // without .amxx", 2);
		write_file(gszClassConfigFile, ";NAME = ^"class name^" // must be in quotes (max 32 characters)", 3);
		write_file(gszClassConfigFile, ";DESCRIPTION = ^"class description^" // must be in quotes (max 127 characters)", 4);
		write_file(gszClassConfigFile, ";If is a problem, DEBUG mode in td_new will find it!", 7);

#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Player class configuration file created succesfully")
#endif
	}

#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Checking player class configuration file completed...")
#endif

}

public gameFalseChangeMap(szNextMap[], iTaskIndex ){
	static iNum;
	static szText[64];
	
	iNum --;
	
	if(iNum == 0) {
		/* Odliczanie zakonczone */
		remove_task(iTaskIndex);
		ChangeMap(szNextMap);
		
		return PLUGIN_CONTINUE
	}
	if(iNum < 0) {
		/* Pierwszy raz wywoluje funkcje */	
		iNum = 45
	}
	
	if(iNum > 30) {
		set_dhudmessage(170, 255, 255, 0.28, 0.61, 0, 6.0, 1.1)
		show_dhudmessage(0, "%L", 0, "GAME_NOT_POSSIBLE", szNextMap)
	}
	
	formatex(szText, charsmax(szText), "%L", 0, "GAME_CHANGE_MAP_COUNTDOWN", szNextMap, iNum)
	
	set_hudmessage(0, 255, 255, 0.17, 0.79, 0, 6.0, 1.1)
	show_hudmessage(0, szText)
	
	return PLUGIN_CONTINUE;
}

public ChangeMap(szMapName[]) {
	/* Zmienia mape */
	
	server_cmd("changelevel %s", szMapName)
}

public RefreshFrag(id)
{
	/* Od?wie?a fragi graczowi */
	
	new ideaths = cs_get_user_deaths(id);
	new ifrags = get_user_frags(id);
	new kteam = _:cs_get_user_team(id);
	
	message_begin( MSG_ALL, get_user_msgid("ScoreInfo"), {0,0,0}, 0 );
	write_byte( id );
	write_short( ifrags );
	write_short( ideaths);
	write_short( 0 );
	write_short( kteam );
	message_end();
}

public CheckMap() {
#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Checking a configuration file of waves completed")
		log_to_file(gszLogFile, "DEBUG: Checking map...")
#endif
	/* start */
	new iEnt = find_ent_by_tname(0, "start")
	
	if(is_valid_ent(iEnt) && iEnt != 0) {
		entity_get_vector(iEnt, EV_VEC_origin, gfStartOrigin)
		
		new iSprite = create_entity("env_sprite")
		
		entity_set_string(iSprite, EV_SZ_classname, "start_sprite")
		entity_set_model(iSprite, giSpriteSpawn)
			
		entity_set_vector(iSprite, EV_VEC_origin, gfStartOrigin)
		entity_set_int(iSprite, EV_INT_solid, SOLID_NOT);
		entity_set_int(iSprite, EV_INT_movetype, MOVETYPE_FLY) 
		
		entity_set_float(iSprite, EV_FL_framerate, 1.0)
		entity_set_float(iSprite, EV_FL_scale, 2.5)
	} else {
#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Enity 'start' is not exist...")
#endif
		gGame = false;
		return PLUGIN_CONTINUE
	}
	/* end */
	iEnt = find_ent_by_tname(0, "end")
	if(is_valid_ent(iEnt) && iEnt != 0) {
		
		entity_get_vector(iEnt, EV_VEC_origin, gfEndOrigin)
		
		if(gModelTurret)
		{
			new iTower = create_entity("info_target")
			new szModel[64], Float:tempOrigin[3];
		
			formatex(szModel, charsmax(szModel), "models/TD/%s.mdl", gModels[random(3)][MODEL_TOWER])
			
			entity_set_string(iTower, EV_SZ_classname, "tower")
			entity_set_model(iTower, szModel);
			entity_set_vector(iTower, EV_VEC_origin, gfEndOrigin);
			entity_set_int(iTower, EV_INT_solid, SOLID_NOT);
			entity_set_int(iTower, EV_INT_movetype, MOVETYPE_FLY) 
			drop_to_floor(iTower)
			
			entity_get_vector(iTower, EV_VEC_origin, tempOrigin)
		
			
			gfTowerOrigin = tempOrigin
			entity_set_vector(iTower,  EV_VEC_origin, gfTowerOrigin)	
		}
		
	} else {
#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Entity 'end' on map is not exist...")
#endif	
		gGame = false;
		return PLUGIN_CONTINUE
	}
	/* track */
	iEnt = find_ent_by_tname(0, "track1")
	
	if(!is_valid_ent(iEnt)) {
#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Entity 'track1' which sterring a monster is not exist. There can be a errors...")
#endif
	}
	else {
		new szTrack[16], i;
		while(iEnt > 0) {
			formatex(szTrack, charsmax(szTrack), "track%d_wall", ++i)
			iEnt = find_ent_by_tname(0, szTrack)
			if(is_valid_ent(iEnt))
				fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 0)
			else {
				formatex(szTrack, charsmax(szTrack), "track%d", i)
				if(is_valid_ent( find_ent_by_tname(0, szTrack) )) {
#if defined DEBUG
					log_to_file(gszLogFile, "DEBUG: Entity %s_wall is not exist...", szTrack)
#endif					
					gGame = false;
				}
				
				iEnt = find_ent_by_tname(0, "end_wall")
				
				if(!is_valid_ent( iEnt )) {
#if defined DEBUG
					log_to_file(gszLogFile, "DEBUG: Entity %s_wall is not exist...", szTrack)
#endif					
					gGame = false;
				}
				fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 0)
				break;
			}
		}
	}

#if defined DEBUG
	log_to_file(gszLogFile, "DEBUG: Checking map completed...")
#endif

	return PLUGIN_CONTINUE
}


public LoadSound() {
#if defined DEBUG
	log_to_file(gszLogFile, "DEBUG: Checking sounds configuration file...")
#endif

	new szText[128], len;
	new szTemp[3][128];
	
	if(!file_exists(gszSoundConfigFile))
	{
		log_to_file(gszLogFile, "Sounds configuration file not exist...")
		gGame = false
		return PLUGIN_CONTINUE
	}
	
	for(new i ; read_file(gszSoundConfigFile, i, szText, 127, len) ; i++)
	{
		if(equali(szText, ";") || equali(szText, ""))
			continue;
			
		parse(szText, szTemp[0], 127, szTemp[1], 16, szTemp[2], 127)
		remove_quotes(szTemp[2]);
		
		if(equali(szTemp[0], "START_WAVE")) 
			copy(gSounds[SOUND_START_WAVE], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_DIE_1")) 
			copy(gSounds[SOUND_MONSTER_DIE_1], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_DIE_2")) 
			copy(gSounds[SOUND_MONSTER_DIE_2], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_DIE_3")) 
			copy(gSounds[SOUND_MONSTER_DIE_3], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_DIE_4")) 
			copy(gSounds[SOUND_MONSTER_DIE_4], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_HIT_1")) 
			copy(gSounds[SOUND_MONSTER_HIT_1], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_HIT_2")) 
			copy(gSounds[SOUND_MONSTER_HIT_2], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_HIT_3")) 
			copy(gSounds[SOUND_MONSTER_HIT_3], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_HIT_4")) 
			copy(gSounds[SOUND_MONSTER_HIT_4], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_SOUND_1")) 
			copy(gSounds[SOUND_MONSTER_1], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_SOUND_2")) 
			copy(gSounds[SOUND_MONSTER_2], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_SOUND_3")) 
			copy(gSounds[SOUND_MONSTER_3], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_SOUND_4")) 
			copy(gSounds[SOUND_MONSTER_4], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_GROWL_1")) 
			copy(gSounds[SOUND_MONSTER_GROWL_1], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_GROWL_2")) 
			copy(gSounds[SOUND_MONSTER_GROWL_2], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_GROWL_3")) 
			copy(gSounds[SOUND_MONSTER_GROWL_3], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_GROWL_4")) 
			copy(gSounds[SOUND_MONSTER_GROWL_4], 127, szTemp[2])
		else if(equali(szTemp[0], "BOSS_DIE")) 
			copy(gSounds[SOUND_BOSS_DIE], 127, szTemp[2])
		else if(equali(szTemp[0], "BONUS_DIE")) 
			copy(gSounds[SOUND_BONUS_DIE], 127, szTemp[2])
		else if(equali(szTemp[0], "COIN")) 
			copy(gSounds[SOUND_COIN], 127, szTemp[2])
		else if(equali(szTemp[0], "ACTIVATED")) 
			copy(gSounds[SOUND_ACTIVATED], 127, szTemp[2])
		else if(equali(szTemp[0], "COUNTDOWN")) 
			copy(gSounds[SOUND_COUNTDOWN], 127, szTemp[2])
		else if(equali(szTemp[0], "PLAYER_LEVELUP")) 
			copy(gSounds[SOUND_PLAYER_LEVELUP], 127, szTemp[2])
		else if(equali(szTemp[0], "PLAYER_USE_LIGHTING")) 
			copy(gSounds[SOUND_PLAYER_USE_LIGHTING], 127, szTemp[2])
		else if(equali(szTemp[0], "CLEAR_WAVE")) 
			copy(gSounds[SOUND_CLEAR_WAVE], 127, szTemp[2])
		
	}
#if defined DEBUG
	log_to_file(gszLogFile, "DEBUG: Checking sounds file configuration completed...")
#endif
	return PLUGIN_CONTINUE
}
public LoadWave(szMapName[33]) {
	replace(szMapName, charsmax(szMapName), ".ini", "")
#if defined DEBUG
	log_to_file(gszLogFile, "DEBUG: Loading waves from ^"%s.ini^" file...", szMapName)
#endif
	
	new szFileDir[64];
	new iLoadStandardWave;
	static LoadStandardConf
		
	formatex(szFileDir, charsmax(szFileDir), "%s/%s.ini", gszWaveConfigDir, szMapName)
	
	if(!file_exists(szFileDir)) {	
#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: File ^"%s^" cannot be found.", szFileDir)
		log_to_file(gszLogFile, "DEBUG: Loading standard waves")
#endif
		iLoadStandardWave = 1;
	}
	
	if(iLoadStandardWave) {
#if defined DEBUG
		if(iLoadStandardWave == 2) 
			log_to_file(gszLogFile, "DEBUG: In wave configuration file ^"%s^" selects loads standard waves.", szFileDir)
#endif		
		formatex(szFileDir, charsmax(szFileDir), "%s/standard_wave.ini", gszWaveConfigDir)
		
		if(!file_exists(szFileDir)) {
#if defined DEBUG       
			log_to_file(gszLogFile, "File configuration ^"%s^" is not exist. Changing to next map from amx_nextmap cvar", szFileDir)
#endif
			gGame = false
			
			return PLUGIN_CONTINUE
		} else {
			LoadWave("standard_wave");
			iLoadStandardWave = 0;
			
			return PLUGIN_CONTINUE
		}
	}
	
	new szText[128], len;
	new szData[10][64]
	
	new iWasConf = 7;
	
	for(new i; read_file(szFileDir, i, szText, 127, len) ; i++) {
		if(szText[0] == ';' || (equali(szText, "")))
			continue;
		
		remove_quotes(szText)
			
		replace_all(szText, 127, "=", "")
		replace_all(szText, 127, "(", "")
		replace_all(szText, 127, ")", "")
		replace_all(szText, 127, ",", "")
		
		parse(szText, szData[0], 63, szData[1], 63, szData[2], 63, 
		szData[3], 63, szData[4], 63, szData[5], 63, szData[6], 63,
		szData[7], 63, szData[8], 63, szData[9], 63)
	
		/* Wczytywanie Konfiguracji */
		
		if(iWasConf > 0 && !LoadStandardConf) {
			
			
			if(equali(szData[0], "BASE_HEALTH")) {
				iWasConf --;
				set_pcvar_num(gCvarInfo[CVAR_BASE_HEALTH], str_to_num(szData[1]));
				giBaseHealth = str_to_num(szData[1])
				continue;
			}
			else if(equali(szData[0], "TIME_TO_WAVE")) {
				iWasConf --;
				set_pcvar_num(gCvarInfo[CVAR_TIME_TO_WAVE], str_to_num(szData[1]));
				continue;
			}
			else if(equali(szData[0], "MONSTER_DAMAGE")) {
				iWasConf --;
				set_pcvar_num(gCvarInfo[CVAR_MONSTER_DAMAGE], str_to_num(szData[1]));
				continue;
			}
			else if(equali(szData[0], "BOSS_DAMAGE")) {
				iWasConf --;
				set_pcvar_num(gCvarInfo[CVAR_BOSS_DAMAGE], str_to_num(szData[1]));
				continue;
			}
			else if(equali(szData[0], "TURRETS")){
				iWasConf --;
				gTurretsAvailable = str_to_num(szData[1])?true:false
				continue;
			}
			else if(equali(szData[0], "TOWER_MODEL")){
				iWasConf --;
				gModelTurret = str_to_num(szData[1])?true:false
				continue;
			}
			else if(equali(szData[0], "[LOAD_STANDARD_WAVE]")){
				iWasConf --;
				LoadStandardConf = 1
				LoadWave("standard_wave.ini")
				continue;
			}
			else if(equali(szData[0], "MAX_MAP_TURRETS")) {
				iWasConf --;
				MAX_MAP_TURRETS = clamp(str_to_num(szData[1]), 1, 100)
				continue;
			}
			
		}
		else
			iWasConf = 0
#if defined DEBUG
		if(iWasConf > 0) {
			gTurretsAvailable = false;
			log_to_file(gszLogFile, "DEBUG: File does not have all required commands.")
			log_to_file(gszLogFile, "DEBUG: Missing commands were replaced a standard params.")
			
			iWasConf = 0;
		}
#endif	
		/* Loading waves */
		
		static iWave, iOldWave, iNum;
		iWave = str_to_num(szData[0]);
		
		if(iWave > 0) {
			if(iWave != iOldWave && iWave-1 == iOldWave) {
				iOldWave = iWave
				if(equali(szData[1], "NORMAL")) {
					gWaveInfo[iWave][WAVE_ROUND_TYPE] = ROUND_NORMAL;
				} else if(equali(szData[1], "FAST")) {
					gWaveInfo[iWave][WAVE_ROUND_TYPE] = ROUND_FAST;
				} else if(equali(szData[1], "STRENGHT")) {
					gWaveInfo[iWave][WAVE_ROUND_TYPE] = ROUND_STRENGHT;
				} else if(equali(szData[1], "BOSS")) {
					gWaveInfo[iWave][WAVE_ROUND_TYPE] = ROUND_BOSS;
				} else if(equali(szData[1], "BONUS")) {
					gWaveInfo[iWave][WAVE_ROUND_TYPE] = ROUND_BONUS;
				} else {
					log_to_file(gszLogFile, "Incorrect round type! ^"%s^" | line: %d", szData[1], i)
					gGame = false
					return PLUGIN_CONTINUE
				}
				
				/* ================================= */
				
				
				iNum = str_to_num(szData[2]);
				
				if(iNum < 0 || (!is_special_wave(iWave) && iNum == 0) || iNum > MAX_MONSTERS) {
					log_to_file(gszLogFile, "Incorrect numbers of monster! ^"%d^" | line: %d", iNum, i)
					gGame = false
					return PLUGIN_CONTINUE
				}
				
				gWaveInfo[iWave][WAVE_MONSTER_NUM] = iNum;
				
				/* ================================= */
				
				iNum = str_to_num(szData[3]);
				if(iNum <= 0 && !is_special_wave(iWave)) {
					log_to_file(gszLogFile, "Incorrect HP value! ^"%d^" | line: %d", iNum, i)
					gGame = false
					return PLUGIN_CONTINUE
				}
				gWaveInfo[iWave][WAVE_MONSTER_HEALTH] = iNum
				
				/* ================================= */
				
				iNum = str_to_num(szData[4]);
				if(iNum <= 0 && !is_special_wave(iWave)) {
					log_to_file(gszLogFile, "Incorrect SPEED value! ^"%d^" | line: %d", iNum, i)
					gGame = false
					return PLUGIN_CONTINUE
				}
				gWaveInfo[iWave][WAVE_MONSTER_SPEED] = iNum
				
				/* ================================= */
				
				if(is_special_wave(iWave)) {	
					iNum = str_to_num(szData[5]);
					
					if(iNum <= 0) {
						log_to_file(gszLogFile, "Incorrect HP value [speccial wave]! ^"%d^" | line: %d", iNum, i)
						gGame = false
						return PLUGIN_CONTINUE
					}
					gWaveInfo[iWave][WAVE_SPECIAL_HEALTH] = iNum
					
					/* ================================= */
					
					iNum = str_to_num(szData[6]);
					if(iNum <= 0) {
						log_to_file(gszLogFile, "Incorrect SPEED value [speccial wave]! ^"%d^" | line: %d", iNum, i)
						gGame = false
						return PLUGIN_CONTINUE
					}
					
					gWaveInfo[iWave][WAVE_SPECIAL_SPEED] = iNum
					
					/* ================================= */
				}
				
				giWaveNum++;
				
				
			} else {
				log_to_file(gszLogFile, "Incorrect wave numver! Was ^"%d^", is ^"%d^". | line: %d", iOldWave, iWave, i)
				gGame = false
				return PLUGIN_CONTINUE
			}
		} 
		
	}
	

	return PLUGIN_CONTINUE
}

public LoadCvar() {
	log_amx("asd 5123131") 
#if defined DEBUG
	log_to_file(gszLogFile, "DEBUG: Loading cvar file configuration...")	
#endif
	if(file_exists(gszCvarConfigFile))
		server_cmd("exec %s",gszCvarConfigFile)
#if defined DEBUG
	else {
		log_to_file(gszLogFile, "DEBUG: Cvar file configuration is not exist...")
	}
	log_to_file(gszLogFile, "DEBUG: Loading cvar file configuration completed...")
#endif	
	
}

public LoadModels()//wczytuje modele
{
#if defined DEBUG
	log_to_file(gszLogFile, "DEBUG: Loading models file configuration...")
#endif

	new szText[128], len;
	new szTemp[4][128];
	new iNumber;
	
	if(!file_exists(gszModelsConfigFile))
	{
		log_to_file(gszLogFile, "Models file configuration is not exist...")
		gGame = false
		return PLUGIN_CONTINUE
	}
	for(new i ; read_file(gszModelsConfigFile, i, szText, 127, len) ; i++)
	{
		trim(szText);
		if(equali(szText, ";", 1) || !strlen(szText))
			continue;
			
		parse(szText, szTemp[0], 127, szTemp[1], 16, szTemp[2], 16, szTemp[3], 127)
		iNumber = str_to_num(szTemp[1]);
		
		if(equali(szTemp[0], "NORMAL_MDL")) 
			copy(gModels[iNumber-1][MODEL_NORMAL], 33, szTemp[3])
		else if(equali(szTemp[0], "FAST_MDL"))
			copy(gModels[iNumber-1][MODEL_FAST], 33, szTemp[3])
		else if(equali(szTemp[0], "STRENGHT_MDL"))		
			copy(gModels[iNumber-1][MODEL_STRENGHT], 33, szTemp[3])
		else if(equali(szTemp[0], "BONUS_MDL"))
			copy(gModels[iNumber-1][MODEL_BONUS], 33, szTemp[3])
		else if(equali(szTemp[0], "BOSS_MDL"))
			copy(gModels[iNumber-1][MODEL_BOSS], 33, szTemp[3])
		else if(equali(szTemp[0], "TOWER_MDL"))
			copy(gModels[iNumber-1][MODEL_TOWER], 33, szTemp[3])
		//else if(equali(szTemp[0], "PLAYER_MODEL_CT"))
	//		copy(gModels[iNumber-1][MODEL_PLAYER_CT], 33, szTemp[3])
//		else if(equali(szTemp[0], "PLAYER_MODEL_TT"))
//			copy(gModels[iNumber-1][MODEL_PLAYER_TT], 33, szTemp[3])
		//else if(equali(szTemp[0], "VIP_MODEL")) {
		//	copy(g_VipModel, charsmax(g_VipModel), szTemp[3]);
		//	log_amx(g_VipModel)
		//}
	}
#if defined DEBUG
	log_to_file(gszLogFile, "DEBUG: Loading models file configuration completed...")
#endif
	log_amx("asd 512321231232123")
	return PLUGIN_CONTINUE
	
}

/*
new ciTime;
new ciColor[3]
new Float:cfPosition[2];
new ciEffect;
new ciMode;
new ciChannel;
new cszText[64];
new ciNum
new giSec

stock set_countdown(id, szText[], iColor[3], Float:posX, Float:posY, iEffect = 0, tTime, iMode = 1, channel = 4, const szFunction[] = "", ifParam[] = "", ifLen = 0)
{
	
	
		iMode = 0 	|| Czas odlicza od 0 do tTime
		iMode == 1 	|| Czas odlicza od tTime do 0
		
	

	ciNum = formatex(cszText, strlen(szText), szText);
	ciTime = tTime;
	ciColor = iColor;
	cfPosition[0] = posX
	cfPosition[1] = posY
	ciEffect = iEffect
	ciMode = iMode;
	ciChannel = channel;	
	display_countdown(id+TASK_COUNTDOWN)
	
	if(gCvarValue[COUNTDOWN_MODE] == 2)
		set_countdownhud(tTime+1)
		
	if(gCvarValue[COUNTDOWN_MODE] == 2 && iMode == 0)
		set_fail_state("Nieprawidlowe uzycie set_countdown, zla wartosc cvara, badz iMode")
		
	if(strlen(szFunction) > 0)
		set_task(float(tTime), szFunction, TASK_COUNTDOWN_FUNCTION, ifParam, ifLen);
	// ciTime - giSec = ile zostalo do wykonania taska
}

public display_countdown(id)
{
	static gszSec[6];
	id-=TASK_COUNTDOWN

	if(giSec >= ciTime) {		
		remove_task(TASK_COUNTDOWN);
		remove_task(id+TASK_COUNTDOWN);
		giSec = 0;
		ciTime = 0
		ciColor = {0, 0, 0}
		cfPosition[0] = 0.0
		cfPosition[1] = 0.0
		ciEffect = 0
		ciMode = 0
		ciChannel = 0
		return PLUGIN_CONTINUE
	}
	if(gCvarValue[COUNTDOWN_MODE] == 1 || containi(cszText, "zostanie"))
	{
		if(ciMode == 1){
			formatex(gszSec, 5, "%d", ciTime-giSec);
			add(cszText, 64,  gszSec);
		} else if(ciMode == 0) {
			formatex(gszSec, 5, "%d", giSec);
			add(cszText, 64,  gszSec);
		}
		
		set_hudmessage(ciColor[0], ciColor[1], ciColor[2], cfPosition[0], cfPosition[1], ciEffect, 6.0, 1.1, _, _, ciChannel)
		show_hudmessage(id, cszText)
		
		formatex(cszText[ciNum], ciNum, "")
		formatex(cszText[ciNum+1], ciNum, "")
		formatex(cszText[ciNum+2], ciNum, "")
		formatex(cszText[ciNum+3], ciNum, "")
	}
		
	if(!gWaveIsStarted && gGame) {
		new iCount = 3;
		if((ciTime-giSec) <= 5 && (ciTime-giSec) >= 1) {
			client_cmd(0, "spk sound/%s", gSounds[SOUND_COUNTDOWN]);
		} else if((ciTime-giSec) > 5 && (giSec%iCount) == 0) {
			client_cmd(0, "spk sound/%s", gSounds[SOUND_COUNTDOWN]);
		}
	}
	giSec++;
	set_task(1.0, "display_countdown", id+TASK_COUNTDOWN);
	return PLUGIN_CONTINUE
}
*/
stock GivePlayerAmmo(id, liczba){
	if(is_user_alive(id) && is_user_connected(id) && !is_user_hltv(id)){
		new weapon = get_user_weapon(id)
		if(weapon != 29) {
			cs_set_user_bpammo(id, weapon, cs_get_user_bpammo(id, weapon)+liczba);
		}
		if(cs_get_user_bpammo(id, weapon) > giMaxAmmo[weapon]) {
			cs_set_user_bpammo(id, weapon, giMaxAmmo[weapon])
		}
	}
}

public ResetGame(iMode, Float:fTime) {
	if(gGame) {
		new iRet;
		ExecuteForward(gForward[FORWARD_RESET_GAME], iRet, iMode, fTime)
		
		if(iRet)
			return iRet
		
		for(new i ; i <= MAX_MONSTERS+1 ; i++)
			remove_task(i + TASK_SEND_MONSTER)
				
		giWave = 0
		if(giBaseHealth < gCvarValue[BASE_HEALTH])
			_td_set_tower_health(1, gCvarValue[BASE_HEALTH]-giBaseHealth, 0)
			
		RemoveMonsters()
		giMonsterAlive = 0
		giSendsMonster = 0
		gWaveIsStarted = false
		gGameIsStarted = false
		gPlayersAreReady = false
		gOnePlayerMode = false	
		remove_task(TASK_DAMAGE_EFFECT)
		remove_task(TASK_COUNTDOWN);
		remove_task(TASK_COUNTDOWN_FUNCTION)
		remove_task(TASK_GAME_FALSE)
		remove_task(TASK_KILL_MONSTER)
		remove_task(TASK_MONSTER_DEATH)
		remove_task(TASK_SEND_MONSTER)
		remove_task(TASK_PRE_SEND_MONSTER)
		remove_task(TASK_START_WAVE)
		
		for(new i=1; i <= giMaxPlayers;i++) {
			remove_task(i+TASK_COUNTDOWN);
			ResetPlayerInformation(i)
		}
		if(iMode)
			set_task(fTime, "StartWave", TASK_START_WAVE)
	}
	return PLUGIN_CONTINUE
}
public SayText(msgid, msgdest, msgentity) {
	new Marg[32]
	get_msg_arg_string(2, Marg, 31)
	if( equal(Marg, "#Cstrike_Name_Change")) {
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}
stock entity_set_aim(ent1, ent2, Float:offset2[3], region) {
	if(!is_valid_ent(ent1) || !is_valid_ent(ent2) || ent1 == ent2)
		return 0;
	
	static Float:offset[3]
	offset[0] = offset2[0],
	offset[1] = offset2[1],
	offset[2] = offset2[2]
	static Float:ent1origin[3]
	static Float:ent2origin[3]
	static Float:view_angles[3]
	
	entity_get_vector(ent2,EV_VEC_origin,ent2origin)
	
	if(ent1>32) 
		entity_get_vector(ent1,EV_VEC_origin,ent1origin)
	else {
		new origin[3]
		get_user_origin(ent1,origin,1)
		IVecFVec(origin,ent1origin)
	}
		
	switch(region) {
		case 1:offset[2] += 30.173410
		case 2:offset[2] += 17.271676
		case 3:{
			offset[0] += 12.000000
			offset[2] += 11.028901
		}
		case 4:{
			offset[0] += -12.000000
			offset[2] += 11.028901
		}
		case 5:{
			offset[0] += 8.000000
			offset[2] += -19.768786
		}
		case 6:{
			offset[0] += -8.000000
			offset[2] += -19.768786
			
		}
	}
	
	static Float:ent2_angles[3]
	entity_get_vector(ent2,EV_VEC_v_angle,ent2_angles)
	ent2origin[0] += offset[0] * (((floatabs(ent2_angles[1]) - 90) / 90) * -1)
	ent2origin[1] += offset[1] * (1 - (floatabs(90 - floatabs(ent2_angles[1])) / 90))
	ent2origin[2] += offset[2]
	
	ent2origin[0] -= ent1origin[0]
	ent2origin[1] -= ent1origin[1]
	ent2origin[2] -= ent1origin[2]
	
	static Float:hyp
	hyp = floatsqroot( (ent2origin[0] * ent2origin[0]) + (ent2origin[1] * ent2origin[1]))
	
	static x, y, z
	x=0, y=0, z=0
	
	if(ent2origin[0]>=0.0) 
		x=1
	if(ent2origin[1]>=0.0) 
		y=1
	if(ent2origin[2]>=0.0) 
		z=1
	
	if(ent2origin[0]==0.0) 
		ent2origin[0] = 0.000001
	if(ent2origin[1]==0.0) 
		ent2origin[1] = 0.000001
	if(ent2origin[2]==0.0) 
		ent2origin[2] = 0.000001
	
	ent2origin[0]=floatabs(ent2origin[0])
	ent2origin[1]=floatabs(ent2origin[1])
	ent2origin[2]=floatabs(ent2origin[2])
	
	view_angles[1] = floatatan2(ent2origin[1],ent2origin[0],degrees)
	
	//1=positive 0=negative
	if(x && !y) 
		view_angles[1] = -1 * ( 180 - view_angles[1] )
	if(!x && !y) 
		view_angles[1] = ( 180 - view_angles[1] )
	if(!x && y) 
		view_angles[1] = view_angles[1] = 180 + floatabs(180 - view_angles[1])
	if(x && !y) 
		view_angles[1] = view_angles[1] = 0 - floatabs(-180 - view_angles[1])
	if(!x && !y) 
		view_angles[1] *= -1
	
	while(view_angles[1]>180.0) 
		view_angles[1] -= 180
	while(view_angles[1]<-180.0) 
		view_angles[1] += 180
	if(view_angles[1]==180.0 || view_angles[1]==-180.0) 
		view_angles[1]=-179.999999
	
	view_angles[0] = floatasin(ent2origin[2] / hyp,degrees)
	
	if(z) 
		view_angles[0] *= -1

	entity_set_int(ent1,EV_INT_fixangle,1)
	entity_set_vector(ent1,EV_VEC_v_angle,view_angles)
	entity_set_vector(ent1,EV_VEC_angles,view_angles)
	entity_set_int(ent1,EV_INT_fixangle,1)
	
	return 1;
}

public getClossestMonster(ent)
{
	if(!td_is_monster(ent) )
		return 0;
		
	new entlist[3]
	new num = find_sphere_class(ent, "monster", 30.0, entlist, 2)
	
	if(!num)
		return 0
		
	if(!is_valid_ent(entlist[1]) || !entity_get_int(entlist[1], EV_INT_monster_type))
		return 0;
	return entlist[1];

}

stock fx_blood(origin[3], size){ //efekt krwi
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0]+random_num(-20,20))
	write_coord(origin[1]+random_num(-20,20))
	write_coord(origin[2]+random_num(-20,20))
	write_short(giSpriteBloodSpray)
	write_short(giSpriteBloodDrop)
	write_byte(229) // color index
	write_byte(size) // size
	message_end()
}
stock set_glow(id, r,g,b, width)
	set_rendering(id, kRenderFxGlowShell, r, g, b, kRenderNormal, width)
	
public Explode(){  //wybuch nad wieza 
	new Origin[3]
	FVecIVec(gfTowerOrigin, Origin)
	Origin[2]+= 275 // wysokoc wybuchu nad wieza
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(Origin[0])	// start position
	write_coord(Origin[1])
	write_coord(Origin[2])
	write_short(giSpriteExplode)	// sprite index
	write_byte(50)	// scale in 0.1's
	write_byte(10)	// framerate
	write_byte(0)	// flags
	message_end()
}
stock Create_Lighting(startEntity, endEntity, startFrame, frameRate, life, width, noise, red, green, blue, alpha, speed) {
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_BEAMENTS )
	write_short( startEntity )              // start entity
	write_short( endEntity )                // end entity
	write_short( giSpriteLighting )                  // model
	write_byte( startFrame )                // starting frame
	write_byte( frameRate )                 // frame rate
	write_byte( life )                              // life
	write_byte( width )                             // line width
	write_byte( noise )                             // noise amplitude
	write_byte( red )                               // red
	write_byte( green )                             // green
	write_byte( blue )                              // blue
	write_byte( alpha )                             // brightness
	write_byte( speed )                             // scroll speed
	message_end()
}
stock msg_implosion(id, Origin[3],  radius, numbers, time_) { // efekt 
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY, Origin, id) //message begin
	write_byte(TE_IMPLOSION)
	write_coord(Origin[0]) // start position
	write_coord(Origin[1])
	write_coord(Origin[2])
	write_byte(radius) // radius
	write_byte(numbers) // count
	write_byte(time_*10) // life in 1's
	message_end()
	
}

/* =========================================== */
/*                   NATYWY 		       */
/* =========================================== */



public _td_shop_register_item(const szName[], const szDescription[], iPrice, iOnePerMap, plugin_index) {
	
	if(giShopItemsNum+1 > MAX_SHOP_ITEMS)
		return PLUGIN_CONTINUE
		
	giShopItemsNum++
	
	param_convert(1)
	param_convert(2)
	
	formatex(giShopItemsName[giShopItemsNum], 63, szName)
	formatex(giShopItemsDesc[giShopItemsNum], 127, szDescription)

	giShopItemsPrice[giShopItemsNum] = iPrice
	giShopOnePerMap[giShopItemsNum] = iOnePerMap

	setItemInfo(plugin_index, giShopItemsNum)
	
	return giShopItemsNum;
}

public _td_register_class(const szClassName[], const szDescription[], plugin_index) {
	
	if(giClassNum+1 > MAX_CLASS)
		return PLUGIN_CONTINUE
		
	giClassNum++
	
	param_convert(1)
	param_convert(2)
	
	formatex(gszClassName[giClassNum], 32, szClassName)
	formatex(gszClassDescription[giClassNum], 127, szDescription)
	
	setClassInfo(plugin_index, giClassNum)

	return giClassNum;
}

public setItemInfo(iPluginIndex, iShopIndex) {
	new szFile[45]
	new szTitle[8]
	new szVersion[8]
	new szAuthor[8]
	new szStatus[8]
	new szText[150];
	new szIndex[45];
	new len
	
	new bool:iFound;
	enum {
		NOT_FIND,
		CHECK_NAME,
		CHECK_DESCRIPTION,
		CHECK_PRICE,
		CHECK_ONE_PER_MAP,
		CHECKED
	}

	get_plugin(iPluginIndex, szFile, 31, szTitle, 7, szVersion, 7, szAuthor, 7, szStatus, 7);
	
	new iStatus = NOT_FIND;

	replace_all(szFile, charsmax(szFile), ".amxx", "");
	replace_all(szFile, charsmax(szFile), ".amx", "");
	
	formatex(szIndex, charsmax(szIndex), "[%s]", szFile);
	
	for(new i; read_file(gszShopConfigFile, i, szText, 149, len) ; i++) {
		trim(szText);
		if(szText[0] == ';' || (equali(szText, "")))
			continue;
			
		replace_all(szText, 149, "=", "")
		
		if(equali(szText, szIndex) && !iFound && iStatus == NOT_FIND) {
			iFound = true
			iStatus = CHECK_NAME
			continue;
		}

		/* Jesli znalazlo przedmiot w pliku, wczytaj wartosci */
		if(iFound) {
			new szCommand[33], szInfo[128];
			parse(szText, szCommand, 32, szInfo, 127);
			
			if(iStatus == CHECK_NAME) {
				static szTemp[64];
				static bool:iMulti;
				
				if(equali(szCommand, "NAME") && !iMulti) {
					replace(szText, 127, szCommand, "");
					trim(szText)
					if(szText[0] == '^"'){
						if(szText[strlen(szText)-1] == '^"') {
							remove_quotes(szText);
							formatex(giShopItemsName[iShopIndex], 63, szText)
						}
						else {
#if defined DEBUG
							log_to_file(gszLogFile, "DEBUG: [This is only warning] Item ^"%s^" in shop configuration file have name consisting of several lines.", szFile)
#endif	
							iMulti = true;
							remove_quotes(szText);
							formatex(szTemp, 63, "%s", szText)
							continue;
						}
						
					}
					else {
#if defined DEBUG
						log_to_file(gszLogFile, "DEBUG: Item ^"%s^" in shop configuration file does not have initial quoted mark.", szFile)
#endif		
					}
					
				}
				else if(iMulti) {
					if(szText[strlen(szText)-1] == '^"')
						iMulti = false;
					format(szText, 63, " %s", szText)
					add(szTemp, 63, szText, 63)

					if(!iMulti) {
						remove_quotes(szTemp)
						formatex(giShopItemsName[iShopIndex], 63, szTemp)
					}
					else {
						continue;
					}
				}
				else {
				
#if defined DEBUG
					log_to_file(gszLogFile, "DEBUG: Item ^"%s^" w pliku konfiguracyjnym sklepu nie zawiera komendy definiujacej nazwe (^"NAME^"). Wczytuje domyslna.", szFile)
#endif					
				}
				iStatus = CHECK_DESCRIPTION;
				continue;
			}
			else if(iStatus == CHECK_DESCRIPTION) {
				static szTemp[128];
				static bool:iMulti;
				
				if(equali(szCommand, "DESCRIPTION") && !iMulti) {
					replace(szText, 127, szCommand, "");
					trim(szText)
					if(szText[0] == '^"'){
						if(szText[strlen(szText)-1] == '^"') {
							remove_quotes(szText);
							formatex(giShopItemsDesc[iShopIndex], 127, szText)
						}
						else {
#if defined DEBUG
							log_to_file(gszLogFile, "DEBUG: [To nie musi by� b��d] Przedmiot ^"%s^" w pliku konfiguracyjnym sklepu zawiera opis skladajacy sie z kilku linijek.", szFile)
#endif	
							iMulti = true;
							remove_quotes(szText);
							formatex(szTemp, 127, "%s", szText)
							continue;
						}
						
					}
					else {
#if defined DEBUG
						log_to_file(gszLogFile, "DEBUG: Przedmiot ^"%s^" w pliku konfiguracyjnym sklepu nie zawiera cudzyslowu poczatkowego w opisie.", szFile)
#endif		
					}
					
				}
				else if(iMulti) {
					if(szText[strlen(szText)-1] == '^"')
						iMulti = false;
					format(szText, 127, " %s", szText)
					add(szTemp, 127, szText, 127)

					if(!iMulti) {
						remove_quotes(szTemp)
						formatex(giShopItemsDesc[iShopIndex], 127, szTemp)
					}
					else {
						continue;
					}
				}
				else {
				
#if defined DEBUG
					log_to_file(gszLogFile, "DEBUG: Przedmiot ^"%s^" w pliku konfiguracyjnym sklepu nie zawiera komendy definiujacej opis (^"DESCRIPTION^"). Wczytuje domyslna.", szFile)
#endif					
				}
				iStatus = CHECK_PRICE;
				continue;
			}
			else if(iStatus == CHECK_PRICE) {
				if(equali(szCommand, "PRICE")) {
					new iNum = str_to_num(szInfo);
					if(iNum < 0 || iNum > 999999) {
#if defined DEBUG
						log_to_file(gszLogFile, "DEBUG: Przedmiot ^"%s^" w pliku konfiguracyjnym sklepu zawiera niepoprawna wartosc definiujaca cene (^"PRICE = %d^"). Wczytuje domyslna wartosc.", szFile, iNum)
#endif
					} else {
						giShopItemsPrice[iShopIndex] = str_to_num(szInfo)
					}
				}
				else {
#if defined DEBUG
					log_to_file(gszLogFile, "DEBUG: Przedmiot ^"%s^" w pliku konfiguracyjnym sklepu nie zawiera komendy definiujacej cene (^"PRICE^"). Wczytuje domyslna wartosc.", szFile)
#endif					
				}
				iStatus = CHECK_ONE_PER_MAP;
				continue;
			}
			else if(iStatus == CHECK_ONE_PER_MAP) {
				if(equali(szCommand, "ONE_PER_MAP")) {
					if(equali(szInfo, "yes") || equali(szInfo, "true"))
						giShopOnePerMap[iShopIndex] = 1
					else if(equali(szInfo, "no") || equali(szInfo, "false"))
						giShopOnePerMap[iShopIndex] = 0
					else {
#if defined DEBUG
					log_to_file(gszLogFile, "DEBUG: Przedmiot ^"%s^" w pliku konfiguracyjnym sklepu zawiera niepoprawna watosc definiujaca zmienna (^"ONE_PER_MAP = %s^" | Dopuszczalne wartosci: yes, true, false, no). Wczytuje domyslna wartosc.", szFile)
#endif	
					}	
				}
				else {
#if defined DEBUG
					log_to_file(gszLogFile, "DEBUG: Przedmiot ^"%s^" w pliku konfiguracyjnym sklepu nie zawiera komendy definiujacaj zmienna (^"ONE_PER_MAP^"). Wczytuje domyslna wartosc.", szFile)
#endif					
				}
				iStatus = CHECKED;
				break;
			}
		}
	}
		
		/* Dopisz do pliku przedmiot */
	if(!iFound) {
#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Przedmiot ^"%s^" w pliku konfiguracyjnym sklepu nie zostal znaleziony. Trwa dopisywanie do pliku", szFile)
#endif
	
		write_file(gszShopConfigFile, "", -1)
		write_file(gszShopConfigFile, szIndex, -1)
			
		formatex(szText, 149, "NAME = ^"%s^"", giShopItemsName[iShopIndex])
		write_file(gszShopConfigFile, szText, -1)
			
		formatex(szText, 149, "DESCRIPTION = ^"%s^"", giShopItemsDesc[iShopIndex])
		write_file(gszShopConfigFile, szText, -1)
			
		formatex(szText, 149, "PRICE = %d", giShopItemsPrice[iShopIndex] )
		write_file(gszShopConfigFile, szText, -1)

		formatex(szText, 149, "ONE_PER_MAP = %s", giShopOnePerMap[iShopIndex] ? "true":"false");
		write_file(gszShopConfigFile, szText, -1)
	}
}

public setClassInfo(iPluginIndex, iClassIndex) {
	new szFile[45]
	new szTitle[8]
	new szVersion[8]
	new szAuthor[8]
	new szStatus[8]
	new szText[150];
	new szIndex[45];
	new len
	
	new bool:iFound;
	enum {
		NOT_FIND,
		CHECK_NAME,
		CHECK_DESCRIPTION,
		CHECKED
	}

	get_plugin(iPluginIndex, szFile, 31, szTitle, 7, szVersion, 7, szAuthor, 7, szStatus, 7);
	
	new iStatus = NOT_FIND;

	replace_all(szFile, charsmax(szFile), ".amxx", "");
	replace_all(szFile, charsmax(szFile), ".amx", "");
	
	formatex(szIndex, charsmax(szIndex), "[%s]", szFile);
	
	for(new i; read_file(gszClassConfigFile, i, szText, 149, len) ; i++) {
		trim(szText);
		if(szText[0] == ';' || (equali(szText, "")))
			continue;
			
		replace_all(szText, 149, "=", "")
		
		if(equali(szText, szIndex) && !iFound && iStatus == NOT_FIND) {
			iFound = true
			iStatus = CHECK_NAME
			continue;
		}

		/* If found a value, sets a params */
		if(iFound) {
			new szCommand[33], szInfo[128];
			parse(szText, szCommand, 32, szInfo, 127);
			
			if(iStatus == CHECK_NAME) {
				static szTemp[64];
				static bool:iMulti;
				
				if(equali(szCommand, "NAME") && !iMulti) {
					replace(szText, 127, szCommand, "");
					trim(szText)
					if(szText[0] == '^"'){
						if(szText[strlen(szText)-1] == '^"') {
							remove_quotes(szText);
							formatex(gszClassName[iClassIndex], 63, szText)
						}
						else {
#if defined DEBUG
							log_to_file(gszLogFile, "DEBUG: [To nie musi by� blad] Klasa ^"%s^" w pliku konfiguracyjnym klas gracza zawiera nazwe skladajaca sie z kilku linijek.", szFile)
#endif	
							iMulti = true;
							remove_quotes(szText);
							formatex(szTemp, 63, "%s", szText)
							continue;
						}
						
					}
					else {
#if defined DEBUG
						log_to_file(gszLogFile, "DEBUG: Klasa ^"%s^" w pliku konfiguracyjnym klas gracza nie zawiera cudzyslowu poczatkowego w nazwie.", szFile)
#endif		
					}
					
				}
				else if(iMulti) {
					if(szText[strlen(szText)-1] == '^"')
						iMulti = false;
					format(szText, 63, " %s", szText)
					add(szTemp, 63, szText, 63)

					if(!iMulti) {
						remove_quotes(szTemp)
						formatex(gszClassName[iClassIndex], 63, szTemp)
					}
					else {
						continue;
					}
				}
				else {
				
#if defined DEBUG
					log_to_file(gszLogFile, "DEBUG: Klasa ^"%s^" w pliku konfiguracyjnym klas gracza nie zawiera komendy definiujacej nazwe (^"NAME^"). Wczytuje domyslna.", szFile)
#endif					
				}
				iStatus = CHECK_DESCRIPTION;
				continue;
			}
			else if(iStatus == CHECK_DESCRIPTION) {
				static szTemp[128];
				static bool:iMulti;
				
				if(equali(szCommand, "DESCRIPTION") && !iMulti) {
					replace(szText, 127, szCommand, "");
					trim(szText)
					if(szText[0] == '^"'){
						if(szText[strlen(szText)-1] == '^"') {
							remove_quotes(szText);
							formatex(gszClassDescription[iClassIndex], 127, szText)
						}
						else {
#if defined DEBUG
							log_to_file(gszLogFile, "DEBUG: [To nie musi by� blad] Klasa ^"%s^" w pliku konfiguracyjnym klas gracza zawiera opis skladajacy sie z kilku linijek.", szFile)
#endif	
							iMulti = true;
							remove_quotes(szText);
							formatex(szTemp, 127, "%s", szText)
							continue;
						}
						
					}
					else {
#if defined DEBUG
						log_to_file(gszLogFile, "DEBUG: Klasa ^"%s^" w pliku konfiguracyjnym klas gracza nie zawiera cudzyslowu poczatkowego w opisie.", szFile)
#endif		
					}
					
				}
				else if(iMulti) {
					if(szText[strlen(szText)-1] == '^"')
						iMulti = false;
					format(szText, 127, " %s", szText)
					add(szTemp, 127, szText, 127)

					if(!iMulti) {
						remove_quotes(szTemp)
						formatex(gszClassDescription[iClassIndex], 127, szTemp)
					}
					else {
						continue;
					}
				}
				else {
				
#if defined DEBUG
					log_to_file(gszLogFile, "DEBUG: Przedmiot ^"%s^" w pliku konfiguracyjnym sklepu nie zawiera komendy definiujacej opis (^"DESCRIPTION^"). Wczytuje domyslna.", szFile)
#endif					
				}
				iStatus = CHECKED;
				break;
			}		
		}
	}
		
		/* Save to file a class if not found*/
	if(!iFound) {
#if defined DEBUG
		log_to_file(gszLogFile, "DEBUG: Klasa ^"%s^" w pliku konfiguracyjnym klas gracza nie zostala znaleziony. Trwa dopisywanie do pliku", szFile)
#endif
	
		write_file(gszClassConfigFile, "", -1)
		write_file(gszClassConfigFile, szIndex, -1)
			
		formatex(szText, 149, "NAME = ^"%s^"", gszClassName[iClassIndex])
		write_file(gszClassConfigFile, szText, -1)
			
		formatex(szText, 149, "DESCRIPTION = ^"%s^"", gszClassDescription[iClassIndex])
		write_file(gszClassConfigFile, szText, -1)		
	}
}

public _td_get_prefix(szDest[], len) {
	param_convert(1)
	copy(szDest, len, gszPrefix)
}

public td_is_monster(ent) {
	if(!is_valid_ent(ent))
		return 0
	new szClassname[24];
	entity_get_string(ent, EV_SZ_classname, szClassname, 23);
	if(equal(szClassname, "monster"))
		return 1;
	return 0
}
public td_is_healthbar(ent) {
	if(!is_valid_ent(ent))
		return 0;
	new szClassname[24];
	entity_get_string(ent, EV_SZ_classname, szClassname, 23);
	if(equal(szClassname, "monster_healtbar"))
		return 1;
	return 0
}
public is_special_monster(ent) {
	if(!is_valid_ent(ent))
		return 0
	if(entity_get_int(ent, EV_INT_monster_type) == _:ROUND_BOSS || entity_get_int(ent, EV_INT_monster_type) == _:ROUND_BONUS)
		return 1
	return 0;
}
public is_special_wave(iWave) {
	if(MAX_WAVE > iWave > 0) {
		
		if(gWaveInfo[iWave][WAVE_ROUND_TYPE] == ROUND_BOSS){
			return 1;
		}
		else if(gWaveInfo[iWave][WAVE_ROUND_TYPE] == ROUND_BONUS) {
			return 2;
		}
	}
	
	return 0;
}


public set_countdownhud(iTime){
	message_begin(MSG_ALL, get_user_msgid("RoundTime"), _, 0);
	write_short(iTime);
	message_end();
}

public _td_update_tower_origin(iMode, Float:fDamage, iExplode) {
	if(gModelTurret && (iMode == 0 || iMode == 1)) {
		new iTower
		new Float:szMax = float( gCvarValue[BASE_HEALTH]) 	
		new Float:fValue
		
		iTower = find_ent_by_class(0, "tower");
			
		fValue = ( szMax / fDamage )
		if(iMode == 0)
			gfTowerOrigin[2] -= ( 225.0 / fValue )
		else if(iMode == 1)
			gfTowerOrigin[2] += ( 225.0 / fValue )
		if(iExplode)
			Explode()
			
		entity_set_vector(iTower,EV_VEC_origin,  gfTowerOrigin)
	}
}
public eGame:_td_get_game_status()
	return gGame?GAME_AVAILABLE:GAME_NOT_AVAILABLE

public _td_set_game_status(eGame:iStatus) {
	if(iStatus == GAME_NOT_AVAILABLE)
		gGame = false
	else if(iStatus == GAME_AVAILABLE)
		gGame = true
	CheckGamePossibility()
}


public _td_get_wave()
	return giWave
public _td_set_wave(wave)
	giWave = wave
public _td_get_wavenum()
	return giWaveNum
	

public _td_get_wave_info(iWave, e_WaveInfo:iInfo) {
	if(iWave > giWaveNum || iWave <= 0)
		return 0
	if(iInfo == WAVE_MONSTER_NUM)
		return is_special_wave(iWave)?gWaveInfo[iWave][WAVE_MONSTER_NUM]+1:gWaveInfo[iWave][WAVE_MONSTER_NUM]

	return gWaveInfo[iWave][iInfo]
}
public _td_set_wave_info(iWave, e_WaveInfo:iInfo, _:iValue) {
	if(iWave > giWaveNum || iWave <= 0)
		return;
	
	gWaveInfo[iWave][iInfo] = iValue;
	
}

public _td_get_user_info(id, e_Player:iInfo) {
	if(is_user_connected(id)) 
		return gPlayerInfo[id][iInfo]
	return 0
}

public _td_set_user_info(id, e_Player:iInfo, iValue) {
	if(is_user_connected(id)) {
		gPlayerInfo[id][iInfo] = iValue
		if(iInfo == PLAYER_FRAGS)
			CheckPlayerLevel(id)
	}
}

public _td_get_max_wave()
	return MAX_WAVE

public _td_get_max_level()
	return MAX_LEVEL-1

public _td_get_max_monsters()
	return MAX_MONSTERS

public _td_get_monster_type(iEnt) {
	if(is_valid_ent(iEnt))
		return e_RoundType:entity_get_int(iEnt, EV_INT_monster_type) 
	return ROUND_NONE
}

public _td_get_monster_health(iEnt) {
	if(is_valid_ent(iEnt))
		return floatround(entity_get_float(iEnt, EV_FL_health))
	return 0
}

public _td_get_monster_healthbar(iEnt) {
	if(is_valid_ent(iEnt) && is_valid_ent(entity_get_edict(iEnt, EV_ENT_monster_healthbar)))
		return entity_get_edict(iEnt, EV_ENT_monster_healthbar)
	return 0
}

public _td_get_start_origin(Float:out[3]) 
	set_array_f(1, gfStartOrigin, 3)

public _td_get_end_origin(Float:out[3]) 
	set_array_f(1, gfEndOrigin, 3)

public _td_remove_monsters() 
	RemoveMonsters()

public _td_remove_tower() {
	if(gModelTurret)
		RemoveTower() 
	else
		return 0;
	return 1;
}
public _td_set_tower_health(iMode, iHealth, iExplode) {
	if(iHealth > gCvarValue[BASE_HEALTH] || iHealth <= 0 || (iMode != 0 && iMode != 1))
		return
		
	if(iMode == 1 && giBaseHealth + iHealth > gCvarValue[BASE_HEALTH])
		return
	if(iMode == 0 && giBaseHealth - iHealth < 0)
		return
	
	if(iMode == 1)
		giBaseHealth += iHealth
	else if(iMode == 0)
		giBaseHealth -= iHealth
	
	if(giBaseHealth <= 0)
		EndGame(PLAYERS_LOSE)
	
	_td_update_tower_origin(iMode, float(iHealth), iExplode)
}
public _td_get_tower_health() {
	return giBaseHealth
}

public _td_get_max_tower_health() {
	return gCvarValue[BASE_HEALTH]
}

public e_EndType:_td_get_end_status() {
	if(!gWaveIsStarted && !gGame  && giWave != 1) {
		return PLAYERS_LOSE
	}
		
	return PLAYERS_WIN
}
	
public _td_get_round_name(e_RoundType:iRoundType, szOutpout[], len) {
	param_convert(2)
	copy(szOutpout, len, gszRoundName[iRoundType])
}

public _get_vip_model(szModel[], len) {
	param_convert(1)
	copy(szModel, len, g_VipModel);
}

public _td_get_max_map_turrets()
	return MAX_MAP_TURRETS
	
fm_set_user_money( id, Money, effect = 1) {
	static s_msgMoney
	if(!s_msgMoney) 
		s_msgMoney = get_user_msgid("Money")
	
	set_pdata_int( id, 115, Money )
	
	emessage_begin( MSG_ONE, s_msgMoney, _, id )
	ewrite_long( Money )
	ewrite_byte( effect )
	emessage_end()
}

public Function()
{
	
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
