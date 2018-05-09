public class ProjectTriggerHandler extends TriggerHandler {
    
    private Map<Id, Project__c> newProjectMap;
    private Map<Id, Project__c> oldProjectMap;
    private List<Project__c> newProjects;
    private Log logger;
    
    static Map<String, Id> recordTypeIdByName;
    
    static {
        recordTypeIdByName = new Map<String, Id>();
        List<RecordType> rtl = [SELECT ID, Name FROM RecordType WHERE SObjectType='Install__c'];
        for(RecordType rt : rtl){
            recordTypeIdByName.put(rt.Name, rt.Id);
        }
    }
    
    public ProjectTriggerHandler() {
        this.logger = new Log(ProjectTriggerHandler.class.getName());
        this.newProjectMap = (Map<Id, Project__c>) Trigger.newMap;
        this.oldProjectMap = (Map<Id, Project__c>) Trigger.oldMap;
        this.newProjects = (List<Project__c>) Trigger.new;
    }
    
    public override void afterInsert() {   
        logger.setEvent('afterInsert');  
        String errorMessage = '';
        
        for(Project__c project: newProjects){
            
            /**
*   Trigger Installation Logic if no installations are already associated with the project 
* 
*/ 
            //if(!approvalHasChanged(project))
            //    continue;
            
            //Boolean approved = project.Approved__c;
            Boolean approved = true;
            Decimal installCount = project.Number_of_Potential_Installations__c;
            
            logger.debug('Approved', approved);
            logger.debug('Installation Count', installCount);
            
            
            if(approved){
                /**
*  If existing installations detected, Error Out.
*/  
                if(installCount>0){
                    
                    errorMessage = 'Found ' + installCount + ' Installations(s). Please remove them before approving the project';
                    logger.debug('Log Error', errorMessage);
                    addError(project, errorMessage);
                    continue;
                    
                } 
                
                String electricUPId = project.Electric_Provider__c;
                String gasUPId = project.Gas_Provider__c;
                
                String spaceHeatSource = project.Space_Heat_Source__c;
                String waterHeatSource = project.Water_Heat_Source__c;
                
                Map<String, String> sourceByHeatType = new Map<String, String>();
                sourceByHeatType.put('Space', spaceHeatSource);
                sourceByHeatType.put('DHW', waterHeatSource);
                
                List<Utility_Rebate__c> utilityRebates = new List<Utility_Rebate__c>();
                
  
                utilityRebates = [SELECT Id, Utility_Provider_del__r.Name, Rebate_Amount__c, Product_Installation__c, 
                                                               Heat_Type__c, Required_Heat_Source__c , Product_Installation__r.RecordType.Name,
                                                               Product_Installation__r.Name, Rebate_Amount_per_Square_Foot__c, Deemed_Savings__c,
                                                               Rebate_as_a_Percent__c, Up_to_Amount__c 
                                                               FROM Utility_Rebate__c 
                                                               WHERE (Utility_Provider_del__c = :electricUPId
                                                                 OR Utility_Provider_del__c = :gasUPId)
                                                               ORDER BY Product_Installation__r.Name asc];                     
                    
              
                
                
                logger.debug('Matching Utility Rebates', utilityRebates.size());    
                
                /*
*   Logic for creating Installs. 
*   Get a unique set of product installs from the utility rebates
*   for each product install, create an install and associate
*   that to the project.
*/ 
                Set<Id> uniqueProductInstalls = new Set<Id>();
                
                for(Utility_Rebate__c utilityRebate: utilityRebates){
                    
                    uniqueProductInstalls.add(utilityRebate.Product_Installation__c);
                    
                }
                
                logger.debug('Matching Product Installs', uniqueProductInstalls.size());  
                
                List<Product_Installation__c> productInstalls = [SELECT Id, RecordTypeId, RecordType.Name, Auditor_or_Contractor__c, Name, Priority__c 
                                                                 FROM Product_Installation__c
                                                                 WHERE Id IN :uniqueProductInstalls];
                
                List<Install__c> installs = new List<Install__c>();
                
                Map<Id, Install__c> installByProductInstall = new Map<Id, Install__c>();
                
                for(Product_Installation__c productInstall: productInstalls){
                    
                    Install__c install = new Install__c();
                    
                    Id recordTypeId = recordTypeIdByName.get(productInstall.RecordType.Name);
                    
                    if(recordTypeId==null) continue;
                    
                    installByProductInstall.put(productInstall.Id, install);
                    
                    install.Name = productInstall.Name + ', ' +  project.Applicant_First_Name__c + ' ' + project.Applicant_Last_Name__c;
                    
                    install.Project__c = project.Id;
                    
                    install.RecordTypeId = recordTypeId;
                    
                    install.Install_Type__c = productInstall.Name;
                    
                    install.Auditor_or_Contractor__c = productInstall.Auditor_or_Contractor__c;
                    
                    install.Priority__c = productInstall.Priority__c;
                    
                    installs.add(install);
                }
                
                logger.debug('Install Count', installs.size());
                
                Savepoint undoinstalls = Database.setSavepoint();
                
                insert installs;
                
                logger.debug('Install By Product Install', installByProductInstall);
                
                logger.debug('Installation Successful. Now processing Rebates');
                
                List<Rebate__c> rebates = new List<Rebate__c>();
                
                logger.debug('Matching Utility Rebates', utilityRebates.size());  
                
                for(Utility_Rebate__c utilityRebate: utilityRebates){
                    
                    System.debug('Adding Utility Rebates::::');
                    
                    
                    try {
                        
                        logger.debug('Utility Rebate Attributes', utilityRebate);
                        Rebate__c rebate = new Rebate__c();
                        rebate.Utility_Provider__c = utilityRebate.Utility_Provider_del__c;
                        if(utilityRebate.Heat_Type__c!='Either'){
                            rebate.Heat_Type__c = utilityRebate.Heat_Type__c;
                            String heatSource = sourceByHeatType.get(utilityRebate.Heat_Type__c);
                            System.debug('Required Heat Source='+ heatSource +' For Heat Type=' + utilityRebate.Heat_Type__c);
                            System.debug('Eligible Heat Source='+ utilityRebate.Required_Heat_Source__c +' For Heat Type=' + utilityRebate.Heat_Type__c);
                            if(heatSource!=utilityRebate.Required_Heat_Source__c){
                                System.debug('Skipping the rebate');
                                continue;
                            }else{
                                System.debug('Including this rebate:'+ utilityRebate.Rebate_Amount__c);
                            }
                        }
                            
                        
                        rebate.Required_heat_Source__c = utilityRebate.Required_Heat_Source__c;
                        rebate.Up_to_Amount__c = utilityRebate.Up_to_Amount__c;
                        rebate.Deemed_Savings__c = utilityRebate.Deemed_Savings__c;
                        rebate.Rebate_as_a_Percent__c = utilityRebate.Rebate_as_a_Percent__c;
                        
                        rebate.Rebate_Amount__c = utilityRebate.Rebate_Amount__c;
                        rebate.Rebate_Amount_per_Square_Foot__c = utilityRebate.Rebate_Amount_per_Square_Foot__c;
                        rebate.Install__c = getRebateId(utilityRebate, installByProductInstall);
                        rebate.Eligible_Rebate__c = true;
                        rebates.add(rebate);                        
                    } catch(Exception e) {
                        logger.debug('Error While Creating Rebates', e.getMessage());
                    }
                    
                    
                }                
                
                logger.debug('Rebate Count', rebates.size());
                
                try 
                {
                    
                    insert rebates;
                    
                }
                catch(Exception e)
                {   
                    errorMessage = ' While creating rebates, encountered this issue =>' + e.getMessage().substring(e.getMessage().indexOf(':')) + '<br/>Contact your admin.<br/>';
                    Database.rollback(undoinstalls);
                    logger.debug('Installs Rolled back successfully');
                    logger.debug('Log Error', errorMessage);
                    addError(project, errorMessage);
                    continue;                    
                    
                }
                
            }
        }
    } 
    
    public override void beforeUpdate() {
        logger.setEvent('before Update');
    }
    
    
    private void addError(SObject p, String error){
        newProjectMap.get(p.Id).addError(error, false);
    }
    
    private Boolean approvalHasChanged(Project__c p){
        return(oldProjectMap.get(p.Id).Approved__c!=p.Approved__c);
    }
    
    private Id getRebateId(Utility_Rebate__c ur, Map<Id, Install__c> installByProductInstall){
        Install__c ins =  installByProductInstall.get(ur.Product_Installation__c);
        if(ins==null){
            logger.debug('Install missing', ur.Product_Installation__c);
        }
        return ins.Id;
    }
    
}