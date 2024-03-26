/*
Name:  IDataEventTypeRequestHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Interface class - provides abstracted pluggable interface for request handling logic. 

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-08-21  Initial development.
1.1  Mark Cane&    2019-09-12  Added sObjectType and recordIds parameter.
*/
global interface IDataEventTypeRequestHandler {
    HttpRequest buildOutboundRequest(String sObjectType, Set<Id> recordIds, HttpRequest r); 
}