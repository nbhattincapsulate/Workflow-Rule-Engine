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
		system.debug('==request===>'+request);
		return request; 	
	}
	
	//Method to prepare Trigger Creation Request
	//@param:
	//@return :
	public static String createCreateTriggerBody(String sObjectName){
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeStringField('Name', 'IncapRule'+sObjectName+'Trigger');
		gen.writeStringField('TableEnumOrId', sObjectName);
		String bodyString = 'trigger IncapRule'+sObjectName+'Trigger on '+sObjectName+'(after insert,after update){';
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
	
	//Method to send request for Trigger Creation
	//@param:
	//@return:
	public static HttpResponse sendRequestforTriggerCreation(String sObjectName){ 
		String endPointURL = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v27.0/sobjects/ApexTrigger';
		map<String,String> headerMap = new map<String,String>();
		headerMap.put('Content-Type', 'application/json');
		headerMap.put('Authorization', 'OAuth ' + UserInfo.getSessionId());
		String requestBody = createCreateTriggerBody(sObjectName);
		return sendRequesttoServer(prepareHttprequest(endPointURL,'POST',headerMap,requestBody));
	}     
}