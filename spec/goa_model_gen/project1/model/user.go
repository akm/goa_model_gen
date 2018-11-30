package model

import (
	"time"
)

type User struct {
	ID string `datastore:"-" goon:"id" json:"id"`
	Email string `json:"email,omitempty"`
	AuthDomain string `json:"auth_domain,omitempty"`
	Admin bool `json:"admin,omitempty"`
	ClientID string `json:"client_id,omitempty"`
	FederatedIdentity string `json:"federated_identity,omitempty"`
	FederatedProvider string `json:"federated_provider,omitempty"`
	CreatedAt time.Time `json:"created_at" validate:"required"`
	UpdatedAt time.Time `json:"updated_at" validate:"required"`
}


func (m *User) PrepareToCreate() error {
	if m.CreatedAt.IsZero() {
		m.CreatedAt = time.Now()
	}
	if m.UpdatedAt.IsZero() {
		m.UpdatedAt = time.Now()
	}
	return nil
}

func (m *User) PrepareToUpdate() error {
	m.UpdatedAt = time.Now()
	return nil
}
