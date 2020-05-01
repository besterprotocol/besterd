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
import base.net;
import base.types;

public final class BesterConnection : Thread
{

	/* The socket to the client */
	private Socket clientConnection;

	/* The server backend */
	public BesterServer server;

	/* The client's credentials  */
	private string username;
	private string password;

	/* If the connection is active */
	private bool isActive = true;

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

	public Socket getSocket()
	{
		return clientConnection;
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
		return username ~ "@" ~ clientConnection.remoteAddress().toAddrString();
	}

	public string[] getCredentials()
	{
		return [username, password];
	}

	/* Read/send loop */
	private void run()
	{
		debugPrint("<<< Begin read/send loop >>>");
		while(isActive) /*TODO: Remove and also make the stting of this kak not be closing socket */
		{
			/* Received JSON message */
			JSONValue receivedMessage;

			/* Attempt to receive a message */
			try
			{
				/* Receive a message */
				receiveMessage(clientConnection, receivedMessage);

				/**
				* If the message was received successfully then
				* process the message. */
				processMessage(receivedMessage);

				/* Check if this is a server connection, if so, end the connection */
				if(connectionType == Scope.SERVER)
				{
					debugPrint("Server connection done, closing BesterConnection.");
					isActive = false;
				}
			}
			catch(BesterException exception)
			{
				debugPrint("Error in read/write loop: " ~ exception.toString());
				break;
			}
		}
		debugPrint("<<< End read/send loop >>>");

		clientConnection.close();
		/* TODO: Remove myself from the connections array */
	}

	/**
	 * Destructor for BesterConnection
	 *
	 * Upon the client disconnecting, the only reference to
	 * this object should be through the `connections` array
	 * in the instance of BesterServer but because that will
	 * be removed in the end of the `run` function call.
	 *
	 * And because the thread ends thereafter, there will be
	 * no reference there either.
	 *
	 * Only then will this function be called by the garbage-
	 * collector, this will provide the remaining clean ups.
	 */
	~this()
	{
		debugPrint("Destructor for \"" ~ this.toString() ~ "\" running...");

		/* Close the socket to the client */
		clientConnection.close();
		debugPrint("Closed socket to client");

		debugPrint("Destructor finished");
	}

	/* TODO: Comment [], rename [] */
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
				isActive = false;
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
				/* Provide the handler the message and let it process it and send us a reply */
				HandlerResponse handlerResponse = chosenHandler.handleMessage(payloadData);

				/* TODO: Continue here, we will make all error handling do on construction as to make this all more compact */
				debugPrint("<<< Message Handler [" ~ chosenHandler.getPluginName() ~ "] response >>>\n\n" ~ handlerResponse.toString());

				/* Execute the message handler's command (as per its reply) */
				handlerResponse.execute(this);
			}
			catch(ResponseError e)
			{
				/* In the case of an error with the message handler, send an error to the client/server */
				
				/* TODO: Send error here */
				//JSONValue errorResponse;
				//errorResponse["dd"] = 2;
				//debugPrint("Response error");
			}
			catch(Exception e)
			{
				/* TODO: Remove me */
				debugPrint("fhjhfsdjhfdjhgsdkjh UUUUH:" ~e.toString());
			}
			
			debugPrint("Handler section done (for client)");
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

					/* TODO: End this here */
					isActive = false;
				}
				else if(scopeField == Scope.CLIENT)
				{
					/**
					 * If the host-provided `scope` field is `Scope.CLIENT`
					 * then we must attempt authentication, if it fails
					 * send the client a message back and then close the
					 * connection.
					 */
					debugPrint("Client scope enabled");

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
						isActive = false;
					}
				}
				else if(scopeField == Scope.SERVER)
				{
					debugPrint("Server scope enabled");
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

			/* TODO: Catch error here and not inside dispatchMessage, gets rid of the need for this if statement */	
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
		/* If the attempt to convert the message to JSON fails */
		catch(JSONException exception)
		{
			debugPrint("<<< There was an error whilst parsing the JSON message >>>\n\n"~exception.toString());
		}
	}
}