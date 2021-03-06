#! /bin/bash 

:<<EOF
This script was write to analysis 16s sequence data. Finaly get the sample_group biom file.
Use software: Qiime

The main script:
1.join_paired_ends.py:    This script takes forward and reverse Illumina reads and joins them using the method chosen

2.plit_libraries_fastq.py:   qulity control for the sequence

3.pick_open_reference_otus.py:   This script will produce an OTU mapping file (pick_otus.py), a representative set of sequences (FASTA file from pick_rep_set.py), a sequence alignment file (FASTA file from align_seqs.py), taxonomy assignment file (from assign_taxonomy.py), a filtered sequence alignment (from filter_alignment.py), a phylogenetic tree (Newick file from make_phylogeny.py) and a biom-formatted OTU table (from make_otu_table.py).This script will produce an OTU mapping file (pick_otus.py), a representative set of sequences (FASTA file from pick_rep_set.py), a sequence alignment file (FASTA file from align_seqs.py), taxonomy assignment file (from assign_taxonomy.py), a filtered sequence alignment (from filter_alignment.py), a phylogenetic tree (Newick file from make_phylogeny.py) and a biom-formatted OTU table (from make_otu_table.py).

input: data_path,in this path include the paired_end sequences file.   eg:1.1.fq.gz; 1.2.fq.gz   they must End with "***.fq.gz" 
otuput:biom file dirctory.  the biom file is outputfile/otus/otu_table_mc2_w_tax_no_pynast_failures.biom. 
EOF

if [ $# -eq 0 ];then
        echo "Usage: 16sRNA_pipeline.sh -p data_path -o output_dirctory"
        exit 1
fi

while getopts ":p:o:h" arg
do
        case $arg in
		o )	
			outputfile=$OPTARG;;
		p )
			data_path=$OPTARG;;
                h )
                        echo "Usage: 16s_pipeline.sh -p data_path -o output_dirctory"
                        exit 0;;
                ? )
                        echo "Usage: 16s_pipeline.sh -p data_path -o output_dirctory"
                        exit 1;;
        esac
done

:<<EOF
Section 1:Loading environment variable
EOF
echo
echo "===========STEP ONE============"
echo "Loading environment variable"
echo "Current time: "`date`

source /home/jianglikun/miniconda2/bin/activate qiime1
export PATH=$PATH:/home/jianglikun/16s_pipeline/qiime_data/SeqPrep

:<<EOF
Section 2:Using join_paired_ends.py joins paired-end Illumina reads
EOF
echo
echo "===========STEP TWO============"
echo "Using join_paired_ends.py joins paired-end Illumina reads"
echo "Current time: "`date`

if [ ! -f ${sample_id}_${outputfile}/seqprep_assembled.fastq.gz ];then 
DATA_dirctory=${data_path}
find $DATA_dirctory -name "*"1.fq.gz|while read sample_files;
do
	sample_id_ex=`basename $sample_files`
        sample_id=${sample_id_ex%_*}
        echo -n $sample_id"," >> all_sample_id
	echo -n ${sample_id}_${outputfile}/"fastqjoin.join.fastq," >> all_sample_seq
	if [ ! -f ${sample_id}_${outputfile}/fastqjoin.join.fastq ]; then join_paired_ends.py -f ${data_path}/${sample_id}_1.fq.gz -r ${data_path}/${sample_id}_2.fq.gz -m fastq-join -o ${sample_id}_${outputfile}
fi
done
fi


:<<EOF
Section 3:Using split_libraries_fastq.py for Quality filter
EOF
echo
echo "===========STEP THREE============"
echo "Using split_libraries_fastq.py for Quality filter"
echo "Current time: "`date`

all_sample_id=`more ./all_sample_id|sed 's/.$//'`
all_sample_seq=`more ./all_sample_seq|sed 's/.$//'`
if [ ! -f ${outputfile}/seqs.fna ]; then split_libraries_fastq.py  $all -i ${all_sample_seq} -q 19 --barcode_type not-barcoded --sample_ids ${all_sample_id} -o ${outputfile}
fi

:<<EOF
Section 4:Using pick_open_reference_otus.py Perform open-reference OTU picking
EOF
echo
echo "===========STEP FOUR============"
echo "Using pick_open_reference_otus.py Perform open-reference OTU picking"
echo "Current time: "`date`

if [ ! -f ${outputfile}/otus/otu_table_mc2_w_tax_no_pynast_failures.biom ]; then pick_open_reference_otus.py -o ${outputfile}/otus/ -i ${outputfile}/seqs.fna  -p /home/jianglikun/16s_pipeline/qiime_data/p_file -f --otu_picking_method usearch61
fi

:<<EOF
Section 5:Using R-script produce data_frame.csv file
EOF
echo
echo "===========STEP FIVE============"
echo "Using R-script produce data_frame.csv file"
echo "Current time: "`date`
cwd=`pwd`
Rscript R_for_biom.R ${cwd}/${outputfile}/otus/otu_table_mc2_w_tax_no_pynast_failures.biom ${cwd}/${outputfile}/otus/rep_set.tre ${cwd}/${outputfile}/otus/rep_set.fna 
