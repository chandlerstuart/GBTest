({
    handleRecordSelection : function(component,event,helper){
        var recordSelectedEvent = component.getEvent("RecordSelected");
        recordSelectedEvent.setParams({ "SelectedRecord": component.get("v.record") });
        console.log('Firing Record Select Event'); 
        recordSelectedEvent.fire();
    }
})