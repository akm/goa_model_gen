package model

import (
	"gopkg.in/go-playground/validator.v9"
)

func (m *Composite) Validate() error {
	validator := validator.New()
	return validator.Struct(m)
}

