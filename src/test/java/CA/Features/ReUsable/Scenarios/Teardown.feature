Feature: Teardown

Scenario: Teardown
    * def Teardown = 
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
    * Teardown()