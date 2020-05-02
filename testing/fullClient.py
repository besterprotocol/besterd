import socket
import json

serverAddress=""
serverPort=0
username=""

def initialize():
    server = input("Enter Bester server URL: ")
    globals()["serverAddress"] = server.split(":")[0]
    globals()["serverPort"] = int(server.split(":")[1])
    globals()["username"] = input("Enter your username to authenticate as: ")


# TODO: Implement a test of `close`
def testBuiltInCommands():
     # Connect to the bester daemon
    clientSock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    clientSock.connect((serverAddress, serverPort))
   
    # Authenticate with the first command being `close`
    jsonData = json.dumps({"header": {"scope" : "client"},"payload": {
    "data": {
        "command" : {"type" : "close", "args" : None}
    },"type":"builtin"}})
    print("Sending", jsonData)

    clientSock.send(len(jsonData).to_bytes(4, "little"))
    clientSock.send(jsonData.encode())
    clientSock.close()

# Authenticate and send a built-in command to close
# the connection.
def testBuiltInCommandClose():
    # Connect to the bester daemon
    clientSock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    clientSock.connect((serverAddress, serverPort))

    # Attempt a built-in command even though we are not logged in
    jsonData = json.dumps({
                            "header": {
                                "scope" : "client",
                                "authentication": {
                                    "username" : username,
                                    "password" : "passwd"
                                }
                            },
                            
                            "payload": {
                                "data": {
                                    "command" : {
                                        "type" : "close",
                                        "args" : None
                                    }
                                },
                                "type" : "builtin"
                            }
    })
    print("Sending: ", jsonData)
    clientSock.send(len(jsonData).to_bytes(4, "little"))
    clientSock.send(jsonData.encode())

    # Get a response
    length=int.from_bytes(list(clientSock.recv(4)), "little")
    receivedDataBytes = clientSock.recv(length)
    print("Received", receivedDataBytes.decode())

# Test whether the server responds with an error message
# due to a message being sent without being authenticated
# (as a client).
def testAuthentication():
    # Connect to the bester daemon
    clientSock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    clientSock.connect((serverAddress, serverPort))
    
    # Attempt a built-in command even though we are not logged in
    jsonData = json.dumps({"header": {"scope" : "client"},"payload": {
    "data": {
        "command" : {"type" : "close", "args" : None}
    },"type":"builtin"}})
    print("Sending: ", jsonData)

    # Send the data
    clientSock.send(len(jsonData).to_bytes(4, "little"))
    clientSock.send(jsonData.encode())

    # Get a response
    length=int.from_bytes(list(clientSock.recv(4)), "little")
    receivedDataBytes = clientSock.recv(length)
    print("Received", receivedDataBytes.decode())
    
def testSingleHandler():
    # Connect to the bester daemon
    clientSock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    clientSock.connect((serverAddress, serverPort))

    # Attempt a built-in command even though we are not logged in
    jsonData = json.dumps({
                            "header": {
                                "scope" : "client",
                                "authentication": {
                                    "username" : username,
                                    "password" : "passwd"
                                }
                            },
                            
                            "payload": {
                                "data": "Hello",
                                "type" : "type1"
                            }
    })
    print("Sending: ", jsonData)
    clientSock.send(len(jsonData).to_bytes(4, "little"))
    clientSock.send(jsonData.encode())

    # Get a response
    length=int.from_bytes(list(clientSock.recv(4)), "little")
    receivedDataBytes = clientSock.recv(length)
    print("Received", receivedDataBytes.decode())

def runTests():
    testAuthentication()
    testBuiltInCommandClose()
    testSingleHandler()

initialize()
runTests()