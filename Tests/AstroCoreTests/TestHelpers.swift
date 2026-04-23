import Foundation
@testable import AstroCore
import CSwissEph

/// Shared ephemeris actor for all tests.
/// Swiss Ephemeris uses process-wide global state, so concurrent access from
/// multiple actor instances causes corruption (NaN results). All tests must
/// go through this single instance.
enum TestEphemeris {
    static let shared: EphemerisActor = {
        let actor = EphemerisActor()
        return actor
    }()

    static func initialize() async {
        let bundle = Bundle.module
        let ephePath = bundle.resourceURL?
            .appendingPathComponent("Resources")
            .appendingPathComponent("Ephemeris")
            .path
        await shared.initialize(ephemerisPath: ephePath)
    }
}
