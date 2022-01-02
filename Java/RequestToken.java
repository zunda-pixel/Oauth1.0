import java.net.URI;
import java.net.URLEncoder;

import java.net.http.*;
import java.net.http.HttpResponse.BodyHandlers;
import java.net.http.HttpRequest.BodyPublishers;

import java.util.*;
import java.util.Map.Entry;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public class RequestToken {
	public static void main(String[] args) throws Exception {
		var consumerkey = "FakeConsumerKey";
		var consumerSecretKey = "FakeSecretConsumerKey";
		var oauthTokenSecret = ""; // ここは空で良い
		var httpMethod = "POST";
		var requestTokenURL = "https://api.twitter.com/oauth/request_token";
		var signatureMethod = "HMAC-SHA1";
		var timestamp = String.valueOf(getUnixTime());
		var nonce = UUID.randomUUID().toString();
		var oauthVersion = "1.0";

		SortedMap<String, String> params = new TreeMap<String, String>() {
			{
				put("oauth_consumer_key", consumerkey);
				put("oauth_signature_method", signatureMethod);
				put("oauth_timestamp", timestamp);
				put("oauth_nonce", nonce);
				put("oauth_version", oauthVersion);
			}
		};

		String parameterString = getParameterString(params);

		var parameters = new ArrayList<String>() {
			{
				add(httpMethod);
				add(requestTokenURL);
				add(parameterString);
			}
		};

		String baseString = getBaseString(parameters);

		String key = urlEncode(consumerSecretKey) + "&" + urlEncode(oauthTokenSecret);

		String signature = getSignature(key, baseString);

		var oauthParameter = new HashMap<String, String>() {
			{
				put("oauth_consumer_key", consumerkey);
				put("oauth_nonce", nonce);
				put("oauth_signature", signature);
				put("oauth_signature_method", signatureMethod);
				put("oauth_timestamp", timestamp);
				put("oauth_version", oauthVersion);
			}
		};

		String authorization = getAuthorization(oauthParameter);

		var headers = new HashMap<String, String>() {
			{
				put("Authorization", authorization);
			}
		};
		
		HttpClient client = HttpClient.newHttpClient();
   	HttpRequest request = HttpRequest.newBuilder()
      .uri(URI.create(requestTokenURL))
			.header("Authorization", authorization)
			.POST(BodyPublishers.noBody())
			.build();
   	HttpResponse<String> response = client.send(request, BodyHandlers.ofString());
		String oauthToken = response.body().split("&")[0].split("=")[1];
		String authenticateURL = "https://api.twitter.com/oauth/authenticate?oauth_token=" + oauthToken;
		System.out.println(authenticateURL);
	}

	private static String getAuthorization(HashMap<String, String> parameters) {
		var values = new ArrayList<String>();

		for (Entry<String, String> parameter : parameters.entrySet()) {
			values.add(urlEncode(parameter.getKey()) + "=\"" + urlEncode(parameter.getValue()) + "\"");
		}

		var authorization = "OAuth " + String.join(",", values);

		return authorization;
	}


	private static String getSignature(String key, String baseString) {
		SecretKeySpec signingKey = new SecretKeySpec(key.getBytes(), "HmacSHA1");
		try {
			Mac mac = Mac.getInstance(signingKey.getAlgorithm());
			mac.init(signingKey);
			byte[] rawHmac = mac.doFinal(baseString.getBytes());
			String signature = new String(Base64.getEncoder().encode(rawHmac));
			return signature;
		} catch (Exception e) {
			return "";
		}
	}

	private static String getParameterString(SortedMap<String, String> parameters) {
			List<String> values = new ArrayList<String>();

			for (Entry<String, String> parameter : parameters.entrySet()) {
				values.add(parameter.getKey() + "=" + parameter.getValue());
			}

			String parameterString = String.join("&", values);

			return parameterString;
	}

	private static String getBaseString(ArrayList<String> parameters)  {
		var encodedParameters = new ArrayList<String>();
		parameters.stream().map(x -> urlEncode(x)).forEach(y -> encodedParameters.add(y));

		String baseString = String.join("&", encodedParameters);
		return baseString;
	}

	private static int getUnixTime() {
		return (int) (System.currentTimeMillis() / 1000L);
	}

	private static String urlEncode(String string) {
		try {
			return URLEncoder.encode(string, "UTF-8");
		} catch (Exception e) {
			return "";
		}
	}
}
