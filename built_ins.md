Built-ins
=========

## `login`

If the `type` field of the `command` JSON object (inside the `data` field
of the `payload` JSON object) is set to `"login"` then the `command` field
within the `command` JSOB object must look like such:

````
"command" : {
	"username" : "<username>",
	"password" : "<password>"
}
````

in context of... *TODO*:

````
```