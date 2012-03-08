Feature: Shell

  In order to explore the CM1 API
  As a potential client
  I want to make simple calculations from an interactive console
  
  Scenario: Running the shell
    When I run `carbon` interactively
    And I type "exit"
    Then the output should contain:
      """
      carbon->
      """

  Scenario: Setting a key
    When I run `carbon` interactively
    And I type "key 'abc'"
    And I type "exit"
    Then the output should contain:
      """
      Using key abc
      """

  Scenario: Seeing a list of emitters
    When I run `carbon` interactively
    And I type "help"
    And I type "exit"
    Then the output should contain:
      """
      Computation
      """

  Scenario: Getting a calculation
    When I run `carbon` interactively
    And I type "computation"
    And I type "done"
    And I type "exit"
    Then the output should contain:
      """
      kg CO2e
      """

  Scenario: Seeing a list of characteristics
    When I run `carbon` interactively
    And I type "computation"
    And I type "help"
    And I type "done"
    And I type "exit"
    Then the output should contain:
      """
      duration
      """

  Scenario: Setting a characteristic
    When I run `carbon` interactively
    And I type "computation"
    And I type "duration 10"
    And I type "done"
    And I type "exit"
    Then the output should contain:
      """
      kg CO2e
      """

  Scenario: Retrieving the default timeframe
    When I run `carbon` interactively
    And I type "computation"
    And I type "timeframe"
    And I type "done"
    And I type "exit"
    Then the output should contain:
      """
      (defaults to current year)
      """

  Scenario: Setting the timeframe
    When I run `carbon` interactively
    And I type "computation"
    And I type "timeframe '2009'"
    And I type "timeframe"
    And I type "done"
    And I type "exit"
    Then the output should contain:
      """
      => 2009
      """

  Scenario: Getting the current emission
    When I run `carbon` interactively
    And I type "computation"
    And I type "emission"
    And I type "done"
    And I type "exit"
    Then the output should contain:
      """
      kg CO2e
      """

  Scenario: Using a different unit
    When I run `carbon` interactively
    And I type "computation"
    And I type "lbs"
    And I type "done"
    And I type "exit"
    Then the output should contain:
      """
      lbs CO2e
      """

  Scenario: Retrieving default characteristics
    When I run `carbon` interactively
    And I type "computation"
    And I type "characteristics"
    And I type "done"
    And I type "exit"
    Then the output should contain:
      """
      (none)
      """

  Scenario: Retrieving set characteristics
    When I run `carbon` interactively
    And I type "computation"
    And I type "duration 10; characteristics; done"
    And I type "exit"
    Then the output should contain:
      """
      duration: 10
      """

  Scenario: Retrieving default methodology
    When I run `carbon` interactively
    And I type "computation"
    And I type "methodology"
    And I type "done"
    And I type "exit"
    Then the output should contain:
      """
      duration: default
      """

  Scenario: Retrieving customized methodology
    When I run `carbon` interactively
    And I type "computation"
    And I type "duration 10; methodology; done"
    And I type "exit"
    Then the output should not contain:
      """
      duration:
      """

  Scenario: Retrieving reports
    When I run `carbon` interactively
    And I type "computation"
    And I type "reports"
    And I type "done"
    And I type "exit"
    Then the output should contain:
      """
      power_usage_effectiveness: 1.5
      """

  Scenario: Retrieving methodology URL
    When I run `carbon` interactively
    And I type "computation"
    And I type "duration 10"
    And I type "url"
    And I type "done"
    And I type "exit"
    Then the output should contain:
      """
      http://impact.brighterplanet.com/computations?duration=10
      """

  Scenario: Retrieving stored emitter
    When I run `carbon` interactively
    And I type "computation"
    And I type "duration 10; done"
    And I type "computation 0; characteristics; done"
    And I type "exit"
    Then the output should not contain:
      """
      duration: 10
      """


