using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using IRISGateway.IRIS;
using IRISGateway.UART;

namespace IRISGateway
{
    public class Program
    {
        /// <summary>
        /// UART lock for async send and receive
        /// </summary>
        public static bool UART_locked = false;

        private static readonly object UART_lock = new object();

        public static UARTManager _uart;

        public static IRISManager _iris_managers;

        public static bool wait_for_cancel = true;

        public static bool robot_instruction_ready = false;

        public static async Task Main()
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                //process can only be run as admin realtime on windows
                Process[] processes = Process.GetProcessesByName("IRISGateway");
                foreach (var proc in processes)
                {
                    proc.PriorityClass = ProcessPriorityClass.RealTime;
                }
                Console.WriteLine("IRIS::Admin::RealTime");
            }

            _uart = new UARTManager();
            _iris_managers = new IRISManager();
            _iris_managers.devices.Add(new IRISDevice() { NODEID = 1 });
            _iris_managers.devices.Add(new IRISDevice() { NODEID = 2 });
            _iris_managers.devices.Add(new IRISDevice() { NODEID = 3 });

            var tokenSource = new CancellationTokenSource();
            var token = tokenSource.Token;
            Console.CancelKeyPress += new ConsoleCancelEventHandler(KeyPressHandler);

            DateTime startTime = DateTime.Now;

            var rx_task = Task.Run(() =>
            {
                while (wait_for_cancel)
                {
                    Thread.Sleep(10);
                    if (UART_locked == false)
                    //lock (UART_lock)
                    {
                        //lock (UART_lock)
                        //{
                            IRISMsg new_uart_msg = _uart.Read(_uart);
                            if (new_uart_msg != null)
                            {
                                IRISDevice.AddMsg(IRISManager.GetDeviceByID(_iris_managers, new_uart_msg.NODEID), new_uart_msg);
                            }
                        }
                    //}
                }
            }, token);

            var tx_task = Task.Run(() =>
            {
                while (wait_for_cancel)
                {
                    //message moves the robot forward with safe mode of operation
                    //move 40 cm and stop
                    //byte[] msg = new byte[] { 128, 131, 137, 1, 44, 128, 0, 156, 1, 144, 137, 0, 0, 0, 0 };
                    string send_move_forward_command = "128131137144128015611441370000";
                    byte[] msg = Encoding.ASCII.GetBytes(send_move_forward_command);
                    Thread.Sleep(1000 * 10); //sleep for 10 seconds
                    //lock (UART_lock)
                    //{
                        //thread regulated task here
                        Console.WriteLine("LOCK::MAIN::THREAD");
                        UART_locked = true;
                        int node = IRISManager.FindFireDevice(_iris_managers);
                        if (node != 0)
                        {
                            _uart.Write(_uart, msg);
                            Console.WriteLine($"Fire Node: {node}");
                        }
                        else Console.WriteLine("No Nodes on fire");
                        Thread.Sleep(1000 * 2);
                        _uart.serialPort.DiscardInBuffer();
                    //}
                    UART_locked = false;
                }
            }, token);

            while (wait_for_cancel)
            {
                //find the averages and run the guess}
                if (!wait_for_cancel)
                {
                    Console.WriteLine("Program Complete");
                }
            }

            await Task.Yield();
            tokenSource.Cancel();
            TimeSpan totaltime = DateTime.Now - startTime;
            Console.WriteLine(totaltime);
        }

        protected static void KeyPressHandler(object sender, ConsoleCancelEventArgs args)
        {
            wait_for_cancel = false;
            args.Cancel = true;
        }
    }
}
