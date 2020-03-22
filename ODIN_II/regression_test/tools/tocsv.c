
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


void miss_lines (int num, FILE *fp) {

    char line[1024];

    for (int i = 0; i < num; i++) 
        fgets(line, sizeof(line), fp);
}

int main (int argc, char* argv[]) {

    FILE *fp1 = NULL;
    // FILE *fp2 = NULL;
    char name[1024];
    int generation_count=-1;
    int generation_size=-1;
    float mutation_rate=-1;
    int generation_number=-1;
    float current_fitness=-1;
    int node_count=-1;
    char* op;
    int op_number=-1;
    int RCA_number=-1;
    int CSLA_number=-1;
    int BE_CSLA_number=-1;
    int critical_path=-1;
    int max_fanin=-1;
    int max_fanout=-1;

    // input
    // output
    // size_t len = strlen(argv[1]);
    // char fcsv[len];
    // strncpy(fcsv, argv[1], len-3);
    // fcsv[len-1] = 'v';
    // fcsv[len-2] = 's';
    // fcsv[len-3] = 'c';
    // printf("---->-%s-\n", fcsv);

    fp1 = fopen(argv[1], "r");
    // fp2 = fopen(fcsv, "w");

    if ( fp1 == NULL ) 
        printf("file open error!\n");

    // if ( fp2 == NULL ) 
    //     printf("csv: file open error!\n");

    //
    miss_lines(15, fp1);
    
    fscanf(fp1, "%s %d\n", name, &generation_count);
    fscanf(fp1, "%s %s %d\n", name, name, &generation_size);
    fscanf(fp1, "%s %s %f\n", name, name, &mutation_rate);
    
    
    //printf("mutation_rate,generation_size,generation_count\n");
    printf("%.3f,%d,%d\n", mutation_rate, generation_size, generation_count);

    // printf("generation_count: -%d-\n", generation_count);
    // printf("generation_size: -%d-\n", generation_size);
    // printf("mutation_rate: -%f-\n", mutation_rate);

    miss_lines(3, fp1);

    //printf("generation_number,fitness,critical_path,max_fanin,max_fanout,op_type,op_num,node_count,RCA,CSLA,BE_CSLA\n");
    
    for (int i = 0; i < generation_count; i++) {

        fscanf(fp1, "%s %d\n", name, &generation_number);
        // printf(">>generation_number: -%d-\n", generation_number);

        for (int j = 0; j < generation_size; j++) {

            fscanf(fp1, "%s %f\n", name, &current_fitness);
            fscanf(fp1, "%s %d\n", name, &critical_path);
            fscanf(fp1, "%s %d\n", name, &max_fanin);
            fscanf(fp1, "%s %d\n", name, &max_fanout);
            fscanf(fp1, "%s %d %d\n", op, &op_number, &node_count);
            fscanf(fp1, "%s %s %d\n", name, name, &RCA_number);
            fscanf(fp1, "%s %s %d\n", name, name, &CSLA_number);
            fscanf(fp1, "%s %s %d\n", name, name, &BE_CSLA_number);
            miss_lines(1, fp1);

            if ( j == 0 ) {
                printf("%d,%f,%d,%d,%d,%s,%d,%d,%d,%d,%d\n", 
                    generation_number, current_fitness, critical_path, max_fanin, max_fanout, op, op_number, node_count, RCA_number, CSLA_number, BE_CSLA_number);
            }

            // if ( j == 0 )
            //     printf("\tparent fitness: -%f-\n", current_fitness);
            // else
            //     printf("\tchild[%d] fitness: -%f-\n", j, current_fitness);

            // printf("\tcritical_path: -%d-\n", critical_path);
            // printf("\tmax_fanin: -%d-\n", max_fanin);
            // printf("\tmax_fanout: -%d-\n", max_fanout);
            // printf("\top type: -%s-\n", op);
            // printf("\top_num: -%d-\n", op_number);
            // printf("\tnode_count: -%d-\n", node_count);
            // printf("\tRCA: -%d-\n", RCA_number);
            // printf("\tCSLA: -%d-\n", CSLA_number);
            // printf("\tBE_CSLA: -%d-\n\n", BE_CSLA_number);
        }
    }
    
    fclose(fp1);
    // fclose(fp2);

}
