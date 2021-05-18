using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace IRISGateway.IRIS
{
    public class IRISMsg
    {
        public int NODEID { get; set; }

        public int RSSI { get; set; }

        public int LIGHT { get; set; }
    }

    public class IRISDevice
    {
        public int NODEID;

        public Stack<IRISMsg> messages;

        public IRISDevice()
        {
            messages = new Stack<IRISMsg>();
        }

        /// <summary>
        /// add a new listing
        /// </summary>
        /// <param name="_dvc"></param>
        /// <param name="_msg"></param>
        public static void AddMsg(IRISDevice _dvc, IRISMsg _msg)
        {
            _dvc.messages.Push(_msg);
        }

        //find average light and delete buffer
        public static double GetAverageLight(IRISDevice _dvc)
        {
            double _avg = 0;
            int _count = _dvc.messages.Count();
            foreach (var _msg in _dvc.messages)
            {
                _avg += _msg.LIGHT;
            }

            //clear the buffer and start again
            _dvc.messages.Clear();

            return (double)(_avg / _count);
        }

        //send last rssi
        public static int GetLastRSSI(IRISDevice _dvc)
        {
            return _dvc.messages.First().RSSI;
        }
    }

    public class IRISManager
    {

        public List<IRISDevice> devices;

        public const int LIGHT_THRESHOLD = 825;

        public IRISManager()
        {
            //manager
            devices = new List<IRISDevice>();
        }

        public static IRISDevice GetDeviceByID(IRISManager _mngr, int _ID)
        {
            return _mngr.devices.Select(x => x).Where(x => x.NODEID == _ID).FirstOrDefault();
        }

        public static int FindFireDevice(IRISManager _mngr)
        {
            List<Tuple<int, double>> light_readings = new List<Tuple<int, double>>();

            foreach(var _dvc in _mngr.devices)
            {
                double light = IRISDevice.GetAverageLight(_dvc);
                int id = _dvc.NODEID;
                light_readings.Add(new Tuple<int, double>(id, light));
            }

            //find highest device light
            Tuple<int, double> high_dvc = new Tuple<int, double>(0, 0);
            foreach (var _dvc in light_readings)
            {
                if (_dvc.Item2 > high_dvc.Item2)
                    high_dvc = _dvc;
            }

            //return if above treshold
            return (high_dvc.Item2 >= LIGHT_THRESHOLD) ? high_dvc.Item1 : 0;
        }
    }
}
