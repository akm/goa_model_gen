// You can edit this file. goa_model_gen doesn't overwrite this file.

package memo

import (
	"context"

	"github.com/akm/goa_model_gen/project1/model"
)

func (s *MemoStore) Validate(ctx context.Context, m *model.Memo) error {
	if err := m.Validate(ctx); err != nil {
		return err
	}
	if err := s.ValidateUniqueness(ctx, m); err != nil {
		return err
	}
	return nil
}
