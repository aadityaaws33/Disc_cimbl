@Teardown
Feature: Teardown

Scenario Outline: Teardown
    * configure report = false
    * configure abortedStepsShouldPass = true
    * def Pause = function(pause){ karate.log('Pausing for ' + pause + 'ms.'); java.lang.Thread.sleep(pause) }
    * def GlobalVarsParams =
        """
            {
                DATAFILENAME: 'DK', 
                STAGE: <STAGE>,
                GenerateRandomString: true
            }
        """
    * call read('classpath:CA/Features/ReUsable/Steps/GlobalVariables.feature') GlobalVarsParams
    * def deleteAssetDBRecords =
        """
            function(TrailerData, TrailerIDs) {
                try {                  
                    karate.log('-- TEARDOWN: ASSETDB DELETE TEST RECORDS --');
                    var DeleteAssetDBRecordsParams = {
                        TrailerData: TrailerData,
                        TrailerIDs: TrailerIDs
                    }
                    karate.call(ReUsableFeaturesPath + '/Steps/DeleteDBRecords.feature', DeleteAssetDBRecordsParams );
                } catch (e) {
                    karate.log('[Teardown] Skipping AssetDB Deletion - ' + e);
                }
            }
        """
    * def deleteIconikAssets =
        """
            function(TrailerData) {
                try {
                    karate.log('-- TEARDOWN: ICONIK DELETE TEST ASSETS --');
                    var deleteIconikAssetsParams = {
                        TrailerData: TrailerData
                    }
                    // karate.log(deleteIconikAssetsParams);
                    karate.call(ReUsableFeaturesPath + '/Steps/TeardownIconikAssets.feature', deleteIconikAssetsParams);
                } catch (e) {
                    karate.log('[Teardown] Iconik Deletion - ' + e);
                }
            }
        """
    * configure afterScenario = 
        """
            function() {
                // Get All Trailer IDs from trailer.json
                try {
                    var TrailerData = karate.read('classpath:CA/' + WochitStage + '_trailers.json');
                    var TrailerIDs = [];
                    karate.forEach(TrailerData, function(id) { TrailerIDs.push(id) });

                    if(TrailerData.length < 1) {
                        karate.log('[Teardown] No TrailerIDs for ' + WochitStage);
                    } else {
                        deleteAssetDBRecords(TrailerData, TrailerIDs);
                        deleteIconikAssets(TrailerData);                    
                    }
                } catch (e) {
                    karate.log('[Teardown] Skipping ASSETDB & ICONIK Deletion - ' + e);                    
                }
            }
        """
    Examples:
        | STAGE             |
        | preWochit         |
        | postWochit        |
        | metadataUpdate    |
        | rerender          |
        | versionTypeUpdate |
        | versionTypeDelete |