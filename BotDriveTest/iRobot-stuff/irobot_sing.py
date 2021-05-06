import serial
from time import sleep

# Open the serial port to communicate with iris gateway
# default port is /dev/ttyUSB1, but it can cange based on
# which port was avaliable when you plugged in the device.
# 57600 is the default serial speed.
ser = serial.Serial('/dev/ttyUSB1', 57600, bytesize=8, parity='N', stopbits=1, timeout=None, xonxoff=0, rtscts=0)
print ser.name

# Send serial command that the iRobot can understand check
# the "iRobot Create Open Interface_v2.pdf" for more info
# the commands that can be used to control the robot.

ser.write(chr(128)) # 128 is Start command
ser.write(chr(131)) # 131 is Safe mode command
ser.write(chr(140))
ser.write(chr(0))
ser.write(chr(4))
ser.write(chr(62))
ser.write(chr(12))
ser.write(chr(66))
ser.write(chr(12))
ser.write(chr(69))
ser.write(chr(12))
ser.write(chr(74))
ser.write(chr(36))
ser.write(chr(141))
ser.write(chr(0))

# close the serial port
ser.close
