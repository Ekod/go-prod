package testgrp

import (
	"encoding/json"
	"net/http"

	"go.uber.org/zap"
)

// Handlers manages the set of check endpoints.
type Handlers struct {
	Log *zap.SugaredLogger
}

// APIMux constructs a http.Handler with all application routes defined.
func (h Handlers) Test(rw http.ResponseWriter, r *http.Request) {

	status := struct {
		Status string
	}{
		Status: "OK",
	}

	json.NewEncoder(rw).Encode(status)
	statusCode := http.StatusOK

	h.Log.Infow("readiness", "statusCode", statusCode, "method", r.Method, "path", r.URL.Path, "remoteaddr", r.RemoteAddr)
}
