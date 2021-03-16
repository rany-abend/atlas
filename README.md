---


---

<h1 id="subcortical-atlas">Subcortical atlas</h1>
<h2 id="background">Background</h2>
<p>These bash scripts generate an atlas of segmented subcortical structures by integrating a number of existing atlases and segmentation pipelines.<br>
The segmented structures include (see table):</p>
<ul>
<li><strong>Amygdala</strong> subnuclei (9 ROIs/hemisphere)<sup class="footnote-ref"><a href="#fn1" id="fnref1">1</a></sup></li>
<li><strong>Hippocampus</strong> subfields (19 ROIs/hemisphere)<sup class="footnote-ref"><a href="#fn2" id="fnref2">2</a></sup></li>
<li><strong>Thalamus</strong> subnuclei (23 ROIs/hemisphere)<sup class="footnote-ref"><a href="#fn3" id="fnref3">3</a></sup></li>
<li><strong>Striatum</strong> (4 nuclei/hemisphere)<sup class="footnote-ref"><a href="#fn4" id="fnref4">4</a></sup></li>
<li><strong>Hypothalamus</strong> (25 ROIs/hemisphere)<sup class="footnote-ref"><a href="#fn5" id="fnref5">5</a></sup></li>
<li><strong>Midbrain/brainstem</strong> (9 ROIs)<sup class="footnote-ref"><a href="#fn6" id="fnref6">6</a></sup></li>
<li><strong>Cerebellum</strong> (28 ROIs)<sup class="footnote-ref"><a href="#fn7" id="fnref7">7</a></sup></li>
<li>Additionally: any of the <strong>Schaefer cortical parcellations</strong> (100-1000 parcels) can be downloaded and added to the atlas<sup class="footnote-ref"><a href="#fn8" id="fnref8">8</a></sup></li>
</ul>
<p>Individual ROIs can be flexibly combined into larger ROIs.<br>
The generated atlas is in MNI152 space and comes in 3D and 4D versions.</p>
<h2 id="usage">Usage</h2>
<p>Create a local directory (ATLAS_DIR, hereafter), and download the four scripts into a “/code” directory within it.</p>
<hr>
<p><strong>SCRIPT 1: 01_get_and_isolate_ROIs.sh</strong><br>
In this script, the user chooses which of the original atlases to download and process. When all the available atlases are processed, they include:</p>
<ol>
<li>FreeSurfer: the scripts then segments amygdala and hippocampus subnuclei (using segmentHA_T1.sh), thalamus subnuclei (using <a href="http://segmentThalamicNuclei.sh">segmentThalamicNuclei.sh</a>), and four strtiatal nuclei (using the original FreeSurfer segmentation).</li>
<li>Hypothalamus</li>
<li>Midbrain/brainstem</li>
<li>Cerebellum</li>
<li>Additionally, the script is set up to download and process any of the Schaefer cortical parcellations.</li>
</ol>
<p><strong>User defines:</strong></p>
<ol>
<li>DOWNLOAD: whether to download source atlases (YES/NO; no need to download again if previously downloaded to ATLAS_DIR/source).</li>
<li>DO_AAN, etc: which atlases to process.</li>
<li>ATLAS_DIR: working directory.</li>
<li>SUBCORTICAL_LIST: name of the output file that will list all the individual subcortical ROIs that were processed (can leave default: ATLAS_DIR}/code/all_subcortical_ROIs.txt).</li>
<li>CORTICAL_LIST: name of the output file that will list all the individual cortical parcels that were processed (can leave default: ATLAS_DIR/code/all_cortical_ROIs.txt).</li>
<li>FREESURFER_HOME: local FreeSurfer install.</li>
</ol>
<p><strong>Script outputs:</strong></p>
<ol>
<li>Directories within ATLAS_DIR containing processed individual nii.gz files per ROI (see Table 1). These files are contained within a /isolated sub-directory in each atlas directory (e.g., <em>ATLAS_DIR/Amygdala/isolated/Amygdala_Left-Accessory-Basal-nucleus.nii.gz</em>, etc).</li>
<li>A text file (saved in ATLAS_DIR/code, defined by SUBCORTICAL_LIST) listing all the processed subcortical ROIs.</li>
<li>A text file (saved in ATLAS_DIR/code, defined by CORTICAL_LIST) listing all the processed cortical parcellations.</li>
</ol>
<hr>
<p><strong>SCRIPT 2: 02_find_overlaps.sh</strong><br>
Since the original atlases were created separately, there are some overlaps between them. This scripts identifies all overlaps.</p>
<p><strong>User defines:</strong></p>
<ol>
<li>ATLAS_DIR: working directory.</li>
<li>OVERLAP_FILE: name of overlap file to be created (can leave as default: ATLAS_DIR/code/overlaps.csv).</li>
</ol>
<p><strong>Script outputs:</strong></p>
<ol>
<li>OVERLAP_FILE in ATLAS_DIR/code/. Each overlap appears in one comma-separated line listing ROI1, ROI2, the size of overlap (in voxels), and coordinates of the overlap.<br>
Note that the next script removes this overlap by subtracting it from ROI1; the user may therefore wish to reorder ROI1 and ROI2 in this file.</li>
</ol>
<hr>
<p><strong>SCRIPT 3: 03_remove_overlaps.sh</strong><br>
This scripts removes the overlaps identified by the previous scripts.</p>
<p><strong>User defines:</strong></p>
<ol>
<li>ATLAS_DIR: working directory.</li>
<li>OVERLAP_FILE: name of the file listing all overlapping pairs of ROIs identified by script 02_find_overlaps.sh (comma-separated). In each pair, script removes overlap between ROI1 and ROI2 from ROI1.</li>
</ol>
<p><strong>Script outputs:</strong><br>
No outputs. The script modifies the individual ROI files in the relevant /isolated directory.</p>
<hr>
<p><strong>SCRIPT 4: 04_merge_ROIs.sh</strong><br>
This scripts takes a user-defined text file specifying all ROIs to comprise the new atlas. These ROIs can include combinations of individual ROIs.</p>
<p><strong>User defines:</strong></p>
<ol>
<li>ATLAS_DIR: working directory.</li>
<li>ROI_FILE: name of user-defined text file specifying ROIs to include in new atlas (default: ATLAS_DIR/code/my_ROIs.txt). Each line should include one specified ROI. The syntax of each line is “roi_number:roi_name;roi1+roi2+roi3+…”, whereby roi_number is an integer defined by the user (note that for Schaefer parcels, these are automatically generated and occupy values 1000-2999); roi_name is a string name defined by the user; and roi1+roi2+roi3+… are individual ROI file names (created by script 01_get_and_isolate_ROIs.sh) combined into roi_name.<br>
For example:<br>
–1008:Schaefer_Left-SomMotA-1:Schaefer_Left-SomMotA-1<br>
–5142:Hypothalamus_Left-BNST:Hypothalamus_Left-BNST<br>
–5243:Hypothalamus_Right-Midbrain:Hypothalamus_Right-STN+Hypothalamus_Right-SN+Hypothalamus_Right-RN+Hypothalamus_Right-ZI</li>
<li>3d_ATLAS_NAME: name of the 3D nii.gz atlas file to be created.</li>
<li>4d_ATLAS_NAME: name of the 4D nii.gz atlas file to be created.</li>
<li>LUT_TABLE_NAME: name of the lookup table text file to be created, accompanying the atlas.</li>
</ol>
<p><strong>Script outputs:</strong></p>
<ol>
<li>A 3D atlas file (3d_ATLAS_NAME.nii.gz) in which all ROIs defined in ROI_FILE are in one volume. Each ROI has the number label defined in ROI_FILE.</li>
<li>A 4D atlas file (4d_ATLAS_NAME.nii.gz) in which each ROI defined in ROI_FILE is in a separate, sequential volume. Each ROI value 1.</li>
<li>A lookup table text file (LUT_TABLE_NAME.txt) defining the RGB color of each ROI in the atlas.</li>
</ol>
<hr>
<p>These scripts require FSL and FreeSurfer 7 to be locally installed.</p>
<h2 id="methods">Methods</h2>
<h2 id="segmented-structures">Segmented structures</h2>
<p>Labels and full names:</p>

<table>
<thead>
<tr>
<th><strong>Amygdala</strong></th>
<th></th>
</tr>
</thead>
<tbody>
<tr>
<td>Amygdala_Left-Accessory-Basal-nucleus</td>
<td>Left Accessory Basal nucleus</td>
</tr>
<tr>
<td>Amygdala_Left-Anterior-amygdaloid-area-AAA</td>
<td>Left Anterior amygdaloid area AAA</td>
</tr>
<tr>
<td>Amygdala_Left-Basal-nucleus</td>
<td>Left Basal nucleus</td>
</tr>
<tr>
<td>Amygdala_Left-Central-nucleus</td>
<td>Left Central nucleus</td>
</tr>
<tr>
<td>Amygdala_Left-Cortical-nucleus</td>
<td>Left Cortical nucleus</td>
</tr>
<tr>
<td>Amygdala_Left-Corticoamygdaloid-transitio</td>
<td>Left Corticoamygdaloid transition</td>
</tr>
<tr>
<td>Amygdala_Left-Lateral-nucleus</td>
<td>Left Lateral nucleus</td>
</tr>
<tr>
<td>Amygdala_Left-Medial-nucleus</td>
<td>Left Medial nucleus</td>
</tr>
<tr>
<td>Amygdala_Left-Paralaminar-nucleus</td>
<td>Left Paralaminar nucleus</td>
</tr>
<tr>
<td>Amygdala_Right-Accessory-Basal-nucleus</td>
<td>Right Accessory Basal nucleus</td>
</tr>
<tr>
<td>Amygdala_Right-Anterior-amygdaloid-area-AAA</td>
<td>Right Anterior amygdaloid area AAA</td>
</tr>
<tr>
<td>Amygdala_Right-Basal-nucleus</td>
<td>Right Basal nucleus</td>
</tr>
<tr>
<td>Amygdala_Right-Central-nucleus</td>
<td>Right Central nucleus</td>
</tr>
<tr>
<td>Amygdala_Right-Cortical-nucleus</td>
<td>Right Cortical nucleus</td>
</tr>
<tr>
<td>Amygdala_Right-Corticoamygdaloid-transitio</td>
<td>Right Corticoamygdaloid transition</td>
</tr>
<tr>
<td>Amygdala_Right-Lateral-nucleus</td>
<td>Right Lateral nucleus</td>
</tr>
<tr>
<td>Amygdala_Right-Medial-nucleus</td>
<td>Right Medial nucleus</td>
</tr>
<tr>
<td>Amygdala_Right-Paralaminar-nucleus</td>
<td>Right Paralaminar nucleus</td>
</tr>
<tr>
<td><strong>Hippocampus</strong></td>
<td></td>
</tr>
<tr>
<td>Hippocampus_Left-CA1-body</td>
<td>Left CA1 body</td>
</tr>
<tr>
<td>Hippocampus_Left-CA1-head</td>
<td>Left CA1 head</td>
</tr>
<tr>
<td>Hippocampus_Left-CA3-body</td>
<td>Left CA3 body</td>
</tr>
<tr>
<td>Hippocampus_Left-CA3-head</td>
<td>Left CA3 head</td>
</tr>
<tr>
<td>Hippocampus_Left-CA4-body</td>
<td>Left CA4 body</td>
</tr>
<tr>
<td>Hippocampus_Left-CA4-head</td>
<td>Left CA4 head</td>
</tr>
<tr>
<td>Hippocampus_Left-fimbria</td>
<td>Left fimbria</td>
</tr>
<tr>
<td>Hippocampus_Left-GC-ML-DG-body</td>
<td>Left GC ML DG body</td>
</tr>
<tr>
<td>Hippocampus_Left-GC-ML-DG-head</td>
<td>Left GC ML DG head</td>
</tr>
<tr>
<td>Hippocampus_Left-HATA</td>
<td>Left HATA</td>
</tr>
<tr>
<td>Hippocampus_Left-hippocampal-fissure</td>
<td>Left hippocampal fissure</td>
</tr>
<tr>
<td>Hippocampus_Left-HP-tail</td>
<td>Left HP tail</td>
</tr>
<tr>
<td>Hippocampus_Left-molecular-layer-HP-body</td>
<td>Left molecular layer HP body</td>
</tr>
<tr>
<td>Hippocampus_Left-molecular-layer-HP-head</td>
<td>Left molecular layer HP head</td>
</tr>
<tr>
<td>Hippocampus_Left-parasubiculum</td>
<td>Left parasubiculum</td>
</tr>
<tr>
<td>Hippocampus_Left-presubiculum-body</td>
<td>Left presubiculum body</td>
</tr>
<tr>
<td>Hippocampus_Left-presubiculum-head</td>
<td>Left presubiculum head</td>
</tr>
<tr>
<td>Hippocampus_Left-subiculum-body</td>
<td>Left subiculum body</td>
</tr>
<tr>
<td>Hippocampus_Left-subiculum-head</td>
<td>Left subiculum head</td>
</tr>
<tr>
<td>Hippocampus_Right-CA1-body</td>
<td>Right CA1 body</td>
</tr>
<tr>
<td>Hippocampus_Right-CA1-head</td>
<td>Right CA1 head</td>
</tr>
<tr>
<td>Hippocampus_Right-CA3-body</td>
<td>Right CA3 body</td>
</tr>
<tr>
<td>Hippocampus_Right-CA3-head</td>
<td>Right CA3 head</td>
</tr>
<tr>
<td>Hippocampus_Right-CA4-body</td>
<td>Right CA4 body</td>
</tr>
<tr>
<td>Hippocampus_Right-CA4-head</td>
<td>Right CA4 head</td>
</tr>
<tr>
<td>Hippocampus_Right-fimbria</td>
<td>Right fimbria</td>
</tr>
<tr>
<td>Hippocampus_Right-GC-ML-DG-body</td>
<td>Right GC ML DG body</td>
</tr>
<tr>
<td>Hippocampus_Right-GC-ML-DG-head</td>
<td>Right GC ML DG head</td>
</tr>
<tr>
<td>Hippocampus_Right-HATA</td>
<td>Right HATA</td>
</tr>
<tr>
<td>Hippocampus_Right-hippocampal-fissure</td>
<td>Right hippocampal fissure</td>
</tr>
<tr>
<td>Hippocampus_Right-HP-tail</td>
<td>Right HP tail</td>
</tr>
<tr>
<td>Hippocampus_Right-molecular-layer-HP-body</td>
<td>Right molecular layer HP body</td>
</tr>
<tr>
<td>Hippocampus_Right-molecular-layer-HP-head</td>
<td>Right molecular layer HP head</td>
</tr>
<tr>
<td>Hippocampus_Right-parasubiculum</td>
<td>Right parasubiculum</td>
</tr>
<tr>
<td>Hippocampus_Right-presubiculum-body</td>
<td>Right presubiculum body</td>
</tr>
<tr>
<td>Hippocampus_Right-presubiculum-head</td>
<td>Right presubiculum head</td>
</tr>
<tr>
<td>Hippocampus_Right-subiculum-body</td>
<td>Right subiculum body</td>
</tr>
<tr>
<td><strong>Thalamus</strong></td>
<td></td>
</tr>
<tr>
<td>Thalamus_Left-AV</td>
<td>Left anteroventral nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-CeM</td>
<td>Left Central medial nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-CL</td>
<td>Left Central lateral nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-CM</td>
<td>Left Centromedian nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-LD</td>
<td>Left laterodorsal nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-LGN</td>
<td>Left Lateral geniculate nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-LP</td>
<td>Left Lateral posterior nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-L-Sg</td>
<td>Left Limitans nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-MDl</td>
<td>Left Mediodorsal lateral parvocellular nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-MDm</td>
<td>Left Mediodorsal medial magnocellular nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-MGN</td>
<td>Left Medial Geniculate nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-MV(Re)</td>
<td>Left Reuniens (medial ventral) nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-Pf</td>
<td>Left Parafascicular nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-PuA</td>
<td>Left Pulvinar anterior nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-PuI</td>
<td>Left Pulvinar inferior nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-PuL</td>
<td>Left Pulvinar lateral nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-PuM</td>
<td>Left Pulvinar medial nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-VAmc</td>
<td>Left Ventral anterior magnocellular nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-VA</td>
<td>Left Ventral anterior nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-VLa</td>
<td>Left Ventral lateral anterior nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-VLp</td>
<td>Left Ventral lateral posterior nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-VM</td>
<td>Left Ventromedial nucleus</td>
</tr>
<tr>
<td>Thalamus_Left-VPL</td>
<td>Left Ventral posterolateral nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-AV</td>
<td>Right anteroventral nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-CeM</td>
<td>Right Central medial nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-CL</td>
<td>Right Central lateral nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-CM</td>
<td>Right Centromedian nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-LD</td>
<td>Right laterodorsal nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-LGN</td>
<td>Right Lateral geniculate nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-LP</td>
<td>Right Lateral posterior nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-L-Sg</td>
<td>Right Limitans nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-MDl</td>
<td>Right Mediodorsal lateral parvocellular nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-MDm</td>
<td>Right Mediodorsal medial magnocellular nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-MGN</td>
<td>Right Medial Geniculate nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-MV(Re)</td>
<td>Right Reuniens (medial ventral) nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-Pc</td>
<td>Right Paracentral nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-Pf</td>
<td>Right Parafascicular nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-PuA</td>
<td>Right Pulvinar anterior nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-PuI</td>
<td>Right Pulvinar inferior nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-PuL</td>
<td>Right Pulvinar lateral nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-PuM</td>
<td>Right Pulvinar medial nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-VAmc</td>
<td>Right Ventral anterior magnocellular nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-VA</td>
<td>Right Ventral anterior nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-VLa</td>
<td>Right Ventral lateral anterior nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-VLp</td>
<td>Right Ventral lateral posterior nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-VM</td>
<td>Right Ventromedial nucleus</td>
</tr>
<tr>
<td>Thalamus_Right-VPL</td>
<td>Right Ventral posterolateral nucleus</td>
</tr>
<tr>
<td><strong>Striatum</strong></td>
<td></td>
</tr>
<tr>
<td>Striatum_Left-Accumbens-area</td>
<td>Left Accumbens area</td>
</tr>
<tr>
<td>Striatum_Left-Caudate</td>
<td>Left Caudate</td>
</tr>
<tr>
<td>Striatum_Left-Pallidum</td>
<td>Left Pallidum</td>
</tr>
<tr>
<td>Striatum_Left-Putamen</td>
<td>Left Putamen</td>
</tr>
<tr>
<td>Striatum_Right-Accumbens-area</td>
<td>Right Accumbens area</td>
</tr>
<tr>
<td>Striatum_Right-Caudate</td>
<td>Right Caudate</td>
</tr>
<tr>
<td>Striatum_Right-Pallidum</td>
<td>Right Pallidum</td>
</tr>
<tr>
<td>Striatum_Right-Putamen</td>
<td>Right Putamen</td>
</tr>
<tr>
<td><strong>Hypothalamus</strong></td>
<td></td>
</tr>
<tr>
<td>Hypothalamus_Left-AC</td>
<td>Left Anterior commissure</td>
</tr>
<tr>
<td>Hypothalamus_Left-AHA</td>
<td>Left Anterior hypothalamic area</td>
</tr>
<tr>
<td>Hypothalamus_Left-AN</td>
<td>Left Arcuate nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Left-BNST</td>
<td>Left Bed nucleus of the stria terminalis</td>
</tr>
<tr>
<td>Hypothalamus_Left-dB</td>
<td>Left Diagonal band of broca</td>
</tr>
<tr>
<td>Hypothalamus_Left-DM</td>
<td>Left Dorsomedial hypothalamic nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Left-DPEH</td>
<td>Left Dorsal periventricular nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Left-FX</td>
<td>Left Fornix</td>
</tr>
<tr>
<td>Hypothalamus_Left-ITP</td>
<td>Left Inferior thalamic peduncle</td>
</tr>
<tr>
<td>Hypothalamus_Left-LH</td>
<td>Left  Lateral hypothalamus</td>
</tr>
<tr>
<td>Hypothalamus_Left-MM</td>
<td>Left Mammillary bodies</td>
</tr>
<tr>
<td>Hypothalamus_Left-MPO</td>
<td>Left Medial preoptic nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Left-MT</td>
<td>Left Mammillothalamic tract</td>
</tr>
<tr>
<td>Hypothalamus_Left-NBM</td>
<td>Left Nucleus basalis of Meynert</td>
</tr>
<tr>
<td>Hypothalamus_Left-Pa</td>
<td>Left Paraventricular nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Left-Pe</td>
<td>Left Periventricular nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Left-PH</td>
<td>Left Posterior hypothalamus</td>
</tr>
<tr>
<td>Hypothalamus_Left-RN</td>
<td>Left Red nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Left-SC</td>
<td>Left Suprachiasmatic nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Left-SN</td>
<td>Left Substantia nigra</td>
</tr>
<tr>
<td>Hypothalamus_Left-SO</td>
<td>Left Supraoptic nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Left-STN</td>
<td>Left Subthalamic nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Left-TM</td>
<td>Left Tuberomammillary nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Left-VM</td>
<td>Left Ventromedial hypothalamus</td>
</tr>
<tr>
<td>Hypothalamus_Left-ZI</td>
<td>Left Zona incerta</td>
</tr>
<tr>
<td>Hypothalamus_Right-AC</td>
<td>Right Anterior commissure</td>
</tr>
<tr>
<td>Hypothalamus_Right-AHA</td>
<td>Right Anterior hypothalamic area</td>
</tr>
<tr>
<td>Hypothalamus_Right-AN</td>
<td>Right Arcuate nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Right-BNST</td>
<td>Right Bed nucleus of the stria terminalis</td>
</tr>
<tr>
<td>Hypothalamus_Right-dB</td>
<td>Right Diagonal band of broca</td>
</tr>
<tr>
<td>Hypothalamus_Right-DM</td>
<td>Right Dorsomedial hypothalamic nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Right-DPEH</td>
<td>Right Dorsal periventricular nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Right-FX</td>
<td>Right Fornix</td>
</tr>
<tr>
<td>Hypothalamus_Right-ITP</td>
<td>Right Inferior thalamic peduncle</td>
</tr>
<tr>
<td>Hypothalamus_Right-LH</td>
<td>Right  Lateral hypothalamus</td>
</tr>
<tr>
<td>Hypothalamus_Right-MM</td>
<td>Right Mammillary bodies</td>
</tr>
<tr>
<td>Hypothalamus_Right-MPO</td>
<td>Right Medial preoptic nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Right-MT</td>
<td>Right Mammillothalamic tract</td>
</tr>
<tr>
<td>Hypothalamus_Right-NBM</td>
<td>Right Nucleus basalis of Meynert</td>
</tr>
<tr>
<td>Hypothalamus_Right-Pa</td>
<td>Right Paraventricular nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Right-Pe</td>
<td>Right Periventricular nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Right-PH</td>
<td>Right Posterior hypothalamus</td>
</tr>
<tr>
<td>Hypothalamus_Right-RN</td>
<td>Right Red nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Right-SC</td>
<td>Right Suprachiasmatic nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Right-SN</td>
<td>Right Substantia nigra</td>
</tr>
<tr>
<td>Hypothalamus_Right-SO</td>
<td>Right Supraoptic nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Right-STN</td>
<td>Right Subthalamic nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Right-TM</td>
<td>Right Tuberomammillary nucleus</td>
</tr>
<tr>
<td>Hypothalamus_Right-VM</td>
<td>Right Ventromedial hypothalamus</td>
</tr>
<tr>
<td>Hypothalamus_Right-ZI</td>
<td>Right Zona incerta</td>
</tr>
<tr>
<td><strong>Midbrain/brainstem</strong></td>
<td></td>
</tr>
<tr>
<td>AAN_DR</td>
<td>Dorsal raphe</td>
</tr>
<tr>
<td>AAN_LC</td>
<td>Locus coeruleus</td>
</tr>
<tr>
<td>AAN_MRF</td>
<td>Midbrain reticular formation</td>
</tr>
<tr>
<td>AAN_MR</td>
<td>Median raphe</td>
</tr>
<tr>
<td>AAN_PAG</td>
<td>Periaqueductal gray</td>
</tr>
<tr>
<td>AAN_PBC</td>
<td>Parabrachial complex</td>
</tr>
<tr>
<td>AAN_PO</td>
<td>Pontis oralis</td>
</tr>
<tr>
<td>AAN_PPN</td>
<td>Pendunculopontine nucleus</td>
</tr>
<tr>
<td>AAN_VTA</td>
<td>Ventral tegmental area</td>
</tr>
<tr>
<td><strong>Cerebellum</strong></td>
<td></td>
</tr>
<tr>
<td>Cerebellum_LeftCrusII</td>
<td>Left Crus II</td>
</tr>
<tr>
<td>Cerebellum_LeftCrusI</td>
<td>Left Crus I</td>
</tr>
<tr>
<td>Cerebellum_LeftI-IV</td>
<td>Left IV</td>
</tr>
<tr>
<td>Cerebellum_LeftIX</td>
<td>Left IX</td>
</tr>
<tr>
<td>Cerebellum_LeftVIIb</td>
<td>Left VIIb</td>
</tr>
<tr>
<td>Cerebellum_LeftVIIIa</td>
<td>Left VIIIa</td>
</tr>
<tr>
<td>Cerebellum_LeftVIIIb</td>
<td>Left VIIIb</td>
</tr>
<tr>
<td>Cerebellum_LeftVI</td>
<td>Left VI</td>
</tr>
<tr>
<td>Cerebellum_LeftV</td>
<td>Left V</td>
</tr>
<tr>
<td>Cerebellum_LeftX</td>
<td>Left X</td>
</tr>
<tr>
<td>Cerebellum_RightCrusII</td>
<td>Right Crus II</td>
</tr>
<tr>
<td>Cerebellum_RightCrusI</td>
<td>Right Crus I</td>
</tr>
<tr>
<td>Cerebellum_RightI-IV</td>
<td>Right IV</td>
</tr>
<tr>
<td>Cerebellum_RightIX</td>
<td>Right IX</td>
</tr>
<tr>
<td>Cerebellum_RightVIIb</td>
<td>Right VIIb</td>
</tr>
<tr>
<td>Cerebellum_RightVIIIa</td>
<td>Right VIIIa</td>
</tr>
<tr>
<td>Cerebellum_RightVIIIb</td>
<td>Right VIIIb</td>
</tr>
<tr>
<td>Cerebellum_RightVI</td>
<td>Right VI</td>
</tr>
<tr>
<td>Cerebellum_RightV</td>
<td>Right V</td>
</tr>
<tr>
<td>Cerebellum_RightX</td>
<td>Right X</td>
</tr>
<tr>
<td>Cerebellum_VermisCrusII</td>
<td>Vermis Crus II</td>
</tr>
<tr>
<td>Cerebellum_VermisCrusI</td>
<td>Vermis Crus I</td>
</tr>
<tr>
<td>Cerebellum_VermisIX</td>
<td>Vermis IX</td>
</tr>
<tr>
<td>Cerebellum_VermisVIIb</td>
<td>Vermis VIIb</td>
</tr>
<tr>
<td>Cerebellum_VermisVIIIa</td>
<td>Vermis VIIIa</td>
</tr>
<tr>
<td>Cerebellum_VermisVIIIb</td>
<td>Vermis VIIIb</td>
</tr>
<tr>
<td>Cerebellum_VermisVI</td>
<td>Vermis VI</td>
</tr>
<tr>
<td>Cerebellum_VermisX</td>
<td>Vermis X</td>
</tr>
</tbody>
</table><h2 id="figures">Figures</h2>
<h2 id="references">References</h2>
<hr class="footnotes-sep">
<section class="footnotes">
<ol class="footnotes-list">
<li id="fn1" class="footnote-item"><p>High-resolution magnetic resonance imaging reveals nuclei of the human amygdala: manual segmentation to automatic atlas. Saygin, Z.M., Kliemann, D., Iglesias, J.E., van der Kouwe, A.J.W., Boyd, E., Reuter, M., Stevens, A., Van Leemput, K., Mc Kee, A., Frosch, M.P., Fischl, B., Augustinack, J.C. Neuroimage, 155, July 2017, 370-382. <a href="#fnref1" class="footnote-backref">↩︎</a></p>
</li>
<li id="fn2" class="footnote-item"><p>A computational atlas of the hippocampal formation using ex vivo, ultra-high resolution MRI: Application to adaptive segmentation of in vivo MRI. Iglesias, J.E., Augustinack, J.C., Nguyen, K., Player, C.M., Player, A., Wright, M., Roy, N., Frosch, M.P., Mc Kee, A.C., Wald, L.L., Fischl, B., and Van Leemput, K. Neuroimage, 115, July 2015, 117-137. <a href="#fnref2" class="footnote-backref">↩︎</a></p>
</li>
<li id="fn3" class="footnote-item"><p>A probabilistic atlas of the human thalamic nuclei combining ex vivo MRI and histology. Iglesias, J.E., Insausti, R., Lerma-Usabiaga, G., Bocchetta, M., Van Leemput, K., Greve, D., van der Kouwe, A., Caballero-Gaudes, C., Paz-Alonso, P. Neuroimage, 2018. <a href="#fnref3" class="footnote-backref">↩︎</a></p>
</li>
<li id="fn4" class="footnote-item"><p>Whole Brain Segmentation: Automated Labeling of Neuroanatomical Structures in the Human Brain, Fischl, B., et al., (2002). Neuron, 33:341-355. <a href="#fnref4" class="footnote-backref">↩︎</a></p>
</li>
<li id="fn5" class="footnote-item"><p>A high-resolution in vivo magnetic resonance imaging atlas of the human hypothalamic region. Neudorfer, C., Germann, J., Elias, G.J.B., Gramer, R., Boutet, A., Lozano, A.M. Scientific Data. 2020;7(1):305. <a href="#fnref5" class="footnote-backref">↩︎</a></p>
</li>
<li id="fn6" class="footnote-item"><p>Neuroanatomic connectivity of the human ascending arousal system critical to consciousness and its disorders. Edlow, B.L., Takahashi, E, Wu, O., et al. Journal of Neuropathology &amp; Experimental Neurology. 2012;71(6):531-546. <a href="#fnref6" class="footnote-backref">↩︎</a></p>
</li>
<li id="fn7" class="footnote-item"><p>A probabilistic MR atlas of the human cerebellum. Diedrichsen, J., Balsters, J.H., Flavell, J., Cussans, E., Ramnani, N. Neuroimage. 2009;46(1):39-46. <a href="#fnref7" class="footnote-backref">↩︎</a></p>
</li>
<li id="fn8" class="footnote-item"><p>Local-Global Parcellation of the Human Cerebral Cortex from Intrinsic Functional Connectivity MRI. Schaefer, A., Kong, R., Gordon, E.M., et al. Cereb Cortex. 2018;28(9):3095-3114. <a href="#fnref8" class="footnote-backref">↩︎</a></p>
</li>
</ol>
</section>

