/**
* @author -         Jerome To (Accenture)
* @date -           July 7, 2016
* @description -    A request wrapper class of Opportunity Account Manager
* #############Change Log#############
* Modified by     Version     Change Date
**/

public with sharing class OpportunityAccountManagerRequestWrapper {
    public Integer AccountManagerEntity; 
    public Integer EntityGolfbreaksID; 
    public EmployeeModel NewAccountManager;    
    
    public class EmployeeModel {
        public Integer GolfbreaksEmployeeID;
        public String Email;
        public String Forename;
        public String Surname;
        
        public EmployeeModel (Integer golfbreaksEmployeeID, String email, String forename, String surname){

            if(golfbreaksEmployeeID <> null){
                this.GolfbreaksEmployeeID = golfbreaksEmployeeID;
                this.Email = '';
                this.Forename = '';
                this.Surname = '';
            } else if (String.isNotBlank(email)) {
                this.GolfbreaksEmployeeID = null;
                this.Email = email;
                this.Forename = '';
                this.Surname = '';                
            } else{
                this.GolfbreaksEmployeeID = null;
                this.Email = '';
                this.Forename = forename;
                this.Surname = surname;                
            }
        }
    }
    
}