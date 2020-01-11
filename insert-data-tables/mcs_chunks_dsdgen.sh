#!/bin/bash


#------------------------------------------------------------------------------------------------------------------------------------------
#   SCRIPT  mcs_chunks_dsdgen.sh  is to
# - generate tpc-ds data and distribute data source files on PM nodes
#   data source files distribution is used for mcs distributed bulk load   
#   with cpimport in modes m2 or m3
#-------------------------------------------------------------------------------------------------------------------------------------------
#   USAGE
#  - run the mcs_chunks_dsdgen.sh  
#    with first parameter tpc-ds  SCALE factor, with  measured units  1GB
#    ./mcs_chunks_dsdgen.sh   1000    #will generate 1TB data and will and distribute data source files across PM nodes 
#    in dirs  $ PM_DATA_CHUNK_PATH/ tpcds_1000
#  Before running script  
#  - specify PM_DATA_CHUNK_PATH in cfg section MariaDB ColumnStore Test
#    for example : PM_DATA_CHUNK_PATH=/tmp
#  - install sshfs on UM
#  - ensure you have ssh key login enabled  between UM and PMs and specify MARIADB_SSH_USER 
#    in cfg section SUT Environment login details; for example MARIADB_SSH_USER=mariadb-user
#
#-------------------------------------------------------------------------------------------------------------------------------------------



SCALE="$1"
if [ -z "${SCALE}" ]; then
        SCALE=1000
fi
source ../cfg
if [ -z "${MARIADB_SSH_USER}" ]; then
        echo -e "Please specify MARIADB_SSH_USER in cfg section SUT Environment login details and ensure you have ssh key login enabled  between UM and PMs"
        exit 1 
fi



j=0
pn=($PM)
N=${#pn[*]}
if [[  $N -le 1 ]]
     then
         echo -e "\nuse nmcs_chunks_dsdgen.sh when  more than 1 MCS PM nodes are involved in SUT"
         exit 1
     fi




sshfs --version  &> /dev/null
if [[ $? -ne 0 ]] ; then echo -e "Please install sshfs" ; exit 1 ; fi




for i in $PM
   do
      ssh -o  StrictHostKeyChecking=no ${i}  -l ${MARIADB_SSH_USER}   mkdir -p -m a=rwx "${PM_DATA_CHUNK_PATH}"/tpcds_${SCALE}
      if [[  $? -ne 0 ]] ; then echo -e "Fail to create target data dir "${PM_DATA_CHUNK_PATH}"/tpcds_${SCALE} on PM ${i}, with ssh-user : ${MARIADB_SSH_USER}, please ensure you have ssh key login enabled  between UM and PMs" ; exit 1 ; fi  
   done


cdir=$PWD

for i in $PM
   do
     rm -rf $i
     mkdir -p $i
     sshfs   ${MARIADB_SSH_USER}@${i}:${PM_DATA_CHUNK_PATH}/tpcds_${SCALE}  ${cdir}/${i}
   done



for i in $PM
   do
     #j=${i//[!0-9]/}
     j=$(( $j + 1 ))
     ./dsdgen_v2.6.0 -SCALE $SCALE -DIR ${cdir}/$i -SUFFIX .tbl  -PARALLEL $N -CHILD $j -VERBOSE Y  &
   done
wait




disown -a
for i in $PM
   do
     sudo umount -l ${cdir}/$i
   done


