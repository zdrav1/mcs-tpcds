#!/bin/bash


#------------------------------------------------------------------------------------------------------------------------------------------
#   SCRIPT run-power.sh  is to
# - generate N number of query streams depend on the Scale Factor
# - perform  tpc-ds power test
# - collect statistics  about  TCP-DS Power Test Start Time ,
#   TPC-DS Power Test  End time  and  tcp-ds performance power time as defined in  TPC-DS Specification
#-------------------------------------------------------------------------------------------------------------------------------------------
#   USAGE
# - run  run-power.sh
#   with first parameter  tpc-ds  SCALE factor   , measured units  1G
#   ./ load-validate-mdb.sh   1000
#-------------------------------------------------------------------------------------------------------------------------------------------


SCALE="$1"
MODE="$2"
TEST_DB="$3"




if [ -z "${MODE}" ]; then
        MODE=tpc-ds
fi
if [ -z "${SCALE}" ]; then
        echo -e "  SCALE FACTOR is requred parameters "
        exit 1
fi
if [ -z "${TEST_DB}" ]; then
        TEST_DB='tpcds'
fi



TEST_DB=${TEST_DB}_${SCALE}
source functions
source cfg
__path_sql   #check if path to mysql tools is currect
__connect_sql ${MARIADB_MCS_HOST} ${MARIADB_MCS_USER} ${MARIADB_MCS_PASS} 1
__test_db    #chech if tpc-ds db exits on SUT
mkdir -p results
__connect_sql ${BASE_IQE_HOST} ${BASE_IQE_USER} ${BASE_IQE_PASS} &> /dev/null
if [[ $? -eq 252 ]] ; then mst=1 ; fi



   if [[ $MODE == tpc-ds ]] ; then


        case $SCALE in
             1)
                STREAMS=3
            ;;
             10)
                STREAMS=5
            ;;

            100)
                STREAMS=7
            ;;
            300)
                STREAMS=9
            ;;
            1000)
                 STREAMS=11
            ;;
            3000)
                 STREAMS=13
            ;;
            10000)
                 STREAMS=15
            ;;
            30000)
                 STREAMS=17
            ;;
            100000)
                 STREAMS=19
            ;;





            *)
              echo -e "
                      Invalide Scale Factor $SCALE
                      Scale Factors are 1 10 100 1000 3000 10000 30000 100000 "
                      exit 1


        esac


rm -rf streams
mkdir -p  streams
cdir=$PWD
cd query_templates
./dsqgen_v2.6.0  -DIALECT ${cdir}/query_templates/ansi  -INPUT templates.lst -RNGSEED $RNGSEED  -STREAMS $STREAMS -SCALE $SCALE  -OUTPUT_DIR ../streams  -VERBOSE Y
#./dsqgen_v2.5.0    -INPUT templates.lst -RNGSEED $RNGSEED  -STREAMS $STREAMS -SCALE $SCALE  -OUTPUT_DIR ../streams  -VERBOSE Y
cd ..


DRl=$(date +"%s")
#t_now=$(GET_NOW)
t_now=$RNGSEED
start_time_load=$(__stamp_time )




echo -e " Power Query Stream 0 started at $start_time_load " | tee -a results/power
$SQL -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} ${TEST_DB} < streams/query_0.sql
 power="$?"
if [[ ! $power -eq 0 ]]
     then
         echo -e "\n\n\n ERROR  Power Test failed . " | tee -a results/power
         exit 1
     fi
echo -e "\n\n\n Power Query Stream 0 finished at $(date "+%Y-%m-%d %H:%M:%S,%3N") "





DUR1=$(DURATION $DRl)
echo -e "Power Test was executed with $DUR1"
end_time_load=$(__stamp_time )
echo -e "\n Power Test finished on SUT $TESTENV  at $end_time_load"
tcp_ds_power_time=$(__tcp_time)
if [[ $mst -eq 1 ]] ; then power_mdb_time ; fi



echo -e "TPC_DS Power Test was executed with Query Stream query_0 on SUT $TESTENV with $DUR1" > results/power
echo -e "start_time_power\t$start_time_load " >> results/power
echo -e "end_time_power\t$end_time_load " >> results/power
echo -e "tcp_ds_power_time\t$tcp_ds_power_time"  >>  results/power
cat results/power



fi
###End  run-power tpc-sd  mode





           if [[ $MODE == debug ]] ; then

######################################################################################EEEEEEEEEEEEEEEEEE
#echo -e "\n Power Test started on SUT $TESTENV  at $start_time_load"
mode=2

#echo -e " One by one query parsing started at  $(date "+%Y-%m-%d %H:%M:%S,%3N") "

#for i in $( ls -1 query_templates/validate_mdb_query_templates | grep -v set | sort -n  -k1.6) ; do
#    query=${i%.*}

#echo $query | tee -a foo


#  mysql -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} ${TEST_DB} <  query_templates/validate_mdb_query_templates/$i |& tee -a foo


#  done

#echo -e " One by one query parsing finished at  $(date "+%Y-%m-%d %H:%M:%S,%3N") "
########EEEEEEEEEEEEEEEEEEEEEEEEEEEEEE#E




           fi


####End  run-power debug mode


        if [[ $MODE == cold ]] ; then
             warm_ms=NULL
             t_now=$RNGSEED
             all=1
             rm -f results/q_c_errors
             echo -e "Starting  query execution from list PASS_MCS in mode $MODE on test DB ${TEST_DB} loaded with SCALE FACTOR $SCALE\n"
             echo -e "query_id\tcold_time "  >>  results/q_cold

             while read query
                  do
                     while [[  ${all} -ne ${query//[!0-9]/} ]] && [[ $all -ne 100 ]]
                            do
                              echo -e "query${all}\t-"  | tee -a results/q_cold
                              all=$(( $all + 1 ))
                            done
                     if [[  ${all} -eq ${query//[!0-9]/} ]] ; then all=$(( $all + 1 )) ; fi
 
#Usinf calFlushCache() before each cold query to clear out any block cache in the PMs.
                     $SQL -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS}  -e "select calFlushCache(); " > /dev/null
                     DRmms=$(date +%s%3N)
#One by one query parsing  and collect  performance of the benchmarking queries in cold  mode
                     $SQL  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} ${TEST_DB}  < query_templates/validate_mdb_query_templates/$query.sql |& tee  results/query

                     cat results/query | grep ERROR
                     if [[ ! $? -eq 0 ]] ; then
                          er=0
                          cold_ms=$(DMS $DRmms)
                     else
                          echo $query >> results/q_c_errors
                          cat results/query >> results/q_c_errors
                          cold_ms=0 ;er=1;ctrl=1

                     fi
                     if [[ $er -eq 1 ]] ; then  echo -e "${query}\tError"  | tee -a results/q_cold
                     else
                     echo -e "${query}\t${cold_ms}"  | tee -a results/q_cold
                     fi
                     if [[ $mst -eq 1 ]] ; then query_time_1 ; fi
                  done<query_templates/validate_mdb_query_templates/PASS_MCS
               rm -f results/query
               if [[ $ctrl -eq 1 ]] ; then
                   echo -e "\n\n\nError in query parsing on test DB ${TEST_DB} loaded with SCALE FACTOR $SCALE"
               fi
               echo -e "Test results from query execution in mode $MODE vs test DB ${TEST_DB} loaded with SCALE FACTOR $SCALE"
               cat results/q_cold
       fi

####End  run-power cold  mode







        if [[ ${MODE/:*} == warm ]] ; then
             declare -A q_warm
             num_warm=$(echo $MODE | cut -d ":" -f2)
             if [[ -z $num_warm ]] || [[ $num_warm == warm ]]  ;then  num_warm=5 ; fi
             rm -f results/q_w_errors

             cold_ms=NULL
             t_now=$RNGSEED
             all=1
             echo -e "\nPerformance Measurements of TPC_DS benchmarking queries in MCS Warm mode\n"  | tee  results/q_warm_${num_warm}
             echo -e "Query Performance Warm Time calculated over $num_warm consecutive executions after warming up"  >> results/q_warm_${num_warm}
             echo -e "Measured on TEST_DB $TEST_DB loaded with Scale Factor ${SCALE}" >> results/q_warm_${num_warm}
             num_str=$( for j in $(seq $num_warm ); do echo -en "exec_$j "; done)
             echo -e "\nquery_id\terr_num\t$num_str\twarm_mean_time[ms]" >> results/q_warm_${num_warm}
#One by one query parsing  repeating each query N times and collect  performance of the benchmarking queries in warm mode
             while read i
                  do
                     while [[  ${all} -ne ${i//[!0-9]/} ]] && [[ $all -ne 100 ]]
                            do
                              echo -e "query${all}\t-\t- - - - - \t-"  | tee -a results/q_warm_${num_warm}
                              all=$(( $all + 1 ))
                            done
                     if [[  ${all} -eq ${i//[!0-9]/} ]] ; then all=$(( $all + 1 )) ; fi

                    q_warm+=(["query${i}"]=0)
#Run query once in cold mode before starting warm mode execution
#Using calFlushCache() before each cold query to clear out any block cache in the PMs.
                     echo -e "\nCleaning Cache and warming up query $i "
                      $SQL -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS}  -e "select calFlushCache(); " 1> /dev/null  |& grep -v "Warning: Using a password on the command line interface can be insecure."

                      $SQL -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} ${TEST_DB} < query_templates/validate_mdb_query_templates/${i}.sql 1> /dev/null |& grep -v "Warning: Using a password on the command line interface can be insecure."


#Start warm mode execution
                     echo -e "\nMeasure performance time in warm mode of query $i "
                     echo -e "\nQuery $i will be executed consecutively $num_warm times"

                     err_count=0
                     exec_warm=$num_warm
                     rez_wrm=()
                     for (( qw=0 ; qw < $num_warm ; qw ++ ))
                           do
                             DRmms=$(date +%s%3N)

                              $SQL -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} ${TEST_DB} < query_templates/validate_mdb_query_templates/${i}.sql &>  results/query
                             cat results/query | grep ERROR
                             if [[ ! $? -eq 0 ]] ; then
                                  er=0
                                  warm_ms=$(DMS $DRmms)
                                  rez_wrm[$qw]=$warm_ms
                                  q_warm["query${i}"]=$(( q_warm["query${i}"] + $warm_ms ))
                             else
                                  echo $i >> results/q_w_errors
                                  cat results/query >> results/q_w_errors
                                  warm_ms=0 ;er=1;ctrl=1
                                  rez_wrm[$qw]='Error'
                                  err_count=$(( err_count + 1 ))
                                  exec_warm=$(( $exec_warm - 1 ))

                              fi
                           done
                     if [[ ! $exec_warm -eq 0 ]] ; then
                          warm_mean_ms=$(echo  "${q_warm["query${i}"]}" $exec_warm | awk '{print $1 / $2 }' )
                     else warm_mean_ms='Error'
                     fi
                     echo -e "${i}\t${err_count}\t"${rez_wrm[*]}"\t${warm_mean_ms}"  | tee -a results/q_warm_${num_warm}


                     #query_time_1
                  done<query_templates/validate_mdb_query_templates/PASS_MCS
             rm -f results/query
             if [[ $ctrl -eq 1 ]] ; then
                  echo -e "\n\n\nError in query parsing on test DB ${TEST_DB} loaded with SCALE FACTOR $SCALE"
             fi
             echo -e "Test results from query execution in mode $MODE vs test DB ${TEST_DB} loaded with SCALE FACTOR $SCALE"
             echo -e "Query Performance Warm Time is calculated over $num_warm consecutive executions of each query"
             echo -e "note: The occurance of Errors is counted per query in err_num counter " >>  results/q_warm_${num_warm}
             echo -e "note: Errored retries are excluded from the calculation of the mean Performance Warm Time " >>  results/q_warm_${num_warm}
             cat results/q_warm_${num_warm}

       fi

####End  run-power warm  mode
