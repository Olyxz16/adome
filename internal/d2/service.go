package d2

import (
	"context"
	
	"oss.terrastruct.com/d2/d2lib"
	"oss.terrastruct.com/d2/d2layouts/d2elklayout"
	"oss.terrastruct.com/d2/d2renderers/d2svg"
	"oss.terrastruct.com/d2/d2graph"
	"oss.terrastruct.com/d2/lib/textmeasure"
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

func (s *Service) Compile(input string) (string, error) {
	ruler, err := textmeasure.NewRuler()
	if err != nil {
		return "", err
	}

	layoutResolver := func(engine string) (d2graph.LayoutGraph, error) {
		return d2elklayout.DefaultLayout, nil
	}
	
	renderOpts := &d2svg.RenderOpts{
		Pad: ptr(100),
	}

	diagram, _, err := d2lib.Compile(context.Background(), input, &d2lib.CompileOptions{
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