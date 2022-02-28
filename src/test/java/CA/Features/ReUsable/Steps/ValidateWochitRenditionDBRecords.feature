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
                                'tv5': '60d5a4b2b913ca2c41ca5698',
                                'frii': '60d5a506b913ca2c41ca569e',
                                'kut': '60d5a4dcb913ca2c41ca569a'
                            },
                            'DK': {
                                'k4': '60e7f0093467b05de4c3ac8f',
                                'k5': '60e7f668d05b353d236b04da',
                                'k6': '60e7f77bd05b353d236b04dd',
                                'c9': '60e7f85c4a5954449fe6db7c'
                            },
                            'NO': {
                                'tvn': '60ed0a203fe6da53b1385f9b',
                                'fem': '60ed13dd3fe6da53b1385fa0',
                                'max': '60ed1fce3fe6da53b1385fa8',
                                'vox': '60ed23ceee1e076949304262',
                            },
                            'SE': {
                                'k5': '60e53f5e4a5954449fe6d6ca',
                                'k9': '60e547bb4a5954449fe6d6d2',
                                'k11': '60e680a44a5954449fe6d8fd'
                            }
                        },
                        'prod': {
                            'FI': {
                                'tv5': '60fa2ad004732008a8bb1043',
                                'frii': '60fa2b5704732008a8bb1045',
                                'kut': '60fa2b8e04732008a8bb1047'
                            },
                            'DK': {
                                'k4': '60fe26ea353ea20724abab95',
                                'k5': '60fe27512cc15704dee2fdf3',
                                'k6': '60fe27ac04732008a8bb1365',
                                'c9': '60fe28772cc15704dee2fdf8'
                            },
                            'NO': {
                                'tvn': '60fe2963353ea20724abab9f',
                                'fem': '60fe2b89353ea20724ababa3',
                                'max': '60fe2bea2cc15704dee2fdfa',
                                'vox': '60fe2c4b04732008a8bb136c',
                            },
                            'SE': {
                                'k5': '60fa3e74353ea20724aba862',
                                'k9': '60fa3e372cc15704dee2fab3',
                                'k11': '60fa3dfc2cc15704dee2fab0'
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