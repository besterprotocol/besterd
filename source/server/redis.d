module server.redis;

import vibe.vibe;
import server.accounts : BesterDataStore;

/**
* This represents a Redis datastore for the Bester
* server's account management system.
*/
public final class RedisDatastore : BesterDataStore
{
    this()
    {
        
    }
}