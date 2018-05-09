@istest
public class ProjectTriggerTest 
{
	public static testmethod void projectTriggerTestmethod()
    {
        try
        {
            Product_Installation__c productInsta=new Product_Installation__c();
            productInsta.Name='Air Sealing';
            productInsta.Auditor_or_Contractor__c='Auditor Install';
            insert productInsta;
            
            Utility_Provider__c utilProvElec=new Utility_Provider__c();
            utilProvElec.Name='test util elec provider';
            utilProvElec.Utility_Type__c='Electric';
            insert utilProvElec;
            
            Utility_Provider__c utilProvGas=new Utility_Provider__c();
            utilProvGas.Name='test util gas provider';
            utilProvGas.Utility_Type__c='Gas';
            insert utilProvGas;
            
            Utility_Rebate__c utilReb=new Utility_Rebate__c();
            utilReb.Product_Installation__c=productInsta.Id;
            utilReb.Utility_Provider_del__c=utilProvGas.id;
            insert utilReb;
            
            Project__c projObj= new Project__c();
            projObj.Electric_Utility_Provider__c=utilProvElec.Id;
            projObj.Gas_Provider__c=utilProvGas.Id;
            
            insert projObj;
            
            projObj.Approved__c=True;
            update projObj;
            
        }
        catch(exception ex)
        {
            system.debug('ex msg ' + ex.getMessage());
            system.debug('ex line ' + ex.getLineNumber());
        }
    }
    
	public static testmethod void projectWithInstallTriggerTestmethod()
    {
        try
        {
            Product_Installation__c productInsta=new Product_Installation__c();
            productInsta.Name='Air Sealing';
            productInsta.Auditor_or_Contractor__c='Auditor Install';
            insert productInsta;
            
  
            
            Utility_Provider__c utilProvElec=new Utility_Provider__c();
            utilProvElec.Name='test util elec provider';
            utilProvElec.Utility_Type__c='Electric';
            insert utilProvElec;
            
            Utility_Provider__c utilProvGas=new Utility_Provider__c();
            utilProvGas.Name='test util gas provider';
            utilProvGas.Utility_Type__c='Gas';
            insert utilProvGas;
            
            Utility_Rebate__c utilReb=new Utility_Rebate__c();
            utilReb.Product_Installation__c=productInsta.Id;
            utilReb.Utility_Provider_del__c=utilProvGas.id;
            insert utilReb;
            
            Project__c projObj= new Project__c();
            projObj.Electric_Utility_Provider__c=utilProvElec.Id;
            projObj.Gas_Provider__c=utilProvGas.Id;
            projObj.Applicant_First_Name__c ='FN';
            projObj.Applicant_Last_Name__c = 'LN';
            
            insert projObj;
            
            Install__c install=new Install__c();
            install.Project__c = projObj.Id;
            install.Auditor_or_Contractor__c='Auditor Install';
            
            insert install;
            
            Install__c inst = [SELECT Name FROM Install__c WHERE Project__c = :projObj.Id LIMIT 1];
            System.assert(inst.Name<>'');
            
            projObj.Approved__c=True;
            update projObj;
            
        }
        catch(exception ex)
        {
            system.debug('ex msg ' + ex.getMessage());
            system.debug('ex line ' + ex.getLineNumber());
        }
    }    
}