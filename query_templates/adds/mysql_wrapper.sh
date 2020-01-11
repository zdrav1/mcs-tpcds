#!/bin/bash



#---------------------------------------------------------------------------------------------------------------------------
#   SCRIPT ./ mysql_wrapper.sh   is to
# - perform  query validation  via mysqltest tool against stable and reliable  SQL Server version 
#---------------------------------------------------------------------------------------------------------------------------
#   USAGE
# - run the script step-id.sh   from  mariadb-columnstore-tpcds/query_templates/adds   directory
#   with first parameter the name of the test environment
#   and seconds parameter the name of the TEST_DB 
#   Test_Result_Summary  and results from mysqltest are collected in dir  
#   mariadb-columnstore-tpcds/query_templates/adds/runs/$date    
#---------------------------------------------------------------------------------------------------------------------------





TEST_DB="$1"

if [ -z "${TEST_DB}" ]; then
        TEST_DB='tpcds_1'
fi

cd ..
cd ..

source cfg
source functions
if [[ -z ${BASE_IQE_HOST} ]] || [[ -z  ${BASE_IQE_USER} ]] || [[ -z  ${BASE_IQE_PASS} ]] ; then
     echo -e "\nMissing mysql host,user and passw of mysql_test_wrapper server\nPlease set these params in the cfg file"
     exit 1  
fi
__path_sql   #check if path to mysql tools is currect 
__connect_sql ${BASE_IQE_HOST} ${BASE_IQE_USER} ${BASE_IQE_PASS} 2
__test_db    #chech if tpc-ds db exits on SUT

mkdir -p query_templates/adds/runs
DAT=$(date +%Y%m%d-%H%M%S)
RESULTDIR="query_templates/adds/runs/$DAT"
mkdir ${RESULTDIR}
mkdir ${RESULTDIR}/results



while read query
      do


                OK_BASELINE=$(cat "query_templates/adds/validate_mdb_query_templates/${query}.sql" | mysqltest  -h ${BASE_IQE_HOST} -u ${BASE_IQE_USER} -p${BASE_IQE_PASS}  --database=${TEST_DB}   --include "./query_templates/adds/setup-test.inc" -r -R "${RESULTDIR}/results/${query}.result")
                OK_MDB=$(cat "query_templates/adds/validate_mdb_query_templates/${query}.sql" | mysqltest  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} --database=${TEST_DB}   --include "./query_templates/adds/setup-test.inc" -R "${RESULTDIR}/results/${query}.result")
                if [ "${OK_BASELINE}" = "ok" ] && [ "${OK_MDB}" = "ok" ]; then
                    echo "QUERY ${query}: PASSED"
                    echo "QUERY ${query}: PASSED" >> $RESULTDIR/Test_Result_Summary-$DAT

                else
                    echo "QUERY ${query}: FAILED"
                    echo "QUERY ${query}: FAILED" >> $RESULTDIR/Test_Result_Summary-$DAT

                    if [[ ! -z $FAILED_STOP ]]; then
                        echo -e "\e[1;31m FAILED at\n$(cat "query_templates/adds/validate_mdb_query_templates/${query}.sql") \e[0m"
                        if [[ $FAILED_STOP -eq 2 ]] ; then
                            exit 1
                        fi
                        #__drive_sanity
                    fi
                fi






      done<query_templates/adds/PASS_MCS







