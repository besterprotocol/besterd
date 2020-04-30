module utils.debugging;

import std.stdio : writeln;
import std.process : environment;

alias dprint = debugPrint;

void debugPrint(string message)
{
	/* Check if the environment variable for `B_DEBUG` exists */
	if(!(environment.get("B_DEBUG") is null))
	{
		writeln("[DEBUG] " ~ message);
	}
}