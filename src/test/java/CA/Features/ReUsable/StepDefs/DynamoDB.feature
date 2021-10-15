Feature: DynamoDB-related ReUsable/Methods functions.

Background:
  * def Pause = function(pause){ java.lang.Thread.sleep(pause) }
  * def initializeDynamoDBObject = 
    """
      function(thisAWSregion) {
        var dynamoDBUtilsClass = Java.type('com.automation.ca.backend.DynamoDBUtils');
        return new dynamoDBUtilsClass(thisAWSregion)
      }
    """
  * def dynamoDB = call initializeDynamoDBObject AWSRegion
  * configure afterScenario =
    """
      function() {
        dynamoDB.shutdown();
      }
    """

@FilterQueryResults
# Filter Results generated from @GetItemsViaQuery
# Parameters:
# {
#   Param_QueryResults: <Results from @GetItemsViaQuery>,
#   Param_FilterNestedInfoList: [
#     {
#       infoName: <attribute to filter>,
#       infoValue: <attribute value to filter>,
#       infoComparator: <[contains | = ]>
#     }        
#   ]
# }
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
                // karate.log(karate.pretty(Param_QueryResults[i]));
                karate.log(Param_QueryResults[i]);
                karate.fail('Empty key-value pair! Key: ' + infoName + ' has value: ' + Param_QueryResults[i][infoName]);
              }
              if(Param_QueryResults[i][infoName].contains(infoValue)) {
                queryResults.push(Param_QueryResults[i]);
              }
            }
          }
          Param_QueryResults = queryResults;    
          if(queryResults.length < 1)  {
            // karate.log('No results found for ' + karate.pretty(Param_FilterNestedInfoList));
            break;
          }      
        }

        return queryResults;
      }
    """
  * def result = call filterResults
  # * print result

@GetItemsViaQuery
# Get DynamoDB Item(s) via Query
# Parameters:
# {
#   Param_TableName: <Tablename>,
#   Param_QueryInfoList: [
#       {
#           infoName: <attribute to filter>,
#           infoValue: <attribute value to filter>,
#           infoComparator: <['contains' | '=']>,
#           infoType: <'key' | 'filter'>
#       }
#   ],
#   Param_GlobalSecondaryIndex: <Table GSI>,
#   AWSRegion: <AWS Region: 'Nordics' | 'APAC'>,
#   Retries: <number of retries>,
#   RetryDuration: <time between retries in milliseconds>
# }
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
        // karate.log('No results found for ' + karate.pretty(Param_QueryInfoList));
        return queryResp;
      }

      return JSON.parse(queryResp);
    }
    """
  * def result = call getItemsQuery
  # * print result

@ValidateItemViaQuery
# Get DynamoDB Item(s) via Query and Validate against Expected Result
# Parameters:
# {
#   Param_TableName: <Tablename>,
#   Param_QueryInfoList: [
#       {
#           infoName: <attribute to filter>,
#           infoValue: <attribute value to filter>,
#           infoComparator: <['contains' | '=']>,
#           infoType: <'key' | 'filter'>
#       }
#   ],
#   Param_GlobalSecondaryIndex: <Table GSI>,
#   Param_ExpectedResponse: <Expected JSON>,
#   AWSRegion: <AWS Region: 'Nordic' | 'APAC'>,
#   Retries: <number of retries>,
#   RetryDuration: <time between retries in milliseconds>,
#   WriteToFile: <true | false>,
#   ShortCircuit: {
#        Key: <The trailing keys from the root e.g. promoAssetStatus>,
#        Value: <Expected value to short circuit>
#   }
# }
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
        // karate.log('No results found for ' + karate.pretty(Param_QueryInfoList));
        karate.log('No results found for ' + Param_QueryInfoList);
        return queryResp;
      }

      // dynamoDB.shutdown();
      
      return JSON.parse(queryResp[0]);

    }
    """
  * def getMatchResult = 
    """
      function(queryResult) {
        var finalResult = {
          message: [],
          pass: false,
          path: null
        }

        if(queryResult.length < 1) {
          finalResult.message.push('No records found.');
        }
        else {
          var thisRes = karate.match('queryResult deep contains Param_ExpectedResponse');
          if(!thisRes.pass) {
            finalResult.message.push(thisRes.message);
          }
        }

        if(finalResult.message.length < 1) {
          finalResult.pass = true;
        }

        return finalResult;
      }
    """
  * def getFinalResult =
    """
      function() {
        var matchResult = {};
        for(var i = 0; i < Retries; i++) {
          queryResult = getItemsQuery();
          karate.log(queryResult);
          matchResult = getMatchResult(queryResult);

          if(WriteToFile == true) {
            karate.write(karate.pretty(queryResult), WritePath);
          }
          if(matchResult.pass) {
            matchResult.response = queryResult;
            break;
          }
          else {
            karate.log('ShortCircuit: ' + ShortCircuit);
            if(ShortCircuit != null) {
              if(eval('queryResult.' + ShortCircuit.Key) == ShortCircuit.Value) {
                matchResult.message.push('comments: ' + queryResult.comments);
                karate.log('[FAILED] Short circuit condition met! ' + karate.pretty(matchResult));
                return matchResult;
              }
            } 
          
            karate.log('Try #' + (i+1) + ' of ' + Retries + ': Failed. Sleeping for ' + RetryDuration + ' ms. - ' + karate.pretty(matchResult));
            Pause(RetryDuration);
          }
        }

        // if(!matchResult.pass) {
        //   karate.fail(karate.pretty(matchResult));
        // }
        return matchResult;
      }
    """
  * def finalResult = getFinalResult()
  * def result =
    """
      {
        "response": #(finalResult.response),
        "message": #(finalResult.message),
        "pass": #(finalResult.pass),
        "path": #(finalResult.path)
      }
    """

@DeleteDBRecords
# Delete items from DynamoDB Table
# Parameters:
# {
#     itemParamList: [
#       {
#         PrimaryPartitionKeyName: <attribute to filter>,
#         PrimaryPartitionKeyValue: <attribute value to filter>
#       }
#     ],
#     TableName: <Tablename>,
#     GSI: <Table GSI>,
#     PromoAssetStatus: <expected promoAssetStatus>,
#     PrimaryFilterKeyName: <expected filter key>,
#     PrimaryFilterKeyValue: <expected filter value>,
#     Retries: <# of retries>,
#     RetryDuration: <time between retries in milliseconds>,
#     AWSRegion: <AWS Region: 'Nordic' | 'APAC'>
# }
Scenario: Delete items from DynamoDB Table
  * def isTrailerIDDeleted =
    """
      function(PrimaryFilterKeyName, PrimaryFilterKeyValue, PromoAssetStatus, GSI) {
        for(var k in PromoAssetStatus) {
          var thisPromoAssetStatus = PromoAssetStatus[k];
          var getItemParams = {
            Param_TableName: TableName,
            Param_QueryInfoList: [
              {
                infoName: 'promoAssetStatus',
                infoValue: thisPromoAssetStatus,
                infoComparator: '=',
                infoType: 'key'           
              },
              {
                infoName: PrimaryFilterKeyName,
                infoValue: PrimaryFilterKeyValue,
                infoComparator: 'contains',
                infoType: 'filter'           
              }
            ],
            Param_GlobalSecondaryIndex: GSI
          }
          
          var thisResult = karate.call(ReUsableFeaturesPath + '/StepDefs/DynamoDB.feature@GetItemsViaQuery', getItemParams);

          if(thisResult.result.length > 0) {
            return false;
          }
          return true;
        }
      }
    """
  * def deleteItems =
    """
      function(itemParamList) {
        var result = {
          message: [],
          pass: false
        }

        var dynamoDB = initializeDynamoDBObject(AWSRegion);
         
        for(var j in itemParamList) {
          var retry = 1;
          var isDeleted = false;
          while(retry <= Retries) {
            var errMsg = '';
            var PrimaryPartitionKeyName = itemParamList[j]['PrimaryPartitionKeyName'];
            var PrimaryPartitionKeyValue = itemParamList[j]['PrimaryPartitionKeyValue'];
            karate.log('[Deleting] ' + PrimaryPartitionKeyName + ': ' + PrimaryPartitionKeyValue);
            var thisDeleteMsg = dynamoDB.Delete_Item(TableName, PrimaryPartitionKeyName, PrimaryPartitionKeyValue);
            if(thisDeleteMsg.contains('Failed')) {
              errMsg = thisDeleteMsg;
            }
            Pause(500);
            if(
              isTrailerIDDeleted(
                PrimaryPartitionKeyName,
                PrimaryPartitionKeyValue,
                PromoAssetStatus,
                GSI
              ) == true) {
              isDeleted = true;
              break;
            }
            karate.log('Try #' + (retry) + ' of ' + Retries + ': Failed. Sleeping for ' + RetryDuration + ' ms. - ' + karate.pretty(errMsg));
            Pause(RetryDuration);
            retry++;
          }
          if(isDeleted == true) {
            result.message.push('Successfully deleted AssetDB trailer Records for ' + PrimaryPartitionKeyValue);
            result.pass = true;
          } else {
            result.message.push('Failed to delete AssetDB trailer Records for ' + PrimaryPartitionKeyValue);
            result.pass = false;
          }
        }

        //dynamoDB.shutdown();
        
        return result;
      }
    """
  * def result = deleteItems(itemParamList)
