module server.server;

import utils.debugging : debugPrint;
import std.conv : to;
import std.socket : Socket, AddressFamily, SocketType, ProtocolType, parseAddress;
import core.thread : Thread;
import std.stdio : writeln, File;
import std.json : JSONValue, parseJSON, JSONException, JSONType, toJSON;
import std.string : cmp, strip;
import handlers.handler : MessageHandler;
import listeners.listener : BesterListener;
import connection.connection : BesterConnection;
import server.informer.informer : BesterInformer;
import server.accounts : BesterDataStore;


/**
* Represents an instance of a Bester server.
*/
public final class BesterServer
{
	/**
	* Array of message handlers attached to
	* this server.
	*/
	public MessageHandler[] handlers;

	/**
	* The server's socket.
	*/
	private Socket serverSocket;
	/* TODO: The above to be replaced */

	/**
	* Socket listeners for incoming connections.
	*/
	private BesterListener[] listeners;

	/**
	* Connected clients.
	*/
	public BesterConnection[] clients;

	/**
	* The informer server.
	*/
	private BesterInformer informer;

	/**
	* Admin information regarding this server.
	*/
	private JSONValue adminInfo;

	/**
	* The datastore for the account information.
	*/
	private BesterDataStore dataStore;

	/**
	 * Returns a list of BesterConnection objects that
	 * match the usernames provided.
	 *
	 * @param usernames Array of strings of usernames to match to
	 */
	public BesterConnection[] getClients(string[] usernames)
	{
		/* List of authenticated users matching `usernames` */
		BesterConnection[] matchedUsers;

		//debugPrint("All clients (ever connected): " ~ to!(string)(clients));

		/* Search through the provided usernames */
		for(ulong i = 0; i < usernames.length; i++)
		{
			for(ulong k = 0; k < clients.length; k++)
			{
				/* The potentially-matched user */
				BesterConnection potentialMatch = clients[k];
				
				/* Check if the user is authenticated */
				if(potentialMatch.getType() == BesterConnection.Scope.CLIENT && cmp(potentialMatch.getCredentials()[0], usernames[i]) == 0)
				{
					matchedUsers ~= potentialMatch;
				}	
			}
		}

		return matchedUsers;
	}

	/**
	* Adds a listener, `listener`, to this server's
	* listener set.
	*/
	public void addListener(BesterListener listener)
	{
		this.listeners ~= listener;
	}

	/**
	* Constructs a new BesterServer with the given
	* JSON configuration.
	*/
	this(JSONValue config)
	{
		/* TODO: Bounds check and JSON type check */
		//debugPrint("Setting up socket...");
		//setupServerSocket(config["network"]);

		/* TODO: Bounds check and JSON type check */
		debugPrint("Setting up message handlers...");
		setupHandlers(config["handlers"]);
	}

	/**
	* Given JSON, `handlerBlock`, this will setup the
	* relevant message handlers.
	*/
	private void setupHandlers(JSONValue handlerBlock)
	{
		/* TODO: Implement me */
		debugPrint("Constructing message handlers...");
		handlers = MessageHandler.constructHandlers(this, handlerBlock);
	}

	/**
	* Setup the server socket.
	*/
	private void setupServerSocket(JSONValue networkBlock)
	{
		string bindAddress;
		ushort listenPort;
		
		JSONValue jsonAddress, jsonPort;

		debugPrint(networkBlock);

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

	/**
	* Starts all the listeners.
	*/
	private void startListeners()
	{
		for(ulong i = 0; i < listeners.length; i++)
		{
			debugPrint("Starting listener \"" ~ listeners[i].toString() ~ "\"...");
			listeners[i].start();
		}
	}

	/**
	* Starts the BesterInformer.
	*/
	private void startInformer()
	{
		informer = new BesterInformer(this);
		informer.start();
	}

	/**
	* Start listen loop.
	*/
	public void run()
	{
		/* Start the listeners */
		startListeners();

		/* Start the informer */
		startInformer();
	}

	/**
	* Authenticate the user.
	*/
	public bool authenticate(string username, string password)
	{
		/* TODO: Implement me */
		debugPrint("Attempting to authenticate:\n\nUsername: " ~ username ~ "\nPassword: " ~ password);

		/* If the authentication went through */
		bool authed = true;

		/* Strip the username of whitespace (TODO: Should we?) */
		username = strip(username);

		/* Make sure username and password are not empty */
		if(cmp(username, "") != 0 && cmp(password, "") != 0)
		{

		}
		else
		{
			authed = false;
		}

		return authed;
	}

	/**
	* Returns the MessageHandler object of the requested type.
	*/
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

	/**
	* Stops the server.
	*/
	private void shutdown()
	{
		/* Stop the informer service */
		informer.shutdown();

		/* Shutdown all the listeners */
		shutdownListeners();

		/* Shutdown all the clients */
		shutdownClients();

		/* Shutdown the datastore */
		dataStore.shutdown();
	}

	/**
	* Loops through the list of `BesterListener`s and
	* shuts each of them down.
	*/
	private void shutdownListeners()
	{
		/* Shutdown all the listeners */
		for(ulong i = 0; i < listeners.length; i++)
		{
			listeners[i].shutdown();
		}
	}

	/**
	* Loops through the list of `BesterConnection`s and
	* shuts each of them down.
	*/
	private void shutdownClients()
	{
		/* Shutdown all the clients */
		for(ulong i = 0; i < clients.length; i++)
		{
			clients[i].shutdown();
		}
	}

	public JSONValue getAdminInfo()
	{
		return adminInfo;
	}
}