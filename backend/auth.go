package main

// auth.go — email validation and PBKDF2-HMAC-SHA256 password hashing.
//
// The wire format is deliberately identical to the Python server so existing
// roster.json files can be loaded by either implementation:
//   pbkdf2_sha256$<iters>$<salt_hex>$<hash_hex>

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"fmt"
	"regexp"
	"strings"

	"golang.org/x/crypto/pbkdf2"
)

const (
	pwMinLen    = 4
	pbkdf2Iters = 120_000
)

var emailRE = regexp.MustCompile(`^[^@\s]+@[^@\s]+\.[^@\s]+$`)

func validEmail(email string) bool {
	return emailRE.MatchString(strings.TrimSpace(email))
}

// hashPassword returns a salted PBKDF2-HMAC-SHA256 token.
func hashPassword(password string) string {
	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
		panic("crypto/rand: " + err.Error())
	}
	dk := pbkdf2.Key([]byte(password), salt, pbkdf2Iters, 32, sha256.New)
	return fmt.Sprintf("pbkdf2_sha256$%d$%s$%s",
		pbkdf2Iters, hex.EncodeToString(salt), hex.EncodeToString(dk))
}

// verifyPassword returns true iff password matches the stored token.
func verifyPassword(password, encoded string) bool {
	parts := strings.SplitN(encoded, "$", 4)
	if len(parts) != 4 || parts[0] != "pbkdf2_sha256" {
		return false
	}
	var iters int
	if _, err := fmt.Sscanf(parts[1], "%d", &iters); err != nil || iters <= 0 {
		return false
	}
	salt, err := hex.DecodeString(parts[2])
	if err != nil {
		return false
	}
	want, err := hex.DecodeString(parts[3])
	if err != nil {
		return false
	}
	got := pbkdf2.Key([]byte(password), salt, iters, 32, sha256.New)
	return subtle.ConstantTimeCompare(got, want) == 1
}
