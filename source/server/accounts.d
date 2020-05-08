module server.accounts;

import vibe.vibe;

/**
* This represents the accounts management system of
* the server. It is only an abstract class.
*/
public abstract class BesterDataStore
{
    /**
    * Creates a new account with the given `username` and
    * `password`.
    */
    public abstract void createAccount(string username, string password);
}