--
-- Legal Notice 
-- 
-- This document and associated source code (the "Work") is a part of a 
-- benchmark specification maintained by the TPC. 
-- 
-- The TPC reserves all right, title, and interest to the Work as provided 
-- under U.S. and international laws, including without limitation all patent 
-- and trademark rights therein. 
-- 
-- No Warranty 
-- 
-- 1.1 TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE INFORMATION 
--     CONTAINED HEREIN IS PROVIDED "AS IS" AND WITH ALL FAULTS, AND THE 
--     AUTHORS AND DEVELOPERS OF THE WORK HEREBY DISCLAIM ALL OTHER 
--     WARRANTIES AND CONDITIONS, EITHER EXPRESS, IMPLIED OR STATUTORY, 
--     INCLUDING, BUT NOT LIMITED TO, ANY (IF ANY) IMPLIED WARRANTIES, 
--     DUTIES OR CONDITIONS OF MERCHANTABILITY, OF FITNESS FOR A PARTICULAR 
--     PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OF 
--     WORKMANLIKE EFFORT, OF LACK OF VIRUSES, AND OF LACK OF NEGLIGENCE. 
--     ALSO, THERE IS NO WARRANTY OR CONDITION OF TITLE, QUIET ENJOYMENT, 
--     QUIET POSSESSION, CORRESPONDENCE TO DESCRIPTION OR NON-INFRINGEMENT 
--     WITH REGARD TO THE WORK. 
-- 1.2 IN NO EVENT WILL ANY AUTHOR OR DEVELOPER OF THE WORK BE LIABLE TO 
--     ANY OTHER PARTY FOR ANY DAMAGES, INCLUDING BUT NOT LIMITED TO THE 
--     COST OF PROCURING SUBSTITUTE GOODS OR SERVICES, LOST PROFITS, LOSS 
--     OF USE, LOSS OF DATA, OR ANY INCIDENTAL, CONSEQUENTIAL, DIRECT, 
--     INDIRECT, OR SPECIAL DAMAGES WHETHER UNDER CONTRACT, TORT, WARRANTY,
--     OR OTHERWISE, ARISING IN ANY WAY OUT OF THIS OR ANY OTHER AGREEMENT 
--     RELATING TO THE WORK, WHETHER OR NOT SUCH AUTHOR OR DEVELOPER HAD 
--     ADVANCE NOTICE OF THE POSSIBILITY OF SUCH DAMAGES. 
-- 
-- Contributors:
-- 
 define HOUR = ulist(random(-1,4,uniform),3);
 define STORE = dist(stores,1,1);
 define _BEGIN="#QUERY_88"; 
 define _END="";

select h8_30_to_9,h9_to_9_30,h9_30_to_10,h10_to_10_30,h10_30_to_11,h11_to_11_30,h11_30_to_12,h12_to_12_30
from
 (select count(*) h8_30_to_9,'a' as j
 from store_sales, household_demographics , time_dim, store
 where ss_sold_time_sk = time_dim.t_time_sk   
     and ss_hdemo_sk = household_demographics.hd_demo_sk 
     and ss_store_sk = s_store_sk
     and time_dim.t_hour = 8
     and time_dim.t_minute >= 30
     and ((household_demographics.hd_dep_count = [HOUR.1] and household_demographics.hd_vehicle_count<=[HOUR.1]+2) or
          (household_demographics.hd_dep_count = [HOUR.2] and household_demographics.hd_vehicle_count<=[HOUR.2]+2) or
          (household_demographics.hd_dep_count = [HOUR.3] and household_demographics.hd_vehicle_count<=[HOUR.3]+2)) 
     and store.s_store_name = 'ese') s1,
 (select count(*) h9_to_9_30,'a' as j 
 from store_sales, household_demographics , time_dim, store
 where ss_sold_time_sk = time_dim.t_time_sk
     and ss_hdemo_sk = household_demographics.hd_demo_sk
     and ss_store_sk = s_store_sk 
     and time_dim.t_hour = 9 
     and time_dim.t_minute < 30
     and ((household_demographics.hd_dep_count = [HOUR.1] and household_demographics.hd_vehicle_count<=[HOUR.1]+2) or
          (household_demographics.hd_dep_count = [HOUR.2] and household_demographics.hd_vehicle_count<=[HOUR.2]+2) or
          (household_demographics.hd_dep_count = [HOUR.3] and household_demographics.hd_vehicle_count<=[HOUR.3]+2))
     and store.s_store_name = 'ese') s2,
 (select count(*) h9_30_to_10,'a' as j 
 from store_sales, household_demographics , time_dim, store
 where ss_sold_time_sk = time_dim.t_time_sk
     and ss_hdemo_sk = household_demographics.hd_demo_sk
     and ss_store_sk = s_store_sk
     and time_dim.t_hour = 9
     and time_dim.t_minute >= 30
     and ((household_demographics.hd_dep_count = [HOUR.1] and household_demographics.hd_vehicle_count<=[HOUR.1]+2) or
          (household_demographics.hd_dep_count = [HOUR.2] and household_demographics.hd_vehicle_count<=[HOUR.2]+2) or
          (household_demographics.hd_dep_count = [HOUR.3] and household_demographics.hd_vehicle_count<=[HOUR.3]+2))
     and store.s_store_name = 'ese') s3,
 (select count(*) h10_to_10_30,'a' as j
 from store_sales, household_demographics , time_dim, store
 where ss_sold_time_sk = time_dim.t_time_sk
     and ss_hdemo_sk = household_demographics.hd_demo_sk
     and ss_store_sk = s_store_sk
     and time_dim.t_hour = 10 
     and time_dim.t_minute < 30
     and ((household_demographics.hd_dep_count = [HOUR.1] and household_demographics.hd_vehicle_count<=[HOUR.1]+2) or
          (household_demographics.hd_dep_count = [HOUR.2] and household_demographics.hd_vehicle_count<=[HOUR.2]+2) or
          (household_demographics.hd_dep_count = [HOUR.3] and household_demographics.hd_vehicle_count<=[HOUR.3]+2))
     and store.s_store_name = 'ese') s4,
 (select count(*) h10_30_to_11,'a' as j
 from store_sales, household_demographics , time_dim, store
 where ss_sold_time_sk = time_dim.t_time_sk
     and ss_hdemo_sk = household_demographics.hd_demo_sk
     and ss_store_sk = s_store_sk
     and time_dim.t_hour = 10 
     and time_dim.t_minute >= 30
     and ((household_demographics.hd_dep_count = [HOUR.1] and household_demographics.hd_vehicle_count<=[HOUR.1]+2) or
          (household_demographics.hd_dep_count = [HOUR.2] and household_demographics.hd_vehicle_count<=[HOUR.2]+2) or
          (household_demographics.hd_dep_count = [HOUR.3] and household_demographics.hd_vehicle_count<=[HOUR.3]+2))
     and store.s_store_name = 'ese') s5,
 (select count(*) h11_to_11_30,'a' as j
 from store_sales, household_demographics , time_dim, store
 where ss_sold_time_sk = time_dim.t_time_sk
     and ss_hdemo_sk = household_demographics.hd_demo_sk
     and ss_store_sk = s_store_sk 
     and time_dim.t_hour = 11
     and time_dim.t_minute < 30
     and ((household_demographics.hd_dep_count = [HOUR.1] and household_demographics.hd_vehicle_count<=[HOUR.1]+2) or
          (household_demographics.hd_dep_count = [HOUR.2] and household_demographics.hd_vehicle_count<=[HOUR.2]+2) or
          (household_demographics.hd_dep_count = [HOUR.3] and household_demographics.hd_vehicle_count<=[HOUR.3]+2))
     and store.s_store_name = 'ese') s6,
 (select count(*) h11_30_to_12,'a' as j
 from store_sales, household_demographics , time_dim, store
 where ss_sold_time_sk = time_dim.t_time_sk
     and ss_hdemo_sk = household_demographics.hd_demo_sk
     and ss_store_sk = s_store_sk
     and time_dim.t_hour = 11
     and time_dim.t_minute >= 30
     and ((household_demographics.hd_dep_count = [HOUR.1] and household_demographics.hd_vehicle_count<=[HOUR.1]+2) or
          (household_demographics.hd_dep_count = [HOUR.2] and household_demographics.hd_vehicle_count<=[HOUR.2]+2) or
          (household_demographics.hd_dep_count = [HOUR.3] and household_demographics.hd_vehicle_count<=[HOUR.3]+2))
     and store.s_store_name = 'ese') s7,
 (select count(*) h12_to_12_30,'a' as j
 from store_sales, household_demographics , time_dim, store
 where ss_sold_time_sk = time_dim.t_time_sk
     and ss_hdemo_sk = household_demographics.hd_demo_sk
     and ss_store_sk = s_store_sk
     and time_dim.t_hour = 12
     and time_dim.t_minute < 30
     and ((household_demographics.hd_dep_count = [HOUR.1] and household_demographics.hd_vehicle_count<=[HOUR.1]+2) or
          (household_demographics.hd_dep_count = [HOUR.2] and household_demographics.hd_vehicle_count<=[HOUR.2]+2) or
          (household_demographics.hd_dep_count = [HOUR.3] and household_demographics.hd_vehicle_count<=[HOUR.3]+2))
     and store.s_store_name = 'ese') s8
where s1.j = s2.j and s2.j = s3.j and s3.j = s4.j and s4.j = s5.j and s5.j = s6.j and s6.j = s7.j and s7.j = s8.j
;
