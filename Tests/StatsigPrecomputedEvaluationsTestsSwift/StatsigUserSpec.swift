import Foundation
import Nimble
import Quick
@testable import StatsigPrecomputedEvaluations
import StatsigInternal

class StatsigUserSpec: BaseSpec {
    override class func spec() {
        super.spec()
        
        let validJSONObject: [String: StatsigUserValue] =
            ["company": "Statsig", "YOE": 10.5, "alias": ["abby", "bob", "charlie"]]
        let invalidJSONObject: [String: StatsigUserValue] =
            ["company": "Statsig", "invalid": String(bytes: [0xD8, 0x00] as [UInt8], encoding: String.Encoding.utf16BigEndian)!]

        describe("creating a new StatsigUser") {
            it("is a valid empty user") {
                let validEmptyUser = StatsigUser(userID: "")
                expect(validEmptyUser).toNot(beNil())
                expect(validEmptyUser.userID).to(beNil())
                expect(validEmptyUser.email).to(beNil())
                expect(validEmptyUser.country).to(beNil())
                expect(validEmptyUser.ip).to(beNil())
                expect(validEmptyUser.custom).to(beNil())
                expect(validEmptyUser.deviceEnvironment).toNot(beNil())
                expect(validEmptyUser.customIDs).to(beNil())
            }

            it("is a valid user with ID provided") {
                let validUserWithID = StatsigUser(userID: "12345")
                expect(validUserWithID).toNot(beNil())
                expect(validUserWithID.userID) == "12345"
                expect(validUserWithID.statsigEnvironment) == [:]
                expect(validUserWithID.toDictionary(forLogging: false).count) == 2
            }

            it("is a valid user with custom attribute") {
                let validUserWithCustom = StatsigUser(userID: "12345", custom: validJSONObject)
                expect(validUserWithCustom).toNot(beNil())
                expect(validUserWithCustom.userID) == "12345"

                let customDict = validUserWithCustom.custom
                expect(customDict.values.count) == 3
                expect(customDict.values["company"] as? String) == "Statsig"
                expect(customDict.values["YOE"] as? Double) == 10.5
                expect(customDict.values["alias"] as? [String]) == ["abby", "bob", "charlie"]
            }

            it("drops private attributes for logging") {
                let userWithPrivateAttributes = StatsigUser(userID: "12345", privateAttributes: validJSONObject)
                let user = StatsigUser(userID: "12345")

                let userWithPrivateDict = userWithPrivateAttributes.toDictionary(forLogging: true)
                expect(userWithPrivateDict.count) == user.toDictionary(forLogging: true).count
                expect(userWithPrivateDict["privateAttributes"]).to(beNil())
            }

            it("is a user with invalid custom attribute") {
                let validUserInvalidCustom = StatsigUser(userID: "12345", custom: invalidJSONObject)
                expect(validUserInvalidCustom).toNot(beNil())
                expect(validUserInvalidCustom.userID) == "12345"
                expect(validUserInvalidCustom.custom).to(beNil())
            }

            it("keeps customIDs in the json") {
                let user = StatsigUser(userID: "12345", customIDs: ["company_id": "998877"])
                let json = user.toDictionary(forLogging: false)
                expect(NSDictionary(dictionary: json["customIDs"] as! [String: String])).to(equal(NSDictionary(dictionary: ["company_id": "998877"])))
            }
        }
    }
}
