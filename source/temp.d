	finally
		{
			/* Always close the socket */
			handlerSocket.close();
			debugPrint("Closed UNIX domain socket to handler");
		}