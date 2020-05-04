module server.informer.utils;

import server.server : BesterServer;
import connection.connection : BesterConnection;

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