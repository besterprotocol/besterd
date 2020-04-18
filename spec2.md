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

## Flow

### Client

Describes client-to-server and server-to-client communications.

#### `Client -> Server`

If a client wants to send a command through to the server
then the following bytes must be sent:

````
[ 4 bytes (size - little endian)][JSON message]
````

The `[JSON message]` contains information that the server will
use to gain the following information:
	* *Authentication*: Is the user allowed to use this server?
	* *Type*: Which _message handler_ should be responsible for
		processing this message.
	* *Payload*: The data to be processed by the _message handler_.

The structure of the `[JSON message]` is as follows:

````
{
	"header" : {
		"authentication" : {
			"username" : "username",
			"password" : "password"
		}
	},
	"payload" : {
		"type" : "type",
		"data" : ...
	}
}
````

* The `[JSON message]` *MUST* contain two fields, `header` and `payload`
which *MUST* be JSON objects.
* The `header` field *MUST* contain a field named `authentication` which
*MUST* be a JSON object and must contain two fields, `username` and `password`,
which *MUST* be JSON strings.
* The `[JSON message]` *MUST* contain a field named `payload` which *MUST*
be a JSON object and *MUST* contain two fields, `type` and `data`, where
`type` *MUST* be a JSON string and `data` can be any JSON type.

*TODO*

#### `Client <- Server`

*TODO*: But basically anything can go here as it is all in order so you will get your
reply.