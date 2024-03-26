({
	onInit : function(component, event, helper) {
        helper.getCalendarFilters(component);
	},
    
    afterScriptsLoaded : function(component, event, helper) {
        helper.getCalendarEvents(component, false);
	},
    
    filterChange : function(component, event, helper) {
        helper.getCalendarEvents(component, true);
	},
    
    exportToPDF : function(component, event, helper) {
        helper.exportCalendarAsPDF(component);
	},
    exportToIMAGE : function(component, event, helper) {
        helper.exportCalendarAsJPEG(component);
	}
})