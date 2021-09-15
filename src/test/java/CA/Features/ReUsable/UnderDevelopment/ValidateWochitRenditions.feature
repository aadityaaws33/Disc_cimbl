
Feature: Validate Wochit Rendition Record
    @WIP
    Scenario Outline: MAIN PHASE 2 Validate Wochit Renditon Table Records
        * def scenarioName = 'MAIN PHASE 2 Validate Wochit Renditon Table Records'
        * def RandomString = 
            """
                {
                    result: '1631686124018'
                }
            """
        * def TestParams =
            """
                {
                    DATAFILENAME: <DATAFILENAME>,
                    EXPECTEDRESPONSEFILE: <EXPECTEDRESPONSEFILE>,
                    STAGE: <STAGE>,
                    isDeleteOutputOnly: <ISDELETEOUTPUTONLY>,
                    WaitTime: <WAITTIME>,
                    DownloadXML: true,
                    ModifyXML: true,
                    GenerateRandomString: false,
                    RandomString: #(RandomString)
                }
            """
        * call read('classpath:CA/Features/ReUsable/Scenarios/Setup.feature') TestParams
        * print TrailerIDs
        Given def ValidateWochitRenditionParams =
            """
                {
                    TrailerIDs: #(TrailerIDs)
                }
            """
        When def validateWochitRenditionTable = call read(ReUsableFeaturesPath + '/UnderDevelopment/ValidateWochitRenditions.feature@ValidateWochitRenditionDBRecords') ValidateWochitRenditionParams
        Then validateWochitRenditionTable.result.pass == true?karate.log('[PASSED] ' + scenarioName + ' ' + ExpectedDataFileName):karate.fail('[FAILED] ' + scenarioName + ' ' + ExpectedDataFileName + ': ' + validateWochitRenditionTable.result.message)
        Examples:
        | DATAFILENAME                                  | EXPECTEDRESPONSEFILE        | STAGE               |  ISDELETEOUTPUTONLY | WAITTIME |
        # ------------------------------- After Wochit Processing ----------------------------------------------------------------------------
        # | promo_generation_DK_generic_dp.xml            | promo_generation_qa.json    | postWochit          |  true               | 15000    |
        # | promo_generation_DK_teaser_combi.xml          | promo_generation_qa.json    | postWochit          |  true               | 17000    |
        # | promo_generation_NO_episodic_dp_1.xml         | promo_generation_qa.json    | postWochit          |  true               | 19000    |
        # | promo_generation_NO_prelaunch_combi.xml       | promo_generation_qa.json    | postWochit          |  true               | 21000    |
        | promo_generation_FI_bundle_dp.xml             | promo_generation_qa.json    | postWochit          |  true               | 0    |
        # | promo_generation_FI_launch_combi.xml          | promo_generation_qa.json    | postWochit          |  true               | 25000    |
        # | promo_generation_SE_film_dp.xml               | promo_generation_qa.json    | postWochit          |  true               | 27000    |

@ValidateWochitRenditionDBRecords
Scenario: MAIN PHASE 2 Validate Wochit Renditon Table Records
    * print TrailerIDs
    * def getWochitRenditionReferenceIDs =
        """
            function(TrailerIDList) {
                var wochitRenditionReferenceIDs = [];
                for(var i in TrailerIDList) {
                    var trailerID = TrailerIDList[i];
                    var getItemsViaQueryParams = {
                        Param_TableName: OAPAssetDBTableName,
                        Param_QueryInfoList: [
                            {
                                infoName: 'trailerId',
                                infoValue: trailerID,
                                infoComparator: '=',
                                infoType: 'key'
                            }
                        ],
                        Param_GlobalSecondaryIndex: OAPAssetDBTableGSI,
                        AWSRegion: AWSRegion,
                        Retries: 5,
                        RetryDuration: 10000
                    }
                    var getItemsViaQueryResult = karate.call(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@GetItemsViaQuery', getItemsViaQueryParams).result;
                    wochitRenditionReferenceIDs.push(getItemsViaQueryResult[0].wochitRenditionReferenceID);
                    Pause(500);
                }
                return wochitRenditionReferenceIDs
            }
        """
    * def wochitReferenceIDs = getWochitRenditionReferenceIDs(TrailerIDs)
    * def validateReferenceIDs =
        """
            function(referenceIDs) {
                var results = [];
                for(var i in referenceIDs) {
                    var referenceID = referenceIDs[i];
                    var getItemsViaQueryParams = {
                        Param_TableName: WochitRenditionTableName,
                        Param_QueryInfoList: [
                            {
                                infoName: 'assetType',
                                infoValue: 'VIDEO',
                                infoComparator: '=',
                                infoType: 'key'
                            },
                            {
                                infoName: 'ID',
                                infoValue: referenceID,
                                infoComparator: '=',
                                infoType: 'filter'
                            }
                        ],
                        Param_GlobalSecondaryIndex: WochitRenditionTableGSI,
                        AWSRegion: AWSRegion,
                        Retries: 5,
                        RetryDuration: 10000
                    }
                    var getItemsViaQueryResult = karate.call(ReUsableFeaturesPath + '/Methods/DynamoDB.feature@GetItemsViaQuery', getItemsViaQueryParams).result;
                    results.push(getItemsViaQueryResult[0]);
                    Pause(500);
                }
                return results;
            }
        """
    * def this = validateReferenceIDs(wochitReferenceIDs)
    * print this
    * def result =
        """
            {
                message: [],
                pass: true
            }
        """
    * print result