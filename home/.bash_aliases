RES=800x600

check_resolution() {

	echo -e "\nParsing resolution... (media-ctl, tvp5150)"
	tmp=$(/usr/local/bin/media-ctl -p | grep ": tvp5150 1-0020" -A 4 | grep fmt)
	tmp2=$(echo $tmp| cut -d'/' -f 2)
	tmp3=$(echo $tmp2| cut -d' ' -f 1)
	RES=$tmp3
	echo -e "\nParsed resolution=${RES}"
}

vlog-media-ctl() {
	
        if [ $# -eq 0 ]; then
                echo -e "\nchecking resolution..."
                check_resolution
                m_option=${RES}
        else    
                m_option=${1}
        fi

	#echo 8 > /proc/sys/kernel/printk
        #echo -n 'file ispccdc.c line 70-113 +p' > /sys/kernel/debug/dynamic_debug/control
        /usr/local/bin/media-ctl -r -v
        /usr/local/bin/media-ctl -l '"tvp5150 1-0020":0->"OMAP3 ISP CCDC":0[1]'
        /usr/local/bin/media-ctl -l '"OMAP3 ISP CCDC":1->"OMAP3 ISP CCDC output":0[1]'
        tmp="/usr/local/bin/media-ctl -v -V '\"tvp5150 1-0020\":0 [Y8_1X8 ${m_option} field:none]'"
	eval $tmp
	tmp="/usr/local/bin/media-ctl -v -V '\"OMAP3 ISP CCDC\":1 [Y8_1X8 ${m_option} field:none]'"
	eval $tmp

	echo -e "\nmedia-ctl configured, resolution=${m_option}"
}

vlog-yavta() {

        if [ $# -eq 0 ]; then
                echo -e "\nchecking resolution..."
		check_resolution
                yavta_option=${RES}
        else
                yavta_option=${1}
        fi

	remote="dgomez@192.168.2.83:"
        mdate=$(/bin/date +"%Y-%m-%d_%H_%M_%S");
	/usr/local/bin/yavta -f Y8 -s ${yavta_option} --field none -n 1 --capture=1 -F /dev/video2 --file=d_$mdate
        echo -e "\nimage:\nd_$mdate\n"
        /usr/bin/scp d_$mdate $remote

	echo -e "\nyavta image captured, resolution=${yavta_option}, file=d_$mdate"
}

adv_hdmi_status() {
	I2CGET=/usr/sbin/i2cget

	calculate_data_adv()
	{
		h2="$I2CGET -y -f 2 $1 $2"
		h2=`eval $h2`
		h1="$I2CGET -y -f 2 $1 $3"
		h1=`eval $h1`
		h1_1=${h1:2:2}
		h1_2=${h2:2:2}
		echo "$4: $((16#$h1_2$h1_1)) [$h1_2 $h1_1]"
		result=$((16#$h1_2$h1_1))
	}

	# WIDTH ***********************************
	#TOTAL_LINE_WIDTH[13:0], Addr 68 (HDMI), Address 0x1E[5:0]; Address 0x1F[7:0] (Read Only)
	calculate_data_adv 0x34 0x1e 0x1f TOTAL_LINE_WIDTH
	tlw=$result

	#LINE_WIDTH[12:0], Addr 68 (HDMI), Address 0x07[4:0]; Address 0x08[7:0] (Read Only)
	calculate_data_adv 0x34 0x07 0x08 LINE_WIDTH
	lw=$result

	#HSYNC_FRONT_PORCH[12:0], Addr 68 (HDMI), Address 0x20[4:0]; Address 0x21[7:0] (Read Only)
	calculate_data_adv 0x34 0x20 0x21 HSYNC_FRONT_PORCH
	hfp=$result

	#HSYNC_PULSE_WIDTH[12:0], Addr 68 (HDMI), Address 0x22[4:0]; Address 0x23[7:0] (Read Only)
	calculate_data_adv 0x34 0x22 0x23 HSYNC_PULSE_WIDTH
	hpw=$result

	#HSYNC_BACK_PORCH[12:0], Addr 68 (HDMI), Address 0x24[4:0]; Address 0x25[7:0] (Read Only)
	calculate_data_adv 0x34 0x24 0x25 HSYNC_BACK_PORCH
	hbp=$result

	#BG_LINE_WIDTH[12:0], Addr 68 (HDMI), Address 0xE2[4:0]; Address 0xE3[7:0] (Read Only)
	calculate_data_adv 0x34 0xe2 0xe3 BG_LINE_WIDTH
	blw=$result

	# HEIGHT ***********************************
	#FIELD0_TOTAL_HEIGHT[13:0], Addr 68 (HDMI), Address 0x26[5:0]; Address 0x27[7:0] (Read Only)
	calculate_data_adv 0x34 0x26 0x27 FIELD0_TOTAL_HEIGHT
	fth=$result

	#FIELD0_HEIGHT[12:0], Addr 68 (HDMI), Address 0x09[4:0]; Address 0x0A[7:0] (Read Only)
	calculate_data_adv 0x34 0x09 0x0a FIELD0_HEIGHT
	fh=$result

	#FIELD0_VS_FRONT_PORCH[13:0], Addr 68 (HDMI), Address 0x2A[5:0]; Address 0x2B[7:0] (Read Only)
	calculate_data_adv 0x34 0x2a 0x2b FIELD0_VS_FRONT_PORCH
	ffp=$result

	#FIELD0_VS_PULSE_WIDTH[13:0], Addr 68 (HDMI), Address 0x2E[5:0]; Address 0x2F[7:0] (Read Only)
	calculate_data_adv 0x34 0x2e 0x2f FIELD0_VS_PULSE_WIDTH
	fpw=$result

	#FIELD0_VS_BACK_PORCH[13:0], Addr 68 (HDMI), Address 0x32[5:0]; Address 0x33[7:0] (Read Only)
	calculate_data_adv 0x34 0x32 0x33 FIELD0_VS_BACK_PORCH
	fbp=$result
}

adv_i2c_cfg() {
	file=${1}	
	pushd /root/adv/; ./config.sh ${file}; popd;
	/usr/sbin/i2cset -y -f 2 0x20 0x03 0xc0

	echo -e "\nPARALLEL 8-bits forced, file=${file}\n\n"
}


vlog() {

        case ${1} in
                'vga')
                echo -e "\nVGA mode"
                adv_option=${RES}
		;;
		
		'hdmi')
		echo -e "\nHDMI mode" 
                adv_option=${1}
		;;

		*)
		echo -e "\nPlease select mode: hdmi or vga"
		return
		;;
	esac

	check_resolution
	vlog-adv EDID-${1,,}  # Just for testing, disable it when split is installed
	vlog-adv
	vlog-media-ctl ${RES}
	vlog-yavta ${RES}
}	

vlog-adv() {

        if [ $# -eq 0 ]; then
                echo -e "\nchecking resolution..."
                check_resolution
                adv_option=${RES}
        else
                adv_option=${1}
        fi


	echo -e "\nADV configuration started: $adv_option"
	
	case ${adv_option} in

		'EDID-vga')
		adv_i2c_cfg "8-1_EDID_Download_VGA"
		;;
		'EDID-hdmi')
		adv_i2c_cfg "8-2_EDID_Download_HDMI"
		;;
		'800x600')
		#adv_i2c_cfg "adv_cfg_vga_800x600"
		adv_i2c_cfg "5-2g_800x600@60_SVGA_RGB_in_444_24bit_H_V_DE_DVI"
		;;
		'1024x768')
		adv_i2c_cfg "5-3e_1024x768@60_XGA_RGB_in_444_24bit_H_V_DE_DVI"
		;;
		'1152x864')
		adv_i2c_cfg "5-8r_1152x864@75_RGB_in_444_24bit_H_V_DE_DVI"
		;;
		'1280x720')
		adv_i2c_cfg "5-8a_1280x720@60_RGB_in_444_24bit_H_V_DE_DVI"
		;;
		'1280x960')
		adv_i2c_cfg "5-8t_1280x960@60_RGB_in_444_24bit_H_V_DE_DVI"
		;;
		'1280x1024')
		adv_i2c_cfg "5-4d_1280x1024@60_SXGA_RGB_in_444_24bit_H_V_DE_DVI"
		;;
		'1920x1080'|'2208x1124')
		adv_i2c_cfg "5-8c_1920x1080@60_RGB_in_444_24bit_H_V_DE_DVI"
		;;
		'1600x1200')
		adv_i2c_cfg "5-5b_1600x1200@60_UXGA_RGB_in_444_24bit_H_V_DE_HDMI"
		;;
		'hdmi')
		adv_i2c_cfg "adv_cfg_gs"
		;;
		'hdmi-status')
		adv_hdmi_status
		;;
		*) echo "Invalid input"
		;;
	esac
}


vlog-res() {

        if [ $# -eq 0 ]; then
                echo -e "\nPlease, insert desired resolution"
		return
        else
                USER_H_RES=${1%x*}
		USER_V_RES=${1#*x}

		#Update resolution 
		rm -rf /etc/modules
		echo -e "# /etc/modules: kernel modules to load at boot time. \n#\n# This file contains the names of kernel modules that should be loaded\n# at boot time, one per line. Lines beginning with "#" are ignored.\n# Parameters can be specified after the module name.\ntvp5150 h_res=${USER_H_RES} v_res=${USER_V_RES} \n" | tee /etc/modules
		sync
	
		echo -e "\nPlease, reboot vlog0035 board"

        fi
}

# Usage help
usage() {
    echo "usage:   $(basename $0) -<option> <arg>"
cat <<EOF

Main options:
  -m    --mode  	     : vga or hdmi
  -r    --resolution <WxY>   : update resolution in /etc/modules
  -pr   --print-resolution   : print current resolution
  -a    --adv <mode>	     : configure adv with selected mode
  -mctl --media-ctl          : configure media-ctl automatically
  -y    --yavta              : make capture with yavta automatically

EOF
exit
}

vlogc() {
	# parse commandline options
	while [ ! -z "$1" ]; do
		case $1 in
			-h|--help)
				usage
				;;
			-m|--mode)
				vlog ${2}
				;;
			-r|--resolution)
				vlog-res ${2}
				;;
			-pr|--print-resolution)
				check_resolution
				;;
			-a|--adv)
				vlog-adv ${2}
				;;
			-mctl|--media-ctl)
				vlog-media-ctl
				;;
			-y|--yavta)
				vlog-yavta
				;;
		esac
		shift
	done
}
