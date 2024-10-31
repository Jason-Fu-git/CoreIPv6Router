in_frames = "frames.txt"
tmp = []

with open(in_frames, "r") as f:
    for line in f:
        iface, length, data = line.rstrip().split(' ', 2)
        if " " in data:
            tmp.append(line.rstrip())
        else:
            formatted = f"{iface} {length}"
            for i in range(0, len(data), 2):
                formatted += f" {data[i:i+2]}"
            tmp.append(formatted)
        
with open(in_frames, "w") as f:
    for line in tmp:
        f.write(f"{line}\n")
