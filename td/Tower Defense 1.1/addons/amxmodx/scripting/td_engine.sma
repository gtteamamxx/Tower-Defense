/*
	1 - g_PlayerShowHitCrosshair
	2 - WIN/LOSE GAME prize
	3 - forward takedamagepost
	4 - bug fixes with chat prefix / loading level / fix crosshair hit effect
	5 - changed forward takedamage from take_amage to take_damage in plugin init
*/

#include <amxmodx>
#include <td_const>
#include <engine>
#include <fakemeta_util>
#include <cstrike>
#include <colorchat>
#include <hamsandwich>
#include <nvault_util>

/*  More allocation memory in plugin */
#pragma dynamic 131072 

#define PLUGIN 				"Tower Defense Mod"
#define VERSION 			"1.1 Rebuild"
#define AUTHOR 				"tomcionek15 & grs4"

#define CHAT_PREFIX			"[TD]"
#define LOG_FILE			"Tower Defense.log"

#define NVAULT_FILE_NAME		"TowerDefense"
#define CONFIG_FILE			"addons/amxmodx/configs/td_config.cfg"
#define MODELS_CONFIG_FILE		"addons/amxmodx/configs/td_models.cfg"
#define SOUNDS_CONFIG_FILE		"addons/amxmodx/configs/td_sounds.cfg"
#define CFG_CONFIG_FILE			"addons/amxmodx/configs/td_cvars.cfg"
#define SHOP_CONFIG_FILE		"addons/amxmodx/configs/td_shop.cfg"
#define MAP_CONFIG_FILE			"addons/amxmodx/configs/maps-td.cfg"
#define SPAWN_SPRITE			"sprites/TD/spawn.spr"

#define MAX_WAVES 				200
#define MAX_MONSTERS_PER_WAVE 	40
#define MAX_SHOP_ITEMS 			50

//#define DEBUG

/* Do not change it */
#define EV_INT_monster_type		EV_INT_iuser1
#define EV_INT_monster_track		EV_INT_iuser2
#define EV_INT_monster_maxhealth	EV_INT_iuser3
#define EV_INT_monster_speed		EV_INT_iuser4
#define EV_ENT_monster_healthbar	EV_ENT_euser1
#define EV_ENT_monster_headshot		EV_ENT_euser2
#define EV_ENT_monster_premium		EV_ENT_euser4
#define EV_INT_monster_maxspeed		EV_INT_team

#define EV_INT_grenade_type 		EV_INT_iuser1
#define EV_INT_grenade_ammo 		EV_INT_iuser2
#define EV_INT_startzone_entity 	EV_INT_iuser1
#define EV_INT_repairzone_entity 	EV_INT_iuser1
#define EV_INT_mapvote_header 		EV_INT_iuser1
#define EV_INT_mapvote_index 		EV_INT_iuser2

/* For stable for, do not change it now */
#define MAX_MAP		16
#define VOTE_MAP_COUNT 	3
#define LAST_MAPS_SAVE 	1

new bool:DEBUG = false;

new Float:g_StartZoneCoordinations[3][3];

/* Default values of zones */
new g_StartZoneWidth = 100;
new g_StartZoneLength = 100;

new g_RepairZoneWidth = 30;
new g_RepairZoneLength = 30;

/* === */

new g_SpriteFlame
new g_SpriteSmoke
new g_SpriteTrail

new g_IsGameEnded;
new bool:g_IsGameStarted;
new bool:g_IsGamePossible;
new bool:g_IsTowerModelOnMap;
new bool:g_AreTurretsEnabled;
new bool:g_isGunModEnabled;
new bool:g_CanPlayerWalk;
new bool:g_IsBonusThief;

new Float:g_BonusThiefRange;
new g_BonusRobbedGold;

new g_TowerUpgradingPlayerIndex;

//new gszClassConfigFile[] = "addons/amxmodx/configs/td_player_class.cfg";

new g_HealthbarsSprite[4][] = 
{
	"",								//0
	"sprites/TD/healthbar1.spr",	//1
	"sprites/TD/healthbar2.spr",	//2
	"sprites/TD/healthbar3.spr"		//3
}

new g_SpriteBloodDrop
new g_SpriteBloodSpray;
new g_SpriteExplode
new g_SpriteLighting;
new g_SpriteWhiteLine;

enum
{
	GRENADE_NO_SPECIAL,
	GRENADE_NAPALM,
	GRENADE_FROZEN,
	GRENADE_STOP
}

enum ENUM_MODELS 
{
	MODEL_NORMAL,
	MODEL_FAST,
	MODEL_STRENGTH,
	MODEL_BOSS,
	MODEL_BONUS,
	MODEL_TOWER,
}

#define GET_MODEL_DIR_FROM_FILE(%1) fmt("models/TD/%s.mdl", (%1))  
#define GET_VIP_MODEL(%1) fmt("models/player/%s/%s.mdl", (%1), (%1))  
#define GET_PLAYER_MODEL(%1) fmt("models/player/%s/%s.mdl", (%1), (%1))  
 
new g_VipModel[33];
new Float:g_PlayerOrigin[33][3];

new g_ModelFileNapalmGrenade_V[33];
new g_ModelFileNapalmGrenade_W[33];
new g_ModelFileNapalmGrenade_P[33];

new g_ModelFileFrozenGrenade_V[33];
new g_ModelFileFrozenGrenade_W[33];
new g_ModelFileFrozenGrenade_P[33];

new g_ModelFileStopGrenade_V[33];
new g_ModelFileStopGrenade_W[33];
new g_ModelFileStopGrenade_P[33];

enum ENUM_SOUNDS 
{
	SND_START_WAVE,
	SND_COIN,
	SND_ACTIVATED,
	SND_COUNTDOWN,
	SND_MONSTER_DIE_1,
	SND_MONSTER_DIE_2,
	SND_MONSTER_DIE_3,
	SND_MONSTER_DIE_4,
	SND_MONSTER_HIT_1,
	SND_MONSTER_HIT_2,
	SND_MONSTER_HIT_3,
	SND_MONSTER_HIT_4,
	SND_MONSTER_1,
	SND_MONSTER_2,
	SND_MONSTER_3,
	SND_MONSTER_4,
	SND_MONSTER_GROWL_1,
	SND_MONSTER_GROWL_2,
	SND_MONSTER_GROWL_3,
	SND_MONSTER_GROWL_4,
	SND_BOSS_SPAWNED,
	SND_BOSS_DIE,
	SND_BONUS_SPAWNED,
	SND_BONUS_DIE,
	SND_PLAYER_LEVELUP,
	SND_PLAYER_USE_LIGHTING,
	SND_CLEAR_WAVE,
	SND_STOP_GRENADE,
	SND_DEFENDERS_WIN,
	SND_DEFENDERS_LOSE,
	SND_HIT,
	SND_LAST_MAN
}

enum ENUM_CONFIG
{
	CFG_TIME_TO_WAVE,
	CFG_BOSS_DAMAGE,
	CFG_MONSTER_DAMAGE,
	CFG_TOWER_HEALTH,
	CFG_WAVE_EXTRA_GOLD,
	CFG_WAVE_EXTRA_MONEY,
	CFG_ONE_PLAYER_MODE,
	CFG_RESPAWN_CMD,
	CFG_SHOW_LEFT_DAMAGE,
	CFG_KILL_GOLD,
	CFG_KILL_MONEY,
	CFG_KILL_BP_AMMO,
	CFG_KILL_BOSS_GOLD,
	CFG_KILL_BOSS_FRAGS,
	CFG_KILL_BONUS_GOLD,
	CFG_KILL_BONUS_FRAGS,
	CFG_SEND_MONSTER_TIME,
	CFG_KILL_MONSTER_FX,
	CFG_HIT_MONSTER_BLOOD_FX,
	CFG_HIT_MONSTER_BLOOD_CHANCE,
	CFG_HIT_MONSTER_SOUND,
	CFG_KILL_MONSTER_SOUND,
	CFG_DAMAGE_GOLD,
	CFG_DAMAGE_MONEY,
	CFG_DAMAGE_RATIO,
	CFG_SWAP_MONEY,
	CFG_SWAP_MONEY_MONEY,
	CFG_SWAP_MONEY_GOLD,
	CFG_NAPALM_NADE_DURATION,
	CFG_NAPALM_NADE_RADIUS,
	CFG_NAPALM_NADE_DAMAGE,
	CFG_NAPALM_NADE_LIMIT,
	CFG_FROZEN_NADE_DURATION,
	CFG_FROZEN_NADE_RADIUS,
	CFG_FROZEN_NADE_PERCENT,
	CFG_FROZEN_NADE_LIMIT,
	CFG_STOP_NADE_DURATION,
	CFG_STOP_NADE_RADIUS,
	CFG_STOP_NADE_LIMIT,
	CFG_START_ZONE_STAY_TIME,
	CFG_BLOCK_CMD_KILL,
	CFG_VIP,
	CFG_VIP_EXTRA_SPEED,
	CFG_VIP_EXTRA_DAMAGE_MLTP,
	CFG_VIP_FLAG,
	CFG_VIP_SHOW_IN_TABLE,
	CFG_VIP_CHAT_COLOR,
	CFG_VIP_EXTRA_KILL_GOLD,
	CFG_VIP_EXTRA_KILL_MONEY,
	CFG_VIP_SURV_WAVE_GOLD,
	CFG_VIP_SURV_WAVE_MONEY,
	CFG_REPAIR_ZONE,
	CFG_REPAIR_ZONE_BLOCKS,
	CFG_REPAIR_ZONE_TIME,
	CFG_REPAIR_ZONE_COST,
	CFG_REPAIR_ZONE_ONE_PLAYER,
	CFG_REPAIR_ZONE_AMOUNT,
	CFG_JOIN_PLAYER_EXTRA,
	CFG_JOIN_PLAYER_EXTRA_MIN_WAVE,
	CFG_JOIN_PLAYER_EXTRA_MONEY,
	CFG_JOIN_PLAYER_EXTRA_GOLD,
	CFG_VOTE_MAP_TIME,
	CFG_VOTE_ALLOW_RESTART,
	CFG_WAVE_MLTP_MIN_PLAYERS,
	CFG_WAVE_MLTP_HP,
	CFG_WAVE_MLTP_HP_BOSS,
	CFG_WAVE_MLTP_HP_BONUS,
	CFG_SHOW_DEATH_MSG,
	CFG_MAP_LIGHT,
	CFG_BONUS_MIN_GOLD,
	CFG_BONUS_MAX_GOLD,
	CFG_BONUS_STAEL_CHANCE,
	CFG_AUTO_RESPAWN,
	CFG_NVAULT_EXPIRE_DAYS,
	CFG_DATA_SAVE_MODE,
	CFG_MAX_SERVER_TURRETS,
	CFG_AFK_TIME,
	CFG_PRM_MONSTER_CHANCE,
	CFG_PRM_MONSTER_GLOW,
	CFG_HIT_SOUND,
	CFG_BANK_LIMIT,
	CFG_BANK_LIMIT_VIP,
	CFG_CHAT_SHOW_LEVEL,
	CFG_WIN_GAME_GOLD_PRIZE,
	CFG_LOSE_GAME_GOLD_PRIZE
}

new g_FogColor[3];
new g_FogColorBoss[3];
new g_FogColorBonus[3];
new g_szVipChatPrefix[8];
new g_szVipStartWeapons[24];
new g_szVipFlag[4];

enum ENUM_CONFIG_FLOAT
{
	Float:CFG_FLOAT_HEADSHOT_MULTIPLIER,
	Float:CFG_FLOAT_SEND_MONSTER_TIME,
	Float:CFG_FLOAT_FROZEN_NADE_PERCENT,
	Float:CFG_FLOAT_VIP_EXTRA_DAMAGE_MLTP,
	Float:CFG_FLOAT_WAVE_MLTP_HP,
	Float:CFG_FLOAT_WAVE_MLTP_HP_BOSS,
	Float:CFG_FLOAT_WAVE_MLTP_HP_BONUS,
	Float:CFG_FLOAT_PRM_MONSTER_MLTP_HP,
	Float:CFG_FLOAT_PRM_MONSTER_MLTP_SPEED,
	Float:CFG_FLOAT_PRM_MONSTER_MLTP_GOLD
}

enum _:ENUM_HUD_SIZE
{
	HUD_SMALL = 1,
	HUD_NORMAL, 
	HUD_BIG
}

/* TASKS */
#define TASK_START_WAVE			555
#define TASK_COUNTDOWN			334
#define TASK_SEND_MONSTERS		404
#define TASK_DAMAGE_EFFECT		594
#define TASK_GIVE_NAPALM		814
#define TASK_GIVE_FROZEN		1431
#define TASK_PLAYER_HUD			521
#define TASK_START_ZONE			91191
#define TASK_GRENADE_NAPALM		1000
#define TASK_GRENADE_FROZEN		2000
#define TASK_GRENADE_STOP		2000
#define TASK_CHECK_STARTZONE		9000
#define TASK_IS_IN_REPAIR_ZONE		12351
#define TASK_CHANGE_MAP			9218
#define TASK_COUNTDOWN_VOTE		9220
#define TASK_SHOW_DEATH_MSG		201
#define TASK_RESPAWN			9500
#define TASK_BONUS_FX			11222
#define TASK_CHECK_USER_DATA		12213
#define TASK_SHOW_SPECIAL_INFO		654321
#define TASK_CHECK_GAME		124541

/* enum  {
	TASK_PLAYER_SPAWN = 437,
	TASK_GAME_FALSE = 790,
}
*/

#define MAX_LEVEL 10

new const g_LevelFrags[MAX_LEVEL+1] =
{
	0,
	89, 
	215, 
	530, 
	1531,
	2814, 
	6073, 
	10319, 
	17553, 
	29841,
	99999
}


new g_SkillsDesc[MAX_LEVEL][64] = 
{
	"No skill",
	"You take 6 more damage.",
	"You are 10% faster.",
	"You get 1 gold more for killing monster.",
	"You get $150 more for kliling monster.",
	"You get 1 napalm nade every 2 minutes.",
	"You are 25% faster.",
	"You take 16 more damage",
	"You get 1 freeze nade every 2 minutes.",
	"You can hit monster by lighting every 30sec. 'X' button"
}

new g_ModelFile[4][ENUM_MODELS][33]
new g_SoundFile[ENUM_SOUNDS][128]
new g_InfoAboutWave[MAX_WAVES][ENUM_WAVE_INFO]
new g_ConfigValues[ENUM_CONFIG];
new Float:g_ConfigValuesFloat[ENUM_CONFIG_FLOAT];

/* Tower Defense: Shop */

new g_ShopItemsName[MAX_SHOP_ITEMS+1][33];
new g_ShopItemsDesc[MAX_SHOP_ITEMS+1][128];
new g_ShopItemsPrice[MAX_SHOP_ITEMS+1];

new g_ShopOnePerMap[MAX_SHOP_ITEMS+1];
new g_ShopPlayerBuy[33][MAX_SHOP_ITEMS+1];

new g_ShopItemsNum;

/* =================== */

new g_PlayerInfo[33][ENUM_PLAYER];

new Float:g_PlayerHealthbarScale[33];
new Float:g_PlayerHudPosition[33][2]
new Float:g_PlayerLightingTime[33];

new g_PlayerHealthbar[33];
new g_PlayerHudSize[33];
new g_PlayerWavesPlayed[33];
new g_PlayerHudColor[33][3]
new g_PlayerHittedDamage[33];
new g_PlayerSwapMoneyAutobuy[33];

new bool:g_IsPlayerVip[33];
new g_PlayerAfkWarns[33];

new g_PlayerGamePlayedNumber[33];
new g_PlayerShowHitCrosshair[33];

/* StartZone */
new bool:g_IsPlayerInStartZone[33];
new bool:g_IsAdminInStartZoneMenu;
new bool:g_ShowPlayersRespawn;
new g_StartZoneEntity;
new g_PlayerTimeInRepairZone[33];
new g_PlayerRepairedBlock[33];

/* RepairZone */
new bool:g_IsPlayerInRepairZone[33];
new g_RepairZoneEntity;

/* MapVoteZone */
new g_MapVoteZoneLastEntity
new g_MapVoteZoneWidth = 100;
new g_MapVoteZoneLength = 100;

/* Voting for nextmap zone */
new Float:g_VoteForNextMapEntityPosition[VOTE_MAP_COUNT][3][3];
new g_VoteForNextMapEntity[VOTE_MAP_COUNT];
new g_VotePlayerForNextMap[33];
new g_VoteForNextMapNames[VOTE_MAP_COUNT][64];
new g_LastMapName[LAST_MAPS_SAVE][32];
new g_LastMapsNum;
new g_VotedForNextMapNum;

/* This must be declared, becouse event Money is executing many times and it fixing display multiple messages */
new g_IsUserNotifiedAboutSwap[33];

new MAX_TURRETS_ON_MAP;
new g_MapLight[2]
new g_TowerHealth;
new g_WavesNum;
new g_MaxPlayers;

new g_HudStatusText;

/* -- */

new g_ActualWave;
new g_AliveMonstersNum;
new g_SentMonstersNum;

new g_SyncHudInfo;
new g_SyncHudDamage;
new g_SyncHudGameInfo;
new g_SyncHudRepair;

/* Forwards */

new g_ForwardShopItemSelected;
new g_ForwardTakeDamage;
new g_ForwardSettingsRefreshed;
new g_ForwardMonsterKilled;
new g_ForwardWaveStarted;
new g_ForwardWaveEnded;
new g_ForwardGameEnded;
new g_ForwardRemoveData;
new g_ForwardTakeDamagePost;

native ShowTurretsMenu(id);
native ShowTurretsSettingsMenu(id);

public plugin_natives() 
{
	register_native("td_get_user_info", 		"_td_get_user_info", 1)
	register_native("td_set_user_info", 		"_td_set_user_info", 1)
	register_native("td_get_max_player_level", 	"_td_get_max_player_level", 1);
	register_native("td_get_user_hud_size",	"_td_get_user_hud_size", 1);
	register_native("td_give_user_napalm_grenade", 	"GiveUserNapalmGrenade",  1);
	register_native("td_give_user_frozen_grenade", 	"GiveUserFrozenGrenade",  1);
	register_native("td_give_user_stop_grenade", 	"GiveUserStopGrenade",  1);
	
	/* Shop */
	register_native("td_shop_register_item", 	"_td_shop_register_item", 1);

	register_native("td_get_actual_wave",		"_td_get_actual_wave", 1);
	register_native("td_set_actual_wave", 		"_td_set_actual_wave", 1);
	register_native("td_get_wave_info",		"_td_get_wave_info", 1);
	register_native("td_set_wave_info",		"_td_set_wave_info", 1);
	register_native("td_is_special_wave",		"IsSpecialWave", 1);
	
	register_native("td_get_max_wave",		"_td_get_max_wave", 1);
	register_native("td_set_tower_health", 		"_td_set_tower_health", 1);
	register_native("td_get_tower_health", 		"_td_get_tower_health", 1);
	register_native("td_get_max_tower_health", 	"_td_get_max_tower_health", 1);
	
	register_native("td_is_monster", 		"IsMonster", 1);
	register_native("td_is_healthbar",		"IsHealthbar", 1);
	register_native("td_get_monster_maxhealth", 	"_td_get_monster_maxhealth", 1);
	register_native("td_get_max_monsters_num",	 "_td_get_max_monsters_num", 1);
	register_native("td_get_monster_speed", 	"_td_get_monster_speed",  1);
	register_native("td_set_monster_speed", 	"_set_monster_speed",  1);
	register_native("td_get_monster_healthbar", 	"_td_get_monster_healthbar", 1);
	register_native("td_kill_monster",		"_td_kill_monster", 1);
	register_native("td_is_special_monster",	"IsSpecialMonster", 1);
	register_native("td_get_monster_type",		"_td_get_monster_type", 1);
	register_native("td_get_monster_health",	"_td_get_monster_health", 1);
	
	register_native("td_get_chat_prefix",		"_td_get_chat_prefix", 1);
	
	register_native("td_get_log_file_name",		"_td_get_log_file_name", 1);
	
	register_native("td_is_game_possible",		"_td_is_game_possible", 1);
	register_native("td_get_max_map_turrets",	"_td_get_max_map_turrets", 1);
	register_native("td_are_turrets_enabled",	"_td_are_turrets_enabled", 1);
	register_native("td_is_wave_started",		"_td_is_wave_started", 1);

	register_native("td_remove_tower",		"_td_remove_tower",	1);
	register_native("td_get_start_origin",		"_td_get_start_origin", 0);
	register_native("td_get_end_origin",		"_td_get_end_origin", 0);
	register_native("td_remove_monsters",		"_td_remove_monsters", 1);
	register_native("td_is_tower_model_on_map",	"_td_is_tower_model_on_map", 1);
	register_native("td_get_end_status",		"_td_get_end_status", 1);
	register_native("td_is_premium_monster",	"IsPremiumMonster", 1);

	register_native("td_is_user_vip",		"_td_is_user_vip", 1);
}

public plugin_precache()
{
	if(is_plugin_loaded("td_debug.amxx", true) != -1)
		DEBUG = true;

	if(file_exists("sprites/TD/startzone.spr"))
		precache_model("sprites/TD/startzone.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/TD/startzone.spr is not exist!");

	if(file_exists("sprites/TD/repairzone.spr"))
		precache_model("sprites/TD/repairzone.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/TD/repairzone.spr is not exist!");

	if(file_exists("sprites/TD/votemap_sprites.spr"))
		precache_model("sprites/TD/votemap_sprites.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/TD/votemap_sprites.spr is not exist!");

	if(file_exists("sprites/TD/ranger.spr"))
		precache_model("sprites/TD/ranger.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/TD/ranger.spr is not exist!");

	if(file_exists("sprites/TD/ranger.spr"))
		precache_model("sprites/TD/ranger.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/TD/ranger.spr is not exist!");
	
	LoadConfiguration();
	
	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Precaching sounds started.")

	new szFormat[64];
	
	/* Precache sounds */
	for(new i; i < _:ENUM_SOUNDS ; i++)
	{
		formatex(szFormat, 63, "sound/%s", g_SoundFile[ENUM_SOUNDS:i]);

		if(file_exists(szFormat))
			precache_sound(g_SoundFile[ENUM_SOUNDS:i]);
		else if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: %s is not exist! i = %d", szFormat, i);
	}

	precache_sound("weapons/hegrenade-1.wav")
	precache_sound("items/9mmclip1.wav")
	
	if(DEBUG)
	{
		log_to_file(LOG_FILE, "DEBUG: Precaching sounds finished.")
		log_to_file(LOG_FILE, "DEBUG: Precaching models started.")
	}
	
	/* Precache models */
	for(new i ; i < _:ENUM_MODELS ; i++) 
	{
		for(new j ; j < 4; j++)
		{
			formatex(szFormat, 63, GET_MODEL_DIR_FROM_FILE(g_ModelFile[j][ENUM_MODELS:i]));
			
			if(file_exists(szFormat))
				precache_model(szFormat)
			else if(DEBUG)
				log_to_file(LOG_FILE, "DEBUG: %s is not exist!", szFormat);
		}
	}
	

	if(file_exists(GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_V)))
		precache_model(GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_V));
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: %s is not exist!", GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_V));

	if(file_exists(GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_W)))
		precache_model(GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_W));
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: %s is not exist!", GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_W));
		
	if(file_exists(GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_P)))
		precache_model(GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_P));
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: %s is not exist!", GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_P));

	if(file_exists(GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_V)))
		precache_model(GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_V));
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: %s is not exist!", GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_V));
		
	if(file_exists(GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_W)))
		precache_model(GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_W));
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: %s is not exist!", GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_W));

	if(file_exists(GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_P)))
		precache_model(GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_P));
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: %s is not exist!", GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_P));
		
	if(file_exists(GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_V)))
		precache_model(GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_V));
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: %s is not exist!", GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_V));
		
	if(file_exists(GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_W)))
		precache_model(GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_W));
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: %s is not exist!", GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_W));
		
	if(file_exists(GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_P)))
		precache_model(GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_P));
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: %s is not exist!", GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_P));
		
	if(file_exists(GET_VIP_MODEL(g_VipModel)))
		precache_model(GET_VIP_MODEL(g_VipModel));
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: %s is not exist!",GET_VIP_MODEL(g_VipModel));
		
	
	if(DEBUG)
	{
		log_to_file(LOG_FILE, "DEBUG: Precaching models finished.")
		log_to_file(LOG_FILE, "DEBUG: Precaching healthbars started.")
	}
	/* Precache healthbars */
	for(new i = 1; i < ( sizeof g_HealthbarsSprite ) ; i++)
	{
		if(file_exists(g_HealthbarsSprite[i]))
			precache_model(g_HealthbarsSprite[i])
		else if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: %s is not exist!", g_HealthbarsSprite[i]);
	}
		
	if(DEBUG)
	{
		log_to_file(LOG_FILE, "DEBUG: Precaching healthbars finished.")	
		log_to_file(LOG_FILE, "DEBUG: Precaching other sprites started.")	
	}

	if(file_exists(SPAWN_SPRITE))
		precache_model(SPAWN_SPRITE)
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: %s is not exist!", SPAWN_SPRITE);
			
	if(file_exists("sprites/TD/blood.spr"))
		g_SpriteBloodDrop = precache_model("sprites/TD/blood.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/TD/blood.spr is not exist!");
			
	if(file_exists("sprites/TD/bloodspray.spr"))
		g_SpriteBloodSpray = precache_model("sprites/TD/bloodspray.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/TD/bloodspray.spr is not exist!");
			
	if(file_exists("sprites/TD/zerogxplode.spr"))
		g_SpriteExplode = precache_model("sprites/TD/zerogxplode.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/TD/zerogxplode.spr is not exist!");

	if(file_exists("sprites/TD/lgtning.spr"))
		g_SpriteLighting = precache_model("sprites/TD/lgtning.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/TD/lgtning.spr is not exist!");

	if(file_exists("sprites/flame.spr"))
		g_SpriteFlame = precache_model("sprites/flame.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/flame.spr is not exist!");

	if(file_exists("sprites/TD/laserbeam.spr"))
		g_SpriteTrail = precache_model("sprites/TD/laserbeam.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/TD/laserbeam.spr is not exist!");

	if(file_exists("sprites/white.spr"))
		g_SpriteWhiteLine = precache_model("sprites/white.spr")
	else if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: sprites/white.spr is not exist!");


	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Precaching other sprites finished.")	
	
}

public tt(id)
	ResetGame();
	
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /info", 	"DisplayWaveInfo");
	register_clcmd("say /respawn", 	"CmdRespawnPlayer")
	//register_clcmd("say /tt", 	"tt");
	//register_clcmd("say /ttt", 	"ttt");
	//register_clcmd("say /test51", 	"test");
	//register_clcmd("say /testt", 	"testt");
	register_clcmd("say /sklep", 	"ShowShopMenu")
	register_clcmd("say /shop", 	"ShowShopMenu")
	register_clcmd("say /spec", 	"CmdGoToSpec")

	register_clcmd("say /skill", 	"CmdPlayerSkillMenu");
	register_clcmd("say /skills", 	"CmdPlayerSkillMenu");
	register_clcmd("say /menu",  	"CmdPlayerMenu");
	register_clcmd("say /swap", 	"CmdSwapMoney")
	register_clcmd("say /wymien", 	"CmdSwapMoney")
	register_clcmd("say /zamien", 	"CmdSwapMoney")
	register_concmd("ShowOptionsMenu","ShowPlayerOptionsMenu")
	register_clcmd("radio1", 		"BlockCommand")
	register_clcmd("radio2",     	"CmdUseLighting")
	register_clcmd("radio3", 		"BlockCommand")
	
	register_clcmd("startzone_select_width", 	"ChangeWidthOfStartZone", ADMIN_CVAR)
	register_clcmd("startzone_select_length", 	"ChangeLengthOfStartZone", ADMIN_CVAR)
	
	register_clcmd("repairzone_select_width", 	"ChangeWidthOfRepairZone", ADMIN_CVAR)
	register_clcmd("repairzone_select_length", 	"ChangeLengthOfRepairZone", ADMIN_CVAR)
	
	register_clcmd("mapvotezone_select_width", 	"ChangeWidthOfMapVoteZone", ADMIN_CVAR)
	register_clcmd("mapvotezone_select_length", "ChangeLengthOfMapVoteZone", ADMIN_CVAR)

	register_clcmd("say", 		"PlayerSaysSomething");
	register_clcmd("say /vip", 	"cmdVipInfo");
	
	register_message(get_user_msgid("ScoreAttrib"), 	"messageScoreAttrib");
	register_message(get_user_msgid("SayText"),			"handleSayText");
	
	register_impulse(100, 			"FlashlightTurn")
	
	register_touch("startzone", 	"player", 	"fwStartZoneTouched");
	register_touch("repairzone", 	"player", 	"fwRepairZoneTouched");
	
	register_think("startzone",		"fwStartZoneDisplay");
	register_think("repairzone",	"fwRepairZoneDisplay");
	
	register_event("Money", 			"EventMoney",	"be")
	register_event("HLTV", 				"HLTV", 		"a", "1=0", "2=0")
	register_logevent("LogEventNewRound", 2, 			"1=Round_Start")
	
	/* Block attacking players */
	register_forward(FM_TraceLine, 			"BlockAttackingPlayer", 1)
	register_forward(FM_SetModel, 			"fw_SetModel")
	register_forward(FM_ClientKill, 		"CmdKill")
	 
	RegisterHam(Ham_Touch, 					"info_target", 		"MonsterChangeTrack", 0)
	
	RegisterHam(Ham_Think, 					"grenade", 			"fw_ThinkGrenade")
	RegisterHam(Ham_TraceAttack, 			"info_target", 		"MonsterHitHeadshot");
	RegisterHam(Ham_TakeDamage, 			"info_target", 		"TakeDamage")
	RegisterHam(Ham_TakeDamage, 			"info_target", 		"ShowDamage", 1)
	RegisterHam(Ham_TakeDamage, 			"player",			"BlockKillPlayer")
	RegisterHam(Ham_Killed, 				"info_target", 		"MonsterKilled")
	RegisterHam(Ham_CS_Player_ResetMaxSpeed,"player", 			"SetPlayerSpeed", 1);
	RegisterHam(Ham_Item_Deploy, 			"weapon_hegrenade", "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Item_Deploy, 			"weapon_smokegrenade", "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Item_Deploy, 			"weapon_flashbang", "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Spawn,					"player",			"PlayerSpawned", 1);
	
	if(nvault_open(NVAULT_FILE_NAME) == INVALID_HANDLE)
		if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: Users config file data/vault/%s.vault is not exist. This message can be showed when you run first time Tower Defense Mod on your server", NVAULT_FILE_NAME)
			
	/* For healthbars */
	register_forward(FM_AddToFullPack, "fwAddToFullPack", 1)
	
	g_ForwardShopItemSelected 	= 	CreateMultiForward("td_shop_item_selected", ET_CONTINUE, FP_CELL, FP_CELL);
	g_ForwardTakeDamage			=	CreateMultiForward("td_take_damage", 		ET_CONTINUE, FP_CELL, FP_CELL,  FP_CELL, FP_FLOAT, FP_ARRAY);
	g_ForwardSettingsRefreshed	=	CreateMultiForward("td_settings_refreshed", ET_CONTINUE);
	g_ForwardMonsterKilled		=	CreateMultiForward("td_monster_killed", 	ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL)
	g_ForwardWaveStarted 		= 	CreateMultiForward("td_wave_started", 		ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_ForwardWaveEnded			= 	CreateMultiForward("td_wave_ended", 		ET_CONTINUE, FP_CELL);
	g_ForwardGameEnded			= 	CreateMultiForward("td_game_ended", 		ET_CONTINUE, FP_CELL);
	g_ForwardRemoveData			= 	CreateMultiForward("td_remove_data", 		ET_CONTINUE);
	g_ForwardTakeDamagePost		=	CreateMultiForward("td_take_damage_post", 	ET_CONTINUE, FP_CELL, FP_CELL,  FP_CELL, FP_FLOAT, FP_ARRAY);

	g_MaxPlayers 				= 	get_maxplayers();
	g_HudStatusText 			= 	get_user_msgid("StatusText");
	
	g_SyncHudInfo 				= CreateHudSyncObj();
	g_SyncHudDamage 			= CreateHudSyncObj();
	g_SyncHudGameInfo			= CreateHudSyncObj();
	g_SyncHudRepair	 			= CreateHudSyncObj();
	
	/* This is player hud task, 2.0 is refreshing time */
	set_task(2.0, "DisplayHud", TASK_PLAYER_HUD, _, _, "b");
	set_task(1.0, "CheckArePlayersInStartZone", TASK_CHECK_STARTZONE, _, _, "b")
	set_task(5.0, "CheckGameTask", TASK_CHECK_GAME, _, _, "b");
	set_task(5.0, "CheckGunModIsEnabled");
	
	new szFormat[15]
	for(new i; i < VOTE_MAP_COUNT; i++)
	{
		formatex(szFormat, 14, 		"mapvote%d", i+1)
		register_think(szFormat, "fwThink");
		register_touch(szFormat, "player", "fwTouch");
	}
	
	//SetMapLight()
}

public CheckGunModIsEnabled()
	if(is_plugin_loaded("td_gunmod.amxx", true) != -1)
		g_isGunModEnabled = true;
		
public PlayerSaysSomething(id)
{
	static szText[32];
	read_args(szText, charsmax(szText));
	
	remove_quotes(szText);
	trim(szText);
	
	if(strlen(szText) < 5 || !equali(szText, "/info", 5) || equali(szText, "/info"))
		return PLUGIN_CONTINUE;
	
	static szTemp[2][3];
			
	parse(szText, szTemp[0], 2, szTemp[1], 2);
	
	if(!strlen(szTemp[1]))
		return PLUGIN_CONTINUE;
	
	trim(szTemp[1]);
	
	static iWave; iWave = str_to_num(szTemp[1])
	
	if(!(1 <= iWave <= g_WavesNum))
	{
		ColorChat(id, GREEN, "%s^x01 You can check only waves from 1 to %d!", CHAT_PREFIX, g_WavesNum);
		return PLUGIN_CONTINUE;
	}

	DisplayWaveInfo(id, iWave);
	
	return PLUGIN_HANDLED;
}

public CmdGoToSpec(id)
{
	if(get_user_team(id) == 3 || get_user_team(id) == 0)
	{
		ColorChat(id, GREEN, "%s^x01 You cannot join to^x03 Spectacors^x01 if you are spectactor", CHAT_PREFIX);
		return PLUGIN_HANDLED;
	}
	
	if(!is_user_alive(id))
	{
		ColorChat(id, GREEN, "%s^x01 You must be alive to use this command.", CHAT_PREFIX);
		return PLUGIN_HANDLED;
	}

	new szName[33];
	get_user_name(id, szName, 32);
	
	user_silentkill(id);

	ColorChat(0, GREEN, "%s^x01 Defender '%s' has been moved to Spectacors.", CHAT_PREFIX, szName);
	cs_set_user_team(id, CS_TEAM_SPECTATOR, CS_DONTCHANGE);

	remove_task(id + TASK_GIVE_NAPALM)
	remove_task(id + TASK_GIVE_FROZEN);

	return PLUGIN_HANDLED;
}

public LoadUserConfig(id)
{
	new iFile
	if((iFile = nvault_open(NVAULT_FILE_NAME)) == INVALID_HANDLE)
		return;

	new szKey[48];
	new szData[128];

	switch(g_ConfigValues[CFG_DATA_SAVE_MODE])
	{
		case 1: get_user_name(id, szKey, 32);
		case 2: get_user_ip(id, szKey, 32, 1);
		case 3: get_user_authid(id, szKey, 32)
	}
	formatex(szKey, charsmax(szKey), "%s-engine#", szKey);

	if(nvault_get(iFile, szKey, szData, charsmax(szData)))
	{	
		new szTempInfo[13][8];
		explode(szData, '|', szTempInfo, 13, 7);
	
		g_PlayerInfo[id][PLAYER_GOLD]  = str_to_num( szTempInfo[0] );
		g_PlayerInfo[id][PLAYER_FRAGS]	= str_to_num( szTempInfo[1] );
		g_PlayerHealthbar[id]		= str_to_num( szTempInfo[2] )
		g_PlayerHudSize[id] 		= str_to_num( szTempInfo[3] );
		g_PlayerHudColor[id][0]		= str_to_num( szTempInfo[4] );
		g_PlayerHudColor[id][1]		= str_to_num( szTempInfo[5] );
		g_PlayerHudColor[id][2]		= str_to_num( szTempInfo[6] );
		g_PlayerSwapMoneyAutobuy[id]	= str_to_num( szTempInfo[7] );
		g_PlayerHealthbarScale[id]	= str_to_float( szTempInfo[8] );
		g_PlayerHudPosition[id][0]	= str_to_float( szTempInfo[9] );
		g_PlayerHudPosition[id][1]	= str_to_float( szTempInfo[10] );
		g_PlayerGamePlayedNumber[id]	= str_to_num( szTempInfo[11] );
		g_PlayerShowHitCrosshair[id]	= str_to_num( szTempInfo[12] );

		new iMax;
		new iFrags = g_PlayerInfo[id][PLAYER_FRAGS];

		for(new i = 1; i <= MAX_LEVEL; i++)
			if(iFrags >= g_LevelFrags[i])
				iMax = i + 1;
	
		g_PlayerInfo[id][PLAYER_LEVEL] = iMax;

		if(g_PlayerInfo[id][PLAYER_LEVEL] > 1)
		{
			for(new i = 2; i <= iMax ; i++)
				GiveUserSkillsByLevel(id, i);
		}

	}

	nvault_close(iFile);	
}


public GiveUserSkillsByLevel(iPlayer, iLevel)
{
	switch(iLevel)
	{
		case 2: g_PlayerInfo[iPlayer][PLAYER_EXTRA_DAMAGE] 	+= 6;
		case 3: g_PlayerInfo[iPlayer][PLAYER_EXTRA_SPEED] 	+= 25;
		case 4: g_PlayerInfo[iPlayer][PLAYER_EXTRA_GOLD]	+= 1
		case 5: g_PlayerInfo[iPlayer][PLAYER_EXTRA_MONEY] 	+= 150
		case 6: set_task(120.0, "GiveUserNapalmTask", iPlayer + TASK_GIVE_NAPALM, _, _, "b");
		case 7: g_PlayerInfo[iPlayer][PLAYER_EXTRA_SPEED] 	+= 50
		case 8: g_PlayerInfo[iPlayer][PLAYER_EXTRA_DAMAGE] 	+= 16;
		case 9: set_task(120.0, "GiveUserFrozenTask", iPlayer + TASK_GIVE_FROZEN, _, _, "b");	
	}
}
stock explode(const string[],const character,output[][],const maxs,const maxlen)
{

	new iDo = 0,
	len = strlen(string),
	oLen = 0;

	do{
		oLen += (1+copyc(output[iDo++],maxlen,string[oLen],character))
	}while(oLen < len && iDo < maxs)
}

public SaveUserConfig(id, iFile)
{
	new szKey[48];
	new szData[128];

	switch(g_ConfigValues[CFG_DATA_SAVE_MODE])
	{
		case 1: get_user_name(id, szKey, 32);
		case 2: get_user_ip(id, szKey, 32, 1);
		case 3: get_user_authid(id, szKey, 32)
	}

	new tmpGold = g_PlayerInfo[id][PLAYER_GOLD];
	
	if(g_IsPlayerVip[id])
	{
		if(g_ConfigValues[CFG_BANK_LIMIT_VIP])
		{
			if(tmpGold > g_ConfigValues[CFG_BANK_LIMIT_VIP])
			{
				ColorChat(id, GREEN, "%s^x01 You reached maximum bank limit of gold for VIP users [ %d ]", CHAT_PREFIX, g_ConfigValues[CFG_BANK_LIMIT_VIP]); 
				tmpGold = g_ConfigValues[CFG_BANK_LIMIT_VIP];
			}
		}
	}
	else
	{
		if(g_ConfigValues[CFG_BANK_LIMIT])
		{
			if(tmpGold > g_ConfigValues[CFG_BANK_LIMIT])
			{
				ColorChat(id, GREEN, "%s^x01 You reached maximum bank limit of gold for normal users [ %d ]", CHAT_PREFIX, g_ConfigValues[CFG_BANK_LIMIT]); 

				if(g_ConfigValues[CFG_VIP] && g_ConfigValues[CFG_BANK_LIMIT_VIP])
					ColorChat(id, GREEN, "%s^x01 VIP users can save in bank %d gold", CHAT_PREFIX, g_ConfigValues[CFG_BANK_LIMIT_VIP])

				tmpGold = g_ConfigValues[CFG_BANK_LIMIT];
			}
		}
	}
	
	formatex(szKey, charsmax(szKey), "%s-engine#", szKey);
	formatex(szData, charsmax(szData), "%d|%d|%d|%d|%d|%d|%d|%d|%0.2f|%0.2f|%0.2f|%d|%d",
	tmpGold, g_PlayerInfo[id][PLAYER_FRAGS], g_PlayerHealthbar[id], g_PlayerHudSize[id],
	g_PlayerHudColor[id][0], g_PlayerHudColor[id][1], g_PlayerHudColor[id][2], 
	g_PlayerSwapMoneyAutobuy[id], g_PlayerHealthbarScale[id], 
	g_PlayerHudPosition[id][0], g_PlayerHudPosition[id][1], g_PlayerGamePlayedNumber[id],
	g_PlayerShowHitCrosshair[id])
	
	nvault_set(iFile, szKey, szData);
}

//public SetMapLight(){}
	//set_lights(g_MapLight);
	
public plugin_end() 
{	
	AddMapToLastMaps();
	RemoveData();
}

public AddMapToLastMaps()
{
	new szText[64], len, index;
	new szData[LAST_MAPS_SAVE][64];
	new currentMap[33];
	get_mapname(currentMap, 32)

	/* Load every line in waves file */
	if(file_exists("addons/amxmodx/data/td-lastmapsplayed.cfg"))
	{
		for(new i; read_file("addons/amxmodx/data/td-lastmapsplayed.cfg", i, szText, 63, len) ; i++) 
		{
			trim(szText)
			
			/* If is comment or is empty load next line */
			if(szText[0] == ';' || !strlen(szText))
				continue;
			
			/* Remove "" */
			remove_quotes(szText)
			copy(szData[index++], 63, szText);
		}
	}

	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Map %s added to td-lastmapsplayed.cfg.", currentMap)
		
	write_file("addons/amxmodx/data/td-lastmapsplayed.cfg", currentMap, 0);
	
	for(new i = 1; i < LAST_MAPS_SAVE ; i++)
		write_file("addons/amxmodx/data/td-lastmapsplayed.cfg", szData[i - 1], i);
}

public tess(id)
{
	GiveUserStopGrenade(id)
	GiveUserFrozenGrenade(id)
	GiveUserNapalmGrenade(id)
	
	EndGame(PLAYERS_WIN);
}
	
public FlashlightTurn(id) 
{
	CmdPlayerMenu(id)
	return PLUGIN_HANDLED_MAIN
}

public plugin_cfg()
{
	server_cmd("sv_maxspeed 9999.9")
	server_cmd("sv_buytime 9999.9")
	server_cmd("mp_freezetime 0")
	server_cmd("mp_timelimit 0")
	server_cmd("mp_flashlights 1")
	server_cmd("mp_autoteambalance 0")
	server_cmd("mp_roundtime 9999")
	server_cmd("sv_alltalk 1")
}

public BlockKillPlayer(this, idinflictor, attacker, Float:damage, damagebits) 
	return HAM_SUPERCEDE


new checkPlayerTime;
public LoadDefaultValues()
{

	g_ConfigValues[CFG_TIME_TO_WAVE]			=	60
	g_ConfigValues[CFG_BOSS_DAMAGE]				=	25
	g_ConfigValues[CFG_MONSTER_DAMAGE]			=	4
	g_ConfigValues[CFG_TOWER_HEALTH]			=	100
	g_ConfigValues[CFG_REPAIR_ZONE_TIME]			=	10
	g_ConfigValues[CFG_REPAIR_ZONE_AMOUNT]			=	4
	MAX_TURRETS_ON_MAP					=	9999;

	g_ConfigValues[CFG_BANK_LIMIT]				= 	800
	g_ConfigValues[CFG_BANK_LIMIT_VIP]			=	1500

	g_ConfigValues[CFG_CHAT_SHOW_LEVEL]			=	1
	
		//CFG_MAP_LIGHT,
	//CFG_NVAULT_EXPIRE_DAYS,
	g_ConfigValues[CFG_AFK_TIME]		=	80;
	
	g_ConfigValues[CFG_WAVE_EXTRA_GOLD] 	= 	7
	g_ConfigValues[CFG_WAVE_EXTRA_MONEY] 	= 	1000
	g_ConfigValues[CFG_ONE_PLAYER_MODE] 	= 	1
	g_ConfigValues[CFG_RESPAWN_CMD]		=	1
	g_ConfigValuesFloat[CFG_FLOAT_SEND_MONSTER_TIME]= 1.7
	g_ConfigValues[CFG_SHOW_LEFT_DAMAGE]	=	1
	g_ConfigValuesFloat[CFG_FLOAT_HEADSHOT_MULTIPLIER]= 2.2
	
	g_ConfigValues[CFG_KILL_GOLD]		=	4
	g_ConfigValues[CFG_KILL_MONEY]		=	700
	g_ConfigValues[CFG_KILL_BP_AMMO]	=	25
	g_ConfigValues[CFG_KILL_BONUS_GOLD]	=	150
	g_ConfigValues[CFG_KILL_BOSS_GOLD]	=	100
	
	g_ConfigValues[CFG_KILL_BONUS_FRAGS]	=	20
	g_ConfigValues[CFG_KILL_BOSS_FRAGS]	=	25

	g_ConfigValues[CFG_PRM_MONSTER_CHANCE]	=	30
	g_ConfigValues[CFG_PRM_MONSTER_GLOW]	=	1;
	g_ConfigValuesFloat[CFG_FLOAT_PRM_MONSTER_MLTP_HP] = 2.0;
	g_ConfigValuesFloat[CFG_FLOAT_PRM_MONSTER_MLTP_SPEED] = 1.0;
	g_ConfigValuesFloat[CFG_FLOAT_PRM_MONSTER_MLTP_GOLD] = 3.5;
	

	g_ConfigValues[CFG_KILL_MONSTER_FX]	=	1
	g_ConfigValues[CFG_KILL_MONSTER_SOUND]	=	1
	g_ConfigValues[CFG_HIT_MONSTER_BLOOD_FX]=	1
	g_ConfigValues[CFG_HIT_MONSTER_BLOOD_CHANCE]=	2
	g_ConfigValues[CFG_HIT_MONSTER_SOUND]	=	1
	
	g_ConfigValues[CFG_DAMAGE_GOLD]		=	1
	g_ConfigValues[CFG_DAMAGE_MONEY]	=	90
	g_ConfigValues[CFG_DAMAGE_RATIO]	=	700
	
	g_ConfigValues[CFG_SWAP_MONEY]		=	1
	g_ConfigValues[CFG_SWAP_MONEY_MONEY]	=	12000
	g_ConfigValues[CFG_SWAP_MONEY_GOLD]	=	15
	
	g_ConfigValues[CFG_NAPALM_NADE_DURATION]=	5
	g_ConfigValues[CFG_NAPALM_NADE_RADIUS]	=	305
	g_ConfigValues[CFG_NAPALM_NADE_DAMAGE]	=	19
	g_ConfigValues[CFG_NAPALM_NADE_LIMIT]	=	2

	g_ConfigValues[CFG_HIT_SOUND]		=	1

	g_ConfigValues[CFG_FROZEN_NADE_DURATION]=	5
	g_ConfigValues[CFG_FROZEN_NADE_RADIUS]	=	305
	g_ConfigValuesFloat[CFG_FLOAT_FROZEN_NADE_PERCENT]= 0.5
	g_ConfigValues[CFG_FROZEN_NADE_LIMIT]	=	2
	
	g_ConfigValues[CFG_STOP_NADE_DURATION]	=	5
	g_ConfigValues[CFG_STOP_NADE_RADIUS]	=	305
	g_ConfigValues[CFG_STOP_NADE_LIMIT]	=	2
	
	g_ConfigValues[CFG_BLOCK_CMD_KILL]	=	1
	checkPlayerTime = g_ConfigValues[CFG_START_ZONE_STAY_TIME] = 10
	g_FogColorBoss[0] = 133 
	g_FogColorBoss[1] = 006
	g_FogColorBoss[2] = 006;
	
 	g_FogColorBonus[0] = 110
 	g_FogColorBonus[1] = 110
 	g_FogColorBonus[2] = 006

	g_FogColor[0] = 006
 	g_FogColor[1] = 006
 	g_FogColor[2] = 110
 	
	g_ConfigValues[CFG_VIP]			=	1
	g_ConfigValues[CFG_VIP_EXTRA_SPEED]	=	38
	g_ConfigValuesFloat[CFG_FLOAT_VIP_EXTRA_DAMAGE_MLTP]= 1.2
	g_ConfigValues[CFG_VIP_SHOW_IN_TABLE]	=	1

	/* Vip prefix colors: 	1 - Normal | 2 - Green | 3 - Team Color */
	g_ConfigValues[CFG_VIP_CHAT_COLOR]	=	2
	g_ConfigValues[CFG_VIP_EXTRA_KILL_GOLD]	=	1
	g_ConfigValues[CFG_VIP_EXTRA_KILL_MONEY]=	200
	g_ConfigValues[CFG_VIP_SURV_WAVE_GOLD]	=	2
	g_ConfigValues[CFG_VIP_SURV_WAVE_MONEY]	=	300

	/*
		Flags of start weapons
		a - deagle
		b - elite
		c - mp5
		d - p90
		e - galil
		f - ak47
		g - m4a1
		h - aug
		i - m249
		j - krieg
		k - awp
		l - g3sg1
		m - sg550
	*/
	g_szVipStartWeapons 		= 	"bgl";
	g_szVipChatPrefix 			= 	"[VIP]";
	g_szVipFlag 				= 	"t";

	g_ConfigValues[CFG_REPAIR_ZONE]		=	1
	g_ConfigValues[CFG_REPAIR_ZONE_ONE_PLAYER]=	0
	g_ConfigValues[CFG_REPAIR_ZONE_BLOCKS]	=	2
	g_ConfigValues[CFG_REPAIR_ZONE_COST]	=	25
		
	g_ConfigValues[CFG_JOIN_PLAYER_EXTRA]	=	0
	g_ConfigValues[CFG_JOIN_PLAYER_EXTRA_MIN_WAVE]=	3
	g_ConfigValues[CFG_JOIN_PLAYER_EXTRA_MONEY]=	500
	g_ConfigValues[CFG_JOIN_PLAYER_EXTRA_GOLD]=	7
	
	g_ConfigValues[CFG_VOTE_MAP_TIME]	=	25
	g_ConfigValues[CFG_VOTE_ALLOW_RESTART]	=	1
	g_ConfigValues[CFG_SHOW_DEATH_MSG]	=	1

	g_ConfigValues[CFG_BONUS_MIN_GOLD]	=	1
	g_ConfigValues[CFG_BONUS_MAX_GOLD]	=	7
	g_ConfigValues[CFG_BONUS_STAEL_CHANCE]	=	4
	
	g_ConfigValues[CFG_WAVE_MLTP_MIN_PLAYERS]	=	2
	g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP]	=	1.07
	g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP_BOSS]=	1.05
	g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP_BONUS]=	1.05
	g_ConfigValues[CFG_AUTO_RESPAWN]	=	1

	if(g_ConfigValues[CFG_REPAIR_ZONE] == 0)
	{
		if(is_valid_ent(g_RepairZoneEntity))
		{
			remove_entity(entity_get_int(g_RepairZoneEntity, EV_INT_repairzone_entity));
			remove_entity(g_RepairZoneEntity)
		}
	}
	g_ConfigValues[CFG_NVAULT_EXPIRE_DAYS]	=	30;

	/* 0 - don't save | 1 - save by name | 2 - save by IP | 3 - save by authid | */
	g_ConfigValues[CFG_DATA_SAVE_MODE]	=	1
}

/* Vip Status */
public messageScoreAttrib(iMsgID, iDest, iReceiver)  
{
	if(g_ConfigValues[CFG_VIP_SHOW_IN_TABLE] && g_ConfigValues[CFG_VIP]) {
		new iPlayer = get_msg_arg_int(1);
		
		if(g_IsPlayerVip[iPlayer])
			set_msg_arg_int(2, ARG_BYTE, is_user_alive(iPlayer) ? (1 << 2) : (1 << 0));  
	}
}

public PlayerSpawned(id)
{
	if(is_user_alive(id))
	{
		if(g_IsPlayerVip[id])
		{
			cs_set_user_model(id, g_VipModel);
			GiveUserWeapons(id, g_szVipStartWeapons);
		}
		
		if(g_ConfigValues[CFG_JOIN_PLAYER_EXTRA]) 
		{
			if(g_ActualWave >= g_ConfigValues[CFG_JOIN_PLAYER_EXTRA_MIN_WAVE] )  
			{
				new iGold = g_ConfigValues[CFG_JOIN_PLAYER_EXTRA_GOLD] * g_ActualWave
				new iMoney = g_ConfigValues[CFG_JOIN_PLAYER_EXTRA_MONEY] * g_ActualWave;
				
				ColorChat(id, GREEN, "%s^x01 Actually defenders reached^x04 %d^x01 wave", CHAT_PREFIX, g_ActualWave)
				
				if(iGold)
				{
					ColorChat(id, GREEN, "%s^x01 For better start you got %d gold", CHAT_PREFIX, iGold)	          
					g_PlayerInfo[id][PLAYER_GOLD] += iGold
				}
				if(iMoney)
				{
					iMoney += cs_get_user_money(id)

					if(iMoney > 16000)
						iMoney = 16000;
						
					ColorChat(id, GREEN, "%s^x01 For better start you got $%d", CHAT_PREFIX, iMoney)
					cs_set_user_money(id, iMoney)
				}
			}
		}	
	}
}

/* Chat prefix before player nick */
public handleSayText(msgId, msgDest, msgEnt) 
{
	static isEmpty;
	
	if(isEmpty == 0) 
	{
		if(!strlen(g_szVipChatPrefix))
			isEmpty = -1;
	}

	static chatColor;
	if(!chatColor) 
		chatColor = g_ConfigValues[CFG_VIP_CHAT_COLOR];
	
	new id = get_msg_arg_int(1);

	new szTmp[256], szTmp2[256], szPrefix[33]
	get_msg_arg_string(2, szTmp, charsmax(szTmp))

	if(g_IsPlayerVip[id] && isEmpty != -1)
	{
		if(chatColor == 1)
			formatex(szPrefix, charsmax(szPrefix), "^x01%s", g_szVipChatPrefix)	
		else if(chatColor == 2)
			formatex(szPrefix, charsmax(szPrefix), "^x04%s", g_szVipChatPrefix)	
		else if(chatColor == 3)
			formatex(szPrefix, charsmax(szPrefix), "^x03%s", g_szVipChatPrefix)	

		if(g_ConfigValues[CFG_CHAT_SHOW_LEVEL])
			formatex(szPrefix, charsmax(szPrefix), "%s^x01 [%d lvl]", szPrefix, g_PlayerInfo[id][PLAYER_LEVEL])	

	}
	else if(g_ConfigValues[CFG_CHAT_SHOW_LEVEL])
		formatex(szPrefix, charsmax(szPrefix), "[%d lvl]", g_PlayerInfo[id][PLAYER_LEVEL])	
	
	if(!equal(szTmp, "#Cstrike_Chat_All")) 
	{
		add(szTmp2, charsmax(szTmp2), szPrefix);
		add(szTmp2, charsmax(szTmp2), " ");
		add(szTmp2, charsmax(szTmp2), szTmp);
	}
	else 
	{
		add(szTmp2, charsmax(szTmp2), szPrefix);
		add(szTmp2, charsmax(szTmp2), "^x03 %s1^x01 :  %s2");
	}
	
	set_msg_arg_string(2, szTmp2);
	return;
}

public CmdKill(id)
{
	if(g_ConfigValues[CFG_BLOCK_CMD_KILL])
	{
		client_print(id, print_console, "This command is blocked by Tower Defense Mod");
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public cmdVipInfo(id) {
	// motd ...
	show_motd(id, "a", "VIP Info");
}

public ChangeWidthOfStartZone(id)
{
	new szAmmount[10], iWidth
	
	read_args(szAmmount, 9)
	remove_quotes(szAmmount)
	
	iWidth = str_to_num(szAmmount);
	
	if(iWidth < 5 || iWidth > 10000)
	{
		client_print(id, print_center, "You typed bad value");
		StartZoneAdminMenu(id);
		return PLUGIN_HANDLED;
	}
	
	g_StartZoneWidth = iWidth;
	StartZoneAdminMenu(id);
	return PLUGIN_HANDLED;
}

public ChangeLengthOfStartZone(id)
{
	new szAmmount[10], iLength
	
	read_args(szAmmount, 9)
	remove_quotes(szAmmount)
	
	iLength = str_to_num(szAmmount);
	
	if(iLength < 5 || iLength > 10000)
	{
		client_print(id, print_center, "You typed bad value");
		StartZoneAdminMenu(id);
		return PLUGIN_HANDLED;
	}
	
	g_StartZoneLength = iLength;
	StartZoneAdminMenu(id);
	
	return PLUGIN_HANDLED
}

public ChangeWidthOfRepairZone(id)
{
	new szAmmount[10], iWidth
	
	read_args(szAmmount, 9)
	remove_quotes(szAmmount)
	
	iWidth = str_to_num(szAmmount);
	
	if(iWidth < 5 || iWidth > 10000)
	{
		client_print(id, print_center, "You typed bad value");
		RepairZoneAdminMenu(id);
		return PLUGIN_HANDLED;
	}
	
	g_RepairZoneWidth = iWidth;
	RepairZoneAdminMenu(id);
	return PLUGIN_HANDLED;
}

public ChangeLengthOfRepairZone(id)
{
	new szAmmount[10], iLength
	
	read_args(szAmmount, 9)
	remove_quotes(szAmmount)
	
	iLength = str_to_num(szAmmount);
	
	if(iLength < 5 || iLength > 10000)
	{
		client_print(id, print_center, "You typed bad value");
		RepairZoneAdminMenu(id);
		return PLUGIN_HANDLED;
	}
	
	g_RepairZoneLength = iLength;
	RepairZoneAdminMenu(id);
	
	return PLUGIN_HANDLED
}

public ChangeWidthOfMapVoteZone(id)
{
	new szAmmount[10], iWidth
	
	read_args(szAmmount, 9)
	remove_quotes(szAmmount)
	
	iWidth = str_to_num(szAmmount);
	
	if(iWidth < 5 || iWidth > 10000)
	{
		client_print(id, print_center, "You typed bad value");
		MapVoteZoneAdminMenu(id);
		return PLUGIN_HANDLED;
	}
	
	g_MapVoteZoneWidth = iWidth;
	MapVoteZoneAdminMenu(id);
	return PLUGIN_HANDLED;
}

public ChangeLengthOfMapVoteZone(id)
{
	new szAmmount[10], iLength
	
	read_args(szAmmount, 9)
	remove_quotes(szAmmount)
	
	iLength = str_to_num(szAmmount);
	
	if(iLength < 5 || iLength > 10000)
	{
		client_print(id, print_center, "You typed bad value");
		MapVoteZoneAdminMenu(id);
		return PLUGIN_HANDLED;
	}
	
	g_MapVoteZoneLength = iLength;
	MapVoteZoneAdminMenu(id);
	
	return PLUGIN_HANDLED
}

public SetPlayerRespawnEntitiesVisible()
{
	if(!g_ShowPlayersRespawn)
		return;
		
	new Float:fOrigin[3];
	new iEnt = find_ent_by_class(iEnt, "info_player_start");
	while(iEnt)
	{
		pev(iEnt, pev_origin, fOrigin);
		DrawLine(fOrigin[0], fOrigin[1], fOrigin[2], fOrigin[0], fOrigin[1], fOrigin[2]+40.0, 1);
		iEnt = find_ent_by_class(iEnt, "info_player_start");
	}
	
	iEnt = find_ent_by_class(iEnt, "info_player_deathmatch");
	
	while(iEnt)
	{
		pev(iEnt, pev_origin, fOrigin);
		DrawLine(fOrigin[0], fOrigin[1], fOrigin[2]-20.0, fOrigin[0], fOrigin[1], fOrigin[2]+40.0, 0);
		iEnt = find_ent_by_class(iEnt, "info_player_deathmatch");
	}

	if(fOrigin[0] != 0.0 || fOrigin[1] != 0.0 || fOrigin[2] != 0.0)
		set_task(2.0, "CheckIfAdminIsInMenu");
 
}

public CheckIfAdminIsInMenu()
	if(g_IsAdminInStartZoneMenu)
		SetPlayerRespawnEntitiesVisible();
		
new g_CreatedMapVoteZoneIndex;

public MapVoteZoneAdminMenu(id)
{
	new menu = menu_create("MapVote zone options", "MapVoteZoneAdminMenuH");
	new cb =menu_makecallback("MapVoteZoneAdminMenuCb");
	
	static szFormat[64]
	formatex(szFormat, 63, "Change width:\r %d", g_MapVoteZoneWidth)
	menu_additem(menu, szFormat, _, _, cb);
	
	formatex(szFormat, 63, "Change length:\r %d", g_MapVoteZoneLength)
	menu_additem(menu, szFormat, _, _, cb);
	
	menu_additem(menu, "Update Width & Length to last zone", _, _, cb);
	menu_additem(menu, "Remove last MapVote zone", _, _, cb);
	menu_additem(menu, "Remove all MapVote zone",  _, _, cb);
	
	menu_additem(menu, "\yCreate MapVoteZone where I am", _, _, cb);
		
	menu_additem(menu, "Print schema in console", _, _, cb);
	
	menu_setprop(menu, MPROP_EXITNAME, "Back")
	menu_display(id, menu);
}

public MapVoteZoneAdminMenuCb(id, menu, item)
{
	if(g_CreatedMapVoteZoneIndex == VOTE_MAP_COUNT && item == 5)
		return ITEM_DISABLED;
	if(item == 3 && !is_valid_ent(g_MapVoteZoneLastEntity))
		return ITEM_DISABLED;
		
	if(item == 0 || item == 1 || item == 2 || item == 3 || item == 4 || item == 6)
		if(!g_CreatedMapVoteZoneIndex)
			return ITEM_DISABLED;
	return ITEM_ENABLED
}
public MapVoteZoneAdminMenuH(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		ShowAdminMenu(id)
		return;
	}	
	
	switch(item)
	{
		case 0:
		{	
			client_print(id, print_center, "Type width");
			console_cmd( id, "messagemode mapvotezone_select_width")
		}
		
		case 1:
		{
			client_print(id, print_center, "Type length");
			console_cmd( id, "messagemode mapvotezone_select_length")
		}
		
		case 2:
		{
			if(!is_valid_ent(g_MapVoteZoneLastEntity))
			{
				client_print(id, print_center, "You must create entity first!");
				StartZoneAdminMenu(id);
				return;
			}
			
			new Float:w, Float:h, Float:Mins[3], Float:Max[3];
			w = float(g_MapVoteZoneWidth);
			h = float(g_MapVoteZoneLength);
			
			Mins[0] = -w;
			Mins[1] = -h;
			Mins[2] = -50.0
			
			Max[0] = w;
			Max[1] = h;
			Max[2] = 50.0;
			
			entity_set_size(g_MapVoteZoneLastEntity, Mins, Max);
			client_print(id, print_center, "Wait while for reconfiguration result");
			
			MapVoteZoneAdminMenu(id);
		}
		case 3:
		{
			client_print(id, print_center, "Last MapVoteZone removed, wait a while for reconfiguration result")
			if(is_valid_ent(g_MapVoteZoneLastEntity))
			{
				if(is_valid_ent(entity_get_int(g_MapVoteZoneLastEntity, EV_INT_mapvote_header)))
					remove_entity(entity_get_int(g_MapVoteZoneLastEntity, EV_INT_mapvote_header))
				remove_entity(g_MapVoteZoneLastEntity)
			}
			g_MapVoteZoneLastEntity = 0
			g_CreatedMapVoteZoneIndex--;
			MapVoteZoneAdminMenu(id);
		}
		case 4:
		{
			client_print(id, print_center, "All MapVoteZones removed, wait a while for reconfiguration result")
			
			new iEnt = find_ent_by_class(-1, "mapvote1")
			while(iEnt)
			{
				if(is_valid_ent(entity_get_int(iEnt, EV_INT_mapvote_header)))
					remove_entity(entity_get_int(iEnt, EV_INT_mapvote_header))
				remove_entity(iEnt)
				iEnt = find_ent_by_class(iEnt, "mapvote1")
			}
			g_CreatedMapVoteZoneIndex = 0;
			MapVoteZoneAdminMenu(id);
		}
		case 5:
		{
			CreateVoteMapZoneEntity(id)
			MapVoteZoneAdminMenu(id);
		}
		case 6:
		{
			PrintUserMapVoteZoneConfig(id);
			MapVoteZoneAdminMenu(id);
		}
	}
}

public StartZoneAdminMenu(id)
{
	g_IsAdminInStartZoneMenu = true;
	
	new menu = menu_create("StartZone options", "StartZoneAdminMenuH");
	new cb =menu_makecallback("StartZoneAdminMenuCb");
	
	static szFormat[64]
	formatex(szFormat, 63, "Change width:\r %d", g_StartZoneWidth)
	menu_additem(menu, szFormat, _, _, cb);
	
	formatex(szFormat, 63, "Change length:\r %d", g_StartZoneLength)
	menu_additem(menu, szFormat, _, _, cb);
	
	menu_additem(menu, "Update Width & Length", _, _, cb);
	menu_additem(menu, "Remove start zone", _, _, cb);
	
	if(!is_valid_ent(g_StartZoneEntity))
		menu_additem(menu, "\yCreate start zone where I am", _, _, cb);
	else
		menu_additem(menu, "\yChange start zone position", _, _, cb);
		
	menu_additem(menu, "Print schema in console", _, _, cb);
	
	menu_additem(menu, (g_ShowPlayersRespawn?"\rHide showing spawns":"\yShow players spawn point"));
	menu_setprop(menu, MPROP_EXITNAME, "Back")
	menu_display(id, menu);
}

public StartZoneAdminMenuCb(id,menu,item)
{
	if(!is_valid_ent(g_StartZoneEntity))
	{
		if(item == 0 || item == 1 || item == 2 || item == 3 || item == 5)
			return ITEM_DISABLED;
	}
	
	return ITEM_ENABLED;
}

public StartZoneAdminMenuH(id,menu,item)
{
	g_IsAdminInStartZoneMenu = false;
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		ShowAdminMenu(id)
		return
	}
	
	switch(item)
	{
		case 0:
		{	
			client_print(id, print_center, "Type width");
			console_cmd( id, "messagemode startzone_select_width")
		}
		
		case 1:
		{
			client_print(id, print_center, "Type length");
			console_cmd( id, "messagemode startzone_select_length")
		}
		
		case 2:
		{
			if(!is_valid_ent(g_StartZoneEntity))
			{
				client_print(id, print_center, "You must create entity first!");
				StartZoneAdminMenu(id);
				return;
			}
			
			new Float:w, Float:h, Float:Mins[3], Float:Max[3];
			w = float(g_StartZoneWidth);
			h = float(g_StartZoneLength);
			
			Mins[0] = -w;
			Mins[1] = -h;
			Mins[2] = -50.0
			
			Max[0] = w;
			Max[1] = h;
			Max[2] = 50.0;
			
			entity_set_size(g_StartZoneEntity, Mins, Max);
			client_print(id, print_center, "Wait while for reconfiguration result");
			
			StartZoneAdminMenu(id);
		}
		case 3:
		{
			client_print(id, print_center, "StartZone removed, wait a while for reconfiguration result")
			if(is_valid_ent(g_StartZoneEntity))
			{
				remove_entity(entity_get_int(g_StartZoneEntity, EV_INT_startzone_entity))
				remove_entity(g_StartZoneEntity)
			}
			g_StartZoneEntity = 0;
			
			
			StartZoneAdminMenu(id);
		}
		case 4:
		{
			new Float:fOrigin[3];
			pev(id, pev_origin, fOrigin);
	
			CreateStartZoneBox(fOrigin, g_StartZoneWidth, g_StartZoneLength,Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0,0.0});
			StartZoneAdminMenu(id);
		}
		case 5:
		{
			PrintUserStartZoneConfig(id);
			StartZoneAdminMenu(id);
		}
		
		case 6:
		{
			g_ShowPlayersRespawn = !g_ShowPlayersRespawn;
			SetPlayerRespawnEntitiesVisible()
			StartZoneAdminMenu(id);
		}
	}
}

public RepairZoneAdminMenu(id)
{
	new menu = menu_create("RepairZone options", "RepairZoneAdminMenuH");
	new cb =menu_makecallback("RepairZoneAdminMenuCb");
	
	static szFormat[64]
	formatex(szFormat, 63, "Change width:\r %d", g_RepairZoneWidth)
	menu_additem(menu, szFormat, _, _, cb);
	
	formatex(szFormat, 63, "Change length:\r %d", g_RepairZoneLength)
	menu_additem(menu, szFormat, _, _, cb);
	
	menu_additem(menu, "Update Width & Length", _, _, cb);
	menu_additem(menu, "Remove repair zone", _, _, cb);
	
	if(!is_valid_ent(g_RepairZoneEntity))
		menu_additem(menu, "\yCreate repair zone where I am", _, _, cb);
	else
		menu_additem(menu, "\yChange repair zone position", _, _, cb);
		
	menu_additem(menu, "Print schema in console", _, _, cb);
	menu_setprop(menu, MPROP_EXITNAME, "Back")
	menu_display(id, menu);
}

public RepairZoneAdminMenuCb(id,menu,item)
{
	if(!is_valid_ent(g_RepairZoneEntity))
	{
		if(item == 0 || item == 1 || item == 2 || item == 3 || item == 5)
			return ITEM_DISABLED;
	}
	
	return ITEM_ENABLED;
}

public RepairZoneAdminMenuH(id,menu,item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		ShowAdminMenu(id)
		return
	}
	
	switch(item)
	{
		case 0:
		{	
			client_print(id, print_center, "Type width");
			console_cmd( id, "messagemode repairzone_select_width")
		}
		
		case 1:
		{
			client_print(id, print_center, "Type length");
			console_cmd( id, "messagemode repairzone_select_length")
		}
		
		case 2:
		{
			if(!is_valid_ent(g_RepairZoneEntity))
			{
				client_print(id, print_center, "You must create entity first!");
				RepairZoneAdminMenu(id);
				return;
			}
			
			new Float:w, Float:h, Float:Mins[3], Float:Max[3];
			w = float(g_RepairZoneWidth);
			h = float(g_RepairZoneLength);
			
			Mins[0] = -w;
			Mins[1] = -h;
			Mins[2] = -50.0
			
			Max[0] = w;
			Max[1] = h;
			Max[2] = 50.0;
			
			entity_set_size(g_RepairZoneEntity, Mins, Max);
			client_print(id, print_center, "Wait a while for reconfiguration result [ max 10 seconds ]");
			RepairZoneAdminMenu(id);
		}
		case 3:
		{
			client_print(id, print_center, "RepairZone removed, wait a while for reconfiguration result")
			if(is_valid_ent(g_RepairZoneEntity))
			{
				remove_entity(entity_get_int(g_RepairZoneEntity, EV_INT_repairzone_entity))
				remove_entity(g_RepairZoneEntity)
			}
			g_RepairZoneEntity = 0;
			
			
			RepairZoneAdminMenu(id);
		}
		case 4:
		{
			new Float:fOrigin[3];
			pev(id, pev_origin, fOrigin);
	
			CreateRepairZoneBox(fOrigin, g_RepairZoneWidth, g_RepairZoneLength,Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0,0.0});
			RepairZoneAdminMenu(id);
		}
		case 5:
		{
			PrintUserRepairZoneConfig(id);
			RepairZoneAdminMenu(id);
		}
	}
}

public PrintUserStartZoneConfig(id)
{
	if(!is_valid_ent(g_StartZoneEntity))
	{
		client_print(id, print_center, "Can't produce text, if entity is not valid! Create new one.");
		return
	}
	
	client_print(id, print_center, "Copy text from console, and paste it to configuration file of this map!");
	client_print(id, print_console, "=========Copy text below=========");
	client_print(id, print_console, "");
	client_print(id, print_console, "[START_ZONE_ENTITY]");
	
	new Float:Origin[3], Float:Mins[3], Float:Max[3], szFormat[128];
	
	pev(g_StartZoneEntity, pev_origin, Origin);
	pev(g_StartZoneEntity, pev_mins, Mins);
	pev(g_StartZoneEntity, pev_maxs, Max);

	formatex(szFormat, charsmax(szFormat), "%0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f",
		Origin[0], Origin[1], Origin[2],
		Mins[0], Mins[1], Mins[2],
		Max[0], Max[1], Max[2]);
	 
	client_print(id, print_console, szFormat);
	
	get_mapname(szFormat, charsmax(szFormat));
	client_print(id, print_console, "");
	client_print(id, print_console, "==to %s.cfg configuration file before loading waves([LOAD_STANDARD_WAVE] too!)==", szFormat);
}

public PrintUserMapVoteZoneConfig(id)
{
	if(!is_valid_ent(g_MapVoteZoneLastEntity) && !g_CreatedMapVoteZoneIndex)
	{
		client_print(id, print_center, "Can't produce text, if entity is not valid! Create new one.");
		return
	}

	
	client_print(id, print_center, "Copy text from console, and paste it to configuration file of this map!");
	client_print(id, print_console, "=========Copy text below=========");
	client_print(id, print_console, "");
	client_print(id, print_console, "[MAP_VOTE_ZONE_%d_ENTITY]", g_CreatedMapVoteZoneIndex);
	
	new Float:Origin[3], Float:Mins[3], Float:Max[3], szFormat[128];
	
	pev(g_MapVoteZoneLastEntity, pev_origin, Origin);
	pev(g_MapVoteZoneLastEntity, pev_mins, Mins);
	pev(g_MapVoteZoneLastEntity, pev_maxs, Max);

	formatex(szFormat, charsmax(szFormat), "%0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f",
		Origin[0], Origin[1], Origin[2],
		Mins[0], Mins[1], Mins[2],
		Max[0], Max[1], Max[2]);
	 
	client_print(id, print_console, szFormat);
	
	get_mapname(szFormat, charsmax(szFormat));
	client_print(id, print_console, "");
	client_print(id, print_console, "==to %s.cfg configuration file before loading waves([LOAD_STANDARD_WAVE] too!)==", szFormat);
}


public PrintUserRepairZoneConfig(id)
{
	if(!is_valid_ent(g_RepairZoneEntity))
	{
		client_print(id, print_center, "Can't produce text, if entity is not valid! Create new one.");
		return
	}
	
	client_print(id, print_center, "Copy text from console, and paste it to configuration file of this map!");
	client_print(id, print_console, "=========Copy text below=========");
	client_print(id, print_console, "");
	client_print(id, print_console, "[REPAIR_ZONE_ENTITY]");
	
	new Float:Origin[3], Float:Mins[3], Float:Max[3], szFormat[128];
	
	pev(g_RepairZoneEntity, pev_origin, Origin);
	pev(g_RepairZoneEntity, pev_mins, Mins);
	pev(g_RepairZoneEntity, pev_maxs, Max);

	formatex(szFormat, charsmax(szFormat), "%0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f",
		Origin[0], Origin[1], Origin[2],
		Mins[0], Mins[1], Mins[2],
		Max[0], Max[1], Max[2]);
	 
	client_print(id, print_console, szFormat);
	
	get_mapname(szFormat, charsmax(szFormat));
	client_print(id, print_console, "");
	client_print(id, print_console, "==to %s.cfg configuration file before loading waves([LOAD_STANDARD_WAVE] too!)==", szFormat);
}

public CreateStartZoneBox(Float:fValidOrigin[3], Width, Length, Float:fMins[3], Float:fMax[3])
{	
	if(is_valid_ent(g_StartZoneEntity)) 
	{
		remove_entity(entity_get_int(g_StartZoneEntity, EV_INT_startzone_entity));
		remove_entity(g_StartZoneEntity);
	}
	new Float:fOrigin[3];
	fOrigin = fValidOrigin;
	
	ResetPlayersIsInStartZone();
	
	g_StartZoneEntity = create_entity("trigger_multiple");
	new iEnt = create_entity("env_sprite");
	entity_set_string(g_StartZoneEntity, EV_SZ_classname, "startzone");
	entity_set_vector(g_StartZoneEntity, EV_VEC_origin, fOrigin);
	
	fOrigin[2] += 55.0
	entity_set_vector(iEnt, EV_VEC_origin, fOrigin)
	entity_set_model(iEnt, "sprites/TD/startzone.spr");
	entity_set_float(iEnt, EV_FL_scale, 0.45);
	fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255);
	
	entity_set_int(g_StartZoneEntity, EV_INT_startzone_entity, iEnt);
	dllfunc(DLLFunc_Spawn, g_StartZoneEntity);
	
	new Float:w, Float:h, Float:Mins[3], Float:Max[3];
	
	if(Width == 0 && Length == 0)
	{
		Mins = fMins;
		Max = fMax;
		
		if(DEBUG)
		{
			log_to_file(LOG_FILE, "---: Creating startzone at Origin[0]: %0.1f | Origin[1]: %0.1f | Origin[2]: %0.1f", fOrigin[0], fOrigin[1], fOrigin[2])
			log_to_file(LOG_FILE, "---: Mins[0]: %0.1f | Mins[1]: %0.1f | Mins[2]: %0.1f", fMins[0], fMins[1], fMins[2])
			log_to_file(LOG_FILE, "---: Max[0]: %0.1f | Max[1]: %0.1f | Max[2]: %0.1f", fMax[0], fMax[1], fMax[2])
		}
	}
	else
	{
		w = float(Width);
		h = float(Length);
		
		Mins[0] = -w;
		Mins[1] = -h;
		Mins[2] = -50.0
		
		Max[0] = w;
		Max[1] = h;
		Max[2] = 50.0;
	}
	
	entity_set_size(g_StartZoneEntity, Mins, Max);
	
	set_pev(g_StartZoneEntity, pev_solid, SOLID_TRIGGER);
	set_pev(g_StartZoneEntity, pev_movetype, MOVETYPE_NONE);
	
	CreateBox(g_StartZoneEntity, 1)
	
	set_pev(g_StartZoneEntity, pev_nextthink, get_gametime() + 1.9)
}

public fwStartZoneDisplay(iEnt)
{
	CreateBox(iEnt, 1)
	set_pev(iEnt, pev_nextthink, get_gametime() + 1.9)
}

public CreateRepairZoneBox(Float:fOrigin[3], Width, Length, Float:fMins[3], Float:fMax[3])
{	
	if(is_valid_ent(g_RepairZoneEntity)) 
	{
		remove_entity(entity_get_int(g_RepairZoneEntity, EV_INT_repairzone_entity));
		remove_entity(g_RepairZoneEntity);
	}
	
	ResetPlayersIsInRepairZone();
	
	g_RepairZoneEntity = create_entity("trigger_multiple");
	new iEnt = create_entity("env_sprite");
	
	entity_set_string(g_RepairZoneEntity, EV_SZ_classname, "repairzone");
	entity_set_vector(g_RepairZoneEntity, EV_VEC_origin, fOrigin);
	
	fOrigin[2] += 50.0
	entity_set_vector(iEnt, EV_VEC_origin, fOrigin)
	entity_set_model(iEnt, "sprites/TD/repairzone.spr");
	entity_set_float(iEnt, EV_FL_scale, 0.45);
	fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255);
	
	entity_set_int(g_RepairZoneEntity, EV_INT_repairzone_entity, iEnt);
	dllfunc(DLLFunc_Spawn, g_RepairZoneEntity);
	
	new Float:w, Float:h, Float:Mins[3], Float:Max[3];
	
	if(Width == 0&& Length == 0)
	{
		Mins = fMins;
		Max = fMax;
		
		if(DEBUG)
		{
			log_to_file(LOG_FILE, "---: Creating repairzone at Origin[0]: %0.1f | Origin[1]: %0.1f | Origin[2]: %0.1f", fOrigin[0], fOrigin[1], fOrigin[2])
			log_to_file(LOG_FILE, "---: Mins[0]: %0.1f | Mins[1]: %0.1f | Mins[2]: %0.1f", fMins[0], fMins[1], fMins[2])
			log_to_file(LOG_FILE, "---: Max[0]: %0.1f | Max[1]: %0.1f | Max[2]: %0.1f", fMax[0], fMax[1], fMax[2])	
		}
	}
	else
	{
		w = float(Width);
		h = float(Length);
		
		Mins[0] = -w;
		Mins[1] = -h;
		Mins[2] = -50.0
		
		Max[0] = w;
		Max[1] = h;
		Max[2] = 50.0;
	}
	
	entity_set_size(g_RepairZoneEntity, Mins, Max);
	
	set_pev(g_RepairZoneEntity, pev_solid, SOLID_TRIGGER);
	set_pev(g_RepairZoneEntity, pev_movetype, MOVETYPE_NONE);
	
	CreateBox(g_RepairZoneEntity, 0)
	set_pev(g_RepairZoneEntity, pev_nextthink, get_gametime() + 9.9)
}

public fwRepairZoneDisplay(iEnt)
{
	if(g_IsGameStarted)
	{
		CreateBox(iEnt, 0)
		set_pev(iEnt, pev_nextthink, get_gametime() + 9.9)
	}
	else
	{
		fm_set_rendering(entity_get_int(iEnt, EV_INT_repairzone_entity), kRenderFxNone, 0, 0, 0, kRenderTransAdd, 0);
	}
}

public fwStartZoneTouched(ent, id)
{
	if(g_IsPlayerInStartZone[id])
		return;
		
	g_IsPlayerInStartZone[id] = true;
	
	set_task(0.5, "CheckIfPlayerIsInStartZone", id + TASK_START_ZONE);
}

public fwRepairZoneTouched(ent, id)
{
	if(g_IsPlayerInRepairZone[id] || !g_IsGameStarted)
		return;
		
	g_IsPlayerInRepairZone[id] = true;
	g_PlayerTimeInRepairZone[id] = g_ConfigValues[CFG_REPAIR_ZONE_TIME];
	
	PlayerIsInRepairZone(id + TASK_IS_IN_REPAIR_ZONE)
}

public PlayerIsInRepairZone(id)
{
	id -= TASK_IS_IN_REPAIR_ZONE;
	
	new entlist[2]
	static maxTowerHealth;
	if(!maxTowerHealth) maxTowerHealth = g_ConfigValues[CFG_TOWER_HEALTH]
	
	if(!find_sphere_class(id, "repairzone", 1.0 , entlist, 1))
	{
		g_IsPlayerInRepairZone[id] = false;
		
		if(id == g_TowerUpgradingPlayerIndex)
			g_TowerUpgradingPlayerIndex = 0;

		return;
	}
	static cost;
	if(!cost) cost = g_ConfigValues[CFG_REPAIR_ZONE_COST];
	
	if(g_PlayerInfo[id][PLAYER_GOLD] < cost)
	{
		if(g_TowerHealth  >= maxTowerHealth)
		{
			set_hudmessage(255, 0, 0, 0.06, 0.70, 1, 1.0, 2.1, 0.2, 0.2, -1)
			ShowSyncHudMsg(id, g_SyncHudRepair, "Tower is not damaged!");
		} 
		else
		{
			set_hudmessage(255, 0, 0, 0.06, 0.70, 1, 1.0, 2.1, 0.2, 0.2, -1)
			ShowSyncHudMsg(id, g_SyncHudRepair, "You don't have %d gold", cost);
		}
		set_task(1.0, "PlayerIsInRepairZone", id + TASK_IS_IN_REPAIR_ZONE)
		
		return;
	}
	if(g_ConfigValues[CFG_REPAIR_ZONE_ONE_PLAYER] == 1)
	{
		if(g_TowerUpgradingPlayerIndex != id && g_TowerUpgradingPlayerIndex != 0)
		{
			set_hudmessage(60, 255, 0, 0.06, 0.70, 1, 1.0, 2.1, 0.2, 0.2, -1)
			ShowSyncHudMsg(id, g_SyncHudRepair, "Tower is being upgraded by other player");
			
			set_task(1.0, "PlayerIsInRepairZone", id + TASK_IS_IN_REPAIR_ZONE)
			return;
		}
	}
	
	static playerTime; playerTime =  g_PlayerTimeInRepairZone[id] 
	static maxBlocks; maxBlocks = g_ConfigValues[CFG_REPAIR_ZONE_BLOCKS];
	
	g_TowerUpgradingPlayerIndex  = id;
	
	if(playerTime == 0)
	{
		if(g_TowerHealth == maxTowerHealth)
		{
			set_hudmessage(255, 0, 0, 0.06, 0.70, 1, 1.0, 2.1, 0.2, 0.2, -1)
			ShowSyncHudMsg(id, g_SyncHudRepair, "Tower is not damaged! Repairing not completed.");
		} 
		else if((++g_PlayerRepairedBlock[id]) == maxBlocks || maxBlocks == 0)
		{
			new szName[33];
			get_user_name(id, szName, 32);
			
			set_hudmessage(0, 255, 0, 0.06, 0.70, 1, 1.0, 2.1, 0.2, 0.2, -1)
			ShowSyncHudMsg(id, g_SyncHudRepair, "Tower repaired!");
			
			static amount; 
			if(!amount) amount = g_ConfigValues[CFG_REPAIR_ZONE_AMOUNT];
			
			g_PlayerRepairedBlock[id] = 0;
			g_PlayerInfo[id][PLAYER_GOLD] -= cost;
			
			if(g_TowerHealth + amount >  maxTowerHealth)
				g_TowerHealth  = maxTowerHealth;
			else
				g_TowerHealth  += amount;
			
			ColorChat(0, GREEN, "%s^x01 Defender %s has just repaired Tower about %d HP", CHAT_PREFIX, szName, amount);
		}
		else
		{
			set_hudmessage(0, 255, 0, 0.06, 0.70, 1, 1.0, 2.1, 0.2, 0.2, -1)
			ShowSyncHudMsg(id, g_SyncHudRepair, "Bulding %d block completed!", g_PlayerRepairedBlock[id]);
		}
		
		g_PlayerTimeInRepairZone[id] = g_ConfigValues[CFG_REPAIR_ZONE_TIME];
		set_task(2.0, "PlayerIsInRepairZone", id + TASK_IS_IN_REPAIR_ZONE)
		
		return;
	}
	
	if(g_TowerHealth >= maxTowerHealth)
	{
		set_hudmessage(255, 0, 0, 0.06, 0.70, 1, 1.0, 2.1, 0.2, 0.2, -1)
		ShowSyncHudMsg(id, g_SyncHudRepair, "Tower is not damaged!");
	}
	else
	{
		set_hudmessage(255, 0, 0, 0.06, 0.70, 1, 1.0, 2.1, 0.2, 0.2, -1)
		ShowSyncHudMsg(id, g_SyncHudRepair, "Wait %d %s to build block [%d / %d] [Tower repair cost: %d gold]", playerTime, playerTime == 1 ? "second" : "seconds",  g_PlayerRepairedBlock[id]+1, maxBlocks, cost);
		
		g_PlayerTimeInRepairZone[id] --;
	}

	set_task(1.0, "PlayerIsInRepairZone", id + TASK_IS_IN_REPAIR_ZONE)
}

public CheckArePlayersInStartZone()
{	
	if(!is_valid_ent(g_StartZoneEntity))
	{
		set_hudmessage(255, 0, 0, 0.06, 0.63, 1, 1.0, 1.1, 0.2, 0.2, 3)
		ShowSyncHudMsg(0, g_SyncHudGameInfo, "StartZone is not exist. Create new one!");
		
		return;
	}
	
	new iAlivePlayers = GetAlivePlayers();
	if(iAlivePlayers == 0)
	{
		set_hudmessage(255, 0, 0, 0.06, 0.63, 1, 1.0, 1.1, 0.2, 0.2, 3)
		ShowSyncHudMsg(0, g_SyncHudGameInfo, "Waiting for players...!");
		
		return
	}
	new iPlayersNeeded ;
	
	if((g_ConfigValues[CFG_ONE_PLAYER_MODE]== 0 && iAlivePlayers == 1) || iAlivePlayers == 2)
		iPlayersNeeded = 2;
	else
		iPlayersNeeded = floatround((iAlivePlayers*0.75), floatround_round)
		
	new iPlayersInZone = GetPlayersNumInZone();
	
	if(iPlayersInZone >= iPlayersNeeded)
	{
		checkPlayerTime--;
		
		if(checkPlayerTime == 0)
		{

			ResetPlayersIsInStartZone();
			
			remove_entity(entity_get_int(g_StartZoneEntity, EV_INT_startzone_entity))
			remove_entity(g_StartZoneEntity);
		
			g_StartZoneEntity = 0;
			g_IsGameStarted = true;
			
			set_hudmessage(0, 255, 0, 0.06, 0.63, 1, 1.0, 1.1, 0.2, 0.2, 3)
			ShowSyncHudMsg(0, g_SyncHudGameInfo, "Game will be started in 10 seconds...");
			
			client_cmd(0, "spk sound/%s", g_SoundFile[SND_CLEAR_WAVE]);
			
			set_task(10.0, "StartNextWave", TASK_START_WAVE); 
			if(is_valid_ent(entity_get_int(g_RepairZoneEntity, EV_INT_repairzone_entity)))
			{
				entity_set_float(g_RepairZoneEntity, EV_FL_nextthink, get_gametime() + 0.1);
				
				fm_set_rendering(entity_get_int(g_RepairZoneEntity, EV_INT_repairzone_entity), kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255);
				set_hudmessage(255, 20, 0, 0.06, 0.63, 1, 1.0, 9.8, 0.2, 0.2, 3)
				ShowSyncHudMsg(0, g_SyncHudRepair, "^n== REPAIR ZONE MAP CONFIGURATION ==^nIf you want to repair tower, go to repair zone.^nRepair zone cost: %d gold^nRepair zone time: %d seconds^nRepair zone amount: %d HP", g_ConfigValues[CFG_REPAIR_ZONE_COST], g_ConfigValues[CFG_REPAIR_ZONE_TIME], g_ConfigValues[CFG_REPAIR_ZONE_AMOUNT]);
			}
			remove_task(TASK_CHECK_STARTZONE)
		}
		else if(!g_IsAdminInStartZoneMenu)
		{
			set_hudmessage(0, 255, 0, 0.06, 0.63, 1, 1.0, 1.1, 0.2, 0.2, 3)
			ShowSyncHudMsg(0, g_SyncHudGameInfo, "Stay yet %d %s in start zone...^n%s created by %s", checkPlayerTime, checkPlayerTime == 1 ? "second" : "seconds",  PLUGIN, AUTHOR);
		}
		else
		{
			set_hudmessage(22, 255, 125, 0.06, 0.63, 1, 1.0, 1.1, 0.2, 0.2, 3)
			ShowSyncHudMsg(0, g_SyncHudGameInfo, "Admin is working... [is in admin menu]");
		}
	}
	else
	{
		checkPlayerTime = g_ConfigValues[CFG_START_ZONE_STAY_TIME] + 1;
		
		new iPlayersLeft = (iPlayersNeeded - iPlayersInZone )
		for(new i = 1; i <= g_MaxPlayers ; i++)
		{
			if(is_user_alive(i))
			{
				if(!g_IsPlayerInStartZone[i])
				{
					set_hudmessage(255, 255, 0, 0.06, 0.63, 1, 1.0, 1.1, 0.2, 0.2, 3)
					ShowSyncHudMsg(0, g_SyncHudGameInfo, "%d %s left to start game. Please go to start zone...", iPlayersLeft,iPlayersLeft== 1 ? "player" : "players");
				}
				else
				{
					set_hudmessage(100, 255, 0, 0.06, 0.63, 1, 1.0, 1.1, 0.2, 0.2, 3)
					ShowSyncHudMsg(0, g_SyncHudGameInfo, "%d %s left to start game. Please wait for %s...", iPlayersLeft ,iPlayersLeft == 1 ? "player" : "players", iPlayersLeft == 1 ? "last player" : "other players");
				}
			}
		}
	}
}

public CheckGameTask()
{
	for(new i = 1 ; i <= g_MaxPlayers ; i++)
	{
		if(is_user_connected(i))
		{
			if(get_user_team(i) == 1 || get_user_team(i) == 2)
			{	
				/* Respawn All not alives player */
				if(!is_user_alive(i))
				{
					if(g_ConfigValues[CFG_AUTO_RESPAWN])
						CmdRespawnPlayerPost(i + TASK_RESPAWN)
				}
				/* Check is player AfK */
				else if(g_ConfigValues[CFG_AFK_TIME])
				{
					new Float:fOrigin[3];
					entity_get_vector(i, EV_VEC_origin, fOrigin);

					if(fOrigin[0] == g_PlayerOrigin[i][0]
					&& fOrigin[1] == g_PlayerOrigin[i][1]
					&& fOrigin[2] == g_PlayerOrigin[i][2])
					{
						new iLimit = (g_ConfigValues[CFG_AFK_TIME] / 5)
						if(++g_PlayerAfkWarns[i] == iLimit)
						{
							new szName[33];
							get_user_name(i, szName, 32);
							g_PlayerAfkWarns[i] = 0;
							user_silentkill(i);

							cs_set_user_team(i, CS_TEAM_SPECTATOR, CS_DONTCHANGE);
							ColorChat(0, GREEN, "%s^x01 Defender '%s' was moved to spectator becouse he was afk about %d seconds.", CHAT_PREFIX, szName, g_ConfigValues[CFG_AFK_TIME]);
						}
						else if(g_PlayerAfkWarns[i] >= floatround( iLimit / 2.0 ) )
						{
							new iLeft = (g_ConfigValues[CFG_AFK_TIME] - (g_PlayerAfkWarns[i] * 5));

							if(iLeft <= 5)
							{
								set_dhudmessage(255, 0, 0, -1.0, 0.55, 1, 1.0, 4.5)
								show_dhudmessage(i, "AFK to SPEC^n - MOVE TO SPEC AFTER %d SECONDS -", iLeft);
							}
							else if(5 < iLeft < 20)
							{
								set_dhudmessage(255, 128, 0, -1.0, 0.55, 1, 1.0, 4.5)
								show_dhudmessage(i, "AFK to SPEC^n - MOVE TO SPEC AFTER %d SECONDS -", iLeft);
							}
							else
							{
								set_dhudmessage(255, 255, 0, -1.0, 0.55, 1, 1.0, 4.5)
								show_dhudmessage(i, "AFK to SPEC^n - MOVE TO SPEC AFTER %d SECONDS -", iLeft);
							}	
						}
					}
					else
					{
						g_PlayerAfkWarns[i] = 0;
					}
					g_PlayerOrigin[i][0] = fOrigin[0];
					g_PlayerOrigin[i][1] = fOrigin[1];
					g_PlayerOrigin[i][2] = fOrigin[2];
				}
			}
		}
	}

	if(g_IsGameStarted)
	{
		if(GetAlivePlayers() == 0)
		{
			ColorChat(0, GREEN, "%s^x01 Game has been resetted becouse there are not alive players.", CHAT_PREFIX);
			ResetGame();
		}
	}
}

public ResetPlayersIsInStartZone()
{
	for(new i = 1; i <= g_MaxPlayers; i++)
		g_IsPlayerInStartZone[i] = false;
}

public ResetPlayersIsInRepairZone()
{
	for(new i = 1; i <= g_MaxPlayers; i++)
		g_IsPlayerInRepairZone[i] = false;
}

public ResetGame()
{
	if(g_ActualWave == 0)
		return;
		
	ResetPlayersIsInStartZone();
	ResetPlayersIsInRepairZone();

	RemoveAllMonsters();
	
	g_ActualWave = 0;

	remove_task(TASK_START_WAVE);
	remove_task(TASK_COUNTDOWN);
	remove_task(TASK_SEND_MONSTERS);

	g_VotedForNextMapNum = 0;
	g_IsGameEnded = PLAYERS_PLAYING;
	g_IsGameStarted = false;

	g_TowerUpgradingPlayerIndex = 0
	CreateStartZoneBox(g_StartZoneCoordinations[0], 0, 0, g_StartZoneCoordinations[1], g_StartZoneCoordinations[2]);
	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Game has been reseted.")
		
	set_task(1.0, "CheckArePlayersInStartZone", TASK_CHECK_STARTZONE, _, _, "b")
}

public GetAlivePlayers()
{
	new num = 0;
	for(new i = 1 ; i <= g_MaxPlayers; i ++)
	{
		if(is_user_alive(i))
			num++;
	}
	
	return num;
}
public CheckIfPlayerIsInStartZone(id)
{
	id -= TASK_START_ZONE;
	
	if(g_IsGameStarted || !is_user_alive(id) || !is_user_connected(id))
		return;
		
	new entlist[2]
	if(!find_sphere_class(id, "startzone", 1.0 , entlist, 1))
	{
		g_IsPlayerInStartZone[id] = false;
		return;
	}
	
	set_task(0.5, "CheckIfPlayerIsInStartZone", id + TASK_START_ZONE);
}

public fw_SetModel(entity, const model[])
{
	static Float:dmgtime;
	new type;
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime == 0.0)
		return FMRES_IGNORED;
	
	if (equal(model[7], "w_he", 4))
		type = GRENADE_NAPALM;
	else if(equal(model[7], "w_sm", 4) )
		type = GRENADE_FROZEN;
	else if(equal(model[7], "w_fl", 4))
		type = GRENADE_STOP
	else
		return FMRES_IGNORED;
		
	static id; id = pev(entity, pev_owner);
	static iWeaponEntity; iWeaponEntity = fm_get_user_current_weapon_ent(id)
	
	if(type == GRENADE_NAPALM)
		fm_set_rendering(entity, kRenderFxGlowShell, 255, 50, 0, kRenderNormal, 16)
	else if(type == GRENADE_FROZEN)
		fm_set_rendering(entity, kRenderFxGlowShell, 0, 50, 255, kRenderNormal, 16)
	else if(type == GRENADE_STOP)
		fm_set_rendering(entity, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 16)
		
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) 
	write_short(entity) 
	write_short(g_SpriteTrail) 
	write_byte(10) 
	write_byte(10) 
	
	if(type == GRENADE_NAPALM)
	{
		write_byte(255) 
		write_byte(50) 
		write_byte(0) 
	}
	else if(type == GRENADE_FROZEN)
	{
		write_byte(0) 
		write_byte(100) 
		write_byte(255) 
	}
	else
	{
		write_byte(0) 
		write_byte(255) 
		write_byte(0) 
	}	
	write_byte(200)
	message_end()

	entity_set_int(iWeaponEntity, EV_INT_grenade_ammo , entity_get_int(iWeaponEntity, EV_INT_grenade_ammo) - 1)
	entity_set_int(entity, EV_INT_grenade_type, type)
	
	if(type == GRENADE_NAPALM)
		engfunc(EngFunc_SetModel, entity, GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_W))
	else if(type == GRENADE_FROZEN)
		engfunc(EngFunc_SetModel, entity, GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_W))
	else if(type == GRENADE_STOP)
		engfunc(EngFunc_SetModel, entity, GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_W))
	return FMRES_SUPERCEDE;
}

public fw_ThinkGrenade(entity)
{
	if (!pev_valid(entity)) 
		return HAM_IGNORED;
	
	static type; type = entity_get_int(entity, EV_INT_grenade_type)
	
	if(type == GRENADE_NAPALM || type== GRENADE_FROZEN || type == GRENADE_STOP)
	{		
		static Float:dmgtime
		pev(entity, pev_dmgtime, dmgtime)
		
		if (dmgtime > get_gametime())
			return HAM_IGNORED;
			
		if(type == GRENADE_NAPALM)
			grenade_explode(entity, GRENADE_NAPALM)
		else if(type == GRENADE_FROZEN)
			grenade_explode(entity, GRENADE_FROZEN)
		else
			grenade_explode(entity, GRENADE_STOP)
	
		remove_entity(entity);
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

/* If grenade touched monster */
public fw_TouchMonster(iPlayer, iMonster){
	if (!IsMonster(iMonster))
		return;
	
	if (!task_exists(iPlayer + TASK_GRENADE_NAPALM) || task_exists(iMonster + TASK_GRENADE_NAPALM))
		return;
	
	static params[2]
	params[0] = g_ConfigValues[CFG_NAPALM_NADE_DURATION] * 2 
	params[1] = iPlayer	

	set_task(0.1, "burning_flame", iMonster + TASK_GRENADE_NAPALM, params, sizeof params)
}

public fw_Item_Deploy_Post(entity)
{
	static type; type = entity_get_int(entity, EV_INT_grenade_type)
	if(type == GRENADE_NO_SPECIAL)
		return;
		
	static owner; owner = fm_get_weapon_ent_owner(entity)
	if(type == GRENADE_NAPALM)
	{
		set_pev(owner, pev_viewmodel2,GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_V))
		set_pev(owner, pev_weaponmodel2,GET_MODEL_DIR_FROM_FILE(g_ModelFileNapalmGrenade_P))
	}
	else if(type == GRENADE_FROZEN)
	{
		set_pev(owner, pev_viewmodel2,GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_V))
		set_pev(owner, pev_weaponmodel2,GET_MODEL_DIR_FROM_FILE(g_ModelFileFrozenGrenade_P))
	}
	else
	{
		set_pev(owner, pev_viewmodel2,GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_V))
		set_pev(owner, pev_weaponmodel2,GET_MODEL_DIR_FROM_FILE(g_ModelFileStopGrenade_P))
	}
}

public LogEventNewRound()
	g_CanPlayerWalk = true

public HLTV()
	g_CanPlayerWalk = false

new g_DirectFromMainMenu[33];
public ShowShopMenu(id, fromMenu) 
{
	g_DirectFromMainMenu[id] = fromMenu;
	
	static szFormat[128]

	formatex(szFormat, charsmax(szFormat), "\yYou have \w%d\y gold!^n\rWhat you want to buy?", g_PlayerInfo[id][PLAYER_GOLD])
	
	new iMenu = menu_create(szFormat, "ShowShopMenuH")
	new iCb = menu_makecallback("ShowShopMenuCb")
	
	for(new i = 1; i <= g_ShopItemsNum; i++) 
	{
		
		if(g_ShopPlayerBuy[id][i] )
			formatex(szFormat, charsmax(szFormat), "\d%s \r[ BOUGHT ]",  g_ShopItemsName[i])
		else 
		{
			if(g_ShopItemsPrice[i] > 0) 
				formatex(szFormat, charsmax(szFormat), "%s \w[ \r%d\y GOLD\w ]", g_ShopItemsName[i], g_ShopItemsPrice[i])
			else
				formatex(szFormat, charsmax(szFormat), "%s \w[ \rFREE\w ]",  g_ShopItemsName[i])
		}
			
		menu_additem(iMenu, szFormat, _, _, iCb)
	}
	
	if(fromMenu)
		menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	menu_display(id, iMenu)
}

public ShowShopMenuCb(id, menu, item) 
{
	new iPlayerGold = g_PlayerInfo[id][PLAYER_GOLD];
	
	for(new i = 1; i <= g_ShopItemsNum;i++) 
	{
		if((item == i-1 &&  iPlayerGold < g_ShopItemsPrice[i]) || (item == i-1 && g_ShopPlayerBuy[id][i]))
			return ITEM_DISABLED
	}
	return ITEM_ENABLED
}

public ShowShopMenuH(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu)
		if(g_DirectFromMainMenu[id]) {
			g_DirectFromMainMenu[id] = 0;
			CmdPlayerMenu(id)
		}
		return PLUGIN_CONTINUE
	}
	
	item++;
	
	new szKey[5];
	new szTitle[256];
	
	num_to_str(item, szKey, 4);
	
	formatex(szTitle, charsmax(szTitle), "\wName: \y%s ^n\wDescription: \y%s ^n\wPrice: \y%d\w gold ^nOne per map: %s ^n\rYou buy?",  
	g_ShopItemsName[item], 
	g_ShopItemsDesc[item],
	g_ShopItemsPrice[item], 
	g_ShopOnePerMap[item] ?  "\rYes": "\yNo")	
	
	new iMenu = menu_create(szTitle, "ShowShopMenu2H")
	menu_additem(iMenu, "\yBuy", szKey)
	menu_additem(iMenu, "\rBack" )	
	menu_display(id, iMenu)
	return PLUGIN_CONTINUE
}

public ShowShopMenu2H(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	
	if(item == 0) 
	{
		new szItem[6], access, callback, iName[4];
		menu_item_getinfo(menu, item, access, szItem,5, iName, 4, callback);
		
		PlayerBuyItem(id, str_to_num(szItem))
	}
	else
		ShowShopMenu(id, g_DirectFromMainMenu[id])
		
	return PLUGIN_CONTINUE
}

public PlayerBuyItem(id, iItemIndex) 
{
	new iRet;
	ExecuteForward(g_ForwardShopItemSelected, iRet, id, iItemIndex);
	
	if(iRet != PLUGIN_CONTINUE)
		return iRet;
		
	ColorChat(id, GREEN, "%s^x01 You buy: %s", CHAT_PREFIX, g_ShopItemsName[iItemIndex])
	ColorChat(id, GREEN, "%s^x01 Description: %s", CHAT_PREFIX, g_ShopItemsDesc[iItemIndex])
	ColorChat(id, GREEN, "%s^x01 For: %d gold", CHAT_PREFIX, g_ShopItemsPrice[iItemIndex])
	
	if(g_ShopOnePerMap[iItemIndex]) 
		g_ShopPlayerBuy[id][iItemIndex] = 1;
	
	g_PlayerInfo[id][PLAYER_GOLD] -= g_ShopItemsPrice[iItemIndex]
	
	client_cmd(id, "spk sound/%s", g_SoundFile[SND_COIN]);
	
	return PLUGIN_CONTINUE
}

public CmdPlayerSkillMenu(id) 
{
	static szFormat[128]
	
	new iMenu = menu_create("Your skills:", "CmdPlayerSkillMenuH")
	new iCb = menu_makecallback("CmdPlayerSkillMenuCb");
	new iPlayerLevel = g_PlayerInfo[id][PLAYER_LEVEL] ;
	
	for(new i; i < MAX_LEVEL ; i++) 
	{
		if(i == 0)
			formatex(szFormat, charsmax(szFormat), g_SkillsDesc[i])
		else if(iPlayerLevel <= i)
			formatex(szFormat, charsmax(szFormat), "%s \r[NEED FRAGS: %d]",  g_SkillsDesc[i], g_LevelFrags[i] ) 
		else
			formatex(szFormat, charsmax(szFormat), "%s \y[UNLOCKED]",  g_SkillsDesc[i]) 
		menu_additem(iMenu, szFormat, _, _, iCb);
	}
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu);
}

public CmdPlayerSkillMenuCb(id, menu, item) 
{
	if(item == 0)
		return ITEM_ENABLED;
		
	new iPlayerLevel = g_PlayerInfo[id][PLAYER_LEVEL] ;
	item++;
	
	for(new i = 1; i <= MAX_LEVEL; i++ ) 
		if(item == i && iPlayerLevel < i) 
			return ITEM_DISABLED;
	
	return ITEM_ENABLED;
}

public CmdPlayerSkillMenuH(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		CmdPlayerMenu(id)
		return PLUGIN_CONTINUE
	}
	
	CmdPlayerSkillMenu(id)
	return PLUGIN_CONTINUE;
}

public CheckPlayerLevel(iPlayer)
 {
	if(!is_user_connected(iPlayer))
		return PLUGIN_CONTINUE
	if(g_PlayerInfo[iPlayer][PLAYER_LEVEL] == MAX_LEVEL)
		return PLUGIN_CONTINUE;
		
	while(g_PlayerInfo[iPlayer][PLAYER_FRAGS] >= g_LevelFrags[g_PlayerInfo[iPlayer][PLAYER_LEVEL]])
	{	
		new szName[33];
		get_user_name(iPlayer, szName, 32);
		g_PlayerInfo[iPlayer][PLAYER_LEVEL]++

		ColorChat(0, GREEN, "%s^x01 Defender^x04 %s^x01 has just reached %d level!", CHAT_PREFIX, szName, g_PlayerInfo[iPlayer][PLAYER_LEVEL]);
		ColorChat(iPlayer, GREEN, "%s^x01 You earned level %d!", CHAT_PREFIX,  g_PlayerInfo[iPlayer][PLAYER_LEVEL])
		ColorChat(iPlayer, GREEN, "%s^x01 You have new skill! Type '/skill' to get more information!", CHAT_PREFIX)
		
		client_cmd(iPlayer, "spk sound/%s", g_SoundFile[SND_PLAYER_LEVELUP])

		GiveUserSkillsByLevel(iPlayer, g_PlayerInfo[iPlayer][PLAYER_LEVEL]);

		switch(g_PlayerInfo[iPlayer][PLAYER_LEVEL])
		{
			case 6: GiveUserNapalmGrenade(iPlayer);
			case 9: GiveUserFrozenGrenade(iPlayer);		
		}
	}
	return PLUGIN_CONTINUE
}

public GiveUserNapalmTask(id)
{
	id -= TASK_GIVE_NAPALM;
	
	if(!is_user_connected(id))
		remove_task(id + TASK_GIVE_NAPALM)
		
	if(is_user_alive(id)) 
		GiveUserNapalmGrenade(id)
}

public GiveUserFrozenTask(id)
{
	id -= TASK_GIVE_FROZEN;
	
	if(!is_user_connected(id))
		remove_task(id + TASK_GIVE_FROZEN)
	
	if(is_user_alive(id)) 
		GiveUserFrozenGrenade(id)
}

/* Swap money*/
public CmdSwapMoney(id)
 {
	if(!g_ConfigValues[CFG_SWAP_MONEY])
	{
		ColorChat(id, GREEN, "%s^x01 Swapping money for gold is disabled on this server.", CHAT_PREFIX);
		return;
	}
	new iMoney = cs_get_user_money(id)
	
	if(iMoney < g_ConfigValues[CFG_SWAP_MONEY_MONEY]) 
	{
		ColorChat(id, GREEN, "%s^x01 You dont have much money to swap. You must have $%d!", CHAT_PREFIX, g_ConfigValues[CFG_SWAP_MONEY_MONEY])
		g_IsUserNotifiedAboutSwap[id] = 0
		
		return;
	}
	
	if(g_IsUserNotifiedAboutSwap[id]) 
	{
		ColorChat(id, GREEN, "%s^x01 You swapped $%d for %d gold!", CHAT_PREFIX, g_ConfigValues[CFG_SWAP_MONEY_MONEY], g_ConfigValues[CFG_SWAP_MONEY_GOLD])
	
		iMoney -= g_ConfigValues[CFG_SWAP_MONEY_MONEY]
		
		cs_set_user_money(id, iMoney)
		
		g_PlayerInfo[id][PLAYER_GOLD] += g_ConfigValues[CFG_SWAP_MONEY_GOLD]
		
		client_cmd(id, "spk sound/%s", g_SoundFile[SND_COIN]);
		g_IsUserNotifiedAboutSwap[id] = 0;
	}
}

public EventMoney(id)
 {
 	if(!g_ConfigValues[CFG_SWAP_MONEY])
		return
			
	if(is_user_alive(id)) 
	{
		new iMoney = cs_get_user_money(id)
		
		if(iMoney >= g_ConfigValues[CFG_SWAP_MONEY_MONEY] && !g_IsUserNotifiedAboutSwap[id]) 
		{
			g_IsUserNotifiedAboutSwap[id] = 1
			if(g_PlayerSwapMoneyAutobuy[id]) 
			{
				ColorChat(id, GREEN, "%s^x03 Auto swaping - condition executed.", CHAT_PREFIX)
				
				CmdSwapMoney(id)
				return
			}
			ColorChat(id, GREEN, "%s^x01 You have $%d!", CHAT_PREFIX, g_ConfigValues[CFG_SWAP_MONEY_MONEY])
			ColorChat(id, GREEN, "%s^x01 Type '/swap' to swap money for %d gold!", CHAT_PREFIX, g_ConfigValues[CFG_SWAP_MONEY_GOLD])	
		} 
		else if(iMoney < g_ConfigValues[CFG_SWAP_MONEY]) 
			g_IsUserNotifiedAboutSwap[id] = 0

	}
}

/* There is information player want increase or decrease */
new bool:g_IsUserAdding[33];

public CmdPlayerMenu(id) 
{
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE

	new iMenu = menu_create("Tower Defense Mod 0.6 Rebuild^n\yCreated by tomcionek15 & grs4", "CmdPlayerMenuH");
	new iCb = menu_makecallback("CmdPlayerMenuCb");
	
	menu_additem(iMenu, "Turrets", "0", _, iCb);
	menu_additem(iMenu, "Skills", "1", _, iCb);
	menu_additem(iMenu, "Shop", "2", _, iCb)
	if(g_isGunModEnabled)
		menu_additem(iMenu, "Weapons", "3", _, iCb);
	menu_additem(iMenu, "Give gold", "4", _, iCb)
	menu_additem(iMenu, "User settings", "5");
	menu_additem(iMenu, "Admin menu", "6", ADMIN_CVAR);

	menu_display(id, iMenu);

	return PLUGIN_CONTINUE;
}
public CmdPlayerMenuCb(id, menu, item) 
{
	static ac, info[3], nm[3], cb;
	menu_item_getinfo(menu, item, ac, info, 2, nm, 2, cb);

	item = str_to_num(info);
	
	if(!is_user_alive(id) && item != 1 && item != 6)
		return ITEM_DISABLED;
	if(item == 0 && !g_AreTurretsEnabled)
		return ITEM_DISABLED;
	
	return ITEM_ENABLED
}

public CmdPlayerMenuH(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}

	static ac, info[3], nm[3], cb;
	menu_item_getinfo(menu, item, ac, info, 2, nm, 2, cb);

	item = str_to_num(info);
	
	switch(item) 
	{
		case 0: ShowTurretsMenu(id)
		case 1: CmdPlayerSkillMenu(id)
		case 2: ShowShopMenu(id, 1);
		case 3: client_cmd(id, "guns");
		case 4: client_cmd(id, "givegold")
		case 5: ShowPlayerOptionsMenu(id)
		case 6: ShowAdminMenu(id)
	}
	
	return PLUGIN_CONTINUE
}

public ShowAdminMenu(id)
{
	new iMenu = menu_create("", "ShowAdminMenuH")
	new cb = menu_makecallback("ShowAdminMenuCb");
	menu_additem(iMenu, "StartZone settings");
	
	if(g_ConfigValues[CFG_REPAIR_ZONE_AMOUNT])
		menu_additem(iMenu, "RepairZone settings");
	else
		menu_additem(iMenu, "RepairZone [plase define first repair^nzone configuration of this map:^nREPAIR_ZONE_AMOUNT]", _, _, cb);
	
	menu_additem(iMenu, "MapVoteZones settings");
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu);
}

public ShowAdminMenuCb(id, menu, item)
{
	if(item == 1 && !g_ConfigValues[CFG_REPAIR_ZONE_AMOUNT])	
		return ITEM_DISABLED
	return ITEM_ENABLED
}

public ShowAdminMenuH(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu)
		CmdPlayerMenu(id)
		return;
	}
	
	switch(++item) 
	{
		case 1: StartZoneAdminMenu(id)
		case 2: RepairZoneAdminMenu(id)
		case 3: MapVoteZoneAdminMenu(id)
	}
}
public ShowPlayerOptionsMenu(id) 
{	
	static  szFormat[90]

	new iMenu = menu_create("\yUser settings", "ShowPlayerOptionsMenuH");
	new iCb = menu_makecallback("ShowPlayerOptionsMenuCb")
	
	menu_additem(iMenu, "Change HUD options", _, _, iCb);
	menu_additem(iMenu, "Change Healthbar", _, _, iCb);
	menu_additem(iMenu, "Change Turrets settings", _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "Automatic swapping money %s^n\w[\y %d gold\w when you have\y $%d\w ]", g_PlayerSwapMoneyAutobuy[id] ? "\yis ON":"\ris OFF",  g_ConfigValues[CFG_SWAP_MONEY_GOLD], g_ConfigValues[CFG_SWAP_MONEY_MONEY]);	
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu);
}
public ShowPlayerOptionsMenuCb(id, meun, item) 
{
	if(item == 2 && !g_AreTurretsEnabled)
		return ITEM_DISABLED;
		
	if(item == 3 && !g_ConfigValues[CFG_SWAP_MONEY])
		return ITEM_DISABLED
		
	return ITEM_ENABLED
}
public ShowPlayerOptionsMenuH(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		CmdPlayerMenu(id)
		return PLUGIN_CONTINUE
	}
	
	switch(item) 
	{
		case 0: ShowPlayerOptionsHudMenu(id);
		case 1: MenuEditHealthbar(id)
		case 2: ShowTurretsSettingsMenu(id)
		case 3: 
		{
			g_PlayerSwapMoneyAutobuy[id] = !g_PlayerSwapMoneyAutobuy[id]
			
			if(cs_get_user_money(id) > g_ConfigValues[CFG_SWAP_MONEY_MONEY])
				CmdSwapMoney(id)
				
			ColorChat(id, GREEN, "%s^x01 Auto swapping money for gold is now %s.", CHAT_PREFIX,  g_PlayerSwapMoneyAutobuy[id] ? "enabled":"disabled");
			ShowPlayerOptionsMenu(id)
		}
	}
	
	return PLUGIN_CONTINUE
}

public MenuEditHealthbar(id) 
{
	new iMenu = menu_create("\yHealthbars settings:", "MenuEditHealthbarH")
	
	menu_additem(iMenu, "Change healthbar style")
	menu_additem(iMenu, "Change healthbar scale")
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu);
}

public MenuEditHealthbarH(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		ShowPlayerOptionsMenu(id)
		return PLUGIN_CONTINUE
	}
	switch(item) 
	{
		case 0: MenuEditHealthbarStyle(id)
		case 1: MenuEditHealthbarScale(id)
	}
	return PLUGIN_CONTINUE
}

public MenuEditHealthbarScale(id) 
{
	static szFormat[33];
	
	formatex(szFormat, charsmax(szFormat), "%s\w every 0.05", g_IsUserAdding[id]? "\yAdd":"\rSubstract")
	new iMenu = menu_create(szFormat, "MenuEditHealthbarScaleH");
	
	formatex(szFormat, charsmax(szFormat), "Scale: \r%0.2f", g_PlayerHealthbarScale[id]);
	menu_additem(iMenu, szFormat);
	menu_additem(iMenu, g_IsUserAdding[id] ? "\rSubstract":"\yAdd")
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu);
	return PLUGIN_CONTINUE;
}

public MenuEditHealthbarScaleH(id, menu, item) {
	if(item == MENU_EXIT)  
	{
		MenuEditHealthbar(id)
		return PLUGIN_CONTINUE
	}
	
	switch(item) 
	{
		case 0:  
		{
			if(g_IsUserAdding[id])
				g_PlayerHealthbarScale[id] += 0.05
			else
				g_PlayerHealthbarScale[id] -= 0.05
			
			if(g_PlayerHealthbarScale[id] < 0.1)
				g_PlayerHealthbarScale[id] = 0.1
			else if(g_PlayerHealthbarScale[id] > 1.0)
				g_PlayerHealthbarScale[id] = 1.0
		}
		case 1: g_IsUserAdding[id] = !g_IsUserAdding[id]
	}
	
	MenuEditHealthbarScale(id)
	return PLUGIN_CONTINUE
}

public MenuEditHealthbarStyle(id) 
{
	static szFormat[33];
	
	new iMenu = menu_create("Change style:", "MenuEditHealthbarStyleH")
	new iCb = menu_makecallback("MenuEditHealthbarStyleCb");
	
	menu_additem(iMenu, "Don't show healthbar", _, _, iCb);
	
	for(new i; i < 3 ; i++) 
	{
		formatex(szFormat, charsmax(szFormat), "Healthbar no. %d", i+1)
		menu_additem(iMenu, szFormat, _, _, iCb)
	}
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu);
}

public MenuEditHealthbarStyleCb(id, menu, item) 
	return item == g_PlayerHealthbar[id] ? ITEM_DISABLED : ITEM_ENABLED
	
public MenuEditHealthbarStyleH(id, menu, item) {
	if(item == MENU_EXIT) 
	{
		MenuEditHealthbar(id)
		return PLUGIN_CONTINUE
	}
	
	if(item == 0)
		ColorChat(id, GREEN, "%s^x01 Healthbars will not be showed", CHAT_PREFIX);
	else
		ColorChat(id, GREEN, "%s^x01 Healthbar was changed to Healthbar no. %d", CHAT_PREFIX, item );
	
	g_PlayerHealthbar[id] = item;
	MenuEditHealthbarStyle(id)
	
	return PLUGIN_CONTINUE
}

public ShowPlayerOptionsHudMenu(id) 
{
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE
	
	static szFormat[64];
	
	new iMenu = menu_create("HUD Settings:", "ShowPlayerOptionsHudMenuH");
	new iCb = menu_makecallback("ShowPlayerOptionsHudMenuCb");
	
	formatex(szFormat, charsmax(szFormat), "Change position \r[ X: %0.2f \yY: %0.2f \r]", g_PlayerHudPosition[id][0], g_PlayerHudPosition[id][1]);
	menu_additem(iMenu, szFormat, _, _, iCb);
	
	formatex(szFormat, charsmax(szFormat), "Change color [R: %d G: %d B: %d]",  g_PlayerHudColor[id][0], g_PlayerHudColor[id][1], g_PlayerHudColor[id][2]);
	menu_additem(iMenu, szFormat,  _, _, iCb);
	menu_additem(iMenu,  "Change HUD size", _, _, iCb);

	formatex(szFormat, charsmax(szFormat), "Show hit crosshair effect(& sound): \y %s", g_PlayerShowHitCrosshair[id] ? "\yEnabled" : "\rDisabled");
	menu_additem(iMenu, szFormat);
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu);
	return PLUGIN_CONTINUE;
}

public ShowPlayerOptionsHudMenuCb(id, menu, item) 
	return g_PlayerHudSize[id] == HUD_SMALL && (item == 0 || item == 1) ? ITEM_DISABLED : ITEM_ENABLED;

public ShowPlayerOptionsHudMenuH(id, menu, item) {
	if(item == MENU_EXIT) 
	{
		ShowPlayerOptionsMenu(id)
		return PLUGIN_CONTINUE
	}
	
	switch(item) 
	{
		case 0: MenuEditHudPosition(id)
		case 1: MenuEditHudColor(id)
		case 2: MenuEditHudSize(id)
		case 3: 
		{
			g_PlayerShowHitCrosshair[id] = !g_PlayerShowHitCrosshair[id];
			ShowPlayerOptionsHudMenu(id) 
		}
	}
	
	return PLUGIN_CONTINUE
}
public MenuEditHudSize(id) 
{
	static szFormat[33]
	
	formatex(szFormat, charsmax(szFormat), "\yActual size:\w %s", g_PlayerHudSize[id] == HUD_SMALL ? "SMALL" : g_PlayerHudSize[id] == HUD_NORMAL ? "NORMAL" : "BIG");
	
	new iMenu = menu_create(szFormat, "MenuEditHudSizeH")
	new iCb = menu_makecallback("MenuEditHudSizeCb");
	
	menu_additem(iMenu, "Small", _, _, iCb);
	menu_additem(iMenu, "Normal", _, _, iCb);
	menu_additem(iMenu, "Big", _, _, iCb);
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	menu_display(id, iMenu);
}

public MenuEditHudSizeCb(id, menu, item) 
	return ++item == g_PlayerHudSize[id] ? ITEM_DISABLED : ITEM_ENABLED;


public MenuEditHudSizeH(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu)
		ShowPlayerOptionsHudMenu(id)
		return PLUGIN_CONTINUE
	}
	
	g_PlayerHudSize[id] = ++item
	
	if(item != HUD_SMALL) 
	{
		message_begin(MSG_ONE, g_HudStatusText, _, id);
		write_byte(0);
		write_string("");
		message_end();
	}
	
	ColorChat(id, GREEN, "%s^x01 Your hud was changed to %s", CHAT_PREFIX,  g_PlayerHudSize[id] == HUD_SMALL ? "SMALL" : g_PlayerHudSize[id] == HUD_NORMAL ? "NORMAL" : "BIG");
	MenuEditHudSize(id)
	
	return PLUGIN_CONTINUE
}

public MenuEditHudPosition(id) 
{
	static szFormat[33];
	
	formatex(szFormat, charsmax(szFormat), "%s\w every 0.04 :", g_IsUserAdding[id] ? "\yAdd":"\rSubstract");
	
	new iMenu = menu_create(szFormat, "MenuEditHudPositionH")
	
	formatex(szFormat, charsmax(szFormat), "X: %0.2f", g_PlayerHudPosition[id][0]);
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "Y: %0.2f", g_PlayerHudPosition[id][1]);
	menu_additem(iMenu, szFormat);
	
	menu_additem(iMenu, g_IsUserAdding[id] ? "\rSubstract":"\yAdd");
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu);
}

public MenuEditHudPositionH(id, menu, item)
{
	if(item == MENU_EXIT) 
	{
		ShowPlayerOptionsHudMenu(id)
		return PLUGIN_CONTINUE
	}
	
	switch(item) 
	{
		case 0: 
		{
			if(g_IsUserAdding[id]) 
				g_PlayerHudPosition[id][0] += 0.04
			else 
				g_PlayerHudPosition[id][0] -= 0.04
			
			if(g_PlayerHudPosition[id][0] < 0.0)
				g_PlayerHudPosition[id][0] = 0.00
			else if(g_PlayerHudPosition[id][0] > 1.0)
				g_PlayerHudPosition[id][0] = 1.00
		}
		case 1: 
		{
			if(g_IsUserAdding[id])
				g_PlayerHudPosition[id][1] += 0.04
			else
				g_PlayerHudPosition[id][1] -= 0.04
			
			if(g_PlayerHudPosition[id][1] < 0.0)
				g_PlayerHudPosition[id][1] = 0.00
			else if(g_PlayerHudPosition[id][1] > 1.0)
				g_PlayerHudPosition[id][1] = 1.00

		}
		
		case 2: g_IsUserAdding[id] = !g_IsUserAdding[id]
	}
	
	MenuEditHudPosition(id)
	return PLUGIN_CONTINUE
}

public MenuEditHudColor(id) 
{
	static szFormat[33]
	
	formatex(szFormat, charsmax(szFormat), "%s\w every 10:", g_IsUserAdding[id] ? "\yAdd":"\rSubstract");
	
	new iMenu = menu_create(szFormat, "MenuEditHudColorH")
	
	formatex(szFormat, charsmax(szFormat), "Red: %d", g_PlayerHudColor[id][0]);
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "Green: %d", g_PlayerHudColor[id][1]);
	menu_additem(iMenu, szFormat);
	
	formatex(szFormat, charsmax(szFormat), "Blue: %d", g_PlayerHudColor[id][2]);
	menu_additem(iMenu, szFormat);
	
	menu_additem(iMenu,  g_IsUserAdding[id] ? "\rSubstract":"\yAdd");
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu);

}

public MenuEditHudColorH(id, menu, item)
{
	if(item == MENU_EXIT) 
	{
		ShowPlayerOptionsMenu(id)
		return PLUGIN_CONTINUE
	}
	
	switch(item) 
	{
		case 0: 
		{
			if(g_IsUserAdding[id])
				g_PlayerHudColor[id][0] += 10
			else
				g_PlayerHudColor[id][0] -= 10
			
			if(g_PlayerHudColor[id][0] == 260)
				g_PlayerHudColor[id][0] = 255
			else if(g_PlayerHudColor[id][0] == 245)
				g_PlayerHudColor[id][0] = 250
				
			if(g_PlayerHudColor[id][0] < 0)
				g_PlayerHudColor[id][0] = 0
			else if(g_PlayerHudColor[id][0] > 255)
				g_PlayerHudColor[id][0] = 255
		}
		case 1: 
		{
			
			if(g_IsUserAdding[id])
				g_PlayerHudColor[id][1] += 10
			else
				g_PlayerHudColor[id][1] -= 10
			
			if(g_PlayerHudColor[id][1] == 260)
				g_PlayerHudColor[id][1] = 255
			else if(g_PlayerHudColor[id][1] == 245)
				g_PlayerHudColor[id][1] = 250
				
			if(g_PlayerHudColor[id][1] < 0)
				g_PlayerHudColor[id][1] = 0
			else if(g_PlayerHudColor[id][1] > 255)
				g_PlayerHudColor[id][1] = 255
		}
		case 2: 
		{
			if(g_IsUserAdding[id])
				g_PlayerHudColor[id][2] += 10
			else
				g_PlayerHudColor[id][2] -= 10
			
			if(g_PlayerHudColor[id][2] == 260)
				g_PlayerHudColor[id][2] = 255
			else if(g_PlayerHudColor[id][2] == 245)
				g_PlayerHudColor[id][2] = 250
				
			if(g_PlayerHudColor[id][2] < 0)
				g_PlayerHudColor[id][2] = 0
			else if(g_PlayerHudColor[id][2] > 255)
				g_PlayerHudColor[id][2] = 255
		}
		case 3: g_IsUserAdding[id] = !g_IsUserAdding[id]
	}
	
	MenuEditHudColor(id)
	return PLUGIN_CONTINUE
}

public MonsterHitHeadshot(iEnt, idattacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if(!IsMonster(iEnt))
		return HAM_IGNORED;
	
	if(get_tr2(tracehandle, TR_iHitgroup) == HIT_HEAD)
		entity_set_edict(iEnt, EV_ENT_monster_headshot, 1)
	else 
		entity_set_edict(iEnt, EV_ENT_monster_headshot, 0)
	
	return HAM_IGNORED;

}

/* Kill the monster and set a death animation*/
public MonsterKilled(iEnt, id) //zabicie potwora
{
	if(!IsMonster(iEnt))
		return HAM_IGNORED
		
	new iMonsterType = entity_get_int(iEnt, EV_INT_monster_type)
	
	new iRet;
	ExecuteForward(g_ForwardMonsterKilled, iRet, iEnt, id, iMonsterType, entity_get_int(iEnt, EV_INT_monster_track) == -2 ? 1 : 0)
	if(iRet != PLUGIN_CONTINUE)
		return iRet
		
	new iDeadSeq;
	/* If monster was killed by headshot */
	if(entity_get_edict(iEnt, EV_ENT_monster_headshot))
		 iDeadSeq = lookup_sequence(iEnt, "head") 
	else
	{
		switch(random_num(1, 3)) 
		{
			case 1:iDeadSeq = lookup_sequence(iEnt, "death1")
			case 2:iDeadSeq = lookup_sequence(iEnt, "death2")
			case 3:iDeadSeq = lookup_sequence(iEnt, "death3")
		}
		
		if(!iDeadSeq)
			iDeadSeq = lookup_sequence(iEnt, "death1");
	}
	
	
	/* Remove monster healthbar */
	if(is_valid_ent(entity_get_edict(iEnt, EV_ENT_monster_healthbar)))
		remove_entity(entity_get_edict(iEnt, EV_ENT_monster_healthbar))

	new iEarnedGold =  g_ConfigValues[CFG_KILL_GOLD]
	
	if(is_user_connected(id)) 
	{	
		if(iMonsterType == ROUND_BONUS ) 
		{
			if(is_valid_ent( entity_get_edict(iEnt, EV_ENT_owner)) )
				remove_entity( entity_get_edict(iEnt, EV_ENT_owner) );
				
			new szNick[33];
			get_user_name(id, szNick, 32);
			iEarnedGold = g_ConfigValues[CFG_KILL_BONUS_GOLD] + g_BonusRobbedGold;
			
			ColorChat(0, GREEN, "%s^x01 Defender %s killed a BONUS and get %d gold!", CHAT_PREFIX, szNick, iEarnedGold);
			
		} 
		else if(iMonsterType == ROUND_BOSS) 
		{
			new szNick[33];
			get_user_name(id, szNick, 32);
			
			ColorChat(0, GREEN, "%s^x01 Defender %s killed a BOSS!",CHAT_PREFIX, szNick);
			iEarnedGold = g_ConfigValues[CFG_KILL_BOSS_GOLD]
		}
			
		if(g_PlayerInfo[id][PLAYER_EXTRA_GOLD])
			iEarnedGold += g_PlayerInfo[id][PLAYER_EXTRA_GOLD]

		if(IsPremiumMonster(iEnt))
			iEarnedGold = floatround(iEarnedGold * g_ConfigValuesFloat[CFG_FLOAT_PRM_MONSTER_MLTP_GOLD]);
			
		set_hudmessage(255, 255, 255, 0.60, 0.6, 2, 6.0, 1.0, 0.0, 0.4)
		show_hudmessage(id, "+ KILL^n+ %d GOLD^n%s",  iEarnedGold, entity_get_edict(iEnt, EV_ENT_monster_headshot)? "HS":"")
	}
	
	AddPlayerBenefits(id, iEarnedGold, iMonsterType);

	/* Check if this is last monster */
	if(--g_AliveMonstersNum == 0)
		if(g_SentMonstersNum >= (IsSpecialWave(g_ActualWave) ? g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM] + 1 : g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM])) 
			if(g_IsGameStarted ) 
				WaveEnded()

	/* Reset monster information */
	entity_set_int(iEnt, 	EV_INT_monster_type, 0)
	entity_set_int(iEnt, 	EV_INT_monster_track, 0)
	entity_set_int(iEnt, 	EV_INT_monster_maxhealth, 0)
	entity_set_int(iEnt, 	EV_INT_monster_speed, 0)
	entity_set_edict(iEnt, 	EV_ENT_monster_healthbar, 0)
	entity_set_int(iEnt, 	EV_INT_monster_maxspeed, 0)
	
	entity_set_float(iEnt,	EV_FL_nextthink, 0.0);
	entity_set_int(iEnt,	EV_INT_solid, SOLID_NOT)
	
	/* Set death sequence */
	entity_set_int(iEnt, 	EV_INT_sequence, iDeadSeq); 
	entity_set_float(iEnt, 	EV_FL_animtime, get_gametime()+0.1); 
	entity_set_float(iEnt, 	EV_FL_framerate,  0.9); 
	entity_set_float(iEnt, 	EV_FL_frame, 3.0); 	
	entity_set_string(iEnt,	EV_SZ_classname, "monster_dead");
	entity_set_vector(iEnt, 	EV_VEC_velocity, Float:{0.0, 0.0, 0.0})
	
	if(g_ConfigValues[CFG_KILL_MONSTER_FX]) 
	{
		new iOrigin[3]
		new Float:fOrigin[3]
		
		entity_get_vector(iEnt, EV_VEC_origin, fOrigin);
		
		FVecIVec(fOrigin, iOrigin)
		
		iOrigin[2]-=35
		
		msg_implosion(0, iOrigin, 100, 70, 5);
	}
	
	new szData[4];
	szData[0] = id,
	szData[1] = iEnt
	szData[2] = iMonsterType
	
	set_task(0.25, "EmitMonsterDieSounds",_, szData, 3)
	set_task(5.0, "DeleteLieMonster", _, szData, 3);
	return HAM_SUPERCEDE
}	

public EmitMonsterDieSounds(szData[]) 
{
	if(!is_valid_ent(szData[1]))
		return;
	
	if(g_ConfigValues[CFG_KILL_MONSTER_SOUND])
	{
		if(IsSpecialMonster(szData[1]))
			emit_sound(szData[1], CHAN_ITEM, (szData[2] == ROUND_BONUS) ? g_SoundFile[SND_BONUS_DIE] : g_SoundFile[SND_BOSS_DIE], 1.0, ATTN_NORM, 0, PITCH_NORM);
		else
		{	
			switch(random_num(1, 4)) 
			{
				case 1: emit_sound(szData[1], CHAN_ITEM, g_SoundFile[SND_MONSTER_DIE_1], 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 2: emit_sound(szData[1], CHAN_ITEM, g_SoundFile[SND_MONSTER_DIE_2], 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 3: emit_sound(szData[1], CHAN_ITEM, g_SoundFile[SND_MONSTER_DIE_3], 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 4: emit_sound(szData[1], CHAN_ITEM, g_SoundFile[SND_MONSTER_DIE_4], 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
		}
	}
}

/* Completly remove a monster */
public DeleteLieMonster(szData[]) 
	if(is_valid_ent(szData[1]))
		remove_entity(szData[1]);
		
public BlockCommand(id)
	return PLUGIN_HANDLED;
	
public CmdUseLighting(id) 
{
	if(!is_user_alive(id) || g_PlayerInfo[id][PLAYER_LEVEL] < 10)
		return PLUGIN_CONTINUE;
		
	if(g_PlayerLightingTime[id] + 30 > get_gametime()) 
	{
		client_print(id, print_center, "You must wait %d seconds!", floatround(g_PlayerLightingTime[id]+30-get_gametime()))
		return PLUGIN_HANDLED
	}
	
	new Float:fAimedOrigin[3]
	new iOrigin[3]
	
	get_user_origin(id, iOrigin, 3)
	IVecFVec(iOrigin, fAimedOrigin)
	
	new iEntList[1]
	find_sphere_class(-1, "monster", 80.0, iEntList, 1, fAimedOrigin)
	
	if(!is_valid_ent(iEntList[0]) || entity_get_int(iEntList[0], EV_INT_monster_type) == ROUND_NONE) 
	{
		client_print(id, print_center, "You must aim the target!")
		return PLUGIN_HANDLED
	}
	
	g_PlayerLightingTime[id] = get_gametime()
	
	emit_sound(id, CHAN_AUTO, g_SoundFile[SND_PLAYER_USE_LIGHTING], 1.0, ATTN_NORM, 0, PITCH_NORM); 
	ExecuteHamB(Ham_TakeDamage, iEntList[0], id, id, 1000.0, DMG_BLAST)
	
	Create_Lighting(id, iEntList[0], 0, 1, 10, 20, 20, 255, 255, 255, 255, 3)
	return PLUGIN_HANDLED
}

public AddPlayerBenefits(iPlayer, iEarnedGold, iMonsterType) 
{
	if(!is_user_connected(iPlayer)) 
		return PLUGIN_CONTINUE;

	/* Golds for kill */
	g_PlayerInfo[iPlayer][PLAYER_GOLD] += iEarnedGold
		
	/* Frags */
	new iFrags = (iMonsterType == ROUND_BOSS ? g_ConfigValues[CFG_KILL_BOSS_FRAGS] : iMonsterType == ROUND_BONUS ? g_ConfigValues[CFG_KILL_BONUS_FRAGS]: 1 )
	g_PlayerInfo[iPlayer][PLAYER_FRAGS] += iFrags;
	
	fm_set_user_frags(iPlayer, get_user_frags(iPlayer)  + iFrags)

	/* Refreshing frags */
	RefreshPlayerFrags(iPlayer)
	
	CheckPlayerLevel(iPlayer);
	
	/* Money */
	fm_set_user_money(iPlayer, cs_get_user_money(iPlayer) + g_PlayerInfo[iPlayer][PLAYER_EXTRA_MONEY] + g_ConfigValues[CFG_KILL_MONEY] + (g_IsPlayerVip[iPlayer] ? g_ConfigValues[CFG_VIP_EXTRA_KILL_MONEY] : 0))
	
	if(cs_get_user_money(iPlayer) > 16000)
		fm_set_user_money(iPlayer, 16000, 0)

	client_cmd(iPlayer, "spk sound/%s", g_SoundFile[SND_COIN]);

	/* Ammo [if is other than knife] */
	switch(get_user_weapon(iPlayer))
	{
		case CSW_FLASHBANG: {}
		case CSW_HEGRENADE: {}
		case CSW_SMOKEGRENADE: {}
		case CSW_KNIFE: {}
		default:
		{
			GivePlayerAmmo(iPlayer, g_ConfigValues[CFG_KILL_BP_AMMO]) // prawy BP
		}

	}
		
	return PLUGIN_CONTINUE;
}

/* Refreshing Player frags */
public RefreshPlayerFrags(id)
{
	message_begin( MSG_ALL, get_user_msgid("ScoreInfo"), {0,0,0}, 0 );
	write_byte( id );
	write_short(  get_user_frags(id)  );
	write_short(  cs_get_user_deaths(id) );
	write_short( 0 );
	write_short( _:cs_get_user_team(id) );
	message_end();
}

/* Block attacking players */
public BlockAttackingPlayer(Float:v1[3], Float:v2[3], noMonsters, pentToSkip)
{
	if(!is_user_alive(pentToSkip))
		return FMRES_IGNORED
		
	static entity2 ; entity2 = get_tr(TR_pHit)
	
	if(!is_valid_ent(entity2) || IsMonster(entity2))
		return FMRES_IGNORED;
		
	set_tr(TR_flFraction, 1.0)
	return FMRES_SUPERCEDE
}


public ShowDamage(ent, idinflictor, attacker, Float:damage, damagetype)
 {
	if(!(damagetype & DMG_DROWN) && !(damagetype & DMG_BURN)) 
	{
		set_hudmessage(0, 255, 0, 0.55, -1.0, 0, 0.0, 0.1)
		ShowSyncHudMsg(attacker, g_SyncHudDamage, "%d^n%s", floatround(damage), entity_get_edict(ent, EV_ENT_monster_headshot) ? "HS" : "")	

		if(g_PlayerShowHitCrosshair[attacker] == 1)
		{
			set_dhudmessage(255, 255, 255, -1.0, -1.0, 0, 0.0, 0.1);
			show_dhudmessage(attacker, "x");

			if(g_ConfigValues[CFG_HIT_SOUND])
				client_cmd(attacker, "spk sound/%s", g_SoundFile[SND_HIT]);
		}
	}

}

/* This event is sterring an damages */
public TakeDamage(ent, idinflictor, attacker, Float:damage, damagetype)
 {
	if(!is_user_connected(attacker))
		return HAM_IGNORED
	
	if(IsMonster(ent)) 
	{ 
		/* Dodatkowe obrazenia dla broni */
		static bool:isCritical; isCritical = false;
		static bool:isHs; isHs = false;
		
		if(damagetype & DMG_BULLET) 
		{
			if(g_PlayerInfo[attacker][PLAYER_EXTRA_DAMAGE])
				damage += float(g_PlayerInfo[attacker][PLAYER_EXTRA_DAMAGE])
				
			if(g_IsPlayerVip[attacker])
				damage *= g_ConfigValuesFloat[CFG_FLOAT_VIP_EXTRA_DAMAGE_MLTP];

			if(random_num(1, 100) < g_PlayerInfo[attacker][PLAYER_CRITICAl_PERCENT])
				isCritical = true;

			isHs = entity_get_edict(ent, EV_ENT_monster_headshot) == 1;
			
			static iWeapon; iWeapon = get_user_weapon(attacker)
			static szData[3]; 
			szData[0] = floatround(damage); 
			szData[1] = isCritical ? 1 : 0;
			szData[2] = isHs ? 1 : 0;
			
			new iRet;
			ExecuteForward(g_ForwardTakeDamage, iRet, attacker, ent, iWeapon, damage, PrepareArray(szData, 3, 1))

			damage = float(szData[0]) 

			isCritical = szData[1] == 1;
			isHs = szData[2] == 1;
			
			if(isCritical)
				damage *= 2.5;
			if(isHs)
			{
			 	entity_set_edict(ent, EV_ENT_monster_headshot, 1)
				damage *= g_ConfigValuesFloat[CFG_FLOAT_HEADSHOT_MULTIPLIER];
			}
				
			if(floatround(entity_get_float(ent, EV_FL_health)-damage) <= 0)
			{
				entity_set_int(ent, EV_INT_monster_track, -2);
				makeDeathMsg(attacker, isHs, 0)
			}

			ExecuteForward(g_ForwardTakeDamagePost, iRet, attacker, ent, iWeapon, damage, PrepareArray(szData, 3, 0))
		}
		else if(damagetype & DMG_BURN)
		{
			if(floatround(entity_get_float(ent, EV_FL_health)-damage) <= 0)
			{
				entity_set_int(ent, EV_INT_monster_track, -2);
				makeDeathMsg(attacker, 0, 1)
			}
		}
		
		/* Update healthbar frame */
		if(is_valid_ent(entity_get_edict(ent, EV_ENT_monster_healthbar)))
			entity_set_float( entity_get_edict(ent, EV_ENT_monster_healthbar) , EV_FL_frame , 0.0 + ( (entity_get_float(ent, EV_FL_health)-floatround(damage)) * 100.0 ) / entity_get_int(ent, EV_INT_monster_maxhealth));
		
		if(!(damagetype & DMG_BLAST) && !(damagetype & DMG_DROWN) && !(damagetype & DMG_BURN)) 
		{
			/* Display left HP */
			if(g_ConfigValues[CFG_SHOW_LEFT_DAMAGE]) 
			{
				if(floatround(entity_get_float(ent, EV_FL_health)-damage) < 0)
					client_print(attacker, print_center, "KILL %s", isCritical?"CRITIC":"");
				else
					client_print(attacker, print_center, "HP: %d %s", floatround(entity_get_float(ent, EV_FL_health)-damage), isCritical?"| CRITIC":"");
			}
			
			if(g_ConfigValues[CFG_DAMAGE_GOLD] || g_ConfigValues[CFG_DAMAGE_MONEY])
			{
				g_PlayerHittedDamage[attacker] += floatround(damage)

				if(g_PlayerHittedDamage[attacker] >= g_ConfigValues[CFG_DAMAGE_RATIO]) 
				{
					g_PlayerHittedDamage[attacker] = 0

					cs_set_user_money(attacker, (cs_get_user_money(attacker)+g_ConfigValues[CFG_DAMAGE_MONEY]) > 16000 ? 16000 : (cs_get_user_money(attacker)+g_ConfigValues[CFG_DAMAGE_MONEY]))
					
					if(g_ConfigValues[CFG_DAMAGE_GOLD])
					{
						g_PlayerInfo[attacker][PLAYER_GOLD]+= g_ConfigValues[CFG_DAMAGE_GOLD]
						client_cmd(attacker, "spk sound/%s", g_SoundFile[SND_COIN]);
					}
				}
			}
		}
		set_task(0.1, "ShowBloodEffect", ent + TASK_DAMAGE_EFFECT)
	}
	
	SetHamParamFloat(4, damage)
	
	return HAM_IGNORED
}

public SetPlayerSpeed(id) 
{
	if(!is_user_alive(id))
		return HAM_IGNORED
	
	if(g_CanPlayerWalk)
		fm_set_user_maxspeed(id, (250.0 + g_PlayerInfo[id][PLAYER_EXTRA_SPEED]))
		
	return HAM_IGNORED
}

/* Shows effect and emits sound */
public ShowBloodEffect(iEnt) 
{
	iEnt -= TASK_DAMAGE_EFFECT

	if(is_valid_ent(iEnt)) 
	{
		if(g_ConfigValues[CFG_HIT_MONSTER_SOUND])
		{
			switch(random_num(1, 32)) 
			{
				case 1, 2: emit_sound(iEnt, CHAN_ITEM, g_SoundFile[SND_MONSTER_HIT_1], 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 3, 4: emit_sound(iEnt, CHAN_ITEM, g_SoundFile[SND_MONSTER_HIT_2], 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 5, 6: emit_sound(iEnt, CHAN_ITEM, g_SoundFile[SND_MONSTER_HIT_3], 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 7, 8: emit_sound(iEnt, CHAN_ITEM, g_SoundFile[SND_MONSTER_HIT_4], 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 9..32: { /* nothing */ }
			}
		}
		
		if(g_ConfigValues[CFG_HIT_MONSTER_BLOOD_FX])
		{
			if(random_num(1, g_ConfigValues[CFG_HIT_MONSTER_BLOOD_CHANCE]) == 1)
			{
	
				static iOrigin[3]
				static Float:fOrigin[3]
				entity_get_vector(iEnt, EV_VEC_origin, fOrigin)
				
				FVecIVec(fOrigin, iOrigin)
				
				iOrigin[0] += random_num(-10, 10)
				iOrigin[1] += random_num(-10, 10)
				iOrigin[2] += random_num(-10, 30)
				
				fx_blood(iOrigin, 15) // krew	
			}
		}
					
	}
	remove_task(iEnt + TASK_DAMAGE_EFFECT)
}


public test(id)
	SendMonster(ROUND_BOSS, 36000, 150);

public client_putinserver(id)
{
	ResetPlayerInformation(id)
	CheckPlayerData(id)
	
	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Client with id=%d put in server.", id)
}

public CheckPlayerData(id) 
{
	LoadUserConfig(id)	
		
	if(!g_ConfigValues[CFG_VIP])
		return;
	
	if(get_user_flags(id) & read_flags(g_szVipFlag))
	{
		g_IsPlayerVip[id] = true

		g_PlayerInfo[id][PLAYER_EXTRA_GOLD] 	+= g_ConfigValues[CFG_VIP_EXTRA_KILL_GOLD]
		g_PlayerInfo[id][PLAYER_EXTRA_MONEY] 	+= g_ConfigValues[CFG_VIP_EXTRA_KILL_MONEY]
		g_PlayerInfo[id][PLAYER_EXTRA_SPEED] 	+= g_ConfigValues[CFG_VIP_EXTRA_SPEED]

		g_PlayerInfo[id][PLAYER_CRITICAl_PERCENT] += 3;
	}
}


public client_disconnected(id) 
{
	static bool:wasSoundLastManStandingPlayed;
	
	switch(GetAlivePlayers())
	{
		case 0: 
		{
			ResetGame();
			wasSoundLastManStandingPlayed = false;
		}
		case 1:
		{
			if(wasSoundLastManStandingPlayed == false)
			{	
				for(new i = 1 ; i <= g_MaxPlayers ; i++)
				{
					if(is_user_alive(i))
					{
						client_cmd(i, "spk sound/%s", g_SoundFile[SND_LAST_MAN]);
						wasSoundLastManStandingPlayed = true;

						break;
					}
				}
			}
		}
		default:
		{
			wasSoundLastManStandingPlayed = false
		}
	}
	
	ResetPlayerInformation(id)

	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Client with id=%d has just disconnected.", id)
}
public ResetPlayerInformation(id)
{
	/*//new iRet;
	ExecuteForward(gForward[FORWARD_RESET_PLAYER_INFO], iRet, id)
			
	if(iRet)
			return iRet;
	*/
	//isJoined[id] = 0;
	
	//giPlayerClass[id] = 0
	//giPlayerChangedClass[id] = 0
	g_PlayerAfkWarns[id]		= 0;
	g_PlayerHudPosition[id] 	= Float:{0.1, 0.0}
	g_PlayerHudColor[id] 		= {0, 255, 255}
	g_PlayerHealthbarScale[id] 	= 0.3
	g_PlayerWavesPlayed[id] = 0;
	g_PlayerLightingTime[id] = 0.0
	
	g_PlayerHudSize[id] 		= HUD_BIG
	g_PlayerHealthbar[id] 		= 1
	g_IsUserNotifiedAboutSwap[id]  	= 0
	g_PlayerSwapMoneyAutobuy[id] 	= 0
	g_PlayerHittedDamage[id] 	= 0
	g_IsPlayerInStartZone[id]	= false;
	g_VotePlayerForNextMap[id] 	= 0;
	g_IsPlayerVip[id]		= false;
	g_PlayerShowHitCrosshair[id]	= 1;
	
	for(new i = 0; i < _:ENUM_PLAYER ; i++)
		g_PlayerInfo[id][ENUM_PLAYER:i] = 0
		
	g_PlayerInfo[id][PLAYER_LEVEL]	= 1;
	
	for(new i = 1; i <= g_ShopItemsNum; i++) 
		g_ShopPlayerBuy[id][i] = 0;

	g_PlayerInfo[id][PLAYER_CRITICAl_PERCENT] = 3;
	
	remove_task(id + TASK_GIVE_NAPALM);
	remove_task(id + TASK_GIVE_FROZEN);
		
}

public DisplayHud(iTask) 
{	
	static maxTowerHealth

	if(!maxTowerHealth) maxTowerHealth = g_ConfigValues[CFG_TOWER_HEALTH]

	for(new id = 1 ; id <= g_MaxPlayers ; id++)
	{
		if(is_user_alive(id)) 
		{	
			new RoundType = g_InfoAboutWave[g_ActualWave][WAVE_ROUND_TYPE], str[32]
			
			formatex(str, charsmax(str), "%s", (RoundType==ROUND_NONE?"GAME NOT STARTED":RoundType==ROUND_NORMAL?"NORMAL":RoundType==ROUND_FAST?"FAST":RoundType==ROUND_STRENGTH?"STRENGTH":RoundType==ROUND_BONUS?"BONUS":RoundType==ROUND_BOSS?"BOSS":"NONE"))
			
			if(g_PlayerHudSize[id] == HUD_BIG) 
			{
				set_dhudmessage(g_PlayerHudColor[id][0], g_PlayerHudColor[id][1], g_PlayerHudColor[id][2], g_PlayerHudPosition[id][0], g_PlayerHudPosition[id][1], 0, 6.0, 2.02, 0.0, 0.1)
				show_dhudmessage(id, "[WAVE: %d / %d | %s] [GOLD: %d]^n[MONSTERS: %d (%d) / %d] [TOWER: %d / %d]^n[LEVEL: %d] [FRAGS: %d / %d]",
				g_ActualWave, g_WavesNum, str,  g_PlayerInfo[id][PLAYER_GOLD],  g_AliveMonstersNum, g_SentMonstersNum, (IsSpecialWave(g_ActualWave) ? g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM] +1:g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM]),
				g_TowerHealth, maxTowerHealth, g_PlayerInfo[id][PLAYER_LEVEL], g_PlayerInfo[id][PLAYER_FRAGS], (g_PlayerInfo[id][PLAYER_LEVEL]==MAX_LEVEL?  g_PlayerInfo[id][PLAYER_FRAGS] :  g_LevelFrags[g_PlayerInfo[id][PLAYER_LEVEL]]))
			} 
			else if(g_PlayerHudSize[id] == HUD_NORMAL) 
			{
				set_hudmessage(g_PlayerHudColor[id][0], g_PlayerHudColor[id][1], g_PlayerHudColor[id][2], g_PlayerHudPosition[id][0], g_PlayerHudPosition[id][1], 0, 6.0, 2.02, 0.0, 0.1)
				ShowSyncHudMsg(id, g_SyncHudInfo, "[WAVE: %d / %d | %s] [GOLD: %d]^n[MONSTERS: %d (%d) / %d] [TOWER: %d / %d]^n[LEVEL: %d] [FRAGS: %d / %d]",
				g_ActualWave, g_WavesNum, str,  g_PlayerInfo[id][PLAYER_GOLD],  g_AliveMonstersNum, g_SentMonstersNum, (IsSpecialWave(g_ActualWave) ? g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM] +1:g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM]),
				g_TowerHealth, maxTowerHealth, g_PlayerInfo[id][PLAYER_LEVEL], g_PlayerInfo[id][PLAYER_FRAGS],( g_PlayerInfo[id][PLAYER_LEVEL]==MAX_LEVEL ?  g_PlayerInfo[id][PLAYER_FRAGS]: g_LevelFrags[g_PlayerInfo[id][PLAYER_LEVEL]]))
			} 
			else if(g_PlayerHudSize[id] == HUD_SMALL) 
			{
				static szText[128]	
				formatex(szText, charsmax(szText),  "Wave: %d|Monsters: %d|Gold: %d|Lvl: %d|Frags: %d/%d", g_ActualWave,  g_AliveMonstersNum, g_PlayerInfo[id][PLAYER_GOLD], g_PlayerInfo[id][PLAYER_LEVEL], g_PlayerInfo[id][PLAYER_FRAGS],( g_PlayerInfo[id][PLAYER_LEVEL]==MAX_LEVEL?  g_PlayerInfo[id][PLAYER_FRAGS]: g_LevelFrags[g_PlayerInfo[id][PLAYER_LEVEL]]))
				
				message_begin(MSG_ONE, g_HudStatusText, _, id);
				write_byte(0);
				write_string(szText);
				message_end();
			}
		}
		else
		{
			set_hudmessage(255, 0, 0, -1.0, 0.75, 1, 1.0, 2.02, 0.2, 0.2, -1)
			show_hudmessage(id, "Play now by choosing team%s!^n%s created by %s", g_ConfigValues[CFG_RESPAWN_CMD] ? " or /respawn command" : "", PLUGIN, AUTHOR);
		}
	}
	
}

/* /respawn command */
public CmdRespawnPlayer(id) 
{
	if(g_ConfigValues[CFG_RESPAWN_CMD] == 0) 
	{
		ColorChat(id, GREEN, "%s^x03 This command is disabled on this server.", CHAT_PREFIX);
		return PLUGIN_HANDLED;
	}
	else if(is_user_alive(id)) 
	{
		ColorChat(id, GREEN, "%s^x01 You are alive.", CHAT_PREFIX);
		return PLUGIN_HANDLED;
	}
	else 
	{
		if(g_ConfigValues[CFG_AUTO_RESPAWN] == 0)
			set_task(0.1, "CmdRespawnPlayerPost", id + TASK_RESPAWN);
		else
		{
			new iCT;
			new iTT;

			for(new i = 1 ; i <= g_MaxPlayers ; i++)
			{
				if(is_user_alive(i))
				{
					switch( get_user_team(i) )
					{
						case 1: iTT++;
						case 2: iCT++;
					}
				}
			}

			engclient_cmd(id, "jointeam 5; joinclass 5");

			if(iTT == iCT || iTT > iCT)
				cs_set_user_team(id, CS_TEAM_CT, CS_DONTCHANGE);
			else
				cs_set_user_team(id, CS_TEAM_T, CS_DONTCHANGE);
			
			ColorChat(id, GREEN, "%s^x01 Wait a few seconds for respawn...", CHAT_PREFIX);
		}
		return PLUGIN_HANDLED;
	}	
}

public CmdRespawnPlayerPost(id)
{
	id -= TASK_RESPAWN;

	new szName[33];
	get_user_name(id, szName, 32);
	
	ColorChat(id, GREEN, "%s^x01 Welcome %s on %s server. Please say^x04 /menu^x01 to open game menu", CHAT_PREFIX, szName, PLUGIN);

	if(is_user_alive(id))
		return;

	remove_task(id + TASK_RESPAWN);
	
	ColorChat(0, GREEN, "%s^x01 Defender^x04 %s^x01 has just respawned.", CHAT_PREFIX, szName);	
	ExecuteHamB(Ham_CS_RoundRespawn, id)
	set_task(0.1, "RepeatRespawn", id + 51233);
	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Client %s has just respawned.", szName)
}


public RepeatRespawn(id)
	ExecuteHamB(Ham_CS_RoundRespawn, id - 51233)

public GiveUserSurviveWaveBonus(id)
{
	/* Speak coin sound */
	client_cmd(id, "spk sound/%s", g_SoundFile[SND_COIN]);
	
	/* Give user extra gold */
	g_PlayerInfo[id][PLAYER_GOLD] += g_ConfigValues[CFG_WAVE_EXTRA_GOLD];
	
	/* Give user extra money */
	fm_set_user_money(id, cs_get_user_money(id) + g_ConfigValues[CFG_WAVE_EXTRA_MONEY]);
	
	if(cs_get_user_money(id) > 16000)
		fm_set_user_money(id, 16000, 0)
	
	new iGold = g_ConfigValues[CFG_WAVE_EXTRA_GOLD]
	new iMoney = g_ConfigValues[CFG_WAVE_EXTRA_MONEY];
	
	if(g_IsPlayerVip[id])
	{
		iGold += g_ConfigValues[CFG_VIP_SURV_WAVE_GOLD]
		iMoney += g_ConfigValues[CFG_VIP_SURV_WAVE_MONEY]
	}
	
	ColorChat(id, GREEN, "%s^x01 You got %d gold and $%d for survive %d wave.", CHAT_PREFIX,iGold , iMoney, g_ActualWave - 1)
}

public WaveEnded()
{
	if(g_ConfigValues[CFG_DATA_SAVE_MODE] != 0)
	{
		new iFile = nvault_open(NVAULT_FILE_NAME);
		for(new i = 1 ; i <= g_MaxPlayers ; i++)
		{
			if(is_user_alive(i) && g_PlayerInfo[i][PLAYER_FRAGS] > 0) 
			{
				ColorChat(i, GREEN, "%s^x01 Your^x03 data^x01 has been saved.", CHAT_PREFIX)
				SaveUserConfig(i, iFile);
			}
		}
		nvault_close(iFile);
	}
	new iRet;
	ExecuteForward(g_ForwardWaveEnded, iRet, g_ActualWave);
	
	if(iRet != PLUGIN_CONTINUE)
		return iRet;

	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Wave %d has just ended.", g_ActualWave)
		
	if(g_FogColor[0] == 0 && g_FogColor[1] == 0 && g_FogColor[2] == 0)
		CreateFog(0, .clear = true);
	
	g_AliveMonstersNum = 0;
	g_SentMonstersNum = 0;
	
	client_cmd(0, "spk sound/%s", g_SoundFile[SND_CLEAR_WAVE]);
	
	set_task(5.0, "StartNextWave", TASK_START_WAVE)
	
	return PLUGIN_CONTINUE
}

public StartNextWave(task)
 {
	if(!g_IsGamePossible)
	{
		ColorChat(0, GREEN, "~ Something wrong was happened | g_IsGamePossible = false");
		return PLUGIN_CONTINUE
	}
	
	if(g_IsGameEnded != PLAYERS_PLAYING)
		return PLUGIN_CONTINUE
		
	RemoveAllMonsters()
	
	g_ActualWave ++;
	
	/* Check if it is not end */
	if(g_ActualWave > g_WavesNum) 
	{
		EndGame(PLAYERS_WIN);
		return PLUGIN_CONTINUE
	}
	
	/* Give gold & money if is not first round and show next wave info*/
	for(new i = 1 ; i <= g_MaxPlayers ; i ++) 
	{
		if(is_user_alive(i) && g_ActualWave != 1) 
			GiveUserSurviveWaveBonus(i)
		
		if(is_user_connected(i))
			DisplayWaveInfo(i, g_ActualWave)
	}
	
	if(g_InfoAboutWave[g_ActualWave][WAVE_ROUND_TYPE] == ROUND_BOSS)
	{
		if(g_FogColorBoss[0] == 0 && g_FogColorBoss[1] == 0 && g_FogColorBoss[2] == 0) {
			//todo what/
		}
		else
			CreateFog( 0, g_FogColorBoss[0], g_FogColorBoss[1], g_FogColorBoss[2]);
	}
	else if(g_InfoAboutWave[g_ActualWave][WAVE_ROUND_TYPE] == ROUND_BONUS)
	{
		if(g_FogColorBonus[0] == 0 && g_FogColorBonus[1] == 0 && g_FogColorBonus[2] == 0) {
			//todo what/
		}
		else
			CreateFog( 0, g_FogColorBonus[0], g_FogColorBonus[1], g_FogColorBonus[2]);
	}
	else
	{
		if(g_FogColor[0] == 0 && g_FogColor[1] == 0 && g_FogColor[2] == 0) {
			//todo what/
		}
		else
			CreateFog( 0, g_FogColor[0], g_FogColor[1], g_FogColor[2]);
	}
	
	ColorChat(0, GREEN, "%s^x01 Wave %d is coming...", CHAT_PREFIX, g_ActualWave);

	new szData[2];
	szData[0] = g_ConfigValues[CFG_TIME_TO_WAVE]
	StartCountdown(szData[0], TASK_COUNTDOWN);
	
	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Countdown to wave %d started.", g_ActualWave)
		
	return PLUGIN_CONTINUE
}

public EndGame(end) 
{
	if(g_ConfigValues[CFG_DATA_SAVE_MODE] != 0)
	{
		new iFile = nvault_open(NVAULT_FILE_NAME);

		new bool:iWinResult = end == PLAYERS_WIN, iReward;

		if(iWinResult)
			iReward = g_ConfigValues[CFG_WIN_GAME_GOLD_PRIZE];
		else
			iReward = g_ConfigValues[CFG_LOSE_GAME_GOLD_PRIZE];
			
		for(new i = 1 ; i <= g_MaxPlayers ; i++)
		{
			if(!is_user_connected(i))
				continue;
				
			if(g_PlayerWavesPlayed[i] >= _td_get_max_wave()/6)
			{
				if(iReward)
				{
					ColorChat(i, GREEN, "%s^x01 You got^x03 %d^x01 gold for^x03 %s^x01 the game.", CHAT_PREFIX, iReward, iWinResult ? "won" : "lost");
					g_PlayerInfo[i][PLAYER_GOLD] += iReward;
				}
			}

			if(g_PlayerInfo[i][PLAYER_FRAGS] > 0) 
			{
				g_PlayerGamePlayedNumber[i] ++;
				ColorChat(i, GREEN, "%s^x01 Your^x03 data^x01 has been saved.", CHAT_PREFIX)
				SaveUserConfig(i, iFile);
			}
		}
		nvault_close(iFile);
	}

	new iRet;
	ExecuteForward(g_ForwardGameEnded, iRet, end);
	
	if(iRet != PLUGIN_CONTINUE)
		return iRet;

	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Game has just ended with endtype: %d.", end)
		
	for(new i = 1 ; i <= g_MaxPlayers ; i++)
	{
		remove_task(i + TASK_GIVE_NAPALM);
		remove_task(i + TASK_GIVE_FROZEN);
	}
		
	/* If game was ended remove player huds */
	remove_task(TASK_PLAYER_HUD);
	
	/* Do not send any monsters more */
	remove_task(TASK_SEND_MONSTERS)
	remove_task(TASK_COUNTDOWN);
	
	g_IsGameEnded = end;
	
	if(is_valid_ent(g_StartZoneEntity))
	{
		remove_entity(entity_get_int(g_StartZoneEntity, EV_INT_startzone_entity));
		remove_entity(g_StartZoneEntity);
		
		g_StartZoneEntity = 0;
	}
	
	if(is_valid_ent(g_RepairZoneEntity))
	{
		remove_entity(entity_get_int(g_RepairZoneEntity, EV_INT_repairzone_entity));
		remove_entity(g_RepairZoneEntity);	
		
		g_RepairZoneEntity = 0;
	}

	if(g_IsTowerModelOnMap)
	{
		new iTower;

		if((iTower = find_ent_by_class(-1, "tower")))
			remove_entity(iTower);
	}
	
	/* Set all monsters to stand-by */
	new iMonster = find_ent_by_class(-1, "monster");
	while(is_valid_ent(iMonster))
	{
		if(is_valid_ent(entity_get_edict(iMonster, EV_ENT_monster_healthbar)))
			remove_entity( entity_get_edict(iMonster, EV_ENT_monster_healthbar) );
		
		/* Reset monster information */
		entity_set_int(iMonster, 	EV_INT_monster_type, 0)
		entity_set_int(iMonster, 	EV_INT_monster_track, 0)
		entity_set_int(iMonster, 	EV_INT_monster_maxhealth, 0)
		entity_set_int(iMonster, 	EV_INT_monster_speed, 0)
		entity_set_edict(iMonster, 	EV_ENT_monster_healthbar, 0)
		entity_set_int(iMonster, 	EV_INT_monster_maxspeed, 0)
		entity_set_float(iMonster,	EV_FL_health, 0.0);
		
		entity_set_float(iMonster,	EV_FL_nextthink, 0.0);
		entity_set_int(iMonster,	EV_INT_solid, SOLID_NOT)
		entity_set_string(iMonster,	EV_SZ_classname, "monster_dead");
		
		/* Set stay sequence */
		entity_set_int(iMonster, 	EV_INT_sequence, 1); 	
	
		entity_set_vector(iMonster, 	EV_VEC_velocity, Float:{0.0, 0.0, 0.0})
	
		iMonster = find_ent_by_class(iMonster, "monster");
	}
	
	new iRanger = find_ent_by_class(-1, "ranger_bonus");
	if(is_valid_ent(iRanger))
		remove_entity(iRanger);
		
	if(end == PLAYERS_WIN)
	{
		set_hudmessage(0, 255, 0, 0.06, 0.70, 1, 1.0, 10.0, 0.2, 0.2, -1)
		ShowSyncHudMsg(0, g_SyncHudRepair, "Defeneders win!^nPrepare to vote in 5 seconds...");
		
		client_cmd(0, "spk %s", g_SoundFile[SND_DEFENDERS_WIN])

		/*for(new i = 1; i < g_MaxPlayers; i++)
		{
			if(!is_user_connected(i) || !is_user_alive(i))
			{
			}
		} todo */
	}
	else 
	{
		set_hudmessage(255, 0, 0, 0.06, 0.70, 1, 1.0, 10.0, 0.2, 0.2, -1)
		ShowSyncHudMsg(0, g_SyncHudRepair, "Defenders lose!^nPrepare to vote in 5 seconds...");
		
		client_cmd(0, "spk %s", g_SoundFile[SND_DEFENDERS_LOSE])
	}
	
	set_task(5.0, "PrepareToVote");
	
	return PLUGIN_CONTINUE;
}
public PrepareToVote()
{
	new params[3];
	params[0] = 10

	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Preparing to vote.")
		
	CountdownVoteForNextMap(params, TASK_COUNTDOWN_VOTE);
}

public EmitTimeToChooseSound()
	client_cmd(0, "spk Gman/Gman_Choose%d", random_num(1, 2));
	
public CountdownVoteForNextMap(params[], task)
{
	if(params[0] == 0)
	{
		EmitTimeToChooseSound();

		set_task(1.5, "StartVoteForNextMap");
		return;
	}
	else
	{
		set_hudmessage(255, 255, 0, 0.06, 0.70, 1, 1.0, 1.1, 0.2, 0.2, -1)
		ShowSyncHudMsg(0, g_SyncHudRepair, "Get ready to vote map in %d %s", params[0], params[0] == 1 ? "second" : "seconds");
		
		if(params[0] == 8)
			client_cmd(0, "spk ^"get red(e80) ninety(s45) to check(e20) use bay(s18) mass(e42) cap(s50)^"");
		else if(params[0] <= 6)
		{
			new word[6];
			num_to_word(params[0], word, 5);
		
			client_cmd(0, "spk ^"fvox/%s^"", word);
		}
		
		if(params[0] == 1)
		{
			params[0] --;
			set_task(2.0, "CountdownVoteForNextMap", TASK_COUNTDOWN_VOTE, params, 2);
			return;
		}
	}
	
	params[0] --;
	set_task(1.0, "CountdownVoteForNextMap", TASK_COUNTDOWN_VOTE, params, 2);
}

new g_VoteTime;
public StartVoteForNextMap()
{	
	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Starting for vote to next map.")
		
	LoadMaps();  
	CreateVoteMapEntities()
	
	g_VoteTime  = g_ConfigValues[CFG_VOTE_MAP_TIME];
	ShowMenuWithMapNames()
}
public LoadMaps()
{
	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Loading maps to vote.")
		
	if(file_exists(MAP_CONFIG_FILE) )
	{
		new Array:aMapNames = ArrayCreate(64, 5);
		new line[64], len;

		for(new i ; read_file( MAP_CONFIG_FILE, i, line, 64, len) ; i++)
		{
			trim(line);
			remove_quotes(line);
			
			if(line[0] == ';' || !line[0])
				continue
				

			if(DEBUG)	
				log_to_file(LOG_FILE, "DEBUG: Loaded map to vote: %s.", line)
				
			ArrayPushString(aMapNames, line);
		}
		
		new tempMapName[64], bool:wasPlayed = false, actualMapName[64];
		get_mapname(actualMapName, 63)
		new bool:reset = false;
		
		while(g_VotedForNextMapNum < VOTE_MAP_COUNT-1)
		{
			ArrayGetString(aMapNames, random_num(0, ArraySize(aMapNames)-1), tempMapName, 63)
			
			for(new i ; i < LAST_MAPS_SAVE; i++)
			{
				if(equali(tempMapName, g_LastMapName[i]))
				{
					wasPlayed = true;
					break;
				}
			}
			for(new i ; i < g_LastMapsNum ; i++)
			{
				if(equali(g_VoteForNextMapNames[i], tempMapName))
				{
					reset = true;
					break;
				}
			}	
			if(reset || wasPlayed || equali(tempMapName, actualMapName))
			{
				wasPlayed = false;
				reset = false;
				continue;
			}
			copy(g_VoteForNextMapNames[g_VotedForNextMapNum++], 63, tempMapName);	
		}
		
		if(g_ConfigValues[CFG_VOTE_ALLOW_RESTART])
			g_VoteForNextMapNames[g_VotedForNextMapNum++] = "Restart map"; //add restarting map
		else
		{	
			while(g_VotedForNextMapNum < VOTE_MAP_COUNT)
			{
				ArrayGetString(aMapNames, random_num(0, ArraySize(aMapNames)-1), tempMapName, 63)
				
				for(new i ; i < LAST_MAPS_SAVE; i++)
				{
					if(equali(tempMapName, g_LastMapName[i]))
					{
						wasPlayed = true;
						break;
					}
				}
				for(new i ; i < g_LastMapsNum ; i++)
				{
					if(equali(g_VoteForNextMapNames[i], tempMapName))
					{
						reset = true;
						break;
					}
				}	
				if(reset || wasPlayed || equali(tempMapName, actualMapName))
				{
					wasPlayed = false;
					reset = false;
					continue;
				}
				copy(g_VoteForNextMapNames[g_VotedForNextMapNum++], 63, tempMapName);	
			}
		}
		
		ArrayDestroy(aMapNames);
	}
}

public ShowMenuWithMapNames()
{
	new menu = menu_create("\yMap in votes:", "ShowMenuMapWithNamesCb");
	new iAllVotes;
	new iRestartEnabled = g_ConfigValues[CFG_VOTE_ALLOW_RESTART]
	
	if(g_VoteTime == 0)
	{
		if(DEBUG)	
			log_to_file(LOG_FILE, "DEBUG: Voting ended.")
		
		new result[3]
		GetMapIndexWithMostVotes(result[0], result[1]);
				
		set_hudmessage(0, 255, 255, 0.06, 0.70, 1, 1.0, 4.5, 0.2, 0.2, -1)
		ShowSyncHudMsg(0, g_SyncHudInfo, "Calculating results...");
			
		RemoveVoteMapEntitiesAndResetUsers();
		set_task(5.0, "CheckVoteResults", _, result, 2);
	}
	else
	{
		
		static szFormat[172]
		
		for(new i = 0 ; i < g_VotedForNextMapNum ; i++)
		{
			new iVoteNum = GetPlayersNumInVoteZone(i+1);
			iAllVotes += iVoteNum;
	
			if(i+1 == g_VotedForNextMapNum)
			{
				new iPlayerNoVoted = GetAlivePlayers()-iAllVotes;
				
				if(iPlayerNoVoted)
					if(i == VOTE_MAP_COUNT-1 && iRestartEnabled)
						formatex(szFormat, charsmax(szFormat), "Restart map | %d %s^n^n\r%d %s\w didn't voted yet",   iVoteNum, iVoteNum == 1 ? "vote" : "votes", iPlayerNoVoted, iPlayerNoVoted == 1 ? "player" : "players");
					else
						formatex(szFormat, charsmax(szFormat), "MAP \y%d\w:\r %s\w | %d %s^n^n\r%d %s\w didn't voted yet", i+1, g_VoteForNextMapNames[i], iVoteNum, iVoteNum == 1 ? "vote" : "votes", iPlayerNoVoted, iPlayerNoVoted == 1 ? "player" : "players");
				else
					if(i == VOTE_MAP_COUNT-1 && iRestartEnabled)
						formatex(szFormat, charsmax(szFormat), "Restart map | %d %s^n^n\yAll players have voted",  iVoteNum, iVoteNum == 1 ? "vote" : "votes");
					else
						formatex(szFormat, charsmax(szFormat), "MAP \y%d\w:\r %s\w | %d %s^n^n\yAll players have voted", i+1, g_VoteForNextMapNames[i], iVoteNum, iVoteNum == 1 ? "vote" : "votes");
				
				format(szFormat, charsmax(szFormat), "%s^n^nEnding vote in: \r%d %s", szFormat, g_VoteTime, g_VoteTime == 1 ? "second" : "seconds")
			}
			else
				if(i == VOTE_MAP_COUNT-1 && iRestartEnabled)
					formatex(szFormat, charsmax(szFormat), "Restart map | %d %s",  iVoteNum, iVoteNum == 1 ? "vote" : "votes");
				else
					formatex(szFormat, charsmax(szFormat), "MAP \y%d\w:\r %s\w | %d %s", i+1, g_VoteForNextMapNames[i], iVoteNum, iVoteNum == 1 ? "vote" : "votes");
				
			menu_additem(menu, szFormat);
		}
	}
	for(new i = 1 ; i <= g_MaxPlayers; i ++)
		if(is_user_connected(i))
			if(g_VoteTime == 0)
				show_menu(i, 0, "^n", 1);
			else
				menu_display(i, menu);
			
	g_VoteTime--;
	
	if(g_VoteTime == -1)
		return;
		
	set_task(1.0, "ShowMenuWithMapNames", 75102)
}

new bool:g_IsDraw = false;
public CheckVoteResults(result[], task)
{
	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Checking vote result.")
		
	new iWinnerMapIndex = result[0];
	new iSecondWinnerMapIndex = result[1];
	new szFormat[128];
	
	if(iSecondWinnerMapIndex != -1)
	{
		if(g_IsDraw == true)
		{
			new iRandom = random_num(0,1);

			static params[4];
			params[0] = iRandom;
			params[1] = 0;
			params[2] = 10;
			
			ChangeLevelTask(params,TASK_CHANGE_MAP);
		}
		else
		{
			formatex(szFormat, charsmax(szFormat), "We have a draw between: '%s' and '%s'.", g_VoteForNextMapNames[iWinnerMapIndex], g_VoteForNextMapNames[iSecondWinnerMapIndex]);
			set_hudmessage(0, 255, 255, 0.06, 0.70, 1, 1.0, 1.1, 0.2, 0.2, -1)
			ShowSyncHudMsg(0, g_SyncHudInfo, szFormat);
			
			
			g_VotedForNextMapNum = 2;
			g_VoteForNextMapNames[0] = g_VoteForNextMapNames[iWinnerMapIndex];
			g_VoteForNextMapNames[1] = g_VoteForNextMapNames[iSecondWinnerMapIndex]

			g_IsDraw = true;
			
			set_task(8.5, "EmitTimeToChooseSound");
			set_task(10.0, "StartDrawVote")
			
			CreateVoteMapEntities();
		}
	}
	else
	{
		static params[4];
		params[0] = iWinnerMapIndex;
		params[1] = 1;
		params[2] = 10;
		
		ChangeLevelTask(params, TASK_CHANGE_MAP);
	}
}

public ChangeLevelTask(params[], taskid)
{	
	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Changing map.")
		
	if(params[2] == 0)
	{
		new iMapIndex = params[0];
		
		new szMapName[64]
		if(containi(g_VoteForNextMapNames[iMapIndex], "restart") != -1)
			get_mapname(szMapName, charsmax(szMapName))
		else
			copy(szMapName, charsmax(szMapName), g_VoteForNextMapNames[iMapIndex]);
			
		server_cmd("changelevel %s", szMapName);
	
	}
	else
	{
		new szFormat[128];
		if(params[1] == 0)
			formatex(szFormat, charsmax(szFormat), "We have second draw.^nGame randomly choosed result: %s^nMap will be changed in %d seconds...", g_VoteForNextMapNames[params[0]], params[2]);
		else 
			formatex(szFormat, charsmax(szFormat), "Vote winner: '%s'. Map will be changed in %d seconds...", g_VoteForNextMapNames[params[0]], params[2]);
		
		set_hudmessage(0, 255, 255, 0.06, 0.70, 1, 1.0, 1.1, 0.2, 0.2, -1)
		ShowSyncHudMsg(0, g_SyncHudInfo, szFormat);
		
		if(params[2] <= 10)
		{
			new word[10];
			num_to_word(params[2], word, 9);
		
			client_cmd(0, "spk %s", word);

			if(params[2] == 1)
				RemoveData()
		}
		
	}
	
	params[2]--;
	
	set_task(1.0, "ChangeLevelTask", TASK_CHANGE_MAP, params,3);
}
 
public RemoveData()
 {
 	new iRet;
	
	ExecuteForward(g_ForwardRemoveData, iRet);
	
	if(iRet != PLUGIN_CONTINUE)
		return iRet;
		
	RemoveAllMonsters();

	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Data removed.")
		
	return PLUGIN_CONTINUE;
}

public RemoveVoteMapEntitiesAndResetUsers()
{
	for(new i = 0; i < VOTE_MAP_COUNT; i++)
	{
		if(is_valid_ent(g_VoteForNextMapEntity[i]))
		{	
			if(is_valid_ent(entity_get_int(g_VoteForNextMapEntity[i], EV_INT_mapvote_header)))
				remove_entity(entity_get_int(g_VoteForNextMapEntity[i], EV_INT_mapvote_header))
			remove_entity(g_VoteForNextMapEntity[i])
		}
	}
	
	for(new i = 1 ; i <= g_MaxPlayers ; i++)
		if(is_user_alive(i))
			g_VotePlayerForNextMap[i] = 0;
}
public StartDrawVote()
{
	g_VoteTime = g_ConfigValues[CFG_VOTE_MAP_TIME];
	ShowMenuWithMapNames();
}
public GetMapIndexWithMostVotes(&ret1, &ret2)
{
	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Getting map index with most votes. Size: %d / %d", g_VotedForNextMapNum, VOTE_MAP_COUNT)

	new votes[ VOTE_MAP_COUNT ];
	
	//new Array:aVotes = ArrayCreate(g_VotedForNextMapNum, VOTE_MAP_COUNT)

	for(new i = 0 ; i < g_VotedForNextMapNum; i++)
		 votes[i] = GetPlayersNumInVoteZone( i + 1);

	new tempvotes, mostVotes, secondMostVotes = -1, firstMapId, secondMapId;

	/* Get map with most votes */
	for (new i = 0; i < g_VotedForNextMapNum; i++)
	{
		tempvotes = votes[i];
		if(tempvotes > mostVotes)
		{
			mostVotes = tempvotes;
			firstMapId = i;
		}
	}

	/* Get second map with most votes */
	for(new i = 0 ; i < g_VotedForNextMapNum; i++)
	{
		if(i == firstMapId)
			continue;
		
		tempvotes = votes[i];
		
		if(tempvotes > secondMostVotes)
		{
			secondMostVotes = tempvotes;
			secondMapId = i;
		}
	}

	// if we have a draw
	if(mostVotes == secondMostVotes)
	{
		ret1 = firstMapId;
		ret2 = secondMapId
	}
	else
	{
		ret1 = firstMapId;
		ret2 = -1;
	}
}

public ShowMenuMapWithNamesCb(id, menu, item) {}

public fwTouch(ent, id)
{
	g_VotePlayerForNextMap[id] = entity_get_int(ent, EV_INT_mapvote_index);

	if(!task_exists(id+61921))
		set_task(3.0, "CheckIfUserIsInVoteZone", id+61921);
}

public CheckIfUserIsInVoteZone(id)
{
	id -= 61921;
	
	if(is_user_alive(id))
	{
		new szClassName[15], entlist[2], bool:isPlayerInAnyZone = false;
		
		for(new i = 1; i <= g_VotedForNextMapNum; i++)
		{
			formatex(szClassName, 14, "mapvote%d", i);
		
			if(find_sphere_class(id, szClassName, 1.0, entlist, 1))	
			{
				isPlayerInAnyZone = true;
				break;
			}
		}
		
		if(!isPlayerInAnyZone)
			g_VotePlayerForNextMap[id] = 0;
	}
	else
		if(is_user_connected(id))
			g_VotePlayerForNextMap[id] = 0;
}

public CreateVoteMapZoneEntity(id)
{
	if(++g_CreatedMapVoteZoneIndex > VOTE_MAP_COUNT)
	{
		g_CreatedMapVoteZoneIndex = VOTE_MAP_COUNT;
		client_print(id, print_center, "LIMIT REACHED");
		return;
	}
	
	new Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	new ent = g_MapVoteZoneLastEntity = create_entity("trigger_multiple");
	
	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Creating vote map zone entity. ENT = %d.", ent)
		
	set_pev(ent, pev_classname, "mapvote1");
	
	set_pev(ent, pev_origin, fOrigin);
	dllfunc(DLLFunc_Spawn, ent);

	new Float:mins[3], Float:max[3];
	
	mins[0] = float(-g_MapVoteZoneWidth);
	mins[1] = float(-g_MapVoteZoneLength);
	mins[2] = -30.0;
	
	max[0] = float(g_MapVoteZoneWidth);
	max[1] = float(g_MapVoteZoneLength);
	max[2] = 30.0;
	
	entity_set_size(ent, mins, max);
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE);
	set_pev(ent, pev_nextthink, get_gametime()+0.1);
	new headerEnt = create_entity("env_sprite");
	
	fOrigin[2] += 55.0
	entity_set_vector(headerEnt, EV_VEC_origin, fOrigin)
	entity_set_model(headerEnt, "sprites/TD/votemap_sprites.spr");
	entity_set_float(headerEnt, EV_FL_scale, 0.7);
	entity_set_float(headerEnt, EV_FL_frame, float((g_CreatedMapVoteZoneIndex == VOTE_MAP_COUNT && g_ConfigValues[CFG_VOTE_ALLOW_RESTART]) ? 0 : g_CreatedMapVoteZoneIndex))
	fm_set_rendering(headerEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255);
	entity_set_int(ent, EV_INT_mapvote_header, headerEnt);
}

public CreateVoteMapEntities()
{
	new szClassname[15]
	for(new i ; i < g_VotedForNextMapNum; i++)
	{
		formatex(szClassname, 14, "mapvote%d", i+1)
		
		new ent = g_VoteForNextMapEntity[i] = create_entity("trigger_multiple");
		
		if(DEBUG)	
			log_to_file(LOG_FILE, "DEBUG: Creating vote map zone entity. ENT = %d", ent)
		
		set_pev(ent, pev_classname, szClassname);
		set_pev(ent, pev_origin, g_VoteForNextMapEntityPosition[i][0]);
		dllfunc(DLLFunc_Spawn, ent);

		entity_set_size(ent, g_VoteForNextMapEntityPosition[i][1], g_VoteForNextMapEntityPosition[i][2]);
		
		entity_set_int(ent, EV_INT_mapvote_index, i+1);
		
		set_pev(ent, pev_solid, SOLID_TRIGGER);
		set_pev(ent, pev_movetype, MOVETYPE_NONE);
		
		set_pev(ent, pev_nextthink, get_gametime()+0.1);
		
		new headerEnt = create_entity("env_sprite");
		set_pev(headerEnt, pev_classname, "mapvote%d_header", i+1);
		
		new Float:headerOrigin[3];
		headerOrigin[0] = g_VoteForNextMapEntityPosition[i][0][0];
		headerOrigin[1] = g_VoteForNextMapEntityPosition[i][0][1];
		headerOrigin[2] = g_VoteForNextMapEntityPosition[i][0][2]+55.0;
		
		entity_set_vector(headerEnt, EV_VEC_origin, headerOrigin)
		entity_set_model(headerEnt, "sprites/TD/votemap_sprites.spr");
		entity_set_float(headerEnt, EV_FL_scale, 0.7);
		if(containi(g_VoteForNextMapNames[i], "restart") == -1)
			entity_set_float(headerEnt, EV_FL_frame, (1.0*(i+1)))
		else
			entity_set_float(headerEnt, EV_FL_frame, 0.0)
		
		fm_set_rendering(headerEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255);
		entity_set_int(ent, EV_INT_mapvote_header, headerEnt);

		set_pev(headerEnt, pev_origin, headerOrigin);
	}
}

public GetPlayersNumInVoteZone(iZoneIndex)
{
	new num;
	for(new i = 1 ; i <= g_MaxPlayers; i++)
		if(is_user_alive(i) && g_VotePlayerForNextMap[i] == iZoneIndex)
			num++;
	return num;
}

public fwThink(ent)
{
	static Float:maxs[3], Float:mins[3];
	pev(ent, pev_absmax, maxs);
	pev(ent, pev_absmin, mins);
	
	static Float:fOrigin[3];
	pev(ent, pev_origin, fOrigin);
	
	new Float:fOff = -5.0;
	new Float:z;
	for(new i=0;i < 3; i++)
	{
		z = fOrigin[2]+fOff;
		DrawVoteMapLine(maxs[0], maxs[1], z, mins[0], maxs[1], z);
		DrawVoteMapLine(maxs[0], maxs[1], z, maxs[0], mins[1], z);
		DrawVoteMapLine(maxs[0], mins[1], z, mins[0], mins[1], z);
		DrawVoteMapLine(mins[0], mins[1], z, mins[0], maxs[1], z);
		fOff += 5.0;
	}
	
	set_pev(ent, pev_nextthink, get_gametime()+1.5);
}

stock DrawVoteMapLine(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2) 
{
	new  iColor[3] = {0, 50, 255};
	new Float:start[3], Float:stop[3];
	start[0] = x1;
	start[1] = y1;
	start[2] = z1 - 20.0;
	
	stop[0] = x2;
	stop[1] = y2;
	stop[2] = z2 - 20.0;
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, start[0])
	engfunc(EngFunc_WriteCoord, start[1])
	engfunc(EngFunc_WriteCoord, start[2])
	engfunc(EngFunc_WriteCoord, stop[0])
	engfunc(EngFunc_WriteCoord, stop[1])
	engfunc(EngFunc_WriteCoord, stop[2])
	write_short(g_SpriteWhiteLine)
	write_byte(1)
	write_byte(5)
	write_byte(15)
	write_byte(20)
	write_byte(0)
	write_byte(iColor[0])	// RED
	write_byte(iColor[1])	// GREEN
	write_byte(iColor[2])	// BLUE					
	write_byte(250)	// brightness
	write_byte(5)
	message_end()
}


public StartCountdown(params[], task) 
{			
	new iSecond = params[0];
	
	/* Emit Growl Sound before Monster come */
	if(random(3) == 1) 
	{
		static iStart;
		if(!iStart) iStart = find_ent_by_tname(-1, "start")

		switch(random_num(1, 4)) 
		{
			case 1: emit_sound(iStart, CHAN_AUTO, g_SoundFile[SND_MONSTER_GROWL_1], 1.0, 0.70, 0, PITCH_NORM); 
			case 2: emit_sound(iStart, CHAN_AUTO, g_SoundFile[SND_MONSTER_GROWL_2], 1.0, 0.70, 0, PITCH_NORM); 
			case 3: emit_sound(iStart, CHAN_AUTO, g_SoundFile[SND_MONSTER_GROWL_3], 1.0, 0.70, 0, PITCH_NORM); 
			case 4: emit_sound(iStart, CHAN_AUTO, g_SoundFile[SND_MONSTER_GROWL_4], 1.0, 0.70, 0, PITCH_NORM); 
		}
	}

	if(iSecond) 
	{
		if((iSecond > 5 && iSecond % 3 == 1) || iSecond <= 5)
			client_cmd(0, "spk sound/%s", g_SoundFile[SND_COUNTDOWN]);
		
		set_dhudmessage(255, 255, 0, 0.06, 0.63, 1, 0.1, 1.0, 0.1, 0.1)
		show_dhudmessage(0, "Wave %d will start in %d %s", g_ActualWave, iSecond, iSecond == 1 ? "second" : "seconds");

		/*
		for(new i = 1 ; i <=  g_MaxPlayers; i++ ) 
		{
			if(is_user_connected(i))
			{
	
				if(giPlayerChangedClass[i]) {
					disablePlayerClassForward(i, giPlayerClass[i])
					giPlayerClass[i] = giPlayerChangedClass[i];
					giPlayerChangedClass[i] = 0;
				}
			}
		}*/
	} 
	else
	{
		set_dhudmessage(255, 255, 0, 0.06, 0.63, 1, 1.0, 1.5)
		show_dhudmessage(0, "START!!!")
		
		CountdownEnded();
		return;
	}
	new szData[2];
	szData[0] = --iSecond;
	
	set_task(1.0, "StartCountdown", TASK_COUNTDOWN, szData, 1) 
}

new g_HowManyMonsters;
public CountdownEnded()
{
	if(g_AliveMonstersNum)
		RemoveAllMonsters();
		
	new iRet;
	ExecuteForward(g_ForwardWaveStarted, iRet, g_ActualWave, g_InfoAboutWave[g_ActualWave][WAVE_ROUND_TYPE], IsSpecialWave(g_ActualWave) ?  g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM] + 1 :  g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM])
	if(iRet != PLUGIN_CONTINUE)
		return iRet

	for(new i = 1 ; i <= g_MaxPlayers; i++)
	{
		if(is_user_alive(i))
			g_PlayerWavesPlayed[i]++
	}
	
	client_cmd(0, "spk sound/%s", g_SoundFile[SND_START_WAVE]);
	
	g_AliveMonstersNum = 0;
	g_SentMonstersNum = 0;
	
	/* If is special wave and to deploy is only special monster */
	g_HowManyMonsters = g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM];
	
	if(IsSpecialWave(g_ActualWave) )
	{
		if(g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM] == 0)
		{
			/* If is only special monster send him */
			new iPlayers = GetAlivePlayers();
			new hp =  g_InfoAboutWave[g_ActualWave][WAVE_SPECIAL_HEALTH]
			new type = g_InfoAboutWave[g_ActualWave][WAVE_ROUND_TYPE];
			
			if(iPlayers >= g_ConfigValues[CFG_WAVE_MLTP_MIN_PLAYERS])
			{
				if(type == ROUND_BONUS)
					hp = floatround( hp * power_float(g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP_BONUS], iPlayers))
				else
					hp = floatround( hp * power_float(g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP_BOSS], iPlayers))	
			}
	
			SendMonster(type, hp,  g_InfoAboutWave[g_ActualWave][WAVE_SPECIAL_SPEED]);
			return PLUGIN_CONTINUE;
		} 
		else
		{
			/* 
				If is special wave and will come more mosters than only 
				one(Boss or Bonus) - repeat one more time to send special monster
			*/
			g_HowManyMonsters++;
		}
	}

	if(DEBUG)	
		log_to_file(LOG_FILE, "DEBUG: Countdown ended.")
		
	set_task(g_ConfigValuesFloat[CFG_FLOAT_SEND_MONSTER_TIME], "PreSendMonster", TASK_SEND_MONSTERS, _, _, "a", g_HowManyMonsters);
	return PLUGIN_CONTINUE;
}

public PreSendMonster()
{
	g_HowManyMonsters--;
	
	new iPlayers = GetAlivePlayers();
	new isSpecialWave = IsSpecialWave(g_ActualWave)
	new hp = g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_HEALTH]
	new bool:isMinPlayers = ( iPlayers >= g_ConfigValues[CFG_WAVE_MLTP_MIN_PLAYERS] )
	
	if(isSpecialWave)
	{
		if(g_HowManyMonsters == 0)
		{
			new type = g_InfoAboutWave[g_ActualWave][WAVE_ROUND_TYPE];
			hp = g_InfoAboutWave[g_ActualWave][WAVE_SPECIAL_HEALTH]
			if(isMinPlayers)
			{
				if(type  == ROUND_BONUS) hp = floatround( hp * power_float(g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP_BONUS], iPlayers))
				else hp = floatround( hp * power_float(g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP_BOSS], iPlayers))	
			}
	
			SendMonster(type, hp, g_InfoAboutWave[g_ActualWave][WAVE_SPECIAL_SPEED]);
		}
		else
		{
			if(isMinPlayers) hp = floatround( hp * power_float(g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP], iPlayers))	
			
			SendMonster(ROUND_NORMAL,  hp, g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_SPEED]);
		}
	}
	else
	{
		if(isMinPlayers) hp = floatround( hp * power_float(g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP], iPlayers))	
			
		SendMonster(g_InfoAboutWave[g_ActualWave][WAVE_ROUND_TYPE],  hp, g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_SPEED]);
	}
}


public SendMonster(iMonsterType, iMonsterHealth, iMonsterSpeed) 
{
	static Float:fStartOrigin[3];
	static szModel[64];
	static iStart;
	
	/* Get start origin. It will execute only one time */
	if(!iStart) 
	{	
		iStart = find_ent_by_tname(-1, "start");
		entity_get_vector(iStart, EV_VEC_origin, fStartOrigin);
	}
	
	switch(iMonsterType)
	{
		case ROUND_NORMAL:	formatex(szModel, charsmax(szModel), "models/TD/%s.mdl", g_ModelFile[random(4)][MODEL_NORMAL])
		case ROUND_FAST:		formatex(szModel, charsmax(szModel), "models/TD/%s.mdl", g_ModelFile[random(4)][MODEL_FAST])
		case ROUND_STRENGTH:	formatex(szModel, charsmax(szModel), "models/TD/%s.mdl", g_ModelFile[random(4)][MODEL_STRENGTH])
		case ROUND_BONUS:	formatex(szModel, charsmax(szModel), "models/TD/%s.mdl", g_ModelFile[random(4)][MODEL_BONUS])
		case ROUND_BOSS:		formatex(szModel, charsmax(szModel), "models/TD/%s.mdl", g_ModelFile[random(4)][MODEL_BOSS])
	}

	/* Create monster with 'monster' classname */
	new iEnt = create_entity("info_target");	

	if( g_ConfigValues[CFG_PRM_MONSTER_CHANCE ] )
		if(random_num(1, g_ConfigValues[CFG_PRM_MONSTER_CHANCE ]) == 1)
			entity_set_edict(iEnt, EV_ENT_monster_premium, 1);
		
	entity_set_string(iEnt, EV_SZ_classname, "monster");
	
	/* Set monster model and that you can shot him */
	entity_set_model(iEnt, szModel);	
	entity_set_float(iEnt, EV_FL_takedamage, DAMAGE_YES);
	
	/* This fu*king function spell mi two days to fixing a problem with loopable touched track_wall, 2:53 AM and it is working :D*/
	entity_set_size(iEnt, Float:{-15.0, -15.0, -20.0}, Float:{15.0, 15.0, 56.0});			
	
	/* Spawn at start */
	entity_set_vector(iEnt, EV_VEC_origin, fStartOrigin);
		
	/* Set monster touchable */
	entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX);
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_FLY) 
	
	/* Set running animation */
	entity_set_int(iEnt, EV_INT_sequence, 4)
	entity_set_float(iEnt, EV_FL_animtime, 1.0)
	
	/* Set glow if is special monster */
	if(iMonsterType == ROUND_BONUS) 
	{
		emit_sound(iEnt, CHAN_ITEM, g_SoundFile[SND_BONUS_SPAWNED], 1.0, 0.1, 0, PITCH_NORM);
		set_rendering(iEnt, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 17)

		if(g_IsBonusThief)
		{
			new iRanger = create_entity("env_sprite")
	
			entity_set_string(iRanger, EV_SZ_classname, "ranger_bonus")
			entity_set_model(iRanger, "sprites/TD/ranger.spr")
			entity_set_edict(iEnt, EV_ENT_owner, iRanger)
		
			new Float:fFloatVal[3];
			/* Angle */
			entity_get_vector(iRanger, EV_VEC_angles, fFloatVal)
			fFloatVal[0] += 90
			entity_set_vector(iRanger, EV_VEC_angles,fFloatVal)
		
			/* Origin */
			entity_get_vector(iEnt, EV_VEC_origin, fFloatVal);
			fFloatVal[2] += 1.0
			entity_set_origin(iRanger, fFloatVal)
		
			entity_set_float(iRanger, EV_FL_scale,  (g_BonusThiefRange / 250.0))
	
			fm_set_rendering(iRanger, kRenderFxNone, 255, 255, 0, kRenderTransAdd, 255)
			set_task(0.5, "MakeBonusFx", iEnt + TASK_BONUS_FX);
		}

		set_task(0.5, "ShowBonusTopInfo", iEnt + TASK_SHOW_SPECIAL_INFO);
	}
	else if(iMonsterType == ROUND_BOSS)
	{
		emit_sound(iEnt, CHAN_ITEM, g_SoundFile[SND_BOSS_SPAWNED], 1.0, 0.1, 0, PITCH_NORM);
		set_rendering(iEnt, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 17)

		set_task(0.5, "ShowBossTopInfo", iEnt + TASK_SHOW_SPECIAL_INFO);
	}
	else if(IsPremiumMonster(iEnt))
	{
		if( g_ConfigValues[CFG_PRM_MONSTER_GLOW] )
			set_rendering(iEnt, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 17)

		iMonsterHealth = floatround(iMonsterHealth * g_ConfigValuesFloat[CFG_FLOAT_PRM_MONSTER_MLTP_HP]);
		iMonsterSpeed = floatround(iMonsterSpeed * g_ConfigValuesFloat[CFG_FLOAT_PRM_MONSTER_MLTP_SPEED]);
	}
		
	/* Animation speed via monster speed */			
	entity_set_int(iEnt, EV_INT_monster_speed, iMonsterSpeed)	
	entity_set_int(iEnt, EV_INT_monster_maxspeed, iMonsterSpeed)
	entity_set_float(iEnt, EV_FL_framerate,  iMonsterSpeed / 240.0 )
	
	/* --- Healthbar --- */

	/* Create healthbar and set him monster_healthbar */
	new iHealtbar = create_entity("env_sprite")
		
	entity_set_string(iHealtbar, EV_SZ_classname, "monster_healthbar");
	
	/* Set not touchable */
	entity_set_int(iHealtbar, EV_INT_solid, SOLID_NOT);
	entity_set_int(iHealtbar, EV_INT_movetype, MOVETYPE_FLY) 
	
	/* Set entity to monster */
	entity_set_edict(iEnt, EV_ENT_monster_healthbar, iHealtbar)
	
	/* Set displaying full health's healthbar */
	entity_set_float(iHealtbar , EV_FL_frame , 99.0 );
			
	 /* --------- */

	g_AliveMonstersNum ++;
	g_SentMonstersNum ++;
	
	/* Set first target */
	entity_set_int(iEnt, EV_INT_monster_track, 1)
	
	/* Set monster type */
	entity_set_int(iEnt, EV_INT_monster_type, iMonsterType)
	
	/* Set target where monster go on start - it will execute only one time */
	new  iTarget;
	
	iTarget = find_ent_by_tname(-1, "track1")
	if(!is_valid_ent(iTarget)) 
	{	
		iTarget = find_ent_by_tname(-1, "end")
		entity_set_int(iEnt, EV_INT_monster_track, -1)
	}
	
	/* Set aiming to target */
	entity_set_aim(iEnt, iTarget, Float:{0.0, 0.0, 0.0}, 0);	
	
	/* Set speed */
	static Float:Velocity[3]

	velocity_by_aim(iEnt, iMonsterSpeed, Velocity)
	entity_set_vector(iEnt, EV_VEC_velocity, Velocity)
	
	/* Set health */
	entity_set_float(iEnt, EV_FL_health, float(iMonsterHealth));
	entity_set_int(iEnt, EV_INT_monster_maxhealth, iMonsterHealth)
	
	/* Monsters will not colide withself */
	set_pev(iEnt, pev_groupinfo, 1 << g_SentMonstersNum );
}

public ShowBonusTopInfo(iEnt)
{
	if(!is_valid_ent( (iEnt -= TASK_SHOW_SPECIAL_INFO) ) || g_IsGameEnded)
		return;
	
	set_dhudmessage(255, 255, 0, -1.0, 0.25, 0, 0.5, 0.5)

	new iHealth = floatround( entity_get_float(iEnt, EV_FL_health) );
	
	if(g_IsBonusThief)
		show_dhudmessage(0, "Bonus HP: %d^nRobbed Gold: %d", iHealth < 0 ? 0 : iHealth, g_BonusRobbedGold)
	else
		show_dhudmessage(0, "Bonus HP: %d", iHealth < 0 ? 0 : iHealth)

	set_task(0.5, "ShowBonusTopInfo", iEnt + TASK_SHOW_SPECIAL_INFO);
}

public ShowBossTopInfo(iEnt)
{
	iEnt -= TASK_SHOW_SPECIAL_INFO
	if(!is_valid_ent(iEnt) || g_IsGameEnded)
		return;

	new iHealth;
	if((iHealth = floatround(entity_get_float(iEnt, EV_FL_health))) <= 0)
		return;
	
	set_dhudmessage(255, 0, 0, -1.0, 0.25, 0, 0.5, 0.5)
	show_dhudmessage(0, "Boss HP: %d", iHealth > 0 ? iHealth : 0)

	set_task(0.5, "ShowBossTopInfo", iEnt + TASK_SHOW_SPECIAL_INFO);
}

public MakeBonusFx(iEnt)
{
	iEnt -= TASK_BONUS_FX;
	
	if(!is_valid_ent(iEnt) || g_IsGameEnded)
		return;

	if(entity_get_float(iEnt, EV_FL_health) <= 0.0)
		return;
		
	new entlist[33];
	new num 
	static iChance;
	if(!iChance) iChance = g_ConfigValues[CFG_BONUS_STAEL_CHANCE];
	
	
	if( (num =  find_sphere_class(iEnt, "player", g_BonusThiefRange, entlist, 32) ) )
	{
		new Float:fOrigin[3], Origin[3];
		
		new iPlayer, iRandom;

		for(new i ; i < num ; i++)
		{
			iPlayer = entlist[i];
			if(!is_user_alive(iPlayer))
				continue;
				
			if(random(iChance - 1) == 0)
			{
				if(!fm_is_ent_visible(iPlayer, iEnt))
					continue;
					
				if(!g_PlayerInfo[iPlayer][PLAYER_GOLD])
					continue;
				
				static iMin, iMax;
				if(!iMin) iMin = g_ConfigValues[CFG_BONUS_MIN_GOLD]
				if(!iMax) iMax = g_ConfigValues[CFG_BONUS_MAX_GOLD]
				iRandom = random_num(iMin, iMax)
				
				if(iRandom == 0)
					continue;
					
				entity_get_vector(iPlayer, EV_VEC_origin, fOrigin);
				
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
				write_byte(TE_BEAMENTPOINT)
				write_short(iEnt | 0x1000)
				write_coord_f(fOrigin[0]) 
				write_coord_f(fOrigin[1]) 
				write_coord_f(fOrigin[2]) 
				write_short(g_SpriteLighting)
				write_byte(0) // framerate
				write_byte(4) // framerate
				write_byte(4) // life
				write_byte(40)  // width
				write_byte(0)   // noise
				write_byte(255)   // r, g, b
				write_byte(255)   // r, g, b
				write_byte(0)   // r, g, b
				write_byte(255)	// brightness
				write_byte(10)		// speed
				message_end()
				
				entity_get_vector(iPlayer, EV_VEC_origin, fOrigin);
				
				FVecIVec(fOrigin, Origin);
				
				message_begin(MSG_BROADCAST ,SVC_TEMPENTITY, Origin,iPlayer) //message begin
				write_byte(TE_SPRITETRAIL)
				write_coord(Origin[0]) // start position
				write_coord(Origin[1])
				write_coord(Origin[2])
				write_coord(Origin[0] + random_num(-3,3)) // end position
				write_coord(Origin[1]+ random_num(-3,3))
				write_coord(Origin[2]+ random_num(-3, 3))
				write_short(g_SpriteBloodDrop) // sprite index
				write_byte(random_num(30, 60)) // count
				write_byte(random_num(5, 15)) // life in 0.1's
				write_byte(5) // scale in 0.1's
				write_byte(random_num(10, 30)) // velocity along vector in 10's
				write_byte(random_num(3, 5)) // randomness of velocity in 10's
				message_end()
				
				client_cmd(iPlayer, "spk sound/%s", g_SoundFile[SND_COIN]);
			
				static szName[33];
				get_user_name(iPlayer, szName, 32);

				g_BonusRobbedGold += iRandom;
				
				if(g_PlayerInfo[iPlayer][PLAYER_GOLD] -  iRandom <= 0)
				{
					ColorChat(0, GREEN, "%s^x01 BONUS was completely robbed defender '%s'!", CHAT_PREFIX, szName);
					g_PlayerInfo[iPlayer][PLAYER_GOLD] = 0
				}	
				else
				{
					ColorChat(0, GREEN, "%s^x01 BONUS was robbed %d gold from defender '%s'!", CHAT_PREFIX,iRandom,  szName);
					g_PlayerInfo[iPlayer][PLAYER_GOLD] -= iRandom;
				}
					
			}
		}
	}
	
	set_task(0.5, "MakeBonusFx", iEnt + TASK_BONUS_FX);
}

makeDeathMsg(iPlayer, iHs, iHe)
{
	if(!g_ConfigValues[CFG_SHOW_DEATH_MSG])
		return
	
	static szWeapon[24], dmsg
	static iWeapon; iWeapon  = get_user_weapon(iPlayer)
	if(!dmsg)
		dmsg = get_user_msgid("DeathMsg");
	if(iHe)
		formatex(szWeapon, 23, "grenade");
	else
	{
		get_weaponname(iWeapon, szWeapon, 23)	
		replace(szWeapon, 23, "weapon_", "")
	}
	
	message_begin(MSG_ALL, dmsg, {0,0,0}, 0);
	write_byte(iPlayer);
	write_byte(0);
	write_byte(iHs);
	write_string(szWeapon)
	message_end()
}

public fwAddToFullPack(es_handle, e, ENT, HOST, hostflags, player, set) {
	if(player || !is_user_connected(HOST) || !is_valid_ent(ENT))
		return FMRES_IGNORED
	
	if(g_PlayerHealthbar[HOST] == 0) 
	{
		static szClassname[24];
		entity_get_string(ENT, EV_SZ_classname, szClassname, 23);
	
		if(equal(szClassname, "monster_healthbar")) 
		{
			set_es(es_handle, ES_RenderMode, kRenderTransAdd)
			set_es(es_handle, ES_RenderAmt, 0)
			
			return FMRES_IGNORED
		}
	}
	
	if(!IsMonster(ENT))
		return FMRES_IGNORED;
		
	static Float:fOrigin[3]
	static iHealthbar 
	
	iHealthbar = entity_get_edict(ENT, EV_ENT_monster_healthbar)
	
	if(is_valid_ent(iHealthbar)) 
	{	
		entity_get_vector(ENT, EV_VEC_origin, fOrigin)
		
		if(g_IsBonusThief && entity_get_int(ENT,EV_INT_monster_type) == ROUND_BONUS)
		{
			fOrigin[2] -= 20.0
			entity_set_origin(entity_get_edict(ENT, EV_ENT_owner), fOrigin) 
			fOrigin[2] +=20.0
		}
	
		fOrigin[ 2 ] += 45.0;		
		
		entity_set_origin(iHealthbar, fOrigin)
		entity_set_model(iHealthbar, g_HealthbarsSprite[g_PlayerHealthbar[HOST]]);
		entity_set_float(iHealthbar, EV_FL_scale, g_PlayerHealthbarScale[HOST])
		
		iHealthbar = 0
	}

	return FMRES_IGNORED;
}

/* Sterring monsters track to move */
public MonsterChangeTrack(iMonster, track) {
	if(!IsMonster(iMonster))
		return HAM_IGNORED

	static szTouchedTrackName[33]
	static szTargetTrackName[33];
	new iTrack = entity_get_int(iMonster, EV_INT_monster_track)
	
	/* Get touched class name */
	entity_get_string(track, EV_SZ_targetname, szTouchedTrackName, 32)

	/* If monster target is other than -1 */
	if(iTrack != -1)
	{
		formatex(szTargetTrackName, charsmax(szTargetTrackName), "track%d_wall", iTrack)
		
		/* If Monster touched his next track_wall target */
		if(equali(szTouchedTrackName, szTargetTrackName)) 
		{
			formatex(szTargetTrackName, charsmax(szTargetTrackName), "track%d", ++iTrack)
			
			new iTarget = find_ent_by_tname(-1, szTargetTrackName)
			
			if(!iTarget)
			{
				iTarget = find_ent_by_tname(-1, "end")
				iTrack = -1;
			}
	
			/* Set target */
			entity_set_int(iMonster, EV_INT_monster_track, iTrack);
			entity_set_aim(iMonster, iTarget, Float:{0.0, 0.0, 0.0},0);
			
			/* Set speed if monster slow down */
			new Float:Velocity[3]
			velocity_by_aim(iMonster, entity_get_int(iMonster, EV_INT_monster_speed), Velocity)
			entity_set_vector(iMonster, EV_VEC_velocity, Velocity)
		}
	} 
	/* If touched end_wall - humans don't kill monster */
	else if(equali(szTouchedTrackName, "end_wall")) 
	{	
		/* Check if monster is last */
		if(--g_AliveMonstersNum == 0 && g_SentMonstersNum == (IsSpecialWave(g_ActualWave) ? g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM] + 1 : g_InfoAboutWave[g_ActualWave][WAVE_MONSTER_NUM]))
			WaveEnded();
		
		new iDamage = entity_get_int(iMonster, EV_INT_monster_type) == ROUND_BOSS ?  g_ConfigValues[CFG_BOSS_DAMAGE] : g_ConfigValues[CFG_MONSTER_DAMAGE];

		g_TowerHealth -= iDamage
			
		if(g_TowerHealth <= 0) 
		{
			g_TowerHealth = 0;	
			EndGame(PLAYERS_LOSE);
		}
		else
			_td_update_tower_origin(0, float(iDamage),  1)
		
		/* Remove Monster and healthbar */
		if(is_valid_ent(entity_get_edict(iMonster, EV_ENT_monster_healthbar)))
			remove_entity(entity_get_edict(iMonster, EV_ENT_monster_healthbar))
		
		if( entity_get_int(iMonster, EV_INT_monster_type) == ROUND_BONUS)
		{
			g_BonusRobbedGold = 0;
			if(is_valid_ent( entity_get_edict(iMonster, EV_ENT_owner)) )
				remove_entity( entity_get_edict(iMonster, EV_ENT_owner) );
		}
			
		remove_entity(iMonster)
		
		if(g_IsTowerModelOnMap)
			TowerExplodeEffect()
	}
	return HAM_HANDLED
}

/* Shows info about acutally wave */
public DisplayWaveInfo(id, iWave) 
{
	new szText[128]

	if(iWave <= 1)
	{
		if(g_ActualWave > 1)
			iWave = g_ActualWave;
		else
		{
			iWave = 1;
			formatex(szText, charsmax(szText), "- START GAME -^n");
		}
		
	}
	
	new bool:isSpecialWave = IsSpecialWave(iWave) ? true : false
	new iMonsterNum = isSpecialWave  ? g_InfoAboutWave[iWave][WAVE_MONSTER_NUM] + 1 : g_InfoAboutWave[iWave][WAVE_MONSTER_NUM]
	new RoundType = g_InfoAboutWave[iWave][WAVE_ROUND_TYPE]
		
	formatex(szText, charsmax(szText), "%sWAVE: %d | %s [ %d %s ]", 
		szText,
		iWave, 
		(RoundType == ROUND_NONE 	? "GAME NOT STARTED":
		RoundType == ROUND_NORMAL 	? "NORMAL": 
		RoundType == ROUND_FAST 	? "FAST":
		RoundType == ROUND_STRENGTH 	? "STRENGTH":
		RoundType == ROUND_BONUS	? "BONUS":
		RoundType == ROUND_BOSS 	? "BOSS": "ERROR"),
		iMonsterNum, 
		iMonsterNum == 1		? "monster" : "monsters")
	
	new iPlayers = GetAlivePlayers();
	new bool:isMinPlayers = ( iPlayers >= g_ConfigValues[CFG_WAVE_MLTP_MIN_PLAYERS] )

	if((!isSpecialWave&& iMonsterNum) || (isSpecialWave && (iMonsterNum-1) > 0)) 
	{	
		new hp = g_InfoAboutWave[iWave][WAVE_MONSTER_HEALTH];
		
		if(isMinPlayers)
			hp = floatround( hp * power_float(g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP], iPlayers));
		formatex(szText, charsmax(szText), "%s^nHP: %d^nSPEED: %d", szText, hp, g_InfoAboutWave[iWave][WAVE_MONSTER_SPEED])
	}
	
	if(isSpecialWave)
	{
		new hp = g_InfoAboutWave[iWave][WAVE_SPECIAL_HEALTH];
		if(isMinPlayers)
		{
			if(RoundType  == ROUND_BONUS) hp = floatround( hp * power_float(g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP_BONUS], iPlayers))
			else hp = floatround( hp * power_float(g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP_BOSS], iPlayers))	
		}
		
		formatex(szText, charsmax(szText), "%s^n^n%s:^nHP: %d^nSPEED: %d", szText, RoundType == ROUND_BOSS ? "BOSS" :"BONUS", hp, g_InfoAboutWave[iWave][WAVE_SPECIAL_SPEED])
	}
	
	set_hudmessage(255, 255, 255, 0.50, 0.65, 2, 9.0, 15.0, 0.05, 3.0)
	show_hudmessage(id, szText)
}
public LoadConfig()
{
	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Loading config from ^"%s^" file started.", CONFIG_FILE)

	new iRet;
	ExecuteForward(g_ForwardSettingsRefreshed, iRet);
	
	if(iRet != PLUGIN_CONTINUE)
	{
		if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: Some plugin block load configs value from td_enginew. iRet != RETURN_PLUGIN_CONTINUE")
		return iRet;
	}
	
	if(!file_exists(CONFIG_FILE)) 
	{
		if(DEBUG)
		{
			log_to_file(LOG_FILE, "DEBUG: Config file ^"%s^" is not exist", CONFIG_FILE)
			log_to_file(LOG_FILE, "DEBUG: Loading default values")
		}

		/* Create default file */
		
		return PLUGIN_CONTINUE;
	}
	
	new szText[128], len;
	new szData[3][64]

	for(new i; read_file(CONFIG_FILE, i, szText, 127, len) ; i++) 
	{
		trim(szText)
		if(szText[0] == ';' || !strlen(szText) || equali(szText, "//", 2))
			continue;
		parse(szText, szData[0], 63, szData[1], 63, szData[2], 63);

		if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: Command '%s' | Set: '%s'", szData[0], szData[2]);
			
		if(equali(szData[0], "DATA_SAVE_MODE"))
			g_ConfigValues[CFG_DATA_SAVE_MODE] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "KILL_GOLD"))
			g_ConfigValues[CFG_KILL_GOLD] 			= str_to_num( szData[2] );
		else if(equali(szData[0], "KILL_MONEY"))
			g_ConfigValues[CFG_KILL_MONEY]			= str_to_num( szData[2] );
		else if(equali(szData[0], "KILL_BP_AMMO"))
			g_ConfigValues[CFG_KILL_BP_AMMO] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "KILL_BONUS_GOLD"))
			g_ConfigValues[CFG_KILL_BONUS_GOLD] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "KILL_BOSS_GOLD"))
			g_ConfigValues[CFG_KILL_BOSS_GOLD] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "KILL_BONUS_FRAGS"))
			g_ConfigValues[CFG_KILL_BONUS_FRAGS] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "KILL_BOSS_FRAGS"))
			g_ConfigValues[CFG_KILL_BOSS_FRAGS] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "AFK_TIME"))
			g_ConfigValues[CFG_AFK_TIME]			= str_to_num( szData[2] );
		else if(equali(szData[0], "PRM_MONSTER_CHANCE"))
			g_ConfigValues[CFG_PRM_MONSTER_CHANCE]			= str_to_num( szData[2] );
		else if(equali(szData[0], "PRM_MONSTER_GLOW"))
			g_ConfigValues[CFG_PRM_MONSTER_GLOW]			= str_to_num( szData[2] );
		else if(equali(szData[0], "PRM_MONSTER_MLTP_HP"))
			g_ConfigValuesFloat[CFG_FLOAT_PRM_MONSTER_MLTP_HP]	= str_to_float( szData[2] );
		else if(equali(szData[0], "PRM_MONSTER_MLTP_SPEED"))
			g_ConfigValuesFloat[CFG_FLOAT_PRM_MONSTER_MLTP_SPEED]	= str_to_float( szData[2] );
		else if(equali(szData[0], "PRM_MONSTER_MLTP_GOLD "))
			g_ConfigValuesFloat[CFG_FLOAT_PRM_MONSTER_MLTP_GOLD]		= str_to_float( szData[2] );
		else if(equali(szData[0], "BANK_LIMIT"))
			g_ConfigValues[CFG_BANK_LIMIT]			= str_to_num( szData[2] );
		else if(equali(szData[0], "BANK_LIMIT_VIP"))
			g_ConfigValues[CFG_BANK_LIMIT_VIP]			= str_to_num( szData[2] );
		else if(equali(szData[0], "BOSS_FOG"))
		{
			remove_quotes(szData[2]);
			
			new szColor[3][6];

			parse(szData[2], szColor[0], 5, szColor[1], 5, szColor[2], 5);

			for(new i = 0 ; i < 3 ; i++)
				g_FogColorBoss[i] = str_to_num( szColor[i] );
		}
		else if(equali(szData[0], "BONUS_FOG"))
		{
			remove_quotes(szData[2]);
			
			new szColor[3][6];

			parse(szData[2], szColor[0], 5, szColor[1], 5, szColor[2], 5);

			for(new i = 0 ; i < 3 ; i++)
				g_FogColorBonus[i] = str_to_num( szColor[i] );
		}
		else if(equali(szData[0], "DEFAULT_FOG"))
		{
			remove_quotes(szData[2]);
			
			new szColor[3][6];

			parse(szData[2], szColor[0], 5, szColor[1], 5, szColor[2], 5);

			for(new i = 0 ; i < 3 ; i++)
				g_FogColor[i] = str_to_num( szColor[i] );
		}
		
			
		else if(equali(szData[0], "DAMAGE_GOLD"))
			g_ConfigValues[CFG_DAMAGE_GOLD] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "DAMAGE_MONEY"))
			g_ConfigValues[CFG_DAMAGE_MONEY] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "DAMAGE_RATIO"))
			g_ConfigValues[CFG_DAMAGE_RATIO] 		= str_to_num( szData[2] );

		else if(equali(szData[0], "VOTE_MAP_TIME"))
			g_ConfigValues[CFG_VOTE_MAP_TIME] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "VOTE_ALLOW_RESTART"))
			g_ConfigValues[CFG_VOTE_ALLOW_RESTART] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "SHOW_DEATH_MSG"))
			g_ConfigValues[CFG_SHOW_DEATH_MSG] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "BONUS_MIN_GOLD"))
			g_ConfigValues[CFG_BONUS_MIN_GOLD] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "BONUS_MAX_GOLD"))
			g_ConfigValues[CFG_BONUS_MAX_GOLD]		= str_to_num( szData[2] );
		else if(equali(szData[0], "BONUS_STAEL_CHANCE"))
			g_ConfigValues[CFG_BONUS_STAEL_CHANCE] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "JOIN_PLAYER_EXTRA"))
			g_ConfigValues[CFG_JOIN_PLAYER_EXTRA] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "JOIN_PLAYER_EXTRA_MIN_WAVE"))
			g_ConfigValues[CFG_JOIN_PLAYER_EXTRA_MIN_WAVE] = str_to_num( szData[2] );
		else if(equali(szData[0], "JOIN_PLAYER_EXTRA_MONEY"))
			g_ConfigValues[CFG_JOIN_PLAYER_EXTRA_MONEY] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "JOIN_PLAYER_EXTRA_GOLD"))
			g_ConfigValues[CFG_JOIN_PLAYER_EXTRA_GOLD] 	= str_to_num( szData[2] );

		else if(equali(szData[0], "SWAP_MONEY"))
			g_ConfigValues[CFG_SWAP_MONEY] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "SWAP_MONEY_NEED"))
			g_ConfigValues[CFG_SWAP_MONEY_MONEY]		= str_to_num( szData[2] );
		else if(equali(szData[0], "SWAP_MONEY_GOLD_NUM"))
			g_ConfigValues[CFG_SWAP_MONEY_GOLD]		= str_to_num( szData[2] );

		else if(equali(szData[0], "HIT_SOUND"))
			g_ConfigValues[CFG_HIT_SOUND]			= str_to_num( szData[2] );
			
		else if(equali(szData[0], "SEND_MONSTER_TIME"))
			g_ConfigValuesFloat[CFG_FLOAT_SEND_MONSTER_TIME] = str_to_float( szData[2] );
		else if(equali(szData[0], "HEADSHOT_DAMAGE_MLTP"))
			g_ConfigValuesFloat[CFG_FLOAT_HEADSHOT_MULTIPLIER]= str_to_float( szData[2] );
		else if(equali(szData[0], "START_ZONE_STAY_TIME"))
			checkPlayerTime = g_ConfigValues[CFG_START_ZONE_STAY_TIME] = str_to_num( szData[2] );
		else if(equali(szData[0], "REPAIR_ZONE"))
			g_ConfigValues[CFG_REPAIR_ZONE]		= str_to_num( szData[2] );
		else if(equali(szData[0], "REPAIR_ZONE_ONE_PLAYER"))
			g_ConfigValues[CFG_REPAIR_ZONE_ONE_PLAYER]	= str_to_num( szData[2] );
		else if(equali(szData[0], "REPAIR_ZONE_BLOCKS"))
			g_ConfigValues[CFG_REPAIR_ZONE_BLOCKS]		= str_to_num( szData[2] );
		else if(equali(szData[0], "REPAIR_ZONE_COST"))
			g_ConfigValues[CFG_REPAIR_ZONE_COST]		= str_to_num( szData[2] );
	
		else if(equali(szData[0], "WAVE_EXTRA_GOLD"))
			g_ConfigValues[CFG_WAVE_EXTRA_GOLD]		= str_to_num( szData[2] );
		else if(equali(szData[0], "WAVE_EXTRA_MONEY"))
			g_ConfigValues[CFG_WAVE_EXTRA_MONEY] 		= str_to_num( szData[2] );

		else if(equali(szData[0], "ONE_PLAYER_MODE"))
			g_ConfigValues[CFG_ONE_PLAYER_MODE] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "RESPAWN_CMD"))
			g_ConfigValues[CFG_RESPAWN_CMD] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "BLOCK_CMD_KILL"))
			g_ConfigValues[CFG_BLOCK_CMD_KILL] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "SHOW_CENTER_LEFT_DAMAGE"))
			g_ConfigValues[CFG_SHOW_LEFT_DAMAGE]		= str_to_num( szData[2] );
		else if(equali(szData[0], "KILL_MONSTER_FX"))
			g_ConfigValues[CFG_KILL_MONSTER_FX] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "KILL_MONSTER_SOUND"))
			g_ConfigValues[CFG_KILL_MONSTER_SOUND] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "HIT_MONSTER_BLOOD_CHANCE"))
			g_ConfigValues[CFG_HIT_MONSTER_BLOOD_CHANCE] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "HIT_MONSTER_SOUND"))
			g_ConfigValues[CFG_HIT_MONSTER_SOUND] 		= str_to_num( szData[2] );

		else if(equali(szData[0], "NAPALM_NADE_DURATION"))
			g_ConfigValues[CFG_NAPALM_NADE_DURATION] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "NAPALM_NADE_RADIUS"))
			g_ConfigValues[CFG_NAPALM_NADE_RADIUS] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "NAPALM_NADE_DAMAGE"))
			g_ConfigValues[CFG_NAPALM_NADE_DAMAGE] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "NAPALM_NADE_LIMIT"))
			g_ConfigValues[CFG_NAPALM_NADE_LIMIT] 		= str_to_num( szData[2] );

		else if(equali(szData[0], "STOP_NADE_DURATION"))
			g_ConfigValues[CFG_STOP_NADE_DURATION] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "STOP_NADE_RADIUS"))
			g_ConfigValues[CFG_STOP_NADE_RADIUS] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "STOP_NADE_LIMIT"))
			g_ConfigValues[CFG_STOP_NADE_LIMIT] 		= str_to_num( szData[2] );

		else if(equali(szData[0], "FROZEN_NADE_DURATION"))
			g_ConfigValues[CFG_FROZEN_NADE_DURATION] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "FROZEN_NADE_RADIUS"))
			g_ConfigValues[CFG_FROZEN_NADE_RADIUS] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "FROZEN_NADE_SLOW_PERCENT"))
			g_ConfigValuesFloat[CFG_FLOAT_FROZEN_NADE_PERCENT] = str_to_float( szData[2] );
		else if(equali(szData[0], "FROZEN_NADE_LIMIT"))
			g_ConfigValues[CFG_FROZEN_NADE_LIMIT] 		= str_to_num( szData[2] );

		else if(equali(szData[0], "VIP"))
			g_ConfigValues[CFG_VIP] 			= str_to_num( szData[2] );
		else if(equali(szData[0], "VIP_EXTRA_SPEED"))
			g_ConfigValues[CFG_VIP_EXTRA_SPEED] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "VIP_EXTRA_DAMAGE_MLTP"))
			g_ConfigValuesFloat[CFG_FLOAT_VIP_EXTRA_DAMAGE_MLTP]	= str_to_float( szData[2] );
		else if(equali(szData[0], "VIP_SHOW_IN_TABLE"))
			g_ConfigValues[CFG_VIP_SHOW_IN_TABLE] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "VIP_CHAT_COLOR"))
			g_ConfigValues[CFG_VIP_CHAT_COLOR] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "VIP_CHAT_PREFIX"))
		{
			remove_quotes( szData[2] );
			formatex(g_szVipChatPrefix, 7, szData[2]);
		}
		else if(equali(szData[0], "VIP_FLAG"))
		{
			remove_quotes( szData[2] );
			formatex(g_szVipFlag, 3, szData[2]);
		}
		else if(equali(szData[0], "VIP_START_WEAPONS"))
		{
			remove_quotes( szData[2] );
			formatex(g_szVipStartWeapons, 23, szData[2]);
		}
		else if(equali(szData[0], "VIP_EXTRA_KILL_GOLD"))
			g_ConfigValues[CFG_VIP_EXTRA_KILL_GOLD] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "VIP_EXTRA_KILL_MONEY"))
			g_ConfigValues[CFG_VIP_EXTRA_KILL_MONEY] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "VIP_SURVIVE_WAVE_GOLD"))
			g_ConfigValues[CFG_VIP_SURV_WAVE_GOLD] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "VIP_SURVIVE_WAVE_MONEY"))
			g_ConfigValues[CFG_VIP_SURV_WAVE_MONEY] 	= str_to_num( szData[2] );

		else if(equali(szData[0], "WAVE_MLTP_MIN_PLAYERS"))
			g_ConfigValues[CFG_WAVE_MLTP_MIN_PLAYERS] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "WAVE_MLTP_HP"))
			g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP] 	= str_to_float( szData[2] );
		else if(equali(szData[0], "WAVE_MLTP_HP_BOSS"))
			g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP_BOSS]= str_to_float( szData[2] );
		else if(equali(szData[0], "WAVE_MLTP_HP_BONUS"))
			g_ConfigValuesFloat[CFG_FLOAT_WAVE_MLTP_HP_BONUS]= str_to_float( szData[2] );
		else if(equali(szData[0], "AUTO_RESPAWN"))
			g_ConfigValues[CFG_AUTO_RESPAWN] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "PREFIX_CHAT_SHOW_LEVEL"))
			g_ConfigValues[CFG_CHAT_SHOW_LEVEL]		= str_to_num( szData[2] );
		else if(equali(szData[0], "WIN_GAME_GOLD_PRIZE"))
			g_ConfigValues[CFG_WIN_GAME_GOLD_PRIZE]	= str_to_num(szData[2]);
		else if(equali(szData[0], "LOSE_GAME_GOLD_PRIZE"))
			g_ConfigValues[CFG_LOSE_GAME_GOLD_PRIZE]	= str_to_num(szData[2]);
	}

	if(g_ConfigValues[CFG_REPAIR_ZONE] == 0)
	{
		if(is_valid_ent(g_RepairZoneEntity))
		{
			remove_entity(entity_get_int(g_RepairZoneEntity, EV_INT_repairzone_entity));
			remove_entity(g_RepairZoneEntity)
		}
	}
	return PLUGIN_CONTINUE;
}
public LoadConfiguration()
{
	g_IsGamePossible = true;
	
	if(DEBUG)
	{
		log_to_file(LOG_FILE, "-------------------DEBUG MODE ON--------------------")
		log_to_file(LOG_FILE, "DEBUG: Validating configuration files...")
	}

	LoadModels();
	LoadSounds();

	LoadDefaultValues()
	
	CheckShopConfig();
	LoadLastMaps();
	
	new szMapName[33];
	get_mapname(szMapName, 32);
	LoadWaves(szMapName);
	
	if(!file_exists(MAP_CONFIG_FILE))
	{
		log_to_file(LOG_FILE, "DEBUG: Maps configuration file '%s' is not exist...", MAP_CONFIG_FILE)
		g_IsGamePossible = false
		
		write_file(MAP_CONFIG_FILE, ";File created automaticly. Here add your TD maps every new line. Automaticly added last played map", 0)
		write_file(MAP_CONFIG_FILE, szMapName, 1)
	}
	/* Allow to load all cvars and configs by server */
	set_task(0.5, "CheckMap");
}

public LoadLastMaps()
{
	new szText[64], len;

	/* Load every line in waves file */
	if(file_exists("addons/amxmodx/data/td-lastmapsplayed.cfg"))
	{
		for(new i; read_file("addons/amxmodx/data/td-lastmapsplayed.cfg", i, szText, 63, len) ; i++) 
		{
			trim(szText)
			
			/* If is comment or is empty load next line */
			if(szText[0] == ';' || !strlen(szText) ||g_LastMapsNum >= LAST_MAPS_SAVE)
				continue;
			
			/* Remove "" */
			remove_quotes(szText)
			if(DEBUG)	
				log_to_file(LOG_FILE, "DEBUG: Loaded last map: %s.", szText);
			copy(g_LastMapName[g_LastMapsNum++], charsmax(g_LastMapName[]),  szText);
		}
	}
}

public FinishLoadingConfig()
{
	CheckIsGamePossible();
	LoadConfig();
	
	if(DEBUG)
	{
		log_to_file(LOG_FILE, "DEBUG: Loading all configuration files finished.")
		log_to_file(LOG_FILE, "---------------END OF DEBUGGING TRACE---------------")
	}
}
public CheckMap() 
{
	set_task(0.5, "FinishLoadingConfig");
	
	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Starting a proccess of checking map.")
	
	/* start */
	new iEnt = find_ent_by_tname(-1, "start")
	
	if(iEnt) 
	{
		new Float:fOrigin[3];
		
		entity_get_vector(iEnt, EV_VEC_origin, fOrigin)
		
		new iSprite = create_entity("env_sprite")
		
		entity_set_string(iSprite, EV_SZ_classname, "start_sprite")
		entity_set_model(iSprite, SPAWN_SPRITE)
			
		entity_set_vector(iSprite, EV_VEC_origin, fOrigin)
		entity_set_int(iSprite, EV_INT_solid, SOLID_NOT);
		entity_set_int(iSprite, EV_INT_movetype, MOVETYPE_FLY) 
		
		entity_set_float(iSprite, EV_FL_framerate, 1.0)
		entity_set_float(iSprite, EV_FL_scale, 2.5)
	}
	else 
	{
		if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: Enity 'start' is not exist. iEnt = %d", iEnt)

		g_IsGamePossible = false;
		return PLUGIN_CONTINUE
	}
	/* end */
	
	iEnt = find_ent_by_tname(-1, "end")
	if(iEnt) 
	{
		new Float:fOrigin[3];
		entity_get_vector(iEnt, EV_VEC_origin, fOrigin)
		
		if(g_IsTowerModelOnMap)
		{
			iEnt = create_entity("info_target")

			entity_set_string(iEnt, EV_SZ_classname, "tower")
			entity_set_model(iEnt, GET_MODEL_DIR_FROM_FILE(g_ModelFile[ random(3) ][ MODEL_TOWER ]));
			entity_set_vector(iEnt, EV_VEC_origin, fOrigin);
			entity_set_int(iEnt, EV_INT_solid, SOLID_NOT);
			entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_FLY) 
			
			drop_to_floor(iEnt)
		}
		
	} 
	else 
	{
		if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: Entity 'end' on map is not exist.")

		g_IsGamePossible = false;
		
		return PLUGIN_CONTINUE
	}
	
	/* Check track */
	iEnt = find_ent_by_tname(-1, "track1")
	
	if(!is_valid_ent(iEnt)) 
	{
		if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: Entity 'track1' which sterring a monster is not exist. There can be a errors...")
	}
	else 
	{
		new szTrack[16], i;
		
		while(iEnt > 0) 
		{
			formatex(szTrack, charsmax(szTrack), "track%d_wall", ++i)
			
			iEnt = find_ent_by_tname(-1, szTrack)
			
			if(is_valid_ent(iEnt))
				fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 0)
			else 
			{
				formatex(szTrack, charsmax(szTrack), "track%d", i)
				if(is_valid_ent( find_ent_by_tname(-1, szTrack) )) {
					if(DEBUG)
						log_to_file(LOG_FILE, "DEBUG: Entity %s_wall is not exist...", szTrack)

					g_IsGamePossible = false;
					
					return PLUGIN_CONTINUE;
				}
				break;
			}
		}
	}

	if(is_valid_ent( (iEnt = find_ent_by_tname(-1, "end_wall")) ))
		fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 0)
	else
	{
		if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: Entity %s_wall is not exist...")					
		g_IsGamePossible = false;

		return PLUGIN_CONTINUE;
	} 

	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Checking map finished.")

	if(g_FogColor[0] == 0 && g_FogColor[1] == 0 && g_FogColor[2] == 0) {
		//todo what/
	}
	else
		CreateFog( 0, g_FogColor[0], g_FogColor[1], g_FogColor[2]);
			
	return PLUGIN_CONTINUE
}

public LoadWaves(szMapName[]) 
{
	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Loading waves from ^"%s.cfg^" file started.", szMapName)

	new szFileDir[64];
	new iLoadStandardWave;
	static LoadStandardConf;
	formatex(szFileDir, charsmax(szFileDir), "addons/amxmodx/configs/Tower Defense/%s.cfg", szMapName)
	
	if(!file_exists(szFileDir)) 
	{
		if(DEBUG)
		{
			log_to_file(LOG_FILE, "DEBUG: File ^"%s^" is not exist", szFileDir)
			log_to_file(LOG_FILE, "DEBUG: Loading standard waves")
		}
		
		iLoadStandardWave = 1;
	}
	
	if(iLoadStandardWave) 
	{
		if(DEBUG)
		{
			if(iLoadStandardWave == 2) 
				log_to_file(LOG_FILE, "DEBUG: In wave configuration file ^"%s^" selects loads standard waves.", szFileDir)
		}
		
		formatex(szFileDir, charsmax(szFileDir), "addons/amxmodx/configs/Tower Defense/standard_wave.cfg")
		
		if(!file_exists(szFileDir)) 
		{    
			log_to_file(LOG_FILE, "File configuration ^"%s^" is not exist. Changing to next map from amx_nextmap cvar", szFileDir)
			g_IsGamePossible = false
			
			return PLUGIN_CONTINUE		
		} 
		else 
		{
			LoadWaves("standard_wave");
			iLoadStandardWave = 0;
			
			return PLUGIN_CONTINUE;
		}
	}
	
	new szText[128], len;
	new szData[10][64]
	new bool:isWithStandardWave = false;
	
	for(new i; read_file(szFileDir, i, szText, 127, len) ; i++) 
	{
		trim(szText)
		remove_quotes(szText)
		
		if(containi(szText, "[LOAD_STANDARD_WAVE]") != -1)
		{
			isWithStandardWave = true;
			break;
		}
	}
	
	
	new iWasConf = 13 + VOTE_MAP_COUNT + (isWithStandardWave? 1 : 0);
	
	new bool:iLoadStartZone 	= false;
	new bool:iLoadedStartZone = false;
	
	new bool:iLoadRepairZone	= false;
	new bool:iLoadedRepairZone= false;
	
	new bool:iLoadVoteMapZone[VOTE_MAP_COUNT] = false;
	new bool:iLoadedVoteMapZone[VOTE_MAP_COUNT] = false;
	new iLoadVoteMapIndex = -1;
	
	/* Load every line in waves file */
	for(new i; read_file(szFileDir, i, szText, 127, len) ; i++) 
	{
		trim(szText)
		
		/* If is comment or is empty load next line */
		if(szText[0] == ';' || !strlen(szText))
			continue;
		
		/* Remove "" */
		remove_quotes(szText)
			
		replace_all(szText, 127, "=", "")
		replace_all(szText, 127, "(", "")
		replace_all(szText, 127, ")", "")
		replace_all(szText, 127, ",", "")
		
		/* Assign data */
		parse(szText, szData[0], 63, szData[1], 63, szData[2], 63, 
		szData[3], 63, szData[4], 63, szData[5], 63, szData[6], 63,
		szData[7], 63, szData[8], 63, szData[9], 63)
	
		/* Loading Configurations */
		if(iLoadStartZone)
		{
			if(DEBUG)
				log_to_file(LOG_FILE, "DEBUG: Loading startzone...")

			new Float:fOrigin[3];
			new Float:fMins[3];
			new Float:fMax[3];
			
			for(new i ; i < 3 ; i++)
			{
				fOrigin[i]  	= str_to_float(szData[i])
				fMins[i] 	= str_to_float(szData[i+3])
				fMax[i] 	= str_to_float(szData[i+6])
			}
			g_StartZoneCoordinations[0] = fOrigin;
			g_StartZoneCoordinations[1] = fMins
			g_StartZoneCoordinations[2] = fMax
			
			CreateStartZoneBox(fOrigin, 0, 0, fMins, fMax)
			iLoadStartZone = false;
			iLoadedStartZone = true;
			
			if(DEBUG)
				log_to_file(LOG_FILE, "DEBUG: Startzone loaded")
				
			continue;
		} 
		else if(iLoadRepairZone)
		{
			if(DEBUG)
				log_to_file(LOG_FILE, "DEBUG: Loading repairzone...")
				
			new Float:fOrigin[3];
			new Float:fMins[3];
			new Float:fMax[3];
			
			for(new i ; i < 3 ; i++)
			{
				fOrigin[i]  	= str_to_float(szData[i])
				fMins[i] 	= str_to_float(szData[i+3])
				fMax[i] 	= str_to_float(szData[i+6])
			}

				
			CreateRepairZoneBox(fOrigin, 0, 0, fMins, fMax)
			iLoadRepairZone = false;
			iLoadedRepairZone = true;
			if(DEBUG)
				log_to_file(LOG_FILE, "DEBUG: Repair Zone loaded")

			continue;
		}
		else if(iLoadVoteMapIndex != -1)
		{
			if(iLoadedVoteMapZone[iLoadVoteMapIndex])
			{
				if(DEBUG)
					log_to_file(LOG_FILE, "DEBUG: Error: [MAP_VOTE_ZONE_%d_ENTITY] was loaded multiply time!", iLoadVoteMapIndex+1)
			}
			
			if(DEBUG)
				log_to_file(LOG_FILE, "DEBUG: Loading Map Vote Zone %d...", iLoadVoteMapIndex + 1)

			for(new i ; i < 3 ; i++)
			{
				g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][0][i]  = str_to_float(szData[i])
				g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][1][i]  = str_to_float(szData[i+3])
				g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][2][i]  = str_to_float(szData[i+6])
			}
	
			iLoadedVoteMapZone[iLoadVoteMapIndex] = true;
			
			if(DEBUG)
			{
				log_to_file(LOG_FILE, "---: Creating map vote zone at Origin[0]: %0.1f | Origin[1]: %0.1f | Origin[2]: %0.1f", g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][0][0], g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][0][1], g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][0][2])
				log_to_file(LOG_FILE, "---: Mins[0]: %0.1f | Mins[1]: %0.1f | Mins[2]: %0.1f", g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][1][0], g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][1][1], g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][1][2])
				log_to_file(LOG_FILE, "---: Max[0]: %0.1f | Max[1]: %0.1f | Max[2]: %0.1f", g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][2][0], g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][2][1], g_VoteForNextMapEntityPosition[iLoadVoteMapIndex][2][2])
		
				log_to_file(LOG_FILE, "DEBUG: Map Vote Zone %d loaded", iLoadVoteMapIndex + 1)
			}
			iLoadVoteMapIndex = -1;
			continue;
		}
		
		if(iWasConf > 0 && !LoadStandardConf) 
		{
			if(DEBUG)
			{
				log_to_file(LOG_FILE, "DEBUG: Left command to use [iWasConf] = %d", iWasConf)

				if(equali(szData[0], "[REPAIR_ZONE_ENTITY]") || equali(szData[0], "[START_ZONE_ENTITY]") || equali(szData[0], "[LOAD_STANDARD_WAVE]"))
					log_to_file(LOG_FILE, "DEBUG: Command '%s'", szData[0])
				else
				{
					new cmd[33], was;
					for(new i ; i < VOTE_MAP_COUNT ; i++)
					{
						formatex(cmd, 32, "[MAP_VOTE_ZONE_%d_ENTITY]", i+1)
						if(equali(cmd, szData[0]))
						{
							log_to_file(LOG_FILE, "DEBUG: Command '%s'", szData[0])
							was = 1;
							break;
						}
					}
					
					if(!was)
						log_to_file(LOG_FILE, "DEBUG: Command '%s' | set: '%s'", szData[0], szData[1])
				}
			}

			if(equali(szData[0], "BASE_HEALTH")) 
			{
				iWasConf --;
				g_TowerHealth = g_ConfigValues[CFG_TOWER_HEALTH] = str_to_num(szData[1])
				
				continue;
			}
			else if(equali(szData[0], "TIME_TO_WAVE")) 
			{
				iWasConf --;
				g_ConfigValues[CFG_TIME_TO_WAVE] =  str_to_num(szData[1])
				
				continue;
			}
			else if(equali(szData[0], "MONSTER_DAMAGE")) 
			{
				iWasConf --;
				g_ConfigValues[CFG_MONSTER_DAMAGE] =  str_to_num(szData[1])
				
				continue;
			}
			else if(equali(szData[0], "BOSS_DAMAGE")) 
			{
				iWasConf --;
				g_ConfigValues[CFG_BOSS_DAMAGE] =  str_to_num(szData[1])
				
				continue;
			}
			else if(equali(szData[0], "TURRETS"))
			{
				iWasConf --;
				g_AreTurretsEnabled = str_to_num(szData[1]) ? true : false
				
				continue;
			}

			else if(equali(szData[0], "TOWER_MODEL"))
			{
				iWasConf --;
				g_IsTowerModelOnMap = str_to_num(szData[1]) ? true : false
				
				continue;
			}
			else if(equali(szData[0], "MAX_MAP_TURRETS")) 
			{
				iWasConf --;
				MAX_TURRETS_ON_MAP = clamp(str_to_num(szData[1]), 1, 100)
				
				continue;
			}
			else if(equali(szData[0], "REPAIR_ZONE_TIME"))
			{
				iWasConf --;
				g_ConfigValues[CFG_REPAIR_ZONE_TIME] =  str_to_num(szData[1])
				continue;
			}
			else if(equali(szData[0], "REPAIR_ZONE_AMOUNT"))
			{
				iWasConf --;
				g_ConfigValues[CFG_REPAIR_ZONE_AMOUNT] =  str_to_num(szData[1])
				continue;
			}
			else if(equali(szData[0], "[REPAIR_ZONE_ENTITY]"))
			{
				iWasConf --;
				iLoadRepairZone = true;
				continue;
			}
			else if(equali(szData[0], "[START_ZONE_ENTITY]"))
			{
				iWasConf --;
				iLoadStartZone = true;
				continue;
			}
			else if(equali(szData[0], "[LOAD_STANDARD_WAVE]"))
			{
				LoadStandardConf = 1
				
				if(DEBUG)
				{
					if(!iLoadedStartZone)
						log_to_file(LOG_FILE, "DEBUG: [START_ZONE_ENTITY] is not exist. Please set it in admin menu nad paste to configuration file to play this map.")
					
					if(!iLoadedRepairZone)
						log_to_file(LOG_FILE, "DEBUG: [REPAIR_ZONE_ENTITY] is not exist. It is not the problem. If you want to add repair zone please set it in admin menu and paste to configuration file code before waves.")
					
					for(new i ; i < VOTE_MAP_COUNT; i++)
						if(!iLoadedVoteMapZone[i])
							log_to_file(LOG_FILE, "DEBUG: [MAP_VOTE_ZONE_%d_ENTITY] is not exist. Please set it in admin menu nad paste to configuration file to play this map.", i+1)
					
					if(!g_MapLight[0])
					{
						//get_pCFG_string(g_CvarPointers[CFG_MAP_LIGHT], g_MapLight, 1);
						log_to_file(LOG_FILE, "DEBUG: MAP_LIGHT is not exist. Loading default value: '%s'", g_MapLight)
					}
				}
				LoadWaves("standard_wave")
				
				continue
			}

			else if(containi(szData[0], "[MAP_VOTE_ZONE") != -1)
			{
				iLoadVoteMapIndex = str_to_num(szData[0][15]) - 1;
				
				iLoadVoteMapZone[iLoadVoteMapIndex] = true;
				iWasConf--;
				continue;
			}
			else if(equali(szData[0], "MAP_LIGHT"))
			{
				iWasConf--;
				copy(g_MapLight, 1, szData[1]);
				continue;
			}
			else if(equali(szData[0], "BONUS_THIEF_RANGE"))
			{
				iWasConf--;
			
				new iVal =  str_to_num(szData[1]);
				
				if(iVal)
				{
					g_IsBonusThief  = true;
					g_BonusThiefRange = float( iVal );
				}	

				continue;
			}

		}
		else
			iWasConf = 0
		
		if(DEBUG)
		{
			if(iWasConf > 0) 
			{
				//g_AreTurretsEnabled = false;
				if(!LoadStandardConf)
				{
					if(!iLoadedStartZone)
					{
						iWasConf--;
						log_to_file(LOG_FILE, "DEBUG: [START_ZONE_ENTITY] is not exist. Please set it in admin menu nad paste to configuration file to play this map.")
					}
					
					if(!iLoadedRepairZone)
					{
						iWasConf--;
						log_to_file(LOG_FILE, "DEBUG: [REPAIR_ZONE_ENTITY] is not exist. It is not the problem. If you want to add repair zone please set it in admin menu and paste to configuration file code before waves.")
					}
					
					for(new i ; i < VOTE_MAP_COUNT; i++)
					{
						if(!iLoadedVoteMapZone[i])
						{
							iWasConf--;
							log_to_file(LOG_FILE, "DEBUG: [MAP_VOTE_ZONE_%d_ENTITY] is not exist. Please set it in admin menu nad paste to configuration file to play this map.", i+1)
						}
					}
					
					if(!g_MapLight[0])
					{
						iWasConf--
						//get_pCFG_string(g_CvarPointers[CFG_MAP_LIGHT], g_MapLight, 1);
						log_to_file(LOG_FILE, "DEBUG: MAP_LIGHT is not exist. Loading default value: %s", g_MapLight)
					}
				}
	
				if(iWasConf > 0)
				{
					log_to_file(LOG_FILE, "DEBUG: File does not have all required commands.")
					log_to_file(LOG_FILE, "DEBUG: Missing commands were replaced with standard params.")
					iWasConf = 0;
				}
			}
		}
		/* Loading waves */
		
		static iWave, iOldWave, iNum;
		iWave = str_to_num(szData[0]);
		
		if(iWave > 0) 
		{
					
			if(DEBUG)
				log_to_file(LOG_FILE, "DEBUG: iWave: %d | RoundType: %s | MonstersNum: %s | MonsterHealth: %s | MonsterSpeed: %s | SpecialMonsterHP: %s | SpecialMonsterSpeed: %s", iWave, szData[1], szData[2], szData[3], szData[4], szData[5], szData[6])

			if(iWave != iOldWave && iWave-1 == iOldWave) 
			{
				iOldWave = iWave
				
				if(equali(szData[1], "NORMAL"))
					g_InfoAboutWave[iWave][WAVE_ROUND_TYPE] = ROUND_NORMAL;
				else if(equali(szData[1], "FAST"))
					g_InfoAboutWave[iWave][WAVE_ROUND_TYPE] = ROUND_FAST;
				else if(equali(szData[1], "STRENGTH"))
					g_InfoAboutWave[iWave][WAVE_ROUND_TYPE] = ROUND_STRENGTH;
				else if(equali(szData[1], "BOSS"))
					g_InfoAboutWave[iWave][WAVE_ROUND_TYPE] = ROUND_BOSS;
				else if(equali(szData[1], "BONUS"))
					g_InfoAboutWave[iWave][WAVE_ROUND_TYPE] = ROUND_BONUS;
			 	else
			 	{
					log_to_file(LOG_FILE, "Incorrect round type! ^"%s^" | line: %d", szData[1], i)
					g_IsGamePossible = false
					return PLUGIN_CONTINUE
				}
				
				/* ================================= */
				
				
				iNum = str_to_num(szData[2]);
				
				if(iNum < 0 || (!IsSpecialWave(iWave) && iNum == 0) || iNum > MAX_MONSTERS_PER_WAVE)
				{
					log_to_file(LOG_FILE, "Incorrect numbers of monster! ^"%d^" | line: %d", iNum, i)
					g_IsGamePossible = false
					
					return PLUGIN_CONTINUE
				}
				
				g_InfoAboutWave[iWave][WAVE_MONSTER_NUM] = iNum;
				
				/* ================================= */
				
				iNum = str_to_num(szData[3]);
				if(iNum <= 0 && !IsSpecialWave(iWave)) 
				{
					log_to_file(LOG_FILE, "Incorrect HP value! ^"%d^" | line: %d", iNum, i)
					g_IsGamePossible = false
					return PLUGIN_CONTINUE
				}
				g_InfoAboutWave[iWave][WAVE_MONSTER_HEALTH] = iNum
				
				/* ================================= */
				
				iNum = str_to_num(szData[4]);
				if(iNum <= 0 && !IsSpecialWave(iWave)) 
				{
					log_to_file(LOG_FILE, "Incorrect SPEED value! ^"%d^" | line: %d", iNum, i)
					g_IsGamePossible = false
					return PLUGIN_CONTINUE
				}
				g_InfoAboutWave[iWave][WAVE_MONSTER_SPEED] = iNum
				
				/* ================================= */
				
				if(IsSpecialWave(iWave)) 
				{	
					iNum = str_to_num(szData[5]);
					
					if(iNum <= 0) 
					{
						log_to_file(LOG_FILE, "Incorrect HP value [speccial wave]! ^"%d^" | line: %d", iNum, i)
						g_IsGamePossible = false
						return PLUGIN_CONTINUE
					}
					g_InfoAboutWave[iWave][WAVE_SPECIAL_HEALTH] = iNum
					
					/* ================================= */
					
					iNum = str_to_num(szData[6]);
					if(iNum <= 0)
					 {
						log_to_file(LOG_FILE, "Incorrect SPEED value [speccial wave]! ^"%d^" | line: %d", iNum, i)
						g_IsGamePossible = false
						return PLUGIN_CONTINUE
					}
					
					g_InfoAboutWave[iWave][WAVE_SPECIAL_SPEED] = iNum
					
					/* ================================= */
				}
				
				g_WavesNum++;
				
				
			} 
			else 
			{
				log_to_file(LOG_FILE, "Incorrect wave numver! Was ^"%d^", is ^"%d^". | line: %d", iOldWave, iWave, i)
				g_IsGamePossible = false
				return PLUGIN_CONTINUE
			}
		} 
		
	}
	if(DEBUG)
	{
		static wasEndDebugMessage;
	
		if(!wasEndDebugMessage)
		{
			wasEndDebugMessage = 1;
			log_to_file(LOG_FILE, "DEBUG: Loading waves finished.")
		}
	}
	return PLUGIN_CONTINUE
}

public CheckIsGamePossible(){
	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Checking game status started.")

	if(!g_IsGamePossible)
	{
		new szNextMap[33];
		get_cvar_string("amx_nextmap", szNextMap, 32);
		
		//set_task(1.0, "gameFalseChangeMap", TASK_GAME_FALSE, szNextMap, 32,"a", 50)
		
		log_to_file(LOG_FILE, "g_IsGamePossible == false - there was a problem with configuration files or map.")
	}
	
	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Checking game status finished.")
}

public CheckShopConfig()
{
	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Checking a configuration file of shop...");

	if(!file_exists(SHOP_CONFIG_FILE))
	{
		if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: Shop configuration file not found, creating new...")

		write_file(SHOP_CONFIG_FILE, ";**** FILE CREATED AUTOMATICLY ****", 0);
		write_file(SHOP_CONFIG_FILE, ";If you add a new item to shop, text will be created automaticly, example:", 1);
		write_file(SHOP_CONFIG_FILE, ";[NAME_OF_PLUGIN] // without .amxx", 2);
		write_file(SHOP_CONFIG_FILE, ";NAME = ^"name of item^" // must be in quotes(max 63 characters)", 3);
		write_file(SHOP_CONFIG_FILE, ";DESCRIPTION = ^"desc of item^" // must be in quotes (max 127 characters)", 4);
		write_file(SHOP_CONFIG_FILE, ";PRICE = 35 // only a numbers! (max 9999999, min 0 -> free)", 5);
		write_file(SHOP_CONFIG_FILE, ";ONE_PER_MAP = true (or yes, no, false) // others characters will not be load", 6);
		write_file(SHOP_CONFIG_FILE, ";If there is a problem, DEBUG mode in td_engine,sma will propably find it!", 7);
		write_file(SHOP_CONFIG_FILE, "", 8);

		if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: Shop configuration file created succesfully")
	}

	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Checking shop configuration file completed...")

}

public LoadModels()
{
	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Loading models from '%s' config file started.", MODELS_CONFIG_FILE)

	new szText[128], len;
	new szTemp[4][128];
	new iIndex;
	new szModelDir[128] = "models/TD";
				
	if(!file_exists(MODELS_CONFIG_FILE))
	{
		log_to_file(LOG_FILE, "Models config file '%s' is not exist.", MODELS_CONFIG_FILE)
		g_IsGamePossible = false
		
		return PLUGIN_CONTINUE;
	}
	
	/* Load all lines */
	for(new i ; read_file(MODELS_CONFIG_FILE, i, szText, 127, len) ; i++)
	{
		/* Remove empty 'char', like 'space' from loaded line */
		trim(szText)
		
		/* If line is comment or empty line - load next line */
		if(equali(szText, ";", 1) || !strlen(szText))
			continue;
		
		/* 
			Assign data to variable.
			Config file:
				'MODEL_TYPE' 'index' = 'name_model_without_mdl'
			e.g.
				'NORMAL_MDL 1 = normal1'
		*/
		szTemp[3] = "";
		szTemp[2] = "";
		szTemp[1] = "";
		szTemp[0] = "";
		
		parse(szText, szTemp[0], 127, szTemp[1], 16, szTemp[2], 127, szTemp[3], 127)
		iIndex = str_to_num(szTemp[1]) - 1;

		if(DEBUG)
		{
			szModelDir = "models/TD";
			log_to_file(LOG_FILE, "DEBUG: Loading model '%s' | set '%s' or '%s'", szTemp[0], szTemp[2], szTemp[3])
		
			if(containi(szTemp[0], "VIP_MODEL") != -1)
			{
				formatex(szModelDir, charsmax(szModelDir),"models/player/%s/%s.mdl", szTemp[3], szTemp[3]);
				if(!file_exists(szModelDir))
					log_to_file(LOG_FILE, "DEBUG: Defined player model '%s' is not exist.", szModelDir)
			}
			else
			{
				format(szModelDir, charsmax(szModelDir),"%s/%s.mdl", szModelDir, szTemp[3])
				
				if(!file_exists(szModelDir))
					log_to_file(LOG_FILE, "DEBUG: Defined model '%s' is not exist.", szModelDir)
			}
		}
	
		if(equali(szTemp[0], "NORMAL_MDL")) 
			copy(g_ModelFile[iIndex][MODEL_NORMAL], 31, szTemp[3])
		else if(equali(szTemp[0], "FAST_MDL"))
			copy(g_ModelFile[iIndex][MODEL_FAST], 31, szTemp[3])
		else if(equali(szTemp[0], "STRENGTH_MDL"))		
			copy(g_ModelFile[iIndex][MODEL_STRENGTH], 31, szTemp[3])
		else if(equali(szTemp[0], "BONUS_MDL"))
			copy(g_ModelFile[iIndex][MODEL_BONUS], 31, szTemp[3])
		else if(equali(szTemp[0], "BOSS_MDL"))
			copy(g_ModelFile[iIndex][MODEL_BOSS], 31, szTemp[3])
		else if(equali(szTemp[0], "TOWER_MDL"))
			copy(g_ModelFile[iIndex][MODEL_TOWER], 31, szTemp[3])
		/* Napalm nade */
		else if(equali(szTemp[0], "FLAME_GRENADE_MDL_V"))
			copy(g_ModelFileNapalmGrenade_V, 31, szTemp[2])
		else if(equali(szTemp[0], "FLAME_GRENADE_MDL_W"))
			copy(g_ModelFileNapalmGrenade_W, 31, szTemp[2])
		else if(equali(szTemp[0], "FLAME_GRENADE_MDL_P"))
			copy(g_ModelFileNapalmGrenade_P, 31, szTemp[2])
		/* Frozen grenade */
		else if(equali(szTemp[0], "FROZEN_GRENADE_MDL_V"))
			copy(g_ModelFileFrozenGrenade_V, 31, szTemp[2])
		else if(equali(szTemp[0], "FROZEN_GRENADE_MDL_W"))
			copy(g_ModelFileFrozenGrenade_W, 31, szTemp[2])
		else if(equali(szTemp[0], "FROZEN_GRENADE_MDL_P"))
			copy(g_ModelFileFrozenGrenade_P, 31, szTemp[2])
		/* Stop grenade */
		else if(equali(szTemp[0], "STOP_GRENADE_MDL_V"))
			copy(g_ModelFileStopGrenade_V, 31, szTemp[2])
		else if(equali(szTemp[0], "STOP_GRENADE_MDL_W"))
			copy(g_ModelFileStopGrenade_W, 31, szTemp[2])
		else if(equali(szTemp[0], "STOP_GRENADE_MDL_P"))
			copy(g_ModelFileStopGrenade_P, 31, szTemp[2])
		else if(equali(szTemp[0], "VIP_MODEL"))
			copy(g_VipModel, 31, szTemp[2])	
	}
	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Loading models finished.")

	return PLUGIN_CONTINUE
	
}

public LoadSounds() 
{
	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Loading sounds from '%s' config file started.", SOUNDS_CONFIG_FILE)


	new szText[128], len;
	new szTemp[3][128];
	
	if(!file_exists(SOUNDS_CONFIG_FILE))
	{
		log_to_file(LOG_FILE, "Sounds config file '%s' is not exist.", SOUNDS_CONFIG_FILE)
		g_IsGamePossible = false
		
		return PLUGIN_CONTINUE;
	}
	
	for(new i ; read_file(SOUNDS_CONFIG_FILE, i, szText, 127, len) ; i++)
	{
		/* Remove empty 'char', like 'space' from loaded line */
		trim(szText)
		
		/* If line is comment or empty line - load next line */
		if(equali(szText, ";", 1) || !strlen(szText))
			continue;
		
		/* 
			Assign data to variable.
			Config file:
				'SND_TYPE' = 'TD/name_of_sound.wav'
			e.g.
				START_WAVE = "TD/start_wave.wav"
		*/
		parse(szText, szTemp[0], 127, szTemp[1], 16, szTemp[2], 127)
		
		/* Remove quotes "" */
		remove_quotes(szTemp[2]);
		
		if(DEBUG)
		{
			log_to_file(LOG_FILE, "DEBUG: Loading sound '%s' | set '%s'", szTemp[0], szTemp[2])
			
			new szSoundDir[128];
			formatex(szSoundDir, charsmax(szSoundDir),"sound/%s", szTemp[2])
			
			if(!file_exists(szSoundDir))
				log_to_file(LOG_FILE, "DEBUG: Defined sound '%s' is not exist.", szSoundDir)
		}
		
		if(equali(szTemp[0], "START_WAVE")) 
			copy(g_SoundFile[SND_START_WAVE], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_DIE_1")) 
			copy(g_SoundFile[SND_MONSTER_DIE_1], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_DIE_2")) 
			copy(g_SoundFile[SND_MONSTER_DIE_2], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_DIE_3")) 
			copy(g_SoundFile[SND_MONSTER_DIE_3], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_DIE_4")) 
			copy(g_SoundFile[SND_MONSTER_DIE_4], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_HIT_1")) 
			copy(g_SoundFile[SND_MONSTER_HIT_1], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_HIT_2")) 
			copy(g_SoundFile[SND_MONSTER_HIT_2], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_HIT_3")) 
			copy(g_SoundFile[SND_MONSTER_HIT_3], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_HIT_4")) 
			copy(g_SoundFile[SND_MONSTER_HIT_4], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_SND_1")) 
			copy(g_SoundFile[SND_MONSTER_1], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_SND_2")) 
			copy(g_SoundFile[SND_MONSTER_2], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_SND_3")) 
			copy(g_SoundFile[SND_MONSTER_3], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_SND_4")) 
			copy(g_SoundFile[SND_MONSTER_4], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_GROWL_1")) 
			copy(g_SoundFile[SND_MONSTER_GROWL_1], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_GROWL_2")) 
			copy(g_SoundFile[SND_MONSTER_GROWL_2], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_GROWL_3")) 
			copy(g_SoundFile[SND_MONSTER_GROWL_3], 127, szTemp[2])
		else if(equali(szTemp[0], "MONSTER_GROWL_4")) 
			copy(g_SoundFile[SND_MONSTER_GROWL_4], 127, szTemp[2])
		else if(equali(szTemp[0], "BOSS_SPAWNED")) 
			copy(g_SoundFile[SND_BOSS_SPAWNED], 127, szTemp[2])
		else if(equali(szTemp[0], "BOSS_DIE")) 
			copy(g_SoundFile[SND_BOSS_DIE], 127, szTemp[2])
		else if(equali(szTemp[0], "BONUS_SPAWNED")) 
			copy(g_SoundFile[SND_BONUS_SPAWNED], 127, szTemp[2])
		else if(equali(szTemp[0], "BONUS_DIE")) 
			copy(g_SoundFile[SND_BONUS_DIE], 127, szTemp[2])
		else if(equali(szTemp[0], "COIN")) 
			copy(g_SoundFile[SND_COIN], 127, szTemp[2])
		else if(equali(szTemp[0], "ACTIVATED")) 
			copy(g_SoundFile[SND_ACTIVATED], 127, szTemp[2])
		else if(equali(szTemp[0], "COUNTDOWN")) 
			copy(g_SoundFile[SND_COUNTDOWN], 127, szTemp[2])
		else if(equali(szTemp[0], "PLAYER_LEVELUP")) 
			copy(g_SoundFile[SND_PLAYER_LEVELUP], 127, szTemp[2])
		else if(equali(szTemp[0], "PLAYER_USE_LIGHTING")) 
			copy(g_SoundFile[SND_PLAYER_USE_LIGHTING], 127, szTemp[2])
		else if(equali(szTemp[0], "CLEAR_WAVE")) 
			copy(g_SoundFile[SND_CLEAR_WAVE], 127, szTemp[2])
		else if(equali(szTemp[0], "STOP_GRENADE")) 
			copy(g_SoundFile[SND_STOP_GRENADE], 127, szTemp[2])
		else if(equali(szTemp[0], "DEFENDERS_WIN")) 
			copy(g_SoundFile[SND_DEFENDERS_WIN], 127, szTemp[2])
		else if(equali(szTemp[0], "DEFENDERS_LOSE")) 
			copy(g_SoundFile[SND_DEFENDERS_LOSE], 127, szTemp[2])
		else if(equali(szTemp[0], "HIT_SOUND"))
			copy(g_SoundFile[SND_HIT], 127, szTemp[2]);
		else if(equali(szTemp[0], "LAST_MAN"))
			copy(g_SoundFile[SND_LAST_MAN], 127, szTemp[2]);
	}
	
	if(DEBUG)
		log_to_file(LOG_FILE, "DEBUG: Loading sounds finished.")
	return PLUGIN_CONTINUE
}

public RemoveAllMonsters() 
{
	new iEnt = find_ent_by_class(-1, "monster");
	while(iEnt) 
	{
		//entity_set_int(iEnt, EV_INT_monster_type, 0)
		//entity_set_int(iEnt, EV_INT_monster_track, 0)
		//entity_set_int(iEnt, EV_INT_monster_maxhealth, 0)
		//entity_set_int(iEnt, EV_INT_monster_speed, 0)
		//entity_set_edict(iEnt, EV_ENT_monster_healthbar, 0)
		
		if(is_valid_ent( entity_get_edict(iEnt, EV_ENT_owner)) )
			remove_entity( entity_get_edict(iEnt, EV_ENT_owner) );
			
		remove_entity(iEnt)
		
		iEnt = find_ent_by_class(-1, "monster");
	}
	
	iEnt = find_ent_by_class(-1, "monster_healthbar")
	while(iEnt) 
	{
		remove_entity(iEnt)
		iEnt = find_ent_by_class(-1, "monster_healthbar")
	}
	
	g_AliveMonstersNum = 0;
	g_SentMonstersNum = 0;
	g_BonusRobbedGold = 0;
}

fm_set_user_money( id, Money, effect = 1)
{
	static s_msgMoney
	
	if(!s_msgMoney) 
		s_msgMoney = get_user_msgid("Money")
	
	set_pdata_int( id, 115, Money )
	
	emessage_begin( MSG_ONE, s_msgMoney, _, id )
	ewrite_long( Money )
	ewrite_byte( effect )
	emessage_end()
}

stock entity_set_aim(ent1, ent2, Float:offset2[3], region) 
{
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
	entity_get_vector(ent1,EV_VEC_origin,ent1origin)
	
	switch(region) 
	{
		case 1: offset[2] += 30.173410
		case 2: offset[2] += 17.271676
		case 3:
		{
			offset[0] += 12.000000
			offset[2] += 11.028901
		}
		case 4:
		{
			offset[0] += -12.000000
			offset[2] += 11.028901
		}
		case 5:
		{
			offset[0] += 8.000000
			offset[2] += -19.768786
		}
		case 6:
		{
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

public _td_update_tower_origin(iMode, Float:fDamage, iExplode)
 {
	if(g_IsTowerModelOnMap) 
	{
		new Float:fOrigin[3];
		
		new iTower = find_ent_by_class(-1, "tower");
		entity_get_vector(iTower, EV_VEC_origin, fOrigin);
		
		if(!iMode)
			fOrigin[2] -= ( 225.0 / ( float( g_ConfigValues[CFG_TOWER_HEALTH])  / fDamage ) )
		else 
			fOrigin[2] += ( 225.0 / ( float( g_ConfigValues[CFG_TOWER_HEALTH])  / fDamage ) )
		
		if(iExplode && g_IsTowerModelOnMap)
			TowerExplodeEffect()
			
		entity_set_vector(iTower,EV_VEC_origin,  fOrigin)
	}
}

new const g_MaxWeaponsBpAmmo[31] = {0,52,0,90,1,32,1,100,90,1,120,100,100,90,90,90,100,120,30,120,200,32,90,120,90,2,35,90,90,0,100};
stock GivePlayerAmmo(id, ammoNum)
{
	if(is_user_alive(id))
	{
		new weapon = get_user_weapon(id)
		if(weapon != 29) 
			cs_set_user_bpammo(id, weapon, cs_get_user_bpammo(id, weapon) + ammoNum);
		
		if(cs_get_user_bpammo(id, weapon) > g_MaxWeaponsBpAmmo[weapon]) 
			cs_set_user_bpammo(id, weapon, g_MaxWeaponsBpAmmo[weapon])
	}
}

stock fx_blood(origin[3], size)
{ 
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0]+random_num(-20,20))
	write_coord(origin[1]+random_num(-20,20))
	write_coord(origin[2]+random_num(-20,20))
	write_short(g_SpriteBloodSpray)
	write_short(g_SpriteBloodDrop)
	write_byte(229) // color index
	write_byte(size) // size
	message_end()
}

stock msg_implosion(id, Origin[3],  radius, numbers, time_)
 { // efekt 
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

public TowerExplodeEffect()
{ 
	static iEnt;
	static fEndOrigin[3];
	
	if(!iEnt)
	{
		new Float:fTemp[3];
		
		iEnt = find_ent_by_class(-1, "tower");
		entity_get_vector(iEnt, EV_VEC_origin, fTemp);
		
		FVecIVec(fTemp, fEndOrigin)
	}
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(fEndOrigin[0])
	write_coord(fEndOrigin[1])
	write_coord(fEndOrigin[2])
	write_short(g_SpriteExplode)
	write_byte(50)
	write_byte(10)
	write_byte(0)
	message_end()
}

stock Create_Lighting(startEntity, endEntity, startFrame, frameRate, life, width, noise, red, green, blue, alpha, speed) 
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_BEAMENTS )
	write_short( startEntity )              // start entity
	write_short( endEntity )                // end entity
	write_short( g_SpriteLighting )                  // model
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

/* Natives */

public _td_get_wave_info(iWave, ENUM_WAVE_INFO:iInfo)
	return g_InfoAboutWave[iWave][iInfo];

public _td_set_wave_info(iWave, ENUM_WAVE_INFO:iInfo, iValue) 
	 g_InfoAboutWave[iWave][iInfo] = iValue;
	
public _td_get_user_info(id, ENUM_PLAYER:iInfo)
	return g_PlayerInfo[id][iInfo]

public _td_set_user_info(id, ENUM_PLAYER:iInfo, iValue) 
	g_PlayerInfo[id][iInfo] = iValue

/* Register shop item */
public _td_shop_register_item(const szName[], const szDescription[], iPrice, iOnePerMap, plugin_index) {
	
	if(g_ShopItemsNum+1 > MAX_SHOP_ITEMS)
		return PLUGIN_CONTINUE
		
	g_ShopItemsNum++
	
	param_convert(1)
	param_convert(2)
	
	formatex(g_ShopItemsName[g_ShopItemsNum], 63, szName)
	formatex(g_ShopItemsDesc[g_ShopItemsNum], 127, szDescription)

	g_ShopItemsPrice[g_ShopItemsNum] = iPrice
	g_ShopOnePerMap[g_ShopItemsNum] = iOnePerMap

	/* Set shop item info to td_shop.cfg or replace existed configuration */
	SetShopItemInfo(plugin_index, g_ShopItemsNum)
	
	/* Return item index */
	return g_ShopItemsNum;
}

public SetShopItemInfo(iPluginIndex, iShopIndex) 
{
	new szFile[45]
	
	/* This variables are not useful */
	new szTitle[8]
	new szVersion[8]
	new szAuthor[8]
	new szStatus[8]
	/* */
	
	new szText[150];
	new szIndex[45];
	new len
	
	new bool:iFound;
	
	enum 
	{
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
	
	for(new i; read_file(SHOP_CONFIG_FILE, i, szText, 149, len) ; i++) 
	{
		trim(szText);
		if(szText[0] == ';' || !strlen(szText))
			continue;
			
		replace_all(szText, 149, "=", "")
		
		/* Check if is shop item */
		if(equali(szText, szIndex) && !iFound)
		{
			iFound = true
			iStatus = CHECK_NAME
			
			/* Load next line */
			continue;
		}

		/* If founded in file - load values */
		if(iFound) 
		{
			new szCommand[33], szInfo[128];
			parse(szText, szCommand, 32, szInfo, 127);
			
			if(iStatus == CHECK_NAME)
			{
				static szTemp[64];
				static bool:iMulti;
				
				if(equali(szCommand, "NAME") && !iMulti) 
				{
					replace(szText, 127, szCommand, "");
					trim(szText)
					
					if(szText[0] == '^"')
					{
						if(szText[strlen(szText)-1] == '^"') 
						{
							remove_quotes(szText);
							formatex(g_ShopItemsName[iShopIndex], 63, szText)
						}
						else
						{
							if(DEBUG)
								log_to_file(LOG_FILE, "DEBUG: [This is only warning] Item ^"%s^" in shop configuration file have name consisting of several lines.", szFile)

							iMulti = true;
							remove_quotes(szText);
							formatex(szTemp, 63, "%s", szText)
							continue;
						}
						
					}
					else
						if(DEBUG)
							log_to_file(LOG_FILE, "DEBUG: Item ^"%s^" in shop configuration file does not have initial quoted mark.", szFile)	
					
				}
				else if(iMulti) 
				{
					if(szText[strlen(szText)-1] == '^"')
						iMulti = false;
					
					format(szText, 63, " %s", szText)
					add(szTemp, 63, szText, 63)

					if(!iMulti) 
					{
						remove_quotes(szTemp)
						formatex(g_ShopItemsName[iShopIndex], 63, szTemp)
					}
					else 
						continue;
				}
				else 
					if(DEBUG)
						log_to_file(LOG_FILE, "DEBUG: Item ^"%s^" does not have a command which set item name (^"NAME^"). Loading default value.", szFile)				
				
				iStatus = CHECK_DESCRIPTION;
				continue;
			}
			else if(iStatus == CHECK_DESCRIPTION) 
			{
				static szTemp[128];
				static bool:iMulti;
				
				if(equali(szCommand, "DESCRIPTION") && !iMulti) 
				{
					replace(szText, 127, szCommand, "");
					trim(szText)
					if(szText[0] == '^"')
					{
						if(szText[strlen(szText)-1] == '^"')
						{
							remove_quotes(szText);
							formatex(g_ShopItemsDesc[iShopIndex], 127, szText)
						}
						else 
						{
							if(DEBUG)
								log_to_file(LOG_FILE, "DEBUG: [This is only warning] Item ^"%s^" in shop configuration file have description consisting of several lines", szFile)
							iMulti = true;
							remove_quotes(szText);
							formatex(szTemp, 127, "%s", szText)
							continue;
						}
						
					}
					else
						if(DEBUG)
							log_to_file(LOG_FILE, "DEBUG: Item ^"%s^" in shop configuration file does not have start quote in description.", szFile)		
					
				}
				else if(iMulti)
				{
					if(szText[strlen(szText)-1] == '^"')
						iMulti = false;
						
					format(szText, 127, " %s", szText)
					add(szTemp, 127, szText, 127)

					if(!iMulti)
					{
						remove_quotes(szTemp)
						formatex(g_ShopItemsDesc[iShopIndex], 127, szTemp)
					}
					else 
						continue;
				}
				else 
					if(DEBUG)
						log_to_file(LOG_FILE, "DEBUG: Item ^"%s^" in shop configuration file does not have description  (^"DESCRIPTION^"). Loading Default", szFile)					
				
				iStatus = CHECK_PRICE;
				continue;
			}
			else if(iStatus == CHECK_PRICE)
			{
				if(equali(szCommand, "PRICE")) 
				{
					new iNum = str_to_num(szInfo);
					
					if(iNum < 0 || iNum > 999999 && DEBUG)
						log_to_file(LOG_FILE, "DEBUG: Item ^"%s^" in shop configuration file is having bad price value (^"PRICE = %d^"). Loading Default.", szFile, iNum)
					else 
						g_ShopItemsPrice[iShopIndex] = str_to_num(szInfo)

				}
				else 
					if(DEBUG)
						log_to_file(LOG_FILE, "DEBUG: Item ^"%s^" in shop configuration file is having bad price value (^"PRICE^"). Loading Default.", szFile)
				
				iStatus = CHECK_ONE_PER_MAP;
				continue;
			}
			else if(iStatus == CHECK_ONE_PER_MAP) 
			{
				if(equali(szCommand, "ONE_PER_MAP")) 
				{
					if(equali(szInfo, "yes") || equali(szInfo, "true"))
						g_ShopOnePerMap[iShopIndex] = 1
					else if(equali(szInfo, "no") || equali(szInfo, "false"))
						g_ShopOnePerMap[iShopIndex] = 0
					else 
						if(DEBUG)
							log_to_file(LOG_FILE, "DEBUG: Item ^"%s^" in shop configuration file is having bad value. (^"ONE_PER_MAP = %s^" | Accepted values: yes, true, false, no). Loading default values.", szFile, szInfo)		
				}
				else 
					if(DEBUG)
						log_to_file(LOG_FILE, "DEBUG: Item ^"%s^" in shop configuration file is having bad value. (^"ONE_PER_MAP^" | Accepted values: yes, true, false, no). Loading default values.", szFile)	
				
				iStatus = CHECKED;
				break;
			}
		}
	}
		
	/* If is first load or item in file does not exist */
	if(!iFound)
	{
		if(DEBUG)
			log_to_file(LOG_FILE, "DEBUG: Item ^"%s^" in shop configuration file is not exist. Adding [This message can be showed when you add new item to shop]", szFile)
	
		write_file(SHOP_CONFIG_FILE, "", -1)
		write_file(SHOP_CONFIG_FILE, szIndex, -1)
			
		formatex(szText, 149, "NAME = ^"%s^"", g_ShopItemsName[iShopIndex])
		write_file(SHOP_CONFIG_FILE, szText, -1)
			
		formatex(szText, 149, "DESCRIPTION = ^"%s^"", g_ShopItemsDesc[iShopIndex])
		write_file(SHOP_CONFIG_FILE, szText, -1)
			
		formatex(szText, 149, "PRICE = %d", g_ShopItemsPrice[iShopIndex] )
		write_file(SHOP_CONFIG_FILE, szText, -1)

		formatex(szText, 149, "ONE_PER_MAP = %s", g_ShopOnePerMap[iShopIndex] ? "true":"false");
		write_file(SHOP_CONFIG_FILE, szText, -1)
	}
}

/* Mode 1 - add health | 0 - substract tower health */
public _td_set_tower_health(iMode, iHealth, iExplode) 
{
	if(iHealth > g_ConfigValues[CFG_TOWER_HEALTH] || iHealth <= 0 || (iMode != 0 && iMode != 1))
		return
		
	if(iMode == 1 && (g_TowerHealth + iHealth) > g_ConfigValues[CFG_TOWER_HEALTH] )
		return
	if(iMode == 0 && g_TowerHealth - iHealth < 0)
		return
	
	if(iMode == 1)
		g_TowerHealth += iHealth
	else if(iMode == 0)
		g_TowerHealth -= iHealth
	
	if(g_TowerHealth <= 0)
		EndGame(PLAYERS_LOSE)
	
	_td_update_tower_origin(iMode, float(iHealth), iExplode)
}
public _td_get_tower_health()
	return g_TowerHealth

public _td_get_max_tower_health()
	return g_ConfigValues[CFG_TOWER_HEALTH] 

public _td_get_monster_maxhealth(iEnt)
	return entity_get_int(iEnt,EV_INT_monster_maxhealth);

public GiveUserNapalmGrenade(iPlayer) 
{
	new napalm_weaponent = fm_get_napalm_entity(iPlayer)
	
	/* If have grenade */

	if (napalm_weaponent != 0)
	{
		new iAmmo =  entity_get_int(napalm_weaponent, EV_INT_grenade_ammo);

		if(iAmmo == g_ConfigValues[CFG_NAPALM_NADE_LIMIT])
			return 0;
			
		entity_set_int(napalm_weaponent, EV_INT_grenade_ammo,  iAmmo + 1)
		
		set_pdata_int(iPlayer, 388, get_pdata_int(iPlayer, 388) + 1, 5)
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoPickup"), _, iPlayer)
		write_byte(12)
		write_byte(1) 
		message_end()
		
		emit_sound(iPlayer, CHAN_ITEM, "items/9mmclip1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	else 
	{
		fm_give_item(iPlayer, "weapon_hegrenade")
		napalm_weaponent = fm_get_napalm_entity(iPlayer)
		
		entity_set_int(napalm_weaponent, EV_INT_grenade_ammo,  1)
	}
	
	entity_set_int(napalm_weaponent, EV_INT_grenade_type, GRENADE_NAPALM)
	set_pev(napalm_weaponent, pev_flTimeStepSound, 681856)

	return 1;
}

public GiveUserFrozenGrenade(iPlayer) 
{
	new frozen_weaponent = fm_get_frozen_entity(iPlayer)
	
	/* If have grenade */
	if (frozen_weaponent != 0)
	{
		new iAmmo =  entity_get_int(frozen_weaponent, EV_INT_grenade_ammo);

		if(iAmmo == g_ConfigValues[CFG_FROZEN_NADE_LIMIT])
			return 0;
			
		entity_set_int(frozen_weaponent, EV_INT_grenade_ammo,  iAmmo + 1)
		
		set_pdata_int(iPlayer, 389, get_pdata_int(iPlayer, 389) + 1, 5)
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoPickup"), _, iPlayer)
		write_byte(12)
		write_byte(1) 
		message_end()
		
		emit_sound(iPlayer, CHAN_ITEM, "items/9mmclip1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
		
	}
	else 
	{
		fm_give_item(iPlayer, "weapon_smokegrenade")
		frozen_weaponent = fm_get_frozen_entity(iPlayer)
		
		entity_set_int(frozen_weaponent, EV_INT_grenade_ammo,  1)
	}
	
	entity_set_int(frozen_weaponent, EV_INT_grenade_type, GRENADE_FROZEN)
	set_pev(frozen_weaponent, pev_flTimeStepSound, 681856)

	return 1;
}

public GiveUserStopGrenade(iPlayer) 
{
	new stop_weaponent = fm_get_stop_entity(iPlayer)
	
	/* If have grenade */
	if (stop_weaponent != 0)
	{
		new iAmmo =  entity_get_int(stop_weaponent, EV_INT_grenade_ammo);

		if(iAmmo == g_ConfigValues[CFG_STOP_NADE_LIMIT])
			return 0;
			
		entity_set_int(stop_weaponent, EV_INT_grenade_ammo,  iAmmo + 1)
		cs_set_user_bpammo(iPlayer, CSW_FLASHBANG, iAmmo + 1)

		//set_pdata_int(iPlayer, 389, get_pdata_int(iPlayer, 389) + 1, 5)
		//fm_give_item(iPlayer, "weapon_flashbang")

		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoPickup"), _, iPlayer)
		write_byte(12)
		write_byte(1) 
		message_end()
		
		emit_sound(iPlayer, CHAN_ITEM, "items/9mmclip1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	else 
	{
		fm_give_item(iPlayer, "weapon_flashbang")
		stop_weaponent = fm_get_stop_entity(iPlayer)
		
		entity_set_int(stop_weaponent, EV_INT_grenade_ammo,  1)
	}
	
	entity_set_int(stop_weaponent, EV_INT_grenade_type, GRENADE_STOP)
	set_pev(stop_weaponent, pev_flTimeStepSound, 681856)

	return 1;
}

public IsMonster(ent) 
{
	if(!is_valid_ent(ent))
		return 0;
		
	new szClassname[24];
	entity_get_string(ent, EV_SZ_classname, szClassname, 23);
	
	return equal(szClassname, "monster")
}

public IsHealthbar(ent)
{
	new szClassname[24];
	entity_get_string(ent, EV_SZ_classname, szClassname, 23);
	
	return equal(szClassname, "monster_healthbar") ? 1 : 0;
}
public IsSpecialMonster(ent)
	return entity_get_int(ent, EV_INT_monster_type) == ROUND_BOSS ? 1 : entity_get_int(ent, EV_INT_monster_type) == ROUND_BONUS ? 2 : 0;
	
public IsSpecialWave(iWaveNumber) 	
	return g_InfoAboutWave[iWaveNumber][WAVE_ROUND_TYPE] == ROUND_BOSS || g_InfoAboutWave[iWaveNumber][WAVE_ROUND_TYPE] == ROUND_BONUS ? 1 : 0

stock fm_get_napalm_entity(id)
	return fm_find_ent_by_owner(-1, "weapon_hegrenade", id);

stock fm_get_frozen_entity(id)
	return fm_find_ent_by_owner(-1, "weapon_smokegrenade", id);

stock fm_get_stop_entity(id)
	return fm_find_ent_by_owner(-1, "weapon_flashbang", id);
	
stock fm_get_user_current_weapon_ent(id)
	return get_pdata_cbase(id, 373, 5);

stock fm_get_weapon_ent_id(ent)
	return get_pdata_int(ent, 43, 4);

stock fm_get_weapon_ent_owner(ent)
	return get_pdata_cbase(ent, 41, 4);

public grenade_explode(ent, type)
{
	static attacker;
	attacker = pev(ent, pev_owner)
	
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	static Float:radius; radius = (type == GRENADE_NAPALM ? float(g_ConfigValues[CFG_NAPALM_NADE_RADIUS]) :
		type == GRENADE_FROZEN ? float(g_ConfigValues[CFG_FROZEN_NADE_RADIUS]) : 
		type == GRENADE_STOP ? float(g_ConfigValues[CFG_STOP_NADE_RADIUS]) : 300.0);
	
	CreateGrenadeBlast(originF, type)
	
	if(type == GRENADE_NAPALM || type == GRENADE_FROZEN)
		emit_sound(ent, CHAN_ITEM, "weapons/hegrenade-1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	else if(type == GRENADE_STOP)
		emit_sound(ent, CHAN_ITEM, g_SoundFile[SND_STOP_GRENADE],1.0, ATTN_NORM, 0, PITCH_NORM);
	
	static victim
	victim = 0
	
	static duration; duration = g_ConfigValues[CFG_NAPALM_NADE_DURATION];
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, radius)) != 0)
	{
		if (!IsMonster(victim))
			continue;
		
		if(type == GRENADE_NAPALM)
		{
			static params[2]
			params[0] = duration * 5 /* *5 becuose set_task is 0.2 */
			params[1] = attacker
			
			set_task(0.1, "burning_flame", victim+1000, params, sizeof params)
		}
		else if(type == GRENADE_FROZEN)
			FreezeMonsterByGrenade(victim + TASK_GRENADE_FROZEN);
		else if(type == GRENADE_STOP)
			FreezeMonsterByStopGrenade(victim + TASK_GRENADE_STOP);
	}
}

public FreezeMonsterByStopGrenade(iEnt)
{
	iEnt -= TASK_GRENADE_STOP
	if (!IsMonster(iEnt) || entity_get_float(iEnt, EV_FL_health) <= 0.0)
		return;

	fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
	if(task_exists(iEnt + TASK_GRENADE_FROZEN))
		remove_task(iEnt + TASK_GRENADE_FROZEN);
	
	_set_monster_speed(iEnt,0, 0, 1)	
	
	set_task(float(g_ConfigValues[CFG_FROZEN_NADE_DURATION]), "ResetMonsterSpeedByStopGrenade", iEnt + TASK_GRENADE_STOP)
}

public ResetMonsterSpeedByStopGrenade(iEnt)
{
	iEnt -= TASK_GRENADE_FROZEN;
	if(is_valid_ent(iEnt))
	{
		new iType = entity_get_int(iEnt, EV_INT_monster_type);
		
		if(iType == ROUND_BOSS)
			fm_set_rendering(iEnt, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 16)
		else if(iType == ROUND_BONUS)
			fm_set_rendering(iEnt, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 16)
		else
		{
			//ciekawy efekt
			//fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
			fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
		}
		
		//if(!task_exists(iEnt + TASK_GRENADE_FROZEN))
		_set_monster_speed(iEnt, 0, 1, 1);
	}
}
public FreezeMonsterByGrenade(iEnt)
{
	iEnt -= TASK_GRENADE_FROZEN
	
	if (!IsMonster(iEnt) || entity_get_float(iEnt, EV_FL_health) <= 0.0)
		return;
		
	new szData[2];
	szData[0] = _td_get_monster_speed(iEnt);
	
	fm_set_rendering(iEnt, kRenderFxGlowShell, 0, 100, 255, kRenderNormal, 17)
	
	if(task_exists(iEnt + TASK_GRENADE_FROZEN))
	{
		_set_monster_speed(iEnt, szData[0], 0, 1)
		szData[0] += 120;
		remove_task(iEnt + TASK_GRENADE_FROZEN);
	}
	else
		_set_monster_speed(iEnt, floatround(szData[0] - (szData[0] * g_ConfigValuesFloat[CFG_FLOAT_FROZEN_NADE_PERCENT])), 0, 1)	
	
	set_task(float(g_ConfigValues[CFG_FROZEN_NADE_DURATION]), "EndFreezeMonsterEffect", iEnt + TASK_GRENADE_FROZEN, szData, sizeof szData)
}

public EndFreezeMonsterEffect(szData[], iEnt) 
{
	iEnt -= TASK_GRENADE_FROZEN;
	if(is_valid_ent(iEnt))
	{
		new iType = entity_get_int(iEnt, EV_INT_monster_type);
		
		if(iType == ROUND_BOSS)
			fm_set_rendering(iEnt, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 16)
		else if(iType == ROUND_BONUS)
			fm_set_rendering(iEnt, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 16)
		else
		{
			//ciekawy efekt
			//fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
			fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
		}
		//if(task_exists(iEnt + TASK_GRENADE_STOP))
		//	return;
		if(szData[0] > 0)
			_set_monster_speed(iEnt, szData[0], 0, 1)
		else
			_set_monster_speed(iEnt, 0, 1, 1);
	}
}

public burning_flame(args[2], iEnt)
{
	iEnt -= TASK_GRENADE_NAPALM;
	
	if (!IsMonster(iEnt) ||  entity_get_float(iEnt, EV_FL_health) <= 0.0)
		return;
	
	static Float:originF[3]
	pev(iEnt, pev_origin, originF)
	
	if (args[0] < 1)
	{
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
	
	/* Takem damage*/
	ExecuteHamB(Ham_TakeDamage, iEnt, args[1], args[1], float(g_ConfigValues[CFG_NAPALM_NADE_DAMAGE]), DMG_BURN, 1);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, originF[0]+random_float(-5.0, 5.0))
	engfunc(EngFunc_WriteCoord, originF[1]+random_float(-5.0, 5.0))
	engfunc(EngFunc_WriteCoord, originF[2]+random_float(-10.0, 10.0))
	write_short(g_SpriteFlame)
	write_byte(random_num(5, 10))
	write_byte(200)
	message_end()
	
	args[0] --;

	set_task(0.2, "burning_flame", iEnt + TASK_GRENADE_NAPALM, args, sizeof args)
}

CreateGrenadeBlast(const Float:originF[3], type = GRENADE_NAPALM)
{
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
	
	if(type == GRENADE_NAPALM)
	{
		write_byte(200) // red
		write_byte(100) // green
		write_byte(0) // blue
	}
	else if(type == GRENADE_FROZEN)
	{
		write_byte(100) // green
		write_byte(255) // blue
		write_byte(200) // brightness
	}
	else
	{
		write_byte(50) // green
		write_byte(255) // blue
		write_byte(100) // brightness
	}
	
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
	
	if(type == GRENADE_NAPALM)
	{
		write_byte(200) // red
		write_byte(50) // green
		write_byte(0) // blue
	}
	else if(type == GRENADE_FROZEN)
	{
		write_byte(0) // red
		write_byte(50) // green
		write_byte(255) // blue
	}
	else if(type == GRENADE_STOP)
	{
		write_byte(100) // red
		write_byte(255) // green
		write_byte(25) // blue
	}
	
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
	
	if(type == GRENADE_NAPALM)
	{
		write_byte(200) // red
		write_byte(0) // green
		write_byte(0) // blue
	}
	else if(type == GRENADE_FROZEN)
	{
		write_byte(0) // red
		write_byte(0) // green
		write_byte(255) // blue
	}
	else if(type == GRENADE_STOP)
	{
		write_byte(0) // red
		write_byte(255) // green
		write_byte(0) // blue
	}
	
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(27); // TE_DLIGHT
	write_coord(floatround(originF[0])); // x
	write_coord(floatround(originF[1])); // y
	write_coord(floatround(originF[2])); // z
	write_byte(308); // radius
	
	if(type == GRENADE_NAPALM)
	{
		write_byte(255);	// r
		write_byte(50); // g
		write_byte(0); // b
	}
	else if(type == GRENADE_FROZEN)
	{
		write_byte(0);	// r
		write_byte(50); // g
		write_byte(255); // b
	}
	else
	{
		write_byte(0);	// r
		write_byte(255); // g
		write_byte(50); // b	
	}
	
	write_byte(8); // life
	write_byte(90); // decay rate
	message_end();
}

public GetPlayersNumInZone()
{
	new num = 0;
	for(new i = 0 ; i <= g_MaxPlayers ; i++)
		if(g_IsPlayerInStartZone[i])
			num++
	
	return num;
}

//thanks to Miczu
stock CreateBox(ent, startzone = 1)
{
	new Float:maxs[3], Float:mins[3];
	pev(ent, pev_absmax, maxs);
	pev(ent, pev_absmin, mins);
	
	new Float:fOrigin[3];
	pev(ent, pev_origin, fOrigin);
	
	new Float:fOff = -5.0;
	new Float:z;
	new num = startzone ? 4 : 2
	for(new i=0;i < num; i++)
	{
		z = fOrigin[2]+fOff;
		DrawLine(maxs[0], maxs[1], z, mins[0], maxs[1], z, startzone );
		DrawLine(maxs[0], maxs[1], z, maxs[0], mins[1], z, startzone );
		DrawLine(maxs[0], mins[1], z, mins[0], mins[1], z, startzone );
		DrawLine(mins[0], mins[1], z, mins[0], maxs[1], z, startzone );
		fOff += 5.0;
	}
}

public DrawLine(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2, startzone ) {
	new Float:start[3], Float:stop[3];
	start[0] = x1;
	start[1] = y1;
	start[2] = z1 - 20.0;
	
	stop[0] = x2;
	stop[1] = y2;
	stop[2] = z2 - 20.0;
	
	if(startzone )
		Create_Line(start, stop, {0,255,0}, 1);
	else
		Create_Line(start, stop, {255,50,0}, 0);
}

stock Create_Line(const Float:start[], const Float:stop[], iColor[3], startzone)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, start[0])
	engfunc(EngFunc_WriteCoord, start[1])
	engfunc(EngFunc_WriteCoord, start[2])
	engfunc(EngFunc_WriteCoord, stop[0])
	engfunc(EngFunc_WriteCoord, stop[1])
	engfunc(EngFunc_WriteCoord, stop[2])
	write_short(g_SpriteWhiteLine)
	write_byte(1)
	write_byte(5)
	
	if(startzone || g_IsAdminInStartZoneMenu)
		write_byte(20)
	else 
		write_byte(100);
	write_byte(20)
	write_byte(0)
	write_byte(iColor[0])	// RED
	write_byte(iColor[1])	// GREEN
	write_byte(iColor[2])	// BLUE					
	write_byte(250)	// brightness
	write_byte(5)
	message_end()
}

stock CreateFog(const index = 0, const red = 127, const green = 127, const blue = 127, const Float:density_f = 0.001, bool:clear = false)
{
	static msgFog;
	if ( msgFog || ( msgFog = get_user_msgid( "Fog" ) ) )
	{
		new density = _:floatclamp( density_f, 0.0001, 0.25 ) * _:!clear;
		
		message_begin( index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgFog, .player = index );
		write_byte( clamp( red  , 0, 255 ) );
		write_byte( clamp( green, 0, 255 ) );
		write_byte( clamp( blue , 0, 255 ) );
		write_long( _:density );
		message_end();
	}
}

stock fm_set_user_bpammo(id, weaponid, amnt) 
{ 
	static offset; 
	switch(weaponid) 
	{ 
		case CSW_AWP: offset = 377; 
		case CSW_SCOUT,CSW_AK47,CSW_G3SG1: offset = 378; 
		case CSW_M249: offset = 379;         
		case CSW_FAMAS,CSW_M4A1,CSW_AUG,CSW_SG550,CSW_GALI,CSW_SG552: offset = 380; 
		case CSW_M3,CSW_XM1014: offset = 381; 
		case CSW_USP,CSW_UMP45,CSW_MAC10: offset = 382; 
		case CSW_FIVESEVEN,CSW_P90: offset = 383; 
		case CSW_DEAGLE: offset = 384; 
		case CSW_P228: offset = 385; 
		case CSW_GLOCK18,CSW_MP5NAVY,CSW_TMP,CSW_ELITE: offset = 386; 
		case CSW_FLASHBANG: offset = 387; 
		case CSW_HEGRENADE: offset = 388; 
		case CSW_SMOKEGRENADE: offset = 389; 
		default: return 0; 
	} 
	set_pdata_int(id,offset,amnt,5); 
	
	return 1; 
} 
public GiveUserWeapons(id, szFlags[]) {
	if(!strlen(szFlags))
		return;
		
	if(containi(szFlags, "a") != -1) {
		fm_give_item(id, "weapon_deagle")
		fm_set_user_bpammo(id, CSW_DEAGLE, 35)
	} if(containi(szFlags, "b") != -1) {
		fm_give_item(id, "weapon_elite") 
		fm_set_user_bpammo(id, CSW_ELITE, 120)
	} if(containi(szFlags, "c") != -1) {
		fm_give_item(id, "weapon_mp5navy") 
		fm_set_user_bpammo(id, CSW_MP5NAVY, 120)
	} if(containi(szFlags, "d") != -1) {
		fm_give_item(id, "weapon_p90")
		fm_set_user_bpammo(id, CSW_P90, 100)
	} if(containi(szFlags, "e") != -1) {
		fm_give_item(id, "weapon_galil") 
		fm_set_user_bpammo(id, CSW_GALIL, 90)	
	} if(containi(szFlags, "f") != -1) {
		fm_give_item(id, "weapon_ak47") 
		fm_set_user_bpammo(id, CSW_AK47, 90)	
	} if(containi(szFlags, "g") != -1) {
		fm_give_item(id, "weapon_m4a1")
		fm_set_user_bpammo(id, CSW_M4A1, 90)
	} if(containi(szFlags, "h") != -1) {
		fm_give_item(id, "weapon_aug")
		fm_set_user_bpammo(id, CSW_AUG, 90) 	
	} if(containi(szFlags, "i") != -1) {
		fm_give_item(id, "weapon_m249") 
		fm_set_user_bpammo(id, CSW_M249, 200)	
	} if(containi(szFlags, "j") != -1) {
		fm_give_item(id, "weapon_sg552")
		fm_set_user_bpammo(id, CSW_SG552, 90) 	
	} if(containi(szFlags, "k") != -1) {
		fm_give_item(id, "weapon_awp")
		fm_set_user_bpammo(id, CSW_AWP, 30)
	} if(containi(szFlags, "l") != -1) {
		fm_give_item(id, "weapon_g3sg1")
		fm_set_user_bpammo(id, CSW_G3SG1, 90) 	
	} if(containi(szFlags, "m") != -1) {
		fm_give_item(id, "weapon_sg550") 	
		fm_set_user_bpammo(id, CSW_SG550, 90)
	}
}

public _td_remove_monsters()
	RemoveAllMonsters();
	
public _td_kill_monster(iEnt, iPlayer)
	 MonsterKilled(iEnt, iPlayer);

public _td_get_chat_prefix(szOutpout[], len)
{
	param_convert(1)
	copy(szOutpout, len, CHAT_PREFIX)
}

public _td_get_log_file_name(szOutpout[], len)
{
	param_convert(1)
	copy(szOutpout, len, LOG_FILE)
}

public _td_get_end_origin(Float:outOrigin[3])
{
	new Float:fEndOrigin[3];
	new iEnd = find_ent_by_tname(-1, "end");

	if(!is_valid_ent(iEnd))
		return 0;

	pev(iEnd, pev_origin, fEndOrigin);
	
	set_array_f(1, fEndOrigin, 3)

	return 1;
}

public _td_get_start_origin(Float:outOrigin[3])
{
	new Float:fStartOrigin[3];
	new iStart = find_ent_by_tname(-1, "start");

	if(!is_valid_ent(iStart))
		return 0;

	pev(iStart, pev_origin, fStartOrigin);
	
	set_array_f(1, fStartOrigin, 3)

	return 1;
}

public _td_is_game_possible()
	return g_IsGamePossible;

public _td_get_max_map_turrets()
	return MAX_TURRETS_ON_MAP;

public _td_are_turrets_enabled()
	return g_AreTurretsEnabled;
	
public _td_get_monster_speed(iEnt) 
	return entity_get_int(iEnt, EV_INT_monster_speed)

public _set_monster_speed(ent, speed, defaultspeed, now) 
{
	if(entity_get_int(ent, EV_INT_monster_type) == ROUND_NONE)
		return
	new changedSpeed  =  defaultspeed ? entity_get_int(ent, EV_INT_monster_maxspeed) : speed;
	
	if(changedSpeed < 0)
		changedSpeed = 0;
		
	entity_set_int(ent, EV_INT_monster_speed,changedSpeed)
	
	if(now) 
	{
		new iTrack = entity_get_int(ent, EV_INT_monster_track), szFormat[33], Float:Velocity[3]
		formatex(szFormat, charsmax(szFormat), "track%d",iTrack)
		
		new iTarget = find_ent_by_tname(-1, szFormat)
		
		if(!is_valid_ent(iTarget))
			iTarget = find_ent_by_tname(-1, "end")
		
		entity_set_aim(ent, iTarget, Float:{0.0, 0.0, 0.0}, 0);
		
		velocity_by_aim(ent, changedSpeed, Velocity)
		entity_set_vector(ent, EV_VEC_velocity, Velocity)
		
		if(changedSpeed <= 0)
		{
			entity_set_int(ent, EV_INT_sequence, 1);
			entity_set_float(ent, EV_FL_framerate, 1.0)
		}
		else
		{
			new Float:fSpeed = float(changedSpeed)
			fSpeed /= 240.0	
		
			entity_set_int(ent, EV_INT_sequence, 4);
			entity_set_float(ent, EV_FL_framerate, fSpeed)
		}	
	}
		
}

public _td_get_monster_healthbar(ent)
	return entity_get_edict(ent, EV_ENT_monster_healthbar);
	
public _td_get_monster_health(ent)
	return floatround(entity_get_float(ent, EV_FL_health));
	
public _td_get_monster_type(ent)
	return entity_get_int(ent, EV_INT_monster_type);
	
public _td_set_actual_wave(iWave)
{
	if(iWave < 0 || iWave > g_WavesNum)
		return 0;
	
	g_ActualWave = iWave;

	return 1;
}
	
public _td_get_actual_wave()
	return g_ActualWave;
	
public _td_get_max_player_level()
	return MAX_LEVEL;
	
public _td_get_max_monsters_num()
	return MAX_MONSTERS_PER_WAVE;
	
public _td_get_max_wave()
	return g_WavesNum;

public _td_is_wave_started()
	return g_SentMonstersNum > 0 ? 1 : 0;

public _td_is_tower_model_on_map()
	return g_IsTowerModelOnMap;

public _td_get_user_hud_size(id)
	return g_PlayerHudSize[id];
	
public IsPremiumMonster(ent)
	return entity_get_edict(ent, EV_ENT_monster_premium);
	
public _td_remove_tower()
{
	if(!g_IsTowerModelOnMap)
		return 0;
		
	new iEnt = find_ent_by_class(-1, "tower");

	if(is_valid_ent(iEnt))
	{
		g_IsTowerModelOnMap = false;
		remove_entity(iEnt);
		return 1;
	}
	return 0;
}

public _td_get_end_status()
	return g_IsGameEnded;

public _td_is_user_vip(iPlayer)
	return g_IsPlayerVip[iPlayer];
	
stock Float:power_float(Float:value, which)
{
	if(which == 0)
		return 1.0;
	if(which == 1)
		return value;
		
	new Float:tmp = value;
	for(new i ; i < which ; i++)
		value *= tmp;
	
	return value;
}
