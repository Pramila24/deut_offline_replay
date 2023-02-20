#!/bin/bash


echo "================================================="
echo "For help on usage, type: ./cafe_setup.sh -help"
echo "================================================="
Help()
{
    # Display Help
    echo "-------------------------------------------------------"
    echo "This shell script automatically sets up the necessary symbolic" 
    echo "links (or dir.) for the CaFe experiment based on which "
    echo "machine (ifarm, cdaq, local) the user is at."
    echo ""
    echo "Syntax: ./cafe_setup.sh [ -h | -f ]"
    echo ""
    echo "options:"
    echo "-help    Print this help display"
    echo ""
    echo "For users on IFARM ONLY: "
    echo "-f    ONLY use this option if you are running this shell script on ifarm. "
    echo "      This option selects filesystem in in which to read/write data " 
    echo "      from the CaFe experiment. "
    echo ""
    echo "      The optional arguments are: test, volatile, work, group"
    echo ""
    echo "      test: "
    echo "           this option will set up pre-determined raw/ ROOTfiles/ and REPORT_OUTPUT/ symbolic links" 
    echo "           for testing the CaFe replay and analysis scripts using existing data."
    echo ""
    echo "      volatile, work, group: "
    echo "            these options will set symbolic links to the corresponding filesystem "
    echo "            you would want to set these options depending on which stage of the analysis you are in "
    echo "            for example, use volatile if you are in the beginning stages of off-line analysis"
    echo ""
    echo "      See https://hallcweb.jlab.org/wiki/index.php/CaFe_Disk_Space " 
    echo "      for detailed information on each of these filesystems."  
    echo "        "
    echo "examples: ./cafe_setup.sh -f test"
    echo "          ./cafe_setup.sh -f volatile"
    echo "          ./cafe_setup.sh -f work" 
    echo "          ./cafe_setup.sh -f group"   
    echo "-------------------------------------------------------"    
}

set_hcana_link()
{
    if [[ -z $HCANALYZER ]]; then	
	echo ""
	echo "Environment variable: $HCANALYZER does NOT exist. "
	echo "Please make sure to do: source setup.sh(csh) in hcana first. " 
	echo ""
    else
	echo ""
	echo "Creating hcana symbolic link now  . . ."
	ln -sf $HCANALYZER"/hcana"
	ln -sf $HCANALYZER"/libHallC.so"
	ln -sf $HCANALYZER"/libHallC.so.0.90.0"
	echo ""
    fi    
}


# initialize machine flags to 0
# (depending on where this script gets called, it will turn ON one of these)
ifarm_flg=0
cdaq_flg=0



# define the optional arguments
while getopts ":h:f:" option; do
    case $option in
	h) # display Help
            Help	    
	    exit;;       	
	f) # Enter a filesystem name (only appplies for ifarm)
            fsys=$OPTARG;;
	\?) # Invalid option
            echo "Error: Invalid option"
	    Help
            exit;;
    esac
done


if echo $HOSTNAME | grep -q "ifarm"; then
    ifarm_flg=1
elif echo $HOSTNAME | grep -q "cdaq"; then
    cdaq_flg=1
fi


#if [[ ifarm_flg==0 &&  cdaq_flg==0 ]]; then
#    echo "***************************************"
#    echo " Did not recognize remote machine. "
#    echo " Please run: ./cafe_setup.sh -help "
#    echo " for help in running this script."
#    echo "***************************************"
#fi


#--- most recent raw data (irrespective of exp.)----
coda_raw="/net/cdaq/cdaql1data/coda/data/raw"
coda_raw_copiedtotape="/net/cdaq/cdaql1data/coda/data/raw.copiedtotape"

#--- define tape allocations ---
# make sure to point to the pionLT 2022 tape dir
# when we run the 1st part of cafe (heep and optics checks)
# since this 1st part will be taken during pionLT running.


# where CaFe raw data output to be replayed will be stored (.dat files(
# but these are NOT directly accessible, one would have to look for them in cache.
# tape_raw_dir="/mss/hallc/c-cafe-2022/raw"
#tape_raw_dir="/mss/hallc/c-pionlt/raw"
tape_raw_dir="/mss/hallc/c-deuteron/raw"



# tape volume for analysis output (simulation or replay output you want to keep long-term)
#tape_analysis_out="/mss/hallc/c-cafe-2022/analysis" 
tape_analysis_out="/mss/hallc/c-deuteron/analysis" 

#--- define cache allocations ---
# cafe
cache_raw_dir_cafe="/cache/hallc/c-cafe-2022/raw/"
cache_raw_dir_pionlt="/cache/hallc/c-pionlt/raw"
cache_raw_dir_deut="/cache/hallc/c-deuteron/raw"

# only for testing purposes (test raw data is here)
#volatile_raw_dir_test="/volatile/hallc/c-cafe-2022/test_raw"
volatile_raw_dir_test="/volatile/hallc/c-deuteron/test_raw"

#cache_analysis_out="/cache/hallc/c-cafe-2022/analysis/"
cache_analysis_out="/cache/hallc/c-deuteron/analysis/"

#=================================
# ifarm
# (off-line experiment analysis
# or testing the replay scripts)
#
# =================================
if [[ ifarm_flg -eq 1 ]]; then

    # source cafe_online_replay
    source setup.csh
    
    if [[ -z $fsys ]]; then
	echo ""
	echo " No optional argumnets provided "
	echo ""
	echo "----------------------------------------------------------------------"
	echo " For help using additional options, please run: ./deut_setup.sh -help "
	echo "----------------------------------------------------------------------"
	echo "Exiting NOW . . . "
	echo ""
	exit 1
    fi
    
    echo ""
    echo "Checking if necessary directories or symlinks exist in remote machine: " ${USER}"@"${HOSTNAME}". . ."
    echo ""
    
    # setup the symbolic links to hcana
    set_hcana_link      
   
    
    if [[ $fsys == "volatile" ]]; then	     
	echo ""
	echo 'Setting up symbolic links to volatile filesystem on ifarm . . .'
	base_dir_voli="/volatile/hallc/c-deuteron/"	

	echo "Creating dir $base_dir_voli$USER . . ."
	mkdir $base_dir_voli$USER
	
	unlink CACHE_LINKS/cache_cafe
	echo "Creating symlink to /cache/hallc/c-deuteron/raw/"
	ln -sf $cache_raw_dir_cafe cache_cafe
	
	unlink CACHE_LINKS/cache_pionlt
	echo "Creating symlink to /cache/hallc/c-pionlt/raw/"
	ln -sf $cache_raw_dir_pionlt cache_pionlt

	unlink REPORT_OUTPUT
	echo "Creating dir and symlink to $base_dir_voli$USER/REPORT_OUTPUT . . ."
	mkdir $base_dir_voli$USER"/REPORT_OUTPUT"
	ln -sf $base_dir_voli$USER"/REPORT_OUTPUT"

	unlink DEUT_OUTPUT
	echo "Creating dir and symlink to $base_dir_voli$USER/DEUT_OUTPUT . . ."
	mkdir $base_dir_voli$USER"/DEUT_OUTPUT"
	ln -sf $base_dir_voli$USER"/DEUT_OUTPUT" 
	mkdir -p "DEUT_OUTPUT/ROOT"
	mkdir -p "DEUT_OUTPUT/REPORT"
	mkdir -p "DEUT_OUTPUT/PDF" 

	unlink ROOTfiles
	echo "Creating dir and symlink to $base_dir_voli$USER/ROOTfiles . . ."
	mkdir $base_dir_voli$USER"/ROOTfiles"
	ln -sf $base_dir_voli$USER"/ROOTfiles"
	echo ""
	
    elif [[ $fsys == "work" ]]; then	     
	echo ""
	echo 'Setting up symbolic links to work filesystem on ifarm . . .'
	base_dir_work="/work/hallc/c-deuteron/"

	echo "Creating dir $base_dir_work$USER . . ."
	mkdir $base_dir_work$USER

	unlink raw
	echo "Creating symlink to $coda_raw"
	ln -sf $coda_raw
	
	unlink CACHE_LINKS/cache_cafe
	echo "Creating symlink to /cache/hallc/c-deuteron/raw/"
	ln -sf $cache_raw_dir_cafe cache_cafe
	
	unlink CACHE_LINKS/cache_pionlt
	echo "Creating symlink to /cache/hallc/c-pionlt/raw/"
	ln -sf $cache_raw_dir_pionlt cache_pionlt

	unlink REPORT_OUTPUT
	echo "Creating dir and symlink to $base_dir_work$USER/REPORT_OUTPUT . . ."
	mkdir $base_dir_work$USER"/REPORT_OUTPUT"
	ln -sf $base_dir_work$USER"/REPORT_OUTPUT"

	unlink DEUT_OUTPUT
	echo "Creating dir and symlink to $base_dir_work$USER/DEUT_OUTPUT . . ."	
	mkdir $base_dir_work$USER"/DEUT_OUTPUT" 
	ln -sf $base_dir_work$USER"/DEUT_OUTPUT"
	mkdir -p "DEUT_OUTPUT/ROOT"
	mkdir -p "DEUT_OUTPUT/REPORT"
	mkdir -p "DEUT_OUTPUT/PDF" 

	unlink ROOTfiles
	echo "Creating dir and symlink to $base_dir_work$USER/ROOTfiles . . ."
	mkdir $base_dir_work$USER"/ROOTfiles"
	ln -sf $base_dir_work$USER"/ROOTfiles"
	
	
    elif [[ $fsys == "group" ]]; then	     
	echo 'Setting up symbolic links to group filesystem on ifarm . . .'
	base_dir_group="/group/c-deuteron/"

	echo "Creating dir $base_dir_group$USER . . ."
	mkdir $base_dir_group$USER

	unlink raw
	echo "Creating symlink to $coda_raw"
	ln -sf $coda_raw

	unlink CACHE_LINKS/cache_cafe
	echo "Creating symlink to /cache/hallc/c-deuteron/raw/"
	ln -sf $cache_raw_dir_cafe cache_cafe
	
	unlink CACHE_LINKS/cache_pionlt
	echo "Creating symlink to /cache/hallc/c-pionlt/raw/"
	ln -sf $cache_raw_dir_pionlt cache_pionlt

	unlink REPORT_OUTPUT
	echo "Creating dir and symlink to $base_dir_group$USER/REPORT_OUTPUT . . ."
	mkdir $base_dir_group$USER"/REPORT_OUTPUT"
	ln -sf $base_dir_group$USER"/REPORT_OUTPUT"

	unlink DEUT_OUTPUT
	echo "Creating dir and symlink to $base_dir_group$USER/DEUT_OUTPUT . . ."
	mkdir $base_dir_group$USER"/DEUT_OUTPUT"
	ln -sf $base_dir_group$USER"/DEUT_OUTPUT"
	mkdir -p "DEUT_OUTPUT/ROOT"
	mkdir -p "DEUT_OUTPUT/REPORT"
	mkdir -p "DEUT_OUTPUT/PDF" 

	unlink ROOTfiles
	echo "Creating dir and symlink to $base_dir_group$USER/ROOTfiles . . ."
	mkdir $base_dir_group$USER"/ROOTfiles"
	ln -sf $base_dir_group$USER"/ROOTfiles"


	echo ""
    elif [[ $fsys == "test" ]]; then
	echo ""
	echo 'Setting up test symlinks on ifarm for testing cafe replay scripts . . .'
	base_dir="/lustre19/expphy/volatile/hallc/c-deuteron/"
	raw_dir=$base_dir'test_raw'  # this is read-only for users (since dir/ was created by cyero to put raw test files)

	base_dir_user="${base_dir}test_output_${USER}/"
	ROOTfiles_dir=${base_dir_user}"ROOTfiles"
	REPORT_OUTPUT_dir=$base_dir_user"REPORT_OUTPUT"
	DEUT_OUTPUT_dir=$base_dir_user"DEUT_OUTPUT"

	mkdir $base_dir_user
	mkdir $ROOTfiles_dir
	mkdir $REPORT_OUTPUT_dir
	mkdir $DEUT_OUTPUT_dir
	mkdir -p "DEUT_OUTPUT/ROOT"
	mkdir -p "DEUT_OUTPUT/REPORT"
	mkdir -p "DEUT_OUTPUT/PDF" 

	unlink raw
	ln -sf $volatile_raw_dir_test raw 	
	ln -sf $ROOTfiles_dir
	ln -sf $REPORT_OUTPUT_dir
	ln -sf $DEUT_OUTPUT_dir  
	echo ""
    fi
fi


#===============================
# cdaq cluster
# (online experiment analysis)
#===============================

if [[ cdaq_flg -eq 1 ]]; then

    echo "Checking if necessary directories or symlinks exist in remote machine: " ${USER}"@"${HOSTNAME}". . ."

    # source cafe_online_replay
    source setup.csh
    
    # setup the symbolic links to hcana
    set_hcana_link
    
    base_dir_cdaq="/net/cdaq/cdaql1data/cdaq/hallc-online-cafe2022"

    echo "Creating symlink to ${coda_raw}"
    ln -sf $coda_raw

    echo "Creating symlink to ${coda_raw_copiedtotape}"
    ln -sf $coda_raw_copiedtotape 

    echo "Creating symlink to $cache_raw_dir_cafe"
    ln -sf $cache_raw_dir_cafe cache_cafe
    
    echo "Creating symlink to $cache_raw_dir_pionlt"
    ln -sf $cache_raw_dir_cafe cache_pionlt

    echo "Creating dir and symlink to $base_dir_cdaq/REPORT_OUTPUT . . ."
    mkdir $base_dir_cdaq"/REPORT_OUTPUT"
    ln -sf $base_dir_cdaq"/REPORT_OUTPUT"
    
    echo "Creating dir and symlink to $base_dir_cdaq/ROOTfiles . . ."
    mkdir $base_dir_cdaq"/ROOTfiles"
    ln -sf $base_dir_cdaq"/ROOTfiles"

    echo "Creating dir and symlink to $base_dir_cdaq/HISTOGRAMS . . ."
    mkdir $base_dir_cdaq"/HISTOGRAMS"
    ln -sf $base_dir_cdaq"/HISTOGRAMS"

    echo "Creating dir and symlink to $base_dir_cdaq/DEUT_OUTPUT . . ."    
    mkdir $base_dir_cdaq"/DEUT_OUTPUT"
    ln -sf $base_dir_cdaq"/DEUT_OUTPUT"
    mkdir -p "DEUT_OUTPUT/ROOT"
    mkdir -p "DEUT_OUTPUT/REPORT"
    mkdir -p "DEUT_OUTPUT/PDF"
	
fi


#=============================
# local
# (the user local computer)
#=============================

# assume user is local if NOT on cdaq or ifarm
if [[ ifarm_flg==0 && cdaq_flg==0 ]]; then

    # source cafe_online_replay (usually shell script on local machine)
    source setup.sh
    
    # This function checks if necessary dir. exists, else it creates them 
    dir_arr=("raw" "ROOTfiles" "REPORT_OUTPUT" "HISTOGRAMS" "DEUT_OUTPUT" "CACHE_LINKS")
    	
    echo "Checking if necessary directories or symlinks exist in local machine: " ${USER}"@"${HOSTNAME}". . ."

    # setup the symbolic links to hcana
    set_hcana_link

    
    for i in "${dir_arr[@]}"	     
    do     
	if [[ -L "$i" && -d "$i" ]]; then
	    cmd="ls -l $i"
	    echo "$i is a symlink to a directory and it exists:"
	    eval $cmd 
	elif [[ -d "$i" ]]; then
	    echo "/$i directory exists"	
	else
	    echo "$i symlink is broken or /$i dir does not exist. Creating $i directory now . . ."
	    
	    cmd="mkdir $i"
	    echo $cmd
	    eval $cmd
	    echo "done!"
	fi    
    done
fi
