/* usage in lua:  
*   first  modify config file , LUA_CPATH include msgserver/luaclib/?.so 
*   second lua xx = require "timestamp"
*   third init begin, make it zero begin.  xx.Init
*   end judge use xx.GetTimestamp()
*   creator: zhangyanlei zhangyl
*	date: 2016/4/29 10:07
*   file from:  trycompetition/server/cpp/CxxUtils/inc/timestamp.h
*/
#include <limits.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <time.h>
#include <stdio.h>

inline	unsigned long	GetTickCount()
{
	struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (ts.tv_sec * 1000 + ts.tv_nsec / 1000000);
}

static 	unsigned long		tickcount_begin_ = 0;	
static	unsigned long		tickcount_last_ = 0;
	
static	double				timestamp_begin_ = 0.0;
static 	double				timestamp_ 		 = 0.0;
	
int  lInit(lua_State *L)
{	
	tickcount_begin_ = GetTickCount();	
	tickcount_last_ = tickcount_begin_;
	return 0;
}

int lGetTimestamp(lua_State *L)
{	
	unsigned long	dwTickCount	= GetTickCount();

	if(dwTickCount == tickcount_last_)
	{
		lua_pushnumber(L, timestamp_);
		return 1;
	}

	if(dwTickCount > tickcount_begin_)
	{
		timestamp_	= timestamp_begin_ + (dwTickCount -	tickcount_begin_) /	1000.0;
		if(dwTickCount >= tickcount_begin_ + 24	* 60 * 60 *	1000)
		{
			timestamp_begin_	= timestamp_;
			tickcount_begin_	= dwTickCount;
		}
	}
	else
	{
		timestamp_		= timestamp_begin_ + (UINT_MAX - tickcount_begin_ +	dwTickCount) / 1000.0f;

		timestamp_begin_	= timestamp_;
		tickcount_begin_	= dwTickCount;
	}

	tickcount_last_	= dwTickCount;
	lua_pushnumber(L, timestamp_);
	return 1;
}

int
luaopen_timestamp(lua_State *L) {
        // luaL_checkversion(L);
        luaL_Reg l[] = {
				{"Init", lInit},
				{"GetTimestamp", lGetTimestamp},
				{NULL, NULL}
        };
        // luaL_newlib(L,l);
        // const char* libName = "timestamp";
        // luaL_register(L, libName, l);
        // lua version less 5.2(included),please using follow functions. 
        lua_newtable(L);
  		luaL_setfuncs(L, l, 0); 
        return 1;
}