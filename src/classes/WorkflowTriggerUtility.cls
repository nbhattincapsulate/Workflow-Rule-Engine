public with sharing class WorkflowTriggerUtility {
  /* @description This function will evaluate a list of objects which are enabled for workflow. It will create Trigger and test classes as per requirement.
   * @Vrajesh Sheth
   * 
   */
    //Method to send request 
    //@param: Httprequest 
    //@param : httpResponse
    public static HttpResponse sendRequesttoServer(Httprequest request){
        Http httpReq = new Http();
        HttpResponse response = httpReq.send(request);
        return response;        
    }
    
    //Method to prepare HttpRequest
    //@param: 
    //@return: Httprequest
    public static Httprequest prepareHttprequest(String endPointUrl,String reqMethod,map<string,string> reqHeader,String reqBody){
        Httprequest request = new HttpRequest();
        request.setEndpoint(endPointUrl);
        request.setMethod(reqMethod);
        for(String header : reqHeader.keyset()){
            request.setHeader(header , reqHeader.get(header));
        }
        request.setBody(reqBody);
        system.debug('==request===>'+reqBody);
        return request;     
    }
    
    //Method to prepare Trigger Creation Request
    //@param:
    //@return :
    public static String createCreateTriggerBody(String sObjectName){
        
        String customsObjectName = sObjectName.contains('__c')?sObjectName.removeEndIgnoreCase('__c'):sObjectName;
        JSONGenerator gen = JSON.createGenerator(true);
        
        gen.writeStartObject();
        gen.writeStringField('Name', 'IncapRule'+customsObjectName+'Trigger');
        gen.writeStringField('TableEnumOrId', sObjectName);
        String bodyString = 'trigger IncapRule'+customsObjectName+'Trigger on '+sObjectName+'(after insert,after update){';
        bodyString += 'Set<Id> Ids=new Set<Id>(); String sobjName=\''+sObjectName+'\';';
        bodyString += 'for ('+sObjectName+' record:trigger.new){ Ids.add(record.Id); }';
        bodyString += 'Boolean evaluate = WorkflowRuleEvaluation.EvaluationIsRunning;';
        bodyString += 'try{ if (!evaluate){ WorkflowRuleEvaluation.startWorkflow(Ids,sobjName,Trigger.isInsert);}}';
        bodyString += 'catch(Exception e){if(Test.isRunningTest()){} else{throw(e);  }}}';
        gen.writeStringField('Body', bodyString);
        gen.writeEndObject();
        system.debug('===json===>'+gen.getAsString()); 
        return gen.getAsString();
        
    }
    
    //Method to prepare deacitvate trigger logic body
    //@param:
    //@return:
    public static String createdeactivateTriggerBody(String triggerName){
    	JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('Name', triggerName);
        gen.writeStringField('Status', 'Inactive');
        gen.writeEndObject();
        return gen.getAsString(); 
        
    }
    
    //Method to deactivate trigger
    public static HttpResponse  deleteTrigger(String sObjectName ,Id triggerID,String triggerName){
        WorkflowConfiguration__c configuration = WorkflowConfiguration__c.getValues('Settings');
        String endPointURL = configuration.Base_Url__c + '/services/data/v38.0/sobjects/ApexTrigger/'+triggerID;
        map<String,String> headerMap = new map<String,String>();
        headerMap.put('Content-Type', 'application/json');
        headerMap.put('Authorization', 'OAuth ' + UserInfo.getSessionId());
        String requestBody = createdeactivateTriggerBody(triggerName);
        return sendRequesttoServer(prepareHttprequest(endPointURL,'DELETE',headerMap,requestBody)); 
    }
    
    
    
    //Method to send request for Trigger Creation
    //@param:
    //@return:
    public static HttpResponse sendRequestforTriggerCreation(String sObjectName){
        WorkflowConfiguration__c configuration = WorkflowConfiguration__c.getValues('Settings');
        String endPointURL = configuration.Base_Url__c + '/services/data/v38.0/sobjects/ApexTrigger';
        map<String,String> headerMap = new map<String,String>();
        headerMap.put('Content-Type', 'application/json');
        headerMap.put('Authorization', 'OAuth ' + UserInfo.getSessionId());
        String requestBody = createCreateTriggerBody(sObjectName);
        return sendRequesttoServer(prepareHttprequest(endPointURL,'POST',headerMap,requestBody));
    }
    /*
    //Method to get query all the fields for any sObject
    //@param: objectapiname
    //@return: set of field api name
    public static set<String> getAllfieldsforSObject(String objectAPIName){
        SObjectType objToken = Schema.getGlobalDescribe().get(objectAPIName);
        Map<String,Schema.SObjectField> mapSObjFieldList = objToken.getDescribe().fields.getMap();
        return mapSObjFieldList.keySet();     
    }

    //Method to create query string with all fields of the object
    //@param: ObjectAPIName, WhereClausestring, string list of extrafields
    //@return: soql string
    public static string createSOQLQuery(String sObjectAPIName,String whereClause,list<String> extraFieldsList){
        list<String> fieldNames =  new List<String>(getAllfieldsforSObject(sObjectAPIName));
        String soqlquery = 'SELECT '+ String.join( fieldNames, ',' );
        //Add extra fields if needed
        if(extraFieldsList != null && extraFieldsList.size()>0 ){
            soqlquery = soqlquery+',';
            soqlquery = soqlquery+ String.join( extraFieldsList, ',' );
        }
        //Complete the query
        soqlquery = soqlquery+' FROM '+sObjectAPIName+' WHERE '+whereClause;
        //system.debug('====>'+soqlquery);
        return soqlquery;
    }
     */
    //method called from the VF's action attribute to clone the WorkflowRule
     public static WorkflowRule__c cloneWithWorkflowRule(WorkflowRule__c wf,Boolean doCopyCriteria, Boolean doCopyAction) 
     {
     	WorkflowRule__c newWF;  
     	try{
     		//copy the WorkflowRule - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
     		 wf = [select Id, Name, Active__c, Advanced_Filter__c, Description__c, Effective_Date__c, Evaluation_Rule__c, Expiration_Date__c, Filter_Logic__c, FormattedFilterLogic__c,Object_Name__c,DisplayfilterLogic__c,Ruleset__c,Status__c, Order__c from WorkflowRule__c where id = :wf.id];
     		 newWF = wf.clone(false);
     		  if (Schema.sObjectType.WorkflowRule__c.isCreateable() ){
     		 insert newWF;  
     		  }
     		 // set the id of the new wf created for testing
             //newRecordId = newWF.id; 
            if(doCopyCriteria){  
            	
            // copy over the line WorkflowRuleCriteria items - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
            List<WorkflowRuleCriteria__c> items = new List<WorkflowRuleCriteria__c>();
            for (WorkflowRuleCriteria__c wc : [Select w.Id, w.Child_Relationship_Name__c, w.Criteria_Object__c, w.CrossFormula__c, w.Evaluate_ChildCriteria_Using__c,w.Evaluate_Criteria_Result_To__c,w.Field_API_Name__c,w.Field_Name__c,w.Field_Relation__c,w.Field_Type__c,w.GlobalVariable__c,w.Operator__c,w.Parent_Object_Field__c,w.Parent_Object_Name__c,w.Relationship_Name__c,w.RuleObjectType__c,w.Sequence__c,w.Value__c From WorkflowRuleCriteria__c w where Workflow_Rule__c	 = :wf.id]) {
     		WorkflowRuleCriteria__c newWC = wc.clone(false); 
     		newWC.Workflow_Rule__c	 = newWF.id; 
     		items.add(newWC); 
          	}
          	if (Schema.sObjectType.WorkflowRuleCriteria__c.isCreateable() ) {
          insert items;
            }  
            }
            if(doCopyAction){
           
           // copy over the line WorkflowRuleAction actionitems - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
            List<WorkflowRuleAction__c> actionitems = new List<WorkflowRuleAction__c>();
            for (WorkflowRuleAction__c wa : [Select a.Id, a.Action_Label__c, a.Action_Object__c, a.ActionType__c, a.Additional_Emails__c,a.Child_Relationship_Name__c,a.CrossObjectField__c,a.Email_Template__c,a.Email_Template_Folder__c,a.EmailTemplateName__c,a.External_Field_API_Name__c,a.ExternalId__c,a.Field_API_Name__c,a.Field_Name__c,a.Field_Type__c,a.Reference_Id__c,a.User_Owner_Id__c,a.Value__c From WorkflowRuleAction__c a where Workflow_Rule__c	 = :wf.id]) {
     		WorkflowRuleAction__c newWA = wa.clone(false); 
     		newWA.Workflow_Rule__c	 = newWA.id; 
     		actionitems.add(newWA); 
          	}
          	if (Schema.sObjectType.WorkflowRuleCriteria__c.isCreateable()) {
         	 insert actionitems;
          	}  
            } 
          	return newWF; 
		}
		catch (Exception e){
     	// roll everything back in case of error
     		//Database.rollback(sp);  
        	ApexPages.addMessages(e); 
       		return null;
         } 
     }  
         // To track all the rules applied - Audit tracking for rule evaluation
     public static AppliedRule__c TrackWorkflowRule(String objId,String ruleId)   {
     	 AppliedRule__c newAppliedRule = new AppliedRule__c();  
     	 newAppliedRule.Object_ID__c = objId;   
     	 newAppliedRule.WorkflowRule__c = ruleId; 
         newAppliedRule.User__c = UserInfo.getUserId();  
     	 return newAppliedRule;        
    }  
}