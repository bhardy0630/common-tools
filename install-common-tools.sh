#!/bin/bash
#
# Add-on script that installs common tools, and maybe the sec stuff as well.
#
#centver=$(cat /etc/redhat-release | cut -d' ' -f2) # test this. Test this hard on every version of Cent.
echo "Installing common tools for" $Centver
echo "Performing pre-script maintenance on RPM DB and Yum..."
#if (centos version equals 5)
  echo "Fixing CentOS 5 repo issue..."
  #download the repo file with "historical" link to /etc/yum.repos.d/ 
  #and rename Centos-Base.repo
  yum clean all
#elif (cent 6)
  #whatever for that
#elif (cent 7)
  #set flag for Cent 7 that runs the special freshclam sed config? or move to sec tools script.
#else
  echo "Something went wrong, not CentOS? Exiting."
  exit
fi
############################### do it:
# rebuild RPM DB
yum clean all
yum makecache fast
yum -y install epel-release
yum -y install atop ncdu
##################### More to come
