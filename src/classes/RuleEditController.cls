public with sharing class RuleEditController {
    public Rule_set__c rulesetRecord{get;set;}
    public list<workFlowRuleInner> workFlowRuleEntrieInnerList{get;set;}
    public RuleEditController(){
        
    }
    
    //Innerclass
    public class workFlowRuleInner{
        public WorkflowRule__c ruleEntry{get;set;}
        public String entryCriteria{get;set;}
        public String actions{get;set;}
    }
}