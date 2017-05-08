#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
#include <sdktools>
#include <knifefight>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Knifefight - Freeze", 
	author = PLUGIN_AUTHOR, 
	description = "Freezes the players during the countdown.", 
	version = PLUGIN_VERSION, 
	url = "painlessgaming.eu"
};

public Action KF_OnCountdownStart(int terrorist, int ct, int timer)
{
	SetEntityMoveType(terrorist, MOVETYPE_NONE);
	SetEntityMoveType(ct, MOVETYPE_NONE);
	PrintToChatAll("Freezed!");
	return Plugin_Continue;
}

public Action KF_OnFightStart(int terrorist, int ct)
{
	SetEntityMoveType(terrorist, MOVETYPE_WALK);
	SetEntityMoveType(ct, MOVETYPE_WALK);
	PrintToChatAll("Unfreezed!");
	return Plugin_Continue;
}

public void KF_OnFightEnd(int terrorist, int ct, int looser)
{
	SetEntityMoveType(terrorist, MOVETYPE_WALK);
	SetEntityMoveType(ct, MOVETYPE_WALK);
	PrintToChatAll("Unfreezed!");
}
