module server.informer;

import core.thread : Thread;

public final class BesterInformer : Thread
{
    this()
    {
        super(&worker);
    }

    private void worker()
    {
        
    }


}