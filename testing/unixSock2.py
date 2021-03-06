#!/bin/python3

import socket
import json

def runTest():
    d=socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    d.bind("../aSock")
    d.listen()
    while True:
        print("Waiting for connection to (this) handler...")
        s = d.accept()[0]

        size=int.from_bytes(s.recv(4), "little")
        receivedBys = json.loads(s.recv(size).decode())
        print(receivedBys)
        bys = json.dumps({
            "header" : {
                "status" : "0",
                "command" : {"type" : "sendClients", "data": ["tbk", "skippy"]}
            }, "data" : receivedBys })
        print(s.send(len(bys).to_bytes(4, "little")))
        print(s.send(bys.encode()))
        print("Connection to (this) handler finished")

    while True: pass

runTest()