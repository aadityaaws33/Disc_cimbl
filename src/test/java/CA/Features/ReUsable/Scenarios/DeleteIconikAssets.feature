@parallel=false
Feature: Delete test assets after all the executions have finished

Background:
    * callonce read('classpath:CA/Features/ReUsable/Scenarios/Background.feature')

# For manual deletion
@SearchAndDeleteAssets
Scenario: Search and delete all Iconik assets which contains a particular pattern in its filename
    * def SearchKeyword = 'SPONS_10923874561*'
    * def SearchFields = ['id']
    * def searchAndDelete =
        """
            function() {
                var filterTerms = [
                    {
                        name: 'status',
                        value: 'ACTIVE'
                    }
                ]
                var searchQuery = karate.read(TestDataPath + '/Iconik/GETSearchRequest.json')
                searchQuery.filter.terms = karate.toJson(filterTerms);
                var SearchForAssetsParams = {
                    URL: '',
                    Query: searchQuery
                }
                var page = 1;
                while (true) {
                    // var deleteAssetIDList = [];
                    SearchForAssetsParams.URL = IconikSearchAPIUrl + '&page=' + page;
                    var searchResult = karate.call(ReUsableFeaturesPath + '/Methods/Iconik.feature@SearchForAssets', SearchForAssetsParams);
                    var thisPath = '$.objects.*.id';
                    var searchedAssetIDs = karate.jsonPath(searchResult.result, thisPath);
                    // for(var j in searchedAssetIDs) {
                    //     deleteAssetIDList.push(searchedAssetIDs[j]);
                    // }

                    var DeleteAssetParams = {
                        URL: IconikDeleteAssetAPIUrl,
                        Query: {
                            ids: searchedAssetIDs
                        }
                    }
                    karate.call(ReUsableFeaturesPath + '/Methods/Iconik.feature@DeleteAsset', DeleteAssetParams);
                    if(page >= searchResult.result.pages) {
                        break
                    } 
                    page++;
                    Pause(1000);
                }
                return page
            }
        """
    * searchAndDelete()

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
    * call read('classpath:CA/Features/ReUsable/Scenarios/DeleteIconikAssets.feature@Delete') TestParams
    * call read('classpath:CA/Features/ReUsable/Scenarios/DeleteIconikAssets.feature@Teardown') TestParams
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
    Then downloadFileStatus.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + karate.pretty(downloadFileStatus.result.message))

@Teardown
Scenario: Teardown: Delete Iconik Assets
    * def scenarioName = 'TEARDOWN Delete Iconik Assets'
    * def getAssetIDs =
        """
            function(QueryResult) {
                
                var assetIDs = karate.jsonPath(QueryResult, '$.*.iconikObjectIds.showTitleCollectionId');
                var finalAssetIDs = [];
                for(var i in assetIDs) {
                    if(assetIDs[i] != null) {
                        finalAssetIDs.push(assetIDs[i]);
                    }
                }
                return finalAssetIDs;
            }
        """
    Given def GetItemsViaQueryParams =
        """
            {
                Param_TableName: #(OAPAssetDBTableName),
                Param_QueryInfoList: [
                    {
                        infoName: 'promoAssetStatus',
                        infoValue: 'Pending Upload',
                        infoComparator: '=',
                        infoType: 'key'
                    },
                    {
                        infoName: 'promoXMLName',
                        infoValue: #(ExpectedDataFileName),
                        infoComparator: 'contains',
                        infoType: 'filter'
                    }
                ],
                Param_GlobalSecondaryIndex: 'promoAssetStatus-modifiedAt-Index',
                AWSRegion: #(AWSRegion)
            }
        """
    When def OAPAssetDBItems = call read(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@GetItemsViaQuery') GetItemsViaQueryParams
    And def DeleteIDList = getAssetIDs(OAPAssetDBItems.result)
    And def DeleteParams =
        """
            {
                URL: #(IconikDeleteQueueAPIUrl + '/bulk'),
                Query: {
                    contently_only: true,
                    object_ids: #(DeleteIDList),
                    object_type: 'collections'   
                },
                ExpectedStatusCode: 202
            }
        """
    Then DeleteIDList.length > 0?karate.log(ReUsableFeaturesPath + '/Methods/Iconik.feature@DeleteAssetCollection',DeleteParams):karate.log('[Teardown] Nothing to delete')
    And def DeleteParams =
        """
            {
                URL: #(IconikDeleteQueueAPIUrl + '/collections'),
                Query: {
                    ids: #(DeleteIDList)
                },
                ExpectedStatusCode: 204
            }
        """
    Then DeleteIDList.length > 0?karate.log(ReUsableFeaturesPath + '/Methods/Iconik.feature@DeleteAssetCollection',DeleteParams):karate.log('[Teardown] Nothing to delete')