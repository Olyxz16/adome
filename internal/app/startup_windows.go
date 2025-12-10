//go:build windows

package app

import (
	"os/exec"
	"syscall"
)

func SetupDetachment(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{
		HideWindow:    true,
		CreationFlags: syscall.DETACHED_PROCESS | syscall.CREATE_NEW_PROCESS_GROUP,
	}
}
