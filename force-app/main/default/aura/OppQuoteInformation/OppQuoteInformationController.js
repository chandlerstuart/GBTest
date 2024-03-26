({
    handleQuoteUpdate : function(component, event, helper){
    	var whichQuote = event.getParam("quote");
        var direction = event.getParam("direction");
        var allQuotes = component.get("v.quotes");
		
        if ('UP' == direction){
			var chosen = allQuotes[parseInt(whichQuote.quoteRecord.DisplayOrder__c)-1];
            var change = allQuotes[parseInt(whichQuote.quoteRecord.DisplayOrder__c)-2];
            
            allQuotes[parseInt(whichQuote.quoteRecord.DisplayOrder__c)-2] = chosen;
            allQuotes[parseInt(whichQuote.quoteRecord.DisplayOrder__c)-1] = change;
        }else if('DOWN' == direction) {
            var chosen = allQuotes[parseInt(whichQuote.quoteRecord.DisplayOrder__c)-1];
            var change = allQuotes[parseInt(whichQuote.quoteRecord.DisplayOrder__c)];
            
            allQuotes[parseInt(whichQuote.quoteRecord.DisplayOrder__c)] = chosen;
            allQuotes[parseInt(whichQuote.quoteRecord.DisplayOrder__c)-1] = change;
        }
        
        for (var i = 0 ; i < allQuotes.length ; i++){
            allQuotes[i].quoteRecord.DisplayOrder__c = i+1;
        }
        
        component.set("v.quotes", allQuotes);
    },
    
    selectAll : function(component, event, helper){
        var allQuotes = component.get("v.quotes");
        for (var i = 0 ; i < allQuotes.length ; i++){
            allQuotes[i].isSelected = true;
        }
        
        component.set("v.quotes", allQuotes);
    },
    
    deSelectAll : function(component, event, helper){
    	var allQuotes = component.get("v.quotes");
        for (var i = 0 ; i < allQuotes.length ; i++){
            allQuotes[i].isSelected = false;
        }
        
        component.set("v.quotes", allQuotes);    
    },
})