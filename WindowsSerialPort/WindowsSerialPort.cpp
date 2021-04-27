// WindowsSerialPort.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <iostream>
#include <Windows.h>
#include <stdio.h>

#define BAUDRATE CBR_57600
#define BYTESIZE 8
#define STOPBITS ONESTOPBIT
#define PARITY NOPARITY
#define COMNAME L"COM4"
#define N 2

using namespace std;

HANDLE hSerial;
void ReadSerial();

int main()
{
	cout << "Serial Read Program!\n";

	hSerial = CreateFile(COMNAME,
		GENERIC_READ | GENERIC_WRITE,
		0,
		0,
		OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL,
		0);

	if (hSerial == INVALID_HANDLE_VALUE) {
		if (GetLastError() == ERROR_FILE_NOT_FOUND) {
			//serial port does not exist. Inform user.
			cout << "Port does not exist." << endl;
		}
		cout << "Port could not open for some reason." << endl;
		//some other error occurred. Inform user.
	}

	DCB dcbSerialParams = { 0 };
	dcbSerialParams.DCBlength = sizeof(dcbSerialParams);
	if (!GetCommState(hSerial, &dcbSerialParams)) {
		//error getting state
	}

	dcbSerialParams.BaudRate = BAUDRATE;
	dcbSerialParams.ByteSize = BYTESIZE;
	dcbSerialParams.StopBits = STOPBITS;
	dcbSerialParams.Parity = PARITY;
	if (!SetCommState(hSerial, &dcbSerialParams)) {
		//error setting serial port state
	}

	/*
	COMMTIMEOUTS timeouts = { 0 };
	timeouts.ReadIntervalTimeout = 50;
	timeouts.ReadTotalTimeoutConstant = 50;
	timeouts.ReadTotalTimeoutMultiplier = 10;
	timeouts.WriteTotalTimeoutConstant = 50;
	timeouts.WriteTotalTimeoutMultiplier = 10;
	if (!SetCommTimeouts(hSerial, &timeouts)) {
		//error occureed. Inform user
	}
	*/

	char input_char = '\0';

	do {
		ReadSerial();
		//input_char = getchar();
	} while (1);

	//char szBuff[N + 1] = { 0 };
	//DWORD dwBytesRead = 0;
	//if (!ReadFile(hSerial, szBuff, N, &dwBytesRead, NULL)) {
	//	//error occurred. Report to user.
	//}

	CloseHandle(hSerial);

}

void ReadSerial() {
	//
	char szBuff[N + 1] = { 0 };
	DWORD dwBytesRead = 0;
	if (!ReadFile(hSerial, szBuff, N, &dwBytesRead, NULL)) {
		//error occurred. Report to user.
	}
 	cout << szBuff << endl;
}