module server.server;

import server.types;
import std.conv : to;
import std.socket : SocketOSException;
import utils.debugging : debugPrint;
import std.stdio : File,;
import std.json : parseJSON, JSONValue;

JSONValue getConfig(string configurationFilePath)
{
	/* TODO: Open the file here */
	File configFile;
	configFile.open(configurationFilePath);

	/* The file buffer */
	byte[] fileBuffer;

	/* Allocate the buffer to be the size of the file */
	fileBuffer.length = configFile.size();

	/* Read the content of the file */
	/* TODO: Error handling ErrnoException */
	fileBuffer = configFile.rawRead(fileBuffer);
	configFile.close();

	JSONValue config;

	/* TODO: JSON error checking */
	config = parseJSON(cast(string)fileBuffer);

	return config;	
}

void startServer(string configurationFilePath)
{
	/* The server configuration */
	JSONValue serverConfiguration = getConfig(configurationFilePath);
	writeln(serverConfiguration);

	/* The server */
	BesterServer server = null;

	try
	{
		server = new BesterServer(serverConfiguration);
		server.run();
	}
	catch(SocketOSException exception)
	{
		debugPrint("Error binding: " ~ exception.toString());
	}
	
}