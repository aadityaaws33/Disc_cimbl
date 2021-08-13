@parallel=false
Feature: Single File Upload

@SaveDBRecords
Scenario Outline: Validate Single File Upload [Data Filename: <DATAFILENAME>]
    * def RandomString = 
        """
            {
                result: '1628134316328'
            }
        """"
    * def TestParams =
        """
            {
                DATAFILENAME: <DATAFILENAME>,
                EXPECTEDRESPONSEFILE: <EXPECTEDRESPONSEFILE>,
                DownloadXML: true,
                ModifyXML: true,
                STAGE: 'beforeProcessing',
                GenerateRandomString: false,
                RandomString: #(RandomString),
                WaitTime: 0
            }
        """
    * call read('classpath:CA/Features/ReUsable/Scenarios/Setup.feature') TestParams
    * def ExpectedDataFileName = DATAFILENAME.replace('.xml', '-' + TargetEnv + '-' + RandomString.result + '-AUTO.xml')
    * def TestXMLPath = 'classpath:' + DownloadsPath + '/' + ExpectedDataFileName
    * call read('classpath:CA/Features/ReUsable/Scenarios/SaveDBRecords.feature@Save') TestParams
    Examples:
        | DATAFILENAME                                  | EXPECTEDRESPONSEFILE          |
        | promo_generation_FI_bundle_dp.xml             | promo_generation_qa.json      |
        # | promo_generation_NO_episodic_dp.xml           | promo_generation_qa.json      |
        # | promo_generation_FI_launch_combi.xml          | promo_generation_qa.json      |
        # | promo_generation_DK_generic_dp.xml            | promo_generation_qa.json      |
        # | promo_generation_DK_teaser_combi.xml          | promo_generation_qa.json      |
        # | promo_generation_NO_prelaunch_combi.xml       | promo_generation_qa.json      | 
        # | promo_generation_SE_film_dp.xml               | promo_generation_qa.json      |
       


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
                        RetryDuration: 10000
                    }
                    var ValidationResult = karate.call(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@ValidateItemViaQuery', ValidationParams);
                    if(ValidationResult.result.response != 'No records found.') {
                        var thisResponse = ValidationResult.result.response;
                        iconikObjectIds = thisResponse.iconikObjectIds;
                        if(WochitStage == 'beforeProcessing') {
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
                        // thisResponse['comments'] = "#? _ == 'Pending Asset Upload' || _ == 'Pending asset upload'";
                        thisResponse['trailerId'] = '#(RandomString.result + ' + "'" + thisResponse['trailerId'].replace(RandomString.result, '') + "'" + ')';
                        thisResponse['promoXMLName'] = '#(ExpectedDataFileName)';
                        thisResponse['showTitle']  = "#('" + thisResponse['showTitle'].replace(' ' + WochitStage, '') + " ' + WochitStage)";
                        thisResponse['associatedFiles']['sponsorFileName'] = WochitStage + '_' + thisResponse['associatedFiles']['sponsorFileName'];

                        karate.write(karate.pretty(thisResponse), 'test-classes/' + ResultsPath + '/' + trailerId.replace(RandomString.result, '') + '.json');
                    }
                }
                
                return result;
            }
        """
    Given def TrailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    When def validateOAPAssetDBTable = validateAssetDBTrailerRecords(TrailerIDs)
    Then karate.log('SAVED! ' + karate.pretty(TrailerIDs))