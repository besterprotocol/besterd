module server.types;

import utils.debugging : debugPrint;
import std.conv : to;
import std.socket : Socket, AddressFamily, SocketType, ProtocolType, parseAddress, SocketFlags;
import core.thread : Thread;
import std.stdio : writeln, File;
import std.json : JSONValue, parseJSON, JSONException, JSONType;
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
	private MessageHandler handlers;

	/* The server's socket */
	private Socket serverSocket;

	this(string bindAddress, ushort listenPort)
	{
		debugPrint("Binding to address: " ~ bindAddress ~ " and port " ~ to!(string)(listenPort));
		initialize(bindAddress, listenPort);
		debugPrint("Setting up message handlers...");
		//setupHandlers(configurationFile);
	}

	private void loadHandlers(JSONValue handlerBlock)
	{
		/* TODO: Implement me */
		debugPrint("Constructing message handlers...");
		MessageHandler.constructHandlers(handlerBlock);
	}

	private void initialize(string bindAddress, ushort listenPort)
	{
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
			/* Make the dynamic array's size 4 */
			buffer.length = 4;

			/* Read the first 4 bytes (retrieve message size) */
			long bytesReceived = clientConnection.receive(buffer);
			writeln("PreambleWait: Bytes received: ", cast(ulong)bytesReceived);

			/* Make sure exactly 4 bytes were received */
			if (bytesReceived != 4)
			{
				/* If we don't get exactly 4 bytes, drop the client */
				debugPrint("Did not get exactly 4 bytes for preamble, disconnecting client...");
				clientConnection.close();
				break;
			}

			/* Get the message length */
			int messageLength = *(cast(int*)buffer.ptr);
			writeln("Message length: ", cast(uint)messageLength);

			/* TODO: Testing locally ain't good as stuff arrives way too fast, although not as fast as I can type */
			/* What must happen is a loop to loop and wait for data */

			/* Full message buffer */
			byte[] messageBuffer;


			/* TODO: Add timeout if we haven't received a message in a certain amount of time */
			
			uint currentByte = 0;
			while(currentByte < cast(uint)messageLength)
			{
				/* Receive 20 bytes (at most) at a time */
				byte[20] messageBufferPartial;
				bytesReceived = clientConnection.receive(messageBufferPartial);

				/* Append the received bytes to the FULL message buffer */
				messageBuffer ~= messageBufferPartial[0..bytesReceived];

				/* TODO: Bug when over send, we must not allow this */

				/* Increment counter of received bytes */
				currentByte += bytesReceived;
				writeln("Received ", currentByte, "/", cast(uint)messageLength, " bytes");
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

		/* TODO: Lookup the payloadType handler */
		
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