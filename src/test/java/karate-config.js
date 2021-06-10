function() {  

    // Global configurations
    karate.configure('connectTimeout', 10000);
    karate.configure('retry',{ count:4, interval:2000});
  
    
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