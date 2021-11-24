@parallel=false
Feature: Single File Upload

Background:
    * def thisFile = ReUsableFeaturesPath + '/Steps/ValidateOAPFull.feature'
    * def shouldValidateWochitRenditionTable =
        """
            function(stage) {
                var runInStage = ['postWochit', 'rerender'];
                var shouldRun = false;
                for(var i in runInStage) {
                    if(stage == runInStage[i]) {
                        shouldRun = true;
                        break;
                    }
                }
                return shouldRun;
            }
        """


@Main
Scenario: MAIN PHASE Validate OAP
    * call read(thisFile + '@UploadXMLFileToS3')
    * call read(thisFile + '@ValidateOAPDataSourceDBRecords')
    * call read(thisFile + '@ValidateOAPAssetDBRecords')
    * shouldValidateWochitRenditionTable(WochitStage)?karate.call(thisFile + '@ValidateWochitRenditionDBRecords'):karate.log(WochitStage + ' SKIPPING ValidateWochitRenditionDBRecords')
    * call read(thisFile + '@ValidateIconikCollectionHeirarchy')
    * call read(thisFile + '@ValidateIconikPlaceholdersAndAssets')


@UploadXMLFileToS3
Scenario: MAIN PHASE 1 Upload File To S3
    * def scenarioName = WochitStage + ' MAIN PHASE 1 Upload File To S3'
    Given def UploadFileParams =
        """
            {
                S3BucketName: #(OAPHotfolderS3.Name),
                S3Key: #(OAPHotfolderS3.Key + '/' + ExpectedDataFileName) ,
                AWSRegion: #(OAPHotfolderS3.Region),
                FilePath: #(DownloadsPath + '/' + ExpectedDataFileName)
            }
        """
    When def uploadFileStatus = call read(ReUsableFeaturesPath + '/StepDefs/S3.feature@UploadFile') UploadFileParams
    * print uploadFileStatus.result
    # Then uploadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + uploadFileStatus.result.message)
    Then uploadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(uploadFileStatus.result.message))

@ValidateOAPDataSourceDBRecords
Scenario: MAIN PHASE 1 Validate OAP DataSource Table Record
    *  def scenarioName = WochitStage + ' MAIN PHASE 1 Validate OAP DataSource Table Record'
    * def ExpectedOAPDataSourceRecord = read(ResourcesPath + '/OAPDataSource/' + TargetEnv + '/' + EXPECTEDRESPONSEFILE)
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
                WriteToFile: false,
                ShortCircuit: {
                    Key: 'dataSourceStatus',
                    Value: 'Failed'
                }
            }
        """
    When def validateOAPDataSourceTable =  call read(ReUsableFeaturesPath + '/StepDefs/DynamoDB.feature@ValidateItemViaQuery') ValidationParams
    * print validateOAPDataSourceTable.result
    # Then validateOAPDataSourceTable.result.pass == true? karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + validateOAPDataSourceTable.result.message)
    Then validateOAPDataSourceTable.result.pass == true? karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(validateOAPDataSourceTable.result.message))
    
@ValidateOAPAssetDBRecords
Scenario: MAIN PHASE 2 Validate OAP AssetDB Table Records
    * def scenarioName = WochitStage + ' MAIN PHASE 2 Validate OAP AssetDB Table Records'
    Given def TrailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    And def ValidateAssetDBRecordsParams =
        """
            {
                TrailerIDs: #(TrailerIDs),
                Stage: #(WochitStage)
            }
        """
    When def validateOAPAssetDBTable = call read(ReUsableFeaturesPath + '/Steps/ValidateAssetDBRecords.feature') ValidateAssetDBRecordsParams
    * print validateOAPAssetDBTable.result
    # Then validateOAPAssetDBTable.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + validateOAPAssetDBTable.result.message)
    Then validateOAPAssetDBTable.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateOAPAssetDBTable.result.message))

@ValidateWochitRenditionDBRecords
Scenario: MAIN PHASE 2 Validate Wochit Rendition Table Records
    * def scenarioName = WochitStage + ' MAIN PHASE 2 Validate Wochit Rendition Table Records'
    Given def TrailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    And def ValidateWochitRenditionDBRecordsParams =
        """
            {
                TrailerIDs: #(TrailerIDs),
                Stage: #(WochitStage),
                XMLNodes: #(XMLNodes)
            }
        """
    When def validateWochitRenditionTable = call read(ReUsableFeaturesPath + '/Steps/ValidateWochitRenditionDBRecords.feature') ValidateWochitRenditionDBRecordsParams
    * print validateWochitRenditionTable.result
    # Then validateWochitRenditionTable.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + validateWochitRenditionTable.result.message)
    Then validateWochitRenditionTable.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateWochitRenditionTable.result.message))

@ValidateIconikCollectionHeirarchy
Scenario: MAIN PHASE 2 Check Iconik Collection Heirarchy
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
    When def validateCollectionHeirarchy = call read(ReUsableFeaturesPath + '/StepDefs/Iconik.feature@ValidateCollectionHeirarchy') ValidateCollectionHeirarchyParams
    * print validateCollectionHeirarchy.result
    # Then validateCollectionHeirarchy.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + validateCollectionHeirarchy.result.message)
    Then validateCollectionHeirarchy.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateCollectionHeirarchy.result.message))

@ValidateIconikPlaceholdersAndAssets
Scenario: MAIN PHASE 2 Check Iconik Placeholder Existence
    *  def scenarioName = WochitStage + ' MAIN PHASE 2 Check Iconik Placeholder Existence'
    Given def TrailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    And def ValidatePlaceholderParams =
        """
            {
                Retries: 120,
                RetryDuration: 10000,
                TrailerIDs: #(TrailerIDs),
                WochitStage: #(WochitStage)
            }
        """
    When def validateIconikPlaceholder = call read(ReUsableFeaturesPath + '/StepDefs/Iconik.feature@ValidateIconikPlaceholders') ValidatePlaceholderParams
    * print validateIconikPlaceholder.result
    # Then validateIconikPlaceholder.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + validateIconikPlaceholder.result.message)
    Then validateIconikPlaceholder.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateIconikPlaceholder.result.message))