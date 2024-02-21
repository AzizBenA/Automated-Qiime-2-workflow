rule all:
    input:
      "output-files/01-demux-paired-end/visualization/demux-paired-end.qzv",
      "output-files/02-dada2-denoise-paired/table.qza",
      "output-files/02-dada2-denoise-paired/rep-seqs.qza",
      "output-files/02-dada2-denoise-paired/denoising-stats.qza",
      "output-files/02-dada2-denoise-paired/visualization/denoising-stats.qzv",
      "output-files/02-dada2-denoise-paired/visualization/rep-seqs.qzv",
      "output-files/02-dada2-denoise-paired/visualization/table.qzv",
      "output-files/03-taxonomy/taxonomy.qza",
      "output-files/03-taxonomy/visualization/taxa-bar-plots.qzv",
      "output-files/03-taxonomy/visualization/krona.qzv",
      "output-files/exported-feature-table/feature-table.biom"


rule import_demultiplexed_reads:
    input:
        "manifest.csv"
    output:
        "output-files/01-demux-paired-end/demux-paired-end.qza"
    shell:
        "qiime tools import "
        "--type 'SampleData[PairedEndSequencesWithQuality]' "
        "--input-path {input} "
        "--output-path {output} "
        "--input-format PairedEndFastqManifestPhred33" 

rule demux_summarize:
    input:
        "output-files/01-demux-paired-end/demux-paired-end.qza"
    output:
        "output-files/01-demux-paired-end/visualization/demux-paired-end.qzv"
    shell:
        "qiime demux summarize \
          --i-data {input} \
          --o-visualization {output}"

rule dada2_denoise_paired:
    input:
        "output-files/01-demux-paired-end/demux-paired-end.qza"
    output:
       table = "output-files/02-dada2-denoise-paired/table.qza",
       repseqs = "output-files/02-dada2-denoise-paired/rep-seqs.qza",
       denoisingstats = "output-files/02-dada2-denoise-paired/denoising-stats.qza"
    params:
        trim_left_f = 17,
        trim_left_r = 22,
        trunc_len_f = 250,
        trunc_len_r = 250,
        n_threads = 12
    shell:
        "qiime dada2 denoise-paired "
        "--i-demultiplexed-seqs {input} "
        "--verbose "
        "--p-trim-left-f {params.trim_left_f} "
        "--p-trim-left-r {params.trim_left_r} "
        "--p-trunc-len-f {params.trunc_len_f} "
        "--p-trunc-len-r {params.trunc_len_r} "
        "--p-n-threads {params.n_threads} "
        "--o-table {output.table} "
        "--o-representative-sequences {output.repseqs} "
        "--o-denoising-stats {output.denoisingstats}"

rule tabulate_denoising_stats:
    input:
        "output-files/02-dada2-denoise-paired/denoising-stats.qza"
    output:
        "output-files/02-dada2-denoise-paired/visualization/denoising-stats.qzv"
    shell:
        "qiime metadata tabulate "
        "--m-input-file {input} "
        "--o-visualization {output}"

rule tabulate_rep_seqs:
    input:
        "output-files/02-dada2-denoise-paired/rep-seqs.qza"
    output:
        "output-files/02-dada2-denoise-paired/visualization/rep-seqs.qzv"
    shell:
        "qiime feature-table tabulate-seqs "
        "--i-data {input} "
        "--o-visualization {output}"

rule summarize_table:
    input:
        "output-files/02-dada2-denoise-paired/table.qza"
    output:
        "output-files/02-dada2-denoise-paired/visualization/table.qzv"
    shell:
        "qiime feature-table summarize "
        "--i-table {input} "
        "--o-visualization {output}"

rule classify_sklearn:
    input:
        "output-files/02-dada2-denoise-paired/rep-seqs.qza"
    output:
        "output-files/03-taxonomy/taxonomy.qza"
    params:
        n_jobs = 1
    shell:
        "qiime feature-classifier classify-sklearn " 
        "--i-classifier silva-138-99-nb-classifier.qza "
        "--i-reads {input} "
        "--verbose "
        "--p-n-jobs {params.n_jobs} "
        "--o-classification {output} "
        
rule taxa_barplot:
    input:
        "output-files/02-dada2-denoise-paired/table.qza",
        "output-files/03-taxonomy/taxonomy.qza"
    output:
        "output-files/03-taxonomy/visualization/taxa-bar-plots.qzv"
    shell:
        "qiime taxa barplot "
        "--i-table {input[0]} "
        "--i-taxonomy {input[1]} "
        "--o-visualization {output}"

rule export_feature_table:
    input:
        "output-files/02-dada2-denoise-paired/table.qza"
    output:
        "output-files/exported-feature-table/feature-table.biom"
    shell:
        "qiime tools export "
        "--input-path {input} "
        "--output-path {output}"

rule krona_plot:
    input:
        "output-files/02-dada2-denoise-paired/table.qza",
        "output-files/03-taxonomy/taxonomy.qza"
    output:
        "output-files/03-taxonomy/visualization/krona.qzv"
    shell:
        "qiime krona collapse-and-plot "
        "--i-table {input[0]} "
        "--i-taxonomy {input[1]} "
        "--o-krona-plot {output}"
