Spec v2
=======

## What does it entail?

1. The *client*
	* The client connects to the server and sends commands
	to it.
2. The *server*
	* The server receives commands from the client and 
	dispatches them to the respective message handler,
	waits for a reply and then either sends the reply
	to a client (originator or otherwise) or another
	server.
3. The *message handler*
	* Receives commands from the client indirectly (via
	the server), processes them and then sends a response
	back to the server (as implied above, who the reply
	is sent to is decided by the message handler and the
	server will act accordingly)