using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using IRISGateway.UART;

namespace IRISGateway
{
    public class Program
    {
        /// <summary>
        /// UART lock for async send and receive
        /// </summary>
        public object UART_lock;

        public static UARTManager _uart;
        
        public static bool wait_for_cancel = true;

        public static bool robot_instruction_ready = false;

        public static async Task Main()
        {
            _uart = new UARTManager();

            var tokenSource = new CancellationTokenSource();
            var token = tokenSource.Token;

            DateTime startTime = DateTime.Now;

            var rx_task = Task.Run(() =>
            {
                while (wait_for_cancel)
                {
                    var readval = _uart.Read(_uart);
                    Console.WriteLine(readval);
                }
            }, token);

            var tx_task = Task.Run(() =>
            {
                while (wait_for_cancel)
                {
                    if (robot_instruction_ready)
                    {
                        //
                    }
                    Thread.Sleep(9);

                    byte[] msg = new byte[] { (byte)'\0' };

                    _uart.Write(_uart, msg);
                }
            }, token);

            while (wait_for_cancel)
            {
                if (!wait_for_cancel) Console.WriteLine("Program Complete");
            }

            await Task.Yield();
            tokenSource.Cancel();
            TimeSpan totaltime = DateTime.Now - startTime;
            Console.WriteLine(totaltime);
        }

        protected static void KeyPressHandler(object sender, ConsoleCancelEventArgs args)
        {
            args.Cancel = true;
            wait_for_cancel = false;
        }
    }
}
