module server.types;

import utils.debugging : debugPrint;
import std.conv : to;
import std.socket : Socket, AddressFamily, SocketType, ProtocolType, parseAddress, SocketFlags;
import core.thread : Thread;
import std.stdio : writeln, File;
import std.json : JSONValue, parseJSON, JSONException, JSONType, toJSON;
import std.string : cmp;
import server.handler;

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

	/* Connected clients */
	private BesterConnection[] clients;

	this(JSONValue config)
	{

		/* TODO: Bounds check and JSON type check */
		debugPrint("Setting up socket...");
		setupServerSocket(config["network"]);

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
		serverSocket.listen(1); /* TODO: This value */
		debugPrint("Server listen loop started");
		while(true)
		{
			/* Wait for an incoming connection */
			Socket clientConnection = serverSocket.accept();

			/* Create a new client connection handler and start its thread */
			BesterConnection besterConnection = new BesterConnection(clientConnection, this);
			besterConnection.start();

			/* Add this client to the list of connected clients */
			clients ~= besterConnection;
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

private class BesterConnection : Thread
{

	/* The socket to the client */
	private Socket clientConnection;

	/* The server backend */
	private BesterServer server;

	/* The client's credentials  */
	private string authUsername;
	private string authPassword;

	this(Socket clientConnection, BesterServer server)
	{
		/* Save socket and set thread worker function pointer */
		super(&run);
		this.clientConnection = clientConnection;
		this.server = server;

		debugPrint("New client handler spawned for " ~ clientConnection.remoteAddress().toAddrString());
	}

	/* Read/send loop */
	private void run()
	{
		/* Receive buffer */
		byte[] buffer;

		while(true)
		{
			/* Byte counter for loop-consumer */
			uint currentByte = 0;

			/* Bytes received counter */
			long bytesReceived;
			
			/* TODO: Add fix here to loop for bytes */
			while(currentByte < 4)
			{
				/* Size buffer */
				byte[4] tempBuffer;
				
				/* Read at most 4 bytes */
				bytesReceived = clientConnection.receive(tempBuffer);

				if(!(bytesReceived > 0))
				{
					/* TODO: Handle error here */
					debugPrint("Error with receiving");
					return;
				}
				else
				{
					/**
					 * Read the bytes from the temp buffer (as many as was received)
					 * and append them to the *real* buffer.
					 */
					buffer ~= tempBuffer[0..bytesReceived];
						
					/* Increment the byte counter */
					currentByte += bytesReceived;	
				}
			}
			
			/* Get the message length */
			int messageLength = *(cast(int*)buffer.ptr);
			writeln("Message length: ", cast(uint)messageLength);

			/* TODO: Testing locally ain't good as stuff arrives way too fast, although not as fast as I can type */
			/* What must happen is a loop to loop and wait for data */

			/* Full message buffer */
			byte[] messageBuffer;


			/* TODO: Add timeout if we haven't received a message in a certain amount of time */

			/* Reset the current byte counter */
			currentByte = 0;
			
			while(currentByte < messageLength)
			{
				/**
				 * Receive 20 bytes (at most) at a time and don't dequeue from
				 * the kernel's TCP stack's buffer.
				 */
				byte[20] messageBufferPartial;
				bytesReceived = clientConnection.receive(messageBufferPartial, SocketFlags.PEEK);

				/* Check for receive error */
				if(!(bytesReceived > 0))
				{
					debugPrint("Error receiving");
					return;
				}
				else
				{
					/* TODO: Make sure we only take [0, messageLength) bytes */
					if(cast(uint)bytesReceived+currentByte > messageLength)
					{
						byte[] remainingBytes;
						remainingBytes.length = messageLength-currentByte;

						clientConnection.receive(remainingBytes);

						/* Increment counter of received bytes */
						currentByte += remainingBytes.length;

						/* Append the received bytes to the FULL message buffer */
						messageBuffer ~= remainingBytes;

						writeln("Received ", currentByte, "/", cast(uint)messageLength, " bytes");
					}
					else
					{
						/* Increment counter of received bytes */
						currentByte += bytesReceived;

						
						/* Append the received bytes to the FULL message buffer */
						messageBuffer ~= messageBufferPartial[0..bytesReceived];

						/* TODO: Bug when over send, we must not allow this */

						
						writeln("Received ", currentByte, "/", cast(uint)messageLength, " bytes");	

						clientConnection.receive(messageBufferPartial);
					}

					
				}
			}

			/* Process the message */
			processMessage(messageBuffer);
		}
	}

	/* TODO: Pass in type and just payload or what */
	private bool dispatch(string payloadType, JSONValue payload)
	{
		/* TODO: Implement me */
		debugPrint("Dispatching payload [" ~ payloadType ~ "]");
		debugPrint("Payload: " ~ payload.toPrettyString());

		/* Status of dispatch */
		bool dispatchStatus = true;

		/* Lookup the payloadType handler */
		MessageHandler chosenHandler;

		for(uint i = 0; i < server.handlers.length; i++)
		{
			if(cmp(server.handlers[i].getPluginName(), payloadType) == 0)
			{
				chosenHandler = server.handlers[i];
				break;
			}
		}

		

		if(chosenHandler)
		{
			/* TODO: Send and receive data here */

			/* Handler's UNIX domain socket */
			Socket handlerSocket = chosenHandler.getSocket();


			/* Get the payload as a string */
			string payloadString = toJSON(payload);
			

			/* Construct the data to send */
			byte[] sendBuffer;
	
			/* TODO: Add 4 bytes of payload length encded in little endian */
			int payloadLength = cast(int)payloadString.length;
			byte* lengthBytes = cast(byte*)&payloadLength;
			sendBuffer ~= *(lengthBytes+0);
			sendBuffer ~= *(lengthBytes+1);
			sendBuffer ~= *(lengthBytes+2);
			sendBuffer ~= *(lengthBytes+3);

			/* Add the string bytes */
			sendBuffer ~= cast(byte[])payloadString;

			/* TODO: Send payload */
			writeln("Send buffer: ", sendBuffer);
			
			debugPrint("Sending payload over to handler for \"" ~ chosenHandler.getPluginName() ~ "\".");
			handlerSocket.send(sendBuffer);
			

			/* TODO: Get response */
			debugPrint("Waiting for response from handler for \"" ~ chosenHandler.getPluginName() ~ "\".");

			/* Construct a buffer to receive into */
			byte[] receiveBuffer;

			/* The current byte */
			uint currentByte = 0;

			/* The amount of bytes received */
			long bytesReceived;

			/* Loop consume the next 4 bytes */
			while(currentByte < 4)
			{
				/* Temporary buffer */
				byte[4] tempBuffer;

				/* Read at-most 4 bytes */
				bytesReceived = handlerSocket.receive(tempBuffer);

				/* If there was an error reading from the socket */
				if(!(bytesReceived > 0))
				{
					/* TODO: Error handling */
					debugPrint("Error receiving from UNIX domain socket");
				}
				/* If there is no error reading from the socket */
				else
				{
					/* Add the read bytes to the *real* buffer */
					receiveBuffer ~= tempBuffer[0..bytesReceived];

					/* Increment the byte counter */
					currentByte += bytesReceived;
				}
			}

			/* Response message length */
			int messageLength = *cast(int*)receiveBuffer.ptr;
			writeln("Message length is: ", cast(uint)messageLength);

			/* Response message buffer */
			byte[] fullMessage;

			/* Reset the byte counter */
			currentByte = 0;

			while(currentByte < messageLength)
			{
				debugPrint("dhjkh");

				/**
				 * Receive 20 bytes (at most) at a time and don't dequeue from
				 * the kernel's TCP stack's buffer.
				 */
				byte[20] tempBuffer;
				bytesReceived = handlerSocket.receive(tempBuffer, SocketFlags.PEEK);

				/* Check for an error whilst receiving */
				if(!(bytesReceived > 0))
				{
					/* TODO: Error handling */
					debugPrint("Error whilst receiving from unix domain socket");
				}
				else
				{
					/* TODO: Make sure we only take [0, messageLength) bytes */
					if(cast(uint)bytesReceived+currentByte > messageLength)
					{
						byte[] remainingBytes;
						remainingBytes.length = messageLength-currentByte;

						handlerSocket.receive(remainingBytes);

						/* Increment counter of received bytes */
						currentByte += remainingBytes.length;

						/* Append the received bytes to the FULL message buffer */
						fullMessage ~= remainingBytes;

						writeln("Received ", currentByte, "/", cast(uint)messageLength, " bytes");
					}
					else
					{
						/* Increment counter of received bytes */
						currentByte += bytesReceived;

						
						/* Append the received bytes to the FULL message buffer */
						fullMessage ~= tempBuffer[0..bytesReceived];

						/* TODO: Bug when over send, we must not allow this */

						
						writeln("Received ", currentByte, "/", cast(uint)messageLength, " bytes");	

						handlerSocket.receive(tempBuffer);
					}
				}
			}


			writeln("MEssage ", fullMessage);

			//int messageLength = 0;

			/* TODO: Loop for collect message */

			/* TODO: So now we have to think about what the hell it means
			 * for a response to be received, like cool and all, but we need
			 * the server to now do something.
			 */


			/* TODO: Set dispatchStatus */
		}
		else
		{
			/* TODO: Error handling */
			debugPrint("No message handler for payload type \"" ~ payloadType ~ "\" found.");
			dispatchStatus = false;
		}
		
		/* TODO: Set return value */
		debugPrint("Dispatch status: " ~ to!(string)(dispatchStatus));

		return dispatchStatus;
	}


	private JSONValue handlerRun(MessageHandler chosenHandler, JSONValue payload)
	{
		/* TODO: Send and receive data here */
		
					/* Handler's UNIX domain socket */
					Socket handlerSocket = chosenHandler.getSocket();
		
		
					/* Get the payload as a string */
					string payloadString = toJSON(payload);
					
		
					/* Construct the data to send */
					byte[] sendBuffer;
			
					/* TODO: Add 4 bytes of payload length encded in little endian */
					int payloadLength = cast(int)payloadString.length;
					byte* lengthBytes = cast(byte*)&payloadLength;
					sendBuffer ~= *(lengthBytes+0);
					sendBuffer ~= *(lengthBytes+1);
					sendBuffer ~= *(lengthBytes+2);
					sendBuffer ~= *(lengthBytes+3);
		
					/* Add the string bytes */
					sendBuffer ~= cast(byte[])payloadString;
		
					/* TODO: Send payload */
					writeln("Send buffer: ", sendBuffer);
					
					debugPrint("Sending payload over to handler for \"" ~ chosenHandler.getPluginName() ~ "\".");
					handlerSocket.send(sendBuffer);
					
		
					/* TODO: Get response */
					debugPrint("Waiting for response from handler for \"" ~ chosenHandler.getPluginName() ~ "\".");
		
					/* Construct a buffer to receive into */
					byte[] receiveBuffer;
		
					/* The current byte */
					uint currentByte = 0;
		
					/* The amount of bytes received */
					long bytesReceived;
		
					/* Loop consume the next 4 bytes */
					while(currentByte < 4)
					{
						/* Temporary buffer */
						byte[4] tempBuffer;
		
						/* Read at-most 4 bytes */
						bytesReceived = handlerSocket.receive(tempBuffer);
		
						/* If there was an error reading from the socket */
						if(!(bytesReceived > 0))
						{
							/* TODO: Error handling */
							debugPrint("Error receiving from UNIX domain socket");
						}
						/* If there is no error reading from the socket */
						else
						{
							/* Add the read bytes to the *real* buffer */
							receiveBuffer ~= tempBuffer[0..bytesReceived];
		
							/* Increment the byte counter */
							currentByte += bytesReceived;
						}
					}
		
					/* Response message length */
					int messageLength = *cast(int*)receiveBuffer.ptr;
					writeln("Message length is: ", cast(uint)messageLength);
		
					/* Response message buffer */
					byte[] fullMessage;
		
					/* Reset the byte counter */
					currentByte = 0;
		
					while(currentByte < messageLength)
					{
						debugPrint("dhjkh");
		
						/**
						 * Receive 20 bytes (at most) at a time and don't dequeue from
						 * the kernel's TCP stack's buffer.
						 */
						byte[20] tempBuffer;
						bytesReceived = handlerSocket.receive(tempBuffer, SocketFlags.PEEK);
		
						/* Check for an error whilst receiving */
						if(!(bytesReceived > 0))
						{
							/* TODO: Error handling */
							debugPrint("Error whilst receiving from unix domain socket");
						}
						else
						{
							/* TODO: Make sure we only take [0, messageLength) bytes */
							if(cast(uint)bytesReceived+currentByte > messageLength)
							{
								byte[] remainingBytes;
								remainingBytes.length = messageLength-currentByte;
		
								handlerSocket.receive(remainingBytes);
		
								/* Increment counter of received bytes */
								currentByte += remainingBytes.length;
		
								/* Append the received bytes to the FULL message buffer */
								fullMessage ~= remainingBytes;
		
								writeln("Received ", currentByte, "/", cast(uint)messageLength, " bytes");
							}
							else
							{
								/* Increment counter of received bytes */
								currentByte += bytesReceived;
		
								
								/* Append the received bytes to the FULL message buffer */
								fullMessage ~= tempBuffer[0..bytesReceived];
		
								/* TODO: Bug when over send, we must not allow this */
		
								
								writeln("Received ", currentByte, "/", cast(uint)messageLength, " bytes");	
		
								handlerSocket.receive(tempBuffer);
							}
						}
					}
		
		
					writeln("MEssage ", fullMessage);
		
					//int messageLength = 0;
		
					/* TODO: Loop for collect message */
		
					/* TODO: So now we have to think about what the hell it means
					 * for a response to be received, like cool and all, but we need
					 * the server to now do something.
					 */
		
		
					/* TODO: Set dispatchStatus */

					return parseJSON(cast(string)fullMessage);
	}

	/**
	 * Handles the response sent back to the server from the
	 * message handler.
	 */
	private bool handleResponse(JSONValue handlerResponse)
	{
		/* TODO: Bounds checking, type checking */
		try
		{
			/* Get the header block */
			JSONValue headerBlock = handlerResponse["header"];

			/* Get the status */
			ulong statusCode = to!(ulong)(headerBlock["status"].str);
			debugPrint("Status code: " ~ to!(string)(statusCode));

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
		catch(JSONException exception)
		{
			debugPrint("<<< There was an error handling the response message >>>\n\n" ~ exception.toString());
			return false;
		}

		return true;
	}

	public enum Scope
	{
		CLIENT,
		SERVER,
		UNKNOWN
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
			JSONValue command = commandBlock["command"];

			/* Check if the command is the `login` */
			if(cmp(commandType, "login") == 0)
			{
				debugPrint("User wants to login");
			}
			//if(cmp(payloadType))
		}
		/* If an external handler is found (i.e. not a built-in command) */
		else if(chosenHandler)
		{
			/* TODO: Implement me */
			debugPrint("Chosen handler for payload type \"" ~ payloadType ~ "\" is " ~ chosenHandler.getPluginName());

			/* TODO: Collect return value */
			JSONValue response = handlerRun(chosenHandler, payloadData);
			debugPrint("<<< Message Handler [" ~ chosenHandler.getPluginName() ~ "] response >>>\n\n" ~ response.toPrettyString());

			/* TODO: Handle response */
			handleResponse(response);
		}
		else
		{
			/* TODO: Implement error handling */
			debugPrint("No handler available for payload type \"" ~ payloadType ~ "\"");
		}

		return dispatchStatus;
	}
	

	/* Process the received message */
	private void processMessage(byte[] messageBuffer)
	{
		/* The message as a JSONValue struct */
		JSONValue jsonMessage;


		/* Attempt to convert the message to JSON */
		try
		{
			/* Convert message to JSON */
			jsonMessage = parseJSON(cast(string)messageBuffer);
			debugPrint("<<< Received JSON >>>\n\n" ~ jsonMessage.toPrettyString());

			/* TODO: Bounds checking, type checking */

			/* Get the header */
			JSONValue headerBlock = jsonMessage["header"];

			/* Get the scope of the message */
			Scope scopeField;
			if(cmp(headerBlock["scope"].str, "client") == 0)
			{
				scopeField = Scope.CLIENT;
			}
			else if(cmp(headerBlock["scope"].str, "server") == 0)
			{
				scopeField = Scope.CLIENT;
			}
			else
			{
				scopeField = Scope.UNKNOWN;
			}
									
			
			/* Get the payload block */
			JSONValue payloadBlock = jsonMessage["payload"];
			debugPrint("<<< Payload is >>>\n\n" ~ payloadBlock.toPrettyString());

			/* If the communication is client->server */
			if(scopeField == Scope.CLIENT)
			{
				debugPrint("Client to server selected");

				/* Get the authentication block */
				JSONValue authenticationBlock = headerBlock["authentication"];
				
				/* Get the username and password */
				string username = authenticationBlock["username"].str, password = authenticationBlock["password"].str;
				
				/* Authenticate the user */
				bool authenticationStatus = server.authenticate(username, password);
				debugPrint("Authentication status: " ~ to!(string)(authenticationStatus));
				
				/* If the authentication succeeded */
				if(!authenticationStatus)
				{
					/* TODO: Error handling */
					return;
				}
			}
			/* If the communication is server->server */
			else if(scopeField == Scope.SERVER)
			{
				debugPrint("Server to server selected");

				/* TODO: Implement me */	
					
			}
			else
			{
				/* TODO: Error handling */
				debugPrint("Unknown scope selected \"" ~ to!(string)(cast(uint)scopeField) ~ "\"");
				return;
			}

			/* Dispatch the message */
			bool dispatchStatus = dispatchMessage(scopeField, payloadBlock);
								
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