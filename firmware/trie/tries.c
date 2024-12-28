//
// Created by Yusaki on 24-12-27.
//

#include <ip6.h>
#include <stdio.h>

extern void         BTrieInitBram();
extern int          BTrieLookup(void*, int);
extern int          BTrieInsert(void*, int, unsigned int);
extern int          BTrieDelete(void*, int);
extern unsigned int VCTrieInsert(void*, unsigned int, unsigned int);
extern void*        VCTrieLookup(void*, unsigned int);
extern unsigned int VCTrieGetNodeCount();
extern unsigned int VCTrieGetExcessiveCount();
extern void         VCEntryInvalidate(void*);
extern void*        VCTrieIndexToAddress(unsigned int);

void TrieInit() {
	BTrieInitBram();
}

int TrieInsert(struct ip6_addr* prefix, unsigned int length, uint32_t next_hop) {
	int result = VCTrieInsert(prefix, length, next_hop);
	if (result < 0) {
		return BTrieInsert(prefix, length, next_hop);
	}
	return result;
}

int TrieLookup(struct ip6_addr* prefix, unsigned int length) {
	int result = VCTrieLookup(prefix, length);
	if (result < 0) {
		return BTrieLookup(prefix, length);
	}
	return (int)result;
}

int TrieDelete(struct ip6_addr* prefix, unsigned int length) {
	int result = VCTrieLookup(prefix, length);
	if (result < 0) {
		return BTrieDelete(prefix, length);
	}
	VCEntryInvalidate(VCTrieIndexToAddress(result));
	return result;
}

void TrieReport() {
	printf("[INFO]VC:%u\n", VCTrieGetNodeCount());
	printf("[INFO]Ex:%u\n", VCTrieGetExcessiveCount());
}
