#!/bin/bash
# Run GA script


################################################
##################--GLOBALS--###################
################################################
footprint=2
DEFAULT_MR=50
DEFAULT_GS=6
DEFAULT_GC=1000

################################################

TESTS_PATH="./regression_test/benchmark/verilog/ga"
GA_OUTPUTS_DIR="./ga_outputs"
NEW_DIR=""
RUN_PATH=""


################################################
################--FUNCTIONS--###################
################################################
# Init Directories and cleanup
function check_dir () {
	declare -i counter=0;
	while true; 
	do
                if [ -d "${GA_OUTPUTS_DIR}/$(printf "%03d" $counter)"  ]
                then
                        counter=$counter+1;
                else
                        break;
                fi
	done
	NEW_DIR=${GA_OUTPUTS_DIR}/$(printf "%03d" $(($counter-1)))
 }



################################################
##################--MAIN--######################
################################################
#make debug
gcc ./tocsv.c -o tocsv -std=c99

check_dir

for file in ${TESTS_PATH}/*.v;
do
        no_path=${file##*/}
        filename=${no_path%.*}
        RUN_PATH=${NEW_DIR}/$filename
        OCSV_PATH=${NEW_DIR}/overall_csv/$filename
        
        generation_size=$DEFAULT_GS
        generation_count=$DEFAULT_GC
        for ((mr=5; mr<=100; mr=mr+5))
        do
            (./tocsv ${RUN_PATH}/mutation_rate_changing/$filename-MR_$mr%-GS_$generation_size-GC_$generation_count.out && printf "\n\n") >> ${OCSV_PATH}/overall_$filename-MR_5%-100%-GS_$generation_size-GC_$generation_count.csv

        done
        
        ##########################################################
        mutation_rate=$DEFAULT_MR
        generation_count=$DEFAULT_GC
        for ((gs=1; gs<=20; gs++))
        do
            (./tocsv ${RUN_PATH}/generation_size_changing/$filename-MR_$mutation_rate%-GS_$gs-GC_$generation_count.out && printf "\n\n") >> ${OCSV_PATH}/overall_$filename-MR_$mutation_rate%-GS_1-20-GC_$generation_count.csv
        done

        ##########################################################
        # fix mutation rate and generation size! increase the generation count by 1000 till 100K
        mutation_rate=$DEFAULT_MR
        generation_size=$DEFAULT_GS
        for ((gc=1000; gc<=50000; gc=gc+500))
        do
            (./tocsv ${RUN_PATH}/generation_count_changing/$filename-MR_$mutation_rate%-GS_$generation_size-GC_$gc.out && printf "\n\n") >> ${OCSV_PATH}/overall_$filename-MR_$mutation_rate%-GS_$generation_size-GC_1k-50k.csv
        done

done