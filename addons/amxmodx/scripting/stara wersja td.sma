#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <cstrike>

#include <dhudmessage>


 // #pragma semicolon 1; // Wymusza srednik na koncu linii
 
// **************************

#define PLUGIN "Tower Defense"
#define VERSION "0.75"
#define AUTHOR "GT Team"

#define MAX_WAVE 100 	// maksymalna liczba wavow
#define MAX_MONSTER 30  // maksymalna liczba potworow

// **************************

#define pev_monster_track	pev_iuser1 // Aktualny numer tracka potwora
#define pev_monster_type	pev_iuser2 // Typ potwora
#define pev_ent_health		pev_iuser3 // HP potwora
#define pev_max_health		pev_iuser4 // Maxymalne HP Potwora

#define MAX_PLAYERS 32

// *************************

new const gModelsConfigFile[] 	= "addons/amxmodx/configs/td_models.ini";	// plik z konfiguracja modeli
new const gCvarConfigFile[] 	= "addons/amxmodx/configs/td_config.cfg"; 	// plik z cvarami
new const gExplodeSprite[]	= "sprites/TD/zerogxplode.spr" 			// plik sprite explozji
new const gSpawnSprite[] 	= "sprites/TD/spawn.spr"			// plik sprite spawna
new const gPrefix[] 		= "[TD]"; // prefix moda
new const gMonsterPrefix[]	= "[P]"; //prefix potwora (uzywany w deathmsg)

// **************************

new gBaseHealth; 			// Zycie bazy
new gMaxBaseHealth; 			// Maksymalne zycie bazu

// **************************

new spr_blood_drop, spr_blood_spray;	//indexy spritow krwii
new gExplode			//index sprita eksplozji

// **************************

new gWaveName[][] = 	// Nazwy rund
{
	"Brak", 	// NONE
	"Normalny", 	// NORMAL
	"Szybcior",	// FAST
	"Mocny", 	// STRENGHT
	"Bonus", 	// BONUS
	"Boss" 		// BOSS
}

// **************************

new const gEntityBar[][] 	= {	//HealthBary
	"sprites/TD/healthbar1.spr",	//1
	"sprites/TD/healthbar2.spr",	//2
	"sprites/TD/healthbar3.spr"	//3
}

new const gLoseGameSound[][] = { //dzwiek gdy przegrali gre
	"TD/endgame1.wav"
}

new const gStartWaveSound[][] = {//dzwiek rozpoczecai wava
	"TD/startwave1.wav"
}

// **************************

new gAttackEffectColorName[][] = { //Nazwy kolorow do usatwien gracza
	"Bialy",
	"Zielony",
	"Niebieski",
	"Czerowny",
	"Zolty",
	"Jasny Niebieski",
	"\yWlasny"
}

new gAttackEffectProperties[6][3] = {
	{255, 255, 255}, //bialy
	{0, 255, 0},//zielony
	{0, 0, 255},//niebieski
	{255, 0, 0},//czerwony
	{255, 255, 0},//zolty
	{0, 255, 255}//jasny niebieski
}

// **************************
//Typy rund i potworow

enum _:MonsterType{  //typy potworow
	MONSTER_NONE = 0, 
	MONSTER_NORMAL, 
	MONSTER_FAST,
	MONSTER_STRENGHT, 
	MONSTER_BONUS,
	MONSTER_BOSS 
}

enum eTask { //enum tasak
	TASK_COUNTDOWN = 522,	//task do odliczania czasu
	TASK_STARTWAVE = 616,	//task rozpoczecia wava
	TASK_GAME_NOT_POSSIBLE = 712,	//task gry niemozliwej
	TASK_ENDROUND = 413,	//task konierndu cy
	TASK_TOWER_LIGHT = 514,	//task oswietlania wiezyczki
	TASK_HUD_INFO = 312,	//task informacji gracza
	TASK_PLAYER_SPAWN = 211,//task odrespienia gracza
	TASK_SHOW_MONSTER_HP = 899,//task pokazywania hp potwora po najechaniu
	TASK_ADD_PLAYER_BONUS = 1234//task dodawania bonusow dla gracza
}

enum ePlayerShow {
	SHOW_TURRET_DAMAGE,
	SHOW_WAVE_INFO,
	SHOW_PLAYER_DAMAGE,
	SHOW_MONSTER_HP
}

new gPlayerShowInfo[33][ ePlayerShow ];

new TASKS[eTask]//taski

new gMonsterDamage[2];			// 0 - Normalny potwor | 1 - Boss 
new gMonsterAlive;	//liczba aktualnie zyjacych potworow
new gSendsMonster;	//liczba wyslanych potworow

// **************************

new monster_normal_mdl[4][64]; //modele normalnych
new monster_fast_mdl[4][64]; //modele szybkich
new monster_strenght_mdl[4][64]; //modele mocnych
new monster_boss_mdl[64]; //modele bossa
new monster_bonus_mdl[64]; //modele bonusa
new tower_mdl[64] //modele wiezy

// **************************

new gGame = 0; 		// Zmienna do sprawdzania czy jest mozliwa gra.
new gStart = 0; 		// Zmienna do sprawzenia czy rozpoczeta jest runda.

// ***Informacje o rundzie***

new gRoundType[MAX_WAVE]	//Typ rundy, NORMAL,FAST itp
new gRoundCount[MAX_WAVE]	//Liczba wysylanych potworow w rundzie
new gRoundHealth[MAX_WAVE]	//Zycie potworow w rundzie
new gRoundBonusHealth[MAX_WAVE]	//Jezeli jest, to zycie bonusa w rundzie
new gRoundBossHealth[MAX_WAVE]  //Jezeli jest to zycie bossa w rundzie

new Float:gRoundSpeed[MAX_WAVE]	//Predkosc zwyklych w rundzie
new Float:gRoundBonusSpeed[MAX_WAVE]//Jezeli jest bonus to predkosc jego w tej rundzie
new Float:gRoundBossSpeed[MAX_WAVE] //Jezeli jest boss to predkosc jego w tej rundzie

// **************************

new gWave; //aktualny wave
new gWaveNum; //liczba max wavow

new szTextHUD[256] // do pokazywania huda
new szCount; // j.w.

// **************************

//Punkty Gracza
new gPlayerPoints[33]

//Efekty strzalu
new gPlayerAttackColor[33];
new gPlayerAttackColorValue[33][3];


//Do wiezyczki
new gPlayerAddAmmo[33];
new gPlayerDamage[33], gPlayerNewDamage[33];

//Pasek zycia
new gPlayerHealthBar[33];

// **************************

new cvar_track_range, cvar_time_to_wave, cvar_default_turrets;
new cvar_default_base_hp, cvar_default_monster_dmg, cvar_default_boss_dmg;
new cvar_boss_points_kill, cvar_bonus_points_kill, cvar_points_kill


// **************************

new SYNC_TIMELEFT
new SYNC_ROUNDINFO
new SYNC_GAME_NOT_POSSIBLE, gSync7, gSync8
new SYNC_PLAYER_DAMAGE

// **************************
// Jeden Gracz
new OnlyOnePlayer = false
new OnlyOnePlayer2 = false

//Originy pozycji ktore sie e bineda zmienialy
new Float:gStartOrigin[3]
new Float:gEndOrigin[3]
new Float:gTowerOrigin[3]

// **************************

new gTurretsAvailable

enum {
	DISABLED = 0,
	ENABLED
}

// *******Wczytywanie*******

new gLoadStandard = 0;
new gLoadStandardChecking = 1;
new Float:gTrackRange

// **************************

//Forwardy

new gForward_ResetAll
new gForward_MonsterKill
new gForward_CountDown;
new gForward_StartWave;

// **************************

public plugin_precache()
{
	LoadModels()
	
	new szModelDir[] = "models/TD"
	new szTemp[128]
	
	for(new i ; i < 4; i++)
	{
		//Model zwyklych potworow		
		formatex(szTemp, 127, "%s/%s.mdl", szModelDir, monster_normal_mdl[i])
		precache_model(szTemp)
		
		//Model szybkich potworow		
		formatex(szTemp, 127, "%s/%s.mdl", szModelDir, monster_fast_mdl[i])
		precache_model(szTemp)
		
		//Model silnych potworow
		formatex(szTemp, 127, "%s/%s.mdl", szModelDir, monster_strenght_mdl[i])
		precache_model(szTemp)
		
	}
	
	//Model Bonusa
	formatex(szTemp, 127, "%s/%s.mdl", szModelDir, monster_bonus_mdl)
	precache_model(szTemp)
	
	//Model Bossa
	formatex(szTemp, 127, "%s/%s.mdl", szModelDir, monster_boss_mdl)
	precache_model(szTemp)
	
	//Model Wie¿y
	formatex(szTemp, 127, "%s/%s.mdl", szModelDir, tower_mdl)
	precache_model(szTemp)
	
	///-
	
	//Krew
	spr_blood_drop = precache_model("sprites/blood.spr")
	spr_blood_spray = precache_model("sprites/bloodspray.spr")
	
	// Sprite Pasku Zycia
	for(new i ; i < ( sizeof gEntityBar ) ; i++)
		precache_model(gEntityBar[i])
	
	precache_model(gSpawnSprite)
	
	//Sprite wybuchu
	gExplode = precache_model(gExplodeSprite)
}

public plugin_cfg()
{
	server_cmd("mp_buytime ^"9999.9^"") // mozan kupywac bronie prawiec caly czas
	server_cmd("mp_timelimit ^"0^"")    //mape moze zmienci tylko mod *(tak jakoby :D)
	server_cmd("mp_timeleft ^"0^"")     //czas do konca rundy
	server_cmd("mp_roundtime ^"999^"")  // j.w
	server_cmd("mp_freezetime ^"0^"") //bez freeze time
}

public plugin_natives()
{
	register_native("td_get_user_points", "_get_player_points", 1)
	register_native("td_set_user_points", "_set_player_points", 1)
	register_native("td_get_game_status", "_get_game_status", 1)
	register_native("td_set_game_status", "_set_game_status", 1)
	register_native("td_is_monster", "is_monster", 1)
	register_native("td_is_round", "is_round", 1)
	register_native("td_is_special_wave", "is_special_wave", 1)
	register_native("td_is_game_started", "_is_game_started", 1)
	register_native("td_is_turret_on", "_is_turret_on", 1)
	register_native("td_kill_monster", "KillMonster", 1)
	register_native("td_get_wave_type", "_get_wave_type", 1)
	register_native("td_get_wave", "_get_wave", 1)
	register_native("td_get_wave_health", "_get_wave_health", 1)
	register_native("td_get_wave_speed", "_get_wave_speed", 1)
	register_native("td_get_wave_bonus_speed", "_get_wave_bonus_speed", 1)
	register_native("td_get_wave_boss_speed", "_get_wave_boss_speed", 1)
	register_native("td_get_wave_bonus_health", "_get_wave_bonus_health", 1)
	register_native("td_get_wave_boss_health", "_get_wave_boss_health", 1)
	register_native("td_get_max_wave", "_get_max_wave", 1)
	register_native("td_get_max_monster", "_get_max_monster", 1)
	register_native("td_get_wave_monster_num", "_get_wave_monster_num", 1)
	register_native("td_get_monster_type__name", "_get_monster_name", 1)
	
}


public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think("monster","MonsterThink"); //think potwora | klasy "monster"
	
	gForward_ResetAll = CreateMultiForward("td_reset_all", ET_CONTINUE);
	gForward_MonsterKill = CreateMultiForward("td_monster_kill", ET_CONTINUE, FP_CELL, FP_CELL);
	gForward_CountDown = CreateMultiForward("td_countdown", ET_CONTINUE);
	gForward_StartWave = CreateMultiForward("td_start_wave", ET_CONTINUE, FP_CELL, FP_CELL);
	
	// *************************************************
	
	RegisterHam(Ham_TakeDamage, "info_target", "TakeDamage") // zadawane obrazenia potworowi
	RegisterHam(Ham_TakeDamage, "player", "TakeDamagePlayer") //zadawane obrazenia graczowi
	RegisterHam(Ham_Spawn, "player", "PlayerRespawn", 1) //spawn gracza
	RegisterHam(Ham_Killed, "info_target", "MonsterKill") //zabicie potwora
	
	// *************************************************
	
	//register_event( "CurWeapon" , "CurWeapon" , "be" , "1=1" );
	register_event("HLTV", "NewRoundHLTV", "a", "1=0", "2=0"); //nowa runda
	
	register_logevent("EndRoundLogEvent", 2, "1=Round_End") //koniec rundy
	register_logevent("GameCommecing", 2, /*"0=World triggered", */"1=Game_Commencing") //Wiadomosc GC
	
	// *************************************************
	
	register_clcmd("changecolor_R", "ChangeAttackColorR"); // zmiany efekty korou strzalu
	register_clcmd("changecolor_G", "ChangeAttackColorG"); //j.w
	register_clcmd("changecolor_B", "ChangeAttackColorB");//j.w
	
	register_clcmd("say /menu", "PlayerMenu") // komenda do otwarcia menu
	register_clcmd("say /solo", "PlayerSolo") //komenda dla jednego gracza
	
	register_forward(FM_AddToFullPack, "fwAddToFullPack", 1); //atfp
	register_forward(FM_ClientKill, "PlayerCmdKill") //zeby gracz nie mogl sie zabic
	
	// *************************************************
	
	register_message(get_user_msgid("SayText"), "SayText")
	
	// *************************************************
	
	cvar_points_kill 	= register_cvar("td_kill_points", "3"); //punkty za zabicie potwora
	cvar_boss_points_kill 	= register_cvar("td_boss_kill_points", "15"); //punkty za zabicie bossa
	cvar_bonus_points_kill 	= register_cvar("td_bonus_kill_points", "10"); //punkty za zabicie bonusa
	
	cvar_track_range 	= register_cvar("td_defailt_track_range", "19.0"); //odleglosc od zmiany trasy potwora 
	cvar_time_to_wave 	= register_cvar("td_time_to_wave", "25"); // czas do next wava
	cvar_default_turrets	= register_cvar("td_default_turrets", "1")	 //domyslne wiezyczki wloczone
	cvar_default_base_hp	= register_cvar("td_default_base_health", "100") //domyslne hp bazy
	cvar_default_monster_dmg= register_cvar("td_default_monster_damage", "5") //domyslnie zadawane obrazenia przez potwora
	cvar_default_boss_dmg	= register_cvar("td_default_boss_damage", "20")	 //domyslnie zadawane obrazenia przez bossa
	
	// *************************************************
	
	SYNC_TIMELEFT = CreateHudSyncObj(); //odliczanie
	SYNC_ROUNDINFO = CreateHudSyncObj();//inf. o rundzie
	SYNC_GAME_NOT_POSSIBLE = CreateHudSyncObj() //gra nie mozliwa
	gSync7 = CreateHudSyncObj(); // Wiad. Koncowa. 1
	gSync8 = CreateHudSyncObj(); // Wiad. koncowa. 2
	SYNC_PLAYER_DAMAGE = CreateHudSyncObj(); // obrazenia gracza
	
	// *************************************************
	
	LoadWave()
	CheckMap();
	LoadConfig()
	
}
public AddBonus(i) // dodawanie bonusa graczowi
{
	i -= TASKS[TASK_ADD_PLAYER_BONUS]
	
	if ( !is_user_connected( i ) || is_user_hltv( i ) )
		return
		
	cs_set_user_money( i, cs_get_user_money( i ) + 500 )
		
	if( cs_get_user_money( i ) >= 16000 )
		cs_set_user_money( i, 16000 )
		
	gPlayerPoints[ i ] += 1
		
	client_print( i , print_center, "Otrzymales bonus | +$500 | +1pkt | za gre")
	client_print( i , print_chat, "Otrzymales bonus | +$500 | +1pkt | za gre")
	
	set_task(40.0, "AddBonus", i+TASKS[TASK_ADD_PLAYER_BONUS])
}

public GameCommecing()
	ResetAll()
	
public MonsterKill(ent, id) //zabicie potwora
{
	if(pev_valid(ent) && is_user_alive(id)) //jezeli potwor zyje i gracz zyje
	{
		if(is_monster(ent)) // jezeli to jest potwor
		{
			new iRet
			ExecuteForward(gForward_MonsterKill, iRet, id, ent); //forward ze potwor zabity
			//kto i kogo
			death_msg(id, ent); // wiadomosc w prawym gornym logu ze ten i ten zabil tego i tego
					
			//Usuwa HealthBar Potwora
			static classname[20]
			if(is_valid_ent( entity_get_int( ent, EV_INT_iuser3 ) )) // jezeli istnieje healthbar
			{
				pev(entity_get_int( ent, EV_INT_iuser3 ), pev_classname, classname, 19)
				if(equali("monster_healthbar", classname)) //jezeli to healthbar
					remove_entity( entity_get_int( ent, EV_INT_iuser3 ) ) //usun go
			}
			KillMonster(id, pev(ent, pev_monster_type)) // reszta kodu zabicia potwora
			//          id gracza, typ potwora
		}
	}
}
public PlayerCmdKill(id) // jezeli ktos uzyl komendy "kill"
{
	if(!is_user_alive(id)) // jezeli gracz nie zyje przerwij
		return FMRES_IGNORED
		
	client_print(id, print_console, "Chciales uzyc komendy ^"kill^" - jest ona nie dozwolona! - 2 pkt")
	client_print(id, 3, "Chciales uzyc komendy ^"kill^" - jest ona nie dozwolona! - 2 pkt")
	gPlayerPoints[id]-=2 //punkty za to ze chcial sie zabic
	
	if(gPlayerPoints[id] < 0) // jezeli gracz ma ponizej 0 pkt to chyba nie chcemy zeby pokazywalo -x :)
		gPlayerPoints[id] = 0 // ustaw 0
	
	return FMRES_SUPERCEDE //przerwij
}
public client_putinserver(id) //jezeli gracz sie polaczyl
{
	if(gGame)//jezeli gra jest mozliwa
	{
		set_task(5.0, "HudInfo", id+TASKS[TASK_HUD_INFO])
		set_task(5.0, "SpawnUser", id+TASKS[TASK_PLAYER_SPAWN], _, _, "b");
		set_task(5.0, "ShowPlayerMonsterHp", id+TASKS[TASK_SHOW_MONSTER_HP])
		set_task(5.0, "AddBonus", id+TASKS[TASK_ADD_PLAYER_BONUS])
	}
	if(get_playersnum(1) == 1)//jezeli on jest sam
	{
		OnlyOnePlayer = true
		if(!gGame)//jezeli gra nie jest mozliwa, wywyloaj nowa runde
			NewRoundHLTV()
	}
	else if(get_playersnum(1) > 1)//jezeli nie jest sam
	{
		OnlyOnePlayer = false
		OnlyOnePlayer2 = false
	}
}

public SpawnUser(id) // odradza graczy
{
	id -= TASKS[TASK_PLAYER_SPAWN]
	
	if(!is_user_connected(id) || is_user_alive(id)) // jezeli nie jest polaczony albo juz gra
		return
	if(get_user_team(id) == 1 || get_user_team(id) == 2) // i jezeli nie przydzieli druzyny
		return;
		
	ExecuteHam(Ham_CS_RoundRespawn, id)//odrodz
	remove_task(id+TASKS[TASK_PLAYER_SPAWN])
}
public client_disconnect(id)// gracz wyszedl
{
	deletePlayerInfo(id) //usun dane 
}

public deletePlayerInfo(id)
{
	if( 1 <= id < 33) // jezeli to gracz
	{
		gPlayerPoints[id] = 0;
		gPlayerAttackColor[id] = 0
		gPlayerAttackColorValue[id] = {255, 255, 255}
		gPlayerHealthBar[id] = 0	
		gPlayerAddAmmo[id] = 0
		gPlayerDamage[id] = 0
		gPlayerNewDamage[id] = 0
		remove_task(id+TASKS[TASK_SHOW_MONSTER_HP])
		remove_task(id+TASKS[TASK_HUD_INFO])
		remove_task(id+TASKS[TASK_PLAYER_SPAWN])
		remove_task(id+TASKS[TASK_ADD_PLAYER_BONUS])
	}
}
	
public PlayerRespawn(id) //gracz sie odrodzil
{
	if(is_user_alive(id) && gGame) // jezeli zyje i gra mozliwa
	{
		set_task(1.0, "ShowPlayerMonsterHp", id+TASKS[TASK_SHOW_MONSTER_HP])// pokazywanie hp potwora
		set_task(2.0, "HudInfo", id+TASKS[TASK_HUD_INFO]) //hud
	}
	if(is_user_alive(id) && OnlyOnePlayer && gGame) //jezeli jest sam, zyje i gra mozliwa
	{
		client_print(0, print_chat, "==============TOWER DEFENSE MOD INFO===========")
		client_print(0, print_chat, "Jestes sam na serwerze, czy chcesz zagrac SOLO?")
		client_print(0, print_chat, "Jezeli chcesz wpisz na chacie ^"/solo^"")
		client_print(0, print_chat, "Ostrzezenie! Gdy bedziesz gral solo")
		client_print(0, print_chat, "Poziom trudnosci gry znacznie wzrosnie!")
	}
}

public PlayerSolo(id) //jezeli wpisal /solo
{
	if(is_user_alive(id) && OnlyOnePlayer && gGame) //jezeli gra mozliwa i jest sam
	{
		new menu = menu_create("Tower Defense Solo Menu^n\rCzy chcesz zagrac \wSOLO ?", "PlayerSoloHandler")
		menu_additem(menu, "\yTak")
		menu_additem(menu, "\rNie")
		menu_display(id, menu)
	}
}
public PlayerSoloHandler(id, menu, item)
{
	if(item == MENU_EXIT && OnlyOnePlayer)
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	switch(item)
	{
		case 0: //tak
		{
			NewRoundHLTV()
			OnlyOnePlayer = false
			OnlyOnePlayer2 = true
			menu_destroy(menu)
			return PLUGIN_CONTINUE
		}
		case 1://nie
		{
			OnlyOnePlayer = false
			OnlyOnePlayer2 = false
			menu_destroy(menu)
			return PLUGIN_CONTINUE
		}
	}
	return PLUGIN_CONTINUE
}

public CheckMap() //sprawdza mape pod katem bledow
{
	new startEnt = find_ent_by_tname(-1, "start")
	new endEnt = find_ent_by_tname(-1, "end")
	new ent3 = find_ent_by_tname(-1, "track1")
	new ent4 = find_ent_by_tname(-1, "healthbar")
	
	new map[64];
	get_mapname(map, 63)
		
	if(pev_valid(startEnt)) // jezeli istnieje byt "start"
	{
		/* Tworzy sprite al'a portalu*/
		new spr = create_entity("env_sprite")
		
		entity_set_string(spr, EV_SZ_classname, "start_sprite")
		entity_set_model(spr, gSpawnSprite)
			
		pev(startEnt, pev_origin, gStartOrigin)
			
		entity_set_origin(spr, gStartOrigin)
		entity_set_int(spr, EV_INT_solid, SOLID_NOT);
		entity_set_int(spr, EV_INT_movetype, MOVETYPE_FLY) 
		
		set_pev(spr, pev_framerate, 1.0)
	}
	else
	{
		/* Jezeli byt nie istnieje przerwij gre*/
		log_to_file("TD.log", "Bad Map: %s. Start point 'start' was not found. Stopping Game.", map)
		gGame = 0;
	}
	
	if(!pev_valid(endEnt)) // jezeli nie istnieje byt "end"
	{
		log_to_file("TD.log", "Bad Map: %s. End point 'start' was not found. Stopping Game.", map)
		gGame = 0;
	}
	else // jezeli istnijee
	{
		//stworz model wiezy
		new mdl[64]
		new tower = create_entity("info_target")
		
		entity_get_vector(endEnt, EV_VEC_origin, gEndOrigin)

		entity_set_string(tower, EV_SZ_classname, "tower")
		
		formatex(mdl, 63, "models/TD/%s.mdl", tower_mdl)
		entity_set_model(tower, mdl);
		entity_set_size(tower, Float:{-40.0, -40.0, 0.0}, Float:{40.0, 40.0, 48.0});	
		entity_set_origin(tower, gEndOrigin);
		entity_set_int(tower, EV_INT_solid, SOLID_NOT);
		entity_set_int(tower, EV_INT_movetype, MOVETYPE_FLY) 
		drop_to_floor(tower)
		pev(tower , pev_origin, gTowerOrigin)
		
		set_task(10.0, "TowerLight", TASKS[TASK_TOWER_LIGHT], _, _, "b") //ostwietlaj wieze
		
		//jezeli istnieje byt healthbara
		if(pev_valid(ent4))
		{
			//stworz go
			new Float:Origin[3]
			
			new bar = create_entity("env_sprite")
			
			entity_set_string(bar, EV_SZ_classname, "tower_healthbar")
			entity_set_model(bar, gEntityBar[0])
			
			pev(ent4, pev_origin, Origin)

			entity_set_origin(bar, Origin)
			entity_set_int(bar, EV_INT_solid, SOLID_NOT);
			entity_set_int(bar, EV_INT_movetype, MOVETYPE_FLY) 
		
			set_pev(bar, pev_scale, 1.0)
			set_pev(bar, pev_frame, 100.0)
			
			set_pev(tower, pev_ent_health, bar)
			set_pev(tower, pev_max_health, gMaxBaseHealth)
			
		}
		else//jezeli nie
		{
			log_to_file("TD.log", "Map: %s. Byte 'info_target' with name 'healthbar' was not found. Tower healthbar will not exist. Game possible.", map)
			//gGame = 0;
		}
	}
	if(!pev_valid(ent3) && gGame)//jezeli nie istnieje trasa potwora
		log_to_file("TD.log", "Warning! Map : %s. Byte 'info_target' begining monster track with name 'track1' wasn't found, Game possible, but errors|bugs will can find.", map)
	
	if(pev_valid(startEnt) && pev_valid(endEnt)) // jezeli wszystko jest w porzadku
		gGame = 1; //stwierdz ze pod wzgledem mapy gra jest mozliwa, wiec ustaw ze mozna grac
}

new ghave[33];
public TakeDamage(ent, idinflictor, attacker, Float:damage, damagebits) //zadawanie obrazen potworowi
{
	if(is_valid_ent(ent) && is_user_connected(attacker)) // jezli gracz zyje i byt 
	{
		static classname[32];
		entity_get_string(ent, EV_SZ_classname, classname, 31);
			
		if(equal(classname, "monster"))  //jezli to potwor
		{	
			/* Pokazuje zadane obrazenia */
			if(!td_is_turret(attacker)){
				ghave[attacker]++
				if(ghave[attacker] == 1){
					set_hudmessage(0, 255, 0, 0.55, 0.465, 0, 0.0, 1.0, 0.0, 0.2, 1)
					ShowSyncHudMsg(attacker, SYNC_PLAYER_DAMAGE, "%d", floatround(damage))
				}
				if(ghave[attacker] == 2){
					set_hudmessage(0, 255, 0, 0.55, 0.5, 0, 0.0, 1.0, 0.0, 0.2, 2)
					ShowSyncHudMsg(attacker, SYNC_PLAYER_DAMAGE, "%d", floatround(damage))
				}
				if(ghave[attacker] == 3){
					set_hudmessage(0, 255, 0, 0.55, 0.535, 0, 0.0, 1.0, 0.0, 0.2, 3)
					ShowSyncHudMsg(attacker, SYNC_PLAYER_DAMAGE, "%d", floatround(damage))
				}
				if(ghave[attacker] == 4){
					set_hudmessage(0, 255, 0, 0.55, 0.57, 0, 0.0, 1.0, 0.0, 0.2, 4)
					ShowSyncHudMsg(attacker, SYNC_PLAYER_DAMAGE, "%d", floatround(damage))
				}
				if(ghave[attacker] == 5){
					set_hudmessage(0, 255, 0, 0.55, 0.605, 0, 0.0, 1.0, 0.0, 0.2, 5)
					ShowSyncHudMsg(attacker, SYNC_PLAYER_DAMAGE, "%d", floatround(damage))
					ghave[attacker] = 0
				}
				
				client_print(attacker, print_center, "HP: %d", pev(ent, pev_health)-floatround(damage)<0?0:pev(ent, pev_health)-floatround(damage))
			} 
			else   // jezlei to wiezyczka
				return HAM_IGNORED;
			
			/* -- */
			static Float:fOrigin[3]
			static Origin[3]
			
			pev(ent, pev_origin, fOrigin)
			
			FVecIVec(fOrigin, Origin)
			
			static Color[33][3] ;
			Color[attacker][0] = gPlayerAttackColorValue[attacker][0]
			Color[attacker][1] = gPlayerAttackColorValue[attacker][1]
			Color[attacker][2] = gPlayerAttackColorValue[attacker][2]
			
			msg_dlight(Origin, 10, Color[attacker], 3, 1)	
			
			if(random_num(1, 2) == 1) // 1/2 szans na pojawienie sie krwii
				fx_blood(Origin, 10) // krew	
		}
	}
	
	SetHamParamFloat(4, damage)
	return HAM_IGNORED
}
public KillMonster(id, monsterType) //zabito potwora
{		
	if(is_user_connected(id))  // jezeli gracz jest polaczony
	{
		set_hudmessage(255, 128, 255, -1.0, 0.45, 0, 0.0, 1.0, 0.0, 0.3)
		ShowSyncHudMsg(id, SYNC_PLAYER_DAMAGE, "KILL!") //pokaz wiadomosc "kill"
		
		if(is_user_alive(id)) // jezeli zyje
			GiveAmmo(id, 20) //daj 20 ammo do akt. broni
		
		if(monsterType != MONSTER_BOSS && monsterType != MONSTER_BONUS) // jezli to nie boss i nie bonus 
			gPlayerPoints[id] += get_pcvar_num(cvar_points_kill) //daj punkty jakoby za normalnego
		if(monsterType == MONSTER_BOSS) // jezeli boss
			gPlayerPoints[id] += get_pcvar_num(cvar_boss_points_kill) // daj punkty za bossa
		if(monsterType == MONSTER_BONUS) // jezeli bonus
			gPlayerPoints[id] += get_pcvar_num(cvar_bonus_points_kill) // daj punkty za bonusa
			
		cs_set_user_money(id, cs_get_user_money(id) + 450) // daj kase
		
		if(cs_get_user_money(id) > 16000) // jezeli ma powyzej 16k
			cs_set_user_money(id, 16000, 0) // ustaw 16k
			
		set_user_frags(id, get_user_frags(id)+1) //dodaj +1 dla fragow
		RefreshFrag(id)//odswiez fragi
		
	}
	
	gMonsterAlive--;//zyjacych potworw o 1 mniej
	
	if(task_exists(949))
		remove_task(949);
	
	if(gMonsterAlive <= 0) // jezeli to byl ostatni
	{
		gMonsterAlive = 0
		if(gWave && gStart && gGame) // jezeli to byl wave, i gra 
			EndRound() //zakoncz
	}
}


public RefreshFrag(id) //odswiez fragi
{
	new ideaths = cs_get_user_deaths(id);
	new ifrags = pev(id, pev_frags);
	new kteam = _:cs_get_user_team(id);
	
	message_begin( MSG_ALL, get_user_msgid("ScoreInfo"), {0,0,0}, 0 );
	write_byte( id );
	write_short( ifrags );
	write_short( ideaths);
	write_short( 0 );
	write_short( kteam );
	message_end();
}

public SayText(msgid, msgdest, msgentity) //bokuje wyswietlanie informacji o zmianie nicku
{
	new Marg[32]
	get_msg_arg_string(2, Marg, 31)
	if( equal(Marg, "#Cstrike_Name_Change"))
	{
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public TowerLight() //oswietla wieze
{
	new ent = find_ent_by_class(-1, "tower")
	
	if(pev_valid(ent))//jezeli istnieje
	{
		new iOrigin[3];
		
		FVecIVec(gTowerOrigin, iOrigin)
		
		msg_dlight(iOrigin, 10, {255, 255, 128}, 99, 0); //oswietl
	}
	else // jezeli nie
		if(task_exists(TASKS[TASK_TOWER_LIGHT]))  //jezeli task istnieje
			remove_task(TASKS[TASK_TOWER_LIGHT]) //usun
}
public LoadWave() //wczytuje wave
{
	new mapName[33];
	get_mapname(mapName, 32); //pobiera nazwe mapy
	
	new szFile[128]
	formatex(szFile, 127, "addons/amxmodx/configs/Tower Defense/%s.ini", mapName);
	if(file_exists(szFile)) //jezeli istnieje plik konf. wavy pod mape
	{
		LoadWaveFromFile(mapName) //wczytaj go 
	}
	else // jezeli nie wczytaj standardowe
	{
		log_to_file("TD_Wave.log", "Warning! Wave File '%s.ini' doesn't exists. Loading Standard Wave", mapName);
		
		
		//jezeli plik standardowych nie istnieje przerwij, bo nie mamy skonfigurowanych wavow
		if(!file_exists("addons/amxmodx/configs/Tower Defense/standard_wave.ini"))
		{
			log_to_file("TD_Wave.log", "File 'standard_wave.ini' doesnt exists while map wave configuration file doesnt exists. Game will not possible. Stopping It!");
			gGame = 0;
		}
		else // jezlei istnieje
		{
			log_to_file("TD_Wave.log", "Initializing Standard Wave...");
			LoadWaveFromFile("standard_wave"); //wczytaj standardowe
		}
	}
}

public LoadWaveFromFile(szFile[33]) //wczytuje wave z pliku
{
	/* UWAGA ! TA CZESC KODU JEST TYLKO DLA ZAAWANSOWANYCH SKRYPTEROW, ZMIENIANIE CZEGOKOLWIEK SKUTKUJE BLEDNYM WCZYTY
	WANIEM WAVOW! JEZELI CHCEZS COS ZROZUMIEC, SKUP SIE*/
	//jezeli jestes poczatkujacym daruj sobie sprawdzanie tego, nie bede komentowac tego publica !
	new szDir[128] = "addons/amxmodx/configs/Tower Defense"
	new szText[256], len;
	new szData[15][64]
	new skip = 0;
	
	formatex(szDir, 127, "%s/%s.ini", szDir, szFile);
	
	if(!file_exists(szDir) && equali(szFile, "standard_wave")) //jezeli plik nie istnieje i to byly standardowe ( ostatnia szansa )
	{
		log_to_file("TD_Wave.log", "Error: File '%s' doesnt exists. Game not possible - Change Map.", szFile)
		gGame = 0; //przerwij 
	}
	else if(equali(szFile, "standard_wave")) // jezeli to byly standardowe 
		set_task(0.5, "CheckLoad", _, szFile, 32)
		
	new size = file_size(szDir, 1)-1
	for(new i; read_file(szDir, i, szText, 255, len) ; i++)
	{
		if(szText[0] == ';') // srednik to komentarz NA POCZATKU WERSA/LINIJKI 
			continue
			
		remove_quotes(szText); // usuwa cudzyslowy 
		
		//Funkcja sprawdza czy plik zawiera linie ktora rozpoczyna 
		//System Wavow
		
		if(equali(szText, "-Start-")) // jezeli zostalo zainicjalizowane
		{
			skip = 1; //pomin ta linijke
			continue
		}
		//Dzieli 'szText' na czesci
		parse(szText, szData[0], 63, szData[1], 63, szData[2], 63, szData[3], 63, szData[4], 63, szData[5], 63,
		szData[6], 63, szData[7], 63, szData[8], 63, szData[9], 63, szData[10], 63, szData[11], 63, szData[12], 63,
		szData[13], 63)
		
		if(gLoadStandard == ENABLED && !equali(szData[0], "[WAVE]"))
			continue;
			
		else if(gLoadStandard == ENABLED && equali(szData[0], "[WAVE]"))
		{
			gLoadStandard = DISABLED;
			gLoadStandardChecking = DISABLED;
			continue;
		}
		
		static was_base_health = 2, was_monster_damage = 2, was_boss_damage = 2, was_turrets = 2, was_range = 2;
		
		if(gLoadStandardChecking == ENABLED)
		{
			if(size == i)
			{
				if(!gBaseHealth)
					was_base_health = 0
				if(!gMonsterDamage[0])
					was_monster_damage = 0
				if(!gMonsterDamage[1])
					was_boss_damage = 0
				if(!gTurretsAvailable)
					was_turrets = 0
				if(gTrackRange <= 0.0)
					was_range = 0
			}
			/*
			szData[0] = Tytul do sprawdzenia
			szData[1] = " = "
			szData[2] = Wartosc
			*/
			if(equali(szData[0], "BASE_HEALTH"))
			{
				gBaseHealth = str_to_num(szData[2]);
				gMaxBaseHealth = str_to_num(szData[2]);
				was_base_health = 1;
			}
			else if(was_base_health == 0)
			{
				log_to_file("TD_Wave.log", "Warning: Line %d | Map '%s' : Doesn't have info about base health, using default value '%d'", i, szFile, get_pcvar_num(cvar_default_base_hp));
				gBaseHealth = get_pcvar_num(cvar_default_base_hp);
				gMaxBaseHealth = get_pcvar_num(cvar_default_base_hp);
				was_base_health = 1;
			}
			
			if(equali(szData[0], "MONSTER_DAMAGE"))
			{
				gMonsterDamage[0] = str_to_num(szData[2]);
				was_monster_damage = 1;
			}
			else if(was_monster_damage == 0)
			{
				log_to_file("TD_Wave.log", "Warning: Line %d | Map '%s' : Doesn't have info about monster damage, using default value '%d'", i, szFile, get_pcvar_num(cvar_default_monster_dmg));
				gMonsterDamage[0] = get_pcvar_num(cvar_default_monster_dmg);
				was_monster_damage = 1;
			}
			
			if(equali(szData[0], "BOSS_DAMAGE"))
			{
				gMonsterDamage[1] = str_to_num(szData[2]);
				was_boss_damage = 1;
			}
			else if(was_boss_damage == 0)
			{
				log_to_file("TD_Wave.log", "Warning: Line %d | Map '%s' : Doesn't have info about boss damage, using default value '%d'", i, szFile, get_pcvar_num(cvar_default_boss_dmg));
				gMonsterDamage[1] = get_pcvar_num(cvar_default_boss_dmg);
				was_boss_damage = 1;
			}
			if(equali(szData[0], "TURRETS"))
			{
				if(equali(szData[2], "ON"))
					gTurretsAvailable = ENABLED
				else if(equali(szData[2], "OFF"))
					gTurretsAvailable = DISABLED
				else
				{
					log_to_file("TD_Wave.log", "Warning: Line %d | Map '%s' : Argument 'TURRET' has bad argument '%s' avalible 'ON' or 'OFF'.", i, szFile, szData[2]);
					gTurretsAvailable = DISABLED
				}
				was_turrets = 1
			}
			
			else if(was_turrets == 0)
			{
				log_to_file("TD_Wave.log", "Warning: Line %d | Map '%s' : Doesn't have info about turrets, turrets has been '%s'", i, szFile, get_pcvar_num(cvar_default_turrets)?"ENABLED":"DISABLED");
				gTurretsAvailable = get_pcvar_num(cvar_default_turrets)
				was_turrets = 1;
			}
			
			if(equali(szData[0], "CHANGE_TRACK_RANGE"))
			{
				gTrackRange = str_to_float(szData[2])
				was_range = 1
			}
			else if(was_range == 0)
			{
				log_to_file("TD_Wave.log", "Warning: Line %d | Map '%s' : Doesn't have info about range of change monster track, using defailtcvar value '%s' '%0.1f'", i, szFile, "td_track_range", get_pcvar_float(cvar_track_range));
				gTrackRange = get_pcvar_float(cvar_track_range)
				was_range = 1
			}
			
			if(equali(szData[0], "[LOAD_STANDARD_WAVE]"))
			{
				gLoadStandard = ENABLED;
				LoadWaveFromFile("standard_wave")
				return PLUGIN_CONTINUE;
			}
		}
			
	
			
		
		// **********************************
		// Powinno to wygladac tak:
		// szData[0] = "Wave"
		// szData[1] = X - Numer Wava
		// szData[2] = "-"
		// szData[3] = Typ Rundy
		// szData[4] = ":"
		// szData[5] = Liczba Potworow
		// szData[6] = ":"
		// szData[7] = Zycie Potworow na Wave
		// szData[8] = ":"
		// szData[9] = Float:Szybkosc Potworow
		// szData[10] = ew. "|"
		// szData[11] = ew. Zycie
		// szData[12] = ew. ":"
		// szData[13] = ew. Float:Szybkosc
		// **********************************
		
		// Ca³y system "programowania wavow"
		
		static oldwave;
		if(equali(szData[0], "Wave"))
		{
			new wave = str_to_num(szData[1]);
			
			if(wave > 0 && wave < MAX_WAVE && wave != oldwave)
			{
				repair_1:
				if(equali(szData[2], "-"))
				{
					if(equali(szData[3], "Normal"))
						gRoundType[wave] = MONSTER_NORMAL
					else if(equali(szData[3], "Fast"))
						gRoundType[wave] = MONSTER_FAST
					else if(equali(szData[3], "Strenght"))
						gRoundType[wave] = MONSTER_STRENGHT
					else if(equali(szData[3], "Bonus"))
						gRoundType[wave] = MONSTER_BONUS
					else if(equali(szData[3], "Boss"))
						gRoundType[wave] = MONSTER_BOSS
					else
					{
						log_to_file("TD_Wave.log", "Error: Line %d | File '%s' : Invalid Round Type : '%s'", i, szFile, szData[3]);
						LoadWaveFromFile("standard_wave");
						return PLUGIN_CONTINUE;
					}
					
					repair_2:
					if(equali(szData[4], ":"))
					{
						new monsters = str_to_num(szData[5])
						
						if((equali(szData[3], "Bonus") || equali(szData[3], "Boss")) && monsters == 0)
						{
							gRoundCount[wave] = -1;
							goto repair_3;
						}
						if(monsters > 0 && monsters <= MAX_MONSTER)
						{
							gRoundCount[wave] = monsters
							repair_3:
							
							if(equali(szData[6], ":"))
							{
								new health = str_to_num(szData[7])
								
								if((equali(szData[3], "Bonus") || equali(szData[3], "Boss")) && health == 0)
								{
									gRoundHealth[wave] = -1;
									goto repair_4;
								}
								if(health > 0)
								{
									gRoundHealth[wave] = health
									repair_4:
									if(equali(szData[8], ":"))
									{
										new Float:speed = str_to_float(szData[9])
										
										if((equali(szData[3], "Bonus") || equali(szData[3], "Boss")) && speed == 0.0)
										{
											gRoundSpeed[wave] = -1.0;
											goto repair_5;
										}
										if(speed > 1.0)
										{
											gRoundSpeed[wave] = speed
											repair_5:
											
											if(is_special_wave(wave))
											{
												if(equali(szData[10], "|"))
												{
													repair_6:
													
													if(gRoundType[wave] == MONSTER_BONUS)
													{
														health = str_to_num(szData[11])
														
														if(health > 0)
														{
															gRoundBonusHealth[wave] = health
															repair_bonus_7:
															if(equali(szData[12], ":"))
															{

																speed = str_to_float(szData[13])
																
																if(speed > 0.0)
																{
																	gRoundBonusSpeed[wave] = speed
																}
																else
																{
																	log_to_file("TD_Wave.log", "Error: Line %d | File '%s' : Bad Argument #11 - '%s' too low", i, szFile, szData[13]);
																	if(equali(szFile, "standard_wave"))
																	{
																		gGame = 0;
																		return PLUGIN_HANDLED
																	}
																	LoadWaveFromFile("standard_wave");
																	return PLUGIN_CONTINUE;
																}
															}
															else
															{
																log_to_file("TD_Wave.log", "Warning: Line %d | File '%s' : Bad Argument #12 - '%s', request ':", i, szFile, szData[12]);
																formatex(szData[12], 63, ":")
																goto repair_bonus_7;
															}
												
															
														}
														else
														{
															log_to_file("TD_Wave.log", "Error: Line %d | File '%s' : Bad Argument #13 - '%s' too low", i, szFile, szData[11]);
															if(equali(szFile, "standard_wave"))
															{
																gGame = 0;
																return PLUGIN_HANDLED
															}
															LoadWaveFromFile("standard_wave");
															return PLUGIN_CONTINUE;
														}
													}
													else if(gRoundType[wave] == MONSTER_BOSS)
													{
														health = str_to_num(szData[11])
														
														if(health > 0)
														{
															gRoundBossHealth[wave] = health
															repair_boss_7:
															if(equali(szData[12], ":"))
															{
																
																
																speed = str_to_float(szData[13])
																
																if(speed > 0.0)
																{
																	gRoundBossSpeed[wave] = speed
																}
																else
																{
																	log_to_file("TD_Wave.log", "Error: Line %d | File '%s' : Bad Argument #13 - '%s' too low", i, szFile, szData[13]);
																	if(equali(szFile, "standard_wave"))
																	{
																		gGame = 0;
																		return PLUGIN_HANDLED
																	}
																	LoadWaveFromFile("standard_wave");
																	
																	return PLUGIN_CONTINUE;
																}
															}
															else
															{
																log_to_file("TD_Wave.log", "Warning: Line %d | File '%s' : Bad Argument #12 - '%s', request ':", i, szFile, szData[12]);
																formatex(szData[12], 63, ":")
																goto repair_boss_7;
															}
														}
														else
														{
															log_to_file("TD_Wave.log", "Error: Line %d | File '%s' : Bad Argument #11 - '%s' too low", i, szFile, szData[11]);
															if(equali(szFile, "standard_wave"))
															{
																gGame = 0;
																return PLUGIN_HANDLED
															}
															gGame = 0;
															LoadWaveFromFile("standard_wave");
													
															return PLUGIN_CONTINUE;
														}
													}
												}
												else
												{
													log_to_file("TD_Wave.log", "Warning: Line %d | File '%s' : Bad Argument #10 - '%s', request '|", i, szFile, szData[10]);
													formatex(szData[8], 63, "|")
													goto repair_6;	
												}
											}
											
										}
										
										else
										{
											log_to_file("TD_Wave.log", "Error: Line %d | File '%s' : Bad Argument #9 - '%s' is invalid", i, szFile, szData[9]);
											if(equali(szFile, "standard_wave"))
											{
												gGame = 0;
												return PLUGIN_HANDLED
											}
											LoadWaveFromFile("standard_wave");
											gGame = 0;
											return PLUGIN_CONTINUE;
										}
										
									}
									else
									{
										log_to_file("TD_Wave.log", "Warning: Line %d | File '%s' : Bad Argument #8 - '%s', request ':'", i, szFile, szData[8]);
										formatex(szData[8], 63, ":")
										goto repair_4;	
									}
								}
								else
								{
									log_to_file("TD_Wave.log", "Error: Line %d | File '%s' : Bad Argument #7 - '%s', is too low", i, szFile, health);
									if(equali(szFile, "standard_wave"))
									{
										gGame = 0;
										return PLUGIN_HANDLED
									}
									LoadWaveFromFile("standard_wave");
									gGame = 0;
									return PLUGIN_CONTINUE;
								}
							}
							else
							{
								log_to_file("TD_Wave.log", "Warning: Line %d | File '%s' : Bad Argument #6 - '%s', request ':'", i, szFile, szData[6]);
								formatex(szData[6], 63, ":")
								goto repair_3;	
							}
							
						}
						else
						{
							log_to_file("TD_Wave.log", "Error: Line %d | File '%s' : Bad Argument #5 - '%s', is too low or greather than '%d'", i, szFile, szData[5], MAX_MONSTER);
							if(equali(szFile, "standard_wave"))
							{
								gGame = 0;
								return PLUGIN_HANDLED
							}
							LoadWaveFromFile("standard_wave");	
							return PLUGIN_CONTINUE;
						}
						
					}
					else
					{
						log_to_file("TD_Wave.log", "Warning: Line %d | File '%s' : Bad Argument #4 - '%s', request ':'", i, szFile, szData[4]);
						formatex(szData[4], 63, ":")
						goto repair_2;	
					}
					
				}
				else
				{
					log_to_file("TD_Wave.log", "Warning: Line %d | File '%s' : Bad Argument #3 - '%s', request '-'", i, szFile, szData[2]);
					formatex(szData[2], 63, "-")
					goto repair_1;
				}
			}
			else
			{
				if(wave <= oldwave || (oldwave+1 != wave))
					log_to_file("TD_Wave.log", "Error: Line %d | File '%s' : Bad Argument #2 - wave '%s' does not match do previous wave", i, szFile, szData[1]);
				else
					log_to_file("TD_Wave.log", "Error: Line %d | File '%s' : Bad Argument #2 - '%s', request constant integer value greather than 0 and lower than %d", i, szFile, szData[1], MAX_WAVE);
				if(equali(szFile, "standard_wave"))
				{
					gGame = 0;
					return PLUGIN_HANDLED
				}
				LoadWaveFromFile("standard_wave");
				
				return PLUGIN_CONTINUE;
			}
			oldwave = wave;
			gWaveNum++
		}
		else
		{
			if(equali(szData[0], "-end-"))
			{
				gGame = 1;
				return PLUGIN_CONTINUE;
			}
			if(equali(szData[0], "BASE_HEALTH") || equali(szData[0], "MONSTER_DAMAGE") || equali(szData[0], "BOSS_DAMAGE") || equali(szData[0], "TURRETS") || equali(szData[0], "CHANGE_TRACK_RANGE") || equali(szData[0], "[LOAD_STANDARD_WAVE]") || equali(szData[0], "[WAVE]"))
				continue
			
			log_to_file("TD_Wave.log", "Error: Line %d | File '%s' : Bad Argument #1 - '%s', request 'Wave' or '-End-'", i, szFile, szData[0]);
			
			if(equali(szFile, "standard_wave"))
			{
				gGame = 0;
				return PLUGIN_HANDLED
			}
			LoadWaveFromFile("standard_wave");
			return PLUGIN_CONTINUE;
		}
	}
	if(skip == 0) //Jezeli go nie posiada ("-Start-") zwraca blad i wczytuje standardowe wavy
	{
		log_to_file("TD_Wave.log", "Error | File '%s' : Doesn't have start line. '-Start-'", szFile)
		if(equali(szFile, "standard_wave"))
		{
			gGame = 0;
			return PLUGIN_HANDLED
		}
		LoadWaveFromFile("standard_wave");
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE
}

public CheckLoad(szFile[33]) //spradza wczytanie standardowych wavow
{
	if(equali(szFile, "standard_wave")) // jezeli to standardowe
	{
		log_to_file("TD_Wave.log", "Loading Standard Wave Completed. Checking waves...");

		if(gRoundType[1] == MONSTER_NONE) // jezeli plik jest zle napisany
		{
			log_to_file("TD_Wave.log", "Error - Game is not possible. Reason : Loading Standard Wave  - Error");
			gGame = 0
			return PLUGIN_CONTINUE
		}
		log_to_file("TD_Wave.log", "Checking Standard Wave - Not found any errors");
	}
	else
	{ // jezeli nie
		if(gRoundType[1] == MONSTER_NONE) // wczytaj standardowe
		{
			LoadWaveFromFile("standard_wave")
		}
	}
	return PLUGIN_CONTINUE
}
public LoadConfig()
{
	server_cmd("exec %s", gCvarConfigFile)
}

public LoadModels()//wczytuje modele
{
	new szText[128], len;
	new szTemp[4][128];
	new number;
	for(new i ; read_file(gModelsConfigFile, i, szText, 127, len) ; i++)
	{
		if(equali(szText, "") || equali(szText, ";"))
			continue;
			
		parse(szText, szTemp[0], 127, szTemp[1], 16, szTemp[2], 16, szTemp[3], 127)
		number++;
		
		if(equali(szTemp[0], "NORMAL_MDL")) // jezeli dla normalnych
		{
			copy(monster_normal_mdl[number-1], 33, szTemp[3])
			if(number >= 4)
				number = 0
		}	
		else if(equali(szTemp[0], "FAST_MDL")) // jezeli dla szybkich
		{
			copy(monster_fast_mdl[number-1], 33, szTemp[3])
			if(number >= 4)
				number = 0
		}
		else if(equali(szTemp[0], "STRENGHT_MDL")) // itd..
		{
			
			copy(monster_strenght_mdl[number-1], 33, szTemp[3])
			if(number >= 4)
				number = 0
		}
		else if(equali(szTemp[0], "BONUS_MDL"))
			copy(monster_bonus_mdl, 33, szTemp[3])
		
		else if(equali(szTemp[0], "BOSS_MDL"))
			copy(monster_boss_mdl, 33, szTemp[3])
		
		else if(equali(szTemp[0], "TOWER_MDL")) // jezeli wieza
			copy(tower_mdl, 33, szTemp[3])
	}
}
public PlayerMenu(id) // menu gracza
{
	new szTitle[64], szTurret[64], szShop[64];
	
	formatex(szTitle, 63, "Twoje punkty: \r%d", gPlayerPoints[id])
	
	
	formatex(szTurret, 63, "%s", gTurretsAvailable ? "Wiezyczki ^t\w[ \yWLACZONE\w ]":"\dWiezyczki na tej mapie sa wylaczone")
	if(!gGame || !gWave)
	{
		if(!gGame)
			formatex(szTurret, 63, "Wiezyczki ^t\w[ \yGra nie mozliwa\w ]")
		if(!gWave)
			formatex(szTurret, 63, "Wiezyczki ^t\w[ \yGra nie rozpoczela sie\w ]")
	}
	formatex(szShop, 63, "Sklep");
	
	new menu = menu_create(szTitle, "PlayerMenuHandler")
	new cb = menu_makecallback("PlayerMenuCb")
	
	menu_additem(menu, szTurret, _, _, cb)
	menu_additem(menu, "Umiejetnosci", _, _, cb)
	menu_additem(menu, szShop, _, _, cb)
	menu_additem(menu, "Ustawienia", _, _, cb)
	menu_display(id, menu);
}

public PlayerMenuCb(id, menu, item)
{

	if((item == 0 && gTurretsAvailable == DISABLED ) || (item == 0 && !is_user_alive(id)) || (item == 0 && (!gGame || !gWave)))
			return ITEM_DISABLED;
	
	// jezeli wiezyczki sa wylaczone albo gracz nie zyje
	// zablokuj
	// a tak to odblokuj
	return ITEM_ENABLED;
}

public PlayerMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	
	switch(item)
	{
		case 0: td_show_turrets_menu(id)
		//case 1: PlayerSkillMenu(id)
		case 2:  client_cmd(id, "say /sklep")
		case 3:	PlayerOptionsMenu(id)
	}
	return PLUGIN_CONTINUE
}

/*new gPlayerDamageCost[33]

public PlayerSkillMenu(id)
{
	new szTitle[128], szDamage[128]
	
	formatex(szTitle, 127, "Twoje Punkty: \r%d\w^nTwoje Umiejetnosci :", gPlayerPoints[id])
	
	formatex(szDamage, 127, "Obrazenia: \r%d \y \y[ \wDodatkowe: \r\r%d \wObrazen \y]", gPlayerDamage[id], gPlayerNewDamage[id])
	
	new menu = menu_create(szTitle, "PlayerSkillMenu1")
	new cb = menu_makecallback("PlayerSkillMenuCb")
	menu_additem(menu, szDamage, _, _, cb)
	
	menu_display(id, menu)
}
public PlayerSkillMenuCb(id, menu, item)
{
	if((item == 0 && gPlayerPoints[id] < (gPlayerDamage[id]*get_pcvar_num(cvar_upgrade_damage_cost))) || (item == 0 && gPlayerDamage[id] >= 10))
		return ITEM_DISABLED
	return ITEM_ENABLED
}

public PlayerSkillMenu1(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	
	switch(item)
	{
		case 0:
		{
			gPlayerPoints[id] -= ( gPlayerDamage[id] * get_pcvar_num(cvar_upgrade_damage_cost) )
			gPlayerDamage[id]++
			gPlayerNewDamage[id] = gPlayerDamage[id]*15			
		}
	}
	return PLUGIN_CONTINUE
}
*/
public PlayerOptionsMenu(id) //opcje gracza
{
	static szTitle[64], szAttackEffect[64], 
	szHealthBar[64]
	
	formatex(szTitle, 63, "Zmien swoje ustawienia :")
	formatex(szAttackEffect, 63, "Kolor efektu strzalu")
	formatex(szHealthBar, 63, "Pasek Zycia nad potworami")
	
	new menu = menu_create(szTitle, "PlayerOptionsMenuHandler")
	
	menu_additem(menu, szAttackEffect);
	menu_additem(menu, szHealthBar);
	
	menu_display(id, menu)
}

public PlayerOptionsMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	
	switch(item)
	{
		case 0: PlayerAttackEffectMenu(id)
		case 1: PlayerHealthBarMenu(id)
	}
	return PLUGIN_CONTINUE
}
public PlayerHealthBarMenu(id) //menu healthbara
{
	new szTitle[128], szItem[128];
	
	formatex(szTitle, 127, "Obecny pasek HP :\r Styl %d", ( gPlayerHealthBar[id] + 1 ) )
	
	new menu = menu_create(szTitle, "PlayerHealthBarMenuHandler")
	
	for(new i ; i < ( sizeof gEntityBar ) ; i++)
	{
		formatex(szItem, 127, "Styl \y%d", ( i + 1 ))
		menu_additem(menu, szItem);
	}
	menu_additem(menu, "Wstecz")
	menu_display(id, menu);
}

public PlayerHealthBarMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	if(item == (sizeof gEntityBar)+1)
	{
		PlayerOptionsMenu(id)
		return PLUGIN_CONTINUE
	}
	if(item == gPlayerHealthBar[id])
	{
		client_print(id, 3, "%s Nie mozesz wybrac tego samego stylu.", gPrefix)
		PlayerHealthBarMenu(id)
		return PLUGIN_CONTINUE
	} else {
		client_print(id, 3, "%s Zmieniles swoj styl z 'Styl %d', na 'Styl %d'.", gPrefix, ( gPlayerHealthBar[id] + 1 ), ( item + 1 ) )
		gPlayerHealthBar[id] = item;
	}
	return PLUGIN_CONTINUE
}

public PlayerAttackEffectMenu(id)//efekty strzalow
{
	new szTitle[128], szItem[128];
	
	formatex(szTitle, 127, "Obecny kolor :\r %s", gAttackEffectColorName[gPlayerAttackColor[id]])
	
	new menu = menu_create(szTitle, "PlayerAttackEffectMenuHandler")
	
	for(new i ; i < 7 ; i++)
	{
		formatex(szItem, 127, "%s", gAttackEffectColorName[i])
		menu_additem(menu, szItem)
	}
	
	menu_additem(menu, "Wstecz")
	menu_display(id, menu);
}

public PlayerAttackEffectMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	if(item == 7)
	{
		PlayerOptionsMenu(id)
		return PLUGIN_CONTINUE
	}
	if(gPlayerAttackColor[id] == item && item != 6) {
		client_print(id, 3, "%s Nie mozesz wybrac tego samego koloru.", gPrefix)
		PlayerAttackEffectMenu(id)
		return PLUGIN_CONTINUE
	}
	
	if(item == 6) // Niestandardowy
	{
		client_print(id, print_center, "Wpisz wartosc koloru 'RED' [ 0 - 255 ]", gPrefix)
		client_cmd(id, "messagemode changecolor_R")
	}
	else
	{
		client_print(id, 3, "%s Zmieniles kolor z '%s' na '%s'", gPrefix, gAttackEffectColorName[gPlayerAttackColor[id]], gAttackEffectColorName[item])
		gPlayerAttackColor[id] = item;
		
		gPlayerAttackColorValue[id][0] = gAttackEffectProperties[item][0]
		gPlayerAttackColorValue[id][1] = gAttackEffectProperties[item][1]
		gPlayerAttackColorValue[id][2] = gAttackEffectProperties[item][2]
	}

	return PLUGIN_CONTINUE
}

public ChangeAttackColorR(id) // zmiana koloru czerwonego
{
	new szArg[8], szValue;
	read_args(szArg, 7)
	
	remove_quotes(szArg)
	
	szValue = str_to_num(szArg)
	
	if(szValue < 0 || szValue > 255)
	{
		client_print(id, 3, "Wprowadzono nieprawidlowa wartosc: '%d', wpisz wartosc z zakresu [ 0 - 255 ]", gPrefix, szValue)
		client_cmd(id, "messagemode changecolor_R")
		return PLUGIN_CONTINUE
	}
	else
	{
		client_print(id, 3, "%s Zmieniono wartosc 'RED' na '%d'", gPrefix, szValue)
		gPlayerAttackColorValue[id][0] = szValue;
		client_print(id, print_center, "Wpisz wartosc koloru 'GREEN' [ 0 - 255 ]", gPrefix)
		client_cmd(id, "messagemode changecolor_G")
	}
	return PLUGIN_CONTINUE
}
public ChangeAttackColorG(id) // zielonego
{
	new szArg[8], szValue;
	read_args(szArg, 7)
	
	remove_quotes(szArg)
	
	szValue = str_to_num(szArg)
	
	if(szValue < 0 || szValue > 255)
	{
		client_print(id, 3, "Wprowadzono nieprawidlowa wartosc: '%d', wpisz wartosc z zakresu [ 0 - 255 ]", gPrefix, szValue)
		client_cmd(id, "messagemode changecolor_G")
		return PLUGIN_CONTINUE
	}
	else
	{
		client_print(id, 3, "%s Zmieniono wartosc 'GREEN' na '%d'", gPrefix, szValue)
		
		gPlayerAttackColorValue[id][1] = szValue;
		
		client_print(id, print_center, "Wpisz wartosc koloru 'BLUE' [ 0 - 255 ]", gPrefix)
		
		client_cmd(id, "messagemode changecolor_B")
	}
	return PLUGIN_CONTINUE
}
public ChangeAttackColorB(id)//niebieskiego
{
	new szArg[8], szValue;
	read_args(szArg, 7)
	
	remove_quotes(szArg)
	
	szValue = str_to_num(szArg)
	
	if(szValue < 0 || szValue > 255)
	{
		client_print(id, 3, "Wprowadzono nieprawidlowa wartosc : '%d', wpisz wartosc z zakresu [ 0 - 255 ]", gPrefix, szValue)
		client_cmd(id, "messagemode changecolor_B")
		return PLUGIN_CONTINUE
	}
	else
	{
		gPlayerAttackColorValue[id][2] = szValue;
		gPlayerAttackColor[id] = 6;

		client_print(id, 3, "%s Zmieniono Kolor Efektu Strzalu na [ %d, %d, %d ]", gPrefix, gPlayerAttackColorValue[id][0], gPlayerAttackColorValue[id][1], gPlayerAttackColorValue[id][2])
		PlayerAttackEffectMenu(id)
	}
	return PLUGIN_CONTINUE
}

public HudInfo(id) // pokazuje hud
{
	id -= TASKS[TASK_HUD_INFO]
	
	if(!is_user_connected(id) || is_user_hltv(id))
		return PLUGIN_CONTINUE
		
	set_task(2.0, "HudInfo", id+TASKS[TASK_HUD_INFO]); // 2.0 - czas odswiezania
		
	formatex(szTextHUD, 255, "[Wave: %d / %d] [Typ: %s]^n[Pozostalo potworow: %d ( %d ) / %d]^n[Punkty: %d] [HP Bazy: %d / %d]", gWave, gWaveNum, gWaveName[gRoundType[gWave]], gMonsterAlive, gSendsMonster, szCount?szCount:1, gPlayerPoints[id], gBaseHealth, gMaxBaseHealth)
	
	set_dhudmessage(255, 0, 0, 0.15, 0.0, 0, 6.0, 2.1, 0.0, 0.0)
	show_dhudmessage(id, szTextHUD)
	
	return PLUGIN_CONTINUE
	
}
public EndRoundLogEvent() // koniec rundy
{
	if(is_round())
		return PLUGIN_CONTINUE
		
	if(task_exists(TASKS[TASK_COUNTDOWN], 0))
		return PLUGIN_CONTINUE
	
	if(task_exists(TASKS[TASK_STARTWAVE], 0))
		return PLUGIN_CONTINUE
		
	gStart = 0
	
	if(gWave >= 1 && gGame)
		EndRound();
	
	return PLUGIN_CONTINUE
}

public NewRoundHLTV() // nowa runda
{
	if(is_round() || (get_playersnum()==1 && !OnlyOnePlayer) && !OnlyOnePlayer2)
		return PLUGIN_CONTINUE
	//jezeli trwa runda
	
	
	RemoveCountDown(0)
	
	remove_task(gWave)
	remove_task(TASKS[TASK_STARTWAVE])
	remove_task(TASKS[TASK_GAME_NOT_POSSIBLE])
	
	gWave++;
	gMonsterAlive = 0

	RemoveAllMonster()
	
	if(gGame) {
		set_task(1.0, "RoundInfo", gWave)
		set_task(float(get_pcvar_num(cvar_time_to_wave)), "StartWave", TASKS[TASK_STARTWAVE])
		
		set_task(1.0, "CountDown", TASKS[TASK_COUNTDOWN], _, _, "b")
	}
	else
		set_task(1.0, "GameIsNotPosibleInfo", TASKS[TASK_GAME_NOT_POSSIBLE])
		
	return PLUGIN_CONTINUE
}

new gSec = 0;

public RemoveCountDown(type) // usuwa task | type = info | !type = brak infa
{
	gSec = 0;
	if(type)
	{
		set_hudmessage(0, 212, 255, -1.0, 0.84, 1, 6.0, 3.0)
		ShowSyncHudMsg(0, SYNC_TIMELEFT , "NADCHODZA POTWORY!")
	}
	if(task_exists(TASKS[TASK_COUNTDOWN], 0))
		remove_task(TASKS[TASK_COUNTDOWN], 0)
}

public CountDown() // odliczanie
{
	
	if(gSec <= 0 && gGame) {
		new iRet;
		ExecuteForward(gForward_CountDown, iRet)
	}
	
	gSec++;
	
	if(gGame)
	{
		
		if(gWave && !gStart)
		{
			
			if(gSec > 0)
			{
				set_hudmessage(0, 212, 255, -1.0, 0.84, 0, 6.0, 1.01)
				ShowSyncHudMsg(0, SYNC_TIMELEFT , "Pozostaly czas : %d", (get_pcvar_num(cvar_time_to_wave)-gSec))
			}
			
		}
	}
	else
	{
		if(get_pcvar_num(cvar_time_to_wave)-gSec <= 0)
		{
			if(task_exists(TASKS[TASK_COUNTDOWN]))
				remove_task(TASKS[TASK_COUNTDOWN])
			
			ChangeMap()
		}
		
		set_hudmessage(0, 212, 255, -1.0, 0.84, 0, 6.0, 1.1)
		ShowSyncHudMsg(0, SYNC_TIMELEFT , "Zmiana mapy za : %d", get_pcvar_num(cvar_time_to_wave)-gSec)
	}
	return PLUGIN_CONTINUE
}
public ChangeMap() //zmienia mape
{
	new nextMap[33]
	get_cvar_string("amx_nextmap", nextMap, 32);
	
	server_cmd("changelevel %s", nextMap)
}

public StartWave() // rozpoczyna wave
{
	RemoveCountDown(1)
	gStart = 1;
	gMonsterAlive = 0
	gSendsMonster = 0
	
	switch(gRoundType[gWave])
	{
		case MONSTER_NORMAL:	SendMonsters(MONSTER_NORMAL, gRoundCount[gWave], gRoundHealth[gWave])
		case MONSTER_FAST:	SendMonsters(MONSTER_FAST, gRoundCount[gWave], gRoundHealth[gWave])
		case MONSTER_STRENGHT:	SendMonsters(MONSTER_STRENGHT, gRoundCount[gWave], gRoundHealth[gWave])
		case MONSTER_BONUS:
		{
			if(gRoundCount[gWave])
				SendMonsters(MONSTER_NORMAL, gRoundCount[gWave]+1, gRoundHealth[gWave])
			
			else if(gRoundCount[gWave] <= 0)
				SendMonsters(MONSTER_BONUS, -1, gRoundBonusHealth[gWave])
		}
		case MONSTER_BOSS:
		{
			if(gRoundCount[gWave])
				SendMonsters(MONSTER_NORMAL, gRoundCount[gWave]+1,gRoundHealth[gWave])
			
			else if(gRoundCount[gWave] <= 0)
				SendMonsters(MONSTER_BOSS,  -1, gRoundBossHealth[gWave])
		}
	}
	set_task(120.0, "Debug", gWave)
}

new tempType, tempNum, tempHealth, start;
public SendMonsters(Type, num, health) // wysylanie potworow
{
	if(gGame == 1)
	{
		num-=1
		
		
		if(!start) {
			start = 1;
			
			new iRet;
			ExecuteForward(gForward_StartWave, iRet, gWave, Type);
		}
		
		if(num < 1 && num >= (-2)) {
			
			start = 0;
			
			if(Type != MONSTER_BONUS && gRoundType[gWave] == MONSTER_BONUS)
			{
				SendMonsters(MONSTER_BONUS, -1, gRoundBonusHealth[gWave])
				
				return PLUGIN_CONTINUE
			}
			if(Type != MONSTER_BOSS && gRoundType[gWave] == MONSTER_BOSS)
			{
				SendMonsters(MONSTER_BOSS, -1, gRoundBossHealth[gWave])
				
				return PLUGIN_CONTINUE
			}
		}
		
		new ent = create_entity("info_target");
		
		entity_set_string(ent, EV_SZ_classname, "monster");
		
		static szModel[64], Float:Origin[3]
				
		switch(Type) //model zalezny od typu
		{
			case MONSTER_NORMAL:	formatex(szModel, 63, "models/TD/%s.mdl", monster_normal_mdl[random(4)])
			case MONSTER_FAST:	formatex(szModel, 63, "models/TD/%s.mdl", monster_fast_mdl[random(4)])
			case MONSTER_STRENGHT:	formatex(szModel, 63, "models/TD/%s.mdl", monster_strenght_mdl[random(4)])
			case MONSTER_BONUS:	formatex(szModel, 63, "models/TD/%s.mdl", monster_bonus_mdl)
			case MONSTER_BOSS:	formatex(szModel, 63, "models/TD/%s.mdl", monster_boss_mdl)
		}
		
		entity_set_model(ent, szModel);	
		entity_set_float(ent, EV_FL_health, float(health));
		entity_set_float(ent, EV_FL_takedamage, DAMAGE_YES);
		entity_set_size(ent, Float:{-20.0, -20.0, 0.0}, Float:{20.0, 20.0, 56.0});			
		entity_set_origin(ent, gStartOrigin);
		entity_set_vector(ent, EV_VEC_angles, Float:{0.0, 0.0, 0.0});
		
		entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY) 
		entity_set_int(ent, EV_INT_sequence, 4) // oodpowiada za animacje
		
		/*Szybkosc animacji wzgledem speeda += 5 :D*/
		
		static Float:szSpeed;
		
		if(Type != MONSTER_BOSS && Type != MONSTER_BONUS)
			szSpeed = gRoundSpeed[gWave]
		else if(Type == MONSTER_BOSS)
			szSpeed = gRoundBossSpeed[gWave]
		else if(Type == MONSTER_BONUS)
			szSpeed = gRoundBonusSpeed[gWave]
		
		szSpeed = ( szSpeed / 250.0 )
		
		set_pev(ent, pev_framerate, szSpeed);
		
		//****
		
		gMonsterAlive++;
		gSendsMonster++;
		
		set_pev(ent, pev_monster_track, 1)
		set_pev(ent, pev_monster_type, Type);
			
		//tworzy healthbara
		Origin[2] += 30.0
		
		new bar = create_entity("env_sprite")
		
		entity_set_string(bar, EV_SZ_classname, "monster_healthbar");
		entity_set_vector(bar, EV_VEC_origin, Origin)
		entity_set_model(bar, gEntityBar[0]);
		entity_set_int(bar, EV_INT_solid, SOLID_NOT);
		entity_set_int(bar, EV_INT_movetype, MOVETYPE_FLY) 
		
		set_pev(ent, pev_ent_health, bar)
		set_pev(ent, pev_max_health, health)
		set_pev(bar, pev_scale, 0.30);
		
		//think potwora
		entity_set_float(ent, EV_FL_nextthink, get_gametime()+0.01);

		if(num >= 1 && Type != MONSTER_BONUS && Type != MONSTER_BOSS)
		{
			tempType = Type
			tempNum = num
			tempHealth = health
			set_task(1.0, "Repeat") // 1.0 - czas wyslania nastepnego potwora
		}
	}
	return PLUGIN_CONTINUE
}
public Repeat() // sendmonsters 2
	if(gGame == 1)
		SendMonsters(tempType, tempNum, tempHealth)
		
public Debug(wave) // jezli cos sknocilem, ta funkcja to naprawia ;(
{
	if(is_round())
	{
		if(wave == gWave)
		{
			set_hudmessage(255, 255, 0, 0.29, 0.64, 2, 6.0, 4.0)
			show_hudmessage(0, "Rozpoczynam^nDebugowanie Gry")
			
			RemoveAllMonster()
			gStart = 0
			set_task(5.0, "DebugNext")
		}
	}
}
public DebugNext()
{
	set_hudmessage(255, 255, 0, 0.29, 0.64, 2, 6.0, 6.0)
	show_hudmessage(0, "Debugowanie Zakonczone!^nPrzepraszamy za bledy ;(")
	NewRoundHLTV()
}
public GameIsNotPosibleInfo() // jezeli gra nie jest mozliwa
{
	new szInfo[140], nextMap[33]
	get_cvar_string("amx_nextmap", nextMap, 32);
	
	formatex(szInfo, 139, "Gra jest niemozliwa z powodu bledow mapy lub zlej konfiguracji.^nPo skonczeniu odliczania mapa zostanie zmieniona na: ^n%s", nextMap);
	
	set_hudmessage(255, 255, 255, 0.24, 0.54, 0, 6.0, 12.0)
	ShowSyncHudMsg(0, SYNC_GAME_NOT_POSSIBLE, szInfo)
	
	set_task(1.0, "CountDown", TASKS[TASK_COUNTDOWN], _, _, "b")
}
public RoundInfo() // info na poczatku rundy
{

	static szInfo[128]
	new szAmount
	
	if(is_special_wave(gWave))
		szAmount = gRoundCount[gWave]+1
	else
		szAmount = gRoundCount[gWave]
	
	if(is_special_wave(gWave))
		formatex(szInfo, 127, "Wave: %d | Typ : %s [ %d %s ]", gWave, gWaveName[gRoundType[gWave]], (szAmount ? szAmount:1), (szAmount>=5?"Potworow":szAmount>1?"Potwory":szAmount==1?"Potwor":szAmount==0?"Potwor":""));
	else
		formatex(szInfo, 127, "Wave: %d | Typ : %s [ %d %s ]", gWave, gWaveName[gRoundType[gWave]], szAmount, (szAmount>=5?"Potworow":szAmount>1?"Potwory":szAmount==1?"Potwor":szAmount==0?"Potwor":""));
	
	static szTemp[64]
	
	if(is_special_wave(gWave) && szAmount)
	{	
		formatex(szTemp, 63, "^nHP: %d^nSzybkosc: %d", (gRoundHealth[gWave]?gRoundHealth[gWave]:0), (floatround( gRoundSpeed[gWave] ) ? floatround( gRoundSpeed[gWave] ): 0))
		add(szInfo, 127, szTemp);
	}
	else if(!is_special_wave(gWave) && szAmount)
	{
		formatex(szTemp, 63, "^nHP: %d^nSzybkosc: %d", (gRoundHealth[gWave]?gRoundHealth[gWave]:0), (floatround( gRoundSpeed[gWave] ) ? floatround( gRoundSpeed[gWave] ): 0))
		add(szInfo, 127, szTemp);
	}
	
	if(gRoundType[gWave] == MONSTER_BOSS)
	{
		formatex(szTemp, 64, "^n^nBOSS :^nHP: %d^nSzybkosc: %d", gRoundBossHealth[gWave], floatround( gRoundBossSpeed[gWave] ) )
		add(szInfo, 127, szTemp)
	}
	else if(gRoundType[gWave] == MONSTER_BONUS)
	{
		formatex(szTemp, 64, "^n^nBONUS:^nHP: %d^nSzybkosc: %d", gRoundBonusHealth[gWave], floatround( gRoundBonusSpeed[gWave] ) )
		add(szInfo, 127, szTemp)
	}
	
	replace_all(szInfo, 127, "-1", "0")
	
	if(gRoundCount[gWave] <= 0)
	{
		if(is_special_wave(gWave))
			szCount = 1
		else
			szCount = 0;
	}
	else
	{
		if(is_special_wave(gWave))
			szCount = gRoundCount[gWave]+1;
		else
			szCount = gRoundCount[gWave]
	}

	set_hudmessage(255, 255, 255, 0.24, 0.54, 1, 9.0, 15.0)
	ShowSyncHudMsg(0, SYNC_ROUNDINFO, szInfo)
}

public EndRound() // symuluje koniec rundy
{
	if(task_exists(TASKS[TASK_COUNTDOWN], 0))
		return PLUGIN_CONTINUE
	
	//DEBUG
	if(task_exists(949))
		remove_task(949)
		
	if(!task_exists(TASKS[TASK_ENDROUND], 0) && !task_exists(TASKS[TASK_COUNTDOWN], 0))
		set_task(10.0, "EndRound", TASKS[TASK_ENDROUND], _, _, "b")
	
	if(gRoundType[gWave] == MONSTER_BONUS && !gRoundCount[gWave] && !gStart && !gSendsMonster && !gMonsterAlive)
		return PLUGIN_CONTINUE
		
	if(gRoundType[gWave] == MONSTER_BONUS || gRoundType[gWave] == MONSTER_BOSS)
		if(gSendsMonster < gRoundCount[gWave]+1 && gRoundCount[gWave] > 0)
			return PLUGIN_CONTINUE	
	
	if(gMonsterAlive >= 1 || (gSendsMonster < gRoundCount[gWave] && gRoundCount[gWave] > 0))
		return PLUGIN_CONTINUE;
	
	RemoveCountDown(0)
	
	if(gWave+1 > gWaveNum) 
	{
		EndGame(0)
		return PLUGIN_CONTINUE
	}
	
	RemoveAllMonster()
	
	gWave++;
	gStart = 0
	gSendsMonster = 0
	
	if(gMonsterAlive < 0)
		gMonsterAlive = 0
	
	if(gGame)
	{
		set_task(1.0, "RoundInfo", gWave)
		set_task(float(get_pcvar_num(cvar_time_to_wave)), "StartWave")
		
		set_task(1.0, "CountDown", TASKS[TASK_COUNTDOWN], _, _, "b")
	}
	else
		set_task(1.0, "GameIsNotPosibleInfo", gWave)
		
	return PLUGIN_CONTINUE
}
//Jezeli atakujesz kogos - Nie odbiera mu Hp

public TakeDamagePlayer(this, idinflictor, attacker, Float:damage, damagebits) // gracze nie moga zadac sobie obrazen
{	
	if(is_user_alive(attacker) && is_user_alive(this))
		return HAM_SUPERCEDE
		;
	return HAM_IGNORED;
}

public MonsterThink(ent) //think potwora
{
	if(!pev_valid(ent))
		return PLUGIN_CONTINUE
	
	static Float:Origin[3]
	pev(ent, pev_origin, Origin);
		
	if(pev_valid(ent) && pev_valid(pev(ent, pev_ent_health))) // ustawia numer klatki sprita od healthbara
		set_pev( pev(ent, pev_ent_health) , pev_frame , 0.0 + ( pev( ent , pev_health ) * 100.0 ) / pev( ent , pev_max_health ) );
	
	static Float:Velocity[3], Float:fSpeed;
	// ustawia predkosc
	if(pev(ent, pev_monster_type) == MONSTER_NORMAL || pev(ent, pev_monster_type) == MONSTER_FAST || pev(ent, pev_monster_type) == MONSTER_STRENGHT)
		fSpeed = gRoundSpeed[gWave]
	
	if(pev(ent, pev_monster_type) == MONSTER_BONUS && pev_valid(ent))
	{
		fSpeed = gRoundBonusSpeed[gWave]
		set_glow(ent, 200, 255, 0, 16)
	}
	if(pev(ent, pev_monster_type) == MONSTER_BOSS && pev_valid(ent))
	{
		fSpeed = gRoundBossSpeed[gWave]	
		set_glow(ent, 255, 0, 0, 16)
	}
	
	/* Przechodzenie przez enty */
	
	new iEnt = getClosestMonster(ent)
	
	static Float:fOrigin15[3]
	static szTrack[33]
	static Float:Origin2[3];
	
	if(pev_valid(iEnt))
	{
		pev(iEnt, pev_origin, fOrigin15)
	
		if(get_distance_f(Origin, fOrigin15) <= 60.0 && (pev(ent, pev_monster_type) == MONSTER_BONUS || pev(ent, pev_monster_type) == MONSTER_BOSS))
			entity_set_int(iEnt, EV_INT_solid, SOLID_NOT)
		else 
			entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX)
	}
	/* Koniec */
	
	formatex(szTrack, 32, "track%d", pev(ent, pev_monster_track))//ustawia trase potwora

	new ent2 = find_ent_by_tname(-1, szTrack)
	
	if(!pev_valid(ent2)) // jezeli na mapie nie ma dalszych trackow to aut. idzie do enda
	{
		ent2 = find_ent_by_tname(-1, "end")
		
		if(!pev_valid(ent2))
			return PLUGIN_CONTINUE
			
		if(get_distance_f(Origin, gEndOrigin) <= gTrackRange) // jezeli doszedl do konca
		{
			new tower = find_ent_by_class(-1, "tower")
			
			set_pev(ent, pev_monster_track, 0)
			
			gMonsterAlive--;
						
			Explode()
						
			if(pev(ent, pev_monster_type) != MONSTER_BOSS)
				gBaseHealth-=gMonsterDamage[0];
			else
				gBaseHealth-=gMonsterDamage[1];
							
			if(pev_valid(tower)) { // odpowiada za obnizanie sie wiezyczki
				set_pev( pev(tower, pev_ent_health) , pev_frame , (0.0 + ((gBaseHealth * 100.0)  / gMaxBaseHealth )));
		
				new Float:szMax = float(gMaxBaseHealth)	
				new Float:szDamage;
								
				if(pev(ent, pev_monster_type) != MONSTER_BOSS)
					szDamage = float(gMonsterDamage[0])
				else
					szDamage = float(gMonsterDamage[1])
							
				new Float:szValue = ( szMax / szDamage )		
				gTowerOrigin[2] -= ( 225.0 / szValue )
										
				set_pev(tower, pev_origin, gTowerOrigin)
			}// ---
						
			//usun potwora i jego healthbar
			remove_entity(pev(ent, pev_ent_health));
			remove_entity(ent)
						
			if(gBaseHealth <= 0) {
				gBaseHealth = 0 //Usuwa bug ze wieza ma ponizej 0 hp
				EndGame(1)	
			}
			if(gMonsterAlive <= 0) //jezeli to byl ostatni potwor to zakoncz runde
				EndRound()	
			
			return PLUGIN_CONTINUE
		}
		else //jezeli jest dalej od enda
		{
			entity_set_aim(ent, ent2, Float:{0.0, 0.0, 0.0}, 0)//ustaw patrzenie na niego
			
			velocity_by_aim(ent, floatround(fSpeed), Velocity);//predksoc w kierunku patrzenia
			entity_set_vector(ent, EV_VEC_velocity, Velocity);//ustaw ta predkosc
			
			if(pev_valid(ent)) 
				entity_set_float(ent, EV_FL_nextthink, get_gametime()+0.08);
			return PLUGIN_CONTINUE
		}
	}

	if(equali(szTrack, "track", 5)) // jezeli nazwa klasy szTrack potowra przez piewrsze 5 liter jest rowna track
	{
		if(pev_valid(ent2)) // jezeli istnieje ent track
		{
			pev(ent2, pev_origin, Origin2)
			
			if(pev_valid(ent)) // jezeli istinieje monster
			{
				if(get_distance_f(Origin, Origin2) <= gTrackRange) // jezeli doszedl do konca
				{
					set_pev(ent, pev_monster_track, pev(ent, pev_monster_track)+1)
					entity_set_float(ent, EV_FL_nextthink, get_gametime()+0.08);
					return PLUGIN_CONTINUE
				}
				else // jezeli nie | tutaj ustawia sie predkosc i aim
				{
					entity_set_aim(ent, ent2, Float:{0.0, 0.0, 0.0}, 0)
					velocity_by_aim(ent, floatround(fSpeed), Velocity);
					entity_set_vector(ent, EV_VEC_velocity, Velocity);
				}
			}
		}
	}
	
	entity_set_float(ent, EV_FL_nextthink, get_gametime()+0.08);
		
	return PLUGIN_CONTINUE
}

public EndGame(Type) // konczy gre | 0 = win | 1 = lose
{
	if(Type != 0 && Type != 1)
		return PLUGIN_CONTINUE;
	
	RemoveAllMonster()
	
	gStart = 0;
	new temp[2], szMsg[256], szNick[33], szFrag
	 
	if(task_exists(TASKS[TASK_COUNTDOWN]))
		remove_task(TASKS[TASK_COUNTDOWN])
		
	if(task_exists(TASKS[TASK_STARTWAVE]))
		remove_task(TASKS[TASK_STARTWAVE])
	
	if(task_exists(TASKS[TASK_GAME_NOT_POSSIBLE]))
		remove_task(TASKS[TASK_GAME_NOT_POSSIBLE])
		
	if(task_exists(TASKS[TASK_ENDROUND]))
		remove_task(TASKS[TASK_ENDROUND])
		
	renew:
	static ag;
	/*Szuka najlepszego gracza*/
	for( new i = 1 ; i < 33 ; i ++ )
	{
		if(!is_user_connected(i) || is_user_hltv(i))
			continue;
			
		if(get_user_frags(i) > temp[0])
		{
			temp[0] = get_user_frags(i)
			temp[1] = i;
		}
	}
	ag++
	szFrag = temp[0]
	/* */
	
	get_user_name(temp[1], szNick, 32)
	
	if(szFrag <= 0 || get_user_index(szNick) <= 0 || !is_user_connected(temp[1])) // jezeli nie ma zwyciezcy
	{
		if(!is_user_connected(temp[1]) && ag<=2)
			goto renew;
			
		if(Type == 0) //wygrali
		{
			formatex(szMsg, 256, "Obroncy zamku WYGRALI wojne z potworami!")
		
			set_hudmessage(255, 255, 170, 0.14, 0.80, 0, 6.0, 25.0)
			ShowSyncHudMsg(0, gSync8, "Dziekujemy za gre :)^nZmiana mapy nastapi za 25 sekund!")
			
			set_task(25.0, "ChangeMap")
		}
		else if(Type == 1) //przegrali
		{
			formatex(szMsg, 256, "Obroncy zamku PRZEGRALI wojne z potworami!")
			
			set_task(0.1, "Explode")
			set_task(1.0, "Explode")
			set_task(2.0, "Explode")
			set_task(2.5, "Explode")
			set_task(3.0, "Explode")
			set_task(4.0, "Explode")
			set_task(4.4, "Explode")
			set_task(4.8, "Explode")
			set_task(5.0, "Explode")
			set_task(6.6, "Explode")
			set_task(6.6, "RemoveTower")
			
			set_hudmessage(255, 255, 170, 0.14, 0.80, 0, 6.0, 25.0)
			ShowSyncHudMsg(0, gSync8, "Zmiana mapy nastapi za 25 sekund.")
			
			set_task(25.0, "ChangeMap")
		}
		return PLUGIN_CONTINUE
	}
	//jezeli jest zwyciezca 
	if(Type == 0) // wygrali
	{
		formatex(szMsg, 256, "Obroncy zamku WYGRALI wojne z potworami!^nNajlepszym graczem jest: '%s' z '%d' zabiciami! Gratulujemy", szNick, szFrag)
		
		set_hudmessage(255, 255, 170, 0.14, 0.80, 0, 6.0, 25.0)
		ShowSyncHudMsg(0, gSync8, "Dziekujemy za gre :)^nZmiana mapy nastapi za 15 sekund!")
		
		set_task(15.0, "ChangeMap")
	}
	else if(Type == 1) //przegrali
	{
		formatex(szMsg, 256, "Obroncy zamku PRZEGRALI wojne z potworami!^nNajlepszym graczem byl: '%s' z '%d' zabiciami! Gratulujemy", szNick, szFrag)
		
		set_task(0.1, "Explode")
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
		
		set_hudmessage(255, 255, 170, 0.14, 0.80, 0, 6.0, 25.0)
		ShowSyncHudMsg(0, gSync8, "Zmiana mapy nastapi za 25 sekund.")
		
		set_task(25.0, "ChangeMap")
	}
	
	set_hudmessage(255, 255, 255, 0.16, -1.0, 0, 6.0, 25.0)
	ShowSyncHudMsg(0, gSync7, szMsg)
	
	return PLUGIN_CONTINUE;
}

//Usuwa wszystkie potwory
public RemoveAllMonster()
{
	new iEnt = find_ent_by_class(-1, "monster")

	while(iEnt > 0)
	{	
		gMonsterAlive = 0;
		gSendsMonster = 0;
		remove_entity(pev(iEnt, pev_ent_health))
		remove_entity(iEnt)
		iEnt = find_ent_by_class(iEnt, "monster")
	}
}

public fwAddToFullPack(es_handle, e, ENT, HOST, hostflags, player, set)
{
	if(player || ENT <= 32 || !is_user_connected(HOST) || !pev_valid(ENT)) 
		return FMRES_IGNORED;
		
	static Float:fOrigin[ 3 ]
	;
	if(pev(ENT, pev_monster_type)) // jezeli ten ent ma typ
	/* Tutaj ta funkcja wykonuje sie baaaaaaaaaaardzo szybko, i zwracajac uwage na 
	optymalne dzialanie, staralem sie nie sprawdzac klasy, tylko sprawdzic ogolna ceche tego potwora
	czyli akurat wypadlo na typ bo 0 to none a powyzej to same dobre typy*/
	{
		if(pev_valid(pev(ENT, pev_ent_health))) //jezeli healthbar istnieje
		{
			static classname[20]
			pev(pev(ENT,pev_ent_health), pev_classname, classname, 19)
			if(equali(classname, "monster_healthbar")) // jezeli to 100% healthbar
			{
				/*I tutaj musialem zastosowac to sprawdzanie klasy, czy to jest na 100% health bar, gdyz 
				wiele problemow bylo wlasnie ze zamiast ustawiac origin healthbara, ustawialo origin 
				wiezyczki i niestety, bylem zmuszony do zastosowania tak drastycznej metody*/
				
				pev(ENT , pev_origin , fOrigin );
				
				//nad glowa potwora
				fOrigin[ 2 ] += 45.0;
				
				//origin
				set_pev(pev(ENT, pev_ent_health), pev_origin, fOrigin)
				//model
				entity_set_model(pev(ENT, pev_ent_health), gEntityBar[gPlayerHealthBar[HOST]]);
			}
		}
			
		return FMRES_IGNORED
	}
	return FMRES_IGNORED;
}


public RemoveTower() // usuwa wieze
{
	new ent = find_ent_by_class(-1, "tower")
	if(pev_valid(ent))
		remove_entity(ent)
}
public Explode() //wybuch nad wieza
{
	new Origin[3]
	FVecIVec(gTowerOrigin, Origin)
	Origin[2]+= 275 // wysokoc wybuchu nad wieza
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(Origin[0])	// start position
	write_coord(Origin[1])
	write_coord(Origin[2])
	write_short(gExplode)	// sprite index
	write_byte(50)	// scale in 0.1's
	write_byte(10)	// framerate
	write_byte(0)	// flags
	message_end()
}

public ResetAll() // usuwa wszystkie dane | resetuje gre
{
	new iRet;
	ExecuteForward(gForward_ResetAll, iRet)
	
	RemoveCountDown(0)
	RemoveAllMonster()
	
	for(new i; i < 33; i++)
		deletePlayerInfo(i)
	
	gTurretsAvailable= get_pcvar_num(cvar_default_turrets)
	gBaseHealth 	= gMaxBaseHealth
	gMonsterAlive 	= 0
	gSendsMonster 	= 0
	gWave 		= 0
	
}



stock entity_set_aim(ent1, ent2, Float:offset2[3], region)
{
	if(!is_valid_ent(ent1) || !is_valid_ent(ent2) || ent1 == ent2)
		return 0;
	
	static Float:offset[3]
	offset[0]=offset2[0], offset[1]=offset2[1], offset[2]=offset2[2]
	static Float:ent1origin[3]
	static Float:ent2origin[3]
	static Float:view_angles[3]
	
	entity_get_vector(ent2,EV_VEC_origin,ent2origin)
	
	if(ent1>32) 
		entity_get_vector(ent1,EV_VEC_origin,ent1origin)
	else
	{
		new origin[3]
		get_user_origin(ent1,origin,1)
		IVecFVec(origin,ent1origin)
	}
	
	new bool:player
	new buttons
	
	if(ent2<=32)
	{
		player=true
		get_user_button(ent2)
	}
	else
	{
		player=false
		buttons=0
	}
	
	switch(region)
	{
		case 1:
		{
			if(player)
			{
				new origin2[3]
				get_user_origin(ent2,origin2,1)
				IVecFVec(origin2,ent2origin)
				offset[0] += 7.0
				//offset[1] += 7.0
				offset[2] += 5.0
			}
			else
				offset[2] += 30.173410
		}
		case 2:
		{
			if(player && (buttons & IN_DUCK))
			{
				offset[2] += (17.271676 / 2.0)
			}
			else
				offset[2] += 17.271676
		}
		case 3:
		{
			if(player && (buttons & IN_DUCK))
			{
				offset[0] += (12.000000 / 2.0)
				offset[2] += (11.028901 / 2.0)
			}
			else
			{
				offset[0] += 12.000000
				offset[2] += 11.028901
			}
		}
		case 4:
		{
			if(player && (buttons & IN_DUCK))
			{
				offset[0] += (-12.000000 / 2.0)
				offset[2] += (11.028901 / 2.0)
			}
			else
			{
				offset[0] += -12.000000
				offset[2] += 11.028901
			}
		}
		case 5:
		{
			if(player && (buttons & IN_DUCK))
			{
				offset[0] += (8.000000 / 2.0)
				offset[2] += (-19.768786 / 2.0)
			}
			else
			{
				offset[0] += 8.000000
				offset[2] += -19.768786
			}
		}
		case 6:
		{
			if(player && (buttons & IN_DUCK))
			{
				offset[0] += (-8.000000 / 2.0)
				offset[2] += (-19.768786 / 2.0)
			}
			else
			{
				offset[0] += -8.000000
				offset[2] += -19.768786
			}
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

stock GiveAmmo(id, liczba){ //ustawia amunicje
	if(is_user_alive(id) && is_user_connected(id) && !is_user_hltv(id)){
		new weapon = get_user_weapon(id)
		if(weapon != 29) cs_set_user_bpammo(id, weapon, cs_get_user_bpammo(id, weapon)+liczba);
	}
}

/*stock msg_lavasplash(Origin[3]){
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY, Origin) //message begin
	write_byte(TE_LAVASPLASH)
	write_coord(Origin[0]) // start position
	write_coord(Origin[1])
	write_coord(Origin[2])
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
	
}*/

stock msg_dlight(Origin[3], radius, Color[3], times, decay) { // al'a swiatlo 
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY, Origin, 0) //message begin
	write_byte(TE_DLIGHT)
	write_coord(Origin[0]) // position
	write_coord(Origin[1])
	write_coord(Origin[2])
	write_byte(radius) // radius in 10's
	write_byte(Color[0]) //colour
	write_byte(Color[1])
	write_byte(Color[2])
	write_byte(times) // life in 10's
	write_byte(decay) // decay rate in 10's
	message_end()
}

public is_monster(ent) {
	if(!pev_valid(ent) ) return 0
	
	static classname[20]
	entity_get_string(ent, EV_SZ_classname, classname, 19)
	
	if(equali(classname, "monster")) return 1

	return 0
}
public is_healthbar(ent) {
	if(!pev_valid(ent)) return 0
	
	static classname[20]
	entity_get_string(ent, EV_SZ_classname, classname, 19)
	
	if(equali(classname, "monster_healthbar")) return 1

	return 0
}
public is_special_wave(wave){
	if(gRoundType[wave] == MONSTER_BONUS || gRoundType[wave] == MONSTER_BOSS) return 1;
	
	return 0;
}

public is_round(){
	if(gMonsterAlive || !task_exists(TASKS[TASK_COUNTDOWN], 0) && gStart) return 1;
	
	return 0
}


/////////////////////////

stock fx_blood(origin[3], size){ //efekt krwi
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0]+random_num(-20,20))
	write_coord(origin[1]+random_num(-20,20))
	write_coord(origin[2]+random_num(-20,20))
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(229) // color index
	write_byte(size) // size
	message_end()
}

stock death_msg(id, ent) {  //usatwia efekt zabicia w prawym gornym rogu
	if(get_playersnum() <= 1)
		return PLUGIN_CONTINUE
	static szName[33], szNick[33];
	
	static iFind
	for(new i; i < MAX_PLAYERS+1 ; i++) {
		if(is_user_connected(i) && !is_user_hltv(i) && i != id && get_user_team(i) != get_user_team(id))
			if(iFind != i) {
				iFind = i;
				break;
			}
	}
	
	if(!iFind) {
		return PLUGIN_CONTINUE;
	}
	
	get_user_name(iFind, szName, 32);
	
	formatex(szNick, 32, "%s %s", gMonsterPrefix, gWaveName[pev(ent, pev_monster_type)]);

	set_user_info(iFind, "name", szNick)
	new Params[34]
	copy(Params, 32, szName)
	Params[33] = id
	set_task(0.1, "ResetDeath", iFind, Params, 34)
	
	return PLUGIN_CONTINUE
	
}
public ResetDeath(Params[], id) //usatwia efekt zabicia w prawym gornym rogu 2
{
	new id2 = Params[33]
	new szNick[33];
	copy(szNick, 32, Params);
	
	set_msg_block(get_user_msgid("DeathMsg"),BLOCK_ONCE)
	message_begin(MSG_ALL, get_user_msgid("DeathMsg")) 
	write_byte(id2)
	write_byte(id)
	write_byte(0)
	message_end()
	
	set_user_info(id, "name", szNick);
}
DMG_BL
stock set_glow(id, r,g,b, width)
	set_rendering(id, kRenderFxGlowShell, r, g, b, kRenderNormal, width)

public ShowPlayerMonsterHp(id)
{
	id -= TASKS[TASK_SHOW_MONSTER_HP]
	
	if(!is_user_alive(id))	
		return PLUGIN_CONTINUE
	
	static Float:AimedOrigin[3]
	static Origin[3]
	
	get_user_origin(id, Origin, 3)
	
	IVecFVec(Origin, AimedOrigin)
	
	new entlist[3] // maxymalna liczba entow zapisanych
	find_sphere_class(0, "monster", 80.0, entlist, 2, AimedOrigin)
	
	if(!pev_valid(entlist[0]))
	{
		set_task(1.0, "ShowPlayerMonsterHp", id+TASKS[TASK_SHOW_MONSTER_HP])
		return PLUGIN_CONTINUE
	}
		
	client_print(id, print_center, "HP: %d", pev(entlist[0], pev_health))
	
	set_task(1.0, "ShowPlayerMonsterHp", id+TASKS[TASK_SHOW_MONSTER_HP])
	
	return PLUGIN_CONTINUE
}
stock getClosestMonster(ent) //szuka najblizszego potwora wokol enta
{ 
	if(!pev_valid(ent))
		return PLUGIN_CONTINUE
		
	new Float:flDistanse
	flDistanse = 99999.0
	static Float:fOrigin[2][3];
	
	pev(ent, pev_origin, fOrigin[0]) //Pobiera origin entu u ktorego ma szukac
	
	new tempEntID = 0; //zapisuje najblizszego enta
	
	new entlist[10] // maxymalna liczba entow zapisanych
	
	new num
	num = find_sphere_class(ent, "monster", flDistanse, entlist, 9)// zwraca liczbe wyszukanych obiektow
	
	if(num <= 0)
		return 0;
		
	for(new i ; i < num ; i++) {
		if(entlist[i] == ent || !pev_valid(entlist[i]))
			continue;
		pev(entlist[i], pev_origin, fOrigin[1]);
		
		if(get_distance_f(fOrigin[0], fOrigin[1]) < flDistanse){
			flDistanse = get_distance_f(fOrigin[0], fOrigin[1]);
			tempEntID = entlist[i];
		}	
	}
	return tempEntID;
}

/////////////////////////////

public _get_wave_monster_num(wave) {
	if(wave > MAX_WAVE)
		return 0;
		
	return gRoundCount[wave];
}

public _get_wave_type(wave) {
	if(wave > MAX_WAVE)
		return MONSTER_NONE;
		
	return gRoundType[wave]
}

public _get_wave_health(wave) {
	if(wave > MAX_WAVE)
		return 0;
	
	return gRoundHealth[wave]
}

public Float:_get_wave_speed(wave) {
	if(wave > MAX_WAVE)
		return 0.0;
	
	return gRoundSpeed[wave]
}

public Float:_get_wave_bonus_speed(wave) {
	if(!is_special_wave(wave) || wave > MAX_WAVE)
		return 0.0;
	
	return gRoundBonusSpeed[wave]
}

public Float:_get_wave_boss_speed(wave) {
	if(!is_special_wave(wave) || wave > MAX_WAVE)
		return 0.0;
	
	return gRoundBossSpeed[wave]
}

public _get_wave_bonus_health(wave) {
	if(wave > MAX_WAVE || !is_special_wave(wave)) 
		return 0;
	
	return gRoundBonusHealth[wave];
}

public _get_wave_boss_health(wave) {
	if(wave > MAX_WAVE || !is_special_wave(wave)) 
		return 0;
	
	return gRoundBossHealth[wave];
}

public _get_wave() {
	return gWave
}
public _get_max_wave()
	return MAX_WAVE;

public _get_max_monster()
	return MAX_MONSTER;
	

public _get_player_points(index) {
	if(is_user_connected(index))
		return gPlayerPoints[index]
	
	return 0;
}

public _set_player_points(index, amount)
	if(is_user_connected(index))
		gPlayerPoints[index] = amount

public _get_game_status()
	return gGame;

public _get_monster_name(type, szName[], iLen) 
	if(type <=  sizeof gWaveName) 
		copy(szName, iLen, gWaveName[type]);
	
public _set_game_status(value)
	gGame = value;
	
public _is_game_started()
	return gStart;
	
public _is_turret_on(){
	if(gTurretsAvailable == ENABLED)
		return 1;
	
	return 0;
}
