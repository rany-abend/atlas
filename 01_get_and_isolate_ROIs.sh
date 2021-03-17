#!/bin/bash
# 1. Place this script and all other scripts in directory: ${ROOTDIR}/code
# 2. Define all constants in ${ROOTDIR}/code/source_this.sh
# 3. Run: source ${ROOTDIR}/code/source_this.sh
# 4. Run this script

# This script downloads (if chose to) source atlases from their orginial online locations.
# It then processes them (if chose to): it registers them all to a common MNI152 space, and
# then isolates all ROIs in all atlases into individual nii.gz files.

rm -f ${SUBCORTICAL_LIST}
rm -f ${CORTICAL_LIST}

# ==========================================================
# Some functions to parse XML files (e.g., for FSL atlases)
read_dom () { # --------------------------------------------
   local IFS=\>
   read -d \< ENTITY CONTENT
   local RET=$?
   TAG_NAME=${ENTITY%% *}
   ATTRIBUTES=${ENTITY#* }
   return $RET
   }

parse_dom () { # -------------------------------------------
   if [[ $TAG_NAME = "label" ]] ; then
      eval local $ATTRIBUTES
      echo "${index},${CONTENT//[[:blank:]]/}"
   fi
   }
# ==========================================================

# Download source files for existing atlases
if [[ ${DOWNLOAD} == "YES" ]] ; then
   echo "Downloading source atlases."
   mkdir -p ${ROOTDIR}/source/
   cd       ${ROOTDIR}/source/
   
   # Hypothalamus
   # Neudorfer C, Germann J, Elias GJB, Gramer R, Boutet A, Lozano AM.
   # A high-resolution in vivo magnetic resonance imaging atlas of the
   # human hypothalamic region. Scientific Data. 2020;7(1):305.
   # https://dx.doi.org/10.1038/s41597-020-00644-6
   # This atlas has good overlap with MNI_ICBM152_2009b
   wget -c https://zenodo.org/record/3942115/files/MNI152b_atlas_labels_0.5mm.nii.gz
   wget -c https://zenodo.org/record/3942115/files/Volumes_names-labels.csv

   # AAN (Harvard Ascending Arousal Network Atlas) 
   # Edlow BL, Takahashi E, Wu O, et al. Neuroanatomic connectivity
   # of the human ascending arousal system critical to consciousness
   # and its disorders. J Neuropathol Exp Neurol. 2012;71(6):531-546.
   # https://dx.doi.org/10.1097/NEN.0b013e3182588293
   # This atlas has good overlap with FSL's MNI162_1mm.
   wget -c http://nmr.mgh.harvard.edu/martinos/resources/aan-atlas/AAN_MNI152_1mm_v1p0.zip
   
   # Cerebellum, from FSL atlases directory
   # Diedrichsen J, Balsters JH, Flavell J, Cussans E, Ramnani N.
   # A probabilistic MR atlas of the human cerebellum.
   # Neuroimage. 2009;46(1):39-46.
   # https://dx.doi.org/10.1016/j.neuroimage.2009.01.045
   # This atlas has good overlap with FSL's MNI162_1mm.
   cp -pv ${FSLDIR}/data/atlases/Cerebellum/Cerebellum-MNIfnirt-maxprob-thr50-1mm.nii.gz .
   cp -pv ${FSLDIR}/data/atlases/Cerebellum_MNIfnirt.xml .

   # ICBM 152 Nonlinear atlases version 2009 (to drive registration)
   # Fonov V, Evans AC, Botteron K, et al. Unbiased average age-appropriate
   # atlases for pediatric studies. Neuroimage. 2011;54(1):313-327.
   # https://dx.doi.org/10.1016/j.neuroimage.2010.07.033
   wget -c http://www.bic.mni.mcgill.ca/~vfonov/icbm/2009/mni_icbm152_nlin_asym_09b_nifti.zip
   
   # Schaefer et al cortical parcellation.
   # Schaefer A, Kong R, Gordon EM, et al. Local-Global Parcellation of the 
   # Human Cerebral Cortex from Intrinsic Functional Connectivity MRI.
   # Cereb Cortex. 2018;28(9):3095-3114.
   # https://dx.doi.org/10.1093/cercor/bhx179
   wget -c https://raw.githubusercontent.com/ThomasYeoLab/CBIG/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order.lut
   wget -c https://raw.githubusercontent.com/ThomasYeoLab/CBIG/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order.txt
   wget -c https://raw.githubusercontent.com/ThomasYeoLab/CBIG/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order_FSLMNI152_1mm.nii.gz
   
else
   echo "Skipping downloads. Assumed all atlases are already in ${ROOTDIR}/source"
fi

# Process the AAN atlas?
if [[ ${DO_AAN} == "YES" ]] ; then
   echo "Working on the AAN atlas."
   
   # Unzip, delete unused files, gzip
   mkdir -p ${ROOTDIR}/atlases/AAN/isolated
   cd       ${ROOTDIR}/atlases/AAN
   unzip ${ROOTDIR}/source/AAN_MNI152_1mm_v1p0.zip 'AAN_*.nii' -d ${ROOTDIR}/atlases/AAN/
   rm -rf ${ROOTDIR}/atlases/AAN/__MACOSX
   gzip ${ROOTDIR}/atlases/AAN/AAN_*.nii
   
   # Rename files to more friendly names
   for oldname in AAN_*.nii.gz ; do
      roi=$(echo ${oldname}|awk -F_ '{print $2}')
      newname=AAN_${roi}.nii.gz
      mv ${ROOTDIR}/atlases/AAN/${oldname} ${ROOTDIR}/atlases/AAN/isolated/${newname}
   done
   
   # Add all individual ROIs to list
   ${FSLDIR}/bin/imglob ${ROOTDIR}/atlases/AAN/isolated >> ${SUBCORTICAL_LIST}

else
   echo "Skipping AAN atlas."
fi

# Process the Cerebellum atlas?
if [[ ${DO_CEREBELLUM} == "YES" ]] ; then
   echo "Working on the Cerebellum atlas."
   
   # Unzip, delete unused files, gzip
   mkdir -p ${ROOTDIR}/atlases/Cerebellum/isolated
   cd       ${ROOTDIR}/atlases/Cerebellum
   
   # Convert the XML file to a friendly CSV file
   echo "Parsing XML file"
   while read_dom ; do
      parse_dom
   done < ${ROOTDIR}/source/Cerebellum_MNIfnirt.xml > ${ROOTDIR}/atlases/Cerebellum/Cerebellum_labels.csv

   # Split the atlas into independent files, one per ROI
   nlines=$(cat ${ROOTDIR}/atlases/Cerebellum/Cerebellum_labels.csv|wc -l)
   for ((lnum=1;lnum<=${nlines};lnum++)) ; do
      roinum=$( head -n ${lnum} ${ROOTDIR}/atlases/Cerebellum/Cerebellum_labels.csv | tail -n 1 | awk -F, '{print $1}')
      roinum=$( echo "${roinum}+1" | bc -l)
      roiname=$(head -n ${lnum} ${ROOTDIR}/atlases/Cerebellum/Cerebellum_labels.csv | tail -n 1 | awk -F, '{print $2}')
      echo "Working on Cerebellum ${roiname} (ROI #${roinum})"
      ${FSLDIR}/bin/fslmaths ${ROOTDIR}/source/Cerebellum-MNIfnirt-maxprob-thr50-1mm \
                             -thr ${roinum} -uthr ${roinum} -bin \
                             ${ROOTDIR}/atlases/Cerebellum/isolated/Cerebellum_${roiname}
   done

   # Add all individual ROIs to list
   ${FSLDIR}/bin/imglob ${ROOTDIR}/atlases/Cerebellum/isolated >> ${SUBCORTICAL_LIST}
else
   echo "Skipping Cerebellum atlas."
fi

# For the Hypothalamus and for the subfield/subnuclei segmentation (in FreeSurfer), we need
# to align the MNI_ICBM152b to FSL's MNI152 (they don't perfectly overlap).
if [[ ${DO_HYPOTHALAMUS} == "YES" ]] || [[ ${DO_SUBFS} == "YES" ]] ; then 
   cd ${ROOTDIR}/source
   
   # Unzip, gzip
   rm -rf ${ROOTDIR}/source/mni_icbm152_nlin_asym_09b
   unzip ${ROOTDIR}/source/mni_icbm152_nlin_asym_09b_nifti.zip '*.nii'
   gzip  ${ROOTDIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_*
   
   # Align to FSL's MNI, keep just the affine matrix. Remove non-brain tissue first.
   echo "Running BET and FLIRT."
   ${FSLDIR}/bin/bet \
                 ${ROOTDIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_hires \
                 ${ROOTDIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_hires_brain
   ${FSLDIR}/bin/flirt \
            -in   ${ROOTDIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_hires_brain \
            -ref  ${TEMPLATE_T1} \
            -dof 6 -interp spline \
            -omat ${ROOTDIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_fsl.mat
   ${FSLDIR}/bin/imrm ${ROOTDIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_hires_brain
fi

# Process the Hypothalamus atlas?
if [[ ${DO_HYPOTHALAMUS} == "YES" ]] ; then
   echo "Working on the Hypothalamus atlas."
   
   # Ensure we have a list of ROIs in this directory
   mkdir -p ${ROOTDIR}/atlases/Hypothalamus/isolated
   cp -p ${ROOTDIR}/source/Volumes_names-labels.csv ${ROOTDIR}/atlases/Hypothalamus
   dos2unix ${ROOTDIR}/atlases/Hypothalamus/Volumes_names-labels.csv
   echo "" >> ${ROOTDIR}/atlases/Hypothalamus/Volumes_names-labels.csv
   sed -i "s/R_/Right_/" ${ROOTDIR}/atlases/Hypothalamus/Volumes_names-labels.csv
   sed -i "s/L_/Left_/"  ${ROOTDIR}/atlases/Hypothalamus/Volumes_names-labels.csv

   # Align to FSL's MNI standard using the affine matrix produced earlier
   ${FSLDIR}/bin/flirt \
             -in   ${ROOTDIR}/source/MNI152b_atlas_labels_0.5mm \
             -ref  ${TEMPLATE_T1} \
             -init ${ROOTDIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_fsl.mat \
             -applyxfm -interp nearestneighbour \
             -out  ${ROOTDIR}/atlases/Hypothalamus/MNI152b_atlas_labels_1mm
   
   # Split the atlas into independent files, one per ROI
   nlines=$(cat ${ROOTDIR}/atlases/Hypothalamus/Volumes_names-labels.csv|wc -l)
   for ((lnum=2;lnum<=${nlines};lnum++)) ; do
      roinum=$( head -n ${lnum} ${ROOTDIR}/atlases/Hypothalamus/Volumes_names-labels.csv | tail -n 1 | awk -F, '{print $1}')
      roiname=$(head -n ${lnum} ${ROOTDIR}/atlases/Hypothalamus/Volumes_names-labels.csv | tail -n 1 | awk -F, '{print $4}')
      roiname=${roiname//[[:blank:]]/}
      roiname=${roiname/_/-}
      echo "Working on Hypothalamus ${roiname} (ROI #${roinum})"
      ${FSLDIR}/bin/fslmaths ${ROOTDIR}/atlases/Hypothalamus/MNI152b_atlas_labels_1mm \
                             -thr ${roinum} -uthr ${roinum} -bin \
                             ${ROOTDIR}/atlases/Hypothalamus/isolated/Hypothalamus_${roiname}
   done

   # Add all individual ROIs to list
   ${FSLDIR}/bin/imglob ${ROOTDIR}/atlases/Hypothalamus/isolated >> ${SUBCORTICAL_LIST}

else
   echo "Skipping Hypothalamus atlas."
fi

# Process the FreeSurfer amygdala, hippocampus, and thalamus subfield/subnuclei segmentations?
if [[ ${DO_SUBFS} == "YES" ]] ; then
   echo "Working on amygdala, hippocampus, and thalamus subfield/subnuclei segmentation."
   
   # Ensure we have a whole-head version of the MNI_ICBM152b in FSL's MNI.
   # For this we can use the affine matrix we produced earlier.
   mkdir -p ${ROOTDIR}/atlases/FreeSurfer/isolated
   ${FSLDIR}/bin/flirt \
          -in   ${ROOTDIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_hires \
          	-ref  ${TEMPLATE_T1} \
          -init ${ROOTDIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_fsl.mat \
          -applyxfm -interp spline \
          -out  ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl

   # Run FreeSurfer!
   if [[ ! -f ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.mgz ]] ; then
      ${FREESURFER_HOME}/bin/recon-all -s  mni_icbm152b_fsl \
                                       -i  ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl.nii.gz \
                                       -sd ${ROOTDIR}/atlases/FreeSurfer -all

      # Run the subfield/subnuclei segmentation for hippocampus, amygdala, and thalamus
      ${FREESURFER_HOME}/bin/segmentHA_T1.sh mni_icbm152b_fsl ${ROOTDIR}/atlases/FreeSurfer
      ${FREESURFER_HOME}/bin/segmentThalamicNuclei.sh mni_icbm152b_fsl ${ROOTDIR}/atlases/FreeSurfer
   else
      echo "FreeSurfer run already found. Skipping."
   fi
   
   # Convert the relevant outputs from MGZ to NIFTI
   ${FREESURFER_HOME}/bin/mri_convert \
                     ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/aseg.mgz \
                     ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/aseg.nii.gz
   ${FREESURFER_HOME}/bin/mri_convert \
                     ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.mgz \
                     ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.nii.gz
   ${FREESURFER_HOME}/bin/mri_convert \
                     ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/lh.hippoAmygLabels-T1.v21.FSvoxelSpace.mgz \
                     ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/lh.hippoAmygLabels-T1.v21.FSvoxelSpace.nii.gz
   ${FREESURFER_HOME}/bin/mri_convert \
                     ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/rh.hippoAmygLabels-T1.v21.FSvoxelSpace.mgz \
                     ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/rh.hippoAmygLabels-T1.v21.FSvoxelSpace.nii.gz
   ${FREESURFER_HOME}/bin/mri_convert \
                     ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/orig.mgz \
                     ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/orig.nii.gz

   # Register the conformed orig to the original (input) space, keep the affine matrix
   ${FSLDIR}/bin/flirt \
          -in   ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/orig \
          -ref  ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -dof 6 -interp spline \
          -omat ${ROOTDIR}/atlases/FreeSurfer/conformed_to_original.mat
   
   # Apply the transformation to the subfields/subnuclei, with nearest neighbor interpolation
   ${FSLDIR}/bin/flirt \
          -in   ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/aseg \
          -ref  ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -init ${ROOTDIR}/atlases/FreeSurfer/conformed_to_original.mat \
          -applyxfm -interp nearestneighbour \
          -out  ${ROOTDIR}/atlases/FreeSurfer/aseg.MNISpace
   ${FSLDIR}/bin/flirt \
          -in   ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/ThalamicNuclei.v12.T1.FSvoxelSpace \
          -ref  ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -init ${ROOTDIR}/atlases/FreeSurfer/conformed_to_original.mat \
          -applyxfm -interp nearestneighbour \
          -out  ${ROOTDIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace
   for h in lh rh ; do
      ${FSLDIR}/bin/flirt \
          -in   ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace \
          -ref  ${ROOTDIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -init ${ROOTDIR}/atlases/FreeSurfer/conformed_to_original.mat \
          -applyxfm -interp nearestneighbour \
          -out  ${ROOTDIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace
   done
   
   # Generate text files with the list of labels, get the label names from the
   # FreeSurferColorLUT.txt, and split into separate regions.
   
   # First for the subcortical segmentations from aseg
   ${FSLDIR}/bin/fsl2ascii \
          ${ROOTDIR}/atlases/FreeSurfer/aseg.MNISpace.nii.gz \
          ${ROOTDIR}/atlases/FreeSurfer/aseg.MNISpace.txt
   cat ${ROOTDIR}/atlases/FreeSurfer/aseg.MNISpace.txt00000 |\
          sed -z 's/\n//g'|sed 's/\ /\n/g'|sort|uniq > \
          ${ROOTDIR}/atlases/FreeSurfer/aseg.labels.txt
   for lab in $(cat ${ROOTDIR}/atlases/FreeSurfer/aseg.labels.txt) ; do
      if [[ ${lab} -gt 0 ]] ; then
         roinum=${lab}
         roiname=$(awk -v "lab=${lab}" '$1 == lab {print $2}' ${FREESURFER_HOME}/FreeSurferColorLUT.txt|sed 's/_/-/g')
         echo "Working on subcortical segmentations/aseg ${roiname} (ROI #${roinum})"
         ${FSLDIR}/bin/fslmaths ${ROOTDIR}/atlases/FreeSurfer/aseg.MNISpace \
                             -thr ${roinum} -uthr ${roinum} -bin \
                             ${ROOTDIR}/atlases/FreeSurfer/isolated/aseg_${roiname}
      fi
   done
   
   # Then for the Thalamus
   ${FSLDIR}/bin/fsl2ascii \
          ${ROOTDIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace.nii.gz \
          ${ROOTDIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace.txt
   cat ${ROOTDIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace.txt00000 |\
          sed -z 's/\n//g'|sed 's/\ /\n/g'|sort|uniq > \
          ${ROOTDIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.labels.txt
   for lab in $(cat ${ROOTDIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.labels.txt) ; do
      if [[ ${lab} -gt 0 ]] ; then
         roinum=${lab}
         roiname=$(awk -v "lab=${lab}" '$1 == lab {print $2}' ${FREESURFER_HOME}/FreeSurferColorLUT.txt|sed 's/_/-/g')
         echo "Working on Thalamus ${roiname} (ROI #${roinum})"
         ${FSLDIR}/bin/fslmaths ${ROOTDIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace \
                             -thr ${roinum} -uthr ${roinum} -bin \
                             ${ROOTDIR}/atlases/FreeSurfer/isolated/Thalamus_${roiname}
      fi
   done
   rm  ${ROOTDIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace.txt00000

   # Then for the Amygdala and Hippocampus
   for h in lh rh ; do
      hemi=Left
      if [[ ${h} == "rh" ]]; then hemi=Right; fi

      ${FSLDIR}/bin/fsl2ascii \
          ${ROOTDIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace \
          ${ROOTDIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace.txt
      cat ${ROOTDIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace.txt00000 |\
          sed -z 's/\n//g'|sed 's/\ /\n/g'|sort|uniq > \
          ${ROOTDIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.labels.txt
      for lab in $(cat ${ROOTDIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.labels.txt) ; do
         if [[ ${lab} -gt 7000 ]] ; then
            struc=Amygdala
         else
            struc=Hippocampus
         fi
         if [[ ${lab} -gt 0 ]] ; then
            roinum=${lab}
            roiname=$(awk -v "lab=${lab}" '$1 == lab {print $2}' ${FREESURFER_HOME}/FreeSurferColorLUT.txt|sed 's/_/-/g')
            echo "Working on ${struc} ${h}-${roiname} (ROI #${roinum})"
            ${FSLDIR}/bin/fslmaths ${ROOTDIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace \
                                -thr ${roinum} -uthr ${roinum} -bin \
                                ${ROOTDIR}/atlases/FreeSurfer/isolated/${struc}_${hemi}-${roiname}
         fi
      done
      rm  ${ROOTDIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace.txt00000
   done

   str_dir=${ROOTDIR}/atlases/FreeSurfer/isolated
   # Rename 4 striatum nuclei
   for h in Left Right ; do
   	mv ${str_dir}/aseg_${h}-Accumbens-area.nii.gz ${str_dir}/Striatum_${h}-Accumbens-area.nii.gz
	mv ${str_dir}/aseg_${h}-Caudate.nii.gz ${str_dir}/Striatum_${h}-Caudate.nii.gz
	mv ${str_dir}/aseg_${h}-Pallidum.nii.gz ${str_dir}/Striatum_${h}-Pallidum.nii.gz
	mv ${str_dir}/aseg_${h}-Putamen.nii.gz ${str_dir}/Striatum_${h}-Putamen.nii.gz
   done

   # Move isolated files into dedicated directories; add to list of ROIs
   for set in Amygdala Hippocampus Thalamus Striatum ; do
   	mkdir -p ${ROOTDIR}/atlases/${set}/isolated
   	mv ${ROOTDIR}/atlases/FreeSurfer/isolated/${set}* ${ROOTDIR}/atlases/${set}/isolated
   	${FSLDIR}/bin/imglob ${ROOTDIR}/atlases/${set}/isolated/ >> ${SUBCORTICAL_LIST}
   done

   # Move remaining files that are not used to source directory so they will not be included in atlas
   mv ${ROOTDIR}/atlases/FreeSurfer ${ROOTDIR}/source/
   
   sed -i "s/.nii.gz//" ${SUBCORTICAL_LIST}
 
else
   echo "Skipping FreeSurfer subfield/subnuclei segmentation."
fi

echo "Finished isolating subcortical ROIs; listed in ${SUBCORTICAL_LIST}."

# Process the Schaefer cortical parcellation?
if [[ ${DO_SCHAEFER} == "YES" ]] ; then
   echo "Working on the Schaefer parcellation."
   
   # Unzip, delete unused files, gzip
   mkdir -p ${ROOTDIR}/atlases/Schaefer/isolated
   cd       ${ROOTDIR}/atlases/Schaefer
   
   # Convert the XML file to a friendly CSV file
   echo "Parsing list of parcellation labels."
   awk 'BEGIN {OFS=","} {print NR, $2}' ${ROOTDIR}/source/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order.txt | \
      sed 's/_/-/g'| sed "s/${SCHAEFER_NUMNETS}Networks-/Schaefer_/g" | \
      sed 's/Schaefer_LH-/Schaefer_Left-/g' | \
      sed 's/Schaefer_RH-/Schaefer_Right-/g' > ${ROOTDIR}/atlases/Schaefer/Schaefer_labels.csv

   # Split the parcellation into independent files, one per ROI
   nlines=$(cat ${ROOTDIR}/atlases/Schaefer/Schaefer_labels.csv|wc -l)
   for ((lnum=1;lnum<=${nlines};lnum++)) ; do
      roinum=$( head -n ${lnum} ${ROOTDIR}/atlases/Schaefer/Schaefer_labels.csv | tail -n 1 | awk -F, '{print $1}')
      roiname=$(head -n ${lnum} ${ROOTDIR}/atlases/Schaefer/Schaefer_labels.csv | tail -n 1 | awk -F, '{print $2}')
      echo "Working on Schaefer ${roiname#Schaefer_} (ROI #${roinum})"
      ${FSLDIR}/bin/fslmaths ${ROOTDIR}/source/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order_FSLMNI152_1mm \
                             -thr ${roinum} -uthr ${roinum} -bin \
                             ${ROOTDIR}/atlases/Schaefer/isolated/${roiname}
   done
   
   # Make a list in the same format as the list for subcortical, so that overlaps
   # can be tested and then ROIs can be merged. List includes number labels.
   lab=1001
   for roiname in $(awk -F, '{print $2}' ${ROOTDIR}/atlases/Schaefer/Schaefer_labels.csv|grep "Schaefer_Left-") ; do
      echo "${lab}:${roiname}:${roiname}" >> ${CORTICAL_LIST}
      ((lab++))
   done
   lab=2001
   for roiname in $(awk -F, '{print $2}' ${ROOTDIR}/atlases/Schaefer/Schaefer_labels.csv|grep "Schaefer_Right-") ; do
      echo "${lab}:${roiname}:${roiname}" >> ${CORTICAL_LIST}
      ((lab++))
   done

   echo "Finished isolating cortical parcels; listed in ${CORTICAL_LIST}."

else
   echo "Skipping cortical parcellation."
fi

echo "Done!"
