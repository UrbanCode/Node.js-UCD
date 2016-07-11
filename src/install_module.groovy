/**
 * © Copyright IBM Corporation 2014.  
 * This is licensed under the following license.
 * The Eclipse Public 1.0 License (http://www.eclipse.org/legal/epl-v10.html)
 * U.S. Government Users Restricted Rights:  Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp. 
 */

import java.io.*;
import java.util.*;

def isEmpty(value) {
	return value == null || value.equals("")
}

//////////////////////MAIN////////////////////////
final def isWindows = (System.getProperty('os.name') =~ /(?i)windows/).find()
final def workDir = new File('.').absolutePath
final def compName = new File(".").getCanonicalFile().name //this gets resolved to component name
final def props = new Properties()
final def inputPropsFile = new File(args[0])
final def inputPropsStream = null
try {
    inputPropsStream = new FileInputStream(inputPropsFile)
    props.load(inputPropsStream)
}
catch (IOException e) {
    throw new RuntimeException(e)
}

def modName = props['moduleName']
def modPath = props['modulePath']

scriptFile = getClass().protectionDomain.codeSource.location.path
def scriptDir = new File(scriptFile).parent
println scriptDir
def script = "/install-node-module.sh"

def cmd = scriptDir + script

def commandArgs = [cmd, modName, modPath];

println commandArgs.join(' ');
def procBuilder = new ProcessBuilder(commandArgs);

if (isWindows) {
	def envMap = procBuilder.environment();
	envMap.put("PROFILE_CONFIG_ACTION","true");
}

def statusProc = procBuilder.start();
def outPrint = new PrintStream(System.out, true);
statusProc.waitForProcessOutput(outPrint, outPrint);
System.exit(statusProc.exitValue());
