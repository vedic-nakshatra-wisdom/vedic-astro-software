import Foundation

// MARK: - Gemstone Enum

public enum Gemstone: String, Codable, Sendable, CaseIterable {
    case ruby
    case pearl
    case redCoral
    case emerald
    case yellowSapphire
    case diamond
    case blueSapphire
    case hessonite
    case catsEye

    public var name: String {
        switch self {
        case .ruby: return "Ruby"
        case .pearl: return "Pearl"
        case .redCoral: return "Red Coral"
        case .emerald: return "Emerald"
        case .yellowSapphire: return "Yellow Sapphire"
        case .diamond: return "Diamond"
        case .blueSapphire: return "Blue Sapphire"
        case .hessonite: return "Hessonite"
        case .catsEye: return "Cat's Eye"
        }
    }

    public var sanskritName: String {
        switch self {
        case .ruby: return "Manikya"
        case .pearl: return "Moti"
        case .redCoral: return "Moonga"
        case .emerald: return "Panna"
        case .yellowSapphire: return "Pukhraj"
        case .diamond: return "Heera"
        case .blueSapphire: return "Neelam"
        case .hessonite: return "Gomed"
        case .catsEye: return "Lehsunia"
        }
    }

    public var planet: Planet {
        switch self {
        case .ruby: return .sun
        case .pearl: return .moon
        case .redCoral: return .mars
        case .emerald: return .mercury
        case .yellowSapphire: return .jupiter
        case .diamond: return .venus
        case .blueSapphire: return .saturn
        case .hessonite: return .rahu
        case .catsEye: return .ketu
        }
    }

    public var alternativeStones: [String] {
        switch self {
        case .ruby: return ["Red Garnet", "Red Spinel"]
        case .pearl: return ["Moonstone"]
        case .redCoral: return ["Carnelian"]
        case .emerald: return ["Green Tourmaline", "Peridot"]
        case .yellowSapphire: return ["Yellow Topaz", "Citrine"]
        case .diamond: return ["White Sapphire", "White Topaz"]
        case .blueSapphire: return ["Amethyst", "Blue Spinel"]
        case .hessonite: return ["Orange Zircon"]
        case .catsEye: return ["Tiger's Eye"]
        }
    }

    public var metal: String {
        switch self {
        case .ruby: return "Gold"
        case .pearl: return "Silver"
        case .redCoral: return "Gold or Copper"
        case .emerald: return "Gold"
        case .yellowSapphire: return "Gold"
        case .diamond: return "Platinum or White Gold"
        case .blueSapphire: return "Silver or Pancha Dhatu"
        case .hessonite: return "Silver or Pancha Dhatu"
        case .catsEye: return "Silver or Pancha Dhatu"
        }
    }

    public var finger: String {
        switch self {
        case .ruby: return "Ring finger"
        case .pearl: return "Little finger"
        case .redCoral: return "Ring finger"
        case .emerald: return "Little finger"
        case .yellowSapphire: return "Index finger"
        case .diamond: return "Middle finger"
        case .blueSapphire: return "Middle finger"
        case .hessonite: return "Middle finger"
        case .catsEye: return "Ring finger"
        }
    }

    public var day: String {
        switch self {
        case .ruby: return "Sunday"
        case .pearl: return "Monday"
        case .redCoral: return "Tuesday"
        case .emerald: return "Wednesday"
        case .yellowSapphire: return "Thursday"
        case .diamond: return "Friday"
        case .blueSapphire: return "Saturday"
        case .hessonite: return "Saturday"
        case .catsEye: return "Tuesday"
        }
    }

    public var mantra: String {
        switch self {
        case .ruby: return "Om Suryaya Namaha"
        case .pearl: return "Om Chandraya Namaha"
        case .redCoral: return "Om Mangalaya Namaha"
        case .emerald: return "Om Budhaya Namaha"
        case .yellowSapphire: return "Om Gurave Namaha"
        case .diamond: return "Om Shukraya Namaha"
        case .blueSapphire: return "Om Shanaischaraya Namaha"
        case .hessonite: return "Om Rahave Namaha"
        case .catsEye: return "Om Ketave Namaha"
        }
    }

    public static func forPlanet(_ planet: Planet) -> Gemstone? {
        allCases.first { $0.planet == planet }
    }
}

// MARK: - Functional Status

public enum FunctionalStatus: String, Codable, Sendable {
    case strongBenefic
    case benefic
    case neutral
    case malefic
    case strongMalefic
}

// MARK: - Score Breakdown

public struct GemstoneScoreBreakdown: Codable, Sendable {
    public let functionalBeneficence: Double
    public let lagnaLordBonus: Double
    public let shadBalaStrength: Double
    public let dashaRelevance: Double
    public let d1Dignity: Double
    public let d9Dignity: Double
    public let ashtakavargaSupport: Double
    public let yogakarakaBonus: Double
}

// MARK: - Planet Gemstone Score

public struct PlanetGemstoneScore: Codable, Sendable {
    public let planet: Planet
    public let gemstone: Gemstone
    public let totalScore: Double
    public let breakdown: GemstoneScoreBreakdown
    public let functionalStatus: FunctionalStatus
    public let isDisqualified: Bool
    public let disqualifyReason: String?
}

// MARK: - Wearing Instructions

public struct WearingInstructions: Codable, Sendable {
    public let finger: String
    public let metal: String
    public let day: String
    public let mantra: String
}

// MARK: - Gemstone Result

public struct GemstoneResult: Codable, Sendable {
    public let recommendedPlanet: Planet
    public let gemstone: Gemstone
    public let alternativeGemstone: String?
    public let confidence: Int
    public let reasoning: [String]
    public let warnings: [String]
    public let allScores: [PlanetGemstoneScore]
    public let wearingInstructions: WearingInstructions
}
