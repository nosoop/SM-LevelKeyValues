/**
 * [ANY?] Level KeyValues
 * 
 * Parses the level entity string (from SDKHooks' `OnLevelInit` forward) into a KeyValues
 * handle, indexed by Hammer ID.
 */
#pragma semicolon 1
#pragma dynamic 1048576
#include <sourcemod>

#include <sdkhooks>
#include <regex>

#include <more_adt>

#include <profiler>

#include "level_keyvalues/map_string_natives.sp"

#pragma newdecls required

#define PLUGIN_VERSION "0.3.0-perf-diagnostics-r02"
public Plugin myinfo = {
	name = "Level KeyValues",
	author = "nosoop",
	description = "Parses the map entity string into a KeyValues structure.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-LevelKeyValues/"
}

ArrayList g_MapEntities;
bool g_bMutableList;

Handle g_OnEntityKeysParsed, g_OnAllEntitiesParsed;

char g_DiagnosticFile[PLATFORM_MAX_PATH];

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int err_max) {
	RegPluginLibrary("level-keyvalues");
	
	CreateNative("LevelEntity_GetKeysByHammerID", Native_GetKeysByHammerID);
	CreateNative("LevelEntity_InsertEntityKeys", Native_InsertEntity);
	
	CreateNative("LevelEntityKeyValues.GetNum", Native_MapGetNum);
	CreateNative("LevelEntityKeyValues.AddNum", Native_MapAddNum);
	
	CreateNative("LevelEntityKeyValues.GetFloat", Native_MapGetFloat);
	CreateNative("LevelEntityKeyValues.AddFloat", Native_MapAddFloat);
	
	CreateNative("LevelEntityKeyValues.GetVector", Native_MapGetVector);
	CreateNative("LevelEntityKeyValues.AddVector", Native_MapAddVector);
	
	CreateNative("LevelEntityKeyValuesIterator.GetNum", Native_MapIterGetNum);
	CreateNative("LevelEntityKeyValuesIterator.SetNum", Native_MapIterSetNum);
	
	CreateNative("LevelEntityKeyValuesIterator.GetFloat", Native_MapIterGetFloat);
	CreateNative("LevelEntityKeyValuesIterator.SetFloat", Native_MapIterSetFloat);
	
	CreateNative("LevelEntityKeyValuesIterator.GetVector", Native_MapIterGetVector);
	CreateNative("LevelEntityKeyValuesIterator.SetVector", Native_MapIterSetVector);
	
	CreateNative("LevelEntityList.Get", Native_LevelListGet);
	CreateNative("LevelEntityList.Push", Native_InsertEntity);
	CreateNative("LevelEntityList.Erase", Native_LevelListErase);
	CreateNative("LevelEntityList.Length", Native_LevelListGetLength);
	
	return APLRes_Success;
}

public void OnPluginStart() {
	g_OnEntityKeysParsed = CreateGlobalForward("LevelEntity_OnEntityKeysParsed", ET_Hook,
			Param_Cell);
	g_OnAllEntitiesParsed = CreateGlobalForward("LevelEntity_OnAllEntitiesParsed", ET_Ignore);
	
	BuildPath(Path_SM, g_DiagnosticFile, sizeof(g_DiagnosticFile), "logs/levelkeyvalues_stats.txt");
	LogToFile(g_DiagnosticFile, "Plugin loaded.");
}

public Action OnLevelInit(const char[] mapName, char mapEntities[2097152]) {
	Handle prof = CreateProfiler();
	if (g_MapEntities) {
		StartProfiling(prof);
		while (g_MapEntities.Length) {
			StringMultiMap handle = g_MapEntities.Get(0);
			delete handle;
			g_MapEntities.Erase(0);
		}
		delete g_MapEntities;
		StopProfiling(prof);
		LogToFile(g_DiagnosticFile, "Cleanup of level entity list for previous map took %f seconds", GetProfilerTime(prof));
	}
	
	StartProfiling(prof);
	g_MapEntities = ParseEntityList(mapEntities);
	StopProfiling(prof);
	
	LogToFile(g_DiagnosticFile, "Entity parsing on %s took %f seconds (%d in list)", mapName, GetProfilerTime(prof), g_MapEntities.Length);
	
	StartProfiling(prof);
	g_bMutableList = true;
	Call_StartForward(g_OnAllEntitiesParsed);
	Call_Finish();
	g_bMutableList = false;
	StopProfiling(prof);
	LogToFile(g_DiagnosticFile, "Post-entity parse forward on %s took %f seconds", mapName, GetProfilerTime(prof));
	
	delete prof;
	
	mapEntities = "";
	WriteEntityList(g_MapEntities, mapEntities, sizeof(mapEntities));
	
	return Plugin_Changed;
}

public int Native_GetKeysByHammerID(Handle plugin, int argc) {
	// native KeyValues LevelEntity_GetKeysByHammerID(int iHammerID);
	int iHammerID = GetNativeCell(1);
	for (int i = 0; i < g_MapEntities.Length; i++) {
		StringMultiMap entityKeys = g_MapEntities.Get(i);
		char hid[16];
		if (entityKeys.GetString("hammerid", hid, sizeof(hid))) {
			if (StringToInt(hid) == iHammerID) {
				return view_as<int>(CloneHandle(entityKeys, plugin));
			}
		}
	}
	
	return 0;
}

public int Native_LevelListGet(Handle plugin, int argc) {
	return view_as<int>(CloneHandle(g_MapEntities.Get(GetNativeCell(1))));
}

public int Native_LevelListErase(Handle plugin, int argc) {
	if (!g_bMutableList) {
		ThrowNativeError(1, "Can't remove entities from list during non-mutable state.");
	}
	g_MapEntities.Erase(GetNativeCell(1));
	return 0;
}

public int Native_InsertEntity(Handle plugin, int argc) {
	if (!g_bMutableList) {
		ThrowNativeError(1, "Can't push new entity into list during non-mutable state.");
	}
	StringMultiMap entity = GetNativeCell(1);
	return g_MapEntities.Push(CloneStringMultiMap(entity));
}

public int Native_LevelListGetLength(Handle plugin, int argc) {
	return g_MapEntities.Length;
}

StringMultiMap CloneStringMultiMap(StringMultiMap source) {
	char key[256], value[256];
	StringMultiMapIterator iter = source.GetIterator();
	
	StringMultiMap output = new StringMultiMap();
	while (iter.Next()) {
		iter.GetKey(key, sizeof(key));
		if (iter.GetString(value, sizeof(value))) {
			output.AddString(key, value);
		}
	}
	return output;
}

/**
 * Parses the level entity string into an ArrayList of StringMultiMap handles.
 */
static ArrayList ParseEntityList(const char mapEntities[2097152]) {
	static Regex s_KeyValueLine;
	
	if (!s_KeyValueLine) {
		// Pattern copied from alliedmodders/stripper-source/master/parser.cpp
		s_KeyValueLine = new Regex("\"([^\"]+)\"\\s+\"([^\"]+)\"");
	}
	
	ArrayList mapEntityList = new ArrayList();
	
	char key[256], value[256];
	
	StringMultiMap currentEntityMap;
	
	int i, n;
	char lineBuffer[4096];
	while ((n = SplitString(mapEntities[i], "\n", lineBuffer, sizeof(lineBuffer))) != -1) {
		switch(lineBuffer[0]) {
			case '{': {
				currentEntityMap = new StringMultiMap();
			}
			case '}': {
				if (ForwardOnEntityKeysParsed(currentEntityMap) != Plugin_Stop) {
					mapEntityList.Push(currentEntityMap);
					currentEntityMap = null; // don't hold a reference that might be pushed later
				} else {
					delete currentEntityMap;
				}
				
				// next open bracket starts on same line
				if (lineBuffer[1] == '{') {
					currentEntityMap = new StringMultiMap();
				}
			}
			default: {
				if (s_KeyValueLine.Match(lineBuffer)) {
					s_KeyValueLine.GetSubString(1, key, sizeof(key));
					s_KeyValueLine.GetSubString(2, value, sizeof(value));
					
					currentEntityMap.AddString(key, value);
				}
			}
		}
		i += n;
	}
	
	if (currentEntityMap) {
		if (ForwardOnEntityKeysParsed(currentEntityMap) != Plugin_Stop) {
			mapEntityList.Push(currentEntityMap);
		} else {
			delete currentEntityMap;
		}
	}
	
	return mapEntityList;
}

Action ForwardOnEntityKeysParsed(StringMultiMap entity) {
	Action result;
	Call_StartForward(g_OnEntityKeysParsed);
	Call_PushCell(entity);
	Call_Finish(result);
	
	return result;
}

/**
 * Writes the entity list back out in level string format.
 */
void WriteEntityList(ArrayList entityList, char[] buffer, int maxlen) {
	for (int i = 0; i < entityList.Length; i++) {
		StrCat(buffer, maxlen, "{\n");
		
		StringMultiMapIterator keyiter = view_as<StringMultiMap>(entityList.Get(i)).GetIterator();
		while (keyiter.Next()) {
			char key[64], value[256];
			keyiter.GetKey(key, sizeof(key));
			keyiter.GetString(value, sizeof(value));
			
			char lineBuffer[512];
			Format(lineBuffer, sizeof(lineBuffer), "\"%s\" \"%s\"\n", key, value);
			StrCat(buffer, maxlen, lineBuffer);
		}
		delete keyiter;
		
		StrCat(buffer, maxlen, "}\n");
	}
}

/**
 * Converts a string to lower case.
 */
stock void StrToLower(char[] buffer) {
	int c;
	do {
		buffer[c] = CharToLower(buffer[c]);
	} while (buffer[++c]);
}
