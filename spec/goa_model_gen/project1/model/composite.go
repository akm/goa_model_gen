package model

import (
	"context"
	"fmt"

	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"

	"github.com/goadesign/goa/uuid"
)

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



type CompositeStore struct{
}

func (s *CompositeStore) All(ctx context.Context) ([]*Composite, error) {
	return s.Select(ctx, s.Query(ctx))
}

func (s *CompositeStore) Select(ctx context.Context, q *datastore.Query) ([]*Composite, error) {
	g := GoonFromContext(ctx)
	r := []*Composite{}
	log.Infof(ctx, "q is %v\n", q)
	_, err := g.GetAll(q.EventualConsistency(), &r)
	if err != nil {
		log.Errorf(ctx, "Failed to Select Composite because of %v\n", err)
		return nil, err
	}
	return r, nil
}

func (s *CompositeStore) Query(ctx context.Context) *datastore.Query {
	g := GoonFromContext(ctx)
	k := g.Kind(new(Composite))
	// log.Infof(ctx, "Kind for Composite is %v\n", k)
	return datastore.NewQuery(k)
}

func (s *CompositeStore) ByID(ctx context.Context, id string) (*Composite, error) {
	r := Composite{Id: id}
  err := s.Get(ctx, &r)
	if err != nil {
		return nil, err
	}
	return &r, nil
}

func (s *CompositeStore) ByKey(ctx context.Context, key *datastore.Key) (*Composite, error) {
	if err := s.IsValidKey(ctx, key); err != nil {
		log.Errorf(ctx, "CompositeStore.ByKey got Invalid key: %v because of %v\n", key, err)
		return nil, err
	}

	r := Composite{Id: key.StringID()}
	err := s.Get(ctx, &r)
	if err != nil {
		return nil, err
	}
	return &r, nil
}

func (s *CompositeStore) Get(ctx context.Context, m *Composite) error {
	g := GoonFromContext(ctx)
	err := g.Get(m)
	if err != nil {
		log.Errorf(ctx, "Failed to Get Composite because of %v\n", err)
		return err
	}

	return nil
}

func (s *CompositeStore) IsValidKey(ctx context.Context, key *datastore.Key) error {
	if key == nil {
		return fmt.Errorf("key is nil")
	}
	g := GoonFromContext(ctx)
	expected := g.Kind(&Composite{})
	if key.Kind() != expected {
		return fmt.Errorf("key kind must be %s but was %s", expected, key.Kind())
	}
	return nil
}

func (s *CompositeStore) Exist(ctx context.Context, m *Composite) (bool, error) {
	g := GoonFromContext(ctx)
	key, err := g.KeyError(m)
	if err != nil {
		log.Errorf(ctx, "Failed to Get Key of %v because of %v\n", m, err)
		return false, err
	}
	_, err = s.ByKey(ctx, key)
	if err == datastore.ErrNoSuchEntity {
		return false, nil
	} else if err != nil {
		log.Errorf(ctx, "Failed to get existance of %v because of %v\n", m, err)
		return false, err
	} else {
		return true, nil
	}
}

func (s *CompositeStore) Create(ctx context.Context, m *Composite) (*datastore.Key, error) {
  err := m.PrepareToCreate()
  if err != nil {
    return nil, err
  }
	if err := m.Validate(); err != nil {
		return nil, err
	}


  return s.Put(ctx, m)
}

func (s *CompositeStore) Update(ctx context.Context, m *Composite) (*datastore.Key, error) {
  err := m.PrepareToUpdate()
  if err != nil {
    return nil, err
  }
	if err := m.Validate(); err != nil {
		return nil, err
	}


  return s.Put(ctx, m)
}

func (s *CompositeStore) Put(ctx context.Context, m *Composite) (*datastore.Key, error) {
	if m.Id == "" {
		m.Id = uuid.NewV4().String()
	}
	g := GoonFromContext(ctx)
	key, err := g.Put(m)
	if err != nil {
		log.Errorf(ctx, "Failed to Put %v because of %v\n", m, err)
		return nil, err
	}
	return key, nil
}

func (s *CompositeStore) Delete(ctx context.Context, m *Composite) error {
	g := GoonFromContext(ctx)
	key, err := g.KeyError(m)
	if err != nil {
		log.Errorf(ctx, "Failed to Get key of %v because of %v\n", m, err)
		return err
	}
	if err := g.Delete(key); err != nil {
		log.Errorf(ctx, "Failed to Delete %v because of %v\n", m, err)
		return err
	}
	return nil
}
