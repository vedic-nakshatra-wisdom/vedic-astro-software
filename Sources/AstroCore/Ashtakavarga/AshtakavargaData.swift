import Foundation

/// Contributing bodies in Ashtakavarga (7 planets + Ascendant)
public enum AshtakavargaContributor: Hashable, Sendable {
    case planet(Planet)
    case ascendant
}

/// BPHS Bhinnashtakavarga benefic point tables.
/// For each of the 7 Ashtakavarga planets, lists the house numbers
/// (1-based, counted from contributor's position) that give a bindu.
public enum AshtakavargaData {

    /// Benefic houses for a planet from each contributor.
    /// Key: the planet whose BAV we're computing.
    /// Value: dictionary of contributor -> [house numbers where bindu is given]
    public static let tables: [Planet: [AshtakavargaContributor: [Int]]] = [
        .sun: [
            .planet(.sun):     [1, 2, 4, 7, 8, 9, 10, 11],
            .planet(.moon):    [3, 6, 10, 11],
            .planet(.mars):    [1, 2, 4, 7, 8, 9, 10, 11],
            .planet(.mercury): [3, 5, 6, 9, 10, 11, 12],
            .planet(.jupiter): [5, 6, 9, 11],
            .planet(.venus):   [6, 7, 12],
            .planet(.saturn):  [1, 2, 4, 7, 8, 9, 10, 11],
            .ascendant:        [3, 4, 6, 10, 11, 12],
        ],
        .moon: [
            .planet(.sun):     [3, 6, 7, 8, 10, 11],
            .planet(.moon):    [1, 3, 6, 7, 10, 11],
            .planet(.mars):    [2, 3, 5, 6, 9, 10, 11],
            .planet(.mercury): [1, 3, 4, 5, 7, 8, 10, 11],
            .planet(.jupiter): [1, 4, 7, 8, 10, 11, 12],
            .planet(.venus):   [3, 4, 5, 7, 9, 10, 11],
            .planet(.saturn):  [3, 5, 6, 11],
            .ascendant:        [3, 6, 10, 11],
        ],
        .mars: [
            .planet(.sun):     [3, 5, 6, 10, 11],
            .planet(.moon):    [3, 6, 11],
            .planet(.mars):    [1, 2, 4, 7, 8, 10, 11],
            .planet(.mercury): [3, 5, 6, 11],
            .planet(.jupiter): [6, 10, 11, 12],
            .planet(.venus):   [6, 8, 11, 12],
            .planet(.saturn):  [1, 4, 7, 8, 9, 10, 11],
            .ascendant:        [1, 3, 6, 10, 11],
        ],
        .mercury: [
            .planet(.sun):     [5, 6, 9, 11, 12],
            .planet(.moon):    [2, 4, 6, 8, 10, 11],
            .planet(.mars):    [1, 2, 4, 7, 8, 9, 10, 11],
            .planet(.mercury): [1, 3, 5, 6, 9, 10, 11, 12],
            .planet(.jupiter): [6, 8, 11, 12],
            .planet(.venus):   [1, 2, 3, 4, 5, 8, 9, 11],
            .planet(.saturn):  [1, 2, 4, 7, 8, 9, 10, 11],
            .ascendant:        [1, 2, 4, 6, 8, 10, 11],
        ],
        .jupiter: [
            .planet(.sun):     [1, 2, 3, 4, 7, 8, 9, 10, 11],
            .planet(.moon):    [2, 5, 7, 9, 11],
            .planet(.mars):    [1, 2, 4, 7, 8, 10, 11],
            .planet(.mercury): [1, 2, 4, 5, 6, 9, 10, 11],
            .planet(.jupiter): [1, 2, 3, 4, 7, 8, 10, 11],
            .planet(.venus):   [2, 5, 6, 9, 10, 11],
            .planet(.saturn):  [3, 5, 6, 12],
            .ascendant:        [1, 2, 4, 5, 6, 7, 9, 10, 11],
        ],
        .venus: [
            .planet(.sun):     [8, 11, 12],
            .planet(.moon):    [1, 2, 3, 4, 5, 8, 9, 11, 12],
            .planet(.mars):    [3, 5, 6, 9, 11, 12],
            .planet(.mercury): [3, 5, 6, 9, 11],
            .planet(.jupiter): [5, 8, 9, 10, 11],
            .planet(.venus):   [1, 2, 3, 4, 5, 8, 9, 10, 11],
            .planet(.saturn):  [3, 4, 5, 8, 9, 10, 11],
            .ascendant:        [1, 2, 3, 4, 5, 8, 9, 11],
        ],
        .saturn: [
            .planet(.sun):     [1, 2, 4, 7, 8, 10, 11],
            .planet(.moon):    [3, 6, 11],
            .planet(.mars):    [3, 5, 6, 10, 11, 12],
            .planet(.mercury): [6, 8, 9, 10, 11, 12],
            .planet(.jupiter): [5, 6, 11, 12],
            .planet(.venus):   [6, 11, 12],
            .planet(.saturn):  [3, 5, 6, 11],
            .ascendant:        [1, 3, 4, 6, 10, 11],
        ],
    ]

    /// Expected total bindus per planet (invariant across all charts)
    public static let expectedTotals: [Planet: Int] = [
        .sun: 48, .moon: 49, .mars: 39, .mercury: 54,
        .jupiter: 56, .venus: 52, .saturn: 39,
    ]

    /// Total SAV bindus (invariant): 337
    public static let savTotal: Int = 337
}
