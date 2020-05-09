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
import base.types : BesterException;

/**
* Represents a server listener which is a method
* by which conections to the server (client or server)
* can be made.
*/
public class BesterListener : Thread
{
	/* The associated BesterServer */
	private BesterServer server;

	/* The server's socket */
	private Socket serverSocket;
	
	/* Whether or not the listener is active */
	private bool active = true;

	/* the address of this listener */
	protected Address address;

	this(BesterServer besterServer)
	{
		/* Set the function address to be called as the worker function */
		super(&run);

		/* Set this listener's BesterServer */
		this.server = besterServer;
	}

	/**
	* Set the server socket.
	*/
	public void setServerSocket(Socket serverSocket)
	{
		/* Set the server socket */
		this.serverSocket = serverSocket;
	}

	/**
	* Get the server socket.
	*/
	public Socket getServerSocket()
	{
		return serverSocket;
	}

	/**
	* Start listen loop.
	*/
	public void run()
	{
		serverSocket.listen(1); /* TODO: This value */
		debugPrint("Server listen loop started");

		/* Loop receive and dispatch connections whilst active */
		while(active)
		{
			/* Wait for an incoming connection */
			Socket clientConnection = serverSocket.accept();

			/* Create a new client connection handler and start its thread */
			BesterConnection besterConnection = new BesterConnection(clientConnection, server);
			besterConnection.start();

			/* Add this client to the list of connected clients */
			server.clients ~= besterConnection;
		}

		/* Close the socket */
		serverSocket.close();
	}

	public void shutdown()
	{
		active = false;
	}
}

public final class BesterListenerException : BesterException
{
	this(BesterListener e)
	{
		super("Could not bind to: " ~ e.toString());
	}
}
