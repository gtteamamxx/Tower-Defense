#if defined td_add_to_full_pack_includes
  #endinput
#endif
#define td_add_to_full_pack_includes

public registerAddToFullPack()
{
    register_forward(FM_AddToFullPack, "@addToFullPack", 1)
}

@addToFullPack(es_handle, e, ENT, HOST, hostflags, player, set) 
{
    if(player || !is_user_connected(HOST) || !isMonster(ENT))
    {
        return FMRES_IGNORED;
    }

    static healthBarEntity;
    if(!CED_GetCell(ENT, MONSTER_DATA_HEALTHBAR_ENTITY, healthBarEntity) || !isHealthBar(healthBarEntity))
    {
        return FMRES_IGNORED;
    }

    static Float:monsterOrigin[3];

    entity_get_vector(ENT, EV_VEC_origin, monsterOrigin);
    monsterOrigin[2] += 45.0;
    entity_set_vector(healthBarEntity, EV_VEC_origin, monsterOrigin);

    return FMRES_IGNORED;
}