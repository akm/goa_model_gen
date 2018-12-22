// DO NOT EDIT this file.
// This code generated by goa_model_gen-<%= GoaModelGen::VERSION %>

package model

import (
	"time"

	"google.golang.org/appengine/datastore"
)

type Memo struct {
	Id          int64          `datastore:"-" goon:"id" json:"id"`
	AuthorKey   *datastore.Key `json:"author_key" validate:"required"`
	ContentText string         `json:"content_text,omitempty"`
	Shared      bool           `json:"shared,omitempty"`
	CreatedAt   time.Time      `json:"created_at" validate:"required"`
	UpdatedAt   time.Time      `json:"updated_at" validate:"required"`
}

func (m *Memo) PrepareToCreate() error {
	if m.CreatedAt.IsZero() {
		m.CreatedAt = time.Now()
	}
	if m.UpdatedAt.IsZero() {
		m.UpdatedAt = time.Now()
	}
	return nil
}

func (m *Memo) PrepareToUpdate() error {
	m.UpdatedAt = time.Now()
	return nil
}

func (m *Memo) IsPersisted() bool {
	return m.ID != 0
}
