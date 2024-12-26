#include <timer.h>
#include <stdint.h>

uint32_t multicast_timer_ldata = 0;
uint32_t multicast_timer_hdata = 0;

int check_timeout(uint32_t time_llimit, uint32_t time_hlimit, uint32_t timer_laddr, uint32_t timer_haddr)
{
    uint32_t timer_ldata = *((volatile uint32_t *)timer_laddr);
    uint32_t timer_hdata = *((volatile uint32_t *)timer_haddr);
    uint32_t cur_timer_ldata = *((volatile uint32_t *)MTIME_LADDR);
    uint32_t cur_timer_hdata = *((volatile uint32_t *)MTIME_HADDR);

    // Add the time limit to the timer
    uint32_t added_timer_ldata = timer_ldata + time_llimit;
    uint32_t added_timer_hdata = timer_hdata + time_hlimit;
    if (added_timer_ldata < timer_ldata)
    {
        added_timer_hdata++;
    }

    // Check if the timer has expired
    if (cur_timer_hdata > added_timer_hdata || (cur_timer_hdata == added_timer_hdata && cur_timer_ldata >= added_timer_ldata))
    {
        return 1;
    }
    return 0;
}