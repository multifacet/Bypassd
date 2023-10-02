import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import re
import sys

def extract_lat_bw(results_file):
    latency = 0
    bandwidth = 0

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

    return (latency, bandwidth)

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

# Baseline write latency
sync_lat = []
sync_bw = []
for blk_size in ["4KB", "8KB", "16KB", "32KB", "64KB", "128KB"]:
    f = open(results_dir + "/baseline_" + blk_size + ".out", "r")
    lat,bw = extract_lat_bw(f)
    sync_lat.append(lat)
    sync_bw.append(bw)

# libaio write latency
libaio_lat = []
libaio_bw = []
for blk_size in ["4KB", "8KB", "16KB", "32KB", "64KB", "128KB"]:
    f = open(results_dir + "/libaio_" + blk_size + ".out", "r")
    lat,bw = extract_lat_bw(f)
    libaio_lat.append(lat)
    libaio_bw.append(bw)

# io_uring write latency
iouring_lat = []
iouring_bw = []
for blk_size in ["4KB", "8KB", "16KB", "32KB", "64KB", "128KB"]:
    f = open(results_dir + "/iouring_" + blk_size + ".out", "r")
    lat,bw = extract_lat_bw(f)
    iouring_lat.append(lat)
    iouring_bw.append(bw)

# spdk write latency
spdk_lat = []
spdk_bw = []
for blk_size in ["4KB", "8KB", "16KB", "32KB", "64KB", "128KB"]:
    f = open(results_dir + "/spdk_" + blk_size + ".out", "r")
    lat,bw = extract_lat_bw(f)
    spdk_lat.append(lat)
    spdk_bw.append(bw)

# bypassd write latency
bypassd_lat = []
bypassd_bw = []
for blk_size in ["4KB", "8KB", "16KB", "32KB", "64KB", "128KB"]:
    f = open(results_dir + "/bypassd_" + blk_size + ".out", "r")
    lat,bw = extract_lat_bw(f)
    bypassd_lat.append(lat)
    bypassd_bw.append(bw)

# Plot the graph
fig = plt.figure()

plt.ylabel("Write latency (us)", size=18)
plt.yticks([10,20,30,40])

plt.xlabel("Write bandwidth (GB/s)",size=18)
plt.plot(sync_bw, sync_lat, label='sync', marker='.', linewidth=1,color='tab:blue')
plt.plot(libaio_bw, libaio_lat, label='libaio', marker='x', linewidth=1,color='tab:orange')
plt.plot(iouring_bw, iouring_lat, label='io_uring', marker='1', linewidth=1,color='tab:purple')
plt.plot(spdk_bw, spdk_lat, label='spdk', marker='s', linewidth=1,color='tab:red')
plt.plot(bypassd_bw, bypassd_lat, label='bypassd', marker='^', linewidth=1,color='tab:green')

plt.legend(loc='best',ncol=2,columnspacing=0,fontsize=10)

block_sizes=['4KB','8KB','16KB','32KB','64KB','128KB']
i=0
for x,y in zip(sync_bw,sync_lat):
    label = block_sizes[i]
    i += 1
    if i == 6:
        plt.annotate(label,(x,y),textcoords="offset points",xytext=(-25,-4), ha='center',fontsize=12)
    else:
        plt.annotate(label, # this is the text
                 (x,y), # these are the coordinates to position the label
                 textcoords="offset points", # how to position the text
                 xytext=(0,10), # distance from text to points (x,y)
                 ha='center',fontsize=12) # horizontal alignment can be left, right or center

figure = plt.gcf()
figure.set_size_inches(6, 2.5)
plt.tight_layout()
plt.savefig("fio_rwrite.pdf")