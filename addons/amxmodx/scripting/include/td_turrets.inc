#if defined td_turrets_included
  #endinput
#endif
#define td_turrets_included

native td_register_turret(turretKey[33], turretName[33]);

forward td_on_turret_created(ent, id);
