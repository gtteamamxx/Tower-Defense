/*
    │ Author  : Arkshine
    │ Plugin  : Infinite Round
    │ Version : v2.1.1

    Support : http://forums.alliedmods.net/showthread.php?t=120866

    This plugin is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2 of the License, or (at
    your option) any later version.

    This plugin is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this plugin; if not, write to the Free Software Foundation,
    Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#if defined _infinite_round_included
  #endinput
#endif
#define _infinite_round_included

#pragma reqlib infinite_round


enum RoundEndType ( <<= 1 )
{
    RoundEndType_RoundTimeExpired = 1,  // a    1
    RoundEndType_BombExploded,          // b    2
    RoundEndType_BombDefused,           // c    4
    RoundEndType_HostagesRescued,       // d    8
    RoundEndType_VipEscaped,            // e    16
    RoundEndType_VipAssassinated,       // f    32
    RoundEndType_TerroristWin,          // g    64
    RoundEndType_CTWin,                 // h    128
    RoundEndType_RoundDraw,             // i    256
    RoundEndType_TerroristsEscaped,     // j    512
    RoundEndType_CTsPreventEscape,      // k    1024
};                                      // *    2047

const RoundEndType:RoundEndTypes_Bomb   = RoundEndType_BombExploded      | RoundEndType_BombDefused;
const RoundEndType:RoundEndTypes_Vip    = RoundEndType_VipEscaped        | RoundEndType_VipAssassinated;
const RoundEndType:RoundEndTypes_Team   = RoundEndType_TerroristWin      | RoundEndType_CTWin;
const RoundEndType:RoundEndTypes_Prison = RoundEndType_TerroristsEscaped | RoundEndType_CTsPreventEscape;
const RoundEndType:RoundEndTypes_Others = RoundEndType_HostagesRescued   | RoundEndType_RoundDraw;

const RoundEndType:Invalid_RoundEndType = RoundEndType:0;
const RoundEndType:RoundEndType_None    = Invalid_RoundEndType;
const RoundEndType:RoundEndType_All     = RoundEndType - RoundEndType:1;

/**
 * @brief Called when a round ends.
 *
 * @note  You can block a round end happening by returning PLUGIN_HANDLED.
 *        Blocking from the forward supercedes always the ir_block_roundend cvar value.
 *
 * @param type     The type of round end. See RoundEndType constants.
 */
forward OnRoundEnd( const RoundEndType:type );

/**
 * @brief Set what round end to block. Same behavior as 'ir_block_roundend' cvar.
 *
 * @param type     The type of round end. See RoundEndType constants.
 * @noreturn
 */
native SetBlockingRoundEnd( const RoundEndType:type );