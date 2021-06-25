@Regression @Phase2
Feature: Phase2: Happy Path Flow

Scenario Outline: Validate Single File Upload [Data Filename: <DATAFILENAME>]
    Given def TestParams =
        """
            {
                DATAFILENAME: <DATAFILENAME>,
                EXPECTEDRESPONSEFILE: <EXPECTEDRESPONSEFILE>
            }
        """
    When def Result = call read('classpath:CA/Features/ReUsable/Scenarios/ValidateOAPFull.feature') TestParams
    Then karate.info.errorMessage == null?karate.log('[PASSED]: <DATAFILENAME>'):karate.fail('[FAILED]: <DATAFILENAME>')
    Examples:
        | DATAFILENAME                              | EXPECTEDRESPONSEFILE        |
        # | promo_generation_FI_qa_SHORTENED.xml      | promo_generation_qa.json    |
        | promo_generation_FI_qa_bundle_v1.0.xml    | promo_generation_qa.json    |
        | promo_generation_FI_qa_episodic.xml       | promo_generation_qa.json    |
        | promo_generation_FI_qa_generic_v1.0.xml   | promo_generation_qa.json    |
        | promo_generation_FI_qa_launch.xml         | promo_generation_qa.json    |
        | promo_generation_FI_qa_prelaunch.xml      | promo_generation_qa.json    |
        | promo_generation_FI_qa_teasers.xml        | promo_generation_qa.json    |
        | promo_generation_FI_qa_films.xml          | promo_generation_qa.json    |

# =>new scenario outline to check each time