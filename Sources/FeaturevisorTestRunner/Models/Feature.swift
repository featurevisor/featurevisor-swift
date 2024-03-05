import Foundation

struct Feature: Decodable {

    enum Tag: String, Decodable {
        case android
        case androidtv
        case ios
        case tvos
        case web
        case lrd
        case unknown

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Tag(rawValue: rawValue) ?? .unknown
        }
    }

    struct Configuration: Decodable {
        var expose: Bool?
        var exposeTags: [Tag]?

        func isExposed(for tag: Tag) -> Bool {
            if let expose {
                return expose
            }
            else {
                return exposeTags?.contains(tag) ?? false
            }
        }
    }

    var key: String?
    var tags: [Tag]
    var environments: [String: Configuration]
}

extension Feature.Configuration {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let _expose = try? container.decode(Bool.self, forKey: .expose) {
            expose = _expose
            exposeTags = nil
        }
        else if let _exposeTags = try? container.decode([Feature.Tag].self, forKey: .expose) {
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
