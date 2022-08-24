#if defined td_included
  #endinput
#endif
#define td_included

native bool:td_register_monster(monsterTypeKey[33], any:...);

native td_get_monster_entity_name(monsterTypeKey[33], output[], len);

native bool:td_is_monster(entity);

native bool:td_is_monster_killed(entity);

native entity_set_aim(ent1, ent2);

native td_aim_monster_to_track(monsterEntity, trackEntity = -1);

native td_get_monster_actual_track_id(monsterEntity);

native td_stop_monster(monsterEntity);

native td_start_game();

forward td_on_configuration_load(configurationFilePath[128], bool:isGamePossible);

forward td_on_game_end(bool:win);

forward td_on_wave_end(wave);

forward td_on_monster_killed(monsterEntity, player);

forward td_on_damage_taken_to_monster(monsterEntity, player, Float:fDamage)