package observability

import (
	"go.opencensus.io/stats"
	"go.opencensus.io/stats/view"
	"go.opencensus.io/tag"
)

var (
	tagKeyStatus     = tag.MustNewKey("status")
	mTransactions    = stats.Int64("transactions", "the number of transactions after .EndBlocker", "1")
	viewTransactions = &view.View{
		Name:        "transactions_processed",
		Measure:     mTransactions,
		Description: "The transactions processed",
		TagKeys:     []tag.Key{tagKeyStatus},
		Aggregation: view.Count(),
	}
)

func TransactionViews() (views []*view.View) {
	views = append(views, viewTransactions)
	return views
}
