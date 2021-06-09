Feature: Common Background

Scenario: Load common background
    # ---- Paths ----
    * def ReUsableFeaturesPath = 'classpath:CA/Features/ReUsable'
    * def RandomString = callonce read(ReUsableFeaturesPath + '/Methods/RandomGenerator.feature@GenerateRandomString')
    * print RandomString
    * print "Successfully loaded comon background"