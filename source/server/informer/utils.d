module server.informer.utils;

import server.server : BesterServer;
import connection.connection : BesterConnection;
import std.string : cmp;

/**
* This functions returns `string[]` where each element
* contains the username of the locally connected client.
*/
public static string[] listClients(BesterServer server)
{
    string[] clientList;

    for(ulong i = 0; i < server.clients.length; i++)
    {
        /* Make sure only to add client connections */
        BesterConnection connection = server.clients[i];
        if(connection.getType() == BesterConnection.Scope.CLIENT)
        {
            clientList ~= [connection.getCredentials()[0]];
        }
    }

    return clientList;
}

/**
* This function returns `true` if the provided username
* matches a locally connected client, `false` otherwise.
*/
public static bool isClient(BesterServer server, string username)
{
    for(ulong i = 0; i < server.clients.length; i++)
    {
        /* Make sure only to match client connections */
        BesterConnection connection = server.clients[i];
        if(connection.getType() == BesterConnection.Scope.CLIENT && cmp(connection.getCredentials[0], username))
        {
            return true;
        }
    }

    return false;
}