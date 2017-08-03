/**
 * Sourcemod 1.7 Plugin Template
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdktools>

#pragma newdecls required
#include <level_keyvalues>

public void OnMapStart() {
	int logicAuto = FindEntityByClassname(-1, "team_control_point");
	
	if (logicAuto != -1) {
		LogMessage("%s", "Found a team_control_point with keys:");
		
		KeyValues entityKeys = LevelEntity_GetKeysByEntity(logicAuto);
		
		if (entityKeys) {
			char keyBuffer[128], valueBuffer[128];
			entityKeys.GotoFirstSubKey(false);
			do {
				entityKeys.GetSectionName(keyBuffer, sizeof(keyBuffer));
				entityKeys.GetString(NULL_STRING, valueBuffer, sizeof(valueBuffer));
				
				LogMessage("%s -> %s", keyBuffer, valueBuffer);
			} while (entityKeys.GotoNextKey(false));
			delete entityKeys;
		}
	}
}
