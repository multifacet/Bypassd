# Bypassd: Enabling fast userspace access to shared SSDs
Bypassd is a novel I/O architecture that provides low latency access to shared SSDs.
This repository contains the source code and instructions to reproduce some of the key results in the BypassD paper (to appear in ASPLOS'24).

## Overview
BypassD has 3 main components:
1. Modified Linux kernel (based on v5.4) that includes the changes necessary to support BypassD
2. Kernel module that performs tasks related to NVMe in BypassD
3. Userspace shim library called 'userLib' that enables transparent support for applications

## System requirements
To test/use BypassD, you will need a system with a low latency NVMe SSD such as the Intel Optane P5800X SSD.
The scripts in this repo assume an Intel machine (Skylake or newer) with atleast 20 cores, running Ubuntu 20.04. If you are testing on other configurations, you will have to manually change the scripts.
Lastly, you would also want to <code>sudo</code> access on the machine.

## Getting started
First, clone the repo and the initialize the submodules. This repo contains a lot of submodules, so make to initialize all of them recursively.
```bash
git clone https://github.com/multifacet/Bypassd.git
cd Bypassd
git submodule update --init --recursive
```
Once the repository is initialized, build and install the linux kernel. The repo contains a script to help you with that.
```bash
bash utils/build_linux_kernel.sh
```
This step might take some time depending on the number of cores in your system. The script has some information on how to handle few common errors during build.
After the kernel is built, update the grub preferences and reboot into the custom kernel.
```bash
sudo grub-reboot "Advanced options for Ubuntu>Ubuntu, with Linux 5.4.0"
sudo reboot
```

You will also have to build SPDK and fio. There are supporting scripts in the <code>utils/</code> directory. You can also refer to the documentation in the respective directories for more information.
```bash
bash utils/build_spdk.sh
bash utils/build_fio.sh
```
You can build the **kernel module** and **user library** by going to their subdirectories and invoking <code>make</code>. If you are using the scripts for artifact evaluation, you can skip this step.
For more information, you can look at <code>utils/enable_bypassd.sh</code>.
```bash
pushd kernel/module
make
sudo insmod bypassd.ko
popd

pushd userLib
make
popd
```

## Reproducing results in the paper
This repo includes scripts to reproduce the key results in the paper.
Here is a list of graphs that can be generated using the scripts in this repo:
* Figure 6a: Single threaded random read performance
* Figure 6b: Single threaded random write performance
* Figure 9:  Random read scaling with multiple threads
* Figure 10: Write scaling with multiple processes demonstration process sharing from userspace
* Figure 11: Random read latency under interference from background processes

Generating these figures is straightforward. The <code>artifact_evaluation/</code> contains scripts to generate each of this figure. All you have to do is run the script.
For example,
```bash
pushd artificat_evaluation/fig6a_1thread_rread_perf
bash run_exp.sh /dev/nvme0n1 /nvme-mntpoint
popd
```
The script will generate a plot using <code>matplotlib</code> which will be saved as a pdf in the respctive subdirectory. You can also look at the <code>results/</code> sub-directory to get more results from the experiments.

We plan to add more scripts and workloads in the near future.

## License
<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.
