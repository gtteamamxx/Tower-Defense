#if defined td_included
  #endinput
#endif
#define td_included

native bool:td_register_monster(monsterTypeKey[33], any:...);

native td_get_monster_entity_name(monsterTypeKey[33], output[], len)