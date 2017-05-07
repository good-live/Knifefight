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
	name = "Knifefight - BHOP", 
	author = PLUGIN_AUTHOR, 
	description = "Disables bhop during a knifefight.", 
	version = PLUGIN_VERSION, 
	url = "painlessgaming.eu"
};

ConVar g_cBhop;

public void OnPluginStart()
{
	g_cBhop = FindConVar("sv_autobunnyhopping");
}

public Action KF_OnCountdownStart(int terrorist, int ct, int timer)
{
	g_cBhop.IntValue = 0;
	PrintToChatAll("Disabled BHOP");
	return Plugin_Continue;
}

public void KF_OnFightEnd(int terrorist, int ct, int looser)
{
	g_cBhop.IntValue = 1;
	PrintToChatAll("Enabled BHOP");
}