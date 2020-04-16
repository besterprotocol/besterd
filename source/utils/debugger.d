module utils.debugging;

import std.stdio : writeln;

void debugPrint(string message)
{
	writeln("[DEBUG] " ~ message);
}