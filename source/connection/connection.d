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

	/* Send a message to the user/server */
	public void sendMessage(JSONValue replyMessage)
	{
		/* TODO: Implement me */
	}

	/* Read/send loop */
	private void run()
	{
		while(true)
		{
			/* Receive buffer */
			byte[] buffer;
		
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

	/**
	 * Generalized socket send function which will send the JSON
	 * encoded message, `jsonMessage`, over to the client at the
	 * other end of the socket, `recipient`.
	 *
	 * It gets the length of `jsonMessage` and encodes a 4 byte
	 * message header in little-endian containing the message's
	 * length.
	 */
	public static void sendMessage(Socket recipient, JSONValue jsonMessage)
	{
		/* The message buffer */
		byte[] messageBuffer;

		/* Get the JSON as a string */
		string message = toJSON(jsonMessage);

		/* Encode the 4 byte message length header (little endian) */
		int payloadLength = cast(int)message.length;
		byte* lengthBytes = cast(byte*)&payloadLength;
		messageBuffer ~= *(lengthBytes+0);
		messageBuffer ~= *(lengthBytes+1);
		messageBuffer ~= *(lengthBytes+2);
		messageBuffer ~= *(lengthBytes+3);

		/* Add the message to the buffer */
		messageBuffer ~= cast(byte[])message;

		/* Send the message */
		recipient.send(messageBuffer);
	}

	/* TODO: Implement me */
	/**
	 * Generalized socket receive function which will read into the
	 * variable pointed to by `receiveMessage` by reading from the
	 * socket `originator`.
	 */
	public static void receiveMessage(Socket originator, ref JSONValue receiveMessage)
	{
		/* TODO: Implement me */

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
			bytesReceived = originator.receive(tempBuffer);

			/* If there was an error reading from the socket */
			if(!(bytesReceived > 0))
			{
				/* TODO: Error handling */
				debugPrint("Error receiving from socket");
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
			bytesReceived = originator.receive(tempBuffer, SocketFlags.PEEK);

			/* Check for an error whilst receiving */
			if(!(bytesReceived > 0))
			{
				/* TODO: Error handling */
				debugPrint("Error whilst receiving from socket");
			}
			else
			{
				/* TODO: Make sure we only take [0, messageLength) bytes */
				if(cast(uint)bytesReceived+currentByte > messageLength)
				{
					byte[] remainingBytes;
					remainingBytes.length = messageLength-currentByte;

					originator.receive(remainingBytes);

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

					originator.receive(tempBuffer);
				}
			}
		}

		writeln("Message ", fullMessage);

		/* Set the message in `receiveMessage */
		receiveMessage = parseJSON(cast(string)fullMessage);
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

		/* Check if a handler was found */
		if(chosenHandler)
		{
			/* If a handler for the message type was found */

			/* TODO: Send and receive data here */

			/* Handler's UNIX domain socket */
			/* TODO: Change this call here below (also remove startup connection) */
			Socket handlerSocket = chosenHandler.getNewSocket();
			//writeln(handlerSocket == null);
			debugPrint("chosenHandler.socketPath: " ~ chosenHandler.socketPath);

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
		/* Handler's UNIX domain socket */
		Socket handlerSocket = chosenHandler.getNewSocket();


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
