Feature: WIP

@SetupCheckIconikAssets
Scenario: Setup: Check Iconik Assets Before Running
    # * var SearchKeywords = ['after*']
    * karate.log('Search for: ' + SearchKeywords)
    * def searchIconikAssets =
        """
            function(SearchKeywords) {
                var results = [];
                
                var filterTerms = [
                    {
                        name: 'status',
                        value: 'ACTIVE'
                    }
                ]
                for(var i in SearchKeywords){
                    var searchQuery = karate.read(resourcesPath + '/Iconik/GETSearchRequest.json');
                    searchQuery.filter.terms = karate.toJson(filterTerms);
                    searchQuery.include_fields = ['id'];
                    searchQuery.query = SearchKeywords[i];
                    var SearchForAssetsParams = {
                        URL: '',
                        Query: searchQuery
                    }
                    
                    karate.log('[Searching] ' + SearchKeywords[i]);
                    var page = 1;
                    while (true) {
                        SearchForAssetsParams.URL = IconikSearchAPIUrl + '&page=' + page;
                        var searchResult = karate.call(ReUsableFeaturesPath + '/StepDefs/Iconik.feature@SearchForAssets', SearchForAssetsParams);
                        var thisPath = '$.objects.*.id';
                        var searchedAssets = karate.jsonPath(searchResult.result, thisPath);
                        for(var j in searchedAssets) {
                            results.push(searchedAssets[j]);
                        }
                        if(page >= searchResult.result.pages) {
                            break
                        } 
                    }
                }
                return results;
            }
        
        """
    * def result = searchIconikAssets(SearchKeywords)
    * karate.log(result)
    