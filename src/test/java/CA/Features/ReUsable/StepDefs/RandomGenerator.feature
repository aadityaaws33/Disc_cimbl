Feature: Random Generator

Background:
    

@GenerateRandomString
Scenario: Generate Random String
    * def Random_String_Generator = 
        """
            function(){ 
                return java.lang.System.currentTimeMillis() 
            }
        """
    * def result = Random_String_Generator()