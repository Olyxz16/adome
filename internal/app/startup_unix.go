//go:build !windows

package app

import (
	"os/exec"
	"syscall"
)

func SetupDetachment(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Setsid: true,
	}
}
