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
    # Then uploadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(uploadFileStatus.result.message))
    Then uploadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + uploadFileStatus.result.message)

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
    # Then validateOAPDataSourceTable.result.pass == true? karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(validateOAPDataSourceTable.result.message))
    Then validateOAPDataSourceTable.result.pass == true? karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + validateOAPDataSourceTable.result.message)
    
@ValidateOAPAssetDBRecords
Scenario: MAIN PHASE 2 Validate OAP AssetDB Table Records
    * def scenarioName = WochitStage + ' MAIN PHASE 2 Validate OAP AssetDB Table Records'
    * def validateAssetDBTrailerRecords =
        """
            function(TrailerIDs, stage) {
                var result = {
                    message: [],
                    pass: true
                };

                for(var i in TrailerIDs) {
                    var trailerId = TrailerIDs[i];

                    // Set expected stage
                    var expectedStage = stage;
                    if(stage == 'metadataUpdate' || stage == 'versionTypeUpdate') {
                        expectedStage = 'preWochit';
                    } else if(stage == 'rerender' || stage == 'versionTypeDelete') {
                        expectedStage = 'postWochit';
                    }

                    karate.log('Expected AssetDB Record: ' + ResourcesPath + '/OAPAssetDB/' + expectedStage + '/' + TargetEnv + '/' + trailerId.replace(RandomString.result, '') + '.json');
                    var ExpectedOAPAssetDBRecord = karate.read(ResourcesPath + '/OAPAssetDB/' + expectedStage + '/' + TargetEnv + '/' + trailerId.replace(RandomString.result, '') + '.json');

                    // Stage-specific modifications
                    if(stage == 'metadataUpdate') {
                        ExpectedOAPAssetDBRecord.xmlMetadata.data.disclaimer = stage;
                        ExpectedOAPAssetDBRecord.isMetadataUpdateRequired = true;
                        // ExpectedOAPAssetDBRecord.promoXMLName = ExpectedOAPAssetDBRecord.promoXMLName.replace(stage, expectedStage);
                    } else if(stage == 'versionTypeUpdate') {
                        ExpectedOAPAssetDBRecord.xmlMetadata.data.versionType = 'TEST';
                        ExpectedOAPAssetDBRecord.comments = '#? _ == "New Version Type - Pending Upload" || _ == "New Version Type - Pending Asset Upload"';
                    } else if(stage == 'rerender') {
                        ExpectedOAPAssetDBRecord.xmlMetadata.data.disclaimer = stage;
                        // ExpectedOAPAssetDBRecord.isMetadataUpdateRequired = true;
                        // ExpectedOAPAssetDBRecord.promoXMLName = ExpectedOAPAssetDBRecord.promoXMLName.replace(stage, expectedStage);
                    } else if(stage == 'versionTypeDelete') {
                        ExpectedOAPAssetDBRecord.xmlMetadata.data.versionType = 'TEST';
                        ExpectedOAPAssetDBRecord.comments = 'New Version Type - Pending Audio Upload';
                        ExpectedOAPAssetDBRecord.sourceAudioFileStatus = 'Not Available';
                        ExpectedOAPAssetDBRecord.promoAssetStatus = 'Pending Upload';
                        ExpectedOAPAssetDBRecord.wochitRenditionStatus = 'Not Started';
                        ExpectedOAPAssetDBRecord.wochitVideoId = null;
                        ExpectedOAPAssetDBRecord.outputFileStatus = 'Not Available';
                    }

                    // Common modifications
                    ExpectedOAPAssetDBRecord.showTitle = ExpectedOAPAssetDBRecord.showTitle.replace(stage, expectedStage);
                    ExpectedOAPAssetDBRecord.associatedFiles.outputFilename = ExpectedOAPAssetDBRecord.associatedFiles.outputFilename.replace(stage, expectedStage);
                    if(ExpectedOAPAssetDBRecord.associatedFiles.sponsorFileName != null) {
                        ExpectedOAPAssetDBRecord.associatedFiles.sponsorFileName = ExpectedOAPAssetDBRecord.associatedFiles.sponsorFileName.replace(stage, expectedStage);
                    }

                    // Environment-specific modifications to expected record
                    // QA_AUTOMATION_USER
                    if(stage == 'postWochit' || stage == 'rerender') {
                        //if(TargetEnv == 'dev' || TargetEnv == 'qa') {
                        if(TestUser == 'QA_AUTOMATION_USER') {
                            ExpectedOAPAssetDBRecord.promoAssetStatus = 'Processing';
                            ExpectedOAPAssetDBRecord.wochitRenditionStatus = 'Processing';
                            ExpectedOAPAssetDBRecord.outputFileStatus = 'Not Available';
                        }
                    }

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
                        WritePath: 'test-classes/' + ResultsPath + '/' + trailerId + '.json',
                        ShortCircuit: {
                            Key: 'promoAssetStatus',
                            Value: 'Failed'
                        }
                    }
                    var ValidationResult = karate.call(ReUsableFeaturesPath + '/StepDefs/DynamoDB.feature@ValidateItemViaQuery', ValidationParams);
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

@ValidateWochitRenditionDBRecords
Scenario: MAIN PHASE 2 Validate Wochit Rendition Table Records
    * def scenarioName = WochitStage + ' MAIN PHASE 2 Validate Wochit Rendition Table Records'
    * def getWochitRenditionReferenceIDs =
        """
            function(TrailerIDList) {
                var wochitRenditionReferenceIDs = [];
                for(var i in TrailerIDList) {
                    var trailerID = TrailerIDList[i];
                    var getItemsViaQueryParams = {
                        Param_TableName: OAPAssetDBTableName,
                        Param_QueryInfoList: [
                            {
                                infoName: 'trailerId',
                                infoValue: trailerID,
                                infoComparator: '=',
                                infoType: 'key'
                            }
                        ],
                        Param_GlobalSecondaryIndex: OAPAssetDBTableGSI,
                        AWSRegion: AWSRegion,
                        Retries: 5,
                        RetryDuration: 10000
                    }
                    //karate.log(getItemsViaQueryParams);
                    var getItemsViaQueryResult = karate.call(ReUsableFeaturesPath + '/StepDefs/DynamoDB.feature@GetItemsViaQuery', getItemsViaQueryParams).result;
                    karate.log(getItemsViaQueryResult);
                    try {
                        var thisRefId = trailerID + ":" + getItemsViaQueryResult[0].wochitRenditionReferenceID;
                        wochitRenditionReferenceIDs.push(thisRefId);
                        Pause(500);
                    } catch(e) {
                        var errMsg = 'Failed to get wochitRenditionReferenceID for ' + trailerID + ': ' + e;
                        karate.log(trailerID + ': ' + errMsg);
                        karate.log(trailerID + ': pushing null value');
                        var thisRefId = trailerID + ":null";
                        wochitRenditionReferenceIDs.push(thisRefId);
                        continue;
                    }
                }
                return wochitRenditionReferenceIDs
            }
        """
    * def validateWochitRenditionRecords =
        """
            function(referenceIDs) {
                var results = {
                    message: [],
                    pass: true
                };
                for(var i in referenceIDs) {
                    var referenceID = referenceIDs[i];
                    var trailerID = referenceID.split(':')[0];
                    var referenceID = referenceID.split(':')[1];
                    //karate.log('RANDOMSTRING: ' + RandomString);
                    var expectedResponse = karate.read(ResourcesPath + '/WochitRendition/' + TargetEnv + '/' + trailerID.split(RandomString.result)[1] + '.json');

                    if(referenceID.contains('null')) {
                        var errMsg = trailerID + ' has a null wochitRenditionReferenceID';
                        karate.log(errMsg);
                        results.message.push(errMsg);
                        results.pass = false;
                        continue;
                    }
                    
                    var validateItemViaQueryParams = {
                        Param_TableName: WochitRenditionTableName,
                        Param_QueryInfoList: [
                            {
                                infoName: 'assetType',
                                infoValue: 'VIDEO',
                                infoComparator: '=',
                                infoType: 'key'
                            },
                            {
                                infoName: 'ID',
                                infoValue: referenceID,
                                infoComparator: '=',
                                infoType: 'filter'
                            }
                        ],
                        Param_GlobalSecondaryIndex: WochitRenditionTableGSI,
                        Param_ExpectedResponse: expectedResponse,
                        AWSRegion: AWSRegion,
                        Retries: 1,
                        RetryDuration: 10000,
                        WriteToFile: true,
                        WritePath: 'test-classes/CA/WochitRenditionResults/' + trailerID + '.json',
                        ShortCircuit: {
                            Key: 'renditionStatus',
                            Value: 'FAILED'
                        }
                    }
                    //karate.log(validateItemViaQueryParams);
                    var getItemsViaQueryResult = karate.call(ReUsableFeaturesPath + '/StepDefs/DynamoDB.feature@ValidateItemViaQuery', validateItemViaQueryParams).result;
                    if(!getItemsViaQueryResult.pass) {
                        for(var j in getItemsViaQueryResult.message) {
                            var resultReason = getItemsViaQueryResult.message[j].split('reason: ')[1];
                            results.message.push(trailerID + ': ' + resultReason);
                        }
                        results.pass = false;
                    }
                    Pause(500);
                }
                return results;
            }
        """
    Given def TrailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    And def wochitReferenceIDs = getWochitRenditionReferenceIDs(TrailerIDs)
    When def validateWochitRenditionTable = validateWochitRenditionRecords(wochitReferenceIDs)
    * print validateWochitRenditionTable
    # Then validateOAPAssetDBTable.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + karate.pretty(TrailerIDs)):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateWochitRenditionTable.message))
    Then validateWochitRenditionTable.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + validateWochitRenditionTable.message)

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
    # Then validateCollectionHeirarchy.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + karate.pretty(TrailerIDs)):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateCollectionHeirarchy.result.message))
    Then validateCollectionHeirarchy.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + validateCollectionHeirarchy.result.message)

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
    # Then validateIconikPlaceholder.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + karate.pretty(TrailerIDs)):karate.fail('[FAILED] ' + scenarioName + ': ' + karate.pretty(validateIconikPlaceholder.result.message))
    Then validateIconikPlaceholder.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' - Successfully validated ' + TrailerIDs):karate.fail('[FAILED] ' + scenarioName + ': ' + validateIconikPlaceholder.result.message)