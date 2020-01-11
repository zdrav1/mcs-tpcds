#!/bin/bash


#------------------------------------------------------------------------------------------------------------------------------------------
#   SCRIPT load-validate-mdb.sh  is to
# - check the loaded  tpc-ds data ;
#   the number of loaded rows is checked per tpc-ds table and  compared to  the  row numbers
#   given in the TPC-DS Specification  for  tpc-ds  tables per Scale Factor
#-------------------------------------------------------------------------------------------------------------------------------------------
#   USAGE
# - run the load-validate-mdb.sh  
#   with first parameter  tpc-ds  SCALE factor   , measured units  1G   
#   and second parameter  the name of the test environment
#   ./ load-validate-mdb.sh   1000  mcsds_sut__um1_pm1    #will check the number of rows  
#   in ds tables loaded with 1TB data  in  tpcds_1000  on SUT  mcsds_sut__um1_pm1 
#-------------------------------------------------------------------------------------------------------------------------------------------



SCALE="$1"
TEST_DB="$2"

ds_count=()
tbls_ds=()
ds_exp_counts=()


send_error ()
{
echo -e "
Required  Parameters  
1  Scale Factor in GB measured units\n "
#2  Test Environment
#3  Test DB Name     
exit 1
}

send_error2 ()
{
echo -e "
Invalide Scale Factor $SCALE
 Scale Factors are 1 10 100 1000 3000 10000 30000 100000 
 Currently  validation for SF=1,SF=10,SF=100,SF=10000 available"
exit 1
}



if [ -z "${SCALE}" ]; then
        send_error
fi
if [ -z "${TEST_DB}" ]; then
        TEST_DB='tpcds'
fi



source functions
source cfg



__validate_sacale ${SCALE}  && echo -e "load validation on SUT $TESTENV of TCP-DS data volume  SF=$SCALE\n" || send_error2
TEST_DB=${TEST_DB}_${SCALE}

__path_sql   #check if path to mysql tools is currect
__connect_sql ${MARIADB_MCS_HOST} ${MARIADB_MCS_USER} ${MARIADB_MCS_PASS} 1
__test_db    #chech if tpc-ds db exits on SUT

ds_tabs=(call_center catalog_page customer customer_address customer_demographics date_dim household_demographics income_band item promotion reason ship_mode store time_dim warehouse web_page web_site catalog_returns catalog_sales inventory store_returns store_sales web_returns web_sales)
ds_table_num=${#ds_tabs[*]}




ds_counts_1=(6 11718 100000 50000 1920800 73049 7200 20 18000 300 35 20 12 86400 5 60 30 144067 1441548 11745000 287514 2880404 71763 719384)
ds_counts_10=(24 12000 500000  250000  1920800 73049 7200 20 102000 500  45 20 102 86400 10 200  42 1439749  14401261  133110000 2875432  28800991  719217  7197566)
ds_counts_100=(30 20400 2000000 1000000 1920800 73049 7200 20 204000 1000 55 20 402 86400 15 2040 24 14404374 143997065 399330000 28795080 287997024 7197670 72001237)
ds_counts_1000=(42 30000 12000000 6000000 1920800 73049 7200 20 300000 1500 65 20 1002 86400 20 3000 54 143996756 1439980416 783000000 287999764 2879987999 71997522 720000376)
ds_counts_3000=(48 36000 30000000 15000000 1920800 73049 7200 20 360000 1800 67 20 1350 86400 22 3600 66 432018033 4320078880  1033560000 863989652  8639936081 216003761  2159968881)

eval ds_exp_counts=(\${ds_counts_$SCALE[@]})




eval '$SQL -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS}  -N -B -e "drop table if exists  ${TEST_DB}.dbgen_version;" '
j=0
for i in $( eval '$SQL -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS}  -N -B -e "show tables from ${TEST_DB};" ')
do 
  tbls_ds[j]=$i
  j=$(( $j + 1 ))
done

nl=${#tbls_ds[*]}





for (( i=0 ; i<$ds_table_num ; i++ ))
do
  ds_count[i]=$( eval '$SQL  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS}  -N -B -e "select count(*) from  ${TEST_DB}."${ds_tabs[i]}" ;" ')
done



if [[ $nl -eq 24 ]]
    then 
        echo -e " 24 DS tables are created "
    else
        echo -e " The number of created DS tables  is not 24   "
        echo -e " expected :\n "${ds_tabs[*]}" \nloaded\n  "${tbls_ds[*]}" "
    exit 1    
fi





for (( i=0 ; i<$ds_table_num ; i++ ))
do

  if [[ ${ds_exp_counts[$i]} -eq  ${ds_count[$i]} ]]
        then 
            echo -e " Table "${ds_tabs[i]}" is loaded with "${ds_count[i]}" rows as expected "  
        else 
            echo -e " Table "${ds_tabs[i]}" is loaded with "${ds_count[i]}" rows , expected rows  "${ds_exp_counts[$i]}" "
   fi

done




