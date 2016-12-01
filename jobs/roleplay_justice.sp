/*
 * Cette oeuvre, création, site ou texte est sous licence Creative Commons Attribution
 * - Pas d’Utilisation Commerciale
 * - Partage dans les Mêmes Conditions 4.0 International. 
 * Pour accéder à une copie de cette licence, merci de vous rendre à l'adresse suivante
 * http://creativecommons.org/licenses/by-nc-sa/4.0/ .
 *
 * Merci de respecter le travail fourni par le ou les auteurs 
 * https://www.ts-x.eu/ - kossolax@ts-x.eu
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <colors_csgo>

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

public Plugin myinfo = {
	
	name = "Utils: Tribunal", author = "KoSSoLaX",
	description = "RolePlay - Utils: Tribunal",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

enum TribunalData {
	td_Plaignant,
	td_Suspect,
	td_Time,
	td_Owner,
	td_ArticlesCount,
	td_AvocatPlaignant,
	td_AvocatSuspect,
	td_TimeMercenaire,
	td_EnquetePlaignant,
	td_EnqueteSuspect,
	td_DoneDedommagement,
	td_Dedommagement,
	
	td_Max
};
int g_cBeam;

// Numéro, Résumé, heure, amende, dédo, détail
char g_szArticles[28][6][512] = {
	{"221-1-a",		"Meurtre d'un civil",							"18",	"1250",		"1000",	"Toutes atteintes volontaires à la vie d’un citoyen sont condamnées à une peine maximale de 18h de prison et 1250$ d’amende." },
	{"221-1-b",		"Meurtre d'un policier",						"24",	"5500",		"1500",	"Toutes atteintes volontaires à la vie d’un officier des forces de l’ordre sont condamnées à une peine maximale de 24h de prison et 5 500$ d’amende." },
	{"221-2",		"Vol",											"6",	"450",		"-1",	"Le vol est un acte punis d’une peine maximale de 6h de prison et 450$ d’amende." },
	{"221-3",		"Manquement convocation",						"18",	"4000",		"0",	"Le manquement à une convocation devant les tribunaux sans motif valable est puni d’une peine maximale de 18h de prison et 4.000$ d'amende." },
	{"221-4",		"Faux aveux / Dénonciation calomnieuse",		"6",	"1500",		"0",	"Les faux aveux ou les dénonciations calomnieuses sont punis d’une peine maximale de 6h de prison et 1500$ d’amende." },
	{"221-5-a",		"Nuisances sonores", 							"6",	"1500", 	"0",	"Les nuisances sonores sont punies d’une peine maximale de 6h de prison et 1 500$ d'amende." },
	{"221-5-b",		"Insultes / irrespects", 						"6",	"1000", 	"1250",	"Les insultes sont passibles d’une peine maximale de 6h de prison et 1000$ d’amende." },
	{"221-5-c",		"Harcèlements / Menaces", 						"6",	"800",		"300",	"Les actes de harcèlement et/ou menaces sont passibles d'une peine maximale de 6h de prison et 800$ d'amende." },
	{"221-6",		"Récidive",										"6",	"15000",	"0",	"Toute personne condamnée pour une récidive vis-à-vis de meurtre ou d'une infraction déjà jugée sera condamnée à une peine plus lourde, l'amende peut être augmentée progressivement de 15 000$ et la peine de prison de 6h." },
	{"221-7",		"Obstruction ",									"6",	"650",		"0",	"Tous actes obstruant les forces de l’ordre (Masque/Suicide/Pilules/Pots de vins que ce soit avant ou pendant l’audience/Changement de pseudo délibéré, pendant la recherche du criminel et GHB), ou la fuite délibérée, ou mutinerie, sont passible d’une peine maximale de 6h de prison et 650$ d'amende. " },
	{"221-8",		"Bavure policière",								"24",	"3000",		"0",	"Toute acte de maltraitance policière (taser, balle perdue, jail/déjail répétitif...) pourra être rapporté devant les tribunaux. La maltraitance est passible de 24h de prison au maximum, et d'une amende de 3 000$ au maximum" },
	{"221-9",		"Abus de métier",								"6",	"1000",		"500",	"Tout abus d’un métier est passible d’une peine maximale de 6h de prison et 1 000$ d'amende, ainsi qu’un remboursement intégral de la caution prélevée (si abus Justice/Police)." },
	{"221-10-a",	"Fraude",										"24",	"5000",		"0",	"Tout acte de fraude (transaction d'argent) pour éviter des sanctions juridiques peut être rapporté et signalé. Les personnes étant complices de cette fraude peuvent encourir une peine maximale de 24h de prison et 5000$ d'amende." },
	{"221-10-b",	"Association de malfaiteurs",					"6",	"500",		"0",	"Toute association de malfaiteurs (Défense lors de perquisitions notamment) est punissable d’une peine maximale de 6h de prison et 500$ d’amende." },
	{"221-11-a",	"Vente forcée",									"12",	"5000",		"-1",	"Toute personne essayant de vendre sans le consentement libre et éclairé d'une personne peut-être condamnée à une peine maximale de 12h de prison et 5.000$ d’amende, ainsi qu'un remboursement de la totalité de ce dernier. (Le remboursement n’est pas un dédommagement est n’est donc pas soumis aux avocats)." },
	{"221-11-b",	"Refus de vente",								"6",	"1500",		"0",	"Tout refus de vente est punissable par 6h de prison et une amende de 1.500$ au maximum." },
	{"221-12",		"Profiter de la vulnérabilité d’une personne",	"18",	"3000",		"1500",	"Le fait de soumettre une personne à un acte criminel en abusant de sa vulnérabilité ou de sa dépendance à son travail est punis d’une peine maximale de 18h de prison et 3 000$ d’amende en plus de la peine du crime commis" },
	{"221-13-a",	"Destruction de bien d’autrui",					"6",	"1500",		"1000",	"Tout acte volontaire ou involontaire de destruction de bien d'autrui et ce quel que soit les méthodes de destruction utilisées, peut-être condamné par 6h de prison et 1500$ au maximum" },
	{"221-13-b",	"Atteinte à la vie privée",						"6",	"950",		"500",	"Les atteintes à la vie privée telles que l’espionnage, ou l’enregistrement d’une conversation intime, sont punies d’une peine maximale de 6h de prison et 950$ d'amende" },
	{"221-13-c",	"Intrusion dans une propriété privée",			"6",	"800",		"500",	"La violation d’une propriété privée est punie d’une peine maximale de 6h de prison et 800$ d’amende." },
	{"221-13-d",	"Intrusion dans un batiment fédéral",			"18",	"5000",		"500",	"La violation d’un batiment fédéral est punie d’une peine maximale de 18h de prison et 5000$ d’amende." },
	{"221-14-a",	"Usage produit illicite",						"6",	"1000",		"250",	"Droguer ou alcooliser une personne à son insu est un acte punis d’une peine maximale de 6h de prison et 1000$ d’amende. " },
	{"221-14-b",	"Trafic d’armes",								"6",	"750",		"0",	"La vente ou la possession illégale d’armes est passible d’une peine maximale de 6h de prison et 750$ d'amende." },
	{"221-15-a",	"Tentative de corruption",						"24",	"10000",	"0",	"Tout acte de corruption ou de tentative de corruption, est puni d’une peine maximale de 24h de prison et 10 000$ d’amende." },
	{"221-15-b",	"Escroquerie",									"18",	"5000",		"-1",	"Tout acte d’escroquerie est puni d’une peine maximale de 24h de prison et 5 000$ d’amende." },
	{"221-16",		"Séquestration",								"6",	"800",		"500",	"Les actes de séquestrations sont passibles d'une peine maximale de 6h de prison et 800$ d'amende." },
	{"221-17",		"Acte de proxénétisme / prostitution",			"6",	"450",		"0",	"Tout acte de proxénétisme ou de prostitution est passible d'une peine maximale de 6h de prison et 450$ d’amende." },
	{"221-18",		"Asile politique",								"24",	"1500",		"1000",	"Le tribunal est une zone internationale indépendante des lois de la police, tout citoyen y est protégé par asile juridique. De ce fait, tout policier mettant une personne étant dans le tribunal en prison encourt une peine maximale de 24h de prison et 1 500$ d'amende." }
};
char g_szAcquittement[3][32] = { "Non coupable", "Conciliation", "Impossible de prouver les faits"};
char g_szCondamnation[5][32] = { "très indulgent", "indulgent", "juste", "sévère", "très sévère" };
float g_flCondamnation[5] = {0.2, 0.4, 0.6, 0.8, 1.0};

int g_iArticles[3][28];
int g_iTribunalData[3][td_Max];

#define TRIBUJAIL_1 287
#define TRIBUJAIL_2 288
#define TRIBUNAL_1 289
#define TRIBUNAL_2 290

#define isTribunalDisponible(%1) (g_iTribunalData[%1][td_Owner]<=0?true:false)
#define GetTribunalZone(%1) (%1==1?TRIBUNAL_1:TRIBUNAL_2)
#define GetTribunalJail(%1) (%1==1?TRIBUJAIL_1:TRIBUJAIL_2)
#define GetTribunalType(%1) ((%1 == TRIBUNAL_1 || %1 == TRIBUJAIL_1) ? 1 : (%1 == TRIBUNAL_2 || %1 == TRIBUJAIL_2) ? 2 : 0)

public void OnPluginStart() {
	
	RegServerCmd("rp_item_enquete",		Cmd_ItemEnquete,		"RP-ITEM",	FCVAR_UNREGISTERED);
	CreateTimer(1.0, Timer_Light, _, TIMER_REPEAT);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}

public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
	
	if( !isTribunalDisponible(1) )
		rp_HookEvent(client, RP_OnPlayerHUD, fwdHUD);
	// Doublon volontaire. Ne pas toucher.
	if( !isTribunalDisponible(2) )
		rp_HookEvent(client, RP_OnPlayerHUD, fwdHUD);
}
public Action Timer_Light(Handle timer, any none) {
	
	TE_SetupBeamPoints(view_as<float>({308.0, -1530.0, -1870.0}), view_as<float>({200.0, -1530.0, -1870.0}), g_cBeam, g_cBeam, 0, 0, 1.1, 4.0, 4.0, 0, 0.0, tribunalColor(2), 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(view_as<float>({-508.0, -818.0, -1870.0}), view_as<float>({-508.0, -712.0, -1870.0}), g_cBeam, g_cBeam, 0, 0, 1.1, 4.0, 4.0, 0, 0.0, tribunalColor(1), 0);
	TE_SendToAll();
}
// ----------------------------------------------------------------------------
public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrContains(command, "tb2") == 0 ) {
		return Draw_Menu(client);
	}
	return Plugin_Continue;
}
Action Draw_Menu(int client) {
	
	int type = GetTribunalType(rp_GetPlayerZone(client));
	
	if( type == 0 )
		return Plugin_Stop;
	if( rp_GetClientJobID(client) != 101 )
		return Plugin_Stop;
	
	
	if( isTribunalDisponible(type) ) {
		
		Menu menu = new Menu(MenuTribunal);
		menu.SetTitle("Tribunal de Princeton\n ");
		menu.AddItem("start -1", "Débuter une audience");
		menu.AddItem("mariage", "Marier des joueurs");
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else {
		
		char title[512];
		Menu menu = new Menu(MenuTribunal);
		g_iTribunalData[type][td_Dedommagement] = calculerDedo(type);
		
		fwdHUD(client, title, sizeof(title));		
		menu.SetTitle(title);
		
		int admin = (g_iTribunalData[type][td_Owner] == client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
		bool injail = rp_GetPlayerZone(g_iTribunalData[type][td_Suspect]) == GetTribunalJail(type);
		
		
		if( admin == ITEMDRAW_DEFAULT ) {
						
			menu.AddItem("articles", "Gestion des articles");
			menu.AddItem("avocat", "Gestion des avocats");
			menu.AddItem("enquete", "Enquêter", (injail) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			
			menu.AddItem("condamner -1", "Condamner", (injail) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
			menu.AddItem("dedomager -1", "Dédommager", (injail && (g_iTribunalData[type][td_AvocatPlaignant] > 0 || g_iTribunalData[type][td_AvocatSuspect] > 0)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
			menu.AddItem("acquitter -1", "Acquitter", (injail) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
			menu.AddItem("stop", "Annuler l'audience", (!injail) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			
		}
		menu.Display(client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
Menu AUDIENCE_Start(int client, int type, int plaignant, int suspect) {
	Menu subMenu = null;
	char tmp[64], tmp2[64];
	
	if( plaignant <= 0 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Qui est le plaignant?\n ");
		
		for (int i = 1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			//if( i == client )
			//	continue;
			if( GetTribunalZone(type) != rp_GetPlayerZone(i) )
				continue;
			
			Format(tmp, sizeof(tmp), "start %d", i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			
			subMenu.AddItem(tmp, tmp2);
		}
	}
	else if( suspect <= 0 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Qui est le suspect?\n ");
		
		for (int i = 1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
/*			if( i == client )
				continue;
			if( i == plaignant )
				continue;
*/			
			Format(tmp, sizeof(tmp), "start %d %d", plaignant, i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			
			subMenu.AddItem(tmp, tmp2);
		}
	}
	else if( g_iTribunalData[type][td_Owner] <= 0 ) {
		g_iTribunalData[type][td_Suspect] = suspect;
		g_iTribunalData[type][td_Plaignant] = plaignant;		
		g_iTribunalData[type][td_Owner] = client;
		
		CreateTimer(1.0, Timer_AUDIENCE, type, TIMER_REPEAT);
		
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			rp_HookEvent(i, RP_OnPlayerHUD, fwdHUD);
		}
	}
	
	return subMenu;
}
Menu AUDIENCE_Stop(int type) {
	
	for (int i = 0; i < view_as<int>(td_Max); i++)
		g_iTribunalData[type][i] = 0;
	
	for (int i = 0; i < sizeof(g_szArticles[]); i++)
		g_iArticles[type][i] = 0;
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		rp_UnhookEvent(i, RP_OnPlayerHUD, fwdHUD);
	}
	return null;
}
Menu AUDIENCE_Articles(int type, int a, int b) {
	Menu subMenu = null;
	char tmp[64];
	
	if( a == 0 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Gestion des articles \n ");
		subMenu.AddItem("articles 1 -1", "Ajouter un article", getMaxArticles(g_iTribunalData[type][td_Owner]) > g_iTribunalData[type][td_ArticlesCount] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
		subMenu.AddItem("articles 2 -1", "Retirer un article", g_iTribunalData[type][td_ArticlesCount] > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
		
	}
	else if( a == 1 && b == -1 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Liste des articles\n ");
		for (int i = 0; i < sizeof(g_szArticles); i++) {
			Format(tmp, sizeof(tmp), "articles 1 %d", i);
			
			subMenu.AddItem(tmp, g_szArticles[i][1]);
		}
	}
	else if( a == 2 && b == -1 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Liste des articles\n ");
		for (int i = 0; i < sizeof(g_szArticles); i++) {
			if( g_iArticles[type][i] <= 0 )
				continue;
			Format(tmp, sizeof(tmp), "articles 2 %d", i);
			
			subMenu.AddItem(tmp, g_szArticles[i][1]);
		}
	}
	else if( a == 1 && b >= 0 ) {
		g_iArticles[type][b]++;
		g_iTribunalData[type][td_ArticlesCount]++;
	}
	else if( a == 2 && b >= 0 ) {
		g_iArticles[type][b]--;
		g_iTribunalData[type][td_ArticlesCount]--;
	}
	
	return subMenu;
}
Menu AUDIENCE_Condamner(int type, int articles) {
	Menu subMenu = null;
	char tmp[64];
	if( articles == -1 ) {
		int severity = timeToSeverity(g_iTribunalData[type][td_Time]);
		
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Quel est votre verdicte?\n ");
		for (int i = 0; i < sizeof(g_szCondamnation); i++) {
			Format(tmp, sizeof(tmp), "condamner %d", i);
			
			subMenu.AddItem(tmp, g_szCondamnation[i], (i>=severity-1&&i<=severity+1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
		}
	}
	else {
		
		int heure, amende, target;
		calculerJail(type, heure, amende);
		
		heure = RoundFloat(float(heure) * g_flCondamnation[articles]);
		amende = RoundFloat(float(amende) * g_flCondamnation[articles]);
		target = g_iTribunalData[type][td_Suspect];
		
		SQL_Insert(type, true, articles, heure, amende);
		PrintToChatSearch(GetTribunalZone(type), target, "{lightblue}[TSX-RP]{default} %N a été condamné à %d heures et %d$ d'amende. Le juge a été %s.", target, heure, amende, g_szCondamnation[articles]);
		
		AUDIENCE_Stop(type);
	}
	
	return subMenu;
}
Menu AUDIENCE_Acquitter(int type, int articles) {
	Menu subMenu = null;
	char tmp[64];
	if( articles == -1 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Pour quel raison doit-il être acquitté?\n ");
		for (int i = 0; i < sizeof(g_szAcquittement); i++) {
			Format(tmp, sizeof(tmp), "acquitter %d", i);
			
			subMenu.AddItem(tmp, g_szAcquittement[i]);
		}
	}
	else {
		PrintToChatSearch(GetTribunalZone(type), g_iTribunalData[type][td_Suspect], "{lightblue}[TSX-RP]{default} %N a été acquitté: %s.", g_iTribunalData[type][td_Suspect], g_szAcquittement[articles]);
		AUDIENCE_Stop(type);
	}
	
	return subMenu;
}
Menu AUDIENCE_Avocat(int type, int a, int b) {
	Menu subMenu = null;
	char tmp[64], tmp2[64];
	
	if( a == 0 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Quel type d'avocat gérer?\n ");
		subMenu.AddItem("avocat 1 -1", "Avocat de la victime");
		subMenu.AddItem("avocat 2 -1", "Avocat de la défense");
	}
	else if( b == -1 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Qui mettre comme avocat?\n ");
		Format(tmp, sizeof(tmp), "avocat %d 0", a);
		subMenu.AddItem(tmp, "Personne");
		
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( rp_GetClientInt(i, i_Avocat) <= 0 )
				continue;
			if( g_iTribunalData[type][td_Plaignant] == i )
				continue;
			if( g_iTribunalData[type][td_Suspect] == i )
				continue;
			if( g_iTribunalData[type][td_AvocatPlaignant] == i )
				continue;
			if( g_iTribunalData[type][td_AvocatSuspect] == i )
				continue;
			
			Format(tmp, sizeof(tmp), "avocat %d %d", a, i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			subMenu.AddItem(tmp, tmp2);
		}
	}
	else {
		g_iTribunalData[type][a == 1 ? td_AvocatPlaignant : td_AvocatSuspect] = b;
	}
	
	return subMenu;
}
Menu AUDIENCE_Dedommage(int type) {
	
	if( g_iTribunalData[type][td_DoneDedommagement] == 0 ) {
	}
	
	return null;
	
}
Menu AUDIENCE_Enquete(int type, int a, int b) {
	Menu subMenu = null;
	char tmp[64], tmp2[64];
	
	if( a == 0 ) {
		
		if( g_iTribunalData[type][td_TimeMercenaire] == 0 && !hasMercenaire() )
			g_iTribunalData[type][td_TimeMercenaire] = 60;
		
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Enquêter\n ");
		subMenu.AddItem("enquete 1", "Convoquer les mercenaires", g_iTribunalData[type][td_TimeMercenaire] < 60 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		subMenu.AddItem("enquete 2", "Enquêter sans mercenaire", g_iTribunalData[type][td_TimeMercenaire] >= 60 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		subMenu.AddItem("enquete 3", "Enquêter dans les logs", (g_iTribunalData[type][td_EnquetePlaignant] + g_iTribunalData[type][td_EnqueteSuspect]) >= 2 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
		
	}
	else if( a == 1 ) {
		if( g_iTribunalData[type][td_TimeMercenaire] < 60 ) {
			CreateTimer(1.0, Timer_MERCENAIRE, type, TIMER_REPEAT);
		}
	}
	else if( a == 2 ) {
		if( b > 0 ) {
			ServerCommand("rp_item_enquete \"%i\" \"%i\"", g_iTribunalData[type][td_Owner], b);
			
			if( b == g_iTribunalData[type][td_Plaignant] )
				g_iTribunalData[type][td_EnquetePlaignant] = 1;
			if( b == g_iTribunalData[type][td_Suspect] )
				g_iTribunalData[type][td_EnqueteSuspect] = 1;			
		}
		else {
			subMenu = new Menu(MenuTribunal);
			subMenu.SetTitle("Enquêter\n ");
			
			int zone;
			int tribu = GetTribunalZone(type);
			int jail = GetTribunalJail(type);
			
			
			for (int i = 1; i <= MaxClients; i++) {
				if( !IsValidClient(i) )
					continue;
				zone = rp_GetPlayerZone(i);
				if( zone == tribu || zone == jail ) {
					Format(tmp, sizeof(tmp), "enquete 2 %d", i);
					Format(tmp2, sizeof(tmp2), "%N", i);
					subMenu.AddItem(tmp, tmp2);
				}
			}
		}
	}
	
	return subMenu;
}
// ----------------------------------------------------------------------------
public int MenuTribunal(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64], expl[4][32];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		ExplodeString(options, " ", expl, sizeof(expl), sizeof(expl[]));
		int a = StringToInt(expl[1]);
		int b = StringToInt(expl[2]);
		
		int type = GetTribunalType(rp_GetPlayerZone(client));
		Menu subMenu = null;
		bool subCommand = false;
		
		if( StrEqual(expl[0], "start") )
			subMenu = AUDIENCE_Start(client, type, a, b);
		else if( StrEqual(expl[0], "stop") )
			subMenu = AUDIENCE_Stop(type);
		else if( StrEqual(expl[0], "articles") )
			subMenu = AUDIENCE_Articles(type, a, b);
		else if( StrEqual(expl[0], "acquitter") )
			subMenu = AUDIENCE_Acquitter(type, a);
		else if( StrEqual(expl[0], "condamner") )
			subMenu = AUDIENCE_Condamner(type, a);
		else if( StrEqual(expl[0], "avocat") )
			subMenu = AUDIENCE_Avocat(type, a, b);
		else if( StrEqual(expl[0], "enquete") )
			subMenu = AUDIENCE_Enquete(type, a, b);
		else if( StrEqual(expl[0], "dedomager") )
			subMenu = AUDIENCE_Dedommage(type);
		else
			subCommand = true;
		
		if( subCommand )
			FakeClientCommand(client, "say /%s", expl[0]);
		else if( subMenu == null )
			Draw_Menu(client);
		else
			subMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return 0;
}
public Action Timer_MERCENAIRE(Handle timer, any type) {
	if( g_iTribunalData[type][td_TimeMercenaire] > 60 )
		return Plugin_Stop;
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetClientJobID(i) == 41 ) {
			if( rp_GetPlayerZone(i) == GetTribunalZone(type) )
				return Plugin_Stop;
			
			PrintHintText(i, "Vos services d'enquêteur sont recquis au Tribunal %d.", type);
		}
	}
	
	g_iTribunalData[type][td_TimeMercenaire]++;
	return Plugin_Continue;
}
public Action Timer_AUDIENCE(Handle timer, any type) {
	
	int target = g_iTribunalData[type][td_Suspect];
	int time = g_iTribunalData[type][td_Time];
	int zone = rp_GetPlayerZone(target);
	int tzone = GetTribunalZone(type);
	int jail = GetTribunalJail(type);
	
	if( !IsValidClient(target) ) {
		AUDIENCE_Stop(type);
		return Plugin_Stop;
	}
	
	if( g_iTribunalData[type][td_ArticlesCount] == 0 ) {
		PrintHintText(g_iTribunalData[type][td_Owner], "La convocation commencera dés que vous aurez ajouter le premier article.");
		return Plugin_Continue;
	}
		
	if( time < 60 && time % 20 == 0 )
		PrintToChatSearch(tzone, target, "{lightblue}[TSX-RP]{default} %N est convoqué par le {green}Tribunal %d{default} de Princeton [%d/3].", target, type, time/20 + 1);
	else if( time % 60 == 0 )
		PrintToChatSearch(tzone, target, "{lightblue}[TSX-RP]{default} %N est recherché par le {green}Tribunal %d{default} de Princeton depuis %d minutes.", target, type, time/60);
	
	if( zone == jail ) {
		PrintToChatSearch(tzone, target, "{lightblue}[TSX-RP]{default} %N est arrivé après %d minutes.", target, time/60);
		Draw_Menu(g_iTribunalData[type][td_Owner]);
		return Plugin_Stop;
	}
	
	float mid[3];
	mid = getZoneMiddle(jail);
	
	ServerCommand("sm_effect_gps %d %f %f %f", target, mid[0], mid[1], mid[2]);
	PrintHintText(target, "Vous êtes attendu au tribunal %d de Princeton. Venez <u>immédiatement</u> pour un jugement <font color='#00cc00'>%s</font>.", type, g_szCondamnation[timeToSeverity(time)]);
	
	g_iTribunalData[type][td_Time]++;
	return Plugin_Continue;
}
public Action fwdHUD(int client, char[] szHUD, const int size) {
	int type = GetTribunalType( rp_GetPlayerZone(client) );
	
	if( type > 0 && !isTribunalDisponible(type) ) {
		int heure, amende;
		Format(szHUD, size, "Tribunal de Princeton, affaire opposant\n%N   et   %N\nJuge: %N", g_iTribunalData[type][td_Plaignant], g_iTribunalData[type][td_Suspect], g_iTribunalData[type][td_Owner]);
		
		if( g_iTribunalData[type][td_AvocatPlaignant] ) {
			Format(szHUD, size, "%s\nAvocat de la victime: %N", szHUD, g_iTribunalData[type][td_AvocatPlaignant]);
		}
		if( g_iTribunalData[type][td_AvocatSuspect] ) {
			Format(szHUD, size, "%s\nAvocat de la défense: %N", szHUD, g_iTribunalData[type][td_AvocatSuspect]);
		}
		
		Format(szHUD, size, "%s\n ", szHUD);
		
		if( g_iTribunalData[type][td_ArticlesCount] > 0 ) {
			Format(szHUD, size, "%s\n \nCharges:\n ", szHUD);
			for (int i = 0; i < sizeof(g_szArticles); i++) {
				if( g_iArticles[type][i] <= 0 )
					continue;
				
				Format(szHUD, size, "%s %2dx   %s\n ", szHUD, g_iArticles[type][i], g_szArticles[i][1]);
				
				heure += (g_iArticles[type][i] * StringToInt(g_szArticles[i][2]));
				amende += (g_iArticles[type][i] * StringToInt(g_szArticles[i][3]));
			}
			Format(szHUD, size, "%s\nPeine encourue: %d heures %d$ d'amendes", szHUD, heure, amende);
			if( g_iTribunalData[type][td_Dedommagement] > 0 )
				Format(szHUD, size, "%s\nDédommagement possible: %d$", szHUD, g_iTribunalData[type][td_Dedommagement]);
		}
		else {
			Format(szHUD, size, "%s\nEn attente d'un article pour débuter l'audience", szHUD, heure, amende);
		}
		
		Format(szHUD, size, "%s\n ", szHUD);
		return Plugin_Changed;
	}
	else if( rp_GetClientInt(client, i_Avocat) ) {
		for (int i = 1; i <= 2; i++) {
			if( g_iTribunalData[i][td_AvocatPlaignant] == client || g_iTribunalData[i][td_AvocatSuspect] == client )
				PrintHintText(client, "Vos services d'avocat sont recquis au Tribunal %d", i);
		}
	}
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
int[] tribunalColor(int type) {
	int color[4];
	color[3] = 128;
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		if( rp_GetClientJobID(i) == 101 && !rp_GetClientBool(i, b_IsAFK) ) {
			if( type == 1 && rp_GetPlayerZone(i) == TRIBUNAL_1 )
				color[1] = 255;
			else if( type == 2 && rp_GetPlayerZone(i) == TRIBUNAL_2 )
				color[1] = 255;
		}
	}
	if( color[1] == 0 ) {
		color[0] = 255;
		color[1] = 255;
	}
	
	if( !isTribunalDisponible(type) ) {
		color[0] = 255;
		color[1] = 0;
	}
	
	return color;
}
stock void PrintToChatSearch(int zone, int target, const char[] message, any...) {
	char buffer[MAX_MESSAGE_LENGTH];
	VFormat(buffer, sizeof(buffer), message, 4);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i))
			continue;
		
		if (i == target || rp_GetPlayerZone(i) == zone ) {
			CPrintToChat(i, buffer);
		}
	}
}
float[] getZoneMiddle(int zone) {
	float middle[3];
	middle[0] = (rp_GetZoneFloat(zone, zone_type_min_x) + rp_GetZoneFloat(zone, zone_type_max_x)) / 2.0;
	middle[1] = (rp_GetZoneFloat(zone, zone_type_min_y) + rp_GetZoneFloat(zone, zone_type_max_y)) / 2.0;
	middle[2] = (rp_GetZoneFloat(zone, zone_type_min_z) + rp_GetZoneFloat(zone, zone_type_max_z)) / 2.0;
	return middle;
}
int timeToSeverity(int time) {
	if( time < (1*60) )	return 0;
	if( time < (4*60) )	return 1;
	if( time < (8*60) )	return 2;
	if( time < (12*60))	return 3;
	return 4;
}
int getMaxArticles(int client) {
	int job = rp_GetClientInt(client, i_Job);
	switch (job) {
		case 101: return 20;
		case 102: return 15;
		case 103: return 10;
		case 104: return 8;
		case 105: return 5;
		case 106: return 3;		
	}
	return 0;
}
void SQL_Insert(int type, int avoue, int condamnation, int heure, int amende) {
	char query[1024], szSteamID[5][32], charges[128];
	
	for (int i = 0; i < sizeof(g_szArticles); i++) {
		if( g_iArticles[type][i] <= 0 )
			continue;
		
		Format(charges, sizeof(charges), "%s%dX %s, ", charges, g_iArticles[type][i], g_szArticles[i][0]);
	}
	
	charges[strlen(charges) - 2] = 0;
	
	
	GetClientAuthId(g_iTribunalData[type][td_Owner], AuthId_Engine, szSteamID[0], sizeof(szSteamID[]));
	GetClientAuthId(g_iTribunalData[type][td_Plaignant], AuthId_Engine, szSteamID[1], sizeof(szSteamID[]));
	GetClientAuthId(g_iTribunalData[type][td_Suspect], AuthId_Engine, szSteamID[2], sizeof(szSteamID[]));
	
	if( IsValidClient(g_iTribunalData[type][td_AvocatPlaignant]) )
		GetClientAuthId(g_iTribunalData[type][td_AvocatPlaignant], AuthId_Engine, szSteamID[3], sizeof(szSteamID[]));
	if( IsValidClient(g_iTribunalData[type][td_AvocatSuspect]) )
		GetClientAuthId(g_iTribunalData[type][td_AvocatSuspect], AuthId_Engine, szSteamID[4], sizeof(szSteamID[]));
	
	Format(query, sizeof(query), "INSERT INTO `rp_audiences` (`id`, `juge`, `plaignant`, `suspect`, `avocat-plaignant`, `avocat-suspect`, `temps`, `avoue`, `charges`, `condamnation`, `heure`, `amende`) VALUES(NULL,");
	Format(query, sizeof(query), "%s '%s', '%s', '%s', '%s', '%s', '%d', '%d', '%s', '%d', '%d', '%d');", query, szSteamID[0], szSteamID[1], szSteamID[2], szSteamID[3], szSteamID[4],
	g_iTribunalData[type][td_Time], avoue, charges, condamnation, heure, amende);
	
	
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
}
bool hasMercenaire() {
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetClientJobID(i) == 41 )
			return true;
	}
	return false;
}
int calculerDedo(int type) {
	if( g_iTribunalData[type][td_AvocatPlaignant] == 0 )
		return 0;
	
	int amende;
	for (int i = 0; i < sizeof(g_szArticles); i++) {
		if( g_iArticles[type][i] <= 0 )
			continue;
		
		amende += (g_iArticles[type][i] * StringToInt(g_szArticles[i][4]));
	}
	return RoundFloat(float(amende) * getAvocatRatio(g_iTribunalData[type][td_AvocatPlaignant]));
}
void calculerJail(int type, int& heure, int& amende) {
	for (int i = 0; i < sizeof(g_szArticles); i++) {
		if( g_iArticles[type][i] <= 0 )
			continue;
		heure += (g_iArticles[type][i] * StringToInt(g_szArticles[i][2]));
		amende += (g_iArticles[type][i] * StringToInt(g_szArticles[i][3]));
	}
}
float getAvocatRatio(int client) {
	int pay = rp_GetClientInt(client, i_Avocat);
	if (pay <= 0)	return 0.0;
	if (pay < 175)	return 0.5;
	if (pay < 300)	return 0.75;
	return 1.0;
	
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemEnquete(int args) {
	
	int client = GetCmdArgInt(1);
	int target = GetCmdArgInt(2);
	char tmp[255];
	
	if( rp_GetClientJobID(client) == 101 ) {
		int type = GetTribunalType( rp_GetPlayerZone(client) );
		if( type > 0 ) {
			if( target == g_iTribunalData[type][td_Plaignant] )
				g_iTribunalData[type][td_EnquetePlaignant] = 1;
			if( target == g_iTribunalData[type][td_Suspect] )
				g_iTribunalData[type][td_EnqueteSuspect] = 1;
		}
	}
	
	
	rp_IncrementSuccess(client, success_list_detective);
	Handle menu = CreateMenu(MenuNothing);
	SetMenuTitle(menu, "Information sur %N\n ", target);
	
	PrintToConsole(client, "\n\n\n\n\n -------------------------------------------------------------------------------------------- ");
	
	rp_GetZoneData(rp_GetPlayerZone(target), zone_type_name, tmp, sizeof(tmp));
	
	AddMenu_Blank(client, menu, "Localisation: %s", tmp);	
	
	int killedBy = rp_GetClientInt(target, i_LastKilled_Reverse);
	if( IsValidClient(killedBy) ) {
		if( Math_GetRandomInt(1, 100) < rp_GetClientInt(target, i_Cryptage)*20 ) {
			
			String_GetRandom(tmp, sizeof(tmp), 24);
			
			AddMenu_Blank(client, menu, "Il a tué: %s", tmp);
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} Votre pot de vin envers un mercenaire vient de vous sauver.");
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L n'a pas montré qui l'a tué pour cause de pot de vin.", target);
		}
		else {	
			AddMenu_Blank(client, menu, "Il a tué: %N", killedBy);
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a montré qu'il a tué %L.", target, killedBy);
		}
	}
	else{
		LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a révélé qu'il n'a tué personne", target, killedBy);
	}
	
	if( rp_GetClientInt(target, i_KillingSpread) > 0 )
		AddMenu_Blank(client, menu, "Meurtre consécutif: %i", rp_GetClientInt(target, i_KillingSpread) );
	
	int killed = rp_GetClientInt(target, i_LastKilled);
	if( IsValidClient(killed) ) {
		
		if( Math_GetRandomInt(1, 100) < rp_GetClientInt(killed, i_Cryptage)*20 ) {	
			
			String_GetRandom(tmp, sizeof(tmp), 24);
			
			AddMenu_Blank(client, menu, "%s, l'a tué", tmp);
			CPrintToChat(killed, "{lightblue}[TSX-RP]{default} Votre pot de vin envers un mercenaire vient de vous sauver.");
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L n'a pas montré qui l'a tué pour cause de pot de vin.", target);
		}
		else {
			AddMenu_Blank(client, menu, "%N, l'a tué", killed);
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a montré que %L l'a tué.", target, killed);
		}
	}
	else{
		LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a révélé qu'il n'a été tué par personne.", target, killed);
	}
	
	if( IsValidClient(rp_GetClientInt(target, i_LastVol)) ) 
		AddMenu_Blank(client, menu, "%N, l'a volé", rp_GetClientInt(target, i_LastVol) );
	
	AddMenu_Blank(client, menu, "--------------------------------");
	
	AddMenu_Blank(client, menu, "Niveau d'entraînement: %i", rp_GetClientInt(target, i_KnifeTrain));
	AddMenu_Blank(client, menu, "Précision de tir: %.2f", rp_GetClientFloat(target, fl_WeaponTrain));
	
	int count=0;
	Format(tmp, sizeof(tmp), "Permis possédé:");
	
	if( rp_GetClientBool(target, b_License1) ) {	Format(tmp, sizeof(tmp), "%s léger", tmp);	count++;	}
	if( rp_GetClientBool(target, b_License2) ) {	Format(tmp, sizeof(tmp), "%s lourd", tmp);	count++;	}
	if( rp_GetClientBool(target, b_LicenseSell) ) {	Format(tmp, sizeof(tmp), "%s vente", tmp);	count++;	}
	
	if( count == 0 ) {
		Format(tmp, sizeof(tmp), "%s Aucun", tmp);
	}
	AddMenu_Blank(client, menu, "%s.", tmp);
	
	AddMenu_Blank(client, menu, "Argent: %i$ - Banque: %i$", rp_GetClientInt(target, i_Money), rp_GetClientInt(target, i_Bank));
	
	count = 0;
	Format(tmp, sizeof(tmp), "Appartement possédé: ");
	for (int i = 1; i <= 100; i++) {
		if( rp_GetClientKeyAppartement(target, i) ) {
			count++;
			if( count > 1 )
				Format(tmp, sizeof(tmp), "%s, ", tmp);
			Format(tmp, sizeof(tmp), "%s%d", tmp, i);
		}	
	}
	
	if( count == 0 )
		Format(tmp, sizeof(tmp), "%s Aucun", tmp);
	
	AddMenu_Blank(client, menu, tmp);
	
	AddMenu_Blank(client, menu, "Taux d'alcoolémie: %.3f", rp_GetClientFloat(client, fl_Alcool));
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ces informations ont été envoyées dans votre console.");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
}
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	
	if( action == MenuAction_Select ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}
// ----------------------------------------------------------------------------
void AddMenu_Blank(int client, Handle menu, const char[] myString , any ...) {
	char[] str = new char[ strlen(myString)+255 ];
	VFormat(str, (strlen(myString)+255), myString, 4);
	
	AddMenuItem(menu, "none", str, ITEMDRAW_DISABLED);
	PrintToConsole(client, str);
}
