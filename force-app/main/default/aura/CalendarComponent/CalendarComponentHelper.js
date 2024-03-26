({
	getCalendarFilters : function(component) {
        var getCalFilters = component.get("c.getCalendarFilters");
        getCalFilters.setCallback(this, function(a){
            if(a.getState() ==='SUCCESS'){
                component.set("v.recordTypes", a.getReturnValue().recordTypes);
                component.set("v.eventTypes", a.getReturnValue().eventTypes);
                component.set("v.territories", a.getReturnValue().territories);
            }else{
                var toastEvent = $A.get("e.force:showToast");
                if(toastEvent){
                    toastEvent.setParams({
                    "title": "Error!",
                    "message": " Something has gone wrong."
                	});
                    toastEvent.fire();
                }
                else{
                    var errors = a.getError();
                    var message = "Errors: "
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                     errors[0].message);
                            message += errors[0].message;
                        }
                        alert(message);
                    } else {
                        console.log("Unknown error");
                    }
                }
            }
            
        });
         $A.enqueueAction(getCalFilters);
    },
    getCalendarEvents : function(component, isRefresh) {
        var getCalEvents = component.get("c.getCalEvents");
        var recType = component.find("recordTypeBox").get("v.value");
        var eventType = component.find("eventTypeBox").get("v.value");
        var territory = component.find("territoryBox").get("v.value");
        getCalEvents.setParams({"sSelectedChannel" : "-None-", "sSelectedType" : eventType, "sSelectedRecordType" : recType, "sSelectedTerritory": territory});
        getCalEvents.setCallback(this, function(a){
            if(a.getState() ==='SUCCESS'){
                component.set("v.events", a.getReturnValue());
                var eventObjects = JSON.parse(a.getReturnValue());//JSON.parse("[{\"allDay\":false,\"url\":\"/7018E000000Ex0TQAS\",\"end\":\"Wed, 17 Feb 2016 20:00:00 GMT\",\"start\":\"Wed, 17 Feb 2016 07:00:00 GMT\",\"title\":\"ABS CBN\"},{\"allDay\":true,\"url\":\"/7018E000000Ex09QAC\",\"end\":\"Fri, 19 Feb 2016 20:00:00 GMT\",\"start\":\"Sat, 13 Feb 2016 07:00:00 GMT\",\"title\":\"Mall Show\"}]");
                if(isRefresh){
                    this.refreshCalendar(component, eventObjects);
                }
                else{
                	this.loadCalendar(component, eventObjects);
                }
                
            }else{
                var toastEvent = $A.get("e.force:showToast");
                if(toastEvent){
                    toastEvent.setParams({
                    "title": "Error!",
                    "message": " Something has gone wrong."
                	});
                    toastEvent.fire();
                }
                else{
                    var errors = a.getError();
                    var message = "Errors: "
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                     errors[0].message);
                            message += errors[0].message;
                        }
                        alert(message);
                    } else {
                        console.log("Unknown error");
                    }
                }
            }
            
        });
         $A.enqueueAction(getCalEvents);
    },
    
    loadCalendar : function(component, eventsList){
		$('#calendar').fullCalendar({
                header: {
                    left: 'prev,next today',
                    center: 'title',
                    right: 'month,agendaWeek,agendaDay'
                    
                },
                editable: true,
                aspectRatio: 3,
            	events: eventsList,
            	height: "auto",
            	fixedWeekCount: false,
            	eventTextColor: "#808080"
            });
	},
    
    refreshCalendar : function(component, eventsList){
        console.log('eventslist'+eventsList);
        $('#calendar').fullCalendar('removeEvents');
        $('#calendar').fullCalendar('addEventSource', eventsList);
	},
    exportCalendarAsPDF : function(component){
        var doc = new jsPDF('landscape');
        var recType = component.find("recordTypeBox").get("v.value");
        var eventType = component.find("eventTypeBox").get("v.value");
        var territory = component.find("territoryBox").get("v.value");
        if(recType == undefined) {recType = "None";}
        if(eventType == undefined) {eventType = "None";}
        if(territory == undefined) {territory = "None";}
        html2canvas($('#exportTextId'), {
            logging: true,
            useCORS: true,
            background: "#ffffff",
            onrendered: function (canvas) {
                //doc.setFontSize(9);
                //doc.text(25, 30, "Record Type: "+recType+"\t\tEvent Type: "+eventType+ "\t\tTerritory: "+territory);
                var imgData = canvas.toDataURL("image/jpeg");
                doc.addImage(imgData, 'JPEG', 25, 20, 250, 165);
                download(doc.output(), "Calendar.pdf", "text/pdf");                         
            }
        });
        
        function download(strData, strFileName, strMimeType) {
            var D = document,
                A = arguments,
                a = D.createElement("a"),
                d = A[0],
                n = A[1],
                t = A[2] || "text/plain";
            
            //build download link:
            a.href = "data:" + strMimeType + "," + escape(strData);
            
            if (window.MSBlobBuilder) {
                var bb = new MSBlobBuilder();
                bb.append(strData);
                return navigator.msSaveBlob(bb, strFileName);
            } /* end if(window.MSBlobBuilder) */
            
            if ('download' in a) {
                a.setAttribute("download", n);
                a.innerHTML = "";
                D.body.appendChild(a);
                setTimeout(function() {
                    var e = D.createEvent("MouseEvents");
                    e.initMouseEvent("click", true, false, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
                    a.dispatchEvent(e);
                    D.body.removeChild(a);
                }, 66);
                return true;
            } /* end if('download' in a) */    
            
            //do iframe dataURL download:
            var f = D.createElement("iframe");
            D.body.appendChild(f);
            f.src = "data:" + (A[2] ? A[2] : "application/octet-stream") + (window.btoa ? ";base64" : "") + "," + (window.btoa ? window.btoa : escape)(strData);
            setTimeout(function() {
                D.body.removeChild(f);
            }, 333);
            return true;
        };
    },
    exportCalendarAsJPEG : function(component){
        html2canvas($('#exportTextId'), {
            logging: true,
            useCORS: true,
            background: "#ffffff",
            onrendered: function (canvas) {
                var MIME_TYPE = "image/png";
                var imgData = canvas.toDataURL(MIME_TYPE);
                var dlLink = document.createElement('a');
                dlLink.download = 'Calendar.png';
                dlLink.href = imgData;
                dlLink.dataset.downloadurl = [MIME_TYPE, dlLink.download, dlLink.href].join(':');
                
                document.body.appendChild(dlLink);
                dlLink.click();
                document.body.removeChild(dlLink);
            }
        });
    }
})