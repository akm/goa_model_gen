// DO NOT EDIT this file.

package model

type Component1 struct {
	Name string `json:"name" validate:"required"`
}

type Composite struct {
	Id            string       `datastore:"-" goon:"id" json:"id"`
	MainComponent Component1   `json:"main_component" validate:"required"`
	Components    []Component1 `json:"components,omitempty"`
}

func (m *Composite) Assign(ref *RefString) error {
	ref.ID = m.ID
	return nil
}

func (m *Composite) PrepareToCreate() error {
	m.PrepareFields()
	return nil
}

func (m *Composite) PrepareToUpdate() error {
	m.PrepareFields()
	return nil
}

func (m *Composite) PrepareFields() error {
	return nil
}

func (m *Composite) IsPersisted() bool {
	return m.ID != ""
}
