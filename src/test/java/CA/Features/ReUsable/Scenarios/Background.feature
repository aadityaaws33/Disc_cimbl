Feature: Common Background

Scenario: Load common background
    # ---- Paths ----
    * def ReUsableFeaturesPath = 'classpath:CA/Features/ReUsable'
    * def TestDataPath = 'classpath:CA/TestData'
    * def DownloadsPath = 'target/test-classes/CA/Downloads'
    # ---- Variables ----
    * def RandomString = call read(ReUsableFeaturesPath + '/Methods/RandomGenerator.feature@GenerateRandomString')
    * def ExpectedDate = call read(ReUsableFeaturesPath + '/Methods/Date.feature@GetDateWithOffset') { offset: 0 }
    # ---- Config ----
    * configure report = { showLog: true, showAllSteps: true }
    * def AWSRegion = EnvConfig['Common']['AWSRegion']
    * def TestAssetsS3 = EnvConfig['Common']['S3bucket']['TestAssets']
    * def OAPHotfolderS3 = EnvConfig['Common']['S3bucket']['OAPHotfolder']
    * def OAPDataSourceTableName = EnvConfig['Common']['DataSource']['TableName']
    * def OAPDataSourceTableGSI = EnvConfig['Common']['DataSource']['GSI']
    # ---- Functions ----
    # -------------------
    * print "Successfully loaded common background"