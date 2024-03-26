({
    onInit : function(component, event, helper) {
        let url = component.get("v.url");
        if(url != null && url.includes('{*recordId*}')){
            let recordId = component.get("v.recordId");
            url = url.replace('{*recordId*}',recordId);
        }
        component.set("v.source",url);
    }
})