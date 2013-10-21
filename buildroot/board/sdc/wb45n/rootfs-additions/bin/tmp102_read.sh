#Read the temperture from the TI TMP102 tmp sensor
rawValue="$(i2cget -y 0 0x48 0 w)"

#Format the 12-bit value
msb=$(($(($rawValue & 0xFF))<<4))
lsb=$(((($rawValue>>12)) & 0x0F))

#Calculate the reading
meas=$(($msb+$lsb))          

#Adjust if we have a negative reading (2's complement)
if [ $(($msb & 0x800)) -eq 0 ] ; then
  degC=$(($meas/16))           
else                                 
  degC=$(($(($meas + 0xFFFFF000))/16))
fi

#Echo out the output in degrees Celcius
echo $degC*C                                

