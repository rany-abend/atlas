#!/bin/bash
# This script takes a list of ROIs from ROI_FILE, and creates the new atlas files.

#********** START DEFINING **************
ATLAS_DIR=/data/EDB/ExtRecall2/Common/templates/new_atlas_test

# User-defined ROI text file. Each line in the file defines one ROI from one or more
# of the individual ROIs created in the previous scrips.
ROI_FILE=${ATLAS_DIR}/code/my_ROIs.txt

# Names of the 3D and 4D atlases to be created, and accompanying color lookup table
ATLAS_NAME_3D=my_atlas_3d
ATLAS_NAME_4D=my_atlas_4dimcp
LUT_TABLE_NAME=my_atlas_LUT2

#*********** END DEFINING ***************

mkdir -p ${ATLAS_DIR}/temp
TEMP_DIR=${ATLAS_DIR}/temp

# A volume of 0s.
${FSLDIR}/bin/fslmaths ${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz -mul 0 ${TEMP_DIR}/zero

# The output atlas files
new_atlas_3d=${ATLAS_DIR}/${ATLAS_NAME_3D}
new_atlas_4d=${ATLAS_DIR}/${ATLAS_NAME_4D}
${FSLDIR}/bin/imcp ${TEMP_DIR}/zero ${new_atlas_3d}
${FSLDIR}/bin/imcp ${TEMP_DIR}/zero ${new_atlas_4d}

temp_vol=${TEMP_DIR}/temp_vol
${FSLDIR}/bin/imcp ${TEMP_DIR}/zero ${temp_vol}

# Init color lookup table
my_atlas_LUT=${ATLAS_DIR}/${LUT_TABLE_NAME}.txt
rm -rf ${my_atlas_LUT}
echo "0 Unknown 0 0 0 0" > ${my_atlas_LUT}

# Number of ROIs to create
n_rois=$(cat ${ROI_FILE} | wc -l)
new_roi=${ATLAS_DIR}/temp/new_roi
${FSLDIR}/bin/imcp ${TEMP_DIR}/zero ${new_roi}

for ((r=1 ; r<=${n_rois} ; r++)) ; do
   # Break next ROI definition line
   ${FSLDIR}/bin/fslmaths ${new_roi} -mul 0 ${new_roi}
   roi_line=$(head -n ${r} ${ROI_FILE} | tail -n 1)
   roi_numb=$(echo ${roi_line} | awk -F: '{print $1}')
   roi_name=$(echo ${roi_line} | awk -F: '{print $2}')
   roi_comp=$(echo ${roi_line} | awk -F: '{print $3}')

   # When combining multiple ROIs into one larger ROI
   for c in $(echo ${roi_comp} | (awk -F+ 'BEGIN {OFS="\n"} $1=$1 {print $0}')) ; do
      roi_set=$( echo ${c} | awk -F_ '{print $1}')
      roi_name=$(echo ${c} | awk -F_ '{print $2}')
      echo "--Creating ROI ${roi_numb} from ${roi_set}_${roi_name}"
      ${FSLDIR}/bin/fslmaths ${new_roi} -add ${ATLAS_DIR}/atlases/${roi_set}/isolated/${roi_set}_${roi_name} ${new_roi}
   done

   # Init 4D atlas file with first ROI
   if [[ ${r} -eq 1 ]] ; then
      ${FSLDIR}/bin/imcp ${new_roi} ${new_atlas_4d}
   # Merge new ROI with accumulating 4D atlas, one volume per ROI
   else
      ${FSLDIR}/bin/imcp ${new_atlas_4d} ${temp_vol}      
      ${FSLDIR}/bin/fslmerge -t ${new_atlas_4d} ${temp_vol} ${new_roi}
   fi
   ${FSLDIR}/bin/fslmaths ${new_roi} -mul ${roi_numb} -add ${new_atlas_3d} ${new_atlas_3d}

   echo "${roi_numb} ${roi_name} $(( (${r}*3) % 255)) $(( (${r}*7) % 255)) $(( (${r}*11) % 255)) 0" >> ${my_atlas_LUT}
done

echo "Created new atlases ${new_atlas_3d} and ${new_atlas_4d}."

${FSLDIR}/bin/imrm ${new_roi} ${TEMP_DIR}/zero
