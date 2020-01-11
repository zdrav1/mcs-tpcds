#QUERY_28
#####Enable and increase MCS internal precision on decimal calculations

 set @@global.infinidb_use_decimal_scale=1 ;
 set @@global.infinidb_decimal_scale=7 ;
 set infinidb_use_decimal_scale=1;
 set infinidb_decimal_scale=7 ;



select  TRIM(TRAILING '.' FROM TRIM(B1_LP))+0 as B1_LP,B1_CNT, B1_CNTD, B2_LP,B2_CNT, B2_CNTD, format(B3_LP,6) as B3_LP ,B3_CNT, B3_CNTD, B4_LP,B4_CNT, B4_CNTD, B5_LP,B5_CNT, B5_CNTD, B6_LP,B6_CNT, B6_CNTD
from (select avg(ss_list_price) B1_LP,'a' as j
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 8 and 8+10
             or ss_coupon_amt between 459 and 459+1000
             or ss_wholesale_cost between 57 and 57+20)) B1,
     (select avg(ss_list_price) B2_LP,'a' as j
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 90 and 90+10
          or ss_coupon_amt between 2323 and 2323+1000
          or ss_wholesale_cost between 31 and 31+20)) B2,
     (select avg(ss_list_price) B3_LP,'a' as j
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 142 and 142+10
          or ss_coupon_amt between 12214 and 12214+1000
          or ss_wholesale_cost between 79 and 79+20)) B3,
     (select avg(ss_list_price) B4_LP,'a' as j
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 135 and 135+10
          or ss_coupon_amt between 6071 and 6071+1000
          or ss_wholesale_cost between 38 and 38+20)) B4,
     (select avg(ss_list_price) B5_LP,'a' as j
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 122 and 122+10
          or ss_coupon_amt between 836 and 836+1000
          or ss_wholesale_cost between 17 and 17+20)) B5,
     (select avg(ss_list_price) B6_LP,'a' as j
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 154 and 154+10
          or ss_coupon_amt between 7326 and 7326+1000
          or ss_wholesale_cost between 7 and 7+20)) B6
where B1.j = B2.j and B2.j = B3.j and  B3.j = B4.j and  B4.j = B5.j and  B5.j = B6.j
limit 100;





#### Resume MCS internal precision on decimal calculations
 set @@global.infinidb_use_decimal_scale=0 ;
 set @@global.infinidb_decimal_scale=8 ;
