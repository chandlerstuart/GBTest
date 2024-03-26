({
    doMoveUp : function(component, event, helper){
		var currentDisplayOrder = component.get("v.quote.quoteRecord.DisplayOrder__c");
        console.log('displayOrder = ' + currentDisplayOrder);
        
        var theQuote = component.get("v.quote");
        var updateEvent = component.getEvent("quoteUpdated");
        updateEvent.setParams({
            "quote" : theQuote,
            "direction" : "UP"
        });
        
        updateEvent.fire();
    },
    doMoveDown : function(component, event, helper){
		var currentDisplayOrder = component.get("v.quote.quoteRecord.DisplayOrder__c");
        
        var theQuote = component.get("v.quote");
        var updateEvent = component.getEvent("quoteUpdated");
        updateEvent.setParams({
            "quote" : theQuote,
            "direction" : "DOWN"
        });
        
        updateEvent.fire();
    },
})