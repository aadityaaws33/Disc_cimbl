Feature: Wochit Rendition DB Validation functions

Scenario: Validate Wochit Rendition DB Records
    * def getWochitRenditionReferenceIDs =
        """
            function(TrailerIDList) {
                var wochitRenditionReferenceIDs = [];
                for(var i in TrailerIDList) {
                    var trailerID = TrailerIDList[i];
                    var getItemsViaQueryParams = {
                        Param_TableName: OAPAssetDBTableName,
                        Param_QueryInfoList: [
                            {
                                infoName: 'trailerId',
                                infoValue: trailerID,
                                infoComparator: '=',
                                infoType: 'key'
                            }
                        ],
                        Param_GlobalSecondaryIndex: OAPAssetDBTableGSI,
                        AWSRegion: AWSRegion,
                        Retries: 5,
                        RetryDuration: 10000
                    }
                    // karate.log(getItemsViaQueryParams);
                    var getItemsViaQueryResult = karate.call(ReUsableFeaturesPath + '/StepDefs/DynamoDB.feature@GetItemsViaQuery', getItemsViaQueryParams).result;
                    // karate.log(getItemsViaQueryResult);
                    try {
                        var thisRefId = trailerID + ":" + getItemsViaQueryResult[0].wochitRenditionReferenceID;
                        wochitRenditionReferenceIDs.push(thisRefId);
                        Pause(500);
                    } catch(e) {
                        var errMsg = 'Failed to get wochitRenditionReferenceID for ' + trailerID + ': ' + e;
                        karate.log(trailerID + ': ' + errMsg);
                        karate.log(trailerID + ': pushing null value');
                        var thisRefId = trailerID + ":null";
                        wochitRenditionReferenceIDs.push(thisRefId);
                        continue;
                    }
                }
                return wochitRenditionReferenceIDs
            }
        """
    * def getExpectedIntroType =
        """
            function(trailerID, thisExpectedWochitRenditionRecord, thisXMLNodeSets) {
                var thisSegmentEndTimes = karate.jsonPath(thisExpectedWochitRenditionRecord, '$.videoUpdates.timelineItems[*].segmentEndTime');
                thisTrailerDuration = 0
                for(var i in thisSegmentEndTimes){
                    if(parseInt(thisSegmentEndTimes[i]) > thisTrailerDuration) {
                        thisTrailerDuration = parseInt(thisSegmentEndTimes[i]);
                    }
                }
                var thisHasBranding = false;
                if(thisXMLNodeSets[trailerID].branding == 'original') {
                    thisHasBranding = true;
                }
               
                var thisIntro = '';
                if(thisTrailerDuration <= 15) {
                    var thisIntro = 'No Intro'
                } else {
                    if(thisHasBranding == true) {
                        thisIntro = 'Originals Over VT';
                    } else {
                        thisIntro = 'Standard Over VT';
                    }
                }
                return thisIntro
            }
        """
    * def getXMLNodeSets =
        """
            function(XMLNodesInfo) {
                // karate.log('XMLNodes: ' + XMLNodesInfo);
                var XMLNodeSets = {};
                var thisXMLNodes = karate.jsonPath(XMLNodesInfo, '$.*.*.*.*');
                // karate.log('THISXMLNODES: ' + thisXMLNodes);
                var thisTrailerIDs = karate.jsonPath(thisXMLNodes, '$.*.*.id');
                // karate.log('THISTRAILERIDS: ' + thisTrailerIDs);
                for(var i in thisTrailerIDs) {
                    for(var j in thisXMLNodes) {
                        if(thisXMLNodes[j]['@']['id'] == thisTrailerIDs[i]) {
                            XMLNodeSets[thisTrailerIDs[i]] = thisXMLNodes[j]['_'];
                            XMLNodeSets[thisTrailerIDs[i]].countryCode = XMLNodesInfo.trailers['@'].countryCode;
                        }
                    }
                }
                // karate.log('XMLNODESETS: ' + karate.pretty(XMLNodeSets));
                return XMLNodeSets
            }
        """
    * def getExpectedTitle = 
        """
            function(thisXMLShowTitle) {
                var thisExpectedTitle = thisXMLShowTitle;
                if(thisXMLShowTitle.contains('\n')) {
                    thisExpectedTitle = thisXMLShowTitle;
                }
                else if(thisXMLShowTitle.contains('-')) {
                    thisExpectedTitle = thisXMLShowTitle.replace('-', '\\n-');
                }
                else if(thisXMLShowTitle.length > 18) {
                    var finalTitle = '';
                    var words = thisXMLShowTitle.split(' ');

                    for(var i in words) {
                        var separator = '';
                        if(i > 0) {
                            separator = ' ';
                            if((finalTitle + words[i]).length >= 18 && !finalTitle.contains('\\n')) {
                                separator = '\\n';
                            }
                        }
                        finalTitle += separator + words[i];
                    }

                    thisExpectedTitle = finalTitle;
                }
                return thisExpectedTitle;
            }
        """
    * def getExpectedTitleCardType =
        """
            function(thisLinkedFields, thisLinkedFieldsKeys) {
                var KeyArtIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.TitleCard.KeyArt');
                var TitleArtIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.TitleCard.TitleArt');
                var KeyArtValue = thisLinkedFields[KeyArtIndex].value;
                var TitleArtValue = thisLinkedFields[TitleArtIndex].value;
                var thisExpectedTitleCardType = 'Generic Text On Background';
                if(KeyArtValue != " " && TitleArtValue != " ") {
                    thisExpectedTitleCardType = 'Title Art Over Key Art';
                } 
                else if(KeyArtValue != " " && TitleArtValue == " ") {
                    thisExpectedTitleCardType = 'Key Art Only';
                }
                else if(KeyArtValue == " " && TitleArtValue != " ") {
                    thisExpectedTitleCardType = 'Title Art On Background';
                }

                return thisExpectedTitleCardType
            }
        """
    * def getExpectedOriginalLine =
        """
            function(thisExpectedTitleCardType, thisTrailerXMLInfo) {
                var thisHasBranding = true;
                if(thisTrailerXMLInfo.branding == '') {
                    thisHasBranding = false
                }
                var thisExpectedOriginalLine = 'off';
                var OriginalLineCardTypes = ['Title Art Over Key Art', 'Title Art On Background', 'Generic Text On Background'];
                for(var i in OriginalLineCardTypes) {
                    if(OriginalLineCardTypes[i] == thisExpectedTitleCardType) {
                        if(thisHasBranding == true) {
                            thisExpectedOriginalLine = 'on'
                        }
                        break;
                    }
                }
                return thisExpectedOriginalLine
            }
        """
    * def getExpectedBackgroundColour =
        """
            function(thisTrailerXMLInfo) {
                var colourSet = {
                   '1': 'DARK BLUE',
                   '2': 'GREEN',
                   '3': 'TURQUOISE',
                   '4': 'RED',
                   '5': 'PURPLE',
                   '6': 'YELLOW',
                   '7': 'BLUE',
                   '8': 'GREY'
                }
                var thisXMLColourScheme = thisTrailerXMLInfo.colourScheme;
                var thisExpectedBackgroundColour = colourSet[thisXMLColourScheme];
                if(!thisXMLColourScheme) {
                    thisXMLColourScheme = 1;
                    thisExpectedBackgroundColour = colourSet[thisXMLColourScheme];
                    karate.log('No colourScheme from XML detected. Defaulting to ' + thisXMLColourScheme + ' colour: ' + thisExpectedBackgroundColour);
                }
                else {
                    karate.log('colourScheme from XML detected: ' + thisXMLColourScheme + ' colour: ' + thisExpectedBackgroundColour);
                }
                
                return thisExpectedBackgroundColour
            }
        """
    * def getExpectedGenreTrainText =
        """
            function(thisTrailerXMLInfo) {
                var genreTrainTexts = {
                    'FI': 'Dokumentit + Urheilu + Reality + Rikos + Moottorit',
                    'NO': 'Humor + Reality + Dokumentarer + Sport + Krim',
                    'SE': 'Dokumentärer + Reality + Sport + Humor + Crime',
                    'DK': 'Dokumentarer + Serier + Sport + Reality + Krimi'
                }
                var thisExpectedGenreTrainText = genreTrainTexts[thisTrailerXMLInfo.countryCode];

                return thisExpectedGenreTrainText
            }
        """
    * def getExpectedLegalText =
        """
            function(thisTrailerXMLInfo) {
                var thisExpectedLegalText = ' ';
                if(thisTrailerXMLInfo.disclaimer != null) {
                    thisExpectedLegalText = thisTrailerXMLInfo.disclaimer;
                }

                return thisExpectedLegalText
            }
        """
    * def getExpectedCTAText =
        """
            function(trailerID) {
                
                // var trailerAssetDBRecord = karate.read('classpath:' + ResultsPath + '/OAPAssetDB/' + trailerID + '.json');
                var getItemsViaQueryParams = {
                    Param_TableName: OAPAssetDBTableName,
                    Param_QueryInfoList: [
                        {
                            infoName: 'trailerId',
                            infoValue: trailerID,
                            infoComparator: '=',
                            infoType: 'key'           
                        }
                    ],
                    Param_GlobalSecondaryIndex: ''
                }
                var trailerAssetDBRecord = karate.call(ReUsableFeaturesPath + '/StepDefs/DynamoDB.feature@GetItemsViaQuery', getItemsViaQueryParams).result[0];
                var trailerXMLData = trailerAssetDBRecord.xmlMetadata.data;
                var thisExpectedCTAText = trailerXMLData.dPlusCta;
                
                if( trailerXMLData.dPlusCta == null && 
                    trailerXMLData.brand != null && 
                    trailerXMLData.tag != null) {
                        thisExpectedCTAText = trailerXMLData.brand + ' ' + trailerXMLData.tag;
                    }
                else if (trailerXMLData.tag != null && trailerXMLData.dPlusCta == null) {
                    thisExpectedCTAText = trailerXMLData.tag;
                }
                // karate.log('EXPECTED CTA : ' + karate.pretty(trailerXMLData) + ' ' + trailerID + ' ' + thisExpectedCTAText);
                return thisExpectedCTAText
            }
        """
    * def getExpectedWochitRenditionRecord =
        """
            function(trailerID, XMLNodesInfo) {
                var thisTrailerID = trailerID.split(RandomString.result)[1];
                var thisExpectedWochitRenditionRecord = karate.read(ResourcesPath + '/WochitRendition/' + TargetEnv + '/' + thisTrailerID + '.json');
                
                var thisLinkedFields = karate.jsonPath(thisExpectedWochitRenditionRecord, '$.videoUpdates.linkedFields[*]');
                var thisLinkedFieldsKeys = karate.jsonPath(thisLinkedFields, '$.*.key');
                var thisXMLNodeSets = getXMLNodeSets(XMLNodesInfo);
            
                // DPLUS TEMPLATES (PHASE 2)
                if(thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.TitleCard.Title') > -1) {
                    // TEMPLATE ID
                    templateIDs = {
                        'dev': '6184ee7bd10e3274f80612e6', 
                        'qa': '6184ee7bd10e3274f80612e6', 
                        'prod': '619f496d29f511256af7109f'
                    }
                    thisExpectedWochitRenditionRecord.templateId = templateIDs[TargetEnv];

                    // INTRO TYPE
                    var IntroTypeIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.Intro.IntroType');
                    var thisExpectedIntroType = getExpectedIntroType(trailerID, thisExpectedWochitRenditionRecord,thisXMLNodeSets);
                    thisLinkedFields[IntroTypeIndex].value = thisExpectedIntroType;
                    
                    // OUTRO TYPE
                    var CTATextIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.Outro.CTAText');
                    var thisExpectedOutroType = 'SHo No CTA';
                    if(thisLinkedFields[CTATextIndex].value) {
                        thisExpectedOutroType = 'SHo Standard';
                    }
                    var OutroTypeIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.Outro.OutroType');
                    thisLinkedFields[OutroTypeIndex].value = thisExpectedOutroType;

                    // TITLE CARD TYPE
                    var thisExpectedTitleCardType = getExpectedTitleCardType(thisLinkedFields, thisLinkedFieldsKeys);
                    var TitleCardTypeIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.TitleCard.TitleCardType');
                    thisLinkedFields[TitleCardTypeIndex].value = thisExpectedTitleCardType;

                    // TITLE
                    var TitleIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.TitleCard.Title');
                    if(thisExpectedTitleCardType == 'Generic Text On Background') {
                        var thisXMLShowTitle = thisXMLNodeSets[trailerID].showTitle;
                        var thisExpectedTitle = getExpectedTitle(thisXMLShowTitle);
                        var TitleIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.TitleCard.Title');
                        thisLinkedFields[TitleIndex].value = thisExpectedTitle;
                    }

                    // ORIGINAL LINE
                    var OriginalLineIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.TitleCard.OriginalLine');
                    var thisExpectedOriginalLine = getExpectedOriginalLine(thisExpectedTitleCardType, thisXMLNodeSets[trailerID]);
                    thisLinkedFields[OriginalLineIndex].value = thisExpectedOriginalLine;

                    // BACKGROUND COLOR
                    var BackgroundColourIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.Outro.BackgroundColour');
                    var thisExpectedBackgroundColour = getExpectedBackgroundColour(thisXMLNodeSets[trailerID]);
                    thisLinkedFields[BackgroundColourIndex].value = thisExpectedBackgroundColour;

                    // GENRE TRAIN TEXT
                    var GenreTrainTextIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.Outro.GenreTrainText');
                    var thisExpectedGenreTrainText = getExpectedGenreTrainText(thisXMLNodeSets[trailerID]);
                    thisLinkedFields[GenreTrainTextIndex].value = thisExpectedGenreTrainText;

                    // LEGAL TEXT
                    var LegalTextIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.Outro.LegalText');
                    var thisExpectedLegalText = getExpectedLegalText(thisXMLNodeSets[trailerID]);
                    thisLinkedFields[LegalTextIndex].value = thisExpectedLegalText;

                    // CTA TEXT
                    var CTATextIndex = thisLinkedFieldsKeys.indexOf('Dplus.OAP.Video.Outro.CTAText');
                    var thisExpectedCTAText = getExpectedCTAText(trailerID);
                    thisLinkedFields[CTATextIndex].value = thisExpectedCTAText;
                }
                // COMBI TEMPLATES (PHASE 1)
                else {
                    // TEMPLATE ID
                    var countryCode = thisXMLNodeSets[trailerID].countryCode;
                    var promotedChannel = thisXMLNodeSets[trailerID].promotedChannel
                    var templateIDs = {
                        'qa': {
                            'FI': {
                                'tv5': '62185c707ae43638498d5e0d',
                                'frii': '621855115f84e62b42aa09ab',
                                'kut': '62185a495f84e62b42aa09ad'
                            },
                            'DK': {
                                'k4': '6218346e5f84e62b42aa099e',
                                'k5': '62183ee77ae43638498d5e01',
                                'k6': '6218430db92b215d724a1bd3',
                                'c9': '621841c2b92b215d724a1bd0'
                            },
                            'NO': {
                                'tvn': '621877f959a90c47b8410874',
                                'fem': '6218742f7ae43638498d5e15',
                                'max': '62187aea7ae43638498d5e18',
                                'vox': '62187ca859a90c47b8410877',
                            },
                            'SE': {
                                'k5': '621886997ae43638498d5e2f',
                                'k9': '6218835e5f84e62b42aa09d2',
                                'k11': '62188921b92b215d724a1bf7'
                            }
                        },
                        'prod': {
                            'FI': {
                                'tv5': '6226d9bc5f84e62b42aa235d',
                                'frii': '6226cc4d8399a14acbe5a303',
                                'kut': '6226da735f84e62b42aa235f'
                            },
                            'DK': {
                                'k4': '6226db708399a14acbe5a327',
                                'k5': '6226dbf98399a14acbe5a329',
                                'k6': '6226dad55f84e62b42aa2361',
                                'c9': '6226db228399a14acbe5a324'
                            },
                            'NO': {
                                'tvn': '6226d97085d03e28bb13d32f',
                                'fem': '6226d9bc5f84e62b42aa235d',
                                'max': '6226d90b7ae43638498d78a0',
                                'vox': '6226d8b485d03e28bb13d32d',
                            },
                            'SE': {
                                'k5': '6226cd2c5f84e62b42aa2355',
                                'k9': '6226ccc37ae43638498d7897',
                                'k11': '6226cba185d03e28bb13d321'
                            }
                        },
                    }
                    templateIDs['dev'] = templateIDs['qa'];
                    thisExpectedWochitRenditionRecord.templateId = templateIDs[TargetEnv][countryCode][promotedChannel];

                    // Disclaimer
                    var DisclaimerIndex = thisLinkedFieldsKeys.indexOf('Combi.OAP.Video.DplusOutro.Disclaimer');
                    var thisExpectedDisclaimer = getExpectedLegalText(thisXMLNodeSets[trailerID]);
                    thisLinkedFields[DisclaimerIndex].value = thisExpectedDisclaimer;
                }

                thisExpectedWochitRenditionRecord.videoUpdates.linkedFields = thisLinkedFields;

                // karate.log('Expected Wochit Rendition Record: ' + thisExpectedWochitRenditionRecord);
                return thisExpectedWochitRenditionRecord
            }
        """

    * def validateWochitRenditionRecords =
        """
            function(referenceIDs, XMLNodesInfo) {
                var results = {
                    message: [],
                    pass: true
                };
                for(var i in referenceIDs) {
                    var referenceID = referenceIDs[i];
                    var trailerID = referenceID.split(':')[0];
                    var referenceID = referenceID.split(':')[1];
                    //karate.log('RANDOMSTRING: ' + RandomString);
                    var expectedResponse = getExpectedWochitRenditionRecord(trailerID, XMLNodesInfo);
                    if(referenceID.contains('null')) {
                        var errMsg = trailerID + ' has a null wochitRenditionReferenceID';
                        karate.log(errMsg);
                        results.message.push(errMsg);
                        results.pass = false;
                        continue;
                    }
                    
                    var validateItemViaQueryParams = {
                        Param_TableName: WochitRenditionTableName,
                        Param_QueryInfoList: [
                            {
                                infoName: 'assetType',
                                infoValue: 'VIDEO',
                                infoComparator: '=',
                                infoType: 'key'
                            },
                            {
                                infoName: 'ID',
                                infoValue: referenceID,
                                infoComparator: '=',
                                infoType: 'filter'
                            }
                        ],
                        Param_GlobalSecondaryIndex: WochitRenditionTableGSI,
                        Param_ExpectedResponse: expectedResponse,
                        AWSRegion: AWSRegion,
                        Retries: 1,
                        RetryDuration: 10000,
                        WriteToFile: true,
                        WritePath: 'test-classes/' + ResultsPath + '/WochitRenditionDB/' + trailerID + '.json',
                        ShortCircuit: {
                            Key: 'renditionStatus',
                            Value: 'FAILED'
                        }
                    }
                    // karate.log(validateItemViaQueryParams);
                    var getItemsViaQueryResult = karate.call(ReUsableFeaturesPath + '/StepDefs/DynamoDB.feature@ValidateItemViaQuery', validateItemViaQueryParams).result;
                    // karate.log(getItemsViaQueryResult)
                    if(!getItemsViaQueryResult.pass) {
                        for(var j in getItemsViaQueryResult.message) {
                            var resultReason = getItemsViaQueryResult.message[j].replace('\\','');
                            
                            results.message.push(trailerID + ': ' + karate.pretty(resultReason));
                        }
                        results.pass = false;
                    }
                    Pause(500);
                }
                return results;
            }
        """
    * def wochitReferenceIDs = getWochitRenditionReferenceIDs(TrailerIDs)
    * def result = validateWochitRenditionRecords(wochitReferenceIDs, XMLNodes)