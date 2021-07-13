@parallel=false
Feature: Single File Upload

Background:
    * callonce read('classpath:CA/Features/ReUsable/Scenarios/Background.feature')
    # * def ExpectedDataFileName = DATAFILENAME.replace('qa', ) //RandomString.result)
    * def ExpectedDataFileName = DATAFILENAME.replace('.xml', '-' + TargetEnv + '-AUTO.xml')

@SaveDBRecords
Scenario Outline: Validate Single File Upload [Data Filename: <DATAFILENAME>]
    * def TestParams =
        """
            {
                DATAFILENAME: <DATAFILENAME>,
                EXPECTEDRESPONSEFILE: <EXPECTEDRESPONSEFILE>
            }
        """
    * call read('classpath:CA/Features/ReUsable/Scenarios/SaveDBRecords.feature@Save') TestParams
    Examples:
        | DATAFILENAME                                  | EXPECTEDRESPONSEFILE        |
        # | promo_generation_FI_qa_bundle_v1.0.xml        | promo_generation_qa.json    |
        # | promo_generation_FI_qa_generic_v1.0.xml       | promo_generation_qa.json    |
        # | promo_generation_FI_qa_episodic_v1.0.xml      | promo_generation_qa.json    |
        # | promo_generation_FI_qa_launch_v1.0.xml        | promo_generation_qa.json    |
        # | promo_generation_FI_qa_prelaunch_v1.0.xml     | promo_generation_qa.json    |
        # | promo_generation_FI_qa_teasers_v1.0.xml       | promo_generation_qa.json    |
        # | promo_generation_FI_qa_films_v1.0.xml         | promo_generation_qa.json    |
        ###############################################################################
        # | promo_generation_FI_qa_bundle_v2.0.xml        | promo_generation_qa.json    |
        # | promo_generation_FI_qa_episodic_v2.0.xml      | promo_generation_qa.json    |
        # | promo_generation_FI_qa_generic_v2.0.xml       | promo_generation_qa.json    |
        # | promo_generation_FI_qa_launch_v2.0.xml        | promo_generation_qa.json    |
        # | promo_generation_FI_qa_prelaunch_v2.0.xml     | promo_generation_qa.json    |
        # | promo_generation_FI_qa_teasers_v2.0.xml       | promo_generation_qa.json    |
        # | promo_generation_FI_qa_films_v2.0.xml         | promo_generation_qa.json    |
        # | promo_generation_FI_qa_SHORTENED.xml        | promo_generation_qa.json    |


@Save
Scenario: PREPARATION: Downloading file from S3
    * def scenarioName = 'PREPARATION Download From S3'
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
    Then downloadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(downloadFileStatus.result.message))

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
            function(trailerIDs) {
                var result = {
                    message: [],
                    pass: true
                };

                for(var i in trailerIDs) {
                    var trailerId = trailerIDs[i];
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
                        if(
                            iconikObjectIds.outputAssetId == null ||
                            (thisResponse.sourceAudioFileStatus == 'Available' && iconikObjectIds.sourceAudioAssetId == null) ||
                            (thisResponse.sourceVideoFileStatus == 'Available' && iconikObjectIds.sourceVideoAssetId == null) ||
                            (thisResponse.sponsorFileStatus == 'Available' && iconikObjectIds.sponsorAssetId == null)
                        ) {
                            i--;
                            continue;
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
                        
                        thisResponse['promoXMLName'] = '#(ExpectedDataFileName)';
                                               
                        karate.write(karate.pretty(thisResponse), 'test-classes/' + ResultsPath + '/' + trailerId + '.json');
                    }
                }
                
                return result;
            }
        """
    Given def trailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    When def validateOAPAssetDBTable = validateAssetDBTrailerRecords(trailerIDs)
    Then karate.log('SAVED! ' + karate.pretty(trailerIDs))