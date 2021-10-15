Feature: Global Variables

Scenario: Global Variables
    # ---- Functions ----
    
    # ---- Paths ----
    * def ReUsableFeaturesPath = 'classpath:CA/Features/ReUsable'
    * def ResourcesPath = 'classpath:CA/resources'
    * def DownloadsPath = 'target/test-classes/CA/Downloads'
    * def ResultsPath = 'CA/Results'
    # ---- Testing Variables ----
    * def WochitStage = STAGE
    * def RandomString = GenerateRandomString == true?karate.call(ReUsableFeaturesPath + '/StepDefs/RandomGenerator.feature@GenerateRandomString'):RandomString
    * def ExpectedDate = callonce read(ReUsableFeaturesPath + '/StepDefs/Date.feature@GetDateWithOffset') { offset: 0 } 
    * def ExpectedDataFileName = DATAFILENAME.replace('.xml', '-' + TargetEnv + '-' + RandomString.result + '-' + WochitStage +'-AUTO.xml')
    * def TestXMLPath = 'classpath:' + DownloadsPath + '/' + ExpectedDataFileName
    # ---- Config Variables----
    # * def TestUser = EnvConfig['Common']['TestUser']
    * def AWSRegion = EnvConfig['Common']['AWSRegion']
    * def TestAssetsS3 = EnvConfig['Common']['S3bucket']['TestAssets']
    * def WochitRenditionTableName = EnvConfig['Common']['WochitRendition']['TableName']
    * def WochitRenditionTableGSI = EnvConfig['Common']['WochitRendition']['GSI']
    * def OAPHotfolderS3 = EnvConfig['Common']['S3bucket']['OAPHotfolder']
    * def OAPDataSourceTableName = EnvConfig['Common']['DataSource']['TableName']
    * def OAPDataSourceTableGSI = EnvConfig['Common']['DataSource']['GSI']
    * def OAPAssetDBTableName = EnvConfig['Common']['AssetDB']['TableName']
    * def OAPAssetDBTableGSI = EnvConfig['Common']['AssetDB']['GSI']
    * def IconikAssetDataAPIUrl = EnvConfig['Common']['Iconik']['AssetDataAPIUrl']
    * def IconikGetAppTokenAPIUrl = EnvConfig['Common']['Iconik']['GetAppTokenAPIUrl']
    * def IconikDeleteQueueAPIUrl = EnvConfig['Common']['Iconik']['DeleteQueueAPIUrl']
    * def IconikSearchAPIUrl = EnvConfig['Common']['Iconik']['SearchAPIUrl']
    * def IconikAppTokenName = EnvConfig['Common']['Iconik']['AppTokenName']
    * def IconikAdminEmail = EnvConfig['Common']['Iconik']['AdminEmail']
    * def IconikAdminPassword = EnvConfig['Common']['Iconik']['AdminPassword']
    * def IconikAuthenticationData = karate.callSingle(ReUsableFeaturesPath + '/StepDefs/Iconik.feature@GetAppTokenData').result
    * def IconikAuthToken = IconikAuthenticationData['IconikAuthToken']
    * def IconikAppID = IconikAuthenticationData['IconikAppID']