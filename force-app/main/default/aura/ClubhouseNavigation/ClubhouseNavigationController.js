({
    onInit : function(component, event, helper) {
        window.setTimeout(
            $A.getCallback(function() {
                try{
                    let url = 'clubhouse://clubhouse.golfbreaks.com/enquiry?id=0063z00001EK7O6AAL';
                    var e = document.createElement('a');
                    e.id = 'test';
                    e.href = url;
                    document.getElementById("containerDiv").appendChild(e);
                    e.click();
                    e.parentNode.removeChild(e);
                }catch(error){
                    alert(JSON.stringify(error));
                    component.set("v.errorMessage",JSON.stringify(error));
                }
            }), 5000
        );
        
    }
})