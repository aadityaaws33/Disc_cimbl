Feature: Common Background

Scenario: Load common background
    # ---- Paths ----
    * def ReUsableFeaturesPath = 'classpath:CA/Features/ReUsable'
    * def TestDataPath = 'classpath:CA/TestData'
    * def DownloadsPath = 'target/test-classes/CA/Downloads'
    * def ResultsPath = 'CA/Results'
    # ---- Variables ----
    # ---- Config ----
    * def AWSRegion = EnvConfig['Common']['AWSRegion']
    * def TestAssetsS3 = EnvConfig['Common']['S3bucket']['TestAssets']
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
    * def IconikAuthenticationData = karate.callSingle(ReUsableFeaturesPath + '/Methods/Iconik.feature@GetAppTokenData').result
    * def IconikAuthToken = IconikAuthenticationData['IconikAuthToken']
    * def IconikAppID = IconikAuthenticationData['IconikAppID']
    # ---- Functions ----
    * def Pause = function(pause){ karate.log('Pausing for ' + pause + 'ms.'); java.lang.Thread.sleep(pause) }
    * print "Successfully loaded common background"