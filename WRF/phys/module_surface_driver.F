!WRF:MEDIATION_LAYER:PHYSICS
!
MODULE module_surface_driver
   USE module_repro_math
  real, private, parameter :: QVAPOR_MIN = 0.0, SMOIS_MIN = 0.0, SMOIS_MAX = 1.0
CONTAINS

   SUBROUTINE surface_driver(                                         &
     &           HYDRO_dt,sfcheadrt,INFXSRT,soldrain,                 &
     &           qtiledrain,ZWATBLE2D,                                & ! tile drainage for WRF-Hydro
     &           acgrdflx,achfx,aclhf                                 &
     &          ,acsnom,acsnow,snowfallac,akhs,akms,albedo,br,canwat  &
     &          ,chklowq,dt,dx,dx2d,area2d,dz8w,dzs,glw               &
     &          ,grdflx,gsw,swdown,gz1oz0,hfx,ht,ifsnow,isfflx        &
     &          ,fractional_seaice,seaice_albedo_opt                  &
     &          ,seaice_albedo_default,seaice_thickness_opt,          &
     &          seaice_thickness_default                              &
     &          ,seaice_snowdepth_opt,seaice_snowdepth_max            &
     &          ,seaice_snowdepth_min,tice2tsk_if2cold                &
     &          ,ifndalbsi, ifndicedepth, ifndsnowsi                  &
     &          ,isltyp,itimestep,julian_in,ivgtyp,lowlyr,mavail,rmol &
     &          ,num_soil_layers,p8w,pblh,pi_phy,pshltr,fm,fhh,psih   &
     &          ,psim,p_phy,q10,q2,qfx,qsfc,qshltr,qz0                &
     &          ,raincv,rho,sfcevp,sfcexc,sfcrunoff ,acrunoff         &
     &          ,smois,smstav,smstot,snoalb,snow,snowc,snowh,stepbl   &
     &          ,smcrel                                               &
     &          ,th10,th2,thz0,th_phy,tmn,tshltr,tsk,tslb             &
     &          ,tyr,tyra,tdly,tlag,lagday,nyear,nday,tmn_update,yr   &
     &          ,t_phy,u10,udrunoff,ust,uz0                           &
     &          ,u_frame,u_phy,v10,vegfra,u10e,v10e,uoce,voce         &
     &          ,vz0,v_frame,v_phy,warm_rain,wspd,xice,xland,z,znt    &
     &          ,max_edom,cplmask                                     &
     &          ,zs                                                   & 
     &          ,albsi, icedepth,snowsi                               &
     &          ,xicem,isice,iswater,ct,tke_pbl                       &
     &          ,albbck,embck,lh,sh2o,shdmax,shdmin,shdavg,z0         &
     &          ,flqc,flhc,psfc,sst,sst_input,sstsk,dtw,sst_update,sst_skin     &
     &          ,scm_force_skintemp,scm_force_flux,t2,emiss           &
     &          ,sf_sfclay_physics,sf_surface_physics,ra_lw_physics   & 
     &          ,bl_pbl_physics                                       &
     &          ,mosaic_lu,mosaic_soil                                &
     &          ,landusef,soilctop,soilcbot,ra,rs,nlcat,nscat,vegf_px & ! PX-LSM
     &          ,snowncv, anal_interval, lai, imperv, canfra          & ! PX-LSM
     &          ,pxlsm_smois_init, pxlsm_soil_nudge                   & ! PX-LSM
     &          ,pxlsm_modis_veg, lai_px, wwlt_px, wfc_px                           & ! PX-LSM
     &          ,wsat_px, clay_px, csand_px, fmsand_px                              & ! PX-LSM
     &          ,idveg    ,iopt_crs  ,iopt_btr  ,iopt_run  ,iopt_sfc  ,iopt_frz     &
     &          ,iopt_inf ,iopt_rad  ,iopt_alb  ,iopt_snf  ,iopt_tbot ,iopt_stc     &
     &          ,iopt_gla ,iopt_rsf  ,iopt_soil ,iopt_pedo ,iopt_crop ,iopt_irr     &
     &          ,iopt_irrm,iopt_infdv,iopt_tdrn ,soiltstep                          &
     &          ,soilcomp  , soilcl1, soilcl2, soilcl3, soilcl4                     &
     &          ,isnowxy  ,tvxy      ,tgxy      ,canicexy  ,canliqxy  ,eahxy        &
     &          ,tahxy    ,cmxy      ,chxy      ,fwetxy    ,sneqvoxy  ,alboldxy     &
     &          ,qsnowxy  ,qrainxy   ,wslakexy  ,zwtxy     ,waxy, wtxy, tsnoxy      &
     &          ,zsnsoxy  ,snicexy   ,snliqxy   ,lfmassxy  ,rtmassxy  ,stmassxy     &
     &          ,woodxy   ,stblcpxy  ,fastcpxy  ,xsaixy    ,taussxy                 &
     &          ,grainxy  ,gddxy     ,cropcat   ,pgsxy                              &
     &          ,planting ,harvest   ,season_gdd                                    &
     &          ,t2mvxy   ,t2mbxy    ,q2mvxy    ,q2mbxy                             &
     &          ,tradxy   ,neexy     ,gppxy     ,nppxy     ,fvegxy    ,runsfxy      &
     &          ,runsbxy  ,ecanxy    ,edirxy    ,etranxy   ,fsaxy     ,firaxy       &
     &          ,aparxy   ,psnxy     ,savxy     ,sagxy     ,rssunxy   ,rsshaxy      &
     &          ,bgapxy   ,wgapxy    ,tgvxy     ,tgbxy     ,chvxy     ,chbxy        &    
     &          ,shgxy    ,shcxy     ,shbxy     ,evgxy     ,evbxy     ,ghvxy        &
     &          ,ghbxy    ,irgxy     ,ircxy     ,irbxy     ,trxy      ,evcxy        &
     &          ,chleafxy ,chucxy    ,chv2xy    ,chb2xy    ,chstarxy                &            
           ! Noah-MP extra output fields
     &          ,qintsxy   ,qintrxy   ,qdripsxy ,qdriprxy  ,qthrosxy  ,qthrorxy     &
     &          ,qsnsubxy  ,qsnfroxy  ,qsubcxy  ,qfrocxy   ,qevacxy   ,qdewcxy      &
     &          ,qfrzcxy   ,qmeltcxy  ,qsnbotxy ,pondingxy ,PAHXY     ,PAHGXY       &
     &          ,PAHVXY    ,PAHBXY    ,qmeltxy                                      &
     &          ,fpicexy   ,RAINLSM   ,SNOWLSM  ,forctlsm  ,forcqlsm  ,forcplsm     &
     &          ,forczlsm  ,forcwlsm  ,acc_ssoil,acc_qinsur,acc_qseva ,acc_etrani   &
     &          ,eflxbxy   ,soilenergy,snowenergy, canhsxy                          &
     &          ,ACC_DWATERXY, ACC_PRCPXY, ACC_ECANXY, ACC_ETRANXY, ACC_EDIRXY      &
           ! Noah-MP irrigation
     &          ,IRFRACT  ,SIFRACT   ,MIFRACT   ,FIFRACT   ,IRNUMSI   ,IRNUMMI      &
     &          ,IRNUMFI  ,IRWATSI   ,IRWATMI   ,IRWATFI   ,IRELOSS   ,IRSIVOL      &
     &          ,IRMIVOL  ,IRFIVOL   ,IRRSPLH                                       &
           ! Noah-MP tile drainage
     &          ,QTDRAIN  ,TD_FRACTION                                              &
           ! Noah-MP ground water
     &          ,smcwtdxy ,rechxy   ,deeprechxy,fdepthxy,areaxy   ,rivercondxy, riverbedxy &
     &          ,eqzwt    ,pexpxy   ,qrfxy    ,qspringxy,qslatxy  ,qrfsxy, qlatxy, qspringsxy &
     &          ,smoiseq  ,wtddt    ,stepwtd                                            &
                ,gecros_state                                   & ! Optional gecros crop
     &          ,opt_thcnd                                                 &
           ! Noah UA changes
     &          ,ua_phys,flx4,fvb,fbur,fgsn                                  &
#if (EM_CORE==1)
     &          ,ch,fgdp,dfgdp,vdfg,grav_settling                       & ! Katata - fog dep
#endif
     &          ,shalwater_z0,water_depth,shalwater_depth               & 
     &          ,lakedepth2d,  savedtke12d,  snowdp2d,   h2osno2d       & !lake
     &          ,snl2d,        t_grnd2d,     t_lake3d,   lake_icefrac3d & !lake
     &          ,z_lake3d,     dz_lake3d,    t_soisno3d, h2osoi_ice3d   & !lake
     &          ,h2osoi_liq3d, h2osoi_vol3d, z3d,        dz3d           & !lake
     &          ,zi3d,         watsat3d,     csol3d,     tkmg3d         & !lake
     &          ,tkdry3d,      tksatu3d,     LakeModel,  lake_min_elev     & !lake
#if (EM_CORE==1)
 !    &          ,lakemask,  lakeflag                                  & !lake
     &          ,lakemask                                  & !lake
                , restart_flag                             & ! restart_flag
#endif
            !  cyl ocean variable
                ,OM_TMP,OM_S,OM_U,OM_V,OM_DEPTH,OM_ML,OM_LON          &
     &          ,OM_LAT,okms,okme,rdx,rdy,msfu,msfv,msft              &
     &          ,XTIME,OM_TINI,OM_SINI,id,omdt                        &
! CLM variables, some only included if WRF_CHEM is compiled     BJG 3/28/19
#if ( WRF_CHEM == 1)
     &          ,e_bio,ne_area  &
#endif
                ,do_bioe,do_meganfile  &
     &          ,numc,nump,sabv,sabg,lwup,snl,history_interval &
     &          ,snowdp,wtc,wtp,h2osno,t_grnd,t_veg,         &
     &           h2ocan,h2ocan_col,t2m_max,t2m_min,t2clm ,         &
     &           t_ref2m,h2osoi_liq_s1,                 &
     &           h2osoi_liq_s2,h2osoi_liq_s3,h2osoi_liq_s4,          &
     &           h2osoi_liq_s5,h2osoi_liq1,h2osoi_liq2,              &
     &           h2osoi_liq3,h2osoi_liq4,h2osoi_liq5,h2osoi_liq6,    &
     &           h2osoi_liq7,h2osoi_liq8,h2osoi_liq9,h2osoi_liq10,   &
     &           h2osoi_ice_s1,h2osoi_ice_s2,                        &
     &           h2osoi_ice_s3,h2osoi_ice_s4,h2osoi_ice_s5,          &
     &           h2osoi_ice1,h2osoi_ice2,h2osoi_ice3,h2osoi_ice4,    &
     &           h2osoi_ice5,h2osoi_ice6,h2osoi_ice7,                &
     &           h2osoi_ice8,h2osoi_ice9,h2osoi_ice10,               &
     &           t_soisno_s1,t_soisno_s2,t_soisno_s3,t_soisno_s4,    &
     &           t_soisno_s5,t_soisno1,t_soisno2,t_soisno3,          &
     &           t_soisno4,t_soisno5,t_soisno6,t_soisno7,            &
     &           t_soisno8,t_soisno9,t_soisno10,                     &
     &           dzsnow1,dzsnow2,dzsnow3,dzsnow4,dzsnow5,            &
     &           snowrds1,snowrds2,snowrds3,snowrds4,snowrds5,       &
     &           t_lake1,t_lake2,t_lake3,t_lake4,t_lake5,            &
     &           t_lake6,t_lake7,t_lake8,t_lake9,t_lake10,           &
     &           h2osoi_vol1,h2osoi_vol2,h2osoi_vol3,                &
     &           h2osoi_vol4,h2osoi_vol5,h2osoi_vol6,                &
     &           h2osoi_vol7,h2osoi_vol8,                            &
     &           h2osoi_vol9,h2osoi_vol10,                           &
     &           maxpatch,inest,                                     &
     &           ALBEDOsubgrid,LHsubgrid,HFXsubgrid,LWUPsubgrid,     &
     &           Q2subgrid,SABVsubgrid,SABGsubgrid,NRAsubgrid,       &
     &           SWUPsubgrid,LHsoi,LHveg,LHtran                      &
!sw++
     &           ,t_veg24, t_veg240, fsun24, fsun240,                &
     &           fsd24, fsd240, fsi24, fsi240, laip                  &
!sw--
#ifdef CN
!ADD_NEW_VAR for crop and cn
     &           ,dyntlai,dyntsai,dyntop,dynbot                              &
     &           ,htmx,croplive,gdd1020,gdd820,gdd020,grainc,grainc_storage  &
     &           ,grainc_xfer,grainn,grainn_storage,grainn_xfer,days_active  &
     &           ,onset_flag,onset_counter,onset_gddflag,onset_fdd,onset_gdd &
     &           ,onset_swi,offset_flag,offset_counter,offset_fdd,offset_swi &
     &           ,dayl,annavg_t2m,tempavg_t2m,tempsum_potential_gpp          &
     &           ,annsum_potential_gpp,tempmax_retransn,annmax_retransn      &
     &           ,prev_leafc_to_litter,prev_frootc_to_litter,tempsum_npp     &
     &           ,annsum_npp,leafc,leafc_storage,leafc_xfer,frootc           &
     &           ,frootc_storage,frootc_xfer,livestemc,livestemc_storage     &
     &           ,livestemc_xfer,deadstemc,deadstemc_storage,deadstemc_xfer  &
     &           ,livecrootc,livecrootc_storage,livecrootc_xfer,deadcrootc   &
     &           ,deadcrootc_storage,deadcrootc_xfer,cpool,pft_ctrunc        &
     &           ,leafn,leafn_storage,leafn_xfer,frootn,frootn_storage       &
     &           ,frootn_xfer,livestemn,livestemn_storage,livestemn_xfer     &
     &           ,deadstemn,deadstemn_storage,deadstemn_xfer,livecrootn      &
     &           ,livecrootn_storage,livecrootn_xfer,deadcrootn              &
     &           ,deadcrootn_storage,deadcrootn_xfer,npool,pft_ntrunc        &
     &           ,gresp_storage,gresp_xfer,xsmrpool,annsum_counter           &
     &           ,cannsum_npp,cannavg_t2m,wf,me,mean_fire_prob,cwdc,litr1c   &
     &           ,litr2c,litr3c,soil1c,soil2c,soil3c,soil4c,seedc,col_ctrunc &
     &           ,prod10c,prod100c,cwdn,litr1n,litr2n,litr3n,soil1n,soil2n   &
     &           ,soil3n,soil4n,seedn,col_ntrunc,prod10n,prod100n,sminn      &
     &           ,totlitc,dwt_seedc_to_leaf,dwt_seedc_to_deadstem,dwt_conv_cflux &
     &           ,dwt_prod10c_gain,dwt_prod100c_gain,prod100c_loss,dwt_frootc_to_litr1c &
     &           ,dwt_frootc_to_litr2c,dwt_frootc_to_litr3c,dwt_livecrootc_to_cwdc &
     &           ,dwt_deadcrootc_to_cwdc,dwt_seedn_to_leaf,dwt_seedn_to_deadstem &
     &           ,dwt_conv_nflux,dwt_prod10n_gain,dwt_prod100n_gain,prod100n_loss &
     &           ,dwt_frootn_to_litr1n,dwt_frootn_to_litr2n, dwt_frootn_to_litr3n &
     &           ,dwt_livecrootn_to_cwdn,dwt_deadcrootn_to_cwdn,retransn &
#endif
!sw++
                 ,pct_pft_input,num_pft_input,input_pft_flag  &
!sw--
            !  Optional urban
     &          ,slope_rad,topo_shading,shadowmask                    & !I solar
     &          ,swnorm,slope,slp_azi,diffuse_frac                    & !I solar
     &          ,declin,solcon,coszen,hrang,xlat_urb2d                & !I solar/urban
     &          ,num_roof_layers, num_wall_layers                     & !I urban
     &          ,num_road_layers, dzr, dzb, dzg                       & !I urban
     &          ,tr_urb2d,tb_urb2d,tg_urb2d,tc_urb2d,qc_urb2d         & !H urban
     &          ,uc_urb2d                                             & !H urban
     &          ,xxxr_urb2d,xxxb_urb2d,xxxg_urb2d,xxxc_urb2d          & !H urban
     &          ,cmcr_urb2d,tgr_urb2d,tgrl_urb3d,smr_urb3d            & !H urban
     &          ,julian,julyr,drelr_urb2d,drelb_urb2d,drelg_urb2d     & !H urban
     &          ,flxhumr_urb2d,flxhumb_urb2d,flxhumg_urb2d            & !H urban
     &          ,trl_urb3d,tbl_urb3d,tgl_urb3d                        & !H urban
     &          ,sh_urb2d,lh_urb2d,g_urb2d,rn_urb2d,ts_urb2d          & !H urban
     &          ,frc_urb2d, utype_urb2d                               & !H urban
     &          ,cmr_sfcdif,chr_sfcdif,cmc_sfcdif,chc_sfcdif          &
     &          ,cmgr_sfcdif,chgr_sfcdif                              &
!-----SSiB LSM (fds 06/2010)---------------------------------------------------
     &          ,alswvisdir, alswvisdif, alswnirdir, alswnirdif       & ! ssib
     &          ,swvisdir, swvisdif, swnirdir, swnirdif               & ! ssib
     &          ,ssib_br  ,ssib_fm  ,ssib_fh  ,ssib_cm  ,ssibxdd      & ! ssib
     &          ,ssib_lhf ,ssib_shf ,ssib_ghf ,ssib_egs ,ssib_eci     & ! ssib
     &          ,ssib_ect ,ssib_egi ,ssib_egt ,ssib_sdn ,ssib_sup     & ! ssib
     &          ,ssib_ldn ,ssib_lup ,ssib_wat ,ssib_shc ,ssib_shg     & ! ssib
     &          ,ssib_lai ,ssib_vcf ,ssib_z00 ,ssib_veg               & ! ssib
     &          ,ISNOW ,SWE ,SNOWDEN ,SNOWDEPTH ,TKAIR                & ! ssib-snow
     &          ,DZO1 ,WO1 ,TSSN1 ,TSSNO1 ,BWO1 ,BTO1                 & ! ssib-snow
     &          ,CTO1 ,FIO1 ,FLO1 ,BIO1 ,BLO1 ,HO1                    & ! ssib-snow
     &          ,DZO2 ,WO2 ,TSSN2 ,TSSNO2 ,BWO2 ,BTO2                 & ! ssib-snow
     &          ,CTO2 ,FIO2 ,FLO2 ,BIO2 ,BLO2 ,HO2                    & ! ssib-snow
     &          ,DZO3 ,WO3 ,TSSN3 ,TSSNO3 ,BWO3 ,BTO3                 & ! ssib-snow
     &          ,CTO3 ,FIO3 ,FLO3 ,BIO3 ,BLO3 ,HO3                    & ! ssib-snow
     &          ,DZO4 ,WO4 ,TSSN4 ,TSSNO4 ,BWO4 ,BTO4                 & ! ssib-snow
     &          ,CTO4 ,FIO4 ,FLO4 ,BIO4 ,BLO4 ,HO4                    & ! ssib-snow
     &          ,ra_sw_physics                                        & ! ssib 
!------------------------------------------------------------------------------
     &          , ids,ide,jds,jde,kds,kde                             &
     &          , ims,ime,jms,jme,kms,kme                             &
     &          , ips,ipe,jps,jpe,kps,kpe                             &
     &          , i_start,i_end,j_start,j_end,kts,kte,num_tiles       &
             !  Optional moisture tracers
     &           ,qv_curr, qc_curr, qr_curr                           &
     &           ,qi_curr, qs_curr, qg_curr                           &
             !  Optional moisture tracer flags
     &           ,f_qv,f_qc,f_qr                                      &
     &           ,f_qi,f_qs,f_qg                                      &
             !  Other optionals (more or less em specific)
     &          ,capg,hol,mol                                         &
     &          ,rainncv,rainshv,rainbl,regime,thc,graupelncv,hailncv &
     &          ,qsg,qvg,qcg,soilt1,tsnav                             &
     &          ,smfr3d,keepfr3dflag,dew,rhosnf,precipfr              &
             !  Other optionals (more or less nmm specific)
     &          ,potevp,snopcx,soiltb,sr                              &
             !  Optional observation PX LSM surface nudging
     &          ,t2_ndg_old, q2_ndg_old, t2_ndg_new, q2_ndg_new       &
     &          ,sn_ndg_old, sn_ndg_new                               &
     &          ,t2obs, q2obs                                         &
             ! OPTIONAL, Required by TEMF surface layer 1/7/09 WA
     &          ,hd_temf,te_temf,fCor,exch_temf,wm_temf               &
             ! Required by ideal SCM surface layer 1/6/10 WA
     &          ,hfx_force,lh_force,tsk_force                         &
     &          ,hfx_force_tend,lh_force_tend,tsk_force_tend          &
             !  Optional observation nudging
     &          ,uratx,vratx,tratx                                    &
             !  Optional ocean model
     &          ,sf_ocean_physics,oml_hml0,oml_gamma                  &
     &          ,tml,t0ml,hml,h0ml,huml,hvml,f,tmoml                  &
     &          ,oml_relaxation_time                                  &
     &          ,ustm,ck,cka,cd,cda,isftcflx,iz0tlnd                  &
     &         ,isurban, mminlu                                       &
     &          ,snotime                                              &
     &           ,rdlai2d                                             &
     &          ,usemonalb                                            &
     &          ,noahres                                              &
             !  Optional adaptive time step
     &          ,bldt,curr_secs,adapt_step_flag,bldtacttime           & 
         ! Optional urban with BEP
     &          ,sf_urban_physics,gmt,xlat,xlong,julday               &
     &          ,distributed_ahe_opt, ahe                             & !For anthropogenic heat
     &          ,num_urban_ndm                                        & !multi-layer urban
     &          ,urban_map_zrd                                        & !multi-layer urban
     &          ,urban_map_zwd                                        & !multi-layer urban
     &          ,urban_map_gd                                         & !multi-layer urban
     &          ,urban_map_zd                                         & !multi-layer urban
     &          ,urban_map_zdf                                        & !multi-layer urban
     &          ,urban_map_bd                                         & !multi-layer urban
     &          ,urban_map_wd                                         & !multi-layer urban
     &          ,urban_map_gbd                                        & !multi-layer urban
     &          ,urban_map_fbd                                        & !multi-layer urban
     &          ,urban_map_zgrd                                       & !multi-layer urban
     &          ,num_urban_hi                                         & !multi-layer urban
     &          ,use_wudapt_lcz                                       & !wudapt
     &          ,slucm_distributed_drag                         & !SLUCM
     &          ,tsk_rural                                            & !multi-layer urban
     &          ,trb_urb4d,tw1_urb4d,tw2_urb4d,tgb_urb4d              & !multi-layer urban
     &          ,tlev_urb3d,qlev_urb3d                                & !multi-layer urban
     &          ,tw1lev_urb3d,tw2lev_urb3d                            & !multi-layer urban
     &          ,tglev_urb3d,tflev_urb3d                              & !multi-layer urban
     &          ,sf_ac_urb3d,lf_ac_urb3d,cm_ac_urb3d                  & !multi-layer urban
     &          ,sfvent_urb3d,lfvent_urb3d                            & !multi-layer urban 
     &          ,sfwin1_urb3d,sfwin2_urb3d                            & !multi-layer urban       
     &          ,sfw1_urb3d,sfw2_urb3d,sfr_urb3d,sfg_urb3d            & !multi-layer urban
     &          ,ep_pv_urb3d,t_pv_urb3d                              & !multi-layer urban GRZ
     &          ,trv_urb4d,qr_urb4d,qgr_urb3d,tgr_urb3d              & !multi-layer urban GRZ
     &          ,drain_urb4d,draingr_urb3d                           & !multi-layer urban GRZ
     &          ,sfrv_urb3d,lfrv_urb3d                               & !multi-layer urban GRZ
     &          ,dgr_urb3d,dg_urb3d                                   & !multi-layer urb;:an GRZ
     &          ,lfr_urb3d,lfg_urb3d                                 & !multi-layer urban GRZ
     &          ,swddir,swddif                                        & !gl
     &          ,lp_urb2d,hi_urb2d,lb_urb2d,hgt_urb2d                 & !multi-layer urban
     &          ,mh_urb2d,stdh_urb2d,lf_urb2d                         &           
     &          ,lf_urb2d_s, z0_urb2d                                 &
     &          ,a_u_bep,a_v_bep,a_t_bep,a_q_bep                      &
     &          ,b_u_bep,b_v_bep,b_t_bep,b_q_bep                      &
     &          ,sf_bep,vl_bep                                        &
     &          ,a_e_bep,b_e_bep,dlg_bep                              &
     &          ,dl_u_bep                                             &                          
     &          ,tsk_save                                             & !for fractional seaice
     &          ,cldfra                                               & !ssib
     &          ,sf_surface_mosaic,mosaic_cat,mosaic_cat_index                                    & !danli mosaic
     &          ,landusef2,TSK_mosaic,QSFC_mosaic,TSLB_mosaic,SMOIS_mosaic,SH2O_mosaic            & !danli mosaic
     &          ,CANWAT_mosaic,SNOW_mosaic,SNOWH_mosaic,SNOWC_mosaic                              & !danli mosaic
     &          ,ALBEDO_mosaic,ALBBCK_mosaic, EMISS_mosaic, EMBCK_mosaic, ZNT_mosaic, Z0_mosaic   & !danli mosaic
     &          ,HFX_mosaic,QFX_mosaic, LH_mosaic, GRDFLX_mosaic,SNOTIME_mosaic                   & !danli mosaic
     &          ,RS_mosaic,LAI_mosaic                                 &  !mosaic
     &          ,TR_URB2D_mosaic,TB_URB2D_mosaic                      &  !danli mosaic 
     &          ,TG_URB2D_mosaic,TC_URB2D_mosaic                      &  !danli mosaic 
     &          ,QC_URB2D_mosaic,UC_URB2D_mosaic                      &  !danli mosaic                  
     &          ,TRL_URB3D_mosaic,TBL_URB3D_mosaic                    &  !danli mosaic 
     &          ,TGL_URB3D_mosaic                                     &  !danli mosaic 
     &          ,SH_URB2D_mosaic,LH_URB2D_mosaic                      &  !danli mosaic 
     &          ,G_URB2D_mosaic,RN_URB2D_mosaic                       &  !danli mosaic 
     &          ,TS_URB2D_mosaic                                      &  !danli mosaic 
     &          ,TS_RUL2D_mosaic                                      &  !danli mosaic     
     &          ,ZOL                                                  &  !ckay
     &          ,SDA_HFX, SDA_QFX, HFX_BOTH, QFX_BOTH, QNORM, fasdas  &  !fasdas
     &          ,spp_lsm,pattern_spp_lsm,field_sf                     &  !SPP
     &          ,spp_pbl,pattern_spp_pbl                              &  !SPP
     &          ,XLAIDYN                                              &
  ! WRF-Solar EPS
     &          ,multi_perturb                                        & 
     &          ,pert_noah, perts_qvapor, perts_th, perts_smois       &
     &          ,perts_tsoil, pert_noah_qv, pert_noah_t               &
     &          ,pert_noah_smois, pert_noah_tslb                      &
     &          ,irrigation,sf_surf_irr_scheme, irr_daily_amount      & !IRRIG
     &          ,irr_start_hour,irr_num_hours,irr_start_julianday     &
     &          ,irr_end_julianday,irr_freq,irr_ph,irr_rand_field     &
     &                                                             )

   USE module_state_description, ONLY : SFCLAYSCHEME              &
                                       ,SFCLAYREVSCHEME           &
                                       ,MYJSFCSCHEME              &
                                       ,QNSESFCSCHEME             &
                                       ,MYJPBLSCHEME              &
                                       ,QNSEPBLSCHEME             &
                                       ,GFSSFCSCHEME              &
                                       ,PXSFCSCHEME               &
                                       ,NOAHMPSCHEME              &
                                       ,TEMFSFCSCHEME             &
                                       ,IDEALSCMSFCSCHEME         &
                                       ,SLABSCHEME                &
                                       ,LSMSCHEME                 &
                                       ,RUCLSMSCHEME              &
                                       ,PXLSMSCHEME               &
                                       ,CLMSCHEME                 &
                                       ,CTSMSCHEME                &
                                       ,SSIBSCHEME                & !ssib
                                       ,MYNNSFCSCHEME             &
                                       ,OMLSCHEME                 &
                                       ,PWP3DSCHEME               &
                                       ,DRIP                      &
                                       ,CHANNEL                   



   USE module_model_constants
   USE module_gpu_work, ONLY : work_p3_sfcdrv_u_phytmp, work_p3_sfcdrv_v_phytmp
#ifdef WRF_GPU
   USE module_gpu_work, ONLY : work_p3_sfcdrv_qgh, work_p3_sfcdrv_chs,          &
                               work_p3_sfcdrv_cqs, work_p3_sfcdrv_cpm,          &
                               work_p3_sfcdrv_chs2, work_p3_sfcdrv_cqs2,        &
                               work_p3_sfcdrv_irrigation_channel
   USE module_gpu_route, ONLY : gpu_on, gpu_island, gpu_world_host, R_SURFACE_DRIVER
   USE module_gpu_callcheck
#endif
! *** add new modules of schemes here
   USE module_irrigation
   USE module_sf_sfclay
   USE module_sf_myjsfc
   USE module_sf_qnsesfc
   USE module_sf_gfs
   USE module_sf_noahdrv                           ! danli mosaic, the " ,only : lsm " needs to be deleted 
   USE module_sf_noahlsm,   only : LCZ_1,LCZ_2,LCZ_3,LCZ_4,LCZ_5,LCZ_6,LCZ_7,LCZ_8,LCZ_9,LCZ_10,LCZ_11
   USE module_sf_noahmpdrv, only : noahmplsm, noahmp_urban
   USE module_sf_noahmp_groundwater
   USE module_sf_noah_seaice_drv
#ifdef WRF_USE_CLM
   USE module_sf_clm
#endif
#ifdef WRF_USE_CTSM
   USE module_sf_ctsm, only : ctsm_run
#endif
   USE module_sf_ssib  ! ssib
   USE module_sf_ruclsm
   USE module_sf_pxsfclay
   USE module_sf_pxlsm
   USE module_sf_temfsfclay
   USE module_sf_sfclayrev
   USE module_sf_noah_seaice_drv
#if ( EM_CORE==1)
   USE module_sf_mynn
   USE module_sf_fogdes    ! Katata - fog deposition module
   USE module_sf_ocean_driver
   USE module_sf_idealscmsfclay
#endif
   USE module_sf_scmflux       
   USE module_sf_scmskintemp

   USE module_sf_slab
!
   USE module_sf_sfcdiags
   USE module_sf_sfcdiags_ruclsm
   USE module_sf_sstskin
   USE module_sf_tmnupdate
   USE module_sf_lake
   USE module_cpl, ONLY : coupler_on, cpl_rcv
   use module_ra_gfdleta, only: cal_mon_day
!
!  This driver calls subroutines for the surface parameterizations.
!
!  surface layer: (between surface and pbl)
!      1. sfclay
!      2. myjsfc
!      7. Pleim surface layer
!      5. MYNN surface layer
!  surface: ground temp/lsm scheme:
!      1. slab
!      2. Noah LSM
!      7. Pleim-Xiu LSM
!     11. Revised sfclay (option 1) 
!
!  surface: ground temp/lsm scheme for urban:
!      2.  BEP
!
!  ocean mixed layer model
!      sf_ocean_physics = 1
!  ocean 3d PWP
!      sf_ocean_physics = 2
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
! Theta      potential temperature (K)
! Qv         water vapor mixing ratio (kg/kg)
! Qc         cloud water mixing ratio (kg/kg)
! Qr         rain water mixing ratio (kg/kg)
! Qi         cloud ice mixing ratio (kg/kg)
! Qs         snow mixing ratio (kg/kg)
!-----------------------------------------------------------------
!-- itimestep     number of time steps
!-- GLW           downward long wave flux at ground surface (W/m^2)
!-- GSW           net short wave flux at ground surface (W/m^2)
!-- SWDOWN        downward short wave flux at ground surface (W/m^2)
!-- EMISS         surface emissivity (between 0 and 1)
!-- TSK           surface temperature (K)
!-- TMN           soil temperature at lower boundary (K)
!-- TYR           annual mean surface temperature of previous year (K)
!-- TYRA          accumulated surface temperature in the current year (K)
!-- TLAG          mean surface temperature of previous 140 days (K)
!-- TDLY          accumulated daily mean surface temperature of the current day (K)
!-- XLAND         land mask (1 for land, 2 for water)
!-- MAX_EDOM      number of external model domains
!-- CPLMASK       coupling mask (0 for data read in wrflowinput, 1 data received from the coupler)
!-- ZNT           thermal time-varying roughness length (m)
!-- MZNT          momentum time-varying roughness length (m)
!-- Z0            background roughness length (m)
!-- MAVAIL        surface moisture availability (between 0 and 1)
!-- UST           u* in similarity theory (m/s)
!-- MOL           T* (similarity theory) (K)
!-- HOL           PBL height over Monin-Obukhov length
!-- PBLH          PBL height (m)
!-- CAPG          heat capacity for soil (J/K/m^3)
!-- THC           thermal inertia (Cal/cm/K/s^0.5)
!-- SNOWC         flag indicating snow coverage (1 for snow cover)
!-- HFX           net upward heat flux at the surface (W/m^2)
!-- QFX           net upward moisture flux at the surface (kg/m^2/s)
!-- TAUX          RHO*U**2 for ocean coupling
!-- TAUY          RHO*U**2 for ocean coupling
!-- LH            net upward latent heat flux at surface (W/m^2)
!-- REGIME        flag indicating PBL regime (stable, unstable, etc.)
!-- tke_pbl       turbulence kinetic energy from PBL schemes (m^2/s^2)
!-- akhs          sfc exchange coefficient of heat/moisture from MYJ
!-- akms          sfc exchange coefficient of momentum from MYJ
!-- thz0          potential temperature at roughness length (K)
!-- uz0           u wind component at roughness length (m/s)
!-- vz0           v wind component at roughness length (m/s)
!-- qsfc          specific humidity at lower boundary (kg/kg)
!-- uratx         ratio of u over u10 (Added for obs-nudging)
!-- vratx         ratio of v over v10 (Added for obs-nudging)
!-- tratx         ratio of t over th2 (Added for obs-nudging)
!-- u10           diagnostic 10-m u component from surface layer
!-- v10           diagnostic 10-m v component from surface layer
!-- UOCE          sea surface zonal currents (m s-1)
!-- VOCE          sea surface meridional currents (m s-1)
!-- th2           diagnostic 2-m theta from surface layer and lsm
!-- t2            diagnostic 2-m temperature from surface layer and lsm
!-- q2            diagnostic 2-m mixing ratio from surface layer and lsm
!-- tshltr        diagnostic 2-m theta from MYJ
!-- th10          diagnostic 10-m theta from MYJ
!-- qshltr        diagnostic 2-m specific humidity from MYJ
!-- q10           diagnostic 10-m specific humidity from MYJ
!-- lowlyr        index of lowest model layer above ground
!-- rr            dry air density (kg/m^3)
!-- u_phy         u-velocity interpolated to theta points (m/s)
!-- v_phy         v-velocity interpolated to theta points (m/s)
!-- th_phy        potential temperature (K)
!-- moist         moisture array (4D - last index is species) (kg/kg)
!-- p_phy         pressure (Pa)
!-- pi_phy        exner function (dimensionless)
!-- pshltr        diagnostic shelter (2m) pressure from MYJ (Pa)
!-- p8w           pressure at full levels (Pa)
!-- t_phy         temperature (K)
!-- dz8w          dz between full levels (m)
!-- z             height above sea level (m)
!-- DX            nominal horizontal space interval (m)
!-- DX2D          horizontal space interval (m), sqrt(dx/mftx * dy/mfty)
!-- AREA2D        horizontal cell area (m^2), (dx/mftx * dy/mfty)
!-- DT            time step (second)
!-- PSFC          pressure at the surface (Pa)
!-- SST           sea-surface temperature (K)
!-- SST_INPUT     sea-surface temperature read in wrflowinput (K) (= SST if no coupling)
!-- SSTSK         skin sea-surface temperature (K)
!-- DTW           warm layer temp diff (K)
!-- TSLB
!-- ZS
!-- DZS
!-- num_soil_layers number of soil layer
!-- IFSNOW      ifsnow=1 for snow-cover effects
!-- sf_ocean_physics       whether to call ocean model from slab (1 = oml, 2=3d PWP)
!-- oml_hml0      initial mixed layer depth (if real-data not available, default 50 m)
!-- oml_gamma     lapse rate below mixed layer in ocean (default 0.14 K m-1)
!-- oml_relaxation_time   time the oml will take to get back to its original state (seconds)
!-- ck            enthalpy exchange coeff at 10 meters
!-- cd            momentum exchange coeff at 10 meters
!-- cka           enthalpy exchange coeff at the lowest model level
!-- cda           momentum exchange coeff at the lowest model level
!!!!!!!!!!!!!!
!
!
!-- LANDUSEF     Landuse fraction                      ! P-X LSM
!-- SOILCTOP     Top soil fraction                     ! P-X LSM
!-- SOILCBOT     Bottom soil fraction                  ! P-X LSM
!-- RA           Aerodynamic resistence                ! P-X LSM
!-- RS           Stomatal resistence                   ! P-X LSM, also from Noah lsm, lsm_mosaic, or noahmp
!-- VEGF_PX      PX LSM internal LU-based Veg Fraction ! P-X LSM
!-- IMPERV       Impervious surface fraction           ! P-X LSM
!-- CANFRA       Canopy/Tree fraction                  ! P-X LSM
!-- NLCAT        Number of landuse categories          ! P-X LSM
!-- NSCAT        Number of soil categories             ! P-X LSM
!-- pxlsm_modis_veg   Flag for using MODIS vegeation LAI and vegF (1 is yes)    ! P-X LSM
!-- LAI_PX            Computed LAI for PX (m^2/m^2)                             ! P-X LSM
!-- WWLT_PX           Computed soil wilting point for PX (m^3/m^3)              ! P-X LSM
!-- WFC_PX            Computed soil field capacity for PX (m^3/m^3)             ! P-X LSM
!-- WSAT_PX           Computed soil saturation for PX (m^3/m^3)                 ! P-X LSM
!-- CLAY_PX           Aggregated soil clay fraction for PX (%)                  ! P-X LSM
!-- CSAND_PX          Aggregated soil coarse sand fraction for PX (%)           ! P-X LSM
!-- FMSAND_PX         Aggregated soil fine-medium sand fraction for PX (%)      ! P-X LSM
!-- ch - drag coefficient for heat/moisture            ! MYNN LSM

!
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
!-- ips           start index for i in patch
!-- ipe           end index for i in patch
!-- jps           start index for j in patch
!-- jpe           end index for j in patch
!-- kps           start index for k in patch
!-- kpe           end index for k in patch
!-- its           start index for i in tile
!-- ite           end index for i in tile
!-- jts           start index for j in tile
!-- jte           end index for j in tile
!-- kts           start index for k in tile
!-- kte           end index for k in tile
!
!******************************************************************
!------------------------------------------------------------------

   INTEGER, INTENT(IN) ::                                             &
     &           ids,ide,jds,jde,kds,kde                              &
     &          ,ims,ime,jms,jme,kms,kme                              &
     &          ,ips,ipe,jps,jpe,kps,kpe                              &
     &          ,kts,kte,num_tiles

   INTEGER, INTENT(IN)::   FRACTIONAL_SEAICE
   INTEGER, INTENT(IN)::   SEAICE_ALBEDO_OPT
   REAL,    INTENT(IN)::   SEAICE_ALBEDO_DEFAULT
   INTEGER, INTENT(IN)::   SEAICE_THICKNESS_OPT
   REAL,    INTENT(IN)::   SEAICE_THICKNESS_DEFAULT
   INTEGER, INTENT(IN)::   SEAICE_SNOWDEPTH_OPT
   REAL,    INTENT(IN)::   SEAICE_SNOWDEPTH_MAX
   REAL,    INTENT(IN)::   SEAICE_SNOWDEPTH_MIN
   INTEGER, INTENT(IN)::   IFNDALBSI
   INTEGER, INTENT(IN)::   IFNDICEDEPTH
   INTEGER, INTENT(IN)::   IFNDSNOWSI
   LOGICAL, INTENT(IN)::   do_bioe
   LOGICAL, INTENT(IN)::   do_meganfile

   INTEGER, INTENT(IN)::   NLCAT, mosaic_lu, mosaic_soil
   INTEGER, INTENT(IN)::   NSCAT
   INTEGER,  INTENT(IN )  :: LakeModel
   REAL,     INTENT(IN)   :: lake_min_elev

   INTEGER, INTENT(IN)::   history_interval

   INTEGER, INTENT(IN) :: sf_sfclay_physics, sf_surface_physics,      &
                          sf_urban_physics,ra_lw_physics,sst_update,  &
                          ra_sw_physics, bl_pbl_physics
   INTEGER, INTENT(IN),OPTIONAL :: sst_skin, tmn_update,              &
                                   scm_force_skintemp, scm_force_flux 

   INTEGER, DIMENSION(num_tiles), INTENT(IN) ::                       &
     &           i_start,i_end,j_start,j_end

   INTEGER, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT )::  ISLTYP
   INTEGER, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   IVGTYP
   INTEGER, DIMENSION( ims:ime , jms:jme ), INTENT(IN )::   LOWLYR
   INTEGER, INTENT(IN )::   IFSNOW
   INTEGER, INTENT(IN )::   ISFFLX
   INTEGER, INTENT(IN )::   ITIMESTEP
   INTEGER, INTENT(IN )::   NUM_SOIL_LAYERS
   REAL,    INTENT(IN ),OPTIONAL ::   JULIAN_in
   INTEGER, INTENT(IN )::   LAGDAY
   INTEGER, INTENT(IN )::   STEPBL
   INTEGER, INTENT(IN )::   ISICE
   INTEGER, INTENT(IN )::   ISWATER
   INTEGER, INTENT(IN ), OPTIONAL :: ISURBAN
   CHARACTER(LEN=*), INTENT(IN ), OPTIONAL :: MMINLU
   LOGICAL, INTENT(IN )::   WARM_RAIN
   LOGICAL, INTENT(IN)::   tice2tsk_if2cold
   INTEGER, INTENT(INOUT ),OPTIONAL ::   NYEAR
   REAL   , INTENT(INOUT ),OPTIONAL ::   NDAY
   INTEGER, INTENT(IN ),OPTIONAL ::   YR
   REAL , INTENT(IN )::   U_FRAME
   REAL , INTENT(IN )::   V_FRAME

     ! WRF-Solar EPS
   integer, intent(in) :: multi_perturb 
   logical, intent(in) :: pert_noah
   real, intent(in):: pert_noah_qv,pert_noah_t, pert_noah_smois,pert_noah_tslb
   real, dimension (ims:ime, kms:kme, jms:jme) ,intent(inout), optional :: perts_qvapor, perts_th, &
       perts_smois, perts_tsoil

  !added by Wei Yu for WRF_HYDRO 
   real ::  HYDRO_dt
   REAL, DIMENSION( ims:ime , jms:jme ):: sfcheadrt,INFXSRT, soldrain
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT):: qtiledrain,ZWATBLE2D  ! NoahMP tile drainage

   REAL, DIMENSION( ims:ime , 1:num_soil_layers, jms:jme ), INTENT(INOUT)::   SMOIS
   REAL, DIMENSION( ims:ime , 1:num_soil_layers, jms:jme ), INTENT(INOUT)::   TSLB
   REAL, DIMENSION( ims:ime , 1:num_soil_layers, jms:jme ), INTENT(OUT)  ::   SMCREL
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN )::   GLW
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   GSW,SWDOWN
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN )::   HT
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN )::   RAINCV
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   SST
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT ),OPTIONAL ::   SSTSK
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN    ),OPTIONAL ::   SST_INPUT
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT ),OPTIONAL ::   DTW
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   TMN
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT ),OPTIONAL ::   TYR
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT ),OPTIONAL ::   TYRA
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT ),OPTIONAL ::   TDLY
   REAL, DIMENSION( ims:ime , 1:lagday , jms:jme ), INTENT(INOUT ),OPTIONAL ::   TLAG
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   VEGFRA
!------fds (06/2010)--------------------------
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   XICE
!---------------------------------------------
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   ALBSI
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   ICEDEPTH
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   SNOWSI
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   XLAND
   INTEGER,                                          INTENT(IN   ) ::   MAX_EDOM
   REAL, DIMENSION( ims:ime , 1:max_edom, jms:jme ), INTENT(IN   ), OPTIONAL ::   CPLMASK
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   XICEM
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   MAVAIL
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT)::   SNOALB
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   ACSNOW
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   SNOTIME
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   AKHS
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   AKMS
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   ALBEDO
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   CANWAT

   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   GRDFLX
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   HFX
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   RMOL
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   PBLH
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   Q2
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   QFX
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   QSFC
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   QZ0
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   SFCRUNOFF
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   ACRUNOFF
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   SMSTAV
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   SMSTOT
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   SNOW
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   SNOWC
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   SNOWH
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   TH2
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   THZ0
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   TSK
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   UDRUNOFF
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   UST
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   UZ0
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   VZ0
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   WSPD
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)::   ZNT
!-----fds (06/2010)---------------------------------------------
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_LHF ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_SHF ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_GHF ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_EGS ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_ECI ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_ECT ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_EGI ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_EGT ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_SDN ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_SUP ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_LDN ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_LUP ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_WAT ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_SHC ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_SHG ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_LAI ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_VCF ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_Z00 ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   SSIB_VEG ! SSiB output
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   ALSWVISDIR! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   ALSWVISDIF! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   ALSWNIRDIR! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(OUT)::   ALSWNIRDIF! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(IN)::      SWVISDIR! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(IN)::      SWVISDIF! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(IN)::      SWNIRDIR! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(IN)::      SWNIRDIF! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   SSiB_BR ! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   SSiB_FM ! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   SSiB_FH ! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   SSiB_CM ! SSiB
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   SSiBXDD ! SSiB
   INTEGER, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT):: ISNOW  ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   SWE     ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   SNOWDEN ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT):: SNOWDEPTH ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   TKAIR   ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   DZO1    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   WO1     ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   TSSN1   ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   TSSNO1  ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BWO1    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BTO1    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   CTO1    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   FIO1    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   FLO1    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BIO1    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BLO1    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   HO1     ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   DZO2    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   WO2     ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   TSSN2   ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   TSSNO2  ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BWO2    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BTO2    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   CTO2    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   FIO2    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   FLO2    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BIO2    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BLO2    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   HO2     ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   DZO3    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   WO3     ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   TSSN3   ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   TSSNO3  ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BWO3    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BTO3    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   CTO3    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   FIO3    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   FLO3    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BIO3    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BLO3    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   HO3     ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   DZO4    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   WO4     ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   TSSN4   ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   TSSNO4  ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BWO4    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BTO4    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   CTO4    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   FIO4    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   FLO4    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BIO4    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   BLO4    ! ssib-snow
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT)::   HO4     ! ssib-snow
!----------------------------------------------------------
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   BR
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   CHKLOWQ
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   GZ1OZ0
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   PSHLTR
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   FHH
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   FM
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   PSIH
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   PSIM
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   Q10
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   QSHLTR
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   TH10
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   TSHLTR
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   U10
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   V10
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   U10E
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   V10E
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   UOCE
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   VOCE
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(OUT)::   PSFC
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT)::   ACSNOM
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT)::   SFCEVP
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT),OPTIONAL ::   ACHFX
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT),OPTIONAL ::   ACLHF
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT),OPTIONAL ::   ACGRDFLX
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT)::   SFCEXC
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT)::   FLHC
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT)::   FLQC
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) ::   CT
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(IN )::   DZ8W
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(IN )::   P8W
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(IN )::   PI_PHY
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(IN )::   P_PHY
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(IN )::   RHO
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(IN )::   TH_PHY
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT)::   T_PHY
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(IN )::   U_PHY
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(IN )::   V_PHY
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(IN )::   Z

   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::   TKE_PBL

   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ),INTENT(INOUT),OPTIONAL ::   pattern_spp_lsm,field_sf
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ),INTENT(INOUT),OPTIONAL ::   pattern_spp_pbl
   INTEGER, INTENT(IN), OPTIONAL                 ::     spp_lsm,spp_pbl

   REAL, DIMENSION(1:num_soil_layers), INTENT(IN)::   DZS
   REAL, DIMENSION(1:num_soil_layers), INTENT(IN)::   ZS
   REAL, INTENT(IN )::   DT
   REAL, INTENT(IN )::   DX
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN ), OPTIONAL :: DX2D, AREA2D
   REAL,       INTENT(IN   ),OPTIONAL    ::     bldt
   REAL,       INTENT(IN   ),OPTIONAL    ::     curr_secs
   LOGICAL,    INTENT(IN   ),OPTIONAL    ::     adapt_step_flag
   REAL,       INTENT(INOUT),OPTIONAL    ::     bldtacttime  

!  arguments for NCAR surface physics

   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT )::   ALBBCK  ! INOUT needed for NMM
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT )::   EMBCK
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT )::   LH
   REAL, DIMENSION( ims:ime , 1:num_soil_layers, jms:jme ), INTENT(INOUT)::   SH2O
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN )::   SHDMAX
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN )::   SHDMIN
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN )::   SHDAVG
   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT )::   Z0

!  NoahMP specific fields

   INTEGER, OPTIONAL, INTENT(IN) ::    idveg, iopt_crs, iopt_btr, iopt_run, iopt_sfc , iopt_frz, &
                                    iopt_inf, iopt_rad, iopt_alb, iopt_snf, iopt_tbot, iopt_stc, &
				    iopt_gla, iopt_rsf, iopt_soil,iopt_pedo,iopt_crop, iopt_irr, &
                                    iopt_irrm,iopt_infdv,iopt_tdrn
   REAL,    OPTIONAL, INTENT(IN) :: soiltstep  ! NoahMP soil timestep (s)
   REAL,    OPTIONAL, DIMENSION(ims:ime ,8, jms:jme), INTENT(IN) :: SOILCOMP
   REAL,    OPTIONAL, DIMENSION(ims:ime , jms:jme)  , INTENT(IN) :: SOILCL1,SOILCL2,SOILCL3,SOILCL4

   INTEGER, OPTIONAL, DIMENSION(ims:ime , jms:jme),                    INTENT(INOUT) :: ISNOWXY,   PGSXY
   REAL,    OPTIONAL, DIMENSION(ims:ime ,-2:num_soil_layers, jms:jme), INTENT(INOUT) :: ZSNSOXY
   REAL,    OPTIONAL, DIMENSION(ims:ime ,-2:0,               jms:jme), INTENT(INOUT) :: TSNOXY, SNICEXY, SNLIQXY
   REAL,    OPTIONAL, DIMENSION(ims:ime , jms:jme),                    INTENT(INOUT) ::                    &
           TVXY,    TGXY,CANICEXY,CANLIQXY,   EAHXY,   TAHXY,    CMXY,    CHXY,  FWETXY,SNEQVOXY,ALBOLDXY, &
        QSNOWXY, QRAINXY, WSLAKEXY, ZWTXY, WAXY,WTXY,LFMASSXY,RTMASSXY,STMASSXY, WOODXY,STBLCPXY,FASTCPXY, &
	GRAINXY,   GDDXY,                                                                                  &
	 XSAIXY, TAUSSXY,  T2MVXY,  T2MBXY,  Q2MVXY,  Q2MBXY,  TRADXY,   NEEXY,   GPPXY,                   &
          NPPXY,  FVEGXY, RUNSFXY, RUNSBXY,  ECANXY,  EDIRXY, ETRANXY,   FSAXY,  FIRAXY,  APARXY,   PSNXY, &
	  SAVXY,   SAGXY, RSSUNXY, RSSHAXY,  BGAPXY,  WGAPXY,   TGVXY,   TGBXY,   CHVXY,   CHBXY,   SHGXY, &
	  SHCXY,   SHBXY,   EVGXY,   EVBXY,   GHVXY,   GHBXY,   IRGXY,   IRCXY,   IRBXY,    TRXY,   EVCXY, &
       CHLEAFXY,  CHUCXY,  CHV2XY,  CHB2XY,CHSTARXY                         
   REAL, OPTIONAL, DIMENSION(ims:ime , jms:jme)                   , INTENT(INOUT) :: acc_ssoil,acc_qinsur,acc_qseva
   REAL, OPTIONAL, DIMENSION(ims:ime , jms:jme)                   , INTENT(INOUT) :: ACC_DWATERXY, ACC_PRCPXY, &
                                                                                     ACC_ECANXY, ACC_ETRANXY, ACC_EDIRXY
   REAL, OPTIONAL, DIMENSION(ims:ime , jms:jme)                   , INTENT(  OUT) :: eflxbxy,soilenergy, snowenergy
   REAL, OPTIONAL, DIMENSION(ims:ime , 1:num_soil_layers, jms:jme), INTENT(INOUT) :: acc_etrani
   REAL, OPTIONAL, DIMENSION(ims:ime , jms:jme), INTENT(INOUT) ::    &
               qintsxy   ,qintrxy   ,qdripsxy   ,&
               qdriprxy  ,qthrosxy  ,qthrorxy   ,&
               qsnsubxy  ,qsnfroxy  ,qsubcxy    ,&
               qfrocxy   ,qevacxy   ,qdewcxy,qfrzcxy   ,qmeltcxy   ,&
               qsnbotxy  ,qmeltxy   ,pondingxy, PAHXY      ,PAHGXY, PAHVXY, PAHBXY,&
               fpicexy,RAINLSM,SNOWLSM,forctlsm,forcqlsm,forcplsm,forczlsm,forcwlsm,canhsxy
   INTEGER,    OPTIONAL, DIMENSION(ims:ime , jms:jme), INTENT(IN) :: CROPCAT
   REAL,    OPTIONAL, DIMENSION(ims:ime , jms:jme), INTENT(IN) :: PLANTING
   REAL,    OPTIONAL, DIMENSION(ims:ime , jms:jme), INTENT(IN) :: HARVEST
   REAL,    OPTIONAL, DIMENSION(ims:ime , jms:jme), INTENT(IN) :: SEASON_GDD

!  NoahMP irrigation
   REAL,    OPTIONAL, DIMENSION(ims:ime , jms:jme), INTENT(IN)    :: IRFRACT, SIFRACT, MIFRACT, FIFRACT
   REAL,    OPTIONAL, DIMENSION(ims:ime , jms:jme), INTENT(INOUT) :: IRWATSI, IRWATMI, IRWATFI, IRELOSS, &
                                                                     IRSIVOL, IRMIVOL, IRFIVOL, IRRSPLH
   INTEGER,    OPTIONAL, DIMENSION(ims:ime , jms:jme), INTENT(INOUT) :: IRNUMSI, IRNUMMI, IRNUMFI
! NoahMP tiledrainage
   REAL,    OPTIONAL, DIMENSION(ims:ime , jms:jme), INTENT(IN)    :: TD_FRACTION
   REAL,    OPTIONAL, DIMENSION(ims:ime , jms:jme), INTENT(INOUT) :: QTDRAIN

!  NoahMP specific fields - runoff option 5

   INTEGER, OPTIONAL, INTENT(IN)      :: stepwtd
   REAL,    OPTIONAL, INTENT(IN)      :: wtddt
   REAL,    OPTIONAL, DIMENSION(ims:ime , 1:num_soil_layers, jms:jme ), INTENT(INOUT)::  smoiseq
   REAL,    OPTIONAL, DIMENSION(ims:ime , jms:jme),                    INTENT(INOUT) ::  &
    SMCWTDXY,   RECHXY, DEEPRECHXY, FDEPTHXY,  AREAXY,  RIVERCONDXY, RIVERBEDXY,  &
    EQZWT,      PEXPXY, QRFXY,      QSPRINGXY, QSLATXY, QRFSXY, QSPRINGSXY, QLATXY                        

   REAL,    OPTIONAL, DIMENSION(ims:ime,60,jms:jme) :: gecros_state                  ! Optional gecros crop

   INTEGER, INTENT(IN )::   OPT_THCND
! Noah UA changes
   LOGICAL, INTENT(IN) :: ua_phys
   REAL, DIMENSION(ims:ime , jms:jme), INTENT(OUT) ::  flx4,fvb,fbur,fgsn

! Variables for multi-layer UCM
   REAL, OPTIONAL, INTENT(IN  )   ::                                   GMT 
   INTEGER, OPTIONAL, INTENT(IN  ) ::                               JULDAY
   INTEGER, INTENT(IN) :: distributed_ahe_opt
   REAL, OPTIONAL, DIMENSION( ims:ime, 0:287, jms:jme ), INTENT(IN)  :: ahe
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN   )        ::XLAT, XLONG
   INTEGER , INTENT(IN)        ::     num_urban_ndm
   INTEGER , INTENT(IN)        ::     urban_map_zrd
   INTEGER , INTENT(IN)        ::     urban_map_zwd
   INTEGER , INTENT(IN)        ::     urban_map_gd
   INTEGER , INTENT(IN)        ::     urban_map_zd
   INTEGER , INTENT(IN)        ::     urban_map_zdf
   INTEGER , INTENT(IN)        ::     urban_map_bd
   INTEGER , INTENT(IN)        ::     urban_map_wd
   INTEGER , INTENT(IN)        ::     urban_map_gbd
   INTEGER , INTENT(IN)        ::     urban_map_fbd
   INTEGER , INTENT(IN)        ::     urban_map_zgrd
   INTEGER, INTENT(IN )::   NUM_URBAN_HI
   INTEGER, INTENT(IN )::   use_wudapt_lcz
   LOGICAL, INTENT(IN )::   slucm_distributed_drag
   REAL, OPTIONAL, DIMENSION( ims:ime,                     jms:jme ), INTENT(INOUT) :: tsk_rural
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zrd, jms:jme ), INTENT(INOUT) :: trb_urb4d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zwd, jms:jme ), INTENT(INOUT) :: tw1_urb4d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zwd, jms:jme ), INTENT(INOUT) :: tw2_urb4d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_gd,  jms:jme ), INTENT(INOUT) :: tgb_urb4d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_bd,  jms:jme ), INTENT(INOUT) :: tlev_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_bd,  jms:jme ), INTENT(INOUT) :: qlev_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_wd,  jms:jme ), INTENT(INOUT) :: tw1lev_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_wd,  jms:jme ), INTENT(INOUT) :: tw2lev_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_gbd, jms:jme ), INTENT(INOUT) :: tglev_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_fbd, jms:jme ), INTENT(INOUT) :: tflev_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: lf_ac_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: sf_ac_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: cm_ac_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: sfvent_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: lfvent_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN ):: SWDDIR,SWDDIF
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_wd,  jms:jme ), INTENT(INOUT) :: sfwin1_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_wd,  jms:jme ), INTENT(INOUT) :: sfwin2_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zd,  jms:jme ), INTENT(INOUT) :: sfw1_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zd,  jms:jme ), INTENT(INOUT) :: sfw2_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zdf, jms:jme ), INTENT(INOUT) :: sfr_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:num_urban_ndm, jms:jme ), INTENT(INOUT) :: sfg_urb3d
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: ep_pv_urb3d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zdf, jms:jme ), INTENT(INOUT) :: t_pv_urb3d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zgrd, jms:jme ),INTENT(INOUT) :: trv_urb4d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zgrd, jms:jme ),INTENT(INOUT) :: qr_urb4d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime,jms:jme ), INTENT(INOUT) :: qgr_urb3d  !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime,jms:jme ), INTENT(INOUT) :: tgr_urb3d  !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zdf, jms:jme ),INTENT(INOUT) :: drain_urb4d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: draingr_urb3d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zdf, jms:jme ),INTENT(INOUT) :: sfrv_urb3d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zdf, jms:jme ),INTENT(INOUT) :: lfrv_urb3d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zdf, jms:jme ),INTENT(INOUT) :: dgr_urb3d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:num_urban_ndm, jms:jme ),INTENT(INOUT) :: dg_urb3d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:urban_map_zdf, jms:jme ),INTENT(INOUT) :: lfr_urb3d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:num_urban_ndm, jms:jme ),INTENT(INOUT) :: lfg_urb3d !GRZ
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:num_urban_hi, jms:jme ), INTENT(IN)  :: hi_urb2d  !urban
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN)  :: lp_urb2d  !urban
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN)  :: lb_urb2d  !urban
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN)  :: hgt_urb2d !urban
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN)  :: mh_urb2d  !urban
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN)  :: stdh_urb2d!urban
   REAL, OPTIONAL, DIMENSION( ims:ime, 4, jms:jme ), INTENT(IN)  :: lf_urb2d  !urban
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN)  :: lf_urb2d_s !urban
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN)  :: z0_urb2d !urban
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::a_u_bep   !Implicit momemtum component X-direction
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::a_v_bep   !Implicit momemtum component Y-direction
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::a_t_bep   !Implicit component pot. temperature
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::a_e_bep   !Implicit component TKE
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::a_q_bep   !Implicit component TKE
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::b_u_bep   !Explicit momentum component X-direction
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::b_v_bep   !Explicit momentum component Y-direction
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::b_t_bep   !Explicit component pot. temperature
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::b_e_bep   !Explicit component TKE
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::b_q_bep   !Explicit component TKE
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::vl_bep    !Fraction air volume in grid cell
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::dlg_bep   !Height above ground
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::sf_bep  !Fraction air at the face of grid cell
   REAL, OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::dl_u_bep  !Length scale

!  arguments for Ocean Mixed Layer Model
   REAL, DIMENSION( ims:ime , jms:jme ), OPTIONAL, INTENT(INOUT )::   TML, T0ML, HML, H0ML, HUML, HVML
   REAL, DIMENSION( ims:ime , jms:jme ), OPTIONAL, INTENT(IN    )::   F, TMOML
   REAL, DIMENSION( ims:ime , jms:jme ), OPTIONAL, INTENT(OUT   )::   CK, CKA, CD, CDA
   REAL, DIMENSION( ims:ime , jms:jme ), OPTIONAL, INTENT(INOUT )::   USTM

   REAL, DIMENSION( ims:ime , jms:jme ), OPTIONAL, INTENT(INOUT )::   TSK_SAVE

#if ( EM_CORE==1)
   REAL, DIMENSION( ims:ime , jms:jme ), &
        &OPTIONAL, INTENT(INOUT   ):: ch

!Katata-added - extra in-output
   REAL, DIMENSION( ims:ime , jms:jme ), OPTIONAL, INTENT(INOUT):: fgdp,dfgdp,vdfg
   INTEGER, OPTIONAL, INTENT(IN)                                :: grav_settling
!Katata-end

#endif


   INTEGER, OPTIONAL, INTENT(IN )::   slope_rad, topo_shading
   INTEGER, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(IN):: shadowmask
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT):: swnorm
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(IN):: slope,slp_azi
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(IN):: diffuse_frac

   INTEGER, OPTIONAL, INTENT(IN )::   ISFTCFLX,IZ0TLND
   INTEGER, OPTIONAL, INTENT(IN )::   SF_OCEAN_PHYSICS
   REAL   , OPTIONAL, INTENT(IN )::   OML_HML0
   REAL   , OPTIONAL, INTENT(IN )::   OML_GAMMA
   REAL   , OPTIONAL, INTENT(IN )::   OML_RELAXATION_TIME
!
!  Observation nudging
!
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(OUT)::   uratx  !Added for obs-nudging
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(OUT)::   vratx  !Added for obs-nudging
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(OUT)::   tratx  !Added for obs-nudging
!
!  PX LSM Surface Grid Analysis nudging
!
   INTEGER, OPTIONAL, INTENT(IN)    :: pxlsm_smois_init, pxlsm_soil_nudge,  &
                                       ANAL_INTERVAL, pxlsm_modis_veg

   REAL, DIMENSION( ims:ime, NLCAT, jms:jme ) , OPTIONAL, INTENT(INOUT)::   LANDUSEF
   REAL, DIMENSION( ims:ime, NSCAT, jms:jme ) , OPTIONAL, INTENT(INOUT)::   SOILCTOP, SOILCBOT
   REAL, DIMENSION( ims:ime , jms:jme ), OPTIONAL, INTENT(INOUT):: IMPERV, CANFRA
   REAL, DIMENSION( ims:ime , jms:jme ), OPTIONAL, INTENT(INOUT):: VEGF_PX
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT):: RA
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT):: RS
   REAL, DIMENSION( ims:ime, jms:jme ) , OPTIONAL, INTENT(INOUT):: LAI
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(OUT)::   T2OBS,  Q2OBS, LAI_PX
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(OUT)::  WWLT_PX, WFC_PX, WSAT_PX,    & 
                                                                 CLAY_PX, CSAND_PX, FMSAND_PX                                       

   REAL,       DIMENSION( ims:ime,  jms:jme ),                                     &
               OPTIONAL, INTENT(INOUT)    ::  t2_ndg_old, t2_ndg_new, q2_ndg_old,  &
                                              q2_ndg_new, sn_ndg_old, sn_ndg_new 

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
                                                     ,f_qg

   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ),                 &
         OPTIONAL, INTENT(INOUT) ::                              &
                      ! optional moisture tracers
                      ! 2 time levels; if only one then use CURR
                      qv_curr, qc_curr, qr_curr                  &
                     ,qi_curr, qs_curr, qg_curr
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(IN)   ::   snowncv
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(IN)   ::   graupelncv
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(IN)   ::   hailncv
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   capg
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   emiss
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   hol
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   mol
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   regime
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(IN )::     rainncv
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(IN )::     rainshv
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   RAINBL
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   t2
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(IN )::     thc
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   qsg
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   qvg
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   qcg
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   dew
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   soilt1
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   tsnav
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   potevp ! NMM LSM
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   snopcx ! NMM LSM
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   soiltb ! NMM LSM
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   sr ! NMM and RUC LSM
   REAL, DIMENSION( ims:ime, 1:num_soil_layers, jms:jme ), OPTIONAL, INTENT(INOUT)::   smfr3d
   REAL, DIMENSION( ims:ime, 1:num_soil_layers, jms:jme ), OPTIONAL, INTENT(INOUT)::   keepfr3dflag
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   rhosnf !  density of snowfall
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(OUT) ::    precipfr ! time-step frozen precip from RUC LSM
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT)::   snowfallac !  density of snowfall

   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(OUT), OPTIONAL  ::   NOAHRES
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT)          ::   ZOL

   INTEGER, INTENT(IN) :: MAXPATCH, inest
#if ( WRF_CHEM == 1 )
   INTEGER, INTENT(IN) :: ne_area
#endif
!   End modification

  integer, optional,  dimension(ims:ime,jms:jme ),intent(inout) :: numc,nump
  real,    optional,  dimension(ims:ime,jms:jme ),intent(inout) :: sabv,sabg,lwup
  integer, optional,  dimension(ims:ime,1:maxpatch,jms:jme ),intent(inout) :: snl
  real,    optional,  dimension(ims:ime,jms:jme ),intent(inout) ::t2m_max,t2m_min,t2clm
  INTEGER, INTENT(IN)         :: num_pft_input
  LOGICAL,OPTIONAL,INTENT(IN) :: input_pft_flag
  REAL, DIMENSION(ims:ime, num_pft_input,jms:jme ),OPTIONAL, INTENT(IN) ::  pct_pft_input
  real,    optional,  dimension(ims:ime,1:maxpatch,jms:jme ),intent(inout) ::  &
                snowdp,wtc,wtp,h2osno,t_grnd,t_veg,         &
                h2ocan,h2ocan_col,   &
                t_ref2m,h2osoi_liq_s1,              &
                h2osoi_liq_s2,h2osoi_liq_s3,h2osoi_liq_s4,          &
                h2osoi_liq_s5,h2osoi_liq1,h2osoi_liq2,              &
                h2osoi_liq3,h2osoi_liq4,h2osoi_liq5,h2osoi_liq6,    &
                h2osoi_liq7,h2osoi_liq8,h2osoi_liq9,h2osoi_liq10,   &
                h2osoi_ice_s1,h2osoi_ice_s2,                        &
                h2osoi_ice_s3,h2osoi_ice_s4,h2osoi_ice_s5,          &
                h2osoi_ice1,h2osoi_ice2,h2osoi_ice3,h2osoi_ice4,    &
                h2osoi_ice5,h2osoi_ice6,h2osoi_ice7,                &
                h2osoi_ice8,h2osoi_ice9,h2osoi_ice10,               &
                t_soisno_s1,t_soisno_s2,t_soisno_s3,t_soisno_s4,    &
                t_soisno_s5,t_soisno1,t_soisno2,t_soisno3,          &
                t_soisno4,t_soisno5,t_soisno6,t_soisno7,            &
                t_soisno8,t_soisno9,t_soisno10,                     &
                dzsnow1,dzsnow2,dzsnow3,dzsnow4,dzsnow5,            &
                snowrds1,snowrds2,snowrds3,snowrds4,snowrds5,       &
                t_lake1,t_lake2,t_lake3,t_lake4,t_lake5,            &
                t_lake6,t_lake7,t_lake8,t_lake9,t_lake10,           &
                h2osoi_vol1,h2osoi_vol2,h2osoi_vol3,                &
                h2osoi_vol4,h2osoi_vol5,h2osoi_vol6,                &
                h2osoi_vol7,h2osoi_vol8,                            &
                h2osoi_vol9,h2osoi_vol10,                           &
                ALBEDOsubgrid,LHsubgrid,HFXsubgrid,LWUPsubgrid,     &
                Q2subgrid,SABVsubgrid,SABGsubgrid,NRAsubgrid,SWUPsubgrid ,&
                LHsoi,LHveg,LHtran
#if ( WRF_CHEM == 1 ) 
  real,    optional,  dimension(ims:ime,jms:jme,1:ne_area ),intent(inout) ::  &
                e_bio
#endif
#ifdef CN
!ylu 05/31/2011

!CROP&CN restart and potential output
  integer, optional,  dimension(ims:ime,1:maxpatch,jms:jme ),intent(inout) :: croplive
  real,optional,dimension(ims:ime,1:maxpatch,jms:jme),intent(inout) :: &
                 dyntlai,dyntsai,dyntop,dynbot,   &
                 htmx,gdd1020,gdd820,gdd020,grainc,grainc_storage  &
                ,grainc_xfer,grainn,grainn_storage,grainn_xfer,days_active  &
                ,onset_flag,onset_counter,onset_gddflag,onset_fdd,onset_gdd &
                ,onset_swi,offset_flag,offset_counter,offset_fdd,offset_swi &
                ,dayl,annavg_t2m,tempavg_t2m,tempsum_potential_gpp          &
                ,annsum_potential_gpp,tempmax_retransn,annmax_retransn      &
                ,prev_leafc_to_litter,prev_frootc_to_litter,tempsum_npp     &
                ,annsum_npp,leafc,leafc_storage,leafc_xfer,frootc           &
                ,frootc_storage,frootc_xfer,livestemc,livestemc_storage     &
                ,livestemc_xfer,deadstemc,deadstemc_storage,deadstemc_xfer  &
                ,livecrootc,livecrootc_storage,livecrootc_xfer,deadcrootc   &
                ,deadcrootc_storage,deadcrootc_xfer,cpool,pft_ctrunc        &
                ,leafn,leafn_storage,leafn_xfer,frootn,frootn_storage       &
                ,frootn_xfer,livestemn,livestemn_storage,livestemn_xfer     &
                ,deadstemn,deadstemn_storage,deadstemn_xfer,livecrootn      &
                ,livecrootn_storage,livecrootn_xfer,deadcrootn              &
                ,deadcrootn_storage,deadcrootn_xfer,npool,pft_ntrunc        &
                ,gresp_storage,gresp_xfer,xsmrpool,annsum_counter           &
                ,cannsum_npp,cannavg_t2m,wf,me,mean_fire_prob,cwdc,litr1c   &
                ,litr2c,litr3c,soil1c,soil2c,soil3c,soil4c,seedc,col_ctrunc &
                ,prod10c,prod100c,cwdn,litr1n,litr2n,litr3n,soil1n,soil2n   &
                ,soil3n,soil4n,seedn,col_ntrunc,prod10n,prod100n,sminn      &
                ,totlitc,dwt_seedc_to_leaf,dwt_seedc_to_deadstem,dwt_conv_cflux &
                ,dwt_prod10c_gain,dwt_prod100c_gain,prod100c_loss,dwt_frootc_to_litr1c &
                ,dwt_frootc_to_litr2c,dwt_frootc_to_litr3c,dwt_livecrootc_to_cwdc &
                ,dwt_deadcrootc_to_cwdc,dwt_seedn_to_leaf,dwt_seedn_to_deadstem &
                ,dwt_conv_nflux,dwt_prod10n_gain,dwt_prod100n_gain,prod100n_loss &
                ,dwt_frootn_to_litr1n,dwt_frootn_to_litr2n, dwt_frootn_to_litr3n &
                , dwt_livecrootn_to_cwdn,dwt_deadcrootn_to_cwdn,retransn
#endif


! Variables for TEMF surface layer
   REAL,OPTIONAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) :: te_temf
   REAL,OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: hd_temf, exch_temf, wm_temf
   REAL,OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN   ) :: fCor

! Variables for ideal SCM surface layer
   REAL,OPTIONAL, INTENT(INOUT) :: hfx_force,lh_force,tsk_force
   REAL,OPTIONAL, INTENT(IN   ) :: hfx_force_tend,lh_force_tend,tsk_force_tend

!  LOCAL  VAR

   ! P1.7: was automatic (ims:ime, kms:kme, jms:jme)
   REAL,       DIMENSION(:,:,:), POINTER, CONTIGUOUS :: v_phytmp
   REAL,       DIMENSION(:,:,:), POINTER, CONTIGUOUS :: u_phytmp
#ifdef WRF_GPU
   LOGICAL :: gpu_isl
   INTEGER :: its, ite, jts, jte
   INTEGER, DIMENSION(num_tiles) :: i_start_h, i_end_h, j_start_h, j_end_h
#endif

#ifdef WRF_GPU
   REAL, DIMENSION(:,:), POINTER, CONTIGUOUS :: QGH, CHS, CQS, CPM, CHS2, CQS2
#else
   REAL,       DIMENSION( ims:ime, jms:jme )          ::          &
                                                             QGH, &
                                                             CHS, &
                                                             CQS, &
                                                             CPM, &
                                                            CHS2, &
                                                            CQS2
#endif
! CTSM local variable
   REAL, DIMENSION( ims:ime , jms:jme ) :: xland_ctsm
! SSIB local variables
   REAL ZDIFF
   REAL, DIMENSION( ims:ime , jms:jme ) :: XICE_save
!
   REAL    :: DTMIN,DTBL
!
   INTEGER :: i,J,K,NK,jj,ij
   INTEGER :: gfdl_ntsflg
   LOGICAL :: radiation, myj, myjpbl, frpcpn, isisfc
   LOGICAL, INTENT(in), OPTIONAL :: rdlai2d
   LOGICAL, INTENT(in), OPTIONAL :: usemonalb
   REAL    :: total_depth,mid_point_depth
   REAL    :: tconst,tprior,tnew,yrday,deltat
   REAL    :: SWSAVE
   REAL,       DIMENSION( ims:ime, jms:jme )          ::  GSWSAVE
!-------------------------------------------------
! urban related variables are added to declaration
!-------------------------------------------------
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: CMR_SFCDIF
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: CHR_SFCDIF
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: CMGR_SFCDIF
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: CHGR_SFCDIF
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: CMC_SFCDIF
   REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: CHC_SFCDIF
     REAL, OPTIONAL, INTENT(IN) :: DECLIN, SOLCON
     REAL, OPTIONAL , DIMENSION( ims:ime, jms:jme ), INTENT(IN) :: COSZEN
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN) :: HRANG
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN) :: XLAT_URB2D  !urban
     INTEGER,  INTENT(IN) :: num_roof_layers                         !urban
     INTEGER,  INTENT(IN) :: num_wall_layers                         !urban
     INTEGER,  INTENT(IN) :: num_road_layers                         !urban
     INTEGER,  INTENT(IN), OPTIONAL :: julian,julyr                            !urban
     REAL, OPTIONAL, DIMENSION(1:num_soil_layers), INTENT(IN) :: DZR          !urban
     REAL, OPTIONAL, DIMENSION(1:num_soil_layers), INTENT(IN) :: DZB          !urban
     REAL, OPTIONAL, DIMENSION(1:num_soil_layers), INTENT(IN) :: DZG          !urban

     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT)  :: TR_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT)  :: TB_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT)  :: TG_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT):: TC_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT):: QC_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT):: UC_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT):: XXXR_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT):: XXXB_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT):: XXXG_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT):: XXXC_URB2D !urban

     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: DRELR_URB2D
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: DRELB_URB2D
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: DRELG_URB2D
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: FLXHUMR_URB2D
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: FLXHUMB_URB2D
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: FLXHUMG_URB2D
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: CMCR_URB2D
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT) :: TGR_URB2D

     REAL, OPTIONAL, DIMENSION( ims:ime , 1:num_soil_layers, jms:jme ), &       !urban
           INTENT(INOUT)  :: TGRL_URB3D                                 !urban
     REAL, OPTIONAL, DIMENSION( ims:ime , 1:num_soil_layers, jms:jme ), &       !urban
           INTENT(INOUT)  :: SMR_URB3D                                 !urban
     REAL, OPTIONAL, DIMENSION( ims:ime , 1:num_soil_layers, jms:jme ), &       !urban
           INTENT(INOUT)  :: TRL_URB3D                                 !urban
     REAL, OPTIONAL, DIMENSION( ims:ime , 1:num_soil_layers, jms:jme ), &       !urban
           INTENT(INOUT)  :: TBL_URB3D                                 !urban
     REAL, OPTIONAL, DIMENSION( ims:ime , 1:num_soil_layers, jms:jme ), &       !urban
           INTENT(INOUT)  :: TGL_URB3D                                 !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT)  :: SH_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT):: LH_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT):: G_URB2D  !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT):: RN_URB2D !urban
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT):: TS_URB2D !urban
!
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT)  :: FRC_URB2D  !urban
     INTEGER, OPTIONAL, DIMENSION( ims:ime, jms:jme ), INTENT(INOUT)  :: UTYPE_URB2D  !urban

     REAL,  DIMENSION( ims:ime, jms:jme )  :: PSIM_URB2D  !urban local var
     REAL,  DIMENSION( ims:ime, jms:jme )  :: PSIH_URB2D  !urban local var
     REAL,  DIMENSION( ims:ime, jms:jme )  :: GZ1OZ0_URB2D  !urban local var
!m     REAL, DIMENSION( ims:ime, jms:jme ) :: AKHS_URB2D  !urban local var
     REAL,  DIMENSION( ims:ime, jms:jme )  :: AKMS_URB2D  !urban local var
     REAL,  DIMENSION( ims:ime, jms:jme )  :: U10_URB2D   !urban local var
     REAL,  DIMENSION( ims:ime, jms:jme )  :: V10_URB2D   !urban local var
     REAL,  DIMENSION( ims:ime, jms:jme )  :: TH2_URB2D   !urban local var
     REAL,  DIMENSION( ims:ime, jms:jme )  :: Q2_URB2D    !urban local var
     REAL,  DIMENSION( ims:ime, jms:jme )  :: UST_URB2D  !urban local var
     
!-------------------------------------------------
! Noah-mosaic related variables are added to declaration  (danli)
!-------------------------------------------------
  
  INTEGER, INTENT(IN) :: sf_surface_mosaic
  INTEGER, INTENT(IN) :: mosaic_cat
  INTEGER, DIMENSION( ims:ime, NLCAT, jms:jme ), INTENT(INOUT), OPTIONAL :: mosaic_cat_index
  REAL,    DIMENSION( ims:ime, NLCAT, jms:jme ), INTENT(INOUT), OPTIONAL :: landusef2

  REAL, DIMENSION( ims:ime, 1:mosaic_cat, jms:jme ) , OPTIONAL, INTENT(INOUT)::   &
        TSK_mosaic, QSFC_mosaic, CANWAT_mosaic, SNOW_mosaic,SNOWH_mosaic, SNOWC_mosaic
  REAL, DIMENSION( ims:ime, 1:mosaic_cat, jms:jme ) , OPTIONAL, INTENT(INOUT)::   &
        ALBEDO_mosaic,ALBBCK_mosaic, EMISS_mosaic, EMBCK_mosaic, ZNT_mosaic, Z0_mosaic,   &
        HFX_mosaic,QFX_mosaic, LH_mosaic,GRDFLX_mosaic,SNOTIME_mosaic, &
        RS_mosaic,LAI_mosaic
  REAL, DIMENSION( ims:ime, 1:num_soil_layers*mosaic_cat, jms:jme ), OPTIONAL, INTENT(INOUT)::   &
        TSLB_mosaic,SMOIS_mosaic,SH2O_mosaic

   REAL, DIMENSION( ims:ime, 1:mosaic_cat, jms:jme ) , OPTIONAL, INTENT(INOUT)::  &
         TR_URB2D_mosaic, TB_URB2D_mosaic, TG_URB2D_mosaic, TC_URB2D_mosaic,QC_URB2D_mosaic, UC_URB2D_mosaic, &
         SH_URB2D_mosaic,LH_URB2D_mosaic,G_URB2D_mosaic,RN_URB2D_mosaic,TS_URB2D_mosaic, TS_RUL2D_mosaic  
                  
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:num_soil_layers*mosaic_cat, jms:jme ), INTENT(INOUT) :: TRL_URB3D_mosaic
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:num_soil_layers*mosaic_cat, jms:jme ), INTENT(INOUT) :: TBL_URB3D_mosaic
   REAL, OPTIONAL, DIMENSION( ims:ime, 1:num_soil_layers*mosaic_cat, jms:jme ), INTENT(INOUT) :: TGL_URB3D_mosaic
     
!-------------------------------------------------
! End of Noah-mosaic related variables 
!-------------------------------------------------     
     
!--------fds (06/2010)---------------------------------------------
     REAL,  DIMENSION( ims:ime, kms:kme, jms:jme ),               &
            OPTIONAL, INTENT(IN) ::                                 CLDFRA
     REAL   :: DAY, CLOUDFRAC, UV10
!------------------------------------------------------------------
!
     REAL, DIMENSION( ims:ime, jms:jme ) :: HFX_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: QFX_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: LH_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: QSFC_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: TSK_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: ZNT_SEA

     REAL, DIMENSION( ims:ime, jms:jme ) :: CHS_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: CHS2_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: CQS2_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: CPM_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: FLHC_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: FLQC_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: QGH_SEA
!
     REAL, DIMENSION( ims:ime, jms:jme ) :: PBLH_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: UST_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: QZ0_SEA
     REAL, DIMENSION( ims:ime, jms:jme ) :: TSK_LOCAL
    ! lake varibles ,inout(14)
    real,    dimension(ims:ime,jms:jme ),intent(inout)                      :: savedtke12d
    real,    dimension(ims:ime,jms:jme ),intent(inout)                      :: snowdp2d,       &
                                                                               h2osno2d,       &
                                                                               snl2d,          &
                                                                               t_grnd2d
 
    real,    dimension( ims:ime,1:nlevlake, jms:jme ),INTENT(inout)          :: t_lake3d,       &
                                                                               lake_icefrac3d
    real,    dimension( ims:ime,-nlevsnow+1:nlevsoil, jms:jme ),INTENT(inout) :: t_soisno3d,     &
                                                                               h2osoi_ice3d,   &
                                                                               h2osoi_liq3d,   &
                                                                               h2osoi_vol3d,   &
                                                                               z3d,            &
                                                                               dz3d
    real,    dimension( ims:ime,-nlevsnow+0:nlevsoil, jms:jme ),INTENT(inout) :: zi3d
    ! in(8)
    real,    dimension( ims:ime,1:nlevlake, jms:jme ),INTENT(in)             :: z_lake3d,       &
                                                                               dz_lake3d
    real,    dimension( ims:ime,1:nlevsoil, jms:jme ),INTENT(in)             :: watsat3d,       &
                                                                               csol3d,         &
                                                                               tkmg3d,         &
                                                                               tkdry3d,        &
                                                                               tksatu3d
    INTEGER, INTENT(IN)                            :: shalwater_z0 
    REAL,    INTENT(IN)                            :: shalwater_depth 
    real,    dimension(ims:ime,jms:jme ),intent(inout) :: water_depth 
    real,    dimension(ims:ime,jms:jme ),intent(in)                         :: lakedepth2d
#if (EM_CORE==1)
    real ,    dimension(ims:ime,jms:jme )  ::  lakemask
    logical , intent(in) :: restart_flag
!    INTEGER  :: lakeflag
#endif
!    logical, dimension(ims:ime,jms:jme ),intent(in)                         :: lake 
 
!
   REAL   :: xice_threshold
   CHARACTER(LEN=256) :: LLANDUSE
! cyl 3d ocean variable 
   integer :: okms, okme
   real, optional , dimension(ims:ime, okms:okme, jms:jme), INTENT(INOUT):: OM_TMP,OM_S,OM_U,OM_V,OM_DEPTH
   real, optional , dimension(ims:ime, okms:okme, jms:jme), INTENT(IN):: OM_TINI,OM_SINI
   real, optional , dimension(ims:ime, jms:jme),INTENT(INOUT):: OM_ML, OM_LAT, OM_LON
   REAL, OPTIONAL , INTENT(IN   ) :: rdx, rdy,xtime,omdt
   REAL , OPTIONAL , DIMENSION( ims:ime , jms:jme ) , INTENT(IN   ) :: msfu, msfv, msft
   INTEGER , OPTIONAL , INTENT(IN)        :: id
!
  real,    dimension(ims:ime,1:maxpatch,jms:jme ) ::  q_ref2m   ! clm

  real,  intent(inout),optional :: t_veg24(ims:ime,1:maxpatch,jms:jme)      ! voce accum variables
  real,  intent(inout),optional :: t_veg240(ims:ime,1:maxpatch,jms:jme)
  real,  intent(inout),optional :: fsun24(ims:ime,1:maxpatch,jms:jme)
  real,  intent(inout),optional :: fsun240(ims:ime,1:maxpatch,jms:jme)
  real,  intent(inout),optional :: fsd24(ims:ime,1:maxpatch,jms:jme)
  real,  intent(inout),optional :: fsd240(ims:ime,1:maxpatch,jms:jme)
  real,  intent(inout),optional :: fsi24(ims:ime,1:maxpatch,jms:jme)
  real,  intent(inout),optional :: fsi240(ims:ime,1:maxpatch,jms:jme)
  real,  intent(inout),optional :: laip(ims:ime,1:maxpatch,jms:jme)

!------------------------------------------------------------------
   CHARACTER*256 :: message
   REAL    :: next_bl_time
   LOGICAL :: run_param , doing_adapt_dt , decided
   LOGICAL :: do_adapt
!
! FASDAS
!
   REAL, DIMENSION( ims:ime, jms:jme ) , INTENT(INOUT), OPTIONAL ::   SDA_HFX,SDA_QFX,HFX_BOTH, QFX_BOTH, QNORM
   INTEGER, INTENT(IN   )                              ::   fasdas
! local vars
   REAL, DIMENSION( ims:ime, jms:jme )                 ::   HFXOLD, QFXOLD
   REAL                                                ::   HFX_KAY, QFX_KAY
! local var for SPP_LSM
   INTEGER                                             ::   spp_lsm_loc

   real,    optional,  dimension(ims:ime,jms:jme ),intent(inout) :: XLAIDYN
! IRRIGATION
   INTEGER :: ihour, jmonth, jday
#ifdef WRF_GPU
   REAL, DIMENSION(:,:), POINTER, CONTIGUOUS :: IRRIGATION_CHANNEL
#else
   REAL, DIMENSION( ims:ime, jms:jme ) :: IRRIGATION_CHANNEL      
#endif
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN)   , OPTIONAL::   IRRIGATION
   REAL,  INTENT(IN),OPTIONAL::  irr_daily_amount     
   INTEGER, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT),OPTIONAL :: irr_rand_field
   INTEGER, INTENT(IN ),OPTIONAL:: sf_surf_irr_scheme,irr_start_hour,irr_num_hours,irr_start_julianday,irr_end_julianday,irr_freq,irr_ph

! WRF-Solar EPS
  real, dimension (:, :, :), allocatable :: smois_tmp, tslb_tmp

! To accommodate shared physics
   character*256 :: errmsg
   integer :: errflg
!
!------------------------------------------------------------------
! Initialize local variables
  q_ref2m = 0.0
!------------------------------------------------------------------
!
! stop run if using ssib and fractional seaice=0  (fds 12/2010)

  if(sf_surface_physics .eq. SSIBSCHEME .and. fractional_seaice .eq. 0) then
    WRITE( message,* ) 'Please activate fractional seaice option when using SSiB model'
    CALL wrf_error_fatal ( message )
  endif

  if (sf_sfclay_physics .eq. 0) return

   ! P1.7: remap the former 3D automatic arrays onto work arrays (both builds).
   u_phytmp(ims:ime,kms:kme,jms:jme) => work_p3_sfcdrv_u_phytmp(1:(ime-ims+1)*(kme-kms+1)*(jme-jms+1))
   v_phytmp(ims:ime,kms:kme,jms:jme) => work_p3_sfcdrv_v_phytmp(1:(ime-ims+1)*(kme-kms+1)*(jme-jms+1))
#ifdef WRF_GPU
   ! GPU-only 2D automatics passed into SFCLAYREV, lsm, seaice_noah and SFCDIAGS.
   qgh(ims:ime,jms:jme) => work_p3_sfcdrv_qgh(1:(ime-ims+1)*(jme-jms+1))
   chs(ims:ime,jms:jme) => work_p3_sfcdrv_chs(1:(ime-ims+1)*(jme-jms+1))
   cqs(ims:ime,jms:jme) => work_p3_sfcdrv_cqs(1:(ime-ims+1)*(jme-jms+1))
   cpm(ims:ime,jms:jme) => work_p3_sfcdrv_cpm(1:(ime-ims+1)*(jme-jms+1))
   chs2(ims:ime,jms:jme) => work_p3_sfcdrv_chs2(1:(ime-ims+1)*(jme-jms+1))
   cqs2(ims:ime,jms:jme) => work_p3_sfcdrv_cqs2(1:(ime-ims+1)*(jme-jms+1))
   irrigation_channel(ims:ime,jms:jme) => work_p3_sfcdrv_irrigation_channel(1:(ime-ims+1)*(jme-jms+1))
   DO ij = 1, num_tiles
      i_start_h(ij) = i_start(ij)
      i_end_h(ij) = i_end(ij)
      j_start_h(ij) = j_start(ij)
      j_end_h(ij) = j_end(ij)
   END DO
   ! Unported options stop before the entry island moves the arrays.
   IF (sf_sfclay_physics .NE. SFCLAYREVSCHEME) &
      CALL wrf_error_fatal('surface_driver: sf_sfclay_physics not ported to the GPU')
   IF (sf_surface_physics .NE. LSMSCHEME) &
      CALL wrf_error_fatal('surface_driver: sf_surface_physics not ported to the GPU')
   IF (fractional_seaice .NE. 0) &
      CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
   IF (sst_update .EQ. 1) &
      CALL wrf_error_fatal('surface_driver: sst_update not ported to the GPU')
   IF (PRESENT(sst_skin)) THEN
      IF (sst_skin .EQ. 1) &
         CALL wrf_error_fatal('surface_driver: sst_skin not ported to the GPU')
   END IF
   IF (PRESENT(tmn_update)) THEN
      IF (tmn_update .EQ. 1) &
         CALL wrf_error_fatal('surface_driver: tmn_update not ported to the GPU')
   END IF
   IF (PRESENT(slope_rad)) THEN
      IF (slope_rad .EQ. 1) &
         CALL wrf_error_fatal('surface_driver: slope_rad not ported to the GPU')
   END IF
   IF (sf_urban_physics .NE. 0) &
      CALL wrf_error_fatal('surface_driver: sf_urban_physics not ported to the GPU')
   IF (sf_surface_mosaic .NE. 0) &
      CALL wrf_error_fatal('surface_driver: sf_surface_mosaic not ported to the GPU')
   IF (fasdas .NE. 0) &
      CALL wrf_error_fatal('surface_driver: fasdas not ported to the GPU')
   IF (PRESENT(sf_surf_irr_scheme)) THEN
      IF (sf_surf_irr_scheme .NE. 0) &
         CALL wrf_error_fatal('surface_driver: sf_surf_irr_scheme not ported to the GPU')
   END IF
   IF (isfflx .EQ. 0) &
      CALL wrf_error_fatal('surface_driver: isfflx=0 not ported to the GPU')
   IF (distributed_ahe_opt .EQ. 2) &
      CALL wrf_error_fatal('surface_driver: distributed_ahe_opt not ported to the GPU')
   IF (LakeModel .EQ. 1) &
      CALL wrf_error_fatal('surface_driver: LakeModel not ported to the GPU')
   IF (coupler_on) &
      CALL wrf_error_fatal('surface_driver: coupler_on not ported to the GPU')
   IF (pert_noah .AND. multi_perturb .EQ. 1) &
      CALL wrf_error_fatal('surface_driver: pert_noah not ported to the GPU')
   IF (.NOT. PRESENT(rainncv) .AND. PRESENT(rainbl)) &
      CALL wrf_error_fatal('surface_driver: rainbl without rainncv not ported to the GPU')
#if (EM_CORE==1)
   IF (PRESENT(grav_settling)) THEN
      IF (grav_settling .NE. 0) &
         CALL wrf_error_fatal('surface_driver: grav_settling not ported to the GPU')
   END IF
   IF (PRESENT(sf_ocean_physics)) THEN
      IF (sf_ocean_physics .EQ. OMLSCHEME .OR. sf_ocean_physics .EQ. PWP3DSCHEME) &
         CALL wrf_error_fatal('surface_driver: sf_ocean_physics not ported to the GPU')
   END IF
#endif
#endif
#ifdef WRF_GPU
99901 CONTINUE
      IF (gpu_cc_start(R_SURFACE_DRIVER)) THEN
        CALL gpu_cc_save_r0(1, hydro_dt)
        CALL gpu_cc_save_r(2, sfcheadrt, SIZE(sfcheadrt,KIND=8))
        CALL gpu_cc_save_r(3, infxsrt, SIZE(infxsrt,KIND=8))
        CALL gpu_cc_save_r(4, soldrain, SIZE(soldrain,KIND=8))
        CALL gpu_cc_save_r(5, qtiledrain, SIZE(qtiledrain,KIND=8))
        CALL gpu_cc_save_r(6, zwatble2d, SIZE(zwatble2d,KIND=8))
        IF (PRESENT(acgrdflx)) CALL gpu_cc_save_r(7, acgrdflx, SIZE(acgrdflx,KIND=8))
        IF (PRESENT(achfx)) CALL gpu_cc_save_r(8, achfx, SIZE(achfx,KIND=8))
        IF (PRESENT(aclhf)) CALL gpu_cc_save_r(9, aclhf, SIZE(aclhf,KIND=8))
        CALL gpu_cc_save_r(10, acsnom, SIZE(acsnom,KIND=8))
        CALL gpu_cc_save_r(11, acsnow, SIZE(acsnow,KIND=8))
        IF (PRESENT(snowfallac)) CALL gpu_cc_save_r(12, snowfallac, SIZE(snowfallac,KIND=8))
        CALL gpu_cc_save_r(13, akhs, SIZE(akhs,KIND=8))
        CALL gpu_cc_save_r(14, akms, SIZE(akms,KIND=8))
        CALL gpu_cc_save_r(15, albedo, SIZE(albedo,KIND=8))
        CALL gpu_cc_save_r(16, br, SIZE(br,KIND=8))
        CALL gpu_cc_save_r(17, canwat, SIZE(canwat,KIND=8))
        CALL gpu_cc_save_r(18, chklowq, SIZE(chklowq,KIND=8))
        CALL gpu_cc_save_r(19, grdflx, SIZE(grdflx,KIND=8))
        CALL gpu_cc_save_r(20, gsw, SIZE(gsw,KIND=8))
        CALL gpu_cc_save_r(21, swdown, SIZE(swdown,KIND=8))
        CALL gpu_cc_save_r(22, gz1oz0, SIZE(gz1oz0,KIND=8))
        CALL gpu_cc_save_r(23, hfx, SIZE(hfx,KIND=8))
        CALL gpu_cc_save_i(24, isltyp, SIZE(isltyp,KIND=8))
        CALL gpu_cc_save_i(25, ivgtyp, SIZE(ivgtyp,KIND=8))
        CALL gpu_cc_save_r(26, mavail, SIZE(mavail,KIND=8))
        CALL gpu_cc_save_r(27, rmol, SIZE(rmol,KIND=8))
        CALL gpu_cc_save_r(28, pblh, SIZE(pblh,KIND=8))
        CALL gpu_cc_save_r(29, pshltr, SIZE(pshltr,KIND=8))
        CALL gpu_cc_save_r(30, fm, SIZE(fm,KIND=8))
        CALL gpu_cc_save_r(31, fhh, SIZE(fhh,KIND=8))
        CALL gpu_cc_save_r(32, psih, SIZE(psih,KIND=8))
        CALL gpu_cc_save_r(33, psim, SIZE(psim,KIND=8))
        CALL gpu_cc_save_r(34, q10, SIZE(q10,KIND=8))
        CALL gpu_cc_save_r(35, q2, SIZE(q2,KIND=8))
        CALL gpu_cc_save_r(36, qfx, SIZE(qfx,KIND=8))
        CALL gpu_cc_save_r(37, qsfc, SIZE(qsfc,KIND=8))
        CALL gpu_cc_save_r(38, qshltr, SIZE(qshltr,KIND=8))
        CALL gpu_cc_save_r(39, qz0, SIZE(qz0,KIND=8))
        CALL gpu_cc_save_r(40, sfcevp, SIZE(sfcevp,KIND=8))
        CALL gpu_cc_save_r(41, sfcexc, SIZE(sfcexc,KIND=8))
        CALL gpu_cc_save_r(42, sfcrunoff, SIZE(sfcrunoff,KIND=8))
        CALL gpu_cc_save_r(43, acrunoff, SIZE(acrunoff,KIND=8))
        CALL gpu_cc_save_r(44, smois, SIZE(smois,KIND=8))
        CALL gpu_cc_save_r(45, smstav, SIZE(smstav,KIND=8))
        CALL gpu_cc_save_r(46, smstot, SIZE(smstot,KIND=8))
        CALL gpu_cc_save_r(47, snoalb, SIZE(snoalb,KIND=8))
        CALL gpu_cc_save_r(48, snow, SIZE(snow,KIND=8))
        CALL gpu_cc_save_r(49, snowc, SIZE(snowc,KIND=8))
        CALL gpu_cc_save_r(50, snowh, SIZE(snowh,KIND=8))
        CALL gpu_cc_save_r(51, smcrel, SIZE(smcrel,KIND=8))
        CALL gpu_cc_save_r(52, th10, SIZE(th10,KIND=8))
        CALL gpu_cc_save_r(53, th2, SIZE(th2,KIND=8))
        CALL gpu_cc_save_r(54, thz0, SIZE(thz0,KIND=8))
        CALL gpu_cc_save_r(55, tmn, SIZE(tmn,KIND=8))
        CALL gpu_cc_save_r(56, tshltr, SIZE(tshltr,KIND=8))
        CALL gpu_cc_save_r(57, tsk, SIZE(tsk,KIND=8))
        CALL gpu_cc_save_r(58, tslb, SIZE(tslb,KIND=8))
        IF (PRESENT(tyr)) CALL gpu_cc_save_r(59, tyr, SIZE(tyr,KIND=8))
        IF (PRESENT(tyra)) CALL gpu_cc_save_r(60, tyra, SIZE(tyra,KIND=8))
        IF (PRESENT(tdly)) CALL gpu_cc_save_r(61, tdly, SIZE(tdly,KIND=8))
        IF (PRESENT(tlag)) CALL gpu_cc_save_r(62, tlag, SIZE(tlag,KIND=8))
        IF (PRESENT(nyear)) CALL gpu_cc_save_i0(63, nyear)
        IF (PRESENT(nday)) CALL gpu_cc_save_r0(64, nday)
        CALL gpu_cc_save_r(65, t_phy, SIZE(t_phy,KIND=8))
        CALL gpu_cc_save_r(66, u10, SIZE(u10,KIND=8))
        CALL gpu_cc_save_r(67, udrunoff, SIZE(udrunoff,KIND=8))
        CALL gpu_cc_save_r(68, ust, SIZE(ust,KIND=8))
        CALL gpu_cc_save_r(69, uz0, SIZE(uz0,KIND=8))
        CALL gpu_cc_save_r(70, v10, SIZE(v10,KIND=8))
        CALL gpu_cc_save_r(71, vegfra, SIZE(vegfra,KIND=8))
        CALL gpu_cc_save_r(72, u10e, SIZE(u10e,KIND=8))
        CALL gpu_cc_save_r(73, v10e, SIZE(v10e,KIND=8))
        CALL gpu_cc_save_r(74, uoce, SIZE(uoce,KIND=8))
        CALL gpu_cc_save_r(75, voce, SIZE(voce,KIND=8))
        CALL gpu_cc_save_r(76, vz0, SIZE(vz0,KIND=8))
        CALL gpu_cc_save_r(77, wspd, SIZE(wspd,KIND=8))
        CALL gpu_cc_save_r(78, xice, SIZE(xice,KIND=8))
        CALL gpu_cc_save_r(79, xland, SIZE(xland,KIND=8))
        CALL gpu_cc_save_r(80, znt, SIZE(znt,KIND=8))
        CALL gpu_cc_save_r(81, albsi, SIZE(albsi,KIND=8))
        CALL gpu_cc_save_r(82, icedepth, SIZE(icedepth,KIND=8))
        CALL gpu_cc_save_r(83, snowsi, SIZE(snowsi,KIND=8))
        CALL gpu_cc_save_r(84, xicem, SIZE(xicem,KIND=8))
        CALL gpu_cc_save_r(85, ct, SIZE(ct,KIND=8))
        CALL gpu_cc_save_r(86, tke_pbl, SIZE(tke_pbl,KIND=8))
        CALL gpu_cc_save_r(87, albbck, SIZE(albbck,KIND=8))
        CALL gpu_cc_save_r(88, embck, SIZE(embck,KIND=8))
        CALL gpu_cc_save_r(89, lh, SIZE(lh,KIND=8))
        CALL gpu_cc_save_r(90, sh2o, SIZE(sh2o,KIND=8))
        CALL gpu_cc_save_r(91, z0, SIZE(z0,KIND=8))
        CALL gpu_cc_save_r(92, flqc, SIZE(flqc,KIND=8))
        CALL gpu_cc_save_r(93, flhc, SIZE(flhc,KIND=8))
        CALL gpu_cc_save_r(94, psfc, SIZE(psfc,KIND=8))
        CALL gpu_cc_save_r(95, sst, SIZE(sst,KIND=8))
        IF (PRESENT(sstsk)) CALL gpu_cc_save_r(96, sstsk, SIZE(sstsk,KIND=8))
        IF (PRESENT(dtw)) CALL gpu_cc_save_r(97, dtw, SIZE(dtw,KIND=8))
        IF (PRESENT(t2)) CALL gpu_cc_save_r(98, t2, SIZE(t2,KIND=8))
        IF (PRESENT(emiss)) CALL gpu_cc_save_r(99, emiss, SIZE(emiss,KIND=8))
        IF (PRESENT(landusef)) CALL gpu_cc_save_r(100, landusef, SIZE(landusef,KIND=8))
        IF (PRESENT(soilctop)) CALL gpu_cc_save_r(101, soilctop, SIZE(soilctop,KIND=8))
        IF (PRESENT(soilcbot)) CALL gpu_cc_save_r(102, soilcbot, SIZE(soilcbot,KIND=8))
        IF (PRESENT(ra)) CALL gpu_cc_save_r(103, ra, SIZE(ra,KIND=8))
        IF (PRESENT(rs)) CALL gpu_cc_save_r(104, rs, SIZE(rs,KIND=8))
        IF (PRESENT(vegf_px)) CALL gpu_cc_save_r(105, vegf_px, SIZE(vegf_px,KIND=8))
        IF (PRESENT(lai)) CALL gpu_cc_save_r(106, lai, SIZE(lai,KIND=8))
        IF (PRESENT(imperv)) CALL gpu_cc_save_r(107, imperv, SIZE(imperv,KIND=8))
        IF (PRESENT(canfra)) CALL gpu_cc_save_r(108, canfra, SIZE(canfra,KIND=8))
        IF (PRESENT(lai_px)) CALL gpu_cc_save_r(109, lai_px, SIZE(lai_px,KIND=8))
        IF (PRESENT(wwlt_px)) CALL gpu_cc_save_r(110, wwlt_px, SIZE(wwlt_px,KIND=8))
        IF (PRESENT(wfc_px)) CALL gpu_cc_save_r(111, wfc_px, SIZE(wfc_px,KIND=8))
        IF (PRESENT(wsat_px)) CALL gpu_cc_save_r(112, wsat_px, SIZE(wsat_px,KIND=8))
        IF (PRESENT(clay_px)) CALL gpu_cc_save_r(113, clay_px, SIZE(clay_px,KIND=8))
        IF (PRESENT(csand_px)) CALL gpu_cc_save_r(114, csand_px, SIZE(csand_px,KIND=8))
        IF (PRESENT(fmsand_px)) CALL gpu_cc_save_r(115, fmsand_px, SIZE(fmsand_px,KIND=8))
        IF (PRESENT(isnowxy)) CALL gpu_cc_save_i(116, isnowxy, SIZE(isnowxy,KIND=8))
        IF (PRESENT(tvxy)) CALL gpu_cc_save_r(117, tvxy, SIZE(tvxy,KIND=8))
        IF (PRESENT(tgxy)) CALL gpu_cc_save_r(118, tgxy, SIZE(tgxy,KIND=8))
        IF (PRESENT(canicexy)) CALL gpu_cc_save_r(119, canicexy, SIZE(canicexy,KIND=8))
        IF (PRESENT(canliqxy)) CALL gpu_cc_save_r(120, canliqxy, SIZE(canliqxy,KIND=8))
        IF (PRESENT(eahxy)) CALL gpu_cc_save_r(121, eahxy, SIZE(eahxy,KIND=8))
        IF (PRESENT(tahxy)) CALL gpu_cc_save_r(122, tahxy, SIZE(tahxy,KIND=8))
        IF (PRESENT(cmxy)) CALL gpu_cc_save_r(123, cmxy, SIZE(cmxy,KIND=8))
        IF (PRESENT(chxy)) CALL gpu_cc_save_r(124, chxy, SIZE(chxy,KIND=8))
        IF (PRESENT(fwetxy)) CALL gpu_cc_save_r(125, fwetxy, SIZE(fwetxy,KIND=8))
        IF (PRESENT(sneqvoxy)) CALL gpu_cc_save_r(126, sneqvoxy, SIZE(sneqvoxy,KIND=8))
        IF (PRESENT(alboldxy)) CALL gpu_cc_save_r(127, alboldxy, SIZE(alboldxy,KIND=8))
        IF (PRESENT(qsnowxy)) CALL gpu_cc_save_r(128, qsnowxy, SIZE(qsnowxy,KIND=8))
        IF (PRESENT(qrainxy)) CALL gpu_cc_save_r(129, qrainxy, SIZE(qrainxy,KIND=8))
        IF (PRESENT(wslakexy)) CALL gpu_cc_save_r(130, wslakexy, SIZE(wslakexy,KIND=8))
        IF (PRESENT(zwtxy)) CALL gpu_cc_save_r(131, zwtxy, SIZE(zwtxy,KIND=8))
        IF (PRESENT(waxy)) CALL gpu_cc_save_r(132, waxy, SIZE(waxy,KIND=8))
        IF (PRESENT(wtxy)) CALL gpu_cc_save_r(133, wtxy, SIZE(wtxy,KIND=8))
        IF (PRESENT(tsnoxy)) CALL gpu_cc_save_r(134, tsnoxy, SIZE(tsnoxy,KIND=8))
        IF (PRESENT(zsnsoxy)) CALL gpu_cc_save_r(135, zsnsoxy, SIZE(zsnsoxy,KIND=8))
        IF (PRESENT(snicexy)) CALL gpu_cc_save_r(136, snicexy, SIZE(snicexy,KIND=8))
        IF (PRESENT(snliqxy)) CALL gpu_cc_save_r(137, snliqxy, SIZE(snliqxy,KIND=8))
        IF (PRESENT(lfmassxy)) CALL gpu_cc_save_r(138, lfmassxy, SIZE(lfmassxy,KIND=8))
        IF (PRESENT(rtmassxy)) CALL gpu_cc_save_r(139, rtmassxy, SIZE(rtmassxy,KIND=8))
        IF (PRESENT(stmassxy)) CALL gpu_cc_save_r(140, stmassxy, SIZE(stmassxy,KIND=8))
        IF (PRESENT(woodxy)) CALL gpu_cc_save_r(141, woodxy, SIZE(woodxy,KIND=8))
        IF (PRESENT(stblcpxy)) CALL gpu_cc_save_r(142, stblcpxy, SIZE(stblcpxy,KIND=8))
        IF (PRESENT(fastcpxy)) CALL gpu_cc_save_r(143, fastcpxy, SIZE(fastcpxy,KIND=8))
        IF (PRESENT(xsaixy)) CALL gpu_cc_save_r(144, xsaixy, SIZE(xsaixy,KIND=8))
        IF (PRESENT(taussxy)) CALL gpu_cc_save_r(145, taussxy, SIZE(taussxy,KIND=8))
        IF (PRESENT(grainxy)) CALL gpu_cc_save_r(146, grainxy, SIZE(grainxy,KIND=8))
        IF (PRESENT(gddxy)) CALL gpu_cc_save_r(147, gddxy, SIZE(gddxy,KIND=8))
        IF (PRESENT(pgsxy)) CALL gpu_cc_save_i(148, pgsxy, SIZE(pgsxy,KIND=8))
        IF (PRESENT(t2mvxy)) CALL gpu_cc_save_r(149, t2mvxy, SIZE(t2mvxy,KIND=8))
        IF (PRESENT(t2mbxy)) CALL gpu_cc_save_r(150, t2mbxy, SIZE(t2mbxy,KIND=8))
        IF (PRESENT(q2mvxy)) CALL gpu_cc_save_r(151, q2mvxy, SIZE(q2mvxy,KIND=8))
        IF (PRESENT(q2mbxy)) CALL gpu_cc_save_r(152, q2mbxy, SIZE(q2mbxy,KIND=8))
        IF (PRESENT(tradxy)) CALL gpu_cc_save_r(153, tradxy, SIZE(tradxy,KIND=8))
        IF (PRESENT(neexy)) CALL gpu_cc_save_r(154, neexy, SIZE(neexy,KIND=8))
        IF (PRESENT(gppxy)) CALL gpu_cc_save_r(155, gppxy, SIZE(gppxy,KIND=8))
        IF (PRESENT(nppxy)) CALL gpu_cc_save_r(156, nppxy, SIZE(nppxy,KIND=8))
        IF (PRESENT(fvegxy)) CALL gpu_cc_save_r(157, fvegxy, SIZE(fvegxy,KIND=8))
        IF (PRESENT(runsfxy)) CALL gpu_cc_save_r(158, runsfxy, SIZE(runsfxy,KIND=8))
        IF (PRESENT(runsbxy)) CALL gpu_cc_save_r(159, runsbxy, SIZE(runsbxy,KIND=8))
        IF (PRESENT(ecanxy)) CALL gpu_cc_save_r(160, ecanxy, SIZE(ecanxy,KIND=8))
        IF (PRESENT(edirxy)) CALL gpu_cc_save_r(161, edirxy, SIZE(edirxy,KIND=8))
        IF (PRESENT(etranxy)) CALL gpu_cc_save_r(162, etranxy, SIZE(etranxy,KIND=8))
        IF (PRESENT(fsaxy)) CALL gpu_cc_save_r(163, fsaxy, SIZE(fsaxy,KIND=8))
        IF (PRESENT(firaxy)) CALL gpu_cc_save_r(164, firaxy, SIZE(firaxy,KIND=8))
        IF (PRESENT(aparxy)) CALL gpu_cc_save_r(165, aparxy, SIZE(aparxy,KIND=8))
        IF (PRESENT(psnxy)) CALL gpu_cc_save_r(166, psnxy, SIZE(psnxy,KIND=8))
        IF (PRESENT(savxy)) CALL gpu_cc_save_r(167, savxy, SIZE(savxy,KIND=8))
        IF (PRESENT(sagxy)) CALL gpu_cc_save_r(168, sagxy, SIZE(sagxy,KIND=8))
        IF (PRESENT(rssunxy)) CALL gpu_cc_save_r(169, rssunxy, SIZE(rssunxy,KIND=8))
        IF (PRESENT(rsshaxy)) CALL gpu_cc_save_r(170, rsshaxy, SIZE(rsshaxy,KIND=8))
        IF (PRESENT(bgapxy)) CALL gpu_cc_save_r(171, bgapxy, SIZE(bgapxy,KIND=8))
        IF (PRESENT(wgapxy)) CALL gpu_cc_save_r(172, wgapxy, SIZE(wgapxy,KIND=8))
        IF (PRESENT(tgvxy)) CALL gpu_cc_save_r(173, tgvxy, SIZE(tgvxy,KIND=8))
        IF (PRESENT(tgbxy)) CALL gpu_cc_save_r(174, tgbxy, SIZE(tgbxy,KIND=8))
        IF (PRESENT(chvxy)) CALL gpu_cc_save_r(175, chvxy, SIZE(chvxy,KIND=8))
        IF (PRESENT(chbxy)) CALL gpu_cc_save_r(176, chbxy, SIZE(chbxy,KIND=8))
        IF (PRESENT(shgxy)) CALL gpu_cc_save_r(177, shgxy, SIZE(shgxy,KIND=8))
        IF (PRESENT(shcxy)) CALL gpu_cc_save_r(178, shcxy, SIZE(shcxy,KIND=8))
        IF (PRESENT(shbxy)) CALL gpu_cc_save_r(179, shbxy, SIZE(shbxy,KIND=8))
        IF (PRESENT(evgxy)) CALL gpu_cc_save_r(180, evgxy, SIZE(evgxy,KIND=8))
        IF (PRESENT(evbxy)) CALL gpu_cc_save_r(181, evbxy, SIZE(evbxy,KIND=8))
        IF (PRESENT(ghvxy)) CALL gpu_cc_save_r(182, ghvxy, SIZE(ghvxy,KIND=8))
        IF (PRESENT(ghbxy)) CALL gpu_cc_save_r(183, ghbxy, SIZE(ghbxy,KIND=8))
        IF (PRESENT(irgxy)) CALL gpu_cc_save_r(184, irgxy, SIZE(irgxy,KIND=8))
        IF (PRESENT(ircxy)) CALL gpu_cc_save_r(185, ircxy, SIZE(ircxy,KIND=8))
        IF (PRESENT(irbxy)) CALL gpu_cc_save_r(186, irbxy, SIZE(irbxy,KIND=8))
        IF (PRESENT(trxy)) CALL gpu_cc_save_r(187, trxy, SIZE(trxy,KIND=8))
        IF (PRESENT(evcxy)) CALL gpu_cc_save_r(188, evcxy, SIZE(evcxy,KIND=8))
        IF (PRESENT(chleafxy)) CALL gpu_cc_save_r(189, chleafxy, SIZE(chleafxy,KIND=8))
        IF (PRESENT(chucxy)) CALL gpu_cc_save_r(190, chucxy, SIZE(chucxy,KIND=8))
        IF (PRESENT(chv2xy)) CALL gpu_cc_save_r(191, chv2xy, SIZE(chv2xy,KIND=8))
        IF (PRESENT(chb2xy)) CALL gpu_cc_save_r(192, chb2xy, SIZE(chb2xy,KIND=8))
        IF (PRESENT(chstarxy)) CALL gpu_cc_save_r(193, chstarxy, SIZE(chstarxy,KIND=8))
        IF (PRESENT(qintsxy)) CALL gpu_cc_save_r(194, qintsxy, SIZE(qintsxy,KIND=8))
        IF (PRESENT(qintrxy)) CALL gpu_cc_save_r(195, qintrxy, SIZE(qintrxy,KIND=8))
        IF (PRESENT(qdripsxy)) CALL gpu_cc_save_r(196, qdripsxy, SIZE(qdripsxy,KIND=8))
        IF (PRESENT(qdriprxy)) CALL gpu_cc_save_r(197, qdriprxy, SIZE(qdriprxy,KIND=8))
        IF (PRESENT(qthrosxy)) CALL gpu_cc_save_r(198, qthrosxy, SIZE(qthrosxy,KIND=8))
        IF (PRESENT(qthrorxy)) CALL gpu_cc_save_r(199, qthrorxy, SIZE(qthrorxy,KIND=8))
        IF (PRESENT(qsnsubxy)) CALL gpu_cc_save_r(200, qsnsubxy, SIZE(qsnsubxy,KIND=8))
        IF (PRESENT(qsnfroxy)) CALL gpu_cc_save_r(201, qsnfroxy, SIZE(qsnfroxy,KIND=8))
        IF (PRESENT(qsubcxy)) CALL gpu_cc_save_r(202, qsubcxy, SIZE(qsubcxy,KIND=8))
        IF (PRESENT(qfrocxy)) CALL gpu_cc_save_r(203, qfrocxy, SIZE(qfrocxy,KIND=8))
        IF (PRESENT(qevacxy)) CALL gpu_cc_save_r(204, qevacxy, SIZE(qevacxy,KIND=8))
        IF (PRESENT(qdewcxy)) CALL gpu_cc_save_r(205, qdewcxy, SIZE(qdewcxy,KIND=8))
        IF (PRESENT(qfrzcxy)) CALL gpu_cc_save_r(206, qfrzcxy, SIZE(qfrzcxy,KIND=8))
        IF (PRESENT(qmeltcxy)) CALL gpu_cc_save_r(207, qmeltcxy, SIZE(qmeltcxy,KIND=8))
        IF (PRESENT(qsnbotxy)) CALL gpu_cc_save_r(208, qsnbotxy, SIZE(qsnbotxy,KIND=8))
        IF (PRESENT(pondingxy)) CALL gpu_cc_save_r(209, pondingxy, SIZE(pondingxy,KIND=8))
        IF (PRESENT(pahxy)) CALL gpu_cc_save_r(210, pahxy, SIZE(pahxy,KIND=8))
        IF (PRESENT(pahgxy)) CALL gpu_cc_save_r(211, pahgxy, SIZE(pahgxy,KIND=8))
        IF (PRESENT(pahvxy)) CALL gpu_cc_save_r(212, pahvxy, SIZE(pahvxy,KIND=8))
        IF (PRESENT(pahbxy)) CALL gpu_cc_save_r(213, pahbxy, SIZE(pahbxy,KIND=8))
        IF (PRESENT(qmeltxy)) CALL gpu_cc_save_r(214, qmeltxy, SIZE(qmeltxy,KIND=8))
        IF (PRESENT(fpicexy)) CALL gpu_cc_save_r(215, fpicexy, SIZE(fpicexy,KIND=8))
        IF (PRESENT(rainlsm)) CALL gpu_cc_save_r(216, rainlsm, SIZE(rainlsm,KIND=8))
        IF (PRESENT(snowlsm)) CALL gpu_cc_save_r(217, snowlsm, SIZE(snowlsm,KIND=8))
        IF (PRESENT(forctlsm)) CALL gpu_cc_save_r(218, forctlsm, SIZE(forctlsm,KIND=8))
        IF (PRESENT(forcqlsm)) CALL gpu_cc_save_r(219, forcqlsm, SIZE(forcqlsm,KIND=8))
        IF (PRESENT(forcplsm)) CALL gpu_cc_save_r(220, forcplsm, SIZE(forcplsm,KIND=8))
        IF (PRESENT(forczlsm)) CALL gpu_cc_save_r(221, forczlsm, SIZE(forczlsm,KIND=8))
        IF (PRESENT(forcwlsm)) CALL gpu_cc_save_r(222, forcwlsm, SIZE(forcwlsm,KIND=8))
        IF (PRESENT(acc_ssoil)) CALL gpu_cc_save_r(223, acc_ssoil, SIZE(acc_ssoil,KIND=8))
        IF (PRESENT(acc_qinsur)) CALL gpu_cc_save_r(224, acc_qinsur, SIZE(acc_qinsur,KIND=8))
        IF (PRESENT(acc_qseva)) CALL gpu_cc_save_r(225, acc_qseva, SIZE(acc_qseva,KIND=8))
        IF (PRESENT(acc_etrani)) CALL gpu_cc_save_r(226, acc_etrani, SIZE(acc_etrani,KIND=8))
        IF (PRESENT(eflxbxy)) CALL gpu_cc_save_r(227, eflxbxy, SIZE(eflxbxy,KIND=8))
        IF (PRESENT(soilenergy)) CALL gpu_cc_save_r(228, soilenergy, SIZE(soilenergy,KIND=8))
        IF (PRESENT(snowenergy)) CALL gpu_cc_save_r(229, snowenergy, SIZE(snowenergy,KIND=8))
        IF (PRESENT(canhsxy)) CALL gpu_cc_save_r(230, canhsxy, SIZE(canhsxy,KIND=8))
        IF (PRESENT(acc_dwaterxy)) CALL gpu_cc_save_r(231, acc_dwaterxy, SIZE(acc_dwaterxy,KIND=8))
        IF (PRESENT(acc_prcpxy)) CALL gpu_cc_save_r(232, acc_prcpxy, SIZE(acc_prcpxy,KIND=8))
        IF (PRESENT(acc_ecanxy)) CALL gpu_cc_save_r(233, acc_ecanxy, SIZE(acc_ecanxy,KIND=8))
        IF (PRESENT(acc_etranxy)) CALL gpu_cc_save_r(234, acc_etranxy, SIZE(acc_etranxy,KIND=8))
        IF (PRESENT(acc_edirxy)) CALL gpu_cc_save_r(235, acc_edirxy, SIZE(acc_edirxy,KIND=8))
        IF (PRESENT(irnumsi)) CALL gpu_cc_save_i(236, irnumsi, SIZE(irnumsi,KIND=8))
        IF (PRESENT(irnummi)) CALL gpu_cc_save_i(237, irnummi, SIZE(irnummi,KIND=8))
        IF (PRESENT(irnumfi)) CALL gpu_cc_save_i(238, irnumfi, SIZE(irnumfi,KIND=8))
        IF (PRESENT(irwatsi)) CALL gpu_cc_save_r(239, irwatsi, SIZE(irwatsi,KIND=8))
        IF (PRESENT(irwatmi)) CALL gpu_cc_save_r(240, irwatmi, SIZE(irwatmi,KIND=8))
        IF (PRESENT(irwatfi)) CALL gpu_cc_save_r(241, irwatfi, SIZE(irwatfi,KIND=8))
        IF (PRESENT(ireloss)) CALL gpu_cc_save_r(242, ireloss, SIZE(ireloss,KIND=8))
        IF (PRESENT(irsivol)) CALL gpu_cc_save_r(243, irsivol, SIZE(irsivol,KIND=8))
        IF (PRESENT(irmivol)) CALL gpu_cc_save_r(244, irmivol, SIZE(irmivol,KIND=8))
        IF (PRESENT(irfivol)) CALL gpu_cc_save_r(245, irfivol, SIZE(irfivol,KIND=8))
        IF (PRESENT(irrsplh)) CALL gpu_cc_save_r(246, irrsplh, SIZE(irrsplh,KIND=8))
        IF (PRESENT(qtdrain)) CALL gpu_cc_save_r(247, qtdrain, SIZE(qtdrain,KIND=8))
        IF (PRESENT(smcwtdxy)) CALL gpu_cc_save_r(248, smcwtdxy, SIZE(smcwtdxy,KIND=8))
        IF (PRESENT(rechxy)) CALL gpu_cc_save_r(249, rechxy, SIZE(rechxy,KIND=8))
        IF (PRESENT(deeprechxy)) CALL gpu_cc_save_r(250, deeprechxy, SIZE(deeprechxy,KIND=8))
        IF (PRESENT(fdepthxy)) CALL gpu_cc_save_r(251, fdepthxy, SIZE(fdepthxy,KIND=8))
        IF (PRESENT(areaxy)) CALL gpu_cc_save_r(252, areaxy, SIZE(areaxy,KIND=8))
        IF (PRESENT(rivercondxy)) CALL gpu_cc_save_r(253, rivercondxy, SIZE(rivercondxy,KIND=8))
        IF (PRESENT(riverbedxy)) CALL gpu_cc_save_r(254, riverbedxy, SIZE(riverbedxy,KIND=8))
        IF (PRESENT(eqzwt)) CALL gpu_cc_save_r(255, eqzwt, SIZE(eqzwt,KIND=8))
        IF (PRESENT(pexpxy)) CALL gpu_cc_save_r(256, pexpxy, SIZE(pexpxy,KIND=8))
        IF (PRESENT(qrfxy)) CALL gpu_cc_save_r(257, qrfxy, SIZE(qrfxy,KIND=8))
        IF (PRESENT(qspringxy)) CALL gpu_cc_save_r(258, qspringxy, SIZE(qspringxy,KIND=8))
        IF (PRESENT(qslatxy)) CALL gpu_cc_save_r(259, qslatxy, SIZE(qslatxy,KIND=8))
        IF (PRESENT(qrfsxy)) CALL gpu_cc_save_r(260, qrfsxy, SIZE(qrfsxy,KIND=8))
        IF (PRESENT(qlatxy)) CALL gpu_cc_save_r(261, qlatxy, SIZE(qlatxy,KIND=8))
        IF (PRESENT(qspringsxy)) CALL gpu_cc_save_r(262, qspringsxy, SIZE(qspringsxy,KIND=8))
        IF (PRESENT(smoiseq)) CALL gpu_cc_save_r(263, smoiseq, SIZE(smoiseq,KIND=8))
        IF (PRESENT(gecros_state)) CALL gpu_cc_save_r(264, gecros_state, SIZE(gecros_state,KIND=8))
        CALL gpu_cc_save_r(265, flx4, SIZE(flx4,KIND=8))
        CALL gpu_cc_save_r(266, fvb, SIZE(fvb,KIND=8))
        CALL gpu_cc_save_r(267, fbur, SIZE(fbur,KIND=8))
        CALL gpu_cc_save_r(268, fgsn, SIZE(fgsn,KIND=8))
        IF (PRESENT(ch)) CALL gpu_cc_save_r(269, ch, SIZE(ch,KIND=8))
        IF (PRESENT(fgdp)) CALL gpu_cc_save_r(270, fgdp, SIZE(fgdp,KIND=8))
        IF (PRESENT(dfgdp)) CALL gpu_cc_save_r(271, dfgdp, SIZE(dfgdp,KIND=8))
        IF (PRESENT(vdfg)) CALL gpu_cc_save_r(272, vdfg, SIZE(vdfg,KIND=8))
        CALL gpu_cc_save_r(273, water_depth, SIZE(water_depth,KIND=8))
        CALL gpu_cc_save_r(274, savedtke12d, SIZE(savedtke12d,KIND=8))
        CALL gpu_cc_save_r(275, snowdp2d, SIZE(snowdp2d,KIND=8))
        CALL gpu_cc_save_r(276, h2osno2d, SIZE(h2osno2d,KIND=8))
        CALL gpu_cc_save_r(277, snl2d, SIZE(snl2d,KIND=8))
        CALL gpu_cc_save_r(278, t_grnd2d, SIZE(t_grnd2d,KIND=8))
        CALL gpu_cc_save_r(279, t_lake3d, SIZE(t_lake3d,KIND=8))
        CALL gpu_cc_save_r(280, lake_icefrac3d, SIZE(lake_icefrac3d,KIND=8))
        CALL gpu_cc_save_r(281, t_soisno3d, SIZE(t_soisno3d,KIND=8))
        CALL gpu_cc_save_r(282, h2osoi_ice3d, SIZE(h2osoi_ice3d,KIND=8))
        CALL gpu_cc_save_r(283, h2osoi_liq3d, SIZE(h2osoi_liq3d,KIND=8))
        CALL gpu_cc_save_r(284, h2osoi_vol3d, SIZE(h2osoi_vol3d,KIND=8))
        CALL gpu_cc_save_r(285, z3d, SIZE(z3d,KIND=8))
        CALL gpu_cc_save_r(286, dz3d, SIZE(dz3d,KIND=8))
        CALL gpu_cc_save_r(287, zi3d, SIZE(zi3d,KIND=8))
        CALL gpu_cc_save_r(288, lakemask, SIZE(lakemask,KIND=8))
        IF (PRESENT(om_tmp)) CALL gpu_cc_save_r(289, om_tmp, SIZE(om_tmp,KIND=8))
        IF (PRESENT(om_s)) CALL gpu_cc_save_r(290, om_s, SIZE(om_s,KIND=8))
        IF (PRESENT(om_u)) CALL gpu_cc_save_r(291, om_u, SIZE(om_u,KIND=8))
        IF (PRESENT(om_v)) CALL gpu_cc_save_r(292, om_v, SIZE(om_v,KIND=8))
        IF (PRESENT(om_depth)) CALL gpu_cc_save_r(293, om_depth, SIZE(om_depth,KIND=8))
        IF (PRESENT(om_ml)) CALL gpu_cc_save_r(294, om_ml, SIZE(om_ml,KIND=8))
        IF (PRESENT(om_lon)) CALL gpu_cc_save_r(295, om_lon, SIZE(om_lon,KIND=8))
        IF (PRESENT(om_lat)) CALL gpu_cc_save_r(296, om_lat, SIZE(om_lat,KIND=8))
        CALL gpu_cc_save_i0(297, okms)
        CALL gpu_cc_save_i0(298, okme)
#if (WRF_CHEM == 1)
        IF (PRESENT(e_bio)) CALL gpu_cc_save_r(299, e_bio, SIZE(e_bio,KIND=8))
#endif
        IF (PRESENT(numc)) CALL gpu_cc_save_i(300, numc, SIZE(numc,KIND=8))
        IF (PRESENT(nump)) CALL gpu_cc_save_i(301, nump, SIZE(nump,KIND=8))
        IF (PRESENT(sabv)) CALL gpu_cc_save_r(302, sabv, SIZE(sabv,KIND=8))
        IF (PRESENT(sabg)) CALL gpu_cc_save_r(303, sabg, SIZE(sabg,KIND=8))
        IF (PRESENT(lwup)) CALL gpu_cc_save_r(304, lwup, SIZE(lwup,KIND=8))
        IF (PRESENT(snl)) CALL gpu_cc_save_i(305, snl, SIZE(snl,KIND=8))
        IF (PRESENT(snowdp)) CALL gpu_cc_save_r(306, snowdp, SIZE(snowdp,KIND=8))
        IF (PRESENT(wtc)) CALL gpu_cc_save_r(307, wtc, SIZE(wtc,KIND=8))
        IF (PRESENT(wtp)) CALL gpu_cc_save_r(308, wtp, SIZE(wtp,KIND=8))
        IF (PRESENT(h2osno)) CALL gpu_cc_save_r(309, h2osno, SIZE(h2osno,KIND=8))
        IF (PRESENT(t_grnd)) CALL gpu_cc_save_r(310, t_grnd, SIZE(t_grnd,KIND=8))
        IF (PRESENT(t_veg)) CALL gpu_cc_save_r(311, t_veg, SIZE(t_veg,KIND=8))
        IF (PRESENT(h2ocan)) CALL gpu_cc_save_r(312, h2ocan, SIZE(h2ocan,KIND=8))
        IF (PRESENT(h2ocan_col)) CALL gpu_cc_save_r(313, h2ocan_col, SIZE(h2ocan_col,KIND=8))
        IF (PRESENT(t2m_max)) CALL gpu_cc_save_r(314, t2m_max, SIZE(t2m_max,KIND=8))
        IF (PRESENT(t2m_min)) CALL gpu_cc_save_r(315, t2m_min, SIZE(t2m_min,KIND=8))
        IF (PRESENT(t2clm)) CALL gpu_cc_save_r(316, t2clm, SIZE(t2clm,KIND=8))
        IF (PRESENT(t_ref2m)) CALL gpu_cc_save_r(317, t_ref2m, SIZE(t_ref2m,KIND=8))
        IF (PRESENT(h2osoi_liq_s1)) CALL gpu_cc_save_r(318, h2osoi_liq_s1, SIZE(h2osoi_liq_s1,KIND=8))
        IF (PRESENT(h2osoi_liq_s2)) CALL gpu_cc_save_r(319, h2osoi_liq_s2, SIZE(h2osoi_liq_s2,KIND=8))
        IF (PRESENT(h2osoi_liq_s3)) CALL gpu_cc_save_r(320, h2osoi_liq_s3, SIZE(h2osoi_liq_s3,KIND=8))
        IF (PRESENT(h2osoi_liq_s4)) CALL gpu_cc_save_r(321, h2osoi_liq_s4, SIZE(h2osoi_liq_s4,KIND=8))
        IF (PRESENT(h2osoi_liq_s5)) CALL gpu_cc_save_r(322, h2osoi_liq_s5, SIZE(h2osoi_liq_s5,KIND=8))
        IF (PRESENT(h2osoi_liq1)) CALL gpu_cc_save_r(323, h2osoi_liq1, SIZE(h2osoi_liq1,KIND=8))
        IF (PRESENT(h2osoi_liq2)) CALL gpu_cc_save_r(324, h2osoi_liq2, SIZE(h2osoi_liq2,KIND=8))
        IF (PRESENT(h2osoi_liq3)) CALL gpu_cc_save_r(325, h2osoi_liq3, SIZE(h2osoi_liq3,KIND=8))
        IF (PRESENT(h2osoi_liq4)) CALL gpu_cc_save_r(326, h2osoi_liq4, SIZE(h2osoi_liq4,KIND=8))
        IF (PRESENT(h2osoi_liq5)) CALL gpu_cc_save_r(327, h2osoi_liq5, SIZE(h2osoi_liq5,KIND=8))
        IF (PRESENT(h2osoi_liq6)) CALL gpu_cc_save_r(328, h2osoi_liq6, SIZE(h2osoi_liq6,KIND=8))
        IF (PRESENT(h2osoi_liq7)) CALL gpu_cc_save_r(329, h2osoi_liq7, SIZE(h2osoi_liq7,KIND=8))
        IF (PRESENT(h2osoi_liq8)) CALL gpu_cc_save_r(330, h2osoi_liq8, SIZE(h2osoi_liq8,KIND=8))
        IF (PRESENT(h2osoi_liq9)) CALL gpu_cc_save_r(331, h2osoi_liq9, SIZE(h2osoi_liq9,KIND=8))
        IF (PRESENT(h2osoi_liq10)) CALL gpu_cc_save_r(332, h2osoi_liq10, SIZE(h2osoi_liq10,KIND=8))
        IF (PRESENT(h2osoi_ice_s1)) CALL gpu_cc_save_r(333, h2osoi_ice_s1, SIZE(h2osoi_ice_s1,KIND=8))
        IF (PRESENT(h2osoi_ice_s2)) CALL gpu_cc_save_r(334, h2osoi_ice_s2, SIZE(h2osoi_ice_s2,KIND=8))
        IF (PRESENT(h2osoi_ice_s3)) CALL gpu_cc_save_r(335, h2osoi_ice_s3, SIZE(h2osoi_ice_s3,KIND=8))
        IF (PRESENT(h2osoi_ice_s4)) CALL gpu_cc_save_r(336, h2osoi_ice_s4, SIZE(h2osoi_ice_s4,KIND=8))
        IF (PRESENT(h2osoi_ice_s5)) CALL gpu_cc_save_r(337, h2osoi_ice_s5, SIZE(h2osoi_ice_s5,KIND=8))
        IF (PRESENT(h2osoi_ice1)) CALL gpu_cc_save_r(338, h2osoi_ice1, SIZE(h2osoi_ice1,KIND=8))
        IF (PRESENT(h2osoi_ice2)) CALL gpu_cc_save_r(339, h2osoi_ice2, SIZE(h2osoi_ice2,KIND=8))
        IF (PRESENT(h2osoi_ice3)) CALL gpu_cc_save_r(340, h2osoi_ice3, SIZE(h2osoi_ice3,KIND=8))
        IF (PRESENT(h2osoi_ice4)) CALL gpu_cc_save_r(341, h2osoi_ice4, SIZE(h2osoi_ice4,KIND=8))
        IF (PRESENT(h2osoi_ice5)) CALL gpu_cc_save_r(342, h2osoi_ice5, SIZE(h2osoi_ice5,KIND=8))
        IF (PRESENT(h2osoi_ice6)) CALL gpu_cc_save_r(343, h2osoi_ice6, SIZE(h2osoi_ice6,KIND=8))
        IF (PRESENT(h2osoi_ice7)) CALL gpu_cc_save_r(344, h2osoi_ice7, SIZE(h2osoi_ice7,KIND=8))
        IF (PRESENT(h2osoi_ice8)) CALL gpu_cc_save_r(345, h2osoi_ice8, SIZE(h2osoi_ice8,KIND=8))
        IF (PRESENT(h2osoi_ice9)) CALL gpu_cc_save_r(346, h2osoi_ice9, SIZE(h2osoi_ice9,KIND=8))
        IF (PRESENT(h2osoi_ice10)) CALL gpu_cc_save_r(347, h2osoi_ice10, SIZE(h2osoi_ice10,KIND=8))
        IF (PRESENT(t_soisno_s1)) CALL gpu_cc_save_r(348, t_soisno_s1, SIZE(t_soisno_s1,KIND=8))
        IF (PRESENT(t_soisno_s2)) CALL gpu_cc_save_r(349, t_soisno_s2, SIZE(t_soisno_s2,KIND=8))
        IF (PRESENT(t_soisno_s3)) CALL gpu_cc_save_r(350, t_soisno_s3, SIZE(t_soisno_s3,KIND=8))
        IF (PRESENT(t_soisno_s4)) CALL gpu_cc_save_r(351, t_soisno_s4, SIZE(t_soisno_s4,KIND=8))
        IF (PRESENT(t_soisno_s5)) CALL gpu_cc_save_r(352, t_soisno_s5, SIZE(t_soisno_s5,KIND=8))
        IF (PRESENT(t_soisno1)) CALL gpu_cc_save_r(353, t_soisno1, SIZE(t_soisno1,KIND=8))
        IF (PRESENT(t_soisno2)) CALL gpu_cc_save_r(354, t_soisno2, SIZE(t_soisno2,KIND=8))
        IF (PRESENT(t_soisno3)) CALL gpu_cc_save_r(355, t_soisno3, SIZE(t_soisno3,KIND=8))
        IF (PRESENT(t_soisno4)) CALL gpu_cc_save_r(356, t_soisno4, SIZE(t_soisno4,KIND=8))
        IF (PRESENT(t_soisno5)) CALL gpu_cc_save_r(357, t_soisno5, SIZE(t_soisno5,KIND=8))
        IF (PRESENT(t_soisno6)) CALL gpu_cc_save_r(358, t_soisno6, SIZE(t_soisno6,KIND=8))
        IF (PRESENT(t_soisno7)) CALL gpu_cc_save_r(359, t_soisno7, SIZE(t_soisno7,KIND=8))
        IF (PRESENT(t_soisno8)) CALL gpu_cc_save_r(360, t_soisno8, SIZE(t_soisno8,KIND=8))
        IF (PRESENT(t_soisno9)) CALL gpu_cc_save_r(361, t_soisno9, SIZE(t_soisno9,KIND=8))
        IF (PRESENT(t_soisno10)) CALL gpu_cc_save_r(362, t_soisno10, SIZE(t_soisno10,KIND=8))
        IF (PRESENT(dzsnow1)) CALL gpu_cc_save_r(363, dzsnow1, SIZE(dzsnow1,KIND=8))
        IF (PRESENT(dzsnow2)) CALL gpu_cc_save_r(364, dzsnow2, SIZE(dzsnow2,KIND=8))
        IF (PRESENT(dzsnow3)) CALL gpu_cc_save_r(365, dzsnow3, SIZE(dzsnow3,KIND=8))
        IF (PRESENT(dzsnow4)) CALL gpu_cc_save_r(366, dzsnow4, SIZE(dzsnow4,KIND=8))
        IF (PRESENT(dzsnow5)) CALL gpu_cc_save_r(367, dzsnow5, SIZE(dzsnow5,KIND=8))
        IF (PRESENT(snowrds1)) CALL gpu_cc_save_r(368, snowrds1, SIZE(snowrds1,KIND=8))
        IF (PRESENT(snowrds2)) CALL gpu_cc_save_r(369, snowrds2, SIZE(snowrds2,KIND=8))
        IF (PRESENT(snowrds3)) CALL gpu_cc_save_r(370, snowrds3, SIZE(snowrds3,KIND=8))
        IF (PRESENT(snowrds4)) CALL gpu_cc_save_r(371, snowrds4, SIZE(snowrds4,KIND=8))
        IF (PRESENT(snowrds5)) CALL gpu_cc_save_r(372, snowrds5, SIZE(snowrds5,KIND=8))
        IF (PRESENT(t_lake1)) CALL gpu_cc_save_r(373, t_lake1, SIZE(t_lake1,KIND=8))
        IF (PRESENT(t_lake2)) CALL gpu_cc_save_r(374, t_lake2, SIZE(t_lake2,KIND=8))
        IF (PRESENT(t_lake3)) CALL gpu_cc_save_r(375, t_lake3, SIZE(t_lake3,KIND=8))
        IF (PRESENT(t_lake4)) CALL gpu_cc_save_r(376, t_lake4, SIZE(t_lake4,KIND=8))
        IF (PRESENT(t_lake5)) CALL gpu_cc_save_r(377, t_lake5, SIZE(t_lake5,KIND=8))
        IF (PRESENT(t_lake6)) CALL gpu_cc_save_r(378, t_lake6, SIZE(t_lake6,KIND=8))
        IF (PRESENT(t_lake7)) CALL gpu_cc_save_r(379, t_lake7, SIZE(t_lake7,KIND=8))
        IF (PRESENT(t_lake8)) CALL gpu_cc_save_r(380, t_lake8, SIZE(t_lake8,KIND=8))
        IF (PRESENT(t_lake9)) CALL gpu_cc_save_r(381, t_lake9, SIZE(t_lake9,KIND=8))
        IF (PRESENT(t_lake10)) CALL gpu_cc_save_r(382, t_lake10, SIZE(t_lake10,KIND=8))
        IF (PRESENT(h2osoi_vol1)) CALL gpu_cc_save_r(383, h2osoi_vol1, SIZE(h2osoi_vol1,KIND=8))
        IF (PRESENT(h2osoi_vol2)) CALL gpu_cc_save_r(384, h2osoi_vol2, SIZE(h2osoi_vol2,KIND=8))
        IF (PRESENT(h2osoi_vol3)) CALL gpu_cc_save_r(385, h2osoi_vol3, SIZE(h2osoi_vol3,KIND=8))
        IF (PRESENT(h2osoi_vol4)) CALL gpu_cc_save_r(386, h2osoi_vol4, SIZE(h2osoi_vol4,KIND=8))
        IF (PRESENT(h2osoi_vol5)) CALL gpu_cc_save_r(387, h2osoi_vol5, SIZE(h2osoi_vol5,KIND=8))
        IF (PRESENT(h2osoi_vol6)) CALL gpu_cc_save_r(388, h2osoi_vol6, SIZE(h2osoi_vol6,KIND=8))
        IF (PRESENT(h2osoi_vol7)) CALL gpu_cc_save_r(389, h2osoi_vol7, SIZE(h2osoi_vol7,KIND=8))
        IF (PRESENT(h2osoi_vol8)) CALL gpu_cc_save_r(390, h2osoi_vol8, SIZE(h2osoi_vol8,KIND=8))
        IF (PRESENT(h2osoi_vol9)) CALL gpu_cc_save_r(391, h2osoi_vol9, SIZE(h2osoi_vol9,KIND=8))
        IF (PRESENT(h2osoi_vol10)) CALL gpu_cc_save_r(392, h2osoi_vol10, SIZE(h2osoi_vol10,KIND=8))
        IF (PRESENT(albedosubgrid)) CALL gpu_cc_save_r(393, albedosubgrid, SIZE(albedosubgrid,KIND=8))
        IF (PRESENT(lhsubgrid)) CALL gpu_cc_save_r(394, lhsubgrid, SIZE(lhsubgrid,KIND=8))
        IF (PRESENT(hfxsubgrid)) CALL gpu_cc_save_r(395, hfxsubgrid, SIZE(hfxsubgrid,KIND=8))
        IF (PRESENT(lwupsubgrid)) CALL gpu_cc_save_r(396, lwupsubgrid, SIZE(lwupsubgrid,KIND=8))
        IF (PRESENT(q2subgrid)) CALL gpu_cc_save_r(397, q2subgrid, SIZE(q2subgrid,KIND=8))
        IF (PRESENT(sabvsubgrid)) CALL gpu_cc_save_r(398, sabvsubgrid, SIZE(sabvsubgrid,KIND=8))
        IF (PRESENT(sabgsubgrid)) CALL gpu_cc_save_r(399, sabgsubgrid, SIZE(sabgsubgrid,KIND=8))
        IF (PRESENT(nrasubgrid)) CALL gpu_cc_save_r(400, nrasubgrid, SIZE(nrasubgrid,KIND=8))
        IF (PRESENT(swupsubgrid)) CALL gpu_cc_save_r(401, swupsubgrid, SIZE(swupsubgrid,KIND=8))
        IF (PRESENT(lhsoi)) CALL gpu_cc_save_r(402, lhsoi, SIZE(lhsoi,KIND=8))
        IF (PRESENT(lhveg)) CALL gpu_cc_save_r(403, lhveg, SIZE(lhveg,KIND=8))
        IF (PRESENT(lhtran)) CALL gpu_cc_save_r(404, lhtran, SIZE(lhtran,KIND=8))
        IF (PRESENT(t_veg24)) CALL gpu_cc_save_r(405, t_veg24, SIZE(t_veg24,KIND=8))
        IF (PRESENT(t_veg240)) CALL gpu_cc_save_r(406, t_veg240, SIZE(t_veg240,KIND=8))
        IF (PRESENT(fsun24)) CALL gpu_cc_save_r(407, fsun24, SIZE(fsun24,KIND=8))
        IF (PRESENT(fsun240)) CALL gpu_cc_save_r(408, fsun240, SIZE(fsun240,KIND=8))
        IF (PRESENT(fsd24)) CALL gpu_cc_save_r(409, fsd24, SIZE(fsd24,KIND=8))
        IF (PRESENT(fsd240)) CALL gpu_cc_save_r(410, fsd240, SIZE(fsd240,KIND=8))
        IF (PRESENT(fsi24)) CALL gpu_cc_save_r(411, fsi24, SIZE(fsi24,KIND=8))
        IF (PRESENT(fsi240)) CALL gpu_cc_save_r(412, fsi240, SIZE(fsi240,KIND=8))
        IF (PRESENT(laip)) CALL gpu_cc_save_r(413, laip, SIZE(laip,KIND=8))
#ifdef CN
        IF (PRESENT(dyntlai)) CALL gpu_cc_save_r(414, dyntlai, SIZE(dyntlai,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dyntsai)) CALL gpu_cc_save_r(415, dyntsai, SIZE(dyntsai,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dyntop)) CALL gpu_cc_save_r(416, dyntop, SIZE(dyntop,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dynbot)) CALL gpu_cc_save_r(417, dynbot, SIZE(dynbot,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(htmx)) CALL gpu_cc_save_r(418, htmx, SIZE(htmx,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(croplive)) CALL gpu_cc_save_i(419, croplive, SIZE(croplive,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(gdd1020)) CALL gpu_cc_save_r(420, gdd1020, SIZE(gdd1020,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(gdd820)) CALL gpu_cc_save_r(421, gdd820, SIZE(gdd820,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(gdd020)) CALL gpu_cc_save_r(422, gdd020, SIZE(gdd020,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(grainc)) CALL gpu_cc_save_r(423, grainc, SIZE(grainc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(grainc_storage)) CALL gpu_cc_save_r(424, grainc_storage, SIZE(grainc_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(grainc_xfer)) CALL gpu_cc_save_r(425, grainc_xfer, SIZE(grainc_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(grainn)) CALL gpu_cc_save_r(426, grainn, SIZE(grainn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(grainn_storage)) CALL gpu_cc_save_r(427, grainn_storage, SIZE(grainn_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(grainn_xfer)) CALL gpu_cc_save_r(428, grainn_xfer, SIZE(grainn_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(days_active)) CALL gpu_cc_save_r(429, days_active, SIZE(days_active,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(onset_flag)) CALL gpu_cc_save_r(430, onset_flag, SIZE(onset_flag,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(onset_counter)) CALL gpu_cc_save_r(431, onset_counter, SIZE(onset_counter,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(onset_gddflag)) CALL gpu_cc_save_r(432, onset_gddflag, SIZE(onset_gddflag,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(onset_fdd)) CALL gpu_cc_save_r(433, onset_fdd, SIZE(onset_fdd,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(onset_gdd)) CALL gpu_cc_save_r(434, onset_gdd, SIZE(onset_gdd,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(onset_swi)) CALL gpu_cc_save_r(435, onset_swi, SIZE(onset_swi,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(offset_flag)) CALL gpu_cc_save_r(436, offset_flag, SIZE(offset_flag,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(offset_counter)) CALL gpu_cc_save_r(437, offset_counter, SIZE(offset_counter,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(offset_fdd)) CALL gpu_cc_save_r(438, offset_fdd, SIZE(offset_fdd,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(offset_swi)) CALL gpu_cc_save_r(439, offset_swi, SIZE(offset_swi,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dayl)) CALL gpu_cc_save_r(440, dayl, SIZE(dayl,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(annavg_t2m)) CALL gpu_cc_save_r(441, annavg_t2m, SIZE(annavg_t2m,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(tempavg_t2m)) CALL gpu_cc_save_r(442, tempavg_t2m, SIZE(tempavg_t2m,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(tempsum_potential_gpp)) CALL gpu_cc_save_r(443, tempsum_potential_gpp, SIZE(tempsum_potential_gpp,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(annsum_potential_gpp)) CALL gpu_cc_save_r(444, annsum_potential_gpp, SIZE(annsum_potential_gpp,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(tempmax_retransn)) CALL gpu_cc_save_r(445, tempmax_retransn, SIZE(tempmax_retransn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(annmax_retransn)) CALL gpu_cc_save_r(446, annmax_retransn, SIZE(annmax_retransn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(prev_leafc_to_litter)) CALL gpu_cc_save_r(447, prev_leafc_to_litter, SIZE(prev_leafc_to_litter,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(prev_frootc_to_litter)) CALL gpu_cc_save_r(448, prev_frootc_to_litter, SIZE(prev_frootc_to_litter,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(tempsum_npp)) CALL gpu_cc_save_r(449, tempsum_npp, SIZE(tempsum_npp,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(annsum_npp)) CALL gpu_cc_save_r(450, annsum_npp, SIZE(annsum_npp,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(leafc)) CALL gpu_cc_save_r(451, leafc, SIZE(leafc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(leafc_storage)) CALL gpu_cc_save_r(452, leafc_storage, SIZE(leafc_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(leafc_xfer)) CALL gpu_cc_save_r(453, leafc_xfer, SIZE(leafc_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(frootc)) CALL gpu_cc_save_r(454, frootc, SIZE(frootc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(frootc_storage)) CALL gpu_cc_save_r(455, frootc_storage, SIZE(frootc_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(frootc_xfer)) CALL gpu_cc_save_r(456, frootc_xfer, SIZE(frootc_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livestemc)) CALL gpu_cc_save_r(457, livestemc, SIZE(livestemc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livestemc_storage)) CALL gpu_cc_save_r(458, livestemc_storage, SIZE(livestemc_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livestemc_xfer)) CALL gpu_cc_save_r(459, livestemc_xfer, SIZE(livestemc_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadstemc)) CALL gpu_cc_save_r(460, deadstemc, SIZE(deadstemc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadstemc_storage)) CALL gpu_cc_save_r(461, deadstemc_storage, SIZE(deadstemc_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadstemc_xfer)) CALL gpu_cc_save_r(462, deadstemc_xfer, SIZE(deadstemc_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livecrootc)) CALL gpu_cc_save_r(463, livecrootc, SIZE(livecrootc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livecrootc_storage)) CALL gpu_cc_save_r(464, livecrootc_storage, SIZE(livecrootc_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livecrootc_xfer)) CALL gpu_cc_save_r(465, livecrootc_xfer, SIZE(livecrootc_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadcrootc)) CALL gpu_cc_save_r(466, deadcrootc, SIZE(deadcrootc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadcrootc_storage)) CALL gpu_cc_save_r(467, deadcrootc_storage, SIZE(deadcrootc_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadcrootc_xfer)) CALL gpu_cc_save_r(468, deadcrootc_xfer, SIZE(deadcrootc_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(cpool)) CALL gpu_cc_save_r(469, cpool, SIZE(cpool,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(pft_ctrunc)) CALL gpu_cc_save_r(470, pft_ctrunc, SIZE(pft_ctrunc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(leafn)) CALL gpu_cc_save_r(471, leafn, SIZE(leafn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(leafn_storage)) CALL gpu_cc_save_r(472, leafn_storage, SIZE(leafn_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(leafn_xfer)) CALL gpu_cc_save_r(473, leafn_xfer, SIZE(leafn_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(frootn)) CALL gpu_cc_save_r(474, frootn, SIZE(frootn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(frootn_storage)) CALL gpu_cc_save_r(475, frootn_storage, SIZE(frootn_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(frootn_xfer)) CALL gpu_cc_save_r(476, frootn_xfer, SIZE(frootn_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livestemn)) CALL gpu_cc_save_r(477, livestemn, SIZE(livestemn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livestemn_storage)) CALL gpu_cc_save_r(478, livestemn_storage, SIZE(livestemn_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livestemn_xfer)) CALL gpu_cc_save_r(479, livestemn_xfer, SIZE(livestemn_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadstemn)) CALL gpu_cc_save_r(480, deadstemn, SIZE(deadstemn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadstemn_storage)) CALL gpu_cc_save_r(481, deadstemn_storage, SIZE(deadstemn_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadstemn_xfer)) CALL gpu_cc_save_r(482, deadstemn_xfer, SIZE(deadstemn_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livecrootn)) CALL gpu_cc_save_r(483, livecrootn, SIZE(livecrootn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livecrootn_storage)) CALL gpu_cc_save_r(484, livecrootn_storage, SIZE(livecrootn_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(livecrootn_xfer)) CALL gpu_cc_save_r(485, livecrootn_xfer, SIZE(livecrootn_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadcrootn)) CALL gpu_cc_save_r(486, deadcrootn, SIZE(deadcrootn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadcrootn_storage)) CALL gpu_cc_save_r(487, deadcrootn_storage, SIZE(deadcrootn_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(deadcrootn_xfer)) CALL gpu_cc_save_r(488, deadcrootn_xfer, SIZE(deadcrootn_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(npool)) CALL gpu_cc_save_r(489, npool, SIZE(npool,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(pft_ntrunc)) CALL gpu_cc_save_r(490, pft_ntrunc, SIZE(pft_ntrunc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(gresp_storage)) CALL gpu_cc_save_r(491, gresp_storage, SIZE(gresp_storage,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(gresp_xfer)) CALL gpu_cc_save_r(492, gresp_xfer, SIZE(gresp_xfer,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(xsmrpool)) CALL gpu_cc_save_r(493, xsmrpool, SIZE(xsmrpool,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(annsum_counter)) CALL gpu_cc_save_r(494, annsum_counter, SIZE(annsum_counter,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(cannsum_npp)) CALL gpu_cc_save_r(495, cannsum_npp, SIZE(cannsum_npp,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(cannavg_t2m)) CALL gpu_cc_save_r(496, cannavg_t2m, SIZE(cannavg_t2m,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(wf)) CALL gpu_cc_save_r(497, wf, SIZE(wf,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(me)) CALL gpu_cc_save_r(498, me, SIZE(me,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(mean_fire_prob)) CALL gpu_cc_save_r(499, mean_fire_prob, SIZE(mean_fire_prob,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(cwdc)) CALL gpu_cc_save_r(500, cwdc, SIZE(cwdc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(litr1c)) CALL gpu_cc_save_r(501, litr1c, SIZE(litr1c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(litr2c)) CALL gpu_cc_save_r(502, litr2c, SIZE(litr2c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(litr3c)) CALL gpu_cc_save_r(503, litr3c, SIZE(litr3c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(soil1c)) CALL gpu_cc_save_r(504, soil1c, SIZE(soil1c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(soil2c)) CALL gpu_cc_save_r(505, soil2c, SIZE(soil2c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(soil3c)) CALL gpu_cc_save_r(506, soil3c, SIZE(soil3c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(soil4c)) CALL gpu_cc_save_r(507, soil4c, SIZE(soil4c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(seedc)) CALL gpu_cc_save_r(508, seedc, SIZE(seedc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(col_ctrunc)) CALL gpu_cc_save_r(509, col_ctrunc, SIZE(col_ctrunc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(prod10c)) CALL gpu_cc_save_r(510, prod10c, SIZE(prod10c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(prod100c)) CALL gpu_cc_save_r(511, prod100c, SIZE(prod100c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(cwdn)) CALL gpu_cc_save_r(512, cwdn, SIZE(cwdn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(litr1n)) CALL gpu_cc_save_r(513, litr1n, SIZE(litr1n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(litr2n)) CALL gpu_cc_save_r(514, litr2n, SIZE(litr2n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(litr3n)) CALL gpu_cc_save_r(515, litr3n, SIZE(litr3n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(soil1n)) CALL gpu_cc_save_r(516, soil1n, SIZE(soil1n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(soil2n)) CALL gpu_cc_save_r(517, soil2n, SIZE(soil2n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(soil3n)) CALL gpu_cc_save_r(518, soil3n, SIZE(soil3n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(soil4n)) CALL gpu_cc_save_r(519, soil4n, SIZE(soil4n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(seedn)) CALL gpu_cc_save_r(520, seedn, SIZE(seedn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(col_ntrunc)) CALL gpu_cc_save_r(521, col_ntrunc, SIZE(col_ntrunc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(prod10n)) CALL gpu_cc_save_r(522, prod10n, SIZE(prod10n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(prod100n)) CALL gpu_cc_save_r(523, prod100n, SIZE(prod100n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(sminn)) CALL gpu_cc_save_r(524, sminn, SIZE(sminn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(totlitc)) CALL gpu_cc_save_r(525, totlitc, SIZE(totlitc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_seedc_to_leaf)) CALL gpu_cc_save_r(526, dwt_seedc_to_leaf, SIZE(dwt_seedc_to_leaf,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_seedc_to_deadstem)) CALL gpu_cc_save_r(527, dwt_seedc_to_deadstem, SIZE(dwt_seedc_to_deadstem,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_conv_cflux)) CALL gpu_cc_save_r(528, dwt_conv_cflux, SIZE(dwt_conv_cflux,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_prod10c_gain)) CALL gpu_cc_save_r(529, dwt_prod10c_gain, SIZE(dwt_prod10c_gain,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_prod100c_gain)) CALL gpu_cc_save_r(530, dwt_prod100c_gain, SIZE(dwt_prod100c_gain,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(prod100c_loss)) CALL gpu_cc_save_r(531, prod100c_loss, SIZE(prod100c_loss,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootc_to_litr1c)) CALL gpu_cc_save_r(532, dwt_frootc_to_litr1c, SIZE(dwt_frootc_to_litr1c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootc_to_litr2c)) CALL gpu_cc_save_r(533, dwt_frootc_to_litr2c, SIZE(dwt_frootc_to_litr2c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootc_to_litr3c)) CALL gpu_cc_save_r(534, dwt_frootc_to_litr3c, SIZE(dwt_frootc_to_litr3c,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_livecrootc_to_cwdc)) CALL gpu_cc_save_r(535, dwt_livecrootc_to_cwdc, SIZE(dwt_livecrootc_to_cwdc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_deadcrootc_to_cwdc)) CALL gpu_cc_save_r(536, dwt_deadcrootc_to_cwdc, SIZE(dwt_deadcrootc_to_cwdc,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_seedn_to_leaf)) CALL gpu_cc_save_r(537, dwt_seedn_to_leaf, SIZE(dwt_seedn_to_leaf,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_seedn_to_deadstem)) CALL gpu_cc_save_r(538, dwt_seedn_to_deadstem, SIZE(dwt_seedn_to_deadstem,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_conv_nflux)) CALL gpu_cc_save_r(539, dwt_conv_nflux, SIZE(dwt_conv_nflux,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_prod10n_gain)) CALL gpu_cc_save_r(540, dwt_prod10n_gain, SIZE(dwt_prod10n_gain,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_prod100n_gain)) CALL gpu_cc_save_r(541, dwt_prod100n_gain, SIZE(dwt_prod100n_gain,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(prod100n_loss)) CALL gpu_cc_save_r(542, prod100n_loss, SIZE(prod100n_loss,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootn_to_litr1n)) CALL gpu_cc_save_r(543, dwt_frootn_to_litr1n, SIZE(dwt_frootn_to_litr1n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootn_to_litr2n)) CALL gpu_cc_save_r(544, dwt_frootn_to_litr2n, SIZE(dwt_frootn_to_litr2n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootn_to_litr3n)) CALL gpu_cc_save_r(545, dwt_frootn_to_litr3n, SIZE(dwt_frootn_to_litr3n,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_livecrootn_to_cwdn)) CALL gpu_cc_save_r(546, dwt_livecrootn_to_cwdn, SIZE(dwt_livecrootn_to_cwdn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(dwt_deadcrootn_to_cwdn)) CALL gpu_cc_save_r(547, dwt_deadcrootn_to_cwdn, SIZE(dwt_deadcrootn_to_cwdn,KIND=8))
#endif
#ifdef CN
        IF (PRESENT(retransn)) CALL gpu_cc_save_r(548, retransn, SIZE(retransn,KIND=8))
#endif
        IF (PRESENT(swnorm)) CALL gpu_cc_save_r(549, swnorm, SIZE(swnorm,KIND=8))
        IF (PRESENT(tr_urb2d)) CALL gpu_cc_save_r(550, tr_urb2d, SIZE(tr_urb2d,KIND=8))
        IF (PRESENT(tb_urb2d)) CALL gpu_cc_save_r(551, tb_urb2d, SIZE(tb_urb2d,KIND=8))
        IF (PRESENT(tg_urb2d)) CALL gpu_cc_save_r(552, tg_urb2d, SIZE(tg_urb2d,KIND=8))
        IF (PRESENT(tc_urb2d)) CALL gpu_cc_save_r(553, tc_urb2d, SIZE(tc_urb2d,KIND=8))
        IF (PRESENT(qc_urb2d)) CALL gpu_cc_save_r(554, qc_urb2d, SIZE(qc_urb2d,KIND=8))
        IF (PRESENT(uc_urb2d)) CALL gpu_cc_save_r(555, uc_urb2d, SIZE(uc_urb2d,KIND=8))
        IF (PRESENT(xxxr_urb2d)) CALL gpu_cc_save_r(556, xxxr_urb2d, SIZE(xxxr_urb2d,KIND=8))
        IF (PRESENT(xxxb_urb2d)) CALL gpu_cc_save_r(557, xxxb_urb2d, SIZE(xxxb_urb2d,KIND=8))
        IF (PRESENT(xxxg_urb2d)) CALL gpu_cc_save_r(558, xxxg_urb2d, SIZE(xxxg_urb2d,KIND=8))
        IF (PRESENT(xxxc_urb2d)) CALL gpu_cc_save_r(559, xxxc_urb2d, SIZE(xxxc_urb2d,KIND=8))
        IF (PRESENT(cmcr_urb2d)) CALL gpu_cc_save_r(560, cmcr_urb2d, SIZE(cmcr_urb2d,KIND=8))
        IF (PRESENT(tgr_urb2d)) CALL gpu_cc_save_r(561, tgr_urb2d, SIZE(tgr_urb2d,KIND=8))
        IF (PRESENT(tgrl_urb3d)) CALL gpu_cc_save_r(562, tgrl_urb3d, SIZE(tgrl_urb3d,KIND=8))
        IF (PRESENT(smr_urb3d)) CALL gpu_cc_save_r(563, smr_urb3d, SIZE(smr_urb3d,KIND=8))
        IF (PRESENT(drelr_urb2d)) CALL gpu_cc_save_r(564, drelr_urb2d, SIZE(drelr_urb2d,KIND=8))
        IF (PRESENT(drelb_urb2d)) CALL gpu_cc_save_r(565, drelb_urb2d, SIZE(drelb_urb2d,KIND=8))
        IF (PRESENT(drelg_urb2d)) CALL gpu_cc_save_r(566, drelg_urb2d, SIZE(drelg_urb2d,KIND=8))
        IF (PRESENT(flxhumr_urb2d)) CALL gpu_cc_save_r(567, flxhumr_urb2d, SIZE(flxhumr_urb2d,KIND=8))
        IF (PRESENT(flxhumb_urb2d)) CALL gpu_cc_save_r(568, flxhumb_urb2d, SIZE(flxhumb_urb2d,KIND=8))
        IF (PRESENT(flxhumg_urb2d)) CALL gpu_cc_save_r(569, flxhumg_urb2d, SIZE(flxhumg_urb2d,KIND=8))
        IF (PRESENT(trl_urb3d)) CALL gpu_cc_save_r(570, trl_urb3d, SIZE(trl_urb3d,KIND=8))
        IF (PRESENT(tbl_urb3d)) CALL gpu_cc_save_r(571, tbl_urb3d, SIZE(tbl_urb3d,KIND=8))
        IF (PRESENT(tgl_urb3d)) CALL gpu_cc_save_r(572, tgl_urb3d, SIZE(tgl_urb3d,KIND=8))
        IF (PRESENT(sh_urb2d)) CALL gpu_cc_save_r(573, sh_urb2d, SIZE(sh_urb2d,KIND=8))
        IF (PRESENT(lh_urb2d)) CALL gpu_cc_save_r(574, lh_urb2d, SIZE(lh_urb2d,KIND=8))
        IF (PRESENT(g_urb2d)) CALL gpu_cc_save_r(575, g_urb2d, SIZE(g_urb2d,KIND=8))
        IF (PRESENT(rn_urb2d)) CALL gpu_cc_save_r(576, rn_urb2d, SIZE(rn_urb2d,KIND=8))
        IF (PRESENT(ts_urb2d)) CALL gpu_cc_save_r(577, ts_urb2d, SIZE(ts_urb2d,KIND=8))
        IF (PRESENT(frc_urb2d)) CALL gpu_cc_save_r(578, frc_urb2d, SIZE(frc_urb2d,KIND=8))
        IF (PRESENT(utype_urb2d)) CALL gpu_cc_save_i(579, utype_urb2d, SIZE(utype_urb2d,KIND=8))
        IF (PRESENT(cmr_sfcdif)) CALL gpu_cc_save_r(580, cmr_sfcdif, SIZE(cmr_sfcdif,KIND=8))
        IF (PRESENT(chr_sfcdif)) CALL gpu_cc_save_r(581, chr_sfcdif, SIZE(chr_sfcdif,KIND=8))
        IF (PRESENT(cmc_sfcdif)) CALL gpu_cc_save_r(582, cmc_sfcdif, SIZE(cmc_sfcdif,KIND=8))
        IF (PRESENT(chc_sfcdif)) CALL gpu_cc_save_r(583, chc_sfcdif, SIZE(chc_sfcdif,KIND=8))
        IF (PRESENT(cmgr_sfcdif)) CALL gpu_cc_save_r(584, cmgr_sfcdif, SIZE(cmgr_sfcdif,KIND=8))
        IF (PRESENT(chgr_sfcdif)) CALL gpu_cc_save_r(585, chgr_sfcdif, SIZE(chgr_sfcdif,KIND=8))
        IF (PRESENT(alswvisdir)) CALL gpu_cc_save_r(586, alswvisdir, SIZE(alswvisdir,KIND=8))
        IF (PRESENT(alswvisdif)) CALL gpu_cc_save_r(587, alswvisdif, SIZE(alswvisdif,KIND=8))
        IF (PRESENT(alswnirdir)) CALL gpu_cc_save_r(588, alswnirdir, SIZE(alswnirdir,KIND=8))
        IF (PRESENT(alswnirdif)) CALL gpu_cc_save_r(589, alswnirdif, SIZE(alswnirdif,KIND=8))
        IF (PRESENT(ssib_br)) CALL gpu_cc_save_r(590, ssib_br, SIZE(ssib_br,KIND=8))
        IF (PRESENT(ssib_fm)) CALL gpu_cc_save_r(591, ssib_fm, SIZE(ssib_fm,KIND=8))
        IF (PRESENT(ssib_fh)) CALL gpu_cc_save_r(592, ssib_fh, SIZE(ssib_fh,KIND=8))
        IF (PRESENT(ssib_cm)) CALL gpu_cc_save_r(593, ssib_cm, SIZE(ssib_cm,KIND=8))
        IF (PRESENT(ssibxdd)) CALL gpu_cc_save_r(594, ssibxdd, SIZE(ssibxdd,KIND=8))
        IF (PRESENT(ssib_lhf)) CALL gpu_cc_save_r(595, ssib_lhf, SIZE(ssib_lhf,KIND=8))
        IF (PRESENT(ssib_shf)) CALL gpu_cc_save_r(596, ssib_shf, SIZE(ssib_shf,KIND=8))
        IF (PRESENT(ssib_ghf)) CALL gpu_cc_save_r(597, ssib_ghf, SIZE(ssib_ghf,KIND=8))
        IF (PRESENT(ssib_egs)) CALL gpu_cc_save_r(598, ssib_egs, SIZE(ssib_egs,KIND=8))
        IF (PRESENT(ssib_eci)) CALL gpu_cc_save_r(599, ssib_eci, SIZE(ssib_eci,KIND=8))
        IF (PRESENT(ssib_ect)) CALL gpu_cc_save_r(600, ssib_ect, SIZE(ssib_ect,KIND=8))
        IF (PRESENT(ssib_egi)) CALL gpu_cc_save_r(601, ssib_egi, SIZE(ssib_egi,KIND=8))
        IF (PRESENT(ssib_egt)) CALL gpu_cc_save_r(602, ssib_egt, SIZE(ssib_egt,KIND=8))
        IF (PRESENT(ssib_sdn)) CALL gpu_cc_save_r(603, ssib_sdn, SIZE(ssib_sdn,KIND=8))
        IF (PRESENT(ssib_sup)) CALL gpu_cc_save_r(604, ssib_sup, SIZE(ssib_sup,KIND=8))
        IF (PRESENT(ssib_ldn)) CALL gpu_cc_save_r(605, ssib_ldn, SIZE(ssib_ldn,KIND=8))
        IF (PRESENT(ssib_lup)) CALL gpu_cc_save_r(606, ssib_lup, SIZE(ssib_lup,KIND=8))
        IF (PRESENT(ssib_wat)) CALL gpu_cc_save_r(607, ssib_wat, SIZE(ssib_wat,KIND=8))
        IF (PRESENT(ssib_shc)) CALL gpu_cc_save_r(608, ssib_shc, SIZE(ssib_shc,KIND=8))
        IF (PRESENT(ssib_shg)) CALL gpu_cc_save_r(609, ssib_shg, SIZE(ssib_shg,KIND=8))
        IF (PRESENT(ssib_lai)) CALL gpu_cc_save_r(610, ssib_lai, SIZE(ssib_lai,KIND=8))
        IF (PRESENT(ssib_vcf)) CALL gpu_cc_save_r(611, ssib_vcf, SIZE(ssib_vcf,KIND=8))
        IF (PRESENT(ssib_z00)) CALL gpu_cc_save_r(612, ssib_z00, SIZE(ssib_z00,KIND=8))
        IF (PRESENT(ssib_veg)) CALL gpu_cc_save_r(613, ssib_veg, SIZE(ssib_veg,KIND=8))
        IF (PRESENT(isnow)) CALL gpu_cc_save_i(614, isnow, SIZE(isnow,KIND=8))
        IF (PRESENT(swe)) CALL gpu_cc_save_r(615, swe, SIZE(swe,KIND=8))
        IF (PRESENT(snowden)) CALL gpu_cc_save_r(616, snowden, SIZE(snowden,KIND=8))
        IF (PRESENT(snowdepth)) CALL gpu_cc_save_r(617, snowdepth, SIZE(snowdepth,KIND=8))
        IF (PRESENT(tkair)) CALL gpu_cc_save_r(618, tkair, SIZE(tkair,KIND=8))
        IF (PRESENT(dzo1)) CALL gpu_cc_save_r(619, dzo1, SIZE(dzo1,KIND=8))
        IF (PRESENT(wo1)) CALL gpu_cc_save_r(620, wo1, SIZE(wo1,KIND=8))
        IF (PRESENT(tssn1)) CALL gpu_cc_save_r(621, tssn1, SIZE(tssn1,KIND=8))
        IF (PRESENT(tssno1)) CALL gpu_cc_save_r(622, tssno1, SIZE(tssno1,KIND=8))
        IF (PRESENT(bwo1)) CALL gpu_cc_save_r(623, bwo1, SIZE(bwo1,KIND=8))
        IF (PRESENT(bto1)) CALL gpu_cc_save_r(624, bto1, SIZE(bto1,KIND=8))
        IF (PRESENT(cto1)) CALL gpu_cc_save_r(625, cto1, SIZE(cto1,KIND=8))
        IF (PRESENT(fio1)) CALL gpu_cc_save_r(626, fio1, SIZE(fio1,KIND=8))
        IF (PRESENT(flo1)) CALL gpu_cc_save_r(627, flo1, SIZE(flo1,KIND=8))
        IF (PRESENT(bio1)) CALL gpu_cc_save_r(628, bio1, SIZE(bio1,KIND=8))
        IF (PRESENT(blo1)) CALL gpu_cc_save_r(629, blo1, SIZE(blo1,KIND=8))
        IF (PRESENT(ho1)) CALL gpu_cc_save_r(630, ho1, SIZE(ho1,KIND=8))
        IF (PRESENT(dzo2)) CALL gpu_cc_save_r(631, dzo2, SIZE(dzo2,KIND=8))
        IF (PRESENT(wo2)) CALL gpu_cc_save_r(632, wo2, SIZE(wo2,KIND=8))
        IF (PRESENT(tssn2)) CALL gpu_cc_save_r(633, tssn2, SIZE(tssn2,KIND=8))
        IF (PRESENT(tssno2)) CALL gpu_cc_save_r(634, tssno2, SIZE(tssno2,KIND=8))
        IF (PRESENT(bwo2)) CALL gpu_cc_save_r(635, bwo2, SIZE(bwo2,KIND=8))
        IF (PRESENT(bto2)) CALL gpu_cc_save_r(636, bto2, SIZE(bto2,KIND=8))
        IF (PRESENT(cto2)) CALL gpu_cc_save_r(637, cto2, SIZE(cto2,KIND=8))
        IF (PRESENT(fio2)) CALL gpu_cc_save_r(638, fio2, SIZE(fio2,KIND=8))
        IF (PRESENT(flo2)) CALL gpu_cc_save_r(639, flo2, SIZE(flo2,KIND=8))
        IF (PRESENT(bio2)) CALL gpu_cc_save_r(640, bio2, SIZE(bio2,KIND=8))
        IF (PRESENT(blo2)) CALL gpu_cc_save_r(641, blo2, SIZE(blo2,KIND=8))
        IF (PRESENT(ho2)) CALL gpu_cc_save_r(642, ho2, SIZE(ho2,KIND=8))
        IF (PRESENT(dzo3)) CALL gpu_cc_save_r(643, dzo3, SIZE(dzo3,KIND=8))
        IF (PRESENT(wo3)) CALL gpu_cc_save_r(644, wo3, SIZE(wo3,KIND=8))
        IF (PRESENT(tssn3)) CALL gpu_cc_save_r(645, tssn3, SIZE(tssn3,KIND=8))
        IF (PRESENT(tssno3)) CALL gpu_cc_save_r(646, tssno3, SIZE(tssno3,KIND=8))
        IF (PRESENT(bwo3)) CALL gpu_cc_save_r(647, bwo3, SIZE(bwo3,KIND=8))
        IF (PRESENT(bto3)) CALL gpu_cc_save_r(648, bto3, SIZE(bto3,KIND=8))
        IF (PRESENT(cto3)) CALL gpu_cc_save_r(649, cto3, SIZE(cto3,KIND=8))
        IF (PRESENT(fio3)) CALL gpu_cc_save_r(650, fio3, SIZE(fio3,KIND=8))
        IF (PRESENT(flo3)) CALL gpu_cc_save_r(651, flo3, SIZE(flo3,KIND=8))
        IF (PRESENT(bio3)) CALL gpu_cc_save_r(652, bio3, SIZE(bio3,KIND=8))
        IF (PRESENT(blo3)) CALL gpu_cc_save_r(653, blo3, SIZE(blo3,KIND=8))
        IF (PRESENT(ho3)) CALL gpu_cc_save_r(654, ho3, SIZE(ho3,KIND=8))
        IF (PRESENT(dzo4)) CALL gpu_cc_save_r(655, dzo4, SIZE(dzo4,KIND=8))
        IF (PRESENT(wo4)) CALL gpu_cc_save_r(656, wo4, SIZE(wo4,KIND=8))
        IF (PRESENT(tssn4)) CALL gpu_cc_save_r(657, tssn4, SIZE(tssn4,KIND=8))
        IF (PRESENT(tssno4)) CALL gpu_cc_save_r(658, tssno4, SIZE(tssno4,KIND=8))
        IF (PRESENT(bwo4)) CALL gpu_cc_save_r(659, bwo4, SIZE(bwo4,KIND=8))
        IF (PRESENT(bto4)) CALL gpu_cc_save_r(660, bto4, SIZE(bto4,KIND=8))
        IF (PRESENT(cto4)) CALL gpu_cc_save_r(661, cto4, SIZE(cto4,KIND=8))
        IF (PRESENT(fio4)) CALL gpu_cc_save_r(662, fio4, SIZE(fio4,KIND=8))
        IF (PRESENT(flo4)) CALL gpu_cc_save_r(663, flo4, SIZE(flo4,KIND=8))
        IF (PRESENT(bio4)) CALL gpu_cc_save_r(664, bio4, SIZE(bio4,KIND=8))
        IF (PRESENT(blo4)) CALL gpu_cc_save_r(665, blo4, SIZE(blo4,KIND=8))
        IF (PRESENT(ho4)) CALL gpu_cc_save_r(666, ho4, SIZE(ho4,KIND=8))
        IF (PRESENT(qv_curr)) CALL gpu_cc_save_r(667, qv_curr, SIZE(qv_curr,KIND=8))
        IF (PRESENT(qc_curr)) CALL gpu_cc_save_r(668, qc_curr, SIZE(qc_curr,KIND=8))
        IF (PRESENT(qr_curr)) CALL gpu_cc_save_r(669, qr_curr, SIZE(qr_curr,KIND=8))
        IF (PRESENT(qi_curr)) CALL gpu_cc_save_r(670, qi_curr, SIZE(qi_curr,KIND=8))
        IF (PRESENT(qs_curr)) CALL gpu_cc_save_r(671, qs_curr, SIZE(qs_curr,KIND=8))
        IF (PRESENT(qg_curr)) CALL gpu_cc_save_r(672, qg_curr, SIZE(qg_curr,KIND=8))
        IF (PRESENT(capg)) CALL gpu_cc_save_r(673, capg, SIZE(capg,KIND=8))
        IF (PRESENT(hol)) CALL gpu_cc_save_r(674, hol, SIZE(hol,KIND=8))
        IF (PRESENT(mol)) CALL gpu_cc_save_r(675, mol, SIZE(mol,KIND=8))
        IF (PRESENT(rainbl)) CALL gpu_cc_save_r(676, rainbl, SIZE(rainbl,KIND=8))
        IF (PRESENT(regime)) CALL gpu_cc_save_r(677, regime, SIZE(regime,KIND=8))
        IF (PRESENT(qsg)) CALL gpu_cc_save_r(678, qsg, SIZE(qsg,KIND=8))
        IF (PRESENT(qvg)) CALL gpu_cc_save_r(679, qvg, SIZE(qvg,KIND=8))
        IF (PRESENT(qcg)) CALL gpu_cc_save_r(680, qcg, SIZE(qcg,KIND=8))
        IF (PRESENT(soilt1)) CALL gpu_cc_save_r(681, soilt1, SIZE(soilt1,KIND=8))
        IF (PRESENT(tsnav)) CALL gpu_cc_save_r(682, tsnav, SIZE(tsnav,KIND=8))
        IF (PRESENT(smfr3d)) CALL gpu_cc_save_r(683, smfr3d, SIZE(smfr3d,KIND=8))
        IF (PRESENT(keepfr3dflag)) CALL gpu_cc_save_r(684, keepfr3dflag, SIZE(keepfr3dflag,KIND=8))
        IF (PRESENT(dew)) CALL gpu_cc_save_r(685, dew, SIZE(dew,KIND=8))
        IF (PRESENT(rhosnf)) CALL gpu_cc_save_r(686, rhosnf, SIZE(rhosnf,KIND=8))
        IF (PRESENT(precipfr)) CALL gpu_cc_save_r(687, precipfr, SIZE(precipfr,KIND=8))
        IF (PRESENT(potevp)) CALL gpu_cc_save_r(688, potevp, SIZE(potevp,KIND=8))
        IF (PRESENT(snopcx)) CALL gpu_cc_save_r(689, snopcx, SIZE(snopcx,KIND=8))
        IF (PRESENT(soiltb)) CALL gpu_cc_save_r(690, soiltb, SIZE(soiltb,KIND=8))
        IF (PRESENT(sr)) CALL gpu_cc_save_r(691, sr, SIZE(sr,KIND=8))
        IF (PRESENT(t2_ndg_old)) CALL gpu_cc_save_r(692, t2_ndg_old, SIZE(t2_ndg_old,KIND=8))
        IF (PRESENT(q2_ndg_old)) CALL gpu_cc_save_r(693, q2_ndg_old, SIZE(q2_ndg_old,KIND=8))
        IF (PRESENT(t2_ndg_new)) CALL gpu_cc_save_r(694, t2_ndg_new, SIZE(t2_ndg_new,KIND=8))
        IF (PRESENT(q2_ndg_new)) CALL gpu_cc_save_r(695, q2_ndg_new, SIZE(q2_ndg_new,KIND=8))
        IF (PRESENT(sn_ndg_old)) CALL gpu_cc_save_r(696, sn_ndg_old, SIZE(sn_ndg_old,KIND=8))
        IF (PRESENT(sn_ndg_new)) CALL gpu_cc_save_r(697, sn_ndg_new, SIZE(sn_ndg_new,KIND=8))
        IF (PRESENT(t2obs)) CALL gpu_cc_save_r(698, t2obs, SIZE(t2obs,KIND=8))
        IF (PRESENT(q2obs)) CALL gpu_cc_save_r(699, q2obs, SIZE(q2obs,KIND=8))
        IF (PRESENT(hd_temf)) CALL gpu_cc_save_r(700, hd_temf, SIZE(hd_temf,KIND=8))
        IF (PRESENT(te_temf)) CALL gpu_cc_save_r(701, te_temf, SIZE(te_temf,KIND=8))
        IF (PRESENT(exch_temf)) CALL gpu_cc_save_r(702, exch_temf, SIZE(exch_temf,KIND=8))
        IF (PRESENT(wm_temf)) CALL gpu_cc_save_r(703, wm_temf, SIZE(wm_temf,KIND=8))
        IF (PRESENT(hfx_force)) CALL gpu_cc_save_r0(704, hfx_force)
        IF (PRESENT(lh_force)) CALL gpu_cc_save_r0(705, lh_force)
        IF (PRESENT(tsk_force)) CALL gpu_cc_save_r0(706, tsk_force)
        IF (PRESENT(uratx)) CALL gpu_cc_save_r(707, uratx, SIZE(uratx,KIND=8))
        IF (PRESENT(vratx)) CALL gpu_cc_save_r(708, vratx, SIZE(vratx,KIND=8))
        IF (PRESENT(tratx)) CALL gpu_cc_save_r(709, tratx, SIZE(tratx,KIND=8))
        IF (PRESENT(tml)) CALL gpu_cc_save_r(710, tml, SIZE(tml,KIND=8))
        IF (PRESENT(t0ml)) CALL gpu_cc_save_r(711, t0ml, SIZE(t0ml,KIND=8))
        IF (PRESENT(hml)) CALL gpu_cc_save_r(712, hml, SIZE(hml,KIND=8))
        IF (PRESENT(h0ml)) CALL gpu_cc_save_r(713, h0ml, SIZE(h0ml,KIND=8))
        IF (PRESENT(huml)) CALL gpu_cc_save_r(714, huml, SIZE(huml,KIND=8))
        IF (PRESENT(hvml)) CALL gpu_cc_save_r(715, hvml, SIZE(hvml,KIND=8))
        IF (PRESENT(ustm)) CALL gpu_cc_save_r(716, ustm, SIZE(ustm,KIND=8))
        IF (PRESENT(ck)) CALL gpu_cc_save_r(717, ck, SIZE(ck,KIND=8))
        IF (PRESENT(cka)) CALL gpu_cc_save_r(718, cka, SIZE(cka,KIND=8))
        IF (PRESENT(cd)) CALL gpu_cc_save_r(719, cd, SIZE(cd,KIND=8))
        IF (PRESENT(cda)) CALL gpu_cc_save_r(720, cda, SIZE(cda,KIND=8))
        IF (PRESENT(snotime)) CALL gpu_cc_save_r(721, snotime, SIZE(snotime,KIND=8))
        IF (PRESENT(noahres)) CALL gpu_cc_save_r(722, noahres, SIZE(noahres,KIND=8))
        IF (PRESENT(bldtacttime)) CALL gpu_cc_save_r0(723, bldtacttime)
        IF (PRESENT(tsk_rural)) CALL gpu_cc_save_r(724, tsk_rural, SIZE(tsk_rural,KIND=8))
        IF (PRESENT(trb_urb4d)) CALL gpu_cc_save_r(725, trb_urb4d, SIZE(trb_urb4d,KIND=8))
        IF (PRESENT(tw1_urb4d)) CALL gpu_cc_save_r(726, tw1_urb4d, SIZE(tw1_urb4d,KIND=8))
        IF (PRESENT(tw2_urb4d)) CALL gpu_cc_save_r(727, tw2_urb4d, SIZE(tw2_urb4d,KIND=8))
        IF (PRESENT(tgb_urb4d)) CALL gpu_cc_save_r(728, tgb_urb4d, SIZE(tgb_urb4d,KIND=8))
        IF (PRESENT(tlev_urb3d)) CALL gpu_cc_save_r(729, tlev_urb3d, SIZE(tlev_urb3d,KIND=8))
        IF (PRESENT(qlev_urb3d)) CALL gpu_cc_save_r(730, qlev_urb3d, SIZE(qlev_urb3d,KIND=8))
        IF (PRESENT(tw1lev_urb3d)) CALL gpu_cc_save_r(731, tw1lev_urb3d, SIZE(tw1lev_urb3d,KIND=8))
        IF (PRESENT(tw2lev_urb3d)) CALL gpu_cc_save_r(732, tw2lev_urb3d, SIZE(tw2lev_urb3d,KIND=8))
        IF (PRESENT(tglev_urb3d)) CALL gpu_cc_save_r(733, tglev_urb3d, SIZE(tglev_urb3d,KIND=8))
        IF (PRESENT(tflev_urb3d)) CALL gpu_cc_save_r(734, tflev_urb3d, SIZE(tflev_urb3d,KIND=8))
        IF (PRESENT(sf_ac_urb3d)) CALL gpu_cc_save_r(735, sf_ac_urb3d, SIZE(sf_ac_urb3d,KIND=8))
        IF (PRESENT(lf_ac_urb3d)) CALL gpu_cc_save_r(736, lf_ac_urb3d, SIZE(lf_ac_urb3d,KIND=8))
        IF (PRESENT(cm_ac_urb3d)) CALL gpu_cc_save_r(737, cm_ac_urb3d, SIZE(cm_ac_urb3d,KIND=8))
        IF (PRESENT(sfvent_urb3d)) CALL gpu_cc_save_r(738, sfvent_urb3d, SIZE(sfvent_urb3d,KIND=8))
        IF (PRESENT(lfvent_urb3d)) CALL gpu_cc_save_r(739, lfvent_urb3d, SIZE(lfvent_urb3d,KIND=8))
        IF (PRESENT(sfwin1_urb3d)) CALL gpu_cc_save_r(740, sfwin1_urb3d, SIZE(sfwin1_urb3d,KIND=8))
        IF (PRESENT(sfwin2_urb3d)) CALL gpu_cc_save_r(741, sfwin2_urb3d, SIZE(sfwin2_urb3d,KIND=8))
        IF (PRESENT(sfw1_urb3d)) CALL gpu_cc_save_r(742, sfw1_urb3d, SIZE(sfw1_urb3d,KIND=8))
        IF (PRESENT(sfw2_urb3d)) CALL gpu_cc_save_r(743, sfw2_urb3d, SIZE(sfw2_urb3d,KIND=8))
        IF (PRESENT(sfr_urb3d)) CALL gpu_cc_save_r(744, sfr_urb3d, SIZE(sfr_urb3d,KIND=8))
        IF (PRESENT(sfg_urb3d)) CALL gpu_cc_save_r(745, sfg_urb3d, SIZE(sfg_urb3d,KIND=8))
        IF (PRESENT(ep_pv_urb3d)) CALL gpu_cc_save_r(746, ep_pv_urb3d, SIZE(ep_pv_urb3d,KIND=8))
        IF (PRESENT(t_pv_urb3d)) CALL gpu_cc_save_r(747, t_pv_urb3d, SIZE(t_pv_urb3d,KIND=8))
        IF (PRESENT(trv_urb4d)) CALL gpu_cc_save_r(748, trv_urb4d, SIZE(trv_urb4d,KIND=8))
        IF (PRESENT(qr_urb4d)) CALL gpu_cc_save_r(749, qr_urb4d, SIZE(qr_urb4d,KIND=8))
        IF (PRESENT(qgr_urb3d)) CALL gpu_cc_save_r(750, qgr_urb3d, SIZE(qgr_urb3d,KIND=8))
        IF (PRESENT(tgr_urb3d)) CALL gpu_cc_save_r(751, tgr_urb3d, SIZE(tgr_urb3d,KIND=8))
        IF (PRESENT(drain_urb4d)) CALL gpu_cc_save_r(752, drain_urb4d, SIZE(drain_urb4d,KIND=8))
        IF (PRESENT(draingr_urb3d)) CALL gpu_cc_save_r(753, draingr_urb3d, SIZE(draingr_urb3d,KIND=8))
        IF (PRESENT(sfrv_urb3d)) CALL gpu_cc_save_r(754, sfrv_urb3d, SIZE(sfrv_urb3d,KIND=8))
        IF (PRESENT(lfrv_urb3d)) CALL gpu_cc_save_r(755, lfrv_urb3d, SIZE(lfrv_urb3d,KIND=8))
        IF (PRESENT(dgr_urb3d)) CALL gpu_cc_save_r(756, dgr_urb3d, SIZE(dgr_urb3d,KIND=8))
        IF (PRESENT(dg_urb3d)) CALL gpu_cc_save_r(757, dg_urb3d, SIZE(dg_urb3d,KIND=8))
        IF (PRESENT(lfr_urb3d)) CALL gpu_cc_save_r(758, lfr_urb3d, SIZE(lfr_urb3d,KIND=8))
        IF (PRESENT(lfg_urb3d)) CALL gpu_cc_save_r(759, lfg_urb3d, SIZE(lfg_urb3d,KIND=8))
        IF (PRESENT(a_u_bep)) CALL gpu_cc_save_r(760, a_u_bep, SIZE(a_u_bep,KIND=8))
        IF (PRESENT(a_v_bep)) CALL gpu_cc_save_r(761, a_v_bep, SIZE(a_v_bep,KIND=8))
        IF (PRESENT(a_t_bep)) CALL gpu_cc_save_r(762, a_t_bep, SIZE(a_t_bep,KIND=8))
        IF (PRESENT(a_q_bep)) CALL gpu_cc_save_r(763, a_q_bep, SIZE(a_q_bep,KIND=8))
        IF (PRESENT(b_u_bep)) CALL gpu_cc_save_r(764, b_u_bep, SIZE(b_u_bep,KIND=8))
        IF (PRESENT(b_v_bep)) CALL gpu_cc_save_r(765, b_v_bep, SIZE(b_v_bep,KIND=8))
        IF (PRESENT(b_t_bep)) CALL gpu_cc_save_r(766, b_t_bep, SIZE(b_t_bep,KIND=8))
        IF (PRESENT(b_q_bep)) CALL gpu_cc_save_r(767, b_q_bep, SIZE(b_q_bep,KIND=8))
        IF (PRESENT(sf_bep)) CALL gpu_cc_save_r(768, sf_bep, SIZE(sf_bep,KIND=8))
        IF (PRESENT(vl_bep)) CALL gpu_cc_save_r(769, vl_bep, SIZE(vl_bep,KIND=8))
        IF (PRESENT(a_e_bep)) CALL gpu_cc_save_r(770, a_e_bep, SIZE(a_e_bep,KIND=8))
        IF (PRESENT(b_e_bep)) CALL gpu_cc_save_r(771, b_e_bep, SIZE(b_e_bep,KIND=8))
        IF (PRESENT(dlg_bep)) CALL gpu_cc_save_r(772, dlg_bep, SIZE(dlg_bep,KIND=8))
        IF (PRESENT(dl_u_bep)) CALL gpu_cc_save_r(773, dl_u_bep, SIZE(dl_u_bep,KIND=8))
        IF (PRESENT(tsk_save)) CALL gpu_cc_save_r(774, tsk_save, SIZE(tsk_save,KIND=8))
        IF (PRESENT(mosaic_cat_index)) CALL gpu_cc_save_i(775, mosaic_cat_index, SIZE(mosaic_cat_index,KIND=8))
        IF (PRESENT(landusef2)) CALL gpu_cc_save_r(776, landusef2, SIZE(landusef2,KIND=8))
        IF (PRESENT(tsk_mosaic)) CALL gpu_cc_save_r(777, tsk_mosaic, SIZE(tsk_mosaic,KIND=8))
        IF (PRESENT(qsfc_mosaic)) CALL gpu_cc_save_r(778, qsfc_mosaic, SIZE(qsfc_mosaic,KIND=8))
        IF (PRESENT(tslb_mosaic)) CALL gpu_cc_save_r(779, tslb_mosaic, SIZE(tslb_mosaic,KIND=8))
        IF (PRESENT(smois_mosaic)) CALL gpu_cc_save_r(780, smois_mosaic, SIZE(smois_mosaic,KIND=8))
        IF (PRESENT(sh2o_mosaic)) CALL gpu_cc_save_r(781, sh2o_mosaic, SIZE(sh2o_mosaic,KIND=8))
        IF (PRESENT(canwat_mosaic)) CALL gpu_cc_save_r(782, canwat_mosaic, SIZE(canwat_mosaic,KIND=8))
        IF (PRESENT(snow_mosaic)) CALL gpu_cc_save_r(783, snow_mosaic, SIZE(snow_mosaic,KIND=8))
        IF (PRESENT(snowh_mosaic)) CALL gpu_cc_save_r(784, snowh_mosaic, SIZE(snowh_mosaic,KIND=8))
        IF (PRESENT(snowc_mosaic)) CALL gpu_cc_save_r(785, snowc_mosaic, SIZE(snowc_mosaic,KIND=8))
        IF (PRESENT(albedo_mosaic)) CALL gpu_cc_save_r(786, albedo_mosaic, SIZE(albedo_mosaic,KIND=8))
        IF (PRESENT(albbck_mosaic)) CALL gpu_cc_save_r(787, albbck_mosaic, SIZE(albbck_mosaic,KIND=8))
        IF (PRESENT(emiss_mosaic)) CALL gpu_cc_save_r(788, emiss_mosaic, SIZE(emiss_mosaic,KIND=8))
        IF (PRESENT(embck_mosaic)) CALL gpu_cc_save_r(789, embck_mosaic, SIZE(embck_mosaic,KIND=8))
        IF (PRESENT(znt_mosaic)) CALL gpu_cc_save_r(790, znt_mosaic, SIZE(znt_mosaic,KIND=8))
        IF (PRESENT(z0_mosaic)) CALL gpu_cc_save_r(791, z0_mosaic, SIZE(z0_mosaic,KIND=8))
        IF (PRESENT(hfx_mosaic)) CALL gpu_cc_save_r(792, hfx_mosaic, SIZE(hfx_mosaic,KIND=8))
        IF (PRESENT(qfx_mosaic)) CALL gpu_cc_save_r(793, qfx_mosaic, SIZE(qfx_mosaic,KIND=8))
        IF (PRESENT(lh_mosaic)) CALL gpu_cc_save_r(794, lh_mosaic, SIZE(lh_mosaic,KIND=8))
        IF (PRESENT(grdflx_mosaic)) CALL gpu_cc_save_r(795, grdflx_mosaic, SIZE(grdflx_mosaic,KIND=8))
        IF (PRESENT(snotime_mosaic)) CALL gpu_cc_save_r(796, snotime_mosaic, SIZE(snotime_mosaic,KIND=8))
        IF (PRESENT(rs_mosaic)) CALL gpu_cc_save_r(797, rs_mosaic, SIZE(rs_mosaic,KIND=8))
        IF (PRESENT(lai_mosaic)) CALL gpu_cc_save_r(798, lai_mosaic, SIZE(lai_mosaic,KIND=8))
        IF (PRESENT(tr_urb2d_mosaic)) CALL gpu_cc_save_r(799, tr_urb2d_mosaic, SIZE(tr_urb2d_mosaic,KIND=8))
        IF (PRESENT(tb_urb2d_mosaic)) CALL gpu_cc_save_r(800, tb_urb2d_mosaic, SIZE(tb_urb2d_mosaic,KIND=8))
        IF (PRESENT(tg_urb2d_mosaic)) CALL gpu_cc_save_r(801, tg_urb2d_mosaic, SIZE(tg_urb2d_mosaic,KIND=8))
        IF (PRESENT(tc_urb2d_mosaic)) CALL gpu_cc_save_r(802, tc_urb2d_mosaic, SIZE(tc_urb2d_mosaic,KIND=8))
        IF (PRESENT(qc_urb2d_mosaic)) CALL gpu_cc_save_r(803, qc_urb2d_mosaic, SIZE(qc_urb2d_mosaic,KIND=8))
        IF (PRESENT(uc_urb2d_mosaic)) CALL gpu_cc_save_r(804, uc_urb2d_mosaic, SIZE(uc_urb2d_mosaic,KIND=8))
        IF (PRESENT(trl_urb3d_mosaic)) CALL gpu_cc_save_r(805, trl_urb3d_mosaic, SIZE(trl_urb3d_mosaic,KIND=8))
        IF (PRESENT(tbl_urb3d_mosaic)) CALL gpu_cc_save_r(806, tbl_urb3d_mosaic, SIZE(tbl_urb3d_mosaic,KIND=8))
        IF (PRESENT(tgl_urb3d_mosaic)) CALL gpu_cc_save_r(807, tgl_urb3d_mosaic, SIZE(tgl_urb3d_mosaic,KIND=8))
        IF (PRESENT(sh_urb2d_mosaic)) CALL gpu_cc_save_r(808, sh_urb2d_mosaic, SIZE(sh_urb2d_mosaic,KIND=8))
        IF (PRESENT(lh_urb2d_mosaic)) CALL gpu_cc_save_r(809, lh_urb2d_mosaic, SIZE(lh_urb2d_mosaic,KIND=8))
        IF (PRESENT(g_urb2d_mosaic)) CALL gpu_cc_save_r(810, g_urb2d_mosaic, SIZE(g_urb2d_mosaic,KIND=8))
        IF (PRESENT(rn_urb2d_mosaic)) CALL gpu_cc_save_r(811, rn_urb2d_mosaic, SIZE(rn_urb2d_mosaic,KIND=8))
        IF (PRESENT(ts_urb2d_mosaic)) CALL gpu_cc_save_r(812, ts_urb2d_mosaic, SIZE(ts_urb2d_mosaic,KIND=8))
        IF (PRESENT(ts_rul2d_mosaic)) CALL gpu_cc_save_r(813, ts_rul2d_mosaic, SIZE(ts_rul2d_mosaic,KIND=8))
        CALL gpu_cc_save_r(814, zol, SIZE(zol,KIND=8))
        IF (PRESENT(sda_hfx)) CALL gpu_cc_save_r(815, sda_hfx, SIZE(sda_hfx,KIND=8))
        IF (PRESENT(sda_qfx)) CALL gpu_cc_save_r(816, sda_qfx, SIZE(sda_qfx,KIND=8))
        IF (PRESENT(hfx_both)) CALL gpu_cc_save_r(817, hfx_both, SIZE(hfx_both,KIND=8))
        IF (PRESENT(qfx_both)) CALL gpu_cc_save_r(818, qfx_both, SIZE(qfx_both,KIND=8))
        IF (PRESENT(qnorm)) CALL gpu_cc_save_r(819, qnorm, SIZE(qnorm,KIND=8))
        IF (PRESENT(pattern_spp_lsm)) CALL gpu_cc_save_r(820, pattern_spp_lsm, SIZE(pattern_spp_lsm,KIND=8))
        IF (PRESENT(field_sf)) CALL gpu_cc_save_r(821, field_sf, SIZE(field_sf,KIND=8))
        IF (PRESENT(pattern_spp_pbl)) CALL gpu_cc_save_r(822, pattern_spp_pbl, SIZE(pattern_spp_pbl,KIND=8))
        IF (PRESENT(xlaidyn)) CALL gpu_cc_save_r(823, xlaidyn, SIZE(xlaidyn,KIND=8))
        IF (PRESENT(perts_qvapor)) CALL gpu_cc_save_r(824, perts_qvapor, SIZE(perts_qvapor,KIND=8))
        IF (PRESENT(perts_th)) CALL gpu_cc_save_r(825, perts_th, SIZE(perts_th,KIND=8))
        IF (PRESENT(perts_smois)) CALL gpu_cc_save_r(826, perts_smois, SIZE(perts_smois,KIND=8))
        IF (PRESENT(perts_tsoil)) CALL gpu_cc_save_r(827, perts_tsoil, SIZE(perts_tsoil,KIND=8))
        IF (PRESENT(irr_rand_field)) CALL gpu_cc_save_i(828, irr_rand_field, SIZE(irr_rand_field,KIND=8))
      END IF
      gpu_isl = gpu_island(R_SURFACE_DRIVER)
      IF (gpu_isl) THEN
        IF (gpu_world_host) THEN
!$acc update device(sfcheadrt, infxsrt, soldrain, qtiledrain, zwatble2d, acsnom, acsnow, akhs, &
!$acc&   akms, albedo, br, canwat, chklowq, dz8w, dzs, glw, grdflx, gsw, swdown, gz1oz0, hfx, ht, &
!$acc&   isltyp, ivgtyp, lowlyr, mavail, rmol, p8w, pblh, pi_phy, pshltr, fm, fhh, psih, psim, &
!$acc&   p_phy, q10, q2, qfx, qsfc, qshltr, qz0, raincv, rho, sfcevp, sfcexc, sfcrunoff, acrunoff, &
!$acc&   smois, smstav, smstot, snoalb, snow, snowc, snowh, smcrel, th10, th2, thz0, th_phy, tmn, &
!$acc&   tshltr, tsk, tslb, t_phy, u10, udrunoff, ust, uz0, u_phy, v10, vegfra, u10e, v10e, uoce, &
!$acc&   voce, vz0, v_phy, wspd, xice, xland, z, znt, zs, albsi, icedepth, snowsi, xicem, ct, &
!$acc&   tke_pbl, albbck, embck, lh, sh2o, shdmax, shdmin, shdavg, z0, flqc, flhc, psfc, sst, flx4, &
!$acc&   fvb, fbur, fgsn, water_depth, lakedepth2d, savedtke12d, snowdp2d, h2osno2d, snl2d, &
!$acc&   t_grnd2d, t_lake3d, lake_icefrac3d, z_lake3d, dz_lake3d, t_soisno3d, h2osoi_ice3d, &
!$acc&   h2osoi_liq3d, h2osoi_vol3d, z3d, dz3d, zi3d, watsat3d, csol3d, tkmg3d, tkdry3d, tksatu3d, &
!$acc&   lakemask, i_start, i_end, j_start, j_end, zol)
          IF (PRESENT(acgrdflx)) THEN
!$acc update device(acgrdflx)
          END IF
          IF (PRESENT(achfx)) THEN
!$acc update device(achfx)
          END IF
          IF (PRESENT(aclhf)) THEN
!$acc update device(aclhf)
          END IF
          IF (PRESENT(snowfallac)) THEN
!$acc update device(snowfallac)
          END IF
          IF (PRESENT(dx2d)) THEN
!$acc update device(dx2d)
          END IF
          IF (PRESENT(area2d)) THEN
!$acc update device(area2d)
          END IF
          IF (PRESENT(tyr)) THEN
!$acc update device(tyr)
          END IF
          IF (PRESENT(tyra)) THEN
!$acc update device(tyra)
          END IF
          IF (PRESENT(tdly)) THEN
!$acc update device(tdly)
          END IF
          IF (PRESENT(tlag)) THEN
!$acc update device(tlag)
          END IF
          IF (PRESENT(cplmask)) THEN
!$acc update device(cplmask)
          END IF
          IF (PRESENT(sst_input)) THEN
!$acc update device(sst_input)
          END IF
          IF (PRESENT(sstsk)) THEN
!$acc update device(sstsk)
          END IF
          IF (PRESENT(dtw)) THEN
!$acc update device(dtw)
          END IF
          IF (PRESENT(t2)) THEN
!$acc update device(t2)
          END IF
          IF (PRESENT(emiss)) THEN
!$acc update device(emiss)
          END IF
          IF (PRESENT(landusef)) THEN
!$acc update device(landusef)
          END IF
          IF (PRESENT(soilctop)) THEN
!$acc update device(soilctop)
          END IF
          IF (PRESENT(soilcbot)) THEN
!$acc update device(soilcbot)
          END IF
          IF (PRESENT(ra)) THEN
!$acc update device(ra)
          END IF
          IF (PRESENT(rs)) THEN
!$acc update device(rs)
          END IF
          IF (PRESENT(vegf_px)) THEN
!$acc update device(vegf_px)
          END IF
          IF (PRESENT(snowncv)) THEN
!$acc update device(snowncv)
          END IF
          IF (PRESENT(lai)) THEN
!$acc update device(lai)
          END IF
          IF (PRESENT(imperv)) THEN
!$acc update device(imperv)
          END IF
          IF (PRESENT(canfra)) THEN
!$acc update device(canfra)
          END IF
          IF (PRESENT(lai_px)) THEN
!$acc update device(lai_px)
          END IF
          IF (PRESENT(wwlt_px)) THEN
!$acc update device(wwlt_px)
          END IF
          IF (PRESENT(wfc_px)) THEN
!$acc update device(wfc_px)
          END IF
          IF (PRESENT(wsat_px)) THEN
!$acc update device(wsat_px)
          END IF
          IF (PRESENT(clay_px)) THEN
!$acc update device(clay_px)
          END IF
          IF (PRESENT(csand_px)) THEN
!$acc update device(csand_px)
          END IF
          IF (PRESENT(fmsand_px)) THEN
!$acc update device(fmsand_px)
          END IF
          IF (PRESENT(soilcomp)) THEN
!$acc update device(soilcomp)
          END IF
          IF (PRESENT(soilcl1)) THEN
!$acc update device(soilcl1)
          END IF
          IF (PRESENT(soilcl2)) THEN
!$acc update device(soilcl2)
          END IF
          IF (PRESENT(soilcl3)) THEN
!$acc update device(soilcl3)
          END IF
          IF (PRESENT(soilcl4)) THEN
!$acc update device(soilcl4)
          END IF
          IF (PRESENT(isnowxy)) THEN
!$acc update device(isnowxy)
          END IF
          IF (PRESENT(tvxy)) THEN
!$acc update device(tvxy)
          END IF
          IF (PRESENT(tgxy)) THEN
!$acc update device(tgxy)
          END IF
          IF (PRESENT(canicexy)) THEN
!$acc update device(canicexy)
          END IF
          IF (PRESENT(canliqxy)) THEN
!$acc update device(canliqxy)
          END IF
          IF (PRESENT(eahxy)) THEN
!$acc update device(eahxy)
          END IF
          IF (PRESENT(tahxy)) THEN
!$acc update device(tahxy)
          END IF
          IF (PRESENT(cmxy)) THEN
!$acc update device(cmxy)
          END IF
          IF (PRESENT(chxy)) THEN
!$acc update device(chxy)
          END IF
          IF (PRESENT(fwetxy)) THEN
!$acc update device(fwetxy)
          END IF
          IF (PRESENT(sneqvoxy)) THEN
!$acc update device(sneqvoxy)
          END IF
          IF (PRESENT(alboldxy)) THEN
!$acc update device(alboldxy)
          END IF
          IF (PRESENT(qsnowxy)) THEN
!$acc update device(qsnowxy)
          END IF
          IF (PRESENT(qrainxy)) THEN
!$acc update device(qrainxy)
          END IF
          IF (PRESENT(wslakexy)) THEN
!$acc update device(wslakexy)
          END IF
          IF (PRESENT(zwtxy)) THEN
!$acc update device(zwtxy)
          END IF
          IF (PRESENT(waxy)) THEN
!$acc update device(waxy)
          END IF
          IF (PRESENT(wtxy)) THEN
!$acc update device(wtxy)
          END IF
          IF (PRESENT(tsnoxy)) THEN
!$acc update device(tsnoxy)
          END IF
          IF (PRESENT(zsnsoxy)) THEN
!$acc update device(zsnsoxy)
          END IF
          IF (PRESENT(snicexy)) THEN
!$acc update device(snicexy)
          END IF
          IF (PRESENT(snliqxy)) THEN
!$acc update device(snliqxy)
          END IF
          IF (PRESENT(lfmassxy)) THEN
!$acc update device(lfmassxy)
          END IF
          IF (PRESENT(rtmassxy)) THEN
!$acc update device(rtmassxy)
          END IF
          IF (PRESENT(stmassxy)) THEN
!$acc update device(stmassxy)
          END IF
          IF (PRESENT(woodxy)) THEN
!$acc update device(woodxy)
          END IF
          IF (PRESENT(stblcpxy)) THEN
!$acc update device(stblcpxy)
          END IF
          IF (PRESENT(fastcpxy)) THEN
!$acc update device(fastcpxy)
          END IF
          IF (PRESENT(xsaixy)) THEN
!$acc update device(xsaixy)
          END IF
          IF (PRESENT(taussxy)) THEN
!$acc update device(taussxy)
          END IF
          IF (PRESENT(grainxy)) THEN
!$acc update device(grainxy)
          END IF
          IF (PRESENT(gddxy)) THEN
!$acc update device(gddxy)
          END IF
          IF (PRESENT(cropcat)) THEN
!$acc update device(cropcat)
          END IF
          IF (PRESENT(pgsxy)) THEN
!$acc update device(pgsxy)
          END IF
          IF (PRESENT(planting)) THEN
!$acc update device(planting)
          END IF
          IF (PRESENT(harvest)) THEN
!$acc update device(harvest)
          END IF
          IF (PRESENT(season_gdd)) THEN
!$acc update device(season_gdd)
          END IF
          IF (PRESENT(t2mvxy)) THEN
!$acc update device(t2mvxy)
          END IF
          IF (PRESENT(t2mbxy)) THEN
!$acc update device(t2mbxy)
          END IF
          IF (PRESENT(q2mvxy)) THEN
!$acc update device(q2mvxy)
          END IF
          IF (PRESENT(q2mbxy)) THEN
!$acc update device(q2mbxy)
          END IF
          IF (PRESENT(tradxy)) THEN
!$acc update device(tradxy)
          END IF
          IF (PRESENT(neexy)) THEN
!$acc update device(neexy)
          END IF
          IF (PRESENT(gppxy)) THEN
!$acc update device(gppxy)
          END IF
          IF (PRESENT(nppxy)) THEN
!$acc update device(nppxy)
          END IF
          IF (PRESENT(fvegxy)) THEN
!$acc update device(fvegxy)
          END IF
          IF (PRESENT(runsfxy)) THEN
!$acc update device(runsfxy)
          END IF
          IF (PRESENT(runsbxy)) THEN
!$acc update device(runsbxy)
          END IF
          IF (PRESENT(ecanxy)) THEN
!$acc update device(ecanxy)
          END IF
          IF (PRESENT(edirxy)) THEN
!$acc update device(edirxy)
          END IF
          IF (PRESENT(etranxy)) THEN
!$acc update device(etranxy)
          END IF
          IF (PRESENT(fsaxy)) THEN
!$acc update device(fsaxy)
          END IF
          IF (PRESENT(firaxy)) THEN
!$acc update device(firaxy)
          END IF
          IF (PRESENT(aparxy)) THEN
!$acc update device(aparxy)
          END IF
          IF (PRESENT(psnxy)) THEN
!$acc update device(psnxy)
          END IF
          IF (PRESENT(savxy)) THEN
!$acc update device(savxy)
          END IF
          IF (PRESENT(sagxy)) THEN
!$acc update device(sagxy)
          END IF
          IF (PRESENT(rssunxy)) THEN
!$acc update device(rssunxy)
          END IF
          IF (PRESENT(rsshaxy)) THEN
!$acc update device(rsshaxy)
          END IF
          IF (PRESENT(bgapxy)) THEN
!$acc update device(bgapxy)
          END IF
          IF (PRESENT(wgapxy)) THEN
!$acc update device(wgapxy)
          END IF
          IF (PRESENT(tgvxy)) THEN
!$acc update device(tgvxy)
          END IF
          IF (PRESENT(tgbxy)) THEN
!$acc update device(tgbxy)
          END IF
          IF (PRESENT(chvxy)) THEN
!$acc update device(chvxy)
          END IF
          IF (PRESENT(chbxy)) THEN
!$acc update device(chbxy)
          END IF
          IF (PRESENT(shgxy)) THEN
!$acc update device(shgxy)
          END IF
          IF (PRESENT(shcxy)) THEN
!$acc update device(shcxy)
          END IF
          IF (PRESENT(shbxy)) THEN
!$acc update device(shbxy)
          END IF
          IF (PRESENT(evgxy)) THEN
!$acc update device(evgxy)
          END IF
          IF (PRESENT(evbxy)) THEN
!$acc update device(evbxy)
          END IF
          IF (PRESENT(ghvxy)) THEN
!$acc update device(ghvxy)
          END IF
          IF (PRESENT(ghbxy)) THEN
!$acc update device(ghbxy)
          END IF
          IF (PRESENT(irgxy)) THEN
!$acc update device(irgxy)
          END IF
          IF (PRESENT(ircxy)) THEN
!$acc update device(ircxy)
          END IF
          IF (PRESENT(irbxy)) THEN
!$acc update device(irbxy)
          END IF
          IF (PRESENT(trxy)) THEN
!$acc update device(trxy)
          END IF
          IF (PRESENT(evcxy)) THEN
!$acc update device(evcxy)
          END IF
          IF (PRESENT(chleafxy)) THEN
!$acc update device(chleafxy)
          END IF
          IF (PRESENT(chucxy)) THEN
!$acc update device(chucxy)
          END IF
          IF (PRESENT(chv2xy)) THEN
!$acc update device(chv2xy)
          END IF
          IF (PRESENT(chb2xy)) THEN
!$acc update device(chb2xy)
          END IF
          IF (PRESENT(chstarxy)) THEN
!$acc update device(chstarxy)
          END IF
          IF (PRESENT(qintsxy)) THEN
!$acc update device(qintsxy)
          END IF
          IF (PRESENT(qintrxy)) THEN
!$acc update device(qintrxy)
          END IF
          IF (PRESENT(qdripsxy)) THEN
!$acc update device(qdripsxy)
          END IF
          IF (PRESENT(qdriprxy)) THEN
!$acc update device(qdriprxy)
          END IF
          IF (PRESENT(qthrosxy)) THEN
!$acc update device(qthrosxy)
          END IF
          IF (PRESENT(qthrorxy)) THEN
!$acc update device(qthrorxy)
          END IF
          IF (PRESENT(qsnsubxy)) THEN
!$acc update device(qsnsubxy)
          END IF
          IF (PRESENT(qsnfroxy)) THEN
!$acc update device(qsnfroxy)
          END IF
          IF (PRESENT(qsubcxy)) THEN
!$acc update device(qsubcxy)
          END IF
          IF (PRESENT(qfrocxy)) THEN
!$acc update device(qfrocxy)
          END IF
          IF (PRESENT(qevacxy)) THEN
!$acc update device(qevacxy)
          END IF
          IF (PRESENT(qdewcxy)) THEN
!$acc update device(qdewcxy)
          END IF
          IF (PRESENT(qfrzcxy)) THEN
!$acc update device(qfrzcxy)
          END IF
          IF (PRESENT(qmeltcxy)) THEN
!$acc update device(qmeltcxy)
          END IF
          IF (PRESENT(qsnbotxy)) THEN
!$acc update device(qsnbotxy)
          END IF
          IF (PRESENT(pondingxy)) THEN
!$acc update device(pondingxy)
          END IF
          IF (PRESENT(pahxy)) THEN
!$acc update device(pahxy)
          END IF
          IF (PRESENT(pahgxy)) THEN
!$acc update device(pahgxy)
          END IF
          IF (PRESENT(pahvxy)) THEN
!$acc update device(pahvxy)
          END IF
          IF (PRESENT(pahbxy)) THEN
!$acc update device(pahbxy)
          END IF
          IF (PRESENT(qmeltxy)) THEN
!$acc update device(qmeltxy)
          END IF
          IF (PRESENT(fpicexy)) THEN
!$acc update device(fpicexy)
          END IF
          IF (PRESENT(rainlsm)) THEN
!$acc update device(rainlsm)
          END IF
          IF (PRESENT(snowlsm)) THEN
!$acc update device(snowlsm)
          END IF
          IF (PRESENT(forctlsm)) THEN
!$acc update device(forctlsm)
          END IF
          IF (PRESENT(forcqlsm)) THEN
!$acc update device(forcqlsm)
          END IF
          IF (PRESENT(forcplsm)) THEN
!$acc update device(forcplsm)
          END IF
          IF (PRESENT(forczlsm)) THEN
!$acc update device(forczlsm)
          END IF
          IF (PRESENT(forcwlsm)) THEN
!$acc update device(forcwlsm)
          END IF
          IF (PRESENT(acc_ssoil)) THEN
!$acc update device(acc_ssoil)
          END IF
          IF (PRESENT(acc_qinsur)) THEN
!$acc update device(acc_qinsur)
          END IF
          IF (PRESENT(acc_qseva)) THEN
!$acc update device(acc_qseva)
          END IF
          IF (PRESENT(acc_etrani)) THEN
!$acc update device(acc_etrani)
          END IF
          IF (PRESENT(eflxbxy)) THEN
!$acc update device(eflxbxy)
          END IF
          IF (PRESENT(soilenergy)) THEN
!$acc update device(soilenergy)
          END IF
          IF (PRESENT(snowenergy)) THEN
!$acc update device(snowenergy)
          END IF
          IF (PRESENT(canhsxy)) THEN
!$acc update device(canhsxy)
          END IF
          IF (PRESENT(acc_dwaterxy)) THEN
!$acc update device(acc_dwaterxy)
          END IF
          IF (PRESENT(acc_prcpxy)) THEN
!$acc update device(acc_prcpxy)
          END IF
          IF (PRESENT(acc_ecanxy)) THEN
!$acc update device(acc_ecanxy)
          END IF
          IF (PRESENT(acc_etranxy)) THEN
!$acc update device(acc_etranxy)
          END IF
          IF (PRESENT(acc_edirxy)) THEN
!$acc update device(acc_edirxy)
          END IF
          IF (PRESENT(irfract)) THEN
!$acc update device(irfract)
          END IF
          IF (PRESENT(sifract)) THEN
!$acc update device(sifract)
          END IF
          IF (PRESENT(mifract)) THEN
!$acc update device(mifract)
          END IF
          IF (PRESENT(fifract)) THEN
!$acc update device(fifract)
          END IF
          IF (PRESENT(irnumsi)) THEN
!$acc update device(irnumsi)
          END IF
          IF (PRESENT(irnummi)) THEN
!$acc update device(irnummi)
          END IF
          IF (PRESENT(irnumfi)) THEN
!$acc update device(irnumfi)
          END IF
          IF (PRESENT(irwatsi)) THEN
!$acc update device(irwatsi)
          END IF
          IF (PRESENT(irwatmi)) THEN
!$acc update device(irwatmi)
          END IF
          IF (PRESENT(irwatfi)) THEN
!$acc update device(irwatfi)
          END IF
          IF (PRESENT(ireloss)) THEN
!$acc update device(ireloss)
          END IF
          IF (PRESENT(irsivol)) THEN
!$acc update device(irsivol)
          END IF
          IF (PRESENT(irmivol)) THEN
!$acc update device(irmivol)
          END IF
          IF (PRESENT(irfivol)) THEN
!$acc update device(irfivol)
          END IF
          IF (PRESENT(irrsplh)) THEN
!$acc update device(irrsplh)
          END IF
          IF (PRESENT(qtdrain)) THEN
!$acc update device(qtdrain)
          END IF
          IF (PRESENT(td_fraction)) THEN
!$acc update device(td_fraction)
          END IF
          IF (PRESENT(smcwtdxy)) THEN
!$acc update device(smcwtdxy)
          END IF
          IF (PRESENT(rechxy)) THEN
!$acc update device(rechxy)
          END IF
          IF (PRESENT(deeprechxy)) THEN
!$acc update device(deeprechxy)
          END IF
          IF (PRESENT(fdepthxy)) THEN
!$acc update device(fdepthxy)
          END IF
          IF (PRESENT(areaxy)) THEN
!$acc update device(areaxy)
          END IF
          IF (PRESENT(rivercondxy)) THEN
!$acc update device(rivercondxy)
          END IF
          IF (PRESENT(riverbedxy)) THEN
!$acc update device(riverbedxy)
          END IF
          IF (PRESENT(eqzwt)) THEN
!$acc update device(eqzwt)
          END IF
          IF (PRESENT(pexpxy)) THEN
!$acc update device(pexpxy)
          END IF
          IF (PRESENT(qrfxy)) THEN
!$acc update device(qrfxy)
          END IF
          IF (PRESENT(qspringxy)) THEN
!$acc update device(qspringxy)
          END IF
          IF (PRESENT(qslatxy)) THEN
!$acc update device(qslatxy)
          END IF
          IF (PRESENT(qrfsxy)) THEN
!$acc update device(qrfsxy)
          END IF
          IF (PRESENT(qlatxy)) THEN
!$acc update device(qlatxy)
          END IF
          IF (PRESENT(qspringsxy)) THEN
!$acc update device(qspringsxy)
          END IF
          IF (PRESENT(smoiseq)) THEN
!$acc update device(smoiseq)
          END IF
          IF (PRESENT(gecros_state)) THEN
!$acc update device(gecros_state)
          END IF
          IF (PRESENT(ch)) THEN
!$acc update device(ch)
          END IF
          IF (PRESENT(fgdp)) THEN
!$acc update device(fgdp)
          END IF
          IF (PRESENT(dfgdp)) THEN
!$acc update device(dfgdp)
          END IF
          IF (PRESENT(vdfg)) THEN
!$acc update device(vdfg)
          END IF
          IF (PRESENT(om_tmp)) THEN
!$acc update device(om_tmp)
          END IF
          IF (PRESENT(om_s)) THEN
!$acc update device(om_s)
          END IF
          IF (PRESENT(om_u)) THEN
!$acc update device(om_u)
          END IF
          IF (PRESENT(om_v)) THEN
!$acc update device(om_v)
          END IF
          IF (PRESENT(om_depth)) THEN
!$acc update device(om_depth)
          END IF
          IF (PRESENT(om_ml)) THEN
!$acc update device(om_ml)
          END IF
          IF (PRESENT(om_lon)) THEN
!$acc update device(om_lon)
          END IF
          IF (PRESENT(om_lat)) THEN
!$acc update device(om_lat)
          END IF
          IF (PRESENT(msfu)) THEN
!$acc update device(msfu)
          END IF
          IF (PRESENT(msfv)) THEN
!$acc update device(msfv)
          END IF
          IF (PRESENT(msft)) THEN
!$acc update device(msft)
          END IF
          IF (PRESENT(om_tini)) THEN
!$acc update device(om_tini)
          END IF
          IF (PRESENT(om_sini)) THEN
!$acc update device(om_sini)
          END IF
#if (WRF_CHEM == 1)
          IF (PRESENT(e_bio)) THEN
!$acc update device(e_bio)
          END IF
#endif
          IF (PRESENT(numc)) THEN
!$acc update device(numc)
          END IF
          IF (PRESENT(nump)) THEN
!$acc update device(nump)
          END IF
          IF (PRESENT(sabv)) THEN
!$acc update device(sabv)
          END IF
          IF (PRESENT(sabg)) THEN
!$acc update device(sabg)
          END IF
          IF (PRESENT(lwup)) THEN
!$acc update device(lwup)
          END IF
          IF (PRESENT(snl)) THEN
!$acc update device(snl)
          END IF
          IF (PRESENT(snowdp)) THEN
!$acc update device(snowdp)
          END IF
          IF (PRESENT(wtc)) THEN
!$acc update device(wtc)
          END IF
          IF (PRESENT(wtp)) THEN
!$acc update device(wtp)
          END IF
          IF (PRESENT(h2osno)) THEN
!$acc update device(h2osno)
          END IF
          IF (PRESENT(t_grnd)) THEN
!$acc update device(t_grnd)
          END IF
          IF (PRESENT(t_veg)) THEN
!$acc update device(t_veg)
          END IF
          IF (PRESENT(h2ocan)) THEN
!$acc update device(h2ocan)
          END IF
          IF (PRESENT(h2ocan_col)) THEN
!$acc update device(h2ocan_col)
          END IF
          IF (PRESENT(t2m_max)) THEN
!$acc update device(t2m_max)
          END IF
          IF (PRESENT(t2m_min)) THEN
!$acc update device(t2m_min)
          END IF
          IF (PRESENT(t2clm)) THEN
!$acc update device(t2clm)
          END IF
          IF (PRESENT(t_ref2m)) THEN
!$acc update device(t_ref2m)
          END IF
          IF (PRESENT(h2osoi_liq_s1)) THEN
!$acc update device(h2osoi_liq_s1)
          END IF
          IF (PRESENT(h2osoi_liq_s2)) THEN
!$acc update device(h2osoi_liq_s2)
          END IF
          IF (PRESENT(h2osoi_liq_s3)) THEN
!$acc update device(h2osoi_liq_s3)
          END IF
          IF (PRESENT(h2osoi_liq_s4)) THEN
!$acc update device(h2osoi_liq_s4)
          END IF
          IF (PRESENT(h2osoi_liq_s5)) THEN
!$acc update device(h2osoi_liq_s5)
          END IF
          IF (PRESENT(h2osoi_liq1)) THEN
!$acc update device(h2osoi_liq1)
          END IF
          IF (PRESENT(h2osoi_liq2)) THEN
!$acc update device(h2osoi_liq2)
          END IF
          IF (PRESENT(h2osoi_liq3)) THEN
!$acc update device(h2osoi_liq3)
          END IF
          IF (PRESENT(h2osoi_liq4)) THEN
!$acc update device(h2osoi_liq4)
          END IF
          IF (PRESENT(h2osoi_liq5)) THEN
!$acc update device(h2osoi_liq5)
          END IF
          IF (PRESENT(h2osoi_liq6)) THEN
!$acc update device(h2osoi_liq6)
          END IF
          IF (PRESENT(h2osoi_liq7)) THEN
!$acc update device(h2osoi_liq7)
          END IF
          IF (PRESENT(h2osoi_liq8)) THEN
!$acc update device(h2osoi_liq8)
          END IF
          IF (PRESENT(h2osoi_liq9)) THEN
!$acc update device(h2osoi_liq9)
          END IF
          IF (PRESENT(h2osoi_liq10)) THEN
!$acc update device(h2osoi_liq10)
          END IF
          IF (PRESENT(h2osoi_ice_s1)) THEN
!$acc update device(h2osoi_ice_s1)
          END IF
          IF (PRESENT(h2osoi_ice_s2)) THEN
!$acc update device(h2osoi_ice_s2)
          END IF
          IF (PRESENT(h2osoi_ice_s3)) THEN
!$acc update device(h2osoi_ice_s3)
          END IF
          IF (PRESENT(h2osoi_ice_s4)) THEN
!$acc update device(h2osoi_ice_s4)
          END IF
          IF (PRESENT(h2osoi_ice_s5)) THEN
!$acc update device(h2osoi_ice_s5)
          END IF
          IF (PRESENT(h2osoi_ice1)) THEN
!$acc update device(h2osoi_ice1)
          END IF
          IF (PRESENT(h2osoi_ice2)) THEN
!$acc update device(h2osoi_ice2)
          END IF
          IF (PRESENT(h2osoi_ice3)) THEN
!$acc update device(h2osoi_ice3)
          END IF
          IF (PRESENT(h2osoi_ice4)) THEN
!$acc update device(h2osoi_ice4)
          END IF
          IF (PRESENT(h2osoi_ice5)) THEN
!$acc update device(h2osoi_ice5)
          END IF
          IF (PRESENT(h2osoi_ice6)) THEN
!$acc update device(h2osoi_ice6)
          END IF
          IF (PRESENT(h2osoi_ice7)) THEN
!$acc update device(h2osoi_ice7)
          END IF
          IF (PRESENT(h2osoi_ice8)) THEN
!$acc update device(h2osoi_ice8)
          END IF
          IF (PRESENT(h2osoi_ice9)) THEN
!$acc update device(h2osoi_ice9)
          END IF
          IF (PRESENT(h2osoi_ice10)) THEN
!$acc update device(h2osoi_ice10)
          END IF
          IF (PRESENT(t_soisno_s1)) THEN
!$acc update device(t_soisno_s1)
          END IF
          IF (PRESENT(t_soisno_s2)) THEN
!$acc update device(t_soisno_s2)
          END IF
          IF (PRESENT(t_soisno_s3)) THEN
!$acc update device(t_soisno_s3)
          END IF
          IF (PRESENT(t_soisno_s4)) THEN
!$acc update device(t_soisno_s4)
          END IF
          IF (PRESENT(t_soisno_s5)) THEN
!$acc update device(t_soisno_s5)
          END IF
          IF (PRESENT(t_soisno1)) THEN
!$acc update device(t_soisno1)
          END IF
          IF (PRESENT(t_soisno2)) THEN
!$acc update device(t_soisno2)
          END IF
          IF (PRESENT(t_soisno3)) THEN
!$acc update device(t_soisno3)
          END IF
          IF (PRESENT(t_soisno4)) THEN
!$acc update device(t_soisno4)
          END IF
          IF (PRESENT(t_soisno5)) THEN
!$acc update device(t_soisno5)
          END IF
          IF (PRESENT(t_soisno6)) THEN
!$acc update device(t_soisno6)
          END IF
          IF (PRESENT(t_soisno7)) THEN
!$acc update device(t_soisno7)
          END IF
          IF (PRESENT(t_soisno8)) THEN
!$acc update device(t_soisno8)
          END IF
          IF (PRESENT(t_soisno9)) THEN
!$acc update device(t_soisno9)
          END IF
          IF (PRESENT(t_soisno10)) THEN
!$acc update device(t_soisno10)
          END IF
          IF (PRESENT(dzsnow1)) THEN
!$acc update device(dzsnow1)
          END IF
          IF (PRESENT(dzsnow2)) THEN
!$acc update device(dzsnow2)
          END IF
          IF (PRESENT(dzsnow3)) THEN
!$acc update device(dzsnow3)
          END IF
          IF (PRESENT(dzsnow4)) THEN
!$acc update device(dzsnow4)
          END IF
          IF (PRESENT(dzsnow5)) THEN
!$acc update device(dzsnow5)
          END IF
          IF (PRESENT(snowrds1)) THEN
!$acc update device(snowrds1)
          END IF
          IF (PRESENT(snowrds2)) THEN
!$acc update device(snowrds2)
          END IF
          IF (PRESENT(snowrds3)) THEN
!$acc update device(snowrds3)
          END IF
          IF (PRESENT(snowrds4)) THEN
!$acc update device(snowrds4)
          END IF
          IF (PRESENT(snowrds5)) THEN
!$acc update device(snowrds5)
          END IF
          IF (PRESENT(t_lake1)) THEN
!$acc update device(t_lake1)
          END IF
          IF (PRESENT(t_lake2)) THEN
!$acc update device(t_lake2)
          END IF
          IF (PRESENT(t_lake3)) THEN
!$acc update device(t_lake3)
          END IF
          IF (PRESENT(t_lake4)) THEN
!$acc update device(t_lake4)
          END IF
          IF (PRESENT(t_lake5)) THEN
!$acc update device(t_lake5)
          END IF
          IF (PRESENT(t_lake6)) THEN
!$acc update device(t_lake6)
          END IF
          IF (PRESENT(t_lake7)) THEN
!$acc update device(t_lake7)
          END IF
          IF (PRESENT(t_lake8)) THEN
!$acc update device(t_lake8)
          END IF
          IF (PRESENT(t_lake9)) THEN
!$acc update device(t_lake9)
          END IF
          IF (PRESENT(t_lake10)) THEN
!$acc update device(t_lake10)
          END IF
          IF (PRESENT(h2osoi_vol1)) THEN
!$acc update device(h2osoi_vol1)
          END IF
          IF (PRESENT(h2osoi_vol2)) THEN
!$acc update device(h2osoi_vol2)
          END IF
          IF (PRESENT(h2osoi_vol3)) THEN
!$acc update device(h2osoi_vol3)
          END IF
          IF (PRESENT(h2osoi_vol4)) THEN
!$acc update device(h2osoi_vol4)
          END IF
          IF (PRESENT(h2osoi_vol5)) THEN
!$acc update device(h2osoi_vol5)
          END IF
          IF (PRESENT(h2osoi_vol6)) THEN
!$acc update device(h2osoi_vol6)
          END IF
          IF (PRESENT(h2osoi_vol7)) THEN
!$acc update device(h2osoi_vol7)
          END IF
          IF (PRESENT(h2osoi_vol8)) THEN
!$acc update device(h2osoi_vol8)
          END IF
          IF (PRESENT(h2osoi_vol9)) THEN
!$acc update device(h2osoi_vol9)
          END IF
          IF (PRESENT(h2osoi_vol10)) THEN
!$acc update device(h2osoi_vol10)
          END IF
          IF (PRESENT(albedosubgrid)) THEN
!$acc update device(albedosubgrid)
          END IF
          IF (PRESENT(lhsubgrid)) THEN
!$acc update device(lhsubgrid)
          END IF
          IF (PRESENT(hfxsubgrid)) THEN
!$acc update device(hfxsubgrid)
          END IF
          IF (PRESENT(lwupsubgrid)) THEN
!$acc update device(lwupsubgrid)
          END IF
          IF (PRESENT(q2subgrid)) THEN
!$acc update device(q2subgrid)
          END IF
          IF (PRESENT(sabvsubgrid)) THEN
!$acc update device(sabvsubgrid)
          END IF
          IF (PRESENT(sabgsubgrid)) THEN
!$acc update device(sabgsubgrid)
          END IF
          IF (PRESENT(nrasubgrid)) THEN
!$acc update device(nrasubgrid)
          END IF
          IF (PRESENT(swupsubgrid)) THEN
!$acc update device(swupsubgrid)
          END IF
          IF (PRESENT(lhsoi)) THEN
!$acc update device(lhsoi)
          END IF
          IF (PRESENT(lhveg)) THEN
!$acc update device(lhveg)
          END IF
          IF (PRESENT(lhtran)) THEN
!$acc update device(lhtran)
          END IF
          IF (PRESENT(t_veg24)) THEN
!$acc update device(t_veg24)
          END IF
          IF (PRESENT(t_veg240)) THEN
!$acc update device(t_veg240)
          END IF
          IF (PRESENT(fsun24)) THEN
!$acc update device(fsun24)
          END IF
          IF (PRESENT(fsun240)) THEN
!$acc update device(fsun240)
          END IF
          IF (PRESENT(fsd24)) THEN
!$acc update device(fsd24)
          END IF
          IF (PRESENT(fsd240)) THEN
!$acc update device(fsd240)
          END IF
          IF (PRESENT(fsi24)) THEN
!$acc update device(fsi24)
          END IF
          IF (PRESENT(fsi240)) THEN
!$acc update device(fsi240)
          END IF
          IF (PRESENT(laip)) THEN
!$acc update device(laip)
          END IF
#ifdef CN
          IF (PRESENT(dyntlai)) THEN
!$acc update device(dyntlai)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dyntsai)) THEN
!$acc update device(dyntsai)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dyntop)) THEN
!$acc update device(dyntop)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dynbot)) THEN
!$acc update device(dynbot)
          END IF
#endif
#ifdef CN
          IF (PRESENT(htmx)) THEN
!$acc update device(htmx)
          END IF
#endif
#ifdef CN
          IF (PRESENT(croplive)) THEN
!$acc update device(croplive)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd1020)) THEN
!$acc update device(gdd1020)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd820)) THEN
!$acc update device(gdd820)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd020)) THEN
!$acc update device(gdd020)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc)) THEN
!$acc update device(grainc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc_storage)) THEN
!$acc update device(grainc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc_xfer)) THEN
!$acc update device(grainc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn)) THEN
!$acc update device(grainn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn_storage)) THEN
!$acc update device(grainn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn_xfer)) THEN
!$acc update device(grainn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(days_active)) THEN
!$acc update device(days_active)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_flag)) THEN
!$acc update device(onset_flag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_counter)) THEN
!$acc update device(onset_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_gddflag)) THEN
!$acc update device(onset_gddflag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_fdd)) THEN
!$acc update device(onset_fdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_gdd)) THEN
!$acc update device(onset_gdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_swi)) THEN
!$acc update device(onset_swi)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_flag)) THEN
!$acc update device(offset_flag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_counter)) THEN
!$acc update device(offset_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_fdd)) THEN
!$acc update device(offset_fdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_swi)) THEN
!$acc update device(offset_swi)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dayl)) THEN
!$acc update device(dayl)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annavg_t2m)) THEN
!$acc update device(annavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempavg_t2m)) THEN
!$acc update device(tempavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempsum_potential_gpp)) THEN
!$acc update device(tempsum_potential_gpp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_potential_gpp)) THEN
!$acc update device(annsum_potential_gpp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempmax_retransn)) THEN
!$acc update device(tempmax_retransn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annmax_retransn)) THEN
!$acc update device(annmax_retransn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prev_leafc_to_litter)) THEN
!$acc update device(prev_leafc_to_litter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prev_frootc_to_litter)) THEN
!$acc update device(prev_frootc_to_litter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempsum_npp)) THEN
!$acc update device(tempsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_npp)) THEN
!$acc update device(annsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc)) THEN
!$acc update device(leafc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc_storage)) THEN
!$acc update device(leafc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc_xfer)) THEN
!$acc update device(leafc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc)) THEN
!$acc update device(frootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc_storage)) THEN
!$acc update device(frootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc_xfer)) THEN
!$acc update device(frootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc)) THEN
!$acc update device(livestemc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc_storage)) THEN
!$acc update device(livestemc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc_xfer)) THEN
!$acc update device(livestemc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc)) THEN
!$acc update device(deadstemc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc_storage)) THEN
!$acc update device(deadstemc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc_xfer)) THEN
!$acc update device(deadstemc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc)) THEN
!$acc update device(livecrootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc_storage)) THEN
!$acc update device(livecrootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc_xfer)) THEN
!$acc update device(livecrootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc)) THEN
!$acc update device(deadcrootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc_storage)) THEN
!$acc update device(deadcrootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc_xfer)) THEN
!$acc update device(deadcrootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cpool)) THEN
!$acc update device(cpool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(pft_ctrunc)) THEN
!$acc update device(pft_ctrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn)) THEN
!$acc update device(leafn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn_storage)) THEN
!$acc update device(leafn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn_xfer)) THEN
!$acc update device(leafn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn)) THEN
!$acc update device(frootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn_storage)) THEN
!$acc update device(frootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn_xfer)) THEN
!$acc update device(frootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn)) THEN
!$acc update device(livestemn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn_storage)) THEN
!$acc update device(livestemn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn_xfer)) THEN
!$acc update device(livestemn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn)) THEN
!$acc update device(deadstemn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn_storage)) THEN
!$acc update device(deadstemn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn_xfer)) THEN
!$acc update device(deadstemn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn)) THEN
!$acc update device(livecrootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn_storage)) THEN
!$acc update device(livecrootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn_xfer)) THEN
!$acc update device(livecrootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn)) THEN
!$acc update device(deadcrootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn_storage)) THEN
!$acc update device(deadcrootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn_xfer)) THEN
!$acc update device(deadcrootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(npool)) THEN
!$acc update device(npool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(pft_ntrunc)) THEN
!$acc update device(pft_ntrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gresp_storage)) THEN
!$acc update device(gresp_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gresp_xfer)) THEN
!$acc update device(gresp_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(xsmrpool)) THEN
!$acc update device(xsmrpool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_counter)) THEN
!$acc update device(annsum_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cannsum_npp)) THEN
!$acc update device(cannsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cannavg_t2m)) THEN
!$acc update device(cannavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(wf)) THEN
!$acc update device(wf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(me)) THEN
!$acc update device(me)
          END IF
#endif
#ifdef CN
          IF (PRESENT(mean_fire_prob)) THEN
!$acc update device(mean_fire_prob)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cwdc)) THEN
!$acc update device(cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr1c)) THEN
!$acc update device(litr1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr2c)) THEN
!$acc update device(litr2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr3c)) THEN
!$acc update device(litr3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil1c)) THEN
!$acc update device(soil1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil2c)) THEN
!$acc update device(soil2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil3c)) THEN
!$acc update device(soil3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil4c)) THEN
!$acc update device(soil4c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(seedc)) THEN
!$acc update device(seedc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(col_ctrunc)) THEN
!$acc update device(col_ctrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod10c)) THEN
!$acc update device(prod10c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100c)) THEN
!$acc update device(prod100c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cwdn)) THEN
!$acc update device(cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr1n)) THEN
!$acc update device(litr1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr2n)) THEN
!$acc update device(litr2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr3n)) THEN
!$acc update device(litr3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil1n)) THEN
!$acc update device(soil1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil2n)) THEN
!$acc update device(soil2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil3n)) THEN
!$acc update device(soil3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil4n)) THEN
!$acc update device(soil4n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(seedn)) THEN
!$acc update device(seedn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(col_ntrunc)) THEN
!$acc update device(col_ntrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod10n)) THEN
!$acc update device(prod10n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100n)) THEN
!$acc update device(prod100n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(sminn)) THEN
!$acc update device(sminn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(totlitc)) THEN
!$acc update device(totlitc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedc_to_leaf)) THEN
!$acc update device(dwt_seedc_to_leaf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedc_to_deadstem)) THEN
!$acc update device(dwt_seedc_to_deadstem)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_conv_cflux)) THEN
!$acc update device(dwt_conv_cflux)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod10c_gain)) THEN
!$acc update device(dwt_prod10c_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod100c_gain)) THEN
!$acc update device(dwt_prod100c_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100c_loss)) THEN
!$acc update device(prod100c_loss)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr1c)) THEN
!$acc update device(dwt_frootc_to_litr1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr2c)) THEN
!$acc update device(dwt_frootc_to_litr2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr3c)) THEN
!$acc update device(dwt_frootc_to_litr3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_livecrootc_to_cwdc)) THEN
!$acc update device(dwt_livecrootc_to_cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_deadcrootc_to_cwdc)) THEN
!$acc update device(dwt_deadcrootc_to_cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedn_to_leaf)) THEN
!$acc update device(dwt_seedn_to_leaf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedn_to_deadstem)) THEN
!$acc update device(dwt_seedn_to_deadstem)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_conv_nflux)) THEN
!$acc update device(dwt_conv_nflux)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod10n_gain)) THEN
!$acc update device(dwt_prod10n_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod100n_gain)) THEN
!$acc update device(dwt_prod100n_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100n_loss)) THEN
!$acc update device(prod100n_loss)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr1n)) THEN
!$acc update device(dwt_frootn_to_litr1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr2n)) THEN
!$acc update device(dwt_frootn_to_litr2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr3n)) THEN
!$acc update device(dwt_frootn_to_litr3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_livecrootn_to_cwdn)) THEN
!$acc update device(dwt_livecrootn_to_cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_deadcrootn_to_cwdn)) THEN
!$acc update device(dwt_deadcrootn_to_cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(retransn)) THEN
!$acc update device(retransn)
          END IF
#endif
          IF (PRESENT(pct_pft_input)) THEN
!$acc update device(pct_pft_input)
          END IF
          IF (PRESENT(shadowmask)) THEN
!$acc update device(shadowmask)
          END IF
          IF (PRESENT(swnorm)) THEN
!$acc update device(swnorm)
          END IF
          IF (PRESENT(slope)) THEN
!$acc update device(slope)
          END IF
          IF (PRESENT(slp_azi)) THEN
!$acc update device(slp_azi)
          END IF
          IF (PRESENT(diffuse_frac)) THEN
!$acc update device(diffuse_frac)
          END IF
          IF (PRESENT(coszen)) THEN
!$acc update device(coszen)
          END IF
          IF (PRESENT(hrang)) THEN
!$acc update device(hrang)
          END IF
          IF (PRESENT(xlat_urb2d)) THEN
!$acc update device(xlat_urb2d)
          END IF
          IF (PRESENT(dzr)) THEN
!$acc update device(dzr)
          END IF
          IF (PRESENT(dzb)) THEN
!$acc update device(dzb)
          END IF
          IF (PRESENT(dzg)) THEN
!$acc update device(dzg)
          END IF
          IF (PRESENT(tr_urb2d)) THEN
!$acc update device(tr_urb2d)
          END IF
          IF (PRESENT(tb_urb2d)) THEN
!$acc update device(tb_urb2d)
          END IF
          IF (PRESENT(tg_urb2d)) THEN
!$acc update device(tg_urb2d)
          END IF
          IF (PRESENT(tc_urb2d)) THEN
!$acc update device(tc_urb2d)
          END IF
          IF (PRESENT(qc_urb2d)) THEN
!$acc update device(qc_urb2d)
          END IF
          IF (PRESENT(uc_urb2d)) THEN
!$acc update device(uc_urb2d)
          END IF
          IF (PRESENT(xxxr_urb2d)) THEN
!$acc update device(xxxr_urb2d)
          END IF
          IF (PRESENT(xxxb_urb2d)) THEN
!$acc update device(xxxb_urb2d)
          END IF
          IF (PRESENT(xxxg_urb2d)) THEN
!$acc update device(xxxg_urb2d)
          END IF
          IF (PRESENT(xxxc_urb2d)) THEN
!$acc update device(xxxc_urb2d)
          END IF
          IF (PRESENT(cmcr_urb2d)) THEN
!$acc update device(cmcr_urb2d)
          END IF
          IF (PRESENT(tgr_urb2d)) THEN
!$acc update device(tgr_urb2d)
          END IF
          IF (PRESENT(tgrl_urb3d)) THEN
!$acc update device(tgrl_urb3d)
          END IF
          IF (PRESENT(smr_urb3d)) THEN
!$acc update device(smr_urb3d)
          END IF
          IF (PRESENT(drelr_urb2d)) THEN
!$acc update device(drelr_urb2d)
          END IF
          IF (PRESENT(drelb_urb2d)) THEN
!$acc update device(drelb_urb2d)
          END IF
          IF (PRESENT(drelg_urb2d)) THEN
!$acc update device(drelg_urb2d)
          END IF
          IF (PRESENT(flxhumr_urb2d)) THEN
!$acc update device(flxhumr_urb2d)
          END IF
          IF (PRESENT(flxhumb_urb2d)) THEN
!$acc update device(flxhumb_urb2d)
          END IF
          IF (PRESENT(flxhumg_urb2d)) THEN
!$acc update device(flxhumg_urb2d)
          END IF
          IF (PRESENT(trl_urb3d)) THEN
!$acc update device(trl_urb3d)
          END IF
          IF (PRESENT(tbl_urb3d)) THEN
!$acc update device(tbl_urb3d)
          END IF
          IF (PRESENT(tgl_urb3d)) THEN
!$acc update device(tgl_urb3d)
          END IF
          IF (PRESENT(sh_urb2d)) THEN
!$acc update device(sh_urb2d)
          END IF
          IF (PRESENT(lh_urb2d)) THEN
!$acc update device(lh_urb2d)
          END IF
          IF (PRESENT(g_urb2d)) THEN
!$acc update device(g_urb2d)
          END IF
          IF (PRESENT(rn_urb2d)) THEN
!$acc update device(rn_urb2d)
          END IF
          IF (PRESENT(ts_urb2d)) THEN
!$acc update device(ts_urb2d)
          END IF
          IF (PRESENT(frc_urb2d)) THEN
!$acc update device(frc_urb2d)
          END IF
          IF (PRESENT(utype_urb2d)) THEN
!$acc update device(utype_urb2d)
          END IF
          IF (PRESENT(cmr_sfcdif)) THEN
!$acc update device(cmr_sfcdif)
          END IF
          IF (PRESENT(chr_sfcdif)) THEN
!$acc update device(chr_sfcdif)
          END IF
          IF (PRESENT(cmc_sfcdif)) THEN
!$acc update device(cmc_sfcdif)
          END IF
          IF (PRESENT(chc_sfcdif)) THEN
!$acc update device(chc_sfcdif)
          END IF
          IF (PRESENT(cmgr_sfcdif)) THEN
!$acc update device(cmgr_sfcdif)
          END IF
          IF (PRESENT(chgr_sfcdif)) THEN
!$acc update device(chgr_sfcdif)
          END IF
          IF (PRESENT(alswvisdir)) THEN
!$acc update device(alswvisdir)
          END IF
          IF (PRESENT(alswvisdif)) THEN
!$acc update device(alswvisdif)
          END IF
          IF (PRESENT(alswnirdir)) THEN
!$acc update device(alswnirdir)
          END IF
          IF (PRESENT(alswnirdif)) THEN
!$acc update device(alswnirdif)
          END IF
          IF (PRESENT(swvisdir)) THEN
!$acc update device(swvisdir)
          END IF
          IF (PRESENT(swvisdif)) THEN
!$acc update device(swvisdif)
          END IF
          IF (PRESENT(swnirdir)) THEN
!$acc update device(swnirdir)
          END IF
          IF (PRESENT(swnirdif)) THEN
!$acc update device(swnirdif)
          END IF
          IF (PRESENT(ssib_br)) THEN
!$acc update device(ssib_br)
          END IF
          IF (PRESENT(ssib_fm)) THEN
!$acc update device(ssib_fm)
          END IF
          IF (PRESENT(ssib_fh)) THEN
!$acc update device(ssib_fh)
          END IF
          IF (PRESENT(ssib_cm)) THEN
!$acc update device(ssib_cm)
          END IF
          IF (PRESENT(ssibxdd)) THEN
!$acc update device(ssibxdd)
          END IF
          IF (PRESENT(ssib_lhf)) THEN
!$acc update device(ssib_lhf)
          END IF
          IF (PRESENT(ssib_shf)) THEN
!$acc update device(ssib_shf)
          END IF
          IF (PRESENT(ssib_ghf)) THEN
!$acc update device(ssib_ghf)
          END IF
          IF (PRESENT(ssib_egs)) THEN
!$acc update device(ssib_egs)
          END IF
          IF (PRESENT(ssib_eci)) THEN
!$acc update device(ssib_eci)
          END IF
          IF (PRESENT(ssib_ect)) THEN
!$acc update device(ssib_ect)
          END IF
          IF (PRESENT(ssib_egi)) THEN
!$acc update device(ssib_egi)
          END IF
          IF (PRESENT(ssib_egt)) THEN
!$acc update device(ssib_egt)
          END IF
          IF (PRESENT(ssib_sdn)) THEN
!$acc update device(ssib_sdn)
          END IF
          IF (PRESENT(ssib_sup)) THEN
!$acc update device(ssib_sup)
          END IF
          IF (PRESENT(ssib_ldn)) THEN
!$acc update device(ssib_ldn)
          END IF
          IF (PRESENT(ssib_lup)) THEN
!$acc update device(ssib_lup)
          END IF
          IF (PRESENT(ssib_wat)) THEN
!$acc update device(ssib_wat)
          END IF
          IF (PRESENT(ssib_shc)) THEN
!$acc update device(ssib_shc)
          END IF
          IF (PRESENT(ssib_shg)) THEN
!$acc update device(ssib_shg)
          END IF
          IF (PRESENT(ssib_lai)) THEN
!$acc update device(ssib_lai)
          END IF
          IF (PRESENT(ssib_vcf)) THEN
!$acc update device(ssib_vcf)
          END IF
          IF (PRESENT(ssib_z00)) THEN
!$acc update device(ssib_z00)
          END IF
          IF (PRESENT(ssib_veg)) THEN
!$acc update device(ssib_veg)
          END IF
          IF (PRESENT(isnow)) THEN
!$acc update device(isnow)
          END IF
          IF (PRESENT(swe)) THEN
!$acc update device(swe)
          END IF
          IF (PRESENT(snowden)) THEN
!$acc update device(snowden)
          END IF
          IF (PRESENT(snowdepth)) THEN
!$acc update device(snowdepth)
          END IF
          IF (PRESENT(tkair)) THEN
!$acc update device(tkair)
          END IF
          IF (PRESENT(dzo1)) THEN
!$acc update device(dzo1)
          END IF
          IF (PRESENT(wo1)) THEN
!$acc update device(wo1)
          END IF
          IF (PRESENT(tssn1)) THEN
!$acc update device(tssn1)
          END IF
          IF (PRESENT(tssno1)) THEN
!$acc update device(tssno1)
          END IF
          IF (PRESENT(bwo1)) THEN
!$acc update device(bwo1)
          END IF
          IF (PRESENT(bto1)) THEN
!$acc update device(bto1)
          END IF
          IF (PRESENT(cto1)) THEN
!$acc update device(cto1)
          END IF
          IF (PRESENT(fio1)) THEN
!$acc update device(fio1)
          END IF
          IF (PRESENT(flo1)) THEN
!$acc update device(flo1)
          END IF
          IF (PRESENT(bio1)) THEN
!$acc update device(bio1)
          END IF
          IF (PRESENT(blo1)) THEN
!$acc update device(blo1)
          END IF
          IF (PRESENT(ho1)) THEN
!$acc update device(ho1)
          END IF
          IF (PRESENT(dzo2)) THEN
!$acc update device(dzo2)
          END IF
          IF (PRESENT(wo2)) THEN
!$acc update device(wo2)
          END IF
          IF (PRESENT(tssn2)) THEN
!$acc update device(tssn2)
          END IF
          IF (PRESENT(tssno2)) THEN
!$acc update device(tssno2)
          END IF
          IF (PRESENT(bwo2)) THEN
!$acc update device(bwo2)
          END IF
          IF (PRESENT(bto2)) THEN
!$acc update device(bto2)
          END IF
          IF (PRESENT(cto2)) THEN
!$acc update device(cto2)
          END IF
          IF (PRESENT(fio2)) THEN
!$acc update device(fio2)
          END IF
          IF (PRESENT(flo2)) THEN
!$acc update device(flo2)
          END IF
          IF (PRESENT(bio2)) THEN
!$acc update device(bio2)
          END IF
          IF (PRESENT(blo2)) THEN
!$acc update device(blo2)
          END IF
          IF (PRESENT(ho2)) THEN
!$acc update device(ho2)
          END IF
          IF (PRESENT(dzo3)) THEN
!$acc update device(dzo3)
          END IF
          IF (PRESENT(wo3)) THEN
!$acc update device(wo3)
          END IF
          IF (PRESENT(tssn3)) THEN
!$acc update device(tssn3)
          END IF
          IF (PRESENT(tssno3)) THEN
!$acc update device(tssno3)
          END IF
          IF (PRESENT(bwo3)) THEN
!$acc update device(bwo3)
          END IF
          IF (PRESENT(bto3)) THEN
!$acc update device(bto3)
          END IF
          IF (PRESENT(cto3)) THEN
!$acc update device(cto3)
          END IF
          IF (PRESENT(fio3)) THEN
!$acc update device(fio3)
          END IF
          IF (PRESENT(flo3)) THEN
!$acc update device(flo3)
          END IF
          IF (PRESENT(bio3)) THEN
!$acc update device(bio3)
          END IF
          IF (PRESENT(blo3)) THEN
!$acc update device(blo3)
          END IF
          IF (PRESENT(ho3)) THEN
!$acc update device(ho3)
          END IF
          IF (PRESENT(dzo4)) THEN
!$acc update device(dzo4)
          END IF
          IF (PRESENT(wo4)) THEN
!$acc update device(wo4)
          END IF
          IF (PRESENT(tssn4)) THEN
!$acc update device(tssn4)
          END IF
          IF (PRESENT(tssno4)) THEN
!$acc update device(tssno4)
          END IF
          IF (PRESENT(bwo4)) THEN
!$acc update device(bwo4)
          END IF
          IF (PRESENT(bto4)) THEN
!$acc update device(bto4)
          END IF
          IF (PRESENT(cto4)) THEN
!$acc update device(cto4)
          END IF
          IF (PRESENT(fio4)) THEN
!$acc update device(fio4)
          END IF
          IF (PRESENT(flo4)) THEN
!$acc update device(flo4)
          END IF
          IF (PRESENT(bio4)) THEN
!$acc update device(bio4)
          END IF
          IF (PRESENT(blo4)) THEN
!$acc update device(blo4)
          END IF
          IF (PRESENT(ho4)) THEN
!$acc update device(ho4)
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
          IF (PRESENT(capg)) THEN
!$acc update device(capg)
          END IF
          IF (PRESENT(hol)) THEN
!$acc update device(hol)
          END IF
          IF (PRESENT(mol)) THEN
!$acc update device(mol)
          END IF
          IF (PRESENT(rainncv)) THEN
!$acc update device(rainncv)
          END IF
          IF (PRESENT(rainshv)) THEN
!$acc update device(rainshv)
          END IF
          IF (PRESENT(rainbl)) THEN
!$acc update device(rainbl)
          END IF
          IF (PRESENT(regime)) THEN
!$acc update device(regime)
          END IF
          IF (PRESENT(thc)) THEN
!$acc update device(thc)
          END IF
          IF (PRESENT(graupelncv)) THEN
!$acc update device(graupelncv)
          END IF
          IF (PRESENT(hailncv)) THEN
!$acc update device(hailncv)
          END IF
          IF (PRESENT(qsg)) THEN
!$acc update device(qsg)
          END IF
          IF (PRESENT(qvg)) THEN
!$acc update device(qvg)
          END IF
          IF (PRESENT(qcg)) THEN
!$acc update device(qcg)
          END IF
          IF (PRESENT(soilt1)) THEN
!$acc update device(soilt1)
          END IF
          IF (PRESENT(tsnav)) THEN
!$acc update device(tsnav)
          END IF
          IF (PRESENT(smfr3d)) THEN
!$acc update device(smfr3d)
          END IF
          IF (PRESENT(keepfr3dflag)) THEN
!$acc update device(keepfr3dflag)
          END IF
          IF (PRESENT(dew)) THEN
!$acc update device(dew)
          END IF
          IF (PRESENT(rhosnf)) THEN
!$acc update device(rhosnf)
          END IF
          IF (PRESENT(precipfr)) THEN
!$acc update device(precipfr)
          END IF
          IF (PRESENT(potevp)) THEN
!$acc update device(potevp)
          END IF
          IF (PRESENT(snopcx)) THEN
!$acc update device(snopcx)
          END IF
          IF (PRESENT(soiltb)) THEN
!$acc update device(soiltb)
          END IF
          IF (PRESENT(sr)) THEN
!$acc update device(sr)
          END IF
          IF (PRESENT(t2_ndg_old)) THEN
!$acc update device(t2_ndg_old)
          END IF
          IF (PRESENT(q2_ndg_old)) THEN
!$acc update device(q2_ndg_old)
          END IF
          IF (PRESENT(t2_ndg_new)) THEN
!$acc update device(t2_ndg_new)
          END IF
          IF (PRESENT(q2_ndg_new)) THEN
!$acc update device(q2_ndg_new)
          END IF
          IF (PRESENT(sn_ndg_old)) THEN
!$acc update device(sn_ndg_old)
          END IF
          IF (PRESENT(sn_ndg_new)) THEN
!$acc update device(sn_ndg_new)
          END IF
          IF (PRESENT(t2obs)) THEN
!$acc update device(t2obs)
          END IF
          IF (PRESENT(q2obs)) THEN
!$acc update device(q2obs)
          END IF
          IF (PRESENT(hd_temf)) THEN
!$acc update device(hd_temf)
          END IF
          IF (PRESENT(te_temf)) THEN
!$acc update device(te_temf)
          END IF
          IF (PRESENT(fcor)) THEN
!$acc update device(fcor)
          END IF
          IF (PRESENT(exch_temf)) THEN
!$acc update device(exch_temf)
          END IF
          IF (PRESENT(wm_temf)) THEN
!$acc update device(wm_temf)
          END IF
          IF (PRESENT(uratx)) THEN
!$acc update device(uratx)
          END IF
          IF (PRESENT(vratx)) THEN
!$acc update device(vratx)
          END IF
          IF (PRESENT(tratx)) THEN
!$acc update device(tratx)
          END IF
          IF (PRESENT(tml)) THEN
!$acc update device(tml)
          END IF
          IF (PRESENT(t0ml)) THEN
!$acc update device(t0ml)
          END IF
          IF (PRESENT(hml)) THEN
!$acc update device(hml)
          END IF
          IF (PRESENT(h0ml)) THEN
!$acc update device(h0ml)
          END IF
          IF (PRESENT(huml)) THEN
!$acc update device(huml)
          END IF
          IF (PRESENT(hvml)) THEN
!$acc update device(hvml)
          END IF
          IF (PRESENT(f)) THEN
!$acc update device(f)
          END IF
          IF (PRESENT(tmoml)) THEN
!$acc update device(tmoml)
          END IF
          IF (PRESENT(ustm)) THEN
!$acc update device(ustm)
          END IF
          IF (PRESENT(ck)) THEN
!$acc update device(ck)
          END IF
          IF (PRESENT(cka)) THEN
!$acc update device(cka)
          END IF
          IF (PRESENT(cd)) THEN
!$acc update device(cd)
          END IF
          IF (PRESENT(cda)) THEN
!$acc update device(cda)
          END IF
          IF (PRESENT(snotime)) THEN
!$acc update device(snotime)
          END IF
          IF (PRESENT(noahres)) THEN
!$acc update device(noahres)
          END IF
          IF (PRESENT(xlat)) THEN
!$acc update device(xlat)
          END IF
          IF (PRESENT(xlong)) THEN
!$acc update device(xlong)
          END IF
          IF (PRESENT(ahe)) THEN
!$acc update device(ahe)
          END IF
          IF (PRESENT(tsk_rural)) THEN
!$acc update device(tsk_rural)
          END IF
          IF (PRESENT(trb_urb4d)) THEN
!$acc update device(trb_urb4d)
          END IF
          IF (PRESENT(tw1_urb4d)) THEN
!$acc update device(tw1_urb4d)
          END IF
          IF (PRESENT(tw2_urb4d)) THEN
!$acc update device(tw2_urb4d)
          END IF
          IF (PRESENT(tgb_urb4d)) THEN
!$acc update device(tgb_urb4d)
          END IF
          IF (PRESENT(tlev_urb3d)) THEN
!$acc update device(tlev_urb3d)
          END IF
          IF (PRESENT(qlev_urb3d)) THEN
!$acc update device(qlev_urb3d)
          END IF
          IF (PRESENT(tw1lev_urb3d)) THEN
!$acc update device(tw1lev_urb3d)
          END IF
          IF (PRESENT(tw2lev_urb3d)) THEN
!$acc update device(tw2lev_urb3d)
          END IF
          IF (PRESENT(tglev_urb3d)) THEN
!$acc update device(tglev_urb3d)
          END IF
          IF (PRESENT(tflev_urb3d)) THEN
!$acc update device(tflev_urb3d)
          END IF
          IF (PRESENT(sf_ac_urb3d)) THEN
!$acc update device(sf_ac_urb3d)
          END IF
          IF (PRESENT(lf_ac_urb3d)) THEN
!$acc update device(lf_ac_urb3d)
          END IF
          IF (PRESENT(cm_ac_urb3d)) THEN
!$acc update device(cm_ac_urb3d)
          END IF
          IF (PRESENT(sfvent_urb3d)) THEN
!$acc update device(sfvent_urb3d)
          END IF
          IF (PRESENT(lfvent_urb3d)) THEN
!$acc update device(lfvent_urb3d)
          END IF
          IF (PRESENT(sfwin1_urb3d)) THEN
!$acc update device(sfwin1_urb3d)
          END IF
          IF (PRESENT(sfwin2_urb3d)) THEN
!$acc update device(sfwin2_urb3d)
          END IF
          IF (PRESENT(sfw1_urb3d)) THEN
!$acc update device(sfw1_urb3d)
          END IF
          IF (PRESENT(sfw2_urb3d)) THEN
!$acc update device(sfw2_urb3d)
          END IF
          IF (PRESENT(sfr_urb3d)) THEN
!$acc update device(sfr_urb3d)
          END IF
          IF (PRESENT(sfg_urb3d)) THEN
!$acc update device(sfg_urb3d)
          END IF
          IF (PRESENT(ep_pv_urb3d)) THEN
!$acc update device(ep_pv_urb3d)
          END IF
          IF (PRESENT(t_pv_urb3d)) THEN
!$acc update device(t_pv_urb3d)
          END IF
          IF (PRESENT(trv_urb4d)) THEN
!$acc update device(trv_urb4d)
          END IF
          IF (PRESENT(qr_urb4d)) THEN
!$acc update device(qr_urb4d)
          END IF
          IF (PRESENT(qgr_urb3d)) THEN
!$acc update device(qgr_urb3d)
          END IF
          IF (PRESENT(tgr_urb3d)) THEN
!$acc update device(tgr_urb3d)
          END IF
          IF (PRESENT(drain_urb4d)) THEN
!$acc update device(drain_urb4d)
          END IF
          IF (PRESENT(draingr_urb3d)) THEN
!$acc update device(draingr_urb3d)
          END IF
          IF (PRESENT(sfrv_urb3d)) THEN
!$acc update device(sfrv_urb3d)
          END IF
          IF (PRESENT(lfrv_urb3d)) THEN
!$acc update device(lfrv_urb3d)
          END IF
          IF (PRESENT(dgr_urb3d)) THEN
!$acc update device(dgr_urb3d)
          END IF
          IF (PRESENT(dg_urb3d)) THEN
!$acc update device(dg_urb3d)
          END IF
          IF (PRESENT(lfr_urb3d)) THEN
!$acc update device(lfr_urb3d)
          END IF
          IF (PRESENT(lfg_urb3d)) THEN
!$acc update device(lfg_urb3d)
          END IF
          IF (PRESENT(swddir)) THEN
!$acc update device(swddir)
          END IF
          IF (PRESENT(swddif)) THEN
!$acc update device(swddif)
          END IF
          IF (PRESENT(lp_urb2d)) THEN
!$acc update device(lp_urb2d)
          END IF
          IF (PRESENT(hi_urb2d)) THEN
!$acc update device(hi_urb2d)
          END IF
          IF (PRESENT(lb_urb2d)) THEN
!$acc update device(lb_urb2d)
          END IF
          IF (PRESENT(hgt_urb2d)) THEN
!$acc update device(hgt_urb2d)
          END IF
          IF (PRESENT(mh_urb2d)) THEN
!$acc update device(mh_urb2d)
          END IF
          IF (PRESENT(stdh_urb2d)) THEN
!$acc update device(stdh_urb2d)
          END IF
          IF (PRESENT(lf_urb2d)) THEN
!$acc update device(lf_urb2d)
          END IF
          IF (PRESENT(lf_urb2d_s)) THEN
!$acc update device(lf_urb2d_s)
          END IF
          IF (PRESENT(z0_urb2d)) THEN
!$acc update device(z0_urb2d)
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
          IF (PRESENT(tsk_save)) THEN
!$acc update device(tsk_save)
          END IF
          IF (PRESENT(cldfra)) THEN
!$acc update device(cldfra)
          END IF
          IF (PRESENT(mosaic_cat_index)) THEN
!$acc update device(mosaic_cat_index)
          END IF
          IF (PRESENT(landusef2)) THEN
!$acc update device(landusef2)
          END IF
          IF (PRESENT(tsk_mosaic)) THEN
!$acc update device(tsk_mosaic)
          END IF
          IF (PRESENT(qsfc_mosaic)) THEN
!$acc update device(qsfc_mosaic)
          END IF
          IF (PRESENT(tslb_mosaic)) THEN
!$acc update device(tslb_mosaic)
          END IF
          IF (PRESENT(smois_mosaic)) THEN
!$acc update device(smois_mosaic)
          END IF
          IF (PRESENT(sh2o_mosaic)) THEN
!$acc update device(sh2o_mosaic)
          END IF
          IF (PRESENT(canwat_mosaic)) THEN
!$acc update device(canwat_mosaic)
          END IF
          IF (PRESENT(snow_mosaic)) THEN
!$acc update device(snow_mosaic)
          END IF
          IF (PRESENT(snowh_mosaic)) THEN
!$acc update device(snowh_mosaic)
          END IF
          IF (PRESENT(snowc_mosaic)) THEN
!$acc update device(snowc_mosaic)
          END IF
          IF (PRESENT(albedo_mosaic)) THEN
!$acc update device(albedo_mosaic)
          END IF
          IF (PRESENT(albbck_mosaic)) THEN
!$acc update device(albbck_mosaic)
          END IF
          IF (PRESENT(emiss_mosaic)) THEN
!$acc update device(emiss_mosaic)
          END IF
          IF (PRESENT(embck_mosaic)) THEN
!$acc update device(embck_mosaic)
          END IF
          IF (PRESENT(znt_mosaic)) THEN
!$acc update device(znt_mosaic)
          END IF
          IF (PRESENT(z0_mosaic)) THEN
!$acc update device(z0_mosaic)
          END IF
          IF (PRESENT(hfx_mosaic)) THEN
!$acc update device(hfx_mosaic)
          END IF
          IF (PRESENT(qfx_mosaic)) THEN
!$acc update device(qfx_mosaic)
          END IF
          IF (PRESENT(lh_mosaic)) THEN
!$acc update device(lh_mosaic)
          END IF
          IF (PRESENT(grdflx_mosaic)) THEN
!$acc update device(grdflx_mosaic)
          END IF
          IF (PRESENT(snotime_mosaic)) THEN
!$acc update device(snotime_mosaic)
          END IF
          IF (PRESENT(rs_mosaic)) THEN
!$acc update device(rs_mosaic)
          END IF
          IF (PRESENT(lai_mosaic)) THEN
!$acc update device(lai_mosaic)
          END IF
          IF (PRESENT(tr_urb2d_mosaic)) THEN
!$acc update device(tr_urb2d_mosaic)
          END IF
          IF (PRESENT(tb_urb2d_mosaic)) THEN
!$acc update device(tb_urb2d_mosaic)
          END IF
          IF (PRESENT(tg_urb2d_mosaic)) THEN
!$acc update device(tg_urb2d_mosaic)
          END IF
          IF (PRESENT(tc_urb2d_mosaic)) THEN
!$acc update device(tc_urb2d_mosaic)
          END IF
          IF (PRESENT(qc_urb2d_mosaic)) THEN
!$acc update device(qc_urb2d_mosaic)
          END IF
          IF (PRESENT(uc_urb2d_mosaic)) THEN
!$acc update device(uc_urb2d_mosaic)
          END IF
          IF (PRESENT(trl_urb3d_mosaic)) THEN
!$acc update device(trl_urb3d_mosaic)
          END IF
          IF (PRESENT(tbl_urb3d_mosaic)) THEN
!$acc update device(tbl_urb3d_mosaic)
          END IF
          IF (PRESENT(tgl_urb3d_mosaic)) THEN
!$acc update device(tgl_urb3d_mosaic)
          END IF
          IF (PRESENT(sh_urb2d_mosaic)) THEN
!$acc update device(sh_urb2d_mosaic)
          END IF
          IF (PRESENT(lh_urb2d_mosaic)) THEN
!$acc update device(lh_urb2d_mosaic)
          END IF
          IF (PRESENT(g_urb2d_mosaic)) THEN
!$acc update device(g_urb2d_mosaic)
          END IF
          IF (PRESENT(rn_urb2d_mosaic)) THEN
!$acc update device(rn_urb2d_mosaic)
          END IF
          IF (PRESENT(ts_urb2d_mosaic)) THEN
!$acc update device(ts_urb2d_mosaic)
          END IF
          IF (PRESENT(ts_rul2d_mosaic)) THEN
!$acc update device(ts_rul2d_mosaic)
          END IF
          IF (PRESENT(sda_hfx)) THEN
!$acc update device(sda_hfx)
          END IF
          IF (PRESENT(sda_qfx)) THEN
!$acc update device(sda_qfx)
          END IF
          IF (PRESENT(hfx_both)) THEN
!$acc update device(hfx_both)
          END IF
          IF (PRESENT(qfx_both)) THEN
!$acc update device(qfx_both)
          END IF
          IF (PRESENT(qnorm)) THEN
!$acc update device(qnorm)
          END IF
          IF (PRESENT(pattern_spp_lsm)) THEN
!$acc update device(pattern_spp_lsm)
          END IF
          IF (PRESENT(field_sf)) THEN
!$acc update device(field_sf)
          END IF
          IF (PRESENT(pattern_spp_pbl)) THEN
!$acc update device(pattern_spp_pbl)
          END IF
          IF (PRESENT(xlaidyn)) THEN
!$acc update device(xlaidyn)
          END IF
          IF (PRESENT(perts_qvapor)) THEN
!$acc update device(perts_qvapor)
          END IF
          IF (PRESENT(perts_th)) THEN
!$acc update device(perts_th)
          END IF
          IF (PRESENT(perts_smois)) THEN
!$acc update device(perts_smois)
          END IF
          IF (PRESENT(perts_tsoil)) THEN
!$acc update device(perts_tsoil)
          END IF
          IF (PRESENT(irrigation)) THEN
!$acc update device(irrigation)
          END IF
          IF (PRESENT(irr_rand_field)) THEN
!$acc update device(irr_rand_field)
          END IF
        ELSE
!$acc update self(sfcheadrt, infxsrt, soldrain, qtiledrain, zwatble2d, acsnom, acsnow, akhs, akms, &
!$acc&   albedo, br, canwat, chklowq, dz8w, dzs, glw, grdflx, gsw, swdown, gz1oz0, hfx, ht, isltyp, &
!$acc&   ivgtyp, lowlyr, mavail, rmol, p8w, pblh, pi_phy, pshltr, fm, fhh, psih, psim, p_phy, q10, &
!$acc&   q2, qfx, qsfc, qshltr, qz0, raincv, rho, sfcevp, sfcexc, sfcrunoff, acrunoff, smois, &
!$acc&   smstav, smstot, snoalb, snow, snowc, snowh, smcrel, th10, th2, thz0, th_phy, tmn, tshltr, &
!$acc&   tsk, tslb, t_phy, u10, udrunoff, ust, uz0, u_phy, v10, vegfra, u10e, v10e, uoce, voce, &
!$acc&   vz0, v_phy, wspd, xice, xland, z, znt, zs, albsi, icedepth, snowsi, xicem, ct, tke_pbl, &
!$acc&   albbck, embck, lh, sh2o, shdmax, shdmin, shdavg, z0, flqc, flhc, psfc, sst, flx4, fvb, &
!$acc&   fbur, fgsn, water_depth, lakedepth2d, savedtke12d, snowdp2d, h2osno2d, snl2d, t_grnd2d, &
!$acc&   t_lake3d, lake_icefrac3d, z_lake3d, dz_lake3d, t_soisno3d, h2osoi_ice3d, h2osoi_liq3d, &
!$acc&   h2osoi_vol3d, z3d, dz3d, zi3d, watsat3d, csol3d, tkmg3d, tkdry3d, tksatu3d, lakemask, &
!$acc&   i_start, i_end, j_start, j_end, zol)
          IF (PRESENT(acgrdflx)) THEN
!$acc update self(acgrdflx)
          END IF
          IF (PRESENT(achfx)) THEN
!$acc update self(achfx)
          END IF
          IF (PRESENT(aclhf)) THEN
!$acc update self(aclhf)
          END IF
          IF (PRESENT(snowfallac)) THEN
!$acc update self(snowfallac)
          END IF
          IF (PRESENT(dx2d)) THEN
!$acc update self(dx2d)
          END IF
          IF (PRESENT(area2d)) THEN
!$acc update self(area2d)
          END IF
          IF (PRESENT(tyr)) THEN
!$acc update self(tyr)
          END IF
          IF (PRESENT(tyra)) THEN
!$acc update self(tyra)
          END IF
          IF (PRESENT(tdly)) THEN
!$acc update self(tdly)
          END IF
          IF (PRESENT(tlag)) THEN
!$acc update self(tlag)
          END IF
          IF (PRESENT(cplmask)) THEN
!$acc update self(cplmask)
          END IF
          IF (PRESENT(sst_input)) THEN
!$acc update self(sst_input)
          END IF
          IF (PRESENT(sstsk)) THEN
!$acc update self(sstsk)
          END IF
          IF (PRESENT(dtw)) THEN
!$acc update self(dtw)
          END IF
          IF (PRESENT(t2)) THEN
!$acc update self(t2)
          END IF
          IF (PRESENT(emiss)) THEN
!$acc update self(emiss)
          END IF
          IF (PRESENT(landusef)) THEN
!$acc update self(landusef)
          END IF
          IF (PRESENT(soilctop)) THEN
!$acc update self(soilctop)
          END IF
          IF (PRESENT(soilcbot)) THEN
!$acc update self(soilcbot)
          END IF
          IF (PRESENT(ra)) THEN
!$acc update self(ra)
          END IF
          IF (PRESENT(rs)) THEN
!$acc update self(rs)
          END IF
          IF (PRESENT(vegf_px)) THEN
!$acc update self(vegf_px)
          END IF
          IF (PRESENT(snowncv)) THEN
!$acc update self(snowncv)
          END IF
          IF (PRESENT(lai)) THEN
!$acc update self(lai)
          END IF
          IF (PRESENT(imperv)) THEN
!$acc update self(imperv)
          END IF
          IF (PRESENT(canfra)) THEN
!$acc update self(canfra)
          END IF
          IF (PRESENT(lai_px)) THEN
!$acc update self(lai_px)
          END IF
          IF (PRESENT(wwlt_px)) THEN
!$acc update self(wwlt_px)
          END IF
          IF (PRESENT(wfc_px)) THEN
!$acc update self(wfc_px)
          END IF
          IF (PRESENT(wsat_px)) THEN
!$acc update self(wsat_px)
          END IF
          IF (PRESENT(clay_px)) THEN
!$acc update self(clay_px)
          END IF
          IF (PRESENT(csand_px)) THEN
!$acc update self(csand_px)
          END IF
          IF (PRESENT(fmsand_px)) THEN
!$acc update self(fmsand_px)
          END IF
          IF (PRESENT(soilcomp)) THEN
!$acc update self(soilcomp)
          END IF
          IF (PRESENT(soilcl1)) THEN
!$acc update self(soilcl1)
          END IF
          IF (PRESENT(soilcl2)) THEN
!$acc update self(soilcl2)
          END IF
          IF (PRESENT(soilcl3)) THEN
!$acc update self(soilcl3)
          END IF
          IF (PRESENT(soilcl4)) THEN
!$acc update self(soilcl4)
          END IF
          IF (PRESENT(isnowxy)) THEN
!$acc update self(isnowxy)
          END IF
          IF (PRESENT(tvxy)) THEN
!$acc update self(tvxy)
          END IF
          IF (PRESENT(tgxy)) THEN
!$acc update self(tgxy)
          END IF
          IF (PRESENT(canicexy)) THEN
!$acc update self(canicexy)
          END IF
          IF (PRESENT(canliqxy)) THEN
!$acc update self(canliqxy)
          END IF
          IF (PRESENT(eahxy)) THEN
!$acc update self(eahxy)
          END IF
          IF (PRESENT(tahxy)) THEN
!$acc update self(tahxy)
          END IF
          IF (PRESENT(cmxy)) THEN
!$acc update self(cmxy)
          END IF
          IF (PRESENT(chxy)) THEN
!$acc update self(chxy)
          END IF
          IF (PRESENT(fwetxy)) THEN
!$acc update self(fwetxy)
          END IF
          IF (PRESENT(sneqvoxy)) THEN
!$acc update self(sneqvoxy)
          END IF
          IF (PRESENT(alboldxy)) THEN
!$acc update self(alboldxy)
          END IF
          IF (PRESENT(qsnowxy)) THEN
!$acc update self(qsnowxy)
          END IF
          IF (PRESENT(qrainxy)) THEN
!$acc update self(qrainxy)
          END IF
          IF (PRESENT(wslakexy)) THEN
!$acc update self(wslakexy)
          END IF
          IF (PRESENT(zwtxy)) THEN
!$acc update self(zwtxy)
          END IF
          IF (PRESENT(waxy)) THEN
!$acc update self(waxy)
          END IF
          IF (PRESENT(wtxy)) THEN
!$acc update self(wtxy)
          END IF
          IF (PRESENT(tsnoxy)) THEN
!$acc update self(tsnoxy)
          END IF
          IF (PRESENT(zsnsoxy)) THEN
!$acc update self(zsnsoxy)
          END IF
          IF (PRESENT(snicexy)) THEN
!$acc update self(snicexy)
          END IF
          IF (PRESENT(snliqxy)) THEN
!$acc update self(snliqxy)
          END IF
          IF (PRESENT(lfmassxy)) THEN
!$acc update self(lfmassxy)
          END IF
          IF (PRESENT(rtmassxy)) THEN
!$acc update self(rtmassxy)
          END IF
          IF (PRESENT(stmassxy)) THEN
!$acc update self(stmassxy)
          END IF
          IF (PRESENT(woodxy)) THEN
!$acc update self(woodxy)
          END IF
          IF (PRESENT(stblcpxy)) THEN
!$acc update self(stblcpxy)
          END IF
          IF (PRESENT(fastcpxy)) THEN
!$acc update self(fastcpxy)
          END IF
          IF (PRESENT(xsaixy)) THEN
!$acc update self(xsaixy)
          END IF
          IF (PRESENT(taussxy)) THEN
!$acc update self(taussxy)
          END IF
          IF (PRESENT(grainxy)) THEN
!$acc update self(grainxy)
          END IF
          IF (PRESENT(gddxy)) THEN
!$acc update self(gddxy)
          END IF
          IF (PRESENT(cropcat)) THEN
!$acc update self(cropcat)
          END IF
          IF (PRESENT(pgsxy)) THEN
!$acc update self(pgsxy)
          END IF
          IF (PRESENT(planting)) THEN
!$acc update self(planting)
          END IF
          IF (PRESENT(harvest)) THEN
!$acc update self(harvest)
          END IF
          IF (PRESENT(season_gdd)) THEN
!$acc update self(season_gdd)
          END IF
          IF (PRESENT(t2mvxy)) THEN
!$acc update self(t2mvxy)
          END IF
          IF (PRESENT(t2mbxy)) THEN
!$acc update self(t2mbxy)
          END IF
          IF (PRESENT(q2mvxy)) THEN
!$acc update self(q2mvxy)
          END IF
          IF (PRESENT(q2mbxy)) THEN
!$acc update self(q2mbxy)
          END IF
          IF (PRESENT(tradxy)) THEN
!$acc update self(tradxy)
          END IF
          IF (PRESENT(neexy)) THEN
!$acc update self(neexy)
          END IF
          IF (PRESENT(gppxy)) THEN
!$acc update self(gppxy)
          END IF
          IF (PRESENT(nppxy)) THEN
!$acc update self(nppxy)
          END IF
          IF (PRESENT(fvegxy)) THEN
!$acc update self(fvegxy)
          END IF
          IF (PRESENT(runsfxy)) THEN
!$acc update self(runsfxy)
          END IF
          IF (PRESENT(runsbxy)) THEN
!$acc update self(runsbxy)
          END IF
          IF (PRESENT(ecanxy)) THEN
!$acc update self(ecanxy)
          END IF
          IF (PRESENT(edirxy)) THEN
!$acc update self(edirxy)
          END IF
          IF (PRESENT(etranxy)) THEN
!$acc update self(etranxy)
          END IF
          IF (PRESENT(fsaxy)) THEN
!$acc update self(fsaxy)
          END IF
          IF (PRESENT(firaxy)) THEN
!$acc update self(firaxy)
          END IF
          IF (PRESENT(aparxy)) THEN
!$acc update self(aparxy)
          END IF
          IF (PRESENT(psnxy)) THEN
!$acc update self(psnxy)
          END IF
          IF (PRESENT(savxy)) THEN
!$acc update self(savxy)
          END IF
          IF (PRESENT(sagxy)) THEN
!$acc update self(sagxy)
          END IF
          IF (PRESENT(rssunxy)) THEN
!$acc update self(rssunxy)
          END IF
          IF (PRESENT(rsshaxy)) THEN
!$acc update self(rsshaxy)
          END IF
          IF (PRESENT(bgapxy)) THEN
!$acc update self(bgapxy)
          END IF
          IF (PRESENT(wgapxy)) THEN
!$acc update self(wgapxy)
          END IF
          IF (PRESENT(tgvxy)) THEN
!$acc update self(tgvxy)
          END IF
          IF (PRESENT(tgbxy)) THEN
!$acc update self(tgbxy)
          END IF
          IF (PRESENT(chvxy)) THEN
!$acc update self(chvxy)
          END IF
          IF (PRESENT(chbxy)) THEN
!$acc update self(chbxy)
          END IF
          IF (PRESENT(shgxy)) THEN
!$acc update self(shgxy)
          END IF
          IF (PRESENT(shcxy)) THEN
!$acc update self(shcxy)
          END IF
          IF (PRESENT(shbxy)) THEN
!$acc update self(shbxy)
          END IF
          IF (PRESENT(evgxy)) THEN
!$acc update self(evgxy)
          END IF
          IF (PRESENT(evbxy)) THEN
!$acc update self(evbxy)
          END IF
          IF (PRESENT(ghvxy)) THEN
!$acc update self(ghvxy)
          END IF
          IF (PRESENT(ghbxy)) THEN
!$acc update self(ghbxy)
          END IF
          IF (PRESENT(irgxy)) THEN
!$acc update self(irgxy)
          END IF
          IF (PRESENT(ircxy)) THEN
!$acc update self(ircxy)
          END IF
          IF (PRESENT(irbxy)) THEN
!$acc update self(irbxy)
          END IF
          IF (PRESENT(trxy)) THEN
!$acc update self(trxy)
          END IF
          IF (PRESENT(evcxy)) THEN
!$acc update self(evcxy)
          END IF
          IF (PRESENT(chleafxy)) THEN
!$acc update self(chleafxy)
          END IF
          IF (PRESENT(chucxy)) THEN
!$acc update self(chucxy)
          END IF
          IF (PRESENT(chv2xy)) THEN
!$acc update self(chv2xy)
          END IF
          IF (PRESENT(chb2xy)) THEN
!$acc update self(chb2xy)
          END IF
          IF (PRESENT(chstarxy)) THEN
!$acc update self(chstarxy)
          END IF
          IF (PRESENT(qintsxy)) THEN
!$acc update self(qintsxy)
          END IF
          IF (PRESENT(qintrxy)) THEN
!$acc update self(qintrxy)
          END IF
          IF (PRESENT(qdripsxy)) THEN
!$acc update self(qdripsxy)
          END IF
          IF (PRESENT(qdriprxy)) THEN
!$acc update self(qdriprxy)
          END IF
          IF (PRESENT(qthrosxy)) THEN
!$acc update self(qthrosxy)
          END IF
          IF (PRESENT(qthrorxy)) THEN
!$acc update self(qthrorxy)
          END IF
          IF (PRESENT(qsnsubxy)) THEN
!$acc update self(qsnsubxy)
          END IF
          IF (PRESENT(qsnfroxy)) THEN
!$acc update self(qsnfroxy)
          END IF
          IF (PRESENT(qsubcxy)) THEN
!$acc update self(qsubcxy)
          END IF
          IF (PRESENT(qfrocxy)) THEN
!$acc update self(qfrocxy)
          END IF
          IF (PRESENT(qevacxy)) THEN
!$acc update self(qevacxy)
          END IF
          IF (PRESENT(qdewcxy)) THEN
!$acc update self(qdewcxy)
          END IF
          IF (PRESENT(qfrzcxy)) THEN
!$acc update self(qfrzcxy)
          END IF
          IF (PRESENT(qmeltcxy)) THEN
!$acc update self(qmeltcxy)
          END IF
          IF (PRESENT(qsnbotxy)) THEN
!$acc update self(qsnbotxy)
          END IF
          IF (PRESENT(pondingxy)) THEN
!$acc update self(pondingxy)
          END IF
          IF (PRESENT(pahxy)) THEN
!$acc update self(pahxy)
          END IF
          IF (PRESENT(pahgxy)) THEN
!$acc update self(pahgxy)
          END IF
          IF (PRESENT(pahvxy)) THEN
!$acc update self(pahvxy)
          END IF
          IF (PRESENT(pahbxy)) THEN
!$acc update self(pahbxy)
          END IF
          IF (PRESENT(qmeltxy)) THEN
!$acc update self(qmeltxy)
          END IF
          IF (PRESENT(fpicexy)) THEN
!$acc update self(fpicexy)
          END IF
          IF (PRESENT(rainlsm)) THEN
!$acc update self(rainlsm)
          END IF
          IF (PRESENT(snowlsm)) THEN
!$acc update self(snowlsm)
          END IF
          IF (PRESENT(forctlsm)) THEN
!$acc update self(forctlsm)
          END IF
          IF (PRESENT(forcqlsm)) THEN
!$acc update self(forcqlsm)
          END IF
          IF (PRESENT(forcplsm)) THEN
!$acc update self(forcplsm)
          END IF
          IF (PRESENT(forczlsm)) THEN
!$acc update self(forczlsm)
          END IF
          IF (PRESENT(forcwlsm)) THEN
!$acc update self(forcwlsm)
          END IF
          IF (PRESENT(acc_ssoil)) THEN
!$acc update self(acc_ssoil)
          END IF
          IF (PRESENT(acc_qinsur)) THEN
!$acc update self(acc_qinsur)
          END IF
          IF (PRESENT(acc_qseva)) THEN
!$acc update self(acc_qseva)
          END IF
          IF (PRESENT(acc_etrani)) THEN
!$acc update self(acc_etrani)
          END IF
          IF (PRESENT(eflxbxy)) THEN
!$acc update self(eflxbxy)
          END IF
          IF (PRESENT(soilenergy)) THEN
!$acc update self(soilenergy)
          END IF
          IF (PRESENT(snowenergy)) THEN
!$acc update self(snowenergy)
          END IF
          IF (PRESENT(canhsxy)) THEN
!$acc update self(canhsxy)
          END IF
          IF (PRESENT(acc_dwaterxy)) THEN
!$acc update self(acc_dwaterxy)
          END IF
          IF (PRESENT(acc_prcpxy)) THEN
!$acc update self(acc_prcpxy)
          END IF
          IF (PRESENT(acc_ecanxy)) THEN
!$acc update self(acc_ecanxy)
          END IF
          IF (PRESENT(acc_etranxy)) THEN
!$acc update self(acc_etranxy)
          END IF
          IF (PRESENT(acc_edirxy)) THEN
!$acc update self(acc_edirxy)
          END IF
          IF (PRESENT(irfract)) THEN
!$acc update self(irfract)
          END IF
          IF (PRESENT(sifract)) THEN
!$acc update self(sifract)
          END IF
          IF (PRESENT(mifract)) THEN
!$acc update self(mifract)
          END IF
          IF (PRESENT(fifract)) THEN
!$acc update self(fifract)
          END IF
          IF (PRESENT(irnumsi)) THEN
!$acc update self(irnumsi)
          END IF
          IF (PRESENT(irnummi)) THEN
!$acc update self(irnummi)
          END IF
          IF (PRESENT(irnumfi)) THEN
!$acc update self(irnumfi)
          END IF
          IF (PRESENT(irwatsi)) THEN
!$acc update self(irwatsi)
          END IF
          IF (PRESENT(irwatmi)) THEN
!$acc update self(irwatmi)
          END IF
          IF (PRESENT(irwatfi)) THEN
!$acc update self(irwatfi)
          END IF
          IF (PRESENT(ireloss)) THEN
!$acc update self(ireloss)
          END IF
          IF (PRESENT(irsivol)) THEN
!$acc update self(irsivol)
          END IF
          IF (PRESENT(irmivol)) THEN
!$acc update self(irmivol)
          END IF
          IF (PRESENT(irfivol)) THEN
!$acc update self(irfivol)
          END IF
          IF (PRESENT(irrsplh)) THEN
!$acc update self(irrsplh)
          END IF
          IF (PRESENT(qtdrain)) THEN
!$acc update self(qtdrain)
          END IF
          IF (PRESENT(td_fraction)) THEN
!$acc update self(td_fraction)
          END IF
          IF (PRESENT(smcwtdxy)) THEN
!$acc update self(smcwtdxy)
          END IF
          IF (PRESENT(rechxy)) THEN
!$acc update self(rechxy)
          END IF
          IF (PRESENT(deeprechxy)) THEN
!$acc update self(deeprechxy)
          END IF
          IF (PRESENT(fdepthxy)) THEN
!$acc update self(fdepthxy)
          END IF
          IF (PRESENT(areaxy)) THEN
!$acc update self(areaxy)
          END IF
          IF (PRESENT(rivercondxy)) THEN
!$acc update self(rivercondxy)
          END IF
          IF (PRESENT(riverbedxy)) THEN
!$acc update self(riverbedxy)
          END IF
          IF (PRESENT(eqzwt)) THEN
!$acc update self(eqzwt)
          END IF
          IF (PRESENT(pexpxy)) THEN
!$acc update self(pexpxy)
          END IF
          IF (PRESENT(qrfxy)) THEN
!$acc update self(qrfxy)
          END IF
          IF (PRESENT(qspringxy)) THEN
!$acc update self(qspringxy)
          END IF
          IF (PRESENT(qslatxy)) THEN
!$acc update self(qslatxy)
          END IF
          IF (PRESENT(qrfsxy)) THEN
!$acc update self(qrfsxy)
          END IF
          IF (PRESENT(qlatxy)) THEN
!$acc update self(qlatxy)
          END IF
          IF (PRESENT(qspringsxy)) THEN
!$acc update self(qspringsxy)
          END IF
          IF (PRESENT(smoiseq)) THEN
!$acc update self(smoiseq)
          END IF
          IF (PRESENT(gecros_state)) THEN
!$acc update self(gecros_state)
          END IF
          IF (PRESENT(ch)) THEN
!$acc update self(ch)
          END IF
          IF (PRESENT(fgdp)) THEN
!$acc update self(fgdp)
          END IF
          IF (PRESENT(dfgdp)) THEN
!$acc update self(dfgdp)
          END IF
          IF (PRESENT(vdfg)) THEN
!$acc update self(vdfg)
          END IF
          IF (PRESENT(om_tmp)) THEN
!$acc update self(om_tmp)
          END IF
          IF (PRESENT(om_s)) THEN
!$acc update self(om_s)
          END IF
          IF (PRESENT(om_u)) THEN
!$acc update self(om_u)
          END IF
          IF (PRESENT(om_v)) THEN
!$acc update self(om_v)
          END IF
          IF (PRESENT(om_depth)) THEN
!$acc update self(om_depth)
          END IF
          IF (PRESENT(om_ml)) THEN
!$acc update self(om_ml)
          END IF
          IF (PRESENT(om_lon)) THEN
!$acc update self(om_lon)
          END IF
          IF (PRESENT(om_lat)) THEN
!$acc update self(om_lat)
          END IF
          IF (PRESENT(msfu)) THEN
!$acc update self(msfu)
          END IF
          IF (PRESENT(msfv)) THEN
!$acc update self(msfv)
          END IF
          IF (PRESENT(msft)) THEN
!$acc update self(msft)
          END IF
          IF (PRESENT(om_tini)) THEN
!$acc update self(om_tini)
          END IF
          IF (PRESENT(om_sini)) THEN
!$acc update self(om_sini)
          END IF
#if (WRF_CHEM == 1)
          IF (PRESENT(e_bio)) THEN
!$acc update self(e_bio)
          END IF
#endif
          IF (PRESENT(numc)) THEN
!$acc update self(numc)
          END IF
          IF (PRESENT(nump)) THEN
!$acc update self(nump)
          END IF
          IF (PRESENT(sabv)) THEN
!$acc update self(sabv)
          END IF
          IF (PRESENT(sabg)) THEN
!$acc update self(sabg)
          END IF
          IF (PRESENT(lwup)) THEN
!$acc update self(lwup)
          END IF
          IF (PRESENT(snl)) THEN
!$acc update self(snl)
          END IF
          IF (PRESENT(snowdp)) THEN
!$acc update self(snowdp)
          END IF
          IF (PRESENT(wtc)) THEN
!$acc update self(wtc)
          END IF
          IF (PRESENT(wtp)) THEN
!$acc update self(wtp)
          END IF
          IF (PRESENT(h2osno)) THEN
!$acc update self(h2osno)
          END IF
          IF (PRESENT(t_grnd)) THEN
!$acc update self(t_grnd)
          END IF
          IF (PRESENT(t_veg)) THEN
!$acc update self(t_veg)
          END IF
          IF (PRESENT(h2ocan)) THEN
!$acc update self(h2ocan)
          END IF
          IF (PRESENT(h2ocan_col)) THEN
!$acc update self(h2ocan_col)
          END IF
          IF (PRESENT(t2m_max)) THEN
!$acc update self(t2m_max)
          END IF
          IF (PRESENT(t2m_min)) THEN
!$acc update self(t2m_min)
          END IF
          IF (PRESENT(t2clm)) THEN
!$acc update self(t2clm)
          END IF
          IF (PRESENT(t_ref2m)) THEN
!$acc update self(t_ref2m)
          END IF
          IF (PRESENT(h2osoi_liq_s1)) THEN
!$acc update self(h2osoi_liq_s1)
          END IF
          IF (PRESENT(h2osoi_liq_s2)) THEN
!$acc update self(h2osoi_liq_s2)
          END IF
          IF (PRESENT(h2osoi_liq_s3)) THEN
!$acc update self(h2osoi_liq_s3)
          END IF
          IF (PRESENT(h2osoi_liq_s4)) THEN
!$acc update self(h2osoi_liq_s4)
          END IF
          IF (PRESENT(h2osoi_liq_s5)) THEN
!$acc update self(h2osoi_liq_s5)
          END IF
          IF (PRESENT(h2osoi_liq1)) THEN
!$acc update self(h2osoi_liq1)
          END IF
          IF (PRESENT(h2osoi_liq2)) THEN
!$acc update self(h2osoi_liq2)
          END IF
          IF (PRESENT(h2osoi_liq3)) THEN
!$acc update self(h2osoi_liq3)
          END IF
          IF (PRESENT(h2osoi_liq4)) THEN
!$acc update self(h2osoi_liq4)
          END IF
          IF (PRESENT(h2osoi_liq5)) THEN
!$acc update self(h2osoi_liq5)
          END IF
          IF (PRESENT(h2osoi_liq6)) THEN
!$acc update self(h2osoi_liq6)
          END IF
          IF (PRESENT(h2osoi_liq7)) THEN
!$acc update self(h2osoi_liq7)
          END IF
          IF (PRESENT(h2osoi_liq8)) THEN
!$acc update self(h2osoi_liq8)
          END IF
          IF (PRESENT(h2osoi_liq9)) THEN
!$acc update self(h2osoi_liq9)
          END IF
          IF (PRESENT(h2osoi_liq10)) THEN
!$acc update self(h2osoi_liq10)
          END IF
          IF (PRESENT(h2osoi_ice_s1)) THEN
!$acc update self(h2osoi_ice_s1)
          END IF
          IF (PRESENT(h2osoi_ice_s2)) THEN
!$acc update self(h2osoi_ice_s2)
          END IF
          IF (PRESENT(h2osoi_ice_s3)) THEN
!$acc update self(h2osoi_ice_s3)
          END IF
          IF (PRESENT(h2osoi_ice_s4)) THEN
!$acc update self(h2osoi_ice_s4)
          END IF
          IF (PRESENT(h2osoi_ice_s5)) THEN
!$acc update self(h2osoi_ice_s5)
          END IF
          IF (PRESENT(h2osoi_ice1)) THEN
!$acc update self(h2osoi_ice1)
          END IF
          IF (PRESENT(h2osoi_ice2)) THEN
!$acc update self(h2osoi_ice2)
          END IF
          IF (PRESENT(h2osoi_ice3)) THEN
!$acc update self(h2osoi_ice3)
          END IF
          IF (PRESENT(h2osoi_ice4)) THEN
!$acc update self(h2osoi_ice4)
          END IF
          IF (PRESENT(h2osoi_ice5)) THEN
!$acc update self(h2osoi_ice5)
          END IF
          IF (PRESENT(h2osoi_ice6)) THEN
!$acc update self(h2osoi_ice6)
          END IF
          IF (PRESENT(h2osoi_ice7)) THEN
!$acc update self(h2osoi_ice7)
          END IF
          IF (PRESENT(h2osoi_ice8)) THEN
!$acc update self(h2osoi_ice8)
          END IF
          IF (PRESENT(h2osoi_ice9)) THEN
!$acc update self(h2osoi_ice9)
          END IF
          IF (PRESENT(h2osoi_ice10)) THEN
!$acc update self(h2osoi_ice10)
          END IF
          IF (PRESENT(t_soisno_s1)) THEN
!$acc update self(t_soisno_s1)
          END IF
          IF (PRESENT(t_soisno_s2)) THEN
!$acc update self(t_soisno_s2)
          END IF
          IF (PRESENT(t_soisno_s3)) THEN
!$acc update self(t_soisno_s3)
          END IF
          IF (PRESENT(t_soisno_s4)) THEN
!$acc update self(t_soisno_s4)
          END IF
          IF (PRESENT(t_soisno_s5)) THEN
!$acc update self(t_soisno_s5)
          END IF
          IF (PRESENT(t_soisno1)) THEN
!$acc update self(t_soisno1)
          END IF
          IF (PRESENT(t_soisno2)) THEN
!$acc update self(t_soisno2)
          END IF
          IF (PRESENT(t_soisno3)) THEN
!$acc update self(t_soisno3)
          END IF
          IF (PRESENT(t_soisno4)) THEN
!$acc update self(t_soisno4)
          END IF
          IF (PRESENT(t_soisno5)) THEN
!$acc update self(t_soisno5)
          END IF
          IF (PRESENT(t_soisno6)) THEN
!$acc update self(t_soisno6)
          END IF
          IF (PRESENT(t_soisno7)) THEN
!$acc update self(t_soisno7)
          END IF
          IF (PRESENT(t_soisno8)) THEN
!$acc update self(t_soisno8)
          END IF
          IF (PRESENT(t_soisno9)) THEN
!$acc update self(t_soisno9)
          END IF
          IF (PRESENT(t_soisno10)) THEN
!$acc update self(t_soisno10)
          END IF
          IF (PRESENT(dzsnow1)) THEN
!$acc update self(dzsnow1)
          END IF
          IF (PRESENT(dzsnow2)) THEN
!$acc update self(dzsnow2)
          END IF
          IF (PRESENT(dzsnow3)) THEN
!$acc update self(dzsnow3)
          END IF
          IF (PRESENT(dzsnow4)) THEN
!$acc update self(dzsnow4)
          END IF
          IF (PRESENT(dzsnow5)) THEN
!$acc update self(dzsnow5)
          END IF
          IF (PRESENT(snowrds1)) THEN
!$acc update self(snowrds1)
          END IF
          IF (PRESENT(snowrds2)) THEN
!$acc update self(snowrds2)
          END IF
          IF (PRESENT(snowrds3)) THEN
!$acc update self(snowrds3)
          END IF
          IF (PRESENT(snowrds4)) THEN
!$acc update self(snowrds4)
          END IF
          IF (PRESENT(snowrds5)) THEN
!$acc update self(snowrds5)
          END IF
          IF (PRESENT(t_lake1)) THEN
!$acc update self(t_lake1)
          END IF
          IF (PRESENT(t_lake2)) THEN
!$acc update self(t_lake2)
          END IF
          IF (PRESENT(t_lake3)) THEN
!$acc update self(t_lake3)
          END IF
          IF (PRESENT(t_lake4)) THEN
!$acc update self(t_lake4)
          END IF
          IF (PRESENT(t_lake5)) THEN
!$acc update self(t_lake5)
          END IF
          IF (PRESENT(t_lake6)) THEN
!$acc update self(t_lake6)
          END IF
          IF (PRESENT(t_lake7)) THEN
!$acc update self(t_lake7)
          END IF
          IF (PRESENT(t_lake8)) THEN
!$acc update self(t_lake8)
          END IF
          IF (PRESENT(t_lake9)) THEN
!$acc update self(t_lake9)
          END IF
          IF (PRESENT(t_lake10)) THEN
!$acc update self(t_lake10)
          END IF
          IF (PRESENT(h2osoi_vol1)) THEN
!$acc update self(h2osoi_vol1)
          END IF
          IF (PRESENT(h2osoi_vol2)) THEN
!$acc update self(h2osoi_vol2)
          END IF
          IF (PRESENT(h2osoi_vol3)) THEN
!$acc update self(h2osoi_vol3)
          END IF
          IF (PRESENT(h2osoi_vol4)) THEN
!$acc update self(h2osoi_vol4)
          END IF
          IF (PRESENT(h2osoi_vol5)) THEN
!$acc update self(h2osoi_vol5)
          END IF
          IF (PRESENT(h2osoi_vol6)) THEN
!$acc update self(h2osoi_vol6)
          END IF
          IF (PRESENT(h2osoi_vol7)) THEN
!$acc update self(h2osoi_vol7)
          END IF
          IF (PRESENT(h2osoi_vol8)) THEN
!$acc update self(h2osoi_vol8)
          END IF
          IF (PRESENT(h2osoi_vol9)) THEN
!$acc update self(h2osoi_vol9)
          END IF
          IF (PRESENT(h2osoi_vol10)) THEN
!$acc update self(h2osoi_vol10)
          END IF
          IF (PRESENT(albedosubgrid)) THEN
!$acc update self(albedosubgrid)
          END IF
          IF (PRESENT(lhsubgrid)) THEN
!$acc update self(lhsubgrid)
          END IF
          IF (PRESENT(hfxsubgrid)) THEN
!$acc update self(hfxsubgrid)
          END IF
          IF (PRESENT(lwupsubgrid)) THEN
!$acc update self(lwupsubgrid)
          END IF
          IF (PRESENT(q2subgrid)) THEN
!$acc update self(q2subgrid)
          END IF
          IF (PRESENT(sabvsubgrid)) THEN
!$acc update self(sabvsubgrid)
          END IF
          IF (PRESENT(sabgsubgrid)) THEN
!$acc update self(sabgsubgrid)
          END IF
          IF (PRESENT(nrasubgrid)) THEN
!$acc update self(nrasubgrid)
          END IF
          IF (PRESENT(swupsubgrid)) THEN
!$acc update self(swupsubgrid)
          END IF
          IF (PRESENT(lhsoi)) THEN
!$acc update self(lhsoi)
          END IF
          IF (PRESENT(lhveg)) THEN
!$acc update self(lhveg)
          END IF
          IF (PRESENT(lhtran)) THEN
!$acc update self(lhtran)
          END IF
          IF (PRESENT(t_veg24)) THEN
!$acc update self(t_veg24)
          END IF
          IF (PRESENT(t_veg240)) THEN
!$acc update self(t_veg240)
          END IF
          IF (PRESENT(fsun24)) THEN
!$acc update self(fsun24)
          END IF
          IF (PRESENT(fsun240)) THEN
!$acc update self(fsun240)
          END IF
          IF (PRESENT(fsd24)) THEN
!$acc update self(fsd24)
          END IF
          IF (PRESENT(fsd240)) THEN
!$acc update self(fsd240)
          END IF
          IF (PRESENT(fsi24)) THEN
!$acc update self(fsi24)
          END IF
          IF (PRESENT(fsi240)) THEN
!$acc update self(fsi240)
          END IF
          IF (PRESENT(laip)) THEN
!$acc update self(laip)
          END IF
#ifdef CN
          IF (PRESENT(dyntlai)) THEN
!$acc update self(dyntlai)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dyntsai)) THEN
!$acc update self(dyntsai)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dyntop)) THEN
!$acc update self(dyntop)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dynbot)) THEN
!$acc update self(dynbot)
          END IF
#endif
#ifdef CN
          IF (PRESENT(htmx)) THEN
!$acc update self(htmx)
          END IF
#endif
#ifdef CN
          IF (PRESENT(croplive)) THEN
!$acc update self(croplive)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd1020)) THEN
!$acc update self(gdd1020)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd820)) THEN
!$acc update self(gdd820)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd020)) THEN
!$acc update self(gdd020)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc)) THEN
!$acc update self(grainc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc_storage)) THEN
!$acc update self(grainc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc_xfer)) THEN
!$acc update self(grainc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn)) THEN
!$acc update self(grainn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn_storage)) THEN
!$acc update self(grainn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn_xfer)) THEN
!$acc update self(grainn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(days_active)) THEN
!$acc update self(days_active)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_flag)) THEN
!$acc update self(onset_flag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_counter)) THEN
!$acc update self(onset_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_gddflag)) THEN
!$acc update self(onset_gddflag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_fdd)) THEN
!$acc update self(onset_fdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_gdd)) THEN
!$acc update self(onset_gdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_swi)) THEN
!$acc update self(onset_swi)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_flag)) THEN
!$acc update self(offset_flag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_counter)) THEN
!$acc update self(offset_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_fdd)) THEN
!$acc update self(offset_fdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_swi)) THEN
!$acc update self(offset_swi)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dayl)) THEN
!$acc update self(dayl)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annavg_t2m)) THEN
!$acc update self(annavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempavg_t2m)) THEN
!$acc update self(tempavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempsum_potential_gpp)) THEN
!$acc update self(tempsum_potential_gpp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_potential_gpp)) THEN
!$acc update self(annsum_potential_gpp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempmax_retransn)) THEN
!$acc update self(tempmax_retransn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annmax_retransn)) THEN
!$acc update self(annmax_retransn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prev_leafc_to_litter)) THEN
!$acc update self(prev_leafc_to_litter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prev_frootc_to_litter)) THEN
!$acc update self(prev_frootc_to_litter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempsum_npp)) THEN
!$acc update self(tempsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_npp)) THEN
!$acc update self(annsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc)) THEN
!$acc update self(leafc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc_storage)) THEN
!$acc update self(leafc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc_xfer)) THEN
!$acc update self(leafc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc)) THEN
!$acc update self(frootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc_storage)) THEN
!$acc update self(frootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc_xfer)) THEN
!$acc update self(frootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc)) THEN
!$acc update self(livestemc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc_storage)) THEN
!$acc update self(livestemc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc_xfer)) THEN
!$acc update self(livestemc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc)) THEN
!$acc update self(deadstemc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc_storage)) THEN
!$acc update self(deadstemc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc_xfer)) THEN
!$acc update self(deadstemc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc)) THEN
!$acc update self(livecrootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc_storage)) THEN
!$acc update self(livecrootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc_xfer)) THEN
!$acc update self(livecrootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc)) THEN
!$acc update self(deadcrootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc_storage)) THEN
!$acc update self(deadcrootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc_xfer)) THEN
!$acc update self(deadcrootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cpool)) THEN
!$acc update self(cpool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(pft_ctrunc)) THEN
!$acc update self(pft_ctrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn)) THEN
!$acc update self(leafn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn_storage)) THEN
!$acc update self(leafn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn_xfer)) THEN
!$acc update self(leafn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn)) THEN
!$acc update self(frootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn_storage)) THEN
!$acc update self(frootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn_xfer)) THEN
!$acc update self(frootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn)) THEN
!$acc update self(livestemn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn_storage)) THEN
!$acc update self(livestemn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn_xfer)) THEN
!$acc update self(livestemn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn)) THEN
!$acc update self(deadstemn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn_storage)) THEN
!$acc update self(deadstemn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn_xfer)) THEN
!$acc update self(deadstemn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn)) THEN
!$acc update self(livecrootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn_storage)) THEN
!$acc update self(livecrootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn_xfer)) THEN
!$acc update self(livecrootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn)) THEN
!$acc update self(deadcrootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn_storage)) THEN
!$acc update self(deadcrootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn_xfer)) THEN
!$acc update self(deadcrootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(npool)) THEN
!$acc update self(npool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(pft_ntrunc)) THEN
!$acc update self(pft_ntrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gresp_storage)) THEN
!$acc update self(gresp_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gresp_xfer)) THEN
!$acc update self(gresp_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(xsmrpool)) THEN
!$acc update self(xsmrpool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_counter)) THEN
!$acc update self(annsum_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cannsum_npp)) THEN
!$acc update self(cannsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cannavg_t2m)) THEN
!$acc update self(cannavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(wf)) THEN
!$acc update self(wf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(me)) THEN
!$acc update self(me)
          END IF
#endif
#ifdef CN
          IF (PRESENT(mean_fire_prob)) THEN
!$acc update self(mean_fire_prob)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cwdc)) THEN
!$acc update self(cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr1c)) THEN
!$acc update self(litr1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr2c)) THEN
!$acc update self(litr2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr3c)) THEN
!$acc update self(litr3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil1c)) THEN
!$acc update self(soil1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil2c)) THEN
!$acc update self(soil2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil3c)) THEN
!$acc update self(soil3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil4c)) THEN
!$acc update self(soil4c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(seedc)) THEN
!$acc update self(seedc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(col_ctrunc)) THEN
!$acc update self(col_ctrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod10c)) THEN
!$acc update self(prod10c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100c)) THEN
!$acc update self(prod100c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cwdn)) THEN
!$acc update self(cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr1n)) THEN
!$acc update self(litr1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr2n)) THEN
!$acc update self(litr2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr3n)) THEN
!$acc update self(litr3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil1n)) THEN
!$acc update self(soil1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil2n)) THEN
!$acc update self(soil2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil3n)) THEN
!$acc update self(soil3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil4n)) THEN
!$acc update self(soil4n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(seedn)) THEN
!$acc update self(seedn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(col_ntrunc)) THEN
!$acc update self(col_ntrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod10n)) THEN
!$acc update self(prod10n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100n)) THEN
!$acc update self(prod100n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(sminn)) THEN
!$acc update self(sminn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(totlitc)) THEN
!$acc update self(totlitc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedc_to_leaf)) THEN
!$acc update self(dwt_seedc_to_leaf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedc_to_deadstem)) THEN
!$acc update self(dwt_seedc_to_deadstem)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_conv_cflux)) THEN
!$acc update self(dwt_conv_cflux)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod10c_gain)) THEN
!$acc update self(dwt_prod10c_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod100c_gain)) THEN
!$acc update self(dwt_prod100c_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100c_loss)) THEN
!$acc update self(prod100c_loss)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr1c)) THEN
!$acc update self(dwt_frootc_to_litr1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr2c)) THEN
!$acc update self(dwt_frootc_to_litr2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr3c)) THEN
!$acc update self(dwt_frootc_to_litr3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_livecrootc_to_cwdc)) THEN
!$acc update self(dwt_livecrootc_to_cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_deadcrootc_to_cwdc)) THEN
!$acc update self(dwt_deadcrootc_to_cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedn_to_leaf)) THEN
!$acc update self(dwt_seedn_to_leaf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedn_to_deadstem)) THEN
!$acc update self(dwt_seedn_to_deadstem)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_conv_nflux)) THEN
!$acc update self(dwt_conv_nflux)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod10n_gain)) THEN
!$acc update self(dwt_prod10n_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod100n_gain)) THEN
!$acc update self(dwt_prod100n_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100n_loss)) THEN
!$acc update self(prod100n_loss)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr1n)) THEN
!$acc update self(dwt_frootn_to_litr1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr2n)) THEN
!$acc update self(dwt_frootn_to_litr2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr3n)) THEN
!$acc update self(dwt_frootn_to_litr3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_livecrootn_to_cwdn)) THEN
!$acc update self(dwt_livecrootn_to_cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_deadcrootn_to_cwdn)) THEN
!$acc update self(dwt_deadcrootn_to_cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(retransn)) THEN
!$acc update self(retransn)
          END IF
#endif
          IF (PRESENT(pct_pft_input)) THEN
!$acc update self(pct_pft_input)
          END IF
          IF (PRESENT(shadowmask)) THEN
!$acc update self(shadowmask)
          END IF
          IF (PRESENT(swnorm)) THEN
!$acc update self(swnorm)
          END IF
          IF (PRESENT(slope)) THEN
!$acc update self(slope)
          END IF
          IF (PRESENT(slp_azi)) THEN
!$acc update self(slp_azi)
          END IF
          IF (PRESENT(diffuse_frac)) THEN
!$acc update self(diffuse_frac)
          END IF
          IF (PRESENT(coszen)) THEN
!$acc update self(coszen)
          END IF
          IF (PRESENT(hrang)) THEN
!$acc update self(hrang)
          END IF
          IF (PRESENT(xlat_urb2d)) THEN
!$acc update self(xlat_urb2d)
          END IF
          IF (PRESENT(dzr)) THEN
!$acc update self(dzr)
          END IF
          IF (PRESENT(dzb)) THEN
!$acc update self(dzb)
          END IF
          IF (PRESENT(dzg)) THEN
!$acc update self(dzg)
          END IF
          IF (PRESENT(tr_urb2d)) THEN
!$acc update self(tr_urb2d)
          END IF
          IF (PRESENT(tb_urb2d)) THEN
!$acc update self(tb_urb2d)
          END IF
          IF (PRESENT(tg_urb2d)) THEN
!$acc update self(tg_urb2d)
          END IF
          IF (PRESENT(tc_urb2d)) THEN
!$acc update self(tc_urb2d)
          END IF
          IF (PRESENT(qc_urb2d)) THEN
!$acc update self(qc_urb2d)
          END IF
          IF (PRESENT(uc_urb2d)) THEN
!$acc update self(uc_urb2d)
          END IF
          IF (PRESENT(xxxr_urb2d)) THEN
!$acc update self(xxxr_urb2d)
          END IF
          IF (PRESENT(xxxb_urb2d)) THEN
!$acc update self(xxxb_urb2d)
          END IF
          IF (PRESENT(xxxg_urb2d)) THEN
!$acc update self(xxxg_urb2d)
          END IF
          IF (PRESENT(xxxc_urb2d)) THEN
!$acc update self(xxxc_urb2d)
          END IF
          IF (PRESENT(cmcr_urb2d)) THEN
!$acc update self(cmcr_urb2d)
          END IF
          IF (PRESENT(tgr_urb2d)) THEN
!$acc update self(tgr_urb2d)
          END IF
          IF (PRESENT(tgrl_urb3d)) THEN
!$acc update self(tgrl_urb3d)
          END IF
          IF (PRESENT(smr_urb3d)) THEN
!$acc update self(smr_urb3d)
          END IF
          IF (PRESENT(drelr_urb2d)) THEN
!$acc update self(drelr_urb2d)
          END IF
          IF (PRESENT(drelb_urb2d)) THEN
!$acc update self(drelb_urb2d)
          END IF
          IF (PRESENT(drelg_urb2d)) THEN
!$acc update self(drelg_urb2d)
          END IF
          IF (PRESENT(flxhumr_urb2d)) THEN
!$acc update self(flxhumr_urb2d)
          END IF
          IF (PRESENT(flxhumb_urb2d)) THEN
!$acc update self(flxhumb_urb2d)
          END IF
          IF (PRESENT(flxhumg_urb2d)) THEN
!$acc update self(flxhumg_urb2d)
          END IF
          IF (PRESENT(trl_urb3d)) THEN
!$acc update self(trl_urb3d)
          END IF
          IF (PRESENT(tbl_urb3d)) THEN
!$acc update self(tbl_urb3d)
          END IF
          IF (PRESENT(tgl_urb3d)) THEN
!$acc update self(tgl_urb3d)
          END IF
          IF (PRESENT(sh_urb2d)) THEN
!$acc update self(sh_urb2d)
          END IF
          IF (PRESENT(lh_urb2d)) THEN
!$acc update self(lh_urb2d)
          END IF
          IF (PRESENT(g_urb2d)) THEN
!$acc update self(g_urb2d)
          END IF
          IF (PRESENT(rn_urb2d)) THEN
!$acc update self(rn_urb2d)
          END IF
          IF (PRESENT(ts_urb2d)) THEN
!$acc update self(ts_urb2d)
          END IF
          IF (PRESENT(frc_urb2d)) THEN
!$acc update self(frc_urb2d)
          END IF
          IF (PRESENT(utype_urb2d)) THEN
!$acc update self(utype_urb2d)
          END IF
          IF (PRESENT(cmr_sfcdif)) THEN
!$acc update self(cmr_sfcdif)
          END IF
          IF (PRESENT(chr_sfcdif)) THEN
!$acc update self(chr_sfcdif)
          END IF
          IF (PRESENT(cmc_sfcdif)) THEN
!$acc update self(cmc_sfcdif)
          END IF
          IF (PRESENT(chc_sfcdif)) THEN
!$acc update self(chc_sfcdif)
          END IF
          IF (PRESENT(cmgr_sfcdif)) THEN
!$acc update self(cmgr_sfcdif)
          END IF
          IF (PRESENT(chgr_sfcdif)) THEN
!$acc update self(chgr_sfcdif)
          END IF
          IF (PRESENT(alswvisdir)) THEN
!$acc update self(alswvisdir)
          END IF
          IF (PRESENT(alswvisdif)) THEN
!$acc update self(alswvisdif)
          END IF
          IF (PRESENT(alswnirdir)) THEN
!$acc update self(alswnirdir)
          END IF
          IF (PRESENT(alswnirdif)) THEN
!$acc update self(alswnirdif)
          END IF
          IF (PRESENT(swvisdir)) THEN
!$acc update self(swvisdir)
          END IF
          IF (PRESENT(swvisdif)) THEN
!$acc update self(swvisdif)
          END IF
          IF (PRESENT(swnirdir)) THEN
!$acc update self(swnirdir)
          END IF
          IF (PRESENT(swnirdif)) THEN
!$acc update self(swnirdif)
          END IF
          IF (PRESENT(ssib_br)) THEN
!$acc update self(ssib_br)
          END IF
          IF (PRESENT(ssib_fm)) THEN
!$acc update self(ssib_fm)
          END IF
          IF (PRESENT(ssib_fh)) THEN
!$acc update self(ssib_fh)
          END IF
          IF (PRESENT(ssib_cm)) THEN
!$acc update self(ssib_cm)
          END IF
          IF (PRESENT(ssibxdd)) THEN
!$acc update self(ssibxdd)
          END IF
          IF (PRESENT(ssib_lhf)) THEN
!$acc update self(ssib_lhf)
          END IF
          IF (PRESENT(ssib_shf)) THEN
!$acc update self(ssib_shf)
          END IF
          IF (PRESENT(ssib_ghf)) THEN
!$acc update self(ssib_ghf)
          END IF
          IF (PRESENT(ssib_egs)) THEN
!$acc update self(ssib_egs)
          END IF
          IF (PRESENT(ssib_eci)) THEN
!$acc update self(ssib_eci)
          END IF
          IF (PRESENT(ssib_ect)) THEN
!$acc update self(ssib_ect)
          END IF
          IF (PRESENT(ssib_egi)) THEN
!$acc update self(ssib_egi)
          END IF
          IF (PRESENT(ssib_egt)) THEN
!$acc update self(ssib_egt)
          END IF
          IF (PRESENT(ssib_sdn)) THEN
!$acc update self(ssib_sdn)
          END IF
          IF (PRESENT(ssib_sup)) THEN
!$acc update self(ssib_sup)
          END IF
          IF (PRESENT(ssib_ldn)) THEN
!$acc update self(ssib_ldn)
          END IF
          IF (PRESENT(ssib_lup)) THEN
!$acc update self(ssib_lup)
          END IF
          IF (PRESENT(ssib_wat)) THEN
!$acc update self(ssib_wat)
          END IF
          IF (PRESENT(ssib_shc)) THEN
!$acc update self(ssib_shc)
          END IF
          IF (PRESENT(ssib_shg)) THEN
!$acc update self(ssib_shg)
          END IF
          IF (PRESENT(ssib_lai)) THEN
!$acc update self(ssib_lai)
          END IF
          IF (PRESENT(ssib_vcf)) THEN
!$acc update self(ssib_vcf)
          END IF
          IF (PRESENT(ssib_z00)) THEN
!$acc update self(ssib_z00)
          END IF
          IF (PRESENT(ssib_veg)) THEN
!$acc update self(ssib_veg)
          END IF
          IF (PRESENT(isnow)) THEN
!$acc update self(isnow)
          END IF
          IF (PRESENT(swe)) THEN
!$acc update self(swe)
          END IF
          IF (PRESENT(snowden)) THEN
!$acc update self(snowden)
          END IF
          IF (PRESENT(snowdepth)) THEN
!$acc update self(snowdepth)
          END IF
          IF (PRESENT(tkair)) THEN
!$acc update self(tkair)
          END IF
          IF (PRESENT(dzo1)) THEN
!$acc update self(dzo1)
          END IF
          IF (PRESENT(wo1)) THEN
!$acc update self(wo1)
          END IF
          IF (PRESENT(tssn1)) THEN
!$acc update self(tssn1)
          END IF
          IF (PRESENT(tssno1)) THEN
!$acc update self(tssno1)
          END IF
          IF (PRESENT(bwo1)) THEN
!$acc update self(bwo1)
          END IF
          IF (PRESENT(bto1)) THEN
!$acc update self(bto1)
          END IF
          IF (PRESENT(cto1)) THEN
!$acc update self(cto1)
          END IF
          IF (PRESENT(fio1)) THEN
!$acc update self(fio1)
          END IF
          IF (PRESENT(flo1)) THEN
!$acc update self(flo1)
          END IF
          IF (PRESENT(bio1)) THEN
!$acc update self(bio1)
          END IF
          IF (PRESENT(blo1)) THEN
!$acc update self(blo1)
          END IF
          IF (PRESENT(ho1)) THEN
!$acc update self(ho1)
          END IF
          IF (PRESENT(dzo2)) THEN
!$acc update self(dzo2)
          END IF
          IF (PRESENT(wo2)) THEN
!$acc update self(wo2)
          END IF
          IF (PRESENT(tssn2)) THEN
!$acc update self(tssn2)
          END IF
          IF (PRESENT(tssno2)) THEN
!$acc update self(tssno2)
          END IF
          IF (PRESENT(bwo2)) THEN
!$acc update self(bwo2)
          END IF
          IF (PRESENT(bto2)) THEN
!$acc update self(bto2)
          END IF
          IF (PRESENT(cto2)) THEN
!$acc update self(cto2)
          END IF
          IF (PRESENT(fio2)) THEN
!$acc update self(fio2)
          END IF
          IF (PRESENT(flo2)) THEN
!$acc update self(flo2)
          END IF
          IF (PRESENT(bio2)) THEN
!$acc update self(bio2)
          END IF
          IF (PRESENT(blo2)) THEN
!$acc update self(blo2)
          END IF
          IF (PRESENT(ho2)) THEN
!$acc update self(ho2)
          END IF
          IF (PRESENT(dzo3)) THEN
!$acc update self(dzo3)
          END IF
          IF (PRESENT(wo3)) THEN
!$acc update self(wo3)
          END IF
          IF (PRESENT(tssn3)) THEN
!$acc update self(tssn3)
          END IF
          IF (PRESENT(tssno3)) THEN
!$acc update self(tssno3)
          END IF
          IF (PRESENT(bwo3)) THEN
!$acc update self(bwo3)
          END IF
          IF (PRESENT(bto3)) THEN
!$acc update self(bto3)
          END IF
          IF (PRESENT(cto3)) THEN
!$acc update self(cto3)
          END IF
          IF (PRESENT(fio3)) THEN
!$acc update self(fio3)
          END IF
          IF (PRESENT(flo3)) THEN
!$acc update self(flo3)
          END IF
          IF (PRESENT(bio3)) THEN
!$acc update self(bio3)
          END IF
          IF (PRESENT(blo3)) THEN
!$acc update self(blo3)
          END IF
          IF (PRESENT(ho3)) THEN
!$acc update self(ho3)
          END IF
          IF (PRESENT(dzo4)) THEN
!$acc update self(dzo4)
          END IF
          IF (PRESENT(wo4)) THEN
!$acc update self(wo4)
          END IF
          IF (PRESENT(tssn4)) THEN
!$acc update self(tssn4)
          END IF
          IF (PRESENT(tssno4)) THEN
!$acc update self(tssno4)
          END IF
          IF (PRESENT(bwo4)) THEN
!$acc update self(bwo4)
          END IF
          IF (PRESENT(bto4)) THEN
!$acc update self(bto4)
          END IF
          IF (PRESENT(cto4)) THEN
!$acc update self(cto4)
          END IF
          IF (PRESENT(fio4)) THEN
!$acc update self(fio4)
          END IF
          IF (PRESENT(flo4)) THEN
!$acc update self(flo4)
          END IF
          IF (PRESENT(bio4)) THEN
!$acc update self(bio4)
          END IF
          IF (PRESENT(blo4)) THEN
!$acc update self(blo4)
          END IF
          IF (PRESENT(ho4)) THEN
!$acc update self(ho4)
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
          IF (PRESENT(capg)) THEN
!$acc update self(capg)
          END IF
          IF (PRESENT(hol)) THEN
!$acc update self(hol)
          END IF
          IF (PRESENT(mol)) THEN
!$acc update self(mol)
          END IF
          IF (PRESENT(rainncv)) THEN
!$acc update self(rainncv)
          END IF
          IF (PRESENT(rainshv)) THEN
!$acc update self(rainshv)
          END IF
          IF (PRESENT(rainbl)) THEN
!$acc update self(rainbl)
          END IF
          IF (PRESENT(regime)) THEN
!$acc update self(regime)
          END IF
          IF (PRESENT(thc)) THEN
!$acc update self(thc)
          END IF
          IF (PRESENT(graupelncv)) THEN
!$acc update self(graupelncv)
          END IF
          IF (PRESENT(hailncv)) THEN
!$acc update self(hailncv)
          END IF
          IF (PRESENT(qsg)) THEN
!$acc update self(qsg)
          END IF
          IF (PRESENT(qvg)) THEN
!$acc update self(qvg)
          END IF
          IF (PRESENT(qcg)) THEN
!$acc update self(qcg)
          END IF
          IF (PRESENT(soilt1)) THEN
!$acc update self(soilt1)
          END IF
          IF (PRESENT(tsnav)) THEN
!$acc update self(tsnav)
          END IF
          IF (PRESENT(smfr3d)) THEN
!$acc update self(smfr3d)
          END IF
          IF (PRESENT(keepfr3dflag)) THEN
!$acc update self(keepfr3dflag)
          END IF
          IF (PRESENT(dew)) THEN
!$acc update self(dew)
          END IF
          IF (PRESENT(rhosnf)) THEN
!$acc update self(rhosnf)
          END IF
          IF (PRESENT(precipfr)) THEN
!$acc update self(precipfr)
          END IF
          IF (PRESENT(potevp)) THEN
!$acc update self(potevp)
          END IF
          IF (PRESENT(snopcx)) THEN
!$acc update self(snopcx)
          END IF
          IF (PRESENT(soiltb)) THEN
!$acc update self(soiltb)
          END IF
          IF (PRESENT(sr)) THEN
!$acc update self(sr)
          END IF
          IF (PRESENT(t2_ndg_old)) THEN
!$acc update self(t2_ndg_old)
          END IF
          IF (PRESENT(q2_ndg_old)) THEN
!$acc update self(q2_ndg_old)
          END IF
          IF (PRESENT(t2_ndg_new)) THEN
!$acc update self(t2_ndg_new)
          END IF
          IF (PRESENT(q2_ndg_new)) THEN
!$acc update self(q2_ndg_new)
          END IF
          IF (PRESENT(sn_ndg_old)) THEN
!$acc update self(sn_ndg_old)
          END IF
          IF (PRESENT(sn_ndg_new)) THEN
!$acc update self(sn_ndg_new)
          END IF
          IF (PRESENT(t2obs)) THEN
!$acc update self(t2obs)
          END IF
          IF (PRESENT(q2obs)) THEN
!$acc update self(q2obs)
          END IF
          IF (PRESENT(hd_temf)) THEN
!$acc update self(hd_temf)
          END IF
          IF (PRESENT(te_temf)) THEN
!$acc update self(te_temf)
          END IF
          IF (PRESENT(fcor)) THEN
!$acc update self(fcor)
          END IF
          IF (PRESENT(exch_temf)) THEN
!$acc update self(exch_temf)
          END IF
          IF (PRESENT(wm_temf)) THEN
!$acc update self(wm_temf)
          END IF
          IF (PRESENT(uratx)) THEN
!$acc update self(uratx)
          END IF
          IF (PRESENT(vratx)) THEN
!$acc update self(vratx)
          END IF
          IF (PRESENT(tratx)) THEN
!$acc update self(tratx)
          END IF
          IF (PRESENT(tml)) THEN
!$acc update self(tml)
          END IF
          IF (PRESENT(t0ml)) THEN
!$acc update self(t0ml)
          END IF
          IF (PRESENT(hml)) THEN
!$acc update self(hml)
          END IF
          IF (PRESENT(h0ml)) THEN
!$acc update self(h0ml)
          END IF
          IF (PRESENT(huml)) THEN
!$acc update self(huml)
          END IF
          IF (PRESENT(hvml)) THEN
!$acc update self(hvml)
          END IF
          IF (PRESENT(f)) THEN
!$acc update self(f)
          END IF
          IF (PRESENT(tmoml)) THEN
!$acc update self(tmoml)
          END IF
          IF (PRESENT(ustm)) THEN
!$acc update self(ustm)
          END IF
          IF (PRESENT(ck)) THEN
!$acc update self(ck)
          END IF
          IF (PRESENT(cka)) THEN
!$acc update self(cka)
          END IF
          IF (PRESENT(cd)) THEN
!$acc update self(cd)
          END IF
          IF (PRESENT(cda)) THEN
!$acc update self(cda)
          END IF
          IF (PRESENT(snotime)) THEN
!$acc update self(snotime)
          END IF
          IF (PRESENT(noahres)) THEN
!$acc update self(noahres)
          END IF
          IF (PRESENT(xlat)) THEN
!$acc update self(xlat)
          END IF
          IF (PRESENT(xlong)) THEN
!$acc update self(xlong)
          END IF
          IF (PRESENT(ahe)) THEN
!$acc update self(ahe)
          END IF
          IF (PRESENT(tsk_rural)) THEN
!$acc update self(tsk_rural)
          END IF
          IF (PRESENT(trb_urb4d)) THEN
!$acc update self(trb_urb4d)
          END IF
          IF (PRESENT(tw1_urb4d)) THEN
!$acc update self(tw1_urb4d)
          END IF
          IF (PRESENT(tw2_urb4d)) THEN
!$acc update self(tw2_urb4d)
          END IF
          IF (PRESENT(tgb_urb4d)) THEN
!$acc update self(tgb_urb4d)
          END IF
          IF (PRESENT(tlev_urb3d)) THEN
!$acc update self(tlev_urb3d)
          END IF
          IF (PRESENT(qlev_urb3d)) THEN
!$acc update self(qlev_urb3d)
          END IF
          IF (PRESENT(tw1lev_urb3d)) THEN
!$acc update self(tw1lev_urb3d)
          END IF
          IF (PRESENT(tw2lev_urb3d)) THEN
!$acc update self(tw2lev_urb3d)
          END IF
          IF (PRESENT(tglev_urb3d)) THEN
!$acc update self(tglev_urb3d)
          END IF
          IF (PRESENT(tflev_urb3d)) THEN
!$acc update self(tflev_urb3d)
          END IF
          IF (PRESENT(sf_ac_urb3d)) THEN
!$acc update self(sf_ac_urb3d)
          END IF
          IF (PRESENT(lf_ac_urb3d)) THEN
!$acc update self(lf_ac_urb3d)
          END IF
          IF (PRESENT(cm_ac_urb3d)) THEN
!$acc update self(cm_ac_urb3d)
          END IF
          IF (PRESENT(sfvent_urb3d)) THEN
!$acc update self(sfvent_urb3d)
          END IF
          IF (PRESENT(lfvent_urb3d)) THEN
!$acc update self(lfvent_urb3d)
          END IF
          IF (PRESENT(sfwin1_urb3d)) THEN
!$acc update self(sfwin1_urb3d)
          END IF
          IF (PRESENT(sfwin2_urb3d)) THEN
!$acc update self(sfwin2_urb3d)
          END IF
          IF (PRESENT(sfw1_urb3d)) THEN
!$acc update self(sfw1_urb3d)
          END IF
          IF (PRESENT(sfw2_urb3d)) THEN
!$acc update self(sfw2_urb3d)
          END IF
          IF (PRESENT(sfr_urb3d)) THEN
!$acc update self(sfr_urb3d)
          END IF
          IF (PRESENT(sfg_urb3d)) THEN
!$acc update self(sfg_urb3d)
          END IF
          IF (PRESENT(ep_pv_urb3d)) THEN
!$acc update self(ep_pv_urb3d)
          END IF
          IF (PRESENT(t_pv_urb3d)) THEN
!$acc update self(t_pv_urb3d)
          END IF
          IF (PRESENT(trv_urb4d)) THEN
!$acc update self(trv_urb4d)
          END IF
          IF (PRESENT(qr_urb4d)) THEN
!$acc update self(qr_urb4d)
          END IF
          IF (PRESENT(qgr_urb3d)) THEN
!$acc update self(qgr_urb3d)
          END IF
          IF (PRESENT(tgr_urb3d)) THEN
!$acc update self(tgr_urb3d)
          END IF
          IF (PRESENT(drain_urb4d)) THEN
!$acc update self(drain_urb4d)
          END IF
          IF (PRESENT(draingr_urb3d)) THEN
!$acc update self(draingr_urb3d)
          END IF
          IF (PRESENT(sfrv_urb3d)) THEN
!$acc update self(sfrv_urb3d)
          END IF
          IF (PRESENT(lfrv_urb3d)) THEN
!$acc update self(lfrv_urb3d)
          END IF
          IF (PRESENT(dgr_urb3d)) THEN
!$acc update self(dgr_urb3d)
          END IF
          IF (PRESENT(dg_urb3d)) THEN
!$acc update self(dg_urb3d)
          END IF
          IF (PRESENT(lfr_urb3d)) THEN
!$acc update self(lfr_urb3d)
          END IF
          IF (PRESENT(lfg_urb3d)) THEN
!$acc update self(lfg_urb3d)
          END IF
          IF (PRESENT(swddir)) THEN
!$acc update self(swddir)
          END IF
          IF (PRESENT(swddif)) THEN
!$acc update self(swddif)
          END IF
          IF (PRESENT(lp_urb2d)) THEN
!$acc update self(lp_urb2d)
          END IF
          IF (PRESENT(hi_urb2d)) THEN
!$acc update self(hi_urb2d)
          END IF
          IF (PRESENT(lb_urb2d)) THEN
!$acc update self(lb_urb2d)
          END IF
          IF (PRESENT(hgt_urb2d)) THEN
!$acc update self(hgt_urb2d)
          END IF
          IF (PRESENT(mh_urb2d)) THEN
!$acc update self(mh_urb2d)
          END IF
          IF (PRESENT(stdh_urb2d)) THEN
!$acc update self(stdh_urb2d)
          END IF
          IF (PRESENT(lf_urb2d)) THEN
!$acc update self(lf_urb2d)
          END IF
          IF (PRESENT(lf_urb2d_s)) THEN
!$acc update self(lf_urb2d_s)
          END IF
          IF (PRESENT(z0_urb2d)) THEN
!$acc update self(z0_urb2d)
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
          IF (PRESENT(tsk_save)) THEN
!$acc update self(tsk_save)
          END IF
          IF (PRESENT(cldfra)) THEN
!$acc update self(cldfra)
          END IF
          IF (PRESENT(mosaic_cat_index)) THEN
!$acc update self(mosaic_cat_index)
          END IF
          IF (PRESENT(landusef2)) THEN
!$acc update self(landusef2)
          END IF
          IF (PRESENT(tsk_mosaic)) THEN
!$acc update self(tsk_mosaic)
          END IF
          IF (PRESENT(qsfc_mosaic)) THEN
!$acc update self(qsfc_mosaic)
          END IF
          IF (PRESENT(tslb_mosaic)) THEN
!$acc update self(tslb_mosaic)
          END IF
          IF (PRESENT(smois_mosaic)) THEN
!$acc update self(smois_mosaic)
          END IF
          IF (PRESENT(sh2o_mosaic)) THEN
!$acc update self(sh2o_mosaic)
          END IF
          IF (PRESENT(canwat_mosaic)) THEN
!$acc update self(canwat_mosaic)
          END IF
          IF (PRESENT(snow_mosaic)) THEN
!$acc update self(snow_mosaic)
          END IF
          IF (PRESENT(snowh_mosaic)) THEN
!$acc update self(snowh_mosaic)
          END IF
          IF (PRESENT(snowc_mosaic)) THEN
!$acc update self(snowc_mosaic)
          END IF
          IF (PRESENT(albedo_mosaic)) THEN
!$acc update self(albedo_mosaic)
          END IF
          IF (PRESENT(albbck_mosaic)) THEN
!$acc update self(albbck_mosaic)
          END IF
          IF (PRESENT(emiss_mosaic)) THEN
!$acc update self(emiss_mosaic)
          END IF
          IF (PRESENT(embck_mosaic)) THEN
!$acc update self(embck_mosaic)
          END IF
          IF (PRESENT(znt_mosaic)) THEN
!$acc update self(znt_mosaic)
          END IF
          IF (PRESENT(z0_mosaic)) THEN
!$acc update self(z0_mosaic)
          END IF
          IF (PRESENT(hfx_mosaic)) THEN
!$acc update self(hfx_mosaic)
          END IF
          IF (PRESENT(qfx_mosaic)) THEN
!$acc update self(qfx_mosaic)
          END IF
          IF (PRESENT(lh_mosaic)) THEN
!$acc update self(lh_mosaic)
          END IF
          IF (PRESENT(grdflx_mosaic)) THEN
!$acc update self(grdflx_mosaic)
          END IF
          IF (PRESENT(snotime_mosaic)) THEN
!$acc update self(snotime_mosaic)
          END IF
          IF (PRESENT(rs_mosaic)) THEN
!$acc update self(rs_mosaic)
          END IF
          IF (PRESENT(lai_mosaic)) THEN
!$acc update self(lai_mosaic)
          END IF
          IF (PRESENT(tr_urb2d_mosaic)) THEN
!$acc update self(tr_urb2d_mosaic)
          END IF
          IF (PRESENT(tb_urb2d_mosaic)) THEN
!$acc update self(tb_urb2d_mosaic)
          END IF
          IF (PRESENT(tg_urb2d_mosaic)) THEN
!$acc update self(tg_urb2d_mosaic)
          END IF
          IF (PRESENT(tc_urb2d_mosaic)) THEN
!$acc update self(tc_urb2d_mosaic)
          END IF
          IF (PRESENT(qc_urb2d_mosaic)) THEN
!$acc update self(qc_urb2d_mosaic)
          END IF
          IF (PRESENT(uc_urb2d_mosaic)) THEN
!$acc update self(uc_urb2d_mosaic)
          END IF
          IF (PRESENT(trl_urb3d_mosaic)) THEN
!$acc update self(trl_urb3d_mosaic)
          END IF
          IF (PRESENT(tbl_urb3d_mosaic)) THEN
!$acc update self(tbl_urb3d_mosaic)
          END IF
          IF (PRESENT(tgl_urb3d_mosaic)) THEN
!$acc update self(tgl_urb3d_mosaic)
          END IF
          IF (PRESENT(sh_urb2d_mosaic)) THEN
!$acc update self(sh_urb2d_mosaic)
          END IF
          IF (PRESENT(lh_urb2d_mosaic)) THEN
!$acc update self(lh_urb2d_mosaic)
          END IF
          IF (PRESENT(g_urb2d_mosaic)) THEN
!$acc update self(g_urb2d_mosaic)
          END IF
          IF (PRESENT(rn_urb2d_mosaic)) THEN
!$acc update self(rn_urb2d_mosaic)
          END IF
          IF (PRESENT(ts_urb2d_mosaic)) THEN
!$acc update self(ts_urb2d_mosaic)
          END IF
          IF (PRESENT(ts_rul2d_mosaic)) THEN
!$acc update self(ts_rul2d_mosaic)
          END IF
          IF (PRESENT(sda_hfx)) THEN
!$acc update self(sda_hfx)
          END IF
          IF (PRESENT(sda_qfx)) THEN
!$acc update self(sda_qfx)
          END IF
          IF (PRESENT(hfx_both)) THEN
!$acc update self(hfx_both)
          END IF
          IF (PRESENT(qfx_both)) THEN
!$acc update self(qfx_both)
          END IF
          IF (PRESENT(qnorm)) THEN
!$acc update self(qnorm)
          END IF
          IF (PRESENT(pattern_spp_lsm)) THEN
!$acc update self(pattern_spp_lsm)
          END IF
          IF (PRESENT(field_sf)) THEN
!$acc update self(field_sf)
          END IF
          IF (PRESENT(pattern_spp_pbl)) THEN
!$acc update self(pattern_spp_pbl)
          END IF
          IF (PRESENT(xlaidyn)) THEN
!$acc update self(xlaidyn)
          END IF
          IF (PRESENT(perts_qvapor)) THEN
!$acc update self(perts_qvapor)
          END IF
          IF (PRESENT(perts_th)) THEN
!$acc update self(perts_th)
          END IF
          IF (PRESENT(perts_smois)) THEN
!$acc update self(perts_smois)
          END IF
          IF (PRESENT(perts_tsoil)) THEN
!$acc update self(perts_tsoil)
          END IF
          IF (PRESENT(irrigation)) THEN
!$acc update self(irrigation)
          END IF
          IF (PRESENT(irr_rand_field)) THEN
!$acc update self(irr_rand_field)
          END IF
        END IF
        gpu_world_host = .NOT. gpu_world_host
      END IF
#endif

  if ( fractional_seaice == 0 ) then
     xice_threshold = 0.5
  else if ( fractional_seaice == 1 ) then
     xice_threshold = 0.02
  endif

  if ( ( seaice_albedo_opt == 2 ) .and. ( ifndalbsi == 0 ) ) then
      call wrf_error_fatal("Field ALBSI not found in input.  Field ALBSI is required if SEAICE_ALBEDO_OPT=2")
  endif

  if ( ( seaice_thickness_opt == 1 ) .and. ( ifndicedepth == 0 ) ) then
      call wrf_error_fatal("Field ICEDEPTH not found in input.  Field ICEDEPTH is required if SEAICE_THICKNESS_OPT=1")
  endif

  if ( ( seaice_snowdepth_opt == 1 ) .and. ( ifndsnowsi == 0 ) ) then
      call wrf_error_fatal("Field SNOWSI not found in input.  Field SNOWSI is required if SEAICE_SNOWDEPTH_OPT=1")
  endif

  IF ( coupler_on .and. present(cplmask) .and. present(sst_input) ) THEN
#ifdef WRF_GPU
    CALL wrf_error_fatal('surface_driver: coupler_on not ported to the GPU')
#endif
     
     CALL cpl_rcv( id, 'SST',            &
        &              ids, ide, jds, jde, kds, kde, &
        &              ims, ime, jms, jme, kms, kme, &
        &              ips, ipe, jps, jpe, kps, kpe, &
        &              max_edom, cplmask, SST, SST_INPUT )
     
     CALL cpl_rcv( id, 'UOCE',            &
        &              ids, ide, jds, jde, kds, kde, &
        &              ims, ime, jms, jme, kms, kme, &
        &              ips, ipe, jps, jpe, kps, kpe, &
        &              max_edom, cplmask, UOCE )
     
     CALL cpl_rcv( id, 'VOCE',            &
        &              ids, ide, jds, jde, kds, kde, &
        &              ims, ime, jms, jme, kms, kme, &
        &              ips, ipe, jps, jpe, kps, kpe, &
        &              max_edom, cplmask, VOCE )
     
  END IF

#if (EM_CORE==1)
     spp_lsm_loc = spp_lsm
#else
     spp_lsm_loc = 0
#endif

  
#ifdef WRF_GPU
  DO ij = 1, num_tiles
     its = i_start_h(ij)
     ite = i_end_h(ij)
     jts = j_start_h(ij)
     jte = j_end_h(ij)
! K-SD-1: zero u_phytmp v_phytmp QGH CHS CPM CHS2 (Template A)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_SURFACE_DRIVER)) default(none) &
!$acc& present(v_phytmp, u_phytmp, qgh, chs, cpm, chs2) &
!$acc& firstprivate(its, ite, jts, jte, kms, kme) &
!$acc& private(i, j, k)
     DO j = jts, jte
     DO i = its, ite
        !$acc loop seq
        DO k = kms, kme
          v_phytmp(i, k, j) = 0.
          u_phytmp(i, k, j) = 0.
        ENDDO
         QGH(i,j) = 0.
         CHS(i,j) = 0.
         CPM(i,j) = 0.
         CHS2(i,j) = 0.
     ENDDO
     ENDDO
  ENDDO
#else
!$OMP PARALLEL DO &
!$OMP PRIVATE (ij, i, j, k)
  DO ij = 1,num_tiles
    DO j = j_start(ij),j_end(ij)
      DO k = kms,kme
        DO i = i_start(ij),i_end(ij)
          v_phytmp(i, k, j) = 0.
          u_phytmp(i, k, j) = 0.
        ENDDO
      ENDDO
      DO i = i_start(ij),i_end(ij)
         QGH(i,j) = 0.
         CHS(i,j) = 0.
         CPM(i,j) = 0.
         CHS2(i,j) = 0.
      ENDDO
    ENDDO
  ENDDO
#endif
  DTMIN = 0.
  DTBL = 0.

! RAINBL in mm (Accumulation between PBL calls)

  IF ( PRESENT( rainncv ) .AND. PRESENT( rainbl ) ) THEN
#ifdef WRF_GPU
  DO ij = 1, num_tiles
     its = i_start_h(ij)
     ite = i_end_h(ij)
     jts = j_start_h(ij)
     jte = j_end_h(ij)
    IF (.NOT. PRESENT(rainshv)) THEN
       CALL wrf_error_fatal('surface_driver: rainshv not present')
    END IF
! K-SD-2: RAINBL accumulation (Template A)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_SURFACE_DRIVER)) default(none) &
!$acc& present(rainbl, raincv, rainncv, rainshv, irrigation_channel) &
!$acc& firstprivate(its, ite, jts, jte) &
!$acc& private(i, j)
      DO j = jts, jte
      DO i = its, ite
         RAINBL(i,j) = RAINBL(i,j) + RAINCV(i,j) + RAINNCV(i,j)
         RAINBL(i,j) = RAINBL(i,j) + RAINSHV(i,j)
         RAINBL(i,j) = MAX (RAINBL(i,j), 0.0)
#if (EM_CORE==1)
         IRRIGATION_CHANNEL(i,j) = 0.
#endif
      ENDDO
      ENDDO
  ENDDO
#else
    !$OMP PARALLEL DO   &
    !$OMP PRIVATE ( ij, i, j, k )
    DO ij = 1 , num_tiles
      DO j=j_start(ij),j_end(ij)
      DO i=i_start(ij),i_end(ij)
         RAINBL(i,j) = RAINBL(i,j) + RAINCV(i,j) + RAINNCV(i,j)
         IF ( PRESENT( rainshv ))RAINBL(i,j) = RAINBL(i,j) + RAINSHV(i,j)
         RAINBL(i,j) = MAX (RAINBL(i,j), 0.0)
#if (EM_CORE==1)
         IRRIGATION_CHANNEL(i,j) = 0.
         sf_surf_irr: SELECT CASE(sf_surf_irr_scheme)
            CASE(DRIP)
               CALL drip_irrigation(                                     &
                &  julian_in,IRRIGATION(i,j),sf_surf_irr_scheme,         &
                &  irr_daily_amount,irr_start_hour,irr_num_hours,        &
                &  irr_start_julianday,irr_end_julianday,                &
                &  irr_freq,irr_ph,i,j,RAINBL(i,j),                      &
                &  IRRIGATION_CHANNEL(i,j),gmt,xtime,dt,                 &
                &  irr_rand_field(i,j)                                   &
                   )
            CASE(CHANNEL)
               CALL channel_irrigation(                                  &
                &  julian_in,IRRIGATION(i,j),sf_surf_irr_scheme,         &
                &  irr_daily_amount,irr_start_hour,irr_num_hours,        &
                &  irr_start_julianday,irr_end_julianday,                &
                &  irr_freq,irr_ph,i,j,RAINBL(i,j),                      &
                &  IRRIGATION_CHANNEL(i,j),gmt,xtime,dt,                 &
                &  irr_rand_field(i,j)                                   &
                   )
           END SELECT sf_surf_irr
#endif
      ENDDO
      ENDDO
    ENDDO
    !$OMP END PARALLEL DO
#endif
  ELSE IF ( PRESENT( rainbl ) ) THEN
#ifdef WRF_GPU
    CALL wrf_error_fatal('surface_driver: rainbl without rainncv not ported to the GPU')
#endif
    !$OMP PARALLEL DO   &
    !$OMP PRIVATE ( ij, i, j, k )
    DO ij = 1 , num_tiles
      DO j=j_start(ij),j_end(ij)
      DO i=i_start(ij),i_end(ij)
         RAINBL(i,j) = RAINBL(i,j) + RAINCV(i,j)
         IF ( PRESENT( rainshv ))RAINBL(i,j) = RAINBL(i,j) + RAINSHV(i,j)
         RAINBL(i,j) = MAX (RAINBL(i,j), 0.0)

#if (EM_CORE==1)
          sf_surf_irr1: SELECT CASE(sf_surf_irr_scheme)
             CASE(DRIP)
               CALL drip_irrigation(                                     &
                &  julian_in,IRRIGATION(i,j),sf_surf_irr_scheme,         &
                &  irr_daily_amount,irr_start_hour,irr_num_hours,        &
                &  irr_start_julianday,irr_end_julianday,                &
                &  irr_freq,irr_ph,i,j,RAINBL(i,j),                      &
                &  IRRIGATION_CHANNEL(i,j),gmt,xtime,dt,                 &
                &  irr_rand_field(i,j)                                   &
                   )

            CASE(CHANNEL)
               CALL channel_irrigation(                                  &
                &  julian_in,IRRIGATION(i,j),sf_surf_irr_scheme,         &
                &  irr_daily_amount,irr_start_hour,irr_num_hours,        &
                &  irr_start_julianday,irr_end_julianday,                &
                &  irr_freq,irr_ph,i,j,RAINBL(i,j),                      &
                &  IRRIGATION_CHANNEL(i,j),gmt,xtime,dt,                 &
                &  irr_rand_field(i,j)                                   &
                   )
        END SELECT sf_surf_irr1
#endif

      ENDDO
      ENDDO
    ENDDO
    !$OMP END PARALLEL DO
  ENDIF
! Update SST
  IF (sst_update .EQ. 1) THEN
#ifdef WRF_GPU
    CALL wrf_error_fatal('surface_driver: sst_update not ported to the GPU')
#endif
    CALL wrf_debug( 100, 'SST_UPDATE is on' )
    !$OMP PARALLEL DO   &
    !$OMP PRIVATE ( ij, i, j, k )
    DO ij = 1 , num_tiles
      DO j=j_start(ij),j_end(ij)
      DO i=i_start(ij),i_end(ij)
 ! check for lake model 
#if (EM_CORE==1)
          if ( lakemodel==1) then
            if(lakemask(i,j).eq.1.) then
              if ( xice(i,j).gt.xice_threshold) then   !mchen
                   xice(i,j)=0.0
               endif
             endif
          endif 
#else
          if ( lakemodel==1) then
            if(ht(i,j)>=lake_min_elev) then
              if ( xice(i,j).gt.xice_threshold) then   !mchen
                   xice(i,j)=0.0
               endif
             endif
          endif 
#endif
! end check lake model    
         XICE_save(I,J) = XICEM(I,J) 

         IF ( FRACTIONAL_SEAICE == 1 ) then
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            IF ( ( XICE(I,J) .NE. XICEM(I,J) ) .AND. ( XICEM(I,J) .GT. XICE_THRESHOLD ) ) THEN
               ! Fractional values of ALBEDO and EMISSIVITY are valid according to the 
               ! earlier fractional seaice value, XICEM.  Recompute them for the new 
               ! seaice value XICE.
                IF ( SEAICE_ALBEDO_OPT ==2 ) THEN
                    IF ( ALBSI(I,J) < -1.E6 ) THEN
                        call wrf_error_fatal("Field ALBSI not found in input.  Field ALBSI is required if SEAICE_ALBEDO_OPT=2")
                    ENDIF
                    ALBEDO(I,J) = 0.08 + XICE(I,J)/XICEM(I,J) * ( ALBSI(I,J) - 0.08 )
                ELSE
                    ALBEDO(I,J) = 0.08 + XICE(I,J)/XICEM(I,J) * ( ALBEDO(I,J) - 0.08 )
                ENDIF
                EMISS (I,J) = 0.98 + XICE(I,J)/XICEM(I,J) * ( EMISS (I,J) - 0.98 )
! use old tsk from seaice part
                TSK(I,J) = TSK_SAVE(I,J)*XICE(I,J) + (1.-XICE(I,J))*SST(I,J)
            ENDIF
         ENDIF

        IF ( XLAND(i,j) .GT. 1.5 .AND. XICE(I,J) .GE. XICE_THRESHOLD .AND. XICEM(I,J) .LT. XICE_THRESHOLD ) THEN
          ! water point turns to sea-ice point
          XICEM(I,J) = XICE(I,J)
          XLAND(I,J) = 1.
          IVGTYP(I,J) = ISICE
          ISLTYP(I,J) = 16
          VEGFRA(I,J) = 0.
          TMN(I,J) = 271.4

          ! Over new ice, initial guesses of ALBEDO and EMISS are
          ! based on default water and ice values for albedo and
          ! emissivity.  The land-surface schemes can update these
          ! values

          SELECT CASE ( SEAICE_ALBEDO_OPT )
          CASE ( 0, 1 )

              ALBEDO(I,J) = SEAICE_ALBEDO_DEFAULT * XICE(I,J) + 0.08 * ( 1.0-XICE(I,J) )
              ALBBCK(I,J) = SEAICE_ALBEDO_DEFAULT

          CASE ( 2 ) 
              
              IF ( ALBSI(I,J) < -1.E6 ) THEN
                  call wrf_error_fatal("Field ALBSI not found in input.  Field ALBSI is required if SEAICE_ALBEDO_OPT=2")
              ENDIF

              ALBEDO(I,J) = ALBSI(I,J) * XICE(I,J) + 0.08 * ( 1.0-XICE(I,J) )
              ALBBCK(I,J) = ALBSI(I,J)

          END SELECT

          EMISS(I,J)  = 0.98 * XICE(I,J) + 0.98 * ( 1.0-XICE(I,J) )
          EMBCK(I,J)  = 0.98
          DO nk = 1, num_soil_layers
            TSLB(I,NK,J) = TSK(I,J)
            SMOIS(I,NK,J) = 1.0
            SH2O(I,NK,J) = 0.0
          ENDDO
        ENDIF
     IF (lakemodel.ne.1) then
         IF(XLAND(i,j) .GT. 1.5) THEN
           IF ( SST(i,j) .LT. 350. .and. SST(i,j) .GT. 250.) THEN
            TSK(i,j)   =SST(i,j)
            TSLB(i,1,j)=SST(i,j)
           ENDIF
          ENDIF
     ELSE
#if (EM_CORE==1)
!       if(lakeflag.eq.1) then
!         IF(XLAND(i,j) .GT. 1.5.AND.LAKEMASK(I,J).NE.1) THEN
!           IF ( SST(i,j) .LT. 350. .and. SST(i,j) .GT. 250.) THEN
!            TSK(i,j)   =SST(i,j)
!            TSLB(i,1,j)=SST(i,j)
!           ENDIF
!          ENDIF
!       else
!         if(XLAND(i,j) .GT. 1.5.and.ht(i,j).lt.lake_min_elev) then
!           IF ( SST(i,j) .LT. 350. .and. SST(i,j) .GT. 250.) THEN
!            TSK(i,j)   =SST(i,j)
!            TSLB(i,1,j)=SST(i,j)
!           ENDIF
!          ENDIF
!       endif   ! (lakeflag=1)
         IF(XLAND(i,j) .GT. 1.5.AND.LAKEMASK(I,J).NE.1) THEN
           IF ( SST(i,j) .LT. 350. .and. SST(i,j) .GT. 250.) THEN
            TSK(i,j)   =SST(i,j)
            TSLB(i,1,j)=SST(i,j)
           ENDIF
          ENDIF
#else
       IF(XLAND(i,j) .GT. 1.5.and.ht(i,j).lt.lake_min_elev) then
           IF ( SST(i,j) .LT. 350. .and. SST(i,j) .GT. 250.) THEN
            TSK(i,j)   =SST(i,j)
            TSLB(i,1,j)=SST(i,j)
           ENDIF
       ENDIF
#endif
     ENDIF  ! (lakemodel=1)
        IF ( XLAND(i,j) .LT. 1.5 .AND. XICEM(I,J) .GE. XICE_THRESHOLD .AND. XICE(I,J) .LT. XICE_THRESHOLD ) THEN
! sea-ice point turns to water point
          XICEM(I,J) = XICE(I,J)
          XLAND(I,J) = 2.
          IVGTYP(I,J) = ISWATER
          ISLTYP(I,J) = 14
          VEGFRA(I,J) = 0.
          SNOW(I,J)  = 0.
          SNOWC(I,J) = 0.
          SNOWH(I,J) = 0.
          TMN(I,J) = SST(I,J)
          ALBEDO(I,J) = 0.08
          ALBBCK(I,J) = 0.08
          EMISS(I,J)  = 0.98
          EMBCK(I,J)  = 0.98
          DO nk = 1, num_soil_layers
            TSLB(I,NK,J) = SST(I,J)
            SMOIS(I,NK,J) = 1.0
            SH2O(I,NK,J) = 1.0
          ENDDO
        ENDIF

        XICE_save(I,J) = XICEM(I,J)
        XICEM(i,j) = XICE(i,j)
        TSK_SAVE(I,J) = TSK(I, J)

      ENDDO
      ENDDO
    ENDDO
    !$OMP END PARALLEL DO
  ENDIF

  IF(PRESENT(SST_SKIN))THEN
    IF (sst_skin .EQ. 1) THEN
#ifdef WRF_GPU
      CALL wrf_error_fatal('surface_driver: sst_skin not ported to the GPU')
#endif
! Calculate skin sst based on Zeng and Beljaars (2005)
      CALL wrf_debug( 100, 'in SST_SKIN_UPDATE' )
      !$OMP PARALLEL DO   &
      !$OMP PRIVATE ( ij, i, j, k )
      DO ij = 1 , num_tiles
        DO j=j_start(ij),j_end(ij)
          DO i=i_start(ij),i_end(ij)
            IF(XLAND(i,j) .GT. 1.5 .and. sst_update .NE. 1) THEN
              TSK(i,j)   =SST(i,j)
              TSLB(i,1,j)=SST(i,j)
            ENDIF
          ENDDO
        ENDDO
        CALL sst_skin_update(xland,glw,gsw,hfx,qfx,tsk,ust,         &
                emiss,dtw,sstsk,dt,stbolt,                          &
                ids, ide, jds, jde, kds, kde,                       &
                ims, ime, jms, jme, kms, kme,                       &
                i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte   )
        DO j=j_start(ij),j_end(ij)
          DO i=i_start(ij),i_end(ij)
            IF(XLAND(i,j) .GT. 1.5)TSK(i,j)=SSTSK(i,j)
          ENDDO
        ENDDO
      ENDDO
    !$OMP END PARALLEL DO
    ENDIF
  ENDIF

  IF(PRESENT(TMN_UPDATE))THEN
  IF (tmn_update .EQ. 1) THEN
#ifdef WRF_GPU
    CALL wrf_error_fatal('surface_driver: tmn_update not ported to the GPU')
#endif
      CALL wrf_debug( 100, 'in TMN_UPDATE' )
      CALL tmnupdate(tsk,tmn,tlag,tyr,tyra,tdly,nday,nyear,lagday, &
                julian_in, dt, yr,                                  &
                ids, ide, jds, jde, kds, kde,                       &
                ims, ime, jms, jme, kms, kme,                       &
                i_start,i_end, j_start,j_end, kts,kte, num_tiles   )

  ENDIF
  ENDIF
!
! Modified for adaptive time step
!
   doing_adapt_dt = .FALSE.
   IF ( PRESENT(adapt_step_flag) ) THEN
      IF ( adapt_step_flag ) THEN
         doing_adapt_dt = .TRUE.
      END IF
   END IF

!  Do we run through this scheme or not?

!    Test 1:  If this is the initial model time, then yes.
!                ITIMESTEP=1
!    Test 2:  If the user asked for the surface to be run every time step, then yes.
!                BLDT=0 or STEPBL=1
!    Test 3:  If not adaptive dt, and this is on the requested surface frequency, then yes.
!                MOD(ITIMESTEP,STEPBL)=0
!    Test 4:  If using adaptive dt and the current time is past the last requested activate surface time, then yes.
!                CURR_SECS >= BLDTACTTIME

!  If we do run through the scheme, we set the flag run_param to TRUE and we set the decided flag
!  to TRUE.  The decided flag says that one of these tests was able to say "yes", run the scheme.
!  We only proceed to other tests if the previous tests all have left decided as FALSE.

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
   END IF

  run_param_if: IF ( run_param ) then

  radiation = .false.
  frpcpn = .false.
  myj    = ((sf_sfclay_physics .EQ. MYJSFCSCHEME) .OR. &
            (sf_sfclay_physics .EQ. QNSESFCSCHEME) )

  myjpbl = ((bl_pbl_physics .EQ. MYJPBLSCHEME) .OR. &
            (bl_pbl_physics .EQ. QNSEPBLSCHEME) )

  isisfc = ( FRACTIONAL_SEAICE .EQ. 1  .AND. (          &
            (sf_sfclay_physics .EQ. SFCLAYSCHEME ) .OR. &
            (sf_sfclay_physics .EQ. SFCLAYREVSCHEME ) .OR. &
            (sf_sfclay_physics .EQ. PXSFCSCHEME  ) .OR. &
            (sf_sfclay_physics .EQ. MYJSFCSCHEME ) .OR. &
            (sf_sfclay_physics .EQ. QNSESFCSCHEME ) .OR. &  !emt
#if (EM_CORE==1)
            (sf_sfclay_physics .EQ. MYNNSFCSCHEME ) .OR. &
#endif
            (sf_sfclay_physics .EQ. GFSSFCSCHEME ) )    &
           )

  IF (ra_lw_physics .gt. 0) radiation = .true.

  IF( PRESENT(slope_rad).AND. radiation )THEN
! topographic slope effects modify SWDOWN and GSW here
    IF (slope_rad .EQ. 1) THEN
#ifdef WRF_GPU
      CALL wrf_error_fatal('surface_driver: slope_rad not ported to the GPU')
#endif
    !$OMP PARALLEL DO   &
    !$OMP PRIVATE ( ij, i, j, k )
    DO ij = 1 , num_tiles
           CALL TOPO_RAD_ADJ_DRVR (XLAT,XLONG,COSZEN,             &
                    shadowmask,diffuse_frac,                      &
                    declin,                                       &
                    SWDOWN,GSW,SWNORM,GSWSAVE,solcon,hrang,       &
                    slope,slp_azi,                                &
                ids, ide, jds, jde, kds, kde,                     &
                ims, ime, jms, jme, kms, kme,                     &
                i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte   )
    ENDDO
    !$OMP END PARALLEL DO

    ENDIF
  ENDIF
!----
! CALCULATE CONSTANT

     DTMIN=DT/60.
! Surface schemes need PBL time step for updates and accumulations
! Assume these schemes provide no tendencies

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
                                 " time-step should be 0 (i.e., equivalent to model time-step)." )
                call wrf_message("In order to proceed, for surface calculations, the "// &
                                 "boundary layer time-step"// &
                                 " will be rounded to the nearest minute," )
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

! SAVE OLD VALUES


#ifdef WRF_GPU
  DO ij = 1, num_tiles
     its = i_start_h(ij)
     ite = i_end_h(ij)
     jts = j_start_h(ij)
     jte = j_end_h(ij)
! K-SD-3: PSFC and u v copies (Template A)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_SURFACE_DRIVER)) default(none) &
!$acc& present(psfc, p8w, v_phytmp, u_phytmp, v_phy, u_phy, uoce, voce) &
!$acc& firstprivate(its, ite, jts, jte, kts, kte, v_frame, u_frame) &
!$acc& private(i, j, k)
       DO j=jts,jte
       DO i=its,ite
! PSFC : in Pa
          PSFC(I,J)=p8w(I,kts,J)
! REVERSE ORDER IN THE VERTICAL DIRECTION
          !$acc loop seq
          DO k=kts,kte
            v_phytmp(i,k,j)=v_phy(i,k,j)+v_frame
            u_phytmp(i,k,j)=u_phy(i,k,j)+u_frame
          ENDDO
! remove surface currents for atmospheric low-level winds
          u_phytmp(i,kts,j)=u_phytmp(i,kts,j)-uoce(i,j)
          v_phytmp(i,kts,j)=v_phytmp(i,kts,j)-voce(i,j)
       ENDDO
       ENDDO
  ENDDO
#else
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij, i, j, k )
     DO ij = 1 , num_tiles
       DO j=j_start(ij),j_end(ij)
       DO i=i_start(ij),i_end(ij)
! PSFC : in Pa
          PSFC(I,J)=p8w(I,kts,J)
! REVERSE ORDER IN THE VERTICAL DIRECTION
          DO k=kts,kte
            v_phytmp(i,k,j)=v_phy(i,k,j)+v_frame
            u_phytmp(i,k,j)=u_phy(i,k,j)+u_frame
          ENDDO
! remove surface currents for atmospheric low-level winds
          u_phytmp(i,kts,j)=u_phytmp(i,kts,j)-uoce(i,j)
          v_phytmp(i,kts,j)=v_phytmp(i,kts,j)-voce(i,j)
       ENDDO
       ENDDO
     ENDDO
     !$OMP END PARALLEL DO
#endif

     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij, i, j, k )
     DO ij = 1 , num_tiles
#ifdef WRF_GPU
       its = i_start_h(ij)
       ite = i_end_h(ij)
       jts = j_start_h(ij)
       jte = j_end_h(ij)
#endif
     sfclay_select: SELECT CASE(sf_sfclay_physics)

     CASE (SFCLAYSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: SFCLAYSCHEME not ported to the GPU')
#endif
! DX varies spatially in NMM, therefore, SFCLAY cannot be called
! because it takes a scalar DX. NMM passes in a dummy value for this
! scalar.  NEEDS FURTHER ATTENTION. JM 20050215
       IF(PRESENT(SCM_FORCE_FLUX))THEN
         IF (scm_force_flux .EQ. 1) THEN
! surface forcing by observed fluxes
         CALL scmflux(u_phytmp, v_phytmp, t_phy, qv_curr, p_phy, dz8w,   &
                     cp, rcp, xlv, psfc, cpm, xland,                     &
                     psim, psih, hfx, qfx, lh, tsk, flhc, flqc,          &
                     znt, gz1oz0, wspd,                                  &
                     julian_in, karman, p1000mb,                         &
                     itimestep,chklowq,                                  &
                     ids, ide, jds, jde, kds, kde,                       &
                     ims, ime, jms, jme, kms, kme,                       &
                     i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte   )
         ENDIF
       ENDIF
       IF(PRESENT(SCM_FORCE_SKINTEMP))THEN
         IF (scm_force_skintemp .EQ. 1) THEN
! surface forcing by observed skin temperature
         CALL scmskintemp(tsk, julian_in, itimestep,                     &
                     ids, ide, jds, jde, kds, kde,                       &
                     ims, ime, jms, jme, kms, kme,                       &
                     i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte   )
         ENDIF
!         IF (scm_force_skintemp .EQ. 2) THEN
! surface forcing by gabls2 skin temperature
!         CALL scmgabls2(tsk, itimestep, dt,                              &
!                     ids, ide, jds, jde, kds, kde,                       &
!                     ims, ime, jms, jme, kms, kme,                       &
!                     i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte   )
!         ENDIF
       ENDIF
       IF (PRESENT(qv_curr)                            .AND.    &
           PRESENT(mol)        .AND.  PRESENT(regime)  .AND.    &
                                                      .TRUE. ) THEN
         CALL wrf_debug( 100, 'in SFCLAY' )
         IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            CALL SFCLAY_SEAICE_WRAPPER(u_phytmp,v_phytmp,t_phy,qv_curr,&
                 p_phy,dz8w,cp,g,rcp,r_d,xlv,psfc,chs,chs2,cqs2,cpm, &
                 znt,ust,pblh,mavail,zol,mol,regime,psim,psih,fm,fhh, &
                 xland,hfx,qfx,lh,tsk,flhc,flqc,qgh,qsfc,rmol,       &
                 u10,v10,th2,t2,q2,                                  &
                 gz1oz0,wspd,br,isfflx,dx2d,                         &
                 svp1,svp2,svp3,svpt0,ep_1,ep_2,karman,eomeg,stbolt, &
                 P1000mb,lakemask,                                   &
                 XICE,SST,TSK_SEA,                                                  &
                 CHS2_SEA,CHS_SEA,CPM_SEA,CQS2_SEA,FLHC_SEA,FLQC_SEA,               &
                 HFX_SEA,LH_SEA,QFX_SEA,QGH_SEA,QSFC_SEA,ZNT_SEA,                   &
                 ITIMESTEP,TICE2TSK_IF2COLD,XICE_THRESHOLD,                         &
                 ids,ide, jds,jde, kds,kde,                          &
                 ims,ime, jms,jme, kms,kme,                          &
                 i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte,    &
                 ustm,ck,cka,cd,cda,isftcflx,iz0tlnd,scm_force_flux, &
                 sf_surface_physics  )
         ELSE
         CALL SFCLAY(u_phytmp,v_phytmp,t_phy,qv_curr,              &
               p_phy,dz8w,cp,g,rcp,r_d,xlv,psfc,chs,chs2,cqs2,cpm, &
               znt,ust,pblh,mavail,zol,mol,regime,psim,psih,fm,fhh, &
               xland,hfx,qfx,lh,tsk,flhc,flqc,qgh,qsfc,rmol,       &
               u10,v10,th2,t2,q2,                                  &
               gz1oz0,wspd,br,isfflx,dx2d,                         &
               svp1,svp2,svp3,svpt0,ep_1,ep_2,karman,eomeg,stbolt, &
               P1000mb,lakemask,                                   &
               ids,ide, jds,jde, kds,kde,                          &
               ims,ime, jms,jme, kms,kme,                          &
               i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte,    &
               ustm,ck,cka,cd,cda,isftcflx,iz0tlnd,scm_force_flux  ) 
#if ( EM_CORE==1)
           DO j = j_start(ij),j_end(ij)
           DO i = i_start(ij),i_end(ij)
             ch(i,j) = chs (i,j)
!!             ch(i,j) = flhc(i,j)/( cpm(i,j)*rho(i,kts,j) )
           end do
           end do
#endif
         ENDIF
       ELSE
         CALL wrf_error_fatal('Lacking arguments for SFCLAY in surface driver')
       ENDIF

     CASE (SFCLAYREVSCHEME)
! DX varies spatially in NMM, therefore, SFCLAY cannot be called
! because it takes a scalar DX. NMM passes in a dummy value for this
! scalar.  NEEDS FURTHER ATTENTION. JM 20050215
       IF (PRESENT(qv_curr)                            .AND.    &
           PRESENT(mol)        .AND.  PRESENT(regime)  .AND.    &
                                                      .TRUE. ) THEN
         CALL wrf_debug( 100, 'in SFCLAY' )

         IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            CALL SFCLAYREV_SEAICE_WRAPPER(u_phytmp,v_phytmp,t_phy,qv_curr,&
                 p_phy,dz8w,cp,g,rcp,r_d,xlv,psfc,chs,chs2,cqs2,cpm, &
                 znt,ust,pblh,mavail,zol,mol,regime,psim,psih,fm,fhh, &
                 xland,hfx,qfx,lh,tsk,flhc,flqc,qgh,qsfc,rmol,       &
                 u10,v10,th2,t2,q2,                                  &
                 gz1oz0,wspd,br,isfflx,dx2d,                         &
                 svp1,svp2,svp3,svpt0,ep_1,ep_2,karman,              &
                 P1000mb,lakemask,                                   &
                 XICE,SST,TSK_SEA,                                                  &
                 CHS2_SEA,CHS_SEA,CPM_SEA,CQS2_SEA,FLHC_SEA,FLQC_SEA,               &
                 HFX_SEA,LH_SEA,QFX_SEA,QGH_SEA,QSFC_SEA,ZNT_SEA,                   &
                 ITIMESTEP,TICE2TSK_IF2COLD,XICE_THRESHOLD,                         &
                 ids,ide, jds,jde, kds,kde,                          &
                 ims,ime, jms,jme, kms,kme,                          &
                 i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte,    &
                 ustm,ck,cka,cd,cda,isftcflx,iz0tlnd,                &
                 shalwater_z0,water_depth,                           & 
                 scm_force_flux,sf_surface_physics,errmsg,errflg     )
         ELSE
         CALL SFCLAYREV(u_phytmp,v_phytmp,t_phy,qv_curr,&
               p_phy,dz8w,cp,g,rcp,r_d,xlv,psfc,chs,chs2,cqs2,cpm, &
               znt,ust,pblh,mavail,zol,mol,regime,psim,psih,fm,fhh, &
               xland,hfx,qfx,lh,tsk,flhc,flqc,qgh,qsfc,rmol,       &
               u10,v10,th2,t2,q2,                                  &
               gz1oz0,wspd,br,isfflx,dx2d,                         &
               svp1,svp2,svp3,svpt0,ep_1,ep_2,karman,              &
               P1000mb,lakemask,                                   &
               ids,ide, jds,jde, kds,kde,                          &
               ims,ime, jms,jme, kms,kme,                          &
               i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte,    &
               ustm,ck,cka,cd,cda,isftcflx,iz0tlnd,                &
               shalwater_z0,water_depth,                           & 
               scm_force_flux,errmsg,errflg                        ) 
#if ( EM_CORE==1)
#ifdef WRF_GPU
! K-SD-4: ch = chs (Template A)
           IF (.NOT. PRESENT(ch)) THEN
              CALL wrf_error_fatal('surface_driver: ch not present')
           END IF
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_SURFACE_DRIVER)) default(none) &
!$acc& present(ch, chs) &
!$acc& firstprivate(its, ite, jts, jte) &
!$acc& private(i, j)
           DO j = jts,jte
           DO i = its,ite
             ch(i,j) = chs (i,j)
!!             ch(i,j) = flhc(i,j)/( cpm(i,j)*rho(i,kts,j) )
           end do
           end do
#else
           DO j = j_start(ij),j_end(ij)
           DO i = i_start(ij),i_end(ij)
             ch(i,j) = chs (i,j)
!!             ch(i,j) = flhc(i,j)/( cpm(i,j)*rho(i,kts,j) )
           end do
           end do
#endif
#endif
         ENDIF
       ELSE
         CALL wrf_error_fatal('Lacking arguments for SFCLAY in surface driver')
       ENDIF

     CASE (PXSFCSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: PXSFCSCHEME not ported to the GPU')
#endif
       IF (PRESENT(qv_curr)                            .AND.    &
           PRESENT(mol)        .AND.  PRESENT(regime)  .AND.    &
                                                      .TRUE. ) THEN
         CALL wrf_debug( 100, 'in PX Surface Layer scheme' )
         IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            CALL PXSFCLAY_SEAICE_WRAPPER(u_phytmp,v_phytmp,t_phy,th_phy,qv_curr,&
                 p_phy,dz8w,cp,g,rcp,r_d,xlv,psfc,chs,chs2,cqs2,cpm, &
                 znt,ust,pblh,mavail,zol,mol,regime,psim,psih,       &
                 xland,hfx,qfx,lh,tsk,flhc,flqc,qgh,qsfc,rmol,       &
                 u10,v10,                                            &
                 gz1oz0,wspd,br,isfflx,dx,                           &
                 svp1,svp2,svp3,svpt0,ep_1,ep_2,karman,              &
                 XICE, SST, ITIMESTEP, TICE2TSK_IF2COLD,XICE_THRESHOLD, &
                 CHS_SEA, CHS2_SEA, CPM_SEA, CQS2_SEA,FLHC_SEA,FLQC_SEA,&
                 HFX_SEA, LH_SEA, QFX_SEA, QGH_SEA, QSFC_SEA, TSK_SEA,  &
                 ids,ide, jds,jde, kds,kde,                          &
                 ims,ime, jms,jme, kms,kme,                          &
                 i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte    )
         ELSE
         CALL PXSFCLAY(u_phytmp,v_phytmp,t_phy,th_phy,qv_curr,&
               p_phy,dz8w,cp,g,rcp,r_d,xlv,psfc,chs,chs2,cqs2,cpm, &
               znt,ust,pblh,mavail,zol,mol,regime,psim,psih,       &
               xland,hfx,qfx,lh,tsk,flhc,flqc,qgh,qsfc,rmol,       &
               u10,v10,                                            &
               gz1oz0,wspd,br,isfflx,dx,                           &
               svp1,svp2,svp3,svpt0,ep_1,ep_2,karman,itimestep,    &
               ids,ide, jds,jde, kds,kde,                          &
               ims,ime, jms,jme, kms,kme,                          &
               i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte    )
         ENDIF
       ELSE
         CALL wrf_error_fatal('Lacking arguments for PX Surface Layer in surface driver')
       ENDIF

      CASE (MYJSFCSCHEME)
       IF (PRESENT(qv_curr)    .AND.  PRESENT(qc_curr) .AND.    &
                                                      .TRUE. ) THEN

        CALL wrf_debug(100,'in MYJSFC')
        IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
          CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
           CALL MYJSFC_SEAICE_WRAPPER(itimestep,ht,dz8w,             &
                p_phy,p8w,th_phy,t_phy,                              &
                qv_curr,qc_curr,                                     &
                u_phy,v_phy,tke_pbl,                                 &
                tsk,qsfc,thz0,qz0,uz0,vz0,                           &
                lowlyr,                                              &
                xland,ivgtyp,isurban,iz0tlnd,                        &
                TICE2TSK_IF2COLD,                                    & ! Extra for wrapper.
                XICE_THRESHOLD,                                      & ! Extra for wrapper.
                XICE, SST,                                           & ! Extra for wrapper.
                CHS_SEA, CHS2_SEA, CQS2_SEA, CPM_SEA,            &
                FLHC_SEA, FLQC_SEA, QSFC_SEA, &
                QGH_SEA, QZ0_SEA, HFX_SEA, QFX_SEA, LH_SEA,         &
                TSK_SEA,                                             &
                ust,znt,z0,pblh,mavail,rmol,                         &
                akhs,akms,                                           &
                br,                                                 &
                chs,chs2,cqs2,hfx,qfx,lh,flhc,flqc,qgh,cpm,ct,       &
                u10,v10,t2,th2,tshltr,th10,q2,qshltr,q10,pshltr,               &
                p1000mb,u10e,v10e,                                   &
                ids,ide, jds,jde, kds,kde,                           &
                ims,ime, jms,jme, kms,kme,                           &
                i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte    )
        ELSE
            CALL MYJSFC(itimestep,ht,dz8w,                         &
              p_phy,p8w,th_phy,t_phy,                              &
              qv_curr,qc_curr,                                      &
              u_phy,v_phy,tke_pbl,                                 &
              tsk,qsfc,thz0,qz0,uz0,vz0,                           &
              lowlyr,                                              &
              xland,ivgtyp,isurban,iz0tlnd,                        &
              ust,znt,z0,pblh,mavail,rmol,                         &
              akhs,akms,                                           &
              br,                                                 &
              chs,chs2,cqs2,hfx,qfx,lh,flhc,flqc,qgh,cpm,ct,       &
              u10,v10,t2,th2,tshltr,th10,q2,qshltr,q10,pshltr,               &
              p1000mb,u10e,v10e,                                   &
              ids,ide, jds,jde, kds,kde,                           &
              ims,ime, jms,jme, kms,kme,                           &
              i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte    )
        ENDIF
!       ustm is needed for LES tke calculation (ustm is ust used in friction)
         DO j = j_start(ij),j_end(ij)
            DO i = i_start(ij),i_end(ij)
               ustm(i,j) = ust(i,j)
               wspd(i,j) = MAX(SQRT(u_phy(i,kts,j)**2+v_phy(i,kts,j)**2),0.001)
               ch(i,j) = chs (i,j)
            END DO
         END DO
       ELSE
         CALL wrf_error_fatal('Lacking arguments for MYJSFC in surface driver')
       ENDIF

      CASE (QNSESFCSCHEME)
       IF(PRESENT(SCM_FORCE_FLUX))THEN
         IF (scm_force_flux .EQ. 1) THEN
! surface forcing by observed fluxes
         CALL scmflux(u_phytmp, v_phytmp, t_phy, qv_curr, p_phy, dz8w,   &
                     cp, rcp, xlv, psfc, cpm, xland,                     &
                     psim, psih, hfx, qfx, lh, tsk, flhc, flqc,          &
                     znt, gz1oz0, wspd,                                  &
                     julian_in, karman, p1000mb,                         &
                     itimestep,chklowq,                                  &
                     ids, ide, jds, jde, kds, kde,                       &
                     ims, ime, jms, jme, kms, kme,                       &
                     i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte   )
         ENDIF
       ENDIF
       IF(PRESENT(SCM_FORCE_SKINTEMP))THEN
         IF (scm_force_skintemp .EQ. 1) THEN
! surface forcing by observed skin temperature
         CALL scmskintemp(tsk, julian_in, itimestep,                     &
                     ids, ide, jds, jde, kds, kde,                       &
                     ims, ime, jms, jme, kms, kme,                       &
                     i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte   )
         ENDIF
       ENDIF

       IF (PRESENT(qv_curr)    .AND.  PRESENT(qc_curr) .AND.    &
                                                      .TRUE. ) THEN
            CALL wrf_debug(100,'in QNSESFC')
             IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
               CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
           CALL QNSESFC_SEAICE_WRAPPER(itimestep,ht,dz8w,             &
                p_phy,p8w,th_phy,t_phy,                              &
                qv_curr,qc_curr,                                     &
                u_phy,v_phy,tke_pbl,                                 &
                tsk,qsfc,thz0,qz0,uz0,vz0,                           &
                lowlyr,                                              &
                xland,                                               &
                TICE2TSK_IF2COLD,                                    & ! Extra for wrapper.
                XICE_THRESHOLD,                                      & ! Extra for wrapper.
                XICE, SST,                                           & ! Extra for wrapper.
                CHS_SEA, CHS2_SEA, CQS2_SEA, CPM_SEA,            &
                FLHC_SEA, FLQC_SEA, QSFC_SEA, &
                QGH_SEA, QZ0_SEA, HFX_SEA, QFX_SEA, LH_SEA,         &
                TSK_SEA,                                             &
                ust,znt,z0,pblh,mavail,rmol,                         &
                akhs,akms,                                           &
                br,                                                 &
                chs,chs2,cqs2,hfx,qfx,lh,flhc,flqc,qgh,cpm,ct,       &
                u10,v10,t2,th2,tshltr,th10,q2,qshltr,q10,pshltr,     &
                u10e,v10e,                                           &
                ids,ide, jds,jde, kds,kde,                           &
                ims,ime, jms,jme, kms,kme,                           &
                i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte,SCM_FORCE_FLUX    )
           ELSE
            CALL QNSESFC(itimestep,ht,dz8w,                         &
              p_phy,p8w,th_phy,t_phy,                              &
              qv_curr,qc_curr,                                     &
              u_phy,v_phy,tke_pbl,                                 &
              tsk,qsfc,thz0,qz0,uz0,vz0,                           &
              lowlyr,                                              &
              xland,                                               &
              ust,znt,z0,pblh,mavail,rmol,                         &
              akhs,akms,                                           &
              br,                                                 &
              chs,chs2,cqs2,hfx,qfx,lh,flhc,flqc,qgh,cpm,ct,       &
              u10,v10,t2,th2,tshltr,th10,q2,qshltr,q10,pshltr,     &
              u10e,v10e,                                           &
              ids,ide, jds,jde, kds,kde,                           &
              ims,ime, jms,jme, kms,kme,                           &
              i_start(ij),i_end(ij), j_start(ij),j_end(ij),     &
              kts,kte,scm_force_flux    )
           ENDIF
#if ( EM_CORE==1)
         DO j = j_start(ij),j_end(ij)
            DO i = i_start(ij),i_end(ij)
               wspd(i,j) = MAX(SQRT(u_phy(i,kts,j)**2+v_phy(i,kts,j)**2),0.001)
               ch(i,j) = chs (i,j)
!!           ch(i,j) = flhc(i,j)/( cpm(i,j)*rho(i,kts,j) )
            END DO
         END DO
#endif         
       ELSE
         CALL wrf_error_fatal('Lacking arguments for QNSESFC in surface driver')
       ENDIF

     CASE (GFSSFCSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: GFSSFCSCHEME not ported to the GPU')
#endif
       IF (PRESENT(qv_curr) .AND. .TRUE. ) THEN
       CALL wrf_debug( 100, 'in GFSSFC' )
       IF (FRACTIONAL_SEAICE == 1) THEN
#ifdef WRF_GPU
         CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
          CALL SF_GFS_SEAICE_WRAPPER(u_phytmp,v_phytmp,t_phy,qv_curr, &
               p_phy,CP,RCP,R_d,XLV,PSFC,CHS,CHS2,CQS2,CPM,        &
               ZNT,UST,PSIM,PSIH,                                  &
               XLAND,HFX,QFX,LH,TSK,FLHC,FLQC,                     &
               QGH,QSFC,U10,V10,                                   &
               GZ1OZ0,WSPD,BR,ISFFLX,                              &
               EP_1,EP_2,KARMAN,itimestep,                         &
               TICE2TSK_IF2COLD,                            &
               XICE_THRESHOLD,                              &
               CHS_SEA, CHS2_SEA, CPM_SEA, CQS2_SEA,        &
               FLHC_SEA, FLQC_SEA,                          &
               HFX_SEA, LH_SEA, QFX_SEA, QGH_SEA, QSFC_SEA, &
               UST_SEA, ZNT_SEA, SST, XICE,                 &
               ids,ide, jds,jde, kds,kde,                          &
               ims,ime, jms,jme, kms,kme,                          &
               i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte    )
      ELSE
         CALL SF_GFS(u_phytmp,v_phytmp,t_phy,qv_curr,              &
               p_phy,CP,RCP,R_d,XLV,PSFC,CHS,CHS2,CQS2,CPM,        &
               ZNT,UST,PSIM,PSIH,                                  &
               XLAND,HFX,QFX,LH,TSK,FLHC,FLQC,                     &
               QGH,QSFC,U10,V10,                                   &
               GZ1OZ0,WSPD,BR,ISFFLX,                              &
               EP_1,EP_2,KARMAN,itimestep,                         &
               ids,ide, jds,jde, kds,kde,                          &
               ims,ime, jms,jme, kms,kme,                          &
               i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte    )
      ENDIF
        CALL wrf_debug(100,'in SFCDIAGS')
       ELSE
         CALL wrf_error_fatal('Lacking arguments for SF_GFS in surface driver')
      ENDIF

#if ( EM_CORE==1)
    CASE(MYNNSFCSCHEME)

       IF (PRESENT(qv_curr)    .AND.  PRESENT(qc_curr)     &
            & .AND.  PRESENT(qcg) ) THEN

          CALL wrf_debug(100,'in MYNNSFC')

         IF (FRACTIONAL_SEAICE == 1) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
          CALL MYNN_SEAICE_WRAPPER(u_phytmp,v_phytmp,t_phy,qv_curr,&
               p_phy,dz8w,th_phy,rho,                              &
               cp,g,rcp,r_d,xlv,psfc,chs,chs2,cqs2,cpm,            &
               znt,ust,pblh,mavail,zol,mol,regime,psim,psih,       &
               xland,hfx,qfx,lh,tsk,flhc,flqc,qgh,qsfc,rmol,       &
               u10,v10,th2,t2,q2,SNOWH,                            &
               gz1oz0,wspd,br,isfflx,dx,                           &
               svp1,svp2,svp3,svpt0,ep_1,ep_2,karman,              &
               itimestep,ch,qcg,                                   &
               spp_pbl,pattern_spp_pbl,                            &
               XICE,SST,TSK_SEA,                                   &
               CHS2_SEA,CHS_SEA,CPM_SEA,CQS2_SEA,FLHC_SEA,FLQC_SEA,&
               HFX_SEA,LH_SEA,QFX_SEA,QGH_SEA,QSFC_SEA,ZNT_SEA,    &
               TICE2TSK_IF2COLD,XICE_THRESHOLD,                    &
               ids,ide, jds,jde, kds,kde,                          &
               ims,ime, jms,jme, kms,kme,                          &
               i_start(ij),i_end(ij),j_start(ij),j_end(ij),kts,kte,&   
               ustm,ck,cka,cd,cda,isftcflx,iz0tlnd                 )
         ELSE
          CALL SFCLAY_mynn(u_phytmp,v_phytmp,t_phy,qv_curr,        &
               p_phy,dz8w,th_phy,rho,                              &
               cp,g,rcp,r_d,xlv,psfc,chs,chs2,cqs2,cpm,            &
               znt,ust,pblh,mavail,zol,mol,regime,psim,psih,       &
               xland,hfx,qfx,lh,tsk,flhc,flqc,qgh,qsfc,rmol,       &
               u10,v10,th2,t2,q2,SNOWH,                            &
               gz1oz0,wspd,br,isfflx,dx,                           &
               svp1,svp2,svp3,svpt0,ep_1,ep_2,karman,              &
               itimestep,ch,qcg,                                   &
               spp_pbl,pattern_spp_pbl,                            &
               ids,ide, jds,jde, kds,kde,                          &
               ims,ime, jms,jme, kms,kme,                          &
               i_start(ij),i_end(ij),j_start(ij),j_end(ij),kts,kte,&
               ustm,ck,cka,cd,cda,isftcflx,iz0tlnd                 )
         ENDIF
       ELSE
          CALL wrf_error_fatal('Lacking arguments for SFCLAY_mynn in surface driver')
       ENDIF
#endif

#if ( EM_CORE==1)
     CASE (TEMFSFCSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: TEMFSFCSCHEME not ported to the GPU')
#endif
       IF (PRESENT(qv_curr).and.PRESENT(hd_temf)) THEN
         CALL wrf_debug( 100, 'in TEMFSFCLAY' )
! WA 9/7/09 must initialize Z0 and ZNT for TEMF in ideal cases
       ! DO J=j_start(ij),j_end(ij)
       ! DO I=i_start(ij),i_end(ij)
       !    CHKLOWQ(i,j) = 1.0
       !    Z0(i,j) = 0.03      ! For GABLS2
       !    ZNT(i,j) = 0.03     ! For GABLS2
       ! ENDDO
       ! ENDDO
         CALL TEMFSFCLAY(u3d=u_phytmp,v3d=v_phytmp,th3d=th_phy,    &
               qv3d=qv_curr,p3d=p_phy,pi3d=pi_phy,rho=rho,z=z,ht=ht, &
               CP=cp,G=g,ROVCP=rcp,R=r_d,XLV=xlv,psfc=psfc,chs=chs,&
               chs2=chs2,cqs2=cqs2,CPM=cpm,znt=znt,ust=ust,        &
               MAVAIL=mavail,XLAND=xland,HFX=hfx,QFX=qfx,LH=lh,   &
               TSK=tsk,FLHC=flhc,FLQC=flqc,QGH=qgh,qsfc=qsfc,      &
               U10=u10,V10=v10,TH2=th2,T2=t2,Q2=q2,                &
               SVP1=svp1,SVP2=svp2,SVP3=svp3,SVPT0=svpt0,EP1=ep_1, &
               EP2=ep_2,KARMAN=karman,fCor=fCor,te_temf=te_temf,   &
               hd_temf=hd_temf,exch_temf=exch_temf,wm_temf=wm_temf,&
               ids=ids,ide=ide, jds=jds,jde=jde, kds=kds,kde=kde,  &
               ims=ims,ime=ime, jms=jms,jme=jme, kms=kms,kme=kme,  &
               its=i_start(ij),ite=i_end(ij),                      &
               jts=j_start(ij),jte=j_end(ij), kts=kts,kte=kte )
       ELSE
         CALL wrf_error_fatal('Lacking arguments for TEMFSFCLAY in surface driver')
       ENDIF

     CASE (IDEALSCMSFCSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: IDEALSCMSFCSCHEME not ported to the GPU')
#endif
       IF (PRESENT(qv_curr)) THEN
         CALL wrf_debug( 100, 'in IDEALSCMSFCLAY' )
         CALL IDEALSCMSFCLAY(u3d=u_phytmp,v3d=v_phytmp,th3d=th_phy,    &
               qv3d=qv_curr,p3d=p_phy,pi3d=pi_phy,rho=rho,z=z,ht=ht, &
               CP=cp,G=g,ROVCP=rcp,R=r_d,XLV=xlv,psfc=psfc,chs=chs,  &
               chs2=chs2,cqs2=cqs2,CPM=cpm,znt=znt,ust=ust,        &
               MAVAIL=mavail,XLAND=xland,HFX=hfx,QFX=qfx,LH=lh,   &
               TSK=tsk,FLHC=flhc,FLQC=flqc,QGH=qgh,qsfc=qsfc,      &
               U10=u10,V10=v10,TH2=th2,T2=t2,Q2=q2,                &
               SVP1=svp1,SVP2=svp2,SVP3=svp3,SVPT0=svpt0,EP1=ep_1, &
               EP2=ep_2,KARMAN=karman,fCor=fCor,   &
               exch_temf=exch_temf,                &
               hfx_force=hfx_force,lh_force=lh_force,tsk_force=tsk_force, &
               hfx_force_tend=hfx_force_tend,                      &
               lh_force_tend=lh_force_tend,                        &
               tsk_force_tend=tsk_force_tend,                      &
               dt=dt,itimestep=itimestep,                          &
               ids=ids,ide=ide, jds=jds,jde=jde, kds=kds,kde=kde,  &
               ims=ims,ime=ime, jms=jms,jme=jme, kms=kms,kme=kme,  &
               its=i_start(ij),ite=i_end(ij),                      &
               jts=j_start(ij),jte=j_end(ij), kts=kts,kte=kte )
       ELSE
         CALL wrf_error_fatal('Lacking arguments for IDEALSCMSFCLAY in surface driver')
       ENDIF
#endif

     CASE DEFAULT

       WRITE( message , * )                                &
   'The sfclay option does not exist: sf_sfclay_physics = ', sf_sfclay_physics
       CALL wrf_error_fatal ( message )

     END SELECT sfclay_select

!  Compute uratx, vratx, tratx for obs nudging
     IF(PRESENT(uratx) .and. PRESENT(vratx) .and. PRESENT(tratx))THEN
#ifdef WRF_GPU
! K-SD-5: uratx vratx tratx (Template A)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_SURFACE_DRIVER)) default(none) &
!$acc& present(uratx, vratx, tratx, u10, v10, u_phytmp, v_phytmp, t_phy, p_phy, th2) &
!$acc& firstprivate(its, ite, jts, jte) &
!$acc& private(i, j)
        DO J=jts,jte
        DO I=its,ite
           IF(ABS(U10(I,J)) .GT. 1.E-10) THEN
              uratx(I,J) = U_PHYTMP(I,1,J)/U10(I,J)
           ELSE
              uratx(I,J) = 1.2
           END IF
           IF(ABS(V10(I,J)) .GT. 1.E-10) THEN
              vratx(I,J) = V_PHYTMP(I,1,J)/V10(I,J)
           ELSE
              vratx(I,J) = 1.2
           END IF
! (Quotient P1000mb/P_PHY must be conditioned due to large value of P1000mb)
           tratx(I,J) = (T_PHY(I,1,J)*rp_pow((P1000mb*0.001/(P_PHY(I,1,J)/1000.)), RCP))  &
                        /TH2(I,J)
        ENDDO
        ENDDO
#else
        DO J=j_start(ij),j_end(ij)
        DO I=i_start(ij),i_end(ij)
           IF(ABS(U10(I,J)) .GT. 1.E-10) THEN
              uratx(I,J) = U_PHYTMP(I,1,J)/U10(I,J)
           ELSE
              uratx(I,J) = 1.2
           END IF
           IF(ABS(V10(I,J)) .GT. 1.E-10) THEN
              vratx(I,J) = V_PHYTMP(I,1,J)/V10(I,J)
           ELSE
              vratx(I,J) = 1.2
           END IF
! (Quotient P1000mb/P_PHY must be conditioned due to large value of P1000mb)
           tratx(I,J) = (T_PHY(I,1,J)*rp_pow((P1000mb*0.001/(P_PHY(I,1,J)/1000.)), RCP))  &
                        /TH2(I,J)
        ENDDO
        ENDDO
#endif
     ENDIF

#if ( EM_CORE==1)
!Katata-added - fog (cloud) water deposition calculation
     IF ( grav_settling .EQ. 0 ) THEN
#ifdef WRF_GPU
        IF (.NOT. PRESENT(vdfg)) THEN
           CALL wrf_error_fatal('surface_driver: vdfg not present')
        END IF
! K-SD-6: vdfg = 0 (Template A)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_SURFACE_DRIVER)) default(none) &
!$acc& present(vdfg) &
!$acc& firstprivate(its, ite, jts, jte) &
!$acc& private(i, j)
        DO j=jts,jte
        DO i=its,ite
           vdfg(i,j)=0.
        ENDDO
        ENDDO
#else
        !vdfg = 0.
        DO j=j_start(ij),j_end(ij)
        DO i=i_start(ij),i_end(ij)
           vdfg(i,j)=0.
        ENDDO
        ENDDO
#endif
     ELSE
#ifdef WRF_GPU
        CALL wrf_error_fatal('surface_driver: grav_settling not ported to the GPU')
#endif
        IF ( PRESENT(dfgdp) .AND. PRESENT(fgdp) .AND. &
           & PRESENT(rainbl) .AND. PRESENT(vdfg)) THEN
           DO j=j_start(ij),j_end(ij)
           DO i=i_start(ij),i_end(ij)
              dfgdp(i,j)=0.
           ENDDO
           ENDDO

           CALL sf_fogdes(                                  &
                vdfg,fgdp,dfgdp,ivgtyp,lai,wspd,qc_curr,    &
                dtbl,rho,dz8w,grav_settling,nlcat,          &
                ids,ide, jds,jde, kds,kde,                  &
                ims,ime, jms,jme, kms,kme,                  &
                i_start(ij),i_end(ij),                      &
                j_start(ij),j_end(ij),kts,kte               )

           !Add fog dep to RAINBL in mm (Accumulation between PBL calls).
           DO j=j_start(ij),j_end(ij)
           DO i=i_start(ij),i_end(ij)
              RAINBL(i,j) = RAINBL(i,j) + dfgdp(i,j)
              RAINBL(i,j) = MAX(RAINBL(i,j), 0.0)
           ENDDO
           ENDDO

        ELSE
          CALL wrf_error_fatal('Missing args for FGDP in surface driver')
        ENDIF
     ENDIF
!Katata/Joe-END
#endif

     ENDDO
     !$OMP END PARALLEL DO

#ifdef WRF_GPU
     IF (ISFFLX.EQ.0 ) CALL wrf_error_fatal('surface_driver: isfflx=0 not ported to the GPU')
#endif
     IF (ISFFLX.EQ.0 ) GOTO 430
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij, i, j, k ) firstprivate(frpcpn)
     DO ij = 1 , num_tiles

#ifdef WRF_GPU
       its = i_start_h(ij)
       ite = i_end_h(ij)
       jts = j_start_h(ij)
       jte = j_end_h(ij)
#endif
     sfc_select: SELECT CASE(sf_surface_physics)

     CASE (SLABSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: SLABSCHEME not ported to the GPU')
#endif

       IF (PRESENT(qv_curr)                            .AND.    &
           PRESENT(capg)        .AND.    &
                                                      .TRUE. ) THEN
           DO j=j_start(ij),j_end(ij)
           DO i=i_start(ij),i_end(ij)
!          CQS2 ACCOUNTS FOR MAVAIL FOR SFCDIAGS 2M Q
              CQS2(I,J)= CQS2(I,J)*MAVAIL(I,J)
           ENDDO
           ENDDO

        CALL wrf_debug(100,'in SLAB')
          CALL SLAB(t_phy,qv_curr,p_phy,flhc,flqc,  &
             psfc,xland,tmn,hfx,qfx,lh,tsk,qsfc,chklowq,          &
             gsw,glw,capg,thc,snowc,emiss,mavail,                 &
             dtbl,rcp,xlv,dtmin,ifsnow,                           &
             svp1,svp2,svp3,svpt0,ep_2,karman,eomeg,stbolt,       &
             tslb,zs,dzs,num_soil_layers,radiation,               &
             p1000mb,                                             &
             ids,ide, jds,jde, kds,kde,                           &
             ims,ime, jms,jme, kms,kme,                           &
             i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte)

           DO j=j_start(ij),j_end(ij)
           DO i=i_start(ij),i_end(ij)
              SFCEVP(I,J)= SFCEVP(I,J) + QFX(I,J)*DTBL
              IF(PRESENT(ACHFX))ACHFX(I,J)=ACHFX(I,J) + HFX(I,J)*DT
              IF(PRESENT(ACLHF))ACLHF(I,J)=ACLHF(I,J) + LH(I,J)*DT
           ENDDO
           ENDDO

        CALL wrf_debug(100,'in SFCDIAGS')
          CALL SFCDIAGS(hfx,qfx,tsk,qsfc,chs2,cqs2,t2,th2,q2,      &
                     psfc,cp,r_d,rcp,CHS,t_phy,qv_curr,ua_phys,    &
                     ids,ide, jds,jde, kds,kde,                    &
                     ims,ime, jms,jme, kms,kme,                    &
             i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte    )

       ENDIF

     CASE (LSMSCHEME)

       IF (PRESENT(qv_curr)    .AND.  PRESENT(rainbl)        .AND.    &
!          PRESENT(emiss)      .AND.  PRESENT(t2)            .AND.    &
!          PRESENT(declin) .AND.  PRESENT(coszen)    .AND.    &
!          PRESENT(hrang)  .AND. PRESENT( xlat_urb2d)    .AND.    &
!          PRESENT(dzr)       .AND.    &
!          PRESENT( dzb)            .AND. PRESENT(dzg)       .AND.    &
!          PRESENT(tr_urb2d) .AND. PRESENT(tb_urb2d)         .AND.    &
!          PRESENT(tg_urb2d) .AND. PRESENT(tc_urb2d) .AND.            &
!          PRESENT(qc_urb2d) .AND. PRESENT(uc_urb2d) .AND.            &
!          PRESENT(xxxr_urb2d) .AND. PRESENT(xxxb_urb2d) .AND.        &
!          PRESENT(xxxg_urb2d) .AND.                                  &
!          PRESENT(xxxc_urb2d) .AND. PRESENT(trl_urb3d) .AND.         &
!          PRESENT(tbl_urb3d)   .AND. PRESENT(tgl_urb3d)  .AND.       &
!          PRESENT(sh_urb2d) .AND. PRESENT(lh_urb2d)  .AND.           &
!          PRESENT(g_urb2d)   .AND. PRESENT(rn_urb2d) .AND.           &
!          PRESENT(ts_urb2d)                          .AND.           &
!          PRESENT(frc_urb2d) .AND. PRESENT(utype_urb2d)   .AND.      &
                                                      .TRUE. ) THEN
!------------------------------------------------------------------
         IF( PRESENT(sr) ) THEN
           frpcpn=.true.
         ENDIF
         IF ( FRACTIONAL_SEAICE == 1) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            ! The fields passed to LSM need to represent the full ice values, not
            ! the fractional values.  Convert ALBEDO and EMISS from the blended value 
            ! to a value representing only the sea-ice portion.   Albedo over open 
            ! water is taken to be 0.08. Emissivity over open water is taken to be 0.98
            DO j = j_start(ij) , j_end(ij)
               DO i = i_start(ij) , i_end(ij)
                  IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1 ) ) THEN
                     ALBEDO(I,J) = (ALBEDO(I,J)-(1.-XICE(I,J))*0.08)/XICE(I,J)
                     EMISS(I,J) = (EMISS(I,J)-(1.-XICE(I,J))*0.98)/XICE(I,J)
                  ENDIF
               ENDDO
            ENDDO

            IF ( isisfc ) THEN
               ! Use surface layer routine values from the ice portion of grid point
            ELSE
               !
               ! We don't have surface layer routine values at this time, so
               ! just use what we have.  Use ice component of TSK
               !
               CALL get_local_ice_tsk( ims, ime, jms, jme,                   &
                                       i_start(ij), i_end(ij),               & 
                                       j_start(ij), j_end(ij),               &
                                       itimestep, .false., tice2tsk_if2cold, &
                                       XICE, XICE_THRESHOLD,                 &
                                       SST, TSK, TSK_SEA, TSK_LOCAL )

               DO j = j_start(ij) , j_end(ij)
                  DO i = i_start(ij) , i_end(ij)
                     TSK(i,j) = TSK_LOCAL(i,j)
                  ENDDO
               ENDDO
            ENDIF
         ENDIF

!added for WRF_HYDRO
#ifdef WRF_HYDRO
         if(HYDRO_dt .ge. 0) HYDRO_dt = dtbl
#endif

! added RA population for WRF/Noah-CMAQ RS Consistency
! following Garland et al. (1977) and Nemitz et al., 2009
         IF ( PRESENT(RA) ) THEN
#ifdef WRF_GPU
! K-SD-7: RA = WSPD/UST**2 (Template A)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_SURFACE_DRIVER)) default(none) &
!$acc& present(ra, wspd, ust) &
!$acc& firstprivate(its, ite, jts, jte) &
!$acc& private(i, j)
         DO j=jts,jte
         DO i=its,ite
            RA(I,J) = WSPD(I,J)/UST(I,J)**2
         ENDDO
         ENDDO
#else
         DO j=j_start(ij),j_end(ij)
         DO i=i_start(ij),i_end(ij)
            RA(I,J) = WSPD(I,J)/UST(I,J)**2
         ENDDO
         ENDDO
#endif
         END IF

         CALL wrf_debug(100,'in NOAH DRV')
                
         IF (sf_surface_mosaic == 1) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: sf_surface_mosaic not ported to the GPU')
#endif
          
           IF ( PRESENT( TSK_mosaic ) .AND. PRESENT( HFX_mosaic ) ) THEN
             CALL lsm_mosaic(dz8w,qv_curr,p8w,t_phy,tsk,                 &
                hfx,qfx,lh,grdflx,qgh,gsw,swdown,glw,smstav,smstot,    &
                sfcrunoff,udrunoff,ivgtyp,isltyp,isurban,isice,vegfra,        &
                albedo,albbck,znt,z0, tmn,xland,xice,emiss, embck,    &
                snowc,qsfc,rainbl,                              &
                mminlu,                                         &
                num_soil_layers,dtbl,dzs,itimestep,             &
                smois,tslb,snow,canwat,                         &
                chs, chs2, cqs2, cpm,rcp,SR,chklowq,lai,qz0,    &
                myj,frpcpn,                                     &
		sh2o,snowh,                                     & !h
                u_phy,v_phy,                                    & !I
                snoalb,shdmin,shdmax,shdavg,                    & !i
                snotime,                                        & !o
                acsnom,acsnow,                                  & !o
                snopcx,                                         & !o
                potevp,                                         & !o
                smcrel,                                         & !o
                xice_threshold,                                 &
                rdlai2d,usemonalb,                              &
                br,                                             & !?
                NOAHRES,opt_thcnd,                              &
                NLCAT,landusef,landusef2,                       & ! danli mosaic
                sf_surface_mosaic,mosaic_cat,mosaic_cat_index,  & ! danli mosaic 
                TSK_mosaic,QSFC_mosaic,                         & ! danli mosaic 
                TSLB_mosaic,SMOIS_mosaic,SH2O_mosaic,           & ! danli mosaic 
                CANWAT_mosaic,SNOW_mosaic,                      & ! danli mosaic
                SNOWH_mosaic,SNOWC_mosaic,                      & ! danli mosaic 
                ALBEDO_mosaic,ALBBCK_mosaic,                    & ! danli mosaic
                EMISS_mosaic, EMBCK_mosaic,                     & ! danli mosaic
                ZNT_mosaic, Z0_mosaic,                          & ! danli mosaic 
                HFX_mosaic,QFX_mosaic,                          & ! danli mosaic
                LH_mosaic, GRDFLX_mosaic, SNOTIME_mosaic,       & ! danli mosaic
                RS_mosaic, LAI_mosaic,                          & ! mosaic
                ua_phys,flx4,fvb,fbur,fgsn,                     &
                ids,ide, jds,jde, kds,kde,                      &
                ims,ime, jms,jme, kms,kme,                      &
                i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte,    &
                sf_urban_physics                                &
!Optional urban
                ,cmr_sfcdif,chr_sfcdif,cmc_sfcdif,chc_sfcdif    &
                ,cmgr_sfcdif,chgr_sfcdif                        &
                ,tr_urb2d,tb_urb2d,tg_urb2d,tc_urb2d,qc_urb2d,  & !H urban
                uc_urb2d,                                       & !H urban
                xxxr_urb2d,xxxb_urb2d,xxxg_urb2d,xxxc_urb2d,    & !H urban
                trl_urb3d,tbl_urb3d,tgl_urb3d,                  & !H urban
                sh_urb2d,lh_urb2d,g_urb2d,rn_urb2d,ts_urb2d,    & !H urban
                TR_URB2D_mosaic,TB_URB2D_mosaic,                & !H urban  danli mosaic
                TG_URB2D_mosaic,TC_URB2D_mosaic,                & !H urban  danli mosaic
                QC_URB2D_mosaic,UC_URB2D_mosaic,                & !H urban  danli mosaic                  
                TRL_URB3D_mosaic,TBL_URB3D_mosaic,              & !H urban  danli mosaic
                TGL_URB3D_mosaic,                               & !H urban  danli mosaic
                SH_URB2D_mosaic,LH_URB2D_mosaic,                & !H urban  danli mosaic
                G_URB2D_mosaic,RN_URB2D_mosaic,                 & !H urban  danli mosaic
                TS_URB2D_mosaic,                                & !H urban  danli mosaic
                TS_RUL2D_mosaic,                                & !H urban  danli mosaic                
                psim_urb2d,psih_urb2d,u10_urb2d,v10_urb2d,      & !O urban
                GZ1OZ0_urb2d, AKMS_URB2D,                       & !O urban
                th2_urb2d,q2_urb2d,ust_urb2d,                   & !O urban
                declin,coszen,hrang,                            & !I solar
                xlat_urb2d,                                     & !I urban
                num_roof_layers, num_wall_layers,               & !I urban
                num_road_layers, DZR, DZB, DZG,                 & !I urban
                CMCR_URB2D,TGR_URB2D,TGRL_URB3D,SMR_URB3D,      & !H urban
                julian,julyr,                                   & !H urban
                DRELR_URB2D,DRELB_URB2D,DRELG_URB2D,            & !H urban
                FLXHUMR_URB2D,FLXHUMB_URB2D,FLXHUMG_URB2D,      & !H urban
                FRC_URB2D, UTYPE_URB2D,                         & !I urban
                num_urban_ndm,                                  & !I multi-layer urban
                urban_map_zrd,                                  & !I multi-layer urban
                urban_map_zwd,                                  & !I multi-layer urban
                urban_map_gd,                                   & !I multi-layer urban
                urban_map_zd,                                   & !I multi-layer urban
                urban_map_zdf,                                  & !I multi-layer urban
                urban_map_bd,                                   & !I multi-layer urban
                urban_map_wd,                                   & !I multi-layer urban
                urban_map_gbd,                                  & !I multi-layer urban
                urban_map_fbd,                                  & !I multi-layer urban
                urban_map_zgrd,                                 & !I multi-layer urban
                num_urban_hi,                                   & !I multi-layer urban
                use_wudapt_lcz,                                 & !I wudapt
                slucm_distributed_drag,                         & !I SLUCM
                tsk_rural,                                      & !H multi-layer urban
                trb_urb4d,tw1_urb4d,tw2_urb4d,tgb_urb4d,        & !H multi-layer urban
                tlev_urb3d,qlev_urb3d,                          & !H multi-layer urban
                tw1lev_urb3d,tw2lev_urb3d,                      & !H multi-layer urban
                tglev_urb3d,tflev_urb3d,                        & !H multi-layer urban
                sf_ac_urb3d,lf_ac_urb3d,cm_ac_urb3d,            & !H multi-layer urban
                sfvent_urb3d,lfvent_urb3d,                      & !H multi-layer urban
                sfwin1_urb3d,sfwin2_urb3d,                      & !H multi-layer urban
                sfw1_urb3d,sfw2_urb3d,sfr_urb3d,sfg_urb3d,      & !H multi-layer urban
                 ep_pv_urb3d,t_pv_urb3d,                         & !GRZ
                trv_urb4d,qr_urb4d,qgr_urb3d,tgr_urb3d,         & !GRZ
                drain_urb4d,draingr_urb3d,sfrv_urb3d,           & !GRZ
                lfrv_urb3d,dgr_urb3d,dg_urb3d,lfr_urb3d,lfg_urb3d,& !GRZ
                lp_urb2d,hi_urb2d,lb_urb2d,hgt_urb2d,           & !H multi-layer urban
                mh_urb2d,stdh_urb2D,lf_urb2d,                   & !SLUCM
                lf_urb2d_s, z0_urb2d,                           & !SLUCM
                th_phy,rho,p_phy,ust,                           & !I multi-layer urban
                gmt,julday,xlong,xlat,                          & !I multi-layer urban
                a_u_bep,a_v_bep,a_t_bep,a_q_bep,                & !O multi-layer urban
                a_e_bep,b_u_bep,b_v_bep,                        & !O multi-layer urban
                b_t_bep,b_q_bep,b_e_bep,dlg_bep,                & !O multi-layer urban
                dl_u_bep,sf_bep,vl_bep                          & !O multi-layer urban
#ifdef WRF_HYDRO
                ,sfcheadrt,INFXSRT, soldrain                    & !hydro
#endif
                ,SDA_HFX, SDA_QFX, HFX_BOTH, QFX_BOTH, QNORM, fasdas    & ! fasdas
                ,RS,XLAIDYN,IRRIGATION_CHANNEL)
           ELSE
               CALL wrf_error_fatal('Lack arguments to call lsm_mosaic')
           ENDIF

	  ELSEIF (sf_surface_mosaic == 0) THEN
	                  
!
!  FASDAS
!
             IF( fasdas == 1 ) THEN
#ifdef WRF_GPU
               CALL wrf_error_fatal('surface_driver: fasdas not ported to the GPU')
#endif
               DO j=j_start(ij),j_end(ij)
               DO i=i_start(ij),i_end(ij)

!ckay2015 only do indirect nudging over land areas 
                     IF(XLAND(i,j) .GT. 1.5) then
                      SDA_QFX(I,J) = 0.0
                      SDA_HFX(I,J) = 0.0
                     END IF

! TWG2015 Removed lines that update fluxes to ensure this section only defines
! the output
                    QFXOLD(I,J)=QFX(I,J)
                    QFX_KAY = SDA_QFX(I,J)*RHO(I,1,J)*DZ8W(I,1,J)
                    QFX_KAY = QFX_KAY * QNORM(I,J)
                    QFX_BOTH(I,J)=QFX(I,J)+QFX_KAY

                    HFXOLD(I,J)=HFX(I,J)
                    HFX_KAY = SDA_HFX(I,J)*RHO(I,1,J)*CPM(I,J)*DZ8W(I,1,J)
                    HFX_BOTH(I,J)=HFX(I,J)+HFX_KAY

               ENDDO
               ENDDO
             END IF
!
!  END FASDAS
!
               if (pert_noah .and. multi_perturb == 1) then
#ifdef WRF_GPU
                 CALL wrf_error_fatal('surface_driver: pert_noah not ported to the GPU')
#endif
                 allocate (tslb_tmp(i_start(ij):i_end(ij), 1:num_soil_layers, j_start(ij):j_end(ij)))
                 allocate (smois_tmp(i_start(ij):i_end(ij), 1:num_soil_layers, j_start(ij):j_end(ij)))

                 call Add_multi_perturb_lsm_perturbations (perts_qvapor, perts_th, perts_smois, perts_tsoil, &
                   pert_noah_qv, pert_noah_t, pert_noah_smois, pert_noah_tslb, t_phy, qv_curr, tslb, smois, &
                   tslb_tmp, smois_tmp, num_soil_layers, i_start(ij), i_end(ij), j_start(ij), j_end(ij), ims, &
                   ime, jms, jme, kms, kme, kts, kte)
               end if

               CALL lsm(dz8w,qv_curr,p8w,t_phy,tsk,                 &
                hfx,qfx,lh,grdflx,qgh,gsw,swdown,swddir,swddif,     &
                glw,smstav,smstot,    &
                sfcrunoff,udrunoff,ivgtyp,isltyp,isurban,isice,vegfra,        &
                albedo,albbck,znt,z0, tmn,xland,xice,emiss, embck,    &
                snowc,qsfc,rainbl,                              &
                mminlu,                                         &
                num_soil_layers,dtbl,dzs,itimestep,             &
                smois,tslb,snow,canwat,                         &
                chs, chs2, cqs2, cpm,rcp,SR,chklowq,lai,qz0,    &
                myj,frpcpn,                                     &
		sh2o,snowh,                                     & !h
                u_phy,v_phy,                                    & !I
                snoalb,shdmin,shdmax,                           & !i
                snotime,                                        & !o
                acsnom,acsnow,                                  & !o
                snopcx,                                         & !o
                potevp,                                         & !o
                smcrel,                                         & !o
                xice_threshold,                                 &
                rdlai2d,usemonalb,                              &
                br,                                             & !?
                NOAHRES,opt_thcnd,                              &
                ua_phys,flx4,fvb,fbur,fgsn,                     &
                ids,ide, jds,jde, kds,kde,                      &
                ims,ime, jms,jme, kms,kme,                      &
                i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte,    &
                sf_urban_physics                                &
!Optional urban
                ,cmr_sfcdif,chr_sfcdif,cmc_sfcdif,chc_sfcdif    &
                ,cmgr_sfcdif,chgr_sfcdif                        &
                ,tr_urb2d,tb_urb2d,tg_urb2d,tc_urb2d,qc_urb2d,  & !H urban
                uc_urb2d,                                       & !H urban
                xxxr_urb2d,xxxb_urb2d,xxxg_urb2d,xxxc_urb2d,    & !H urban
                trl_urb3d,tbl_urb3d,tgl_urb3d,                  & !H urban
                sh_urb2d,lh_urb2d,g_urb2d,rn_urb2d,ts_urb2d,    & !H urban
                psim_urb2d,psih_urb2d,u10_urb2d,v10_urb2d,      & !O urban
                GZ1OZ0_urb2d, AKMS_URB2D,                       & !O urban
                th2_urb2d,q2_urb2d,ust_urb2d,                   & !O urban
                declin,coszen,hrang,                            & !I solar
                xlat_urb2d,                                     & !I urban
                num_roof_layers, num_wall_layers,               & !I urban
                num_road_layers, DZR, DZB, DZG,                 & !I urban
                CMCR_URB2D,TGR_URB2D,TGRL_URB3D,SMR_URB3D,      & !H urban
                DRELR_URB2D,DRELB_URB2D,DRELG_URB2D,            & !H urban
                FLXHUMR_URB2D,FLXHUMB_URB2D,FLXHUMG_URB2D,      & !H urban
                julian, julyr,                                  & !H urban
                FRC_URB2D, UTYPE_URB2D,                         & !I urban
                num_urban_ndm,                                  & !I multi-layer urban
                urban_map_zrd,                                  & !I multi-layer urban
                urban_map_zwd,                                  & !I multi-layer urban
                urban_map_gd,                                   & !I multi-layer urban
                urban_map_zd,                                   & !I multi-layer urban
                urban_map_zdf,                                  & !I multi-layer urban
                urban_map_bd,                                   & !I multi-layer urban
                urban_map_wd,                                   & !I multi-layer urban
                urban_map_gbd,                                  & !I multi-layer urban
                urban_map_fbd,                                  & !I multi-layer urban
                urban_map_zgrd,                                 & !I multi-layer urban
                num_urban_hi,                                   & !I multi-layer urban
                tsk_rural,                                      & !H multi-layer urban
                trb_urb4d,tw1_urb4d,tw2_urb4d,tgb_urb4d,        & !H multi-layer urban
                tlev_urb3d,qlev_urb3d,                          & !H multi-layer urban
                tw1lev_urb3d,tw2lev_urb3d,                      & !H multi-layer urban
                tglev_urb3d,tflev_urb3d,                        & !H multi-layer urban
                sf_ac_urb3d,lf_ac_urb3d,cm_ac_urb3d,            & !H multi-layer urban
                sfvent_urb3d,lfvent_urb3d,                      & !H multi-layer urban
                sfwin1_urb3d,sfwin2_urb3d,                      & !H multi-layer urban
                sfw1_urb3d,sfw2_urb3d,sfr_urb3d,sfg_urb3d,      & !H multi-layer urban
                ep_pv_urb3d,t_pv_urb3d,                         & !GRZ
                trv_urb4d,qr_urb4d,qgr_urb3d,tgr_urb3d,         & !GRZ
                drain_urb4d,draingr_urb3d,sfrv_urb3d,           & !GRZ
                lfrv_urb3d,dgr_urb3d,dg_urb3d,lfr_urb3d,lfg_urb3d,& !GRZ
                lp_urb2d,hi_urb2d,lb_urb2d,hgt_urb2d,           & !H multi-layer urban
                mh_urb2d,stdh_urb2D,lf_urb2d,                   & !SLUCM
                lf_urb2d_s, z0_urb2d,                           & !SLUCM
                th_phy,rho,p_phy,ust,                           & !I multi-layer urban
                gmt,julday,xlong,xlat,                          & !I multi-layer urban
                a_u_bep,a_v_bep,a_t_bep,a_q_bep,                & !O multi-layer urban
                a_e_bep,b_u_bep,b_v_bep,                        & !O multi-layer urban
                b_t_bep,b_q_bep,b_e_bep,dlg_bep,                & !O multi-layer urban
                dl_u_bep,sf_bep,vl_bep                          & !O multi-layer urban
#ifdef WRF_HYDRO
                ,sfcheadrt,INFXSRT, soldrain                    &
#endif
                ,SDA_HFX, SDA_QFX, HFX_BOTH, QFX_BOTH, QNORM, fasdas    &
                ,RS,XLAIDYN,IRRIGATION_CHANNEL)
         ENDIF

         if (pert_noah .and. multi_perturb == 1) then
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: pert_noah not ported to the GPU')
#endif
           call Remove_multi_perturb_lsm_perturbations (perts_qvapor, perts_th, perts_smois, perts_tsoil, &
               pert_noah_qv, pert_noah_t, pert_noah_smois, pert_noah_tslb, t_phy, qv_curr, tslb, smois, &
               tslb_tmp, smois_tmp, num_soil_layers, i_start(ij), i_end(ij), j_start(ij), j_end(ij), ims, &
               ime, jms, jme, kms, kme, kts, kte)
           deallocate (tslb_tmp)
           deallocate (smois_tmp)
         end if

         call seaice_noah( SEAICE_ALBEDO_OPT, SEAICE_ALBEDO_DEFAULT, SEAICE_THICKNESS_OPT, &
              &            SEAICE_THICKNESS_DEFAULT, SEAICE_SNOWDEPTH_OPT,             &
              &            SEAICE_SNOWDEPTH_MAX, SEAICE_SNOWDEPTH_MIN,                 &
              &            t_phy, qv_curr, p8w, dz8w, num_soil_layers, dt, frpcpn, sr, &
              &            glw, swdown, rainbl, snoalb, qgh, xice, xice_threshold,     &
              &            albsi, icedepth, snowsi,                                    &
              &            tslb, emiss, albedo, z0, tsk, snow, snowc, snowh,           &
              &            chs, chs2, cqs2,                                            &
              &            br, znt, lh, hfx, qfx, potevp, grdflx, qsfc, acsnow,        &
              &            acsnom, snopcx, sfcrunoff, noahres,                         &
              &            sf_urban_physics, b_t_bep, b_q_bep, rho,                    &
              &            ids,ide, jds,jde, kds,kde,                                  &
              &            ims,ime, jms,jme, kms,kme,                                  &
              &            i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte )

         IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            ! LSM Returns full land/ice values, no fractional values.
            ! We return to a fractional component here.  SFLX currently hard-wires
            ! emissivity over sea ice to 0.98, the same value as over open water, so
            ! the fractional consideration doesn't have any effect for emissivity.
            DO j=j_start(ij),j_end(ij)
               DO i=i_start(ij),i_end(ij)
                  IF ( ( XICE(I,J) .GE. XICE_THRESHOLD) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                     albedo(i,j) = ( albedo(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * 0.08  )
                     emiss(i,j) = ( emiss(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * 0.98  )
                  ENDIF
               ENDDO
            ENDDO

            IF ( isisfc ) THEN
               DO j=j_start(ij),j_end(ij)
                  DO i=i_start(ij),i_end(ij)
                     IF ( ( XICE(I,J) .GE. XICE_THRESHOLD) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                        !  Weighted average of fields between ice-cover values and open-water values.
                        flhc(i,j) = ( flhc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * flhc_sea(i,j) )
                        flqc(i,j) = ( flqc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * flqc_sea(i,j) )
                        cpm(i,j)  = ( cpm(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * cpm_sea(i,j)  )
                        cqs2(i,j) = ( cqs2(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * cqs2_sea(i,j) )
                        chs2(i,j) = ( chs2(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * chs2_sea(i,j) )
                        chs(i,j)  = ( chs(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * chs_sea(i,j)  )
                        qsfc(i,j) = ( qsfc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qsfc_sea(i,j) )
                        qgh(i,j)  = ( qgh(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qgh_sea(i,j)  )
                        qz0(i,j)  = ( qz0(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qz0_sea(i,j)  )
                                                            !  print *,'hfx =',hfx_sea(170,20)
                                                            !   print *,'XICE =',XICE(170,20)
                                                            !    print *,'QSFC =',QSFC(170,20)
                        hfx(i,j)  = ( hfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * hfx_sea(i,j)  )
                        qfx(i,j)  = ( qfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qfx_sea(i,j)  )
                        lh(i,j)   = ( lh(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * lh_sea(i,j)   )
!save old tsk_ice
                        tsk_save(i,j)  = tsk(i,j)
                        tsk(i,j)  = ( tsk(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * tsk_sea(i,j)  )
                     ENDIF
                  ENDDO
               ENDDO
            ELSE
               DO j = j_start(ij) , j_end(ij)
                  DO i = i_start(ij) , i_end(ij)
                     IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                        ! Compute TSK as the open-water and ice-cover average
                        tsk(i,j) = ( tsk(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * tsk_sea(i,j) )
                     ENDIF
                  ENDDO
               ENDDO
            ENDIF
         ENDIF
#ifdef WRF_GPU
           IF (.NOT. PRESENT(ACHFX) .OR. .NOT. PRESENT(ACLHF) .OR. .NOT. PRESENT(ACGRDFLX)) THEN
              CALL wrf_error_fatal('surface_driver: ACHFX ACLHF ACGRDFLX not present')
           END IF
! K-SD-8: SFCEVP SFCEXC ACHFX ACLHF ACGRDFLX (Template A)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_SURFACE_DRIVER)) default(none) &
!$acc& present(sfcevp, qfx, sfcexc, chs, achfx, aclhf, hfx, lh, acgrdflx, grdflx) &
!$acc& firstprivate(its, ite, jts, jte, dtbl, dt) &
!$acc& private(i, j)
           DO j=jts,jte
           DO i=its,ite
!              CHKLOWQ(I,J)= 1.0
               SFCEVP(I,J)= SFCEVP(I,J) + QFX(I,J)*DTBL
               SFCEXC(I,J)= CHS(I,J)
               ACHFX(I,J)=ACHFX(I,J) + HFX(I,J)*DT
               ACLHF(I,J)=ACLHF(I,J) + LH(I,J)*DT
               ACGRDFLX(I,J)=ACGRDFLX(I,J) + GRDFLX(I,J)*DT
           ENDDO
           ENDDO
#else
           DO j=j_start(ij),j_end(ij)
           DO i=i_start(ij),i_end(ij)
!              CHKLOWQ(I,J)= 1.0
               SFCEVP(I,J)= SFCEVP(I,J) + QFX(I,J)*DTBL
               SFCEXC(I,J)= CHS(I,J)
               IF(PRESENT(ACHFX))ACHFX(I,J)=ACHFX(I,J) + HFX(I,J)*DT
               IF(PRESENT(ACLHF))ACLHF(I,J)=ACLHF(I,J) + LH(I,J)*DT
               IF(PRESENT(ACGRDFLX))ACGRDFLX(I,J)=ACGRDFLX(I,J) + GRDFLX(I,J)*DT
           ENDDO
           ENDDO
#endif

          CALL SFCDIAGS(HFX,QFX,TSK,QSFC,CHS2,CQS2,T2,TH2,Q2,      &
                     PSFC,CP,R_d,RCP,CHS,t_phy,qv_curr,ua_phys,    &
                     ids,ide, jds,jde, kds,kde,                    &
                     ims,ime, jms,jme, kms,kme,                    &
             i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte    )
!urban
     IF(SF_URBAN_PHYSICS.eq.1) THEN
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: sf_urban_physics not ported to the GPU')
#endif
       DO j=j_start(ij),j_end(ij)                             !urban
         DO i=i_start(ij),i_end(ij)                           !urban
           IF(IVGTYP(I,J) == ISURBAN   .or. IVGTYP(I,J) == LCZ_1 .or. IVGTYP(I,J) == LCZ_2 .or. &
             IVGTYP(I,J) == LCZ_3      .or. IVGTYP(I,J) == LCZ_4 .or. IVGTYP(I,J) == LCZ_5 .or. &
             IVGTYP(I,J) == LCZ_6      .or. IVGTYP(I,J) == LCZ_7 .or. IVGTYP(I,J) == LCZ_8 .or. &
             IVGTYP(I,J) == LCZ_9      .or. IVGTYP(I,J) == LCZ_10 .or. IVGTYP(I,J) == LCZ_11 )THEN
             U10(I,J)  = U10_URB2D(I,J)                       !urban
             V10(I,J)  = V10_URB2D(I,J)                       !urban
             PSIM(I,J) = PSIM_URB2D(I,J)                      !urban
             PSIH(I,J) = PSIH_URB2D(I,J)                      !urban
             GZ1OZ0(I,J) = GZ1OZ0_URB2D(I,J)                  !urban
!m             AKHS(I,J) = AKHS_URB2D(I,J)                    !urban
             AKHS(I,J) = CHS(I,J)                             !urban
             AKMS(I,J) = AKMS_URB2D(I,J)                      !urban
           END IF                                             !urban
         ENDDO                                                !urban
       ENDDO                                                  !urban
     ENDIF
! urban BEP
     IF((SF_URBAN_PHYSICS.eq.2).OR.(SF_URBAN_PHYSICS.eq.3)) THEN
       DO j=j_start(ij),j_end(ij)                             !urban
         DO i=i_start(ij),i_end(ij)                           !urban
            IF( IVGTYP(I,J) == ISURBAN    .or. IVGTYP(I,J) == LCZ_1 .or. IVGTYP(I,J) == LCZ_2 .or. &
             IVGTYP(I,J) == LCZ_3      .or. IVGTYP(I,J) == LCZ_4 .or. IVGTYP(I,J) == LCZ_5 .or. &
             IVGTYP(I,J) == LCZ_6      .or. IVGTYP(I,J) == LCZ_7 .or. IVGTYP(I,J) == LCZ_8 .or. &
             IVGTYP(I,J) == LCZ_9      .or. IVGTYP(I,J) == LCZ_10 .or. IVGTYP(I,J) == LCZ_11 )THEN
            T2(I,J)   = TH_PHY(i,1,j)/(rp_pow((1.E5/PSFC(I,J)), RCP)) !urban
            TH2(I,J) = TH_PHY(i,1,j) !urban
            Q2(I,J)   = qv_curr(i,1,j)  !urban
            U10(I,J)  = U_phy(I,1,J)                       !urban
            V10(I,J)  = V_phy(I,1,J)                       !urban
           END IF                                             !urban
         ENDDO                                                !urban
       ENDDO                                                  !urban
     ENDIF

!------------------------------------------------------------------

       ELSE
         CALL wrf_error_fatal('Lacking arguments for LSM in surface driver')
       ENDIF

     CASE (NOAHMPSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: NOAHMPSCHEME not ported to the GPU')
#endif
       IF (PRESENT(qv_curr)    .AND.  PRESENT(rainbl)        .AND.    &
!          PRESENT(emiss)      .AND.  PRESENT(t2)            .AND.    &
!          PRESENT(declin) .AND.  PRESENT(coszen)    .AND.    &
!          PRESENT(hrang)  .AND. PRESENT( xlat_urb2d)    .AND.    &
!          PRESENT(dzr)       .AND.    &
!          PRESENT( dzb)            .AND. PRESENT(dzg)       .AND.    &
!          PRESENT(tr_urb2d) .AND. PRESENT(tb_urb2d)         .AND.    &
!          PRESENT(tg_urb2d) .AND. PRESENT(tc_urb2d) .AND.            &
!          PRESENT(qc_urb2d) .AND. PRESENT(uc_urb2d) .AND.            &
!          PRESENT(xxxr_urb2d) .AND. PRESENT(xxxb_urb2d) .AND.        &
!          PRESENT(xxxg_urb2d) .AND.                                  &
!          PRESENT(xxxc_urb2d) .AND. PRESENT(trl_urb3d) .AND.         &
!          PRESENT(tbl_urb3d)   .AND. PRESENT(tgl_urb3d)  .AND.       &
!          PRESENT(sh_urb2d) .AND. PRESENT(lh_urb2d)  .AND.           &
!          PRESENT(g_urb2d)   .AND. PRESENT(rn_urb2d) .AND.           &
!          PRESENT(ts_urb2d)                          .AND.           &
!          PRESENT(frc_urb2d) .AND. PRESENT(utype_urb2d)   .AND.      &
#if (EM_CORE==1)
           PRESENT(smcwtdxy)       .AND.                              &
           PRESENT(rechxy)         .AND.                              &   
           PRESENT(deeprechxy)     .AND.                              &
           PRESENT(fdepthxy)       .AND.                              &
           PRESENT(areaxy)         .AND.                              &   
           PRESENT(rivercondxy)    .AND.                              &
           PRESENT(riverbedxy)     .AND.                              & 
           PRESENT(eqzwt)          .AND.                              &    
           PRESENT(pexpxy)         .AND.                              &   
           PRESENT(qrfxy)          .AND.                              &    
           PRESENT(qspringxy)      .AND.                              &
           PRESENT(qslatxy)        .AND.                              &  
           PRESENT(qrfsxy)         .AND.                              &   
           PRESENT(qspringsxy)     .AND.                              & 
           PRESENT(smoiseq)        .AND.                              &  
           PRESENT(wtddt)          .AND.                              &    
           PRESENT(stepwtd)        .AND.                              &
#endif
                                                      .TRUE. ) THEN
!------------------------------------------------------------------


         IF ( FRACTIONAL_SEAICE == 1) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            ! The fields passed to LSM need to represent the full ice values, not
            ! the fractional values.  Convert ALBEDO and EMISS from the blended value 
            ! to a value representing only the sea-ice portion.   Albedo over open 
            ! water is taken to be 0.08. Emissivity over open water is taken to be 0.98
            DO j = j_start(ij) , j_end(ij)
               DO i = i_start(ij) , i_end(ij)
                  IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1 ) ) THEN
                     ALBEDO(I,J) = (ALBEDO(I,J)-(1.-XICE(I,J))*0.08)/XICE(I,J)
                     EMISS(I,J) = (EMISS(I,J)-(1.-XICE(I,J))*0.98)/XICE(I,J)
                  ENDIF
               ENDDO
            ENDDO

            IF ( isisfc ) THEN
               ! Use surface layer routine values from the ice portion of grid point
            ELSE
               !
               ! We don't have surface layer routine values at this time, so
               ! just use what we have.  Use ice component of TSK
               !
               CALL get_local_ice_tsk( ims, ime, jms, jme,                   &
                                       i_start(ij), i_end(ij),               &
                                       j_start(ij), j_end(ij),               &
                                       itimestep, .false., tice2tsk_if2cold, &
                                       XICE, XICE_THRESHOLD,                 &
                                       SST, TSK, TSK_SEA, TSK_LOCAL )

               DO j = j_start(ij) , j_end(ij)
                  DO i = i_start(ij) , i_end(ij)
                     TSK(i,j) = TSK_LOCAL(i,j)
                  ENDDO
               ENDDO
            ENDIF
         ENDIF

!for NoahMP irrigation scheme
         LLANDUSE = MMINLU
!added for WRF_HYDRO
#ifdef WRF_HYDRO
         if(HYDRO_dt .ge. 0) HYDRO_dt = dtbl
#endif
         CALL wrf_debug(100,'in NOAHMP DRV')
         CALL noahmplsm(ITIMESTEP,       YR, JULIAN_IN,   COSZEN, XLAT,XLONG, &
	           DZ8W,     DTBL,      DZS,     NUM_SOIL_LAYERS,         DX, &
		 IVGTYP,   ISLTYP,   VEGFRA,   SHDMAX,       TMN,             &
		  XLAND,     XICE,     XICE_THRESHOLD,   CROPCAT,             &
               PLANTING,  HARVEST,SEASON_GDD,                               &
                  IDVEG, IOPT_CRS, IOPT_BTR, IOPT_RUN,  IOPT_SFC,   IOPT_FRZ, &
	       IOPT_INF, IOPT_RAD, IOPT_ALB, IOPT_SNF, IOPT_TBOT,   IOPT_STC, &
	       IOPT_GLA, IOPT_RSF, IOPT_SOIL,IOPT_PEDO,IOPT_CROP,   IOPT_IRR, &
              IOPT_IRRM, IOPT_INFDV, IOPT_TDRN, soiltstep,                    &
                IZ0TLND, SF_URBAN_PHYSICS,                                    &
	       SOILCOMP,  SOILCL1,  SOILCL2,  SOILCL3,   SOILCL4,             &
		  T_PHY,  QV_CURR,    U_PHY,    V_PHY,    SWDOWN,    SWDDIR,  &
                SWDDIF,     GLW,                                              &
		    P8W,   RAINBL,       SR,                                  &
		IRFRACT,  SIFRACT,  MIFRACT,  FIFRACT,                        &
                    TSK,      HFX,      QFX,       LH,    GRDFLX,     SMSTAV, &
		 SMSTOT,SFCRUNOFF, UDRUNOFF,   ALBEDO,     SNOWC,      SMOIS, &
		   SH2O,     TSLB,     SNOW,    SNOWH,    CANWAT,     ACSNOM, &
		 ACSNOW,    EMISS,     QSFC,                                  &
 		     Z0,      ZNT,                                            & ! IN/OUT LSM eqv
                IRNUMSI,  IRNUMMI,  IRNUMFI,  IRWATSI,   IRWATMI,    IRWATFI, & ! IN/OUT Noah MP only
                IRELOSS,  IRSIVOL,  IRMIVOL,  IRFIVOL,   IRRSPLH,   LLANDUSE, &
		ISNOWXY,     TVXY,     TGXY, CANICEXY,  CANLIQXY,      EAHXY, &
		  TAHXY,     CMXY,     CHXY,   FWETXY,  SNEQVOXY,   ALBOLDXY, &
		QSNOWXY, QRAINXY, WSLAKEXY, ZWTXY, WAXY,    WTXY,     TSNOXY, &
		ZSNSOXY,  SNICEXY,  SNLIQXY, LFMASSXY,  RTMASSXY,   STMASSXY, &
		 WOODXY, STBLCPXY, FASTCPXY,      LAI,    XSAIXY,    TAUSSXY, &
	        SMOISEQ, SMCWTDXY,DEEPRECHXY,  RECHXY,   GRAINXY,      GDDXY,PGSXY, & ! IN/OUT Noah MP only
               GECROS_STATE,                                                  & ! IN/OUT gecros model
                QTDRAIN,   TD_FRACTION,                                       & ! IN/OUT tile drainage
	         T2MVXY,   T2MBXY,   Q2MVXY,   Q2MBXY,                        &
                 TRADXY,    NEEXY,    GPPXY,    NPPXY,    FVEGXY,    RUNSFXY, &
	        RUNSBXY,   ECANXY,   EDIRXY,  ETRANXY,     FSAXY,     FIRAXY, &
                 APARXY,    PSNXY,    SAVXY,    SAGXY,   RSSUNXY,    RSSHAXY, &
                 BGAPXY,   WGAPXY,    TGVXY,    TGBXY,     CHVXY,      CHBXY, &
		  SHGXY,    SHCXY,    SHBXY,    EVGXY,     EVBXY,      GHVXY, &
		  GHBXY,    IRGXY,    IRCXY,    IRBXY,      TRXY,      EVCXY, &
	       CHLEAFXY,   CHUCXY,   CHV2XY,   CHB2XY,    RS,                 &
               qintsxy   ,qintrxy   ,qdripsxy   ,&
               qdriprxy  ,qthrosxy  ,qthrorxy   ,&
               qsnsubxy  ,qsnfroxy  ,qsubcxy    ,&
               qfrocxy   ,qevacxy   ,qdewcxy    ,qfrzcxy   ,qmeltcxy   ,&
               qsnbotxy  ,qmeltxy   ,pondingxy ,PAHXY      ,PAHGXY, PAHVXY, PAHBXY,&
               fpicexy,RAINLSM,SNOWLSM,forctlsm,forcqlsm,forcplsm,forczlsm,forcwlsm,&
               acc_ssoil, acc_qinsur, acc_qseva, acc_etrani, eflxbxy, soilenergy, snowenergy, canhsxy,&
               ACC_DWATERXY, ACC_PRCPXY, ACC_ECANXY, ACC_ETRANXY, ACC_EDIRXY, &
#ifdef WRF_HYDRO
                 sfcheadrt,INFXSRT,soldrain,qtiledrain,ZWATBLE2D,             &    !O
#endif
                ids,ide, jds,jde, kds,kde,                      &
                ims,ime, jms,jme, kms,kme,                      &
                i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte,        &
! variables below are optional
                MP_RAINC =  RAINCV, MP_RAINNC =    RAINNCV, MP_SHCV = RAINSHV,&
		MP_SNOW  = SNOWNCV, MP_GRAUP  = GRAUPELNCV, MP_HAIL = HAILNCV )

         IF(SF_URBAN_PHYSICS > 0 ) THEN  !urban
         
	   call noahmp_urban (sf_urban_physics,     NUM_SOIL_LAYERS,     IVGTYP,ITIMESTEP,  & ! IN : Model configuration 
                               DTBL,         COSZEN,     XLAT_URB2D,                        & ! IN : Time/Space-related
                              T_PHY,        QV_CURR,          U_PHY,      V_PHY,   SWDOWN,  & ! IN : Forcing
                             SWDDIR,         SWDDIF,                                        &
		                GLW,            P8W,         RAINBL,       DZ8W,      ZNT,  & ! IN : Forcing
                                TSK,            HFX,            QFX,         LH,   GRDFLX,  & ! IN/OUT : LSM 
		             ALBEDO,          EMISS,           QSFC,                        & ! IN/OUT : LSM 
                            ids,ide,        jds,jde,        kds,kde,                        &
                            ims,ime,        jms,jme,        kms,kme,                        &
              i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte,                        &
                         cmr_sfcdif,     chr_sfcdif,     cmc_sfcdif,                        &
	                 chc_sfcdif,    cmgr_sfcdif,    chgr_sfcdif,                        &
                           tr_urb2d,       tb_urb2d,       tg_urb2d,                        & !H urban
	                   tc_urb2d,       qc_urb2d,       uc_urb2d,                        & !H urban
                         xxxr_urb2d,     xxxb_urb2d,     xxxg_urb2d, xxxc_urb2d,            & !H urban
                          trl_urb3d,      tbl_urb3d,      tgl_urb3d,                        & !H urban
                           sh_urb2d,       lh_urb2d,        g_urb2d,   rn_urb2d,  ts_urb2d, & !H urban
                         psim_urb2d,     psih_urb2d,      u10_urb2d,  v10_urb2d,            & !O urban
                       GZ1OZ0_urb2d,     AKMS_URB2D,                                        & !O urban
                          th2_urb2d,       q2_urb2d,      ust_urb2d,                        & !O urban
                             declin,          hrang,                                        & !I urban
                    num_roof_layers,num_wall_layers,num_road_layers,                        & !I urban
                                dzr,            dzb,            dzg,                        & !I urban
                         cmcr_urb2d,      tgr_urb2d,     tgrl_urb3d,  smr_urb3d,            & !H urban
                        drelr_urb2d,    drelb_urb2d,    drelg_urb2d,                        & !H urban
                      flxhumr_urb2d,  flxhumb_urb2d,  flxhumg_urb2d,                        & !H urban
                             julian,          julyr,                                        & !H urban
                          frc_urb2d,    utype_urb2d,                                        & !I urban
                                chs,           chs2,           cqs2,                        & !H
                      num_urban_ndm,  urban_map_zrd,  urban_map_zwd, urban_map_gd,          & !I multi-layer urban
                       urban_map_zd,  urban_map_zdf,   urban_map_bd, urban_map_wd,          & !I multi-layer urban
                      urban_map_gbd,  urban_map_fbd, urban_map_zgrd,                        & !I multi-layer urban
                       num_urban_hi,                                                        & !I multi-layer urban
                          trb_urb4d,      tw1_urb4d,      tw2_urb4d,  tgb_urb4d,            & !H multi-layer urban
                         tlev_urb3d,     qlev_urb3d,                                        & !H multi-layer urban
                       tw1lev_urb3d,   tw2lev_urb3d,                                        & !H multi-layer urban
                        tglev_urb3d,    tflev_urb3d,                                        & !H multi-layer urban
                        sf_ac_urb3d,    lf_ac_urb3d,    cm_ac_urb3d,                        & !H multi-layer urban
                       sfvent_urb3d,   lfvent_urb3d,                                        & !H multi-layer urban
                       sfwin1_urb3d,   sfwin2_urb3d,                                        & !H multi-layer urban
                         sfw1_urb3d,     sfw2_urb3d,      sfr_urb3d,  sfg_urb3d,            & !H multi-layer urban
                        ep_pv_urb3d,     t_pv_urb3d,                                        & !GRZ
                          trv_urb4d,       qr_urb4d,      qgr_urb3d,  tgr_urb3d,            & !GRZ
                        drain_urb4d,  draingr_urb3d,     sfrv_urb3d, lfrv_urb3d,            & !GRZ
                          dgr_urb3d,       dg_urb3d,      lfr_urb3d,  lfg_urb3d,            & !GRZ
                           lp_urb2d,       hi_urb2d,       lb_urb2d,  hgt_urb2d,            & !H multi-layer urban
                           mh_urb2d,     stdh_urb2d,       lf_urb2d,                        & !SLUCM
                         lf_urb2d_s,       z0_urb2d,         vegfra,                        & !SLUCM
                             th_phy,            rho,          p_phy,        ust,            & !I multi-layer urban
                                gmt,         julday,          xlong,       xlat,            & !I multi-layer urban
                            a_u_bep,        a_v_bep,        a_t_bep,    a_q_bep,            & !O multi-layer urban
                            a_e_bep,        b_u_bep,        b_v_bep,                        & !O multi-layer urban
                            b_t_bep,        b_q_bep,        b_e_bep,    dlg_bep,            & !O multi-layer urban
                           dl_u_bep,         sf_bep,         vl_bep)                          !O multi-layer urban
	 
	 ENDIF 

  IF ( iopt_run .EQ. 5 ) THEN
     IF ( rp_mod(itimestep,STEPWTD) .EQ. 0 ) THEN ! STEPWTD always and only non-zero for iopt_run == 5
           CALL wrf_debug( 100, 'calling WTABLE' )

!gmm update wtable from lateral flow and shed water to rivers

           CALL WTABLE_mmf_noahmp(num_soil_layers,xland,xice, xice_threshold, isice,        &
                                  isltyp,smoiseq,dzs,wtddt,                                 &
                                  fdepthxy,areaxy,ht,isurban,ivgtyp,                         &
                                  rivercondxy,riverbedxy,eqzwt,pexpxy,                      &
                                  smois,sh2o,smcwtdxy,zwtxy,qlatxy,qrfxy,deeprechxy,qspringxy,     &
                                  qslatxy,qrfsxy,qspringsxy,rechxy,                        &
                                  ids,ide, jds,jde, kds,kde,                             &
                                  ims,ime, jms,jme, kms,kme,                             &
                                  i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte )

     END IF
  END IF

         call seaice_noah( SEAICE_ALBEDO_OPT, SEAICE_ALBEDO_DEFAULT, SEAICE_THICKNESS_OPT, &
              &            SEAICE_THICKNESS_DEFAULT, SEAICE_SNOWDEPTH_OPT,             &
              &            SEAICE_SNOWDEPTH_MAX, SEAICE_SNOWDEPTH_MIN,                 &
              &            t_phy, qv_curr, p8w, dz8w, num_soil_layers, dt, frpcpn, sr, &
              &            glw, swdown, rainbl, snoalb, qgh, xice, xice_threshold,     &
              &            albsi, icedepth, snowsi,                                    &
              &            tslb, emiss, albedo, z0, tsk, snow, snowc, snowh,           &
              &            chs, chs2, cqs2,                                            &
              &            br, znt, lh, hfx, qfx, potevp, grdflx, qsfc, acsnow,        &
              &            acsnom, snopcx, sfcrunoff, noahres,                         &
              &            sf_urban_physics, b_t_bep, b_q_bep, rho,                    &
              &            ids,ide, jds,jde, kds,kde,                                  &
              &            ims,ime, jms,jme, kms,kme,                                  &
              &            i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte )

         IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            ! LSM Returns full land/ice values, no fractional values.
            ! We return to a fractional component here.  SFLX currently hard-wires
            ! emissivity over sea ice to 0.98, the same value as over open water, so
            ! the fractional consideration doesn't have any effect for emissivity.
            DO j=j_start(ij),j_end(ij)
               DO i=i_start(ij),i_end(ij)
                  IF ( ( XICE(I,J) .GE. XICE_THRESHOLD) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                     albedo(i,j) = ( albedo(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * 0.08  )
                     emiss(i,j) = ( emiss(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * 0.98  )
                  ENDIF
               ENDDO
            ENDDO

            IF ( isisfc ) THEN
               DO j=j_start(ij),j_end(ij)
                  DO i=i_start(ij),i_end(ij)
                     IF ( ( XICE(I,J) .GE. XICE_THRESHOLD) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                        !  Weighted average of fields between ice-cover values and open-water values.
                        flhc(i,j) = ( flhc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * flhc_sea(i,j) )
                        flqc(i,j) = ( flqc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * flqc_sea(i,j) )
                        cpm(i,j)  = ( cpm(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * cpm_sea(i,j)  )
                        cqs2(i,j) = ( cqs2(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * cqs2_sea(i,j) )
                        chs2(i,j) = ( chs2(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * chs2_sea(i,j) )
                        chs(i,j)  = ( chs(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * chs_sea(i,j)  )
                        qsfc(i,j) = ( qsfc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qsfc_sea(i,j) )
                        qgh(i,j)  = ( qgh(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qgh_sea(i,j)  )
                        qz0(i,j)  = ( qz0(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qz0_sea(i,j)  )
                        hfx(i,j)  = ( hfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * hfx_sea(i,j)  )
                        qfx(i,j)  = ( qfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qfx_sea(i,j)  )
                        lh(i,j)   = ( lh(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * lh_sea(i,j)   )
!save old tsk_ice
                        tsk_save(i,j)  = tsk(i,j)
                        tsk(i,j)  = ( tsk(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * tsk_sea(i,j)  )
                     ENDIF
                  ENDDO
               ENDDO
            ELSE
               DO j = j_start(ij) , j_end(ij)
                  DO i = i_start(ij) , i_end(ij)
                     IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                        ! Compute TSK as the open-water and ice-cover average
                        tsk(i,j) = ( tsk(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * tsk_sea(i,j) )
                     ENDIF
                  ENDDO
               ENDDO
            ENDIF
         ENDIF
           DO j=j_start(ij),j_end(ij)
           DO i=i_start(ij),i_end(ij)
              CHKLOWQ(I,J)= 1.0
               SFCEVP(I,J)= SFCEVP(I,J) + QFX(I,J)*DTBL
               SFCEXC(I,J)= CHS(I,J)
               IF(PRESENT(ACHFX))ACHFX(I,J)=ACHFX(I,J) + HFX(I,J)*DT
               IF(PRESENT(ACLHF))ACLHF(I,J)=ACLHF(I,J) + LH(I,J)*DT
               IF(PRESENT(ACGRDFLX))ACGRDFLX(I,J)=ACGRDFLX(I,J) + GRDFLX(I,J)*DT

               ! Check that SFCDIAGS can declare these as intent(out)
               T2(I,J)  = -1.E36
               TH2(I,J) = -1.E36
               Q2(I,J)  = -1.E36
           ENDDO
           ENDDO
           
!jref: sfc diagnostics
           DO j=j_start(ij),j_end(ij)
           DO i=i_start(ij),i_end(ij)
!             IF (IVGTYP(I,J) == ISWATER .OR. XICE(I,J) .GE. XICE_THRESHOLD) THEN
              IF (IVGTYP(I,J) == ISWATER .OR. (IVGTYP(I,J) == ISICE .AND. XICE(I,J) .GE. XICE_THRESHOLD)) THEN
                 IF(CQS2(I,J).lt.1.E-5) then
                   Q2(I,J)=QSFC(I,J)
                 ELSE
                   Q2(I,J) = QSFC(I,J) - QFX(I,J)/(PSFC(I,J)/(R_d * TSK(I,J))*CQS2(I,J))
                 ENDIF
                 IF(CHS2(I,J).lt.1.E-5) then
                   T2(I,J) = TSK(I,J) 
                 ELSE
                   T2(I,J) = TSK(I,J) - HFX(I,J)/(PSFC(I,J)/(R_d * TSK(I,J))*CP*CHS2(I,J))
                 ENDIF
                   TH2(I,J) = T2(I,J)*rp_pow((1.E5/PSFC(I,J)), RCP)
!             ELSEIF (IVGTYP(I,J) == ISURBAN .OR. IVGTYP(I,J) == ISICE .OR. FVEGXY(I,J) == 0.0 ) THEN
              ELSEIF( IVGTYP(I,J) == ISURBAN    .or. IVGTYP(I,J) == LCZ_1 .or. IVGTYP(I,J) == LCZ_2 .or. &
                      IVGTYP(I,J) == LCZ_3      .or. IVGTYP(I,J) == LCZ_4 .or. IVGTYP(I,J) == LCZ_5 .or. &
                      IVGTYP(I,J) == LCZ_6      .or. IVGTYP(I,J) == LCZ_7 .or. IVGTYP(I,J) == LCZ_8 .or. &
                      IVGTYP(I,J) == LCZ_9      .or. IVGTYP(I,J) == LCZ_10 .or. IVGTYP(I,J) == LCZ_11 .or. &
                     (IVGTYP(I,J) == ISICE .AND. XICE(I,J) .LT. XICE_THRESHOLD)) THEN

                   Q2(I,J)  = Q2MBXY(I,J)
                   T2(I,J)  = T2MBXY(I,J)
                   TH2(I,J) = T2(i,j)*rp_pow((1.E5/PSFC(i,j)), RCP)
              ELSE
                 T2(I,J)  = FVEGXY(I,J)*T2MVXY(I,J) + (1.-FVEGXY(I,J))*T2MBXY(I,J)
                 Q2(I,J)  = FVEGXY(I,J)*Q2MVXY(I,J) + (1.-FVEGXY(I,J))*Q2MBXY(I,J)
                 TH2(I,J) = T2(i,j)*rp_pow((1.E5/PSFC(i,j)), RCP)
              ENDIF
           ENDDO
           ENDDO
           
!          CALL SFCDIAGS(HFX,QFX,TSK,QSFC,CHS2,CQS2,T2,TH2,Q2,      &
!                     PSFC,CP,R_d,RCP,CHS,t_phy,qv_curr,ua_phys,    &
!                     ids,ide, jds,jde, kds,kde,                    &
!                     ims,ime, jms,jme, kms,kme,                    &
!             i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte    )

!jref: sfc diagnostics end

         IF(SF_URBAN_PHYSICS.eq.1) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: sf_urban_physics not ported to the GPU')
#endif
           DO j=j_start(ij),j_end(ij)                             !urban
             DO i=i_start(ij),i_end(ij)                           !urban
               IF( IVGTYP(I,J) == ISURBAN    .or. IVGTYP(I,J) == LCZ_1 .or. IVGTYP(I,J) == LCZ_2 .or. &
                   IVGTYP(I,J) == LCZ_3      .or. IVGTYP(I,J) == LCZ_4 .or. IVGTYP(I,J) == LCZ_5 .or. &
                   IVGTYP(I,J) == LCZ_6      .or. IVGTYP(I,J) == LCZ_7 .or. IVGTYP(I,J) == LCZ_8 .or. &
                   IVGTYP(I,J) == LCZ_9      .or. IVGTYP(I,J) == LCZ_10 .or. IVGTYP(I,J) == LCZ_11 )THEN
                 Q2(I,J)  = (FVEGXY(I,J)*Q2MVXY(I,J) + (1.-FVEGXY(I,J))*Q2MBXY(I,J))*(1.-FRC_URB2D(I,J)) +   &
                             Q2_URB2D(I,J)*FRC_URB2D(I,J)
                 T2(I,J)  = (FVEGXY(I,J)*T2MVXY(I,J) + (1.-FVEGXY(I,J))*T2MBXY(I,J))*(1.-FRC_URB2D(I,J)) +   &
                             (TH2_URB2D(i,j)/(rp_pow((1.E5/PSFC(i,j)), RCP)))*FRC_URB2D(I,J)
                 TH2(I,J) = T2(i,j)*rp_pow((1.E5/PSFC(i,j)), RCP)
                 U10(I,J)  = U10_URB2D(I,J)                       !urban
                 V10(I,J)  = V10_URB2D(I,J)                       !urban
                 PSIM(I,J) = PSIM_URB2D(I,J)                      !urban
                 PSIH(I,J) = PSIH_URB2D(I,J)                      !urban
                 GZ1OZ0(I,J) = GZ1OZ0_URB2D(I,J)                  !urban
                 AKHS(I,J) = CHS(I,J)                             !urban
                 AKMS(I,J) = AKMS_URB2D(I,J)                      !urban
               END IF                                             !urban
             ENDDO                                                !urban
           ENDDO                                                  !urban
         ENDIF

         IF((SF_URBAN_PHYSICS.eq.2).OR.(SF_URBAN_PHYSICS.eq.3)) THEN
           DO j=j_start(ij),j_end(ij)                             !urban
             DO i=i_start(ij),i_end(ij)                           !urban
                IF( IVGTYP(I,J) == ISURBAN    .or. IVGTYP(I,J) == LCZ_1 .or. IVGTYP(I,J) == LCZ_2 .or. &
                    IVGTYP(I,J) == LCZ_3      .or. IVGTYP(I,J) == LCZ_4 .or. IVGTYP(I,J) == LCZ_5 .or. &
                    IVGTYP(I,J) == LCZ_6      .or. IVGTYP(I,J) == LCZ_7 .or. IVGTYP(I,J) == LCZ_8 .or. &
                    IVGTYP(I,J) == LCZ_9      .or. IVGTYP(I,J) == LCZ_10 .or. IVGTYP(I,J) == LCZ_11 )THEN
                T2(I,J)   = TH_PHY(i,1,j)/(rp_pow((1.E5/PSFC(I,J)), RCP)) !urban
                TH2(I,J) = TH_PHY(i,1,j) !urban
                Q2(I,J)   = qv_curr(i,1,j)  !urban
                U10(I,J)  = U_phy(I,1,J)                       !urban
                V10(I,J)  = V_phy(I,1,J)                       !urban
               END IF                                             !urban
             ENDDO                                                !urban
           ENDDO                                                  !urban
         ENDIF

! added RA population for WRF/Noah-CMAQ RS Consistency
! following Garland et al. (1977) and Nemitz et al., 2009
         IF ( PRESENT(RA) ) THEN
         DO j=j_start(ij),j_end(ij)
         DO i=i_start(ij),i_end(ij)
            RA(I,J) = WSPD(I,J)/UST(I,J)**2
         ENDDO
         ENDDO
         END IF
!------------------------------------------------------------------

       ELSE
         CALL wrf_error_fatal('Lacking arguments for NOAHMPLSM in surface driver')
       ENDIF

     CASE (RUCLSMSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: RUCLSMSCHEME not ported to the GPU')
#endif
       IF (PRESENT(qv_curr)    .AND.  PRESENT(qc_curr) .AND.    &
!           PRESENT(emiss)      .AND.  PRESENT(t2)      .AND.    &
           PRESENT(qsg)        .AND.  PRESENT(qvg)     .AND.    &
           PRESENT(qcg)        .AND.  PRESENT(soilt1)  .AND.    &
           PRESENT(tsnav)      .AND.  PRESENT(smfr3d)  .AND.    &
           PRESENT(keepfr3dflag) .AND. PRESENT(rainbl) .AND.    &
           PRESENT(dew)                                 .AND.   &
                                                      .TRUE. ) THEN

           IF( PRESENT(sr) ) THEN
               frpcpn=.true.
           ELSE
               SR = 1.
           ENDIF
           CALL wrf_debug(100,'in RUC LSM')
           DO j = j_start(ij) , j_end(ij)
              DO i = i_start(ij) , i_end(ij)
                 IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1. ) ) THEN
                    ALBBCK(I,J) = SEAICE_ALBEDO_DEFAULT
                 ENDIF
              ENDDO
           ENDDO
           IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
             CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
              ! The fields passed to LSMRUC need to represent the full ice values, not
              ! the fractional values.  Convert ALBEDO and EMISS from the blended value 
              ! to a value representing only the sea-ice portion.   Albedo over open 
              ! water is taken to be 0.08. Emissivity over open water is taken to be 0.98
              DO j = j_start(ij) , j_end(ij)
                 DO i = i_start(ij) , i_end(ij)
                    IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1 ) ) THEN
                       ALBEDO(I,J) = (ALBEDO(I,J) - (1.-XICE(I,J))*0.08) / XICE(I,J)
                       EMISS(I,J)  = (EMISS(I,J)  - (1.-XICE(I,J))*0.98) / XICE(I,J)
! also set skin temperature to saved sea-ice portion only
                       TSK(I,J) = TSK_SAVE(I,J)
                    ENDIF
                 ENDDO
              ENDDO

              IF ( isisfc ) THEN
                 !
                 ! use surface layer routine values from the ice portion of grid point
                 !
              ELSE
                 !
                 ! don't have srfc layer routine values at this time, so just use what you have
                 ! use ice component of TSK
                 !
                 CALL get_local_ice_tsk( ims, ime, jms, jme,                   &
                                         i_start(ij), i_end(ij),               &
                                         j_start(ij), j_end(ij),               &
                                         itimestep, .false., tice2tsk_if2cold, &
                                         XICE, XICE_THRESHOLD,                 &
                                         SST, TSK, TSK_SEA, TSK_LOCAL )
                 DO j = j_start(ij) , j_end(ij)
                    DO i = i_start(ij) , i_end(ij)
                       TSK(i,j) = TSK_LOCAL(i,j)
                    ENDDO
                 ENDDO
              ENDIF
           ENDIF

           CALL LSMRUC( spp_lsm_loc,                            &
#if (EM_CORE==1)
                pattern_spp_lsm,field_sf,                       &
#endif
                dtbl,itimestep,num_soil_layers,                 &
#if (EM_CORE==1)
                lakemodel,lakemask,                             &
                graupelncv,snowncv,rainncv,                     &
#endif
                zs,rainbl,snow,snowh,snowc,sr,frpcpn,           &
                rhosnf,precipfr,                                &
                dz8w,p_phy,t_phy,qv_curr,qc_curr,rho,           & !p_phy in [pa]
                glw,gsw,emiss,chklowq,                          &
                chs,flqc,flhc,mavail,canwat,vegfra,albedo,znt,  &
                z0,snoalb, albbck, lai,                         &   !new
                mminlu, landusef, nlcat, mosaic_lu,             &
                mosaic_soil, soilctop, nscat,                   &   !new
                qsfc,qsg,qvg,qcg,dew,soilt1,tsnav,              &
                tmn,ivgtyp,isltyp,xland,                        &
                iswater,isice,xice,xice_threshold,              &
                cp ,rcp,g,xlv,stbolt,                           &
                smois,sh2o,smstav,smstot,tslb,tsk,hfx,qfx,lh,   &
                sfcrunoff,udrunoff,acrunoff,sfcexc,             &
                sfcevp,grdflx,snowfallac,acsnow,acsnom,         &
                smfr3d,keepfr3dflag,                            &
                myjpbl,shdmin,shdmax,rdlai2d,                   &
                ids,ide, jds,jde, kds,kde,                      &
                ims,ime, jms,jme, kms,kme,                      &
                i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte    )

           IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
             CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
              ! LSMRUC Returns full land/ice values, no fractional values.
              ! We return to a fractional component here.
              DO j=j_start(ij),j_end(ij)
                 DO i=i_start(ij),i_end(ij)
                    IF ( ( XICE(I,J) .GE. XICE_THRESHOLD) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                       albedo(i,j) = ( albedo(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * 0.08  )
                       emiss(i,j)  = ( emiss(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * 0.98  )
                    ENDIF
                 ENDDO
              ENDDO
              if ( isisfc ) then
                 !
                 !  back to ice and ocean average
                 !
                 DO j=j_start(ij),j_end(ij)
                    DO i=i_start(ij),i_end(ij)
                       IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN
                          flhc(i,j) = ( flhc(i,j) * XICE(i,j) ) + ( (1.-XICE(i,j)) * flhc_sea(i,j) )
                          flqc(i,j) = ( flqc(i,j) * XICE(i,j) ) + ( (1.-XICE(i,j)) * flqc_sea(i,j) )
                          cpm(i,j)  = ( cpm(i,j)  * XICE(i,j) ) + ( (1.-XICE(i,j)) * cpm_sea(i,j)  )
                          cqs2(i,j) = ( cqs2(i,j) * XICE(i,j) ) + ( (1.-XICE(i,j)) * cqs2_sea(i,j) )
                          chs2(i,j) = ( chs2(i,j) * XICE(i,j) ) + ( (1.-XICE(i,j)) * chs2_sea(i,j) )
                          chs(i,j)  = ( chs(i,j)  * XICE(i,j) ) + ( (1.-XICE(i,j)) * chs_sea(i,j)  )
                          qsfc(i,j) = ( qsfc(i,j) * XICE(i,j) ) + ( (1.-XICE(i,j)) * QSFC_SEA(i,j) )
                          qgh(i,j)  = ( qgh(i,j)  * XICE(i,j) ) + ( (1.-XICE(i,j)) * qgh_sea(i,j)  )
                          hfx(i,j)  = ( hfx(i,j)  * XICE(i,j) ) + ( (1.-XICE(i,j)) * HFX_SEA(i,j)  )
                          qfx(i,j)  = ( qfx(i,j)  * XICE(i,j) ) + ( (1.-XICE(i,j)) * QFX_SEA(i,j)  )
                          lh(i,j)   = ( lh(i,j)   * XICE(i,j) ) + ( (1.-XICE(i,j)) * LH_SEA(i,j)   )
!save old tsk_ice
                          tsk_save(i,j)  = tsk(i,j)
                          tsk(i,j)  = ( tsk(i,j)  * XICE(i,j) ) + ( (1.-XICE(i,j)) * TSK_SEA(i,j)  )
                       ENDIF
                    ENDDO
                 ENDDO
              else
                 !
                 ! tsk back to liquid and ice average
                 !
                 DO j = j_start(ij) , j_end(ij)
                    DO i = i_start(ij) , i_end(ij)
                       IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN
                          tsk(i,j) = ( tsk(i,j) * XICE(i,j) ) + ( (1.-XICE(i,j)) * TSK_SEA(i,j) )
                       ENDIF
                    ENDDO
                 ENDDO
              endif
           ENDIF

! Compute CHS and CQS that will be used in 2-m diagnostics
            DO j=j_start(ij),j_end(ij)
               DO i=i_start(ij),i_end(ij)
                     cqs(i,j)=flqc(i,j)/(mavail(i,j)*rho(i,kts,j))
                     chs(i,j)=flhc(i,j)/(cpm(i,j)*rho(i,kts,j) )
               ENDDO
            ENDDO

          CALL SFCDIAGS_RUCLSM(HFX,QFX,TSK,QSFC,CQS,CQS2,CHS,CHS2,T2,TH2,Q2,  &
                     T_PHY,QV_CURR,RHO,P_PHY,PSFC,SNOW,                       &
                     CP,R_d,RCP,                                              &
                     ids,ide, jds,jde, kds,kde,                               &
                     ims,ime, jms,jme, kms,kme,                               &
                     i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte   )

       ELSE
         CALL wrf_error_fatal('Lacking arguments for RUCLSM in surface driver')
       ENDIF

     CASE (PXLSMSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: PXLSMSCHEME not ported to the GPU')
#endif
       IF (PRESENT(qv_curr)    .AND.  PRESENT(qc_curr) .AND.    &
           PRESENT(emiss)      .AND.  PRESENT(t2)      .AND.    &
           PRESENT(rainbl) .AND.    &
                                                      .TRUE. ) THEN
          IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
            CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif

             IF ( isisfc ) THEN
                !
                ! use surface layer routine values from the ice portion of grid point
                !
             ELSE
                !
                ! don't have srfc layer routine values at this time, so just use what you have
                ! use ice component of TSK
                !
                CALL get_local_ice_tsk( ims, ime, jms, jme,                   &
                                        i_start(ij), i_end(ij),               &
                                        j_start(ij), j_end(ij),               &
                                        itimestep, .false., tice2tsk_if2cold, &
                                        XICE, XICE_THRESHOLD,                 &
                                        SST, TSK, TSK_SEA, TSK_LOCAL )
                DO j = j_start(ij) , j_end(ij)
                   DO i=i_start(ij) , i_end(ij)
                      TSK(i,j) = TSK_LOCAL(i,j)
                   ENDDO
                ENDDO
             ENDIF
          ENDIF
          CALL wrf_debug(100,'in P-X LSM')
          CALL PXLSM(u_phy, v_phy, dz8w, qv_curr, t_phy, th_phy, rho,&
                     psfc, gsw, glw, rainbl, emiss,                  &
                     ITIMESTEP, curr_secs, num_soil_layers, DT,      &
                     anal_interval, xland, xice, albbck, albedo,     &
                     snoalb, smois, tslb, mavail,T2, Q2, qsfc,       &
                     zs, dzs, psih,                                  &
                     landusef,soilctop,soilcbot,vegfra, vegf_px,     &
                     isltyp,ra,rs,lai,imperv,canfra,nlcat,nscat,     &
                     hfx,qfx,lh,tsk,sst,znt,canwat,                  &
                     grdflx,shdmin,shdmax,                           &
                     snowc,pblh,rmol,ust,capg,dtbl,                  &
                     t2_ndg_old,t2_ndg_new,q2_ndg_old,q2_ndg_new,    &
                     sn_ndg_old, sn_ndg_new, snow, snowh,snowncv,    &
                     t2obs, q2obs,pxlsm_smois_init,pxlsm_soil_nudge, &
                     pxlsm_modis_veg, LAI_PX, WWLT_PX, WFC_PX,       &
                     WSAT_PX, CLAY_PX, CSAND_PX, FMSAND_PX,          &
                     ids,ide, jds,jde, kds,kde,                      &
                     ims,ime, jms,jme, kms,kme,                      &
                     i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte)
          IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
            CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
             IF ( isisfc ) THEN
                !
                !  back to ice and ocean average
                !
                DO j = j_start(ij) , j_end(ij)
                   DO i = i_start(ij) , i_end(ij)
                      IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                         flhc(i,j) = ( flhc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * flhc_sea(i,j) )
                         flqc(i,j) = ( flqc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * flqc_sea(i,j) )
                         cpm(i,j)  = ( cpm(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * cpm_sea(i,j)  )
                         cqs2(i,j) = ( cqs2(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * cqs2_sea(i,j) )
                         chs2(i,j) = ( chs2(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * chs2_sea(i,j) )
                         chs(i,j)  = ( chs(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * chs_sea(i,j)  )
                         qsfc(i,j) = ( qsfc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * QSFC_SEA(i,j) )
                         qgh(i,j)  = ( qgh(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * QGH_SEA(i,j)  )
                         hfx(i,j)  = ( hfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * HFX_SEA(i,j)  )
                         qfx(i,j)  = ( qfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * QFX_SEA(i,j)  )
                         lh(i,j)   = ( lh(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * LH_SEA(i,j)   )
!save old tsk_ice
                         tsk_save(i,j)  = tsk(i,j)
                         tsk(i,j)  = ( tsk(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * TSK_SEA(i,j)  )
                      ENDIF
                   ENDDO
                ENDDO
             ELSE
                !
                ! tsk back to liquid and ice average
                !
                DO j=j_start(ij),j_end(ij)
                   DO i=i_start(ij),i_end(ij)
                      IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
!save old tsk_ice
                         tsk_save(i,j)  = tsk(i,j)
                         tsk(i,j)=tsk(i,j)*XICE(i,j)+(1.0-XICE(i,j))*TSK_SEA(i,j)
                      ENDIF
                   ENDDO
                ENDDO
             ENDIF
          ENDIF
           DO j=j_start(ij),j_end(ij)
           DO i=i_start(ij),i_end(ij)
              CHKLOWQ(I,J)= 1.0
              TH2(I,J) = T2(I,J)*rp_pow((1.E5/PSFC(I,J)), RCP)
              SFCEVP(I,J)= SFCEVP(I,J) + QFX(I,J)*DTBL
           ENDDO
           ENDDO

       ELSE
         CALL wrf_error_fatal('Lacking arguments for P-X LSM in surface driver')
       ENDIF
#ifdef WRF_USE_CLM
!---------------------------------------------------------------------
! CLM coupling currently version 4 added by Yaqiong Lu and Jiming Jin

     CASE (CLMSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: CLMSCHEME not ported to the GPU')
#endif
     CALL wrf_debug(100,'in CLM')

     IF (MYJ) call wrf_error_fatal('CLM is not currently compatible with MYJ.  Please pick different PBL Schemes')

     IF (present(qv_curr) .and.  present(rainbl) .and.    &
                                                      .true. ) then

       ! print *, "itimestep = ", itimestep
      !  print *," in module_surface_driver.F :  dz8w(i,1,j) = ",dz8w(:,1,:)
         IF( PRESENT(sr) ) THEN
           frpcpn=.true.
         ENDIF
         IF ( FRACTIONAL_SEAICE == 1) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            ! The fields passed to LSM need to represent the full ice values, not
            ! the fractional values.  Convert ALBEDO and EMISS from the blended value 
            ! to a value representing only the sea-ice portion.   Albedo over open 
            ! water is taken to be 0.08. Emissivity over open water is taken to be 0.98
            DO j = j_start(ij) , j_end(ij)
               DO i = i_start(ij) , i_end(ij)
                  IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE.  1 ) ) THEN
                     ALBEDO(I,J) = (ALBEDO(I,J)-(1.-XICE(I,J))*0.08)/XICE(I,J)
                     EMISS(I,J) = (EMISS(I,J)-(1.-XICE(I,J))*0.98)/XICE(I,J)
                  ENDIF
               ENDDO
            ENDDO
            IF ( isisfc ) THEN
              ! Use surface layer routine values from the ice portion of grid
              ! point
            ELSE
               !    
               ! We don't have surface layer routine values at this time, so
               ! just use what we have.  Use ice component of TSK
               !    
               DO j = j_start(ij) , j_end(ij)
                  DO i = i_start(ij) , i_end(ij)
                     IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1 ) ) THEN
                        IF ( SST(i,j) .LT. 271.4 ) THEN
                           SST(i,j) = 271.4
                        ENDIF
                        TSK_SEA(i,j) = SST(i,j)
                        ! Convert TSK from our ice/water average value to value
                        ! good for solid-ice surface.
                        TSK(i,j) = ( TSK(i,j) - (1.-XICE(i,j)) *SST(i,j) ) / XICE(i,j)
                        IF (XICE(i,j).lt.0.2 .and. TSK(i,j).lt.253.15) THEN
                           TSK(i,j) = 253.15
                        ENDIF
                        IF (XICE(i,j).lt.0.1 .and. TSK(i,j).lt.263.15) THEN
                           TSK(i,j) = 263.15
                        ENDIF
                     ELSE
                        TSK_SEA(i,j) = TSK(i,j)
                     ENDIF
                  ENDDO
               ENDDO
            ENDIF
         ENDIF

       write(message,'('' surface_driver: B4 call to clmdrv with do_bioe = '',l)') do_bioe
       CALL wrf_debug( 100,trim(message) )
       CALL wrf_debug(100,'in clmdrv')

       if (num_soil_layers.ne.10) then
        CALL wrf_error_fatal('CLM land surface model need num_soil_layers=10')
       endif

       CALL clmdrv(dz8w,qv_curr,p8w, t_phy,tsk,                   &
                hfx,qfx,lh,grdflx,qgh,gsw,swdown,               &
                ra_sw_physics,history_interval,glw,smstav,smstot, &
                sfcrunoff,udrunoff,ivgtyp,isltyp,vegfra,        &
                albedo,znt,z0, tmn,xland,xice, emiss,           &
                snowc,qsfc,rainbl,maxpatch,                     &
                num_soil_layers,dtbl,xtime, dt,dzs,             &
                smois,tslb,snow,canwat,                         &
                chs,chs2,sh2o,snowh,                            &
                u_phy,v_phy,rho,                                &
                shdmin,shdmax,                                  &
                acsnom,acsnow,                                  &
                dx,xlat,xlong,ht,                               &
#if ( WRF_CHEM == 1 )
                ne_area,e_bio,                                  &
#endif
                ids,ide, jds,jde, kds,kde,                      &
                ims,ime, jms,jme, kms,kme,                      &
                i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte, &
                inest,sf_urban_physics,do_bioe,do_meganfile,id   &
!Optional urban
               ,cmr_sfcdif,chr_sfcdif,cmc_sfcdif,chc_sfcdif    &
               ,cmgr_sfcdif,chgr_sfcdif                        &
               ,tr_urb2d,tb_urb2d,tg_urb2d,tc_urb2d,qc_urb2d,  & !H urban
                uc_urb2d,                                       & !H urban
                xxxr_urb2d,xxxb_urb2d,xxxg_urb2d,xxxc_urb2d,    & !H urban
                trl_urb3d,tbl_urb3d,tgl_urb3d,                  & !H urban
                sh_urb2d,lh_urb2d,g_urb2d,rn_urb2d,ts_urb2d,    & !H urban
                psim_urb2d,psih_urb2d,u10_urb2d,v10_urb2d,      & !O urban
                GZ1OZ0_urb2d, AKMS_URB2D,                       & !O urban
                th2_urb2d,q2_urb2d,ust_urb2d,                   & !O urban
                declin,coszen,hrang,                            & !I urban   !  by hongping Gu
                xlat_urb2d,                                     & !I urban
                num_roof_layers, num_wall_layers,               & !I urban
                num_road_layers, DZR, DZB, DZG,                 & !I urban
                FRC_URB2D, UTYPE_URB2D,                         & !I urban
                cmcr_urb2d,tgr_urb2d,tgrl_urb3d,smr_urb3d,      & ! urban
                drelr_urb2d,drelb_urb2d,drelg_urb2d,            & ! urban
                flxhumr_urb2d,flxhumb_urb2d,flxhumg_urb2d,      &
! CLM subgrids
                numc,nump,sabv,sabg,lwup,snl, &
                snowdp,wtc,wtp,h2osno,t_grnd,t_veg,         &
                h2ocan,h2ocan_col,t2m_max,t2m_min,t2clm ,    &
                t_ref2m,h2osoi_liq_s1,                 &
                h2osoi_liq_s2,h2osoi_liq_s3,h2osoi_liq_s4,          &
                h2osoi_liq_s5,h2osoi_liq1,h2osoi_liq2,              &
                h2osoi_liq3,h2osoi_liq4,h2osoi_liq5,h2osoi_liq6,    &
                h2osoi_liq7,h2osoi_liq8,h2osoi_liq9,h2osoi_liq10,   &
                h2osoi_ice_s1,h2osoi_ice_s2,                        &
                h2osoi_ice_s3,h2osoi_ice_s4,h2osoi_ice_s5,          &
                h2osoi_ice1,h2osoi_ice2,h2osoi_ice3,h2osoi_ice4,    &
                h2osoi_ice5,h2osoi_ice6,h2osoi_ice7,                &
                h2osoi_ice8,h2osoi_ice9,h2osoi_ice10,               &
                t_soisno_s1,t_soisno_s2,t_soisno_s3,t_soisno_s4,    &
                t_soisno_s5,t_soisno1,t_soisno2,t_soisno3,          &
                t_soisno4,t_soisno5,t_soisno6,t_soisno7,            &
                t_soisno8,t_soisno9,t_soisno10,                     &
                dzsnow1,dzsnow2,dzsnow3,dzsnow4,dzsnow5,            &
                snowrds1,snowrds2,snowrds3,snowrds4,snowrds5,       &
                t_lake1,t_lake2,t_lake3,t_lake4,t_lake5,            &
                t_lake6,t_lake7,t_lake8,t_lake9,t_lake10,           &
                h2osoi_vol1,h2osoi_vol2,h2osoi_vol3,                &
                h2osoi_vol4,h2osoi_vol5,h2osoi_vol6,                &
                h2osoi_vol7,h2osoi_vol8,                            &
                h2osoi_vol9,h2osoi_vol10,                           &
                q_ref2m,                                   &
                ALBEDOsubgrid,LHsubgrid,HFXsubgrid,LWUPsubgrid,     &
                Q2subgrid,SABVsubgrid,SABGsubgrid,NRAsubgrid,SWUPsubgrid,&
                LHsoi,LHveg,LHtran, &
                alswvisdir, alswvisdif, alswnirdir, alswnirdif,      & ! clm
                swvisdir, swvisdif, swnirdir, swnirdif,              & ! clm
                t_veg24, t_veg240, fsun24, fsun240,                  &
                fsd24, fsd240, fsi24, fsi240, laip                   &
#ifdef CN
!CROP&CN RESTART AND OUTPUTS
                ,dyntlai,dyntsai,dyntop,dynbot &
                ,htmx,croplive,gdd1020,gdd820,gdd020,grainc,grainc_storage  &
                ,grainc_xfer,grainn,grainn_storage,grainn_xfer,days_active  &
                ,onset_flag,onset_counter,onset_gddflag,onset_fdd,onset_gdd &
                ,onset_swi,offset_flag,offset_counter,offset_fdd,offset_swi &
                ,dayl,annavg_t2m,tempavg_t2m,tempsum_potential_gpp          &
                ,annsum_potential_gpp,tempmax_retransn,annmax_retransn      &
                ,prev_leafc_to_litter,prev_frootc_to_litter,tempsum_npp     &
                ,annsum_npp,leafc,leafc_storage,leafc_xfer,frootc           &
                ,frootc_storage,frootc_xfer,livestemc,livestemc_storage     &
                ,livestemc_xfer,deadstemc,deadstemc_storage,deadstemc_xfer  &
                ,livecrootc,livecrootc_storage,livecrootc_xfer,deadcrootc   &
                ,deadcrootc_storage,deadcrootc_xfer,cpool,pft_ctrunc        &
                ,leafn,leafn_storage,leafn_xfer,frootn,frootn_storage       &
                ,frootn_xfer,livestemn,livestemn_storage,livestemn_xfer     &
                ,deadstemn,deadstemn_storage,deadstemn_xfer,livecrootn      &
                ,livecrootn_storage,livecrootn_xfer,deadcrootn              &
                ,deadcrootn_storage,deadcrootn_xfer,npool,pft_ntrunc        &
                ,gresp_storage,gresp_xfer,xsmrpool,annsum_counter           &
                ,cannsum_npp,cannavg_t2m,wf,me,mean_fire_prob,cwdc,litr1c   &
                ,litr2c,litr3c,soil1c,soil2c,soil3c,soil4c,seedc,col_ctrunc &
                ,prod10c,prod100c,cwdn,litr1n,litr2n,litr3n,soil1n,soil2n   &
                ,soil3n,soil4n,seedn,col_ntrunc,prod10n,prod100n,sminn      &
                ,totlitc,dwt_seedc_to_leaf,dwt_seedc_to_deadstem,dwt_conv_cflux &
                ,dwt_prod10c_gain,dwt_prod100c_gain,prod100c_loss,dwt_frootc_to_litr1c &
                ,dwt_frootc_to_litr2c,dwt_frootc_to_litr3c,dwt_livecrootc_to_cwdc &
                ,dwt_deadcrootc_to_cwdc,dwt_seedn_to_leaf,dwt_seedn_to_deadstem &
                ,dwt_conv_nflux,dwt_prod10n_gain,dwt_prod100n_gain,prod100n_loss &
                ,dwt_frootn_to_litr1n,dwt_frootn_to_litr2n, dwt_frootn_to_litr3n &
                ,dwt_livecrootn_to_cwdn,dwt_deadcrootn_to_cwdn,retransn &
#endif
                ,nlcat,landusef,num_pft_input,pct_pft_input,input_pft_flag &
                 )

         IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            DO j=j_start(ij),j_end(ij)
               DO i=i_start(ij),i_end(ij)
                  IF ( ( XICE(I,J) .GE. XICE_THRESHOLD) .AND. ( XICE(i,j) .LE.  1.0 ) ) THEN
                     albedo(i,j) = ( albedo(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * 0.08  )
                     emiss(i,j) = ( emiss(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * 0.98  )
                  ENDIF
               ENDDO
            ENDDO

            IF ( isisfc ) THEN
               DO j=j_start(ij),j_end(ij)
                  DO i=i_start(ij),i_end(ij)
                     IF ( ( XICE(I,J) .GE. XICE_THRESHOLD) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                        !  Weighted average of fields between ice-cover values
                        !  and open-water values.
                        flhc(i,j) = ( flhc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * flhc_sea(i,j) )
                        flqc(i,j) = ( flqc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * flqc_sea(i,j) )
                        cpm(i,j)  = ( cpm(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * cpm_sea(i,j)  )
                        cqs2(i,j) = ( cqs2(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * cqs2_sea(i,j) )
                        chs2(i,j) = ( chs2(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * chs2_sea(i,j) )
                        chs(i,j)  = ( chs(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * chs_sea(i,j)  )
                        qsfc(i,j) = ( qsfc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qsfc_sea(i,j) )
                        qgh(i,j)  = ( qgh(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qgh_sea(i,j)  )
                        qz0(i,j)  = ( qz0(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qz0_sea(i,j)  )
                        hfx(i,j)  = ( hfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * hfx_sea(i,j)  )
                        qfx(i,j)  = ( qfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qfx_sea(i,j)  )
                        lh(i,j)   = ( lh(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * lh_sea(i,j)   )
!save old tsk_ice
                        tsk_save(i,j)  = tsk(i,j)
                        tsk(i,j)  = ( tsk(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * tsk_sea(i,j)  )
                     ENDIF
                  ENDDO
               ENDDO
            ELSE
               DO j = j_start(ij) , j_end(ij)
                  DO i = i_start(ij) , i_end(ij)
                     IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                        ! Compute TSK as the open-water and ice-cover average
                        tsk(i,j) = ( tsk(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * tsk_sea(i,j) )
                     ENDIF
                  ENDDO
               ENDDO
            ENDIF
         ENDIF
          CALL SFCDIAGS(HFX,QFX,TSK,QSFC,CHS2,CQS2,T2,TH2,Q2,      &
                     PSFC,CP,R_d,RCP,CHS,t_phy,qv_curr,ua_phys,    &
                     ids,ide, jds,jde, kds,kde,                    &
                     ims,ime, jms,jme, kms,kme,                    &
             i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte    )

           DO j=j_start(ij),j_end(ij)
           DO i=i_start(ij),i_end(ij)
              CHKLOWQ(I,J)= 1.0
              SFCEVP(I,J)= SFCEVP(I,J) + QFX(I,J)*DTBL

! update land variables from CLM
              IF(XLAND(I,J).LT.1.5) then
                  Q2(I,J) = sum(q_ref2m(i,1:nump(i,j),j)*wtp(i,1:nump(i,j),j))

! convert specific humidty to mixing ratio unit: kg/kg)
                  Q2(I,J) = Q2(I,J)/(1.0-Q2(I,J))

                  T2(I,J) = sum(t_ref2m(i,1:nump(i,j),j)*wtp(i,1:nump(i,j),j))
                  TH2(I,J)= T2(I,J)*rp_pow((1.E5/PSFC(I,J)), RCP)
              END IF
           ENDDO
           ENDDO

       ELSE
         CALL wrf_error_fatal('Lacking arguments for CLM in surface driver')
       ENDIF

! end of CLM scehme
! -------------------------------------------------------------------
#endif

#ifdef WRF_USE_CTSM
     CASE (CTSMSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: CTSMSCHEME not ported to the GPU')
#endif

     IF (MYJ) call wrf_error_fatal('CTSM is not currently compatible with MYJ.  Please pick a different PBL scheme,')

     IF (PRESENT(qv_curr)    .AND.  PRESENT(rainbl)        .AND.  &
       ! PRESENT(emiss)      .AND.  PRESENT(t2)            .AND.    &
       ! PRESENT(declin) .AND.  PRESENT(coszen)    .AND.            &
       ! PRESENT(hrang)  .AND. PRESENT( xlat_urb2d)    .AND.        &
       ! PRESENT(dzr)       .AND.                                   &
       ! PRESENT( dzb)            .AND. PRESENT(dzg)       .AND.    &
       ! PRESENT(tr_urb2d) .AND. PRESENT(tb_urb2d)         .AND.    &
       ! PRESENT(tg_urb2d) .AND. PRESENT(tc_urb2d) .AND.            &
       ! PRESENT(qc_urb2d) .AND. PRESENT(uc_urb2d) .AND.            &
       ! PRESENT(xxxr_urb2d) .AND. PRESENT(xxxb_urb2d) .AND.        &
       ! PRESENT(xxxg_urb2d) .AND.                                  &
       ! PRESENT(xxxc_urb2d) .AND. PRESENT(trl_urb3d) .AND.         &
       ! PRESENT(tbl_urb3d)   .AND. PRESENT(tgl_urb3d)  .AND.       &
       ! PRESENT(sh_urb2d) .AND. PRESENT(lh_urb2d)  .AND.           &
       ! PRESENT(g_urb2d)   .AND. PRESENT(rn_urb2d) .AND.           &
       ! PRESENT(ts_urb2d)                          .AND.           &
       ! PRESENT(frc_urb2d) .AND. PRESENT(utype_urb2d)   .AND.      &
                                                      .TRUE. ) THEN


!------------------------------------------------------------------
        !For WRF-CTSM simulations, we would like the land model (CTSM)
        ! to handle inland lake points.
        ! Here, we are making ctsm_xland to include lake points, so that
        ! CTSM can handle it.
         DO j=j_start(ij),j_end(ij)
            DO i=i_start(ij),i_end(ij)
                xland_ctsm (i,j) = xland (i,j) 
                IF (lakemask(i,j).EQ.1.) THEN
                    xland_ctsm (i,j)  = 1  
                ENDIF
            ENDDO
         ENDDO

         IF ( FRACTIONAL_SEAICE == 1) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            ! The fields passed to LSM need to represent the full ice values, not
            ! the fractional values.  Convert ALBEDO and EMISS from the blended value 
            ! to a value representing only the sea-ice portion.   Albedo over open 
            ! water is taken to be 0.08. Emissivity over open water is taken to be 0.98
            DO j = j_start(ij) , j_end(ij)
               DO i = i_start(ij) , i_end(ij)
                  IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1 ) ) THEN
                     ALBEDO(I,J) = (ALBEDO(I,J)-(1.-XICE(I,J))*0.08)/XICE(I,J)
                     EMISS(I,J) = (EMISS(I,J)-(1.-XICE(I,J))*0.98)/XICE(I,J)
                  ENDIF  
               ENDDO 
            ENDDO
            IF ( isisfc ) THEN
               ! Use surface layer routine values from the ice portion of grid point
            ELSE      
               !      
               ! We don't have surface layer routine values at this time, so
               ! just use what we have.  Use ice component of TSK
               !      
               CALL get_local_ice_tsk( ims, ime, jms, jme,                   &
                                       i_start(ij), i_end(ij),               &
                                       j_start(ij), j_end(ij),               &
                                       itimestep, .false., tice2tsk_if2cold, &
                                       XICE, XICE_THRESHOLD,                 &
                                       SST, TSK, TSK_SEA, TSK_LOCAL )

               DO j = j_start(ij) , j_end(ij)
                  DO i = i_start(ij) , i_end(ij)
                     TSK(i,j) = TSK_LOCAL(i,j)
                  ENDDO
               ENDDO                                                                                                                                                                 
            ENDIF                                                                                                                                                                  
        ENDIF 


         CALL ctsm_run( &
             ! bounds
             ids=ids, ide=ide, jds=jds, jde=jde, &
             ims=ims, ime=ime, jms=jms, jme=jme, kms=kms, &
             its=i_start(ij), ite=i_end(ij), jts=j_start(ij), jte=j_end(ij), &

             ! restart flag
             restart_flag=restart_flag,&

             ! general information
             dt             = dt, &
             xland          = xland_ctsm, &
             xice           = xice, &
             xice_threshold = xice_threshold, &

             ! atm -> lnd variables
             dz8w     = dz8w, &
             ht       = ht, &
             u_phy    = u_phy,  &
             v_phy    = v_phy,  &
             p8w      = p_phy,  &
             t_phy    = t_phy,  &
             th_phy   = th_phy, &
             qv_curr  = qv_curr, &
             rainbl   = rainbl, &
             sr       = sr, &
             glw      = glw, &
             swvisdir = swvisdir, &
             swvisdif = swvisdif, &
             swnirdir = swnirdir, &
             swnirdif = swnirdif, &

             ! lnd -> atm variables
             tsk      = tsk, &
             t2       = t2, &
             qsfc     = qsfc, &
             albedo   = albedo, &
             ust      = ust, &
             hfx      = hfx, &
             lh       = lh, &
             qfx      = qfx, &
             emiss    = emiss, &
             z0       = z0, &
             znt      = znt)

         call seaice_noah( SEAICE_ALBEDO_OPT, SEAICE_ALBEDO_DEFAULT, SEAICE_THICKNESS_OPT, &
              &            SEAICE_THICKNESS_DEFAULT, SEAICE_SNOWDEPTH_OPT,             &
              &            SEAICE_SNOWDEPTH_MAX, SEAICE_SNOWDEPTH_MIN,                 &
              &            t_phy, qv_curr, p8w, dz8w, num_soil_layers, dt, frpcpn, sr, &
              &            glw, swdown, rainbl, snoalb, qgh, xice, xice_threshold,     &
              &            albsi, icedepth, snowsi,                                    &
              &            tslb, emiss, albedo, z0, tsk, snow, snowc, snowh,           &
              &            chs, chs2, cqs2,                                            &
              &            br, znt, lh, hfx, qfx, potevp, grdflx, qsfc, acsnow,        &
              &            acsnom, snopcx, sfcrunoff, noahres,                         &
              &            sf_urban_physics, b_t_bep, b_q_bep, rho,                    &
              &            ids,ide, jds,jde, kds,kde,                                  &
              &            ims,ime, jms,jme, kms,kme,                                  &
              &            i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte )

         IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
           CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
            ! LSM Returns full land/ice values, no fractional values.
            ! We return to a fractional component here.  SFLX currently hard-wires
            ! emissivity over sea ice to 0.98, the same value as over open water, so
            ! the fractional consideration doesn't have any effect for emissivity.
            DO j=j_start(ij),j_end(ij)
               DO i=i_start(ij),i_end(ij)
                  IF ( ( XICE(I,J) .GE. XICE_THRESHOLD) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                     albedo(i,j) = ( albedo(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * 0.08  )
                     emiss(i,j) = ( emiss(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * 0.98  )
                  ENDIF
               ENDDO
            ENDDO

            IF ( isisfc ) THEN
               DO j=j_start(ij),j_end(ij)
                  DO i=i_start(ij),i_end(ij)
                     IF ( ( XICE(I,J) .GE. XICE_THRESHOLD) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                        !  Weighted average of fields between ice-cover values and open-water values.
                        flhc(i,j) = ( flhc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * flhc_sea(i,j) )
                        flqc(i,j) = ( flqc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * flqc_sea(i,j) )
                        cpm(i,j)  = ( cpm(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * cpm_sea(i,j)  )
                        cqs2(i,j) = ( cqs2(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * cqs2_sea(i,j) )
                        chs2(i,j) = ( chs2(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * chs2_sea(i,j) )
                        chs(i,j)  = ( chs(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * chs_sea(i,j)  )
                        qsfc(i,j) = ( qsfc(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qsfc_sea(i,j) )
                        qgh(i,j)  = ( qgh(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qgh_sea(i,j)  )
                        qz0(i,j)  = ( qz0(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qz0_sea(i,j)  )
                                                            !  print *,'hfx =',hfx_sea(170,20)
                                                            !   print *,'XICE =',XICE(170,20)
                                                            !    print *,'QSFC =',QSFC(170,20)
                        hfx(i,j)  = ( hfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * hfx_sea(i,j)  )
                        qfx(i,j)  = ( qfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qfx_sea(i,j)  )
                        lh(i,j)   = ( lh(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * lh_sea(i,j)   )
!save old tsk_ice
                        tsk_save(i,j)  = tsk(i,j)
                        tsk(i,j)  = ( tsk(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * tsk_sea(i,j)  )
                     ENDIF
                  ENDDO
               ENDDO
            ELSE
               DO j = j_start(ij) , j_end(ij)
                  DO i = i_start(ij) , i_end(ij)
                     IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                        ! Compute TSK as the open-water and ice-cover average
                        tsk(i,j) = ( tsk(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * tsk_sea(i,j) )
                     ENDIF
                  ENDDO
               ENDDO
            ENDIF
         ENDIF

      ENDIF

      DO j=j_start(ij),j_end(ij)                                               
         DO i=i_start(ij),i_end(ij)
            CHKLOWQ(I,J)= 1.0
            SFCEVP(I,J)= SFCEVP(I,J) + QFX(I,J)*DTBL
            !SFCEXC(I,J)= CHS(I,J)
            IF(PRESENT(ACHFX))ACHFX(I,J)=ACHFX(I,J) + HFX(I,J)*DT
            IF(PRESENT(ACLHF))ACLHF(I,J)=ACLHF(I,J) + LH(I,J)*DT
            IF(PRESENT(ACGRDFLX))ACGRDFLX(I,J)=ACGRDFLX(I,J) + GRDFLX(I,J)*DT
         ENDDO
      ENDDO

#endif

     CASE (SSIBSCHEME)
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: SSIBSCHEME not ported to the GPU')
#endif
     IF(PRESENT(alswvisdir))THEN
!---Fernando De Sales (fds 06/2010)--------------------------------------
     CALL wrf_debug(100,'in SSIB')
!
       IF ( FRACTIONAL_SEAICE == 1) THEN
#ifdef WRF_GPU
         CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
          ! The fields passed to SSIB need to represent the full ice values, not
          ! the fractional values.  Convert ALBEDO from the blended value
          ! to a value representing only the sea-ice portion.   Albedo over open
          ! water is taken to be 0.08.
          DO j = j_start(ij) , j_end(ij)
             DO i = i_start(ij) , i_end(ij)
                IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1 ) ) THEN
                   ALBEDO(I,J) = (ALBEDO(I,J)-(1.-XICE(I,J))*0.08)/XICE(I,J)
                ENDIF
             ENDDO
          ENDDO
       ELSE
!  we shouldn't be here. must have fractional seaice for SSIB to work properly (fds 12/2010)
       ENDIF
!
!This stuff is not needed anymore since isisfc is always TRUE for SSIB
!Keep it for later use when code is adapted for isisfc=FALSE
!          IF ( isisfc ) THEN
!             ! Use surface layer routine values from the ice portion of grid point
!          ELSE
!             !
!             ! We don't have surface layer routine values at this time, so
!             ! just use what we have.  Use ice component of TSK
!             !
!             DO j = j_start(ij) , j_end(ij)
!                DO i = i_start(ij) , i_end(ij)
!                   IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1 ) ) THEN
!                      IF ( SST(i,j) .LT. 271.4 ) THEN
!                         SST(i,j) = 271.4
!                      ENDIF
!                      TSK_SEA(i,j) = SST(i,j)
!                      ! Convert TSK from our ice/water average value to value good for solid-ice surface.
!                      TSK(i,j) = ( TSK(i,j) - (1.-XICE(i,j)) *SST(i,j) ) / XICE(i,j)
!                      IF (XICE(i,j).lt.0.2 .and. TSK(i,j).lt.253.15) THEN
!                         TSK(i,j) = 253.15
!                      ENDIF
!                      IF (XICE(i,j).lt.0.1 .and. TSK(i,j).lt.263.15) THEN
!                         TSK(i,j) = 263.15
!                      ENDIF
!                   ELSE
!                      TSK_SEA(i,j) = TSK(i,j)
!                   ENDIF
!                ENDDO
!             ENDDO
!          ENDIF
!
       day=float(int(julian_in+0.01))+1.
       DO j=j_start(ij),j_end(ij)
       DO i=i_start(ij),i_end(ij)

!check land mask and land-use map !fds (02/2012)
!       IF(itimestep .EQ. 1 ) THEN
!          IF(IVGTYP(i,j).NE.ISWATER)THEN
!            XLAND(I,J)=1.0
!          ELSE
!            XLAND(I,J)=2.0
!          ENDIF
!          IF (IVGTYP(I,J).LE.0 .AND. XLAND(I,J).NE.ISWATER ) IVGTYP(I,J) = 7.0
!       ENDIF

       IF(XLAND(I,J).LT.1.5) THEN ! seaice and land points

           CLOUDFRAC=0.
           IF(PRESENT(CLDFRA))THEN
           DO K=KMS,KME
             CLOUDFRAC=AMAX1(CLOUDFRAC,AMIN1(CLDFRA(I,K,J),1.0))
           ENDDO
           ENDIF

         IF (XICE(I,J) .GE. XICE_THRESHOLD) THEN !sea ice points only

           CALL ssib_seaice                                                        &
                    ( i, j, DTBL, itimestep, xlat_urb2d(i,j), coszen(i,j),         &
                      rainncv(i,j), raincv(i,j), glw(i,j), dz8w(i,1,j),            &
                      smois(i,1,j), smois(i,2,j), smois(i,3,j),                    &
                      tslb(i,1,j), tslb(i,2,j), tslb(i,3,j),                       &
                      snow(i,j), sfcrunoff(i,j), xice_save(i,j),                   &
                      u_phytmp(i,1,j),v_phytmp(i,1,j),qv_curr(i,1,j),t_phy(i,1,j), &
                      p_phy(i,1,j), psfc(i,j),                                     &
                      swdown(i,j), canwat(i,j),                                    &
                 alswvisdir(i,j),alswvisdif(i,j),alswnirdir(i,j),alswnirdif(i,j),  &
                      swvisdir(i,j), swvisdif(i,j), swnirdir(i,j), swnirdif(i,j),  &
                      hfx(i,j), lh(i,j), grdflx(i,j), qfx(i,j), tsk(i,j),          &
                      ust(i,j), ssib_br(i,j), ssib_fm(i,j), ssib_fh(i,j), ssib_cm(i,j), &
                      ssib_lhf(i,j), ssib_shf(i,j), ssib_ghf(i,j),                 &
                      ssib_sdn(i,j), ssib_sup(i,j), ssib_ldn(i,j), ssib_lup(i,j),  &
                      ssib_wat(i,j),                                               &
                                     ssib_z00(i,j), ssib_veg(i,j),                 &
                      day, cloudfrac, q2(i,j), t2(i,j), albedo(i,j), uv10,         &
                      ra_sw_physics,xice_threshold                                 &
                                                                                   )
         ELSE  !land points only (including land ice)

           CALL ssib( i, j, DTBL, itimestep, xlat_urb2d(i,j), coszen(i,j),        &
                     rainncv(i,j), raincv(i,j), glw(i,j), dz8w(i,1,j),            &
                     smois(i,1,j), smois(i,2,j), smois(i,3,j),                    &
                     tslb(i,1,j), tslb(i,2,j), tslb(i,3,j),                       &
                     snow(i,j), sfcrunoff(i,j),                                   &
                     u_phytmp(i,1,j),v_phytmp(i,1,j),qv_curr(i,1,j),t_phy(i,1,j), &
                     p_phy(i,1,j), psfc(i,j), ivgtyp(i,j),                        &
                     swdown(i,j), canwat(i,j),                                    &
                alswvisdir(i,j),alswvisdif(i,j),alswnirdir(i,j),alswnirdif(i,j),  &
                     swvisdir(i,j), swvisdif(i,j), swnirdir(i,j), swnirdif(i,j),  &
                     hfx(i,j), lh(i,j), grdflx(i,j), qfx(i,j), tsk(i,j),          &
                     ust(i,j), ssib_br(i,j), ssib_fm(i,j), ssib_fh(i,j), ssib_cm(i,j), &
                     ssib_lhf(i,j), ssib_shf(i,j), ssib_ghf(i,j), ssib_egs(i,j),  & 
                     ssib_eci(i,j), ssib_ect(i,j), ssib_egi(i,j), ssib_egt(i,j),  &
                     ssib_sdn(i,j), ssib_sup(i,j), ssib_ldn(i,j), ssib_lup(i,j),  &
                     ssib_wat(i,j), ssib_shc(i,j), ssib_shg(i,j), ssib_lai(i,j),  &
                     ssib_vcf(i,j), ssib_z00(i,j), ssib_veg(i,j), ssibxdd(i,j),   &
                     isnow(i,j), swe(i,j), snowden(i,j), snowdepth(i,j),tkair(i,j),  &
                     dzo1(i,j),  wo1(i,j),   tssn1(i,j), tssno1(i,j), bwo1(i,j), bto1(i,j),  &
                     cto1(i,j), fio1(i,j),    flo1(i,j),   bio1(i,j), blo1(i,j),  ho1(i,j),  &
                     dzo2(i,j),  wo2(i,j),   tssn2(i,j), tssno2(i,j), bwo2(i,j), bto2(i,j),  &
                     cto2(i,j), fio2(i,j),    flo2(i,j),   bio2(i,j), blo2(i,j),  ho2(i,j),  &
                     dzo3(i,j),  wo3(i,j),   tssn3(i,j), tssno3(i,j), bwo3(i,j), bto3(i,j),  &
                     cto3(i,j), fio3(i,j),    flo3(i,j),   bio3(i,j), blo3(i,j),  ho3(i,j),  &
                     dzo4(i,j),  wo4(i,j),   tssn4(i,j), tssno4(i,j), bwo4(i,j), bto4(i,j),  &
                     cto4(i,j), fio4(i,j),    flo4(i,j),   bio4(i,j), blo4(i,j),  ho4(i,j),  &
                     day, cloudfrac, q2(i,j), t2(i,j), albedo(i,j), uv10,          &
                     ra_sw_physics, mminlu                                        &
                                                                                  )
         ENDIF
!
         BR(i,j)=ssib_br(i,j)
         ZNT(i,j) = ssib_z00(i,j)
         SFCEVP(I,J)= SFCEVP(I,J) + QFX(I,J)*DTBL
         t2(i,j) = tsk(i,j)  !keep this
         IF (itimestep .ne. 1) THEN
           ZDIFF=(0.5*dz8w(i,1,j))-SSiBXDD(I,J)
           IF(ZDIFF.LE.ZNT(I,J)) ZDIFF=ZNT(I,J)+0.2
           GZ1OZ0(I,J)=rp_log(ZDIFF/ZNT(I,J))
         ENDIF
         IF (XICE(I,J) .GE. XICE_THRESHOLD) THEN
           snowh(i,j) = 0.0
         ELSE
           snowh(i,j) = snowdepth(i,j)
         ENDIF
         U10(i,j) = UV10*u_phytmp(i,1,j)/SQRT(u_phytmp(i,1,j)**2+v_phytmp(i,1,j)**2)
         V10(i,j) = UV10*v_phytmp(i,1,j)/SQRT(u_phytmp(i,1,j)**2+v_phytmp(i,1,j)**2)
!        Overwrite WSPD to remove convective velocity (wspd=wspd1 in YSU)
!        WSPD(I,J)=sqrt( u_phytmp(i,1,j)*u_phytmp(i,1,j) +      &
!                        v_phytmp(i,1,j)*v_phytmp(i,1,j) ) + 1.e-9
!
       ENDIF
!
       ENDDO
       ENDDO
!
       IF ( FRACTIONAL_SEAICE == 1 ) THEN
#ifdef WRF_GPU
         CALL wrf_error_fatal('surface_driver: fractional_seaice not ported to the GPU')
#endif
          ! SSIB_seaice returns full land/ice albedo values, no fractional values.
          ! We return to a fractional component here. 
          DO j=j_start(ij),j_end(ij)
             DO i=i_start(ij),i_end(ij)
                IF ( ( XICE(I,J) .GE. XICE_THRESHOLD) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                   albedo(i,j) = ( albedo(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * 0.08  )
                ENDIF
             ENDDO
          ENDDO
!
          IF ( isisfc ) THEN
             DO j=j_start(ij),j_end(ij)
                DO i=i_start(ij),i_end(ij)
                   IF ( ( XICE(I,J) .GE. XICE_THRESHOLD) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                      !  Weighted average of fields between ice-cover values and open-water values.
                      hfx(i,j)  = ( hfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * hfx_sea(i,j)  )
                      qfx(i,j)  = ( qfx(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * qfx_sea(i,j)  )
                      lh(i,j)   = ( lh(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * lh_sea(i,j)   )
!save old tsk_ice
                      tsk_save(i,j)  = tsk(i,j)
                      tsk(i,j)  = ( tsk(i,j)  * XICE(i,j) ) + ( (1.0-XICE(i,j)) * tsk_sea(i,j)  )
                   ENDIF
                ENDDO
             ENDDO
          ELSE
             DO j = j_start(ij) , j_end(ij)
                DO i = i_start(ij) , i_end(ij)
                   IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
                      ! Compute TSK as the open-water and ice-cover average
                      tsk(i,j) = ( tsk(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * tsk_sea(i,j) )
                   ENDIF
                ENDDO
             ENDDO
          ENDIF
       ENDIF
       ELSE
         CALL wrf_error_fatal('Lacking arguments for SSIB in surface driver')
       ENDIF
!end ssib
!-------------------------------------------------------------------

     CASE DEFAULT

       IF ( itimestep .eq. 1 ) THEN
       WRITE( message , * ) &
        'No land surface physics option is used: sf_surface_physics = ', sf_surface_physics
        CALL wrf_message ( message )
       ENDIF

     END SELECT sfc_select

     ENDDO
     !$OMP END PARALLEL DO

 430 CONTINUE

#if ( EM_CORE==1)
   IF (sf_ocean_physics .EQ. OMLSCHEME .or. sf_ocean_physics .EQ. PWP3DSCHEME) THEN
#ifdef WRF_GPU
     CALL wrf_error_fatal('surface_driver: sf_ocean_physics not ported to the GPU')
#endif
! simple ocean mixed layer model based Pollard, Rhines and Thompson (1973)
     CALL wrf_debug( 100, 'Call OCEANML' )
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )
     DO ij = 1 , num_tiles
        CALL ocean_driver(tml,t0ml,hml,h0ml,huml,hvml,ust,u_phy,v_phy, &
                     tmoml,f,g,oml_gamma,                         &
                     xland,hfx,lh,tsk,gsw,glw,emiss,              &
                     dtbl,STBOLT,oml_relaxation_time,             &
                     ids,ide, jds,jde, kds,kde,                   &
                     ims,ime, jms,jme, kms,kme,                   &
                     i_start(ij),i_end(ij), j_start(ij),j_end(ij), kts,kte, & 
                     sf_ocean_physics,okms, okme,                 & !cyl
                     om_tmp,om_s,om_u, om_v,  om_depth, om_ml,    & !cyl
                     om_lat, om_lon,                              & !cyl
                     QFX,                                         & !cyl 
                     rdx, rdy, msfu, msfv, msft,xtime,            & !cyl 
                     om_tini,om_sini,id,omdt,                     & !cyl 
                     itimestep )                                    !cyl
     ENDDO
     !$OMP END PARALLEL DO
   ENDIF
#endif
! adding a lake model -- 07/02/2010
   IF ( LakeModel == 1 ) THEN
#ifdef WRF_GPU
     CALL wrf_error_fatal('surface_driver: LakeModel not ported to the GPU')
#endif
 
      CALL wrf_debug( 100, 'Call LakeModel' )
 
      DO ij = 1 , num_tiles
 
         CALL Lake(  t_phy        ,p8w            ,dz8w         ,qv_curr         ,&  !i
                     u_phy        ,v_phy          , glw         ,emiss           ,&
                     rainbl       ,dtbl           ,swdown       ,albedo          ,&
                     xlat_urb2d   ,z_lake3d       ,dz_lake3d    ,lakedepth2d     ,&
                     watsat3d     ,csol3d         ,tkmg3d       ,tkdry3d         ,&
                     tksatu3d     ,ivgtyp         ,ht           ,xland           ,&
                     iswater      ,xice           ,xice_threshold, lake_min_elev    ,&
                     ids          ,ide            ,jds          ,jde             ,&
                     kds          ,kde            ,ims          ,ime             ,&
                     jms          ,jme            ,kms          ,kme             ,&
                     i_start(ij)  ,i_end(ij)      ,j_start(ij)  ,j_end(ij)       ,&
                     kts          ,kte                                           ,&
                     h2osno2d     ,snowdp2d       ,snl2d        ,z3d             ,&  !h
                     dz3d         ,zi3d           ,h2osoi_vol3d ,h2osoi_liq3d    ,&
                     h2osoi_ice3d ,t_grnd2d       ,t_soisno3d   ,t_lake3d        ,&
                     savedtke12d  ,lake_icefrac3d                                ,&
#if ( EM_CORE==1)
  !                   lakemask  ,lakeflag                                         ,&
                     lakemask                                           ,&
#endif
                     hfx          ,lh             ,grdflx       ,tsk             ,&  !o
                     qfx          ,t2             ,th2          ,q2 )
 
 
      ENDDO
 
   ENDIF

! Reset RAINBL in mm (Accumulation between PBL calls)

     IF ( PRESENT( rainbl ) ) THEN
#ifdef WRF_GPU
  DO ij = 1, num_tiles
     its = i_start_h(ij)
     ite = i_end_h(ij)
     jts = j_start_h(ij)
     jte = j_end_h(ij)
! K-SD-1..8: RAINBL reset (Template A)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_SURFACE_DRIVER)) default(none) &
!$acc& present(rainbl) &
!$acc& firstprivate(its, ite, jts, jte) &
!$acc& private(i, j)
         DO j=jts,jte
         DO i=its,ite
            RAINBL(i,j) = 0.
         ENDDO
         ENDDO
  ENDDO
#else
       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij, i, j, k )
       DO ij = 1 , num_tiles
         DO j=j_start(ij),j_end(ij)
         DO i=i_start(ij),i_end(ij)
            RAINBL(i,j) = 0.
         ENDDO
         ENDDO
       ENDDO
       !$OMP END PARALLEL DO
#endif
     ENDIF

! Limit Q2 diagnostic to no more than 5 per cent higher than lowest level value
!     This prevents unrealistic values when QFX is not mostly surface flux 
!          because calculation is based on surface flux only
!     Problems occurred in transition periods and weak winds and vegetation source
#ifdef WRF_GPU
  DO ij = 1, num_tiles
     its = i_start_h(ij)
     ite = i_end_h(ij)
     jts = j_start_h(ij)
     jte = j_end_h(ij)
       IF (.NOT. PRESENT(qv_curr)) THEN
          CALL wrf_error_fatal('surface_driver: qv_curr not present')
       END IF
! K-SD-1..8: Q2 cap (Template A)
!$acc parallel loop gang vector collapse(2) if(gpu_on(R_SURFACE_DRIVER)) default(none) &
!$acc& present(q2, xland, qv_curr) &
!$acc& firstprivate(its, ite, jts, jte) &
!$acc& private(i, j)
         DO j=jts,jte
         DO i=its,ite
            IF (XLAND(I,J).LT.1.5) THEN
            Q2(i,j) = MIN(Q2(i,j),1.05*QV_CURR(i,1,j))
            END IF
         ENDDO
         ENDDO
  ENDDO
#else
       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij, i, j, k )
       DO ij = 1 , num_tiles
         DO j=j_start(ij),j_end(ij)
         DO i=i_start(ij),i_end(ij)
            IF (XLAND(I,J).LT.1.5) THEN
            Q2(i,j) = MIN(Q2(i,j),1.05*QV_CURR(i,1,j))
            END IF
         ENDDO
         ENDDO
       ENDDO
       !$OMP END PARALLEL DO
#endif

     IF( PRESENT(slope_rad).AND. radiation )THEN
! topographic slope effects removed from SWDOWN and GSW here for output
       IF (slope_rad .EQ. 1) THEN
#ifdef WRF_GPU
         CALL wrf_error_fatal('surface_driver: slope_rad not ported to the GPU')
#endif

       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij, i, j, k )
       DO ij = 1 , num_tiles
         DO j=j_start(ij),j_end(ij)
         DO i=i_start(ij),i_end(ij)
         IF(SWNORM(I,J) .GT. 1.E-3)THEN  ! daytime
            SWSAVE = SWDOWN(i,j)
! SWDOWN contains unaffected SWDOWN in output
            SWDOWN(i,j) = SWNORM(i,j)
! SWNORM contains slope-affected SWDOWN in output
            SWNORM(i,j) = SWSAVE
            GSW(i,j) = GSWSAVE(i,j)
         ENDIF
         ENDDO
         ENDDO
       ENDDO
       !$OMP END PARALLEL DO

       ENDIF
     ENDIF

     IF (distributed_ahe_opt == 2) THEN
#ifdef WRF_GPU
       CALL wrf_error_fatal('surface_driver: distributed_ahe_opt not ported to the GPU')
#endif
       call cal_mon_day(julday, julyr, jmonth, jday)
       ihour = (jmonth - 1) * 24 + rp_mod(INT(gmt + xtime / 60.0), 24)
       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij, i, j, k )
       DO ij = 1, num_tiles
         DO j = j_start(ij), j_end(ij)
         DO i = i_start(ij), i_end(ij)
           HFX(i, j) = HFX(i, j) + ahe(i, ihour, j)
         END DO
         END DO
       END DO
       !$OMP END PARALLEL DO
     END IF

   ENDIF run_param_if

#ifdef WRF_GPU
      IF (gpu_isl) THEN
        gpu_world_host = .NOT. gpu_world_host
        IF (gpu_world_host) THEN
!$acc update self(sfcheadrt, infxsrt, soldrain, qtiledrain, zwatble2d, acsnom, acsnow, akhs, akms, &
!$acc&   albedo, br, canwat, chklowq, grdflx, gsw, swdown, gz1oz0, hfx, isltyp, ivgtyp, mavail, &
!$acc&   rmol, pblh, pshltr, fm, fhh, psih, psim, q10, q2, qfx, qsfc, qshltr, qz0, sfcevp, sfcexc, &
!$acc&   sfcrunoff, acrunoff, smois, smstav, smstot, snoalb, snow, snowc, snowh, smcrel, th10, th2, &
!$acc&   thz0, tmn, tshltr, tsk, tslb, t_phy, u10, udrunoff, ust, uz0, v10, vegfra, u10e, v10e, &
!$acc&   uoce, voce, vz0, wspd, xice, xland, znt, albsi, icedepth, snowsi, xicem, ct, tke_pbl, &
!$acc&   albbck, embck, lh, sh2o, z0, flqc, flhc, psfc, sst, flx4, fvb, fbur, fgsn, water_depth, &
!$acc&   savedtke12d, snowdp2d, h2osno2d, snl2d, t_grnd2d, t_lake3d, lake_icefrac3d, t_soisno3d, &
!$acc&   h2osoi_ice3d, h2osoi_liq3d, h2osoi_vol3d, z3d, dz3d, zi3d, lakemask, zol)
          IF (PRESENT(acgrdflx)) THEN
!$acc update self(acgrdflx)
          END IF
          IF (PRESENT(achfx)) THEN
!$acc update self(achfx)
          END IF
          IF (PRESENT(aclhf)) THEN
!$acc update self(aclhf)
          END IF
          IF (PRESENT(snowfallac)) THEN
!$acc update self(snowfallac)
          END IF
          IF (PRESENT(tyr)) THEN
!$acc update self(tyr)
          END IF
          IF (PRESENT(tyra)) THEN
!$acc update self(tyra)
          END IF
          IF (PRESENT(tdly)) THEN
!$acc update self(tdly)
          END IF
          IF (PRESENT(tlag)) THEN
!$acc update self(tlag)
          END IF
          IF (PRESENT(sstsk)) THEN
!$acc update self(sstsk)
          END IF
          IF (PRESENT(dtw)) THEN
!$acc update self(dtw)
          END IF
          IF (PRESENT(t2)) THEN
!$acc update self(t2)
          END IF
          IF (PRESENT(emiss)) THEN
!$acc update self(emiss)
          END IF
          IF (PRESENT(landusef)) THEN
!$acc update self(landusef)
          END IF
          IF (PRESENT(soilctop)) THEN
!$acc update self(soilctop)
          END IF
          IF (PRESENT(soilcbot)) THEN
!$acc update self(soilcbot)
          END IF
          IF (PRESENT(ra)) THEN
!$acc update self(ra)
          END IF
          IF (PRESENT(rs)) THEN
!$acc update self(rs)
          END IF
          IF (PRESENT(vegf_px)) THEN
!$acc update self(vegf_px)
          END IF
          IF (PRESENT(lai)) THEN
!$acc update self(lai)
          END IF
          IF (PRESENT(imperv)) THEN
!$acc update self(imperv)
          END IF
          IF (PRESENT(canfra)) THEN
!$acc update self(canfra)
          END IF
          IF (PRESENT(lai_px)) THEN
!$acc update self(lai_px)
          END IF
          IF (PRESENT(wwlt_px)) THEN
!$acc update self(wwlt_px)
          END IF
          IF (PRESENT(wfc_px)) THEN
!$acc update self(wfc_px)
          END IF
          IF (PRESENT(wsat_px)) THEN
!$acc update self(wsat_px)
          END IF
          IF (PRESENT(clay_px)) THEN
!$acc update self(clay_px)
          END IF
          IF (PRESENT(csand_px)) THEN
!$acc update self(csand_px)
          END IF
          IF (PRESENT(fmsand_px)) THEN
!$acc update self(fmsand_px)
          END IF
          IF (PRESENT(isnowxy)) THEN
!$acc update self(isnowxy)
          END IF
          IF (PRESENT(tvxy)) THEN
!$acc update self(tvxy)
          END IF
          IF (PRESENT(tgxy)) THEN
!$acc update self(tgxy)
          END IF
          IF (PRESENT(canicexy)) THEN
!$acc update self(canicexy)
          END IF
          IF (PRESENT(canliqxy)) THEN
!$acc update self(canliqxy)
          END IF
          IF (PRESENT(eahxy)) THEN
!$acc update self(eahxy)
          END IF
          IF (PRESENT(tahxy)) THEN
!$acc update self(tahxy)
          END IF
          IF (PRESENT(cmxy)) THEN
!$acc update self(cmxy)
          END IF
          IF (PRESENT(chxy)) THEN
!$acc update self(chxy)
          END IF
          IF (PRESENT(fwetxy)) THEN
!$acc update self(fwetxy)
          END IF
          IF (PRESENT(sneqvoxy)) THEN
!$acc update self(sneqvoxy)
          END IF
          IF (PRESENT(alboldxy)) THEN
!$acc update self(alboldxy)
          END IF
          IF (PRESENT(qsnowxy)) THEN
!$acc update self(qsnowxy)
          END IF
          IF (PRESENT(qrainxy)) THEN
!$acc update self(qrainxy)
          END IF
          IF (PRESENT(wslakexy)) THEN
!$acc update self(wslakexy)
          END IF
          IF (PRESENT(zwtxy)) THEN
!$acc update self(zwtxy)
          END IF
          IF (PRESENT(waxy)) THEN
!$acc update self(waxy)
          END IF
          IF (PRESENT(wtxy)) THEN
!$acc update self(wtxy)
          END IF
          IF (PRESENT(tsnoxy)) THEN
!$acc update self(tsnoxy)
          END IF
          IF (PRESENT(zsnsoxy)) THEN
!$acc update self(zsnsoxy)
          END IF
          IF (PRESENT(snicexy)) THEN
!$acc update self(snicexy)
          END IF
          IF (PRESENT(snliqxy)) THEN
!$acc update self(snliqxy)
          END IF
          IF (PRESENT(lfmassxy)) THEN
!$acc update self(lfmassxy)
          END IF
          IF (PRESENT(rtmassxy)) THEN
!$acc update self(rtmassxy)
          END IF
          IF (PRESENT(stmassxy)) THEN
!$acc update self(stmassxy)
          END IF
          IF (PRESENT(woodxy)) THEN
!$acc update self(woodxy)
          END IF
          IF (PRESENT(stblcpxy)) THEN
!$acc update self(stblcpxy)
          END IF
          IF (PRESENT(fastcpxy)) THEN
!$acc update self(fastcpxy)
          END IF
          IF (PRESENT(xsaixy)) THEN
!$acc update self(xsaixy)
          END IF
          IF (PRESENT(taussxy)) THEN
!$acc update self(taussxy)
          END IF
          IF (PRESENT(grainxy)) THEN
!$acc update self(grainxy)
          END IF
          IF (PRESENT(gddxy)) THEN
!$acc update self(gddxy)
          END IF
          IF (PRESENT(pgsxy)) THEN
!$acc update self(pgsxy)
          END IF
          IF (PRESENT(t2mvxy)) THEN
!$acc update self(t2mvxy)
          END IF
          IF (PRESENT(t2mbxy)) THEN
!$acc update self(t2mbxy)
          END IF
          IF (PRESENT(q2mvxy)) THEN
!$acc update self(q2mvxy)
          END IF
          IF (PRESENT(q2mbxy)) THEN
!$acc update self(q2mbxy)
          END IF
          IF (PRESENT(tradxy)) THEN
!$acc update self(tradxy)
          END IF
          IF (PRESENT(neexy)) THEN
!$acc update self(neexy)
          END IF
          IF (PRESENT(gppxy)) THEN
!$acc update self(gppxy)
          END IF
          IF (PRESENT(nppxy)) THEN
!$acc update self(nppxy)
          END IF
          IF (PRESENT(fvegxy)) THEN
!$acc update self(fvegxy)
          END IF
          IF (PRESENT(runsfxy)) THEN
!$acc update self(runsfxy)
          END IF
          IF (PRESENT(runsbxy)) THEN
!$acc update self(runsbxy)
          END IF
          IF (PRESENT(ecanxy)) THEN
!$acc update self(ecanxy)
          END IF
          IF (PRESENT(edirxy)) THEN
!$acc update self(edirxy)
          END IF
          IF (PRESENT(etranxy)) THEN
!$acc update self(etranxy)
          END IF
          IF (PRESENT(fsaxy)) THEN
!$acc update self(fsaxy)
          END IF
          IF (PRESENT(firaxy)) THEN
!$acc update self(firaxy)
          END IF
          IF (PRESENT(aparxy)) THEN
!$acc update self(aparxy)
          END IF
          IF (PRESENT(psnxy)) THEN
!$acc update self(psnxy)
          END IF
          IF (PRESENT(savxy)) THEN
!$acc update self(savxy)
          END IF
          IF (PRESENT(sagxy)) THEN
!$acc update self(sagxy)
          END IF
          IF (PRESENT(rssunxy)) THEN
!$acc update self(rssunxy)
          END IF
          IF (PRESENT(rsshaxy)) THEN
!$acc update self(rsshaxy)
          END IF
          IF (PRESENT(bgapxy)) THEN
!$acc update self(bgapxy)
          END IF
          IF (PRESENT(wgapxy)) THEN
!$acc update self(wgapxy)
          END IF
          IF (PRESENT(tgvxy)) THEN
!$acc update self(tgvxy)
          END IF
          IF (PRESENT(tgbxy)) THEN
!$acc update self(tgbxy)
          END IF
          IF (PRESENT(chvxy)) THEN
!$acc update self(chvxy)
          END IF
          IF (PRESENT(chbxy)) THEN
!$acc update self(chbxy)
          END IF
          IF (PRESENT(shgxy)) THEN
!$acc update self(shgxy)
          END IF
          IF (PRESENT(shcxy)) THEN
!$acc update self(shcxy)
          END IF
          IF (PRESENT(shbxy)) THEN
!$acc update self(shbxy)
          END IF
          IF (PRESENT(evgxy)) THEN
!$acc update self(evgxy)
          END IF
          IF (PRESENT(evbxy)) THEN
!$acc update self(evbxy)
          END IF
          IF (PRESENT(ghvxy)) THEN
!$acc update self(ghvxy)
          END IF
          IF (PRESENT(ghbxy)) THEN
!$acc update self(ghbxy)
          END IF
          IF (PRESENT(irgxy)) THEN
!$acc update self(irgxy)
          END IF
          IF (PRESENT(ircxy)) THEN
!$acc update self(ircxy)
          END IF
          IF (PRESENT(irbxy)) THEN
!$acc update self(irbxy)
          END IF
          IF (PRESENT(trxy)) THEN
!$acc update self(trxy)
          END IF
          IF (PRESENT(evcxy)) THEN
!$acc update self(evcxy)
          END IF
          IF (PRESENT(chleafxy)) THEN
!$acc update self(chleafxy)
          END IF
          IF (PRESENT(chucxy)) THEN
!$acc update self(chucxy)
          END IF
          IF (PRESENT(chv2xy)) THEN
!$acc update self(chv2xy)
          END IF
          IF (PRESENT(chb2xy)) THEN
!$acc update self(chb2xy)
          END IF
          IF (PRESENT(chstarxy)) THEN
!$acc update self(chstarxy)
          END IF
          IF (PRESENT(qintsxy)) THEN
!$acc update self(qintsxy)
          END IF
          IF (PRESENT(qintrxy)) THEN
!$acc update self(qintrxy)
          END IF
          IF (PRESENT(qdripsxy)) THEN
!$acc update self(qdripsxy)
          END IF
          IF (PRESENT(qdriprxy)) THEN
!$acc update self(qdriprxy)
          END IF
          IF (PRESENT(qthrosxy)) THEN
!$acc update self(qthrosxy)
          END IF
          IF (PRESENT(qthrorxy)) THEN
!$acc update self(qthrorxy)
          END IF
          IF (PRESENT(qsnsubxy)) THEN
!$acc update self(qsnsubxy)
          END IF
          IF (PRESENT(qsnfroxy)) THEN
!$acc update self(qsnfroxy)
          END IF
          IF (PRESENT(qsubcxy)) THEN
!$acc update self(qsubcxy)
          END IF
          IF (PRESENT(qfrocxy)) THEN
!$acc update self(qfrocxy)
          END IF
          IF (PRESENT(qevacxy)) THEN
!$acc update self(qevacxy)
          END IF
          IF (PRESENT(qdewcxy)) THEN
!$acc update self(qdewcxy)
          END IF
          IF (PRESENT(qfrzcxy)) THEN
!$acc update self(qfrzcxy)
          END IF
          IF (PRESENT(qmeltcxy)) THEN
!$acc update self(qmeltcxy)
          END IF
          IF (PRESENT(qsnbotxy)) THEN
!$acc update self(qsnbotxy)
          END IF
          IF (PRESENT(pondingxy)) THEN
!$acc update self(pondingxy)
          END IF
          IF (PRESENT(pahxy)) THEN
!$acc update self(pahxy)
          END IF
          IF (PRESENT(pahgxy)) THEN
!$acc update self(pahgxy)
          END IF
          IF (PRESENT(pahvxy)) THEN
!$acc update self(pahvxy)
          END IF
          IF (PRESENT(pahbxy)) THEN
!$acc update self(pahbxy)
          END IF
          IF (PRESENT(qmeltxy)) THEN
!$acc update self(qmeltxy)
          END IF
          IF (PRESENT(fpicexy)) THEN
!$acc update self(fpicexy)
          END IF
          IF (PRESENT(rainlsm)) THEN
!$acc update self(rainlsm)
          END IF
          IF (PRESENT(snowlsm)) THEN
!$acc update self(snowlsm)
          END IF
          IF (PRESENT(forctlsm)) THEN
!$acc update self(forctlsm)
          END IF
          IF (PRESENT(forcqlsm)) THEN
!$acc update self(forcqlsm)
          END IF
          IF (PRESENT(forcplsm)) THEN
!$acc update self(forcplsm)
          END IF
          IF (PRESENT(forczlsm)) THEN
!$acc update self(forczlsm)
          END IF
          IF (PRESENT(forcwlsm)) THEN
!$acc update self(forcwlsm)
          END IF
          IF (PRESENT(acc_ssoil)) THEN
!$acc update self(acc_ssoil)
          END IF
          IF (PRESENT(acc_qinsur)) THEN
!$acc update self(acc_qinsur)
          END IF
          IF (PRESENT(acc_qseva)) THEN
!$acc update self(acc_qseva)
          END IF
          IF (PRESENT(acc_etrani)) THEN
!$acc update self(acc_etrani)
          END IF
          IF (PRESENT(eflxbxy)) THEN
!$acc update self(eflxbxy)
          END IF
          IF (PRESENT(soilenergy)) THEN
!$acc update self(soilenergy)
          END IF
          IF (PRESENT(snowenergy)) THEN
!$acc update self(snowenergy)
          END IF
          IF (PRESENT(canhsxy)) THEN
!$acc update self(canhsxy)
          END IF
          IF (PRESENT(acc_dwaterxy)) THEN
!$acc update self(acc_dwaterxy)
          END IF
          IF (PRESENT(acc_prcpxy)) THEN
!$acc update self(acc_prcpxy)
          END IF
          IF (PRESENT(acc_ecanxy)) THEN
!$acc update self(acc_ecanxy)
          END IF
          IF (PRESENT(acc_etranxy)) THEN
!$acc update self(acc_etranxy)
          END IF
          IF (PRESENT(acc_edirxy)) THEN
!$acc update self(acc_edirxy)
          END IF
          IF (PRESENT(irnumsi)) THEN
!$acc update self(irnumsi)
          END IF
          IF (PRESENT(irnummi)) THEN
!$acc update self(irnummi)
          END IF
          IF (PRESENT(irnumfi)) THEN
!$acc update self(irnumfi)
          END IF
          IF (PRESENT(irwatsi)) THEN
!$acc update self(irwatsi)
          END IF
          IF (PRESENT(irwatmi)) THEN
!$acc update self(irwatmi)
          END IF
          IF (PRESENT(irwatfi)) THEN
!$acc update self(irwatfi)
          END IF
          IF (PRESENT(ireloss)) THEN
!$acc update self(ireloss)
          END IF
          IF (PRESENT(irsivol)) THEN
!$acc update self(irsivol)
          END IF
          IF (PRESENT(irmivol)) THEN
!$acc update self(irmivol)
          END IF
          IF (PRESENT(irfivol)) THEN
!$acc update self(irfivol)
          END IF
          IF (PRESENT(irrsplh)) THEN
!$acc update self(irrsplh)
          END IF
          IF (PRESENT(qtdrain)) THEN
!$acc update self(qtdrain)
          END IF
          IF (PRESENT(smcwtdxy)) THEN
!$acc update self(smcwtdxy)
          END IF
          IF (PRESENT(rechxy)) THEN
!$acc update self(rechxy)
          END IF
          IF (PRESENT(deeprechxy)) THEN
!$acc update self(deeprechxy)
          END IF
          IF (PRESENT(fdepthxy)) THEN
!$acc update self(fdepthxy)
          END IF
          IF (PRESENT(areaxy)) THEN
!$acc update self(areaxy)
          END IF
          IF (PRESENT(rivercondxy)) THEN
!$acc update self(rivercondxy)
          END IF
          IF (PRESENT(riverbedxy)) THEN
!$acc update self(riverbedxy)
          END IF
          IF (PRESENT(eqzwt)) THEN
!$acc update self(eqzwt)
          END IF
          IF (PRESENT(pexpxy)) THEN
!$acc update self(pexpxy)
          END IF
          IF (PRESENT(qrfxy)) THEN
!$acc update self(qrfxy)
          END IF
          IF (PRESENT(qspringxy)) THEN
!$acc update self(qspringxy)
          END IF
          IF (PRESENT(qslatxy)) THEN
!$acc update self(qslatxy)
          END IF
          IF (PRESENT(qrfsxy)) THEN
!$acc update self(qrfsxy)
          END IF
          IF (PRESENT(qlatxy)) THEN
!$acc update self(qlatxy)
          END IF
          IF (PRESENT(qspringsxy)) THEN
!$acc update self(qspringsxy)
          END IF
          IF (PRESENT(smoiseq)) THEN
!$acc update self(smoiseq)
          END IF
          IF (PRESENT(gecros_state)) THEN
!$acc update self(gecros_state)
          END IF
          IF (PRESENT(ch)) THEN
!$acc update self(ch)
          END IF
          IF (PRESENT(fgdp)) THEN
!$acc update self(fgdp)
          END IF
          IF (PRESENT(dfgdp)) THEN
!$acc update self(dfgdp)
          END IF
          IF (PRESENT(vdfg)) THEN
!$acc update self(vdfg)
          END IF
          IF (PRESENT(om_tmp)) THEN
!$acc update self(om_tmp)
          END IF
          IF (PRESENT(om_s)) THEN
!$acc update self(om_s)
          END IF
          IF (PRESENT(om_u)) THEN
!$acc update self(om_u)
          END IF
          IF (PRESENT(om_v)) THEN
!$acc update self(om_v)
          END IF
          IF (PRESENT(om_depth)) THEN
!$acc update self(om_depth)
          END IF
          IF (PRESENT(om_ml)) THEN
!$acc update self(om_ml)
          END IF
          IF (PRESENT(om_lon)) THEN
!$acc update self(om_lon)
          END IF
          IF (PRESENT(om_lat)) THEN
!$acc update self(om_lat)
          END IF
#if (WRF_CHEM == 1)
          IF (PRESENT(e_bio)) THEN
!$acc update self(e_bio)
          END IF
#endif
          IF (PRESENT(numc)) THEN
!$acc update self(numc)
          END IF
          IF (PRESENT(nump)) THEN
!$acc update self(nump)
          END IF
          IF (PRESENT(sabv)) THEN
!$acc update self(sabv)
          END IF
          IF (PRESENT(sabg)) THEN
!$acc update self(sabg)
          END IF
          IF (PRESENT(lwup)) THEN
!$acc update self(lwup)
          END IF
          IF (PRESENT(snl)) THEN
!$acc update self(snl)
          END IF
          IF (PRESENT(snowdp)) THEN
!$acc update self(snowdp)
          END IF
          IF (PRESENT(wtc)) THEN
!$acc update self(wtc)
          END IF
          IF (PRESENT(wtp)) THEN
!$acc update self(wtp)
          END IF
          IF (PRESENT(h2osno)) THEN
!$acc update self(h2osno)
          END IF
          IF (PRESENT(t_grnd)) THEN
!$acc update self(t_grnd)
          END IF
          IF (PRESENT(t_veg)) THEN
!$acc update self(t_veg)
          END IF
          IF (PRESENT(h2ocan)) THEN
!$acc update self(h2ocan)
          END IF
          IF (PRESENT(h2ocan_col)) THEN
!$acc update self(h2ocan_col)
          END IF
          IF (PRESENT(t2m_max)) THEN
!$acc update self(t2m_max)
          END IF
          IF (PRESENT(t2m_min)) THEN
!$acc update self(t2m_min)
          END IF
          IF (PRESENT(t2clm)) THEN
!$acc update self(t2clm)
          END IF
          IF (PRESENT(t_ref2m)) THEN
!$acc update self(t_ref2m)
          END IF
          IF (PRESENT(h2osoi_liq_s1)) THEN
!$acc update self(h2osoi_liq_s1)
          END IF
          IF (PRESENT(h2osoi_liq_s2)) THEN
!$acc update self(h2osoi_liq_s2)
          END IF
          IF (PRESENT(h2osoi_liq_s3)) THEN
!$acc update self(h2osoi_liq_s3)
          END IF
          IF (PRESENT(h2osoi_liq_s4)) THEN
!$acc update self(h2osoi_liq_s4)
          END IF
          IF (PRESENT(h2osoi_liq_s5)) THEN
!$acc update self(h2osoi_liq_s5)
          END IF
          IF (PRESENT(h2osoi_liq1)) THEN
!$acc update self(h2osoi_liq1)
          END IF
          IF (PRESENT(h2osoi_liq2)) THEN
!$acc update self(h2osoi_liq2)
          END IF
          IF (PRESENT(h2osoi_liq3)) THEN
!$acc update self(h2osoi_liq3)
          END IF
          IF (PRESENT(h2osoi_liq4)) THEN
!$acc update self(h2osoi_liq4)
          END IF
          IF (PRESENT(h2osoi_liq5)) THEN
!$acc update self(h2osoi_liq5)
          END IF
          IF (PRESENT(h2osoi_liq6)) THEN
!$acc update self(h2osoi_liq6)
          END IF
          IF (PRESENT(h2osoi_liq7)) THEN
!$acc update self(h2osoi_liq7)
          END IF
          IF (PRESENT(h2osoi_liq8)) THEN
!$acc update self(h2osoi_liq8)
          END IF
          IF (PRESENT(h2osoi_liq9)) THEN
!$acc update self(h2osoi_liq9)
          END IF
          IF (PRESENT(h2osoi_liq10)) THEN
!$acc update self(h2osoi_liq10)
          END IF
          IF (PRESENT(h2osoi_ice_s1)) THEN
!$acc update self(h2osoi_ice_s1)
          END IF
          IF (PRESENT(h2osoi_ice_s2)) THEN
!$acc update self(h2osoi_ice_s2)
          END IF
          IF (PRESENT(h2osoi_ice_s3)) THEN
!$acc update self(h2osoi_ice_s3)
          END IF
          IF (PRESENT(h2osoi_ice_s4)) THEN
!$acc update self(h2osoi_ice_s4)
          END IF
          IF (PRESENT(h2osoi_ice_s5)) THEN
!$acc update self(h2osoi_ice_s5)
          END IF
          IF (PRESENT(h2osoi_ice1)) THEN
!$acc update self(h2osoi_ice1)
          END IF
          IF (PRESENT(h2osoi_ice2)) THEN
!$acc update self(h2osoi_ice2)
          END IF
          IF (PRESENT(h2osoi_ice3)) THEN
!$acc update self(h2osoi_ice3)
          END IF
          IF (PRESENT(h2osoi_ice4)) THEN
!$acc update self(h2osoi_ice4)
          END IF
          IF (PRESENT(h2osoi_ice5)) THEN
!$acc update self(h2osoi_ice5)
          END IF
          IF (PRESENT(h2osoi_ice6)) THEN
!$acc update self(h2osoi_ice6)
          END IF
          IF (PRESENT(h2osoi_ice7)) THEN
!$acc update self(h2osoi_ice7)
          END IF
          IF (PRESENT(h2osoi_ice8)) THEN
!$acc update self(h2osoi_ice8)
          END IF
          IF (PRESENT(h2osoi_ice9)) THEN
!$acc update self(h2osoi_ice9)
          END IF
          IF (PRESENT(h2osoi_ice10)) THEN
!$acc update self(h2osoi_ice10)
          END IF
          IF (PRESENT(t_soisno_s1)) THEN
!$acc update self(t_soisno_s1)
          END IF
          IF (PRESENT(t_soisno_s2)) THEN
!$acc update self(t_soisno_s2)
          END IF
          IF (PRESENT(t_soisno_s3)) THEN
!$acc update self(t_soisno_s3)
          END IF
          IF (PRESENT(t_soisno_s4)) THEN
!$acc update self(t_soisno_s4)
          END IF
          IF (PRESENT(t_soisno_s5)) THEN
!$acc update self(t_soisno_s5)
          END IF
          IF (PRESENT(t_soisno1)) THEN
!$acc update self(t_soisno1)
          END IF
          IF (PRESENT(t_soisno2)) THEN
!$acc update self(t_soisno2)
          END IF
          IF (PRESENT(t_soisno3)) THEN
!$acc update self(t_soisno3)
          END IF
          IF (PRESENT(t_soisno4)) THEN
!$acc update self(t_soisno4)
          END IF
          IF (PRESENT(t_soisno5)) THEN
!$acc update self(t_soisno5)
          END IF
          IF (PRESENT(t_soisno6)) THEN
!$acc update self(t_soisno6)
          END IF
          IF (PRESENT(t_soisno7)) THEN
!$acc update self(t_soisno7)
          END IF
          IF (PRESENT(t_soisno8)) THEN
!$acc update self(t_soisno8)
          END IF
          IF (PRESENT(t_soisno9)) THEN
!$acc update self(t_soisno9)
          END IF
          IF (PRESENT(t_soisno10)) THEN
!$acc update self(t_soisno10)
          END IF
          IF (PRESENT(dzsnow1)) THEN
!$acc update self(dzsnow1)
          END IF
          IF (PRESENT(dzsnow2)) THEN
!$acc update self(dzsnow2)
          END IF
          IF (PRESENT(dzsnow3)) THEN
!$acc update self(dzsnow3)
          END IF
          IF (PRESENT(dzsnow4)) THEN
!$acc update self(dzsnow4)
          END IF
          IF (PRESENT(dzsnow5)) THEN
!$acc update self(dzsnow5)
          END IF
          IF (PRESENT(snowrds1)) THEN
!$acc update self(snowrds1)
          END IF
          IF (PRESENT(snowrds2)) THEN
!$acc update self(snowrds2)
          END IF
          IF (PRESENT(snowrds3)) THEN
!$acc update self(snowrds3)
          END IF
          IF (PRESENT(snowrds4)) THEN
!$acc update self(snowrds4)
          END IF
          IF (PRESENT(snowrds5)) THEN
!$acc update self(snowrds5)
          END IF
          IF (PRESENT(t_lake1)) THEN
!$acc update self(t_lake1)
          END IF
          IF (PRESENT(t_lake2)) THEN
!$acc update self(t_lake2)
          END IF
          IF (PRESENT(t_lake3)) THEN
!$acc update self(t_lake3)
          END IF
          IF (PRESENT(t_lake4)) THEN
!$acc update self(t_lake4)
          END IF
          IF (PRESENT(t_lake5)) THEN
!$acc update self(t_lake5)
          END IF
          IF (PRESENT(t_lake6)) THEN
!$acc update self(t_lake6)
          END IF
          IF (PRESENT(t_lake7)) THEN
!$acc update self(t_lake7)
          END IF
          IF (PRESENT(t_lake8)) THEN
!$acc update self(t_lake8)
          END IF
          IF (PRESENT(t_lake9)) THEN
!$acc update self(t_lake9)
          END IF
          IF (PRESENT(t_lake10)) THEN
!$acc update self(t_lake10)
          END IF
          IF (PRESENT(h2osoi_vol1)) THEN
!$acc update self(h2osoi_vol1)
          END IF
          IF (PRESENT(h2osoi_vol2)) THEN
!$acc update self(h2osoi_vol2)
          END IF
          IF (PRESENT(h2osoi_vol3)) THEN
!$acc update self(h2osoi_vol3)
          END IF
          IF (PRESENT(h2osoi_vol4)) THEN
!$acc update self(h2osoi_vol4)
          END IF
          IF (PRESENT(h2osoi_vol5)) THEN
!$acc update self(h2osoi_vol5)
          END IF
          IF (PRESENT(h2osoi_vol6)) THEN
!$acc update self(h2osoi_vol6)
          END IF
          IF (PRESENT(h2osoi_vol7)) THEN
!$acc update self(h2osoi_vol7)
          END IF
          IF (PRESENT(h2osoi_vol8)) THEN
!$acc update self(h2osoi_vol8)
          END IF
          IF (PRESENT(h2osoi_vol9)) THEN
!$acc update self(h2osoi_vol9)
          END IF
          IF (PRESENT(h2osoi_vol10)) THEN
!$acc update self(h2osoi_vol10)
          END IF
          IF (PRESENT(albedosubgrid)) THEN
!$acc update self(albedosubgrid)
          END IF
          IF (PRESENT(lhsubgrid)) THEN
!$acc update self(lhsubgrid)
          END IF
          IF (PRESENT(hfxsubgrid)) THEN
!$acc update self(hfxsubgrid)
          END IF
          IF (PRESENT(lwupsubgrid)) THEN
!$acc update self(lwupsubgrid)
          END IF
          IF (PRESENT(q2subgrid)) THEN
!$acc update self(q2subgrid)
          END IF
          IF (PRESENT(sabvsubgrid)) THEN
!$acc update self(sabvsubgrid)
          END IF
          IF (PRESENT(sabgsubgrid)) THEN
!$acc update self(sabgsubgrid)
          END IF
          IF (PRESENT(nrasubgrid)) THEN
!$acc update self(nrasubgrid)
          END IF
          IF (PRESENT(swupsubgrid)) THEN
!$acc update self(swupsubgrid)
          END IF
          IF (PRESENT(lhsoi)) THEN
!$acc update self(lhsoi)
          END IF
          IF (PRESENT(lhveg)) THEN
!$acc update self(lhveg)
          END IF
          IF (PRESENT(lhtran)) THEN
!$acc update self(lhtran)
          END IF
          IF (PRESENT(t_veg24)) THEN
!$acc update self(t_veg24)
          END IF
          IF (PRESENT(t_veg240)) THEN
!$acc update self(t_veg240)
          END IF
          IF (PRESENT(fsun24)) THEN
!$acc update self(fsun24)
          END IF
          IF (PRESENT(fsun240)) THEN
!$acc update self(fsun240)
          END IF
          IF (PRESENT(fsd24)) THEN
!$acc update self(fsd24)
          END IF
          IF (PRESENT(fsd240)) THEN
!$acc update self(fsd240)
          END IF
          IF (PRESENT(fsi24)) THEN
!$acc update self(fsi24)
          END IF
          IF (PRESENT(fsi240)) THEN
!$acc update self(fsi240)
          END IF
          IF (PRESENT(laip)) THEN
!$acc update self(laip)
          END IF
#ifdef CN
          IF (PRESENT(dyntlai)) THEN
!$acc update self(dyntlai)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dyntsai)) THEN
!$acc update self(dyntsai)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dyntop)) THEN
!$acc update self(dyntop)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dynbot)) THEN
!$acc update self(dynbot)
          END IF
#endif
#ifdef CN
          IF (PRESENT(htmx)) THEN
!$acc update self(htmx)
          END IF
#endif
#ifdef CN
          IF (PRESENT(croplive)) THEN
!$acc update self(croplive)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd1020)) THEN
!$acc update self(gdd1020)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd820)) THEN
!$acc update self(gdd820)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd020)) THEN
!$acc update self(gdd020)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc)) THEN
!$acc update self(grainc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc_storage)) THEN
!$acc update self(grainc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc_xfer)) THEN
!$acc update self(grainc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn)) THEN
!$acc update self(grainn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn_storage)) THEN
!$acc update self(grainn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn_xfer)) THEN
!$acc update self(grainn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(days_active)) THEN
!$acc update self(days_active)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_flag)) THEN
!$acc update self(onset_flag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_counter)) THEN
!$acc update self(onset_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_gddflag)) THEN
!$acc update self(onset_gddflag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_fdd)) THEN
!$acc update self(onset_fdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_gdd)) THEN
!$acc update self(onset_gdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_swi)) THEN
!$acc update self(onset_swi)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_flag)) THEN
!$acc update self(offset_flag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_counter)) THEN
!$acc update self(offset_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_fdd)) THEN
!$acc update self(offset_fdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_swi)) THEN
!$acc update self(offset_swi)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dayl)) THEN
!$acc update self(dayl)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annavg_t2m)) THEN
!$acc update self(annavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempavg_t2m)) THEN
!$acc update self(tempavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempsum_potential_gpp)) THEN
!$acc update self(tempsum_potential_gpp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_potential_gpp)) THEN
!$acc update self(annsum_potential_gpp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempmax_retransn)) THEN
!$acc update self(tempmax_retransn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annmax_retransn)) THEN
!$acc update self(annmax_retransn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prev_leafc_to_litter)) THEN
!$acc update self(prev_leafc_to_litter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prev_frootc_to_litter)) THEN
!$acc update self(prev_frootc_to_litter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempsum_npp)) THEN
!$acc update self(tempsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_npp)) THEN
!$acc update self(annsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc)) THEN
!$acc update self(leafc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc_storage)) THEN
!$acc update self(leafc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc_xfer)) THEN
!$acc update self(leafc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc)) THEN
!$acc update self(frootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc_storage)) THEN
!$acc update self(frootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc_xfer)) THEN
!$acc update self(frootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc)) THEN
!$acc update self(livestemc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc_storage)) THEN
!$acc update self(livestemc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc_xfer)) THEN
!$acc update self(livestemc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc)) THEN
!$acc update self(deadstemc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc_storage)) THEN
!$acc update self(deadstemc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc_xfer)) THEN
!$acc update self(deadstemc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc)) THEN
!$acc update self(livecrootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc_storage)) THEN
!$acc update self(livecrootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc_xfer)) THEN
!$acc update self(livecrootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc)) THEN
!$acc update self(deadcrootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc_storage)) THEN
!$acc update self(deadcrootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc_xfer)) THEN
!$acc update self(deadcrootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cpool)) THEN
!$acc update self(cpool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(pft_ctrunc)) THEN
!$acc update self(pft_ctrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn)) THEN
!$acc update self(leafn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn_storage)) THEN
!$acc update self(leafn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn_xfer)) THEN
!$acc update self(leafn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn)) THEN
!$acc update self(frootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn_storage)) THEN
!$acc update self(frootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn_xfer)) THEN
!$acc update self(frootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn)) THEN
!$acc update self(livestemn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn_storage)) THEN
!$acc update self(livestemn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn_xfer)) THEN
!$acc update self(livestemn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn)) THEN
!$acc update self(deadstemn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn_storage)) THEN
!$acc update self(deadstemn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn_xfer)) THEN
!$acc update self(deadstemn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn)) THEN
!$acc update self(livecrootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn_storage)) THEN
!$acc update self(livecrootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn_xfer)) THEN
!$acc update self(livecrootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn)) THEN
!$acc update self(deadcrootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn_storage)) THEN
!$acc update self(deadcrootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn_xfer)) THEN
!$acc update self(deadcrootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(npool)) THEN
!$acc update self(npool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(pft_ntrunc)) THEN
!$acc update self(pft_ntrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gresp_storage)) THEN
!$acc update self(gresp_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gresp_xfer)) THEN
!$acc update self(gresp_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(xsmrpool)) THEN
!$acc update self(xsmrpool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_counter)) THEN
!$acc update self(annsum_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cannsum_npp)) THEN
!$acc update self(cannsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cannavg_t2m)) THEN
!$acc update self(cannavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(wf)) THEN
!$acc update self(wf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(me)) THEN
!$acc update self(me)
          END IF
#endif
#ifdef CN
          IF (PRESENT(mean_fire_prob)) THEN
!$acc update self(mean_fire_prob)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cwdc)) THEN
!$acc update self(cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr1c)) THEN
!$acc update self(litr1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr2c)) THEN
!$acc update self(litr2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr3c)) THEN
!$acc update self(litr3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil1c)) THEN
!$acc update self(soil1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil2c)) THEN
!$acc update self(soil2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil3c)) THEN
!$acc update self(soil3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil4c)) THEN
!$acc update self(soil4c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(seedc)) THEN
!$acc update self(seedc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(col_ctrunc)) THEN
!$acc update self(col_ctrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod10c)) THEN
!$acc update self(prod10c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100c)) THEN
!$acc update self(prod100c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cwdn)) THEN
!$acc update self(cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr1n)) THEN
!$acc update self(litr1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr2n)) THEN
!$acc update self(litr2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr3n)) THEN
!$acc update self(litr3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil1n)) THEN
!$acc update self(soil1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil2n)) THEN
!$acc update self(soil2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil3n)) THEN
!$acc update self(soil3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil4n)) THEN
!$acc update self(soil4n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(seedn)) THEN
!$acc update self(seedn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(col_ntrunc)) THEN
!$acc update self(col_ntrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod10n)) THEN
!$acc update self(prod10n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100n)) THEN
!$acc update self(prod100n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(sminn)) THEN
!$acc update self(sminn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(totlitc)) THEN
!$acc update self(totlitc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedc_to_leaf)) THEN
!$acc update self(dwt_seedc_to_leaf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedc_to_deadstem)) THEN
!$acc update self(dwt_seedc_to_deadstem)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_conv_cflux)) THEN
!$acc update self(dwt_conv_cflux)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod10c_gain)) THEN
!$acc update self(dwt_prod10c_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod100c_gain)) THEN
!$acc update self(dwt_prod100c_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100c_loss)) THEN
!$acc update self(prod100c_loss)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr1c)) THEN
!$acc update self(dwt_frootc_to_litr1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr2c)) THEN
!$acc update self(dwt_frootc_to_litr2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr3c)) THEN
!$acc update self(dwt_frootc_to_litr3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_livecrootc_to_cwdc)) THEN
!$acc update self(dwt_livecrootc_to_cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_deadcrootc_to_cwdc)) THEN
!$acc update self(dwt_deadcrootc_to_cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedn_to_leaf)) THEN
!$acc update self(dwt_seedn_to_leaf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedn_to_deadstem)) THEN
!$acc update self(dwt_seedn_to_deadstem)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_conv_nflux)) THEN
!$acc update self(dwt_conv_nflux)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod10n_gain)) THEN
!$acc update self(dwt_prod10n_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod100n_gain)) THEN
!$acc update self(dwt_prod100n_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100n_loss)) THEN
!$acc update self(prod100n_loss)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr1n)) THEN
!$acc update self(dwt_frootn_to_litr1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr2n)) THEN
!$acc update self(dwt_frootn_to_litr2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr3n)) THEN
!$acc update self(dwt_frootn_to_litr3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_livecrootn_to_cwdn)) THEN
!$acc update self(dwt_livecrootn_to_cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_deadcrootn_to_cwdn)) THEN
!$acc update self(dwt_deadcrootn_to_cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(retransn)) THEN
!$acc update self(retransn)
          END IF
#endif
          IF (PRESENT(swnorm)) THEN
!$acc update self(swnorm)
          END IF
          IF (PRESENT(tr_urb2d)) THEN
!$acc update self(tr_urb2d)
          END IF
          IF (PRESENT(tb_urb2d)) THEN
!$acc update self(tb_urb2d)
          END IF
          IF (PRESENT(tg_urb2d)) THEN
!$acc update self(tg_urb2d)
          END IF
          IF (PRESENT(tc_urb2d)) THEN
!$acc update self(tc_urb2d)
          END IF
          IF (PRESENT(qc_urb2d)) THEN
!$acc update self(qc_urb2d)
          END IF
          IF (PRESENT(uc_urb2d)) THEN
!$acc update self(uc_urb2d)
          END IF
          IF (PRESENT(xxxr_urb2d)) THEN
!$acc update self(xxxr_urb2d)
          END IF
          IF (PRESENT(xxxb_urb2d)) THEN
!$acc update self(xxxb_urb2d)
          END IF
          IF (PRESENT(xxxg_urb2d)) THEN
!$acc update self(xxxg_urb2d)
          END IF
          IF (PRESENT(xxxc_urb2d)) THEN
!$acc update self(xxxc_urb2d)
          END IF
          IF (PRESENT(cmcr_urb2d)) THEN
!$acc update self(cmcr_urb2d)
          END IF
          IF (PRESENT(tgr_urb2d)) THEN
!$acc update self(tgr_urb2d)
          END IF
          IF (PRESENT(tgrl_urb3d)) THEN
!$acc update self(tgrl_urb3d)
          END IF
          IF (PRESENT(smr_urb3d)) THEN
!$acc update self(smr_urb3d)
          END IF
          IF (PRESENT(drelr_urb2d)) THEN
!$acc update self(drelr_urb2d)
          END IF
          IF (PRESENT(drelb_urb2d)) THEN
!$acc update self(drelb_urb2d)
          END IF
          IF (PRESENT(drelg_urb2d)) THEN
!$acc update self(drelg_urb2d)
          END IF
          IF (PRESENT(flxhumr_urb2d)) THEN
!$acc update self(flxhumr_urb2d)
          END IF
          IF (PRESENT(flxhumb_urb2d)) THEN
!$acc update self(flxhumb_urb2d)
          END IF
          IF (PRESENT(flxhumg_urb2d)) THEN
!$acc update self(flxhumg_urb2d)
          END IF
          IF (PRESENT(trl_urb3d)) THEN
!$acc update self(trl_urb3d)
          END IF
          IF (PRESENT(tbl_urb3d)) THEN
!$acc update self(tbl_urb3d)
          END IF
          IF (PRESENT(tgl_urb3d)) THEN
!$acc update self(tgl_urb3d)
          END IF
          IF (PRESENT(sh_urb2d)) THEN
!$acc update self(sh_urb2d)
          END IF
          IF (PRESENT(lh_urb2d)) THEN
!$acc update self(lh_urb2d)
          END IF
          IF (PRESENT(g_urb2d)) THEN
!$acc update self(g_urb2d)
          END IF
          IF (PRESENT(rn_urb2d)) THEN
!$acc update self(rn_urb2d)
          END IF
          IF (PRESENT(ts_urb2d)) THEN
!$acc update self(ts_urb2d)
          END IF
          IF (PRESENT(frc_urb2d)) THEN
!$acc update self(frc_urb2d)
          END IF
          IF (PRESENT(utype_urb2d)) THEN
!$acc update self(utype_urb2d)
          END IF
          IF (PRESENT(cmr_sfcdif)) THEN
!$acc update self(cmr_sfcdif)
          END IF
          IF (PRESENT(chr_sfcdif)) THEN
!$acc update self(chr_sfcdif)
          END IF
          IF (PRESENT(cmc_sfcdif)) THEN
!$acc update self(cmc_sfcdif)
          END IF
          IF (PRESENT(chc_sfcdif)) THEN
!$acc update self(chc_sfcdif)
          END IF
          IF (PRESENT(cmgr_sfcdif)) THEN
!$acc update self(cmgr_sfcdif)
          END IF
          IF (PRESENT(chgr_sfcdif)) THEN
!$acc update self(chgr_sfcdif)
          END IF
          IF (PRESENT(alswvisdir)) THEN
!$acc update self(alswvisdir)
          END IF
          IF (PRESENT(alswvisdif)) THEN
!$acc update self(alswvisdif)
          END IF
          IF (PRESENT(alswnirdir)) THEN
!$acc update self(alswnirdir)
          END IF
          IF (PRESENT(alswnirdif)) THEN
!$acc update self(alswnirdif)
          END IF
          IF (PRESENT(ssib_br)) THEN
!$acc update self(ssib_br)
          END IF
          IF (PRESENT(ssib_fm)) THEN
!$acc update self(ssib_fm)
          END IF
          IF (PRESENT(ssib_fh)) THEN
!$acc update self(ssib_fh)
          END IF
          IF (PRESENT(ssib_cm)) THEN
!$acc update self(ssib_cm)
          END IF
          IF (PRESENT(ssibxdd)) THEN
!$acc update self(ssibxdd)
          END IF
          IF (PRESENT(ssib_lhf)) THEN
!$acc update self(ssib_lhf)
          END IF
          IF (PRESENT(ssib_shf)) THEN
!$acc update self(ssib_shf)
          END IF
          IF (PRESENT(ssib_ghf)) THEN
!$acc update self(ssib_ghf)
          END IF
          IF (PRESENT(ssib_egs)) THEN
!$acc update self(ssib_egs)
          END IF
          IF (PRESENT(ssib_eci)) THEN
!$acc update self(ssib_eci)
          END IF
          IF (PRESENT(ssib_ect)) THEN
!$acc update self(ssib_ect)
          END IF
          IF (PRESENT(ssib_egi)) THEN
!$acc update self(ssib_egi)
          END IF
          IF (PRESENT(ssib_egt)) THEN
!$acc update self(ssib_egt)
          END IF
          IF (PRESENT(ssib_sdn)) THEN
!$acc update self(ssib_sdn)
          END IF
          IF (PRESENT(ssib_sup)) THEN
!$acc update self(ssib_sup)
          END IF
          IF (PRESENT(ssib_ldn)) THEN
!$acc update self(ssib_ldn)
          END IF
          IF (PRESENT(ssib_lup)) THEN
!$acc update self(ssib_lup)
          END IF
          IF (PRESENT(ssib_wat)) THEN
!$acc update self(ssib_wat)
          END IF
          IF (PRESENT(ssib_shc)) THEN
!$acc update self(ssib_shc)
          END IF
          IF (PRESENT(ssib_shg)) THEN
!$acc update self(ssib_shg)
          END IF
          IF (PRESENT(ssib_lai)) THEN
!$acc update self(ssib_lai)
          END IF
          IF (PRESENT(ssib_vcf)) THEN
!$acc update self(ssib_vcf)
          END IF
          IF (PRESENT(ssib_z00)) THEN
!$acc update self(ssib_z00)
          END IF
          IF (PRESENT(ssib_veg)) THEN
!$acc update self(ssib_veg)
          END IF
          IF (PRESENT(isnow)) THEN
!$acc update self(isnow)
          END IF
          IF (PRESENT(swe)) THEN
!$acc update self(swe)
          END IF
          IF (PRESENT(snowden)) THEN
!$acc update self(snowden)
          END IF
          IF (PRESENT(snowdepth)) THEN
!$acc update self(snowdepth)
          END IF
          IF (PRESENT(tkair)) THEN
!$acc update self(tkair)
          END IF
          IF (PRESENT(dzo1)) THEN
!$acc update self(dzo1)
          END IF
          IF (PRESENT(wo1)) THEN
!$acc update self(wo1)
          END IF
          IF (PRESENT(tssn1)) THEN
!$acc update self(tssn1)
          END IF
          IF (PRESENT(tssno1)) THEN
!$acc update self(tssno1)
          END IF
          IF (PRESENT(bwo1)) THEN
!$acc update self(bwo1)
          END IF
          IF (PRESENT(bto1)) THEN
!$acc update self(bto1)
          END IF
          IF (PRESENT(cto1)) THEN
!$acc update self(cto1)
          END IF
          IF (PRESENT(fio1)) THEN
!$acc update self(fio1)
          END IF
          IF (PRESENT(flo1)) THEN
!$acc update self(flo1)
          END IF
          IF (PRESENT(bio1)) THEN
!$acc update self(bio1)
          END IF
          IF (PRESENT(blo1)) THEN
!$acc update self(blo1)
          END IF
          IF (PRESENT(ho1)) THEN
!$acc update self(ho1)
          END IF
          IF (PRESENT(dzo2)) THEN
!$acc update self(dzo2)
          END IF
          IF (PRESENT(wo2)) THEN
!$acc update self(wo2)
          END IF
          IF (PRESENT(tssn2)) THEN
!$acc update self(tssn2)
          END IF
          IF (PRESENT(tssno2)) THEN
!$acc update self(tssno2)
          END IF
          IF (PRESENT(bwo2)) THEN
!$acc update self(bwo2)
          END IF
          IF (PRESENT(bto2)) THEN
!$acc update self(bto2)
          END IF
          IF (PRESENT(cto2)) THEN
!$acc update self(cto2)
          END IF
          IF (PRESENT(fio2)) THEN
!$acc update self(fio2)
          END IF
          IF (PRESENT(flo2)) THEN
!$acc update self(flo2)
          END IF
          IF (PRESENT(bio2)) THEN
!$acc update self(bio2)
          END IF
          IF (PRESENT(blo2)) THEN
!$acc update self(blo2)
          END IF
          IF (PRESENT(ho2)) THEN
!$acc update self(ho2)
          END IF
          IF (PRESENT(dzo3)) THEN
!$acc update self(dzo3)
          END IF
          IF (PRESENT(wo3)) THEN
!$acc update self(wo3)
          END IF
          IF (PRESENT(tssn3)) THEN
!$acc update self(tssn3)
          END IF
          IF (PRESENT(tssno3)) THEN
!$acc update self(tssno3)
          END IF
          IF (PRESENT(bwo3)) THEN
!$acc update self(bwo3)
          END IF
          IF (PRESENT(bto3)) THEN
!$acc update self(bto3)
          END IF
          IF (PRESENT(cto3)) THEN
!$acc update self(cto3)
          END IF
          IF (PRESENT(fio3)) THEN
!$acc update self(fio3)
          END IF
          IF (PRESENT(flo3)) THEN
!$acc update self(flo3)
          END IF
          IF (PRESENT(bio3)) THEN
!$acc update self(bio3)
          END IF
          IF (PRESENT(blo3)) THEN
!$acc update self(blo3)
          END IF
          IF (PRESENT(ho3)) THEN
!$acc update self(ho3)
          END IF
          IF (PRESENT(dzo4)) THEN
!$acc update self(dzo4)
          END IF
          IF (PRESENT(wo4)) THEN
!$acc update self(wo4)
          END IF
          IF (PRESENT(tssn4)) THEN
!$acc update self(tssn4)
          END IF
          IF (PRESENT(tssno4)) THEN
!$acc update self(tssno4)
          END IF
          IF (PRESENT(bwo4)) THEN
!$acc update self(bwo4)
          END IF
          IF (PRESENT(bto4)) THEN
!$acc update self(bto4)
          END IF
          IF (PRESENT(cto4)) THEN
!$acc update self(cto4)
          END IF
          IF (PRESENT(fio4)) THEN
!$acc update self(fio4)
          END IF
          IF (PRESENT(flo4)) THEN
!$acc update self(flo4)
          END IF
          IF (PRESENT(bio4)) THEN
!$acc update self(bio4)
          END IF
          IF (PRESENT(blo4)) THEN
!$acc update self(blo4)
          END IF
          IF (PRESENT(ho4)) THEN
!$acc update self(ho4)
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
          IF (PRESENT(capg)) THEN
!$acc update self(capg)
          END IF
          IF (PRESENT(hol)) THEN
!$acc update self(hol)
          END IF
          IF (PRESENT(mol)) THEN
!$acc update self(mol)
          END IF
          IF (PRESENT(rainbl)) THEN
!$acc update self(rainbl)
          END IF
          IF (PRESENT(regime)) THEN
!$acc update self(regime)
          END IF
          IF (PRESENT(qsg)) THEN
!$acc update self(qsg)
          END IF
          IF (PRESENT(qvg)) THEN
!$acc update self(qvg)
          END IF
          IF (PRESENT(qcg)) THEN
!$acc update self(qcg)
          END IF
          IF (PRESENT(soilt1)) THEN
!$acc update self(soilt1)
          END IF
          IF (PRESENT(tsnav)) THEN
!$acc update self(tsnav)
          END IF
          IF (PRESENT(smfr3d)) THEN
!$acc update self(smfr3d)
          END IF
          IF (PRESENT(keepfr3dflag)) THEN
!$acc update self(keepfr3dflag)
          END IF
          IF (PRESENT(dew)) THEN
!$acc update self(dew)
          END IF
          IF (PRESENT(rhosnf)) THEN
!$acc update self(rhosnf)
          END IF
          IF (PRESENT(precipfr)) THEN
!$acc update self(precipfr)
          END IF
          IF (PRESENT(potevp)) THEN
!$acc update self(potevp)
          END IF
          IF (PRESENT(snopcx)) THEN
!$acc update self(snopcx)
          END IF
          IF (PRESENT(soiltb)) THEN
!$acc update self(soiltb)
          END IF
          IF (PRESENT(sr)) THEN
!$acc update self(sr)
          END IF
          IF (PRESENT(t2_ndg_old)) THEN
!$acc update self(t2_ndg_old)
          END IF
          IF (PRESENT(q2_ndg_old)) THEN
!$acc update self(q2_ndg_old)
          END IF
          IF (PRESENT(t2_ndg_new)) THEN
!$acc update self(t2_ndg_new)
          END IF
          IF (PRESENT(q2_ndg_new)) THEN
!$acc update self(q2_ndg_new)
          END IF
          IF (PRESENT(sn_ndg_old)) THEN
!$acc update self(sn_ndg_old)
          END IF
          IF (PRESENT(sn_ndg_new)) THEN
!$acc update self(sn_ndg_new)
          END IF
          IF (PRESENT(t2obs)) THEN
!$acc update self(t2obs)
          END IF
          IF (PRESENT(q2obs)) THEN
!$acc update self(q2obs)
          END IF
          IF (PRESENT(hd_temf)) THEN
!$acc update self(hd_temf)
          END IF
          IF (PRESENT(te_temf)) THEN
!$acc update self(te_temf)
          END IF
          IF (PRESENT(exch_temf)) THEN
!$acc update self(exch_temf)
          END IF
          IF (PRESENT(wm_temf)) THEN
!$acc update self(wm_temf)
          END IF
          IF (PRESENT(uratx)) THEN
!$acc update self(uratx)
          END IF
          IF (PRESENT(vratx)) THEN
!$acc update self(vratx)
          END IF
          IF (PRESENT(tratx)) THEN
!$acc update self(tratx)
          END IF
          IF (PRESENT(tml)) THEN
!$acc update self(tml)
          END IF
          IF (PRESENT(t0ml)) THEN
!$acc update self(t0ml)
          END IF
          IF (PRESENT(hml)) THEN
!$acc update self(hml)
          END IF
          IF (PRESENT(h0ml)) THEN
!$acc update self(h0ml)
          END IF
          IF (PRESENT(huml)) THEN
!$acc update self(huml)
          END IF
          IF (PRESENT(hvml)) THEN
!$acc update self(hvml)
          END IF
          IF (PRESENT(ustm)) THEN
!$acc update self(ustm)
          END IF
          IF (PRESENT(ck)) THEN
!$acc update self(ck)
          END IF
          IF (PRESENT(cka)) THEN
!$acc update self(cka)
          END IF
          IF (PRESENT(cd)) THEN
!$acc update self(cd)
          END IF
          IF (PRESENT(cda)) THEN
!$acc update self(cda)
          END IF
          IF (PRESENT(snotime)) THEN
!$acc update self(snotime)
          END IF
          IF (PRESENT(noahres)) THEN
!$acc update self(noahres)
          END IF
          IF (PRESENT(tsk_rural)) THEN
!$acc update self(tsk_rural)
          END IF
          IF (PRESENT(trb_urb4d)) THEN
!$acc update self(trb_urb4d)
          END IF
          IF (PRESENT(tw1_urb4d)) THEN
!$acc update self(tw1_urb4d)
          END IF
          IF (PRESENT(tw2_urb4d)) THEN
!$acc update self(tw2_urb4d)
          END IF
          IF (PRESENT(tgb_urb4d)) THEN
!$acc update self(tgb_urb4d)
          END IF
          IF (PRESENT(tlev_urb3d)) THEN
!$acc update self(tlev_urb3d)
          END IF
          IF (PRESENT(qlev_urb3d)) THEN
!$acc update self(qlev_urb3d)
          END IF
          IF (PRESENT(tw1lev_urb3d)) THEN
!$acc update self(tw1lev_urb3d)
          END IF
          IF (PRESENT(tw2lev_urb3d)) THEN
!$acc update self(tw2lev_urb3d)
          END IF
          IF (PRESENT(tglev_urb3d)) THEN
!$acc update self(tglev_urb3d)
          END IF
          IF (PRESENT(tflev_urb3d)) THEN
!$acc update self(tflev_urb3d)
          END IF
          IF (PRESENT(sf_ac_urb3d)) THEN
!$acc update self(sf_ac_urb3d)
          END IF
          IF (PRESENT(lf_ac_urb3d)) THEN
!$acc update self(lf_ac_urb3d)
          END IF
          IF (PRESENT(cm_ac_urb3d)) THEN
!$acc update self(cm_ac_urb3d)
          END IF
          IF (PRESENT(sfvent_urb3d)) THEN
!$acc update self(sfvent_urb3d)
          END IF
          IF (PRESENT(lfvent_urb3d)) THEN
!$acc update self(lfvent_urb3d)
          END IF
          IF (PRESENT(sfwin1_urb3d)) THEN
!$acc update self(sfwin1_urb3d)
          END IF
          IF (PRESENT(sfwin2_urb3d)) THEN
!$acc update self(sfwin2_urb3d)
          END IF
          IF (PRESENT(sfw1_urb3d)) THEN
!$acc update self(sfw1_urb3d)
          END IF
          IF (PRESENT(sfw2_urb3d)) THEN
!$acc update self(sfw2_urb3d)
          END IF
          IF (PRESENT(sfr_urb3d)) THEN
!$acc update self(sfr_urb3d)
          END IF
          IF (PRESENT(sfg_urb3d)) THEN
!$acc update self(sfg_urb3d)
          END IF
          IF (PRESENT(ep_pv_urb3d)) THEN
!$acc update self(ep_pv_urb3d)
          END IF
          IF (PRESENT(t_pv_urb3d)) THEN
!$acc update self(t_pv_urb3d)
          END IF
          IF (PRESENT(trv_urb4d)) THEN
!$acc update self(trv_urb4d)
          END IF
          IF (PRESENT(qr_urb4d)) THEN
!$acc update self(qr_urb4d)
          END IF
          IF (PRESENT(qgr_urb3d)) THEN
!$acc update self(qgr_urb3d)
          END IF
          IF (PRESENT(tgr_urb3d)) THEN
!$acc update self(tgr_urb3d)
          END IF
          IF (PRESENT(drain_urb4d)) THEN
!$acc update self(drain_urb4d)
          END IF
          IF (PRESENT(draingr_urb3d)) THEN
!$acc update self(draingr_urb3d)
          END IF
          IF (PRESENT(sfrv_urb3d)) THEN
!$acc update self(sfrv_urb3d)
          END IF
          IF (PRESENT(lfrv_urb3d)) THEN
!$acc update self(lfrv_urb3d)
          END IF
          IF (PRESENT(dgr_urb3d)) THEN
!$acc update self(dgr_urb3d)
          END IF
          IF (PRESENT(dg_urb3d)) THEN
!$acc update self(dg_urb3d)
          END IF
          IF (PRESENT(lfr_urb3d)) THEN
!$acc update self(lfr_urb3d)
          END IF
          IF (PRESENT(lfg_urb3d)) THEN
!$acc update self(lfg_urb3d)
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
          IF (PRESENT(tsk_save)) THEN
!$acc update self(tsk_save)
          END IF
          IF (PRESENT(mosaic_cat_index)) THEN
!$acc update self(mosaic_cat_index)
          END IF
          IF (PRESENT(landusef2)) THEN
!$acc update self(landusef2)
          END IF
          IF (PRESENT(tsk_mosaic)) THEN
!$acc update self(tsk_mosaic)
          END IF
          IF (PRESENT(qsfc_mosaic)) THEN
!$acc update self(qsfc_mosaic)
          END IF
          IF (PRESENT(tslb_mosaic)) THEN
!$acc update self(tslb_mosaic)
          END IF
          IF (PRESENT(smois_mosaic)) THEN
!$acc update self(smois_mosaic)
          END IF
          IF (PRESENT(sh2o_mosaic)) THEN
!$acc update self(sh2o_mosaic)
          END IF
          IF (PRESENT(canwat_mosaic)) THEN
!$acc update self(canwat_mosaic)
          END IF
          IF (PRESENT(snow_mosaic)) THEN
!$acc update self(snow_mosaic)
          END IF
          IF (PRESENT(snowh_mosaic)) THEN
!$acc update self(snowh_mosaic)
          END IF
          IF (PRESENT(snowc_mosaic)) THEN
!$acc update self(snowc_mosaic)
          END IF
          IF (PRESENT(albedo_mosaic)) THEN
!$acc update self(albedo_mosaic)
          END IF
          IF (PRESENT(albbck_mosaic)) THEN
!$acc update self(albbck_mosaic)
          END IF
          IF (PRESENT(emiss_mosaic)) THEN
!$acc update self(emiss_mosaic)
          END IF
          IF (PRESENT(embck_mosaic)) THEN
!$acc update self(embck_mosaic)
          END IF
          IF (PRESENT(znt_mosaic)) THEN
!$acc update self(znt_mosaic)
          END IF
          IF (PRESENT(z0_mosaic)) THEN
!$acc update self(z0_mosaic)
          END IF
          IF (PRESENT(hfx_mosaic)) THEN
!$acc update self(hfx_mosaic)
          END IF
          IF (PRESENT(qfx_mosaic)) THEN
!$acc update self(qfx_mosaic)
          END IF
          IF (PRESENT(lh_mosaic)) THEN
!$acc update self(lh_mosaic)
          END IF
          IF (PRESENT(grdflx_mosaic)) THEN
!$acc update self(grdflx_mosaic)
          END IF
          IF (PRESENT(snotime_mosaic)) THEN
!$acc update self(snotime_mosaic)
          END IF
          IF (PRESENT(rs_mosaic)) THEN
!$acc update self(rs_mosaic)
          END IF
          IF (PRESENT(lai_mosaic)) THEN
!$acc update self(lai_mosaic)
          END IF
          IF (PRESENT(tr_urb2d_mosaic)) THEN
!$acc update self(tr_urb2d_mosaic)
          END IF
          IF (PRESENT(tb_urb2d_mosaic)) THEN
!$acc update self(tb_urb2d_mosaic)
          END IF
          IF (PRESENT(tg_urb2d_mosaic)) THEN
!$acc update self(tg_urb2d_mosaic)
          END IF
          IF (PRESENT(tc_urb2d_mosaic)) THEN
!$acc update self(tc_urb2d_mosaic)
          END IF
          IF (PRESENT(qc_urb2d_mosaic)) THEN
!$acc update self(qc_urb2d_mosaic)
          END IF
          IF (PRESENT(uc_urb2d_mosaic)) THEN
!$acc update self(uc_urb2d_mosaic)
          END IF
          IF (PRESENT(trl_urb3d_mosaic)) THEN
!$acc update self(trl_urb3d_mosaic)
          END IF
          IF (PRESENT(tbl_urb3d_mosaic)) THEN
!$acc update self(tbl_urb3d_mosaic)
          END IF
          IF (PRESENT(tgl_urb3d_mosaic)) THEN
!$acc update self(tgl_urb3d_mosaic)
          END IF
          IF (PRESENT(sh_urb2d_mosaic)) THEN
!$acc update self(sh_urb2d_mosaic)
          END IF
          IF (PRESENT(lh_urb2d_mosaic)) THEN
!$acc update self(lh_urb2d_mosaic)
          END IF
          IF (PRESENT(g_urb2d_mosaic)) THEN
!$acc update self(g_urb2d_mosaic)
          END IF
          IF (PRESENT(rn_urb2d_mosaic)) THEN
!$acc update self(rn_urb2d_mosaic)
          END IF
          IF (PRESENT(ts_urb2d_mosaic)) THEN
!$acc update self(ts_urb2d_mosaic)
          END IF
          IF (PRESENT(ts_rul2d_mosaic)) THEN
!$acc update self(ts_rul2d_mosaic)
          END IF
          IF (PRESENT(sda_hfx)) THEN
!$acc update self(sda_hfx)
          END IF
          IF (PRESENT(sda_qfx)) THEN
!$acc update self(sda_qfx)
          END IF
          IF (PRESENT(hfx_both)) THEN
!$acc update self(hfx_both)
          END IF
          IF (PRESENT(qfx_both)) THEN
!$acc update self(qfx_both)
          END IF
          IF (PRESENT(qnorm)) THEN
!$acc update self(qnorm)
          END IF
          IF (PRESENT(pattern_spp_lsm)) THEN
!$acc update self(pattern_spp_lsm)
          END IF
          IF (PRESENT(field_sf)) THEN
!$acc update self(field_sf)
          END IF
          IF (PRESENT(pattern_spp_pbl)) THEN
!$acc update self(pattern_spp_pbl)
          END IF
          IF (PRESENT(xlaidyn)) THEN
!$acc update self(xlaidyn)
          END IF
          IF (PRESENT(perts_qvapor)) THEN
!$acc update self(perts_qvapor)
          END IF
          IF (PRESENT(perts_th)) THEN
!$acc update self(perts_th)
          END IF
          IF (PRESENT(perts_smois)) THEN
!$acc update self(perts_smois)
          END IF
          IF (PRESENT(perts_tsoil)) THEN
!$acc update self(perts_tsoil)
          END IF
          IF (PRESENT(irr_rand_field)) THEN
!$acc update self(irr_rand_field)
          END IF
        ELSE
!$acc update device(sfcheadrt, infxsrt, soldrain, qtiledrain, zwatble2d, acsnom, acsnow, akhs, &
!$acc&   akms, albedo, br, canwat, chklowq, grdflx, gsw, swdown, gz1oz0, hfx, isltyp, ivgtyp, &
!$acc&   mavail, rmol, pblh, pshltr, fm, fhh, psih, psim, q10, q2, qfx, qsfc, qshltr, qz0, sfcevp, &
!$acc&   sfcexc, sfcrunoff, acrunoff, smois, smstav, smstot, snoalb, snow, snowc, snowh, smcrel, &
!$acc&   th10, th2, thz0, tmn, tshltr, tsk, tslb, t_phy, u10, udrunoff, ust, uz0, v10, vegfra, &
!$acc&   u10e, v10e, uoce, voce, vz0, wspd, xice, xland, znt, albsi, icedepth, snowsi, xicem, ct, &
!$acc&   tke_pbl, albbck, embck, lh, sh2o, z0, flqc, flhc, psfc, sst, flx4, fvb, fbur, fgsn, &
!$acc&   water_depth, savedtke12d, snowdp2d, h2osno2d, snl2d, t_grnd2d, t_lake3d, lake_icefrac3d, &
!$acc&   t_soisno3d, h2osoi_ice3d, h2osoi_liq3d, h2osoi_vol3d, z3d, dz3d, zi3d, lakemask, zol)
          IF (PRESENT(acgrdflx)) THEN
!$acc update device(acgrdflx)
          END IF
          IF (PRESENT(achfx)) THEN
!$acc update device(achfx)
          END IF
          IF (PRESENT(aclhf)) THEN
!$acc update device(aclhf)
          END IF
          IF (PRESENT(snowfallac)) THEN
!$acc update device(snowfallac)
          END IF
          IF (PRESENT(tyr)) THEN
!$acc update device(tyr)
          END IF
          IF (PRESENT(tyra)) THEN
!$acc update device(tyra)
          END IF
          IF (PRESENT(tdly)) THEN
!$acc update device(tdly)
          END IF
          IF (PRESENT(tlag)) THEN
!$acc update device(tlag)
          END IF
          IF (PRESENT(sstsk)) THEN
!$acc update device(sstsk)
          END IF
          IF (PRESENT(dtw)) THEN
!$acc update device(dtw)
          END IF
          IF (PRESENT(t2)) THEN
!$acc update device(t2)
          END IF
          IF (PRESENT(emiss)) THEN
!$acc update device(emiss)
          END IF
          IF (PRESENT(landusef)) THEN
!$acc update device(landusef)
          END IF
          IF (PRESENT(soilctop)) THEN
!$acc update device(soilctop)
          END IF
          IF (PRESENT(soilcbot)) THEN
!$acc update device(soilcbot)
          END IF
          IF (PRESENT(ra)) THEN
!$acc update device(ra)
          END IF
          IF (PRESENT(rs)) THEN
!$acc update device(rs)
          END IF
          IF (PRESENT(vegf_px)) THEN
!$acc update device(vegf_px)
          END IF
          IF (PRESENT(lai)) THEN
!$acc update device(lai)
          END IF
          IF (PRESENT(imperv)) THEN
!$acc update device(imperv)
          END IF
          IF (PRESENT(canfra)) THEN
!$acc update device(canfra)
          END IF
          IF (PRESENT(lai_px)) THEN
!$acc update device(lai_px)
          END IF
          IF (PRESENT(wwlt_px)) THEN
!$acc update device(wwlt_px)
          END IF
          IF (PRESENT(wfc_px)) THEN
!$acc update device(wfc_px)
          END IF
          IF (PRESENT(wsat_px)) THEN
!$acc update device(wsat_px)
          END IF
          IF (PRESENT(clay_px)) THEN
!$acc update device(clay_px)
          END IF
          IF (PRESENT(csand_px)) THEN
!$acc update device(csand_px)
          END IF
          IF (PRESENT(fmsand_px)) THEN
!$acc update device(fmsand_px)
          END IF
          IF (PRESENT(isnowxy)) THEN
!$acc update device(isnowxy)
          END IF
          IF (PRESENT(tvxy)) THEN
!$acc update device(tvxy)
          END IF
          IF (PRESENT(tgxy)) THEN
!$acc update device(tgxy)
          END IF
          IF (PRESENT(canicexy)) THEN
!$acc update device(canicexy)
          END IF
          IF (PRESENT(canliqxy)) THEN
!$acc update device(canliqxy)
          END IF
          IF (PRESENT(eahxy)) THEN
!$acc update device(eahxy)
          END IF
          IF (PRESENT(tahxy)) THEN
!$acc update device(tahxy)
          END IF
          IF (PRESENT(cmxy)) THEN
!$acc update device(cmxy)
          END IF
          IF (PRESENT(chxy)) THEN
!$acc update device(chxy)
          END IF
          IF (PRESENT(fwetxy)) THEN
!$acc update device(fwetxy)
          END IF
          IF (PRESENT(sneqvoxy)) THEN
!$acc update device(sneqvoxy)
          END IF
          IF (PRESENT(alboldxy)) THEN
!$acc update device(alboldxy)
          END IF
          IF (PRESENT(qsnowxy)) THEN
!$acc update device(qsnowxy)
          END IF
          IF (PRESENT(qrainxy)) THEN
!$acc update device(qrainxy)
          END IF
          IF (PRESENT(wslakexy)) THEN
!$acc update device(wslakexy)
          END IF
          IF (PRESENT(zwtxy)) THEN
!$acc update device(zwtxy)
          END IF
          IF (PRESENT(waxy)) THEN
!$acc update device(waxy)
          END IF
          IF (PRESENT(wtxy)) THEN
!$acc update device(wtxy)
          END IF
          IF (PRESENT(tsnoxy)) THEN
!$acc update device(tsnoxy)
          END IF
          IF (PRESENT(zsnsoxy)) THEN
!$acc update device(zsnsoxy)
          END IF
          IF (PRESENT(snicexy)) THEN
!$acc update device(snicexy)
          END IF
          IF (PRESENT(snliqxy)) THEN
!$acc update device(snliqxy)
          END IF
          IF (PRESENT(lfmassxy)) THEN
!$acc update device(lfmassxy)
          END IF
          IF (PRESENT(rtmassxy)) THEN
!$acc update device(rtmassxy)
          END IF
          IF (PRESENT(stmassxy)) THEN
!$acc update device(stmassxy)
          END IF
          IF (PRESENT(woodxy)) THEN
!$acc update device(woodxy)
          END IF
          IF (PRESENT(stblcpxy)) THEN
!$acc update device(stblcpxy)
          END IF
          IF (PRESENT(fastcpxy)) THEN
!$acc update device(fastcpxy)
          END IF
          IF (PRESENT(xsaixy)) THEN
!$acc update device(xsaixy)
          END IF
          IF (PRESENT(taussxy)) THEN
!$acc update device(taussxy)
          END IF
          IF (PRESENT(grainxy)) THEN
!$acc update device(grainxy)
          END IF
          IF (PRESENT(gddxy)) THEN
!$acc update device(gddxy)
          END IF
          IF (PRESENT(pgsxy)) THEN
!$acc update device(pgsxy)
          END IF
          IF (PRESENT(t2mvxy)) THEN
!$acc update device(t2mvxy)
          END IF
          IF (PRESENT(t2mbxy)) THEN
!$acc update device(t2mbxy)
          END IF
          IF (PRESENT(q2mvxy)) THEN
!$acc update device(q2mvxy)
          END IF
          IF (PRESENT(q2mbxy)) THEN
!$acc update device(q2mbxy)
          END IF
          IF (PRESENT(tradxy)) THEN
!$acc update device(tradxy)
          END IF
          IF (PRESENT(neexy)) THEN
!$acc update device(neexy)
          END IF
          IF (PRESENT(gppxy)) THEN
!$acc update device(gppxy)
          END IF
          IF (PRESENT(nppxy)) THEN
!$acc update device(nppxy)
          END IF
          IF (PRESENT(fvegxy)) THEN
!$acc update device(fvegxy)
          END IF
          IF (PRESENT(runsfxy)) THEN
!$acc update device(runsfxy)
          END IF
          IF (PRESENT(runsbxy)) THEN
!$acc update device(runsbxy)
          END IF
          IF (PRESENT(ecanxy)) THEN
!$acc update device(ecanxy)
          END IF
          IF (PRESENT(edirxy)) THEN
!$acc update device(edirxy)
          END IF
          IF (PRESENT(etranxy)) THEN
!$acc update device(etranxy)
          END IF
          IF (PRESENT(fsaxy)) THEN
!$acc update device(fsaxy)
          END IF
          IF (PRESENT(firaxy)) THEN
!$acc update device(firaxy)
          END IF
          IF (PRESENT(aparxy)) THEN
!$acc update device(aparxy)
          END IF
          IF (PRESENT(psnxy)) THEN
!$acc update device(psnxy)
          END IF
          IF (PRESENT(savxy)) THEN
!$acc update device(savxy)
          END IF
          IF (PRESENT(sagxy)) THEN
!$acc update device(sagxy)
          END IF
          IF (PRESENT(rssunxy)) THEN
!$acc update device(rssunxy)
          END IF
          IF (PRESENT(rsshaxy)) THEN
!$acc update device(rsshaxy)
          END IF
          IF (PRESENT(bgapxy)) THEN
!$acc update device(bgapxy)
          END IF
          IF (PRESENT(wgapxy)) THEN
!$acc update device(wgapxy)
          END IF
          IF (PRESENT(tgvxy)) THEN
!$acc update device(tgvxy)
          END IF
          IF (PRESENT(tgbxy)) THEN
!$acc update device(tgbxy)
          END IF
          IF (PRESENT(chvxy)) THEN
!$acc update device(chvxy)
          END IF
          IF (PRESENT(chbxy)) THEN
!$acc update device(chbxy)
          END IF
          IF (PRESENT(shgxy)) THEN
!$acc update device(shgxy)
          END IF
          IF (PRESENT(shcxy)) THEN
!$acc update device(shcxy)
          END IF
          IF (PRESENT(shbxy)) THEN
!$acc update device(shbxy)
          END IF
          IF (PRESENT(evgxy)) THEN
!$acc update device(evgxy)
          END IF
          IF (PRESENT(evbxy)) THEN
!$acc update device(evbxy)
          END IF
          IF (PRESENT(ghvxy)) THEN
!$acc update device(ghvxy)
          END IF
          IF (PRESENT(ghbxy)) THEN
!$acc update device(ghbxy)
          END IF
          IF (PRESENT(irgxy)) THEN
!$acc update device(irgxy)
          END IF
          IF (PRESENT(ircxy)) THEN
!$acc update device(ircxy)
          END IF
          IF (PRESENT(irbxy)) THEN
!$acc update device(irbxy)
          END IF
          IF (PRESENT(trxy)) THEN
!$acc update device(trxy)
          END IF
          IF (PRESENT(evcxy)) THEN
!$acc update device(evcxy)
          END IF
          IF (PRESENT(chleafxy)) THEN
!$acc update device(chleafxy)
          END IF
          IF (PRESENT(chucxy)) THEN
!$acc update device(chucxy)
          END IF
          IF (PRESENT(chv2xy)) THEN
!$acc update device(chv2xy)
          END IF
          IF (PRESENT(chb2xy)) THEN
!$acc update device(chb2xy)
          END IF
          IF (PRESENT(chstarxy)) THEN
!$acc update device(chstarxy)
          END IF
          IF (PRESENT(qintsxy)) THEN
!$acc update device(qintsxy)
          END IF
          IF (PRESENT(qintrxy)) THEN
!$acc update device(qintrxy)
          END IF
          IF (PRESENT(qdripsxy)) THEN
!$acc update device(qdripsxy)
          END IF
          IF (PRESENT(qdriprxy)) THEN
!$acc update device(qdriprxy)
          END IF
          IF (PRESENT(qthrosxy)) THEN
!$acc update device(qthrosxy)
          END IF
          IF (PRESENT(qthrorxy)) THEN
!$acc update device(qthrorxy)
          END IF
          IF (PRESENT(qsnsubxy)) THEN
!$acc update device(qsnsubxy)
          END IF
          IF (PRESENT(qsnfroxy)) THEN
!$acc update device(qsnfroxy)
          END IF
          IF (PRESENT(qsubcxy)) THEN
!$acc update device(qsubcxy)
          END IF
          IF (PRESENT(qfrocxy)) THEN
!$acc update device(qfrocxy)
          END IF
          IF (PRESENT(qevacxy)) THEN
!$acc update device(qevacxy)
          END IF
          IF (PRESENT(qdewcxy)) THEN
!$acc update device(qdewcxy)
          END IF
          IF (PRESENT(qfrzcxy)) THEN
!$acc update device(qfrzcxy)
          END IF
          IF (PRESENT(qmeltcxy)) THEN
!$acc update device(qmeltcxy)
          END IF
          IF (PRESENT(qsnbotxy)) THEN
!$acc update device(qsnbotxy)
          END IF
          IF (PRESENT(pondingxy)) THEN
!$acc update device(pondingxy)
          END IF
          IF (PRESENT(pahxy)) THEN
!$acc update device(pahxy)
          END IF
          IF (PRESENT(pahgxy)) THEN
!$acc update device(pahgxy)
          END IF
          IF (PRESENT(pahvxy)) THEN
!$acc update device(pahvxy)
          END IF
          IF (PRESENT(pahbxy)) THEN
!$acc update device(pahbxy)
          END IF
          IF (PRESENT(qmeltxy)) THEN
!$acc update device(qmeltxy)
          END IF
          IF (PRESENT(fpicexy)) THEN
!$acc update device(fpicexy)
          END IF
          IF (PRESENT(rainlsm)) THEN
!$acc update device(rainlsm)
          END IF
          IF (PRESENT(snowlsm)) THEN
!$acc update device(snowlsm)
          END IF
          IF (PRESENT(forctlsm)) THEN
!$acc update device(forctlsm)
          END IF
          IF (PRESENT(forcqlsm)) THEN
!$acc update device(forcqlsm)
          END IF
          IF (PRESENT(forcplsm)) THEN
!$acc update device(forcplsm)
          END IF
          IF (PRESENT(forczlsm)) THEN
!$acc update device(forczlsm)
          END IF
          IF (PRESENT(forcwlsm)) THEN
!$acc update device(forcwlsm)
          END IF
          IF (PRESENT(acc_ssoil)) THEN
!$acc update device(acc_ssoil)
          END IF
          IF (PRESENT(acc_qinsur)) THEN
!$acc update device(acc_qinsur)
          END IF
          IF (PRESENT(acc_qseva)) THEN
!$acc update device(acc_qseva)
          END IF
          IF (PRESENT(acc_etrani)) THEN
!$acc update device(acc_etrani)
          END IF
          IF (PRESENT(eflxbxy)) THEN
!$acc update device(eflxbxy)
          END IF
          IF (PRESENT(soilenergy)) THEN
!$acc update device(soilenergy)
          END IF
          IF (PRESENT(snowenergy)) THEN
!$acc update device(snowenergy)
          END IF
          IF (PRESENT(canhsxy)) THEN
!$acc update device(canhsxy)
          END IF
          IF (PRESENT(acc_dwaterxy)) THEN
!$acc update device(acc_dwaterxy)
          END IF
          IF (PRESENT(acc_prcpxy)) THEN
!$acc update device(acc_prcpxy)
          END IF
          IF (PRESENT(acc_ecanxy)) THEN
!$acc update device(acc_ecanxy)
          END IF
          IF (PRESENT(acc_etranxy)) THEN
!$acc update device(acc_etranxy)
          END IF
          IF (PRESENT(acc_edirxy)) THEN
!$acc update device(acc_edirxy)
          END IF
          IF (PRESENT(irnumsi)) THEN
!$acc update device(irnumsi)
          END IF
          IF (PRESENT(irnummi)) THEN
!$acc update device(irnummi)
          END IF
          IF (PRESENT(irnumfi)) THEN
!$acc update device(irnumfi)
          END IF
          IF (PRESENT(irwatsi)) THEN
!$acc update device(irwatsi)
          END IF
          IF (PRESENT(irwatmi)) THEN
!$acc update device(irwatmi)
          END IF
          IF (PRESENT(irwatfi)) THEN
!$acc update device(irwatfi)
          END IF
          IF (PRESENT(ireloss)) THEN
!$acc update device(ireloss)
          END IF
          IF (PRESENT(irsivol)) THEN
!$acc update device(irsivol)
          END IF
          IF (PRESENT(irmivol)) THEN
!$acc update device(irmivol)
          END IF
          IF (PRESENT(irfivol)) THEN
!$acc update device(irfivol)
          END IF
          IF (PRESENT(irrsplh)) THEN
!$acc update device(irrsplh)
          END IF
          IF (PRESENT(qtdrain)) THEN
!$acc update device(qtdrain)
          END IF
          IF (PRESENT(smcwtdxy)) THEN
!$acc update device(smcwtdxy)
          END IF
          IF (PRESENT(rechxy)) THEN
!$acc update device(rechxy)
          END IF
          IF (PRESENT(deeprechxy)) THEN
!$acc update device(deeprechxy)
          END IF
          IF (PRESENT(fdepthxy)) THEN
!$acc update device(fdepthxy)
          END IF
          IF (PRESENT(areaxy)) THEN
!$acc update device(areaxy)
          END IF
          IF (PRESENT(rivercondxy)) THEN
!$acc update device(rivercondxy)
          END IF
          IF (PRESENT(riverbedxy)) THEN
!$acc update device(riverbedxy)
          END IF
          IF (PRESENT(eqzwt)) THEN
!$acc update device(eqzwt)
          END IF
          IF (PRESENT(pexpxy)) THEN
!$acc update device(pexpxy)
          END IF
          IF (PRESENT(qrfxy)) THEN
!$acc update device(qrfxy)
          END IF
          IF (PRESENT(qspringxy)) THEN
!$acc update device(qspringxy)
          END IF
          IF (PRESENT(qslatxy)) THEN
!$acc update device(qslatxy)
          END IF
          IF (PRESENT(qrfsxy)) THEN
!$acc update device(qrfsxy)
          END IF
          IF (PRESENT(qlatxy)) THEN
!$acc update device(qlatxy)
          END IF
          IF (PRESENT(qspringsxy)) THEN
!$acc update device(qspringsxy)
          END IF
          IF (PRESENT(smoiseq)) THEN
!$acc update device(smoiseq)
          END IF
          IF (PRESENT(gecros_state)) THEN
!$acc update device(gecros_state)
          END IF
          IF (PRESENT(ch)) THEN
!$acc update device(ch)
          END IF
          IF (PRESENT(fgdp)) THEN
!$acc update device(fgdp)
          END IF
          IF (PRESENT(dfgdp)) THEN
!$acc update device(dfgdp)
          END IF
          IF (PRESENT(vdfg)) THEN
!$acc update device(vdfg)
          END IF
          IF (PRESENT(om_tmp)) THEN
!$acc update device(om_tmp)
          END IF
          IF (PRESENT(om_s)) THEN
!$acc update device(om_s)
          END IF
          IF (PRESENT(om_u)) THEN
!$acc update device(om_u)
          END IF
          IF (PRESENT(om_v)) THEN
!$acc update device(om_v)
          END IF
          IF (PRESENT(om_depth)) THEN
!$acc update device(om_depth)
          END IF
          IF (PRESENT(om_ml)) THEN
!$acc update device(om_ml)
          END IF
          IF (PRESENT(om_lon)) THEN
!$acc update device(om_lon)
          END IF
          IF (PRESENT(om_lat)) THEN
!$acc update device(om_lat)
          END IF
#if (WRF_CHEM == 1)
          IF (PRESENT(e_bio)) THEN
!$acc update device(e_bio)
          END IF
#endif
          IF (PRESENT(numc)) THEN
!$acc update device(numc)
          END IF
          IF (PRESENT(nump)) THEN
!$acc update device(nump)
          END IF
          IF (PRESENT(sabv)) THEN
!$acc update device(sabv)
          END IF
          IF (PRESENT(sabg)) THEN
!$acc update device(sabg)
          END IF
          IF (PRESENT(lwup)) THEN
!$acc update device(lwup)
          END IF
          IF (PRESENT(snl)) THEN
!$acc update device(snl)
          END IF
          IF (PRESENT(snowdp)) THEN
!$acc update device(snowdp)
          END IF
          IF (PRESENT(wtc)) THEN
!$acc update device(wtc)
          END IF
          IF (PRESENT(wtp)) THEN
!$acc update device(wtp)
          END IF
          IF (PRESENT(h2osno)) THEN
!$acc update device(h2osno)
          END IF
          IF (PRESENT(t_grnd)) THEN
!$acc update device(t_grnd)
          END IF
          IF (PRESENT(t_veg)) THEN
!$acc update device(t_veg)
          END IF
          IF (PRESENT(h2ocan)) THEN
!$acc update device(h2ocan)
          END IF
          IF (PRESENT(h2ocan_col)) THEN
!$acc update device(h2ocan_col)
          END IF
          IF (PRESENT(t2m_max)) THEN
!$acc update device(t2m_max)
          END IF
          IF (PRESENT(t2m_min)) THEN
!$acc update device(t2m_min)
          END IF
          IF (PRESENT(t2clm)) THEN
!$acc update device(t2clm)
          END IF
          IF (PRESENT(t_ref2m)) THEN
!$acc update device(t_ref2m)
          END IF
          IF (PRESENT(h2osoi_liq_s1)) THEN
!$acc update device(h2osoi_liq_s1)
          END IF
          IF (PRESENT(h2osoi_liq_s2)) THEN
!$acc update device(h2osoi_liq_s2)
          END IF
          IF (PRESENT(h2osoi_liq_s3)) THEN
!$acc update device(h2osoi_liq_s3)
          END IF
          IF (PRESENT(h2osoi_liq_s4)) THEN
!$acc update device(h2osoi_liq_s4)
          END IF
          IF (PRESENT(h2osoi_liq_s5)) THEN
!$acc update device(h2osoi_liq_s5)
          END IF
          IF (PRESENT(h2osoi_liq1)) THEN
!$acc update device(h2osoi_liq1)
          END IF
          IF (PRESENT(h2osoi_liq2)) THEN
!$acc update device(h2osoi_liq2)
          END IF
          IF (PRESENT(h2osoi_liq3)) THEN
!$acc update device(h2osoi_liq3)
          END IF
          IF (PRESENT(h2osoi_liq4)) THEN
!$acc update device(h2osoi_liq4)
          END IF
          IF (PRESENT(h2osoi_liq5)) THEN
!$acc update device(h2osoi_liq5)
          END IF
          IF (PRESENT(h2osoi_liq6)) THEN
!$acc update device(h2osoi_liq6)
          END IF
          IF (PRESENT(h2osoi_liq7)) THEN
!$acc update device(h2osoi_liq7)
          END IF
          IF (PRESENT(h2osoi_liq8)) THEN
!$acc update device(h2osoi_liq8)
          END IF
          IF (PRESENT(h2osoi_liq9)) THEN
!$acc update device(h2osoi_liq9)
          END IF
          IF (PRESENT(h2osoi_liq10)) THEN
!$acc update device(h2osoi_liq10)
          END IF
          IF (PRESENT(h2osoi_ice_s1)) THEN
!$acc update device(h2osoi_ice_s1)
          END IF
          IF (PRESENT(h2osoi_ice_s2)) THEN
!$acc update device(h2osoi_ice_s2)
          END IF
          IF (PRESENT(h2osoi_ice_s3)) THEN
!$acc update device(h2osoi_ice_s3)
          END IF
          IF (PRESENT(h2osoi_ice_s4)) THEN
!$acc update device(h2osoi_ice_s4)
          END IF
          IF (PRESENT(h2osoi_ice_s5)) THEN
!$acc update device(h2osoi_ice_s5)
          END IF
          IF (PRESENT(h2osoi_ice1)) THEN
!$acc update device(h2osoi_ice1)
          END IF
          IF (PRESENT(h2osoi_ice2)) THEN
!$acc update device(h2osoi_ice2)
          END IF
          IF (PRESENT(h2osoi_ice3)) THEN
!$acc update device(h2osoi_ice3)
          END IF
          IF (PRESENT(h2osoi_ice4)) THEN
!$acc update device(h2osoi_ice4)
          END IF
          IF (PRESENT(h2osoi_ice5)) THEN
!$acc update device(h2osoi_ice5)
          END IF
          IF (PRESENT(h2osoi_ice6)) THEN
!$acc update device(h2osoi_ice6)
          END IF
          IF (PRESENT(h2osoi_ice7)) THEN
!$acc update device(h2osoi_ice7)
          END IF
          IF (PRESENT(h2osoi_ice8)) THEN
!$acc update device(h2osoi_ice8)
          END IF
          IF (PRESENT(h2osoi_ice9)) THEN
!$acc update device(h2osoi_ice9)
          END IF
          IF (PRESENT(h2osoi_ice10)) THEN
!$acc update device(h2osoi_ice10)
          END IF
          IF (PRESENT(t_soisno_s1)) THEN
!$acc update device(t_soisno_s1)
          END IF
          IF (PRESENT(t_soisno_s2)) THEN
!$acc update device(t_soisno_s2)
          END IF
          IF (PRESENT(t_soisno_s3)) THEN
!$acc update device(t_soisno_s3)
          END IF
          IF (PRESENT(t_soisno_s4)) THEN
!$acc update device(t_soisno_s4)
          END IF
          IF (PRESENT(t_soisno_s5)) THEN
!$acc update device(t_soisno_s5)
          END IF
          IF (PRESENT(t_soisno1)) THEN
!$acc update device(t_soisno1)
          END IF
          IF (PRESENT(t_soisno2)) THEN
!$acc update device(t_soisno2)
          END IF
          IF (PRESENT(t_soisno3)) THEN
!$acc update device(t_soisno3)
          END IF
          IF (PRESENT(t_soisno4)) THEN
!$acc update device(t_soisno4)
          END IF
          IF (PRESENT(t_soisno5)) THEN
!$acc update device(t_soisno5)
          END IF
          IF (PRESENT(t_soisno6)) THEN
!$acc update device(t_soisno6)
          END IF
          IF (PRESENT(t_soisno7)) THEN
!$acc update device(t_soisno7)
          END IF
          IF (PRESENT(t_soisno8)) THEN
!$acc update device(t_soisno8)
          END IF
          IF (PRESENT(t_soisno9)) THEN
!$acc update device(t_soisno9)
          END IF
          IF (PRESENT(t_soisno10)) THEN
!$acc update device(t_soisno10)
          END IF
          IF (PRESENT(dzsnow1)) THEN
!$acc update device(dzsnow1)
          END IF
          IF (PRESENT(dzsnow2)) THEN
!$acc update device(dzsnow2)
          END IF
          IF (PRESENT(dzsnow3)) THEN
!$acc update device(dzsnow3)
          END IF
          IF (PRESENT(dzsnow4)) THEN
!$acc update device(dzsnow4)
          END IF
          IF (PRESENT(dzsnow5)) THEN
!$acc update device(dzsnow5)
          END IF
          IF (PRESENT(snowrds1)) THEN
!$acc update device(snowrds1)
          END IF
          IF (PRESENT(snowrds2)) THEN
!$acc update device(snowrds2)
          END IF
          IF (PRESENT(snowrds3)) THEN
!$acc update device(snowrds3)
          END IF
          IF (PRESENT(snowrds4)) THEN
!$acc update device(snowrds4)
          END IF
          IF (PRESENT(snowrds5)) THEN
!$acc update device(snowrds5)
          END IF
          IF (PRESENT(t_lake1)) THEN
!$acc update device(t_lake1)
          END IF
          IF (PRESENT(t_lake2)) THEN
!$acc update device(t_lake2)
          END IF
          IF (PRESENT(t_lake3)) THEN
!$acc update device(t_lake3)
          END IF
          IF (PRESENT(t_lake4)) THEN
!$acc update device(t_lake4)
          END IF
          IF (PRESENT(t_lake5)) THEN
!$acc update device(t_lake5)
          END IF
          IF (PRESENT(t_lake6)) THEN
!$acc update device(t_lake6)
          END IF
          IF (PRESENT(t_lake7)) THEN
!$acc update device(t_lake7)
          END IF
          IF (PRESENT(t_lake8)) THEN
!$acc update device(t_lake8)
          END IF
          IF (PRESENT(t_lake9)) THEN
!$acc update device(t_lake9)
          END IF
          IF (PRESENT(t_lake10)) THEN
!$acc update device(t_lake10)
          END IF
          IF (PRESENT(h2osoi_vol1)) THEN
!$acc update device(h2osoi_vol1)
          END IF
          IF (PRESENT(h2osoi_vol2)) THEN
!$acc update device(h2osoi_vol2)
          END IF
          IF (PRESENT(h2osoi_vol3)) THEN
!$acc update device(h2osoi_vol3)
          END IF
          IF (PRESENT(h2osoi_vol4)) THEN
!$acc update device(h2osoi_vol4)
          END IF
          IF (PRESENT(h2osoi_vol5)) THEN
!$acc update device(h2osoi_vol5)
          END IF
          IF (PRESENT(h2osoi_vol6)) THEN
!$acc update device(h2osoi_vol6)
          END IF
          IF (PRESENT(h2osoi_vol7)) THEN
!$acc update device(h2osoi_vol7)
          END IF
          IF (PRESENT(h2osoi_vol8)) THEN
!$acc update device(h2osoi_vol8)
          END IF
          IF (PRESENT(h2osoi_vol9)) THEN
!$acc update device(h2osoi_vol9)
          END IF
          IF (PRESENT(h2osoi_vol10)) THEN
!$acc update device(h2osoi_vol10)
          END IF
          IF (PRESENT(albedosubgrid)) THEN
!$acc update device(albedosubgrid)
          END IF
          IF (PRESENT(lhsubgrid)) THEN
!$acc update device(lhsubgrid)
          END IF
          IF (PRESENT(hfxsubgrid)) THEN
!$acc update device(hfxsubgrid)
          END IF
          IF (PRESENT(lwupsubgrid)) THEN
!$acc update device(lwupsubgrid)
          END IF
          IF (PRESENT(q2subgrid)) THEN
!$acc update device(q2subgrid)
          END IF
          IF (PRESENT(sabvsubgrid)) THEN
!$acc update device(sabvsubgrid)
          END IF
          IF (PRESENT(sabgsubgrid)) THEN
!$acc update device(sabgsubgrid)
          END IF
          IF (PRESENT(nrasubgrid)) THEN
!$acc update device(nrasubgrid)
          END IF
          IF (PRESENT(swupsubgrid)) THEN
!$acc update device(swupsubgrid)
          END IF
          IF (PRESENT(lhsoi)) THEN
!$acc update device(lhsoi)
          END IF
          IF (PRESENT(lhveg)) THEN
!$acc update device(lhveg)
          END IF
          IF (PRESENT(lhtran)) THEN
!$acc update device(lhtran)
          END IF
          IF (PRESENT(t_veg24)) THEN
!$acc update device(t_veg24)
          END IF
          IF (PRESENT(t_veg240)) THEN
!$acc update device(t_veg240)
          END IF
          IF (PRESENT(fsun24)) THEN
!$acc update device(fsun24)
          END IF
          IF (PRESENT(fsun240)) THEN
!$acc update device(fsun240)
          END IF
          IF (PRESENT(fsd24)) THEN
!$acc update device(fsd24)
          END IF
          IF (PRESENT(fsd240)) THEN
!$acc update device(fsd240)
          END IF
          IF (PRESENT(fsi24)) THEN
!$acc update device(fsi24)
          END IF
          IF (PRESENT(fsi240)) THEN
!$acc update device(fsi240)
          END IF
          IF (PRESENT(laip)) THEN
!$acc update device(laip)
          END IF
#ifdef CN
          IF (PRESENT(dyntlai)) THEN
!$acc update device(dyntlai)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dyntsai)) THEN
!$acc update device(dyntsai)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dyntop)) THEN
!$acc update device(dyntop)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dynbot)) THEN
!$acc update device(dynbot)
          END IF
#endif
#ifdef CN
          IF (PRESENT(htmx)) THEN
!$acc update device(htmx)
          END IF
#endif
#ifdef CN
          IF (PRESENT(croplive)) THEN
!$acc update device(croplive)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd1020)) THEN
!$acc update device(gdd1020)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd820)) THEN
!$acc update device(gdd820)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gdd020)) THEN
!$acc update device(gdd020)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc)) THEN
!$acc update device(grainc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc_storage)) THEN
!$acc update device(grainc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainc_xfer)) THEN
!$acc update device(grainc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn)) THEN
!$acc update device(grainn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn_storage)) THEN
!$acc update device(grainn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(grainn_xfer)) THEN
!$acc update device(grainn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(days_active)) THEN
!$acc update device(days_active)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_flag)) THEN
!$acc update device(onset_flag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_counter)) THEN
!$acc update device(onset_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_gddflag)) THEN
!$acc update device(onset_gddflag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_fdd)) THEN
!$acc update device(onset_fdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_gdd)) THEN
!$acc update device(onset_gdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(onset_swi)) THEN
!$acc update device(onset_swi)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_flag)) THEN
!$acc update device(offset_flag)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_counter)) THEN
!$acc update device(offset_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_fdd)) THEN
!$acc update device(offset_fdd)
          END IF
#endif
#ifdef CN
          IF (PRESENT(offset_swi)) THEN
!$acc update device(offset_swi)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dayl)) THEN
!$acc update device(dayl)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annavg_t2m)) THEN
!$acc update device(annavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempavg_t2m)) THEN
!$acc update device(tempavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempsum_potential_gpp)) THEN
!$acc update device(tempsum_potential_gpp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_potential_gpp)) THEN
!$acc update device(annsum_potential_gpp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempmax_retransn)) THEN
!$acc update device(tempmax_retransn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annmax_retransn)) THEN
!$acc update device(annmax_retransn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prev_leafc_to_litter)) THEN
!$acc update device(prev_leafc_to_litter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prev_frootc_to_litter)) THEN
!$acc update device(prev_frootc_to_litter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(tempsum_npp)) THEN
!$acc update device(tempsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_npp)) THEN
!$acc update device(annsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc)) THEN
!$acc update device(leafc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc_storage)) THEN
!$acc update device(leafc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafc_xfer)) THEN
!$acc update device(leafc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc)) THEN
!$acc update device(frootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc_storage)) THEN
!$acc update device(frootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootc_xfer)) THEN
!$acc update device(frootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc)) THEN
!$acc update device(livestemc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc_storage)) THEN
!$acc update device(livestemc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemc_xfer)) THEN
!$acc update device(livestemc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc)) THEN
!$acc update device(deadstemc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc_storage)) THEN
!$acc update device(deadstemc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemc_xfer)) THEN
!$acc update device(deadstemc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc)) THEN
!$acc update device(livecrootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc_storage)) THEN
!$acc update device(livecrootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootc_xfer)) THEN
!$acc update device(livecrootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc)) THEN
!$acc update device(deadcrootc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc_storage)) THEN
!$acc update device(deadcrootc_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootc_xfer)) THEN
!$acc update device(deadcrootc_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cpool)) THEN
!$acc update device(cpool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(pft_ctrunc)) THEN
!$acc update device(pft_ctrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn)) THEN
!$acc update device(leafn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn_storage)) THEN
!$acc update device(leafn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(leafn_xfer)) THEN
!$acc update device(leafn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn)) THEN
!$acc update device(frootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn_storage)) THEN
!$acc update device(frootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(frootn_xfer)) THEN
!$acc update device(frootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn)) THEN
!$acc update device(livestemn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn_storage)) THEN
!$acc update device(livestemn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livestemn_xfer)) THEN
!$acc update device(livestemn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn)) THEN
!$acc update device(deadstemn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn_storage)) THEN
!$acc update device(deadstemn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadstemn_xfer)) THEN
!$acc update device(deadstemn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn)) THEN
!$acc update device(livecrootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn_storage)) THEN
!$acc update device(livecrootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(livecrootn_xfer)) THEN
!$acc update device(livecrootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn)) THEN
!$acc update device(deadcrootn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn_storage)) THEN
!$acc update device(deadcrootn_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(deadcrootn_xfer)) THEN
!$acc update device(deadcrootn_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(npool)) THEN
!$acc update device(npool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(pft_ntrunc)) THEN
!$acc update device(pft_ntrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gresp_storage)) THEN
!$acc update device(gresp_storage)
          END IF
#endif
#ifdef CN
          IF (PRESENT(gresp_xfer)) THEN
!$acc update device(gresp_xfer)
          END IF
#endif
#ifdef CN
          IF (PRESENT(xsmrpool)) THEN
!$acc update device(xsmrpool)
          END IF
#endif
#ifdef CN
          IF (PRESENT(annsum_counter)) THEN
!$acc update device(annsum_counter)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cannsum_npp)) THEN
!$acc update device(cannsum_npp)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cannavg_t2m)) THEN
!$acc update device(cannavg_t2m)
          END IF
#endif
#ifdef CN
          IF (PRESENT(wf)) THEN
!$acc update device(wf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(me)) THEN
!$acc update device(me)
          END IF
#endif
#ifdef CN
          IF (PRESENT(mean_fire_prob)) THEN
!$acc update device(mean_fire_prob)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cwdc)) THEN
!$acc update device(cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr1c)) THEN
!$acc update device(litr1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr2c)) THEN
!$acc update device(litr2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr3c)) THEN
!$acc update device(litr3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil1c)) THEN
!$acc update device(soil1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil2c)) THEN
!$acc update device(soil2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil3c)) THEN
!$acc update device(soil3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil4c)) THEN
!$acc update device(soil4c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(seedc)) THEN
!$acc update device(seedc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(col_ctrunc)) THEN
!$acc update device(col_ctrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod10c)) THEN
!$acc update device(prod10c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100c)) THEN
!$acc update device(prod100c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(cwdn)) THEN
!$acc update device(cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr1n)) THEN
!$acc update device(litr1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr2n)) THEN
!$acc update device(litr2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(litr3n)) THEN
!$acc update device(litr3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil1n)) THEN
!$acc update device(soil1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil2n)) THEN
!$acc update device(soil2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil3n)) THEN
!$acc update device(soil3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(soil4n)) THEN
!$acc update device(soil4n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(seedn)) THEN
!$acc update device(seedn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(col_ntrunc)) THEN
!$acc update device(col_ntrunc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod10n)) THEN
!$acc update device(prod10n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100n)) THEN
!$acc update device(prod100n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(sminn)) THEN
!$acc update device(sminn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(totlitc)) THEN
!$acc update device(totlitc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedc_to_leaf)) THEN
!$acc update device(dwt_seedc_to_leaf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedc_to_deadstem)) THEN
!$acc update device(dwt_seedc_to_deadstem)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_conv_cflux)) THEN
!$acc update device(dwt_conv_cflux)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod10c_gain)) THEN
!$acc update device(dwt_prod10c_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod100c_gain)) THEN
!$acc update device(dwt_prod100c_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100c_loss)) THEN
!$acc update device(prod100c_loss)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr1c)) THEN
!$acc update device(dwt_frootc_to_litr1c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr2c)) THEN
!$acc update device(dwt_frootc_to_litr2c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootc_to_litr3c)) THEN
!$acc update device(dwt_frootc_to_litr3c)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_livecrootc_to_cwdc)) THEN
!$acc update device(dwt_livecrootc_to_cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_deadcrootc_to_cwdc)) THEN
!$acc update device(dwt_deadcrootc_to_cwdc)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedn_to_leaf)) THEN
!$acc update device(dwt_seedn_to_leaf)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_seedn_to_deadstem)) THEN
!$acc update device(dwt_seedn_to_deadstem)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_conv_nflux)) THEN
!$acc update device(dwt_conv_nflux)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod10n_gain)) THEN
!$acc update device(dwt_prod10n_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_prod100n_gain)) THEN
!$acc update device(dwt_prod100n_gain)
          END IF
#endif
#ifdef CN
          IF (PRESENT(prod100n_loss)) THEN
!$acc update device(prod100n_loss)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr1n)) THEN
!$acc update device(dwt_frootn_to_litr1n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr2n)) THEN
!$acc update device(dwt_frootn_to_litr2n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_frootn_to_litr3n)) THEN
!$acc update device(dwt_frootn_to_litr3n)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_livecrootn_to_cwdn)) THEN
!$acc update device(dwt_livecrootn_to_cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(dwt_deadcrootn_to_cwdn)) THEN
!$acc update device(dwt_deadcrootn_to_cwdn)
          END IF
#endif
#ifdef CN
          IF (PRESENT(retransn)) THEN
!$acc update device(retransn)
          END IF
#endif
          IF (PRESENT(swnorm)) THEN
!$acc update device(swnorm)
          END IF
          IF (PRESENT(tr_urb2d)) THEN
!$acc update device(tr_urb2d)
          END IF
          IF (PRESENT(tb_urb2d)) THEN
!$acc update device(tb_urb2d)
          END IF
          IF (PRESENT(tg_urb2d)) THEN
!$acc update device(tg_urb2d)
          END IF
          IF (PRESENT(tc_urb2d)) THEN
!$acc update device(tc_urb2d)
          END IF
          IF (PRESENT(qc_urb2d)) THEN
!$acc update device(qc_urb2d)
          END IF
          IF (PRESENT(uc_urb2d)) THEN
!$acc update device(uc_urb2d)
          END IF
          IF (PRESENT(xxxr_urb2d)) THEN
!$acc update device(xxxr_urb2d)
          END IF
          IF (PRESENT(xxxb_urb2d)) THEN
!$acc update device(xxxb_urb2d)
          END IF
          IF (PRESENT(xxxg_urb2d)) THEN
!$acc update device(xxxg_urb2d)
          END IF
          IF (PRESENT(xxxc_urb2d)) THEN
!$acc update device(xxxc_urb2d)
          END IF
          IF (PRESENT(cmcr_urb2d)) THEN
!$acc update device(cmcr_urb2d)
          END IF
          IF (PRESENT(tgr_urb2d)) THEN
!$acc update device(tgr_urb2d)
          END IF
          IF (PRESENT(tgrl_urb3d)) THEN
!$acc update device(tgrl_urb3d)
          END IF
          IF (PRESENT(smr_urb3d)) THEN
!$acc update device(smr_urb3d)
          END IF
          IF (PRESENT(drelr_urb2d)) THEN
!$acc update device(drelr_urb2d)
          END IF
          IF (PRESENT(drelb_urb2d)) THEN
!$acc update device(drelb_urb2d)
          END IF
          IF (PRESENT(drelg_urb2d)) THEN
!$acc update device(drelg_urb2d)
          END IF
          IF (PRESENT(flxhumr_urb2d)) THEN
!$acc update device(flxhumr_urb2d)
          END IF
          IF (PRESENT(flxhumb_urb2d)) THEN
!$acc update device(flxhumb_urb2d)
          END IF
          IF (PRESENT(flxhumg_urb2d)) THEN
!$acc update device(flxhumg_urb2d)
          END IF
          IF (PRESENT(trl_urb3d)) THEN
!$acc update device(trl_urb3d)
          END IF
          IF (PRESENT(tbl_urb3d)) THEN
!$acc update device(tbl_urb3d)
          END IF
          IF (PRESENT(tgl_urb3d)) THEN
!$acc update device(tgl_urb3d)
          END IF
          IF (PRESENT(sh_urb2d)) THEN
!$acc update device(sh_urb2d)
          END IF
          IF (PRESENT(lh_urb2d)) THEN
!$acc update device(lh_urb2d)
          END IF
          IF (PRESENT(g_urb2d)) THEN
!$acc update device(g_urb2d)
          END IF
          IF (PRESENT(rn_urb2d)) THEN
!$acc update device(rn_urb2d)
          END IF
          IF (PRESENT(ts_urb2d)) THEN
!$acc update device(ts_urb2d)
          END IF
          IF (PRESENT(frc_urb2d)) THEN
!$acc update device(frc_urb2d)
          END IF
          IF (PRESENT(utype_urb2d)) THEN
!$acc update device(utype_urb2d)
          END IF
          IF (PRESENT(cmr_sfcdif)) THEN
!$acc update device(cmr_sfcdif)
          END IF
          IF (PRESENT(chr_sfcdif)) THEN
!$acc update device(chr_sfcdif)
          END IF
          IF (PRESENT(cmc_sfcdif)) THEN
!$acc update device(cmc_sfcdif)
          END IF
          IF (PRESENT(chc_sfcdif)) THEN
!$acc update device(chc_sfcdif)
          END IF
          IF (PRESENT(cmgr_sfcdif)) THEN
!$acc update device(cmgr_sfcdif)
          END IF
          IF (PRESENT(chgr_sfcdif)) THEN
!$acc update device(chgr_sfcdif)
          END IF
          IF (PRESENT(alswvisdir)) THEN
!$acc update device(alswvisdir)
          END IF
          IF (PRESENT(alswvisdif)) THEN
!$acc update device(alswvisdif)
          END IF
          IF (PRESENT(alswnirdir)) THEN
!$acc update device(alswnirdir)
          END IF
          IF (PRESENT(alswnirdif)) THEN
!$acc update device(alswnirdif)
          END IF
          IF (PRESENT(ssib_br)) THEN
!$acc update device(ssib_br)
          END IF
          IF (PRESENT(ssib_fm)) THEN
!$acc update device(ssib_fm)
          END IF
          IF (PRESENT(ssib_fh)) THEN
!$acc update device(ssib_fh)
          END IF
          IF (PRESENT(ssib_cm)) THEN
!$acc update device(ssib_cm)
          END IF
          IF (PRESENT(ssibxdd)) THEN
!$acc update device(ssibxdd)
          END IF
          IF (PRESENT(ssib_lhf)) THEN
!$acc update device(ssib_lhf)
          END IF
          IF (PRESENT(ssib_shf)) THEN
!$acc update device(ssib_shf)
          END IF
          IF (PRESENT(ssib_ghf)) THEN
!$acc update device(ssib_ghf)
          END IF
          IF (PRESENT(ssib_egs)) THEN
!$acc update device(ssib_egs)
          END IF
          IF (PRESENT(ssib_eci)) THEN
!$acc update device(ssib_eci)
          END IF
          IF (PRESENT(ssib_ect)) THEN
!$acc update device(ssib_ect)
          END IF
          IF (PRESENT(ssib_egi)) THEN
!$acc update device(ssib_egi)
          END IF
          IF (PRESENT(ssib_egt)) THEN
!$acc update device(ssib_egt)
          END IF
          IF (PRESENT(ssib_sdn)) THEN
!$acc update device(ssib_sdn)
          END IF
          IF (PRESENT(ssib_sup)) THEN
!$acc update device(ssib_sup)
          END IF
          IF (PRESENT(ssib_ldn)) THEN
!$acc update device(ssib_ldn)
          END IF
          IF (PRESENT(ssib_lup)) THEN
!$acc update device(ssib_lup)
          END IF
          IF (PRESENT(ssib_wat)) THEN
!$acc update device(ssib_wat)
          END IF
          IF (PRESENT(ssib_shc)) THEN
!$acc update device(ssib_shc)
          END IF
          IF (PRESENT(ssib_shg)) THEN
!$acc update device(ssib_shg)
          END IF
          IF (PRESENT(ssib_lai)) THEN
!$acc update device(ssib_lai)
          END IF
          IF (PRESENT(ssib_vcf)) THEN
!$acc update device(ssib_vcf)
          END IF
          IF (PRESENT(ssib_z00)) THEN
!$acc update device(ssib_z00)
          END IF
          IF (PRESENT(ssib_veg)) THEN
!$acc update device(ssib_veg)
          END IF
          IF (PRESENT(isnow)) THEN
!$acc update device(isnow)
          END IF
          IF (PRESENT(swe)) THEN
!$acc update device(swe)
          END IF
          IF (PRESENT(snowden)) THEN
!$acc update device(snowden)
          END IF
          IF (PRESENT(snowdepth)) THEN
!$acc update device(snowdepth)
          END IF
          IF (PRESENT(tkair)) THEN
!$acc update device(tkair)
          END IF
          IF (PRESENT(dzo1)) THEN
!$acc update device(dzo1)
          END IF
          IF (PRESENT(wo1)) THEN
!$acc update device(wo1)
          END IF
          IF (PRESENT(tssn1)) THEN
!$acc update device(tssn1)
          END IF
          IF (PRESENT(tssno1)) THEN
!$acc update device(tssno1)
          END IF
          IF (PRESENT(bwo1)) THEN
!$acc update device(bwo1)
          END IF
          IF (PRESENT(bto1)) THEN
!$acc update device(bto1)
          END IF
          IF (PRESENT(cto1)) THEN
!$acc update device(cto1)
          END IF
          IF (PRESENT(fio1)) THEN
!$acc update device(fio1)
          END IF
          IF (PRESENT(flo1)) THEN
!$acc update device(flo1)
          END IF
          IF (PRESENT(bio1)) THEN
!$acc update device(bio1)
          END IF
          IF (PRESENT(blo1)) THEN
!$acc update device(blo1)
          END IF
          IF (PRESENT(ho1)) THEN
!$acc update device(ho1)
          END IF
          IF (PRESENT(dzo2)) THEN
!$acc update device(dzo2)
          END IF
          IF (PRESENT(wo2)) THEN
!$acc update device(wo2)
          END IF
          IF (PRESENT(tssn2)) THEN
!$acc update device(tssn2)
          END IF
          IF (PRESENT(tssno2)) THEN
!$acc update device(tssno2)
          END IF
          IF (PRESENT(bwo2)) THEN
!$acc update device(bwo2)
          END IF
          IF (PRESENT(bto2)) THEN
!$acc update device(bto2)
          END IF
          IF (PRESENT(cto2)) THEN
!$acc update device(cto2)
          END IF
          IF (PRESENT(fio2)) THEN
!$acc update device(fio2)
          END IF
          IF (PRESENT(flo2)) THEN
!$acc update device(flo2)
          END IF
          IF (PRESENT(bio2)) THEN
!$acc update device(bio2)
          END IF
          IF (PRESENT(blo2)) THEN
!$acc update device(blo2)
          END IF
          IF (PRESENT(ho2)) THEN
!$acc update device(ho2)
          END IF
          IF (PRESENT(dzo3)) THEN
!$acc update device(dzo3)
          END IF
          IF (PRESENT(wo3)) THEN
!$acc update device(wo3)
          END IF
          IF (PRESENT(tssn3)) THEN
!$acc update device(tssn3)
          END IF
          IF (PRESENT(tssno3)) THEN
!$acc update device(tssno3)
          END IF
          IF (PRESENT(bwo3)) THEN
!$acc update device(bwo3)
          END IF
          IF (PRESENT(bto3)) THEN
!$acc update device(bto3)
          END IF
          IF (PRESENT(cto3)) THEN
!$acc update device(cto3)
          END IF
          IF (PRESENT(fio3)) THEN
!$acc update device(fio3)
          END IF
          IF (PRESENT(flo3)) THEN
!$acc update device(flo3)
          END IF
          IF (PRESENT(bio3)) THEN
!$acc update device(bio3)
          END IF
          IF (PRESENT(blo3)) THEN
!$acc update device(blo3)
          END IF
          IF (PRESENT(ho3)) THEN
!$acc update device(ho3)
          END IF
          IF (PRESENT(dzo4)) THEN
!$acc update device(dzo4)
          END IF
          IF (PRESENT(wo4)) THEN
!$acc update device(wo4)
          END IF
          IF (PRESENT(tssn4)) THEN
!$acc update device(tssn4)
          END IF
          IF (PRESENT(tssno4)) THEN
!$acc update device(tssno4)
          END IF
          IF (PRESENT(bwo4)) THEN
!$acc update device(bwo4)
          END IF
          IF (PRESENT(bto4)) THEN
!$acc update device(bto4)
          END IF
          IF (PRESENT(cto4)) THEN
!$acc update device(cto4)
          END IF
          IF (PRESENT(fio4)) THEN
!$acc update device(fio4)
          END IF
          IF (PRESENT(flo4)) THEN
!$acc update device(flo4)
          END IF
          IF (PRESENT(bio4)) THEN
!$acc update device(bio4)
          END IF
          IF (PRESENT(blo4)) THEN
!$acc update device(blo4)
          END IF
          IF (PRESENT(ho4)) THEN
!$acc update device(ho4)
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
          IF (PRESENT(capg)) THEN
!$acc update device(capg)
          END IF
          IF (PRESENT(hol)) THEN
!$acc update device(hol)
          END IF
          IF (PRESENT(mol)) THEN
!$acc update device(mol)
          END IF
          IF (PRESENT(rainbl)) THEN
!$acc update device(rainbl)
          END IF
          IF (PRESENT(regime)) THEN
!$acc update device(regime)
          END IF
          IF (PRESENT(qsg)) THEN
!$acc update device(qsg)
          END IF
          IF (PRESENT(qvg)) THEN
!$acc update device(qvg)
          END IF
          IF (PRESENT(qcg)) THEN
!$acc update device(qcg)
          END IF
          IF (PRESENT(soilt1)) THEN
!$acc update device(soilt1)
          END IF
          IF (PRESENT(tsnav)) THEN
!$acc update device(tsnav)
          END IF
          IF (PRESENT(smfr3d)) THEN
!$acc update device(smfr3d)
          END IF
          IF (PRESENT(keepfr3dflag)) THEN
!$acc update device(keepfr3dflag)
          END IF
          IF (PRESENT(dew)) THEN
!$acc update device(dew)
          END IF
          IF (PRESENT(rhosnf)) THEN
!$acc update device(rhosnf)
          END IF
          IF (PRESENT(precipfr)) THEN
!$acc update device(precipfr)
          END IF
          IF (PRESENT(potevp)) THEN
!$acc update device(potevp)
          END IF
          IF (PRESENT(snopcx)) THEN
!$acc update device(snopcx)
          END IF
          IF (PRESENT(soiltb)) THEN
!$acc update device(soiltb)
          END IF
          IF (PRESENT(sr)) THEN
!$acc update device(sr)
          END IF
          IF (PRESENT(t2_ndg_old)) THEN
!$acc update device(t2_ndg_old)
          END IF
          IF (PRESENT(q2_ndg_old)) THEN
!$acc update device(q2_ndg_old)
          END IF
          IF (PRESENT(t2_ndg_new)) THEN
!$acc update device(t2_ndg_new)
          END IF
          IF (PRESENT(q2_ndg_new)) THEN
!$acc update device(q2_ndg_new)
          END IF
          IF (PRESENT(sn_ndg_old)) THEN
!$acc update device(sn_ndg_old)
          END IF
          IF (PRESENT(sn_ndg_new)) THEN
!$acc update device(sn_ndg_new)
          END IF
          IF (PRESENT(t2obs)) THEN
!$acc update device(t2obs)
          END IF
          IF (PRESENT(q2obs)) THEN
!$acc update device(q2obs)
          END IF
          IF (PRESENT(hd_temf)) THEN
!$acc update device(hd_temf)
          END IF
          IF (PRESENT(te_temf)) THEN
!$acc update device(te_temf)
          END IF
          IF (PRESENT(exch_temf)) THEN
!$acc update device(exch_temf)
          END IF
          IF (PRESENT(wm_temf)) THEN
!$acc update device(wm_temf)
          END IF
          IF (PRESENT(uratx)) THEN
!$acc update device(uratx)
          END IF
          IF (PRESENT(vratx)) THEN
!$acc update device(vratx)
          END IF
          IF (PRESENT(tratx)) THEN
!$acc update device(tratx)
          END IF
          IF (PRESENT(tml)) THEN
!$acc update device(tml)
          END IF
          IF (PRESENT(t0ml)) THEN
!$acc update device(t0ml)
          END IF
          IF (PRESENT(hml)) THEN
!$acc update device(hml)
          END IF
          IF (PRESENT(h0ml)) THEN
!$acc update device(h0ml)
          END IF
          IF (PRESENT(huml)) THEN
!$acc update device(huml)
          END IF
          IF (PRESENT(hvml)) THEN
!$acc update device(hvml)
          END IF
          IF (PRESENT(ustm)) THEN
!$acc update device(ustm)
          END IF
          IF (PRESENT(ck)) THEN
!$acc update device(ck)
          END IF
          IF (PRESENT(cka)) THEN
!$acc update device(cka)
          END IF
          IF (PRESENT(cd)) THEN
!$acc update device(cd)
          END IF
          IF (PRESENT(cda)) THEN
!$acc update device(cda)
          END IF
          IF (PRESENT(snotime)) THEN
!$acc update device(snotime)
          END IF
          IF (PRESENT(noahres)) THEN
!$acc update device(noahres)
          END IF
          IF (PRESENT(tsk_rural)) THEN
!$acc update device(tsk_rural)
          END IF
          IF (PRESENT(trb_urb4d)) THEN
!$acc update device(trb_urb4d)
          END IF
          IF (PRESENT(tw1_urb4d)) THEN
!$acc update device(tw1_urb4d)
          END IF
          IF (PRESENT(tw2_urb4d)) THEN
!$acc update device(tw2_urb4d)
          END IF
          IF (PRESENT(tgb_urb4d)) THEN
!$acc update device(tgb_urb4d)
          END IF
          IF (PRESENT(tlev_urb3d)) THEN
!$acc update device(tlev_urb3d)
          END IF
          IF (PRESENT(qlev_urb3d)) THEN
!$acc update device(qlev_urb3d)
          END IF
          IF (PRESENT(tw1lev_urb3d)) THEN
!$acc update device(tw1lev_urb3d)
          END IF
          IF (PRESENT(tw2lev_urb3d)) THEN
!$acc update device(tw2lev_urb3d)
          END IF
          IF (PRESENT(tglev_urb3d)) THEN
!$acc update device(tglev_urb3d)
          END IF
          IF (PRESENT(tflev_urb3d)) THEN
!$acc update device(tflev_urb3d)
          END IF
          IF (PRESENT(sf_ac_urb3d)) THEN
!$acc update device(sf_ac_urb3d)
          END IF
          IF (PRESENT(lf_ac_urb3d)) THEN
!$acc update device(lf_ac_urb3d)
          END IF
          IF (PRESENT(cm_ac_urb3d)) THEN
!$acc update device(cm_ac_urb3d)
          END IF
          IF (PRESENT(sfvent_urb3d)) THEN
!$acc update device(sfvent_urb3d)
          END IF
          IF (PRESENT(lfvent_urb3d)) THEN
!$acc update device(lfvent_urb3d)
          END IF
          IF (PRESENT(sfwin1_urb3d)) THEN
!$acc update device(sfwin1_urb3d)
          END IF
          IF (PRESENT(sfwin2_urb3d)) THEN
!$acc update device(sfwin2_urb3d)
          END IF
          IF (PRESENT(sfw1_urb3d)) THEN
!$acc update device(sfw1_urb3d)
          END IF
          IF (PRESENT(sfw2_urb3d)) THEN
!$acc update device(sfw2_urb3d)
          END IF
          IF (PRESENT(sfr_urb3d)) THEN
!$acc update device(sfr_urb3d)
          END IF
          IF (PRESENT(sfg_urb3d)) THEN
!$acc update device(sfg_urb3d)
          END IF
          IF (PRESENT(ep_pv_urb3d)) THEN
!$acc update device(ep_pv_urb3d)
          END IF
          IF (PRESENT(t_pv_urb3d)) THEN
!$acc update device(t_pv_urb3d)
          END IF
          IF (PRESENT(trv_urb4d)) THEN
!$acc update device(trv_urb4d)
          END IF
          IF (PRESENT(qr_urb4d)) THEN
!$acc update device(qr_urb4d)
          END IF
          IF (PRESENT(qgr_urb3d)) THEN
!$acc update device(qgr_urb3d)
          END IF
          IF (PRESENT(tgr_urb3d)) THEN
!$acc update device(tgr_urb3d)
          END IF
          IF (PRESENT(drain_urb4d)) THEN
!$acc update device(drain_urb4d)
          END IF
          IF (PRESENT(draingr_urb3d)) THEN
!$acc update device(draingr_urb3d)
          END IF
          IF (PRESENT(sfrv_urb3d)) THEN
!$acc update device(sfrv_urb3d)
          END IF
          IF (PRESENT(lfrv_urb3d)) THEN
!$acc update device(lfrv_urb3d)
          END IF
          IF (PRESENT(dgr_urb3d)) THEN
!$acc update device(dgr_urb3d)
          END IF
          IF (PRESENT(dg_urb3d)) THEN
!$acc update device(dg_urb3d)
          END IF
          IF (PRESENT(lfr_urb3d)) THEN
!$acc update device(lfr_urb3d)
          END IF
          IF (PRESENT(lfg_urb3d)) THEN
!$acc update device(lfg_urb3d)
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
          IF (PRESENT(tsk_save)) THEN
!$acc update device(tsk_save)
          END IF
          IF (PRESENT(mosaic_cat_index)) THEN
!$acc update device(mosaic_cat_index)
          END IF
          IF (PRESENT(landusef2)) THEN
!$acc update device(landusef2)
          END IF
          IF (PRESENT(tsk_mosaic)) THEN
!$acc update device(tsk_mosaic)
          END IF
          IF (PRESENT(qsfc_mosaic)) THEN
!$acc update device(qsfc_mosaic)
          END IF
          IF (PRESENT(tslb_mosaic)) THEN
!$acc update device(tslb_mosaic)
          END IF
          IF (PRESENT(smois_mosaic)) THEN
!$acc update device(smois_mosaic)
          END IF
          IF (PRESENT(sh2o_mosaic)) THEN
!$acc update device(sh2o_mosaic)
          END IF
          IF (PRESENT(canwat_mosaic)) THEN
!$acc update device(canwat_mosaic)
          END IF
          IF (PRESENT(snow_mosaic)) THEN
!$acc update device(snow_mosaic)
          END IF
          IF (PRESENT(snowh_mosaic)) THEN
!$acc update device(snowh_mosaic)
          END IF
          IF (PRESENT(snowc_mosaic)) THEN
!$acc update device(snowc_mosaic)
          END IF
          IF (PRESENT(albedo_mosaic)) THEN
!$acc update device(albedo_mosaic)
          END IF
          IF (PRESENT(albbck_mosaic)) THEN
!$acc update device(albbck_mosaic)
          END IF
          IF (PRESENT(emiss_mosaic)) THEN
!$acc update device(emiss_mosaic)
          END IF
          IF (PRESENT(embck_mosaic)) THEN
!$acc update device(embck_mosaic)
          END IF
          IF (PRESENT(znt_mosaic)) THEN
!$acc update device(znt_mosaic)
          END IF
          IF (PRESENT(z0_mosaic)) THEN
!$acc update device(z0_mosaic)
          END IF
          IF (PRESENT(hfx_mosaic)) THEN
!$acc update device(hfx_mosaic)
          END IF
          IF (PRESENT(qfx_mosaic)) THEN
!$acc update device(qfx_mosaic)
          END IF
          IF (PRESENT(lh_mosaic)) THEN
!$acc update device(lh_mosaic)
          END IF
          IF (PRESENT(grdflx_mosaic)) THEN
!$acc update device(grdflx_mosaic)
          END IF
          IF (PRESENT(snotime_mosaic)) THEN
!$acc update device(snotime_mosaic)
          END IF
          IF (PRESENT(rs_mosaic)) THEN
!$acc update device(rs_mosaic)
          END IF
          IF (PRESENT(lai_mosaic)) THEN
!$acc update device(lai_mosaic)
          END IF
          IF (PRESENT(tr_urb2d_mosaic)) THEN
!$acc update device(tr_urb2d_mosaic)
          END IF
          IF (PRESENT(tb_urb2d_mosaic)) THEN
!$acc update device(tb_urb2d_mosaic)
          END IF
          IF (PRESENT(tg_urb2d_mosaic)) THEN
!$acc update device(tg_urb2d_mosaic)
          END IF
          IF (PRESENT(tc_urb2d_mosaic)) THEN
!$acc update device(tc_urb2d_mosaic)
          END IF
          IF (PRESENT(qc_urb2d_mosaic)) THEN
!$acc update device(qc_urb2d_mosaic)
          END IF
          IF (PRESENT(uc_urb2d_mosaic)) THEN
!$acc update device(uc_urb2d_mosaic)
          END IF
          IF (PRESENT(trl_urb3d_mosaic)) THEN
!$acc update device(trl_urb3d_mosaic)
          END IF
          IF (PRESENT(tbl_urb3d_mosaic)) THEN
!$acc update device(tbl_urb3d_mosaic)
          END IF
          IF (PRESENT(tgl_urb3d_mosaic)) THEN
!$acc update device(tgl_urb3d_mosaic)
          END IF
          IF (PRESENT(sh_urb2d_mosaic)) THEN
!$acc update device(sh_urb2d_mosaic)
          END IF
          IF (PRESENT(lh_urb2d_mosaic)) THEN
!$acc update device(lh_urb2d_mosaic)
          END IF
          IF (PRESENT(g_urb2d_mosaic)) THEN
!$acc update device(g_urb2d_mosaic)
          END IF
          IF (PRESENT(rn_urb2d_mosaic)) THEN
!$acc update device(rn_urb2d_mosaic)
          END IF
          IF (PRESENT(ts_urb2d_mosaic)) THEN
!$acc update device(ts_urb2d_mosaic)
          END IF
          IF (PRESENT(ts_rul2d_mosaic)) THEN
!$acc update device(ts_rul2d_mosaic)
          END IF
          IF (PRESENT(sda_hfx)) THEN
!$acc update device(sda_hfx)
          END IF
          IF (PRESENT(sda_qfx)) THEN
!$acc update device(sda_qfx)
          END IF
          IF (PRESENT(hfx_both)) THEN
!$acc update device(hfx_both)
          END IF
          IF (PRESENT(qfx_both)) THEN
!$acc update device(qfx_both)
          END IF
          IF (PRESENT(qnorm)) THEN
!$acc update device(qnorm)
          END IF
          IF (PRESENT(pattern_spp_lsm)) THEN
!$acc update device(pattern_spp_lsm)
          END IF
          IF (PRESENT(field_sf)) THEN
!$acc update device(field_sf)
          END IF
          IF (PRESENT(pattern_spp_pbl)) THEN
!$acc update device(pattern_spp_pbl)
          END IF
          IF (PRESENT(xlaidyn)) THEN
!$acc update device(xlaidyn)
          END IF
          IF (PRESENT(perts_qvapor)) THEN
!$acc update device(perts_qvapor)
          END IF
          IF (PRESENT(perts_th)) THEN
!$acc update device(perts_th)
          END IF
          IF (PRESENT(perts_smois)) THEN
!$acc update device(perts_smois)
          END IF
          IF (PRESENT(perts_tsoil)) THEN
!$acc update device(perts_tsoil)
          END IF
          IF (PRESENT(irr_rand_field)) THEN
!$acc update device(irr_rand_field)
          END IF
        END IF
      END IF
      IF (gpu_cc_active(R_SURFACE_DRIVER)) THEN
        CALL gpu_cc_done_r0(1, hydro_dt, 'hydro_dt')
        CALL gpu_cc_done_r(2, sfcheadrt, SIZE(sfcheadrt,KIND=8), 'sfcheadrt', &
          LBOUND(sfcheadrt), UBOUND(sfcheadrt))
        CALL gpu_cc_done_r(3, infxsrt, SIZE(infxsrt,KIND=8), 'infxsrt', &
          LBOUND(infxsrt), UBOUND(infxsrt))
        CALL gpu_cc_done_r(4, soldrain, SIZE(soldrain,KIND=8), 'soldrain', &
          LBOUND(soldrain), UBOUND(soldrain))
        CALL gpu_cc_done_r(5, qtiledrain, SIZE(qtiledrain,KIND=8), 'qtiledrain', &
          LBOUND(qtiledrain), UBOUND(qtiledrain))
        CALL gpu_cc_done_r(6, zwatble2d, SIZE(zwatble2d,KIND=8), 'zwatble2d', &
          LBOUND(zwatble2d), UBOUND(zwatble2d))
        IF (PRESENT(acgrdflx)) CALL gpu_cc_done_r(7, acgrdflx, SIZE(acgrdflx,KIND=8), 'acgrdflx', &
          LBOUND(acgrdflx), UBOUND(acgrdflx))
        IF (PRESENT(achfx)) CALL gpu_cc_done_r(8, achfx, SIZE(achfx,KIND=8), 'achfx', &
          LBOUND(achfx), UBOUND(achfx))
        IF (PRESENT(aclhf)) CALL gpu_cc_done_r(9, aclhf, SIZE(aclhf,KIND=8), 'aclhf', &
          LBOUND(aclhf), UBOUND(aclhf))
        CALL gpu_cc_done_r(10, acsnom, SIZE(acsnom,KIND=8), 'acsnom', &
          LBOUND(acsnom), UBOUND(acsnom))
        CALL gpu_cc_done_r(11, acsnow, SIZE(acsnow,KIND=8), 'acsnow', &
          LBOUND(acsnow), UBOUND(acsnow))
        IF (PRESENT(snowfallac)) CALL gpu_cc_done_r(12, snowfallac, SIZE(snowfallac,KIND=8), 'snowfallac', &
          LBOUND(snowfallac), UBOUND(snowfallac))
        CALL gpu_cc_done_r(13, akhs, SIZE(akhs,KIND=8), 'akhs', &
          LBOUND(akhs), UBOUND(akhs))
        CALL gpu_cc_done_r(14, akms, SIZE(akms,KIND=8), 'akms', &
          LBOUND(akms), UBOUND(akms))
        CALL gpu_cc_done_r(15, albedo, SIZE(albedo,KIND=8), 'albedo', &
          LBOUND(albedo), UBOUND(albedo))
        CALL gpu_cc_done_r(16, br, SIZE(br,KIND=8), 'br', &
          LBOUND(br), UBOUND(br))
        CALL gpu_cc_done_r(17, canwat, SIZE(canwat,KIND=8), 'canwat', &
          LBOUND(canwat), UBOUND(canwat))
        CALL gpu_cc_done_r(18, chklowq, SIZE(chklowq,KIND=8), 'chklowq', &
          LBOUND(chklowq), UBOUND(chklowq))
        CALL gpu_cc_done_r(19, grdflx, SIZE(grdflx,KIND=8), 'grdflx', &
          LBOUND(grdflx), UBOUND(grdflx))
        CALL gpu_cc_done_r(20, gsw, SIZE(gsw,KIND=8), 'gsw', &
          LBOUND(gsw), UBOUND(gsw))
        CALL gpu_cc_done_r(21, swdown, SIZE(swdown,KIND=8), 'swdown', &
          LBOUND(swdown), UBOUND(swdown))
        CALL gpu_cc_done_r(22, gz1oz0, SIZE(gz1oz0,KIND=8), 'gz1oz0', &
          LBOUND(gz1oz0), UBOUND(gz1oz0))
        CALL gpu_cc_done_r(23, hfx, SIZE(hfx,KIND=8), 'hfx', &
          LBOUND(hfx), UBOUND(hfx))
        CALL gpu_cc_done_i(24, isltyp, SIZE(isltyp,KIND=8), 'isltyp', &
          LBOUND(isltyp), UBOUND(isltyp))
        CALL gpu_cc_done_i(25, ivgtyp, SIZE(ivgtyp,KIND=8), 'ivgtyp', &
          LBOUND(ivgtyp), UBOUND(ivgtyp))
        CALL gpu_cc_done_r(26, mavail, SIZE(mavail,KIND=8), 'mavail', &
          LBOUND(mavail), UBOUND(mavail))
        CALL gpu_cc_done_r(27, rmol, SIZE(rmol,KIND=8), 'rmol', &
          LBOUND(rmol), UBOUND(rmol))
        CALL gpu_cc_done_r(28, pblh, SIZE(pblh,KIND=8), 'pblh', &
          LBOUND(pblh), UBOUND(pblh))
        CALL gpu_cc_done_r(29, pshltr, SIZE(pshltr,KIND=8), 'pshltr', &
          LBOUND(pshltr), UBOUND(pshltr))
        CALL gpu_cc_done_r(30, fm, SIZE(fm,KIND=8), 'fm', &
          LBOUND(fm), UBOUND(fm))
        CALL gpu_cc_done_r(31, fhh, SIZE(fhh,KIND=8), 'fhh', &
          LBOUND(fhh), UBOUND(fhh))
        CALL gpu_cc_done_r(32, psih, SIZE(psih,KIND=8), 'psih', &
          LBOUND(psih), UBOUND(psih))
        CALL gpu_cc_done_r(33, psim, SIZE(psim,KIND=8), 'psim', &
          LBOUND(psim), UBOUND(psim))
        CALL gpu_cc_done_r(34, q10, SIZE(q10,KIND=8), 'q10', &
          LBOUND(q10), UBOUND(q10))
        CALL gpu_cc_done_r(35, q2, SIZE(q2,KIND=8), 'q2', &
          LBOUND(q2), UBOUND(q2))
        CALL gpu_cc_done_r(36, qfx, SIZE(qfx,KIND=8), 'qfx', &
          LBOUND(qfx), UBOUND(qfx))
        CALL gpu_cc_done_r(37, qsfc, SIZE(qsfc,KIND=8), 'qsfc', &
          LBOUND(qsfc), UBOUND(qsfc))
        CALL gpu_cc_done_r(38, qshltr, SIZE(qshltr,KIND=8), 'qshltr', &
          LBOUND(qshltr), UBOUND(qshltr))
        CALL gpu_cc_done_r(39, qz0, SIZE(qz0,KIND=8), 'qz0', &
          LBOUND(qz0), UBOUND(qz0))
        CALL gpu_cc_done_r(40, sfcevp, SIZE(sfcevp,KIND=8), 'sfcevp', &
          LBOUND(sfcevp), UBOUND(sfcevp))
        CALL gpu_cc_done_r(41, sfcexc, SIZE(sfcexc,KIND=8), 'sfcexc', &
          LBOUND(sfcexc), UBOUND(sfcexc))
        CALL gpu_cc_done_r(42, sfcrunoff, SIZE(sfcrunoff,KIND=8), 'sfcrunoff', &
          LBOUND(sfcrunoff), UBOUND(sfcrunoff))
        CALL gpu_cc_done_r(43, acrunoff, SIZE(acrunoff,KIND=8), 'acrunoff', &
          LBOUND(acrunoff), UBOUND(acrunoff))
        CALL gpu_cc_done_r(44, smois, SIZE(smois,KIND=8), 'smois', &
          LBOUND(smois), UBOUND(smois))
        CALL gpu_cc_done_r(45, smstav, SIZE(smstav,KIND=8), 'smstav', &
          LBOUND(smstav), UBOUND(smstav))
        CALL gpu_cc_done_r(46, smstot, SIZE(smstot,KIND=8), 'smstot', &
          LBOUND(smstot), UBOUND(smstot))
        CALL gpu_cc_done_r(47, snoalb, SIZE(snoalb,KIND=8), 'snoalb', &
          LBOUND(snoalb), UBOUND(snoalb))
        CALL gpu_cc_done_r(48, snow, SIZE(snow,KIND=8), 'snow', &
          LBOUND(snow), UBOUND(snow))
        CALL gpu_cc_done_r(49, snowc, SIZE(snowc,KIND=8), 'snowc', &
          LBOUND(snowc), UBOUND(snowc))
        CALL gpu_cc_done_r(50, snowh, SIZE(snowh,KIND=8), 'snowh', &
          LBOUND(snowh), UBOUND(snowh))
        CALL gpu_cc_done_r(51, smcrel, SIZE(smcrel,KIND=8), 'smcrel', &
          LBOUND(smcrel), UBOUND(smcrel))
        CALL gpu_cc_done_r(52, th10, SIZE(th10,KIND=8), 'th10', &
          LBOUND(th10), UBOUND(th10))
        CALL gpu_cc_done_r(53, th2, SIZE(th2,KIND=8), 'th2', &
          LBOUND(th2), UBOUND(th2))
        CALL gpu_cc_done_r(54, thz0, SIZE(thz0,KIND=8), 'thz0', &
          LBOUND(thz0), UBOUND(thz0))
        CALL gpu_cc_done_r(55, tmn, SIZE(tmn,KIND=8), 'tmn', &
          LBOUND(tmn), UBOUND(tmn))
        CALL gpu_cc_done_r(56, tshltr, SIZE(tshltr,KIND=8), 'tshltr', &
          LBOUND(tshltr), UBOUND(tshltr))
        CALL gpu_cc_done_r(57, tsk, SIZE(tsk,KIND=8), 'tsk', &
          LBOUND(tsk), UBOUND(tsk))
        CALL gpu_cc_done_r(58, tslb, SIZE(tslb,KIND=8), 'tslb', &
          LBOUND(tslb), UBOUND(tslb))
        IF (PRESENT(tyr)) CALL gpu_cc_done_r(59, tyr, SIZE(tyr,KIND=8), 'tyr', &
          LBOUND(tyr), UBOUND(tyr))
        IF (PRESENT(tyra)) CALL gpu_cc_done_r(60, tyra, SIZE(tyra,KIND=8), 'tyra', &
          LBOUND(tyra), UBOUND(tyra))
        IF (PRESENT(tdly)) CALL gpu_cc_done_r(61, tdly, SIZE(tdly,KIND=8), 'tdly', &
          LBOUND(tdly), UBOUND(tdly))
        IF (PRESENT(tlag)) CALL gpu_cc_done_r(62, tlag, SIZE(tlag,KIND=8), 'tlag', &
          LBOUND(tlag), UBOUND(tlag))
        IF (PRESENT(nyear)) CALL gpu_cc_done_i0(63, nyear, 'nyear')
        IF (PRESENT(nday)) CALL gpu_cc_done_r0(64, nday, 'nday')
        CALL gpu_cc_done_r(65, t_phy, SIZE(t_phy,KIND=8), 't_phy', &
          LBOUND(t_phy), UBOUND(t_phy))
        CALL gpu_cc_done_r(66, u10, SIZE(u10,KIND=8), 'u10', &
          LBOUND(u10), UBOUND(u10))
        CALL gpu_cc_done_r(67, udrunoff, SIZE(udrunoff,KIND=8), 'udrunoff', &
          LBOUND(udrunoff), UBOUND(udrunoff))
        CALL gpu_cc_done_r(68, ust, SIZE(ust,KIND=8), 'ust', &
          LBOUND(ust), UBOUND(ust))
        CALL gpu_cc_done_r(69, uz0, SIZE(uz0,KIND=8), 'uz0', &
          LBOUND(uz0), UBOUND(uz0))
        CALL gpu_cc_done_r(70, v10, SIZE(v10,KIND=8), 'v10', &
          LBOUND(v10), UBOUND(v10))
        CALL gpu_cc_done_r(71, vegfra, SIZE(vegfra,KIND=8), 'vegfra', &
          LBOUND(vegfra), UBOUND(vegfra))
        CALL gpu_cc_done_r(72, u10e, SIZE(u10e,KIND=8), 'u10e', &
          LBOUND(u10e), UBOUND(u10e))
        CALL gpu_cc_done_r(73, v10e, SIZE(v10e,KIND=8), 'v10e', &
          LBOUND(v10e), UBOUND(v10e))
        CALL gpu_cc_done_r(74, uoce, SIZE(uoce,KIND=8), 'uoce', &
          LBOUND(uoce), UBOUND(uoce))
        CALL gpu_cc_done_r(75, voce, SIZE(voce,KIND=8), 'voce', &
          LBOUND(voce), UBOUND(voce))
        CALL gpu_cc_done_r(76, vz0, SIZE(vz0,KIND=8), 'vz0', &
          LBOUND(vz0), UBOUND(vz0))
        CALL gpu_cc_done_r(77, wspd, SIZE(wspd,KIND=8), 'wspd', &
          LBOUND(wspd), UBOUND(wspd))
        CALL gpu_cc_done_r(78, xice, SIZE(xice,KIND=8), 'xice', &
          LBOUND(xice), UBOUND(xice))
        CALL gpu_cc_done_r(79, xland, SIZE(xland,KIND=8), 'xland', &
          LBOUND(xland), UBOUND(xland))
        CALL gpu_cc_done_r(80, znt, SIZE(znt,KIND=8), 'znt', &
          LBOUND(znt), UBOUND(znt))
        CALL gpu_cc_done_r(81, albsi, SIZE(albsi,KIND=8), 'albsi', &
          LBOUND(albsi), UBOUND(albsi))
        CALL gpu_cc_done_r(82, icedepth, SIZE(icedepth,KIND=8), 'icedepth', &
          LBOUND(icedepth), UBOUND(icedepth))
        CALL gpu_cc_done_r(83, snowsi, SIZE(snowsi,KIND=8), 'snowsi', &
          LBOUND(snowsi), UBOUND(snowsi))
        CALL gpu_cc_done_r(84, xicem, SIZE(xicem,KIND=8), 'xicem', &
          LBOUND(xicem), UBOUND(xicem))
        CALL gpu_cc_done_r(85, ct, SIZE(ct,KIND=8), 'ct', &
          LBOUND(ct), UBOUND(ct))
        CALL gpu_cc_done_r(86, tke_pbl, SIZE(tke_pbl,KIND=8), 'tke_pbl', &
          LBOUND(tke_pbl), UBOUND(tke_pbl))
        CALL gpu_cc_done_r(87, albbck, SIZE(albbck,KIND=8), 'albbck', &
          LBOUND(albbck), UBOUND(albbck))
        CALL gpu_cc_done_r(88, embck, SIZE(embck,KIND=8), 'embck', &
          LBOUND(embck), UBOUND(embck))
        CALL gpu_cc_done_r(89, lh, SIZE(lh,KIND=8), 'lh', &
          LBOUND(lh), UBOUND(lh))
        CALL gpu_cc_done_r(90, sh2o, SIZE(sh2o,KIND=8), 'sh2o', &
          LBOUND(sh2o), UBOUND(sh2o))
        CALL gpu_cc_done_r(91, z0, SIZE(z0,KIND=8), 'z0', &
          LBOUND(z0), UBOUND(z0))
        CALL gpu_cc_done_r(92, flqc, SIZE(flqc,KIND=8), 'flqc', &
          LBOUND(flqc), UBOUND(flqc))
        CALL gpu_cc_done_r(93, flhc, SIZE(flhc,KIND=8), 'flhc', &
          LBOUND(flhc), UBOUND(flhc))
        CALL gpu_cc_done_r(94, psfc, SIZE(psfc,KIND=8), 'psfc', &
          LBOUND(psfc), UBOUND(psfc))
        CALL gpu_cc_done_r(95, sst, SIZE(sst,KIND=8), 'sst', &
          LBOUND(sst), UBOUND(sst))
        IF (PRESENT(sstsk)) CALL gpu_cc_done_r(96, sstsk, SIZE(sstsk,KIND=8), 'sstsk', &
          LBOUND(sstsk), UBOUND(sstsk))
        IF (PRESENT(dtw)) CALL gpu_cc_done_r(97, dtw, SIZE(dtw,KIND=8), 'dtw', &
          LBOUND(dtw), UBOUND(dtw))
        IF (PRESENT(t2)) CALL gpu_cc_done_r(98, t2, SIZE(t2,KIND=8), 't2', &
          LBOUND(t2), UBOUND(t2))
        IF (PRESENT(emiss)) CALL gpu_cc_done_r(99, emiss, SIZE(emiss,KIND=8), 'emiss', &
          LBOUND(emiss), UBOUND(emiss))
        IF (PRESENT(landusef)) CALL gpu_cc_done_r(100, landusef, SIZE(landusef,KIND=8), 'landusef', &
          LBOUND(landusef), UBOUND(landusef))
        IF (PRESENT(soilctop)) CALL gpu_cc_done_r(101, soilctop, SIZE(soilctop,KIND=8), 'soilctop', &
          LBOUND(soilctop), UBOUND(soilctop))
        IF (PRESENT(soilcbot)) CALL gpu_cc_done_r(102, soilcbot, SIZE(soilcbot,KIND=8), 'soilcbot', &
          LBOUND(soilcbot), UBOUND(soilcbot))
        IF (PRESENT(ra)) CALL gpu_cc_done_r(103, ra, SIZE(ra,KIND=8), 'ra', &
          LBOUND(ra), UBOUND(ra))
        IF (PRESENT(rs)) CALL gpu_cc_done_r(104, rs, SIZE(rs,KIND=8), 'rs', &
          LBOUND(rs), UBOUND(rs))
        IF (PRESENT(vegf_px)) CALL gpu_cc_done_r(105, vegf_px, SIZE(vegf_px,KIND=8), 'vegf_px', &
          LBOUND(vegf_px), UBOUND(vegf_px))
        IF (PRESENT(lai)) CALL gpu_cc_done_r(106, lai, SIZE(lai,KIND=8), 'lai', &
          LBOUND(lai), UBOUND(lai))
        IF (PRESENT(imperv)) CALL gpu_cc_done_r(107, imperv, SIZE(imperv,KIND=8), 'imperv', &
          LBOUND(imperv), UBOUND(imperv))
        IF (PRESENT(canfra)) CALL gpu_cc_done_r(108, canfra, SIZE(canfra,KIND=8), 'canfra', &
          LBOUND(canfra), UBOUND(canfra))
        IF (PRESENT(lai_px)) CALL gpu_cc_done_r(109, lai_px, SIZE(lai_px,KIND=8), 'lai_px', &
          LBOUND(lai_px), UBOUND(lai_px))
        IF (PRESENT(wwlt_px)) CALL gpu_cc_done_r(110, wwlt_px, SIZE(wwlt_px,KIND=8), 'wwlt_px', &
          LBOUND(wwlt_px), UBOUND(wwlt_px))
        IF (PRESENT(wfc_px)) CALL gpu_cc_done_r(111, wfc_px, SIZE(wfc_px,KIND=8), 'wfc_px', &
          LBOUND(wfc_px), UBOUND(wfc_px))
        IF (PRESENT(wsat_px)) CALL gpu_cc_done_r(112, wsat_px, SIZE(wsat_px,KIND=8), 'wsat_px', &
          LBOUND(wsat_px), UBOUND(wsat_px))
        IF (PRESENT(clay_px)) CALL gpu_cc_done_r(113, clay_px, SIZE(clay_px,KIND=8), 'clay_px', &
          LBOUND(clay_px), UBOUND(clay_px))
        IF (PRESENT(csand_px)) CALL gpu_cc_done_r(114, csand_px, SIZE(csand_px,KIND=8), 'csand_px', &
          LBOUND(csand_px), UBOUND(csand_px))
        IF (PRESENT(fmsand_px)) CALL gpu_cc_done_r(115, fmsand_px, SIZE(fmsand_px,KIND=8), 'fmsand_px', &
          LBOUND(fmsand_px), UBOUND(fmsand_px))
        IF (PRESENT(isnowxy)) CALL gpu_cc_done_i(116, isnowxy, SIZE(isnowxy,KIND=8), 'isnowxy', &
          LBOUND(isnowxy), UBOUND(isnowxy))
        IF (PRESENT(tvxy)) CALL gpu_cc_done_r(117, tvxy, SIZE(tvxy,KIND=8), 'tvxy', &
          LBOUND(tvxy), UBOUND(tvxy))
        IF (PRESENT(tgxy)) CALL gpu_cc_done_r(118, tgxy, SIZE(tgxy,KIND=8), 'tgxy', &
          LBOUND(tgxy), UBOUND(tgxy))
        IF (PRESENT(canicexy)) CALL gpu_cc_done_r(119, canicexy, SIZE(canicexy,KIND=8), 'canicexy', &
          LBOUND(canicexy), UBOUND(canicexy))
        IF (PRESENT(canliqxy)) CALL gpu_cc_done_r(120, canliqxy, SIZE(canliqxy,KIND=8), 'canliqxy', &
          LBOUND(canliqxy), UBOUND(canliqxy))
        IF (PRESENT(eahxy)) CALL gpu_cc_done_r(121, eahxy, SIZE(eahxy,KIND=8), 'eahxy', &
          LBOUND(eahxy), UBOUND(eahxy))
        IF (PRESENT(tahxy)) CALL gpu_cc_done_r(122, tahxy, SIZE(tahxy,KIND=8), 'tahxy', &
          LBOUND(tahxy), UBOUND(tahxy))
        IF (PRESENT(cmxy)) CALL gpu_cc_done_r(123, cmxy, SIZE(cmxy,KIND=8), 'cmxy', &
          LBOUND(cmxy), UBOUND(cmxy))
        IF (PRESENT(chxy)) CALL gpu_cc_done_r(124, chxy, SIZE(chxy,KIND=8), 'chxy', &
          LBOUND(chxy), UBOUND(chxy))
        IF (PRESENT(fwetxy)) CALL gpu_cc_done_r(125, fwetxy, SIZE(fwetxy,KIND=8), 'fwetxy', &
          LBOUND(fwetxy), UBOUND(fwetxy))
        IF (PRESENT(sneqvoxy)) CALL gpu_cc_done_r(126, sneqvoxy, SIZE(sneqvoxy,KIND=8), 'sneqvoxy', &
          LBOUND(sneqvoxy), UBOUND(sneqvoxy))
        IF (PRESENT(alboldxy)) CALL gpu_cc_done_r(127, alboldxy, SIZE(alboldxy,KIND=8), 'alboldxy', &
          LBOUND(alboldxy), UBOUND(alboldxy))
        IF (PRESENT(qsnowxy)) CALL gpu_cc_done_r(128, qsnowxy, SIZE(qsnowxy,KIND=8), 'qsnowxy', &
          LBOUND(qsnowxy), UBOUND(qsnowxy))
        IF (PRESENT(qrainxy)) CALL gpu_cc_done_r(129, qrainxy, SIZE(qrainxy,KIND=8), 'qrainxy', &
          LBOUND(qrainxy), UBOUND(qrainxy))
        IF (PRESENT(wslakexy)) CALL gpu_cc_done_r(130, wslakexy, SIZE(wslakexy,KIND=8), 'wslakexy', &
          LBOUND(wslakexy), UBOUND(wslakexy))
        IF (PRESENT(zwtxy)) CALL gpu_cc_done_r(131, zwtxy, SIZE(zwtxy,KIND=8), 'zwtxy', &
          LBOUND(zwtxy), UBOUND(zwtxy))
        IF (PRESENT(waxy)) CALL gpu_cc_done_r(132, waxy, SIZE(waxy,KIND=8), 'waxy', &
          LBOUND(waxy), UBOUND(waxy))
        IF (PRESENT(wtxy)) CALL gpu_cc_done_r(133, wtxy, SIZE(wtxy,KIND=8), 'wtxy', &
          LBOUND(wtxy), UBOUND(wtxy))
        IF (PRESENT(tsnoxy)) CALL gpu_cc_done_r(134, tsnoxy, SIZE(tsnoxy,KIND=8), 'tsnoxy', &
          LBOUND(tsnoxy), UBOUND(tsnoxy))
        IF (PRESENT(zsnsoxy)) CALL gpu_cc_done_r(135, zsnsoxy, SIZE(zsnsoxy,KIND=8), 'zsnsoxy', &
          LBOUND(zsnsoxy), UBOUND(zsnsoxy))
        IF (PRESENT(snicexy)) CALL gpu_cc_done_r(136, snicexy, SIZE(snicexy,KIND=8), 'snicexy', &
          LBOUND(snicexy), UBOUND(snicexy))
        IF (PRESENT(snliqxy)) CALL gpu_cc_done_r(137, snliqxy, SIZE(snliqxy,KIND=8), 'snliqxy', &
          LBOUND(snliqxy), UBOUND(snliqxy))
        IF (PRESENT(lfmassxy)) CALL gpu_cc_done_r(138, lfmassxy, SIZE(lfmassxy,KIND=8), 'lfmassxy', &
          LBOUND(lfmassxy), UBOUND(lfmassxy))
        IF (PRESENT(rtmassxy)) CALL gpu_cc_done_r(139, rtmassxy, SIZE(rtmassxy,KIND=8), 'rtmassxy', &
          LBOUND(rtmassxy), UBOUND(rtmassxy))
        IF (PRESENT(stmassxy)) CALL gpu_cc_done_r(140, stmassxy, SIZE(stmassxy,KIND=8), 'stmassxy', &
          LBOUND(stmassxy), UBOUND(stmassxy))
        IF (PRESENT(woodxy)) CALL gpu_cc_done_r(141, woodxy, SIZE(woodxy,KIND=8), 'woodxy', &
          LBOUND(woodxy), UBOUND(woodxy))
        IF (PRESENT(stblcpxy)) CALL gpu_cc_done_r(142, stblcpxy, SIZE(stblcpxy,KIND=8), 'stblcpxy', &
          LBOUND(stblcpxy), UBOUND(stblcpxy))
        IF (PRESENT(fastcpxy)) CALL gpu_cc_done_r(143, fastcpxy, SIZE(fastcpxy,KIND=8), 'fastcpxy', &
          LBOUND(fastcpxy), UBOUND(fastcpxy))
        IF (PRESENT(xsaixy)) CALL gpu_cc_done_r(144, xsaixy, SIZE(xsaixy,KIND=8), 'xsaixy', &
          LBOUND(xsaixy), UBOUND(xsaixy))
        IF (PRESENT(taussxy)) CALL gpu_cc_done_r(145, taussxy, SIZE(taussxy,KIND=8), 'taussxy', &
          LBOUND(taussxy), UBOUND(taussxy))
        IF (PRESENT(grainxy)) CALL gpu_cc_done_r(146, grainxy, SIZE(grainxy,KIND=8), 'grainxy', &
          LBOUND(grainxy), UBOUND(grainxy))
        IF (PRESENT(gddxy)) CALL gpu_cc_done_r(147, gddxy, SIZE(gddxy,KIND=8), 'gddxy', &
          LBOUND(gddxy), UBOUND(gddxy))
        IF (PRESENT(pgsxy)) CALL gpu_cc_done_i(148, pgsxy, SIZE(pgsxy,KIND=8), 'pgsxy', &
          LBOUND(pgsxy), UBOUND(pgsxy))
        IF (PRESENT(t2mvxy)) CALL gpu_cc_done_r(149, t2mvxy, SIZE(t2mvxy,KIND=8), 't2mvxy', &
          LBOUND(t2mvxy), UBOUND(t2mvxy))
        IF (PRESENT(t2mbxy)) CALL gpu_cc_done_r(150, t2mbxy, SIZE(t2mbxy,KIND=8), 't2mbxy', &
          LBOUND(t2mbxy), UBOUND(t2mbxy))
        IF (PRESENT(q2mvxy)) CALL gpu_cc_done_r(151, q2mvxy, SIZE(q2mvxy,KIND=8), 'q2mvxy', &
          LBOUND(q2mvxy), UBOUND(q2mvxy))
        IF (PRESENT(q2mbxy)) CALL gpu_cc_done_r(152, q2mbxy, SIZE(q2mbxy,KIND=8), 'q2mbxy', &
          LBOUND(q2mbxy), UBOUND(q2mbxy))
        IF (PRESENT(tradxy)) CALL gpu_cc_done_r(153, tradxy, SIZE(tradxy,KIND=8), 'tradxy', &
          LBOUND(tradxy), UBOUND(tradxy))
        IF (PRESENT(neexy)) CALL gpu_cc_done_r(154, neexy, SIZE(neexy,KIND=8), 'neexy', &
          LBOUND(neexy), UBOUND(neexy))
        IF (PRESENT(gppxy)) CALL gpu_cc_done_r(155, gppxy, SIZE(gppxy,KIND=8), 'gppxy', &
          LBOUND(gppxy), UBOUND(gppxy))
        IF (PRESENT(nppxy)) CALL gpu_cc_done_r(156, nppxy, SIZE(nppxy,KIND=8), 'nppxy', &
          LBOUND(nppxy), UBOUND(nppxy))
        IF (PRESENT(fvegxy)) CALL gpu_cc_done_r(157, fvegxy, SIZE(fvegxy,KIND=8), 'fvegxy', &
          LBOUND(fvegxy), UBOUND(fvegxy))
        IF (PRESENT(runsfxy)) CALL gpu_cc_done_r(158, runsfxy, SIZE(runsfxy,KIND=8), 'runsfxy', &
          LBOUND(runsfxy), UBOUND(runsfxy))
        IF (PRESENT(runsbxy)) CALL gpu_cc_done_r(159, runsbxy, SIZE(runsbxy,KIND=8), 'runsbxy', &
          LBOUND(runsbxy), UBOUND(runsbxy))
        IF (PRESENT(ecanxy)) CALL gpu_cc_done_r(160, ecanxy, SIZE(ecanxy,KIND=8), 'ecanxy', &
          LBOUND(ecanxy), UBOUND(ecanxy))
        IF (PRESENT(edirxy)) CALL gpu_cc_done_r(161, edirxy, SIZE(edirxy,KIND=8), 'edirxy', &
          LBOUND(edirxy), UBOUND(edirxy))
        IF (PRESENT(etranxy)) CALL gpu_cc_done_r(162, etranxy, SIZE(etranxy,KIND=8), 'etranxy', &
          LBOUND(etranxy), UBOUND(etranxy))
        IF (PRESENT(fsaxy)) CALL gpu_cc_done_r(163, fsaxy, SIZE(fsaxy,KIND=8), 'fsaxy', &
          LBOUND(fsaxy), UBOUND(fsaxy))
        IF (PRESENT(firaxy)) CALL gpu_cc_done_r(164, firaxy, SIZE(firaxy,KIND=8), 'firaxy', &
          LBOUND(firaxy), UBOUND(firaxy))
        IF (PRESENT(aparxy)) CALL gpu_cc_done_r(165, aparxy, SIZE(aparxy,KIND=8), 'aparxy', &
          LBOUND(aparxy), UBOUND(aparxy))
        IF (PRESENT(psnxy)) CALL gpu_cc_done_r(166, psnxy, SIZE(psnxy,KIND=8), 'psnxy', &
          LBOUND(psnxy), UBOUND(psnxy))
        IF (PRESENT(savxy)) CALL gpu_cc_done_r(167, savxy, SIZE(savxy,KIND=8), 'savxy', &
          LBOUND(savxy), UBOUND(savxy))
        IF (PRESENT(sagxy)) CALL gpu_cc_done_r(168, sagxy, SIZE(sagxy,KIND=8), 'sagxy', &
          LBOUND(sagxy), UBOUND(sagxy))
        IF (PRESENT(rssunxy)) CALL gpu_cc_done_r(169, rssunxy, SIZE(rssunxy,KIND=8), 'rssunxy', &
          LBOUND(rssunxy), UBOUND(rssunxy))
        IF (PRESENT(rsshaxy)) CALL gpu_cc_done_r(170, rsshaxy, SIZE(rsshaxy,KIND=8), 'rsshaxy', &
          LBOUND(rsshaxy), UBOUND(rsshaxy))
        IF (PRESENT(bgapxy)) CALL gpu_cc_done_r(171, bgapxy, SIZE(bgapxy,KIND=8), 'bgapxy', &
          LBOUND(bgapxy), UBOUND(bgapxy))
        IF (PRESENT(wgapxy)) CALL gpu_cc_done_r(172, wgapxy, SIZE(wgapxy,KIND=8), 'wgapxy', &
          LBOUND(wgapxy), UBOUND(wgapxy))
        IF (PRESENT(tgvxy)) CALL gpu_cc_done_r(173, tgvxy, SIZE(tgvxy,KIND=8), 'tgvxy', &
          LBOUND(tgvxy), UBOUND(tgvxy))
        IF (PRESENT(tgbxy)) CALL gpu_cc_done_r(174, tgbxy, SIZE(tgbxy,KIND=8), 'tgbxy', &
          LBOUND(tgbxy), UBOUND(tgbxy))
        IF (PRESENT(chvxy)) CALL gpu_cc_done_r(175, chvxy, SIZE(chvxy,KIND=8), 'chvxy', &
          LBOUND(chvxy), UBOUND(chvxy))
        IF (PRESENT(chbxy)) CALL gpu_cc_done_r(176, chbxy, SIZE(chbxy,KIND=8), 'chbxy', &
          LBOUND(chbxy), UBOUND(chbxy))
        IF (PRESENT(shgxy)) CALL gpu_cc_done_r(177, shgxy, SIZE(shgxy,KIND=8), 'shgxy', &
          LBOUND(shgxy), UBOUND(shgxy))
        IF (PRESENT(shcxy)) CALL gpu_cc_done_r(178, shcxy, SIZE(shcxy,KIND=8), 'shcxy', &
          LBOUND(shcxy), UBOUND(shcxy))
        IF (PRESENT(shbxy)) CALL gpu_cc_done_r(179, shbxy, SIZE(shbxy,KIND=8), 'shbxy', &
          LBOUND(shbxy), UBOUND(shbxy))
        IF (PRESENT(evgxy)) CALL gpu_cc_done_r(180, evgxy, SIZE(evgxy,KIND=8), 'evgxy', &
          LBOUND(evgxy), UBOUND(evgxy))
        IF (PRESENT(evbxy)) CALL gpu_cc_done_r(181, evbxy, SIZE(evbxy,KIND=8), 'evbxy', &
          LBOUND(evbxy), UBOUND(evbxy))
        IF (PRESENT(ghvxy)) CALL gpu_cc_done_r(182, ghvxy, SIZE(ghvxy,KIND=8), 'ghvxy', &
          LBOUND(ghvxy), UBOUND(ghvxy))
        IF (PRESENT(ghbxy)) CALL gpu_cc_done_r(183, ghbxy, SIZE(ghbxy,KIND=8), 'ghbxy', &
          LBOUND(ghbxy), UBOUND(ghbxy))
        IF (PRESENT(irgxy)) CALL gpu_cc_done_r(184, irgxy, SIZE(irgxy,KIND=8), 'irgxy', &
          LBOUND(irgxy), UBOUND(irgxy))
        IF (PRESENT(ircxy)) CALL gpu_cc_done_r(185, ircxy, SIZE(ircxy,KIND=8), 'ircxy', &
          LBOUND(ircxy), UBOUND(ircxy))
        IF (PRESENT(irbxy)) CALL gpu_cc_done_r(186, irbxy, SIZE(irbxy,KIND=8), 'irbxy', &
          LBOUND(irbxy), UBOUND(irbxy))
        IF (PRESENT(trxy)) CALL gpu_cc_done_r(187, trxy, SIZE(trxy,KIND=8), 'trxy', &
          LBOUND(trxy), UBOUND(trxy))
        IF (PRESENT(evcxy)) CALL gpu_cc_done_r(188, evcxy, SIZE(evcxy,KIND=8), 'evcxy', &
          LBOUND(evcxy), UBOUND(evcxy))
        IF (PRESENT(chleafxy)) CALL gpu_cc_done_r(189, chleafxy, SIZE(chleafxy,KIND=8), 'chleafxy', &
          LBOUND(chleafxy), UBOUND(chleafxy))
        IF (PRESENT(chucxy)) CALL gpu_cc_done_r(190, chucxy, SIZE(chucxy,KIND=8), 'chucxy', &
          LBOUND(chucxy), UBOUND(chucxy))
        IF (PRESENT(chv2xy)) CALL gpu_cc_done_r(191, chv2xy, SIZE(chv2xy,KIND=8), 'chv2xy', &
          LBOUND(chv2xy), UBOUND(chv2xy))
        IF (PRESENT(chb2xy)) CALL gpu_cc_done_r(192, chb2xy, SIZE(chb2xy,KIND=8), 'chb2xy', &
          LBOUND(chb2xy), UBOUND(chb2xy))
        IF (PRESENT(chstarxy)) CALL gpu_cc_done_r(193, chstarxy, SIZE(chstarxy,KIND=8), 'chstarxy', &
          LBOUND(chstarxy), UBOUND(chstarxy))
        IF (PRESENT(qintsxy)) CALL gpu_cc_done_r(194, qintsxy, SIZE(qintsxy,KIND=8), 'qintsxy', &
          LBOUND(qintsxy), UBOUND(qintsxy))
        IF (PRESENT(qintrxy)) CALL gpu_cc_done_r(195, qintrxy, SIZE(qintrxy,KIND=8), 'qintrxy', &
          LBOUND(qintrxy), UBOUND(qintrxy))
        IF (PRESENT(qdripsxy)) CALL gpu_cc_done_r(196, qdripsxy, SIZE(qdripsxy,KIND=8), 'qdripsxy', &
          LBOUND(qdripsxy), UBOUND(qdripsxy))
        IF (PRESENT(qdriprxy)) CALL gpu_cc_done_r(197, qdriprxy, SIZE(qdriprxy,KIND=8), 'qdriprxy', &
          LBOUND(qdriprxy), UBOUND(qdriprxy))
        IF (PRESENT(qthrosxy)) CALL gpu_cc_done_r(198, qthrosxy, SIZE(qthrosxy,KIND=8), 'qthrosxy', &
          LBOUND(qthrosxy), UBOUND(qthrosxy))
        IF (PRESENT(qthrorxy)) CALL gpu_cc_done_r(199, qthrorxy, SIZE(qthrorxy,KIND=8), 'qthrorxy', &
          LBOUND(qthrorxy), UBOUND(qthrorxy))
        IF (PRESENT(qsnsubxy)) CALL gpu_cc_done_r(200, qsnsubxy, SIZE(qsnsubxy,KIND=8), 'qsnsubxy', &
          LBOUND(qsnsubxy), UBOUND(qsnsubxy))
        IF (PRESENT(qsnfroxy)) CALL gpu_cc_done_r(201, qsnfroxy, SIZE(qsnfroxy,KIND=8), 'qsnfroxy', &
          LBOUND(qsnfroxy), UBOUND(qsnfroxy))
        IF (PRESENT(qsubcxy)) CALL gpu_cc_done_r(202, qsubcxy, SIZE(qsubcxy,KIND=8), 'qsubcxy', &
          LBOUND(qsubcxy), UBOUND(qsubcxy))
        IF (PRESENT(qfrocxy)) CALL gpu_cc_done_r(203, qfrocxy, SIZE(qfrocxy,KIND=8), 'qfrocxy', &
          LBOUND(qfrocxy), UBOUND(qfrocxy))
        IF (PRESENT(qevacxy)) CALL gpu_cc_done_r(204, qevacxy, SIZE(qevacxy,KIND=8), 'qevacxy', &
          LBOUND(qevacxy), UBOUND(qevacxy))
        IF (PRESENT(qdewcxy)) CALL gpu_cc_done_r(205, qdewcxy, SIZE(qdewcxy,KIND=8), 'qdewcxy', &
          LBOUND(qdewcxy), UBOUND(qdewcxy))
        IF (PRESENT(qfrzcxy)) CALL gpu_cc_done_r(206, qfrzcxy, SIZE(qfrzcxy,KIND=8), 'qfrzcxy', &
          LBOUND(qfrzcxy), UBOUND(qfrzcxy))
        IF (PRESENT(qmeltcxy)) CALL gpu_cc_done_r(207, qmeltcxy, SIZE(qmeltcxy,KIND=8), 'qmeltcxy', &
          LBOUND(qmeltcxy), UBOUND(qmeltcxy))
        IF (PRESENT(qsnbotxy)) CALL gpu_cc_done_r(208, qsnbotxy, SIZE(qsnbotxy,KIND=8), 'qsnbotxy', &
          LBOUND(qsnbotxy), UBOUND(qsnbotxy))
        IF (PRESENT(pondingxy)) CALL gpu_cc_done_r(209, pondingxy, SIZE(pondingxy,KIND=8), 'pondingxy', &
          LBOUND(pondingxy), UBOUND(pondingxy))
        IF (PRESENT(pahxy)) CALL gpu_cc_done_r(210, pahxy, SIZE(pahxy,KIND=8), 'pahxy', &
          LBOUND(pahxy), UBOUND(pahxy))
        IF (PRESENT(pahgxy)) CALL gpu_cc_done_r(211, pahgxy, SIZE(pahgxy,KIND=8), 'pahgxy', &
          LBOUND(pahgxy), UBOUND(pahgxy))
        IF (PRESENT(pahvxy)) CALL gpu_cc_done_r(212, pahvxy, SIZE(pahvxy,KIND=8), 'pahvxy', &
          LBOUND(pahvxy), UBOUND(pahvxy))
        IF (PRESENT(pahbxy)) CALL gpu_cc_done_r(213, pahbxy, SIZE(pahbxy,KIND=8), 'pahbxy', &
          LBOUND(pahbxy), UBOUND(pahbxy))
        IF (PRESENT(qmeltxy)) CALL gpu_cc_done_r(214, qmeltxy, SIZE(qmeltxy,KIND=8), 'qmeltxy', &
          LBOUND(qmeltxy), UBOUND(qmeltxy))
        IF (PRESENT(fpicexy)) CALL gpu_cc_done_r(215, fpicexy, SIZE(fpicexy,KIND=8), 'fpicexy', &
          LBOUND(fpicexy), UBOUND(fpicexy))
        IF (PRESENT(rainlsm)) CALL gpu_cc_done_r(216, rainlsm, SIZE(rainlsm,KIND=8), 'rainlsm', &
          LBOUND(rainlsm), UBOUND(rainlsm))
        IF (PRESENT(snowlsm)) CALL gpu_cc_done_r(217, snowlsm, SIZE(snowlsm,KIND=8), 'snowlsm', &
          LBOUND(snowlsm), UBOUND(snowlsm))
        IF (PRESENT(forctlsm)) CALL gpu_cc_done_r(218, forctlsm, SIZE(forctlsm,KIND=8), 'forctlsm', &
          LBOUND(forctlsm), UBOUND(forctlsm))
        IF (PRESENT(forcqlsm)) CALL gpu_cc_done_r(219, forcqlsm, SIZE(forcqlsm,KIND=8), 'forcqlsm', &
          LBOUND(forcqlsm), UBOUND(forcqlsm))
        IF (PRESENT(forcplsm)) CALL gpu_cc_done_r(220, forcplsm, SIZE(forcplsm,KIND=8), 'forcplsm', &
          LBOUND(forcplsm), UBOUND(forcplsm))
        IF (PRESENT(forczlsm)) CALL gpu_cc_done_r(221, forczlsm, SIZE(forczlsm,KIND=8), 'forczlsm', &
          LBOUND(forczlsm), UBOUND(forczlsm))
        IF (PRESENT(forcwlsm)) CALL gpu_cc_done_r(222, forcwlsm, SIZE(forcwlsm,KIND=8), 'forcwlsm', &
          LBOUND(forcwlsm), UBOUND(forcwlsm))
        IF (PRESENT(acc_ssoil)) CALL gpu_cc_done_r(223, acc_ssoil, SIZE(acc_ssoil,KIND=8), 'acc_ssoil', &
          LBOUND(acc_ssoil), UBOUND(acc_ssoil))
        IF (PRESENT(acc_qinsur)) CALL gpu_cc_done_r(224, acc_qinsur, SIZE(acc_qinsur,KIND=8), 'acc_qinsur', &
          LBOUND(acc_qinsur), UBOUND(acc_qinsur))
        IF (PRESENT(acc_qseva)) CALL gpu_cc_done_r(225, acc_qseva, SIZE(acc_qseva,KIND=8), 'acc_qseva', &
          LBOUND(acc_qseva), UBOUND(acc_qseva))
        IF (PRESENT(acc_etrani)) CALL gpu_cc_done_r(226, acc_etrani, SIZE(acc_etrani,KIND=8), 'acc_etrani', &
          LBOUND(acc_etrani), UBOUND(acc_etrani))
        IF (PRESENT(eflxbxy)) CALL gpu_cc_done_r(227, eflxbxy, SIZE(eflxbxy,KIND=8), 'eflxbxy', &
          LBOUND(eflxbxy), UBOUND(eflxbxy))
        IF (PRESENT(soilenergy)) CALL gpu_cc_done_r(228, soilenergy, SIZE(soilenergy,KIND=8), 'soilenergy', &
          LBOUND(soilenergy), UBOUND(soilenergy))
        IF (PRESENT(snowenergy)) CALL gpu_cc_done_r(229, snowenergy, SIZE(snowenergy,KIND=8), 'snowenergy', &
          LBOUND(snowenergy), UBOUND(snowenergy))
        IF (PRESENT(canhsxy)) CALL gpu_cc_done_r(230, canhsxy, SIZE(canhsxy,KIND=8), 'canhsxy', &
          LBOUND(canhsxy), UBOUND(canhsxy))
        IF (PRESENT(acc_dwaterxy)) CALL gpu_cc_done_r(231, acc_dwaterxy, SIZE(acc_dwaterxy,KIND=8), 'acc_dwaterxy', &
          LBOUND(acc_dwaterxy), UBOUND(acc_dwaterxy))
        IF (PRESENT(acc_prcpxy)) CALL gpu_cc_done_r(232, acc_prcpxy, SIZE(acc_prcpxy,KIND=8), 'acc_prcpxy', &
          LBOUND(acc_prcpxy), UBOUND(acc_prcpxy))
        IF (PRESENT(acc_ecanxy)) CALL gpu_cc_done_r(233, acc_ecanxy, SIZE(acc_ecanxy,KIND=8), 'acc_ecanxy', &
          LBOUND(acc_ecanxy), UBOUND(acc_ecanxy))
        IF (PRESENT(acc_etranxy)) CALL gpu_cc_done_r(234, acc_etranxy, SIZE(acc_etranxy,KIND=8), 'acc_etranxy', &
          LBOUND(acc_etranxy), UBOUND(acc_etranxy))
        IF (PRESENT(acc_edirxy)) CALL gpu_cc_done_r(235, acc_edirxy, SIZE(acc_edirxy,KIND=8), 'acc_edirxy', &
          LBOUND(acc_edirxy), UBOUND(acc_edirxy))
        IF (PRESENT(irnumsi)) CALL gpu_cc_done_i(236, irnumsi, SIZE(irnumsi,KIND=8), 'irnumsi', &
          LBOUND(irnumsi), UBOUND(irnumsi))
        IF (PRESENT(irnummi)) CALL gpu_cc_done_i(237, irnummi, SIZE(irnummi,KIND=8), 'irnummi', &
          LBOUND(irnummi), UBOUND(irnummi))
        IF (PRESENT(irnumfi)) CALL gpu_cc_done_i(238, irnumfi, SIZE(irnumfi,KIND=8), 'irnumfi', &
          LBOUND(irnumfi), UBOUND(irnumfi))
        IF (PRESENT(irwatsi)) CALL gpu_cc_done_r(239, irwatsi, SIZE(irwatsi,KIND=8), 'irwatsi', &
          LBOUND(irwatsi), UBOUND(irwatsi))
        IF (PRESENT(irwatmi)) CALL gpu_cc_done_r(240, irwatmi, SIZE(irwatmi,KIND=8), 'irwatmi', &
          LBOUND(irwatmi), UBOUND(irwatmi))
        IF (PRESENT(irwatfi)) CALL gpu_cc_done_r(241, irwatfi, SIZE(irwatfi,KIND=8), 'irwatfi', &
          LBOUND(irwatfi), UBOUND(irwatfi))
        IF (PRESENT(ireloss)) CALL gpu_cc_done_r(242, ireloss, SIZE(ireloss,KIND=8), 'ireloss', &
          LBOUND(ireloss), UBOUND(ireloss))
        IF (PRESENT(irsivol)) CALL gpu_cc_done_r(243, irsivol, SIZE(irsivol,KIND=8), 'irsivol', &
          LBOUND(irsivol), UBOUND(irsivol))
        IF (PRESENT(irmivol)) CALL gpu_cc_done_r(244, irmivol, SIZE(irmivol,KIND=8), 'irmivol', &
          LBOUND(irmivol), UBOUND(irmivol))
        IF (PRESENT(irfivol)) CALL gpu_cc_done_r(245, irfivol, SIZE(irfivol,KIND=8), 'irfivol', &
          LBOUND(irfivol), UBOUND(irfivol))
        IF (PRESENT(irrsplh)) CALL gpu_cc_done_r(246, irrsplh, SIZE(irrsplh,KIND=8), 'irrsplh', &
          LBOUND(irrsplh), UBOUND(irrsplh))
        IF (PRESENT(qtdrain)) CALL gpu_cc_done_r(247, qtdrain, SIZE(qtdrain,KIND=8), 'qtdrain', &
          LBOUND(qtdrain), UBOUND(qtdrain))
        IF (PRESENT(smcwtdxy)) CALL gpu_cc_done_r(248, smcwtdxy, SIZE(smcwtdxy,KIND=8), 'smcwtdxy', &
          LBOUND(smcwtdxy), UBOUND(smcwtdxy))
        IF (PRESENT(rechxy)) CALL gpu_cc_done_r(249, rechxy, SIZE(rechxy,KIND=8), 'rechxy', &
          LBOUND(rechxy), UBOUND(rechxy))
        IF (PRESENT(deeprechxy)) CALL gpu_cc_done_r(250, deeprechxy, SIZE(deeprechxy,KIND=8), 'deeprechxy', &
          LBOUND(deeprechxy), UBOUND(deeprechxy))
        IF (PRESENT(fdepthxy)) CALL gpu_cc_done_r(251, fdepthxy, SIZE(fdepthxy,KIND=8), 'fdepthxy', &
          LBOUND(fdepthxy), UBOUND(fdepthxy))
        IF (PRESENT(areaxy)) CALL gpu_cc_done_r(252, areaxy, SIZE(areaxy,KIND=8), 'areaxy', &
          LBOUND(areaxy), UBOUND(areaxy))
        IF (PRESENT(rivercondxy)) CALL gpu_cc_done_r(253, rivercondxy, SIZE(rivercondxy,KIND=8), 'rivercondxy', &
          LBOUND(rivercondxy), UBOUND(rivercondxy))
        IF (PRESENT(riverbedxy)) CALL gpu_cc_done_r(254, riverbedxy, SIZE(riverbedxy,KIND=8), 'riverbedxy', &
          LBOUND(riverbedxy), UBOUND(riverbedxy))
        IF (PRESENT(eqzwt)) CALL gpu_cc_done_r(255, eqzwt, SIZE(eqzwt,KIND=8), 'eqzwt', &
          LBOUND(eqzwt), UBOUND(eqzwt))
        IF (PRESENT(pexpxy)) CALL gpu_cc_done_r(256, pexpxy, SIZE(pexpxy,KIND=8), 'pexpxy', &
          LBOUND(pexpxy), UBOUND(pexpxy))
        IF (PRESENT(qrfxy)) CALL gpu_cc_done_r(257, qrfxy, SIZE(qrfxy,KIND=8), 'qrfxy', &
          LBOUND(qrfxy), UBOUND(qrfxy))
        IF (PRESENT(qspringxy)) CALL gpu_cc_done_r(258, qspringxy, SIZE(qspringxy,KIND=8), 'qspringxy', &
          LBOUND(qspringxy), UBOUND(qspringxy))
        IF (PRESENT(qslatxy)) CALL gpu_cc_done_r(259, qslatxy, SIZE(qslatxy,KIND=8), 'qslatxy', &
          LBOUND(qslatxy), UBOUND(qslatxy))
        IF (PRESENT(qrfsxy)) CALL gpu_cc_done_r(260, qrfsxy, SIZE(qrfsxy,KIND=8), 'qrfsxy', &
          LBOUND(qrfsxy), UBOUND(qrfsxy))
        IF (PRESENT(qlatxy)) CALL gpu_cc_done_r(261, qlatxy, SIZE(qlatxy,KIND=8), 'qlatxy', &
          LBOUND(qlatxy), UBOUND(qlatxy))
        IF (PRESENT(qspringsxy)) CALL gpu_cc_done_r(262, qspringsxy, SIZE(qspringsxy,KIND=8), 'qspringsxy', &
          LBOUND(qspringsxy), UBOUND(qspringsxy))
        IF (PRESENT(smoiseq)) CALL gpu_cc_done_r(263, smoiseq, SIZE(smoiseq,KIND=8), 'smoiseq', &
          LBOUND(smoiseq), UBOUND(smoiseq))
        IF (PRESENT(gecros_state)) CALL gpu_cc_done_r(264, gecros_state, SIZE(gecros_state,KIND=8), 'gecros_state', &
          LBOUND(gecros_state), UBOUND(gecros_state))
        CALL gpu_cc_done_r(265, flx4, SIZE(flx4,KIND=8), 'flx4', &
          LBOUND(flx4), UBOUND(flx4))
        CALL gpu_cc_done_r(266, fvb, SIZE(fvb,KIND=8), 'fvb', &
          LBOUND(fvb), UBOUND(fvb))
        CALL gpu_cc_done_r(267, fbur, SIZE(fbur,KIND=8), 'fbur', &
          LBOUND(fbur), UBOUND(fbur))
        CALL gpu_cc_done_r(268, fgsn, SIZE(fgsn,KIND=8), 'fgsn', &
          LBOUND(fgsn), UBOUND(fgsn))
        IF (PRESENT(ch)) CALL gpu_cc_done_r(269, ch, SIZE(ch,KIND=8), 'ch', &
          LBOUND(ch), UBOUND(ch))
        IF (PRESENT(fgdp)) CALL gpu_cc_done_r(270, fgdp, SIZE(fgdp,KIND=8), 'fgdp', &
          LBOUND(fgdp), UBOUND(fgdp))
        IF (PRESENT(dfgdp)) CALL gpu_cc_done_r(271, dfgdp, SIZE(dfgdp,KIND=8), 'dfgdp', &
          LBOUND(dfgdp), UBOUND(dfgdp))
        IF (PRESENT(vdfg)) CALL gpu_cc_done_r(272, vdfg, SIZE(vdfg,KIND=8), 'vdfg', &
          LBOUND(vdfg), UBOUND(vdfg))
        CALL gpu_cc_done_r(273, water_depth, SIZE(water_depth,KIND=8), 'water_depth', &
          LBOUND(water_depth), UBOUND(water_depth))
        CALL gpu_cc_done_r(274, savedtke12d, SIZE(savedtke12d,KIND=8), 'savedtke12d', &
          LBOUND(savedtke12d), UBOUND(savedtke12d))
        CALL gpu_cc_done_r(275, snowdp2d, SIZE(snowdp2d,KIND=8), 'snowdp2d', &
          LBOUND(snowdp2d), UBOUND(snowdp2d))
        CALL gpu_cc_done_r(276, h2osno2d, SIZE(h2osno2d,KIND=8), 'h2osno2d', &
          LBOUND(h2osno2d), UBOUND(h2osno2d))
        CALL gpu_cc_done_r(277, snl2d, SIZE(snl2d,KIND=8), 'snl2d', &
          LBOUND(snl2d), UBOUND(snl2d))
        CALL gpu_cc_done_r(278, t_grnd2d, SIZE(t_grnd2d,KIND=8), 't_grnd2d', &
          LBOUND(t_grnd2d), UBOUND(t_grnd2d))
        CALL gpu_cc_done_r(279, t_lake3d, SIZE(t_lake3d,KIND=8), 't_lake3d', &
          LBOUND(t_lake3d), UBOUND(t_lake3d))
        CALL gpu_cc_done_r(280, lake_icefrac3d, SIZE(lake_icefrac3d,KIND=8), 'lake_icefrac3d', &
          LBOUND(lake_icefrac3d), UBOUND(lake_icefrac3d))
        CALL gpu_cc_done_r(281, t_soisno3d, SIZE(t_soisno3d,KIND=8), 't_soisno3d', &
          LBOUND(t_soisno3d), UBOUND(t_soisno3d))
        CALL gpu_cc_done_r(282, h2osoi_ice3d, SIZE(h2osoi_ice3d,KIND=8), 'h2osoi_ice3d', &
          LBOUND(h2osoi_ice3d), UBOUND(h2osoi_ice3d))
        CALL gpu_cc_done_r(283, h2osoi_liq3d, SIZE(h2osoi_liq3d,KIND=8), 'h2osoi_liq3d', &
          LBOUND(h2osoi_liq3d), UBOUND(h2osoi_liq3d))
        CALL gpu_cc_done_r(284, h2osoi_vol3d, SIZE(h2osoi_vol3d,KIND=8), 'h2osoi_vol3d', &
          LBOUND(h2osoi_vol3d), UBOUND(h2osoi_vol3d))
        CALL gpu_cc_done_r(285, z3d, SIZE(z3d,KIND=8), 'z3d', &
          LBOUND(z3d), UBOUND(z3d))
        CALL gpu_cc_done_r(286, dz3d, SIZE(dz3d,KIND=8), 'dz3d', &
          LBOUND(dz3d), UBOUND(dz3d))
        CALL gpu_cc_done_r(287, zi3d, SIZE(zi3d,KIND=8), 'zi3d', &
          LBOUND(zi3d), UBOUND(zi3d))
        CALL gpu_cc_done_r(288, lakemask, SIZE(lakemask,KIND=8), 'lakemask', &
          LBOUND(lakemask), UBOUND(lakemask))
        IF (PRESENT(om_tmp)) CALL gpu_cc_done_r(289, om_tmp, SIZE(om_tmp,KIND=8), 'om_tmp', &
          LBOUND(om_tmp), UBOUND(om_tmp))
        IF (PRESENT(om_s)) CALL gpu_cc_done_r(290, om_s, SIZE(om_s,KIND=8), 'om_s', &
          LBOUND(om_s), UBOUND(om_s))
        IF (PRESENT(om_u)) CALL gpu_cc_done_r(291, om_u, SIZE(om_u,KIND=8), 'om_u', &
          LBOUND(om_u), UBOUND(om_u))
        IF (PRESENT(om_v)) CALL gpu_cc_done_r(292, om_v, SIZE(om_v,KIND=8), 'om_v', &
          LBOUND(om_v), UBOUND(om_v))
        IF (PRESENT(om_depth)) CALL gpu_cc_done_r(293, om_depth, SIZE(om_depth,KIND=8), 'om_depth', &
          LBOUND(om_depth), UBOUND(om_depth))
        IF (PRESENT(om_ml)) CALL gpu_cc_done_r(294, om_ml, SIZE(om_ml,KIND=8), 'om_ml', &
          LBOUND(om_ml), UBOUND(om_ml))
        IF (PRESENT(om_lon)) CALL gpu_cc_done_r(295, om_lon, SIZE(om_lon,KIND=8), 'om_lon', &
          LBOUND(om_lon), UBOUND(om_lon))
        IF (PRESENT(om_lat)) CALL gpu_cc_done_r(296, om_lat, SIZE(om_lat,KIND=8), 'om_lat', &
          LBOUND(om_lat), UBOUND(om_lat))
        CALL gpu_cc_done_i0(297, okms, 'okms')
        CALL gpu_cc_done_i0(298, okme, 'okme')
#if (WRF_CHEM == 1)
        IF (PRESENT(e_bio)) CALL gpu_cc_done_r(299, e_bio, SIZE(e_bio,KIND=8), 'e_bio', &
          LBOUND(e_bio), UBOUND(e_bio))
#endif
        IF (PRESENT(numc)) CALL gpu_cc_done_i(300, numc, SIZE(numc,KIND=8), 'numc', &
          LBOUND(numc), UBOUND(numc))
        IF (PRESENT(nump)) CALL gpu_cc_done_i(301, nump, SIZE(nump,KIND=8), 'nump', &
          LBOUND(nump), UBOUND(nump))
        IF (PRESENT(sabv)) CALL gpu_cc_done_r(302, sabv, SIZE(sabv,KIND=8), 'sabv', &
          LBOUND(sabv), UBOUND(sabv))
        IF (PRESENT(sabg)) CALL gpu_cc_done_r(303, sabg, SIZE(sabg,KIND=8), 'sabg', &
          LBOUND(sabg), UBOUND(sabg))
        IF (PRESENT(lwup)) CALL gpu_cc_done_r(304, lwup, SIZE(lwup,KIND=8), 'lwup', &
          LBOUND(lwup), UBOUND(lwup))
        IF (PRESENT(snl)) CALL gpu_cc_done_i(305, snl, SIZE(snl,KIND=8), 'snl', &
          LBOUND(snl), UBOUND(snl))
        IF (PRESENT(snowdp)) CALL gpu_cc_done_r(306, snowdp, SIZE(snowdp,KIND=8), 'snowdp', &
          LBOUND(snowdp), UBOUND(snowdp))
        IF (PRESENT(wtc)) CALL gpu_cc_done_r(307, wtc, SIZE(wtc,KIND=8), 'wtc', &
          LBOUND(wtc), UBOUND(wtc))
        IF (PRESENT(wtp)) CALL gpu_cc_done_r(308, wtp, SIZE(wtp,KIND=8), 'wtp', &
          LBOUND(wtp), UBOUND(wtp))
        IF (PRESENT(h2osno)) CALL gpu_cc_done_r(309, h2osno, SIZE(h2osno,KIND=8), 'h2osno', &
          LBOUND(h2osno), UBOUND(h2osno))
        IF (PRESENT(t_grnd)) CALL gpu_cc_done_r(310, t_grnd, SIZE(t_grnd,KIND=8), 't_grnd', &
          LBOUND(t_grnd), UBOUND(t_grnd))
        IF (PRESENT(t_veg)) CALL gpu_cc_done_r(311, t_veg, SIZE(t_veg,KIND=8), 't_veg', &
          LBOUND(t_veg), UBOUND(t_veg))
        IF (PRESENT(h2ocan)) CALL gpu_cc_done_r(312, h2ocan, SIZE(h2ocan,KIND=8), 'h2ocan', &
          LBOUND(h2ocan), UBOUND(h2ocan))
        IF (PRESENT(h2ocan_col)) CALL gpu_cc_done_r(313, h2ocan_col, SIZE(h2ocan_col,KIND=8), 'h2ocan_col', &
          LBOUND(h2ocan_col), UBOUND(h2ocan_col))
        IF (PRESENT(t2m_max)) CALL gpu_cc_done_r(314, t2m_max, SIZE(t2m_max,KIND=8), 't2m_max', &
          LBOUND(t2m_max), UBOUND(t2m_max))
        IF (PRESENT(t2m_min)) CALL gpu_cc_done_r(315, t2m_min, SIZE(t2m_min,KIND=8), 't2m_min', &
          LBOUND(t2m_min), UBOUND(t2m_min))
        IF (PRESENT(t2clm)) CALL gpu_cc_done_r(316, t2clm, SIZE(t2clm,KIND=8), 't2clm', &
          LBOUND(t2clm), UBOUND(t2clm))
        IF (PRESENT(t_ref2m)) CALL gpu_cc_done_r(317, t_ref2m, SIZE(t_ref2m,KIND=8), 't_ref2m', &
          LBOUND(t_ref2m), UBOUND(t_ref2m))
        IF (PRESENT(h2osoi_liq_s1)) CALL gpu_cc_done_r(318, h2osoi_liq_s1, SIZE(h2osoi_liq_s1,KIND=8), 'h2osoi_liq_s1', &
          LBOUND(h2osoi_liq_s1), UBOUND(h2osoi_liq_s1))
        IF (PRESENT(h2osoi_liq_s2)) CALL gpu_cc_done_r(319, h2osoi_liq_s2, SIZE(h2osoi_liq_s2,KIND=8), 'h2osoi_liq_s2', &
          LBOUND(h2osoi_liq_s2), UBOUND(h2osoi_liq_s2))
        IF (PRESENT(h2osoi_liq_s3)) CALL gpu_cc_done_r(320, h2osoi_liq_s3, SIZE(h2osoi_liq_s3,KIND=8), 'h2osoi_liq_s3', &
          LBOUND(h2osoi_liq_s3), UBOUND(h2osoi_liq_s3))
        IF (PRESENT(h2osoi_liq_s4)) CALL gpu_cc_done_r(321, h2osoi_liq_s4, SIZE(h2osoi_liq_s4,KIND=8), 'h2osoi_liq_s4', &
          LBOUND(h2osoi_liq_s4), UBOUND(h2osoi_liq_s4))
        IF (PRESENT(h2osoi_liq_s5)) CALL gpu_cc_done_r(322, h2osoi_liq_s5, SIZE(h2osoi_liq_s5,KIND=8), 'h2osoi_liq_s5', &
          LBOUND(h2osoi_liq_s5), UBOUND(h2osoi_liq_s5))
        IF (PRESENT(h2osoi_liq1)) CALL gpu_cc_done_r(323, h2osoi_liq1, SIZE(h2osoi_liq1,KIND=8), 'h2osoi_liq1', &
          LBOUND(h2osoi_liq1), UBOUND(h2osoi_liq1))
        IF (PRESENT(h2osoi_liq2)) CALL gpu_cc_done_r(324, h2osoi_liq2, SIZE(h2osoi_liq2,KIND=8), 'h2osoi_liq2', &
          LBOUND(h2osoi_liq2), UBOUND(h2osoi_liq2))
        IF (PRESENT(h2osoi_liq3)) CALL gpu_cc_done_r(325, h2osoi_liq3, SIZE(h2osoi_liq3,KIND=8), 'h2osoi_liq3', &
          LBOUND(h2osoi_liq3), UBOUND(h2osoi_liq3))
        IF (PRESENT(h2osoi_liq4)) CALL gpu_cc_done_r(326, h2osoi_liq4, SIZE(h2osoi_liq4,KIND=8), 'h2osoi_liq4', &
          LBOUND(h2osoi_liq4), UBOUND(h2osoi_liq4))
        IF (PRESENT(h2osoi_liq5)) CALL gpu_cc_done_r(327, h2osoi_liq5, SIZE(h2osoi_liq5,KIND=8), 'h2osoi_liq5', &
          LBOUND(h2osoi_liq5), UBOUND(h2osoi_liq5))
        IF (PRESENT(h2osoi_liq6)) CALL gpu_cc_done_r(328, h2osoi_liq6, SIZE(h2osoi_liq6,KIND=8), 'h2osoi_liq6', &
          LBOUND(h2osoi_liq6), UBOUND(h2osoi_liq6))
        IF (PRESENT(h2osoi_liq7)) CALL gpu_cc_done_r(329, h2osoi_liq7, SIZE(h2osoi_liq7,KIND=8), 'h2osoi_liq7', &
          LBOUND(h2osoi_liq7), UBOUND(h2osoi_liq7))
        IF (PRESENT(h2osoi_liq8)) CALL gpu_cc_done_r(330, h2osoi_liq8, SIZE(h2osoi_liq8,KIND=8), 'h2osoi_liq8', &
          LBOUND(h2osoi_liq8), UBOUND(h2osoi_liq8))
        IF (PRESENT(h2osoi_liq9)) CALL gpu_cc_done_r(331, h2osoi_liq9, SIZE(h2osoi_liq9,KIND=8), 'h2osoi_liq9', &
          LBOUND(h2osoi_liq9), UBOUND(h2osoi_liq9))
        IF (PRESENT(h2osoi_liq10)) CALL gpu_cc_done_r(332, h2osoi_liq10, SIZE(h2osoi_liq10,KIND=8), 'h2osoi_liq10', &
          LBOUND(h2osoi_liq10), UBOUND(h2osoi_liq10))
        IF (PRESENT(h2osoi_ice_s1)) CALL gpu_cc_done_r(333, h2osoi_ice_s1, SIZE(h2osoi_ice_s1,KIND=8), 'h2osoi_ice_s1', &
          LBOUND(h2osoi_ice_s1), UBOUND(h2osoi_ice_s1))
        IF (PRESENT(h2osoi_ice_s2)) CALL gpu_cc_done_r(334, h2osoi_ice_s2, SIZE(h2osoi_ice_s2,KIND=8), 'h2osoi_ice_s2', &
          LBOUND(h2osoi_ice_s2), UBOUND(h2osoi_ice_s2))
        IF (PRESENT(h2osoi_ice_s3)) CALL gpu_cc_done_r(335, h2osoi_ice_s3, SIZE(h2osoi_ice_s3,KIND=8), 'h2osoi_ice_s3', &
          LBOUND(h2osoi_ice_s3), UBOUND(h2osoi_ice_s3))
        IF (PRESENT(h2osoi_ice_s4)) CALL gpu_cc_done_r(336, h2osoi_ice_s4, SIZE(h2osoi_ice_s4,KIND=8), 'h2osoi_ice_s4', &
          LBOUND(h2osoi_ice_s4), UBOUND(h2osoi_ice_s4))
        IF (PRESENT(h2osoi_ice_s5)) CALL gpu_cc_done_r(337, h2osoi_ice_s5, SIZE(h2osoi_ice_s5,KIND=8), 'h2osoi_ice_s5', &
          LBOUND(h2osoi_ice_s5), UBOUND(h2osoi_ice_s5))
        IF (PRESENT(h2osoi_ice1)) CALL gpu_cc_done_r(338, h2osoi_ice1, SIZE(h2osoi_ice1,KIND=8), 'h2osoi_ice1', &
          LBOUND(h2osoi_ice1), UBOUND(h2osoi_ice1))
        IF (PRESENT(h2osoi_ice2)) CALL gpu_cc_done_r(339, h2osoi_ice2, SIZE(h2osoi_ice2,KIND=8), 'h2osoi_ice2', &
          LBOUND(h2osoi_ice2), UBOUND(h2osoi_ice2))
        IF (PRESENT(h2osoi_ice3)) CALL gpu_cc_done_r(340, h2osoi_ice3, SIZE(h2osoi_ice3,KIND=8), 'h2osoi_ice3', &
          LBOUND(h2osoi_ice3), UBOUND(h2osoi_ice3))
        IF (PRESENT(h2osoi_ice4)) CALL gpu_cc_done_r(341, h2osoi_ice4, SIZE(h2osoi_ice4,KIND=8), 'h2osoi_ice4', &
          LBOUND(h2osoi_ice4), UBOUND(h2osoi_ice4))
        IF (PRESENT(h2osoi_ice5)) CALL gpu_cc_done_r(342, h2osoi_ice5, SIZE(h2osoi_ice5,KIND=8), 'h2osoi_ice5', &
          LBOUND(h2osoi_ice5), UBOUND(h2osoi_ice5))
        IF (PRESENT(h2osoi_ice6)) CALL gpu_cc_done_r(343, h2osoi_ice6, SIZE(h2osoi_ice6,KIND=8), 'h2osoi_ice6', &
          LBOUND(h2osoi_ice6), UBOUND(h2osoi_ice6))
        IF (PRESENT(h2osoi_ice7)) CALL gpu_cc_done_r(344, h2osoi_ice7, SIZE(h2osoi_ice7,KIND=8), 'h2osoi_ice7', &
          LBOUND(h2osoi_ice7), UBOUND(h2osoi_ice7))
        IF (PRESENT(h2osoi_ice8)) CALL gpu_cc_done_r(345, h2osoi_ice8, SIZE(h2osoi_ice8,KIND=8), 'h2osoi_ice8', &
          LBOUND(h2osoi_ice8), UBOUND(h2osoi_ice8))
        IF (PRESENT(h2osoi_ice9)) CALL gpu_cc_done_r(346, h2osoi_ice9, SIZE(h2osoi_ice9,KIND=8), 'h2osoi_ice9', &
          LBOUND(h2osoi_ice9), UBOUND(h2osoi_ice9))
        IF (PRESENT(h2osoi_ice10)) CALL gpu_cc_done_r(347, h2osoi_ice10, SIZE(h2osoi_ice10,KIND=8), 'h2osoi_ice10', &
          LBOUND(h2osoi_ice10), UBOUND(h2osoi_ice10))
        IF (PRESENT(t_soisno_s1)) CALL gpu_cc_done_r(348, t_soisno_s1, SIZE(t_soisno_s1,KIND=8), 't_soisno_s1', &
          LBOUND(t_soisno_s1), UBOUND(t_soisno_s1))
        IF (PRESENT(t_soisno_s2)) CALL gpu_cc_done_r(349, t_soisno_s2, SIZE(t_soisno_s2,KIND=8), 't_soisno_s2', &
          LBOUND(t_soisno_s2), UBOUND(t_soisno_s2))
        IF (PRESENT(t_soisno_s3)) CALL gpu_cc_done_r(350, t_soisno_s3, SIZE(t_soisno_s3,KIND=8), 't_soisno_s3', &
          LBOUND(t_soisno_s3), UBOUND(t_soisno_s3))
        IF (PRESENT(t_soisno_s4)) CALL gpu_cc_done_r(351, t_soisno_s4, SIZE(t_soisno_s4,KIND=8), 't_soisno_s4', &
          LBOUND(t_soisno_s4), UBOUND(t_soisno_s4))
        IF (PRESENT(t_soisno_s5)) CALL gpu_cc_done_r(352, t_soisno_s5, SIZE(t_soisno_s5,KIND=8), 't_soisno_s5', &
          LBOUND(t_soisno_s5), UBOUND(t_soisno_s5))
        IF (PRESENT(t_soisno1)) CALL gpu_cc_done_r(353, t_soisno1, SIZE(t_soisno1,KIND=8), 't_soisno1', &
          LBOUND(t_soisno1), UBOUND(t_soisno1))
        IF (PRESENT(t_soisno2)) CALL gpu_cc_done_r(354, t_soisno2, SIZE(t_soisno2,KIND=8), 't_soisno2', &
          LBOUND(t_soisno2), UBOUND(t_soisno2))
        IF (PRESENT(t_soisno3)) CALL gpu_cc_done_r(355, t_soisno3, SIZE(t_soisno3,KIND=8), 't_soisno3', &
          LBOUND(t_soisno3), UBOUND(t_soisno3))
        IF (PRESENT(t_soisno4)) CALL gpu_cc_done_r(356, t_soisno4, SIZE(t_soisno4,KIND=8), 't_soisno4', &
          LBOUND(t_soisno4), UBOUND(t_soisno4))
        IF (PRESENT(t_soisno5)) CALL gpu_cc_done_r(357, t_soisno5, SIZE(t_soisno5,KIND=8), 't_soisno5', &
          LBOUND(t_soisno5), UBOUND(t_soisno5))
        IF (PRESENT(t_soisno6)) CALL gpu_cc_done_r(358, t_soisno6, SIZE(t_soisno6,KIND=8), 't_soisno6', &
          LBOUND(t_soisno6), UBOUND(t_soisno6))
        IF (PRESENT(t_soisno7)) CALL gpu_cc_done_r(359, t_soisno7, SIZE(t_soisno7,KIND=8), 't_soisno7', &
          LBOUND(t_soisno7), UBOUND(t_soisno7))
        IF (PRESENT(t_soisno8)) CALL gpu_cc_done_r(360, t_soisno8, SIZE(t_soisno8,KIND=8), 't_soisno8', &
          LBOUND(t_soisno8), UBOUND(t_soisno8))
        IF (PRESENT(t_soisno9)) CALL gpu_cc_done_r(361, t_soisno9, SIZE(t_soisno9,KIND=8), 't_soisno9', &
          LBOUND(t_soisno9), UBOUND(t_soisno9))
        IF (PRESENT(t_soisno10)) CALL gpu_cc_done_r(362, t_soisno10, SIZE(t_soisno10,KIND=8), 't_soisno10', &
          LBOUND(t_soisno10), UBOUND(t_soisno10))
        IF (PRESENT(dzsnow1)) CALL gpu_cc_done_r(363, dzsnow1, SIZE(dzsnow1,KIND=8), 'dzsnow1', &
          LBOUND(dzsnow1), UBOUND(dzsnow1))
        IF (PRESENT(dzsnow2)) CALL gpu_cc_done_r(364, dzsnow2, SIZE(dzsnow2,KIND=8), 'dzsnow2', &
          LBOUND(dzsnow2), UBOUND(dzsnow2))
        IF (PRESENT(dzsnow3)) CALL gpu_cc_done_r(365, dzsnow3, SIZE(dzsnow3,KIND=8), 'dzsnow3', &
          LBOUND(dzsnow3), UBOUND(dzsnow3))
        IF (PRESENT(dzsnow4)) CALL gpu_cc_done_r(366, dzsnow4, SIZE(dzsnow4,KIND=8), 'dzsnow4', &
          LBOUND(dzsnow4), UBOUND(dzsnow4))
        IF (PRESENT(dzsnow5)) CALL gpu_cc_done_r(367, dzsnow5, SIZE(dzsnow5,KIND=8), 'dzsnow5', &
          LBOUND(dzsnow5), UBOUND(dzsnow5))
        IF (PRESENT(snowrds1)) CALL gpu_cc_done_r(368, snowrds1, SIZE(snowrds1,KIND=8), 'snowrds1', &
          LBOUND(snowrds1), UBOUND(snowrds1))
        IF (PRESENT(snowrds2)) CALL gpu_cc_done_r(369, snowrds2, SIZE(snowrds2,KIND=8), 'snowrds2', &
          LBOUND(snowrds2), UBOUND(snowrds2))
        IF (PRESENT(snowrds3)) CALL gpu_cc_done_r(370, snowrds3, SIZE(snowrds3,KIND=8), 'snowrds3', &
          LBOUND(snowrds3), UBOUND(snowrds3))
        IF (PRESENT(snowrds4)) CALL gpu_cc_done_r(371, snowrds4, SIZE(snowrds4,KIND=8), 'snowrds4', &
          LBOUND(snowrds4), UBOUND(snowrds4))
        IF (PRESENT(snowrds5)) CALL gpu_cc_done_r(372, snowrds5, SIZE(snowrds5,KIND=8), 'snowrds5', &
          LBOUND(snowrds5), UBOUND(snowrds5))
        IF (PRESENT(t_lake1)) CALL gpu_cc_done_r(373, t_lake1, SIZE(t_lake1,KIND=8), 't_lake1', &
          LBOUND(t_lake1), UBOUND(t_lake1))
        IF (PRESENT(t_lake2)) CALL gpu_cc_done_r(374, t_lake2, SIZE(t_lake2,KIND=8), 't_lake2', &
          LBOUND(t_lake2), UBOUND(t_lake2))
        IF (PRESENT(t_lake3)) CALL gpu_cc_done_r(375, t_lake3, SIZE(t_lake3,KIND=8), 't_lake3', &
          LBOUND(t_lake3), UBOUND(t_lake3))
        IF (PRESENT(t_lake4)) CALL gpu_cc_done_r(376, t_lake4, SIZE(t_lake4,KIND=8), 't_lake4', &
          LBOUND(t_lake4), UBOUND(t_lake4))
        IF (PRESENT(t_lake5)) CALL gpu_cc_done_r(377, t_lake5, SIZE(t_lake5,KIND=8), 't_lake5', &
          LBOUND(t_lake5), UBOUND(t_lake5))
        IF (PRESENT(t_lake6)) CALL gpu_cc_done_r(378, t_lake6, SIZE(t_lake6,KIND=8), 't_lake6', &
          LBOUND(t_lake6), UBOUND(t_lake6))
        IF (PRESENT(t_lake7)) CALL gpu_cc_done_r(379, t_lake7, SIZE(t_lake7,KIND=8), 't_lake7', &
          LBOUND(t_lake7), UBOUND(t_lake7))
        IF (PRESENT(t_lake8)) CALL gpu_cc_done_r(380, t_lake8, SIZE(t_lake8,KIND=8), 't_lake8', &
          LBOUND(t_lake8), UBOUND(t_lake8))
        IF (PRESENT(t_lake9)) CALL gpu_cc_done_r(381, t_lake9, SIZE(t_lake9,KIND=8), 't_lake9', &
          LBOUND(t_lake9), UBOUND(t_lake9))
        IF (PRESENT(t_lake10)) CALL gpu_cc_done_r(382, t_lake10, SIZE(t_lake10,KIND=8), 't_lake10', &
          LBOUND(t_lake10), UBOUND(t_lake10))
        IF (PRESENT(h2osoi_vol1)) CALL gpu_cc_done_r(383, h2osoi_vol1, SIZE(h2osoi_vol1,KIND=8), 'h2osoi_vol1', &
          LBOUND(h2osoi_vol1), UBOUND(h2osoi_vol1))
        IF (PRESENT(h2osoi_vol2)) CALL gpu_cc_done_r(384, h2osoi_vol2, SIZE(h2osoi_vol2,KIND=8), 'h2osoi_vol2', &
          LBOUND(h2osoi_vol2), UBOUND(h2osoi_vol2))
        IF (PRESENT(h2osoi_vol3)) CALL gpu_cc_done_r(385, h2osoi_vol3, SIZE(h2osoi_vol3,KIND=8), 'h2osoi_vol3', &
          LBOUND(h2osoi_vol3), UBOUND(h2osoi_vol3))
        IF (PRESENT(h2osoi_vol4)) CALL gpu_cc_done_r(386, h2osoi_vol4, SIZE(h2osoi_vol4,KIND=8), 'h2osoi_vol4', &
          LBOUND(h2osoi_vol4), UBOUND(h2osoi_vol4))
        IF (PRESENT(h2osoi_vol5)) CALL gpu_cc_done_r(387, h2osoi_vol5, SIZE(h2osoi_vol5,KIND=8), 'h2osoi_vol5', &
          LBOUND(h2osoi_vol5), UBOUND(h2osoi_vol5))
        IF (PRESENT(h2osoi_vol6)) CALL gpu_cc_done_r(388, h2osoi_vol6, SIZE(h2osoi_vol6,KIND=8), 'h2osoi_vol6', &
          LBOUND(h2osoi_vol6), UBOUND(h2osoi_vol6))
        IF (PRESENT(h2osoi_vol7)) CALL gpu_cc_done_r(389, h2osoi_vol7, SIZE(h2osoi_vol7,KIND=8), 'h2osoi_vol7', &
          LBOUND(h2osoi_vol7), UBOUND(h2osoi_vol7))
        IF (PRESENT(h2osoi_vol8)) CALL gpu_cc_done_r(390, h2osoi_vol8, SIZE(h2osoi_vol8,KIND=8), 'h2osoi_vol8', &
          LBOUND(h2osoi_vol8), UBOUND(h2osoi_vol8))
        IF (PRESENT(h2osoi_vol9)) CALL gpu_cc_done_r(391, h2osoi_vol9, SIZE(h2osoi_vol9,KIND=8), 'h2osoi_vol9', &
          LBOUND(h2osoi_vol9), UBOUND(h2osoi_vol9))
        IF (PRESENT(h2osoi_vol10)) CALL gpu_cc_done_r(392, h2osoi_vol10, SIZE(h2osoi_vol10,KIND=8), 'h2osoi_vol10', &
          LBOUND(h2osoi_vol10), UBOUND(h2osoi_vol10))
        IF (PRESENT(albedosubgrid)) CALL gpu_cc_done_r(393, albedosubgrid, SIZE(albedosubgrid,KIND=8), 'albedosubgrid', &
          LBOUND(albedosubgrid), UBOUND(albedosubgrid))
        IF (PRESENT(lhsubgrid)) CALL gpu_cc_done_r(394, lhsubgrid, SIZE(lhsubgrid,KIND=8), 'lhsubgrid', &
          LBOUND(lhsubgrid), UBOUND(lhsubgrid))
        IF (PRESENT(hfxsubgrid)) CALL gpu_cc_done_r(395, hfxsubgrid, SIZE(hfxsubgrid,KIND=8), 'hfxsubgrid', &
          LBOUND(hfxsubgrid), UBOUND(hfxsubgrid))
        IF (PRESENT(lwupsubgrid)) CALL gpu_cc_done_r(396, lwupsubgrid, SIZE(lwupsubgrid,KIND=8), 'lwupsubgrid', &
          LBOUND(lwupsubgrid), UBOUND(lwupsubgrid))
        IF (PRESENT(q2subgrid)) CALL gpu_cc_done_r(397, q2subgrid, SIZE(q2subgrid,KIND=8), 'q2subgrid', &
          LBOUND(q2subgrid), UBOUND(q2subgrid))
        IF (PRESENT(sabvsubgrid)) CALL gpu_cc_done_r(398, sabvsubgrid, SIZE(sabvsubgrid,KIND=8), 'sabvsubgrid', &
          LBOUND(sabvsubgrid), UBOUND(sabvsubgrid))
        IF (PRESENT(sabgsubgrid)) CALL gpu_cc_done_r(399, sabgsubgrid, SIZE(sabgsubgrid,KIND=8), 'sabgsubgrid', &
          LBOUND(sabgsubgrid), UBOUND(sabgsubgrid))
        IF (PRESENT(nrasubgrid)) CALL gpu_cc_done_r(400, nrasubgrid, SIZE(nrasubgrid,KIND=8), 'nrasubgrid', &
          LBOUND(nrasubgrid), UBOUND(nrasubgrid))
        IF (PRESENT(swupsubgrid)) CALL gpu_cc_done_r(401, swupsubgrid, SIZE(swupsubgrid,KIND=8), 'swupsubgrid', &
          LBOUND(swupsubgrid), UBOUND(swupsubgrid))
        IF (PRESENT(lhsoi)) CALL gpu_cc_done_r(402, lhsoi, SIZE(lhsoi,KIND=8), 'lhsoi', &
          LBOUND(lhsoi), UBOUND(lhsoi))
        IF (PRESENT(lhveg)) CALL gpu_cc_done_r(403, lhveg, SIZE(lhveg,KIND=8), 'lhveg', &
          LBOUND(lhveg), UBOUND(lhveg))
        IF (PRESENT(lhtran)) CALL gpu_cc_done_r(404, lhtran, SIZE(lhtran,KIND=8), 'lhtran', &
          LBOUND(lhtran), UBOUND(lhtran))
        IF (PRESENT(t_veg24)) CALL gpu_cc_done_r(405, t_veg24, SIZE(t_veg24,KIND=8), 't_veg24', &
          LBOUND(t_veg24), UBOUND(t_veg24))
        IF (PRESENT(t_veg240)) CALL gpu_cc_done_r(406, t_veg240, SIZE(t_veg240,KIND=8), 't_veg240', &
          LBOUND(t_veg240), UBOUND(t_veg240))
        IF (PRESENT(fsun24)) CALL gpu_cc_done_r(407, fsun24, SIZE(fsun24,KIND=8), 'fsun24', &
          LBOUND(fsun24), UBOUND(fsun24))
        IF (PRESENT(fsun240)) CALL gpu_cc_done_r(408, fsun240, SIZE(fsun240,KIND=8), 'fsun240', &
          LBOUND(fsun240), UBOUND(fsun240))
        IF (PRESENT(fsd24)) CALL gpu_cc_done_r(409, fsd24, SIZE(fsd24,KIND=8), 'fsd24', &
          LBOUND(fsd24), UBOUND(fsd24))
        IF (PRESENT(fsd240)) CALL gpu_cc_done_r(410, fsd240, SIZE(fsd240,KIND=8), 'fsd240', &
          LBOUND(fsd240), UBOUND(fsd240))
        IF (PRESENT(fsi24)) CALL gpu_cc_done_r(411, fsi24, SIZE(fsi24,KIND=8), 'fsi24', &
          LBOUND(fsi24), UBOUND(fsi24))
        IF (PRESENT(fsi240)) CALL gpu_cc_done_r(412, fsi240, SIZE(fsi240,KIND=8), 'fsi240', &
          LBOUND(fsi240), UBOUND(fsi240))
        IF (PRESENT(laip)) CALL gpu_cc_done_r(413, laip, SIZE(laip,KIND=8), 'laip', &
          LBOUND(laip), UBOUND(laip))
#ifdef CN
        IF (PRESENT(dyntlai)) CALL gpu_cc_done_r(414, dyntlai, SIZE(dyntlai,KIND=8), 'dyntlai', &
          LBOUND(dyntlai), UBOUND(dyntlai))
#endif
#ifdef CN
        IF (PRESENT(dyntsai)) CALL gpu_cc_done_r(415, dyntsai, SIZE(dyntsai,KIND=8), 'dyntsai', &
          LBOUND(dyntsai), UBOUND(dyntsai))
#endif
#ifdef CN
        IF (PRESENT(dyntop)) CALL gpu_cc_done_r(416, dyntop, SIZE(dyntop,KIND=8), 'dyntop', &
          LBOUND(dyntop), UBOUND(dyntop))
#endif
#ifdef CN
        IF (PRESENT(dynbot)) CALL gpu_cc_done_r(417, dynbot, SIZE(dynbot,KIND=8), 'dynbot', &
          LBOUND(dynbot), UBOUND(dynbot))
#endif
#ifdef CN
        IF (PRESENT(htmx)) CALL gpu_cc_done_r(418, htmx, SIZE(htmx,KIND=8), 'htmx', &
          LBOUND(htmx), UBOUND(htmx))
#endif
#ifdef CN
        IF (PRESENT(croplive)) CALL gpu_cc_done_i(419, croplive, SIZE(croplive,KIND=8), 'croplive', &
          LBOUND(croplive), UBOUND(croplive))
#endif
#ifdef CN
        IF (PRESENT(gdd1020)) CALL gpu_cc_done_r(420, gdd1020, SIZE(gdd1020,KIND=8), 'gdd1020', &
          LBOUND(gdd1020), UBOUND(gdd1020))
#endif
#ifdef CN
        IF (PRESENT(gdd820)) CALL gpu_cc_done_r(421, gdd820, SIZE(gdd820,KIND=8), 'gdd820', &
          LBOUND(gdd820), UBOUND(gdd820))
#endif
#ifdef CN
        IF (PRESENT(gdd020)) CALL gpu_cc_done_r(422, gdd020, SIZE(gdd020,KIND=8), 'gdd020', &
          LBOUND(gdd020), UBOUND(gdd020))
#endif
#ifdef CN
        IF (PRESENT(grainc)) CALL gpu_cc_done_r(423, grainc, SIZE(grainc,KIND=8), 'grainc', &
          LBOUND(grainc), UBOUND(grainc))
#endif
#ifdef CN
        IF (PRESENT(grainc_storage)) CALL gpu_cc_done_r(424, grainc_storage, SIZE(grainc_storage,KIND=8), 'grainc_storage', &
          LBOUND(grainc_storage), UBOUND(grainc_storage))
#endif
#ifdef CN
        IF (PRESENT(grainc_xfer)) CALL gpu_cc_done_r(425, grainc_xfer, SIZE(grainc_xfer,KIND=8), 'grainc_xfer', &
          LBOUND(grainc_xfer), UBOUND(grainc_xfer))
#endif
#ifdef CN
        IF (PRESENT(grainn)) CALL gpu_cc_done_r(426, grainn, SIZE(grainn,KIND=8), 'grainn', &
          LBOUND(grainn), UBOUND(grainn))
#endif
#ifdef CN
        IF (PRESENT(grainn_storage)) CALL gpu_cc_done_r(427, grainn_storage, SIZE(grainn_storage,KIND=8), 'grainn_storage', &
          LBOUND(grainn_storage), UBOUND(grainn_storage))
#endif
#ifdef CN
        IF (PRESENT(grainn_xfer)) CALL gpu_cc_done_r(428, grainn_xfer, SIZE(grainn_xfer,KIND=8), 'grainn_xfer', &
          LBOUND(grainn_xfer), UBOUND(grainn_xfer))
#endif
#ifdef CN
        IF (PRESENT(days_active)) CALL gpu_cc_done_r(429, days_active, SIZE(days_active,KIND=8), 'days_active', &
          LBOUND(days_active), UBOUND(days_active))
#endif
#ifdef CN
        IF (PRESENT(onset_flag)) CALL gpu_cc_done_r(430, onset_flag, SIZE(onset_flag,KIND=8), 'onset_flag', &
          LBOUND(onset_flag), UBOUND(onset_flag))
#endif
#ifdef CN
        IF (PRESENT(onset_counter)) CALL gpu_cc_done_r(431, onset_counter, SIZE(onset_counter,KIND=8), 'onset_counter', &
          LBOUND(onset_counter), UBOUND(onset_counter))
#endif
#ifdef CN
        IF (PRESENT(onset_gddflag)) CALL gpu_cc_done_r(432, onset_gddflag, SIZE(onset_gddflag,KIND=8), 'onset_gddflag', &
          LBOUND(onset_gddflag), UBOUND(onset_gddflag))
#endif
#ifdef CN
        IF (PRESENT(onset_fdd)) CALL gpu_cc_done_r(433, onset_fdd, SIZE(onset_fdd,KIND=8), 'onset_fdd', &
          LBOUND(onset_fdd), UBOUND(onset_fdd))
#endif
#ifdef CN
        IF (PRESENT(onset_gdd)) CALL gpu_cc_done_r(434, onset_gdd, SIZE(onset_gdd,KIND=8), 'onset_gdd', &
          LBOUND(onset_gdd), UBOUND(onset_gdd))
#endif
#ifdef CN
        IF (PRESENT(onset_swi)) CALL gpu_cc_done_r(435, onset_swi, SIZE(onset_swi,KIND=8), 'onset_swi', &
          LBOUND(onset_swi), UBOUND(onset_swi))
#endif
#ifdef CN
        IF (PRESENT(offset_flag)) CALL gpu_cc_done_r(436, offset_flag, SIZE(offset_flag,KIND=8), 'offset_flag', &
          LBOUND(offset_flag), UBOUND(offset_flag))
#endif
#ifdef CN
        IF (PRESENT(offset_counter)) CALL gpu_cc_done_r(437, offset_counter, SIZE(offset_counter,KIND=8), 'offset_counter', &
          LBOUND(offset_counter), UBOUND(offset_counter))
#endif
#ifdef CN
        IF (PRESENT(offset_fdd)) CALL gpu_cc_done_r(438, offset_fdd, SIZE(offset_fdd,KIND=8), 'offset_fdd', &
          LBOUND(offset_fdd), UBOUND(offset_fdd))
#endif
#ifdef CN
        IF (PRESENT(offset_swi)) CALL gpu_cc_done_r(439, offset_swi, SIZE(offset_swi,KIND=8), 'offset_swi', &
          LBOUND(offset_swi), UBOUND(offset_swi))
#endif
#ifdef CN
        IF (PRESENT(dayl)) CALL gpu_cc_done_r(440, dayl, SIZE(dayl,KIND=8), 'dayl', &
          LBOUND(dayl), UBOUND(dayl))
#endif
#ifdef CN
        IF (PRESENT(annavg_t2m)) CALL gpu_cc_done_r(441, annavg_t2m, SIZE(annavg_t2m,KIND=8), 'annavg_t2m', &
          LBOUND(annavg_t2m), UBOUND(annavg_t2m))
#endif
#ifdef CN
        IF (PRESENT(tempavg_t2m)) CALL gpu_cc_done_r(442, tempavg_t2m, SIZE(tempavg_t2m,KIND=8), 'tempavg_t2m', &
          LBOUND(tempavg_t2m), UBOUND(tempavg_t2m))
#endif
#ifdef CN
        IF (PRESENT(tempsum_potential_gpp)) CALL gpu_cc_done_r(443, tempsum_potential_gpp, SIZE(tempsum_potential_gpp,KIND=8), 'tempsum_potential_gpp', &
          LBOUND(tempsum_potential_gpp), UBOUND(tempsum_potential_gpp))
#endif
#ifdef CN
        IF (PRESENT(annsum_potential_gpp)) CALL gpu_cc_done_r(444, annsum_potential_gpp, SIZE(annsum_potential_gpp,KIND=8), 'annsum_potential_gpp', &
          LBOUND(annsum_potential_gpp), UBOUND(annsum_potential_gpp))
#endif
#ifdef CN
        IF (PRESENT(tempmax_retransn)) CALL gpu_cc_done_r(445, tempmax_retransn, SIZE(tempmax_retransn,KIND=8), 'tempmax_retransn', &
          LBOUND(tempmax_retransn), UBOUND(tempmax_retransn))
#endif
#ifdef CN
        IF (PRESENT(annmax_retransn)) CALL gpu_cc_done_r(446, annmax_retransn, SIZE(annmax_retransn,KIND=8), 'annmax_retransn', &
          LBOUND(annmax_retransn), UBOUND(annmax_retransn))
#endif
#ifdef CN
        IF (PRESENT(prev_leafc_to_litter)) CALL gpu_cc_done_r(447, prev_leafc_to_litter, SIZE(prev_leafc_to_litter,KIND=8), 'prev_leafc_to_litter', &
          LBOUND(prev_leafc_to_litter), UBOUND(prev_leafc_to_litter))
#endif
#ifdef CN
        IF (PRESENT(prev_frootc_to_litter)) CALL gpu_cc_done_r(448, prev_frootc_to_litter, SIZE(prev_frootc_to_litter,KIND=8), 'prev_frootc_to_litter', &
          LBOUND(prev_frootc_to_litter), UBOUND(prev_frootc_to_litter))
#endif
#ifdef CN
        IF (PRESENT(tempsum_npp)) CALL gpu_cc_done_r(449, tempsum_npp, SIZE(tempsum_npp,KIND=8), 'tempsum_npp', &
          LBOUND(tempsum_npp), UBOUND(tempsum_npp))
#endif
#ifdef CN
        IF (PRESENT(annsum_npp)) CALL gpu_cc_done_r(450, annsum_npp, SIZE(annsum_npp,KIND=8), 'annsum_npp', &
          LBOUND(annsum_npp), UBOUND(annsum_npp))
#endif
#ifdef CN
        IF (PRESENT(leafc)) CALL gpu_cc_done_r(451, leafc, SIZE(leafc,KIND=8), 'leafc', &
          LBOUND(leafc), UBOUND(leafc))
#endif
#ifdef CN
        IF (PRESENT(leafc_storage)) CALL gpu_cc_done_r(452, leafc_storage, SIZE(leafc_storage,KIND=8), 'leafc_storage', &
          LBOUND(leafc_storage), UBOUND(leafc_storage))
#endif
#ifdef CN
        IF (PRESENT(leafc_xfer)) CALL gpu_cc_done_r(453, leafc_xfer, SIZE(leafc_xfer,KIND=8), 'leafc_xfer', &
          LBOUND(leafc_xfer), UBOUND(leafc_xfer))
#endif
#ifdef CN
        IF (PRESENT(frootc)) CALL gpu_cc_done_r(454, frootc, SIZE(frootc,KIND=8), 'frootc', &
          LBOUND(frootc), UBOUND(frootc))
#endif
#ifdef CN
        IF (PRESENT(frootc_storage)) CALL gpu_cc_done_r(455, frootc_storage, SIZE(frootc_storage,KIND=8), 'frootc_storage', &
          LBOUND(frootc_storage), UBOUND(frootc_storage))
#endif
#ifdef CN
        IF (PRESENT(frootc_xfer)) CALL gpu_cc_done_r(456, frootc_xfer, SIZE(frootc_xfer,KIND=8), 'frootc_xfer', &
          LBOUND(frootc_xfer), UBOUND(frootc_xfer))
#endif
#ifdef CN
        IF (PRESENT(livestemc)) CALL gpu_cc_done_r(457, livestemc, SIZE(livestemc,KIND=8), 'livestemc', &
          LBOUND(livestemc), UBOUND(livestemc))
#endif
#ifdef CN
        IF (PRESENT(livestemc_storage)) CALL gpu_cc_done_r(458, livestemc_storage, SIZE(livestemc_storage,KIND=8), 'livestemc_storage', &
          LBOUND(livestemc_storage), UBOUND(livestemc_storage))
#endif
#ifdef CN
        IF (PRESENT(livestemc_xfer)) CALL gpu_cc_done_r(459, livestemc_xfer, SIZE(livestemc_xfer,KIND=8), 'livestemc_xfer', &
          LBOUND(livestemc_xfer), UBOUND(livestemc_xfer))
#endif
#ifdef CN
        IF (PRESENT(deadstemc)) CALL gpu_cc_done_r(460, deadstemc, SIZE(deadstemc,KIND=8), 'deadstemc', &
          LBOUND(deadstemc), UBOUND(deadstemc))
#endif
#ifdef CN
        IF (PRESENT(deadstemc_storage)) CALL gpu_cc_done_r(461, deadstemc_storage, SIZE(deadstemc_storage,KIND=8), 'deadstemc_storage', &
          LBOUND(deadstemc_storage), UBOUND(deadstemc_storage))
#endif
#ifdef CN
        IF (PRESENT(deadstemc_xfer)) CALL gpu_cc_done_r(462, deadstemc_xfer, SIZE(deadstemc_xfer,KIND=8), 'deadstemc_xfer', &
          LBOUND(deadstemc_xfer), UBOUND(deadstemc_xfer))
#endif
#ifdef CN
        IF (PRESENT(livecrootc)) CALL gpu_cc_done_r(463, livecrootc, SIZE(livecrootc,KIND=8), 'livecrootc', &
          LBOUND(livecrootc), UBOUND(livecrootc))
#endif
#ifdef CN
        IF (PRESENT(livecrootc_storage)) CALL gpu_cc_done_r(464, livecrootc_storage, SIZE(livecrootc_storage,KIND=8), 'livecrootc_storage', &
          LBOUND(livecrootc_storage), UBOUND(livecrootc_storage))
#endif
#ifdef CN
        IF (PRESENT(livecrootc_xfer)) CALL gpu_cc_done_r(465, livecrootc_xfer, SIZE(livecrootc_xfer,KIND=8), 'livecrootc_xfer', &
          LBOUND(livecrootc_xfer), UBOUND(livecrootc_xfer))
#endif
#ifdef CN
        IF (PRESENT(deadcrootc)) CALL gpu_cc_done_r(466, deadcrootc, SIZE(deadcrootc,KIND=8), 'deadcrootc', &
          LBOUND(deadcrootc), UBOUND(deadcrootc))
#endif
#ifdef CN
        IF (PRESENT(deadcrootc_storage)) CALL gpu_cc_done_r(467, deadcrootc_storage, SIZE(deadcrootc_storage,KIND=8), 'deadcrootc_storage', &
          LBOUND(deadcrootc_storage), UBOUND(deadcrootc_storage))
#endif
#ifdef CN
        IF (PRESENT(deadcrootc_xfer)) CALL gpu_cc_done_r(468, deadcrootc_xfer, SIZE(deadcrootc_xfer,KIND=8), 'deadcrootc_xfer', &
          LBOUND(deadcrootc_xfer), UBOUND(deadcrootc_xfer))
#endif
#ifdef CN
        IF (PRESENT(cpool)) CALL gpu_cc_done_r(469, cpool, SIZE(cpool,KIND=8), 'cpool', &
          LBOUND(cpool), UBOUND(cpool))
#endif
#ifdef CN
        IF (PRESENT(pft_ctrunc)) CALL gpu_cc_done_r(470, pft_ctrunc, SIZE(pft_ctrunc,KIND=8), 'pft_ctrunc', &
          LBOUND(pft_ctrunc), UBOUND(pft_ctrunc))
#endif
#ifdef CN
        IF (PRESENT(leafn)) CALL gpu_cc_done_r(471, leafn, SIZE(leafn,KIND=8), 'leafn', &
          LBOUND(leafn), UBOUND(leafn))
#endif
#ifdef CN
        IF (PRESENT(leafn_storage)) CALL gpu_cc_done_r(472, leafn_storage, SIZE(leafn_storage,KIND=8), 'leafn_storage', &
          LBOUND(leafn_storage), UBOUND(leafn_storage))
#endif
#ifdef CN
        IF (PRESENT(leafn_xfer)) CALL gpu_cc_done_r(473, leafn_xfer, SIZE(leafn_xfer,KIND=8), 'leafn_xfer', &
          LBOUND(leafn_xfer), UBOUND(leafn_xfer))
#endif
#ifdef CN
        IF (PRESENT(frootn)) CALL gpu_cc_done_r(474, frootn, SIZE(frootn,KIND=8), 'frootn', &
          LBOUND(frootn), UBOUND(frootn))
#endif
#ifdef CN
        IF (PRESENT(frootn_storage)) CALL gpu_cc_done_r(475, frootn_storage, SIZE(frootn_storage,KIND=8), 'frootn_storage', &
          LBOUND(frootn_storage), UBOUND(frootn_storage))
#endif
#ifdef CN
        IF (PRESENT(frootn_xfer)) CALL gpu_cc_done_r(476, frootn_xfer, SIZE(frootn_xfer,KIND=8), 'frootn_xfer', &
          LBOUND(frootn_xfer), UBOUND(frootn_xfer))
#endif
#ifdef CN
        IF (PRESENT(livestemn)) CALL gpu_cc_done_r(477, livestemn, SIZE(livestemn,KIND=8), 'livestemn', &
          LBOUND(livestemn), UBOUND(livestemn))
#endif
#ifdef CN
        IF (PRESENT(livestemn_storage)) CALL gpu_cc_done_r(478, livestemn_storage, SIZE(livestemn_storage,KIND=8), 'livestemn_storage', &
          LBOUND(livestemn_storage), UBOUND(livestemn_storage))
#endif
#ifdef CN
        IF (PRESENT(livestemn_xfer)) CALL gpu_cc_done_r(479, livestemn_xfer, SIZE(livestemn_xfer,KIND=8), 'livestemn_xfer', &
          LBOUND(livestemn_xfer), UBOUND(livestemn_xfer))
#endif
#ifdef CN
        IF (PRESENT(deadstemn)) CALL gpu_cc_done_r(480, deadstemn, SIZE(deadstemn,KIND=8), 'deadstemn', &
          LBOUND(deadstemn), UBOUND(deadstemn))
#endif
#ifdef CN
        IF (PRESENT(deadstemn_storage)) CALL gpu_cc_done_r(481, deadstemn_storage, SIZE(deadstemn_storage,KIND=8), 'deadstemn_storage', &
          LBOUND(deadstemn_storage), UBOUND(deadstemn_storage))
#endif
#ifdef CN
        IF (PRESENT(deadstemn_xfer)) CALL gpu_cc_done_r(482, deadstemn_xfer, SIZE(deadstemn_xfer,KIND=8), 'deadstemn_xfer', &
          LBOUND(deadstemn_xfer), UBOUND(deadstemn_xfer))
#endif
#ifdef CN
        IF (PRESENT(livecrootn)) CALL gpu_cc_done_r(483, livecrootn, SIZE(livecrootn,KIND=8), 'livecrootn', &
          LBOUND(livecrootn), UBOUND(livecrootn))
#endif
#ifdef CN
        IF (PRESENT(livecrootn_storage)) CALL gpu_cc_done_r(484, livecrootn_storage, SIZE(livecrootn_storage,KIND=8), 'livecrootn_storage', &
          LBOUND(livecrootn_storage), UBOUND(livecrootn_storage))
#endif
#ifdef CN
        IF (PRESENT(livecrootn_xfer)) CALL gpu_cc_done_r(485, livecrootn_xfer, SIZE(livecrootn_xfer,KIND=8), 'livecrootn_xfer', &
          LBOUND(livecrootn_xfer), UBOUND(livecrootn_xfer))
#endif
#ifdef CN
        IF (PRESENT(deadcrootn)) CALL gpu_cc_done_r(486, deadcrootn, SIZE(deadcrootn,KIND=8), 'deadcrootn', &
          LBOUND(deadcrootn), UBOUND(deadcrootn))
#endif
#ifdef CN
        IF (PRESENT(deadcrootn_storage)) CALL gpu_cc_done_r(487, deadcrootn_storage, SIZE(deadcrootn_storage,KIND=8), 'deadcrootn_storage', &
          LBOUND(deadcrootn_storage), UBOUND(deadcrootn_storage))
#endif
#ifdef CN
        IF (PRESENT(deadcrootn_xfer)) CALL gpu_cc_done_r(488, deadcrootn_xfer, SIZE(deadcrootn_xfer,KIND=8), 'deadcrootn_xfer', &
          LBOUND(deadcrootn_xfer), UBOUND(deadcrootn_xfer))
#endif
#ifdef CN
        IF (PRESENT(npool)) CALL gpu_cc_done_r(489, npool, SIZE(npool,KIND=8), 'npool', &
          LBOUND(npool), UBOUND(npool))
#endif
#ifdef CN
        IF (PRESENT(pft_ntrunc)) CALL gpu_cc_done_r(490, pft_ntrunc, SIZE(pft_ntrunc,KIND=8), 'pft_ntrunc', &
          LBOUND(pft_ntrunc), UBOUND(pft_ntrunc))
#endif
#ifdef CN
        IF (PRESENT(gresp_storage)) CALL gpu_cc_done_r(491, gresp_storage, SIZE(gresp_storage,KIND=8), 'gresp_storage', &
          LBOUND(gresp_storage), UBOUND(gresp_storage))
#endif
#ifdef CN
        IF (PRESENT(gresp_xfer)) CALL gpu_cc_done_r(492, gresp_xfer, SIZE(gresp_xfer,KIND=8), 'gresp_xfer', &
          LBOUND(gresp_xfer), UBOUND(gresp_xfer))
#endif
#ifdef CN
        IF (PRESENT(xsmrpool)) CALL gpu_cc_done_r(493, xsmrpool, SIZE(xsmrpool,KIND=8), 'xsmrpool', &
          LBOUND(xsmrpool), UBOUND(xsmrpool))
#endif
#ifdef CN
        IF (PRESENT(annsum_counter)) CALL gpu_cc_done_r(494, annsum_counter, SIZE(annsum_counter,KIND=8), 'annsum_counter', &
          LBOUND(annsum_counter), UBOUND(annsum_counter))
#endif
#ifdef CN
        IF (PRESENT(cannsum_npp)) CALL gpu_cc_done_r(495, cannsum_npp, SIZE(cannsum_npp,KIND=8), 'cannsum_npp', &
          LBOUND(cannsum_npp), UBOUND(cannsum_npp))
#endif
#ifdef CN
        IF (PRESENT(cannavg_t2m)) CALL gpu_cc_done_r(496, cannavg_t2m, SIZE(cannavg_t2m,KIND=8), 'cannavg_t2m', &
          LBOUND(cannavg_t2m), UBOUND(cannavg_t2m))
#endif
#ifdef CN
        IF (PRESENT(wf)) CALL gpu_cc_done_r(497, wf, SIZE(wf,KIND=8), 'wf', &
          LBOUND(wf), UBOUND(wf))
#endif
#ifdef CN
        IF (PRESENT(me)) CALL gpu_cc_done_r(498, me, SIZE(me,KIND=8), 'me', &
          LBOUND(me), UBOUND(me))
#endif
#ifdef CN
        IF (PRESENT(mean_fire_prob)) CALL gpu_cc_done_r(499, mean_fire_prob, SIZE(mean_fire_prob,KIND=8), 'mean_fire_prob', &
          LBOUND(mean_fire_prob), UBOUND(mean_fire_prob))
#endif
#ifdef CN
        IF (PRESENT(cwdc)) CALL gpu_cc_done_r(500, cwdc, SIZE(cwdc,KIND=8), 'cwdc', &
          LBOUND(cwdc), UBOUND(cwdc))
#endif
#ifdef CN
        IF (PRESENT(litr1c)) CALL gpu_cc_done_r(501, litr1c, SIZE(litr1c,KIND=8), 'litr1c', &
          LBOUND(litr1c), UBOUND(litr1c))
#endif
#ifdef CN
        IF (PRESENT(litr2c)) CALL gpu_cc_done_r(502, litr2c, SIZE(litr2c,KIND=8), 'litr2c', &
          LBOUND(litr2c), UBOUND(litr2c))
#endif
#ifdef CN
        IF (PRESENT(litr3c)) CALL gpu_cc_done_r(503, litr3c, SIZE(litr3c,KIND=8), 'litr3c', &
          LBOUND(litr3c), UBOUND(litr3c))
#endif
#ifdef CN
        IF (PRESENT(soil1c)) CALL gpu_cc_done_r(504, soil1c, SIZE(soil1c,KIND=8), 'soil1c', &
          LBOUND(soil1c), UBOUND(soil1c))
#endif
#ifdef CN
        IF (PRESENT(soil2c)) CALL gpu_cc_done_r(505, soil2c, SIZE(soil2c,KIND=8), 'soil2c', &
          LBOUND(soil2c), UBOUND(soil2c))
#endif
#ifdef CN
        IF (PRESENT(soil3c)) CALL gpu_cc_done_r(506, soil3c, SIZE(soil3c,KIND=8), 'soil3c', &
          LBOUND(soil3c), UBOUND(soil3c))
#endif
#ifdef CN
        IF (PRESENT(soil4c)) CALL gpu_cc_done_r(507, soil4c, SIZE(soil4c,KIND=8), 'soil4c', &
          LBOUND(soil4c), UBOUND(soil4c))
#endif
#ifdef CN
        IF (PRESENT(seedc)) CALL gpu_cc_done_r(508, seedc, SIZE(seedc,KIND=8), 'seedc', &
          LBOUND(seedc), UBOUND(seedc))
#endif
#ifdef CN
        IF (PRESENT(col_ctrunc)) CALL gpu_cc_done_r(509, col_ctrunc, SIZE(col_ctrunc,KIND=8), 'col_ctrunc', &
          LBOUND(col_ctrunc), UBOUND(col_ctrunc))
#endif
#ifdef CN
        IF (PRESENT(prod10c)) CALL gpu_cc_done_r(510, prod10c, SIZE(prod10c,KIND=8), 'prod10c', &
          LBOUND(prod10c), UBOUND(prod10c))
#endif
#ifdef CN
        IF (PRESENT(prod100c)) CALL gpu_cc_done_r(511, prod100c, SIZE(prod100c,KIND=8), 'prod100c', &
          LBOUND(prod100c), UBOUND(prod100c))
#endif
#ifdef CN
        IF (PRESENT(cwdn)) CALL gpu_cc_done_r(512, cwdn, SIZE(cwdn,KIND=8), 'cwdn', &
          LBOUND(cwdn), UBOUND(cwdn))
#endif
#ifdef CN
        IF (PRESENT(litr1n)) CALL gpu_cc_done_r(513, litr1n, SIZE(litr1n,KIND=8), 'litr1n', &
          LBOUND(litr1n), UBOUND(litr1n))
#endif
#ifdef CN
        IF (PRESENT(litr2n)) CALL gpu_cc_done_r(514, litr2n, SIZE(litr2n,KIND=8), 'litr2n', &
          LBOUND(litr2n), UBOUND(litr2n))
#endif
#ifdef CN
        IF (PRESENT(litr3n)) CALL gpu_cc_done_r(515, litr3n, SIZE(litr3n,KIND=8), 'litr3n', &
          LBOUND(litr3n), UBOUND(litr3n))
#endif
#ifdef CN
        IF (PRESENT(soil1n)) CALL gpu_cc_done_r(516, soil1n, SIZE(soil1n,KIND=8), 'soil1n', &
          LBOUND(soil1n), UBOUND(soil1n))
#endif
#ifdef CN
        IF (PRESENT(soil2n)) CALL gpu_cc_done_r(517, soil2n, SIZE(soil2n,KIND=8), 'soil2n', &
          LBOUND(soil2n), UBOUND(soil2n))
#endif
#ifdef CN
        IF (PRESENT(soil3n)) CALL gpu_cc_done_r(518, soil3n, SIZE(soil3n,KIND=8), 'soil3n', &
          LBOUND(soil3n), UBOUND(soil3n))
#endif
#ifdef CN
        IF (PRESENT(soil4n)) CALL gpu_cc_done_r(519, soil4n, SIZE(soil4n,KIND=8), 'soil4n', &
          LBOUND(soil4n), UBOUND(soil4n))
#endif
#ifdef CN
        IF (PRESENT(seedn)) CALL gpu_cc_done_r(520, seedn, SIZE(seedn,KIND=8), 'seedn', &
          LBOUND(seedn), UBOUND(seedn))
#endif
#ifdef CN
        IF (PRESENT(col_ntrunc)) CALL gpu_cc_done_r(521, col_ntrunc, SIZE(col_ntrunc,KIND=8), 'col_ntrunc', &
          LBOUND(col_ntrunc), UBOUND(col_ntrunc))
#endif
#ifdef CN
        IF (PRESENT(prod10n)) CALL gpu_cc_done_r(522, prod10n, SIZE(prod10n,KIND=8), 'prod10n', &
          LBOUND(prod10n), UBOUND(prod10n))
#endif
#ifdef CN
        IF (PRESENT(prod100n)) CALL gpu_cc_done_r(523, prod100n, SIZE(prod100n,KIND=8), 'prod100n', &
          LBOUND(prod100n), UBOUND(prod100n))
#endif
#ifdef CN
        IF (PRESENT(sminn)) CALL gpu_cc_done_r(524, sminn, SIZE(sminn,KIND=8), 'sminn', &
          LBOUND(sminn), UBOUND(sminn))
#endif
#ifdef CN
        IF (PRESENT(totlitc)) CALL gpu_cc_done_r(525, totlitc, SIZE(totlitc,KIND=8), 'totlitc', &
          LBOUND(totlitc), UBOUND(totlitc))
#endif
#ifdef CN
        IF (PRESENT(dwt_seedc_to_leaf)) CALL gpu_cc_done_r(526, dwt_seedc_to_leaf, SIZE(dwt_seedc_to_leaf,KIND=8), 'dwt_seedc_to_leaf', &
          LBOUND(dwt_seedc_to_leaf), UBOUND(dwt_seedc_to_leaf))
#endif
#ifdef CN
        IF (PRESENT(dwt_seedc_to_deadstem)) CALL gpu_cc_done_r(527, dwt_seedc_to_deadstem, SIZE(dwt_seedc_to_deadstem,KIND=8), 'dwt_seedc_to_deadstem', &
          LBOUND(dwt_seedc_to_deadstem), UBOUND(dwt_seedc_to_deadstem))
#endif
#ifdef CN
        IF (PRESENT(dwt_conv_cflux)) CALL gpu_cc_done_r(528, dwt_conv_cflux, SIZE(dwt_conv_cflux,KIND=8), 'dwt_conv_cflux', &
          LBOUND(dwt_conv_cflux), UBOUND(dwt_conv_cflux))
#endif
#ifdef CN
        IF (PRESENT(dwt_prod10c_gain)) CALL gpu_cc_done_r(529, dwt_prod10c_gain, SIZE(dwt_prod10c_gain,KIND=8), 'dwt_prod10c_gain', &
          LBOUND(dwt_prod10c_gain), UBOUND(dwt_prod10c_gain))
#endif
#ifdef CN
        IF (PRESENT(dwt_prod100c_gain)) CALL gpu_cc_done_r(530, dwt_prod100c_gain, SIZE(dwt_prod100c_gain,KIND=8), 'dwt_prod100c_gain', &
          LBOUND(dwt_prod100c_gain), UBOUND(dwt_prod100c_gain))
#endif
#ifdef CN
        IF (PRESENT(prod100c_loss)) CALL gpu_cc_done_r(531, prod100c_loss, SIZE(prod100c_loss,KIND=8), 'prod100c_loss', &
          LBOUND(prod100c_loss), UBOUND(prod100c_loss))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootc_to_litr1c)) CALL gpu_cc_done_r(532, dwt_frootc_to_litr1c, SIZE(dwt_frootc_to_litr1c,KIND=8), 'dwt_frootc_to_litr1c', &
          LBOUND(dwt_frootc_to_litr1c), UBOUND(dwt_frootc_to_litr1c))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootc_to_litr2c)) CALL gpu_cc_done_r(533, dwt_frootc_to_litr2c, SIZE(dwt_frootc_to_litr2c,KIND=8), 'dwt_frootc_to_litr2c', &
          LBOUND(dwt_frootc_to_litr2c), UBOUND(dwt_frootc_to_litr2c))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootc_to_litr3c)) CALL gpu_cc_done_r(534, dwt_frootc_to_litr3c, SIZE(dwt_frootc_to_litr3c,KIND=8), 'dwt_frootc_to_litr3c', &
          LBOUND(dwt_frootc_to_litr3c), UBOUND(dwt_frootc_to_litr3c))
#endif
#ifdef CN
        IF (PRESENT(dwt_livecrootc_to_cwdc)) CALL gpu_cc_done_r(535, dwt_livecrootc_to_cwdc, SIZE(dwt_livecrootc_to_cwdc,KIND=8), 'dwt_livecrootc_to_cwdc', &
          LBOUND(dwt_livecrootc_to_cwdc), UBOUND(dwt_livecrootc_to_cwdc))
#endif
#ifdef CN
        IF (PRESENT(dwt_deadcrootc_to_cwdc)) CALL gpu_cc_done_r(536, dwt_deadcrootc_to_cwdc, SIZE(dwt_deadcrootc_to_cwdc,KIND=8), 'dwt_deadcrootc_to_cwdc', &
          LBOUND(dwt_deadcrootc_to_cwdc), UBOUND(dwt_deadcrootc_to_cwdc))
#endif
#ifdef CN
        IF (PRESENT(dwt_seedn_to_leaf)) CALL gpu_cc_done_r(537, dwt_seedn_to_leaf, SIZE(dwt_seedn_to_leaf,KIND=8), 'dwt_seedn_to_leaf', &
          LBOUND(dwt_seedn_to_leaf), UBOUND(dwt_seedn_to_leaf))
#endif
#ifdef CN
        IF (PRESENT(dwt_seedn_to_deadstem)) CALL gpu_cc_done_r(538, dwt_seedn_to_deadstem, SIZE(dwt_seedn_to_deadstem,KIND=8), 'dwt_seedn_to_deadstem', &
          LBOUND(dwt_seedn_to_deadstem), UBOUND(dwt_seedn_to_deadstem))
#endif
#ifdef CN
        IF (PRESENT(dwt_conv_nflux)) CALL gpu_cc_done_r(539, dwt_conv_nflux, SIZE(dwt_conv_nflux,KIND=8), 'dwt_conv_nflux', &
          LBOUND(dwt_conv_nflux), UBOUND(dwt_conv_nflux))
#endif
#ifdef CN
        IF (PRESENT(dwt_prod10n_gain)) CALL gpu_cc_done_r(540, dwt_prod10n_gain, SIZE(dwt_prod10n_gain,KIND=8), 'dwt_prod10n_gain', &
          LBOUND(dwt_prod10n_gain), UBOUND(dwt_prod10n_gain))
#endif
#ifdef CN
        IF (PRESENT(dwt_prod100n_gain)) CALL gpu_cc_done_r(541, dwt_prod100n_gain, SIZE(dwt_prod100n_gain,KIND=8), 'dwt_prod100n_gain', &
          LBOUND(dwt_prod100n_gain), UBOUND(dwt_prod100n_gain))
#endif
#ifdef CN
        IF (PRESENT(prod100n_loss)) CALL gpu_cc_done_r(542, prod100n_loss, SIZE(prod100n_loss,KIND=8), 'prod100n_loss', &
          LBOUND(prod100n_loss), UBOUND(prod100n_loss))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootn_to_litr1n)) CALL gpu_cc_done_r(543, dwt_frootn_to_litr1n, SIZE(dwt_frootn_to_litr1n,KIND=8), 'dwt_frootn_to_litr1n', &
          LBOUND(dwt_frootn_to_litr1n), UBOUND(dwt_frootn_to_litr1n))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootn_to_litr2n)) CALL gpu_cc_done_r(544, dwt_frootn_to_litr2n, SIZE(dwt_frootn_to_litr2n,KIND=8), 'dwt_frootn_to_litr2n', &
          LBOUND(dwt_frootn_to_litr2n), UBOUND(dwt_frootn_to_litr2n))
#endif
#ifdef CN
        IF (PRESENT(dwt_frootn_to_litr3n)) CALL gpu_cc_done_r(545, dwt_frootn_to_litr3n, SIZE(dwt_frootn_to_litr3n,KIND=8), 'dwt_frootn_to_litr3n', &
          LBOUND(dwt_frootn_to_litr3n), UBOUND(dwt_frootn_to_litr3n))
#endif
#ifdef CN
        IF (PRESENT(dwt_livecrootn_to_cwdn)) CALL gpu_cc_done_r(546, dwt_livecrootn_to_cwdn, SIZE(dwt_livecrootn_to_cwdn,KIND=8), 'dwt_livecrootn_to_cwdn', &
          LBOUND(dwt_livecrootn_to_cwdn), UBOUND(dwt_livecrootn_to_cwdn))
#endif
#ifdef CN
        IF (PRESENT(dwt_deadcrootn_to_cwdn)) CALL gpu_cc_done_r(547, dwt_deadcrootn_to_cwdn, SIZE(dwt_deadcrootn_to_cwdn,KIND=8), 'dwt_deadcrootn_to_cwdn', &
          LBOUND(dwt_deadcrootn_to_cwdn), UBOUND(dwt_deadcrootn_to_cwdn))
#endif
#ifdef CN
        IF (PRESENT(retransn)) CALL gpu_cc_done_r(548, retransn, SIZE(retransn,KIND=8), 'retransn', &
          LBOUND(retransn), UBOUND(retransn))
#endif
        IF (PRESENT(swnorm)) CALL gpu_cc_done_r(549, swnorm, SIZE(swnorm,KIND=8), 'swnorm', &
          LBOUND(swnorm), UBOUND(swnorm))
        IF (PRESENT(tr_urb2d)) CALL gpu_cc_done_r(550, tr_urb2d, SIZE(tr_urb2d,KIND=8), 'tr_urb2d', &
          LBOUND(tr_urb2d), UBOUND(tr_urb2d))
        IF (PRESENT(tb_urb2d)) CALL gpu_cc_done_r(551, tb_urb2d, SIZE(tb_urb2d,KIND=8), 'tb_urb2d', &
          LBOUND(tb_urb2d), UBOUND(tb_urb2d))
        IF (PRESENT(tg_urb2d)) CALL gpu_cc_done_r(552, tg_urb2d, SIZE(tg_urb2d,KIND=8), 'tg_urb2d', &
          LBOUND(tg_urb2d), UBOUND(tg_urb2d))
        IF (PRESENT(tc_urb2d)) CALL gpu_cc_done_r(553, tc_urb2d, SIZE(tc_urb2d,KIND=8), 'tc_urb2d', &
          LBOUND(tc_urb2d), UBOUND(tc_urb2d))
        IF (PRESENT(qc_urb2d)) CALL gpu_cc_done_r(554, qc_urb2d, SIZE(qc_urb2d,KIND=8), 'qc_urb2d', &
          LBOUND(qc_urb2d), UBOUND(qc_urb2d))
        IF (PRESENT(uc_urb2d)) CALL gpu_cc_done_r(555, uc_urb2d, SIZE(uc_urb2d,KIND=8), 'uc_urb2d', &
          LBOUND(uc_urb2d), UBOUND(uc_urb2d))
        IF (PRESENT(xxxr_urb2d)) CALL gpu_cc_done_r(556, xxxr_urb2d, SIZE(xxxr_urb2d,KIND=8), 'xxxr_urb2d', &
          LBOUND(xxxr_urb2d), UBOUND(xxxr_urb2d))
        IF (PRESENT(xxxb_urb2d)) CALL gpu_cc_done_r(557, xxxb_urb2d, SIZE(xxxb_urb2d,KIND=8), 'xxxb_urb2d', &
          LBOUND(xxxb_urb2d), UBOUND(xxxb_urb2d))
        IF (PRESENT(xxxg_urb2d)) CALL gpu_cc_done_r(558, xxxg_urb2d, SIZE(xxxg_urb2d,KIND=8), 'xxxg_urb2d', &
          LBOUND(xxxg_urb2d), UBOUND(xxxg_urb2d))
        IF (PRESENT(xxxc_urb2d)) CALL gpu_cc_done_r(559, xxxc_urb2d, SIZE(xxxc_urb2d,KIND=8), 'xxxc_urb2d', &
          LBOUND(xxxc_urb2d), UBOUND(xxxc_urb2d))
        IF (PRESENT(cmcr_urb2d)) CALL gpu_cc_done_r(560, cmcr_urb2d, SIZE(cmcr_urb2d,KIND=8), 'cmcr_urb2d', &
          LBOUND(cmcr_urb2d), UBOUND(cmcr_urb2d))
        IF (PRESENT(tgr_urb2d)) CALL gpu_cc_done_r(561, tgr_urb2d, SIZE(tgr_urb2d,KIND=8), 'tgr_urb2d', &
          LBOUND(tgr_urb2d), UBOUND(tgr_urb2d))
        IF (PRESENT(tgrl_urb3d)) CALL gpu_cc_done_r(562, tgrl_urb3d, SIZE(tgrl_urb3d,KIND=8), 'tgrl_urb3d', &
          LBOUND(tgrl_urb3d), UBOUND(tgrl_urb3d))
        IF (PRESENT(smr_urb3d)) CALL gpu_cc_done_r(563, smr_urb3d, SIZE(smr_urb3d,KIND=8), 'smr_urb3d', &
          LBOUND(smr_urb3d), UBOUND(smr_urb3d))
        IF (PRESENT(drelr_urb2d)) CALL gpu_cc_done_r(564, drelr_urb2d, SIZE(drelr_urb2d,KIND=8), 'drelr_urb2d', &
          LBOUND(drelr_urb2d), UBOUND(drelr_urb2d))
        IF (PRESENT(drelb_urb2d)) CALL gpu_cc_done_r(565, drelb_urb2d, SIZE(drelb_urb2d,KIND=8), 'drelb_urb2d', &
          LBOUND(drelb_urb2d), UBOUND(drelb_urb2d))
        IF (PRESENT(drelg_urb2d)) CALL gpu_cc_done_r(566, drelg_urb2d, SIZE(drelg_urb2d,KIND=8), 'drelg_urb2d', &
          LBOUND(drelg_urb2d), UBOUND(drelg_urb2d))
        IF (PRESENT(flxhumr_urb2d)) CALL gpu_cc_done_r(567, flxhumr_urb2d, SIZE(flxhumr_urb2d,KIND=8), 'flxhumr_urb2d', &
          LBOUND(flxhumr_urb2d), UBOUND(flxhumr_urb2d))
        IF (PRESENT(flxhumb_urb2d)) CALL gpu_cc_done_r(568, flxhumb_urb2d, SIZE(flxhumb_urb2d,KIND=8), 'flxhumb_urb2d', &
          LBOUND(flxhumb_urb2d), UBOUND(flxhumb_urb2d))
        IF (PRESENT(flxhumg_urb2d)) CALL gpu_cc_done_r(569, flxhumg_urb2d, SIZE(flxhumg_urb2d,KIND=8), 'flxhumg_urb2d', &
          LBOUND(flxhumg_urb2d), UBOUND(flxhumg_urb2d))
        IF (PRESENT(trl_urb3d)) CALL gpu_cc_done_r(570, trl_urb3d, SIZE(trl_urb3d,KIND=8), 'trl_urb3d', &
          LBOUND(trl_urb3d), UBOUND(trl_urb3d))
        IF (PRESENT(tbl_urb3d)) CALL gpu_cc_done_r(571, tbl_urb3d, SIZE(tbl_urb3d,KIND=8), 'tbl_urb3d', &
          LBOUND(tbl_urb3d), UBOUND(tbl_urb3d))
        IF (PRESENT(tgl_urb3d)) CALL gpu_cc_done_r(572, tgl_urb3d, SIZE(tgl_urb3d,KIND=8), 'tgl_urb3d', &
          LBOUND(tgl_urb3d), UBOUND(tgl_urb3d))
        IF (PRESENT(sh_urb2d)) CALL gpu_cc_done_r(573, sh_urb2d, SIZE(sh_urb2d,KIND=8), 'sh_urb2d', &
          LBOUND(sh_urb2d), UBOUND(sh_urb2d))
        IF (PRESENT(lh_urb2d)) CALL gpu_cc_done_r(574, lh_urb2d, SIZE(lh_urb2d,KIND=8), 'lh_urb2d', &
          LBOUND(lh_urb2d), UBOUND(lh_urb2d))
        IF (PRESENT(g_urb2d)) CALL gpu_cc_done_r(575, g_urb2d, SIZE(g_urb2d,KIND=8), 'g_urb2d', &
          LBOUND(g_urb2d), UBOUND(g_urb2d))
        IF (PRESENT(rn_urb2d)) CALL gpu_cc_done_r(576, rn_urb2d, SIZE(rn_urb2d,KIND=8), 'rn_urb2d', &
          LBOUND(rn_urb2d), UBOUND(rn_urb2d))
        IF (PRESENT(ts_urb2d)) CALL gpu_cc_done_r(577, ts_urb2d, SIZE(ts_urb2d,KIND=8), 'ts_urb2d', &
          LBOUND(ts_urb2d), UBOUND(ts_urb2d))
        IF (PRESENT(frc_urb2d)) CALL gpu_cc_done_r(578, frc_urb2d, SIZE(frc_urb2d,KIND=8), 'frc_urb2d', &
          LBOUND(frc_urb2d), UBOUND(frc_urb2d))
        IF (PRESENT(utype_urb2d)) CALL gpu_cc_done_i(579, utype_urb2d, SIZE(utype_urb2d,KIND=8), 'utype_urb2d', &
          LBOUND(utype_urb2d), UBOUND(utype_urb2d))
        IF (PRESENT(cmr_sfcdif)) CALL gpu_cc_done_r(580, cmr_sfcdif, SIZE(cmr_sfcdif,KIND=8), 'cmr_sfcdif', &
          LBOUND(cmr_sfcdif), UBOUND(cmr_sfcdif))
        IF (PRESENT(chr_sfcdif)) CALL gpu_cc_done_r(581, chr_sfcdif, SIZE(chr_sfcdif,KIND=8), 'chr_sfcdif', &
          LBOUND(chr_sfcdif), UBOUND(chr_sfcdif))
        IF (PRESENT(cmc_sfcdif)) CALL gpu_cc_done_r(582, cmc_sfcdif, SIZE(cmc_sfcdif,KIND=8), 'cmc_sfcdif', &
          LBOUND(cmc_sfcdif), UBOUND(cmc_sfcdif))
        IF (PRESENT(chc_sfcdif)) CALL gpu_cc_done_r(583, chc_sfcdif, SIZE(chc_sfcdif,KIND=8), 'chc_sfcdif', &
          LBOUND(chc_sfcdif), UBOUND(chc_sfcdif))
        IF (PRESENT(cmgr_sfcdif)) CALL gpu_cc_done_r(584, cmgr_sfcdif, SIZE(cmgr_sfcdif,KIND=8), 'cmgr_sfcdif', &
          LBOUND(cmgr_sfcdif), UBOUND(cmgr_sfcdif))
        IF (PRESENT(chgr_sfcdif)) CALL gpu_cc_done_r(585, chgr_sfcdif, SIZE(chgr_sfcdif,KIND=8), 'chgr_sfcdif', &
          LBOUND(chgr_sfcdif), UBOUND(chgr_sfcdif))
        IF (PRESENT(alswvisdir)) CALL gpu_cc_done_r(586, alswvisdir, SIZE(alswvisdir,KIND=8), 'alswvisdir', &
          LBOUND(alswvisdir), UBOUND(alswvisdir))
        IF (PRESENT(alswvisdif)) CALL gpu_cc_done_r(587, alswvisdif, SIZE(alswvisdif,KIND=8), 'alswvisdif', &
          LBOUND(alswvisdif), UBOUND(alswvisdif))
        IF (PRESENT(alswnirdir)) CALL gpu_cc_done_r(588, alswnirdir, SIZE(alswnirdir,KIND=8), 'alswnirdir', &
          LBOUND(alswnirdir), UBOUND(alswnirdir))
        IF (PRESENT(alswnirdif)) CALL gpu_cc_done_r(589, alswnirdif, SIZE(alswnirdif,KIND=8), 'alswnirdif', &
          LBOUND(alswnirdif), UBOUND(alswnirdif))
        IF (PRESENT(ssib_br)) CALL gpu_cc_done_r(590, ssib_br, SIZE(ssib_br,KIND=8), 'ssib_br', &
          LBOUND(ssib_br), UBOUND(ssib_br))
        IF (PRESENT(ssib_fm)) CALL gpu_cc_done_r(591, ssib_fm, SIZE(ssib_fm,KIND=8), 'ssib_fm', &
          LBOUND(ssib_fm), UBOUND(ssib_fm))
        IF (PRESENT(ssib_fh)) CALL gpu_cc_done_r(592, ssib_fh, SIZE(ssib_fh,KIND=8), 'ssib_fh', &
          LBOUND(ssib_fh), UBOUND(ssib_fh))
        IF (PRESENT(ssib_cm)) CALL gpu_cc_done_r(593, ssib_cm, SIZE(ssib_cm,KIND=8), 'ssib_cm', &
          LBOUND(ssib_cm), UBOUND(ssib_cm))
        IF (PRESENT(ssibxdd)) CALL gpu_cc_done_r(594, ssibxdd, SIZE(ssibxdd,KIND=8), 'ssibxdd', &
          LBOUND(ssibxdd), UBOUND(ssibxdd))
        IF (PRESENT(ssib_lhf)) CALL gpu_cc_done_r(595, ssib_lhf, SIZE(ssib_lhf,KIND=8), 'ssib_lhf', &
          LBOUND(ssib_lhf), UBOUND(ssib_lhf))
        IF (PRESENT(ssib_shf)) CALL gpu_cc_done_r(596, ssib_shf, SIZE(ssib_shf,KIND=8), 'ssib_shf', &
          LBOUND(ssib_shf), UBOUND(ssib_shf))
        IF (PRESENT(ssib_ghf)) CALL gpu_cc_done_r(597, ssib_ghf, SIZE(ssib_ghf,KIND=8), 'ssib_ghf', &
          LBOUND(ssib_ghf), UBOUND(ssib_ghf))
        IF (PRESENT(ssib_egs)) CALL gpu_cc_done_r(598, ssib_egs, SIZE(ssib_egs,KIND=8), 'ssib_egs', &
          LBOUND(ssib_egs), UBOUND(ssib_egs))
        IF (PRESENT(ssib_eci)) CALL gpu_cc_done_r(599, ssib_eci, SIZE(ssib_eci,KIND=8), 'ssib_eci', &
          LBOUND(ssib_eci), UBOUND(ssib_eci))
        IF (PRESENT(ssib_ect)) CALL gpu_cc_done_r(600, ssib_ect, SIZE(ssib_ect,KIND=8), 'ssib_ect', &
          LBOUND(ssib_ect), UBOUND(ssib_ect))
        IF (PRESENT(ssib_egi)) CALL gpu_cc_done_r(601, ssib_egi, SIZE(ssib_egi,KIND=8), 'ssib_egi', &
          LBOUND(ssib_egi), UBOUND(ssib_egi))
        IF (PRESENT(ssib_egt)) CALL gpu_cc_done_r(602, ssib_egt, SIZE(ssib_egt,KIND=8), 'ssib_egt', &
          LBOUND(ssib_egt), UBOUND(ssib_egt))
        IF (PRESENT(ssib_sdn)) CALL gpu_cc_done_r(603, ssib_sdn, SIZE(ssib_sdn,KIND=8), 'ssib_sdn', &
          LBOUND(ssib_sdn), UBOUND(ssib_sdn))
        IF (PRESENT(ssib_sup)) CALL gpu_cc_done_r(604, ssib_sup, SIZE(ssib_sup,KIND=8), 'ssib_sup', &
          LBOUND(ssib_sup), UBOUND(ssib_sup))
        IF (PRESENT(ssib_ldn)) CALL gpu_cc_done_r(605, ssib_ldn, SIZE(ssib_ldn,KIND=8), 'ssib_ldn', &
          LBOUND(ssib_ldn), UBOUND(ssib_ldn))
        IF (PRESENT(ssib_lup)) CALL gpu_cc_done_r(606, ssib_lup, SIZE(ssib_lup,KIND=8), 'ssib_lup', &
          LBOUND(ssib_lup), UBOUND(ssib_lup))
        IF (PRESENT(ssib_wat)) CALL gpu_cc_done_r(607, ssib_wat, SIZE(ssib_wat,KIND=8), 'ssib_wat', &
          LBOUND(ssib_wat), UBOUND(ssib_wat))
        IF (PRESENT(ssib_shc)) CALL gpu_cc_done_r(608, ssib_shc, SIZE(ssib_shc,KIND=8), 'ssib_shc', &
          LBOUND(ssib_shc), UBOUND(ssib_shc))
        IF (PRESENT(ssib_shg)) CALL gpu_cc_done_r(609, ssib_shg, SIZE(ssib_shg,KIND=8), 'ssib_shg', &
          LBOUND(ssib_shg), UBOUND(ssib_shg))
        IF (PRESENT(ssib_lai)) CALL gpu_cc_done_r(610, ssib_lai, SIZE(ssib_lai,KIND=8), 'ssib_lai', &
          LBOUND(ssib_lai), UBOUND(ssib_lai))
        IF (PRESENT(ssib_vcf)) CALL gpu_cc_done_r(611, ssib_vcf, SIZE(ssib_vcf,KIND=8), 'ssib_vcf', &
          LBOUND(ssib_vcf), UBOUND(ssib_vcf))
        IF (PRESENT(ssib_z00)) CALL gpu_cc_done_r(612, ssib_z00, SIZE(ssib_z00,KIND=8), 'ssib_z00', &
          LBOUND(ssib_z00), UBOUND(ssib_z00))
        IF (PRESENT(ssib_veg)) CALL gpu_cc_done_r(613, ssib_veg, SIZE(ssib_veg,KIND=8), 'ssib_veg', &
          LBOUND(ssib_veg), UBOUND(ssib_veg))
        IF (PRESENT(isnow)) CALL gpu_cc_done_i(614, isnow, SIZE(isnow,KIND=8), 'isnow', &
          LBOUND(isnow), UBOUND(isnow))
        IF (PRESENT(swe)) CALL gpu_cc_done_r(615, swe, SIZE(swe,KIND=8), 'swe', &
          LBOUND(swe), UBOUND(swe))
        IF (PRESENT(snowden)) CALL gpu_cc_done_r(616, snowden, SIZE(snowden,KIND=8), 'snowden', &
          LBOUND(snowden), UBOUND(snowden))
        IF (PRESENT(snowdepth)) CALL gpu_cc_done_r(617, snowdepth, SIZE(snowdepth,KIND=8), 'snowdepth', &
          LBOUND(snowdepth), UBOUND(snowdepth))
        IF (PRESENT(tkair)) CALL gpu_cc_done_r(618, tkair, SIZE(tkair,KIND=8), 'tkair', &
          LBOUND(tkair), UBOUND(tkair))
        IF (PRESENT(dzo1)) CALL gpu_cc_done_r(619, dzo1, SIZE(dzo1,KIND=8), 'dzo1', &
          LBOUND(dzo1), UBOUND(dzo1))
        IF (PRESENT(wo1)) CALL gpu_cc_done_r(620, wo1, SIZE(wo1,KIND=8), 'wo1', &
          LBOUND(wo1), UBOUND(wo1))
        IF (PRESENT(tssn1)) CALL gpu_cc_done_r(621, tssn1, SIZE(tssn1,KIND=8), 'tssn1', &
          LBOUND(tssn1), UBOUND(tssn1))
        IF (PRESENT(tssno1)) CALL gpu_cc_done_r(622, tssno1, SIZE(tssno1,KIND=8), 'tssno1', &
          LBOUND(tssno1), UBOUND(tssno1))
        IF (PRESENT(bwo1)) CALL gpu_cc_done_r(623, bwo1, SIZE(bwo1,KIND=8), 'bwo1', &
          LBOUND(bwo1), UBOUND(bwo1))
        IF (PRESENT(bto1)) CALL gpu_cc_done_r(624, bto1, SIZE(bto1,KIND=8), 'bto1', &
          LBOUND(bto1), UBOUND(bto1))
        IF (PRESENT(cto1)) CALL gpu_cc_done_r(625, cto1, SIZE(cto1,KIND=8), 'cto1', &
          LBOUND(cto1), UBOUND(cto1))
        IF (PRESENT(fio1)) CALL gpu_cc_done_r(626, fio1, SIZE(fio1,KIND=8), 'fio1', &
          LBOUND(fio1), UBOUND(fio1))
        IF (PRESENT(flo1)) CALL gpu_cc_done_r(627, flo1, SIZE(flo1,KIND=8), 'flo1', &
          LBOUND(flo1), UBOUND(flo1))
        IF (PRESENT(bio1)) CALL gpu_cc_done_r(628, bio1, SIZE(bio1,KIND=8), 'bio1', &
          LBOUND(bio1), UBOUND(bio1))
        IF (PRESENT(blo1)) CALL gpu_cc_done_r(629, blo1, SIZE(blo1,KIND=8), 'blo1', &
          LBOUND(blo1), UBOUND(blo1))
        IF (PRESENT(ho1)) CALL gpu_cc_done_r(630, ho1, SIZE(ho1,KIND=8), 'ho1', &
          LBOUND(ho1), UBOUND(ho1))
        IF (PRESENT(dzo2)) CALL gpu_cc_done_r(631, dzo2, SIZE(dzo2,KIND=8), 'dzo2', &
          LBOUND(dzo2), UBOUND(dzo2))
        IF (PRESENT(wo2)) CALL gpu_cc_done_r(632, wo2, SIZE(wo2,KIND=8), 'wo2', &
          LBOUND(wo2), UBOUND(wo2))
        IF (PRESENT(tssn2)) CALL gpu_cc_done_r(633, tssn2, SIZE(tssn2,KIND=8), 'tssn2', &
          LBOUND(tssn2), UBOUND(tssn2))
        IF (PRESENT(tssno2)) CALL gpu_cc_done_r(634, tssno2, SIZE(tssno2,KIND=8), 'tssno2', &
          LBOUND(tssno2), UBOUND(tssno2))
        IF (PRESENT(bwo2)) CALL gpu_cc_done_r(635, bwo2, SIZE(bwo2,KIND=8), 'bwo2', &
          LBOUND(bwo2), UBOUND(bwo2))
        IF (PRESENT(bto2)) CALL gpu_cc_done_r(636, bto2, SIZE(bto2,KIND=8), 'bto2', &
          LBOUND(bto2), UBOUND(bto2))
        IF (PRESENT(cto2)) CALL gpu_cc_done_r(637, cto2, SIZE(cto2,KIND=8), 'cto2', &
          LBOUND(cto2), UBOUND(cto2))
        IF (PRESENT(fio2)) CALL gpu_cc_done_r(638, fio2, SIZE(fio2,KIND=8), 'fio2', &
          LBOUND(fio2), UBOUND(fio2))
        IF (PRESENT(flo2)) CALL gpu_cc_done_r(639, flo2, SIZE(flo2,KIND=8), 'flo2', &
          LBOUND(flo2), UBOUND(flo2))
        IF (PRESENT(bio2)) CALL gpu_cc_done_r(640, bio2, SIZE(bio2,KIND=8), 'bio2', &
          LBOUND(bio2), UBOUND(bio2))
        IF (PRESENT(blo2)) CALL gpu_cc_done_r(641, blo2, SIZE(blo2,KIND=8), 'blo2', &
          LBOUND(blo2), UBOUND(blo2))
        IF (PRESENT(ho2)) CALL gpu_cc_done_r(642, ho2, SIZE(ho2,KIND=8), 'ho2', &
          LBOUND(ho2), UBOUND(ho2))
        IF (PRESENT(dzo3)) CALL gpu_cc_done_r(643, dzo3, SIZE(dzo3,KIND=8), 'dzo3', &
          LBOUND(dzo3), UBOUND(dzo3))
        IF (PRESENT(wo3)) CALL gpu_cc_done_r(644, wo3, SIZE(wo3,KIND=8), 'wo3', &
          LBOUND(wo3), UBOUND(wo3))
        IF (PRESENT(tssn3)) CALL gpu_cc_done_r(645, tssn3, SIZE(tssn3,KIND=8), 'tssn3', &
          LBOUND(tssn3), UBOUND(tssn3))
        IF (PRESENT(tssno3)) CALL gpu_cc_done_r(646, tssno3, SIZE(tssno3,KIND=8), 'tssno3', &
          LBOUND(tssno3), UBOUND(tssno3))
        IF (PRESENT(bwo3)) CALL gpu_cc_done_r(647, bwo3, SIZE(bwo3,KIND=8), 'bwo3', &
          LBOUND(bwo3), UBOUND(bwo3))
        IF (PRESENT(bto3)) CALL gpu_cc_done_r(648, bto3, SIZE(bto3,KIND=8), 'bto3', &
          LBOUND(bto3), UBOUND(bto3))
        IF (PRESENT(cto3)) CALL gpu_cc_done_r(649, cto3, SIZE(cto3,KIND=8), 'cto3', &
          LBOUND(cto3), UBOUND(cto3))
        IF (PRESENT(fio3)) CALL gpu_cc_done_r(650, fio3, SIZE(fio3,KIND=8), 'fio3', &
          LBOUND(fio3), UBOUND(fio3))
        IF (PRESENT(flo3)) CALL gpu_cc_done_r(651, flo3, SIZE(flo3,KIND=8), 'flo3', &
          LBOUND(flo3), UBOUND(flo3))
        IF (PRESENT(bio3)) CALL gpu_cc_done_r(652, bio3, SIZE(bio3,KIND=8), 'bio3', &
          LBOUND(bio3), UBOUND(bio3))
        IF (PRESENT(blo3)) CALL gpu_cc_done_r(653, blo3, SIZE(blo3,KIND=8), 'blo3', &
          LBOUND(blo3), UBOUND(blo3))
        IF (PRESENT(ho3)) CALL gpu_cc_done_r(654, ho3, SIZE(ho3,KIND=8), 'ho3', &
          LBOUND(ho3), UBOUND(ho3))
        IF (PRESENT(dzo4)) CALL gpu_cc_done_r(655, dzo4, SIZE(dzo4,KIND=8), 'dzo4', &
          LBOUND(dzo4), UBOUND(dzo4))
        IF (PRESENT(wo4)) CALL gpu_cc_done_r(656, wo4, SIZE(wo4,KIND=8), 'wo4', &
          LBOUND(wo4), UBOUND(wo4))
        IF (PRESENT(tssn4)) CALL gpu_cc_done_r(657, tssn4, SIZE(tssn4,KIND=8), 'tssn4', &
          LBOUND(tssn4), UBOUND(tssn4))
        IF (PRESENT(tssno4)) CALL gpu_cc_done_r(658, tssno4, SIZE(tssno4,KIND=8), 'tssno4', &
          LBOUND(tssno4), UBOUND(tssno4))
        IF (PRESENT(bwo4)) CALL gpu_cc_done_r(659, bwo4, SIZE(bwo4,KIND=8), 'bwo4', &
          LBOUND(bwo4), UBOUND(bwo4))
        IF (PRESENT(bto4)) CALL gpu_cc_done_r(660, bto4, SIZE(bto4,KIND=8), 'bto4', &
          LBOUND(bto4), UBOUND(bto4))
        IF (PRESENT(cto4)) CALL gpu_cc_done_r(661, cto4, SIZE(cto4,KIND=8), 'cto4', &
          LBOUND(cto4), UBOUND(cto4))
        IF (PRESENT(fio4)) CALL gpu_cc_done_r(662, fio4, SIZE(fio4,KIND=8), 'fio4', &
          LBOUND(fio4), UBOUND(fio4))
        IF (PRESENT(flo4)) CALL gpu_cc_done_r(663, flo4, SIZE(flo4,KIND=8), 'flo4', &
          LBOUND(flo4), UBOUND(flo4))
        IF (PRESENT(bio4)) CALL gpu_cc_done_r(664, bio4, SIZE(bio4,KIND=8), 'bio4', &
          LBOUND(bio4), UBOUND(bio4))
        IF (PRESENT(blo4)) CALL gpu_cc_done_r(665, blo4, SIZE(blo4,KIND=8), 'blo4', &
          LBOUND(blo4), UBOUND(blo4))
        IF (PRESENT(ho4)) CALL gpu_cc_done_r(666, ho4, SIZE(ho4,KIND=8), 'ho4', &
          LBOUND(ho4), UBOUND(ho4))
        IF (PRESENT(qv_curr)) CALL gpu_cc_done_r(667, qv_curr, SIZE(qv_curr,KIND=8), 'qv_curr', &
          LBOUND(qv_curr), UBOUND(qv_curr))
        IF (PRESENT(qc_curr)) CALL gpu_cc_done_r(668, qc_curr, SIZE(qc_curr,KIND=8), 'qc_curr', &
          LBOUND(qc_curr), UBOUND(qc_curr))
        IF (PRESENT(qr_curr)) CALL gpu_cc_done_r(669, qr_curr, SIZE(qr_curr,KIND=8), 'qr_curr', &
          LBOUND(qr_curr), UBOUND(qr_curr))
        IF (PRESENT(qi_curr)) CALL gpu_cc_done_r(670, qi_curr, SIZE(qi_curr,KIND=8), 'qi_curr', &
          LBOUND(qi_curr), UBOUND(qi_curr))
        IF (PRESENT(qs_curr)) CALL gpu_cc_done_r(671, qs_curr, SIZE(qs_curr,KIND=8), 'qs_curr', &
          LBOUND(qs_curr), UBOUND(qs_curr))
        IF (PRESENT(qg_curr)) CALL gpu_cc_done_r(672, qg_curr, SIZE(qg_curr,KIND=8), 'qg_curr', &
          LBOUND(qg_curr), UBOUND(qg_curr))
        IF (PRESENT(capg)) CALL gpu_cc_done_r(673, capg, SIZE(capg,KIND=8), 'capg', &
          LBOUND(capg), UBOUND(capg))
        IF (PRESENT(hol)) CALL gpu_cc_done_r(674, hol, SIZE(hol,KIND=8), 'hol', &
          LBOUND(hol), UBOUND(hol))
        IF (PRESENT(mol)) CALL gpu_cc_done_r(675, mol, SIZE(mol,KIND=8), 'mol', &
          LBOUND(mol), UBOUND(mol))
        IF (PRESENT(rainbl)) CALL gpu_cc_done_r(676, rainbl, SIZE(rainbl,KIND=8), 'rainbl', &
          LBOUND(rainbl), UBOUND(rainbl))
        IF (PRESENT(regime)) CALL gpu_cc_done_r(677, regime, SIZE(regime,KIND=8), 'regime', &
          LBOUND(regime), UBOUND(regime))
        IF (PRESENT(qsg)) CALL gpu_cc_done_r(678, qsg, SIZE(qsg,KIND=8), 'qsg', &
          LBOUND(qsg), UBOUND(qsg))
        IF (PRESENT(qvg)) CALL gpu_cc_done_r(679, qvg, SIZE(qvg,KIND=8), 'qvg', &
          LBOUND(qvg), UBOUND(qvg))
        IF (PRESENT(qcg)) CALL gpu_cc_done_r(680, qcg, SIZE(qcg,KIND=8), 'qcg', &
          LBOUND(qcg), UBOUND(qcg))
        IF (PRESENT(soilt1)) CALL gpu_cc_done_r(681, soilt1, SIZE(soilt1,KIND=8), 'soilt1', &
          LBOUND(soilt1), UBOUND(soilt1))
        IF (PRESENT(tsnav)) CALL gpu_cc_done_r(682, tsnav, SIZE(tsnav,KIND=8), 'tsnav', &
          LBOUND(tsnav), UBOUND(tsnav))
        IF (PRESENT(smfr3d)) CALL gpu_cc_done_r(683, smfr3d, SIZE(smfr3d,KIND=8), 'smfr3d', &
          LBOUND(smfr3d), UBOUND(smfr3d))
        IF (PRESENT(keepfr3dflag)) CALL gpu_cc_done_r(684, keepfr3dflag, SIZE(keepfr3dflag,KIND=8), 'keepfr3dflag', &
          LBOUND(keepfr3dflag), UBOUND(keepfr3dflag))
        IF (PRESENT(dew)) CALL gpu_cc_done_r(685, dew, SIZE(dew,KIND=8), 'dew', &
          LBOUND(dew), UBOUND(dew))
        IF (PRESENT(rhosnf)) CALL gpu_cc_done_r(686, rhosnf, SIZE(rhosnf,KIND=8), 'rhosnf', &
          LBOUND(rhosnf), UBOUND(rhosnf))
        IF (PRESENT(precipfr)) CALL gpu_cc_done_r(687, precipfr, SIZE(precipfr,KIND=8), 'precipfr', &
          LBOUND(precipfr), UBOUND(precipfr))
        IF (PRESENT(potevp)) CALL gpu_cc_done_r(688, potevp, SIZE(potevp,KIND=8), 'potevp', &
          LBOUND(potevp), UBOUND(potevp))
        IF (PRESENT(snopcx)) CALL gpu_cc_done_r(689, snopcx, SIZE(snopcx,KIND=8), 'snopcx', &
          LBOUND(snopcx), UBOUND(snopcx))
        IF (PRESENT(soiltb)) CALL gpu_cc_done_r(690, soiltb, SIZE(soiltb,KIND=8), 'soiltb', &
          LBOUND(soiltb), UBOUND(soiltb))
        IF (PRESENT(sr)) CALL gpu_cc_done_r(691, sr, SIZE(sr,KIND=8), 'sr', &
          LBOUND(sr), UBOUND(sr))
        IF (PRESENT(t2_ndg_old)) CALL gpu_cc_done_r(692, t2_ndg_old, SIZE(t2_ndg_old,KIND=8), 't2_ndg_old', &
          LBOUND(t2_ndg_old), UBOUND(t2_ndg_old))
        IF (PRESENT(q2_ndg_old)) CALL gpu_cc_done_r(693, q2_ndg_old, SIZE(q2_ndg_old,KIND=8), 'q2_ndg_old', &
          LBOUND(q2_ndg_old), UBOUND(q2_ndg_old))
        IF (PRESENT(t2_ndg_new)) CALL gpu_cc_done_r(694, t2_ndg_new, SIZE(t2_ndg_new,KIND=8), 't2_ndg_new', &
          LBOUND(t2_ndg_new), UBOUND(t2_ndg_new))
        IF (PRESENT(q2_ndg_new)) CALL gpu_cc_done_r(695, q2_ndg_new, SIZE(q2_ndg_new,KIND=8), 'q2_ndg_new', &
          LBOUND(q2_ndg_new), UBOUND(q2_ndg_new))
        IF (PRESENT(sn_ndg_old)) CALL gpu_cc_done_r(696, sn_ndg_old, SIZE(sn_ndg_old,KIND=8), 'sn_ndg_old', &
          LBOUND(sn_ndg_old), UBOUND(sn_ndg_old))
        IF (PRESENT(sn_ndg_new)) CALL gpu_cc_done_r(697, sn_ndg_new, SIZE(sn_ndg_new,KIND=8), 'sn_ndg_new', &
          LBOUND(sn_ndg_new), UBOUND(sn_ndg_new))
        IF (PRESENT(t2obs)) CALL gpu_cc_done_r(698, t2obs, SIZE(t2obs,KIND=8), 't2obs', &
          LBOUND(t2obs), UBOUND(t2obs))
        IF (PRESENT(q2obs)) CALL gpu_cc_done_r(699, q2obs, SIZE(q2obs,KIND=8), 'q2obs', &
          LBOUND(q2obs), UBOUND(q2obs))
        IF (PRESENT(hd_temf)) CALL gpu_cc_done_r(700, hd_temf, SIZE(hd_temf,KIND=8), 'hd_temf', &
          LBOUND(hd_temf), UBOUND(hd_temf))
        IF (PRESENT(te_temf)) CALL gpu_cc_done_r(701, te_temf, SIZE(te_temf,KIND=8), 'te_temf', &
          LBOUND(te_temf), UBOUND(te_temf))
        IF (PRESENT(exch_temf)) CALL gpu_cc_done_r(702, exch_temf, SIZE(exch_temf,KIND=8), 'exch_temf', &
          LBOUND(exch_temf), UBOUND(exch_temf))
        IF (PRESENT(wm_temf)) CALL gpu_cc_done_r(703, wm_temf, SIZE(wm_temf,KIND=8), 'wm_temf', &
          LBOUND(wm_temf), UBOUND(wm_temf))
        IF (PRESENT(hfx_force)) CALL gpu_cc_done_r0(704, hfx_force, 'hfx_force')
        IF (PRESENT(lh_force)) CALL gpu_cc_done_r0(705, lh_force, 'lh_force')
        IF (PRESENT(tsk_force)) CALL gpu_cc_done_r0(706, tsk_force, 'tsk_force')
        IF (PRESENT(uratx)) CALL gpu_cc_done_r(707, uratx, SIZE(uratx,KIND=8), 'uratx', &
          LBOUND(uratx), UBOUND(uratx))
        IF (PRESENT(vratx)) CALL gpu_cc_done_r(708, vratx, SIZE(vratx,KIND=8), 'vratx', &
          LBOUND(vratx), UBOUND(vratx))
        IF (PRESENT(tratx)) CALL gpu_cc_done_r(709, tratx, SIZE(tratx,KIND=8), 'tratx', &
          LBOUND(tratx), UBOUND(tratx))
        IF (PRESENT(tml)) CALL gpu_cc_done_r(710, tml, SIZE(tml,KIND=8), 'tml', &
          LBOUND(tml), UBOUND(tml))
        IF (PRESENT(t0ml)) CALL gpu_cc_done_r(711, t0ml, SIZE(t0ml,KIND=8), 't0ml', &
          LBOUND(t0ml), UBOUND(t0ml))
        IF (PRESENT(hml)) CALL gpu_cc_done_r(712, hml, SIZE(hml,KIND=8), 'hml', &
          LBOUND(hml), UBOUND(hml))
        IF (PRESENT(h0ml)) CALL gpu_cc_done_r(713, h0ml, SIZE(h0ml,KIND=8), 'h0ml', &
          LBOUND(h0ml), UBOUND(h0ml))
        IF (PRESENT(huml)) CALL gpu_cc_done_r(714, huml, SIZE(huml,KIND=8), 'huml', &
          LBOUND(huml), UBOUND(huml))
        IF (PRESENT(hvml)) CALL gpu_cc_done_r(715, hvml, SIZE(hvml,KIND=8), 'hvml', &
          LBOUND(hvml), UBOUND(hvml))
        IF (PRESENT(ustm)) CALL gpu_cc_done_r(716, ustm, SIZE(ustm,KIND=8), 'ustm', &
          LBOUND(ustm), UBOUND(ustm))
        IF (PRESENT(ck)) CALL gpu_cc_done_r(717, ck, SIZE(ck,KIND=8), 'ck', &
          LBOUND(ck), UBOUND(ck))
        IF (PRESENT(cka)) CALL gpu_cc_done_r(718, cka, SIZE(cka,KIND=8), 'cka', &
          LBOUND(cka), UBOUND(cka))
        IF (PRESENT(cd)) CALL gpu_cc_done_r(719, cd, SIZE(cd,KIND=8), 'cd', &
          LBOUND(cd), UBOUND(cd))
        IF (PRESENT(cda)) CALL gpu_cc_done_r(720, cda, SIZE(cda,KIND=8), 'cda', &
          LBOUND(cda), UBOUND(cda))
        IF (PRESENT(snotime)) CALL gpu_cc_done_r(721, snotime, SIZE(snotime,KIND=8), 'snotime', &
          LBOUND(snotime), UBOUND(snotime))
        IF (PRESENT(noahres)) CALL gpu_cc_done_r(722, noahres, SIZE(noahres,KIND=8), 'noahres', &
          LBOUND(noahres), UBOUND(noahres))
        IF (PRESENT(bldtacttime)) CALL gpu_cc_done_r0(723, bldtacttime, 'bldtacttime')
        IF (PRESENT(tsk_rural)) CALL gpu_cc_done_r(724, tsk_rural, SIZE(tsk_rural,KIND=8), 'tsk_rural', &
          LBOUND(tsk_rural), UBOUND(tsk_rural))
        IF (PRESENT(trb_urb4d)) CALL gpu_cc_done_r(725, trb_urb4d, SIZE(trb_urb4d,KIND=8), 'trb_urb4d', &
          LBOUND(trb_urb4d), UBOUND(trb_urb4d))
        IF (PRESENT(tw1_urb4d)) CALL gpu_cc_done_r(726, tw1_urb4d, SIZE(tw1_urb4d,KIND=8), 'tw1_urb4d', &
          LBOUND(tw1_urb4d), UBOUND(tw1_urb4d))
        IF (PRESENT(tw2_urb4d)) CALL gpu_cc_done_r(727, tw2_urb4d, SIZE(tw2_urb4d,KIND=8), 'tw2_urb4d', &
          LBOUND(tw2_urb4d), UBOUND(tw2_urb4d))
        IF (PRESENT(tgb_urb4d)) CALL gpu_cc_done_r(728, tgb_urb4d, SIZE(tgb_urb4d,KIND=8), 'tgb_urb4d', &
          LBOUND(tgb_urb4d), UBOUND(tgb_urb4d))
        IF (PRESENT(tlev_urb3d)) CALL gpu_cc_done_r(729, tlev_urb3d, SIZE(tlev_urb3d,KIND=8), 'tlev_urb3d', &
          LBOUND(tlev_urb3d), UBOUND(tlev_urb3d))
        IF (PRESENT(qlev_urb3d)) CALL gpu_cc_done_r(730, qlev_urb3d, SIZE(qlev_urb3d,KIND=8), 'qlev_urb3d', &
          LBOUND(qlev_urb3d), UBOUND(qlev_urb3d))
        IF (PRESENT(tw1lev_urb3d)) CALL gpu_cc_done_r(731, tw1lev_urb3d, SIZE(tw1lev_urb3d,KIND=8), 'tw1lev_urb3d', &
          LBOUND(tw1lev_urb3d), UBOUND(tw1lev_urb3d))
        IF (PRESENT(tw2lev_urb3d)) CALL gpu_cc_done_r(732, tw2lev_urb3d, SIZE(tw2lev_urb3d,KIND=8), 'tw2lev_urb3d', &
          LBOUND(tw2lev_urb3d), UBOUND(tw2lev_urb3d))
        IF (PRESENT(tglev_urb3d)) CALL gpu_cc_done_r(733, tglev_urb3d, SIZE(tglev_urb3d,KIND=8), 'tglev_urb3d', &
          LBOUND(tglev_urb3d), UBOUND(tglev_urb3d))
        IF (PRESENT(tflev_urb3d)) CALL gpu_cc_done_r(734, tflev_urb3d, SIZE(tflev_urb3d,KIND=8), 'tflev_urb3d', &
          LBOUND(tflev_urb3d), UBOUND(tflev_urb3d))
        IF (PRESENT(sf_ac_urb3d)) CALL gpu_cc_done_r(735, sf_ac_urb3d, SIZE(sf_ac_urb3d,KIND=8), 'sf_ac_urb3d', &
          LBOUND(sf_ac_urb3d), UBOUND(sf_ac_urb3d))
        IF (PRESENT(lf_ac_urb3d)) CALL gpu_cc_done_r(736, lf_ac_urb3d, SIZE(lf_ac_urb3d,KIND=8), 'lf_ac_urb3d', &
          LBOUND(lf_ac_urb3d), UBOUND(lf_ac_urb3d))
        IF (PRESENT(cm_ac_urb3d)) CALL gpu_cc_done_r(737, cm_ac_urb3d, SIZE(cm_ac_urb3d,KIND=8), 'cm_ac_urb3d', &
          LBOUND(cm_ac_urb3d), UBOUND(cm_ac_urb3d))
        IF (PRESENT(sfvent_urb3d)) CALL gpu_cc_done_r(738, sfvent_urb3d, SIZE(sfvent_urb3d,KIND=8), 'sfvent_urb3d', &
          LBOUND(sfvent_urb3d), UBOUND(sfvent_urb3d))
        IF (PRESENT(lfvent_urb3d)) CALL gpu_cc_done_r(739, lfvent_urb3d, SIZE(lfvent_urb3d,KIND=8), 'lfvent_urb3d', &
          LBOUND(lfvent_urb3d), UBOUND(lfvent_urb3d))
        IF (PRESENT(sfwin1_urb3d)) CALL gpu_cc_done_r(740, sfwin1_urb3d, SIZE(sfwin1_urb3d,KIND=8), 'sfwin1_urb3d', &
          LBOUND(sfwin1_urb3d), UBOUND(sfwin1_urb3d))
        IF (PRESENT(sfwin2_urb3d)) CALL gpu_cc_done_r(741, sfwin2_urb3d, SIZE(sfwin2_urb3d,KIND=8), 'sfwin2_urb3d', &
          LBOUND(sfwin2_urb3d), UBOUND(sfwin2_urb3d))
        IF (PRESENT(sfw1_urb3d)) CALL gpu_cc_done_r(742, sfw1_urb3d, SIZE(sfw1_urb3d,KIND=8), 'sfw1_urb3d', &
          LBOUND(sfw1_urb3d), UBOUND(sfw1_urb3d))
        IF (PRESENT(sfw2_urb3d)) CALL gpu_cc_done_r(743, sfw2_urb3d, SIZE(sfw2_urb3d,KIND=8), 'sfw2_urb3d', &
          LBOUND(sfw2_urb3d), UBOUND(sfw2_urb3d))
        IF (PRESENT(sfr_urb3d)) CALL gpu_cc_done_r(744, sfr_urb3d, SIZE(sfr_urb3d,KIND=8), 'sfr_urb3d', &
          LBOUND(sfr_urb3d), UBOUND(sfr_urb3d))
        IF (PRESENT(sfg_urb3d)) CALL gpu_cc_done_r(745, sfg_urb3d, SIZE(sfg_urb3d,KIND=8), 'sfg_urb3d', &
          LBOUND(sfg_urb3d), UBOUND(sfg_urb3d))
        IF (PRESENT(ep_pv_urb3d)) CALL gpu_cc_done_r(746, ep_pv_urb3d, SIZE(ep_pv_urb3d,KIND=8), 'ep_pv_urb3d', &
          LBOUND(ep_pv_urb3d), UBOUND(ep_pv_urb3d))
        IF (PRESENT(t_pv_urb3d)) CALL gpu_cc_done_r(747, t_pv_urb3d, SIZE(t_pv_urb3d,KIND=8), 't_pv_urb3d', &
          LBOUND(t_pv_urb3d), UBOUND(t_pv_urb3d))
        IF (PRESENT(trv_urb4d)) CALL gpu_cc_done_r(748, trv_urb4d, SIZE(trv_urb4d,KIND=8), 'trv_urb4d', &
          LBOUND(trv_urb4d), UBOUND(trv_urb4d))
        IF (PRESENT(qr_urb4d)) CALL gpu_cc_done_r(749, qr_urb4d, SIZE(qr_urb4d,KIND=8), 'qr_urb4d', &
          LBOUND(qr_urb4d), UBOUND(qr_urb4d))
        IF (PRESENT(qgr_urb3d)) CALL gpu_cc_done_r(750, qgr_urb3d, SIZE(qgr_urb3d,KIND=8), 'qgr_urb3d', &
          LBOUND(qgr_urb3d), UBOUND(qgr_urb3d))
        IF (PRESENT(tgr_urb3d)) CALL gpu_cc_done_r(751, tgr_urb3d, SIZE(tgr_urb3d,KIND=8), 'tgr_urb3d', &
          LBOUND(tgr_urb3d), UBOUND(tgr_urb3d))
        IF (PRESENT(drain_urb4d)) CALL gpu_cc_done_r(752, drain_urb4d, SIZE(drain_urb4d,KIND=8), 'drain_urb4d', &
          LBOUND(drain_urb4d), UBOUND(drain_urb4d))
        IF (PRESENT(draingr_urb3d)) CALL gpu_cc_done_r(753, draingr_urb3d, SIZE(draingr_urb3d,KIND=8), 'draingr_urb3d', &
          LBOUND(draingr_urb3d), UBOUND(draingr_urb3d))
        IF (PRESENT(sfrv_urb3d)) CALL gpu_cc_done_r(754, sfrv_urb3d, SIZE(sfrv_urb3d,KIND=8), 'sfrv_urb3d', &
          LBOUND(sfrv_urb3d), UBOUND(sfrv_urb3d))
        IF (PRESENT(lfrv_urb3d)) CALL gpu_cc_done_r(755, lfrv_urb3d, SIZE(lfrv_urb3d,KIND=8), 'lfrv_urb3d', &
          LBOUND(lfrv_urb3d), UBOUND(lfrv_urb3d))
        IF (PRESENT(dgr_urb3d)) CALL gpu_cc_done_r(756, dgr_urb3d, SIZE(dgr_urb3d,KIND=8), 'dgr_urb3d', &
          LBOUND(dgr_urb3d), UBOUND(dgr_urb3d))
        IF (PRESENT(dg_urb3d)) CALL gpu_cc_done_r(757, dg_urb3d, SIZE(dg_urb3d,KIND=8), 'dg_urb3d', &
          LBOUND(dg_urb3d), UBOUND(dg_urb3d))
        IF (PRESENT(lfr_urb3d)) CALL gpu_cc_done_r(758, lfr_urb3d, SIZE(lfr_urb3d,KIND=8), 'lfr_urb3d', &
          LBOUND(lfr_urb3d), UBOUND(lfr_urb3d))
        IF (PRESENT(lfg_urb3d)) CALL gpu_cc_done_r(759, lfg_urb3d, SIZE(lfg_urb3d,KIND=8), 'lfg_urb3d', &
          LBOUND(lfg_urb3d), UBOUND(lfg_urb3d))
        IF (PRESENT(a_u_bep)) CALL gpu_cc_done_r(760, a_u_bep, SIZE(a_u_bep,KIND=8), 'a_u_bep', &
          LBOUND(a_u_bep), UBOUND(a_u_bep))
        IF (PRESENT(a_v_bep)) CALL gpu_cc_done_r(761, a_v_bep, SIZE(a_v_bep,KIND=8), 'a_v_bep', &
          LBOUND(a_v_bep), UBOUND(a_v_bep))
        IF (PRESENT(a_t_bep)) CALL gpu_cc_done_r(762, a_t_bep, SIZE(a_t_bep,KIND=8), 'a_t_bep', &
          LBOUND(a_t_bep), UBOUND(a_t_bep))
        IF (PRESENT(a_q_bep)) CALL gpu_cc_done_r(763, a_q_bep, SIZE(a_q_bep,KIND=8), 'a_q_bep', &
          LBOUND(a_q_bep), UBOUND(a_q_bep))
        IF (PRESENT(b_u_bep)) CALL gpu_cc_done_r(764, b_u_bep, SIZE(b_u_bep,KIND=8), 'b_u_bep', &
          LBOUND(b_u_bep), UBOUND(b_u_bep))
        IF (PRESENT(b_v_bep)) CALL gpu_cc_done_r(765, b_v_bep, SIZE(b_v_bep,KIND=8), 'b_v_bep', &
          LBOUND(b_v_bep), UBOUND(b_v_bep))
        IF (PRESENT(b_t_bep)) CALL gpu_cc_done_r(766, b_t_bep, SIZE(b_t_bep,KIND=8), 'b_t_bep', &
          LBOUND(b_t_bep), UBOUND(b_t_bep))
        IF (PRESENT(b_q_bep)) CALL gpu_cc_done_r(767, b_q_bep, SIZE(b_q_bep,KIND=8), 'b_q_bep', &
          LBOUND(b_q_bep), UBOUND(b_q_bep))
        IF (PRESENT(sf_bep)) CALL gpu_cc_done_r(768, sf_bep, SIZE(sf_bep,KIND=8), 'sf_bep', &
          LBOUND(sf_bep), UBOUND(sf_bep))
        IF (PRESENT(vl_bep)) CALL gpu_cc_done_r(769, vl_bep, SIZE(vl_bep,KIND=8), 'vl_bep', &
          LBOUND(vl_bep), UBOUND(vl_bep))
        IF (PRESENT(a_e_bep)) CALL gpu_cc_done_r(770, a_e_bep, SIZE(a_e_bep,KIND=8), 'a_e_bep', &
          LBOUND(a_e_bep), UBOUND(a_e_bep))
        IF (PRESENT(b_e_bep)) CALL gpu_cc_done_r(771, b_e_bep, SIZE(b_e_bep,KIND=8), 'b_e_bep', &
          LBOUND(b_e_bep), UBOUND(b_e_bep))
        IF (PRESENT(dlg_bep)) CALL gpu_cc_done_r(772, dlg_bep, SIZE(dlg_bep,KIND=8), 'dlg_bep', &
          LBOUND(dlg_bep), UBOUND(dlg_bep))
        IF (PRESENT(dl_u_bep)) CALL gpu_cc_done_r(773, dl_u_bep, SIZE(dl_u_bep,KIND=8), 'dl_u_bep', &
          LBOUND(dl_u_bep), UBOUND(dl_u_bep))
        IF (PRESENT(tsk_save)) CALL gpu_cc_done_r(774, tsk_save, SIZE(tsk_save,KIND=8), 'tsk_save', &
          LBOUND(tsk_save), UBOUND(tsk_save))
        IF (PRESENT(mosaic_cat_index)) CALL gpu_cc_done_i(775, mosaic_cat_index, SIZE(mosaic_cat_index,KIND=8), 'mosaic_cat_index', &
          LBOUND(mosaic_cat_index), UBOUND(mosaic_cat_index))
        IF (PRESENT(landusef2)) CALL gpu_cc_done_r(776, landusef2, SIZE(landusef2,KIND=8), 'landusef2', &
          LBOUND(landusef2), UBOUND(landusef2))
        IF (PRESENT(tsk_mosaic)) CALL gpu_cc_done_r(777, tsk_mosaic, SIZE(tsk_mosaic,KIND=8), 'tsk_mosaic', &
          LBOUND(tsk_mosaic), UBOUND(tsk_mosaic))
        IF (PRESENT(qsfc_mosaic)) CALL gpu_cc_done_r(778, qsfc_mosaic, SIZE(qsfc_mosaic,KIND=8), 'qsfc_mosaic', &
          LBOUND(qsfc_mosaic), UBOUND(qsfc_mosaic))
        IF (PRESENT(tslb_mosaic)) CALL gpu_cc_done_r(779, tslb_mosaic, SIZE(tslb_mosaic,KIND=8), 'tslb_mosaic', &
          LBOUND(tslb_mosaic), UBOUND(tslb_mosaic))
        IF (PRESENT(smois_mosaic)) CALL gpu_cc_done_r(780, smois_mosaic, SIZE(smois_mosaic,KIND=8), 'smois_mosaic', &
          LBOUND(smois_mosaic), UBOUND(smois_mosaic))
        IF (PRESENT(sh2o_mosaic)) CALL gpu_cc_done_r(781, sh2o_mosaic, SIZE(sh2o_mosaic,KIND=8), 'sh2o_mosaic', &
          LBOUND(sh2o_mosaic), UBOUND(sh2o_mosaic))
        IF (PRESENT(canwat_mosaic)) CALL gpu_cc_done_r(782, canwat_mosaic, SIZE(canwat_mosaic,KIND=8), 'canwat_mosaic', &
          LBOUND(canwat_mosaic), UBOUND(canwat_mosaic))
        IF (PRESENT(snow_mosaic)) CALL gpu_cc_done_r(783, snow_mosaic, SIZE(snow_mosaic,KIND=8), 'snow_mosaic', &
          LBOUND(snow_mosaic), UBOUND(snow_mosaic))
        IF (PRESENT(snowh_mosaic)) CALL gpu_cc_done_r(784, snowh_mosaic, SIZE(snowh_mosaic,KIND=8), 'snowh_mosaic', &
          LBOUND(snowh_mosaic), UBOUND(snowh_mosaic))
        IF (PRESENT(snowc_mosaic)) CALL gpu_cc_done_r(785, snowc_mosaic, SIZE(snowc_mosaic,KIND=8), 'snowc_mosaic', &
          LBOUND(snowc_mosaic), UBOUND(snowc_mosaic))
        IF (PRESENT(albedo_mosaic)) CALL gpu_cc_done_r(786, albedo_mosaic, SIZE(albedo_mosaic,KIND=8), 'albedo_mosaic', &
          LBOUND(albedo_mosaic), UBOUND(albedo_mosaic))
        IF (PRESENT(albbck_mosaic)) CALL gpu_cc_done_r(787, albbck_mosaic, SIZE(albbck_mosaic,KIND=8), 'albbck_mosaic', &
          LBOUND(albbck_mosaic), UBOUND(albbck_mosaic))
        IF (PRESENT(emiss_mosaic)) CALL gpu_cc_done_r(788, emiss_mosaic, SIZE(emiss_mosaic,KIND=8), 'emiss_mosaic', &
          LBOUND(emiss_mosaic), UBOUND(emiss_mosaic))
        IF (PRESENT(embck_mosaic)) CALL gpu_cc_done_r(789, embck_mosaic, SIZE(embck_mosaic,KIND=8), 'embck_mosaic', &
          LBOUND(embck_mosaic), UBOUND(embck_mosaic))
        IF (PRESENT(znt_mosaic)) CALL gpu_cc_done_r(790, znt_mosaic, SIZE(znt_mosaic,KIND=8), 'znt_mosaic', &
          LBOUND(znt_mosaic), UBOUND(znt_mosaic))
        IF (PRESENT(z0_mosaic)) CALL gpu_cc_done_r(791, z0_mosaic, SIZE(z0_mosaic,KIND=8), 'z0_mosaic', &
          LBOUND(z0_mosaic), UBOUND(z0_mosaic))
        IF (PRESENT(hfx_mosaic)) CALL gpu_cc_done_r(792, hfx_mosaic, SIZE(hfx_mosaic,KIND=8), 'hfx_mosaic', &
          LBOUND(hfx_mosaic), UBOUND(hfx_mosaic))
        IF (PRESENT(qfx_mosaic)) CALL gpu_cc_done_r(793, qfx_mosaic, SIZE(qfx_mosaic,KIND=8), 'qfx_mosaic', &
          LBOUND(qfx_mosaic), UBOUND(qfx_mosaic))
        IF (PRESENT(lh_mosaic)) CALL gpu_cc_done_r(794, lh_mosaic, SIZE(lh_mosaic,KIND=8), 'lh_mosaic', &
          LBOUND(lh_mosaic), UBOUND(lh_mosaic))
        IF (PRESENT(grdflx_mosaic)) CALL gpu_cc_done_r(795, grdflx_mosaic, SIZE(grdflx_mosaic,KIND=8), 'grdflx_mosaic', &
          LBOUND(grdflx_mosaic), UBOUND(grdflx_mosaic))
        IF (PRESENT(snotime_mosaic)) CALL gpu_cc_done_r(796, snotime_mosaic, SIZE(snotime_mosaic,KIND=8), 'snotime_mosaic', &
          LBOUND(snotime_mosaic), UBOUND(snotime_mosaic))
        IF (PRESENT(rs_mosaic)) CALL gpu_cc_done_r(797, rs_mosaic, SIZE(rs_mosaic,KIND=8), 'rs_mosaic', &
          LBOUND(rs_mosaic), UBOUND(rs_mosaic))
        IF (PRESENT(lai_mosaic)) CALL gpu_cc_done_r(798, lai_mosaic, SIZE(lai_mosaic,KIND=8), 'lai_mosaic', &
          LBOUND(lai_mosaic), UBOUND(lai_mosaic))
        IF (PRESENT(tr_urb2d_mosaic)) CALL gpu_cc_done_r(799, tr_urb2d_mosaic, SIZE(tr_urb2d_mosaic,KIND=8), 'tr_urb2d_mosaic', &
          LBOUND(tr_urb2d_mosaic), UBOUND(tr_urb2d_mosaic))
        IF (PRESENT(tb_urb2d_mosaic)) CALL gpu_cc_done_r(800, tb_urb2d_mosaic, SIZE(tb_urb2d_mosaic,KIND=8), 'tb_urb2d_mosaic', &
          LBOUND(tb_urb2d_mosaic), UBOUND(tb_urb2d_mosaic))
        IF (PRESENT(tg_urb2d_mosaic)) CALL gpu_cc_done_r(801, tg_urb2d_mosaic, SIZE(tg_urb2d_mosaic,KIND=8), 'tg_urb2d_mosaic', &
          LBOUND(tg_urb2d_mosaic), UBOUND(tg_urb2d_mosaic))
        IF (PRESENT(tc_urb2d_mosaic)) CALL gpu_cc_done_r(802, tc_urb2d_mosaic, SIZE(tc_urb2d_mosaic,KIND=8), 'tc_urb2d_mosaic', &
          LBOUND(tc_urb2d_mosaic), UBOUND(tc_urb2d_mosaic))
        IF (PRESENT(qc_urb2d_mosaic)) CALL gpu_cc_done_r(803, qc_urb2d_mosaic, SIZE(qc_urb2d_mosaic,KIND=8), 'qc_urb2d_mosaic', &
          LBOUND(qc_urb2d_mosaic), UBOUND(qc_urb2d_mosaic))
        IF (PRESENT(uc_urb2d_mosaic)) CALL gpu_cc_done_r(804, uc_urb2d_mosaic, SIZE(uc_urb2d_mosaic,KIND=8), 'uc_urb2d_mosaic', &
          LBOUND(uc_urb2d_mosaic), UBOUND(uc_urb2d_mosaic))
        IF (PRESENT(trl_urb3d_mosaic)) CALL gpu_cc_done_r(805, trl_urb3d_mosaic, SIZE(trl_urb3d_mosaic,KIND=8), 'trl_urb3d_mosaic', &
          LBOUND(trl_urb3d_mosaic), UBOUND(trl_urb3d_mosaic))
        IF (PRESENT(tbl_urb3d_mosaic)) CALL gpu_cc_done_r(806, tbl_urb3d_mosaic, SIZE(tbl_urb3d_mosaic,KIND=8), 'tbl_urb3d_mosaic', &
          LBOUND(tbl_urb3d_mosaic), UBOUND(tbl_urb3d_mosaic))
        IF (PRESENT(tgl_urb3d_mosaic)) CALL gpu_cc_done_r(807, tgl_urb3d_mosaic, SIZE(tgl_urb3d_mosaic,KIND=8), 'tgl_urb3d_mosaic', &
          LBOUND(tgl_urb3d_mosaic), UBOUND(tgl_urb3d_mosaic))
        IF (PRESENT(sh_urb2d_mosaic)) CALL gpu_cc_done_r(808, sh_urb2d_mosaic, SIZE(sh_urb2d_mosaic,KIND=8), 'sh_urb2d_mosaic', &
          LBOUND(sh_urb2d_mosaic), UBOUND(sh_urb2d_mosaic))
        IF (PRESENT(lh_urb2d_mosaic)) CALL gpu_cc_done_r(809, lh_urb2d_mosaic, SIZE(lh_urb2d_mosaic,KIND=8), 'lh_urb2d_mosaic', &
          LBOUND(lh_urb2d_mosaic), UBOUND(lh_urb2d_mosaic))
        IF (PRESENT(g_urb2d_mosaic)) CALL gpu_cc_done_r(810, g_urb2d_mosaic, SIZE(g_urb2d_mosaic,KIND=8), 'g_urb2d_mosaic', &
          LBOUND(g_urb2d_mosaic), UBOUND(g_urb2d_mosaic))
        IF (PRESENT(rn_urb2d_mosaic)) CALL gpu_cc_done_r(811, rn_urb2d_mosaic, SIZE(rn_urb2d_mosaic,KIND=8), 'rn_urb2d_mosaic', &
          LBOUND(rn_urb2d_mosaic), UBOUND(rn_urb2d_mosaic))
        IF (PRESENT(ts_urb2d_mosaic)) CALL gpu_cc_done_r(812, ts_urb2d_mosaic, SIZE(ts_urb2d_mosaic,KIND=8), 'ts_urb2d_mosaic', &
          LBOUND(ts_urb2d_mosaic), UBOUND(ts_urb2d_mosaic))
        IF (PRESENT(ts_rul2d_mosaic)) CALL gpu_cc_done_r(813, ts_rul2d_mosaic, SIZE(ts_rul2d_mosaic,KIND=8), 'ts_rul2d_mosaic', &
          LBOUND(ts_rul2d_mosaic), UBOUND(ts_rul2d_mosaic))
        CALL gpu_cc_done_r(814, zol, SIZE(zol,KIND=8), 'zol', &
          LBOUND(zol), UBOUND(zol))
        IF (PRESENT(sda_hfx)) CALL gpu_cc_done_r(815, sda_hfx, SIZE(sda_hfx,KIND=8), 'sda_hfx', &
          LBOUND(sda_hfx), UBOUND(sda_hfx))
        IF (PRESENT(sda_qfx)) CALL gpu_cc_done_r(816, sda_qfx, SIZE(sda_qfx,KIND=8), 'sda_qfx', &
          LBOUND(sda_qfx), UBOUND(sda_qfx))
        IF (PRESENT(hfx_both)) CALL gpu_cc_done_r(817, hfx_both, SIZE(hfx_both,KIND=8), 'hfx_both', &
          LBOUND(hfx_both), UBOUND(hfx_both))
        IF (PRESENT(qfx_both)) CALL gpu_cc_done_r(818, qfx_both, SIZE(qfx_both,KIND=8), 'qfx_both', &
          LBOUND(qfx_both), UBOUND(qfx_both))
        IF (PRESENT(qnorm)) CALL gpu_cc_done_r(819, qnorm, SIZE(qnorm,KIND=8), 'qnorm', &
          LBOUND(qnorm), UBOUND(qnorm))
        IF (PRESENT(pattern_spp_lsm)) CALL gpu_cc_done_r(820, pattern_spp_lsm, SIZE(pattern_spp_lsm,KIND=8), 'pattern_spp_lsm', &
          LBOUND(pattern_spp_lsm), UBOUND(pattern_spp_lsm))
        IF (PRESENT(field_sf)) CALL gpu_cc_done_r(821, field_sf, SIZE(field_sf,KIND=8), 'field_sf', &
          LBOUND(field_sf), UBOUND(field_sf))
        IF (PRESENT(pattern_spp_pbl)) CALL gpu_cc_done_r(822, pattern_spp_pbl, SIZE(pattern_spp_pbl,KIND=8), 'pattern_spp_pbl', &
          LBOUND(pattern_spp_pbl), UBOUND(pattern_spp_pbl))
        IF (PRESENT(xlaidyn)) CALL gpu_cc_done_r(823, xlaidyn, SIZE(xlaidyn,KIND=8), 'xlaidyn', &
          LBOUND(xlaidyn), UBOUND(xlaidyn))
        IF (PRESENT(perts_qvapor)) CALL gpu_cc_done_r(824, perts_qvapor, SIZE(perts_qvapor,KIND=8), 'perts_qvapor', &
          LBOUND(perts_qvapor), UBOUND(perts_qvapor))
        IF (PRESENT(perts_th)) CALL gpu_cc_done_r(825, perts_th, SIZE(perts_th,KIND=8), 'perts_th', &
          LBOUND(perts_th), UBOUND(perts_th))
        IF (PRESENT(perts_smois)) CALL gpu_cc_done_r(826, perts_smois, SIZE(perts_smois,KIND=8), 'perts_smois', &
          LBOUND(perts_smois), UBOUND(perts_smois))
        IF (PRESENT(perts_tsoil)) CALL gpu_cc_done_r(827, perts_tsoil, SIZE(perts_tsoil,KIND=8), 'perts_tsoil', &
          LBOUND(perts_tsoil), UBOUND(perts_tsoil))
        IF (PRESENT(irr_rand_field)) CALL gpu_cc_done_i(828, irr_rand_field, SIZE(irr_rand_field,KIND=8), 'irr_rand_field', &
          LBOUND(irr_rand_field), UBOUND(irr_rand_field))
        IF (gpu_cc_next(R_SURFACE_DRIVER)) GOTO 99901
      END IF
#endif
   END SUBROUTINE surface_driver

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

   subroutine myjsfc_seaice_wrapper(ITIMESTEP,HT,DZ,      &
        &     PMID,PINT,TH,T,QV,QC,U,V,Q2,                &
        &     TSK,QSFC,THZ0,QZ0,UZ0,VZ0,                  &
        &     LOWLYR,XLAND,IVGTYP,ISURBAN,IZ0TLND,        &
        &     TICE2TSK_IF2COLD,                           &  ! Extra for wrapper
        &     XICE_THRESHOLD,                             &  ! Extra for wrapper
        &     XICE,SST,                                   &  ! Extra for wrapper
        &     CHS_SEA, CHS2_SEA, CQS2_SEA, CPM_SEA,       &  ! Extra for wrapper
        &     FLHC_SEA, FLQC_SEA, QSFC_SEA,               &  ! Extra for wrapper
        &     QGH_SEA, QZ0_SEA, HFX_SEA, QFX_SEA,         &  ! Extra for wrapper
        &     FLX_LH_SEA, TSK_SEA,                        &  ! Extra for wrapper
        &     USTAR,ZNT,Z0BASE,PBLH,MAVAIL,RMOL,          &
        &     AKHS,AKMS,                                  &
        &     BR,                                         &
        &     CHS,CHS2,CQS2,HFX,QFX,FLX_LH,FLHC,FLQC,     &
        &     QGH,CPM,CT,                                 &
        &     U10,V10,T02,TH02,TSHLTR,TH10,Q02,QSHLTR,Q10,PSHLTR,          &
        &     P1000,U10E,V10E,                            &
        &     IDS,IDE,JDS,JDE,KDS,KDE,                        &
        &     IMS,IME,JMS,JME,KMS,KME,                        &
        &     ITS,ITE,JTS,JTE,KTS,KTE )
!     USE module_model_constants
     USE module_sf_myjsfc

     IMPLICIT NONE

     INTEGER,                                INTENT(IN)    :: ITIMESTEP
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: HT
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: DZ
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: PMID
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: PINT
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: TH
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: T
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: QV
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: QC
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: U
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: V
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: Q2   ! Q2 is TKE?

     ! REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: TSK
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT)    :: TSK

     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: QSFC
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: THZ0
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: QZ0
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: UZ0
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: VZ0
     INTEGER,DIMENSION(IMS:IME,JMS:JME),     INTENT(IN)    :: LOWLYR
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: XLAND
     INTEGER,DIMENSION(IMS:IME,JMS:JME),     INTENT(IN)    :: IVGTYP
     INTEGER                                               :: ISURBAN
     INTEGER                                               :: IZ0TLND
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: XICE       ! Extra for wrapper
     ! REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: SST        ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: SST        ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: BR
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CHS_SEA    ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CHS2_SEA   ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CQS2_SEA   ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CPM_SEA    ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QZ0_SEA   ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QSFC_SEA   ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QGH_SEA   ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLHC_SEA  ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLQC_SEA  ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: HFX_SEA    ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QFX_SEA    ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLX_LH_SEA ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: TSK_SEA    ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: USTAR
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: ZNT
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: Z0BASE
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: PBLH
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: MAVAIL
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: RMOL
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: AKHS
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: AKMS
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CHS
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CHS2
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CQS2
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: HFX
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QFX
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLX_LH
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLHC
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLQC
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QGH
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CPM
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CT
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: U10
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: V10
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: U10E
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: V10E
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: T02
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: TH02
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: TSHLTR
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: TH10
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: Q02
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QSHLTR
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: Q10
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: PSHLTR
     REAL,                                   INTENT(IN)    :: P1000
     REAL,                                   INTENT(IN)    :: XICE_THRESHOLD
     LOGICAL,                                INTENT(IN)    :: TICE2TSK_IF2COLD
     INTEGER,INTENT(IN) :: IDS,IDE,JDS,JDE,KDS,KDE,       &
          &                IMS,IME,JMS,JME,KMS,KME,       &
          &                ITS,ITE,JTS,JTE,KTS,KTE


     ! Local
     INTEGER :: i
     INTEGER :: j
     REAL, DIMENSION( ims:ime, jms:jme ) :: ct_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: u10_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: v10_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: u10e_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: v10e_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: t02_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: th02_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: tshltr_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: pshltr_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: qshltr_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: th10_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: q02_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: q10_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: thz0_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: uz0_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: vz0_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: ustar_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: pblh_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: rmol_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: akhs_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: akms_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: xland_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: mavail_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: znt_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: z0base_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: br_sea

     REAL, DIMENSION( ims:ime, jms:jme ) :: QSFC_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: QZ0_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: THZ0_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: UZ0_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: VZ0_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: USTAR_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: ZNT_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: PBLH_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: RMOL_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: AKHS_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: AKMS_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: TSK_LOCAL
     REAL :: PSFC

     ! Set things up for the frozen-surface call to myjsfc
     ! Is SST local here, or are the changes to be fed back to the calling routines?

     ! We want a TSK valid for the ice-covered regions of the grid cell.

     CALL get_local_ice_tsk( ims, ime, jms, jme, its, ite, jts, jte,  &
                             itimestep, .true., tice2tsk_if2cold,     &
                             XICE, XICE_THRESHOLD,                    &
                             SST, TSK, TSK_SEA, TSK_LOCAL )
     DO j = JTS , JTE
        DO i = ITS , ITE
           TSK(i,j) = TSK_LOCAL(i,j)
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN

              ! Over fractional sea-ice points, back out an ice portion of QSFC as well.
              ! QSFC_SEA calculation as done in myjsfc for open water points
              PSFC = PINT(I,LOWLYR(I,J),J)
              QSFC_SEA(i,j) = PQ0SEA/PSFC*rp_exp(A2S*(TSK(i,j)-A3S)/(TSK(i,j)-A4S))
              QSFC(i,j) = (QSFC(i,j) - (1.0-XICE(i,j)) * QSFC_SEA(i,j)) / XICE(i,j)
!
              HFX_SEA(i,j)  = HFX(i,j)
              QFX_SEA(i,j)  = QFX(i,j)
              FLX_LH_SEA(i,j)   = FLX_LH(i,j)
           ENDIF
        ENDDO
     ENDDO

!
! frozen ocean call for sea ice points
!

! Strictly INTENT(IN) to MYJSFC, should be unchanged by call.

     ! DZ
     ! HT
     ! LOWLYR
     ! MAVAIL
     ! PINT
     ! PMID
     ! QC
     ! QV
     ! Q2
     ! T
     ! TH
     ! TSK
     ! U
     ! V
     ! XLAND
     ! Z0BASE

! INTENT (INOUT),  updated by MYJSFC.  Values will need to be saved before the first call to MYJSFC, so that
! the second call to MYJSFC does not double-count the effect.

     ! Save INTENT(INOUT) variables before the frozen-water/true-land call to MYJSFC:
     QSFC_HOLD(its:ite,jts:jte)  = QSFC(its:ite,jts:jte)
     QZ0_HOLD(its:ite,jts:jte)   = QZ0(its:ite,jts:jte)
     THZ0_HOLD(its:ite,jts:jte)  = THZ0(its:ite,jts:jte)
     UZ0_HOLD(its:ite,jts:jte)   = UZ0(its:ite,jts:jte)
     VZ0_HOLD(its:ite,jts:jte)   = VZ0(its:ite,jts:jte)
     USTAR_HOLD(its:ite,jts:jte) = USTAR(its:ite,jts:jte)
     ZNT_HOLD(its:ite,jts:jte)   = ZNT(its:ite,jts:jte)
     PBLH_HOLD(its:ite,jts:jte)  = PBLH(its:ite,jts:jte)
     RMOL_HOLD(its:ite,jts:jte)  = RMOL(its:ite,jts:jte)
     AKHS_HOLD(its:ite,jts:jte)  = AKHS(its:ite,jts:jte)
     AKMS_HOLD(its:ite,jts:jte)  = AKMS(its:ite,jts:jte)

! Strictly INTENT(OUT):  Set by MYJSFC

     ! CHS
     ! CHS2
     ! CPM
     ! CQS2
     ! CT
     ! FLHC
     ! FLQC
     ! FLX_LH
     ! HFX
     ! PSHLTR
     ! QFX
     ! QGH
     ! QSHLTR
     ! Q02
     ! Q10
     ! TH02
     ! TH10
     ! TSHLTR
     ! T02
     ! U10
     ! V10

     ! Frozen-water/true-land call.
     CALL MYJSFC ( ITIMESTEP, HT, DZ,                              &  ! I,I,I,
          &        PMID, PINT, TH, T, QV, QC, U, V, Q2,            &  ! I,I,I,I,I,I,I,I,I,
          &        TSK, QSFC, THZ0, QZ0, UZ0, VZ0,                 &  ! I,IO,IO,IO,IO,IO,
          &        LOWLYR, XLAND, IVGTYP, ISURBAN, IZ0TLND,        &  ! I,I,I,I,I
          &        USTAR, ZNT, Z0BASE, PBLH, MAVAIL, RMOL,         &  ! IO,IO,I,IO,I,IO,
          &        AKHS, AKMS,                                     &  ! IO,IO,
          &        BR,                                             &  ! O
          &        CHS, CHS2, CQS2, HFX, QFX, FLX_LH, FLHC, FLQC,  &  ! O,O,O,0,0,0,0,0,
          &        QGH, CPM, CT, U10, V10, T02,                    &  ! 0,0,0,0,0,0,
          &        TH02, TSHLTR, TH10, Q02,                        &  ! 0,0,0,0,
          &        QSHLTR, Q10, PSHLTR,                            &  ! 0,0,0,
          &        P1000, U10E, V10E,                              &  ! I
          &        ids,ide, jds,jde, kds,kde,                      &
          &        ims,ime, jms,jme, kms,kme,                      &
          &        its,ite, jts,jte, kts,kte    )

     ! Set up things for the open ocean call.
     DO j = JTS, JTE
        DO i = ITS, ITE
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
              XLAND_SEA(i,j)=2.
              MAVAIL_SEA(I,J)  = 1.
              ZNT_SEA(I,J) = 0.0001
              Z0BASE_SEA(I,J) = ZNT_SEA(I,J)
              IF ( SST(i,j) .LT. 271.4 ) THEN
                 SST(i,j) = 271.4
              ENDIF
              TSK_SEA(i,j) = SST(i,j)
              PSFC = PINT(I,LOWLYR(I,J),J)
              QSFC_SEA(I,J) = PQ0SEA/PSFC*rp_exp(A2S*(TSK_SEA(i,j)-A3S)/(TSK_SEA(i,j)-A4S))
           ELSE
              ! This should be a land point or a true open water point
              XLAND_SEA(i,j)=xland(i,j)
              MAVAIL_SEA(i,j) = mavail(i,j)
              ZNT_SEA(I,J)    = ZNT_HOLD(I,J)
              Z0BASE_SEA(I,J) = Z0BASE(I,J)
              TSK_SEA(i,j)  = TSK(i,j)
              QSFC_SEA(i,j) = QSFC_HOLD(i,j)
           ENDIF
        ENDDO
     ENDDO

     QZ0_SEA(its:ite,jts:jte)  = QZ0_HOLD(its:ite,jts:jte)
     THZ0_SEA(its:ite,jts:jte) = THZ0_HOLD(its:ite,jts:jte)
     UZ0_SEA(its:ite,jts:jte)  = UZ0_HOLD(its:ite,jts:jte)
     VZ0_SEA(its:ite,jts:jte)  = VZ0_HOLD(its:ite,jts:jte)
     USTAR_SEA(its:ite,jts:jte) = USTAR_HOLD(its:ite,jts:jte)
     PBLH_SEA(its:ite,jts:jte) = PBLH_HOLD(its:ite,jts:jte)
     RMOL_SEA(its:ite,jts:jte) = RMOL_HOLD(its:ite,jts:jte)
     AKHS_SEA(its:ite,jts:jte) = AKHS_HOLD(its:ite,jts:jte)
     AKMS_SEA(its:ite,jts:jte) = AKMS_HOLD(its:ite,jts:jte)
!
! open water call
!
     CALL MYJSFC ( ITIMESTEP, HT, DZ,                                                          & ! I,I,I,
          &        PMID, PINT, TH, T, QV, QC, U, V, Q2,                                        & ! I,I,I,I,I,I,I,I,I,
          &        TSK_SEA, QSFC_SEA, THZ0_SEA, QZ0_SEA, UZ0_SEA, VZ0_SEA,                     & ! I,IO,IO,IO,IO,IO,
          &        LOWLYR, XLAND_SEA, IVGTYP, ISURBAN, IZ0TLND,                                & ! I,I,I,I,I,
          &        USTAR_SEA, ZNT_SEA, Z0BASE_SEA, PBLH_SEA, MAVAIL_SEA, RMOL_SEA,             & ! IO,IO,I,IO,I,IO,
          &        AKHS_SEA, AKMS_SEA,                                                         & ! IO,IO,
          &        BR_SEA,                                                                     & ! dummy space holder
          &        CHS_SEA, CHS2_SEA, CQS2_SEA, HFX_SEA, QFX_SEA, FLX_LH_SEA, FLHC_SEA,        & ! 0,0,0,0,0,0,0,
          &        FLQC_SEA, QGH_SEA, CPM_SEA, CT_SEA, U10_SEA, V10_SEA, T02_SEA, TH02_SEA,    & ! 0,0,0,0,0,0,0,0,
          &        TSHLTR_SEA, TH10_SEA, Q02_SEA, QSHLTR_SEA, Q10_SEA, PSHLTR_SEA,             & ! 0,0,0,0,0,0,
          &        p1000, u10e_sea,  v10e_sea,                                                 & ! I
          &        ids,ide, jds,jde, kds,kde,                                                  &
          &        ims,ime, jms,jme, kms,kme,                                                  &
          &        its,ite, jts,jte, kts,kte    )

!
! Scale the appropriate terms between open-water values and ice-covered values
!

     DO j = JTS, JTE
        DO i = ITS, ITE
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN
              ! Over sea-ice points, blend the results.

              ! INTENT(OUT) from MYJSFC
              ! CHS  wait
              ! CHS2 wait
              ! CPM  wait
              ! CQS2 wait
              CT(i,j)     = CT(i,j)     * XICE(i,j) + (1.0-XICE(i,j)) * CT_SEA (i,j)
              ! FLHC(i,j)   = FLHC(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * FLHC_SEA (i,j)
              ! FLQC(i,j)   = FLQC(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * FLQC_SEA (i,j)
              ! FLX_LH wait
              ! HFX  wait
              PSHLTR(i,j) = PSHLTR(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * PSHLTR_SEA(i,j)
              ! QFX  wait
              ! QGH  wait
              QSHLTR(i,j) = QSHLTR(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * QSHLTR_SEA(i,j)
              Q02(i,j)    = Q02(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * Q02_SEA(i,j)
              Q10(i,j)    = Q10(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * Q10_SEA(i,j)
              TH02(i,j)   = TH02(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * TH02_SEA(i,j)
              TH10(i,j)   = TH10(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * TH10_SEA(i,j)
              TSHLTR(i,j) = TSHLTR(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * TSHLTR_SEA(i,j)
              T02(i,j)    = T02(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * T02_SEA(i,j)
              U10(i,j)    = U10(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * U10_SEA(i,j)
              V10(i,j)    = V10(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * V10_SEA(i,j)
              U10E(i,j)   = U10(i,j)
              V10E(i,j)   = V10(i,j)

              ! INTENT(INOUT):  updated by MYJSFC
              ! QSFC:  wait
              THZ0(i,j)   = THZ0(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * THZ0_SEA(i,j)
              ! qz0 wait
              UZ0(i,j)    = UZ0(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * UZ0_SEA(i,j)
              VZ0(i,j)    = VZ0(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * VZ0_SEA(i,j)
              USTAR(i,j)  = USTAR(i,j)  * XICE(i,j) + (1.0-XICE(i,j)) * USTAR_SEA(i,j)
              ! ZNT wait
              PBLH(i,j)   = PBLH(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * PBLH_SEA(i,j)
              RMOL(i,j)   = RMOL(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * RMOL_SEA(i,j)
              AKHS(i,j)   = AKHS(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * AKHS_SEA(i,j)
              AKMS(i,j)   = AKMS(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * AKMS_SEA(i,j)

              !         tsk(i,j) = tsk(i,j)*XICE(i,j) + (1.0-XICE(i,j))*TSK_SEA(i,j)
           ELSE
              ! We're not over sea ice.  Take the results from the first call.
           ENDIF
        ENDDO
     ENDDO

   END SUBROUTINE myjsfc_seaice_wrapper

!------------------------------------------------------------------------

 subroutine qnsesfc_seaice_wrapper(ITIMESTEP,HT,DZ,      &
        &     PMID,PINT,TH,T,QV,QC,U,V,Q2,                &
        &     TSK,QSFC,THZ0,QZ0,UZ0,VZ0,                  &
        &     LOWLYR,XLAND,       &
        &     TICE2TSK_IF2COLD,                           &  ! Extra for wrapper
        &     XICE_THRESHOLD,                             &  ! Extra for wrapper
        &     XICE,SST,                                   &  ! Extra for wrapper
        &     CHS_SEA, CHS2_SEA, CQS2_SEA, CPM_SEA,       &  ! Extra for wrapper
        &     FLHC_SEA, FLQC_SEA, QSFC_SEA,               &  ! Extra for wrapper
        &     QGH_SEA, QZ0_SEA, HFX_SEA, QFX_SEA,         &  ! Extra for wrapper
        &     FLX_LH_SEA, TSK_SEA,                        &  ! Extra for wrapper
        &     USTAR,ZNT,Z0BASE,PBLH,MAVAIL,RMOL,          &
        &     AKHS,AKMS,                                  &
        &     BR,                                         &
        &     CHS,CHS2,CQS2,HFX,QFX,FLX_LH,FLHC,FLQC,     &
        &     QGH,CPM,CT,                                 &
        &     U10,V10,T02,TH02,TSHLTR,TH10,Q02,QSHLTR,Q10,PSHLTR,          &
        &     U10E,V10E,                                  &
        &     IDS,IDE,JDS,JDE,KDS,KDE,                        &
        &     IMS,IME,JMS,JME,KMS,KME,                        &
        &     ITS,ITE,JTS,JTE,KTS,KTE,SCM_FORCE_FLUX )
!     USE module_model_constants
     USE module_sf_qnsesfc

     IMPLICIT NONE

     INTEGER,                                INTENT(IN)    :: ITIMESTEP
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: HT
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: DZ
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: PMID
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: PINT
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: TH
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: T
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: QV
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: QC
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: U
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: V
     REAL,DIMENSION(IMS:IME,KMS:KME,JMS:JME),INTENT(IN)    :: Q2   ! Q2 is TKE?

     ! REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: TSK
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT)    :: TSK

     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: QSFC
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: THZ0
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: QZ0
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: UZ0
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: VZ0
     INTEGER,DIMENSION(IMS:IME,JMS:JME),     INTENT(IN)    :: LOWLYR
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: XLAND
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: XICE       ! Extra for wrapper
     ! REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: SST        ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: SST        ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: BR
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CHS_SEA    ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CHS2_SEA   ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CQS2_SEA   ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CPM_SEA    ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QZ0_SEA   ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QSFC_SEA   ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QGH_SEA   ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLHC_SEA  ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLQC_SEA  ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: HFX_SEA    ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QFX_SEA    ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLX_LH_SEA ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: TSK_SEA    ! Extra for wrapper
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: USTAR
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: ZNT
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: Z0BASE
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: PBLH
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(IN)    :: MAVAIL
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: RMOL
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: AKHS
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(INOUT) :: AKMS
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CHS
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CHS2
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CQS2
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: HFX
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QFX
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLX_LH
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLHC
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: FLQC
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QGH
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CPM
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: CT
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: U10
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: V10
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: U10E
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: V10E
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: T02
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: TH02
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: TSHLTR
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: TH10
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: Q02
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: QSHLTR
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: Q10
     REAL,DIMENSION(IMS:IME,JMS:JME),        INTENT(OUT)   :: PSHLTR
     REAL,                                   INTENT(IN)    :: XICE_THRESHOLD
     LOGICAL,                                INTENT(IN)    :: TICE2TSK_IF2COLD
     INTEGER,                                INTENT(IN)    :: SCM_FORCE_FLUX
     INTEGER,INTENT(IN) :: IDS,IDE,JDS,JDE,KDS,KDE,       &
          &                IMS,IME,JMS,JME,KMS,KME,       &
          &                ITS,ITE,JTS,JTE,KTS,KTE


     ! Local
     INTEGER :: i
     INTEGER :: j
     REAL, DIMENSION( ims:ime, jms:jme ) :: ct_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: u10_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: v10_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: u10e_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: v10e_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: t02_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: th02_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: tshltr_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: pshltr_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: qshltr_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: th10_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: q02_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: q10_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: thz0_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: uz0_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: vz0_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: ustar_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: pblh_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: rmol_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: akhs_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: akms_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: xland_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: mavail_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: znt_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: z0base_sea
     REAL, DIMENSION( ims:ime, jms:jme ) :: br_sea

     REAL, DIMENSION( ims:ime, jms:jme ) :: QSFC_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: QZ0_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: THZ0_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: UZ0_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: VZ0_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: USTAR_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: ZNT_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: PBLH_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: RMOL_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: AKHS_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: AKMS_HOLD
     REAL, DIMENSION( ims:ime, jms:jme ) :: TSK_LOCAL
     REAL :: PSFC

     ! Set things up for the frozen-surface call to qnsesfc

     ! We want a TSK valid for the ice-covered regions of the grid cell.

     CALL get_local_ice_tsk( ims, ime, jms, jme, its, ite, jts, jte,  &
                             itimestep, .true., tice2tsk_if2cold,     &
                             XICE, XICE_THRESHOLD,                    &
                             SST, TSK, TSK_SEA, TSK_LOCAL )
     DO j = JTS , JTE
        DO i = ITS , ITE
           TSK(i,j) = TSK_LOCAL(i,j)
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN

              ! Over fractional sea-ice points, back out an ice portion of QSFC as well.
              ! QSFC_SEA calculation as done in qnsesfc for open water points
              PSFC = PINT(I,LOWLYR(I,J),J)
              QSFC_SEA(i,j) = PQ0SEA/PSFC*rp_exp(A2S*(TSK(i,j)-A3S)/(TSK(i,j)-A4S))
              QSFC(i,j) = (QSFC(i,j) - (1.0-XICE(i,j)) * QSFC_SEA(i,j)) / XICE(i,j)
!
              HFX_SEA(i,j)  = HFX(i,j)
              QFX_SEA(i,j)  = QFX(i,j)
              FLX_LH_SEA(i,j)   = FLX_LH(i,j)
           ENDIF
        ENDDO
     ENDDO

!
! frozen ocean call for sea ice points
!

! Strictly INTENT(IN) to QNSESFC, should be unchanged by call.

     ! DZ
     ! HT
     ! LOWLYR
     ! MAVAIL
     ! PINT
     ! PMID
     ! QC
     ! QV
     ! Q2
     ! T
     ! TH
     ! TSK
     ! U
     ! V
     ! XLAND
     ! Z0BASE

! INTENT (INOUT),  updated by QNSESFC.  Values will need to be saved before the first call to QNSESFC, so that
! the second call to QNSESFC does not double-count the effect.

     ! Save INTENT(INOUT) variables before the frozen-water/true-land call to QNSESFC:
     QSFC_HOLD(its:ite,jts:jte)  = QSFC(its:ite,jts:jte)
     QZ0_HOLD(its:ite,jts:jte)   = QZ0(its:ite,jts:jte)
     THZ0_HOLD(its:ite,jts:jte)  = THZ0(its:ite,jts:jte)
     UZ0_HOLD(its:ite,jts:jte)   = UZ0(its:ite,jts:jte)
     VZ0_HOLD(its:ite,jts:jte)   = VZ0(its:ite,jts:jte)
     USTAR_HOLD(its:ite,jts:jte) = USTAR(its:ite,jts:jte)
     ZNT_HOLD(its:ite,jts:jte)   = ZNT(its:ite,jts:jte)
     PBLH_HOLD(its:ite,jts:jte)  = PBLH(its:ite,jts:jte)
     RMOL_HOLD(its:ite,jts:jte)  = RMOL(its:ite,jts:jte)
     AKHS_HOLD(its:ite,jts:jte)  = AKHS(its:ite,jts:jte)
     AKMS_HOLD(its:ite,jts:jte)  = AKMS(its:ite,jts:jte)

! Strictly INTENT(OUT):  Set by QNSESFC

     ! CHS
     ! CHS2
     ! CPM
     ! CQS2
     ! CT
     ! FLHC
     ! FLQC
     ! FLX_LH
     ! HFX
     ! PSHLTR
     ! QFX
     ! QGH
     ! QSHLTR
     ! Q02
     ! Q10
     ! TH02
     ! TH10
     ! TSHLTR
     ! T02
     ! U10
     ! V10

     ! Frozen-water/true-land call.
     CALL QNSESFC ( ITIMESTEP, HT, DZ,                              &  ! I,I,I,
          &        PMID, PINT, TH, T, QV, QC, U, V, Q2,            &  ! I,I,I,I,I,I,I,I,I,
          &        TSK, QSFC, THZ0, QZ0, UZ0, VZ0,                 &  ! I,IO,IO,IO,IO,IO,
          &        LOWLYR, XLAND,      &  ! I,I
          &        USTAR, ZNT, Z0BASE, PBLH, MAVAIL, RMOL,         &  ! IO,IO,I,IO,I,IO,
          &        AKHS, AKMS,                                     &  ! IO,IO,
          &        BR,                                             &  ! O
          &        CHS, CHS2, CQS2, HFX, QFX, FLX_LH, FLHC, FLQC,  &  ! O,O,O,0,0,0,0,0,
          &        QGH, CPM, CT, U10, V10,T02,TH02,                    &  ! 0,0,0,0,0,0,0
          &        TSHLTR, TH10, Q02,                    &  ! 0,0,0
          &        QSHLTR, Q10, PSHLTR,                            &  ! 0,0,0,
          &        U10E, V10E,                                     &  ! 0,0,0,
          &        ids,ide, jds,jde, kds,kde,                      &
          &        ims,ime, jms,jme, kms,kme,                      &
          &        its,ite, jts,jte, kts,kte, SCM_FORCE_FLUX    )

     ! Set up things for the open ocean call.
     DO j = JTS, JTE
        DO i = ITS, ITE
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .AND. ( XICE(i,j) .LE. 1.0 ) ) THEN
              XLAND_SEA(i,j)=2.
              MAVAIL_SEA(I,J)  = 1.
              ZNT_SEA(I,J) = 0.0001
              Z0BASE_SEA(I,J) = ZNT_SEA(I,J)
              IF ( SST(i,j) .LT. 271.4 ) THEN
                 SST(i,j) = 271.4
              ENDIF
              TSK_SEA(i,j) = SST(i,j)
              PSFC = PINT(I,LOWLYR(I,J),J)
              QSFC_SEA(I,J) = PQ0SEA/PSFC*rp_exp(A2S*(TSK_SEA(i,j)-A3S)/(TSK_SEA(i,j)-A4S))
           ELSE
              ! This should be a land point or a true open water point
              XLAND_SEA(i,j)=xland(i,j)
              MAVAIL_SEA(i,j) = mavail(i,j)
              ZNT_SEA(I,J)    = ZNT_HOLD(I,J)
              Z0BASE_SEA(I,J) = Z0BASE(I,J)
              TSK_SEA(i,j)  = TSK(i,j)
              QSFC_SEA(i,j) = QSFC_HOLD(i,j)
           ENDIF
        ENDDO
     ENDDO

     QZ0_SEA(its:ite,jts:jte)  = QZ0_HOLD(its:ite,jts:jte)
     THZ0_SEA(its:ite,jts:jte) = THZ0_HOLD(its:ite,jts:jte)
     UZ0_SEA(its:ite,jts:jte)  = UZ0_HOLD(its:ite,jts:jte)
     VZ0_SEA(its:ite,jts:jte)  = VZ0_HOLD(its:ite,jts:jte)
     USTAR_SEA(its:ite,jts:jte) = USTAR_HOLD(its:ite,jts:jte)
     PBLH_SEA(its:ite,jts:jte) = PBLH_HOLD(its:ite,jts:jte)
     RMOL_SEA(its:ite,jts:jte) = RMOL_HOLD(its:ite,jts:jte)
     AKHS_SEA(its:ite,jts:jte) = AKHS_HOLD(its:ite,jts:jte)
     AKMS_SEA(its:ite,jts:jte) = AKMS_HOLD(its:ite,jts:jte)
!
! open water call
!
     CALL QNSESFC ( ITIMESTEP, HT, DZ,                                                          & ! I,I,I,
          &        PMID, PINT, TH, T, QV, QC, U, V, Q2,                                        & ! I,I,I,I,I,I,I,I,I,
          &        TSK_SEA, QSFC_SEA, THZ0_SEA, QZ0_SEA, UZ0_SEA, VZ0_SEA,                     & ! I,IO,IO,IO,IO,IO,
          &        LOWLYR, XLAND_SEA,                             & ! I,I,
          &        USTAR_SEA, ZNT_SEA, Z0BASE_SEA, PBLH_SEA, MAVAIL_SEA, RMOL_SEA,             & ! IO,IO,I,IO,I,IO,
          &        AKHS_SEA, AKMS_SEA,                                                         & ! IO,IO,
          &        BR_SEA,                                                                     & ! dummy space holder
          &        CHS_SEA, CHS2_SEA, CQS2_SEA, HFX_SEA, QFX_SEA, FLX_LH_SEA, FLHC_SEA,        & ! 0,0,0,0,0,0,0,
          &        FLQC_SEA, QGH_SEA, CPM_SEA, CT_SEA, U10_SEA, V10_SEA,T02_SEA,TH02_SEA,   & ! 0,0,0,0,0,0,0,0
          &        TSHLTR_SEA, TH10_SEA, Q02_SEA, QSHLTR_SEA, Q10_SEA, PSHLTR_SEA,             & ! 0,0,0,0,0,0
          &        U10E, V10E,                                                                 &
          &        ids,ide, jds,jde, kds,kde,                                                  &
          &        ims,ime, jms,jme, kms,kme,                                                  &
          &        its,ite, jts,jte, kts,kte, SCM_FORCE_FLUX    )

!
! Scale the appropriate terms between open-water values and ice-covered values
         

     DO j = JTS, JTE
        DO i = ITS, ITE
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN
              ! Over sea-ice points, blend the results.

              ! INTENT(OUT) from QNSESFC
              ! CHS  wait
              ! CHS2 wait
              ! CPM  wait
              ! CQS2 wait
              CT(i,j)     = CT(i,j)     * XICE(i,j) + (1.0-XICE(i,j)) * CT_SEA (i,j)
              ! FLHC(i,j)   = FLHC(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * FLHC_SEA (i,j)
              ! FLQC(i,j)   = FLQC(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * FLQC_SEA (i,j)
              ! FLX_LH wait
              ! HFX  wait
              PSHLTR(i,j) = PSHLTR(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * PSHLTR_SEA(i,j)
              ! QFX  wait
              ! QGH  wait
              QSHLTR(i,j) = QSHLTR(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * QSHLTR_SEA(i,j)
              Q10(i,j)    = Q10(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * Q10_SEA(i,j)
              Q02(i,j)    = Q02(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * Q02_SEA(i,j)
              TH10(i,j)   = TH10(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * TH10_SEA(i,j)
               TH02(i,j)   = TH02(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * TH02_SEA(i,j)
              TSHLTR(i,j) = TSHLTR(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * TSHLTR_SEA(i,j)
              T02(i,j)    = T02(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * T02_SEA(i,j)
              U10(i,j)    = U10(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * U10_SEA(i,j)
              V10(i,j)    = V10(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * V10_SEA(i,j)
              U10E(i,j)   = U10(i,j)
              V10E(i,j)   = V10(i,j)

              ! INTENT(INOUT):  updated by QNSESFC
              ! QSFC:  wait
              THZ0(i,j)   = THZ0(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * THZ0_SEA(i,j)
              ! qz0 wait
              UZ0(i,j)    = UZ0(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * UZ0_SEA(i,j)
              VZ0(i,j)    = VZ0(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * VZ0_SEA(i,j)
              USTAR(i,j)  = USTAR(i,j)  * XICE(i,j) + (1.0-XICE(i,j)) * USTAR_SEA(i,j)
              ! ZNT wait
              PBLH(i,j)   = PBLH(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * PBLH_SEA(i,j)
              RMOL(i,j)   = RMOL(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * RMOL_SEA(i,j)
              AKHS(i,j)   = AKHS(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * AKHS_SEA(i,j)
              AKMS(i,j)   = AKMS(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * AKMS_SEA(i,j)

              !         tsk(i,j) = tsk(i,j)*XICE(i,j) + (1.0-XICE(i,j))*TSK_SEA(i,j)
           ELSE
              ! We're not over sea ice.  Take the results from the first call.
           ENDIF
        ENDDO
     ENDDO

   END SUBROUTINE qnsesfc_seaice_wrapper


!-------------------------------------------------------------------------

   SUBROUTINE mynn_seaice_wrapper(U3D,V3D,T3D,QV3D,                &
              P3D,dz8w,th3d,rho,                                   &
              CP,G,ROVCP,R,XLV,PSFC,CHS,CHS2,CQS2,CPM,             &
              ZNT,UST,PBLH,MAVAIL,ZOL,MOL,REGIME,PSIM,PSIH,        &
              XLAND,HFX,QFX,LH,TSK,FLHC,FLQC,QGH,QSFC,RMOL,        &
              U10,V10,TH2,T2,Q2,SNOWH,                             &
              GZ1OZ0,WSPD,BR,ISFFLX,DX,                            &
              SVP1,SVP2,SVP3,SVPT0,EP1,EP2,KARMAN,                 &
              &itimestep,ch,qcg,                                   &
              &spp_pbl,pattern_spp_pbl,                            &
              XICE,SST,TSK_SEA,                                    &
              CHS2_SEA,CHS_SEA,CPM_SEA,CQS2_SEA,FLHC_SEA,FLQC_SEA, &
              HFX_SEA,LH_SEA,QFX_SEA,QGH_SEA,QSFC_SEA,ZNT_SEA,     &
              TICE2TSK_IF2COLD,XICE_THRESHOLD,                     &
              ids,ide, jds,jde, kds,kde,                           &
              ims,ime, jms,jme, kms,kme,                           &
              its,ite, jts,jte, kts,kte,                           &
              ustm,ck,cka,cd,cda,isftcflx,iz0tlnd                  )

     USE module_sf_mynn

     implicit none

     INTEGER,  INTENT(IN )   ::       ids,ide, jds,jde, kds,kde,  &
                                      ims,ime, jms,jme, kms,kme,  &
                                      its,ite, jts,jte, kts,kte
     INTEGER,  INTENT(IN )   ::       itimestep, ISFFLX
     INTEGER,  INTENT(IN ), optional ::  ISFTCFLX, IZ0TLND
     REAL,     INTENT(IN )   ::       SVP1,SVP2,SVP3,SVPT0
     REAL,     INTENT(IN )   ::       EP1,EP2,KARMAN,             &
                                      CP,G,ROVCP,R,XLV,DX

     INTEGER,  INTENT(IN), optional      ::     spp_pbl
     REAL,     DIMENSION( ims:ime, kms:kme, jms:jme ),            &
               INTENT(IN), OPTIONAL      ::   pattern_spp_pbl

     REAL,     DIMENSION( ims:ime, kms:kme, jms:jme )           , &
               INTENT(IN   )   ::                           dz8w, &
                                                            QV3D, &
                                                             P3D, &
                                                             T3D, &
                                                             U3D, &
                                                             V3D, &
                                                        rho,th3d

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(IN   )               ::             MAVAIL, &
                                                            PBLH, &
                                                           XLAND, &
                                                             QCG, &
                                                            PSFC, &
                                                           SNOWH, &
                                                             TSK

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(OUT  )               ::                U10, &
                                                             V10, &
                                                             TH2, &
                                                              T2, &
                                                              Q2

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)               ::             REGIME, &
                                                             HFX, &
                                                             QFX, &
                                                              LH, &
                                                        MOL,RMOL, &
                                                            QSFC, &
                                                             QGH, &
                                                             ZNT, &
                                                             ZOL, &
                                                             UST, &
                                                             CPM, &
                                                            CHS2, &
                                                            CQS2, &
                                                             CHS, &
                                                              CH, &
                                                       FLHC,FLQC, &
                                                  GZ1OZ0,WSPD,BR, &
                                                       PSIM,PSIH

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(OUT), OPTIONAL  ::      ck,cka,cd,cda,ustm

!--------------------------------------------------------------------
!    New for wrapper
!--------------------------------------------------------------------
     LOGICAL,  INTENT(IN)               ::      TICE2TSK_IF2COLD
     REAL,     INTENT(IN)               ::      XICE_THRESHOLD
     REAL,     DIMENSION( ims:ime, jms:jme ),                     &
               INTENT(IN)               ::      XICE
     REAL,     DIMENSION( ims:ime, jms:jme ),                     &
               INTENT(INOUT)            ::      SST
     REAL,     DIMENSION( ims:ime, jms:jme ), OPTIONAL,           &
               INTENT(OUT)              ::      TSK_SEA,          &
                                                CHS2_SEA,         &
                                                CHS_SEA,          &
                                                CPM_SEA,          &
                                                CQS2_SEA,         &
                                                FLHC_SEA,         &
                                                FLQC_SEA,         &
                                                HFX_SEA,          &
                                                LH_SEA,           &
                                                QFX_SEA,          &
                                                QGH_SEA,          &
                                                QSFC_SEA,         &
                                                ZNT_SEA

!--------------------------------------------------------------------
!    Local
!--------------------------------------------------------------------
     INTEGER :: I, J
     REAL,     DIMENSION( ims:ime, jms:jme ) :: TSK_LOCAL,        &
                 XLAND_SEA,                                       &
                 MAVAIL_sea,                                      &
                 BR_SEA,                        BR_HOLD,          &
                                                FLHC_HOLD,        &
                                                FLQC_HOLD,        &
                 GZ1OZ0_SEA,                    GZ1OZ0_HOLD,      &
                                                HFX_HOLD,         &
                                                LH_HOLD,          &
                 CH_SEA,                                          &
                 MOL_SEA,                       MOL_HOLD,         &
                 PSIH_SEA,                      PSIH_HOLD,        &
                 PSIM_SEA,                      PSIM_HOLD,        &
                                                QFX_HOLD,         &
                                                QGH_HOLD,         &
                                                CPM_HOLD,         &
                 RMOL_SEA,                      RMOL_HOLD,        &
                 UST_SEA,                       UST_HOLD,         &
                 WSPD_SEA,                      WSPD_HOLD,        &
                                                ZNT_HOLD,         &
                 ZOL_SEA,                       ZOL_HOLD,         &
                 Q2_SEA,                                          &
                 T2_SEA,                                          &
                 TH2_SEA,                                         &
                 U10_SEA,                                         &
                 V10_SEA,                                         &
                 CD_SEA,                                          &
                 CDA_SEA,                                         &
                 CK_SEA,                                          &
                 CKA_SEA,                                         &
                 USTM_SEA,                      USTM_HOLD


    CALL get_local_ice_tsk( ims, ime, jms, jme, its, ite, jts, jte,  &
                            itimestep, .true., tice2tsk_if2cold,     &
                            XICE, XICE_THRESHOLD,                    &
                            SST, TSK, TSK_SEA, TSK_LOCAL )


! DFS 8/25/10 Set TSK to ice value
!    DO j = JTS , JTE
!        DO i = ITS , ITE
!            TSK(i,j) = TSK_LOCAL(i,j)
!        ENDDO
!    ENDDO

! Save the variables before the first call
! (for land/frozen water) to SFCLAY_mynn.
     BR_HOLD(its:ite,jts:jte)   = BR(its:ite,jts:jte)
     CPM_HOLD(its:ite,jts:jte)  = CPM(its:ite,jts:jte)
     FLHC_HOLD(its:ite,jts:jte) = FLHC(its:ite,jts:jte)
     FLQC_HOLD(its:ite,jts:jte) = FLQC(its:ite,jts:jte)
     GZ1OZ0_HOLD(its:ite,jts:jte) = GZ1OZ0(its:ite,jts:jte)
     HFX_HOLD(its:ite,jts:jte)  = HFX(its:ite,jts:jte)
     LH_HOLD(its:ite,jts:jte)   = LH(its:ite,jts:jte)
     MOL_HOLD(its:ite,jts:jte)  = MOL(its:ite,jts:jte)
     PSIH_HOLD(its:ite,jts:jte) = PSIH(its:ite,jts:jte)
     PSIM_HOLD(its:ite,jts:jte) = PSIM(its:ite,jts:jte)
     QFX_HOLD(its:ite,jts:jte)  = QFX(its:ite,jts:jte)
     QGH_HOLD(its:ite,jts:jte)  = QGH(its:ite,jts:jte)
     RMOL_HOLD(its:ite,jts:jte) = RMOL(its:ite,jts:jte)
     UST_HOLD(its:ite,jts:jte)  = UST(its:ite,jts:jte)
     USTM_HOLD(its:ite,jts:jte) = USTM(its:ite,jts:jte)
     WSPD_HOLD(its:ite,jts:jte) = WSPD(its:ite,jts:jte)
     ZNT_HOLD(its:ite,jts:jte)  = ZNT(its:ite,jts:jte)
     ZOL_HOLD(its:ite,jts:jte)  = ZOL(its:ite,jts:jte)

     ! We'll want to save the ouput
     ! for weighting after the second call to SFCLAY.

     ! land/frozen-water call
     CALL SFCLAY_mynn(U3D,V3D,T3D,QV3D,P3D,dz8w,th3d,rho,     &
          CP,G,ROVCP,R,XLV,PSFC,CHS,CHS2,CQS2,CPM,            &
          ZNT,UST,PBLH,MAVAIL,ZOL,MOL,REGIME,PSIM,PSIH,       &
          XLAND,HFX,QFX,LH,TSK_LOCAL,FLHC,FLQC,QGH,QSFC,RMOL, &
          U10,V10,TH2,T2,Q2,SNOWH,                            &
          GZ1OZ0,WSPD,BR,ISFFLX,DX,                           &
          SVP1,SVP2,SVP3,SVPT0,EP1,EP2,KARMAN,                &
          itimestep,ch,qcg,                                   &
          spp_pbl,pattern_spp_pbl,                            &
          ids,ide, jds,jde, kds,kde,                          &
          ims,ime, jms,jme, kms,kme,                          &
          its,ite, jts,jte, kts,kte,                          &
          ustm,ck,cka,cd,cda,isftcflx,iz0tlnd                 )

     ! Set up lower boundary conditions to force an open-water call
      DO j = JTS , JTE
        DO i = ITS , ITE
           IF ( ( XICE(i,j) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN
              XLAND_SEA(i,j) = 2. !water
              MAVAIL_SEA(i,j)= 1.
              ZNT_SEA(i,j)   = 0.0001 !will be recalculated anyway
              TSK_SEA(i,j)   = SST(i,j)
              IF ( SST(i,j) .LT. 271.4 ) THEN
                 SST(i,j)    = 271.4
                 TSK_SEA(i,j)= SST(i,j)
              ENDIF
              QSFC_SEA(i,j)  = QSFC(i,j) !will be recalculated anyway
           ELSE
              !keep original values
              XLAND_SEA(i,j) = XLAND(i,j)
              MAVAIL_SEA(i,j)= MAVAIL(i,j)
              ZNT_SEA(i,j)   = ZNT_HOLD(i,j)
              TSK_SEA(i,j)   = TSK_LOCAL(i,j)
              QSFC_SEA(i,j)  = QSFC(i,j)
           ENDIF
        ENDDO
     ENDDO

     ! Restore the values from before the land/frozen-water call
     BR_SEA(its:ite,jts:jte)   = BR_HOLD(its:ite,jts:jte)
     CPM_SEA(its:ite,jts:jte)  = CPM_HOLD(its:ite,jts:jte)
     FLHC_SEA(its:ite,jts:jte) = FLHC_HOLD(its:ite,jts:jte)
     FLQC_SEA(its:ite,jts:jte) = FLQC_HOLD(its:ite,jts:jte)
     GZ1OZ0_SEA(its:ite,jts:jte) = GZ1OZ0_HOLD(its:ite,jts:jte)
     HFX_SEA(its:ite,jts:jte)  = HFX_HOLD(its:ite,jts:jte)
     LH_SEA(its:ite,jts:jte)   = LH_HOLD(its:ite,jts:jte)
     MOL_SEA(its:ite,jts:jte)  = MOL_HOLD(its:ite,jts:jte)
     PSIH_SEA(its:ite,jts:jte) = PSIH_HOLD(its:ite,jts:jte)
     PSIM_SEA(its:ite,jts:jte) = PSIM_HOLD(its:ite,jts:jte)
     QFX_SEA(its:ite,jts:jte)  = QFX_HOLD(its:ite,jts:jte)
     QGH_SEA(its:ite,jts:jte)  = QGH_HOLD(its:ite,jts:jte)
     RMOL_SEA(its:ite,jts:jte) = RMOL_HOLD(its:ite,jts:jte)
     UST_SEA(its:ite,jts:jte)  = UST_HOLD(its:ite,jts:jte)
     USTM_SEA(its:ite,jts:jte) = USTM_HOLD(its:ite,jts:jte)
     WSPD_SEA(its:ite,jts:jte) = WSPD_HOLD(its:ite,jts:jte)
     ZOL_SEA(its:ite,jts:jte)  = ZOL_HOLD(its:ite,jts:jte)


     ! open-water call
          CALL SFCLAY_mynn(U3D,V3D,T3D,QV3D,P3D,dz8w,th3d,rho,     &
               CP,G,ROVCP,R,XLV,PSFC,                              &
               CHS_SEA,CHS2_SEA,CQS2_SEA,CPM_SEA,                  &
               ZNT_SEA,UST_SEA,                                    &
               PBLH,MAVAIL_SEA,                                    &
               ZOL_SEA,MOL_SEA,REGIME,PSIM_SEA,PSIH_SEA,           &
               XLAND_SEA,                                          &
               HFX_SEA,QFX_SEA,LH_SEA,                             &
               TSK_SEA,                                            &
               FLHC_SEA,FLQC_SEA,QGH_SEA,QSFC_SEA,RMOL_SEA,        &
               U10_SEA,V10_SEA,TH2_SEA,T2_SEA,Q2_SEA,SNOWH,        &
               GZ1OZ0_SEA,WSPD_SEA,BR_SEA,                         &
               ISFFLX,DX,                                          &
               SVP1,SVP2,SVP3,SVPT0,EP1,EP2,KARMAN,                &
               itimestep,CH_SEA,qcg,                               &
               spp_pbl,pattern_spp_pbl,                            &
               ids,ide, jds,jde, kds,kde,                          &
               ims,ime, jms,jme, kms,kme,                          &
               its,ite, jts,jte, kts,kte,                          &
               ustm_sea,ck_sea,cka_sea,cd_sea,cda_sea,isftcflx,    &
               iz0tlnd                                             )

     DO j = JTS , JTE
        DO i = ITS, ITE
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD )  .and.( XICE(i,j) .LE. 1.0 ) ) THEN
              ! weighted average for sea ice points
              br(i,j)     = br(i,j)     * XICE(i,j) + (1.0-XICE(i,j)) * br_sea(i,j)
              ! CHS2 -- wait
              ! CHS  -- wait
              ! CPM  -- wait
              ! CQS2 -- wait
              !FLHC(i,j)   = FLHC(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * FLHC_SEA (i,j)
              !FLQC(i,j)   = FLQC(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * FLQC_SEA (i,j)
              gz1oz0(i,j) = gz1oz0(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * gz1oz0_sea(i,j)
              ! HFX  -- wait
              ! LH   -- wait
              mol(i,j)    = mol(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * mol_sea(i,j)
              psih(i,j)   = psih(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * psih_sea(i,j)
              psim(i,j)   = psim(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * psim_sea(i,j)
              ! QFX  -- wait
              ! QGH  -- wait
              rmol(i,j)   = rmol(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * rmol_sea(i,j)
              ust(i,j)    = ust(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * ust_sea(i,j)
              wspd(i,j)   = wspd(i,j)   * XICE(i,j) + (1.0-XICE(i,j)) * wspd_sea(i,j)
              zol(i,j)    = zol(i,j)    * XICE(i,j) + (1.0-XICE(i,j)) * zol_sea(i,j)
              ch(i,j)     = ch(i,j)     * XICE(i,j) + (1.0-XICE(i,j)) * ch_sea(i,j)
              ! INTENT(OUT)
              ! --------------------------------------------------------------------
              IF ( PRESENT ( CD ) ) THEN
                 CD(i,j)  = CD(i,j)  * XICE(i,j) + (1.0-XICE(i,j)) * CD_sea(i,j)
              ENDIF
              IF ( PRESENT ( CDA ) ) THEN
                 CDA(i,j) = CDA(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * CDA_sea(i,j)
              ENDIF
              IF ( PRESENT ( CK ) ) THEN
                 CK(i,j)  = CK(i,j)  * XICE(i,j) + (1.0-XICE(i,j)) * CK_sea(i,j)
              ENDIF
              IF ( PRESENT ( CKA ) ) THEN
                 CKA(i,j) = CKA(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * CKA_sea(i,j)
              ENDIF
              q2(i,j)     = q2(i,j)  * XICE(i,j) + (1.0-XICE(i,j)) * q2_sea(i,j)
              ! QSFC -- wait
              t2(i,j)     = t2(i,j)  * XICE(i,j) + (1.0-XICE(i,j)) * t2_sea(i,j)
              th2(i,j)    = th2(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * th2_sea(i,j)
              u10(i,j)    = u10(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * u10_sea(i,j)
              IF ( PRESENT ( USTM ) ) THEN
                 USTM(i,j)= USTM(i,j)* XICE(i,j) + (1.0-XICE(i,j)) * USTM_sea(i,j)
              ENDIF
              v10(i,j)    = v10(i,j) * XICE(i,j) + (1.0-XICE(i,j)) * v10_sea(i,j)
           ENDIF
        END DO
      END DO


   END SUBROUTINE mynn_seaice_wrapper

!-------------------------------------------------------------------------

   SUBROUTINE sf_gfs_seaice_wrapper(U3D,V3D,T3D,QV3D,P3D,        &
		 CP,ROVCP,R,XLV,PSFC,CHS,CHS2,CQS2,CPM,          &
                     ZNT,UST,PSIM,PSIH,                          &
                     XLAND,HFX,QFX,LH,TSK,FLHC,FLQC,             &
                     QGH,QSFC,U10,V10,                           &
                     GZ1OZ0,WSPD,BR,ISFFLX,                      &
                     EP1,EP2,KARMAN,itimestep,                   &
                     TICE2TSK_IF2COLD,                           &
                     XICE_THRESHOLD,                             &
                     CHS_SEA, CHS2_SEA, CPM_SEA, CQS2_SEA,       &
                     FLHC_SEA, FLQC_SEA,                         &
                     HFX_SEA, LH_SEA, QFX_SEA, QGH_SEA, QSFC_SEA,&
                     UST_SEA, ZNT_SEA, SST, XICE,                &
                     ids,ide, jds,jde, kds,kde,                  &
                     ims,ime, jms,jme, kms,kme,                  &
                     its,ite, jts,jte, kts,kte                   )
     USE module_sf_gfs
     implicit none

     INTEGER, INTENT(IN) ::             ids,ide, jds,jde, kds,kde,      &
                                        ims,ime, jms,jme, kms,kme,      &
                                        its,ite, jts,jte, kts,kte,      &
                                        ISFFLX,itimestep

      REAL,    INTENT(IN) ::                                            &
                                        CP,                             &
                                        EP1,                            &
                                        EP2,                            &
                                        KARMAN,                         &
                                        R,                              &
                                        ROVCP,                          &
                                        XLV

      REAL,    DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(IN) ::      &
                                        P3D,                            &
                                        QV3D,                           &
                                        T3D,                            &
                                        U3D,                            &
                                        V3D

      REAL,    DIMENSION(ims:ime, jms:jme), INTENT(IN) ::               &
                                        TSK,                            &
                                        PSFC,                           &
                                        XLAND

      REAL,    DIMENSION(ims:ime, jms:jme), INTENT(INOUT) ::            &
                                        UST,                            &
                                        ZNT

      REAL, DIMENSION(ims:ime, jms:jme), INTENT(OUT) ::                 &
                                        BR,                             &
                                        CHS,                            &
                                        CHS2,                           &
                                        CPM,                            &
                                        CQS2,                           &
                                        FLHC,                           &
                                        FLQC,                           &
                                        GZ1OZ0,                         &
                                        HFX,                            &
                                        LH,                             &
                                        PSIM,                           &
                                        PSIH,                           &
                                        QFX,                            &
                                        QGH,                            &
                                        QSFC,                           &
                                        U10,                            &
                                        V10,                            &
                                        WSPD

      REAL, DIMENSION(ims:ime, jms:jme), INTENT(IN) ::                  &
                                        XICE
      REAL, DIMENSION(ims:ime, jms:jme), INTENT(OUT) ::                 &
                                        CHS_SEA,                        &
                                        CHS2_SEA,                       &
                                        CPM_SEA,                        &
                                        CQS2_SEA,                       &
                                        FLHC_SEA,                       &
                                        FLQC_SEA,                       &
                                        HFX_SEA,                        &
                                        LH_SEA,                         &
                                        QFX_SEA,                        &
                                        QGH_SEA,                        &
                                        QSFC_SEA,                       &
                                        UST_SEA,                        &
                                        ZNT_SEA
      REAL, DIMENSION(ims:ime, jms:jme), INTENT(INOUT) ::               &
                                        SST

      REAL,                              INTENT(IN)    ::               &
                                        XICE_THRESHOLD
      LOGICAL,                          INTENT(IN)     :: TICE2TSK_IF2COLD

!-------------------------------------------------------------------------
!   Local
!-------------------------------------------------------------------------
      INTEGER :: I
      INTEGER :: J
      REAL, DIMENSION(ims:ime, jms:jme) ::                              &
                                        BR_SEA,                         &
                                        GZ1OZ0_SEA,                     &
                                        PSIM_SEA,                       &
                                        PSIH_SEA,                       &
                                        U10_SEA,                        &
                                        V10_SEA,                        &
                                        WSPD_SEA,                       &
                                        XLAND_SEA,                &
                                        TSK_SEA,                        &
                                        UST_HOLD,                       &
                                        ZNT_HOLD,                       &
                                        TSK_LOCAL

      CALL get_local_ice_tsk( ims, ime, jms, jme, its, ite, jts, jte,  &
                              itimestep, .true., tice2tsk_if2cold,     &
                              XICE, XICE_THRESHOLD,                    &
                              SST, TSK, TSK_SEA, TSK_LOCAL )

!
! Set up for frozen ocean call for sea ice points
!

! Strictly INTENT(IN), Should be unchanged by SF_GFS:
!     CP
!     EP1
!     EP2
!     KARMAN
!     R
!     ROVCP
!     XLV
!     P3D
!     QV3D
!     T3D
!     U3D
!     V3D
!     TSK
!     PSFC
!     XLAND
!     ISFFLX
!     ITIMESTEP


! Intent (INOUT), original value is used and changed by SF_GFS.
!     UST
!     ZNT

     ZNT_HOLD = ZNT
     UST_HOLD = UST

! Strictly INTENT (OUT), set by SF_GFS:
!     BR
!     CHS     -- used by LSM routines
!     CHS2    -- used by LSM routines
!     CPM     -- used by LSM routines
!     CQS2    -- used by LSM routines
!     FLHC
!     FLQC
!     GZ1OZ0
!     HFX     -- used by LSM routines
!     LH      -- used by LSM routines
!     PSIM
!     PSIH
!     QFX     -- used by LSM routines
!     QGH     -- used by LSM routines
!     QSFC    -- used by LSM routines
!     U10
!     V10
!     WSPD

!
! Frozen ocean / true land call.
!
     CALL SF_GFS(U3D,V3D,T3D,QV3D,P3D,                  &
          CP,ROVCP,R,XLV,PSFC,CHS,CHS2,CQS2,CPM_SEA,    &
          ZNT,UST,PSIM,PSIH,                            &
          XLAND,HFX,QFX,LH,TSK_LOCAL,FLHC,FLQC,         &
          QGH,QSFC,U10,V10,                             &
          GZ1OZ0,WSPD,BR,ISFFLX,                        &
          EP1,EP2,KARMAN,ITIMESTEP,                     &
          ids,ide, jds,jde, kds,kde,                    &
          ims,ime, jms,jme, kms,kme,                    &
          its,ite, jts,jte, kts,kte                     )

! Set up for open-water call

     DO j = JTS , JTE
        DO i = ITS , ITE
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN
              ! Sets up things for open ocean fraction of sea-ice points
              XLAND_SEA(i,j)=2.
              ZNT_SEA(I,J) = 0.0001
              IF ( SST(i,j) .LT. 271.4 ) THEN
                 SST(i,j) = 271.4
              ENDIF
              TSK_SEA(i,j) = SST(i,j)
           ELSE
              ! Fully open ocean or true land points
              XLAND_SEA(i,j)=xland(i,j)
              ZNT_SEA(I,J) = ZNT_HOLD(I,J)
              UST_SEA(i,j) = UST_HOLD(i,j)
              TSK_SEA(i,j) = TSK(i,j)
           ENDIF
        ENDDO
     ENDDO

     ! Open-water call
     ! _SEA variables are held for later use as the result of the open-water call.
     CALL SF_GFS(U3D,V3D,T3D,QV3D,P3D,                  &
          CP,ROVCP,R,XLV,PSFC,CHS_SEA,CHS2_SEA,CQS2_SEA,CPM,        &
          ZNT_SEA,UST_SEA,PSIM_SEA,PSIH_SEA,                        &
          XLAND,HFX_SEA,QFX_SEA,LH_SEA,TSK_SEA,FLHC_SEA,FLQC_SEA,   &
          QGH_SEA,QSFC_SEA,U10_SEA,V10_SEA,                         &
          GZ1OZ0_SEA,WSPD_SEA,BR_SEA,ISFFLX,                        &
          EP1,EP2,KARMAN,ITIMESTEP,                     &
          ids,ide, jds,jde, kds,kde,                    &
          ims,ime, jms,jme, kms,kme,                    &
          its,ite, jts,jte, kts,kte                     )

! Weighting, after our two calls to SF_GFS

     DO j = JTS , JTE
        DO i = ITS , ITE
           ! Over sea-ice points, weight the results.  Otherwise, just take the results from the
           ! first call to SF_GFS_
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN
              ! Weight a number of fields (between open-water results
              ! and full ice results) by sea-ice fraction.

              BR(i,j)     = ( BR(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * BR_SEA(i,j)     )
              ! CHS, used by the LSM routines, is not updated yet.  Return results from both calls in separate variables
              ! CHS2, used by the LSM routines, is not updated yet.  Return results from both calls in separate variables
              ! CPM, used by the LSM routines, is not updated yet.  Return results from both calls in separate variables
              ! CQS2, used by the LSM routines, is not updated yet.  Return results from both calls in separate variables
              ! FLHC(i,j) = ( FLHC(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * FLHC_SEA(i,j) )
              ! FLQC(i,j) = ( FLQC(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * FLQC_SEA(i,j) )
              GZ1OZ0(i,j) = ( GZ1OZ0(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * GZ1OZ0_SEA(i,j) )
              ! HFX, used by the LSM routines, is not updated yet.  Return results from both calls in separate variables
              ! LH, used by the LSM routines, is not updated yet.  Return results from both calls in separate variables
              PSIM(i,j)   = ( PSIM(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * PSIM_SEA(i,j)   )
              PSIH(i,j)   = ( PSIH(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * PSIH_SEA(i,j)   )
              ! QFX, used by the LSM routines, is not updated yet.  Return results from both calls in separate variables
              ! QGH, used by the LSM routines, is not updated yet.  Return results from both calls in separate variables
              ! QSFC, used by the LSM routines, is not updated yet.  Return results from both calls in separate variables
              U10(i,j)    = ( U10(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * U10_SEA(i,j)    )
              V10(i,j)    = ( V10(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * V10_SEA(i,j)    )
              WSPD(i,j)   = ( WSPD(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * WSPD_SEA(i,j)   )
              ! UST, used by the LSM routines, is not updated yet.  Return results from both calls in separate variables
              ! ZNT, used by the LSM routines, is not updated yet.  Return results from both calls in separate variables

           ENDIF
        ENDDO
     ENDDO

   END SUBROUTINE sf_gfs_seaice_wrapper

!-------------------------------------------------------------------------

!-------------------------------------------------------------------------

   SUBROUTINE sfclayrev_seaice_wrapper(U3D,V3D,T3D,QV3D,P3D,dz8w,     &
                     CP,G,ROVCP,R,XLV,PSFC,CHS,CHS2,CQS2,CPM,      &
                     ZNT,UST,PBLH,MAVAIL,ZOL,MOL,REGIME,PSIM,PSIH, &
                     FM,FH,                                        &
                     XLAND,HFX,QFX,LH,TSK,FLHC,FLQC,QGH,QSFC,RMOL, &
                     U10,V10,TH2,T2,Q2,                            &
                     GZ1OZ0,WSPD,BR,ISFFLX,DX2D,                   &
                     SVP1,SVP2,SVP3,SVPT0,EP1,EP2,                 &
                     KARMAN,                                       &
                     P1000,LAKEMASK,                               &
                     XICE,SST,TSK_SEA,                                                  &
                     CHS2_SEA,CHS_SEA,CPM_SEA,CQS2_SEA,FLHC_SEA,FLQC_SEA,               &
                     HFX_SEA,LH_SEA,QFX_SEA,QGH_SEA,QSFC_SEA,ZNT_SEA,                   &
                     ITIMESTEP,TICE2TSK_IF2COLD,XICE_THRESHOLD,                         &
                     ids,ide, jds,jde, kds,kde,                    &
                     ims,ime, jms,jme, kms,kme,                    &
                     its,ite, jts,jte, kts,kte,                    &
                     ustm,ck,cka,cd,cda,isftcflx,iz0tlnd,          &
                     shalwater_z0,water_depth,                     & 
                     scm_force_flux,sf_surface_physics,errmsg,errflg)

     USE module_sf_sfclayrev
     implicit none

     INTEGER,  INTENT(IN )   ::        ids,ide, jds,jde, kds,kde,  &
                                       ims,ime, jms,jme, kms,kme,  &
                                       its,ite, jts,jte, kts,kte

     INTEGER,  INTENT(IN )   ::        ISFFLX
     REAL,     INTENT(IN )   ::        SVP1,SVP2,SVP3,SVPT0
     REAL,     INTENT(IN )   ::        EP1,EP2,KARMAN
     REAL,     INTENT(IN )   ::        P1000

     REAL,     DIMENSION( ims:ime, kms:kme, jms:jme )           , &
               INTENT(IN   )   ::                           dz8w

     REAL,     DIMENSION( ims:ime, kms:kme, jms:jme )           , &
               INTENT(IN   )   ::                           QV3D, &
                                                             P3D, &
                                                             T3D

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(IN   )               ::             MAVAIL, &
                                                            PBLH, &
                                                           XLAND, &
                                                        LAKEMASK, &
                                                             TSK
     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(OUT  )               ::                U10, &
                                                             V10, &
                                                             TH2, &
                                                              T2, &
                                                              Q2, &
                                                            QSFC
     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)               ::             REGIME, &
                                                             HFX, &
                                                             QFX, &
                                                              LH, &
                                                         MOL,RMOL

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                 GZ1OZ0,WSPD,BR, &
                                                 PSIM,PSIH,FM,FH

     REAL,     DIMENSION( ims:ime, kms:kme, jms:jme )           , &
               INTENT(IN   )   ::                            U3D, &
                                                             V3D

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(IN   )               ::               PSFC, &
                                                            DX2D

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                            ZNT, &
                                                             ZOL, &
                                                             UST, &
                                                             CPM, &
                                                            CHS2, &
                                                            CQS2, &
                                                             CHS

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                      FLHC,FLQC

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                                 &
                                                              QGH

     REAL,     INTENT(IN   )               ::   CP,G,ROVCP,R,XLV

     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme )              , &
               INTENT(OUT)     ::                   ck,cka,cd,cda
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme )              , &
               INTENT(INOUT)   ::                            ustm

     INTEGER,  OPTIONAL,  INTENT(IN )   ::     ISFTCFLX,IZ0TLND
     INTEGER,  INTENT(IN )   ::     shalwater_z0 
     REAL,     DIMENSION( ims:ime, jms:jme ) , INTENT(IN ) :: water_depth 
     INTEGER,  OPTIONAL,  INTENT(IN )   ::     SCM_FORCE_FLUX

!--------------------------------------------------------------------
!    New for wrapper
!--------------------------------------------------------------------
     INTEGER,  INTENT(IN)          ::    ITIMESTEP, sf_surface_physics
     LOGICAL,  INTENT(IN)               ::      TICE2TSK_IF2COLD
     REAL,     INTENT(IN)               ::      XICE_THRESHOLD
     REAL,     DIMENSION( ims:ime, jms:jme ),                     &
               INTENT(IN)               ::      XICE
     REAL,     DIMENSION( ims:ime, jms:jme ),                     &
               INTENT(INOUT)            ::      SST
     REAL,     DIMENSION( ims:ime, jms:jme ),                     &
               INTENT(OUT)              ::      TSK_SEA,          &
                                                CHS2_SEA,         &
                                                CHS_SEA,          &
                                                CPM_SEA,          &
                                                CQS2_SEA,         &
                                                FLHC_SEA,         &
                                                FLQC_SEA,         &
                                                HFX_SEA,          &
                                                LH_SEA,           &
                                                QFX_SEA,          &
                                                QGH_SEA,          &
                                                QSFC_SEA,         &
                                                ZNT_SEA

!--------------------------------------------------------------------
!    Local
!--------------------------------------------------------------------
     INTEGER :: I, J
     REAL,     DIMENSION( ims:ime, jms:jme ) :: XLAND_SEA,        &
                                                MAVAIL_sea,       &
                                                TSK_LOCAL,        &
                                                BR_HOLD,          &
                                                CHS2_HOLD,        &
                                                CHS_HOLD,         &
                                                CPM_HOLD,         &
                                                CQS2_HOLD,        &
                                                FLHC_HOLD,        &
                                                FLQC_HOLD,        &
                                                GZ1OZ0_HOLD,      &
                                                HFX_HOLD,         &
                                                LH_HOLD,          &
                                                MOL_HOLD,         &
                                                PSIH_HOLD,        &
                                                PSIM_HOLD,        &
                                                FH_HOLD,          &
                                                FM_HOLD,          &
                                                QFX_HOLD,         &
                                                QGH_HOLD,         &
                                                REGIME_HOLD,      &
                                                RMOL_HOLD,        &
                                                UST_HOLD,         &
                                                WSPD_HOLD,        &
                                                ZNT_HOLD,         &
                                                ZOL_HOLD,         &
                                                QSFC_HOLD,        &
                                                TH2_HOLD,         & !ssib
                                                T2_HOLD,          & !ssib
                                                Q2_HOLD,          & !ssib
                                                TSK_HOLD,         & !ssib
                                                U10_HOLD,         & !ssib
                                                V10_HOLD,         & !ssib
                                                CD_SEA,           &
                                                CDA_SEA,          &
                                                CK_SEA,           &
                                                CKA_SEA,          &
                                                Q2_SEA,           &
                                                T2_SEA,           &
                                                TH2_SEA,          &
                                                U10_SEA,          &
                                                USTM_SEA,         &
                                                V10_SEA

     REAL,     DIMENSION( ims:ime, jms:jme ) ::                   &
                                                BR_SEA,           &
                                                GZ1OZ0_SEA,       &
                                                MOL_SEA,          &
                                                PSIH_SEA,         &
                                                PSIM_SEA,         &
                                                FH_SEA,           &
                                                FM_SEA,           &
                                                REGIME_SEA,       &
                                                RMOL_SEA,         &
                                                UST_SEA,          &
                                                WSPD_SEA,         &
                                                ZOL_SEA

! To accommodate shared physics
   character*256 :: errmsg
   integer :: errflg

! INTENT(IN) to SFCLAY; unchanged by the call
      ! ISFFLX
      ! SVP1,SVP2,SVP3,SVPT0
      ! EP1,EP2,KARMAN
      ! CP,G,ROVCP,R,XLV,DX2D
      ! ISFTCFLX,IZ0TLND
      ! P1000
      ! dz8w
      ! QV3D
      ! P3D
      ! T3D
      ! MAVAIL
      ! PBLH
      ! XLAND
      ! TSK
      ! U3D
      ! V3D
      ! PSFC

     CALL get_local_ice_tsk( ims, ime, jms, jme, its, ite, jts, jte,  &
                             itimestep, .true., tice2tsk_if2cold,     &
                             XICE, XICE_THRESHOLD,                    &
                             SST, TSK, TSK_SEA, TSK_LOCAL )


! INTENT (INOUT) to SFCLAY:  Save the variables before the first call
! (for land/frozen water) to SFCLAY, to keep from double-counting the
     BR_HOLD(its:ite,jts:jte)     = BR(its:ite,jts:jte)
     CHS2_HOLD(its:ite,jts:jte)   = CHS2(its:ite,jts:jte)
     CHS_HOLD(its:ite,jts:jte)    = CHS(its:ite,jts:jte)
     CPM_HOLD(its:ite,jts:jte)    = CPM(its:ite,jts:jte)
     CQS2_HOLD(its:ite,jts:jte)   = CQS2(its:ite,jts:jte)
     FLHC_HOLD(its:ite,jts:jte)   = FLHC(its:ite,jts:jte)
     FLQC_HOLD(its:ite,jts:jte)   = FLQC(its:ite,jts:jte)
     GZ1OZ0_HOLD(its:ite,jts:jte) = GZ1OZ0(its:ite,jts:jte)
     HFX_HOLD(its:ite,jts:jte)    = HFX(its:ite,jts:jte)
     LH_HOLD(its:ite,jts:jte)     = LH(its:ite,jts:jte)
     MOL_HOLD(its:ite,jts:jte)    = MOL(its:ite,jts:jte)
     PSIH_HOLD(its:ite,jts:jte)   = PSIH(its:ite,jts:jte)
     PSIM_HOLD(its:ite,jts:jte)   = PSIM(its:ite,jts:jte)
     FH_HOLD(its:ite,jts:jte)     = FH(its:ite,jts:jte)
     FM_HOLD(its:ite,jts:jte)     = FM(its:ite,jts:jte)
     QFX_HOLD(its:ite,jts:jte)    = QFX(its:ite,jts:jte)
     QGH_HOLD(its:ite,jts:jte)    = QGH(its:ite,jts:jte)
     REGIME_HOLD(its:ite,jts:jte) = REGIME(its:ite,jts:jte)
     RMOL_HOLD(its:ite,jts:jte)   = RMOL(its:ite,jts:jte)
     UST_HOLD(its:ite,jts:jte)    = UST(its:ite,jts:jte)
     WSPD_HOLD(its:ite,jts:jte)   = WSPD(its:ite,jts:jte)
     ZNT_HOLD(its:ite,jts:jte)    = ZNT(its:ite,jts:jte)
     ZOL_HOLD(its:ite,jts:jte)    = ZOL(its:ite,jts:jte)
     QSFC_HOLD(its:ite,jts:jte)   = QSFC(its:ite,jts:jte)
!also save these variables for SSIB (fds 12/2010)
     TH2_HOLD(its:ite,jts:jte)    = TH2(its:ite,jts:jte)
     T2_HOLD(its:ite,jts:jte)     = T2(its:ite,jts:jte)
     Q2_HOLD(its:ite,jts:jte)     = Q2(its:ite,jts:jte)
     TSK_HOLD(its:ite,jts:jte)    = TSK(its:ite,jts:jte)
     U10_HOLD(its:ite,jts:jte)    = U10(its:ite,jts:jte) !fds (01/2014)
     V10_HOLD(its:ite,jts:jte)    = V10(its:ite,jts:jte) !fds (01/2014)
     
! INTENT(OUT) from SFCLAY.  Input shouldn't matter, but we'll want to
! keep things around for weighting after the second call to SFCLAY.
     ! CD
     ! CDA
     ! CK
     ! CKA
     ! Q2
     ! QSFC
     ! T2
     ! TH2
     ! U10
     ! USTM
     ! V10


     ! land/frozen-water call
     call sfclayrev(U3D,V3D,T3D,QV3D,P3D,dz8w,                    & ! I
                 CP,G,ROVCP,R,XLV,PSFC,CHS,CHS2,CQS2,CPM,      & ! I,I,I,I,I,I,IO,IO,IO,IO,
                 ZNT,UST,PBLH,MAVAIL,ZOL,MOL,REGIME,PSIM,PSIH, &
                 FM,FH,                                        &
                 XLAND,HFX,QFX,LH,TSK_LOCAL,FLHC,FLQC,QGH,QSFC,RMOL, &
                 U10,V10,TH2,T2,Q2,                            &
                 GZ1OZ0,WSPD,BR,ISFFLX,DX2D,                   &
                 SVP1,SVP2,SVP3,SVPT0,EP1,EP2,                 &
                 KARMAN,                                       &
                 P1000,lakemask,                               &
                 ids,ide, jds,jde, kds,kde,                    &
                 ims,ime, jms,jme, kms,kme,                    &
                 its,ite, jts,jte, kts,kte,                    &
                 ustm,ck,cka,cd,cda,isftcflx,iz0tlnd,          &
                 shalwater_z0,water_depth,                     & 
                 scm_force_flux,errmsg,errflg                  )
!
!Restore land-point values calculated by SSiB (fds 12/2010)
     IF (itimestep .gt. 1 .and. sf_surface_physics .EQ. 8) then
     DO j = JTS , JTE
        DO i = ITS, ITE
           IF ( XLAND(I,J) .LT. 1.5 ) THEN
              BR(I,J) = BR_HOLD(I,J)
              TH2(I,J) = TH2_HOLD(I,J)
              T2(I,J) = T2_HOLD(I,J)
              Q2(I,J) = Q2_HOLD(I,J)
              HFX(I,J) = HFX_HOLD(I,J)
              QFX(I,J) = QFX_HOLD(I,J)
              LH(I,J) = LH_HOLD(I,J)
              GZ1OZ0(I,J) = GZ1OZ0_HOLD(I,J)
              WSPD(I,J) = WSPD_HOLD(I,J)
              ZNT(I,J) = ZNT_HOLD(I,J)
              UST(I,J) = UST_HOLD(I,J)
!             TSK(I,J) = TSK_HOLD(I,J)
           ENDIF
        ENDDO
     ENDDO
     ENDIF
!
     ! Set up for open-water call
     DO j = JTS , JTE
        DO i = ITS , ITE
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN
              XLAND_SEA(i,j)=2.
              MAVAIL_SEA(I,J)  =1.
              ZNT_SEA(I,J) = 0.0001
              TSK_SEA(i,j) = SST(i,j)
              IF ( SST(i,j) .LT. 271.4 ) THEN
                 SST(i,j) = 271.4
                 TSK_SEA(i,j) = SST(i,j)
              ENDIF
           ELSE
              XLAND_SEA(i,j) = XLAND(i,j)
              MAVAIL_SEA(i,j) = MAVAIL(i,j)
              ZNT_SEA(i,j)  = ZNT_HOLD(i,j)
              TSK_SEA(i,j) = TSK_LOCAL(i,j)
           ENDIF
        ENDDO
     ENDDO

     ! Restore the values from before the land/frozen-water call
     BR_SEA(its:ite,jts:jte)     = BR_HOLD(its:ite,jts:jte)
     CHS2_SEA(its:ite,jts:jte)   = CHS2_HOLD(its:ite,jts:jte)
     CHS_SEA(its:ite,jts:jte)    = CHS_HOLD(its:ite,jts:jte)
     CPM_SEA(its:ite,jts:jte)    = CPM_HOLD(its:ite,jts:jte)
     CQS2_SEA(its:ite,jts:jte)   = CQS2_HOLD(its:ite,jts:jte)
     FLHC_SEA(its:ite,jts:jte)   = FLHC_HOLD(its:ite,jts:jte)
     FLQC_SEA(its:ite,jts:jte)   = FLQC_HOLD(its:ite,jts:jte)
     GZ1OZ0_SEA(its:ite,jts:jte) = GZ1OZ0_HOLD(its:ite,jts:jte)
     HFX_SEA(its:ite,jts:jte)    = HFX_HOLD(its:ite,jts:jte)
     LH_SEA(its:ite,jts:jte)     = LH_HOLD(its:ite,jts:jte)
     MOL_SEA(its:ite,jts:jte)    = MOL_HOLD(its:ite,jts:jte)
     PSIH_SEA(its:ite,jts:jte)   = PSIH_HOLD(its:ite,jts:jte)
     PSIM_SEA(its:ite,jts:jte)   = PSIM_HOLD(its:ite,jts:jte)
     FH_SEA(its:ite,jts:jte)     = FH_HOLD(its:ite,jts:jte)
     FM_SEA(its:ite,jts:jte)     = FM_HOLD(its:ite,jts:jte)
     QFX_SEA(its:ite,jts:jte)    = QFX_HOLD(its:ite,jts:jte)
     QGH_SEA(its:ite,jts:jte)    = QGH_HOLD(its:ite,jts:jte)
     REGIME_SEA(its:ite,jts:jte) = REGIME_HOLD(its:ite,jts:jte)
     RMOL_SEA(its:ite,jts:jte)   = RMOL_HOLD(its:ite,jts:jte)
     UST_SEA(its:ite,jts:jte)    = UST_HOLD(its:ite,jts:jte)
     WSPD_SEA(its:ite,jts:jte)   = WSPD_HOLD(its:ite,jts:jte)
     ZOL_SEA(its:ite,jts:jte)    = ZOL_HOLD(its:ite,jts:jte)
     ZNT_SEA(its:ite,jts:jte)    = ZNT_HOLD(its:ite,jts:jte)
     QSFC_SEA(its:ite,jts:jte)   = QSFC_HOLD(its:ite,jts:jte)
!
     ! open-water call
     call sfclayrev(U3D,V3D,T3D,QV3D,P3D,dz8w,                    & ! I
                 CP,G,ROVCP,R,XLV,PSFC,                        & ! I
                 CHS_SEA,CHS2_SEA,CQS2_SEA,CPM_SEA,            & ! I/O
                 ZNT_SEA,UST_SEA,                              & ! I/O
                 PBLH,MAVAIL_SEA,                              & ! I
                 ZOL_SEA,MOL_SEA,REGIME_SEA,PSIM_SEA,PSIH_SEA, & ! I/O
                 FM_SEA,FH_SEA,                                &
                 XLAND_SEA,                              & ! I
                 HFX_SEA,QFX_SEA,LH_SEA,                       & ! I/O
                 TSK_SEA,                                      & ! I
                 FLHC_SEA,FLQC_SEA,QGH_SEA,QSFC_sea,RMOL_SEA,  & ! I/O
                 U10_sea,V10_sea,TH2_sea,T2_sea,Q2_sea,        & ! O
                 GZ1OZ0_SEA,WSPD_SEA,BR_SEA,                   & ! I/O
                 ISFFLX,DX2D,                                  &
                 SVP1,SVP2,SVP3,SVPT0,EP1,EP2,                 &
                 KARMAN,                                       &
                 P1000,lakemask,                               &
                 ids,ide, jds,jde, kds,kde,                    &
                 ims,ime, jms,jme, kms,kme,                    &
                 its,ite, jts,jte, kts,kte,                    & ! 0
                 ustm_sea,ck_sea,cka_sea,cd_sea,cda_sea,isftcflx,iz0tlnd,&
                 shalwater_z0,water_depth,                     & 
                 scm_force_flux,errmsg,errflg                  ) 
!
     DO j = JTS , JTE
        DO i = ITS, ITE
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD )  .and.( XICE(i,j) .LE. 1.0 ) ) THEN
              ! weighted average for sea ice points
              br(i,j)     = ( br(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * br_sea(i,j)     )
              ! CHS2 -- wait
              ! CHS  -- wait
              ! CPM  -- wait
              ! CQS2 -- wait
              ! FLHC -- wait
              ! FLQC -- wait
              gz1oz0(i,j) = ( gz1oz0(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * gz1oz0_sea(i,j) )
              ! HFX  -- wait
              ! LH   -- wait
              mol(i,j)    = ( mol(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * mol_sea(i,j)    )
              psih(i,j)   = ( psih(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * psih_sea(i,j)   )
              psim(i,j)   = ( psim(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * psim_sea(i,j)   )
              fh(i,j)    = ( fh(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * fh_sea(i,j)   )
              fm(i,j)    = ( fm(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * fm_sea(i,j)   )
              ! QFX  -- wait
              ! QGH  -- wait
              if ( XICE(i,j).GE. 0.5 ) regime(i,j) = regime_hold(i,j)
              rmol(i,j)   = ( rmol(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * rmol_sea(i,j)   )
              ust(i,j)    = ( ust(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * ust_sea(i,j)    )
              wspd(i,j)   = ( wspd(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * wspd_sea(i,j)   )
              zol(i,j)    = ( zol(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * zol_sea(i,j)    )
              ! INTENT(OUT) --------------------------------------------------------------------
              IF ( PRESENT ( CD ) ) THEN
                 CD(i,j)     = ( CD(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * CD_sea(i,j)     )
              ENDIF
              IF ( PRESENT ( CDA ) ) THEN
                 CDA(i,j)     = ( CDA(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * CDA_sea(i,j)     )
              ENDIF
              IF ( PRESENT ( CK ) ) THEN
                 CK(i,j)     = ( CK(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * CK_sea(i,j)     )
              ENDIF
              IF ( PRESENT ( CKA ) ) THEN
                 CKA(i,j)     = ( CKA(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * CKA_sea(i,j)     )
              ENDIF
              q2(i,j)     = ( q2(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * q2_sea(i,j)     )
              ! QSFC -- wait
              t2(i,j)     = ( t2(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * t2_sea(i,j)     )
              th2(i,j)    = ( th2(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * th2_sea(i,j)    )
              u10(i,j)    = ( u10(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * u10_sea(i,j)    )
              IF ( PRESENT ( USTM ) ) THEN
                 USTM(i,j)    = ( USTM(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * USTM_sea(i,j)    )
              ENDIF
              v10(i,j)    = ( v10(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * v10_sea(i,j)    )
           ENDIF
        END DO
     END DO
!
!         tsk(i,j) = tsk(i,j)*XICE(i,j) + (1.0-XICE(i,j))*TSK_SEA(i,j)
!
   END SUBROUTINE sfclayrev_seaice_wrapper

!-------------------------------------------------------------------------

   SUBROUTINE sfclay_seaice_wrapper(U3D,V3D,T3D,QV3D,P3D,dz8w,     &
                     CP,G,ROVCP,R,XLV,PSFC,CHS,CHS2,CQS2,CPM,      &
                     ZNT,UST,PBLH,MAVAIL,ZOL,MOL,REGIME,PSIM,PSIH, &
                     FM,FH,                                        &
                     XLAND,HFX,QFX,LH,TSK,FLHC,FLQC,QGH,QSFC,RMOL, &
                     U10,V10,TH2,T2,Q2,                            &
                     GZ1OZ0,WSPD,BR,ISFFLX,DX,                     &
                     SVP1,SVP2,SVP3,SVPT0,EP1,EP2,                 &
                     KARMAN,EOMEG,STBOLT,                          &
                     P1000,lakemask,                               &
XICE,SST,TSK_SEA,                                                  &
CHS2_SEA,CHS_SEA,CPM_SEA,CQS2_SEA,FLHC_SEA,FLQC_SEA,               &
HFX_SEA,LH_SEA,QFX_SEA,QGH_SEA,QSFC_SEA,ZNT_SEA,                   &
ITIMESTEP,TICE2TSK_IF2COLD,XICE_THRESHOLD,                         &
                     ids,ide, jds,jde, kds,kde,                    &
                     ims,ime, jms,jme, kms,kme,                    &
                     its,ite, jts,jte, kts,kte,                    &
                     ustm,ck,cka,cd,cda,isftcflx,iz0tlnd,          &
                     scm_force_flux,sf_surface_physics             )

     USE module_sf_sfclay
     implicit none

     INTEGER,  INTENT(IN )   ::        ids,ide, jds,jde, kds,kde,  &
                                       ims,ime, jms,jme, kms,kme,  &
                                       its,ite, jts,jte, kts,kte

     INTEGER,  INTENT(IN )   ::        ISFFLX
     REAL,     INTENT(IN )   ::        SVP1,SVP2,SVP3,SVPT0
     REAL,     INTENT(IN )   ::        EP1,EP2,KARMAN,EOMEG,STBOLT
     REAL,     INTENT(IN )   ::        P1000

     REAL,     DIMENSION( ims:ime, kms:kme, jms:jme )           , &
               INTENT(IN   )   ::                           dz8w

     REAL,     DIMENSION( ims:ime, kms:kme, jms:jme )           , &
               INTENT(IN   )   ::                           QV3D, &
                                                             P3D, &
                                                             T3D

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(IN   )               ::             MAVAIL, &
                                                            PBLH, &
                                                           XLAND, &
                                                        LAKEMASK, &
                                                             TSK
     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(OUT  )               ::                U10, &
                                                             V10, &
                                                             TH2, &
                                                              T2, &
                                                              Q2, &
                                                            QSFC
     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)               ::             REGIME, &
                                                             HFX, &
                                                             QFX, &
                                                              LH, &
                                                         MOL,RMOL

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                 GZ1OZ0,WSPD,BR, &
                                                 PSIM,PSIH,FM,FH

     REAL,     DIMENSION( ims:ime, kms:kme, jms:jme )           , &
               INTENT(IN   )   ::                            U3D, &
                                                             V3D

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(IN   )               ::               PSFC

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                            ZNT, &
                                                             ZOL, &
                                                             UST, &
                                                             CPM, &
                                                            CHS2, &
                                                            CQS2, &
                                                             CHS

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                      FLHC,FLQC

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                                 &
                                                              QGH

     REAL,     INTENT(IN   )               ::   CP,G,ROVCP,R,XLV
     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(IN) ::   DX

     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme )              , &
               INTENT(OUT)     ::                   ck,cka,cd,cda
     REAL, OPTIONAL, DIMENSION( ims:ime, jms:jme )              , &
               INTENT(INOUT)   ::                            ustm

     INTEGER,  OPTIONAL,  INTENT(IN )   ::     ISFTCFLX,IZ0TLND
     INTEGER,  OPTIONAL,  INTENT(IN )   ::     SCM_FORCE_FLUX

!--------------------------------------------------------------------
!    New for wrapper
!--------------------------------------------------------------------
     INTEGER,  INTENT(IN)          ::    ITIMESTEP, sf_surface_physics
     LOGICAL,  INTENT(IN)               ::      TICE2TSK_IF2COLD
     REAL,     INTENT(IN)               ::      XICE_THRESHOLD
     REAL,     DIMENSION( ims:ime, jms:jme ),                     &
               INTENT(IN)               ::      XICE
     REAL,     DIMENSION( ims:ime, jms:jme ),                     &
               INTENT(INOUT)            ::      SST
     REAL,     DIMENSION( ims:ime, jms:jme ),                     &
               INTENT(OUT)              ::      TSK_SEA,          &
                                                CHS2_SEA,         &
                                                CHS_SEA,          &
                                                CPM_SEA,          &
                                                CQS2_SEA,         &
                                                FLHC_SEA,         &
                                                FLQC_SEA,         &
                                                HFX_SEA,          &
                                                LH_SEA,           &
                                                QFX_SEA,          &
                                                QGH_SEA,          &
                                                QSFC_SEA,         &
                                                ZNT_SEA

!--------------------------------------------------------------------
!    Local
!--------------------------------------------------------------------
     INTEGER :: I, J
     REAL,     DIMENSION( ims:ime, jms:jme ) :: XLAND_SEA,        &
                                                MAVAIL_sea,       &
                                                TSK_LOCAL,        &
                                                BR_HOLD,          &
                                                CHS2_HOLD,        &
                                                CHS_HOLD,         &
                                                CPM_HOLD,         &
                                                CQS2_HOLD,        &
                                                FLHC_HOLD,        &
                                                FLQC_HOLD,        &
                                                GZ1OZ0_HOLD,      &
                                                HFX_HOLD,         &
                                                LH_HOLD,          &
                                                MOL_HOLD,         &
                                                PSIH_HOLD,        &
                                                PSIM_HOLD,        &
                                                FH_HOLD,          &
                                                FM_HOLD,          &
                                                QFX_HOLD,         &
                                                QGH_HOLD,         &
                                                REGIME_HOLD,      &
                                                RMOL_HOLD,        &
                                                UST_HOLD,         &
                                                WSPD_HOLD,        &
                                                ZNT_HOLD,         &
                                                ZOL_HOLD,         &
                                                QSFC_HOLD,        &
                                                TH2_HOLD,         & !ssib
                                                T2_HOLD,          & !ssib
                                                Q2_HOLD,          & !ssib
                                                TSK_HOLD,         & !ssib
                                                U10_HOLD,         & !ssib
                                                V10_HOLD,         & !ssib
                                                CD_SEA,           &
                                                CDA_SEA,          &
                                                CK_SEA,           &
                                                CKA_SEA,          &
                                                Q2_SEA,           &
                                                T2_SEA,           &
                                                TH2_SEA,          &
                                                U10_SEA,          &
                                                USTM_SEA,         &
                                                V10_SEA

     REAL,     DIMENSION( ims:ime, jms:jme ) ::                   &
                                                BR_SEA,           &
                                                GZ1OZ0_SEA,       &
                                                MOL_SEA,          &
                                                PSIH_SEA,         &
                                                PSIM_SEA,         &
                                                FH_SEA,           &
                                                FM_SEA,           &
                                                REGIME_SEA,       &
                                                RMOL_SEA,         &
                                                UST_SEA,          &
                                                WSPD_SEA,         &
                                                ZOL_SEA

! INTENT(IN) to SFCLAY; unchanged by the call
      ! ISFFLX
      ! SVP1,SVP2,SVP3,SVPT0
      ! EP1,EP2,KARMAN,EOMEG,STBOLT
      ! CP,G,ROVCP,R,XLV,DX
      ! ISFTCFLX,IZ0TLND
      ! P1000
      ! dz8w
      ! QV3D
      ! P3D
      ! T3D
      ! MAVAIL
      ! PBLH
      ! XLAND
      ! TSK
      ! U3D
      ! V3D
      ! PSFC

     CALL get_local_ice_tsk( ims, ime, jms, jme, its, ite, jts, jte,  &
                             itimestep, .true., tice2tsk_if2cold,     &
                             XICE, XICE_THRESHOLD,                    &
                             SST, TSK, TSK_SEA, TSK_LOCAL )


! INTENT (INOUT) to SFCLAY:  Save the variables before the first call
! (for land/frozen water) to SFCLAY, to keep from double-counting the
! effects of that routine
     BR_HOLD(its:ite,jts:jte)     = BR(its:ite,jts:jte)
     CHS2_HOLD(its:ite,jts:jte)   = CHS2(its:ite,jts:jte)
     CHS_HOLD(its:ite,jts:jte)    = CHS(its:ite,jts:jte)
     CPM_HOLD(its:ite,jts:jte)    = CPM(its:ite,jts:jte)
     CQS2_HOLD(its:ite,jts:jte)   = CQS2(its:ite,jts:jte)
     FLHC_HOLD(its:ite,jts:jte)   = FLHC(its:ite,jts:jte)
     FLQC_HOLD(its:ite,jts:jte)   = FLQC(its:ite,jts:jte)
     GZ1OZ0_HOLD(its:ite,jts:jte) = GZ1OZ0(its:ite,jts:jte)
     HFX_HOLD(its:ite,jts:jte)    = HFX(its:ite,jts:jte)
     LH_HOLD(its:ite,jts:jte)     = LH(its:ite,jts:jte)
     MOL_HOLD(its:ite,jts:jte)    = MOL(its:ite,jts:jte)
     PSIH_HOLD(its:ite,jts:jte)   = PSIH(its:ite,jts:jte)
     PSIM_HOLD(its:ite,jts:jte)   = PSIM(its:ite,jts:jte)
     FH_HOLD(its:ite,jts:jte)     = FH(its:ite,jts:jte)
     FM_HOLD(its:ite,jts:jte)     = FM(its:ite,jts:jte)
     QFX_HOLD(its:ite,jts:jte)    = QFX(its:ite,jts:jte)
     QGH_HOLD(its:ite,jts:jte)    = QGH(its:ite,jts:jte)
     REGIME_HOLD(its:ite,jts:jte) = REGIME(its:ite,jts:jte)
     RMOL_HOLD(its:ite,jts:jte)   = RMOL(its:ite,jts:jte)
     UST_HOLD(its:ite,jts:jte)    = UST(its:ite,jts:jte)
     WSPD_HOLD(its:ite,jts:jte)   = WSPD(its:ite,jts:jte)
     ZNT_HOLD(its:ite,jts:jte)    = ZNT(its:ite,jts:jte)
     ZOL_HOLD(its:ite,jts:jte)    = ZOL(its:ite,jts:jte)
     QSFC_HOLD(its:ite,jts:jte)   = QSFC(its:ite,jts:jte)
!also save these variables for SSIB (fds 12/2010)
     TH2_HOLD(its:ite,jts:jte)    = TH2(its:ite,jts:jte)
     T2_HOLD(its:ite,jts:jte)     = T2(its:ite,jts:jte)
     Q2_HOLD(its:ite,jts:jte)     = Q2(its:ite,jts:jte)
     TSK_HOLD(its:ite,jts:jte)    = TSK(its:ite,jts:jte)
     U10_HOLD(its:ite,jts:jte)    = U10(its:ite,jts:jte) !fds (01/2014)
     V10_HOLD(its:ite,jts:jte)    = V10(its:ite,jts:jte) !fds (01/2014)
     
! INTENT(OUT) from SFCLAY.  Input shouldn't matter, but we'll want to
! keep things around for weighting after the second call to SFCLAY.
     ! CD
     ! CDA
     ! CK
     ! CKA
     ! Q2
     ! QSFC
     ! T2
     ! TH2
     ! U10
     ! USTM
     ! V10


     ! land/frozen-water call
     call sfclay(U3D,V3D,T3D,QV3D,P3D,dz8w,                    & ! I
                 CP,G,ROVCP,R,XLV,PSFC,CHS,CHS2,CQS2,CPM,      & ! I,I,I,I,I,I,IO,IO,IO,IO,
                 ZNT,UST,PBLH,MAVAIL,ZOL,MOL,REGIME,PSIM,PSIH, &
                 FM,FH,                                        &
                 XLAND,HFX,QFX,LH,TSK_LOCAL,FLHC,FLQC,QGH,QSFC,RMOL, &
                 U10,V10,TH2,T2,Q2,                            &
                 GZ1OZ0,WSPD,BR,ISFFLX,DX,                     &
                 SVP1,SVP2,SVP3,SVPT0,EP1,EP2,                 &
                 KARMAN,EOMEG,STBOLT,                          &
                 P1000,lakemask,                               &
                 ids,ide, jds,jde, kds,kde,                    &
                 ims,ime, jms,jme, kms,kme,                    &
                 its,ite, jts,jte, kts,kte,                    &
                 ustm,ck,cka,cd,cda,isftcflx,iz0tlnd,scm_force_flux)
!
!Restore land-point values calculated by SSiB (fds 12/2010)
     IF (itimestep .gt. 1 .and. sf_surface_physics .EQ. 8) then
     DO j = JTS , JTE
        DO i = ITS, ITE
           IF ( XLAND(I,J) .LT. 1.5 ) THEN
              BR(I,J) = BR_HOLD(I,J)
              TH2(I,J) = TH2_HOLD(I,J)
              T2(I,J) = T2_HOLD(I,J)
              Q2(I,J) = Q2_HOLD(I,J)
              HFX(I,J) = HFX_HOLD(I,J)
              QFX(I,J) = QFX_HOLD(I,J)
              LH(I,J) = LH_HOLD(I,J)
              GZ1OZ0(I,J) = GZ1OZ0_HOLD(I,J)
              WSPD(I,J) = WSPD_HOLD(I,J)
              ZNT(I,J) = ZNT_HOLD(I,J)
              UST(I,J) = UST_HOLD(I,J)
!             TSK(I,J) = TSK_HOLD(I,J)
              U10(I,J) = U10_HOLD(I,J) !fds (01/2014)
              V10(I,J) = V10_HOLD(I,J) !fds (01/2014)
           ENDIF
        ENDDO
     ENDDO
     ENDIF
!
     ! Set up for open-water call
     DO j = JTS , JTE
        DO i = ITS , ITE
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN
              XLAND_SEA(i,j)=2.
              MAVAIL_SEA(I,J)  =1.
              ZNT_SEA(I,J) = 0.0001
              TSK_SEA(i,j) = SST(i,j)
              IF ( SST(i,j) .LT. 271.4 ) THEN
                 SST(i,j) = 271.4
                 TSK_SEA(i,j) = SST(i,j)
              ENDIF
           ELSE
              XLAND_SEA(i,j) = XLAND(i,j)
              MAVAIL_SEA(i,j) = MAVAIL(i,j)
              ZNT_SEA(i,j)  = ZNT_HOLD(i,j)
              TSK_SEA(i,j) = TSK_LOCAL(i,j)
           ENDIF
        ENDDO
     ENDDO

     ! Restore the values from before the land/frozen-water call
     BR_SEA(its:ite,jts:jte)     = BR_HOLD(its:ite,jts:jte)
     CHS2_SEA(its:ite,jts:jte)   = CHS2_HOLD(its:ite,jts:jte)
     CHS_SEA(its:ite,jts:jte)    = CHS_HOLD(its:ite,jts:jte)
     CPM_SEA(its:ite,jts:jte)    = CPM_HOLD(its:ite,jts:jte)
     CQS2_SEA(its:ite,jts:jte)   = CQS2_HOLD(its:ite,jts:jte)
     FLHC_SEA(its:ite,jts:jte)   = FLHC_HOLD(its:ite,jts:jte)
     FLQC_SEA(its:ite,jts:jte)   = FLQC_HOLD(its:ite,jts:jte)
     GZ1OZ0_SEA(its:ite,jts:jte) = GZ1OZ0_HOLD(its:ite,jts:jte)
     HFX_SEA(its:ite,jts:jte)    = HFX_HOLD(its:ite,jts:jte)
     LH_SEA(its:ite,jts:jte)     = LH_HOLD(its:ite,jts:jte)
     MOL_SEA(its:ite,jts:jte)    = MOL_HOLD(its:ite,jts:jte)
     PSIH_SEA(its:ite,jts:jte)   = PSIH_HOLD(its:ite,jts:jte)
     PSIM_SEA(its:ite,jts:jte)   = PSIM_HOLD(its:ite,jts:jte)
     FH_SEA(its:ite,jts:jte)     = FH_HOLD(its:ite,jts:jte)
     FM_SEA(its:ite,jts:jte)     = FM_HOLD(its:ite,jts:jte)
     QFX_SEA(its:ite,jts:jte)    = QFX_HOLD(its:ite,jts:jte)
     QGH_SEA(its:ite,jts:jte)    = QGH_HOLD(its:ite,jts:jte)
     REGIME_SEA(its:ite,jts:jte) = REGIME_HOLD(its:ite,jts:jte)
     RMOL_SEA(its:ite,jts:jte)   = RMOL_HOLD(its:ite,jts:jte)
     UST_SEA(its:ite,jts:jte)    = UST_HOLD(its:ite,jts:jte)
     WSPD_SEA(its:ite,jts:jte)   = WSPD_HOLD(its:ite,jts:jte)
     ZOL_SEA(its:ite,jts:jte)    = ZOL_HOLD(its:ite,jts:jte)
     ZNT_SEA(its:ite,jts:jte)    = ZNT_HOLD(its:ite,jts:jte)
     QSFC_SEA(its:ite,jts:jte)   = QSFC_HOLD(its:ite,jts:jte)
!
     ! open-water call
     call sfclay(U3D,V3D,T3D,QV3D,P3D,dz8w,                    & ! I
                 CP,G,ROVCP,R,XLV,PSFC,                        & ! I
                 CHS_SEA,CHS2_SEA,CQS2_SEA,CPM_SEA,            & ! I/O
                 ZNT_SEA,UST_SEA,                              & ! I/O
                 PBLH,MAVAIL_SEA,                              & ! I
                 ZOL_SEA,MOL_SEA,REGIME_SEA,PSIM_SEA,PSIH_SEA, & ! I/O
                 FM_SEA,FH_SEA,                                &
                 XLAND_SEA,                              & ! I
                 HFX_SEA,QFX_SEA,LH_SEA,                       & ! I/O
                 TSK_SEA,                                      & ! I
                 FLHC_SEA,FLQC_SEA,QGH_SEA,QSFC_sea,RMOL_SEA,  & ! I/O
                 U10_sea,V10_sea,TH2_sea,T2_sea,Q2_sea,        & ! O
                 GZ1OZ0_SEA,WSPD_SEA,BR_SEA,                   & ! I/O
                 ISFFLX,DX,                                    &
                 SVP1,SVP2,SVP3,SVPT0,EP1,EP2,                 &
                 KARMAN,EOMEG,STBOLT,                          &
                 P1000,lakemask,                               &
                 ids,ide, jds,jde, kds,kde,                    &
                 ims,ime, jms,jme, kms,kme,                    &
                 its,ite, jts,jte, kts,kte,                    & ! 0
                 ustm_sea,ck_sea,cka_sea,cd_sea,cda_sea,isftcflx,iz0tlnd,scm_force_flux)
!
     DO j = JTS , JTE
        DO i = ITS, ITE
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD )  .and.( XICE(i,j) .LE. 1.0 ) ) THEN
              ! weighted average for sea ice points
              br(i,j)     = ( br(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * br_sea(i,j)     )
              ! CHS2 -- wait
              ! CHS  -- wait
              ! CPM  -- wait
              ! CQS2 -- wait
              ! FLHC -- wait
              ! FLQC -- wait
              gz1oz0(i,j) = ( gz1oz0(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * gz1oz0_sea(i,j) )
              ! HFX  -- wait
              ! LH   -- wait
              mol(i,j)    = ( mol(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * mol_sea(i,j)    )
              psih(i,j)   = ( psih(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * psih_sea(i,j)   )
              psim(i,j)   = ( psim(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * psim_sea(i,j)   )
              fh(i,j)    = ( fh(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * fh_sea(i,j)   )
              fm(i,j)    = ( fm(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * fm_sea(i,j)   )
              ! QFX  -- wait
              ! QGH  -- wait
              if ( XICE(i,j).GE. 0.5 ) regime(i,j) = regime_hold(i,j)
              rmol(i,j)   = ( rmol(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * rmol_sea(i,j)   )
              ust(i,j)    = ( ust(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * ust_sea(i,j)    )
              wspd(i,j)   = ( wspd(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * wspd_sea(i,j)   )
              zol(i,j)    = ( zol(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * zol_sea(i,j)    )
              ! INTENT(OUT) --------------------------------------------------------------------
              IF ( PRESENT ( CD ) ) THEN
                 CD(i,j)     = ( CD(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * CD_sea(i,j)     )
              ENDIF
              IF ( PRESENT ( CDA ) ) THEN
                 CDA(i,j)     = ( CDA(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * CDA_sea(i,j)     )
              ENDIF
              IF ( PRESENT ( CK ) ) THEN
                 CK(i,j)     = ( CK(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * CK_sea(i,j)     )
              ENDIF
              IF ( PRESENT ( CKA ) ) THEN
                 CKA(i,j)     = ( CKA(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * CKA_sea(i,j)     )
              ENDIF
              q2(i,j)     = ( q2(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * q2_sea(i,j)     )
              ! QSFC -- wait
              t2(i,j)     = ( t2(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * t2_sea(i,j)     )
              th2(i,j)    = ( th2(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * th2_sea(i,j)    )
              u10(i,j)    = ( u10(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * u10_sea(i,j)    )
              IF ( PRESENT ( USTM ) ) THEN
                 USTM(i,j)    = ( USTM(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * USTM_sea(i,j)    )
              ENDIF
              v10(i,j)    = ( v10(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * v10_sea(i,j)    )
           ENDIF
        END DO
     END DO
!
!         tsk(i,j) = tsk(i,j)*XICE(i,j) + (1.0-XICE(i,j))*TSK_SEA(i,j)
!
   END SUBROUTINE sfclay_seaice_wrapper

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

   SUBROUTINE pxsfclay_seaice_wrapper(U3D,V3D,T3D,TH3D,QV3D,P3D,dz8w, &
                     CP,G,ROVCP,R,XLV,PSFC,CHS,CHS2,CQS2,CPM,      &
                     ZNT,UST,PBLH,MAVAIL,ZOL,MOL,REGIME,PSIM,PSIH, &
                     XLAND,HFX,QFX,LH,TSK,FLHC,FLQC,QGH,QSFC,RMOL, &
                     U10,V10,                                      &
                     GZ1OZ0,WSPD,BR,ISFFLX,DX,                     &
                     SVP1,SVP2,SVP3,SVPT0,EP1,EP2,KARMAN,          &
XICE, SST, ITIMESTEP, TICE2TSK_IF2COLD,XICE_THRESHOLD,             &
CHS_SEA, CHS2_SEA, CPM_SEA, CQS2_SEA, FLHC_SEA, FLQC_SEA,          &
HFX_SEA, LH_SEA, QFX_SEA, QGH_SEA, QSFC_SEA, TSK_SEA,  &
                     ids,ide, jds,jde, kds,kde,                    &
                     ims,ime, jms,jme, kms,kme,                    &
                     its,ite, jts,jte, kts,kte                     )
     USE module_sf_pxsfclay
     implicit none
     INTEGER,  INTENT(IN )   ::        ids,ide, jds,jde, kds,kde, &
                                       ims,ime, jms,jme, kms,kme, &
                                       its,ite, jts,jte, kts,kte

     INTEGER,  INTENT(IN )   ::        ISFFLX
     LOGICAL,  INTENT(IN )   ::        TICE2TSK_IF2COLD
     REAL,     INTENT(IN )   ::        SVP1,SVP2,SVP3,SVPT0
     REAL,     INTENT(IN )   ::        EP1,EP2,KARMAN

     REAL,     DIMENSION( ims:ime, kms:kme, jms:jme )           , &
               INTENT(IN   )   ::                           dz8w

     REAL,     DIMENSION( ims:ime, kms:kme, jms:jme )           , &
               INTENT(IN   )   ::                           QV3D, &
                                                             P3D, &
                                                             T3D, &
                                                            TH3D

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(IN   )               ::             MAVAIL, &
                                                            PBLH, &
                                                           XLAND, &
                                                             TSK
     REAL,     DIMENSION( ims:ime, kms:kme, jms:jme )           , &
               INTENT(IN   )   ::                            U3D, &
                                                             V3D

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(IN   )               ::               PSFC

     REAL,     INTENT(IN   )                  ::   CP,G,ROVCP,R,XLV,DX

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(OUT  )               ::                U10, &
                                                             V10, &
                                                            QSFC
     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)               ::             REGIME, &
                                                             HFX, &
                                                             QFX, &
                                                              LH, &
                                                         MOL,RMOL
     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                 GZ1OZ0,WSPD,BR, &
                                                       PSIM,PSIH

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                            ZNT, &
                                                             ZOL, &
                                                             UST, &
                                                             CPM, &
                                                            CHS2, &
                                                            CQS2, &
                                                             CHS

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                      FLHC,FLQC

     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)   ::                            QGH

!--------------------------------------------------------------------
!    For wrapper
!--------------------------------------------------------------------

     INTEGER,  INTENT(IN)                           :: ITIMESTEP
     REAL,     INTENT(IN)                           :: XICE_THRESHOLD
     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(IN)                           ::      XICE
     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(OUT)                        ::     TSK_SEA
     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(INOUT)              ::                 SST

!--------------------------------------------------------------------
!    Local
!--------------------------------------------------------------------
     INTEGER :: I, J
     REAL,     DIMENSION( ims:ime, jms:jme )                    , &
               INTENT(OUT)    ::                         CHS_SEA, &
                                                        CHS2_SEA, &
                                                         CPM_SEA, &
                                                        CQS2_SEA, &
                                                        FLHC_SEA, &
                                                        FLQC_SEA, &
                                                         HFX_SEA, &
                                                          LH_SEA, &
                                                         QFX_SEA, &
                                                         QGH_SEA, &
                                                        QSFC_SEA

     REAL,     DIMENSION( ims:ime, jms:jme ) ::          BR_HOLD, &
                                                        CHS_HOLD, &
                                                       CHS2_HOLD, &
                                                        CPM_HOLD, &
                                                       CQS2_HOLD, &
                                                       FLHC_HOLD, &
                                                       FLQC_HOLD, &
                                                     GZ1OZ0_HOLD, &
                                                        HFX_HOLD, &
                                                         LH_HOLD, &
                                                        MOL_HOLD, &
                                                       PSIH_HOLD, &
                                                       PSIM_HOLD, &
                                                        QFX_HOLD, &
                                                        QGH_HOLD, &
                                                     REGIME_HOLD, &
                                                       RMOL_HOLD, &
                                                        UST_HOLD, &
                                                       WSPD_HOLD, &
                                                        ZNT_HOLD, &
                                                        ZOL_HOLD, &
                                                       TSK_LOCAL

     REAL,     DIMENSION( ims:ime, jms:jme ) ::        XLAND_SEA, &
                                                      MAVAIL_SEA, &
                                                          BR_SEA, &
                                                      GZ1OZ0_SEA, &
                                                         MOL_SEA, &
                                                        PSIH_SEA, &
                                                        PSIM_SEA, &
                                                      REGIME_SEA, &
                                                        RMOL_SEA, &
                                                         UST_SEA, &
                                                        WSPD_SEA, &
                                                         ZNT_SEA, &
                                                         ZOL_SEA, &
                                                         U10_SEA, &
                                                         V10_SEA

     CALL get_local_ice_tsk( ims, ime, jms, jme, its, ite, jts, jte,  &
                             itimestep, .true., tice2tsk_if2cold,     &
                             XICE, XICE_THRESHOLD,                    &
                             SST, TSK, TSK_SEA, TSK_LOCAL )
!
! INTENT (INOUT) to PXSFCLAY:  Save the variables before the first call
! (for land/frozen water) to SFCLAY, to keep from double-counting the
! effects of that routine
!
     BR_HOLD(its:ite,jts:jte)     = BR(its:ite,jts:jte)
     CHS_HOLD(its:ite,jts:jte)    = CHS(its:ite,jts:jte)
     CHS2_HOLD(its:ite,jts:jte)   = CHS2(its:ite,jts:jte)
     CPM_HOLD(its:ite,jts:jte)    = CPM(its:ite,jts:jte)
     CQS2_HOLD(its:ite,jts:jte)   = CQS2(its:ite,jts:jte)
     FLHC_HOLD(its:ite,jts:jte)   = FLHC(its:ite,jts:jte)
     FLQC_HOLD(its:ite,jts:jte)   = FLQC(its:ite,jts:jte)
     GZ1OZ0_HOLD(its:ite,jts:jte) = GZ1OZ0(its:ite,jts:jte)
     HFX_HOLD(its:ite,jts:jte)    = HFX(its:ite,jts:jte)
     LH_HOLD(its:ite,jts:jte)     = LH(its:ite,jts:jte)
     MOL_HOLD(its:ite,jts:jte)    = MOL(its:ite,jts:jte)
     PSIH_HOLD(its:ite,jts:jte)   = PSIH(its:ite,jts:jte)
     PSIM_HOLD(its:ite,jts:jte)   = PSIM(its:ite,jts:jte)
     QFX_HOLD(its:ite,jts:jte)    = QFX(its:ite,jts:jte)
     QGH_HOLD(its:ite,jts:jte)    = QGH(its:ite,jts:jte)
     REGIME_HOLD(its:ite,jts:jte) = REGIME(its:ite,jts:jte)
     RMOL_HOLD(its:ite,jts:jte)   = RMOL(its:ite,jts:jte)
     UST_HOLD(its:ite,jts:jte)    = UST(its:ite,jts:jte)
     WSPD_HOLD(its:ite,jts:jte)   = WSPD(its:ite,jts:jte)
     ZNT_HOLD(its:ite,jts:jte)    = ZNT(its:ite,jts:jte)
     ZOL_HOLD(its:ite,jts:jte)    = ZOL(its:ite,jts:jte)

! INTENT(OUT) from PXSFCLAY.  Input shouldn't matter, but we'll want to
! keep things around for weighting after the second call to PXSFCLAY.
     ! U10
     ! V10
     ! QSFC

! Land/frozen-water call.
     CALL pxsfclay(U3D,V3D,T3D,TH3D,QV3D,P3D,dz8w,                 &
                     CP,G,ROVCP,R,XLV,PSFC,CHS,CHS2,CQS2,CPM,      &
                     ZNT,UST,PBLH,MAVAIL,ZOL,MOL,REGIME,PSIM,PSIH, &
                     XLAND,HFX,QFX,LH,TSK_LOCAL,FLHC,FLQC,QGH,QSFC,RMOL, &
                     U10,V10,                                      &
                     GZ1OZ0,WSPD,BR,ISFFLX,DX,                     &
                     SVP1,SVP2,SVP3,SVPT0,EP1,EP2,KARMAN,ITIMESTEP,&
                     ids,ide, jds,jde, kds,kde,                    &
                     ims,ime, jms,jme, kms,kme,                    &
                     its,ite, jts,jte, kts,kte                     )

     DO j = JTS , JTE
        DO i= ITS , ITE
           IF( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN
              ! Sets up things for open ocean.
              XLAND_SEA(i,j)=2.
              MAVAIL_SEA(I,J)  =1.
              ZNT_SEA(I,J) = 0.0001
              TSK_SEA(i,j)  = SST(i,j)
              if ( SST(i,j) .LT. 271.4 ) then
                 SST(i,j) = 271.4
                 TSK_SEA(i,j) = SST(i,j)
              endif
           ELSE
              XLAND_SEA(i,j)=xland(i,j)
              MAVAIL_SEA(i,j) = mavail(i,j)
              ZNT_SEA(I,J)  = ZNT_HOLD(I,J)
              TSK_SEA(i,j)  = TSK(i,j)
           ENDIF
        ENDDO
     ENDDO

     ! INTENT(INOUT) variables held over from before the first call to PXSFCLAY:
     BR_SEA(its:ite,jts:jte)     = BR_HOLD(its:ite,jts:jte)
     CHS_SEA(its:ite,jts:jte)    = CHS_HOLD(its:ite,jts:jte)
     CHS2_SEA(its:ite,jts:jte)   = CHS2_HOLD(its:ite,jts:jte)
     CPM_SEA(its:ite,jts:jte)    = CPM_HOLD(its:ite,jts:jte)
     CQS2_SEA(its:ite,jts:jte)   = CQS2_HOLD(its:ite,jts:jte)
     FLHC_SEA(its:ite,jts:jte)   = FLHC_HOLD(its:ite,jts:jte)
     FLQC_SEA(its:ite,jts:jte)   = FLQC_HOLD(its:ite,jts:jte)
     GZ1OZ0_SEA(its:ite,jts:jte) = GZ1OZ0_HOLD(its:ite,jts:jte)
     HFX_SEA(its:ite,jts:jte)    = HFX_HOLD(its:ite,jts:jte)
     LH_SEA(its:ite,jts:jte)     = LH_HOLD(its:ite,jts:jte)
     MOL_SEA(its:ite,jts:jte)    = MOL_HOLD(its:ite,jts:jte)
     PSIH_SEA(its:ite,jts:jte)   = PSIH_HOLD(its:ite,jts:jte)
     PSIM_SEA(its:ite,jts:jte)   = PSIM_HOLD(its:ite,jts:jte)
     QFX_SEA(its:ite,jts:jte)    = QFX_HOLD(its:ite,jts:jte)
     QGH_SEA(its:ite,jts:jte)    = QGH_HOLD(its:ite,jts:jte)
     REGIME_SEA(its:ite,jts:jte) = REGIME_HOLD(its:ite,jts:jte)
     RMOL_SEA(its:ite,jts:jte)   = RMOL_HOLD(its:ite,jts:jte)
     UST_SEA(its:ite,jts:jte)    = UST_HOLD(its:ite,jts:jte)
     WSPD_SEA(its:ite,jts:jte)   = WSPD_HOLD(its:ite,jts:jte)
     ZOL_SEA(its:ite,jts:jte)    = ZOL_HOLD(its:ite,jts:jte)

! Open-water call.
     ! Variables newly set (INTENT(OUT)) or changed (INTENT(INOUT)) by
     ! PXSFCLAY are here appended with the "_SEA" label.
     ! Special intent(IN) variables here:  XLAND_SEA, MAVAIL_SEA, TSK_SEA
     CALL pxsfclay(U3D,V3D,T3D,TH3D,QV3D,P3D,dz8w,                 &
                     CP,G,ROVCP,R,XLV,PSFC,CHS_SEA,CHS2_SEA,CQS2_SEA,CPM_SEA,      &
                     ZNT_SEA,UST_SEA,PBLH,MAVAIL_SEA,ZOL_SEA,MOL_SEA,REGIME_SEA,PSIM_SEA,PSIH_SEA, &
                     XLAND_SEA,HFX_SEA,QFX_SEA,LH_SEA,TSK_SEA,FLHC_SEA,FLQC_SEA,QGH_SEA,QSFC_SEA,RMOL_SEA, &
                     U10_SEA,V10_SEA,                              &
                     GZ1OZ0_SEA,WSPD_SEA,BR_SEA,ISFFLX,DX,         &
                     SVP1,SVP2,SVP3,SVPT0,EP1,EP2,KARMAN,ITIMESTEP,&
                     ids,ide, jds,jde, kds,kde,                    &
                     ims,ime, jms,jme, kms,kme,                    &
                     its,ite, jts,jte, kts,kte                     )

     DO j = JTS , JTE
        DO i = ITS , ITE
           IF ( ( XICE(I,J) .GE. XICE_THRESHOLD ) .and. ( XICE(i,j) .LE. 1.0 ) ) THEN
              ! INTENT (INOUT) for PXSFCLAY:
              br(i,j)     = ( br(i,j)     * XICE(i,j) ) + ( (1.0-XICE(i,j)) * br_sea(i,j)     )
              gz1oz0(i,j) = ( gz1oz0(i,j) * XICE(i,j) ) + ( (1.0-XICE(i,j)) * gz1oz0_sea(i,j) )
              mol(i,j)    = ( mol(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * mol_sea(i,j)    )
              psih(i,j)   = ( psih(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * psih_sea(i,j)   )
              psim(i,j)   = ( psim(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * psim_sea(i,j)   )
              rmol(i,j)   = ( rmol(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * rmol_sea(i,j)   )
              ust(i,j)    = ( ust(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * ust_sea(i,j)    )
              wspd(i,j)   = ( wspd(i,j)   * XICE(i,j) ) + ( (1.0-XICE(i,j)) * wspd_sea(i,j)   )
              zol(i,j)    = ( zol(i,j)    * XICE(i,j) ) + ( (1.0-XICE(i,j)) * zol_sea(i,j)    )
              ! REGIME:  Special case for this variable.  Just take the land values.
              ! CHS -- wait
              ! CHS2 -- wait
              ! CPM -- wait
              ! CQS2 -- wait
              ! FLHC -- wait
              ! FLQC -- wait
              ! HFX -- wait
              ! LH -- wait
              ! QFX -- wait
              ! QGH -- wait

              ! INTENT (OUT) from PXSFCLAY:
              u10(i,j) = ( u10(i,j)       * XICE(i,j) ) + ( (1.0-XICE(i,j)) * u10_sea(i,j)    )
              v10(i,j) = ( v10(i,j)       * XICE(i,j) ) + ( (1.0-XICE(i,j)) * v10_sea(i,j)    )
              ! QSFC -- wait
           ENDIF
        ENDDO
     ENDDO

   END SUBROUTINE pxsfclay_seaice_wrapper

!-------------------------------------------------------------------------

   SUBROUTINE TOPO_RAD_ADJ_DRVR (XLAT,XLONG,COSZEN,               &
                    shadowmask, diffuse_frac,                     &
                    declin,                                       &
                    SWDOWN,GSW,SWNORM,GSWSAVE,solcon,hrang2d,     &
                    slope_in,slp_azi_in,                          &
                ids, ide, jds, jde, kds, kde,                     &
                ims, ime, jms, jme, kms, kme,                     &
                its, ite, jts, jte, kts, kte                      )
!------------------------------------------------------------------
   IMPLICIT NONE
!------------------------------------------------------------------
   INTEGER, INTENT(IN)   ::       its,ite,jts,jte,kts,kte,        &
                                  ims,ime,jms,jme,kms,kme,        &
                                  ids,ide,jds,jde,kds,kde
   INTEGER, DIMENSION( ims:ime, jms:jme ),                        &
         INTENT(IN)      ::       shadowmask
   REAL, DIMENSION( ims:ime, jms:jme ),                           &
         INTENT(IN)      ::       diffuse_frac
   REAL, DIMENSION( ims:ime, jms:jme ),                           &
         INTENT(IN   )   ::       XLAT,XLONG
   REAL, DIMENSION( ims:ime, jms:jme ),                           &
         INTENT(INOUT)   ::       SWDOWN,GSW,SWNORM,GSWSAVE
   real,intent(in)  :: solcon   
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN   ) :: hrang2d,coszen 


   REAL, INTENT(IN    )  ::       declin
   REAL, DIMENSION( ims:ime, jms:jme ), INTENT(IN   ) :: slope_in,slp_azi_in


! LOCAL VARS
   integer    :: i,j
   real       :: pi,degrad
   integer    :: shadow
   real       :: swdown_teradj,swdown_in,xlat1,xlong1

!------------------------------------------------------------------

     pi = 4.*rp_atan(1.)
     degrad=pi/180.

       DO J=jts,jte
       DO I=its,ite
         SWNORM(i,j) = SWDOWN(i,j)     ! save
         IF(SWDOWN(I,J) .GT. 1.E-3)THEN  ! daytime
             shadow = shadowmask(i,j)

         SWDOWN_IN = SWDOWN(i,j)
         XLAT1 = XLAT(i,j)
         XLONG1 = XLONG(i,j)
         CALL TOPO_RAD_ADJ (XLAT1,XLONG1,COSZEN(i,j),             &
                    diffuse_frac(i,j),DECLIN,DEGRAD,              &
                    SWDOWN_IN,solcon,hrang2d(i,j),SWDOWN_teradj,  &
                    kts,kte,                                      &
                    slope_in(i,j),slp_azi_in(i,j),                &
                    shadow , i,j                                  &
                    )

         GSWSAVE(I,J) = GSW(I,J)       ! save
         GSW(I,J) = GSW(I,J)*SWDOWN_teradj/SWDOWN(i,j)
         SWDOWN(i,j) = SWDOWN_teradj

         ENDIF ! daytime
       ENDDO  ! i_loop
       ENDDO  ! j_loop


   END SUBROUTINE TOPO_RAD_ADJ_DRVR
!------------------------------------------------------------------
!------------------------------------------------------------------
   SUBROUTINE TOPO_RAD_ADJ (XLAT1,XLONG1,COSZEN,                 &
                    diffuse_frac_in,DECLIN,DEGRAD,               &
                    SWDOWN_IN,solcon,hrang,SWDOWN_teradj,        &
                    kts,kte,                                     &
                    slope,slp_azi,                               &
                    shadow                                       &
                    ,i,j)

!------------------------------------------------------------------
   IMPLICIT NONE
!------------------------------------------------------------------
  INTEGER, INTENT(IN)       :: kts,kte
  REAL, INTENT(IN)          :: COSZEN,DECLIN,              &
                               XLAT1,XLONG1,DEGRAD
  REAL, INTENT(IN)          :: SWDOWN_IN,solcon,hrang
  INTEGER, INTENT(IN)       :: shadow
  REAL, INTENT(IN)          :: slp_azi,slope
  REAL, INTENT(IN)          :: diffuse_frac_in

  REAL, INTENT(OUT)         :: SWDOWN_teradj

! LOCAL VARS
   REAL            :: XT24,TLOCTM,CSZA,XXLAT
   REAL            :: diffuse_frac,corr_fac,csza_slp
   integer         :: i,j


!------------------------------------------------------------------

     SWDOWN_teradj=SWDOWN_IN

     CSZA=COSZEN
     XXLAT=XLAT1*DEGRAD

! RETURN IF NIGHT
         IF(CSZA.LE.1.E-4) return 
        
!  Parameterize diffuse fraction of global solar radiation as a function of the ratio 
!    between TOA radiation and surface global radiation
!             diffuse_frac = min(1.,1./(max(0.1,2.1-2.8*log(log(csza*solcon/max(SWDOWN_IN,1.e-3))))))
              diffuse_frac = diffuse_frac_in
        if ((slope.eq.0).or.(diffuse_frac.eq.1).or.(csza.le.1.e-4)) then
!  no topographic effects when all radiation diffuse or sun too close to horizon
          corr_fac = 1
          if(shadow.eq.1) corr_fac = diffuse_frac
          goto 140
        endif

! cosine of zenith angle over sloping topography
        csza_slp = ((rp_sin(XXLAT)*rp_cos(HRANG))*                                          &
                    (-rp_cos(slp_azi)*rp_sin(slope))-rp_sin(HRANG)*(rp_sin(slp_azi)*rp_sin(slope))+  &
                    (rp_cos(XXLAT)*rp_cos(HRANG))*rp_cos(slope))*                              &
                   rp_cos(DECLIN)+(rp_cos(XXLAT)*(rp_cos(slp_azi)*rp_sin(slope))+                 &
                   rp_sin(XXLAT)*rp_cos(slope))*rp_sin(DECLIN)
        IF(csza_slp.LE.1.E-4) csza_slp = 0

! Topographic shading
        if (shadow.eq.1) csza_slp = 0

! Correction factor for sloping topography; the diffuse fraction of solar radiation 
!   is assumed to be unaffected by the slope
        corr_fac = diffuse_frac + (1-diffuse_frac)*csza_slp/csza

 140        continue

      SWDOWN_teradj=(1.)*SWDOWN_IN*corr_fac

   END SUBROUTINE TOPO_RAD_ADJ

!=======================================================================

   SUBROUTINE get_local_ice_tsk ( ims, ime, jms, jme,     &
                                  its, ite, jts, jte,     &
                                  itimestep,              &
                                  sfc_layer_values,       &
                                  tice2tsk_if2cold,       &
                                  XICE, XICE_THRESHOLD,   &
                                  SST, TSK, TSK_SEA, TSK_ICE )
!<DESCRIPTION>
!
! For grid cells with a fractional ice area, derive the ice surface 
! temperature from the area-averaged surface temperature (the blended
! result of the open-water values (SST) and the ice-covered value).
!
!</DESCRIPTION>

      IMPLICIT NONE

      INTEGER, INTENT(IN) :: ims, ime, jms, jme    !-- start/end index for i/j in memory
      INTEGER, INTENT(IN) :: its, ite, jts, jte    !-- start/end index for i/j in tile
      INTEGER, INTENT(IN) :: itimestep             !-- timestep
      LOGICAL, INTENT(IN) :: sfc_layer_values      !-- True if there are surface layer routine values
                                                   !-- available from the ice portion of the grid point
                                                   !-- (i.e. called from a seaice_wrapper subroutine)
      LOGICAL, INTENT(IN) :: tice2tsk_if2cold      !-- True to set TSK_ICE to TSK.  This may be
                                                   !-- necessary to avoid unphysically low ice
                                                   !-- temperatures is there is a mis-match between
                                                   !-- ice fraction and surface temperature.

      REAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN)    :: XICE        ! Ice fraction
      REAL                                , INTENT(IN)    :: XICE_THRESHOLD 
      REAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN)    :: TSK         ! Surface temperature (K)
      REAL, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT) :: SST         ! Sea surface temperature (K)
      REAL, DIMENSION( ims:ime , jms:jme ), INTENT(OUT)   :: TSK_SEA     ! Sfc temp of open water portion of grid cell 
      REAL, DIMENSION( ims:ime , jms:jme ), INTENT(OUT)   :: TSK_ICE     ! Sfc temp of ice oprtion of grid cell

! Local
      INTEGER :: i,j
      REAL    :: TICE_MIN

      TICE_MIN = 221.4

      DO j = JTS , JTE
         DO i = ITS , ITE
            IF ( ( XICE(i,j) >= XICE_THRESHOLD ) .AND. ( XICE(I,J) <= 1.0 ) ) THEN
 
               IF ( SST(i,j) < 271.4 ) THEN
                  SST(i,j) = 271.4
               ENDIF
 
               IF (sfc_layer_values) THEN
                  IF ( SST(i,j) > 273. .AND. itimestep <= 3) then
                     ! Why the dependence on the time step count, here?
                     IF ( XICE(i,j) >= 0.6 ) THEN
                        SST(i,j) = 271.4
                     ELSEIF ( XICE(i,j) >= 0.4 ) THEN
                        SST(i,j) = 273.
                     ELSEIF (XICE(i,j) >= 0.2 .AND. SST(i,j) > 275.) THEN
                        SST(i,j) = 275.
                     ELSEIF (SST(i,j) > 278.) THEN
                        SST(i,j) = 278.
                     ENDIF
                  ENDIF
               ENDIF
               TSK_SEA(i,j) = SST(i,j)
 
               IF ( tice2tsk_if2cold ) THEN
!------------------------------------------------------------------------------------
! This avoids unphysically low ice temperatures for grid cells with low ice fractions
! and low area-averaged temperatures.  This can happen when the initial ice fraction 
! and surface temperature come from different data sets.
!------------------------------------------------------------------------------------
                  TSK_ICE(i,j) = MIN( TSK(i,j), 273.15 )
               ELSE
                  TSK_ICE(i,j) = ( TSK(i,j) - (1.0-XICE(i,j)) * SST(i,j) ) / XICE(i,j)
                  IF ( TSK_ICE(i,j) < TICE_MIN ) TSK_ICE(i,j) = TICE_MIN
               ENDIF
 
               IF ( ( XICE(i,j) < 0.2 ) .AND. ( TSK(i,j) < 253.15 ) ) THEN
                  TSK_ICE(i,j) = 253.15
               ENDIF
               IF ( ( XICE(i,j) < 0.1 ) .AND. ( TSK(i,j) < 263.15 ) ) THEN
                  TSK_ICE(i,j) = 263.15
               ENDIF
            ELSE
               ! land/open-water point
               TSK_SEA(i,j) = TSK(i,j)
               TSK_ICE(i,j) = TSK(i,j)
            ENDIF
         ENDDO
      ENDDO

   END SUBROUTINE get_local_ice_tsk

!=======================================================================
!=======================================================================

   subroutine Add_multi_perturb_lsm_perturbations (perts_qvapor, perts_th, perts_smois, perts_tsoil, &
       pert_noah_qv, pert_noah_t, pert_noah_smois, pert_noah_tslb, t_phy, qv_curr, tslb, smois, &
       tslb_tmp, smois_tmp, num_soil_layers, its, ite, jts, jte, ims, ime, jms, jme, kms, kme, kts, kte)

     implicit none

     integer, intent(in) :: its, ite, jts, jte, ims, ime, jms, jme, kms, kme, kts, kte, num_soil_layers
     real, intent(in) :: pert_noah_qv, pert_noah_t, pert_noah_smois, pert_noah_tslb
     real, dimension(ims:ime, kms:kme, jms:jme), optional, intent (in) :: perts_qvapor, &
         perts_th, perts_smois, perts_tsoil
     real, dimension(ims:ime, kms:kme, jms:jme), intent (inout) :: t_phy, qv_curr
     real, dimension(ims:ime, 1:num_soil_layers, jms:jme), intent (inout) :: tslb, smois
     real, dimension (its:ite, 1:num_soil_layers, jts:jte), intent(out) :: tslb_tmp, smois_tmp

     integer :: i, j, k


     k = 1
     do j = jts, jte
       do i = its, ite
           qv_curr(i, k, j) = max (QVAPOR_MIN, (1.0 + perts_qvapor(i, k, j) * pert_noah_qv) * qv_curr(i, k, j))
           t_phy(i, k, j) = (1.0 + perts_th(i, k, j) * pert_noah_t) * t_phy(i, k, j)
       end do
     end do

     do j = jts, jte
       do k = 1, num_soil_layers
         do i = its, ite
           smois_tmp(i, k, j) = smois(i, k, j)
           smois(i, k, j) = min (SMOIS_MAX, max (SMOIS_MIN, (1.0 + perts_smois(i, k, j) * pert_noah_smois) * smois(i, k, j)))
           tslb_tmp(i, k, j) = tslb(i, k, j)
           tslb(i, k, j) = (1.0 + perts_tsoil(i, k, j) * pert_noah_tslb) * tslb(i, k, j)
         end do
       end do
     end do

   end subroutine Add_multi_perturb_lsm_perturbations

   subroutine Remove_multi_perturb_lsm_perturbations (perts_qvapor, perts_th, perts_smois, perts_tsoil, &
       pert_noah_qv, pert_noah_t, pert_noah_smois, pert_noah_tslb, t_phy, qv_curr, tslb, smois, &
       tslb_tmp, smois_tmp, num_soil_layers, its, ite, jts, jte, ims, ime, jms, jme, kms, kme, kts, kte)

     implicit none

     integer, intent(in) :: its, ite, jts, jte, ims, ime, jms, jme, kms, kme, kts, kte, num_soil_layers
     real, intent(in) :: pert_noah_qv, pert_noah_t, pert_noah_smois, pert_noah_tslb
     real, dimension(ims:ime, kms:kme, jms:jme), optional, intent (in) :: perts_qvapor, &
         perts_th, perts_smois, perts_tsoil
     real, dimension(ims:ime, kms:kme, jms:jme), intent (inout) :: t_phy, qv_curr
     real, dimension(ims:ime, 1:num_soil_layers, jms:jme), intent (inout) :: tslb, smois
     real, dimension (its:ite, 1:num_soil_layers, jts:jte), intent(in) :: tslb_tmp, smois_tmp

     integer :: i, j, k


     k = 1
     do j = jts, jte
       do i = its, ite
           qv_curr(i, k, j) = max (QVAPOR_MIN, qv_curr(i, k, j) / (1.0 + perts_qvapor(i, k, j) * pert_noah_qv))
           t_phy(i, k, j) = t_phy(i, k, j) / (1.0 + perts_th(i, k, j) * pert_noah_t)
       end do
     end do

     do j = jts, jte
       do k = 1, num_soil_layers
         do i = its, ite
           smois(i, k, j) = min (SMOIS_MAX, max (SMOIS_MIN, smois(i, k, j) - perts_smois(i, k, j) * pert_noah_smois * smois_tmp(i, k, j)))
           tslb(i, k, j) = tslb(i, k, j) - perts_tsoil(i, k, j) * pert_noah_tslb * tslb_tmp(i, k, j)
         end do
       end do
     end do

  end subroutine Remove_multi_perturb_lsm_perturbations

END MODULE module_surface_driver
