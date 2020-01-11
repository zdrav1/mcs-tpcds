#!/bin/bash


#------------------------------------------------------------------------------------------------------------------------------------------
#   SCRIPT load-test.sh is to
# - perform  mcs load of tpc-ds schema  and  tpc-ds data  
# - collect statistics about the used load method, Scale Factor of data volume, TCP-DS Load test Start Time , 
#   TPC-DS Load test  End time and tcp-ds performance load time as defined in TPC-DS Specification
#-------------------------------------------------------------------------------------------------------------------------------------------
#   USAGE
# - run the load-test.sh
#   with first parameter tpc-ds  SCALE factor, with  measured units 1GB  
#   ./load-test.sh  1       #will load 1GB data in tpcds_1 on SUT mcsds_sut__um1_pm1 used for query validation 
#   ./load-test.sh  1000    #will load 1TB data in tpcds_1000 on SUT  mcsds_sut__um1_pm1
#-------------------------------------------------------------------------------------------------------------------------------------------



SCALE="$1"
LOAD_DB="$2"


_send_helper ()
{
         echo -e "\n\nBefore running load-test please generate data volume(es) with dsdgen and prepare test configuration cfg file with set\nmcs load mode to be used in MCS_MODE var and the location of the flat files:\nmcs_local | mcs_remote in the STORE var\nFor mcs load mode m1 and in case data will be stored locally on the UM place data files in\ndir insert-data-tables/data/tpcds_\$scale;\nin case it’s used remote location to store data\nplace data files in dir tpcds_\$scale and give the path to the remote parent dir in the cfg in the REMOTE_DATA_STORE var \n\nFor mcs load mode m2 please generate data volume(es) with dsdgen using the option parallel and specify in the cfg,var PM_DATA_PATH the location of the dir tpcds_\$scale with data chunks on PMs.\n\nRequired parameter for running load-test is SCALE Factor in GB units \n  "
         exit 1
}


_send_error ()
{
         echo -e "\e[1;31m \nSCALE Factor [measured units 1GB] is required parameter \e[0m"
         echo -e "\e[1;33m \n Recommended SCALE Factors :\e[0m"
         echo -e "\e[1;33m 1 [1GB]\tUsed for query validation   \e[0m "
         echo -e "\e[1;33m 10 [10GB]    100 [100GB] \tNot qualified data volumes \e[0m "      
         echo -e "\e[1;33m 1000 [1TB]   3000 [3TB]   10000 [10TB]   30000 [30TB]   100000 [100TB] \tTPC-DS qualified data volumes \e[0m "   
         exit 1
}


_clean ()
{
if [[ $mr -eq 1 ]]
    then
        sudo umount -l insert-data-tables/data
fi
if [[ $mr -eq 2 ]]
    then
        sudo umount -l ${BULK_DATA_IMPORT}
fi

if [[ $mr == m ]]
    then
        for i in $PM
           do
               echo -e "umount dir PM $i:/${PM_DATA_PATH}/${LOAD_DB}"
               ssh -o  StrictHostKeyChecking=no ${i}  -l ${MARIADB_SSH_USER} -q -i ${MARIADB_SSH_KEY}  sudo umount -l ${PM_DATA_PATH}/${LOAD_DB}
           done
fi

if [[ $mr == lr ]]
    then
        unlink insert-data-tables/data/${LOAD_DB}
fi
if [[ $mr == lri ]]
    then
        rm -rf  ${BULK_DATA_IMPORT}/*.tbl

fi
}


if [[  ${SCALE} == help ]] || [[  ${SCALE} == -help ]] || [[  ${SCALE} == --help ]] || [[  ${SCALE} == -h ]] || [[  ${SCALE} == h ]] ; then _send_helper ; fi






if [ -z "${LOAD_DB}" ]; then
        LOAD_DB='tpcds'
fi
if [ -z "${SCALE}" ]; then
        _send_error
fi


declare -A row_counts

row_counts=(
[tpcds_1]=19557335
[tpcds_10]=191496628
[tpcds_100]=959037905
[tpcds_1000]=6347386005
[tpcds_3000]=17713045730
[tpcds_10000]=56851497516
[tpcds_30000]=168070129094
[tpcds_100000]=224921626610
)


LOAD_DB=${LOAD_DB}_${SCALE}
fp=d
rm -rf results
mkdir -p results


source functions
source cfg
__path_sql   #check if path to mysql tools is currect
__connect_sql ${MARIADB_MCS_HOST} ${MARIADB_MCS_USER} ${MARIADB_MCS_PASS} 1 | tee -a results/load_time


echo $STORE | grep remote &>/dev/null
if [[ $? -eq 0 ]]
    then
        if [ ! "${EUID}" -eq 0 ]; then
        echo -e "\nPlease login as root" ;
        if [[ $MCS_MODE -eq 2 ]] || [[ $MCS_MODE -eq 3 ]] ; then
            echo -e "Warning : Before running the load test in modes m2 or m2 and data is located on external storage device , please verify that you have ssh key for PM nodes, ssh user with root permissions or set sudoer with NOPASSWD on PMs"
        fi 
        exit 1
    fi
fi





        echo -e "Drop $LOAD_DB if exists "
        echo -e "DROP DATABASE IF EXISTS $LOAD_DB " |  eval '$SQL  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} '
        ex=${PIPESTATUS[1]}
        if [[ $ex -ne 0 ]]
             then
                 echo -e "\n Test DB $LOAD_DB alredy exists.Cannot drop $LOAD_DB.\nPlease check mcsadmin System Status " | tee -a results/load_time
                 exit 1
        fi
        echo "Done"




if [[ $PRODUCT == MariaDBColumnStore ]]
    then
        SCHEMA_N=mcsds
        tpc_ds_tbls=(call_center.tbl catalog_page.tbl catalog_returns.tbl catalog_sales.tbl customer_address.tbl customer_demographics.tbl customer.tbl date_dim.tbl  household_demographics.tbl income_band.tbl inventory.tbl item.tbl promotion.tbl reason.tbl ship_mode.tbl store_returns.tbl store_sales.tbl store.tbl time_dim.tbl warehouse.tbl web_page.tbl web_returns.tbl web_sales.tbl web_site.tbl)
        tpc_ds_tbl_num=${#tpc_ds_tbls[*]}
        $PMCSTOOLS/mcsadmin help > /dev/null
        if [[ $? -ne 0 ]] ; then echo -e "Unable to locate path to MCS tools through $PMCSTOOLS \nPlease check the path for MCS tools and update test cfg file,section Path to the MCS tools depend on the mcs installation in vars PMCSTOOLS,PCPIMPORT,PCOLXML,BULK_DATA_IMPORT " ; exit 1 ; fi 
        echo -e "\nStart Load Test columnstore_info.total_usage" | tee -a results/load_time
        $SQL  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} -e "call columnstore_info.total_usage();" | tee -a results/load_time
        TOTAL_DISK_USAGE_b=$($SQL -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} -N -B -e "call columnstore_info.total_usage();"  | awk '{print $3" "$4}')
        start_usage=$(__disc_usage  "${TOTAL_DISK_USAGE_b}" )
     else
         SCHEMA_N=tpcds

fi




DRl=$(date +"%s")
#t_now=$(GET_NOW)
format=csv
start_time_load=$(__stamp_time )





echo -e "\n Load Test started on SUT $TESTENV  at $start_time_load"
        echo -e "Create $LOAD_DB DATABASE "
        echo -e "CREATE DATABASE  $LOAD_DB " |  eval '$SQL  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} '
        ex=${PIPESTATUS[1]}
        if [[ $ex -ne 0 ]]
             then
                 echo -e "\n Cannot create database $LOAD_DB.\nPlease check mcsadmin System Status " | tee -a results/load_time
                 exit 1
        fi
        echo "Done"
        echo -e "Create $LOAD_DB SCHEMA  "

                 f=$(find insert-data-tables/schemas -type f -name ${SCHEMA_N}.sql )
                 if [[ ! -z $f ]]
                     then
                         eval '$SQL  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} ${LOAD_DB} ' <  insert-data-tables/schemas/${SCHEMA_N}.sql
                         if [[ $? -ne 0 ]] 
                             then echo -e "\n Fail to create TPC-DS SCHEMA ,\nPlease check mcsadmin System Status " | tee -a results/load_time 
                             exit 1
                         fi
                 else
                     echo -e " Cannot find  ${SCHEMA_N}.sql  SCHEMA in insert-data-tables/schemas/"
                     exit 1
                 fi
                 echo "Done"





if [[ $STORE == remote ]]
    then
        echo -e "Data will be loaded from remote location $REMOTE_DATA_STORE"
        sudo mount -t nfs $REMOTE_DATA_STORE insert-data-tables/data -o ro
        if [[ ! $? -eq 0 ]] ; then exit 1 ; fi
                 ls insert-data-tables/data/${LOAD_DB}/ |  grep .csv > /dev/null
                 if [[ $? -ne 0 ]] ; then
                 echo -e "Unable to find data files *.csv  in insert-data-tables/data/${LOAD_DB}/  dir \nPlease check the contents of $REMOTE_DATA_STORE/$LOAD_DB "
                 exit 1
                                     fi

        mr=1
fi



if [[ $STORE == import_remote ]]
    then
        echo -e "Data will be loaded from imported remote location $IMPORTED_REMOTE_DATA_STORE"
        ln -s  ${IMPORTED_REMOTE_DATA_STORE}/${LOAD_DB}  insert-data-tables/data/
        fp=l
        mr=lr
fi


if [[ $STORE == mcs_remote ]]


    then
             case $MCS_MODE in
                  1)
                     if [[ $colxml -eq 0 ]]
                        then
                             mr=1

                             echo -e "Data will be loaded from remote location $REMOTE_DATA_STORE"
                             sudo mount -t nfs $REMOTE_DATA_STORE insert-data-tables/data -o ro
                             if [[ ! $? -eq 0 ]] ; then exit 1 ; fi
                                     ls insert-data-tables/data/${LOAD_DB}/ |  grep .tbl > /dev/null
                                     if [[ $? -ne 0 ]] ; then
                                         echo -e "Unable to find data files *.tbl  in insert-data-tables/data/${LOAD_DB}/ dir \numounting insert-data-tables/data\nPlease check the contents of $REMOTE_DATA_STORE/$LOAD_DB "
                                         _clean
                                         exit 1
                                     fi
                             load_mode=mcs_m1
                             load_method='mcs_m1_remote_store'
                        else
                                     mr=2
                                     echo -e "Data will be loaded from remote location $REMOTE_DATA_STORE  imported to local location ${BULK_DATA_IMPORT} "
                              sudo mount -t nfs $REMOTE_DATA_STORE/$LOAD_DB  ${BULK_DATA_IMPORT}
                              if [[ ! $? -eq 0 ]] ; then exit 1 ; fi 
                                     ls ${BULK_DATA_IMPORT} |  grep .tbl > /dev/null
                                     if [[ $? -ne 0 ]] ; then
                                         echo -e "Unable to find data files *.tbl  in mounted ${BULK_DATA_IMPORT} dir \numounting ${BULK_DATA_IMPORT}\nPlease check the contents of $REMOTE_DATA_STORE/$LOAD_DB "
                                         _clean
                                         exit 1
                                     fi
 
                              RAN=$(__generate_random_id 5)
                              ${PCOLXML} $LOAD_DB  -j${RAN}
                              if [[ $? -ne 0 ]] ; then exit 1 ; fi
                              load_mode=mcs_m1_colxml
                              load_method='mcs_m1_colxml_remote_store'
                        fi
                    ;;
                    2|3)
                     if [[ $colxml -eq 0 ]]
                        then
                             mr=m
                             for i in $PM
                                do
                                     echo -e "Data will be loaded from remote location $REMOTE_DATA_STORE  imported to PM $i:${PM_DATA_PATH}/${LOAD_DB} "
                                     #sshpass -p${MARIADB_SSH_PASS}  ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=no  ${MARIADB_MCS_HOST}  -l ${MARIADB_SSH_USER}  'sudo mount -t nfs ${REMOTE_DATA_STORE}/${LOAD_DB}_m/'${i}' ${PM_DATA_PATH}/${LOAD_DB} -ro '
                                      ssh -o  StrictHostKeyChecking=no ${i}  -l ${MARIADB_SSH_USER} -q -i ${MARIADB_SSH_KEY}  mkdir -p -m a=rwx "${PM_DATA_PATH}"/${LOAD_DB}
                                      ssh -o  StrictHostKeyChecking=no ${i}  -l ${MARIADB_SSH_USER} -q -i ${MARIADB_SSH_KEY}  sudo mount -t nfs ${REMOTE_DATA_STORE}/${LOAD_DB}_m/"${i}" ${PM_DATA_PATH}/${LOAD_DB}
                                      if [[ ! $? -eq 0 ]] ; then exit 1 ; fi
                                         ssh -o  StrictHostKeyChecking=no ${i}  -l ${MARIADB_SSH_USER} -q -i ${MARIADB_SSH_KEY}  ls ${PM_DATA_PATH}/${LOAD_DB}/ |  grep .tbl > /dev/null
                                             if [[ $? -ne 0 ]] ; then
                                                 echo -e "Unable to find data files *.tbl  in ${PM_DATA_PATH}/${LOAD_DB}/ dir \numounting insert-data-tables/data\nPlease check the contents of $REMOTE_DATA_STORE/$LOAD_DB_m/${i} "
                                                _clean
                                                exit 1
                                             fi

                                done
                             if [[ $MCS_MODE -eq 2 ]] ; then
                                 load_mode=mcs_m2
                                 load_method='mcs_m2_remote_store'
                             else
                                 load_mode=mcs_m3
                                 load_method='mcs_m3_remote_store'
                             fi
                        else 
                            echo -e "err2 ;cpimport MCS_MODE=m$MCS_MODE, colxml=$colxml"
                            exit 1
                        fi

                   ;;
                   *)
                      echo -e "Unknown MCS_MODE\n msc bulk modes are 1 , 2 , 3\nPlease set MCS_MODE value in the cfg configuration file"
                      exit 1
        esac
                   

                            
#mount

fi



if [[ $STORE == mcs_local ]]
    then

    case $MCS_MODE in
         1)
           echo -e "Data will be loaded from local location  insert-data-tables/data/${LOAD_DB}"
           SUITE_PATH=$PWD
           ls ${SUITE_PATH}/insert-data-tables/data/${LOAD_DB}/ |  grep .tbl > /dev/null
           if [[ $? -ne 0 ]] ; then
              echo -e "Unable to find data files *.tbl in insert-data-tables/data/${LOAD_DB}/ dir "
              exit 1
           fi

           if [[ $colxml -eq 1 ]]
               then 
                    mr='lri'
                    ln -s  ${SUITE_PATH}/insert-data-tables/data/${LOAD_DB}/*.tbl   ${BULK_DATA_IMPORT}
                    if [[ $? -ne 0 ]] ; then
                         echo -e "Please check the configuration of variable BULK_DATA_IMPORT in cfg, it should be set with correct path to colxml data dir  mariadb/columnstore/data/bulk/data/import"
                         _clean
                         exit 1
                    fi
                    RAN=$(__generate_random_id 5)
                    ${PCOLXML} $LOAD_DB  -j${RAN}
                    if [[ $? -ne 0 ]] ; then exit 1 ; fi
                    load_mode=mcs_m1_colxml
                    load_method='mcs_m1_colxml_local'
                else 
                    load_mode=mcs_m1
                    load_method='mcs_m1_local'
           fi    
         ;;
         2)
            if [[ $colxml -ne 0 ]] ; then echo -e "err2 ;cpimport MCS_MODE=m$MCS_MODE, colxml=$colxml" ; exit 1 ; fi
            __node_um
            if [[ $? == 111 ]] 
                 then
                     echo -e "Load test will be executed in MCS mode m2 from UM node " | tee -a results/load_time
                     __locate_pms
                     #Check if raw data is available on PMs
                     for  (( i=0 ; i<$p_num ; i++ ))
                       do
                          #ssh -o  StrictHostKeyChecking=no ${pp_ip[$i]}  -l ${MARIADB_SSH_USER} -q -i ${MARIADB_SSH_KEY} ls ${PM_DATA_PATH}/${LOAD_DB}/ |  grep .tbl 
                          ssh -o  StrictHostKeyChecking=no ${pp_ip[$i]}  -l ${MARIADB_SSH_USER} -q  ls ${PM_DATA_PATH}/${LOAD_DB}/ |  grep .tbl

                          if [[ $? -ne 0 ]] ; then
                              echo -e "Unable to find data files *.tbl in "${pp_ip[i]}":${PM_DATA_PATH}/${LOAD_DB}/ dir "
                              exit 1
                          fi
                       done

                 else
                     __node_pm
                     echo -e "Load test will be executed in MCS mode m2 from PM node $pn : $pn_ip" | tee -a results/load_time
                     ls ${PM_DATA_PATH}/${LOAD_DB}/ |  grep .tbl
                          if [[ $? -ne 0 ]] ; then
                              echo -e "Unable to find data files *.tbl in PM node $pn ${pn_ip}:${PM_DATA_PATH}/${LOAD_DB}/ dir "
                              exit 1
                          fi
                     for  (( i=0 ; i<$jm ; i++ ))
                       do
                            ssh -o  StrictHostKeyChecking=no "${pms[i]}"  -l ${MARIADB_SSH_USER} -q -i ${MARIADB_SSH_KEY} ls ${PM_DATA_PATH}/${LOAD_DB}/ |  grep .tbl
                          if [[ $? -ne 0 ]] ; then
                              echo -e "Unable to find data files *.tbl in in PM node "${pps[i]}"  "${pms[i]}":${PM_DATA_PATH}/${LOAD_DB}/ dir "
                              exit 1
                          fi
                       done
                        
                 fi

                    load_mode=mcs_m2
                    load_method='mcs_m2_local'
     
         ;;
         3) #echo err2 ; exit1 
            if [[ $colxml -eq 0 ]]
                then
                    load_mode=mcs_m3
                    load_method='mcs_m3_local'

            fi

         ;;
         *)
           echo -e "Unknown MCS_MODE\n msc bulk modes are 1 , 2 , 3\nPlease set MCS_MODE value in the cfg configuration file"
           exit 1
     esac
          

fi





echo -e "Load Data in  $LOAD_DB SCHEMA  "
echo -e "\n\n\n Starting load data on SUT: $TESTENV  with load_mode: $load_mode and load_method: $load_method at\n START TIME: $start_time_load\n " |  tee -a results/load_time



 __connect_sql ${BASE_IQE_HOST} ${BASE_IQE_USER} ${BASE_IQE_PASS} &> /dev/null
if [[ $? -eq 252 ]] ; then mst=1 ; fi




case  $load_mode  in

         mcs_m1)
                 load_mode='mcs_m1'                                     
                 d=$(find insert-data-tables/data -type ${fp} -name ${LOAD_DB} )
                 if [[ ! -z $d ]]
                     then
                           if [[ $parallel -eq 1 ]]
                                then

                                   for i in $( ls insert-data-tables/data/${LOAD_DB} | grep tbl )
                                     do
                                       MCS_TABLE="${i%.*}"
                                       echo "Loading MammothDB Table ${MCS_TABLE}"

                                       ${PCPIMPORT} -m1  ${LOAD_DB} ${i%.*}  insert-data-tables/data/${LOAD_DB}/${i}  |&  tee -a results/load_time &
                                     done
                                    wait

                             else
                           
                                   for i in $( ls insert-data-tables/data/${LOAD_DB} | grep tbl )
                                     do
                                       echo $i
                                       DRt=$(date +"%s")
                                       echo "Loading MammothDB Table ${MCS_TABLE}"
                                       date
echo  ${LOAD_DB} ${i%.*}  insert-data-tables/data/${LOAD_DB}/${i}

                                       ${PCPIMPORT} -m1  ${LOAD_DB} ${i%.*}  insert-data-tables/data/${LOAD_DB}/${i} |&  tee -a results/load_time
                                       echo "Done"
                                       date

                                       DURt1=$(DURATION $DRt)
                                       table_name="${i%.*}"
                                       if [[ $mst -eq 1 ]] ; then load_mdb_table_time ; fi
                                       echo -e "${LOAD_DB}\t\t${SCALE}\t\t${table_name}\t\t${DURt1}" | tee -a results/load_tables
                                     done
          
                           fi

                        else
                            echo -e " Cannot find data $LOAD_DB in dir insert-data-tables/data"
                            exit 1
                   fi


         ;;



         mcs_m1_colxml)

                      ${PCPIMPORT}  -m1 -j${RAN}  |&  tee -a results/load_time
                      ex=${PIPESTATUS[0]}
                      if [[ $ex -ne 0 ]]
                          then
                               echo -e "\n Load failed " | tee -a results/load_time
                               exit 1
                      fi


                                       
         ;;

 

         mcs_m2)
    
                           if [[ $parallel -eq 1 ]]
                                then

                                       for (( i=0 ; i<$tpc_ds_tbl_num ; i++))
                                           do
                                             ${PCPIMPORT} -m2   ${LOAD_DB}  ${tpc_ds_tbls[i]%.*} -l ${PM_DATA_PATH}/${LOAD_DB}/${tpc_ds_tbls[i]}  |&  tee -a results/load_time &
                                           done
                                           wait


                                 else

                                       for (( i=0 ; i<$tpc_ds_tbl_num ; i++))
                                           do
                                             DRt=$(date +"%s")
                                             ${PCPIMPORT} -m2   ${LOAD_DB}  ${tpc_ds_tbls[i]%.*} -l ${PM_DATA_PATH}/${LOAD_DB}/${tpc_ds_tbls[i]}  |&  tee -a results/load_time
                                             DURt1=$(DURATION $DRt)
                                             if [[ $mst -eq 1 ]] ; then load_mdb_table_time ; fi
                                             echo -e "${LOAD_DB}\t\t${SCALE}\t\t${table_name}\t\t${DURt1}" | tee -a results/load_tables

                                           done

                            fi



                                  
         
         ;;
        
         mcs_m3)
                                 for (( i=0 ; i<$tpc_ds_tbl_num ; i++))
                                    do
                                       for j in $PM
                                           do
#                                             ssh -o  StrictHostKeyChecking=no ${j}  -l ${MARIADB_SSH_USER} -q -i ${MARIADB_SSH_KEY} sudo  ${PCPIMPORT} -m3   ${LOAD_DB}  ${tpc_ds_tbls[i]%.*} -l ${PM_DATA_PATH}/${LOAD_DB}/${tpc_ds_tbls[i]}  &
#                                             table_name="${i%.*}"
                                              ssh ${j} -o  StrictHostKeyChecking=no -l ${MARIADB_SSH_USER} ${PCPIMPORT} -m3   ${LOAD_DB}  ${tpc_ds_tbls[i]%.*} -l ${PM_DATA_PATH}/${LOAD_DB}/${tpc_ds_tbls[i]}  |&  tee -a results/load_time &
                                              sleep 3 #Aviod table stripping from cpimport m3 due to ssh_exchange_identification failures: Connection closed                                               # by remote host or read: Connection reset by peer;                                                                                                          #with possible tunning of sshd_config for the MaxSessions and MaxStartups

                                           done
                                     done
                                     wait
         ;;


         *)

d=$(find insert-data-tables/data -type ${fp} -name ${LOAD_DB} )
                 if [[ ! -z $d ]]
                     then
                          load=$(__mysqlimport 2)
                          if [[ $load -eq 11 ]]
                               then
                                   load_mode='mysqlimport'
                                   for i in $( ls insert-data-tables/data/${LOAD_DB} | grep csv )
                                     do
                                       echo $i
                                       DRt=$(date +"%s") 
                                       echo "Loading MammothDB Table ${MCS_TABLE}"
                                       date
                                       mysqlimport  --fields-terminated-by='|'  --lines-terminated-by='\n'  --local  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS}  ${LOAD_DB}  insert-data-tables/data/${LOAD_DB}/${i}
                                       echo "Done"
                                       date

                                       DURt1=$(DURATION $DRt)
                                       table_name="${i%.*}"
                                       load_mdb_table_time
                                     done

                                 else
                                     __locate_mts
                                     if [[ $? -eq 0 ]]
                                         then
                                             load_mode='load_data_local_infile'
                                             echo -e "\mysqlimport is not supported on MTS ; data load will be done by mysql load data infile utility "

                                             for i in $( ls insert-data-tables/data/${LOAD_DB} | grep csv )
                                               do
                                                 echo $i
                                                 DRt=$(date +"%s")
                                                 table_name="${i%.*}"
                                                 echo "Loading MammothDB Table ${MCS_TABLE}"
                                                 date
                                                 echo  "LOAD DATA LOCAL  INFILE 'insert-data-tables/data/${LOAD_DB}/${i}' INTO TABLE  ${LOAD_DB}.${table_name}  COLUMNS TERMINATED BY '|' LINES TERMINATED BY '\n' ; "  |  mysql -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS}
                                                 echo "Done"
                                                 date
                                                 DURt1=$(DURATION $DRt)
                                                 load_mdb_table_time
                                               done

                                          else
                                               echo -e "\nmysqlimport is not supported on MTS ; \nplease run the load-test locally from  the $TESTENV SUT ${MARIADB_MCS_HOST}  "
                                               exit 1
                                     fi
                           fi


                        else
                            echo -e " Cannot find data $LOAD_DB in dir insert-data-tables/data"
                            exit 1
                   fi

esac



DUR1=$(DURATION $DRl)
echo -e "\n${LOAD_DB} was loaded with $DUR1"
end_time_load=$(__stamp_time )
seed=$(date "+%m%d%H%M%S%3N")
sed -i "s/RNGSEED=[0-9\(\)]\+/RNGSEED="$seed"/g"  cfg
#sed -i "s/^t_now.*/t_now=\'${t_now}\'/g" cfg
echo -e "\n Load Test finished on SUT $TESTENV  at $end_time_load"
t_now=$RNGSEED
__get_versions
tcp_ds_load_time=$(__tcp_time)
echo -e "\n\ndb_name\tscale\tstart_time\tend_time\tload_time\tTLoad "| tee -a results/load_time
echo -e "${LOAD_DB}\t${SCALE}\t${start_time_load}\t${end_time_load}\t${DUR1}\t${tcp_ds_load_time}\n"  | tee -a results/load_time 
mcs_rows_min=$(__load_rows_minutes)
echo -e "mcs number of data rows loaded per minute $mcs_rows_min"  | tee -a results/load_time


if [[ $PRODUCT == MariaDBColumnStore ]]
    then
        echo -e "\ncolumnstore_info.table_usage" | tee -a results/load_time
        $SQL  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} -e "call columnstore_info.table_usage('${LOAD_DB}', NULL);" | tee -a results/load_time
        echo -e "\ncolumnstore_info.compression_ratio" | tee -a results/load_time
        $SQL  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} -e "call columnstore_info.compression_ratio(); " | tee -a results/load_time
        echo -e "\nEnd Load Test columnstore_info.total_usage" | tee -a results/load_time
        $SQL  -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} -e "call columnstore_info.total_usage();" | tee -a results/load_time

        TOTAL_DISK_USAGE_e=$($SQL -h ${MARIADB_MCS_HOST} -u ${MARIADB_MCS_USER} -p${MARIADB_MCS_PASS} -N -B -e "call columnstore_info.total_usage();"  | awk '{print $3" "$4}')
         __disc_ratio  "${TOTAL_DISK_USAGE_e}" $start_usage
fi
if [[ $mst -eq 1 ]] ; then load_mdb_time ; fi 
_clean

# cd tools ; ./dump_test_results.sh
exit
