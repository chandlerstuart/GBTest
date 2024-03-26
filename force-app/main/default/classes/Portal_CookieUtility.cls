/**
* @author -         Abrar Haq (Accenture)
* @date -           21/06/2016
* @description -    A utility class to set the Cookie in the Browser
* #############Change Log#############
* Modified by     Version     Change Date
**/
public with sharing class Portal_CookieUtility {

	public Portal_CookieUtility(){
		setBrowserCookies();
		getBrowserCookies();
	}

	public void setBrowserCookies(){
		String jsonBrowserData = APIMockResponseUtility.getBrowserCookieJSON();

		// Store JSON 
		Cookie jsonBrowserCookie = new Cookie('cookieData', jsonBrowserData, null, 43200, true);

		//Set the page cookies using the setCookies() method
		ApexPages.currentPage().setCookies(new Cookie[]{ jsonBrowserCookie });        
	}

	public void getBrowserCookies(){  
		Cookie theCookieFromBrowser;
		theCookieFromBrowser = ApexPages.currentPage().getCookies().get('cookieData');
		System.Debug('>>theCookieFromBrowser.getValue()<<'+ theCookieFromBrowser.getValue() );
	}

}