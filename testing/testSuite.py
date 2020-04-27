
import socket
import json

def basicTest():
    d=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    d.connect(("127.0.0.1",2223))

    # First do it and authenticate
    bys=json.dumps({"header":{"authentication":{"username":"tbk", "password":"passwd"}, "scope":"client"},"payload":{"data":"ABBA","type":"type1"}})
    print(len(bys), bys)
    d.send(len(bys).to_bytes(4, "little"))
    d.send(bys.encode())

    length=int.from_bytes(list(d.recv(4)), "little")
    print(length)
    receivedData = list(d.recv(length))
    print(receivedData)

    # Now we can do it again (without authentication)
    bys=json.dumps({"header":{},"payload":{"data":"POES","type":"type1"}})
    print(len(bys), bys)
    d.send(len(bys).to_bytes(4, "little"))
    d.send(bys.encode())

    while True: pass
    d.close()

def commandBuiltInClose():
    d=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    d.connect(("127.0.0.1",2221))
    bys=json.dumps({"header": {"scope" : "client"},"payload": {
    "data": {
        "command" : {"type" : "close", "args" : None}
    },"type":"builtin"}})
    print(bys)
    d.send(len(bys).to_bytes(4, "little"))
    d.send(bys.encode())
    d.close()

def commandAuthTest():
    d=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    d.connect(("127.0.0.1",2221))
    bys=json.dumps({"header": {"scope" : "client"},"payload": {
    "data": {
        "command" : {"type" : "login", "args" : {"username" :"1", "password":"2"}}
    },"type":"builtin"}})
    print(bys)
    d.send(len(bys).to_bytes(4, "little"))
    d.send(bys.encode())
    d.close()



def simpleTest():
    d=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    d.connect(("127.0.0.1",2224))
    bys=json.dumps({"name":1})
    print(bys)
    d.send(len(bys).to_bytes(4, "little"))
    d.send(bys.encode())
    while True: pass
    d.close()


def runTests():
    #simpleTest()
    #commandBuiltInClose()
    #commandAuthTest()
    basicTest()

runTests()