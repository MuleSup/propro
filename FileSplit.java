package s3withdirectory;


import java.io.BufferedOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;


/*
 * Class : FileSplit
 * Split a large source file into chunks for the purposes of uploading it into AWS S3
 */

public class FileSplit {

	/*
	 * Method : splitFile
	 * Inputs :
	 * inputFilePath - the path at which the input source file is located
	 * stagingFilePath - the path at which the chunks of the source file will be kept for uploading them into AWS S3
	 * bytesPerSplit - the chunk size for each split .
	 * Output :
	 * void
	 */
	public void splitFile(String inputFilePath, String stagingFilePath, Integer bytesPerSplit, String filePrefix, String fileExtension) throws Exception
    {

		//in case the bytesPerSplit argument has not been defined
		if(null == bytesPerSplit)
		{
			bytesPerSplit =  500*1024*1024;
		}


        //get the file name from the inputFilePath
        Path path  =  Paths.get(inputFilePath);
        Path fName = path.getFileName();

		      //read the source file from the input file path
        RandomAccessFile raf = new RandomAccessFile(inputFilePath, "r");

        long sourceSize = raf.length();  //the size in bytes for the input source file

        int numSplits = 1;   //default value of number of file chunks to be created

        //residual bytes for a file determining the size of the last chunk if the source file size is not an exact multiple of the bytesPerSplit
        long remainingBytes = 0;


        //split only if the source file size is more than the bytesPerSplit
        if(sourceSize >  bytesPerSplit)
        {
        	numSplits = (int)Math.floor(sourceSize / bytesPerSplit);
        	remainingBytes = sourceSize - numSplits*bytesPerSplit;
        }

        //split the file into chunks
        int maxReadBufferSize = 8 * 1024; //8KB
        for(int destIx=1; destIx <= numSplits; destIx++) {
            BufferedOutputStream bw = new BufferedOutputStream(new FileOutputStream(stagingFilePath + "/"+ filePrefix +".split."+ destIx + "." + fileExtension));
            if(bytesPerSplit > maxReadBufferSize) {
                long numReads = bytesPerSplit/maxReadBufferSize;
                long numRemainingRead = bytesPerSplit % maxReadBufferSize;
                for(int i=0; i<numReads; i++) {
                    readWrite(raf, bw, maxReadBufferSize);
                }
                if(numRemainingRead > 0) {
                    readWrite(raf, bw, numRemainingRead);
                }
            }else {
                readWrite(raf, bw, bytesPerSplit);
            }
            bw.close();
        }
        if(remainingBytes > 0) {
            BufferedOutputStream bw = new BufferedOutputStream(new FileOutputStream(stagingFilePath+"/"+filePrefix+".split."+(numSplits+1)+  "." + fileExtension));
            readWrite(raf, bw, remainingBytes);
            bw.close();
        }
            
            raf.close();
            
    }

     void readWrite(RandomAccessFile raf, BufferedOutputStream bw, long numBytes) throws IOException {
        byte[] buf = new byte[(int) numBytes];
        int val = raf.read(buf);
        if(val != -1) {
            bw.write(buf);
        }
    }

}
