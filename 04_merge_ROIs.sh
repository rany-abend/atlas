#!/bin/bash
# This script takes a list of ROIs (code/ROI_FILE), and creates the new atlas files.

# A volume of 0s.
${FSLDIR}/bin/fslmaths ${TEMPLATE_T1} -mul 0 ${TEMP_DIR}/zero

# The output atlas files
new_atlas_3d=${ROOTDIR}/${ATLAS_NAME_3D}
new_atlas_4d=${ROOTDIR}/${ATLAS_NAME_4D}
${FSLDIR}/bin/imcp ${TEMP_DIR}/zero ${new_atlas_3d}
${FSLDIR}/bin/imcp ${TEMP_DIR}/zero ${new_atlas_4d}

# Init color lookup table
my_atlas_LUT=${ROOTDIR}/${LUT_TABLE_NAME}.txt
rm -rf ${my_atlas_LUT}
echo "0 Unknown 0 0 0 0" > ${my_atlas_LUT}

# Number of ROIs to create
n_rois=$(cat ${ROI_FILE} | wc -l)
new_roi=${TEMP_DIR}/new_roi
${FSLDIR}/bin/imcp ${TEMP_DIR}/zero ${new_roi}

for ((r=1 ; r<=${n_rois} ; r++)) ; do
   # Init new_roi with 0s
   ${FSLDIR}/bin/fslmaths ${new_roi} -mul 0 ${new_roi}
   # Break next ROI definition line
   roi_line=$(head -n ${r} ${ROI_FILE} | tail -n 1)
   roi_numb=$(echo ${roi_line} | awk -F: '{print $1}')
   roi_name=$(echo ${roi_line} | awk -F: '{print $2}')
   roi_comp=$(echo ${roi_line} | awk -F: '{print $3}')

   # When combining multiple ROIs into one larger ROI
   for c in $(echo ${roi_comp} | (awk -F+ 'BEGIN {OFS="\n"} $1=$1 {print $0}')) ; do
      roi_cset=$(echo ${c} | awk -F_ '{print $1}')
      roi_cnam=$(echo ${c} | awk -F_ '{print $2}')
      echo "--Creating ROI ${roi_numb} from ${roi_cset}_${roi_cnam}"
      ${FSLDIR}/bin/fslmaths ${new_roi} -add ${ROOTDIR}/atlases/${roi_cset}/isolated/${roi_cset}_${roi_cnam} ${new_roi}
   done

   # Init 4D atlas file with first ROI
   if [[ ${r} -eq 1 ]] ; then
      ${FSLDIR}/bin/imcp ${new_roi} ${new_atlas_4d}
   # Merge new ROI with accumulating 4D atlas, one volume per ROI
   else
      ${FSLDIR}/bin/fslmerge -t ${new_atlas_4d} ${new_atlas_4d} ${new_roi}
   fi
   # Merge new ROI with accumulating 3D atlas, all in one volume
   ${FSLDIR}/bin/fslmaths ${new_roi} -mul ${roi_numb} -add ${new_atlas_3d} ${new_atlas_3d}

   # Add new ROI to color lookup table
   echo "${roi_numb} ${roi_name} $(( (${r}*3) % 255)) $(( (${r}*7) % 255)) $(( (${r}*11) % 255)) 0" >> ${my_atlas_LUT}
done

echo "Created new 3D atlas: ${new_atlas_3d}."
echo "Created new 4D atlas: ${new_atlas_4d}."

${FSLDIR}/bin/imrm ${new_roi} ${TEMP_DIR}/zero
