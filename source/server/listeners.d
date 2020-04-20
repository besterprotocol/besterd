module server.listeners;

import server.types;
import std.socket : Socket;

public class UNIXListener : BesterListener
{
	this(BesterServer besterServer, string path)
	{
		super(besterServer);
		setServerSocket(setupUNIXSocket(path));
	}

	private Socket setupUNIXSocket(string path)
	{
		Socket unixSocket;

		return unixSocket;
	}
}