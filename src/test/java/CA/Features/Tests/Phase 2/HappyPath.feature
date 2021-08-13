@Regression @Phase2
Feature: Phase2: Happy Path Flow

Scenario Outline: Validate Single File Upload [Data Filename: <DATAFILENAME>]
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
    * configure afterFeature =
        """
            function() {
                var teardownParams = {
                    ExpectedDataFileName: ExpectedDataFileName
                }
                karate.call(ReUsableFeaturesPath + '/Scenarios/Teardown.feature', teardownParams)
            }
        """
    # * karate.abort()
    Given print TestParams
    When def Result = call read('classpath:CA/Features/ReUsable/Scenarios/ValidateOAPFull.feature') TestParams
    Then karate.info.errorMessage == null?karate.log('[PASSED]: <DATAFILENAME>'):karate.fail('[FAILED]: <DATAFILENAME>')
    Examples:
        | DATAFILENAME                                  | EXPECTEDRESPONSEFILE        | STAGE               |  ISDELETEOUTPUTONLY | WAITTIME |
        # ------------------------------- Before Wochit Processing ---------------------------------------------------------------------------
        | promo_generation_DK_generic_dp.xml            | promo_generation_qa.json    | beforeProcessing    |  false              | 1000     |
        | promo_generation_DK_teaser_combi.xml          | promo_generation_qa.json    | beforeProcessing    |  false              | 2000     |
        | promo_generation_NO_episodic_dp_1.xml         | promo_generation_qa.json    | beforeProcessing    |  false              | 3000     |
        | promo_generation_NO_prelaunch_combi.xml       | promo_generation_qa.json    | beforeProcessing    |  false              | 4000     |
        | promo_generation_FI_bundle_dp.xml             | promo_generation_qa.json    | beforeProcessing    |  false              | 5000     |
        | promo_generation_FI_launch_combi.xml          | promo_generation_qa.json    | beforeProcessing    |  false              | 6000     |
        # SWEDEN IS NOT YET IMPLEMENTED FOR WOCHIT
        # | promo_generation_SE_film_dp.xml               | promo_generation_qa.json    | beforeProcessing    |  false              | 7000     |
        # ------------------------------- After Wochit Processing ----------------------------------------------------------------------------
        | promo_generation_DK_generic_dp.xml            | promo_generation_qa.json    | afterProcessing     |  true               | 8000     |
        | promo_generation_DK_teaser_combi.xml          | promo_generation_qa.json    | afterProcessing     |  true               | 9000     |
        | promo_generation_NO_episodic_dp_1.xml         | promo_generation_qa.json    | afterProcessing     |  true               | 10000    |
        | promo_generation_NO_prelaunch_combi.xml       | promo_generation_qa.json    | afterProcessing     |  true               | 11000    |
        | promo_generation_FI_bundle_dp.xml             | promo_generation_qa.json    | afterProcessing     |  true               | 12000    |
        | promo_generation_FI_launch_combi.xml          | promo_generation_qa.json    | afterProcessing     |  true               | 13000    |
        # SWEDEN IS NOT YET IMPLEMENTED FOR WOCHIT 
        # | promo_generation_SE_film_dp.xml               | promo_generation_qa.json    | afterProcessing     |  true              | 14000     |
# =>new scenario outline to check each time