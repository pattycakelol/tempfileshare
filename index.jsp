<%@page import="java.io.*, java.util.UUID, java.sql.*" %>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <title>File Upload Test</title>
    </head>
    <body>
        <h1>Uploading files</h1>
        <form name="uploadForm" action="/tempfileshare/" method="POST" enctype="multipart/form-data">
            <input type="file" name="file" value="" width="100"/><br><br>
            <button type="submit"  value="Upload File" name="submit">Upload File</button><br>

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
                String uniqueID = UUID.randomUUID().toString().replace("-", "").substring(0, 5);
                File ff = new File(uploadDir + "/" + uniqueID);

                // if directory does not exist (and it shouldnt since it uses UUID), make directory

                // this loop should never be run, but just in case, we will change the UUID in case a duplicate is found
                while (ff.exists()) { 
                    uniqueID = UUID.randomUUID().toString().replace("-", "").substring(0, 5);
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
                    String query = "insert into uploads (file_id, filename, type, path) values (?,?,?,?)";
                    PreparedStatement ps = conn.prepareStatement(query);
                    ps.setString(1, uniqueID);
                    ps.setString(2, saveFile.substring(0, saveFile.lastIndexOf(".")));
                    ps.setString(3, saveFile.substring(saveFile.lastIndexOf(".") + 1, saveFile.length()));
                    ps.setString(4, uploadDir + "/" + uniqueID + "/" + saveFile);
                    ps.execute();
                    conn.close();
                    
                    // generate new index to download the file
                    String downloadPath = uploadDir + "/" + uniqueID;
                    File downloadIndex = new File(uploadDir + "/" + uniqueID + "/index.jsp");
                    PrintWriter out1 = new PrintWriter(new FileWriter(downloadIndex));
                    out1.println("<" + "%@page import=\"java.io.*, java.sql.*\"%" + ">");
                    out1.println("<" + "%");

                    // delete from database
                    out1.println("Class.forName(\"com.mysql.jdbc.Driver\");");
                    out1.println("Connection conn = DriverManager.getConnection(\"jdbc:mysql://localhost:3306/upload_db\", \"root\", \"root\");");
                    out1.println("String query = \"select downloads from uploads where file_id = ?\";");
                    out1.println("PreparedStatement ps = conn.prepareStatement(query);");
                    out1.println("ps.setString(1, \"" + uniqueID + "\");");
                    out1.println("ResultSet rs = ps.executeQuery();");
                    out1.println("if (rs.next()) {");
                    out1.println("    if (rs.getInt(\"downloads\"));"); // uniqueID exists in db, continue with download
                    out1.println("} else out.print(\"This file has expired.\");");
                    out1.println("");
                    out1.println("");
                    out1.println("conn.close();");

                    // download file
                    out1.println("String file = \"" + uploadDir + "/" + uniqueID + "/" + saveFile + "\";");
                    out1.println("response.setContentType(\"application/octet-stream\");");
                    out1.println("String header = \"Atachment; Filename=\\\"" + saveFile + "\\\"\";");
                    out1.println("response.setHeader(\"Content-Disposition\", header);");
                    out1.println("File downloadFile = new File(file);") ;
                    out1.println("InputStream in = null;");
                    out1.println("ServletOutputStream outs = response.getOutputStream();");
                    out1.println("try {");
                    out1.println("    in = new BufferedInputStream(new FileInputStream(file));");
                    out1.println("    int ch;");
                    out1.println("    while((ch = in.read()) != -1) {");
                    out1.println("        outs.print((char)ch);");
                    out1.println("    }");
                    out1.println("}");
                    out1.println("finally {");
                    out1.println("    if (in != null) in.close();");
                    out1.println("}");
                    out1.println("outs.flush();");
                    out1.println("outs.close();");
                    out1.println("in.close();");
                    out1.println("%" + ">");

                    // delete actual file from server, but keep the file folder with the generated index
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