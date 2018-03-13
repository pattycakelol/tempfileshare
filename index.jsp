<%@page import="java.io.*, java.util.UUID, java.sql.*" %>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <title>File Upload Test</title>
    </head>
    <body>
        <h1>Uploading files</h1>
        <form name="uploadForm" action="index.jsp" method="POST" enctype="multipart/form-data">
            <input type="file" name="file" value="" width="100"/><br><br>
            <input type="submit" value="Upload File" name="submit" /><br>

            <% 
            String saveFile = new String();
            String contentType = request.getContentType();

            if((contentType != null) && (contentType.indexOf("multipart/form-data") >= 0)) {

                // convert uploaded file into array of bytes

                DataInputStream in = new DataInputStream(request.getInputStream());

                int formDataLength = request.getContentLength();
                byte dataBytes[] = new byte[formDataLength];

                int byteRead = 0;
                int totalBytesRead = 0;

                while(totalBytesRead < formDataLength) {
                    byteRead = in.read(dataBytes, totalBytesRead, formDataLength);
                    totalBytesRead += byteRead;
                }

                // convert array of bytes into string

                String file = new String(dataBytes);

                // save file to machine

                saveFile = file.substring(file.indexOf("filename=\"") + 10 ); // get the name of the file
                saveFile = saveFile.substring(0, saveFile.indexOf("\n"));
                saveFile = saveFile.substring(saveFile.lastIndexOf("\\") + 1, saveFile.indexOf("\""));

                int lastIndex = contentType.lastIndexOf("=");

                String boundary = contentType.substring(lastIndex + 1, contentType.length());

                int pos;

                // very specific
                pos = file.indexOf("filename=\"");
                pos = file.indexOf("\n", pos) + 1;
                pos = file.indexOf("\n", pos) + 1;
                pos = file.indexOf("\n", pos) + 1;
                
                int boundaryLocation = file.indexOf(boundary, pos) - 4;

                int startPos = ((file.substring(0, pos)).getBytes()).length;
                int endPos = ((file.substring(0, boundaryLocation)).getBytes()).length;

                // make unique dir for the file
                String uploadDir = "C:/xampp/tomcat/webapps/tempfileshare";
                String uniqueID = UUID.randomUUID().toString().replace("-", "");
                File ff = new File(uploadDir + "/" + uniqueID);

                // if directory does not exist (and it shouldnt since it uses UUID), make directory

                // this loop should never be run, but just in case, we will change the UUID in case a duplicate is found
                while (ff.exists()) { 
                    uniqueID = UUID.randomUUID().toString().replace("-", "");
                    ff = new File(uploadDir + "/" + uniqueID + "/" + saveFile);
                }

                // directory does not exist, create it:
                ff.mkdirs();
                ff = new File(uploadDir + "/" + uniqueID + "/" + saveFile);
                try {
                    // put file onto machine
                    FileOutputStream fileOut = new FileOutputStream(ff);
                    fileOut.write(dataBytes, startPos, (endPos - startPos));
                    fileOut.flush();
                    fileOut.close();

                    // save file information into database
                    
                    Class.forName("com.mysql.jdbc.Driver");
                    Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/upload_db", "root", "root");
                    String query = "insert into uploads (filename, type, path) values (?,?,?)";
                    PreparedStatement ps = conn.prepareStatement(query);
                    ps.setString(1, saveFile.substring(0, saveFile.lastIndexOf(".")));
                    ps.setString(2, saveFile.substring(saveFile.lastIndexOf(".") + 1, saveFile.length()));
                    ps.setString(3, (uploadDir + "/" + uniqueID + "/" + saveFile).replace("/", "\\"));
                    ps.execute();
                    conn.close();
                    
                    // generate new file for the 
                    String downloadPath = uploadDir + "/" + uniqueID;
                    File downloadIndex = new File(uploadDir + "/" + uniqueID + "/index.jsp");
                    PrintWriter out1 = new PrintWriter(new FileWriter(downloadIndex));
                    out1.write("<html>");

                    out1.write("<head>");
                    out1.write("<title>dl: " + uniqueID + "</title>");
                    out1.write("</head>");

                    out1.write("<body>");
                    out1.write("test index file for download: " + uniqueID);
                    out1.write("</body>");
                    
                    out1.write("</html>");
                    out1.close();

                } catch (FileNotFoundException fnfe) {
                    out.print("Please select a file to upload<br>"); // dont want to show file paths to the user
                } catch (Exception e) {
                    out.print(e);
                }

            }
            %>

        </form>
    </body>
</html>