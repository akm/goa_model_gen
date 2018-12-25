// You can edit this file. goa_model_gen doesn't overwrite this file.
// This code generated by goa_model_gen-<%= GoaModelGen::VERSION %>

package model

import (
	"context"

	"gopkg.in/go-playground/validator.v9"
)

func (m *Memo) Validate(ctx context.Context) error {
	return WithValidator(ctx, func(validate *validator.Validate) error {
		return validate.Struct(m)
	})
}
