Feature: S3 Utility

Background:
    * def initializeS3Object =
        """
            function(thisAWSregion) {
                var S3UtilsClass = Java.type('CA.Utils.java.S3Utils');
                return new S3UtilsClass(AWSRegion);
            }
        """
    * def s3Utils = call initializeS3Object AWSRegion
    * configure afterFeature =
        """
            function() {
                s3Utils.shutdown();
            }
        """

@DownloadS3Object
Scenario: Download an S3 Object
    * def downloadS3Object = 
        """
        function() {       
            var s3DownloadStatus = s3Utils.downloadS3Object(
                S3BucketName, //s3 bucket name
                S3Key, //s3 key
                DownloadPath, //target download path
                DownloadFilename //target download filename
            ); 
            var resp = {
                message: s3DownloadStatus,
                pass: s3DownloadStatus.contains('success')?true:false
            }

            return resp;
        }
        """
    * def result = downloadS3Object()

@UploadFile
Scenario: Upload a File
    * def uploadFile =
        """
            function() {
                var s3UploadStatus = s3Utils.uploadFile(
                    S3BucketName, //s3 bucket name
                    S3Key, //s3 key
                    FilePath //target file to be upload
                );
                var resp = {
                    message: s3UploadStatus,
                    pass: s3UploadStatus.contains('success')?true:false
                }

                return resp;
            }
        """
    * def result = uploadFile()

@DeleteS3Object
Scenario: Delete an S3 Object
    * def deleteS3Object = 
        """
            function() {
                var s3DeleteStatus = s3Utils.deleteS3Object(
                    S3BucketName, //s3 bucket name
                    S3Key //s3 key
                ); 
                var resp = {
                    message: s3DeleteStatus,
                    pass: s3DeleteStatus.contains('success')?true:false
                }

                return resp;
            }
        """
    * def result = deleteS3Object()