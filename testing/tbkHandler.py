import socket
import json
import os

def runTest():
    os.remove("../aSock")
    
    handlerSock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    handlerSock.bind("../aSock")
    handlerSock.listen()
    while True:
        print("Waiting for connection to (this) handler...")
        serverSock = handlerSock.accept()[0]

        size=int.from_bytes(serverSock.recv(4), "little")
        receivedBys = json.loads(serverSock.recv(size).decode())
        print(receivedBys)
        
        bys = json.dumps({
            "header" : {
                "status" : "0",
                "command" : {"type" : "sendClients", "data": ["tbk", "skippy"]}
            }, "data" : receivedBys })
        print(serverSock.send(len(bys).to_bytes(4, "little")))
        print(serverSock.send(bys.encode()))

runTest()