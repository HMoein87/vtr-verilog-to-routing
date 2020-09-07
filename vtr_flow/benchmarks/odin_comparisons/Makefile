raw_suite = bheap_2_32_scan.v\
             bheap_4_32_scan.v\
             bheap_6_32_scan.v\
             bheap_8_32_scan.v\
             bubblesort_004_32_scan.v\
             bubblesort_064_32_scan.v\
             bubblesort_256_32_scan.v\
             bubblesort_512_32_scan.v\
             des_01_scan.v\
             des_04_scan.v\
             des_48_scan.v\
             fft_04_scan.v\
             fft_16_scan.v\
             fft_32_scan.v\
             intmatmul_02_8_scan.v\
             intmatmul_04_8_scan.v\
             intmatmul_08_8_scan.v\
             intmatmul_16_8_scan.v\
             jacobi_04_04_08_64_scan.v\
             jacobi_08_08_08_64_scan.v\
             jacobi_16_16_08_64_scan.v\
             jacobi_32_32_08_64_scan.v\
             jacobi_32_64_08_64_scan.v\
             life_032_1_64_scan.v\
             life_032_6_64_scan.v\
             life_64_64_64_scan.v\
             life_064_16_64_scan.v\
             life_096_16_64_scan.v\
             mergesort_008_32_scan.v\
             mergesort_064_32_scan.v\
             mergesort_256_32_scan.v\
             nqueens_08_223_scan.v\
             nqueens_16_1_scan.v\
             nqueens_32_1_scan.v\
             nqueens_64_1_scan.v

temp_suites := bheap bubblesort des fft intmatmul jacobi life mergesort nqueens
suites := raw_benchmarks
cores := ddr3_synthesizable_bfm groundhog_io_extractor dct jpeg turbo three_rs_255_n
generated_files := $(cores:%=%.v) $(raw_suite)
all_files := $(wildcard *.v)
all_files += $(generated_files)

.PHONY: all
all: $(all_files)
	@echo "Generated Verilog files: " $(all_files)

ddr3_synthesizable_bfm:
	git clone https://github.com/freecores/ddr3_synthesizable_bfm.git $@
ddr3_synthesizable_bfm.v: ddr3_synthesizable_bfm
	@awk 'FNR==1{print ""}1' ddr3_synthesizable_bfm/rtl/* | sed '/$timeformat/d' > ddr3_synthesizable_bfm.v

raw_benchmarks:
	wget http://cag.csail.mit.edu/raw/benchmark_v1.0.tar.gz
	tar -xzf benchmark_v1.0.tar.gz
	@mv benchmark_v1.0/suites/ $@
	@mv benchmark_v1.0/include $@/include
	@rm -r benchmark_v1.0.tar.gz benchmark_v1.0

define raw_suite_build_src
	awk 'FNR==1{print ""}1' raw_benchmarks/include/common/main_define.v raw_benchmarks/$(1)/src/library.v | sed '/include/d' > $(1)/src.v
endef

define raw_suite_add_test
	awk 'FNR==1{print ""}1' $(1)/src.v raw_benchmarks/include/common/main_header.v raw_benchmarks/$(1)/build/$(2) raw_benchmarks/include/common/main_trailer.v | sed '/include/d' > $(1)_$(2)
endef

bheap: raw_benchmarks
	@[ -d $@ ] || mkdir $@
	@$(call raw_suite_build_src,$@)
bheap_2_32_scan.v: bheap
	@$(call raw_suite_add_test,bheap,2_32_scan.v)
bheap_4_32_scan.v: bheap
	@$(call raw_suite_add_test,bheap,4_32_scan.v)
bheap_6_32_scan.v: bheap
	@$(call raw_suite_add_test,bheap,6_32_scan.v)
bheap_8_32_scan.v: bheap
	@$(call raw_suite_add_test,bheap,8_32_scan.v)

bubblesort: raw_benchmarks
	@[ -d $@ ] || mkdir $@
	@$(call raw_suite_build_src,$@)
bubblesort_004_32_scan.v: bubblesort
	@$(call raw_suite_add_test,bubblesort,004_32_scan.v)
bubblesort_064_32_scan.v: bubblesort
	@$(call raw_suite_add_test,bubblesort,064_32_scan.v)
bubblesort_256_32_scan.v: bubblesort
	@$(call raw_suite_add_test,bubblesort,256_32_scan.v)
bubblesort_512_32_scan.v: bubblesort
	@$(call raw_suite_add_test,bubblesort,512_32_scan.v)

des: raw_benchmarks
	@[ -d $@ ] || mkdir $@
	@$(call raw_suite_build_src,$@)
des_01_scan.v: des
	@$(call raw_suite_add_test,des,01_scan.v)
des_04_scan.v: des
	@$(call raw_suite_add_test,des,04_scan.v)
des_48_scan.v: des
	@$(call raw_suite_add_test,des,48_scan.v)

fft: raw_benchmarks
	@[ -d $@ ] || mkdir $@
	@$(call raw_suite_build_src,$@)
fft_04_scan.v: fft
	@$(call raw_suite_add_test,fft,04_scan.v)
fft_16_scan.v: fft
	@$(call raw_suite_add_test,fft,16_scan.v)
fft_32_scan.v: fft
	@$(call raw_suite_add_test,fft,32_scan.v)

intmatmul: raw_benchmarks
	@[ -d $@ ] || mkdir $@
	@$(call raw_suite_build_src,$@)
intmatmul_02_8_scan.v: intmatmul
	@$(call raw_suite_add_test,intmatmul,02_8_scan.v)
intmatmul_04_8_scan.v: intmatmul
	@$(call raw_suite_add_test,intmatmul,04_8_scan.v)
intmatmul_08_8_scan.v: intmatmul
	@$(call raw_suite_add_test,intmatmul,08_8_scan.v)
intmatmul_16_8_scan.v: intmatmul
	@$(call raw_suite_add_test,intmatmul,16_8_scan.v)

jacobi: raw_benchmarks
	@[ -d $@ ] || mkdir $@
	@$(call raw_suite_build_src,$@)
jacobi_04_04_08_64_scan.v: jacobi
	@$(call raw_suite_add_test,jacobi,04_04_08_64_scan.v)
jacobi_08_08_08_64_scan.v: jacobi
	@$(call raw_suite_add_test,jacobi,08_08_08_64_scan.v)
jacobi_16_16_08_64_scan.v: jacobi
	@$(call raw_suite_add_test,jacobi,16_16_08_64_scan.v)
jacobi_32_32_08_64_scan.v: jacobi
	@$(call raw_suite_add_test,jacobi,32_32_08_64_scan.v)
jacobi_32_64_08_64_scan.v: jacobi
	@$(call raw_suite_add_test,jacobi,32_64_08_64_scan.v)

life: raw_benchmarks
	@[ -d $@ ] || mkdir $@
	@echo "" >> raw_benchmarks/life/src/cell_list.v
	@awk 'FNR==1{print ""}1' raw_benchmarks/include/common/main_define.v raw_benchmarks/life/src/library.v | sed -e "/.*cell_list.v.*/r raw_benchmarks/life/src/cell_list.v" | sed '/include/d' > $@/src.v
life_032_1_64_scan.v: life
	@$(call raw_suite_add_test,life,032_1_64_scan.v)
life_032_6_64_scan.v: life
	@$(call raw_suite_add_test,life,032_6_64_scan.v)
life_64_64_64_scan.v: life
	@$(call raw_suite_add_test,life,64_64_64_scan.v)
life_064_16_64_scan.v: life
	@$(call raw_suite_add_test,life,064_16_64_scan.v)
life_096_16_64_scan.v: life
	@$(call raw_suite_add_test,life,096_16_64_scan.v)

mergesort: raw_benchmarks
	@[ -d $@ ] || mkdir $@
	@$(call raw_suite_build_src,$@)
mergesort_008_32_scan.v: mergesort
	@$(call raw_suite_build_src,mergesort,008_32_scan.v)
mergesort_064_32_scan.v: mergesort
	@$(call raw_suite_build_src,mergesort,064_32_scan.v)
mergesort_256_32_scan.v: mergesort
	@$(call raw_suite_build_src,mergesort,256_32_scan.v)

nqueens: raw_benchmarks
	@[ -d $@ ] || mkdir $@
	@$(call raw_suite_build_src,$@)
nqueens_08_223_scan.v: nqueens
	@$(call raw_suite_build_src,nqueens,08_223_scan)
nqueens_16_1_scan.v: nqueens
	@$(call raw_suite_build_src,nqueens,16_1_scan)
nqueens_32_1_scan.v: nqueens
	@$(call raw_suite_build_src,nqueens,32_1_scan)
nqueens_64_1_scan.v: nqueens
	@$(call raw_suite_build_src,nqueens,64_1_scan)

groundhog_io_extractor:
	wget https://opencores.org/ocsvn/groundhog2009_repository/groundhog2009_repository/web_uploads/gh09.B.1.tar.gz
	tar -xzf gh09.B.1.tar.gz
	@rm gh09.B.1.tar.gz
	@mv GH09.B.1.VERILOG groundhog_io_extractor
groundhog_io_extractor.v: groundhog_io_extractor
	@ls groundhog_io_extractor/* | grep -v "test_" | xargs awk 'FNR==1{print ""}1' | sed '/include/d' > groundhog_io_extractor.v

define download_rcg
	wget http://www.ecs.umass.edu/ece/tessier/rcg/benchmarks/$(1).zip
	@unzip $(1).zip
	@rm $(1).zip
endef

dct:
	$(call download_rcg,$@)
dct.v: dct
	@awk 'FNR==1{print ""}1' dct/*.v | sed '/include/d' > $@

jpeg:
	$(call download_rcg,$@)
jpeg.v: jpeg
	@awk 'FNR==1{print ""}1' jpeg/*.v | sed '/include/d' > $@

turbo:
	$(call download_rcg,$@)
turbo.v: turbo
	@ls turbo/*.v | grep -v parameters | xargs awk 'FNR==1{print ""}1' turbo/parameters.v | sed '/include/d' > $@
three_rs_255_n:
	$(call download_rcg,$@)
three_rs_255_n.v: three_rs_255_n
	@echo "" >> three_rs_255_n/shared_multiply.h
	@ls three_rs_255_n/*.v | grep -v -e _inst -e _bb -e syndrome -e chien -e gf_multiplier -e euclid_alg.v -e locator\
			-e erasure_position.v -e gen_poly_roots.v -e mod_syndr_polyn_Q.v -e omega_buffer_1.v -e threshold_compute \
			| xargs awk 'FNR==1{print ""}1' three_rs_255_n/chien_search_alg.v three_rs_255_n/syndromes.v \
			three_rs_255_n/modified_syndrome_polyn.v three_rs_255_n/erasure_locator_polyn.v three_rs_255_n/erasure_locator_polyn_0.v\
			| sed -e '/include/r three_rs_255_n/shared_multiply.h'	| sed '/include/d' | perl -pe 's/\r\n/#/' \
			| tr '\n' '#' | sed 's/,#\t*)/)/g' | tr '#' '\n' \
			| sed "s/reg \[14:0\]channel_char/output reg \[14:0\]channel_char/" > $@

.PHONY: clean
clean:
	rm -f $(generated_files)
	rm -rf $(temp_suites)

.PHONY: dist-clean
dist-clean: clean
	rm -rf $(cores) $(suites)