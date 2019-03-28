import XCTest

@testable import AppTests

XCTMain([
    testCase(AppTests.allTests),
    testCase(AcronymTests.allTests),
    testCase(CategoryTests.allTests),
    testCase(UserTests.allTests)
    ])
