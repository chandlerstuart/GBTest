/**
 * Class TriggerFactory
 *
 * Used to instantiate and execute Trigger Handlers associated with sObjects.
 */
public class TriggerFactory
{
    /**
     * Public static method to create and execute a trigger handler
     *
     * Arguments:   Schema.sObjectType soType - Object type to process (SObject.sObjectType)
     *
     * Throws a TriggerException if no handler has been coded.
     */
    public static void createHandler(Type t) {
        // Get a handler appropriate to the object being processed
        TriggerHandlerInterface handler = getHandler(t);
        
        // Make sure we have a handler registered, new handlers must be registered in the getHandler method.
        if (handler == null) {
            throw makeNewException(t);
        }
        
        // Execute the handler to fulfil the trigger
        execute(handler);
    }
    
    public class TriggerException extends Exception{}
    
    private static TriggerException makeNewException(Type constName) {
        TriggerException trigException = new TriggerException();
        trigException.setMessage('No Trigger Handler registered for Object Type: ' + constName);
        return trigException;
    }
    
    /**
     * private static method to control the execution of the handler
     *
     * Arguments:   TriggerHandlerInterface handler - A Trigger Handler to execute
     */ 
    private static void execute(TriggerHandlerInterface handler) {
        // Before Trigger
        if (Trigger.isBefore) {
        
            // Call the bulk before to handle any caching of data and enable bulkification
            handler.bulkBefore();
            
            // Iterate through the records to be deleted passing them to the handler.
            if (Trigger.isDelete) { 
                for (SObject so : Trigger.old) {
                    handler.beforeDelete(so);
                }
            }
            // Iterate through the records to be inserted passing them to the handler.
            else if (Trigger.isInsert) { 
                for (SObject so : Trigger.new) {
                    handler.beforeInsert(so);
                }
            }
            // Iterate through the records to be updated passing them to the handler.
            else if (Trigger.isUpdate) { 
                for (SObject so : Trigger.old) {
                    handler.beforeUpdate(so, Trigger.newMap.get(so.Id));
                }
            }
        }
        else{
            // Call the bulk after to handle any caching of data and enable bulkification
            handler.bulkAfter();
        
            // Iterate through the records deleted passing them to the handler.
            if (Trigger.isDelete){ 
                for (SObject so : Trigger.old) {
                    handler.afterDelete(so);
                }
            }
            // Iterate through the records inserted passing them to the handler.
            else if (Trigger.isInsert) { 
                for (SObject so : Trigger.new) {
        
                    handler.afterInsert(so);
                }
            }
            // Iterate through the records updated passing them to the handler.
            else if (Trigger.isUpdate) {  
                for (SObject so : Trigger.old) {
                    handler.afterUpdate(so, Trigger.newMap.get(so.Id));
                }
            }
        }
        
        // Perform any post processing
        handler.andFinally();

    }
    
    /**
     * private static method to get the named handler.
     *
     * Arguments:   Type t - Class of handler to instatiate
     *
     * Returns:     TriggerHandlerInterface - A trigger handler if one exists or null.
     */
    private static TriggerHandlerInterface getHandler(Type t) {
        // Instantiate the type
        Object o = t.newInstance();
        
        // if its not an instance of TriggerHandlerInterface return null
        if (!(o instanceOf TriggerHandlerInterface)) {
            return null;
        }
 
        return (TriggerHandlerInterface) o;
    }
}