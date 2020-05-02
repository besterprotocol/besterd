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

def listen():
    # Connect to the bester daemon
    clientSock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    clientSock.connect((serverAddress, serverPort))

    # First authenticate (to be put into the connection queue)
    jsonMessage = json.dumps({"header":{"authentication":{"username":username, "password":"passwd"}, "scope":"client"},"payload":{"data":{"bruhMsg":"fhdjhgfhjd"},"type":"null"}})
    print(len(jsonMessage), jsonMessage)
    clientSock.send(len(jsonMessage).to_bytes(4, "little"))
    clientSock.send(jsonMessage.encode())

    # Loop and listen
    while True:
        length=int.from_bytes(list(clientSock.recv(4)), "little")
        print(length)
        receivedDataBytes = clientSock.recv(length)
        receivedData = list(receivedDataBytes)
        print(receivedDataBytes.decode())

    clientSock.close()

initialize()
listen()