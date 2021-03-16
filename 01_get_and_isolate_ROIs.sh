#!/bin/bash
# Place this script and all other scripts in directory: ${ATLAS_DIR}/code.
# Choose which original atlases to download and process.
# Isolate ROIs from these atlases into different files.

#********** START DEFINING **************
# Choose YES or NO to download atlases sources
DOWNLOAD=NO

# Which atlases to include?
DO_AAN=YES		# Harvard Ascending Arousal Network (AAN; midbrain and brainstem) atlas (Edlow et al., 2012)
DO_CEREBELLUM=YES	# Cerebellum atlas (Diedrichsen et al., 2009; copied from local FSL atlases directory)
DO_HYPOTHALAMUS=YES	# Hypothalamus atlas (Neudorfer et al., 2020)
DO_SUBFS=YES		# Amygdala, hippocampus, thalamus subnuclei; 4 striatal nuclei (Saygin et al., 2017; Iglesias et al., 2015, 2018)
DO_SCHAEFER=YES		# Include Schaefer cortical parcellation (Schaefer et al., 2018)
SCHAEFER_NUMNETS=17	# Which Shaefer parcellation: number of networks
SCHAEFER_NUMPARC=100	# Which Shaefer parcellation: number of parcels

# Working directory
ATLAS_DIR=/data/EDB/ExtRecall2/Common/templates/new_atlas_test

# Files that will list all individual subcortical and cortical ROIs processed by script.
SUBCORTICAL_LIST=${ATLAS_DIR}/code/all_subcortical_ROIs.txt
CORTICAL_LIST=${ATLAS_DIR}/code/all_cortical_ROIs.txt

# Local FreeSurfer directory
FREESURFER_HOME=/data/EDB/opt/freesurfer/7.1.1
#*********** END DEFINING ***************

source ${FREESURFER_HOME}/SetUpFreeSurfer.sh

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
   mkdir -p ${ATLAS_DIR}/source/
   cd       ${ATLAS_DIR}/source/
   
   # Hypothalamus
   # Neudorfer C, Germann J, Elias GJB, Gramer R, Boutet A, Lozano AM.
   # A high-resolution in vivo magnetic resonance imaging atlas of the
   # human hypothalamic region. Scientific Data. 2020;7(1):305.
   # https://dx.doi.org/10.1038/s41597-020-00644-6
   # This atlas has good overlap with MNI_ICBM152_2009b
   wget -c https://zenodo.org/record/3942115/files/MNI152b_atlas_labels_0.5mm.nii.gz
   wget -c https://zenodo.org/record/3942115/files/Volumes_names-labels.csv

   # AAN (Harvard Ascending Arousal Network Atlas 
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
   echo "Skipping downloads. Assumed all atlases are already in ${ATLAS_DIR}/source"
fi

# Process the AAN atlas?
if [[ ${DO_AAN} == "YES" ]] ; then
   echo "Working on the AAN atlas."
   
   # Unzip, delete unused files, gzip
   mkdir -p ${ATLAS_DIR}/atlases/AAN/isolated
   cd       ${ATLAS_DIR}/atlases/AAN
   unzip ${ATLAS_DIR}/source/AAN_MNI152_1mm_v1p0.zip 'AAN_*.nii' -d ${ATLAS_DIR}/atlases/AAN/
   rm -rf ${ATLAS_DIR}/atlases/AAN/__MACOSX
   gzip ${ATLAS_DIR}/atlases/AAN/AAN_*.nii
   
   # Rename files to more friendly names
   for oldname in AAN_*.nii.gz ; do
      roi=$(echo ${oldname}|awk -F_ '{print $2}')
      newname=AAN_${roi}.nii.gz
      mv ${ATLAS_DIR}/atlases/AAN/${oldname} ${ATLAS_DIR}/atlases/AAN/isolated/${newname}
   done
   
   ${FSLDIR}/bin/imglob ${ATLAS_DIR}/atlases/AAN/isolated >> ${SUBCORTICAL_LIST}

else
   echo "Skipping AAN atlas."
fi

# Process the Cerebellum atlas?
if [[ ${DO_CEREBELLUM} == "YES" ]] ; then
   echo "Working on the Cerebellum atlas."
   
   # Unzip, delete unused files, gzip
   mkdir -p ${ATLAS_DIR}/atlases/Cerebellum/isolated
   cd       ${ATLAS_DIR}/atlases/Cerebellum
   
   # Convert the XML file to a friendly CSV file
   echo "Parsing XML file"
   while read_dom ; do
      parse_dom
   done < ${ATLAS_DIR}/source/Cerebellum_MNIfnirt.xml > ${ATLAS_DIR}/atlases/Cerebellum/Cerebellum_labels.csv

   # Split the atlas into independent files, one per ROI
   nlines=$(cat ${ATLAS_DIR}/atlases/Cerebellum/Cerebellum_labels.csv|wc -l)
   for ((lnum=1;lnum<=${nlines};lnum++)) ; do
      roinum=$( head -n ${lnum} ${ATLAS_DIR}/atlases/Cerebellum/Cerebellum_labels.csv | tail -n 1 | awk -F, '{print $1}')
      roinum=$( echo "${roinum}+1" | bc -l)
      roiname=$(head -n ${lnum} ${ATLAS_DIR}/atlases/Cerebellum/Cerebellum_labels.csv | tail -n 1 | awk -F, '{print $2}')
      echo "Working on Cerebellum ${roiname} (ROI #${roinum})"
      ${FSLDIR}/bin/fslmaths ${ATLAS_DIR}/source/Cerebellum-MNIfnirt-maxprob-thr50-1mm \
                             -thr ${roinum} -uthr ${roinum} -bin \
                             ${ATLAS_DIR}/atlases/Cerebellum/isolated/Cerebellum_${roiname}
   done

   ${FSLDIR}/bin/imglob ${ATLAS_DIR}/atlases/Cerebellum/isolated >> ${SUBCORTICAL_LIST}
else
   echo "Skipping Cerebellum atlas."
fi

# For the Hypothalamus and for the subfield/subnuclei segmentation (in FS) we need
# to align the MNI_ICBM152b to FSL's MNI152 (they don't perfectly overlap).
if [[ ${DO_HYPOTHALAMUS} == "YES" ]] || [[ ${DO_SUBFS} == "YES" ]] ; then 
   cd ${ATLAS_DIR}/source
   
   # Unzip, gzip
   rm -rf ${ATLAS_DIR}/source/mni_icbm152_nlin_asym_09b
   unzip ${ATLAS_DIR}/source/mni_icbm152_nlin_asym_09b_nifti.zip '*.nii'
   gzip  ${ATLAS_DIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_*
   
   # Align to FSL's MNI, keep just the affine matrix. Remove non-brain tissue first.
   echo "Running BET and FLIRT."
   ${FSLDIR}/bin/bet \
                 ${ATLAS_DIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_hires \
                 ${ATLAS_DIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_hires_brain
   ${FSLDIR}/bin/flirt \
            -in   ${ATLAS_DIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_hires_brain \
            -ref  ${FSLDIR}/data/standard/MNI152_T1_1mm_brain \
            -dof 6 -interp spline \
            -omat ${ATLAS_DIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_fsl.mat
   ${FSLDIR}/bin/imrm ${ATLAS_DIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_hires_brain
fi

# Process the Hypothalamus atlas?
if [[ ${DO_HYPOTHALAMUS} == "YES" ]] ; then
   echo "Working on the Hypothalamus atlas."
   
   # Ensure we have a list of ROIs in this directory
   mkdir -p ${ATLAS_DIR}/atlases/Hypothalamus/isolated
   cp -p ${ATLAS_DIR}/source/Volumes_names-labels.csv ${ATLAS_DIR}/atlases/Hypothalamus
   dos2unix ${ATLAS_DIR}/atlases/Hypothalamus/Volumes_names-labels.csv
   echo "" >> ${ATLAS_DIR}/atlases/Hypothalamus/Volumes_names-labels.csv
   sed -i "s/R_/Right_/" ${ATLAS_DIR}/atlases/Hypothalamus/Volumes_names-labels.csv
   sed -i "s/L_/Left_/"  ${ATLAS_DIR}/atlases/Hypothalamus/Volumes_names-labels.csv

   # Align to FSL's MNI using the affine matrix produced earlier
   ${FSLDIR}/bin/flirt \
             -in   ${ATLAS_DIR}/source/MNI152b_atlas_labels_0.5mm \
             -ref  ${FSLDIR}/data/standard/MNI152_T1_1mm_brain \
             -init ${ATLAS_DIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_fsl.mat \
             -applyxfm -interp nearestneighbour \
             -out  ${ATLAS_DIR}/atlases/Hypothalamus/MNI152b_atlas_labels_1mm
   
   # Split the atlas into independent files, one per ROI
   nlines=$(cat ${ATLAS_DIR}/atlases/Hypothalamus/Volumes_names-labels.csv|wc -l)
   for ((lnum=2;lnum<=${nlines};lnum++)) ; do
      roinum=$( head -n ${lnum} ${ATLAS_DIR}/atlases/Hypothalamus/Volumes_names-labels.csv | tail -n 1 | awk -F, '{print $1}')
      roiname=$(head -n ${lnum} ${ATLAS_DIR}/atlases/Hypothalamus/Volumes_names-labels.csv | tail -n 1 | awk -F, '{print $4}')
      roiname=${roiname//[[:blank:]]/}
      roiname=${roiname/_/-}
      echo "Working on Hypothalamus ${roiname} (ROI #${roinum})"
      ${FSLDIR}/bin/fslmaths ${ATLAS_DIR}/atlases/Hypothalamus/MNI152b_atlas_labels_1mm \
                             -thr ${roinum} -uthr ${roinum} -bin \
                             ${ATLAS_DIR}/atlases/Hypothalamus/isolated/Hypothalamus_${roiname}
   done

   ${FSLDIR}/bin/imglob ${ATLAS_DIR}/atlases/Hypothalamus/isolated >> ${SUBCORTICAL_LIST}

else
   echo "Skipping Hypothalamus atlas."
fi

# Process the FreeSurfer subfield/subnuclei segmentations?
if [[ ${DO_SUBFS} == "YES" ]] ; then
   echo "Working on the FreeSurfer subfield/subnuclei segmentation."
   
   # Ensure we have a whole-head version of the MNI_ICBM152b in FSL's MNI.
   # For this we can use the affine matrix we produced earlier.
   mkdir -p ${ATLAS_DIR}/atlases/FreeSurfer/isolated
   ${FSLDIR}/bin/flirt \
          -in   ${ATLAS_DIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_hires \
          	-ref  ${FSLDIR}/data/standard/MNI152_T1_1mm \
          -init ${ATLAS_DIR}/source/mni_icbm152_nlin_asym_09b/mni_icbm152_t1_tal_nlin_asym_09b_fsl.mat \
          -applyxfm -interp spline \
          -out  ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl

   # Run FreeSurfer!
   if [[ ! -f ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.mgz ]] ; then
      ${FREESURFER_HOME}/bin/recon-all -s  mni_icbm152b_fsl \
                                       -i  ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl.nii.gz \
                                       -sd ${ATLAS_DIR}/atlases/FreeSurfer -all

      # Run the subfield/subnuclei segmentation for hippocampus, amygdala, and thalamus
      ${FREESURFER_HOME}/bin/segmentHA_T1.sh mni_icbm152b_fsl ${ATLAS_DIR}/atlases/FreeSurfer
      ${FREESURFER_HOME}/bin/segmentThalamicNuclei.sh mni_icbm152b_fsl ${ATLAS_DIR}/atlases/FreeSurfer
   else
      echo "FreeSurfer run already found. Skipping."
   fi
   
   # Convert the relevant outputs from MGZ to NIFTI
   ${FREESURFER_HOME}/bin/mri_convert \
                     ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/aseg.mgz \
                     ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/aseg.nii.gz
   ${FREESURFER_HOME}/bin/mri_convert \
                     ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.mgz \
                     ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.nii.gz
   ${FREESURFER_HOME}/bin/mri_convert \
                     ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/lh.hippoAmygLabels-T1.v21.FSvoxelSpace.mgz \
                     ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/lh.hippoAmygLabels-T1.v21.FSvoxelSpace.nii.gz
   ${FREESURFER_HOME}/bin/mri_convert \
                     ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/rh.hippoAmygLabels-T1.v21.FSvoxelSpace.mgz \
                     ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/rh.hippoAmygLabels-T1.v21.FSvoxelSpace.nii.gz
   ${FREESURFER_HOME}/bin/mri_convert \
                     ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/orig.mgz \
                     ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/orig.nii.gz

   # Register the conformed orig to the original (input) space, keep the affine matrix
   ${FSLDIR}/bin/flirt \
          -in   ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/orig \
          -ref  ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -dof 6 -interp spline \
          -omat ${ATLAS_DIR}/atlases/FreeSurfer/conformed_to_original.mat
   
   # Apply the transformation to the subfields/subnuclei, with nearest neighbor interpolation
   ${FSLDIR}/bin/flirt \
          -in   ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/aseg \
          -ref  ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -init ${ATLAS_DIR}/atlases/FreeSurfer/conformed_to_original.mat \
          -applyxfm -interp nearestneighbour \
          -out  ${ATLAS_DIR}/atlases/FreeSurfer/aseg.MNISpace
   ${FSLDIR}/bin/flirt \
          -in   ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/ThalamicNuclei.v12.T1.FSvoxelSpace \
          -ref  ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -init ${ATLAS_DIR}/atlases/FreeSurfer/conformed_to_original.mat \
          -applyxfm -interp nearestneighbour \
          -out  ${ATLAS_DIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace
   for h in lh rh ; do
      ${FSLDIR}/bin/flirt \
          -in   ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152b_fsl/mri/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace \
          -ref  ${ATLAS_DIR}/atlases/FreeSurfer/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -init ${ATLAS_DIR}/atlases/FreeSurfer/conformed_to_original.mat \
          -applyxfm -interp nearestneighbour \
          -out  ${ATLAS_DIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace
   done
   
   # Generate text files with the list of labels, get the label names from the
   # FreeSurferColorLUT.txt, and split into separate regions.
   
   # First for the subcortical segmentations from aseg
   ${FSLDIR}/bin/fsl2ascii \
          ${ATLAS_DIR}/atlases/FreeSurfer/aseg.MNISpace.nii.gz \
          ${ATLAS_DIR}/atlases/FreeSurfer/aseg.MNISpace.txt
   cat ${ATLAS_DIR}/atlases/FreeSurfer/aseg.MNISpace.txt00000 |\
          sed -z 's/\n//g'|sed 's/\ /\n/g'|sort|uniq > \
          ${ATLAS_DIR}/atlases/FreeSurfer/aseg.labels.txt
   for lab in $(cat ${ATLAS_DIR}/atlases/FreeSurfer/aseg.labels.txt) ; do
      if [[ ${lab} -gt 0 ]] ; then
         roinum=${lab}
         roiname=$(awk -v "lab=${lab}" '$1 == lab {print $2}' ${FREESURFER_HOME}/FreeSurferColorLUT.txt|sed 's/_/-/g')
         echo "Working on subcortical segmentations/aseg ${roiname} (ROI #${roinum})"
         ${FSLDIR}/bin/fslmaths ${ATLAS_DIR}/atlases/FreeSurfer/aseg.MNISpace \
                             -thr ${roinum} -uthr ${roinum} -bin \
                             ${ATLAS_DIR}/atlases/FreeSurfer/isolated/aseg_${roiname}
      fi
   done
   
   # Then for the Thalamus
   ${FSLDIR}/bin/fsl2ascii \
          ${ATLAS_DIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace.nii.gz \
          ${ATLAS_DIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace.txt
   cat ${ATLAS_DIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace.txt00000 |\
          sed -z 's/\n//g'|sed 's/\ /\n/g'|sort|uniq > \
          ${ATLAS_DIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.labels.txt
   for lab in $(cat ${ATLAS_DIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.labels.txt) ; do
      if [[ ${lab} -gt 0 ]] ; then
         roinum=${lab}
         roiname=$(awk -v "lab=${lab}" '$1 == lab {print $2}' ${FREESURFER_HOME}/FreeSurferColorLUT.txt|sed 's/_/-/g')
         echo "Working on Thalamus ${roiname} (ROI #${roinum})"
         ${FSLDIR}/bin/fslmaths ${ATLAS_DIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace \
                             -thr ${roinum} -uthr ${roinum} -bin \
                             ${ATLAS_DIR}/atlases/FreeSurfer/isolated/Thalamus_${roiname}
      fi
   done
   rm  ${ATLAS_DIR}/atlases/FreeSurfer/ThalamicNuclei.v12.T1.MNISpace.txt00000

   # Then for the Amygdala and Hippocampus
   for h in lh rh ; do
      hemi=Left
      if [[ ${h} == "rh" ]]; then hemi=Right; fi

      ${FSLDIR}/bin/fsl2ascii \
          ${ATLAS_DIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace \
          ${ATLAS_DIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace.txt
      cat ${ATLAS_DIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace.txt00000 |\
          sed -z 's/\n//g'|sed 's/\ /\n/g'|sort|uniq > \
          ${ATLAS_DIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.labels.txt
      for lab in $(cat ${ATLAS_DIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.labels.txt) ; do
         if [[ ${lab} -gt 7000 ]] ; then
            struc=Amygdala
         else
            struc=Hippocampus
         fi
         if [[ ${lab} -gt 0 ]] ; then
            roinum=${lab}
            roiname=$(awk -v "lab=${lab}" '$1 == lab {print $2}' ${FREESURFER_HOME}/FreeSurferColorLUT.txt|sed 's/_/-/g')
            echo "Working on ${struc} ${h}-${roiname} (ROI #${roinum})"
            ${FSLDIR}/bin/fslmaths ${ATLAS_DIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace \
                                -thr ${roinum} -uthr ${roinum} -bin \
                                ${ATLAS_DIR}/atlases/FreeSurfer/isolated/${struc}_${hemi}-${roiname}
         fi
      done
      rm  ${ATLAS_DIR}/atlases/FreeSurfer/${h}.hippoAmygLabels-T1.v21.FSvoxelSpace.txt00000
   done

   str_dir=${ATLAS_DIR}/atlases/FreeSurfer/isolated
   for h in Left Right ; do
   	mv ${str_dir}/aseg_${h}-Accumbens-area.nii.gz ${str_dir}/Striatum_${h}-Accumbens-area.nii.gz
	mv ${str_dir}/aseg_${h}-Caudate.nii.gz ${str_dir}/Striatum_${h}-Caudate.nii.gz
	mv ${str_dir}/aseg_${h}-Pallidum.nii.gz ${str_dir}/Striatum_${h}-Pallidum.nii.gz
	mv ${str_dir}/aseg_${h}-Putamen.nii.gz ${str_dir}/Striatum_${h}-Putamen.nii.gz
   done

   for set in Amygdala Hippocampus Thalamus Striatum ; do
   	mkdir -p ${ATLAS_DIR}/atlases/${set}/isolated
   	mv ${ATLAS_DIR}/atlases/FreeSurfer/isolated/${set}* ${ATLAS_DIR}/atlases/${set}/isolated
   	${FSLDIR}/bin/imglob ${ATLAS_DIR}/atlases/${set}/isolated/ >> ${SUBCORTICAL_LIST}
   done

   mv ${ATLAS_DIR}/atlases/FreeSurfer ${ATLAS_DIR}/source/
   sed -i "s/.nii.gz//" ${SUBCORTICAL_LIST}
 
else
   echo "Skipping FreeSurfer subfield/subnuclei segmentation."
fi

echo "Finished isolating subcortical ROIs; listed in ${SUBCORTICAL_LIST}."

# Process the Schaefer cortical parcellation?
if [[ ${DO_SCHAEFER} == "YES" ]] ; then
   echo "Working on the Schaefer parcellation."
   
   # Unzip, delete unused files, gzip
   mkdir -p ${ATLAS_DIR}/atlases/Schaefer/isolated
   cd       ${ATLAS_DIR}/atlases/Schaefer
   
   # Convert the XML file to a friendly CSV file
   echo "Parsing list of parcellation labels."
   awk 'BEGIN {OFS=","} {print NR, $2}' ${ATLAS_DIR}/source/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order.txt | \
      sed 's/_/-/g'| sed "s/${SCHAEFER_NUMNETS}Networks-/Schaefer_/g" | \
      sed 's/Schaefer_LH-/Schaefer_Left-/g' | \
      sed 's/Schaefer_RH-/Schaefer_Right-/g' > ${ATLAS_DIR}/atlases/Schaefer/Schaefer_labels.csv

   # Split the parcellation into independent files, one per ROI
   nlines=$(cat ${ATLAS_DIR}/atlases/Schaefer/Schaefer_labels.csv|wc -l)
   for ((lnum=1;lnum<=${nlines};lnum++)) ; do
      roinum=$( head -n ${lnum} ${ATLAS_DIR}/atlases/Schaefer/Schaefer_labels.csv | tail -n 1 | awk -F, '{print $1}')
      roiname=$(head -n ${lnum} ${ATLAS_DIR}/atlases/Schaefer/Schaefer_labels.csv | tail -n 1 | awk -F, '{print $2}')
      echo "Working on Schaefer ${roiname#Schaefer_} (ROI #${roinum})"
      ${FSLDIR}/bin/fslmaths ${ATLAS_DIR}/source/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order_FSLMNI152_1mm \
                             -thr ${roinum} -uthr ${roinum} -bin \
                             ${ATLAS_DIR}/atlases/Schaefer/isolated/${roiname}
   done
   
   # Make a list in the same format as the list for subcortical, so that overlaps
   # can be tested and then ROIs can be merged. List includes number labels.
   lab=1001
   for roiname in $(awk -F, '{print $2}' ${ATLAS_DIR}/atlases/Schaefer/Schaefer_labels.csv|grep "Schaefer_Left-") ; do
      echo "${lab}:${roiname}:${roiname}" >> ${CORTICAL_LIST}
      ((lab++))
   done
   lab=2001
   for roiname in $(awk -F, '{print $2}' ${ATLAS_DIR}/atlases/Schaefer/Schaefer_labels.csv|grep "Schaefer_Right-") ; do
      echo "${lab}:${roiname}:${roiname}" >> ${CORTICAL_LIST}
      ((lab++))
   done

   echo "Finished isolating cortical parcels; listed in ${CORTICAL_LIST}."

else
   echo "Skipping cortical parcellation."
fi

echo "Done!"
