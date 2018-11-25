#if defined td_included
  #endinput
#endif
#define td_included

native bool:td_register_monster(monsterTypeKey[33], any:...);

native td_get_monster_entity_name(monsterTypeKey[33], output[], len);

native bool:td_is_monster(entity);

native bool:td_is_killed_monster(entity);

native entity_set_aim(ent1, ent2);

native td_aim_monster_to_track(monsterEntity, trackEntity = -1);

native td_get_monster_actual_track_id(monsterEntity);