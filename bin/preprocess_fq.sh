#!/bin/bash
export PATH="~/projects/RNAseq/bin/:$PATH"
#export BOWTIE_INDEXES=/dbase/genomes/maize/for_filter/
wd=`pwd`
#
# initialize variables with default values
# which can be superseded with clo's
#
min_qual=13
min_length=32
percent_high_quality=90
bowtie_threads=8
BOWTIE_INDEXES='index'
#
function help_messg {
    echo "invoke script like this:"
    echo "preprocess_fq.sh min_qual min_length %high_quality #bowtie_threads"
    echo "or, to accept the default values:"
    echo "preprocess_fq.sh"
    echo "example with the default values:"
    echo "preprocess.sh --min_qual 13 --min_length 32 --percent_high_quality 90 --bowtie_threads 8"
    echo ""
}

# command line option parsing adpated from /usr/share/doc/util-linux-2.13/getopt-parse.bash
#
TEMP=`getopt -o q:l:p:t:hi: --long min_qual:,min_length:,percent_high_quality:,bowtie_threads:,indexpath: -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

while true ; do
    case "$1" in
        -q|--min_qual) min_qual=$2 ; shift 2 ;;
        -l|--min_length) min_length=$2 ; shift 2 ;;
        -p|--percent_high_quality) percent_high_quality=$2 ; shift 2 ;; 
        -t|--bowtie_threads) bowtie_threads=$2 ; shift 2 ;;
        -i|--indexpath) BOWTIE_INDEXES=$2 ; shift 2 ;;
        -h|help) help_messg ; exit ;;
#        --) shift ; break ;;
        *) break ;;
    esac
done

export BOWTIE_INDEXES
echo "min_qual min_length percent_high_quality bowtie_threads indexpath = $min_qual $min_length $percent_high_quality $bowtie_threads $BOWTIE_INDEXES"
#
echo "creating preprocess directory in $wd"
mkdir -p preprocess
mv set1.fq set1_input.fq
mv set2.fq set2_input.fq
cd preprocess
ln -sf ../set1_input.fq ./set1.fq
ln -sf ../set2_input.fq ./set2.fq
echo "quality trimming and filtering"
fastq_quality_trimmer -i set1.fq -t $min_qual -l $min_length -v 2> set1_qt.log | fastq_quality_filter -p $percent_high_quality -q $min_qual -o set1_qt_qf.fq -v > set1_qt_qf.log 
fastq_quality_trimmer -i set2.fq -t $min_qual -l $min_length -v 2> set2_qt.log | fastq_quality_filter -p $percent_high_quality -q $min_qual -o set2_qt_qf.fq -v > set2_qt_qf.log
echo "sequence similarity filtering using bowtie"
echo "reads that fail to align are retained, reads that align are filtered out of data"
echo "first data file ..."
bowtie -q --solexa1.3-quals --un set1_qt_qf_sf.fq --threads $bowtie_threads filter set1_qt_qf.fq > set1_qt_qf_filter_matched.sam 2> set1_qt_qf_bwt.log
cat set1_qt_qf_bwt.log

if [[ -e set2_qt_qf.fq ]]
then
echo "second data file"
bowtie -q --solexa1.3-quals --un set2_qt_qf_sf.fq --threads $bowtie_threads filter set2_qt_qf.fq > set2_qt_qf_filter_matched.sam 2> set2_qt_qf_bwt.log
cat set2_qt_qf_bwt.log
fi

echo "removing temporary files"
rm *.sam
#rm set?_qt_qf_sf.fq
rm set?_qt_qf.fq
echo "creating symlinks to final files"
#mv set1.fq set1_input.fq
#mv set2.fq set2_input.fq
#ln -sf set1_final.fq set1.fq
#ln -sf set2_final.fq set2.fq
cd ..
#ln -sf preprocess/set1_final_matched.fq ./set1.fq
#ln -sf preprocess/set2_final_matched.fq ./set2.fq
ln -sf preprocess/set1_qt_qf_sf.fq set1.fq
ln -sf preprocess/set2_qt_qf_sf.fq set2.fq
