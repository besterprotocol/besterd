module utils.message;

import std.socket : Socket, SocketFlags;
import std.json : JSONValue, parseJSON, toJSON;
import utils.debugging : debugPrint;
import std.stdio : writeln;
import base.net : NetworkException;
import bmessage : bformatreceiveMessage = receiveMessage, bformatsendMessage = sendMessage;

/**
 * Generalized socket receive function which will read into the
 * variable pointed to by `receiveMessage` by reading from the
 * socket `originator`.
 */
public void receiveMessage(Socket originator, ref JSONValue receiveMessage)
{
	/* The received bytes */
	byte[] receivedBytes;

	if(!bformatreceiveMessage(originator, receivedBytes))
	{
		throw new NetworkException(originator);
	}

	receiveMessage = parseJSON(cast(string)receivedBytes);
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
public void sendMessage(Socket recipient, JSONValue jsonMessage)
{
	if(!bformatsendMessage(recipient, cast(byte[])toJSON(jsonMessage)))
	{
		throw new NetworkException(recipient);
	}
}


/* TODO: Hash message: Next-gen implementation */