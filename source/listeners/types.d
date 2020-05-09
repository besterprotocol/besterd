module listeners.types;

import listeners.listener : BesterListener, BesterListenerException;
import server.server : BesterServer;
import std.socket : Socket, Address, AddressFamily, SocketType, SocketException;

/**
* Represents a stream socket listener over UNIX
* domain sockets.
*/
public final class UNIXListener : BesterListener
{
	this(BesterServer besterServer, Address address)
	{
		super(besterServer);
		try
		{
			setServerSocket(setupUNIXSocket(address));
		}
		catch(SocketException e)
		{
			throw new BesterListenerException(this);
		}	
	}

	private Socket setupUNIXSocket(Address address)
	{
		Socket unixSocket = new Socket(AddressFamily.UNIX, SocketType.STREAM);
		unixSocket.bind(address);
		return unixSocket;
	}

	override public string toString()
	{
		string address = "unix://"~super.address.toAddrString();
		return address;
	}
}

/**
* Represents a stream socket listener over TCP
* on IPv4.
*/
public final class TCP4Listener : BesterListener
{
	this(BesterServer besterServer, Address address)
	{
		super(besterServer);
		try
		{
			setServerSocket(setupTCP4Socket(address));
		}
		catch(SocketException e)
		{
			throw new BesterListenerException(this);
		}
	}

	private Socket setupTCP4Socket(Address address)
	{
		Socket tcp4Socket = new Socket(AddressFamily.INET, SocketType.STREAM);
		tcp4Socket.bind(address);
		return tcp4Socket;
	}

	override public string toString()
	{
		string address = "tcp4://"~super.address.toAddrString()~":"~super.address.toPortString();
		return address;
	}
}

/**
* Represents a stream socket listener over TCP
* on IPv6.
*/
public final class TCP6Listener : BesterListener
{
	this(BesterServer besterServer, Address address)
	{
		super(besterServer);
		try
		{
			setServerSocket(setupTCP6Socket(address));
		}
		catch(SocketException e)
		{
			throw new BesterListenerException(this);
		}
	}

	private Socket setupTCP6Socket(Address address)
	{
		Socket tcp6Socket = new Socket(AddressFamily.INET6, SocketType.STREAM);
		tcp6Socket.bind(address);
		return tcp6Socket;
	}

	override public string toString()
	{
		string address = "tcp6://"~super.address.toAddrString()~":"~super.address.toPortString();
		return address;
	}
}

