## TPC-DS Benchmark Framework for MariaDB ColumnStore
----

mariadb-columnstore-tpcds framework project directory  content: 

```
.
├── answer_sets        #TPC-DS v2.5.0 query answer sets with changes
├── answer_sets_ds     #Original TPC-DS v2.5.0 query answer sets
├── cnf                #Optional mysql configuration files
├── cfg                #Configuration file for tests driving and SUT Environment login details
├── insert-data-tables #TPC-DS schema and data location dir 
│   ├── data           #Raw Data dir to be used when data will be stored locally on SUT 
│   └── schemas        #TPC-DS original schema and TPC-DS MCS schema
│   │   ├── mcsds.sql
│   │   └── tpcds.sql
    ├── dsdgen_v2.6.0      #TPC-DS data generator
│   ├── mcs_chunks_dsdgen.sh
│   └── tpcds.idx
├── query_templates        #TPC-DS query  templates  with rewritten queries and customized  dsdgen BEGIN operator BEGIN=Query_Id
    ├── query-validate.sh  #Script to be used for query validation against the  TPC_DS answer_sets
    ├── PASS_MCS           #List of currently MCS supported queries which passed validation test 
│   ├── adds
│   │   └── validate_mdb_query_templates  #TPC-DS v2.5.0 queries with qualification substitution parameters from TPC-DS Standard Specification/Appendix B:Business Questions

        ├── mysql_wrapper.sh #Addtional Script to be used to do query validations 
│   ├── ansi.tpl
│   ├── dsqgen_v2.6.0  #TPC-DS query generator 
│   │  
│   └── validate_mdb_query_templates      #TPC-DS v2.5.0 queries with randomly generated qualification substitution parameters
└── query_templates_ds  #Original TPC-DS query  templates  

```


General TPC-DS benchmark execution flow
---- 
sine qua non

- Load of 1GB qualification Database
- Execution of query templates using qualification substitution parameters  and query validation against the tpc answer-set

Main TPC-DS benchmark execution flow

- Database Load Test
- Power Test
- Throughput Test 1 
- Data Maintenance Test 1
- Throughput Test 2
- Data Maintenance Test 2


Transitory benchmark   execution flow 
--


1. Copy the mariadb-columnstore-tpcds package  on the SUT
2. Create output dir for 1G data generation   
    mkdir -m a=rwx insert-data-tables/data/tpcds_1
3. Generate 1GB raw data files
```
~/../mariadb-columnstore-tpcds/insert-data-tables$ ./dsdgen_v2.5.0 -SCALE 1 -SUFFIX .tbl -DIR data/tpcds_1
```
4. Load 1GB data
```
 ~/../mariadb-columnstore-tpcds$  ./load-test.sh 1 
```
5. Check the loaded data
```
~/../mariadb-columnstore-tpcds$ ./load-validate-mdb.sh  1  
```   
6. Filter the unsupported queries
7. Start query validation of supported queries against the tcp-ds answer-set  // queries with qualification  substitution parameters are placed in query_templates/validate_mdb_query_templates
~/../mariadb-columnstore-tpcds/query_templates$  ./query-validate.sh   tpcds_1
9. Generate 1TB raw data files
10. Load 1TB data   
```
./load-test.sh  1000 
```
11. Check the loaded data
```
./load-validate-mdb.sh  1000  
```   
12. Run Power test  in mode cold  and gather the execution time per query  
```
./run-power.sh 1000 cold 
```
13. Tune if possibly environment
14. Run Power test in mode warm and gather the mean performance time per N times query executes ,N=5 by default
```
./run-power.sh 1000 warm
./run-power.sh 1000 warm:N 
```
15. Tune if possibly environment
16. Run Power test in mode tpc-ds  and  gather the  execution time  of  the set of queries  in the Stream0, default 
```
./run-power.sh 1000
./run-power.sh 1000 tpc-ds
```



Guide to run the framework on Single Server ColumnStore installation
---- 

This kind of setup is useful for execution of the queries during some development and for experiments with rewriting of the queries. 
The framework setup configuration is adjusted for work with 1 GB data, generated by TPC-DS tools.

Prerequisites:

- Single Server ColumnStore installed and run on the environment;
- Create a database user and grant privileges for local and remote access. This use must have a password.

Initial configurations and load of data:

1. Copy `mariadb-columnstore-tpcds` project directory on the system under test.
2. Assure execution permissions on the scripts in the suite.
3. Navigate into `mariadb-columnstore-tpcds` directory
4. Create output dir for 1GB data generation
```
     mkdir -m a=rwx insert-data-tables/data/tpcds_1
```
5. Generate 1GB raw data files
```
     cd insert-data-tables 
     ./dsdgen_v2.5.0 -SCALE 1 -SUFFIX .tbl -DIR data/tpcds_1
```
6. Update cfg configuration

   For Single Server installation edit the `cfg` file, section Single Server ColumnStore  and update  host name or IP adress and user creadentials to Single Server ColumnStore
7. Load 1GB data 

   From the mariadb-columnstore-tpcds directory run the command:
     ```
     ./load-test.sh 1 
     ```
8. Validate correct table load 

    From the mariadb-columnstore-tpcds directory run command:
     ```
     ./load-validate-mdb.sh 1 
     ```
9. Queries prepared with parameters requered for comparison with provided answer set are available in directory:

    ```
    query_templates/validate_mdb_query_templates
    ```
    
    This queries can be used for verification tests and rewriting pusrposes.

10. The file `PASS_MCS` contains succesfully passed queries and this file can be found in the same directory.
