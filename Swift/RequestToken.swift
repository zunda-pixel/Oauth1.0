import Foundation
import CryptoKit
import Collections
import OrderedCollections

let consumerKey = "FakeConcumerKey"
let consumerSecretKey = "FakeCOnsumerKey"
let requestTokenURL = "https://api.twitter.com/oauth/request_token"
let httpMethod = "POST"
let oauthVersion = "1.0"
let signatureMethod = "HMAC-SHA1"
let nonce = UUID().uuidString
let timestamp = String(Int(Date().timeIntervalSince1970))
let accessTokenSecret = "" // ここは空で良い

extension String {
  func encodeURL() -> String? {
    // Oauth1.0で許可されている文字列(許可されている文字は変換されない)
    // https://developer.twitter.com/ja/docs/authentication/oauth-1-0a/percent-encoding-parameters
    let allowedCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
    return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
  }
}

func getParameterString(parameters:[String: String]) -> String {
  let encodedValues = parameters.map {($0.encodeURL()!, $1.encodeURL()!)}
  let dictionary = encodedValues.reduce(into: OrderedDictionary<String, String>()) { $0[$1.0] = $1.1 }
  let sortedValues = dictionary.sorted { $0.0 < $1.0 } .map { $0 }
  let eachJoinedValues = OrderedSet(sortedValues.map { "\($0)=\($1)" })
  let joinedValue = eachJoinedValues.joined(separator: "&")
  return joinedValue
}

let oauth_params = [
  "oauth_consumer_key": consumerKey,
  "oauth_signature_method": signatureMethod,
  "oauth_timestamp": timestamp,
  "oauth_nonce": nonce,
  "oauth_version": oauthVersion,
]

let parameterString = getParameterString(parameters: oauth_params)

let parameters = [
  httpMethod,
  requestTokenURL,
  parameterString,
]

func getBaseString(parameters: [String]) -> String {
  let encodedValues = parameters.map{ $0.encodeURL()!}
  let joinedValue = encodedValues.joined(separator: "&")
  return joinedValue
}

let baseString = getBaseString(parameters: parameters)
let key = "\(consumerSecretKey.encodeURL()!)&\(accessTokenSecret.encodeURL()!)"

func getSignature(key:String, message:String) -> String {
  let key = SymmetricKey(data: key.data(using: .utf8)!)
  let signature = HMAC<Insecure.SHA1>.authenticationCode(for: message.data(using: .utf8)!, using: key)
  let signatureString = Data(signature).base64EncodedString(options: .lineLength64Characters)
  return signatureString
}

let signature = getSignature(key: key, message: baseString)

let headers = [
  "oauth_consumer_key": consumerKey,
  "oauth_nonce": nonce,
  "oauth_signature": signature,
  "oauth_signature_method": signatureMethod,
  "oauth_timestamp": timestamp,
  "oauth_version": oauthVersion,
]

let oauth_values = headers.map{"\($0.encodeURL()!)=\"\($1.encodeURL()!)\""}

let authorization = "OAuth \(oauth_values.joined(separator: ","))"

func getAuthenticateURL(_ oauthToken: String) -> URL{
  let authenticateURL = "https://api.twitter.com/oauth/authenticate"
  var urlComponents = URLComponents(string: authenticateURL)!
  urlComponents.queryItems = [.init(name: "oauth_token", value: oauthToken)]
  return urlComponents.url!
}

_runAsyncMain {
  do {
    let url: URL = .init(string: requestTokenURL)!
    let (data, _) = try await HTTPClient.post(url: url, headers: ["Authorization": authorization])
    let values = String(data: data, encoding: .utf8)!.split(separator: "&").map{$0.split(separator: "=")}
    let oauthToken = String(values[0][1])
    let authenticateURL = getAuthenticateURL(oauthToken)
    print(authenticateURL)
  } catch let error {
    print(error)
  }
}



