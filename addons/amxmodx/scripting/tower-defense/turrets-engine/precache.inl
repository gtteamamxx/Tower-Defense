#if defined _towerdefense_turrets_precache_included
  #endinput
#endif
#define _towerdefense_turrets_precache_included

public plugin_precache()
{
    // before plugin loads initialize all global variables to store
    // information about turrets
    initGlobalVariables();

    // temp
    precache_model("models/TDNew/sentrygun_1.mdl");
    precache_model("models/TDNew/sentrygun_2.mdl");
    precache_model("models/TDNew/sentrygun_3.mdl");
    precache_model("models/TDNew/sentrygun_4.mdl");
    precache_model("models/TDNew/sentrygun_5.mdl");
    precache_model("sprites/TDNew/ranger.spr");
}