Feature: Iconik functionalities

Background:
  * def thisFile = 'classpath:CA/Features/ReUsable/Methods/Iconik.feature'

@GetRenditionHTTPInfo
Scenario: Get Rendition URL from custom action list via Iconik API
  * def getRenditionHTTPInfo =
    """
      function (resp) {
        var url = '';
        var respObjects = resp['objects'];
        for(var index in respObjects) {
          var actionSet = respObjects[index];
          if(actionSet['id'] == Iconik_TriggerRenditionCustomActionID) {
            url = actionSet['url'];
            break;
          }
        }
        var finalResp = {
          URL: url
        }
        return finalResp
      }
    """
  Given url URL
  And header Auth-Token = IconikAuthToken
  And header App-ID = IconikAppID
  When method get
  Then def result = call getRenditionHTTPInfo response

@GetAppTokenData
Scenario: Get Authentication Token from Application Token via Iconik API
  * def getAppTokenData =
    """
      function (resp) {
        var finalResp = {
          IconikAuthToken: resp['token'],
          IconikAppID: resp['app_id']
        }
        return finalResp
      }
    """
  * def GetAppTokenDataPayload =
    """
      {
        app_name: #(IconikAppTokenName),
        email: #(IconikAdminEmail),
        password: #(IconikAdminPassword)
      }
    """
  Given url IconikGetAppTokenAPIUrl
  And header Content-Type = 'application/json'
  And request GetAppTokenDataPayload
  When method post
  And def result = call getAppTokenData response
  Then assert result.error == null

@TriggerRendition
Scenario: Rendition
  Given url URL
  When header Auth-Token = IconikAuthToken
  And header App-ID = IconikAppID
  And request RenditionRequestPayload
  And method post
  Then def matchResult = karate.match('response contains RenditionExpectedResponse')
  And def result =
    """
      {
        "response": #(response),
        "message": #(matchResult.message),
        "pass": #(matchResult.pass)
      }
    """

@RenameAsset
Scenario: Rename Asset
  Given url URL
  When header Auth-Token = IconikAuthToken
  And header App-ID = IconikAppID
  And request UpdateAssetNamePayload
  And method put
  Then status 200

@UpdateAssetMetadata
Scenario: Update AssetMetadata & validate response
  * url URL
  * header Auth-Token = IconikAuthToken
  * header App-ID = IconikAppID
  * request Query
  * method put
  # * print response
  * def getMatchResult = 
    """
      function() {
        var matchRes = karate.match('response contains ExpectedResponse');
        if(!matchRes['pass']) {
          karate.log('Initial matching failed');
          for(var key in response) {
            var thisRes = '';
            expectedValue = ExpectedResponse[key];
            actualValue = response[key];
            if(key == 'metadata_values') {
              for(var videoUpdatesKey in actualValue) {
                actualVideoField = actualValue[videoUpdatesKey];
                expectedVideoField = expectedValue[videoUpdatesKey];
                thisRes = karate.match('actualVideoField contains expectedVideoField');
                karate.log(key + '[' + videoUpdatesKey + ']: ' + thisRes);
                if(!thisRes['pass']) {
                  break;
                }
              }
            } else {
              thisRes = karate.match('actualValue contains expectedValue');
            }
            karate.log(key + ': ' + thisRes);
            matchRes = thisRes;
            if(!matchRes['pass']) {
              break;
            }
          }
        }
        return matchRes;
      }
    """
  * def result = call getMatchResult
  # * print result

@ExecuteHTTPRequest
Scenario: Execute an HTTP request to Iconik
  Given url thisURL
  And header Auth-Token = IconikAuthToken
  And header App-ID = IconikAppID
  When request thisQuery
  And method thisMethod
  Then assert responseStatus == thisStatus
  * def result = response

@GetAssetData
Scenario: Get Asset Data
  * def GetAssetDataParams = 
    """
      {
        thisURL: #(URL),
        thisQuery: #(Query),
        thisMethod: get,
        thisStatus: 200
      }
    """
  * def resp = call read(thisFile + '@ExecuteHTTPRequest') GetAssetDataParams
  * def result = resp.result

@SearchForAssets
Scenario: Search for Assets
  * def SearchForAssetParams = 
    """
      {
        thisURL: #(URL),
        thisQuery: #(Query),
        thisMethod: post,
        thisStatus: 200
      }
    """
  * def resp = call read(thisFile + '@ExecuteHTTPRequest') SearchForAssetParams
  * def result = resp.result

@DeleteAsset
Scenario: Delete Asset
  * def DeleteAssetParams = 
    """
      {
        thisURL: #(URL),
        thisQuery: #(Query),
        thisMethod: post,
        thisStatus: 204
      }
    """
  * def resp = call read(thisFile + '@ExecuteHTTPRequest') DeleteAssetParams
  * def result = resp.result

@GetAssetACL
Scenario: Get Asset User Group ACL
  * def GetAssetACLParams =
    """
      {
        thisURL: #(URL),
        thisQuery: null,
        thisMethod: get,
        thisStatus: 200
      }
    """
  * def resp = call read(thisFile + '@ExecuteHTTPRequest') GetAssetACLParams
  * def result = resp.result

@ValidatePlaceholderExists
Scenario: Check if placeholder exists
  * def GetAssetDataParams =
    """
      {
        URL: #(GetAssetDataURL)
      }
    """
  * def AssetData = call read(thisFile + '@GetAssetData') GetAssetDataParams
  # * print AssetData.result
  * def result = karate.match('AssetData.result contains ExpectedAssetData')
  * print result

@ValidateACLExists
Scenario: Check if ACL exists in an assetId
  * def GetAssetsUserGroupACLParams = 
    """
      {
        URL: #(GetAssetACLURL),
      }
    """
  * def AssetACL = call read(thisFile + '@GetAssetACL') GetAssetsUserGroupACLParams
  * def result = karate.match('AssetACL.result contains ExpectedAssetACL')
  * print result

@ValidateCollectionHeirarchy
Scenario: Validate Collection Heirarchy
  * def execute =
    """
        function(trailerIDList) {
            var result = {
                message: [],
                pass: true
            };
            for(var i in trailerIDList) {
                var trailerId = trailerIDList[i];
                var trailerIdAssetDBrecord = karate.read('classpath:' + ResultsPath + '/' + trailerId + '.json');

                // Build expectedCollectionHeirarchy array
                // Push collection ID to array if it is not null
                var expectedCollectionHeirarchy = [];
                var trailerIDIconikObjectIDs = trailerIdAssetDBrecord.iconikObjectIds;
                karate.log(trailerId + ' iconikObjectIDs: ' + karate.pretty(trailerIDIconikObjectIDs));
                // ORDERED LIST, CANNOT DO DYNAMICALLY
                // FIRST IN, LAST OUT
                var expectedHeirarchyCollectionKeys = [
                  'showTitleCollectionId',
                  'seasonCollectionId',
                  'episodeCollectionId',
                  'mediaAssetCollectionId',
                  'outputCollectionId'
                ]

                var actualTrailerIconikObjectIDkeys = karate.jsonPath(trailerIDIconikObjectIDs, '$.*~');

                for(var key in expectedHeirarchyCollectionKeys) {
                  if(actualTrailerIconikObjectIDkeys.contains(expectedHeirarchyCollectionKeys.key)) {
                    expectedCollectionHeirarchy.push(trailerIDIconikObjectIDs.key);
                  }
                }               
                
                for(var j = expectedCollectionHeirarchy.length - 1; j >= 0; j--) {
                    var collectionID = expectedCollectionHeirarchy[j];
                    var thisURL = IconikAssetDataAPIUrl + '/collections/' + collectionID;
                    var getAssetDataParams = {
                        URL: thisURL,
                        thisQuery: ''
                    }
                    var assetData = karate.call(ReUsableFeaturesPath + '/Methods/Iconik.feature@GetAssetData', getAssetDataParams);
                    var assetDataParentCollections = assetData.result.parents;
                    
                    // API response: parents -> OAP / COUNTRY / FILM -OR- SHOW / ...
                    // need to offset first 3 because they are not in assetDB record
                    for(var k = assetDataParentCollections.length - 1; k >= 3; k--) {
                        var actualParentCollectionIndex = k;
                        var actualParentID = assetDataParentCollections[actualParentCollectionIndex];
                        var expectedParentCollectionIndex = j - (assetDataParentCollections.length - k);
                        var expectedParentID = expectedCollectionHeirarchy[expectedParentCollectionIndex];
                        var thisResult = karate.match(expectedParentID, actualParentID);

                        if(!thisResult.pass) {
                            result.pass = false;
                            if(ValidationResult.result.path) {
                                errMsg = ValidationResult.result.message.replace(ValidationResult.result.path);
                            } else {
                                errMsg = ValidationResult.result.message;
                            }
                            result.message.push(trailerId + ': ' + errMsg);
                            break;
                        }
                    }
                    if(!result.pass) {
                        break;
                    }
                }
                if(!result.pass) {
                    break;
                }
            }
            return result;
        }
    """
  * def validateCollectionHeirarchy =
    """
      function(trailerIDList) {
        var thisResult = {};
        for(var i = 0; i < Retries; i++) {
          thisResult = execute(trailerIDList);
          
          if(thisResult.pass) {
            break;
          }
          else {
            karate.log('Try #' + (i+1) + ' of ' + Retries + ': Failed. Sleeping for ' + RetryDuration + ' ms. - ' + karate.pretty(thisResult));
            Pause(RetryDuration);
          }
        }
        return thisResult
      }
    """
  * def result = validateCollectionHeirarchy(trailerIDs)

@ValidatePlaceholders
Scenario: Validate Placeholders
  * def execute =
    """
        function(trailerIDList) {
            var result = {
                message: [],
                pass: true
            };
            for(var i in trailerIDList) {
                var trailerId = trailerIDList[i];
                var trailerIdAssetDBrecord = karate.read('classpath:' + ResultsPath + '/' + trailerId + '.json');
                
                // Build Assets array
                // Push asset ID to array if it is not null
                var expectedIconikPlaceholderAssets = [];
                var trailerIDIconikObjectIDs = trailerIdAssetDBrecord.iconikObjectIds;
                var trailerIDassociatedFiles = trailerIdAssetDBrecord.associatedFiles;

                for(var j in trailerIDIconikObjectIDs) {
                    if(j.contains('AssetId') && trailerIDIconikObjectIDs[j] != null) {
                        var thisAssetID = trailerIDIconikObjectIDs[j];
                        var thisAssetName = trailerIDassociatedFiles[j.replace('AssetId', 'FileName')] == null?trailerIDassociatedFiles[j.replace('AssetId', 'Filename')]:trailerIDassociatedFiles[j.replace('AssetId', 'FileName')];
                        var thisAssetType = j.replace('AssetId', '');
                        var thisAssetSet = {
                            assetType: thisAssetType,
                            assetId: thisAssetID,
                            assetName: thisAssetName
                        }
                        expectedIconikPlaceholderAssets.push(thisAssetSet);
                    }
                }                  
                
                for(var j in expectedIconikPlaceholderAssets) {
                    var expectedAssetID = expectedIconikPlaceholderAssets[j]['assetId'];
                    var expectedAssetName = expectedIconikPlaceholderAssets[j]['assetName'];
                    var thisURL = IconikAssetDataAPIUrl + '/assets/' + expectedAssetID;
                    var ExpectedPlaceholderAssetData = read(TestDataPath + '/Iconik/ExpectedPlaceholderAssetData.json')
                    ExpectedPlaceholderAssetData.title = expectedAssetName;
                    ExpectedPlaceholderAssetData.external_id = expectedAssetName;
                    ExpectedPlaceholderAssetData.id = expectedAssetID;
                    var ValidatePlaceholderExistsParams = {
                        GetAssetDataURL: thisURL,
                        ExpectedAssetData: ExpectedPlaceholderAssetData
                    }
                    var thisResult = karate.call(ReUsableFeaturesPath + '/Methods/Iconik.feature@ValidatePlaceholderExists', ValidatePlaceholderExistsParams);
                    if(!thisResult.result.pass) {
                        if(ValidationResult.result.path) {
                            errMsg = ValidationResult.result.message.replace(ValidationResult.result.path);
                        } else {
                            errMsg = ValidationResult.result.message;
                        }
                        result.message.push(trailerId + ': ' + errMsg);
                        result.pass = false;
                    }
                }
            }
            return result;
        }
    """
  * def validatePlaceholders =
    """
      function(trailerIDList) {
        var thisResult = {};
        for(var i = 0; i < Retries; i++) {
          thisResult = execute(trailerIDList);
          
          if(thisResult.pass) {
            break;
          }
          else {
            karate.log('Try #' + (i+1) + ' of ' + Retries + ': Failed. Sleeping for ' + RetryDuration + ' ms. - ' + karate.pretty(thisResult));
            Pause(RetryDuration);
          }
        }
        return thisResult;
      }
    """
  * def result = validatePlaceholders(trailerIDs)