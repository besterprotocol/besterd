module server.server;

import server.types;
import std.conv : to;
import std.socket : SocketOSException;
import utils.debugging : debugPrint;

void startServer(string configurationFilePath)
{
	BesterServer server = null;

	/* TODO: Open the file here */
	File configFile;
	configFile.open(configurationFilePath);

	/* The file buffer */
	byte[] fileBuffer;

	/* Allocate the buffer to be the size of the file */
	fileBuffer.length = configFile.size();

	/* TODO: File read here */

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