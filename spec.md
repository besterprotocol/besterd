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