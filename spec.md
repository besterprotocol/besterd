Bester protocol
===============

## What is bester?

Bester is a protocol for authenticated message-passing in a federated network.

## Protocol

Every message in bester contains the following:

````
[8 bytes - message size][JSON message]
````

### JSON payload

The JSON message *MUST* be a JSON object and *MUST* include
a field named `header`.


Received message:

````
"header" : {
	
}
````

This `header` field *MUST* contain the following fields of which
are JSON objects, `authentication`.

The `header` field *MUST* contain two field of which are of type
JSON string, `scope` and `type`.

Received message:

````
"header" : {
	"scope" : "scope",
	"type" : "type",
	"authentication" : {}
}
````

The `authentication` field *MUST* be a JSON object and must contain
two fields `username` and `password` which *MUST* both be JSON strings.

The `scope` field *MUST* be a JSON string.
The `type` field *MUST* be a JSON string.

Received message:

````
"header" : {
	"scope" : "scope",
	"type" : "type",
	"authentication" : {
		"username" : "username",
		"password" : "password"
	}
}
````

There *MUST* also be a field in the original JSON message named `payload`,
the JSON type doesn't matter.

Received message:

````
"header" : {
	"scope" : "scope",
	"type" : "type",
	"authentication" : {
		"username" : "username",
		"password" : "password"
	}
},
"payload" : anything
````

## Message handling

The way messages are handled depends on their `type`. The way the server deals with it
works like this.

The server configuration looks like this:

````
"handlers" : {
	"availableTypes" : ["type1", "type2"],
	"typeMap" :{
		"type1" : {"handlerBinary" : "aBin", "unixDomainSocketPath" : "aSock"},
		"type2" : {"handlerBinary" : "bBin", "unixDomainSocketPath" : "bSock"}
	}
}
````