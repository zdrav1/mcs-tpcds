#!/bin/bash


#------------------------------------------------------------------------------------------------------------------------------------------
#   SCRIPT run-throughput-base.sh  is to
# - perform  tpc-ds throughput test
# - run  Q  number of query  streams  depend  on the  used Scale Factor
# - collect statistics  about  the number of executed Strems ,TCP-DS Throughput Test Start Time ,
#   TPC-DS Throughput Test  End time  and  tcp-ds performance Throughput time as defined in  TPC-DS Specification
#-------------------------------------------------------------------------------------------------------------------------------------------
#   USAGE
# - run  run-power.sh
#   with first parameter  Throughput Test number  ; by  default is 1
#   and second parameter  the name of the test environment
#   ./run-throughput-base.sh  1    # will run  Strems   S1 -  Sq
#   ./run-throughput-base.sh  2    # will run  Strems   Sq - 2*Sq

#-------------------------------------------------------------------------------------------------------------------------------------------



THROUGHPUT="$1"
TEST_DB="$2"
EXIT_CODE=0
call=0
tpid=$$
pid=()

if [[ -z ${THROUGHPUT} ]] ||  [[  ${THROUGHPUT} -ne 1 ]] &&  [[ ${THROUGHPUT} -ne 2 ]] ; then
        echo  "THROUGHPUT test number : < 1 > st | < 2 > nd is requred parameter "
        echo -e "\nERROR Throughput Test Number values are 1 or 2 \n When Throughput Test is run manually: \n  1 -- Run the Throughput Test imediately after the Power Test\n  2 -- Run the Throughput Test the after first Data Maintenace Tets\n "
        exit 1
fi
if [ -z "${TEST_DB}" ]; then
        TEST_DB='tpcds'
fi




source cfg
source functions

q_num=$(grep -cEv "^[[:space:]]*$" query_templates/templates.lst) 

if [[  -z $(ls streams/) ]]

       then
            echo -e "\nERROR Throughput Test cannot be started \n Query Streams are not found in the streams directory ; \nPlease execute at first the Power Test\n  " ; exit 1
       else
           all=$(ls -1 streams/ | wc -l)
           nthall=$(( $all  - 1 ))
           nth=$(( nthall / 2 ))
           if [[ $THROUGHPUT -eq 1 ]]
               then
                   str_fr=1
                   str_last=$nth
           elif [[ $THROUGHPUT -eq 2 ]]
               then
                   str_fr=$(( $nth +1 ))
                   str_last=$nthall
           else
               echo -e "\nERROR Throughput Test  Number values are 1 or 2 \n When  Throughput Test is run manually \n  1 -- Run the  Throughput Test imediately after the Power Test\n 2 --Run the  Throughput Test the  after first Data Maintenace Tets "
               exit 1
           fi
fi

        


__path_sql   #check if path to mysql tools is currect
__connect_sql ${MARIADB_MCS_HOST} ${MARIADB_MCS_USER} ${MARIADB_MCS_PASS} 1
__test_db    #chech if tpc-ds db exits on SUT
mkdir -p results
#rm -rf results/throughput
__connect_sql ${BASE_IQE_HOST} ${BASE_IQE_USER} ${BASE_IQE_PASS} &> /dev/null
if [[ $? -eq 252 ]] ; then mst=1 ; fi

DRl=$(date +"%s")
#t_now=$(GET_NOW)
t_now=$RNGSEED
start_time_load=$(__stamp_time )


echo -e "\n\n Throughput Test started at $start_time_load " | tee -a results/throughput
echo -e " with $nth parallel streams " | tee -a results/throughput
echo -e " each stream set is currentely composed by $q_num queries with randomely generated substitution parameters from tpc-ds query generator" | tee -a results/throughput
echo -e " and RNGSEED updated after execution of load test" | tee -a results/throughput
__locate_mts
mts_local=$?




function _exit_thr ()
{
local ex=$1
local rc

if [[ $ex -ne 0 ]]
    then
        if [[ $loth -eq 1 ]] 
             then 
                 ps aux | grep -v grep | grep -E ${rez} &> /dev/null
                 rc=$?
             else 
                 rc=0
        fi
        ppp=$(ps -p ${pid[*]} | tail -n +2 | wc -l )
        if [[ ! $rc -eq 0 ]] && [[ $nth -eq $ppp ]] 
            then 
                 echo -e "Warning: Collecting mcs throughput_${nth}.log failed, check the mariadb columnstore logs on SUT for details\n\n" | tee -a  results/throughput_${nth}.log results/throughput
                  _wait_th
            else
                 echo -e "Throughput Test failes" | tee -a results/throughput
                 echo -e "Check results/throughput_${nth}.log or mariadb columnstore logs on SUT for more details" | tee -a results/throughput
                 kill -9 ${pid[*]} &> /dev/null
                 kill -9 ${rez}
                 sleep 1
                 __terminate_query
                 EXIT_CODE=1
                 exit 1
             fi
fi
}




function _wait_th ()
{
local st 
wait -n
st=$? 
if [[ $st -ne 0 ]] 
     then 
         _exit_thr 1 
     else
         ppp=$(ps -p ${pid[*]} | tail -n +2 | wc -l ) 
         if [[ $ppp -ne 0 ]] 
              then  
                  _wait_th 
         fi
fi
}


wait --help 2>&1   | grep  "wait \[\-n\]" > /dev/null
w=$?    

# Collect logs if script is called standalone
Call_Depth=${#BASH_SOURCE[@]}
if [[ $Call_Depth = 1 ]] && [[ $w -eq 0 ]]
     then
         loth=1
         if [[ $mts_local -eq 0 ]]
              then
                  tail -n 0 -f  /var/log/mariadb/columnstore/debug.log >   results/th_${nth}.log &

                  rez=$!
                  mts=0
              else
                  ssh -q -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${MARIADB_MCS_HOST} -l ${MARIADB_SSH_USER} 'ls /var/log/mariadb/columnstore/debug.log' > /dev/null
                  rr=$? ;if [[ ! $rr -eq 0 ]] ; then echo -e "\nUnable to access /var/log/mariadb/columnstore/debug.log on ${MARIADB_MCS_HOST} with MARIADB_SSH_USER ${MARIADB_SSH_USER};\nenable ssh key login and/or set variable MARIADB_SSH_USER in cfg "; exit 1 ; fi 
       
                  ssh -q -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${MARIADB_MCS_HOST} -l ${MARIADB_SSH_USER} 'tail -n 0 -f  /var/log/mariadb/columnstore/debug.log ' &> results/throughput_${nth}.log &
                  rez=$!
                  mts=1
         fi
fi



j=0
 for  (( i=$str_fr ; i<=$str_last ; i++ ))
       do
            echo $i
            $SQL -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} ${TEST_DB} < streams/query_${i}.sql  &
            pid[j]=$!
            j=$(( $j + 1 ))
       done
pids=${#pid[*]}


if [[ $w -eq 0 ]] 
     then
          _wait_th 
     else
           wait 
fi



 end_time_load=$(__stamp_time )
 echo -e " Throughput Test finished at $end_time_load " | tee -a results/throughput



DUR1=$(DURATION $DRl)
if [[ $loth -eq 1 ]] ; then kill -9 ${rez} ; fi 
echo -e " Throughput Test was executed over $nth Query Streams on SUT $TESTENV with $DUR1" | tee -a results/throughput
echo -e "\n  Throughput  Test finished on SUT $TESTENV  at $end_time_load" | tee -a results/throughput
tcp_ds_throughput_time=$(__tcp_time)
echo -e "start_time_throughput\t$start_time_load " | tee -a results/throughput
echo -e "end_time_throughput\t$end_time_load " | tee -a results/throughput
echo -e "tcp_ds_throughput_time\t$tcp_ds_throughput_time"  | tee -a results/throughput


if [[ $mst -eq 1 ]] ; then
     if [[ ${THROUGHPUT} -eq 1 ]]
          then
              throughput_1_mdb_time
          else
              throughput_2_mdb_time
     fi
fi
#exit "$EXIT_CODE"

