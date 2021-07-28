@parallel=false 
Feature: Delete AssetDB Records

@DeleteAssetDBRecords
Scenario: Delete AssetDB Records
    * json XMLNodes = read('classpath:' + DownloadsPath + '/' + ExpectedDataFileName)
    * def trailerIDs = karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id')
    * def formDeleteDBRecordsParams =
        """
            function(trailerIDList) {
                var paramList = [];
                for(var i in trailerIDList) {
                    var thisParam = {

                        PrimaryPartitionKeyName: 'trailerId',
                        PrimaryPartitionKeyValue: trailerIDList[i],
                    }
                    paramList.push(thisParam);
                }

                var finalParams = {
                    itemParamList: paramList,
                    TableName: OAPAssetDBTableName,
                    GSI: 'promoAssetStatus-modifiedAt-Index',
                    PromoAssetStatus: 'Pending Upload',
                    PrimaryFilterKeyName: 'promoXMLName',
                    PrimaryFilterKeyValue: ExpectedDataFileName,
                    Retries: 5,
                    RetryDuration: 5000,
                    AWSRegion: AWSRegion
                };

                return finalParams;
            }
        """
    Given def DeleteDBRecordsParams = formDeleteDBRecordsParams(trailerIDs)
    When def deleteDBRecordStatus = call read(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@DeleteDBRecords') DeleteDBRecordsParams
    * print deleteDBRecordStatus.result
    Then deleteDBRecordStatus.result.pass == true?karate.log('[PASSED]: Successfully deleted in DB: ' + karate.pretty(trailerIDs)):karate.fail('[FAILED]: ' + karate.pretty(deleteDBRecordStatus.result.message))

# @ManualDeleteAssetDBRecords
# Scenario Outline: Delete Asset DB Records
#     * def TestParams =
#         """
#             {
#                 DATAFILENAME: <DATAFILENAME>,
#                 EXPECTEDRESPONSEFILE: <EXPECTEDRESPONSEFILE>
#             }
#         """
#     * call read('classpath:CA/Features/ReUsable/Scenarios/DeleteDBRecords.feature@Delete') TestParams
#     Examples:
#         | DATAFILENAME                                   | EXPECTEDRESPONSEFILE        |
#         | promo_generation_FI_qa_bundle_v1.0.xml         | promo_generation_qa.json    |
#         | promo_generation_FI_qa_generic_v1.0.xml        | promo_generation_qa.json    |
#         | promo_generation_FI_qa_launch_v1.0.xml         | promo_generation_qa.json    |
#         | promo_generation_FI_qa_prelaunch_v1.0.xml      | promo_generation_qa.json    |
#         | promo_generation_FI_qa_teasers_v1.0.xml        | promo_generation_qa.json    |
#         | promo_generation_FI_qa_episodic_v1.0.xml       | promo_generation_qa.json    |
#         | promo_generation_FI_qa_films_v1.0.xml          | promo_generation_qa.json    |
#         ###############################################################################
#         # | promo_generation_FI_qa_bundle_v2.0.xml        | promo_generation_qa.json    |
#         # | promo_generation_FI_qa_episodic_v2.0.xml      | promo_generation_qa.json    |
#         # | promo_generation_FI_qa_generic_v2.0.xml       | promo_generation_qa.json    |
#         # | promo_generation_FI_qa_launch_v2.0.xml        | promo_generation_qa.json    |
#         # | promo_generation_FI_qa_prelaunch_v2.0.xml     | promo_generation_qa.json    |
#         # | promo_generation_FI_qa_teasers_v2.0.xml       | promo_generation_qa.json    |
#         # | promo_generation_FI_qa_films_v2.0.xml         | promo_generation_qa.json    |

# @Delete
# Scenario: PREPARATION: Downloading file from S3
#     * def scenarioName = 'PREPARATION Download From S3'
#     Given def DownloadS3ObjectParams =
#         """
#             {
#                 S3BucketName: #(TestAssetsS3.Name),
#                 S3Key: #(TestAssetsS3.Key + '/' + DATAFILENAME),
#                 AWSRegion: #(TestAssetsS3.Region),
#                 DownloadPath: #(DownloadsPath),
#                 DownloadFilename: #(ExpectedDataFileName),
#             }
#         """
#     When def downloadFileStatus = call read(ReUsableFeaturesPath + '/Methods/S3.feature@DownloadS3Object') DownloadS3ObjectParams
#     Then downloadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(downloadFileStatus.result.message))

