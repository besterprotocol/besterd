import socket
import json

def basicTest():
    d=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    d.connect(("127.0.0.1",2223))
    bys=json.dumps({"header":{"authentication":{"username":"tbk", "password":"passwd"},"type":"type1", "scope":"poes"},"payload":1})
    d.send(bytes([len(bys),0,0,0]))
    d.send(bys.encode())
    d.close()

def runTests():
    basicTest()

runTests()