Bester protocol - Specification
===============================

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

## Protocol flow

### Client and Server

Describes client-to-server and server-to-client communications.

<hr>

#### Client -> Server

If a client wants to send a command through to the server
then the following bytes must be sent:

````
[ 4 bytes (size - little endian)][JSON message]
````

The `[JSON message]` contains information that the server will
use to gain the following information:
	* *Authentication*: Is the user allowed to use this server?
	* *Scope*: Is this a client-to-server of server-to-server
		communication?
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
		},
		"scope" : "client"
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
which *MUST* be JSON strings. The `header` field *MUST* also contain a field
named `scope` which *MUST* be a JSON string (and in this case must be equal
to `"client"`).
* The `[JSON message]` *MUST* contain a field named `payload` which *MUST*
be a JSON object and *MUST* contain two fields, `type` and `data`, where
`type` *MUST* be a JSON string and `data` can be any JSON type.

##### Note on authentication

It should be noted that the `authentication` block need only be transmitted the as the first message sent to the server (as to authenticate the user's self), after this it is never checked and can contain bogus data or be omitted entirely.

Authentication is not required when the `scope` field is set to `"server"` as then the communication is server-to-server and not client-to-server.

<hr>

#### Client <- Server

If a server wants to reply to a client (that just sent a message to it) then
the following bytes must be sent to the client:

````
[ 4 bytes (size - little endian)][JSON message]
````

The `[JSON message]` contains information that the client will
use to gain the following information:
	* *Status*: Did the command sent prior to this response
		run successfully?
	* *Payload*: The data to be processed by the _client_.

The structure of the `[JSON message]` is as follows:

````
{
	"header" : {
		"status" : "status"
	},
	"payload" : {
		"data" : ...,
		"type" : "<type/handlerName>"
	}
}
````

The interpretation of the entirety of the `[JSON message]` is up
to the client but the client *SHOULD* expect and interpret as
follows:

* There is a field called `header` which is a JSON object and
*SHOULD* be inetrpreted as such. Within it there is a field
called `status` which is a JSON string and *SHOULD* be interpreted
as such.
* There is a field  called `payload` which *MUST* contain two fields, `data` and `type`.
* The `data` field is of a JSON type up to
the _message handler_ and *SHOULD* be interpreted in accordance to
its (the _message handler_'s) rules.
* The `type` field *MUST* be a string an will contain the name of the _message handler_ that generated this response.

### Server and Message Handler

Describes server-to-message-handler and message-handler-to-server communications.

<hr>

#### Server -> Message Handler

If the server receives a message from the client and then checks the `type` field of the message as to determine what handler should run it, then the server will send the payload to the handler in the following format:

````
[4 bytes (size - little endian)][JSON message]
````

The `[JSON message]` contains the following information:

* The `data` field which indicates the payload to be sent to the handler.

There is not format really. The server get's a JSON payload as described in the [Client -> Server] section and all it does it extracts the JSON object at the field `data`, this then becomes the `[JSON message]` here and is then sent to the message handler as is.

<hr>

#### Message Handler -> Server

If a message handler sends a reply back to the server then the following
bytes should be sent to the server:

````
[ 4 bytes (size - little endian)][JSON message]
````

The `[JSON message]` contains information that the server will
use to gain the following information:
	* *Status*: Did the command sent prior to this response
		run successfully?
	* *Command*: To tell the server what to do with the response.
	* *Payload*: The data to be processed by the _server_.

The structure of the `[JSON message]` is as follows:

````
{
	"header" : {
		"status" : "status",
		"command" : "command",
		"commandData" : ...
	},
	"payload" : {
		"type" : "",
		"data" : ...
	}
}
````

Allowed values for `command` are:
	1. `"sendClients"`: The generated response must be sent to a client(s)
		attached to the local server.
	2. `"sendServers"`: The generated response must be sent to a remote
		server(s).

The above two tell the server where to send the response from the
_message handler_ to. Either it can be sent

The interpretation of the entirety of the `[JSON message]` is up
to the client but the client *SHOULD* expect and interpret as
follows:

* There is a field called `header` which is a JSON object and





## TODO: Built in server commands

TODO: Authentication for users should be a command.

logout, authenticate, change password