import fileinput

last_size = 25000
last_item = None
entries = []
sum = 0
head = 0

for line in fileinput.input():
    size_, entry_, kind = line.split(",")
    if kind.strip() != "addr":
        continue
    entry_ = entry_.strip()
    if entry_.startswith("i_"):
        continue
    if entry_.startswith("__C_LINE"):
        continue
    if entry_.startswith("__ASM_LINE"):
        continue
    if entry_.startswith("__CDB_INFO"):
        continue

    if head == 0:
        if entry_ == "module_header":
            head = size_
        else:
            continue

    size_ = int(size_, 16)
    if size_ > 65535:
        continue

    diff = size_ - last_size

    if diff <= 0:
        last_size = size_
        continue

    if diff >= 8:
        entries.append((last_item, (diff, size_)))
        sum += diff

    last_size = size_
    last_item = entry_

l_total = 0

for key, value in sorted(entries, key=lambda x: x[1], reverse=True):
    if key and not key.startswith("_"):
        l_total += value[0]
    print("{0}: {1} (${2:02x}...${3:02x})".format(key, value[0], value[1], value[1] + value[0]))

print("L: {0}".format(l_total))
print("Sum: {0}".format(sum))
