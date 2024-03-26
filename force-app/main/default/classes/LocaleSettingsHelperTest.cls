/*
Name: LocaleSettingsHelper.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test Suite for LocaleSettingsHelper
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-03-27  Initial development.
*/
@isTest
public with sharing class LocaleSettingsHelperTest {
    @isTest static void testGetLocalDateFormatString(){
        DateTime testDate = DateTime.newInstance(2020,03,27);
        system.assertEquals('27/03/2020', LocaleSettingsHelper.getLocalDateFormatString('en-gb', testDate));
        system.assertEquals('03/27/2020', LocaleSettingsHelper.getLocalDateFormatString('en-us', testDate));
        system.assertEquals('27-03-2020', LocaleSettingsHelper.getLocalDateFormatString('da-dk', testDate));
        system.assertEquals('2020-03-27', LocaleSettingsHelper.getLocalDateFormatString('sv-se', testDate));
        system.assertEquals('27.03.2020', LocaleSettingsHelper.getLocalDateFormatString('no-no', testDate));
    }
}