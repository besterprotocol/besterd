module server.informer;

import core.thread : Thread;
import server.server : BesterServer;


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

    this(BesterServer server)
    {
        super(&worker);
    }

    private void worker()
    {

    }


}