
#include <sys/stat.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

/************************************************************************
 * Support for atomic operations
 ************************************************************************/

bool gnatcoll_sync_bool_compare_and_swap_access
  (void** ptr, void* oldval, void* newval)
{
   return __sync_bool_compare_and_swap(ptr, oldval, newval);
}



