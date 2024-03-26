/*
Name:  IDataEventTypeResponseHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Interface class - provides abstracted pluggable interface for response handling logic. 

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-08-21  Initial development.
*/
global interface IDataEventTypeResponseHandler {
    Boolean handleOutboundResponse(HttpResponse r); 
}