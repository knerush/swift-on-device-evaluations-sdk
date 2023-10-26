import Foundation

import Nimble
import Quick
import OHHTTPStubs
#if !COCOAPODS
import OHHTTPStubsSwift
#endif
@testable import StatsigPrecomputedEvaluations

class AsyncInitVsUpdateSpec: BaseSpec {
    override class func spec() {
        super.spec()

        describe("Race conditions between initializeAsync and updateUser") {

            it("does not overwrite user values when unawaited response return") {
                TestUtils.clearStorage()
                
                let userA = StatsigUser(userID: "user-a", customIDs: ["workID": "employee-a"])
                let userB = StatsigUser(userID: "user-b", customIDs: ["workID": "employee-b"])

                stub(condition: isHost("api.statsig.com")) { req in
                    if ((req.url?.absoluteString.contains("/initialize") ?? false) == false) {
                        return HTTPStubsResponse(jsonObject: [:], statusCode: 200, headers: nil)
                    }

                    let body = TestUtils.getBody(fromRequest: req)
                    let userId = body[jsonDict: "user"]?["userID"] as? String
                    if (userId == "user-a") {
                        return HTTPStubsResponse(jsonObject: TestUtils.makeInitializeResponse("user_a_value"), statusCode: 200, headers: nil).responseTime(0.1)
                    }

                    if (userId == "user-b") {
                        return HTTPStubsResponse(jsonObject: TestUtils.makeInitializeResponse("user_b_value"), statusCode: 200, headers: nil).responseTime(0.2)
                    }

                    return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: 500))
                }


                var didInitializeUserA = false
                var didInitializeUserB = false

                // Call initialize then immediately call updateUser
                let client = StatsigClient(sdkKey: "client-key", user: userA, options: StatsigOptions(initTimeout: 99999, disableDiagnostics: true)) { errorMessage in
                    didInitializeUserA = true
                }
                client.updateUser(userB) { errorMessage in
                    didInitializeUserB = true
                }

                var value = client
                    .getConfig("a_config")
                    .getValue(forKey: "key", defaultValue: "default")

                expect(didInitializeUserA).to(beFalse())
                expect(value).to(equal("default"))

                // Wait for the first initialize call to return
                expect(didInitializeUserA).toEventually(beTrue())

                value = client
                    .getConfig("a_config")
                    .getValue(forKey: "key", defaultValue: "default")
                expect(didInitializeUserB).to(beFalse())
                // Our current user is user-b, so we should still get default values
                expect(value).to(equal("default"))

                // Wait for the second initialize call to return
                expect(didInitializeUserB).toEventually(beTrue())

                value = client
                    .getConfig("a_config")
                    .getValue(forKey: "key", defaultValue: "default")
                expect(value).to(equal("user_b_value"))


                var updated = false
                client.updateUser(userB) { errorMessage in
                    updated = true
                }

                expect(updated).toEventually(beTrue())
                value = client
                    .getConfig("a_config")
                    .getValue(forKey: "key", defaultValue: "default")
                expect(value).to(equal("user_b_value"))
            }
        }
    }
}
