import Foundation

class ServerManager: ObservableObject {
    @Published var currentView: ViewComponent = EmptyComponent(id: UUID().uuidString, modifier: [])
    
    func loadScreenFromServer(_ route: String) async -> ViewRepresentable {
        if let view = await ServidoreCache.instance.get(route: route) {
            return view
        } else {
            if var url = URLComponents(string: "http://localhost:3000/screen") {
                do {
                    url.queryItems = [
                        URLQueryItem(name: "screenName", value: route)
                    ]
                    let request = URLRequest(url: url.url!)
                    let (data, _) = try await URLSession.shared.data(for: request)
                    if let decodedResponse = try? JSONDecoder().decode(ViewRepresentable.self, from: data) {
                        ServidoreCache.instance.add(route: route, view: decodedResponse)
                        return decodedResponse
                    } else {
                        print("invalid json data")
                    }
                } catch {
                    print("Invalid data")
                }
            }
        }
        return ViewRepresentable(id: UUID().uuidString, type: "TEXT", text: "Connection failed!")
    }
    
    func sendPayloadGetUiChanges(url route: String, payload: [ComponentPayload]) async -> UiChangeReponse {
        if var url = URLComponents(string: "http://localhost:3000\(route)" ) {
            do {
                url.queryItems = payload.map { p in
                    let encodedData = try? JSONEncoder().encode(p)
                    var jsonString = ""
                    if(encodedData != nil){
                        jsonString = String(data: encodedData!, encoding: .utf8) ?? "Error while encoding JSON"
                    } else {
                        jsonString = "Error while encoding JSON"
                    }
                   
                    return URLQueryItem(name: p.id, value: jsonString)
                }
                let request = URLRequest(url: url.url!)
                let (data, _) = try await URLSession.shared.data(for: request)
                if let decodedResponse = try? JSONDecoder().decode(UiChangeReponse.self, from: data) {
                    return decodedResponse
                } else {
                    print("invalid json data")
                }
            } catch {
                print("Invalid data")
            }
        }
            
        return UiChangeReponse(changes: [])
    }
    
    func sendPayloadGetNewScreen(url route: String, payload: [ComponentPayload]) async -> ViewRepresentable {
        if var url = URLComponents(string: "http://localhost:3000\(route)" ) {
            do {
                url.queryItems = payload.map { p in
                    let encodedData = try? JSONEncoder().encode(p)
                    var jsonString = ""
                    if(encodedData != nil){
                        jsonString = String(data: encodedData!, encoding: .utf8) ?? "Error while encoding JSON"
                    } else {
                        jsonString = "Error while encoding JSON"
                    }
                   
                    return URLQueryItem(name: p.id, value: jsonString)
                }
                let request = URLRequest(url: url.url!)
                let (data, _) = try await URLSession.shared.data(for: request)
                if let decodedResponse = try? JSONDecoder().decode(ViewRepresentable.self, from: data) {
                    return decodedResponse
                } else {
                    print("invalid json data")
                }
            } catch {
                print("Invalid data")
            }
        }
            
        return ViewRepresentable(id: UUID().uuidString, type: "TEXT", text: "Connection failed!")
    }
}

struct ViewRepresentable: Codable {
    let id: String
    let type: String
    var children: [ViewRepresentable]? = nil
    var modifier: [ModifierRepresentable]? = nil
    var text: String? = nil
    var message: String? = nil
    var imagePath: String? = nil
    var icon: String? = nil
    var rangeStart: Int? = nil
    var rangeEnd: Int? = nil
    var tabViews: [ServerTabView]? = nil
    var action: ClickAction? = nil
    var validator: Validator? = nil
    var isEnabled: Bool? = nil
}

struct ServerTabView: Codable {
    let name: String
    let icon: String
    let view: ViewRepresentable
}

struct Validator: Codable {
    let type: String
    let value: String
}

struct ComponentPayload: Codable {
    let id: String
    let type: String
    let payload: [ComponentFieldValue]
}

struct ComponentFieldValue: Codable {
    let fieldName: String
    let value: String
}
struct UiChangeReponse: Codable {
    let changes: [FieldValue]
}
struct FieldValue: Codable {
    let id: String
    let type: String
    let fieldName: String
    let value: String
}

struct ModifierRepresentable: Codable {
    let type: String
    var color: String? = nil
    var fontGroup: String? = nil
    var fontSize: Int? = nil
    var fontStyle: String? = nil
    var borderWidth: Int? = nil
    var shape: String? = nil
    var elevation: String? = nil
    var radius: Int? = nil
    var x: Int? = nil
    var y: Int? = nil
    var stroke: Int? = nil
    var width: Int? = nil
    var height: Int? = nil
    var action: ClickAction? = nil
}
