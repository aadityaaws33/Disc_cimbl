Feature: DynamoDB-related ReUsable/Methods functions

Background:
  * def Pause = function(pause){ java.lang.Thread.sleep(pause) }
  * def initializeDynamoDBObject = 
    """
      function(thisAWSregion) {
        var dynamoDBUtilsClass = Java.type('CA.utils.java.DynamoDBUtils');
        return new dynamoDBUtilsClass(thisAWSregion)
      }
    """
  * def dynamoDB = call initializeDynamoDBObject AWSregion
  * configure afterFeature =
    """
      function() {
        dynamoDB.shutdown();
      }
    """

@FilterQueryResults
Scenario: Filter Results generated from Querying DynamoDB
  * def filterResults =
    """
      function()
      {
        for(var index in Param_FilterNestedInfoList) {
          var queryResults = [];
          var infoName = Param_FilterNestedInfoList[index].infoName;
          var infoValue = Param_FilterNestedInfoList[index].infoValue;
          var infoComparator = Param_FilterNestedInfoList[index].infoComparator;

          if(infoName.contains('.')) {
            var infoFilter = infoName.split('.').pop();
            infoName = infoName.replace('.' + infoFilter, '');
            var thisPath = "$." + infoName + "[?(@." + infoFilter + " contains '" + infoValue + "')]";
            karate.log(thisPath);
            for(i in Param_QueryResults) {
              var filteredValue = karate.jsonPath(Param_QueryResults[i], thisPath);
              if(filteredValue.length > 0) {
                queryResults.push(Param_QueryResults[i]);
              }
            }
          } else {
            for(i in Param_QueryResults) {
              karate.log(Param_QueryResults[i][infoName]);
              if(!Param_QueryResults[i][infoName]) {
                karate.log(karate.pretty(Param_QueryResults[i]));
                karate.fail('Empty key-value pair! Key: ' + infoName + ' has value: ' + Param_QueryResults[i][infoName]);
              }
              if(Param_QueryResults[i][infoName].contains(infoValue)) {
                queryResults.push(Param_QueryResults[i]);
              }
            }
          }
          Param_QueryResults = queryResults;    
          if(queryResults.length < 1)  {
            karate.log('No results found for ' + karate.pretty(Param_FilterNestedInfoList));
            break;
          }      
        }

        return queryResults;
      }
    """
  * def result = call filterResults
  # * print result

@GetItemsViaQuery
Scenario: Get DynamoDB Item(s) via Query
  * def getItemsQuery =
    """
    function()
    {
      var HashMap = Java.type('java.util.HashMap');
      var Param_QueryInfoListJava = [];
      for(var index in Param_QueryInfoList){
        // Convert J04 Object into Java HashMap
        var Param_QueryInfoItemHashMapJava = new HashMap();
        Param_QueryInfoItemHashMapJava.putAll(Param_QueryInfoList[index]);
        // Append converted Java HashMap to Java List
        Param_QueryInfoListJava.push(
          Param_QueryInfoItemHashMapJava
        );
      }

      var queryResp = dynamoDB.Query_GetItems(
        Param_TableName,
        Param_QueryInfoListJava,
        Param_GlobalSecondaryIndex
      );

      if(queryResp.length < 1)  {
        karate.log('No results found for ' + karate.pretty(Param_QueryInfoList));
        return queryResp;
      }
      return JSON.parse(queryResp);

    }
    """
  * def result = call getItemsQuery
  # * print result

@ValidateItemViaQuery
Scenario: Validate DynamoDB Item via Query
  #* print '-------------------Dynamo DB Feature and Item Count-------------'
  * def getItemsQuery =
    """
    function()
    {
      var HashMap = Java.type('java.util.HashMap');
      var Param_QueryInfoListJava = [];
      for(var index in Param_QueryInfoList){
        // Convert J04 Object into Java HashMap
        var Param_QueryInfoItemHashMapJava = new HashMap();
        Param_QueryInfoItemHashMapJava.putAll(Param_QueryInfoList[index]);
        // Append converted Java HashMap to Java List
        Param_QueryInfoListJava.push(
          Param_QueryInfoItemHashMapJava
        );
      }

      var queryResp = dynamoDB.Query_GetItems(
        Param_TableName,
        Param_QueryInfoListJava,
        Param_GlobalSecondaryIndex
      );

      if(queryResp.length < 1)  {
        karate.log('No results found for ' + karate.pretty(Param_QueryInfoList));
        return queryResp;
      }

      return JSON.parse(queryResp[0]);

    }
    """
  * def queryResult = call getItemsQuery
  # * print queryResult
  * def getMatchResult = 
    """
      function() {
        if (queryResult.length < 1) {
          var matchRes = {
            message: 'No records found. ' + queryResult,
            pass: false,
            path: null
          }
        }
        else {
          var matchRes = karate.match('queryResult contains Param_ExpectedResponse');
          if(!matchRes['pass']) {
            karate.log('Initial matching failed');
            for(var key in queryResult) {
              var thisRes = '';
              var path = '$.' + key;
              expectedValue = Param_ExpectedResponse[key];
              actualValue = queryResult[key];
              if(key == 'assetMetadata' || key == 'seasonMetadata' || key == 'seriesMetadata') {
                for(var metadataKey in actualValue) {
                  path = '$.' + key + '.' + metadataKey;
                  expectedMetadataValue = expectedValue[metadataKey];
                  actualMetadataValue = actualValue[metadataKey];
                  if(typeof(actualMetadataValue) == 'object') {
                    karate.log(metadataKey + ' TYPE: ' + typeof(actualMetadataValue));
                    karate.log(actualMetadataValue);
                    if(actualMetadataValue.length > 0) {
                      for(var dataKey in actualMetadataValue) {
                        path = '$.' + key + '.' + metadataKey + '.' + dataKey;
                        expectedDataField = expectedMetadataValue[dataKey];
                        actualDataField = actualMetadataValue[dataKey];
                        thisRes = karate.match('actualDataField contains expectedDataField');
                        karate.log(key,'[',metadataKey,']','[',dataKey,']', thisRes);
                        if(!thisRes['pass']) {
                          break;
                        }
                      }
                    } else {
                      thisRes = {
                        message: 'Skipping empty object',
                        pass: true
                      }
                    }
                  } else {
                    thisRes = karate.match('actualMetadataValue contains expectedMetadataValue');
                    karate.log(key,'[',metadataKey,']', thisRes);
                  }
                  if(!thisRes['pass']) {
                    break;
                  }
                }
              } else {
                thisRes = karate.match('actualValue contains expectedValue');
                karate.log(key, thisRes);
              }
              matchRes = thisRes;
              if(!matchRes['pass']) {
                matchRes['path'] = path;
                break;
              }
            }
          }
        }
        return matchRes;
      }
    """
  * def matchResult = call getMatchResult
  * def result =
    """
      {
        "response": #(queryResult),
        "message": #(matchResult.message),
        "pass": #(matchResult.pass),
        "path": #(matchResult.path)
      }
    """
  # * print result
