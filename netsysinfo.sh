#!/bin/bash
#
# Flavor determination
#
DISTRO=""
NIC=`ip -o link show | awk '{print $2,$9}' | grep -v lo | cut -f1 -d":"`
declare -a FLAVAFLAV=("/etc/os-release"
			"/etc/redhat-release"
			"/etc/system-release"
			"/etc/rocky-release"
			"/etc/lsb-release"
			"/etc/debian_version"
)
#
# Network files determination
#
declare -a NETSTRINGS=("/etc/network/interfaces" # proper interfaces
			"/etc/resolv.conf" # proper DNS
			"/etc/network/interfaces.d" # for weird configs shit
			"/etc/NetworkManager" # for desktop users
			"/etc/netplan" # insert disdainful comment here
			"/etc/sysconfig/network-scripts" # for redhat/centos/rocky
			"/etc/sysconfig/network" # for SuSE/redhat/centos/rocky
			"/etc/systemd/networkd.conf" # insert disdainful comment here
			"/etc/systemd/resolvd.conf" # insert disdainful comment here
)
declare -a PACKAGES=("resolvconf*"
			"openresolv*"
			"netplan*"
			"networkd*"
			"ifupdown*"
			"sysconfig-netconfig*"
)
#
# string variable for appending to things that are empty
EMPTYSTATEMENT="...appears to be emtpy, not used."
#
# Existence function
#
CHKSIZE(){
	linesize=$(wc -l $1 | awk '{print $1}')
	echo $linesize
}
CHKPROTO(){
	if grep -qiF DHCP "$1";
	then
		echo -e '\t' "Appears to be set for DHCP..."
	fi
}
ISDIR (){
	# Check if the damned thing is a directory or not
	if [ -d "$1" ];
	then
		# return true
		return 0;
	else
		# return false
		return 1;
	fi
}
ISFILE (){
	# Test for existence of passed in file
	if [ -f "$1" ];
	then
		# return true
		return 0;
	else
		# return false
		return 1;
	fi
}
ISEMPTYDIR (){
	# Test for empty file
	if [ -z "$(ls -A $1)" ];
	then
		# return true
		return 0;
	else
		# return false
		return 1;
	fi
}

ISEMPTYFILE (){
	# Test for empty file
	# Uses what I refer to as backwards logic, either that or I'm just that burned out.
	if [ -s "$1" ];
	then
		# return false
		return 1;
	else
		# return true
		return 0;
	fi
}
#
SYSDBS (){
	# Checks for systemd shennagins.
	if grep -q systemd "$1";
	then
		return 0;
	else
		# return false
		return 1;
	fi
}
CHECKDIST(){
	# for all the elements in the FLAVAFLAV array
	for idist in "${FLAVAFLAV[@]}"
	do
		# check if it's a file or a directory
		if (ISFILE "$idist" || ISDIR "$idist");
		then
#			echo -e "Found : " $idist'\n'
			distrocheck=$(cat $idist | grep "PRETTY_NAME=" | sed 's/PRETTY_NAME=//' | sed 's/"//g')
			if [ ! -z "${distrocheck}" ];
			then
				DISTRO="$distrocheck"
			fi
		fi
	done
}
PACKAGECHECKS(){
	echo
	echo "$1"
	echo
	echo "--- Checking for installed packages ---"
	if [[ "$1" =~ "bian" || "$1" =~ "untu" ]];
	then
	{	
		for ipkg in "${PACKAGES[@]}"
		do
			apt -qq list $ipkg 2>/dev/null | grep install
		done
	}
	fi
	if [[ "$1" =~ "ocky" || "$1" =~ "ent" ]];
	then
	{	
		for ipkg in "${PACKAGES[@]}"
		do
			rpm -qa | grep $ipkg #2>/dev/null | grep install
		done
	}
	fi
	if [[ "$1" =~ "SUSE" || "$1" =~ "SuSE" ]];
	then
	{	
		for ipkg in "${PACKAGES[@]}"
		do
			rpm -qa | grep $ipkg #2>/dev/null | grep install
		done
	}
	fi

#	case $1 in
#		*"bian"*)
#			echo "Working"
#		*"untu"*)
#			echo "Ubuntu"
#		;;
#	esac
}
ACTUAL(){
	#
	#  Add case structure, possibly switch for this and future
	#
	# Decent human beings
	echo
	CHECKDIST
	echo "Network Interface Card name : " $NIC
	PACKAGECHECKS "$DISTRO"
	echo
	echo "--- Checking for files/directories ---"
	for inetst in "${NETSTRINGS[@]}"
	do
		# check if it's a file or a directory
		if (ISFILE "$inetst" || ISDIR "$inetst");
		then
			echo "Found : $inetst"
			# check if it's an empty file
			if (ISEMPTYFILE "$inetst");
			then
				echo -e '\t' $EMPTYSTATEMENT
			fi
			# check if it's an empty directory
			if (ISEMPTYDIR "$inetst");
			then
				echo -e '\t' "***"$inetst $EMPTYSTATEMENT
			else
				if [[ "$inetst" =~ "sysconfig" || "$inetst" =~ "network-scripts" || "$inetst" =~ "network" ]];
				then
					if (ISFILE "$inetst/ifcfg-$NIC");
					then
						syscfgnic="$inetst/ifcfg-$NIC"
						echo "Found : $syscfgnic"
						echo -e '\t' $(CHKSIZE $syscfgnic) "lines counted..."
						CHKPROTO "$syscfgnic"
					fi
				fi
				if [[ "$inetst" =~ "netplan" ]];
				then
					for shamls in `ls "$inetst"`
					do
						if (ISFILE "$inetst/$shamls");
						then
							nutplio="$inetst/$shamls"
							echo "Found : $nutplio"
							echo -e '\t' $(CHKSIZE $nutplio) "lines counted..."
							CHKPROTO "$nutplio"
						fi
					done
				fi

			fi
			
					
		fi
		# if it's a file
		if ISFILE "$inetst";
		then
			# check for systemd BS
			if (SYSDBS "$inetst");
			then
				echo -e '\t' "*** $inetst appears to have systemd manglement present."
			fi
			echo -e '\t' $(CHKSIZE $inetst) "lines counted..."
#			if "$inetst" =~ "resolv.conf";
#			then
#				for lines in `grep nameserver /etc/resolv.conf | wc -l`
#				dns=`grep nameserver /etc/resolv.conf | awk '{print $2}'`
#				if "$dns" =~ "127.0.0";
#				then
#					echo $dns " appears to be a local resolver.  This can be bad."
#				else
		fi


	done
}
echo
ACTUAL
