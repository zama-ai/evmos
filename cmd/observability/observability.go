package observability

import (
	"fmt"
	"net/http"

	"contrib.go.opencensus.io/exporter/prometheus"
	"go.opencensus.io/stats/view"
)

func Enable(name string) error {
	pe, err := prometheus.NewExporter(
		// TODO: add other fields
		prometheus.Options{
			Namespace: name,
		},
	)
	if err != nil {
		return fmt.Errorf("cmd/config: failed to create the OpenCensus Prometheus exporter: %w", err)
	}

	views := TransactionViews()

	if err := view.Register(views...); err != nil {
		return fmt.Errorf("cmd/config: failed to register OpenCensus views: %w", err)
	}

	view.RegisterExporter(pe)

	mux := http.NewServeMux()
	mux.Handle("/metrics", pe)

	// TODO: Derive the Prometheus observability exporter from the Evmos config.
	addr := ":8877"
	go func() {
		println("Serving the Prometheus observability exporter at", addr)
		// TODO:
		if err := http.ListenAndServeTLS(addr, "", "", mux); err != nil {
			panic(err)
		}
	}()

	return nil
}
