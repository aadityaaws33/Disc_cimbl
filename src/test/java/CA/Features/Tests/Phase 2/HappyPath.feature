@Regression @Phase2
Feature: Phase2: Happy Path Flow

Scenario Outline: Validate Single File Upload [Data Filename: <DATAFILENAME>]
    * def TestParams =
        """
            {
                DATAFILENAME: <DATAFILENAME>,
                EXPECTEDRESPONSEFILE: <EXPECTEDRESPONSEFILE>,
                ModifyXML: true
            }
        """
    * call read('classpath:CA/Features/ReUsable/Scenarios/Setup.feature') TestParams
    * configure afterFeature =
        """
            function() {
                karate.call(ReUsableFeaturesPath + '/Scenarios/Teardown.feature', {ExpectedDataFileName: ExpectedDataFileName})
            }
        """
    Given print TestParams
    When def Result = call read('classpath:CA/Features/ReUsable/Scenarios/ValidateOAPFull.feature') TestParams
    Then karate.info.errorMessage == null?karate.log('[PASSED]: <DATAFILENAME>'):karate.fail('[FAILED]: <DATAFILENAME>')

    Examples:
        | DATAFILENAME                                    | EXPECTEDRESPONSEFILE        |
        # NEW XML BASED ON CUSTOMER XML
        | promo_generation_DK_generic_dp.xml            | promo_generation_qa.json      |
        | promo_generation_DK_teaser_combi.xml          | promo_generation_qa.json      |
        | promo_generation_FI_bundle_dp.xml             | promo_generation_qa.json      |
        | promo_generation_FI_launch_combi.xml          | promo_generation_qa.json      |
        | promo_generation_NO_episodic_dp.xml           | promo_generation_qa.json      |
        | promo_generation_NO_prelaunch_combi.xml       | promo_generation_qa.json      | 
        | promo_generation_SE_film_dp.xml               | promo_generation_qa.json      |

# =>new scenario outline to check each time