module server.redis;

import vibe.vibe;
import server.accounts : BesterDataStore;

/**
* This represents a Redis datastore for the Bester
* server's account management system.
*/
public final class RedisDatastore : BesterDataStore
{

    /**
    * Redis client.
    */
    private RedisClient redisClient;

    /**
    * Redis database with the account information
    */
    private RedisDatabase redisDatabase;

    this(string address, ushort port)
    {
        /* Opens a connection to the redis server */
        initializeRedis(address, port);
    }

    private void initializeRedis(string address, ushort port)
    {
        redisClient = new RedisClient(address, port);
        redisDatabase = redisClient.getDatabase(0);
    }

    override public void createAccount(string username, string password)
    {
        /* TODO: Implement me */
        
    }

    public void f()
    {

    }

    override public void shutdown()
    {
        /* TODO: Should we shutdown the server? */
        redisClient.shutdown();
    }
}