@RestResource(UrlMapping='/Lead/*')
global with sharing class InboundRequests {
    
    // Entrypoint for Post request
    @HttpPost
    global static void RequestSubmission_Post() {
        
        //Pass the request body to method
        ProcessRequest(RestContext.request.requestBody);
    }
    
    // Entrypoint for Put request
    @HttpPut
    global static void RequestSubmission_Put() {
        
        //Pass the request body to method
        ProcessRequest(RestContext.request.requestBody);
    }
    
    
    
    // Main method 
    public static void ProcessRequest(Blob respbody) {
        boolean success = true;
        string message = 'success';
        
        
        try {
            
            if(respbody != null && !string.isBlank(respbody.toString())) {
                
                // Deserialize the Request
                InboundRequest request = (InboundRequest)JSON.Deserialize(respbody.toString(), InboundRequest.class);
                
                // Variables for standard objects
                Opportunity opp;
                Account acct;
                
                
                ////////////////////////////
                // Find/Created Opportunity//
                // //////////////////////////
                if(!string.isBlank(request.enquiryID)) {
                    
                    //for(Opportunity rec :[SELECT Id FROM Opportunity WHERE EnquiryId__c = :request.enquiryID]); inquiry id is not existing
                    for(Opportunity rec :[SELECT Id FROM Opportunity WHERE Name = 'Testing Lead 101'/*:request.oppName*/ LIMIT 1])                    
                     opp = rec;
                    
                     System.debug('Opp REST: ' +opp);
                     System.debug('Req Date REST: ' +request.closedate); 
                     System.debug('Req Date Parse REST: ' +date.parse(request.closedate)); 
                     date myDate = date.parse(request.closedate);
                     
                     System.debug('Date REST: ' +myDate);   
                    if(opp != null) {
                     
                        opp = new Opportunity(
                            //Name = request.oppName
                             Address__c = request.oppName
                        //    RecordTypeID = 'Sales_Opportunity',
                           // Name = (!string.isBlank(request.oppName) ? request.oppName : 'Not Provided')
                          //  StageName = (!string.isBlank(request.stage) ? request.stage : 'Not Provided'),
                          //  Account = 'Patrick Villarica',
                         //   CloseDate = myDate,
//                            ForecastCategoryName = (!string.isBlank(request.category) ? request.category : 'Not Provided')
                           
                        );
                    } // end of checking opp
                    
                    
                    upsert(opp);
                    
                } // end of find/create opportunity
                
          
            
            
            } // end for checking of respbody
            
            
            else {
                success = false;
                message = 'Must Provide a valid request body';
            }
    
        } // end of try
        
        catch(Exception ex) {
                success = false;
                message = 'Received request body was not valid';
        } //end of catch
  
        
         ////////////////////////////
        // Populate Response       //
        // //////////////////////////
        
        RestResponse res = RestContext.response;
        
        map<string, object> containerMap = new map<string, object> {
            'response' =>
                new Response (
                    success ? 200 : 500,
                    message
                )
        };
        
        res.statusCode = success ? 200 : 500;
        res.responseBody = blob.valueof(json.serialize(containerMap));
        
        
    } //end of process request class
    
    
    
    // class for a typed deserialization json formats
    public class InboundRequest {
        
        public string enquiryId {get; set;}
      //  public string personAccountId {get; set;}
        public string oppName { get; set; }
        public string stage { get; set; }
        public string closedate { get; set; }
        public string category { get; set; }
        
       // public string acctName { get; set; }
        
        
        
        // other json request to follow up
        
        //Constructor for InboundRequest
        public InboundRequest() {}
    }
    
    
    
    //class for POST Response
    public class Response {
        
        public integer resp_code { get; set;}
        public string resp_detail { get; set;}
        
        //Constructor for Response
        public Response(integer code, string detail) {
            this.resp_code = code;
            this.resp_detail = detail;
        }
        
    }
    
    
    
    
    
    
}