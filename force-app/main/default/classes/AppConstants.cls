/*
Name:  AppConstants.cls
Copyright © 2014  CloudMethods
======================================================
======================================================
Purpose:
-------
All constants must be defined in this utility class.
Apex script should not contain primitive type literals.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2014-05-21  Initial development.
1.1  Mark Cane&    2015-03-12  Added Coop Funding related opp, quote and product record type constants.
1.2  Mark Cane&    2015-07-30  Added Salesforce_Support case record type constant.
*/
public class AppConstants {

	public final static String CASE_STATUS_ASSIGNED_TO_PRICING = 'Assigned To Pricing';
	public final static String CASE_STATUS_PRICING_COMPLETED = 'Pricing Completed';
	public final static String CASE_STATUS_IN_PROGRESS = 'In Progress';
	public final static String CASE_STATUS_ASSIGNED_TO_CASE_CREATOR = 'Assigned to Case Creator';
	
	public final static String ID_PREFIX_QUEUE = '00G';	
	
	public final static String ENTITLEMENT_PROCESS_NAME_PRICING_SLA = 'Pricing SLA';
	
	public final static String CASE_RECORD_TYPE_DEVELOPER_NAME_PRICING = 'Pricing';
	public final static String CASE_RECORD_TYPE_DEVELOPER_NAME_SALESFORCE_SUPPORT = 'Salesforce_Support';
	
	public final static String PRODUCT2_RECORD_TYPE_DEVELOPER_NAME_MARKETING_INVENTORY_ITEM = 'Marketing_Inventory_Item';
	public final static String QUOTE_RECORD_TYPE_DEVELOPER_NAME_COOP_FUNDING_PROPOSAL = 'Co_op_Funding_Proposal';	
	public final static String OPPORTUNITY_RECORD_TYPE_DEVELOPER_NAME_COOP_FUNDING = 'Co_op_Funding';
}