/*
Name:  RedirectController.cls
Copyright © 2014  Kaptio ehf.
Based on code from Frank Neezen
http://www.frankneezen.com/2013/04/salesforce-url-hacking-prepopulating-fields/
======================================================
======================================================
Purpose:
-------
Controller for redirect.page

Gives the option of using objects and fiels api name 
in the parameters of a path and redirects accordingly

======================================================
======================================================
History
------- 
Ver.  Author             Date        Detail
1.0  Halldór Örn   2014-05-21  Class creation.

*/

public with sharing class RedirectController {


    /*
     *  Method name:    redirectUser
     *  @description    Redirects the user to the given object + parameters
     *  @return         PageReference The page the user needs to be redirect to.
     */
    public PageReference redirectUser(){
        
        //Get object name
        String strObject = System.currentPageReference().getParameters().get('object');
        
        //Get object Id // Use when editing a single record.
        String strObjectId = System.currentPageReference().getParameters().get('objectId');
        
        //Allow record type selection? if set to yes, then allow RTS
        String strEnableRTS = System.currentPageReference().getParameters().get('allowRTS');
        
        //If there is an object name
        if(strObject != ''){
            
            //Create a generic object based on the name
            Schema.Sobjecttype oGenericObj = Schema.getGlobalDescribe().get(strObject);     
            
            //If a real object has been given
            if(oGenericObj != null){
                
                PageReference pReference = null;
                
                //Check if we have to use record type selection or not
                if(strEnableRTS != '' && strEnableRTS == 'true'){
                    
                    //If we need RTS, the URL will have to point to the recordtypeselect.jsp
                    if(oGenericObj.getDescribe().custom){
                        pReference = new PageReference('/setup/ui/recordtypeselect.jsp?ent=' +oGenericObj.getDescribe().getKeyPrefix()+ '&save_new_url=/' + oGenericObj.getDescribe().getKeyPrefix() + '/e?');                   
                    }
                    else{
                        pReference = new PageReference('/setup/ui/recordtypeselect.jsp?ent=' + strObject + '&save_new_url=/' + oGenericObj.getDescribe().getKeyPrefix() + '/e?');                   
                    }
                        
                }else{
                
                    //Else create the page reference to the edit page of this object
                    pReference = new PageReference('/' +  oGenericObj.getDescribe().getKeyPrefix() + '/e');
                    if(strObjectId != null)
                        pReference = new PageReference('/' +  strObjectId + '/e');
                }
                
                //Also get a separate reference - we always need to get the parameters based on the edit page
                PageReference pEditReference = new PageReference('/' +  oGenericObj.getDescribe().getKeyPrefix() + '/e');
                if(strObjectId != null)
                    pReference = new PageReference('/' +  strObjectId + '/e');
                
                //Get all current parameters - this could be either edit page or the record type selection.
                Map<String, String> m = pReference.getParameters();
                
                //Create the parameters for the URL (translates field to ID)             
                m.putAll(RedirectHelper.createLabelParameters(pEditReference, oGenericObj.newSObject()));
                m.put('nooverride', '1');
                m.put('retURL', ApexPages.currentPage().getParameters().get('retURL'));
                m.put('saveURL', ApexPages.currentPage().getParameters().get('saveURL'));
                
                    
                //Return the page
                return pReference;
            }
        }
        
        //Return null if someone is playing with the URL
        return null;
    }
}