// DO NOT EDIT this file.

package memo

import (
	"github.com/akm/goa_model_gen/project1/converters"
	gen "github.com/akm/goa_model_gen/project1/gen/memo"
	"github.com/akm/goa_model_gen/project1/model"
)

func MemoPayloadToModel(payload *gen.MemoPayload) (*model.Memo, error) {
	m := &model.Memo{}
	if err := CopyFromMemoPayloadToModel(payload, m); err != nil {
		return nil, err
	}
	return m, nil
}

func CopyFromMemoPayloadToModel(payload *gen.MemoPayload, m *model.Memo) error {
	if payload == nil {
		return converters.NoPayloadGiven
	}
	if m == nil {
		return converters.NoModelGiven
	}

	// Id not found in MemoPayload fields
	// AuthorKey not found in MemoPayload fields
	m.ContentText = payload.Content
	if payload.Shared != nil {
		m.Shared = *payload.Shared
	}
	// CreatedAt not found in MemoPayload fields
	// UpdatedAt not found in MemoPayload fields
	return nil
}

func MemoModelToResult(m *model.Memo) (*gen.Memo, error) {
	if m == nil {
		return nil, converters.NoModelGiven
	}
	r := &gen.Memo{}

	r.ID = converters.Int64ToString(m.Id)
	// AuthorKey not found in Memo fields
	r.Content = m.ContentText
	r.Shared = m.Shared
	r.CreatedAt = converters.TimeToString(m.CreatedAt)
	r.UpdatedAt = converters.TimeToString(m.UpdatedAt)
	return r, nil
}
