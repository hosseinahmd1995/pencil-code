pro rvid_line,field,mpeg=mpeg,tmin=tmin,tmax=tmax,max=amax,min=amin,$
  nrepeat=nrepeat,wait=wait,stride=stride,datadir=datadir,OLDFILE=OLDFILE,$
  test=test,proc=proc,exponential=exponential,map=map,tt=tt,noplot=noplot,$
  extension=extension, sqroot=sqroot, nocontour=nocontour,imgdir=imgdir, $
  squared=squared, exsquared=exsquared, against_time=against_time,func=func, $
  findmax=findmax, csection=csection,xrange=xrange, $
  transp=transp,global_scaling=global_scaling,nsmooth=nsmooth, $
  log=log,xgrid=xgrid,ygrid=ygrid,zgrid=zgrid,psym=psym, $
  xstyle=xstyle,ystyle=ystyle,fluct=fluct,newwindow=newwindow, xsize=xsize, $
  ysize=ysize,png_truecolor=png_truecolor, noexp=noexp, help=help, $
  xaxisscale=xaxisscale, normalize=normalize, quiet=quiet, _extra=_extra, single=single
;
; $Id$
;+
;  Reads in 4 slices as they are generated by the pencil code.
;  The variable "field" can be changed. Default is 'lnrho'.
;
;  if the keyword /mpeg is given, the file movie.mpg is written.
;  tmin is the time after which data are written
;  nrepeat is the number of repeated images (to slow down movie)
;
;  Typical calling sequence
;  rvid_box,'bz',tmin=190,tmax=200,min=-.35,max=.35,/mpeg
;  rvid_line,'by',proc=0,/xgrid
;  rvid_line,'XX_chiral',proc=1,/xgrid,min=0,max=1
;-
;
common pc_precision, zero, one, precision, data_type, data_bytes, type_idl
;
if (keyword_set(help)) then begin
  doc_library, 'rvid_line'
  return
endif
;
default,field,'lnrho'
default,datadir,'data'
default,imgdir,'.'
default,nrepeat,0
default,stride,0
default,tmin,0.
default,tmax,1e38
default,wait,.03
default,extension,'xy'
default,xgrid, 0
default,ygrid, 0
default,zgrid, 0
default,psym, -2
default,single, 0
default,func, ''
;
;  normalization by the rms value at each time step
;  in that case the default should be around 3.
;
if keyword_set(normalize) then default,amax,2.5 else default,amax,.05
default,amin,-amax
;
if (keyword_set(png_truecolor)) then png=1
;
; Load HDF5 slice if requested or available.
;
  if (file_test (datadir+'/slices', /directory)) then begin
    rvid_line_hdf5, field, mpeg=mpeg, tmin=tmin, tmax=tmax, max=amax, min=amin,$
        nrepeat=nrepeat, wait=wait, stride=stride, datadir=datadir, OLDFILE=OLDFILE,$
        test=test, proc=proc, exponential=exponential, map=map, tt=tt, noplot=noplot,$
        extension=extension, sqroot=sqroot, nocontour=nocontour, imgdir=imgdir, $
        squared=squared, exsquared=exsquared, against_time=against_time, func=func, $
        findmax=findmax, csection=csection, xrange=xrange, $
        transp=transp, global_scaling=global_scaling, nsmooth=nsmooth, $
        log=log,xgrid=xgrid,ygrid=ygrid,zgrid=zgrid, psym=psym, $
        xstyle=xstyle, ystyle=ystyle, fluct=fluct, newwindow=newwindow, xsize=xsize, $
        ysize=ysize, png_truecolor=png_truecolor, noexp=noexp, single=single, $
        xaxisscale=xaxisscale, normalize=normalize, quiet=quiet, _extra=_extra
    return
  end
;
; if png's are requested don't open a window
;
if (not keyword_set(png)) then begin
  if (keyword_set(newwindow)) then begin
    window, /free, xsize=xsize, ysize=ysize, title=title
  endif
endif
;
if (not check_slices_par(field, stride, arg_present(proc) ? datadir+'/proc'+str(proc) : datadir, s)) then return
;
if (not any (tag_names (s) eq strupcase (strtrim (extension,2)+'read'))) then begin
  print, "rvid_line: ERROR: slice '"+extension+"' is missing!"
  return
endif
;
if (size (proc, /type) ne 0) then begin
  file_slice=datadir+'/proc'+str(proc)+'/slice_'+field+'.'+extension
endif else begin
  file_slice=datadir+'/slice_'+field+'.'+extension
endelse
;
if not file_test(file_slice) then begin
  print, 'Slice file "'+file_slice+'" does not exist!!!'
  pos=strpos(file_slice,'.'+extension)
  compfile=strmid(file_slice,0,pos)+'1'+'.'+extension
  if file_test(compfile) then $
    print, 'Field name "'+field+'" refers to a vectorial quantity -> select component!!!'
  return
endif
;
;  Read the dimensions and precision (single or double) from dim.dat
;
pc_read_dim, obj=dim, proc=proc, datadir=datadir, /quiet
pc_set_precision, dim=dim, /quiet
;
nx=dim.nx
ny=dim.ny
nz=dim.nz
;
t=zero
islice=0
slice_z2pos=zero
;
if (extension eq 'xy') then begin
  plane=make_array(nx,ny, type=type_idl)
endif else if (extension eq 'xz') then begin
  plane=make_array(nx,nz, type=type_idl)
endif else if (extension eq 'yz') then begin
  plane=make_array(ny,nz, type=type_idl)
endif
if (keyword_set(global_scaling)) then begin
  amax=!Values.F_NaN & amin=amax
  if (not keyword_set (quiet)) then print, 'Reading "'+file_slice+'".'
  openr, lun, file_slice, /f77, /get_lun
  while (not eof(lun)) do begin
    if (keyword_set(OLDFILE)) then begin ; For files without position
      readu, lun, plane, t
    endif else begin
      readu, lun, plane, t, slice_z2pos
    endelse
    if (keyword_set(exponential)) then begin
      amax=max([amax,exp(max(float(plane)))], /NaN)
      amin=min([amin,exp(min(float(plane)))], /NaN)
    endif else if (keyword_set(sqroot)) then begin
      amax=max([amax,sqrt(max(float(plane)))], /NaN)
      amin=min([amin,sqrt(min(float(plane)))], /NaN)
    endif else if (keyword_set(log)) then begin
      amax=max([amax,alog(max(float(plane)))], /NaN)
      amin=min([amin,alog(min(float(plane)))], /NaN)
    endif else begin
      amax=max([amax,max(float(plane))], /NaN)
      amin=min([amin,min(float(plane))], /NaN)
    endelse
  end
  close, lun
  free_lun, lun
  if (not keyword_set (quiet)) then print, 'Scale using global min, max: ', amin, amax
endif
;
pc_read_grid, object=grid, proc=proc, dim=dim, datadir=datadir, /trim, quiet=quiet, single=single
;
if (xgrid) then begin
  xaxisscale=grid.x
endif else if (ygrid) then begin
  xaxisscale=grid.y
endif else if (zgrid) then begin
  xaxisscale=grid.z
endif else begin
  xaxisscale=findgen(max([nx,ny,nz]))
endelse
;
;  open MPEG file, if keyword is set
;
dev='x' ;(default)
if (keyword_set(png)) then begin
  set_plot, 'z'                   ; switch to Z buffer
  device, SET_RESOLUTION=[!d.x_size,!d.y_size] ; set window size
  itpng=0 ;(image counter)
  dev='z'
endif else if (keyword_set(mpeg)) then begin
  ;Nwx=400
  ;Nwy=320
  Nwx=!d.x_size
  Nwy=!d.y_size
  if (!d.name eq 'X') then window,2,xs=Nwx,ys=Nwy
  mpeg_name = 'movie.mpg'
  if (not keyword_set (quiet)) then print,'write mpeg movie: ',mpeg_name
  mpegID = mpeg_open([Nwx,Nwy],FILENAME=mpeg_name)
  itmpeg=0 ;(image counter)
endif
;
;  allow for skipping "stride" time slices
;  initialize counter
;
istride=stride ;(make sure the first one is written)
;
it=0
if (not keyword_set (quiet)) then print, 'Reading "'+file_slice+'".'
openr, lun, file_slice, /f77, /get_lun
while (not eof(lun)) do begin
  if (keyword_set(OLDFILE)) then begin ; For files without position
    readu, lun, plane, t
  endif else begin
    readu, lun, plane, t, slice_z2pos
  endelse
;
  if (single) then begin
    plane=float(plane) & t=float(t)
  endif
  if (keyword_set(transp)) then plane=transpose(plane)
  default,csection,((size(plane))[2]+1)/2
  plane=reform(plane)
  if ((size(plane))[0] gt 1) then begin
    plane=reform(plane[*,csection])
  endif
  if (keyword_set(sqroot)) then plane=sqrt(plane)
  if (keyword_set(log)) then plane=alog(plane)
  if (keyword_set(squared)) then plane=plane^2
  if (keyword_set(exsquared)) then plane=exp(plane)^2
  if (keyword_set(nsmooth)) then plane=smooth(plane,nsmooth)
  if (keyword_set(fluct)) then plane=plane-mean(plane)
  if (keyword_set(normalize)) then plane=plane/sqrt(mean(plane^2))
  if (func ne '') then begin
    value=plane    ; duplication needed?
    res=execute('plane='+func,1)
  endif
;
  if (keyword_set(findmax)) then begin
    ; [PABourdin]: the parameter 'findmax' has no function in the rest of the code, yet!
    ; [PABourdin]: the 'findshock' procedure does not exist in the PC! Therfore commented:
    ;findshock,plane,xaxisscale,leftpnt=leftpnt,rightpnt=rightpnt
    ;if (it eq 0) then begin
    ;  max_left=leftpnt
    ;  max_right=rightpnt
    ;endif else begin
    ;  max_left=[max_left, leftpnt]
    ;  max_right=[max_right, rightpnt]
    ;endelse
  endif
;
  if (it eq 0) then tt=t else tt=[tt,t]
  if (it eq 0) then map=plane else map=[map,plane]
  it=it+1L
;
  if (keyword_set(test)) then begin
    if (not keyword_set(noplot) and not keyword_set (quiet)) then $
        print,t,min([plane,xy,xz,yz]),max([plane,xy,xz,yz])
  endif else begin
    if (t ge tmin and t le tmax) then begin
      if (istride eq stride) then begin
        if (not keyword_set(noplot)) then begin
          if (keyword_set(exponential)) then begin
            plot, xaxisscale, exp(plane), psym=psym, yrange=[amin,amax], _extra=_extra, $
                xstyle=xstyle,ystyle=ystyle,xrange=xrange
          endif else begin
            plot, xaxisscale, plane, psym=psym, yrange=[amin,amax], _extra=_extra, $
                xstyle=xstyle,ystyle=ystyle,xrange=xrange
          endelse
        endif
        if (keyword_set(png)) then begin
          istr2 = string(itpng,'(I4.4)') ; maximum 9999 frames
          image = tvrd()
;
;  make background white, and write png file
;
          ;bad=where(image eq 0, num)
          ;if (num gt 0) then image(bad)=255
          tvlct, red, green, blue, /GET
          imgname = imgdir+'/img_'+istr2+'.png'
          write_png, imgname, image, red, green, blue
          itpng=itpng+1 ;(counter)
;
        endif else if (keyword_set(mpeg)) then begin
;
;  write directly mpeg file
;  for idl_5.5 and later this requires the mpeg license
;
          image = tvrd(true=1)
          for irepeat=0,nrepeat do begin
            mpeg_put, mpegID, window=2, FRAME=itmpeg, /ORDER
            itmpeg=itmpeg+1 ;(counter)
          end
          if (not keyword_set (quiet)) then print,islice,itmpeg,t,min([plane]),max([plane])
        endif else begin
;
; default: output on the screen
;
          if (not keyword_set(noplot) and not keyword_set (quiet)) then print,islice,t,min([plane]),max([plane])
        endelse
        istride=0
        wait,wait
;
; check whether file has been written
;
        if (keyword_set(png)) then spawn,'ls -l '+imgname
;
      endif else begin
        istride=istride+1
      endelse
    endif
    islice=islice+1
  endelse
endwhile
close, lun
free_lun, lun
;
;  write & close mpeg file
;
if (keyword_set(mpeg)) then begin
  if (not keyword_set (quiet)) then print,'Writing MPEG file..'
  mpeg_save, mpegID, FILENAME=mpeg_name
  mpeg_close, mpegID
endif
;
;  reform map appropriately
;
nxz=n_elements(plane)
nt=it
map=reform(map,nxz,nt)
;
if (not keyword_set(nocontour)) then begin
  if (keyword_set(against_time)) then begin
    if (keyword_set(noexp)) then begin
      contour, transpose(map), tt, xaxisscale, /fill, nlev=60,ys=1,xs=1
    endif else begin
      contour, transpose(exp(map)), tt, xaxisscale, /fill, nlev=60,ys=1,xs=1
    endelse
  endif else begin
    if (keyword_set(noexp)) then begin
      contour, transpose(map), /fill, nlev=60,ys=1,xs=1
    endif else begin
      contour, transpose(exp(map)), /fill, nlev=60,ys=1,xs=1
    endelse
  endelse
endif
;
END
