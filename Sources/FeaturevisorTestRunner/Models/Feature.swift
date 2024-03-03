import Foundation

struct Feature: Decodable {

    struct Configuration: Decodable {
        var expose: Bool?
        var exposeTags: [String]?

        func isExposed(for tag: String) -> Bool {
            if let expose {
                return expose
            }
            else {
                return exposeTags?.contains(tag) ?? false
            }
        }
    }

    var key: String?
    var tags: [String]
    var environments: [String: Configuration]
}

extension Feature.Configuration {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let _expose = try? container.decode(Bool.self, forKey: .expose) {
            expose = _expose
            exposeTags = nil
        }
        else if let _exposeTags = try? container.decode([String].self, forKey: .expose) {
            expose = nil
            exposeTags = _exposeTags
        }
        else {
            // Be default expose is set to true
            expose = true
            exposeTags = nil
        }
    }

    public enum CodingKeys: String, CodingKey {
        case expose
    }
}
