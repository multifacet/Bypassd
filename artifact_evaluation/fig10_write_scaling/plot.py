import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import numpy as np
import sys

def extract_bw(results_file):
    bandwidth = 0

    for line in results_file.readlines():
        # Throughput
        if 'WRITE: bw=' in line:
            words = line.split()
            bandwidth = 0
            for word in words:
                if 'bw=' in word:
                    bandwidth = float(''.join(c for c in word if (c.isdigit() or c=='.')))

    return bandwidth

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

# Baseline aggregate write bandwidth
sync_bw = []
for procs in ["1", "2", "4", "8"]:
    f = open(results_dir + "/baseline_" + procs + ".out", "r")
    bw = extract_bw(f)
    sync_bw.append(bw)

# libaio aggregate write bandwidth
libaio_bw = []
for procs in ["1", "2", "4", "8"]:
    f = open(results_dir + "/libaio_" + procs + ".out", "r")
    bw = extract_bw(f)
    libaio_bw.append(bw)

# iouring aggregate write bandwidth
iouring_bw = []
for procs in ["1", "2", "4", "8"]:
    f = open(results_dir + "/iouring_" + procs + ".out", "r")
    bw = extract_bw(f)
    iouring_bw.append(bw)

# Bypassd aggregate write bandwidth
bypassd_bw = []
for procs in ["1", "2", "4", "8"]:
    f = open(results_dir + "/bypassd_" + procs + ".out", "r")
    bw = extract_bw(f)
    bypassd_bw.append(bw)

# Plot the graph
proc = ['1','2','4','8']
ind = np.arange(len(proc))
width = 0.15

plt.bar(ind,sync_bw,width,label='sync',color='tab:blue')
plt.bar(ind+1.2*width,libaio_bw,width,label='libaio',color='tab:orange')
plt.bar(ind+2.4*width,iouring_bw,width,label='io_uring',color='tab:purple')
plt.bar(ind+3.6*width,bypassd_bw,width,label='bypassd',color='tab:green')

procs=['1','2','4','8']

plt.legend(loc='upper left',ncol=2)
plt.ylabel('Aggregate write\nbandwidth (MB/s)')
plt.xlabel('# of processes')
plt.xticks([0.27,1.27,2.27,3.27],procs)
plt.yticks([0,1500,3000,4500])

figure = plt.gcf()
figure.set_size_inches(6, 2.5)
plt.tight_layout()
plt.savefig("fio_write_multiproc.pdf")