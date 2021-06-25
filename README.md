# CA OAP Adapter Test Automation

This project is intended to test CA OAP using the [Karate Framework](https://intuit.github.io/karate/). 

# Prerequisites
1. Java Development Kit
2. Maven

# Running The Tests Locally

## IMPORTANT NOTE: 
* Make sure that you have updated your aws credentials
    * `gimme-aws-creds`
* Set Iconik admin user and password as environment variable
    * `export IconikAdminEmail="xxxx@xxx.com"`
    * `export IconikAdminPassword="xxxxxxxx"`
* Set parallel threads (NOTE: Defaults to 4 parallel threads if not set) 
  * `export parallelThreads=10`

* RUN TESTS

  * `./bin/run-test [-t|-tag <Regression|CustomTags>] [-e|-env <dev|qa|preprod|prod>]`

# File Structure

All test code are located inside `src/test/java`

## Config
    Contains all environment-related configurations using a JSON file.

## Features
    Contains all code which runs the tests

##### Features/ReUsable/Methods
    Contains all reusable Methods which directly utilize JAVA code or any method in its simplest form
##### Features/ReUsable/Scenarios
    Contains all reusable Scenarios which is collective structure of methods to achieve a series of steps
##### Features/Tests
    Contains all Scenario Outlines which is a collective struture of Scenarios to achieve an series of end-to-end steps

## TestData
    Contains all test segragated per environment

##### TestData/OAPAssetDB
    Contains all Expected AssetDB records per trailer ID stored using a JSON file

##### TestData/OAPDataSource
    Contains all Expeceted Datasource records per promo XML file stored using a JSON file

## Utils
    Contains all custom JAVA code used for the test automation
