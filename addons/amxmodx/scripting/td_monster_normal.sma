#include <amxmodx>
#include <td>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <fun>

#define PLUGIN "Tower Defense Monster: Normal"
#define VERSION "1.0"
#define AUTHOR "GT Team"

#define MONSTER_KEY "NORMAL"
#define STONE_CLASS_NAME "stone"

#define MODEL_1 "models/Tower Defense/normal1.mdl"
#define MODEL_2 "models/Tower Defense/normal2.mdl"
#define MODEL_3 "models/Tower Defense/normal3.mdl"
#define MODEL_4 "models/Tower Defense/normal4.mdl"
#define STONE_MODEL "models/Tower Defense/stone.mdl"

#define TRAIL_SPRITE "sprites/laserbeam.spr"

#define MONSTER_ATTACK_RANGE 800.0

#define STONE_BIT 1 << 1

#define PERCENTAGE_CHANCE_OF_MONSTER_PERFORM_ATTACK 8

#define IDLE_SEQUENCE_ID 1
#define RUN_SEQUENCE_ID 4
#define ATTACK_SEQUENCE_NAME "ref_shoot_knife"

#define THROW_SPEED 2000
#define STONE_DAMAGE 5

new g_trailSprite;
new g_screenShakeMsgId;

public plugin_precache()
{
    precache_model(MODEL_1);
    precache_model(MODEL_2);
    precache_model(MODEL_3);
    precache_model(MODEL_4);

    precache_model(STONE_MODEL);

    g_trailSprite = precache_model(TRAIL_SPRITE);
}

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    td_register_monster(MONSTER_KEY, MODEL_1, MODEL_2, MODEL_3, MODEL_4);

    @registerMonsterThink();

    RegisterHam(Ham_Touch, "info_target", "@stoneTouchedPlayer")

    g_screenShakeMsgId = get_user_msgid("ScreenShake");
}

@registerMonsterThink()
{
    new monsterEntityName[64];
    td_get_monster_entity_name(MONSTER_KEY, monsterEntityName, charsmax(monsterEntityName));

    register_think(monsterEntityName, "@monsterThink");
}

@stoneTouchedPlayer(stoneEntity, touchedEntity)
{
    if(!@isEntityStone(stoneEntity))
    {
        return;
    }

    if(is_user_alive(touchedEntity))
    {
        new playerId = touchedEntity;

        @hurtPlayer(playerId);
        @shakeUserScreen(playerId);
        @setStoneUntouchable(stoneEntity);
    }

    new param[1]; param[0] = stoneEntity;
    set_task(1.0, "@removeStoneEntity", .parameter = param, .len = 1);
}

@removeStoneEntity(param[1])
{
    new stoneEntity = param[0];
    if(is_valid_ent(stoneEntity))
    {
        remove_entity(stoneEntity);
    }
}

@monsterThink(monsterEntity)
{
    new bool:shouldMonsterAttackPlayer = random_num(1, 100) >= (100 - PERCENTAGE_CHANCE_OF_MONSTER_PERFORM_ATTACK);

    if(shouldMonsterAttackPlayer)
    {
        startAttackingPlayer(monsterEntity);
        return;
    }

    entity_set_float(monsterEntity, EV_FL_nextthink, get_gametime() + 1.0);
}

startAttackingPlayer(monsterEntity)
{
    new playersInRange[11];
    new numberOfFoundPlayers = find_sphere_class(monsterEntity, "player", MONSTER_ATTACK_RANGE, playersInRange, charsmax(playersInRange));

    if(numberOfFoundPlayers > 0)
    {
        new randomPlayer = playersInRange[random(numberOfFoundPlayers)];

        @attackRandomPlayer(monsterEntity, .player = randomPlayer);

        return;
    }

    entity_set_float(monsterEntity, EV_FL_nextthink, get_gametime() + 1.0);
}

@attackRandomPlayer(monsterEntity, player)
{
    if(!is_user_alive(player) || !is_visible(monsterEntity, player))
    {
        entity_set_float(monsterEntity, EV_FL_nextthink, get_gametime() + 1.0);
        return;
    }

    entity_set_aim(monsterEntity, player);
    @stopMonster(monsterEntity);
    
    entity_set_int(monsterEntity, EV_INT_sequence, IDLE_SEQUENCE_ID);
    entity_set_float(monsterEntity, EV_FL_animtime, get_gametime());
    
    new param[2];
    param[0] = monsterEntity;
    param[1] = player;
    set_task(0.5, "@prepareMonsterToThrowStoneToPlayer", .parameter = param, .len = 2);
    return;
}

@prepareMonsterToThrowStoneToPlayer(param[2])
{
    new monsterEntity = param[0];
    if(td_is_monster_killed(monsterEntity))
    {
        return;
    }

    new Float:sequenceFramerate;
    new attackSequenceId = lookup_sequence(monsterEntity, ATTACK_SEQUENCE_NAME, sequenceFramerate);

    entity_set_int(monsterEntity, EV_INT_sequence, attackSequenceId);
    entity_set_float(monsterEntity, EV_FL_animtime, get_gametime());

    new Float:attackAnimationTime = sequenceFramerate / 100;

    set_task(attackAnimationTime / 3, "@throwStoneToPlayer", .parameter = param, .len = 2);
    set_task(attackAnimationTime, "@setMonsterToContinueHisTrack", .parameter = param, .len = 1);
}

@setMonsterToContinueHisTrack(param[1])
{
    new monsterEntity = param[0];
    if(td_is_monster_killed(monsterEntity))
    {
        return;
    }
    
    td_aim_monster_to_track(monsterEntity);

    entity_set_int(monsterEntity, EV_INT_sequence, RUN_SEQUENCE_ID);
    entity_set_float(monsterEntity, EV_FL_animtime, get_gametime());
    entity_set_float(monsterEntity, EV_FL_nextthink, get_gametime() + 1.0);
}

@throwStoneToPlayer(param[2])
{
    new monsterEntity = param[0];
    new playerId = param[1];

    if(td_is_monster_killed(monsterEntity) || !is_user_alive(playerId))
    {
        return;
    }

    entity_set_aim(monsterEntity, playerId);

    new stoneEntity = @createStoneEntity();
    @setStoneEntityPositionToMonsterHand(stoneEntity, monsterEntity);
    @throwStoneEntityByMonsterAimToPlayer(stoneEntity, playerId);
    @addRedTrailToStone(stoneEntity);
}

@createStoneEntity()
{
    new stoneEntity = cs_create_entity("info_target");

    cs_set_ent_class(stoneEntity, STONE_CLASS_NAME);
    entity_set_model(stoneEntity, STONE_MODEL);

    entity_set_int(stoneEntity, EV_INT_solid, SOLID_TRIGGER);
    entity_set_int(stoneEntity, EV_INT_movetype, MOVETYPE_TOSS);

    entity_set_int(stoneEntity, EV_INT_iuser2, STONE_BIT)

    return stoneEntity;
}

@setStoneEntityPositionToMonsterHand(stoneEntity, monsterEntity)
{
    new Float:monsterOrigin[3];
    entity_get_vector(monsterEntity, EV_VEC_origin, monsterOrigin);

    monsterOrigin[2] += 25;

    entity_set_origin(stoneEntity, monsterOrigin);
}

@throwStoneEntityByMonsterAimToPlayer(stoneEntity, playerId)
{
    entity_set_aim(stoneEntity, playerId);

    new Float:stoneThrowVelocity[3];
    velocity_by_aim(stoneEntity, THROW_SPEED, stoneThrowVelocity);
    entity_set_vector(stoneEntity, EV_VEC_velocity, stoneThrowVelocity);
}

@addRedTrailToStone(stoneEntity)
{
    static trailLength, trailWidth, rgb[3];
    if(!trailLength || !trailWidth)
    {
        trailLength = 5;
        trailWidth = 3;
        rgb[0] = 255;
    }

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY); 
    write_byte(TE_BEAMFOLLOW); 
    write_short(stoneEntity);
    write_short(g_trailSprite); 
    write_byte(trailLength);
    write_byte(trailWidth); 
    write_byte(rgb[0]); 
    write_byte(rgb[1]); 
    write_byte(rgb[2]); 
    write_byte( 255 ); 
    message_end();
}

@stopMonster(monsterEntity)
{
    td_stop_monster(monsterEntity);
}

@isEntityStone(ent)
{
    return is_valid_ent(ent) && entity_get_int(ent, EV_INT_iuser2) == STONE_BIT;
}

@hurtPlayer(playerId)
{
    new health = get_user_health(playerId) - STONE_DAMAGE;

    set_user_health(playerId, health);
}

@setStoneUntouchable(stoneEntity)
{
    entity_set_int(stoneEntity, EV_INT_solid, SOLID_NOT);
}

@shakeUserScreen(playerId)
{
    message_begin(MSG_ONE, g_screenShakeMsgId, {0,0,0}, playerId);
    write_short(7<<14);
    write_short(1<<13);
    write_short(1<<14);
    message_end();
}