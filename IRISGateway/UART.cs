using System;
using System.Collections.Generic;
using System.IO.Ports;
using System.Text;

namespace IRISGateway.UART
{
    public class UARTManager
    {

        #region CONSTANTS

        public const int BAUDRATE = 57600;
        public const int DATABITS = 8;
        public const string PORT = "COM4";

        #endregion CONSTANTS

        #region VARIABLES

        /// <summary>
        /// What COM port is used
        /// </summary>
        public string port = PORT;

        /// <summary>
        /// Rate of transmission ex. 57600
        /// </summary>
        public int baudrate = BAUDRATE;

        /// <summary>
        /// Gets or sets the standard length of data bits per byte.
        /// </summary>
        public int databits = 8;

        /// <summary>
        /// How to long to wait for input
        /// </summary>
        public int ReadTimeout;

        /// <summary>
        /// How long to wait for a read response
        /// </summary>
        public int WriteTimeout;

        /// <summary>
        /// error detection check
        /// </summary>
        public System.IO.Ports.Parity parity = Parity.None;

        /// <summary>
        /// allows for making sure the byte was receiving correctly
        /// </summary>
        public System.IO.Ports.StopBits stopBits = StopBits.One;

        /// <summary>
        /// RTC CTS flow controls
        /// </summary>
        public System.IO.Ports.Handshake handshake = Handshake.XOnXOff;

        /// <summary>
        /// The device itself
        /// </summary>
        public SerialPort serialPort;

        #endregion VARIABLES

        #region METHODS

        public UARTManager()
        {
            serialPort = new SerialPort()
            {
                PortName = PORT,
                BaudRate = BAUDRATE,
                DataBits = DATABITS,
                Parity = parity,
                StopBits = stopBits
            };
            serialPort.Handshake = handshake;
            try
            {
                serialPort.Open();
                Console.WriteLine($"UART::START::{PORT}::{BAUDRATE}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"UART::FAIL::{PORT}::{BAUDRATE}");
                Console.WriteLine(ex.StackTrace);
            }
        }

        public void Write(UARTManager _uart, byte[] sendMessage)
        {
            _uart.serialPort.DiscardOutBuffer();
            _uart.serialPort.Write(sendMessage, 0, sendMessage.Length);
        }

        public string Read(UARTManager _uart)
        {
            return _uart.serialPort.ReadLine();
        }

        #endregion METHODS
    }
}
