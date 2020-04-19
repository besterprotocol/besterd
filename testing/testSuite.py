
import socket
import json

def basicTest():
    d=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    d.connect(("127.0.0.1",2223))
    bys=json.dumps({"header":{"authentication":{"username":"tbk", "password":"passwd"}, "scope":"client"},"payload":{"data":"ABBA","type":"type1"}})
    print(bys)
    d.send(bytes([len(bys),0,0,0]))
    d.send(bys.encode())
    d.close()

def basicTest2():
    d=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    d.connect(("127.0.0.1",2223))
    bys=json.dumps({"header": {"scope" : "client"},"payload": {
    "data": {
        "command" : {"type" : "close", "command" : None}
    },"type":"builtin"}})
    print(bys)
    d.send(bytes([len(bys),0,0,0]))
    d.send(bys.encode())
    d.close()



def simpleTest():
    d=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    d.connect(("127.0.0.1",2224))
    bys=json.dumps({"name":1})
    print(bys)
    d.send(bytes([len(bys),0,0,0]))
    d.send(bys.encode())
    while True: pass
    d.close()


def runTests():
    #simpleTest()
    basicTest()
    basicTest2()

runTests()