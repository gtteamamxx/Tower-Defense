#if defined _towerdefense_included
  #endinput
#endif
#define _towerdefense_included

#if !defined towerdefense_const_included
	#include <td_const>
#endif

/* Returns max waves limit */
native td_get_max_wave()

/* Returns max monsters limit per wave */
native td_get_max_monsters()

/* Returns max player level */
native td_get_max_level()

/* Returns  '1' if is special round BOSS, BONUS*/
native td_is_special_wave(iWave)

/* Returns  '1' if entity is BOSS, '2' if entity is BONUS*/
native td_is_special_monster(iEnt)

/* Returns  '1' if entity is healthbar*/
native td_is_healthbar(iEnt)

/* Returns  '1' if entity is monster*/
native td_is_monster(iEnt)

/* Returns game status */
native eGame:td_get_game_status()

/* Sets game status */
native td_set_game_status(eGame:iStatus)

/* Returns actual wave */
native td_get_wave()

/* Sets wave */
native td_set_wave(iWave)

/* Returns a loaded waves num */
native td_get_wavenum()

/* Returns a wave info */
native td_get_wave_info(iWave, e_WaveInfo:iInfo)

/* Sets a wave info
	@WARNING: Round Type you must set before wave started
*/
native td_set_wave_info(iWave, e_WaveInfo:iInfo, _:iValue)

/* Returns a player info */
native td_get_user_info(iPlayer, e_Player:iInfo)

/* Sets a player info */
native td_set_user_info(iPlayer, e_Player:iInfo, iValue)

/* Returns monster type */
native e_RoundType:td_get_monster_type(iEnt)

/* Returns monster speed
   @Param: if defaultspeed is '1' then will be returned default speed of monster (depends of monster type)
		if defualtspeed is '0' then will be returned actual monster speed
*/
native td_get_monster_speed(iEnt, defaultspeed=0)

/* Sets monster speed
	@Param: if defaultspeed is '1' then will be set normal monster speed, if '0' then the speed from 'speed' param.
	@Param: if now is '1' then monster will be slowed/fastest just after using this function, if '0' after changed track
*/

native td_set_monster_speed(ent, speed, defaultspeed=0, now=1)

/* Returns monster HP */
native td_get_monster_health(iEnt)

/* Returns id[ent] healthbar of monster*/
native td_get_monster_healthbar(iEnt)

/* Returns a 'start' entity origins (monster respawns) */
native td_get_start_origin(Float:outOrigin[3])

/* Returns a 'end' entity origins (tower origin) */
native td_get_end_origin(Float:outOrigin[3])

/* Returns round name */
native td_get_round_name(e_RoundType:iRoundType, szOutpout[], len)

/* Kill monster as player */
native td_kill_monster(iEnt, id)

/* Returns a max turrets can be placed on map*/
native td_get_max_map_turrets()

/* Removing a tower model */
native td_remove_tower()

/* Kills all monster */
native td_remove_monsters();

/* Returns chat prefix */
native td_get_prefix(szDest[], iLen)

/* Register a shop item*/
native td_shop_register_item(const szName[], const szDescription[], const iPrice, const iOnePerMap = 0, iPluginIndex)

/* Register a player class */
native td_register_class(const szClassName[], const szClassDescription[], iPluginIndex)

/* Sets a tower health */
native td_set_tower_health(iAdd = 1, iHealth, iExplode = 0)

/* Returns a tower health */
native td_get_tower_health()

/* Returns max tower health on map */
native td_get_max_tower_health()

/* Returns end status ( e_EndType ) */
native e_EndType: td_get_end_status()

// TD TURRETS
/* Returns a tutrret type */
native e_TurretsType:td_get_player_turret_type(index, turret)

/* Sets turret type */
native td_set_player_turret_type(index, turret, e_TurretsType:type)

/* Returns  'true' if slot is buyed by player, 'false' if is not */
native bool:td_get_player_turret_slot(index, slot)

native td_set_alarm_value(index, iValue);

native td_get_player_alarm_value(index)

/* Sets player slots */
native td_set_player_turret_slot(index, slot, value)

/* Returns 'true' if turret is upgrading, 'false' if is not */
native bool:td_turret_is_upgrading(index, turret)

/* Returns turret entity */
native td_get_turret_entity(index, turret)

/* Returns turret level */
native td_get_turret_level(index, turret)

/* Returns a damage level */
native td_get_turret_damage_level(index, turret)

/* Returns a range level */
native td_get_turret_range_level(index, turret)

/* Returns turret ammo num*/
native td_get_turret_ammo(index, turret)

/* Sets turret ammo*/
native td_set_turret_ammo(index, turret, value)

/* Returns 'true' if player is moving any turret */
native bool:td_player_is_moving_turret(index)

/* Returns entity moving turret, if is not moving any turret, returns 0 */
native td_get_moved_turret_entity(index)

/* Returns player turret (num)*/
native td_get_turrets_num(index)

/* Returns entity of turret target
	@Note: EV_INT_iuser4
	
	turret_entity - turret entity
	index - player index
	turret - turret index
	
	@note If 'turret_entity' is not specified, you must set 'index' and 'turret'
*/
native td_get_turret_target(turret_entity, index=0, turret=0)

/* Returns turret index
	@Note: EV_INT_iuser1
	@note j.w
*/
native td_get_turret_id(turret_entity, index=0, turret=0)

/* Zwraca Index ammobar'a danej wiezyczki (jesli sa wlaczone)
	@Note: EV_ENT_euser2
	@note j.w
*/
native td_get_turret_ammobar(turret_entity, index=0, turret=0)

/* Zwraca id gracza, ktory jest wlascicielem danej wiezyczki
	@Note: EV_ENT_owner
	@note j.w
*/
native td_get_turret_owner(turret_entity, index=0, turret=0)

/* Zwraca Index 'rangera' danej wiezyczki
	@Note: EV_ENT_euser3
	@note j.w
*/
native td_get_turret_ranger(turret_entity, index=0, turret=0)	

/* Zwraca status rangera danej wiezyczki
	@Note: EV_INT_iuser1
	@note j.w
*/
native td_get_turret_ranger_status(turret_entity, index=0, turret=0)

/* Zwraca '1' jesli jest to wiezyczka, '0' jesli nie */
native td_is_turret(iEnt)

/* Zwraca '1' jesli jest to ranger, '0' jesli nie */
native td_is_ranger(iEnt)

/* Zwraca '1' jesli jest to ammobar, '0' jesli nie */
native td_is_ammobar(iEnt)

/* Zwraca '1' jesli na serwerze znajduja sie wiezyczki, '0' jesli ich nie ma */
native td_is_turret_on_server()

/* Zwraca '1' jesli dana wiezyczka posiada 'ranger' */
native td_is_ranger_exists(turret_entity)

/* Zwraca maksymalna ilosc wiezyczek, jaka moze posiadac gracz */
native td_get_max_turrets_per_player()

/* Zwraca maksymalna ilosc wiezyczek, jaka moze byc na serwerze */
native td_get_max_server_turrets()

/* Zwraca czas, jaki jest odejmowany przy sterowania thinami.
	Na przyk³ad Install Time = 5.0 - ExtraTime
*/
native Float:td_get_player_extra_time(index)

/* Ustawia extra czas */
native td_set_player_extra_time(index, Float:fTime)

/* ============================ */
/*           Forwards           */
/* ============================ */

/* Wykonwywany przy rozpoczeciu wave'u */
forward td_startwave(iWave, e_RoundType:iMonsterType, iNum)

/* Wykonwywany przy zakonczeniu wave'u */
forward td_endwave(iWave)

/* Wykonywany przed zabiciem potwora */
forward td_monster_killed(iEnt, iPlayer, e_RoundType:iMonsterType)

/* Wykonywany podczas kupienia przedmiotu w sklepie */
forward td_shop_item_selected(iPlayer, iItemId);

/* Wykonywany podczas wybrania klasy */
forward td_class_selected(iPlayer, iClassIndex);

/* Wykonywany podczas wylaczania klasy */
forward td_class_disabled(iPlayer, iClassIndex);

/* Wykonywany podczas resetowania gry */
forward td_reset_game(iMode, Float:fTime);

/* Wykonywany przy resetowaniu wszystkich informacji u gracza */
forward td_reset_player_info(iPlayer)

/* Wykonywany przed zadaniem obra?en potworowi
	@UWAGA: Tylko przy DMG_BULLET
*/
forward td_take_damage(iPlayer, iEnt, iWeapon, Float:fOutDamage, szInDamage[2])

/* Wykonywany przy starcie odliczania do nastepnego wave
	@iToWhichWave 	Zwraca numer wav'e dla ktorego odlicza, przykladowo
			weszli pierwsi gracze, wiec iToWhichWave zwroci wratosc 1,
			poniewaz po odliczaniu bedzie wave nr. 1,
			natomiast po przejœciu 2 wavu, odlicza do 3
*/
forward td_countdown_started(iToWhichWave)
