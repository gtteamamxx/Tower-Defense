#if defined td_turrets_included
  #endinput
#endif
#define td_turrets_included

native td_register_turret(turretKey[33], turretName[33]);

forward td_on_turret_created(ent, id);

forward td_on_turret_low_ammo(ent, id);

forward td_on_turret_stop_fire(ent, id);

forward td_on_turret_no_ammo(ent, id);

forward td_on_turret_shot(ent, monster, id, Float:damage);

forward td_on_turret_shot_miss(ent, monster, id);

forward td_on_turret_start_fire(ent, monster, id);

