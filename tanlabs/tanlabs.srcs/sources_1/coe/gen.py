nodes = [64, 256, 6144, 7168, 5120, 3072]
bins = [1, 7, 15, 15, 14, 10]
addrs = [8, 13, 13, 13, 13, 12]


def s(a, b):
	return "0" * (2 * b) + ("1" * 5 + "0" * 28 + "1" * 5) * a


def main():
	for i in range(6):
		with open(f"vc_{i}.coe", "w") as f:
			f.write("memory_initialization_radix=2;\nmemory_initialization_vector=\n")
			line = s(bins[i], addrs[i])
			for _ in range(nodes[i] - 1):
				f.write(line + ",\n")
			f.write(line + ";")


if __name__ == '__main__':
	main()
