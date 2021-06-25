@parallel=false
Feature: Single File Upload

Background:
    * callonce read('classpath:CA/Features/ReUsable/Scenarios/Background.feature')
    * def ExpectedDataFileName = DATAFILENAME.replace('qa', '1625016211929') //RandomString.result)

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
        | DATAFILENAME                              | EXPECTEDRESPONSEFILE        |
        | promo_generation_FI_qa_bundle_v1.0.xml    | promo_generation_qa.json    |
        # | promo_generation_FI_qa_generic_v1.0.xml   | promo_generation_qa.json    |
        # | promo_generation_FI_qa_launch.xml         | promo_generation_qa.json    |
        # | promo_generation_FI_qa_prelaunch.xml      | promo_generation_qa.json    |
        # | promo_generation_FI_qa_teasers.xml        | promo_generation_qa.json    |
        # | promo_generation_FI_qa_episodic.xml       | promo_generation_qa.json    |
        # | promo_generation_FI_qa_films.xml          | promo_generation_qa.json    |


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
                        Retries: 1,
                        RetryDuration: 1000
                    }
                    var ValidationResult = karate.call(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@ValidateItemViaQuery', ValidationParams);
                    karate.write(karate.pretty(ValidationResult.result.response), 'test-classes/' + ResultsPath + '/' + trailerId + '.json');
                }
                
                return result;
            }
        """
    Given def trailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    When def validateOAPAssetDBTable = validateAssetDBTrailerRecords(trailerIDs)
    Then karate.log('SAVED!')