function() {  

    // Global configurations
    karate.configure('connectTimeout', 10000);
    karate.configure('retry',{ count:4, interval:2000});
  
    // // Custom Report
    // try {
    //   karate.read('classpath:target/test-classes/Results.json')
    // } catch (err) {
    //   karate.write([],'test-classes/Results.json');
    // }
    
    // Environment configurations
    var targetEnv = karate.properties['karate.targetEnv'];
  
    var targetTag = karate.properties['karate.options'].split('@')[1];
    if(targetTag != 'E2E' && targetTag != 'Regression') {
      if(targetTag.contains('E2E')) {
        targetTag = 'E2E'
      } else {
        targetTag = 'Regression';
      }
    }
  
    var configDir = 'classpath:CA/Config/' + targetEnv;
    var CommonData = read(configDir + '/' + 'Common.json');
  
    var envConfig = {
      Common: CommonData
    };
   
    // Secret Data configurations
    // var secretsData = null;
    // try {
    //   var AWSUtilsClass = Java.type('AWSUtils.AWSUtils');
    //   var AWSUtils = new AWSUtilsClass();
    //   secretsData = AWSUtils.getSecrets(envConfig.Common.SecretsManager.secretName, envConfig.Common.SecretsManager.region);
    // } catch (err) {
    //   karate.fail('Problem encountered while fetching data from Secrets Manager.\nReason: ' + err);
    // }
  
    // Consolidation of configurations
    var config = {
      TargetEnv: targetEnv,
      TargetTag: targetTag,
      EnvConfig: envConfig,
    };
    
    // Testing purposes only, avoid logging as it contains SECRET DATA
    // karate.log(config);
    return config;
  }