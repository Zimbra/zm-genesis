#!/bin/bash

#following are the basic packages required 

function install_basic {
   
   #Check if the system has basic linux packages and install the missing ones
   
   req_pkgs=(wget curl zip zlib1g openssl man)
   echo "Checking for packages: $req_pkgs"
   for pkg in "${req_pkgs[@]}"
   do
      echo "For package: $pkg"
      python -mplatform | grep -qi Ubuntu && dpkg -l $pkg|| rpm -qa $pkg
      exit_status=$?
      if [ "$exit_status" -ne "0" ]; then
         echo "$pkg is not installed, please install before continuing..."
         exit "$exit_status"
      else
         echo "$pkg is installed on the system, no action required"
      fi
   
   done
}


function install_rubygems {
   
   #install rubygems
   echo "Starting installation of ruby gems, this could take a while."

   install_rubygems=(
      "sudo gpg --keyserver keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3"
      "curl -sSL https://get.rvm.io | bash -s stable"
      "source /etc/profile.d/rvm.sh"
      "source /usr/local/rvm/bin/rvm"
      "rvm install 2.0.0 --with-zlib-directory=/usr/local/rvm/usr --with-openssl-directory=/usr/local/rvm/usr"
      "rvm --default use 2.0.0"
      "gem install soap4r-spox log4r net-ldap json httpclient"
      
   )
   for cmd in "${install_rubygems[@]}"; do
      eval "$cmd" || {
      retval=$?
      echo "Error occured while running $cmd; Exiting..."
      exit "$retval"
    }
   done
}  

 	
read -r -p "Starting with genesis setup, Continue? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
   #update existing repositories and upgrade packages
   #apt-get update; apt-get upgrade 
   install_basic
   install_rubygems
   echo "SETUP COMPLETE!"
else
   echo "Exiting..."
fi
