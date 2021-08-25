Feature: Single File Upload

@SaveDBRecords
Scenario Outline: Validate Single File Upload [Data Filename: <DATAFILENAME>]
    * def RandomString = 
        """
            {
                result: '1630295984313'
            }
        """
    * def TestParams =
        """
            {
                DATAFILENAME: <DATAFILENAME>,
                EXPECTEDRESPONSEFILE: <EXPECTEDRESPONSEFILE>,
                STAGE: <STAGE>,
                isDeleteOutputOnly: <ISDELETEOUTPUTONLY>,
                WaitTime: <WAITTIME>,
                DownloadXML: true,
                ModifyXML: true,
                GenerateRandomString: false
            }
        """
    * call read('classpath:CA/Features/ReUsable/Scenarios/Setup.feature') TestParams
    * def ExpectedDataFileName = DATAFILENAME.replace('.xml', '-' + TargetEnv + '-' + RandomString.result + '-' + WochitStage +'-AUTO.xml')
    * def TestXMLPath = 'classpath:' + DownloadsPath + '/' + ExpectedDataFileName
    * call read('classpath:CA/Features/ReUsable/UnderDevelopment/SaveDBRecords.feature@Save') TestParams

    Examples:
        | DATAFILENAME                                  | EXPECTEDRESPONSEFILE        | STAGE               |  ISDELETEOUTPUTONLY | WAITTIME |
        # ------------------------------- Before Wochit Processing ---------------------------------------------------------------------------
        | promo_generation_DK_generic_dp.xml            | promo_generation_qa.json    | preWochit           |  false              | 1000     |
        | promo_generation_DK_teaser_combi.xml          | promo_generation_qa.json    | preWochit           |  false              | 2000     |
        | promo_generation_NO_episodic_dp_1.xml         | promo_generation_qa.json    | preWochit           |  false              | 3000     |
        | promo_generation_NO_prelaunch_combi.xml       | promo_generation_qa.json    | preWochit           |  false              | 4000     |
        | promo_generation_FI_bundle_dp.xml             | promo_generation_qa.json    | preWochit           |  false              | 5000     |
        | promo_generation_FI_launch_combi.xml          | promo_generation_qa.json    | preWochit           |  false              | 6000     |
        | promo_generation_SE_film_dp.xml               | promo_generation_qa.json    | preWochit           |  false              | 7000     |
       


# @Save
# Scenario: PREPARATION: Upload file to S3
#     * def scenarioName = 'PREPARATION Upload File To S3'
#     Given def UploadFileParams =
#         """
#             {
#                 S3BucketName: #(OAPHotfolderS3.Name),
#                 S3Key: #(OAPHotfolderS3.Key + '/' + ExpectedDataFileName) ,
#                 AWSRegion: #(OAPHotfolderS3.Region),
#                 FilePath: #(DownloadsPath + '/' + ExpectedDataFileName)
#             }
#         """
#     When def uploadFileStatus = call read(ReUsableFeaturesPath + '/Methods/S3.feature@UploadFile') UploadFileParams
#     * print uploadFileStatus.result
#     Then uploadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(uploadFileStatus.result.message))

@Save
Scenario: MAIN PHASE 2: Save AssetDB Records
    * def scenarioName = 'MAIN PHASE 2 Save AssetDB Records'
    * json XMLNodes = read('classpath:' + DownloadsPath + '/' +ExpectedDataFileName)
    * def validateAssetDBTrailerRecords =
        """
            function(TrailerIDs) {
                var result = {
                    message: [],
                    pass: true
                };

                for(var i in TrailerIDs) {
                    var trailerId = TrailerIDs[i];
                    var ExpectedOAPAssetDBRecord = {};
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
                        RetryDuration: 10000,
                        WriteToFile: false,
                        ShortCircuit: {}
                    }
                    var ValidationResult = karate.call(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@ValidateItemViaQuery', ValidationParams);
                    if(ValidationResult.result.response != 'No records found.') {
                        var thisResponse = ValidationResult.result.response;
                        iconikObjectIds = thisResponse.iconikObjectIds;
                        if(WochitStage == 'preWochit') {
                            if(
                                iconikObjectIds.outputAssetId == null ||
                                thisResponse.promoAssetStatus != 'Pending Upload' ||
                                (thisResponse.sourceAudioFileStatus == 'Available' && iconikObjectIds.sourceAudioAssetId == null) ||
                                (thisResponse.sourceVideoFileStatus == 'Available' && iconikObjectIds.sourceVideoAssetId == null) ||
                                (thisResponse.sponsorFileStatus == 'Available' && iconikObjectIds.sponsorAssetId == null)
                            ) {
                                i--;
                                continue;
                            }
                        }
                        for(var j in iconikObjectIds) {
                            if(thisResponse['iconikObjectIds'][j] != null) {
                                thisResponse['iconikObjectIds'][j] = '#notnull'
                            }
                        }
                        
                        var notNullFields = [
                            'modifiedAt',
                            'modifiedBy',
                            'promoXMLId',
                            'createdBy',
                            'createdAt'
                        ]

                        for(var j in notNullFields) {
                            for(var k in thisResponse) {
                                if(notNullFields[j] == k) {
                                    thisResponse[notNullFields[j]] = '#notnull';
                                }
                            }
                        }
                        karate.log()
                        // thisResponse['comments'] = "#? _ == 'Pending Asset Upload' || _ == 'Pending asset upload'";
                        thisResponse['trailerId'] = '#(RandomString.result + ' + "'" + thisResponse['trailerId'].replace(RandomString.result, '') + "'" + ')';
                        thisResponse['promoXMLName'] = '#(ExpectedDataFileName)';
                        thisResponse['showTitle']  = "#('" + thisResponse['showTitle'].replace(' ' + WochitStage, '') + " ' + WochitStage)";
                        if(thisResponse['associatedFiles']['sponsorFileName'] != '') {
                            thisResponse['associatedFiles']['sponsorFileName'] = "#(WochitStage + '_' + " + "'" + thisResponse['associatedFiles']['sponsorFileName'].replace(WochitStage + '_', '') + "')";
                        }
                        karate.log(thisResponse['associatedFiles']['outputFileName']);
                        thisResponse['associatedFiles']['outputFilename'] = "#(RandomString.result + '_' + WochitStage + '_' + " + "'" + thisResponse['associatedFiles']['outputFilename'].replace(RandomString.result + '_' + WochitStage + '_', '') + "')";
                        
                        // thisResponse['associatedFiles']['outputFileName'].replace(RandomString.result, '#(RandomString.result + ').replace(WochitStage, 'WochitStage + ') + ')';
                        //                    #(RandomString.result + 
                        // "outputFilename": "1629802776510_preWochit_FI0000000000004551337011_X_tvn_QA_TEST_AUTOMATION_NORWAY_s18_prelaunch_30_newseason_streamnow.mxf",
                        // 1629802776510_preWochit_DK0000000000004551337015_X_k5_QA_TEST_AUTOMATION_DENMARK_s01_teaser_30_+X5432_comingsoon.mxf
                        // "#(RandomString.result + '_' + WochitStage + '_' + 'FI0000000000004551337001_X_dp_Greys_Anatomy_s18_bundle02_15_newseason_27may.mxf')",

                        karate.write(karate.pretty(thisResponse), 'test-classes/' + ResultsPath + '/' + trailerId.replace(RandomString.result, '') + '.json');
                    }
                }
                
                return result;
            }
        """
    Given def TrailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    When def validateOAPAssetDBTable = validateAssetDBTrailerRecords(TrailerIDs)
    Then karate.log('SAVED! ' + karate.pretty(TrailerIDs))