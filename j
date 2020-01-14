package S3muleSoft.amazonUtils;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import com.amazonaws.AmazonClientException;
import com.amazonaws.AmazonServiceException;
import com.amazonaws.SdkClientException;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.CompleteMultipartUploadRequest;
import com.amazonaws.services.s3.model.InitiateMultipartUploadRequest;
import com.amazonaws.services.s3.model.InitiateMultipartUploadResult;
import com.amazonaws.services.s3.model.UploadPartRequest;
import com.amazonaws.services.s3.model.UploadPartResult;
import com.amazonaws.services.s3.transfer.TransferManager;
import com.amazonaws.services.s3.transfer.TransferManagerBuilder;
import com.amazonaws.services.s3.transfer.Upload;
import com.amazonaws.services.s3.model.PartETag;

public class UploadMultiPartToS3Utils {
	private static final String UPLOADS_DIR ="/uploads/";
    
	public static String UploadMultiPartFile(String fileName, String filePath, String accessKey, String sAccessKey, String bucketName, String env) {

		AmazonS3ClientUtil s3ClientFactory = new AmazonS3ClientUtil();
/*		System.out.println("Bucket name "+bucketName+UPLOADS_DIR +" "+fileName+" "+filePath);
		System.out.println("access key "+accessKey+UPLOADS_DIR +" sAccessKey "+sAccessKey+" env "+env);   
*/		final AmazonS3 amazonS3 = s3ClientFactory.createClient(accessKey,sAccessKey );
		TransferManager tm = TransferManagerBuilder.standard()
				  .withS3Client(amazonS3)
				  .withMultipartUploadThreshold((long) (5 * 1024 * 1024))
				  .build();
		Upload upload = tm.upload(bucketName+UPLOADS_DIR+env,fileName, new File(filePath+File.separator+fileName));
		
		try {
		    upload.waitForCompletion();
		    return "success";
		}  catch(AmazonServiceException e) {
            // The call was transmitted successfully, but Amazon S3 couldn't process 
            // it, so it returned an error response.
            e.printStackTrace();
            return "Error Occured";
        }
        catch(SdkClientException e) {
            // Amazon S3 couldn't be contacted for a response, or the client  
            // couldn't parse the response from Amazon S3.
            e.printStackTrace();
            return "Error Occured";
        } catch (AmazonClientException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error Occured";
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error Occured";
		}
	}

	public static String UploadMultiPartFileLowLevel(String fileName, String filePath,  String accessKey, String sAccessKey, String bucketName) {

		AmazonS3ClientUtil s3ClientFactory = new AmazonS3ClientUtil();
		final AmazonS3 amazonS3 = s3ClientFactory.createClient(accessKey,sAccessKey );
        File file = new File(filePath+File.separator+fileName);
        long contentLength = file.length();
/*		System.out.println("Bucket name "+bucketName+UPLOADS_DIR +" "+fileName+" "+filePath);
		System.out.println("access key "+accessKey+UPLOADS_DIR +" sAccessKey "+sAccessKey+" bucketName "+bucketName);   
*/        long partSize = 100 * 1024 * 1024; //set part size to 100 MB
		try {
	           List<PartETag> partETags = new ArrayList<PartETag>();

	            // Initiate the multipart upload.
	            InitiateMultipartUploadRequest initRequest = new InitiateMultipartUploadRequest(bucketName, fileName);
	            InitiateMultipartUploadResult initResponse = amazonS3.initiateMultipartUpload(initRequest);

	            // Upload the file parts.
	            long filePosition = 0;
	            System.out.println("file contentLength "+contentLength);
	            for (int i = 1; filePosition < contentLength; i++) {
	                // Because the last part could be less than 5 MB, adjust the part size as needed.
	                partSize = Math.min(partSize, (contentLength - filePosition));

	                // Create the request to upload a part.
	                UploadPartRequest uploadRequest = new UploadPartRequest()
	                        .withBucketName(bucketName)
	                        .withKey(fileName)
	                        .withUploadId(initResponse.getUploadId())
	                        .withPartNumber(i)
	                        .withFileOffset(filePosition)
	                        .withFile(file)
	                        .withPartSize(partSize);

	                // Upload the part and add the response's ETag to our list.
	                UploadPartResult uploadResult = amazonS3.uploadPart(uploadRequest);
	                partETags.add(uploadResult.getPartETag());

	                filePosition += partSize;
	            }

	            // Complete the multipart upload.
	            CompleteMultipartUploadRequest compRequest = new CompleteMultipartUploadRequest(bucketName, fileName,
	                    initResponse.getUploadId(), partETags);
	            amazonS3.completeMultipartUpload(compRequest);
	            return "success";
		}  catch(AmazonServiceException e) {
            // The call was transmitted successfully, but Amazon S3 couldn't process 
            // it, so it returned an error response.
            e.printStackTrace();
            return "error";
        }
        catch(SdkClientException e) {
            // Amazon S3 couldn't be contacted for a response, or the client  
            // couldn't parse the response from Amazon S3.
            e.printStackTrace();
            return "error";
        } catch (AmazonClientException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "error";
		} 
	}
	

}
----------

package muleSoft.amazonUtils;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.auth.profile.ProfileCredentialsProvider;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3Client;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;

public class AmazonS3ClientUtil {
	
    private static final String clientRegion = "us-gov-west-1";

/*    BasicAWSCredentials awsCreds = null;
 
//	private final AmazonS3ClientBuilder  s3ClientBuilder = AmazonS3ClientBuilder.standard()
            .withCredentials(new AWSStaticCredentialsProvider(awsCreds))
            .withRegion(clientRegion);*/

    public AmazonS3 createClient(String accessKey, String sAccessKey) {

    		 BasicAWSCredentials awsCreds  = new BasicAWSCredentials(accessKey, sAccessKey);
    		 AmazonS3ClientBuilder  s3ClientBuilder = AmazonS3ClientBuilder.standard()
    		            .withCredentials(new AWSStaticCredentialsProvider(awsCreds))
    		            .withRegion(clientRegion);
    		return s3ClientBuilder.build();


    	}
}

