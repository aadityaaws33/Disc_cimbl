@parallel=false
Feature: Single File Upload

# Scenario: Validate OAP

Scenario: MAIN PHASE Validate OAP
    * def scenarioName = WochitStage + ' MAIN PHASE 1 Upload File To S3'
    * def UploadFileParams =
        """
            {
                S3BucketName: #(OAPHotfolderS3.Name),
                S3Key: #(OAPHotfolderS3.Key + '/' + ExpectedDataFileName) ,
                AWSRegion: #(OAPHotfolderS3.Region),
                FilePath: #(DownloadsPath + '/' + ExpectedDataFileName)
            }
        """
    * def uploadFileStatus = call read(ReUsableFeaturesPath + '/Methods/S3.feature@UploadFile') UploadFileParams
    * print uploadFileStatus.result
    # * uploadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(uploadFileStatus.result.message))
    * uploadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + uploadFileStatus.result.message)
    # --------------------------------------------------------------------------------
    *  def scenarioName = WochitStage + ' MAIN PHASE 1 Validate OAP DataSource Table Record'
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
                Retries: 120,
                RetryDuration: 10000,
                WriteToFile: False
            }
        """
    When def validateOAPDataSourceTable =  call read(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@ValidateItemViaQuery') ValidationParams
    * print validateOAPDataSourceTable.result
    # Then validateOAPDataSourceTable.result.pass == true? karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(validateOAPDataSourceTable.result.message))
    Then validateOAPDataSourceTable.result.pass == true? karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + validateOAPDataSourceTable.result.message)
    # --------------------------------------------------------------------------------    
    *  def scenarioName = WochitStage + ' MAIN PHASE 2 Validate OAP AssetDB Table Records'
    * def validateAssetDBTrailerRecords =
        """
            function(TrailerIDs, stage) {
                var result = {
                    message: [],
                    pass: true
                };

                for(var i in TrailerIDs) {
                    var trailerId = TrailerIDs[i];
                    karate.log(TestDataPath + '/OAPAssetDB/' + stage + '/' + TargetEnv + '/' + trailerId.replace(RandomString.result, '') + '.json');
                    var ExpectedOAPAssetDBRecord = karate.read(TestDataPath + '/OAPAssetDB/' + stage + '/' + TargetEnv + '/' + trailerId.replace(RandomString.result, '') + '.json');

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
                        Retries: 120,
                        RetryDuration: 10000,
                        WriteToFile: true,
                        WritePath: 'test-classes/' + ResultsPath + '/' + trailerId + '.json'
                    }
                    var ValidationResult = karate.call(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@ValidateItemViaQuery', ValidationParams);
                    // karate.write(karate.pretty(ValidationResult.result.response), 'test-classes/' + ResultsPath + '/' + trailerId + '.json');
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
    Given def TrailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    When def validateOAPAssetDBTable = validateAssetDBTrailerRecords(TrailerIDs, WochitStage)
    * print validateOAPAssetDBTable
    # Then validateOAPAssetDBTable.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + karate.pretty(TrailerIDs)):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateOAPAssetDBTable.message))
    Then validateOAPAssetDBTable.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + validateOAPAssetDBTable.message)
    # --------------------------------------------------------------------------------    
    *  def scenarioName = WochitStage + ' MAIN PHASE 2 Check Iconik Collection Heirarchy'
    Given def TrailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    And def ValidateCollectionHeirarchyParams =
        """
            {
                Retries: 120,
                RetryDuration: 10000,
                TrailerIDs: #(TrailerIDs)
            }
        """
    When def validateCollectionHeirarchy = call read(ReUsableFeaturesPath + '/Methods/Iconik.feature@ValidateCollectionHeirarchy') ValidateCollectionHeirarchyParams
    * print validateCollectionHeirarchy.result
    # Then validateCollectionHeirarchy.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + karate.pretty(TrailerIDs)):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateCollectionHeirarchy.result.message))
    Then validateCollectionHeirarchy.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + validateCollectionHeirarchy.result.message)

    #--------------------------------------------------------------------------------
    *  def scenarioName = WochitStage + ' MAIN PHASE 2 Check Iconik Placeholder Existence'
    Given def TrailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    And def ExpectedType = WochitStage == 'beforeProcessing'?'PLACEHOLDER':'ASSET'
    And def ValidatePlaceholderParams =
        """
            {
                Retries: 120,
                RetryDuration: 10000,
                TrailerIDs: #(TrailerIDs),
                ExpectedType: #(ExpectedType),
                WochitStage: #(WochitStage)
            }
        """
    When def validateIconikPlaceholder = call read(ReUsableFeaturesPath + '/Methods/Iconik.feature@ValidatePlaceholders') ValidatePlaceholderParams
    * print validateIconikPlaceholder.result
    # Then validateIconikPlaceholder.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + karate.pretty(TrailerIDs)):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateIconikPlaceholder.result.message))
    Then validateIconikPlaceholder.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + validateIconikPlaceholder.result.message)
    # --------------------------------------------------------------------------------