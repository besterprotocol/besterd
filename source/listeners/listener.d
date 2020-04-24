module listeners.listener;

import utils.debugging : debugPrint;
import std.conv : to;
import std.socket : Socket, AddressFamily, SocketType, ProtocolType, parseAddress, SocketFlags, Address;
import core.thread : Thread;
import std.stdio : writeln, File;
import std.json : JSONValue, parseJSON, JSONException, JSONType, toJSON;
import std.string : cmp;
import handlers.handler;
import server.server;
import connection.connection;


/* TODO: Implement me */
/* All this will do is accept incoming connections
 * but they will be pooled in the BesterServer.
 */
public class BesterListener : Thread
{

	/* The associated BesterServer */
	private BesterServer server;

	/* The server's socket */
	private Socket serverSocket;

	this(BesterServer besterServer)
	{
		/* Set the function address to be called as the worker function */
		super(&run);

		/* Set this listener's BesterServer */
		this.server = besterServer;
	}

	public void setServerSocket(Socket serverSocket)
	{
		/* Set the server socket */
		this.serverSocket = serverSocket;
	}


	/* Start listen loop */
	public void run()
	{
		serverSocket.listen(1); /* TODO: This value */
		debugPrint("Server listen loop started");
		while(true)
		{
			/* Wait for an incoming connection */
			Socket clientConnection = serverSocket.accept();

			/* Create a new client connection handler and start its thread */
			BesterConnection besterConnection = new BesterConnection(clientConnection, server);
			besterConnection.start();

			/* Add this client to the list of connected clients */
			server.clients ~= besterConnection;
		}
	}
	
}
