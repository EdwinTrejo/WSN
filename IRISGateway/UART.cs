using IRISGateway.IRIS;
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

        public IRISMsg Read(UARTManager _uart)
        {
            //_uart.serialPort.DiscardInBuffer();
            IRISMsg _mssg = new IRISMsg() { NODEID = 4 };
            try
            {
                _mssg = CleanString(_uart.serialPort.ReadLine());
            }
            catch (Exception ex)
            {
                Console.WriteLine("UART::RX::ERROR");
            }
            return _mssg;
        }

        private IRISMsg CleanString(string _str)
        {
            StringBuilder _strbldr = new StringBuilder();
            foreach (char _chr in _str)
            {
                if ((_chr >= '0' && _chr <= '9') /*|| (_chr >= 'A' && _chr <= 'Z')*/ || (_chr == ','))
                {
                    _strbldr.Append(_chr);
                }
            }
            string _clean_str = _strbldr.ToString();
            IRISMsg _iris_msg;
            try
            {
                _iris_msg = ProcessLine(_clean_str);
                Console.WriteLine($"{_iris_msg.NODEID}, {_iris_msg.LIGHT}, {_iris_msg.RSSI}");
                return _iris_msg;
            } catch (Exception ex)
            {
                Console.WriteLine("UART::RX::ERROR");
                return null;
            }
        }

        private IRISMsg ProcessLine(string _str)
        {
            string[] parts = _str.Split(',');
            if (parts.Length != 3) throw new InvalidCastException();
            IRISMsg _msg = new IRISMsg();
            int.TryParse(parts[0], out int ID);
            int.TryParse(parts[1], out int LIGHT);
            int.TryParse(parts[2], out int RSSI);

            if (!(ID >= 1 && ID <= 3))
            {
                throw new DataMisalignedException();
            }
            else
            {
                _msg.NODEID = ID;
                _msg.LIGHT = LIGHT;
                _msg.RSSI = RSSI;
            }
            return _msg;
        }

        private string CleanCleanString(string _str)
        {
            StringBuilder _strbldr_NUM = new StringBuilder();

            bool ID = false, RSSI = false, LIGHT = false;

            if (_str.Contains('L') && _str.Contains('I') && _str.Contains('G') && _str.Contains('H') && _str.Contains('T'))
            {
                LIGHT = true;
            }
            else if (_str.Contains('R') && _str.Contains('S') && _str.Contains('I'))
            {
                RSSI = true;
            }
            else if (_str.Contains('I') && _str.Contains('D'))
            {
                ID = true;
            }

            foreach (char _chr in _str)
            {
                //find number

                if ((_chr >= '0' && _chr <= '9') || (_chr >= 'A' && _chr <= 'Z') || (_chr == ':'))
                {
                    _strbldr_NUM.Append(_chr);
                }
            }
            return _strbldr_NUM.ToString();
        }

        #endregion METHODS
    }
}
