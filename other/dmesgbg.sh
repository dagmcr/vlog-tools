dmesg | tail -n 5000
j=`dmesg | tail -n 1`
while [ 0 -ne 1 ]; do
	k=`dmesg | tail -n 1`
	if [ "$j" != "$k" ]; then
		echo $k
		j=$k
	fi
done
