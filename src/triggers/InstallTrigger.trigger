trigger InstallTrigger on Install__c (before update, after update) {
    
    if(Trigger.isBefore && Trigger.isUpdate){
        for(Install__c install: Trigger.new){
            if(install.Square_Footage__c!=null && install.Square_Footage__c>0){
                if(install.Install_Type__c=='Attic Insulation'){
                    install.Attic_Square_Footage__c = install.Square_Footage__c;
                }
                if(install.Install_Type__c=='Wall Insulation'){
                    install.Square_footage_of_Wall_Insulation__c = install.Square_Footage__c;
                }
            }
        }
    }
    
    if(Trigger.isAfter && Trigger.isUpdate) {
        UPDATE[SELECT ID FROM Rebate__c WHERE Install__c = :Trigger.new];
    }
   

}