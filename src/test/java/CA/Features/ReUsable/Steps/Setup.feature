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
    * def storeData =
        """
            function(dataList, filename) {
                try {
                    var data = karate.read('classpath:CA/' + filename);
                } catch(e) {
                    var data = {};
                }
                for(var i in dataList) {
                    data[dataList[i]] = isDeleteOutputOnly;
                }
                karate.write(karate.pretty(data), 'test-classes/CA/' + filename);
            }
        """
    # # ---- SETUP Global Variables ----
    * Pause(WaitTime)
    * def ExpectedCountry = getExpectedCountry(DATAFILENAME) 
    * call read('classpath:CA/Features/ReUsable/Steps/GlobalVariables.feature')
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
    * if(DownloadXML == true) {karate.call(ReUsableFeaturesPath + '/Steps/DownloadS3Assets.feature', DownloadXMLfromS3Params)}
    # ---- Modify XML for Unique Trailer IDs: epochTime + originalTrailerID ----
    # DO NOT EXECUTE IF ONLY DOING PHASE1!
    * karate.log('-- SETUP: Modify XML to make it unique --')
    * xml XMLNodes = ModifyXML == true?karate.call(ReUsableFeaturesPath + '/StepDefs/XML.feature@modifyXML', {TestXMLPath: TestXMLPath}).result:'<xml></xml>'
    * if(ModifyXML == true) {karate.write(karate.prettyXml(XMLNodes), TestXMLPath.replace('classpath:target/', ''))}
    * def TrailerIDs = ModifyXML == true?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].id'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.id'):''
    * def TrailerNames = ModifyXML == true?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.*.outputFilename').length == 0?karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.outputFilename'):karate.jsonPath(XMLNodes, '$.trailers._.trailer[*].*.*.outputFilename'):''
    * karate.log('-- SETUP: successfully executed --')
