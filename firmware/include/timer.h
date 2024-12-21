#ifndef _TIMER_H_
#define _TIMER_H_

#include "stdint.h"

#define MULTICAST_TIME_LIMIT (30 * 5 * 10000000)

#define TIMEOUT_TIME_LIMIT (180 * 5 * 10000000)
#define TIMEOUT_TIME_LLIMIT 410065408
#define TIMEOUT_TIME_HLIMIT 2

#define GARBAGE_COLLECTION_TIME_LIMIT (120 * 5 * 10000000)
#define GARBAGE_COLLECTION_TIME_LLIMIT 1705032704
#define GARBAGE_COLLECTION_TIME_HLIMIT 1


#define MTIME_LADDR 0x0200BFF8    // lower 32 bits of mtime
#define MTIMECMP_LADDR 0x02004000 // lower 32 bits of mtimecmp

#define MTIME_HADDR 0x0200BFFC    // higher 32 bits of mtime
#define MTIMECMP_HADDR 0x02004004 // higher 32 bits of mtimecmp

/**
 * @brief Check if the timer has expired
 * @param time_llimit lower 32 bits of the time limit
 * @param time_hlimit higher 32 bits of the time limit
 * @param timer_laddr lower 32 bits of the timer (in the route table)
 * @param timer_haddr higher 32 bits of the timer (in the route table)
 * @return 1 if the timer has expired, 0 otherwise
 * @author Jason Fu * 
 */
int check_timeout(uint32_t time_llimit, uint32_t time_hlimit, uint32_t timer_laddr, uint32_t timer_haddr);

#endif // _TIMER_H_