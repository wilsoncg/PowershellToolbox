### Useful powershell scripts

###### Modules

* Script module ([Vmware-workflows](http://github.com/wilsoncg/PowershellToolbox/tree/master/Modules/vmware-workflows))
  * wraps REST web calls to Vsphere
  * Combine credential object with Authorization:Basic header

* Script module ([EdbAndTeamcity](http://github.com/wilsoncg/PowershellToolbox/tree/master/Modules/EdbAndTeamcity))
  * Wrap REST calls to teamcity
  * Fetching data from OData source
  * Example of working nuspec and powershell module specification
  * Supplemental scripts for copying/zipping files

###### IIS
* Load balanced setup
  * Install ARR 
  * Setup local server farm
  * Reverse proxy requests
  * Round robin local requests to multiple App pools

###### ARR links
* <http://www.iis.net/learn/extensions/installing-application-request-routing-arr/install-application-request-routing>
* <http://www.iis.net/learn/extensions/url-rewrite-module/reverse-proxy-with-url-rewrite-v2-and-application-request-routing>

###### AD group membership
* Query AD to find out what groups a user is a member of

###### SQL
* Use SMO to extract a full database ([DatabaseCreation](http://github.com/wilsoncg/PowershellToolbox/tree/master/Sql/DatabaseCreation))
* Update a local BIN range table ([BinRange](http://github.com/wilsoncg/PowershellToolbox/tree/master/Sql/BinRange))
* Examples of using Invoke-sqlcmd 

###### TFS
* Get TFS locked files ([Tfs-Get-Locks](http://github.com/wilsoncg/PowershellToolbox/tree/master/Tfs/tfs-get-locks.ps1))
  * Write C# code inside powershell
  * Reference and load TFS assemblies
  * Contact TFS server to find locked files

###### Xml
* Reading/Writing XML document (inserting/updating elements and attributes using .net XML objects)
* Simple MD5 generation using .net System.Security.Cryptography.MD5CryptoServiceProvider
* Visual studio command line initilization

###### Wiremock-transformer
* Working example of wiremock, using the wiremock-body-transformer plugin 
* Attempt to install wiremock as a service, running java and passing in the working directory into the service args
