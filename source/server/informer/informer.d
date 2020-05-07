module server.informer.informer;

import core.thread : Thread;
import server.server : BesterServer;
import std.socket;
import server.informer.client : BesterInformerClient;

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

    /* Whether or not the informer server is active */
    private bool active = true;

    /**
    * Constructs a new `BesterInformer` object
    * which will accept incoming connections
    * (upon calling `.start`) from handlers,
    * over a UNIX domain socket, requesting
    * server information.
    */
    this(BesterServer server)
    {
        /* Set the worker function */
        super(&worker);

        /* Setup the socket */
        informerSocket = new Socket(AddressFamily.UNIX, SocketType.STREAM);
        informerSocket.bind(new UnixAddress("bInformer"));
        informerSocket.listen(1); /* TODO: Value */

        /* Set the associated BesterServer */
        this.server = server;
    }

    /**
    * Client send-receive loop.
    * Accepts incoming connections to the informer
    * and dispatches them to a worker thread.
    */
    private void worker()
    {
        while(active)
        {
            /* Accept the queued incoming connection */
            Socket handlerSocket = informerSocket.accept();

            /**
            * Create a new worker for the informer client and dispatch
            * its worker thread.
            */
            BesterInformerClient newInformer = new BesterInformerClient(server, handlerSocket);
            newInformer.start();
        }

        /* Close the informer socket */
        informerSocket.close();
    }


}