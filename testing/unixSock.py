import socket


def runTest():
    d=socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    d.bind("../aSock")
    d.listen()
    s = d.accept()[0]
    print(list(s.recv(130)))

    while True: pass

runTest()