@Regression @Phase2
Feature: Phase2: Happy Path Flow

Background:
    * callonce read('classpath:CA/Features/ReUsable/Scenarios/Background.feature')
    * def RandomString = callonce read(ReUsableFeaturesPath + '/Methods/RandomGenerator.feature@GenerateRandomString')
    * def ExpectedDate = callonce read(ReUsableFeaturesPath + '/Methods/Date.feature@GetDateWithOffset') { offset: 0 }
    * def ExpectedDataFileName = DATAFILENAME.replace('.xml', '-' + TargetEnv + '-' + RandomString.result + '-AUTO.xml')
    * def TestXMLPath = 'classpath:' + DownloadsPath + '/' + ExpectedDataFileName
    * configure afterScenario =
        """
            function() {
                karate.log('-- TEARDOWN: S3 DELETE XML FROM INGEST --');
                // Teardown. Delete uploaded S3 object: failed
                var DeleteS3ObjectParams = {
                    S3BucketName: OAPHotfolderS3.Name,
                    S3Key: OAPHotfolderS3.Key + '/failed/' + ExpectedDataFileName
                }
                karate.call(ReUsableFeaturesPath + '/Methods/S3.feature@DeleteS3Object', DeleteS3ObjectParams);
                
                // Teardown. Delete uploaded S3 object: archive
                var DeleteS3ObjectParams = {
                    S3BucketName: OAPHotfolderS3.Name,
                    S3Key: OAPHotfolderS3.Key + '/archive/' + ExpectedDataFileName
                }
                karate.call(ReUsableFeaturesPath + '/Methods/S3.feature@DeleteS3Object', DeleteS3ObjectParams);
                
                karate.log('-- TEARDOWN: ICONIK DELETE TEST ASSETS --');
                var deleteIconikAssetsParams = {
                    ExpectedDataFileName: ExpectedDataFileName
                }
                karate.call(ReUsableFeaturesPath + '/Scenarios/DeleteIconikAssets.feature@Teardown', deleteIconikAssetsParams);

                karate.log('-- TEARDOWN: ASSETDB DELETE TEST RECORDS --');
                karate.call(ReUsableFeaturesPath + '/Scenarios/DeleteDBRecords.feature@DeleteAssetDBRecords');
            }
        """

Scenario Outline: Validate Single File Upload [Data Filename: <DATAFILENAME>]
    Given def TestParams =
        """
            {
                DATAFILENAME: <DATAFILENAME>,
                EXPECTEDRESPONSEFILE: <EXPECTEDRESPONSEFILE>
            }
        """
    When def Result = call read('classpath:CA/Features/ReUsable/Scenarios/ValidateOAPFull.feature') TestParams
    Then karate.info.errorMessage == null?karate.log('[PASSED]: <DATAFILENAME>'):karate.fail('[FAILED]: <DATAFILENAME>')
    Examples:
        | DATAFILENAME                                  | EXPECTEDRESPONSEFILE          |
        | promo_generation_FI_qa.xml                    | promo_generation_qa.json      |
        # | promo_generation_FI_qa_bundle_v1.0.xml        | promo_generation_qa.json    |
        # | promo_generation_FI_qa_generic_v1.0.xml       | promo_generation_qa.json    |
        # | promo_generation_FI_qa_episodic_v1.0.xml      | promo_generation_qa.json    |
        # | promo_generation_FI_qa_launch_v1.0.xml        | promo_generation_qa.json    |
        # | promo_generation_FI_qa_prelaunch_v1.0.xml     | promo_generation_qa.json    |
        # | promo_generation_FI_qa_teasers_v1.0.xml       | promo_generation_qa.json    |
        # | promo_generation_FI_qa_films_v1.0.xml         | promo_generation_qa.json    |
        # ###############################################################################
        # | promo_generation_FI_qa_bundle_v2.0.xml        | promo_generation_qa.json    |
        # | promo_generation_FI_qa_episodic_v2.0.xml      | promo_generation_qa.json    |
        # | promo_generation_FI_qa_generic_v2.0.xml       | promo_generation_qa.json    |
        # | promo_generation_FI_qa_launch_v2.0.xml        | promo_generation_qa.json    |
        # | promo_generation_FI_qa_prelaunch_v2.0.xml     | promo_generation_qa.json    |
        # | promo_generation_FI_qa_teasers_v2.0.xml       | promo_generation_qa.json    |
        # | promo_generation_FI_qa_films_v2.0.xml         | promo_generation_qa.json    |

# =>new scenario outline to check each time