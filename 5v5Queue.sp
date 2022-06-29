#include <sourcemod>
#include <sdktools>

ArrayList g_aJoinQueue;

bool g_bLate = false;

ConVar g_hMax;

public Plugin myinfo = 
{
	name = "5v5 Queue System",
	author = "Cruze",
	description = "Limits teams and adds queue to join.",
	version = "1.2.0",
	url = "http://steamcommunity.com/profiles/76561198132924835"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	AddCommandListener(Command_Jointeam, "jointeam");
	
	g_hMax = CreateConVar("sm_5v5queue_max_per_team", "5", "MAX PLAYERS PER TEAM", _, true, 1.0);

	if(g_bLate)
	{
		for(int i = 2; i <= 3; i++)
		{
			do
			{
				MoveRandomTeamPlayerToSpec(i);
			}
			while(GetTeamPlayerCount(i) > g_hMax.IntValue);
		}
		g_bLate = false;
	}
}

public void OnMapStart()
{
	g_aJoinQueue = new ArrayList(ByteCountToCells(64));
}

public Action Command_Jointeam(int client, const char[] command, int args)
{
	if(!client || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	if(IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	char sBuf[16];
	GetCmdArg(1, sBuf, 16);
	int newTeam = StringToInt(sBuf);
	int team = GetClientTeam(client);
	
	int tCount = GetTeamPlayerCount(2);
	int ctCount = GetTeamPlayerCount(3);
	if(tCount >= g_hMax.IntValue && ctCount >= g_hMax.IntValue)
	{
		//    no team       spec        auto select        t                ct
		if((team == 0 || team == 1) && (newTeam == 0 || newTeam == 2 || newTeam == 3))
		{
			int arrayCount = g_aJoinQueue.FindValue(client);
			SetHudTextParams(-1.0, 0.2, 3.5, 250, 250, 250, 255);
			if(arrayCount == -1)
			{
				g_aJoinQueue.Push(client);
				PrintHintText(client, "Teams full. You are placed in queue. Position: %i", arrayCount+1);
				ShowHudText(client, -1, "Teams full. You are placed in queue. Position: %i", arrayCount+1);
				PrintToChat(client, "[SM] Teams full. You are placed in queue. Position: %i", arrayCount+1);
			}
			else
			{
				PrintHintText(client, "Teams full. Your position in queue: %i", arrayCount+1);
				ShowHudText(client, -1, "Teams full. Your position in queue: %i", arrayCount+1);
				PrintToChat(client, "[SM] Teams full. Your position in queue: %i", arrayCount+1);
			}
			CreateTimer(0.2, Timer_ChangeTeamToSpec, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Continue;
		}
		//   spec              t             ct
		if(newTeam == 1 && (team == 2 || team == 3))
		{
			ChangeFirstInQueueTeam(team);
		}
	}
	return Plugin_Continue;
}

public Action Timer_ChangeTeamToSpec(Handle timer, any userid)
{
	int client;
	if((client = GetClientOfUserId(userid)) == 0)
	{
		return;
	}
	if(!IsClientInGame(client))
	{
		return;
	}
	int team = GetClientTeam(client);
	if(team != 1)
	{
		ChangeClientTeam(client, 1);
	}
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	int arrayCount = g_aJoinQueue.FindValue(client);
	if(arrayCount != -1)
	{
		g_aJoinQueue.Erase(arrayCount);
	}
	int tCount = GetTeamPlayerCount(2);
	int ctCount = GetTeamPlayerCount(3);
	if(tCount >= g_hMax.IntValue && ctCount >= g_hMax.IntValue)
	{
		int team = GetClientTeam(client);
		//    t             ct
		if(team == 2 || team == 3)
		{
			ChangeFirstInQueueTeam(team);
		}
	}
}

void ChangeFirstInQueueTeam(int team)
{
	if(g_aJoinQueue.Length == 0)
	{
		return;
	}
	
	int target = g_aJoinQueue.Get(0);
	if(target != -1 && IsClientInGame(target))
	{
		g_aJoinQueue.Erase(0);
		ChangeClientTeam(target, team);
	}
}

int GetTeamPlayerCount(int team)
{
	int count;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			count++;
		}
	}
	return count;
}

void MoveRandomTeamPlayerToSpec(int team)
{
	int[] clients = new int[MaxClients+1];
	int count = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			clients[count++] = i;
		}
	}
	int target = -1;
	target = count == 0 ? -1 : clients[GetRandomInt(0, count-1)];
	if(target != -1)
	{
		ChangeClientTeam(target, 1);
		PrintHintText(target, "You are moved to spectators team because your team was full.");
		SetHudTextParams(-1.0, 0.2, 3.5, 250, 250, 250, 255);
		ShowHudText(target, -1, "You are moved to spectators team because your team was full.");
		PrintToChat(target, "[SM] You are moved to spectators team because your team was full.");
	}
}