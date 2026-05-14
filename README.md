# GenePull

Tool to extract a certain gene from an assembly using Blast. There is an update of that tool that manages automatization and usage of this tool with multiple genomes and genes at the same time

## Requirements

GenePull interactive bash script which runs in the linux command line. To download, simply use:

```
wget https://raw.githubusercontent.com/Rowena-h/MiscGenomicsTools/main/GenePull/GenePull
```
GenePull automatized bash script:
```
wget https://raw.githubusercontent.com/Rowena-h/MiscGenomicsTools/main/GenePull/GenePull
```
Make the script executable with:

```
chmod +x GenePull
```

[BLAST+](https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download) and [bedtools](https://bedtools.readthedocs.io/en/latest/) must be installed for the script to work.

## GenePull Usage

Option | Description
------ | -----------
-h, --help | Display these options
-a, --assembly | A genome assembly in fasta format
-g, --gene | Gene of closely related species in fasta format
-o, --output | Prefix for output file

If there are multiple hits for the query gene, you will be shown the blast results and asked which hit you want to extract. To pick multiple hits, numbers must be separated by commas (e.g. `1,2,5,6,8`). Alternatively all hits can be extracted by typing `a`.

### Example

```
./GenePull -a assembly.fa -g LSU.fa -o LSU_result
```

## GenePull automatic

This is ment to run in a cluster, but you are free to 'unsilence' the messages and ignore the SLURM commands to run it locally.

The script automatically detects the input folders:

- **genomes**: stores the unziped assemblies, it can manage messy folder inceptions NCBI and other databases provide when downloading a genome assembly.
- **genes_to_pull**: desired genes to extract as individual fasta files. I recommend to use simple short names for this files.

```
genepull
|
├── GenePull.sh
|
├── genomes
│   └── *
│       └── *.fasta
├── genes_to_pull
│   └── *random_gene_name*.fasta
├── results
│   └── *random_gene_name*
│       └── *.fasta
└── logs
     └── *.log
```
The expected outpout folders are:

- **results**: here the script will create a folder with the name of each of the genes found in *genes_to_pull* and will store the hits obtained in fasta format.
- **logs**: all errors, warnings and additional info will be found here named as the *gene_genome.log*.



