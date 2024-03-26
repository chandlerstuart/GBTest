public class SalesUserWrapper {
    
    public String userName { get; set; }
    public String online { get; set; }
    public Integer newLeads { get; set; }
    public Integer diarisedLeads { get; set; }
    
    public Integer recommendationOpp { get; set; }
    public Integer quoteSentOpp { get; set; }
    public Integer closeOpp { get; set; }
    public Integer custAcceptedOpp { get; set; }
    
    public Integer cases { get; set; }
    
    public Integer taskCallBacks { get; set; }
    
    public Integer leadTotal { get; set; }
    public Integer oppTotal { get; set; }
    public Integer caseTotal { get; set; }
    public Integer taskTotal { get; set; }
    
    public SalesUserWrapper(String userName, 
                          String online,
                          Integer newLeads, 
                          Integer diarisedLeads, 
                          Integer recommendationOpp, 
                          Integer quoteSentOpp, 
                          Integer closeOpp, 
                          Integer custAcceptedOpp, 
                          Integer cases, 
                          Integer taskCallBacks, 
                          Integer leadTotal, 
                          Integer oppTotal, 
                          Integer caseTotal, 
                          Integer taskTotal) {
                           
    		this.userName = userName;
    		this.online = online;
    		this.newLeads = newLeads;
    		this.diarisedLeads = diarisedLeads;
    		this.recommendationOpp = recommendationOpp;
    		this.quoteSentOpp = quoteSentOpp;
    		this.closeOpp = closeOpp;
    		this.custAcceptedOpp = custAcceptedOpp;
    		this.cases = cases;
    		this.taskCallBacks = taskCallBacks;
    		this.leadTotal = leadTotal;
    		this.oppTotal = oppTotal;
    		this.caseTotal = caseTotal;
    		this.taskTotal = taskTotal;
    		
    }    
}