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

    override public bool authenticate(string username, string password)
    {
         /* TODO: Implement me */

        /* Check if a key exists with the `username` */
        bool accountExists = redisDatabase.exists(username);

        if(accountExists)
        {
            /**
            * Check within the key if the subkey and value pair exists.
            * `(username) [password: <password>], ...`
            */
            if(redisDatabase.hexists(username, "password"))
            {
                
            }
            else
            {
                /* TODO: Raise exception for missing password sub-key */
            }
        }
        else
        {
            /* TODO: Raise exception for non-existent account */
        }
    }

    override public void createAccount(string username, string password)
    {
        /* TODO: Implement me */

        /* Check if a key exists with the `username` */
        bool accountExists = redisDatabase.exists(username);

        if(!accountExists)
        {
            /**
            * Create the new account.
            * This involves creating a new key named `username`
            * with a field named `"password"` matching to the value
            * of `password`.
            */
            redisDatabase.hset(username, "password", password);
        }
        else
        {
            /* TODO: Raise exception for an already existing account */
        }
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