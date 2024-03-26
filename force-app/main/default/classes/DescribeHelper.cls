/*
Name: DescribeHelper.cls
Copyright � 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Describer Helper class - general describe functions related to a SObjectType.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-13  Initial development.
1.1  Mark Cane&    2019-07-01  Added sotToFieldTokenMap.
1.2  Mark Cane&    2019-07-01  Added getObjectParentRelationshipMap.
1.3  Mark Cane&    2020-04-20  Added getFieldDisplayType.
1.4  J Radcliffe   2020-05-05  Bug Fix - Added support for 'Owner' relationship fields to be included in DET request bodies (previously no polymorphic fields permitted)
1.5  Mark Cane&    2020-05-13  Enhancements to 1.4 to support a generic design approach for polymorphic parent relationship fields.
1.6  J Radcliffe   2021-08-02  Bug Fix/Workaround - Adding try/catch around getDescribe method to account for any issues caused by version misalignment
1.7  Mark Cane&    2023-11-23  Enhancements - sotToAccessibleFieldTypeMap.
*/
public with sharing class DescribeHelper {
  
    public static Map<String, Schema.SObjectType> globalDescribe;
    private static Map<String, Map<String,Schema.SObjectField>> sotToFieldTokenMap;//1.1+
    private static Map<String, Map<String,List<String>>> sotToParentRelationshipMap;//1.1+ 1.5~
    private static Map<String, Map<String,Schema.DisplayType>> sotToFieldTypeMap;//1.3+
    private static Map<String, Map<String,Schema.DisplayType>> sotToAccessibleFieldTypeMap;//1.7+
    private static Map<Schema.SObjectType,String> sObjectTypeToName;//1.3+
      
    static {
        globalDescribe = Schema.getGlobalDescribe();

        sotToFieldTokenMap = new Map<String, Map<String,Schema.SObjectField>>();//1.1+
        sotToParentRelationshipMap = new Map<String, Map<String,List<String>>>();//1.2+ 1.5~
        sotToFieldTypeMap = new Map<String, Map<String,Schema.DisplayType>>();//1.3+
        sObjectTypeToName = new Map<Schema.SObjectType,String>();//1.3+
        sotToAccessibleFieldTypeMap = new Map<String, Map<String,Schema.DisplayType>>();//1.7+
    }

    public static String getSObjectTypeName(Schema.SObjectType sObjectType){//1.3+
        if (!sObjectTypeToName.containsKey(sObjectType)) sObjectTypeToName.put(sObjectType,sObjectType.getDescribe().getName());
        return sObjectTypeToName.get(sObjectType);
    }

    public static Map<String,Schema.SObjectField> getObjectFieldMap(String sot){

        if (!sotToFieldTokenMap.containsKey(sot)){
            Schema.DescribeSObjectResult d = globalDescribe.get(sot).getDescribe();

            sotToFieldTokenMap.put(sot,d.fields.getMap());            
        }
        return sotToFieldTokenMap.get(sot);
    }    

    public static Map<String,Schema.DisplayType> getObjectAccessibleFieldMap(String sot){//1.7+

        if (!sotToAccessibleFieldTypeMap.containsKey(sot)){

            sotToAccessibleFieldTypeMap.put(sot,new Map<String,Schema.DisplayType>());

            Schema.DescribeSObjectResult d = globalDescribe.get(sot).getDescribe();
            Schema.DescribeFieldResult fd;

            for (Schema.SObjectField f : d.fields.getMap().values()){
                fd = f.getDescribe();
                //[Removed for release] LoggingLevel.ERROR,fd);
                
                if (!fd.isPermissionable() || !fd.isAccessible()) continue;
                
                sotToAccessibleFieldTypeMap.get(sot).put(fd.getName(),fd.getType());
            }
        }
        return sotToAccessibleFieldTypeMap.get(sot);
    }

    public static Schema.DisplayType getFieldDisplayType(String sot, String fieldName){//1.3+

        if (sotToFieldTypeMap.containsKey(sot) && sotToFieldTypeMap.get(sot).containsKey(fieldName)) return sotToFieldTypeMap.get(sot).get(fieldName);

        if (!sotToFieldTokenMap.containsKey(sot)) getObjectFieldMap(sot);
        if (sotToFieldTokenMap==null || !sotToFieldTokenMap.containsKey(sot) || !sotToFieldTokenMap.get(sot).containsKey(fieldName)) return null;

        Schema.DescribeFieldResult fd =  sotToFieldTokenMap.get(sot).get(fieldName).getDescribe();

        if (!sotToFieldTypeMap.containsKey(sot)) sotToFieldTypeMap.put(sot, new Map<String,Schema.DisplayType>());
        sotToFieldTypeMap.get(sot).put(fieldName,fd.getType());

        return fd.getType();
    }
  
	public static Map<String,List<String>> getObjectParentRelationshipMap(String sot){//1.2+ 1.5~
        
        if (sotToParentRelationshipMap.containsKey(sot)) return sotToParentRelationshipMap.get(sot);

        sotToParentRelationshipMap.put(sot, new Map<String,List<String>>());//1.5~

        Schema.DescribeFieldResult fd;

        //1.5- Boolean isOwnerField = false;//1.4+
        //1.5- Set<String> relatedObjects;//1.4+
        for (Schema.SObjectField f : getObjectFieldMap(sot).values()){
            //1.5- isOwnerField = false;//1.4+
            try{//1.6+
                fd = f.getDescribe();
            }catch(Exception e){
                //[Removed for release] e.getStackTraceString()+'-'+e.getMessage());
                continue;
            }
            //1.5- if(fd.getType()==Schema.Displaytype.Reference && fd.getReferenceTo().size()==2){//1.4+
            //1.5-     relatedObjects = new Set<String>();
            //1.5-     for(Schema.sObjectType refToSOT : fd.getReferenceTo()){relatedObjects.add(refToSOT.getDescribe().getName().toUpperCase());}
            //1.5-     isOwnerField = (relatedObjects.contains('USER') && relatedObjects.contains('GROUP'))? true:false;
            //1.5- }

            //1.5- if (fd.getType()!=Schema.Displaytype.Reference || (fd.getReferenceTo().size()!=1 && !isOwnerField)) continue;//1.4~
            if (fd.getType()!=Schema.Displaytype.Reference) continue;//1.5~

            //1.5-if(isOwnerField){//1.4+
            //1.5-    sotToParentRelationshipMap.get(sot).put(fd.getRelationshipName(),'User');//Explicitly add to Map to avoid adding the Queue SOT (from the 0 index) 
            //1.5-}else{                

            sotToParentRelationshipMap.get(sot).put(fd.getRelationshipName(),new List<String>());

            for(Schema.sObjectType refToSOT : fd.getReferenceTo()){ sotToParentRelationshipMap.get(sot).get(fd.getRelationshipName()).add(refToSOT.getDescribe().getName()); }
        }
        return sotToParentRelationshipMap.get(sot);
    }
}