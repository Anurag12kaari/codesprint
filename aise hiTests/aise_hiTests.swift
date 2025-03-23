import XCTest
@testable import aise_hi

class aise_hiTests: XCTestCase {
    func testUserInitialization() {
        let user = User.defaultUser
        XCTAssertEqual(user.username, "CodeMaster")
        XCTAssertEqual(user.completedProblems, 15)
    }
}
