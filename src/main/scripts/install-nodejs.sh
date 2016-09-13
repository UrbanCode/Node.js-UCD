#
#  � Copyright IBM Corporation 2014, 2016.
#  This is licensed under the following license.
#  The Eclipse Public 1.0 License (http://www.eclipse.org/legal/epl-v10.html)
#  U.S. Government Users Restricted Rights:  Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
#!/bin/bash

# Define functions

rhelInstall() {
			echo "Ensure we have the EPEL installed"
			sudo rpm -Uvh http://download-i2.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
			echo "Calling yum to install nodejs and npm...."
			echo
			sudo yum -y install nodejs npm --enablerepo=epel
			if [ $? -ne 0 ]; then
				echo
				echo "YUM install has failed"
				echo
				exit 1
			fi
}

yumInstall() {
			echo "Calling yum to install nodejs and npm...."
			echo
			sudo yum -y install nodejs npm
			if [ $? -ne 0 ]; then
				echo
				echo "YUM install has failed"
				echo
				exit 1
			fi
}

zypperInstall() {
			echo "Calling zypper to install nodejs and npm...."
			echo
			sudo zypper -n ar http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_12.1/ NodeJSBuildService
			sudo zypper -n in nodejs nodejs-devel
			if [ $? -ne 0 ]; then
				echo
				echo "YUM install has failed"
				echo
				exit 1
			fi
}

aptgetInstall() {
			echo "Install pre-reqs of python, g++, make and checkinstall"
			sudo apt-get --fix-missing -q -y install python g++ make checkinstall
			src=$(mktemp -d) && cd $src
			echo "wget latest nodejs source..."
			wget -N http://nodejs.org/dist/node-latest.tar.gz
			if [ $? -ne 0 ]; then
				echo
				echo "Get of source has failed"
				echo
				exit 1
			fi
			echo "Untar the source..."
			tar xzvf node-latest.tar.gz && cd node-v*
			echo "Configure nodejs build..."
			./configure
			echo "Make and checkinstall nodejs..."
			fakeroot checkinstall -y --install=no --pkgversion $(echo $(pwd) | sed -n -re's/.+node-v(.+)$/\1/p') make -j$(($(nproc)+1)) install
			echo "Call dpkg to install nodejs..."
			sudo dpkg -i node_*
			if [ $? -ne 0 ]; then
				echo
				echo "Install has failed"
				echo
				exit 1
			fi
}


echo ================================================================
echo "Starting installation of Node.js and Node Package Mangaer (npm)"
echo ================================================================
echo
echo "Checking if we have node and npm installed already..."
command -v node
if [ $? -eq 0 ]; then
	echo
	echo "Node is installed"
	echo
	exit 0
fi

echo "Checking which Linux distro is installed on target server...."


detectedDistro="Unknown"
regExpLsbInfo="Description:[[:space:]]*([^ ]*)"
regExpLsbFile="/etc/(.*)[-_]"

if [ `which lsb_release 2>/dev/null` ]; then       # lsb_release available
   lsbInfo=`lsb_release -d`
   if [[ $lsbInfo =~ $regExpLsbInfo ]]; then
      detectedDistro=${BASH_REMATCH[1]}
   else
      echo "??? Should not occur: Don't find distro name in lsb_release output ???"
      exit 1
   fi

else                                               # lsb_release not available
   etcFiles=`ls /etc/*[-_]{release,version} 2>/dev/null`
   for file in $etcFiles; do
      if [[ $file =~ $regExpLsbFile ]]; then
         detectedDistro=${BASH_REMATCH[1]}
         break
      else
         echo "??? Should not occur: Don't find any etcFiles ???"
         exit 1
      fi
   done
fi

detectedDistro=`echo $detectedDistro | tr "[:upper:]" "[:lower:]"`

case $detectedDistro in
	suse) 	detectedDistro="opensuse" ;;
        linux)	detectedDistro="linuxmint" ;;
esac

echo
echo "Detected distro: $detectedDistro"
echo

case "$detectedDistro" in
        centos)
        	echo ===============================================================
			echo "Running Centos installation steps"
			echo ===============================================================
			echo
			yumInstall
			exit 0
            ;;
        fedora)
        	echo ===============================================================
			echo "Running Fedora installation steps"
			echo ===============================================================
			echo
			yumInstall
			exit 0
            ;;
        red)
        	echo ===============================================================
			echo "Running RedHat installation steps"
			echo ===============================================================
			echo
			rhelInstall
			exit 0
            ;;
        redhat)
        	echo ===============================================================
			echo "Running RedHat installation steps"
			echo ===============================================================
			echo
			rhelInstall
			exit 0
            ;;
        ubuntu)
        	echo ===============================================================
			echo "Running Ubuntu installation steps"
			echo ===============================================================
			echo
			aptgetInstall
			exit 0
            ;;
        debian)
        	echo ===============================================================
			echo "Running Debian installation steps"
			echo ===============================================================
			echo
			aptgetInstall
			exit 0
            ;;
        opensuse)
        	echo ===============================================================
			echo "Running OpenSUSE installation steps"
			echo ===============================================================
			echo
			zypperInstall
			exit 0
            ;;
        *)
            echo $"Linux distribution detected is unsupported by this plugin - sorry :-("
            exit 1

esac

exit 0
