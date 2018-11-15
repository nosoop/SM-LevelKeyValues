/**
 * [TF2] Level KeyValues Sample Plugin
 * 
 * Sample plugin for Level KeyValues.
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
		
		LevelEntityKeyValues entityKeys = LevelEntity_GetKeysByEntity(captureArea);
		
		if (entityKeys) {
			char keyBuffer[128], valueBuffer[128];
			LevelEntityKeyValuesIterator iter = entityKeys.GetIterator();
			while (iter.Next()) {
				iter.GetKey(keyBuffer, sizeof(keyBuffer));
				iter.GetString(valueBuffer, sizeof(valueBuffer));
				
				LogMessage("%s -> %s", keyBuffer, valueBuffer);
			}
			delete iter;
		}
		
		LogMessage("---- %s", "List of " ... OUTPUT_NAME ... " outputs:");
		
		LevelEntityKeyValuesIterator outputIter = entityKeys.GetKeyIterator(OUTPUT_NAME);
		while (outputIter.Next()) {
			char outputString[256];
			outputIter.GetString(outputString, sizeof(outputString));
			
			char targetName[32], inputName[64], variantValue[32];
			float delay;
			int nFireCount;
			
			ParseEntityOutputString(outputString, targetName, sizeof(targetName),
					inputName, sizeof(inputName), variantValue, sizeof(variantValue),
					delay, nFireCount);
			
			LogMessage("target %s -> input %s (value %s, delay %.2f, refire %d)",
					targetName, inputName, variantValue, delay, nFireCount);
		}
		delete outputIter;
	}
}
