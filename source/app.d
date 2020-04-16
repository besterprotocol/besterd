module app;

import std.stdio;
import server.types;

void main()
{
	/* TODO: Change this */
	string address = "0.0.0.0";
	ushort port = 2222;

	BesterServer server = new BesterServer(address, port);
}
