import Foundation

/// Arudha Lagna (Pada Lagna) for all 12 houses per Jaimini system.
///
/// For each house: find the lord, count houses from the house to the lord,
/// then project the same count from the lord. Special BPHS exception:
/// if the Arudha falls in the same house or 7th from it, use the 10th instead.
public struct ArudhaLagnaResult: Codable, Sendable {
    /// Arudha sign for each house (1-12). Key = house number.
    public let arudhas: [Int: Sign]
    /// The primary Arudha Lagna (A1 / Pada Lagna) — Arudha of the 1st house
    public var padaLagna: Sign? { arudhas[1] }
    /// Upapada Lagna (A12 / UL) — Arudha of the 12th house
    public var upapadaLagna: Sign? { arudhas[12] }
    /// Darapada (A7) — Arudha of the 7th house
    public var darapada: Sign? { arudhas[7] }

    /// Get Arudha for a specific house
    public func arudha(ofHouse house: Int) -> Sign? {
        arudhas[house]
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case arudhas
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        init(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { return nil }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var arudhasContainer = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .arudhas)
        for house in 1...12 {
            if let sign = arudhas[house] {
                try arudhasContainer.encode(sign, forKey: DynamicKey(stringValue: "\(house)"))
            }
        }
    }
}

/// Computes Arudha Lagnas for all 12 houses.
public struct ArudhaLagnaCalculator: Sendable {

    public init() {}

    /// Compute Arudha Lagnas. Requires ascendant (birth time known).
    public func compute(from chart: BirthChart) -> ArudhaLagnaResult? {
        guard let lagnaIndex = chart.ascendant?.signIndex else { return nil }

        var arudhas: [Int: Sign] = [:]

        for house in 1...12 {
            // Sign of this house (Whole Sign)
            let houseSignIndex = (lagnaIndex + house - 1) % 12
            let houseSign = Sign(rawValue: houseSignIndex)!
            let lord = houseSign.lord

            // Find which house the lord is in
            guard let lordHouse = chart.house(of: lord) else { continue }

            // Count from the house to the lord (1-based)
            let distanceFromHouse = ((lordHouse - house + 12) % 12)

            // Project same distance from lord's house
            var arudhaHouse = ((lordHouse + distanceFromHouse - 1) % 12) + 1

            // BPHS exception: if Arudha lands in the same house or 7th from it
            if arudhaHouse == house || arudhaHouse == ((house + 5) % 12) + 1 {
                // Use the 10th house from the original house instead
                arudhaHouse = ((house + 8) % 12) + 1
            }

            let arudhaSignIndex = (lagnaIndex + arudhaHouse - 1) % 12
            arudhas[house] = Sign(rawValue: arudhaSignIndex)!
        }

        return ArudhaLagnaResult(arudhas: arudhas)
    }
}
