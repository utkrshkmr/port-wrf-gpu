 module module_mp_wsm6
 use ccpp_kind_types,only: kind_phys

 use mp_wsm6,only: mp_wsm6_run
 use mp_wsm6_effectrad,only: mp_wsm6_effectRad_run


 implicit none
 private
 public:: wsm6


 contains


!=================================================================================================================
 subroutine wsm6(th,q,qc,qr,qi,qs,qg,den,pii,p,delz,                 &
                 delt,g,cpd,cpv,rd,rv,t0c,ep1,ep2,qmin,              &
                 xls,xlv0,xlf0,den0,denr,cliq,cice,psat,             &
                 rain,rainncv,snow,snowncv,graupel,graupelncv,sr,    &
                 refl_10cm,diagflag,do_radar_ref,                    &
                 has_reqc,has_reqi,has_reqs,                         &
                 re_qc_bg,re_qi_bg,re_qs_bg,                         &
                 re_qc_max,re_qi_max,re_qs_max,                      &
                 re_cloud,re_ice,re_snow,                            &
                 ids,ide,jds,jde,kds,kde,                            &
                 ims,ime,jms,jme,kms,kme,                            &
                 its,ite,jts,jte,kts,kte,                            &
                 errmsg,errflg                                       &
#if(WRF_CHEM == 1)
                 ,wetscav_on,evapprod,rainprod                       &
#endif
                )
!=================================================================================================================
#ifdef WRF_GPU
#include "gpu_col.h"
#endif
      USE module_gpu_route, ONLY : gpu_on, gpu_island, gpu_world_host, R_WSM6
      USE module_gpu_callcheck

!--- input arguments:
 logical,intent(in),optional:: diagflag

 integer,intent(in):: ids,ide,jds,jde,kds,kde, &
                      ims,ime,jms,jme,kms,kme, &
                      its,ite,jts,jte,kts,kte

 integer,intent(in):: has_reqc,has_reqi,has_reqs
 integer,intent(in),optional:: do_radar_ref

 real(kind=kind_phys),intent(in):: &
    delt,g,rd,rv,t0c,den0,cpd,cpv,ep1,ep2,qmin,xls,xlv0,xlf0, &
    cliq,cice,psat,denr

 real(kind=kind_phys),intent(in):: &
    re_qc_bg,re_qi_bg,re_qs_bg,re_qc_max,re_qi_max,re_qs_max

 real(kind=kind_phys),intent(in),dimension(ims:ime,kms:kme,jms:jme ):: &
    den, &
    pii, &
    p,   &
    delz

!inout arguments:
 real(kind=kind_phys),intent(inout),dimension(ims:ime,jms:jme):: &
    rain,rainncv,sr

 real(kind=kind_phys),intent(inout),dimension(ims:ime,jms:jme),optional:: &
    snow,snowncv

 real(kind=kind_phys),intent(inout),dimension(ims:ime,jms:jme),optional:: &
    graupel,graupelncv

 real(kind=kind_phys),intent(inout),dimension(ims:ime,kms:kme,jms:jme):: &
    th, &
    q,  &
    qc, &
    qi, &
    qr, &
    qs, &
    qg

 real(kind=kind_phys),intent(inout),dimension(ims:ime,kms:kme,jms:jme):: &
    re_cloud, &
    re_ice,   &
    re_snow

 real(kind=kind_phys),intent(inout),dimension(ims:ime,kms:kme,jms:jme),optional:: &
    refl_10cm

#if(WRF_CHEM == 1) 
 logical,intent(in):: wetscav_on
 real(kind=kind_phys),intent(inout),dimension(ims:ime,kms:kme,jms:jme ):: &
    rainprod,evapprod
 real(kind=kind_phys),dimension(its:ite,kts:kte):: rainprod_hv,evapprod_hv
#endif

!output arguments:
 character(len=*),intent(out):: errmsg
 integer,intent(out):: errflg

!local variables and arrays:
 logical:: do_microp_re
 integer:: i,j,k
#ifdef WRF_GPU
 logical :: gpu_isl
 integer :: nz, kk
 integer :: errflg_c
 character(len=256) :: errmsg_c
 real(kind=kind_phys), dimension(GPU_IK) :: t_col, den_col, p_col, delz_col
 real(kind=kind_phys), dimension(GPU_IK) :: qv_col, qc_col, qi_col, qr_col, qs_col, qg_col
 real(kind=kind_phys), dimension(GPU_I) :: rain_col, rainncv_col, sr_col
 real(kind=kind_phys), dimension(GPU_I) :: snow_col, snowncv_col
 real(kind=kind_phys), dimension(GPU_I) :: graupel_col, graupelncv_col
#if (WRF_CHEM == 1)
 real(kind=kind_phys), dimension(GPU_IK) :: rainprod_col, evapprod_col
#endif
#endif

 real(kind=kind_phys),dimension(kts:kte):: qv1d,t1d,p1d,qr1d,qs1d,qg1d,dBZ
 real(kind=kind_phys),dimension(kts:kte):: den1d,qc1d,qi1d,re_qc,re_qi,re_qs

 real(kind=kind_phys),dimension(its:ite):: rainncv_hv,rain_hv,sr_hv
 real(kind=kind_phys),dimension(its:ite):: snowncv_hv,snow_hv
 real(kind=kind_phys),dimension(its:ite):: graupelncv_hv,graupel_hv
 real(kind=kind_phys),dimension(its:ite,kts:kte):: t_hv,den_hv,p_hv,delz_hv
 real(kind=kind_phys),dimension(its:ite,kts:kte):: qv_hv,qc_hv,qi_hv,qr_hv,qs_hv,qg_hv
 real(kind=kind_phys),dimension(its:ite,kts:kte):: re_qc_hv,re_qi_hv,re_qs_hv

!-----------------------------------------------------------------------------------------------------------------

#ifdef WRF_GPU
      IF ((has_reqc /= 0) .OR. (has_reqi /= 0) .OR. (has_reqs /= 0)) THEN
         CALL wrf_error_fatal('wsm6: effective radius not ported to the GPU')
      END IF
      IF (.NOT. (PRESENT(snow) .AND. PRESENT(snowncv) .AND. PRESENT(graupel) .AND. PRESENT(graupelncv))) THEN
         CALL wrf_error_fatal('wsm6: snow or graupel argument not ported to the GPU')
      END IF
99901 CONTINUE
      IF (gpu_cc_start(R_WSM6)) THEN
        CALL gpu_cc_save_r(1, th, SIZE(th,KIND=8))
        CALL gpu_cc_save_r(2, q, SIZE(q,KIND=8))
        CALL gpu_cc_save_r(3, qc, SIZE(qc,KIND=8))
        CALL gpu_cc_save_r(4, qr, SIZE(qr,KIND=8))
        CALL gpu_cc_save_r(5, qi, SIZE(qi,KIND=8))
        CALL gpu_cc_save_r(6, qs, SIZE(qs,KIND=8))
        CALL gpu_cc_save_r(7, qg, SIZE(qg,KIND=8))
        CALL gpu_cc_save_r(8, rain, SIZE(rain,KIND=8))
        CALL gpu_cc_save_r(9, rainncv, SIZE(rainncv,KIND=8))
        IF (PRESENT(snow)) CALL gpu_cc_save_r(10, snow, SIZE(snow,KIND=8))
        IF (PRESENT(snowncv)) CALL gpu_cc_save_r(11, snowncv, SIZE(snowncv,KIND=8))
        IF (PRESENT(graupel)) CALL gpu_cc_save_r(12, graupel, SIZE(graupel,KIND=8))
        IF (PRESENT(graupelncv)) CALL gpu_cc_save_r(13, graupelncv, SIZE(graupelncv,KIND=8))
        CALL gpu_cc_save_r(14, sr, SIZE(sr,KIND=8))
        IF (PRESENT(refl_10cm)) CALL gpu_cc_save_r(15, refl_10cm, SIZE(refl_10cm,KIND=8))
        CALL gpu_cc_save_r(16, re_cloud, SIZE(re_cloud,KIND=8))
        CALL gpu_cc_save_r(17, re_ice, SIZE(re_ice,KIND=8))
        CALL gpu_cc_save_r(18, re_snow, SIZE(re_snow,KIND=8))
        CALL gpu_cc_save_i0(19, errflg)
#if (WRF_CHEM == 1)
        CALL gpu_cc_save_r(20, evapprod, SIZE(evapprod,KIND=8))
        CALL gpu_cc_save_r(21, rainprod, SIZE(rainprod,KIND=8))
#endif
      END IF
      gpu_isl = gpu_island(R_WSM6)
      IF (gpu_isl) THEN
        IF (gpu_world_host) THEN
!$acc update device(th, q, qc, qr, qi, qs, qg, den, pii, p, delz, rain, rainncv, sr, re_cloud, &
!$acc&   re_ice, re_snow)
#if (WRF_CHEM == 1)
!$acc update device(evapprod, rainprod)
#endif
          IF (PRESENT(snow)) THEN
!$acc update device(snow)
          END IF
          IF (PRESENT(snowncv)) THEN
!$acc update device(snowncv)
          END IF
          IF (PRESENT(graupel)) THEN
!$acc update device(graupel)
          END IF
          IF (PRESENT(graupelncv)) THEN
!$acc update device(graupelncv)
          END IF
          IF (PRESENT(refl_10cm)) THEN
!$acc update device(refl_10cm)
          END IF
        ELSE
!$acc update self(th, q, qc, qr, qi, qs, qg, den, pii, p, delz, rain, rainncv, sr, re_cloud, &
!$acc&   re_ice, re_snow)
#if (WRF_CHEM == 1)
!$acc update self(evapprod, rainprod)
#endif
          IF (PRESENT(snow)) THEN
!$acc update self(snow)
          END IF
          IF (PRESENT(snowncv)) THEN
!$acc update self(snowncv)
          END IF
          IF (PRESENT(graupel)) THEN
!$acc update self(graupel)
          END IF
          IF (PRESENT(graupelncv)) THEN
!$acc update self(graupelncv)
          END IF
          IF (PRESENT(refl_10cm)) THEN
!$acc update self(refl_10cm)
          END IF
        END IF
        gpu_world_host = .NOT. gpu_world_host
      END IF
#endif

#ifdef WRF_GPU
      nz = kte - kts + 1
#if (WRF_CHEM == 1)
#define WSM6_CHEM_ARR , rainprod, evapprod
#define WSM6_CHEM_FP , wetscav_on
#define WSM6_CHEM_COL , rainprod_col, evapprod_col
#else
#define WSM6_CHEM_ARR
#define WSM6_CHEM_FP
#define WSM6_CHEM_COL
#endif
! K-WSM6: one thread per column (Template CP)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_WSM6)) default(none) &
!$acc& present(th, q, qc, qi, qr, qs, qg, den, pii, p, delz, rain, rainncv, sr, &
!$acc& snow, snowncv, graupel, graupelncv WSM6_CHEM_ARR) &
!$acc& firstprivate(its, ite, jts, jte, kts, kte, nz, delt, g, cpd, cpv, rd, rv, &
!$acc& t0c, ep1, ep2, qmin, xls, xlv0, xlf0, den0, denr, cliq, cice, psat WSM6_CHEM_FP) &
!$acc& private(k, kk, t_col, den_col, p_col, delz_col, qv_col, qc_col, qi_col, &
!$acc& qr_col, qs_col, qg_col, rain_col, rainncv_col, sr_col, snow_col, &
!$acc& snowncv_col, graupel_col, graupelncv_col, errmsg_c, errflg_c WSM6_CHEM_COL)
      do j = jts, jte
      do i = its, ite
         !$acc loop seq
         do k = kts, kte
            kk = k - kts + 1
            den_col(1,kk)  = den(i,k,j)
            p_col(1,kk)    = p(i,k,j)
            delz_col(1,kk) = delz(i,k,j)
         enddo
         rain_col(1) = rain(i,j)
         !$acc loop seq
         do k = kts, kte
            kk = k - kts + 1
            t_col(1,kk)  = th(i,k,j)*pii(i,k,j)
            qv_col(1,kk) = q(i,k,j)
            qc_col(1,kk) = qc(i,k,j)
            qi_col(1,kk) = qi(i,k,j)
            qr_col(1,kk) = qr(i,k,j)
            qs_col(1,kk) = qs(i,k,j)
            qg_col(1,kk) = qg(i,k,j)
         enddo
         snow_col(1) = snow(i,j)
         graupel_col(1) = graupel(i,j)
         call mp_wsm6_run(t=t_col(1:1,1:nz), q=qv_col(1:1,1:nz), qc=qc_col(1:1,1:nz), &
                 qi=qi_col(1:1,1:nz), qr=qr_col(1:1,1:nz), qs=qs_col(1:1,1:nz),       &
                 qg=qg_col(1:1,1:nz), den=den_col(1:1,1:nz), p=p_col(1:1,1:nz),       &
                 delz=delz_col(1:1,1:nz), delt=delt, g=g, cpd=cpd, cpv=cpv,           &
                 rd=rd, rv=rv, t0c=t0c, ep1=ep1, ep2=ep2, qmin=qmin, xls=xls,         &
                 xlv0=xlv0, xlf0=xlf0, den0=den0, denr=denr, cliq=cliq, cice=cice,    &
                 psat=psat, rain=rain_col(1:1), rainncv=rainncv_col(1:1),            &
                 sr=sr_col(1:1), snow=snow_col(1:1), snowncv=snowncv_col(1:1),        &
                 graupel=graupel_col(1:1), graupelncv=graupelncv_col(1:1),            &
                 its=1, ite=1, kts=1, kte=nz, errmsg=errmsg_c, errflg=errflg_c        &
#if (WRF_CHEM == 1)
                 ,rainprod2d=rainprod_col(1:1,1:nz), evapprod2d=evapprod_col(1:1,1:nz) &
#endif
                 )
         rain(i,j)    = rain_col(1)
         rainncv(i,j) = rainncv_col(1)
         sr(i,j)      = sr_col(1)
         !$acc loop seq
         do k = kts, kte
            kk = k - kts + 1
            th(i,k,j) = t_col(1,kk)/pii(i,k,j)
            q(i,k,j)  = qv_col(1,kk)
            qc(i,k,j) = qc_col(1,kk)
            qi(i,k,j) = qi_col(1,kk)
            qr(i,k,j) = qr_col(1,kk)
            qs(i,k,j) = qs_col(1,kk)
            qg(i,k,j) = qg_col(1,kk)
         enddo
         snow(i,j)       = snow_col(1)
         snowncv(i,j)    = snowncv_col(1)
         graupel(i,j)    = graupel_col(1)
         graupelncv(i,j) = graupelncv_col(1)
#if (WRF_CHEM == 1)
         if (wetscav_on) then
            !$acc loop seq
            do k = kts, kte
               kk = k - kts + 1
               rainprod(i,k,j) = rainprod_col(1,kk)
               evapprod(i,k,j) = evapprod_col(1,kk)
            enddo
         else
            !$acc loop seq
            do k = kts, kte
               rainprod(i,k,j) = 0.
               evapprod(i,k,j) = 0.
            enddo
         endif
#endif
      enddo
      enddo
      errmsg = 'mp_wsm6_run OK'
      errflg = 0

#ifdef WRF_GPU
      IF (gpu_isl) THEN
        gpu_world_host = .NOT. gpu_world_host
        IF (gpu_world_host) THEN
!$acc update self(th, q, qc, qr, qi, qs, qg, rain, rainncv, sr, re_cloud, re_ice, re_snow)
#if (WRF_CHEM == 1)
!$acc update self(evapprod, rainprod)
#endif
          IF (PRESENT(snow)) THEN
!$acc update self(snow)
          END IF
          IF (PRESENT(snowncv)) THEN
!$acc update self(snowncv)
          END IF
          IF (PRESENT(graupel)) THEN
!$acc update self(graupel)
          END IF
          IF (PRESENT(graupelncv)) THEN
!$acc update self(graupelncv)
          END IF
          IF (PRESENT(refl_10cm)) THEN
!$acc update self(refl_10cm)
          END IF
        ELSE
!$acc update device(th, q, qc, qr, qi, qs, qg, rain, rainncv, sr, re_cloud, re_ice, re_snow)
#if (WRF_CHEM == 1)
!$acc update device(evapprod, rainprod)
#endif
          IF (PRESENT(snow)) THEN
!$acc update device(snow)
          END IF
          IF (PRESENT(snowncv)) THEN
!$acc update device(snowncv)
          END IF
          IF (PRESENT(graupel)) THEN
!$acc update device(graupel)
          END IF
          IF (PRESENT(graupelncv)) THEN
!$acc update device(graupelncv)
          END IF
          IF (PRESENT(refl_10cm)) THEN
!$acc update device(refl_10cm)
          END IF
        END IF
      END IF
      IF (gpu_cc_active(R_WSM6)) THEN
        CALL gpu_cc_done_r(1, th, SIZE(th,KIND=8), 'th', &
          LBOUND(th), UBOUND(th))
        CALL gpu_cc_done_r(2, q, SIZE(q,KIND=8), 'q', &
          LBOUND(q), UBOUND(q))
        CALL gpu_cc_done_r(3, qc, SIZE(qc,KIND=8), 'qc', &
          LBOUND(qc), UBOUND(qc))
        CALL gpu_cc_done_r(4, qr, SIZE(qr,KIND=8), 'qr', &
          LBOUND(qr), UBOUND(qr))
        CALL gpu_cc_done_r(5, qi, SIZE(qi,KIND=8), 'qi', &
          LBOUND(qi), UBOUND(qi))
        CALL gpu_cc_done_r(6, qs, SIZE(qs,KIND=8), 'qs', &
          LBOUND(qs), UBOUND(qs))
        CALL gpu_cc_done_r(7, qg, SIZE(qg,KIND=8), 'qg', &
          LBOUND(qg), UBOUND(qg))
        CALL gpu_cc_done_r(8, rain, SIZE(rain,KIND=8), 'rain', &
          LBOUND(rain), UBOUND(rain))
        CALL gpu_cc_done_r(9, rainncv, SIZE(rainncv,KIND=8), 'rainncv', &
          LBOUND(rainncv), UBOUND(rainncv))
        IF (PRESENT(snow)) CALL gpu_cc_done_r(10, snow, SIZE(snow,KIND=8), 'snow', &
          LBOUND(snow), UBOUND(snow))
        IF (PRESENT(snowncv)) CALL gpu_cc_done_r(11, snowncv, SIZE(snowncv,KIND=8), 'snowncv', &
          LBOUND(snowncv), UBOUND(snowncv))
        IF (PRESENT(graupel)) CALL gpu_cc_done_r(12, graupel, SIZE(graupel,KIND=8), 'graupel', &
          LBOUND(graupel), UBOUND(graupel))
        IF (PRESENT(graupelncv)) CALL gpu_cc_done_r(13, graupelncv, SIZE(graupelncv,KIND=8), 'graupelncv', &
          LBOUND(graupelncv), UBOUND(graupelncv))
        CALL gpu_cc_done_r(14, sr, SIZE(sr,KIND=8), 'sr', &
          LBOUND(sr), UBOUND(sr))
        IF (PRESENT(refl_10cm)) CALL gpu_cc_done_r(15, refl_10cm, SIZE(refl_10cm,KIND=8), 'refl_10cm', &
          LBOUND(refl_10cm), UBOUND(refl_10cm))
        CALL gpu_cc_done_r(16, re_cloud, SIZE(re_cloud,KIND=8), 're_cloud', &
          LBOUND(re_cloud), UBOUND(re_cloud))
        CALL gpu_cc_done_r(17, re_ice, SIZE(re_ice,KIND=8), 're_ice', &
          LBOUND(re_ice), UBOUND(re_ice))
        CALL gpu_cc_done_r(18, re_snow, SIZE(re_snow,KIND=8), 're_snow', &
          LBOUND(re_snow), UBOUND(re_snow))
        CALL gpu_cc_done_i0(19, errflg, 'errflg')
#if (WRF_CHEM == 1)
        CALL gpu_cc_done_r(20, evapprod, SIZE(evapprod,KIND=8), 'evapprod', &
          LBOUND(evapprod), UBOUND(evapprod))
        CALL gpu_cc_done_r(21, rainprod, SIZE(rainprod,KIND=8), 'rainprod', &
          LBOUND(rainprod), UBOUND(rainprod))
#endif
        IF (gpu_cc_next(R_WSM6)) GOTO 99901
      END IF
#endif
      RETURN
#undef WSM6_CHEM_ARR
#undef WSM6_CHEM_FP
#undef WSM6_CHEM_COL
#endif

 do j = jts,jte

    do i = its,ite
       !input arguments:
       do k = kts,kte
          den_hv(i,k)  = den(i,k,j)
          p_hv(i,k)    = p(i,k,j)
          delz_hv(i,k) = delz(i,k,j)
       enddo

       !inout arguments:
       rain_hv(i) = rain(i,j)

       do k = kts,kte
          t_hv(i,k)  = th(i,k,j)*pii(i,k,j)
          qv_hv(i,k) = q(i,k,j)
          qc_hv(i,k) = qc(i,k,j)
          qi_hv(i,k) = qi(i,k,j)
          qr_hv(i,k) = qr(i,k,j)
          qs_hv(i,k) = qs(i,k,j)
          qg_hv(i,k) = qg(i,k,j)
       enddo
    enddo

    if(present(snow) .and. present(snowncv)) then
       do i = its,ite
          snow_hv(i) = snow(i,j)
       enddo
    endif
    if(present(graupel) .and. present(graupelncv)) then
       do i = its,ite
          graupel_hv(i) = graupel(i,j)
       enddo
    endif

!--- call to cloud microphysics scheme:
    call mp_wsm6_run(t=t_hv,q=qv_hv,qc=qc_hv,qi=qi_hv,qr=qr_hv,qs=qs_hv,qg=qg_hv, &
                 den=den_hv,p=p_hv,delz=delz_hv,delt=delt,g=g,cpd=cpd,cpv=cpv,    &
                 rd=rd,rv=rv,t0c=t0c,ep1=ep1,ep2=ep2,qmin=qmin,xls=xls,xlv0=xlv0, &
                 xlf0=xlf0,den0=den0,denr=denr,cliq=cliq,cice=cice,psat=psat,     &
                 rain=rain_hv,rainncv=rainncv_hv,sr=sr_hv,snow=snow_hv,           &
                 snowncv=snowncv_hv,graupel=graupel_hv,graupelncv=graupelncv_hv,  &
                 its=its,ite=ite,kts=kts,kte=kte,errmsg=errmsg,errflg=errflg      &
#if(WRF_CHEM == 1)
                 ,rainprod2d=rainprod_hv,evapprod2d=evapprod_hv                   &
#endif
                    )

    do i = its,ite
       !inout arguments:
       rain(i,j)    = rain_hv(i)
       rainncv(i,j) = rainncv_hv(i)
       sr(i,j)      = sr_hv(i)

       do k = kts,kte
          th(i,k,j) = t_hv(i,k)/pii(i,k,j)
          q(i,k,j)  = qv_hv(i,k)
          qc(i,k,j) = qc_hv(i,k)
          qi(i,k,j) = qi_hv(i,k)
          qr(i,k,j) = qr_hv(i,k)
          qs(i,k,j) = qs_hv(i,k)
          qg(i,k,j) = qg_hv(i,k)
       enddo
    enddo

    if(present(snow) .and. present(snowncv)) then
       do i = its,ite
          snow(i,j)    = snow_hv(i)
          snowncv(i,j) = snowncv_hv(i)
       enddo
    endif
    if(present(graupel) .and. present(graupelncv)) then
       do i = its,ite
          graupel(i,j)    = graupel_hv(i)
          graupelncv(i,j) = graupelncv_hv(i)
       enddo
    endif

#if(WRF_CHEM == 1)
    if(wetscav_on) then
       do k = kts,kte
          do i = its, ite
             rainprod(i,k,j) = rainprod_hv(i,k)
             evapprod(i,k,j) = evapprod_hv(i,k)
          enddo
        enddo
     else
       do k = kts,kte
          do i = its, ite
             rainprod(i,k,j) = 0.
             evapprod(i,k,j) = 0.
          enddo
        enddo
     endif
#endif

!--- call to computation of effective radii for cloud water, cloud ice, and snow:
     do_microp_re = .false.
     if(has_reqc == 1 .and. has_reqi == 1 .and. has_reqs == 1) do_microp_re = .true.

     do k = kts,kte
        do i = its,ite
           t_hv(i,k) = th(i,k,j)*pii(i,k,j)
           re_qc_hv(i,k) = re_cloud(i,k,j)
           re_qi_hv(i,k) = re_ice(i,k,j)
           re_qs_hv(i,k) = re_snow(i,k,j)
        enddo
     enddo

     call  mp_wsm6_effectRad_run(do_microp_re,t_hv,qc_hv,qi_hv,qs_hv,den_hv,qmin,t0c, &
                   re_qc_bg,re_qi_bg,re_qs_bg,re_qc_max,re_qi_max,re_qs_max,re_qc_hv, &
                   re_qi_hv,re_qs_hv,its,ite,kts,kte,errmsg,errflg)

     do k = kts,kte
        do i = its,ite
           re_cloud(i,k,j) = re_qc_hv(i,k)
           re_ice(i,k,j)   = re_qi_hv(i,k)
           re_snow(i,k,j)  = re_qs_hv(i,k)
        enddo
     enddo

 enddo

#ifdef WRF_GPU
      IF (gpu_isl) THEN
        gpu_world_host = .NOT. gpu_world_host
        IF (gpu_world_host) THEN
!$acc update self(th, q, qc, qr, qi, qs, qg, rain, rainncv, sr, re_cloud, re_ice, re_snow)
#if (WRF_CHEM == 1)
!$acc update self(evapprod, rainprod)
#endif
          IF (PRESENT(snow)) THEN
!$acc update self(snow)
          END IF
          IF (PRESENT(snowncv)) THEN
!$acc update self(snowncv)
          END IF
          IF (PRESENT(graupel)) THEN
!$acc update self(graupel)
          END IF
          IF (PRESENT(graupelncv)) THEN
!$acc update self(graupelncv)
          END IF
          IF (PRESENT(refl_10cm)) THEN
!$acc update self(refl_10cm)
          END IF
        ELSE
!$acc update device(th, q, qc, qr, qi, qs, qg, rain, rainncv, sr, re_cloud, re_ice, re_snow)
#if (WRF_CHEM == 1)
!$acc update device(evapprod, rainprod)
#endif
          IF (PRESENT(snow)) THEN
!$acc update device(snow)
          END IF
          IF (PRESENT(snowncv)) THEN
!$acc update device(snowncv)
          END IF
          IF (PRESENT(graupel)) THEN
!$acc update device(graupel)
          END IF
          IF (PRESENT(graupelncv)) THEN
!$acc update device(graupelncv)
          END IF
          IF (PRESENT(refl_10cm)) THEN
!$acc update device(refl_10cm)
          END IF
        END IF
      END IF
      IF (gpu_cc_active(R_WSM6)) THEN
        CALL gpu_cc_done_r(1, th, SIZE(th,KIND=8), 'th', &
          LBOUND(th), UBOUND(th))
        CALL gpu_cc_done_r(2, q, SIZE(q,KIND=8), 'q', &
          LBOUND(q), UBOUND(q))
        CALL gpu_cc_done_r(3, qc, SIZE(qc,KIND=8), 'qc', &
          LBOUND(qc), UBOUND(qc))
        CALL gpu_cc_done_r(4, qr, SIZE(qr,KIND=8), 'qr', &
          LBOUND(qr), UBOUND(qr))
        CALL gpu_cc_done_r(5, qi, SIZE(qi,KIND=8), 'qi', &
          LBOUND(qi), UBOUND(qi))
        CALL gpu_cc_done_r(6, qs, SIZE(qs,KIND=8), 'qs', &
          LBOUND(qs), UBOUND(qs))
        CALL gpu_cc_done_r(7, qg, SIZE(qg,KIND=8), 'qg', &
          LBOUND(qg), UBOUND(qg))
        CALL gpu_cc_done_r(8, rain, SIZE(rain,KIND=8), 'rain', &
          LBOUND(rain), UBOUND(rain))
        CALL gpu_cc_done_r(9, rainncv, SIZE(rainncv,KIND=8), 'rainncv', &
          LBOUND(rainncv), UBOUND(rainncv))
        IF (PRESENT(snow)) CALL gpu_cc_done_r(10, snow, SIZE(snow,KIND=8), 'snow', &
          LBOUND(snow), UBOUND(snow))
        IF (PRESENT(snowncv)) CALL gpu_cc_done_r(11, snowncv, SIZE(snowncv,KIND=8), 'snowncv', &
          LBOUND(snowncv), UBOUND(snowncv))
        IF (PRESENT(graupel)) CALL gpu_cc_done_r(12, graupel, SIZE(graupel,KIND=8), 'graupel', &
          LBOUND(graupel), UBOUND(graupel))
        IF (PRESENT(graupelncv)) CALL gpu_cc_done_r(13, graupelncv, SIZE(graupelncv,KIND=8), 'graupelncv', &
          LBOUND(graupelncv), UBOUND(graupelncv))
        CALL gpu_cc_done_r(14, sr, SIZE(sr,KIND=8), 'sr', &
          LBOUND(sr), UBOUND(sr))
        IF (PRESENT(refl_10cm)) CALL gpu_cc_done_r(15, refl_10cm, SIZE(refl_10cm,KIND=8), 'refl_10cm', &
          LBOUND(refl_10cm), UBOUND(refl_10cm))
        CALL gpu_cc_done_r(16, re_cloud, SIZE(re_cloud,KIND=8), 're_cloud', &
          LBOUND(re_cloud), UBOUND(re_cloud))
        CALL gpu_cc_done_r(17, re_ice, SIZE(re_ice,KIND=8), 're_ice', &
          LBOUND(re_ice), UBOUND(re_ice))
        CALL gpu_cc_done_r(18, re_snow, SIZE(re_snow,KIND=8), 're_snow', &
          LBOUND(re_snow), UBOUND(re_snow))
        CALL gpu_cc_done_i0(19, errflg, 'errflg')
#if (WRF_CHEM == 1)
        CALL gpu_cc_done_r(20, evapprod, SIZE(evapprod,KIND=8), 'evapprod', &
          LBOUND(evapprod), UBOUND(evapprod))
        CALL gpu_cc_done_r(21, rainprod, SIZE(rainprod,KIND=8), 'rainprod', &
          LBOUND(rainprod), UBOUND(rainprod))
#endif
        IF (gpu_cc_next(R_WSM6)) GOTO 99901
      END IF
#endif

 end subroutine wsm6

!=================================================================================================================
 end module module_mp_wsm6
!=================================================================================================================
