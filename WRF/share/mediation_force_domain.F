!
!WRF:MEDIATION_LAYER:NESTING
!
SUBROUTINE med_force_domain ( parent_grid , nested_grid )
   USE module_domain
   USE module_configure
#ifdef DM_PARALLEL
   USE module_dm, ONLY : intercomm_active, &
                         mpi_comm_to_kid, mpi_comm_to_mom, which_kid
#else
   USE module_dm, ONLY : intercomm_active
#endif
#ifdef WRF_GPU
   USE module_gpu_route, ONLY : gpu_on, R_COUPLE_OR_UNCOUPLE_EM
   USE module_gpu_updates, ONLY : gpu_upd_dev_bdy
#endif

   IMPLICIT NONE
   TYPE(domain), POINTER :: parent_grid , nested_grid
   TYPE(domain), POINTER :: grid
   INTEGER nlev, msize
#if !defined(MAC_KLUDGE)
   TYPE (grid_config_rec_type)            :: config_flags
#endif

! ----------------------------------------------------------
! ------------------------------------------------------
! Interface blocks
! ------------------------------------------------------
   INTERFACE
! ------------------------------------------------------
!    Interface definitions for EM CORE
! ------------------------------------------------------
#if (EM_CORE == 1)
#if !defined(MAC_KLUDGE)
! ------------------------------------------------------
!    These routines are supplied by module_dm.F from the
!    external communication package (e.g. external/RSL)
! ------------------------------------------------------
      SUBROUTINE interp_domain_em_part1 ( grid, intermediate_grid, ngrid, config_flags   &
!
#        include "dummy_new_args.inc"
!
                 )
         USE module_domain
         USE module_configure
         TYPE(domain), POINTER :: grid          ! name of the grid being dereferenced (must be "grid")
         TYPE(domain), POINTER :: intermediate_grid
         TYPE(domain), POINTER :: ngrid
         TYPE (grid_config_rec_type)            :: config_flags
#        include "dummy_new_decl.inc"
      END SUBROUTINE interp_domain_em_part1

      SUBROUTINE force_domain_em_part2 ( grid, nested_grid, parent_grid, config_flags   &
!
#        include "dummy_new_args.inc"
!
                 )
         USE module_domain
         USE module_configure
         TYPE(domain), POINTER :: grid          ! name of the grid being dereferenced (must be "grid")
         TYPE(domain), POINTER :: nested_grid
	 TYPE(domain), POINTER :: parent_grid   ! KAL added for vertical nesting
         TYPE (grid_config_rec_type)            :: config_flags
#        include "dummy_new_decl.inc"
      END SUBROUTINE force_domain_em_part2

! ----------------------------------------------------------
!    This routine is supplied by dyn_em/couple_or_uncouple_em.F
! ----------------------------------------------------------
      SUBROUTINE couple_or_uncouple_em ( grid, config_flags , couple  &
!
#        include "dummy_new_args.inc"
!
                 )
         USE module_domain
         USE module_configure
         TYPE(domain), INTENT(INOUT)            :: grid
         TYPE (grid_config_rec_type)            :: config_flags
         LOGICAL, INTENT(   IN) :: couple
#        include "dummy_new_decl.inc"
      END SUBROUTINE couple_or_uncouple_em
#endif
#endif
   END INTERFACE
! ----------------------------------------------------------
! End of Interface blocks
! ----------------------------------------------------------
! ----------------------------------------------------------
! ----------------------------------------------------------
! Executable code
! ----------------------------------------------------------
! ----------------------------------------------------------
!    Forcing calls for EM CORE.
! ----------------------------------------------------------
#if (EM_CORE == 1 && defined( DM_PARALLEL ))
# if !defined(MAC_KLUDGE)
   CALL model_to_grid_config_rec ( nested_grid%id , model_config_rec , config_flags )

   grid => nested_grid%intermediate_grid
#  if (defined(MOVE_NESTS) || ((!defined(KEEP_INT_AROUND)) && (!defined(SGIALTIX)) && (!defined(FUJITSU_FX10))))
!   IF ( intercomm_active(grid%id) ) THEN
     CALL alloc_space_field ( grid, grid%id , 1 , 2 ,  .TRUE. , intercomm_active(grid%id),    &
                            grid%sd31, grid%ed31, grid%sd32, grid%ed32, grid%sd33, grid%ed33, &
                            grid%sm31,  grid%em31,  grid%sm32,  grid%em32,  grid%sm33,  grid%em33, &
                            grid%sp31,  grid%ep31,  grid%sp32,  grid%ep32,  grid%sp33,  grid%ep33, &
                            grid%sp31x, grid%ep31x, grid%sp32x, grid%ep32x, grid%sp33x, grid%ep33x,&
                            grid%sp31y, grid%ep31y, grid%sp32y, grid%ep32y, grid%sp33y, grid%ep33y,&
                            grid%sm31x, grid%em31x, grid%sm32x, grid%em32x, grid%sm33x, grid%em33x, &   ! x-xpose
                            grid%sm31y, grid%em31y, grid%sm32y, grid%em32y, grid%sm33y, grid%em33y  &   ! y-xpose
     )
!   ENDIF
#  endif

   ! couple parent domain
   grid => parent_grid
   IF ( grid%active_this_task ) THEN
     CALL push_communicators_for_domain(grid%id)
   ! swich config_flags to point to parent rconfig info
     CALL model_to_grid_config_rec ( grid%id , model_config_rec , config_flags )
     CALL couple_or_uncouple_em ( grid , config_flags ,  .true. &
!
#         include "actual_new_args.inc"
!
                                )
     CALL pop_communicators_for_domain
   ENDIF
   ! couple nested domain
   grid => nested_grid
   IF ( grid%active_this_task ) THEN
     CALL push_communicators_for_domain(grid%id)
     CALL model_to_grid_config_rec ( grid%id , model_config_rec , config_flags )
     CALL couple_or_uncouple_em ( grid , config_flags ,  .true. &
!
#         include "actual_new_args.inc"
!
                                   )
     CALL pop_communicators_for_domain
   ENDIF
   ! perform first part: transfer data from parent to intermediate domain
   ! at the same resolution but on the same decomposition as the nest
   ! note that this will involve communication on multiple DM procs
   grid => parent_grid
   CALL model_to_grid_config_rec ( grid%id , model_config_rec , config_flags )
   !
   ! Added following line to handle adaptive time step.  This should probably
   !   go somewhere else, but I'm not sure where.
   !   
   ! T. Hutchinson, WSI  1/23/07
   !

   IF ( parent_grid%active_this_task .AND. nested_grid%active_this_task ) THEN
     nested_grid%intermediate_grid%dt = grid%dt
   ENDIF
   IF ( parent_grid%active_this_task ) THEN
     CALL BYTE_BCAST( parent_grid%dt,RWORDSIZE,mpi_comm_to_kid( which_kid( nested_grid%id ) , parent_grid%id ))
   ELSE IF ( nested_grid%active_this_task ) THEN
     CALL BYTE_BCAST( nested_grid%dt,RWORDSIZE,mpi_comm_to_mom( nested_grid%id ) )
   ENDIF

   IF ( parent_grid%active_this_task .OR. nested_grid%active_this_task ) THEN
     CALL wrf_dm_nestexchange_init

#ifdef WRF_GPU
     ! P5.2 step 3: parent INTERP_DOWN j-slab. Rows are those the pack loop
     ! visits (rsl_bcast.c 258-260, module_dm.F 4296-4303). Step 2 is the
     ! couple calls above; on the device when this route is on (P5-CPL).
     IF (gpu_on(R_COUPLE_OR_UNCOUPLE_EM) .AND. parent_grid%active_this_task) THEN
       CALL med_force_domain_gpu_parent_slab(parent_grid, nested_grid%intermediate_grid)
     ENDIF
#endif
     CALL interp_domain_em_part1 ( grid , nested_grid%intermediate_grid, nested_grid, config_flags  &
!
#         include "actual_new_args.inc"
!
                                    )
   ENDIF

  IF ( nested_grid%active_this_task ) THEN
   grid => nested_grid%intermediate_grid
      ! perform 2nd part: run interpolation on the intermediate domain
      ! and compute the values for the nest boundaries
      ! note that this is all local (no communication)
   CALL model_to_grid_config_rec ( nested_grid%id , model_config_rec , config_flags )
#ifdef WRF_GPU
   ! P5.2 step 4: nest FORCE_DOWN spec-zone strips, device to host, before
   ! the host interpolation reads them. Step 5 is the host calls themselves.
   IF (gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) THEN
     CALL med_force_domain_gpu_nest_strips(nested_grid)
   ENDIF
#endif
   CALL force_domain_em_part2 ( grid, nested_grid, parent_grid, config_flags   &
!
#          include "actual_new_args.inc"
!
                                   )
#ifdef WRF_GPU
   ! P5.2 step 6: nest boundary arrays and the non-bdy_interp FORCE_DOWN
   ! fields (o3rad via p2c in this configuration). Step 7 is the uncouple
   ! below. When the route is off, S6 moves the whole state (I-11).
   IF (gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) THEN
     CALL gpu_upd_dev_bdy(nested_grid)
     CALL med_force_domain_gpu_upd_dev_full(nested_grid)
   ENDIF
#endif
  ENDIF
   ! uncouple the nest
   grid => nested_grid
   IF ( grid%active_this_task ) THEN
     CALL push_communicators_for_domain(grid%id)
     CALL model_to_grid_config_rec ( grid%id , model_config_rec , config_flags )
     CALL couple_or_uncouple_em ( grid , config_flags ,  .false.  &
!
#          include "actual_new_args.inc"
!
                                   )
     CALL pop_communicators_for_domain
   ENDIF
   ! uncouple the parent
   grid => parent_grid
   IF ( grid%active_this_task ) THEN
     CALL push_communicators_for_domain(grid%id)
     CALL model_to_grid_config_rec ( grid%id , model_config_rec , config_flags )
     CALL couple_or_uncouple_em ( grid , config_flags ,  .false.  &
!
#          include "actual_new_args.inc"
!
                                )
     CALL pop_communicators_for_domain
   ENDIF
   IF ( nested_grid%first_force ) THEN
      nested_grid%first_force = .FALSE.
   ENDIF
   nested_grid%dtbc = 0.
!
   grid => nested_grid%intermediate_grid
#  if (defined(MOVE_NESTS) || ((!defined(KEEP_INT_AROUND)) && (!defined(SGIALTIX)) && (!defined(FUJITSU_FX10))))
   IF ( intercomm_active(grid%id) ) THEN
     CALL dealloc_space_field ( grid )
   ENDIF
#  endif
# endif
#endif
! ------------------------------------------------------
!    End of Forcing calls for EM CORE.
! ------------------------------------------------------
   RETURN
END SUBROUTINE med_force_domain

#ifdef WRF_GPU
! P5.2 steps 3, 4 and 6. The generated lists are included here (module_gpu_updates
! belongs to P1-SYNC). OpenACC clauses name dummy arguments or the buffer, never
! a grid component. Slab rows: jcoord = j_parent_start(intermediate) - shw and
! jdim_cd = ijde - ijds + 1, then js = max(cjps, jcoord), je = min(cjpe,
! jcoord + jdim_cd - 1), the same calls as module_dm.F interp_domain_em_part1.

SUBROUTINE med_force_domain_gpu_parent_slab(grid, inter)
   USE module_domain, ONLY : domain, get_ijk_from_grid
   USE module_configure
   USE module_gpu_map
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
   TYPE(domain), INTENT(IN)    :: inter
   INTEGER :: cids, cide, cjds, cjde, ckds, ckde
   INTEGER :: cims, cime, cjms, cjme, ckms, ckme
   INTEGER :: cips, cipe, cjps, cjpe, ckps, ckpe
   INTEGER :: iids, iide, ijds, ijde, ikds, ikde
   INTEGER :: iims, iime, ijms, ijme, ikms, ikme
   INTEGER :: iips, iipe, ijps, ijpe, ikps, ikpe
   INTEGER :: jparstrt, sw, jcoord, jdim_cd, js, je
   INTEGER :: work_p5_force_n, work_p5_force_n2
   IF (grid%is_intermediate) RETURN
   work_p5_force_n = 0
   work_p5_force_n2 = 0
   CALL get_ijk_from_grid(grid,                              &
        cids, cide, cjds, cjde, ckds, ckde,                  &
        cims, cime, cjms, cjme, ckms, ckme,                  &
        cips, cipe, cjps, cjpe, ckps, ckpe)
   CALL get_ijk_from_grid(inter,                             &
        iids, iide, ijds, ijde, ikds, ikde,                  &
        iims, iime, ijms, ijme, ikms, ikme,                  &
        iips, iipe, ijps, ijpe, ikps, ikpe)
   CALL nl_get_j_parent_start(inter%id, jparstrt)
   CALL nl_get_shw(inter%id, sw)
   jcoord = jparstrt - sw
   jdim_cd = ijde - ijds + 1
   js = MAX(cjps, jcoord)
   je = MIN(cjpe, jcoord + jdim_cd - 1)
   IF (js <= je) THEN
#include "gpu_upd_host_force_slab.inc"
   ENDIF
END SUBROUTINE med_force_domain_gpu_parent_slab

SUBROUTINE med_force_domain_gpu_nest_strips(grid)
   USE module_domain, ONLY : domain, get_ijk_from_grid
   USE module_configure
   USE module_gpu_map
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
   INTEGER :: ids, ide, jds, jde, kds, kde
   INTEGER :: ims, ime, jms, jme, kms, kme
   INTEGER :: ips, ipe, jps, jpe, kps, kpe
   INTEGER :: spec_zone, relax_zone, spec_bdy_width, sz, swid
   INTEGER :: work_p5_force_iw0, work_p5_force_iw1
   INTEGER :: work_p5_force_ie0, work_p5_force_ie1
   INTEGER :: work_p5_force_js0, work_p5_force_js1
   INTEGER :: work_p5_force_jn0, work_p5_force_jn1
   IF (grid%is_intermediate) RETURN
   CALL get_ijk_from_grid(grid,                              &
        ids, ide, jds, jde, kds, kde,                        &
        ims, ime, jms, jme, kms, kme,                        &
        ips, ipe, jps, jpe, kps, kpe)
   ! Same sz as bdy_interp, plus one column for the staggered edge index.
   CALL nl_get_spec_zone(1, spec_zone)
   CALL nl_get_relax_zone(1, relax_zone)
   CALL nl_get_spec_bdy_width(1, spec_bdy_width)
   sz = MIN(MAX(spec_zone, relax_zone + 1), spec_bdy_width)
   swid = sz + 1
   work_p5_force_iw0 = ids
   work_p5_force_iw1 = ids + swid - 1
   work_p5_force_ie1 = ide
   work_p5_force_ie0 = ide - swid + 1
   work_p5_force_js0 = jds
   work_p5_force_js1 = jds + swid - 1
   work_p5_force_jn1 = jde
   work_p5_force_jn0 = jde - swid + 1
#include "gpu_pack_force_strips.inc"
END SUBROUTINE med_force_domain_gpu_nest_strips

SUBROUTINE med_force_domain_gpu_upd_dev_full(grid)
   USE module_domain, ONLY : domain
   USE module_configure, ONLY : in_use_for_config
   USE module_gpu_map
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
   IF (grid%is_intermediate) RETURN
#include "gpu_upd_dev_force_full.inc"
END SUBROUTINE med_force_domain_gpu_upd_dev_full

! K-NEST-STRIP-PACK: four edge strips into one buffer, then one device-to-host
! copy (plan.md P5.2 step 4). Strip bounds are domain indices; each routine
! clamps them to the field. A point is inside a strip when its i is in the
! west or east run or its j is in the south or north run, at every k.
! island of R_COUPLE_OR_UNCOUPLE_EM in med_force_domain

SUBROUTINE med_force_domain_gpu_pack3(a, ims, ime, kms, kme, jms, jme, &
     iw0, iw1, ie0, ie1, js0, js1, jn0, jn1)
   USE module_gpu_route, ONLY : gpu_on, R_COUPLE_OR_UNCOUPLE_EM
   USE module_gpu_map
   IMPLICIT NONE
   INTEGER, INTENT(IN) :: ims, ime, kms, kme, jms, jme
   INTEGER, INTENT(IN) :: iw0, iw1, ie0, ie1, js0, js1, jn0, jn1
   REAL, INTENT(INOUT) :: a(ims:ime, kms:kme, jms:jme)
   INTEGER :: iw0c, iw1c, ie0c, ie1c, js0c, js1c, jn0c, jn1c
   INTEGER :: n_south, n_north, n_west, n_east, nbuf
   INTEGER :: base_s, base_n, base_w, base_e
   INTEGER :: i, k, j, ierr
   REAL, ALLOCATABLE :: buf(:)
   iw0c = MAX(ims, iw0)
   iw1c = MIN(ime, iw1)
   ie0c = MAX(ims, ie0)
   ie1c = MIN(ime, ie1)
   js0c = MAX(jms, js0)
   js1c = MIN(jme, js1)
   jn0c = MAX(jms, jn0)
   jn1c = MIN(jme, jn1)
   n_south = 0
   n_north = 0
   n_west = 0
   n_east = 0
   IF (js0c <= js1c) n_south = (ime - ims + 1) * (kme - kms + 1) * (js1c - js0c + 1)
   IF (jn0c <= jn1c) n_north = (ime - ims + 1) * (kme - kms + 1) * (jn1c - jn0c + 1)
   IF (iw0c <= iw1c) n_west = (iw1c - iw0c + 1) * (kme - kms + 1) * (jme - jms + 1)
   IF (ie0c <= ie1c) n_east = (ie1c - ie0c + 1) * (kme - kms + 1) * (jme - jms + 1)
   nbuf = n_south + n_north + n_west + n_east
   IF (nbuf <= 0) RETURN
   ALLOCATE(buf(nbuf), STAT=ierr)
   IF (ierr /= 0) THEN
      CALL wrf_error_fatal("med_force_domain_gpu_pack3: strip buffer allocate failed")
   ENDIF
   base_s = 1
   base_n = base_s + n_south
   base_w = base_n + n_north
   base_e = base_w + n_west
!$acc enter data create(buf)
   IF (js0c <= js1c) THEN
! K-NEST-STRIP-PACK: south strip (Template G)
!$acc parallel loop gang vector collapse(3) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, ime, kms, kme, jms, js0c, js1c, base_s)
      DO j = js0c, js1c
         DO k = kms, kme
            DO i = ims, ime
               buf(base_s + (i - ims) + (k - kms) * (ime - ims + 1) + (j - js0c) * (ime - ims + 1) * (kme - kms + 1)) = a(i, k, j)
            END DO
         END DO
      END DO
   ENDIF
   IF (jn0c <= jn1c) THEN
! K-NEST-STRIP-PACK: north strip (Template G)
!$acc parallel loop gang vector collapse(3) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, ime, kms, kme, jms, jn0c, jn1c, base_n)
      DO j = jn0c, jn1c
         DO k = kms, kme
            DO i = ims, ime
               buf(base_n + (i - ims) + (k - kms) * (ime - ims + 1) + (j - jn0c) * (ime - ims + 1) * (kme - kms + 1)) = a(i, k, j)
            END DO
         END DO
      END DO
   ENDIF
   IF (iw0c <= iw1c) THEN
! K-NEST-STRIP-PACK: west strip (Template G)
!$acc parallel loop gang vector collapse(3) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, ime, kms, kme, jms, jme, iw0c, iw1c, base_w)
      DO j = jms, jme
         DO k = kms, kme
            DO i = iw0c, iw1c
               buf(base_w + (i - iw0c) + (k - kms) * (iw1c - iw0c + 1) + (j - jms) * (iw1c - iw0c + 1) * (kme - kms + 1)) = a(i, k, j)
            END DO
         END DO
      END DO
   ENDIF
   IF (ie0c <= ie1c) THEN
! K-NEST-STRIP-PACK: east strip (Template G)
!$acc parallel loop gang vector collapse(3) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, ime, kms, kme, jms, jme, ie0c, ie1c, base_e)
      DO j = jms, jme
         DO k = kms, kme
            DO i = ie0c, ie1c
               buf(base_e + (i - ie0c) + (k - kms) * (ie1c - ie0c + 1) + (j - jms) * (ie1c - ie0c + 1) * (kme - kms + 1)) = a(i, k, j)
            END DO
         END DO
      END DO
   ENDIF
   CALL gpu_map_r(buf, SIZE(buf, KIND=8), GPU_UPD_FROM)
   IF (js0c <= js1c) THEN
      DO j = js0c, js1c
         DO k = kms, kme
            DO i = ims, ime
               a(i, k, j) = buf(base_s + (i - ims) + (k - kms) * (ime - ims + 1) + (j - js0c) * (ime - ims + 1) * (kme - kms + 1))
            END DO
         END DO
      END DO
   ENDIF
   IF (jn0c <= jn1c) THEN
      DO j = jn0c, jn1c
         DO k = kms, kme
            DO i = ims, ime
               a(i, k, j) = buf(base_n + (i - ims) + (k - kms) * (ime - ims + 1) + (j - jn0c) * (ime - ims + 1) * (kme - kms + 1))
            END DO
         END DO
      END DO
   ENDIF
   IF (iw0c <= iw1c) THEN
      DO j = jms, jme
         DO k = kms, kme
            DO i = iw0c, iw1c
               a(i, k, j) = buf(base_w + (i - iw0c) + (k - kms) * (iw1c - iw0c + 1) + (j - jms) * (iw1c - iw0c + 1) * (kme - kms + 1))
            END DO
         END DO
      END DO
   ENDIF
   IF (ie0c <= ie1c) THEN
      DO j = jms, jme
         DO k = kms, kme
            DO i = ie0c, ie1c
               a(i, k, j) = buf(base_e + (i - ie0c) + (k - kms) * (ie1c - ie0c + 1) + (j - jms) * (ie1c - ie0c + 1) * (kme - kms + 1))
            END DO
         END DO
      END DO
   ENDIF
!$acc exit data delete(buf)
   DEALLOCATE(buf)
END SUBROUTINE med_force_domain_gpu_pack3

SUBROUTINE med_force_domain_gpu_pack2(a, ims, ime, jms, jme, &
     iw0, iw1, ie0, ie1, js0, js1, jn0, jn1)
   USE module_gpu_route, ONLY : gpu_on, R_COUPLE_OR_UNCOUPLE_EM
   USE module_gpu_map
   IMPLICIT NONE
   INTEGER, INTENT(IN) :: ims, ime, jms, jme
   INTEGER, INTENT(IN) :: iw0, iw1, ie0, ie1, js0, js1, jn0, jn1
   REAL, INTENT(INOUT) :: a(ims:ime, jms:jme)
   INTEGER :: iw0c, iw1c, ie0c, ie1c, js0c, js1c, jn0c, jn1c
   INTEGER :: n_south, n_north, n_west, n_east, nbuf
   INTEGER :: base_s, base_n, base_w, base_e
   INTEGER :: i, j, ierr
   REAL, ALLOCATABLE :: buf(:)
   iw0c = MAX(ims, iw0)
   iw1c = MIN(ime, iw1)
   ie0c = MAX(ims, ie0)
   ie1c = MIN(ime, ie1)
   js0c = MAX(jms, js0)
   js1c = MIN(jme, js1)
   jn0c = MAX(jms, jn0)
   jn1c = MIN(jme, jn1)
   n_south = 0
   n_north = 0
   n_west = 0
   n_east = 0
   IF (js0c <= js1c) n_south = (ime - ims + 1) * (js1c - js0c + 1)
   IF (jn0c <= jn1c) n_north = (ime - ims + 1) * (jn1c - jn0c + 1)
   IF (iw0c <= iw1c) n_west = (iw1c - iw0c + 1) * (jme - jms + 1)
   IF (ie0c <= ie1c) n_east = (ie1c - ie0c + 1) * (jme - jms + 1)
   nbuf = n_south + n_north + n_west + n_east
   IF (nbuf <= 0) RETURN
   ALLOCATE(buf(nbuf), STAT=ierr)
   IF (ierr /= 0) THEN
      CALL wrf_error_fatal("med_force_domain_gpu_pack2: strip buffer allocate failed")
   ENDIF
   base_s = 1
   base_n = base_s + n_south
   base_w = base_n + n_north
   base_e = base_w + n_west
!$acc enter data create(buf)
   IF (js0c <= js1c) THEN
! K-NEST-STRIP-PACK: south strip, 2D (Template G)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, ime, jms, js0c, js1c, base_s)
      DO j = js0c, js1c
         DO i = ims, ime
            buf(base_s + (i - ims) + (j - js0c) * (ime - ims + 1)) = a(i, j)
         END DO
      END DO
   ENDIF
   IF (jn0c <= jn1c) THEN
! K-NEST-STRIP-PACK: north strip, 2D (Template G)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, ime, jms, jn0c, jn1c, base_n)
      DO j = jn0c, jn1c
         DO i = ims, ime
            buf(base_n + (i - ims) + (j - jn0c) * (ime - ims + 1)) = a(i, j)
         END DO
      END DO
   ENDIF
   IF (iw0c <= iw1c) THEN
! K-NEST-STRIP-PACK: west strip, 2D (Template G)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, jms, jme, iw0c, iw1c, base_w)
      DO j = jms, jme
         DO i = iw0c, iw1c
            buf(base_w + (i - iw0c) + (j - jms) * (iw1c - iw0c + 1)) = a(i, j)
         END DO
      END DO
   ENDIF
   IF (ie0c <= ie1c) THEN
! K-NEST-STRIP-PACK: east strip, 2D (Template G)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, jms, jme, ie0c, ie1c, base_e)
      DO j = jms, jme
         DO i = ie0c, ie1c
            buf(base_e + (i - ie0c) + (j - jms) * (ie1c - ie0c + 1)) = a(i, j)
         END DO
      END DO
   ENDIF
   CALL gpu_map_r(buf, SIZE(buf, KIND=8), GPU_UPD_FROM)
   IF (js0c <= js1c) THEN
      DO j = js0c, js1c
         DO i = ims, ime
            a(i, j) = buf(base_s + (i - ims) + (j - js0c) * (ime - ims + 1))
         END DO
      END DO
   ENDIF
   IF (jn0c <= jn1c) THEN
      DO j = jn0c, jn1c
         DO i = ims, ime
            a(i, j) = buf(base_n + (i - ims) + (j - jn0c) * (ime - ims + 1))
         END DO
      END DO
   ENDIF
   IF (iw0c <= iw1c) THEN
      DO j = jms, jme
         DO i = iw0c, iw1c
            a(i, j) = buf(base_w + (i - iw0c) + (j - jms) * (iw1c - iw0c + 1))
         END DO
      END DO
   ENDIF
   IF (ie0c <= ie1c) THEN
      DO j = jms, jme
         DO i = ie0c, ie1c
            a(i, j) = buf(base_e + (i - ie0c) + (j - jms) * (ie1c - ie0c + 1))
         END DO
      END DO
   ENDIF
!$acc exit data delete(buf)
   DEALLOCATE(buf)
END SUBROUTINE med_force_domain_gpu_pack2

SUBROUTINE med_force_domain_gpu_pack4(a, ims, ime, kms, kme, jms, jme, nms, nme, &
     iw0, iw1, ie0, ie1, js0, js1, jn0, jn1)
   USE module_gpu_route, ONLY : gpu_on, R_COUPLE_OR_UNCOUPLE_EM
   USE module_gpu_map
   IMPLICIT NONE
   INTEGER, INTENT(IN) :: ims, ime, kms, kme, jms, jme, nms, nme
   INTEGER, INTENT(IN) :: iw0, iw1, ie0, ie1, js0, js1, jn0, jn1
   REAL, INTENT(INOUT) :: a(ims:ime, kms:kme, jms:jme, nms:nme)
   INTEGER :: iw0c, iw1c, ie0c, ie1c, js0c, js1c, jn0c, jn1c
   INTEGER :: n_south, n_north, n_west, n_east, nbuf
   INTEGER :: base_s, base_n, base_w, base_e
   INTEGER :: i, k, j, n, ierr
   REAL, ALLOCATABLE :: buf(:)
   iw0c = MAX(ims, iw0)
   iw1c = MIN(ime, iw1)
   ie0c = MAX(ims, ie0)
   ie1c = MIN(ime, ie1)
   js0c = MAX(jms, js0)
   js1c = MIN(jme, js1)
   jn0c = MAX(jms, jn0)
   jn1c = MIN(jme, jn1)
   n_south = 0
   n_north = 0
   n_west = 0
   n_east = 0
   IF (js0c <= js1c) n_south = (ime - ims + 1) * (kme - kms + 1) * (js1c - js0c + 1)
   IF (jn0c <= jn1c) n_north = (ime - ims + 1) * (kme - kms + 1) * (jn1c - jn0c + 1)
   IF (iw0c <= iw1c) n_west = (iw1c - iw0c + 1) * (kme - kms + 1) * (jme - jms + 1)
   IF (ie0c <= ie1c) n_east = (ie1c - ie0c + 1) * (kme - kms + 1) * (jme - jms + 1)
   nbuf = n_south + n_north + n_west + n_east
   IF (nbuf <= 0) RETURN
   ALLOCATE(buf(nbuf), STAT=ierr)
   IF (ierr /= 0) THEN
      CALL wrf_error_fatal("med_force_domain_gpu_pack4: strip buffer allocate failed")
   ENDIF
   base_s = 1
   base_n = base_s + n_south
   base_w = base_n + n_north
   base_e = base_w + n_west
!$acc enter data create(buf)
   DO n = nms, nme
      IF (js0c <= js1c) THEN
! K-NEST-STRIP-PACK: south strip, one species (Template G)
!$acc parallel loop gang vector collapse(3) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, ime, kms, kme, jms, js0c, js1c, base_s, n)
         DO j = js0c, js1c
            DO k = kms, kme
               DO i = ims, ime
                  buf(base_s + (i - ims) + (k - kms) * (ime - ims + 1) + (j - js0c) * (ime - ims + 1) * (kme - kms + 1)) = a(i, k, j, n)
               END DO
            END DO
         END DO
      ENDIF
      IF (jn0c <= jn1c) THEN
! K-NEST-STRIP-PACK: north strip, one species (Template G)
!$acc parallel loop gang vector collapse(3) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, ime, kms, kme, jms, jn0c, jn1c, base_n, n)
         DO j = jn0c, jn1c
            DO k = kms, kme
               DO i = ims, ime
                  buf(base_n + (i - ims) + (k - kms) * (ime - ims + 1) + (j - jn0c) * (ime - ims + 1) * (kme - kms + 1)) = a(i, k, j, n)
               END DO
            END DO
         END DO
      ENDIF
      IF (iw0c <= iw1c) THEN
! K-NEST-STRIP-PACK: west strip, one species (Template G)
!$acc parallel loop gang vector collapse(3) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, ime, kms, kme, jms, jme, iw0c, iw1c, base_w, n)
         DO j = jms, jme
            DO k = kms, kme
               DO i = iw0c, iw1c
                  buf(base_w + (i - iw0c) + (k - kms) * (iw1c - iw0c + 1) + (j - jms) * (iw1c - iw0c + 1) * (kme - kms + 1)) = a(i, k, j, n)
               END DO
            END DO
         END DO
      ENDIF
      IF (ie0c <= ie1c) THEN
! K-NEST-STRIP-PACK: east strip, one species (Template G)
!$acc parallel loop gang vector collapse(3) if(gpu_on(R_COUPLE_OR_UNCOUPLE_EM)) default(none) &
!$acc& present(a, buf) firstprivate(ims, ime, kms, kme, jms, jme, ie0c, ie1c, base_e, n)
         DO j = jms, jme
            DO k = kms, kme
               DO i = ie0c, ie1c
                  buf(base_e + (i - ie0c) + (k - kms) * (ie1c - ie0c + 1) + (j - jms) * (ie1c - ie0c + 1) * (kme - kms + 1)) = a(i, k, j, n)
               END DO
            END DO
         END DO
      ENDIF
      CALL gpu_map_r(buf, SIZE(buf, KIND=8), GPU_UPD_FROM)
      IF (js0c <= js1c) THEN
         DO j = js0c, js1c
            DO k = kms, kme
               DO i = ims, ime
                  a(i, k, j, n) = buf(base_s + (i - ims) + (k - kms) * (ime - ims + 1) + (j - js0c) * (ime - ims + 1) * (kme - kms + 1))
               END DO
            END DO
         END DO
      ENDIF
      IF (jn0c <= jn1c) THEN
         DO j = jn0c, jn1c
            DO k = kms, kme
               DO i = ims, ime
                  a(i, k, j, n) = buf(base_n + (i - ims) + (k - kms) * (ime - ims + 1) + (j - jn0c) * (ime - ims + 1) * (kme - kms + 1))
               END DO
            END DO
         END DO
      ENDIF
      IF (iw0c <= iw1c) THEN
         DO j = jms, jme
            DO k = kms, kme
               DO i = iw0c, iw1c
                  a(i, k, j, n) = buf(base_w + (i - iw0c) + (k - kms) * (iw1c - iw0c + 1) + (j - jms) * (iw1c - iw0c + 1) * (kme - kms + 1))
               END DO
            END DO
         END DO
      ENDIF
      IF (ie0c <= ie1c) THEN
         DO j = jms, jme
            DO k = kms, kme
               DO i = ie0c, ie1c
                  a(i, k, j, n) = buf(base_e + (i - ie0c) + (k - kms) * (ie1c - ie0c + 1) + (j - jms) * (ie1c - ie0c + 1) * (kme - kms + 1))
               END DO
            END DO
         END DO
      ENDIF
   END DO
!$acc exit data delete(buf)
   DEALLOCATE(buf)
END SUBROUTINE med_force_domain_gpu_pack4
#endif


