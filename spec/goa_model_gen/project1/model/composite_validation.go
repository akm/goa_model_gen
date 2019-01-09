// You can edit this file. goa_model_gen doesn't overwrite this file.

package model

import (
	"context"

	"gopkg.in/go-playground/validator.v9"
)

func (m *Composite) Validate(ctx context.Context) error {
	return WithValidator(ctx, func(validate *validator.Validate) error {
		return validate.Struct(m)
	})
}
