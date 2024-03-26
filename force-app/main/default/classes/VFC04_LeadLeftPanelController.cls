/**
  * @author -         Jerome To (Accenture)
  * @date -           18/04/2016
  * @description -    Controller for leadLeftPanel
  * #############Change Log#############
  * Modified by     Version     Change Date
  **/

public with sharing class VFC04_LeadLeftPanelController {

  public List<SummaryReportWrapper> listSummaryReport {get; set;}
  private static final Id currentUser =  UserInfo.getUserId();

  public VFC04_LeadLeftPanelController() {
    listSummaryReport = new List<SummaryReportWrapper>(); 
    addSummaryReportLead();
    addSummaryReportOpportunity();
    addSummaryReportCase();
    addSummaryReportTask();
  }

  //method for adding summary report of leads
  private void addSummaryReportLead(){
    SummaryReportWrapper summaryReport = new SummaryReportWrapper();
    List<Lead> openRecord = [SELECT Id FROM Lead WHERE OwnerId = :currentUser AND (Status != 'No Sale' OR Status !='Closed-Converted')];
    summaryReport.objectName = 'Leads';
    summaryReport.totalOpenRecords = openRecord.size();
    listSummaryReport.add(summaryReport);
  }

   //method for adding summary report of opportunities
  private void addSummaryReportOpportunity(){
    SummaryReportWrapper summaryReport = new SummaryReportWrapper();
    List<Opportunity> openRecord = [SELECT Id FROM Opportunity WHERE OwnerId = :currentUser AND IsClosed = False];
    summaryReport.objectName = 'Opportunities';
    summaryReport.totalOpenRecords = openRecord.size();
    listSummaryReport.add(summaryReport);
  }

   //method for adding summary report of cases
  private void addSummaryReportCase(){
    SummaryReportWrapper summaryReport = new SummaryReportWrapper();
    List<Case> openRecord = [SELECT Id FROM Case WHERE OwnerId = :currentUser AND Status != 'Closed'];
    summaryReport.objectName = 'Cases';
    summaryReport.totalOpenRecords = openRecord.size();
    listSummaryReport.add(summaryReport);
  }

   //method for adding summary report of tasks
  private void addSummaryReportTask(){
    SummaryReportWrapper summaryReport = new SummaryReportWrapper();
    List<Task> openRecord = [SELECT Id FROM Task WHERE OwnerId = :currentUser AND Status != 'Closed'];
    summaryReport.objectName = 'Tasks';
    summaryReport.totalOpenRecords = openRecord.size();
    listSummaryReport.add(summaryReport);
  }

   //method for summary wrapper class
  public class SummaryReportWrapper{ 
      public String objectName {get;set;}
      public Integer totalOpenRecords {get;set;}
      public SummaryReportWrapper(){
        
      }
  }
}