module besterd;

import server.server : BesterServer;
import std.conv : to;
import std.socket : SocketOSException, parseAddress, UnixAddress;
import utils.debugging : dprint;
import std.stdio : File, writeln;
import std.json : parseJSON, JSONValue;
import listeners.listener : BesterListener;
import listeners.types : TCP4Listener, TCP6Listener, UNIXListener;
import std.file : exists;

void main(string[] args)
{
	/* Make sure we have atleast two arguments */
	if(args.length >= 2)
	{
		/* Get the second argument for configuration file path */
		string configFilePath = args[1];

		/* Start thhe server if the file exists, else show an error */
		if(exists(configFilePath))
		{
			startServer(args[1]);
		}
		else
		{
			writeln("Provided server configuration file \"" ~ configFilePath ~ "\" does not exist");
		}
	}

	/* TODO: Add usage check and arguments before this */

	dprint("Main finished, remaining threads are keeping this open if it hangs");
}

private JSONValue getConfig(string configurationFilePath)
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

private BesterListener[] getListeners(BesterServer server, JSONValue networkBlock)
{
	BesterListener[] listeners;

	/* TODO: Error handling and get keys and clean up for formality */

	/* Look for IPv4 TCP block */
	JSONValue inet4TCPBlock = networkBlock["tcp4"];
	dprint("<<< IPv4 TCP Block >>>\n" ~ inet4TCPBlock.toPrettyString());
	string inet4Address = inet4TCPBlock["address"].str();
	ushort inet4Port = to!(ushort)(inet4TCPBlock["port"].str());
	TCP4Listener tcp4Listener = new TCP4Listener(server, parseAddress(inet4Address, inet4Port));
	listeners ~= tcp4Listener;

	/* Look for IPv6 TCP block */
	JSONValue inet6TCPBlock = networkBlock["tcp6"];
	dprint("<<< IPv6 TCP Block >>>\n" ~ inet6TCPBlock.toPrettyString());
	string inet6Address = inet6TCPBlock["address"].str();
	ushort inet6Port = to!(ushort)(inet6TCPBlock["port"].str());
	TCP6Listener tcp6Listener = new TCP6Listener(server, parseAddress(inet6Address, inet6Port));
	listeners ~= tcp6Listener;

	/* Look for UNIX Domain block */
	JSONValue unixDomainBlock = networkBlock["unix"];
	dprint("<<< UNIX Domain Block >>>\n" ~ unixDomainBlock.toPrettyString());
	string unixAddress = unixDomainBlock["address"].str();
//	UNIXListener unixListener = new UNIXListener(server, new UnixAddress(unixAddress));
//	listeners ~= unixListener;

	return listeners;
}

private void startServer(string configurationFilePath)
{
	/* The server configuration */
	JSONValue serverConfiguration = getConfig(configurationFilePath);
	dprint("<<< Bester.d configuration >>>\n" ~ serverConfiguration.toPrettyString());

	try
	{
		/* The server */
		BesterServer server = null;

		/* TODO: Bounds anc type checking */

		/* Get the network block */
		JSONValue networkBlock = serverConfiguration["network"];

		/* Create the Bester server */
		server = new BesterServer(serverConfiguration);

		/* TODO: Get keys */
		BesterListener[] listeners = getListeners(server, networkBlock);

		for(ulong i = 0; i < listeners.length; i++)
		{
			/* Add listener */
			server.addListener(listeners[i]);
		}
		
		/* Start running the server (starts the listeners) */
		server.run();
	}
	catch(SocketOSException exception)
	{
		dprint("Error binding: " ~ exception.toString());
	}
	
}
