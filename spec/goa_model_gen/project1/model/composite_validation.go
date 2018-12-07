// You can edit this file. goa_model_gen doesn't overwrite this file.
// This code generated by goa_model_gen-0.5.0

package model

import (
	"context"

	"gopkg.in/go-playground/validator.v9"
)

func (s *CompositeStore) Validate(ctx context.Context, m *Tenant) error {
	if err := m.Validate(ctx); err != nil {
		return err
	}
	if err := s.ValidateUniqueness(ctx, m); err != nil {
		return err
	}
	return nil
}

func (m *Composite) Validate(ctx context.Context) error {
	return WithValidator(ctx, func(validate *validator.Validate) error {
		return validate.Struct(m)
	})
}
