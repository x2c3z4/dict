// Copyright (c) 2020 vonnyfly
// All rights reserved.

package common

import (
	"fmt"
	"strings"
)

var (
	// Version will show the version.
	Version string
	// CommitID is the latest commit hash.
	CommitID string
	// BuildTime is the compile time.
	BuildTime string
	// ChangeLog is the latest changelog.
	ChangeLog string
)

// EchoVersion outputs standard version information.
func EchoVersion() {
	fmt.Printf("%-10s: %s\n", "Version", Version)
	fmt.Printf("%-10s: %s\n", "CommitID", CommitID)
	fmt.Printf("%-10s: %s\n", "BuildTime", BuildTime)
	fmt.Printf("%s\n", strings.Repeat("=", 80))
	fmt.Printf("%-10s: \n%s\n", "ChangeLog", ChangeLog)
}
