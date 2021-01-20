#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <warden>

#define MAX_WORDS 2048

public Plugin myinfo = 
{
	name = "DSustum", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

char yazilar[MAX_WORDS][256];
bool yazildi = true, vantep = true;
static int randomSayi;
static int toplamYazi;
int KalanSure, KalanSure2;
bool BordoBereli[MAXPLAYERS] =  { false, ... }, oldurdumu[MAXPLAYERS] =  { false, ... };
Handle h_timer = null;

#define foreachPlayer(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsValidClient(%1))

ConVar dsustum_flag = null;

public void OnClientPostAdminCheck(int client)
{
	BordoBereli[client] = false;
	oldurdumu[client] = false;
}

public OnPluginStart()
{
	HookEvent("weapon_fire", WeaponFire);
	HookEvent("round_start", RoundStart);
	HookEvent("player_death", OnClientDead);
	RegConsoleCmd("sm_dsustum", Command_Sustum, "sm_dsustum");
	dsustum_flag = CreateConVar("sm_dsustum_flag", "q", "Komutçu harici kullanacak kişinin yetki bayrağı");
	AutoExecConfig(true, "DSustum", "ByDexter");
	yazilariOku();
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (h_timer != null)
	{
		delete h_timer;
		h_timer = null;
	}
	yazildi = true;
}

public Action OnClientDead(Event event, const char[] name, bool dontBroadcast)
{
	if (!yazildi)
	{
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (IsValidClient(attacker) && BordoBereli[attacker])
		{
			int victim = GetClientOfUserId(event.GetInt("userid"));
			if (IsValidClient(victim))
			{
				oldurdumu[attacker] = true;
			}
		}
	}
}

public void OnMapStart()
{
	yazilariOku();
}

void yazilariOku()
{
	char yazilarDosyasi[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, yazilarDosyasi, sizeof(yazilarDosyasi), "configs/dextersustum.txt");
	if (!FileExists(yazilarDosyasi))
		SetFailState("[ByDexter] --> addons/sourcemod/configs/dextersustum.txt , dosyası bulunamadı. <--");
	
	Handle yazilarHandle = OpenFile(yazilarDosyasi, "r");
	int i = 0;
	while (i < MAX_WORDS && !IsEndOfFile(yazilarHandle))
	{
		ReadFileLine(yazilarHandle, yazilar[i], sizeof(yazilar[]));
		TrimString(yazilar[i]);
		i++;
	}
	toplamYazi = i;
	delete yazilarHandle;
}

public Action Command_Sustum(int client, int args)
{
	char YetkiBayragi[4];
	dsustum_flag.GetString(YetkiBayragi, sizeof(YetkiBayragi));
	if (warden_iswarden(client) || CheckAdminFlag(client, YetkiBayragi))
	{
		if (yazildi)
		{
			Menu menu = new Menu(Menu_CallBack);
			menu.SetTitle("[DSUSTUM] Öldüremezse Ölsün Mü?\n ");
			menu.AddItem("0", "Evet");
			menu.AddItem("1", "Hayır");
			menu.Display(client, 0);
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "[SM] \x01Aktif bir DSustum bulunmakta.");
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \x01Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
}

public int Menu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (yazildi)
		{
			char Item[32];
			menu.GetItem(param2, Item, sizeof(Item));
			if (StringToInt(Item) == 0)
			{
				vantep = true;
			}
			else if (StringToInt(Item) == 1)
			{
				vantep = false;
			}
			foreachPlayer(player)
			{
				oldurdumu[player] = false;
				BordoBereli[player] = false;
			}
			KalanSure = 3;
			PrintToChatAll("[SM] \x10%N\x01, DSustumu başlattı.", param1);
			if (h_timer != null)
				delete h_timer;
			h_timer = CreateTimer(1.0, MenuGoster, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		}
		else
		{
			PrintToChat(param1, "[SM] \x01Aktif bir DSustum bulunmakta.");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && BordoBereli[client])
	{
		char WeaponNameDeagle[64];
		GetClientWeapon(client, WeaponNameDeagle, sizeof(WeaponNameDeagle));
		if (strcmp(WeaponNameDeagle, "weapon_deagle", false) == 0)
		{
			CreateTimer(0.2, Silahial, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Silahial(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		int Slots = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		if (Slots != -1)
		{
			RemovePlayerItem(client, Slots);
			RemoveEntity(Slots);
		}
		SetEntityRenderColor(client, 255, 255, 255, 255);
		CreateTimer(0.3, Kontrolettir, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Kontrolettir(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client) && vantep)
	{
		if (oldurdumu[client])
		{
			PrintToChatAll("[SM] \x10%N\x01, birisini avladığı için hayatta kaldı.", client);
		}
		else
		{
			PrintToChatAll("[SM] \x10%N\x01, kimseyi öldüremediği için öldürüldü.", client);
			ForcePlayerSuicide(client);
		}
	}
	BordoBereli[client] = false;
	oldurdumu[client] = false;
}

public Action MenuGoster(Handle timer)
{
	if (KalanSure <= 0)
	{
		randomSayi = GetRandomInt(0, toplamYazi);
		yazildi = false;
		h_timer = null;
		KalanSure2 = 15;
		h_timer = CreateTimer(1.0, BaslatOyunu, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		return Plugin_Stop;
	}
	else
	{
		char sBuffer[512];
		Format(sBuffer, sizeof(sBuffer), "DSustum Başlamasına Kalan Saniye: <font color='#00FF00'>%d</font>", KalanSure);
		ShowStatusMessage(-1, sBuffer, 2);
	}
	KalanSure--;
	return Plugin_Continue;
}

public Action BaslatOyunu(Handle timer)
{
	if (KalanSure2 <= 0)
	{
		if (!yazildi)
		{
			PrintToChatAll("[SM] \x01Kimse yazamadığı için oyun sona erdi.");
			yazildi = true;
		}
		h_timer = null;
		return Plugin_Stop;
	}
	else
	{
		if (yazildi)
		{
			h_timer = null;
			return Plugin_Stop;
		}
		else
		{
			char sBuffer[512];
			Format(sBuffer, sizeof(sBuffer), "DSustum: <font color='#FFA500'>%s</font> | Kalan Saniye: <font color='#FFA500'>%d</font>", yazilar[randomSayi], KalanSure2);
			ShowStatusMessage(-1, sBuffer, 2);
		}
	}
	KalanSure2--;
	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (!yazildi && IsValidClient(client) && IsPlayerAlive(client) && strcmp(sArgs, yazilar[randomSayi], true) == 0 && !IsFakeClient(client) && GetClientTeam(client) == CS_TEAM_T)
	{
		char sBuffer[512];
		char ClientName[128];
		GetClientName(client, ClientName, sizeof(ClientName));
		Format(sBuffer, sizeof(sBuffer), "<font color='#00FF00'>%s</font> Kazandı", ClientName);
		ShowStatusMessage(-1, sBuffer, 2);
		PrintToChatAll("[SM] \x10%N\x01, klavye delikanlısı oyunu kazandı.", client);
		BordoBereli[client] = true;
		int Slots = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		if (Slots != -1)
		{
			RemovePlayerItem(client, Slots);
			RemoveEntity(Slots);
		}
		int Silahi = GivePlayerItem(client, "weapon_deagle");
		SetEntProp(Silahi, Prop_Data, "m_iClip1", 1);
		SetEntProp(Silahi, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
		SetEntProp(Silahi, Prop_Send, "m_iSecondaryReserveAmmoCount", 0);
		SetEntityRenderColor(client, 0, 255, 0, 255);
		if (h_timer != null)
		{
			delete h_timer;
			h_timer = null;
		}
		yazildi = true;
	}
}

void ShowStatusMessage(int client = -1, const char[] message = NULL_STRING, int hold = 1)
{
	Event show_survival_respawn_status = CreateEvent("show_survival_respawn_status");
	if (show_survival_respawn_status != null)
	{
		show_survival_respawn_status.SetString("loc_token", message);
		show_survival_respawn_status.SetInt("duration", hold);
		show_survival_respawn_status.SetInt("userid", -1);
		if (client == -1)
		{
			foreachPlayer(player)
			{
				show_survival_respawn_status.FireToClient(player);
			}
		}
		else
		{
			show_survival_respawn_status.FireToClient(client);
		}
		show_survival_respawn_status.Cancel();
	}
}

stock bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}

stock bool CheckAdminFlag(int client, const char[] flags) // Z harfi otomatik erişim verir
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			bEntitled = true;
			break;
		}
	}
	return bEntitled;
} 