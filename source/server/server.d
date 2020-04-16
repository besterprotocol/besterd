module server.server;

import server.types;
import std.conv : to;
import std.socket : SocketOSException;
import utils.debugging : debugPrint;

void startServer(string address, ushort port)
{
	BesterServer server = null;

	try
	{
		server = new BesterServer(address, port);
		server.run();
	}
	catch(SocketOSException exception)
	{
		debugPrint("Error binding to address " ~ address ~ " and port " ~ to!(string)(port));
	}
	
}