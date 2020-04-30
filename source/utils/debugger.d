module utils.debugging;

import std.stdio : writeln;
import std.process : environment;
import std.conv : to;

alias dprint = debugPrint;

void debugPrint(MessageType)(MessageType message)
{
	/* Check if the environment variable for `B_DEBUG` exists */
	if(!(environment.get("B_DEBUG") is null))
	{
		writeln("[DEBUG] " ~ to!(string)(message));
	}
}