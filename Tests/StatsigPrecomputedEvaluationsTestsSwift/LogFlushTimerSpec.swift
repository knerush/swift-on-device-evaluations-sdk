import Nimble
import OHHTTPStubs
import Quick

#if !COCOAPODS
import OHHTTPStubsSwift
#endif

@testable import StatsigPrecomputedEvaluations

class LogFlushTimerSpec: BaseSpec {
    override class func spec() {
        super.spec()

        let user = StatsigUser(userID: "jkw")

        var requests: [URLRequest] = []
        var logger: SpiedEventLogger!

        describe("LogFlushTimer") {
            beforeEach {
                stub(condition: isPath("/v1/log_event")) { request in
                    requests.append(request)
                    return HTTPStubsResponse(jsonObject: [:], statusCode: 200, headers: nil)
                }

                requests = []

                let network = NetworkService(sdkKey: "client-key", options: StatsigOptions(), store: InternalStore(user))
                logger = SpiedEventLogger(user: user, networkService: network, userDefaults: MockDefaults())
            }

            it("invalidates previous timers") {
                logger.start()
                logger.start()

                expect(logger.timerInstances.count).toEventually(equal(2))
                expect(logger.timerInstances[0].isValid).to(beFalse())
            }

            it("fires timers regardless of starting thread") {
                DispatchQueue.global(qos: .background).async {
                    logger.start(flushInterval: 0.001)
                }

                expect(logger.timesFlushCalled).toEventually(beGreaterThanOrEqualTo(1))
            }
        }
    }
}
