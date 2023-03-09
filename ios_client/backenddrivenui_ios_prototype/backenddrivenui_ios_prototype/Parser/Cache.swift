import Foundation

class ServidoreCache {
    static let instance = ServidoreCache()
    
    //TTL in seconds
    private let ttl = 15.0
    private init() {
        if let encoded = try? JSONEncoder().encode([CachedRoute]()) {
            UserDefaults.standard.set(encoded, forKey: "CACHE")
        }
    }

    func add(route: String, view: ViewRepresentable){
        let cachedRoute = CachedRoute(route: route, view: view)
        
        if let data = UserDefaults.standard.object(forKey: "CACHE") as? Data,
           var cache = try? JSONDecoder().decode(Array<CachedRoute>.self, from: data) {
                cache.append(cachedRoute)
            
                if let encoded = try? JSONEncoder().encode(cache) {
                    UserDefaults.standard.set(encoded, forKey: "CACHE")
                }
        }
    }
    
    func get(route: String) async -> ViewRepresentable? {
        if let data = UserDefaults.standard.object(forKey: "CACHE") as? Data,
           let cache = try? JSONDecoder().decode(Array<CachedRoute>.self, from: data) {
            if let cachedRoute = cache.first(where: { $0.route == route}) {
                if((cachedRoute.date.timeIntervalSinceNow * -1) > ttl){
                    if let newFetchedView = await cacheScreenFromServer(route) {
                        return newFetchedView
                    }
                }
                return cachedRoute.view
            }
        }
        return nil
    }
    
    func cacheScreenFromServer(_ route: String) async -> ViewRepresentable? {
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
                        print("invalid json data while caching")
                    }
                } catch {
                    print("Invalid data while caching")
                }
            }
        return nil
    }
    
    struct CachedRoute: Codable {
        var id: String = UUID().uuidString
        var date = Date()
        let route: String
        let view: ViewRepresentable
    }
}
