package d2

import (
	"context"
	"strings"
	"testing"
)

func TestService_Compile(t *testing.T) {
	svc := NewService()
	svc.Startup(context.Background())

	tests := []struct {
		name    string
		input   string
		themeID int64
		wantErr bool
	}{
		{
			name:    "Basic D2",
			input:   "x -> y",
			themeID: 0,
			wantErr: false,
		},
		{
			name:    "Empty Input",
			input:   "",
			themeID: 0,
			wantErr: false, // D2 might handle empty input gracefully or error, let's see.
		},
		{
			name:    "Invalid Syntax",
			input:   "x -> {", // Syntax error
			themeID: 0,
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := svc.Compile(tt.input, tt.themeID, "#ffffff")
			if (err != nil) != tt.wantErr {
				t.Errorf("Compile() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr {
				if !strings.Contains(got, "<svg") {
					t.Errorf("Compile() result does not look like SVG: %v", got)
				}
			}
		})
	}
}
