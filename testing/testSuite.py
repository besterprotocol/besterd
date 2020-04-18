import socket
import json

def basicTest():
    d=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    d.connect(("127.0.0.1",2222))
    bys=json.dumps({"header":{"authentication":{"username":"tbk", "password":"passwd"},"type":"type1", "scope":"poes"},"payload":"ABBA"})
    print(bys)
    d.send(bytes([len(bys),0,0,0]))
    d.send(bys.encode())
    d.send(bytes([len(bys),0,0,0]))
    d.send(bys.encode())
    while True: pass
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

runTests()