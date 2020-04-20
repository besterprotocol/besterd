module server.server;

import server.types;
import std.conv : to;
import std.socket : SocketOSException;
import utils.debugging : debugPrint;
import std.stdio : File, writeln;
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

BesterListener[] getListeners(JSONValue networkBlock)
{
	BesterListener[] listeners;

	/* TODO: Error handling */

	/* Look for IPv4 TCP block */
	JSONValue inet4TCPBlock = networkBlock["tcp4"];
	debugPrint("<<< IPv4 TCP Block >>>\n" ~ inet4TCPBlock.toPrettyString());
	string inet4Address = inet4TCPBlock["address"].str();
	ushort inet4Port = to!(ushort)(inet4TCPBlock["port"].str());
	
	/* Look for IPv6 TCP block */
	JSONValue inet6TCPBlock = networkBlock["tcp6"];
	debugPrint("<<< IPv6 TCP Block >>>\n" ~ inet6TCPBlock.toPrettyString());
	string inet6Address = inet6TCPBlock["address"].str();
	ushort inet6Port = to!(ushort)(inet6TCPBlock["port"].str());
	
	/* Look for UNIX Domain block */
	JSONValue unixDomainBlock = networkBlock["unix"];
	debugPrint("<<< UNIX Domain Block >>>\n" ~ unixDomainBlock.toPrettyString());
	string unixAddress = unixDomainBlock["address"].str();
	

	return listeners;
}

void startServer(string configurationFilePath)
{
	/* The server configuration */
	JSONValue serverConfiguration = getConfig(configurationFilePath);
	debugPrint("<<< Bester.d configuration >>>\n" ~ serverConfiguration.toPrettyString());

	/* TODO: Bounds anc type checking */
	/* Get the network block */
	JSONValue networkBlock = serverConfiguration["network"];

	/* TODO: Get keys */
	BesterListener[] listeners = getListeners(networkBlock);

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