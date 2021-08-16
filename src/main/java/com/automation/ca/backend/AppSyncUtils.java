package com.automation.ca.backend;

import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;

import java.io.File;
import java.io.IOException;
import java.io.FileOutputStream;
import java.io.FileNotFoundException;

import com.amazonaws.AmazonServiceException;
import com.amazonaws.ClientConfiguration;
import com.amazonaws.retry.PredefinedRetryPolicies;

import com.amazonaws.services.appsync.AWSAppSync;
import com.amazonaws.services.appsync.AWSAppSyncClientBuilder;
import com.amazonaws.services.appsync.model.GetIntrospectionSchemaRequest;
// import com.amazonaws.services.appsync.model.GetIntrospectionSchemaResult;
// import com.amazonaws.services.appsync.model.ListGraphqlApisRequest;
// import com.amazonaws.services.appsync.model.ListGraphqlApisResult;

public class AppSyncUtils {
    public AWSAppSync appSync;

    public void shutdown() {
        appSync.shutdown();
    }

    public AppSyncUtils(String region) {
        if (region.contentEquals("Nordic")) {
            appSync = AWSAppSyncClientBuilder.standard().withRegion("eu-west-1")
                    .withClientConfiguration(createAppSyncClientConfiguration()).build();
        } else if (region.contentEquals("APAC")) {
            appSync = AWSAppSyncClientBuilder.standard().withRegion("ap-southeast-1")
                    .withClientConfiguration(createAppSyncClientConfiguration()).build();
        }
    }

    /**
     * Creates a ClientConfiguration object for AppSync
     * 
     * @return ClientConfiguration object
     */
    private static ClientConfiguration createAppSyncClientConfiguration() {
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

    /**
     * Returns a String which contains an Expression used for a dynamoDB QuerySpec
     *
     * @param ApiId     The AppSync API Id
     * @param TargetDir Target directory to store the AppSync schema
     * @return Success or throwable exception message
     */
    public String downloadAppSyncSchema(String ApiId, String TargetDir) {
        GetIntrospectionSchemaRequest request = new GetIntrospectionSchemaRequest().withApiId(ApiId).withFormat("SDL");
        ByteBuffer schemaBuffer = appSync.getIntrospectionSchema(request).getSchema().asReadOnlyBuffer();
        String output = "Download SuT successful.";
        try {
            // System.out.format("Downloading AppSync schema for %s to %s\n", ApiId,
            // TargetDir);
            File OutputDir = new File(TargetDir);
            File OutputPath = new File(OutputDir.getPath() + "/SuT.graphql");
            OutputDir.mkdirs();
            FileChannel fos = new FileOutputStream(OutputPath).getChannel();
            fos.write(schemaBuffer);
            fos.close();
        } catch (FileNotFoundException e) {
            System.err.println(e.getMessage());
            output = e.getMessage();
        } catch (IOException e) {
            System.err.println(e.getMessage());
            output = e.getMessage();
        } catch (AmazonServiceException e) {
            System.err.println(e.getErrorMessage());
            output = e.getErrorMessage();
        }
        return output;
    }
}
