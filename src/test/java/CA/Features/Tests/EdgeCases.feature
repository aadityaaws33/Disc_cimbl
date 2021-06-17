@Regression
<<<<<<< HEAD
Feature: Happy Path Flow TestAssetsS3
=======
Feature: Edge Casess TestAssetsS3
>>>>>>> a0c191d (CRAU-1415)

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
        | Empty.xml                 |   Empty.json                  |
        | UnclosedNode.xml          |   UnclosedNode.json           |
        | UnexpectedNode.xml        |   UnexpectedNode.json         |
        | WrongFileExtension.pdf    |   WrongFileExtension.json     |
        | WrongValueType.xml        |   WrongValueType.json         |
        | NoFileExtension           |   NoFileExtension.json        |