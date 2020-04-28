module utils.debugging;

import std.stdio : writeln;

alias dprint = debugPrint;

void debugPrint(string message)
{
	writeln("[DEBUG] " ~ message);
}