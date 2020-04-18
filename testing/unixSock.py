import socket


def runTest():
    d=socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    d.bind("../aSock")
    d.listen()
    while True:
        s = d.accept()[0]
        print(list(s.recv(130)))
        print(s.send(bytes([4,0,0,0,65,66,66,65])))

    while True: pass

runTest()