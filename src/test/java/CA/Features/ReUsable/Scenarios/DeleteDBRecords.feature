@parallel=false 
Feature: Delete AssetDB Records

Scenario: Delete AssetDB Records
    # * json XMLNodes = read('classpath:' + DownloadsPath + '/' + ExpectedDataFileName)
    # * def TrailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    * def formDeleteDBRecordsParams =
        """
            function(TrailerData) {
                var paramList = [];
                for(var i in TrailerData) {
                    var thisParam = {

                        PrimaryPartitionKeyName: 'trailerId',
                        PrimaryPartitionKeyValue: i,
                    }
                    paramList.push(thisParam);
                }
                if(WochitStage == 'preWochit') {
                    var promoAssetStatus = ['Pending Upload'];
                } else {
                    var promoAssetStatus = ['Completed', 'Processing'];
                }
                var finalParams = {
                    itemParamList: paramList,
                    TableName: OAPAssetDBTableName,
                    GSI: 'promoAssetStatus-modifiedAt-Index',
                    PromoAssetStatus: promoAssetStatus,
                    PrimaryFilterKeyName: 'promoXMLName',
                    PrimaryFilterKeyValue: ExpectedDataFileName,
                    Retries: 5,
                    RetryDuration: 5000,
                    AWSRegion: AWSRegion
                };

                return finalParams;
            }
        """
    Given def DeleteDBRecordsParams = formDeleteDBRecordsParams(TrailerData)
    When def deleteDBRecordStatus = call read(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@DeleteDBRecords') DeleteDBRecordsParams
    * print deleteDBRecordStatus.result
    # Then deleteDBRecordStatus.result.pass == true?karate.log('[PASSED]: Successfully deleted in DB: ' + karate.pretty(TrailerIDs)):karate.fail('[FAILED]: ' + karate.pretty(deleteDBRecordStatus.result.message))
    Then deleteDBRecordStatus.result.pass == true?karate.log('[PASSED]: Successfully deleted in DB: ' + TrailerIDs):karate.fail('[FAILED]: ' + deleteDBRecordStatus.result.message)
