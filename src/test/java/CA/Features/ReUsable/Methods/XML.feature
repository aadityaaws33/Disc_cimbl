Feature: XML-related Methods

Background:
    * def thisFile = ReUsableFeaturesPath + '/Methods/XML.feature'
@modifyXML
Scenario: XML modifications depending on Wochit Stages
    * def result = karate.call(thisFile + '@modifyXMLTrailers', {TestXMLPath: TestXMLPath, WochitStage: WochitStage}).result


@modifyXMLTrailers
Scenario:
    * def TestXMLData = read(TestXMLPath)
    * def modifyTrailers =
        """
            function(TestXMLData, WochitStage) {
                for(var index in TestXMLData['trailers']['_']['trailer']) {
                    if(WochitStage == 'afterProcessing') {
                        TestXMLData['trailers']['_']['trailer'][index]['@']['id'] = TestXMLData['trailers']['_']['trailer'][index]['@']['id'] + '01';
                    }
                    TestXMLData['trailers']['_']['trailer'][index]['_']['associatedFiles']['outputFilename'] = RandomString.result + '_' + WochitStage + '_' + TestXMLData['trailers']['_']['trailer'][index]['_']['associatedFiles']['outputFilename'];
                    TestXMLData['trailers']['_']['trailer'][index]['@']['id'] = RandomString.result + TestXMLData['trailers']['_']['trailer'][index]['@']['id'];
                    TestXMLData['trailers']['_']['trailer'][index]['_']['showTitle'] = TestXMLData['trailers']['_']['trailer'][index]['_']['showTitle'] + ' ' + WochitStage;
                     if(TestXMLData['trailers']['_']['trailer'][index]['_']['associatedFiles']['sponsorTail'] != null) {
                         TestXMLData['trailers']['_']['trailer'][index]['_']['associatedFiles']['sponsorTail'] = WochitStage + '_' + TestXMLData['trailers']['_']['trailer'][index]['_']['associatedFiles']['sponsorTail']
                     }
                    // karate.log(TestXMLData['trailers']['_']['trailer'][index]['@']['id'].replace(RandomString.result, '')); 
                }
                return TestXMLData;
            }
        """
    * def result = modifyTrailers(TestXMLData, WochitStage)