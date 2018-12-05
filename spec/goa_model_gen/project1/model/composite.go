package model


type Component1 struct {
	Name string `json:"name" validate:"required"`
}

type Composite struct {
	Id string `datastore:"-" goon:"id" json:"id"`
	MainComponent Component1 `json:"main_component" validate:"required"`
	Components []Component1 `json:"components,omitempty"`
}


func (m *Composite) PrepareToCreate() error {
	return nil
}

func (m *Composite) PrepareToUpdate() error {
	return nil
}
