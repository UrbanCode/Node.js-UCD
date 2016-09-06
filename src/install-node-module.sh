#/**
# * � Copyright IBM Corporation 2014.
# * This is licensed under the following license.
# * The Eclipse Public 1.0 License (http://www.eclipse.org/legal/epl-v10.html)
# * U.S. Government Users Restricted Rights:  Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# */
#!/bin/bash

echo ===============================================================
echo "Checking npm is installed...."
echo ===============================================================
echo
echo "Checking Node.js is installed...."

echo "Checking if we have node and npm installed already..."
command -v npm
if [ $? -ne 0 ]; then
	echo
	echo "npm is not installed"
	echo
	exit 0
fi

echo
echo ===============================================================
echo Calling npm to install module
echo ===============================================================
echo

if [[ "$@" -ne 2 ]]; then
    echo >&2 "You must supply 2 arguments <module path> <module name>!"
    exit 1
fi
# check if target dir exists
if [[ ! -d "$1" ]]; then
    echo >&2 "$1 is does not exist so exiting..."
    exit 1
fi

cd $1

echo "Installing node module $2 to $1 ..."

if [[ -z $3 ]]; then
	echo "Installing latest version of $2..."
	npm install $2
else
	echo "Installing version $2 @ $3 ..."
	npm install $2@$3
fi

exit 0
