
/*	
	nVault Utility
	     v0.4
	   by bugsy
*/

#if defined _nvault_util_included
	#endinput
#endif
#define _nvault_util_included

#if !defined _nvault_included
	#include <nvault>
#endif

#if !defined _amxmisc_included
	#include <amxmisc>
#endif

#define _NVAULTUTIL_MAX_KEY_LEN	255
#define _NVAULTUTIL_MAX_VAL_LEN	512
#define _NVAULTUTIL_BUFFER_SIZE	128

#define _NVAULTUTIL_OFFSET_ENTRYCOUNT	6
#define _NVAULTUTIL_OFFSET_DATASTART	10

#define _nvault_util_minsize(%1,%2)	((%1<%2)?%1:%2)

//********************************************************************************************
//   Increase this value if your plugin throws the below error:
//   "Array size too large, you must increase NVAULTUTIL_MAXARRAYSIZE in nvault_util.inc"   

const _NVAULTUTIL_MAXARRAYSIZE = 500;
//********************************************************************************************

const _NVAULTUTIL_BUFFERSIZE = ( ( _NVAULTUTIL_MAXARRAYSIZE * 5 ) + 1);
const _NVAULTUTIL_BYTEMAP = 0b11110000;
const _NVAULTUTIL_NULLBYTE = 0b10101010;

stock nvault_util_open( const szVault[] )
{
	new szFile[ 64 ];
	
	formatex( szFile[ get_datadir( szFile , charsmax( szFile ) ) ] , charsmax( szFile ) , "/vault/%s.vault" , szVault );
	
	return fopen( szFile , "rb" );
}

stock nvault_util_close( iVaultHandle )
{
	fclose( iVaultHandle );
}

stock nvault_util_count( iVaultHandle )
{
	new DataBuffer[ 1 ];

	fseek( iVaultHandle , _NVAULTUTIL_OFFSET_ENTRYCOUNT , SEEK_SET );
	fread_raw( iVaultHandle , DataBuffer , 1 , BLOCK_INT );
	
	return DataBuffer[ 0 ];
}

stock nvault_util_read( iVaultHandle , iOffset , szKey[] , iKeySize , szVal[] , iValSize , &iTimeStamp=0 )
{
	static iKeyLen , iValLen , DataBuffer[ _NVAULTUTIL_BUFFER_SIZE ];
	
	fseek( iVaultHandle , iOffset ? iOffset : _NVAULTUTIL_OFFSET_DATASTART , SEEK_SET );
	
	fread_raw( iVaultHandle , DataBuffer , 1 , BLOCK_INT );
	iTimeStamp = DataBuffer[ 0 ];
	
	fread_raw( iVaultHandle , DataBuffer , 1 , BLOCK_BYTE );
	iKeyLen = DataBuffer[ 0 ] & 0xFF;
	
	fread_raw( iVaultHandle , DataBuffer , 1 , BLOCK_SHORT );
	iValLen = DataBuffer[ 0 ] & 0xFFFF;
	
	fread_raw( iVaultHandle , DataBuffer , iKeyLen , BLOCK_CHAR );
	_nvault_util_read_string( szKey , _nvault_util_minsize( iKeySize , iKeyLen ) , DataBuffer , sizeof( DataBuffer ) );
	
	fread_raw( iVaultHandle , DataBuffer , iValLen , BLOCK_CHAR );
	_nvault_util_read_string( szVal , _nvault_util_minsize( iValSize , iValLen ) , DataBuffer , sizeof( DataBuffer ) ); 
					  
	return ftell( iVaultHandle );
}

stock nvault_util_readall( iVaultHandle , const szForwardFunc[] , Data[] = {0} , iSize=0 )
{
	new iFwdHandle = CreateMultiForward( szForwardFunc , ET_IGNORE , FP_CELL , FP_CELL , FP_STRING , FP_STRING , FP_CELL , FP_STRING , FP_CELL );
	
	if ( iFwdHandle <= 0 )
		set_fail_state( "nvault_util_readall() failed to create forward" );
		
	new iRet , iPos , iNumEntries = nvault_util_count( iVaultHandle );
	new szKey[ _NVAULTUTIL_MAX_KEY_LEN ] , szValue[ _NVAULTUTIL_MAX_VAL_LEN ] , iTimeStamp;

	for ( new iCurrent = 1 ; iCurrent <= iNumEntries ; iCurrent++ )
	{
		iPos = nvault_util_read( iVaultHandle , iPos , szKey , charsmax( szKey ) , szValue , charsmax( szValue ) , iTimeStamp );
		
		ExecuteForward( iFwdHandle , iRet , iCurrent , iNumEntries , szKey , szValue , iTimeStamp , Data , iSize );
	}
	
	return iRet;
}

stock nvault_util_pos( iVaultHandle )
{
	return ftell( iVaultHandle );
}

stock nvault_util_read_array( iVaultHandle , iOffset , szKey[] , iKeySize , iArray[] , iArraySize , &iItemsRead=0 , &iTimeStamp=0 )
{
	static iKeyLen , iValLen , DataBuffer[ _NVAULTUTIL_BUFFER_SIZE ];
	new iStringPos , iArrayPos , iValue[ 1 ] , bmByteMap , szString[ _NVAULTUTIL_BUFFERSIZE ];
	
	fseek( iVaultHandle , iOffset ? iOffset : _NVAULTUTIL_OFFSET_DATASTART , SEEK_SET );
	
	fread_raw( iVaultHandle , DataBuffer , 1 , BLOCK_INT );
	iTimeStamp = DataBuffer[ 0 ];
	
	fread_raw( iVaultHandle , DataBuffer , 1 , BLOCK_BYTE );
	iKeyLen = DataBuffer[ 0 ] & 0xFF;
	
	fread_raw( iVaultHandle , DataBuffer , 1 , BLOCK_SHORT );
	iValLen = DataBuffer[ 0 ] & 0xFFFF;
	
	fread_raw( iVaultHandle , DataBuffer , iKeyLen , BLOCK_CHAR );
	_nvault_util_read_string( szKey , _nvault_util_minsize( iKeySize , iKeyLen ) , DataBuffer , sizeof( DataBuffer ) );
	
	fread_raw( iVaultHandle , DataBuffer , iValLen , BLOCK_CHAR );
	_nvault_util_read_string( szString , _nvault_util_minsize( charsmax( szString ) , iValLen ) , DataBuffer , sizeof( DataBuffer ) ); 
	
	while ( szString[ iStringPos ] && ( iStringPos < charsmax( szString ) ) && ( iArrayPos < iArraySize ) )
	{
		bmByteMap = szString[ iStringPos++ ];
		
		for ( new i = 0 ; i < 4 ; i++ )
		{
			iValue{ i } = bmByteMap & ( 1 << i ) ? szString[ iStringPos ] : 0;
			iStringPos++;
		}
	
		iArray[ iArrayPos++ ] = iValue[ 0 ];
	}
	
	iItemsRead = iArrayPos;
	
	return ftell( iVaultHandle );
}

stock nvault_util_readall_array( iVaultHandle , const szForwardFunc[] , Data[]={0} , iSize=0 )
{
	new iFwdHandle = CreateMultiForward( szForwardFunc , ET_IGNORE , FP_CELL , FP_CELL , FP_STRING , FP_ARRAY , FP_CELL , FP_CELL , FP_STRING , FP_CELL );
	
	if ( iFwdHandle <= 0 )
		set_fail_state( "nvault_util_readall() failed to create forward" );
		
	new iRet , iPos , iNumEntries = nvault_util_count( iVaultHandle );
	new szKey[ _NVAULTUTIL_MAX_KEY_LEN ] , iArray[ _NVAULTUTIL_MAXARRAYSIZE ] , iTimeStamp , iArrayHandle , iItemsRead;

	for ( new iCurrent = 1 ; iCurrent <= iNumEntries ; iCurrent++ )
	{
		iPos = nvault_util_read_array( iVaultHandle , iPos , szKey , charsmax( szKey ) , iArray , sizeof( iArray ) , iItemsRead , iTimeStamp );
		
		iArrayHandle = PrepareArray( iArray , _NVAULTUTIL_MAXARRAYSIZE , 0 );
		ExecuteForward( iFwdHandle , iRet , iCurrent , iNumEntries , szKey , iArrayHandle , iItemsRead , iTimeStamp , Data , iSize );
	}
	
	return iRet;
}

stock _nvault_util_byte_map( iValue[ 1 ] )
{
	new iOut[ 1 ] = { _NVAULTUTIL_BYTEMAP };

	for ( new i = 0 ; i < 4 ; i++)
		iOut[ 0 ] |= !iValue{ i } ? 0 : ( 1 << i );

	return iOut[ 0 ];
}

stock _nvault_util_read_string( szDestString[] , iMaxLen , const SourceData[] , iSourceSize )
{   
	new iDestPos = -1;
	new iBytePos = 4;
	new iOffset = 1;
	new iSourceMax = ( iSourceSize * 4 );
	
	while ( ( ++iDestPos < iMaxLen ) && ( iBytePos < iSourceMax ) )
	{
		szDestString[ iDestPos ] = SourceData{ iBytePos - iOffset++ };

		if ( iDestPos && ( ( iDestPos % 4 ) == 3 ) )
		{
			iBytePos += 4;
			iOffset = 1;
		}
	}
	
	szDestString[ iDestPos ] = EOS;
}
