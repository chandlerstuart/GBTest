public with sharing class MockLocalEnquiryHandler implements IEnquiryRecordHandler{
    
    public Boolean processEnquiries(List<EnquiryManager.Enquiry> enquiries) {
        return true;
    }
}