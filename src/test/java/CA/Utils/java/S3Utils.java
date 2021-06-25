package CA.Utils.java;

import java.util.Date;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.S3Object;
import com.amazonaws.services.s3.model.S3ObjectInputStream;
import com.amazonaws.services.s3.model.GetObjectMetadataRequest;
import com.amazonaws.services.s3.model.ObjectMetadata;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.amazonaws.services.s3.model.DeleteObjectRequest;

import com.amazonaws.auth.DefaultAWSCredentialsProviderChain;
import com.amazonaws.auth.profile.ProfileCredentialsProvider;
import com.amazonaws.SdkClientException;
import com.amazonaws.AmazonServiceException;
import com.amazonaws.ClientConfiguration;
import com.amazonaws.retry.PredefinedRetryPolicies;

import java.io.File;
import java.io.IOException;
import java.io.FileOutputStream;
import java.io.FileNotFoundException;

public class S3Utils {
    AmazonS3 s3;

    public void shutdown() {
        s3.shutdown();
    }

    public S3Utils(String region) {
        if (region.contentEquals("Nordic")) {
            s3 = AmazonS3ClientBuilder.standard().withRegion("eu-west-1")
                    .withClientConfiguration(createS3ClientConfiguration())
                    .withCredentials(DefaultAWSCredentialsProviderChain.getInstance()).build();
        } else if (region.contentEquals("APAC")) {
            s3 = AmazonS3ClientBuilder.standard().withRegion("ap-southeast-1")
                    .withClientConfiguration(createS3ClientConfiguration())
                    .withCredentials(DefaultAWSCredentialsProviderChain.getInstance()).build();
        }
    }

    /**
     * Creates a ClientConfiguration object for AppSync
     * 
     * @return ClientConfiguration object
     */
    private static ClientConfiguration createS3ClientConfiguration() {

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

        return clientConfiguration;
    }

    /**
     * Deletes an S3 object
     * 
     * @param BucketName The full S3 Bucket Name
     * @param ObjectKey  The full S3 Object Key
     * @param FilePath   The file path of the file to be uploaded
     * @return Output or error message
     */
    public String deleteS3Object(String BucketName, String ObjectKey) {

        String output = "Deleted successfully.";
        try {
            s3.deleteObject(new DeleteObjectRequest(BucketName, ObjectKey));
        } catch (AmazonServiceException e) {
            System.err.println(e.getErrorMessage());
            output = e.getErrorMessage();
        } catch (SdkClientException e) {
            System.err.println(e.getMessage());
            output = e.getMessage();
        }

        return output;
    }

    /**
     * Uploads a file to S3
     * 
     * @param BucketName The full S3 Bucket Name
     * @param ObjectKey  The full S3 Object Key
     * @param FilePath   The file path of the file to be uploaded
     * @return Output or error message
     */
    public String uploadFile(String BucketName, String ObjectKey, String FilePath) {

        String output = "Uploaded successfully.";
        try {
            PutObjectRequest request = new PutObjectRequest(BucketName, ObjectKey, new File(FilePath));
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentType("text/xml");
            request.setMetadata(metadata);
            s3.putObject(request);
        } catch (AmazonServiceException e) {
            System.err.println(e.getErrorMessage());
            output = e.getErrorMessage();
        } catch (SdkClientException e) {
            System.err.println(e.getMessage());
            output = e.getMessage();
        }

        return output;
    }

    /**
     * Returns a Boolean which tells if an S3 Object exists
     *
     * @param BucketName The full S3 Bucket Name
     * @param ObjectKey  The full S3 Object Key
     * @return Boolean which tells if an S3 Object exists
     */
    public boolean isS3ObjectExists(String BucketName, String ObjectKey) {

        boolean output = false;
        try {
            output = s3.doesObjectExist(BucketName, ObjectKey);
        } catch (AmazonServiceException e) {
            System.err.println(e.getErrorMessage());
        }

        return output;
    }

    /**
     * Downloads an S3 Object to a File directory
     *
     * @param BucketName   The full S3 Bucket Name
     * @param ObjectKey    The full S3 Object Key
     * @param TargetDir    The target directory to store the S3 object
     * @param SaveFileName The Filename to be used in saving the file (defaults to
     *                     ObjectKey)
     * @return Output or error message
     */
    public String downloadS3Object(String BucketName, String ObjectKey, String TargetDir, String SaveFileName) {

        String ObjectKeySplit[] = ObjectKey.split("/");
        if (SaveFileName == "") {
            SaveFileName = URLEncoder.encode(ObjectKeySplit[ObjectKeySplit.length - 1], StandardCharsets.UTF_8);
        }
        File OutputDir = new File(TargetDir);
        File OutputPath = new File(OutputDir.getPath() + "/" + SaveFileName);

        var output = "Downloaded successfully.";
        try {
            S3Object o = s3.getObject(BucketName, ObjectKey);
            S3ObjectInputStream s3is = o.getObjectContent();

            OutputDir.mkdirs();
            FileOutputStream fos = new FileOutputStream(OutputPath);

            byte[] read_buf = new byte[1024];
            int read_len = 0;
            while ((read_len = s3is.read(read_buf)) > 0) {
                fos.write(read_buf, 0, read_len);
            }
            s3is.close();
            fos.close();
        } catch (AmazonServiceException e) {
            System.err.println(e.getErrorMessage());
            output = e.getErrorMessage();
        } catch (FileNotFoundException e) {
            System.err.println(e.getMessage());
            output = e.getMessage();
        } catch (IOException e) {
            System.err.println(e.getMessage());
            output = e.getMessage();
        }
        return output;
    }

    /**
     * Returns s3 metadata
     *
     * @param BucketName The full S3 Bucket Name
     * @param ObjectKey  The full S3 Object Key
     * @return s3 metadata
     */
    public ObjectMetadata getS3ObjectMetadata(String BucketName, String ObjectKey) {

        ObjectMetadata metadata = s3.getObjectMetadata(BucketName, ObjectKey);

        return metadata;
    }

    /**
     * Returns s3 object's last modified date
     *
     * @param BucketName The full S3 Bucket Name
     * @param ObjectKey  The full S3 Object Key
     * @return s3 object's last modified date
     */
    public Date getS3ObjectLastModified(String BucketName, String ObjectKey) {

        ObjectMetadata metadata = getS3ObjectMetadata(BucketName, ObjectKey);
        Date date = metadata.getLastModified();

        return date;
    }
}
