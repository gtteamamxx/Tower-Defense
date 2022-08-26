#if defined _towerdefense_calculate_monster_target
  #endinput
#endif
#define _towerdefense_calculate_monster_target

public TURRET_SHOT_RESULT:getTargetByShotMode(ent, Float:distance, TURRET_SHOT_MODE:shotMode)
{
    switch(shotMode)
    {
        case NEAREST: return @getNearestMonster(ent, distance);
        case FARTHEST: return @getFarthestMonster(ent, distance);
        case STRONGEST: return @getStrongestMonster(ent, distance);
        case WEAKEST: return @getWeaknestMonster(ent, distance);
        case FOLLOW: return @getPreviousTurretMonster(ent, distance);
        default: return No_Monster_Found;
    }

    return No_Monster_Found;
}

TURRET_SHOT_RESULT:@getPreviousTurretMonster(ent, Float:distance)
{
    // get current monster target
    new monster = getTurretTargetMonster(ent);

    // if monster is valid
    if (is_valid_ent(monster))
    {	
        new Float:monsterHealth = entity_get_float(monster, EV_FL_health);

        // if monster is not alive return nearest
        if (monsterHealth <= 0.0)
        {
            return @getNearestMonster(ent, distance);
        }
        // if monster is still alive
        else
        {
            // get distance between monster
            new Float:distanceBetweenMonster = entity_range(ent, monster);
            
            // if monster is in range and is visible return him
            if (distanceBetweenMonster <= distance && fm_is_ent_visible(ent, monster))
            {
                return TURRET_SHOT_RESULT:monster;
            }
        }
    }

    // if monster is not valid return nearest
    return @getNearestMonster(ent, distance);
}

TURRET_SHOT_RESULT:@getStrongestMonster(ent, Float:distance)
{
    // get all monsters nearby
    new monsters[12];
    new monstersNum = td_get_monsters_in_sphere(ent, distance , monsters, 11);

    // if no monsters found then exit
    if(monstersNum == 0)
    {
        return No_Monster_Found;
    }

    new Float:strongestMonsterHealth = 0.0;
    new strongestMonster = -1;

    // loop through all monsters
    for (new i = 0; i < monstersNum; ++i)
    {
        new monster = monsters[i];

        // get distance between monster
        new Float:monsterHealth = entity_get_float(monster, EV_FL_health);

        // save farthest distance if is visible
        if (monsterHealth > strongestMonsterHealth && fm_is_ent_visible(ent, monster))
        {
            strongestMonsterHealth = monsterHealth;
            strongestMonster = monster;
        }
    }

    return TURRET_SHOT_RESULT:strongestMonster;
}

TURRET_SHOT_RESULT:@getWeaknestMonster(ent, Float:distance)
{
    // get all monsters nearby
    new monsters[12];
    new monstersNum = td_get_monsters_in_sphere(ent, distance , monsters, 11);

    // if no monsters found then exit
    if(monstersNum == 0)
    {
        return No_Monster_Found;
    }

    new Float:weaknestMonsterHealth = 999999.9;
    new weaknesMonster = -1;

    // loop through all monsters
    for (new i = 0; i < monstersNum; ++i)
    {
        new monster = monsters[i];

        // get health
        new Float:monsterHealth = entity_get_float(monster, EV_FL_health);

        // save weaknest if is visible
        if (monsterHealth < weaknestMonsterHealth && fm_is_ent_visible(ent, monster))
        {
            weaknestMonsterHealth = monsterHealth;
            weaknesMonster = monster;
        }
    }

    return TURRET_SHOT_RESULT:weaknesMonster;
}


TURRET_SHOT_RESULT:@getFarthestMonster(ent, Float:distance)
{
    // get all monsters nearby
    new monsters[12];
    new monstersNum = td_get_monsters_in_sphere(ent, distance , monsters, 11);

    // if no monsters found then exit
    if(monstersNum == 0)
    {
        return No_Monster_Found;
    }

    new Float:farthestDistance = 0.0;
    new farthestMonster = -1;

    // loop through all monsters
    for (new i = 0; i < monstersNum; ++i)
    {
        new monster = monsters[i];

        // get distance between monster
        new Float:distanceBetweenMonster = entity_range(ent, monster)

        // save farthest distance & monster
        if (distanceBetweenMonster > farthestDistance && fm_is_ent_visible(ent, monster))
        {
            farthestDistance = distanceBetweenMonster;
            farthestMonster = monster;
        }
    }

    return TURRET_SHOT_RESULT:farthestMonster;
}

TURRET_SHOT_RESULT:@getNearestMonster(ent, Float:distance)
{
    // get nearest monsters
    new monsters[12];
    new monstersNum = td_get_monsters_in_sphere(ent, distance, monsters, 11);

    // loop throgh all monsters
    for(new i = 0; i < monstersNum; ++i)
    {
        new monster = monsters[i];

        // if monster is visible
        if (fm_is_ent_visible(ent, monster))
        {
            return TURRET_SHOT_RESULT:monster;
        }
    }

    return No_Monster_Found;
}