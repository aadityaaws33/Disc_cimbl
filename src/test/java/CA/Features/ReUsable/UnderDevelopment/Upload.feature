Feature: UPLOAD WIP

Background:
    * def TestParams =
        """
            {
                DATAFILENAME: <DATAFILENAME>,
                EXPECTEDRESPONSEFILE: <EXPECTEDRESPONSEFILE>,
                DownloadXML: false,
                ModifyXML: false,
                GenerateRandomString: true,
                WaitTime: 0
            }
        """
    * call read('classpath:CA/Features/ReUsable/Scenarios/Setup.feature') TestParams
    * def RandomString =
        """
            {
                result: '1628048169995'
            }
        """
    * def stage = 'preWochit'
    * def TrailerIDs = ['1628048169995006']
    * def this =
        """
            function() {
                for(var index in TrailerIDs) {
                    trailerId = TrailerIDs[index];
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
                        Retries: 1,
                        RetryDuration: 10000
                    }
                    var ValidationResult = karate.call(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@GetItemsViaQuery', ValidationParams);
                    karate.write(karate.pretty(ValidationResult.result[0]), 'test-classes/' + ResultsPath + '/' + trailerId + '.json');
                }
            }
        """
    * call this


@WIP
Scenario: MAIN PHASE 2 Upload Assets to Iconik Placeholders
    * def scenarioName = 'MAIN PHASE 2 Upload Assets to Iconik Placeholders'
    * def GetAssetDetailsByTrailerIDsParams =
        """
            {
                TrailerIDs: #(TrailerIDs)
            }
        """
    * def TrailerAssetDetails = call read(ReUsableFeaturesPath + '/Methods/Iconik.feature@GetAssetDetailsByTrailerIDs') GetAssetDetailsByTrailerIDsParams
    * def formUploadAssetParams =
        """
            function(TrailerAssetDetails) {
                var UploadList = [];
                for(var i in TrailerAssetDetails) {
                    if(TrailerAssetDetails[i].assetType != 'OUTPUT') {
                        var fileExtension = 'mxf';
                        if(TrailerAssetDetails[i].assetType == 'AUDIO') {
                            fileExtension = 'wav'
                        }
                        TrailerAssetDetails[i]['requiredAsset'] = TrailerAssetDetails[i].assetDuration + ' ' + TrailerAssetDetails[i].assetType + '.' + fileExtension;
                        UploadList.push(TrailerAssetDetails[i]);
                    }

                }
                return UploadList
            }
        """
    * def UploadAssetToPlaceholderParams = formUploadAssetParams(TrailerAssetDetails.result)
    * print UploadAssetToPlaceholderParams
    # * call read(ReUsableFeaturesPath + '/Methods/Iconik.feature@UploadAssetToPlaceholder') UploadAssetToPlaceholderParams
    # -------------------------------------
    


