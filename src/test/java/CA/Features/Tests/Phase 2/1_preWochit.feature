@Regression @Phase2 @preWochit
Feature: Phase2: Happy Path Flow - Pre Wochit

Scenario Outline: Validate Single File Upload [Data Filename: <DATAFILENAME>][Stage: <STAGE>]
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
                GenerateRandomString: true
            }
        """
    * call read('classpath:CA/Features/ReUsable/Scenarios/Setup.feature') TestParams
    * def setupCheckIconikForAssets = karate.call(ReUsableFeaturesPath + '/Methods/Iconik.feature@SetupCheckIconikAssets', {SearchKeywords: TrailerNames}).result
    * if(setupCheckIconikForAssets.length > 0) {karate.log('[SETUP][FAILED] Iconik Assets Exist! ' + setupCheckIconikForAssets); karate.abort()} else {karate.log('[SETUP][PASSED] Iconik Assets Do Not Exist')}
    * configure afterScenario =
        """
            function() {
                if(karate.info.errorMessage == null) {
                    storeData(TrailerIDs, STAGE + '_trailers.json')
                }
            }
        """
    Given print TestParams
    When def Result = call read('classpath:CA/Features/ReUsable/Scenarios/ValidateOAPFull.feature@Main') TestParams
    Then karate.info.errorMessage == null?karate.log('[PASSED]: <DATAFILENAME>'):karate.fail('[FAILED]: <DATAFILENAME>')
    Examples:
        | DATAFILENAME                                  | EXPECTEDRESPONSEFILE        | STAGE               |  ISDELETEOUTPUTONLY | WAITTIME |
        # ------------------------------- Before Wochit Processing ---------------------------------------------------------------------------
        | promo_generation_DK_generic_dp.xml            | promo_generation_qa.json    | preWochit           |  false              | 1000    |
        | promo_generation_DK_teaser_combi.xml          | promo_generation_qa.json    | preWochit           |  false              | 1500    |
        | promo_generation_NO_episodic_dp_1.xml         | promo_generation_qa.json    | preWochit           |  false              | 2000    |
        | promo_generation_NO_prelaunch_combi.xml       | promo_generation_qa.json    | preWochit           |  false              | 2500    |
        | promo_generation_FI_bundle_dp.xml             | promo_generation_qa.json    | preWochit           |  false              | 3000    |
        | promo_generation_FI_launch_combi.xml          | promo_generation_qa.json    | preWochit           |  false              | 2500    |
        | promo_generation_SE_film_dp.xml               | promo_generation_qa.json    | preWochit           |  false              | 4000    |

# =>new scenario outline to check each time