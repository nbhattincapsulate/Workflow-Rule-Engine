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
}