module server.types;

import utils.debugging : debugPrint;
import std.conv : to;

public class BesterServer
{

	this(string bindAddress, ushort listenPort)
	{
		debugPrint("Binding to address: " ~ bindAddress ~ " and port " ~ to!(string)(listenPort));
	}
	
}