public class multi_pick_list {
    public Set<string> nscities         {Set;get;}
    public Set<string> scities          {set;get;}
    public List<selectoption> soptions  {set;get;}
    public List<selectoption> nsoptions   {set;get;}
    public List<string> selected        {set;get;}
    public List<string> removed     {set;get;}
    public String val {get;set;}
    public String gd {get;set;}
    map<string,string> objectapilabelmap = new map<string,string>();
    
    public multi_pick_list(){ 
        nsoptions = new List<SelectOption>();
        soptions = new List<SelectOption>();
        nscities = new set <string>();
        scities = new set <string>();
        List<Schema.SObjectType> gd = Schema.getGlobalDescribe().Values();
        for(Schema.SObjectType f : gd)
    {objectapilabelmap.put(f.getDescribe().getName(),f.getDescribe().getLabel());
    nscities.add(f.getDescribe().getName());
    //scities.add(f.getDescribe().getName());
    }
populateOptions();   
    }
    public void populateOptions()
  {
nsoptions = new List<SelectOption>();
soptions = new List<SelectOption>();
    for(string f : nscities)
    {
       nsoptions.add(new SelectOption(f,objectapilabelmap.get(f)));

    }
    
    for(string f : scities)
    {
       soptions.add(new SelectOption(f,objectapilabelmap.get(f)));

    }
    //return nsoptions ;
   }
   public void addElements(){
        nscities.removeAll(selected);
        scities.addAll(selected);
        populateOptions();
    }
    public void removeElements(){
        scities.removeAll(removed);
        nscities.addAll(removed);
        populateOptions();
    }



}