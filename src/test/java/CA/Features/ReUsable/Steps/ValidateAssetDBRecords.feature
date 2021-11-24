Feature: AssetDB Validation functions

Scenario: Validate Asset DB Trailer Records
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
                    
                    if(stage == 'metadataUpdate') {
                        ExpectedOAPAssetDBRecord.xmlMetadata.data.disclaimer = stage;
                        ExpectedOAPAssetDBRecord.isMetadataUpdateRequired = true;
                        // ExpectedOAPAssetDBRecord.promoXMLName = ExpectedOAPAssetDBRecord.promoXMLName.replace(stage, expectedStage);
                    } else if(stage == 'versionTypeUpdate') {
                        ExpectedOAPAssetDBRecord.xmlMetadata.data.versionType = 'TEST';
                        ExpectedOAPAssetDBRecord.comments = '#? _ == "New Version Type - Pending Upload" || _ == "New Version Type - Pending Asset Upload"';
                    } else if(stage == 'rerender') {
                        ExpectedOAPAssetDBRecord.xmlMetadata.data.disclaimer = 'rerender';
                        ExpectedOAPAssetDBRecord.isMetadataUpdateRequired = '#ignore';
                        // ExpectedOAPAssetDBRecord.promoXMLName = ExpectedOAPAssetDBRecord.promoXMLName.replace(stage, expectedStage);
                    } else if(stage == 'versionTypeDelete') {
                        ExpectedOAPAssetDBRecord.xmlMetadata.data.versionType = 'TEST';
                        ExpectedOAPAssetDBRecord.comments = 'New Version Type - Pending Audio Upload';
                        ExpectedOAPAssetDBRecord.sourceAudioFileStatus = 'Not Available';
                        ExpectedOAPAssetDBRecord.promoAssetStatus = 'Pending Upload';
                        // ExpectedOAPAssetDBRecord.wochitRenditionStatus = '#ignore';
                        // ExpectedOAPAssetDBRecord.wochitVideoId = null;
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
                        if(TestUser == 'QA_AUTOMATION_USER') {
                            // ExpectedOAPAssetDBRecord.promoAssetStatus = 'Processing';
                            // ExpectedOAPAssetDBRecord.wochitRenditionStatus = 'Processing';
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
                        WritePath: 'test-classes/' + ResultsPath + '/OAPAssetDB/' + trailerId + '.json',
                        ShortCircuit: {
                            Key: 'promoAssetStatus',
                            Value: 'Failed'
                        }
                    }
                    var ValidationResult = karate.call(ReUsableFeaturesPath + '/StepDefs/DynamoDB.feature@ValidateItemViaQuery', ValidationParams);
                    // karate.write(karate.pretty(ValidationResult.result.response), 'test-classes/' + ResultsPath + '/OAPAssetDB/' + trailerId + '.json');
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
    * def result = validateAssetDBTrailerRecords(TrailerIDs, Stage)