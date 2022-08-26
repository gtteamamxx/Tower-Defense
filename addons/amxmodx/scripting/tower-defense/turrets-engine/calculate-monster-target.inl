#if defined _towerdefense_calculate_monster_target
  #endinput
#endif
#define _towerdefense_calculate_monster_target

// Returns -1 if no monster found
public getTargetByShotMode(ent, Float:distance, TURRET_SHOT_MODE:shotMode = TURRET_SHOT_MODE.NEAREST)
{
	switch(shotMode)
	{
		case TURRET_SHOT_MODE.NEAREST: 
			return @getNearestMonster(ent, distance);

		case TURRET_SHOT_MODE.FARTHEST:
			return @getFarthestMonster(ent, distance);

		case TURRET_SHOT_MODE.STRONGEST:
			return @getStrongestMonster(ent, distance);
	}
}

@getStrongestMonster(ent, Float:distance)
{
	// TODO: Dodać consta maksymalnej liczby potworów
	new monsters[64];
	if(find_sphere_class(ent, MONSTER_ENTITY_NAME, distance , monsters, 63))
	{
		new Float:strongestMonsterHealth = -1.0;
        new strongestMonster = -1;

		for (new i = 0; i < 63; i++)
		{
			if (is_valid_ent(monsters[i])) {
				break;
			}

			// get distance between monster
            new Float:monsterHealth = entity_get_float(monsters[i], EV_FL_health);

			// save farthest distance 
			if (strongestMonsterHealth > monsterHealth)
			{
				strongestMonsterHealth = monsterHealth;
				strongestMonster = monsters[i];
			}
		}

		return strongestMonster;
	}

	return -1;
}

@getFarthestMonster(ent, Float:distance)
{
	// TODO: Dodać consta maksymalnej liczby potworów
	new monsters[64];
	if(find_sphere_class(ent, MONSTER_ENTITY_NAME, distance , monsters, 63))
	{
		new farthestDistance = -1;
        new farthestMonster = -1;

		for (new i = 0; i < 63; i++)
		{
			if (is_valid_ent(monsters[i])) {
				break;
			}

			// get distance between monster
            new distanceBetweenMonster = get_entity_distance(ent, monsters[i])

			// save farthest distance 
			if (distanceBetweenMonster > farthestDistance)
			{
				farthestDistance = distanceBetweenMonster;
				farthestMonster = monsters[i];
			}
		}

		return farthestMonster;
	}

	return -1;
}

@getNearestMonster(ent, Float:distance)
{
	new entlist[2];
	if(find_sphere_class(ent, MONSTER_ENTITY_NAME, distance , entlist, 1))
	{
		return entlist[0];
	}

	return -1;
}