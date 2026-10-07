!WRF:MEDIATION_LAYER:PHYSICS
!

MODULE module_pbl_driver
   USE module_repro_math
  real, private, parameter :: QCLOUD_MIN = 0.0
  real, private, parameter :: QVAPOR_MIN = 0.0
  real, private, parameter :: QKE_MIN = 1.e-4
CONTAINS

!------------------------------------------------------------------
   SUBROUTINE pbl_driver(                                          &
                  itimestep,dt,u_frame,v_frame                     &
                 ,bldt,curr_secs,adapt_step_flag                   &
                 ,bldtacttime                                      & 
                 ,rublten,rvblten,rthblten                         &
                 ,tsk,xland,znt                                    &
                 ,ht                                               &   
                 ,ust,pblh,hfx,qfx,grdflx,hpbl_hold                &
                 ,u_phy,v_phy,w,th_phy,rho                         &
                 ,p_phy,pi_phy,p8w,t_phy,dz8w,z                    &
                 ,exch_h,exch_m,akhs,akms                          &
                 ,thz0,qz0,uz0,vz0,qsfc,f                          &
                 ,lowlyr,u10,v10,uoce,voce,t2                      &
                 ,psim,psih,fm,fhh,gz1oz0, wspd,br,chklowq         &
                 ,bl_pbl_physics, ra_lw_physics, dx, dy            &
                 ,dx2d ,area2d                                     &
                 ,stepbl,warm_rain                                 &
                 ,kpbl,mixht,ct,lh,snow,xice                       &
                 ,znu, znw, mut, p_top                             &
                 ,ctopo,ctopo2,windfarm_opt,power                  &
                 ,windfarm_wake_model, windfarm_overlap_method     &
                 ,ysu_topdown_pblmix                               &
                 ,shinhong_tke_diag                                &
              ! OPTIONAL for TEMF scheme
                 ,te_temf,km_temf,kh_temf                     &
                 ,shf_temf,qf_temf,uw_temf,vw_temf                &
                 ,hd_temf,lcl_temf,hct_temf                       &
                 ,wupd_temf,mf_temf,thup_temf,qtup_temf,qlup_temf &
                 ,exch_temf,cf3d_temf,cfm_temf                    &
                 ,flhc,flqc                                        &
              ! MYNN
                 ,qke,Sh3d,Sm3d                                    &
                 ,qke_adv,bl_mynn_tkeadvect                        &
                 ,tsq,qsq,cov,rmol,ch,qcg,grav_settling            & 
                 ,dqke,qWT,qSHEAR,qBUOY,qDISS,tke_budget           &
                 ,bl_mynn_closure,bl_mynn_cloudpdf                 &
                 ,bl_mynn_mixlength                                &
                 ,icloud_bl,qc_bl,qi_bl,cldfra_bl                  &
                 ,bl_mynn_edmf,bl_mynn_edmf_mom,bl_mynn_edmf_tke   &
                 ,bl_mynn_mixscalars,bl_mynn_output                &
                 ,bl_mynn_cloudmix,bl_mynn_mixqt                   &
                 ,edmf_a,edmf_w,edmf_thl                           &
                 ,edmf_qt,edmf_ent,edmf_qc                         &
                 ,sub_thl3D,sub_sqv3D                              &
                 ,det_thl3D,det_sqv3D                              &
                 ,vdfg                                             &
                 ,maxwidth,maxMF,ztop_plume,ktop_plume             &
                 ,spp_pbl,pattern_spp_pbl                          &
              ! EEPS
                 ,pek,pep,pek_adv,pep_adv                          &
                 ,restart,cycling                                  &
                 ,ids,ide, jds,jde, kds,kde                        &
                 ,ims,ime, jms,jme, kms,kme                        &
                 ,i_start,i_end, j_start,j_end, kts,kte, num_tiles &
             ! Optional
                 ,hol, mol, regime                                 &
             ! Optional gravity-wave drag             
                 ,gwd_opt,gwd_diags                                &
                 ,dtaux3d,dtauy3d                                  &
                 ,dusfcg,dvsfcg,var2d,oc12d                        &
                 ,oa1,oa2,oa3,oa4,ol1,ol2,ol3,ol4                  &
                 ,sina,cosa                                        &
                 ,dtaux3d_ls,dtauy3d_ls                            &
                 ,dtaux3d_bl,dtauy3d_bl                            &
                 ,dtaux3d_ss,dtauy3d_ss                            &
                 ,dtaux3d_fd,dtauy3d_fd                            &
                 ,dusfcg_ls,dvsfcg_ls                              &
                 ,dusfcg_bl,dvsfcg_bl                              &
                 ,dusfcg_ss,dvsfcg_ss                              &
                 ,dusfcg_fd,dvsfcg_fd                              &
                 ,var2dls,oc12dls                                  &
                 ,oa1ls,oa2ls,oa3ls,oa4ls,ol1ls,ol2ls,ol3ls,ol4ls  &
                 ,var2dss,oc12dss                                  &
                 ,oa1ss,oa2ss,oa3ss,oa4ss,ol1ss,ol2ss,ol3ss,ol4ss  &
             !  Optional moisture tracers
                 ,qv_curr, qc_curr, qr_curr                        &
                 ,qi_curr, qs_curr, qg_curr                        &
                 ,rqvblten,rqcblten,rqiblten                       &
                 ,rqrblten,rqsblten,rqgblten                       &
             !  Optional aerosol
                 ,qnwfa_curr,f_qnwfa                               &
                 ,qnifa_curr,f_qnifa                               &
                 ,qnbca_curr,f_qnbca                               &
             !  Optional moisture tracer flags
                 ,f_qv,f_qc,f_qr                                   &
                 ,f_qi,f_qs,f_qg                                   &
! variables added for BEP
               ,frc_urb2d                                  &
               ,a_u_bep,a_v_bep,a_t_bep,a_q_bep            &
               ,b_u_bep,b_v_bep,b_t_bep,b_q_bep            &
               ,sf_bep,vl_bep                              &
               ,sf_sfclay_physics,sf_urban_physics         &
               ,tke_pbl,diss_pbl,tpe_pbl                   &
               ,tke_adv,diss_adv,tpe_adv                   &
               ,pr_pbl,el_pbl                              &
               ,wu_tur,wv_tur,wt_tur,wq_tur                &
! variables added for AHE
               , gmt, xtime, julday, julyr, ahe &
               , distributed_ahe_opt &
! variables  for GBM PBL
               ,exch_tke, rthraten                         &
               ,a_e_bep,b_e_bep,dlg_bep,dl_u_bep           &
               ,mfshconv, massflux_EDKF, entr_EDKF, detr_EDKF    & 
               ,thl_up, thv_up, rt_up ,rv_up, rc_up, u_up, v_up    &
               ,frac_up,rc_mf                                      & 
! Wind Turbine Parameterizations
               ,phb,xlat_u,xlong_u,xlat_v,xlong_v,id                 &
! WRF-Solar EPS
                 ,multi_perturb, pert_mynn                         &
                 ,perts_qvapor                                     &
                 ,perts_qcloud                                     &
                 ,perts_th                                         &
                 ,perts_tke                                        &
                 ,pert_mynn_qv, pert_mynn_qc, pert_mynn_t          &
                 ,pert_mynn_qke                                    &
! variables required for camuwpbl scheme
               , z_at_w,cldfra_old_mp,cldfra, rthratenlw             &
               , tauresx2d,tauresy2d                                 &
               , tpert2d,qpert2d,wpert2d,wsedl3d                     &
               , turbtype3d,smaw3d                                   &
               , fnm,fnp                                             &
! variables required for camuwpbl scheme (optional)               
               ,qnc_curr,f_qnc,qni_curr,f_qni,rqniblten              &
               ,IS_CAMMGMP_USED                                      &
! for grims shallow convection with ysupbl/MYNN
               , wstar,delta                                         &
! for pbl mixing of scalars and tracers
     &        ,scalar,scalar_tend,num_scalar                         &
     &        ,tracer,tracer_tend,num_tracer                         &
     &        ,scalar_pblmix,tracer_pblmix                           &
#if (WRF_CHEM == 1)
              ,mynn_chem_vertmx,chem,vd,nchem,kdvel                  &
     &        ,ndvel,num_vert_mix                                    &
#endif
!
! FASDAS
!
              ,QNORM, fasdas           &
!
! END FASDAS
!
                                                                     )
       
!------------------------------------------------------------------
#if (EM_CORE==1)
   USE module_state_description, ONLY :                            &
                   YSUSCHEME,MRFSCHEME,GFSSCHEME,MYJPBLSCHEME,ACMPBLSCHEME,&
                   QNSEPBLSCHEME,MYNNPBLSCHEME,BOULACSCHEME,         &
                   CAMUWPBLSCHEME,BEPSCHEME,BEP_BEMSCHEME,MYJSFCSCHEME, &
                   FITCHSCHEME,SHINHONGSCHEME,                       &
                   TEMFPBLSCHEME,GBMPBLSCHEME,EEPSSCHEME,KEPSSCHEME,                  &
                   MAVSCHEME,  & ! Yulong add for WLM
                   CAMMGMPSCHEME,p_qi,p_qni,p_qnc,param_first_scalar,& !CAMMGMPSCHEME, p_qni,p_qnc is used for camuwpbl scheme
                   p_qnwfa,p_qnifa,p_qnbca
#if ( WRFPLUS == 1 )
   USE module_state_description, ONLY : SURFDRAGSCHEME
#endif
#else
   USE module_state_description, ONLY :                            &
                   YSUSCHEME,MRFSCHEME,GFSSCHEME,MYJPBLSCHEME,ACMPBLSCHEME &
                   , QNSEPBLSCHEME, p_qi,param_first_scalar &
                   , TEMFPBLSCHEME, GFSEDMFSCHEME           &
                   , CAMUWPBLSCHEME                                       &
                   , FITCHSCHEME, SHINHONGSCHEME                          &
                   , MAVSCHEME  ! Yulong add for WLM
                   , GBMPBLSCHEME, MYJSFCSCHEME
#endif

   USE module_model_constants
   USE module_gpu_work, ONLY : work_p3_pbl_u_phytmp, work_p3_pbl_v_phytmp,     &
                               work_p3_pbl_tke_windfarm,                       &
                               work_p3_pbl_rqncblten, work_p3_pbl_rqnwfablten, &
                               work_p3_pbl_rqnifablten, work_p3_pbl_rqnbcablten
#ifdef WRF_GPU
   USE module_gpu_work, ONLY : work_p3_pbl_tskold, work_p3_pbl_ustold,         &
                               work_p3_pbl_zntold, work_p3_pbl_psfc
   USE module_gpu_route, ONLY : gpu_on, gpu_island, gpu_world_host, R_PBL_DRIVER
   USE module_gpu_callcheck
#endif

! *** add new modules of schemes here

   USE module_bl_myjpbl
   USE module_bl_qnsepbl
   USE module_bl_ysu
   USE module_bl_shinhong
   USE module_bl_mrf
   USE module_bl_gfs
   USE module_bl_acm
   USE module_bl_gwdo
   USE module_bl_gwdo_gsl
   USE module_bl_myjurb
   USE module_bl_boulac
#if ( WRFPLUS == 1 )
   USE module_bl_surface_drag
#endif
   USE module_bl_camuwpbl_driver, only:CAMUWPBL
   USE module_bl_temf
   USE module_bl_mfshconvpbl
   USE module_bl_gbmpbl
#if (EM_CORE==1)
   USE module_bl_mynn_wrapper
   USE module_bl_eeps
   USE module_bl_keps
   USE module_bl_fogdes
   USE module_wind_fitch
   USE module_wind_mav ! Yulong add for WLM
#endif
   use module_ra_gfdleta, only: cal_mon_day

   !  This driver calls subroutines for the PBL parameterizations.
   !
   !  pbl scheme:
   !      1. ysupbl
   !      2. myjpbl
   !      4. qnsepbl
   !      5. mynnpbl2
   !      6. mynnpbl3
   !      7. acmpbl
   !      8. boulacpbl
   !      9. camuwpbl
   !      10. temfpbl
   !      11. shinhongpbl
   !      17. kepsstpe
   !      98. surface_drag
   !      99. mrfpbl
   !      12. gbmpbl
   !
!------------------------------------------------------------------
   IMPLICIT NONE
!======================================================================
! Grid structure in physics part of WRF
!----------------------------------------------------------------------
! The horizontal velocities used in the physics are unstaggered
! relative to temperature/moisture variables. All predicted
! variables are carried at half levels except w, which is at full
! levels. Some arrays with names (*8w) are at w (full) levels.
!
!----------------------------------------------------------------------
! In WRF, kms (smallest number) is the bottom level and kme (largest
! number) is the top level.  In your scheme, if 1 is at the top level,
! then you have to reverse the order in the k direction.
!
!         kme      -   half level (no data at this level)
!         kme    ----- full level
!         kme-1    -   half level
!         kme-1  ----- full level
!         .
!         .
!         .
!         kms+2    -   half level
!         kms+2  ----- full level
!         kms+1    -   half level
!         kms+1  ----- full level
!         kms      -   half level
!         kms    ----- full level
!
!======================================================================
! Definitions
!-----------
! Rho_d      dry density (kg/m^3)
! Theta_m    moist potential temperature (K)
! Qv         water vapor mixing ratio (kg/kg)
! Qc         cloud water mixing ratio (kg/kg)
! Qr         rain water mixing ratio (kg/kg)
! Qi         cloud ice mixing ratio (kg/kg)
! Qs         snow mixing ratio (kg/kg)
! QNC        cloud Liq number concentration (#/kg) !For CAMUWPBL scheme
! QNI        cloud ice number concentration (#/kg) !For CAMUWPBL scheme
!-----------------------------------------------------------------
!-- RUBLTEN       U tendency due to 
!                 PBL parameterization (m/s^2)
!-- RVBLTEN       V tendency due to 
!                 PBL parameterization (m/s^2)
!-- RTHBLTEN      Theta tendency due to 
!                 PBL parameterization (K/s)
!-- RQVBLTEN      Qv tendency due to 
!                 PBL parameterization (kg/kg/s)
!-- RQCBLTEN      Qc tendency due to 
!                 PBL parameterization (kg/kg/s)
!-- RQIBLTEN      Qi tendency due to 
!                 PBL parameterization (kg/kg/s)
!-- RQNIBLTEN     Qni tendency due to 
!                 PBL parameterization (#/kg/s) !For CAMUWPBL scheme
!-- id            WRF grid id  (optional, only needed by turbine drag schemes)
!-- itimestep     number of time steps
!-- GLW           downward long wave flux at ground surface (W/m^2)
!-- GSW           downward short wave flux at ground surface (W/m^2)
!-- EMISS         surface emissivity (between 0 and 1)
!-- TSK           surface temperature (K)
!-- TMN           soil temperature at lower boundary (K)
!-- XLAND         land mask (1 for land, 2 for water)
!-- ZNT           thermal roughness length (m)
!-- MZNT          momentum roughness length (m)
!-- MAVAIL        surface moisture availability (between 0 and 1)
!-- UST           u* in similarity theory (m/s)
!-- MOL           T* (similarity theory) (K)
!-- HOL           PBL height over Monin-Obukhov length
!-- PBLH          PBL height (m)
!-- CAPG          heat capacity for soil (J/K/m^3)
!-- THC           thermal inertia (Cal/cm/K/s^0.5)
!-- SNOWC         flag indicating snow coverage (1 for snow cover)
!-- HFX           upward heat flux at the surface (W/m^2)
!-- QFX           upward moisture flux at the surface (kg/m^2/s)
!-- REGIME        flag indicating PBL regime (stable, unstable, etc.)
!-- exch_m        exchange coefficient for momentum, m^2/s
!-- exch_h        exchange coefficient for heat, K m/s 
!-- exch_tke      exchange coeff. for TKE [enhanced], m^2/s (gbmpbl scheme)
!-- rthraten      tendency from radiation, used in GBM PBL scheme
!-- akhs          sfc exchange coefficient of heat/moisture from MYJ
!-- akms          sfc exchange coefficient of momentum from MYJ
!-- tke_pbl       turbulence kinetic energy from PBL schemes (m^2/s^2)
!-- el_pbl        length scale from PBL schemes (m)
!-- wu_tur        turbulent flux of momentum (x) (m^2/s^2)
!-- wv_tur        turbulent flux of momentum (y) (m^2/s^2)
!-- wt_tur        turbulent flux of potential temperature  (K m/s)
!-- wq_tur        turbulent flux of water vapor  (- m/s)
!-- te_temf       Total energy from TEMF BL scheme
!-- km_temf       Exchange coefficient for momentum from TEMF BL scheme
!-- kh_temf       Exchange coefficient for heat from TEMF BL scheme
!-- shf_temf      Sensible heat flux from TEMF BL scheme
!-- qf_temf       Water vapor flux from TEMF BL scheme
!-- uw_temf       Momentum flux in U direction from TEMF BL scheme
!-- vw_temf       Momentum flux in V direction from TEMF BL scheme
!-- wupd_temf     Updraft velocity from TEMF BL scheme
!-- mf_temf       Mass flux from TEMF BL scheme
!-- thup_temf     Updraft thetal from TEMF BL scheme
!-- qtup_temf     Updraft qt from TEMF BL scheme
!-- qlup_temf     Updraft ql from TEMF BL scheme
!-- cf3d_temf     3D cloud fraction from TEMF PBL
!-- cfm_temf      Column cloud fraction from TEMF PBL
!-- exch_temf     Surface exchange coefficient (as for moisture) from TEMF surface layer scheme
!-- flhc          Surface exchange coefficient for heat (for TEMF)
!-- flqc          Surface exchange coefficient for moisture (for TEMF)
!-- thz0          potential temperature at roughness length (K)
!-- uz0           u wind component at roughness length (m/s)
!-- vz0           v wind component at roughness length (m/s)
!-- qsfc          specific humidity at lower boundary (kg/kg)
!-- UOCE          sea surface zonal currents (m s-1)
!-- VOCE          sea surface meridional currents (m s-1)
!-- th2           diagnostic 2-m theta from surface layer and lsm
!-- t2            diagnostic 2-m temperature from surface layer and lsm
!-- q2            diagnostic 2-m mixing ratio from surface layer and lsm
!-- lowlyr        index of lowest model layer above ground
!-- rr            dry air density (kg/m^3)
!-- u_phy         u-velocity interpolated to theta points (m/s)
!-- v_phy         v-velocity interpolated to theta points (m/s)
!-- th_phy        potential temperature (K)
!-- p_phy         pressure (Pa)
!-- pi_phy        exner function (dimensionless)
!-- p8w           pressure at full levels (Pa)
!-- t_phy         temperature (K)
!-- dz8w          dz between full levels (m)
!-- z             height above sea level (m)
!-- DX            horizontal space interval (m)
!-- DT            time step (second)
!-- n_moist       number of moisture species
!-- PSFC          pressure at the surface (Pa)
!-- TSLB          
!-- ZS
!-- DZS
!-- num_soil_layers number of soil layer
!-- IFSNOW      ifsnow=1 for snow-cover effects
!-- z_at_w      Height above sea level at layer interfaces (m) 
!-- cldfra      Cloud fraction [unitless]
!-- cldfra_old_mp      Cloud fraction [unitless]
!-- rthratenlw  Tendency for LW ( K/s)
!-- tauresx2d   X-COMP OF RESIDUAL STRESS(m^2/s^2)
!-- tauresy2d   Y-COMP OF RESIDUAL STRESS(m^2/s^2)
!-- tpert2d     Convective temperature excess (K)
!-- qpert2d     Convective humidity excess (kg/kg)
!-- wpert2d     Turbulent velocity excess (m/s)
!-- wsedl3d     Sedimentation velocity of stratiform liquid cloud droplet (m/s)
!-- turbtype3d  Turbulent interface types [ no unit ]  
!-- smaw3d      Normalized Galperin instability function for momentum  ( 0<= <=4.964 and 1 at neutral ) [no units]
!
!-- P_QV          species index for water vapor
!-- P_QC          species index for cloud water
!-- P_QR          species index for rain water
!-- P_QI          species index for cloud ice
!-- P_QNC         species index for cloud liq number concentration !For CAMUWPBL scheme
!-- P_QNI         species index for cloud ice number concentration !For CAMUWPBL scheme
!-- P_QS          species index for snow
!-- P_QG          species index for graupel
!-- ids           start index for i in domain
!-- ide           end index for i in domain
!-- jds           start index for j in domain
!-- jde           end index for j in domain
!-- kds           start index for k in domain
!-- kde           end index for k in domain
!-- ims           start index for i in memory
!-- ime           end index for i in memory
!-- jms           start index for j in memory
!-- jme           end index for j in memory
!-- kms           start index for k in memory
!-- kme           end index for k in memory
!-- jts           start index for j in tile
!-- jte           end index for j in tile
!-- kts           start index for k in tile
!-- kte           end index for k in tile
!
!******************************************************************
!------------------------------------------------------------------ 
!


   INTEGER,    INTENT(IN   )    ::     bl_pbl_physics, ra_lw_physics,sf_sfclay_physics,sf_urban_physics,windfarm_opt
   INTEGER,    INTENT(IN   )    ::     ysu_topdown_pblmix
   INTEGER,    OPTIONAL,  INTENT(IN   )    ::     shinhong_tke_diag
   INTEGER,    OPTIONAL,  INTENT(IN   )    ::     scalar_pblmix, tracer_pblmix

   INTEGER,    INTENT(IN   )    ::     ids,ide, jds,jde, kds,kde, &
                                       ims,ime, jms,jme, kms,kme, &
                                       kts,kte, num_tiles
   INTEGER,    INTENT(IN   )    ::     num_scalar, num_tracer

   INTEGER, DIMENSION(num_tiles), INTENT(IN) ::                   &
  &                                    i_start,i_end,j_start,j_end

   INTEGER,    INTENT(IN   )    ::     itimestep,STEPBL
   INTEGER,    DIMENSION( ims:ime , jms:jme ),                    &
               INTENT(IN   )    ::                        LOWLYR
!
   LOGICAL,      INTENT(IN   )    ::   warm_rain
   LOGICAL,      INTENT(IN   )    ::   is_CAMMGMP_used !BSINGH:01/31/2013: Added for CAMUWPBL
   LOGICAL,    OPTIONAL,   INTENT(IN   )    ::   restart,cycling !used by mynn

   REAL,       DIMENSION( kms:kme ),                              &
               OPTIONAL, INTENT(IN   )    ::               znu,   &
                                                           znw
!
   REAL,       INTENT(IN   )    ::     DT,DX,DY
   REAL,       DIMENSION( ims:ime, jms:jme ), INTENT(IN) , OPTIONAL :: &
                                                dx2d, area2d
   REAL,       INTENT(IN   ),OPTIONAL    ::     bldt
   REAL,       INTENT(IN   ),OPTIONAL    ::     curr_secs
   LOGICAL,    INTENT(IN   ),OPTIONAL    ::     adapt_step_flag
   REAL,       INTENT(INOUT),OPTIONAL    ::     bldtacttime  
! Optional for Wind Turbine Parameterizations
   REAL, DIMENSION( ims:ime, kms:kme ,jms:jme ), &
         INTENT(IN), OPTIONAL    :: phb
   REAL, DIMENSION( ims:ime, jms:jme ), &
         INTENT(IN), OPTIONAL    :: xlat_u,xlong_u,xlat_v,xlong_v

   ! Yulong add for WLM
   INTEGER,    INTENT(IN   )    ::     windfarm_wake_model, windfarm_overlap_method

   REAL,       DIMENSION( ims:ime, kms:kme ,jms:jme ),            &
               INTENT(IN), OPTIONAL    :: w
!
   REAL,       DIMENSION( ims:ime, kms:kme, jms:jme ),            &
               INTENT(IN   )    ::                         p_phy, &
                                                          pi_phy, &
                                                             p8w, &
                                                             rho, &
                                                           t_phy, &
                                                           u_phy, &
                                                           v_phy, &
                                                            dz8w, &
                                                               z
  REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) :: th_phy

! WRF-Solar EPS
   integer, intent (in) :: multi_perturb
   LOGICAL, intent (in) :: pert_mynn
   real, intent (in) :: pert_mynn_qv, pert_mynn_qc, pert_mynn_t, pert_mynn_qke
   real, dimension(ims:ime, kms:kme, jms:jme), optional, intent (in) :: perts_qvapor, &
       perts_qcloud, perts_th, perts_tke

!1D variables required for CAMUWPBL scheme
   REAL , DIMENSION( kms:kme ) ,                                      &
        INTENT(IN   ) , OPTIONAL ::                                        fnm,  & !Factors for interpolation at "w" grid (interfaces)
                                                                fnp                                                                  
!3D Variables for camuwpbl scheme
    REAL,       DIMENSION( ims:ime, kms:kme, jms:jme ),           &
               INTENT(IN   ), OPTIONAL    ::              z_at_w, &
                                                   cldfra_old_mp, &
                                                          cldfra, &
                                                      rthratenlw, &
                                                      wsedl3d

!For EEPS PBL scheme
    REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ),            &
               INTENT(INOUT   )    ::            pek, pep
    REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ),        &
               INTENT(INOUT) ::                  pek_adv,pep_adv

!2D Variables required by camuwpbl scheme
    REAL,       DIMENSION( ims:ime , jms:jme ),                   &
               INTENT(INOUT   ), OPTIONAL    ::        tauresx2d, &
                                                       tauresy2d, &
                                                         tpert2d, &
                                                         qpert2d, &
                                                         wpert2d


!3D Variables for camuwpbl scheme - out
    REAL,       DIMENSION( ims:ime, kms:kme, jms:jme ),           &
               INTENT(OUT) , OPTIONAL   ::                      turbtype3d, &
                                                          smaw3d
!
! for grims shallow convection with ysupbl
!
    REAL,      DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT   ), OPTIONAL    ::          wstar
    REAL,      DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT   ), OPTIONAL    ::            delta
!
   REAL,       DIMENSION( ims:ime , jms:jme ),                    &
               INTENT(IN   )    ::                         XLAND, &
                                                              HT, &
                                                            PSIM, &
                                                            PSIH, &
                                                              FM, &
                                                             FHH, &
                                                          GZ1OZ0, &
                                                              BR, &
                                                               F, &
                                                         CHKLOWQ

!
   REAL,       DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)    ::                           TSK, &
                                                             UST, &
                                                            PBLH, &
                                                             HFX, &
                                                             QFX, &
                                                             ZNT, &
                                                            QSFC, &
                                                            AKHS, &
                                                            AKMS, &
                                                           MIXHT, &
                                                             QZ0, &
                                                            THZ0, &
                                                             UZ0, &
                                                             VZ0, &
                                                              CT, &
                                                          GRDFLX, &
                                                             U10, &
                                                             V10, &
                                                            UOCE, &
                                                            VOCE, &
                                                              T2, &
                                                           POWER, &
                                                            WSPD
   REAL,       DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)    ::                     HPBL_HOLD

!
   REAL,       DIMENSION( ims:ime, kms:kme, jms:jme ),            &
               INTENT(INOUT)    ::                       RUBLTEN, &
                                                         RVBLTEN, &
                                                        RTHBLTEN, &
                                           EXCH_H,EXCH_M,TKE_PBL, &
                                                DISS_PBL,TPE_PBL, &
                                        TKE_ADV,DISS_ADV,TPE_ADV, &
                                                 PR_PBL,RTHRATEN

 REAL,       DIMENSION( ims:ime, kms:kme, jms:jme ),            &
               INTENT(OUT)    ::                       WU_TUR,WV_TUR,WT_TUR,WQ_TUR
!

!MYNN
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ),     &
          INTENT(INOUT) ::        tsq,qsq,cov, & !,k_m,k_h,k_q &
                                  qke,Sh3d,Sm3d,               &
                                  dqke,qWT,qSHEAR,qBUOY,qDISS, &
                                  qc_bl,qi_bl,cldfra_bl

   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ),     &
          INTENT(INOUT) ::         edmf_a,edmf_w,edmf_thl,     & !JOE- MYNN edmf
                                   edmf_qt,edmf_ent,edmf_qc,   & !JOE- MYNN edmf
                                   sub_thl3D,sub_sqv3D,        &
                                   det_thl3D,det_sqv3D

   INTEGER, OPTIONAL, INTENT(IN)  :: grav_settling,            &
                                     bl_mynn_cloudpdf,         &
                                     bl_mynn_mixlength,        &
                                     bl_mynn_edmf,             &
                                     bl_mynn_edmf_mom,         &
                                     bl_mynn_edmf_tke,         &
                                     bl_mynn_mixscalars,       &
                                     bl_mynn_output,           &
                                     bl_mynn_cloudmix,         &
                                     bl_mynn_mixqt,            &
                                     icloud_bl,                &
                                     tke_budget

   REAL, OPTIONAL, INTENT(IN)  :: bl_mynn_closure

   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), &
        & INTENT(INOUT) :: qke_adv
   LOGICAL, OPTIONAL, INTENT(IN) :: bl_mynn_tkeadvect

   REAL, DIMENSION( ims:ime , jms:jme ), OPTIONAL,              &
        &    INTENT(INOUT)::                               vdfg

   INTEGER, OPTIONAL, DIMENSION( ims:ime , jms:jme ),           &
        &    INTENT(OUT) ::                          ktop_plume
   REAL, OPTIONAL, DIMENSION( ims:ime , jms:jme ),              &
        &    INTENT(OUT) ::           maxwidth,maxMF,ztop_plume

    REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ),     &
           INTENT(INOUT) ::         qnwfa_curr,qnifa_curr,qnbca_curr

   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), &
        & INTENT(INOUT) ::  exch_tke      ! for GBM PBL scheme


   INTEGER, OPTIONAL :: id

   REAL,    DIMENSION( ims:ime , jms:jme ), &
        &OPTIONAL, INTENT(IN) ::  &
        & qcg,  ch
   REAL,    DIMENSION( ims:ime , jms:jme ), &
        &OPTIONAL, INTENT(INOUT) ::  rmol
   


!
   REAL,       DIMENSION( ims:ime, kms:kme, jms:jme ),            &
               INTENT(OUT)    ::                          EL_PBL

   REAL, INTENT(IN) :: gmt, xtime
   INTEGER,  INTENT(IN) :: julday, julyr
   REAL, OPTIONAL, DIMENSION( ims:ime, 0:287, jms:jme ), INTENT(IN)  :: ahe
   INTEGER, INTENT(IN) :: distributed_ahe_opt

   REAL ,                             INTENT(IN   )  ::  u_frame, &
                                                         v_frame
!

   INTEGER,    DIMENSION( ims:ime , jms:jme ),                    &
               INTENT(INOUT) ::                             KPBL

   REAL,       DIMENSION( ims:ime , jms:jme ),                    &
               INTENT(IN)    :: XICE, SNOW, LH

   ! Stochastic parameter perturbations
   INTEGER,    INTENT(IN), OPTIONAL              ::             spp_pbl
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ),INTENT(IN),OPTIONAL ::pattern_spp_pbl

! Bep changes: variable added for urban
   real, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) ::FRC_URB2D   ! URBAN Landuse fraction
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::a_u_bep        ! Implicit component for the momemtum in X-direction
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::a_v_bep        ! Implicit component for the momemtum in Y-direction
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::a_t_bep        ! Implicit component for the Pot. Temp.
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::a_q_bep        ! Implicit component for Moisture

   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::a_e_bep        ! Implicit component for the TKE
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::b_u_bep        ! Explicit component for the momemtum in X-direction
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::b_v_bep        ! Explicit component for the momemtum in Y-direction
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::b_t_bep        ! Explicit component for the Pot. Temp.
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::b_q_bep        ! Explicit component for Moisture

   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::b_e_bep        ! Explicit component for the TKE

   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::dlg_bep        ! Height above ground (L_ground in formula (24) of the BLM paper). 
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::dl_u_bep        ! Length scale (lb in formula (22) ofthe BLM paper).
! urban surface and volumes        
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::sf_bep           ! surfaces
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::vl_bep            ! volumes
 
! Bep changes end
!  New variables for TEMF scheme
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ),            &
               INTENT(INOUT) :: te_temf
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ),            &
               INTENT(  OUT) :: km_temf, kh_temf,        &
                         shf_temf,qf_temf,uw_temf,vw_temf,        &
                         wupd_temf,mf_temf,thup_temf,qtup_temf,   &
                         qlup_temf,cf3d_temf
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ),            &
               INTENT(INOUT) :: flhc,flqc
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ),            &
               INTENT(  OUT) :: hd_temf, lcl_temf, hct_temf, cfm_temf
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ),            &
               INTENT(INOUT) :: exch_temf

!
!
! Optional
!
!
! Flags relating to the optional tendency arrays declared above
! Models that carry the optional tendencies will provdide the
! optional arguments at compile time; these flags all the model
! to determine at run-time whether a particular tracer is in
! use or not.
!
   LOGICAL, INTENT(IN), OPTIONAL ::                             &
                                                      f_qv      &
                                                     ,f_qc      &
                                                     ,f_qr      &
                                                     ,f_qi      &
                                                     ,f_qs      &
                                                     ,f_qg      &
                                                     ,f_qnc     & !used in CAMUWPBL
                                                     ,f_qni     & !used in CAMUWPBL
                                                     ,f_qnwfa   &
                                                     ,f_qnifa   &
                                                     ,f_qnbca

   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ),                 &
         OPTIONAL, INTENT(INOUT) ::                              &
                      ! optional moisture tracers
                      ! 2 time levels; if only one then use CURR
                      qv_curr, qc_curr, qr_curr                  &
                     ,qi_curr, qs_curr, qg_curr                  &
                     ,qnc_curr,qni_curr                          & !used in CAMUWPBL
                     ,rqvblten,rqcblten,rqrblten                 &
                     ,rqiblten,rqsblten,rqgblten,rqniblten         !rqniblten  used in CAMUWPBL

   ! P1.7: was automatic (ims:ime, kms:kme, jms:jme); local, added for MYNN
   REAL, DIMENSION(:,:,:), POINTER, CONTIGUOUS :: rqncblten, rqnwfablten,     &
                                                   rqnifablten, rqnbcablten

   REAL,       DIMENSION( ims:ime, jms:jme )                    , &
               OPTIONAL                                         , &
               INTENT(INOUT)    ::                           HOL, &
                                                             MOL, &
                                                          REGIME
   REAL,       DIMENSION( ims:ime, jms:jme )                    , &
               OPTIONAL                                         , &
               INTENT(IN)    ::                           mut
!
   INTEGER,    OPTIONAL, INTENT(IN)    ::               gwd_opt,gwd_diags
   REAL,       OPTIONAL, INTENT(IN)    ::               p_top
!
  real,   dimension( ims:ime, kms:kme, jms:jme )                             , &
          optional                                                           , &
             intent(inout  )   :: dtaux3d,dtauy3d,                             &
                                  dtaux3d_ls,dtauy3d_ls,dtaux3d_bl,dtauy3d_bl, &
                                  dtaux3d_ss,dtauy3d_ss,dtaux3d_fd,dtauy3d_fd

!
  real,   dimension( ims:ime, jms:jme )                                      , &
          optional                                                           , &
             intent(inout  )   :: dusfcg,dvsfcg,                               &
                                  dusfcg_ls,dvsfcg_ls,dusfcg_bl,dvsfcg_bl,     &
                                  dusfcg_ss,dvsfcg_ss,dusfcg_fd,dvsfcg_fd

!
  real,   dimension( ims:ime, jms:jme )                                      , &
          optional                                                           , &
             intent(in  )   ::                                          var2d, &
                                                                        oc12d, &
                                                              oa1,oa2,oa3,oa4, &
                                                              ol1,ol2,ol3,ol4, &
                                                                    sina,cosa

! Addtional topographic statistics based on 2.5min (large-scale) and 30sec orographic
! (small-scale) GSL drag schemes
  real,   dimension( ims:ime, jms:jme )                                      , &
          optional                                                           , &
             intent(in  )   ::                                                 &
                var2dls,oc12dls,                                               &
                oa1ls,oa2ls,oa3ls,oa4ls,ol1ls,ol2ls,ol3ls,ol4ls,               &
                var2dss,oc12dss,                                               &
                oa1ss,oa2ss,oa3ss,oa4ss,ol1ss,ol2ss,ol3ss,ol4ss

! paj
   REAL, OPTIONAL,   DIMENSION( ims:ime , jms:jme ),                    &  !mchen
               INTENT(IN   )    ::                        CTOPO, &
                                                          CTOPO2
   real, dimension (:, :, :), allocatable :: qke_tmp

! Variables and Diagnostic for QNSE and EDKF JP
   INTEGER, INTENT(IN) ::  mfshconv

   REAL,       DIMENSION( ims:ime, kms:kme, jms:jme ), OPTIONAL,  &
               INTENT(OUT) ::    massflux_EDKF, entr_EDKF, detr_EDKF & 
                                     ,thl_up, thv_up, rt_up       &
                                     ,rv_up, rc_up, u_up, v_up    &
                                     ,frac_up,rc_mf  

    REAL , OPTIONAL   ,DIMENSION(ims:ime,kms:kme,jms:jme,num_tracer),INTENT(INOUT)   :: tracer
    REAL , OPTIONAL   ,DIMENSION(ims:ime,kms:kme,jms:jme,num_tracer),INTENT(INOUT)   :: tracer_tend
    REAL , OPTIONAL   ,DIMENSION(ims:ime,kms:kme,jms:jme,num_scalar),INTENT(INOUT)   :: scalar
    REAL , OPTIONAL   ,DIMENSION(ims:ime,kms:kme,jms:jme,num_scalar),INTENT(INOUT)   :: scalar_tend

#if (WRF_CHEM == 1)
!   ACM Chem
    INTEGER, INTENT(IN) :: nchem, kdvel,ndvel,num_vert_mix
    REAL, INTENT(INOUT),  DIMENSION( ims:ime, kms:kme, jms:jme,nchem ) :: CHEM
    REAL, INTENT(IN)   ,  DIMENSION( ims:ime, kdvel, jms:jme, ndvel )  :: VD
    LOGICAL, INTENT(IN) :: mynn_chem_vertmx
#endif

!  LOCAL  VAR

   ! P1.7: was automatic (ims:ime, kms:kme, jms:jme)
   REAL,       DIMENSION(:,:,:), POINTER, CONTIGUOUS :: v_phytmp
   REAL,       DIMENSION(:,:,:), POINTER, CONTIGUOUS :: u_phytmp

#ifdef WRF_GPU
   REAL, DIMENSION(:,:), POINTER, CONTIGUOUS :: TSKOLD, USTOLD, ZNTOLD, PSFC
   REAL, DIMENSION( ims:ime, jms:jme ) :: ZOL
   LOGICAL :: gpu_isl
   LOGICAL :: has_rqcblten, has_rqvblten, has_rqiblten
   INTEGER :: ktend_pbl
   INTEGER, DIMENSION(num_tiles) :: i_start_h, i_end_h, j_start_h, j_end_h
#else
   REAL,       DIMENSION( ims:ime, jms:jme )          ::  TSKOLD, &
                                                          USTOLD, &
                                                          ZNTOLD, &
                                                             ZOL, &
                                                            PSFC
#endif

! make these allocatable depending on the setting of idiff
! Typically, we try to avoide allocating and deallocating local storage like this
! so as not to fragment the stack. But at this point, the idiff = 1 case is disabled
! (set to 0 for all cases) and has to be set manually by users who want to work with
! it.  When it becomes a more standard option, this should be redone, either defining
! these as state with package clauses to turn them on and off and passing them in,
! or pass in an integer flag that can be used to dimension the arrays to 1:1:1 as
! local variables.  JM 20100316

   REAL, ALLOCATABLE, DIMENSION( :, :, : )::a_u        ! Implicit component for the momemtum in X-direction
   REAL, ALLOCATABLE, DIMENSION( :, :, : )::a_v        ! Implicit component for the momemtum in Y-direction
   REAL, ALLOCATABLE, DIMENSION( :, :, : )::a_t        ! Implicit component for the Pot. Temp.
   REAL, ALLOCATABLE, DIMENSION( :, :, : )::a_q        ! Implicit component for the water vapor

   REAL, ALLOCATABLE, DIMENSION( :, :, : )::b_u        ! Explicit component for the momemtum in X-direction
   REAL, ALLOCATABLE, DIMENSION( :, :, : )::b_v        ! Explicit component for the momemtum in Y-direction
   REAL, ALLOCATABLE, DIMENSION( :, :, : )::b_t        ! Explicit component for the Pot. Temp.
   REAL, ALLOCATABLE, DIMENSION( :, :, : )::b_q        ! Explicit component for the water vapor

   REAL, ALLOCATABLE, DIMENSION( :, :, : )::sf         ! surfaces
   REAL, ALLOCATABLE, DIMENSION( :, :, : )::vl         ! volumes

   REAL    :: DTMIN,DTBL
!
   INTEGER :: initflag
!
   INTEGER :: i,J,K,NK,jj,ij,its,ite,jts,jte
   LOGICAL :: radiation
   LOGICAL :: flag_bep
   LOGICAL :: flag_myjsfc
   LOGICAL :: flag_qv, flag_qc, flag_qr, flag_qi, flag_qs, flag_qg, &
              flag_qnc,flag_qni, flag_qnwfa, flag_qnifa, flag_qnbca
   CHARACTER*256 :: message
   REAL    :: next_bl_time
   LOGICAL :: run_param , doing_adapt_dt , decided
   LOGICAL :: do_adapt
   integer iu_bep,iurb,idiff
   real seamask,thsk,zzz,unew,vnew,tnew,qnew,umom,vmom
   REAL :: z0,z1,z2,w1,w2
   ! P1.7: was automatic (ims:ime, kms:kme, jms:jme). Yulong add for WLM
   REAL, DIMENSION(:,:,:), POINTER, CONTIGUOUS :: TKE_windfarm
   INTEGER :: ihour, jmonth, jday
!
! FASDAS
!
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(  OUT) , OPTIONAL ::   QNORM
   INTEGER, INTENT(IN   )                                         ::   fasdas
   REAL                                                           ::   scrp1
!
! END FASDAS
!
! To accommodate shared physics
   character*256 :: errmsg
   integer :: errflg
!
!------------------------------------------------------------------
!
#ifdef WRF_GPU
   DO ij = 1, num_tiles
      i_start_h(ij) = i_start(ij)
      i_end_h(ij) = i_end(ij)
      j_start_h(ij) = j_start(ij)
      j_end_h(ij) = j_end(ij)
   END DO
#endif
!!!!!!!if using BEP set flag_bep to true
    SELECT CASE(sf_urban_physics)
      CASE (BEPSCHEME)
        flag_bep=.true.
      CASE (BEP_BEMSCHEME)
        flag_bep=.true.
      CASE DEFAULT
        flag_bep=.false.
    END SELECT

    SELECT CASE(sf_sfclay_physics)
      CASE (MYJSFCSCHEME)
         flag_myjsfc=.true.
      CASE DEFAULT
         flag_myjsfc=.false.
    END SELECT
!
  flag_qv = .FALSE. ; IF ( PRESENT( F_QV ) ) flag_qv = F_QV
  flag_qc = .FALSE. ; IF ( PRESENT( F_QC ) ) flag_qc = F_QC
  flag_qr = .FALSE. ; IF ( PRESENT( F_QR ) ) flag_qr = F_QR
  flag_qi = .FALSE. ; IF ( PRESENT( F_QI ) ) flag_qi = F_QI
  flag_qs = .FALSE. ; IF ( PRESENT( F_QS ) ) flag_qs = F_QS
  flag_qg = .FALSE. ; IF ( PRESENT( F_QG ) ) flag_qg = F_QG
  flag_qnc = .FALSE. ; IF ( PRESENT( F_QNC ) ) flag_qnc = F_QNC !Used in CAMUWPBL
  flag_qni = .FALSE. ; IF ( PRESENT( F_QNI ) ) flag_qni = F_QNI !Used in CAMUWPBL
  flag_qnwfa = .FALSE. ; IF ( PRESENT( F_QNWFA ) ) flag_qnwfa = F_QNWFA
  flag_qnifa = .FALSE. ; IF ( PRESENT( F_QNIFA ) ) flag_qnifa = F_QNIFA
  flag_qnbca = .FALSE. ; IF ( PRESENT( F_QNBCA ) ) flag_qnbca = F_QNBCA

  if (bl_pbl_physics .eq. 0) return

#ifdef WRF_GPU
99901 CONTINUE
      IF (gpu_cc_start(R_PBL_DRIVER)) THEN
        IF (PRESENT(bldtacttime)) CALL gpu_cc_save_r0(1, bldtacttime)
        CALL gpu_cc_save_r(2, rublten, SIZE(rublten,KIND=8))
        CALL gpu_cc_save_r(3, rvblten, SIZE(rvblten,KIND=8))
        CALL gpu_cc_save_r(4, rthblten, SIZE(rthblten,KIND=8))
        CALL gpu_cc_save_r(5, tsk, SIZE(tsk,KIND=8))
        CALL gpu_cc_save_r(6, znt, SIZE(znt,KIND=8))
        CALL gpu_cc_save_r(7, ust, SIZE(ust,KIND=8))
        CALL gpu_cc_save_r(8, pblh, SIZE(pblh,KIND=8))
        CALL gpu_cc_save_r(9, hfx, SIZE(hfx,KIND=8))
        CALL gpu_cc_save_r(10, qfx, SIZE(qfx,KIND=8))
        CALL gpu_cc_save_r(11, grdflx, SIZE(grdflx,KIND=8))
        CALL gpu_cc_save_r(12, hpbl_hold, SIZE(hpbl_hold,KIND=8))
        CALL gpu_cc_save_r(13, th_phy, SIZE(th_phy,KIND=8))
        CALL gpu_cc_save_r(14, exch_h, SIZE(exch_h,KIND=8))
        CALL gpu_cc_save_r(15, exch_m, SIZE(exch_m,KIND=8))
        CALL gpu_cc_save_r(16, akhs, SIZE(akhs,KIND=8))
        CALL gpu_cc_save_r(17, akms, SIZE(akms,KIND=8))
        CALL gpu_cc_save_r(18, thz0, SIZE(thz0,KIND=8))
        CALL gpu_cc_save_r(19, qz0, SIZE(qz0,KIND=8))
        CALL gpu_cc_save_r(20, uz0, SIZE(uz0,KIND=8))
        CALL gpu_cc_save_r(21, vz0, SIZE(vz0,KIND=8))
        CALL gpu_cc_save_r(22, qsfc, SIZE(qsfc,KIND=8))
        CALL gpu_cc_save_r(23, u10, SIZE(u10,KIND=8))
        CALL gpu_cc_save_r(24, v10, SIZE(v10,KIND=8))
        CALL gpu_cc_save_r(25, uoce, SIZE(uoce,KIND=8))
        CALL gpu_cc_save_r(26, voce, SIZE(voce,KIND=8))
        CALL gpu_cc_save_r(27, t2, SIZE(t2,KIND=8))
        CALL gpu_cc_save_r(28, wspd, SIZE(wspd,KIND=8))
        CALL gpu_cc_save_i(29, kpbl, SIZE(kpbl,KIND=8))
        CALL gpu_cc_save_r(30, mixht, SIZE(mixht,KIND=8))
        CALL gpu_cc_save_r(31, ct, SIZE(ct,KIND=8))
        CALL gpu_cc_save_r(32, power, SIZE(power,KIND=8))
        IF (PRESENT(te_temf)) CALL gpu_cc_save_r(33, te_temf, SIZE(te_temf,KIND=8))
        IF (PRESENT(km_temf)) CALL gpu_cc_save_r(34, km_temf, SIZE(km_temf,KIND=8))
        IF (PRESENT(kh_temf)) CALL gpu_cc_save_r(35, kh_temf, SIZE(kh_temf,KIND=8))
        IF (PRESENT(shf_temf)) CALL gpu_cc_save_r(36, shf_temf, SIZE(shf_temf,KIND=8))
        IF (PRESENT(qf_temf)) CALL gpu_cc_save_r(37, qf_temf, SIZE(qf_temf,KIND=8))
        IF (PRESENT(uw_temf)) CALL gpu_cc_save_r(38, uw_temf, SIZE(uw_temf,KIND=8))
        IF (PRESENT(vw_temf)) CALL gpu_cc_save_r(39, vw_temf, SIZE(vw_temf,KIND=8))
        IF (PRESENT(hd_temf)) CALL gpu_cc_save_r(40, hd_temf, SIZE(hd_temf,KIND=8))
        IF (PRESENT(lcl_temf)) CALL gpu_cc_save_r(41, lcl_temf, SIZE(lcl_temf,KIND=8))
        IF (PRESENT(hct_temf)) CALL gpu_cc_save_r(42, hct_temf, SIZE(hct_temf,KIND=8))
        IF (PRESENT(wupd_temf)) CALL gpu_cc_save_r(43, wupd_temf, SIZE(wupd_temf,KIND=8))
        IF (PRESENT(mf_temf)) CALL gpu_cc_save_r(44, mf_temf, SIZE(mf_temf,KIND=8))
        IF (PRESENT(thup_temf)) CALL gpu_cc_save_r(45, thup_temf, SIZE(thup_temf,KIND=8))
        IF (PRESENT(qtup_temf)) CALL gpu_cc_save_r(46, qtup_temf, SIZE(qtup_temf,KIND=8))
        IF (PRESENT(qlup_temf)) CALL gpu_cc_save_r(47, qlup_temf, SIZE(qlup_temf,KIND=8))
        IF (PRESENT(exch_temf)) CALL gpu_cc_save_r(48, exch_temf, SIZE(exch_temf,KIND=8))
        IF (PRESENT(cf3d_temf)) CALL gpu_cc_save_r(49, cf3d_temf, SIZE(cf3d_temf,KIND=8))
        IF (PRESENT(cfm_temf)) CALL gpu_cc_save_r(50, cfm_temf, SIZE(cfm_temf,KIND=8))
        IF (PRESENT(flhc)) CALL gpu_cc_save_r(51, flhc, SIZE(flhc,KIND=8))
        IF (PRESENT(flqc)) CALL gpu_cc_save_r(52, flqc, SIZE(flqc,KIND=8))
        IF (PRESENT(qke)) CALL gpu_cc_save_r(53, qke, SIZE(qke,KIND=8))
        IF (PRESENT(sh3d)) CALL gpu_cc_save_r(54, sh3d, SIZE(sh3d,KIND=8))
        IF (PRESENT(sm3d)) CALL gpu_cc_save_r(55, sm3d, SIZE(sm3d,KIND=8))
        IF (PRESENT(qke_adv)) CALL gpu_cc_save_r(56, qke_adv, SIZE(qke_adv,KIND=8))
        IF (PRESENT(tsq)) CALL gpu_cc_save_r(57, tsq, SIZE(tsq,KIND=8))
        IF (PRESENT(qsq)) CALL gpu_cc_save_r(58, qsq, SIZE(qsq,KIND=8))
        IF (PRESENT(cov)) CALL gpu_cc_save_r(59, cov, SIZE(cov,KIND=8))
        IF (PRESENT(rmol)) CALL gpu_cc_save_r(60, rmol, SIZE(rmol,KIND=8))
        IF (PRESENT(dqke)) CALL gpu_cc_save_r(61, dqke, SIZE(dqke,KIND=8))
        IF (PRESENT(qwt)) CALL gpu_cc_save_r(62, qwt, SIZE(qwt,KIND=8))
        IF (PRESENT(qshear)) CALL gpu_cc_save_r(63, qshear, SIZE(qshear,KIND=8))
        IF (PRESENT(qbuoy)) CALL gpu_cc_save_r(64, qbuoy, SIZE(qbuoy,KIND=8))
        IF (PRESENT(qdiss)) CALL gpu_cc_save_r(65, qdiss, SIZE(qdiss,KIND=8))
        IF (PRESENT(qc_bl)) CALL gpu_cc_save_r(66, qc_bl, SIZE(qc_bl,KIND=8))
        IF (PRESENT(qi_bl)) CALL gpu_cc_save_r(67, qi_bl, SIZE(qi_bl,KIND=8))
        IF (PRESENT(cldfra_bl)) CALL gpu_cc_save_r(68, cldfra_bl, SIZE(cldfra_bl,KIND=8))
        IF (PRESENT(edmf_a)) CALL gpu_cc_save_r(69, edmf_a, SIZE(edmf_a,KIND=8))
        IF (PRESENT(edmf_w)) CALL gpu_cc_save_r(70, edmf_w, SIZE(edmf_w,KIND=8))
        IF (PRESENT(edmf_thl)) CALL gpu_cc_save_r(71, edmf_thl, SIZE(edmf_thl,KIND=8))
        IF (PRESENT(edmf_qt)) CALL gpu_cc_save_r(72, edmf_qt, SIZE(edmf_qt,KIND=8))
        IF (PRESENT(edmf_ent)) CALL gpu_cc_save_r(73, edmf_ent, SIZE(edmf_ent,KIND=8))
        IF (PRESENT(edmf_qc)) CALL gpu_cc_save_r(74, edmf_qc, SIZE(edmf_qc,KIND=8))
        IF (PRESENT(sub_thl3d)) CALL gpu_cc_save_r(75, sub_thl3d, SIZE(sub_thl3d,KIND=8))
        IF (PRESENT(sub_sqv3d)) CALL gpu_cc_save_r(76, sub_sqv3d, SIZE(sub_sqv3d,KIND=8))
        IF (PRESENT(det_thl3d)) CALL gpu_cc_save_r(77, det_thl3d, SIZE(det_thl3d,KIND=8))
        IF (PRESENT(det_sqv3d)) CALL gpu_cc_save_r(78, det_sqv3d, SIZE(det_sqv3d,KIND=8))
        IF (PRESENT(vdfg)) CALL gpu_cc_save_r(79, vdfg, SIZE(vdfg,KIND=8))
        IF (PRESENT(maxwidth)) CALL gpu_cc_save_r(80, maxwidth, SIZE(maxwidth,KIND=8))
        IF (PRESENT(maxmf)) CALL gpu_cc_save_r(81, maxmf, SIZE(maxmf,KIND=8))
        IF (PRESENT(ztop_plume)) CALL gpu_cc_save_r(82, ztop_plume, SIZE(ztop_plume,KIND=8))
        IF (PRESENT(ktop_plume)) CALL gpu_cc_save_i(83, ktop_plume, SIZE(ktop_plume,KIND=8))
        IF (PRESENT(pek)) CALL gpu_cc_save_r(84, pek, SIZE(pek,KIND=8))
        IF (PRESENT(pep)) CALL gpu_cc_save_r(85, pep, SIZE(pep,KIND=8))
        IF (PRESENT(pek_adv)) CALL gpu_cc_save_r(86, pek_adv, SIZE(pek_adv,KIND=8))
        IF (PRESENT(pep_adv)) CALL gpu_cc_save_r(87, pep_adv, SIZE(pep_adv,KIND=8))
        IF (PRESENT(hol)) CALL gpu_cc_save_r(88, hol, SIZE(hol,KIND=8))
        IF (PRESENT(mol)) CALL gpu_cc_save_r(89, mol, SIZE(mol,KIND=8))
        IF (PRESENT(regime)) CALL gpu_cc_save_r(90, regime, SIZE(regime,KIND=8))
        IF (PRESENT(dtaux3d)) CALL gpu_cc_save_r(91, dtaux3d, SIZE(dtaux3d,KIND=8))
        IF (PRESENT(dtauy3d)) CALL gpu_cc_save_r(92, dtauy3d, SIZE(dtauy3d,KIND=8))
        IF (PRESENT(dusfcg)) CALL gpu_cc_save_r(93, dusfcg, SIZE(dusfcg,KIND=8))
        IF (PRESENT(dvsfcg)) CALL gpu_cc_save_r(94, dvsfcg, SIZE(dvsfcg,KIND=8))
        IF (PRESENT(dtaux3d_ls)) CALL gpu_cc_save_r(95, dtaux3d_ls, SIZE(dtaux3d_ls,KIND=8))
        IF (PRESENT(dtauy3d_ls)) CALL gpu_cc_save_r(96, dtauy3d_ls, SIZE(dtauy3d_ls,KIND=8))
        IF (PRESENT(dtaux3d_bl)) CALL gpu_cc_save_r(97, dtaux3d_bl, SIZE(dtaux3d_bl,KIND=8))
        IF (PRESENT(dtauy3d_bl)) CALL gpu_cc_save_r(98, dtauy3d_bl, SIZE(dtauy3d_bl,KIND=8))
        IF (PRESENT(dtaux3d_ss)) CALL gpu_cc_save_r(99, dtaux3d_ss, SIZE(dtaux3d_ss,KIND=8))
        IF (PRESENT(dtauy3d_ss)) CALL gpu_cc_save_r(100, dtauy3d_ss, SIZE(dtauy3d_ss,KIND=8))
        IF (PRESENT(dtaux3d_fd)) CALL gpu_cc_save_r(101, dtaux3d_fd, SIZE(dtaux3d_fd,KIND=8))
        IF (PRESENT(dtauy3d_fd)) CALL gpu_cc_save_r(102, dtauy3d_fd, SIZE(dtauy3d_fd,KIND=8))
        IF (PRESENT(dusfcg_ls)) CALL gpu_cc_save_r(103, dusfcg_ls, SIZE(dusfcg_ls,KIND=8))
        IF (PRESENT(dvsfcg_ls)) CALL gpu_cc_save_r(104, dvsfcg_ls, SIZE(dvsfcg_ls,KIND=8))
        IF (PRESENT(dusfcg_bl)) CALL gpu_cc_save_r(105, dusfcg_bl, SIZE(dusfcg_bl,KIND=8))
        IF (PRESENT(dvsfcg_bl)) CALL gpu_cc_save_r(106, dvsfcg_bl, SIZE(dvsfcg_bl,KIND=8))
        IF (PRESENT(dusfcg_ss)) CALL gpu_cc_save_r(107, dusfcg_ss, SIZE(dusfcg_ss,KIND=8))
        IF (PRESENT(dvsfcg_ss)) CALL gpu_cc_save_r(108, dvsfcg_ss, SIZE(dvsfcg_ss,KIND=8))
        IF (PRESENT(dusfcg_fd)) CALL gpu_cc_save_r(109, dusfcg_fd, SIZE(dusfcg_fd,KIND=8))
        IF (PRESENT(dvsfcg_fd)) CALL gpu_cc_save_r(110, dvsfcg_fd, SIZE(dvsfcg_fd,KIND=8))
        IF (PRESENT(qv_curr)) CALL gpu_cc_save_r(111, qv_curr, SIZE(qv_curr,KIND=8))
        IF (PRESENT(qc_curr)) CALL gpu_cc_save_r(112, qc_curr, SIZE(qc_curr,KIND=8))
        IF (PRESENT(qr_curr)) CALL gpu_cc_save_r(113, qr_curr, SIZE(qr_curr,KIND=8))
        IF (PRESENT(qi_curr)) CALL gpu_cc_save_r(114, qi_curr, SIZE(qi_curr,KIND=8))
        IF (PRESENT(qs_curr)) CALL gpu_cc_save_r(115, qs_curr, SIZE(qs_curr,KIND=8))
        IF (PRESENT(qg_curr)) CALL gpu_cc_save_r(116, qg_curr, SIZE(qg_curr,KIND=8))
        IF (PRESENT(rqvblten)) CALL gpu_cc_save_r(117, rqvblten, SIZE(rqvblten,KIND=8))
        IF (PRESENT(rqcblten)) CALL gpu_cc_save_r(118, rqcblten, SIZE(rqcblten,KIND=8))
        IF (PRESENT(rqiblten)) CALL gpu_cc_save_r(119, rqiblten, SIZE(rqiblten,KIND=8))
        IF (PRESENT(rqrblten)) CALL gpu_cc_save_r(120, rqrblten, SIZE(rqrblten,KIND=8))
        IF (PRESENT(rqsblten)) CALL gpu_cc_save_r(121, rqsblten, SIZE(rqsblten,KIND=8))
        IF (PRESENT(rqgblten)) CALL gpu_cc_save_r(122, rqgblten, SIZE(rqgblten,KIND=8))
        IF (PRESENT(qnwfa_curr)) CALL gpu_cc_save_r(123, qnwfa_curr, SIZE(qnwfa_curr,KIND=8))
        IF (PRESENT(qnifa_curr)) CALL gpu_cc_save_r(124, qnifa_curr, SIZE(qnifa_curr,KIND=8))
        IF (PRESENT(qnbca_curr)) CALL gpu_cc_save_r(125, qnbca_curr, SIZE(qnbca_curr,KIND=8))
        IF (PRESENT(frc_urb2d)) CALL gpu_cc_save_r(126, frc_urb2d, SIZE(frc_urb2d,KIND=8))
        IF (PRESENT(a_u_bep)) CALL gpu_cc_save_r(127, a_u_bep, SIZE(a_u_bep,KIND=8))
        IF (PRESENT(a_v_bep)) CALL gpu_cc_save_r(128, a_v_bep, SIZE(a_v_bep,KIND=8))
        IF (PRESENT(a_t_bep)) CALL gpu_cc_save_r(129, a_t_bep, SIZE(a_t_bep,KIND=8))
        IF (PRESENT(a_q_bep)) CALL gpu_cc_save_r(130, a_q_bep, SIZE(a_q_bep,KIND=8))
        IF (PRESENT(b_u_bep)) CALL gpu_cc_save_r(131, b_u_bep, SIZE(b_u_bep,KIND=8))
        IF (PRESENT(b_v_bep)) CALL gpu_cc_save_r(132, b_v_bep, SIZE(b_v_bep,KIND=8))
        IF (PRESENT(b_t_bep)) CALL gpu_cc_save_r(133, b_t_bep, SIZE(b_t_bep,KIND=8))
        IF (PRESENT(b_q_bep)) CALL gpu_cc_save_r(134, b_q_bep, SIZE(b_q_bep,KIND=8))
        IF (PRESENT(sf_bep)) CALL gpu_cc_save_r(135, sf_bep, SIZE(sf_bep,KIND=8))
        IF (PRESENT(vl_bep)) CALL gpu_cc_save_r(136, vl_bep, SIZE(vl_bep,KIND=8))
        CALL gpu_cc_save_r(137, tke_pbl, SIZE(tke_pbl,KIND=8))
        CALL gpu_cc_save_r(138, diss_pbl, SIZE(diss_pbl,KIND=8))
        CALL gpu_cc_save_r(139, tpe_pbl, SIZE(tpe_pbl,KIND=8))
        CALL gpu_cc_save_r(140, tke_adv, SIZE(tke_adv,KIND=8))
        CALL gpu_cc_save_r(141, diss_adv, SIZE(diss_adv,KIND=8))
        CALL gpu_cc_save_r(142, tpe_adv, SIZE(tpe_adv,KIND=8))
        CALL gpu_cc_save_r(143, pr_pbl, SIZE(pr_pbl,KIND=8))
        CALL gpu_cc_save_r(144, el_pbl, SIZE(el_pbl,KIND=8))
        CALL gpu_cc_save_r(145, wu_tur, SIZE(wu_tur,KIND=8))
        CALL gpu_cc_save_r(146, wv_tur, SIZE(wv_tur,KIND=8))
        CALL gpu_cc_save_r(147, wt_tur, SIZE(wt_tur,KIND=8))
        CALL gpu_cc_save_r(148, wq_tur, SIZE(wq_tur,KIND=8))
        IF (PRESENT(exch_tke)) CALL gpu_cc_save_r(149, exch_tke, SIZE(exch_tke,KIND=8))
        CALL gpu_cc_save_r(150, rthraten, SIZE(rthraten,KIND=8))
        IF (PRESENT(a_e_bep)) CALL gpu_cc_save_r(151, a_e_bep, SIZE(a_e_bep,KIND=8))
        IF (PRESENT(b_e_bep)) CALL gpu_cc_save_r(152, b_e_bep, SIZE(b_e_bep,KIND=8))
        IF (PRESENT(dlg_bep)) CALL gpu_cc_save_r(153, dlg_bep, SIZE(dlg_bep,KIND=8))
        IF (PRESENT(dl_u_bep)) CALL gpu_cc_save_r(154, dl_u_bep, SIZE(dl_u_bep,KIND=8))
        IF (PRESENT(massflux_edkf)) CALL gpu_cc_save_r(155, massflux_edkf, SIZE(massflux_edkf,KIND=8))
        IF (PRESENT(entr_edkf)) CALL gpu_cc_save_r(156, entr_edkf, SIZE(entr_edkf,KIND=8))
        IF (PRESENT(detr_edkf)) CALL gpu_cc_save_r(157, detr_edkf, SIZE(detr_edkf,KIND=8))
        IF (PRESENT(thl_up)) CALL gpu_cc_save_r(158, thl_up, SIZE(thl_up,KIND=8))
        IF (PRESENT(thv_up)) CALL gpu_cc_save_r(159, thv_up, SIZE(thv_up,KIND=8))
        IF (PRESENT(rt_up)) CALL gpu_cc_save_r(160, rt_up, SIZE(rt_up,KIND=8))
        IF (PRESENT(rv_up)) CALL gpu_cc_save_r(161, rv_up, SIZE(rv_up,KIND=8))
        IF (PRESENT(rc_up)) CALL gpu_cc_save_r(162, rc_up, SIZE(rc_up,KIND=8))
        IF (PRESENT(u_up)) CALL gpu_cc_save_r(163, u_up, SIZE(u_up,KIND=8))
        IF (PRESENT(v_up)) CALL gpu_cc_save_r(164, v_up, SIZE(v_up,KIND=8))
        IF (PRESENT(frac_up)) CALL gpu_cc_save_r(165, frac_up, SIZE(frac_up,KIND=8))
        IF (PRESENT(rc_mf)) CALL gpu_cc_save_r(166, rc_mf, SIZE(rc_mf,KIND=8))
        IF (PRESENT(id)) CALL gpu_cc_save_i0(167, id)
        IF (PRESENT(tauresx2d)) CALL gpu_cc_save_r(168, tauresx2d, SIZE(tauresx2d,KIND=8))
        IF (PRESENT(tauresy2d)) CALL gpu_cc_save_r(169, tauresy2d, SIZE(tauresy2d,KIND=8))
        IF (PRESENT(tpert2d)) CALL gpu_cc_save_r(170, tpert2d, SIZE(tpert2d,KIND=8))
        IF (PRESENT(qpert2d)) CALL gpu_cc_save_r(171, qpert2d, SIZE(qpert2d,KIND=8))
        IF (PRESENT(wpert2d)) CALL gpu_cc_save_r(172, wpert2d, SIZE(wpert2d,KIND=8))
        IF (PRESENT(turbtype3d)) CALL gpu_cc_save_r(173, turbtype3d, SIZE(turbtype3d,KIND=8))
        IF (PRESENT(smaw3d)) CALL gpu_cc_save_r(174, smaw3d, SIZE(smaw3d,KIND=8))
        IF (PRESENT(qnc_curr)) CALL gpu_cc_save_r(175, qnc_curr, SIZE(qnc_curr,KIND=8))
        IF (PRESENT(qni_curr)) CALL gpu_cc_save_r(176, qni_curr, SIZE(qni_curr,KIND=8))
        IF (PRESENT(rqniblten)) CALL gpu_cc_save_r(177, rqniblten, SIZE(rqniblten,KIND=8))
        IF (PRESENT(wstar)) CALL gpu_cc_save_r(178, wstar, SIZE(wstar,KIND=8))
        IF (PRESENT(delta)) CALL gpu_cc_save_r(179, delta, SIZE(delta,KIND=8))
        IF (PRESENT(scalar)) CALL gpu_cc_save_r(180, scalar, SIZE(scalar,KIND=8))
        IF (PRESENT(scalar_tend)) CALL gpu_cc_save_r(181, scalar_tend, SIZE(scalar_tend,KIND=8))
        IF (PRESENT(tracer)) CALL gpu_cc_save_r(182, tracer, SIZE(tracer,KIND=8))
        IF (PRESENT(tracer_tend)) CALL gpu_cc_save_r(183, tracer_tend, SIZE(tracer_tend,KIND=8))
#if (WRF_CHEM == 1)
        CALL gpu_cc_save_r(184, chem, SIZE(chem,KIND=8))
#endif
        IF (PRESENT(qnorm)) CALL gpu_cc_save_r(185, qnorm, SIZE(qnorm,KIND=8))
      END IF
      gpu_isl = gpu_island(R_PBL_DRIVER)
      IF (gpu_isl) THEN
        IF (gpu_world_host) THEN
!$acc update device(rublten, rvblten, rthblten, tsk, xland, znt, ht, ust, pblh, hfx, qfx, grdflx, &
!$acc&   hpbl_hold, u_phy, v_phy, th_phy, rho, p_phy, pi_phy, p8w, t_phy, dz8w, z, exch_h, exch_m, &
!$acc&   akhs, akms, thz0, qz0, uz0, vz0, qsfc, f, lowlyr, u10, v10, uoce, voce, t2, psim, psih, &
!$acc&   fm, fhh, gz1oz0, wspd, br, chklowq, kpbl, mixht, ct, lh, snow, xice, power, i_start, &
!$acc&   i_end, j_start, j_end, tke_pbl, diss_pbl, tpe_pbl, tke_adv, diss_adv, tpe_adv, pr_pbl, &
!$acc&   el_pbl, wu_tur, wv_tur, wt_tur, wq_tur, rthraten &
#if (WRF_CHEM == 1)
!$acc&   , chem, vd &
#endif
!$acc&   )
          IF (PRESENT(w)) THEN
!$acc update device(w)
          END IF
          IF (PRESENT(dx2d)) THEN
!$acc update device(dx2d)
          END IF
          IF (PRESENT(area2d)) THEN
!$acc update device(area2d)
          END IF
          IF (PRESENT(znu)) THEN
!$acc update device(znu)
          END IF
          IF (PRESENT(znw)) THEN
!$acc update device(znw)
          END IF
          IF (PRESENT(mut)) THEN
!$acc update device(mut)
          END IF
          IF (PRESENT(ctopo)) THEN
!$acc update device(ctopo)
          END IF
          IF (PRESENT(ctopo2)) THEN
!$acc update device(ctopo2)
          END IF
          IF (PRESENT(te_temf)) THEN
!$acc update device(te_temf)
          END IF
          IF (PRESENT(km_temf)) THEN
!$acc update device(km_temf)
          END IF
          IF (PRESENT(kh_temf)) THEN
!$acc update device(kh_temf)
          END IF
          IF (PRESENT(shf_temf)) THEN
!$acc update device(shf_temf)
          END IF
          IF (PRESENT(qf_temf)) THEN
!$acc update device(qf_temf)
          END IF
          IF (PRESENT(uw_temf)) THEN
!$acc update device(uw_temf)
          END IF
          IF (PRESENT(vw_temf)) THEN
!$acc update device(vw_temf)
          END IF
          IF (PRESENT(hd_temf)) THEN
!$acc update device(hd_temf)
          END IF
          IF (PRESENT(lcl_temf)) THEN
!$acc update device(lcl_temf)
          END IF
          IF (PRESENT(hct_temf)) THEN
!$acc update device(hct_temf)
          END IF
          IF (PRESENT(wupd_temf)) THEN
!$acc update device(wupd_temf)
          END IF
          IF (PRESENT(mf_temf)) THEN
!$acc update device(mf_temf)
          END IF
          IF (PRESENT(thup_temf)) THEN
!$acc update device(thup_temf)
          END IF
          IF (PRESENT(qtup_temf)) THEN
!$acc update device(qtup_temf)
          END IF
          IF (PRESENT(qlup_temf)) THEN
!$acc update device(qlup_temf)
          END IF
          IF (PRESENT(exch_temf)) THEN
!$acc update device(exch_temf)
          END IF
          IF (PRESENT(cf3d_temf)) THEN
!$acc update device(cf3d_temf)
          END IF
          IF (PRESENT(cfm_temf)) THEN
!$acc update device(cfm_temf)
          END IF
          IF (PRESENT(flhc)) THEN
!$acc update device(flhc)
          END IF
          IF (PRESENT(flqc)) THEN
!$acc update device(flqc)
          END IF
          IF (PRESENT(qke)) THEN
!$acc update device(qke)
          END IF
          IF (PRESENT(sh3d)) THEN
!$acc update device(sh3d)
          END IF
          IF (PRESENT(sm3d)) THEN
!$acc update device(sm3d)
          END IF
          IF (PRESENT(qke_adv)) THEN
!$acc update device(qke_adv)
          END IF
          IF (PRESENT(tsq)) THEN
!$acc update device(tsq)
          END IF
          IF (PRESENT(qsq)) THEN
!$acc update device(qsq)
          END IF
          IF (PRESENT(cov)) THEN
!$acc update device(cov)
          END IF
          IF (PRESENT(rmol)) THEN
!$acc update device(rmol)
          END IF
          IF (PRESENT(ch)) THEN
!$acc update device(ch)
          END IF
          IF (PRESENT(qcg)) THEN
!$acc update device(qcg)
          END IF
          IF (PRESENT(dqke)) THEN
!$acc update device(dqke)
          END IF
          IF (PRESENT(qwt)) THEN
!$acc update device(qwt)
          END IF
          IF (PRESENT(qshear)) THEN
!$acc update device(qshear)
          END IF
          IF (PRESENT(qbuoy)) THEN
!$acc update device(qbuoy)
          END IF
          IF (PRESENT(qdiss)) THEN
!$acc update device(qdiss)
          END IF
          IF (PRESENT(qc_bl)) THEN
!$acc update device(qc_bl)
          END IF
          IF (PRESENT(qi_bl)) THEN
!$acc update device(qi_bl)
          END IF
          IF (PRESENT(cldfra_bl)) THEN
!$acc update device(cldfra_bl)
          END IF
          IF (PRESENT(edmf_a)) THEN
!$acc update device(edmf_a)
          END IF
          IF (PRESENT(edmf_w)) THEN
!$acc update device(edmf_w)
          END IF
          IF (PRESENT(edmf_thl)) THEN
!$acc update device(edmf_thl)
          END IF
          IF (PRESENT(edmf_qt)) THEN
!$acc update device(edmf_qt)
          END IF
          IF (PRESENT(edmf_ent)) THEN
!$acc update device(edmf_ent)
          END IF
          IF (PRESENT(edmf_qc)) THEN
!$acc update device(edmf_qc)
          END IF
          IF (PRESENT(sub_thl3d)) THEN
!$acc update device(sub_thl3d)
          END IF
          IF (PRESENT(sub_sqv3d)) THEN
!$acc update device(sub_sqv3d)
          END IF
          IF (PRESENT(det_thl3d)) THEN
!$acc update device(det_thl3d)
          END IF
          IF (PRESENT(det_sqv3d)) THEN
!$acc update device(det_sqv3d)
          END IF
          IF (PRESENT(vdfg)) THEN
!$acc update device(vdfg)
          END IF
          IF (PRESENT(maxwidth)) THEN
!$acc update device(maxwidth)
          END IF
          IF (PRESENT(maxmf)) THEN
!$acc update device(maxmf)
          END IF
          IF (PRESENT(ztop_plume)) THEN
!$acc update device(ztop_plume)
          END IF
          IF (PRESENT(ktop_plume)) THEN
!$acc update device(ktop_plume)
          END IF
          IF (PRESENT(pattern_spp_pbl)) THEN
!$acc update device(pattern_spp_pbl)
          END IF
          IF (PRESENT(pek)) THEN
!$acc update device(pek)
          END IF
          IF (PRESENT(pep)) THEN
!$acc update device(pep)
          END IF
          IF (PRESENT(pek_adv)) THEN
!$acc update device(pek_adv)
          END IF
          IF (PRESENT(pep_adv)) THEN
!$acc update device(pep_adv)
          END IF
          IF (PRESENT(hol)) THEN
!$acc update device(hol)
          END IF
          IF (PRESENT(mol)) THEN
!$acc update device(mol)
          END IF
          IF (PRESENT(regime)) THEN
!$acc update device(regime)
          END IF
          IF (PRESENT(dtaux3d)) THEN
!$acc update device(dtaux3d)
          END IF
          IF (PRESENT(dtauy3d)) THEN
!$acc update device(dtauy3d)
          END IF
          IF (PRESENT(dusfcg)) THEN
!$acc update device(dusfcg)
          END IF
          IF (PRESENT(dvsfcg)) THEN
!$acc update device(dvsfcg)
          END IF
          IF (PRESENT(var2d)) THEN
!$acc update device(var2d)
          END IF
          IF (PRESENT(oc12d)) THEN
!$acc update device(oc12d)
          END IF
          IF (PRESENT(oa1)) THEN
!$acc update device(oa1)
          END IF
          IF (PRESENT(oa2)) THEN
!$acc update device(oa2)
          END IF
          IF (PRESENT(oa3)) THEN
!$acc update device(oa3)
          END IF
          IF (PRESENT(oa4)) THEN
!$acc update device(oa4)
          END IF
          IF (PRESENT(ol1)) THEN
!$acc update device(ol1)
          END IF
          IF (PRESENT(ol2)) THEN
!$acc update device(ol2)
          END IF
          IF (PRESENT(ol3)) THEN
!$acc update device(ol3)
          END IF
          IF (PRESENT(ol4)) THEN
!$acc update device(ol4)
          END IF
          IF (PRESENT(sina)) THEN
!$acc update device(sina)
          END IF
          IF (PRESENT(cosa)) THEN
!$acc update device(cosa)
          END IF
          IF (PRESENT(dtaux3d_ls)) THEN
!$acc update device(dtaux3d_ls)
          END IF
          IF (PRESENT(dtauy3d_ls)) THEN
!$acc update device(dtauy3d_ls)
          END IF
          IF (PRESENT(dtaux3d_bl)) THEN
!$acc update device(dtaux3d_bl)
          END IF
          IF (PRESENT(dtauy3d_bl)) THEN
!$acc update device(dtauy3d_bl)
          END IF
          IF (PRESENT(dtaux3d_ss)) THEN
!$acc update device(dtaux3d_ss)
          END IF
          IF (PRESENT(dtauy3d_ss)) THEN
!$acc update device(dtauy3d_ss)
          END IF
          IF (PRESENT(dtaux3d_fd)) THEN
!$acc update device(dtaux3d_fd)
          END IF
          IF (PRESENT(dtauy3d_fd)) THEN
!$acc update device(dtauy3d_fd)
          END IF
          IF (PRESENT(dusfcg_ls)) THEN
!$acc update device(dusfcg_ls)
          END IF
          IF (PRESENT(dvsfcg_ls)) THEN
!$acc update device(dvsfcg_ls)
          END IF
          IF (PRESENT(dusfcg_bl)) THEN
!$acc update device(dusfcg_bl)
          END IF
          IF (PRESENT(dvsfcg_bl)) THEN
!$acc update device(dvsfcg_bl)
          END IF
          IF (PRESENT(dusfcg_ss)) THEN
!$acc update device(dusfcg_ss)
          END IF
          IF (PRESENT(dvsfcg_ss)) THEN
!$acc update device(dvsfcg_ss)
          END IF
          IF (PRESENT(dusfcg_fd)) THEN
!$acc update device(dusfcg_fd)
          END IF
          IF (PRESENT(dvsfcg_fd)) THEN
!$acc update device(dvsfcg_fd)
          END IF
          IF (PRESENT(var2dls)) THEN
!$acc update device(var2dls)
          END IF
          IF (PRESENT(oc12dls)) THEN
!$acc update device(oc12dls)
          END IF
          IF (PRESENT(oa1ls)) THEN
!$acc update device(oa1ls)
          END IF
          IF (PRESENT(oa2ls)) THEN
!$acc update device(oa2ls)
          END IF
          IF (PRESENT(oa3ls)) THEN
!$acc update device(oa3ls)
          END IF
          IF (PRESENT(oa4ls)) THEN
!$acc update device(oa4ls)
          END IF
          IF (PRESENT(ol1ls)) THEN
!$acc update device(ol1ls)
          END IF
          IF (PRESENT(ol2ls)) THEN
!$acc update device(ol2ls)
          END IF
          IF (PRESENT(ol3ls)) THEN
!$acc update device(ol3ls)
          END IF
          IF (PRESENT(ol4ls)) THEN
!$acc update device(ol4ls)
          END IF
          IF (PRESENT(var2dss)) THEN
!$acc update device(var2dss)
          END IF
          IF (PRESENT(oc12dss)) THEN
!$acc update device(oc12dss)
          END IF
          IF (PRESENT(oa1ss)) THEN
!$acc update device(oa1ss)
          END IF
          IF (PRESENT(oa2ss)) THEN
!$acc update device(oa2ss)
          END IF
          IF (PRESENT(oa3ss)) THEN
!$acc update device(oa3ss)
          END IF
          IF (PRESENT(oa4ss)) THEN
!$acc update device(oa4ss)
          END IF
          IF (PRESENT(ol1ss)) THEN
!$acc update device(ol1ss)
          END IF
          IF (PRESENT(ol2ss)) THEN
!$acc update device(ol2ss)
          END IF
          IF (PRESENT(ol3ss)) THEN
!$acc update device(ol3ss)
          END IF
          IF (PRESENT(ol4ss)) THEN
!$acc update device(ol4ss)
          END IF
          IF (PRESENT(qv_curr)) THEN
!$acc update device(qv_curr)
          END IF
          IF (PRESENT(qc_curr)) THEN
!$acc update device(qc_curr)
          END IF
          IF (PRESENT(qr_curr)) THEN
!$acc update device(qr_curr)
          END IF
          IF (PRESENT(qi_curr)) THEN
!$acc update device(qi_curr)
          END IF
          IF (PRESENT(qs_curr)) THEN
!$acc update device(qs_curr)
          END IF
          IF (PRESENT(qg_curr)) THEN
!$acc update device(qg_curr)
          END IF
          IF (PRESENT(rqvblten)) THEN
!$acc update device(rqvblten)
          END IF
          IF (PRESENT(rqcblten)) THEN
!$acc update device(rqcblten)
          END IF
          IF (PRESENT(rqiblten)) THEN
!$acc update device(rqiblten)
          END IF
          IF (PRESENT(rqrblten)) THEN
!$acc update device(rqrblten)
          END IF
          IF (PRESENT(rqsblten)) THEN
!$acc update device(rqsblten)
          END IF
          IF (PRESENT(rqgblten)) THEN
!$acc update device(rqgblten)
          END IF
          IF (PRESENT(qnwfa_curr)) THEN
!$acc update device(qnwfa_curr)
          END IF
          IF (PRESENT(qnifa_curr)) THEN
!$acc update device(qnifa_curr)
          END IF
          IF (PRESENT(qnbca_curr)) THEN
!$acc update device(qnbca_curr)
          END IF
          IF (PRESENT(frc_urb2d)) THEN
!$acc update device(frc_urb2d)
          END IF
          IF (PRESENT(a_u_bep)) THEN
!$acc update device(a_u_bep)
          END IF
          IF (PRESENT(a_v_bep)) THEN
!$acc update device(a_v_bep)
          END IF
          IF (PRESENT(a_t_bep)) THEN
!$acc update device(a_t_bep)
          END IF
          IF (PRESENT(a_q_bep)) THEN
!$acc update device(a_q_bep)
          END IF
          IF (PRESENT(b_u_bep)) THEN
!$acc update device(b_u_bep)
          END IF
          IF (PRESENT(b_v_bep)) THEN
!$acc update device(b_v_bep)
          END IF
          IF (PRESENT(b_t_bep)) THEN
!$acc update device(b_t_bep)
          END IF
          IF (PRESENT(b_q_bep)) THEN
!$acc update device(b_q_bep)
          END IF
          IF (PRESENT(sf_bep)) THEN
!$acc update device(sf_bep)
          END IF
          IF (PRESENT(vl_bep)) THEN
!$acc update device(vl_bep)
          END IF
          IF (PRESENT(ahe)) THEN
!$acc update device(ahe)
          END IF
          IF (PRESENT(exch_tke)) THEN
!$acc update device(exch_tke)
          END IF
          IF (PRESENT(a_e_bep)) THEN
!$acc update device(a_e_bep)
          END IF
          IF (PRESENT(b_e_bep)) THEN
!$acc update device(b_e_bep)
          END IF
          IF (PRESENT(dlg_bep)) THEN
!$acc update device(dlg_bep)
          END IF
          IF (PRESENT(dl_u_bep)) THEN
!$acc update device(dl_u_bep)
          END IF
          IF (PRESENT(massflux_edkf)) THEN
!$acc update device(massflux_edkf)
          END IF
          IF (PRESENT(entr_edkf)) THEN
!$acc update device(entr_edkf)
          END IF
          IF (PRESENT(detr_edkf)) THEN
!$acc update device(detr_edkf)
          END IF
          IF (PRESENT(thl_up)) THEN
!$acc update device(thl_up)
          END IF
          IF (PRESENT(thv_up)) THEN
!$acc update device(thv_up)
          END IF
          IF (PRESENT(rt_up)) THEN
!$acc update device(rt_up)
          END IF
          IF (PRESENT(rv_up)) THEN
!$acc update device(rv_up)
          END IF
          IF (PRESENT(rc_up)) THEN
!$acc update device(rc_up)
          END IF
          IF (PRESENT(u_up)) THEN
!$acc update device(u_up)
          END IF
          IF (PRESENT(v_up)) THEN
!$acc update device(v_up)
          END IF
          IF (PRESENT(frac_up)) THEN
!$acc update device(frac_up)
          END IF
          IF (PRESENT(rc_mf)) THEN
!$acc update device(rc_mf)
          END IF
          IF (PRESENT(phb)) THEN
!$acc update device(phb)
          END IF
          IF (PRESENT(xlat_u)) THEN
!$acc update device(xlat_u)
          END IF
          IF (PRESENT(xlong_u)) THEN
!$acc update device(xlong_u)
          END IF
          IF (PRESENT(xlat_v)) THEN
!$acc update device(xlat_v)
          END IF
          IF (PRESENT(xlong_v)) THEN
!$acc update device(xlong_v)
          END IF
          IF (PRESENT(perts_qvapor)) THEN
!$acc update device(perts_qvapor)
          END IF
          IF (PRESENT(perts_qcloud)) THEN
!$acc update device(perts_qcloud)
          END IF
          IF (PRESENT(perts_th)) THEN
!$acc update device(perts_th)
          END IF
          IF (PRESENT(perts_tke)) THEN
!$acc update device(perts_tke)
          END IF
          IF (PRESENT(z_at_w)) THEN
!$acc update device(z_at_w)
          END IF
          IF (PRESENT(cldfra_old_mp)) THEN
!$acc update device(cldfra_old_mp)
          END IF
          IF (PRESENT(cldfra)) THEN
!$acc update device(cldfra)
          END IF
          IF (PRESENT(rthratenlw)) THEN
!$acc update device(rthratenlw)
          END IF
          IF (PRESENT(tauresx2d)) THEN
!$acc update device(tauresx2d)
          END IF
          IF (PRESENT(tauresy2d)) THEN
!$acc update device(tauresy2d)
          END IF
          IF (PRESENT(tpert2d)) THEN
!$acc update device(tpert2d)
          END IF
          IF (PRESENT(qpert2d)) THEN
!$acc update device(qpert2d)
          END IF
          IF (PRESENT(wpert2d)) THEN
!$acc update device(wpert2d)
          END IF
          IF (PRESENT(wsedl3d)) THEN
!$acc update device(wsedl3d)
          END IF
          IF (PRESENT(turbtype3d)) THEN
!$acc update device(turbtype3d)
          END IF
          IF (PRESENT(smaw3d)) THEN
!$acc update device(smaw3d)
          END IF
          IF (PRESENT(fnm)) THEN
!$acc update device(fnm)
          END IF
          IF (PRESENT(fnp)) THEN
!$acc update device(fnp)
          END IF
          IF (PRESENT(qnc_curr)) THEN
!$acc update device(qnc_curr)
          END IF
          IF (PRESENT(qni_curr)) THEN
!$acc update device(qni_curr)
          END IF
          IF (PRESENT(rqniblten)) THEN
!$acc update device(rqniblten)
          END IF
          IF (PRESENT(wstar)) THEN
!$acc update device(wstar)
          END IF
          IF (PRESENT(delta)) THEN
!$acc update device(delta)
          END IF
          IF (PRESENT(scalar)) THEN
!$acc update device(scalar)
          END IF
          IF (PRESENT(scalar_tend)) THEN
!$acc update device(scalar_tend)
          END IF
          IF (PRESENT(tracer)) THEN
!$acc update device(tracer)
          END IF
          IF (PRESENT(tracer_tend)) THEN
!$acc update device(tracer_tend)
          END IF
          IF (PRESENT(qnorm)) THEN
!$acc update device(qnorm)
          END IF
        ELSE
!$acc update self(rublten, rvblten, rthblten, tsk, xland, znt, ht, ust, pblh, hfx, qfx, grdflx, &
!$acc&   hpbl_hold, u_phy, v_phy, th_phy, rho, p_phy, pi_phy, p8w, t_phy, dz8w, z, exch_h, exch_m, &
!$acc&   akhs, akms, thz0, qz0, uz0, vz0, qsfc, f, lowlyr, u10, v10, uoce, voce, t2, psim, psih, &
!$acc&   fm, fhh, gz1oz0, wspd, br, chklowq, kpbl, mixht, ct, lh, snow, xice, power, i_start, &
!$acc&   i_end, j_start, j_end, tke_pbl, diss_pbl, tpe_pbl, tke_adv, diss_adv, tpe_adv, pr_pbl, &
!$acc&   el_pbl, wu_tur, wv_tur, wt_tur, wq_tur, rthraten &
#if (WRF_CHEM == 1)
!$acc&   , chem, vd &
#endif
!$acc&   )
          IF (PRESENT(w)) THEN
!$acc update self(w)
          END IF
          IF (PRESENT(dx2d)) THEN
!$acc update self(dx2d)
          END IF
          IF (PRESENT(area2d)) THEN
!$acc update self(area2d)
          END IF
          IF (PRESENT(znu)) THEN
!$acc update self(znu)
          END IF
          IF (PRESENT(znw)) THEN
!$acc update self(znw)
          END IF
          IF (PRESENT(mut)) THEN
!$acc update self(mut)
          END IF
          IF (PRESENT(ctopo)) THEN
!$acc update self(ctopo)
          END IF
          IF (PRESENT(ctopo2)) THEN
!$acc update self(ctopo2)
          END IF
          IF (PRESENT(te_temf)) THEN
!$acc update self(te_temf)
          END IF
          IF (PRESENT(km_temf)) THEN
!$acc update self(km_temf)
          END IF
          IF (PRESENT(kh_temf)) THEN
!$acc update self(kh_temf)
          END IF
          IF (PRESENT(shf_temf)) THEN
!$acc update self(shf_temf)
          END IF
          IF (PRESENT(qf_temf)) THEN
!$acc update self(qf_temf)
          END IF
          IF (PRESENT(uw_temf)) THEN
!$acc update self(uw_temf)
          END IF
          IF (PRESENT(vw_temf)) THEN
!$acc update self(vw_temf)
          END IF
          IF (PRESENT(hd_temf)) THEN
!$acc update self(hd_temf)
          END IF
          IF (PRESENT(lcl_temf)) THEN
!$acc update self(lcl_temf)
          END IF
          IF (PRESENT(hct_temf)) THEN
!$acc update self(hct_temf)
          END IF
          IF (PRESENT(wupd_temf)) THEN
!$acc update self(wupd_temf)
          END IF
          IF (PRESENT(mf_temf)) THEN
!$acc update self(mf_temf)
          END IF
          IF (PRESENT(thup_temf)) THEN
!$acc update self(thup_temf)
          END IF
          IF (PRESENT(qtup_temf)) THEN
!$acc update self(qtup_temf)
          END IF
          IF (PRESENT(qlup_temf)) THEN
!$acc update self(qlup_temf)
          END IF
          IF (PRESENT(exch_temf)) THEN
!$acc update self(exch_temf)
          END IF
          IF (PRESENT(cf3d_temf)) THEN
!$acc update self(cf3d_temf)
          END IF
          IF (PRESENT(cfm_temf)) THEN
!$acc update self(cfm_temf)
          END IF
          IF (PRESENT(flhc)) THEN
!$acc update self(flhc)
          END IF
          IF (PRESENT(flqc)) THEN
!$acc update self(flqc)
          END IF
          IF (PRESENT(qke)) THEN
!$acc update self(qke)
          END IF
          IF (PRESENT(sh3d)) THEN
!$acc update self(sh3d)
          END IF
          IF (PRESENT(sm3d)) THEN
!$acc update self(sm3d)
          END IF
          IF (PRESENT(qke_adv)) THEN
!$acc update self(qke_adv)
          END IF
          IF (PRESENT(tsq)) THEN
!$acc update self(tsq)
          END IF
          IF (PRESENT(qsq)) THEN
!$acc update self(qsq)
          END IF
          IF (PRESENT(cov)) THEN
!$acc update self(cov)
          END IF
          IF (PRESENT(rmol)) THEN
!$acc update self(rmol)
          END IF
          IF (PRESENT(ch)) THEN
!$acc update self(ch)
          END IF
          IF (PRESENT(qcg)) THEN
!$acc update self(qcg)
          END IF
          IF (PRESENT(dqke)) THEN
!$acc update self(dqke)
          END IF
          IF (PRESENT(qwt)) THEN
!$acc update self(qwt)
          END IF
          IF (PRESENT(qshear)) THEN
!$acc update self(qshear)
          END IF
          IF (PRESENT(qbuoy)) THEN
!$acc update self(qbuoy)
          END IF
          IF (PRESENT(qdiss)) THEN
!$acc update self(qdiss)
          END IF
          IF (PRESENT(qc_bl)) THEN
!$acc update self(qc_bl)
          END IF
          IF (PRESENT(qi_bl)) THEN
!$acc update self(qi_bl)
          END IF
          IF (PRESENT(cldfra_bl)) THEN
!$acc update self(cldfra_bl)
          END IF
          IF (PRESENT(edmf_a)) THEN
!$acc update self(edmf_a)
          END IF
          IF (PRESENT(edmf_w)) THEN
!$acc update self(edmf_w)
          END IF
          IF (PRESENT(edmf_thl)) THEN
!$acc update self(edmf_thl)
          END IF
          IF (PRESENT(edmf_qt)) THEN
!$acc update self(edmf_qt)
          END IF
          IF (PRESENT(edmf_ent)) THEN
!$acc update self(edmf_ent)
          END IF
          IF (PRESENT(edmf_qc)) THEN
!$acc update self(edmf_qc)
          END IF
          IF (PRESENT(sub_thl3d)) THEN
!$acc update self(sub_thl3d)
          END IF
          IF (PRESENT(sub_sqv3d)) THEN
!$acc update self(sub_sqv3d)
          END IF
          IF (PRESENT(det_thl3d)) THEN
!$acc update self(det_thl3d)
          END IF
          IF (PRESENT(det_sqv3d)) THEN
!$acc update self(det_sqv3d)
          END IF
          IF (PRESENT(vdfg)) THEN
!$acc update self(vdfg)
          END IF
          IF (PRESENT(maxwidth)) THEN
!$acc update self(maxwidth)
          END IF
          IF (PRESENT(maxmf)) THEN
!$acc update self(maxmf)
          END IF
          IF (PRESENT(ztop_plume)) THEN
!$acc update self(ztop_plume)
          END IF
          IF (PRESENT(ktop_plume)) THEN
!$acc update self(ktop_plume)
          END IF
          IF (PRESENT(pattern_spp_pbl)) THEN
!$acc update self(pattern_spp_pbl)
          END IF
          IF (PRESENT(pek)) THEN
!$acc update self(pek)
          END IF
          IF (PRESENT(pep)) THEN
!$acc update self(pep)
          END IF
          IF (PRESENT(pek_adv)) THEN
!$acc update self(pek_adv)
          END IF
          IF (PRESENT(pep_adv)) THEN
!$acc update self(pep_adv)
          END IF
          IF (PRESENT(hol)) THEN
!$acc update self(hol)
          END IF
          IF (PRESENT(mol)) THEN
!$acc update self(mol)
          END IF
          IF (PRESENT(regime)) THEN
!$acc update self(regime)
          END IF
          IF (PRESENT(dtaux3d)) THEN
!$acc update self(dtaux3d)
          END IF
          IF (PRESENT(dtauy3d)) THEN
!$acc update self(dtauy3d)
          END IF
          IF (PRESENT(dusfcg)) THEN
!$acc update self(dusfcg)
          END IF
          IF (PRESENT(dvsfcg)) THEN
!$acc update self(dvsfcg)
          END IF
          IF (PRESENT(var2d)) THEN
!$acc update self(var2d)
          END IF
          IF (PRESENT(oc12d)) THEN
!$acc update self(oc12d)
          END IF
          IF (PRESENT(oa1)) THEN
!$acc update self(oa1)
          END IF
          IF (PRESENT(oa2)) THEN
!$acc update self(oa2)
          END IF
          IF (PRESENT(oa3)) THEN
!$acc update self(oa3)
          END IF
          IF (PRESENT(oa4)) THEN
!$acc update self(oa4)
          END IF
          IF (PRESENT(ol1)) THEN
!$acc update self(ol1)
          END IF
          IF (PRESENT(ol2)) THEN
!$acc update self(ol2)
          END IF
          IF (PRESENT(ol3)) THEN
!$acc update self(ol3)
          END IF
          IF (PRESENT(ol4)) THEN
!$acc update self(ol4)
          END IF
          IF (PRESENT(sina)) THEN
!$acc update self(sina)
          END IF
          IF (PRESENT(cosa)) THEN
!$acc update self(cosa)
          END IF
          IF (PRESENT(dtaux3d_ls)) THEN
!$acc update self(dtaux3d_ls)
          END IF
          IF (PRESENT(dtauy3d_ls)) THEN
!$acc update self(dtauy3d_ls)
          END IF
          IF (PRESENT(dtaux3d_bl)) THEN
!$acc update self(dtaux3d_bl)
          END IF
          IF (PRESENT(dtauy3d_bl)) THEN
!$acc update self(dtauy3d_bl)
          END IF
          IF (PRESENT(dtaux3d_ss)) THEN
!$acc update self(dtaux3d_ss)
          END IF
          IF (PRESENT(dtauy3d_ss)) THEN
!$acc update self(dtauy3d_ss)
          END IF
          IF (PRESENT(dtaux3d_fd)) THEN
!$acc update self(dtaux3d_fd)
          END IF
          IF (PRESENT(dtauy3d_fd)) THEN
!$acc update self(dtauy3d_fd)
          END IF
          IF (PRESENT(dusfcg_ls)) THEN
!$acc update self(dusfcg_ls)
          END IF
          IF (PRESENT(dvsfcg_ls)) THEN
!$acc update self(dvsfcg_ls)
          END IF
          IF (PRESENT(dusfcg_bl)) THEN
!$acc update self(dusfcg_bl)
          END IF
          IF (PRESENT(dvsfcg_bl)) THEN
!$acc update self(dvsfcg_bl)
          END IF
          IF (PRESENT(dusfcg_ss)) THEN
!$acc update self(dusfcg_ss)
          END IF
          IF (PRESENT(dvsfcg_ss)) THEN
!$acc update self(dvsfcg_ss)
          END IF
          IF (PRESENT(dusfcg_fd)) THEN
!$acc update self(dusfcg_fd)
          END IF
          IF (PRESENT(dvsfcg_fd)) THEN
!$acc update self(dvsfcg_fd)
          END IF
          IF (PRESENT(var2dls)) THEN
!$acc update self(var2dls)
          END IF
          IF (PRESENT(oc12dls)) THEN
!$acc update self(oc12dls)
          END IF
          IF (PRESENT(oa1ls)) THEN
!$acc update self(oa1ls)
          END IF
          IF (PRESENT(oa2ls)) THEN
!$acc update self(oa2ls)
          END IF
          IF (PRESENT(oa3ls)) THEN
!$acc update self(oa3ls)
          END IF
          IF (PRESENT(oa4ls)) THEN
!$acc update self(oa4ls)
          END IF
          IF (PRESENT(ol1ls)) THEN
!$acc update self(ol1ls)
          END IF
          IF (PRESENT(ol2ls)) THEN
!$acc update self(ol2ls)
          END IF
          IF (PRESENT(ol3ls)) THEN
!$acc update self(ol3ls)
          END IF
          IF (PRESENT(ol4ls)) THEN
!$acc update self(ol4ls)
          END IF
          IF (PRESENT(var2dss)) THEN
!$acc update self(var2dss)
          END IF
          IF (PRESENT(oc12dss)) THEN
!$acc update self(oc12dss)
          END IF
          IF (PRESENT(oa1ss)) THEN
!$acc update self(oa1ss)
          END IF
          IF (PRESENT(oa2ss)) THEN
!$acc update self(oa2ss)
          END IF
          IF (PRESENT(oa3ss)) THEN
!$acc update self(oa3ss)
          END IF
          IF (PRESENT(oa4ss)) THEN
!$acc update self(oa4ss)
          END IF
          IF (PRESENT(ol1ss)) THEN
!$acc update self(ol1ss)
          END IF
          IF (PRESENT(ol2ss)) THEN
!$acc update self(ol2ss)
          END IF
          IF (PRESENT(ol3ss)) THEN
!$acc update self(ol3ss)
          END IF
          IF (PRESENT(ol4ss)) THEN
!$acc update self(ol4ss)
          END IF
          IF (PRESENT(qv_curr)) THEN
!$acc update self(qv_curr)
          END IF
          IF (PRESENT(qc_curr)) THEN
!$acc update self(qc_curr)
          END IF
          IF (PRESENT(qr_curr)) THEN
!$acc update self(qr_curr)
          END IF
          IF (PRESENT(qi_curr)) THEN
!$acc update self(qi_curr)
          END IF
          IF (PRESENT(qs_curr)) THEN
!$acc update self(qs_curr)
          END IF
          IF (PRESENT(qg_curr)) THEN
!$acc update self(qg_curr)
          END IF
          IF (PRESENT(rqvblten)) THEN
!$acc update self(rqvblten)
          END IF
          IF (PRESENT(rqcblten)) THEN
!$acc update self(rqcblten)
          END IF
          IF (PRESENT(rqiblten)) THEN
!$acc update self(rqiblten)
          END IF
          IF (PRESENT(rqrblten)) THEN
!$acc update self(rqrblten)
          END IF
          IF (PRESENT(rqsblten)) THEN
!$acc update self(rqsblten)
          END IF
          IF (PRESENT(rqgblten)) THEN
!$acc update self(rqgblten)
          END IF
          IF (PRESENT(qnwfa_curr)) THEN
!$acc update self(qnwfa_curr)
          END IF
          IF (PRESENT(qnifa_curr)) THEN
!$acc update self(qnifa_curr)
          END IF
          IF (PRESENT(qnbca_curr)) THEN
!$acc update self(qnbca_curr)
          END IF
          IF (PRESENT(frc_urb2d)) THEN
!$acc update self(frc_urb2d)
          END IF
          IF (PRESENT(a_u_bep)) THEN
!$acc update self(a_u_bep)
          END IF
          IF (PRESENT(a_v_bep)) THEN
!$acc update self(a_v_bep)
          END IF
          IF (PRESENT(a_t_bep)) THEN
!$acc update self(a_t_bep)
          END IF
          IF (PRESENT(a_q_bep)) THEN
!$acc update self(a_q_bep)
          END IF
          IF (PRESENT(b_u_bep)) THEN
!$acc update self(b_u_bep)
          END IF
          IF (PRESENT(b_v_bep)) THEN
!$acc update self(b_v_bep)
          END IF
          IF (PRESENT(b_t_bep)) THEN
!$acc update self(b_t_bep)
          END IF
          IF (PRESENT(b_q_bep)) THEN
!$acc update self(b_q_bep)
          END IF
          IF (PRESENT(sf_bep)) THEN
!$acc update self(sf_bep)
          END IF
          IF (PRESENT(vl_bep)) THEN
!$acc update self(vl_bep)
          END IF
          IF (PRESENT(ahe)) THEN
!$acc update self(ahe)
          END IF
          IF (PRESENT(exch_tke)) THEN
!$acc update self(exch_tke)
          END IF
          IF (PRESENT(a_e_bep)) THEN
!$acc update self(a_e_bep)
          END IF
          IF (PRESENT(b_e_bep)) THEN
!$acc update self(b_e_bep)
          END IF
          IF (PRESENT(dlg_bep)) THEN
!$acc update self(dlg_bep)
          END IF
          IF (PRESENT(dl_u_bep)) THEN
!$acc update self(dl_u_bep)
          END IF
          IF (PRESENT(massflux_edkf)) THEN
!$acc update self(massflux_edkf)
          END IF
          IF (PRESENT(entr_edkf)) THEN
!$acc update self(entr_edkf)
          END IF
          IF (PRESENT(detr_edkf)) THEN
!$acc update self(detr_edkf)
          END IF
          IF (PRESENT(thl_up)) THEN
!$acc update self(thl_up)
          END IF
          IF (PRESENT(thv_up)) THEN
!$acc update self(thv_up)
          END IF
          IF (PRESENT(rt_up)) THEN
!$acc update self(rt_up)
          END IF
          IF (PRESENT(rv_up)) THEN
!$acc update self(rv_up)
          END IF
          IF (PRESENT(rc_up)) THEN
!$acc update self(rc_up)
          END IF
          IF (PRESENT(u_up)) THEN
!$acc update self(u_up)
          END IF
          IF (PRESENT(v_up)) THEN
!$acc update self(v_up)
          END IF
          IF (PRESENT(frac_up)) THEN
!$acc update self(frac_up)
          END IF
          IF (PRESENT(rc_mf)) THEN
!$acc update self(rc_mf)
          END IF
          IF (PRESENT(phb)) THEN
!$acc update self(phb)
          END IF
          IF (PRESENT(xlat_u)) THEN
!$acc update self(xlat_u)
          END IF
          IF (PRESENT(xlong_u)) THEN
!$acc update self(xlong_u)
          END IF
          IF (PRESENT(xlat_v)) THEN
!$acc update self(xlat_v)
          END IF
          IF (PRESENT(xlong_v)) THEN
!$acc update self(xlong_v)
          END IF
          IF (PRESENT(perts_qvapor)) THEN
!$acc update self(perts_qvapor)
          END IF
          IF (PRESENT(perts_qcloud)) THEN
!$acc update self(perts_qcloud)
          END IF
          IF (PRESENT(perts_th)) THEN
!$acc update self(perts_th)
          END IF
          IF (PRESENT(perts_tke)) THEN
!$acc update self(perts_tke)
          END IF
          IF (PRESENT(z_at_w)) THEN
!$acc update self(z_at_w)
          END IF
          IF (PRESENT(cldfra_old_mp)) THEN
!$acc update self(cldfra_old_mp)
          END IF
          IF (PRESENT(cldfra)) THEN
!$acc update self(cldfra)
          END IF
          IF (PRESENT(rthratenlw)) THEN
!$acc update self(rthratenlw)
          END IF
          IF (PRESENT(tauresx2d)) THEN
!$acc update self(tauresx2d)
          END IF
          IF (PRESENT(tauresy2d)) THEN
!$acc update self(tauresy2d)
          END IF
          IF (PRESENT(tpert2d)) THEN
!$acc update self(tpert2d)
          END IF
          IF (PRESENT(qpert2d)) THEN
!$acc update self(qpert2d)
          END IF
          IF (PRESENT(wpert2d)) THEN
!$acc update self(wpert2d)
          END IF
          IF (PRESENT(wsedl3d)) THEN
!$acc update self(wsedl3d)
          END IF
          IF (PRESENT(turbtype3d)) THEN
!$acc update self(turbtype3d)
          END IF
          IF (PRESENT(smaw3d)) THEN
!$acc update self(smaw3d)
          END IF
          IF (PRESENT(fnm)) THEN
!$acc update self(fnm)
          END IF
          IF (PRESENT(fnp)) THEN
!$acc update self(fnp)
          END IF
          IF (PRESENT(qnc_curr)) THEN
!$acc update self(qnc_curr)
          END IF
          IF (PRESENT(qni_curr)) THEN
!$acc update self(qni_curr)
          END IF
          IF (PRESENT(rqniblten)) THEN
!$acc update self(rqniblten)
          END IF
          IF (PRESENT(wstar)) THEN
!$acc update self(wstar)
          END IF
          IF (PRESENT(delta)) THEN
!$acc update self(delta)
          END IF
          IF (PRESENT(scalar)) THEN
!$acc update self(scalar)
          END IF
          IF (PRESENT(scalar_tend)) THEN
!$acc update self(scalar_tend)
          END IF
          IF (PRESENT(tracer)) THEN
!$acc update self(tracer)
          END IF
          IF (PRESENT(tracer_tend)) THEN
!$acc update self(tracer_tend)
          END IF
          IF (PRESENT(qnorm)) THEN
!$acc update self(qnorm)
          END IF
        END IF
        gpu_world_host = .NOT. gpu_world_host
      END IF
#endif

   ! P1.7: remap the former 3D automatic arrays onto work arrays (both builds).
   u_phytmp(ims:ime,kms:kme,jms:jme) => work_p3_pbl_u_phytmp(1:(ime-ims+1)*(kme-kms+1)*(jme-jms+1))
   v_phytmp(ims:ime,kms:kme,jms:jme) => work_p3_pbl_v_phytmp(1:(ime-ims+1)*(kme-kms+1)*(jme-jms+1))
   TKE_windfarm(ims:ime,kms:kme,jms:jme) => work_p3_pbl_tke_windfarm(1:(ime-ims+1)*(kme-kms+1)*(jme-jms+1))
   rqncblten(ims:ime,kms:kme,jms:jme) => work_p3_pbl_rqncblten(1:(ime-ims+1)*(kme-kms+1)*(jme-jms+1))
   rqnwfablten(ims:ime,kms:kme,jms:jme) => work_p3_pbl_rqnwfablten(1:(ime-ims+1)*(kme-kms+1)*(jme-jms+1))
   rqnifablten(ims:ime,kms:kme,jms:jme) => work_p3_pbl_rqnifablten(1:(ime-ims+1)*(kme-kms+1)*(jme-jms+1))
   rqnbcablten(ims:ime,kms:kme,jms:jme) => work_p3_pbl_rqnbcablten(1:(ime-ims+1)*(kme-kms+1)*(jme-jms+1))
#ifdef WRF_GPU
   TSKOLD(ims:ime,jms:jme) => work_p3_pbl_tskold(1:(ime-ims+1)*(jme-jms+1))
   USTOLD(ims:ime,jms:jme) => work_p3_pbl_ustold(1:(ime-ims+1)*(jme-jms+1))
   ZNTOLD(ims:ime,jms:jme) => work_p3_pbl_zntold(1:(ime-ims+1)*(jme-jms+1))
   PSFC(ims:ime,jms:jme) => work_p3_pbl_psfc(1:(ime-ims+1)*(jme-jms+1))
   IF (bl_pbl_physics .NE. YSUSCHEME) THEN
      CALL wrf_error_fatal('pbl_driver: bl_pbl_physics not ported to the GPU')
   END IF
#endif

! RAINBL in mm (Accumulation between PBL calls)
!
   doing_adapt_dt = .FALSE.
   IF ( PRESENT(adapt_step_flag) ) THEN
      IF ( adapt_step_flag ) THEN
         doing_adapt_dt = .TRUE.
         IF ( bldtacttime .eq. 0. ) THEN
            bldtacttime = CURR_SECS + bldt*60.
         END IF
      END IF
   END IF

!  Do we run through this scheme or not?

!    Test 1:  If this is the initial model time, then yes.
!                ITIMESTEP=1
!    Test 2:  If the user asked for the pbl to be run every time step, then yes.
!                BLDT=0 or STEPBL=1
!    Test 3:  If not adaptive dt, and this is on the requested pbl frequency, then yes.
!                MOD(ITIMESTEP,STEPBL)=0
!    Test 4:  If using adaptive dt and the current time is past the last requested activate pbl time, then yes.
!                CURR_SECS >= BLDTACTTIME

!  If we do run through the scheme, we set the flag run_param to TRUE and we set the decided flag
!  to TRUE.  The decided flag says that one of these tests was able to say "yes", run the scheme.
!  We only proceed to other tests if the previous tests all have left decided as FALSE.

!  If we set run_param to TRUE and this is adaptive time stepping, we set the time to the next
!  pbl run.

   run_param = .FALSE.
   decided = .FALSE.
   IF ( ( .NOT. decided ) .AND. &
        ( itimestep .EQ. 1 ) ) THEN
      run_param   = .TRUE.
      decided     = .TRUE.
   END IF

   IF ( PRESENT(bldt) )THEN
      IF ( ( .NOT. decided ) .AND. &
           ( ( bldt .EQ. 0. ) .OR. ( stepbl .EQ. 1 ) ) ) THEN
         run_param   = .TRUE.
         decided     = .TRUE.
      END IF
   ELSE
      IF ( ( .NOT. decided ) .AND. &
                                   ( stepbl .EQ. 1 )   ) THEN
         run_param   = .TRUE.
         decided     = .TRUE.
      END IF
   END IF

   IF ( ( .NOT. decided ) .AND. &
        ( .NOT. doing_adapt_dt ) .AND. &
        ( rp_mod(itimestep,stepbl) .EQ. 0 ) ) THEN
      run_param   = .TRUE.
      decided     = .TRUE.
   END IF

   IF ( ( .NOT. decided ) .AND. &
        ( doing_adapt_dt ) .AND. &
        ( curr_secs .GE. bldtacttime ) ) THEN
      run_param   = .TRUE.
      decided     = .TRUE.
      bldtacttime = curr_secs + bldt*60
   END IF


 IF (run_param) THEN
  radiation = .false.
  IF (ra_lw_physics .gt. 0) radiation = .true.

!---- 
! CALCULATE CONSTANT
 
   DTMIN=DT/60.
! PBL schemes need PBL time step for updates

    if (PRESENT(adapt_step_flag)) then
       if (adapt_step_flag) then
          do_adapt = .TRUE.
       else
          do_adapt = .FALSE.
       endif
    else
       do_adapt = .FALSE.
    endif

   if (PRESENT(BLDT)) then
      if (bldt .eq. 0) then
         DTBL = dt
      ELSE
         if (do_adapt) then
            IF ( curr_secs .LT. 2. * dt ) THEN
               call wrf_message("WARNING: When using an adaptive time-step the boundary layer"// &
                                " time-step should be 0 (i.e., equivalent to model time-step).  ")
               call wrf_message("In order to proceed, for boundary layer calculations, the "// &
                                "boundary layer time-step "// &
                                "will be rounded to the nearest minute," )
               call wrf_message("possibly resulting in innacurate results.")
            END IF
            DTBL=bldt*60
         else
            DTBL=DT*STEPBL
         endif
      endif
   else
      DTBL=DT*STEPBL
   endif

!!Alberto. If idiff=1, then compute the tendencies at the end in the routine diff3d
!!Alberto. If idiff=0, then compute the tendencies in each PBL routine (standard version).
       idiff=0

   IF ( idiff .EQ. 1 ) THEN
#ifdef WRF_GPU
     CALL wrf_error_fatal('pbl_driver: idiff=1 not ported to the GPU')
#endif
     ALLOCATE (a_u(ims:ime,kms:kme,jms:jme))       ! Implicit component for the momemtum in X-direction
     ALLOCATE (a_v(ims:ime,kms:kme,jms:jme))       ! Implicit component for the momemtum in Y-direction
     ALLOCATE (a_t(ims:ime,kms:kme,jms:jme))       ! Implicit component for the Pot. Temp.
     ALLOCATE (a_q(ims:ime,kms:kme,jms:jme))       ! Implicit component for the water vapor
     ALLOCATE (b_u(ims:ime,kms:kme,jms:jme))       ! Explicit component for the momemtum in X-direction
     ALLOCATE (b_v(ims:ime,kms:kme,jms:jme))       ! Explicit component for the momemtum in Y-direction
     ALLOCATE (b_t(ims:ime,kms:kme,jms:jme))       ! Explicit component for the Pot. Temp.
     ALLOCATE (b_q(ims:ime,kms:kme,jms:jme))       ! Explicit component for the water vapor
     ALLOCATE (sf(ims:ime,kms:kme,jms:jme) )       ! surfaces
     ALLOCATE (vl(ims:ime,kms:kme,jms:jme) )       ! volumes
   ENDIF
   
! SAVE OLD VALUES

   !$OMP PARALLEL DO   &
   !$OMP PRIVATE ( ij,i,j,k )

   DO ij = 1 , num_tiles
#ifdef WRF_GPU
      its = i_start_h(ij)
      ite = i_end_h(ij)
      jts = j_start_h(ij)
      jte = j_end_h(ij)
      has_rqcblten = PRESENT( RQCBLTEN )
      has_rqvblten = PRESENT( RQVBLTEN )
      has_rqiblten = PRESENT( RQIBLTEN )
      IF (.NOT. has_rqcblten .OR. .NOT. has_rqvblten .OR. .NOT. has_rqiblten) THEN
         CALL wrf_error_fatal('pbl_driver: moisture BL tendencies not present')
      END IF
      IF (flag_QNI) THEN
         CALL wrf_error_fatal('pbl_driver: QNI not ported to the GPU')
      END IF
      ktend_pbl = MIN(kte+1,kde)
! K-PBLD-1: save TSK UST ZNT HPBL, copy u and v, zero BL tendencies (Template A)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_PBL_DRIVER)) default(none) &
!$acc& present(tskold, ustold, zntold, hpbl_hold, v_phytmp, u_phytmp, psfc, &
!$acc&   tsk, ust, znt, pblh, v_phy, u_phy, p8w, rthblten, rublten, rvblten, &
!$acc&   rqcblten, rqvblten, rqiblten) &
!$acc& firstprivate(its, ite, jts, jte, kts, kte, ktend_pbl, kms, v_frame, u_frame, &
!$acc&   flag_qi, has_rqcblten, has_rqvblten, has_rqiblten) &
!$acc& private(i, j, k)
      DO j = jts, jte
      DO i = its, ite
         TSKOLD(i,j)=TSK(i,j)
         USTOLD(i,j)=UST(i,j)
         ZNTOLD(i,j)=ZNT(i,j)
         HPBL_HOLD(i,j)=PBLH(i,j)

         !$acc loop seq
         DO k=kts,kte
            v_phytmp(i,k,j)=v_phy(i,k,j)+v_frame
            u_phytmp(i,k,j)=u_phy(i,k,j)+u_frame
         ENDDO

! PSFC : in Pa

         PSFC(I,J)=p8w(I,kms,J)

         !$acc loop seq
         DO k=kts,ktend_pbl
            RTHBLTEN(I,K,J)=0.
            RUBLTEN(I,K,J)=0.
            RVBLTEN(I,K,J)=0.
            IF ( has_rqcblten ) RQCBLTEN(I,K,J)=0.
            IF ( has_rqvblten ) RQVBLTEN(I,K,J)=0.
         ENDDO

         IF (flag_QI .AND. has_rqiblten ) THEN
            !$acc loop seq
            DO k=kts,ktend_pbl
               RQIBLTEN(I,K,J)=0.
            ENDDO
         ENDIF
      ENDDO
      ENDDO
#else
      DO j=j_start(ij),j_end(ij)
      DO i=i_start(ij),i_end(ij)
         TSKOLD(i,j)=TSK(i,j)
         USTOLD(i,j)=UST(i,j)
         ZNTOLD(i,j)=ZNT(i,j)
         HPBL_HOLD(i,j)=PBLH(i,j)

         DO k=kts,kte
            v_phytmp(i,k,j)=v_phy(i,k,j)+v_frame
            u_phytmp(i,k,j)=u_phy(i,k,j)+u_frame
         ENDDO

! PSFC : in Pa

         PSFC(I,J)=p8w(I,kms,J)

         DO k=kts,min(kte+1,kde)
            RTHBLTEN(I,K,J)=0.
            RUBLTEN(I,K,J)=0.
            RVBLTEN(I,K,J)=0.
            IF ( PRESENT( RQCBLTEN )) RQCBLTEN(I,K,J)=0.
            IF ( PRESENT( RQVBLTEN )) RQVBLTEN(I,K,J)=0.
         ENDDO

         IF (flag_QI .AND. PRESENT(RQIBLTEN) ) THEN
            DO k=kts,min(kte+1,kde)
               RQIBLTEN(I,K,J)=0.
            ENDDO
         ENDIF
         !Following if condition is added for CAMUWPBL scheme
         IF (flag_QNI .AND. PRESENT(RQNIBLTEN) ) THEN
            DO k=kts,min(kte+1,kde)
               RQNIBLTEN(I,K,J)=0.
            ENDDO
         ENDIF
      ENDDO
      ENDDO
#endif

      IF (bl_pbl_physics .EQ. QNSEPBLSCHEME ) THEN
#ifdef WRF_GPU
         CALL wrf_error_fatal('pbl_driver: QNSE not ported to the GPU')
#endif
! use u_phytmp instead of wthv_mf, and v_phytmp instead of lm_bl89
           DO j=j_start(ij),j_end(ij)
           DO i=i_start(ij),i_end(ij)
           DO k=kms,kme
              u_phytmp(i,k,j)=0.
              v_phytmp(i,k,j)=0.
           ENDDO
           ENDDO
           ENDDO
      ENDIF

      IF ( idiff.eq.1 ) THEN
#ifdef WRF_GPU
         CALL wrf_error_fatal('pbl_driver: idiff=1 not ported to the GPU')
#endif
!Alberto
! Here we should put a switch: 
! if we do not use BEP, just initialize the values of the a, and b to zero, except for the lowest model level, 
! where the heat and momentum fluxes are introduced         
! if we use BEP, use the values computed by BEP weigthed by the urban fraction.
! for the moment I put a simple "if" but it should be changed to a more elegant way after(using the CASE, maybe?)
!!!!!!!!!!!!!!
! This is the more general way to go, however some of these variables (e. g. a_t, a_q) may be zero nearly all time. 
! if we need to be as tight as possible for the memory we can think how to reduce the storage.
!!!!!!!!!!!!!!!!!!
! This stuff is becoming large, probably better to put in a subroutine
!!!!!!!!!!!!!!!!!!!
! preparing the a, b, sf, and vl terms
         
         IF (flag_bep) THEN    
           do j=j_start(ij),j_end(ij)
           do i=i_start(ij),i_end(ij)            
           do k=kts,kte
             a_u(i,k,j)=a_u_bep(i,k,j)
             a_v(i,k,j)=a_v_bep(i,k,j)
             a_t(i,k,j)=a_t_bep(i,k,j)
             a_q(i,k,j)=a_q_bep(i,k,j)
             b_u(i,k,j)=b_u_bep(i,k,j)
             b_v(i,k,j)=b_v_bep(i,k,j)
             b_t(i,k,j)=b_t_bep(i,k,j)
             b_q(i,k,j)=b_q_bep(i,k,j)
             vl(i,k,j)=vl_bep(i,k,j)
             sf(i,k,j)=sf_bep(i,k,j)
           enddo
           sf(i,kte+1,j)=1.
           enddo
           enddo
         ELSE
           do j=j_start(ij),j_end(ij)
           do i=i_start(ij),i_end(ij)
           do k=kts,kte
             a_u(i,k,j)=0.
             a_v(i,k,j)=0.
             a_t(i,k,j)=0.
             a_q(i,k,j)=0.
             b_u(i,k,j)=0.
             b_v(i,k,j)=0.
             b_t(i,k,j)=0.
             b_q(i,k,j)=0.
             vl(i,k,j)=1.
             sf(i,k,j)=1.
           enddo
           sf(i,kte+1,j)=1.
! fix the values for the surface fluxes (source/sink terms)
! here for momentum the resolution is done implicitely
! while for heat and moisture is done explicitely 
            a_u(i,1,j)=(-ust(I,J)*ust(I,J))/dz8w(i,1,j)/(rp_pow((u_phy(i,1,j)**2+v_phy(i,1,j)**2), .5))           
            a_v(i,1,j)=(-ust(I,J)*ust(I,J))/dz8w(i,1,j)/(rp_pow((u_phy(i,1,j)**2+v_phy(i,1,j)**2), .5))
            b_t(i,1,j)=hfx(i,j)/rho(i,1,j)/CP/dz8w(i,1,j)
            b_q(i,1,j)=qfx(i,j)/rho(i,1,j)/dz8w(i,1,j)
!! if you want to solve also the heat and moisture fluxes implicitely, uncomment the following lines.
!! (of course you will need the values of thz0,qz0,akhs).
!             b_t(i,1,j)=akhs(i,j)*(thz0(I,J))/dz8w(i,1,j)
!             b_q(i,1,j)=akhs(i,j)*(qz0(I,J))/dz8w(i,1,j)
!             a_t(i,1,j)=-1.*akhs(i,j)/dz8w(i,1,j)
!             a_q(i,1,j)=-1.*akhs(i,j)/dz8w(i,1,j)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
           enddo
           enddo
           
         ENDIF

        endif      
                                           
     
 
!Alberto. From this point if some PBL scheme has a non local term 
! (not dependent on the local values of the variable)
! this can be added to b_t, b_q, or b_u, b_v.
!!!!!!!!!!!!!!!!!!!           
 
   ENDDO
   !$OMP END PARALLEL DO
!
  !$OMP PARALLEL DO   &
  !$OMP PRIVATE ( ij, i,j,k, its, ite, jts, jte, z0, z1, z2, w1, w2, message, initflag )
  DO ij = 1 , num_tiles

#ifdef WRF_GPU
   its = i_start_h(ij)
   ite = i_end_h(ij)
   jts = j_start_h(ij)
   jte = j_end_h(ij)
#else
   its = i_start(ij)
   ite = i_end(ij)
   jts = j_start(ij)
   jte = j_end(ij)
#endif

   pbl_select: SELECT CASE(bl_pbl_physics)

      CASE (TEMFPBLSCHEME)
! WA Test
       ! WRITE( message , * ) 'Calling TEMF PBL scheme, timestep = ', itimestep
       ! CALL wrf_message ( message )
       ! print *,'Calling TEMF PBL scheme'
        CALL wrf_debug(100,'in TEMF PBL')
           IF ( PRESENT( qv_curr )  .AND. PRESENT( qc_curr )  .AND. &
                PRESENT( qi_curr )                            .AND. &
                PRESENT( rqvblten ) .AND. PRESENT( rqcblten ) .AND. &
                PRESENT( rqiblten )                           .AND. &
                PRESENT( te_temf ) .AND. PRESENT( cfm_temf ) .AND. &
                PRESENT( hol      ) ) THEN
             CALL temfpbl(                                              &
               U3D=u_phytmp,V3D=v_phytmp,TH3D=th_phy,T3D=t_phy      &
              ,QV3D=qv_curr,QC3D=qc_curr,QI3D=qi_curr               &
              ,P3D=p_phy,P3DI=p8w,PI3D=pi_phy,RHO=rho               &
              ,RUBLTEN=rublten,RVBLTEN=rvblten                      &
              ,RTHBLTEN=rthblten,RQVBLTEN=rqvblten                  &
              ,RQCBLTEN=rqcblten,RQIBLTEN=rqiblten                  &
              ,FLAG_QI=flag_qi                                      &
              ,g=g,cp=cp,rcp=rcp,r_d=r_d,r_v=r_v,cpv=cpv                    &
              ,Z=z,XLV=XLV,PSFC=PSFC               &
              ,P_TOP=p_top                                          &
              ,ZNT=znt,HT=ht,UST=ust,ZOL=zol,HOL=hol,HPBL=pblh      &
              ,PSIM=psim,PSIH=psih,XLAND=xland                      &
              ,HFX=hfx,QFX=qfx,TSK=tskold,QSFC=qsfc,GZ1OZ0=gz1oz0   &
              ,U10=u10,V10=v10,T2=t2                                &
              ,WSPD=wspd,BR=br,DT=dtbl,DTMIN=dtmin,KPBL2D=kpbl      &
              ,SVP1=svp1,SVP2=svp2,SVP3=svp3,SVPT0=svpt0            &
              ,EP1=ep_1,EP2=ep_2,KARMAN=karman,EOMEG=eomeg          &
              ,STBOLT=stbolt                                       &
              ,te_temf=te_temf,kh_temf=kh_temf,km_temf=km_temf      &
              ,shf_temf=shf_temf,qf_temf=qf_temf                    &
              ,uw_temf=uw_temf,vw_temf=vw_temf                      &
              ,hd_temf=hd_temf,lcl_temf=lcl_temf,hct_temf=hct_temf  &
              ,wupd_temf=wupd_temf,mf_temf=mf_temf                  &
              ,thup_temf=thup_temf,qtup_temf=qtup_temf,qlup_temf=qlup_temf  &
              ,cf3d_temf=cf3d_temf,cfm_temf=cfm_temf                &
              ,flhc=flhc,flqc=flqc,exch_temf=exch_temf              &
              ,fCor=f                                            &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      &
                                                                    )
           ELSE
               CALL wrf_error_fatal('Lack arguments to call TEMF pbl')
           ENDIF

      CASE (YSUSCHEME)
        CALL wrf_debug(100,'in YSU PBL')
           IF ( PRESENT( qv_curr )  .AND. PRESENT( qc_curr )  .AND. &
                PRESENT( qi_curr )                            .AND. &
                PRESENT( rqvblten ) .AND. PRESENT( rqcblten ) .AND. &
                PRESENT( rqiblten )                           .AND. &
                PRESENT( hol      ) ) THEN
!
             CALL ysu(                                              &
               U3D=u_phytmp,V3D=v_phytmp,T3D=t_phy                  &
              ,QV3D=qv_curr,QC3D=qc_curr,QI3D=qi_curr               &
              ,P3D=p_phy,P3DI=p8w,PI3D=pi_phy                       &
              ,RUBLTEN=rublten,RVBLTEN=rvblten                      &
              ,RTHBLTEN=rthblten,RQVBLTEN=rqvblten                  &
              ,RQCBLTEN=rqcblten,RQIBLTEN=rqiblten                  &
              ,FLAG_QI=flag_qi,FLAG_QC=flag_qc                      &
              ,CP=cp,G=g,ROVCP=rcp,RD=r_D,ROVG=rovg                 &
              ,DZ8W=dz8w,XLV=XLV,RV=r_v,PSFC=PSFC                   &
              ,ZNT=znt,UST=ust,HPBL=pblh                            &
              ,PSIM=fm,PSIH=fhh,XLAND=xland                         &
              ,HFX=hfx,QFX=qfx                                      &
              ,U10=u10,V10=v10                                      &
              ,UOCE=uoce,VOCE=voce                                  &
! paj
              ,CTOPO=ctopo,CTOPO2=ctopo2                            &
              ,YSU_TOPDOWN_PBLMIX=ysu_topdown_pblmix                &
              ,WSPD=wspd,BR=br,DT=dtbl,KPBL2D=kpbl                  &
              ,EP1=ep_1,EP2=ep_2,KARMAN=karman                      &
              ,EXCH_H=exch_h,EXCH_M=exch_m                          &
              ,RTHRATEN=RTHRATEN                                    &
! for multilayer UCM
              ,IDIFF=idiff,FLAG_BEP=flag_bep,FRC_URB2D=frc_urb2d    &
              ,A_U_BEP=a_u_bep,A_V_BEP=a_v_bep,A_T_BEP=a_t_bep      &
              ,A_Q_BEP=a_q_bep                                      &
              ,A_E_BEP=a_e_bep,B_U_BEP=b_u_bep,B_V_BEP=b_v_bep      &
              ,B_T_BEP=b_t_bep,B_Q_BEP=b_q_bep                      &
              ,B_E_BEP=b_e_bep,DLG_BEP=dlg_bep                      &
              ,DL_U_BEP=dl_u_bep,SF_BEP=sf_bep,VL_BEP=vl_bep        &
! for grims shallow convection with ysupbl
              ,WSTAR=wstar,DELTA=delta                              &
              ,errmsg=errmsg,errflg=errflg                          &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      &
                                                                   )
!
! FASDAS
!
              IF( fasdas == 1 ) THEN
#ifdef WRF_GPU
                  CALL wrf_error_fatal('pbl_driver: fasdas not ported to the GPU')
#endif
                  DO j=j_start(ij),j_end(ij)
                  DO i=i_start(ij),i_end(ij)
                     scrp1 = rqvblten(i,1,j)
                     scrp1 = scrp1*(2.0*DT)/qv_curr(i,1,j)
                     scrp1 = scrp1*100.0
                     scrp1 = amax1(0.0,scrp1)
                     scrp1 = amin1(5.0,scrp1)
                     QNORM(I,J)= scrp1/100.0
                  ENDDO
                  ENDDO
              ENDIF
!
! END FASDAS
!

           ELSE
               WRITE ( message , FMT = '(A,7(L1,1X))' )             &
                 'present: '//                                      &
                 'qv_curr, '//                                      &
                 'qc_curr, '//                                      &
                 'qi_curr, '//                                      &
                 'rqvblten, '//                                     &
                 'rqcblten, '//                                     &
                 'rqiblten, '//                                     &
                 'hol = ' ,                                         &
                  PRESENT( qv_curr ) ,                              &
                  PRESENT( qc_curr ) ,                              &
                  PRESENT( qi_curr ) ,                              &
                  PRESENT( rqvblten ) ,                             &
                  PRESENT( rqcblten ) ,                             &
                  PRESENT( rqiblten ) ,                             &
                  PRESENT( hol      )
               CALL wrf_debug(0,message)
               CALL wrf_error_fatal('Lack arguments to call YSU pbl')
           ENDIF

      CASE (SHINHONGSCHEME)
        CALL wrf_debug(100,'in SHINHONG PBL')
           IF ( PRESENT( qv_curr )  .AND. PRESENT( qc_curr )  .AND. &
                PRESENT( qi_curr )                            .AND. &
                PRESENT( rqvblten ) .AND. PRESENT( rqcblten ) .AND. &
                PRESENT( rqiblten )                           .AND. &
                PRESENT( hol      ) ) THEN
!
             CALL shinhong(                                         &
               U3D=u_phytmp,V3D=v_phytmp,TH3D=th_phy,T3D=t_phy      &
              ,QV3D=qv_curr,QC3D=qc_curr,QI3D=qi_curr               &
              ,P3D=p_phy,P3DI=p8w,PI3D=pi_phy                       &
              ,RUBLTEN=rublten,RVBLTEN=rvblten                      &
              ,RTHBLTEN=rthblten,RQVBLTEN=rqvblten                  &
              ,RQCBLTEN=rqcblten,RQIBLTEN=rqiblten                  &
              ,FLAG_QI=flag_qi                                      &
              ,CP=cp,G=g,ROVCP=rcp,RD=r_D,ROVG=rovg                 &
              ,DZ8W=dz8w,XLV=XLV,RV=r_v,PSFC=PSFC                   &
              ,ZNU=znu,ZNW=znw,P_TOP=p_top                          &
              ,ZNT=znt,UST=ust,HPBL=pblh                            &
              ,PSIM=fm,PSIH=fhh,XLAND=xland                         &
              ,HFX=hfx,QFX=qfx                                      &
              ,U10=u10,V10=v10                                      &
! paj
              ,CTOPO=ctopo,CTOPO2=ctopo2                            &
              ,SHINHONG_TKE_DIAG=shinhong_tke_diag                  &
              ,WSPD=wspd,BR=br,DT=dtbl,KPBL2D=kpbl                  &
              ,EP1=ep_1,EP2=ep_2,KARMAN=karman                      &
              ,EXCH_H=exch_h,REGIME=regime                          &
! for grims shallow convection with shinhongpbl
              ,WSTAR=wstar,DELTA=delta                              &
              ,TKE_PBL=tke_pbl,EL_PBL=el_pbl,CORF=f                 &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      &
              ,DX=dx,DY=dy                                          &
                                                                    )
           ELSE
               WRITE ( message , FMT = '(A,7(L1,1X))' )             &
                 'present: '//                                      &
                 'qv_curr, '//                                      &
                 'qc_curr, '//                                      &
                 'qi_curr, '//                                      &
                 'rqvblten, '//                                     &
                 'rqcblten, '//                                     &
                 'rqiblten, '//                                     &
                 'hol = ' ,                                         &
                  PRESENT( qv_curr ) ,                              &
                  PRESENT( qc_curr ) ,                              &
                  PRESENT( qi_curr ) ,                              &
                  PRESENT( rqvblten ) ,                             &
                  PRESENT( rqcblten ) ,                             &
                  PRESENT( rqiblten ) ,                             &
                  PRESENT( hol      )
               CALL wrf_debug(0,message)
               CALL wrf_error_fatal('Lack arguments to call SHINHONG pbl')
           ENDIF

      CASE (MRFSCHEME)
           IF ( PRESENT( qv_curr )  .AND. PRESENT( qc_curr )  .AND. &
                PRESENT( rqvblten ) .AND. PRESENT( rqcblten ) .AND. &
                PRESENT( hol      )                           .AND. &
                                                        .TRUE.  ) THEN

             CALL wrf_debug(100,'in MRF')
             CALL mrf(                                              &
               U3D=u_phytmp,V3D=v_phytmp,TH3D=th_phy,T3D=t_phy      &
              ,QV3D=qv_curr                                         &
              ,QC3D=qc_curr                                         &
              ,QI3D=qi_curr                                         &
              ,P3D=p_phy,PI3D=pi_phy                                &
              ,RUBLTEN=rublten,RVBLTEN=rvblten                      &
              ,RTHBLTEN=rthblten,RQVBLTEN=rqvblten                  &
              ,RQCBLTEN=rqcblten,RQIBLTEN=rqiblten                  &
              ,CP=cp,G=g,ROVCP=rcp,R=r_d,ROVG=rovg                  &
              ,DZ8W=dz8w,Z=z,XLV=xlv,RV=r_v,PSFC=psfc               &
              ,P1000MB=p1000mb                                      &
              ,ZNT=znt,UST=ust,ZOL=zol,HOL=hol                      &
              ,PBL=pblh,PSIM=psim,PSIH=psih                         &
              ,XLAND=xland,HFX=hfx,QFX=qfx,TSK=tskold               &
              ,GZ1OZ0=gz1oz0,WSPD=wspd,BR=br                        &
              ,DT=dtbl,DTMIN=dtmin,KPBL2D=kpbl                      &
              ,SVP1=svp1,SVP2=svp2,SVP3=svp3,SVPT0=svpt0            &
              ,EP1=ep_1,EP2=ep_2,KARMAN=karman,EOMEG=eomeg          &
              ,STBOLT=stbolt,REGIME=regime                          &
              ,FLAG_QI=flag_qi                                      &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      &
                                                                    ) 
           ELSE
               WRITE ( message , FMT = '(A,5(L1,1X))' )             &
                 'present: '//                                      &
                 'qv_curr, '//                                      &
                 'qc_curr, '//                                      &
                 'rqvblten, '//                                     &
                 'rqcblten, '//                                     &
                 'hol = ' ,                                         &
                  PRESENT( qv_curr ) ,                              &
                  PRESENT( qc_curr ) ,                              &
                  PRESENT( rqvblten ) ,                             &
                  PRESENT( rqcblten ) ,                             &
                  PRESENT( hol      )
               CALL wrf_debug(0,message)
               CALL wrf_error_fatal('Lack arguments to call MRF pbl')
           ENDIF

      CASE (GFSSCHEME)
           IF ( PRESENT( qv_curr )  .AND. PRESENT( qc_curr )  .AND. &
                PRESENT( rqvblten ) .AND. PRESENT( rqcblten ) .AND. &
                                                        .TRUE.  ) THEN
             CALL wrf_debug(100,'in GFS')
             CALL bl_gfs(                                           &
               U3D=u_phytmp,V3D=v_phytmp                            &
              ,TH3D=th_phy,T3D=t_phy                                &
              ,QV3D=qv_curr,QC3D=qc_curr,QI3D=qi_curr               &
              ,P3D=p_phy,PI3D=pi_phy                                &
              ,RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten    &
              ,RQVBLTEN=rqvblten,RQCBLTEN=rqcblten                  &
              ,RQIBLTEN=rqiblten                                    &
              ,CP=cp,G=g,ROVCP=rcp,R=r_d,ROVG=rovg                  &
              ,DZ8W=dz8w,z=z,PSFC=psfc                              &
              ,UST=ust,PBL=pblh,PSIM=psim,PSIH=psih                 &
              ,HFX=hfx,QFX=qfx,TSK=tskold,GZ1OZ0=gz1oz0             &
              ,WSPD=wspd,BR=br                                      &
              ,DT=dtbl,KPBL2D=kpbl,EP1=ep_1,KARMAN=karman           &
              ,P_QI=p_qi,P_FIRST_SCALAR=param_first_scalar          &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      &
                                                                    )
           ELSE
               WRITE ( message , FMT = '(A,4(L1,1X))' )             &
                 'present: '//                                      &
                 'qv_curr, '//                                      &
                 'qc_curr, '//                                      &
                 'rqvblten, '//                                     &
                 'rqcblten = ',                                     &
                  PRESENT( qv_curr ) ,                              &
                  PRESENT( qc_curr ) ,                              &
                  PRESENT( rqvblten ) ,                             &
                  PRESENT( rqcblten )
               CALL wrf_debug(0,message)
               CALL wrf_error_fatal('Lack arguments to call GFS pbl')
           ENDIF

      CASE (MYJPBLSCHEME)
           IF ( PRESENT( qv_curr )  .AND. PRESENT( qc_curr )  .AND. &
                PRESENT( rqvblten ) .AND. PRESENT( rqcblten ) .AND. &
                                                        .TRUE.  ) THEN

             CALL wrf_debug(100,'in MYJPBL')
            IF ( .not.flag_bep .and. idiff.ne.1) THEN
             CALL myjpbl(DT=dt,STEPBL=stepbl,HT=ht,DZ=dz8w          &
              ,PMID=p_phy,PINT=p8w,TH=th_phy,T=t_phy,EXNER=pi_phy   &
              ,QV=qv_curr,QCW=qc_curr,QCI=qi_curr,QCS=qs_curr       & !BSF
              ,QCR=qr_curr,QCG=qg_curr                              & !BSF
              ,U=u_phy,V=v_phy,RHO=rho                              &
              ,TSK=tsk,QSFC=qsfc,CHKLOWQ=chklowq,THZ0=thz0          &
              ,QZ0=qz0,UZ0=uz0,VZ0=vz0                              &
              ,LOWLYR=lowlyr                                        &
              ,XLAND=xland,SICE=xice,SNOW=snow                      &
              ,TKE_MYJ=tke_pbl,EXCH_H=exch_h,USTAR=ust,ZNT=znt      &
              ,EL_MYJ=el_pbl,PBLH=pblh,KPBL=kpbl,CT=ct              &
              ,AKHS=akhs,AKMS=akms,ELFLX=lh,MIXHT=mixht             &  
              ,RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten    &
              ,RQVBLTEN=rqvblten,RQCBLTEN=rqcblten                  &
              ,RQIBLTEN=rqiblten,RQSBLTEN=rqsblten                  & !BSF
              ,RQRBLTEN=rqrblten,RQGBLTEN=rqgblten                  & !BSF
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      &
                                                                    )
            ELSE !(SF_URBAN_PHYSICS.EQ.2)
! Bep changes begin

             CALL myjurb(IDIFF=idiff,FLAG_BEP=flag_bep              &
              ,DT=dtbl,STEPBL=stepbl,HT=ht,DZ=dz8w                  &
              ,PMID=p_phy,PINT=p8w,TH=th_phy,T=t_phy,EXNER=pi_phy   &
              ,QV=qv_curr, CWM=qc_curr                              &
              ,U=u_phy,V=v_phy,RHO=rho                              &
              ,TSK=tsk,QSFC=qsfc,CHKLOWQ=chklowq,THZ0=thz0          &
              ,QZ0=qz0,UZ0=uz0,VZ0=vz0                              &
              ,LOWLYR=lowlyr                                        &
              ,XLAND=xland,SICE=xice,SNOW=snow                      &
              ,TKE_MYJ=tke_pbl,EXCH_H=exch_h,EXCH_M=exch_m          &
              ,USTAR=ust,ZNT=znt                                    &
              ,EL_MYJ=el_pbl,PBLH=pblh,KPBL=kpbl,CT=ct              &
              ,AKHS=akhs,AKMS=akms,ELFLX=lh                         &
              ,RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten    &
              ,RQVBLTEN=rqvblten,RQCBLTEN=rqcblten                  &
! Multi-layer UCM
              ,FRC_URB2D=frc_urb2d                                  &
              ,A_U_BEP=a_u_bep,A_V_BEP=a_v_bep,A_T_BEP=a_t_bep      &
              ,A_Q_BEP=a_q_bep                                      &
              ,A_E_BEP=a_e_bep,B_U_BEP=b_u_bep,B_V_BEP=b_v_bep      &
              ,B_T_BEP=b_t_bep,B_Q_BEP=b_q_bep                      &
              ,B_E_BEP=b_e_bep,DLG_BEP=dlg_bep                      &
              ,DL_U_BEP=dl_u_bep,SF_BEP=sf_bep,VL_BEP=vl_bep        &
! UCM end
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      &
                                                                    )
            ENDIF

           ELSE
               WRITE ( message , FMT = '(A,4(L1,1X))' )             &
                 'present: '//                                      &
                 'qv_curr, '//                                      &
                 'qc_curr, '//                                      &
                 'rqvblten, '//                                     &
                 'rqcblten = ' ,                                    &
                  PRESENT( qv_curr ) ,                              &
                  PRESENT( qc_curr ) ,                              &
                  PRESENT( rqvblten ) ,                             &
                  PRESENT( rqcblten )
               CALL wrf_debug(0,message)
               CALL wrf_error_fatal('Lack arguments to call MYJ pbl')
           ENDIF
 
      CASE (QNSEPBLSCHEME)
           IF ( PRESENT( qv_curr )  .AND. PRESENT( qc_curr )  .AND. &
                PRESENT( rqvblten ) .AND. PRESENT( rqcblten ) .AND. &
                                                        .TRUE.  ) THEN
               IF ( MFSHCONV.EQ.1 )THEN
               CALL wrf_debug(100,'in MFSHCONVPBL')
               CALL mfshconvpbl(DT=dt,STEPBL=stepbl,HT=ht,DZ=dz8w         &
                    ,RHO=rho,PMID=p_phy,PINT=p8w,TH=th_phy,EXNER=pi_phy   &
                    ,QV=qv_curr, QC=qc_curr                    &
                    ,U=u_phy,V=v_phy                                      &
                    ,HFX=hfx, QFX=qfx,TKE=tke_pbl                         &
                    ,RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten    &
                    ,RQVBLTEN=rqvblten,RQCBLTEN=rqcblten                  &
                    ,IDS=IDS,IDE=IDE,JDS=JDS,JDE=JDE,KDS=KDS,KDE=KDE      &
                    ,IMS=IMS,IME=IME,JMS=JMS,JME=JME,KMS=KMS,KME=KME      &
                    ,ITS=ITS,ITE=ITE,JTS=JTS,JTE=JTE,KTS=KTS,KTE=KTE      &
                    ,KRR=2,MASSFLUX_EDKF=massflux_EDKF                    &
                    ,ENTR_EDKF=entr_EDKF, DETR_EDKF=detr_EDKF             & 
                    ,THL_UP=thl_up, THV_UP=thv_up, RT_UP=rt_up            &
                    ,RV_UP=rv_up,RC_UP=rc_up, U_UP=u_up, V_UP=v_up        &
                    ,FRAC_UP=frac_up, RC_MF=rc_mf,WTHV=u_phytmp           &
                    ,PLM_BL89=v_phytmp   ) 
               ENDIF   

             CALL wrf_debug(100,'in QNSEPBL')
             CALL qnsepbl(                                           &
               DT=dt,STEPBL=stepbl,HT=ht,DZ=dz8w                    &
              ,PMID=p_phy,PINT=p8w,TH=th_phy,T=t_phy,EXNER=pi_phy   &
              ,QV=qv_curr, CWM=qc_curr                              &
              ,U=u_phy,V=v_phy,RHO=rho                              &
              ,TSK=tsk,QSFC=qsfc,CHKLOWQ=chklowq,THZ0=thz0          &
              ,QZ0=qz0,UZ0=uz0,VZ0=vz0,CORF=f                       &
              ,LOWLYR=lowlyr                                        &
              ,XLAND=xland,SICE=xice,SNOW=snow                      &
              ,TKE=tke_pbl,EXCH_H=exch_h,EXCH_M=exch_m,USTAR=ust,ZNT=znt      &
              ,EL_MYJ=el_pbl,PBLH=pblh,KPBL=kpbl,CT=ct              &
              ,AKHS=akhs,AKMS=akms,ELFLX=lh                         &
              ,HFX=hfx,WTHV_MF=u_phytmp,LM_BL89=v_phytmp            & 
              ,RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten    &
              ,RQVBLTEN=rqvblten,RQCBLTEN=rqcblten                  &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      &
                                                                    )
! note the tendencies have been added inside qnse 
!            IF ( PRESENT (MFSHCONV) )THEN
!              IF (MFSHCONV.EQ.1)THEN
!              rublten(:,:,:)=rublten(:,:,:)+rumften(:,:,:)
!              rvblten(:,:,:)=rvblten(:,:,:)+rvmften(:,:,:)
!              rthblten(:,:,:)=rthblten(:,:,:)+rthmften(:,:,:)
!              rqvblten(:,:,:)=rqvblten(:,:,:)+rqvmften(:,:,:)
!              rqcblten(:,:,:)=rqcblten(:,:,:)+rqcmften(:,:,:)
!              ENDIF   
!            ENDIF   

            ELSE
               WRITE ( message , FMT = '(A,4(L1,1X))' )             &
                 'present: '//                                      &
                 'qv_curr, '//                                      &
                 'qc_curr, '//                                      &
                 'rqvblten, '//                                     &
                 'rqcblten = ' ,                                    &
                  PRESENT( qv_curr ) ,                              &
                  PRESENT( qc_curr ) ,                              &
                  PRESENT( rqvblten ) ,                             &
                  PRESENT( rqcblten )
               CALL wrf_debug(0,message)
               CALL wrf_error_fatal('Lack arguments to call QNSE pbl')
           ENDIF

      CASE (ACMPBLSCHEME)
           
           !!  These are values that are not supplied to pbl driver, but are required by ACM
           IF ( PRESENT( qv_curr )  .AND. PRESENT( qc_curr )  .AND. &
                PRESENT( rqvblten ) .AND. PRESENT( rqcblten ) .AND. &
                                                        .TRUE.  ) THEN
             CALL wrf_debug(100,'in ACM PBL')

             CALL ACMPBL(                                                        &
               XTIME=itimestep, DTPBL=dtbl,U3D=u_phytmp, V3D=v_phytmp          &
              ,PP3D=p_phy, DZ8W=dz8w, TH3D=th_phy, T3D=t_phy                   &
              ,QV3D=qv_curr, QC3D=qc_curr, QI3D=qi_curr, RR3D=rho                &
#if (WRF_CHEM == 1)
              ,CHEM3D=CHEM,   VD3D=VD,  NCHEM=nchem, KDVEL=kdvel              &
              ,NDVEL=ndvel, NUM_VERT_MIX=num_vert_mix                         &
#endif
              ,UST=UST, HFX=HFX, QFX=QFX, TSK=tsk                               &
              ,PSFC=PSFC, EP1=EP_1, G=g, ROVCP=rcp,RD=r_D,CPD=cp                 &
              ,PBLH=pblh, KPBL2D=kpbl, EXCH_H=exch_h, EXCH_M=exch_m              &
              ,REGIME=regime                                                     &
              ,GZ1OZ0=gz1oz0,WSPD=wspd,PSIM=psim, MUT=mut, RMOL=rmol             &
              ,RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten                 &
              ,RQVBLTEN=rqvblten,RQCBLTEN=rqcblten,RQIBLTEN=rqiblten             &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde                   &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme                   &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte                   &   
                                                                      )
           ELSE
               WRITE ( message , FMT = '(A,4(L1,1X))' )             &
                 'present: '//                                      &
                 'qv_curr, '//                                      &
                 'qc_curr, '//                                      &
                 'rqvblten, '//                                     &
                 'rqcblten = ' ,                                    &
                  PRESENT( qv_curr ) ,                              &
                  PRESENT( qc_curr ) ,                              &
                  PRESENT( rqvblten ) ,                             &
                  PRESENT( rqcblten )
               CALL wrf_debug(0,message)
               CALL wrf_error_fatal('Lack arguments to call ACM2 pbl')
           ENDIF

#if (EM_CORE==1)

        CASE (MYNNPBLSCHEME)

           IF ( PRESENT( qv_curr )  .AND. PRESENT( qc_curr )  .AND. &
                PRESENT( rqvblten ) .AND. PRESENT( rqcblten ) .AND. &
                PRESENT( qi_curr ) .AND. PRESENT( rqiblten ) .AND.  &
                PRESENT( rqniblten ) .AND. PRESENT( qni_curr ) .AND.&
                PRESENT(qke) .AND. PRESENT(tsq) .AND.               &
                PRESENT(qsq) .AND. PRESENT(cov) .AND.               &
                PRESENT(rmol) .AND. PRESENT(ch) .AND.               &
                PRESENT(tke_budget) .AND. PRESENT(qke_adv) .AND.    &
                PRESENT(bl_mynn_tkeadvect)  ) THEN

              CALL wrf_debug(100,'in MYNNPBL')

              IF (itimestep==1) THEN
                 initflag=1
              ELSE
                 initflag=0
              ENDIF
              
              if (pert_mynn .and. multi_perturb == 1) then
                allocate (qke_tmp(its:ite, kts:kte, jts:jte))

                call Add_multi_perturb_pbl_perturbations (               &
                  perts_qvapor, perts_qcloud, perts_th, perts_tke,       &
                  pert_mynn_qv, pert_mynn_qc, pert_mynn_t, pert_mynn_qke,&
                  th_phy, qke, qke_adv, qv_curr, qc_curr,                &
                  bl_mynn_tkeadvect, qke_tmp, its, ite, jts, jte,        &
                  ims, ime, jms, jme, kms, kme, kts, kte)
              end if

              CALL mynnedmf_wrapper_run(                                 &
                   &initflag=initflag,restart=restart,cycling=cycling,   &
                   &delt=dtbl,dz=dz8w,dxc=dx,znt=znt,                    &
                   &u=u_phy,v=v_phy,w=w,th=th_phy,qv=qv_curr,            &
                   &qc=qc_curr,qi=qi_curr,qs=qs_curr,                    &
                   &qnc=qnc_curr,qni=qni_curr,                           &
                   &QNWFA=qnwfa_curr,QNIFA=qnifa_curr,QNBCA=qnbca_curr,  &
!                   &ozone=ozone,                                         &
                   &p=p_phy,exner=pi_phy,rho=rho,T3D=t_phy,              &
                   &xland=xland,ts=tsk,qsfc=qsfc,ps=psfc,                &
                   &ust=ust,ch=ch,hfx=hfx,qfx=qfx,rmol=rmol,wspd=wspd,   &
                   &uoce=uoce,voce=voce,                                 & !Ocean currents
                   &Qke=qke,qke_adv=qke_adv,Sh3d=Sh3d,Sm3d=Sm3d,         &
#if (WRF_CHEM == 1)
                   &mix_chem=mynn_chem_vertmx,                           &
                   &chem3d=chem,vd3d=vd,nchem=nchem,kdvel=kdvel,         &
                   &ndvel=ndvel,num_vert_mix=num_vert_mix,               &
!                   &FRP_MEAN=FRP_MEAN,EMIS_ANT_NO=EMIS_ANT_NO,           & !to be included soon
!                   &fire_turb=enh_vermix,                                & !to be included soon
#endif
                   &Tsq=tsq,Qsq=qsq,Cov=cov,                             &
                   &RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten,   &
                   &RQVBLTEN=rqvblten,RQCBLTEN=rqcblten,RQIBLTEN=rqiblten,&
                   &RQNCBLTEN=rqncblten,RQNIBLTEN=rqniblten,             &
                   &RQSBLTEN=rqsblten,                                   &
                   &RQNWFABLTEN=rqnwfablten,RQNIFABLTEN=rqnifablten,     &
                   &RQNBCABLTEN=rqnbcablten,                             &
!                   &Ro3BLTEN=ro3blten,                                   &
                   &EXCH_H=exch_h,EXCH_M=exch_m,                         &
                   &pblh=pblh,KPBL=KPBL,                                 &
                   &el_pbl=el_pbl,                                       &
                   &dqke=dqke,                                           &
                   &qWT=qWT,qSHEAR=qSHEAR,qBUOY=qBUOY,qDISS=qDISS,       &
                   &qc_bl=qc_bl,qi_bl=qi_bl,cldfra_bl=cldfra_bl,         &
                   &edmf_a=edmf_a,edmf_w=edmf_w,edmf_qt=edmf_qt,         &
                   &edmf_thl=edmf_thl,edmf_ent=edmf_ent,edmf_qc=edmf_qc, &
                   &sub_thl3D=sub_thl3D,sub_sqv3D=sub_sqv3D,             &
                   &det_thl3D=det_thl3D,det_sqv3D=det_sqv3D,             &
                   &maxwidth=maxwidth,maxMF=maxMF,                       &
                   &ztop_plume=ztop_plume,ktop_plume=ktop_plume,         &
                   &RTHRATEN=RTHRATEN,                                   &
                   &bl_mynn_tkeadvect=bl_mynn_tkeadvect,                 &
                   &tke_budget=tke_budget,                               &
                   &bl_mynn_cloudpdf=bl_mynn_cloudpdf,                   &
                   &bl_mynn_mixlength=bl_mynn_mixlength,                 &
                   &icloud_bl=icloud_bl,                                 &
                   &bl_mynn_edmf=bl_mynn_edmf,                           &
                   &bl_mynn_edmf_mom=bl_mynn_edmf_mom,                   &
                   &bl_mynn_edmf_tke=bl_mynn_edmf_tke,                   &
                   &bl_mynn_mixscalars=bl_mynn_mixscalars,               &
                   &bl_mynn_output=bl_mynn_output,                       &
                   &bl_mynn_cloudmix=bl_mynn_cloudmix,                   &
                   &bl_mynn_mixqt=bl_mynn_mixqt,                         &
                   &bl_mynn_closure=bl_mynn_closure,                     &
                   &spp_pbl=spp_pbl,pattern_spp_pbl=pattern_spp_pbl,     &
                   &FLAG_QC=flag_qc,FLAG_QI=flag_qi,FLAG_QS=flag_qs,     &
                   &FLAG_QNC=flag_qnc,FLAG_QNI=flag_qni,                 &
                   &FLAG_QNWFA=flag_qnwfa,FLAG_QNIFA=flag_qnifa,         &
                   &FLAG_QNBCA=flag_qnbca,                               &
                   &IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde,     &
                   &IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme,     &
                   &ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      )

              if (pert_mynn .and. multi_perturb == 1) then
                call Remove_multi_perturb_pbl_perturbations (            &
                  perts_qvapor, perts_qcloud, perts_th, perts_tke,       &
                  pert_mynn_qv, pert_mynn_qc, pert_mynn_t, pert_mynn_qke,&
                  th_phy, qke, qke_adv, qv_curr, qc_curr,                &
                  bl_mynn_tkeadvect, qke_tmp, its, ite, jts, jte,        &
                  ims, ime, jms, jme, kms, kme, kts, kte)

                  deallocate (qke_tmp)
              end if
           ELSE
               WRITE ( message , FMT = '(A,17(L1,1X))' )            &
                 'present: '//                                      &
                 'qv_curr, '//                                      &
                 'qc_curr, '//                                      &
                 'qi_curr, '//                                      &
                 'qni_curr, '//                                     &
                 'rqvblten, '//                                     &
                 'rqcblten, '//                                     &
                 'rqiblten, '//                                     &
                 'rqniblten, '//                                    &
                 'qke, '//                                          &
                 'tsq, '//                                          &
                 'qsq, '//                                          &
                 'cov, '//                                          &
                 'rmol, '//                                         &
                 'ch, '//                                           &
                 'tke_budget, '//                                   &
                 'qke_adv, '//                                      &
                 'bl_mynn_tkeadvect ' ,                             &
                  PRESENT( qv_curr ) ,                              &
                  PRESENT( qc_curr ) ,                              &
                  PRESENT( qi_curr ) ,                              &
                  PRESENT( qni_curr ) ,                             &
                  PRESENT( rqvblten ) ,                             &
                  PRESENT( rqcblten ) ,                             &
                  PRESENT( rqiblten ) ,                             &
                  PRESENT( rqniblten ) ,                            &
                  PRESENT( qke      ) ,                             &
                  PRESENT( tsq      ) ,                             &
                  PRESENT( qsq      ) ,                             &
                  PRESENT( cov      ) ,                             &
                  PRESENT( rmol     ) ,                             &
                  PRESENT( ch       ) ,                             &
                  PRESENT( tke_budget) ,                            &
                  PRESENT( qke_adv  ) ,                             &
                  PRESENT( bl_mynn_tkeadvect)
               CALL wrf_debug(0,message)
              CALL wrf_error_fatal('Lack arguments to call MYNN pbl')
           ENDIF

           !fill scalar_tend array. The RQN*BLTEN arrays are no longer
           !passed to module_physics_addtendc.F (for MYNN)
           IF (bl_mynn_mixscalars .eq. 1) THEN
              IF (PRESENT( qni_curr ) .AND. Flag_qni) THEN
                !print*,"Updating qni after mynn-edmf",P_QNI
                DO j=j_start(ij),j_end(ij)
                DO k=kts,kte 
                DO i=i_start(ij),i_end(ij)
                   scalar_tend(i,k,j,P_QNI)=RQNIBLTEN(i,k,j)
                enddo
                enddo
                enddo
              ENDIF
              IF (PRESENT( qnc_curr ) .AND. Flag_qnc) THEN
                !print*,"Updating qnc after mynn-edmf",P_QNC
                DO j=j_start(ij),j_end(ij)
                DO k=kts,kte
                DO i=i_start(ij),i_end(ij)
                   scalar_tend(i,k,j,P_QNC)=RQNCBLTEN(i,k,j)
                enddo
                enddo
                enddo
              ENDIF
              IF (PRESENT( qnwfa_curr ) .AND. Flag_qnwfa) THEN
                !print*,"Updating qnwfa after mynn-edmf",P_QNWFA
                DO j=j_start(ij),j_end(ij)
                DO k=kts,kte
                DO i=i_start(ij),i_end(ij)
                   scalar_tend(i,k,j,P_QNWFA)=RQNWFABLTEN(i,k,j)
                enddo
                enddo
                enddo
              ENDIF
              IF (PRESENT( qnifa_curr ) .AND. Flag_qnifa) THEN
                !print*,"Updating qnifa after mynn-edmf",P_QNIFA
                DO j=j_start(ij),j_end(ij)
                DO k=kts,kte
                DO i=i_start(ij),i_end(ij)
                   scalar_tend(i,k,j,P_QNIFA)=RQNIFABLTEN(i,k,j)
                enddo
                enddo
                enddo
              ENDIF
              IF (PRESENT( qnbca_curr ) .AND. Flag_qnbca) THEN
                !print*,"Updating qnbca after mynn-edmf",P_QNBCA
                DO j=j_start(ij),j_end(ij)
                DO k=kts,kte
                DO i=i_start(ij),i_end(ij)
                   scalar_tend(i,k,j,P_QNBCA)=RQNBCABLTEN(i,k,j)
                enddo
                enddo
                enddo
              ENDIF
           ENDIF

        CASE (EEPSSCHEME)

              IF ( PRESENT( qv_curr )  .AND. PRESENT( qc_curr )  .AND. &
                   PRESENT( qi_curr )                            .AND. &
                   PRESENT( rqvblten ) .AND. PRESENT( rqcblten ) .AND. &
                   PRESENT( rqiblten )                           .AND. &
                   PRESENT( pek )      .AND. PRESENT( pep)       .AND. &
                   PRESENT( pek_adv )  .AND. PRESENT( pep_adv ) ) THEN

                CALL wrf_debug(100,'in EEPSPBL')

                CALL  eeps(&
                   U3D=u_phytmp,V3D=v_phytmp,T3D=t_phy                  &
                  ,QV3D=qv_curr,QC3D=qc_curr,QI3D=qi_curr               &
                  ,QR3D=qr_curr,QS3D=qs_curr,QG3D=qg_curr               &
                  ,P3D=p_phy,PI3D=pi_phy,PEK=pek,PEP=pep                &
                  ,RHO3D=rho,RTHRATEN=rthraten                          &
                  ,RUBLTEN=rublten,RVBLTEN=rvblten                      &
                  ,RTHBLTEN=rthblten,RQVBLTEN=rqvblten                  &
                  ,RQCBLTEN=rqcblten,RQIBLTEN=rqiblten,KPBL=kpbl        &
                  ,DZ8W=dz8w,PSFC=psfc,TSK=tsk,QSFC=qsfc,WSPD=wspd      &
                  ,UST=ust,XLAND=xland,HFX=hfx,QFX=qfx,RMOL=rmol        &
                  ,DT=dtbl,DX=dx,EXCH_H=exch_h,EXCH_M=exch_m,PBLH=pblh  &
                  ,ITIMESTEP=itimestep,PEK_ADV=pek_adv,PEP_ADV=pep_adv   &
                   ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
                   ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
                   ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      &
                   )
              ELSE
               WRITE ( message , FMT = '(A,6(L1,1X))' )             &
                 'present: '//                                      &
                 'qv_curr, '//                                      &
                 'qc_curr, '//                                      &
                 'qi_curr, '//                                      &
                 'rqvblten, '//                                     &
                 'rqcblten, '//                                     &
                 'rqiblten, ' ,                                     &
                  PRESENT( qv_curr ) ,                              &
                  PRESENT( qc_curr ) ,                              &
                  PRESENT( qi_curr ) ,                              &
                  PRESENT( rqvblten ) ,                             &
                  PRESENT( rqcblten ) ,                             &
                  PRESENT( rqiblten )
               CALL wrf_debug(0,message)
               CALL wrf_error_fatal('Lack arguments to call EEPS pbl')
           ENDIF


               CASE (KEPSSCHEME)

             CALL wrf_debug(100,'in keps')
             CALL KEPS(TSK=tsk,MOL=mol,XTIME=itimestep,FRC_URB2D=frc_urb2d            &
              , FLAG_BEP=flag_bep  &
              ,DZ8W=dz8w,DT=dt,U_PHY=u_phytmp                                  &
              ,V_PHY=v_phytmp,TH_PHY=th_phy                                    &
              ,PI_PHY=pi_phy,RTHRATEN=RTHRATEN,P8W=p8w                         &
              ,RHO=rho,QV_CURR=qv_curr,QC_CURR=qc_curr,HFX=hfx                 &
              ,QFX=qfx,USTAR=ust,CP=cp,G=g                                     &
              ,RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten               &
              ,RQVBLTEN=rqvblten,RQCBLTEN=rqcblten                             &
              ,TKE_PBL=tke_pbl,DISS_PBL=diss_pbl,TPE_PBL=tpe_pbl               &
              ,TKE_ADV=tke_adv,DISS_ADV=diss_adv,TPE_ADV=tpe_adv               &
              ,PR_PBL=pr_pbl                                                   &
              ,WU=wu_tur,WV=wv_tur,WT=wt_tur,WQ=wq_tur                         &
              ,EXCH_H=exch_h,EXCH_M=exch_m,PBLH=pblh                           &
              ,A_U_BEP=a_u_bep,A_V_BEP=a_v_bep,A_T_BEP=a_t_bep                 &
              ,A_Q_BEP=a_q_bep                                                 &
              ,B_U_BEP=b_u_bep,B_V_BEP=b_v_bep                                 &
              ,B_T_BEP=b_t_bep                                                 &
              ,B_Q_BEP=b_q_bep                                                 &
              ,B_E_BEP=b_e_bep                                                 &
              ,SF_BEP=sf_bep,VL_BEP=vl_bep                                     &
              ,BR=br,ZNT=znt                                                   &
              ,PSIM=psim,PSIH=psih                                             &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde                 &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme                 &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte  )



        CASE (BOULACSCHEME)

             CALL wrf_debug(100,'in boulac')

             CALL BOULAC(FRC_URB2D=frc_urb2d,IDIFF=idiff,FLAG_BEP=flag_bep     &
              ,DZ8W=dz8w,DT=dt,U_PHY=u_phytmp                                  &
              ,V_PHY=v_phytmp,TH_PHY=th_phy                                    &
              ,RHO=rho,QV_CURR=qv_curr,QC_CURR=qc_curr,HFX=hfx                 &
              ,QFX=qfx,USTAR=ust,CP=cp,G=g                                     &
              ,RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten               &
              ,RQVBLTEN=rqvblten,RQCBLTEN=rqcblten                             &
              ,TKE=tke_pbl,DLK=el_pbl,WU=wu_tur,WV=wv_tur,WT=wt_tur,WQ=wq_tur  &
              ,EXCH_H=exch_h,EXCH_M=exch_m,PBLH=pblh                           &
              ,A_U_BEP=a_u_bep,A_V_BEP=a_v_bep,A_T_BEP=a_t_bep                 &
              ,A_Q_BEP=a_q_bep                                                 &
              ,A_E_BEP=a_e_bep,B_U_BEP=b_u_bep,B_V_BEP=b_v_bep                 &
              ,B_T_BEP=b_t_bep,B_E_BEP=b_e_bep,DLG_BEP=dlg_bep                 &
              ,B_Q_BEP=b_q_bep                                                 &
              ,DL_U_BEP=dl_u_bep,SF_BEP=sf_bep,VL_BEP=vl_bep                   &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde                 &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme                 &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte  )

           CASE (CAMUWPBLSCHEME)
              
              CALL wrf_debug(100,'in camuwpbl')
              IF ( PRESENT( qv_curr  )  .AND. PRESENT( qc_curr   )  .AND. &
                   PRESENT( qi_curr  )  .AND. PRESENT( qnc_curr  )  .AND. &
                   PRESENT( qni_curr )  .AND.                             &
                   PRESENT( rqvblten )  .AND. PRESENT( rqcblten  )  .AND. &
                   PRESENT( rqiblten )  .AND. PRESENT( rqniblten )        &                   
                 )THEN
                 CALL CAMUWPBL(DT=dt,U_PHY=u_phy,V_PHY=v_phy,TH_PHY=th_phy,RHO=rho   &
                      ,QV_CURR=qv_curr,HFX=hfx,QFX=qfx,USTAR=ust,P8W=p8w,P_PHY=p_phy &
                      ,Z=z,T_PHY=t_phy,QC_CURR=qc_curr,QI_CURR=qi_curr,Z_AT_W=z_at_w &
                      ,CLDFRA_OLD_mp=cldfra_old_mp,CLDFRA=cldfra,HT=ht               &
                      ,RTHRATENLW=rthratenlw,EXNER=pi_phy                            &
                      ,is_CAMMGMP_used=is_CAMMGMP_used                               &
                      ,ITIMESTEP=itimestep,QNC_CURR=qnc_curr,QNI_CURR=qni_curr       &
                      ,WSEDL3D=wsedl3d                                               &

                      ,IDS=ids,IDE=ide, JDS=jds,JDE=jde, KDS=kds,KDE=kde             &
                      ,IMS=ims,IME=ime, JMS=jms,JME=jme, KMS=kms,KME=kme             &
                      ,ITS=its,ITE=ite, JTS=jts,JTE=jte, KTS=kts,KTE=kte             &
!Intent-inout 
                      ,TAURESX2D=tauresx2d,TAURESY2D=tauresy2d                       &
                      ,RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten             &
                      ,RQIBLTEN=rqiblten,RQNIBLTEN=rqniblten,RQVBLTEN=rqvblten       &
                      ,RQCBLTEN=rqcblten,KVM3D=exch_m,KVH3D=exch_h                   &
!Intent-out
                      ,TPERT2D=tpert2d,QPERT2D=qpert2d,WPERT2D=wpert2d,SMAW3D=smaw3d &
                      ,TURBTYPE3D=turbtype3d                                         &
                      ,TKE_pbl=tke_pbl,PBLH2D=pblh,KPBL2D=kpbl                       )
              ELSE
                 WRITE ( message , FMT = '(A,8(L1,1X))' )            &
                      'present: '//                                      &
                      'qv_curr, '//                                      &
                      'qc_curr, '//                                      &
                      'qi_curr, '//                                      &
                      'qnc_curr, '//                                     &
                      'qni_curr, '//                                     &
                      'rqvblten, '//                                     &
                      'rqcblten, '//                                     &
                      'rqiblten, '//                                     &
                      'rqniblten= ',                                     &
                      PRESENT( qv_curr ) ,                              &
                      PRESENT( qc_curr ) ,                              &
                      PRESENT( qi_curr ) ,                              &
                      PRESENT( qnc_curr ) ,                             &
                      PRESENT( qni_curr ) ,                             &
                      PRESENT( rqvblten ) ,                             &
                      PRESENT( rqcblten ) ,                             &
                      PRESENT( rqiblten ) ,                             &
                      PRESENT( rqniblten ) 

                 CALL wrf_debug(0,message)
                 CALL wrf_error_fatal('Lack arguments to call CAMUWPBL pbl')
              ENDIF
              
#endif

           CASE (GBMPBLSCHEME)
               CALL wrf_debug(100,'in gbmpbl') 
               IF ( PRESENT( qv_curr )  .AND. PRESENT( qc_curr )  .AND.&
               PRESENT( qi_curr )                            .AND. &
               PRESENT( rqvblten ) .AND. PRESENT( rqcblten ) .AND. &
               PRESENT( rqiblten )                           .AND. &
               PRESENT( hol      )                           .AND. &
                                       .TRUE.  ) THEN
             CALL gbmpbl(                                           &
               U3D=u_phytmp,V3D=v_phytmp,TH3D=th_phy,T3D=t_phy      &
              ,QV3D=qv_curr,QC3D=qc_curr,QI3D=qi_curr               &
              ,P3D=p_phy,PI3D=pi_phy                                &
              ,RUBLTEN=rublten,RVBLTEN=rvblten                      &
              ,RTHBLTEN=rthblten,RQVBLTEN=rqvblten                  &
              ,RQCBLTEN=rqcblten,RQIBLTEN=rqiblten                  &
              ,KZM_GBM=exch_m,KTH_GBM=exch_h,KETHL_GBM=exch_tke     & 
              ,EL_GBM=el_pbl,DZ8W=dz8w,Z=z,PSFC=PSFC                &
              ,TKE_PBL=tke_pbl,RTHRATEN=rthraten                    & 
              ,ZNT=znt,UST=ust,ZOL=zol,HOL=hol,PBL=pblh             & 
              ,KPBL2D=kpbl,REGIME=regime                            & 
              ,PSIM=psim,PSIH=psih,XLAND=xland                      &
              ,HFX=hfx,QFX=qfx,TSK=tskold,GZ1OZ0=gz1oz0             &
              ,WSPD=wspd,BR=br,DT=dtbl,DTMIN=dtmin                  &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      &
                                                                    )
              ELSE
               CALL wrf_error_fatal('Lack arguments to call GBM pbl')
              ENDIF

#if ( WRFPLUS == 1 )
! this scheme is for WRFPlus only
!-----------------------------------
        CASE (SURFDRAGSCHEME)

           CALL wrf_debug(100,'in SURFDRAG scheme')

           CALL surface_drag(                                     &
             RUBLTEN=rublten,RVBLTEN=rvblten                      &  !
            ,U_PHY=u_phy, V_PHY=v_phy, Z=z                                &  !
            ,XLAND=xland, HT=ht, KPBL2D=kpbl                      &  !
            ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
            ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
            ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      &
                                                                  )
#endif

     CASE DEFAULT

       WRITE( message , * ) 'The pbl option does not exist: bl_pbl_physics = ', bl_pbl_physics
       CALL wrf_error_fatal ( message )

   END SELECT pbl_select

#if (EM_CORE==1)
!
! ... paj: wind farm ...
!
#ifdef WRF_GPU
    IF (windfarm_opt .NE. 0) CALL wrf_error_fatal('pbl_driver: windfarm_opt not ported to the GPU')
#endif
    windfarm_select: SELECT CASE(windfarm_opt)

      CASE (fitchscheme)

                  IF (PRESENT(id) .AND.                                  &
                     PRESENT(z_at_w) ) THEN
!
                     CALL wrf_debug(100,'in phys/module_wind_fitch.F')
                     CALL dragforce(                                  &
                     & ID=id                                             &
                     &,Z_AT_W=z_at_w,u=u_phy,v=v_phy                     &
                     &,DX=dx,DZ=dz8w,DT=dt                               &
                     &,QKE=qke                                           &
                     &,DU=rublten,DV=rvblten                             &
                     &,WINDFARM_OPT=windfarm_opt,POWER=power             &
                     &,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde   &
                     &,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme   &
                     &,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte   &
                     &)

                    IF (bl_mynn_tkeadvect) THEN
                       qke_adv=qke
                    ENDIF

                  ELSE
                     WRITE ( message , FMT = '(A,6(L1,1X))' )           &
                     'present: '//                                      &
                     'ID, '//                                           &
                     'z_at_w, '//                                       &
                     'xlat_u, '//                                       &
                     'xlong_u, '//                                      &
                     'xlat_v, '//                                       &
                     'xlong_v = ' ,                                     &
                      PRESENT( id ) ,                                   &
                      PRESENT( z_at_w ) 
                     CALL wrf_debug(0,message)
                     CALL wrf_error_fatal('Lack arguments to call turbine_drag')
                  ENDIF

      ! Yulong add new wind farm schemes with wind turbine loss effect
      CASE (mavscheme)
                  IF (PRESENT(id) .AND.                                  &
                     PRESENT(z_at_w) ) THEN
                     CALL wrf_debug(100,'in phys/module_wind_mav.F')
                     CALL dragforce_mav(itimestep                     &
                     &,ID=id                                             &
                     &,Z_AT_W=z_at_w,z_at_m=z,u=u_phy,v=v_phy            &
                     &,DX=dx,DZ=dz8w,DT=dt                               &
                     &,TKE=TKE_windfarm                                  &
                     &,DU=rublten,DV=rvblten                             &
                     &,WINDFARM_OPT=windfarm_opt,POWER=power             &
                     &,windfarm_wake_model=windfarm_wake_model           &
                     &,windfarm_overlap_method=windfarm_overlap_method   &
                     &,xland=xland                                       &
                     &,cosa=cosa,sina=sina                               &
                     &,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde   &
                     &,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme   &
                     &,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte   &
                     &)

                     IF (bl_mynn_tkeadvect) THEN
                        QKE = QKE + 2.*TKE_windfarm
                        qke_adv=qke
                     ENDIF

                  ELSE
                     WRITE ( message , FMT = '(A,6(L1,1X))' )           &
                     'present: '//                                      &
                     'ID, '//                                           &
                     'z_at_w, '//                                       &
                     'xlat_u, '//                                       &
                     'xlong_u, '//                                      &
                     'xlat_v, '//                                       &
                     'xlong_v = ' ,                                     &
                      PRESENT( id ) ,                                   &
                      PRESENT( z_at_w )
                     CALL wrf_debug(0,message)
                     CALL wrf_error_fatal('Lack arguments to call dragforce_mav')
                  ENDIF                 

   END SELECT windfarm_select
#endif


#ifdef WRF_GPU
   IF (PRESENT(GWD_opt)) THEN
      IF (GWD_opt .NE. 0) CALL wrf_error_fatal('pbl_driver: gwd_opt not ported to the GPU')
   END IF
#endif
   IF (PRESENT(GWD_opt)) THEN
     IF (GWD_opt .EQ. 1) THEN
       IF (PRESENT(dtaux3d)) THEN
             CALL gwdo(                                             &
               U3D=u_phy,V3D=v_phy,T3D=t_phy                        &
              ,QV3D=qv_curr                                         &
              ,P3D=p_phy,P3DI=p8w,PI3D=pi_phy,Z=z                   &
              ,RUBLTEN=rublten,RVBLTEN=rvblten                      &
              ,DTAUX3D=dtaux3d,DTAUY3D=dtauy3d                      &
              ,DUSFCG=dusfcg,DVSFCG=dvsfcg                          &
              ,VAR2D=var2d,OC12D=oc12d                              &
              ,OA2D1=oa1,OA2D2=oa2,OA2D3=oa3,OA2D4=oa4              &
              ,OL2D1=ol1,OL2D2=ol2,OL2D3=ol3,OL2D4=ol4              &
              ,SINA=sina,COSA=cosa                                  &
              ,ZNU=znu,ZNW=znw,P_TOP=p_top                          &
              ,CP=cp,G=g,RD=r_d                                     &
              ,RV=r_v,EP1=ep_1,PI=3.141592653                       &
              ,DT=dtbl,DX=dx2d,KPBL2D=kpbl,ITIMESTEP=itimestep      &
              ,errmsg=errmsg,errflg=errflg                          &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      )
       ENDIF
     ELSEIF(gwd_opt .EQ. 3) THEN
             CALL gwdo_gsl(                                         &
               U3D=u_phy,V3D=v_phy,T3D=t_phy                        &
              ,QV3D=qv_curr                                         &
              ,P3D=p_phy,P3DI=p8w,PI3D=pi_phy,Z=z                   &
              ,RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten    &
              ,DTAUX3D_ls=dtaux3d_ls,DTAUY3D_ls=dtauy3d_ls          &
              ,DTAUX3D_bl=dtaux3d_bl,DTAUY3D_bl=dtauy3d_bl          &
              ,DTAUX3D_ss=dtaux3d_ss,DTAUY3D_ss=dtauy3d_ss          &
              ,DTAUX3D_fd=dtaux3d_fd,DTAUY3D_fd=dtauy3d_fd          &
              ,DUSFCG_ls=dusfcg_ls,DVSFCG_ls=dvsfcg_ls              &
              ,DUSFCG_bl=dusfcg_bl,DVSFCG_bl=dvsfcg_bl              &
              ,DUSFCG_ss=dusfcg_ss,DVSFCG_ss=dvsfcg_ss              &
              ,DUSFCG_fd=dusfcg_fd,DVSFCG_fd=dvsfcg_fd              &
              ,xland=xland,br=br                                    &
              ,VAR2D=var2dls,OC12D=oc12dls                          &
              ,OA2D1=oa1ls,OA2D2=oa2ls,OA2D3=oa3ls,OA2D4=oa4ls      &
              ,OL2D1=ol1ls,OL2D2=ol2ls,OL2D3=ol3ls,OL2D4=ol4ls      &
              ,VAR2Dss=var2dss,OC12Dss=oc12dss                      &
              ,OA2D1ss=oa1ss,OA2D2ss=oa2ss,OA2D3ss=oa3ss            &
              ,OA2D4ss=oa4ss,OL2D1ss=ol1ss,OL2D2ss=ol2ss            &
              ,OL2D3ss=ol3ss,OL2D4ss=ol4ss                          &
              ,SINA=sina,COSA=cosa                                  &
              ,ZNU=znu,ZNW=znw,P_TOP=p_top                          &
              ,DZ=dz8w,PBLH=PBLH                                    &
              ,CP=cp,G=g,RD=r_d                                     &
              ,RV=r_v,EP1=ep_1,PI=3.141592653                       &
              ,DT=dtbl,DX=dx,KPBL2D=kpbl                            &
              ,ITIMESTEP=itimestep,gwd_opt=gwd_opt                  &
              ,gwd_diags=gwd_diags                                  &
              ,spp_pbl=spp_pbl,pattern_spp_pbl=pattern_spp_pbl      &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde      &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme      &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte      )
     ENDIF
   ENDIF

#if (EM_CORE==1)                                                                                                                                                                             
!JOE-added - fog (cloud) water deposition calculation
#ifdef WRF_GPU
   IF (grav_settling .GE. 1) CALL wrf_error_fatal('pbl_driver: grav_settling not ported to the GPU')
#endif
   IF (grav_settling .GE. 1) THEN
      IF ( PRESENT(vdfg) .AND. PRESENT(qc_curr)) THEN
         !NOTE 1: vdfg is calculated in the surface driver.
         !NOTE 2: as of now, only qc_curr settles, not # conc.

          CALL bl_fogdes(                                        &
               vdfg,qc_curr,dtbl,rho,dz8w,grav_settling,RQCBLTEN,&
               ids,ide, jds,jde, kds,kde,                        &
               ims,ime, jms,jme, kms,kme,                        &
               i_start(ij),i_end(ij),                            &
               j_start(ij),j_end(ij),kts,kte                     )
      ELSE
          CALL wrf_error_fatal('Missing args for bl_fogdes in pbl driver')
      ENDIF
   ENDIF
!JOE-END
#endif

     IF (idiff.eq.1) THEN

!Alberto: here we call the general routine to solve the diffusion
! + all the source/sink terms.
! the only thing that should be passed from the PBL schemes is the value of the exch_h, and exch_m 
! (and the non local terms, if present, through the b).
! So, this routine can be used by any of the previous schemes. We only need to pass the right variables
! (and eliminate the computation of the tendencies from the previous routines, to avoid doing twice the job).
! As I explain below, in the routine, here we could extract the vertical turbulent 
! fluxes (something that will be general for all the routines).
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
            
          CALL diff3d  (DT=dtbl,CP=cp,DZ=dz8w,TH=th_phy,QV=qv_curr,QC=qc_curr,T=t_phy  &
              ,U=u_phy,V=v_phy,RHO=rho,EXCH_H=exch_h                  &
              ,EXCH_M=exch_m                                          &
              ,RUBLTEN=rublten,RVBLTEN=rvblten,RTHBLTEN=rthblten      &
              ,WU=wu_tur,WV=wv_tur,WT=wt_tur,WQ=wq_tur                &
              ,RQVBLTEN=rqvblten,RQCBLTEN=rqcblten                    &
              ,A_U=a_u,A_V=a_v,A_T=a_t,A_Q=a_q        &
              ,B_U=b_u,B_V=b_v,B_T=b_t,B_Q=b_q        &
              ,SF=sf,VL=vl            &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde        &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme        &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte)

          DEALLOCATE (a_u)       ! Implicit component for the momemtum in X-direction
          DEALLOCATE (a_v)       ! Implicit component for the momemtum in Y-direction
          DEALLOCATE (a_t)       ! Implicit component for the Pot. Temp.
          DEALLOCATE (a_q)       ! Implicit component for the water vapor
          DEALLOCATE (b_u)       ! Explicit component for the momemtum in X-direction
          DEALLOCATE (b_v)       ! Explicit component for the momemtum in Y-direction
          DEALLOCATE (b_t)       ! Explicit component for the Pot. Temp.
          DEALLOCATE (b_q)       ! Explicit component for the water vapor
          DEALLOCATE (sf )       ! surfaces
          DEALLOCATE (vl )       ! volumes
     ENDIF       !idiff
      
#ifdef WRF_GPU
          IF (scalar_pblmix .GT. 0) CALL wrf_error_fatal('pbl_driver: scalar_pblmix not ported to the GPU')
          IF (tracer_pblmix .GT. 0 .AND. num_tracer .GE. param_first_scalar) &
             CALL wrf_error_fatal('pbl_driver: tracer_pblmix not ported to the GPU')
#endif
          IF(scalar_pblmix .GT. 0)THEN
            CALL diff4d  (DT=dtbl,DZ=dz8w, SCALAR=scalar, is_scalar=.true.  &
              ,RHO=rho,EXCH_H=exch_h        &
              ,EXCH_M=exch_m                &
              ,SCALAR_TEND=scalar_tend      &
              ,NUM_SCALAR=num_scalar, PARAM_FIRST_SCALAR=param_first_scalar &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde        &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme        &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte)
          ENDIF
          IF(tracer_pblmix .GT. 0)THEN
            CALL diff4d  (DT=dtbl,DZ=dz8w, SCALAR=tracer, is_scalar=.false.  &
              ,RHO=rho,EXCH_H=exch_h        &
              ,EXCH_M=exch_m                &
              ,SCALAR_TEND=tracer_tend      &
              ,NUM_SCALAR=num_tracer, PARAM_FIRST_SCALAR=param_first_scalar &
              ,IDS=ids,IDE=ide,JDS=jds,JDE=jde,KDS=kds,KDE=kde        &
              ,IMS=ims,IME=ime,JMS=jms,JME=jme,KMS=kms,KME=kme        &
              ,ITS=its,ITE=ite,JTS=jts,JTE=jte,KTS=kts,KTE=kte)
          ENDIF

     IF (distributed_ahe_opt == 1) THEN
#ifdef WRF_GPU
       CALL wrf_error_fatal('pbl_driver: distributed_ahe_opt not ported to the GPU')
#endif
       call cal_mon_day(julday, julyr, jmonth, jday)
       ihour = (jmonth - 1) * 24 + rp_mod(INT(gmt + xtime / 60.0), 24)
       DO j = jts, jte
       DO i = its, ite
         ! Volumetric heat capacity of air = 1200 J/(K m3)
         RTHBLTEN(i, 1, j) = RTHBLTEN(i, 1, j) + ahe(i, ihour, j) / 1200 / DZ8W(i, 1, j)
       END DO
       END DO
     END IF

   ENDDO
   !$OMP END PARALLEL DO

   ENDIF

#ifdef WRF_GPU
      IF (gpu_isl) THEN
        gpu_world_host = .NOT. gpu_world_host
        IF (gpu_world_host) THEN
!$acc update self(rublten, rvblten, rthblten, tsk, znt, ust, pblh, hfx, qfx, grdflx, hpbl_hold, &
!$acc&   th_phy, exch_h, exch_m, akhs, akms, thz0, qz0, uz0, vz0, qsfc, u10, v10, uoce, voce, t2, &
!$acc&   wspd, kpbl, mixht, ct, power, tke_pbl, diss_pbl, tpe_pbl, tke_adv, diss_adv, tpe_adv, &
!$acc&   pr_pbl, el_pbl, wu_tur, wv_tur, wt_tur, wq_tur, rthraten &
#if (WRF_CHEM == 1)
!$acc&   , chem &
#endif
!$acc&   )
          IF (PRESENT(te_temf)) THEN
!$acc update self(te_temf)
          END IF
          IF (PRESENT(km_temf)) THEN
!$acc update self(km_temf)
          END IF
          IF (PRESENT(kh_temf)) THEN
!$acc update self(kh_temf)
          END IF
          IF (PRESENT(shf_temf)) THEN
!$acc update self(shf_temf)
          END IF
          IF (PRESENT(qf_temf)) THEN
!$acc update self(qf_temf)
          END IF
          IF (PRESENT(uw_temf)) THEN
!$acc update self(uw_temf)
          END IF
          IF (PRESENT(vw_temf)) THEN
!$acc update self(vw_temf)
          END IF
          IF (PRESENT(hd_temf)) THEN
!$acc update self(hd_temf)
          END IF
          IF (PRESENT(lcl_temf)) THEN
!$acc update self(lcl_temf)
          END IF
          IF (PRESENT(hct_temf)) THEN
!$acc update self(hct_temf)
          END IF
          IF (PRESENT(wupd_temf)) THEN
!$acc update self(wupd_temf)
          END IF
          IF (PRESENT(mf_temf)) THEN
!$acc update self(mf_temf)
          END IF
          IF (PRESENT(thup_temf)) THEN
!$acc update self(thup_temf)
          END IF
          IF (PRESENT(qtup_temf)) THEN
!$acc update self(qtup_temf)
          END IF
          IF (PRESENT(qlup_temf)) THEN
!$acc update self(qlup_temf)
          END IF
          IF (PRESENT(exch_temf)) THEN
!$acc update self(exch_temf)
          END IF
          IF (PRESENT(cf3d_temf)) THEN
!$acc update self(cf3d_temf)
          END IF
          IF (PRESENT(cfm_temf)) THEN
!$acc update self(cfm_temf)
          END IF
          IF (PRESENT(flhc)) THEN
!$acc update self(flhc)
          END IF
          IF (PRESENT(flqc)) THEN
!$acc update self(flqc)
          END IF
          IF (PRESENT(qke)) THEN
!$acc update self(qke)
          END IF
          IF (PRESENT(sh3d)) THEN
!$acc update self(sh3d)
          END IF
          IF (PRESENT(sm3d)) THEN
!$acc update self(sm3d)
          END IF
          IF (PRESENT(qke_adv)) THEN
!$acc update self(qke_adv)
          END IF
          IF (PRESENT(tsq)) THEN
!$acc update self(tsq)
          END IF
          IF (PRESENT(qsq)) THEN
!$acc update self(qsq)
          END IF
          IF (PRESENT(cov)) THEN
!$acc update self(cov)
          END IF
          IF (PRESENT(rmol)) THEN
!$acc update self(rmol)
          END IF
          IF (PRESENT(dqke)) THEN
!$acc update self(dqke)
          END IF
          IF (PRESENT(qwt)) THEN
!$acc update self(qwt)
          END IF
          IF (PRESENT(qshear)) THEN
!$acc update self(qshear)
          END IF
          IF (PRESENT(qbuoy)) THEN
!$acc update self(qbuoy)
          END IF
          IF (PRESENT(qdiss)) THEN
!$acc update self(qdiss)
          END IF
          IF (PRESENT(qc_bl)) THEN
!$acc update self(qc_bl)
          END IF
          IF (PRESENT(qi_bl)) THEN
!$acc update self(qi_bl)
          END IF
          IF (PRESENT(cldfra_bl)) THEN
!$acc update self(cldfra_bl)
          END IF
          IF (PRESENT(edmf_a)) THEN
!$acc update self(edmf_a)
          END IF
          IF (PRESENT(edmf_w)) THEN
!$acc update self(edmf_w)
          END IF
          IF (PRESENT(edmf_thl)) THEN
!$acc update self(edmf_thl)
          END IF
          IF (PRESENT(edmf_qt)) THEN
!$acc update self(edmf_qt)
          END IF
          IF (PRESENT(edmf_ent)) THEN
!$acc update self(edmf_ent)
          END IF
          IF (PRESENT(edmf_qc)) THEN
!$acc update self(edmf_qc)
          END IF
          IF (PRESENT(sub_thl3d)) THEN
!$acc update self(sub_thl3d)
          END IF
          IF (PRESENT(sub_sqv3d)) THEN
!$acc update self(sub_sqv3d)
          END IF
          IF (PRESENT(det_thl3d)) THEN
!$acc update self(det_thl3d)
          END IF
          IF (PRESENT(det_sqv3d)) THEN
!$acc update self(det_sqv3d)
          END IF
          IF (PRESENT(vdfg)) THEN
!$acc update self(vdfg)
          END IF
          IF (PRESENT(maxwidth)) THEN
!$acc update self(maxwidth)
          END IF
          IF (PRESENT(maxmf)) THEN
!$acc update self(maxmf)
          END IF
          IF (PRESENT(ztop_plume)) THEN
!$acc update self(ztop_plume)
          END IF
          IF (PRESENT(ktop_plume)) THEN
!$acc update self(ktop_plume)
          END IF
          IF (PRESENT(pek)) THEN
!$acc update self(pek)
          END IF
          IF (PRESENT(pep)) THEN
!$acc update self(pep)
          END IF
          IF (PRESENT(pek_adv)) THEN
!$acc update self(pek_adv)
          END IF
          IF (PRESENT(pep_adv)) THEN
!$acc update self(pep_adv)
          END IF
          IF (PRESENT(hol)) THEN
!$acc update self(hol)
          END IF
          IF (PRESENT(mol)) THEN
!$acc update self(mol)
          END IF
          IF (PRESENT(regime)) THEN
!$acc update self(regime)
          END IF
          IF (PRESENT(dtaux3d)) THEN
!$acc update self(dtaux3d)
          END IF
          IF (PRESENT(dtauy3d)) THEN
!$acc update self(dtauy3d)
          END IF
          IF (PRESENT(dusfcg)) THEN
!$acc update self(dusfcg)
          END IF
          IF (PRESENT(dvsfcg)) THEN
!$acc update self(dvsfcg)
          END IF
          IF (PRESENT(dtaux3d_ls)) THEN
!$acc update self(dtaux3d_ls)
          END IF
          IF (PRESENT(dtauy3d_ls)) THEN
!$acc update self(dtauy3d_ls)
          END IF
          IF (PRESENT(dtaux3d_bl)) THEN
!$acc update self(dtaux3d_bl)
          END IF
          IF (PRESENT(dtauy3d_bl)) THEN
!$acc update self(dtauy3d_bl)
          END IF
          IF (PRESENT(dtaux3d_ss)) THEN
!$acc update self(dtaux3d_ss)
          END IF
          IF (PRESENT(dtauy3d_ss)) THEN
!$acc update self(dtauy3d_ss)
          END IF
          IF (PRESENT(dtaux3d_fd)) THEN
!$acc update self(dtaux3d_fd)
          END IF
          IF (PRESENT(dtauy3d_fd)) THEN
!$acc update self(dtauy3d_fd)
          END IF
          IF (PRESENT(dusfcg_ls)) THEN
!$acc update self(dusfcg_ls)
          END IF
          IF (PRESENT(dvsfcg_ls)) THEN
!$acc update self(dvsfcg_ls)
          END IF
          IF (PRESENT(dusfcg_bl)) THEN
!$acc update self(dusfcg_bl)
          END IF
          IF (PRESENT(dvsfcg_bl)) THEN
!$acc update self(dvsfcg_bl)
          END IF
          IF (PRESENT(dusfcg_ss)) THEN
!$acc update self(dusfcg_ss)
          END IF
          IF (PRESENT(dvsfcg_ss)) THEN
!$acc update self(dvsfcg_ss)
          END IF
          IF (PRESENT(dusfcg_fd)) THEN
!$acc update self(dusfcg_fd)
          END IF
          IF (PRESENT(dvsfcg_fd)) THEN
!$acc update self(dvsfcg_fd)
          END IF
          IF (PRESENT(qv_curr)) THEN
!$acc update self(qv_curr)
          END IF
          IF (PRESENT(qc_curr)) THEN
!$acc update self(qc_curr)
          END IF
          IF (PRESENT(qr_curr)) THEN
!$acc update self(qr_curr)
          END IF
          IF (PRESENT(qi_curr)) THEN
!$acc update self(qi_curr)
          END IF
          IF (PRESENT(qs_curr)) THEN
!$acc update self(qs_curr)
          END IF
          IF (PRESENT(qg_curr)) THEN
!$acc update self(qg_curr)
          END IF
          IF (PRESENT(rqvblten)) THEN
!$acc update self(rqvblten)
          END IF
          IF (PRESENT(rqcblten)) THEN
!$acc update self(rqcblten)
          END IF
          IF (PRESENT(rqiblten)) THEN
!$acc update self(rqiblten)
          END IF
          IF (PRESENT(rqrblten)) THEN
!$acc update self(rqrblten)
          END IF
          IF (PRESENT(rqsblten)) THEN
!$acc update self(rqsblten)
          END IF
          IF (PRESENT(rqgblten)) THEN
!$acc update self(rqgblten)
          END IF
          IF (PRESENT(qnwfa_curr)) THEN
!$acc update self(qnwfa_curr)
          END IF
          IF (PRESENT(qnifa_curr)) THEN
!$acc update self(qnifa_curr)
          END IF
          IF (PRESENT(qnbca_curr)) THEN
!$acc update self(qnbca_curr)
          END IF
          IF (PRESENT(frc_urb2d)) THEN
!$acc update self(frc_urb2d)
          END IF
          IF (PRESENT(a_u_bep)) THEN
!$acc update self(a_u_bep)
          END IF
          IF (PRESENT(a_v_bep)) THEN
!$acc update self(a_v_bep)
          END IF
          IF (PRESENT(a_t_bep)) THEN
!$acc update self(a_t_bep)
          END IF
          IF (PRESENT(a_q_bep)) THEN
!$acc update self(a_q_bep)
          END IF
          IF (PRESENT(b_u_bep)) THEN
!$acc update self(b_u_bep)
          END IF
          IF (PRESENT(b_v_bep)) THEN
!$acc update self(b_v_bep)
          END IF
          IF (PRESENT(b_t_bep)) THEN
!$acc update self(b_t_bep)
          END IF
          IF (PRESENT(b_q_bep)) THEN
!$acc update self(b_q_bep)
          END IF
          IF (PRESENT(sf_bep)) THEN
!$acc update self(sf_bep)
          END IF
          IF (PRESENT(vl_bep)) THEN
!$acc update self(vl_bep)
          END IF
          IF (PRESENT(exch_tke)) THEN
!$acc update self(exch_tke)
          END IF
          IF (PRESENT(a_e_bep)) THEN
!$acc update self(a_e_bep)
          END IF
          IF (PRESENT(b_e_bep)) THEN
!$acc update self(b_e_bep)
          END IF
          IF (PRESENT(dlg_bep)) THEN
!$acc update self(dlg_bep)
          END IF
          IF (PRESENT(dl_u_bep)) THEN
!$acc update self(dl_u_bep)
          END IF
          IF (PRESENT(massflux_edkf)) THEN
!$acc update self(massflux_edkf)
          END IF
          IF (PRESENT(entr_edkf)) THEN
!$acc update self(entr_edkf)
          END IF
          IF (PRESENT(detr_edkf)) THEN
!$acc update self(detr_edkf)
          END IF
          IF (PRESENT(thl_up)) THEN
!$acc update self(thl_up)
          END IF
          IF (PRESENT(thv_up)) THEN
!$acc update self(thv_up)
          END IF
          IF (PRESENT(rt_up)) THEN
!$acc update self(rt_up)
          END IF
          IF (PRESENT(rv_up)) THEN
!$acc update self(rv_up)
          END IF
          IF (PRESENT(rc_up)) THEN
!$acc update self(rc_up)
          END IF
          IF (PRESENT(u_up)) THEN
!$acc update self(u_up)
          END IF
          IF (PRESENT(v_up)) THEN
!$acc update self(v_up)
          END IF
          IF (PRESENT(frac_up)) THEN
!$acc update self(frac_up)
          END IF
          IF (PRESENT(rc_mf)) THEN
!$acc update self(rc_mf)
          END IF
          IF (PRESENT(tauresx2d)) THEN
!$acc update self(tauresx2d)
          END IF
          IF (PRESENT(tauresy2d)) THEN
!$acc update self(tauresy2d)
          END IF
          IF (PRESENT(tpert2d)) THEN
!$acc update self(tpert2d)
          END IF
          IF (PRESENT(qpert2d)) THEN
!$acc update self(qpert2d)
          END IF
          IF (PRESENT(wpert2d)) THEN
!$acc update self(wpert2d)
          END IF
          IF (PRESENT(turbtype3d)) THEN
!$acc update self(turbtype3d)
          END IF
          IF (PRESENT(smaw3d)) THEN
!$acc update self(smaw3d)
          END IF
          IF (PRESENT(qnc_curr)) THEN
!$acc update self(qnc_curr)
          END IF
          IF (PRESENT(qni_curr)) THEN
!$acc update self(qni_curr)
          END IF
          IF (PRESENT(rqniblten)) THEN
!$acc update self(rqniblten)
          END IF
          IF (PRESENT(wstar)) THEN
!$acc update self(wstar)
          END IF
          IF (PRESENT(delta)) THEN
!$acc update self(delta)
          END IF
          IF (PRESENT(scalar)) THEN
!$acc update self(scalar)
          END IF
          IF (PRESENT(scalar_tend)) THEN
!$acc update self(scalar_tend)
          END IF
          IF (PRESENT(tracer)) THEN
!$acc update self(tracer)
          END IF
          IF (PRESENT(tracer_tend)) THEN
!$acc update self(tracer_tend)
          END IF
          IF (PRESENT(qnorm)) THEN
!$acc update self(qnorm)
          END IF
        ELSE
!$acc update device(rublten, rvblten, rthblten, tsk, znt, ust, pblh, hfx, qfx, grdflx, hpbl_hold, &
!$acc&   th_phy, exch_h, exch_m, akhs, akms, thz0, qz0, uz0, vz0, qsfc, u10, v10, uoce, voce, t2, &
!$acc&   wspd, kpbl, mixht, ct, power, tke_pbl, diss_pbl, tpe_pbl, tke_adv, diss_adv, tpe_adv, &
!$acc&   pr_pbl, el_pbl, wu_tur, wv_tur, wt_tur, wq_tur, rthraten &
#if (WRF_CHEM == 1)
!$acc&   , chem &
#endif
!$acc&   )
          IF (PRESENT(te_temf)) THEN
!$acc update device(te_temf)
          END IF
          IF (PRESENT(km_temf)) THEN
!$acc update device(km_temf)
          END IF
          IF (PRESENT(kh_temf)) THEN
!$acc update device(kh_temf)
          END IF
          IF (PRESENT(shf_temf)) THEN
!$acc update device(shf_temf)
          END IF
          IF (PRESENT(qf_temf)) THEN
!$acc update device(qf_temf)
          END IF
          IF (PRESENT(uw_temf)) THEN
!$acc update device(uw_temf)
          END IF
          IF (PRESENT(vw_temf)) THEN
!$acc update device(vw_temf)
          END IF
          IF (PRESENT(hd_temf)) THEN
!$acc update device(hd_temf)
          END IF
          IF (PRESENT(lcl_temf)) THEN
!$acc update device(lcl_temf)
          END IF
          IF (PRESENT(hct_temf)) THEN
!$acc update device(hct_temf)
          END IF
          IF (PRESENT(wupd_temf)) THEN
!$acc update device(wupd_temf)
          END IF
          IF (PRESENT(mf_temf)) THEN
!$acc update device(mf_temf)
          END IF
          IF (PRESENT(thup_temf)) THEN
!$acc update device(thup_temf)
          END IF
          IF (PRESENT(qtup_temf)) THEN
!$acc update device(qtup_temf)
          END IF
          IF (PRESENT(qlup_temf)) THEN
!$acc update device(qlup_temf)
          END IF
          IF (PRESENT(exch_temf)) THEN
!$acc update device(exch_temf)
          END IF
          IF (PRESENT(cf3d_temf)) THEN
!$acc update device(cf3d_temf)
          END IF
          IF (PRESENT(cfm_temf)) THEN
!$acc update device(cfm_temf)
          END IF
          IF (PRESENT(flhc)) THEN
!$acc update device(flhc)
          END IF
          IF (PRESENT(flqc)) THEN
!$acc update device(flqc)
          END IF
          IF (PRESENT(qke)) THEN
!$acc update device(qke)
          END IF
          IF (PRESENT(sh3d)) THEN
!$acc update device(sh3d)
          END IF
          IF (PRESENT(sm3d)) THEN
!$acc update device(sm3d)
          END IF
          IF (PRESENT(qke_adv)) THEN
!$acc update device(qke_adv)
          END IF
          IF (PRESENT(tsq)) THEN
!$acc update device(tsq)
          END IF
          IF (PRESENT(qsq)) THEN
!$acc update device(qsq)
          END IF
          IF (PRESENT(cov)) THEN
!$acc update device(cov)
          END IF
          IF (PRESENT(rmol)) THEN
!$acc update device(rmol)
          END IF
          IF (PRESENT(dqke)) THEN
!$acc update device(dqke)
          END IF
          IF (PRESENT(qwt)) THEN
!$acc update device(qwt)
          END IF
          IF (PRESENT(qshear)) THEN
!$acc update device(qshear)
          END IF
          IF (PRESENT(qbuoy)) THEN
!$acc update device(qbuoy)
          END IF
          IF (PRESENT(qdiss)) THEN
!$acc update device(qdiss)
          END IF
          IF (PRESENT(qc_bl)) THEN
!$acc update device(qc_bl)
          END IF
          IF (PRESENT(qi_bl)) THEN
!$acc update device(qi_bl)
          END IF
          IF (PRESENT(cldfra_bl)) THEN
!$acc update device(cldfra_bl)
          END IF
          IF (PRESENT(edmf_a)) THEN
!$acc update device(edmf_a)
          END IF
          IF (PRESENT(edmf_w)) THEN
!$acc update device(edmf_w)
          END IF
          IF (PRESENT(edmf_thl)) THEN
!$acc update device(edmf_thl)
          END IF
          IF (PRESENT(edmf_qt)) THEN
!$acc update device(edmf_qt)
          END IF
          IF (PRESENT(edmf_ent)) THEN
!$acc update device(edmf_ent)
          END IF
          IF (PRESENT(edmf_qc)) THEN
!$acc update device(edmf_qc)
          END IF
          IF (PRESENT(sub_thl3d)) THEN
!$acc update device(sub_thl3d)
          END IF
          IF (PRESENT(sub_sqv3d)) THEN
!$acc update device(sub_sqv3d)
          END IF
          IF (PRESENT(det_thl3d)) THEN
!$acc update device(det_thl3d)
          END IF
          IF (PRESENT(det_sqv3d)) THEN
!$acc update device(det_sqv3d)
          END IF
          IF (PRESENT(vdfg)) THEN
!$acc update device(vdfg)
          END IF
          IF (PRESENT(maxwidth)) THEN
!$acc update device(maxwidth)
          END IF
          IF (PRESENT(maxmf)) THEN
!$acc update device(maxmf)
          END IF
          IF (PRESENT(ztop_plume)) THEN
!$acc update device(ztop_plume)
          END IF
          IF (PRESENT(ktop_plume)) THEN
!$acc update device(ktop_plume)
          END IF
          IF (PRESENT(pek)) THEN
!$acc update device(pek)
          END IF
          IF (PRESENT(pep)) THEN
!$acc update device(pep)
          END IF
          IF (PRESENT(pek_adv)) THEN
!$acc update device(pek_adv)
          END IF
          IF (PRESENT(pep_adv)) THEN
!$acc update device(pep_adv)
          END IF
          IF (PRESENT(hol)) THEN
!$acc update device(hol)
          END IF
          IF (PRESENT(mol)) THEN
!$acc update device(mol)
          END IF
          IF (PRESENT(regime)) THEN
!$acc update device(regime)
          END IF
          IF (PRESENT(dtaux3d)) THEN
!$acc update device(dtaux3d)
          END IF
          IF (PRESENT(dtauy3d)) THEN
!$acc update device(dtauy3d)
          END IF
          IF (PRESENT(dusfcg)) THEN
!$acc update device(dusfcg)
          END IF
          IF (PRESENT(dvsfcg)) THEN
!$acc update device(dvsfcg)
          END IF
          IF (PRESENT(dtaux3d_ls)) THEN
!$acc update device(dtaux3d_ls)
          END IF
          IF (PRESENT(dtauy3d_ls)) THEN
!$acc update device(dtauy3d_ls)
          END IF
          IF (PRESENT(dtaux3d_bl)) THEN
!$acc update device(dtaux3d_bl)
          END IF
          IF (PRESENT(dtauy3d_bl)) THEN
!$acc update device(dtauy3d_bl)
          END IF
          IF (PRESENT(dtaux3d_ss)) THEN
!$acc update device(dtaux3d_ss)
          END IF
          IF (PRESENT(dtauy3d_ss)) THEN
!$acc update device(dtauy3d_ss)
          END IF
          IF (PRESENT(dtaux3d_fd)) THEN
!$acc update device(dtaux3d_fd)
          END IF
          IF (PRESENT(dtauy3d_fd)) THEN
!$acc update device(dtauy3d_fd)
          END IF
          IF (PRESENT(dusfcg_ls)) THEN
!$acc update device(dusfcg_ls)
          END IF
          IF (PRESENT(dvsfcg_ls)) THEN
!$acc update device(dvsfcg_ls)
          END IF
          IF (PRESENT(dusfcg_bl)) THEN
!$acc update device(dusfcg_bl)
          END IF
          IF (PRESENT(dvsfcg_bl)) THEN
!$acc update device(dvsfcg_bl)
          END IF
          IF (PRESENT(dusfcg_ss)) THEN
!$acc update device(dusfcg_ss)
          END IF
          IF (PRESENT(dvsfcg_ss)) THEN
!$acc update device(dvsfcg_ss)
          END IF
          IF (PRESENT(dusfcg_fd)) THEN
!$acc update device(dusfcg_fd)
          END IF
          IF (PRESENT(dvsfcg_fd)) THEN
!$acc update device(dvsfcg_fd)
          END IF
          IF (PRESENT(qv_curr)) THEN
!$acc update device(qv_curr)
          END IF
          IF (PRESENT(qc_curr)) THEN
!$acc update device(qc_curr)
          END IF
          IF (PRESENT(qr_curr)) THEN
!$acc update device(qr_curr)
          END IF
          IF (PRESENT(qi_curr)) THEN
!$acc update device(qi_curr)
          END IF
          IF (PRESENT(qs_curr)) THEN
!$acc update device(qs_curr)
          END IF
          IF (PRESENT(qg_curr)) THEN
!$acc update device(qg_curr)
          END IF
          IF (PRESENT(rqvblten)) THEN
!$acc update device(rqvblten)
          END IF
          IF (PRESENT(rqcblten)) THEN
!$acc update device(rqcblten)
          END IF
          IF (PRESENT(rqiblten)) THEN
!$acc update device(rqiblten)
          END IF
          IF (PRESENT(rqrblten)) THEN
!$acc update device(rqrblten)
          END IF
          IF (PRESENT(rqsblten)) THEN
!$acc update device(rqsblten)
          END IF
          IF (PRESENT(rqgblten)) THEN
!$acc update device(rqgblten)
          END IF
          IF (PRESENT(qnwfa_curr)) THEN
!$acc update device(qnwfa_curr)
          END IF
          IF (PRESENT(qnifa_curr)) THEN
!$acc update device(qnifa_curr)
          END IF
          IF (PRESENT(qnbca_curr)) THEN
!$acc update device(qnbca_curr)
          END IF
          IF (PRESENT(frc_urb2d)) THEN
!$acc update device(frc_urb2d)
          END IF
          IF (PRESENT(a_u_bep)) THEN
!$acc update device(a_u_bep)
          END IF
          IF (PRESENT(a_v_bep)) THEN
!$acc update device(a_v_bep)
          END IF
          IF (PRESENT(a_t_bep)) THEN
!$acc update device(a_t_bep)
          END IF
          IF (PRESENT(a_q_bep)) THEN
!$acc update device(a_q_bep)
          END IF
          IF (PRESENT(b_u_bep)) THEN
!$acc update device(b_u_bep)
          END IF
          IF (PRESENT(b_v_bep)) THEN
!$acc update device(b_v_bep)
          END IF
          IF (PRESENT(b_t_bep)) THEN
!$acc update device(b_t_bep)
          END IF
          IF (PRESENT(b_q_bep)) THEN
!$acc update device(b_q_bep)
          END IF
          IF (PRESENT(sf_bep)) THEN
!$acc update device(sf_bep)
          END IF
          IF (PRESENT(vl_bep)) THEN
!$acc update device(vl_bep)
          END IF
          IF (PRESENT(exch_tke)) THEN
!$acc update device(exch_tke)
          END IF
          IF (PRESENT(a_e_bep)) THEN
!$acc update device(a_e_bep)
          END IF
          IF (PRESENT(b_e_bep)) THEN
!$acc update device(b_e_bep)
          END IF
          IF (PRESENT(dlg_bep)) THEN
!$acc update device(dlg_bep)
          END IF
          IF (PRESENT(dl_u_bep)) THEN
!$acc update device(dl_u_bep)
          END IF
          IF (PRESENT(massflux_edkf)) THEN
!$acc update device(massflux_edkf)
          END IF
          IF (PRESENT(entr_edkf)) THEN
!$acc update device(entr_edkf)
          END IF
          IF (PRESENT(detr_edkf)) THEN
!$acc update device(detr_edkf)
          END IF
          IF (PRESENT(thl_up)) THEN
!$acc update device(thl_up)
          END IF
          IF (PRESENT(thv_up)) THEN
!$acc update device(thv_up)
          END IF
          IF (PRESENT(rt_up)) THEN
!$acc update device(rt_up)
          END IF
          IF (PRESENT(rv_up)) THEN
!$acc update device(rv_up)
          END IF
          IF (PRESENT(rc_up)) THEN
!$acc update device(rc_up)
          END IF
          IF (PRESENT(u_up)) THEN
!$acc update device(u_up)
          END IF
          IF (PRESENT(v_up)) THEN
!$acc update device(v_up)
          END IF
          IF (PRESENT(frac_up)) THEN
!$acc update device(frac_up)
          END IF
          IF (PRESENT(rc_mf)) THEN
!$acc update device(rc_mf)
          END IF
          IF (PRESENT(tauresx2d)) THEN
!$acc update device(tauresx2d)
          END IF
          IF (PRESENT(tauresy2d)) THEN
!$acc update device(tauresy2d)
          END IF
          IF (PRESENT(tpert2d)) THEN
!$acc update device(tpert2d)
          END IF
          IF (PRESENT(qpert2d)) THEN
!$acc update device(qpert2d)
          END IF
          IF (PRESENT(wpert2d)) THEN
!$acc update device(wpert2d)
          END IF
          IF (PRESENT(turbtype3d)) THEN
!$acc update device(turbtype3d)
          END IF
          IF (PRESENT(smaw3d)) THEN
!$acc update device(smaw3d)
          END IF
          IF (PRESENT(qnc_curr)) THEN
!$acc update device(qnc_curr)
          END IF
          IF (PRESENT(qni_curr)) THEN
!$acc update device(qni_curr)
          END IF
          IF (PRESENT(rqniblten)) THEN
!$acc update device(rqniblten)
          END IF
          IF (PRESENT(wstar)) THEN
!$acc update device(wstar)
          END IF
          IF (PRESENT(delta)) THEN
!$acc update device(delta)
          END IF
          IF (PRESENT(scalar)) THEN
!$acc update device(scalar)
          END IF
          IF (PRESENT(scalar_tend)) THEN
!$acc update device(scalar_tend)
          END IF
          IF (PRESENT(tracer)) THEN
!$acc update device(tracer)
          END IF
          IF (PRESENT(tracer_tend)) THEN
!$acc update device(tracer_tend)
          END IF
          IF (PRESENT(qnorm)) THEN
!$acc update device(qnorm)
          END IF
        END IF
      END IF
      IF (gpu_cc_active(R_PBL_DRIVER)) THEN
        IF (PRESENT(bldtacttime)) CALL gpu_cc_done_r0(1, bldtacttime, 'bldtacttime')
        CALL gpu_cc_done_r(2, rublten, SIZE(rublten,KIND=8), 'rublten', &
          LBOUND(rublten), UBOUND(rublten))
        CALL gpu_cc_done_r(3, rvblten, SIZE(rvblten,KIND=8), 'rvblten', &
          LBOUND(rvblten), UBOUND(rvblten))
        CALL gpu_cc_done_r(4, rthblten, SIZE(rthblten,KIND=8), 'rthblten', &
          LBOUND(rthblten), UBOUND(rthblten))
        CALL gpu_cc_done_r(5, tsk, SIZE(tsk,KIND=8), 'tsk', &
          LBOUND(tsk), UBOUND(tsk))
        CALL gpu_cc_done_r(6, znt, SIZE(znt,KIND=8), 'znt', &
          LBOUND(znt), UBOUND(znt))
        CALL gpu_cc_done_r(7, ust, SIZE(ust,KIND=8), 'ust', &
          LBOUND(ust), UBOUND(ust))
        CALL gpu_cc_done_r(8, pblh, SIZE(pblh,KIND=8), 'pblh', &
          LBOUND(pblh), UBOUND(pblh))
        CALL gpu_cc_done_r(9, hfx, SIZE(hfx,KIND=8), 'hfx', &
          LBOUND(hfx), UBOUND(hfx))
        CALL gpu_cc_done_r(10, qfx, SIZE(qfx,KIND=8), 'qfx', &
          LBOUND(qfx), UBOUND(qfx))
        CALL gpu_cc_done_r(11, grdflx, SIZE(grdflx,KIND=8), 'grdflx', &
          LBOUND(grdflx), UBOUND(grdflx))
        CALL gpu_cc_done_r(12, hpbl_hold, SIZE(hpbl_hold,KIND=8), 'hpbl_hold', &
          LBOUND(hpbl_hold), UBOUND(hpbl_hold))
        CALL gpu_cc_done_r(13, th_phy, SIZE(th_phy,KIND=8), 'th_phy', &
          LBOUND(th_phy), UBOUND(th_phy))
        CALL gpu_cc_done_r(14, exch_h, SIZE(exch_h,KIND=8), 'exch_h', &
          LBOUND(exch_h), UBOUND(exch_h))
        CALL gpu_cc_done_r(15, exch_m, SIZE(exch_m,KIND=8), 'exch_m', &
          LBOUND(exch_m), UBOUND(exch_m))
        CALL gpu_cc_done_r(16, akhs, SIZE(akhs,KIND=8), 'akhs', &
          LBOUND(akhs), UBOUND(akhs))
        CALL gpu_cc_done_r(17, akms, SIZE(akms,KIND=8), 'akms', &
          LBOUND(akms), UBOUND(akms))
        CALL gpu_cc_done_r(18, thz0, SIZE(thz0,KIND=8), 'thz0', &
          LBOUND(thz0), UBOUND(thz0))
        CALL gpu_cc_done_r(19, qz0, SIZE(qz0,KIND=8), 'qz0', &
          LBOUND(qz0), UBOUND(qz0))
        CALL gpu_cc_done_r(20, uz0, SIZE(uz0,KIND=8), 'uz0', &
          LBOUND(uz0), UBOUND(uz0))
        CALL gpu_cc_done_r(21, vz0, SIZE(vz0,KIND=8), 'vz0', &
          LBOUND(vz0), UBOUND(vz0))
        CALL gpu_cc_done_r(22, qsfc, SIZE(qsfc,KIND=8), 'qsfc', &
          LBOUND(qsfc), UBOUND(qsfc))
        CALL gpu_cc_done_r(23, u10, SIZE(u10,KIND=8), 'u10', &
          LBOUND(u10), UBOUND(u10))
        CALL gpu_cc_done_r(24, v10, SIZE(v10,KIND=8), 'v10', &
          LBOUND(v10), UBOUND(v10))
        CALL gpu_cc_done_r(25, uoce, SIZE(uoce,KIND=8), 'uoce', &
          LBOUND(uoce), UBOUND(uoce))
        CALL gpu_cc_done_r(26, voce, SIZE(voce,KIND=8), 'voce', &
          LBOUND(voce), UBOUND(voce))
        CALL gpu_cc_done_r(27, t2, SIZE(t2,KIND=8), 't2', &
          LBOUND(t2), UBOUND(t2))
        CALL gpu_cc_done_r(28, wspd, SIZE(wspd,KIND=8), 'wspd', &
          LBOUND(wspd), UBOUND(wspd))
        CALL gpu_cc_done_i(29, kpbl, SIZE(kpbl,KIND=8), 'kpbl', &
          LBOUND(kpbl), UBOUND(kpbl))
        CALL gpu_cc_done_r(30, mixht, SIZE(mixht,KIND=8), 'mixht', &
          LBOUND(mixht), UBOUND(mixht))
        CALL gpu_cc_done_r(31, ct, SIZE(ct,KIND=8), 'ct', &
          LBOUND(ct), UBOUND(ct))
        CALL gpu_cc_done_r(32, power, SIZE(power,KIND=8), 'power', &
          LBOUND(power), UBOUND(power))
        IF (PRESENT(te_temf)) CALL gpu_cc_done_r(33, te_temf, SIZE(te_temf,KIND=8), 'te_temf', &
          LBOUND(te_temf), UBOUND(te_temf))
        IF (PRESENT(km_temf)) CALL gpu_cc_done_r(34, km_temf, SIZE(km_temf,KIND=8), 'km_temf', &
          LBOUND(km_temf), UBOUND(km_temf))
        IF (PRESENT(kh_temf)) CALL gpu_cc_done_r(35, kh_temf, SIZE(kh_temf,KIND=8), 'kh_temf', &
          LBOUND(kh_temf), UBOUND(kh_temf))
        IF (PRESENT(shf_temf)) CALL gpu_cc_done_r(36, shf_temf, SIZE(shf_temf,KIND=8), 'shf_temf', &
          LBOUND(shf_temf), UBOUND(shf_temf))
        IF (PRESENT(qf_temf)) CALL gpu_cc_done_r(37, qf_temf, SIZE(qf_temf,KIND=8), 'qf_temf', &
          LBOUND(qf_temf), UBOUND(qf_temf))
        IF (PRESENT(uw_temf)) CALL gpu_cc_done_r(38, uw_temf, SIZE(uw_temf,KIND=8), 'uw_temf', &
          LBOUND(uw_temf), UBOUND(uw_temf))
        IF (PRESENT(vw_temf)) CALL gpu_cc_done_r(39, vw_temf, SIZE(vw_temf,KIND=8), 'vw_temf', &
          LBOUND(vw_temf), UBOUND(vw_temf))
        IF (PRESENT(hd_temf)) CALL gpu_cc_done_r(40, hd_temf, SIZE(hd_temf,KIND=8), 'hd_temf', &
          LBOUND(hd_temf), UBOUND(hd_temf))
        IF (PRESENT(lcl_temf)) CALL gpu_cc_done_r(41, lcl_temf, SIZE(lcl_temf,KIND=8), 'lcl_temf', &
          LBOUND(lcl_temf), UBOUND(lcl_temf))
        IF (PRESENT(hct_temf)) CALL gpu_cc_done_r(42, hct_temf, SIZE(hct_temf,KIND=8), 'hct_temf', &
          LBOUND(hct_temf), UBOUND(hct_temf))
        IF (PRESENT(wupd_temf)) CALL gpu_cc_done_r(43, wupd_temf, SIZE(wupd_temf,KIND=8), 'wupd_temf', &
          LBOUND(wupd_temf), UBOUND(wupd_temf))
        IF (PRESENT(mf_temf)) CALL gpu_cc_done_r(44, mf_temf, SIZE(mf_temf,KIND=8), 'mf_temf', &
          LBOUND(mf_temf), UBOUND(mf_temf))
        IF (PRESENT(thup_temf)) CALL gpu_cc_done_r(45, thup_temf, SIZE(thup_temf,KIND=8), 'thup_temf', &
          LBOUND(thup_temf), UBOUND(thup_temf))
        IF (PRESENT(qtup_temf)) CALL gpu_cc_done_r(46, qtup_temf, SIZE(qtup_temf,KIND=8), 'qtup_temf', &
          LBOUND(qtup_temf), UBOUND(qtup_temf))
        IF (PRESENT(qlup_temf)) CALL gpu_cc_done_r(47, qlup_temf, SIZE(qlup_temf,KIND=8), 'qlup_temf', &
          LBOUND(qlup_temf), UBOUND(qlup_temf))
        IF (PRESENT(exch_temf)) CALL gpu_cc_done_r(48, exch_temf, SIZE(exch_temf,KIND=8), 'exch_temf', &
          LBOUND(exch_temf), UBOUND(exch_temf))
        IF (PRESENT(cf3d_temf)) CALL gpu_cc_done_r(49, cf3d_temf, SIZE(cf3d_temf,KIND=8), 'cf3d_temf', &
          LBOUND(cf3d_temf), UBOUND(cf3d_temf))
        IF (PRESENT(cfm_temf)) CALL gpu_cc_done_r(50, cfm_temf, SIZE(cfm_temf,KIND=8), 'cfm_temf', &
          LBOUND(cfm_temf), UBOUND(cfm_temf))
        IF (PRESENT(flhc)) CALL gpu_cc_done_r(51, flhc, SIZE(flhc,KIND=8), 'flhc', &
          LBOUND(flhc), UBOUND(flhc))
        IF (PRESENT(flqc)) CALL gpu_cc_done_r(52, flqc, SIZE(flqc,KIND=8), 'flqc', &
          LBOUND(flqc), UBOUND(flqc))
        IF (PRESENT(qke)) CALL gpu_cc_done_r(53, qke, SIZE(qke,KIND=8), 'qke', &
          LBOUND(qke), UBOUND(qke))
        IF (PRESENT(sh3d)) CALL gpu_cc_done_r(54, sh3d, SIZE(sh3d,KIND=8), 'sh3d', &
          LBOUND(sh3d), UBOUND(sh3d))
        IF (PRESENT(sm3d)) CALL gpu_cc_done_r(55, sm3d, SIZE(sm3d,KIND=8), 'sm3d', &
          LBOUND(sm3d), UBOUND(sm3d))
        IF (PRESENT(qke_adv)) CALL gpu_cc_done_r(56, qke_adv, SIZE(qke_adv,KIND=8), 'qke_adv', &
          LBOUND(qke_adv), UBOUND(qke_adv))
        IF (PRESENT(tsq)) CALL gpu_cc_done_r(57, tsq, SIZE(tsq,KIND=8), 'tsq', &
          LBOUND(tsq), UBOUND(tsq))
        IF (PRESENT(qsq)) CALL gpu_cc_done_r(58, qsq, SIZE(qsq,KIND=8), 'qsq', &
          LBOUND(qsq), UBOUND(qsq))
        IF (PRESENT(cov)) CALL gpu_cc_done_r(59, cov, SIZE(cov,KIND=8), 'cov', &
          LBOUND(cov), UBOUND(cov))
        IF (PRESENT(rmol)) CALL gpu_cc_done_r(60, rmol, SIZE(rmol,KIND=8), 'rmol', &
          LBOUND(rmol), UBOUND(rmol))
        IF (PRESENT(dqke)) CALL gpu_cc_done_r(61, dqke, SIZE(dqke,KIND=8), 'dqke', &
          LBOUND(dqke), UBOUND(dqke))
        IF (PRESENT(qwt)) CALL gpu_cc_done_r(62, qwt, SIZE(qwt,KIND=8), 'qwt', &
          LBOUND(qwt), UBOUND(qwt))
        IF (PRESENT(qshear)) CALL gpu_cc_done_r(63, qshear, SIZE(qshear,KIND=8), 'qshear', &
          LBOUND(qshear), UBOUND(qshear))
        IF (PRESENT(qbuoy)) CALL gpu_cc_done_r(64, qbuoy, SIZE(qbuoy,KIND=8), 'qbuoy', &
          LBOUND(qbuoy), UBOUND(qbuoy))
        IF (PRESENT(qdiss)) CALL gpu_cc_done_r(65, qdiss, SIZE(qdiss,KIND=8), 'qdiss', &
          LBOUND(qdiss), UBOUND(qdiss))
        IF (PRESENT(qc_bl)) CALL gpu_cc_done_r(66, qc_bl, SIZE(qc_bl,KIND=8), 'qc_bl', &
          LBOUND(qc_bl), UBOUND(qc_bl))
        IF (PRESENT(qi_bl)) CALL gpu_cc_done_r(67, qi_bl, SIZE(qi_bl,KIND=8), 'qi_bl', &
          LBOUND(qi_bl), UBOUND(qi_bl))
        IF (PRESENT(cldfra_bl)) CALL gpu_cc_done_r(68, cldfra_bl, SIZE(cldfra_bl,KIND=8), 'cldfra_bl', &
          LBOUND(cldfra_bl), UBOUND(cldfra_bl))
        IF (PRESENT(edmf_a)) CALL gpu_cc_done_r(69, edmf_a, SIZE(edmf_a,KIND=8), 'edmf_a', &
          LBOUND(edmf_a), UBOUND(edmf_a))
        IF (PRESENT(edmf_w)) CALL gpu_cc_done_r(70, edmf_w, SIZE(edmf_w,KIND=8), 'edmf_w', &
          LBOUND(edmf_w), UBOUND(edmf_w))
        IF (PRESENT(edmf_thl)) CALL gpu_cc_done_r(71, edmf_thl, SIZE(edmf_thl,KIND=8), 'edmf_thl', &
          LBOUND(edmf_thl), UBOUND(edmf_thl))
        IF (PRESENT(edmf_qt)) CALL gpu_cc_done_r(72, edmf_qt, SIZE(edmf_qt,KIND=8), 'edmf_qt', &
          LBOUND(edmf_qt), UBOUND(edmf_qt))
        IF (PRESENT(edmf_ent)) CALL gpu_cc_done_r(73, edmf_ent, SIZE(edmf_ent,KIND=8), 'edmf_ent', &
          LBOUND(edmf_ent), UBOUND(edmf_ent))
        IF (PRESENT(edmf_qc)) CALL gpu_cc_done_r(74, edmf_qc, SIZE(edmf_qc,KIND=8), 'edmf_qc', &
          LBOUND(edmf_qc), UBOUND(edmf_qc))
        IF (PRESENT(sub_thl3d)) CALL gpu_cc_done_r(75, sub_thl3d, SIZE(sub_thl3d,KIND=8), 'sub_thl3d', &
          LBOUND(sub_thl3d), UBOUND(sub_thl3d))
        IF (PRESENT(sub_sqv3d)) CALL gpu_cc_done_r(76, sub_sqv3d, SIZE(sub_sqv3d,KIND=8), 'sub_sqv3d', &
          LBOUND(sub_sqv3d), UBOUND(sub_sqv3d))
        IF (PRESENT(det_thl3d)) CALL gpu_cc_done_r(77, det_thl3d, SIZE(det_thl3d,KIND=8), 'det_thl3d', &
          LBOUND(det_thl3d), UBOUND(det_thl3d))
        IF (PRESENT(det_sqv3d)) CALL gpu_cc_done_r(78, det_sqv3d, SIZE(det_sqv3d,KIND=8), 'det_sqv3d', &
          LBOUND(det_sqv3d), UBOUND(det_sqv3d))
        IF (PRESENT(vdfg)) CALL gpu_cc_done_r(79, vdfg, SIZE(vdfg,KIND=8), 'vdfg', &
          LBOUND(vdfg), UBOUND(vdfg))
        IF (PRESENT(maxwidth)) CALL gpu_cc_done_r(80, maxwidth, SIZE(maxwidth,KIND=8), 'maxwidth', &
          LBOUND(maxwidth), UBOUND(maxwidth))
        IF (PRESENT(maxmf)) CALL gpu_cc_done_r(81, maxmf, SIZE(maxmf,KIND=8), 'maxmf', &
          LBOUND(maxmf), UBOUND(maxmf))
        IF (PRESENT(ztop_plume)) CALL gpu_cc_done_r(82, ztop_plume, SIZE(ztop_plume,KIND=8), 'ztop_plume', &
          LBOUND(ztop_plume), UBOUND(ztop_plume))
        IF (PRESENT(ktop_plume)) CALL gpu_cc_done_i(83, ktop_plume, SIZE(ktop_plume,KIND=8), 'ktop_plume', &
          LBOUND(ktop_plume), UBOUND(ktop_plume))
        IF (PRESENT(pek)) CALL gpu_cc_done_r(84, pek, SIZE(pek,KIND=8), 'pek', &
          LBOUND(pek), UBOUND(pek))
        IF (PRESENT(pep)) CALL gpu_cc_done_r(85, pep, SIZE(pep,KIND=8), 'pep', &
          LBOUND(pep), UBOUND(pep))
        IF (PRESENT(pek_adv)) CALL gpu_cc_done_r(86, pek_adv, SIZE(pek_adv,KIND=8), 'pek_adv', &
          LBOUND(pek_adv), UBOUND(pek_adv))
        IF (PRESENT(pep_adv)) CALL gpu_cc_done_r(87, pep_adv, SIZE(pep_adv,KIND=8), 'pep_adv', &
          LBOUND(pep_adv), UBOUND(pep_adv))
        IF (PRESENT(hol)) CALL gpu_cc_done_r(88, hol, SIZE(hol,KIND=8), 'hol', &
          LBOUND(hol), UBOUND(hol))
        IF (PRESENT(mol)) CALL gpu_cc_done_r(89, mol, SIZE(mol,KIND=8), 'mol', &
          LBOUND(mol), UBOUND(mol))
        IF (PRESENT(regime)) CALL gpu_cc_done_r(90, regime, SIZE(regime,KIND=8), 'regime', &
          LBOUND(regime), UBOUND(regime))
        IF (PRESENT(dtaux3d)) CALL gpu_cc_done_r(91, dtaux3d, SIZE(dtaux3d,KIND=8), 'dtaux3d', &
          LBOUND(dtaux3d), UBOUND(dtaux3d))
        IF (PRESENT(dtauy3d)) CALL gpu_cc_done_r(92, dtauy3d, SIZE(dtauy3d,KIND=8), 'dtauy3d', &
          LBOUND(dtauy3d), UBOUND(dtauy3d))
        IF (PRESENT(dusfcg)) CALL gpu_cc_done_r(93, dusfcg, SIZE(dusfcg,KIND=8), 'dusfcg', &
          LBOUND(dusfcg), UBOUND(dusfcg))
        IF (PRESENT(dvsfcg)) CALL gpu_cc_done_r(94, dvsfcg, SIZE(dvsfcg,KIND=8), 'dvsfcg', &
          LBOUND(dvsfcg), UBOUND(dvsfcg))
        IF (PRESENT(dtaux3d_ls)) CALL gpu_cc_done_r(95, dtaux3d_ls, SIZE(dtaux3d_ls,KIND=8), 'dtaux3d_ls', &
          LBOUND(dtaux3d_ls), UBOUND(dtaux3d_ls))
        IF (PRESENT(dtauy3d_ls)) CALL gpu_cc_done_r(96, dtauy3d_ls, SIZE(dtauy3d_ls,KIND=8), 'dtauy3d_ls', &
          LBOUND(dtauy3d_ls), UBOUND(dtauy3d_ls))
        IF (PRESENT(dtaux3d_bl)) CALL gpu_cc_done_r(97, dtaux3d_bl, SIZE(dtaux3d_bl,KIND=8), 'dtaux3d_bl', &
          LBOUND(dtaux3d_bl), UBOUND(dtaux3d_bl))
        IF (PRESENT(dtauy3d_bl)) CALL gpu_cc_done_r(98, dtauy3d_bl, SIZE(dtauy3d_bl,KIND=8), 'dtauy3d_bl', &
          LBOUND(dtauy3d_bl), UBOUND(dtauy3d_bl))
        IF (PRESENT(dtaux3d_ss)) CALL gpu_cc_done_r(99, dtaux3d_ss, SIZE(dtaux3d_ss,KIND=8), 'dtaux3d_ss', &
          LBOUND(dtaux3d_ss), UBOUND(dtaux3d_ss))
        IF (PRESENT(dtauy3d_ss)) CALL gpu_cc_done_r(100, dtauy3d_ss, SIZE(dtauy3d_ss,KIND=8), 'dtauy3d_ss', &
          LBOUND(dtauy3d_ss), UBOUND(dtauy3d_ss))
        IF (PRESENT(dtaux3d_fd)) CALL gpu_cc_done_r(101, dtaux3d_fd, SIZE(dtaux3d_fd,KIND=8), 'dtaux3d_fd', &
          LBOUND(dtaux3d_fd), UBOUND(dtaux3d_fd))
        IF (PRESENT(dtauy3d_fd)) CALL gpu_cc_done_r(102, dtauy3d_fd, SIZE(dtauy3d_fd,KIND=8), 'dtauy3d_fd', &
          LBOUND(dtauy3d_fd), UBOUND(dtauy3d_fd))
        IF (PRESENT(dusfcg_ls)) CALL gpu_cc_done_r(103, dusfcg_ls, SIZE(dusfcg_ls,KIND=8), 'dusfcg_ls', &
          LBOUND(dusfcg_ls), UBOUND(dusfcg_ls))
        IF (PRESENT(dvsfcg_ls)) CALL gpu_cc_done_r(104, dvsfcg_ls, SIZE(dvsfcg_ls,KIND=8), 'dvsfcg_ls', &
          LBOUND(dvsfcg_ls), UBOUND(dvsfcg_ls))
        IF (PRESENT(dusfcg_bl)) CALL gpu_cc_done_r(105, dusfcg_bl, SIZE(dusfcg_bl,KIND=8), 'dusfcg_bl', &
          LBOUND(dusfcg_bl), UBOUND(dusfcg_bl))
        IF (PRESENT(dvsfcg_bl)) CALL gpu_cc_done_r(106, dvsfcg_bl, SIZE(dvsfcg_bl,KIND=8), 'dvsfcg_bl', &
          LBOUND(dvsfcg_bl), UBOUND(dvsfcg_bl))
        IF (PRESENT(dusfcg_ss)) CALL gpu_cc_done_r(107, dusfcg_ss, SIZE(dusfcg_ss,KIND=8), 'dusfcg_ss', &
          LBOUND(dusfcg_ss), UBOUND(dusfcg_ss))
        IF (PRESENT(dvsfcg_ss)) CALL gpu_cc_done_r(108, dvsfcg_ss, SIZE(dvsfcg_ss,KIND=8), 'dvsfcg_ss', &
          LBOUND(dvsfcg_ss), UBOUND(dvsfcg_ss))
        IF (PRESENT(dusfcg_fd)) CALL gpu_cc_done_r(109, dusfcg_fd, SIZE(dusfcg_fd,KIND=8), 'dusfcg_fd', &
          LBOUND(dusfcg_fd), UBOUND(dusfcg_fd))
        IF (PRESENT(dvsfcg_fd)) CALL gpu_cc_done_r(110, dvsfcg_fd, SIZE(dvsfcg_fd,KIND=8), 'dvsfcg_fd', &
          LBOUND(dvsfcg_fd), UBOUND(dvsfcg_fd))
        IF (PRESENT(qv_curr)) CALL gpu_cc_done_r(111, qv_curr, SIZE(qv_curr,KIND=8), 'qv_curr', &
          LBOUND(qv_curr), UBOUND(qv_curr))
        IF (PRESENT(qc_curr)) CALL gpu_cc_done_r(112, qc_curr, SIZE(qc_curr,KIND=8), 'qc_curr', &
          LBOUND(qc_curr), UBOUND(qc_curr))
        IF (PRESENT(qr_curr)) CALL gpu_cc_done_r(113, qr_curr, SIZE(qr_curr,KIND=8), 'qr_curr', &
          LBOUND(qr_curr), UBOUND(qr_curr))
        IF (PRESENT(qi_curr)) CALL gpu_cc_done_r(114, qi_curr, SIZE(qi_curr,KIND=8), 'qi_curr', &
          LBOUND(qi_curr), UBOUND(qi_curr))
        IF (PRESENT(qs_curr)) CALL gpu_cc_done_r(115, qs_curr, SIZE(qs_curr,KIND=8), 'qs_curr', &
          LBOUND(qs_curr), UBOUND(qs_curr))
        IF (PRESENT(qg_curr)) CALL gpu_cc_done_r(116, qg_curr, SIZE(qg_curr,KIND=8), 'qg_curr', &
          LBOUND(qg_curr), UBOUND(qg_curr))
        IF (PRESENT(rqvblten)) CALL gpu_cc_done_r(117, rqvblten, SIZE(rqvblten,KIND=8), 'rqvblten', &
          LBOUND(rqvblten), UBOUND(rqvblten))
        IF (PRESENT(rqcblten)) CALL gpu_cc_done_r(118, rqcblten, SIZE(rqcblten,KIND=8), 'rqcblten', &
          LBOUND(rqcblten), UBOUND(rqcblten))
        IF (PRESENT(rqiblten)) CALL gpu_cc_done_r(119, rqiblten, SIZE(rqiblten,KIND=8), 'rqiblten', &
          LBOUND(rqiblten), UBOUND(rqiblten))
        IF (PRESENT(rqrblten)) CALL gpu_cc_done_r(120, rqrblten, SIZE(rqrblten,KIND=8), 'rqrblten', &
          LBOUND(rqrblten), UBOUND(rqrblten))
        IF (PRESENT(rqsblten)) CALL gpu_cc_done_r(121, rqsblten, SIZE(rqsblten,KIND=8), 'rqsblten', &
          LBOUND(rqsblten), UBOUND(rqsblten))
        IF (PRESENT(rqgblten)) CALL gpu_cc_done_r(122, rqgblten, SIZE(rqgblten,KIND=8), 'rqgblten', &
          LBOUND(rqgblten), UBOUND(rqgblten))
        IF (PRESENT(qnwfa_curr)) CALL gpu_cc_done_r(123, qnwfa_curr, SIZE(qnwfa_curr,KIND=8), 'qnwfa_curr', &
          LBOUND(qnwfa_curr), UBOUND(qnwfa_curr))
        IF (PRESENT(qnifa_curr)) CALL gpu_cc_done_r(124, qnifa_curr, SIZE(qnifa_curr,KIND=8), 'qnifa_curr', &
          LBOUND(qnifa_curr), UBOUND(qnifa_curr))
        IF (PRESENT(qnbca_curr)) CALL gpu_cc_done_r(125, qnbca_curr, SIZE(qnbca_curr,KIND=8), 'qnbca_curr', &
          LBOUND(qnbca_curr), UBOUND(qnbca_curr))
        IF (PRESENT(frc_urb2d)) CALL gpu_cc_done_r(126, frc_urb2d, SIZE(frc_urb2d,KIND=8), 'frc_urb2d', &
          LBOUND(frc_urb2d), UBOUND(frc_urb2d))
        IF (PRESENT(a_u_bep)) CALL gpu_cc_done_r(127, a_u_bep, SIZE(a_u_bep,KIND=8), 'a_u_bep', &
          LBOUND(a_u_bep), UBOUND(a_u_bep))
        IF (PRESENT(a_v_bep)) CALL gpu_cc_done_r(128, a_v_bep, SIZE(a_v_bep,KIND=8), 'a_v_bep', &
          LBOUND(a_v_bep), UBOUND(a_v_bep))
        IF (PRESENT(a_t_bep)) CALL gpu_cc_done_r(129, a_t_bep, SIZE(a_t_bep,KIND=8), 'a_t_bep', &
          LBOUND(a_t_bep), UBOUND(a_t_bep))
        IF (PRESENT(a_q_bep)) CALL gpu_cc_done_r(130, a_q_bep, SIZE(a_q_bep,KIND=8), 'a_q_bep', &
          LBOUND(a_q_bep), UBOUND(a_q_bep))
        IF (PRESENT(b_u_bep)) CALL gpu_cc_done_r(131, b_u_bep, SIZE(b_u_bep,KIND=8), 'b_u_bep', &
          LBOUND(b_u_bep), UBOUND(b_u_bep))
        IF (PRESENT(b_v_bep)) CALL gpu_cc_done_r(132, b_v_bep, SIZE(b_v_bep,KIND=8), 'b_v_bep', &
          LBOUND(b_v_bep), UBOUND(b_v_bep))
        IF (PRESENT(b_t_bep)) CALL gpu_cc_done_r(133, b_t_bep, SIZE(b_t_bep,KIND=8), 'b_t_bep', &
          LBOUND(b_t_bep), UBOUND(b_t_bep))
        IF (PRESENT(b_q_bep)) CALL gpu_cc_done_r(134, b_q_bep, SIZE(b_q_bep,KIND=8), 'b_q_bep', &
          LBOUND(b_q_bep), UBOUND(b_q_bep))
        IF (PRESENT(sf_bep)) CALL gpu_cc_done_r(135, sf_bep, SIZE(sf_bep,KIND=8), 'sf_bep', &
          LBOUND(sf_bep), UBOUND(sf_bep))
        IF (PRESENT(vl_bep)) CALL gpu_cc_done_r(136, vl_bep, SIZE(vl_bep,KIND=8), 'vl_bep', &
          LBOUND(vl_bep), UBOUND(vl_bep))
        CALL gpu_cc_done_r(137, tke_pbl, SIZE(tke_pbl,KIND=8), 'tke_pbl', &
          LBOUND(tke_pbl), UBOUND(tke_pbl))
        CALL gpu_cc_done_r(138, diss_pbl, SIZE(diss_pbl,KIND=8), 'diss_pbl', &
          LBOUND(diss_pbl), UBOUND(diss_pbl))
        CALL gpu_cc_done_r(139, tpe_pbl, SIZE(tpe_pbl,KIND=8), 'tpe_pbl', &
          LBOUND(tpe_pbl), UBOUND(tpe_pbl))
        CALL gpu_cc_done_r(140, tke_adv, SIZE(tke_adv,KIND=8), 'tke_adv', &
          LBOUND(tke_adv), UBOUND(tke_adv))
        CALL gpu_cc_done_r(141, diss_adv, SIZE(diss_adv,KIND=8), 'diss_adv', &
          LBOUND(diss_adv), UBOUND(diss_adv))
        CALL gpu_cc_done_r(142, tpe_adv, SIZE(tpe_adv,KIND=8), 'tpe_adv', &
          LBOUND(tpe_adv), UBOUND(tpe_adv))
        CALL gpu_cc_done_r(143, pr_pbl, SIZE(pr_pbl,KIND=8), 'pr_pbl', &
          LBOUND(pr_pbl), UBOUND(pr_pbl))
        CALL gpu_cc_done_r(144, el_pbl, SIZE(el_pbl,KIND=8), 'el_pbl', &
          LBOUND(el_pbl), UBOUND(el_pbl))
        CALL gpu_cc_done_r(145, wu_tur, SIZE(wu_tur,KIND=8), 'wu_tur', &
          LBOUND(wu_tur), UBOUND(wu_tur))
        CALL gpu_cc_done_r(146, wv_tur, SIZE(wv_tur,KIND=8), 'wv_tur', &
          LBOUND(wv_tur), UBOUND(wv_tur))
        CALL gpu_cc_done_r(147, wt_tur, SIZE(wt_tur,KIND=8), 'wt_tur', &
          LBOUND(wt_tur), UBOUND(wt_tur))
        CALL gpu_cc_done_r(148, wq_tur, SIZE(wq_tur,KIND=8), 'wq_tur', &
          LBOUND(wq_tur), UBOUND(wq_tur))
        IF (PRESENT(exch_tke)) CALL gpu_cc_done_r(149, exch_tke, SIZE(exch_tke,KIND=8), 'exch_tke', &
          LBOUND(exch_tke), UBOUND(exch_tke))
        CALL gpu_cc_done_r(150, rthraten, SIZE(rthraten,KIND=8), 'rthraten', &
          LBOUND(rthraten), UBOUND(rthraten))
        IF (PRESENT(a_e_bep)) CALL gpu_cc_done_r(151, a_e_bep, SIZE(a_e_bep,KIND=8), 'a_e_bep', &
          LBOUND(a_e_bep), UBOUND(a_e_bep))
        IF (PRESENT(b_e_bep)) CALL gpu_cc_done_r(152, b_e_bep, SIZE(b_e_bep,KIND=8), 'b_e_bep', &
          LBOUND(b_e_bep), UBOUND(b_e_bep))
        IF (PRESENT(dlg_bep)) CALL gpu_cc_done_r(153, dlg_bep, SIZE(dlg_bep,KIND=8), 'dlg_bep', &
          LBOUND(dlg_bep), UBOUND(dlg_bep))
        IF (PRESENT(dl_u_bep)) CALL gpu_cc_done_r(154, dl_u_bep, SIZE(dl_u_bep,KIND=8), 'dl_u_bep', &
          LBOUND(dl_u_bep), UBOUND(dl_u_bep))
        IF (PRESENT(massflux_edkf)) CALL gpu_cc_done_r(155, massflux_edkf, SIZE(massflux_edkf,KIND=8), 'massflux_edkf', &
          LBOUND(massflux_edkf), UBOUND(massflux_edkf))
        IF (PRESENT(entr_edkf)) CALL gpu_cc_done_r(156, entr_edkf, SIZE(entr_edkf,KIND=8), 'entr_edkf', &
          LBOUND(entr_edkf), UBOUND(entr_edkf))
        IF (PRESENT(detr_edkf)) CALL gpu_cc_done_r(157, detr_edkf, SIZE(detr_edkf,KIND=8), 'detr_edkf', &
          LBOUND(detr_edkf), UBOUND(detr_edkf))
        IF (PRESENT(thl_up)) CALL gpu_cc_done_r(158, thl_up, SIZE(thl_up,KIND=8), 'thl_up', &
          LBOUND(thl_up), UBOUND(thl_up))
        IF (PRESENT(thv_up)) CALL gpu_cc_done_r(159, thv_up, SIZE(thv_up,KIND=8), 'thv_up', &
          LBOUND(thv_up), UBOUND(thv_up))
        IF (PRESENT(rt_up)) CALL gpu_cc_done_r(160, rt_up, SIZE(rt_up,KIND=8), 'rt_up', &
          LBOUND(rt_up), UBOUND(rt_up))
        IF (PRESENT(rv_up)) CALL gpu_cc_done_r(161, rv_up, SIZE(rv_up,KIND=8), 'rv_up', &
          LBOUND(rv_up), UBOUND(rv_up))
        IF (PRESENT(rc_up)) CALL gpu_cc_done_r(162, rc_up, SIZE(rc_up,KIND=8), 'rc_up', &
          LBOUND(rc_up), UBOUND(rc_up))
        IF (PRESENT(u_up)) CALL gpu_cc_done_r(163, u_up, SIZE(u_up,KIND=8), 'u_up', &
          LBOUND(u_up), UBOUND(u_up))
        IF (PRESENT(v_up)) CALL gpu_cc_done_r(164, v_up, SIZE(v_up,KIND=8), 'v_up', &
          LBOUND(v_up), UBOUND(v_up))
        IF (PRESENT(frac_up)) CALL gpu_cc_done_r(165, frac_up, SIZE(frac_up,KIND=8), 'frac_up', &
          LBOUND(frac_up), UBOUND(frac_up))
        IF (PRESENT(rc_mf)) CALL gpu_cc_done_r(166, rc_mf, SIZE(rc_mf,KIND=8), 'rc_mf', &
          LBOUND(rc_mf), UBOUND(rc_mf))
        IF (PRESENT(id)) CALL gpu_cc_done_i0(167, id, 'id')
        IF (PRESENT(tauresx2d)) CALL gpu_cc_done_r(168, tauresx2d, SIZE(tauresx2d,KIND=8), 'tauresx2d', &
          LBOUND(tauresx2d), UBOUND(tauresx2d))
        IF (PRESENT(tauresy2d)) CALL gpu_cc_done_r(169, tauresy2d, SIZE(tauresy2d,KIND=8), 'tauresy2d', &
          LBOUND(tauresy2d), UBOUND(tauresy2d))
        IF (PRESENT(tpert2d)) CALL gpu_cc_done_r(170, tpert2d, SIZE(tpert2d,KIND=8), 'tpert2d', &
          LBOUND(tpert2d), UBOUND(tpert2d))
        IF (PRESENT(qpert2d)) CALL gpu_cc_done_r(171, qpert2d, SIZE(qpert2d,KIND=8), 'qpert2d', &
          LBOUND(qpert2d), UBOUND(qpert2d))
        IF (PRESENT(wpert2d)) CALL gpu_cc_done_r(172, wpert2d, SIZE(wpert2d,KIND=8), 'wpert2d', &
          LBOUND(wpert2d), UBOUND(wpert2d))
        IF (PRESENT(turbtype3d)) CALL gpu_cc_done_r(173, turbtype3d, SIZE(turbtype3d,KIND=8), 'turbtype3d', &
          LBOUND(turbtype3d), UBOUND(turbtype3d))
        IF (PRESENT(smaw3d)) CALL gpu_cc_done_r(174, smaw3d, SIZE(smaw3d,KIND=8), 'smaw3d', &
          LBOUND(smaw3d), UBOUND(smaw3d))
        IF (PRESENT(qnc_curr)) CALL gpu_cc_done_r(175, qnc_curr, SIZE(qnc_curr,KIND=8), 'qnc_curr', &
          LBOUND(qnc_curr), UBOUND(qnc_curr))
        IF (PRESENT(qni_curr)) CALL gpu_cc_done_r(176, qni_curr, SIZE(qni_curr,KIND=8), 'qni_curr', &
          LBOUND(qni_curr), UBOUND(qni_curr))
        IF (PRESENT(rqniblten)) CALL gpu_cc_done_r(177, rqniblten, SIZE(rqniblten,KIND=8), 'rqniblten', &
          LBOUND(rqniblten), UBOUND(rqniblten))
        IF (PRESENT(wstar)) CALL gpu_cc_done_r(178, wstar, SIZE(wstar,KIND=8), 'wstar', &
          LBOUND(wstar), UBOUND(wstar))
        IF (PRESENT(delta)) CALL gpu_cc_done_r(179, delta, SIZE(delta,KIND=8), 'delta', &
          LBOUND(delta), UBOUND(delta))
        IF (PRESENT(scalar)) CALL gpu_cc_done_r(180, scalar, SIZE(scalar,KIND=8), 'scalar', &
          LBOUND(scalar), UBOUND(scalar))
        IF (PRESENT(scalar_tend)) CALL gpu_cc_done_r(181, scalar_tend, SIZE(scalar_tend,KIND=8), 'scalar_tend', &
          LBOUND(scalar_tend), UBOUND(scalar_tend))
        IF (PRESENT(tracer)) CALL gpu_cc_done_r(182, tracer, SIZE(tracer,KIND=8), 'tracer', &
          LBOUND(tracer), UBOUND(tracer))
        IF (PRESENT(tracer_tend)) CALL gpu_cc_done_r(183, tracer_tend, SIZE(tracer_tend,KIND=8), 'tracer_tend', &
          LBOUND(tracer_tend), UBOUND(tracer_tend))
#if (WRF_CHEM == 1)
        CALL gpu_cc_done_r(184, chem, SIZE(chem,KIND=8), 'chem', &
          LBOUND(chem), UBOUND(chem))
#endif
        IF (PRESENT(qnorm)) CALL gpu_cc_done_r(185, qnorm, SIZE(qnorm,KIND=8), 'qnorm', &
          LBOUND(qnorm), UBOUND(qnorm))
        IF (gpu_cc_next(R_PBL_DRIVER)) GOTO 99901
      END IF
#endif

   END SUBROUTINE pbl_driver

   subroutine  Add_multi_perturb_pbl_perturbations (perts_qvapor, perts_qcloud, &
                  perts_th, perts_tke, pert_mynn_qv, pert_mynn_qc, pert_mynn_t, pert_mynn_qke, &
                  th_phy, qke, qke_adv, qv_curr, qc_curr, bl_mynn_tkeadvect, qke_tmp, its, ite, jts, jte, &
                  ims, ime, jms, jme, kms, kme, kts, kte)


     implicit none

     integer, intent(in) :: its, ite, jts, jte, ims, ime, jms, jme, kms, kme, kts, kte
     logical, optional, intent(in) :: bl_mynn_tkeadvect
     real, intent(in) :: pert_mynn_qv, pert_mynn_qc, pert_mynn_t, pert_mynn_qke
     real, dimension(ims:ime, kms:kme, jms:jme), optional, intent (in) :: perts_qvapor, &
       perts_qcloud, perts_th, perts_tke
     real, dimension(ims:ime, kms:kme, jms:jme), intent (inout) :: th_phy, qke, qv_curr, qc_curr
     real, optional, dimension (ims:ime, kms:kme, jms:jme), intent(inout) :: qke_adv
     real, dimension (its:ite, kts:kte, jts:jte), intent(out) :: qke_tmp

     integer :: i, j, k


     do j = jts, jte
       do k = kts, kte 
         do i = its, ite 
           qc_curr(i, k, j) = max (QCLOUD_MIN, (1.0 + perts_qcloud(i, k, j) * pert_mynn_qc) * qc_curr(i, k, j))
           qv_curr(i, k, j) = max (QVAPOR_MIN, (1.0 + perts_qvapor(i, k, j) * pert_mynn_qv) * qv_curr(i, k, j))
           th_phy(i, k, j) = (1.0 + perts_th(i, k, j) * pert_mynn_t) * th_phy(i, k, j)
         end do
       end do
     end do

     if (bl_mynn_tkeadvect) then
       do j = jts, jte
         do k = kts, kte
           do i = its, ite
             qke_tmp(i, k, j) = qke_adv(i, k, j)
             qke_adv(i, k, j) = max (QKE_MIN, (1.0 + perts_tke(i, k, j) * pert_mynn_qke) * qke_adv(i, k, j))
           end do
         end do
       end do
     else
       do j = jts, jte
         do k = kts, kte
           do i = its, ite
             qke_tmp(i, k, j) = qke(i, k, j)
             qke(i, k, j) = max (QKE_MIN, (1.0 + perts_tke(i, k, j) * pert_mynn_qke) * qke(i, k, j))
           end do
         end do
       end do
     end if

   end subroutine  Add_multi_perturb_pbl_perturbations

   subroutine  Remove_multi_perturb_pbl_perturbations (perts_qvapor, perts_qcloud, &
                  perts_th, perts_tke, pert_mynn_qv, pert_mynn_qc, pert_mynn_t, pert_mynn_qke, &
                  th_phy, qke, qke_adv, qv_curr, qc_curr, bl_mynn_tkeadvect, qke_tmp, its, ite, jts, jte, &
                  ims, ime, jms, jme, kms, kme, kts, kte)


     implicit none

     integer, intent(in) :: its, ite, jts, jte, ims, ime, jms, jme, kms, kme, kts, kte
     logical, optional, intent(in) :: bl_mynn_tkeadvect
     real, intent(in) :: pert_mynn_qv, pert_mynn_qc, pert_mynn_t, pert_mynn_qke
     real, dimension(ims:ime, kms:kme, jms:jme), optional, intent (in) :: perts_qvapor, &
       perts_qcloud, perts_th, perts_tke
     real, dimension(ims:ime, kms:kme, jms:jme), intent (inout) :: th_phy, qke, qv_curr, qc_curr
     real, optional, dimension (ims:ime, kms:kme, jms:jme), intent(inout) :: qke_adv
     real, dimension (its:ite, kts:kte, jts:jte), intent(in) :: qke_tmp

     integer :: i, j, k


     do j = jts, jte
       do k = kts, kte
         do i = its, ite
           qc_curr(i, k, j) = max (QCLOUD_MIN, qc_curr(i, k, j) / (1.0 + perts_qcloud(i, k, j) * pert_mynn_qc))
           qv_curr(i, k, j) = max (QVAPOR_MIN, qv_curr(i, k, j) / (1.0 + perts_qvapor(i, k, j) * pert_mynn_qv))
           th_phy(i, k, j) = th_phy(i, k, j) / (1.0 + perts_th(i, k, j) * pert_mynn_t)
         end do
       end do
     end do

     if (bl_mynn_tkeadvect) then
       do j = jts, jte
         do k = kts, kte
           do i = its, ite
             qke_adv(i, k, j) = max (QKE_MIN, qke_adv(i, k, j) - perts_tke(i, k, j) * pert_mynn_qke * qke_tmp(i, k, j))
             qke(i, k, j) = qke_adv(i, k, j)
           end do
         end do
       end do
     else
       do j = jts, jte
         do k = kts, kte
           do i = its, ite
             qke(i, k, j) = max (QKE_MIN, qke(i, k, j) - perts_tke(i, k, j) * pert_mynn_qke * qke_tmp(i, k, j))
           end do
         end do
       end do
     end if

   end subroutine  Remove_multi_perturb_pbl_perturbations

!=============================================================================
          SUBROUTINE diff3d(DT,CP,DZ,TH ,QV,QC,T,U,V,RHO                              &
              ,EXCH_H,EXCH_M                   &  
              ,RUBLTEN,RVBLTEN,RTHBLTEN    &
              ,RQVBLTEN,RQCBLTEN                  &
              ,WU,WV,WT,WQ                 &
              ,A_U,A_V,A_T,A_Q      &
              ,B_U,B_V,B_T,B_Q      &
              ,SF,VL        &
              ,IDS,IDE,JDS,JDE,KDS,KDE      &
              ,IMS,IME,JMS,JME,KMS,KME      &
              ,ITS,ITE,JTS,JTE,KTS,KTE      &
                                                                    )
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!    Subroutine written by Alberto Martilli, CIEMAT, Spain,
!    e-mail:alberto_martilli@ciemat.es
!    August 2008.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ALberto
! This routine solves the vertical diffusion 
! + other source/sink terms (surface fluxes, building drag, non local terms, etc.)
! for U,V, potential temperature and moisture. The equation should be written 
! as follow, for a generic variable M:
! 
!      dM      1     d      dM
!     ---- =----  ---(rho*K----)+AM+B
!      dt     rho    dz     dz  
! where A and B are the implict and explcit coefficients of the source/sink terms
! (at the lowest level the surface fluxes should go in these terms)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!-----------------------------------------------------------------------

      IMPLICIT NONE
!
!----------------------------------------------------------------------
      INTEGER,INTENT(IN) :: IDS,IDE,JDS,JDE,KDS,KDE                    &
     &                     ,IMS,IME,JMS,JME,KMS,KME                    &
     &                     ,ITS,ITE,JTS,JTE,KTS,KTE

! INputs
      real DT,CP
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: DZ ! Depth of vertical levels
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: TH ! Potential Temperature
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: QV ! water vapor mixing ratio (kg/kg)
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: QC ! cloud water mixing ratio (kg/kg)
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: T  ! temperature
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: U ! X-compnent of the wind
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: V ! Y-compnent of the wind
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: RHO ! Air Density
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: EXCH_H ! Turbulent coefficient for heat
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: EXCH_M ! Turbulent coefficient for momentum 
      
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: A_U ! Implicit coefficient for DRAG (x -component)
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: B_U ! Explicit coefficient for DRAG (x -component)
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: A_V ! Implicit coefficient for DRAG (y -component)
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: B_V ! Explicit coefficient for DRAG (y -component)
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: A_T ! Implicit coefficient for Heat flux from buildings
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: B_T ! Explicit coefficient for Heat flux from buildings
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: A_Q ! Implicit coefficient for moisture flux
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: B_Q ! Explicit coefficient for moisture flux 
    
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: VL ! fraction of air volume in the grid cell
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: SF ! fraction of air at the face of the grid cell
!outputs
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(OUT) :: RUBLTEN ! tendency for x-wind component
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(OUT) :: RVBLTEN ! tendency for y-wind component
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(OUT) :: RTHBLTEN ! tendency for Potential Temperature
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(OUT) :: RQVBLTEN ! tendency for water vapor mixing ratio (kg/kg)
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(OUT) :: RQCBLTEN ! tendency for cloud water mixing ratio (kg/kg)
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(OUT) :: WU ! turbulent flux of momentum (x)
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(OUT) :: WV ! turbulent flux of momentum (y)
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(OUT) :: WT ! turbulent flux of potential temperature
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(OUT) :: WQ ! turbulent flux of water vapor
! Parameters
     REAL ELOCP 
! locals (same meaning as above, but 1D)

      real u1d(kms:kme),v1d(kms:kme),exch_h1d(kms:kme)
      real the1d(kms:kme) ! Equivalent potential temperature
      real exch_m1d(kms:kme),qv1d(kms:kme),qc1d(kms:kme)
      real dz1d(kms:kme),rho1d(kms:kme),rhoz1d(kms:kme)
      real sf1d(kms:kme),vl1d(kms:kme)   
      real a_u1d(kms:kme),b_u1d(kms:kme)
      real a_v1d(kms:kme),b_v1d(kms:kme)
      real a_t1d(kms:kme),b_t1d(kms:kme)
      real a_q1d(kms:kme),b_q1d(kms:kme)
      real a_qc1d(kms:kme),b_qc1d(kms:kme)
      real wu1d(kms:kme),wv1d(kms:kme),wt1d(kms:kme),wq1d(kms:kme),wqc1d(kms:kme)
      real thnew
!
      integer i,k,j  
!----------------------------------------------------------------------
      ELOCP=2.72E6/CP
      u1d=0.
      v1d=0.
      exch_h1d=0.
      exch_m1d=0.
      qv1d=0.
      qc1d=0.
      dz1d=0.
      rho1d=0.
      rhoz1d=0.
      sf1d=0.
      vl1d=0.
      a_u1d=0.
      a_v1d=0.
      a_t1d=0.
      a_q1d=0.
      a_qc1d=0.
      b_u1d=0.
      b_v1d=0.
      b_t1d=0.
      b_q1d=0.
      b_qc1d=0.
       
      do j=jts,jte
      do i=its,ite

! put three D variables in temporary 1D variables

       do k=kts,kte
        u1d(k)=U(i,k,j)
        v1d(k)=V(i,k,j)
        the1d(k)=TH(i,k,j)*(QC(i,k,j)*(-ELOCP/T(i,k,j))+1)
        qv1d(k)=qv(i,k,j)
        dz1d(k)=dz(i,k,j)
        rho1d(k)=rho(i,k,j) 
        a_u1d(k)=a_u(i,k,j)
        b_u1d(k)=b_u(i,k,j)
        a_v1d(k)=a_v(i,k,j)
        b_v1d(k)=b_v(i,k,j)
        a_t1d(k)=a_t(i,k,j)
        b_t1d(k)=b_t(i,k,j)
        a_q1d(k)=a_q(i,k,j)
        b_q1d(k)=b_q(i,k,j)
        a_qc1d(k)=0.
        b_qc1d(k)=0.
        vl1d(k)=vl(i,k,j)
        sf1d(k)=sf(i,k,j)
       enddo
       sf1d(kte+1)=1. 
       do k=kts,kte    
        exch_h1d(k)=exch_h(i,k,j)
        exch_m1d(k)=exch_m(i,k,j)
       enddo
       exch_h1d(kts)=0.
!       exch_h1d(kte+1)=0  
       exch_m1d(kts)=0.
!       exch_m1d(kte+1)=0
        rhoz1d(kts)=rho1d(kts)
        do k=kts+1,kte
         rhoz1d(k)=(rho1d(k)*dz1d(k-1)+rho1d(k-1)*dz1d(k))/       &
     &                      (dz1d(k-1)+dz1d(k))
        enddo
        rhoz1d(kte+1)=rho1d(kte)


! solve the diffusion for x-component of the wind   
          
       call diff(kms,kme,kts,kte,dt,u1d,rho1d,rhoz1d,exch_m1d,a_u1d,b_u1d,sf1d, &
     &            vl1d,dz1d,wu1d) 

! solve the diffusion for y-component of the wind              

       call diff(kms,kme,kts,kte,dt,v1d,rho1d,rhoz1d,exch_m1d,a_v1d,b_v1d,sf1d, &
     &            vl1d,dz1d,wv1d) 

! solve the diffusion for equivalent potential temperature

       call diff(kms,kme,kts,kte,dt,the1d,rho1d,rhoz1d,exch_h1d,a_t1d,b_t1d,sf1d, &
     &            vl1d,dz1d,wt1d) 

! solve the diffusion for the water vapor mixing ratio

       call diff(kms,kme,kts,kte,dt,qv1d,rho1d,rhoz1d,exch_h1d,a_q1d,b_q1d,sf1d, &
     &            vl1d,dz1d,wq1d) 

! solve the diffusion for the cloud water mixing ratio

       call diff(kms,kme,kts,kte,dt,qc1d,rho1d,rhoz1d,exch_h1d,a_qc1d,b_qc1d,sf1d, &
     &            vl1d,dz1d,wqc1d)        

!     
! compute the tendencies

        do k=kts,kte
          rublten(i,k,j)=(u1d(k)-u(i,k,j))/dt
          rvblten(i,k,j)=(v1d(k)-v(i,k,j))/dt
          thnew=the1d(k)/(QC(i,k,j)*(-ELOCP/T(i,k,j))+1)
          rthblten(i,k,j)=(thnew-th(i,k,j))/dt
          rqvblten(i,k,j)=(qv1d(k)-qv(i,k,j))/dt
          rqcblten(i,k,j)=(qc1d(k)-qc(i,k,j))/dt
          wu(i,k,j)=wu1d(k)
          wv(i,k,j)=wv1d(k)
          wt(i,k,j)=wt1d(k)
          wq(i,k,j)=wq1d(k)
        enddo
      enddo
      enddo 
!!!!!!!!!!!!

        
      END SUBROUTINE diff3d
#if (EM_CORE==1)
! ===6=8===============================================================72
          SUBROUTINE diff4d(DT,DZ,SCALAR,IS_SCALAR,RHO              &
              ,EXCH_H,EXCH_M  &  
              ,SCALAR_TEND    &
              ,NUM_SCALAR, PARAM_FIRST_SCALAR     &
              ,IDS,IDE,JDS,JDE,KDS,KDE      &
              ,IMS,IME,JMS,JME,KMS,KME      &
              ,ITS,ITE,JTS,JTE,KTS,KTE      &
                                                                    )
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!    Based on subroutine written by Alberto Martilli, CIEMAT, Spain,
!    e-mail:alberto_martilli@ciemat.es
!    August 2008.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ALberto
! This routine solves the vertical diffusion 
! + other source/sink terms (surface fluxes, building drag, non local terms, etc.)
! for U,V, potential temperature and moisture. The equation should be written 
! as follow, for a generic variable M:
! 
!      dM      1     d      dM
!     ---- =----  ---(rho*K----)+AM+B
!      dt     rho    dz     dz  
! where A and B are the implict and explcit coefficients of the source/sink terms
! (at the lowest level the surface fluxes should go in these terms)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!-----------------------------------------------------------------------
      USE module_state_description, ONLY: &
                  P_QNS, P_QNR, P_QNG, P_QT, P_QNH, P_QVOLG, P_QKE_ADV


      IMPLICIT NONE
!
!----------------------------------------------------------------------
      INTEGER,INTENT(IN) :: NUM_SCALAR, PARAM_FIRST_SCALAR
      INTEGER,INTENT(IN) :: IDS,IDE,JDS,JDE,KDS,KDE                    &
     &                     ,IMS,IME,JMS,JME,KMS,KME                    &
     &                     ,ITS,ITE,JTS,JTE,KTS,KTE

! inputs
      REAL, INTENT(IN)   :: DT
      LOGICAL,INTENT(IN) :: IS_SCALAR
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: DZ ! Depth of vertical levels
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME,NUM_SCALAR),INTENT(IN) :: SCALAR ! 4d scalar mixing ratio
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: RHO ! Air Density
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: EXCH_H ! Turbulent coefficient for heat
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN) :: EXCH_M ! Turbulent coefficient for momentum 
      
! outputs
      REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME,NUM_SCALAR),INTENT(INOUT) :: SCALAR_TEND ! 4d scalar mixing ratio tendency
! locals (same meaning as above, but 1D)

      real s1d(kms:kme),exch_h1d(kms:kme)
      real exch_m1d(kms:kme)
      real dz1d(kms:kme),rho1d(kms:kme),rhoz1d(kms:kme)
      real sf1d(kms:kme),vl1d(kms:kme)   
      real a_s1d(kms:kme),b_s1d(kms:kme)
      real ws1d(kms:kme)
!
      integer i,k,j,im  
!----------------------------------------------------------------------
      s1d=0.
      exch_h1d=0.
      exch_m1d=0.
      rho1d=0.
      rhoz1d=0.
      sf1d=0.
      vl1d=0.
      a_s1d=0.
      b_s1d=0.
       
      DO im=PARAM_FIRST_SCALAR,NUM_SCALAR
! need to avoid mixing scalars associated with precipitating species (e.g. Nr)
        IF((IS_SCALAR .AND. im.NE.P_QNS .AND. im.NE.P_QNR .AND. im.NE.P_QNG &
          .AND. im.NE.P_QNH .AND. im.NE.P_QT .AND. im.NE.P_QVOLG .AND. im.NE.P_QKE_ADV) &
          .OR. (.not. IS_SCALAR)) THEN
        do j=jts,jte
        do i=its,ite

! put three D variables in temporary 1D variables

       do k=kts,kte
        s1d(k)=SCALAR(i,k,j,im)
        dz1d(k)=dz(i,k,j)
        rho1d(k)=rho(i,k,j) 
!        a_s1d(k)=a_s(i,k,j)   ! implicit source
!        b_s1d(k)=b_s(i,k,j)   ! explicit source
        vl1d(k)=1.
        sf1d(k)=1.
       enddo
       sf1d(kte+1)=1. 
       do k=kts,kte    
        exch_h1d(k)=exch_h(i,k,j)
        exch_m1d(k)=exch_m(i,k,j)
       enddo
       exch_h1d(kts)=0.
!       exch_h1d(kte+1)=0  
       exch_m1d(kts)=0.
!       exch_m1d(kte+1)=0
        rhoz1d(kts)=rho1d(kts)
        do k=kts+1,kte
         rhoz1d(k)=(rho1d(k)*dz1d(k-1)+rho1d(k-1)*dz1d(k))/       &
     &                      (dz1d(k-1)+dz1d(k))
        enddo
        rhoz1d(kte+1)=rho1d(kte)


! solve the diffusion for scalar
          
       call diff(kms,kme,kts,kte,dt,s1d,rho1d,rhoz1d,exch_h1d,a_s1d,b_s1d,sf1d, &
     &            vl1d,dz1d,ws1d) 

!     
! compute the tendencies

        do k=kts,kte
          scalar_tend(i,k,j,im)=(s1d(k)-scalar(i,k,j,im))/dt
!          ws(i,k,j)=ws1d(k)   ! output fluxes
        enddo
        enddo
        enddo 
      ELSE
!      print *,'scalar skipped im=',im, is_scalar
      ENDIF
      
      ENDDO ! im loop
!!!!!!!!!!!!

        
      END SUBROUTINE diff4d
! ===6=8===============================================================72
#endif

       subroutine diff(kms,kme,kts,kte,dt,co,da,daz,cd,aa,bb,sf,vl,dz,fc)

!------------------------------------------------------------------------
!           Calculation of the diffusion in 1D
!------------------------------------------------------------------------
!  - Input:
!       nz    : number of points
!       iz1   : first calculated point
!       co    : concentration of the variable of interest
!       dz    : vertical levels
!       cd    : diffusion coefficients
!       da    : density of the air at the center
!       daz   : density of the air at the face
!       dt    : diffusion time step
!  - Output:
!       co :concentration of the variable of interest

!  - Internal:
!       cddz  : constant terms in the equations
!---------------------------------------------------------------------

        implicit none
        integer iz,iz1,izf
        integer kms,kme,kts,kte
        real dt,dzv
        real co(kms:kme),cd(kms:kme),dz(kms:kme)
        real da(kms:kme),daz(kms:kme)
        real cddz(kms:kme),fc(kms:kme),df(kms:kme)
        real a(kms:kme,3),c(kms:kme)
        real sf(kms:kme),vl(kms:kme)
        real aa(kms:kme),bb(kms:kme)

        
! Compute cddz=2*cd/dz

        cddz(kts)=sf(kts)*daz(kts)*cd(kts)/dz(kts)
        do iz=kts+1,kte
         cddz(iz)=2.*sf(iz)*daz(iz)*cd(iz)/(dz(iz)+dz(iz-1))
        enddo
        cddz(kte+1)=sf(kte+1)*daz(kte+1)*cd(kte+1)/dz(kte)

          iz1=1
          izf=1

          do iz=iz1,kte-1

           dzv=vl(iz)*dz(iz)
           a(iz,1)=-cddz(iz)*dt/dzv/da(iz)
           a(iz,2)=1+dt*(cddz(iz)+cddz(iz+1))/dzv/da(iz)-aa(iz)*dt
           a(iz,3)=-cddz(iz+1)*dt/dzv/da(iz)
           c(iz)=co(iz)+bb(iz)*dt
          enddo

          do iz=kte-(izf-1),kte
           a(iz,1)=0.
           a(iz,2)=1
           a(iz,3)=0.
           c(iz)=co(iz)
          enddo
          call invert (kms,kme,kts,kte,a,c,co)
           
!let compute the fluxes, as diagnostic variable

          do iz=kts,iz1
           fc(iz)=0.
          enddo

          do iz=iz1+1,kte
           fc(iz)=-(cddz(iz)*(co(iz)-co(iz-1)))/da(iz)
          enddo



       return
       end subroutine diff
! ===6=8===============================================================72

       subroutine invert(kms,kme,kts,kte,a,c,x)

!ccccccccccccccccccccccccccccccc
! Aim: Inversion and resolution of a tridiagonal matrix
!          A X = C
! Input:
!  a(*,1) lower diagonal (Ai,i-1)
!  a(*,2) principal diagonal (Ai,i)
!  a(*,3) upper diagonal (Ai,i+1)
!  c
! Output
!  x     results
!ccccccccccccccccccccccccccccccc

       implicit none
       integer kms,kme,kts,kte,in
       real a(kms:kme,3),c(kms:kme),x(kms:kme)

        do in=kte-1,kts,-1
         c(in)=c(in)-a(in,3)*c(in+1)/a(in+1,2)
         a(in,2)=a(in,2)-a(in,3)*a(in+1,1)/a(in+1,2)
        enddo

        do in=kts+1,kte
         c(in)=c(in)-a(in,1)*c(in-1)/a(in-1,2)
        enddo

        do in=kts,kte
         x(in)=c(in)/a(in,2)
        enddo

        return
        end subroutine invert

! ===6=8===============================================================72

END MODULE module_pbl_driver
