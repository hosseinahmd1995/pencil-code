! $Id$
!
!  This module takes care of drag forces between particles and gas.
!
!** AUTOMATIC CPARAM.INC GENERATION ****************************
!
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: lparticles_drag = .false.
!
!***************************************************************
module Particles_drag
!
  use Cparam
  use General, only: keep_compiler_quiet
!
  implicit none
!
  include 'particles_drag.h'
!
  contains
!***********************************************************************
    subroutine register_particles_drag()
!
!  Register this module.
!
!  14-dec-14/ccyang: dummy.
!
    endsubroutine register_particles_drag
!***********************************************************************
    subroutine initialize_particles_drag()
!
!  Perform any post-parameter-read initialization, i.e., calculate
!  derived parameters.
!
!  14-dec-14/ccyang: dummy.
!
    endsubroutine initialize_particles_drag
!***********************************************************************
    subroutine read_particles_drag_run_pars(unit, iostat)
!
!  Read runtime parameters from namelist particles_drag_run_pars.
!
!  14-dec-14/ccyang: coded.
!
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat
!
      call keep_compiler_quiet(unit)
      if (present(iostat)) call keep_compiler_quiet(iostat)
!
    endsubroutine read_particles_drag_run_pars
!***********************************************************************
    subroutine write_particles_drag_run_pars(unit)
!
!  Write runtime parameters to namelist particles_drag_run_pars.
!
!  14-dec-14/ccyang: coded.
!
      integer, intent(in) :: unit
!
      call keep_compiler_quiet(unit)
!
    endsubroutine write_particles_drag_run_pars
!***********************************************************************
    subroutine integrate_drag(f, fp, ipar, ineargrid)
!
!  Wrapper for the integration of the drag force between particles and
!  gas.
!
!  16-dec-14/ccyang: dummy.
!
      real, dimension(mx,my,mz,mfarray), intent(in) :: f
      real, dimension(mpar_loc,mparray), intent(in) :: fp
      integer, dimension(mpar_loc), intent(in) :: ipar
      integer, dimension(mpar_loc,3), intent(in) :: ineargrid
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(fp)
      call keep_compiler_quiet(ipar)
      call keep_compiler_quiet(ineargrid)
!
    endsubroutine integrate_drag
!***********************************************************************
endmodule Particles_drag
