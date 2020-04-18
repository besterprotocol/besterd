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
		}
	}

	/* Authenticate the user */
	public bool authenticate(string username, string password)
	{
		/* TODO: Implement me */
		debugPrint("Attempting to authenticate:\n\nUsername: " ~ username ~ "\nPassword: " ~ password);
		return true;
	}
}

private class BesterConnection : Thread
{

	/* The socket to the client */
	private Socket clientConnection;

	/* The server backend */
	private BesterServer server;

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
				/* Receive 20 bytes (at most) at a time */
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

		/* Lookup the payloadType handler */
		MessageHandler chosenHandler;

		for(uint i = 0; i < server.handlers.length; i++)
		{
			if(cmp(server.handlers[i].getPluginName(), payloadType))
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
			

			/* TODO: Get response */
			debugPrint("Waiting for response from handler for \"" ~ chosenHandler.getPluginName() ~ "\".");
		}
		else
		{
			/* TODO: Error handling */
			debugPrint("No message handler for payload type \"" ~ payloadType ~ "\" found.");
		}
		
		/* TODO: Set return value */
		return true;
	}

	/* Process the received message */
	private void processMessage(byte[] messageBuffer)
	{
		/* The message as a JSONValue struct */
		JSONValue jsonMessage;
		
		try
		{
			/* Convert message to JSON */
			jsonMessage = parseJSON(cast(string)messageBuffer);
			writeln("JSON received: ", jsonMessage);
			
			/* Make sure we have a JSON object */
			if(jsonMessage.type == JSONType.object)
			{
				/* As per spec, look for the "besterHeader" */
				JSONValue besterHeader;
			
				/* TODO: Check for out of bounds here */
				besterHeader = jsonMessage["header"];

				/* Check if it is a JSON object */
				if(besterHeader.type == JSONType.object)
				{
					/* TODO: Add further checks here */

					/* TODO: Bounds check */
					JSONValue payloadType;

					payloadType = besterHeader["type"];

					/* The payload type must be a string */
					if(payloadType.type == JSONType.string)
					{
						string payloadTypeString = payloadType.str;
					
						/* TODO: Move everything into this block */
						/* The header must contain a scope block */
						JSONValue scopeBlock;
						
						/* TODO: Add bounds check */
						scopeBlock = besterHeader["scope"];
						
						/* Make sure the type of the JSON value is string */
						if(scopeBlock.type == JSONType.string)
						{
							/* Get the scope */
							string scopeString = scopeBlock.str;
						
							/* If the message is for client<->server */
							if(cmp(scopeString, "client"))
							{
								debugPrint("Scope: client<->server");
						
								/* The header must contain a authentication JSON object */
								JSONValue authenticationBlock;
												
								/* TODO: Check for out of bounds here */
								authenticationBlock = besterHeader["authentication"];
												
								/* TODO: Bounds check for both below */
								JSONValue username, password;
								username = authenticationBlock["username"];
								password = authenticationBlock["password"];
													
												
								if(username.type == JSONType.string && password.type == JSONType.string)
								{
									/* TODO: Now do some stuff */
						
									/* TODO: Authenticate the user */
									string usernameString = username.str;
									string passwordString = password.str;
									bool isAuthenticated = server.authenticate(usernameString, passwordString);
						
									if(isAuthenticated)
									{
										debugPrint("Authenticated");

										/* Get the payload */
										JSONValue payload;

										/* TODO: Bounds check */
										payload = jsonMessage["payload"];

										/* TODO: Dispatch to the correct message handler */
										dispatch(payloadTypeString, payload);
									}
									else
									{
										/* TODO: Add error handling here */
										debugPrint("Authentication failure");
									}
								}
								else
								{
									/* TODO: Add error handling here */
									debugPrint("Username or password is not a JSON string");
								}
							}
							/* If the message is for server<->server */
							else if(cmp(scopeString, "server"))
							{
								debugPrint("Scope: server<->server");
							}
							else
							{
								/* TODO: Error handling */
								debugPrint("Unknown scope provided");
							}
						}
						else
						{
							/* TODO: Handle error */
							debugPrint("Scope block JSON value not a string");
						}
					}
					else
					{
						/* TODO: Add error handling */
						debugPrint("Type is not of type JSON string");
					}
				}
				else
				{
					/* TODO: Add error handling here */
					debugPrint("Header received was not a JSON object");
				}
			}
			else
			{
				/* TODO: Add error here */
				debugPrint("Did not receive a JSON object");
			}
		}
		catch(JSONException exception)
		{
			/* TODO: Implement this */
			debugPrint("Error parsing the received JSON message: " ~ exception.toString());
		}
	
	}

	
}