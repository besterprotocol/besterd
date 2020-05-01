module handlers.handler;

import std.stdio : writeln;
import std.socket : Socket, AddressFamily, parseAddress, SocketType, SocketOSException, UnixAddress;
import std.json : JSONValue, JSONType;
import utils.debugging : debugPrint;
import handlers.response;
import base.net;
import utils.message : sendMessage, receiveMessage;
import server.server : BesterServer;
import std.process : spawnProcess, Pid;

public final class MessageHandler
{
	/* The path to the message handler executable */
	private string executablePath;

	/* The UNIX domain socket */
	private Socket domainSocket;

	/* The pluginName/type */
	private string pluginName;

	/* The UNIX domain socket path */
	public string socketPath;

	/* The BesterServer being used */
	public BesterServer server;

	/* The PID of the process */
	private Pid pid;

	public Socket getSocket()
	{
		return domainSocket;
	}

	this(BesterServer server, string executablePath, string socketPath, string pluginName)
	{
		/* Set the plugin name */
		this.pluginName = pluginName;

		/* Set the socket path */
		this.socketPath = socketPath;

		/* Set the server this handler is associated with */
		this.server = server;

		/* Start the message handler */
		startHandlerExecutable();
	}

	private void startHandlerExecutable()
	{
		// pid = spawnProcess(executablePath);
	}

	public string getPluginName()
	{
		return pluginName;
	}

	public Socket getNewSocket()
	{
		/* Create the UNIX domain socket */
		Socket domainSocket = new Socket(AddressFamily.UNIX, SocketType.STREAM);
		
		/* Connect to the socket at the socket path */
		domainSocket.connect(new UnixAddress(socketPath));

		return domainSocket;
	}

	private static string[] getAvailableTypes(JSONValue handlerBlock)
	{
		/* Available types as strings */
		string[] availableTypesStrings;
		
		/* Get the available handlers */
		JSONValue availableTypes;
		
		/* TODO: Bounds check */
		availableTypes = handlerBlock["availableTypes"];
		
		/* Make sure it is an array */
		if(availableTypes.type == JSONType.array)
		{
			/* Get the array of available types */
			JSONValue[] availableTypesArray = availableTypes.array;
		
			for(uint i = 0; i < availableTypesArray.length; i++)
			{
				/* Make sure that it is a string */
				if(availableTypesArray[i].type == JSONType.string)
				{
					/* Add the type handler to the list of available types */
					availableTypesStrings ~= availableTypesArray[i].str;
					debugPrint("Module wanted: " ~ availableTypesArray[i].str);
				}
				else
				{
					/* TODO: Error handling here */
					debugPrint("Available type not of type JSON string");
				}
			}
		}
		else
		{
			/* TODO: Error handling */
		}

		return availableTypesStrings;
	}

	private static string[2] getConfigurationArray(string pluginName, JSONValue typeMapBlock)
	{
		/* The configuration string */
		string[2] configurationString;

		/* The module block */		
		JSONValue moduleBlock;

		/* TODO: Bounds check */
		moduleBlock = typeMapBlock[pluginName];

		/* Module block mst be of tpe JSON object */
		if(moduleBlock.type == JSONType.object)
		{
			/* TODO: Set the executable path */
			configurationString[0] = moduleBlock["handlerBinary"].str;

			/* TODO: Set the UNIX domain socket path */
			configurationString[1] = moduleBlock["unixDomainSocketPath"].str;
		}
		else
		{
			/* TODO: Error handling */
		}

		return configurationString;
	}

	/* TODO: Implement me */
	public static MessageHandler[] constructHandlers(BesterServer server, JSONValue handlerBlock)
	{
		/* List of loaded message handlers */
		MessageHandler[] handlers;

		/* TODO: Throwing error from inside this function */
		string[] availableTypes = getAvailableTypes(handlerBlock);

		for(uint i = 0; i < availableTypes.length; i++)
		{
			/* Load module */
			string pluginName = availableTypes[i];
			debugPrint("Loading module \"" ~ pluginName ~ "\"...");

			try
			{
				JSONValue typeMap;

				/* TODO: Bounds check */
				typeMap = handlerBlock["typeMap"];
			
				string[2] configuration = getConfigurationArray(pluginName, typeMap);
				debugPrint("Module executable at: \"" ~ configuration[0] ~ "\"");
				debugPrint("Module socket path at: \"" ~ configuration[1] ~ "\"");
				MessageHandler constructedMessageHandler = new MessageHandler(server, configuration[0], configuration[1], pluginName);
				handlers ~= constructedMessageHandler;
				debugPrint("Module \"" ~ pluginName ~ "\" loaded");
			}
			catch(SocketOSException exception)
			{
				debugPrint("Error whilst loading module \"" ~ pluginName ~ "\": " ~ exception.toString());
			}
		}

		return handlers;
	}

	/**
	 * Sends the payload to the designated message handler and gets
	 * the response message from the handler and returns it.
	 */
	public HandlerResponse handleMessage(JSONValue payload)
	{
		/* TODO: If unix sock is down, this just hangs, we should see if the socket file exists first */
		/* Handler's UNIX domain socket */
		Socket handlerSocket = getNewSocket();
	
		/* Send the payload to the message handler */
		debugPrint("Sending payload over to handler for \"" ~ getPluginName() ~ "\".");
		sendMessage(handlerSocket, payload);
						
		/* Get the payload sent from the message handler in response */
		debugPrint("Waiting for response from handler for \"" ~ getPluginName() ~ "\".");
		JSONValue response;
	
		try
		{
			receiveMessage(handlerSocket, response);
		}
		catch(NetworkException exception)
		{
			/* TODO: Implement error handling here and send a repsonse back (Issue: https://github.com/besterprotocol/besterd/issues/10) */
			debugPrint("Error communicating with message handler");
		}
		finally
		{
			/* Always close the socket */
			handlerSocket.close();
			debugPrint("Closed UNIX domain socket to handler");
		}
				
			
		return new HandlerResponse(server, this, response);
	}
}