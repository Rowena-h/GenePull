#!/bin/bash

# Script to pull several reference genes from several genomes (requires blast)
# Adapted to run on SLURM so all errors and warnings are redirected to a log file with the name of the querry

#SBATCH --job-name=GenePull_Loop
#SBATCH --output=logs/genepull_%j.out
#SBATCH --error=logs/genepull_%j.err
#SBATCH --time=24:00:00       # Adjust
#SBATCH --mem=4G              # Adjust
#SBATCH --cpus-per-task=1
#SBATCH --partition=standard  # Adjust

# Directories

# Reference genes
REF_DIR="../genepull/genes_to_pull"
# Genomes to exctract genes
GENOME_DIR="../genepull/genomes"
# Output folder
OUTPUT_DIR="../genepull/results"

# Create directories if they dont exist
mkdir -p "$OUTPUT_DIR"
mkdir -p logs

################################
# Automatic Gene pull function
################################

run_genepull() {
    local ASSEMBLY="$1"
    local GENE="$2"
    local OUT="$3"

    local GENE_LABEL=$(echo $GENE | sed 's#/##g')

    # Make blast database
    makeblastdb -in "$ASSEMBLY" -dbtype nucl -logfile /dev/null

    # Blast genes against contigs
    blastn -query "$GENE" -db "$ASSEMBLY" \
        -outfmt '6 qseqid sseqid length pident bitscore evalue sstart send' \
        -out "${ASSEMBLY}_${GENE_LABEL}_blast"

    # No hits
    if [[ ! -s "${ASSEMBLY}_${GENE_LABEL}_blast" ]]; then
        rm -f "${ASSEMBLY}_${GENE_LABEL}_blast"
        return 1  # signals "no hits" to the caller
    fi

    # Convert all hits to BED, respecting orientation
    # Warns about the orientation, might not be really neat for short coincidences
    local tmp_bed=$(mktemp)
    while IFS=$'\t' read -r qseqid sseqid length pident bitscore evalue sstart send; do
        if [[ "$sstart" -gt "$send" ]]; then
        	echo "  WARNING: Sequence ${i} (${sseqid}) is in the opposite orientation to the query and may need to be reverse complemented" >&2
            printf '%s\t%s\t%s\n' "$sseqid" "$send" "$sstart"
        else
            printf '%s\t%s\t%s\n' "$sseqid" "$sstart" "$send"
        fi
    done < "${ASSEMBLY}_${GENE_LABEL}_blast" > "$tmp_bed"

    # Extract sequences
    bedtools getfasta -fi "$ASSEMBLY" -bed "$tmp_bed" > "${OUT}.fasta"

    # Cleanup
    rm -f "$tmp_bed" "${ASSEMBLY}_${GENE_LABEL}_blast"
    return 0
}

################################
# Prepare file list
################################

# List of genes to pull
shopt -s nullglob
ref_files=("$REF_DIR"/*.fas "$REF_DIR"/*.fasta "$REF_DIR"/*.fna) # asses ambiguity of formats
shopt -u nullglob

# Evaluete presence of files in the directory
if [ ${#ref_files[@]} -eq 0 ]; then
    echo "ERROR: No reference files found in $REF_DIR"
    exit 1
fi

# amount of reference genes to evaluate 
#echo "Found ${#ref_files[@]} reference files to process."

# Loop through each reference gene
for ref_file in "${ref_files[@]}"; do
    gene_name=$(basename "$ref_file" | sed 's/\.[^.]*$//')

    #echo "PROCESSING GENE: $gene_name"

    # Then each gene loops over each genome
    # Downloaded genomes can have several folders, search for the specific documents
    shopt -s nullglob
    mapfile -t genome_files < <(find "$GENOME_DIR" -type f \( -name "*.fas" -o -name "*.fasta" -o -name "*.fna" \)) # asses ambiguity of formats
    shopt -u nullglob
    
    # look for coincidences
    if [ ${#genome_files[@]} -eq 0 ]; then
        echo " ERROR: No genome files found in $GENOME_DIR" >> "logs/genepull_${gene_name}_${genome_name}.log"
        exit 1
    fi

    # create a folder for each gene evaluated so the outpout is easier to follow
    # create a .fasta file based on the name of the genome to store the results
    for genome_file in "${genome_files[@]}"; do
        genome_name=$(basename "$genome_file" | sed 's/\.[^.]*$//')
        
        gene_dir="$OUTPUT_DIR/$gene_name"
        mkdir -p "$gene_dir"
        out_file="$gene_dir/${genome_name}.fasta"

        if [ -f "$out_file" ] && [ -s "$out_file" ]; then
            echo "  SKIP: $gene_name x $genome_name (already exists)" >> "logs/genepull_${gene_name}_${genome_name}.log"
            continue
        fi

        #echo "  RUNNING: $gene_name x $genome_name"

    ################################
		# Gene pull function
		################################
        run_genepull "$genome_file" "$ref_file" "$gene_dir/$genome_name" \
    	> "logs/genepull_${gene_name}_${genome_name}.log" 2>&1

		exit_code=$?
		if [ "$exit_code" -ne 0 ]; then
    		echo "  NO HITS: $gene_name x $genome_name" >> "logs/genepull_${gene_name}_${genome_name}.log"
    		continue
		fi

		if [ ! -s "$gene_dir/${genome_name}.fasta" ]; then
	    	echo "  WARNING: $gene_name x $genome_name — output empty" >> "logs/genepull_${gene_name}_${genome_name}.log"
		else
   			 echo "  SUCCESS: $gene_name x $genome_name -> $gene_dir/${genome_name}.fasta" >> "logs/genepull_${gene_name}_${genome_name}.log"
			fi
		################################
    done
done
