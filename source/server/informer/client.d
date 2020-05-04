module server.informer.client;

import core.thread : Thread;
import server.server : BesterServer;
import std.socket;
import bmessage;
import std.json;
import utils.debugging;

public class BesterInformerClient : Thread
{
    /* The associated `BesterServer` */
    private BesterServer server;

    /* The socket to the handler */
    private Socket handlerSocket;

    this(BesterServer server, Socket handlerSocket)
    {
        super(&worker);
        this.server = server;
        this.handlerSocket = handlerSocket;
    }

    private void worker()
    {
        /* TODO: Implement me */
        while(1)
        {
            /* Receive a message */
            JSONValue handlerCommand;
            receiveMessage(handlerSocket, handlerCommand);

            /* The response to send */
            JSONValue handlerResponse;

            /* Attempt to get the JSON */
            try
            {
                /* Get the command type */
                string commandType = handlerCommand["command"]["type"].str();
                debugPrint("Command: "~ commandType);



                /* Set the `status` field to `"0"` */
                handlerResponse["status"] = "0";
            }
            catch(JSONException e)
            {
                /* Set the `status` field to `"1"` */
                handlerResponse["status"] = "1";
            }

            /* Send the response to the handler */
            sendMessage(handlerSocket, handlerResponse);
            
        }
    }

}