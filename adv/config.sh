while read line; do    
    #echo $line
    addr=${line:3:2} 
    reg=${line:6:2}
    value=${line:12:2}
    addr1=0x$addr
    addr2=`printf "%d\n" $addr1`
    addr_write_dec=`expr $addr2 / 2`
    addr_write_hex=`printf "%02X\n" $addr_write_dec`
    #echo i2cset -f -y 2 0x$addr_write_hex 0x$reg 0x$value
    sudo /usr/sbin/i2cset -f -y 2 0x$addr_write_hex 0x$reg 0x$value
    #sleep 0.1
done < $1 
