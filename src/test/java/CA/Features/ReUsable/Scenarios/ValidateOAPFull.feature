@parallel=false
Feature: Single File Upload

Scenario: Validate OAP
    * def scenarioName = 'SETUP: Download From S3'
    Given def DownloadS3ObjectParams =
        """
            {
                S3BucketName: #(TestAssetsS3.Name),
                S3Key: #(TestAssetsS3.Key + '/' + DATAFILENAME),
                AWSRegion: #(TestAssetsS3.Region),
                DownloadPath: #(DownloadsPath),
                DownloadFilename: #(ExpectedDataFileName),
            }
        """
    When def downloadFileStatus = call read(ReUsableFeaturesPath + '/Methods/S3.feature@DownloadS3Object') DownloadS3ObjectParams
    * print downloadFileStatus.result
    Then downloadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(downloadFileStatus.result.message))
    # ------- Modify XML for Unique Trailer IDs: epochTime + originalTrailerID -------
    * xml XMLNodes = karate.call(ReUsableFeaturesPath + '/Methods/XML.feature@modifyXMLTrailerIDs', {TestXMLPath: TestXMLPath}).result
    * karate.write(karate.prettyXml(XMLNodes), TestXMLPath.replace('classpath:target/', ''))
    * def trailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    # --------------------------------------------------------------------------------
    * def scenarioName = 'SETUP: Upload File To S3'
    Given def UploadFileParams =
        """
            {
                S3BucketName: #(OAPHotfolderS3.Name),
                S3Key: #(OAPHotfolderS3.Key + '/' + ExpectedDataFileName) ,
                AWSRegion: #(OAPHotfolderS3.Region),
                FilePath: #(DownloadsPath + '/' + ExpectedDataFileName)
            }
        """
    When def uploadFileStatus = call read(ReUsableFeaturesPath + '/Methods/S3.feature@UploadFile') UploadFileParams
    * print uploadFileStatus.result
    Then uploadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(uploadFileStatus.result.message))
    # --------------------------------------------------------------------------------
    * def scenarioName = 'MAIN PHASE 1 Validate OAP DataSource Table Record'
    * def ExpectedOAPDataSourceRecord = read(TestDataPath + '/OAPDataSource/' + TargetEnv + '/' + EXPECTEDRESPONSEFILE)
    Given def ValidationParams =
        """
            {
                Param_TableName: #(OAPDataSourceTableName),
                Param_QueryInfoList: [
                    {
                        infoName: 'dataFileName',
                        infoValue: '#(ExpectedDataFileName)',
                        infoComparator: '=',
                        infoType: 'key'
                    },
                    {
                        infoName: 'createdAt',
                        infoValue: #(ExpectedDate.result),
                        infoComparator: 'begins',
                        infoType: 'key'
                    }
                ],
                Param_GlobalSecondaryIndex: #(OAPDataSourceTableGSI),
                Param_ExpectedResponse: #(ExpectedOAPDataSourceRecord),
                AWSRegion: #(AWSRegion),
                Retries: 30,
                RetryDuration: 10000
            }
        """
    When def validateOAPDataSourceTable =  call read(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@ValidateItemViaQuery') ValidationParams
    * print validateOAPDataSourceTable.result
    Then validateOAPDataSourceTable.result.pass == true? karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(validateOAPDataSourceTable.result.message))
    # --------------------------------------------------------------------------------    
    * def scenarioName = 'MAIN PHASE 2 Validate OAP AssetDB Table Records'
    * def validateAssetDBTrailerRecords =
        """
            function(trailerIDs) {
                var result = {
                    message: [],
                    pass: true
                };

                for(var i in trailerIDs) {
                    var trailerId = trailerIDs[i];
                    var ExpectedOAPAssetDBRecord = karate.read(TestDataPath + '/OAPAssetDB/' + TargetEnv + '/' + trailerId.replace(RandomString.result, '') + '.json');
                    var ValidationParams = {
                        Param_TableName: OAPAssetDBTableName,
                        Param_QueryInfoList: [
                            {
                                infoName: 'trailerId',
                                infoValue: trailerId,
                                infoComparator: '=',
                                infoType: 'key'
                            }
                        ],
                        Param_GlobalSecondaryIndex: OAPAssetDBTableGSI,
                        Param_ExpectedResponse: ExpectedOAPAssetDBRecord,
                        AWSRegion: AWSRegion,
                        Retries: 30,
                        RetryDuration: 10000
                    }
                    var ValidationResult = karate.call(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@ValidateItemViaQuery', ValidationParams);
                    karate.write(karate.pretty(ValidationResult.result.response), 'test-classes/' + ResultsPath + '/' + trailerId + '.json');
                    if(!ValidationResult.result.pass) {
                        result.pass = false;
                        var errMsg = '';
                        if(ValidationResult.result.message.contains('Error')) {
                            errMsg = ValidationResult.result.message
                        } else {
                            if(ValidationResult.result.path) {
                                errMsg = ValidationResult.result.message.replace(ValidationResult.result.path);
                            } else {
                                errMsg = ValidationResult.result.message;
                            }
                        }
                        result.message.push(ExpectedDataFileName + '['+ trailerId + ']: ' + errMsg);
                        break;
                    }
                }        
                return result;
            }
        """
    Given def trailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    When def validateOAPAssetDBTable = validateAssetDBTrailerRecords(trailerIDs)
    * print validateOAPAssetDBTable
    Then validateOAPAssetDBTable.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + karate.pretty(trailerIDs)):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateOAPAssetDBTable.message))
    # --------------------------------------------------------------------------------    
    * def scenarioName = "MAIN PHASE 2 Check Iconik Collection Heirarchy"
    Given def trailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    And def ValidateCollectionHeirarchyParams =
        """
            {
                Retries: 30,
                RetryDuration: 10000,
                trailerIDs: #(trailerIDs)
            }
        """
    When def validateCollectionHeirarchy = call read(ReUsableFeaturesPath + '/Methods/Iconik.feature@ValidateCollectionHeirarchy') ValidateCollectionHeirarchyParams
    * print validateCollectionHeirarchy.result
    Then validateCollectionHeirarchy.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + karate.pretty(trailerIDs)):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateCollectionHeirarchy.result.message))
    # --------------------------------------------------------------------------------
    * def scenarioName = "MAIN PHASE 2 Check Iconik Placeholder Existence"
    Given def trailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    And def ValidatePlaceholderParams =
        """
            {
                Retries: 30,
                RetryDuration: 10000,
                trailerIDs: #(trailerIDs)
            }
        """
    When def validateIconikPlaceholder = call read(ReUsableFeaturesPath + '/Methods/Iconik.feature@ValidatePlaceholders') ValidatePlaceholderParams
    * print validateIconikPlaceholder.result
    Then validateIconikPlaceholder.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + karate.pretty(trailerIDs)):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateIconikPlaceholder.result.message))
    

# # Scenario:
# #     * fetch DB record for trailerID
# #     * modifiedAt - createdAt => duration
# #     * write duration => jsonfile
# #     * for each file
# #         for each trailerID
# #         <filename>.json
# #             {
# #                 trailerID: <time>
# #                     ...
# #             }