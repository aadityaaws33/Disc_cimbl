package CA.Utils.java;

import com.amazonaws.ClientConfiguration;
import com.amazonaws.retry.PredefinedRetryPolicies;
import com.amazonaws.services.secretsmanager.AWSSecretsManager;
import com.amazonaws.services.secretsmanager.AWSSecretsManagerClientBuilder;
import com.amazonaws.services.secretsmanager.model.GetSecretValueRequest;
import com.amazonaws.services.secretsmanager.model.GetSecretValueResult;
import com.amazonaws.services.secretsmanager.model.ResourceNotFoundException;
import com.amazonaws.services.secretsmanager.model.InvalidParameterException;
import com.amazonaws.services.secretsmanager.model.InvalidRequestException;
import com.amazonaws.services.secretsmanager.model.DecryptionFailureException;
import com.amazonaws.services.secretsmanager.model.InternalServiceErrorException;

import java.util.Map;
import java.util.Base64;

public class SecretsManagerUtils {
    AWSSecretsManager secretsManager;

    public void shutdown() {
        secretsManager.shutdown();
    }

    public SecretsManagerUtils(String region) {
        if (region.contentEquals("Nordic")) {
            secretsManager = AWSSecretsManagerClientBuilder.standard().withRegion("eu-west-1")
                    .withClientConfiguration(createSMClientConfiguration()).build();
        } else if (region.contentEquals("APAC")) {
            secretsManager = AWSSecretsManagerClientBuilder.standard().withRegion("ap-southeast-1")
                    .withClientConfiguration(createSMClientConfiguration()).build();
        }
    }

    /**
     * Creates a ClientConfiguration object for DynamoDB
     * 
     * @return ClientConfiguration object
     */
    private static ClientConfiguration createSMClientConfiguration() {
        int connectionTimeout = GlobalUtilsConfig.connectionTimeout;
        int clientExecutionTimeout = GlobalUtilsConfig.clientExecutionTimeout;
        int requestTimeout = GlobalUtilsConfig.requestTimeout;
        int socketTimeout = GlobalUtilsConfig.socketTimeout;
        int maxErrorRetries = GlobalUtilsConfig.maxErrorRetries;
        int maxConnections = GlobalUtilsConfig.maxConnections;

        ClientConfiguration clientConfiguration = new ClientConfiguration().withConnectionTimeout(connectionTimeout)
                .withClientExecutionTimeout(clientExecutionTimeout).withRequestTimeout(requestTimeout)
                .withSocketTimeout(socketTimeout).withMaxConnections(maxConnections).withRetryPolicy(
                        PredefinedRetryPolicies.getDynamoDBDefaultRetryPolicyWithCustomMaxRetries(maxErrorRetries));

        // ClientConfiguration.getClientConfiguration(clientConfiguration);

        return clientConfiguration;
    }

    public Map<String, String> getSecrets(String secretName) {

        String secret = null;
        String decodedBinarySecret = null;

        GetSecretValueRequest getSecretValueRequest = new GetSecretValueRequest().withSecretId(secretName);
        GetSecretValueResult getSecretValueResult = null;

        try {
            getSecretValueResult = secretsManager.getSecretValue(getSecretValueRequest);
        } catch (DecryptionFailureException e) {
            System.err.println(e.getMessage());
            throw e;
        } catch (InternalServiceErrorException e) {
            System.err.println(e.getMessage());
            throw e;
        } catch (InvalidParameterException e) {
            System.err.println(e.getMessage());
            throw e;
        } catch (InvalidRequestException e) {
            System.err.println(e.getMessage());
            throw e;
        } catch (ResourceNotFoundException e) {
            System.err.println(e.getMessage());
            throw e;
        }

        if (getSecretValueResult.getSecretString() != null) {
            secret = getSecretValueResult.getSecretString();
        } else {
            decodedBinarySecret = new String(
                    Base64.getDecoder().decode(getSecretValueResult.getSecretBinary()).array());
        }

        Map<String, String> output = GenericUtils.convertJSONStringToMap(secret);
        return output;
    }

}
