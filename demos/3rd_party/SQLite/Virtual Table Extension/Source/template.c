/*
** 2025-06-26
**
** www.steema.com
**
**
*************************************************************************
**
** This file implements a TeeBI virtual-table for SQLite.
*/
#if !defined(SQLITEINT_H)
#include "sqlite3ext.h"
#endif
SQLITE_EXTENSION_INIT1
#include <string.h>
#include <assert.h>

/* bi_tab_vtab is a subclass of sqlite3_vtab which is
** underlying representation of the virtual table
*/
typedef struct bi_tab_vtab bi_tab_vtab;
struct bi_tab_vtab {
  sqlite3_vtab base;  /* Base class - must be first */
  /* Add new fields here, as necessary */
};

/* bi_tab_cursor is a subclass of sqlite3_vtab_cursor which will
** serve as the underlying representation of a cursor that scans
** over rows of the result
*/
typedef struct bi_tab_cursor bi_tab_cursor;
struct bi_tab_cursor {
  sqlite3_vtab_cursor base;  /* Base class - must be first */
  /* Insert new fields here.  For this bi_tab we only keep track
  ** of the rowid */
  sqlite3_int64 iRowid;      /* The rowid */
};

/*
** The bi_tabConnect() method is invoked to create a new
** template virtual table.
**
** Think of this routine as the constructor for bi_tab_vtab objects.
**
** All this routine needs to do is:
**
**    (1) Allocate the bi_tab_vtab object and initialize all fields.
**
**    (2) Tell SQLite (via the sqlite3_declare_vtab() interface) what the
**        result set of queries against the virtual table will look like.
*/
static int bi_tabConnect(
  sqlite3 *db,
  void *pAux,
  int argc, const char *const*argv,
  sqlite3_vtab **ppVtab,
  char **pzErr
){
  bi_tab_vtab *pNew;
  int rc;

  rc = sqlite3_declare_vtab(db,
           "CREATE TABLE x(a,b)"
       );
  /* For convenience, define symbolic names for the index to each column. */
#define bi_tab_A  0
#define bi_tab_B  1
  if( rc==SQLITE_OK ){
    pNew = sqlite3_malloc( sizeof(*pNew) );
    *ppVtab = (sqlite3_vtab*)pNew;
    if( pNew==0 ) return SQLITE_NOMEM;
    memset(pNew, 0, sizeof(*pNew));
  }
  return rc;
}

/*
** This method is the destructor for bi_tab_vtab objects.
*/
static int bi_tabDisconnect(sqlite3_vtab *pVtab){
  bi_tab_vtab *p = (bi_tab_vtab*)pVtab;
  sqlite3_free(p);
  return SQLITE_OK;
}

/*
** Constructor for a new bi_tab_cursor object.
*/
static int bi_tabOpen(sqlite3_vtab *p, sqlite3_vtab_cursor **ppCursor){
  bi_tab_cursor *pCur;
  pCur = sqlite3_malloc( sizeof(*pCur) );
  if( pCur==0 ) return SQLITE_NOMEM;
  memset(pCur, 0, sizeof(*pCur));
  *ppCursor = &pCur->base;
  return SQLITE_OK;
}

/*
** Destructor for a bi_tab_cursor.
*/
static int bi_tabClose(sqlite3_vtab_cursor *cur){
  bi_tab_cursor *pCur = (bi_tab_cursor*)cur;
  sqlite3_free(pCur);
  return SQLITE_OK;
}


/*
** Advance a bi_tab_cursor to its next row of output.
*/
static int bi_tabNext(sqlite3_vtab_cursor *cur){
  bi_tab_cursor *pCur = (bi_tab_cursor*)cur;
  pCur->iRowid++;
  return SQLITE_OK;
}

/*
** Return values of columns for the row at which the bi_tab_cursor
** is currently pointing.
*/
static int bi_tabColumn(
  sqlite3_vtab_cursor *cur,   /* The cursor */
  sqlite3_context *ctx,       /* First argument to sqlite3_result_...() */
  int i                       /* Which column to return */
){
  bi_tab_cursor *pCur = (bi_tab_cursor*)cur;
  switch( i ){
    case bi_tab_A:
      sqlite3_result_int(ctx, 1000 + pCur->iRowid);
      break;
    default:
      assert( i==bi_tab_B );
      sqlite3_result_int(ctx, 2000 + pCur->iRowid);
      break;
  }
  return SQLITE_OK;
}

/*
** Return the rowid for the current row.  In this implementation, the
** rowid is the same as the output value.
*/
static int bi_tabRowid(sqlite3_vtab_cursor *cur, sqlite_int64 *pRowid){
  bi_tab_cursor *pCur = (bi_tab_cursor*)cur;
  *pRowid = pCur->iRowid;
  return SQLITE_OK;
}

/*
** Return TRUE if the cursor has been moved off of the last
** row of output.
*/
static int bi_tabEof(sqlite3_vtab_cursor *cur){
  bi_tab_cursor *pCur = (bi_tab_cursor*)cur;
  return pCur->iRowid>=10;
}

/*
** This method is called to "rewind" the bi_tab_cursor object back
** to the first row of output.  This method is always called at least
** once prior to any call to bi_tabColumn() or bi_tabRowid() or 
** bi_tabEof().
*/
static int bi_tabFilter(
  sqlite3_vtab_cursor *pVtabCursor, 
  int idxNum, const char *idxStr,
  int argc, sqlite3_value **argv
){
  bi_tab_cursor *pCur = (bi_tab_cursor *)pVtabCursor;
  pCur->iRowid = 1;
  return SQLITE_OK;
}

/*
** SQLite will invoke this method one or more times while planning a query
** that uses the virtual table.  This routine needs to create
** a query plan for each invocation and compute an estimated cost for that
** plan.
*/
static int bi_tabBestIndex(
  sqlite3_vtab *tab,
  sqlite3_index_info *pIdxInfo
){
  pIdxInfo->estimatedCost = (double)10;
  pIdxInfo->estimatedRows = 10;
  return SQLITE_OK;
}

/*
** This following structure defines all the methods for the 
** virtual table.
*/
static sqlite3_module bi_tabModule = {
  /* iVersion    */ 0,
  /* xCreate     */ 0,
  /* xConnect    */ bi_tabConnect,
  /* xBestIndex  */ bi_tabBestIndex,
  /* xDisconnect */ bi_tabDisconnect,
  /* xDestroy    */ 0,
  /* xOpen       */ bi_tabOpen,
  /* xClose      */ bi_tabClose,
  /* xFilter     */ bi_tabFilter,
  /* xNext       */ bi_tabNext,
  /* xEof        */ bi_tabEof,
  /* xColumn     */ bi_tabColumn,
  /* xRowid      */ bi_tabRowid,
  /* xUpdate     */ 0,
  /* xBegin      */ 0,
  /* xSync       */ 0,
  /* xCommit     */ 0,
  /* xRollback   */ 0,
  /* xFindMethod */ 0,
  /* xRename     */ 0,
  /* xSavepoint  */ 0,
  /* xRelease    */ 0,
  /* xRollbackTo */ 0,
  /* xShadowName */ 0,
  /* xIntegrity  */ 0
};


#ifdef _WIN32
__declspec(dllexport)
#endif
int sqlite3_bi_tab_init(
  sqlite3 *db, 
  char **pzErrMsg, 
  const sqlite3_api_routines *pApi
){
  int rc = SQLITE_OK;
  SQLITE_EXTENSION_INIT2(pApi);
  rc = sqlite3_create_module(db, "bi_tab", &bi_tabModule, 0);
  return rc;
}

