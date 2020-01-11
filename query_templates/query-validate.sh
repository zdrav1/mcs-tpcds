#!/bin/bash



#--------------------------------------------------------------------------------------------------------------------------------------------
#   SCRIPT  ./query-validate.sh   is to
# - validate the query results  from the TPC_DS validation set against the  TPC_DS answer_sets
#
#--------------------------------------------------------------------------------------------------------------------------------------------
#   USAGE
# - run the script ./query-validate.sh    from   mariadb-columnstore-tpcds/query_templates    directory
#   with first parameter the name of the test environment
#   and seconds parameter the name of the TEST_DB
#
#   Test_Result_Summary  and results  are collected in dir
#   mariadb-columnstore-tpcds/query_templates/result_sets
#
#   The differnces from the answer_sets are collected in dir 
#   mariadb-columnstore-tpcds/query_templates/result_sets/results/${query_number}.rez
#   where diff on the left side is from the  MCS query output result  and  diff on the right side is from the answer_sets 
#--------------------------------------------------------------------------------------------------------------------------------------------
#   WARNING
#   The  validate_mdb_query_templates  shell be set manually with  the Qualification Substitution
#   Parameters  taken from the spec    as  the TPC_DS query generator dsqgen   currently   dues not
#   support  Qualification Substitution generation   even run with option scale 1
#---------------------------------------------------------------------------------------------------------------------------------------------
#   NOTES
#   The  script  overcomes the inconsistency  of output query formats  in TPC_DS v2.5.0  answer set   ,
#   refer to the Point 1  in the Notes below
#   and it shell  be  updated  by the occurrence of new answer_set   version
#
#
#    Dismiss and break automation of query validation points  found in answer set
#
#
#
#    1.Unconsistant output query formats
#    -------  The outputs of some queries are done using tab separators between columns
#    -------  The outputs of some queries are done using pipe separators between columns
#    -------  The outputs of some queries are done using mixed tab separators and spaces or
#pipe separators and spaces between columns
#
#
#    2.Output Header issues
#    ------- The headers in some query outputs are with missing column names or with stripped column names
#    ------- The outputs of some queries include outlining tracers such as  ----------  , but are skipped in the others
#    ------- The outputs of some queries include vendor specific or some current environment specific   information
#
#
#    3.Output Trailing issues
#    ------- The outputs of some queries include row number trailers but are skipped in the others
#    ------- The outputs of some queries include some Warning messages
#    ------- The outputs of some queries include vendor specific or some current environment specific   information
#
#
#    3.Output Content issues
#    ------- The outputs of some queries are with trimmed 0  before the decimal point
#    ------- The outputs of some queries are with trimmed 0(es)   after the  decimal point
#    ------- The outputs of some queries are done empty string  instead of NULL values , but NULLs are given in the others
#    ------- The outputs of some queries are done  ‘%‘ string  instead of NULL value
#    ------- The outputs of some queries are done  ‘-‘ string  instead of NULL value
#
#
#    3. MCS specifics
#    ------- The given outputs in the answer sets seems to be done with  decimal (9,8)  precision after the decimal point  while  currently received mcs # results  are with  smaller precision
#TODO try  fit  the  precision  in  the test results
#    ------- String sorting  in order by   is case insensitive
#
#
#
#
#
#    Changes done and to be done  in answer set
#
#    -- Output Header issues
#    ------- Remove the custom or environment specific information
#    ------- Repaired output  Headers  in the Colum  names
#    ------- Remove the tracing lines  from headers
#
#    -- Output Trailing issues
#    ------- Remove row number trailers
#    ------- Remove the Warning messages
#    ------- Remove the custom or environment specific information
#
#
#
#
#
#
#
#
#
#
#
#---------------------------------------------------------------------------------------------------------------------------------------------





TEST_DB="$1"
FAILED_STOP=$2

send_errorh ()
{
         echo -e "\n\n TEST_DB name is requred parameters "
         echo -e " TEST_DB expected in format NAME_TPC-DS-SCALE, for example: tpcds_1\n     where TPC-DS-SCALE is in GB measured units ;For TPC-DS Query Validation the SCALE Factor shell be 1\n\nFor more datals regading query validation  against the  TPC_DS answer_sets refer to the descrition the query-validate.sh file  "
        exit 1

}


if [[  ${TEST_DB} == help ]] || [[  ${TEST_DB} == -help ]] || [[  ${TEST_DB} == --help ]] || [[  ${TEST_DB} == -h ]] || [[  ${TEST_DB} == h ]] ; then  end_errorh ; fi
if  [[ -z ${TEST_DB} ]]; then send_errorh ; fi


source ../cfg
source ../functions

__path_sql   #check if path to mysql tools is currect
__connect_sql ${MARIADB_MCS_HOST} ${MARIADB_MCS_USER} ${MARIADB_MCS_PASS} 1
__test_db    #chech if tpc-ds db exits on SUT

rm -rf result_sets
mkdir -p result_sets/results


echo -e "\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\nWARNING : the validate_mdb_query_templates shell be set with  Qualification Substitution Parameters  taken from the \n          TPC-DS Standard Specification/Appendix B:Business Questions
\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n" 


ds_frm=(5 7 14 18 21 22 36 39 43 53 63 66 68 76 79 80 86 93 97 99 )
n_ds_frm=${#ds_frm[*]}

for query in $(cat validate_mdb_query_templates/PASS_MCS)
      
do

         f=0
         j=${query//[!0-9]/}
         an=$(ls ../answer_sets/ | grep -E -w "${j}|${j}_NULLS_FIRST")

                    $SQL  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} ${TEST_DB} < validate_mdb_query_templates/${query}.sql | tee result_sets/${j}.res 


         for  (( who=0 ; who <n_ds_frm ; who ++ ))
             do
               if [[ $j -eq ${ds_frm[$who]} ]] 
                    then 
echo  ${ds_frm[$who]}

                   __strip_null "result_sets/${j}.res"
                   f=1
                fi
         done
         
if [[ $f -ne 1 ]] 
    then
        echo "6  15  30  46  51  56  62  64  67  74  81" | grep -F -q -w "$j"
        if [[ ! $? -eq 0 ]] ; then 
            __strip_null0  "result_sets/${j}.res"
            f1=1
            else mv result_sets/${j}.res result_sets/${j}.result
        fi
fi  

         diff  -iwBZ   --ignore-tab-expansion  --strip-trailing-cr  result_sets/${j}.result ../answer_sets/${an} > result_sets/results/${j}.rez
         if [[ -s result_sets/results/${j}.rez ]]
             then 
                 echo " $query validation  FAILED " | tee -a result_sets/Query_Valdation_Summary
                 echo " Details about devaition from  answer_sets  are collected in query_templates/result_sets/results/${j}.rez "
                                     if [[ ! -z $FAILED_STOP ]]; then
                                              echo -e "\e[1;31m FAILED at\n$(cat "validate_mdb_query_templates/${query}.sql") \e[0m"
                                                      if [[ $FAILED_STOP -eq 2 ]] ; then
                                                         exit 1
                                                      fi
                                     __drive_validation  
                    fi
 
             else
                 echo " $query validation  PASSED " | tee -a result_sets/Query_Valdation_Summary
         fi




done
