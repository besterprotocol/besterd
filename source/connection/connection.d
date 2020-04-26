module connection.connection;

import utils.debugging : debugPrint;
import std.conv : to;
import std.socket : Socket, AddressFamily, SocketType, ProtocolType, parseAddress, SocketFlags, Address;
import core.thread : Thread;
import std.stdio : writeln, File;
import std.json : JSONValue, parseJSON, JSONException, JSONType, toJSON;
import std.string : cmp;
import handlers.handler;
import listeners.listener;
import server.server;
import handlers.response;
import connection.message;

public final class BesterConnection : Thread
{

	/* The socket to the client */
	private Socket clientConnection;

	/* The server backend */
	public BesterServer server;

	/* The client's credentials  */
	private string username;
	private string password;

	/* The connection scope */
	public enum Scope
	{
		CLIENT,
		SERVER,
		UNKNOWN
	}

	/* The type of this connection */
	private Scope connectionType = Scope.UNKNOWN;

	public Scope getType()
	{
		return connectionType;
	}

	this(Socket clientConnection, BesterServer server)
	{
		/* Save socket and set thread worker function pointer */
		super(&run);
		this.clientConnection = clientConnection;
		this.server = server;

		debugPrint("New client handler spawned for " ~ clientConnection.remoteAddress().toAddrString());
	}

	override public string toString()
	{
		return clientConnection.remoteAddress().toAddrString();
	}

	public string[] getCredentials()
	{
		return [username, password];
	}

	/* Read/send loop */
	private void run()
	{
		while(true)
		{
			/* Received JSON message */
			JSONValue receivedMessage;
			
			/* Receive a message */
			receiveMessage(clientConnection, receivedMessage);
			
			/* Process the message */
			processMessage(receivedMessage);
		}
	}

	/**
	 * Sends the payload to the designated message handler and gets
	 * the response message from the handler and returns it.
	 */
	private JSONValue handlerRun(MessageHandler chosenHandler, JSONValue payload)
	{
		/* Handler's UNIX domain socket */
		Socket handlerSocket = chosenHandler.getNewSocket();

		/* Send the payload to the message handler */
		debugPrint("Sending payload over to handler for \"" ~ chosenHandler.getPluginName() ~ "\".");
		sendMessage(handlerSocket, payload);
					
		/* Get the payload sent from the message handler in response */
		debugPrint("Waiting for response from handler for \"" ~ chosenHandler.getPluginName() ~ "\".");
		JSONValue response;
		receiveMessage(handlerSocket, response);
		
		return response;
	}

	

	/* TODO: Version 2 of message dispatcher */
	private bool dispatchMessage(Scope scopeField, JSONValue payloadBlock)
	{
		/* Status of dispatch */
		bool dispatchStatus = true;

		/* TODO: Bounds checking, type checking */

		/* Get the payload type */
		string payloadType = payloadBlock["type"].str;
		debugPrint("Payload type is \"" ~ payloadType ~ "\"");

		/* Get the payload data */
		JSONValue payloadData = payloadBlock["data"];

		/* Lookup the payloadType handler */
		MessageHandler chosenHandler = server.findHandler(payloadType);

		/* Check if the payload is a built-in command */
		if(cmp(payloadType, "builtin") == 0)
		{
			/* TODO: Implement me */
			debugPrint("Built-in payload type");

			/**
			 * Built-in commands follow the structure of 
			 * "command" : {"type" : "cmdType", "command" : ...}
			 */
			JSONValue commandBlock = payloadData["command"];
			string commandType = commandBlock["type"].str;
			JSONValue command = commandBlock["args"];

			/* If the command is `close` */
			if(cmp(commandType, "close") == 0)
			{
				debugPrint("Closing socket...");
				this.clientConnection.close();
			}
			else
			{
				debugPrint("Invalid built-in command type");
				/* TODO: Generate error response */
			}
		}
		/* If an external handler is found (i.e. not a built-in command) */
		else if(chosenHandler)
		{
			/* TODO: Implement me */
			debugPrint("Chosen handler for payload type \"" ~ payloadType ~ "\" is " ~ chosenHandler.getPluginName());

			try
			{
				/* TODO: Collect return value */
				HandlerResponse handlerResponse = new HandlerResponse(handlerRun(chosenHandler, payloadData));	

				/* TODO: Continue here, we will make all error handling do on construction as to make this all more compact */
				debugPrint("<<< Message Handler [" ~ chosenHandler.getPluginName() ~ "] response >>>\n\n" ~ handlerResponse.toString());

				/* Execute the message handler's command */
				handlerResponse.execute(this);
			}
			catch(ResponseError e)
			{
				/* In the case of an error with the message handler, send an error to the client/server */
				
				/* TODO: Send error here */
			}
			

			/* TODO: Handle response */
		}
		else
		{
			/* TODO: Implement error handling */
			debugPrint("No handler available for payload type \"" ~ payloadType ~ "\"");
		}

		return dispatchStatus;
	}


	/**
	 * Given the headerBlock, this returns the requested scope
	 * of the connection.
	 */
	private Scope getConnectionScope(JSONValue headerBlock)
	{
		/* TODO: Type checking and bounds checking */

		/* Get the scope block */
		JSONValue scopeBlock = headerBlock["scope"];
		string scopeString = scopeBlock.str();
		
		if(cmp(scopeString, "client") == 0)
		{
			return Scope.CLIENT;
		}
		else if(cmp(scopeString, "server") == 0)
		{
			return Scope.SERVER;
		}

		return Scope.UNKNOWN;
	}

	/* Process the received message */
	private void processMessage(JSONValue jsonMessage)
	{

		/* Attempt to convert the message to JSON */
		try
		{
			/* Convert message to JSON */
			debugPrint("<<< Received JSON >>>\n\n" ~ jsonMessage.toPrettyString());

			/* TODO: Bounds checking, type checking */

			/* Get the header */
			JSONValue headerBlock = jsonMessage["header"];

			

			/**
			 * Check to see if this connection is currently "untyped".
			 *
			 * If it is then we set the type.
			 */
			if(connectionType == Scope.UNKNOWN)
			{
				/* Get the scope of the message */
				Scope scopeField = getConnectionScope(headerBlock);

				/* TODO: Authenticate if client, else do ntohing for server */

				/* Decide what action to take depending on the scope */
				if(scopeField == Scope.UNKNOWN)
				{
					/* If the host-provided `scope` field was invalid */
					debugPrint("Host provided scope was UNKNOWN");

					/* TODO: Send message back about an invalid scope */

					/* Close the connection */
					clientConnection.close();
				}
				else if(scopeField == Scope.CLIENT)
				{
					/**
					 * If the host-provided `scope` field is `Scope.CLIENT`
					 * then we must attempt authentication, if it fails
					 * send the client a message back and then close the
					 * connection.
					 */

					/* Get the authentication block */
					JSONValue authenticationBlock = headerBlock["authentication"];

					/* Get the username and password */
					string username = authenticationBlock["username"].str(), password = authenticationBlock["password"].str();

					/* Attempt authentication */
					bool authenticationStatus = server.authenticate(username, password);

					/* Check if the authentication was successful or not */
					if(authenticationStatus)
					{
						/**
						 * If the authentication was successful then store the 
						 * client's credentials.
						 */
						 this.username = username;
						 this.password = password;
					}
					else
					{
						/**
						 * If the authentication was unsuccessful then send a
						 * message to the client stating so and close the connection.
						 */
						debugPrint("Authenticating the user failed, sending error and closing connection.");

						 /* TODO : Send error message to client */

						 /* Close the connection */
						 clientConnection.close();
					}
				}


				/* Set the connection type to `scopeField` */
				connectionType = scopeField;
			}
			else
			{
				/* TODO: Implement worker here */
			}


			/* Get the payload block */
			JSONValue payloadBlock = jsonMessage["payload"];
			debugPrint("<<< Payload is >>>\n\n" ~ payloadBlock.toPrettyString());


			/* Dispatch the message */
			bool dispatchStatus = dispatchMessage(connectionType, payloadBlock);
								
			if(dispatchStatus)
			{
				debugPrint("Dispatch succeeded");
			}
			else
			{
				/* TODO: Error handling */
				debugPrint("Dispatching failed...");
			}	
		}
		/* If thr attempt to convert the message to JSON fails */
		catch(JSONException exception)
		{
			debugPrint("<<< There was an error whilst parsing the JSON message >>>\n\n"~exception.toString());
		}

		/* TODO: Return value */

	}

	
}
