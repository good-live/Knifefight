#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "1.0.3"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>
#include <emitsoundany>

#define SOUND_BLIP "buttons/blip1.wav"
#define SOUND_CHICKEN "play ambient/creatures/chicken_death_01.wav"

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Knifefight", 
	author = PLUGIN_AUTHOR, 
	description = "1v1 Knifefight on round end", 
	version = PLUGIN_VERSION, 
	url = "painlessgaming.eu"
};

int g_iStatus = 0;
int g_iCT;
int g_iT;
int g_iCountdown = -1;
int g_iFightTime = -1;

int g_beamsprite;
int g_halosprite;

bool g_bConfirmed[MAXPLAYERS + 1];
bool g_bLoaded;

float g_fSpawns[2][3];

ConVar g_cCountdown;
ConVar g_cFightTime;

bool g_bNewRound = false;

Handle g_hCountdownForward;
Handle g_hFightStartForward;
Handle g_hKnifeEndForward;

public void OnPluginStart()
{
	
	g_hCountdownForward = CreateGlobalForward("KF_OnCountdownStart", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFightStartForward = CreateGlobalForward("KF_OnFightStart", ET_Event, Param_Cell, Param_Cell);
	g_hKnifeEndForward = CreateGlobalForward("KF_OnFightEnd", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	
	RegConsoleCmd("sm_addspawn", Command_AddSpawn, "", ADMFLAG_ROOT);
	
	g_cCountdown = CreateConVar("knifefight_countdown", "4", "The time in secounds for the countdown!");
	g_cFightTime = CreateConVar("knifefight_fighttime", "20", "The time in secounds for the fighttime!");
	
	AutoExecConfig(true);
	LoadTranslations("knifefight.phrases");
}

public void OnMapStart()
{
	LoadSpawns();
	
	g_beamsprite = PrecacheModel("materials/sprites/laser.vmt");
 	g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");
 	
	PrecacheSound(SOUND_BLIP, true);
}

public void OnClientPutInServer(int i)
{
	SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action EventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	
	if (g_iStatus)
	{
		//There is a fight and somebody won :)
		int looser = GetClientOfUserId(event.GetInt("userid"));
		EndFight(looser);
	} else {
		//Check the amount of alive ct's/t's
		int ct, t;
		int team;
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientValid(i) && IsPlayerAlive(i))
			{
				team = GetClientTeam(i);
				if (team == 3)
				{
					g_iCT = i;
					ct++;
				} else if (team == 2) {
					g_iT = i;
					t++;
				}
			}
		}
		
		if (ct == 1 && t == 1)
		{
			//There is a 1v1 Situation
			g_bConfirmed[g_iCT] = false;
			g_bConfirmed[g_iT] = false;
			
			g_bNewRound = false;
			
			DisplaySelectionMenu(g_iCT);
			DisplaySelectionMenu(g_iT);
			
		}
	}
}

void DisplaySelectionMenu(int client)
{
	char sTitel[32];
	char sYes[32];
	char sNo[32];
	
	Format(sTitel, sizeof(sTitel), "%T", "titel", client);
	Format(sYes, sizeof(sYes), "%T", "yes", client);
	Format(sNo, sizeof(sNo), "%T", "no", client);
	
	Menu menu = new Menu(ConfirmMenuHandler);
	menu.SetTitle(sTitel);
	menu.AddItem("yes", sYes);
	menu.AddItem("no", sNo);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ConfirmMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if(g_bNewRound)
	{
		if (action == MenuAction_End)
			delete menu;
		return 0;
	}
		
	if(!IsClientValid(client))
		return 0;
		
	if (action == MenuAction_Select)
	{
		char sParam[32];
		GetMenuItem(menu, param, sParam, sizeof(sParam));
		
		if (StrEqual(sParam, "yes", false))
		{
			g_bConfirmed[client] = true;
			CPrintToChatAll("%t", "accepted", client);
			CheckConfirmations();
		}
		else
		{
			CPrintToChatAll("%t", "declined", client);
			for (int i = 0; i <= MaxClients; i++)
			{
				if(IsClientValid(i))
				{
					ClientCommand(i, "playgamesound Music.StopAllMusic");
					ClientCommand(i, "play error.wav");
					ClientCommand(i, SOUND_CHICKEN);  
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		CPrintToChatAll("%t", "declined", client);
		for (int i = 0; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				ClientCommand(i, "playgamesound Music.StopAllMusic");
				ClientCommand(i, "play error.wav");
				ClientCommand(i, SOUND_CHICKEN);  
			}
		}
	}
	else if (action == MenuAction_End)
		delete menu;
	
	return 0;
}

void CheckConfirmations()
{
	if (!g_iStatus)
	{
		if (g_bConfirmed[g_iCT] && g_bConfirmed[g_iT])
		{
			if (IsClientValid(g_iCT) && IsPlayerAlive(g_iCT) && IsClientValid(g_iT) && IsPlayerAlive(g_iT))
				StartFight();
		}
	}
}

void StartFight()
{
	Action result;
	
	Call_StartForward(g_hCountdownForward);
	Call_PushCell(g_iCT);
	Call_PushCell(g_iT);
	Call_PushCell(g_cCountdown.IntValue);
	Call_Finish(result);
	
	//Aborted
	if(result >= Plugin_Stop)
	{
		g_iStatus = 0;
		return;
	}
	
	g_iStatus = 1;
	if (!g_bLoaded)
	{
		float ctPos[3];
		GetClientAbsOrigin(g_iCT, ctPos);
		TeleportEntity(g_iT, ctPos, NULL_VECTOR, NULL_VECTOR);
	} else {
		TeleportEntity(g_iT, g_fSpawns[0], NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(g_iCT, g_fSpawns[1], NULL_VECTOR, NULL_VECTOR);
	}
	
	SetEntityHealth(g_iT, 100);
	SetEntityHealth(g_iCT, 100);
	
	SetEntProp(g_iT, Prop_Data, "m_ArmorValue", 100, 1);
	SetEntProp(g_iCT, Prop_Data, "m_ArmorValue", 100, 1);
	
	//Swap to knife
	ChangePlayerWeaponSlot(g_iCT, 2);
	ChangePlayerWeaponSlot(g_iT, 2);
	
	g_iFightTime = g_cFightTime.IntValue;
	g_iCountdown = g_cCountdown.IntValue;
	
	CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
}

public Action Timer_Countdown(Handle timer)
{
	if(g_iStatus != 1)
		return Plugin_Stop;
	
	if (IsClientValid(g_iCT) && IsPlayerAlive(g_iCT) && IsClientValid(g_iT) && IsPlayerAlive(g_iT))
	{
		PrintHintText(g_iCT, "%T", "countdown", g_iCT, --g_iCountdown);
		PrintHintText(g_iT, "%T", "countdown", g_iT, g_iCountdown);
	} else {
		return Plugin_Stop;
	}
	if (g_iCountdown > 0)
		return Plugin_Continue;
	
	
	Action result;
	
	Call_StartForward(g_hFightStartForward);
	Call_PushCell(g_iCT);
	Call_PushCell(g_iT);
	Call_Finish(result);
	
	//Aborted
	if(result >= Plugin_Stop)
	{
		g_iStatus = 0;
		return Plugin_Stop;
	}
	
	g_iStatus = 2;
	
	PrintHintText(g_iCT, "%T", "gogogo", g_iCT);
	PrintHintText(g_iT, "%T", "gogogo", g_iT);
	
	CreateTimer(1.0, Timer_FightTime, _, TIMER_REPEAT);
	
	return Plugin_Stop;
}

public Action Timer_FightTime(Handle Timer)
{
	if(g_iStatus != 2)
		return Plugin_Stop;
		
	if (IsClientValid(g_iCT) && IsPlayerAlive(g_iCT) && IsClientValid(g_iT) && IsPlayerAlive(g_iT))
	{

		Beacon(g_iCT);
		Beacon(g_iT);
		
		if (g_iFightTime > 0)
		{
			PrintHintText(g_iCT, "%T", "timeleft", g_iCT, --g_iFightTime);
			PrintHintText(g_iT, "%T", "timeleft", g_iT, g_iFightTime);
			return Plugin_Continue;
		} else {
			ForcePlayerSuicide(g_iCT);
			ForcePlayerSuicide(g_iT);
			
			CPrintToChatAll("%t", "end");
	
			Call_StartForward(g_hKnifeEndForward);
			Call_PushCell(g_iCT);
			Call_PushCell(g_iT);
			Call_PushCell(-1);
			Call_Finish();
			
			return Plugin_Stop;
		}
		
	} else {
		return Plugin_Stop;
	}
}

void Beacon(int client)
{
	int redColor[4] =  { 255, 75, 75, 255 };
	int blueColor[4] =  { 75, 75, 255, 255 };
	int greyColor[4] =  { 128, 128, 128, 255 };
	int team = GetClientTeam(client);
	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 10;
	
	TE_SetupBeamRingPoint(fPos, 10.0, 375.0, g_beamsprite, g_halosprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
	TE_SendToAll();
	
	if (team == 2)
	{
		TE_SetupBeamRingPoint(fPos, 10.0, 375.0, g_beamsprite, g_halosprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	}
	else if (team == 3)
	{
		TE_SetupBeamRingPoint(fPos, 10.0, 375.0, g_beamsprite, g_halosprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
	}
	TE_SendToAll();
	
	GetClientEyePosition(client, fPos);
	EmitAmbientSound(SOUND_BLIP, fPos, client, SNDLEVEL_RAIDSIREN);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (g_iStatus && IsClientValid(attacker))
	{
		if (g_iStatus == 1)
			return Plugin_Handled;
		
		char sWeapon[32];
		
		GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
		
		if ((StrContains(sWeapon, "knife", false) != -1) || (StrContains(sWeapon, "bayonet", false) != -1))
			return Plugin_Continue;
		else
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

void EndFight(int looser)
{
	Call_StartForward(g_hKnifeEndForward);
	Call_PushCell(g_iCT);
	Call_PushCell(g_iT);
	Call_PushCell(looser);
	Call_Finish();
	CPrintToChatAll("%t", "lostround", looser);
	g_iStatus = 0;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	g_bNewRound = true;
	g_iStatus = 0;
	
	Call_StartForward(g_hKnifeEndForward);
	Call_PushCell(g_iCT);
	Call_PushCell(g_iT);
	Call_PushCell(-1);
	Call_Finish();
}

bool IsClientValid(int client)
{
	if (!(0 < client <= MaxClients) || !IsClientConnected(client) || !IsClientInGame(client))
		return false;
	
	return true;
}

//Thanks to bl4nk
stock bool ChangePlayerWeaponSlot(int iClient, int iSlot) {
	int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWeapon > MaxClients) {
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		return true;
	}
	
	return false;
}

//Thanks to Z1pcore
void LoadSpawns()
{
	g_bLoaded = false;
	char sMap[64];
	
	GetCurrentMap(sMap, sizeof(sMap));
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/knifefight/%s.txt", sMap);
	
	Handle hFile = OpenFile(sPath, "r");
	
	char sBuffer[512];
	char sDatas[3][32];
	
	if (hFile != null)
	{
		for (int i = 0; i < 2; i++)
		{
			if (!ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
			{
				g_bLoaded = false;
				return;
			}
			ExplodeString(sBuffer, ";", sDatas, 3, 32);
			
			g_fSpawns[i][0] = StringToFloat(sDatas[0]);
			g_fSpawns[i][1] = StringToFloat(sDatas[1]);
			g_fSpawns[i][2] = StringToFloat(sDatas[2]);
		}
		g_bLoaded = true;
		CloseHandle(hFile);
	}
}

public Action Command_AddSpawn(int client, int args)
{
	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/knifefight/%s.txt", sMap);
	PrintToChatAll("Path: %s", sPath);
	Handle hFile = OpenFile(sPath, "a");
	
	if (hFile != null)
	{
		WriteFileLine(hFile, "%.2f;%.2f;%.2f;", fPos[0], fPos[1], fPos[2]);
		CloseHandle(hFile);
		ReplyToCommand(client, "Succesfully saved spawn!");
		return Plugin_Handled;
	}
	ReplyToCommand(client, "Failed to save spawn");
	return Plugin_Handled;
} 
