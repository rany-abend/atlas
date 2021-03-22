#!/bin/bash
# This script identifies overlaps among all atlases.
# Output is saved in ${ROOTDIR}/lists/OVERLAP_FILE. 
# In the file, each line specifies one overlap: ROI1 name, ROI2 name, overlap size, overlap coordinates.

mkdir -p ${ROOTDIR}/lists/
rm -f ${OVERLAP_FILE}

# List all atlases
all_atlases=$(echo $(ls ${ROOTDIR}/atlases/))
n_atlases=$(echo ${all_atlases}|wc -w)

echo "Identifying overlaps among ${n_atlases} atlases: ${all_atlases}."
echo "This might take a while..."

# Fill array with atlas directory names
atlas_num=1
for atlas in ${all_atlases} ; do
   ARR[${atlas_num}]=${atlas}
   ((atlas_num++))
done

n_overlaps=0
for ((atlas1=1;atlas1<=${n_atlases};atlas1++)) ; do
    # For all atlas1 and atlas2 pairs
    for ((atlas2=${atlas1}+1;atlas2<=${n_atlases};atlas2++)) ; do
      echo "--Investigating overlaps between ${ARR[${atlas1}]} ROIs and ${ARR[${atlas2}]} ROIs"
      for roiA in ${ROOTDIR}/atlases/${ARR[${atlas1}]}/isolated/* ; do
         for roiB in ${ROOTDIR}/atlases/${ARR[${atlas2}]}/isolated/* ; do
            # Save overlap
            ${FSLDIR}/bin/fslmaths ${roiA} -mul ${roiB} ${TEMP_DIR}/overlap
	    # Extract max value, size, and location of overlap
            stats=$(${FSLDIR}/bin/fslstats ${TEMP_DIR}/overlap -R -V -x)
            maxval=$(echo ${stats}|awk '{print $2}')
            maxval=${maxval//[[:blank:]]/}
            # If there is an overlap
            if (( $(echo "${maxval} > 0" |bc -l ) )) ; then
	       size=$(echo ${stats}|awk '{print $3}')
               coor=$(echo ${stats}|awk '{print $5,$6,$7}')
               roiA_name=$(basename $(${FSLDIR}/bin/remove_ext ${roiA}))
               roiB_name=$(basename $(${FSLDIR}/bin/remove_ext ${roiB}))
               # Save overlap in OVERLAP_FILE
               echo "${roiA_name},${roiB_name},${size},${coor}" | tee -a ${OVERLAP_FILE}
	       ((n_overlaps++))
            fi
         done
      done
   done
done

echo "============================="
echo "Summary:"
echo "Identified ${n_overlaps} overlaps; saved in ${ROOTDIR}/lists/${OVERLAP_FILE}."
echo "Ready to remove overlaps using 03_remove_overlaps.sh ."
