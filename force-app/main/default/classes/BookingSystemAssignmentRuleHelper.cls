/*
Name:  BookingSystemAssignmentRuleHelper.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Helper class responsible for Booking System Assignment Rule processing.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-08-07  Initial development.
1.1  Mark Cane&    2019-08-19  Literal=>Picklist label references added.
1.2  J Radcliffe   2019-09-30  Data Event Type Assignment
1.3  J Radcliffe   2019-10-17  Set DeveloperName on Enquiry (Not Mtd Id)
1.4  J Radcliffe   2019-11-04  Bug Fix - Adding 'EvaluationOrder__c' Field to Query - Booking Assignment Rules not being evaluated in the correct order - Known Issue: https://success.salesforce.com/issues_view?id=a1p3A0000001BreQAE&title=custom-metadata-type-not-being-sorted-as-expected
1.5  J Radcliffe   2020-01-20  Still evaluate rules even if Booking System is specified (bookingSystem is sometimes set explicity (via flow) to assign the correct Booking System and Data Types). Implemented alternate means of exiting once the enquiry has had a booking assigned via the rules
*/
public with sharing class BookingSystemAssignmentRuleHelper {
    public BookingSystemAssignmentRuleHelper(){}

    /*  ======================================================
        Method: runBookingSystemAssignmentRules
        Params: List of Enquiries.
        Returns: Boolean (false=runtime exception). 
        Purpose: Populates the Enquiry.bookingSystem property as required for the Enquiry attributes and configured rules.

        ----------------
        Revision History
        ----------------
        Ver. Author        Date        Detail
        1.0  Mark Cane&    2019-08-07  Initial development.
        ======================================================
    */
    public static Boolean runBookingSystemAssignmentRules(List<EnquiryManager.Enquiry> enquiries){        
        try {

            // enumerate configured rules in evaluation order ascending
            // for each enquiry 
            //   if bookingSystem populated continue
            //   evaluate each entry in turn
            //   if all rules pass (or any if rule is set this way) - set the enquiry bookingSystem, break

            // Note - unassigned is a valid return state.

            Boolean isValidRuleEntry=false, hasInvalidRequiredRuleEntry=false;
            Integer validRuleEntryCount=0;
            Set<String> enquiriesWithAssignedBookingSystems = new Set<String>();//1.5+

            for (BookingSystemAssignmentRule__mdt assignmentRule : [select Id, EvaluationOrder__c, ClientDataEventType__c, ClientDataEventType__r.DeveloperName, EnquiryDataEventType__c, EnquiryDataEventType__r.DeveloperName, AllRuleEntriesRequired__c, BookingSystem__c,
                                                                        (select Id, IsRequired__c, EnquiryPropertyDataType__c, EnquiryPropertyName__c, EntryValue__c, Operator__c
                                                                            from BookingSystemAssignmentRuleEntries__r)
                                                                    from BookingSystemAssignmentRule__mdt 
                                                                    where IsActive__c=true and IsTest__c=:Test.isRunningTest()
                                                                    order by EvaluationOrder__c asc]){//1.2~ //1.3~ //1.4~

                for (EnquiryManager.Enquiry e : enquiries){
                    if (e.isAborted/*|| String.isNotBlank(e.bookingSystem)*/) continue; //1.5~ 
                    if(e.uniqueIdentifier == null) e.uniqueIdentifier = DuplicateManagementHelper.createUniqueIdentifier(e);//1.5+
                    if(enquiriesWithAssignedBookingSystems.contains(e.uniqueIdentifier)) continue;//1.5+

                    validRuleEntryCount=0;
                    hasInvalidRequiredRuleEntry=false;

                    for (BookingSystemAssignmentRuleEntry__mdt ruleEntry : assignmentRule.BookingSystemAssignmentRuleEntries__r){
                        if (!e.propertyCache.containsKey(ruleEntry.EnquiryPropertyName__c)) continue;

                        isValidRuleEntry = evaluateRuleEntry(ruleEntry, e.propertyCache.get(ruleEntry.EnquiryPropertyName__c));
                        if (isValidRuleEntry) validRuleEntryCount++;

                        if (!isValidRuleEntry && assignmentRule.AllRuleEntriesRequired__c) break;//All rule entries must be valid.
                        
                        if (!isValidRuleEntry 
                            && !assignmentRule.AllRuleEntriesRequired__c
                            && ruleEntry.IsRequired__c){
                                
                            hasInvalidRequiredRuleEntry=true;
                            break;//Invalid required rule entry.
                        }
                    }

                    if ( (assignmentRule.AllRuleEntriesRequired__c && validRuleEntryCount==assignmentRule.BookingSystemAssignmentRuleEntries__r.size())
                            || (!assignmentRule.AllRuleEntriesRequired__c && validRuleEntryCount>=1 && !hasInvalidRequiredRuleEntry)){
                        
                        e.bookingSystem = (assignmentRule.BookingSystem__c != null)? assignmentRule.BookingSystem__c:null;
                        e.clientDataEvent = (assignmentRule.ClientDataEventType__c != null && assignmentRule.ClientDataEventType__r.DeveloperName != null)?assignmentRule.ClientDataEventType__r.DeveloperName:null;//1.2+//1.3~
                        e.enquiryDataEvent = (assignmentRule.EnquiryDataEventType__c != null && assignmentRule.EnquiryDataEventType__r.DeveloperName != null)? assignmentRule.EnquiryDataEventType__r.DeveloperName:null;//1.2+//1.3~
                        if(!enquiriesWithAssignedBookingSystems.contains(e.uniqueIdentifier)) enquiriesWithAssignedBookingSystems.add(e.uniqueIdentifier);//1.5
                    }

                }// enquiry.
            }// bookingSystemAssignmentRule

            return true;

        } catch(Exception ex){ 
            LogHelper.logExceptions(ex, 'BookingSystemAssignmentRuleHelper', 'runBookingSystemAssignmentRules');
            for (EnquiryManager.Enquiry e : enquiries){ e.errorMessages.put('0001',Label.Enquiry_Technical_Error+': '+ex.getMessage()); e.isAborted=true; }
        }
        return false;
    }

    private static Boolean evaluateRuleEntry(BookingSystemAssignmentRuleEntry__mdt ruleEntry, Object o){
        try {

            switch on ruleEntry.EnquiryPropertyDataType__c {
                when 'String' {

                    String entryValue = String.valueOf(o);

                    if (ruleEntry.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Booking_System_Assignment_Rule_Entry_Operator_Equals)){

                        if (entryValue.equalsIgnoreCase(ruleEntry.EntryValue__c)) return true;

                    } else if (ruleEntry.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Booking_System_Assignment_Rule_Entry_Operator_Does_Not_Equal)){

                        if (!entryValue.equalsIgnoreCase(ruleEntry.EntryValue__c)) return true;

                    } else if (ruleEntry.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Booking_System_Assignment_Rule_Entry_Operator_Contains)){

                        if (entryValue.containsIgnoreCase(ruleEntry.EntryValue__c)) return true;
                    }
                }
                when 'String Array' {

                    List<String> entryValues = (List<String>)o;

                    if (ruleEntry.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Booking_System_Assignment_Rule_Entry_Operator_Contains)){ 
                        if (entryValues.contains(ruleEntry.EntryValue__c)) return true;
                    }
                }
                when 'Boolean' {

                    Boolean entryValue = (Boolean)o;
                
                    if (ruleEntry.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Booking_System_Assignment_Rule_Entry_Operator_Equals)){

                        if (entryValue && ruleEntry.EntryValue__c.equalsIgnoreCase('true')) return true;

                        if (!entryValue && ruleEntry.EntryValue__c.equalsIgnoreCase('false')) return true;                    
                    }
                } 
                when 'Integer', 'Decimal' {

                    Decimal entryValue = (Decimal)o;
                    Decimal ruleEntryValue = Decimal.valueOf(ruleEntry.EntryValue__c);

                    if (ruleEntry.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Booking_System_Assignment_Rule_Entry_Operator_Equals)){

                        if (entryValue==ruleEntryValue) return true;

                    } else if (ruleEntry.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Booking_System_Assignment_Rule_Entry_Operator_Does_Not_Equal)){

                        if (entryValue<>ruleEntryValue) return true;

                    } else if (ruleEntry.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Booking_System_Assignment_Rule_Entry_Operator_Greater_Than)){

                        if (entryValue>ruleEntryValue) return true;

                    } else if (ruleEntry.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Booking_System_Assignment_Rule_Entry_Operator_Less_Than)){

                        if (entryValue<ruleEntryValue) return true;
                    }
                }
            }
        } catch(Exception ex){ }
        return false;
    }
}