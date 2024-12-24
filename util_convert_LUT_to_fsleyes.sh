#!/bin/bash

# This script reads the atlas output lookup table and creates a new table in a fsleyes-compatible format.

BASE_LUT=${ROOTDIR}/result_atlas_LUT.txt
FSLEYES_LUT=${ROOTDIR}/result_atlas_LUT_fsleyes.txt

n_rois=$(cat ${BASE_LUT} | wc -l)
for ((r=1 ; r<=${n_rois} ; r++)) ; do
   # Break next ROI definition line
   roi_line=$(head -n ${r} ${BASE_LUT} | tail -n 1)
   echo "roi_line: $roi_line"
   roi_numb=$(echo ${roi_line} | awk -F' ' '{print $1}')
   echo "roi_numb: $roi_numb"
   roi_name=$(echo ${roi_line} | awk -F' ' '{print $2}')
   echo "roi_name: $roi_name"
   R=$(echo ${roi_line} | awk -F' ' '{print $3}')
   G=$(echo ${roi_line} | awk -F' ' '{print $4}')
   B=$(echo ${roi_line} | awk -F' ' '{print $5}')

   # Fix Schaefer asymmetry
   if [[ ${roi_name} == *"Schaefer"* ]] ; then
      R=$(echo "(${R} % 90)" | bc)
      G=$(echo "(${G} % 220)" | bc)
      B=$(echo "(${B} % 90)" | bc)
   fi
   R=$(echo "scale=6; ${R}/255" | bc -l) 
   G=$(echo "scale=6; ${G}/255" | bc -l) 
   B=$(echo "scale=6; ${B}/255" | bc -l) 

   echo "${roi_numb} ${R} ${G} ${B} ${roi_name}" >> ${FSLEYES_LUT}
done