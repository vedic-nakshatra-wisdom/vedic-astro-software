import Foundation

/// Computes divisional charts from a D1 birth chart.
/// Pure math — no ephemeris calls needed.
public struct VargaCalculator: Sendable {

    public init() {}

    /// Compute a single divisional chart from a D1 chart.
    public func computeVarga(_ vargaType: VargaType, from chart: BirthChart) -> VargaChart {
        var placements: [Planet: Sign] = [:]

        for (planet, position) in chart.planets {
            let signIndex = vargaType.vargaSignIndex(for: position.longitude)
            placements[planet] = Sign(rawValue: signIndex)!
        }

        let ascSign: Sign?
        if let asc = chart.ascendant {
            ascSign = Sign(rawValue: vargaType.vargaSignIndex(for: asc.longitude))
        } else {
            ascSign = nil
        }

        return VargaChart(
            vargaType: vargaType,
            placements: placements,
            sourceChart: chart,
            ascendantSign: ascSign
        )
    }

    /// Compute all 16 Shodasha Vargas at once.
    public func computeAllVargas(from chart: BirthChart) -> [VargaType: VargaChart] {
        var result: [VargaType: VargaChart] = [:]
        for varga in VargaType.allCases {
            result[varga] = computeVarga(varga, from: chart)
        }
        return result
    }
}
