process SCORE_TREE {

    label 'process_low'
    tag "All genes"
    container = 'ecoflowucl/chopgo:r-4.3.2_python-3.10_perl-5.38'
    publishDir "$params.outdir/tables" , mode: "copy", pattern:"My_scores.tsv"
    publishDir "$params.outdir/tables" , mode: "copy", pattern:"My_sim_cores.tsv"
    publishDir "$params.outdir/tables" , mode: "copy", pattern:"My_comp_synteny_similarity.tsv"
    publishDir "$params.outdir/figures/synteny_comparisons" , mode: "copy", pattern:"My_pair_synteny_identity.pdf"
    publishDir "$params.outdir/tables" , mode: "copy", pattern:"Synteny_matrix.tsv"
    publishDir "$params.outdir/tables/synt_gene_scores" , mode: "copy", pattern:"*geneScore.tsv"
    publishDir "$params.outdir/tables" , mode: "copy", pattern:"Trans_location_version.out.txt"
    publishDir "$params.outdir/figures/synteny_comparisons" , mode: "copy", pattern:"*-all_treesort.pdf"
    publishDir "$params.outdir/tables" , mode: "copy", pattern:"Trans_Inversion_junction_merged.txt"
    publishDir "$params.outdir/tables/paired_anchor_change_junction_prediction" , mode: "copy", pattern:"*Classification_summary.tsv"

    input:
    path(anchors)
    path(simularity)
    path(gffs)
    path(beds)
    path(last)
    path(tree)


    output:
    path("My_scores.tsv"), emit: score_combine
    path("My_sim_cores.tsv"), emit: simil_combine
    path("My_pair_synteny_identity.pdf"), emit: pairwiseplot
    path("My_comp_synteny_similarity.tsv"), emit: pairdata
    path("Synteny_matrix.tsv"), emit:synmat
    path("*geneScore.tsv"), emit: pairedgenescores
    path("*SpeciesScoreSummary.txt"), emit:speciesSummary
    path("Trans_location_version.out.txt"), emit:trans_inver_summary
    path("filec"), emit: filec
    path("species_order"), emit: species_order
    path("*Classification_summary.tsv"), emit:classifications
    path "versions.yml", emit: versions

    script:
    """
    #If gff files are compressed, decompress them (useful in testing)
    if [ "\$(ls -A | grep -i \\.*.gff3.gz\$)" ]; then
       for gff in *.gff3.gz; do zcat \$gff > "\${gff%.gz}"; done
    fi

    #Run Score for each gene on how close it is to the edge of the syntenic block

    #Run score for genome X in terms of size of syntenic blacks to species Y.

    summarise_anchors.pl

    summarise_similarity.pl

    syntenicVSsimilarity.pl

    Synteny_gene_score.pl

    SyntenyScoreSummary.pl

    #Now we run newick tools to get the correct species order, based on the phylogenetic tree in nw format.

    #nw_prune $tree # This is the file called pruned_tree from Goatee

    nw_labels $tree | grep -v 'N[0-9]' > species_order

    Trans_location_Inversion_score_treeSort.pl

    #Refined junction scores:
    Best_synteny_classifier_v6.pl
    Best_synteny_classifier_v6.classify.pl

    paste -d'\t' Trans_location_version.out.txt Trans_Inversion_junction_count.txt > filec

    md5sum My_scores.tsv > My_scores.tsv.md5
    md5sum My_sim_cores.tsv > My_sim_cores.tsv.md5
    md5sum My_comp_synteny_similarity.tsv > My_comp_synteny_similarity.tsv.md5
    md5sum Synteny_matrix.tsv > Synteny_matrix.tsv.md5
    md5sum Trans_location_version.out.txt > Trans_location_version.out.txt.md5

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R version: \$(R --version | grep "R version" | sed 's/[(].*//' | sed 's/ //g' | sed 's/[^0-9]*//')
        ggplot2 version: \$(Rscript -e "as.data.frame(installed.packages())[ ,c(1,3)]" | grep ggplot2 | sed 's/  */ /g' | cut -f 3 -d " ")
        ggstar version: \$(Rscript -e "as.data.frame(installed.packages())[ ,c(1,3)]" | grep ggstar | sed 's/[^0-9]*//')
        pheatmap version: \$(Rscript -e "as.data.frame(installed.packages())[ ,c(1,3)]" | grep pheatmap | sed 's/[^0-9]*//')
        Perl version: \$(perl --version | grep "version" | sed 's/.*(//g' | sed 's/[)].*//')
    END_VERSIONS
    """
}