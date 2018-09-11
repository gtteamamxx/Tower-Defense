#if defined _towerdefense_included
  #endinput
#endif
#define _towerdefense_included

#if !defined towerdefense_const_included
	#include <td_const>
#endif

#if !defined _towerdefense_turrets_included
	#include <td_turrets>
#endif

/* Returns max waves limit */
native td_get_max_wave();

/* Returns max monsters limit per wave */
native td_get_max_monsters_num();

/* Returns max player level */
native td_get_max_player_level();

/* Returns '1' if player is VIP */
native td_is_user_vip(iPlayer);

/* Returns  '1' if is special round BOSS, BONUS*/
native td_is_special_wave(iWave);

/* Returns  '1' if entity is BOSS, '2' if entity is BONUS otherwise 0*/
native td_is_special_monster(iEnt);

/* Returns  '1' if entity is healthbar*/
native td_is_healthbar(iEnt);

/* Returns  '1' if entity is monster */
native td_is_monster(iEnt);

/* Returns '1' if game is possible */
native td_is_game_possible();

/* Returns actual wave */
native td_get_actual_wave();

/* Sets wave, Returns 1 if wave has been setted, otherwise 0*/
native td_set_actual_wave(iWave);

/* Returns a wave info */
native td_get_wave_info(iWave, ENUM_WAVE_INFO:iInfo);

/* Sets a wave info
	@WARNING: Round Type you must set before wave started
*/
native td_set_wave_info(iWave, ENUM_WAVE_INFO:iInfo, _:iValue);

/* Returns a player info */
native td_get_user_info(iPlayer, ENUM_PLAYER:iInfo);

/* Sets a player info */
native td_set_user_info(iPlayer, ENUM_PLAYER:iInfo, iValue);

/* Returns player hud size option */
native td_get_user_hud_size(iPlayer);

/* Returns 1 if monster is premium monster */
native td_is_premium_monster(iEnt);

/* Returns monster type */
native td_get_monster_type(iEnt);

/* Returns monster speed
   @Param: if defaultspeed is '1' then will be returned default speed of monster (depends of monster type)
		if defualtspeed is '0' then will be returned actual monster speed
*/
native td_get_monster_speed(iEnt, defaultspeed=0);

/* Sets monster speed
	@Param: if defaultspeed is '1' then will be set normal monster speed, if '0' then the speed from 'speed' param.
	@Param: if now is '1' then monster will be slowed/fastest just after using this function, if '0' after changed track
*/
native td_set_monster_speed(ent, speed, defaultspeed = 0, now = 1);

/* Returns monster HP */
native td_get_monster_health(iEnt);

/* Returns id[ent] healthbar of monster*/
native td_get_monster_healthbar(iEnt);

/* Returns a 'start' entity origins (monster respawns) */
native td_get_start_origin(Float:outOrigin[3]);

/* Returns a 'end' entity origins (tower origin) */
native td_get_end_origin(Float:outOrigin[3]);

/* Kill monster by player */
native td_kill_monster(iEnt, iPlayer);

/* Returns true if is tower model on map */
native td_is_tower_model_on_map();

/* Removes tower model. Returns '1' if model will be deleted, otherwise 0 */
native td_remove_tower();

/* Killing all monsters */
native td_remove_monsters();

/* Register a shop item
	@Note:
	iPluginIndex = is a index which you must set when you eg. registering plugin.
	example:
	new iPluginIndex = register_plugin(A, B, C);
*/
native td_shop_register_item(const szName[], const szDescription[], const iPrice, const iOnePerMap = 0, iPluginIndex);

/* Register a player class */
native td_register_class(const szClassName[], const szClassDescription[], iPluginIndex);

/* Sets a tower health */
native td_set_tower_health(iAdd = 1, iHealth, iExplode = 0);

/* Returns a tower health */
native td_get_tower_health();

/* Returns max tower health on map */
native td_get_max_tower_health();

/* If game is ended, returns PLAYERS_WIN or PLAYERS_LOSE. Otherwise PLAYERS_PLAYING */
native td_get_end_status();

/* Zwraca czas, jaki jest odejmowany przy sterowania thinami.
	Na przyk³ad Install Time = 5.0 - ExtraTime
*/
native Float:td_get_player_extra_time(index);

/* Ustawia extra czas */
native td_set_player_extra_time(index, Float:fTime);

/* Return maxhealth of monster */
native td_get_monster_maxhealth(iEnt);

native td_give_user_napalm_grenade(index);

native td_give_user_frozen_grenade(index);

native td_give_user_stop_grenade(index);

native td_get_chat_prefix(szOutpout[], len);

native td_get_log_file_name(szOutpout[], len);

/* Returns '1' if wave is now played */
native td_is_wave_started();
/* ============================ */
/*           Forwards           */
/* ============================ */

/* Wykonywany podczas odswiezania ustawien (cvary itp) */
forward td_settings_refreshed();

/* Wykonwywany przy rozpoczeciu wave'u */
forward td_wave_started(iWave, iMonsterType, iNum)

/* Wykonwywany przy zakonczeniu wave'u */
forward td_wave_ended(iEndedWave);

/* Wykonywany przy zakonczeniu gry
	@iEndResult - PLAYER_WIN / PLAYER_LOSE
*/
forward td_game_ended(iEndResult);

/* Wykonywany przed zabiciem potwora */
forward td_monster_killed(iEnt, iPlayer, iMonsterType, IsKilledByWeapon);

/* Wykonywany podczas kupienia przedmiotu w sklepie */
forward td_shop_item_selected(iPlayer, iItemId);

/* Wykonywany podczas wybrania klasy */
forward td_class_selected(iPlayer, iClassIndex);

/* Wykonywany podczas wylaczania klasy */
forward td_class_disabled(iPlayer, iClassIndex);

/* Wykonywany podczas resetowania gry */
forward td_reset_game(iMode, Float:fTime);

/* Wykonywany przy resetowaniu wszystkich informacji u gracza */
forward td_reset_player_info(iPlayer);

/* Wykonywany przed zadaniem obrazen potworowi
	@UWAGA: Tylko przy DMG_BULLET
	szInDamage[0] = INT Damage
	szInDamage[1] = isCritical
*/
forward td_take_damage(iPlayer, iEnt, iWeapon, Float:fOutDamage, szInDamage[3]);

/* Wykonywany po zadaniem obrazen potworowi
	@UWAGA: Tylko przy DMG_BULLET
	szInDamage[0] = INT Damage
	szInDamage[1] = isCritical
*/
forward td_take_damage_post(iPlayer, iEnt, iWeapon, Float:fOutDamage, szInDamage[3]);

/* Wykonywany przy starcie odliczania do nastepnego wave
	@iToWhichWave 	Zwraca numer wav'e dla ktorego odlicza, przykladowo
			weszli pierwsi gracze, wiec iToWhichWave zwroci wratosc 1,
			poniewaz po odliczaniu bedzie wave nr. 1,
			natomiast po przejciu 2 wavu, odlicza do 3
*/
forward td_countdown_started(iToWhichWave);

/* Executed 1 second before map change */
forward td_remove_data();
