Feature: Test Setup

Scenario: Test Setup - Global Variables & Procedures
    # ---- Functions ----
    * def Pause = function(pause){ karate.log('Pausing for ' + pause + 'ms.'); java.lang.Thread.sleep(pause) }
    * def getExpectedCountry =
        """
            function(DATAFILENAME) {
                var expectedCountry = 'Finland';
                if(DATAFILENAME.contains('DK')) {
                    expectedCountry = 'Denmark';
                } 
                else if(DATAFILENAME.contains('NO')) {
                    expectedCountry = 'Norway'
                }
                else if(DATAFILENAME.contains('SE')) {
                    expectedCountry = 'Sweden'
                }
                return expectedCountry
            }
        """
    # ---- Paths ----
    * def ReUsableFeaturesPath = 'classpath:CA/Features/ReUsable'
    * def TestDataPath = 'classpath:CA/TestData'
    * def DownloadsPath = 'target/test-classes/CA/Downloads'
    * def ResultsPath = 'CA/Results'
    # ---- Variables ----
    * def RandomString = karate.callSingle(ReUsableFeaturesPath + '/Methods/RandomGenerator.feature@GenerateRandomString')
    * def ExpectedDate = callonce read(ReUsableFeaturesPath + '/Methods/Date.feature@GetDateWithOffset') { offset: 0 } 
    * def ExpectedCountry = getExpectedCountry(DATAFILENAME) 
    * def ExpectedDataFileName = DATAFILENAME.replace('.xml', '-' + TargetEnv + '-' + RandomString.result + '-AUTO.xml')
    * def TestXMLPath = 'classpath:' + DownloadsPath + '/' + ExpectedDataFileName
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
    # # ---- SETUP Procedures ----
    # * def DownloadS3AssetsParams =
    #     """
    #         {
    #             TestAssets: [
    #                 'Assets/15 AUDIO.wav',
    #                 'Assets/15 VIDEO.mxf'
    #                 'Assets/25 AUDIO.wav',
    #                 'Assets/25 VIDEO.mxf'
    #                 'Assets/30 AUDIO.wav',
    #                 'Assets/30 VIDEO.mxf',
    #                 'Assets/SPONSOR.mxf'
    #             ],
    #             AssetType: 'media'
    #         }
    #     """
    # * karate.callSingle(ReUsableFeaturesPath + '/Scenarios/DownloadS3Assets.feature', DownloadS3AssetsParams)
    * def DownloadXMLfromS3Params =
        """
            {
                TestAssets: [
                    #(DATAFILENAME)
                ],
                AssetType: 'xml'
            }
        """
    * call read(ReUsableFeaturesPath + '/Scenarios/DownloadS3Assets.feature') DownloadXMLfromS3Params
    # ---- Modify XML for Unique Trailer IDs: epochTime + originalTrailerID ----
    # DO NOT EXECUTE IF ONLY DOING PHASE1!
    * def scenarioName = 'SETUP: Modify XML to make it unique'
    * xml XMLNodes = ModifyXML?karate.call(ReUsableFeaturesPath + '/Methods/XML.feature@modifyXMLTrailerIDs', {TestXMLPath: TestXMLPath}).result:'<xml></xml>'
    * if(ModifyXML) {karate.write(karate.prettyXml(XMLNodes), TestXMLPath.replace('classpath:target/', ''))}
    * def trailerIDs = ModifyXML?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id'):''
    * print 'SETUP successfully executed'
