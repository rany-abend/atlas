# Make all scripts runnable.
chmod 777 ./Documents/Atlas/atlas-main/01_get_and_isolate_ROIs.sh
chmod 777 ./Documents/Atlas/atlas-main/02_find_overlaps.sh
chmod 777 ./Documents/Atlas/atlas-main/03_remove_overlaps.sh
chmod 777 ./Documents/Atlas/atlas-main/04_merge_ROIs.sh

# Define root directory for new atlas and intermediate files. Can be outside the repository.
NOW=$(date +%Y%m%d-%H%M%S)
ROOTDIR=/home/ayelet/Documents/Atlas/atlas-maker/Atlas-${NOW}
mkdir ${ROOTDIR}

# Names for the 3D and 4D atlases (and color lookup table) to be created by 04_merge_ROIs.sh.
ATLAS_NAME_3D=result_atlas_3d_${NOW}
ATLAS_NAME_4D=result_atlas_4d_${NOW}
LUT_TABLE_NAME=result_atlas_LUT



# ============================================ Select source maps ===========================================

# Template T1 brain to register to:
TEMPLATE_T1=${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz

# Source atlases to include in new atlas:
DO_HYPOTHALAMUS=YES  # Hypothalamus atlas (Neudorfer et al., 2020)
DO_SUBFS=NO         # Amygdala, hippocampus, thalamus subnuclei; 4 striatal nuclei (Saygin et al., 2017; Iglesias et al., 2015, 2018)
DO_AAN=YES           # Harvard Ascending Arousal Network (AAN; midbrain and brainstem) atlas (Edlow et al., 2012)
DO_CEREBELLUM=NO    # Cerebellum atlas (Diedrichsen et al., 2009; imported from local FSL standard directory)
DO_SCHAEFER=NO     # Schaefer cortical parcellation (Schaefer et al., 2018)

# Specifications for Schaefer parcellation:
SCHAEFER_NUMNETS=Kong2022_17    # Number of networks    [ 7 / 17 / Kong2022_17 ]
SCHAEFER_NUMPARC=100            # Number of parcels     [ 100, 200, ..., 1000 ]

# Download atlases sources? (YES/NO)
# No need to download again if sources already in ROOTDIR/source.
DOWNLOAD=YES

# ===========================================================================================================


mkdir -p ${ROOTDIR}/temp ${ROOTDIR}/lists ${ROOTDIR}/atlases
TEMP_DIR=${ROOTDIR}/temp

# User-defined ROI text file.
# Each line in the file defines one ROI from one or more of the individual ROI volumes created by the scrips.
# Used by 04_merge_ROIs.sh.
ROI_FILE=${ROOTDIR}/lists/result_atlas_all_ROIs.txt

# Files that will list all individual subcortical and cortical ROIs processed by scripts.
# Produced by 01_get_and_isolate_ROIs.sh.
SUBCORTICAL_LIST=${ROOTDIR}/lists/all_subcortical_ROIs.txt
CORTICAL_LIST=${ROOTDIR}/lists/all_cortical_ROIs.txt

# File that will list all identified overlaps between ROIs.
# Produced by 02_find_overlaps.sh.
OVERLAP_FILE=${ROOTDIR}/lists/overlaps.csv


export ROOTDIR TEMPLATE_T1 DOWNLOAD DO_HYPOTHALAMUS DO_SUBFS DO_AAN DO_CEREBELLUM DO_SCHAEFER SCHAEFER_NUMNETS SCHAEFER_NUMPARC SUBCORTICAL_LIST CORTICAL_LIST OVERLAP_FILE ROI_FILE ATLAS_NAME_3D ATLAS_NAME_4D LUT_TABLE_NAME TEMP_DIR FSLDIR

echo "Atlas directory: ${ROOTDIR}."
echo "Please run 01_get_and_isolate_ROIs.sh."
