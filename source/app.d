module app;

import std.stdio;
import server.server;

void main()
{
	/* TODO: Change this */
	string address = "0.0.0.0";
	ushort port = 2223;

	/* TODO: Add usage check and arguments before this */
	startServer(address, port);
}
