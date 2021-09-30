@parallel=false
Feature: Delete test assets after all the executions have finished

Scenario: Teardown: Delete Iconik Assets
    * def scenarioName = 'TEARDOWN Delete Iconik Assets'
    * def getAssets =
        """
            function(TrailerData) {
                var finalAssets = {
                    assetIDs: [],
                    assetNames: [],
                    collections: []
                }

                for(var i in TrailerData) {
                    var trailerId = i;
                    var isDeleteOutputOnly = TrailerData[i];
                    karate.log('TrailerID: ' + trailerId + ' isDeleteOnly: ' + isDeleteOutputOnly);
                    var filePath = 'classpath:' + ResultsPath + '/' + trailerId + '.json';
                    try {
                        var trailerIdAssetDBrecord = karate.read(filePath);
                    } catch (e) {
                        karate.log('Failed to read ' + filePath + '! ' + e);
                    }
                    // karate.log(trailerIdAssetDBrecord)
                    if(isDeleteOutputOnly == true) {
                        var iconikAsset = karate.jsonPath(trailerIdAssetDBrecord, '$.iconikObjectIds.outputAssetId');
                        finalAssets.assetIDs.push(iconikAsset);
                        
                        var iconikOutputFilename = karate.jsonPath(trailerIdAssetDBrecord, '$.associatedFiles.outputFilename');
                        finalAssets.assetNames.push(iconikOutputFilename);                       
                    } else {
                        var iconikCollection = karate.jsonPath(trailerIdAssetDBrecord, '$.iconikObjectIds.showTitleCollectionId');
                        finalAssets.collections.push(iconikCollection);
                    }

                }

                // Schema:
                // finalAssets = {
                //     assetIDs: [<Iconik AssetIDs>],
                //     assetNames: [<Iconik OutputFilenames>],
                //     collections: [<Iconik Collections>]
                // }

                return finalAssets;
            }
        """
    * def deleteAssets =
        """
            function(assetData) {
                // karate.log('[Teardown] Asset Data: ' + karate.pretty(assetData));
                karate.log('[Teardown] Asset Data: ' + assetData);

                if(assetData.assetIDs == null || assetData.assetIDs.length < 1) {
                    karate.log('[Teardown] No asset IDs to delete');
                } else {
                    karate.log('[Teardown] Deleting assets: ' + assetData.assets);
                    // ASSET IDs
                    var deleteParams = {
                        URL: IconikDeleteQueueAPIUrl + '/assets',
                        Query: {
                            ids: assetData.assetIDs
                        },
                        ExpectedStatusCode: 204
                    }
                    karate.call(ReUsableFeaturesPath + '/StepDefs/Iconik.feature@DeleteAssetCollection', deleteParams);
                }

                if(assetData.assetNames == null || assetData.assetNames.length < 1) {
                    karate.log('[Teardown] No output filenames to search and delete ');
                } else {
                    karate.log('[Teardown] : Searching and deleting:' + assetData.assetNames);
                    karate.call(ReUsableFeaturesPath + '/StepDefs/Iconik.feature@SearchAndDeleteAssets', {SearchKeywords: assetData.assetNames});
                }

                if(assetData.collections == null || assetData.collections.length < 1) {
                    karate.log('[Teardown] No collections to delete');
                } else {
                    // COLLECTIONS - DELETE CONTENT
                    karate.log('[Teardown] Deleting collection contents: ' + assetData.collections);
                    var deleteParams = {
                        URL: IconikDeleteQueueAPIUrl + '/bulk',
                        Query: {
                            content_only: true,
                            object_ids: assetData.collections,
                            object_type: 'collections'
                        },
                        ExpectedStatusCode: 202
                    }
                    karate.call(ReUsableFeaturesPath + '/StepDefs/Iconik.feature@DeleteAssetCollection', deleteParams);
                    
                    // COLLECTIONS - DELETE COLLECTION
                    karate.log('[Teardown] Deleting collections: ' + assetData.collections);
                    var deleteParams = {
                        URL: IconikDeleteQueueAPIUrl + '/collections',
                        Query: {
                            ids: assetData.collections
                        },
                        ExpectedStatusCode: 204
                    }
                    karate.call(ReUsableFeaturesPath + '/StepDefs/Iconik.feature@DeleteAssetCollection', deleteParams);
                }
            }
        """   
    * def assetData = getAssets(TrailerData)
    * deleteAssets(assetData)
