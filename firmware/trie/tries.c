//
// Created by Yusaki on 24-12-27.
//

#include <ip6.h>
#include <stdio.h>
#include <packet.h>

extern void         BTrieInitBram();
extern int          BTrieLookup(void*, int);
extern int          BTrieInsert(void*, int, unsigned int);
extern int          BTrieDelete(void*, int);
extern void*        BTrieIndexToAddress(unsigned int);
extern void         VCTrieInit();
extern unsigned int VCTrieInsert(void*, unsigned int, unsigned int);
extern int          VCTrieLookup(void*, unsigned int);
extern unsigned int VCTrieGetNodeCount();
extern unsigned int VCTrieGetExcessiveCount();
extern void         VCEntryInvalidate(void*);
extern void         VCEntryModify(void*, unsigned int);
extern void*        VCTrieIndexToAddress(unsigned int);

void TrieInit() {
	BTrieInitBram();
    VCTrieInit();
}

int TrieInsert(void* prefix, unsigned int length, uint32_t next_hop) {
    struct ip6_addr ip6_prefix;
    struct ip6_addr* ip6 = (struct ip6_addr*)prefix;
    for(int i = 0; i < 4; i++) {
		ip6_prefix.s6_addr32[i] = brev8(ip6->s6_addr32[i]);
	}
	int result = VCTrieInsert(&ip6_prefix, length, next_hop);
	if (result < 0) {
		return BTrieInsert(&ip6_prefix, length, next_hop);
	}
	return result;
    // return BTrieInsert(&ip6_prefix, length, next_hop);
}

int TrieLookup(void* prefix, unsigned int length) {
    struct ip6_addr ip6_prefix;
    struct ip6_addr* ip6 = (struct ip6_addr*)prefix;
    for(int i = 0; i < 4; i++) {
		ip6_prefix.s6_addr32[i] = brev8(ip6->s6_addr32[i]);
	}
	int result = VCTrieLookup(&ip6_prefix, length);
	if (result < 0) {
		return BTrieLookup(&ip6_prefix, length);
	}
	return (int)result;
    // return BTrieLookup(&ip6_prefix, length);
}

int TrieDelete(void* prefix, unsigned int length) {
    struct ip6_addr ip6_prefix;
    struct ip6_addr* ip6 = (struct ip6_addr*)prefix;
    for(int i = 0; i < 4; i++) {
		ip6_prefix.s6_addr32[i] = brev8(ip6->s6_addr32[i]);
	}
	int result = VCTrieLookup(&ip6_prefix, length);
	if (result < 0) {
		return BTrieDelete(&ip6_prefix, length);
	}
	VCEntryInvalidate(VCTrieIndexToAddress(result));
	return result;
    // return BTrieDelete(&ip6_prefix, length);
}

void TrieModify(void* prefix, unsigned int length, uint32_t next_hop) {
    struct ip6_addr ip6_prefix;
    struct ip6_addr* ip6 = (struct ip6_addr*)prefix;
    for(int i = 0; i < 4; i++) {
		ip6_prefix.s6_addr32[i] = brev8(ip6->s6_addr32[i]);
	}
	int result = VCTrieLookup(&ip6_prefix, length);
	if (result < 0) {
	    result = BTrieInsert(&ip6_prefix, length, next_hop);
		// if (result > 0) {
		// 	printf("[TF]%d", result);
		// }
        return;
	}
    VCEntryModify(VCTrieIndexToAddress(result), next_hop);
	// if (result > 0) {
	// 	printf("[TF]%d", result);
	// }
}

void TrieReport() {
	printf("[INFO]VC:%u\n", VCTrieGetNodeCount());
	printf("[INFO]Ex:%u\n", VCTrieGetExcessiveCount());
}
