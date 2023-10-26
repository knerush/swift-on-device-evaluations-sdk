import Foundation

import Nimble
import Quick
@testable import StatsigPrecomputedEvaluations

class DeviceEnvironmentSpec: BaseSpec {
    override class func spec() {
        super.spec()
        
        describe("getting the environment info about current device") {
            StatsigUserDefaults.defaults.removeObject(forKey: "com.Statsig.InternalStore.stableIDKey")
            let env1 = DeviceEnvironment().get()
            let env2 = DeviceEnvironment().get()
            let env3 = DeviceEnvironment().get("12345")
            let env4 = DeviceEnvironment().get()

            it("gets the same value across multiple times") {
                for (key, value) in env1 {
                    if key == "sessionID" {
                        expect(value) != env2[key]
                    } else {
                        expect(value) == env2[key]
                    }
                }
                expect(env1.count) == env2.count
            }

            it("has all the fields and non-nil values for required ones") {
                expect(env1.count) == 12
                expect(env1["sessionID"]).toNot(beNil())
                expect(env1["stableID"]).toNot(beNil())
                expect(env1["deviceOS"]).toNot(beNil())
                expect(env1["sdkVersion"]).toNot(beNil())
                expect(env1["sdkType"]).toNot(beNil())
            }

            it("has the same stable ID if no override, otherwise override is used") {
                expect(env1["stableID"]).to(equal(env2["stableID"]))
                expect(env1["stableID"]).toNot(equal(env3["stableID"]))
                expect(env3["stableID"]).to(equal("12345"))
                expect(env3["stableID"]).to(equal(env4["stableID"]))
            }
        }
    }
}
