module server.types.server;

import utils.debugging : debugPrint;
import std.conv : to;
import std.socket : Socket, AddressFamily, SocketType, ProtocolType, parseAddress, SocketFlags, Address;
import core.thread : Thread;
import std.stdio : writeln, File;
import std.json : JSONValue, parseJSON, JSONException, JSONType, toJSON;
import std.string : cmp;
import server.handler;
import server.listeners;





public class BesterServer
{
	/**
	* Message handlers
	*
	* Associative array of `payloadType (string)`:`MessageHandler`
	* TODO: Implement this
	*/
	private MessageHandler[] handlers;

	/* The server's socket */
	private Socket serverSocket;
	/* TODO: The above to be replaced */

	/* Socket listeners for incoming connections */
	private BesterListener[] listeners;

	/* Connected clients */
	public BesterConnection[] clients;

	public void addListener(BesterListener listener)
	{
		this.listeners ~= listener;
	}

	this(JSONValue config)
	{
		/* TODO: Bounds check and JSON type check */
		//debugPrint("Setting up socket...");
		//setupServerSocket(config["network"]);

		/* TODO: Bounds check and JSON type check */
		debugPrint("Setting up message handlers...");
		setupHandlers(config["handlers"]);
	}

	private void setupHandlers(JSONValue handlerBlock)
	{
		/* TODO: Implement me */
		debugPrint("Constructing message handlers...");
		handlers = MessageHandler.constructHandlers(handlerBlock);
		writeln(handlers[0].getPluginName());
	}

	/* Setup the server socket */
	private void setupServerSocket(JSONValue networkBlock)
	{
		string bindAddress;
		ushort listenPort;
		
		JSONValue jsonAddress, jsonPort;

		writeln(networkBlock);

		/* TODO: Bounds check */
		jsonAddress = networkBlock["address"];
		jsonPort = networkBlock["port"];

		bindAddress = jsonAddress.str;
		listenPort = cast(ushort)jsonPort.integer;

		debugPrint("Binding to address: " ~ bindAddress ~ " and port " ~ to!(string)(listenPort));
		
		/* Create a socket */
		serverSocket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
		serverSocket.bind(parseAddress(bindAddress, listenPort));
	}

	/* Start listen loop */
	public void run()
	{
		for(ulong i = 0; i < listeners.length; i++)
		{
			debugPrint("Starting...");
			listeners[i].start();
		}
		
	}

	/* Authenticate the user */
	public bool authenticate(string username, string password)
	{
		/* TODO: Implement me */
		debugPrint("Attempting to authenticate:\n\nUsername: " ~ username ~ "\nPassword: " ~ password);

		/* If the authentication went through */
		bool authed = true;

		/* If the authentication succeeded */
		if(authed)
		{
			/* Add the user to the list of authenticated clients */
		}
		
		return true;
	}

	/* Returns the MessageHandler object of the requested type */
	public MessageHandler findHandler(string payloadType)
	{
		/* The found MessageHandler */
		MessageHandler foundHandler;
		
		for(uint i = 0; i < handlers.length; i++)
		{
			if(cmp(handlers[i].getPluginName(), payloadType) == 0)
			{
				foundHandler = handlers[i];
				break;
			}
		}
		return foundHandler;
	}

	public static bool isBuiltInCommand(string command)
	{
		/* Whether or not `payloadType` is a built-in command */
		bool isBuiltIn = true;


		return isBuiltIn;
	}
}


