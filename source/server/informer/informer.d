module server.informer.informer;

import core.thread : Thread;
import server.server : BesterServer;
import std.socket;

/**
* The `BesterInformer` allows handlers to query (out-of-band)
* information regarding this bester server.
*
* This is useful when the message handler requires additional
* information before it sends its final message response.
*/
public final class BesterInformer : Thread
{
    /* The associated `BesterServer` */
    private BesterServer server;

    /* Informer socket */
    private Socket informerSocket;

    this(BesterServer server)
    {
        /* Set the worker function */
        super(&worker);

        /* Setup the socket */
        informerSocket = new Socket(AddressFamily.UNIX, SocketType.STREAM);
        informerSocket.bind(new UnixAddress("bInformer"));
        informerSocket.listen(1); /* TODO: Value */
    }

    private void worker()
    {
        while(1)
        {
            Socket handler = informerSocket.accept();
        }
    }


}