# About this code
This code implements the 3D Cells Segmenter algorithm. Current implementation is done in Matlab and needs the Image Processing Toolbox. Additionally, it uses the “export_fig” and the “slicer” Matlab packages, provided in the “libs” folder, which are freely distributed according to their licenses. Finally, in order for the algorithm to work, you need to download and copy the MIJ library (“mij.jar” and “ij.jar” files) from the following URL and copy them to the “libs” folder.

http://bigwww.epfl.ch/sage/soft/mij/

# How to run the code
The main entry point for the 3D Cells Segmenter is the “demoCS3DGUI.m” file. This program presents a GUI that can be used to select the stacks that are going to be processed for each of the channels, the output directory for the resulting files with the segmentation and some of the basic parameters of the algorithm.

All the remainder parameters can be configured from the “Config.m” file according to the guidelines provided in this and previous papers.

# Citing

If you find this code useful, you might consider citing the original paper:

A. LaTorre, L. Alonso-Nanclares, J. M. Peña, and J. DeFelipe, “3D segmentation of neuronal nuclei and cell-type identification using multi-channel information,” Expert Systems with Applications, vol. 183, p. 115443, Nov. 2021, doi: 10.1016/j.eswa.2021.115443.
