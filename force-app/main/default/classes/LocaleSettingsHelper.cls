/*
Name: LocaleSettingsHelper.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Utility class for handling all actions pertaining to 
user/business unit locale settings
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-03-27  Initial development.
*/
public with sharing class LocaleSettingsHelper {
    
    //Return a the Date in a String formatted to specified locale 
    public static String getLocalDateFormatString(String locale, DateTime dt){
        if(locale.equalsIgnoreCase('en-gb')) return dt.format('dd/MM/YYYY');
        if(locale.equalsIgnoreCase('en-us')) return dt.format('MM/dd/YYYY');
        if(locale.equalsIgnoreCase('da-dk')) return dt.format('dd-MM-YYYY');
        if(locale.equalsIgnoreCase('sv-se')) return dt.format('YYYY-MM-dd');
        if(locale.equalsIgnoreCase('no-no')) return dt.format('dd.MM.YYYY');
        return dt.format('dd/MM/YYYY');
    }

}