module app;

import std.stdio;
import server.server;

unittest d
{
	writeln("Hello");
}

void main()
{
	/* TODO: Change this */
	string address = "0.0.0.0";
	ushort port = 2222;

	/* TODO: Add usage check and arguments before this */
	startServer(address, port);
}
