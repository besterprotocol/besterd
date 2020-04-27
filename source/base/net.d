module base.net;

import base.types;
import std.socket : Socket;

public class NetworkException : BesterException
{
	this(Socket socketResponsible)
	{
		super("Socket error with: " ~ socketResponsible.remoteAddress().toAddrString());
	}
}