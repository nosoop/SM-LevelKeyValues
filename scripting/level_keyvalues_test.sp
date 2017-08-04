/**
 * Sourcemod 1.7 Plugin Template
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdktools>

#pragma newdecls required
#include <level_keyvalues>


#define OUTPUT_NAME "OnCapTeam1"

public void OnMapStart() {
	int captureArea = FindEntityByClassname(-1, "trigger_capture_area");
	
	if (captureArea != -1) {
		LogMessage("---- %s", "Found a trigger_capture_area with keys:");
		
		KeyValues entityKeys = LevelEntity_GetKeysByEntity(captureArea);
		
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
		
		LogMessage("---- %s", "List of " ... OUTPUT_NAME ... " outputs:");
		
		LevelEntityOutputIterator captureOutputEvents =
				LevelEntityOutputIterator.FromEntity(captureArea, OUTPUT_NAME);
		
		char targetName[32], inputName[64], variantValue[32];
		float delay;
		int nFireCount;
		
		while (captureOutputEvents.Next(targetName, sizeof(targetName), inputName,
				sizeof(inputName), variantValue, sizeof(variantValue), delay, nFireCount)) {
			LogMessage("target %s -> input %s (value %s, delay %.2f, refire %d)",
					targetName, inputName, variantValue, delay, nFireCount);
		}
		delete captureOutputEvents;
	}
}
