Feature: Common ReUsable/Methods functions

@GetDateWithOffset
# Creates a date string in YYYY-MM-DD format
# Parameters: 
# {
#   offset: <# of days>
# }
Scenario: Get Date in YYYY-MM-DD format with specified offset
  * def getDateWithOffset =
    """
      function(delta) {
        var todaysDate = new Date();
        var yyyy = todaysDate.getUTCFullYear().toString();
        var mm = (todaysDate.getUTCMonth() + 1).toString();
        var dd  = (todaysDate.getUTCDate() + delta).toString();

        var mmChars = mm.split('');
        var ddChars = dd.split('');

        var result = yyyy + '-' + (mmChars[1]?mm:"0"+mmChars[0]) + '-' + (ddChars[1]?dd:"0"+ddChars[0]);

        return result;
      }
    """
  * def result = getDateWithOffset(offset)
  * print result

@CreateDateList
# Creates a list of date strings in YYYY-MM-DD format from Today backwards til <offset>
# Parameters: 
# {
#   offset: <# of days>
# }
Scenario: Create Date in YYYY-MM-DD format with specified offset
  * def createDateList =
    """
      function(offset) {
        var dateList = [];
        for(var i = 0; i > offset; i--) {
          var thisDate = karate.call(ResuableMethodsPath + '/Date.feature@GetDateWithOffset', { offset: i})['result'];
          dateList.push(thisDate);
        }
        return dateList
      }
    """
  * def result = createDateList(offset)
  * print result