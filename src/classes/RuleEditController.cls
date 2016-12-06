public with sharing class RuleEditController {

    public Rule_set__c rulesetRecord{get;set;}
    public WorkflowRule__c wf{get;set;}
    public list<workFlowRuleInner> workFlowRuleEntrieInnerList{get;set;}
    public Boolean isEdit{get;set;}
    public String selectedruleEntryID{get;set;} 
    public String deleteruleEntryID{get;set;} 
    public Integer  counter          {get; set;}
    
    ApexPages.StandardController stdController;
    
    public RuleEditController(){
        
    }
    public List<SelectOption> getOrgObjects(){
        List<SelectOption> options = new List<SelectOption>();
                for(ApexTrigger existingTrigger : [SELECT ID,Name,TableEnumOrId from ApexTrigger where Name LIKE 'IncapRule%' And Status = 'Active']){
                        options.add(new SelectOption(existingTrigger.TableEnumOrId,Schema.getGlobalDescribe().get(existingTrigger.TableEnumOrId).getDescribe().getLabel()));
                }
        
        return WorkflowRuleUtils.selectOptionSortByLabel(options);
    }
     
    public RuleEditController(ApexPages.StandardController controller) {
        if(Apexpages.currentpage().getparameters().get('id') != null){
            isEdit = true;
        }else{
            isEdit = false;
        }
        list<string> fieldList = new list<string>{'Name','Active__c','Type__c','Object_Name__c','CreatedById'};
        if(!Test.isRunningTest()){
                controller.addfields(fieldList);
        }
        rulesetRecord = (Rule_set__c)controller.getRecord();
        stdController = controller;
        workFlowRuleEntrieInnerList = new list<workFlowRuleInner>();
        prepareData();
    }
    
    //Innerclass
    public class workFlowRuleInner{
        public WorkflowRule__c ruleEntry{get;set;}
        public String entryCriteria{get;set;}
        public String actions{get;set;}
        public Integer  counter          {get; set;}
        //Constructor
        public workFlowRuleInner(WorkflowRule__c ruleEntry ,String entryCriteria, String actions){
            this.ruleEntry = ruleEntry ;
            this.entryCriteria = entryCriteria;
            this.actions = actions;
        }
        
    }
    
    //method to redirect to new Rule Page
    public pageReference gotoNewRule(){
        pageReference createRulePage = Page.WorkflowRule;
        createRulePage.setredirect(true);
        createRulePage.getParameters().put('retURL',Apexpages.currentpage().getUrl());
        createRulePage.getParameters().put('rulesetID',rulesetRecord.id);
        createRulePage.getParameters().put('obj',rulesetRecord.Object_Name__c);
        return createRulePage; 
    }
    
    //Method to override Save Method
    public void onSave(){
        stdController.save();
        isEdit = true; 
    }
    // method to deactive 
    public void deactive(){  
        rulesetRecord.Active__c=false;
        update rulesetRecord;  
    }    
    
    //method to clone
        public static void ruleclone(){
        //public WorkflowRule__c ruleEntry{get;set;}
        WorkflowRule__c newWF;    
        
         WorkflowTriggerUtility.cloneWithWorkflowRule(newWF,true,true); 
       } 
    // method to remove RuleEntry   
    public void ruleEntryDelete(){ 
        if(Apexpages.currentpage().getparameters().get('deleteruleEntryID') != null){
         if (Schema.sObjectType.WorkflowRule__c.isDeletable()){
                                 delete [SELECT id from WorkflowRule__c where id=:Apexpages.currentpage().getparameters().get('deleteruleEntryID')];
                        } 
                workFlowRuleEntrieInnerList = new list<workFlowRuleInner>();
        prepareData();
        }  
    } 
    public pageReference  ruleEntryEdit(){
        
        pageReference createRulePage = Page.WorkflowRule;
        createRulePage.setredirect(true);
        createRulePage.getParameters().put('retURL',Apexpages.currentpage().getUrl());
        createRulePage.getParameters().put('id',Apexpages.currentpage().getparameters().get('selectedruleEntryID'));
        return createRulePage; 
    }
    
   
    
    //Method to prepare data onLoad
    private void prepareData(){
        if(isEdit){
            for(WorkflowRule__c workFlowRule : pullAllWorkFlowRules(rulesetRecord.id)){
                workFlowRuleEntrieInnerList.add(new workFlowRuleInner(workFlowRule,'',''));
            }
        }
    }
    
    //Method to save All the entries 
    public void saveAllEntries(){
        list<WorkflowRule__c> workFlowRuletoUpsert = new list<WorkflowRule__c>();
        for(workFlowRuleInner innerEntryRecord : workFlowRuleEntrieInnerList){
            workFlowRuletoUpsert.add(innerEntryRecord.ruleEntry);
        }
        
        //upsert the record
        if(workFlowRuletoUpsert.size()>0){
            upsert workFlowRuletoUpsert;
        }
    }
    
    //Method to query Rule Entries
    private list<WorkflowRule__c> pullAllWorkFlowRules(ID ruleSetID){
        return  [Select Id, OwnerId, IsDeleted, Name, RecordTypeId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastViewedDate, LastReferencedDate, Active__c, Description__c, DisplayActions__c, DisplayfilterLogic__c, Evaluation_Rule__c, Filter_Logic__c, FormattedFilterLogic__c, Object_Name__c, Order__c, Status__c, Version__c, Effective_Date__c, Expiration_Date__c, Advanced_Filter__c, Ruleset__c From WorkflowRule__c WHERE Ruleset__c =:rulesetRecord.id Order By Order__c];
        
    }
    
}