# tempfileshare

This website allows users to upload files to the website's database.
The catch is that these files are temporary; they are limited to 1 download per link created for that file (may add feature to change # of times file can be downloaded)

To do:
1) create separate page for download links
2) file download + deletion of link once the download occurs
3) convert JSP to servlet (jsp only used to make sure it works first)
4) make it look pretty
5) deployment (I'm thinking AWS?)

QoL:
 - add encryption of file uploaded to database
 - add # of allowed downloads for file (however, I don't want to have it stay forever since I have limited space)
 - add option to select an expiration date (may have a default expiration date on every file uploaded as well)
