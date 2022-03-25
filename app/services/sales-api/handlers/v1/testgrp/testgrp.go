package testgrp

import (
	"context"
	"net/http"

	"github.com/Ekod/go-prod/foundation/web"
	"go.uber.org/zap"
)

// Handlers manages the set of check endpoints.
type Handlers struct {
	Log *zap.SugaredLogger
}

// APIMux constructs a http.Handler with all application routes defined.
func (h Handlers) Test(ctx context.Context, rw http.ResponseWriter, r *http.Request) error {

	status := struct {
		Status string
	}{
		Status: "OK",
	}

	return web.Respond(ctx, rw, status, http.StatusOK)
}
