module server.types;

import utils.debugging : debugPrint;
import std.conv : to;
import std.socket : Socket, AddressFamily, SocketType, ProtocolType, parseAddress, SocketFlags;
import core.thread : Thread;
import std.stdio : writeln;
import std.json : JSONValue, parseJSON, JSONException, JSONType;

public class BesterServer
{

	/* The server's socket */
	private Socket serverSocket;

	this(string bindAddress, ushort listenPort)
	{
		debugPrint("Binding to address: " ~ bindAddress ~ " and port " ~ to!(string)(listenPort));
		initialize(bindAddress, listenPort);
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
			BesterConnection besterConnection = new BesterConnection(clientConnection);
			besterConnection.start();
		}
	}
	
}

private class BesterConnection : Thread
{

	/* The socket to the client */
	private Socket clientConnection;

	this(Socket clientConnection)
	{
		/* Save socket and set thread worker function pointer */
		super(&run);
		this.clientConnection = clientConnection;

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
				besterHeader = jsonMessage["besterHeader"];

				/* Check if it is a JSON object */
				if(besterHeader.type == JSONType.object)
				{
					/* TODO: Add further checks here */

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
			debugPrint("Error parsing the received JSON message");
		}
	
	}

	
}