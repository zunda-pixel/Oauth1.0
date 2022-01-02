import time, uuid
import urllib.parse
import urllib.request
import hmac, hashlib, base64

consumerKey = "FakeConsumerKey"
consumerSecretKey = "FakeSecretConsumerKey"
requestTokenURL = "https://api.twitter.com/oauth/request_token"
httpMethod = "POST"
oauthVersion = "1.0"
signatureMethod = "HMAC-SHA1"
nonce = str(uuid.uuid4())
timestamp = str(int(time.time()))
accessTokenSecret = "" # ここは空で良い

def encodeURL(value):
  # Oauth1.0で許可されている文字列(許可されている文字は変換されない)
  # https://developer.twitter.com/ja/docs/authentication/oauth-1-0a/percent-encoding-parameters
  return urllib.parse.quote(value, safe="-._~")

def getParameterString(parameters):
  encodedValues = dict([(encodeURL(key), encodeURL(value)) for key, value in parameters.items()])
  sortedValues = dict(sorted(encodedValues.items()))
  eachJoinedValues = list([f"{key}={value}" for key, value in sortedValues.items()]) # 本当はこれが順番付きリストにならないといけない
  joinedValue = "&".join(eachJoinedValues)
  return joinedValue

oauth_params = {
  "oauth_consumer_key": consumerKey,
  "oauth_nonce": nonce,
  "oauth_signature_method": signatureMethod,
  "oauth_timestamp": timestamp,
  "oauth_version": oauthVersion,
}

parameterString = getParameterString(oauth_params)

parameters = [
  httpMethod,
  requestTokenURL,
  parameterString,
]

def getBaseString(parameters):
  encodedValues = list([encodeURL(parameter) for parameter in parameters])
  joinedValue = "&".join(encodedValues)
  return joinedValue

baseString = getBaseString(parameters)

key = f"{encodeURL(consumerSecretKey)}&{encodeURL(accessTokenSecret)}"

def getSignature(key, message):
  hashedValue = hmac.new(key.encode(), message.encode(), hashlib.sha1).digest()
  signature = base64.b64encode(hashedValue).decode()
  return signature

signature = getSignature(key, baseString)

oauthValues = {
  "oauth_consumer_key": consumerKey,
  "oauth_nonce": nonce,
  "oauth_signature": signature,
  "oauth_signature_method": signatureMethod,
  "oauth_timestamp": timestamp,
  "oauth_version": oauthVersion,
}

joinedOauthValus = list([f"{encodeURL(key)}=\"{encodeURL(value)}\"" for key, value in oauthValues.items()])
oauth = ",".join(joinedOauthValus)
authorization = f"OAuth {oauth}"

request = urllib.request.Request(requestTokenURL, method=httpMethod)
request.add_header("Authorization", authorization)

with urllib.request.urlopen(request) as response:
  data = response.read().decode()
  values = data.split("&")
  oauth_token = values[0].split("=")[1]
  url = f"https://api.twitter.com/oauth/authenticate?oauth_token={oauth_token}"
  print(url)
