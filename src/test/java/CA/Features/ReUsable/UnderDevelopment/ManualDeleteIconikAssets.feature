Feature: WIP

# For manual deletion


# For manual deletion
@DeleteIconikAssets
Scenario Outline: Validate Single File Upload [Data Filename: <DATAFILENAME>]
    * def ExpectedDataFileName = DATAFILENAME.replace('.xml', '-' + TargetEnv + '-AUTO.xml')
    * def TestParams =
        """
            {
                DATAFILENAME: <DATAFILENAME>,
                ExpectedDataFileName: #(ExpectedDataFileName)
            }
        """
    * call read('classpath:CA/Features/ReUsable/Steps/TeardownIconikAssets.feature@Delete') TestParams
    * call read('classpath:CA/Features/ReUsable/Steps/TeardownIconikAssets.feature@Teardown') TestParams
    Examples:
        | DATAFILENAME                                  | EXPECTEDRESPONSEFILE        |
        | promo_generation_FI_qa_bundle_v1.0.xml        | promo_generation_qa.json    |
        | promo_generation_FI_qa_generic_v1.0.xml       | promo_generation_qa.json    |
        | promo_generation_FI_qa_episodic_v1.0.xml      | promo_generation_qa.json    |
        | promo_generation_FI_qa_launch_v1.0.xml        | promo_generation_qa.json    |
        | promo_generation_FI_qa_prelaunch_v1.0.xml     | promo_generation_qa.json    |
        | promo_generation_FI_qa_teasers_v1.0.xml       | promo_generation_qa.json    |
        | promo_generation_FI_qa_films_v1.0.xml         | promo_generation_qa.json    |
        ###############################################################################
        # | promo_generation_FI_qa_bundle_v2.0.xml        | promo_generation_qa.json    |
        # | promo_generation_FI_qa_episodic_v2.0.xml      | promo_generation_qa.json    |
        # | promo_generation_FI_qa_generic_v2.0.xml       | promo_generation_qa.json    |
        # | promo_generation_FI_qa_launch_v2.0.xml        | promo_generation_qa.json    |
        # | promo_generation_FI_qa_prelaunch_v2.0.xml     | promo_generation_qa.json    |
        # | promo_generation_FI_qa_teasers_v2.0.xml       | promo_generation_qa.json    |
        # | promo_generation_FI_qa_films_v2.0.xml         | promo_generation_qa.json    |
        # | promo_generation_FI_qa_SHORTENED.xml        | promo_generation_qa.json    |

@Delete
Scenario: PREPARATION: Downloading file from S3
    * def scenarioName = WochitStage + ' PREPARATION Download From S3'
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
    When def downloadFileStatus = call read(ReUsableFeaturesPath + '/StepDefs/S3.feature@DownloadS3Object') DownloadS3ObjectParams
    # Then downloadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(downloadFileStatus.result.message))
    Then downloadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + downloadFileStatus.result.message)
