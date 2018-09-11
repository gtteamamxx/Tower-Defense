#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <ColorChat>
#include <nvault>
#include <td>

#pragma dynamic 32768 

#define PLUGIN "Tower Defense Mod: Turrets"
#define VERSION "1.1 Rebuild"
#define AUTHOR "tomcionek15 & grs4"

#define TURRETS_CONFIG_PATH		"addons/amxmodx/configs/Tower Defense/Turrets/"
#define CONFIG_FILE			"addons/amxmodx/configs/td_turrets_config.cfg"
#define SOUND_CONFIG_FILE		"addons/amxmodx/configs/td_turrets_sounds.cfg"
#define TURRETS_DEFAULT_CONFIG_FILE	"td_turrets_default.cfg"
#define NVAULT_FILE_NAME		"TowerDefefnseTurrets"

#define MAX_PLAYER_TURRETS		3
#define TURRETS_MODELS_LEVEL		5
#define MAX_TURRETS_LEVEL		10

#define EV_INT_turret_index 		EV_INT_iuser1
#define EV_INT_turret_type 			EV_INT_iuser2
#define EV_INT_turret_canshoot 		EV_INT_iuser3
#define EV_INT_turret_target		EV_INT_iuser4
#define EV_INT_place_owner			EV_INT_iuser1
#define EV_INT_turret_ammo			EV_INT_team
#define EV_INT_turret_level			EV_INT_flSwimTime
#define EV_INT_turret_move_entity	EV_INT_flTimeStepSound
#define EV_ENT_ranger_owner			EV_ENT_owner

#define EV_ENT_turret_owner 		EV_ENT_owner
#define EV_ENT_turret_ranger		EV_ENT_euser4

#define EV_SZ_turret_name			EV_SZ_targetname
#define EV_VEC_turret_old_origin	EV_VEC_vuser1

#define EV_INT_totem_time			EV_INT_iuser1
#define EV_INT_totem_type			EV_INT_iuser2
#define EV_ENT_turret_totem_bit 	EV_ENT_euser3
#define EV_ENT_totem_owner			EV_ENT_owner

#define EV_INT_rocket_turretent		EV_INT_iuser3

#define TASK_CREATE_TURRET		4000
#define TASK_RELOAD_TURRET		4500
#define TASK_MOVE_TURRET		5000
#define TASK_CHECK_IS_IN_RANGE	5500
#define TASK_UPGRADE_TURRET		6000
#define TASK_OPEN_TURRET_MENU	6500

/* Configs */
new bool:DEBUG_T;
new bool:g_AreTurretsEnabled;

new LOG_FILE[25];
new CHAT_PREFIX[8];

new MAX_SERVER_TURRETS;
new MAX_MAP_TURRETS;

/* Sprites */
new g_SpriteLaserBeam;
new g_SpriteShell;
new g_SpriteRocketSmoke;
new g_SpriteExplosion;
new g_SpriteWhite;

/* Main data */

new g_ServerTurretsNum;
new g_TurretsFreqData[ENUM_TURRETS_TYPE]
new g_TurretsPriceData[ENUM_TURRETS_TYPE][MAX_TURRETS_LEVEL]
new g_TurretsDamageData[ENUM_TURRETS_TYPE][MAX_TURRETS_LEVEL][2]
new g_TurretsRangeData[ENUM_TURRETS_TYPE][MAX_TURRETS_LEVEL]
new g_TurretsAccuracyData[ENUM_TURRETS_TYPE][MAX_TURRETS_LEVEL]
new g_TurretsFireRateData[ENUM_TURRETS_TYPE][MAX_TURRETS_LEVEL]
new g_TurretsMaxLevelData[ENUM_TURRETS_TYPE][4] 

enum ENUM_SOUNDS 
{
	SOUND_TURRET_BULLET_FIRE_1,
	SOUND_TURRET_BULLET_FIRE_2,
	SOUND_TURRET_LASER_FIRE_1,
	SOUND_TURRET_LASER_FIRE_2,
	SOUND_TURRET_LIGHTING_FIRE_1,
	SOUND_TURRET_LIGHTING_FIRE_2,
	SOUND_TURRET_M_LASER_FIRE_1,
	SOUND_TURRET_M_LASER_FIRE_2,
	SOUND_TURRET_ROCKET_FIRE_1,
	SOUND_TURRET_ROCKET_FIRE_2,
	SOUND_TURRET_GATLING_FIRE_1,
	SOUND_TURRET_GATLING_FIRE_2,
	SOUND_TURRET_START_FIRE,
	SOUND_TURRET_STOP_FIRE,
	SOUND_TURRET_PLANT,
	SOUND_TURRET_LOWAMMO,
	SOUND_TURRET_NOAMMO,
	SOUND_TURRET_READY,
	SOUND_MENU_SELECT,
	SOUND_TURRET_LEVELUP
}

enum ENUM_CONFIG
{
	CFG_TURRET_INSTALL_TIME,
	CFG_CHANGE_ENEMY_TIME,
	CFG_TURRET_BULLET_AMMO_NUM,
	CFG_TURRET_BULLET_AMMO_COST,
	CFG_TURRET_LASER_AMMO_NUM,
	CFG_TURRET_LASER_AMMO_COST,
	CFG_TURRET_LIGHTING_AMMO_NUM,
	CFG_TURRET_LIGHTING_AMMO_COST,
	CFG_TURRET_M_LASER_AMMO_NUM,
	CFG_TURRET_M_LASER_AMMO_COST,
	CFG_TURRET_ROCKET_AMMO_COST,
	CFG_TURRET_ROCKET_AMMO_NUM,
	CFG_TURRET_GATLING_AMMO_COST,
	CFG_TURRET_GATLING_AMMO_NUM,
	CFG_TURRET_MOVE_COST,
	CFG_TURRET_RELOAD_TIME,
	CFG_TURRET_CHANGE_NAME_COST,
	CFG_TURRET_REMOVE_CHARGE_BACK,
	CFG_TURRET_CHARGE_BACK_MLTP,
	CFG_TURRET_MOVE_INSTALL_TIME,
	CFG_TURRET_SHOW_DEATH_MSG,
	CFG_TURRET_UPGRADE_TIME,
	CFG_TURRET_SERVER_MAX
}

enum ENUM_CONFIG_FLOAT
{
	Float:CFG_FLOAT_TURRET_INSTALL_TIME,
	Float:CFG_FLOAT_CHANGE_ENEMY_TIME,
	Float:CFG_FLOAT_TURRET_RELOAD_TIME,
	Float:CFG_FLOAT_CHARGE_BACK_MLTP,
	Float:CFG_FLOAT_MOVE_INSTALL_TIME,
	Float:CFG_FLOAT_TURRET_UPGRADE_TIME
}

new const g_TurretsName[ENUM_TURRETS_TYPE][] = 
{
	"None",
	"BULLET",
	"LASER",
	"LIGHTING",
	"MULTI LASER",
	"ROCKET",
	"GATLING"
}

new const g_TurretsShopName[MAX_PLAYER_TURRETS][] = {
	"Sentry 1",
	"Sentry 2",
	"Sentry 3"
}

new g_TurretSlotCost[MAX_PLAYER_TURRETS] = 
{
	35,
	80,
	140
}

new g_PlayerTurretShowingOption[33];

new g_TurretsLevelColor[TURRETS_MODELS_LEVEL][3] = 
{
	{255, 255, 255},
	{0, 255, 0},
	{255, 255, 0},
	{255, 0, 0},
	{0, 0, 255}
}

new g_ConfigValues[ENUM_CONFIG];
new Float:g_ConfigValuesFloat[ENUM_CONFIG_FLOAT];

new g_SoundFile[ENUM_SOUNDS][128];

/* Players information */
new bool:g_PlayerBoughtSlot[33][MAX_PLAYER_TURRETS]
new bool:g_PlayerAlarmStatus[33][MAX_PLAYER_TURRETS]
new bool:g_IsTurretUpgrading[33][MAX_PLAYER_TURRETS]

new g_PlayerTurretEnt[33][MAX_PLAYER_TURRETS]
new g_PlayerTurretDamageLevel[33][MAX_PLAYER_TURRETS]
new g_PlayerTurretRangeLevel[33][MAX_PLAYER_TURRETS]
new g_PlayerTurretAccuracyLevel[33][MAX_PLAYER_TURRETS]
new g_PlayerTurretFireRateLevel[33][MAX_PLAYER_TURRETS]
new g_PlayerTurretsNum[33];
new g_PlayerMovingTurretEntity[33];
new g_PlayerAmmoAlarmValue[33];
new g_PlayerTouchingTurret[33];

new Float:g_PlayerExtraTaskTime[33];

new g_PlayerTotems[33];

public plugin_natives()
{
	register_native("ShowTurretsMenu", "ShowUserTurretsMenu", 1);
	register_native("ShowTurretsSettingsMenu", "ShowUserSettingsMenu", 1);
	register_native("td_turrets_get_player_totem", "_td_turrets_get_player_totem", 1);
	register_native("td_turrets_set_player_totem", "_td_turrets_set_player_totem", 1);
}
public plugin_precache()
{
	log_to_file(LOG_FILE, "Loading configuration...");
	LoadConfiguration();
	
	if(DEBUG_T)
	{
		log_to_file(LOG_FILE, "DEBUG_T: Precaching resources started");
		log_to_file(LOG_FILE, "DEBUG_T: Precaching sounds");
	}

	new szFile[64];
	for(new i; i < _:ENUM_SOUNDS ; i++)
	{
		formatex(szFile, charsmax(szFile), "sound/%s", g_SoundFile[ENUM_SOUNDS:i]);
		
		if(file_exists(szFile))
			precache_sound(g_SoundFile[ENUM_SOUNDS:i]);
		else if(DEBUG_T)
			log_to_file(LOG_FILE, "DEBUG_T: '%s' is not exist! id=%d", szFile, i);
	}

	if(file_exists("models/rshell_big.mdl"))
		g_SpriteShell 		= precache_model("models/rshell_big.mdl")
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'models/rshell_big.mdl' is not exist!");

	if(file_exists("sprites/TD/laserbeam.spr"))
		g_SpriteLaserBeam 	= precache_model("sprites/TD/laserbeam.spr")
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'sprites/TD/laserbeam.spr' is not exist!");

	if(file_exists("sprites/TD/zerogxplode.spr"))
		g_SpriteExplosion	= precache_model("sprites/TD/zerogxplode.spr")
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'sprites/TD/zerogxplode.spr' is not exist!");
		
	if(file_exists("sprites/white.spr"))
		g_SpriteWhite		= precache_model("sprites/white.spr");
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'sprites/white.spr' is not exist!");

	if(file_exists("sprites/TD/smoke.spr"))
		g_SpriteRocketSmoke= precache_model("sprites/TD/smoke.spr");
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'sprites/TD/smoke.spr' is not exists!");
		
	if(file_exists("sprites/TD/ranger.spr"))
		precache_model("sprites/TD/ranger.spr");
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'sprites/TD/ranger.spr' is not exist!");
		
	if(file_exists("models/TD/rocket.mdl"))
		precache_model("models/TD/rocket.mdl");
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'models/TD/rocket.mdl' is not exist!");
		
	if(file_exists("models/TD/sentrygun_1.mdl"))
		precache_model("models/TD/sentrygun_1.mdl")
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'models/TD/sentrygun_1.mdl' is not exist!");
		
	if(file_exists("models/TD/sentrygun_2.mdl"))
		precache_model("models/TD/sentrygun_2.mdl")
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'models/TD/sentrygun_2.mdl' is not exist!");
		
	if(file_exists("models/TD/sentrygun_3.mdl"))
		precache_model("models/TD/sentrygun_3.mdl")
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'models/TD/sentrygun_3.mdl' is not exist!");

	if(file_exists("models/TD/sentrygun_4.mdl"))
		precache_model("models/TD/sentrygun_4.mdl")
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'models/TD/sentrygun_4.mdl' is not exist!");
		
	if(file_exists("models/TD/sentrygun_5.mdl"))
		precache_model("models/TD/sentrygun_5.mdl")
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'models/TD/sentrygun_5.mdl' is not exist!");
	
	if(file_exists("models/TD/totem.mdl"))
		precache_model("models/TD/totem.mdl");
	else if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: 'models/TD/totem.mdl' is not exist!");

	if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: Precaching resources finished");	
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /turrets", 		"ShowUserTurretsMenu")
	register_clcmd("say /turret", 		"ShowUserTurretsMenu")
	register_clcmd("turret_change_name", 	"MessageModeTurretChangeName")

	//for totem
	register_clcmd("radio1",		"PlayerPlaceTotem");
	
	register_think("turret", 		"TurretThink")
	register_think("totem",			"TotemThink")
	register_think("turret_move",		"TurretMoveThink");
	register_touch("turret", 		"player", "TurretTouched");
	register_touch("turret_rocket", 	"worldspawn", 	"RocketHitSomething")
	register_touch("turret_rocket", 	"monster",	"RocketHitSomething");
	
	register_forward(FM_AddToFullPack,	"fwAddToFullPack", 1)
	register_forward(FM_CmdStart,		"CmdUse");
}

public _td_turrets_set_player_totem(id, value)
{
	g_PlayerTotems[id] = value;
	
	new totemName[20];
	switch(value)
	{
		case TOTEM_DAMAGE: formatex(totemName, charsmax(totemName), "DAMAGE");
		case TOTEM_RANGE: formatex(totemName, charsmax(totemName), "RANGE");
		case TOTEM_FIRERATE: formatex(totemName, charsmax(totemName), "FIRERATE");
		case TOTEM_ALL: formatex(totemName, charsmax(totemName), "SUPER");
	}

	client_print(id, print_center, "Press 'Z' in place where you want to place %s totem.", totemName);
}

public _td_turrets_get_player_totem(id)
	return g_PlayerTotems[id];

public PlayerPlaceTotem(id)
{
	new playerTotem = g_PlayerTotems[id];
	
	if(playerTotem <= TOTEMS && playerTotem != TOTEM_NONE && is_user_alive(id))
	{
		CreateTotem(id, g_PlayerTotems[id]);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public CreateTotem(id, totemType)
{
	if(totemType == TOTEM_NONE)
		return;

	new ent = g_PlayerTotems[id] = CreateTotemEnt(id);
	SetTotemAbilities(ent, totemType, id);
	emit_sound(id, CHAN_AUTO, g_SoundFile[SOUND_TURRET_PLANT], 1.0, 0.7, 0, PITCH_NORM);
}

SetTotemAbilities(ent, totemType, player)
{
	entity_set_int(ent, EV_INT_totem_type, totemType);
	entity_set_int(ent, EV_INT_totem_time, totemType == TOTEM_ALL ? 5 : 3);
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0);
	entity_set_edict(ent, EV_ENT_totem_owner, player);
	
	new red = totemType == TOTEM_DAMAGE ? 255 : totemType == TOTEM_ALL ? 255 : 0;
	new green = totemType == TOTEM_RANGE ? 255 : totemType == TOTEM_ALL ? 255 : 0;
	new blue = totemType == TOTEM_FIRERATE ? 255 : totemType == TOTEM_ALL ? 255 : 0;
	
	fm_set_rendering(ent, kRenderFxGlowShell, red, green, blue, kRenderNormal, 16);
}

CreateTotemEnt(id)
{
	new Float:fPlayerOrigin[3];
	entity_get_vector(id, EV_VEC_origin, fPlayerOrigin);

	new ent = create_entity("info_target");
	entity_set_origin(ent, fPlayerOrigin);
	drop_to_floor(ent);
	entity_set_model(ent, "models/TD/totem.mdl");
	entity_set_string(ent, EV_SZ_classname, "totem");
	return ent;
}

public TurretMoveThink(ent)
{
	if(!is_valid_ent(ent))
		return;
	
	static entlist[15];
	new num = find_sphere_class(ent, "totem", 500.0, entlist, 14);
	
	if(num > 0)
	{
		new totemEnt;
		for(new i = 0; i < num ; i++)
		{
			totemEnt = entlist[i];
			if(!is_valid_ent(totemEnt))
				continue;
			entlist[0] = ent;
			CreateFromTotemToTurretLineEffect(totemEnt, entlist, 1, entity_get_int(totemEnt, EV_INT_totem_type), 9);
		}
	}
	
	entity_set_float(ent, EV_FL_nextthink, get_gametime() +  1.0);
}
public TotemThink(ent)
{
	if(!is_valid_ent(ent))
		return;
	
	static entlist[15];
	new num = find_sphere_class(ent, "turret", 500.0, entlist, 14);
	ResetTotemEffectForTurrets(ent);
	if(num > 0)
	{
		static iTotemType; iTotemType = entity_get_int(ent, EV_INT_totem_type);
		CreateFromTotemToTurretLineEffect(ent, entlist, num, iTotemType, 49);
		SetTurretInTotemRangeAbilities(ent, entlist, num)
	}
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 5.0);
}

public ResetTotemEffectForTurrets(totemEnt)
{
	new maskRemove = (1 << entity_get_edict(totemEnt, EV_ENT_totem_owner));
	for(new i = 1; i < 33; i++)
	{
		if(!is_user_connected(i))
			continue;
		
		for(new j = 0; j < MAX_PLAYER_TURRETS; j++)
		{
			if(!g_PlayerBoughtSlot[i][j])
				continue;
			
			static ent; ent = g_PlayerTurretEnt[i][j];
			if(!is_valid_ent(ent))
				continue;

			static turretBit; turretBit = entity_get_edict(ent, EV_ENT_turret_totem_bit);

			turretBit &= ~(maskRemove);
			entity_set_edict(ent, EV_ENT_turret_totem_bit, turretBit);
		}
	}
}
public CreateFromTotemToTurretLineEffect(totemEnt, turretEnts[], len, totemType, duration)
{
	for(new i = 0; i < len; i++)
	{
		message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
		write_byte(TE_BEAMENTS)
		write_short(totemEnt)	// start entity
		write_short(turretEnts[i])  // end entity
		write_short(g_SpriteLaserBeam)	// sprite index
		write_byte(0)	// starting frame
		write_byte(0)	// frame rate in 0.1's
		write_byte(duration)	// life in 0.1's
		write_byte(20)	// line width in 0.1's
		write_byte(1)	// noise amplitude in 0.01's
		write_byte(totemType == TOTEM_DAMAGE ? 255 : totemType == TOTEM_ALL ? 255 : 0) // r 
		write_byte(totemType == TOTEM_RANGE ? 255 : totemType == TOTEM_ALL ? 255 : 0) // g
		write_byte(totemType == TOTEM_FIRERATE ? 255 : totemType == TOTEM_ALL ? 255 : 0) // b
		write_byte(90)	// brightness
		write_byte(10)	// scroll speed in 0.1's
		message_end()
	}
}
public SetTurretInTotemRangeAbilities(totemEnt, turretEnts[], len)
{
	new turretEnt;
	for(new i = 0; i < len; i++)
	{
		turretEnt = turretEnts[i];
		
		if(!is_valid_ent(turretEnt))
			continue;
		
		static bit, allBit;
		bit = (1 << entity_get_edict(totemEnt, EV_ENT_totem_owner));
		allBit = entity_get_edict(turretEnt, EV_ENT_turret_totem_bit);
		if(!(bit & allBit))
			entity_set_edict(turretEnt, EV_ENT_turret_totem_bit, allBit | bit);
	}
}
public RocketHitSomething(iRocket, ent)
{
	new Float:fEndOrigin[3], iEndOrigin[3], iMonsters[10], iRocketOwner = entity_get_edict(iRocket, EV_ENT_owner),
		iTurretIndex = entity_get_int(iRocket, EV_INT_turret_index), iTurretType = entity_get_int(iRocket, EV_INT_turret_type);
		
	entity_get_vector(iRocket, EV_VEC_origin, fEndOrigin);
	FVecIVec(fEndOrigin, iEndOrigin);

	new iTurretDamagelevel = g_PlayerTurretDamageLevel[iRocketOwner][iTurretIndex];
	new Float:dmg = random_float(float(g_TurretsDamageData[iTurretType][iTurretDamagelevel][0]), float(g_TurretsDamageData[iTurretType][iTurretDamagelevel][1]))

	new turretEnt = entity_get_int(iRocket, EV_INT_rocket_turretent);
	if(is_valid_ent(turretEnt))
	{
		new totemAbilities[3];
		GetTurretAbilitiesFromTotem(turretEnt, totemAbilities);
		dmg *= (1.0 + (totemAbilities[0] / 100.0));
	}
	
	static iShowDeathMsg;
	if(iShowDeathMsg == 0) 
	{
		iShowDeathMsg = g_ConfigValues[CFG_TURRET_SHOW_DEATH_MSG] ;
		if(iShowDeathMsg == 0)
			iShowDeathMsg = -1
	}

	new iMonster = 0;	
	for(new i, num = find_sphere_class(iRocket, "monster", 500.0, iMonsters, sizeof iMonsters); i < num; i++)
	{
		iMonster = iMonsters[i];
		if(iMonster == 0)
			break;

		if(iShowDeathMsg && entity_get_float(iMonster, EV_FL_health) - dmg <= 0.0)
			makeDeathMsg(iRocketOwner);
		
		ExecuteHamB(Ham_TakeDamage, iMonster, iRocketOwner, iRocketOwner, dmg, DMG_DROWN, 1);
	}

	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(iEndOrigin[0])
	write_coord(iEndOrigin[1])
	write_coord(iEndOrigin[2] + 10)
	write_short(g_SpriteExplosion)
	write_byte(50)
	write_byte(40)
	write_byte(0)
	message_end()

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(21)
	write_coord(iEndOrigin[0])
	write_coord(iEndOrigin[1])
	write_coord(iEndOrigin[2] + 5)
	write_coord(iEndOrigin[0])
	write_coord(iEndOrigin[1])
	write_coord(iEndOrigin[2] + 370)
	write_short(g_SpriteWhite)
	write_byte(0)
	write_byte(0)
	write_byte(5)
	write_byte(32)
	write_byte(0)
	write_byte(255)
	write_byte(255)
	write_byte(192)
	write_byte(128)
	write_byte(0)
	message_end()

	remove_entity(iRocket);
}

public client_authorized(id)
{
	LoadUserConfig(id)
}

public LoadUserConfig(id)
{
	new iFile;
	if((iFile = nvault_open(NVAULT_FILE_NAME)) == INVALID_HANDLE)
		return;
	
	new szKey[48];
	new szData[128];
	
	get_user_authid(id, szKey, 32)
	get_user_name(id, szKey, 32);
	
	formatex(szKey, charsmax(szKey), "%s-turrets#", szKey);

	if(nvault_get(iFile, szKey, szData, charsmax(szData)))
	{
		new szTempInfo[2][8];
		explode(szData, '|', szTempInfo, 2, 7);
	
		g_PlayerTurretShowingOption[id]	= str_to_num( szTempInfo[0] );
		g_PlayerAmmoAlarmValue[id]	= str_to_num( szTempInfo[1] );
	}
	
	nvault_close(iFile);
}

stock explode(const string[], const character,output[][], const maxs, const maxlen){
	new iDo = 0, len = strlen(string), oLen = 0;
	do { 
		oLen += (1 + copyc(output[iDo++], maxlen, string[oLen], character)) 
	} while(oLen < len && iDo < maxs);
}

public td_wave_ended(iWave)
{
	SavePlayersConfig();
	RemoveTotemsEffectAndEntities();
}

public RemoveTotemsEffectAndEntities()
{
	new ent = find_ent_by_class(-1, "totem")

	while(is_valid_ent(ent))
	{
		ResetTotemEffectForTurrets(ent);
		
		new waveLeft = entity_get_int(ent, EV_INT_totem_time);
		waveLeft--;
		entity_set_int(ent, EV_INT_totem_time, waveLeft);
			
		if(waveLeft == 0)
		{
			g_PlayerTotems[entity_get_edict(ent, EV_ENT_totem_owner)] = TOTEM_NONE;
			remove_entity(ent)
		}
		ent = find_ent_by_class(ent, "totem")
	}
}
public SavePlayersConfig()
{
	new iFile = nvault_open(NVAULT_FILE_NAME);
	for(new i = 1 ; i < 33; i++)
		if(is_user_alive(i)) 
			SaveUserConfig(i, iFile);
		
	nvault_close(iFile);
}
public SaveUserConfig(id, iFile)
{
	new szKey[48];
	new szData[128];
	
	get_user_authid(id, szKey, 32)
	get_user_name(id, szKey, 32);
	
	formatex(szKey, charsmax(szKey), "%s-turrets#", szKey);
	formatex(szData, charsmax(szData), "%d|%d", g_PlayerTurretShowingOption[id], g_PlayerAmmoAlarmValue[id])
	
	nvault_set(iFile, szKey, szData);
}

public LoadConfiguration()
{
	log_to_file(LOG_FILE, "Loading configuration...");
	/* firstly get name of LOG FILE */
	td_get_log_file_name(LOG_FILE, charsmax(LOG_FILE));

	/* If td_DEBUG_T.amxx is included before main engines in plugins-td.ini, set DEBUG_T mode ON */
	if(is_plugin_loaded("td_debug.amxx", true) != -1)
	{
		DEBUG_T = true;
		
		log_to_file(LOG_FILE, "DEBUG_T: ===== Starting Debugging trace of Tower Defense Turrets =====");
		log_to_file(LOG_FILE, "");	
	}
	
	if(!td_is_game_possible())
	{
		set_fail_state("TURRETS: Plugin will not be working because td_engine will not work propertly[Returns IsGamePossible = false]");
		return PLUGIN_HANDLED_MAIN
	}
	
	if(DEBUG_T)
		log_to_file(LOG_FILE, "Loading configuration...");
	
	td_get_chat_prefix(CHAT_PREFIX, charsmax(CHAT_PREFIX));	

	LoadSounds();
	LoadDefaultValues();
	
	new szMapName[33]
	get_mapname(szMapName, 32)
	LoadTurretsConfig(szMapName)
	
	MAX_MAP_TURRETS = 20
	g_AreTurretsEnabled = bool:td_are_turrets_enabled();
	return PLUGIN_CONTINUE;
}

public LoadConfig()
{
	if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: Loading turrets plugin config from ^"%s^" file started.", CONFIG_FILE)
	
	if(!file_exists(CONFIG_FILE)) 
	{
		if(DEBUG_T)
		{
			log_to_file(LOG_FILE, "DEBUG_T TURRETS: Config file ^"%s^" is not exist", CONFIG_FILE)
			log_to_file(LOG_FILE, "DEBUG_T TURRETS: Loading default values")
		}

		/* Create default file */
		// ...
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

		if(DEBUG_T)
			log_to_file(LOG_FILE, "DEBUG_T TURRETS: Command '%s' | Set: '%s'", szData[0], szData[2]);
			
		if(equali(szData[0], "TURRET_BULLET_AMMO_NUM"))
			g_ConfigValues[CFG_TURRET_BULLET_AMMO_NUM] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "TURRET_BULLET_AMMO_COST"))
			g_ConfigValues[CFG_TURRET_BULLET_AMMO_COST] 	= str_to_num( szData[2] );

		else if(equali(szData[0], "TURRET_LASER_AMMO_NUM"))
			g_ConfigValues[CFG_TURRET_LASER_AMMO_NUM] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "TURRET_LASER_AMMO_COST"))
			g_ConfigValues[CFG_TURRET_LASER_AMMO_COST] 	= str_to_num( szData[2] );

		else if(equali(szData[0], "TURRET_LIGHTING_AMMO_NUM"))
			g_ConfigValues[CFG_TURRET_LIGHTING_AMMO_NUM] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "TURRET_LIGHTING_AMMO_COST"))
			g_ConfigValues[CFG_TURRET_LIGHTING_AMMO_COST] 	= str_to_num( szData[2] );

		else if(equali(szData[0], "TURRET_M_LASER_AMMO_NUM"))
			g_ConfigValues[CFG_TURRET_M_LASER_AMMO_NUM] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "TURRET_M_LASER_AMMO_COST"))
			g_ConfigValues[CFG_TURRET_M_LASER_AMMO_COST] 	= str_to_num( szData[2] );

		else if(equali(szData[0], "TURRET_ROCKET_AMMO_NUM"))
			g_ConfigValues[CFG_TURRET_ROCKET_AMMO_NUM] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "TURRET_ROCKET_AMMO_COST"))
			g_ConfigValues[CFG_TURRET_ROCKET_AMMO_COST] 	= str_to_num( szData[2] );

		else if(equali(szData[0], "TURRET_GATLING_AMMO_NUM"))
			g_ConfigValues[CFG_TURRET_GATLING_AMMO_NUM] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "TURRET_GATLING_AMMO_COST"))
			g_ConfigValues[CFG_TURRET_GATLING_AMMO_COST] 	= str_to_num( szData[2] );

		else if(equali(szData[0], "TURRET_MOVE_COST"))
			g_ConfigValues[CFG_TURRET_MOVE_COST] 		= str_to_num( szData[2] );
		else if(equali(szData[0], "TURRET_CHANGE_NAME_COST"))
			g_ConfigValues[CFG_TURRET_CHANGE_NAME_COST] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "TURRET_REMOVE_CHARGE_BACK"))
			g_ConfigValues[CFG_TURRET_REMOVE_CHARGE_BACK] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "TURRET_SHOW_DEATH_MSG"))
			g_ConfigValues[CFG_TURRET_SHOW_DEATH_MSG] 	= str_to_num( szData[2] );
		else if(equali(szData[0], "MAX_SERVER_TURRETS"))
			MAX_SERVER_TURRETS = str_to_num( szData[2] );
		else if(equali(szData[0], "TURRET_INSTALL_TIME"))
			g_ConfigValuesFloat[CFG_FLOAT_TURRET_INSTALL_TIME]= str_to_float( szData[2] );
		else if(equali(szData[0], "TURRET_CHANGE_ENEMY_TIME"))
			g_ConfigValuesFloat[CFG_FLOAT_CHANGE_ENEMY_TIME]= str_to_float( szData[2] );
		else if(equali(szData[0], "TURRET_RELOAD_TIME"))
			g_ConfigValuesFloat[CFG_FLOAT_TURRET_RELOAD_TIME]= str_to_float( szData[2] );
		else if(equali(szData[0], "TURRET_REMOVE_CHARGE_BACK_MLTP"))
			g_ConfigValuesFloat[CFG_FLOAT_CHARGE_BACK_MLTP]	= str_to_float( szData[2] );
		else if(equali(szData[0], "TURRET_MOVE_INSTALL_TIME"))
			g_ConfigValuesFloat[CFG_FLOAT_MOVE_INSTALL_TIME]= str_to_float( szData[2] );
		else if(equali(szData[0], "TURRET_UPGRADE_TIME"))
			g_ConfigValuesFloat[CFG_FLOAT_TURRET_UPGRADE_TIME]= str_to_float( szData[2] );

	}

	return PLUGIN_CONTINUE;
}
public LoadDefaultValues()
{
	g_ConfigValuesFloat[CFG_FLOAT_TURRET_INSTALL_TIME] 	= 8.0
	g_ConfigValuesFloat[CFG_FLOAT_CHANGE_ENEMY_TIME] 	= 0.6
	g_ConfigValuesFloat[CFG_FLOAT_TURRET_RELOAD_TIME] 	= 7.0
	g_ConfigValuesFloat[CFG_FLOAT_CHARGE_BACK_MLTP] 	= 0.25
	g_ConfigValuesFloat[CFG_FLOAT_MOVE_INSTALL_TIME] 	= 6.0
	g_ConfigValuesFloat[CFG_FLOAT_TURRET_UPGRADE_TIME] 	= 8.0
	
	g_ConfigValues[CFG_TURRET_BULLET_AMMO_NUM] 		= 150
	g_ConfigValues[CFG_TURRET_BULLET_AMMO_COST] 		= 30
	
	g_ConfigValues[CFG_TURRET_LASER_AMMO_NUM] 		= 80
	g_ConfigValues[CFG_TURRET_LASER_AMMO_COST] 		= 45
	
	g_ConfigValues[CFG_TURRET_LIGHTING_AMMO_NUM] 		= 250
	g_ConfigValues[CFG_TURRET_LIGHTING_AMMO_COST] 		= 55

	g_ConfigValues[CFG_TURRET_M_LASER_AMMO_NUM] 		= 35
	g_ConfigValues[CFG_TURRET_M_LASER_AMMO_COST] 		= 75

	g_ConfigValues[CFG_TURRET_ROCKET_AMMO_NUM] 		= 10
	g_ConfigValues[CFG_TURRET_ROCKET_AMMO_COST] 		= 100

	g_ConfigValues[CFG_TURRET_GATLING_AMMO_NUM] 		= 500
	g_ConfigValues[CFG_TURRET_GATLING_AMMO_COST] 		= 200
	
	g_ConfigValues[CFG_TURRET_MOVE_COST] 			= 20
	g_ConfigValues[CFG_TURRET_CHANGE_NAME_COST] 		= 10
	g_ConfigValues[CFG_TURRET_REMOVE_CHARGE_BACK] 		= 0
	g_ConfigValues[CFG_TURRET_SHOW_DEATH_MSG] 		= 1
	
	MAX_SERVER_TURRETS 					= 20;
}

public td_settings_refreshed()
	LoadConfig();

public td_game_ended()
{
	SavePlayersConfig();
}

public td_remove_data()
{
	new iEnt;
	
	for(new i = 1 ; i < 33 ; i++)
	{
		for(new j ; j < MAX_PLAYER_TURRETS ; j++)
		{
			/*if(is_valid_ent( g_PlayerTurretEnt[i][j] ))
			{
				entity_get_vector(g_PlayerTurretEnt[i][j], EV_VEC_origin, fOrigin);
				FVecIVec(fOrigin, iOrigin);
	
				MakeLavaSplashEffect(iOrigin);
				
				DestroyTurretRanger(g_PlayerTurretEnt[i][j])
				remove_entity( g_PlayerTurretEnt[i][j]  )
			}
			g_PlayerTurretEnt[i][j] = 0;*/
			iEnt = g_PlayerTurretEnt[i][j] ;
			if(is_valid_ent(iEnt))
				DeleteTurret(iEnt, i, j);
		}
	}
}

public IsEntityRanger(iEnt)
{
	static szClassName[16]; entity_get_string(iEnt, EV_SZ_classname, szClassName, 15);
	return equali(szClassName, "ranger");
}

public IsEntityPlayerTurret(iEnt, iPlayer) {
	return entity_get_edict(iEnt, EV_ENT_turret_owner) == iPlayer && entity_get_int(iEnt, EV_INT_turret_level)
}

public fwAddToFullPack(es_handle, e, ENT, HOST, hostflags, player, set) 
{
	if(player || !is_user_connected(HOST) || !is_valid_ent(ENT))
		return FMRES_IGNORED

	/* If ranger owner is other than player -> hide him */
	if(IsEntityRanger(ENT) && entity_get_edict(ENT, EV_ENT_ranger_owner) != HOST) 
	{
		set_es( es_handle, ES_RenderMode, kRenderTransAdd ) 
		set_es( es_handle, ES_RenderAmt, 0);  
		return FMRES_OVERRIDE
	}

	static iEffectType ; iEffectType = g_PlayerTurretShowingOption[HOST]
	if(iEffectType != TURRET_SHOW_NONE && IsEntityPlayerTurret(ENT, HOST))
	{
		if(iEffectType == TURRET_SHOW_TRANSPARENT)
		{
			set_es( es_handle, ES_RenderMode, kRenderTransAdd ) 
			set_es( es_handle, ES_RenderAmt, 255);
		}
		else if(!g_PlayerMovingTurretEntity[HOST])
		{
			set_es(es_handle, ES_RenderMode, kRenderNormal)
			set_es(es_handle, ES_RenderAmt, 16)
			set_es(es_handle, ES_RenderColor, g_TurretsLevelColor[ entity_get_int(ENT, EV_INT_turret_level) - 1])
			set_es(es_handle, ES_RenderFx, kRenderFxGlowShell)
		}
		return FMRES_OVERRIDE
	}	
	return FMRES_IGNORED
}			

public ShowUserSettingsMenu(id) 
{
	new iMenu = menu_create("Turrets settings:", "ShowUserSettingsMenuH")
	menu_additem(iMenu, "Change turrets alarm value")
	menu_additem(iMenu, "Change own turrets effect")
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	menu_display(id, iMenu);
}

public ShowUserSettingsMenuH(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		client_cmd(id, "ShowOptionsMenu")
		return PLUGIN_CONTINUE
	}

	switch(item) 
	{
		case 0: ShowEditAlarmValueMenu(id);
		case 1: ShowEditOwnTurretEffect(id);
	}
	return PLUGIN_CONTINUE
}

public ShowEditOwnTurretEffect(id)
{
	new iMenu = menu_create("\ySelect mode: ", "ShowEditOwnTurretEffectH");
	new iCb = menu_makecallback("ShowEditOwnTurretEffectCb");
	
	menu_additem(iMenu, "Turn off effects", _, _, iCb);
	menu_additem(iMenu, "Show glow", _, _, iCb);
	menu_additem(iMenu, "Show transparently", _, _, iCb);
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu)
}

public ShowEditOwnTurretEffectCb(id, menu, item)
	return item == g_PlayerTurretShowingOption[id] ? ITEM_DISABLED : ITEM_ENABLED;

public ShowEditOwnTurretEffectH(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		ShowUserSettingsMenu(id)
		return;
	}
	
	g_PlayerTurretShowingOption[id]  = item;
	ColorChat(id, GREEN, "%s^x01 You changed visibility of your turret effect.", CHAT_PREFIX);
	ShowEditOwnTurretEffect(id);
}
public ShowEditAlarmValueMenu(id) 
{
	static szTitle[64]
	
	formatex(szTitle, charsmax(szTitle), "\wSet alarm status at \y%d\w ammo", g_PlayerAmmoAlarmValue[id]);
	
	new iMenu = menu_create(szTitle, "ShowEditAlarmValueMenuH")
	new iCb = menu_makecallback("ShowEditAlarmValueMenuCb");
	
	menu_additem(iMenu, "10", _, _, iCb)
	menu_additem(iMenu, "25", _, _, iCb)
	menu_additem(iMenu, "50", _, _, iCb)
	menu_additem(iMenu, "75", _, _, iCb)
	menu_additem(iMenu, "100", _, _, iCb)
	menu_additem(iMenu, "150", _, _, iCb)
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	menu_display(id, iMenu);
}

public ShowEditAlarmValueMenuCb(id, menu, item) 
{
	new iAlarmValue = g_PlayerAmmoAlarmValue[id];

	if(item == 0 && iAlarmValue == 10)
		return ITEM_DISABLED;
	if(item == 1 && iAlarmValue == 25)
		return ITEM_DISABLED;
	if(item == 2 &&  iAlarmValue == 50)
		return ITEM_DISABLED;
	if(item == 3 && iAlarmValue == 75)
		return ITEM_DISABLED;
	if(item == 4 && iAlarmValue == 100)
		return ITEM_DISABLED;
	if(item == 5 && iAlarmValue == 150)
		return ITEM_DISABLED;
		
	return ITEM_ENABLED
}

public ShowEditAlarmValueMenuH(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		ShowUserSettingsMenu(id)
		return PLUGIN_CONTINUE
	}
	item++;
	
	switch(item) 
	{
		case 1: g_PlayerAmmoAlarmValue[id] = 10
		case 2: g_PlayerAmmoAlarmValue[id] = 25
		case 3: g_PlayerAmmoAlarmValue[id] = 50
		case 4: g_PlayerAmmoAlarmValue[id] = 75
		case 5: g_PlayerAmmoAlarmValue[id] = 100
		case 6: g_PlayerAmmoAlarmValue[id] = 150
	}
	
	ColorChat(id, GREEN, "%s^x01 You changed alarm status at %d ammo.", CHAT_PREFIX, g_PlayerAmmoAlarmValue[id]);
	
	ShowEditAlarmValueMenu(id);
	return PLUGIN_CONTINUE
}

public ShowUserTurretsMenu(id) 
{
	if(!is_user_alive(id))
		return
	
	if(!g_AreTurretsEnabled)
	{
		ColorChat(id, GREEN, "[TD TURRETS]^x01 Turrets are disabled from some reason.")
		return;
	}
	static szFormat[128], szAlarm[33];

	new iMaxTurretsNum = MAX_SERVER_TURRETS < MAX_MAP_TURRETS ? MAX_SERVER_TURRETS : MAX_MAP_TURRETS;
	
	formatex(szFormat, charsmax(szFormat), "\yServer turrets:\r %d\d /\r %d^n\yYour turrets:\r %d\d /\r %d^n\wSelect option:", g_ServerTurretsNum, iMaxTurretsNum, g_PlayerTurretsNum[id], MAX_PLAYER_TURRETS);

	static menu ; menu = menu_create(szFormat, "ShowUserTurretsMenuH")
	static cb; cb =  menu_makecallback("ShowUserTurretsMenuCb");
	
	static iGold; iGold = td_get_user_info(id, PLAYER_GOLD)
	
	for(new i ; i < MAX_PLAYER_TURRETS; i++) 
	{
		static isValidTurret; isValidTurret = is_valid_ent(g_PlayerTurretEnt[id][i]);
		static isSlotBought; isSlotBought = g_PlayerBoughtSlot[id][i]
		
		if(isSlotBought) 
		{
			if(!isValidTurret)
				formatex(szFormat, charsmax(szFormat), "Slot %d\r [\y BUY TURRET\r ]",  i+1)
			else
			{
				new szTurretName[33];
				new iEnt = g_PlayerTurretEnt[id][i];
				
				entity_get_string(iEnt, EV_SZ_targetname, szTurretName, 32);
				formatex(szFormat, charsmax(szFormat), "%s \r[ \y%d lvl\r ] [ \y%s\r ]", szTurretName, entity_get_int( iEnt, EV_INT_turret_level), g_TurretsName[ entity_get_int(iEnt, EV_INT_turret_type)])
			
				new iAmmo = entity_get_int( g_PlayerTurretEnt[id][i], EV_INT_turret_ammo);
			
				if(iAmmo < 1)
				{
					formatex(szAlarm, 32, "\r [\w NO AMMO\r ]")
					add(szFormat, 127, szAlarm)
				}
				
				else if(g_PlayerAlarmStatus[id][i]) 
				{
					formatex(szAlarm,32, "\r [\w LOW AMMO\r ]")
					add(szFormat, 127, szAlarm)
				}	
			}
		}
		else if(g_ServerTurretsNum >= iMaxTurretsNum)
		{
			if(g_ServerTurretsNum >= MAX_SERVER_TURRETS && !isValidTurret)
				formatex(szFormat, charsmax(szFormat), "Slot %d\r [ SERVER LIMIT REACHED ]", i+1)
			else if(g_ServerTurretsNum >= MAX_MAP_TURRETS && !isValidTurret)
				formatex(szFormat, charsmax(szFormat), "Slot %d\r [ MAP LIMIT REACHED ]", i+1)
		}
		else if(iGold < g_TurretSlotCost[i])
			formatex(szFormat, charsmax(szFormat), "Slot %d\r [ %d \yGOLD\r ]", i+1, g_TurretSlotCost[i])
		else if(iGold >= g_TurretSlotCost[i])
			formatex(szFormat, charsmax(szFormat), "Slot %d\r [\y BUY FOR \r%d\y GOLD\r ]",  i+1,  g_TurretSlotCost[i])

		
		menu_additem(menu, szFormat, _, _, cb)
	}
	
	menu_additem(menu, "Refresh menu");
	menu_display(id, menu)
	
	client_cmd(id, "spk sound/%s", g_SoundFile[SOUND_MENU_SELECT]);	
}
public ShowUserTurretsMenuCb(id, menu, item) 
{ 
	static iGold ; iGold = td_get_user_info(id, PLAYER_GOLD)

	for(new i ; i < MAX_PLAYER_TURRETS; i++) 
	{	
		if(item == i)
		{
			if(g_IsTurretUpgrading[id][i]) 
				return ITEM_DISABLED
			if((g_ServerTurretsNum >= MAX_SERVER_TURRETS || g_ServerTurretsNum >= MAX_MAP_TURRETS) && g_PlayerTurretEnt[id][i] <= 0)
				return ITEM_DISABLED
			if(!g_PlayerBoughtSlot[id][i] && iGold < g_TurretSlotCost[i])
				return ITEM_DISABLED
		}
	}
		
	return ITEM_ENABLED
}

public ShowUserTurretsMenuH(id, menu, item) 
{
	if(item == MENU_EXIT || !is_user_alive(id)) 
		return PLUGIN_CONTINUE
	
	/* If selected item is "Refresh menu" */
	if(item == MAX_PLAYER_TURRETS)
	{
		g_PlayerTouchingTurret[id] = 0;
		ShowUserTurretsMenu(id)
		return PLUGIN_CONTINUE
	}
	
	if(!g_PlayerBoughtSlot[id][item]) 
	{
		td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_TurretSlotCost[item])
		
		ColorChat(id, GREEN, "[TD TURRETS]^x01 You bought slot %d!", item + 1)
		
		g_PlayerBoughtSlot[id][item] = true
		
		ShowUserTurretsMenu(id);
		return PLUGIN_CONTINUE 
	}
	else
	{
		if(!is_valid_ent(g_PlayerTurretEnt[id][item])) 
			ShowBuyTurretMenu(id, item)	
		else
			ShowTurretMenu(id, item);
	}
			
	return PLUGIN_CONTINUE;
}

public ShowBuyTurretMenu(id, iTurretIndex) 
{
	new szFormat[64];
	
	new iMenu  = menu_create("Select turret type;", "ShowBuyTurretMenuH")
	new cb = menu_makecallback("ShowBuyTurretMenuCb")
	
	/* Sent sentry index */
	new szTurretIndex[4]
	num_to_str(iTurretIndex, szTurretIndex, 3)
	
	for(new i = 1; i < _:ENUM_TURRETS_TYPE; i++) 
	{
		formatex(szFormat, charsmax(szFormat), "%s \r[ \y%d\w GOLD\r ]", g_TurretsName[i], g_TurretsPriceData[i][0])
		menu_additem(iMenu, szFormat, szTurretIndex, _, cb)
	}
	
	client_cmd(id, "spk sound/%s", g_SoundFile[SOUND_MENU_SELECT]);
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back")
	menu_display(id, iMenu)
}

public ShowBuyTurretMenuCb(id, menu, item)
{
	static iGold; iGold = td_get_user_info(id, PLAYER_GOLD) ;
	
	for(new i = 1; i < _:ENUM_TURRETS_TYPE; i++)
		if(iGold < g_TurretsPriceData[ i][0] && item == i-1)
			return ITEM_DISABLED
			
	return ITEM_ENABLED
}

public ShowBuyTurretMenuH(id, menu, item)
{
	if(item == MENU_EXIT ) 
	{
		ShowUserTurretsMenu(id)
		return PLUGIN_CONTINUE
	}
	
	new acces, szTurretIndex[4], name[3], cb
	menu_item_getinfo(menu, 0, acces, szTurretIndex, 3, name, 2, cb)
	
	ShowMenuCreateTurret(id,  (item + 1), str_to_num(szTurretIndex))
	client_cmd(id, "spk sound/%s", g_SoundFile[SOUND_MENU_SELECT], str_to_num(szTurretIndex));
	return PLUGIN_CONTINUE
}

public ShowMenuCreateTurret(id,  iTurretType, iTurretIndex)
{
	new szData[4]
	new szTitle[256], szTurretInfo[174]
	formatex(szTurretInfo, charsmax(szTurretInfo), "Turret type: \w %s^n\yTurret damage:\r %d\w ~\r %d^n\yTurret range:\r %d^n\yTurret accuracy:\r %d%%^n\yTurret firerate:\r %0.2fs", g_TurretsName[iTurretType],
	g_TurretsDamageData[iTurretType][0][0], g_TurretsDamageData[iTurretType][0][1],
	g_TurretsRangeData[iTurretType][0], g_TurretsAccuracyData[iTurretType][0], ((g_TurretsFreqData[iTurretType] / 100.0) * (g_TurretsFireRateData[iTurretType][0] / 100.0)))

	if(g_TurretsMaxLevelData[iTurretType][1] == 1) 
		formatex(szTitle, charsmax(szTitle), "Where do you want to place turret?^n%s^n\rWARNING!\w On this map is only one level of range!", szTurretInfo);
	else
		formatex(szTitle, charsmax(szTitle), "Where do you want to place turret?^n%s", szTurretInfo);
		
	new iMenu = menu_create(szTitle, "ShowMenuCreateTurretH")
	
	num_to_str(iTurretIndex, szData, 3)
	menu_additem(iMenu, "Create turret here", szData)
	
	num_to_str(_:iTurretType, szData, 3)
	menu_additem(iMenu, "Back", szData)
	
	menu_display(id, iMenu);
	
	/* Sent turret type & turret index */
	if(!g_PlayerMovingTurretEntity[id])
		CreateTurretMoveEffect(id, 0, g_TurretsRangeData[iTurretType][0], iTurretType, 0)
}

public ShowMenuCreateTurretH(id, menu, item)
{
	new acces, szTurretIndex[4], szType[4], cb
	menu_item_getinfo(menu, 0, acces, szTurretIndex, 3, szType, 3, cb)
	new iTurretIndex = str_to_num(szTurretIndex)
	
	menu_item_getinfo(menu,1, acces, szType, 3, szTurretIndex, 3, cb)
	new iTurretType = str_to_num(szType)
	
	if(item == MENU_EXIT || !is_user_alive(id) || item == 1)
	{
		menu_destroy(menu)
		
		new iEnt = g_PlayerMovingTurretEntity[id];
		if(iEnt)
		{
			if(is_valid_ent(entity_get_edict(iEnt, EV_ENT_turret_ranger)))
				remove_entity( entity_get_edict(iEnt, EV_ENT_turret_ranger) )
			entity_set_edict(iEnt, EV_ENT_turret_ranger, 0)
			
			remove_entity(iEnt)
			g_PlayerMovingTurretEntity[id] = 0;
		}
		ShowBuyTurretMenu(id, iTurretIndex)
		return PLUGIN_CONTINUE
	}
	
	new iEnt = g_PlayerMovingTurretEntity[id] , 
	Float:fOrigin[3], entlist[3]
	entity_get_vector(iEnt, EV_VEC_origin, fOrigin)
	
	if(find_sphere_class(iEnt, "turret", 60.0, entlist, 2) 
	|| find_sphere_class(iEnt, "turret_reloading", 60.0, entlist, 2) 
	|| find_sphere_class(iEnt, "turret_upgrading", 60.0, entlist, 2)) 
	{
		client_print(id, print_center,"You cannot create turret near other turret");
		ShowMenuCreateTurret(id, iTurretType, iTurretIndex)
		return PLUGIN_CONTINUE
	}
	else if(find_sphere_class(iEnt, "func_illusionary", 10.0, entlist, 2) || !fm_is_ent_visible(id, iEnt)) {
		client_print(id, print_center, "You cannot create turret here")
		ShowMenuCreateTurret(id, iTurretType, iTurretIndex)
		return PLUGIN_CONTINUE
	}		
	else if(find_sphere_class(iEnt, "slot_reservation", 60.0, entlist, 2)  && iEnt!= entity_get_int(entlist[0], EV_INT_place_owner))
	{
		new szName[33], szTurretName[33];
		get_user_name(entity_get_edict(entity_get_int(entlist[0], EV_INT_place_owner), EV_ENT_turret_owner), szName, 32);
		entity_get_string(entity_get_int(entlist[0], EV_INT_place_owner), EV_SZ_turret_name, szTurretName ,32);
		
		client_print(id, print_center, "This place is taken by '%s' turret [%s is moving turret]", szTurretName, szName)
		ShowMenuCreateTurret(id, iTurretType, iTurretIndex)
		return PLUGIN_CONTINUE
	}
	PlayerCreateTurret(id, iTurretType, iTurretIndex)
	client_cmd(id, "spk sound/%s", g_SoundFile[SOUND_MENU_SELECT]);
	
	return PLUGIN_CONTINUE		
}

public PlayerCreateTurret(id, iTurretType, iTurretIndex) 
{	
	new iEnt = g_PlayerMovingTurretEntity[id];
	g_PlayerMovingTurretEntity[id] = 0;
	
	/* If something went wrong */
	if(!is_valid_ent(iEnt))
		return PLUGIN_CONTINUE;
	
	DestroyTurretRanger(iEnt);
	
	/* Remove all effects */
	fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);

	new iLevel = 1;
	
	if(g_TurretsMaxLevelData[iTurretType][0] == 1 
	&& g_TurretsMaxLevelData[iTurretType][1] == 1
	&& g_TurretsMaxLevelData[iTurretType][2] == 1)
		iLevel = 5;
		
	SetTurretModelByLevel(iEnt, iLevel);

	/* Make turret touchable */
	entity_set_size(iEnt, Float:{-16.0, -16.0, 0.0}, Float:{16.0, 16.0, 48.0});

	entity_set_string(iEnt,	EV_SZ_classname, 	"turret")
	entity_set_edict(iEnt, 	EV_ENT_turret_owner, 	id)
	entity_set_int(iEnt, 	EV_INT_turret_index, 	iTurretIndex)
	entity_set_int(iEnt, 	EV_INT_turret_type, 	_:iTurretType)
	entity_set_string(iEnt, EV_SZ_turret_name, 	g_TurretsShopName[iTurretIndex]);
	entity_set_int(iEnt, 	EV_INT_solid, 		SOLID_TRIGGER)
	
	drop_to_floor(iEnt)

	/* Set player params */
	g_PlayerTurretEnt[id][iTurretIndex] 		= iEnt

	entity_set_int(iEnt, EV_INT_turret_level, 1);
	g_PlayerTurretDamageLevel[id][iTurretIndex] 	= 0
	g_PlayerTurretRangeLevel[id][iTurretIndex] 	= 0
	g_PlayerTurretAccuracyLevel[id][iTurretIndex] 	= 0
	g_PlayerTurretFireRateLevel[id][iTurretIndex]	= 0
	
	/* Give turret ammo */

	new iAmmoNum;
	switch( iTurretType) 
	{
		case TURRET_BULLET : 		iAmmoNum = g_ConfigValues[CFG_TURRET_BULLET_AMMO_NUM];
		case TURRET_LASER: 		iAmmoNum = g_ConfigValues[CFG_TURRET_LASER_AMMO_NUM];
		case TURRET_LIGHTING: 		iAmmoNum = g_ConfigValues[CFG_TURRET_LIGHTING_AMMO_NUM];
		case TURRET_MULTI_LASER:	iAmmoNum = g_ConfigValues[CFG_TURRET_M_LASER_AMMO_NUM];
		case TURRET_ROCKET:		iAmmoNum = g_ConfigValues[CFG_TURRET_ROCKET_AMMO_NUM]
		case TURRET_GATLING:		iAmmoNum = g_ConfigValues[CFG_TURRET_GATLING_AMMO_NUM]
	}
	entity_set_int(iEnt, EV_INT_turret_ammo, iAmmoNum);
	
	if(iAmmoNum  <= g_PlayerAmmoAlarmValue[id]) 
		g_PlayerAlarmStatus[id][iTurretIndex] = true;
		
	g_PlayerTurretsNum[id]++
	g_ServerTurretsNum++
	g_IsTurretUpgrading[id][iTurretIndex] = true

	emit_sound(id, CHAN_AUTO, g_SoundFile[SOUND_TURRET_PLANT], 1.0, 0.7, 0, PITCH_NORM);
	
	new Float: fInstallTime = g_ConfigValuesFloat[CFG_FLOAT_TURRET_INSTALL_TIME] - g_PlayerExtraTaskTime[id];
	if(fInstallTime <= 0.0) fInstallTime = 0.1;
	
	td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_TurretsPriceData[iTurretType][0])
	ColorChat(id, GREEN, "%s^x01 Building turret.. Turret type: %s | Turret name: %s | Ammo: %d [ %0.1f seconds ]", CHAT_PREFIX, g_TurretsName[iTurretType], g_TurretsShopName[iTurretIndex], entity_get_int(iEnt, EV_INT_turret_ammo), fInstallTime);
	
	new Float:fOrigin[3]
	new iOrigin[3]
	entity_get_vector(iEnt, EV_VEC_origin, fOrigin);
	FVecIVec(fOrigin, iOrigin);
	
	MakeLavaSplashEffect(iOrigin);
	
	new szData[4]; szData[0] = id; szData[1] = iEnt; szData[2] = iTurretIndex
	set_task(fInstallTime, "TaskTurretInstalled", iEnt+ TASK_CREATE_TURRET, szData, 3)
	
	return PLUGIN_CONTINUE
}

public TaskTurretInstalled(params[], task)
{
	/*
		params[0] = id
		params[1] = iTurretEntity
		params[2] = iTurretIndex
	*/
	
	/* Make turret active */

	if(!is_valid_ent(params[1]))
		return;
		
	g_IsTurretUpgrading[ params[0] ][ params[2] ] = false;
	if(entity_get_int(params[1], EV_INT_turret_ammo) > 0)
		entity_set_float(params[1], EV_FL_nextthink, get_gametime() + 1.0);
	
	ColorChat(params[0], GREEN, "%s^x01 Turret '%s' is ready!", CHAT_PREFIX, g_TurretsShopName[ params[2] ]);
	
	emit_sound(params[1], CHAN_AUTO, g_SoundFile[SOUND_TURRET_READY], 1.0, 2.3, 0, PITCH_NORM);
	
	new szData[3]; szData[0] = params[2]; szData[1] = params[0]
	set_task(0.1, "OpenTurretMenuIfStayingNear", params[1] + TASK_OPEN_TURRET_MENU, szData, 2);
}

public CreateTurretMoveEffect(id , iEntity, iRange, iTurretType, iRangerLevel)
{
	static Float:fOrigin[3];
	entity_get_vector(id, EV_VEC_origin, fOrigin)

	get_origin_from_dist_player(id, 70.0, fOrigin)

	new iEnt;
	if(iEntity)
		iEnt = iEntity;
	else
		iEnt = create_entity("info_target");
	
	entity_set_string(iEnt, EV_SZ_classname, "turret_move")
	entity_set_model(iEnt, "models/TD/sentrygun_2.mdl")
	entity_set_vector(iEnt, EV_VEC_origin, fOrigin)
	
	entity_set_int(iEnt, EV_INT_solid, SOLID_NOT)
	entity_set_int(iEnt, EV_INT_turret_type, _:iTurretType)
	
	fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)

	CreateTurretRanger(id, iEnt, iRangerLevel);
	
	g_PlayerMovingTurretEntity[id] = iEnt;
	
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() +  0.5);
}

public CreateTurretRanger(iPlayer, iEnt, iRangerLevel)
{
	if(is_valid_ent(entity_get_edict(iEnt, EV_ENT_turret_ranger)))
		return;

	new iRanger = create_entity("env_sprite")
	entity_set_edict(iEnt, EV_ENT_turret_ranger, iRanger)
	
	entity_set_string(iRanger, EV_SZ_classname, "ranger")
	entity_set_model(iRanger, "sprites/TD/ranger.spr")
	entity_set_edict(iRanger, EV_ENT_turret_owner, iPlayer)
	
	new Float:fFloatVal[3];
	/* Angle */
	entity_get_vector(iRanger, EV_VEC_angles, fFloatVal)
	fFloatVal[0] += 90
	entity_set_vector(iRanger, EV_VEC_angles,fFloatVal)
	
	/* Origin */
	entity_get_vector(iEnt, EV_VEC_origin, fFloatVal);
	fFloatVal[2] += 1.0
	entity_set_origin(iRanger, fFloatVal)
	
	new totemAbilities[3], iRange;
	GetTurretAbilitiesFromTotem(iEnt, totemAbilities);

	iRange = g_TurretsRangeData[entity_get_int(iEnt, EV_INT_turret_type)][iRangerLevel];
	
	if(totemAbilities[1])
		iRange = (iRange + floatround(iRange * (totemAbilities[1] / 100.0)));
	
	entity_set_float(iRanger, EV_FL_scale, iRange / 250.0)
	entity_set_edict(iRanger, EV_ENT_ranger_owner, iPlayer)

	fm_set_rendering(iRanger, kRenderFxNone, 0, 255, 0, kRenderTransAdd, 255)
}

public DestroyTurretRanger(iEnt)
{
	new iRanger = entity_get_edict(iEnt, EV_ENT_turret_ranger);
	entity_set_edict(iEnt, EV_ENT_turret_ranger, 0);
	
	if(is_valid_ent(iRanger))
		remove_entity(iRanger);
}

public TurretThink(iTurretEntity) 
{
	static iTurretType; 	iTurretType = entity_get_int(iTurretEntity, EV_INT_turret_type)
	static iPlayer; 	iPlayer = entity_get_edict(iTurretEntity, EV_ENT_turret_owner)
	static iTurretIndex ; 	iTurretIndex = entity_get_int(iTurretEntity, EV_INT_turret_index)
	static iCanShoot; 	iCanShoot = entity_get_int(iTurretEntity, EV_INT_turret_canshoot)
	static iTarget; 	iTarget = entity_get_int(iTurretEntity, EV_INT_turret_target)
	
	static Float:TurretOrigin[3]
	static Float:TargetOrigin[3]
	static iTurretAmmo ; iTurretAmmo = entity_get_int(iTurretEntity, EV_INT_turret_ammo)

	new totemAbbilities[3];
	GetTurretAbilitiesFromTotem(iTurretEntity, totemAbbilities);
	/* If turret ammo is 0 stop fire */
	if(iTurretAmmo == 0) 
	{
		/*new iRet;
		ExecuteForward(g_ForwardNoAmmo, iRet, iPlayer, ent, iSentry)
		
		if(iRet)
			return iRet
		*/
		new szTurretName[33];
		entity_get_string(iTurretEntity, EV_SZ_turret_name, szTurretName, 32);
		
		emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_NOAMMO], 1.0, 0.7, 0, PITCH_NORM);
		
		ColorChat(iPlayer, GREEN, "%s^x01 Your '%s' turret is empty!", CHAT_PREFIX, szTurretName)
		client_cmd(iPlayer, "spk sound/%s", g_SoundFile[SOUND_TURRET_NOAMMO]);
		
		/* Set -1 ammo because this message can be showed only one time */
		entity_set_int(iTurretEntity, EV_INT_turret_ammo, -1);
		
		/* Do not set next think. Turret will unfreezed when player buy ammo */
		return PLUGIN_CONTINUE
	}
	
	/* ============ */
	
	/* Firstly check turret can shoot and target is still exist */
	if(iCanShoot && is_valid_ent(iTarget)) 
	{
		/* Check are visible. If no - emit sound stop fire and set next think 0.25s after 
		   And check additional if monster health <= 0.
		 */
		if(!fm_is_ent_visible(iTurretEntity, iTarget) || entity_get_float(iTarget, EV_FL_health) <= 0.0)
		{
			STOP_FIRE:
			emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_STOP_FIRE], 1.0, ATTN_NORM, 0, PITCH_NORM);
	
			entity_set_int(iTurretEntity, EV_INT_turret_canshoot, 0)
			entity_set_int(iTurretEntity, EV_INT_turret_target, 0)
			
			entity_set_float(iTurretEntity, EV_FL_nextthink, get_gametime() + 0.25);
			return PLUGIN_CONTINUE
		}
		
		entity_get_vector(iTarget, EV_VEC_origin, TargetOrigin)
		entity_get_vector(iTurretEntity, EV_VEC_origin, TurretOrigin)
		
		/* If monster is too far, go to STOP_FIRE [upside] */
		if(get_distance_f(TargetOrigin, TurretOrigin) > g_TurretsRangeData[iTurretType][g_PlayerTurretRangeLevel[iPlayer][iTurretIndex]])
			goto STOP_FIRE;
		
		TurretTurnToTarget(iTurretEntity, iTarget);
		entity_set_int(iTurretEntity, EV_INT_turret_ammo, --iTurretAmmo);
		
		if(iTurretAmmo == g_PlayerAmmoAlarmValue[iPlayer])
		{
			/*new iRet;
			ExecuteForward(g_ForwardLowAmmo, iRet, iPlayer, ent, iSentry)
			if(iRet)
				return iRet
			*/
			new szTurretName[33];
			entity_get_string(iTurretEntity, EV_SZ_turret_name, szTurretName, 32);
		
			ColorChat(iPlayer, GREEN, "%s^x01 Your '%s' turret reached alarm value of ammo. [ %d ]", CHAT_PREFIX, szTurretName, g_PlayerAmmoAlarmValue[iPlayer])
			g_PlayerAlarmStatus[iPlayer][iTurretIndex] = true;
			
			client_cmd(iPlayer, "spk sound/%s", g_SoundFile[SOUND_TURRET_LOWAMMO]);
			emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_LOWAMMO], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		
		/* Make sounds */
		switch(iTurretType)
		{
			case TURRET_BULLET: 
			{
				switch(random_num(1, 2))
				{
					case 1:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_BULLET_FIRE_1], 1.0, ATTN_NORM, 0, PITCH_NORM);
					case 2:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_BULLET_FIRE_2], 1.0, ATTN_NORM, 0, PITCH_NORM);
				}
			}
			case TURRET_LASER: 
			{
				switch(random_num(1, 2))
				{
					case 1:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_LASER_FIRE_1], 1.0, ATTN_NORM, 0, PITCH_NORM);
					case 2:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_LASER_FIRE_2], 1.0, ATTN_NORM, 0, PITCH_NORM);
				}
			}
			case TURRET_LIGHTING: 
			{
				switch(random_num(1, 2))
				{
					case 1:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_LIGHTING_FIRE_1], 1.0, ATTN_NORM, 0, PITCH_NORM);
					case 2:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_LIGHTING_FIRE_2], 1.0, ATTN_NORM, 0, PITCH_NORM);
				}
			}
			case TURRET_MULTI_LASER: 
			{
				switch(random_num(1, 2))
				{
					case 1:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_M_LASER_FIRE_1], 1.0, ATTN_NORM, 0, PITCH_NORM);
					case 2:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_M_LASER_FIRE_2], 1.0, ATTN_NORM, 0, PITCH_NORM);
				}
			}
			case TURRET_ROCKET:
			{
				switch(random_num(1, 2))
				{
					case 1:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_ROCKET_FIRE_1], 1.0, ATTN_NORM, 0, PITCH_NORM);
					case 2:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_ROCKET_FIRE_2], 1.0, ATTN_NORM, 0, PITCH_NORM);
				}
			}
			case TURRET_GATLING:
			{
				switch(random_num(1, 2))
				{
					case 1:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_GATLING_FIRE_1], 1.0, ATTN_NORM, 0, PITCH_NORM);
					case 2:emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_GATLING_FIRE_2], 1.0, ATTN_NORM, 0, PITCH_NORM);
				}
			}
		}
		
		/* Make shot effect */
		
		static iTurretOrigin[3];
		static iTargetOrigin[3];
		static iTurretLevel; iTurretLevel =  entity_get_int(iTurretEntity, EV_INT_turret_level);
		
		FVecIVec(TurretOrigin, iTurretOrigin);
		FVecIVec(TargetOrigin, iTargetOrigin);
		
		/* Shot effect will not be perfectly straight */
		iTurretOrigin[2] += 45;	
		
		if(iTurretType != TURRET_MULTI_LASER)
			iTargetOrigin[2] = random_num(iTargetOrigin[2] - 20, iTargetOrigin[2] + 30);
		
		message_begin(MSG_BROADCAST ,SVC_TEMPENTITY, iTargetOrigin) //message begin
		write_byte(TE_SPARKS)
		write_coord(iTargetOrigin[0]) // start position
		write_coord(iTargetOrigin[1])
		write_coord(iTargetOrigin[2])
		message_end()

		new iNearestMonsters[15], iNearestMonstersNum

		new bool:isMissShoot = random_num(1, 100) > g_TurretsAccuracyData[iTurretType][ g_PlayerTurretAccuracyLevel[iPlayer][iTurretIndex] ]

		if(iTurretType == TURRET_MULTI_LASER || iTurretType == TURRET_ROCKET)
		{
			new bool:isRocketTurret = iTurretType == TURRET_ROCKET;
			new Float:fRange = isRocketTurret ? (305.0 + (iTurretLevel * 15.0)) : (500.0 + (iTurretLevel * 50.0));
			iNearestMonstersNum = find_sphere_class(iTarget, "monster", fRange, iNearestMonsters, isRocketTurret ? sizeof iNearestMonsters : 4)
			new iNearestMonster;
			for(new i ; i < iNearestMonstersNum ; i++)
			{
				iNearestMonster = iNearestMonsters[i]
				if(iNearestMonster == 0)
					continue;

				if(iNearestMonster == iTarget || (!isRocketTurret && !fm_is_ent_visible(iTarget, iNearestMonster)))
					iNearestMonsters[i] = 0;
			}
		}
	
		switch(iTurretType) 
		{
			case TURRET_BULLET: 
			{
				/* Make fire */
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
				write_byte(TE_TRACER);
				write_coord(iTurretOrigin[0]);
				write_coord(iTurretOrigin[1]);
				write_coord(iTurretOrigin[2]);
				write_coord(iTargetOrigin[0]);
				write_coord(iTargetOrigin[1]);
				write_coord(iTargetOrigin[2]);
				message_end();
				
				/* Make shell */
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0.0, 0.0, 0.0}, iTurretEntity);
				write_byte(TE_MODEL);
				write_coord(iTurretOrigin[0]);
				write_coord(iTurretOrigin[1]);
				write_coord(iTurretOrigin[2]);
				write_coord(random_num(-100,100));
				write_coord(random_num(-100,100));
				write_coord(random_num(100,200));
				write_angle(random_num(0,360));
				write_short(g_SpriteShell);
				write_byte(0);
				write_byte(100);
				message_end()

				/*Make splash effect*/

				message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
				write_byte(TE_WORLDDECAL)
				write_coord(iTurretOrigin[0]);
				write_coord(iTurretOrigin[1]);
				write_coord(iTurretOrigin[2]);
				write_byte(41) //num of 'sparks'
				message_end()
			}
			case TURRET_LASER: 
			{
				message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
				write_byte(TE_BEAMPOINTS)
				write_coord(iTurretOrigin[0]);
				write_coord(iTurretOrigin[1]);
				write_coord(iTurretOrigin[2]);
				write_coord(iTargetOrigin[0]);
				write_coord(iTargetOrigin[1]);
				write_coord(iTargetOrigin[2]);
				write_short(g_SpriteLaserBeam)
				write_byte(0)
				write_byte(0)
				write_byte(3) // time
				write_byte(6 * iTurretLevel) // grubosc
				write_byte(1)
				
				switch(iTurretLevel) 
				{
					case 1: 
					{
						write_byte(255)
						write_byte(255)
						write_byte(255)
					} 
					case 2: 
					{
						write_byte(0)
						write_byte(255)
						write_byte(0)
					}
					case 3: 
					{
						write_byte(255)
						write_byte(255)
						write_byte(0)
					} 
					case 4: 
					{
						write_byte(255)
						write_byte(0)
						write_byte(0)
					} 
					case 5:
					{
						write_byte(0)
						write_byte(0)
						write_byte(255)
					}
				}
				write_byte(255)
				write_byte(5)
				message_end()
			}
			case TURRET_LIGHTING:
			{
				message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
				write_byte(TE_BEAMPOINTS)
				write_coord(iTurretOrigin[0]);
				write_coord(iTurretOrigin[1]);
				write_coord(iTurretOrigin[2]);
				write_coord(iTargetOrigin[0]);
				write_coord(iTargetOrigin[1]);
				write_coord(iTargetOrigin[2]);
				write_short(g_SpriteLaserBeam)
				write_byte(0)
				write_byte(0)
				write_byte(1) // time
				write_byte(10) // grubosc
				write_byte(16)
				
				switch(iTurretLevel) 
				{
					case 1: 
					{
						write_byte(255)
						write_byte(255)
						write_byte(255)
					} 
					case 2:
					{	
						write_byte(0)
						write_byte(255)
						write_byte(0)
					}
					case 3: 
					{
						write_byte(255)
						write_byte(255)
						write_byte(0)
					} 
					case 4: 
					{
						write_byte(255)
						write_byte(0)
						write_byte(0)
					} 
					case 5:
					{
						write_byte(0)
						write_byte(0)
						write_byte(255)
					}
				}
				write_byte(255)
				write_byte(5) //szybkosc
				message_end()
			}
			case TURRET_MULTI_LASER:
			{
				message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
				write_byte(TE_BEAMPOINTS)
				write_coord(iTurretOrigin[0]);
				write_coord(iTurretOrigin[1]);
				write_coord(iTurretOrigin[2]);
				write_coord(iTargetOrigin[0]);
				write_coord(iTargetOrigin[1]);
				write_coord(iTargetOrigin[2]);
				write_short(g_SpriteLaserBeam)
				write_byte(0)
				write_byte(0)
				write_byte(3) // time
				write_byte(14 * iTurretLevel) // grubosc
				write_byte(1)
				
				switch(iTurretLevel) 
				{
					case 1: 
					{
						write_byte(255)
						write_byte(255)
						write_byte(255)
					} 
					case 2: 
					{
						write_byte(0)
						write_byte(255)
						write_byte(0)
					}
					case 3: 
					{
						write_byte(255)
						write_byte(255)
						write_byte(0)
					} 
					case 4: 
					{
						write_byte(255)
						write_byte(0)
						write_byte(0)
					} 
					case 5:
					{
						write_byte(0)
						write_byte(0)
						write_byte(255)
					}
				}
				write_byte(255)
				write_byte(5)
				message_end()

				if(!isMissShoot && iNearestMonstersNum)
				{
					new iNearestMonster;
					for(new i; i < iNearestMonstersNum; i++)
					{
						iNearestMonster = iNearestMonsters[i];
						
						if(iNearestMonster == 0)
							continue;

						message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
						write_byte(TE_BEAMENTS)
						write_short(iTarget)	// start entity
						write_short(iNearestMonster)  // end entity
						write_short(g_SpriteLaserBeam)	// sprite index
						write_byte(0)	// starting frame
						write_byte(0)	// frame rate in 0.1's
						write_byte(5)	// life in 0.1's
						write_byte((14 * iTurretLevel) - (iTurretLevel*2*i))	// line width in 0.1's
						write_byte(1)	// noise amplitude in 0.01's

						switch(iTurretLevel) 
						{
							case 1: 
							{
								write_byte(255)
								write_byte(255)
								write_byte(255)
							} 
							case 2: 
							{
								write_byte(0)
								write_byte(255)
								write_byte(0)
							}
							case 3: 
							{
								write_byte(255)
								write_byte(255)
								write_byte(0)
							} 
							case 4: 
							{
								write_byte(255)
								write_byte(0)
								write_byte(0)
							} 
							case 5:
							{
								write_byte(0)
								write_byte(0)
								write_byte(255)
							}
						}
						
						write_byte(90)	// brightness
						write_byte(10)	// scroll speed in 0.1's
						message_end()
					}
				}
			}

			case TURRET_ROCKET:
			{
				new iRocket = create_entity("info_target");
				entity_set_string(iRocket, EV_SZ_classname, "turret_rocket")
				entity_set_model(iRocket, "models/TD/rocket.mdl")

				TurretOrigin[2] += 45.0;
				entity_set_origin(iRocket, TurretOrigin);
				entity_set_aim(iRocket, iTarget, Float:{0.0, 0.0, -36.0}, 0); 
				entity_set_vector(iRocket, EV_VEC_mins, Float:{-1.0, -1.0, -1.0})
 				entity_set_vector(iRocket, EV_VEC_maxs, Float:{1.0, 1.0, 1.0});

				entity_set_int(iRocket, EV_INT_solid, SOLID_TRIGGER)
				entity_set_int(iRocket, EV_INT_movetype, MOVETYPE_FLY)
				
				entity_set_edict(iRocket, EV_ENT_owner, iPlayer)
				entity_set_int(iRocket, EV_INT_rocket_turretent, iTurretEntity)
				entity_set_int(iRocket,  EV_INT_turret_index, iTurretIndex);
				entity_set_int(iRocket, EV_INT_turret_type, iTurretType);
				
				new Float:Velocity[3]
				VelocityByAim(iRocket, 1000, Velocity) //Rocket speed
				entity_set_vector(iRocket, EV_VEC_velocity, Velocity)

				message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
				write_byte(TE_BEAMFOLLOW)
				write_short(iRocket)
				write_short(g_SpriteRocketSmoke)
				write_byte(30)
				write_byte(3)
				write_byte(255)
				write_byte(255)
				write_byte(255)
				write_byte(255);
				message_end();	
			}

			case TURRET_GATLING:
			{	
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
				write_byte(TE_TRACER);
				write_coord(iTurretOrigin[0]);
				write_coord(iTurretOrigin[1]);
				write_coord(iTurretOrigin[2]);
				write_coord(iTargetOrigin[0]);
				write_coord(iTargetOrigin[1]);
				write_coord(iTargetOrigin[2]);
				message_end();
				
				/* Make shell */
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0.0, 0.0, 0.0}, iTurretEntity);
				write_byte(TE_MODEL);
				write_coord(iTurretOrigin[0]);
				write_coord(iTurretOrigin[1]);
				write_coord(iTurretOrigin[2]);
				write_coord(random_num(-100,100));
				write_coord(random_num(-100,100));
				write_coord(random_num(100,200));
				write_angle(random_num(0,360));
				write_short(g_SpriteShell);
				write_byte(0);
				write_byte(100);
				message_end()

				message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
				write_byte(TE_BEAMPOINTS)
				write_coord(iTurretOrigin[0]);
				write_coord(iTurretOrigin[1]);
				write_coord(iTurretOrigin[2]);
				write_coord(iTargetOrigin[0]);
				write_coord(iTargetOrigin[1]);
				write_coord(iTargetOrigin[2]);
				write_short(g_SpriteLaserBeam)
				write_byte(0)
				write_byte(0)
				write_byte(3) // time
				write_byte(4) // grubosc
				write_byte(1)
				write_byte(255);
				write_byte(255);
				write_byte(0);
				write_byte(255);
				write_byte(5);
				message_end();
			}
		}
		
		/* Take damage to monster | Chance 3/4 to shot*/
		if(!isMissShoot && iTurretType != TURRET_ROCKET) 
		{
			new iTurretDamagelevel = g_PlayerTurretDamageLevel[iPlayer][iTurretIndex];
			new Float:dmg = random_float(float(g_TurretsDamageData[iTurretType][iTurretDamagelevel][0]), float(g_TurretsDamageData[iTurretType][iTurretDamagelevel][1]))
			dmg *= (1.0 + (totemAbbilities[0] / 100.0));

			static iShowDeathMsg;
			if(iShowDeathMsg == 0) 
			{
				iShowDeathMsg = g_ConfigValues[CFG_TURRET_SHOW_DEATH_MSG] ;
				if(iShowDeathMsg == 0)
					iShowDeathMsg = -1
			}
			
			if(iShowDeathMsg && entity_get_float(iTarget, EV_FL_health) - dmg <= 0.0)
				makeDeathMsg(iPlayer);
				
			ExecuteHamB(Ham_TakeDamage, iTarget, iPlayer, iPlayer, dmg, DMG_DROWN, 1);
			
			if(iTurretType == TURRET_MULTI_LASER && iNearestMonstersNum)
			{
				new Float:fTempDamage, iNearestMonster;
				
				for(new i; i < iNearestMonstersNum; i++)
				{
					iNearestMonster = iNearestMonsters[i];				
					if(iNearestMonster == 0)
						continue;
						
					fTempDamage = dmg * (0.76 - (i * 0.15));

					if(iShowDeathMsg && entity_get_float(iNearestMonster, EV_FL_health) - fTempDamage <= 0.0)
						makeDeathMsg(iPlayer);
					ExecuteHamB(Ham_TakeDamage, iNearestMonster, iPlayer, iPlayer, fTempDamage, DMG_DROWN, 1);
				}
			}

		}
		else
		{
			/* If turret missed | missed.wav? */
		}
		
		/* Set shot next think */
		new Float:fTime = ((g_TurretsFreqData[iTurretType] / 100.0) * (g_TurretsFireRateData[iTurretType][g_PlayerTurretFireRateLevel[iPlayer][iTurretIndex]] / 100.0));
		fTime *= (1.0 - (totemAbbilities[2] / 100.0));

		entity_set_float(iTurretEntity, EV_FL_nextthink, get_gametime() + fTime);
		return PLUGIN_CONTINUE	
	}
	else
	{
		/* If monster is valid, set stand-by */
		iCanShoot = 0
	}
		
	/* Every stand-by think try to find closest monster in range */
	static Float:fRange; fRange = float(g_TurretsRangeData[iTurretType][g_PlayerTurretRangeLevel[iPlayer][iTurretIndex]])
	fRange *= (1.0 + (totemAbbilities[1] / 100.0));
	iTarget = TurretGetClosestMonster(iTurretEntity, TurretOrigin, fRange);

	/* If monster finded and are visible */
	if(iTarget && fm_is_ent_visible(iTurretEntity, iTarget))
	{
		emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_START_FIRE], 1.0, ATTN_NORM, 0, PITCH_NORM);
		TurretTurnToTarget(iTurretEntity, iTarget);
		
		entity_set_int(iTurretEntity, EV_INT_turret_target, iTarget)
		entity_set_int(iTurretEntity, EV_INT_turret_canshoot, 1)
		
		entity_set_float(iTurretEntity, EV_FL_nextthink, get_gametime() + g_ConfigValuesFloat[CFG_FLOAT_CHANGE_ENEMY_TIME]);
		
		return PLUGIN_CONTINUE
	}
	
	/*  Freeze time  */
	if(!iCanShoot) 
	{
		new controler1 = entity_get_byte(iTurretEntity, EV_BYTE_controller1)+2;
		if(controler1 > 255)
			controler1 = 0;
		entity_set_byte(iTurretEntity, EV_BYTE_controller1, controler1);
			
		/*new controler2 = entity_get_byte(ent, EV_BYTE_controller2);
		if(controler2 > 127 || controler2 < 127)*/
		entity_set_byte(iTurretEntity, EV_BYTE_controller2, 127);
		
		/* Stand-by checking time */
		entity_set_float(iTurretEntity, EV_FL_nextthink, get_gametime() + 0.25);
	}
	return PLUGIN_CONTINUE
}

makeDeathMsg(iPlayer)
{
	static dmsg
	if(!dmsg)
		dmsg = get_user_msgid("DeathMsg");
		
	message_begin(MSG_ALL, dmsg, {0,0,0}, 0);
	write_byte(iPlayer);
	write_byte(0);
	write_byte(0);
	write_string("")
	message_end()
}

public TurretTouched(iEnt, iPlayer)
{
	if(g_PlayerTouchingTurret[iPlayer] || g_PlayerMovingTurretEntity[iPlayer])
		return;
		
	if(task_exists(iEnt + TASK_CREATE_TURRET) || task_exists(iEnt +TASK_MOVE_TURRET))
		return;
		
	static szText[128];
	static szTurretName[64];
	entity_get_string(iEnt, EV_SZ_turret_name, szTurretName, 32);
	format(szTurretName, 63, "%s [%s]", szTurretName, g_TurretsName[entity_get_int(iEnt, EV_INT_turret_type)]);
	g_PlayerTouchingTurret[iPlayer] = iEnt;

	if(IsPlayerTurretOwner(iEnt, iPlayer))
	{
		new iAmmo = entity_get_int(iEnt, EV_INT_turret_ammo);
		if(!iAmmo)
			iAmmo = 0;
		formatex(szText, 127, "Your turret: %s^nAmmo: %d^nPress 'E' to open turret menu.", szTurretName, clamp(iAmmo, 0, 9999));
		CreateTurretRanger(iPlayer,iEnt, g_PlayerTurretRangeLevel[iPlayer][ entity_get_int(iEnt, EV_INT_turret_index)]);
	}
	else
	{
		new szOwnerName[33];
		get_user_name(GetTurretOwner(iEnt), szOwnerName, 32);
		
		formatex(szText, 127, "Turret: %s^nTurret owner: %s", szTurretName, szOwnerName);
	}

	CheckIsPlayerInRange(szText, iPlayer + TASK_CHECK_IS_IN_RANGE);
}

public CheckIsPlayerInRange(szText[], iPlayer)
{
	iPlayer -= TASK_CHECK_IS_IN_RANGE;
	if(!is_user_alive(iPlayer))
		return;

	new entlist[3];
	if(find_sphere_class(iPlayer, "turret", 60.0, entlist, 2))
	{	
		if(entlist[0] == g_PlayerTouchingTurret[iPlayer] || entlist[1] == g_PlayerTouchingTurret[iPlayer])
		{
			set_dhudmessage(255, 255, 170, -1.0, 0.77, 0, 1.1, 1.1)
			show_dhudmessage(iPlayer, szText)
			
			set_task(1.0, "CheckIsPlayerInRange", iPlayer + TASK_CHECK_IS_IN_RANGE, szText, 127);
		}
		else
			DestroyMenuWhenIsNotTouching(iPlayer)
	}
	else if(GetTurretOwner(g_PlayerTouchingTurret[iPlayer]) == iPlayer)
		DestroyMenuWhenIsNotTouching(iPlayer)
	else
		g_PlayerTouchingTurret[iPlayer] = 0;
}

public DestroyMenuWhenIsNotTouching(iPlayer)
{
	if(g_PlayerMovingTurretEntity[iPlayer] == g_PlayerTouchingTurret[iPlayer])
		return;

	DestroyTurretRanger(g_PlayerTouchingTurret[iPlayer]);			
	show_menu(iPlayer, 0, "^n", 1);
		
	g_PlayerTouchingTurret[iPlayer] = 0;
}

public CmdUse(id, uc_handle, seed)
{
	if(!task_exists(id + TASK_CHECK_IS_IN_RANGE))
		return;

	/* If player is touching him turret */
	if((get_uc(uc_handle, UC_Buttons) & IN_USE) && !(get_user_oldbutton(id) & IN_USE))
		if(GetTurretOwner(g_PlayerTouchingTurret[id]) == id)
			ShowTurretMenu(id, entity_get_int(g_PlayerTouchingTurret[id], EV_INT_turret_index));

}
public client_PostThink(id) 
{
	if(g_PlayerMovingTurretEntity[id]) 
	{
		new iEnt = g_PlayerMovingTurretEntity[id];
		
		static Float:fOrigin[3]
		get_origin_from_dist_player(id, 70.0, fOrigin)
		entity_set_origin(iEnt, fOrigin)
		
		drop_to_floor(iEnt)
		entity_get_vector(iEnt, EV_VEC_origin, fOrigin);
		
		fOrigin[2] += 1.0
		entity_set_origin(entity_get_edict(iEnt, EV_ENT_turret_ranger), fOrigin)
		
		//entity_get_vector(iEnt, EV_VEC_origin, fOrigin)
		static Origin[3]; get_user_origin(id, Origin, 3)
		IVecFVec(Origin, fOrigin)
		TurretTurnToTarget(iEnt, 0, 1, fOrigin);
		
		new entlist[3];
		if(find_sphere_class(iEnt, "turret", 60.0, entlist, 2)
		|| find_sphere_class(iEnt, "turret_reloading", 60.0, entlist, 2)
		|| find_sphere_class(iEnt, "turret_upgrading", 60.0, entlist, 2)
		|| find_sphere_class(iEnt, "func_illusionary", 10.0, entlist, 2)
		|| !fm_is_ent_visible(id, iEnt)
		|| (find_sphere_class(iEnt, "slot_reservation", 60.0, entlist, 2)
		&& iEnt!= entity_get_int(entlist[0], EV_INT_place_owner)))
			entity_set_model(iEnt, "models/TD/sentrygun_4.mdl")
		else
			entity_set_model(iEnt, "models/TD/sentrygun_2.mdl")
	}	
}

public GetTurretAbilitiesFromTotem(turretEnt, outData[3])
{
	new turretTotemBit = entity_get_edict(turretEnt, EV_ENT_turret_totem_bit);
	
	for(new i; i <= 30; i++)
	{
		if(!((1 << i) & turretTotemBit))
			continue;
		
		static ent; ent = g_PlayerTotems[i];

		if(ent <= _:TOTEMS)
			continue;
		
		static totemType; totemType = entity_get_int(ent, EV_INT_totem_type);

		switch(totemType)
		{
			case TOTEM_DAMAGE: outData[0] += 30;
			case TOTEM_RANGE: outData[1] += 25;
			case TOTEM_FIRERATE: outData[2] += 15;
			case TOTEM_ALL: 
			{
				outData[0] += 25;
				outData[1] += 25;
				outData[2] += 25;
			}
		}
	}
}

public ShowTurretMenu(id, iTurretIndex) 
{	
	client_cmd(id, "spk sound/%s", g_SoundFile[SOUND_MENU_SELECT]);
	
	new szTitle[512], szFormat[33];
	new iEnt = g_PlayerTurretEnt[id][iTurretIndex];
	new iTurretType = entity_get_int(iEnt, EV_INT_turret_type)
	new iTurretAmmo = entity_get_int(iEnt, EV_INT_turret_ammo);
	new iDamageLevel = g_PlayerTurretDamageLevel[id][iTurretIndex]
	new Float:fFireRate = ((g_TurretsFreqData[iTurretType] / 100.0) * (g_TurretsFireRateData[iTurretType][g_PlayerTurretFireRateLevel[id][iTurretIndex]] / 100.0));

	entity_get_string(iEnt, EV_SZ_turret_name, szFormat, 32);
	
	if(iTurretAmmo == -1)
	{
		iTurretAmmo = 0;
		formatex(szTitle, charsmax(szTitle), "\r[\y %s \r] [\y %s\r ] [\w NO AMMO\r ]", szFormat, g_TurretsName[iTurretType]);
	}
	else if(g_PlayerAlarmStatus[id][iTurretIndex])
		formatex(szTitle, charsmax(szTitle), "\r[\y %s \r] [\y %s\r ] [\w LOW AMMO\r ]", szFormat, g_TurretsName[iTurretType]);
	else
		formatex(szTitle, charsmax(szTitle), "\r[\y %s \r] [\y %s\r ]", szFormat, g_TurretsName[iTurretType]);

	CreateTurretRanger(id, iEnt, g_PlayerTurretRangeLevel[id][iTurretIndex]);

	new totemAbbilities[3];
	GetTurretAbilitiesFromTotem(iEnt, totemAbbilities);

	if(totemAbbilities[0] || totemAbbilities[1] || totemAbbilities[2])
		format(szTitle, charsmax(szTitle), "%s\w + TOTEM EFFECT\r", szTitle);

	new iDamageMin = floatround(g_TurretsDamageData[iTurretType][iDamageLevel][0] * (1.0 + totemAbbilities[0] / 100.0));
	new iDamageMax = floatround(g_TurretsDamageData[iTurretType][iDamageLevel][1] * (1.0 + totemAbbilities[0] / 100.0));
	new iRange = floatround(g_TurretsRangeData[iTurretType][g_PlayerTurretRangeLevel[id][iTurretIndex]] * (1.0 + totemAbbilities[1] / 100.0));
	fFireRate *= (1.0 - (totemAbbilities[2] / 100.0));

	formatex(szTitle, charsmax(szTitle), "%s^n[ \yLevel: \w%d\r ] [ \yAmmo: \w%d\r ]^n[ \yDamage: \w%d\y ~\w %d\r ] [ \yRange:\w %d\r ]^n[ \yAccuracy: \w%d%%\r ] [\yFirerate: \w%0.2fs\r ]", 
	szTitle, entity_get_int(iEnt, EV_INT_turret_level), iTurretAmmo ?  iTurretAmmo : 0, 
	iDamageMin, iDamageMax, iRange, g_TurretsAccuracyData[iTurretType][ g_PlayerTurretAccuracyLevel[id][iTurretIndex]], fFireRate)
	
	if(g_PlayerTouchingTurret[id] !=  iEnt)
		formatex(szTitle, charsmax(szTitle), "%s^n\w- You must stay near your turret -", szTitle);
	
	new iMenu = menu_create(szTitle, "ShowTurretMenuH")
	new cb = menu_makecallback("ShowTurretMenuCb")
	
	new szTurretIndex[4];
	num_to_str(iTurretIndex, szTurretIndex, 3)
	
	switch(iTurretType)
	{
		case TURRET_BULLET:		formatex(szFormat, 32, "Buy %d ammo for %d gold", g_ConfigValues[CFG_TURRET_BULLET_AMMO_NUM], g_ConfigValues[CFG_TURRET_BULLET_AMMO_COST])
		case TURRET_LASER:		formatex(szFormat, 32, "Buy %d ammo for %d gold", g_ConfigValues[CFG_TURRET_LASER_AMMO_NUM], g_ConfigValues[CFG_TURRET_LASER_AMMO_COST])
		case TURRET_LIGHTING:	formatex(szFormat, 32, "Buy %d ammo for %d gold", g_ConfigValues[CFG_TURRET_LIGHTING_AMMO_NUM], g_ConfigValues[CFG_TURRET_LIGHTING_AMMO_COST])
		case TURRET_MULTI_LASER:formatex(szFormat, 32, "Buy %d ammo for %d gold", g_ConfigValues[CFG_TURRET_M_LASER_AMMO_NUM], g_ConfigValues[CFG_TURRET_M_LASER_AMMO_COST])
		case TURRET_ROCKET:		formatex(szFormat, 32, "Buy %d ammo for %d gold", g_ConfigValues[CFG_TURRET_ROCKET_AMMO_NUM], g_ConfigValues[CFG_TURRET_ROCKET_AMMO_COST])
		case TURRET_GATLING:	formatex(szFormat, 32, "Buy %d ammo for %d gold", g_ConfigValues[CFG_TURRET_GATLING_AMMO_NUM], g_ConfigValues[CFG_TURRET_GATLING_AMMO_COST])
	}
	// 0
	menu_additem(iMenu, szFormat, szTurretIndex, _, cb);
	
	// 1
	menu_additem(iMenu, "Delete turret", _, _, cb);

	// 2
	formatex(szFormat, 32, "Move turret for %d gold", g_ConfigValues[CFG_TURRET_MOVE_COST])
	menu_additem(iMenu, szFormat, _, _, cb)
	
	// 3
	formatex(szFormat, 32, "Change turret name for %d gold", g_ConfigValues[CFG_TURRET_CHANGE_NAME_COST])
	menu_additem(iMenu, szFormat, _, _, cb)
	
	// 4
	if(g_IsTurretUpgrading[id][iTurretIndex])
		menu_additem(iMenu, "Is during in phase configuration...", _, _, cb)
	else 
		menu_additem(iMenu, "Upgrade turret", _, _, cb)
	
	if(g_PlayerTouchingTurret[id] != iEnt)
		menu_setprop(iMenu, MPROP_EXITNAME, "Back")
	
	menu_display(id, iMenu);
	set_task(0.1, "reset", id + 7192);
	return PLUGIN_CONTINUE
}

public reset(id)
	g_PlayerTouchingTurret[id - 7192] = 0;
	
public ShowTurretMenuCb(id, menu, item)
{
	new cb, acces, szName[3], szTurretIndex[4]
	menu_item_getinfo(menu, 0, acces, szTurretIndex, 3, szName, 2, cb)
	
	new iTurretIndex = str_to_num(szTurretIndex);	
	
	if(g_PlayerTouchingTurret[id] != g_PlayerTurretEnt[id][iTurretIndex])
		return ITEM_DISABLED
	
	if(g_IsTurretUpgrading[id][iTurretIndex])
		return ITEM_DISABLED;
		
	new iPlayerGold = td_get_user_info(id, PLAYER_GOLD)
	new iTurretType = entity_get_int(g_PlayerTurretEnt[id][iTurretIndex], EV_INT_turret_type)

	if(item == 0)
	{
		switch(iTurretType)
		{
			case TURRET_BULLET:
			{
				if(g_ConfigValues[CFG_TURRET_BULLET_AMMO_COST] > iPlayerGold)
					return ITEM_DISABLED
			}
			case TURRET_LASER:
			{
				if(g_ConfigValues[CFG_TURRET_LASER_AMMO_COST] > iPlayerGold)
					return ITEM_DISABLED
			}
			case TURRET_LIGHTING:
			{
				if(g_ConfigValues[CFG_TURRET_LIGHTING_AMMO_COST] > iPlayerGold)
					return ITEM_DISABLED
			}
			case TURRET_MULTI_LASER:
			{
				if(g_ConfigValues[CFG_TURRET_M_LASER_AMMO_COST] > iPlayerGold)
					return ITEM_DISABLED
			}
			case TURRET_ROCKET:
			{
				if(g_ConfigValues[CFG_TURRET_ROCKET_AMMO_COST] > iPlayerGold)
					return ITEM_DISABLED
			}
			case TURRET_GATLING:
			{
				if(g_ConfigValues[CFG_TURRET_GATLING_AMMO_COST] > iPlayerGold)
					return ITEM_DISABLED
			}
			
		}
	}
	
	if(item == 2 && iPlayerGold < g_ConfigValues[CFG_TURRET_MOVE_COST])
		return ITEM_DISABLED
	
	if(item == 3 && iPlayerGold < g_ConfigValues[CFG_TURRET_CHANGE_NAME_COST])
		return ITEM_DISABLED;
		
	return ITEM_ENABLED
}

public ShowTurretMenuH(id, menu, item) 
{
	new cb, acces, szName[3], szTurretIndex[4]
	menu_item_getinfo(menu, 0, acces, szTurretIndex, 3, szName, 2, cb)
	
	new iTurretIndex = str_to_num(szTurretIndex);
	new iTurretEntity = g_PlayerTurretEnt[id][iTurretIndex];
	if(item == MENU_EXIT) 
	{
		if( g_PlayerTouchingTurret[id] == iTurretEntity)
			return PLUGIN_CONTINUE;
		
		DestroyTurretRanger(g_PlayerTurretEnt[id][iTurretIndex]);
		
		ShowUserTurretsMenu(id);
		return PLUGIN_CONTINUE
	}
	
	new iTurretType = entity_get_int(iTurretEntity, EV_INT_turret_type)
	
	if(item == 0)
	{
		new iTurretAmmo = entity_get_int(iTurretEntity, EV_INT_turret_ammo);
		if(iTurretAmmo == -1)
			iTurretAmmo = 0;
			
		switch(iTurretType)
		{
			case TURRET_BULLET: 
			{
				td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_ConfigValues[CFG_TURRET_BULLET_AMMO_COST])
				iTurretAmmo += g_ConfigValues[CFG_TURRET_BULLET_AMMO_NUM]
			}
			case TURRET_LASER: 
			{
				td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_ConfigValues[CFG_TURRET_LASER_AMMO_COST])
				iTurretAmmo += g_ConfigValues[CFG_TURRET_LASER_AMMO_NUM]
			}
			case TURRET_LIGHTING:
			{
				td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_ConfigValues[CFG_TURRET_LIGHTING_AMMO_COST])
				iTurretAmmo += g_ConfigValues[CFG_TURRET_LIGHTING_AMMO_NUM]
			}
			case TURRET_MULTI_LASER:
			{
				td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_ConfigValues[CFG_TURRET_M_LASER_AMMO_COST])
				iTurretAmmo += g_ConfigValues[CFG_TURRET_M_LASER_AMMO_NUM]
			}
			case TURRET_ROCKET:
			{
				td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_ConfigValues[CFG_TURRET_ROCKET_AMMO_COST])
				iTurretAmmo += g_ConfigValues[CFG_TURRET_ROCKET_AMMO_NUM]
			}
			case TURRET_GATLING:
			{
				td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_ConfigValues[CFG_TURRET_GATLING_AMMO_COST])
				iTurretAmmo += g_ConfigValues[CFG_TURRET_GATLING_AMMO_NUM]
			}
		}
		
		entity_set_int(iTurretEntity,  EV_INT_turret_ammo, iTurretAmmo);
		
		new Float:fTaskTime =  g_ConfigValuesFloat[CFG_FLOAT_TURRET_RELOAD_TIME] - g_PlayerExtraTaskTime[id];
		if(fTaskTime <= 0.0)
			fTaskTime = 0.1
		
		ColorChat(id, GREEN, "%s^x01 Reloading turret... [ %0.1f seconds ]",CHAT_PREFIX,  fTaskTime)
		
		DestroyTurretRanger(iTurretEntity);
		
		if(iTurretAmmo > g_PlayerAmmoAlarmValue[id]) 
			g_PlayerAlarmStatus[id][iTurretIndex] = false;
		
		g_IsTurretUpgrading[id][iTurretIndex] = true
		g_PlayerTouchingTurret[id] = 0;
		
		entity_set_string(iTurretEntity, EV_SZ_classname, "turret_reloading")
		new szData[3]; szData[0] = id; szData[1] = iTurretIndex
		set_task(fTaskTime, "TurretReloadTaskEnd", iTurretEntity + TASK_RELOAD_TURRET, szData, 2)
	
		client_cmd(id, "spk sound/%s", g_SoundFile[SOUND_MENU_SELECT]);
	}
	else if(item == 1)
		ShowDeleteTurretMenu(id, iTurretIndex);
	else if(item == 2)
	{
		new entlist[2];
		if(!find_sphere_class(id, "turret", 60.0, entlist, 1))
		{
			client_print(id, print_center, "You must stay near your [activated] turret!");
			ShowTurretMenu(id, iTurretIndex);
			return PLUGIN_CONTINUE;
		}

		else if(entlist[0] != iTurretEntity)
		{
			client_print(id, print_center, "You are staying near wrong turret!");
			ShowTurretMenu(id, iTurretIndex);
			return PLUGIN_CONTINUE;
		}
		g_PlayerTouchingTurret[id] = 0;
		
		new Float:fOldOrigin[3]
		entity_get_vector(iTurretEntity, EV_VEC_origin, fOldOrigin);
		entity_set_vector(iTurretEntity, EV_VEC_turret_old_origin, fOldOrigin);
		
		
		CreateMoveEntity(iTurretEntity);
		
		CreateTurretMoveEffect(id, iTurretEntity, g_TurretsRangeData[iTurretType][g_PlayerTurretRangeLevel[id][iTurretIndex]], iTurretType, g_PlayerTurretRangeLevel[id][iTurretIndex]);
		ShowMenuMoveTurret(id, iTurretIndex);
		
		return PLUGIN_CONTINUE;
	}
	else if(item == 3)
	{
		client_cmd(id, "setinfo _tcn true");
		client_cmd(id, "setinfo _tindex %d", iTurretIndex);
		client_cmd(id, "messagemode turret_change_name");
	}
	else if(item == 4)
		ShowMenuUpgradeTurret(id, iTurretIndex);

	return PLUGIN_CONTINUE;
}

public ShowMenuUpgradeTurret(id, iTurretIndex)
{
	client_cmd(id, "spk sound/%s", g_SoundFile[SOUND_MENU_SELECT]);
	
	static szFormat[256], szTurretName[33];
	
	new iEnt = g_PlayerTurretEnt[id][iTurretIndex];
	new iTurretType = entity_get_int(iEnt, EV_INT_turret_type)
	entity_get_string(iEnt, EV_SZ_turret_name, szTurretName, 32);
	
	new iTurretDamageLevel = g_PlayerTurretDamageLevel[id][iTurretIndex]
	new iTurretRangeLevel = g_PlayerTurretRangeLevel[id][iTurretIndex]
	new iTurretAccuracyLevel = g_PlayerTurretAccuracyLevel[id][iTurretIndex]
	new iTurretFireRateLevel = g_PlayerTurretFireRateLevel[id][iTurretIndex]
	new Float:fTime = ((g_TurretsFreqData[iTurretType] / 100.0) * (g_TurretsFireRateData[iTurretType][iTurretFireRateLevel] / 100.0));

	CreateTurretRanger(id, iEnt, iTurretRangeLevel);
	
	formatex(szFormat, 255, "\r[\y %s \r] [\y %s\r ]^n[ \yTurret level: \w%d\r ]^n[ \yDamage: \w%d\y ~\w %d\r ] [ \yRange:\w %d\r ]^n[ \yAccuracy: \w%d%%\r ] [\yFirerate: \w%0.2fs\r ]", 
	g_TurretsName[iTurretType],szTurretName,
	entity_get_int(iEnt, EV_INT_turret_level),
	g_TurretsDamageData[iTurretType][iTurretDamageLevel][0], g_TurretsDamageData[iTurretType][iTurretDamageLevel][1],
	g_TurretsRangeData[iTurretType][iTurretRangeLevel], g_TurretsAccuracyData[iTurretType][iTurretAccuracyLevel], fTime)

	new menu = menu_create(szFormat, "ShowMenuUpgradeTurretH")
	new cb = menu_makecallback("ShowMenuUpgradeTurretCb")
	
	new szData[4]
	num_to_str(iTurretIndex, szData, 3)

	if(iTurretDamageLevel + 1 == g_TurretsMaxLevelData[iTurretType][0])
		menu_additem(menu, "Increase Damage\r [ \yMAX \w~ \yMAX \r]", szData,_,cb)
	else 
	{
		iTurretDamageLevel++;
		formatex(szFormat,   charsmax(szFormat), "Increase Damage\r [ \y%d\w gold\r ] [\w +\y%d \w~ \w+\y%d\r ]",
		g_TurretsPriceData[iTurretType][iTurretDamageLevel],
		(g_TurretsDamageData[iTurretType][iTurretDamageLevel][0] - g_TurretsDamageData[iTurretType][iTurretDamageLevel - 1][0]), 
		(g_TurretsDamageData[iTurretType][iTurretDamageLevel][1] - g_TurretsDamageData[iTurretType][iTurretDamageLevel - 1][1]))
		
		menu_additem(menu, szFormat, szData,_,cb)
	}
	
	if(iTurretRangeLevel + 1 == g_TurretsMaxLevelData[iTurretType][1])
		menu_additem(menu, "Increase Range\r [ \yMAX\r ]", _,_,cb)
	else
	{
		iTurretRangeLevel++;
		
		formatex(szFormat,   charsmax(szFormat), "Increase Range\r [ \y%d\w gold\r ] [\w + \y%d\r ]",
		g_TurretsPriceData[iTurretType][iTurretRangeLevel],
		(g_TurretsRangeData[iTurretType][iTurretRangeLevel] - g_TurretsRangeData[iTurretType][iTurretRangeLevel - 1]))
		
		menu_additem(menu, szFormat,_,_,cb)
	}

	if(iTurretAccuracyLevel + 1 == g_TurretsMaxLevelData[iTurretType][2])
		menu_additem(menu, "Increase Accuracy\r [ \yMAX\r ]", _,_,cb)
	else
	{
		iTurretAccuracyLevel++;
		
		formatex(szFormat,   charsmax(szFormat), "Increase Accuracy\r [ \y%d\w gold\r ] [\w + \y%d%%\r ]",
		g_TurretsPriceData[iTurretType][iTurretAccuracyLevel],
		(g_TurretsAccuracyData[iTurretType][iTurretAccuracyLevel] - g_TurretsAccuracyData[iTurretType][iTurretAccuracyLevel - 1]))
		
		menu_additem(menu, szFormat,_,_,cb)
	}

	if(iTurretFireRateLevel + 1 == g_TurretsMaxLevelData[iTurretType][3])
		menu_additem(menu, "Increase Firerate\r [ \yMAX\r ]", _,_,cb)
	else
	{
		iTurretFireRateLevel++;

		new Float:fTime2 = ((g_TurretsFreqData[iTurretType] / 100.0) * (g_TurretsFireRateData[iTurretType][iTurretFireRateLevel] / 100.0));
			
		formatex(szFormat,   charsmax(szFormat), "Increase Firerate\r [ \y%d\w gold\r ] [\w -\y%0.2fs\r ]",
		g_TurretsPriceData[iTurretType][iTurretFireRateLevel],
		 (fTime - fTime2));
		
		menu_additem(menu, szFormat,_,_,cb)
	}
	
	if(g_PlayerTouchingTurret[id] != iEnt)
		menu_setprop(menu, MPROP_EXITNAME, "Back")
	
	menu_display(id, menu)

	return PLUGIN_CONTINUE
}

public ShowMenuUpgradeTurretCb(id, menu, item) 
{
	new cb, acces, szName[3], szData[4]
	menu_item_getinfo(menu, 0, acces, szData, 3, szName, 2, cb)
	
	new iTurretIndex = str_to_num(szData);
	new iEnt = g_PlayerTurretEnt[id][iTurretIndex];
	new iTurretType = entity_get_int(iEnt, EV_INT_turret_type)
	
	if(item == 0)
	{
		if((g_PlayerTurretDamageLevel[id][iTurretIndex] + 1 )>= g_TurretsMaxLevelData[iTurretType][0])
			return ITEM_DISABLED
		if(td_get_user_info(id, PLAYER_GOLD) < g_TurretsPriceData[iTurretType][g_PlayerTurretDamageLevel[id][iTurretIndex] + 1])
			return ITEM_DISABLED
	}
	else if(item == 1)
	{
		if(g_PlayerTurretRangeLevel[id][iTurretIndex] + 1 >= g_TurretsMaxLevelData[iTurretType][1])
			return ITEM_DISABLED
		
		if(td_get_user_info(id, PLAYER_GOLD) < g_TurretsPriceData[iTurretType][g_PlayerTurretRangeLevel[id][iTurretIndex] + 1 ])
			return ITEM_DISABLED
	} 
	else if(item == 2)
	{
		if(g_PlayerTurretAccuracyLevel[id][iTurretIndex] + 1 >= g_TurretsMaxLevelData[iTurretType][2])
			return ITEM_DISABLED
		
		if(td_get_user_info(id, PLAYER_GOLD) < g_TurretsPriceData[iTurretType][g_PlayerTurretAccuracyLevel[id][iTurretIndex] + 1 ])
			return ITEM_DISABLED
	}
	else if(item == 3)
	{
		if(g_PlayerTurretFireRateLevel[id][iTurretIndex] + 1 >= g_TurretsMaxLevelData[iTurretType][3])
			return ITEM_DISABLED

		if(td_get_user_info(id, PLAYER_GOLD) < g_TurretsPriceData[iTurretType][g_PlayerTurretFireRateLevel[id][iTurretIndex] + 1 ])
			return ITEM_DISABLED
	}
	
	return ITEM_ENABLED
}

public ShowMenuUpgradeTurretH(id, menu, item) {	
	new cb, acces, szName[3], szDataItem[4]
	menu_item_getinfo(menu, 0, acces, szDataItem, 3, szName, 2, cb)
	
	new iTurretIndex = str_to_num(szDataItem);
	new iEnt  = g_PlayerTurretEnt[id][iTurretIndex];
	
	if(item == MENU_EXIT) 
	{
		if(g_PlayerTouchingTurret[id] == iEnt)
			return PLUGIN_CONTINUE
		
		ShowTurretMenu(id, iTurretIndex);	
	}
	
	if(item == 0) // damage
		td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_TurretsPriceData[entity_get_int(g_PlayerTurretEnt[id][iTurretIndex], EV_INT_turret_type)][++ g_PlayerTurretDamageLevel[id][iTurretIndex] ])
	else if(item == 1) 	// range
		td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_TurretsPriceData[entity_get_int(g_PlayerTurretEnt[id][iTurretIndex], EV_INT_turret_type)][ ++ g_PlayerTurretRangeLevel[id][iTurretIndex] ])
	else if(item == 2)	// accuracy
		td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_TurretsPriceData[entity_get_int(g_PlayerTurretEnt[id][iTurretIndex], EV_INT_turret_type)][++ g_PlayerTurretAccuracyLevel[id][iTurretIndex] ])	
	else if(item == 3)
		td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_TurretsPriceData[entity_get_int(g_PlayerTurretEnt[id][iTurretIndex], EV_INT_turret_type)][++ g_PlayerTurretFireRateLevel[id][iTurretIndex] ])	
	
	new Float:fUpgradeTime =  g_ConfigValuesFloat[CFG_FLOAT_TURRET_UPGRADE_TIME] - g_PlayerExtraTaskTime[id];
	if(fUpgradeTime <= 0.0)
		fUpgradeTime = 0.1;
	g_IsTurretUpgrading[id][iTurretIndex] = true;
	g_PlayerTouchingTurret[id] = 0;
	ColorChat(id, GREEN, "%s^x01 Upgrading turret... [ %0.1f seconds ]", CHAT_PREFIX, fUpgradeTime);
	
	entity_set_string(iEnt, EV_SZ_classname, "turret_upgrading")
	new szData[4]; szData[0] = id;szData[1] = item; szData[2] = iTurretIndex
	set_task(fUpgradeTime, "UpgradeTurretTaskInfo",iEnt +  TASK_UPGRADE_TURRET, szData, 3)
	
	DestroyTurretRanger(iEnt);
	
	return PLUGIN_CONTINUE
}

public UpgradeTurretTaskInfo(szData[], iTask) {
	/* 
		szData[0] = id
		szData[1] = item
		szData[2] = iTurretIndex
	*/
	new id = szData[0]
	new item = szData[1] // 0 - damage | 1 - range | 2 - accuracy
	new iTurretIndex = szData[2]
	new iEnt = iTask - TASK_UPGRADE_TURRET//g_PlayerTurretEnt[id][iTurretIndex];
	new iTurretType = entity_get_int(iEnt, EV_INT_turret_type)
	new szTurretName[33];
	new iOldLevel= entity_get_int(iEnt, EV_INT_turret_level);
	
	entity_get_string(iEnt, EV_SZ_turret_name, szTurretName, 32);
	
	if(entity_get_int(iEnt, EV_INT_turret_ammo) > 0)
		entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.0)

	emit_sound(iEnt, CHAN_AUTO, g_SoundFile[SOUND_TURRET_READY], 1.0, 2.3, 0, PITCH_NORM);
	
	g_IsTurretUpgrading[id][iTurretIndex] = false;
	
	if(item == 0) 
		ColorChat(id, GREEN, "%s^x01 Your '%s' turret takes from now %d - %d damage.",CHAT_PREFIX, szTurretName, g_TurretsDamageData[iTurretType][g_PlayerTurretDamageLevel[id][iTurretIndex]][0], g_TurretsDamageData[iTurretType][g_PlayerTurretDamageLevel[id][iTurretIndex]][1])
	else if(item == 1)
		ColorChat(id, GREEN, "%s^x01 Your '%s' turret now can shoot in %d units range", CHAT_PREFIX, szTurretName,  g_TurretsRangeData[iTurretType][ g_PlayerTurretRangeLevel[id][iTurretIndex] ])		
	else if(item == 2)
		ColorChat(id, GREEN, "%s^x01 Your '%s' turret now have %d%% accurancy", CHAT_PREFIX, szTurretName,  g_TurretsAccuracyData[iTurretType][ g_PlayerTurretAccuracyLevel[id][iTurretIndex] ])		

	new iNewLevel, iDivider;
	iNewLevel += g_PlayerTurretDamageLevel[id][iTurretIndex] 	+ 1;
	iNewLevel += g_PlayerTurretRangeLevel[id][iTurretIndex] 	+ 1;
	iNewLevel += g_PlayerTurretAccuracyLevel[id][iTurretIndex] 	+ 1;
	iNewLevel += g_PlayerTurretFireRateLevel[id][iTurretIndex]	+ 1;
	
	iDivider += g_TurretsMaxLevelData[iTurretType][0] 
	iDivider += g_TurretsMaxLevelData[iTurretType][1]
	iDivider += g_TurretsMaxLevelData[iTurretType][2]
	iDivider += g_TurretsMaxLevelData[iTurretType][3]

	iNewLevel = floatround( ((float(iNewLevel) / iDivider ) * TURRETS_MODELS_LEVEL), floatround_floor);
	
	entity_set_int(iEnt, EV_INT_turret_level, iNewLevel)
	entity_set_string(iEnt, EV_SZ_classname, "turret")
	
	if(iOldLevel !=  iNewLevel)
	{
		client_cmd(id, "spk %s", g_SoundFile[SOUND_TURRET_LEVELUP]);
		emit_sound(iEnt, CHAN_AUTO, g_SoundFile[SOUND_TURRET_LEVELUP], 1.5, 2.3, 0, PITCH_NORM);
		
		ColorChat(id, GREEN, "%s^x01 Your '%s' turret earned %d level", CHAT_PREFIX, szTurretName, iNewLevel)
		SetTurretModelByLevel(iEnt, iNewLevel)
	}
	
	new szData[3]; szData[0] = iTurretIndex; szData[1] = id
	set_task(0.1, "OpenTurretUpgradeMenuPost", iEnt + TASK_OPEN_TURRET_MENU, szData, 2);
}

public OpenTurretUpgradeMenuPost(params[], iEnt)
	if(g_PlayerTouchingTurret[params[1]] == iEnt - TASK_OPEN_TURRET_MENU)
		ShowMenuUpgradeTurret(params[1], params[0]);

public OpenTurretMenuIfStayingNear(params[], iEnt)
	if(g_PlayerTouchingTurret[params[1]] == iEnt - TASK_OPEN_TURRET_MENU)
		ShowTurretMenu(params[1], params[0]);

public ShowMenuMoveTurret(id, iTurretIndex)
{
	new iMenu ;
	
	if(g_TurretsMaxLevelData[  entity_get_int( g_PlayerTurretEnt[id][iTurretIndex], EV_INT_turret_type)][1] == 1) 
		iMenu = menu_create("Where do you want to move this turret?^n\rWARNING!\w On this map is only one level of range!", "ShowMenuMoveTurretH")
	else
		iMenu = menu_create("Where do you want to move this turret?", "ShowMenuMoveTurretH")
	
	new szData[4];
	num_to_str(iTurretIndex, szData, 3)
	
	menu_additem(iMenu, "Move turret here", szData)
	menu_additem(iMenu, "Back")
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu);
}

public ShowMenuMoveTurretH(id, menu, item)
{
	new acces, szTurretIndex[4], szType[33], cb
	menu_item_getinfo(menu, 0, acces, szTurretIndex, 3, szType, 32, cb)
	
	new iTurretIndex = str_to_num(szTurretIndex)
	new iEnt = g_PlayerMovingTurretEntity[id] ;

	entity_get_string(iEnt, EV_SZ_turret_name, szType, 32);
	
	static Float:fActivateTime;
	if(!fActivateTime)
		fActivateTime = g_ConfigValuesFloat[CFG_FLOAT_MOVE_INSTALL_TIME];
	
	if(td_get_user_info(id, PLAYER_GOLD) < g_ConfigValues[CFG_TURRET_MOVE_COST] )
	{
		client_print(id, print_center, "You don't have %d gold", g_ConfigValues[CFG_TURRET_MOVE_COST] );
		goto removeEffect;
	}
	
	if(item == MENU_EXIT || !is_user_alive(id) || item == 1)
	{	
		ColorChat(id, GREEN, "%s^x01 You decided not to move your '%s' turret. [Activate time: %0.1f]", CHAT_PREFIX, szType, fActivateTime);
		
		removeEffect:
		
		// When player moving turret and he decide to not move, set old origin */
		g_PlayerMovingTurretEntity[id] = 0;
	
		entity_set_string(iEnt,	 EV_SZ_classname, "turret");
		entity_set_int(iEnt, 	EV_INT_solid, SOLID_TRIGGER)
		
		fm_set_rendering(iEnt, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
		
		new Float:fOldOrigin[3]
		entity_get_vector(iEnt, EV_VEC_turret_old_origin, fOldOrigin);
		
		entity_set_origin(iEnt, fOldOrigin);
		entity_set_vector(iEnt, EV_VEC_turret_old_origin, Float:{0.0, 0.0, 0.0});
		
		emit_sound(iEnt, CHAN_AUTO, g_SoundFile[SOUND_TURRET_PLANT], 1.0, 0.7, 0, PITCH_NORM);
		
		RemoveMoveEntity(iEnt);
		
		set_task(fActivateTime, "PlayerMoveTurretTaskInfo", iEnt + TASK_MOVE_TURRET, szType, 32);
		
		SetTurretModelByLevel(iEnt, entity_get_int(iEnt, EV_INT_turret_level));
		DestroyTurretRanger(iEnt);
		return PLUGIN_CONTINUE
	}
	
	new Float:fOrigin[3], entlist[3];
	entity_get_vector(iEnt, EV_VEC_origin, fOrigin)

	if(find_sphere_class(iEnt, "turret", 60.0, entlist, 2)
	|| find_sphere_class(iEnt, "turret_reloading", 60.0, entlist, 2)
	|| find_sphere_class(iEnt, "turret_upgrading", 60.0, entlist, 2))
	{
		client_print(id, print_center,"You cannot create turret near other turret");
		ShowMenuMoveTurret(id, iTurretIndex)
		return PLUGIN_CONTINUE
	}
	else if(find_sphere_class(iEnt, "func_illusionary", 10.0, entlist, 2) || !fm_is_ent_visible(id, iEnt)) {
		client_print(id, print_center, "You cannot create turret here")
		ShowMenuMoveTurret(id, iTurretIndex)
		return PLUGIN_CONTINUE
	}
	else if(find_sphere_class(iEnt, "slot_reservation", 60.0, entlist, 2)  &&iEnt!= entity_get_int(entlist[0], EV_INT_place_owner))
	{
		//entlist[0] - index of turret enity place owner
		new szName[33], szTurretName[33];
		get_user_name(entity_get_edict(entity_get_int(entlist[0], EV_INT_place_owner), EV_ENT_turret_owner), szName, 32);
		entity_get_string(entity_get_int(entlist[0], EV_INT_place_owner), EV_SZ_turret_name, szTurretName ,32);
		
		client_print(id, print_center, "This place is taken by '%s' turret [%s is moving turret]", szTurretName, szName)
		ShowMenuMoveTurret(id, iTurretIndex)
		return PLUGIN_CONTINUE
	}
	
	g_PlayerMovingTurretEntity[id] = 0;
	td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) - g_ConfigValues[CFG_TURRET_MOVE_COST] )
	
	entity_set_string(iEnt, 	EV_SZ_classname, "turret");
	entity_set_int(iEnt, 		EV_INT_solid, SOLID_TRIGGER)
	fm_set_rendering(iEnt, 		kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	SetTurretModelByLevel(iEnt, 	entity_get_int(iEnt, EV_INT_turret_level));
	RemoveMoveEntity(iEnt);
	entity_set_vector(iEnt, 	EV_VEC_turret_old_origin, Float:{0.0, 0.0, 0.0});
	
	emit_sound(iEnt, CHAN_AUTO, g_SoundFile[SOUND_TURRET_PLANT], 1.0, 0.7, 0, PITCH_NORM);
	
	ColorChat(id, GREEN, "%s^x01 You moved your '%s' turret. [Activate time: %0.1f]", CHAT_PREFIX, szType, fActivateTime);
	set_task(fActivateTime, "PlayerMoveTurretTaskInfo", iEnt + TASK_MOVE_TURRET, szType, 32);
	
	DestroyTurretRanger(iEnt);
	return PLUGIN_CONTINUE;
}

public SetTurretModelByLevel(iEnt, iLevel)
{
	new szModel[64];
	formatex(szModel, 63, "models/TD/sentrygun_%d.mdl", iLevel)
	entity_set_model(iEnt, szModel);
}
public CreateMoveEntity(iEnt)
{
	new Float:fOrigin[3];
	
	entity_get_vector(iEnt, EV_VEC_origin, fOrigin);
	
	new tmpEnt = create_entity("info_target");
	entity_set_string(tmpEnt, EV_SZ_classname, "slot_reservation");
	entity_set_origin(tmpEnt, fOrigin);
	entity_set_int(tmpEnt, EV_INT_place_owner, iEnt);
	entity_set_int(iEnt, EV_INT_turret_move_entity, tmpEnt);
}

public RemoveMoveEntity(iEnt)
{
	remove_entity( entity_get_int(iEnt, EV_INT_turret_move_entity) )
	entity_set_int(iEnt, EV_INT_turret_move_entity, 0);
}

public PlayerMoveTurretTaskInfo(szTurretName[], iEnt)
{
	iEnt -= TASK_MOVE_TURRET;
	new id = GetTurretOwner(iEnt);
	
	ColorChat(id, GREEN, "%s^x01 '%s' turret is ready!", CHAT_PREFIX, szTurretName);
	
	g_IsTurretUpgrading[ id ][ entity_get_int(iEnt, EV_INT_turret_index) ] = false;
	
	/* Make turret touchable again */
	entity_set_size(iEnt, Float:{-16.0, -16.0, 0.0}, Float:{16.0, 16.0, 48.0});
	if(entity_get_int(iEnt, EV_INT_turret_ammo) > 0)
		entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.0);
		
	emit_sound(iEnt, CHAN_AUTO, g_SoundFile[SOUND_TURRET_READY], 1.0, 2.3, 0, PITCH_NORM);
	
	if(g_PlayerTouchingTurret[id] == iEnt)
		ShowTurretMenu(id,  entity_get_int(iEnt, EV_INT_turret_index));
}
public ShowDeleteTurretMenu(id, iTurretIndex)
{
	new szTitle[128];
	
	new szTurretInfo[2][4];
	num_to_str(iTurretIndex, szTurretInfo[0], 3);
	
	if(g_ConfigValues[CFG_TURRET_REMOVE_CHARGE_BACK])
	{
		new iEnt = g_PlayerTurretEnt[id][iTurretIndex];
		
		new iTurretType 	= entity_get_int(iEnt, EV_INT_turret_type);
		new iTurretCost 	= g_TurretsPriceData[ iTurretType ][0];
		
		new iDamageLevel 	= g_PlayerTurretDamageLevel[id][iTurretIndex];
		new iRangeLevel 	= g_PlayerTurretRangeLevel[id][iTurretIndex];
		new iAccuracyLevel	= g_PlayerTurretAccuracyLevel[id][iTurretIndex];
		new iFireRateLevel	= g_PlayerTurretFireRateLevel[id][iTurretIndex];
		
		for(new i = 1; i < iDamageLevel ; i++)
			iTurretCost +=  g_TurretsPriceData[iTurretType][i]
		for(new i = 1; i < iRangeLevel ; i++)
			iTurretCost +=  g_TurretsPriceData[iTurretType][i]
		for(new i = 1; i < iAccuracyLevel ; i++)
			iTurretCost +=  g_TurretsPriceData[iTurretType][i]
		for(new i = 1; i < iFireRateLevel ; i++)
			iTurretCost +=  g_TurretsPriceData[iTurretType][i]
					
		/* All costs for buying turret */
		for(new i ; i < entity_get_int(iEnt, EV_INT_turret_level) ; i++)
		{
			if(g_PlayerTurretRangeLevel[id][iTurretIndex] == i+1)
				iTurretCost += g_TurretsPriceData[iTurretType][i];
			if(g_PlayerTurretDamageLevel[id][iTurretIndex] == i+1)
				iTurretCost += g_TurretsPriceData[iTurretType][i];
			if(g_PlayerTurretAccuracyLevel[id][iTurretIndex] == i+1)
				iTurretCost += g_TurretsPriceData[iTurretType][i];
			if(g_PlayerTurretFireRateLevel[id][iTurretIndex] == i+1)
				iTurretCost += g_TurretsPriceData[iTurretType][i];
		}
		
		iTurretCost = floatround( iTurretCost * g_ConfigValuesFloat[CFG_FLOAT_CHARGE_BACK_MLTP] );
		num_to_str(iTurretCost, szTurretInfo[1], 3);
		
		formatex(szTitle, 127, "Delete turret confirm:^n\rAre you sure? You will get back %d gold", iTurretCost);
	}
	else
		formatex(szTitle, 127, "Delete turret confirm:^n\rAre you sure?");
	
	new menu = menu_create(szTitle, "ShowDeleteTurretMenuH");
	menu_additem(menu, "\yYes", szTurretInfo[0]);
	menu_additem(menu, "Back", szTurretInfo[1]);
	
	menu_display(id, menu);
}

public ShowDeleteTurretMenuH(id, menu, item)
{
	new cb, acces, szName[3], szInfo[2][4]
	menu_item_getinfo(menu, 0, acces, szInfo[0], 3, szName, 2, cb)
	menu_item_getinfo(menu, 1, acces, szInfo[1], 3, szName, 2, cb)
	
	new szTurretInfo[2];
	szTurretInfo[0] = str_to_num(szInfo[0]);
	szTurretInfo[1] = str_to_num(szInfo[1]);
	
	/*
		szTurretInfo[0] = iTurretIndex
		szTurretInfo[1] = iTurretCost
	*/
	
	if(item == MENU_EXIT || item == 1)
	{
		menu_destroy(menu);
		
		if(!g_PlayerTouchingTurret[id])
			ShowTurretMenu(id, szTurretInfo[0]);
		return;
	}
	
	/* Player wants to delete turret */
	new szTurretName[33];
	new iEnt = g_PlayerTurretEnt[id][szTurretInfo[0]];
	
	entity_get_string(iEnt, EV_SZ_turret_name, szTurretName, 32);
	
	if(szTurretInfo[1] > 0)
	{
		td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) + szTurretInfo[1]);
		ColorChat(id, GREEN, "%s^x01 You has just deleted your turret (%s) and got %d gold back.", CHAT_PREFIX, szTurretName, szTurretInfo[1]);
	}
	else
		ColorChat(id, GREEN, "%s^x01 You has just deleted your turret (%s)", CHAT_PREFIX, szTurretName);

	g_PlayerTouchingTurret[id] = 0;
	DeleteTurret(iEnt, id, szTurretInfo[0]);
}

stock DeleteTurret(iEnt, id = 0, iTurretIndex = -1)
{
	if(!id)
		id = GetTurretOwner(iEnt)
	
	if(iTurretIndex == -1)
		iTurretIndex = entity_get_int(iEnt, EV_INT_turret_index);

	g_PlayerAlarmStatus[id][iTurretIndex] = false;
	g_IsTurretUpgrading[id][iTurretIndex] = false;
	
	g_PlayerTurretEnt[id][iTurretIndex] = 0
	g_PlayerTurretDamageLevel[id][iTurretIndex] = 0;
	g_PlayerTurretRangeLevel[id][iTurretIndex] = 0;
	g_PlayerTurretAccuracyLevel[id][iTurretIndex] = 0;
	g_PlayerTurretFireRateLevel[id][iTurretIndex] = 0;
	
	g_PlayerTurretsNum[id]--;
	g_ServerTurretsNum--;

	
	new Float:fOrigin[3]
	new iOrigin[3];
	entity_get_vector(iEnt, EV_VEC_origin, fOrigin);
	
	FVecIVec(fOrigin, iOrigin);
	MakeLavaSplashEffect(iOrigin);
	
	new iRanger = entity_get_edict(iEnt, EV_ENT_turret_ranger);
	
	if(is_valid_ent(iRanger))
		remove_entity(iRanger);
	
	remove_entity(iEnt);
}

public client_disconnected(id)
{
	/* Removing user information and his turrets */
	
	new iOrigin[3];
	get_user_origin(id, iOrigin);
	
	if(is_user_alive(id))
		MakeLavaSplashEffect(iOrigin);

	new iEnt;
	
	for(new i; i < MAX_PLAYER_TURRETS ; i++)
	{
		iEnt = g_PlayerTurretEnt[id][i]
		
		if(is_valid_ent(iEnt))
			DeleteTurret(iEnt, 0, i);
		
		g_PlayerBoughtSlot[id][i] 	= false
	}
	
	g_PlayerTurretsNum[id]		= 0
	g_PlayerMovingTurretEntity[id]	= 0
	g_PlayerAmmoAlarmValue[id]	= 75
	g_PlayerTouchingTurret[id]	= 0
	g_PlayerExtraTaskTime[id]	= 0.0
	g_PlayerTurretShowingOption[id] = TURRET_SHOW_TRANSPARENT;
	
	if(g_PlayerTotems[id] > _:TOTEMS)
	{
		ResetTotemEffectForTurrets(g_PlayerTotems[id]);
		remove_entity(g_PlayerTotems[id]);
	}
	g_PlayerTotems[id] = 0;
}

public client_connect(id)
{
	g_PlayerAmmoAlarmValue[id] 	= 75
	g_PlayerTurretShowingOption[id] = TURRET_SHOW_TRANSPARENT;
}
public MessageModeTurretChangeName(id)
{
	new szAccessCode[6];
	get_user_info(id, "_tcn", szAccessCode, 5);
	
	if(!equali(szAccessCode, "true"))
	{
		ColorChat(id, GREEN, "%s^x01 You don't have access. Please go to turret menu.", CHAT_PREFIX);
		return PLUGIN_HANDLED;
	}
	
	new iPlayerGold = td_get_user_info(id, PLAYER_GOLD);
	new iCost = g_ConfigValues[CFG_TURRET_CHANGE_NAME_COST];
	
	if(iPlayerGold < iCost)
	{
		ColorChat(id,GREEN, "%s^x01 You don't have %d gold.", CHAT_PREFIX, iCost);
		return PLUGIN_HANDLED
	}
	client_cmd(id, "setinfo _tcn false");
	
	new szNewTurretName[33];
	read_args(szNewTurretName, 32)
	remove_quotes(szNewTurretName)
	
	get_user_info(id, "_tindex", szAccessCode, 5);
	new iTurretIndex = str_to_num(szAccessCode);
	
	if(strlen(szNewTurretName) < 4)
	{
		ColorChat(id,GREEN, "%s^x01 Turret must have at least 4 chars.", CHAT_PREFIX);
		ShowTurretMenu(id, iTurretIndex);
		return PLUGIN_HANDLED
	}
	
	new szOldName[33];
	entity_get_string(g_PlayerTurretEnt[id][iTurretIndex], EV_SZ_turret_name, szOldName, 32);
	
	ColorChat(id,GREEN, "%s^x01 You changed turret name from '%s' to '%s'", CHAT_PREFIX, szOldName, szNewTurretName);
	
	entity_set_string(g_PlayerTurretEnt[id][iTurretIndex], EV_SZ_turret_name, szNewTurretName);
	td_set_user_info(id,PLAYER_GOLD, iPlayerGold - iCost);
	
	ShowTurretMenu(id, iTurretIndex);
	return PLUGIN_HANDLED;
}

public TurretReloadTaskEnd(params[], iTurretEntity)
{
	iTurretEntity -= TASK_RELOAD_TURRET
	/*
		params[0] = id
		params[1] = iTurretIndex
	*/
	new id = params[0];
	new iTurretIndex = params[1];
	new szTurretName[33];
	g_IsTurretUpgrading[id][iTurretIndex] = false
	
	entity_set_string(iTurretEntity, EV_SZ_classname, "turret")
	entity_set_size(iTurretEntity, Float:{-16.0, -16.0, 0.0}, Float:{16.0, 16.0, 48.0});
	
	entity_get_string(iTurretEntity, EV_SZ_turret_name, szTurretName, 32);
	
	entity_set_float(iTurretEntity, EV_FL_nextthink, get_gametime() + 1.0);
	emit_sound(iTurretEntity, CHAN_AUTO, g_SoundFile[SOUND_TURRET_READY], 1.0, 1.3, 0, PITCH_NORM)
	
	//g_PlayerTurretIsUpgrading[id][iTurretIndex] = false
	ColorChat(id, GREEN, "%s^x01 Turret '%s' has been reloaded! [Current ammo: %d]", CHAT_PREFIX, szTurretName, entity_get_int(iTurretEntity, EV_INT_turret_ammo))
	
	new szData[3]; szData[0] = iTurretIndex; szData[1] = id
	set_task(0.1, "OpenTurretMenuIfStayingNear", iTurretEntity + TASK_OPEN_TURRET_MENU, szData, 2);
}


public LoadSounds() 
{
	if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: Loading sounds...")
		
	new szText[128], len;
	new szTemp[3][128];
	
	if(!file_exists(SOUND_CONFIG_FILE)) 
	{
		log_to_file(LOG_FILE, "TURRETS: Sounds configuration file '%s' not found...", SOUND_CONFIG_FILE)
		return PLUGIN_CONTINUE
	}
	
	new szDir[128];
	
	for(new i ; read_file(SOUND_CONFIG_FILE, i, szText, 127, len) ; i++)
	{
		if(equali(szText, ";", 1) || !strlen(szText) || !equali(szText, "TURRET", 6))
			continue;
			
		parse(szText, szTemp[0], 127, szTemp[1], 16, szTemp[2], 127)
		remove_quotes(szTemp[2]);
		
		if(DEBUG_T)
		{
			log_to_file(LOG_FILE, "DEBUG_T: Sound : '%s' | value: '%s'", szTemp[0], szTemp[2]);
			formatex(szDir, 127, "sound/%s", szTemp[2]);
			
			if(!file_exists(szDir))
				log_to_file(LOG_FILE, "DEBUG_T: Error - this sound is not exist");
		}
		
		if(equali(szTemp[0], "TURRET_BULLET_FIRE_1")) 
			copy(g_SoundFile[SOUND_TURRET_BULLET_FIRE_1], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_BULLET_FIRE_2")) 
			copy(g_SoundFile[SOUND_TURRET_BULLET_FIRE_2], 127, szTemp[2])
			
		else if(equali(szTemp[0], "TURRET_LASER_FIRE_1")) 
			copy(g_SoundFile[SOUND_TURRET_LASER_FIRE_1], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_LASER_FIRE_2")) 
			copy(g_SoundFile[SOUND_TURRET_LASER_FIRE_2], 127, szTemp[2])
			
		else if(equali(szTemp[0], "TURRET_LIGHTING_FIRE_1")) 
			copy(g_SoundFile[SOUND_TURRET_LIGHTING_FIRE_1], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_LIGHTING_FIRE_2")) 
			copy(g_SoundFile[SOUND_TURRET_LIGHTING_FIRE_2], 127, szTemp[2])

		else if(equali(szTemp[0], "TURRET_M_LASER_FIRE_1")) 
			copy(g_SoundFile[SOUND_TURRET_M_LASER_FIRE_1], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_M_LASER_FIRE_2")) 
			copy(g_SoundFile[SOUND_TURRET_M_LASER_FIRE_2], 127, szTemp[2])

		else if(equali(szTemp[0], "TURRET_ROCKET_FIRE_1")) 
			copy(g_SoundFile[SOUND_TURRET_ROCKET_FIRE_1], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_ROCKET_FIRE_2")) 
			copy(g_SoundFile[SOUND_TURRET_ROCKET_FIRE_2], 127, szTemp[2])

		else if(equali(szTemp[0], "TURRET_GATLING_FIRE_1")) 
			copy(g_SoundFile[SOUND_TURRET_GATLING_FIRE_1], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_GATLING_FIRE_2")) 
			copy(g_SoundFile[SOUND_TURRET_GATLING_FIRE_2], 127, szTemp[2])
			
		else if(equali(szTemp[0], "TURRET_START_FIRE")) 
			copy(g_SoundFile[SOUND_TURRET_START_FIRE], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_STOP_FIRE")) 
			copy(g_SoundFile[SOUND_TURRET_STOP_FIRE], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_PLANT")) 
			copy(g_SoundFile[SOUND_TURRET_PLANT], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_LOW_AMMO")) 
			copy(g_SoundFile[SOUND_TURRET_LOWAMMO], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_NO_AMMO")) 
			copy(g_SoundFile[SOUND_TURRET_NOAMMO], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_MENU_SELECT")) 
			copy(g_SoundFile[SOUND_MENU_SELECT], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_READY")) 
			copy(g_SoundFile[SOUND_TURRET_READY], 127, szTemp[2])
		else if(equali(szTemp[0], "TURRET_LEVELUP"))
			copy(g_SoundFile[SOUND_TURRET_LEVELUP], 127, szTemp[2]);
	}
	
	if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: Loading sounds finished");
		
	return PLUGIN_CONTINUE
}

public LoadTurretsConfig(szMapName[])
{
	if(DEBUG_T)
		log_to_file(LOG_FILE, "DEBUG_T: Loading turrets config from '%s/%s.cfg'", TURRETS_CONFIG_PATH, szMapName);
		
	new szText[64], len
	new szData[64], iData[2][6]
	new szFormat[64]
	new iMaxLevel[ENUM_TURRETS_TYPE][4] ;
	
	new szDir[80];
	formatex(szDir, charsmax(szDir), "%s/%s.cfg", TURRETS_CONFIG_PATH, szMapName);
	
	if(!file_exists(szDir)) 
	{
		if(DEBUG_T)
			log_to_file(LOG_FILE, "DEBUG_T: Turrets config file is not exist. Attempt to load default config file '%s'", TURRETS_DEFAULT_CONFIG_FILE);
		
		formatex(szDir, charsmax(szDir), "%s/%s", TURRETS_CONFIG_PATH, TURRETS_DEFAULT_CONFIG_FILE)
		
		if(!file_exists(szDir))
		{
			log_to_file(LOG_FILE, "TURRETS : Default turrets config file is not exist. Turrets are disabled on this map.")
		
			g_AreTurretsEnabled = false;
			return PLUGIN_CONTINUE
		}
		
		formatex(szDir, charsmax(szDir), TURRETS_DEFAULT_CONFIG_FILE)
		replace_string(szDir, charsmax(szDir), ".cfg", "")
		trim(szDir)
		
		/* It is TURRETS_DEFAULT_CONFIG_FILE without .cfg */
		LoadTurretsConfig(szDir)
		
		return PLUGIN_CONTINUE
	}
	
	for(new i = 0 ; read_file(szDir, i, szText, 63, len); i ++)
	{
		/* If it is comment, read next line */
		if(equali(szText, ";", 1)|| (szText[0] == '/' && szText[1] == '/') || !strlen(szText))
			continue;
		
		replace_all(szText, 63, "=", "")
		
		parse(szText, szData, 63, iData[0], 5, iData[1], 5)
		
		if(DEBUG_T)
		{
			if(containi(szData, "DMG") != -1)
				log_to_file(LOG_FILE, "DEBUG_T: Command '%s' | set: '%s' and '%s'", szData, iData[0], iData[1]);
			else
				log_to_file(LOG_FILE, "DEBUG_T: Command '%s' | set: '%s'", szData, iData[0]);
		}
			
		new iNum = str_to_num(iData[0])
		new iNum2 = str_to_num(iData[1])
		
		new szCommand[64]
		copy(szCommand, 63, szData)

		if(equali(szData, "BULLET", 6)) 
		{
			if(equali(szCommand, "BULLET_TURRET_FIRE_FREQ")) 
			{
				g_TurretsFreqData[TURRET_BULLET] = iNum
				continue
			}
			replace(szData, 63, "BULLET_TURRET_RANGE_", "");
			formatex(szFormat, 63, "BULLET_TURRET_RANGE_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_BULLET][1] ++;
				g_TurretsRangeData[TURRET_BULLET][str_to_num(szData)-1] = iNum
				continue;

			}
			replace(szData, 63, "BULLET_TURRET_PRICE_", "");
			formatex(szFormat, 63, "BULLET_TURRET_PRICE_%d", str_to_num(szData))
			if(equali(szCommand, szFormat))
			{
				g_TurretsPriceData[TURRET_BULLET][str_to_num(szData)-1] = iNum
				continue;
			}
			replace(szData, 63, "BULLET_TURRET_DMG_", "");
			formatex(szFormat, 63, "BULLET_TURRET_DMG_%d", str_to_num(szData))
			if(equali(szCommand, szFormat))
			{
				g_TurretsDamageData[TURRET_BULLET][str_to_num(szData)-1][0] = iNum
				g_TurretsDamageData[TURRET_BULLET][str_to_num(szData)-1][1] = iNum2
				iNum2 = 0
				iMaxLevel[TURRET_BULLET][0] ++;
				continue;
			}
			replace(szData, 63, "BULLET_TURRET_ACCURACY_", "");
			formatex(szFormat, 63, "BULLET_TURRET_ACCURACY_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_BULLET][2] ++;
				g_TurretsAccuracyData[TURRET_BULLET][str_to_num(szData)-1] = iNum
				continue;

			}

			replace(szData, 63, "BULLET_TURRET_FIRE_RATE_", "");
			formatex(szFormat, 63, "BULLET_TURRET_FIRE_RATE_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_BULLET][3] ++;
				g_TurretsFireRateData[TURRET_BULLET][str_to_num(szData)-1] = iNum
				continue;

			}
		}
		else if(equali(szData, "LASER", 5))
		{
			if(equali(szCommand, "LASER_TURRET_FIRE_FREQ")) 
			{
				g_TurretsFreqData[TURRET_LASER] = iNum
				continue
			}
			replace(szData, 63, "LASER_TURRET_RANGE_", "");
			formatex(szFormat, 63, "LASER_TURRET_RANGE_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) {
				g_TurretsRangeData[TURRET_LASER][str_to_num(szData)-1] = iNum
				iMaxLevel[TURRET_LASER][1] ++;
				continue;
			}
			replace(szData, 63, "LASER_TURRET_PRICE_", "");
			formatex(szFormat, 63, "LASER_TURRET_PRICE_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsPriceData[TURRET_LASER][str_to_num(szData)-1] = iNum
				continue;
			}
			replace(szData, 63, "LASER_TURRET_DMG_", "");
			formatex(szFormat, 63, "LASER_TURRET_DMG_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) {
				g_TurretsDamageData[TURRET_LASER][str_to_num(szData)-1][0] = iNum
				g_TurretsDamageData[TURRET_LASER][str_to_num(szData)-1][1] = iNum2
				iNum2 = 0
				iMaxLevel[TURRET_LASER][0] ++;
				continue;
			}

			replace(szData, 63, "LASER_TURRET_ACCURACY_", "");
			formatex(szFormat, 63, "LASER_TURRET_ACCURACY_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_LASER][2] ++;
				g_TurretsAccuracyData[TURRET_LASER][str_to_num(szData)-1] = iNum
				continue;

			}
			
			replace(szData, 63, "LASER_TURRET_FIRE_RATE_", "");
			formatex(szFormat, 63, "LASER_TURRET_FIRE_RATE_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_LASER][3] ++;
				g_TurretsFireRateData[TURRET_LASER][str_to_num(szData)-1] = iNum
				continue;
			}
			
			
		}
		else if(equali(szData, "LIGHTING", 8)) 
		{	
			if(equali(szCommand, "LIGHTING_TURRET_FIRE_FREQ")) 
			{
				g_TurretsFreqData[TURRET_LIGHTING] = iNum
				continue
			}
			replace(szData, 63, "LIGHTING_TURRET_RANGE_", "");
			formatex(szFormat, 63, "LIGHTING_TURRET_RANGE_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsRangeData[TURRET_LIGHTING][str_to_num(szData)-1] = iNum
				iMaxLevel[TURRET_LIGHTING][1] ++;
				continue;
			}
			replace(szData, 63, "LIGHTING_TURRET_PRICE_", "");
			formatex(szFormat, 63, "LIGHTING_TURRET_PRICE_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsPriceData[TURRET_LIGHTING][str_to_num(szData)-1] = iNum
				continue;
			}
			replace(szData, 63, "LIGHTING_TURRET_DMG_", "");
			formatex(szFormat, 63, "LIGHTING_TURRET_DMG_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsDamageData[TURRET_LIGHTING][str_to_num(szData)-1][0] = iNum
				g_TurretsDamageData[TURRET_LIGHTING][str_to_num(szData)-1][1] = iNum2
				iNum2 = 0
				iMaxLevel[TURRET_LIGHTING][0] ++;
				continue;
			}
			replace(szData, 63, "LIGHTING_TURRET_ACCURACY_", "");
			formatex(szFormat, 63, "LIGHTING_TURRET_ACCURACY_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_LIGHTING][2] ++;
				g_TurretsAccuracyData[TURRET_LIGHTING][str_to_num(szData)-1] = iNum
				continue;

			}
			replace(szData, 63, "LIGHTING_TURRET_FIRE_RATE_", "");
			formatex(szFormat, 63, "LIGHTING_TURRET_FIRE_RATE_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_LIGHTING][3] ++;
				g_TurretsFireRateData[TURRET_LIGHTING][str_to_num(szData)-1] = iNum
				continue;
			}
			
		}	
		else if(equali(szData, "M_LASER", 7))
		{
			if(equali(szCommand, "M_LASER_TURRET_FIRE_FREQ")) 
			{
				g_TurretsFreqData[TURRET_MULTI_LASER] = iNum
				continue
			}
			replace(szData, 63, "M_LASER_TURRET_RANGE_", "");
			formatex(szFormat, 63, "M_LASER_TURRET_RANGE_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsRangeData[TURRET_MULTI_LASER][str_to_num(szData)-1] = iNum
				iMaxLevel[TURRET_MULTI_LASER][1] ++;
				continue;
			}
			replace(szData, 63, "M_LASER_TURRET_PRICE_", "");
			formatex(szFormat, 63, "M_LASER_TURRET_PRICE_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsPriceData[TURRET_MULTI_LASER][str_to_num(szData)-1] = iNum
				continue;
			}
			replace(szData, 63, "M_LASER_TURRET_DMG_", "");
			formatex(szFormat, 63, "M_LASER_TURRET_DMG_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsDamageData[TURRET_MULTI_LASER][str_to_num(szData)-1][0] = iNum
				g_TurretsDamageData[TURRET_MULTI_LASER][str_to_num(szData)-1][1] = iNum2
				iNum2 = 0
				iMaxLevel[TURRET_MULTI_LASER][0] ++;
				continue;
			}
			replace(szData, 63, "M_LASER_TURRET_ACCURACY_", "");
			formatex(szFormat, 63, "M_LASER_TURRET_ACCURACY_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_MULTI_LASER][2] ++;
				g_TurretsAccuracyData[TURRET_MULTI_LASER][str_to_num(szData)-1] = iNum
				continue;

			}

			replace(szData, 63, "M_LASER_TURRET_FIRE_RATE_", "");
			formatex(szFormat, 63, "M_LASER_TURRET_FIRE_RATE_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_MULTI_LASER][3] ++;
				g_TurretsFireRateData[TURRET_MULTI_LASER][str_to_num(szData)-1] = iNum
				continue;

			}
		}
		else if(equali(szData, "ROCKET", 5))
		{
			if(equali(szCommand, "ROCKET_TURRET_FIRE_FREQ")) 
			{
				g_TurretsFreqData[TURRET_ROCKET] = iNum
				continue
			}
			replace(szData, 63, "ROCKET_TURRET_RANGE_", "");
			formatex(szFormat, 63, "ROCKET_TURRET_RANGE_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsRangeData[TURRET_ROCKET][str_to_num(szData)-1] = iNum
				iMaxLevel[TURRET_ROCKET][1] ++;
				continue;
			}
			replace(szData, 63, "ROCKET_TURRET_PRICE_", "");
			formatex(szFormat, 63, "ROCKET_TURRET_PRICE_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsPriceData[TURRET_ROCKET][str_to_num(szData)-1] = iNum
				continue;
			}
			replace(szData, 63, "ROCKET_TURRET_DMG_", "");
			formatex(szFormat, 63, "ROCKET_TURRET_DMG_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsDamageData[TURRET_ROCKET][str_to_num(szData)-1][0] = iNum
				g_TurretsDamageData[TURRET_ROCKET][str_to_num(szData)-1][1] = iNum2
				iNum2 = 0
				iMaxLevel[TURRET_ROCKET][0] ++;
				continue;
			}
			replace(szData, 63, "ROCKET_TURRET_ACCURACY_", "");
			formatex(szFormat, 63, "ROCKET_TURRET_ACCURACY_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_ROCKET][2] ++;
				g_TurretsAccuracyData[TURRET_ROCKET][str_to_num(szData)-1] = iNum
				continue;

			}

			replace(szData, 63, "ROCKET_TURRET_FIRE_RATE_", "");
			formatex(szFormat, 63, "ROCKET_TURRET_FIRE_RATE_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_ROCKET][3] ++;
				g_TurretsFireRateData[TURRET_ROCKET][str_to_num(szData)-1] = iNum
				continue;

			}
			
		}
		else if(equali(szData, "GATLING", 7))
		{
			if(equali(szCommand, "GATLING_TURRET_FIRE_FREQ")) 
			{
				g_TurretsFreqData[TURRET_GATLING] = iNum
				continue
			}
			replace(szData, 63, "GATLING_TURRET_RANGE_", "");
			formatex(szFormat, 63, "GATLING_TURRET_RANGE_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsRangeData[TURRET_GATLING][str_to_num(szData)-1] = iNum
				iMaxLevel[TURRET_GATLING][1] ++;
				continue;
			}
			replace(szData, 63, "GATLING_TURRET_PRICE_", "");
			formatex(szFormat, 63, "GATLING_TURRET_PRICE_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsPriceData[TURRET_GATLING][str_to_num(szData)-1] = iNum
				continue;
			}
			replace(szData, 63, "GATLING_TURRET_DMG_", "");
			formatex(szFormat, 63, "GATLING_TURRET_DMG_%d", str_to_num(szData))
			if(equali(szCommand, szFormat)) 
			{
				g_TurretsDamageData[TURRET_GATLING][str_to_num(szData)-1][0] = iNum
				g_TurretsDamageData[TURRET_GATLING][str_to_num(szData)-1][1] = iNum2
				iNum2 = 0
				iMaxLevel[TURRET_GATLING][0] ++;
				continue;
			}
			replace(szData, 63, "GATLING_TURRET_ACCURACY_", "");
			formatex(szFormat, 63, "GATLING_TURRET_ACCURACY_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_GATLING][2] ++;
				g_TurretsAccuracyData[TURRET_GATLING][str_to_num(szData)-1] = iNum
				continue;

			}

			replace(szData, 63, "GATLING_TURRET_FIRE_RATE_", "");
			formatex(szFormat, 63, "GATLING_TURRET_FIRE_RATE_%d", str_to_num(szData))

			if(equali(szCommand, szFormat))
			{
				iMaxLevel[TURRET_GATLING][3] ++;
				g_TurretsFireRateData[TURRET_GATLING][str_to_num(szData)-1] = iNum
				continue;

			}
		}
	}

	for(new i = 1; i < ENUM_TURRETS_TYPE ; i++)
	{
		/* 0 is DAMAGE, 1 is RANGE, 2 is Accuracy */
		g_TurretsMaxLevelData[i][0] = iMaxLevel[i][0]
		g_TurretsMaxLevelData[i][1] = iMaxLevel[i][1]
		g_TurretsMaxLevelData[i][2] = iMaxLevel[i][2]
		g_TurretsMaxLevelData[i][3] = iMaxLevel[i][3]
		
		if(DEBUG_T)
		{
			log_to_file(LOG_FILE, "DEBUG_T: Maximum level of DAMAGE for %s turret: %d", g_TurretsName[i], iMaxLevel[i][0]);
			log_to_file(LOG_FILE, "DEBUG_T: Maximum level of RANGE for %s turret: %d", g_TurretsName[i], iMaxLevel[i][1]);
			log_to_file(LOG_FILE, "DEBUG_T: Maximum level of ACCURACY for %s turret: %d", g_TurretsName[i], iMaxLevel[i][2]);
			log_to_file(LOG_FILE, "DEBUG_T: Maximum level of FIRE RATE for %s turret: %d", g_TurretsName[i], iMaxLevel[i][3]);
		}
	}

	return PLUGIN_CONTINUE;
}

stock TurretTurnToTarget(ent, enemy, mode = 0, Float:enemyOrigin[3] = {0.0, 0.0, 0.0})
{
	static Float:sentryOrigin[3], Float:closestOrigin[3]
	entity_get_vector(ent, EV_VEC_origin, sentryOrigin)
	
	if(enemyOrigin[0] == 0.0 && enemyOrigin[1] == 0.0 && enemyOrigin[2] == 0.0)
		entity_get_vector(enemy, EV_VEC_origin, closestOrigin)
	else
		closestOrigin = enemyOrigin
		
	new newTrip, Float:newAngle = floatatan(((closestOrigin[1]-sentryOrigin[1])/(closestOrigin[0]-sentryOrigin[0])), radian) * 57.2957795;

	if(closestOrigin[0] < sentryOrigin[0])
		newAngle += 180.0;
	if(newAngle < 0.0)
		newAngle += 360.0;
	
	sentryOrigin[2] += 35.0
	if(closestOrigin[2] > sentryOrigin[2])
		newTrip = 0;
	if(closestOrigin[2] < sentryOrigin[2])
		newTrip = 255;
	if(closestOrigin[2] == sentryOrigin[2])
		newTrip = 127;
		
	entity_set_byte(ent, EV_BYTE_controller1, floatround(newAngle*0.70833));
	entity_set_byte(ent, EV_BYTE_controller2, newTrip);
	
	if(!mode)
		entity_set_byte(ent, EV_BYTE_controller3, entity_get_byte(ent, EV_BYTE_controller3)+20>255? 0: entity_get_byte(ent, EV_BYTE_controller3)+20);
}

stock get_origin_from_dist_player(id, Float:dist, Float:origin[3], s3d = 1) 
{
	new Float:idorigin[3];
	entity_get_vector(id, EV_VEC_origin, idorigin); // lub pev(id, pev_origin, idorigin) dla fakemety
	
	if(dist == 0) 
	{
		origin = idorigin;
		return;
	}
	
	new Float:idvangle[3];
	entity_get_vector(id, EV_VEC_v_angle, idvangle); // lub pev(id, pev_v_angle, idvangle) dla fakemety
	idvangle[0] *= -1;
	
	origin[0] = idorigin[0] + dist * floatcos(idvangle[1], degrees) * ((s3d) ? floatabs(floatcos(idvangle[0], degrees)) : 1.0);
	origin[1] = idorigin[1] + dist * floatsin(idvangle[1], degrees) * ((s3d) ? floatabs(floatcos(idvangle[0], degrees)) : 1.0);
	origin[2] = idorigin[2]
}

stock TurretGetClosestMonster(iEntity, Float:TurretOrigin[3], Float:flRange) 
{
	if(!td_is_wave_started())
		return 0;
		
	/*new Float:fOrigin1[3];
	new Float:fOrigin2[3]
	
	entity_get_vector(ent, EV_VEC_origin, fOrigin1)
	
	new tempEntID;
	new entlist[3]
	new Float:dis;
	for(new i ; i < ; i++) 
	{	if(entity_get_int(entlist[i], EV_INT_iuser1) == 0)
			continue
		
		entity_get_vector(entlist[i], EV_VEC_origin, fOrigin2);
		
		dis = get_distance_f(fOrigin1, fOrigin2)
		if(dis < flDistanse) {
			flDistanse = dis;
			tempEntID = entlist[i];
		}	
	}*/
	#define MAX_MONSTERS_IN_RANGE	7
	new iMonstersFinded[MAX_MONSTERS_IN_RANGE];
	new iMonstersNum;

	if( (iMonstersNum = find_sphere_class(iEntity, "monster", flRange, iMonstersFinded, MAX_MONSTERS_IN_RANGE-1)) == 1)
		return iMonstersFinded[0];
	
	new Float:fMonsterOrigin[3];
	new Float: fDistanse
	new Float: fClosestDistanse = 9999.9;
	new iMonsterEntity;

	for(new i ; i < iMonstersNum ; i++)
	{
		entity_get_vector(iMonstersFinded[i], EV_VEC_origin, fMonsterOrigin)
		
		if( (fDistanse = get_distance_f(TurretOrigin, fMonsterOrigin)) < fClosestDistanse)
		{
			fClosestDistanse = fDistanse;
			iMonsterEntity = iMonstersFinded[i]
		}
	}
			
	return iMonsterEntity;
}

stock GetClosestTurret(index, Float:radius, mode) 
{
	new iEntList[3]
	new iNum = find_sphere_class(index, "turret", radius, iEntList, 2)
	
	return iNum ? iEntList[mode] : 0
}

stock MakeLavaSplashEffect(iOrigin[3])
{
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY, iOrigin) //message begin
	write_byte(TE_LAVASPLASH)
	write_coord(iOrigin[0]) // start position
	write_coord(iOrigin[1])
	write_coord(iOrigin[2])
	message_end()
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

public IsPlayerTurretOwner(iEnt, iPlayer)
	return entity_get_edict(iEnt, EV_ENT_turret_owner) == iPlayer

public GetTurretOwner(iEnt)
	return entity_get_edict(iEnt, EV_ENT_turret_owner);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
