@Regression @Phase1
Feature: Edge Casess TestAssetsS3

Scenario Outline: Validate Single File Upload [Data Filename: <DATAFILENAME>]
    * def TestParams =
        """
            {
                DATAFILENAME: <DATAFILENAME>,
                EXPECTEDRESPONSEFILE: <EXPECTEDRESPONSEFILE>,
                STAGE: '',
                isDeleteOutputOnly: <ISDELETEOUTPUTONLY>,
                WaitTime: <WAITTIME>,
                DownloadXML: true,
                ModifyXML: true,
                GenerateRandomString: false
            }
        """
    * call read('classpath:CA/Features/ReUsable/Scenarios/ValidateOAPPhase1.feature') TestParams

    Examples:
        | DATAFILENAME              |   EXPECTEDRESPONSEFILE        | WAITTIME |
        | Empty.xml                 |   Empty.json                  | 0        |
        | UnclosedNode.xml          |   UnclosedNode.json           | 0        |
        | UnexpectedNode.xml        |   UnexpectedNode.json         | 0        |
        | WrongFileExtension.pdf    |   WrongFileExtension.json     | 0        |
        | WrongValueType.xml        |   WrongValueType.json         | 0        |
        | NoFileExtension           |   NoFileExtension.json        | 0        |