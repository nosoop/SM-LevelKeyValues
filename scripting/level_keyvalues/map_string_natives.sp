/**
 * Wrapper natives that stringify / unstringify parsed entity string values.
 */

static stock KeyValues KeyValueBuffer() {
	static KeyValues s_KVBuffer;
	if (!s_KVBuffer) {
		s_KVBuffer = new KeyValues("");
	}
	return s_KVBuffer;
}

static stock void VectorToString(const float vec[3], char[] buffer, int maxlen) {
	KeyValueBuffer().SetVector("key", vec);
	KeyValueBuffer().GetString("key", buffer, maxlen);
}

static stock void StringToVector(const char[] buffer, float vec[3]) {
	KeyValueBuffer().SetString("key", buffer);
	KeyValueBuffer().GetVector("key", vec);
}


public int Native_MapGetNum(Handle plugin, int argc) {
	StringMultiMap map = GetNativeCell(1);
	
	char key[128], value[128];
	GetNativeString(2, key, sizeof(key));
	
	return map.GetString(key, value, sizeof(value))? StringToInt(value) : GetNativeCell(3);
}

public int Native_MapAddNum(Handle plugin, int argc) {
	StringMultiMap map = GetNativeCell(1);
	
	char key[128], value[128];
	GetNativeString(2, key, sizeof(key));
	IntToString(GetNativeCell(3), value, sizeof(value));
	
	map.AddString(key, value);
	return 0;
}

public int Native_MapGetFloat(Handle plugin, int argc) {
	StringMultiMap map = GetNativeCell(1);
	
	char key[128], value[128];
	GetNativeString(2, key, sizeof(key));
	
	return view_as<int>(map.GetString(key, value, sizeof(value))? StringToFloat(value) : GetNativeCell(3));
}

public int Native_MapAddFloat(Handle plugin, int argc) {
	StringMultiMap map = GetNativeCell(1);
	
	char key[128], value[128];
	GetNativeString(2, key, sizeof(key));
	FloatToString(GetNativeCell(3), value, sizeof(value));
	
	map.AddString(key, value);
	return 0;
}

public int Native_MapGetVector(Handle plugin, int argc) {
	StringMultiMap map = GetNativeCell(1);
	
	char key[128], value[128];
	GetNativeString(2, key, sizeof(key));
	
	float outputVec[3];
	if (map.GetString(key, value, sizeof(value))) {
		StringToVector(value, outputVec);
	} else {
		GetNativeArray(4, outputVec, 3);
	}
	SetNativeArray(3, outputVec, 3);
}

public int Native_MapAddVector(Handle plugin, int argc) {
	StringMultiMap map = GetNativeCell(1);
	
	char key[128], value[128];
	GetNativeString(2, key, sizeof(key));
	
	float vec[3];
	GetNativeArray(3, vec, 3);
	
	VectorToString(vec, value, sizeof(value));
	map.AddString(key, value);
	return 0;
}

public int Native_MapIterGetNum(Handle plugin, int argc) {
	StringMultiMapIterator mapIter = GetNativeCell(1);
	
	char value[128];
	return mapIter.GetString(value, sizeof(value))? StringToInt(value) : GetNativeCell(2);
}

public int Native_MapIterSetNum(Handle plugin, int argc) {
	StringMultiMapIterator mapIter = GetNativeCell(1);
	
	char value[128];
	IntToString(GetNativeCell(2), value, sizeof(value));
	
	mapIter.SetString(value);
	return;
}

public int Native_MapIterGetFloat(Handle plugin, int argc) {
	StringMultiMapIterator mapIter = GetNativeCell(1);
	
	char value[128];
	return view_as<int>(mapIter.GetString(value, sizeof(value))?
			StringToFloat(value) : GetNativeCell(2));
}

public int Native_MapIterSetFloat(Handle plugin, int argc) {
	StringMultiMapIterator mapIter = GetNativeCell(1);
	
	char value[128];
	FloatToString(GetNativeCell(2), value, sizeof(value));
	
	mapIter.SetString(value);
	return 0;
}

public int Native_MapIterGetVector(Handle plugin, int argc) {
	StringMultiMapIterator mapIter = GetNativeCell(1);
	
	char value[128];
	
	float outputVec[3];
	if (mapIter.GetString(value, sizeof(value))) {
		StringToVector(value, outputVec);
	} else {
		GetNativeArray(3, outputVec, 3);
	}
	SetNativeArray(2, outputVec, 3);
}

public int Native_MapIterSetVector(Handle plugin, int argc) {
	StringMultiMapIterator mapIter = GetNativeCell(1);
	
	char value[128];
	
	float vec[3];
	GetNativeArray(2, vec, 3);
	
	VectorToString(vec, value, sizeof(value));
	mapIter.SetString(value);
	return 0;
}