import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import numpy as np
import sys

def extract_lat_iops(results_file):
    latency = 0
    iops = 0

    for line in results_file.readlines():
        # Average latency
        if 'lat' in line and 'avg' in line and 'clat' not in line and 'slat' not in line:
            words = line.split(',')
            for word in words:
                if 'avg' in word:
                    latency = float(''.join(c for c in word if (c.isdigit() or c =='.')))
                    if 'nsec' in line:
                        latency /= 1000

        elif 'lat percentiles' in line:
            if 'nsec' in line:
                lat_unit = 'nsec'
            else:
                lat_unit = 'usec'

    return (latency, iops)

# Check if the results directory is provided
if len(sys.argv) != 2:
    print("Usage: python plot.py <results_dir>")
    sys.exit(0)

# Matplotlib graph settings
plt.rcParams['xtick.labelsize']=14
plt.rcParams['ytick.labelsize']=14
plt.rcParams['lines.linewidth']=2
plt.rcParams['legend.fontsize']=12
plt.rcParams['axes.labelsize']=18
plt.rcParams['axes.linewidth'] = 2
plt.rcParams['axes.facecolor'] = "white"
plt.rcParams['axes.edgecolor'] = "black"
plt.rcParams['axes.spines.top'] = True
plt.rcParams['axes.spines.bottom'] = True
plt.rcParams['axes.spines.left'] = True
plt.rcParams['axes.spines.right'] = True

font_path = '/usr/share/fonts/truetype/adf/GilliusADF-Regular.otf'  # Your font path goes here
font_manager.fontManager.addfont(font_path)
prop = font_manager.FontProperties(fname=font_path)

plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['font.sans-serif'] = prop.get_name()
plt.rcParams['pdf.fonttype'] = 42
plt.rcParams['ps.fonttype'] = 42

# Extract the data from the files
results_dir = sys.argv[1]

# Read baseline latency
sync_lat = []
sync_iops = []
for bg_procs in ["1", "2", "4", "8", "12", "16"]:
    f = open(results_dir + "/baseline_" + bg_procs + ".out", "r")
    lat,bw = extract_lat_iops(f)
    sync_lat.append(lat)

# Read bypassd latency
bypassd_lat = []
bypassd_iops = []
for bg_procs in ["1", "2", "4", "8", "12", "16"]:
    f = open(results_dir + "/bypassd_" + bg_procs + ".out", "r")
    lat,bw = extract_lat_iops(f)
    bypassd_lat.append(lat)

# Plot the graph
background_readers = ['1','2','4','8','12','16']
ind = np.arange(len(background_readers))
width = 0.15

plt.bar(ind,sync_lat,width,label='sync',color='tab:blue')
plt.bar(ind+1.2*width,bypassd_lat,width,label='bypassd',color='tab:green')

plt.legend(loc='upper left',ncol=2)
plt.ylabel('4KB rand read\nlatency (us)')
plt.xlabel('# of background readers', size=18)
plt.xticks([0.27,1.27,2.27,3.27,4.27,5.27],background_readers)
plt.ylim(0,13)

figure = plt.gcf()
figure.set_size_inches(6, 2.2)
plt.tight_layout()
plt.savefig("io_interference.pdf")