@Teardown
Feature: Teardown

Scenario Outline: Teardown
    * def Pause = function(pause){ karate.log('Pausing for ' + pause + 'ms.'); java.lang.Thread.sleep(pause) }
    * configure abortedStepsShouldPass = true
    * def GlobalVarsParams =
        """
            {
                DATAFILENAME: 'DK', 
                STAGE: <STAGE>,
                GenerateRandomString: true
            }
        """
    * call read('classpath:CA/Features/ReUsable/Scenarios/GlobalVariables.feature') GlobalVarsParams
    * def deleteAssetDBRecords =
        """
            function(TrailerData, TrailerIDs) {
                try {                  
                    karate.log('-- TEARDOWN: ASSETDB DELETE TEST RECORDS --');
                    var DeleteAssetDBRecordsParams = {
                        TrailerData: TrailerData,
                        TrailerIDs: TrailerIDs
                    }
                    karate.call(ReUsableFeaturesPath + '/Scenarios/DeleteDBRecords.feature', DeleteAssetDBRecordsParams );
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
                    karate.call(ReUsableFeaturesPath + '/Scenarios/TeardownIconikAssets.feature', deleteIconikAssetsParams);
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
                } catch (e) {
                    karate.log('[Teardown] Skipping ASSETDB & ICONIK Deletion - ' + e);
                    karate.abort();
                }

                if(TrailerData.length < 1) {
                    karate.log('[Teardown] No TrailerIDs for ' + WochitStage);
                } else {
                    deleteAssetDBRecords(TrailerData, TrailerIDs);
                    deleteIconikAssets(TrailerData);                    
                }
            }
        """
    Examples:
        | STAGE          |
        | preWochit      |
        | postWochit     |
        | metadataUpdate |