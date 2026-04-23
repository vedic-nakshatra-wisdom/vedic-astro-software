import Foundation
import CSwissEph

/// Thread-safe actor wrapping all Swiss Ephemeris C calls.
/// Swiss Ephemeris uses process-wide global state (swe_set_sid_mode, swe_set_ephe_path),
/// so all calls MUST go through this actor to prevent concurrent corruption.
public actor EphemerisActor {

    private var isInitialized = false

    public init() {}

    /// Initialize the ephemeris engine with the path to .se1 data files.
    /// Falls back to Moshier mode (~1 arc-second accuracy) if path is invalid.
    public func initialize(ephemerisPath: String?) {
        if let path = ephemerisPath {
            swe_set_ephe_path(path)
        }
        isInitialized = true
    }

    /// Set the sidereal mode (ayanamsa). Must be called before any position calculations.
    /// - Parameter mode: Swiss Ephemeris sidereal mode constant (e.g., SE_SIDM_LAHIRI = 1)
    public func setSiderealMode(_ mode: Int32) {
        swe_set_sid_mode(mode, 0, 0)
    }

    /// Convert a calendar date to Julian Day number.
    /// - Parameters:
    ///   - year: Calendar year
    ///   - month: Month (1-12)
    ///   - day: Day of month
    ///   - hour: Decimal hours in UT (e.g., 14.5 for 2:30 PM UT)
    /// - Returns: Julian Day number
    public func julianDay(year: Int32, month: Int32, day: Int32, hour: Double) -> Double {
        return swe_julday(year, month, day, hour, SE_GREG_CAL)
    }

    /// Calculate the sidereal position of a celestial body.
    /// - Parameters:
    ///   - body: Planet/body number (SE_SUN=0 through SE_TRUE_NODE=11)
    ///   - julianDay: Julian Day number in UT
    /// - Returns: Tuple of (longitude, latitude, distance, speedLon, speedLat, speedDist) or nil on error
    public func calcUT(body: Int32, at julianDay: Double) -> (longitude: Double, latitude: Double, distance: Double, speedLon: Double, speedLat: Double, speedDist: Double)? {
        var xx = [Double](repeating: 0, count: 6)
        var serr = [CChar](repeating: 0, count: 256)
        let flags = SEFLG_SIDEREAL | SEFLG_SPEED
        let result = swe_calc_ut(julianDay, body, flags, &xx, &serr)
        guard result >= 0 else {
            let errorMsg = String(cString: serr)
            print("Swiss Ephemeris error: \(errorMsg)")
            return nil
        }
        return (xx[0], xx[1], xx[2], xx[3], xx[4], xx[5])
    }

    /// Get the current ayanamsa value for a given Julian Day.
    public func ayanamsaUT(at julianDay: Double) -> Double {
        return swe_get_ayanamsa_ut(julianDay)
    }

    /// Close the Swiss Ephemeris and free resources.
    public func close() {
        swe_close()
        isInitialized = false
    }
}
