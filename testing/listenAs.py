
import socket
import json

def listenAs(username):
    # Connect to the bester daemon
    d=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    d.connect(("127.0.0.1",2223))

    # First authenticate (to be put into the connection queue)
    bys=json.dumps({"header":{"authentication":{"username":username, "password":"passwd"}, "scope":"client"},"payload":{"data":{"bruhMsg":"fhdjhgfhjd"},"type":"type1"}})
    print(len(bys), bys)
    d.send(len(bys).to_bytes(4, "little"))
    d.send(bys.encode())

    # Loop and listen
    while True:
        length=int.from_bytes(list(d.recv(4)), "little")
        print(length)
        receivedDataBytes = d.recv(length)
        receivedData = list(receivedDataBytes)
        print(receivedDataBytes.decode())

    d.close()

def runTests():
    # Enter username for listening
    listenAs(input("Enter username to listen as: "))

runTests()