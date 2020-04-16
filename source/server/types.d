module server.types;

import utils.debugging : debugPrint;
import std.conv : to;
import std.socket : Socket, AddressFamily, SocketType, ProtocolType, parseAddress, SocketFlags;
import core.thread : Thread;
import std.stdio : writeln;

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


			uint currentByte = 0;
			while(currentByte < cast(uint)messageLength)
			{
				/* Receive 20 bytes (at most) at a time */
				byte[20] messageBufferPartial;
				bytesReceived = clientConnection.receive(messageBufferPartial);

				/* Append the received bytes to the FULL message buffer */
				messageBuffer ~= messageBufferPartial[0..bytesReceived];

				/* Increment counter of received bytes */
				currentByte += bytesReceived;
			}


		}
	}

	
}