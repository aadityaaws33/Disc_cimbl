@Demo
Feature: Demo Feature

Background:
    * def TCName = 'DemoTC'
    * callonce read('classpath:CA/Features/ReUsable/Scenarios/Background.feature')

Scenario: Demo Scenario
    Given url 'https://www.google.com'
    When method get
    Then status 200