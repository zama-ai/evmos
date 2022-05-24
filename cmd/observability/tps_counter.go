package observability

import (
	"context"
	"math/big"
	"sync"
	"sync/atomic"
	"time"

	"github.com/tendermint/tendermint/libs/log"
	"go.opencensus.io/stats"
	"go.opencensus.io/tag"
)

const (
	DefaultTPSReportPeriod = 10 * time.Second
)

type TpsCounter struct {
	logger        log.Logger
	successfulTxs uint64
	revertedTxs   uint64
	failedTxs     uint64
	reportPeriod  time.Duration
	doneCloseOnce sync.Once
	doneCh        chan bool
}

func NewTPSCounter(logger log.Logger, reportPeriod time.Duration) *TpsCounter {
	return &TpsCounter{
		logger:       logger,
		doneCh:       make(chan bool, 1),
		reportPeriod: reportPeriod,
	}
}

func (tpc *TpsCounter) incrementSuccess() {
	atomic.AddUint64(&tpc.successfulTxs, 1)
}

func (tpc *TpsCounter) incrementRevert() {
	atomic.AddUint64(&tpc.revertedTxs, 1)
}

func (tpc *TpsCounter) incrementFailure() {
	atomic.AddUint64(&tpc.failedTxs, 1)
}

func (tpc *TpsCounter) start(ctx context.Context) error {
	if tpc.reportPeriod == 0 {
		tpc.reportPeriod = DefaultTPSReportPeriod
	}

	ticker := time.NewTicker(tpc.reportPeriod)

	defer func() {
		ticker.Stop()
		tpc.doneCloseOnce.Do(func() {
			close(tpc.doneCh)
		})
	}()

	var lastNSuccessful, lastNFailed uint64

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()

		case <-ticker.C:
			// Report the number of transactions seen in the designated period of time.
			latestNSuccessful := atomic.LoadUint64(&tpc.successfulTxs)
			latestNFailed := atomic.LoadUint64(&tpc.failedTxs)

			var nTxn int64
			nSuccess, err := tpc.recordValue(ctx, latestNSuccessful, lastNSuccessful, statusSuccess)
			if err != nil {
				panic(err)
			}

			nTxn += nSuccess

			nFailed, err := tpc.recordValue(ctx, latestNFailed, lastNFailed, statusFailure)
			if err != nil {
				panic(err)
			}

			nTxn += nFailed

			if nTxn != 0 {
				// Record to our logger for easy examination in the logs.
				tpc.logger.Info("Transactions per second", "tps", new(big.Int).Div(big.NewInt(nTxn), big.NewInt(int64(tpc.reportPeriod.Seconds()))))
			}

			lastNFailed = latestNFailed
			lastNSuccessful = latestNSuccessful
		}
	}
}

type status string

const (
	statusSuccess = "success"
	statusFailure = "failure"
)

func (tpc *TpsCounter) recordValue(ctx context.Context, latest, previous uint64, status status) (int64, error) {
	if latest < previous {
		return 0, nil
	}

	n := int64(latest - previous)
	if n < 0 {
		// Perhaps we exceeded the uint64 limits then wrapped around, for the latest value.
		// TODO: Perhaps log this?
		return 0, nil
	}

	statusValue := "OK"
	if status == statusFailure {
		statusValue = "ERR"
	}
	ctx, err := tag.New(ctx, tag.Upsert(tagKeyStatus, statusValue))
	if err != nil {
		return 0, err
	}

	stats.Record(ctx, mTransactions.M(n))
	return n, nil
}
