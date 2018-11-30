package model

import (
	"context"
	"fmt"

	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"
)

type MemoStore struct{
}

func (s *MemoStore) All(ctx context.Context) ([]*Memo, error) {
	return s.Select(ctx, s.Query(ctx))
}

func (s *MemoStore) Select(ctx context.Context, q *datastore.Query) ([]*Memo, error) {
	g := GoonFromContext(ctx)
	r := []*Memo{}
	log.Infof(ctx, "q is %v\n", q)
	_, err := g.GetAll(q.EventualConsistency(), &r)
	if err != nil {
		log.Errorf(ctx, "Failed to Select Memo because of %v\n", err)
		return nil, err
	}
	return r, nil
}

func (s *MemoStore) Query(ctx context.Context) *datastore.Query {
	g := GoonFromContext(ctx)
	k := g.Kind(new(Memo))
	// log.Infof(ctx, "Kind for Memo is %v\n", k)
	return datastore.NewQuery(k)
}

func (s *MemoStore) ByID(ctx context.Context, id int64) (*Memo, error) {
	r := Memo{Id: id}
  err := s.Get(ctx, &r)
	if err != nil {
		return nil, err
	}
	return &r, nil
}

func (s *MemoStore) ByKey(ctx context.Context, key *datastore.Key) (*Memo, error) {
	if err := s.IsValidKey(ctx, key); err != nil {
		log.Errorf(ctx, "MemoStore.ByKey got Invalid key: %v because of %v\n", key, err)
		return nil, err
	}

	r := Memo{Id: key.IntID()}
	err := s.Get(ctx, &r)
	if err != nil {
		return nil, err
	}
	return &r, nil
}

func (s *MemoStore) Get(ctx context.Context, m *Memo) error {
	g := GoonFromContext(ctx)
	err := g.Get(m)
	if err != nil {
		log.Errorf(ctx, "Failed to Get Memo because of %v\n", err)
		return err
	}

	return nil
}

func (s *MemoStore) IsValidKey(ctx context.Context, key *datastore.Key) error {
	if key == nil {
		return fmt.Errorf("key is nil")
	}
	g := GoonFromContext(ctx)
	expected := g.Kind(&Memo{})
	if key.Kind() != expected {
		return fmt.Errorf("key kind must be %s but was %s", expected, key.Kind())
	}
	return nil
}

func (s *MemoStore) Exist(ctx context.Context, m *Memo) (bool, error) {
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

func (s *MemoStore) Create(ctx context.Context, m *Memo) (*datastore.Key, error) {
  err := m.PrepareToCreate()
  if err != nil {
    return nil, err
  }
	if err := m.Validate(); err != nil {
		return nil, err
	}


  return s.Put(ctx, m)
}

func (s *MemoStore) Update(ctx context.Context, m *Memo) (*datastore.Key, error) {
  err := m.PrepareToUpdate()
  if err != nil {
    return nil, err
  }
	if err := m.Validate(); err != nil {
		return nil, err
	}


  return s.Put(ctx, m)
}

func (s *MemoStore) Put(ctx context.Context, m *Memo) (*datastore.Key, error) {
	g := GoonFromContext(ctx)
	key, err := g.Put(m)
	if err != nil {
		log.Errorf(ctx, "Failed to Put %v because of %v\n", m, err)
		return nil, err
	}
	return key, nil
}

func (s *MemoStore) Delete(ctx context.Context, m *Memo) error {
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
