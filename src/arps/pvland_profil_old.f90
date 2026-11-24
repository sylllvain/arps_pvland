!##################################################################
!##################################################################
!######                                                      ######
!######               SUBROUTINE compute_U_plus              ######
!######                                                      ######
!##################################################################
!##################################################################

subroutine compute_U_plus(z, theta, a, beta_deg, L, clearance, theta_0, Uplus)

!============================================================
! Purpose:
! --------
! Compute the dimensionless velocity U+ at height z, accounting
! for whether the point lies above or within the PV canopy.
!
! Inputs:
! -------
! z         : vertical coordinate above ground [m]
! theta     : wind direction angle [rad]
! a         : row spacing between PV panels [m]
! beta_deg  : PV panel tilt angle [degrees]
! L         : PV panel length [m]
! clearance : clearance height below the panel [m]
! theta_0   : park orientation angle [rad]
!
! Output:
! -------
! Uplus     : dimensionless velocity U+ [-]
!============================================================

  implicit none

  !-------------------------
  ! Input variables
  !-------------------------
  real, intent(in)  :: z          ! Height above ground [m]
  real, intent(in)  :: theta      ! Wind direction [rad]
  real, intent(in)  :: a          ! Row spacing [m]
  real, intent(in)  :: beta_deg   ! Panel tilt angle [deg]
  real, intent(in)  :: L          ! Panel length [m]
  real, intent(in)  :: clearance  ! Ground clearance [m]
  real, intent(in)  :: theta_0    ! Park orientation angle [rad]

  !-------------------------
  ! Output variable
  !-------------------------
  real, intent(out) :: Uplus      ! Dimensionless velocity [-]

  !-------------------------
  ! Local constants
  !-------------------------
  real, parameter :: pi = 3.141592653589793  ! Pi [-]

  !-------------------------
  ! Local variables
  !-------------------------
  real :: beta       ! Panel tilt angle [rad]
  real :: h_PV       ! Effective canopy height [m]
  real :: lambda_f   ! Frontal density parameter [-]

  ! Convert tilt angle from degrees to radians
  beta = beta_deg * pi / 180.0

  ! Compute effective PV height
  h_PV = L * sin(beta) + clearance

  ! Compute frontal density parameter
  call compute_lambda_f(a, L, beta, lambda_f)

  ! Select velocity profile depending on height
  if (z >= h_PV) then
     call U_above(z, theta, lambda_f, h_PV, beta_deg, theta_0, Uplus)
  else
     call U_within(z, theta, lambda_f, h_PV, beta_deg, theta_0, Uplus)
  endif

end subroutine compute_U_plus


!============================================================
! SUBROUTINE: compute_lambda_f
!
! Purpose:
! --------
! Compute the frontal density parameter lambda_f.
!
! Inputs:
! -------
! a     : row spacing [m]
! L     : panel length [m]
! beta  : panel tilt angle [rad]
!
! Output:
! -------
! lambda_f : frontal density parameter [-]
!============================================================
subroutine compute_lambda_f(a, L, beta, lambda_f)
  implicit none

  real, intent(in)  :: a        ! Row spacing [m]
  real, intent(in)  :: L        ! Panel length [m]
  real, intent(in)  :: beta     ! Tilt angle [rad]
  real, intent(out) :: lambda_f ! Frontal density [-]

  lambda_f = (L * sin(beta)) / (a + L * cos(beta))
end subroutine compute_lambda_f


!============================================================
! SUBROUTINE: alpha1_lambda
!
! Purpose:
! --------
! Compute coefficient alpha1 as a function of lambda_f.
!
! Input:
! ------
! lambda_f : frontal density [-]
!
! Output:
! -------
! alpha1   : displacement scaling coefficient [-]
!============================================================
subroutine alpha1_lambda(lambda_f, alpha1)
  implicit none

  real, intent(in)  :: lambda_f ! Frontal density [-]
  real, intent(out) :: alpha1   ! Coefficient [-]

  real, parameter :: alpha_inf = 0.95 / (3.38 + 1.0) ! Asymptotic value [-]
  real, parameter :: lambda_c  = 0.48                ! Transition density [-]

  alpha1 = (alpha_inf - 0.15) * lambda_f**2 / &
           (lambda_f**2 + lambda_c**2) + 0.15
end subroutine alpha1_lambda


!============================================================
! SUBROUTINE: A1_gamma
!
! Purpose:
! --------
! Compute the asymmetric gamma-like coefficient A1(lambda_f).
!
! Input:
! ------
! lambda_f : frontal density [-]
!
! Output:
! -------
! A1       : directional amplitude coefficient [-]
!============================================================
subroutine A1_gamma(lambda_f, A1)
  implicit none

  real, intent(in)  :: lambda_f ! Frontal density [-]
  real, intent(out) :: A1       ! Amplitude coefficient [-]

  real, parameter :: lambda_peak = 0.2   ! Peak density [-]
  real, parameter :: p = 0.3             ! Shape parameter [-]
  real, parameter :: xpt = 0.204         ! Reference x-point [-]
  real, parameter :: ypt = 0.138         ! Reference y-point [-]

  real :: q       ! Exponential decay factor [-]
  real :: h_xpt   ! Normalization helper [-]
  real :: A1_max  ! Maximum amplitude [-]

  if (lambda_f <= 0.0) then
     A1 = 0.0
     return
  endif

  q = p / lambda_peak
  h_xpt = (xpt / lambda_peak)**p * exp(-q * (xpt - lambda_peak))
  A1_max = ypt / h_xpt

  A1 = A1_max * (lambda_f / lambda_peak)**p * &
       exp(-q * (lambda_f - lambda_peak))
end subroutine A1_gamma


!============================================================
! SUBROUTINE: d_theta
!
! Purpose:
! --------
! Compute the displacement height d as a function of wind
! direction and canopy geometry.
!
! Inputs:
! -------
! theta     : wind direction [rad]
! lambda_f  : frontal density [-]
! h_PV      : canopy height [m]
!
! Output:
! -------
! d         : displacement height [m]
!============================================================
subroutine d_theta(theta, lambda_f, h_PV, theta_0, d)
  implicit none

  real, intent(in)  :: theta     ! Wind direction [rad]
  real, intent(in)  :: lambda_f  ! Frontal density [-]
  real, intent(in)  :: h_PV      ! Canopy height [m]
  real, intent(in)  :: theta_0   ! Park orientation angle [rad]
  real, intent(out) :: d         ! Displacement height [m]

  real, parameter :: A = 3.38 ! Empirical constant [-]

  real :: alpha1 ! Scaling coefficient [-]

  call alpha1_lambda(lambda_f, alpha1)

  d = alpha1 * (A * cos(theta - theta_0)**2 + 1.0) * h_PV
end subroutine d_theta


!============================================================
! SUBROUTINE: r_beta
!
! Purpose:
! --------
! Compute the asymmetry ratio r as a function of panel tilt.
!
! Input:
! ------
! beta_deg : panel tilt angle [deg]
!
! Output:
! -------
! r        : asymmetry ratio [-]
!============================================================
subroutine r_beta(beta_deg, r)
  implicit none

  real, intent(in)  :: beta_deg ! Tilt angle [deg]
  real, intent(out) :: r        ! Ratio [-]

  r = 1.70195e-7 * beta_deg**4 - 3.06351e-5 * beta_deg**3 + &
      2.19236e-3 * beta_deg**2 - 7.32403e-2 * beta_deg + 1.0
end subroutine r_beta


!============================================================
! SUBROUTINE: beta_theta
!
! Purpose:
! --------
! Compute the directional beta coefficient used in roughness
! length estimation.
!
! Inputs:
! -------
! theta     : wind direction [rad]
! lambda_f  : frontal density [-]
! beta_deg  : panel tilt angle [deg]
!
! Output:
! -------
! beta_t    : directional beta coefficient [-]
!============================================================
subroutine beta_theta(theta, lambda_f, beta_deg, theta_0, beta_t)
  implicit none

  real, intent(in)  :: theta, lambda_f, beta_deg, theta_0
  real, intent(out) :: beta_t

  real, parameter :: C = 8.72e-2
  real, parameter :: pi = 3.141592653589793

  real :: A1, r
  real :: term1, term2

  call A1_gamma(lambda_f, A1)
  call r_beta(beta_deg, r)

  term1 = max(cos(theta - theta_0), 0.0)**2
  term2 = max(cos(theta - theta_0 - pi), 0.0)**2

  beta_t = A1 * term1 + A1 * r * term2 + C
end subroutine beta_theta


!============================================================
! SUBROUTINE: z0_theta
!
! Purpose:
! --------
! Compute the aerodynamic roughness length z0.
!
! Inputs:
! -------
! theta     : wind direction [rad]
! lambda_f  : frontal density [-]
! h_PV      : canopy height [m]
! beta_deg  : panel tilt angle [deg]
!
! Output:
! -------
! z0        : roughness length [m]
!============================================================
subroutine z0_theta(theta, lambda_f, h_PV, beta_deg, theta_0, z0)
  implicit none

  real, intent(in)  :: theta, lambda_f, h_PV, beta_deg, theta_0
  real, intent(out) :: z0

  real, parameter :: kappa = 0.387 ! von Kármán constant [-]

  real :: z_m     ! Mixing height [m]
  real :: d       ! Displacement height [m]
  real :: beta_t  ! Directional beta [-]

  z_m = 3.26 * h_PV

  call d_theta(theta, lambda_f, h_PV, theta_0, d)
  call beta_theta(theta, lambda_f, beta_deg, theta_0, beta_t)

  z0 = (z_m - d) * exp(-kappa / beta_t)
end subroutine z0_theta


!============================================================
! SUBROUTINE: c1_theta
!
! Purpose:
! --------
! Compute coefficient c1 controlling wake effects above canopy.
!
! Input:
! ------
! theta : wind direction [rad]
!
! Output:
! -------
! c1    : wake coefficient [-]
!============================================================
subroutine c1_theta(theta, theta_0, c1)
  implicit none

  real, intent(in)  :: theta
  real, intent(in)  :: theta_0
  real, intent(out) :: c1

  real :: val

  val = 0.28 * exp(1.51 * cos(theta - theta_0)) + &
        0.18 * exp(1.51 * cos(theta - theta_0 - 3.141592653589793)) - 0.61

  c1 = max(val, 0.0)
end subroutine c1_theta


!============================================================
! SUBROUTINE: c3_theta
!
! Purpose:
! --------
! Compute coefficient c3 controlling exponential decay inside
! the canopy.
!
! Inputs:
! -------
! theta     : wind direction [rad]
! lambda_f  : frontal density [-]
!
! Output:
! -------
! c3        : decay coefficient [-]
!============================================================
subroutine c3_theta(theta, lambda_f, theta_0, c3)
  implicit none

  real, intent(in)  :: theta, lambda_f, theta_0
  real, intent(out) :: c3

  c3 = (5.0 * lambda_f) / (0.48 * cos(theta - theta_0) + 1.0)
end subroutine c3_theta


!============================================================
! SUBROUTINE: alpha_w
!
! Purpose:
! --------
! Compute weighting factor between logarithmic and exponential
! profiles inside the canopy.
!
! Input:
! ------
! lambda_f : frontal density [-]
!
! Output:
! -------
! w        : weighting factor [0Ã¢â‚¬â€œ1]
!============================================================
subroutine alpha_w(lambda_f, w)
  implicit none

  real, intent(in)  :: lambda_f
  real, intent(out) :: w

  w = lambda_f**3 / (lambda_f**3 + 0.04**3)
end subroutine alpha_w


!============================================================
! SUBROUTINE: expint_E1
!
! Purpose:
! --------
! Compute the exponential integral E1(x).
!
! Input:
! ------
! x   : argument (x > 0) [-]
!
! Output:
! -------
! res : exponential integral E1(x) [-]
!============================================================
subroutine expint_E1(x, res)
  implicit none

  real, intent(in)  :: x
  real, intent(out) :: res

  real, parameter :: gamma = 0.5772156649015328606
  real :: term, sum
  integer :: k

  if (x <= 0.0) then
     res = huge(res)
     return
  endif

  if (x <= 1.0) then
     sum = 0.0
     term = 1.0

     do k = 1, 100
        term = -term * x / real(k)
        sum  = sum + term / real(k)
        if (abs(term) < 1.0e-7) exit
     enddo

     res = -log(x) - gamma - sum
  else
     term = 1.0
     sum  = 1.0

     do k = 1, 20
        term = -term * real(k) / x
        sum  = sum + term
     enddo

     res = exp(-x) * sum / x
  endif
end subroutine expint_E1


!============================================================
! SUBROUTINE: U_above
!
! Purpose:
! --------
! Compute the dimensionless velocity profile above the canopy.
!
! Inputs:
! -------
! z         : height above ground [m]
! theta     : wind direction [rad]
! lambda_f  : frontal density [-]
! h_PV      : canopy height [m]
! beta_deg  : panel tilt angle [deg]
!
! Output:
! -------
! U         : dimensionless velocity [-]
!============================================================
subroutine U_above(z, theta, lambda_f, h_PV, beta_deg, theta_0, U)
  implicit none

  real, intent(in)  :: z, theta, lambda_f, h_PV, beta_deg, theta_0
  real, intent(out) :: U

  real, parameter :: kappa = 0.387
  real, parameter :: c2 = 0.17

  real :: d, z0, c1
  real :: arg, E1

  call d_theta(theta, lambda_f, h_PV, theta_0, d)
  call z0_theta(theta, lambda_f, h_PV, beta_deg, theta_0, z0)
  call c1_theta(theta, theta_0, c1)

  arg = (c2 / (4.0 * (h_PV - d)**2)) * (z - d)
  call expint_E1(arg, E1)

  U = (1.0 / kappa) * (log((z - d) / z0) + c1 * exp(-c2 / 2.0) * E1)
end subroutine U_above


!============================================================
! SUBROUTINE: U_within
!
! Purpose:
! --------
! Compute the dimensionless velocity profile within the canopy.
!
! Inputs:
! -------
! z         : height above ground [m]
! theta     : wind direction [rad]
! lambda_f  : frontal density [-]
! h_PV      : canopy height [m]
! beta_deg  : panel tilt angle [deg]
!
! Output:
! -------
! U         : dimensionless velocity [-]
!============================================================
subroutine U_within(z, theta, lambda_f, h_PV, beta_deg, theta_0, U)
  implicit none

  real, intent(in)  :: z, theta, lambda_f, h_PV, beta_deg, theta_0
  real, intent(out) :: U

  real :: U_h      ! Velocity at canopy top [-]
  real :: w        ! Weighting factor [-]
  real :: d_par    ! Displacement height (perpendicular) [m]
  real :: z0_par   ! Roughness length (perpendicular) [m]
  real :: log_part ! Logarithmic contribution [-]
  real :: exp_part ! Exponential contribution [-]
  real :: c3       ! Decay coefficient [-]

  call U_above(h_PV, theta, lambda_f, h_PV, beta_deg, theta_0, U_h)
  call alpha_w(lambda_f, w)

  w = w * cos(theta - theta_0)**2

  call d_theta(theta_0 + 3.141592653589793 / 2.0, lambda_f, h_PV, theta_0, d_par)
  call z0_theta(theta_0 + 3.141592653589793 / 2.0, lambda_f, h_PV, beta_deg, theta_0, z0_par)
  call c3_theta(theta, lambda_f, theta_0, c3)

  log_part = log((z - d_par) / z0_par) / log((h_PV - d_par) / z0_par)
  exp_part = exp(-c3 * (1.0 - z / h_PV))

  U = (1.0 - w) * U_h * log_part + w * U_h * exp_part
end subroutine U_within
