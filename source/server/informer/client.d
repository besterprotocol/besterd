module server.informer.client;

import core.thread : Thread;
import server.server : BesterServer;
import std.socket;
import bmessage;
import std.json;
import utils.debugging;
import std.string;
import server.informer.utils;
import std.conv : to;

/**
* Represents a handler's connection to the
* Bester informer socket, runs as a seperate
* thread with a read, dispatch, write loop
* to handle commands and responses to the handler
* from the server.
*/
public final class BesterInformerClient : Thread
{
    /* The associated `BesterServer` */
    private BesterServer server;

    /* The socket to the handler */
    private Socket handlerSocket;

    /* If the connection is still active or not */
    private bool active = true;

    this(BesterServer server, Socket handlerSocket)
    {
        super(&worker);
        this.server = server;
        this.handlerSocket = handlerSocket;
    }

    /**
    * Run's the command specified in `commandBlock` and sets the
    * response in the variable pointed to by `result`.
    */
    private bool runCommand(JSONValue commandBlock, ref JSONValue result)
    {
        try
        {
            /* Get the command type */
            string commandType = commandBlock["type"].str();
            debugPrint("CommandType: " ~ commandType);

            /* Check if the command if `listClients` */
            if(cmp(commandType, "listClients") == 0)
            {
                /* Create a JSON list of strings */
                result = listClients(server);
            }
            /* Check if the command is `isClient` */
            else if(cmp(commandType, "isClient") == 0)
            {
                /* The username to match */
                string username = commandBlock["data"].str();
                result = isClient(server, username);
            }
            /* Check if the command is `serverInfo` */
            else if(cmp(commandType, "serverInfo") == 0)
            {
                result = getServerInfo(server);
            }
            /* Check if the command is `quit` */
            else if (cmp(commandType, "quit") == 0)
            {
                /* Set the connection to inactive */
                active = false;
                result = null; /* TODO: JSOn default value */
            }
            /* TODO: Add any more new command here */
            /* If the command is invalid */
            else
            {
                result = null;
                return false;
            }

            debugPrint(result.toPrettyString());
            return true;
        }
        catch(JSONException e)
        {
            return false;
        }
    }

    private void worker()
    {
        /* TODO: Implement me */
        while(active)
        {
            /* Receive a message */
            JSONValue handlerCommand;
            receiveMessage(handlerSocket, handlerCommand);

            /* The response to send */
            JSONValue handlerResponse;

            /* Respose from `runCommand` */
            JSONValue runCommandData;

            /* Attempt to get the JSON */
            try
            {
                /* Get the command type */
                string commandType = handlerCommand["command"]["type"].str();
                debugPrint("Command: " ~ commandType);

                /* Dispatch to the correct command and return a status */
                bool commandStatus = runCommand(handlerCommand["command"], runCommandData);

                /* Set the data */
                handlerResponse["data"] = runCommandData;

                /* Set the `status` field to `"0"` */
                handlerResponse["status"] = commandStatus ? "0" : "1";
            }
            catch(JSONException e)
            {
                /* Set the `status` field to `"1"` */
                handlerResponse["status"] = "1";
            }

            /* Send the response to the handler */
            sendMessage(handlerSocket, handlerResponse);
        }

        /* Close the socket */
        handlerSocket.close();
    }

}