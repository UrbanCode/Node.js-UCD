/**
 * © Copyright IBM Corporation 2014.  
 * This is licensed under the following license.
 * The Eclipse Public 1.0 License (http://www.eclipse.org/legal/epl-v10.html)
 * U.S. Government Users Restricted Rights:  Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp. 
 */

package com.urbancode.air.plugin.amazonec2;

//sdk imports
import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.model.DescribeInstancesRequest;
import com.amazonaws.services.ec2.model.DescribeInstancesResult;
import com.amazonaws.services.ec2.model.Instance;
import com.amazonaws.services.ec2.model.InstanceState;
import com.amazonaws.services.ec2.model.Placement;
import com.amazonaws.services.ec2.model.Reservation;
import com.amazonaws.services.ec2.model.RunInstancesRequest;
import com.amazonaws.services.ec2.model.RunInstancesResult;


public class AmazonEC2Helper {
    def apTool;
    def ec2;

    public AmazonEC2Helper(def apTool, AmazonEC2 ec2) {
        this.apTool = apTool;
        this.ec2 = ec2;
    }

    public def startInstances(def ami, def number, def instanceType, def keyPair, def zone,
            def group, def options) {
        RunInstancesRequest req = new RunInstancesRequest()
                                  .withImageId(ami)
                                  .withMinCount(Integer.valueOf(number))
                                  .withMaxCount(Integer.valueOf(number))
                                  .withInstanceType(instanceType);
        
        if (keyPair) {
            req = req.withKeyName(keyPair);
        }
        
        if (zone) {
            Placement placement = new Placement(zone);
            req = req.withPlacement(placement);
        }
        
        if (group) {
            req = req.withSecurityGroups(group.split(','));
        }
        
        if (options) {
            req = req.withUserData(options);
        }
        
        println "Creating $number instances of $ami";
        RunInstancesResult result = ec2.runInstances(req);
        List<Instance> instances = result.getReservation().getInstances();
        
        def insts = instances.collect { return it.getInstanceId() };
                                  
        apTool.setOutputProperty("instances", insts.join(','));
        
        return insts;
    }

    public def gatherInstanceDetails(def instanceIds) {
        def dnses = [];
        def privateIPs = [];
        
        DescribeInstancesRequest describeRequest = new DescribeInstancesRequest().withInstanceIds(instanceIds);
        DescribeInstancesResult describeResult = ec2.describeInstances(describeRequest);
        
        List<Instance> describeInstances = new ArrayList<Instance>();
        List<Reservation> reservations = describeResult.getReservations();
        reservations.each { reservation ->
            List<Instance> currInstances = reservation.getInstances();
            describeInstances.addAll(currInstances);
        }
        
        instanceIds.each { instanceId ->
            Instance instance = describeInstances.find { it.getInstanceId() == instanceId };
            dnses << instance.getPublicDnsName();
            privateIPs << instance.getPrivateIpAddress();
        }
            
        apTool.setOutputProperty("dns", dnses.join(','));
        apTool.setOutputProperty("privateIPs", privateIPs.join(','));
    }
    
    public def waitForInstances(def instanceIds, def timeout, def status) {
        def badStates = [:];
        for (def inst : instanceIds) {
            badStates.put(inst, "bad");
        }
        
        Long startTime = System.currentTimeMillis();
        while (!badStates.isEmpty() && System.currentTimeMillis() - startTime < timeout) {
            println "Waiting for instances to achieve "+status+" state: "+badStates
            
            def newBadStates = [:];
            def badInstanceIds = badStates.collect { it.getKey() };
        
            DescribeInstancesRequest req = new DescribeInstancesRequest().withInstanceIds(instanceIds);
            DescribeInstancesResult result = ec2.describeInstances(req);
        
            List<Instance> instances = new ArrayList<Instance>();
            List<Reservation> reservations = result.getReservations();
            reservations.each { reservation ->
                List<Instance> currInstances = reservation.getInstances();
                instances.addAll(currInstances);
            }
        
            badInstanceIds.each { instanceId ->
                Instance instance = instances.find { it.getInstanceId() == instanceId };
        
                if (!instance.getState().getName().equals(status)) {
                    newBadStates.put(instanceId, status);
                }
            }
            badStates = newBadStates;
            Thread.sleep(5000);
        }

        if (badStates.isEmpty()) {
            println "All instances are in state: "+status;
        }
        else {
            println "The following instances were not in the expected state after the timeout: "+badStates;
            System.exit(1);
        }
    }
}

