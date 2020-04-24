module handlers.handler;

import std.stdio : writeln;
import std.socket : Socket, AddressFamily, parseAddress, SocketType, SocketOSException, UnixAddress;
import std.json : JSONValue, JSONType;
import utils.debugging : debugPrint;

public final class MessageHandler
{
	/* The path to the message handler executable */
	private string executablePath;

	/* The UNIX domain socket */
	private Socket domainSocket;

	/* The pluginName/type */
	private string pluginName;

	public Socket getSocket()
	{
		return domainSocket;
	}

	this(string executablePath, string socketPath, string pluginName)
	{
		/* Set the plugin name */
		this.pluginName = pluginName;

		/* Initialize the socket */
		initializeUNIXSocket(socketPath);
	}

	public string getPluginName()
	{
		return pluginName;
	}

	private void initializeUNIXSocket(string socketPath)
	{
		/* Create the UNIX domain socket */
		domainSocket = new Socket(AddressFamily.UNIX, SocketType.STREAM);

		/* Bind it to the socket path */
		domainSocket.connect(new UnixAddress(socketPath));
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
	public static MessageHandler[] constructHandlers(JSONValue handlerBlock)
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
				MessageHandler constructedMessageHandler = new MessageHandler(configuration[0], configuration[1], pluginName);
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
}