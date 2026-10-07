/*
   gen_gpu.c -- update lists for the WRF GPU port (plan.md P1.3).

   Writes into inc/:

     gpu_upd_dev_all.inc    host -> device update of every field allocs.inc allocates
     gpu_upd_host_all.inc   device -> host update of the same fields
     gpu_upd_dev_bdy.inc    host -> device update of the boundary arrays only
     gpu_upd_host_force_slab.inc   device -> host j-slab (js:je) of INTERP_DOWN fields
     gpu_pack_force_strips.inc     nest FORCE_DOWN bdy_interp strip packs
     gpu_upd_dev_force_full.inc    host -> device of other FORCE_DOWN fields (o3rad)

   The three original lists are unchanged. The Phase 5 lists are emitted by
   gen_gpu_force (P5.2): by address through module_gpu_map, never a grid
   component in an OpenACC clause. A j-slab is the contiguous section
   grid%x(:,:,js:je) or (:,js:je), or one index of each dimension after j.

   Each update is a call of the by-address mapping routines of
   WRF/frame/module_gpu_map.F (gpu_map_call below, also used by gen_allocs.c
   for the enter/exit data of P1.2):
     CALL gpu_map_r(grid%u_2, SIZE(grid%u_2,KIND=8), GPU_UPD_TO)

   The walk over the fields is the one of gen_alloc2 (gen_allocs.c): arrays and
   boundary arrays of kind FIELD or FOURD, every time level, the 4D boundary
   arrays (use _4d_bdy_array_), the four boundary arrays of each boundary field
   (bdy_indicator), and the components of derived types.  Each non-boundary
   field is guarded by the same in_use_for_config test that allocs.inc uses, so
   fields allocated as (1,1,1) dummies are not moved.  Boundary arrays are
   allocated unconditionally (IF(.TRUE.) in allocs.inc) and are moved
   unconditionally.  Everything is inside #ifdef WRF_GPU; the files are included
   by WRF/frame/module_gpu_updates.F.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef _WIN32
# include <strings.h>
#endif

#include "protos.h"
#include "registry.h"
#include "data.h"

#define GPU_UPD_ALL 0
#define GPU_UPD_BDY 1

static int gen_gpu1 ( char * dirname , char * fn , char * dir , int which ) ;
static int gen_gpu2 ( FILE * fp , char * structname , char * structname2 , node_t * node , char * dir , int which ) ;
static int gen_gpu_force ( char * dirname ) ;

/* One call of the by-address mapping routines (WRF/frame/module_gpu_map.F)
   for the field structname//fname//suffix of node p.  guard: a Fortran
   condition, or "" for none.  op: GPU_MAP_ENTER, GPU_MAP_EXIT, GPU_UPD_TO or
   GPU_UPD_FROM.  A type without a mapping routine gets a warning and no call. */
int
gpu_map_call ( FILE * fp , char * guard , char * structname , char * fname , char * suffix , node_t * p , char * op )
{
  char t ;
  if ( p == NULL || p->type == NULL ) return(1) ;
  if      ( !strcmp( p->type->name , "real" ) )            t = 'r' ;
  else if ( !strcmp( p->type->name , "doubleprecision" ) ) t = 'd' ;
  else if ( !strcmp( p->type->name , "integer" ) )         t = 'i' ;
  else if ( !strcmp( p->type->name , "logical" ) )         t = 'l' ;
  else {
    fprintf(stderr,"gen_gpu: WARNING no device mapping for %s%s%s (type %s)\n",
            structname, fname, suffix, p->type->name) ;
    return(1) ;
  }
  if ( guard != NULL && strlen(guard) > 0 ) fprintf(fp,"  IF (%s) &\n", guard) ;
  fprintf(fp,"  CALL gpu_map_%c(%s%s%s, &\n    SIZE(%s%s%s,KIND=8), %s)\n",
          t, structname, fname, suffix, structname, fname, suffix, op) ;
  return(0) ;
}

int
gen_gpu ( char * dirname )
{
  if ( gen_gpu1( dirname , "gpu_upd_dev_all.inc"  , "GPU_UPD_TO"   , GPU_UPD_ALL ) ) return(1) ;
  if ( gen_gpu1( dirname , "gpu_upd_host_all.inc" , "GPU_UPD_FROM" , GPU_UPD_ALL ) ) return(1) ;
  if ( gen_gpu1( dirname , "gpu_upd_dev_bdy.inc"  , "GPU_UPD_TO"   , GPU_UPD_BDY ) ) return(1) ;
  if ( gen_gpu_force( dirname ) ) return(1) ;
  return(0) ;
}

static int
gen_gpu1 ( char * dirname , char * fn , char * dir , int which )
{
  FILE * fp ;
  char fname[NAMELEN] ;

  if ( dirname == NULL ) return(1) ;
  if ( strlen(dirname) > 0 ) { sprintf(fname,"%s/%s",dirname,fn) ; }
  else                       { sprintf(fname,"%s",fn) ; }
  if ((fp = fopen( fname , "w" )) == NULL ) return(1) ;
  print_warning(fp,fname) ;
  fprintf(fp,"#ifdef WRF_GPU\n") ;
  gen_gpu2( fp , "grid%" , NULL , &Domain , dir , which ) ;
  fprintf(fp,"#endif\n") ;
  close_the_file( fp ) ;
  return(0) ;
}

static int
gen_gpu2 ( FILE * fp , char * structname , char * structname2 , node_t * node , char * dir , int which )
{
  node_t * p ;
  int tag , bdy ;
  char fname[NAMELEN] , fname2[NAMELEN] ;
  char x[NAMELEN] , x2[NAMELEN] ;

  if ( node == NULL ) return(1) ;

  for ( p = node->fields ; p != NULL ; p = p->next )
  {
    /* the same selection as gen_alloc2 */
    if ( (p->ndims > 0 || p->boundary_array) && (
          (p->node_kind & FIELD) ||
          (p->node_kind & FOURD) )
       )
    {
      for ( tag = 1 ; tag <= p->ntl ; tag++ )
      {
        if ( !strcmp ( p->use , "_4d_bdy_array_") ) {
          strcpy(fname,p->name) ;
        } else {
          strcpy(fname,field_name(t4,p,(p->ntl>1)?tag:0)) ;
        }
        if ( structname2 != NULL ) {
          sprintf(fname2,"%s%s",structname2,fname) ;
        } else {
          strcpy(fname2,fname) ;
        }

        if ( p->boundary_array ) {
          /* allocated unconditionally by allocs.inc */
          if ( sw_new_bdys ) {
            for ( bdy = 1 ; bdy <= 4 ; bdy++ ) {
              gpu_map_call( fp , "" , structname , fname , bdy_indicator(bdy) , p , dir ) ;
            }
          } else {
            gpu_map_call( fp , "" , structname , fname , "" , p , dir ) ;
          }
        } else if ( which == GPU_UPD_ALL ) {
          fprintf(fp,"IF (in_use_for_config(grid%%id,'%s')) THEN\n", fname2 ) ;
          gpu_map_call( fp , "" , structname , fname , "" , p , dir ) ;
          fprintf(fp,"ENDIF\n") ;
        }
      }
    }
    if ( p->type != NULL )
    {
      if ( p->type->type_type == DERIVED )
      {
        sprintf(x,"%s%s%%",structname,p->name ) ;
        sprintf(x2,"%s%%",p->name ) ;
        gen_gpu2( fp , x , x2 , p->type , dir , which ) ;
      }
    }
  }
  return(0) ;
}

/* ---- P5.2 nest-forcing lists (do not change gen_gpu1 / gen_gpu2) ---- */

static int
gpu_open_inc ( char * dirname , char * fn , char * path , FILE ** fp )
{
  if ( strlen(dirname) > 0 ) sprintf(path, "%s/%s", dirname, fn) ;
  else                       sprintf(path, "%s", fn) ;
  *fp = fopen( path , "w" ) ;
  return *fp == NULL ;
}

/* FOURD nest flags live on the members. gen_nest_packunpack reads members->next
   (the header member is the "-" registry line; the next member carries the flags). */
static node_t *
gpu_rep ( node_t * p )
{
  if ( p->node_kind & FOURD ) {
    if ( p->members == NULL ) return NULL ;
    if ( p->members->next ) return p->members->next ;
    return p->members ;
  }
  return p ;
}

static int
gpu_is_bdy_interp ( char * fcn )
{
  return fcn != NULL && strcmp( fcn , "bdy_interp" ) == 0 ;
}

/* j-slab. Dimensions after j are looped one index at a time so the section
   stays contiguous. More than two such dimensions, or no j axis: the whole
   field (still correct; the slab is an optimization). The section is the
   suffix of gpu_map_call, so the call is by address and no OpenACC clause
   names a grid component. */
static void
gpu_emit_slab ( FILE * fp , char * structname , char * fname , char * fname2 , node_t * p )
{
  int ydex, rank, after, d ;
  char sec[256] ;

  rank = p->ndims + ((p->node_kind & FOURD) ? 1 : 0) ;
  ydex = get_index_for_coord( p , COORD_Y ) ;
  after = (ydex < 0) ? 99 : (rank - (ydex + 1)) ;
  fprintf(fp, "IF (in_use_for_config(grid%%id,'%s')) THEN\n", fname2) ;
  if ( ydex < 0 || rank <= 0 || rank > 7 || after > 2 ) {
    gpu_map_call( fp , "" , structname , fname , "" , p , "GPU_UPD_FROM" ) ;
    fprintf(fp, "ENDIF\n") ;
    return ;
  }
  strcpy( sec , "(" ) ;
  for ( d = 0 ; d < rank ; d++ ) {
    if ( d ) strcat( sec , "," ) ;
    if      ( d == ydex )     strcat( sec , "js:je" ) ;
    else if ( d == ydex + 1 ) strcat( sec , "work_p5_force_n" ) ;
    else if ( d == ydex + 2 ) strcat( sec , "work_p5_force_n2" ) ;
    else                      strcat( sec , ":" ) ;
  }
  strcat( sec , ")" ) ;
  if ( after == 2 ) {
    fprintf(fp, "  DO work_p5_force_n2 = 1, SIZE(%s%s,%d)\n", structname, fname, rank) ;
    fprintf(fp, "  DO work_p5_force_n = 1, SIZE(%s%s,%d)\n", structname, fname, ydex + 2) ;
  } else if ( after == 1 ) {
    fprintf(fp, "  DO work_p5_force_n = 1, SIZE(%s%s,%d)\n", structname, fname, ydex + 2) ;
  }
  gpu_map_call( fp , "" , structname , fname , sec , p , "GPU_UPD_FROM" ) ;
  if ( after == 2 )      fprintf(fp, "  ENDDO\n  ENDDO\n") ;
  else if ( after == 1 ) fprintf(fp, "  ENDDO\n") ;
  fprintf(fp, "ENDIF\n") ;
}

/* ikj -> 3, ij -> 2, ikj plus a species dimension -> 4. Anything else is a
   whole-field device-to-host copy (the host still sees every element). */
static int
gpu_layout ( node_t * p )
{
  int x, y, z, spatial ;
  x = get_index_for_coord( p , COORD_X ) ;
  y = get_index_for_coord( p , COORD_Y ) ;
  z = get_index_for_coord( p , COORD_Z ) ;
  spatial = p->ndims ;
  if ( (p->node_kind & FOURD) && spatial == 3 && x == 0 && z == 1 && y == 2 ) return 4 ;
  if ( !(p->node_kind & FOURD) && spatial == 3 && x == 0 && z == 1 && y == 2 ) return 3 ;
  if ( !(p->node_kind & FOURD) && spatial == 2 && x == 0 && y == 1 && z < 0 ) return 2 ;
  return 0 ;
}

static void
gpu_emit_pack_call ( FILE * fp , char * sub , char * structname , char * fname , int rank )
{
  int d ;
  fprintf(fp, "  CALL %s(%s%s", sub, structname, fname) ;
  for ( d = 1 ; d <= rank ; d++ ) {
    fprintf(fp, ", &\n    LBOUND(%s%s,%d), UBOUND(%s%s,%d)", structname, fname, d, structname, fname, d) ;
  }
  fprintf(fp, ", &\n    work_p5_force_iw0, work_p5_force_iw1, &\n") ;
  fprintf(fp, "    work_p5_force_ie0, work_p5_force_ie1, &\n") ;
  fprintf(fp, "    work_p5_force_js0, work_p5_force_js1, &\n") ;
  fprintf(fp, "    work_p5_force_jn0, work_p5_force_jn1)\n") ;
}

static void
gpu_emit_pack ( FILE * fp , char * structname , char * fname , char * fname2 , node_t * p )
{
  int layout, rank ;
  char * sub ;
  int real_field ;
  layout = gpu_layout( p ) ;
  rank = p->ndims + ((p->node_kind & FOURD) ? 1 : 0) ;
  real_field = (p->type != NULL && !strcmp( p->type->name , "real" )) ;
  fprintf(fp, "IF (in_use_for_config(grid%%id,'%s')) THEN\n", fname2) ;
  if ( real_field && layout == 2 ) sub = "med_force_domain_gpu_pack2" ;
  else if ( real_field && layout == 3 ) sub = "med_force_domain_gpu_pack3" ;
  else if ( real_field && layout == 4 ) sub = "med_force_domain_gpu_pack4" ;
  else sub = NULL ;
  if ( sub ) gpu_emit_pack_call( fp , sub , structname , fname , rank ) ;
  else       gpu_map_call( fp , "" , structname , fname , "" , p , "GPU_UPD_FROM" ) ;
  fprintf(fp, "ENDIF\n") ;
}

static void
gpu_force_walk ( FILE * slab , FILE * pack , FILE * full ,
                 char * structname , char * structname2 , node_t * node )
{
  node_t * p ;
  char x[NAMELEN] , x2[NAMELEN] ;

  if ( node == NULL ) return ;
  for ( p = node->fields ; p != NULL ; p = p->next )
  {
    if ( !p->boundary_array && p->ndims > 0 && !p->scalar_array_member &&
         ( (p->node_kind & FIELD) || (p->node_kind & FOURD) ) )
    {
      node_t * rep = gpu_rep( p ) ;
      char fname[NAMELEN] , fname2[NAMELEN] ;
      int tag ;
      if ( rep != NULL ) {
        /* Same time level the nest pack visits: _2 when that node has more
           than one time level, otherwise the unsuffixed name. */
        tag = (rep->ntl > 1) ? 2 : 0 ;
        field_name( fname , p , tag ) ;
        if ( structname2 != NULL )
          sprintf( fname2 , "%s%s" , structname2 , fname ) ;
        else
          strcpy( fname2 , fname ) ;
        if ( rep->nest_mask & INTERP_DOWN )
          gpu_emit_slab( slab , structname , fname , fname2 , p ) ;
        if ( rep->nest_mask & FORCE_DOWN ) {
          if ( gpu_is_bdy_interp( rep->force_fcn_name ) )
            gpu_emit_pack( pack , structname , fname , fname2 , p ) ;
          else {
            fprintf(full, "IF (in_use_for_config(grid%%id,'%s')) THEN\n", fname2) ;
            gpu_map_call( full , "" , structname , fname , "" , p , "GPU_UPD_TO" ) ;
            fprintf(full, "ENDIF\n") ;
          }
        }
      }
    }
    if ( p->type != NULL && p->type->type_type == DERIVED )
    {
      sprintf( x  , "%s%s%%" , structname , p->name ) ;
      sprintf( x2 , "%s%%" , p->name ) ;
      gpu_force_walk( slab , pack , full , x , x2 , p->type ) ;
    }
  }
}

static int
gen_gpu_force ( char * dirname )
{
  FILE * slab , * pack , * full ;
  char fs[NAMELEN] , fpac[NAMELEN] , ff[NAMELEN] ;

  if ( dirname == NULL ) return(1) ;
  if ( gpu_open_inc( dirname , "gpu_upd_host_force_slab.inc" , fs , &slab ) ) return(1) ;
  if ( gpu_open_inc( dirname , "gpu_pack_force_strips.inc" , fpac , &pack ) ) {
    fclose( slab ) ; return(1) ;
  }
  if ( gpu_open_inc( dirname , "gpu_upd_dev_force_full.inc" , ff , &full ) ) {
    fclose( slab ) ; fclose( pack ) ; return(1) ;
  }
  print_warning( slab , fs ) ;
  print_warning( pack , fpac ) ;
  print_warning( full , ff ) ;
  fprintf( slab , "#ifdef WRF_GPU\n" ) ;
  fprintf( pack , "#ifdef WRF_GPU\n" ) ;
  fprintf( full , "#ifdef WRF_GPU\n" ) ;
  fprintf( slab , "! INTERP_DOWN j-slab. Caller sets js, je, work_p5_force_n and work_p5_force_n2.\n" ) ;
  fprintf( pack , "! FORCE_DOWN bdy_interp strips. Caller sets work_p5_force_iw0 through work_p5_force_jn1.\n" ) ;
  fprintf( full , "! FORCE_DOWN fields whose force function is not bdy_interp. Host to device.\n" ) ;
  gpu_force_walk( slab , pack , full , "grid%" , NULL , &Domain ) ;
  fprintf( slab , "#endif\n" ) ;
  fprintf( pack , "#endif\n" ) ;
  fprintf( full , "#endif\n" ) ;
  close_the_file( slab ) ;
  close_the_file( pack ) ;
  close_the_file( full ) ;
  return(0) ;
}
