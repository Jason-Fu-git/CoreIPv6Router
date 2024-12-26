# 协议与规范手册

## CPU如何读写BRAM

### 读BRAM

共32块BRAM，其中BT和VC各16块。给CPU读的端口接到总线上，地址为0x2???????，详见bram_data_converter.sv中的注释。摘录如下：

```c
// We need word select to determine which field to give back
// Address to fetch BRAM: 0010 0~15 000X 0000 0000 0000 XXXX XXXX
// So that we have address 0x2??????? for BRAM, and 0x2X??????? for the X-th trie.
// | 31-28 | 27-24 | 23-20 | 19-16 | 15-12 | 11--8 |  7--4 |  3--0 |
// |-------|-------|-------|-------|-------|-------|-------|-------|
// |     2 |  0~15 | 0 / 1 |  zero |  zero |  zero | entry | field |
// |  BRAM |  trie | vc/bt |  none |  none |  none |   sel |   sel |
//
// The lower part is given to the converters below.
// Since the entry index is less than 15, we use 4 bits to represent it.
// field: 0000 for prefix_length, 0001 for prefix, 0010 for entry_offset, 1000 for lc (no matter what entry is) and 1100 for rc.
// Especially, the highest 4 bits 0010 means read, and we will design how to write to BRAM using the highest 4 bits 0011.
```

即规定31~28位为2表示读BRAM，27~24位选择BRAM下标，20位选择VC或BT（规定0表示读BT，1表示读VC），7~4位选择VC的entry下标，3~0位选择读取字段。BT忽略低8位。

我们已经编写了converter将读出来的超长word选择字段并转换为32位word。

### 写BRAM

写BRAM基本与读BRAM相同，但是将地址最高位改为3，即0x3???????。

我们需要一个buffer存储CPU多次写的内容，并用reverse converter转换为BRAM的word。实际上这可以合并成一个模块。
