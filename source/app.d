module app;

import std.stdio;
import server.server;

unittest d
{
	writeln("Hello");
	main();
}

void main()
{
	/* TODO: Change this */
	string address = "0.0.0.0";
	ushort port = 2222;

	/* TODO: Add usage check and arguments before this */
	startServer("server.conf");

	writeln("fdhjf he do be vibing though");
}
