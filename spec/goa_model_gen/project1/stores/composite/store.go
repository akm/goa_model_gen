// DO NOT EDIT this file.

package composite

import (
	"context"
	"fmt"

	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"

	"github.com/akm/goa_model_gen/project1/model"
	goon "github.com/akm/goa_model_gen/project1/stores/goon_store"
	"github.com/goadesign/goa/uuid"
	goonorig "github.com/mjibson/goon"
)

type CompositeStoreBinder interface {
	Query(q *datastore.Query) *datastore.Query
	Visible(m *model.Composite) bool
	Prepare(m *model.Composite)
}

type CompositeStore struct {
	Binder CompositeStoreBinder
}

func (s *CompositeStore) KindName() string {
	return "Composite"
}

func (s *CompositeStore) Query() *datastore.Query {
	q := datastore.NewQuery(s.KindName())
	if s.Binder != nil {
		q = s.Binder.Query(q)
	}
	return q
}

func (s *CompositeStore) Run(ctx context.Context, q *datastore.Query) *goonorig.Iterator {
	g := goon.FromContext(ctx)
	return g.Run(q)
}

func (s *CompositeStore) All(ctx context.Context) ([]*model.Composite, error) {
	return s.AllBy(ctx, s.Query())
}

func (s *CompositeStore) AllBy(ctx context.Context, q *datastore.Query) ([]*model.Composite, error) {
	g := goon.FromContext(ctx)
	r := []*model.Composite{}
	_, err := g.GetAll(q.EventualConsistency(), &r)
	if err != nil {
		log.Errorf(ctx, "Failed to AllBy model.Composite because of %v\n", err)
		return nil, err
	}
	return r, nil
}

func (s *CompositeStore) Select(ctx context.Context, q *datastore.Query) ([]*model.Composite, error) {
	return s.AllBy(ctx, q)
}

func (s *CompositeStore) FirstBy(ctx context.Context, q *datastore.Query) (*model.Composite, error) {
	r, err := s.AllBy(ctx, q.Limit(1))
	if err != nil {
		return nil, err
	}
	if len(r) > 0 {
		return r[0], nil
	} else {
		return nil, nil
	}
}

func (s *CompositeStore) CountBy(ctx context.Context, q *datastore.Query) (int, error) {
	g := goon.FromContext(ctx)
	c, err := g.Count(q)
	if err != nil {
		log.Errorf(ctx, "Failed to count model.Composite with %v because of %v\n", q, err)
		return 0, err
	}
	return c, nil
}

func (s *CompositeStore) ByID(ctx context.Context, id string) (*model.Composite, error) {
	r := model.Composite{Id: id}
	err := s.Get(ctx, &r)
	if err != nil {
		return nil, err
	}
	return &r, nil
}

func (s *CompositeStore) ByKey(ctx context.Context, key *datastore.Key) (*model.Composite, error) {
	if err := s.IsValidKey(ctx, key); err != nil {
		log.Errorf(ctx, "CompositeStore.ByKey got Invalid key: %v because of %v\n", key, err)
		return nil, err
	}

	return s.ByID(ctx, key.IntID())
}

func (s *CompositeStore) Get(ctx context.Context, m *model.Composite) error {
	g := goon.FromContext(ctx)
	err := g.Get(m)
	if err != nil {
		log.Errorf(ctx, "Failed to Get model.Composite because of %v\n", err)
		return err
	}

	if s.Binder != nil && !s.Binder.Visible(m) {
		return datastore.ErrNoSuchEntity
	}

	return nil
}

func (s *CompositeStore) IsValidKey(ctx context.Context, key *datastore.Key) error {
	if key == nil {
		return fmt.Errorf("key is nil")
	}
	g := goon.FromContext(ctx)
	expected := g.Kind(&model.Composite{})
	if key.Kind() != expected {
		return fmt.Errorf("key kind must be %s but was %s", expected, key.Kind())
	}
	return nil
}

func (s *CompositeStore) Exist(ctx context.Context, m *model.Composite) (bool, error) {
	if m.ID == "" {
		return false, nil
	}
	g := goon.FromContext(ctx)
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

func (s *CompositeStore) Create(ctx context.Context, m *model.Composite) (*datastore.Key, error) {
	if err := m.PrepareToCreate(); err != nil {
		return nil, err
	}
	return s.PutWith(ctx, m, func() error {
		exist, err := s.Exist(ctx, m)
		if err != nil {
			return err
		}
		if exist {
			log.Errorf(ctx, "Failed to create %v because of another entity has same key\n", m)
			return fmt.Errorf("Duplicate Id error: %q of %v\n", m.Id, m)
		}
		return nil
	})
}

func (s *CompositeStore) Update(ctx context.Context, m *model.Composite) (*datastore.Key, error) {
	if err := m.PrepareToUpdate(); err != nil {
		return nil, err
	}
	return s.PutWith(ctx, m, func() error {
		exist, err := s.Exist(ctx, m)
		if err != nil {
			return err
		}
		if !exist {
			log.Errorf(ctx, "Failed to update %v because it doesn't exist\n", m)
			return fmt.Errorf("No data to update %q of %v\n", m.Id, m)
		}
		return nil
	})
}

func (s *CompositeStore) PutWith(ctx context.Context, m *model.Composite, f func() error) (*datastore.Key, error) {
	if s.Binder != nil {
		s.Binder.Prepare(m)
	}
	if err := s.Validate(ctx, m); err != nil {
		return nil, err
	}
	if f != nil {
		if err := f(); err != nil {
			return nil, err
		}
	}

	return s.Put(ctx, m)
}

func (s *CompositeStore) Put(ctx context.Context, m *model.Composite) (*datastore.Key, error) {
	if m.Id == "" {
		m.Id = uuid.NewV4().String()
	}
	g := goon.FromContext(ctx)
	key, err := g.Put(m)
	if err != nil {
		log.Errorf(ctx, "Failed to Put %v because of %v\n", m, err)
		return nil, err
	}
	return key, nil
}

func (s *CompositeStore) Delete(ctx context.Context, m *model.Composite) error {
	g := goon.FromContext(ctx)
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

func (s *CompositeStore) ValidateUniqueness(ctx context.Context, m *model.Composite) error {
	conditions := map[string]interface{}{}
	for field, value := range conditions {
		q := s.Query().Filter(field+" =", value)
		c, err := s.CountBy(ctx, q)
		if err != nil {
			return err
		}
		b := 0
		if m.IsPersisted() {
			b = 1
		}
		if c > b {
			return &model.ValidationError{
				Field:   field,
				Message: fmt.Sprintf("%v has already been taken", value),
			}
		}
	}
	return nil
}
