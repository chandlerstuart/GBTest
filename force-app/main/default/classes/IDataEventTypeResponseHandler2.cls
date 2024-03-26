/*
Name:  IDataEventTypeResponseHandler2.cls
Copyright © 2021  Golfbreaks
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
1.0  Mark Cane&    2021-06-30  Initial development.
*/
global interface IDataEventTypeResponseHandler2 {
    Boolean handleOutboundResponse(HttpResponse r, String reshapedResponseBody, Id outboundCalloutId);
}