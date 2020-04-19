import socket
import json

def runTest():
    d=socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    d.bind("../aSock")
    d.listen()
    while True:
        s = d.accept()[0]
        print(list(s.recv(130)))
        bys = json.dumps({
            "header" : {
                "status" : "0",
                "command" : {"type" : "sendClients", "data": ["usr1", "usr2"]}
            } })
        print(s.send(bytes([len(bys),0,0,0])))
        print(s.send(bys.encode()))

    while True: pass

runTest()