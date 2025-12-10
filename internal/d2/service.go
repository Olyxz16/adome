package d2

import (
	"context"
	"log/slog"
	"os"
	
	"oss.terrastruct.com/d2/d2lib"
	"oss.terrastruct.com/d2/d2layouts/d2elklayout"
	"oss.terrastruct.com/d2/d2renderers/d2svg"
	"oss.terrastruct.com/d2/d2graph"
	"oss.terrastruct.com/d2/lib/textmeasure"
	d2log "oss.terrastruct.com/d2/lib/log"
)

type Service struct {
	ctx context.Context
}

func NewService() *Service {
	return &Service{}
}

func (s *Service) Startup(ctx context.Context) {
	s.ctx = ctx
}

func (s *Service) Compile(input string, themeID int64, backgroundColor string) (string, error) {
	// Initialize logger to avoid "missing slog.Logger in context" warning
	l := slog.New(slog.NewTextHandler(os.Stderr, nil))
	ctx := d2log.With(context.Background(), l)
	
	if backgroundColor != "" {
		// Prepend the background color to the D2 input
		input = "style.fill: \"" + backgroundColor + "\"\n" + input
	}

	ruler, err := textmeasure.NewRuler()
	if err != nil {
		return "", err
	}

	layoutResolver := func(engine string) (d2graph.LayoutGraph, error) {
		return d2elklayout.DefaultLayout, nil
	}
	
	renderOpts := &d2svg.RenderOpts{
		Pad: ptr(100),
		ThemeID: &themeID,
	}

	diagram, _, err := d2lib.Compile(ctx, input, &d2lib.CompileOptions{
		LayoutResolver: layoutResolver,
		Ruler:  ruler,
	}, renderOpts)
	
	if err != nil {
		return "", err
	}
	
	out, err := d2svg.Render(diagram, renderOpts)
	if err != nil {
		return "", err
	}

	return string(out), nil
}

func ptr(i int64) *int64 {
	return &i
}
