@Regression
Feature: Happy Path Flow TestAssetsS3

Scenario Outline: Validate Single File Upload [Data Filename: <DATAFILENAME>]
    * def TestParams =
        """
            {
                DATAFILENAME: <DATAFILENAME>,
                EXPECTEDRESPONSEFILE: <EXPECTEDRESPONSEFILE>
            }
        """
    * call read('classpath:CA/Features/ReUsable/Scenarios/ValidateSingleFileUpload.feature') TestParams
    Examples:
        | DATAFILENAME              |   EXPECTEDRESPONSEFILE        |
        | ValidFile.xml             |   ValidFile.json              |