import Foundation

struct StatsigUserInternal {
    let user: StatsigUser

    internal func getUnitID(_ type: String) -> String? {
        let lowered = type.lowercased()

        if lowered == "userid" {
            return user.userID
        }

        return user.customIDs[type] ?? user.customIDs[lowered]
    }

    internal func getFromEnvironment(_ field: String?) -> JsonValue? {
        guard let field else {
            return nil
        }

        let lowered = field.lowercased()
        if let value = getEnvironmentValueString(lowered) {
            return .string(value)
        }

        return nil
    }

    internal func getUserValue(_ field: String?) -> JsonValue? {
        guard let field else {
            return nil
        }

        let lowered = field.lowercased()
        if let strValue = getUserValueString(lowered) {
            return .string(strValue)
        }

        if let value = user.custom[field] ?? user.custom[lowered] {
            return value
        }

        if let value = user.privateAttributes[field] ?? user.privateAttributes[lowered] {
            return value
        }

        return nil
    }

    private func getUserValueString(_ field: String) -> String? {
        switch field {
        case "userid", "user_id": return user.userID
        case "email": return user.email
        case "ip": return user.ip
        case "useragent", "user_agent": return user.userAgent
        case "country": return user.country
        case "locale": return user.locale
        case "appversion", "app_version": return user.appVersion
        default: return nil
        }
    }

    private func getEnvironmentValueString(_ field: String) -> String? {
        switch field {
        case "tier": return user.environment?.tier
        default: return nil
        }
    }
}

func internalizeUser(_ user: StatsigUser, _ options: StatsigOptions?) -> StatsigUserInternal {
    StatsigUserInternal(user: user)
}

extension StatsigUserValueMap {
    subscript(key: String) -> JsonValue? {
        get {
            return JsonValue(self.values[key])
        }
    }
}
