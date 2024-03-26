/*
Name:  Utilities.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Utilities class for multi-use functions and simplification
of Apex capabilities. 
======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  Halldór Örn         2014-05-21      Initial development.


*/

public class Utilities {
    /* Class Utilities */
    
    /// <summary>
    /// OVERLOADED
    /// CHECKS IF STRING IS NULL OR EMPTY
    /// </summary>
    /// <param name="sInValueToCheck">STRING TO CHECK</param>
    /// <returns>TRUE IF NULL</returns>

    public static boolean isNullOrEmpty(string sInValueToCheck)
    {
        if(sInValueToCheck != null && sInValueToCheck != '' && sInValueToCheck.toLowerCase() != 'null')
        {
            return false;
        }
        return true;
    }


    public static boolean isNullOrEmpty(decimal dInValueToCheck)
    {
        if(dInValueToCheck != null && dInValueToCheck != 0.0)
        {
            return false;
        }
        return true;
    }

    /// <summary>
    /// OVERLOADED
    /// CHECKS IF SOBJECT LIST IS NULL OR EMPTY
    /// </summary>
    /// <param name="lstInValueToCheck">STRING TO CHECK</param>
    /// <returns>TRUE IF NULL</returns>
    public static boolean isNullOrEmpty(List<sobject> lstInValueToCheck)
    {
          if(lstInValueToCheck != null && lstInValueToCheck.size() > 0)
          {
                return false;
          }
          return true;
    }
    /* Parameters Util */
    public static string grabParameter(String name)
    {
        return ApexPages.currentPage().getParameters().get(name);
    }
    /* End parameter Util */

    /* Returns a randomly generated Hash string */
    public static String generateHash() 
    {       
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.convertToHex(blobKey);
        return key.toUpperCase();
    }   
    /* MD5 encodes a string parameter and returns the string value */
    public static String generateMD5(String val) 
    {       
        return EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(val)));
    }

    /* Adds a leading zero to a string if the string is numeric and less than 10 */
    public static String addZero(String n){
        return Integer.valueOf(n)<10 ? '0'+n : ''+n;
    }

    /* Returns the string value of an integer. Adds a leading zero to the string if the integer is less than 10*/
    public static String addZero(Integer n){
        return n<10 ? '0'+n : ''+n;
    }

    /* Returns true if the current code is run in a Sandbox org */
    public static Boolean isSandbox() {
        return URL.getSalesforceBaseUrl().getHost().contains('cs');//.equalsignorecase('cs');
    }

    /* Returns true if the current code is run in a Developer org */
    public static Boolean isDeveloperEdition() {
        String edition = [ SELECT Id, OrganizationType from Organization WHERE Id != null LIMIT 1 ].OrganizationType;
        if(edition == 'Developer Edition')
            return true;
        else
            return false;
    }

    /* Returns the name of the current apexpage being viewed */
    public static String getCurrentPageName(){
        return ApexPages.currentPage().getUrl().split('apex/')[1];
    }   
}