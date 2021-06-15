@Regression
Feature: Single File Upload

Background:
    * def TCName = 'Single File Upload'
    * callonce read('classpath:CA/Features/ReUsable/Scenarios/Background.feature')
    * configure afterFeature =
        """
            function() {
                // Teardown. Delete uploaded S3 object.
                var DeleteS3ObjectParams = {
                    S3BucketName: OAPHotfolderS3.Name,
                    S3Key: OAPHotfolderS3.Key + '/' + ExpectedDataFileName
                }
                karate.call(ReUsableFeaturesPath + '/Methods/S3.feature@DeleteS3Object', DeleteS3ObjectParams);
            }
        """
Scenario Outline: Uploading Single Files And Validating OAP Data Source Table [Data Filename: <DATAFILENAME>]
    * def ExpectedDataFileName = RandomString.result + ' ' + '<DATAFILENAME>'
    * def ExpectedOAPDataSourceRecord = read(TestDataPath + '/OAPDataSource/' + TargetEnv + '/<EXPECTEDRESPONSEFILE>')
    * def ValidationParams =
        """
            {
                Param_TableName: #(OAPDataSourceTableName),
                Param_QueryInfoList: [
                    {
                        infoName: 'DataFileName',
                        infoValue: #(ExpectedDataFileName),
                        infoComparator: '=',
                        infoType: 'key'
                    },
                    {
                        infoName: 'CreatedAt',
                        infoValue: #(ExpectedDate.result),
                        infoComparator: 'begins',
                        infoType: 'key'
                    }
                ],
                Param_GlobalSecondaryIndex: #(OAPDataSourceTableGSI),
                Param_ExpectedResponse: #(ExpectedOAPDataSourceRecord),
                AWSRegion: #(AWSRegion),
                Retries: 15
            }
        """
    * def DownloadS3ObjectParams =
        """
            {
                S3BucketName: #(TestAssetsS3.Name),
                S3Key: #(TestAssetsS3.Key + '/' + '<DATAFILENAME>') ,
                AWSRegion: #(TestAssetsS3.Region),
                DownloadPath: #(DownloadsPath),
                DownloadFilename: #(ExpectedDataFileName)
            }
        """
    * def downloadFileStatus = call read(ReUsableFeaturesPath + '/Methods/S3.feature@DownloadS3Object') DownloadS3ObjectParams
    * def UploadFileParams =
        """
            {
                S3BucketName: #(OAPHotfolderS3.Name),
                S3Key: #(OAPHotfolderS3.Key + '/' + ExpectedDataFileName) ,
                AWSRegion: #(OAPHotfolderS3.Region),
                FilePath: #(DownloadsPath + '/' + ExpectedDataFileName)
            }
        """
    * def uploadFileStatus = call read(ReUsableFeaturesPath + '/Methods/S3.feature@UploadFile') UploadFileParams
    # Given The file has been downloaded from Test Assets S3 Bucket.
    Given karate.match(downloadFileStatus.result.pass, true).pass?karate.log(downloadFileStatus.result):karate.fail(karate.pretty(downloadFileStatus.result))
    # And The file has been uploaded to the OAP Hotfolder S3 Bucket
    And karate.match(uploadFileStatus.result.pass, true).pass?karate.log(uploadFileStatus.result):karate.fail(karate.pretty(uploadFileStatus.result))
    # When I validate the OAP Data Source Table Record
    When def validateOAPDataSourceTable =  call read(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@ValidateItemViaQuery') ValidationParams
    # Then It should pass the validation. Otherwise, it should fail.
    Then karate.match(validateOAPDataSourceTable.result.pass, true).pass?karate.log(validateOAPDataSourceTable.result):karate.fail(validateOAPDataSourceTable.result)

    Examples:
        | DATAFILENAME              |   EXPECTEDRESPONSEFILE        |
        | Empty.xml                 |   Empty.json                  |