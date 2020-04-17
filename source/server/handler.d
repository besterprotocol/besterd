module server.handler;

import std.stdio : writeln;
import std.socket : Socket;
import std.json : JSONValue, JSONType;
import utils.debugging : debugPrint;

public class MessageHandler
{
	/* The path to the message handler executable */
	private string executablePath;

	/* The UNIX domain socket */
	private Socket domainSocket;

	this(string executablePath, string socketPath)
	{
		
	}

	private static string[] getAvailableTypes(JSONValue handlerBlock)
	{
		/* TODO: Use this */

/* AVailable types as strings */
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

	/* TODO: Implement me */
	public static MessageHandler[] constructHandlers(JSONValue handlerBlock)
	{
		/* List of loaded message handlers */
		MessageHandler[] handlers;

		/* TODO: Throwing error from inside this function */
		string[] availableTypes = getAvailableTypes(handlerBlock);
		

		return handlers;
	}
}