@parallel=false
Feature: Single File Upload

Background:
    * def TestParams =
        """
            {
                ModifyXML: false,
                GenerateRandomString: true
            }
        """
    * callonce read('classpath:CA/Features/ReUsable/Scenarios/Setup.feature') TestParams
    * configure afterFeature =
        """
            function() {
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
            }
        """

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
    * print downloadFileStatus.result
    Then downloadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(downloadFileStatus.result.message))

Scenario: PREPARATION: Upload file to S3
    * def scenarioName = 'PREPARATION Upload File To S3'
    Given def UploadFileParams =
        """
            {
                S3BucketName: #(OAPHotfolderS3.Name),
                S3Key: #(OAPHotfolderS3.Key + '/' + ExpectedDataFileName) ,
                AWSRegion: #(OAPHotfolderS3.Region),
                FilePath: #(DownloadsPath + '/' + ExpectedDataFileName)
            }
        """
    When def uploadFileStatus = call read(ReUsableFeaturesPath + '/Methods/S3.feature@UploadFile') UploadFileParams
    * print uploadFileStatus.result
    Then uploadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(uploadFileStatus.result.message))

Scenario: MAIN PHASE 1: Validate OAP Datasource Table Record
    * def scenarioName = 'MAIN PHASE 1 Validate OAP DataSource Table Record'
    * def ExpectedOAPDataSourceRecord = read(TestDataPath + '/OAPDataSource/' + TargetEnv + '/' + EXPECTEDRESPONSEFILE)
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
                Retries: 30,
                RetryDuration: 10000,
                WriteToFile: false
            }
        """
    When def validateOAPDataSourceTable =  call read(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@ValidateItemViaQuery') ValidationParams
    * print validateOAPDataSourceTable.result
    Then validateOAPDataSourceTable.result.pass == true? karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(validateOAPDataSourceTable.result.message))
