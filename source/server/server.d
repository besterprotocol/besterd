module server.server;

import server.types;

void startServer(string address, ushort port)
{
	BesterServer server = new BesterServer(address, port);
	server.run();
}