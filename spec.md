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

The `header` field *MUST* contain a field of which is a JSON
string, `type`.

Received message:

````
"header" : {
	"authentication" : {},
	"type" : "type"
}
````

The `authentication` field *MUST* be a JSON object and must contain
two fields `username` and `password` which *MUST* both be JSON strings.

The `type` field *MUST* be a JSON string.

Received message:

````
"header" : {
	"authentication" : {
		"username" : "username",
		"password" : "password"
	},
	"type" : "type"
}
````