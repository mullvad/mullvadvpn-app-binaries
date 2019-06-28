/* SPDX-License-Identifier: Apache-2.0
 *
 * Copyright (C) 2017-2019 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
 */

package main

import (
	"C"
	"bufio"
	"io"
	"io/ioutil"
	"log"
	"math"
	"net"
	"os"
	"os/signal"
	"runtime"
	"strings"

	"golang.org/x/sys/unix"

	"golang.zx2c4.com/wireguard/device"
	"golang.zx2c4.com/wireguard/ipc"
	"golang.zx2c4.com/wireguard/tun"
)

type TunnelHandle struct {
	device *device.Device
	uapi   net.Listener
}

var tunnelHandles map[int32]TunnelHandle

func init() {
	device.RoamingDisabled = true
	tunnelHandles = make(map[int32]TunnelHandle)
	signals := make(chan os.Signal)
	signal.Notify(signals, unix.SIGUSR2)
	go func() {
		buf := make([]byte, os.Getpagesize())
		for {
			select {
			case <-signals:
				n := runtime.Stack(buf, true)
				buf[n] = 0
				log.Println("WireGuard/GoBackend/StackTrace - ", buf)
			}
		}
	}()
}

// Adjust logger to use the passed file descriptor for all output if the filedescriptor is valid
func newLogger(loggingFd int, level int) *device.Logger {
	logger := new(device.Logger)
	outputFile := os.NewFile(uintptr(loggingFd), "")
	var output io.Writer
	if outputFile != nil {
		output = outputFile
	} else {
		output = os.Stdout
	}

	logErr, logInfo, logDebug := func() (io.Writer, io.Writer, io.Writer) {
		if level >= device.LogLevelDebug {
			return output, output, output
		}
		if level >= device.LogLevelInfo {
			return output, output, ioutil.Discard
		}
		if level >= device.LogLevelError {
			return output, ioutil.Discard, ioutil.Discard
		}
		return ioutil.Discard, ioutil.Discard, ioutil.Discard
	}()

	logger.Debug = log.New(logDebug,
		"DEBUG: ",
		log.Ldate|log.Ltime,
	)

	logger.Info = log.New(logInfo,
		"INFO: ",
		log.Ldate|log.Ltime,
	)
	logger.Error = log.New(logErr,
		"ERROR: ",
		log.Ldate|log.Ltime,
	)

	return logger
}

//export wgTurnOnWithFd
func wgTurnOnWithFd(cIfaceName *C.char, mtu int, cSettings *C.char, fd int, loggingFd int, level int) int32 {

	logger := newLogger(loggingFd, level)
	if cIfaceName == nil {
		logger.Error.Println("cIfaceName is null")
		return -1
	}

	if cSettings == nil {
		logger.Error.Println("cSettings is null")
		return -1
	}
	settings := C.GoString(cSettings)
	ifaceName := C.GoString(cIfaceName)

	file := os.NewFile(uintptr(fd), "")
	tunDevice, err := tun.CreateTUNFromFile(file, mtu)
	if err != nil {
		logger.Error.Println(err)
		return -1
	}

	device := device.NewDevice(tunDevice, logger)

	var uapi net.Listener

	uapiFile, err := ipc.UAPIOpen(ifaceName)
	if err != nil {
		logger.Error.Println(err)
	} else {
		uapi, err = ipc.UAPIListen(ifaceName, uapiFile)
		if err != nil {
			uapiFile.Close()
			logger.Error.Println("Failed to start the UAPI")
			logger.Error.Println(err)
		} else {
			go func() {
				for {
					conn, err := uapi.Accept()
					if err != nil {
						return
					}
					go device.IpcHandle(conn)
				}
			}()
		}
	}

	setError := device.IpcSetOperation(bufio.NewReader(strings.NewReader(settings)))
	if setError != nil {
		tunDevice.Close()
		logger.Error.Println(setError)
		return -1
	}
	var i int32
	for i = 0; i < math.MaxInt32; i++ {
		if _, exists := tunnelHandles[i]; !exists {
			break
		}
	}
	if i == math.MaxInt32 {
		tunDevice.Close()
		return -1
	}
	tunnelHandles[i] = TunnelHandle{device: device, uapi: uapi}
	device.Up()
	return i
}

//export wgTurnOff
func wgTurnOff(tunnelHandle int32) {
	handle, ok := tunnelHandles[tunnelHandle]
	if !ok {
		return
	}
	delete(tunnelHandles, tunnelHandle)
	if handle.uapi != nil {
		handle.uapi.Close()
	}
	handle.device.Close()
}

//export wgVersion
func wgVersion() *C.char {
	return C.CString(device.WireGuardGoVersion)
}

func main() {}
