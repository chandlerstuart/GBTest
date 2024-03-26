/*
Name:  VFC16_EmployeeProductServiceSetup.cls
======================================================
======================================================
Purpose:
-------
Controller class for VF Page VFP16_EmployeeProductServiceSetup

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-11-10  Initial development.
*/
public with sharing class VFC16_EmployeeProductServiceSetup {
    // the soql without the order and limit
    private String soql {get; set;}
    // the collection of contacts to display
    public List<Product_Service__c> products {get; set;}
    // the collection of Wrappers to display
    public List<ProductServiceWrapper> productWrappers {get; set;}
    // size of Product list for use on VF Page
    public integer productListSize {
        get {
            if (productWrappers == null || productWrappers.isEmpty()){
                return 0;
            }else {
                return productWrappers.size();
            }
        }
        set;
    }
    // the current sort direction. defaults to asc
    public String sortDir {
        get  { 
            if (sortDir == null) {  sortDir = 'asc'; } return sortDir;  
        }
        set;
    }
    // the current field to sort by. defaults to last name
    public String sortField {
        get  { 
            if (sortField == null) {sortField = 'Product_Service_Name__c'; } return sortField;  
        }
        set;
    }
    // format the soql for display on the visualforce page
    public String debugSoql {
        get { 
            return soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT 50'; 
        }
        set;
    }
    // List of Department records
    public List<SelectOption> departments {
        get {
            if (null == departments){
                departments = new List<SelectOption>();
                departments.add(new SelectOption('','-- All --'));

                for (Department__c d : [select Id, Name from Department__c ORDER BY Name ASC]){
                    departments.add(new SelectOption(d.Id, d.Name));
                }
            }

            return departments;
        }
        set;
    }

    // List of 'Default' options
    public List<SelectOption> defaultSelections {
        get {
            if (null == defaultSelections){
                defaultSelections = new List<SelectOption>();
                defaultSelections.add(new SelectOption('','-- None --'));
                defaultSelections.add(new SelectOption('BO','Back Office'));
                defaultSelections.add(new SelectOption('CC','Contact Centre'));
                defaultSelections.add(new SelectOption('IT','Team IT'));
            }

            return defaultSelections;
        }
        set;
    }

    public Map<String, String> defaultFieldMap {
        get {
            if (null == defaultFieldMap){
                defaultFieldMap = new Map<String, String>();
                defaultFieldMap.put('BO','Default_BO_User__c');
                defaultFieldMap.put('CC','Default_CC_User__c');
                defaultFieldMap.put('IT','Default_IT_User__c');
            }
            return defaultFieldMap;
        }
        set;
    }

    // List of Employment records
    public List<SelectOption> employees {
        get {
            if (null == employees){
                employees = new List<SelectOption>();
                employees.add(new SelectOption('','-- None --'));
                if (null == selectedDepartment || String.isBlank(selectedDepartment)){
                    for (Employment__c e : [select Id, User__c, User__r.Name from Employment__c where Current_Employment__c = TRUE ORDER BY User__r.Name ASC]){
                        employees.add(new SelectOption(e.Id, e.User__r.Name));
                    }
                }else {
                    for (Employment__c e : [select Id, User__c, User__r.Name from Employment__c where Current_Employment__c = TRUE 
                                            AND Department__c = :selectedDepartment ORDER BY User__r.Name ASC]){
                        employees.add(new SelectOption(e.Id, e.User__r.Name));
                    }
                }
            }

            return employees;
        }
        set;
    }

    // Selected Department
    public Id selectedDepartment {get; set;}
    // Selected Employee
    public Id selectedEmployee {get; set;}
    // Selected Default 
    public String selectedDefault {get; set;}
    // Current list of Resource records
    public List<ResourceWrapper> currentRecords {
        get {
            if (null == currentRecords) currentRecords = new List<ResourceWrapper>();
            return currentRecords;
        }
        set;
    }

    // Total Annual Cost for an Employee
    public Decimal totalAnnualCost {
        get {
            if (null == totalAnnualCost) totalAnnualCost = 0;
            return totalAnnualCost;
        }
        set;
    }
    // Total Monthly Cost for an Employee
    public Decimal totalMonthlyCost {
        get {
            if (null == totalMonthlyCost) totalMonthlyCost = 0;
            return totalMonthlyCost;
        }
        set;
    }

    public VFC16_EmployeeProductServiceSetup() {
        init();
    }

    public void init(){
        soql = 'SELECT Product_Service_Name__c, Account__c, Account__r.Name, Annual_Cost__c, Monthly_Cost__c FROM Product_Service__c WHERE Product_Service_Name__c != NULL';
        runQuery(); 
    }

    public PageReference clearEmployees(){
        employees = null;
        return null;
    }

    public PageReference getCurrentRecords(){
        totalAnnualCost = 0;
        totalMonthlyCost = 0;
        currentRecords = new List<ResourceWrapper>();
        system.debug('*** -- selectedEmployee = ' + selectedEmployee + ' -- ***');
        if (null != selectedEmployee && !String.isBlank(selectedEmployee)){
            for (Product_Service_Resource__c psr : [SELECT Id, Product_Service__r.Product_Service_Name__c, Product_Service__r.Account__r.Name,  
                                                    Employment__c, Product_Service_Annual_Cost__c, Product_Service_Monthly_Cost__c FROM Product_Service_Resource__c where Employment__c = :selectedEmployee
                                                    ORDER BY Product_Service__r.Product_Service_Name__c ASC]){
                currentRecords.add(new ResourceWrapper(psr));

                totalAnnualCost += (null == psr.Product_Service_Annual_Cost__c ? 0 : psr.Product_Service_Annual_Cost__c);
                totalMonthlyCost += (null == psr.Product_Service_Monthly_Cost__c ? 0 : psr.Product_Service_Monthly_Cost__c);
                
                //Round the totals
                totalAnnualCost = totalAnnualCost.setScale(2);
                totalMonthlyCost = totalMonthlyCost.setScale(2);
            }
        }

        return null;
    }

    // toggles the sorting of query from asc<-->desc
    public void toggleSort() {
        // simply toggle the direction
        sortDir = sortDir.equals('ASC') ? 'DESC' : 'ASC';
        // run the query again
        runQuery();
    }

    // runs the actual query
    public void runQuery() {
        try {
          products = Database.query(soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT 50');
          productWrappers = buildWrappers(products);
        } catch (Exception e) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops!'));
        }
    }

    public PageReference fetchDefaults(){
        try {
                String defaultField;

                soql = 'SELECT Product_Service_Name__c, Account__c, Account__r.Name, Annual_Cost__c, Monthly_Cost__c FROM Product_Service__c ';
                soql += ' WHERE Product_Service_Name__c != NULL ';
                if (!String.isBlank(selectedDefault)) {
                    defaultField = defaultFieldMap.get(selectedDefault);
                    soql += 'AND ' + defaultField + ' = \'Yes\'';
                }

                products = Database.query(soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT 50');
                productWrappers = buildWrappers(products);  
            }catch (Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops!'));
            }

            return null;
    }

    // runs the search with parameters passed via Javascript
    public PageReference runSearch() {

        String defaultField;
        String productName = Apexpages.currentPage().getParameters().get('productname');
        String accountName = Apexpages.currentPage().getParameters().get('accountname');
        
        soql = 'SELECT Product_Service_Name__c, Account__c, Account__r.Name, Annual_Cost__c, Monthly_Cost__c FROM Product_Service__c WHERE Product_Service_Name__c != NULL';
        if (!String.isBlank(productName))
          soql += ' AND Product_Service_Name__c LIKE \''+String.escapeSingleQuotes(productName)+'%\'';
        if (!String.isBlank(accountName))
          soql += ' AND Account__r.Name LIKE \''+String.escapeSingleQuotes(accountName)+'%\'';
        if (!String.isBlank(selectedDefault)){
          defaultField = defaultFieldMap.get(selectedDefault);
          soql += 'AND ' + defaultField + ' = \'Yes\'';
        }
        /*if (!accountName.equals(''))
          soql += ' and account.name LIKE ''+String.escapeSingleQuotes(accountName)+'%'';  
        if (!technology.equals(''))
          soql += ' and interested_technologies__c includes (''+technology+'')';
        */
        // run the query again
        runQuery();

        return null;
    }

    public PageReference saveSelection(){
        // Validate that we are not saving PSR records that already exist
        Map<String, Product_Service_Resource__c> currentRecordMap = new Map<String, Product_Service_Resource__c>();
        if (currentRecords != null && !currentRecords.isEmpty()){
            for (ResourceWrapper rw : currentRecords){
                currentRecordMap.put(rw.resource.Employment__c + '~' + rw.resource.Product_Service__c, rw.resource);
            }
        }
        List<Product_Service_Resource__c> psrList = new List<Product_Service_Resource__c>();


        if (null == selectedEmployee || String.isBlank(selectedEmployee)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select an Employee first'));
            return null;
        }
        for (ProductServiceWrapper psw : productWrappers){
            if (psw.isSelected){
                if (!currentRecordMap.containsKey(selectedEmployee + '~' + psw.productService.Id)){
                    psrList.add(new Product_Service_Resource__c(Product_Service__c = psw.productService.Id, Employment__c = selectedEmployee));
                }
            }
        }

        if (!psrList.isEmpty()) insert psrList;

        getCurrentRecords();
        //Do not re-run the init method so we do not muck up the Product / Service list
        //init();

        return null;
    }

    public PageReference deleteSelected(){
        List<Product_Service_Resource__c> psrDelete = new List<Product_Service_Resource__c>();
        for (ResourceWrapper rw : currentRecords){
            if (rw.isSelected) psrDelete.add(rw.resource);
        }
        if (!psrDelete.isEmpty()){
            delete psrDelete;
        }

        selectedDefault = null;
        getCurrentRecords();
        init();

        return null;
    }
    
    public PageReference clearDeptEmp(){
        employees = null;
        selectedDepartment = null;
        selectedEmployee = null;
        currentRecords = null;
        
        return null;
        
    }

    public List<ProductServiceWrapper> buildWrappers(List<Product_Service__c> products){
        List<ProductServiceWrapper> wrapperList = new List<ProductServiceWrapper>();
        for (Product_Service__c ps : products){
            wrapperList.add(new ProductServiceWrapper(ps));
        }

        return wrapperList;
    }

    public class ProductServiceWrapper {
        public Product_Service__c productService {get; set;}
        public boolean isSelected {get; set;}

        public ProductServiceWrapper(Product_Service__c ps){
            this.productService = ps;
        }
    }

    public class ResourceWrapper {
        public Product_Service_Resource__c resource {get; set;}
        public boolean isSelected {get; set;}

        public ResourceWrapper(Product_Service_Resource__c psr){
            this.resource = psr;
        }
    }
}