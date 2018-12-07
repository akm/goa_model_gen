package model

import (
	"context"
	"fmt"

	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"
)

type UserStore struct{
}

func (s *UserStore) All(ctx context.Context) ([]*User, error) {
	return s.Select(ctx, s.Query(ctx))
}

func (s *UserStore) Select(ctx context.Context, q *datastore.Query) ([]*User, error) {
	g := GoonFromContext(ctx)
	r := []*User{}
	log.Infof(ctx, "q is %v\n", q)
	_, err := g.GetAll(q.EventualConsistency(), &r)
	if err != nil {
		log.Errorf(ctx, "Failed to Select User because of %v\n", err)
		return nil, err
	}
	return r, nil
}

func (s *UserStore) CountBy(ctx context.Context, q *datastore.Query) (int, error) {
	g := GoonFromContext(ctx)
	c, err := g.Count(q)
	if err != nil {
		log.Errorf(ctx, "Failed to count User with %v because of %v\n", q, err)
		return 0, err
	}
	return c, nil
}

func (s *UserStore) Query(ctx context.Context) *datastore.Query {
	g := GoonFromContext(ctx)
	k := g.Kind(new(User))
	// log.Infof(ctx, "Kind for User is %v\n", k)
	return datastore.NewQuery(k)
}

func (s *UserStore) ByID(ctx context.Context, iD string) (*User, error) {
	r := User{ID: iD}
  err := s.Get(ctx, &r)
	if err != nil {
		return nil, err
	}
	return &r, nil
}

func (s *UserStore) ByKey(ctx context.Context, key *datastore.Key) (*User, error) {
	if err := s.IsValidKey(ctx, key); err != nil {
		log.Errorf(ctx, "UserStore.ByKey got Invalid key: %v because of %v\n", key, err)
		return nil, err
	}

	r := User{ID: key.StringID()}
	err := s.Get(ctx, &r)
	if err != nil {
		return nil, err
	}
	return &r, nil
}

func (s *UserStore) Get(ctx context.Context, m *User) error {
	g := GoonFromContext(ctx)
	err := g.Get(m)
	if err != nil {
		log.Errorf(ctx, "Failed to Get User because of %v\n", err)
		return err
	}

	return nil
}

func (s *UserStore) IsValidKey(ctx context.Context, key *datastore.Key) error {
	if key == nil {
		return fmt.Errorf("key is nil")
	}
	g := GoonFromContext(ctx)
	expected := g.Kind(&User{})
	if key.Kind() != expected {
		return fmt.Errorf("key kind must be %s but was %s", expected, key.Kind())
	}
	return nil
}

func (s *UserStore) Exist(ctx context.Context, m *User) (bool, error) {
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

func (s *UserStore) Create(ctx context.Context, m *User) (*datastore.Key, error) {
  err := m.PrepareToCreate()
  if err != nil {
    return nil, err
  }
	if err := m.Validate(); err != nil {
		return nil, err
	}

	exist, err := s.Exist(ctx, m)
	if err != nil {
		return nil, err
	}
	if exist {
		log.Errorf(ctx, "Failed to create %v because of another entity has same key\n", m)
		return nil, fmt.Errorf("Duplicate ID error: %q of %v\n", m.ID, m)
	}

  return s.Put(ctx, m)
}

func (s *UserStore) Update(ctx context.Context, m *User) (*datastore.Key, error) {
  err := m.PrepareToUpdate()
  if err != nil {
    return nil, err
  }
	if err := m.Validate(); err != nil {
		return nil, err
	}

	exist, err := s.Exist(ctx, m)
	if err != nil {
		return nil, err
	}
	if !exist {
		log.Errorf(ctx, "Failed to update %v because it doesn't exist\n", m)
		return nil, fmt.Errorf("No data to update %q of %v\n", m.ID, m)
	}

  return s.Put(ctx, m)
}

func (s *UserStore) Put(ctx context.Context, m *User) (*datastore.Key, error) {
	g := GoonFromContext(ctx)
	key, err := g.Put(m)
	if err != nil {
		log.Errorf(ctx, "Failed to Put %v because of %v\n", m, err)
		return nil, err
	}
	return key, nil
}

func (s *UserStore) Delete(ctx context.Context, m *User) error {
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

func (s *UserStore) ValidateUniqueness(ctx context.Context, m *Tenant) error {
	conditions := map[string]interface{}{
		"Email": m.Email,
	}
	for field, value := range conditions {
		q := s.Query(ctx).Filter(field + " =", value)
		c, err := s.CountBy(ctx, q)
		if err != nil {
			return err
		}
		if c > 0 {
			return &ValidationError{
				Field: field,
				Message: fmt.Sprintf("%v has already been taken", value),
			}
		}
	}
	return nil
}
