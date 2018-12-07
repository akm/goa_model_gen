package model

import (
	"context"

	"gopkg.in/go-playground/validator.v9"
)

func (s *MemoStore) Validate(ctx context.Context, m *Tenant) error {
	if err := m.Validate(ctx); err != nil {
		return err
	}
	if err := s.ValidateUniqueness(ctx, m); err != nil {
		return err
	}
	return nil
}

func (m *Memo) Validate(ctx context.Context) error {
	return WithValidator(ctx, func(validate *validator.Validate) error {
		return validate.Struct(m)
	})
}
