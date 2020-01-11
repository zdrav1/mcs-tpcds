#QUERY_71
##Business Question
###Select the top revenue generating products, sold during breakfast or dinner time for one month managed by a given manager a cross all three sales channels


select brand_id,  brand,t_hour,t_minute,ext_price
from 
(
select i_brand_id brand_id, i_brand brand,t_hour,t_minute,
        ISNULL(TRIM(TRAILING '.' FROM TRIM(sum(ext_price)))+0),TRIM(TRAILING '.' FROM TRIM(sum(ext_price)))+0  ext_price
 from item, (select ws_ext_sales_price as ext_price,
                        ws_sold_date_sk as sold_date_sk,
                        ws_item_sk as sold_item_sk,
                        ws_sold_time_sk as time_sk
                 from web_sales,date_dim
                 where d_date_sk = ws_sold_date_sk
                   and d_moy=11
                   and d_year=1999
                 union all
                 select cs_ext_sales_price as ext_price,
                        cs_sold_date_sk as sold_date_sk,
                        cs_item_sk as sold_item_sk,
                        cs_sold_time_sk as time_sk
                 from catalog_sales,date_dim
                 where d_date_sk = cs_sold_date_sk
                   and d_moy=11
                   and d_year=1999
                 union all
                 select ss_ext_sales_price as ext_price,
                        ss_sold_date_sk as sold_date_sk,
                        ss_item_sk as sold_item_sk,
                        ss_sold_time_sk as time_sk
                 from store_sales,date_dim
                 where d_date_sk = ss_sold_date_sk
                   and d_moy=11
                   and d_year=1999
                 ) tmp,time_dim
 where
   sold_item_sk = i_item_sk
   and i_manager_id=1
   and time_sk = t_time_sk
   and (t_meal_time = 'breakfast' or t_meal_time = 'dinner')
 group by i_brand, i_brand_id,t_hour,t_minute

)f
order by
 ISNULL(ext_price ) desc, ext_price desc, brand_id ;


