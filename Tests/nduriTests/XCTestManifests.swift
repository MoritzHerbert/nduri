import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [testCase(nduriTests.allTests)]
    }
#endif
