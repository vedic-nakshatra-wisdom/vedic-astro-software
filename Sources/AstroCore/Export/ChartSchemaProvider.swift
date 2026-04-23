import Foundation

/// Provides the JSON schema that documents the chart export format.
/// The schema file is written alongside the chart data JSON.
public enum ChartSchemaProvider {
    /// The JSON schema as a string, describing every field in the chart export.
    public static let schemaJSON: String = """
    {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "$id": "vedicastro-chart-export-v0.5",
      "title": "VedicAstro Chart Export Schema",
      "description": "Documents the JSON structure exported by VedicAstro engine v0.5. This file is auto-generated alongside the chart data. Use it to understand what each field represents.",

      "_sections": {
        "1_metadata": "Export settings — engine version, ayanamsa, house system, node type",
        "2_birthData": "Input birth data — name, UTC datetime, timezone, coordinates",
        "3_rasiChart": "D1 Rasi chart — ascendant, 9 planets (sign, degree, nakshatra, house, retrograde), house cusps",
        "4_divisionalCharts": "16 Shodasha Vargas sorted D1→D60 — each planet's sign placement per varga formula",
        "5_vimshottariDasha": "120-year dasha cycle — current period, 9 Maha Dashas with Antar sub-periods",
        "6_ashtakavarga": "Benefic point system — 7 BAV tables (per planet × 12 signs) + SAV (sum, always 337)",
        "7_shadbala": "Six-fold strength in virupas — Sthana + Dig + Kala Bala per planet",
        "8_jaimini": "Jaimini system — Chara Karakas, Karakamsa, Ishta Devta, 12 Arudha Lagnas",
        "9_specialPoints": "Bhrigu Bindu (Moon-Rahu midpoint) with SAV score"
      },

      "fieldReference": {

        "metadata": {
          "engineVersion": "string — VedicAstro engine version (e.g. '0.5')",
          "exportDate": "ISO 8601 datetime — when the export was generated",
          "ayanamsa": "string — sidereal ayanamsa system ('Lahiri', 'Raman', 'KP', etc.)",
          "ayanamsaValue": "number — precession offset in degrees at birth time",
          "houseSystem": "string — house division method ('Whole Sign', 'Placidus', etc.)",
          "nodeType": "string — Rahu/Ketu type ('True Node' or 'Mean Node')"
        },

        "birthData": {
          "name": "string — person's name",
          "dateTimeUTC": "ISO 8601 datetime — birth time converted to UTC",
          "timeZoneOffsetSeconds": "number — timezone offset in seconds (e.g. 19800 = +5:30)",
          "timeZoneOffsetHours": "string — human-readable offset (e.g. '+5.50')",
          "latitude": "number — birth latitude, North positive",
          "longitude": "number — birth longitude, East positive",
          "hasBirthTime": "boolean — if false, ascendant/houses/dashas are null"
        },

        "rasiChart": {
          "ascendant": {
            "sign": "string — zodiac sign name (Aries through Pisces)",
            "degree": "string — formatted degree in sign (e.g. 5°23'45\\\")",
            "longitude": "number — absolute sidereal longitude 0-360°",
            "nakshatra": "string — one of 27 lunar mansions",
            "pada": "integer 1-4 — nakshatra quarter"
          },
          "planets[]": {
            "planet": "string — Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, Rahu, Ketu",
            "sign": "string — sidereal sign placement",
            "longitude": "number — sidereal longitude 0-360°",
            "degreeInSign": "string — formatted degree within sign",
            "nakshatra": "string — lunar mansion",
            "pada": "integer 1-4",
            "house": "integer 1-12 or null — Whole Sign house from Lagna",
            "isRetrograde": "boolean — true if negative speed in longitude"
          },
          "houseCusps": "array of 12 numbers or null — house cusp longitudes"
        },

        "divisionalCharts[]": {
          "_note": "Sorted by division: D1, D2, D3, D4, D7, D9, D10, D12, D16, D20, D24, D27, D30, D40, D45, D60",
          "division": "integer — division number",
          "name": "string — Sanskrit name (Rasi, Hora, Drekkana, Navamsa, ...)",
          "shortName": "string — D1, D2, D9, etc.",
          "ascendantSign": "string or null — lagna sign in this varga",
          "placements[]": {
            "planet": "string — planet name",
            "sign": "string — sign this planet occupies in the varga"
          }
        },

        "vimshottariDasha": {
          "_note": "120-year cycle starting from Moon's nakshatra lord. Balance at birth determines first period length.",
          "currentDasha": {
            "asOf": "ISO 8601 datetime — date the current period was calculated for",
            "maha": "string — current Maha Dasha planet",
            "antar": "string or null — current Antar Dasha planet",
            "pratyantar": "string or null — current Pratyantar Dasha planet"
          },
          "mahaDashas[]": {
            "planet": "string — ruling planet",
            "startDate": "ISO 8601 datetime",
            "endDate": "ISO 8601 datetime",
            "years": "number — duration in years",
            "antarDashas[]": {
              "planet": "string",
              "startDate": "ISO 8601 datetime",
              "endDate": "ISO 8601 datetime"
            }
          }
        },

        "ashtakavarga": {
          "_note": "BPHS benefic point system. BAV totals per planet: Su=48, Mo=49, Ma=39, Me=54, Ju=56, Ve=52, Sa=39. SAV total always = 337.",
          "bpiBindus": {
            "_note": "Key = planet name. Value = { planet, bindus[12], total }",
            "bindus": "array of 12 integers — index 0=Aries through 11=Pisces, values 0-8"
          },
          "sarvashtakavarga": {
            "bindus": "array of 12 integers — sum of all 7 BAV tables per sign"
          }
        },

        "shadbala": {
          "_note": "Strength in virupas (1 rupa = 60 virupas). BPHS minimum: Su=6.5, Mo=6.0, Ma=5.0, Me=7.0, Ju=6.5, Ve=5.5, Sa=5.0 rupas. Current implementation is partial (missing Cheshta, Ayana, Drig Bala).",
          "planetBala": {
            "_note": "Key = planet name (7 sign-lord planets, no Rahu/Ketu)",
            "uchchaBala": "0-60 virupas — exaltation strength, max at deep exaltation degree",
            "saptavargajaBala": "virupas — dignity score (basic: own=30, exalt=20, debil=5, neutral=10)",
            "ojhayugmarasiBala": "0/15/30 virupas — odd/even sign + navamsa match",
            "kendradiBala": "15/30/60 virupas — kendra=60, panapara=30, apoklima=15",
            "drekkanaBala": "0/15 virupas — decanate gender match",
            "digBala": "0-60 virupas — directional strength based on house",
            "naisargikaBala": "fixed virupas — natural strength (Su=60 down to Sa=8.57)",
            "pakshaBala": "0-60 virupas — lunar phase (benefics gain in waxing Moon)"
          }
        },

        "jaimini": {
          "charaKarakas": {
            "_note": "Planets sorted by degree-in-sign descending. Rahu inverted (30 - degree).",
            "ranking[]": "{ planet, degreeInSign, karaka } — from AK (highest) to DK (lowest)",
            "isEightKaraka": "boolean — true includes Rahu as Pitrikaraka"
          },
          "karakamsa": {
            "_note": "AK's Navamsa sign. Foundation for Swamsa analysis.",
            "karakamsaSign": "string — the D9 sign of Atmakaraka",
            "planetsInKarakamsa": "array — planets in that D9 sign",
            "houseFromLagna": "integer or null — Karakamsa's house from D1 Lagna"
          },
          "ishtaDevta": {
            "_note": "12th sign from Karakamsa checked in D1. Occupant planet → deity. If empty → sign lord → deity.",
            "deity": "string — indicated deity (e.g. 'Goddess Lakshmi')",
            "significator": "string — planet determining the deity"
          },
          "arudhaLagnas": {
            "_note": "12 Arudha Padas. Key = house number (1-12). Value = sign name. Key padas: 1=AL (Pada Lagna), 7=Darapada, 12=UL (Upapada)."
          }
        },

        "specialPoints": {
          "bhriguBindu": {
            "_note": "Midpoint of Moon and Rahu (shorter arc). Transit trigger point.",
            "longitude": "number — sidereal longitude 0-360°",
            "sign": "string — zodiac sign",
            "degreeInSign": "number — degree within sign 0-30",
            "nakshatra": "string — lunar mansion",
            "pada": "integer 1-4",
            "house": "integer 1-12 or null — from Lagna",
            "savScore": "integer or null — SAV bindus at this sign (higher = more favorable transits)"
          }
        }
      }
    }
    """
}
