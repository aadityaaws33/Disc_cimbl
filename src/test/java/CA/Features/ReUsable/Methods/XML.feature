Feature: XML-related Methods

@modifyXMLTrailerIDs
Scenario:
* def TestXMLData = read(TestXMLPath)
* def modifyTrailerIDs =
    """
        function(TestXMLData) {
            for(var index in TestXMLData['trailers']['_']['trailer']) {
                TestXMLData['trailers']['_']['trailer'][index]['@']['id'] = RandomString.result + TestXMLData['trailers']['_']['trailer'][index]['@']['id'];
                // karate.log(TestXMLData['trailers']['_']['trailer'][index]['@']['id'].replace(RandomString.result, '')); 
            }
            return TestXMLData;
        }
    """
* def result = modifyTrailerIDs(TestXMLData)