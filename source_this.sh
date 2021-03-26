# Define root directory (where the new atlas will be generated and
# where intermediate files will be stored). It can be outside the 
# repository.
ROOTDIR=/data/EDB/ExtRecall2/Atlas/

# Names of the 3D and 4D atlases to be created by 04_merge_ROIs.sh, and accompanying color lookup table
ATLAS_NAME_3D=atlas_allROIs297_3d
ATLAS_NAME_4D=atlas_allROIs297_4d
LUT_TABLE_NAME=atlas_allROIs297_LUT

# Template T1 brain to register to.
TEMPLATE_T1=${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz

# Download atlases sources (YES/NO)? No need to download again if sources are already in ROOTDIR/source.
DOWNLOAD=YES

# Which atlases to process in include in new atlas (YES/NO)?
DO_HYPOTHALAMUS=YES  # Hypothalamus atlas (Neudorfer et al., 2020)
DO_SUBFS=YES         # Amygdala, hippocampus, thalamus subnuclei; 4 striatal nuclei (Saygin et al., 2017; Iglesias et al., 2015, 2018)
DO_AAN=YES           # Harvard Ascending Arousal Network (AAN; midbrain and brainstem) atlas (Edlow et al., 2012)
DO_CEREBELLUM=YES    # Cerebellum atlas (Diedrichsen et al., 2009; copied from local FSL atlases directory)
DO_SCHAEFER=YES      # Include Schaefer cortical parcellation (Schaefer et al., 2018)
SCHAEFER_NUMNETS=17  # Which Shaefer parcellation: number of networks
SCHAEFER_NUMPARC=100 # Which Shaefer parcellation: number of parcels

# User-defined ROI text file. 
# Each line in the file defines one ROI from one or more of the individual ROIs created in the previous scrips.
# Used by 04_merge_ROIs.sh.
ROI_FILE=${ROOTDIR}/lists/allROIs297.txt

# Files that will list all individual subcortical and cortical ROIs processed by scripts.
# Produced by 01_get_and_isolate_ROIs.sh.
SUBCORTICAL_LIST=${ROOTDIR}/lists/all_subcortical_ROIs.txt
CORTICAL_LIST=${ROOTDIR}/lists/all_cortical_ROIs.txt

# File that will list all identified overlaps between ROIs.
# Produced by 02_find_overlaps.sh.
OVERLAP_FILE=${ROOTDIR}/lists/overlaps.csv

mkdir -p ${ROOTDIR}/temp ${ROOTDIR}/lists
TEMP_DIR=${ROOTDIR}/temp

export ROOTDIR TEMPLATE_T1 DOWNLOAD DO_HYPOTHALAMUS DO_SUBFS DO_AAN DO_CEREBELLUM DO_SCHAEFER SCHAEFER_NUMNETS SCHAEFER_NUMPARC SUBCORTICAL_LIST CORTICAL_LIST OVERLAP_FILE ROI_FILE ATLAS_NAME_3D ATLAS_NAME_4D LUT_TABLE_NAME TEMP_DIR FSLDIR

echo "Root directory is now: ${ROOTDIR}."
