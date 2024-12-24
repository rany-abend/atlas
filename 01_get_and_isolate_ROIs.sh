#!/bin/bash

# This script downloads (if chose to) source atlases from their original online locations.
# It then processes them (if chose to): it registers them all to a common MNI152 space, and
# then isolates all ROIs in all atlases into individual nii.gz files.

# Before running this script: 
# 1. Define all constants in the accompanying source_this.sh file;
# 2. Run command: source source_this.sh.


rm -f ${SUBCORTICAL_LIST}
rm -f ${CORTICAL_LIST}

> ${SUBCORTICAL_LIST}
> ${CORTICAL_LIST}



#======================================================================
# Some functions to parse XML files (e.g., for FSL atlases).
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
      echo "${index},Cerebellum_${CONTENT//[[:blank:]]/}"
   fi
   }
#======================================================================





###~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ###
###~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ Get the source atlases ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~###
###~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ###

src_mni=${ROOTDIR}/source/mni_icbm152_nlin_asym_09b

if [[ ${DOWNLOAD} == "YES" ]] ; then
   echo "Downloading source atlases."
   mkdir -p ${ROOTDIR}/source/
   cd ${ROOTDIR}/source/
   
   if [[ ${DO_HYPOTHALAMUS} == "YES" ]] ; then
      # Hypothalamus
      # Neudorfer C, Germann J, Elias GJB, Gramer R, Boutet A, Lozano AM.
      # A high-resolution in vivo magnetic resonance imaging atlas of the
      # human hypothalamic region. Scientific Data. 2020;7(1):305.
      # https://dx.doi.org/10.1038/s41597-020-00644-6
      wget -c https://zenodo.org/record/3942115/files/MNI152b_atlas_labels_0.5mm.nii.gz
      wget -c https://zenodo.org/record/3942115/files/Volumes_names-labels.csv
   fi

   if [[ ${DO_AAN} == "YES" ]] ; then
      # AAN (Harvard Ascending Arousal Network Atlas) 
      # Edlow BL, Takahashi E, Wu O, et al. Neuroanatomic connectivity
      # of the human ascending arousal system critical to consciousness
      # and its disorders. J Neuropathol Exp Neurol. 2012;71(6):531-546.
      # https://dx.doi.org/10.1097/NEN.0b013e3182588293
      # This atlas has good overlap with FSL's MNI162_1mm.
      wget -c http://nmr.mgh.harvard.edu/martinos/resources/aan-atlas/AAN_MNI152_1mm_v1p0.zip
   fi
   
   if [[ ${DO_CEREBELLUM} == "YES" ]] ; then
      # Cerebellum, from FSL atlases directory
      # Diedrichsen J, Balsters JH, Flavell J, Cussans E, Ramnani N.
      # A probabilistic MR atlas of the human cerebellum.
      # Neuroimage. 2009;46(1):39-46.
      # https://dx.doi.org/10.1016/j.neuroimage.2009.01.045
      # This atlas has good overlap with FSL's MNI152_1mm.
      cp -pv ${FSLDIR}/data/atlases/Cerebellum/Cerebellum-MNIfnirt-maxprob-thr50-1mm.nii.gz .
      cp -pv ${FSLDIR}/data/atlases/Cerebellum_MNIfnirt.xml .
   fi
   
   if [[ ${DO_HYPOTHALAMUS} == "YES" ]] || [[ ${DO_SUBFS} == "YES" ]] ; then
      # ICBM 152 Nonlinear atlases version 2009 (to drive registration)
      # Fonov V, Evans AC, Botteron K, et al. Unbiased average age-appropriate
      # atlases for pediatric studies. Neuroimage. 2011;54(1):313-327.
      # https://dx.doi.org/10.1016/j.neuroimage.2010.07.033
      wget -c http://www.bic.mni.mcgill.ca/~vfonov/icbm/2009/mni_icbm152_nlin_asym_09b_nifti.zip
   fi

   if [[ ${DO_SCHAEFER} == "YES" ]] ; then
      # Schaefer et al cortical parcellation.
      # Schaefer A, Kong R, Gordon EM, et al. Local-Global Parcellation of the 
      # Human Cerebral Cortex from Intrinsic Functional Connectivity MRI.
      # Cereb Cortex. 2018;28(9):3095-3114.
      # https://dx.doi.org/10.1093/cercor/bhx179
      wget -c https://raw.githubusercontent.com/ThomasYeoLab/CBIG/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI/fsleyes_lut/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order.lut
      wget -c https://raw.githubusercontent.com/ThomasYeoLab/CBIG/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI/freeview_lut/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order.txt
      wget -c https://raw.githubusercontent.com/ThomasYeoLab/CBIG/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order_FSLMNI152_1mm.nii.gz
   fi
   cd

else
   echo "Skipping downloads. Assumed all atlases are already in ${ROOTDIR}/source"

fi






###~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ###
###~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ FreeSurfer preparation for subcortical regions ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~###
###~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ###

rm -f ${SUBCORTICAL_LIST}

# For the Hypothalamus and for the subfield/subnuclei segmentation (in FreeSurfer), we need
# to align the MNI_ICBM152b to FSL's MNI152 (they don't perfectly overlap).


if [[ ${DO_HYPOTHALAMUS} == "YES" ]] || [[ ${DO_SUBFS} == "YES" ]] ; then 
   
   cd ${ROOTDIR}/source
   # Unzip, gzip
   rm -rf ${src_mni}
   unzip ${src_mni}_nifti.zip '*.nii'
   gzip  ${src_mni}/mni_icbm152_*
   
   # Align to FSL's MNI, keep just the affine matrix. Remove non-brain tissue first.
   echo "Running BET and FLIRT."
   ${FSLDIR}/bin/bet \
                 ${src_mni}/mni_icbm152_t1_tal_nlin_asym_09b_hires \
                 ${src_mni}/mni_icbm152_t1_tal_nlin_asym_09b_hires_brain
   ${FSLDIR}/bin/flirt \
            -in   ${src_mni}/mni_icbm152_t1_tal_nlin_asym_09b_hires_brain \
            -ref  ${TEMPLATE_T1} \
            -dof 6 -interp spline \
            -omat ${src_mni}/mni_icbm152_t1_tal_nlin_asym_09b_fsl.mat
   ${FSLDIR}/bin/imrm ${src_mni}/mni_icbm152_t1_tal_nlin_asym_09b_hires_brain
fi




###~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ###
###~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ Processing specified atlases ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~###
###~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ###






###------------------------------------------------AAN----------------------------------------------------###


if [[ ${DO_AAN} == "YES" ]] ; then
   echo "Working on the AAN atlas."
   
   mkdir -p ${ROOTDIR}/atlases/AAN/isolated
   cd       ${ROOTDIR}/atlases/AAN
   # Unzip, delete unused files, gzip
   unzip    ${ROOTDIR}/source/AAN_MNI152_1mm_v1p0.zip 'AAN_*.nii' -d ${ROOTDIR}/atlases/AAN/
   rm -rf ${ROOTDIR}/atlases/AAN/__MACOSX
   gzip   ${ROOTDIR}/atlases/AAN/AAN_*.nii
   
   # Rename files to more friendly names
   lab=1
   for oldname in AAN_*.nii.gz ; do
      roi=$(echo ${oldname} | awk -F_ '{print $2}')
      newname=AAN_${roi}.nii.gz
      mv ${ROOTDIR}/atlases/AAN/${oldname} ${ROOTDIR}/atlases/AAN/isolated/${newname}
      # Add individual ROI to list
      echo "${lab}:${newname}:${newname}" >> ${SUBCORTICAL_LIST}
      ((lab++))
   done
   cd

   
else
   echo "Skipping AAN atlas."
fi






###-------------------------------------------Cerebellum---------------------------------------------###


if [[ ${DO_CEREBELLUM} == "YES" ]] ; then
   echo "Working on the Cerebellum atlas."
   
   # Unzip, delete unused files, gzip
   cbm_dir=${ROOTDIR}/atlases/Cerebellum
   mkdir -p ${cbm_dir}/isolated
   cd ${cbm_dir}

   # Convert the XML file to a friendly CSV file
   while read_dom ; do
      parse_dom
   done < ${ROOTDIR}/source/Cerebellum_MNIfnirt.xml > ${cbm_dir}/Cerebellum_labels.csv

   # Split the atlas into independent files, one per ROI
   nlines=$(cat ${cbm_dir}/Cerebellum_labels.csv | wc -l)
   lab=101
   for (( lnum=1; lnum<=${nlines}; lnum++ )) ; do
      roinum=$(head -n ${lnum} ${cbm_dir}/Cerebellum_labels.csv | tail -n 1 | awk -F, '{print $1}')
      roinum=$(echo "${roinum}+1" | bc -l)
      roiname=$(head -n ${lnum} ${cbm_dir}/Cerebellum_labels.csv | tail -n 1 | awk -F, '{print $2}')
      echo "Working on Cerebellum ${roiname} (ROI #${roinum})"
      ${FSLDIR}/bin/fslmaths ${ROOTDIR}/source/Cerebellum-MNIfnirt-maxprob-thr50-1mm \
                             -thr ${roinum} -uthr ${roinum} -bin ${cbm_dir}/isolated/${roiname}
      # Add individual ROI to list
      echo "${lab}:${roiname}:${roiname}" >> ${SUBCORTICAL_LIST}
      ((lab++))
   done
   cd


else
   echo "Skipping Cerebellum atlas."
fi






###-------------------------------------------Hypothalamus---------------------------------------------------###


if [[ ${DO_HYPOTHALAMUS} == "YES" ]] ; then
   echo "Working on the Hypothalamus atlas."
   
   # Ensure we have a list of ROIs in this directory
   hyp_dir=${ROOTDIR}/atlases/Hypothalamus
   mkdir -p ${hyp_dir}/isolated

   cp -p ${ROOTDIR}/source/Volumes_names-labels.csv ${hyp_dir}
   dos2unix ${hyp_dir}/Volumes_names-labels.csv
   echo "" >> ${hyp_dir}/Volumes_names-labels.csv
   sed -i "s/R_/Right_/" ${hyp_dir}/Volumes_names-labels.csv
   sed -i "s/L_/Left_/"  ${hyp_dir}/Volumes_names-labels.csv

   # Align to FSL's MNI standard using the affine matrix produced earlier
   ${FSLDIR}/bin/flirt \
             -in   ${ROOTDIR}/source/MNI152b_atlas_labels_0.5mm \
             -ref  ${TEMPLATE_T1} \
             -init ${src_mni}/mni_icbm152_t1_tal_nlin_asym_09b_fsl.mat \
             -applyxfm -interp nearestneighbour \
             -out  ${hyp_dir}/MNI152b_atlas_labels_1mm
   
   # Split the atlas into independent files, one per ROI
   nlines=$(cat ${hyp_dir}/Volumes_names-labels.csv | wc -l)
   lab=201
   for (( lnum=2; lnum<=${nlines}; lnum++ )) ; do
      roinum=$(head -n ${lnum} ${hyp_dir}/Volumes_names-labels.csv | tail -n 1 | awk -F, '{print $1}')
      roiname=$(head -n ${lnum} ${hyp_dir}/Volumes_names-labels.csv | tail -n 1 | awk -F, '{print $4}')
      #roiname=${roiname//[[:blank:]]/}
      roiname=${roiname/_/-}
      echo "Working on Hypothalamus ${roiname} (ROI #${roinum})"
      ${FSLDIR}/bin/fslmaths ${hyp_dir}/MNI152b_atlas_labels_1mm \
                             -thr ${roinum} -uthr ${roinum} -bin ${hyp_dir}/isolated/Hypothalamus_${roiname}
      # Add individual ROI to list
      echo "${lab}:Hypothalamus_${roiname}:Hypothalamus_${roiname}" >> ${SUBCORTICAL_LIST}
      ((lab++))
   done


else
   echo "Skipping Hypothalamus atlas."
fi





###----------------------------------Amygdala, Hippocampus & Thalamus-------------------------------------------###


if [[ ${DO_SUBFS} == "YES" ]] ; then
   echo "Working on amygdala, hippocampus, and thalamus subfield/subnuclei segmentation."
   
   # Ensure we have a whole-head version of the MNI_ICBM152b in FSL's MNI.
   # For this we can use the affine matrix we produced earlier.

   fs_dir=${ROOTDIR}/atlases/FreeSurfer
   mkdir -p ${fs_dir}/isolated

   ${FSLDIR}/bin/flirt \
          -in   ${src_mni}/mni_icbm152_t1_tal_nlin_asym_09b_hires \
          -ref  ${TEMPLATE_T1} \
          -init ${src_mni}/mni_icbm152_t1_tal_nlin_asym_09b_fsl.mat \
          -applyxfm -interp spline \
          -out  ${fs_dir}/mni_icbm152_t1_tal_nlin_asym_09b_fsl

   # Run FreeSurfer!
   TH=ThalamicNuclei.v13.T1
   HiAmy=hippoAmygLabels-T1.v22

   if [[ ! -f ${fs_dir}/mni_icbm152b_fsl/mri/${TH}.FSvoxelSpace.mgz ]] ; then
      ${FREESURFER_HOME}/bin/recon-all -s  mni_icbm152b_fsl \
                                       -i  ${fs_dir}/mni_icbm152_t1_tal_nlin_asym_09b_fsl.nii.gz \
                                       -sd ${fs_dir} -all

      # Run the subfield/subnuclei segmentation for hippocampus, amygdala, and thalamus
      ${FREESURFER_HOME}/bin/segmentHA_T1.sh mni_icbm152b_fsl ${fs_dir}
      ${FREESURFER_HOME}/bin/segmentThalamicNuclei.sh mni_icbm152b_fsl ${fs_dir}
   else
      echo "FreeSurfer run already found. Skipping."
   fi

   
   # Convert the relevant outputs from MGZ to NIFTI
   for a in aseg ${TH}.FSvoxelSpace lh.${HiAmy}.FSvoxelSpace rh.${HiAmy}.FSvoxelSpace orig ; do
      ${FREESURFER_HOME}/bin/mri_convert \
                     ${fs_dir}/mni_icbm152b_fsl/mri/${a}.mgz \
                     ${fs_dir}/mni_icbm152b_fsl/mri/${a}.nii.gz
   done


   # Register the conformed orig to the original (input) space, keep the affine matrix
   ${FSLDIR}/bin/flirt \
          -in   ${fs_dir}/mni_icbm152b_fsl/mri/orig \
          -ref  ${fs_dir}/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -dof 6 -interp spline \
          -omat ${fs_dir}/conformed_to_original.mat
   
   # Apply the transformation to the subfields/subnuclei, with nearest neighbor interpolation
   ${FSLDIR}/bin/flirt \
          -in   ${fs_dir}/mni_icbm152b_fsl/mri/aseg \
          -ref  ${fs_dir}/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -init ${fs_dir}/conformed_to_original.mat \
          -applyxfm -interp nearestneighbour \
          -out  ${fs_dir}/aseg.MNISpace
   ${FSLDIR}/bin/flirt \
          -in   ${fs_dir}/mni_icbm152b_fsl/mri/${TH}.FSvoxelSpace \
          -ref  ${fs_dir}/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -init ${fs_dir}/conformed_to_original.mat \
          -applyxfm -interp nearestneighbour \
          -out  ${fs_dir}/${TH}.MNISpace
   for h in lh rh ; do
      ${FSLDIR}/bin/flirt \
          -in   ${fs_dir}/mni_icbm152b_fsl/mri/${h}.${HiAmy}.FSvoxelSpace \
          -ref  ${fs_dir}/mni_icbm152_t1_tal_nlin_asym_09b_fsl \
          -init ${fs_dir}/conformed_to_original.mat \
          -applyxfm -interp nearestneighbour \
          -out  ${fs_dir}/${h}.${HiAmy}.FSvoxelSpace
   done


   # Generate text files with list of labels, get label names from FreeSurferColorLUT.txt, 
   # and split into separate regions.
   
   ##  1. For the subcortical segmentations (from aseg):
   ${FSLDIR}/bin/fsl2ascii \
          ${fs_dir}/aseg.MNISpace.nii.gz \
          ${fs_dir}/aseg.MNISpace.txt

   cat ${fs_dir}/aseg.MNISpace.txt00000 | \
          sed -z 's/\n//g' | sed 's/\ /\n/g' | sort | uniq > ${fs_dir}/aseg.labels.txt
   lbl=301
   for lab in $(cat ${fs_dir}/aseg.labels.txt) ; do
      if [[ ${lab} -gt 0 ]] ; then
         roinum=${lab}
         roiname=$(awk -v "lab=${lab}" '$1 == lab {print $2}' ${FREESURFER_HOME}/FreeSurferColorLUT.txt | sed 's/_/-/g')
         
         echo "Working on subcortical segmentations/aseg ${roiname} (ROI #${roinum})"
         roinum=$(echo "${roinum}+1" | bc -l)
         ${FSLDIR}/bin/fslmaths ${fs_dir}/aseg.MNISpace \
                             -thr ${roinum} -uthr ${roinum} -bin ${fs_dir}/isolated/aseg_${roiname}
         # Add individual ROI to list
         echo "${lbl}:${roiname}:${roiname}" >> ${SUBCORTICAL_LIST}
         ((lbl++))
      fi
   done

   ##  2. Then for the Thalamus:
   ${FSLDIR}/bin/fsl2ascii \
          ${fs_dir}/${TH}.MNISpace.nii.gz \
          ${fs_dir}/${TH}.MNISpace.txt

   cat ${fs_dir}/${TH}.MNISpace.txt00000 | \
          sed -z 's/\n//g' | sed 's/\ /\n/g' | sort | uniq > ${fs_dir}/${TH}.labels.txt
   lbl=401
   for lab in $(cat ${fs_dir}/${TH}.labels.txt) ; do
      if [[ ${lab} -gt 0 ]] ; then
         roinum=${lab}
         roiname=$(awk -v "lab=${lab}" '$1 == lab {print $2}' ${FREESURFER_HOME}/FreeSurferColorLUT.txt | sed 's/_/-/g')
         
         echo "Working on Thalamus ${roiname} (ROI #${roinum})"
         ${FSLDIR}/bin/fslmaths ${fs_dir}/${TH}.MNISpace \
                             -thr ${roinum} -uthr ${roinum} -bin ${fs_dir}/isolated/Thalamus_${roiname}
         # Add individual ROI to list
         echo "${lbl}:Thalamus_${roiname}:Thalamus_${roiname}" >> ${SUBCORTICAL_LIST}
         ((lbl++))
      fi
   done
   rm ${fs_dir}/${TH}.MNISpace.txt00000

   ##  3. Then for the Amygdala and Hippocampus:
   for h in lh rh ; do
      if [[ ${h} == "lh" ]]; then 
         hemi=Left
         lbl=501
      else
         hemi=Right
         lbl=551
      fi

      ${FSLDIR}/bin/fsl2ascii \
          ${fs_dir}/${h}.${HiAmy}.FSvoxelSpace \
          ${fs_dir}/${h}.${HiAmy}.FSvoxelSpace.txt

      cat ${fs_dir}/${h}.${HiAmy}.FSvoxelSpace.txt00000 | \
          sed -z 's/\n//g' | sed 's/\ /\n/g' | sort | uniq > ${fs_dir}/${h}.${HiAmy}.labels.txt
      
      for lab in $(cat ${fs_dir}/${h}.${HiAmy}.labels.txt) ; do
         if [[ ${lab} -gt 7000 ]] ; then struc=Amygdala ; else struc=Hippocampus ; fi
         if [[ ${lab} -gt 0 ]] ; then
            roinum=${lab}
            roiname=$(awk -v "lab=${lab}" '$1 == lab {print $2}' ${FREESURFER_HOME}/FreeSurferColorLUT.txt | sed 's/_/-/g')
            echo "Working on ${struc} ${h}-${roiname} (ROI #${roinum})"
            ${FSLDIR}/bin/fslmaths ${fs_dir}/${h}.${HiAmy}.FSvoxelSpace \
                                -thr ${roinum} -uthr ${roinum} -bin ${fs_dir}/isolated/${struc}_${hemi}-${roiname}
            # Add individual ROI to list
            echo "${lbl}:${struc}_${hemi}-${roiname}:${struc}_${hemi}-${roiname}" >> ${SUBCORTICAL_LIST}
            ((lbl++))
         fi
      done
      rm  ${fs_dir}/${h}.${HiAmy}.FSvoxelSpace.txt00000
   done

   ## 4. Then the Striatum
   str_dir=${ROOTDIR}/atlases/FreeSurfer/isolated
   # Rename 4 striatum nuclei
   for h in Left Right ; do
   	mv ${str_dir}/aseg_${h}-Accumbens-area.nii.gz ${str_dir}/Striatum_${h}-Accumbens-area.nii.gz
	   mv ${str_dir}/aseg_${h}-Caudate.nii.gz ${str_dir}/Striatum_${h}-Caudate.nii.gz
	   mv ${str_dir}/aseg_${h}-Pallidum.nii.gz ${str_dir}/Striatum_${h}-Pallidum.nii.gz
	   mv ${str_dir}/aseg_${h}-Putamen.nii.gz ${str_dir}/Striatum_${h}-Putamen.nii.gz
   done

## ----------------

   # Move isolated files into dedicated directories
   for set in Amygdala Hippocampus Thalamus Striatum ; do
   	mkdir -p ${ROOTDIR}/atlases/${set}/isolated
   	mv ${fs_dir}/isolated/${set}* ${ROOTDIR}/atlases/${set}/isolated
   done

   # Move remaining files (unused) to 'source' directory so they will not be included in atlas
   mv ${fs_dir} ${ROOTDIR}/source/processed_unused

 
else
   echo "Skipping FreeSurfer subfield/subnuclei segmentation."
fi

# Format ROI names
sed -i "s/.nii.gz//g" ${SUBCORTICAL_LIST}

echo "Finished isolating subcortical ROIs; listed in ${SUBCORTICAL_LIST}."







###----------------------------------Schaefer cortical parcellation------------------------------------------###

#rm -f ${CORTICAL_LIST}

if [[ ${DO_SCHAEFER} == "YES" ]] ; then
   echo "Working on the Schaefer parcellation."
   
   # Unzip, delete unused files, gzip
   sch_dir=${ROOTDIR}/atlases/Schaefer
   mkdir -p ${sch_dir}/isolated
   cd ${sch_dir}
   
   # Convert the XML file to a friendly CSV file of parcellation labels
   if [[ ${SCHAEFER_NUMNETS} == "Kong2022_17" ]] ; then
      substr=17networks-/Schaefer
   else
      substr=${SCHAEFER_NUMNETS}Networks-/Schaefer
   fi
   awk 'BEGIN {OFS=","} {print NR, $2}' ${ROOTDIR}/source/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order.txt | \
      sed 's/_/-/g' | sed "s/${substr}_/g" | \
      sed 's/Schaefer_LH-/Schaefer_Left-/g' | \
      sed 's/Schaefer_RH-/Schaefer_Right-/g' > ${sch_dir}/Schaefer_labels.csv


   # Split the parcellation into independent files, one per ROI
   nlines=$(cat ${sch_dir}/Schaefer_labels.csv | wc -l)
   for (( lnum=1; lnum<=${nlines}; lnum++ )) ; do
      roinum=$(head -n ${lnum} ${sch_dir}/Schaefer_labels.csv | tail -n 1 | awk -F, '{print $1}')
      roiname=$(head -n ${lnum} ${sch_dir}/Schaefer_labels.csv | tail -n 1 | awk -F, '{print $2}')
      
      echo "Working on Schaefer ${roiname#Schaefer_} (ROI #${roinum})"
      ${FSLDIR}/bin/fslmaths ${ROOTDIR}/source/Schaefer2018_${SCHAEFER_NUMPARC}Parcels_${SCHAEFER_NUMNETS}Networks_order_FSLMNI152_1mm \
                           -thr ${roinum} -uthr ${roinum} -bin ${sch_dir}/isolated/${roiname}  
   done
   
   # Make a list in the same format as the list for subcortical, with new label numbers.
   lab=1001
   for roiname in $(awk -F, '{print $2}' ${sch_dir}/Schaefer_labels.csv | grep "Schaefer_Left-") ; do
      echo "${lab}:${roiname}:${roiname}" >> ${CORTICAL_LIST}
      ((lab++))
   done
   lab=2001
   for roiname in $(awk -F, '{print $2}' ${sch_dir}/Schaefer_labels.csv | grep "Schaefer_Right-") ; do
      echo "${lab}:${roiname}:${roiname}" >> ${CORTICAL_LIST}
      ((lab++))
   done
   echo "Finished isolating cortical ROIs; listed in ${CORTICAL_LIST}."
   cd
   
else
   echo "Skipping cortical parcellation."
fi





###-------------------------------------------------------------------------------------------------------###

rm -f ${ROI_FILE}
cat ${SUBCORTICAL_LIST} >> ${ROI_FILE}
cat ${CORTICAL_LIST} >> ${ROI_FILE}

all_atlases=$(echo $(ls ${ROOTDIR}/atlases/))

echo "============================="
echo "Summary:"
for atlas in ${all_atlases} ; do
   echo "== Number of ROIs isolated to atlases/${atlas}: $(ls -1 ${ROOTDIR}/atlases/${atlas}/isolated | wc -l)."
done
echo "Ready to find overlaps using 02_find_overlaps.sh ."
