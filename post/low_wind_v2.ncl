; Example script to produce plots for a WRF real-data run,
; with the ARW coordinate dynamics option.
; Plot data on a cross section
; This script will plot data at a set angle through a specified point
; This script adds lon/lat info along X-axis
loadscript("./cd_inv_string.ncl")
loadscript("./cd_string.ncl")
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
begin
;
; The WRF ARW input file.
; This needs to have a ".nc" appended, so just do it.
WRFdir = "/magma-dirs/jas983/wrf_data/eas5555/wrfwrk/ARW/NYpvow_A5Dx3D/2011jan23-24/wrfrun_r1bl5cu300ls2/"
WRFfile = "wrfout_NYpvow_A5Dx3D_d03_2011-01-24_01:00:00"

if (fileexists(WRFdir+WRFfile)) then
         a = addfile(WRFdir+WRFfile, "r")
else
         print("")
         print("The WRF file "+WRFdir+WRFfile+" does not exist. Check your path.")
         print("")
     exit
end if

; We generate plots, but what kind do we prefer?
; type = "x11"
type = "png"
; type = "pdf"
; type = "ps"
; type = "ncgm"
wks = gsn_open_wks(type,"plt_CrossSection4")
; Set some basic resources
res = True
res@MainTitle = "REAL-TIME WRF"
res@Footer = False
pltres = True

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FirstTime = True
FirstTimeMap = True
times = wrf_user_getvar(a,"times",-1)   ; get times in the file
ntimes = dimsizes(times)                ; number of times in the file
mdims = getfilevardimsizes(a,"P")       ; get some dimension sizes for the file
nd = dimsizes(mdims)
xlat = wrf_user_getvar(a, "XLAT",0)
xlon = wrf_user_getvar(a, "XLONG",0)
ter = wrf_user_getvar(a, "HGT",0)

;---------------------------------------------------------------
do it = 0,ntimes-1,24                   ; TIME LOOP
print("Working on time: " + times(it) )
res@TimeLabel = times(it)               ; Set Valid time to use on plots
tc = wrf_user_getvar(a,"tc",it)         ; T in C
u  = wrf_user_getvar(a,"ua",it)          ; U wind component
printVarSummary(u)
v  = wrf_user_getvar(a,"va",it)          ; V wind component
printVarSummary(v)
wind = sqrt(u^2+v^2)                    ; relative humidity
printVarSummary(wind)
printMinMax(wind,0)
z = wrf_user_getvar(a, "z",it)          ; grid point height
printVarSummary(z)

; Format the time to EST
time_numeric = cd_inv_string( times(it), "%Y-%N-%D_%H:%M:%S")  ;; will return in hours since 1800-01-01 unless specified otherwise
offset = 5                                  ; hours
time_numeric = time_numeric - offset
time_str = cd_string( time_numeric, "%c %D, %Y %H:%M")

if ( FirstTime ) then                   ; get height info for labels
zmin = 0.
zmax = 1.                               ; We are only interested in the first 1km
nz = floattoint(zmax + 1)
end if
;---------------------------------------------------------------
;do ip = 1, 3 ; we are doing 3 plots
ip = 3
; all with the pivot point (plane) in the center of the domain
; at angles 0, 45 and 90
;
; |
; angle=0 is |
; |
;
plane = new(2,float)
plane = (/ mdims(nd-1)/2, mdims(nd-2)/2 /) ; pivot point is center of domain (x,y)
opts = False
if(ip .eq. 1) then
angle = 90.
X_plane = wrf_user_intrp2d(xlon,plane,angle,opts)
X_desc = "longitude"
end if
if(ip .eq. 2) then
angle = 0.
X_plane = wrf_user_intrp2d(xlat,plane,angle,opts)
X_desc = "latitude"
end if
if(ip .eq. 3) then
angle = 45.
X_plane = wrf_user_intrp2d(xlon,plane,angle,opts)
X_desc = "longitude"
end if
wind_plane = wrf_user_intrp3d(wind,z,"v",plane,angle,opts)
tc_plane = wrf_user_intrp3d(tc,z,"v",plane,angle,opts)

; Find the index where zmax km is - only need to do this once
if ( FirstTime ) then
zz = wrf_user_intrp3d(z,z,"v",plane,angle,opts)
b = ind(zz(:,0) .gt. zmax*1000. )
zmax_pos = b(0) - 1
if ( abs(zz(zmax_pos,0)-zmax*1000.) .lt. abs(zz(zmax_pos+1,0)-zmax*1000.) ) then
zspan = b(0) - 1
else
zspan = b(0)
end if
delete(zz)
delete(b)
FirstTime = False
end if

; X-axis lables
dimsX = dimsizes(X_plane)
xmin = X_plane(0)
xmax = X_plane(dimsX(0)-1)
xspan = dimsX(0)-1
nx = floattoint( (xmax-xmin)/2 + 1)

;---------------------------------------------------------------
; Options for XY Plots
opts_xy = res
opts_xy@tiXAxisString = X_desc
opts_xy@tiYAxisString = "Height (km)"
opts_xy@cnMissingValPerimOn = True
opts_xy@cnMissingValFillColor = 0
opts_xy@cnMissingValFillPattern = 11
opts_xy@tmXTOn = False
opts_xy@tmYROn = False
opts_xy@tmXBMode = "Explicit"
; opts_xy@tmXBValues = fspan(0,xspan,nx) ; Create tick marks
; opts_xy@tmXBLabels = sprintf("%.1f",fspan(xmin,xmax,nx)) ; Create labels
opts_xy@tmXBLabelFontHeightF = 0.015
opts_xy@tmYLMode = "Explicit"
opts_xy@tmYLValues = fspan(0,zspan,nz)                      ; Create tick marks
opts_xy@tmYLLabels = sprintf("%.1f",fspan(zmin,zmax,nz))    ; Create labels
opts_xy@tiXAxisFontHeightF = 0.020
opts_xy@tiYAxisFontHeightF = 0.020
opts_xy@tmXBMajorLengthF = 0.02
opts_xy@tmYLMajorLengthF = 0.02
opts_xy@tmYLLabelFontHeightF = 0.015
opts_xy@PlotOrientation = tc_plane@Orientation

; Plotting options for wind
cmap = read_colormap_file("MPL_YlGnBu")               ;-- so we can subset later
opts_wind = opts_xy
;opts_wind@ContourParameters = (/ 10., 90., 10. /)
opts_wind@pmLabelBarOrthogonalPosF = -0.1
opts_wind@cnFillOn               = True 
opts_wind@cnSpanFillPalette      = True
opts_wind@cnLevelSelectionMode   = "ManualLevels"
opts_wind@cnMinLevelValF         = 3.               ;-- set min contour level
opts_wind@cnMaxLevelValF         = 30.              ;-- set max contour level
opts_wind@cnLevelSpacingF        = 3;
;res@cnMaxLevelCount        = 30                       ;-- maximum contour level count  
;res@cnLevelSelectionMode   = "EqualSpacedLevels"      ;-- color fill  
opts_wind@cnFillPalette          = cmap(:,:)          ;-- subset the color map
opts_wind@lbTitleString          = "Wind Speed (m/s)"
opts_wind@lbTitleOffsetF         = -0.35
opts_wind@lbTitleFontHeightF     = 0.02
opts_wind@lbLabelFontHeightF     = 0.015
;opts_wind@gsnLeftString          = ""                 ;-- do not draw the left sub-title (otherwise automatically set)
;opts_wind@gsnRightString         = time_str                 ;-- do not draw the right sub-title (otherwise automatically set)
;opts_wind@gsnCenterString        = time_str           ;-- write time to center string
;opts_wind@gsnCenterStringOrthogonalPosF = 0.02        ;-- move center string upwards


; Plotting options for Temperature
opts_tc = opts_xy
opts_tc@cnInfoLabelZone = 1
opts_tc@cnInfoLabelSide = "Top"
opts_tc@cnInfoLabelPerimOn = True
opts_tc@cnInfoLabelOrthogonalPosF = -0.00005
opts_tc@ContourParameters = (/ 3. /)

; Get the contour info for the wind and temp
contour_tc = wrf_contour(a,wks,tc_plane(0:zmax_pos,:),opts_tc)
contour_wind = wrf_contour(a,wks,wind_plane(0:zmax_pos,:),opts_wind)

;---------------------------------------------------------------
; MAKE PLOTS
if (FirstTimeMap) then
lat_plane = wrf_user_intrp2d(xlat,plane,angle,opts)
lon_plane = wrf_user_intrp2d(xlon,plane,angle,opts)
mpres = True
pltres = True
pltres@gsnLeftString 	     = ""            ; do not draw the left sub-title (otherwise automatically set)
pltres@FramePlot = False
optsM = res
optsM@NoHeaderFooter = True
optsM@cnFillOn = True
;optsM@lbTitleOn = False
optsM@lbLabelOffsetF 	     = -0.4
optsM@lbTitleString          = "Terrain Height (m)"
optsM@lbTitleOffsetF         = -0.6
optsM@lbTitleFontHeightF     = 0.02
optsM@lbLabelFontHeightF     = 0.015
;optsM@lbLabelOffsetF	     = -0.4
contour = wrf_contour(a,wks,ter,optsM)
plot = wrf_map_overlays(a,wks,(/contour/),pltres,mpres)

lnres = True
lnres@gsLineThicknessF = 3.0
lnres@gsLineColor = "Red"
do ii = 0,dimsX(0)-2
gsn_polyline(wks,plot,(/lon_plane(ii),lon_plane(ii+1)/),(/lat_plane(ii),lat_plane(ii+1)/),lnres)
end do
frame(wks)
delete(lon_plane)
delete(lat_plane)
pltres@FramePlot = True
end if
plot = wrf_overlays(a,wks,(/contour_wind,contour_tc/),pltres) ; plot x-section

; Delete options and fields, so we don't have carry over
delete(opts_xy)
delete(opts_tc)
delete(opts_wind)
delete(tc_plane)
delete(wind_plane)
delete(X_plane)

;end do ; make next cross section

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FirstTimeMap = False
end do ; END OF TIME LOOP
end