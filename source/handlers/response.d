module handlers.response;

import std.json : JSONValue, JSONException, parseJSON;
import std.conv : to;
import utils.debugging : debugPrint;
import std.string : cmp;
import std.stdio : writeln;
import connection.connection;
import base.types;
import std.socket : Socket, SocketOSException, AddressFamily, SocketType, ProtocolType, parseAddress;
import utils.message : receiveMessage, sendMessage;
import handlers.handler;
import std.string : split;
import server.server : BesterServer;
import handlers.commands : Command;

/* The type of the command the message handler wants us to run */
private enum CommandType : ubyte
{
	/* Simple message flow (always end point) */
	SEND_CLIENTS, SEND_SERVERS, SEND_HANDLER,

	/* Unknown command */
	UNKNOWN
}

/**
* Represents a response message from a handler.
*/
public final class HandlerResponse
{
	/**
	* The message-handler's response.
	*/
	private JSONValue messageResponse;

	/* The command to be executed */
	private CommandType commandType;

	/* The handler that caused such a response to be illicited */
	private MessageHandler handler;

	/* The associated server */
	private BesterServer server;	

	/**
	* Constructs a new `HandlerResponse` object that represents the
	* message handler's response message and the execution of it.
	*/
	this(BesterServer server, MessageHandler handler, JSONValue messageResponse)
	{
		/* Set the message-handler's response message */
		this.messageResponse = messageResponse;

		/* Set the handler who caused this reponse to occur */
		this.handler = handler;

		/* Set the server associated with this message handler */
		this.server = server;

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

		/**
		 * If an error was envountered anyway down the processing of the
		 * message-handler then raise a `ResponseError` exception.
		 */
		if(error)
		{
			throw new ResponseError(messageResponse, statusCode);
		}
	}

	/**
	* Executes the command. Either `sendClients`, `sendServers`
	* or `sendHandler`.
	*/
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

			debugPrint("Users wanting to send to: " ~ to!(string)(clients));

			/* Find the users that are wanting to be sent to */
			BesterConnection[] connectionList = originalRequester.server.getClients(clients);
			//debugPrint("Users matched online on server: " ~ to!(string)(connectionList));

			/* The fully response message to send back */
			JSONValue clientPayload;

			/* Set the header of the response */
			JSONValue headerBlock; /* TODO: Do something with this */
			clientPayload["header"] = headerBlock;

			/* Set the payload of the response */
			JSONValue payloadBlock;
			payloadBlock["data"] = messageResponse["data"];
			payloadBlock["type"] = handler.getPluginName();
			clientPayload["payload"] = payloadBlock;


			/**
			* Loop through each BesterConnection in connectionList and
			* send the message-handler payload response message to each
			* of them.
			*/
			bool allSuccess = true;
			for(ulong i = 0; i < connectionList.length; i++)
			{
				/* Get the conneciton */
				BesterConnection clientConnection = connectionList[i];

				try
				{
					/* Get the client's socket */
					Socket clientSocket = clientConnection.getSocket();
					//debugPrint("IsAlive?: " ~ to!(string)(clientSocket.isAlive()));
					
					/* Send the message to the client */
					debugPrint("Sending handler's response to client \"" ~ clientConnection.toString() ~ "\"...");
					sendMessage(clientSocket, clientPayload);
					debugPrint("Sending handler's response to client \"" ~ clientConnection.toString() ~ "\"... [sent]");
				}
				catch(SocketOSException exception)
				{
					/**
					* If there was an error sending to the client, this can happen
					* if the client has disconnected but hasn't yet been removed from
					* the connections array and hence we try to send on a dead socket
					* or get the remoteAddress on a dead socket, which causes a
					* SocketOSException to be called.
					*/
					debugPrint("Attempted interacting with dead socket");
					allSuccess=false;
				}
			}

			debugPrint("SEND_CLIENTS: Completed run");

			/**
			* Send a status report here.
			*/
			originalRequester.sendStatusReport(cast(BesterConnection.StatusType)!allSuccess, messageResponse["payload"]["id"].str());
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


			/* The fully response message to send back */
			JSONValue serverPayload;

			/* Set the header of the response */
			JSONValue headerBlock;
			headerBlock["scope"] = "server";
			serverPayload["header"] = headerBlock;

			/* Set the payload of the response */
			JSONValue payloadBlock;
			payloadBlock["data"] = messageResponse["data"];
			payloadBlock["type"] = handler.getPluginName();
			serverPayload["payload"] = payloadBlock;


			/* Attempt connecting to each server and sending the payload */
			for(ulong i = 0; i < servers.length; i++)
			{
				/* Get the current server address and port */
				string serverString = servers[i];
				string host = serverString.split(":")[0];
				ushort port = to!(ushort)(serverString.split(":")[1]);

				try
				{
					Socket serverConnection = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);

					/* Connect to the server */
					debugPrint("Connecting to server \"" ~ serverConnection.toString() ~ "\"...");
					serverConnection.connect(parseAddress(host, port));
					debugPrint("Connecting to server \"" ~ serverConnection.toString() ~ "\"... [connected]");

					/* Send the payload */
					debugPrint("Sending handler's response to server \"" ~ serverConnection.toString() ~ "\"...");
					sendMessage(serverConnection, serverPayload);
					debugPrint("Sending handler's response to server \"" ~ serverConnection.toString() ~ "\"... [sent]");

					/* Close the connection to the server */
					serverConnection.close();
					debugPrint("Closed connection to server \"" ~ serverConnection.toString() ~ "\"");
				}
				catch(Exception e)
				{
					/* TODO: Be more specific with the above exception type */
					debugPrint("Error whilst sending payload to server: " ~ e.toString());
				}
			}

			debugPrint("SEND_SERVERS: Completed run");
		}
		else if (commandType == CommandType.SEND_HANDLER)
		{
			/* Name of the handler to send the message to */
			string handler = messageResponse["header"]["command"]["data"].str();
			debugPrint("Handler to forward to: " ~ handler);

			/* Lookup the payloadType handler */
			MessageHandler chosenHandler = server.findHandler(handler);

			/* Send the data to the message handler */
			HandlerResponse handlerResponse = chosenHandler.handleMessage(messageResponse["data"]);

			/* Execute the code (this here, recursive) */
			handlerResponse.execute(originalRequester);

			debugPrint("SEND_HANDLER: Completed run");
		}
		else
		{
			/* TODO: */
		}
	}

	override public string toString()
	{
		return messageResponse.toPrettyString();
	}
}

/**
* Represents an error in handling the response.
*/
public final class ResponseError : BesterException
{

	/* */

	/* The status code that resulted in the response handling error */
	private ulong statusCode;

	this(JSONValue messageResponse, ulong statusCode)
	{
		/* TODO: Set message afterwards again */
		super("");
	}
}