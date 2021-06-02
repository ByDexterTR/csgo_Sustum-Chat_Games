#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <warden>

#define MAX_WORDS 2048

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "CTSustum", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

char yazilar[MAX_WORDS][256];
bool yazildi = true, CTyazdimi[65] =  { false, ... };
static int randomSayi;
static int toplamYazi;
int KalanSure, KalanSure2, KALANCT;
Handle h_timer = null;

#define foreachPlayer(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientInGame(%1) && !IsFakeClient(%1))

ConVar ctsustum_flag = null, g_Advanced = null;

public void OnPluginStart()
{
	HookEvent("round_start", RoundStart);
	RegConsoleCmd("sm_ctsustum", Command_Sustum, "sm_ctsustum");
	ctsustum_flag = CreateConVar("sm_ctsustum_flag", "q", "Komutçu harici kullanacak kişinin yetki bayrağı");
	g_Advanced = CreateConVar("sm_ctsustum_gosterim", "0", "0 = Menü | 1 = Ekran Ortası");
	AutoExecConfig(true, "CTSustum", "ByDexter");
	yazilariOku();
}

public void OnClientPostAdminCheck(int client)
{
	CTyazdimi[client] = false;
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

public void OnMapStart()
{
	yazilariOku();
}

public int Panel_CallBack(Menu panel, MenuAction action, int client, int position)
{
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
	ctsustum_flag.GetString(YetkiBayragi, sizeof(YetkiBayragi));
	if (warden_iswarden(client) || CheckAdminFlag(client, YetkiBayragi))
	{
		if (yazildi)
		{
			KalanSure = 3;
			PrintToChatAll("[SM] \x10%N\x01, CTSustumu başlattı.", client);
			KALANCT = 0;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_CT && !warden_iswarden(i))
				{
					CTyazdimi[i] = true;
					KALANCT++;
				}
			}
			if (h_timer != null)
			{
				delete h_timer;
				h_timer = null;
			}
			h_timer = CreateTimer(1.0, MenuGoster, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "[SM] \x01Aktif bir CTSustum bulunmakta.");
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \x01Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
}

public Action MenuGoster(Handle timer)
{
	if (KalanSure <= 0)
	{
		randomSayi = GetRandomInt(0, toplamYazi);
		yazildi = false;
		h_timer = null;
		KalanSure2 = 15;
		if (g_Advanced.BoolValue)
		{
			char sBuffer[512];
			Format(sBuffer, sizeof(sBuffer), "CTSustum: <font color='#00FF00'>%s</font> | Kalan Saniye: <font color='#00FF00'>%d</font>", yazilar[randomSayi], KalanSure2);
			ShowStatusMessage(-1, sBuffer, 2);
		}
		else
		{
			Panel panel = new Panel();
			char MenuFormat[256];
			Format(MenuFormat, 256, "CTSustum Kalan Saniye: %d\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", KalanSure2);
			panel.SetTitle(MenuFormat);
			Format(MenuFormat, 256, "%s\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", yazilar[randomSayi]);
			panel.DrawText(MenuFormat);
			foreachPlayer(Oyuncu)
			{
				//menu.Display(Oyuncu, 1);
				panel.Send(Oyuncu, Panel_CallBack, 1);
			}
			delete panel;
		}
		h_timer = CreateTimer(1.0, BaslatOyunu, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		return Plugin_Stop;
	}
	else
	{
		if (g_Advanced.BoolValue)
		{
			char sBuffer[512];
			Format(sBuffer, sizeof(sBuffer), "CTSustum Başlamasına Kalan Saniye: <font color='#00FF00'>%d</font>", KalanSure);
			ShowStatusMessage(-1, sBuffer, 2);
		}
		else
		{
			Panel panel = new Panel();
			char MenuFormat[256];
			Format(MenuFormat, 256, "CTSustum %d Saniye sonra başlayacak\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", KalanSure);
			panel.SetTitle(MenuFormat);
			Format(MenuFormat, 256, "Kelime burada çıkacak\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
			panel.DrawText(MenuFormat);
			foreachPlayer(Oyuncu)
			{
				panel.Send(Oyuncu, Panel_CallBack, 1);
			}
			delete panel;
		}
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
			PrintToChatAll("[SM] Oyun sona erdi.");
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_CT && !warden_iswarden(i) && CTyazdimi[i])
				{
					PrintToChatAll("[SM] \x01CTSustumu Yazmadı: \x10%N", i);
				}
			}
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
			if (g_Advanced.BoolValue)
			{
				char sBuffer[512];
				Format(sBuffer, sizeof(sBuffer), "CTSustum: <font color='#FFA500'>%s</font> | Kalan Saniye: <font color='#FFA500'>%d</font>", yazilar[randomSayi], KalanSure2);
				ShowStatusMessage(-1, sBuffer, 2);
			}
			else
			{
				Panel panel = new Panel();
				char MenuFormat[256];
				Format(MenuFormat, 256, "CTSustum Kalan Saniye: %d\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", KalanSure2);
				panel.SetTitle(MenuFormat);
				Format(MenuFormat, 256, "%s\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", yazilar[randomSayi]);
				panel.DrawText(MenuFormat);
				foreachPlayer(Oyuncu)
				{
					//menu.Display(Oyuncu, 1);
					panel.Send(Oyuncu, Panel_CallBack, 1);
				}
				delete panel;
			}
		}
	}
	KalanSure2--;
	return Plugin_Continue;
}

/*public int Menu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
}*/

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (!yazildi && CTyazdimi[client] && IsClientInGame(client) && strcmp(sArgs, yazilar[randomSayi], true) == 0 && !IsFakeClient(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		CTyazdimi[client] = false;
		KALANCT--;
		if (KALANCT <= 1)
		{
			char ClientName[128];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_CT && !warden_iswarden(i) && CTyazdimi[i])
				{
					CTyazdimi[i] = false;
					ClearWeaponEx(i);
					ForcePlayerSuicide(i);
					GetClientName(i, ClientName, sizeof(ClientName));
					ChangeClientTeam(i, CS_TEAM_T);
				}
			}
			if (g_Advanced.BoolValue)
			{
				char sBuffer[512];
				Format(sBuffer, sizeof(sBuffer), "<font color='#00FF00'>%s</font> Kaybetti", ClientName);
				ShowStatusMessage(-1, sBuffer, 2);
			}
			else
			{
				Panel panel = new Panel();
				char MenuFormat[256];
				Format(MenuFormat, 256, "Kaybeden: %s\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", ClientName);
				panel.SetTitle(MenuFormat);
				Format(MenuFormat, 256, "Aga be :C\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
				panel.DrawText(MenuFormat);
				foreachPlayer(Oyuncu)
				{
					//menu.Display(Oyuncu, 1);
					panel.Send(Oyuncu, Panel_CallBack, 3);
				}
				delete panel;
				/*Menu menu = new Menu(Menu_CallBack);
				menu.SetTitle("➔ %s Kaybeti.\n ", ClientName);
				menu.AddItem("X", "Aga be :C", ITEMDRAW_DISABLED);
				menu.ExitBackButton = false;
				menu.ExitButton = false;
				foreachPlayer(oyuncu)
				{
					menu.Display(oyuncu, 3);
				}*/
			}
			if (h_timer != null)
			{
				delete h_timer;
				h_timer = null;
			}
			yazildi = true;
		}
		PrintToChatAll("[SM] \x10%N\x01, klavye delikanlısı yazdı.", client);
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


void ClearWeaponEx(int client)
{
	int wepIdx;
	for (int i; i < 12; i++)
	{
		while ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, wepIdx);
			RemoveEntity(wepIdx);
		}
	}
}

bool CheckAdminFlag(int client, const char[] flags) // Z harfi otomatik erişim verir
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