Feature: Test Setup

Scenario: Test Setup - Global Functions, Variables & Procedures
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
    * def storeTrailers =
        """
            function(trailerIDs) {
                try {
                    var data = karate.read('classpath:CA/trailers.json');
                } catch(e) {
                    karate.write({}, 'test-classes/CA/trailers.json');
                    var data = {};
                }
                for(var i in trailerIDs) {
                    data[trailerIDs[i]] = isDeleteOutputOnly;
                }
                karate.write(karate.pretty(data), 'test-classes/CA/trailers.json');
            }
        """
    # ---- Paths ----
    * def ReUsableFeaturesPath = 'classpath:CA/Features/ReUsable'
    * def TestDataPath = 'classpath:CA/TestData'
    * def DownloadsPath = 'target/test-classes/CA/Downloads'
    * def ResultsPath = 'CA/Results'
    # ---- Testing Variables ----
    * def WochitStage = STAGE
    * def RandomString = GenerateRandomString == true?karate.callSingle(ReUsableFeaturesPath + '/Methods/RandomGenerator.feature@GenerateRandomString'):RandomString
    * def ExpectedDate = callonce read(ReUsableFeaturesPath + '/Methods/Date.feature@GetDateWithOffset') { offset: 0 } 
    * def ExpectedCountry = getExpectedCountry(DATAFILENAME) 
    * def ExpectedDataFileName = DATAFILENAME.replace('.xml', '-' + TargetEnv + '-' + RandomString.result + '-' + WochitStage +'-AUTO.xml')
    * def TestXMLPath = 'classpath:' + DownloadsPath + '/' + ExpectedDataFileName
    # ---- Config Variables----
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
    * karate.log('-- SETUP: Download XML File --')
    * def DownloadXMLfromS3Params =
        """
            {
                TestAssets: [
                    #(DATAFILENAME)
                ],
                AssetType: 'xml'
            }
        """
    * if(DownloadXML == true) {karate.call(ReUsableFeaturesPath + '/Scenarios/DownloadS3Assets.feature', DownloadXMLfromS3Params)}
    # ---- Modify XML for Unique Trailer IDs: epochTime + originalTrailerID ----
    # DO NOT EXECUTE IF ONLY DOING PHASE1!
    * karate.log('-- SETUP: Modify XML to make it unique --')
    * xml XMLNodes = ModifyXML == true?karate.call(ReUsableFeaturesPath + '/Methods/XML.feature@modifyXML', {TestXMLPath: TestXMLPath}).result:'<xml></xml>'
    * if(ModifyXML == true) {karate.write(karate.prettyXml(XMLNodes), TestXMLPath.replace('classpath:target/', ''))}
    * def TrailerIDs = ModifyXML == true?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id'):''
    * def TrailerNames = ModifyXML == true?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.*.outputFilename').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.outputFilename'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.*.outputFilename'):''
    * Pause(Math.floor(Math.random() * 10000) + Math.floor(Math.random() * 10000))
    * storeTrailers(TrailerIDs)
    * karate.log('-- SETUP: successfully executed --')
