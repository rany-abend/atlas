#!/bin/bash

# This script removes subcortical-subcortical overlaps (between atlases)
# and subcortical-cortical overlaps (between atlases and parcellation, if used).


# Number of overlaps to fix
n_rois=$(cat ${OVERLAP_FILE} | wc -l)
echo "Fixing ${n_rois} overlaps in overlap file ${OVERLAP_FILE}."

# Break line defining next overlap in file
for (( p=1; p<=${n_rois}; p++ )) ; do

   roi_pair=$(head -n ${p} ${OVERLAP_FILE} | tail -n 1)

   roi1_str=$(echo ${roi_pair} | awk 'BEGIN {FS="[,]"} {print $1}')
   roi1_set=$(echo ${roi1_str} | awk 'BEGIN {FS="[_]"} {print $1}')
   roi1_nam=$(echo ${roi1_str} | awk 'BEGIN {FS="[_]"} {print $2}')

   roi2_str=$(echo ${roi_pair} | awk 'BEGIN {FS="[,]"} {print $2}')
   roi2_set=$(echo ${roi2_str} | awk 'BEGIN {FS="[_]"} {print $1}')
   roi2_nam=$(echo ${roi2_str} | awk 'BEGIN {FS="[_]"} {print $2}')

   over_siz=$(echo ${roi_pair} | awk 'BEGIN {FS="[,]"} {print $3}')
   roi1=${ROOTDIR}/atlases/${roi1_set}/isolated/${roi1_str}
   roi2=${ROOTDIR}/atlases/${roi2_set}/isolated/${roi2_str}

   echo "--Working on ${roi1_set}/${roi1_nam} and ${roi2_set}/${roi2_nam}; removing from ${roi2_set}/${roi2_nam}, ${over_siz} voxels"
   
   # Remove overlap from ROI2 file and save as ROI2 file again
   ${FSLDIR}/bin/fslmaths ${roi1} -mul ${roi2} -sub ${roi2} -mul -1 ${roi2}

done

echo "============================="
echo "Summary:"
echo "Fixed ${n_rois} overlaps."
echo "Ready to merge ROIs and create atlas using 04_merge_ROIs.sh ."


