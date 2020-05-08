module server.accounts;

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

    /**
    * Check if the user, `username`, exists in the database.
    */
    public abstract bool userExists(string username);

    public abstract bool authenticate(string username, string password);

    public abstract void shutdown();
}