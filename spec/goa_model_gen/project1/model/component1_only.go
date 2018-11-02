package model

import (
  "fmt"
  "time"

  "golang.org/x/net/context"
	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"

)

type Component1 struct {
	Name string `json:"name" validate:"required"`
}



