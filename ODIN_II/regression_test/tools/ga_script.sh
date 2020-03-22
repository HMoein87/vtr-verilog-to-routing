#!/bin/bash
# Run GA script


################################################
##################--GLOBALS--###################
################################################
footprint=2
DEFAULT_MR=50
DEFAULT_GS=6
DEFAULT_GC=1000
WIDE_PATH="==========================================="

################################################

TESTS_PATH="./regression_test/benchmark/verilog/ga"
GA_OUTPUTS_DIR="./ga_outputs"
NEW_DIR=""
RUN_PATH=""


################################################
################--FUNCTIONS--###################
################################################
# Init Directories and cleanup
function helpFunction()
{
   echo ""
   echo -e "Specify the default values\n"
   echo "Usage: $0 [-m Mutation Rate (0-100)] [-s Generation Size [1-20]]"
   echo -e "\t[-c Generation Count [1K-100K]]"
   echo ""
   exit 1 # Exit script after printing help
}

function print_config () {
        
        printf "\n$WIDE_PATH\n"
        printf "\t-Mutation rate: %d%%\n\t-Generation size: %d\n\t-Generation count: %d\n" $DEFAULT_MR $DEFAULT_GS $DEFAULT_GC
        printf "$WIDE_PATH\n\n"
}

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
	NEW_DIR=${GA_OUTPUTS_DIR}/$(printf "%03d" $counter)
 }



################################################
##################--MAIN--######################
################################################
while getopts ":m:s:c:h:" opt;
do
        case "$opt" in

                m) _MR=${OPTARG}
                ;;
                s) _GS=${OPTARG}
                ;;
                c) _GC=${OPTARG}
                ;;
                ?) helpFunction
                ;;
        esac
                
done

if [ -n "$_MR" ]
then
        DEFAULT_MR=$_MR
fi
if [ -n "$_GS" ]
then
        DEFAULT_GS=$_GS
fi
if [ -n "$_GC" ]
then
        DEFAULT_GC=$_GC
fi

print_config

#make debug
gcc ./tocsv.c -o tocsv -std=c99

check_dir
mkdir -p ${NEW_DIR}

printf "\n-------------------- Running Odin-II for test cases! --------------------\n"

for file in ${TESTS_PATH}/*.v;
do
        no_path=${file##*/}
        filename=${no_path%.*}

        if [ "$filename" == "*" ];
        then
                printf "\n** ERROR: No file exists! **\n\n"
                exit 1
        fi

        mkdir ${NEW_DIR}/$filename
        RUN_PATH=${NEW_DIR}/$filename
        mkdir -p ${NEW_DIR}/overall_csv/$filename
        OCSV_PATH=${NEW_DIR}/overall_csv/$filename
        
        mkdir ${RUN_PATH}/mutation_rate_changing
        mkdir ${RUN_PATH}/mutation_rate_changing/csv

        generation_size=$DEFAULT_GS
        generation_count=$DEFAULT_GC
        
        start=$(date +%s%N)/1000000
        for ((mr=5; mr<=100; mr=mr+5))
        do
                ./odin_II -V $file --GA $footprint --GA-MR $mr --GA-GS $generation_size --GA-GC $generation_count > ${RUN_PATH}/mutation_rate_changing/$filename-MR_$mr%-GS_$generation_size-GC_$generation_count.out && 
                ./tocsv ${RUN_PATH}/mutation_rate_changing/$filename-MR_$mr%-GS_$generation_size-GC_$generation_count.out > ${RUN_PATH}/mutation_rate_changing/csv/$filename-MR_$mr%-GS_$generation_size-GC_$generation_count.csv &
        done
        end=$(date +%s%N)/1000000

        printf "Execution time: %.3f s\n" $(bc <<<"scale=4;$[end-start]/1000")
        echo "$filename -- Mutation Rate Changing:" 
        ls ${RUN_PATH}/mutation_rate_changing/
        printf "\n"


        ##########################################################
        # fix mutation rate and generation count! increase the generation size by 1 till 20
        mkdir ${RUN_PATH}/generation_size_changing
        mkdir ${RUN_PATH}/generation_size_changing/csv

        mutation_rate=$DEFAULT_MR
        generation_count=$DEFAULT_GC

        start=$(date +%s%N)/1000000
        for ((gs=1; gs<=20; gs++))
        do
                ./odin_II -V $file --GA $footprint --GA-MR $mutation_rate --GA-GS $gs --GA-GC $generation_count > ${RUN_PATH}/generation_size_changing/$filename-MR_$mutation_rate%-GS_$gs-GC_$generation_count.out && 
                ./tocsv ${RUN_PATH}/generation_size_changing/$filename-MR_$mutation_rate%-GS_$gs-GC_$generation_count.out > ${RUN_PATH}/generation_size_changing/csv/$filename-MR_$mutation_rate%-GS_$gs-GC_$generation_count.csv &
        done
        end=$(date +%s%N)/1000000

        printf "Execution time: %.3f s\n" $(bc <<<"scale=4;$[end-start]/1000")
        echo "$filename -- Generation Size Changing:"
        ls ${RUN_PATH}/generation_size_changing/
        printf "\n"


        ##########################################################
        # fix mutation rate and generation size! increase the generation count by 1000 till 100K
        mkdir ${RUN_PATH}/generation_count_changing
        mkdir ${RUN_PATH}/generation_count_changing/csv

        mutation_rate=$DEFAULT_MR
        generation_size=$DEFAULT_GS

        start=$(date +%s%N)/1000000
        for ((gc=1000; gc<=50000; gc=gc+500))
        do
                ./odin_II -V $file --GA $footprint --GA-MR $mutation_rate --GA-GS $generation_size --GA-GC $gc > ${RUN_PATH}/generation_count_changing/$filename-MR_$mutation_rate%-GS_$generation_size-GC_$gc.out &&
                ./tocsv ${RUN_PATH}/generation_count_changing/$filename-MR_$mutation_rate%-GS_$generation_size-GC_$gc.out > ${RUN_PATH}/generation_count_changing/csv/$filename-MR_$mutation_rate%-GS_$generation_size-GC_$gc.csv &
        done
        end=$(date +%s%N)/1000000

        printf "Execution time: %.3f s\n" $(bc <<<"scale=4;$[end-start]/1000")
        echo "$filename -- Generation Count Changing:"
        ls ${RUN_PATH}/generation_count_changing/
        printf "\n\n"

done

wait
printf "\n-------------------- Generating general csv files --------------------\n\n"
./tocsv_script.sh
