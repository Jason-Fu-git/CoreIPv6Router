#include <timer.h>
#include <stdint.h>

uint32_t multicast_timer_ldata = 0;

int check_timeout(uint32_t time_llimit, uint32_t timer_ldata)
{
    uint32_t cur_timer_ldata = *((volatile uint32_t *)MTIME_LADDR);

    // Add the time limit to the timer
    uint32_t added_timer_ldata = timer_ldata + time_llimit;

    // Check if the timer has expired
    if (cur_timer_ldata >= added_timer_ldata)
    {
        return 1;
    }
    return 0;
}