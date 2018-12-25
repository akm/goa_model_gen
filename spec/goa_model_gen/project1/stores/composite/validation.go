// You can edit this file. goa_model_gen doesn't overwrite this file.
// This code generated by goa_model_gen-<%= GoaModelGen::VERSION %>

package composite

import (
	"context"

	"github.com/akm/goa_model_gen/project1/model"
)

func (s *CompositeStore) Validate(ctx context.Context, m *model.Composite) error {
	if err := m.Validate(ctx); err != nil {
		return err
	}
	if err := s.ValidateUniqueness(ctx, m); err != nil {
		return err
	}
	return nil
}
