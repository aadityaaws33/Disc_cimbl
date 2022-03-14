
Feature: Validate Wochit Rendition Record
    Scenario Outline: MAIN PHASE 2 Validate Wochit Renditon Table Records
        * def scenarioName = 'MAIN PHASE 2 Validate Wochit Renditon Table Records'
        * def RandomString = 
            """
                {
                    result: '1634033181619'
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
        * call read('classpath:CA/Features/ReUsable/Steps/Setup.feature') TestParams
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
        | promo_generation_DK_generic_dp.xml            | promo_generation_qa.json    | postWochit          |  true               | 15000    |
        # | promo_generation_DK_teaser_combi.xml          | promo_generation_qa.json    | postWochit          |  true               | 17000    |
        # | promo_generation_NO_episodic_dp.xml         | promo_generation_qa.json    | postWochit          |  true               | 19000    |
        # | promo_generation_NO_prelaunch_combi.xml       | promo_generation_qa.json    | postWochit          |  true               | 21000    |
        # | promo_generation_FI_bundle_dp.xml             | promo_generation_qa.json    | postWochit          |  true               | 0    |
        # | promo_generation_FI_launch_combi.xml          | promo_generation_qa.json    | postWochit          |  true               | 25000    |
        # | promo_generation_SE_film_dp.xml               | promo_generation_qa.json    | postWochit          |  true               | 27000    |

@ValidateWochitRenditionDBRecords
Scenario: MAIN PHASE 2 Validate Wochit Renditon Table Records
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
                    karate.log(getItemsViaQueryParams);
                    var getItemsViaQueryResult = karate.call(ReUsableFeaturesPath + '/StepDefs/DynamoDB.feature@GetItemsViaQuery', getItemsViaQueryParams).result;
                    karate.log(getItemsViaQueryResult);
                    try {
                        var thisRefId = trailerID + ":" + getItemsViaQueryResult[0].wochitRenditionReferenceID;
                        wochitRenditionReferenceIDs.push(thisRefId);
                        Pause(500);
                    } catch(e) {
                        var errMsg = 'Failed to get wochitRenditionReferenceID for ' + trailerID + ': ' + e;
                        karate.log(trailerID + ': ' + errMsg);
                        karate.log(trailerID + ': pushing null value');
                        var thisRefId = trailerID + ":null";
                        wochitRenditionReferenceIDs.push(thisRefId);
                        continue;
                    }
                }
                return wochitRenditionReferenceIDs
            }
        """
    * def wochitReferenceIDs = getWochitRenditionReferenceIDs(TrailerIDs)
    * print wochitReferenceIDs
    * def validateReferenceIDs =
        """
            function(referenceIDs) {
                var results = {
                    message: [],
                    pass: true
                };
                for(var i in referenceIDs) {
                    var referenceID = referenceIDs[i];
                    var trailerID = referenceID.split(':')[0];
                    var referenceID = referenceID.split(':')[1];
                    //karate.log('RANDOMSTRING: ' + RandomString);
                    var expectedResponse = karate.read(ResourcesPath + '/WochitRendition/' + TargetEnv + '/' + trailerID.split(RandomString.result)[1] + '.json');

                    if(referenceID.contains('null')) {
                        var errMsg = trailerID + ' has a null wochitRenditionReferenceID';
                        karate.log(errMsg);
                        results.message.push(errMsg);
                        results.pass = false;
                        continue;
                    }
                    
                    var validateItemViaQueryParams = {
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
                        Param_ExpectedResponse: expectedResponse,
                        AWSRegion: AWSRegion,
                        Retries: 1,
                        RetryDuration: 10000,
                        WriteToFile: true,
                        WritePath: 'test-classes/CA/WochitRenditionResults/' + trailerID + '.json',
                        ShortCircuit: {
                            Key: 'renditionStatus',
                            Value: 'FAILED'
                        }
                    }
                    //karate.log(validateItemViaQueryParams);
                    var getItemsViaQueryResult = karate.call(ReUsableFeaturesPath + '/StepDefs/DynamoDB.feature@ValidateItemViaQuery', validateItemViaQueryParams).result;
                    if(!getItemsViaQueryResult.pass) {
                        for(var j in getItemsViaQueryResult.message) {
                            var resultReason = getItemsViaQueryResult.message[j].split('reason: ')[1];
                            results.message.push(trailerID + ': ' + resultReason);
                        }
                        results.pass = false;
                    }
                    Pause(500);
                }
                return results;
            }
        """
    * def result = validateReferenceIDs(wochitReferenceIDs)
    * print result