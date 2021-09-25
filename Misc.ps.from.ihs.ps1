Hey Lars,

I’ve never used powershell, so you might want to adjust the below code so that it suits you, but it looks like I have it working. I think the problem you are having is PS’s reluctance to accept a self-signed certificate from AIQ. You need to over-ride it in your script.

Googling your exact error message led me to this… 
https://stackoverflow.com/questions/41618766/powershell-invoke-webrequest-fails-with-ssl-tls-secure-channel

Which , in turn led me here…
https://blog.ukotic.net/2017/08/15/could-not-establish-trust-relationship-for-the-ssltls-invoke-webrequest/ 

The code to make a successful call is then…. (Just paste this in and adjust the ‘user’ and ‘pass’ variables and let me know what you get). When I run it I get 401 – Unauthorized, because I don’t know the user and pass, but at least that means I have connected successfully.

if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore()

$user = 'user'
$pass = 'pass'

$pair = "$($user):$($pass)"

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}

Invoke-WebRequest  -Uri 'https://10.240.65.9/api/v2/gateways' -Headers $Headers


With the result being…

 

Thanks,
Geoff


From: Lars Petersson <Lars.Petersson@ihsmarkit.com> 
Sent: 08 June 2020 18:38
To: Geoff Baldry1 <Geoff.Baldry1@ihsmarkit.com>; John Escreet <John.Escreet@ihsmarkit.com>
Subject: RE: NetApp REST API access

The IP address I’m using is the one I got from @John:
 
I forgot I wasn’t getting an authentication token, but changing to get gives the same error:
 

Using your IP address and a nonsense address, all give the same error:
 

This seems to indicate that 11.240.65.9 is one that works from the server I am  using, and it tries to connect, but it couldn’t create a secure channel.
So back to either a network issue or a configuration issue on the NetApp device.
For reference, I’m trying to connect from our server LON6D2GITAPP885 with IP 10.44.213.24.
I ping test confirms that 11 works:
 

Although I have been led to believe that ping isn’t always enabled on our network, so isn’t a fool proof test.
Cheerio,
Lars

From: Geoff Baldry1 <Geoff.Baldry1@ihsmarkit.com> 
Sent: 08 June 2020 17:48
To: Lars Petersson <Lars.Petersson@ihsmarkit.com>; John Escreet <John.Escreet@ihsmarkit.com>
Subject: RE: NetApp REST API access

Looking again, the address you are using is only 1 octet out from the one I just offered….

You used 11.240.65.9, and I provided 10.240.65.9.

I think there is some kind of NAT translation that sometimes uses the 11. So maybe that is throwing it off?

Anyway, once you have overcome the network issues, this example is pretty good for powershell I think to get your request working, although I would start with a ‘GET’ on whatever end-point you are interested in.

$user = 'user'
$pass = 'pass'

$pair = "$($user):$($pass)"

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}

Invoke-WebRequest -Uri 'https://whatever' -Headers $Headers


From: Geoff Baldry1 
Sent: 08 June 2020 17:29
To: Lars Petersson <Lars.Petersson@ihsmarkit.com>; John Escreet <john.escreet@ihsmarkit.com>
Subject: RE: NetApp REST API access

Thanks Lars,

I have fully automated Pure Storage allocation here at IHS Markit, and I agree that its API is easy to use, and well documented. They feel very modern.

Have you checked that you are hitting the correct IP address? I don’t own or manage any of the infra we are discussing here – it’s all storage ops, but give this a go… (I’m not 100% sure, but I have this in a chat history related to AIQ)

 

I can’t see you passing a -headers parameter with your generated BASE64 authentication token still, but I suspect you have a network issue that takes precedence here. Once you have double-checked if that address you are using is right we can drill in a bit further with the actual API call…

Cheers,
Geoff

From: Lars Petersson <Lars.Petersson@ihsmarkit.com> 
Sent: 08 June 2020 17:06
To: Geoff Baldry1 <Geoff.Baldry1@ihsmarkit.com>; John Escreet <John.Escreet@ihsmarkit.com>
Subject: RE: NetApp REST API access

Hi Geoff,

Thanks for the help.
This also highlights why documentation should be language agnostic.
If their  documentation had been written with REST API in mind, rather than Java, then this would not have been a problem.
I would strongly recommend looking at Pure1’s documentation. Of all the vendor’s I’ve had to write PowerShell wrappers for, they easily have the best documentation, and don’t expect their audience to be Java or Python devs.
Because they write with the API in mind, any dev can take it and plug it into their language’s implementation, rather than first having to figure out a language they don’t know.

But anyway, I still have the same error as I did originally:
 

Cheerio,
Lars


From: Geoff Baldry1 <Geoff.Baldry1@ihsmarkit.com> 
Sent: 08 June 2020 15:26
To: John Escreet <John.Escreet@ihsmarkit.com>
Cc: Lars Petersson <Lars.Petersson@ihsmarkit.com>
Subject: RE: NetApp REST API access

Hello guys,

A quick look at the documentation for Netapp ActiveIQ Unified manager…
https://docs.netapp.com/ocum-97/index.jsp?topic=%2Fcom.netapp.doc.onc-um-api-dev%2FGUID-BE9B8950-76BD-4ACE-86AB-E42CFEEE976A.html

…and the hello_api server example code (https://docs.netapp.com/ocum-97/index.jsp?topic=%2Fcom.netapp.doc.onc-um-api-dev%2FGUID-BE9B8950-76BD-4ACE-86AB-E42CFEEE976A.html) shows that the API server uses the BASIC authentication mechanism.

This means that you need to send a BASE64 encoded string as your authentication – pretty old-skool. Here is a good explanation - https://en.wikipedia.org/wiki/Basic_access_authentication

The hello API server example is Java, but hold on tight if you don’t do Java, it’s not too hard to understand…

/*
      * * This forms the Base64 encoded string using the username and password *
      * provided by the user. This is required for HTTP Basic Authentication.
      */ private static String getAuthorizationString() {
            String userPassword = user + ":" + password;
            byte[] authEncodedBytes = Base64.encodeBase64(userPassword.getBytes());
            String authString = new String(authEncodedBytes);
            return authString;
      }


…see how is takes a username and password, concatenates them into “user” + “:” + “password”, then does a BASE64 encoding of them?

I’m really not a powershell guy, but this code snippet looks promising…
PS C:\Temp>$b  = [System.Text.Encoding]::UTF8.GetBytes("Hello World")
PS C:\Temp>[System.Convert]::ToBase64String($b)
SGVsbG8gV29ybGQ=

That is what you then need to provide to the API server in your request header….

Again in the example Java code they do this…

connection.setRequestProperty("Authorization", "Basic " + authString);

You can see that they are setting a request header (not in the body as your example attempted) called  “Authorization” to be the string “Basic <authstring>”, where authstring is your base64 encoded string.

Let me know how you get on. Also, I would double-check the IP address you are hitting. I don’t see a lot of stuff starting with 11. In my travels 😊

Shout if you lose the will to live and I’ll try to help some more.

Thanks,
Geoff




From: John Escreet <John.Escreet@ihsmarkit.com> 
Sent: 08 June 2020 14:51
To: Geoff Baldry1 <Geoff.Baldry1@ihsmarkit.com>
Cc: Lars Petersson <Lars.Petersson@ihsmarkit.com>
Subject: RE: NetApp REST API access

Hi there Geoff

Could you assist Lars please to get connected.

Thanks

John


From: Lars Petersson <Lars.Petersson@ihsmarkit.com> 
Sent: 05 June 2020 14:34
To: John Escreet <John.Escreet@ihsmarkit.com>
Subject: FW: NetApp REST API access

Just FYI…

From: Lars Petersson 
Sent: 05 June 2020 14:33
To: James Goring <James.Goring@ihsmarkit.com>
Cc: Bhola Gond <Bhola.Gond@ihsmarkit.com>; Abhishek Srivastava <Abhishek.Srivastava2@ihsmarkit.com>
Subject: RE: NetApp REST API access

Hi James,

Yes, I had looked at this and I don’t see anything about how to format the authorisation request.
Every vendor so far does it differently, and I have tried these different ways that work elsewhere.
For example:
$Body = @{
       username = <username>
       password = <password>
}
$JsonContentType = 'application/json'
$Uri = https://11.240.65.9:443/api/datacenter/svm/svms
Invoke-RestMethod -Method post -Uri $Uri -Body $Body -ContentType $JSONContentType

This gives me the following error:
 

This could also be either a network issue or a lack of permissions on the OCUM server.

I think it is most likely to be a lack of prior authentication.
Other vendors would have a url ending in "/oauth2/token" or similar which you would use to get an authentication token. 
And then you can start getting information from a url like https://11.240.65.9:443/api/datacenter/svm/svms. Unless NetApp expects you to provide the username and password in every single request.

If the account I’m using, power_bi, should definitely have this access, and there are no network blockers on our internal network, then it would probably be useful to run this by the NetApp SME.
It would probably be useful to do this straight away since that might solve this whole thing with a two line reply…

Cheerio,
Lars

From: James Goring <James.Goring@ihsmarkit.com> 
Sent: 05 June 2020 13:19
To: Lars Petersson <Lars.Petersson@ihsmarkit.com>
Cc: Bhola Gond <Bhola.Gond@ihsmarkit.com>; Abhishek Srivastava <Abhishek.Srivastava2@ihsmarkit.com>
Subject: RE: NetApp REST API access

Hi Lars

Attached is the REST API docs, have you already looked at this? also some details on the authentication. 

If this still doesn’t help let me know and I will ask our Netapp SME if there is something we are missing. 

Thanks
James
REST API access and authentication in Active IQ Unified Manager
The Active IQ Unified Manager REST API is accessible by using any web browser or programming platform that can issue HTTP requests. Unified Manager supports basic HTTP authentication mechanism. Before you call the Unified Manager REST API, you must authenticate a user.
REST access
You can use any web browser or programming platform that can issue HTTP requests to access the Unified Manager REST API. For example, after logging in to Unified Manager, you can type the URL in any browser to retrieve the attributes of all of the management stations, such as the management station name, key, and IP address.
Request
GET https://<IP address/hostname>:<port_number>/api/v2/datacenter/cluster/clusters
Response
{
  "records": [
    {
      "key": "4c6bf721-2e3f-11e9-a3e2-00a0985badbb:type=cluster,uuid=4c6bf721-2e3f-11e9-a3e2-00a0985badbb",
      "name": "fas8040-206-21",
      "uuid": "4c6bf721-2e3f-11e9-a3e2-00a0985badbb",
      "contact": null,
      "location": null,
      "version": {
        "full": "NetApp Release Dayblazer__9.5.0: Thu Jan 17 10:28:33 UTC 2019",
        "generation": 9,
        "major": 5,
        "minor": 0
      },
      "isSanOptimized": false,
      "management_ip": "10.226.207.25",
      "nodes": [
        {
          "key": "4c6bf721-2e3f-11e9-a3e2-00a0985badbb:type=cluster_node,uuid=12cf06cc-2e3a-11e9-b9b4-00a0985badbb",
          "uuid": "12cf06cc-2e3a-11e9-b9b4-00a0985badbb",
          "name": "fas8040-206-21-01",
          "_links": {
            "self": {
              "href": "/api/datacenter/cluster/nodes/4c6bf721-2e3f-11e9-a3e2-00a0985badbb:type=cluster_node,uuid=12cf06cc-2e3a-11e9-b9b4-00a0985badbb"
            }
          },
          "location": null,
          "version": {
            "full": "NetApp Release Dayblazer__9.5.0: Thu Jan 17 10:28:33 UTC 2019",
            "generation": 9,
            "major": 5,
            "minor": 0
          },
          "model": "FAS8040",
          "uptime": 13924095,
          "serial_number": "701424000157"
        },
        {
          "key": "4c6bf721-2e3f-11e9-a3e2-00a0985badbb:type=cluster_node,uuid=1ed606ed-2e3a-11e9-a270-00a0985bb9b7",
          "uuid": "1ed606ed-2e3a-11e9-a270-00a0985bb9b7",
          "name": "fas8040-206-21-02",
          "_links": {
            "self": {
              "href": "/api/datacenter/cluster/nodes/4c6bf721-2e3f-11e9-a3e2-00a0985badbb:type=cluster_node,uuid=1ed606ed-2e3a-11e9-a270-00a0985bb9b7"
            }
          },
          "location": null,
          "version": {
            "full": "NetApp Release Dayblazer__9.5.0: Thu Jan 17 10:28:33 UTC 2019",
            "generation": 9,
            "major": 5,
            "minor": 0
          },
          "model": "FAS8040",
          "uptime": 14012386,
          "serial_number": "701424000564"
        }
      ],
      "_links": {
        "self": {
          "href": "/api/datacenter/cluster/clusters/4c6bf721-2e3f-11e9-a3e2-00a0985badbb:type=cluster,uuid=4c6bf721-2e3f-11e9-a3e2-00a0985badbb"
        }
      }
    },
•	IP address/hostname is the IP address or the fully qualified domain name (FQDN) of the API server.
•	Port 443
443 is the default HTTPS port. You can customize the HTTPS port, if required.
To issue POST, PATCH, and DELETE HTTP requests from a web browser, you have to use browser plugins. You can also access the REST API by using scripting platforms such as cURL and Perl.

Authentication
Unified Manager supports the basic HTTP authentication scheme for APIs. For secure information flow (request and response), the REST APIs are accessible only over HTTPS. The API server provides a self-signed SSL certificate to all clients for server verification. This certificate can be replaced by a custom certificate (or CA certificate).
You must configure user access to the API server for invoking the REST APIs. The users can be local users (user profiles stored in the local database) or LDAP users (if you have configured the API server to authenticate over LDAP). You can manage user access by logging in to the Unified Manager Administration Console user interface.

Hello API server
The Hello API server is a sample program that demonstrates how to invoke a REST API in Active IQ Unified Manager using a simple REST client. The sample program provides you basic details about the API server in the JSON format (the server supports only application/json format).
The URI used is: https://<hostname>/api/datacenter/svm/svms. This sample code takes the following input parameters:
•	The API server IP address or FQDN
•	Optional: Port number (default: 443)
•	User name
•	Password
•	Response format (application/json)
To invoke REST APIs, you can also use other scripts such as Jersey and RESTEasy to write a Java REST client for Active IQ Unified Manager. You should be aware of the following considerations about the sample code:
•	Uses an HTTPS connection to Active IQ Unified Manager to invoke the specified REST URI
•	Ignores the certificate provided by Active IQ Unified Manager
•	Skips the host name verification during the handshake
•	Uses javax.net.ssl.HttpsURLConnection for a URI connection
•	Uses a third-party library (org.apache.commons.codec.binary.Base64) for constructing the Base64 encoded string used in the HTTP basic authentication


From: Lars Petersson <Lars.Petersson@ihsmarkit.com> 
Sent: 02 June 2020 16:52
To: James Goring <James.Goring@ihsmarkit.com>
Subject: NetApp REST API access

Hi James,

I have been trawling through the documentation, and can’t find anything on how to initially authenticate a REST session so I can pull out NetApp data.
Do you know if there is someone at NetApp I can contact about this, to get either some useful documentation, or technical help/guidance?

Cheerio,
Lars

From: James Goring <James.Goring@ihsmarkit.com> 
Sent: 29 April 2020 10:47
To: John Escreet <John.Escreet@ihsmarkit.com>
Cc: Lars Petersson <Lars.Petersson@ihsmarkit.com>; Bhola Gond <Bhola.Gond@ihsmarkit.com>
Subject: RE: NetApp

Hi John

In regards, API access for the Netapp OCUM server, this is currently being collected from VROP’s and Sightray, can you pull the data you need from there? Or would you prefer a direct link to the OnCommand server? 

Netapp don’t have anything like protection groups that allows us to group volumes etc, so I am in the process of trying to work out the best way to approach this from the netapp volume side.

Thanks
James 

From: John Escreet <John.Escreet@ihsmarkit.com> 
Sent: 28 April 2020 13:35
To: James Goring <James.Goring@ihsmarkit.com>
Cc: Lars Petersson <Lars.Petersson@ihsmarkit.com>
Subject: NetApp

Hi there James

After my weekly meeting with Dave, he has asked for a few things.

Trying to get my head around this , so if anything doesn't make sense please shout.

Can we get 
•	API access to one of the OnCommand products from NetApp so we can pull all the volumes/LUNs and their related SNAPs.

•	Add service ID to the names of all the protection groups. We might not be able to pull protection groups from Pure1 if that doesn’t work they need to add service ID to the names of volumes for Pure. - @Lars Petersson not sure what we are getting out of this system already.
•	Same thing with NetApp, what can you give us in terms of the protection groups with the service ID for LUNs and Volumes.

Let me know if you want to discuss further.

Thanks

John


