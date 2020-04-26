module handlers.response;

import std.json : JSONValue, JSONException;
import std.conv : to;
import utils.debugging : debugPrint;
import std.string : cmp;
import std.stdio : writeln;
import connection.connection;
import base.types;

/* The type of the command the message handler wants us to run */
private enum CommandType
{
	SEND_CLIENTS, SEND_SERVERS, SEND_HANDLER
}

public final class HandlerResponse
{
	/* The message-handler's response */
	private JSONValue messageResponse;

	/* The command to be executed */
	private CommandType commandType;

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
							/* Set the command type to SEND_CLIENTS */
							commandType = CommandType.SEND_CLIENTS;

							/* TODO: Error check and do accesses JSON that would be done in `.execute` */
						}
						else if(cmp(serverCommand, "sendServers") == 0)
						{
							/* Set the command type to SEND_SERVERS */
							commandType = CommandType.SEND_SERVERS;

							/* TODO: Error check and do accesses JSON that would be done in `.execute` */
						}
						else if(cmp(serverCommand, "sendHandler") == 0)
						{
							/* Set the command type to SEND_HAANDLER */
							commandType = CommandType.SEND_HANDLER;

							/* TODO: Error check and do accesses JSON that would be done in `.execute` */
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

	public void execute(BesterConnection originalRequester)
	{
		/* TODO: Implement me */

		/* If the command is SEND_CLIENTS */
		if(commandType == CommandType.SEND_CLIENTS)
		{
			/* Get the list of clients to send to */
			string[] clients;
			JSONValue[] clientList = messageResponse["header"]["command"]["data"].array();
			for(ulong i = 0; i < clientList.length; i++)
			{
				clients ~= clientList[i].str();
			}

			writeln("Users wanting to send to ", clients);

			/* Find the users that are wanting to be sent to */
			BesterConnection[] connectionList = originalRequester.server.getClients(clients);
			writeln(connectionList);

			/* TODO: Implement me */
			
			writeln("sdafdfasd", originalRequester.server.clients[0].toString());
		}
		else if (commandType == CommandType.SEND_SERVERS)
		{
			/* Get the list of servers to send to */
			string[] servers;
			JSONValue[] serverList = messageResponse["header"]["command"]["data"].array();
			for(ulong i = 0; i < serverList.length; i++)
			{
				servers ~= serverList[i].str();
			}
													
			/* TODO: Implement me */
			writeln("Servers wanting to send to ", servers);
		}
		else if (commandType == CommandType.SEND_HANDLER)
		{
			/* Name of the handler to send the message to */
			string handler = messageResponse["header"]["command"]["data"]["handler"].str();
			debugPrint("Handler to forward to: " ~ handler);

			/* TODO: Add me */
		}
	}

	override public string toString()
	{
		return messageResponse.toPrettyString();
	}
}

public final class ResponseError : BesterException
{
	this(JSONValue messageResponse, ulong statusCode)
	{
		/* TODO: Set message afterwards again */
		super();
	}
}