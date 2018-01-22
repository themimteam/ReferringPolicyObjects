# ReferringPolicyObjects
Show Referring Policy Objects in the Portal

# Author
Carol Wapshere

The scripts on this page help make FIM Portal Policy more self-documenting by showing where certain Policy objects are used. While an MPR will show the Sets and Workflows it uses it can be difficult to see the reverse relationship - ie being able to look at a  Set, Workflow or Email Template and see where it is being used.

The **Update-ReferringPolicy.ps1** script populates a multivalued string attributes called "ReferringPolicy" which lists the other Policy objects (such as MPRs and Sets) that use this object. This script must be run on a schedule.

The **Install-ReferringPolicy.ps1** sets up the prerequisites for the Update-ReferringPolicy script to work. This includes the Schema objects, MPRs and Search Scopes. See the comments at the top of the script for details.

Both scripts use the [functions library from Technet](http://technet.microsoft.com/en-us/library/ff720152(v=ws.10).aspx).

![Policy](https://github.com/themimteam/ReferringPolicyObjects/blob/master/image2014-2-18%2020_11_0.png)