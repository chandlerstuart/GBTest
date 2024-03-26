/*
Name:  IDataEventTypeResponseHandler3.cls
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
1.0  J Radcliffe   2022-02-04  Initial development.
*/
global interface IDataEventTypeResponseHandler3 {
    Boolean handleOutboundResponse(HttpResponse r, String reshapedResponseBody, Id outboundCalloutId, Set<Id> recordIds);
}