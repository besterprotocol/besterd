module server.informer.client;

import core.thread : Thread;
import server.server : BesterServer;
import std.socket;


public class BesterInformerClient : Thread
{
    /* The associated `BesterServer` */
    private BesterServer server;

    /* The socket to the handler */
    private Socket handlerSocket;

    this(BesterServer server, Socket handlerSocket)
    {
        super(&worker);
        this.server = server;
        this.handlerSocket = handlerSocket;
    }

    private void worker()
    {
        /* TODO: Implement me */
    }

}