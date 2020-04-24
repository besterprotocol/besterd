module handlers.response;

import std.json : JSONValue, JSONException;
import std.conv : to;
import utils.debugging : debugPrint;
import std.string : cmp;
import std.stdio : writeln;

public class HandlerResponse
{
	/* The message-handler's response */
	private JSONValue messageResponse;

	this(JSONValue messageResponse)
	{
		/* Set the message-handler's response message */
		this.messageResponse = messageResponse;

		/* Attempt parsing the message and error checking it */
		parse(messageResponse);
	}

	private void parse(JSONValue handlerResponse)
	{
		/**
		 * Handles the response sent back to the server from the
		 * message handler.
		 */

		 /* Get the status */
		 ulong statusCode;

		 /* Error? */
		 bool error;
		
				/* TODO: Bounds checking, type checking */
				try
				{
					/* Get the header block */
					JSONValue headerBlock = handlerResponse["header"];
		
					/* Get the status */
					statusCode = to!(ulong)(headerBlock["status"].str());
					debugPrint("Status code: " ~ to!(string)(statusCode));
		
					/* If the status is 0, then it is all fine */
					if(statusCode == 0)
					{
						debugPrint("Status is fine, the handler ran correctly");
						
						/* The command block */
						JSONValue commandBlock = headerBlock["command"];
						
						/**
						 * Get the command that the message handler wants the
						 * server to run.
						 */
						string serverCommand = commandBlock["type"].str;
						debugPrint("Handler->Server command: \"" ~ serverCommand ~ "\"");
						
						/* Check the command to be run */
						if(cmp(serverCommand, "sendClients") == 0)
						{
							/* Get the list of clients to send to */
							string[] clients;
							JSONValue[] clientList = commandBlock["data"].array();
							for(ulong i = 0; i < clientList.length; i++)
							{
								clients ~= clientList[i].str();
							}
						
							/* TODO: Implement me */
							writeln("Users wanting to send to ", clients);
						}
						else if(cmp(serverCommand, "sendServers") == 0)
						{
							/* Get the list of clients to send to */
							string[] clients;
							JSONValue[] clientList = commandBlock["data"].array();
							for(ulong i = 0; i < clientList.length; i++)
							{
								clients ~= clientList[i].str();
							}
										
							/* TODO: Implement me */
							writeln("Users wanting to send to ", clients);
						}
						else
						{
							/* TODO: Error handling */
							debugPrint("The message handler is using an invalid command");
						}
					}
					else
					{
						/* If the message handler returned a response in error */
						debugPrint("Message handler returned an error code: " ~ to!(string)(statusCode));
						error = true;
					}
				}
				catch(JSONException exception)
				{
					debugPrint("<<< There was an error handling the response message >>>\n\n" ~ exception.toString());
					error = true;
				}
		
		if(error)
		{
			throw new ResponseError(messageResponse, statusCode);
		}
			
		
	}

	override public string toString()
	{
		return messageResponse.toPrettyString();
	}
}

public final class ResponseError : Exception
{
	this(JSONValue messageResponse, ulong statusCode)
	{
		/* TODO: Set message afterwards again */
		super("");
	}
}