package model


type Component1 struct {
	Name string `json:"name" validate:"required"`
}