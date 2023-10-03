import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import re
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

        # Throughput
        elif 'bw=' in line:
            words = line.split()
            bandwidth = 0
            for word in words:
                if 'bw=' in word:
                    bandwidth = float(''.join(c for c in word if (c.isdigit() or c=='.')))
                    iops = (bandwidth * 1024 * 1024) / (4096 * 1000)

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

plt.rcParams['pdf.fonttype'] = 42
plt.rcParams['ps.fonttype'] = 42

# Extract the data from the files
results_dir = sys.argv[1]

# Read baseline measurements
sync_lat = []
sync_iops = []
for threads in ["1", "2", "4", "8", "12", "16", "20"]:
    f = open(results_dir + "/baseline_" + threads + ".out", "r")
    lat,bw = extract_lat_iops(f)
    sync_lat.append(lat)
    sync_iops.append(bw)

# Read libaio measurements
libaio_lat = []
libaio_iops = []
for threads in ["1", "2", "4", "8", "12", "16", "20"]:
    f = open(results_dir + "/libaio_" + threads + ".out", "r")
    lat,bw = extract_lat_iops(f)
    libaio_lat.append(lat)
    libaio_iops.append(bw)

# Read io_uring measurements
iouring_lat = []
iouring_iops = []
for threads in ["1", "2", "4", "8", "12", "16", "20"]:
    f = open(results_dir + "/iouring_" + threads + ".out", "r")
    lat,bw = extract_lat_iops(f)
    iouring_lat.append(lat)
    iouring_iops.append(bw)

# Read spdk measurements
spdk_lat = []
spdk_iops = []
for threads in ["1", "2", "4", "8", "12", "16", "20"]:
    f = open(results_dir + "/spdk_" + threads + ".out", "r")
    lat,bw = extract_lat_iops(f)
    spdk_lat.append(lat)
    spdk_iops.append(bw)

# Read bypassd measurements
bypassd_lat = []
bypassd_iops = []
for threads in ["1", "2", "4", "8", "12", "16", "20"]:
    f = open(results_dir + "/bypassd_" + threads + ".out", "r")
    lat,bw = extract_lat_iops(f)
    bypassd_lat.append(lat)
    bypassd_iops.append(bw)

# Plot the graph
fig = plt.figure()

plt.ylim(3, 18)
plt.ylabel("Latency (us)", size = 18)
plt.xlabel("IOPS (K)", size=18)
plt.plot(sync_iops, sync_lat, label='sync', marker='.', linewidth=1,color='tab:blue')
plt.plot(libaio_iops, libaio_lat, label='libaio', marker='x', linewidth=1,color='tab:orange')
plt.plot(iouring_iops, iouring_lat, label='io_uring', marker='1', linewidth=1,color='tab:purple')
plt.plot(spdk_iops, spdk_lat, label='spdk', marker='s', linewidth=1,color='tab:red')
plt.plot(bypassd_iops, bypassd_lat, label='bypassd', marker='^', linewidth=1,color='tab:green')

threads=['1','2','4','8','12','16','20']
i=0
for x,y in zip(libaio_iops,libaio_lat):
    label = threads[i]
    i += 1
    if i == 4:
        plt.annotate(label,(x,y),textcoords="offset points",xytext=(5,5), ha='center',fontsize=14)
    elif i == 6:
        plt.annotate(label,(x,y),textcoords="offset points",xytext=(-10,5), ha='center',fontsize=14)
    else:
        plt.annotate(label, # this is the text
                 (x,y), # these are the coordinates to position the label
                 textcoords="offset points", # how to position the text
                 xytext=(0,5), # distance from text to points (x,y)
                 ha='center',fontsize=14) # horizontal alignment can be left, right or center
        
plt.legend(loc='upper left',ncol=2,fontsize=10)

figure = plt.gcf()
figure.set_size_inches(6, 2.5)
plt.tight_layout()
plt.savefig("fio_read_scaling.pdf", bbox_inches="tight")