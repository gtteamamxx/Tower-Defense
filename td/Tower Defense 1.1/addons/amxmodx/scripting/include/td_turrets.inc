#if defined _towerdefense_turrets_included
  #endinput
#endif
#define _towerdefense_turrets_included

/* Returns a max turrets can be placed on map*/
native td_get_max_map_turrets()

/* Returns 'true' if turret's are enabled on actually played map */
native td_are_turrets_enabled();

/* Returns a turret type 
	- TURRET_NONE,
	- TURRET_BULLET,
	- TURRET_LASER,
	- TURRET_LIGHTING
*/
native td_get_player_turret_type(index, turret)

/* Sets turret type 
   (Check type above)
   
   You must be careful before using this native.
   If you for example changed from BULLET to LASER, when
   turret had eg. damage level 5 but LASER turret can have only damaage level 4,
   you can experience bugs/errors.
*/
native td_set_player_turret_type(index, turret, type)

/* Returns 1 if slot is bought by player otherwise 0 */
native td_get_player_turret_slot(index, slot)

/* Sets bought slot by player */
native td_set_player_turret_slot(index, slot, bool:value);

/* Sets for player alarm ammo value */
native td_set_player_alarm_value(index, iValue);

/* Returns player alarm ammo value */
native td_get_player_alarm_value(index)

/* Returns 1 if turret is upgrading otherwise 0 */
native td_is_turret_upgrading(index, turret)

/* Sets turret is upgrading */
native td_set_is_turret_upgrading(index, turret, bool:value)

/* Returns a player turret entity */
native td_get_player_turret_entity(index, turret)

/* Sets a player turret entity */
native td_set_player_turret_entity(id, turret, iEntity)

/* Returns turret level */
native td_get_player_turret_level(index, turret)

/* Returns turret a damage level */
native td_get_player_turret_dmg_level(index, turret)

/* Returns turret a range level */
native td_get_player_turret_rng_level(index, turret)

/* Returns turret ammo num*/
native td_get_player_turret_ammo(index, turret)

/* Sets turret ammo*/
native td_set_player_turret_ammo(index, turret, value)

/* Returns entity moving turret, if is not moving any turret, returns 0 */
native td_get_moved_turret_entity(index)

/* Returns a player turrets num*/
native td_get_player_turrets_num(index)

/* Returns entity of turret target
	@Note: EV_INT_iuser4
	
	turret_entity - turret entity
	index - player index
	turret - turret index
	
	@note If 'turret_entity' is not specified, you must set 'index' and 'turret'
*/

native td_get_turret_target(turret_entity, player_index=0, turret=0)

/* Returns turret index
	@Note: EV_INT_iuser1
	@Note: check above about index & turret
*/
native td_get_turret_id(turret_entity, index=0, turret=0)

/* Returns owner of turret
	@Note: EV_ENT_owner
	@Note check above about index & turret
*/
native td_get_turret_owner(turret_entity, index=0, turret=0)

/* Zwraca Index 'rangera' danej wiezyczki
	@Note: EV_ENT_euser3
	@Note check above about index & turret
*/
native td_get_turret_ranger(turret_entity, index=0, turret=0)	

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

/* Returns player totem */
native td_turrets_get_player_totem(index)

/* Sets player totem */
native td_turrets_set_player_totem(index, value)