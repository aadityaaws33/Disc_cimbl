Feature: Download Assets from S3

Scenario: Download Assets from S3
    * def downloadTestAssets =
        """
            function(TestAssets, AssetType) {
                var scenarioName = 'SETUP: Download Test Assets';
                for(i in TestAssets) {
                    var thisTestAsset = TestAssets[i];
                    var thisDownloadFileName = thisTestAsset.replace('Assets/', '');
                    if(AssetType == 'xml') {
                        thisDownloadFileName = ExpectedDataFileName;
                    }


                    var DownloadS3ObjectParams = {
                        S3BucketName: TestAssetsS3.Name,
                        S3Key: TestAssetsS3.Key + '/' +  thisTestAsset,
                        AWSRegion: TestAssetsS3.Region,
                        DownloadPath: DownloadsPath,
                        DownloadFilename: thisDownloadFileName,
                    }
                    var downloadFileStatus = karate.call(ReUsableFeaturesPath + '/StepDefs/S3.feature@DownloadS3Object', DownloadS3ObjectParams);
                    karate.log(downloadFileStatus.result);
                    if(downloadFileStatus.result.pass) {
                        karate.log('[PASSED] ' + scenarioName + ': ' + thisDownloadFileName);
                    } else {
                        // karate.fail('[FAILED] ' + scenarioName + ': ' + thisDownloadFileName + ': ' + karate.pretty(downloadFileStatus.result.message))
                        karate.fail('[FAILED] ' + scenarioName + ': ' + thisDownloadFileName + ': ' + downloadFileStatus.result.message)
                    }
                }
            }
        """
    * downloadTestAssets(TestAssets, AssetType)