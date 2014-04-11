#include <stdio.h>
#include <sys/time.h>
#include <uuid/uuid.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <curses.h>


#pragma mark - macros

#ifndef CUTIL_MODNAME
#define CUTIL_MODNAME   "cutil"
#endif

#ifndef CUTIL_VERSION
#define CUTIL_VERSION   "0.1"
#endif


#pragma mark - interfaces

static int util_timestamp(lua_State *l) {
    struct timeval  val;
    lua_Number      lval;

    gettimeofday(&val, NULL);
    lval = 1e-6 * val.tv_usec + val.tv_sec;

    lua_pushnumber(l, lval);
    return 1;
}

static int util_uuid(lua_State *l) {
    uuid_t uu;
    char str[37];

    uuid_generate(uu);
    uuid_unparse(uu, str);

    lua_pushstring(l, str);
    return 1;
}

static int util_getchar(lua_State *l) {
    char c = getchar();

    lua_pushlstring(l, &c, 1);

    return 1;
}


#pragma mark - libcurses extentions

static const char *WINDOWMETA          = "curses:window";

#define B(v) ((((int) (v)) == ERR))


static WINDOW **lcw_get(lua_State *l, int offset)
{
    WINDOW **w = (WINDOW**)luaL_checkudata(l, offset, WINDOWMETA);
    if (w == NULL) luaL_argerror(l, offset, "bad curses window");
    return w;
}

static WINDOW *lcw_check(lua_State *l, int offset)
{
    WINDOW **w = lcw_get(l, offset);
    if (*w == NULL) luaL_argerror(l, offset, "attempt to use closed curses window");
    return *w;
}

static int util_wresize(lua_State *l) {
    WINDOW *w = lcw_check(l, 1);
    int lines = luaL_checkint(l, 2);
    int cols  = luaL_checkint(l, 3);
    lua_pushboolean(l, B(wresize(w, lines, cols)));
    return 1;
}


#pragma mark - lib method

static const struct luaL_reg cutil[] = {
    {"timestamp",       util_timestamp},
    {"uuid",            util_uuid},
    {"getchar",         util_getchar},
    {"wresize",         util_wresize},
    {NULL,              NULL}
};

int luaopen_cutil(lua_State *l) {
    luaL_openlib(l, CUTIL_MODNAME, cutil, 0);
    return 1;
}

