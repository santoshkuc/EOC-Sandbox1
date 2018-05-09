trigger ProjectTrigger on Project__c (before insert, after insert, before update, after update) {

    new ProjectTriggerHandler().run();
    
}