import Foundation

import Nimble
import OHHTTPStubs
import Quick
@testable import StatsigPrecomputedEvaluations

#if !COCOAPODS
import OHHTTPStubsSwift
#endif

class CodableSpec: BaseSpec {
    override class func spec() {
        super.spec()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        describe("Codable") {
            let opts = StatsigOptions(disableDiagnostics: true)
            opts.overrideURL = URL(string: "http://CodableSpec")

            beforeEach {
                _ = TestUtils.startWithResponseAndWait([
                    "feature_gates": [
                        "a_gate".sha256(): [
                            "value": true
                        ]
                    ],
                    "dynamic_configs": [
                        "a_config".sha256(): [
                            "value": ["a_bool": true],
                        ]
                    ],
                    "layer_configs": [
                        "a_layer".sha256(): [
                            "value": ["a_bool": true],
                        ]
                    ],
                    "time": 321,
                    "has_updates": true
                ], options: opts)
            }

            afterEach {
                Statsig.client?.shutdown()
                Statsig.client = nil
            }


            it("encodes/decodes FeatureGate") {
                let gate = Statsig.getFeatureGateWithExposureLoggingDisabled("a_gate")

                let encoded = try! encoder.encode(gate)
                let decoded = try! decoder.decode(FeatureGate.self, from: encoded)

                expect(gate.name).to(equal(decoded.name))
                expect(gate.ruleID).to(equal(decoded.ruleID))
                expect(gate.value).to(equal(decoded.value))
                expect(gate.secondaryExposures).to(equal(decoded.secondaryExposures))

                expect(gate.evaluationDetails.reason).to(equal(decoded.evaluationDetails.reason))
                expect(gate.evaluationDetails.time).to(equal(decoded.evaluationDetails.time))
            }

            it("encodes/decodes DynamicConfig") {
                let config = Statsig.getConfigWithExposureLoggingDisabled("a_config")

                let encoded = try! encoder.encode(config)
                let decoded = try! decoder.decode(DynamicConfig.self, from: encoded)

                expect(config.name).to(equal(decoded.name))
                expect(config.ruleID).to(equal(decoded.ruleID))
                expect(config.secondaryExposures).to(equal(decoded.secondaryExposures))
                expect(config.evaluationDetails.reason).to(equal(decoded.evaluationDetails.reason))
                expect(config.evaluationDetails.time).to(equal(decoded.evaluationDetails.time))
            }

            it("encodes/decodes Layer") {
                let config = Statsig.getLayerWithExposureLoggingDisabled("a_layer")

                let encoded = try! encoder.encode(config)
                let decoded = try! decoder.decode(Layer.self, from: encoded)

                expect(config.name).to(equal(decoded.name))
                expect(config.ruleID).to(equal(decoded.ruleID))
                expect(config.secondaryExposures).to(equal(decoded.secondaryExposures))
                expect(config.evaluationDetails.reason).to(equal(decoded.evaluationDetails.reason))
                expect(config.evaluationDetails.time).to(equal(decoded.evaluationDetails.time))
            }
        }

        describe("Codable - Direct Instantiation") {
            it("encodes/decodes DynamicConfig") {
                [
                    DynamicConfig(
                        configName: "empty_config",
                        evalDetails: EvaluationDetails(reason: .Uninitialized)
                    ),
                    DynamicConfig(
                        configName: "parital_config",
                        configObj: [
                            "name": "partial_config",
                            "value": ["foo":"bar"],
                            "rule_id": "default"
                        ],
                        evalDetails: EvaluationDetails(reason: .Cache)
                    ),
                    DynamicConfig(
                        configName: "full_config",
                        configObj: [
                            "name": "full_config",
                            "value": ["foo":"bar"],
                            "rule_id": "a_rule_id",
                            "group": "default",
                            "group_name": "A Group",
                            "is_device_based": true,
                            "id_type": "userID",
                            "is_experiment_active": true,
                            "is_user_in_experiment": true,
                            "secondary_exposures": [
                                [
                                    "gate": "4XBVXe7WRiQd22ZhNLlqnm",
                                    "gateValue": "false",
                                    "ruleID": "default"
                                ]
                            ]
                        ],
                        evalDetails: EvaluationDetails(reason: .Cache)
                    )
                ].forEach { config in
                    let encoded = try! encoder.encode(config)
                    let decoded = try! decoder.decode(DynamicConfig.self, from: encoded)

                    expect(config.name).to(equal(decoded.name))
                    expect(config.ruleID).to(equal(decoded.ruleID))
                    expect(config.secondaryExposures).to(equal(decoded.secondaryExposures))
                    expect(config.evaluationDetails.reason).to(equal(decoded.evaluationDetails.reason))
                    expect(config.evaluationDetails.time).to(equal(decoded.evaluationDetails.time))
                }
            }

            it("encodes/decodes Layer") {
                [
                    Layer.init(
                        client: nil,
                        name: "empty_layer",
                        evalDetails: EvaluationDetails(reason: .Uninitialized)
                    ),
                    Layer.init(
                        client: nil,
                        name: "partial_layer",
                        configObj: [
                            "name": "partial_config",
                            "value": ["foo":"bar"],
                            "rule_id": "default"
                        ],
                        evalDetails: EvaluationDetails(reason: .Uninitialized)
                    ),
                    Layer.init(
                        client: StatsigClient(sdkKey: "client-key", user: nil, options: nil) { _ in },
                        name: "full_layer",
                        configObj: [
                            "name": "full_layer",
                            "value": ["foo":"bar"],
                            "rule_id": "a_rule_id",
                            "group": "default",
                            "group_name": "A Group",
                            "explicit_parameters": ["foo"],
                            "allocated_experiment_name": "an_experiment",
                            "is_device_based": true,
                            "is_user_in_experiment": true,
                            "is_experiment_active": true,
                            "id_type": "userID",
                            "secondary_exposures": [
                                [
                                    "gate": "4XBVXe7WRiQd22ZhNLlqnm",
                                    "gateValue": "false",
                                    "ruleID": "default"
                                ]
                            ],
                            "undelegated_secondary_exposures": [
                                [
                                    "gate": "4XBVXe7WRiQd22ZhNLlqnm",
                                    "gateValue": "false",
                                    "ruleID": "default"
                                ]
                            ]
                        ],
                        evalDetails: EvaluationDetails(reason: .Uninitialized)
                    )
                ].forEach { config in
                    let encoded = try! encoder.encode(config)
                    let decoded = try! decoder.decode(Layer.self, from: encoded)

                    expect(config.name).to(equal(decoded.name))
                    expect(config.ruleID).to(equal(decoded.ruleID))
                    expect(config.secondaryExposures).to(equal(decoded.secondaryExposures))
                    expect(config.evaluationDetails.reason).to(equal(decoded.evaluationDetails.reason))
                    expect(config.evaluationDetails.time).to(equal(decoded.evaluationDetails.time))
                }
            }
        }
    }
}
