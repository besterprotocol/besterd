import socket
import json

serverAddress=""
serverPort=0
username=""

def initialize():
    server = input("Enter Bester server URL: ")
    globals()["serverAddress"] = server.split(":")[0]
    globals()["serverPort"] = int(server.split(":")[1])
    username = input("Enter your username to authenticate as: ")


# TODO: Implement a test of `close`
def testBuiltInCommands():
    pass

# Test whether the server responds with an error message
# due to a message being sent without being authenticated
# (as a client).
def testAuthentication():
    # Connect to the bester daemon
    clientSock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    print(serverAddress)
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
    


def runTests():
    testAuthentication()
    testBuiltInCommands()

initialize()
runTests()