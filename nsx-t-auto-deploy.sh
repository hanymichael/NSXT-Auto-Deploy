##!/bin/bash
if [ -z "$4" ]
  then
    echo "Arguments supplied not complete. Please provide the NSX-T release and build numbers."
    echo "Prereqs: ovftool, jq and sshpass utilities."
    echo "Syntax: ./nsx-t-auto-deploy.sh <NSX_RELEASE> <NSX_MAIN_BUILD> <UNIFIED_APP_BUILD> <EDGE_NODE_BUILD>"
    echo "Example: ./nsx-t-auto-deploy.sh 2.4.1.0.0 13622466 13622477 13622482"
    exit 1
fi

echo ""
echo "███╗   ██╗███████╗██╗  ██╗  ████████╗     █████╗ ██╗   ██╗████████╗ ██████╗       ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗"
echo "████╗  ██║██╔════╝╚██╗██╔╝  ╚══██╔══╝    ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗      ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝"
echo "██╔██╗ ██║███████╗ ╚███╔╝█████╗██║       ███████║██║   ██║   ██║   ██║   ██║█████╗██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ "
echo "██║╚██╗██║╚════██║ ██╔██╗╚════╝██║       ██╔══██║██║   ██║   ██║   ██║   ██║╚════╝██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  "
echo "██║ ╚████║███████║██╔╝ ██╗     ██║       ██║  ██║╚██████╔╝   ██║   ╚██████╔╝      ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   "
echo "╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝     ╚═╝       ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝       ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   "

# The source configuration of the script
source sample.conf

echo ""
echo "╔════════════════════════════╗"
echo "║- Author: Hany Michael      ║"
echo "║- eMail: hany@vmware.com    ║"
echo "║- Compatibility: NSX-T 2.4  ║"
echo "╚════════════════════════════╝"
echo ""
echo ""

echo "╔═══════════════════════════════════════════════════════╗"
echo "║ NSX-T Release: $1                                    ║"
echo "║ NSX-T General Build: $2                         ║"
echo "║ NSX-T Manager Build: $3                         ║"
echo "║ NSX-T Edge Node Build: $4                       ║"
echo "╚═══════════════════════════════════════════════════════╝"


#######################################
######### VALIDATION FUNCTIONS ########
#######################################

function prereqTOOLs() {
    $1
    if [ $? -eq 127 ]; then
        echo -e "\e[1m\e[91m[-FAIL-]-> \e[0m$1 is either not installed or not in the path of the script"
        exit 1
    fi
}


function ovaURLs() {
  if [ $nsxMgrBuildweb_URL == NULL ] || [ $nsxCtrlBuildweb_URL == NULL ] || [ $nsxEdgeBuildweb_URL == NULL ]; then
    echo "\e[1m\e[91m[FAIL]-> \e[0mNSX-T OVA locations are not set. Please edit the configuration file (sample.conf) and add the location of the OVA(s)"
    exit 1
  else
    echo -e "\e[1m\e[32m[SUCCESS]-> \e[0m\e[1mNSX-T OVA locations are set.\e[0m"
  fi
  
}

function validateTASK() {
  if [ $1 -eq 0 ]; then
   echo -e "\e[1m\e[32m[SUCCESS]-> \e[0m\e[1m$2\e[0m"
   sed -i 's/DeploymentTask'$3'_Status=.*/DeploymentTask'$3'_Status=1/' sample.conf
  else
   echo -e "\e[1m\e[91m[FAIL]-> $2\e[0m"
   exit 1
  fi
}


#######################################
############# START SCRIPT ############
#######################################

echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ Checking Prereqs and if OVA URLs are set              ║"
echo "╚═══════════════════════════════════════════════════════╝"
prereqTOOLs "ovftool -v"

prereqTOOLs "jq -V"

prereqTOOLs "sshpass -V"

ovaURLs


echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ NSX-T Unified Appliance Download and Deployment       ║"
echo "╚═══════════════════════════════════════════════════════╝"
export task_num=01
if [ $DeploymentTask01_Status -eq 0 ]; then
# Downloading the OVA
wget -P /tmp/ $nsxMgrBuildweb_URL'nsx-unified-appliance-'$1'.'$3'.ova'
validateTASK $? "$DeploymentTask01_Name" $task_num
else
echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask01_Name\e[0m"
fi

export task_num=02
if [ $DeploymentTask02_Status -eq 0 ]; then
# Deploying the appliance 
ovftool --noSSLVerify --skipManifestCheck --powerOn --deploymentOption=$mgrformfactor --diskMode=thin --acceptAllEulas --allowExtraConfig --ipProtocol=IPv4 --ipAllocationPolicy=$ipAllocationPolicy  --datastore=$mgrdatastore  --network=$mgrnetwork --name=$mgrname --prop:nsx_hostname=$mgrhostname01 --prop:nsx_role="NSX Manager" --prop:nsx_ip_0=$mgrip --prop:nsx_netmask_0=$mgrnetmask  --prop:nsx_gateway_0=$mgrgw  --prop:nsx_dns1_0=$mgrdns  --prop:nsx_ntp_0=$mgrntp --prop:nsx_passwd_0=$mgrpasswd  --prop:nsx_cli_passwd_0=$mgrpasswd --prop:nsx_cli_audit_passwd_0=$mgrpasswd --prop:nsx_isSSHEnabled=$mgrssh --prop:nsx_allowSSHRootLogin=$mgrroot --X:logFile=nsxt-manager-ovf.log --X:logLevel=$logLevel /tmp/'nsx-unified-appliance-'$1'.'$3'.ova' vi://$vcadmin:$vcpass@$vcip/?ip=$mgresxhost
validateTASK $? "$DeploymentTask02_Name" $task_num
else
echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask02_Name\e[0m"
fi

echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ NSX-T Unified Appliance Clustering                    ║"
echo "╚═══════════════════════════════════════════════════════╝"
if [ $nsxcluster == "true" ]; then
    export task_num=03
    echo "Clustering option enabled."
    if [ $DeploymentTask03_Status -eq 0 ]; then
    echo " Deploying applaince 2 .."
    ovftool --noSSLVerify --skipManifestCheck --powerOn --deploymentOption=$mgrformfactor --diskMode=thin --acceptAllEulas --allowExtraConfig --ipProtocol=IPv4 --ipAllocationPolicy=$ipAllocationPolicy02  --datastore=$mgrdatastore02  --network=$mgrnetwork02 --name=$mgrname02 --prop:nsx_hostname=$mgrhostname02 --prop:nsx_role="nsx-manager nsx-controller" --prop:nsx_ip_0=$mgrip02 --prop:nsx_netmask_0=$mgrnetmask02  --prop:nsx_gateway_0=$mgrgw02  --prop:nsx_dns1_0=$mgrdns02  --prop:nsx_ntp_0=$mgrntp02 --prop:nsx_passwd_0=$mgrpasswd02  --prop:nsx_cli_passwd_0=$mgrpasswd02 --prop:nsx_cli_audit_passwd_0=$mgrpasswd02 --prop:nsx_isSSHEnabled=$mgrssh02 --prop:nsx_allowSSHRootLogin=$mgrroot02 --X:logFile=nsxt-manager-ovf.log --X:logLevel=$logLevel02 /tmp/'nsx-unified-appliance-'$1'.'$3'.ova' vi://$vcadmin:$vcpass@$vcip/?ip=$mgresxhost02
    validateTASK $? "$DeploymentTask03_Name" $task_num
    else
    echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask03_Name\e[0m"
    fi

    if [ $DeploymentTask04_Status -eq 0 ]; then
    export task_num=04
    echo "Clustering option enabled. Deploying applaince 3 .."
    ovftool --noSSLVerify --skipManifestCheck --powerOn --deploymentOption=$mgrformfactor --diskMode=thin --acceptAllEulas --allowExtraConfig --ipProtocol=IPv4 --ipAllocationPolicy=$ipAllocationPolicy03  --datastore=$mgrdatastore03  --network=$mgrnetwork03 --name=$mgrname03 --prop:nsx_hostname=$mgrhostname03 --prop:nsx_role="nsx-manager nsx-controller" --prop:nsx_ip_0=$mgrip03 --prop:nsx_netmask_0=$mgrnetmask03  --prop:nsx_gateway_0=$mgrgw03  --prop:nsx_dns1_0=$mgrdns03  --prop:nsx_ntp_0=$mgrntp03 --prop:nsx_passwd_0=$mgrpasswd03  --prop:nsx_cli_passwd_0=$mgrpasswd03 --prop:nsx_cli_audit_passwd_0=$mgrpasswd03 --prop:nsx_isSSHEnabled=$mgrssh03 --prop:nsx_allowSSHRootLogin=$mgrroot03 --X:logFile=nsxt-manager-ovf.log --X:logLevel=$logLevel03 /tmp/'nsx-unified-appliance-'$1'.'$3'.ova' vi://$vcadmin:$vcpass@$vcip/?ip=$mgresxhost03
    validateTASK $? "$DeploymentTask04_Name" $task_num
    else
    echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask04_Name\e[0m"
    fi
else 
    echo "NSX Clustering is not selected."
fi

echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ Deploying the NSX-T Edge01 OVA                        ║"
echo "╚═══════════════════════════════════════════════════════╝"
if [ $DeploymentTask05_Status -eq 0 ]; then
export task_num=05
# Downloading the OVA
wget -P /tmp/ $nsxEdgeBuildweb_URL'nsx-edge-'$1'.'$4'.ova'
validateTASK $? "$DeploymentTask05_Name" $task_num
else
echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask05_Name\e[0m"
fi

if [ $DeploymentTask06_Status -eq 0 ]; then
export task_num=06
# Deploying the appliance
ovftool --name=$e1name --deploymentOption=$e1deploymentsize --X:injectOvfEnv --X:logFile=e1ovftool.log --allowExtraConfig --datastore=$e1datastore --net:"Network 0=$e1net0" --net:"Network 1=$e1net1" --net:"Network 2=$e1net2" --net:"Network 3=$e1net3" --acceptAllEulas --noSSLVerify --diskMode=thin --powerOn --prop:nsx_ip_0=$e1ip --prop:nsx_netmask_0=$e1netmask --prop:nsx_gateway_0=$e1gw --prop:nsx_dns1_0=$e1dns --prop:nsx_domain_0=$e1domain --prop:nsx_ntp_0=$e1ntp --prop:nsx_isSSHEnabled=$e1ssh --prop:nsx_allowSSHRootLogin=$e1root --prop:nsx_passwd_0=$e1passwd --prop:nsx_cli_passwd_0=$e1passwd --prop:nsx_cli_audit_passwd_0=$e1passwd --prop:nsx_hostname=$e1hostname /tmp/'nsx-edge-'$1'.'$4'.ova' vi://$vcadmin:$vcpass@$vcip/?ip=$e1esxhost 
validateTASK $? "$DeploymentTask06_Name" $task_num
else
echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask06_Name\e[0m"
fi

echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ Deploying the NSX-T Edge02 OVA                        ║"
echo "╚═══════════════════════════════════════════════════════╝"
if [ $DeploymentTask07_Status -eq 0 ]; then
export task_num=07
# Deploying the appliance
ovftool --name=$e2name --deploymentOption=$e2deploymentsize --X:injectOvfEnv --X:logFile=e2ovftool.log --allowExtraConfig --datastore=$e2datastore --net:"Network 0=$e1net0" --net:"Network 1=$e1net1" --net:"Network 2=$e1net2" --net:"Network 3=$e1net3" --acceptAllEulas --noSSLVerify --diskMode=thin --powerOn --prop:nsx_ip_0=$e2ip --prop:nsx_netmask_0=$e2netmask --prop:nsx_gateway_0=$e2gw --prop:nsx_dns1_0=$e2dns --prop:nsx_domain_0=$e2domain --prop:nsx_ntp_0=$e2ntp --prop:nsx_isSSHEnabled=$e2ssh --prop:nsx_allowSSHRootLogin=$e2root --prop:nsx_passwd_0=$e2passwd --prop:nsx_cli_passwd_0=$e2passwd --prop:nsx_cli_audit_passwd_0=$e2passwd --prop:nsx_hostname=$e2hostname /tmp/'nsx-edge-'$1'.'$4'.ova' vi://$vcadmin:$vcpass@$vcip/?ip=$e2esxhost
validateTASK $? "$DeploymentTask07_Name" $task_num
echo "Sleeping for 3 minutes for all appliances to bootup..."
sleep 3m
else
echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask07_Name\e[0m"
fi

echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ Getting NSX-T Manager Thumbprint                      ║"
echo "╚═══════════════════════════════════════════════════════╝"
# if [ $DeploymentTask08_Status -eq 0 ]; then
# export task_num=08
thumbp=$(sshpass -p $mgrpasswd ssh admin@$mgrip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "get certificate api thumbprint")
validateTASK $? "$DeploymentTask08_Name" $task_num
# else
# echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask08_Name\e[0m"
# fi

echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ Joining Edge Node 01 to the NSX-T Manager             ║"
echo "╚═══════════════════════════════════════════════════════╝"
if [ $DeploymentTask09_Status -eq 0 ]; then
export task_num=09
e1joinresult=$(sshpass -p $e1passwd ssh admin@$e1ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "join management-plane $mgrip username admin password $mgrpasswd thumbprint $thumbp")
validateTASK $? "$DeploymentTask09_Name" $task_num
echo -e "\e[0m$e1joinresult"
else
echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask09_Name\e[0m"
fi

echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ Joining Edge Node 02 to the NSX-T Manager             ║"
echo "╚═══════════════════════════════════════════════════════╝"
if [ $DeploymentTask10_Status -eq 0 ]; then
export task_num=10
e2joinresult=$(sshpass -p $e2passwd ssh admin@$e2ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "join management-plane $mgrip username admin password $mgrpasswd thumbprint $thumbp")
validateTASK $? "$DeploymentTask10_Name" $task_num
echo -e "\e[0m$e2joinresult"
else
echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask10_Name\e[0m"
fi

echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ Adding vCenter as a Compute Manager                   ║"
echo "╚═══════════════════════════════════════════════════════╝"
if [ $nsxcomputemgr == "true" ]; then
    if [ $DeploymentTask11_Status -eq 0 ]; then
    export task_num=11
    addcomputemgr=$(curl --silent  -k -u admin:$mgrpasswd -X POST -H "Content-Type: application/json" -d '{"server": "'$vchost'", "origin_type": "vCenter", "credential" : { "credential_type" : "UsernamePasswordLoginCredential",  "username": "'$vcadmin'",     "password": "'$vcpass'", "thumbprint": "'$vcthumbprint'"  } }'  "https://$mgrip/api/v1/fabric/compute-managers")
    validateTASK $? "$DeploymentTask11_Name" $task_num
    computemanagerid=$(echo $addcomputemgr | jq '.id' -r)
    echo "vCenter Compute Manager ID: $computemanagerid"
    else
    echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask11_Name\e[0m"
    fi
else 
    echo "Compute Managers config. is not selected."
fi

echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ Registering the NSX-T Nodes to the cluster            ║"
echo "╚═══════════════════════════════════════════════════════╝"
if [ $nsxcluster == "true" ]; then
    if [ $DeploymentTask12_Status -eq 0 ]; then
    export task_num=12
    nsxclusterid=$(curl --silent  -k -u admin:$mgrpasswd -X GET -H "Content-Type: application/json" "https://$mgrip/api/v1/cluster")
    validateTASK $? "$DeploymentTask12_Name" $task_num
    export nsxclusterid=$(echo $nsxclusterid | jq '.cluster_id' -r)
    echo "NSX-T Cluster ID: $nsxclusterid"
    else
    echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask12_Name\e[0m"
    fi

    if [ $DeploymentTask13_Status -eq 0 ]; then
    echo "----------------"
    echo "Registering Second Node.."    
    export task_num=13
    thumbp=$(sshpass -p $mgrpasswd ssh admin@$mgrip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "get certificate api thumbprint")
    node1joinresult=$(sshpass -p $mgrpasswd02 ssh admin@$mgrip02 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "join $mgrip cluster-id $nsxclusterid thumbprint $thumbp username admin password $mgrpasswd")
    validateTASK $? "$DeploymentTask13_Name" $task_num
    echo -e "\e[0m$node1joinresult"
    else
    echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask13_Name\e[0m"
    fi

    if [ $DeploymentTask14_Status -eq 0 ]; then
    echo "----------------"
    echo "Registering Third Node.."
    export task_num=14
    thumbp=$(sshpass -p $mgrpasswd ssh admin@$mgrip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "get certificate api thumbprint")
    node2joinresult=$(sshpass -p $mgrpasswd03 ssh admin@$mgrip03 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "join $mgrip cluster-id $nsxclusterid thumbprint $thumbp username admin password $mgrpasswd")
    validateTASK $? "$DeploymentTask14_Name" $task_num
    echo -e "\e[0m$node2joinresult"
    else
    echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask14_Name\e[0m"
    fi

echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║ Setting the Virtual IP                                ║"
echo "╚═══════════════════════════════════════════════════════╝"
    if [ $DeploymentTask15_Status -eq 0 ]; then
    export task_num=15
    setvirtualip=$(curl --silent  -k -u admin:$mgrpasswd -X POST "https://$mgrip/api/v1/cluster/api-virtual-ip?action=set_virtual_ip&ip_address=$nsxvip")
    validateTASK $? "$DeploymentTask15_Name" $task_num
    else
    echo -e "\e[32m[DONE]-> \e[0m\e[1m$DeploymentTask15_Name\e[0m"
    fi
else
    echo "NSX Clustering is not selected."
fi

echo ' ____  _  _   ___   ___  ____  ____  ____'
echo '/ ___)/ )( \ / __) / __)(  __)/ ___)/ ___)'
echo '\___ \) \/ (( (__ ( (__  ) _) \___ \\___ \'
echo '(____/\____/ \___) \___)(____)(____/(____/'
