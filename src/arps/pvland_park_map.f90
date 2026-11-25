!
!##################################################################
!##################################################################
!######                                                      ######
!######              SUBROUTINE PVLAND_PARK_MAP              ######
!######                                                      ######
!##################################################################
!##################################################################
!

SUBROUTINE pvland_park_map(nx,ny,pv_park,tem1)

!
!-----------------------------------------------------------------------
!
!  PURPOSE:
!
!  Define the location of the PV park on the ARPS grid:
!  pv_park(i,j) = 1. inside the park, 0. outside.
!  Namelist &pvland (module pvland_nml):
!    pv_park_opt = 0 : whole domain
!    pv_park_opt = 1 : rectangle pv_park_i1:pv_park_i2 x pv_park_j1:pv_park_j2
!                      (global scalar-point indices, clipped to the domain)
!    pv_park_opt = 2 : no PV park (natural ground only, PV-LAND soil physics)
!
!  This routine is host-model specific (MPI, boundary conditions):
!  the ARPS version is here, the offline PV-LAND model provides its own
!  version (pv_park = 1. everywhere). INIT_PVLAND (pvland.f90) calls it
!  and is therefore identical in ARPS and in the offline model.
!
!-----------------------------------------------------------------------
!
!  AUTHOR: Sylvain Dupont (moved out of INIT_PVLAND)
!
!-----------------------------------------------------------------------
!
  USE pvland_nml, ONLY : pv_park_opt, pv_park_i1, pv_park_i2,         &
                         pv_park_j1, pv_park_j2

  IMPLICIT NONE

  INTEGER :: nx,ny
  REAL :: pv_park(nx,ny)
  REAL :: tem1(nx,ny)          ! temporary array (MPI exchange)
!
!-----------------------------------------------------------------------
!
!  Misc. local variables:
!
!-----------------------------------------------------------------------
!
  INTEGER :: nxlg,nylg
  REAL, ALLOCATABLE :: temp_pv_park(:,:)
!
!-----------------------------------------------------------------------
!
!  Include files:
!
!-----------------------------------------------------------------------
!
  INCLUDE 'globcst.inc'
  INCLUDE 'bndry.inc'
  INCLUDE 'mp.inc'            ! Message passing parameters.
!
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
!
!  Beginning of executable code...
!
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
!

  nxlg = (nx-3)*nproc_x+3
  nylg = (ny-3)*nproc_y+3

  ALLOCATE(temp_pv_park(nxlg,nylg))
  temp_pv_park = 0.

  IF (myproc == 0) THEN

	IF (pv_park_opt == 1) THEN
	  temp_pv_park(MAX(pv_park_i1,1):MIN(pv_park_i2,nxlg),           &
	               MAX(pv_park_j1,1):MIN(pv_park_j2,nylg)) = 1.
	ELSE IF (pv_park_opt == 0) THEN
	  temp_pv_park(:,:) = 1.
	ENDIF                           ! pv_park_opt = 2: no PV park

  ENDIF

  CALL mpisplit2d(temp_pv_park,nx,ny,pv_park)

  IF (mp_opt > 0) THEN
    CALL acct_interrupt(mp_acct)
    CALL mpsendrecv1dew(pv_park,nx,ny,ebc,wbc,0,tem1)
    CALL mpsendrecv1dns(pv_park,nx,ny,nbc,sbc,0,tem1)
  END IF

  CALL acct_interrupt(bc_acct)

  CALL bcs2d(nx,ny, pv_park, ebc,wbc,nbc,sbc)
  CALL acct_stop_inter

  DEALLOCATE(temp_pv_park)

  RETURN
END SUBROUTINE pvland_park_map
