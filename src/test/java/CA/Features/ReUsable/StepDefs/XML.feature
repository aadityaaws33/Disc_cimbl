Feature: XML-related Methods

Background:
    * def thisFile = ReUsableFeaturesPath + '/StepDefs/XML.feature'
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
                    var thisStage = WochitStage;

                    // Set expected stage
                    var expectedStage = WochitStage;
                    if(WochitStage == 'metadataUpdate' || WochitStage == 'versionTypeUpdate') {
                        expectedStage = 'preWochit';
                    } else if(WochitStage == 'rerender' || WochitStage == 'versionTypeDelete' || WochitStage == 'mediaReversion') {
                        expectedStage = 'postWochit';
                    }

                    // Stage-specific modifications
                    if(WochitStage == 'postWochit' || WochitStage == 'rerender' || WochitStage == 'versionTypeDelete' || WochitStage == 'mediaReversion') {
                        TestXMLData['trailers']['_']['trailer'][index]['@']['id'] = TestXMLData['trailers']['_']['trailer'][index]['@']['id'] + '01';
                    } 
                    if(WochitStage == 'metadataUpdate' || WochitStage == 'rerender') {
                        TestXMLData['trailers']['_']['trailer'][index]['_']['disclaimer'] = WochitStage;
                    } 
                    if(WochitStage == 'versionTypeUpdate' || WochitStage == 'versionTypeDelete') {
                        TestXMLData['trailers']['_']['trailer'][index]['_']['versionType'] = 'TEST';
                    }
                    if(WochitStage == 'mediaReversion') {
                        TestXMLData['trailers']['_']['trailer'][index]['_']['mediaReversion'] = 'true';
                    }


                    // Common modifications
                    TestXMLData['trailers']['_']['trailer'][index]['_']['associatedFiles']['outputFilename'] = RandomString.result + '_' + expectedStage + '_' + TestXMLData['trailers']['_']['trailer'][index]['_']['associatedFiles']['outputFilename'];
                    TestXMLData['trailers']['_']['trailer'][index]['@']['id'] = RandomString.result + TestXMLData['trailers']['_']['trailer'][index]['@']['id'];
                    TestXMLData['trailers']['_']['trailer'][index]['_']['showTitle'] = TestXMLData['trailers']['_']['trailer'][index]['_']['showTitle'] + ' ' + expectedStage;
                     if(TestXMLData['trailers']['_']['trailer'][index]['_']['associatedFiles']['sponsorTail'] != null) {
                         TestXMLData['trailers']['_']['trailer'][index]['_']['associatedFiles']['sponsorTail'] = expectedStage + '_' + TestXMLData['trailers']['_']['trailer'][index]['_']['associatedFiles']['sponsorTail']
                     }
                    // karate.log(TestXMLData['trailers']['_']['trailer'][index]['@']['id'].replace(RandomString.result, '')); 

                    // Environment-specific modifications
                    if(TargetEnv == 'dev' || TargetEnv == 'qa' || TargetEnv == 'prod') {
                        TestXMLData['trailers']['@']['username'] = TestUser;
                    }
                }
                return TestXMLData;
            }
        """
    * def result = modifyTrailers(TestXMLData, WochitStage)