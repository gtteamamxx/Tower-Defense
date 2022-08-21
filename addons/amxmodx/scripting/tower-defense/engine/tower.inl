#if defined td_engine_tower_includes
  #endinput
#endif
#define td_engine_tower_includes

public manageTowerOnMonsterTouchEndWall(monsterEntity) 
{
    new bool:shouldTowerBeVisible = getMapConfigurationData(SHOW_TOWER);
    if (shouldTowerBeVisible) 
    {
        static towerEntity; towerEntity = find_ent_by_class(-1, TOWER_ENTITY_NAME);

        @createExplodeEffectOnTowerPosition(towerEntity);

        new damageTakenToTower = getMonsterDamageToTakeForTower(monsterEntity);
        @moveTowerDownByTakenDamage(towerEntity,damageTakenToTower);
    }
}

@moveTowerDownByTakenDamage(towerEntity, damageTakenToTower)
{
    static Float:fTowerOrigin[3];

    entity_get_vector(towerEntity, EV_VEC_origin, fTowerOrigin);

    static mapTowerHealth; 
    if (!mapTowerHealth) mapTowerHealth = getMapConfigurationData(TOWER_HEALTH);

    fTowerOrigin[2] -= ( 225.0 / ( float(mapTowerHealth)  / float(damageTakenToTower) ) );

    entity_set_vector(towerEntity, EV_VEC_origin,  fTowerOrigin)
}

@createExplodeEffectOnTowerPosition(towerEntity) 
{
    static fTowerOrigin[3];

    new Float:fTemp[3];
    entity_get_vector(towerEntity, EV_VEC_origin, fTemp);
    FVecIVec(fTemp, fTowerOrigin);

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_EXPLOSION);
    write_coord(fTowerOrigin[0]);
    write_coord(fTowerOrigin[1]);
    write_coord(fTowerOrigin[2]);
    write_short(getModelPrecacheId(EXPLODE_SPRITE_MODEL));
    write_byte(50);
    write_byte(10);
    write_byte(0);
    message_end();
}