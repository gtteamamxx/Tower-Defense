#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <xs>

#include <hamsandwich>

#define PLUGIN "spriteFixer"
#define VERSION "1.0"
#define AUTHOR "AMXX.PL Team"

#define SPRITES_PER_PLAYER 16

#define AUTH_STEAM 2

new const spriteClass[]	=	"spriteFix";

new pcv_dp_r_id_provider;

new bool:gbHaveSprite[MAX_PLAYERS];
new giEntsIds[MAX_PLAYERS][SPRITES_PER_PLAYER];
new Float:gfOffset[MAX_PLAYERS][SPRITES_PER_PLAYER][2];
new Float:gfOffsetLen[MAX_PLAYERS][SPRITES_PER_PLAYER];
new Float:gfPosition[MAX_PLAYERS][3];
new Float: fBob[ MAX_PLAYERS ] ,
Float: fBobUp[ MAX_PLAYERS ]


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_forward(FM_AddToFullPack, "fwAddToFullPack", 0 );
	
	register_think( spriteClass, "fwSpriteThink");
	
	pcv_dp_r_id_provider = get_cvar_pointer("dp_r_id_provider");
	
	if( !pcv_dp_r_id_provider ){
		state onlysteam;
	}
	else {
		state dproto;
	}
}

public client_disconnect(id){
	for(new i=0;i<SPRITES_PER_PLAYER;i++){
		if(pev_valid(giEntsIds[id][i])){
			remove_entity(giEntsIds[id][i]);
		}
		giEntsIds[id][i] = 0;
	}
}

public client_authorized(id){
	
	checkUserCvars( id );
	
	gbHaveSprite[id] = false;
}

public checkUserCvars( id ){
	
	if( !is_user_steam( id ) ){
		
		fBob[ id ]		=	0.01;
		fBobUp[ id ]	=	0.5;
		
		return PLUGIN_CONTINUE;
	}
	
	query_client_cvar( id , "cl_bob" , "clBobResult" )
	query_client_cvar( id , "cl_bobup" , "clBobUpResult" )
	
	return PLUGIN_CONTINUE;
}

public clBobResult(id, const cvar[], const value[]){
	fBob[ id ]	=	str_to_float( value );
}

public clBobUpResult(id, const cvar[], const value[]){
	fBobUp[ id ]	=	str_to_float( value );
}

public resetUserCvars( id ){
	
	client_cmd( id , "cl_bob %f" , fBob[ id ] );
	client_cmd( id , "cl_bobup %f" , fBobUp[ id ] );
	
}

public setUserCvars( id ){
	
	client_cmd( id , "cl_bob 0" );
	client_cmd( id , "cl_bobup 0" );
	
}

public plugin_natives(){
	register_native("addPlayerSprite","addSprite");
	
	register_native( "setSpriteFX" , "setSpriteFX" , 1 );
	register_native( "setSpriteRender" , "setSpriteRender" , 1 );
	register_native( "setSpriteColor" , "setSpriteColor" , 1 );
	register_native( "setSpriteSequence" , "setSpriteSequence" , 1 );
	register_native( "setSpriteScale" , "setSpriteScale" , 1 );
	register_native( "setSpriteFrameRate" , "setSpriteFrameRate" , 1 );
	register_native( "setSpriteAmount" , "setSpriteAmount" , 1 );
	register_native( "setSpriteFrame" , "setSpriteFrame" , 1 );
	
	register_native( "setSpriteAngle" , "setSpriteAngle" , 1 );
}

public setSpriteFX( id , indexSprite , fx ){
	
	if( checkSprite( id , indexSprite ) ){
		
		return PLUGIN_CONTINUE;
		
	}
	
	set_pev( giEntsIds[ id ][ indexSprite - 1 ] , pev_renderfx , fx );
	
	return PLUGIN_CONTINUE;
}

public setSpriteRender( id , indexSprite , render ){
	
	if( checkSprite( id , indexSprite ) ){
		
		return PLUGIN_CONTINUE;
		
	}
	
	set_pev( giEntsIds[ id ][ indexSprite - 1 ] , pev_rendermode , render );
	
	return PLUGIN_CONTINUE;
	
}

public setSpriteColor( id , indexSprite , Float: fColor[ 3 ] ){
	
	if( checkSprite( id , indexSprite ) ){
		
		return PLUGIN_CONTINUE;
		
	}
	
	set_pev( giEntsIds[ id ][ indexSprite - 1 ] , pev_rendercolor , fColor );
	
	return PLUGIN_CONTINUE;
}

public setSpriteSequence( id , indexSprite , iSequence ){
	
	if( checkSprite( id , indexSprite ) ){
		
		return PLUGIN_CONTINUE;
		
	}
	
	set_pev( giEntsIds[ id ][ indexSprite - 1 ] , pev_sequence , iSequence );
	
	return PLUGIN_CONTINUE;
}

public setSpriteScale( id , indexSprite , Float: fScale ){
	
	if( checkSprite( id , indexSprite ) ){
		
		return PLUGIN_CONTINUE;
		
	}
	
	set_pev( giEntsIds[ id ][ indexSprite - 1 ] , pev_scale , fScale );
	
	return PLUGIN_CONTINUE;
}

public setSpriteFrame( id , indexSprite , frame ){
	
	if( checkSprite( id , indexSprite ) ){
		
		return PLUGIN_CONTINUE;
		
	}
	
	set_pev( giEntsIds[ id ][ indexSprite - 1 ] , pev_frame , frame );
	
	return PLUGIN_CONTINUE;
}

public setSpriteFrameRate( id , indexSprite , Float: fFrameRate ){
	
	if( checkSprite( id , indexSprite ) ){
		
		return PLUGIN_CONTINUE;
		
	}
	
	set_pev( giEntsIds[ id ][ indexSprite - 1 ] , pev_framerate , fFrameRate );
	
	return PLUGIN_CONTINUE;
}

public setSpriteAmount( id , indexSprite , Float: fAmount ){
	
	if( checkSprite( id , indexSprite ) ){
		
		return PLUGIN_CONTINUE;
		
	}
	
	set_pev( giEntsIds[ id ][ indexSprite - 1 ] , pev_renderamt , fAmount );
	
	return PLUGIN_CONTINUE;
}

public setSpriteAngle( id , indexSprite , Float: fAngle ){
	
	if( checkSprite( id , indexSprite ) ){
		
		return PLUGIN_CONTINUE;
		
	}
	
	gfOffset[id][ indexSprite ][ 0 ]	=	fAngle;
	
	return PLUGIN_CONTINUE;
}


bool: checkSprite( id , indexSprite ){
	return bool: ( indexSprite <= 0 || !pev_valid( giEntsIds[ id ][ indexSprite - 1 ] ) );
}

public addSprite(plugin,params){
	if(params < 7){
		log_amx("addSprite zbyt malo parametrow!");
		return 0;
	}
	new ent = create_entity("env_sprite");
	
	new id = get_param(1);
	
	set_pev(ent, pev_classname, spriteClass );
	set_pev(ent, pev_solid, SOLID_NOT);
	set_pev( ent, pev_movetype, MOVETYPE_FLY );
	
	new szModel[256]
	get_string(4, szModel, charsmax(szModel));
	
	entity_set_model(ent, szModel);
	entity_set_size(ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
	set_rendering(ent, kRenderFxNone, 255, 255, 255, get_param( 9 ) ? kRenderTransAdd : kRenderNormal , 255 );
	
	set_pev(ent, pev_scale, get_param_f(2));
	set_pev(ent, pev_owner, id);
	set_pev(ent, pev_framerate, get_param_f(3));
	
	new Float:fLTime = get_param_f(7);
	
	new iIndex	=	addFixedSprite(id, ent, get_param_f(5), get_param_f(6), get_param_f(8), fLTime);
	
	if( !iIndex ){
		remove_entity(ent);
		return 0;
	}
	
	if( !gbHaveSprite[ id ] ){
		setUserCvars( id );
	}
	
	gbHaveSprite[id] = true;
	
	if(fLTime >= 0.0){
		set_pev(ent, pev_nextthink, get_gametime()+fLTime);
	}
	
	return ent;
}

public ent_get(id){
	for(new i=0;i<SPRITES_PER_PLAYER;i++){
		if(giEntsIds[id][i] == 0){
			return i;
		}
	}
	return -1;
}

/**
* Dodaje do kolejki nowy byt
*
*	@param 	id 		Gracz
*	@param 	ent		Byt
*	@param 	fOffset		Przesuniecie katowe (tarcza zegara)
*	@param  fOffsetLen	Odleglosc od srodka ekranu
*	@param  fOffsetDistance	Odleglosc od gracza
*/
addFixedSprite(id, ent, const Float:fOffset, Float:fOffsetLen, Float:fOffsetDistance, Float:fLTime = -1.0){	
	new index = ent_get(id);
	if(index == -1){
		return 0;
	}
	
	gfOffset[id][index][0] = fOffset;
	gfOffset[id][index][1] = fOffsetLen;
	
	gfOffsetLen[id][index] = fOffsetDistance;
	giEntsIds[id][index] = ent;
	
	if(fLTime >= 0.0)
		set_pev(ent, pev_ltime, get_gametime()+fLTime);
	else
	set_pev(ent, pev_ltime, 0.0);
	set_pev(ent, pev_iuser1, index)
	getPosition(id);
	
	return index + 1;
}
removeFixedSprite(id, ent){
	new index = -1;
	for(new i=0;i<SPRITES_PER_PLAYER;i++){
		if(giEntsIds[id][i] == ent){
			index = i;
			break;
		}
	}
	
	if(index < 0){
		gbHaveSprite[id] = false;
		
		resetUserCvars( id );
		
		return;
	}
	
	giEntsIds[id][index] = 0;
	gfOffsetLen[id][index] = 0.0;
	
	xs_vec_copy(Float:{0.0,0.0,0.0}, gfOffset[id][index]);
}
public fwAddToFullPack(es_handle, e, ENT, HOST, hostflags, player, set){
	if(player || !pev_valid( ENT ) ) return FMRES_IGNORED;
	
	new szClassName[ 64 ];
	
	pev( ENT , pev_classname , szClassName , charsmax( szClassName ) );
	
	if( !equal( szClassName , spriteClass ) ){
		return FMRES_IGNORED;
	}
	
	if(pev(ENT, pev_owner) == HOST) {
		getPosition( HOST );
				
		new Float:fAngles[3];
		new Float:fVector[3];
		new i = pev(ENT, pev_iuser1)
		pev(HOST, pev_v_angle, fAngles);
			
		angle_vector(fAngles, ANGLEVECTOR_FORWARD, fVector);
		xs_vec_mul_scalar(fVector, gfOffsetLen[HOST][i], fVector);
				
		fAngles[2] = gfOffset[HOST][i][0];
		angle_vector(fAngles, ANGLEVECTOR_RIGHT, fAngles);
				
		xs_vec_mul_scalar(fAngles, gfOffset[HOST][i][1], fAngles);
		
		xs_vec_add(gfPosition[HOST], fVector, fVector);
		xs_vec_add(fVector, fAngles, fVector);
				
		set_pev(giEntsIds[HOST][i], pev_origin, fVector);
				
		set_es( es_handle , ES_Origin , fVector );
		return FMRES_IGNORED
	} 
	

	set_es( es_handle , ES_Scale , 0.001 );
	set_es( es_handle , ES_Origin , { 9999.0 , 9999.0 , 9999.0 } );    
	
	return FMRES_HANDLED;
}
public fwSpriteThink(ent){
	if(!pev_valid(ent)) 
		return PLUGIN_CONTINUE;
	
	new Float:fNow = get_gametime();
	new Float:fLTime;
	if(pev(ent, pev_ltime, fLTime) && fLTime > 0.0 && fLTime <= fNow){
		removeFixedSprite(pev(ent, pev_owner), ent);
		remove_entity(ent);
	}
	else
	set_pev(ent, pev_nextthink, fNow+0.1);
	return PLUGIN_CONTINUE;
}
getPosition(id){
	pev(id, pev_origin, gfPosition[id]);
	
	static Float:fOffset[3];
	pev(id, pev_view_ofs, fOffset);
	
	xs_vec_add(gfPosition[id], fOffset, gfPosition[id]);
}

stock bool: is_user_steam(id) <dproto>
{
	if( is_user_bot( id ) ){
		return false;
	}
	
	server_cmd("dp_clientinfo %d", id);
	server_exec();
	
	static uClient;
	uClient = get_pcvar_num(pcv_dp_r_id_provider);
	
	if ( uClient == AUTH_STEAM )
		return true;
	
	return false;
}

stock bool: is_user_steam(id) <onlysteam>
{
	return !is_user_bot( id );
	
	#pragma unused id
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
