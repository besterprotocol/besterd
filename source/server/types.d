module server.types;

import utils.debugging : debugPrint;
import std.conv : to;
import std.socket : Socket, AddressFamily, SocketType, ProtocolType;

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
	}

	/* Start listen loop */
	public void run()
	{
		debugPrint("Server listen loop started");
		while(true)
		{
			
		}
	}
	
}