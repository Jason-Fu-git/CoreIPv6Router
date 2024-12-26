//
// Created by Yusaki on 24-12-17.
//

#ifndef FIRMWARE_BRAM_H
#define FIRMWARE_BRAM_H

#include <stdint.h>

const uint32_t TRIE_TYPE_BT = 0;
const uint32_t TRIE_TYPE_VC = 1;

const uint32_t VCTRIE_ENTRY_FIELD_PREFIX_LENGTH = 0;
const uint32_t VCTRIE_ENTRY_FIELD_PREFIX = 1;
const uint32_t VCTRIE_ENTRY_FIELD_NEXT_HOP = 2;
const uint32_t VCTRIE_ENTRY_FIELD_LC = 8;
const uint32_t VCTRIE_ENTRY_FIELD_RC = 12;

typedef uint32_t TrieAddr;
typedef uint32_t NodeAddr;

#endif //FIRMWARE_BRAM_H
