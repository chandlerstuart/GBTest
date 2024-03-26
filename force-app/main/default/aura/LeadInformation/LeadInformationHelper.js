({
	setDefaultOppName : function(component) {
		var today = new Date();
        var dd = today.getDate();
        var mm = today.getMonth()+1; //January is 0!
    
        if(dd<10){
            dd='0'+dd
        } 
        if(mm<10){
            mm='0'+mm
        } 
        var today = dd+'/'+mm;
        var defaultOppName = "New enquiry made on "+today;
        return defaultOppName;
        
	}
})